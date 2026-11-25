# Auto-generated client for Weatherbit - Interactive Swagger UI Documentation v2.0.0
# Source: https://api.apis.guru/v2/specs/weatherbit.io/2.0.0/swagger.json
# Auth: --token flag or $env.WEATHERBIT_INTERACTIVE_SWAGGER_UI_DOCUMENTATION_TOKEN

const CLIENT = {
  base_url: "https://api.weatherbit.io/v2.0"
  token_env_var: "WEATHERBIT_INTERACTIVE_SWAGGER_UI_DOCUMENTATION_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: []
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

def base-url-completer [] { ["https://api.weatherbit.io/v2.0" "http://api.weatherbit.io/v2.0"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def units-completer [] { ["I" "S"] }
def marine-completer [] { ["t"] }
def lang-completer [] { ["ar" "az" "be" "bg" "bs" "ca" "cs" "de" "el" "es" "et" "fi" "fr" "hr" "hu" "id" "is" "it" "kw" "nb" "nl" "pl" "pt" "ro" "ru" "sk" "sl" "sr" "sv" "tr" "uk" "zh" "zh-tw"] }
def include-completer [] { ["minutely"] }
def tp-completer [] { ["daily" "hourly"] }
def tp-completer-1 [] { ["daily" "hourly" "monthly"] }
def tz-completer [] { ["local" "utc"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-alerts-lat-lat-lon-lon: "record<alerts: table<alerts: list, description: string, effective_local: string, effective_utc: string, expires_local: string, expires_utc: string, severity: string, title: string, uri: string>, lat: float, lon: float>"
    get-bulk-files-file: "record<code: int, message: string>"
    get-current-airquality-city-city-country-country: "record<city_name: string, country_code: string, data: table<aqi: int, no2: float, o3: float, pm10: float, pm25: float, so2: float>, lat: string, lon: string, state_code: string, timezone: string>"
    get-current-airquality-city-id-city-id: "record<city_name: string, country_code: string, data: table<aqi: int, no2: float, o3: float, pm10: float, pm25: float, so2: float>, lat: string, lon: string, state_code: string, timezone: string>"
    get-current-airquality-lat-lat-lon-lon: "record<city_name: string, country_code: string, data: table<aqi: int, no2: float, o3: float, pm10: float, pm25: float, so2: float>, lat: string, lon: string, state_code: string, timezone: string>"
    get-current-airquality-postal-code-postal-code: "record<city_name: string, country_code: string, data: table<aqi: int, no2: float, o3: float, pm10: float, pm25: float, so2: float>, lat: string, lon: string, state_code: string, timezone: string>"
    get-current-cities-cities: "record<count: int, data: table<app_temp: float, aqi: float, city_name: string, clouds: int, country_code: string, datetime: string, dewpt: float, dhi: float, dni: float, elev_angle: float, ghi: float, gust: float, hour_angle: float, lat: float, lon: float, ob_time: string, pod: string, precip: float, pres: float, rh: int, slp: float, snow: float, solar_rad: float, sources: list, state_code: string, station: string, sunrise: string, sunset: string, temp: float, timezone: string, ts: float, uv: float, vis: int, weather: record, wind_cdir: string, wind_cdir_full: string, wind_dir: int, wind_speed: float>>"
    get-current-city-city-country-country: "record<count: int, data: table<app_temp: float, aqi: float, city_name: string, clouds: int, country_code: string, datetime: string, dewpt: float, dhi: float, dni: float, elev_angle: float, ghi: float, gust: float, hour_angle: float, lat: float, lon: float, ob_time: string, pod: string, precip: float, pres: float, rh: int, slp: float, snow: float, solar_rad: float, sources: list, state_code: string, station: string, sunrise: string, sunset: string, temp: float, timezone: string, ts: float, uv: float, vis: int, weather: record, wind_cdir: string, wind_cdir_full: string, wind_dir: int, wind_speed: float>>"
    get-current-city-id-city-id: "record<count: int, data: table<app_temp: float, aqi: float, city_name: string, clouds: int, country_code: string, datetime: string, dewpt: float, dhi: float, dni: float, elev_angle: float, ghi: float, gust: float, hour_angle: float, lat: float, lon: float, ob_time: string, pod: string, precip: float, pres: float, rh: int, slp: float, snow: float, solar_rad: float, sources: list, state_code: string, station: string, sunrise: string, sunset: string, temp: float, timezone: string, ts: float, uv: float, vis: int, weather: record, wind_cdir: string, wind_cdir_full: string, wind_dir: int, wind_speed: float>>"
    get-current-lat-lat-lon-lon: "record<count: int, data: table<app_temp: float, aqi: float, city_name: string, clouds: int, country_code: string, datetime: string, dewpt: float, dhi: float, dni: float, elev_angle: float, ghi: float, gust: float, hour_angle: float, lat: float, lon: float, ob_time: string, pod: string, precip: float, pres: float, rh: int, slp: float, snow: float, solar_rad: float, sources: list, state_code: string, station: string, sunrise: string, sunset: string, temp: float, timezone: string, ts: float, uv: float, vis: int, weather: record, wind_cdir: string, wind_cdir_full: string, wind_dir: int, wind_speed: float>>"
    get-current-points-points: "record<count: int, data: table<app_temp: float, aqi: float, city_name: string, clouds: int, country_code: string, datetime: string, dewpt: float, dhi: float, dni: float, elev_angle: float, ghi: float, gust: float, hour_angle: float, lat: float, lon: float, ob_time: string, pod: string, precip: float, pres: float, rh: int, slp: float, snow: float, solar_rad: float, sources: list, state_code: string, station: string, sunrise: string, sunset: string, temp: float, timezone: string, ts: float, uv: float, vis: int, weather: record, wind_cdir: string, wind_cdir_full: string, wind_dir: int, wind_speed: float>>"
    get-current-postal-code-postal-code: "record<count: int, data: table<app_temp: float, aqi: float, city_name: string, clouds: int, country_code: string, datetime: string, dewpt: float, dhi: float, dni: float, elev_angle: float, ghi: float, gust: float, hour_angle: float, lat: float, lon: float, ob_time: string, pod: string, precip: float, pres: float, rh: int, slp: float, snow: float, solar_rad: float, sources: list, state_code: string, station: string, sunrise: string, sunset: string, temp: float, timezone: string, ts: float, uv: float, vis: int, weather: record, wind_cdir: string, wind_cdir_full: string, wind_dir: int, wind_speed: float>>"
    get-current-station-station: "record<count: int, data: table<app_temp: float, aqi: float, city_name: string, clouds: int, country_code: string, datetime: string, dewpt: float, dhi: float, dni: float, elev_angle: float, ghi: float, gust: float, hour_angle: float, lat: float, lon: float, ob_time: string, pod: string, precip: float, pres: float, rh: int, slp: float, snow: float, solar_rad: float, sources: list, state_code: string, station: string, sunrise: string, sunset: string, temp: float, timezone: string, ts: float, uv: float, vis: int, weather: record, wind_cdir: string, wind_cdir_full: string, wind_dir: int, wind_speed: float>>"
    get-current-stations-stations: "record<count: int, data: table<app_temp: float, aqi: float, city_name: string, clouds: int, country_code: string, datetime: string, dewpt: float, dhi: float, dni: float, elev_angle: float, ghi: float, gust: float, hour_angle: float, lat: float, lon: float, ob_time: string, pod: string, precip: float, pres: float, rh: int, slp: float, snow: float, solar_rad: float, sources: list, state_code: string, station: string, sunrise: string, sunset: string, temp: float, timezone: string, ts: float, uv: float, vis: int, weather: record, wind_cdir: string, wind_cdir_full: string, wind_dir: int, wind_speed: float>>"
    get-forecast-airquality-city-city-country-country: "record<city_name: string, country_code: string, data: table<aqi: int, no2: float, o3: float, pm10: float, pm25: float, so2: float, timestamp_local: string, timestamp_utc: string, ts: float>, lat: string, lon: string, state_code: string, timezone: string>"
    get-forecast-airquality-city-id-city-id: "record<city_name: string, country_code: string, data: table<aqi: int, no2: float, o3: float, pm10: float, pm25: float, so2: float, timestamp_local: string, timestamp_utc: string, ts: float>, lat: string, lon: string, state_code: string, timezone: string>"
    get-forecast-airquality-lat-lat-lon-lon: "record<city_name: string, country_code: string, data: table<aqi: int, no2: float, o3: float, pm10: float, pm25: float, so2: float, timestamp_local: string, timestamp_utc: string, ts: float>, lat: string, lon: string, state_code: string, timezone: string>"
    get-forecast-airquality-postal-code-postal-code: "record<city_name: string, country_code: string, data: table<aqi: int, no2: float, o3: float, pm10: float, pm25: float, so2: float, timestamp_local: string, timestamp_utc: string, ts: float>, lat: string, lon: string, state_code: string, timezone: string>"
    get-forecast-daily-city-city-country-country: "record<city_name: string, country_code: string, data: table<app_max_temp: float, app_min_temp: float, clouds: int, datetime: string, dewpt: float, max_dhi: float, max_temp: float, min_temp: float, moon_phase: float, moonrise_ts: int, moonset_ts: int, pod: string, pop: float, precip: float, pres: float, rh: int, slp: float, snow: float, snow_depth: float, sunrise_ts: int, sunset_ts: int, temp: float, timestamp_local: string, timestamp_utc: string, ts: float, uv: float, vis: float, weather: record, wind_cdir: string, wind_cdir_full: string, wind_dir: int, wind_spd: float>, lat: string, lon: string, state_code: string, timezone: string>"
    get-forecast-daily-city-id-city-id: "record<city_name: string, country_code: string, data: table<app_max_temp: float, app_min_temp: float, clouds: int, datetime: string, dewpt: float, max_dhi: float, max_temp: float, min_temp: float, moon_phase: float, moonrise_ts: int, moonset_ts: int, pod: string, pop: float, precip: float, pres: float, rh: int, slp: float, snow: float, snow_depth: float, sunrise_ts: int, sunset_ts: int, temp: float, timestamp_local: string, timestamp_utc: string, ts: float, uv: float, vis: float, weather: record, wind_cdir: string, wind_cdir_full: string, wind_dir: int, wind_spd: float>, lat: string, lon: string, state_code: string, timezone: string>"
    get-forecast-daily-lat-lat-lon-lon: "record<city_name: string, country_code: string, data: table<app_max_temp: float, app_min_temp: float, clouds: int, datetime: string, dewpt: float, max_dhi: float, max_temp: float, min_temp: float, moon_phase: float, moonrise_ts: int, moonset_ts: int, pod: string, pop: float, precip: float, pres: float, rh: int, slp: float, snow: float, snow_depth: float, sunrise_ts: int, sunset_ts: int, temp: float, timestamp_local: string, timestamp_utc: string, ts: float, uv: float, vis: float, weather: record, wind_cdir: string, wind_cdir_full: string, wind_dir: int, wind_spd: float>, lat: string, lon: string, state_code: string, timezone: string>"
    get-forecast-daily-postal-code-postal-code: "record<city_name: string, country_code: string, data: table<app_max_temp: float, app_min_temp: float, clouds: int, datetime: string, dewpt: float, max_dhi: float, max_temp: float, min_temp: float, moon_phase: float, moonrise_ts: int, moonset_ts: int, pod: string, pop: float, precip: float, pres: float, rh: int, slp: float, snow: float, snow_depth: float, sunrise_ts: int, sunset_ts: int, temp: float, timestamp_local: string, timestamp_utc: string, ts: float, uv: float, vis: float, weather: record, wind_cdir: string, wind_cdir_full: string, wind_dir: int, wind_spd: float>, lat: string, lon: string, state_code: string, timezone: string>"
    get-forecast-energy-lat-lat-lon-lon: "record<city_name: string, country_code: string, data: table<cdd: float, clouds: int, date: string, dewpt: float, hdd: float, precip: float, rh: int, snow: float, sun_hours: float, t_dhi: float, t_dni: float, t_ghi: float, temp: float, wind_dir: int, wind_spd: float>, lat: string, lon: string, state_code: string, threshold_units: string, threshold_value: string, timezone: string>"
    get-forecast-hourly-city-city-country-country: "record<city_name: string, country_code: string, data: table<app_temp: float, clouds: int, datetime: string, dewpt: float, dhi: float, dni: float, ghi: float, pod: string, pop: float, precip: float, pres: float, rh: int, slp: float, snow: float, snow_depth: float, solar_rad: float, temp: float, timestamp_local: string, timestamp_utc: string, ts: float, uv: float, vis: float, weather: record, wind_cdir: string, wind_cdir_full: string, wind_dir: int, wind_gust_spd: float, wind_spd: float>, lat: string, lon: string, state_code: string, timezone: string>"
    get-forecast-hourly-city-id-city-id: "record<city_name: string, country_code: string, data: table<app_temp: float, clouds: int, datetime: string, dewpt: float, dhi: float, dni: float, ghi: float, pod: string, pop: float, precip: float, pres: float, rh: int, slp: float, snow: float, snow_depth: float, solar_rad: float, temp: float, timestamp_local: string, timestamp_utc: string, ts: float, uv: float, vis: float, weather: record, wind_cdir: string, wind_cdir_full: string, wind_dir: int, wind_gust_spd: float, wind_spd: float>, lat: string, lon: string, state_code: string, timezone: string>"
    get-forecast-hourly-lat-lat-lon-lon: "record<city_name: string, country_code: string, data: table<app_temp: float, clouds: int, datetime: string, dewpt: float, dhi: float, dni: float, ghi: float, pod: string, pop: float, precip: float, pres: float, rh: int, slp: float, snow: float, snow_depth: float, solar_rad: float, temp: float, timestamp_local: string, timestamp_utc: string, ts: float, uv: float, vis: float, weather: record, wind_cdir: string, wind_cdir_full: string, wind_dir: int, wind_gust_spd: float, wind_spd: float>, lat: string, lon: string, state_code: string, timezone: string>"
    get-forecast-hourly-postal-code-postal-code: "record<city_name: string, country_code: string, data: table<app_temp: float, clouds: int, datetime: string, dewpt: float, dhi: float, dni: float, ghi: float, pod: string, pop: float, precip: float, pres: float, rh: int, slp: float, snow: float, snow_depth: float, solar_rad: float, temp: float, timestamp_local: string, timestamp_utc: string, ts: float, uv: float, vis: float, weather: record, wind_cdir: string, wind_cdir_full: string, wind_dir: int, wind_gust_spd: float, wind_spd: float>, lat: string, lon: string, state_code: string, timezone: string>"
    get-history-airquality-city-city-country-country: "record<city_name: string, country_code: string, data: table<aqi: int, no2: float, o3: float, pm10: float, pm25: float, so2: float>, lat: string, lon: string, state_code: string, timezone: string>"
    get-history-airquality-city-id-city-id: "record<city_name: string, country_code: string, data: table<aqi: int, no2: float, o3: float, pm10: float, pm25: float, so2: float>, lat: string, lon: string, state_code: string, timezone: string>"
    get-history-airquality-lat-lat-lon-lon: "record<city_name: string, country_code: string, data: table<aqi: int, no2: float, o3: float, pm10: float, pm25: float, so2: float>, lat: string, lon: string, state_code: string, timezone: string>"
    get-history-airquality-postal-code-postal-code: "record<city_name: string, country_code: string, data: table<aqi: int, no2: float, o3: float, pm10: float, pm25: float, so2: float>, lat: string, lon: string, state_code: string, timezone: string>"
    get-history-daily-city-city-country-country: "record<city_name: string, country_code: string, data: table<datetime: string, dewpt: float, dhi: int, dni: int, ghi: int, max_temp: float, max_temp_ts: float, max_uv: float, max_wind_dir: int, max_wind_spd: float, max_wind_spd_ts: float, min_temp: float, min_temp_ts: float, precip: float, precip_gpm: float, pres: float, revision_status: string, rh: int, slp: float, snow: float, snow_depth: float, t_dhi: int, t_dni: int, t_ghi: int, temp: float, ts: int, wind_dir: int, wind_gust_spd: float, wind_spd: float>, lat: string, lon: string, sources: list<string>, state_code: string, timezone: string>"
    get-history-daily-city-id-city-id: "record<city_name: string, country_code: string, data: table<datetime: string, dewpt: float, dhi: int, dni: int, ghi: int, max_temp: float, max_temp_ts: float, max_uv: float, max_wind_dir: int, max_wind_spd: float, max_wind_spd_ts: float, min_temp: float, min_temp_ts: float, precip: float, precip_gpm: float, pres: float, revision_status: string, rh: int, slp: float, snow: float, snow_depth: float, t_dhi: int, t_dni: int, t_ghi: int, temp: float, ts: int, wind_dir: int, wind_gust_spd: float, wind_spd: float>, lat: string, lon: string, sources: list<string>, state_code: string, timezone: string>"
    get-history-daily-lat-lat-lon-lon: "record<city_name: string, country_code: string, data: table<datetime: string, dewpt: float, dhi: int, dni: int, ghi: int, max_temp: float, max_temp_ts: float, max_uv: float, max_wind_dir: int, max_wind_spd: float, max_wind_spd_ts: float, min_temp: float, min_temp_ts: float, precip: float, precip_gpm: float, pres: float, revision_status: string, rh: int, slp: float, snow: float, snow_depth: float, t_dhi: int, t_dni: int, t_ghi: int, temp: float, ts: int, wind_dir: int, wind_gust_spd: float, wind_spd: float>, lat: string, lon: string, sources: list<string>, state_code: string, timezone: string>"
    get-history-daily-postal-code-postal-code: "record<city_name: string, country_code: string, data: table<datetime: string, dewpt: float, dhi: int, dni: int, ghi: int, max_temp: float, max_temp_ts: float, max_uv: float, max_wind_dir: int, max_wind_spd: float, max_wind_spd_ts: float, min_temp: float, min_temp_ts: float, precip: float, precip_gpm: float, pres: float, revision_status: string, rh: int, slp: float, snow: float, snow_depth: float, t_dhi: int, t_dni: int, t_ghi: int, temp: float, ts: int, wind_dir: int, wind_gust_spd: float, wind_spd: float>, lat: string, lon: string, sources: list<string>, state_code: string, timezone: string>"
    get-history-daily-station-station: "record<city_name: string, country_code: string, data: table<datetime: string, dewpt: float, dhi: int, dni: int, ghi: int, max_temp: float, max_temp_ts: float, max_uv: float, max_wind_dir: int, max_wind_spd: float, max_wind_spd_ts: float, min_temp: float, min_temp_ts: float, precip: float, precip_gpm: float, pres: float, revision_status: string, rh: int, slp: float, snow: float, snow_depth: float, t_dhi: int, t_dni: int, t_ghi: int, temp: float, ts: int, wind_dir: int, wind_gust_spd: float, wind_spd: float>, lat: string, lon: string, sources: list<string>, state_code: string, timezone: string>"
    get-history-energy-lat-lat-lon-lon: "record<count: int, data: table<cdd: float, city_name: string, clouds: int, country_code: string, dewpt: float, hdd: float, lat: string, lon: string, precip: float, rh: int, snow: float, sources: list, state_code: string, station_id: string, sun_hours: float, t_dhi: float, t_dni: float, t_ghi: float, temp: float, timezone: string, wind_dir: int, wind_spd: float>, end_date: int, start_date: int>"
    get-history-hourly-city-city-country-country: "record<city_name: string, country_code: string, data: table<app_temp: float, azimuth: float, clouds: int, datetime: string, dewpt: int, dhi: float, dni: float, elev_angle: float, ghi: float, h_angle: float, pod: string, precip: float, pres: float, revision_status: string, rh: int, slp: float, snow: float, solar_rad: float, temp: float, timestamp_local: string, timestamp_utc: string, ts: float, uv: float, vis: float, weather: record, wind_dir: int, wind_gust_spd: float, wind_spd: float>, lat: string, lon: string, sources: list<string>, state_code: string, timezone: string>"
    get-history-hourly-city-id-city-id: "record<city_name: string, country_code: string, data: table<app_temp: float, azimuth: float, clouds: int, datetime: string, dewpt: int, dhi: float, dni: float, elev_angle: float, ghi: float, h_angle: float, pod: string, precip: float, pres: float, revision_status: string, rh: int, slp: float, snow: float, solar_rad: float, temp: float, timestamp_local: string, timestamp_utc: string, ts: float, uv: float, vis: float, weather: record, wind_dir: int, wind_gust_spd: float, wind_spd: float>, lat: string, lon: string, sources: list<string>, state_code: string, timezone: string>"
    get-history-hourly-lat-lat-lon-lon: "record<city_name: string, country_code: string, data: table<app_temp: float, azimuth: float, clouds: int, datetime: string, dewpt: int, dhi: float, dni: float, elev_angle: float, ghi: float, h_angle: float, pod: string, precip: float, pres: float, revision_status: string, rh: int, slp: float, snow: float, solar_rad: float, temp: float, timestamp_local: string, timestamp_utc: string, ts: float, uv: float, vis: float, weather: record, wind_dir: int, wind_gust_spd: float, wind_spd: float>, lat: string, lon: string, sources: list<string>, state_code: string, timezone: string>"
    get-history-hourly-postal-code-postal-code: "record<city_name: string, country_code: string, data: table<app_temp: float, azimuth: float, clouds: int, datetime: string, dewpt: int, dhi: float, dni: float, elev_angle: float, ghi: float, h_angle: float, pod: string, precip: float, pres: float, revision_status: string, rh: int, slp: float, snow: float, solar_rad: float, temp: float, timestamp_local: string, timestamp_utc: string, ts: float, uv: float, vis: float, weather: record, wind_dir: int, wind_gust_spd: float, wind_spd: float>, lat: string, lon: string, sources: list<string>, state_code: string, timezone: string>"
    get-history-hourly-station-station: "record<city_name: string, country_code: string, data: table<app_temp: float, azimuth: float, clouds: int, datetime: string, dewpt: int, dhi: float, dni: float, elev_angle: float, ghi: float, h_angle: float, pod: string, precip: float, pres: float, revision_status: string, rh: int, slp: float, snow: float, solar_rad: float, temp: float, timestamp_local: string, timestamp_utc: string, ts: float, uv: float, vis: float, weather: record, wind_dir: int, wind_gust_spd: float, wind_spd: float>, lat: string, lon: string, sources: list<string>, state_code: string, timezone: string>"
    get-history-subhourly-city-city-country-country: "record<city_name: string, country_code: string, data: table<app_temp: float, azimuth: float, clouds: int, datetime: string, dewpt: int, dhi: float, dni: float, elev_angle: float, ghi: float, h_angle: float, pod: string, precip: float, pres: float, revision_status: string, rh: int, slp: float, snow: float, solar_rad: float, temp: float, timestamp_local: string, timestamp_utc: string, ts: float, uv: float, vis: float, weather: record, wind_dir: int, wind_gust_spd: float, wind_spd: float>, lat: string, lon: string, sources: list<string>, state_code: string, timezone: string>"
    get-history-subhourly-city-id-city-id: "record<city_name: string, country_code: string, data: table<app_temp: float, azimuth: float, clouds: int, datetime: string, dewpt: int, dhi: float, dni: float, elev_angle: float, ghi: float, h_angle: float, pod: string, precip: float, pres: float, revision_status: string, rh: int, slp: float, snow: float, solar_rad: float, temp: float, timestamp_local: string, timestamp_utc: string, ts: float, uv: float, vis: float, weather: record, wind_dir: int, wind_gust_spd: float, wind_spd: float>, lat: string, lon: string, sources: list<string>, state_code: string, timezone: string>"
    get-history-subhourly-lat-lat-lon-lon: "record<city_name: string, country_code: string, data: table<app_temp: float, azimuth: float, clouds: int, datetime: string, dewpt: int, dhi: float, dni: float, elev_angle: float, ghi: float, h_angle: float, pod: string, precip: float, pres: float, revision_status: string, rh: int, slp: float, snow: float, solar_rad: float, temp: float, timestamp_local: string, timestamp_utc: string, ts: float, uv: float, vis: float, weather: record, wind_dir: int, wind_gust_spd: float, wind_spd: float>, lat: string, lon: string, sources: list<string>, state_code: string, timezone: string>"
    get-history-subhourly-postal-code-postal-code: "record<city_name: string, country_code: string, data: table<app_temp: float, azimuth: float, clouds: int, datetime: string, dewpt: int, dhi: float, dni: float, elev_angle: float, ghi: float, h_angle: float, pod: string, precip: float, pres: float, revision_status: string, rh: int, slp: float, snow: float, solar_rad: float, temp: float, timestamp_local: string, timestamp_utc: string, ts: float, uv: float, vis: float, weather: record, wind_dir: int, wind_gust_spd: float, wind_spd: float>, lat: string, lon: string, sources: list<string>, state_code: string, timezone: string>"
    get-history-subhourly-station-station: "record<city_name: string, country_code: string, data: table<app_temp: float, azimuth: float, clouds: int, datetime: string, dewpt: int, dhi: float, dni: float, elev_angle: float, ghi: float, h_angle: float, pod: string, precip: float, pres: float, revision_status: string, rh: int, slp: float, snow: float, solar_rad: float, temp: float, timestamp_local: string, timestamp_utc: string, ts: float, uv: float, vis: float, weather: record, wind_dir: int, wind_gust_spd: float, wind_spd: float>, lat: string, lon: string, sources: list<string>, state_code: string, timezone: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-alerts-lat-lat-lon-lon" "get-bulk-files-file" "get-current-airquality-city-city-country-country" "get-current-airquality-city-id-city-id" "get-current-airquality-lat-lat-lon-lon" "get-current-airquality-postal-code-postal-code" "get-current-cities-cities" "get-current-city-city-country-country" "get-current-city-id-city-id" "get-current-lat-lat-lon-lon" "get-current-points-points" "get-current-postal-code-postal-code" "get-current-station-station" "get-current-stations-stations" "get-forecast-airquality-city-city-country-country" "get-forecast-airquality-city-id-city-id" "get-forecast-airquality-lat-lat-lon-lon" "get-forecast-airquality-postal-code-postal-code" "get-forecast-daily-city-city-country-country" "get-forecast-daily-city-id-city-id" "get-forecast-daily-lat-lat-lon-lon" "get-forecast-daily-postal-code-postal-code" "get-forecast-energy-lat-lat-lon-lon" "get-forecast-hourly-city-city-country-country" "get-forecast-hourly-city-id-city-id" "get-forecast-hourly-lat-lat-lon-lon" "get-forecast-hourly-postal-code-postal-code" "get-history-airquality-city-city-country-country" "get-history-airquality-city-id-city-id" "get-history-airquality-lat-lat-lon-lon" "get-history-airquality-postal-code-postal-code" "get-history-daily-city-city-country-country" "get-history-daily-city-id-city-id" "get-history-daily-lat-lat-lon-lon" "get-history-daily-postal-code-postal-code" "get-history-daily-station-station" "get-history-energy-lat-lat-lon-lon" "get-history-hourly-city-city-country-country" "get-history-hourly-city-id-city-id" "get-history-hourly-lat-lat-lon-lon" "get-history-hourly-postal-code-postal-code" "get-history-hourly-station-station" "get-history-subhourly-city-city-country-country" "get-history-subhourly-city-id-city-id" "get-history-subhourly-lat-lat-lon-lon" "get-history-subhourly-postal-code-postal-code" "get-history-subhourly-station-station" "commands"] | sort) } | get name | first)
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

# Returns severe weather alerts issued by meteorological agencies - Given a lat/lon.
#
# GET /alerts?lat={lat}&lon={lon}
# Returns: record<alerts: table<alerts: list, description: string, effective_local: string, effective_utc: string, expires_local: string, expires_utc: string, severity: string, title: string, uri: string>, lat: float, lon: float>
export def "get-alerts-lat-lat-lon-lon" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --callback: string # Wraps return in jsonp callback - Example - callback=func (format: string)
  --key: string # Your registered API key. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/alerts"
    fixed_query: "lat={lat}&lon={lon}"
    query: [{name: callback, var: callback}, {name: key, var: key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    callback: $callback, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download pre-generated bulk datasets
#
# GET /bulk/files/{file}
# Returns: record<code: int, message: string>
export def "get-bulk-files-file" [
  file: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Your registered API key. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bulk/files/{file}"
    path_params: [{name: file, var: file}]
    query: [{name: key, var: key, required: true}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    file: $file, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns current air quality conditions - Given City and/or State, Country.
#
# GET /current/airquality?city={city}&country={country}
# Returns: record<city_name: string, country_code: string, data: table<aqi: int, no2: float, o3: float, pm10: float, pm25: float, so2: float>, lat: string, lon: string, state_code: string, timezone: string>
export def "get-current-airquality-city-city-country-country" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --state: string # Full name of state. (format: string)
  --callback: string # Wraps return in jsonp callback. Example: callback=func (format: string)
  --key: string # Your registered API key. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/current/airquality"
    fixed_query: "city={city}&country={country}"
    query: [{name: state, var: state}, {name: callback, var: callback}, {name: key, var: key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    state: $state, callback: $callback, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns current air quality conditions - Given a City ID.
#
# GET /current/airquality?city_id={city_id}
# Returns: record<city_name: string, country_code: string, data: table<aqi: int, no2: float, o3: float, pm10: float, pm25: float, so2: float>, lat: string, lon: string, state_code: string, timezone: string>
export def "get-current-airquality-city-id-city-id" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --callback: string # Wraps return in jsonp callback. Example - callback=func (format: string)
  --key: string # Your registered API key. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/current/airquality"
    fixed_query: "city_id={city_id}"
    query: [{name: callback, var: callback}, {name: key, var: key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    callback: $callback, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns current air quality conditions - Given a lat/lon.
#
# GET /current/airquality?lat={lat}&lon={lon}
# Returns: record<city_name: string, country_code: string, data: table<aqi: int, no2: float, o3: float, pm10: float, pm25: float, so2: float>, lat: string, lon: string, state_code: string, timezone: string>
export def "get-current-airquality-lat-lat-lon-lon" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --callback: string # Wraps return in jsonp callback. Example - callback=func (format: string)
  --key: string # Your registered API key. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/current/airquality"
    fixed_query: "lat={lat}&lon={lon}"
    query: [{name: callback, var: callback}, {name: key, var: key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    callback: $callback, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns current air quality conditions - Given a Postal Code.
#
# GET /current/airquality?postal_code={postal_code}
# Returns: record<city_name: string, country_code: string, data: table<aqi: int, no2: float, o3: float, pm10: float, pm25: float, so2: float>, lat: string, lon: string, state_code: string, timezone: string>
export def "get-current-airquality-postal-code-postal-code" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --country: string # Country Code (2 letter). (format: string)
  --callback: string # Wraps return in jsonp callback. Example - callback=func (format: string)
  --key: string # Your registered API key. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/current/airquality"
    fixed_query: "postal_code={postal_code}"
    query: [{name: country, var: country}, {name: callback, var: callback}, {name: key, var: key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    country: $country, callback: $callback, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a group of observations given a list of cities
#
# GET /current?cities={cities}
# Returns: record<count: int, data: table<app_temp: float, aqi: float, city_name: string, clouds: int, country_code: string, datetime: string, dewpt: float, dhi: float, dni: float, elev_angle: float, ghi: float, gust: float, hour_angle: float, lat: float, lon: float, ob_time: string, pod: string, precip: float, pres: float, rh: int, slp: float, snow: float, solar_rad: float, sources: list, state_code: string, station: string, sunrise: string, sunset: string, temp: float, timezone: string, ts: float, uv: float, vis: int, weather: record, wind_cdir: string, wind_cdir_full: string, wind_dir: int, wind_speed: float>>
export def "get-current-cities-cities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --units: string@units-completer # Convert to units. Default Metric See units field description (format: string)
  --marine: string@marine-completer # Marine stations only (buoys, oil platforms, etc) (format: string)
  --lang: string@lang-completer # Language (Default: English) See language field description (format: string)
  --callback: string # Wraps return in jsonp callback - Example - callback=func (format: string)
  --key: string # Your registered API key. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/current"
    fixed_query: "cities={cities}"
    query: [{name: units, var: units}, {name: marine, var: marine}, {name: lang, var: lang}, {name: callback, var: callback}, {name: key, var: key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    units: $units, marine: $marine, lang: $lang, callback: $callback, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a Current Observation - Given City and/or State, Country.
#
# GET /current?city={city}&country={country}
# Returns: record<count: int, data: table<app_temp: float, aqi: float, city_name: string, clouds: int, country_code: string, datetime: string, dewpt: float, dhi: float, dni: float, elev_angle: float, ghi: float, gust: float, hour_angle: float, lat: float, lon: float, ob_time: string, pod: string, precip: float, pres: float, rh: int, slp: float, snow: float, solar_rad: float, sources: list, state_code: string, station: string, sunrise: string, sunset: string, temp: float, timezone: string, ts: float, uv: float, vis: int, weather: record, wind_cdir: string, wind_cdir_full: string, wind_dir: int, wind_speed: float>>
export def "get-current-city-city-country-country" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: string@include-completer # Include 1 hour - minutely forecast in the response (format: string)
  --state: string # Full name of state. (format: string)
  --marine: string@marine-completer # Marine stations only (buoys, oil platforms, etc) (format: string)
  --units: string@units-completer # Convert to units. Default Metric See units field description (format: string)
  --lang: string@lang-completer # Language (Default: English) See language field description (format: string)
  --callback: string # Wraps return in jsonp callback - Example - callback=func (format: string)
  --key: string # Your registered API key. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/current"
    fixed_query: "city={city}&country={country}"
    query: [{name: include, var: include}, {name: state, var: state}, {name: marine, var: marine}, {name: units, var: units}, {name: lang, var: lang}, {name: callback, var: callback}, {name: key, var: key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    include: $include, state: $state, marine: $marine, units: $units, lang: $lang, callback: $callback, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a current observation by city id.
#
# GET /current?city_id={city_id}
# Returns: record<count: int, data: table<app_temp: float, aqi: float, city_name: string, clouds: int, country_code: string, datetime: string, dewpt: float, dhi: float, dni: float, elev_angle: float, ghi: float, gust: float, hour_angle: float, lat: float, lon: float, ob_time: string, pod: string, precip: float, pres: float, rh: int, slp: float, snow: float, solar_rad: float, sources: list, state_code: string, station: string, sunrise: string, sunset: string, temp: float, timezone: string, ts: float, uv: float, vis: int, weather: record, wind_cdir: string, wind_cdir_full: string, wind_dir: int, wind_speed: float>>
export def "get-current-city-id-city-id" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --units: string@units-completer # Convert to units. Default Metric See units field description (format: string)
  --include: string@include-completer # Include 1 hour - minutely forecast in the response (format: string)
  --marine: string@marine-completer # Marine stations only (buoys, oil platforms, etc) (format: string)
  --lang: string@lang-completer # Language (Default: English) See language field description (format: string)
  --callback: string # Wraps return in jsonp callback - Example - callback=func (format: string)
  --key: string # Your registered API key. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/current"
    fixed_query: "city_id={city_id}"
    query: [{name: units, var: units}, {name: include, var: include}, {name: marine, var: marine}, {name: lang, var: lang}, {name: callback, var: callback}, {name: key, var: key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    units: $units, include: $include, marine: $marine, lang: $lang, callback: $callback, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a Current Observation - Given a lat/lon.
#
# GET /current?lat={lat}&lon={lon}
# Returns: record<count: int, data: table<app_temp: float, aqi: float, city_name: string, clouds: int, country_code: string, datetime: string, dewpt: float, dhi: float, dni: float, elev_angle: float, ghi: float, gust: float, hour_angle: float, lat: float, lon: float, ob_time: string, pod: string, precip: float, pres: float, rh: int, slp: float, snow: float, solar_rad: float, sources: list, state_code: string, station: string, sunrise: string, sunset: string, temp: float, timezone: string, ts: float, uv: float, vis: int, weather: record, wind_cdir: string, wind_cdir_full: string, wind_dir: int, wind_speed: float>>
export def "get-current-lat-lat-lon-lon" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: string@include-completer # Include 1 hour - minutely forecast in the response (format: string)
  --marine: string@marine-completer # Marine stations only (buoys, oil platforms, etc) (format: string)
  --units: string@units-completer # Convert to units. Default Metric See units field description (format: string)
  --lang: string@lang-completer # Language (Default: English) See language field description (format: string)
  --callback: string # Wraps return in jsonp callback - Example - callback=func (format: string)
  --key: string # Your registered API key. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/current"
    fixed_query: "lat={lat}&lon={lon}"
    query: [{name: include, var: include}, {name: marine, var: marine}, {name: units, var: units}, {name: lang, var: lang}, {name: callback, var: callback}, {name: key, var: key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    include: $include, marine: $marine, units: $units, lang: $lang, callback: $callback, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a group of observations given a list of points in the format (lat1, lon1), (lat2, lon2), (latN, lonN), ...
#
# GET /current?points={points}
# Returns: record<count: int, data: table<app_temp: float, aqi: float, city_name: string, clouds: int, country_code: string, datetime: string, dewpt: float, dhi: float, dni: float, elev_angle: float, ghi: float, gust: float, hour_angle: float, lat: float, lon: float, ob_time: string, pod: string, precip: float, pres: float, rh: int, slp: float, snow: float, solar_rad: float, sources: list, state_code: string, station: string, sunrise: string, sunset: string, temp: float, timezone: string, ts: float, uv: float, vis: int, weather: record, wind_cdir: string, wind_cdir_full: string, wind_dir: int, wind_speed: float>>
export def "get-current-points-points" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --units: string@units-completer # Convert to units. Default Metric See units field description (format: string)
  --lang: string@lang-completer # Language (Default: English) See language field description (format: string)
  --callback: string # Wraps return in jsonp callback. Example: callback=func (format: string)
  --key: string # Your registered API key. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/current"
    fixed_query: "points={points}"
    query: [{name: units, var: units}, {name: lang, var: lang}, {name: callback, var: callback}, {name: key, var: key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    units: $units, lang: $lang, callback: $callback, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a current observation by postal code.
#
# GET /current?postal_code={postal_code}
# Returns: record<count: int, data: table<app_temp: float, aqi: float, city_name: string, clouds: int, country_code: string, datetime: string, dewpt: float, dhi: float, dni: float, elev_angle: float, ghi: float, gust: float, hour_angle: float, lat: float, lon: float, ob_time: string, pod: string, precip: float, pres: float, rh: int, slp: float, snow: float, solar_rad: float, sources: list, state_code: string, station: string, sunrise: string, sunset: string, temp: float, timezone: string, ts: float, uv: float, vis: int, weather: record, wind_cdir: string, wind_cdir_full: string, wind_dir: int, wind_speed: float>>
export def "get-current-postal-code-postal-code" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --country: string # Country Code (2 letter). (format: string)
  --include: string@include-completer # Include 1 hour - minutely forecast in the response (format: string)
  --marine: string@marine-completer # Marine stations only (buoys, oil platforms, etc) (format: string)
  --units: string@units-completer # Convert to units. Default Metric See units field description (format: string)
  --lang: string@lang-completer # Language (Default: English) See language field description (format: string)
  --callback: string # Wraps return in jsonp callback - Example - callback=func (format: string)
  --key: string # Your registered API key. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/current"
    fixed_query: "postal_code={postal_code}"
    query: [{name: country, var: country}, {name: include, var: include}, {name: marine, var: marine}, {name: units, var: units}, {name: lang, var: lang}, {name: callback, var: callback}, {name: key, var: key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    country: $country, include: $include, marine: $marine, units: $units, lang: $lang, callback: $callback, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a Current Observation. - Given a station ID.
#
# GET /current?station={station}
# Returns: record<count: int, data: table<app_temp: float, aqi: float, city_name: string, clouds: int, country_code: string, datetime: string, dewpt: float, dhi: float, dni: float, elev_angle: float, ghi: float, gust: float, hour_angle: float, lat: float, lon: float, ob_time: string, pod: string, precip: float, pres: float, rh: int, slp: float, snow: float, solar_rad: float, sources: list, state_code: string, station: string, sunrise: string, sunset: string, temp: float, timezone: string, ts: float, uv: float, vis: int, weather: record, wind_cdir: string, wind_cdir_full: string, wind_dir: int, wind_speed: float>>
export def "get-current-station-station" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: string@include-completer # Include 1 hour - minutely forecast in the response (format: string)
  --units: string@units-completer # Convert to units. Default Metric See units field description (format: string)
  --lang: string@lang-completer # Language (Default: English) See language field description (format: string)
  --callback: string # Wraps return in jsonp callback. Example: callback=func (format: string)
  --key: string # Your registered API key. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/current"
    fixed_query: "station={station}"
    query: [{name: include, var: include}, {name: units, var: units}, {name: lang, var: lang}, {name: callback, var: callback}, {name: key, var: key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    include: $include, units: $units, lang: $lang, callback: $callback, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a group of observations given a list of stations
#
# GET /current?stations={stations}
# Returns: record<count: int, data: table<app_temp: float, aqi: float, city_name: string, clouds: int, country_code: string, datetime: string, dewpt: float, dhi: float, dni: float, elev_angle: float, ghi: float, gust: float, hour_angle: float, lat: float, lon: float, ob_time: string, pod: string, precip: float, pres: float, rh: int, slp: float, snow: float, solar_rad: float, sources: list, state_code: string, station: string, sunrise: string, sunset: string, temp: float, timezone: string, ts: float, uv: float, vis: int, weather: record, wind_cdir: string, wind_cdir_full: string, wind_dir: int, wind_speed: float>>
export def "get-current-stations-stations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --units: string@units-completer # Convert to units. Default Metric See units field description (format: string)
  --lang: string@lang-completer # Language (Default: English) See language field description (format: string)
  --callback: string # Wraps return in jsonp callback. Example: callback=func (format: string)
  --key: string # Your registered API key. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/current"
    fixed_query: "stations={stations}"
    query: [{name: units, var: units}, {name: lang, var: lang}, {name: callback, var: callback}, {name: key, var: key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    units: $units, lang: $lang, callback: $callback, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns 72 hour (hourly) Air Quality forecast - Given City and/or State, Country.
#
# GET /forecast/airquality?city={city}&country={country}
# Returns: record<city_name: string, country_code: string, data: table<aqi: int, no2: float, o3: float, pm10: float, pm25: float, so2: float, timestamp_local: string, timestamp_utc: string, ts: float>, lat: string, lon: string, state_code: string, timezone: string>
export def "get-forecast-airquality-city-city-country-country" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --state: string # Full name of state. (format: string)
  --callback: string # Wraps return in jsonp callback. Example: callback=func (format: string)
  --hours: int # Number of hours to return. (format: integer)
  --key: string # Your registered API key. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/forecast/airquality"
    fixed_query: "city={city}&country={country}"
    query: [{name: state, var: state}, {name: callback, var: callback}, {name: hours, var: hours}, {name: key, var: key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    state: $state, callback: $callback, hours: $hours, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns 72 hour (hourly) Air Quality forecast - Given a City ID.
#
# GET /forecast/airquality?city_id={city_id}
# Returns: record<city_name: string, country_code: string, data: table<aqi: int, no2: float, o3: float, pm10: float, pm25: float, so2: float, timestamp_local: string, timestamp_utc: string, ts: float>, lat: string, lon: string, state_code: string, timezone: string>
export def "get-forecast-airquality-city-id-city-id" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --callback: string # Wraps return in jsonp callback. Example - callback=func (format: string)
  --hours: int # Number of hours to return. (format: integer)
  --key: string # Your registered API key. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/forecast/airquality"
    fixed_query: "city_id={city_id}"
    query: [{name: callback, var: callback}, {name: hours, var: hours}, {name: key, var: key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    callback: $callback, hours: $hours, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns 72 hour (hourly) Air Quality forecast - Given a lat/lon.
#
# GET /forecast/airquality?lat={lat}&lon={lon}
# Returns: record<city_name: string, country_code: string, data: table<aqi: int, no2: float, o3: float, pm10: float, pm25: float, so2: float, timestamp_local: string, timestamp_utc: string, ts: float>, lat: string, lon: string, state_code: string, timezone: string>
export def "get-forecast-airquality-lat-lat-lon-lon" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --callback: string # Wraps return in jsonp callback. Example - callback=func (format: string)
  --key: string # Your registered API key. (required, format: string)
  --hours: int # Number of hours to return. (format: integer)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/forecast/airquality"
    fixed_query: "lat={lat}&lon={lon}"
    query: [{name: callback, var: callback}, {name: key, var: key, required: true}, {name: hours, var: hours}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    callback: $callback, key: $key, hours: $hours
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns 72 hour (hourly) Air Quality forecast - Given a Postal Code.
#
# GET /forecast/airquality?postal_code={postal_code}
# Returns: record<city_name: string, country_code: string, data: table<aqi: int, no2: float, o3: float, pm10: float, pm25: float, so2: float, timestamp_local: string, timestamp_utc: string, ts: float>, lat: string, lon: string, state_code: string, timezone: string>
export def "get-forecast-airquality-postal-code-postal-code" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --country: string # Country Code (2 letter). (format: string)
  --callback: string # Wraps return in jsonp callback. Example - callback=func (format: string)
  --hours: int # Number of hours to return. (format: integer)
  --key: string # Your registered API key. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/forecast/airquality"
    fixed_query: "postal_code={postal_code}"
    query: [{name: country, var: country}, {name: callback, var: callback}, {name: hours, var: hours}, {name: key, var: key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    country: $country, callback: $callback, hours: $hours, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a daily forecast - Given City and/or State, Country.
#
# GET /forecast/daily?city={city}&country={country}
# Returns: record<city_name: string, country_code: string, data: table<app_max_temp: float, app_min_temp: float, clouds: int, datetime: string, dewpt: float, max_dhi: float, max_temp: float, min_temp: float, moon_phase: float, moonrise_ts: int, moonset_ts: int, pod: string, pop: float, precip: float, pres: float, rh: int, slp: float, snow: float, snow_depth: float, sunrise_ts: int, sunset_ts: int, temp: float, timestamp_local: string, timestamp_utc: string, ts: float, uv: float, vis: float, weather: record, wind_cdir: string, wind_cdir_full: string, wind_dir: int, wind_spd: float>, lat: string, lon: string, state_code: string, timezone: string>
export def "get-forecast-daily-city-city-country-country" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --state: string # Full name of state. (format: string)
  --days: float # Number of days to return. Default 16. (format: integer)
  --units: string@units-completer # Convert to units. Default Metric See units field description (format: string)
  --lang: string@lang-completer # Language (Default: English) See language field description (format: string)
  --callback: string # Wraps return in jsonp callback. Example - callback=func (format: string)
  --key: string # Your registered API key. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/forecast/daily"
    fixed_query: "city={city}&country={country}"
    query: [{name: state, var: state}, {name: days, var: days}, {name: units, var: units}, {name: lang, var: lang}, {name: callback, var: callback}, {name: key, var: key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    state: $state, days: $days, units: $units, lang: $lang, callback: $callback, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a daily forecast - Given a City ID.
#
# GET /forecast/daily?city_id={city_id}
# Returns: record<city_name: string, country_code: string, data: table<app_max_temp: float, app_min_temp: float, clouds: int, datetime: string, dewpt: float, max_dhi: float, max_temp: float, min_temp: float, moon_phase: float, moonrise_ts: int, moonset_ts: int, pod: string, pop: float, precip: float, pres: float, rh: int, slp: float, snow: float, snow_depth: float, sunrise_ts: int, sunset_ts: int, temp: float, timestamp_local: string, timestamp_utc: string, ts: float, uv: float, vis: float, weather: record, wind_cdir: string, wind_cdir_full: string, wind_dir: int, wind_spd: float>, lat: string, lon: string, state_code: string, timezone: string>
export def "get-forecast-daily-city-id-city-id" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --days: float # Number of days to return. Default 16. (format: integer)
  --units: string@units-completer # Convert to units. Default Metric See units field description (format: string)
  --lang: string@lang-completer # Language (Default: English) See language field description (format: string)
  --callback: string # Wraps return in jsonp callback. Example: callback=func (format: string)
  --key: string # Your registered API key. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/forecast/daily"
    fixed_query: "city_id={city_id}"
    query: [{name: days, var: days}, {name: units, var: units}, {name: lang, var: lang}, {name: callback, var: callback}, {name: key, var: key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    days: $days, units: $units, lang: $lang, callback: $callback, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a daily forecast - Given Lat/Lon.
#
# GET /forecast/daily?lat={lat}&lon={lon}
# Returns: record<city_name: string, country_code: string, data: table<app_max_temp: float, app_min_temp: float, clouds: int, datetime: string, dewpt: float, max_dhi: float, max_temp: float, min_temp: float, moon_phase: float, moonrise_ts: int, moonset_ts: int, pod: string, pop: float, precip: float, pres: float, rh: int, slp: float, snow: float, snow_depth: float, sunrise_ts: int, sunset_ts: int, temp: float, timestamp_local: string, timestamp_utc: string, ts: float, uv: float, vis: float, weather: record, wind_cdir: string, wind_cdir_full: string, wind_dir: int, wind_spd: float>, lat: string, lon: string, state_code: string, timezone: string>
export def "get-forecast-daily-lat-lat-lon-lon" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --days: float # Number of days to return. Default 16. (format: integer)
  --units: string@units-completer # Convert to units. Default Metric See units field description (format: string)
  --lang: string@lang-completer # Language (Default: English) See language field description (format: string)
  --callback: string # Wraps return in jsonp callback. Example: callback=func (format: string)
  --key: string # Your registered API key. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/forecast/daily"
    fixed_query: "lat={lat}&lon={lon}"
    query: [{name: days, var: days}, {name: units, var: units}, {name: lang, var: lang}, {name: callback, var: callback}, {name: key, var: key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    days: $days, units: $units, lang: $lang, callback: $callback, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a daily forecast - Given a Postal Code.
#
# GET /forecast/daily?postal_code={postal_code}
# Returns: record<city_name: string, country_code: string, data: table<app_max_temp: float, app_min_temp: float, clouds: int, datetime: string, dewpt: float, max_dhi: float, max_temp: float, min_temp: float, moon_phase: float, moonrise_ts: int, moonset_ts: int, pod: string, pop: float, precip: float, pres: float, rh: int, slp: float, snow: float, snow_depth: float, sunrise_ts: int, sunset_ts: int, temp: float, timestamp_local: string, timestamp_utc: string, ts: float, uv: float, vis: float, weather: record, wind_cdir: string, wind_cdir_full: string, wind_dir: int, wind_spd: float>, lat: string, lon: string, state_code: string, timezone: string>
export def "get-forecast-daily-postal-code-postal-code" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --country: string # Country Code (2 letter). (format: string)
  --days: float # Number of days to return. Default 16. (format: integer)
  --units: string@units-completer # Convert to units. Default Metric See units field description (format: string)
  --lang: string@lang-completer # Language (Default: English) See language field description (format: string)
  --callback: string # Wraps return in jsonp callback. Example: callback=func (format: string)
  --key: string # Your registered API key. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/forecast/daily"
    fixed_query: "postal_code={postal_code}"
    query: [{name: country, var: country}, {name: days, var: days}, {name: units, var: units}, {name: lang, var: lang}, {name: callback, var: callback}, {name: key, var: key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    country: $country, days: $days, units: $units, lang: $lang, callback: $callback, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns Energy Forecast API response - Given a single lat/lon.
#
# GET /forecast/energy?lat={lat}&lon={lon}
# Returns: record<city_name: string, country_code: string, data: table<cdd: float, clouds: int, date: string, dewpt: float, hdd: float, precip: float, rh: int, snow: float, sun_hours: float, t_dhi: float, t_dni: float, t_ghi: float, temp: float, wind_dir: int, wind_spd: float>, lat: string, lon: string, state_code: string, threshold_units: string, threshold_value: string, timezone: string>
export def "get-forecast-energy-lat-lat-lon-lon" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --threshold: float # Temperature threshold to use to calculate degree days (default 18 C) (format: double)
  --units: string@units-completer # Convert to units. Default Metric See units field description (format: string)
  --tp: string@tp-completer # Time period (default: daily) (format: string)
  --callback: string # Wraps return in jsonp callback. Example: callback=func (format: string)
  --key: string # Your registered API key. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/forecast/energy"
    fixed_query: "lat={lat}&lon={lon}"
    query: [{name: threshold, var: threshold}, {name: units, var: units}, {name: tp, var: tp}, {name: callback, var: callback}, {name: key, var: key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    threshold: $threshold, units: $units, tp: $tp, callback: $callback, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns an hourly forecast - Given City and/or State, Country.
#
# GET /forecast/hourly?city={city}&country={country}
# Returns: record<city_name: string, country_code: string, data: table<app_temp: float, clouds: int, datetime: string, dewpt: float, dhi: float, dni: float, ghi: float, pod: string, pop: float, precip: float, pres: float, rh: int, slp: float, snow: float, snow_depth: float, solar_rad: float, temp: float, timestamp_local: string, timestamp_utc: string, ts: float, uv: float, vis: float, weather: record, wind_cdir: string, wind_cdir_full: string, wind_dir: int, wind_gust_spd: float, wind_spd: float>, lat: string, lon: string, state_code: string, timezone: string>
export def "get-forecast-hourly-city-city-country-country" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --state: string # Full name of state. (format: string)
  --units: string@units-completer # Convert to units. Default Metric See units field description (format: string)
  --lang: string@lang-completer # Language (Default: English) See language field description (format: string)
  --callback: string # Wraps return in jsonp callback. Example: callback=func (format: string)
  --hours: int # Number of hours to return. (format: integer)
  --key: string # Your registered API key. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/forecast/hourly"
    fixed_query: "city={city}&country={country}"
    query: [{name: state, var: state}, {name: units, var: units}, {name: lang, var: lang}, {name: callback, var: callback}, {name: hours, var: hours}, {name: key, var: key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    state: $state, units: $units, lang: $lang, callback: $callback, hours: $hours, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns an hourly forecast - Given a City ID.
#
# GET /forecast/hourly?city_id={city_id}
# Returns: record<city_name: string, country_code: string, data: table<app_temp: float, clouds: int, datetime: string, dewpt: float, dhi: float, dni: float, ghi: float, pod: string, pop: float, precip: float, pres: float, rh: int, slp: float, snow: float, snow_depth: float, solar_rad: float, temp: float, timestamp_local: string, timestamp_utc: string, ts: float, uv: float, vis: float, weather: record, wind_cdir: string, wind_cdir_full: string, wind_dir: int, wind_gust_spd: float, wind_spd: float>, lat: string, lon: string, state_code: string, timezone: string>
export def "get-forecast-hourly-city-id-city-id" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --units: string@units-completer # Convert to units. Default Metric See units field description (format: string)
  --lang: string@lang-completer # Language (Default: English) See language field description (format: string)
  --callback: string # Wraps return in jsonp callback. Example - callback=func (format: string)
  --hours: int # Number of hours to return. (format: integer)
  --key: string # Your registered API key. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/forecast/hourly"
    fixed_query: "city_id={city_id}"
    query: [{name: units, var: units}, {name: lang, var: lang}, {name: callback, var: callback}, {name: hours, var: hours}, {name: key, var: key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    units: $units, lang: $lang, callback: $callback, hours: $hours, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns an hourly forecast - Given a lat/lon.
#
# GET /forecast/hourly?lat={lat}&lon={lon}
# Returns: record<city_name: string, country_code: string, data: table<app_temp: float, clouds: int, datetime: string, dewpt: float, dhi: float, dni: float, ghi: float, pod: string, pop: float, precip: float, pres: float, rh: int, slp: float, snow: float, snow_depth: float, solar_rad: float, temp: float, timestamp_local: string, timestamp_utc: string, ts: float, uv: float, vis: float, weather: record, wind_cdir: string, wind_cdir_full: string, wind_dir: int, wind_gust_spd: float, wind_spd: float>, lat: string, lon: string, state_code: string, timezone: string>
export def "get-forecast-hourly-lat-lat-lon-lon" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --units: string@units-completer # Convert to units. Default Metric See units field description (format: string)
  --lang: string@lang-completer # Language (Default: English) See language field description (format: string)
  --callback: string # Wraps return in jsonp callback. Example - callback=func (format: string)
  --key: string # Your registered API key. (required, format: string)
  --hours: int # Number of hours to return. (format: integer)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/forecast/hourly"
    fixed_query: "lat={lat}&lon={lon}"
    query: [{name: units, var: units}, {name: lang, var: lang}, {name: callback, var: callback}, {name: key, var: key, required: true}, {name: hours, var: hours}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    units: $units, lang: $lang, callback: $callback, key: $key, hours: $hours
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns an hourly forecast - Given a Postal Code.
#
# GET /forecast/hourly?postal_code={postal_code}
# Returns: record<city_name: string, country_code: string, data: table<app_temp: float, clouds: int, datetime: string, dewpt: float, dhi: float, dni: float, ghi: float, pod: string, pop: float, precip: float, pres: float, rh: int, slp: float, snow: float, snow_depth: float, solar_rad: float, temp: float, timestamp_local: string, timestamp_utc: string, ts: float, uv: float, vis: float, weather: record, wind_cdir: string, wind_cdir_full: string, wind_dir: int, wind_gust_spd: float, wind_spd: float>, lat: string, lon: string, state_code: string, timezone: string>
export def "get-forecast-hourly-postal-code-postal-code" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --country: string # Country Code (2 letter). (format: string)
  --units: string@units-completer # Convert to units. Default Metric See units field description (format: string)
  --lang: string@lang-completer # Language (Default: English) See language field description (format: string)
  --callback: string # Wraps return in jsonp callback. Example - callback=func (format: string)
  --hours: int # Number of hours to return. (format: integer)
  --key: string # Your registered API key. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/forecast/hourly"
    fixed_query: "postal_code={postal_code}"
    query: [{name: country, var: country}, {name: units, var: units}, {name: lang, var: lang}, {name: callback, var: callback}, {name: hours, var: hours}, {name: key, var: key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    country: $country, units: $units, lang: $lang, callback: $callback, hours: $hours, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns 72 hours of historical quality conditions - Given City and/or State, Country.
#
# GET /history/airquality?city={city}&country={country}
# Returns: record<city_name: string, country_code: string, data: table<aqi: int, no2: float, o3: float, pm10: float, pm25: float, so2: float>, lat: string, lon: string, state_code: string, timezone: string>
export def "get-history-airquality-city-city-country-country" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --state: string # Full name of state. (format: string)
  --callback: string # Wraps return in jsonp callback. Example: callback=func (format: string)
  --key: string # Your registered API key. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/history/airquality"
    fixed_query: "city={city}&country={country}"
    query: [{name: state, var: state}, {name: callback, var: callback}, {name: key, var: key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    state: $state, callback: $callback, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns 72 hours of historical air quality conditions - Given a City ID.
#
# GET /history/airquality?city_id={city_id}
# Returns: record<city_name: string, country_code: string, data: table<aqi: int, no2: float, o3: float, pm10: float, pm25: float, so2: float>, lat: string, lon: string, state_code: string, timezone: string>
export def "get-history-airquality-city-id-city-id" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --callback: string # Wraps return in jsonp callback. Example - callback=func (format: string)
  --key: string # Your registered API key. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/history/airquality"
    fixed_query: "city_id={city_id}"
    query: [{name: callback, var: callback}, {name: key, var: key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    callback: $callback, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns 72 hours of historical air quality conditions - Given a lat/lon.
#
# GET /history/airquality?lat={lat}&lon={lon}
# Returns: record<city_name: string, country_code: string, data: table<aqi: int, no2: float, o3: float, pm10: float, pm25: float, so2: float>, lat: string, lon: string, state_code: string, timezone: string>
export def "get-history-airquality-lat-lat-lon-lon" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --callback: string # Wraps return in jsonp callback. Example - callback=func (format: string)
  --key: string # Your registered API key. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/history/airquality"
    fixed_query: "lat={lat}&lon={lon}"
    query: [{name: callback, var: callback}, {name: key, var: key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    callback: $callback, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns 72 hours of historical air quality conditions - Given a Postal Code.
#
# GET /history/airquality?postal_code={postal_code}
# Returns: record<city_name: string, country_code: string, data: table<aqi: int, no2: float, o3: float, pm10: float, pm25: float, so2: float>, lat: string, lon: string, state_code: string, timezone: string>
export def "get-history-airquality-postal-code-postal-code" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --country: string # Country Code (2 letter). (format: string)
  --callback: string # Wraps return in jsonp callback. Example - callback=func (format: string)
  --key: string # Your registered API key. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/history/airquality"
    fixed_query: "postal_code={postal_code}"
    query: [{name: country, var: country}, {name: callback, var: callback}, {name: key, var: key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    country: $country, callback: $callback, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns Historical Observations - Given City and/or State, Country.
#
# GET /history/daily?city={city}&country={country}
# Returns: record<city_name: string, country_code: string, data: table<datetime: string, dewpt: float, dhi: int, dni: int, ghi: int, max_temp: float, max_temp_ts: float, max_uv: float, max_wind_dir: int, max_wind_spd: float, max_wind_spd_ts: float, min_temp: float, min_temp_ts: float, precip: float, precip_gpm: float, pres: float, revision_status: string, rh: int, slp: float, snow: float, snow_depth: float, t_dhi: int, t_dni: int, t_ghi: int, temp: float, ts: int, wind_dir: int, wind_gust_spd: float, wind_spd: float>, lat: string, lon: string, sources: list<string>, state_code: string, timezone: string>
export def "get-history-daily-city-city-country-country" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --state: string # Full name of state. (format: string)
  --start-date: string # Start Date (YYYY-MM-DD or YYYY-MM-DD:HH). (required, format: string)
  --end-date: string # End Date (YYYY-MM-DD or YYYY-MM-DD:HH). (required, format: string)
  --units: string@units-completer # Convert to units. Default Metric See units field description (format: string)
  --lang: string@lang-completer # Language (Default: English) See language field description (format: string)
  --callback: string # Wraps return in jsonp callback. Example: callback=func (format: string)
  --key: string # Your registered API key. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/history/daily"
    fixed_query: "city={city}&country={country}"
    query: [{name: state, var: state}, {name: start_date, var: start_date, required: true}, {name: end_date, var: end_date, required: true}, {name: units, var: units}, {name: lang, var: lang}, {name: callback, var: callback}, {name: key, var: key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    state: $state, start_date: $start_date, end_date: $end_date, units: $units, lang: $lang, callback: $callback, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns Historical Observations - Given a City ID
#
# GET /history/daily?city_id={city_id}
# Returns: record<city_name: string, country_code: string, data: table<datetime: string, dewpt: float, dhi: int, dni: int, ghi: int, max_temp: float, max_temp_ts: float, max_uv: float, max_wind_dir: int, max_wind_spd: float, max_wind_spd_ts: float, min_temp: float, min_temp_ts: float, precip: float, precip_gpm: float, pres: float, revision_status: string, rh: int, slp: float, snow: float, snow_depth: float, t_dhi: int, t_dni: int, t_ghi: int, temp: float, ts: int, wind_dir: int, wind_gust_spd: float, wind_spd: float>, lat: string, lon: string, sources: list<string>, state_code: string, timezone: string>
export def "get-history-daily-city-id-city-id" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # Start Date (YYYY-MM-DD or YYYY-MM-DD:HH) (required, format: string)
  --end-date: string # End Date (YYYY-MM-DD or YYYY-MM-DD:HH) (required, format: string)
  --units: string@units-completer # Convert to units. Default Metric See units field description (format: string)
  --lang: string@lang-completer # Language (Default: English) See language field description (format: string)
  --callback: string # Wraps return in jsonp callback. Example: callback=func (format: string)
  --key: string # Your registered API key. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/history/daily"
    fixed_query: "city_id={city_id}"
    query: [{name: start_date, var: start_date, required: true}, {name: end_date, var: end_date, required: true}, {name: units, var: units}, {name: lang, var: lang}, {name: callback, var: callback}, {name: key, var: key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    start_date: $start_date, end_date: $end_date, units: $units, lang: $lang, callback: $callback, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns Historical Observations - Given a lat/lon.
#
# GET /history/daily?lat={lat}&lon={lon}
# Returns: record<city_name: string, country_code: string, data: table<datetime: string, dewpt: float, dhi: int, dni: int, ghi: int, max_temp: float, max_temp_ts: float, max_uv: float, max_wind_dir: int, max_wind_spd: float, max_wind_spd_ts: float, min_temp: float, min_temp_ts: float, precip: float, precip_gpm: float, pres: float, revision_status: string, rh: int, slp: float, snow: float, snow_depth: float, t_dhi: int, t_dni: int, t_ghi: int, temp: float, ts: int, wind_dir: int, wind_gust_spd: float, wind_spd: float>, lat: string, lon: string, sources: list<string>, state_code: string, timezone: string>
export def "get-history-daily-lat-lat-lon-lon" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # Start Date (YYYY-MM-DD or YYYY-MM-DD:HH). (required, format: string)
  --end-date: string # End Date (YYYY-MM-DD or YYYY-MM-DD:HH). (required, format: string)
  --units: string@units-completer # Convert to units. Default Metric See units field description (format: string)
  --lang: string@lang-completer # Language (Default: English) See language field description (format: string)
  --callback: string # Wraps return in jsonp callback. Example: callback=func (format: string)
  --key: string # Your registered API key. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/history/daily"
    fixed_query: "lat={lat}&lon={lon}"
    query: [{name: start_date, var: start_date, required: true}, {name: end_date, var: end_date, required: true}, {name: units, var: units}, {name: lang, var: lang}, {name: callback, var: callback}, {name: key, var: key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    start_date: $start_date, end_date: $end_date, units: $units, lang: $lang, callback: $callback, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns Historical Observations - Given a Postal Code
#
# GET /history/daily?postal_code={postal_code}
# Returns: record<city_name: string, country_code: string, data: table<datetime: string, dewpt: float, dhi: int, dni: int, ghi: int, max_temp: float, max_temp_ts: float, max_uv: float, max_wind_dir: int, max_wind_spd: float, max_wind_spd_ts: float, min_temp: float, min_temp_ts: float, precip: float, precip_gpm: float, pres: float, revision_status: string, rh: int, slp: float, snow: float, snow_depth: float, t_dhi: int, t_dni: int, t_ghi: int, temp: float, ts: int, wind_dir: int, wind_gust_spd: float, wind_spd: float>, lat: string, lon: string, sources: list<string>, state_code: string, timezone: string>
export def "get-history-daily-postal-code-postal-code" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --country: string # Country Code (2 letter). (format: string)
  --start-date: string # Start Date (YYYY-MM-DD or YYYY-MM-DD:HH) (required, format: string)
  --end-date: string # End Date (YYYY-MM-DD or YYYY-MM-DD:HH) (required, format: string)
  --units: string@units-completer # Convert to units. Default Metric See units field description (format: string)
  --lang: string@lang-completer # Language (Default: English) See language field description (format: string)
  --callback: string # Wraps return in jsonp callback. Example: callback=func (format: string)
  --key: string # Your registered API key. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/history/daily"
    fixed_query: "postal_code={postal_code}"
    query: [{name: country, var: country}, {name: start_date, var: start_date, required: true}, {name: end_date, var: end_date, required: true}, {name: units, var: units}, {name: lang, var: lang}, {name: callback, var: callback}, {name: key, var: key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    country: $country, start_date: $start_date, end_date: $end_date, units: $units, lang: $lang, callback: $callback, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns Historical Observations - Given a station ID.
#
# GET /history/daily?station={station}
# Returns: record<city_name: string, country_code: string, data: table<datetime: string, dewpt: float, dhi: int, dni: int, ghi: int, max_temp: float, max_temp_ts: float, max_uv: float, max_wind_dir: int, max_wind_spd: float, max_wind_spd_ts: float, min_temp: float, min_temp_ts: float, precip: float, precip_gpm: float, pres: float, revision_status: string, rh: int, slp: float, snow: float, snow_depth: float, t_dhi: int, t_dni: int, t_ghi: int, temp: float, ts: int, wind_dir: int, wind_gust_spd: float, wind_spd: float>, lat: string, lon: string, sources: list<string>, state_code: string, timezone: string>
export def "get-history-daily-station-station" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # Start Date (YYYY-MM-DD or YYYY-MM-DD:HH). (required, format: string)
  --end-date: string # End Date (YYYY-MM-DD or YYYY-MM-DD:HH). (required, format: string)
  --units: string@units-completer # Convert to units. Default Metric See units field description (format: string)
  --lang: string@lang-completer # Language (Default: English) See language field description (format: string)
  --callback: string # Wraps return in jsonp callback. Example: callback=func (format: string)
  --key: string # Your registered API key. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/history/daily"
    fixed_query: "station={station}"
    query: [{name: start_date, var: start_date, required: true}, {name: end_date, var: end_date, required: true}, {name: units, var: units}, {name: lang, var: lang}, {name: callback, var: callback}, {name: key, var: key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    start_date: $start_date, end_date: $end_date, units: $units, lang: $lang, callback: $callback, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns Energy API response - Given a single lat/lon.
#
# GET /history/energy?lat={lat}&lon={lon}
# Returns: record<count: int, data: table<cdd: float, city_name: string, clouds: int, country_code: string, dewpt: float, hdd: float, lat: string, lon: string, precip: float, rh: int, snow: float, sources: list, state_code: string, station_id: string, sun_hours: float, t_dhi: float, t_dni: float, t_ghi: float, temp: float, timezone: string, wind_dir: int, wind_spd: float>, end_date: int, start_date: int>
export def "get-history-energy-lat-lat-lon-lon" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # Start Date (YYYY-MM-DD or YYYY-MM-DD:HH). (required, format: string)
  --end-date: string # End Date (YYYY-MM-DD or YYYY-MM-DD:HH). (required, format: string)
  --tp: string@tp-completer-1 # Time period to aggregate by (daily, monthly) (format: string)
  --threshold: float # Temperature threshold to use to calculate degree days (default 18 C) (format: double)
  --units: string@units-completer # Convert to units. Default Metric See units field description (format: string)
  --callback: string # Wraps return in jsonp callback. Example: callback=func (format: string)
  --key: string # Your registered API key. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/history/energy"
    fixed_query: "lat={lat}&lon={lon}"
    query: [{name: start_date, var: start_date, required: true}, {name: end_date, var: end_date, required: true}, {name: tp, var: tp}, {name: threshold, var: threshold}, {name: units, var: units}, {name: callback, var: callback}, {name: key, var: key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    start_date: $start_date, end_date: $end_date, tp: $tp, threshold: $threshold, units: $units, callback: $callback, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns Historical Observations - Given City and/or State, Country.
#
# GET /history/hourly?city={city}&country={country}
# Returns: record<city_name: string, country_code: string, data: table<app_temp: float, azimuth: float, clouds: int, datetime: string, dewpt: int, dhi: float, dni: float, elev_angle: float, ghi: float, h_angle: float, pod: string, precip: float, pres: float, revision_status: string, rh: int, slp: float, snow: float, solar_rad: float, temp: float, timestamp_local: string, timestamp_utc: string, ts: float, uv: float, vis: float, weather: record, wind_dir: int, wind_gust_spd: float, wind_spd: float>, lat: string, lon: string, sources: list<string>, state_code: string, timezone: string>
export def "get-history-hourly-city-city-country-country" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --state: string # Full name of state. (format: string)
  --start-date: string # Start Date (YYYY-MM-DD or YYYY-MM-DD:HH). (required, format: string)
  --end-date: string # End Date (YYYY-MM-DD or YYYY-MM-DD:HH). (required, format: string)
  --units: string@units-completer # Convert to units. Default Metric See units field description (format: string)
  --lang: string@lang-completer # Language (Default: English) See language field description (format: string)
  --tz: string@tz-completer # Assume utc (default) or local time for start_date, end_date (format: string)
  --callback: string # Wraps return in jsonp callback. Example: callback=func (format: string)
  --key: string # Your registered API key. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/history/hourly"
    fixed_query: "city={city}&country={country}"
    query: [{name: state, var: state}, {name: start_date, var: start_date, required: true}, {name: end_date, var: end_date, required: true}, {name: units, var: units}, {name: lang, var: lang}, {name: tz, var: tz}, {name: callback, var: callback}, {name: key, var: key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    state: $state, start_date: $start_date, end_date: $end_date, units: $units, lang: $lang, tz: $tz, callback: $callback, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns Historical Observations - Given a City ID
#
# GET /history/hourly?city_id={city_id}
# Returns: record<city_name: string, country_code: string, data: table<app_temp: float, azimuth: float, clouds: int, datetime: string, dewpt: int, dhi: float, dni: float, elev_angle: float, ghi: float, h_angle: float, pod: string, precip: float, pres: float, revision_status: string, rh: int, slp: float, snow: float, solar_rad: float, temp: float, timestamp_local: string, timestamp_utc: string, ts: float, uv: float, vis: float, weather: record, wind_dir: int, wind_gust_spd: float, wind_spd: float>, lat: string, lon: string, sources: list<string>, state_code: string, timezone: string>
export def "get-history-hourly-city-id-city-id" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # Start Date (YYYY-MM-DD or YYYY-MM-DD:HH) (required, format: string)
  --end-date: string # End Date (YYYY-MM-DD or YYYY-MM-DD:HH) (required, format: string)
  --units: string@units-completer # Convert to units. Default Metric See units field description (format: string)
  --lang: string@lang-completer # Language (Default: English) See language field description (format: string)
  --tz: string@tz-completer # Assume utc (default) or local time for start_date, end_date (format: string)
  --callback: string # Wraps return in jsonp callback. Example: callback=func (format: string)
  --key: string # Your registered API key. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/history/hourly"
    fixed_query: "city_id={city_id}"
    query: [{name: start_date, var: start_date, required: true}, {name: end_date, var: end_date, required: true}, {name: units, var: units}, {name: lang, var: lang}, {name: tz, var: tz}, {name: callback, var: callback}, {name: key, var: key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    start_date: $start_date, end_date: $end_date, units: $units, lang: $lang, tz: $tz, callback: $callback, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns Historical Observations - Given a lat/lon.
#
# GET /history/hourly?lat={lat}&lon={lon}
# Returns: record<city_name: string, country_code: string, data: table<app_temp: float, azimuth: float, clouds: int, datetime: string, dewpt: int, dhi: float, dni: float, elev_angle: float, ghi: float, h_angle: float, pod: string, precip: float, pres: float, revision_status: string, rh: int, slp: float, snow: float, solar_rad: float, temp: float, timestamp_local: string, timestamp_utc: string, ts: float, uv: float, vis: float, weather: record, wind_dir: int, wind_gust_spd: float, wind_spd: float>, lat: string, lon: string, sources: list<string>, state_code: string, timezone: string>
export def "get-history-hourly-lat-lat-lon-lon" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # Start Date (YYYY-MM-DD or YYYY-MM-DD:HH). (required, format: string)
  --end-date: string # End Date (YYYY-MM-DD or YYYY-MM-DD:HH). (required, format: string)
  --units: string@units-completer # Convert to units. Default Metric See units field description (format: string)
  --lang: string@lang-completer # Language (Default: English) See language field description (format: string)
  --tz: string@tz-completer # Assume utc (default) or local time for start_date, end_date (format: string)
  --callback: string # Wraps return in jsonp callback. Example: callback=func (format: string)
  --key: string # Your registered API key. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/history/hourly"
    fixed_query: "lat={lat}&lon={lon}"
    query: [{name: start_date, var: start_date, required: true}, {name: end_date, var: end_date, required: true}, {name: units, var: units}, {name: lang, var: lang}, {name: tz, var: tz}, {name: callback, var: callback}, {name: key, var: key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    start_date: $start_date, end_date: $end_date, units: $units, lang: $lang, tz: $tz, callback: $callback, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns Historical Observations - Given a Postal Code
#
# GET /history/hourly?postal_code={postal_code}
# Returns: record<city_name: string, country_code: string, data: table<app_temp: float, azimuth: float, clouds: int, datetime: string, dewpt: int, dhi: float, dni: float, elev_angle: float, ghi: float, h_angle: float, pod: string, precip: float, pres: float, revision_status: string, rh: int, slp: float, snow: float, solar_rad: float, temp: float, timestamp_local: string, timestamp_utc: string, ts: float, uv: float, vis: float, weather: record, wind_dir: int, wind_gust_spd: float, wind_spd: float>, lat: string, lon: string, sources: list<string>, state_code: string, timezone: string>
export def "get-history-hourly-postal-code-postal-code" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --country: string # Country Code (2 letter). (format: string)
  --start-date: string # Start Date (YYYY-MM-DD or YYYY-MM-DD:HH) (required, format: string)
  --end-date: string # End Date (YYYY-MM-DD or YYYY-MM-DD:HH) (required, format: string)
  --units: string@units-completer # Convert to units. Default Metric See units field description (format: string)
  --lang: string@lang-completer # Language (Default: English) See language field description (format: string)
  --tz: string@tz-completer # Assume utc (default) or local time for start_date, end_date (format: string)
  --callback: string # Wraps return in jsonp callback. Example: callback=func (format: string)
  --key: string # Your registered API key. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/history/hourly"
    fixed_query: "postal_code={postal_code}"
    query: [{name: country, var: country}, {name: start_date, var: start_date, required: true}, {name: end_date, var: end_date, required: true}, {name: units, var: units}, {name: lang, var: lang}, {name: tz, var: tz}, {name: callback, var: callback}, {name: key, var: key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    country: $country, start_date: $start_date, end_date: $end_date, units: $units, lang: $lang, tz: $tz, callback: $callback, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns Historical Observations - Given a station ID.
#
# GET /history/hourly?station={station}
# Returns: record<city_name: string, country_code: string, data: table<app_temp: float, azimuth: float, clouds: int, datetime: string, dewpt: int, dhi: float, dni: float, elev_angle: float, ghi: float, h_angle: float, pod: string, precip: float, pres: float, revision_status: string, rh: int, slp: float, snow: float, solar_rad: float, temp: float, timestamp_local: string, timestamp_utc: string, ts: float, uv: float, vis: float, weather: record, wind_dir: int, wind_gust_spd: float, wind_spd: float>, lat: string, lon: string, sources: list<string>, state_code: string, timezone: string>
export def "get-history-hourly-station-station" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # Start Date (YYYY-MM-DD or YYYY-MM-DD:HH). (required, format: string)
  --end-date: string # End Date (YYYY-MM-DD or YYYY-MM-DD:HH). (required, format: string)
  --units: string@units-completer # Convert to units. Default Metric See units field description (format: string)
  --lang: string@lang-completer # Language (Default: English) See language field description (format: string)
  --tz: string@tz-completer # Assume utc (default) or local time for start_date, end_date (format: string)
  --callback: string # Wraps return in jsonp callback. Example: callback=func (format: string)
  --key: string # Your registered API key. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/history/hourly"
    fixed_query: "station={station}"
    query: [{name: start_date, var: start_date, required: true}, {name: end_date, var: end_date, required: true}, {name: units, var: units}, {name: lang, var: lang}, {name: tz, var: tz}, {name: callback, var: callback}, {name: key, var: key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    start_date: $start_date, end_date: $end_date, units: $units, lang: $lang, tz: $tz, callback: $callback, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns Historical Observations - Given City and/or State, Country.
#
# GET /history/subhourly?city={city}&country={country}
# Returns: record<city_name: string, country_code: string, data: table<app_temp: float, azimuth: float, clouds: int, datetime: string, dewpt: int, dhi: float, dni: float, elev_angle: float, ghi: float, h_angle: float, pod: string, precip: float, pres: float, revision_status: string, rh: int, slp: float, snow: float, solar_rad: float, temp: float, timestamp_local: string, timestamp_utc: string, ts: float, uv: float, vis: float, weather: record, wind_dir: int, wind_gust_spd: float, wind_spd: float>, lat: string, lon: string, sources: list<string>, state_code: string, timezone: string>
export def "get-history-subhourly-city-city-country-country" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --state: string # Full name of state. (format: string)
  --start-date: string # Start Date (YYYY-MM-DD or YYYY-MM-DD:HH). (required, format: string)
  --end-date: string # End Date (YYYY-MM-DD or YYYY-MM-DD:HH). (required, format: string)
  --units: string@units-completer # Convert to units. Default Metric See units field description (format: string)
  --lang: string@lang-completer # Language (Default: English) See language field description (format: string)
  --tz: string@tz-completer # Assume utc (default) or local time for start_date, end_date (format: string)
  --callback: string # Wraps return in jsonp callback. Example: callback=func (format: string)
  --key: string # Your registered API key. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/history/subhourly"
    fixed_query: "city={city}&country={country}"
    query: [{name: state, var: state}, {name: start_date, var: start_date, required: true}, {name: end_date, var: end_date, required: true}, {name: units, var: units}, {name: lang, var: lang}, {name: tz, var: tz}, {name: callback, var: callback}, {name: key, var: key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    state: $state, start_date: $start_date, end_date: $end_date, units: $units, lang: $lang, tz: $tz, callback: $callback, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns Historical Observations - Given a City ID
#
# GET /history/subhourly?city_id={city_id}
# Returns: record<city_name: string, country_code: string, data: table<app_temp: float, azimuth: float, clouds: int, datetime: string, dewpt: int, dhi: float, dni: float, elev_angle: float, ghi: float, h_angle: float, pod: string, precip: float, pres: float, revision_status: string, rh: int, slp: float, snow: float, solar_rad: float, temp: float, timestamp_local: string, timestamp_utc: string, ts: float, uv: float, vis: float, weather: record, wind_dir: int, wind_gust_spd: float, wind_spd: float>, lat: string, lon: string, sources: list<string>, state_code: string, timezone: string>
export def "get-history-subhourly-city-id-city-id" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # Start Date (YYYY-MM-DD or YYYY-MM-DD:HH) (required, format: string)
  --end-date: string # End Date (YYYY-MM-DD or YYYY-MM-DD:HH) (required, format: string)
  --units: string@units-completer # Convert to units. Default Metric See units field description (format: string)
  --lang: string@lang-completer # Language (Default: English) See language field description (format: string)
  --tz: string@tz-completer # Assume utc (default) or local time for start_date, end_date (format: string)
  --callback: string # Wraps return in jsonp callback. Example: callback=func (format: string)
  --key: string # Your registered API key. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/history/subhourly"
    fixed_query: "city_id={city_id}"
    query: [{name: start_date, var: start_date, required: true}, {name: end_date, var: end_date, required: true}, {name: units, var: units}, {name: lang, var: lang}, {name: tz, var: tz}, {name: callback, var: callback}, {name: key, var: key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    start_date: $start_date, end_date: $end_date, units: $units, lang: $lang, tz: $tz, callback: $callback, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns Historical Observations - Given a lat/lon.
#
# GET /history/subhourly?lat={lat}&lon={lon}
# Returns: record<city_name: string, country_code: string, data: table<app_temp: float, azimuth: float, clouds: int, datetime: string, dewpt: int, dhi: float, dni: float, elev_angle: float, ghi: float, h_angle: float, pod: string, precip: float, pres: float, revision_status: string, rh: int, slp: float, snow: float, solar_rad: float, temp: float, timestamp_local: string, timestamp_utc: string, ts: float, uv: float, vis: float, weather: record, wind_dir: int, wind_gust_spd: float, wind_spd: float>, lat: string, lon: string, sources: list<string>, state_code: string, timezone: string>
export def "get-history-subhourly-lat-lat-lon-lon" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # Start Date (YYYY-MM-DD or YYYY-MM-DD:HH). (required, format: string)
  --end-date: string # End Date (YYYY-MM-DD or YYYY-MM-DD:HH). (required, format: string)
  --units: string@units-completer # Convert to units. Default Metric See units field description (format: string)
  --lang: string@lang-completer # Language (Default: English) See language field description (format: string)
  --tz: string@tz-completer # Assume utc (default) or local time for start_date, end_date (format: string)
  --callback: string # Wraps return in jsonp callback. Example: callback=func (format: string)
  --key: string # Your registered API key. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/history/subhourly"
    fixed_query: "lat={lat}&lon={lon}"
    query: [{name: start_date, var: start_date, required: true}, {name: end_date, var: end_date, required: true}, {name: units, var: units}, {name: lang, var: lang}, {name: tz, var: tz}, {name: callback, var: callback}, {name: key, var: key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    start_date: $start_date, end_date: $end_date, units: $units, lang: $lang, tz: $tz, callback: $callback, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns Historical Observations - Given a Postal Code
#
# GET /history/subhourly?postal_code={postal_code}
# Returns: record<city_name: string, country_code: string, data: table<app_temp: float, azimuth: float, clouds: int, datetime: string, dewpt: int, dhi: float, dni: float, elev_angle: float, ghi: float, h_angle: float, pod: string, precip: float, pres: float, revision_status: string, rh: int, slp: float, snow: float, solar_rad: float, temp: float, timestamp_local: string, timestamp_utc: string, ts: float, uv: float, vis: float, weather: record, wind_dir: int, wind_gust_spd: float, wind_spd: float>, lat: string, lon: string, sources: list<string>, state_code: string, timezone: string>
export def "get-history-subhourly-postal-code-postal-code" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --country: string # Country Code (2 letter). (format: string)
  --start-date: string # Start Date (YYYY-MM-DD or YYYY-MM-DD:HH) (required, format: string)
  --end-date: string # End Date (YYYY-MM-DD or YYYY-MM-DD:HH) (required, format: string)
  --units: string@units-completer # Convert to units. Default Metric See units field description (format: string)
  --lang: string@lang-completer # Language (Default: English) See language field description (format: string)
  --tz: string@tz-completer # Assume utc (default) or local time for start_date, end_date (format: string)
  --callback: string # Wraps return in jsonp callback. Example: callback=func (format: string)
  --key: string # Your registered API key. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/history/subhourly"
    fixed_query: "postal_code={postal_code}"
    query: [{name: country, var: country}, {name: start_date, var: start_date, required: true}, {name: end_date, var: end_date, required: true}, {name: units, var: units}, {name: lang, var: lang}, {name: tz, var: tz}, {name: callback, var: callback}, {name: key, var: key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    country: $country, start_date: $start_date, end_date: $end_date, units: $units, lang: $lang, tz: $tz, callback: $callback, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns Historical Observations - Given a station ID.
#
# GET /history/subhourly?station={station}
# Returns: record<city_name: string, country_code: string, data: table<app_temp: float, azimuth: float, clouds: int, datetime: string, dewpt: int, dhi: float, dni: float, elev_angle: float, ghi: float, h_angle: float, pod: string, precip: float, pres: float, revision_status: string, rh: int, slp: float, snow: float, solar_rad: float, temp: float, timestamp_local: string, timestamp_utc: string, ts: float, uv: float, vis: float, weather: record, wind_dir: int, wind_gust_spd: float, wind_spd: float>, lat: string, lon: string, sources: list<string>, state_code: string, timezone: string>
export def "get-history-subhourly-station-station" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # Start Date (YYYY-MM-DD or YYYY-MM-DD:HH). (required, format: string)
  --end-date: string # End Date (YYYY-MM-DD or YYYY-MM-DD:HH). (required, format: string)
  --units: string@units-completer # Convert to units. Default Metric See units field description (format: string)
  --lang: string@lang-completer # Language (Default: English) See language field description (format: string)
  --tz: string@tz-completer # Assume utc (default) or local time for start_date, end_date (format: string)
  --callback: string # Wraps return in jsonp callback. Example: callback=func (format: string)
  --key: string # Your registered API key. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/history/subhourly"
    fixed_query: "station={station}"
    query: [{name: start_date, var: start_date, required: true}, {name: end_date, var: end_date, required: true}, {name: units, var: units}, {name: lang, var: lang}, {name: tz, var: tz}, {name: callback, var: callback}, {name: key, var: key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    start_date: $start_date, end_date: $end_date, units: $units, lang: $lang, tz: $tz, callback: $callback, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
