# Auto-generated client for App Engine Admin API v1beta
# Source: https://api.apis.guru/v2/specs/googleapis.com/appengine/v1beta/openapi.json
# Auth: --token flag or $env.APP_ENGINE_ADMIN_API_TOKEN

const CLIENT = {
  base_url: "https://appengine.googleapis.com"
  token_env_var: "APP_ENGINE_ADMIN_API_TOKEN"
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

def base-url-completer [] { ["https://appengine.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def database-type-completer [] { ["CLOUD_DATASTORE" "CLOUD_DATASTORE_COMPATIBILITY" "CLOUD_FIRESTORE" "DATABASE_TYPE_UNSPECIFIED"] }
def serving-status-completer [] { ["SERVING" "SYSTEM_DISABLED" "UNSPECIFIED" "USER_DISABLED"] }
def view-completer [] { ["BASIC_CERTIFICATE" "FULL_CERTIFICATE"] }
def override-strategy-completer [] { ["OVERRIDE" "STRICT" "UNSPECIFIED_DOMAIN_OVERRIDE_STRATEGY"] }
def action-completer [] { ["ALLOW" "DENY" "UNSPECIFIED_ACTION"] }
def view-completer-1 [] { ["BASIC" "FULL"] }
def serving-status-completer-1 [] { ["SERVING" "SERVING_STATUS_UNSPECIFIED" "STOPPED"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    appengine-apps-create: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    appengine-apps-get: "record<authDomain: string, codeBucket: string, databaseType: string, defaultBucket: string, defaultCookieExpiration: string, defaultHostname: string, dispatchRules: table<domain: string, path: string, service: string>, featureSettings: record<splitHealthChecks: bool, useContainerOptimizedOs: bool>, gcrDomain: string, iap: record<enabled: bool, oauth2ClientId: string, oauth2ClientSecret: string, oauth2ClientSecretSha256: string>, id: string, locationId: string, name: string, serviceAccount: string, servingStatus: string>"
    appengine-apps-patch: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    appengine-apps-authorized-certificates-list: "record<certificates: table<certificateRawData: record, displayName: string, domainMappingsCount: int, domainNames: list, expireTime: string, id: string, managedCertificate: record, name: string, visibleDomainMappings: list>, nextPageToken: string>"
    appengine-apps-authorized-certificates-create: "record<certificateRawData: record<privateKey: string, publicCertificate: string>, displayName: string, domainMappingsCount: int, domainNames: list<string>, expireTime: string, id: string, managedCertificate: record<lastRenewalTime: string, status: string>, name: string, visibleDomainMappings: list<string>>"
    appengine-apps-authorized-certificates-delete: "record"
    appengine-apps-authorized-certificates-get: "record<certificateRawData: record<privateKey: string, publicCertificate: string>, displayName: string, domainMappingsCount: int, domainNames: list<string>, expireTime: string, id: string, managedCertificate: record<lastRenewalTime: string, status: string>, name: string, visibleDomainMappings: list<string>>"
    appengine-apps-authorized-certificates-patch: "record<certificateRawData: record<privateKey: string, publicCertificate: string>, displayName: string, domainMappingsCount: int, domainNames: list<string>, expireTime: string, id: string, managedCertificate: record<lastRenewalTime: string, status: string>, name: string, visibleDomainMappings: list<string>>"
    appengine-apps-authorized-domains-list: "record<domains: table<id: string, name: string>, nextPageToken: string>"
    appengine-apps-domain-mappings-list: "record<domainMappings: table<id: string, name: string, resourceRecords: list, sslSettings: record>, nextPageToken: string>"
    appengine-apps-domain-mappings-create: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    appengine-apps-domain-mappings-delete: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    appengine-apps-domain-mappings-get: "record<id: string, name: string, resourceRecords: table<name: string, rrdata: string, type: string>, sslSettings: record<certificateId: string, pendingManagedCertificateId: string, sslManagementType: string>>"
    appengine-apps-domain-mappings-patch: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    appengine-apps-firewall-ingress-rules-list: "record<ingressRules: table<action: string, description: string, priority: int, sourceRange: string>, nextPageToken: string>"
    appengine-apps-firewall-ingress-rules-create: "record<action: string, description: string, priority: int, sourceRange: string>"
    appengine-apps-firewall-ingress-rules-delete: "record"
    appengine-apps-firewall-ingress-rules-get: "record<action: string, description: string, priority: int, sourceRange: string>"
    appengine-apps-firewall-ingress-rules-patch: "record<action: string, description: string, priority: int, sourceRange: string>"
    appengine-apps-firewall-ingress-rules-batch-update: "record<ingressRules: table<action: string, description: string, priority: int, sourceRange: string>>"
    appengine-apps-locations-list: "record<locations: table<displayName: string, labels: record, locationId: string, metadata: record, name: string>, nextPageToken: string>"
    appengine-apps-locations-get: "record<displayName: string, labels: record, locationId: string, metadata: record, name: string>"
    appengine-apps-operations-list: "record<nextPageToken: string, operations: table<done: bool, error: record, metadata: record, name: string, response: record>>"
    appengine-apps-operations-get: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    appengine-apps-services-list: "record<nextPageToken: string, services: table<id: string, labels: record, name: string, networkSettings: record, split: record>>"
    appengine-apps-services-delete: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    appengine-apps-services-get: "record<id: string, labels: record, name: string, networkSettings: record<ingressTrafficAllowed: string>, split: record<allocations: record, shardBy: string>>"
    appengine-apps-services-patch: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    appengine-apps-services-versions-list: "record<nextPageToken: string, versions: table<apiConfig: record, appEngineApis: bool, automaticScaling: record, basicScaling: record, betaSettings: record, buildEnvVariables: record, createTime: string, createdBy: string, defaultExpiration: string, deployment: record, diskUsageBytes: string, endpointsApiService: record, entrypoint: record, env: string, envVariables: record, errorHandlers: list, flexibleRuntimeSettings: record, handlers: list, healthCheck: record, id: string, inboundServices: list, instanceClass: string, libraries: list, livenessCheck: record, manualScaling: record, name: string, network: record, nobuildFilesRegex: string, readinessCheck: record, resources: record, runtime: string, runtimeApiVersion: string, runtimeChannel: string, runtimeMainExecutablePath: string, serviceAccount: string, servingStatus: string, threadsafe: bool, versionUrl: string, vm: bool, vpcAccessConnector: record, zones: list>>"
    appengine-apps-services-versions-create: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    appengine-apps-services-versions-delete: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    appengine-apps-services-versions-get: "record<apiConfig: record<authFailAction: string, login: string, script: string, securityLevel: string, url: string>, appEngineApis: bool, automaticScaling: record<coolDownPeriod: string, cpuUtilization: record<aggregationWindowLength: string, targetUtilization: float>, customMetrics: list<record>, diskUtilization: record<targetReadBytesPerSecond: int, targetReadOpsPerSecond: int, targetWriteBytesPerSecond: int, targetWriteOpsPerSecond: int>, maxConcurrentRequests: int, maxIdleInstances: int, maxPendingLatency: string, maxTotalInstances: int, minIdleInstances: int, minPendingLatency: string, minTotalInstances: int, networkUtilization: record<targetReceivedBytesPerSecond: int, targetReceivedPacketsPerSecond: int, targetSentBytesPerSecond: int, targetSentPacketsPerSecond: int>, requestUtilization: record<targetConcurrentRequests: int, targetRequestCountPerSecond: int>, standardSchedulerSettings: record<maxInstances: int, minInstances: int, targetCpuUtilization: float, targetThroughputUtilization: float>>, basicScaling: record<idleTimeout: string, maxInstances: int>, betaSettings: record, buildEnvVariables: record, createTime: string, createdBy: string, defaultExpiration: string, deployment: record<build: record<cloudBuildId: string>, cloudBuildOptions: record<appYamlPath: string, cloudBuildTimeout: string>, container: record<image: string>, files: record, zip: record<filesCount: int, sourceUrl: string>>, diskUsageBytes: string, endpointsApiService: record<configId: string, disableTraceSampling: bool, name: string, rolloutStrategy: string>, entrypoint: record<shell: string>, env: string, envVariables: record, errorHandlers: table<errorCode: string, mimeType: string, staticFile: string>, flexibleRuntimeSettings: record<operatingSystem: string, runtimeVersion: string>, handlers: table<apiEndpoint: record, authFailAction: string, login: string, redirectHttpResponseCode: string, script: record, securityLevel: string, staticFiles: record, urlRegex: string>, healthCheck: record<checkInterval: string, disableHealthCheck: bool, healthyThreshold: int, host: string, restartThreshold: int, timeout: string, unhealthyThreshold: int>, id: string, inboundServices: list<string>, instanceClass: string, libraries: table<name: string, version: string>, livenessCheck: record<checkInterval: string, failureThreshold: int, host: string, initialDelay: string, path: string, successThreshold: int, timeout: string>, manualScaling: record<instances: int>, name: string, network: record<forwardedPorts: list<string>, instanceIpMode: string, instanceTag: string, name: string, sessionAffinity: bool, subnetworkName: string>, nobuildFilesRegex: string, readinessCheck: record<appStartTimeout: string, checkInterval: string, failureThreshold: int, host: string, path: string, successThreshold: int, timeout: string>, resources: record<cpu: float, diskGb: float, kmsKeyReference: string, memoryGb: float, volumes: list<record>>, runtime: string, runtimeApiVersion: string, runtimeChannel: string, runtimeMainExecutablePath: string, serviceAccount: string, servingStatus: string, threadsafe: bool, versionUrl: string, vm: bool, vpcAccessConnector: record<egressSetting: string, name: string>, zones: list<string>>"
    appengine-apps-services-versions-patch: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    appengine-apps-services-versions-instances-list: "record<instances: table<appEngineRelease: string, availability: string, averageLatency: int, errors: int, id: string, memoryUsage: string, name: string, qps: float, requests: int, startTime: string, vmDebugEnabled: bool, vmId: string, vmIp: string, vmLiveness: string, vmName: string, vmStatus: string, vmZoneName: string>, nextPageToken: string>"
    appengine-apps-services-versions-instances-delete: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    appengine-apps-services-versions-instances-get: "record<appEngineRelease: string, availability: string, averageLatency: int, errors: int, id: string, memoryUsage: string, name: string, qps: float, requests: int, startTime: string, vmDebugEnabled: bool, vmId: string, vmIp: string, vmLiveness: string, vmName: string, vmStatus: string, vmZoneName: string>"
    appengine-apps-services-versions-instances-debug: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    appengine-apps-repair: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    appengine-projects-locations-list: "record<locations: table<displayName: string, labels: record, locationId: string, metadata: record, name: string>, nextPageToken: string>"
    appengine-projects-locations-get: "record<displayName: string, labels: record, locationId: string, metadata: record, name: string>"
    appengine-projects-locations-applications-create: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    appengine-projects-locations-applications-get: "record<authDomain: string, codeBucket: string, databaseType: string, defaultBucket: string, defaultCookieExpiration: string, defaultHostname: string, dispatchRules: table<domain: string, path: string, service: string>, featureSettings: record<splitHealthChecks: bool, useContainerOptimizedOs: bool>, gcrDomain: string, iap: record<enabled: bool, oauth2ClientId: string, oauth2ClientSecret: string, oauth2ClientSecretSha256: string>, id: string, locationId: string, name: string, serviceAccount: string, servingStatus: string>"
    appengine-projects-locations-applications-repair: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    appengine-projects-locations-operations-list: "record<nextPageToken: string, operations: table<done: bool, error: record, metadata: record, name: string, response: record>>"
    appengine-projects-locations-operations-get: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["appengine-apps-create" "appengine-apps-get" "appengine-apps-patch" "appengine-apps-authorized-certificates-list" "appengine-apps-authorized-certificates-create" "appengine-apps-authorized-certificates-delete" "appengine-apps-authorized-certificates-get" "appengine-apps-authorized-certificates-patch" "appengine-apps-authorized-domains-list" "appengine-apps-domain-mappings-list" "appengine-apps-domain-mappings-create" "appengine-apps-domain-mappings-delete" "appengine-apps-domain-mappings-get" "appengine-apps-domain-mappings-patch" "appengine-apps-firewall-ingress-rules-list" "appengine-apps-firewall-ingress-rules-create" "appengine-apps-firewall-ingress-rules-delete" "appengine-apps-firewall-ingress-rules-get" "appengine-apps-firewall-ingress-rules-patch" "appengine-apps-firewall-ingress-rules-batch-update" "appengine-apps-locations-list" "appengine-apps-locations-get" "appengine-apps-operations-list" "appengine-apps-operations-get" "appengine-apps-services-list" "appengine-apps-services-delete" "appengine-apps-services-get" "appengine-apps-services-patch" "appengine-apps-services-versions-list" "appengine-apps-services-versions-create" "appengine-apps-services-versions-delete" "appengine-apps-services-versions-get" "appengine-apps-services-versions-patch" "appengine-apps-services-versions-instances-list" "appengine-apps-services-versions-instances-delete" "appengine-apps-services-versions-instances-get" "appengine-apps-services-versions-instances-debug" "appengine-apps-repair" "appengine-projects-locations-list" "appengine-projects-locations-get" "appengine-projects-locations-applications-create" "appengine-projects-locations-applications-get" "appengine-projects-locations-applications-repair" "appengine-projects-locations-operations-list" "appengine-projects-locations-operations-get" "commands"] | sort) } | get name | first)
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

# Creates an App Engine application for a Google Cloud Platform project. Required fields: id - The ID of the target Cloud Platform project. location - The region (https://cloud.google.com/appengine/docs/locations) where you want the App Engine application located.For more information about App Engine applications, see Managing Projects, Applications, and Billing (https://cloud.google.com/appengine/docs/standard/python/console/).
#
# POST /v1beta/apps
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: appengine.apps.create
export def "appengine-apps-create" [
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
  --parent: string # The project and location in which the application should be created, specified in the format projects/*/locations/*
  --auth-domain: string # Google Apps authentication domain that controls which users can access this application.Defaults to open access for any Google Account.
  --database-type: string@database-type-completer # The type of the Cloud Firestore or Cloud Datastore database associated with this application.
  --default-cookie-expiration: string # Cookie expiration policy for this application. (format: google-duration)
  --dispatch-rules: list # HTTP path dispatch rules for requests to the application that do not explicitly target a service or version. Rules are order-dependent. Up to 20 dispatch rules can be supported. — item shape: {domain?: string, path?: string, service?: string}
  --feature-settings: record # The feature specific settings to be used in the application. These define behaviors that are user configurable. — shape: {splitHealthChecks?: bool, useContainerOptimizedOs?: bool}
  --iap: record # Identity-Aware Proxy — shape: {enabled?: bool, oauth2ClientId?: string, oauth2ClientSecret?: string}
  --id: string # Identifier of the Application resource. This identifier is equivalent to the project ID of the Google Cloud Platform project where you want to deploy your application. Example: myapp.
  --location-id: string # Location from which this application runs. Application instances run out of the data centers in the specified location, which is also where all of the application's end user content is stored.Defaults to us-central.View the list of supported locations (https://cloud.google.com/appengine/docs/locations).
  --service-account: string # The service account associated with the application. This is the app-level default identity. If no identity provided during create version, Admin API will fallback to this one.
  --serving-status: string@serving-status-completer # Serving status of this application.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta/apps"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: parent, var: parent}]
    body: {content_type: "application/json", kind: json, fields: [{name: authDomain, var: auth_domain}, {name: databaseType, var: database_type}, {name: defaultCookieExpiration, var: default_cookie_expiration}, {name: dispatchRules, var: dispatch_rules}, {name: featureSettings, var: feature_settings}, {name: iap, var: iap}, {name: id, var: id}, {name: locationId, var: location_id}, {name: serviceAccount, var: service_account}, {name: servingStatus, var: serving_status}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, parent: $parent, auth_domain: $auth_domain, database_type: $database_type, default_cookie_expiration: $default_cookie_expiration, dispatch_rules: $dispatch_rules, feature_settings: $feature_settings, iap: $iap, id: $id, location_id: $location_id, service_account: $service_account, serving_status: $serving_status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about an application.
#
# GET /v1beta/apps/{appsId}
# Returns: record<authDomain: string, codeBucket: string, databaseType: string, defaultBucket: string, defaultCookieExpiration: string, defaultHostname: string, dispatchRules: table<domain: string, path: string, service: string>, featureSettings: record<splitHealthChecks: bool, useContainerOptimizedOs: bool>, gcrDomain: string, iap: record<enabled: bool, oauth2ClientId: string, oauth2ClientSecret: string, oauth2ClientSecretSha256: string>, id: string, locationId: string, name: string, serviceAccount: string, servingStatus: string>
# operationId: appengine.apps.get
export def "appengine-apps-get" [
  apps_id: string
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
    path: "/v1beta/apps/{appsId}"
    path_params: [{name: appsId, var: apps_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    apps_id: $apps_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the specified Application resource. You can update the following fields: auth_domain - Google authentication domain for controlling user access to the application. default_cookie_expiration - Cookie expiration policy for the application. iap - Identity-Aware Proxy properties for the application.
#
# PATCH /v1beta/apps/{appsId}
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: appengine.apps.patch
export def "appengine-apps-patch" [
  apps_id: string
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
  --update-mask: string # Required. Standard field mask for the set of fields to be updated.
  --auth-domain: string # Google Apps authentication domain that controls which users can access this application.Defaults to open access for any Google Account.
  --database-type: string@database-type-completer # The type of the Cloud Firestore or Cloud Datastore database associated with this application.
  --default-cookie-expiration: string # Cookie expiration policy for this application. (format: google-duration)
  --dispatch-rules: list # HTTP path dispatch rules for requests to the application that do not explicitly target a service or version. Rules are order-dependent. Up to 20 dispatch rules can be supported. — item shape: {domain?: string, path?: string, service?: string}
  --feature-settings: record # The feature specific settings to be used in the application. These define behaviors that are user configurable. — shape: {splitHealthChecks?: bool, useContainerOptimizedOs?: bool}
  --iap: record # Identity-Aware Proxy — shape: {enabled?: bool, oauth2ClientId?: string, oauth2ClientSecret?: string}
  --id: string # Identifier of the Application resource. This identifier is equivalent to the project ID of the Google Cloud Platform project where you want to deploy your application. Example: myapp.
  --location-id: string # Location from which this application runs. Application instances run out of the data centers in the specified location, which is also where all of the application's end user content is stored.Defaults to us-central.View the list of supported locations (https://cloud.google.com/appengine/docs/locations).
  --service-account: string # The service account associated with the application. This is the app-level default identity. If no identity provided during create version, Admin API will fallback to this one.
  --serving-status: string@serving-status-completer # Serving status of this application.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1beta/apps/{appsId}"
    path_params: [{name: appsId, var: apps_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: updateMask, var: update_mask}]
    body: {content_type: "application/json", kind: json, fields: [{name: authDomain, var: auth_domain}, {name: databaseType, var: database_type}, {name: defaultCookieExpiration, var: default_cookie_expiration}, {name: dispatchRules, var: dispatch_rules}, {name: featureSettings, var: feature_settings}, {name: iap, var: iap}, {name: id, var: id}, {name: locationId, var: location_id}, {name: serviceAccount, var: service_account}, {name: servingStatus, var: serving_status}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    apps_id: $apps_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, update_mask: $update_mask, auth_domain: $auth_domain, database_type: $database_type, default_cookie_expiration: $default_cookie_expiration, dispatch_rules: $dispatch_rules, feature_settings: $feature_settings, iap: $iap, id: $id, location_id: $location_id, service_account: $service_account, serving_status: $serving_status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all SSL certificates the user is authorized to administer.
#
# GET /v1beta/apps/{appsId}/authorizedCertificates
# Returns: record<certificates: table<certificateRawData: record, displayName: string, domainMappingsCount: int, domainNames: list, expireTime: string, id: string, managedCertificate: record, name: string, visibleDomainMappings: list>, nextPageToken: string>
# operationId: appengine.apps.authorizedCertificates.list
export def "appengine-apps-authorized-certificates-list" [
  apps_id: string
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
  --page-size: int # Maximum results to return per page.
  --page-token: string # Continuation token for fetching the next page of results.
  --view: string@view-completer # Controls the set of fields returned in the LIST response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta/apps/{appsId}/authorizedCertificates"
    path_params: [{name: appsId, var: apps_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}, {name: view, var: view}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    apps_id: $apps_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, page_size: $page_size, page_token: $page_token, view: $view
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Uploads the specified SSL certificate.
#
# POST /v1beta/apps/{appsId}/authorizedCertificates
# Returns: record<certificateRawData: record<privateKey: string, publicCertificate: string>, displayName: string, domainMappingsCount: int, domainNames: list<string>, expireTime: string, id: string, managedCertificate: record<lastRenewalTime: string, status: string>, name: string, visibleDomainMappings: list<string>>
# operationId: appengine.apps.authorizedCertificates.create
export def "appengine-apps-authorized-certificates-create" [
  apps_id: string
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
  --certificate-raw-data: record # An SSL certificate obtained from a certificate authority. — shape: {privateKey?: string, publicCertificate?: string}
  --display-name: string # The user-specified display name of the certificate. This is not guaranteed to be unique. Example: My Certificate.
  --domain-mappings-count: int # Aggregate count of the domain mappings with this certificate mapped. This count includes domain mappings on applications for which the user does not have VIEWER permissions.Only returned by GET or LIST requests when specifically requested by the view=FULL_CERTIFICATE option.@OutputOnly (format: int32)
  --domain-names: list<string> # Topmost applicable domains of this certificate. This certificate applies to these domains and their subdomains. Example: example.com.@OutputOnly
  --expire-time: string # The time when this certificate expires. To update the renewal time on this certificate, upload an SSL certificate with a different expiration time using AuthorizedCertificates.UpdateAuthorizedCertificate.@OutputOnly (format: google-datetime)
  --id: string # Relative name of the certificate. This is a unique value autogenerated on AuthorizedCertificate resource creation. Example: 12345.@OutputOnly
  --managed-certificate: record # A certificate managed by App Engine. — shape: {lastRenewalTime?: string, status?: "MANAGEMENT_STATUS_UNSPECIFIED"|"OK"|"PENDING"|"FAILED_RETRYING_NOT_VISIBLE"|"FAILED_PERMANENT"|"FAILED_RETRYING_CAA_FORBIDDEN"|"FAILED_RETRYING_CAA_CHECKING"}
  --name: string # Full path to the AuthorizedCertificate resource in the API. Example: apps/myapp/authorizedCertificates/12345.@OutputOnly
  --visible-domain-mappings: list<string> # The full paths to user visible Domain Mapping resources that have this certificate mapped. Example: apps/myapp/domainMappings/example.com.This may not represent the full list of mapped domain mappings if the user does not have VIEWER permissions on all of the applications that have this certificate mapped. See domain_mappings_count for a complete count.Only returned by GET or LIST requests when specifically requested by the view=FULL_CERTIFICATE option.@OutputOnly
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta/apps/{appsId}/authorizedCertificates"
    path_params: [{name: appsId, var: apps_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: certificateRawData, var: certificate_raw_data}, {name: displayName, var: display_name}, {name: domainMappingsCount, var: domain_mappings_count}, {name: domainNames, var: domain_names}, {name: expireTime, var: expire_time}, {name: id, var: id}, {name: managedCertificate, var: managed_certificate}, {name: name, var: name}, {name: visibleDomainMappings, var: visible_domain_mappings}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    apps_id: $apps_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, certificate_raw_data: $certificate_raw_data, display_name: $display_name, domain_mappings_count: $domain_mappings_count, domain_names: $domain_names, expire_time: $expire_time, id: $id, managed_certificate: $managed_certificate, name: $name, visible_domain_mappings: $visible_domain_mappings
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified SSL certificate.
#
# DELETE /v1beta/apps/{appsId}/authorizedCertificates/{authorizedCertificatesId}
# Returns: record
# operationId: appengine.apps.authorizedCertificates.delete
export def "appengine-apps-authorized-certificates-delete" [
  apps_id: string
  authorized_certificates_id: string
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
    path: "/v1beta/apps/{appsId}/authorizedCertificates/{authorizedCertificatesId}"
    path_params: [{name: appsId, var: apps_id}, {name: authorizedCertificatesId, var: authorized_certificates_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    apps_id: $apps_id, authorized_certificates_id: $authorized_certificates_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the specified SSL certificate.
#
# GET /v1beta/apps/{appsId}/authorizedCertificates/{authorizedCertificatesId}
# Returns: record<certificateRawData: record<privateKey: string, publicCertificate: string>, displayName: string, domainMappingsCount: int, domainNames: list<string>, expireTime: string, id: string, managedCertificate: record<lastRenewalTime: string, status: string>, name: string, visibleDomainMappings: list<string>>
# operationId: appengine.apps.authorizedCertificates.get
export def "appengine-apps-authorized-certificates-get" [
  apps_id: string
  authorized_certificates_id: string
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
  --view: string@view-completer # Controls the set of fields returned in the GET response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta/apps/{appsId}/authorizedCertificates/{authorizedCertificatesId}"
    path_params: [{name: appsId, var: apps_id}, {name: authorizedCertificatesId, var: authorized_certificates_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: view, var: view}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    apps_id: $apps_id, authorized_certificates_id: $authorized_certificates_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, view: $view
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the specified SSL certificate. To renew a certificate and maintain its existing domain mappings, update certificate_data with a new certificate. The new certificate must be applicable to the same domains as the original certificate. The certificate display_name may also be updated.
#
# PATCH /v1beta/apps/{appsId}/authorizedCertificates/{authorizedCertificatesId}
# Returns: record<certificateRawData: record<privateKey: string, publicCertificate: string>, displayName: string, domainMappingsCount: int, domainNames: list<string>, expireTime: string, id: string, managedCertificate: record<lastRenewalTime: string, status: string>, name: string, visibleDomainMappings: list<string>>
# operationId: appengine.apps.authorizedCertificates.patch
export def "appengine-apps-authorized-certificates-patch" [
  apps_id: string
  authorized_certificates_id: string
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
  --update-mask: string # Standard field mask for the set of fields to be updated. Updates are only supported on the certificate_raw_data and display_name fields.
  --certificate-raw-data: record # An SSL certificate obtained from a certificate authority. — shape: {privateKey?: string, publicCertificate?: string}
  --display-name: string # The user-specified display name of the certificate. This is not guaranteed to be unique. Example: My Certificate.
  --domain-mappings-count: int # Aggregate count of the domain mappings with this certificate mapped. This count includes domain mappings on applications for which the user does not have VIEWER permissions.Only returned by GET or LIST requests when specifically requested by the view=FULL_CERTIFICATE option.@OutputOnly (format: int32)
  --domain-names: list<string> # Topmost applicable domains of this certificate. This certificate applies to these domains and their subdomains. Example: example.com.@OutputOnly
  --expire-time: string # The time when this certificate expires. To update the renewal time on this certificate, upload an SSL certificate with a different expiration time using AuthorizedCertificates.UpdateAuthorizedCertificate.@OutputOnly (format: google-datetime)
  --id: string # Relative name of the certificate. This is a unique value autogenerated on AuthorizedCertificate resource creation. Example: 12345.@OutputOnly
  --managed-certificate: record # A certificate managed by App Engine. — shape: {lastRenewalTime?: string, status?: "MANAGEMENT_STATUS_UNSPECIFIED"|"OK"|"PENDING"|"FAILED_RETRYING_NOT_VISIBLE"|"FAILED_PERMANENT"|"FAILED_RETRYING_CAA_FORBIDDEN"|"FAILED_RETRYING_CAA_CHECKING"}
  --name: string # Full path to the AuthorizedCertificate resource in the API. Example: apps/myapp/authorizedCertificates/12345.@OutputOnly
  --visible-domain-mappings: list<string> # The full paths to user visible Domain Mapping resources that have this certificate mapped. Example: apps/myapp/domainMappings/example.com.This may not represent the full list of mapped domain mappings if the user does not have VIEWER permissions on all of the applications that have this certificate mapped. See domain_mappings_count for a complete count.Only returned by GET or LIST requests when specifically requested by the view=FULL_CERTIFICATE option.@OutputOnly
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1beta/apps/{appsId}/authorizedCertificates/{authorizedCertificatesId}"
    path_params: [{name: appsId, var: apps_id}, {name: authorizedCertificatesId, var: authorized_certificates_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: updateMask, var: update_mask}]
    body: {content_type: "application/json", kind: json, fields: [{name: certificateRawData, var: certificate_raw_data}, {name: displayName, var: display_name}, {name: domainMappingsCount, var: domain_mappings_count}, {name: domainNames, var: domain_names}, {name: expireTime, var: expire_time}, {name: id, var: id}, {name: managedCertificate, var: managed_certificate}, {name: name, var: name}, {name: visibleDomainMappings, var: visible_domain_mappings}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    apps_id: $apps_id, authorized_certificates_id: $authorized_certificates_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, update_mask: $update_mask, certificate_raw_data: $certificate_raw_data, display_name: $display_name, domain_mappings_count: $domain_mappings_count, domain_names: $domain_names, expire_time: $expire_time, id: $id, managed_certificate: $managed_certificate, name: $name, visible_domain_mappings: $visible_domain_mappings
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all domains the user is authorized to administer.
#
# GET /v1beta/apps/{appsId}/authorizedDomains
# Returns: record<domains: table<id: string, name: string>, nextPageToken: string>
# operationId: appengine.apps.authorizedDomains.list
export def "appengine-apps-authorized-domains-list" [
  apps_id: string
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
  --page-size: int # Maximum results to return per page.
  --page-token: string # Continuation token for fetching the next page of results.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta/apps/{appsId}/authorizedDomains"
    path_params: [{name: appsId, var: apps_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    apps_id: $apps_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the domain mappings on an application.
#
# GET /v1beta/apps/{appsId}/domainMappings
# Returns: record<domainMappings: table<id: string, name: string, resourceRecords: list, sslSettings: record>, nextPageToken: string>
# operationId: appengine.apps.domainMappings.list
export def "appengine-apps-domain-mappings-list" [
  apps_id: string
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
  --page-size: int # Maximum results to return per page.
  --page-token: string # Continuation token for fetching the next page of results.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta/apps/{appsId}/domainMappings"
    path_params: [{name: appsId, var: apps_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    apps_id: $apps_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Maps a domain to an application. A user must be authorized to administer a domain in order to map it to an application. For a list of available authorized domains, see AuthorizedDomains.ListAuthorizedDomains.
#
# POST /v1beta/apps/{appsId}/domainMappings
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: appengine.apps.domainMappings.create
export def "appengine-apps-domain-mappings-create" [
  apps_id: string
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
  --override-strategy: string@override-strategy-completer # Whether the domain creation should override any existing mappings for this domain. By default, overrides are rejected.
  --id: string # Relative name of the domain serving the application. Example: example.com.
  --name: string # Full path to the DomainMapping resource in the API. Example: apps/myapp/domainMapping/example.com.@OutputOnly
  --resource-records: list # The resource records required to configure this domain mapping. These records must be added to the domain's DNS configuration in order to serve the application via this domain mapping.@OutputOnly — item shape: {name?: string, rrdata?: string, type?: "A"|"AAAA"|"CNAME"}
  --ssl-settings: record # SSL configuration for a DomainMapping resource. — shape: {certificateId?: string, pendingManagedCertificateId?: string, sslManagementType?: "AUTOMATIC"|"MANUAL"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta/apps/{appsId}/domainMappings"
    path_params: [{name: appsId, var: apps_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: overrideStrategy, var: override_strategy}]
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}, {name: name, var: name}, {name: resourceRecords, var: resource_records}, {name: sslSettings, var: ssl_settings}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    apps_id: $apps_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, override_strategy: $override_strategy, id: $id, name: $name, resource_records: $resource_records, ssl_settings: $ssl_settings
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified domain mapping. A user must be authorized to administer the associated domain in order to delete a DomainMapping resource.
#
# DELETE /v1beta/apps/{appsId}/domainMappings/{domainMappingsId}
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: appengine.apps.domainMappings.delete
export def "appengine-apps-domain-mappings-delete" [
  apps_id: string
  domain_mappings_id: string
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
    path: "/v1beta/apps/{appsId}/domainMappings/{domainMappingsId}"
    path_params: [{name: appsId, var: apps_id}, {name: domainMappingsId, var: domain_mappings_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    apps_id: $apps_id, domain_mappings_id: $domain_mappings_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the specified domain mapping.
#
# GET /v1beta/apps/{appsId}/domainMappings/{domainMappingsId}
# Returns: record<id: string, name: string, resourceRecords: table<name: string, rrdata: string, type: string>, sslSettings: record<certificateId: string, pendingManagedCertificateId: string, sslManagementType: string>>
# operationId: appengine.apps.domainMappings.get
export def "appengine-apps-domain-mappings-get" [
  apps_id: string
  domain_mappings_id: string
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
    path: "/v1beta/apps/{appsId}/domainMappings/{domainMappingsId}"
    path_params: [{name: appsId, var: apps_id}, {name: domainMappingsId, var: domain_mappings_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    apps_id: $apps_id, domain_mappings_id: $domain_mappings_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the specified domain mapping. To map an SSL certificate to a domain mapping, update certificate_id to point to an AuthorizedCertificate resource. A user must be authorized to administer the associated domain in order to update a DomainMapping resource.
#
# PATCH /v1beta/apps/{appsId}/domainMappings/{domainMappingsId}
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: appengine.apps.domainMappings.patch
export def "appengine-apps-domain-mappings-patch" [
  apps_id: string
  domain_mappings_id: string
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
  --update-mask: string # Required. Standard field mask for the set of fields to be updated.
  --id: string # Relative name of the domain serving the application. Example: example.com.
  --name: string # Full path to the DomainMapping resource in the API. Example: apps/myapp/domainMapping/example.com.@OutputOnly
  --resource-records: list # The resource records required to configure this domain mapping. These records must be added to the domain's DNS configuration in order to serve the application via this domain mapping.@OutputOnly — item shape: {name?: string, rrdata?: string, type?: "A"|"AAAA"|"CNAME"}
  --ssl-settings: record # SSL configuration for a DomainMapping resource. — shape: {certificateId?: string, pendingManagedCertificateId?: string, sslManagementType?: "AUTOMATIC"|"MANUAL"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1beta/apps/{appsId}/domainMappings/{domainMappingsId}"
    path_params: [{name: appsId, var: apps_id}, {name: domainMappingsId, var: domain_mappings_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: updateMask, var: update_mask}]
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}, {name: name, var: name}, {name: resourceRecords, var: resource_records}, {name: sslSettings, var: ssl_settings}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    apps_id: $apps_id, domain_mappings_id: $domain_mappings_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, update_mask: $update_mask, id: $id, name: $name, resource_records: $resource_records, ssl_settings: $ssl_settings
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the firewall rules of an application.
#
# GET /v1beta/apps/{appsId}/firewall/ingressRules
# Returns: record<ingressRules: table<action: string, description: string, priority: int, sourceRange: string>, nextPageToken: string>
# operationId: appengine.apps.firewall.ingressRules.list
export def "appengine-apps-firewall-ingress-rules-list" [
  apps_id: string
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
  --matching-address: string # A valid IP Address. If set, only rules matching this address will be returned. The first returned rule will be the rule that fires on requests from this IP.
  --page-size: int # Maximum results to return per page.
  --page-token: string # Continuation token for fetching the next page of results.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta/apps/{appsId}/firewall/ingressRules"
    path_params: [{name: appsId, var: apps_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: matchingAddress, var: matching_address}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    apps_id: $apps_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, matching_address: $matching_address, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a firewall rule for the application.
#
# POST /v1beta/apps/{appsId}/firewall/ingressRules
# Returns: record<action: string, description: string, priority: int, sourceRange: string>
# operationId: appengine.apps.firewall.ingressRules.create
export def "appengine-apps-firewall-ingress-rules-create" [
  apps_id: string
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
  --action: string@action-completer # The action to take on matched requests.
  --description: string # An optional string description of this rule. This field has a maximum length of 400 characters.
  --priority: int # A positive integer between 1, Int32.MaxValue-1 that defines the order of rule evaluation. Rules with the lowest priority are evaluated first.A default rule at priority Int32.MaxValue matches all IPv4 and IPv6 traffic when no previous rule matches. Only the action of this rule can be modified by the user. (format: int32)
  --source-range: string # IP address or range, defined using CIDR notation, of requests that this rule applies to. You can use the wildcard character "*" to match all IPs equivalent to "0/0" and "::/0" together. Examples: 192.168.1.1 or 192.168.0.0/16 or 2001:db8::/32 or 2001:0db8:0000:0042:0000:8a2e:0370:7334. Truncation will be silently performed on addresses which are not properly truncated. For example, 1.2.3.4/24 is accepted as the same address as 1.2.3.0/24. Similarly, for IPv6, 2001:db8::1/32 is accepted as the same address as 2001:db8::/32.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta/apps/{appsId}/firewall/ingressRules"
    path_params: [{name: appsId, var: apps_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: action, var: action}, {name: description, var: description}, {name: priority, var: priority}, {name: sourceRange, var: source_range}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    apps_id: $apps_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, action: $action, description: $description, priority: $priority, source_range: $source_range
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified firewall rule.
#
# DELETE /v1beta/apps/{appsId}/firewall/ingressRules/{ingressRulesId}
# Returns: record
# operationId: appengine.apps.firewall.ingressRules.delete
export def "appengine-apps-firewall-ingress-rules-delete" [
  apps_id: string
  ingress_rules_id: string
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
    path: "/v1beta/apps/{appsId}/firewall/ingressRules/{ingressRulesId}"
    path_params: [{name: appsId, var: apps_id}, {name: ingressRulesId, var: ingress_rules_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    apps_id: $apps_id, ingress_rules_id: $ingress_rules_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the specified firewall rule.
#
# GET /v1beta/apps/{appsId}/firewall/ingressRules/{ingressRulesId}
# Returns: record<action: string, description: string, priority: int, sourceRange: string>
# operationId: appengine.apps.firewall.ingressRules.get
export def "appengine-apps-firewall-ingress-rules-get" [
  apps_id: string
  ingress_rules_id: string
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
    path: "/v1beta/apps/{appsId}/firewall/ingressRules/{ingressRulesId}"
    path_params: [{name: appsId, var: apps_id}, {name: ingressRulesId, var: ingress_rules_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    apps_id: $apps_id, ingress_rules_id: $ingress_rules_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the specified firewall rule.
#
# PATCH /v1beta/apps/{appsId}/firewall/ingressRules/{ingressRulesId}
# Returns: record<action: string, description: string, priority: int, sourceRange: string>
# operationId: appengine.apps.firewall.ingressRules.patch
export def "appengine-apps-firewall-ingress-rules-patch" [
  apps_id: string
  ingress_rules_id: string
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
  --update-mask: string # Standard field mask for the set of fields to be updated.
  --action: string@action-completer # The action to take on matched requests.
  --description: string # An optional string description of this rule. This field has a maximum length of 400 characters.
  --priority: int # A positive integer between 1, Int32.MaxValue-1 that defines the order of rule evaluation. Rules with the lowest priority are evaluated first.A default rule at priority Int32.MaxValue matches all IPv4 and IPv6 traffic when no previous rule matches. Only the action of this rule can be modified by the user. (format: int32)
  --source-range: string # IP address or range, defined using CIDR notation, of requests that this rule applies to. You can use the wildcard character "*" to match all IPs equivalent to "0/0" and "::/0" together. Examples: 192.168.1.1 or 192.168.0.0/16 or 2001:db8::/32 or 2001:0db8:0000:0042:0000:8a2e:0370:7334. Truncation will be silently performed on addresses which are not properly truncated. For example, 1.2.3.4/24 is accepted as the same address as 1.2.3.0/24. Similarly, for IPv6, 2001:db8::1/32 is accepted as the same address as 2001:db8::/32.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1beta/apps/{appsId}/firewall/ingressRules/{ingressRulesId}"
    path_params: [{name: appsId, var: apps_id}, {name: ingressRulesId, var: ingress_rules_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: updateMask, var: update_mask}]
    body: {content_type: "application/json", kind: json, fields: [{name: action, var: action}, {name: description, var: description}, {name: priority, var: priority}, {name: sourceRange, var: source_range}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    apps_id: $apps_id, ingress_rules_id: $ingress_rules_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, update_mask: $update_mask, action: $action, description: $description, priority: $priority, source_range: $source_range
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Replaces the entire firewall ruleset in one bulk operation. This overrides and replaces the rules of an existing firewall with the new rules.If the final rule does not match traffic with the '*' wildcard IP range, then an "allow all" rule is explicitly added to the end of the list.
#
# POST /v1beta/apps/{appsId}/firewall/ingressRules:batchUpdate
# Returns: record<ingressRules: table<action: string, description: string, priority: int, sourceRange: string>>
# operationId: appengine.apps.firewall.ingressRules.batchUpdate
export def "appengine-apps-firewall-ingress-rules-batch-update" [
  apps_id: string
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
  --ingress-rules: list # A list of FirewallRules to replace the existing set. — item shape: {action?: "UNSPECIFIED_ACTION"|"ALLOW"|"DENY", description?: string, priority?: int, sourceRange?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta/apps/{appsId}/firewall/ingressRules:batchUpdate"
    path_params: [{name: appsId, var: apps_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: ingressRules, var: ingress_rules}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    apps_id: $apps_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, ingress_rules: $ingress_rules
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists information about the supported locations for this service.
#
# GET /v1beta/apps/{appsId}/locations
# Returns: record<locations: table<displayName: string, labels: record, locationId: string, metadata: record, name: string>, nextPageToken: string>
# operationId: appengine.apps.locations.list
export def "appengine-apps-locations-list" [
  apps_id: string
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
    path: "/v1beta/apps/{appsId}/locations"
    path_params: [{name: appsId, var: apps_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: filter, var: filter}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    apps_id: $apps_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, filter: $filter, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about a location.
#
# GET /v1beta/apps/{appsId}/locations/{locationsId}
# Returns: record<displayName: string, labels: record, locationId: string, metadata: record, name: string>
# operationId: appengine.apps.locations.get
export def "appengine-apps-locations-get" [
  apps_id: string
  locations_id: string
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
    path: "/v1beta/apps/{appsId}/locations/{locationsId}"
    path_params: [{name: appsId, var: apps_id}, {name: locationsId, var: locations_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    apps_id: $apps_id, locations_id: $locations_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists operations that match the specified filter in the request. If the server doesn't support this method, it returns UNIMPLEMENTED.
#
# GET /v1beta/apps/{appsId}/operations
# Returns: record<nextPageToken: string, operations: table<done: bool, error: record, metadata: record, name: string, response: record>>
# operationId: appengine.apps.operations.list
export def "appengine-apps-operations-list" [
  apps_id: string
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
    path: "/v1beta/apps/{appsId}/operations"
    path_params: [{name: appsId, var: apps_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: filter, var: filter}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    apps_id: $apps_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, filter: $filter, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the latest state of a long-running operation. Clients can use this method to poll the operation result at intervals as recommended by the API service.
#
# GET /v1beta/apps/{appsId}/operations/{operationsId}
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: appengine.apps.operations.get
export def "appengine-apps-operations-get" [
  apps_id: string
  operations_id: string
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
    path: "/v1beta/apps/{appsId}/operations/{operationsId}"
    path_params: [{name: appsId, var: apps_id}, {name: operationsId, var: operations_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    apps_id: $apps_id, operations_id: $operations_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all the services in the application.
#
# GET /v1beta/apps/{appsId}/services
# Returns: record<nextPageToken: string, services: table<id: string, labels: record, name: string, networkSettings: record, split: record>>
# operationId: appengine.apps.services.list
export def "appengine-apps-services-list" [
  apps_id: string
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
  --page-size: int # Maximum results to return per page.
  --page-token: string # Continuation token for fetching the next page of results.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta/apps/{appsId}/services"
    path_params: [{name: appsId, var: apps_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    apps_id: $apps_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified service and all enclosed versions.
#
# DELETE /v1beta/apps/{appsId}/services/{servicesId}
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: appengine.apps.services.delete
export def "appengine-apps-services-delete" [
  apps_id: string
  services_id: string
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
    path: "/v1beta/apps/{appsId}/services/{servicesId}"
    path_params: [{name: appsId, var: apps_id}, {name: servicesId, var: services_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    apps_id: $apps_id, services_id: $services_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the current configuration of the specified service.
#
# GET /v1beta/apps/{appsId}/services/{servicesId}
# Returns: record<id: string, labels: record, name: string, networkSettings: record<ingressTrafficAllowed: string>, split: record<allocations: record, shardBy: string>>
# operationId: appengine.apps.services.get
export def "appengine-apps-services-get" [
  apps_id: string
  services_id: string
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
    path: "/v1beta/apps/{appsId}/services/{servicesId}"
    path_params: [{name: appsId, var: apps_id}, {name: servicesId, var: services_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    apps_id: $apps_id, services_id: $services_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the configuration of the specified service.
#
# PATCH /v1beta/apps/{appsId}/services/{servicesId}
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: appengine.apps.services.patch
export def "appengine-apps-services-patch" [
  apps_id: string
  services_id: string
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
  --migrate-traffic: oneof<nothing, bool> # Set to true to gradually shift traffic to one or more versions that you specify. By default, traffic is shifted immediately. For gradual traffic migration, the target versions must be located within instances that are configured for both warmup requests (https://cloud.google.com/appengine/docs/admin-api/reference/rest/v1beta/apps.services.versions#InboundServiceType) and automatic scaling (https://cloud.google.com/appengine/docs/admin-api/reference/rest/v1beta/apps.services.versions#AutomaticScaling). You must specify the shardBy (https://cloud.google.com/appengine/docs/admin-api/reference/rest/v1beta/apps.services#ShardBy) field in the Service resource. Gradual traffic migration is not supported in the App Engine flexible environment. For examples, see Migrating and Splitting Traffic (https://cloud.google.com/appengine/docs/admin-api/migrating-splitting-traffic).
  --update-mask: string # Required. Standard field mask for the set of fields to be updated.
  --id: string # Relative name of the service within the application. Example: default.@OutputOnly
  --labels: record # A set of labels to apply to this service. Labels are key/value pairs that describe the service and all resources that belong to it (e.g., versions). The labels can be used to search and group resources, and are propagated to the usage and billing reports, enabling fine-grain analysis of costs. An example of using labels is to tag resources belonging to different environments (e.g., "env=prod", "env=qa"). Label keys and values can be no longer than 63 characters and can only contain lowercase letters, numeric characters, underscores, dashes, and international characters. Label keys must start with a lowercase letter or an international character. Each service can have at most 32 labels.
  --name: string # Full path to the Service resource in the API. Example: apps/myapp/services/default.@OutputOnly
  --network-settings: record # A NetworkSettings resource is a container for ingress settings for a version or service. — shape: {ingressTrafficAllowed?: "INGRESS_TRAFFIC_ALLOWED_UNSPECIFIED"|"INGRESS_TRAFFIC_ALLOWED_ALL"|"INGRESS_TRAFFIC_ALLOWED_INTERNAL_ONLY"|"INGRESS_TRAFFIC_ALLOWED_INTERNAL_AND_LB"}
  --split: record # Traffic routing configuration for versions within a single service. Traffic splits define how traffic directed to the service is assigned to versions. — shape: {allocations?: record, shardBy?: "UNSPECIFIED"|"COOKIE"|"IP"|"RANDOM"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1beta/apps/{appsId}/services/{servicesId}"
    path_params: [{name: appsId, var: apps_id}, {name: servicesId, var: services_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: migrateTraffic, var: migrate_traffic}, {name: updateMask, var: update_mask}]
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}, {name: labels, var: labels}, {name: name, var: name}, {name: networkSettings, var: network_settings}, {name: split, var: split}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    apps_id: $apps_id, services_id: $services_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, migrate_traffic: $migrate_traffic, update_mask: $update_mask, id: $id, labels: $labels, name: $name, network_settings: $network_settings, split: $split
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the versions of a service.
#
# GET /v1beta/apps/{appsId}/services/{servicesId}/versions
# Returns: record<nextPageToken: string, versions: table<apiConfig: record, appEngineApis: bool, automaticScaling: record, basicScaling: record, betaSettings: record, buildEnvVariables: record, createTime: string, createdBy: string, defaultExpiration: string, deployment: record, diskUsageBytes: string, endpointsApiService: record, entrypoint: record, env: string, envVariables: record, errorHandlers: list, flexibleRuntimeSettings: record, handlers: list, healthCheck: record, id: string, inboundServices: list, instanceClass: string, libraries: list, livenessCheck: record, manualScaling: record, name: string, network: record, nobuildFilesRegex: string, readinessCheck: record, resources: record, runtime: string, runtimeApiVersion: string, runtimeChannel: string, runtimeMainExecutablePath: string, serviceAccount: string, servingStatus: string, threadsafe: bool, versionUrl: string, vm: bool, vpcAccessConnector: record, zones: list>>
# operationId: appengine.apps.services.versions.list
export def "appengine-apps-services-versions-list" [
  apps_id: string
  services_id: string
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
  --page-size: int # Maximum results to return per page.
  --page-token: string # Continuation token for fetching the next page of results.
  --view: string@view-completer-1 # Controls the set of fields returned in the List response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta/apps/{appsId}/services/{servicesId}/versions"
    path_params: [{name: appsId, var: apps_id}, {name: servicesId, var: services_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}, {name: view, var: view}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    apps_id: $apps_id, services_id: $services_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, page_size: $page_size, page_token: $page_token, view: $view
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deploys code and resource files to a new version.
#
# POST /v1beta/apps/{appsId}/services/{servicesId}/versions
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: appengine.apps.services.versions.create
export def "appengine-apps-services-versions-create" [
  apps_id: string
  services_id: string
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
  --api-config: record # Google Cloud Endpoints (https://cloud.google.com/endpoints) configuration for API handlers. — shape: {authFailAction?: "AUTH_FAIL_ACTION_UNSPECIFIED"|"AUTH_FAIL_ACTION_REDIRECT"|"AUTH_FAIL_ACTION_UNAUTHORIZED", login?: "LOGIN_UNSPECIFIED"|"LOGIN_OPTIONAL"|"LOGIN_ADMIN"|"LOGIN_REQUIRED", script?: string, securityLevel?: "SECURE_UNSPECIFIED"|"SECURE_DEFAULT"|"SECURE_NEVER"|"SECURE_OPTIONAL"|"SECURE_ALWAYS", url?: string}
  --app-engine-apis: oneof<nothing, bool> # Allows App Engine second generation runtimes to access the legacy bundled services.
  --automatic-scaling: record # Automatic scaling is based on request rate, response latencies, and other application metrics. — shape: {coolDownPeriod?: string, cpuUtilization?: record, customMetrics?: list, diskUtilization?: record, maxConcurrentRequests?: int, maxIdleInstances?: int, maxPendingLatency?: string, maxTotalInstances?: int, minIdleInstances?: int, minPendingLatency?: string, minTotalInstances?: int, networkUtilization?: record, requestUtilization?: record, standardSchedulerSettings?: record}
  --basic-scaling: record # A service with basic scaling will create an instance when the application receives a request. The instance will be turned down when the app becomes idle. Basic scaling is ideal for work that is intermittent or driven by user activity. — shape: {idleTimeout?: string, maxInstances?: int}
  --beta-settings: record # Metadata settings that are supplied to this version to enable beta runtime features.
  --build-env-variables: record # Environment variables available to the build environment.Only returned in GET requests if view=FULL is set.
  --create-time: string # Time that this version was created.@OutputOnly (format: google-datetime)
  --created-by: string # Email address of the user who created this version.@OutputOnly
  --default-expiration: string # Duration that static files should be cached by web proxies and browsers. Only applicable if the corresponding StaticFilesHandler (https://cloud.google.com/appengine/docs/admin-api/reference/rest/v1beta/apps.services.versions#StaticFilesHandler) does not specify its own expiration time.Only returned in GET requests if view=FULL is set. (format: google-duration)
  --deployment: record # Code and application artifacts used to deploy a version to App Engine. — shape: {build?: record, cloudBuildOptions?: record, container?: record, files?: record, zip?: record}
  --disk-usage-bytes: string # Total size in bytes of all the files that are included in this version and currently hosted on the App Engine disk.@OutputOnly (format: int64)
  --endpoints-api-service: record # Google Cloud Endpoints (https://cloud.google.com/endpoints) configuration. The Endpoints API Service provides tooling for serving Open API and gRPC endpoints via an NGINX proxy. Only valid for App Engine Flexible environment deployments.The fields here refer to the name and configuration ID of a "service" resource in the Service Management API (https://cloud.google.com/service-management/overview). — shape: {configId?: string, disableTraceSampling?: bool, name?: string, rolloutStrategy?: "UNSPECIFIED_ROLLOUT_STRATEGY"|"FIXED"|"MANAGED"}
  --entrypoint: record # The entrypoint for the application. — shape: {shell?: string}
  --body-env: string # App Engine execution environment for this version.Defaults to standard. (spec name: env)
  --env-variables: record # Environment variables available to the application.Only returned in GET requests if view=FULL is set.
  --error-handlers: list # Custom static error pages. Limited to 10KB per page.Only returned in GET requests if view=FULL is set. — item shape: {errorCode?: "ERROR_CODE_UNSPECIFIED"|"ERROR_CODE_DEFAULT"|"ERROR_CODE_OVER_QUOTA"|"ERROR_CODE_DOS_API_DENIAL"|"ERROR_CODE_TIMEOUT", mimeType?: string, staticFile?: string}
  --flexible-runtime-settings: record # Runtime settings for the App Engine flexible environment. — shape: {operatingSystem?: string, runtimeVersion?: string}
  --handlers: list # An ordered list of URL-matching patterns that should be applied to incoming requests. The first matching URL handles the request and other request handlers are not attempted.Only returned in GET requests if view=FULL is set. — item shape: {apiEndpoint?: record, authFailAction?: "AUTH_FAIL_ACTION_UNSPECIFIED"|"AUTH_FAIL_ACTION_REDIRECT"|"AUTH_FAIL_ACTION_UNAUTHORIZED", login?: "LOGIN_UNSPECIFIED"|"LOGIN_OPTIONAL"|"LOGIN_ADMIN"|"LOGIN_REQUIRED", redirectHttpResponseCode?: "REDIRECT_HTTP_RESPONSE_CODE_UNSPECIFIED"|"REDIRECT_HTTP_RESPONSE_CODE_301"|"REDIRECT_HTTP_RESPONSE_CODE_302"|"REDIRECT_HTTP_RESPONSE_CODE_303"|"REDIRECT_HTTP_RESPONSE_CODE_307", script?: record, ... (3 more fields)}
  --health-check: record # Health checking configuration for VM instances. Unhealthy instances are killed and replaced with new instances. Only applicable for instances in App Engine flexible environment. — shape: {checkInterval?: string, disableHealthCheck?: bool, healthyThreshold?: int, host?: string, restartThreshold?: int, timeout?: string, unhealthyThreshold?: int}
  --id: string # Relative name of the version within the service. Example: v1. Version names can contain only lowercase letters, numbers, or hyphens. Reserved names: "default", "latest", and any name with the prefix "ah-".
  --inbound-services: list<string> # Before an application can receive email or XMPP messages, the application must be configured to enable the service.
  --instance-class: string # Instance class that is used to run this version. Valid values are: AutomaticScaling: F1, F2, F4, F4_1G ManualScaling or BasicScaling: B1, B2, B4, B8, B4_1GDefaults to F1 for AutomaticScaling and B1 for ManualScaling or BasicScaling.
  --libraries: list # Configuration for third-party Python runtime libraries that are required by the application.Only returned in GET requests if view=FULL is set. — item shape: {name?: string, version?: string}
  --liveness-check: record # Health checking configuration for VM instances. Unhealthy instances are killed and replaced with new instances. — shape: {checkInterval?: string, failureThreshold?: int, host?: string, initialDelay?: string, path?: string, successThreshold?: int, timeout?: string}
  --manual-scaling: record # A service with manual scaling runs continuously, allowing you to perform complex initialization and rely on the state of its memory over time. — shape: {instances?: int}
  --name: string # Full path to the Version resource in the API. Example: apps/myapp/services/default/versions/v1.@OutputOnly
  --network: record # Extra network settings. Only applicable in the App Engine flexible environment. — shape: {forwardedPorts?: list<string>, instanceIpMode?: "INSTANCE_IP_MODE_UNSPECIFIED"|"EXTERNAL"|"INTERNAL", instanceTag?: string, name?: string, sessionAffinity?: bool, subnetworkName?: string}
  --nobuild-files-regex: string # Files that match this pattern will not be built into this version. Only applicable for Go runtimes.Only returned in GET requests if view=FULL is set.
  --readiness-check: record # Readiness checking configuration for VM instances. Unhealthy instances are removed from traffic rotation. — shape: {appStartTimeout?: string, checkInterval?: string, failureThreshold?: int, host?: string, path?: string, successThreshold?: int, timeout?: string}
  --resources: record # Machine resources for a version. — shape: {cpu?: float, diskGb?: float, kmsKeyReference?: string, memoryGb?: float, volumes?: list}
  --runtime: string # Desired runtime. Example: python27.
  --runtime-api-version: string # The version of the API in the given runtime environment. Please see the app.yaml reference for valid values at https://cloud.google.com/appengine/docs/standard//config/appref
  --runtime-channel: string # The channel of the runtime to use. Only available for some runtimes. Defaults to the default channel.
  --runtime-main-executable-path: string # The path or name of the app's main executable.
  --service-account: string # The identity that the deployed version will run as. Admin API will use the App Engine Appspot service account as default if this field is neither provided in app.yaml file nor through CLI flag.
  --serving-status: string@serving-status-completer-1 # Current serving status of this version. Only the versions with a SERVING status create instances and can be billed.SERVING_STATUS_UNSPECIFIED is an invalid value. Defaults to SERVING.
  --threadsafe: oneof<nothing, bool> # Whether multiple requests can be dispatched to this version at once.
  --version-url: string # Serving URL for this version. Example: "https://myversion-dot-myservice-dot-myapp.appspot.com"@OutputOnly
  --vm: oneof<nothing, bool> # Whether to deploy this version in a container on a virtual machine.
  --vpc-access-connector: record # VPC access connector specification. — shape: {egressSetting?: "EGRESS_SETTING_UNSPECIFIED"|"ALL_TRAFFIC"|"PRIVATE_IP_RANGES", name?: string}
  --zones: list<string> # The Google Compute Engine zones that are supported by this version in the App Engine flexible environment. Deprecated.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta/apps/{appsId}/services/{servicesId}/versions"
    path_params: [{name: appsId, var: apps_id}, {name: servicesId, var: services_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: apiConfig, var: api_config}, {name: appEngineApis, var: app_engine_apis}, {name: automaticScaling, var: automatic_scaling}, {name: basicScaling, var: basic_scaling}, {name: betaSettings, var: beta_settings}, {name: buildEnvVariables, var: build_env_variables}, {name: createTime, var: create_time}, {name: createdBy, var: created_by}, {name: defaultExpiration, var: default_expiration}, {name: deployment, var: deployment}, {name: diskUsageBytes, var: disk_usage_bytes}, {name: endpointsApiService, var: endpoints_api_service}, {name: entrypoint, var: entrypoint}, {name: env, var: body_env}, {name: envVariables, var: env_variables}, {name: errorHandlers, var: error_handlers}, {name: flexibleRuntimeSettings, var: flexible_runtime_settings}, {name: handlers, var: handlers}, {name: healthCheck, var: health_check}, {name: id, var: id}, {name: inboundServices, var: inbound_services}, {name: instanceClass, var: instance_class}, {name: libraries, var: libraries}, {name: livenessCheck, var: liveness_check}, {name: manualScaling, var: manual_scaling}, {name: name, var: name}, {name: network, var: network}, {name: nobuildFilesRegex, var: nobuild_files_regex}, {name: readinessCheck, var: readiness_check}, {name: resources, var: resources}, {name: runtime, var: runtime}, {name: runtimeApiVersion, var: runtime_api_version}, {name: runtimeChannel, var: runtime_channel}, {name: runtimeMainExecutablePath, var: runtime_main_executable_path}, {name: serviceAccount, var: service_account}, {name: servingStatus, var: serving_status}, {name: threadsafe, var: threadsafe}, {name: versionUrl, var: version_url}, {name: vm, var: vm}, {name: vpcAccessConnector, var: vpc_access_connector}, {name: zones, var: zones}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    apps_id: $apps_id, services_id: $services_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, api_config: $api_config, app_engine_apis: $app_engine_apis, automatic_scaling: $automatic_scaling, basic_scaling: $basic_scaling, beta_settings: $beta_settings, build_env_variables: $build_env_variables, create_time: $create_time, created_by: $created_by, default_expiration: $default_expiration, deployment: $deployment, disk_usage_bytes: $disk_usage_bytes, endpoints_api_service: $endpoints_api_service, entrypoint: $entrypoint, body_env: $body_env, env_variables: $env_variables, error_handlers: $error_handlers, flexible_runtime_settings: $flexible_runtime_settings, handlers: $handlers, health_check: $health_check, id: $id, inbound_services: $inbound_services, instance_class: $instance_class, libraries: $libraries, liveness_check: $liveness_check, manual_scaling: $manual_scaling, name: $name, network: $network, nobuild_files_regex: $nobuild_files_regex, readiness_check: $readiness_check, resources: $resources, runtime: $runtime, runtime_api_version: $runtime_api_version, runtime_channel: $runtime_channel, runtime_main_executable_path: $runtime_main_executable_path, service_account: $service_account, serving_status: $serving_status, threadsafe: $threadsafe, version_url: $version_url, vm: $vm, vpc_access_connector: $vpc_access_connector, zones: $zones
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an existing Version resource.
#
# DELETE /v1beta/apps/{appsId}/services/{servicesId}/versions/{versionsId}
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: appengine.apps.services.versions.delete
export def "appengine-apps-services-versions-delete" [
  apps_id: string
  services_id: string
  versions_id: string
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
    path: "/v1beta/apps/{appsId}/services/{servicesId}/versions/{versionsId}"
    path_params: [{name: appsId, var: apps_id}, {name: servicesId, var: services_id}, {name: versionsId, var: versions_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    apps_id: $apps_id, services_id: $services_id, versions_id: $versions_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the specified Version resource. By default, only a BASIC_VIEW will be returned. Specify the FULL_VIEW parameter to get the full resource.
#
# GET /v1beta/apps/{appsId}/services/{servicesId}/versions/{versionsId}
# Returns: record<apiConfig: record<authFailAction: string, login: string, script: string, securityLevel: string, url: string>, appEngineApis: bool, automaticScaling: record<coolDownPeriod: string, cpuUtilization: record<aggregationWindowLength: string, targetUtilization: float>, customMetrics: list<record>, diskUtilization: record<targetReadBytesPerSecond: int, targetReadOpsPerSecond: int, targetWriteBytesPerSecond: int, targetWriteOpsPerSecond: int>, maxConcurrentRequests: int, maxIdleInstances: int, maxPendingLatency: string, maxTotalInstances: int, minIdleInstances: int, minPendingLatency: string, minTotalInstances: int, networkUtilization: record<targetReceivedBytesPerSecond: int, targetReceivedPacketsPerSecond: int, targetSentBytesPerSecond: int, targetSentPacketsPerSecond: int>, requestUtilization: record<targetConcurrentRequests: int, targetRequestCountPerSecond: int>, standardSchedulerSettings: record<maxInstances: int, minInstances: int, targetCpuUtilization: float, targetThroughputUtilization: float>>, basicScaling: record<idleTimeout: string, maxInstances: int>, betaSettings: record, buildEnvVariables: record, createTime: string, createdBy: string, defaultExpiration: string, deployment: record<build: record<cloudBuildId: string>, cloudBuildOptions: record<appYamlPath: string, cloudBuildTimeout: string>, container: record<image: string>, files: record, zip: record<filesCount: int, sourceUrl: string>>, diskUsageBytes: string, endpointsApiService: record<configId: string, disableTraceSampling: bool, name: string, rolloutStrategy: string>, entrypoint: record<shell: string>, env: string, envVariables: record, errorHandlers: table<errorCode: string, mimeType: string, staticFile: string>, flexibleRuntimeSettings: record<operatingSystem: string, runtimeVersion: string>, handlers: table<apiEndpoint: record, authFailAction: string, login: string, redirectHttpResponseCode: string, script: record, securityLevel: string, staticFiles: record, urlRegex: string>, healthCheck: record<checkInterval: string, disableHealthCheck: bool, healthyThreshold: int, host: string, restartThreshold: int, timeout: string, unhealthyThreshold: int>, id: string, inboundServices: list<string>, instanceClass: string, libraries: table<name: string, version: string>, livenessCheck: record<checkInterval: string, failureThreshold: int, host: string, initialDelay: string, path: string, successThreshold: int, timeout: string>, manualScaling: record<instances: int>, name: string, network: record<forwardedPorts: list<string>, instanceIpMode: string, instanceTag: string, name: string, sessionAffinity: bool, subnetworkName: string>, nobuildFilesRegex: string, readinessCheck: record<appStartTimeout: string, checkInterval: string, failureThreshold: int, host: string, path: string, successThreshold: int, timeout: string>, resources: record<cpu: float, diskGb: float, kmsKeyReference: string, memoryGb: float, volumes: list<record>>, runtime: string, runtimeApiVersion: string, runtimeChannel: string, runtimeMainExecutablePath: string, serviceAccount: string, servingStatus: string, threadsafe: bool, versionUrl: string, vm: bool, vpcAccessConnector: record<egressSetting: string, name: string>, zones: list<string>>
# operationId: appengine.apps.services.versions.get
export def "appengine-apps-services-versions-get" [
  apps_id: string
  services_id: string
  versions_id: string
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
  --view: string@view-completer-1 # Controls the set of fields returned in the Get response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta/apps/{appsId}/services/{servicesId}/versions/{versionsId}"
    path_params: [{name: appsId, var: apps_id}, {name: servicesId, var: services_id}, {name: versionsId, var: versions_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: view, var: view}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    apps_id: $apps_id, services_id: $services_id, versions_id: $versions_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, view: $view
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the specified Version resource. You can specify the following fields depending on the App Engine environment and type of scaling that the version resource uses:Standard environment instance_class (https://cloud.google.com/appengine/docs/admin-api/reference/rest/v1beta/apps.services.versions#Version.FIELDS.instance_class)automatic scaling in the standard environment: automatic_scaling.min_idle_instances (https://cloud.google.com/appengine/docs/admin-api/reference/rest/v1beta/apps.services.versions#Version.FIELDS.automatic_scaling) automatic_scaling.max_idle_instances (https://cloud.google.com/appengine/docs/admin-api/reference/rest/v1beta/apps.services.versions#Version.FIELDS.automatic_scaling) automaticScaling.standard_scheduler_settings.max_instances (https://cloud.google.com/appengine/docs/admin-api/reference/rest/v1beta/apps.services.versions#StandardSchedulerSettings) automaticScaling.standard_scheduler_settings.min_instances (https://cloud.google.com/appengine/docs/admin-api/reference/rest/v1beta/apps.services.versions#StandardSchedulerSettings) automaticScaling.standard_scheduler_settings.target_cpu_utilization (https://cloud.google.com/appengine/docs/admin-api/reference/rest/v1beta/apps.services.versions#StandardSchedulerSettings) automaticScaling.standard_scheduler_settings.target_throughput_utilization (https://cloud.google.com/appengine/docs/admin-api/reference/rest/v1beta/apps.services.versions#StandardSchedulerSettings)basic scaling or manual scaling in the standard environment: serving_status (https://cloud.google.com/appengine/docs/admin-api/reference/rest/v1beta/apps.services.versions#Version.FIELDS.serving_status) manual_scaling.instances (https://cloud.google.com/appengine/docs/admin-api/reference/rest/v1beta/apps.services.versions#manualscaling)Flexible environment serving_status (https://cloud.google.com/appengine/docs/admin-api/reference/rest/v1beta/apps.services.versions#Version.FIELDS.serving_status)automatic scaling in the flexible environment: automatic_scaling.min_total_instances (https://cloud.google.com/appengine/docs/admin-api/reference/rest/v1beta/apps.services.versions#Version.FIELDS.automatic_scaling) automatic_scaling.max_total_instances (https://cloud.google.com/appengine/docs/admin-api/reference/rest/v1beta/apps.services.versions#Version.FIELDS.automatic_scaling) automatic_scaling.cool_down_period_sec (https://cloud.google.com/appengine/docs/admin-api/reference/rest/v1beta/apps.services.versions#Version.FIELDS.automatic_scaling) automatic_scaling.cpu_utilization.target_utilization (https://cloud.google.com/appengine/docs/admin-api/reference/rest/v1beta/apps.services.versions#Version.FIELDS.automatic_scaling)manual scaling in the flexible environment: manual_scaling.instances (https://cloud.google.com/appengine/docs/admin-api/reference/rest/v1beta/apps.services.versions#manualscaling)
#
# PATCH /v1beta/apps/{appsId}/services/{servicesId}/versions/{versionsId}
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: appengine.apps.services.versions.patch
export def "appengine-apps-services-versions-patch" [
  apps_id: string
  services_id: string
  versions_id: string
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
  --update-mask: string # Standard field mask for the set of fields to be updated.
  --api-config: record # Google Cloud Endpoints (https://cloud.google.com/endpoints) configuration for API handlers. — shape: {authFailAction?: "AUTH_FAIL_ACTION_UNSPECIFIED"|"AUTH_FAIL_ACTION_REDIRECT"|"AUTH_FAIL_ACTION_UNAUTHORIZED", login?: "LOGIN_UNSPECIFIED"|"LOGIN_OPTIONAL"|"LOGIN_ADMIN"|"LOGIN_REQUIRED", script?: string, securityLevel?: "SECURE_UNSPECIFIED"|"SECURE_DEFAULT"|"SECURE_NEVER"|"SECURE_OPTIONAL"|"SECURE_ALWAYS", url?: string}
  --app-engine-apis: oneof<nothing, bool> # Allows App Engine second generation runtimes to access the legacy bundled services.
  --automatic-scaling: record # Automatic scaling is based on request rate, response latencies, and other application metrics. — shape: {coolDownPeriod?: string, cpuUtilization?: record, customMetrics?: list, diskUtilization?: record, maxConcurrentRequests?: int, maxIdleInstances?: int, maxPendingLatency?: string, maxTotalInstances?: int, minIdleInstances?: int, minPendingLatency?: string, minTotalInstances?: int, networkUtilization?: record, requestUtilization?: record, standardSchedulerSettings?: record}
  --basic-scaling: record # A service with basic scaling will create an instance when the application receives a request. The instance will be turned down when the app becomes idle. Basic scaling is ideal for work that is intermittent or driven by user activity. — shape: {idleTimeout?: string, maxInstances?: int}
  --beta-settings: record # Metadata settings that are supplied to this version to enable beta runtime features.
  --build-env-variables: record # Environment variables available to the build environment.Only returned in GET requests if view=FULL is set.
  --create-time: string # Time that this version was created.@OutputOnly (format: google-datetime)
  --created-by: string # Email address of the user who created this version.@OutputOnly
  --default-expiration: string # Duration that static files should be cached by web proxies and browsers. Only applicable if the corresponding StaticFilesHandler (https://cloud.google.com/appengine/docs/admin-api/reference/rest/v1beta/apps.services.versions#StaticFilesHandler) does not specify its own expiration time.Only returned in GET requests if view=FULL is set. (format: google-duration)
  --deployment: record # Code and application artifacts used to deploy a version to App Engine. — shape: {build?: record, cloudBuildOptions?: record, container?: record, files?: record, zip?: record}
  --disk-usage-bytes: string # Total size in bytes of all the files that are included in this version and currently hosted on the App Engine disk.@OutputOnly (format: int64)
  --endpoints-api-service: record # Google Cloud Endpoints (https://cloud.google.com/endpoints) configuration. The Endpoints API Service provides tooling for serving Open API and gRPC endpoints via an NGINX proxy. Only valid for App Engine Flexible environment deployments.The fields here refer to the name and configuration ID of a "service" resource in the Service Management API (https://cloud.google.com/service-management/overview). — shape: {configId?: string, disableTraceSampling?: bool, name?: string, rolloutStrategy?: "UNSPECIFIED_ROLLOUT_STRATEGY"|"FIXED"|"MANAGED"}
  --entrypoint: record # The entrypoint for the application. — shape: {shell?: string}
  --body-env: string # App Engine execution environment for this version.Defaults to standard. (spec name: env)
  --env-variables: record # Environment variables available to the application.Only returned in GET requests if view=FULL is set.
  --error-handlers: list # Custom static error pages. Limited to 10KB per page.Only returned in GET requests if view=FULL is set. — item shape: {errorCode?: "ERROR_CODE_UNSPECIFIED"|"ERROR_CODE_DEFAULT"|"ERROR_CODE_OVER_QUOTA"|"ERROR_CODE_DOS_API_DENIAL"|"ERROR_CODE_TIMEOUT", mimeType?: string, staticFile?: string}
  --flexible-runtime-settings: record # Runtime settings for the App Engine flexible environment. — shape: {operatingSystem?: string, runtimeVersion?: string}
  --handlers: list # An ordered list of URL-matching patterns that should be applied to incoming requests. The first matching URL handles the request and other request handlers are not attempted.Only returned in GET requests if view=FULL is set. — item shape: {apiEndpoint?: record, authFailAction?: "AUTH_FAIL_ACTION_UNSPECIFIED"|"AUTH_FAIL_ACTION_REDIRECT"|"AUTH_FAIL_ACTION_UNAUTHORIZED", login?: "LOGIN_UNSPECIFIED"|"LOGIN_OPTIONAL"|"LOGIN_ADMIN"|"LOGIN_REQUIRED", redirectHttpResponseCode?: "REDIRECT_HTTP_RESPONSE_CODE_UNSPECIFIED"|"REDIRECT_HTTP_RESPONSE_CODE_301"|"REDIRECT_HTTP_RESPONSE_CODE_302"|"REDIRECT_HTTP_RESPONSE_CODE_303"|"REDIRECT_HTTP_RESPONSE_CODE_307", script?: record, ... (3 more fields)}
  --health-check: record # Health checking configuration for VM instances. Unhealthy instances are killed and replaced with new instances. Only applicable for instances in App Engine flexible environment. — shape: {checkInterval?: string, disableHealthCheck?: bool, healthyThreshold?: int, host?: string, restartThreshold?: int, timeout?: string, unhealthyThreshold?: int}
  --id: string # Relative name of the version within the service. Example: v1. Version names can contain only lowercase letters, numbers, or hyphens. Reserved names: "default", "latest", and any name with the prefix "ah-".
  --inbound-services: list<string> # Before an application can receive email or XMPP messages, the application must be configured to enable the service.
  --instance-class: string # Instance class that is used to run this version. Valid values are: AutomaticScaling: F1, F2, F4, F4_1G ManualScaling or BasicScaling: B1, B2, B4, B8, B4_1GDefaults to F1 for AutomaticScaling and B1 for ManualScaling or BasicScaling.
  --libraries: list # Configuration for third-party Python runtime libraries that are required by the application.Only returned in GET requests if view=FULL is set. — item shape: {name?: string, version?: string}
  --liveness-check: record # Health checking configuration for VM instances. Unhealthy instances are killed and replaced with new instances. — shape: {checkInterval?: string, failureThreshold?: int, host?: string, initialDelay?: string, path?: string, successThreshold?: int, timeout?: string}
  --manual-scaling: record # A service with manual scaling runs continuously, allowing you to perform complex initialization and rely on the state of its memory over time. — shape: {instances?: int}
  --name: string # Full path to the Version resource in the API. Example: apps/myapp/services/default/versions/v1.@OutputOnly
  --network: record # Extra network settings. Only applicable in the App Engine flexible environment. — shape: {forwardedPorts?: list<string>, instanceIpMode?: "INSTANCE_IP_MODE_UNSPECIFIED"|"EXTERNAL"|"INTERNAL", instanceTag?: string, name?: string, sessionAffinity?: bool, subnetworkName?: string}
  --nobuild-files-regex: string # Files that match this pattern will not be built into this version. Only applicable for Go runtimes.Only returned in GET requests if view=FULL is set.
  --readiness-check: record # Readiness checking configuration for VM instances. Unhealthy instances are removed from traffic rotation. — shape: {appStartTimeout?: string, checkInterval?: string, failureThreshold?: int, host?: string, path?: string, successThreshold?: int, timeout?: string}
  --resources: record # Machine resources for a version. — shape: {cpu?: float, diskGb?: float, kmsKeyReference?: string, memoryGb?: float, volumes?: list}
  --runtime: string # Desired runtime. Example: python27.
  --runtime-api-version: string # The version of the API in the given runtime environment. Please see the app.yaml reference for valid values at https://cloud.google.com/appengine/docs/standard//config/appref
  --runtime-channel: string # The channel of the runtime to use. Only available for some runtimes. Defaults to the default channel.
  --runtime-main-executable-path: string # The path or name of the app's main executable.
  --service-account: string # The identity that the deployed version will run as. Admin API will use the App Engine Appspot service account as default if this field is neither provided in app.yaml file nor through CLI flag.
  --serving-status: string@serving-status-completer-1 # Current serving status of this version. Only the versions with a SERVING status create instances and can be billed.SERVING_STATUS_UNSPECIFIED is an invalid value. Defaults to SERVING.
  --threadsafe: oneof<nothing, bool> # Whether multiple requests can be dispatched to this version at once.
  --version-url: string # Serving URL for this version. Example: "https://myversion-dot-myservice-dot-myapp.appspot.com"@OutputOnly
  --vm: oneof<nothing, bool> # Whether to deploy this version in a container on a virtual machine.
  --vpc-access-connector: record # VPC access connector specification. — shape: {egressSetting?: "EGRESS_SETTING_UNSPECIFIED"|"ALL_TRAFFIC"|"PRIVATE_IP_RANGES", name?: string}
  --zones: list<string> # The Google Compute Engine zones that are supported by this version in the App Engine flexible environment. Deprecated.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1beta/apps/{appsId}/services/{servicesId}/versions/{versionsId}"
    path_params: [{name: appsId, var: apps_id}, {name: servicesId, var: services_id}, {name: versionsId, var: versions_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: updateMask, var: update_mask}]
    body: {content_type: "application/json", kind: json, fields: [{name: apiConfig, var: api_config}, {name: appEngineApis, var: app_engine_apis}, {name: automaticScaling, var: automatic_scaling}, {name: basicScaling, var: basic_scaling}, {name: betaSettings, var: beta_settings}, {name: buildEnvVariables, var: build_env_variables}, {name: createTime, var: create_time}, {name: createdBy, var: created_by}, {name: defaultExpiration, var: default_expiration}, {name: deployment, var: deployment}, {name: diskUsageBytes, var: disk_usage_bytes}, {name: endpointsApiService, var: endpoints_api_service}, {name: entrypoint, var: entrypoint}, {name: env, var: body_env}, {name: envVariables, var: env_variables}, {name: errorHandlers, var: error_handlers}, {name: flexibleRuntimeSettings, var: flexible_runtime_settings}, {name: handlers, var: handlers}, {name: healthCheck, var: health_check}, {name: id, var: id}, {name: inboundServices, var: inbound_services}, {name: instanceClass, var: instance_class}, {name: libraries, var: libraries}, {name: livenessCheck, var: liveness_check}, {name: manualScaling, var: manual_scaling}, {name: name, var: name}, {name: network, var: network}, {name: nobuildFilesRegex, var: nobuild_files_regex}, {name: readinessCheck, var: readiness_check}, {name: resources, var: resources}, {name: runtime, var: runtime}, {name: runtimeApiVersion, var: runtime_api_version}, {name: runtimeChannel, var: runtime_channel}, {name: runtimeMainExecutablePath, var: runtime_main_executable_path}, {name: serviceAccount, var: service_account}, {name: servingStatus, var: serving_status}, {name: threadsafe, var: threadsafe}, {name: versionUrl, var: version_url}, {name: vm, var: vm}, {name: vpcAccessConnector, var: vpc_access_connector}, {name: zones, var: zones}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    apps_id: $apps_id, services_id: $services_id, versions_id: $versions_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, update_mask: $update_mask, api_config: $api_config, app_engine_apis: $app_engine_apis, automatic_scaling: $automatic_scaling, basic_scaling: $basic_scaling, beta_settings: $beta_settings, build_env_variables: $build_env_variables, create_time: $create_time, created_by: $created_by, default_expiration: $default_expiration, deployment: $deployment, disk_usage_bytes: $disk_usage_bytes, endpoints_api_service: $endpoints_api_service, entrypoint: $entrypoint, body_env: $body_env, env_variables: $env_variables, error_handlers: $error_handlers, flexible_runtime_settings: $flexible_runtime_settings, handlers: $handlers, health_check: $health_check, id: $id, inbound_services: $inbound_services, instance_class: $instance_class, libraries: $libraries, liveness_check: $liveness_check, manual_scaling: $manual_scaling, name: $name, network: $network, nobuild_files_regex: $nobuild_files_regex, readiness_check: $readiness_check, resources: $resources, runtime: $runtime, runtime_api_version: $runtime_api_version, runtime_channel: $runtime_channel, runtime_main_executable_path: $runtime_main_executable_path, service_account: $service_account, serving_status: $serving_status, threadsafe: $threadsafe, version_url: $version_url, vm: $vm, vpc_access_connector: $vpc_access_connector, zones: $zones
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the instances of a version.Tip: To aggregate details about instances over time, see the Stackdriver Monitoring API (https://cloud.google.com/monitoring/api/ref_v3/rest/v3/projects.timeSeries/list).
#
# GET /v1beta/apps/{appsId}/services/{servicesId}/versions/{versionsId}/instances
# Returns: record<instances: table<appEngineRelease: string, availability: string, averageLatency: int, errors: int, id: string, memoryUsage: string, name: string, qps: float, requests: int, startTime: string, vmDebugEnabled: bool, vmId: string, vmIp: string, vmLiveness: string, vmName: string, vmStatus: string, vmZoneName: string>, nextPageToken: string>
# operationId: appengine.apps.services.versions.instances.list
export def "appengine-apps-services-versions-instances-list" [
  apps_id: string
  services_id: string
  versions_id: string
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
  --page-size: int # Maximum results to return per page.
  --page-token: string # Continuation token for fetching the next page of results.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta/apps/{appsId}/services/{servicesId}/versions/{versionsId}/instances"
    path_params: [{name: appsId, var: apps_id}, {name: servicesId, var: services_id}, {name: versionsId, var: versions_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    apps_id: $apps_id, services_id: $services_id, versions_id: $versions_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stops a running instance.The instance might be automatically recreated based on the scaling settings of the version. For more information, see "How Instances are Managed" (standard environment (https://cloud.google.com/appengine/docs/standard/python/how-instances-are-managed) | flexible environment (https://cloud.google.com/appengine/docs/flexible/python/how-instances-are-managed)).To ensure that instances are not re-created and avoid getting billed, you can stop all instances within the target version by changing the serving status of the version to STOPPED with the apps.services.versions.patch (https://cloud.google.com/appengine/docs/admin-api/reference/rest/v1/apps.services.versions/patch) method.
#
# DELETE /v1beta/apps/{appsId}/services/{servicesId}/versions/{versionsId}/instances/{instancesId}
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: appengine.apps.services.versions.instances.delete
export def "appengine-apps-services-versions-instances-delete" [
  apps_id: string
  services_id: string
  versions_id: string
  instances_id: string
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
    path: "/v1beta/apps/{appsId}/services/{servicesId}/versions/{versionsId}/instances/{instancesId}"
    path_params: [{name: appsId, var: apps_id}, {name: servicesId, var: services_id}, {name: versionsId, var: versions_id}, {name: instancesId, var: instances_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    apps_id: $apps_id, services_id: $services_id, versions_id: $versions_id, instances_id: $instances_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets instance information.
#
# GET /v1beta/apps/{appsId}/services/{servicesId}/versions/{versionsId}/instances/{instancesId}
# Returns: record<appEngineRelease: string, availability: string, averageLatency: int, errors: int, id: string, memoryUsage: string, name: string, qps: float, requests: int, startTime: string, vmDebugEnabled: bool, vmId: string, vmIp: string, vmLiveness: string, vmName: string, vmStatus: string, vmZoneName: string>
# operationId: appengine.apps.services.versions.instances.get
export def "appengine-apps-services-versions-instances-get" [
  apps_id: string
  services_id: string
  versions_id: string
  instances_id: string
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
    path: "/v1beta/apps/{appsId}/services/{servicesId}/versions/{versionsId}/instances/{instancesId}"
    path_params: [{name: appsId, var: apps_id}, {name: servicesId, var: services_id}, {name: versionsId, var: versions_id}, {name: instancesId, var: instances_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    apps_id: $apps_id, services_id: $services_id, versions_id: $versions_id, instances_id: $instances_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enables debugging on a VM instance. This allows you to use the SSH command to connect to the virtual machine where the instance lives. While in "debug mode", the instance continues to serve live traffic. You should delete the instance when you are done debugging and then allow the system to take over and determine if another instance should be started.Only applicable for instances in App Engine flexible environment.
#
# POST /v1beta/apps/{appsId}/services/{servicesId}/versions/{versionsId}/instances/{instancesId}:debug
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: appengine.apps.services.versions.instances.debug
export def "appengine-apps-services-versions-instances-debug" [
  apps_id: string
  services_id: string
  versions_id: string
  instances_id: string
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
  --ssh-key: string # Public SSH key to add to the instance. Examples: [USERNAME]:ssh-rsa [KEY_VALUE] [USERNAME] [USERNAME]:ssh-rsa [KEY_VALUE] google-ssh {"userName":"[USERNAME]","expireOn":"[EXPIRE_TIME]"}For more information, see Adding and Removing SSH Keys (https://cloud.google.com/compute/docs/instances/adding-removing-ssh-keys).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta/apps/{appsId}/services/{servicesId}/versions/{versionsId}/instances/{instancesId}:debug"
    path_params: [{name: appsId, var: apps_id}, {name: servicesId, var: services_id}, {name: versionsId, var: versions_id}, {name: instancesId, var: instances_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: sshKey, var: ssh_key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    apps_id: $apps_id, services_id: $services_id, versions_id: $versions_id, instances_id: $instances_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, ssh_key: $ssh_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Recreates the required App Engine features for the specified App Engine application, for example a Cloud Storage bucket or App Engine service account. Use this method if you receive an error message about a missing feature, for example, Error retrieving the App Engine service account. If you have deleted your App Engine service account, this will not be able to recreate it. Instead, you should attempt to use the IAM undelete API if possible at https://cloud.google.com/iam/reference/rest/v1/projects.serviceAccounts/undelete?apix_params=%7B"name"%3A"projects%2F-%2FserviceAccounts%2Funique_id"%2C"resource"%3A%7B%7D%7D . If the deletion was recent, the numeric ID can be found in the Cloud Console Activity Log.
#
# POST /v1beta/apps/{appsId}:repair
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: appengine.apps.repair
export def "appengine-apps-repair" [
  apps_id: string
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
    path: "/v1beta/apps/{appsId}:repair"
    path_params: [{name: appsId, var: apps_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    apps_id: $apps_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists information about the supported locations for this service.
#
# GET /v1beta/projects/{projectsId}/locations
# Returns: record<locations: table<displayName: string, labels: record, locationId: string, metadata: record, name: string>, nextPageToken: string>
# operationId: appengine.projects.locations.list
export def "appengine-projects-locations-list" [
  projects_id: string
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
    path: "/v1beta/projects/{projectsId}/locations"
    path_params: [{name: projectsId, var: projects_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: filter, var: filter}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    projects_id: $projects_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, filter: $filter, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about a location.
#
# GET /v1beta/projects/{projectsId}/locations/{locationsId}
# Returns: record<displayName: string, labels: record, locationId: string, metadata: record, name: string>
# operationId: appengine.projects.locations.get
export def "appengine-projects-locations-get" [
  projects_id: string
  locations_id: string
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
    path: "/v1beta/projects/{projectsId}/locations/{locationsId}"
    path_params: [{name: projectsId, var: projects_id}, {name: locationsId, var: locations_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    projects_id: $projects_id, locations_id: $locations_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an App Engine application for a Google Cloud Platform project. Required fields: id - The ID of the target Cloud Platform project. location - The region (https://cloud.google.com/appengine/docs/locations) where you want the App Engine application located.For more information about App Engine applications, see Managing Projects, Applications, and Billing (https://cloud.google.com/appengine/docs/standard/python/console/).
#
# POST /v1beta/projects/{projectsId}/locations/{locationsId}/applications
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: appengine.projects.locations.applications.create
export def "appengine-projects-locations-applications-create" [
  projects_id: string
  locations_id: string
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
  --auth-domain: string # Google Apps authentication domain that controls which users can access this application.Defaults to open access for any Google Account.
  --database-type: string@database-type-completer # The type of the Cloud Firestore or Cloud Datastore database associated with this application.
  --default-cookie-expiration: string # Cookie expiration policy for this application. (format: google-duration)
  --dispatch-rules: list # HTTP path dispatch rules for requests to the application that do not explicitly target a service or version. Rules are order-dependent. Up to 20 dispatch rules can be supported. — item shape: {domain?: string, path?: string, service?: string}
  --feature-settings: record # The feature specific settings to be used in the application. These define behaviors that are user configurable. — shape: {splitHealthChecks?: bool, useContainerOptimizedOs?: bool}
  --iap: record # Identity-Aware Proxy — shape: {enabled?: bool, oauth2ClientId?: string, oauth2ClientSecret?: string}
  --id: string # Identifier of the Application resource. This identifier is equivalent to the project ID of the Google Cloud Platform project where you want to deploy your application. Example: myapp.
  --location-id: string # Location from which this application runs. Application instances run out of the data centers in the specified location, which is also where all of the application's end user content is stored.Defaults to us-central.View the list of supported locations (https://cloud.google.com/appengine/docs/locations).
  --service-account: string # The service account associated with the application. This is the app-level default identity. If no identity provided during create version, Admin API will fallback to this one.
  --serving-status: string@serving-status-completer # Serving status of this application.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta/projects/{projectsId}/locations/{locationsId}/applications"
    path_params: [{name: projectsId, var: projects_id}, {name: locationsId, var: locations_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: authDomain, var: auth_domain}, {name: databaseType, var: database_type}, {name: defaultCookieExpiration, var: default_cookie_expiration}, {name: dispatchRules, var: dispatch_rules}, {name: featureSettings, var: feature_settings}, {name: iap, var: iap}, {name: id, var: id}, {name: locationId, var: location_id}, {name: serviceAccount, var: service_account}, {name: servingStatus, var: serving_status}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    projects_id: $projects_id, locations_id: $locations_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, auth_domain: $auth_domain, database_type: $database_type, default_cookie_expiration: $default_cookie_expiration, dispatch_rules: $dispatch_rules, feature_settings: $feature_settings, iap: $iap, id: $id, location_id: $location_id, service_account: $service_account, serving_status: $serving_status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about an application.
#
# GET /v1beta/projects/{projectsId}/locations/{locationsId}/applications/{applicationsId}
# Returns: record<authDomain: string, codeBucket: string, databaseType: string, defaultBucket: string, defaultCookieExpiration: string, defaultHostname: string, dispatchRules: table<domain: string, path: string, service: string>, featureSettings: record<splitHealthChecks: bool, useContainerOptimizedOs: bool>, gcrDomain: string, iap: record<enabled: bool, oauth2ClientId: string, oauth2ClientSecret: string, oauth2ClientSecretSha256: string>, id: string, locationId: string, name: string, serviceAccount: string, servingStatus: string>
# operationId: appengine.projects.locations.applications.get
export def "appengine-projects-locations-applications-get" [
  projects_id: string
  locations_id: string
  applications_id: string
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
    path: "/v1beta/projects/{projectsId}/locations/{locationsId}/applications/{applicationsId}"
    path_params: [{name: projectsId, var: projects_id}, {name: locationsId, var: locations_id}, {name: applicationsId, var: applications_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    projects_id: $projects_id, locations_id: $locations_id, applications_id: $applications_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Recreates the required App Engine features for the specified App Engine application, for example a Cloud Storage bucket or App Engine service account. Use this method if you receive an error message about a missing feature, for example, Error retrieving the App Engine service account. If you have deleted your App Engine service account, this will not be able to recreate it. Instead, you should attempt to use the IAM undelete API if possible at https://cloud.google.com/iam/reference/rest/v1/projects.serviceAccounts/undelete?apix_params=%7B"name"%3A"projects%2F-%2FserviceAccounts%2Funique_id"%2C"resource"%3A%7B%7D%7D . If the deletion was recent, the numeric ID can be found in the Cloud Console Activity Log.
#
# POST /v1beta/projects/{projectsId}/locations/{locationsId}/applications/{applicationsId}:repair
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: appengine.projects.locations.applications.repair
export def "appengine-projects-locations-applications-repair" [
  projects_id: string
  locations_id: string
  applications_id: string
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
    path: "/v1beta/projects/{projectsId}/locations/{locationsId}/applications/{applicationsId}:repair"
    path_params: [{name: projectsId, var: projects_id}, {name: locationsId, var: locations_id}, {name: applicationsId, var: applications_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    projects_id: $projects_id, locations_id: $locations_id, applications_id: $applications_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists operations that match the specified filter in the request. If the server doesn't support this method, it returns UNIMPLEMENTED.
#
# GET /v1beta/projects/{projectsId}/locations/{locationsId}/operations
# Returns: record<nextPageToken: string, operations: table<done: bool, error: record, metadata: record, name: string, response: record>>
# operationId: appengine.projects.locations.operations.list
export def "appengine-projects-locations-operations-list" [
  projects_id: string
  locations_id: string
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
    path: "/v1beta/projects/{projectsId}/locations/{locationsId}/operations"
    path_params: [{name: projectsId, var: projects_id}, {name: locationsId, var: locations_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: filter, var: filter}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    projects_id: $projects_id, locations_id: $locations_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, filter: $filter, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the latest state of a long-running operation. Clients can use this method to poll the operation result at intervals as recommended by the API service.
#
# GET /v1beta/projects/{projectsId}/locations/{locationsId}/operations/{operationsId}
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: appengine.projects.locations.operations.get
export def "appengine-projects-locations-operations-get" [
  projects_id: string
  locations_id: string
  operations_id: string
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
    path: "/v1beta/projects/{projectsId}/locations/{locationsId}/operations/{operationsId}"
    path_params: [{name: projectsId, var: projects_id}, {name: locationsId, var: locations_id}, {name: operationsId, var: operations_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    projects_id: $projects_id, locations_id: $locations_id, operations_id: $operations_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
