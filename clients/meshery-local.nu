# Auto-generated client for Meshery API. v0.4.27
# Source: https://api.apis.guru/v2/specs/meshery.local/0.4.27/openapi.json
# Auth: --token flag or $env.MESHERY_API_TOKEN

const CLIENT = {
  base_url: "http://meshery.local"
  token_env_var: "MESHERY_API_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: cookie-token, in: cookie, header_name: token, prefix: ""}
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

def base-url-completer [] { ["http://meshery.local" "https://api.apis.guru"] }
def auth-scheme-completer [] { ["cookie-token"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    id-get-application-file-request: "record<applications: table<application_file: string, created_at: string, id: list, location: record, name: string, updated_at: string, user_id: string>, page: int, page_size: int, total_count: int>"
    id-post-application-file-request: "record<application_file: string, created_at: string, id: list<int>, location: record, name: string, updated_at: string, user_id: string>"
    id-post-deploy-application-file: "record<application_file: string, created_at: string, id: list<int>, location: record, name: string, updated_at: string, user_id: string>"
    id-get-meshery-application: "record<application_file: string, created_at: string, id: list<int>, location: record, name: string, updated_at: string, user_id: string>"
    id-get-filter-file: "record<filters: table<created_at: string, filter_file: string, id: list, location: record, name: string, updated_at: string, user_id: string>, page: int, page_size: int, total_count: int>"
    id-post-filter-file: "record<created_at: string, filter_file: string, id: list<int>, location: record, name: string, updated_at: string, user_id: string>"
    id-get-filter-files: "record<created_at: string, filter_file: string, id: list<int>, location: record, name: string, updated_at: string, user_id: string>"
    id-get-meshery-filter: "record<created_at: string, filter_file: string, id: list<int>, location: record, name: string, updated_at: string, user_id: string>"
    id-get-pattern-files: "record<page: int, page_size: int, patterns: table<created_at: string, id: list, location: record, name: string, pattern_file: string, updated_at: string, user_id: string>, total_count: int>"
    id-post-pattern-file: "record<created_at: string, id: list<int>, location: record, name: string, pattern_file: string, updated_at: string, user_id: string>"
    id-get-meshery-pattern: "record<created_at: string, id: list<int>, location: record, name: string, pattern_file: string, updated_at: string, user_id: string>"
    id-get-all-perf-results: "record<page: int, page_size: int, results: table<mesh: string, meshery_id: list, name: string, performance_profile: list, runner_results: record, server_board_config: record, server_metrics: record, test_start_time: string, user_id: list>, total_count: int>"
    id-get-single-perf-result: "record<ActualQPS: float, DetailsURI: string, EndTime: string, EnvID: string, Latencies: record<Average: float, Max: float, Min: float, P50: float, P90: float, P99: float>, MeshConfigID: string, SMPVersion: string, StartTime: string, TestID: string>"
    id-get-providers-list: "record"
    id-post-adapter-config: "table<adapter_location: string, git_commit_sha: string, name: string, ops: list<record>, version: string>"
    id-get-system-adapters: "table<adapter_location: string, git_commit_sha: string, name: string, ops: list<record>, version: string>"
    id-post-k8s-config: "record<clusterConfigured: bool, config: list<int>, configuredServer: string, contextName: string, inClusterConfig: bool, k8sfile: string, nodes: table<allocatable_cpu: string, allocatable_memory: string, architecture: string, capacity_cpu: string, capacity_memory: string, container_runtime_version: string, hostname: string, internal_ip: string, kubelet_version: string, kubeproxy_version: string, operating_system: string, os_image: string>, server_version: string>"
    id-post-k8s-contexts: "table<clusterName: string, contextName: string, currentContext: bool>"
    id-mesh-sync-grafana: "record"
    id-mesh-sync-prometheus: "record"
    id-system-sync: "record<anonymousPerfResults: bool, anonymousUsageStats: bool, grafana: record<grafanaAPIKey: string, grafanaURL: string, selectedBoardsConfigs: list<record>>, k8sConfig: record<clusterConfigured: bool, config: list<int>, configuredServer: string, contextName: string, inClusterConfig: bool, k8sfile: string, nodes: list<record>, server_version: string>, loadTestPrefs: record<c: int, gen: string, qps: int, t: string>, meshAdapters: table<adapter_location: string, git_commit_sha: string, name: string, ops: list, version: string>, prometheus: record<prometheusURL: string, selectedPrometheusBoardsConfigs: list<record>>, updated_at: string>"
    id-get-system-version: "record<build: string, commitsha: string, latest: string, outdated: bool, release_channel: string>"
    id-post-prometheus-board-import: "record<org_id: int, panels: table<alert: record, aliasColors: record, bars: bool, cards: record, collapsed: bool, color: record, colorBackground: bool, colorValue: bool, colors: list, columns: list, content: string, dashLength: int, dashboardTags: list, dashes: bool, dataFormat: string, datasource: string, decimals: int, description: string, editable: bool, error: bool, fieldConfig: record, fill: int, folderId: int, format: string, gauge: record, gridPos: record, headings: bool, height: record, hideTimeOverride: bool, hideZeroBuckets: bool, highlightCards: bool, id: int, isNew: bool, leftYAxisLabel: string, legend: record, limit: int, lines: bool, linewidth: int, links: list, mappingType: int, mappingTypes: list, maxDataPoints: record, minSpan: float, mode: string, nameFilter: string, nullPointMode: string, onlyAlertsOnDashboard: bool, options: record, pageSize: int, panels: list, percentage: bool, pointradius: float, points: bool, postfix: string, postfixFontSize: string, prefix: string, prefixFontSize: string, query: string, rangeMaps: list, recent: bool, renderer: string, repeat: string, repeatPanelId: int, reverseYBuckets: bool, rightYAxisLabel: string, scopedVars: record, scroll: bool, search: bool, seriesOverrides: list, show: string, showHeader: bool, sort: record, sortOrder: int, spaceLength: int, span: float, sparkline: record, stack: bool, starred: bool, stateFilter: list, steppedLine: bool, styles: list, tags: list, targets: list, thresholds: string, timeFrom: string, timeShift: string, title: string, tooltip: record, tooltipDecimals: int, transform: string, transparent: bool, type: string, valueFontSize: string, valueMaps: list, valueName: string, x-axis: bool, xAxis: record, xBucketNumber: float, xBucketSize: string, xaxis: record, y-axis: bool, yAxis: record, yBucketBound: string, yBucketNumber: float, yBucketSize: float, y_formats: list, yaxes: list>, slug: string, template_vars: table<datasource: record, hide: int, name: string, query: string, value: record>, title: string, uid: string, uri: string>"
    id-get-prometheus-config: "record<prometheusURL: string, selectedPrometheusBoardsConfigs: table<board: record, panels: list, templateVars: list>>"
    id-get-grafana-boards: "table<org_id: int, panels: list<record>, slug: string, template_vars: list<record>, title: string, uid: string, uri: string>"
    id-get-grafana-config: "record<grafanaAPIKey: string, grafanaURL: string, selectedBoardsConfigs: table<board: record, panels: list, templateVars: list>>"
    id-get-grafana: "record"
    id-get-prometheus-static-board: "record"
    id-get-performance-profiles: "record<page: int, page_size: int, profiles: table<concurrent_request: int, content_type: string, created_at: record, duration: string, endpoints: list, id: list, last_run: record, load_generators: list, name: string, qps: int, request_body: string, request_cookies: string, request_headers: string, schedule: list, service_mesh: string, total_results: int, updated_at: record>, total_count: int>"
    id-save-performance-profile: "record<concurrent_request: int, content_type: string, created_at: record, duration: string, endpoints: list<string>, id: list<int>, last_run: record, load_generators: list<string>, name: string, qps: int, request_body: string, request_cookies: string, request_headers: string, schedule: list<int>, service_mesh: string, total_results: int, updated_at: record>"
    id-get-all-performance-results: "record<page: int, page_size: int, results: table<mesh: string, meshery_id: list, name: string, performance_profile: list, runner_results: record, server_board_config: record, server_metrics: record, test_start_time: string, user_id: list>, total_count: int>"
    id-get-single-performance-profile: "record<concurrent_request: int, content_type: string, created_at: record, duration: string, endpoints: list<string>, id: list<int>, last_run: record, load_generators: list<string>, name: string, qps: int, request_body: string, request_cookies: string, request_headers: string, schedule: list<int>, service_mesh: string, total_results: int, updated_at: record>"
    id-get-profile-results: "record<page: int, page_size: int, results: table<mesh: string, meshery_id: list, name: string, performance_profile: list, runner_results: record, server_board_config: record, server_metrics: record, test_start_time: string, user_id: list>, total_count: int>"
    id-get-user-test-prefs: "record<anonymousPerfResults: bool, anonymousUsageStats: bool, grafana: record<grafanaAPIKey: string, grafanaURL: string, selectedBoardsConfigs: list<record>>, k8sConfig: record<clusterConfigured: bool, config: list<int>, configuredServer: string, contextName: string, inClusterConfig: bool, k8sfile: string, nodes: list<record>, server_version: string>, loadTestPrefs: record<c: int, gen: string, qps: int, t: string>, meshAdapters: table<adapter_location: string, git_commit_sha: string, name: string, ops: list, version: string>, prometheus: record<prometheusURL: string, selectedPrometheusBoardsConfigs: list<record>>, updated_at: string>"
    id-post-user-test-prefs: "record<anonymousPerfResults: bool, anonymousUsageStats: bool, grafana: record<grafanaAPIKey: string, grafanaURL: string, selectedBoardsConfigs: list<record>>, k8sConfig: record<clusterConfigured: bool, config: list<int>, configuredServer: string, contextName: string, inClusterConfig: bool, k8sfile: string, nodes: list<record>, server_version: string>, loadTestPrefs: record<c: int, gen: string, qps: int, t: string>, meshAdapters: table<adapter_location: string, git_commit_sha: string, name: string, ops: list, version: string>, prometheus: record<prometheusURL: string, selectedPrometheusBoardsConfigs: list<record>>, updated_at: string>"
    id-get-load-preferences: "record<clients: table<body: string, connections: int, content_type: string, cookies: record, endpoint_urls: list, headers: record, internal: bool, load_generator: string, protocol: int, rps: int>, duration: string, id: string, labels: record, name: string, smp_version: string>"
    id-get-schedules: "record<page: int, page_size: int, schedules: table<cron_expression: string, id: list>, total_count: int>"
    id-post-schedules: "record<cron_expression: string, id: list<int>>"
    id-delete-schedules: "record<page: int, page_size: int, schedules: table<cron_expression: string, id: list>, total_count: int>"
    id-get-single-schedule: "record<cron_expression: string, id: list<int>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["id-get-application-file-request" "id-post-application-file-request" "id-delete-application-file" "id-post-deploy-application-file" "id-delete-meshery-application-file" "id-get-meshery-application" "id-get-filter-file" "id-post-filter-file" "id-get-filter-files" "id-delete-meshery-filter" "id-get-meshery-filter" "id-getoam-meshery-pattern" "id-postoam-meshery-pattern" "id-get-pattern-files" "id-post-pattern-file" "id-delete-deploy-pattern" "id-post-deploy-pattern" "id-delete-meshery-pattern" "id-get-meshery-pattern" "id-run-perf-test" "id-get-all-perf-results" "id-get-single-perf-result" "id-choice-provider" "id-get-provider-capabilities" "id-react-components" "id-get-providers-list" "id-delete-adapter-config" "id-post-adapter-config" "id-post-adapter-operation" "id-get-system-adapters" "id-delete-k8s-config" "id-post-k8s-config" "id-post-k8s-contexts" "id-get-kubernetes-ping" "id-mesh-sync-grafana" "id-mesh-sync-prometheus" "id-system-sync" "id-get-system-version" "id-post-prometheus-board-import" "id-post-prometheus-board" "id-delete-prometheus-config" "id-get-prometheus-config" "id-post-prometheus-config" "id-get-grafana-boards" "id-post-grafana-boards" "id-delete-grafana-config" "id-get-grafana-config" "id-post-grafana-config" "id-get-grafana-ping" "id-get-grafana-query" "id-get-grafana" "id-get-prometheus-ping" "id-get-prometheus-query" "id-get-prometheus-static-board" "id-get-user-login" "id-get-user-logout" "id-get-performance-profiles" "id-save-performance-profile" "id-get-all-performance-results" "id-delete-performance-profile" "id-get-single-performance-profile" "id-get-profile-results" "id-run-performance-test" "id-get-user-test-prefs" "id-post-user-test-prefs" "id-delete-load-preferences" "id-get-load-preferences" "id-post-load-preferences" "id-get-schedules" "id-post-schedules" "id-delete-schedules" "id-get-single-schedule" "id-get-token-provider" "id-post-token-provider" "id-provider" "commands"] | sort) } | get name | first)
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

# Handle GET request for Application Files
#
# GET /api/application/
# Returns: record<applications: table<application_file: string, created_at: string, id: list, location: record, name: string, updated_at: string, user_id: string>, page: int, page_size: int, total_count: int>
# operationId: idGetApplicationFileRequest
export def "id-get-application-file-request" [
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
    path: "/api/application/"
    accept: ["application/json"]
    ok: [200]
    auth: cookie-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handle POST request for Application Files
#
# POST /api/application/
# Returns: record<application_file: string, created_at: string, id: list<int>, location: record, name: string, updated_at: string, user_id: string>
# operationId: idPostApplicationFileRequest
export def "id-post-application-file-request" [
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
    method: post
    path: "/api/application/"
    accept: ["application/json"]
    ok: [200]
    auth: cookie-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handle DELETE request for Application File Deploy
#
# DELETE /api/application/deploy
# operationId: idDeleteApplicationFile
export def "id-delete-application-file" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/application/deploy"
    accept: ["application/json"]
    ok: [200]
    auth: cookie-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handle POST request for Application File Deploy
#
# POST /api/application/deploy
# Returns: record<application_file: string, created_at: string, id: list<int>, location: record, name: string, updated_at: string, user_id: string>
# operationId: idPostDeployApplicationFile
export def "id-post-deploy-application-file" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --upload-yaml-yml-file: string # format: binary
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/application/deploy"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: "Upload Yaml/Yml File", var: upload_yaml_yml_file}], files: ["Upload Yaml/Yml File"]}
    accept: ["application/json"]
    ok: [200]
    auth: cookie-token
  } {
    upload_yaml_yml_file: $upload_yaml_yml_file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handle Delete for a Meshery Application File
#
# DELETE /api/application/{id}
# operationId: idDeleteMesheryApplicationFile
export def "id-delete-meshery-application-file" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/application/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: cookie-token
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handle GET request for Meshery Application with the given id
#
# GET /api/application/{id}
# Returns: record<application_file: string, created_at: string, id: list<int>, location: record, name: string, updated_at: string, user_id: string>
# operationId: idGetMesheryApplication
export def "id-get-meshery-application" [
  id: string
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
    path: "/api/application/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: cookie-token
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handle GET request for all filters
#
# GET /api/filter
# Returns: record<filters: table<created_at: string, filter_file: string, id: list, location: record, name: string, updated_at: string, user_id: string>, page: int, page_size: int, total_count: int>
# operationId: idGetFilterFile
export def "id-get-filter-file" [
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
    path: "/api/filter"
    accept: ["application/json"]
    ok: [200]
    auth: cookie-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handle POST requests for Meshery Filters
#
# POST /api/filter
# Returns: record<created_at: string, filter_file: string, id: list<int>, location: record, name: string, updated_at: string, user_id: string>
# operationId: idPostFilterFile
export def "id-post-filter-file" [
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
    method: post
    path: "/api/filter"
    accept: ["application/json"]
    ok: [200]
    auth: cookie-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handle GET request for filter file with given id
#
# GET /api/filter/file/{id}
# Returns: record<created_at: string, filter_file: string, id: list<int>, location: record, name: string, updated_at: string, user_id: string>
# operationId: idGetFilterFiles
export def "id-get-filter-files" [
  id: string
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
    path: "/api/filter/file/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: cookie-token
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handle Delete for a Meshery Filter
#
# DELETE /api/filter/{id}
# operationId: idDeleteMesheryFilter
export def "id-delete-meshery-filter" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/filter/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: cookie-token
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handle GET request for a Meshery Filter
#
# GET /api/filter/{id}
# Returns: record<created_at: string, filter_file: string, id: list<int>, location: record, name: string, updated_at: string, user_id: string>
# operationId: idGetMesheryFilter
export def "id-get-meshery-filter" [
  id: string
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
    path: "/api/filter/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: cookie-token
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handles the get requests for the OAM objects
#
# GET /api/oam/{type}
# operationId: idGETOAMMesheryPattern
export def "id-getoam-meshery-pattern" [
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/api/oam/{type}"
    path_params: [{name: type, var: type}]
    accept: ["application/json"]
    ok: [200]
    auth: cookie-token
  } {
    type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handles registering OMA objects
#
# POST /api/oam/{type}
# operationId: idPOSTOAMMesheryPattern
export def "id-postoam-meshery-pattern" [
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: post
    path: "/api/oam/{type}"
    path_params: [{name: type, var: type}]
    accept: ["application/json"]
    ok: [200]
    auth: cookie-token
  } {
    type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handle GET request for patterns
#
# GET /api/pattern
# Returns: record<page: int, page_size: int, patterns: table<created_at: string, id: list, location: record, name: string, pattern_file: string, updated_at: string, user_id: string>, total_count: int>
# operationId: idGetPatternFiles
export def "id-get-pattern-files" [
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
    path: "/api/pattern"
    accept: ["application/json"]
    ok: [200]
    auth: cookie-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handle POST requests for patterns
#
# POST /api/pattern
# Returns: record<created_at: string, id: list<int>, location: record, name: string, pattern_file: string, updated_at: string, user_id: string>
# operationId: idPostPatternFile
export def "id-post-pattern-file" [
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
    method: post
    path: "/api/pattern"
    accept: ["application/json"]
    ok: [200]
    auth: cookie-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handle DELETE request for Pattern Deploy
#
# DELETE /api/pattern/deploy
# operationId: idDeleteDeployPattern
export def "id-delete-deploy-pattern" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/pattern/deploy"
    accept: ["application/json"]
    ok: [200]
    auth: cookie-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handle POST request for Pattern Deploy
#
# POST /api/pattern/deploy
# operationId: idPostDeployPattern
export def "id-post-deploy-pattern" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --upload-yaml-yml-file: string # format: binary
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/pattern/deploy"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: "Upload Yaml/Yml File", var: upload_yaml_yml_file}], files: ["Upload Yaml/Yml File"]}
    accept: ["application/json"]
    ok: [200]
    auth: cookie-token
  } {
    upload_yaml_yml_file: $upload_yaml_yml_file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handle Delete for a Meshery Pattern
#
# DELETE /api/pattern/{id}
# operationId: idDeleteMesheryPattern
export def "id-delete-meshery-pattern" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/pattern/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: cookie-token
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handle GET for a Meshery Pattern
#
# GET /api/pattern/{id}
# Returns: record<created_at: string, id: list<int>, location: record, name: string, pattern_file: string, updated_at: string, user_id: string>
# operationId: idGetMesheryPattern
export def "id-get-meshery-pattern" [
  id: string
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
    path: "/api/pattern/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: cookie-token
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handle GET request to run a test
#
# GET /api/perf/profile
# operationId: idRunPerfTest
export def "id-run-perf-test" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/api/perf/profile"
    accept: ["application/json"]
    ok: [200]
    auth: cookie-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handles GET requests for perf results
#
# GET /api/perf/profile/result
# Returns: record<page: int, page_size: int, results: table<mesh: string, meshery_id: list, name: string, performance_profile: list, runner_results: record, server_board_config: record, server_metrics: record, test_start_time: string, user_id: list>, total_count: int>
# operationId: idGetAllPerfResults
export def "id-get-all-perf-results" [
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
    path: "/api/perf/profile/result"
    accept: ["application/json"]
    ok: [200]
    auth: cookie-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handles GET requests for perf result
#
# GET /api/perf/profile/result/{id}
# Returns: record<ActualQPS: float, DetailsURI: string, EndTime: string, EnvID: string, Latencies: record<Average: float, Max: float, Min: float, P50: float, P90: float, P99: float>, MeshConfigID: string, SMPVersion: string, StartTime: string, TestID: string>
# operationId: idGetSinglePerfResult
export def "id-get-single-perf-result" [
  id: string
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
    path: "/api/perf/profile/result/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: cookie-token
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handle GET request for the choice of provider
#
# GET /api/provider
# operationId: idChoiceProvider
export def "id-choice-provider" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --provider: string
]: nothing -> any {
  http-request {
    method: get
    path: "/api/provider"
    query: [{name: provider, var: provider}]
    accept: ["application/json"]
    ok: [200]
    auth: cookie-token
  } {
    provider: $provider
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handle GET requests for Provider
#
# GET /api/provider/capabilities
# operationId: idGetProviderCapabilities
export def "id-get-provider-capabilities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/api/provider/capabilities"
    accept: ["application/json"]
    ok: [200]
    auth: cookie-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handle GET request for React Components
#
# GET /api/provider/extension
# operationId: idReactComponents
export def "id-react-components" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/api/provider/extension"
    accept: ["application/json"]
    ok: [200]
    auth: cookie-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handle GET request for list of providers
#
# GET /api/providers
# Returns: record
# operationId: idGetProvidersList
export def "id-get-providers-list" [
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
    path: "/api/providers"
    accept: ["application/json"]
    ok: [200]
    auth: cookie-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handle DELETE requests to delete adapter config
#
# DELETE /api/system/adapter/manage
# operationId: idDeleteAdapterConfig
export def "id-delete-adapter-config" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --adapter: string
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/system/adapter/manage"
    query: [{name: adapter, var: adapter}]
    accept: ["application/json"]
    ok: [200]
    auth: cookie-token
  } {
    adapter: $adapter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handle POST requests to persist adapter config
#
# POST /api/system/adapter/manage
# Returns: table<adapter_location: string, git_commit_sha: string, name: string, ops: list<record>, version: string>
# operationId: idPostAdapterConfig
export def "id-post-adapter-config" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: string
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/system/adapter/manage"
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: cookie-token
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handle POST requests for Adapter Operations
#
# POST /api/system/adapter/operation
# operationId: idPostAdapterOperation
export def "id-post-adapter-operation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --adapter: string
  --query: string
  --custom-body: string
  --namespace: string
  --delete-op: string
]: nothing -> any {
  http-request {
    method: post
    path: "/api/system/adapter/operation"
    query: [{name: adapter, var: adapter}, {name: query, var: query}, {name: customBody, var: custom_body}, {name: namespace, var: namespace}, {name: deleteOp, var: delete_op}]
    accept: ["application/json"]
    ok: [200]
    auth: cookie-token
  } {
    adapter: $adapter, query: $query, custom_body: $custom_body, namespace: $namespace, delete_op: $delete_op
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handle GET request for adapters
#
# GET /api/system/adapters
# Returns: table<adapter_location: string, git_commit_sha: string, name: string, ops: list<record>, version: string>
# operationId: idGetSystemAdapters
export def "id-get-system-adapters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --adapter: string
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/system/adapters"
    query: [{name: adapter, var: adapter}]
    accept: ["application/json"]
    ok: [200]
    auth: cookie-token
  } {
    adapter: $adapter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handle DELETE request for Kubernetes Config
#
# DELETE /api/system/kubernetes
# operationId: idDeleteK8SConfig
export def "id-delete-k8s-config" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/system/kubernetes"
    accept: ["application/json"]
    ok: [200]
    auth: cookie-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handle POST request for Kubernetes Config
#
# POST /api/system/kubernetes
# Returns: record<clusterConfigured: bool, config: list<int>, configuredServer: string, contextName: string, inClusterConfig: bool, k8sfile: string, nodes: table<allocatable_cpu: string, allocatable_memory: string, architecture: string, capacity_cpu: string, capacity_memory: string, container_runtime_version: string, hostname: string, internal_ip: string, kubelet_version: string, kubeproxy_version: string, operating_system: string, os_image: string>, server_version: string>
# operationId: idPostK8SConfig
export def "id-post-k8s-config" [
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
    method: post
    path: "/api/system/kubernetes"
    accept: ["application/json"]
    ok: [200]
    auth: cookie-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handle POST requests for Kubernetes Context list
#
# POST /api/system/kubernetes/contexts
# Returns: table<clusterName: string, contextName: string, currentContext: bool>
# operationId: idPostK8SContexts
export def "id-post-k8s-contexts" [
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
    method: post
    path: "/api/system/kubernetes/contexts"
    accept: ["application/json"]
    ok: [200]
    auth: cookie-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handle GET request for Kubernetes ping
#
# GET /api/system/kubernetes/ping
# operationId: idGetKubernetesPing
export def "id-get-kubernetes-ping" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/api/system/kubernetes/ping"
    accept: ["application/json"]
    ok: [200]
    auth: cookie-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handle GET request for mesh-sync grafana
#
# GET /api/system/meshsync/grafana
# Returns: record
# operationId: idMeshSyncGrafana
export def "id-mesh-sync-grafana" [
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
    path: "/api/system/meshsync/grafana"
    accept: ["application/json"]
    ok: [200]
    auth: cookie-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handle GET request for fetching prometheus
#
# GET /api/system/meshsync/prometheus
# Returns: record
# operationId: idMeshSyncPrometheus
export def "id-mesh-sync-prometheus" [
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
    path: "/api/system/meshsync/prometheus"
    accept: ["application/json"]
    ok: [200]
    auth: cookie-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handle GET request for config sync
#
# GET /api/system/sync
# Returns: record<anonymousPerfResults: bool, anonymousUsageStats: bool, grafana: record<grafanaAPIKey: string, grafanaURL: string, selectedBoardsConfigs: list<record>>, k8sConfig: record<clusterConfigured: bool, config: list<int>, configuredServer: string, contextName: string, inClusterConfig: bool, k8sfile: string, nodes: list<record>, server_version: string>, loadTestPrefs: record<c: int, gen: string, qps: int, t: string>, meshAdapters: table<adapter_location: string, git_commit_sha: string, name: string, ops: list, version: string>, prometheus: record<prometheusURL: string, selectedPrometheusBoardsConfigs: list<record>>, updated_at: string>
# operationId: idSystemSync
export def "id-system-sync" [
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
    path: "/api/system/sync"
    accept: ["application/json"]
    ok: [200]
    auth: cookie-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handle GET request for system/server version
#
# GET /api/system/version
# Returns: record<build: string, commitsha: string, latest: string, outdated: bool, release_channel: string>
# operationId: idGetSystemVersion
export def "id-get-system-version" [
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
    path: "/api/system/version"
    accept: ["application/json"]
    ok: [200]
    auth: cookie-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handle POST request for Prometheus board import
#
# POST /api/telemetry/metrics/board_import
# Returns: record<org_id: int, panels: table<alert: record, aliasColors: record, bars: bool, cards: record, collapsed: bool, color: record, colorBackground: bool, colorValue: bool, colors: list, columns: list, content: string, dashLength: int, dashboardTags: list, dashes: bool, dataFormat: string, datasource: string, decimals: int, description: string, editable: bool, error: bool, fieldConfig: record, fill: int, folderId: int, format: string, gauge: record, gridPos: record, headings: bool, height: record, hideTimeOverride: bool, hideZeroBuckets: bool, highlightCards: bool, id: int, isNew: bool, leftYAxisLabel: string, legend: record, limit: int, lines: bool, linewidth: int, links: list, mappingType: int, mappingTypes: list, maxDataPoints: record, minSpan: float, mode: string, nameFilter: string, nullPointMode: string, onlyAlertsOnDashboard: bool, options: record, pageSize: int, panels: list, percentage: bool, pointradius: float, points: bool, postfix: string, postfixFontSize: string, prefix: string, prefixFontSize: string, query: string, rangeMaps: list, recent: bool, renderer: string, repeat: string, repeatPanelId: int, reverseYBuckets: bool, rightYAxisLabel: string, scopedVars: record, scroll: bool, search: bool, seriesOverrides: list, show: string, showHeader: bool, sort: record, sortOrder: int, spaceLength: int, span: float, sparkline: record, stack: bool, starred: bool, stateFilter: list, steppedLine: bool, styles: list, tags: list, targets: list, thresholds: string, timeFrom: string, timeShift: string, title: string, tooltip: record, tooltipDecimals: int, transform: string, transparent: bool, type: string, valueFontSize: string, valueMaps: list, valueName: string, x-axis: bool, xAxis: record, xBucketNumber: float, xBucketSize: string, xaxis: record, y-axis: bool, yAxis: record, yBucketBound: string, yBucketNumber: float, yBucketSize: float, y_formats: list, yaxes: list>, slug: string, template_vars: table<datasource: record, hide: int, name: string, query: string, value: record>, title: string, uid: string, uri: string>
# operationId: idPostPrometheusBoardImport
export def "id-post-prometheus-board-import" [
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
    method: post
    path: "/api/telemetry/metrics/board_import"
    accept: ["application/json"]
    ok: [200]
    auth: cookie-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handle POST request for Prometheus board
#
# POST /api/telemetry/metrics/boards
# operationId: idPostPrometheusBoard
export def "id-post-prometheus-board" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/telemetry/metrics/boards"
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: cookie-token
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handle DELETE for Prometheus configuration
#
# DELETE /api/telemetry/metrics/config
# operationId: idDeletePrometheusConfig
export def "id-delete-prometheus-config" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/telemetry/metrics/config"
    accept: ["application/json"]
    ok: [200]
    auth: cookie-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handle GET for Prometheus configuration
#
# GET /api/telemetry/metrics/config
# Returns: record<prometheusURL: string, selectedPrometheusBoardsConfigs: table<board: record, panels: list, templateVars: list>>
# operationId: idGetPrometheusConfig
export def "id-get-prometheus-config" [
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
    path: "/api/telemetry/metrics/config"
    accept: ["application/json"]
    ok: [200]
    auth: cookie-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handle POST for Prometheus configuration
#
# POST /api/telemetry/metrics/config
# operationId: idPostPrometheusConfig
export def "id-post-prometheus-config" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/telemetry/metrics/config"
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: cookie-token
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handle GET request for Grafana boards
#
# GET /api/telemetry/metrics/grafana/boards
# Returns: table<org_id: int, panels: list<record>, slug: string, template_vars: list<record>, title: string, uid: string, uri: string>
# operationId: idGetGrafanaBoards
export def "id-get-grafana-boards" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --dashboard-search: string
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/telemetry/metrics/grafana/boards"
    query: [{name: dashboardSearch, var: dashboard_search}]
    accept: ["application/json"]
    ok: [200]
    auth: cookie-token
  } {
    dashboard_search: $dashboard_search
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handle POST request for Grafana boards
#
# POST /api/telemetry/metrics/grafana/boards
# operationId: idPostGrafanaBoards
export def "id-post-grafana-boards" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: post
    path: "/api/telemetry/metrics/grafana/boards"
    accept: ["application/json"]
    ok: [200]
    auth: cookie-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handle DELETE request for Grafana configuration
#
# DELETE /api/telemetry/metrics/grafana/config
# operationId: idDeleteGrafanaConfig
export def "id-delete-grafana-config" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/telemetry/metrics/grafana/config"
    accept: ["application/json"]
    ok: [200]
    auth: cookie-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handle GET request for Grafana configuration
#
# GET /api/telemetry/metrics/grafana/config
# Returns: record<grafanaAPIKey: string, grafanaURL: string, selectedBoardsConfigs: table<board: record, panels: list, templateVars: list>>
# operationId: idGetGrafanaConfig
export def "id-get-grafana-config" [
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
    path: "/api/telemetry/metrics/grafana/config"
    accept: ["application/json"]
    ok: [200]
    auth: cookie-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handle POST request for Grafana configuration
#
# POST /api/telemetry/metrics/grafana/config
# operationId: idPostGrafanaConfig
export def "id-post-grafana-config" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --grafana-api-key: string
  --grafana-url: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/telemetry/metrics/grafana/config"
    body: {content_type: "application/json", kind: json, fields: [{name: grafanaAPIKey, var: grafana_api_key}, {name: grafanaURL, var: grafana_url}]}
    accept: ["application/json"]
    ok: [200]
    auth: cookie-token
  } {
    grafana_api_key: $grafana_api_key, grafana_url: $grafana_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handle GET request for Grafana ping
#
# GET /api/telemetry/metrics/grafana/ping
# operationId: idGetGrafanaPing
export def "id-get-grafana-ping" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/api/telemetry/metrics/grafana/ping"
    accept: ["application/json"]
    ok: [200]
    auth: cookie-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handle GET request for Grafana queries
#
# GET /api/telemetry/metrics/grafana/query
# operationId: idGetGrafanaQuery
export def "id-get-grafana-query" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/api/telemetry/metrics/grafana/query"
    accept: ["application/json"]
    ok: [200]
    auth: cookie-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handle GET request for Grafana
#
# GET /api/telemetry/metrics/grafana/scan
# Returns: record
# operationId: idGetGrafana
export def "id-get-grafana" [
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
    path: "/api/telemetry/metrics/grafana/scan"
    accept: ["application/json"]
    ok: [200]
    auth: cookie-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handle GET request for Prometheus Ping
#
# GET /api/telemetry/metrics/ping
# operationId: idGetPrometheusPing
export def "id-get-prometheus-ping" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/api/telemetry/metrics/ping"
    accept: ["application/json"]
    ok: [200]
    auth: cookie-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handle GET request for Prometheus Query
#
# GET /api/telemetry/metrics/query
# operationId: idGetPrometheusQuery
export def "id-get-prometheus-query" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/api/telemetry/metrics/query"
    accept: ["application/json"]
    ok: [200]
    auth: cookie-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handle GET request for Prometheus static board
#
# GET /api/telemetry/metrics/static-board
# Returns: record
# operationId: idGetPrometheusStaticBoard
export def "id-get-prometheus-static-board" [
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
    path: "/api/telemetry/metrics/static-board"
    accept: ["application/json"]
    ok: [200]
    auth: cookie-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handlers GET request for User login
#
# GET /api/user/login
# operationId: idGetUserLogin
export def "id-get-user-login" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/api/user/login"
    accept: ["application/json"]
    ok: [200]
    auth: cookie-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handlers GET request for User logout
#
# GET /api/user/logout
# operationId: idGetUserLogout
export def "id-get-user-logout" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/api/user/logout"
    accept: ["application/json"]
    ok: [200]
    auth: cookie-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handle GET requests for performance profiles
#
# GET /api/user/performance/profiles
# Returns: record<page: int, page_size: int, profiles: table<concurrent_request: int, content_type: string, created_at: record, duration: string, endpoints: list, id: list, last_run: record, load_generators: list, name: string, qps: int, request_body: string, request_cookies: string, request_headers: string, schedule: list, service_mesh: string, total_results: int, updated_at: record>, total_count: int>
# operationId: idGetPerformanceProfiles
export def "id-get-performance-profiles" [
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
    path: "/api/user/performance/profiles"
    accept: ["application/json"]
    ok: [200]
    auth: cookie-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handle POST requests for saving performance profile
#
# POST /api/user/performance/profiles
# Returns: record<concurrent_request: int, content_type: string, created_at: record, duration: string, endpoints: list<string>, id: list<int>, last_run: record, load_generators: list<string>, name: string, qps: int, request_body: string, request_cookies: string, request_headers: string, schedule: list<int>, service_mesh: string, total_results: int, updated_at: record>
# operationId: idSavePerformanceProfile
export def "id-save-performance-profile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --concurrent-request: int # number of concurrent requests (format: int64)
  --duration: string # duration of tests e.g. 30s
  --endpoints: list<string> # array of urls of performance results
  --load-generators: list<string> # array of load generators
  --name: string # name of performance profile
  --qps: int # qps in integer (format: int64)
  --service-mesh: string # service mesh for performance tests
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/user/performance/profiles"
    body: {content_type: "application/json", kind: json, fields: [{name: concurrent_request, var: concurrent_request}, {name: duration, var: duration}, {name: endpoints, var: endpoints}, {name: load_generators, var: load_generators}, {name: name, var: name}, {name: qps, var: qps}, {name: service_mesh, var: service_mesh}]}
    accept: ["application/json"]
    ok: [200]
    auth: cookie-token
  } {
    concurrent_request: $concurrent_request, duration: $duration, endpoints: $endpoints, load_generators: $load_generators, name: $name, qps: $qps, service_mesh: $service_mesh
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handles GET requests for performance results
#
# GET /api/user/performance/profiles/results
# Returns: record<page: int, page_size: int, results: table<mesh: string, meshery_id: list, name: string, performance_profile: list, runner_results: record, server_board_config: record, server_metrics: record, test_start_time: string, user_id: list>, total_count: int>
# operationId: idGetAllPerformanceResults
export def "id-get-all-performance-results" [
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
    path: "/api/user/performance/profiles/results"
    accept: ["application/json"]
    ok: [200]
    auth: cookie-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handle Delete requests for performance profiles
#
# DELETE /api/user/performance/profiles/{id}
# operationId: idDeletePerformanceProfile
export def "id-delete-performance-profile" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/user/performance/profiles/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: cookie-token
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handle GET requests for performance results of a profile
#
# GET /api/user/performance/profiles/{id}
# Returns: record<concurrent_request: int, content_type: string, created_at: record, duration: string, endpoints: list<string>, id: list<int>, last_run: record, load_generators: list<string>, name: string, qps: int, request_body: string, request_cookies: string, request_headers: string, schedule: list<int>, service_mesh: string, total_results: int, updated_at: record>
# operationId: idGetSinglePerformanceProfile
export def "id-get-single-performance-profile" [
  id: string
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
    path: "/api/user/performance/profiles/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: cookie-token
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handle GET request for results of a profile
#
# GET /api/user/performance/profiles/{id}/results
# Returns: record<page: int, page_size: int, results: table<mesh: string, meshery_id: list, name: string, performance_profile: list, runner_results: record, server_board_config: record, server_metrics: record, test_start_time: string, user_id: list>, total_count: int>
# operationId: idGETProfileResults
export def "id-get-profile-results" [
  id: string
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
    path: "/api/user/performance/profiles/{id}/results"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: cookie-token
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handle GET request to run a performance test
#
# GET /api/user/performance/profiles/{id}/run
# operationId: idRunPerformanceTest
export def "id-run-performance-test" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/api/user/performance/profiles/{id}/run"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: cookie-token
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handle GET for User Load Test Preferences
#
# GET /api/user/prefs
# Returns: record<anonymousPerfResults: bool, anonymousUsageStats: bool, grafana: record<grafanaAPIKey: string, grafanaURL: string, selectedBoardsConfigs: list<record>>, k8sConfig: record<clusterConfigured: bool, config: list<int>, configuredServer: string, contextName: string, inClusterConfig: bool, k8sfile: string, nodes: list<record>, server_version: string>, loadTestPrefs: record<c: int, gen: string, qps: int, t: string>, meshAdapters: table<adapter_location: string, git_commit_sha: string, name: string, ops: list, version: string>, prometheus: record<prometheusURL: string, selectedPrometheusBoardsConfigs: list<record>>, updated_at: string>
# operationId: idGetUserTestPrefs
export def "id-get-user-test-prefs" [
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
    path: "/api/user/prefs"
    accept: ["application/json"]
    ok: [200]
    auth: cookie-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handle GET for User Load Test Preferences
#
# POST /api/user/prefs
# Returns: record<anonymousPerfResults: bool, anonymousUsageStats: bool, grafana: record<grafanaAPIKey: string, grafanaURL: string, selectedBoardsConfigs: list<record>>, k8sConfig: record<clusterConfigured: bool, config: list<int>, configuredServer: string, contextName: string, inClusterConfig: bool, k8sfile: string, nodes: list<record>, server_version: string>, loadTestPrefs: record<c: int, gen: string, qps: int, t: string>, meshAdapters: table<adapter_location: string, git_commit_sha: string, name: string, ops: list, version: string>, prometheus: record<prometheusURL: string, selectedPrometheusBoardsConfigs: list<record>>, updated_at: string>
# operationId: idPostUserTestPrefs
export def "id-post-user-test-prefs" [
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
    method: post
    path: "/api/user/prefs"
    accept: ["application/json"]
    ok: [200]
    auth: cookie-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handle DELETE request for load test preferences
#
# DELETE /api/user/prefs/perf
# operationId: idDeleteLoadPreferences
export def "id-delete-load-preferences" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --uuid: string # format: uuid
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/user/prefs/perf"
    query: [{name: uuid, var: uuid}]
    accept: ["application/json"]
    ok: [200]
    auth: cookie-token
  } {
    uuid: $uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handle GET request for load test preferences
#
# GET /api/user/prefs/perf
# Returns: record<clients: table<body: string, connections: int, content_type: string, cookies: record, endpoint_urls: list, headers: record, internal: bool, load_generator: string, protocol: int, rps: int>, duration: string, id: string, labels: record, name: string, smp_version: string>
# operationId: idGetLoadPreferences
export def "id-get-load-preferences" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --uuid: string # format: uuid
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/user/prefs/perf"
    query: [{name: uuid, var: uuid}]
    accept: ["application/json"]
    ok: [200]
    auth: cookie-token
  } {
    uuid: $uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handle POST request for load test preferences
#
# POST /api/user/prefs/perf
# operationId: idPostLoadPreferences
export def "id-post-load-preferences" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clients: list # Single or distributed load generators — item shape: {body?: string, connections?: int, content_type?: string, cookies?: record, endpoint_urls?: list<string>, headers?: record, internal?: bool, load_generator?: string, protocol?: int, rps?: int}
  --duration: string # Length of time the endpoint will be under load
  --id: string
  --labels: record
  --name: string
  --smp-version: string # Spec version
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/user/prefs/perf"
    body: {content_type: "application/json", kind: json, fields: [{name: clients, var: clients}, {name: duration, var: duration}, {name: id, var: id}, {name: labels, var: labels}, {name: name, var: name}, {name: smp_version, var: smp_version}]}
    accept: ["application/json"]
    ok: [200]
    auth: cookie-token
  } {
    clients: $clients, duration: $duration, id: $id, labels: $labels, name: $name, smp_version: $smp_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handle GET reqeuest for Schedules
#
# GET /api/user/schedules
# Returns: record<page: int, page_size: int, schedules: table<cron_expression: string, id: list>, total_count: int>
# operationId: idGetSchedules
export def "id-get-schedules" [
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
    path: "/api/user/schedules"
    accept: ["application/json"]
    ok: [200]
    auth: cookie-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handle POST reqeuest for Schedules
#
# POST /api/user/schedules
# Returns: record<cron_expression: string, id: list<int>>
# operationId: idPostSchedules
export def "id-post-schedules" [
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
    method: post
    path: "/api/user/schedules"
    accept: ["application/json"]
    ok: [200]
    auth: cookie-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handle DELETE reqeuest for Schedules
#
# DELETE /api/user/schedules/{id}
# Returns: record<page: int, page_size: int, schedules: table<cron_expression: string, id: list>, total_count: int>
# operationId: idDeleteSchedules
export def "id-delete-schedules" [
  id: string
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
    method: delete
    path: "/api/user/schedules/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: cookie-token
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handle GET reqeuest for Schedules
#
# GET /api/user/schedules/{id}
# Returns: record<cron_expression: string, id: list<int>>
# operationId: idGetSingleSchedule
export def "id-get-single-schedule" [
  id: string
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
    path: "/api/user/schedules/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: cookie-token
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handle GET request for tokens
#
# GET /api/user/token
# operationId: idGetTokenProvider
export def "id-get-token-provider" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/api/user/token"
    accept: ["application/json"]
    ok: []
    auth: cookie-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handle POST request for tokens
#
# POST /api/user/token
# operationId: idPostTokenProvider
export def "id-post-token-provider" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: post
    path: "/api/user/token"
    accept: ["application/json"]
    ok: []
    auth: cookie-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handle GET request to provider UI
#
# GET /provider
# operationId: idProvider
export def "id-provider" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/provider"
    accept: ["application/json"]
    ok: [200]
    auth: cookie-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
