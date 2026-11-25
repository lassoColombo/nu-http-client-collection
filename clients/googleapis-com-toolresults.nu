# Auto-generated client for Cloud Tool Results API v1beta3
# Source: https://api.apis.guru/v2/specs/googleapis.com/toolresults/v1beta3/openapi.json
# Auth: --token flag or $env.CLOUD_TOOL_RESULTS_API_TOKEN

const CLIENT = {
  base_url: "https://toolresults.googleapis.com"
  token_env_var: "CLOUD_TOOL_RESULTS_API_TOKEN"
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

def base-url-completer [] { ["https://toolresults.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def test-platform-completer [] { ["android" "ios" "unknownPlatform"] }
def state-completer [] { ["complete" "inProgress" "pending" "unknownState"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    toolresults-projects-histories-list: "record<histories: table<displayName: string, historyId: string, name: string, testPlatform: string>, nextPageToken: string>"
    toolresults-projects-histories-create: "record<displayName: string, historyId: string, name: string, testPlatform: string>"
    toolresults-projects-histories-get: "record<displayName: string, historyId: string, name: string, testPlatform: string>"
    toolresults-projects-histories-executions-list: "record<executions: table<completionTime: record, creationTime: record, dimensionDefinitions: list, executionId: string, outcome: record, specification: record, state: string, testExecutionMatrixId: string>, nextPageToken: string>"
    toolresults-projects-histories-executions-create: "record<completionTime: record<nanos: int, seconds: string>, creationTime: record<nanos: int, seconds: string>, dimensionDefinitions: list<record>, executionId: string, outcome: record<failureDetail: record<crashed: bool, deviceOutOfMemory: bool, failedRoboscript: bool, notInstalled: bool, otherNativeCrash: bool, timedOut: bool, unableToCrawl: bool>, inconclusiveDetail: record<abortedByUser: bool, hasErrorLogs: bool, infrastructureFailure: bool>, skippedDetail: record<incompatibleAppVersion: bool, incompatibleArchitecture: bool, incompatibleDevice: bool>, successDetail: record<otherNativeCrash: bool>, summary: string>, specification: record<androidTest: record<androidAppInfo: record, androidInstrumentationTest: record, androidRoboTest: record, androidTestLoop: record, testTimeout: record>, iosTest: record<iosAppInfo: record, iosRoboTest: record, iosTestLoop: record, iosXcTest: record, testTimeout: record>>, state: string, testExecutionMatrixId: string>"
    toolresults-projects-histories-executions-get: "record<completionTime: record<nanos: int, seconds: string>, creationTime: record<nanos: int, seconds: string>, dimensionDefinitions: list<record>, executionId: string, outcome: record<failureDetail: record<crashed: bool, deviceOutOfMemory: bool, failedRoboscript: bool, notInstalled: bool, otherNativeCrash: bool, timedOut: bool, unableToCrawl: bool>, inconclusiveDetail: record<abortedByUser: bool, hasErrorLogs: bool, infrastructureFailure: bool>, skippedDetail: record<incompatibleAppVersion: bool, incompatibleArchitecture: bool, incompatibleDevice: bool>, successDetail: record<otherNativeCrash: bool>, summary: string>, specification: record<androidTest: record<androidAppInfo: record, androidInstrumentationTest: record, androidRoboTest: record, androidTestLoop: record, testTimeout: record>, iosTest: record<iosAppInfo: record, iosRoboTest: record, iosTestLoop: record, iosXcTest: record, testTimeout: record>>, state: string, testExecutionMatrixId: string>"
    toolresults-projects-histories-executions-patch: "record<completionTime: record<nanos: int, seconds: string>, creationTime: record<nanos: int, seconds: string>, dimensionDefinitions: list<record>, executionId: string, outcome: record<failureDetail: record<crashed: bool, deviceOutOfMemory: bool, failedRoboscript: bool, notInstalled: bool, otherNativeCrash: bool, timedOut: bool, unableToCrawl: bool>, inconclusiveDetail: record<abortedByUser: bool, hasErrorLogs: bool, infrastructureFailure: bool>, skippedDetail: record<incompatibleAppVersion: bool, incompatibleArchitecture: bool, incompatibleDevice: bool>, successDetail: record<otherNativeCrash: bool>, summary: string>, specification: record<androidTest: record<androidAppInfo: record, androidInstrumentationTest: record, androidRoboTest: record, androidTestLoop: record, testTimeout: record>, iosTest: record<iosAppInfo: record, iosRoboTest: record, iosTestLoop: record, iosXcTest: record, testTimeout: record>>, state: string, testExecutionMatrixId: string>"
    toolresults-projects-histories-executions-clusters-list: "record<clusters: table<activity: string, clusterId: string, keyScreen: record, screens: list>>"
    toolresults-projects-histories-executions-clusters-get: "record<activity: string, clusterId: string, keyScreen: record<fileReference: string, locale: string, model: string, version: string>, screens: table<fileReference: string, locale: string, model: string, version: string>>"
    toolresults-projects-histories-executions-environments-list: "record<environments: table<completionTime: record, creationTime: record, dimensionValue: list, displayName: string, environmentId: string, environmentResult: record, executionId: string, historyId: string, projectId: string, resultsStorage: record, shardSummaries: list>, executionId: string, historyId: string, nextPageToken: string, projectId: string>"
    toolresults-projects-histories-executions-environments-get: "record<completionTime: record<nanos: int, seconds: string>, creationTime: record<nanos: int, seconds: string>, dimensionValue: table<key: string, value: string>, displayName: string, environmentId: string, environmentResult: record<outcome: record<failureDetail: record, inconclusiveDetail: record, skippedDetail: record, successDetail: record, summary: string>, state: string, testSuiteOverviews: list<record>>, executionId: string, historyId: string, projectId: string, resultsStorage: record<resultsStoragePath: record<fileUri: string>, xunitXmlFile: record<fileUri: string>>, shardSummaries: table<runs: list, shardResult: record>>"
    toolresults-projects-histories-executions-steps-list: "record<nextPageToken: string, steps: table<completionTime: record, creationTime: record, description: string, deviceUsageDuration: record, dimensionValue: list, hasImages: bool, labels: list, multiStep: record, name: string, outcome: record, runDuration: record, state: string, stepId: string, testExecutionStep: record, toolExecutionStep: record>>"
    toolresults-projects-histories-executions-steps-create: "record<completionTime: record<nanos: int, seconds: string>, creationTime: record<nanos: int, seconds: string>, description: string, deviceUsageDuration: record<nanos: int, seconds: string>, dimensionValue: table<key: string, value: string>, hasImages: bool, labels: table<key: string, value: string>, multiStep: record<multistepNumber: int, primaryStep: record<individualOutcome: list, rollUp: string>, primaryStepId: string>, name: string, outcome: record<failureDetail: record<crashed: bool, deviceOutOfMemory: bool, failedRoboscript: bool, notInstalled: bool, otherNativeCrash: bool, timedOut: bool, unableToCrawl: bool>, inconclusiveDetail: record<abortedByUser: bool, hasErrorLogs: bool, infrastructureFailure: bool>, skippedDetail: record<incompatibleAppVersion: bool, incompatibleArchitecture: bool, incompatibleDevice: bool>, successDetail: record<otherNativeCrash: bool>, summary: string>, runDuration: record<nanos: int, seconds: string>, state: string, stepId: string, testExecutionStep: record<testIssues: list<record>, testSuiteOverviews: list<record>, testTiming: record<testProcessDuration: record>, toolExecution: record<commandLineArguments: list, exitCode: record, toolLogs: list, toolOutputs: list>>, toolExecutionStep: record<toolExecution: record<commandLineArguments: list, exitCode: record, toolLogs: list, toolOutputs: list>>>"
    toolresults-projects-histories-executions-steps-get: "record<completionTime: record<nanos: int, seconds: string>, creationTime: record<nanos: int, seconds: string>, description: string, deviceUsageDuration: record<nanos: int, seconds: string>, dimensionValue: table<key: string, value: string>, hasImages: bool, labels: table<key: string, value: string>, multiStep: record<multistepNumber: int, primaryStep: record<individualOutcome: list, rollUp: string>, primaryStepId: string>, name: string, outcome: record<failureDetail: record<crashed: bool, deviceOutOfMemory: bool, failedRoboscript: bool, notInstalled: bool, otherNativeCrash: bool, timedOut: bool, unableToCrawl: bool>, inconclusiveDetail: record<abortedByUser: bool, hasErrorLogs: bool, infrastructureFailure: bool>, skippedDetail: record<incompatibleAppVersion: bool, incompatibleArchitecture: bool, incompatibleDevice: bool>, successDetail: record<otherNativeCrash: bool>, summary: string>, runDuration: record<nanos: int, seconds: string>, state: string, stepId: string, testExecutionStep: record<testIssues: list<record>, testSuiteOverviews: list<record>, testTiming: record<testProcessDuration: record>, toolExecution: record<commandLineArguments: list, exitCode: record, toolLogs: list, toolOutputs: list>>, toolExecutionStep: record<toolExecution: record<commandLineArguments: list, exitCode: record, toolLogs: list, toolOutputs: list>>>"
    toolresults-projects-histories-executions-steps-patch: "record<completionTime: record<nanos: int, seconds: string>, creationTime: record<nanos: int, seconds: string>, description: string, deviceUsageDuration: record<nanos: int, seconds: string>, dimensionValue: table<key: string, value: string>, hasImages: bool, labels: table<key: string, value: string>, multiStep: record<multistepNumber: int, primaryStep: record<individualOutcome: list, rollUp: string>, primaryStepId: string>, name: string, outcome: record<failureDetail: record<crashed: bool, deviceOutOfMemory: bool, failedRoboscript: bool, notInstalled: bool, otherNativeCrash: bool, timedOut: bool, unableToCrawl: bool>, inconclusiveDetail: record<abortedByUser: bool, hasErrorLogs: bool, infrastructureFailure: bool>, skippedDetail: record<incompatibleAppVersion: bool, incompatibleArchitecture: bool, incompatibleDevice: bool>, successDetail: record<otherNativeCrash: bool>, summary: string>, runDuration: record<nanos: int, seconds: string>, state: string, stepId: string, testExecutionStep: record<testIssues: list<record>, testSuiteOverviews: list<record>, testTiming: record<testProcessDuration: record>, toolExecution: record<commandLineArguments: list, exitCode: record, toolLogs: list, toolOutputs: list>>, toolExecutionStep: record<toolExecution: record<commandLineArguments: list, exitCode: record, toolLogs: list, toolOutputs: list>>>"
    toolresults-projects-histories-executions-steps-get-perf-metrics-summary: "record<appStartTime: record<fullyDrawnTime: record<nanos: int, seconds: string>, initialDisplayTime: record<nanos: int, seconds: string>>, executionId: string, graphicsStats: record<buckets: list<record>, highInputLatencyCount: string, jankyFrames: string, missedVsyncCount: string, p50Millis: string, p90Millis: string, p95Millis: string, p99Millis: string, slowBitmapUploadCount: string, slowDrawCount: string, slowUiThreadCount: string, totalFrames: string>, historyId: string, perfEnvironment: record<cpuInfo: record<cpuProcessor: string, cpuSpeedInGhz: float, numberOfCores: int>, memoryInfo: record<memoryCapInKibibyte: string, memoryTotalInKibibyte: string>>, perfMetrics: list<string>, projectId: string, stepId: string>"
    toolresults-projects-histories-executions-steps-perf-metrics-summary-create: "record<appStartTime: record<fullyDrawnTime: record<nanos: int, seconds: string>, initialDisplayTime: record<nanos: int, seconds: string>>, executionId: string, graphicsStats: record<buckets: list<record>, highInputLatencyCount: string, jankyFrames: string, missedVsyncCount: string, p50Millis: string, p90Millis: string, p95Millis: string, p99Millis: string, slowBitmapUploadCount: string, slowDrawCount: string, slowUiThreadCount: string, totalFrames: string>, historyId: string, perfEnvironment: record<cpuInfo: record<cpuProcessor: string, cpuSpeedInGhz: float, numberOfCores: int>, memoryInfo: record<memoryCapInKibibyte: string, memoryTotalInKibibyte: string>>, perfMetrics: list<string>, projectId: string, stepId: string>"
    toolresults-projects-histories-executions-steps-perf-sample-series-list: "record<perfSampleSeries: table<basicPerfSampleSeries: record, executionId: string, historyId: string, projectId: string, sampleSeriesId: string, stepId: string>>"
    toolresults-projects-histories-executions-steps-perf-sample-series-create: "record<basicPerfSampleSeries: record<perfMetricType: string, perfUnit: string, sampleSeriesLabel: string>, executionId: string, historyId: string, projectId: string, sampleSeriesId: string, stepId: string>"
    toolresults-projects-histories-executions-steps-perf-sample-series-get: "record<basicPerfSampleSeries: record<perfMetricType: string, perfUnit: string, sampleSeriesLabel: string>, executionId: string, historyId: string, projectId: string, sampleSeriesId: string, stepId: string>"
    toolresults-projects-histories-executions-steps-perf-sample-series-samples-list: "record<nextPageToken: string, perfSamples: table<sampleTime: record, value: float>>"
    toolresults-projects-histories-executions-steps-perf-sample-series-samples-batch-create: "record<perfSamples: table<sampleTime: record, value: float>>"
    toolresults-projects-histories-executions-steps-test-cases-list: "record<nextPageToken: string, testCases: table<elapsedTime: record, endTime: record, skippedMessage: string, stackTraces: list, startTime: record, status: string, testCaseId: string, testCaseReference: record, toolOutputs: list>>"
    toolresults-projects-histories-executions-steps-test-cases-get: "record<elapsedTime: record<nanos: int, seconds: string>, endTime: record<nanos: int, seconds: string>, skippedMessage: string, stackTraces: table<exception: string>, startTime: record<nanos: int, seconds: string>, status: string, testCaseId: string, testCaseReference: record<className: string, name: string, testSuiteName: string>, toolOutputs: table<creationTime: record, output: record, testCase: record>>"
    toolresults-projects-histories-executions-steps-thumbnails-list: "record<nextPageToken: string, thumbnails: table<error: record, sourceImage: record, stepId: string, thumbnail: record>>"
    toolresults-projects-histories-executions-steps-publish-xunit-xml-files: "record<completionTime: record<nanos: int, seconds: string>, creationTime: record<nanos: int, seconds: string>, description: string, deviceUsageDuration: record<nanos: int, seconds: string>, dimensionValue: table<key: string, value: string>, hasImages: bool, labels: table<key: string, value: string>, multiStep: record<multistepNumber: int, primaryStep: record<individualOutcome: list, rollUp: string>, primaryStepId: string>, name: string, outcome: record<failureDetail: record<crashed: bool, deviceOutOfMemory: bool, failedRoboscript: bool, notInstalled: bool, otherNativeCrash: bool, timedOut: bool, unableToCrawl: bool>, inconclusiveDetail: record<abortedByUser: bool, hasErrorLogs: bool, infrastructureFailure: bool>, skippedDetail: record<incompatibleAppVersion: bool, incompatibleArchitecture: bool, incompatibleDevice: bool>, successDetail: record<otherNativeCrash: bool>, summary: string>, runDuration: record<nanos: int, seconds: string>, state: string, stepId: string, testExecutionStep: record<testIssues: list<record>, testSuiteOverviews: list<record>, testTiming: record<testProcessDuration: record>, toolExecution: record<commandLineArguments: list, exitCode: record, toolLogs: list, toolOutputs: list>>, toolExecutionStep: record<toolExecution: record<commandLineArguments: list, exitCode: record, toolLogs: list, toolOutputs: list>>>"
    toolresults-projects-get-settings: "record<defaultBucket: string, name: string>"
    toolresults-projects-initialize-settings: "record<defaultBucket: string, name: string>"
    toolresults-projects-histories-executions-steps-accessibility-clusters: "record<clusters: table<category: string, suggestions: list>, name: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["toolresults-projects-histories-list" "toolresults-projects-histories-create" "toolresults-projects-histories-get" "toolresults-projects-histories-executions-list" "toolresults-projects-histories-executions-create" "toolresults-projects-histories-executions-get" "toolresults-projects-histories-executions-patch" "toolresults-projects-histories-executions-clusters-list" "toolresults-projects-histories-executions-clusters-get" "toolresults-projects-histories-executions-environments-list" "toolresults-projects-histories-executions-environments-get" "toolresults-projects-histories-executions-steps-list" "toolresults-projects-histories-executions-steps-create" "toolresults-projects-histories-executions-steps-get" "toolresults-projects-histories-executions-steps-patch" "toolresults-projects-histories-executions-steps-get-perf-metrics-summary" "toolresults-projects-histories-executions-steps-perf-metrics-summary-create" "toolresults-projects-histories-executions-steps-perf-sample-series-list" "toolresults-projects-histories-executions-steps-perf-sample-series-create" "toolresults-projects-histories-executions-steps-perf-sample-series-get" "toolresults-projects-histories-executions-steps-perf-sample-series-samples-list" "toolresults-projects-histories-executions-steps-perf-sample-series-samples-batch-create" "toolresults-projects-histories-executions-steps-test-cases-list" "toolresults-projects-histories-executions-steps-test-cases-get" "toolresults-projects-histories-executions-steps-thumbnails-list" "toolresults-projects-histories-executions-steps-publish-xunit-xml-files" "toolresults-projects-get-settings" "toolresults-projects-initialize-settings" "toolresults-projects-histories-executions-steps-accessibility-clusters" "commands"] | sort) } | get name | first)
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

# Lists Histories for a given Project. The histories are sorted by modification time in descending order. The history_id key will be used to order the history with the same modification time. May return any of the following canonical error codes: - PERMISSION_DENIED - if the user is not authorized to read project - INVALID_ARGUMENT - if the request is malformed - NOT_FOUND - if the History does not exist
#
# GET /toolresults/v1beta3/projects/{projectId}/histories
# Returns: record<histories: table<displayName: string, historyId: string, name: string, testPlatform: string>, nextPageToken: string>
# operationId: toolresults.projects.histories.list
export def "toolresults-projects-histories-list" [
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
  --filter-by-name: string # If set, only return histories with the given name. Optional.
  --page-size: int # The maximum number of Histories to fetch. Default value: 20. The server will use this default if the field is not set or has a value of 0. Any value greater than 100 will be treated as 100. Optional.
  --page-token: string # A continuation token to resume the query at the next item. Optional.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/toolresults/v1beta3/projects/{projectId}/histories"
    path_params: [{name: projectId, var: project_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: filterByName, var: filter_by_name}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, filter_by_name: $filter_by_name, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a History. The returned History will have the id set. May return any of the following canonical error codes: - PERMISSION_DENIED - if the user is not authorized to write to project - INVALID_ARGUMENT - if the request is malformed - NOT_FOUND - if the containing project does not exist
#
# POST /toolresults/v1beta3/projects/{projectId}/histories
# Returns: record<displayName: string, historyId: string, name: string, testPlatform: string>
# operationId: toolresults.projects.histories.create
export def "toolresults-projects-histories-create" [
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
  --request-id: string # A unique request ID for server to detect duplicated requests. For example, a UUID. Optional, but strongly recommended.
  --display-name: string # A short human-readable (plain text) name to display in the UI. Maximum of 100 characters. - In response: present if set during create. - In create request: optional
  --history-id: string # A unique identifier within a project for this History. Returns INVALID_ARGUMENT if this field is set or overwritten by the caller. - In response always set - In create request: never set
  --name: string # A name to uniquely identify a history within a project. Maximum of 200 characters. - In response always set - In create request: always set
  --test-platform: string@test-platform-completer # The platform of the test history. - In response: always set. Returns the platform of the last execution if unknown.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/toolresults/v1beta3/projects/{projectId}/histories"
    path_params: [{name: projectId, var: project_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: requestId, var: request_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: displayName, var: display_name}, {name: historyId, var: history_id}, {name: name, var: name}, {name: testPlatform, var: test_platform}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, request_id: $request_id, display_name: $display_name, history_id: $history_id, name: $name, test_platform: $test_platform
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a History. May return any of the following canonical error codes: - PERMISSION_DENIED - if the user is not authorized to read project - INVALID_ARGUMENT - if the request is malformed - NOT_FOUND - if the History does not exist
#
# GET /toolresults/v1beta3/projects/{projectId}/histories/{historyId}
# Returns: record<displayName: string, historyId: string, name: string, testPlatform: string>
# operationId: toolresults.projects.histories.get
export def "toolresults-projects-histories-get" [
  project_id: string
  history_id: string
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
    path: "/toolresults/v1beta3/projects/{projectId}/histories/{historyId}"
    path_params: [{name: projectId, var: project_id}, {name: historyId, var: history_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, history_id: $history_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists Executions for a given History. The executions are sorted by creation_time in descending order. The execution_id key will be used to order the executions with the same creation_time. May return any of the following canonical error codes: - PERMISSION_DENIED - if the user is not authorized to read project - INVALID_ARGUMENT - if the request is malformed - NOT_FOUND - if the containing History does not exist
#
# GET /toolresults/v1beta3/projects/{projectId}/histories/{historyId}/executions
# Returns: record<executions: table<completionTime: record, creationTime: record, dimensionDefinitions: list, executionId: string, outcome: record, specification: record, state: string, testExecutionMatrixId: string>, nextPageToken: string>
# operationId: toolresults.projects.histories.executions.list
export def "toolresults-projects-histories-executions-list" [
  project_id: string
  history_id: string
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
  --page-size: int # The maximum number of Executions to fetch. Default value: 25. The server will use this default if the field is not set or has a value of 0. Optional.
  --page-token: string # A continuation token to resume the query at the next item. Optional.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/toolresults/v1beta3/projects/{projectId}/histories/{historyId}/executions"
    path_params: [{name: projectId, var: project_id}, {name: historyId, var: history_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, history_id: $history_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an Execution. The returned Execution will have the id set. May return any of the following canonical error codes: - PERMISSION_DENIED - if the user is not authorized to write to project - INVALID_ARGUMENT - if the request is malformed - NOT_FOUND - if the containing History does not exist
#
# POST /toolresults/v1beta3/projects/{projectId}/histories/{historyId}/executions
# Returns: record<completionTime: record<nanos: int, seconds: string>, creationTime: record<nanos: int, seconds: string>, dimensionDefinitions: list<record>, executionId: string, outcome: record<failureDetail: record<crashed: bool, deviceOutOfMemory: bool, failedRoboscript: bool, notInstalled: bool, otherNativeCrash: bool, timedOut: bool, unableToCrawl: bool>, inconclusiveDetail: record<abortedByUser: bool, hasErrorLogs: bool, infrastructureFailure: bool>, skippedDetail: record<incompatibleAppVersion: bool, incompatibleArchitecture: bool, incompatibleDevice: bool>, successDetail: record<otherNativeCrash: bool>, summary: string>, specification: record<androidTest: record<androidAppInfo: record, androidInstrumentationTest: record, androidRoboTest: record, androidTestLoop: record, testTimeout: record>, iosTest: record<iosAppInfo: record, iosRoboTest: record, iosTestLoop: record, iosXcTest: record, testTimeout: record>>, state: string, testExecutionMatrixId: string>
# operationId: toolresults.projects.histories.executions.create
export def "toolresults-projects-histories-executions-create" [
  project_id: string
  history_id: string
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
  --request-id: string # A unique request ID for server to detect duplicated requests. For example, a UUID. Optional, but strongly recommended.
  --completion-time: record # A Timestamp represents a point in time independent of any time zone or local calendar, encoded as a count of seconds and fractions of seconds at nanosecond resolution. The count is relative to an epoch at UTC midnight on January 1, 1970, in the proleptic Gregorian calendar which extends the Gregorian calendar backwards to year one. All minutes are 60 seconds long. Leap seconds are "smeared" so that no leap second table is needed for interpretation, using a [24-hour linear smear](https://developers.google.com/time/smear). The range is from 0001-01-01T00:00:00Z to 9999-12-31T23:59:59.999999999Z. By restricting to that range, we ensure that we can convert to and from [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) date strings. — shape: {nanos?: int, seconds?: string}
  --creation-time: record # A Timestamp represents a point in time independent of any time zone or local calendar, encoded as a count of seconds and fractions of seconds at nanosecond resolution. The count is relative to an epoch at UTC midnight on January 1, 1970, in the proleptic Gregorian calendar which extends the Gregorian calendar backwards to year one. All minutes are 60 seconds long. Leap seconds are "smeared" so that no leap second table is needed for interpretation, using a [24-hour linear smear](https://developers.google.com/time/smear). The range is from 0001-01-01T00:00:00Z to 9999-12-31T23:59:59.999999999Z. By restricting to that range, we ensure that we can convert to and from [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) date strings. — shape: {nanos?: int, seconds?: string}
  --dimension-definitions: list # The dimensions along which different steps in this execution may vary. This must remain fixed over the life of the execution. Returns INVALID_ARGUMENT if this field is set in an update request. Returns INVALID_ARGUMENT if the same name occurs in more than one dimension_definition. Returns INVALID_ARGUMENT if the size of the list is over 100. - In response: present if set by create - In create request: optional - In update request: never set
  --execution-id: string # A unique identifier within a History for this Execution. Returns INVALID_ARGUMENT if this field is set or overwritten by the caller. - In response always set - In create/update request: never set
  --outcome: record # Interprets a result so that humans and machines can act on it. — shape: {failureDetail?: record, inconclusiveDetail?: record, skippedDetail?: record, successDetail?: record, summary?: "unset"|"success"|"failure"|"inconclusive"|"skipped"|"flaky"}
  --specification: record # The details about how to run the execution. — shape: {androidTest?: record, iosTest?: record}
  --state: string@state-completer # The initial state is IN_PROGRESS. The only legal state transitions is from IN_PROGRESS to COMPLETE. A PRECONDITION_FAILED will be returned if an invalid transition is requested. The state can only be set to COMPLETE once. A FAILED_PRECONDITION will be returned if the state is set to COMPLETE multiple times. If the state is set to COMPLETE, all the in-progress steps within the execution will be set as COMPLETE. If the outcome of the step is not set, the outcome will be set to INCONCLUSIVE. - In response always set - In create/update request: optional
  --test-execution-matrix-id: string # TestExecution Matrix ID that the TestExecutionService uses. - In response: present if set by create - In create: optional - In update: never set
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/toolresults/v1beta3/projects/{projectId}/histories/{historyId}/executions"
    path_params: [{name: projectId, var: project_id}, {name: historyId, var: history_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: requestId, var: request_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: completionTime, var: completion_time}, {name: creationTime, var: creation_time}, {name: dimensionDefinitions, var: dimension_definitions}, {name: executionId, var: execution_id}, {name: outcome, var: outcome}, {name: specification, var: specification}, {name: state, var: state}, {name: testExecutionMatrixId, var: test_execution_matrix_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, history_id: $history_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, request_id: $request_id, completion_time: $completion_time, creation_time: $creation_time, dimension_definitions: $dimension_definitions, execution_id: $execution_id, outcome: $outcome, specification: $specification, state: $state, test_execution_matrix_id: $test_execution_matrix_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets an Execution. May return any of the following canonical error codes: - PERMISSION_DENIED - if the user is not authorized to write to project - INVALID_ARGUMENT - if the request is malformed - NOT_FOUND - if the Execution does not exist
#
# GET /toolresults/v1beta3/projects/{projectId}/histories/{historyId}/executions/{executionId}
# Returns: record<completionTime: record<nanos: int, seconds: string>, creationTime: record<nanos: int, seconds: string>, dimensionDefinitions: list<record>, executionId: string, outcome: record<failureDetail: record<crashed: bool, deviceOutOfMemory: bool, failedRoboscript: bool, notInstalled: bool, otherNativeCrash: bool, timedOut: bool, unableToCrawl: bool>, inconclusiveDetail: record<abortedByUser: bool, hasErrorLogs: bool, infrastructureFailure: bool>, skippedDetail: record<incompatibleAppVersion: bool, incompatibleArchitecture: bool, incompatibleDevice: bool>, successDetail: record<otherNativeCrash: bool>, summary: string>, specification: record<androidTest: record<androidAppInfo: record, androidInstrumentationTest: record, androidRoboTest: record, androidTestLoop: record, testTimeout: record>, iosTest: record<iosAppInfo: record, iosRoboTest: record, iosTestLoop: record, iosXcTest: record, testTimeout: record>>, state: string, testExecutionMatrixId: string>
# operationId: toolresults.projects.histories.executions.get
export def "toolresults-projects-histories-executions-get" [
  project_id: string
  history_id: string
  execution_id: string
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
    path: "/toolresults/v1beta3/projects/{projectId}/histories/{historyId}/executions/{executionId}"
    path_params: [{name: projectId, var: project_id}, {name: historyId, var: history_id}, {name: executionId, var: execution_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, history_id: $history_id, execution_id: $execution_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing Execution with the supplied partial entity. May return any of the following canonical error codes: - PERMISSION_DENIED - if the user is not authorized to write to project - INVALID_ARGUMENT - if the request is malformed - FAILED_PRECONDITION - if the requested state transition is illegal - NOT_FOUND - if the containing History does not exist
#
# PATCH /toolresults/v1beta3/projects/{projectId}/histories/{historyId}/executions/{executionId}
# Returns: record<completionTime: record<nanos: int, seconds: string>, creationTime: record<nanos: int, seconds: string>, dimensionDefinitions: list<record>, executionId: string, outcome: record<failureDetail: record<crashed: bool, deviceOutOfMemory: bool, failedRoboscript: bool, notInstalled: bool, otherNativeCrash: bool, timedOut: bool, unableToCrawl: bool>, inconclusiveDetail: record<abortedByUser: bool, hasErrorLogs: bool, infrastructureFailure: bool>, skippedDetail: record<incompatibleAppVersion: bool, incompatibleArchitecture: bool, incompatibleDevice: bool>, successDetail: record<otherNativeCrash: bool>, summary: string>, specification: record<androidTest: record<androidAppInfo: record, androidInstrumentationTest: record, androidRoboTest: record, androidTestLoop: record, testTimeout: record>, iosTest: record<iosAppInfo: record, iosRoboTest: record, iosTestLoop: record, iosXcTest: record, testTimeout: record>>, state: string, testExecutionMatrixId: string>
# operationId: toolresults.projects.histories.executions.patch
export def "toolresults-projects-histories-executions-patch" [
  project_id: string
  history_id: string
  execution_id: string
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
  --request-id: string # A unique request ID for server to detect duplicated requests. For example, a UUID. Optional, but strongly recommended.
  --completion-time: record # A Timestamp represents a point in time independent of any time zone or local calendar, encoded as a count of seconds and fractions of seconds at nanosecond resolution. The count is relative to an epoch at UTC midnight on January 1, 1970, in the proleptic Gregorian calendar which extends the Gregorian calendar backwards to year one. All minutes are 60 seconds long. Leap seconds are "smeared" so that no leap second table is needed for interpretation, using a [24-hour linear smear](https://developers.google.com/time/smear). The range is from 0001-01-01T00:00:00Z to 9999-12-31T23:59:59.999999999Z. By restricting to that range, we ensure that we can convert to and from [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) date strings. — shape: {nanos?: int, seconds?: string}
  --creation-time: record # A Timestamp represents a point in time independent of any time zone or local calendar, encoded as a count of seconds and fractions of seconds at nanosecond resolution. The count is relative to an epoch at UTC midnight on January 1, 1970, in the proleptic Gregorian calendar which extends the Gregorian calendar backwards to year one. All minutes are 60 seconds long. Leap seconds are "smeared" so that no leap second table is needed for interpretation, using a [24-hour linear smear](https://developers.google.com/time/smear). The range is from 0001-01-01T00:00:00Z to 9999-12-31T23:59:59.999999999Z. By restricting to that range, we ensure that we can convert to and from [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) date strings. — shape: {nanos?: int, seconds?: string}
  --dimension-definitions: list # The dimensions along which different steps in this execution may vary. This must remain fixed over the life of the execution. Returns INVALID_ARGUMENT if this field is set in an update request. Returns INVALID_ARGUMENT if the same name occurs in more than one dimension_definition. Returns INVALID_ARGUMENT if the size of the list is over 100. - In response: present if set by create - In create request: optional - In update request: never set
  --body-execution-id: string # A unique identifier within a History for this Execution. Returns INVALID_ARGUMENT if this field is set or overwritten by the caller. - In response always set - In create/update request: never set (spec name: executionId)
  --outcome: record # Interprets a result so that humans and machines can act on it. — shape: {failureDetail?: record, inconclusiveDetail?: record, skippedDetail?: record, successDetail?: record, summary?: "unset"|"success"|"failure"|"inconclusive"|"skipped"|"flaky"}
  --specification: record # The details about how to run the execution. — shape: {androidTest?: record, iosTest?: record}
  --state: string@state-completer # The initial state is IN_PROGRESS. The only legal state transitions is from IN_PROGRESS to COMPLETE. A PRECONDITION_FAILED will be returned if an invalid transition is requested. The state can only be set to COMPLETE once. A FAILED_PRECONDITION will be returned if the state is set to COMPLETE multiple times. If the state is set to COMPLETE, all the in-progress steps within the execution will be set as COMPLETE. If the outcome of the step is not set, the outcome will be set to INCONCLUSIVE. - In response always set - In create/update request: optional
  --test-execution-matrix-id: string # TestExecution Matrix ID that the TestExecutionService uses. - In response: present if set by create - In create: optional - In update: never set
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/toolresults/v1beta3/projects/{projectId}/histories/{historyId}/executions/{executionId}"
    path_params: [{name: projectId, var: project_id}, {name: historyId, var: history_id}, {name: executionId, var: execution_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: requestId, var: request_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: completionTime, var: completion_time}, {name: creationTime, var: creation_time}, {name: dimensionDefinitions, var: dimension_definitions}, {name: executionId, var: body_execution_id}, {name: outcome, var: outcome}, {name: specification, var: specification}, {name: state, var: state}, {name: testExecutionMatrixId, var: test_execution_matrix_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, history_id: $history_id, execution_id: $execution_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, request_id: $request_id, completion_time: $completion_time, creation_time: $creation_time, dimension_definitions: $dimension_definitions, body_execution_id: $body_execution_id, outcome: $outcome, specification: $specification, state: $state, test_execution_matrix_id: $test_execution_matrix_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists Screenshot Clusters Returns the list of screenshot clusters corresponding to an execution. Screenshot clusters are created after the execution is finished. Clusters are created from a set of screenshots. Between any two screenshots, a matching score is calculated based off their metadata that determines how similar they are. Screenshots are placed in the cluster that has screens which have the highest matching scores.
#
# GET /toolresults/v1beta3/projects/{projectId}/histories/{historyId}/executions/{executionId}/clusters
# Returns: record<clusters: table<activity: string, clusterId: string, keyScreen: record, screens: list>>
# operationId: toolresults.projects.histories.executions.clusters.list
export def "toolresults-projects-histories-executions-clusters-list" [
  project_id: string
  history_id: string
  execution_id: string
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
    path: "/toolresults/v1beta3/projects/{projectId}/histories/{historyId}/executions/{executionId}/clusters"
    path_params: [{name: projectId, var: project_id}, {name: historyId, var: history_id}, {name: executionId, var: execution_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, history_id: $history_id, execution_id: $execution_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a single screenshot cluster by its ID
#
# GET /toolresults/v1beta3/projects/{projectId}/histories/{historyId}/executions/{executionId}/clusters/{clusterId}
# Returns: record<activity: string, clusterId: string, keyScreen: record<fileReference: string, locale: string, model: string, version: string>, screens: table<fileReference: string, locale: string, model: string, version: string>>
# operationId: toolresults.projects.histories.executions.clusters.get
export def "toolresults-projects-histories-executions-clusters-get" [
  project_id: string
  history_id: string
  execution_id: string
  cluster_id: string
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
    path: "/toolresults/v1beta3/projects/{projectId}/histories/{historyId}/executions/{executionId}/clusters/{clusterId}"
    path_params: [{name: projectId, var: project_id}, {name: historyId, var: history_id}, {name: executionId, var: execution_id}, {name: clusterId, var: cluster_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, history_id: $history_id, execution_id: $execution_id, cluster_id: $cluster_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists Environments for a given Execution. The Environments are sorted by display name. May return any of the following canonical error codes: - PERMISSION_DENIED - if the user is not authorized to read project - INVALID_ARGUMENT - if the request is malformed - NOT_FOUND - if the containing Execution does not exist
#
# GET /toolresults/v1beta3/projects/{projectId}/histories/{historyId}/executions/{executionId}/environments
# Returns: record<environments: table<completionTime: record, creationTime: record, dimensionValue: list, displayName: string, environmentId: string, environmentResult: record, executionId: string, historyId: string, projectId: string, resultsStorage: record, shardSummaries: list>, executionId: string, historyId: string, nextPageToken: string, projectId: string>
# operationId: toolresults.projects.histories.executions.environments.list
export def "toolresults-projects-histories-executions-environments-list" [
  project_id: string
  history_id: string
  execution_id: string
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
  --page-size: int # The maximum number of Environments to fetch. Default value: 25. The server will use this default if the field is not set or has a value of 0.
  --page-token: string # A continuation token to resume the query at the next item.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/toolresults/v1beta3/projects/{projectId}/histories/{historyId}/executions/{executionId}/environments"
    path_params: [{name: projectId, var: project_id}, {name: historyId, var: history_id}, {name: executionId, var: execution_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, history_id: $history_id, execution_id: $execution_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets an Environment. May return any of the following canonical error codes: - PERMISSION_DENIED - if the user is not authorized to read project - INVALID_ARGUMENT - if the request is malformed - NOT_FOUND - if the Environment does not exist
#
# GET /toolresults/v1beta3/projects/{projectId}/histories/{historyId}/executions/{executionId}/environments/{environmentId}
# Returns: record<completionTime: record<nanos: int, seconds: string>, creationTime: record<nanos: int, seconds: string>, dimensionValue: table<key: string, value: string>, displayName: string, environmentId: string, environmentResult: record<outcome: record<failureDetail: record, inconclusiveDetail: record, skippedDetail: record, successDetail: record, summary: string>, state: string, testSuiteOverviews: list<record>>, executionId: string, historyId: string, projectId: string, resultsStorage: record<resultsStoragePath: record<fileUri: string>, xunitXmlFile: record<fileUri: string>>, shardSummaries: table<runs: list, shardResult: record>>
# operationId: toolresults.projects.histories.executions.environments.get
export def "toolresults-projects-histories-executions-environments-get" [
  project_id: string
  history_id: string
  execution_id: string
  environment_id: string
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
    path: "/toolresults/v1beta3/projects/{projectId}/histories/{historyId}/executions/{executionId}/environments/{environmentId}"
    path_params: [{name: projectId, var: project_id}, {name: historyId, var: history_id}, {name: executionId, var: execution_id}, {name: environmentId, var: environment_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, history_id: $history_id, execution_id: $execution_id, environment_id: $environment_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists Steps for a given Execution. The steps are sorted by creation_time in descending order. The step_id key will be used to order the steps with the same creation_time. May return any of the following canonical error codes: - PERMISSION_DENIED - if the user is not authorized to read project - INVALID_ARGUMENT - if the request is malformed - FAILED_PRECONDITION - if an argument in the request happens to be invalid; e.g. if an attempt is made to list the children of a nonexistent Step - NOT_FOUND - if the containing Execution does not exist
#
# GET /toolresults/v1beta3/projects/{projectId}/histories/{historyId}/executions/{executionId}/steps
# Returns: record<nextPageToken: string, steps: table<completionTime: record, creationTime: record, description: string, deviceUsageDuration: record, dimensionValue: list, hasImages: bool, labels: list, multiStep: record, name: string, outcome: record, runDuration: record, state: string, stepId: string, testExecutionStep: record, toolExecutionStep: record>>
# operationId: toolresults.projects.histories.executions.steps.list
export def "toolresults-projects-histories-executions-steps-list" [
  project_id: string
  history_id: string
  execution_id: string
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
  --page-size: int # The maximum number of Steps to fetch. Default value: 25. The server will use this default if the field is not set or has a value of 0. Optional.
  --page-token: string # A continuation token to resume the query at the next item. Optional.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/toolresults/v1beta3/projects/{projectId}/histories/{historyId}/executions/{executionId}/steps"
    path_params: [{name: projectId, var: project_id}, {name: historyId, var: history_id}, {name: executionId, var: execution_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, history_id: $history_id, execution_id: $execution_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a Step. The returned Step will have the id set. May return any of the following canonical error codes: - PERMISSION_DENIED - if the user is not authorized to write to project - INVALID_ARGUMENT - if the request is malformed - FAILED_PRECONDITION - if the step is too large (more than 10Mib) - NOT_FOUND - if the containing Execution does not exist
#
# POST /toolresults/v1beta3/projects/{projectId}/histories/{historyId}/executions/{executionId}/steps
# Returns: record<completionTime: record<nanos: int, seconds: string>, creationTime: record<nanos: int, seconds: string>, description: string, deviceUsageDuration: record<nanos: int, seconds: string>, dimensionValue: table<key: string, value: string>, hasImages: bool, labels: table<key: string, value: string>, multiStep: record<multistepNumber: int, primaryStep: record<individualOutcome: list, rollUp: string>, primaryStepId: string>, name: string, outcome: record<failureDetail: record<crashed: bool, deviceOutOfMemory: bool, failedRoboscript: bool, notInstalled: bool, otherNativeCrash: bool, timedOut: bool, unableToCrawl: bool>, inconclusiveDetail: record<abortedByUser: bool, hasErrorLogs: bool, infrastructureFailure: bool>, skippedDetail: record<incompatibleAppVersion: bool, incompatibleArchitecture: bool, incompatibleDevice: bool>, successDetail: record<otherNativeCrash: bool>, summary: string>, runDuration: record<nanos: int, seconds: string>, state: string, stepId: string, testExecutionStep: record<testIssues: list<record>, testSuiteOverviews: list<record>, testTiming: record<testProcessDuration: record>, toolExecution: record<commandLineArguments: list, exitCode: record, toolLogs: list, toolOutputs: list>>, toolExecutionStep: record<toolExecution: record<commandLineArguments: list, exitCode: record, toolLogs: list, toolOutputs: list>>>
# operationId: toolresults.projects.histories.executions.steps.create
export def "toolresults-projects-histories-executions-steps-create" [
  project_id: string
  history_id: string
  execution_id: string
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
  --request-id: string # A unique request ID for server to detect duplicated requests. For example, a UUID. Optional, but strongly recommended.
  --completion-time: record # A Timestamp represents a point in time independent of any time zone or local calendar, encoded as a count of seconds and fractions of seconds at nanosecond resolution. The count is relative to an epoch at UTC midnight on January 1, 1970, in the proleptic Gregorian calendar which extends the Gregorian calendar backwards to year one. All minutes are 60 seconds long. Leap seconds are "smeared" so that no leap second table is needed for interpretation, using a [24-hour linear smear](https://developers.google.com/time/smear). The range is from 0001-01-01T00:00:00Z to 9999-12-31T23:59:59.999999999Z. By restricting to that range, we ensure that we can convert to and from [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) date strings. — shape: {nanos?: int, seconds?: string}
  --creation-time: record # A Timestamp represents a point in time independent of any time zone or local calendar, encoded as a count of seconds and fractions of seconds at nanosecond resolution. The count is relative to an epoch at UTC midnight on January 1, 1970, in the proleptic Gregorian calendar which extends the Gregorian calendar backwards to year one. All minutes are 60 seconds long. Leap seconds are "smeared" so that no leap second table is needed for interpretation, using a [24-hour linear smear](https://developers.google.com/time/smear). The range is from 0001-01-01T00:00:00Z to 9999-12-31T23:59:59.999999999Z. By restricting to that range, we ensure that we can convert to and from [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) date strings. — shape: {nanos?: int, seconds?: string}
  --description: string # A description of this tool For example: mvn clean package -D skipTests=true - In response: present if set by create/update request - In create/update request: optional
  --device-usage-duration: record # A Duration represents a signed, fixed-length span of time represented as a count of seconds and fractions of seconds at nanosecond resolution. It is independent of any calendar and concepts like "day" or "month". It is related to Timestamp in that the difference between two Timestamp values is a Duration and it can be added or subtracted from a Timestamp. Range is approximately +-10,000 years. — shape: {nanos?: int, seconds?: string}
  --dimension-value: list # If the execution containing this step has any dimension_definition set, then this field allows the child to specify the values of the dimensions. The keys must exactly match the dimension_definition of the execution. For example, if the execution has `dimension_definition = ['attempt', 'device']` then a step must define values for those dimensions, eg. `dimension_value = ['attempt': '1', 'device': 'Nexus 6']` If a step does not participate in one dimension of the matrix, the value for that dimension should be empty string. For example, if one of the tests is executed by a runner which does not support retries, the step could have `dimension_value = ['attempt': '', 'device': 'Nexus 6']` If the step does not participate in any dimensions of the matrix, it may leave dimension_value unset. A PRECONDITION_FAILED will be returned if any of the keys do not exist in the dimension_definition of the execution. A PRECONDITION_FAILED will be returned if another step in this execution already has the same name and dimension_value, but differs on other data fields, for example, step field is different. A PRECONDITION_FAILED will be returned if dimension_value is set, and there is a dimension_definition in the execution which is not specified as one of the keys. - In response: present if set by create - In create request: optional - In update request: never set — item shape: {key?: string, value?: string}
  --has-images: oneof<nothing, bool> # Whether any of the outputs of this step are images whose thumbnails can be fetched with ListThumbnails. - In response: always set - In create/update request: never set
  --labels: list # Arbitrary user-supplied key/value pairs that are associated with the step. Users are responsible for managing the key namespace such that keys don't accidentally collide. An INVALID_ARGUMENT will be returned if the number of labels exceeds 100 or if the length of any of the keys or values exceeds 100 characters. - In response: always set - In create request: optional - In update request: optional; any new key/value pair will be added to the map, and any new value for an existing key will update that key's value — item shape: {key?: string, value?: string}
  --multi-step: record # Details when multiple steps are run with the same configuration as a group. — shape: {multistepNumber?: int, primaryStep?: record, primaryStepId?: string}
  --name: string # A short human-readable name to display in the UI. Maximum of 100 characters. For example: Clean build A PRECONDITION_FAILED will be returned upon creating a new step if it shares its name and dimension_value with an existing step. If two steps represent a similar action, but have different dimension values, they should share the same name. For instance, if the same set of tests is run on two different platforms, the two steps should have the same name. - In response: always set - In create request: always set - In update request: never set
  --outcome: record # Interprets a result so that humans and machines can act on it. — shape: {failureDetail?: record, inconclusiveDetail?: record, skippedDetail?: record, successDetail?: record, summary?: "unset"|"success"|"failure"|"inconclusive"|"skipped"|"flaky"}
  --run-duration: record # A Duration represents a signed, fixed-length span of time represented as a count of seconds and fractions of seconds at nanosecond resolution. It is independent of any calendar and concepts like "day" or "month". It is related to Timestamp in that the difference between two Timestamp values is a Duration and it can be added or subtracted from a Timestamp. Range is approximately +-10,000 years. — shape: {nanos?: int, seconds?: string}
  --state: string@state-completer # The initial state is IN_PROGRESS. The only legal state transitions are * IN_PROGRESS -> COMPLETE A PRECONDITION_FAILED will be returned if an invalid transition is requested. It is valid to create Step with a state set to COMPLETE. The state can only be set to COMPLETE once. A PRECONDITION_FAILED will be returned if the state is set to COMPLETE multiple times. - In response: always set - In create/update request: optional
  --step-id: string # A unique identifier within a Execution for this Step. Returns INVALID_ARGUMENT if this field is set or overwritten by the caller. - In response: always set - In create/update request: never set
  --test-execution-step: record # A step that represents running tests. It accepts ant-junit xml files which will be parsed into structured test results by the service. Xml file paths are updated in order to append more files, however they can't be deleted. Users can also add test results manually by using the test_result field. — shape: {testIssues?: list, testSuiteOverviews?: list, testTiming?: record, toolExecution?: record}
  --tool-execution-step: record # Generic tool step to be used for binaries we do not explicitly support. For example: running cp to copy artifacts from one location to another. — shape: {toolExecution?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/toolresults/v1beta3/projects/{projectId}/histories/{historyId}/executions/{executionId}/steps"
    path_params: [{name: projectId, var: project_id}, {name: historyId, var: history_id}, {name: executionId, var: execution_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: requestId, var: request_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: completionTime, var: completion_time}, {name: creationTime, var: creation_time}, {name: description, var: description}, {name: deviceUsageDuration, var: device_usage_duration}, {name: dimensionValue, var: dimension_value}, {name: hasImages, var: has_images}, {name: labels, var: labels}, {name: multiStep, var: multi_step}, {name: name, var: name}, {name: outcome, var: outcome}, {name: runDuration, var: run_duration}, {name: state, var: state}, {name: stepId, var: step_id}, {name: testExecutionStep, var: test_execution_step}, {name: toolExecutionStep, var: tool_execution_step}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, history_id: $history_id, execution_id: $execution_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, request_id: $request_id, completion_time: $completion_time, creation_time: $creation_time, description: $description, device_usage_duration: $device_usage_duration, dimension_value: $dimension_value, has_images: $has_images, labels: $labels, multi_step: $multi_step, name: $name, outcome: $outcome, run_duration: $run_duration, state: $state, step_id: $step_id, test_execution_step: $test_execution_step, tool_execution_step: $tool_execution_step
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a Step. May return any of the following canonical error codes: - PERMISSION_DENIED - if the user is not authorized to read project - INVALID_ARGUMENT - if the request is malformed - NOT_FOUND - if the Step does not exist
#
# GET /toolresults/v1beta3/projects/{projectId}/histories/{historyId}/executions/{executionId}/steps/{stepId}
# Returns: record<completionTime: record<nanos: int, seconds: string>, creationTime: record<nanos: int, seconds: string>, description: string, deviceUsageDuration: record<nanos: int, seconds: string>, dimensionValue: table<key: string, value: string>, hasImages: bool, labels: table<key: string, value: string>, multiStep: record<multistepNumber: int, primaryStep: record<individualOutcome: list, rollUp: string>, primaryStepId: string>, name: string, outcome: record<failureDetail: record<crashed: bool, deviceOutOfMemory: bool, failedRoboscript: bool, notInstalled: bool, otherNativeCrash: bool, timedOut: bool, unableToCrawl: bool>, inconclusiveDetail: record<abortedByUser: bool, hasErrorLogs: bool, infrastructureFailure: bool>, skippedDetail: record<incompatibleAppVersion: bool, incompatibleArchitecture: bool, incompatibleDevice: bool>, successDetail: record<otherNativeCrash: bool>, summary: string>, runDuration: record<nanos: int, seconds: string>, state: string, stepId: string, testExecutionStep: record<testIssues: list<record>, testSuiteOverviews: list<record>, testTiming: record<testProcessDuration: record>, toolExecution: record<commandLineArguments: list, exitCode: record, toolLogs: list, toolOutputs: list>>, toolExecutionStep: record<toolExecution: record<commandLineArguments: list, exitCode: record, toolLogs: list, toolOutputs: list>>>
# operationId: toolresults.projects.histories.executions.steps.get
export def "toolresults-projects-histories-executions-steps-get" [
  project_id: string
  history_id: string
  execution_id: string
  step_id: string
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
    path: "/toolresults/v1beta3/projects/{projectId}/histories/{historyId}/executions/{executionId}/steps/{stepId}"
    path_params: [{name: projectId, var: project_id}, {name: historyId, var: history_id}, {name: executionId, var: execution_id}, {name: stepId, var: step_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, history_id: $history_id, execution_id: $execution_id, step_id: $step_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing Step with the supplied partial entity. May return any of the following canonical error codes: - PERMISSION_DENIED - if the user is not authorized to write project - INVALID_ARGUMENT - if the request is malformed - FAILED_PRECONDITION - if the requested state transition is illegal (e.g try to upload a duplicate xml file), if the updated step is too large (more than 10Mib) - NOT_FOUND - if the containing Execution does not exist
#
# PATCH /toolresults/v1beta3/projects/{projectId}/histories/{historyId}/executions/{executionId}/steps/{stepId}
# Returns: record<completionTime: record<nanos: int, seconds: string>, creationTime: record<nanos: int, seconds: string>, description: string, deviceUsageDuration: record<nanos: int, seconds: string>, dimensionValue: table<key: string, value: string>, hasImages: bool, labels: table<key: string, value: string>, multiStep: record<multistepNumber: int, primaryStep: record<individualOutcome: list, rollUp: string>, primaryStepId: string>, name: string, outcome: record<failureDetail: record<crashed: bool, deviceOutOfMemory: bool, failedRoboscript: bool, notInstalled: bool, otherNativeCrash: bool, timedOut: bool, unableToCrawl: bool>, inconclusiveDetail: record<abortedByUser: bool, hasErrorLogs: bool, infrastructureFailure: bool>, skippedDetail: record<incompatibleAppVersion: bool, incompatibleArchitecture: bool, incompatibleDevice: bool>, successDetail: record<otherNativeCrash: bool>, summary: string>, runDuration: record<nanos: int, seconds: string>, state: string, stepId: string, testExecutionStep: record<testIssues: list<record>, testSuiteOverviews: list<record>, testTiming: record<testProcessDuration: record>, toolExecution: record<commandLineArguments: list, exitCode: record, toolLogs: list, toolOutputs: list>>, toolExecutionStep: record<toolExecution: record<commandLineArguments: list, exitCode: record, toolLogs: list, toolOutputs: list>>>
# operationId: toolresults.projects.histories.executions.steps.patch
export def "toolresults-projects-histories-executions-steps-patch" [
  project_id: string
  history_id: string
  execution_id: string
  step_id: string
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
  --request-id: string # A unique request ID for server to detect duplicated requests. For example, a UUID. Optional, but strongly recommended.
  --completion-time: record # A Timestamp represents a point in time independent of any time zone or local calendar, encoded as a count of seconds and fractions of seconds at nanosecond resolution. The count is relative to an epoch at UTC midnight on January 1, 1970, in the proleptic Gregorian calendar which extends the Gregorian calendar backwards to year one. All minutes are 60 seconds long. Leap seconds are "smeared" so that no leap second table is needed for interpretation, using a [24-hour linear smear](https://developers.google.com/time/smear). The range is from 0001-01-01T00:00:00Z to 9999-12-31T23:59:59.999999999Z. By restricting to that range, we ensure that we can convert to and from [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) date strings. — shape: {nanos?: int, seconds?: string}
  --creation-time: record # A Timestamp represents a point in time independent of any time zone or local calendar, encoded as a count of seconds and fractions of seconds at nanosecond resolution. The count is relative to an epoch at UTC midnight on January 1, 1970, in the proleptic Gregorian calendar which extends the Gregorian calendar backwards to year one. All minutes are 60 seconds long. Leap seconds are "smeared" so that no leap second table is needed for interpretation, using a [24-hour linear smear](https://developers.google.com/time/smear). The range is from 0001-01-01T00:00:00Z to 9999-12-31T23:59:59.999999999Z. By restricting to that range, we ensure that we can convert to and from [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) date strings. — shape: {nanos?: int, seconds?: string}
  --description: string # A description of this tool For example: mvn clean package -D skipTests=true - In response: present if set by create/update request - In create/update request: optional
  --device-usage-duration: record # A Duration represents a signed, fixed-length span of time represented as a count of seconds and fractions of seconds at nanosecond resolution. It is independent of any calendar and concepts like "day" or "month". It is related to Timestamp in that the difference between two Timestamp values is a Duration and it can be added or subtracted from a Timestamp. Range is approximately +-10,000 years. — shape: {nanos?: int, seconds?: string}
  --dimension-value: list # If the execution containing this step has any dimension_definition set, then this field allows the child to specify the values of the dimensions. The keys must exactly match the dimension_definition of the execution. For example, if the execution has `dimension_definition = ['attempt', 'device']` then a step must define values for those dimensions, eg. `dimension_value = ['attempt': '1', 'device': 'Nexus 6']` If a step does not participate in one dimension of the matrix, the value for that dimension should be empty string. For example, if one of the tests is executed by a runner which does not support retries, the step could have `dimension_value = ['attempt': '', 'device': 'Nexus 6']` If the step does not participate in any dimensions of the matrix, it may leave dimension_value unset. A PRECONDITION_FAILED will be returned if any of the keys do not exist in the dimension_definition of the execution. A PRECONDITION_FAILED will be returned if another step in this execution already has the same name and dimension_value, but differs on other data fields, for example, step field is different. A PRECONDITION_FAILED will be returned if dimension_value is set, and there is a dimension_definition in the execution which is not specified as one of the keys. - In response: present if set by create - In create request: optional - In update request: never set — item shape: {key?: string, value?: string}
  --has-images: oneof<nothing, bool> # Whether any of the outputs of this step are images whose thumbnails can be fetched with ListThumbnails. - In response: always set - In create/update request: never set
  --labels: list # Arbitrary user-supplied key/value pairs that are associated with the step. Users are responsible for managing the key namespace such that keys don't accidentally collide. An INVALID_ARGUMENT will be returned if the number of labels exceeds 100 or if the length of any of the keys or values exceeds 100 characters. - In response: always set - In create request: optional - In update request: optional; any new key/value pair will be added to the map, and any new value for an existing key will update that key's value — item shape: {key?: string, value?: string}
  --multi-step: record # Details when multiple steps are run with the same configuration as a group. — shape: {multistepNumber?: int, primaryStep?: record, primaryStepId?: string}
  --name: string # A short human-readable name to display in the UI. Maximum of 100 characters. For example: Clean build A PRECONDITION_FAILED will be returned upon creating a new step if it shares its name and dimension_value with an existing step. If two steps represent a similar action, but have different dimension values, they should share the same name. For instance, if the same set of tests is run on two different platforms, the two steps should have the same name. - In response: always set - In create request: always set - In update request: never set
  --outcome: record # Interprets a result so that humans and machines can act on it. — shape: {failureDetail?: record, inconclusiveDetail?: record, skippedDetail?: record, successDetail?: record, summary?: "unset"|"success"|"failure"|"inconclusive"|"skipped"|"flaky"}
  --run-duration: record # A Duration represents a signed, fixed-length span of time represented as a count of seconds and fractions of seconds at nanosecond resolution. It is independent of any calendar and concepts like "day" or "month". It is related to Timestamp in that the difference between two Timestamp values is a Duration and it can be added or subtracted from a Timestamp. Range is approximately +-10,000 years. — shape: {nanos?: int, seconds?: string}
  --state: string@state-completer # The initial state is IN_PROGRESS. The only legal state transitions are * IN_PROGRESS -> COMPLETE A PRECONDITION_FAILED will be returned if an invalid transition is requested. It is valid to create Step with a state set to COMPLETE. The state can only be set to COMPLETE once. A PRECONDITION_FAILED will be returned if the state is set to COMPLETE multiple times. - In response: always set - In create/update request: optional
  --body-step-id: string # A unique identifier within a Execution for this Step. Returns INVALID_ARGUMENT if this field is set or overwritten by the caller. - In response: always set - In create/update request: never set (spec name: stepId)
  --test-execution-step: record # A step that represents running tests. It accepts ant-junit xml files which will be parsed into structured test results by the service. Xml file paths are updated in order to append more files, however they can't be deleted. Users can also add test results manually by using the test_result field. — shape: {testIssues?: list, testSuiteOverviews?: list, testTiming?: record, toolExecution?: record}
  --tool-execution-step: record # Generic tool step to be used for binaries we do not explicitly support. For example: running cp to copy artifacts from one location to another. — shape: {toolExecution?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/toolresults/v1beta3/projects/{projectId}/histories/{historyId}/executions/{executionId}/steps/{stepId}"
    path_params: [{name: projectId, var: project_id}, {name: historyId, var: history_id}, {name: executionId, var: execution_id}, {name: stepId, var: step_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: requestId, var: request_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: completionTime, var: completion_time}, {name: creationTime, var: creation_time}, {name: description, var: description}, {name: deviceUsageDuration, var: device_usage_duration}, {name: dimensionValue, var: dimension_value}, {name: hasImages, var: has_images}, {name: labels, var: labels}, {name: multiStep, var: multi_step}, {name: name, var: name}, {name: outcome, var: outcome}, {name: runDuration, var: run_duration}, {name: state, var: state}, {name: stepId, var: body_step_id}, {name: testExecutionStep, var: test_execution_step}, {name: toolExecutionStep, var: tool_execution_step}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, history_id: $history_id, execution_id: $execution_id, step_id: $step_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, request_id: $request_id, completion_time: $completion_time, creation_time: $creation_time, description: $description, device_usage_duration: $device_usage_duration, dimension_value: $dimension_value, has_images: $has_images, labels: $labels, multi_step: $multi_step, name: $name, outcome: $outcome, run_duration: $run_duration, state: $state, body_step_id: $body_step_id, test_execution_step: $test_execution_step, tool_execution_step: $tool_execution_step
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a PerfMetricsSummary. May return any of the following error code(s): - NOT_FOUND - The specified PerfMetricsSummary does not exist
#
# GET /toolresults/v1beta3/projects/{projectId}/histories/{historyId}/executions/{executionId}/steps/{stepId}/perfMetricsSummary
# Returns: record<appStartTime: record<fullyDrawnTime: record<nanos: int, seconds: string>, initialDisplayTime: record<nanos: int, seconds: string>>, executionId: string, graphicsStats: record<buckets: list<record>, highInputLatencyCount: string, jankyFrames: string, missedVsyncCount: string, p50Millis: string, p90Millis: string, p95Millis: string, p99Millis: string, slowBitmapUploadCount: string, slowDrawCount: string, slowUiThreadCount: string, totalFrames: string>, historyId: string, perfEnvironment: record<cpuInfo: record<cpuProcessor: string, cpuSpeedInGhz: float, numberOfCores: int>, memoryInfo: record<memoryCapInKibibyte: string, memoryTotalInKibibyte: string>>, perfMetrics: list<string>, projectId: string, stepId: string>
# operationId: toolresults.projects.histories.executions.steps.getPerfMetricsSummary
export def "toolresults-projects-histories-executions-steps-get-perf-metrics-summary" [
  project_id: string
  history_id: string
  execution_id: string
  step_id: string
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
    path: "/toolresults/v1beta3/projects/{projectId}/histories/{historyId}/executions/{executionId}/steps/{stepId}/perfMetricsSummary"
    path_params: [{name: projectId, var: project_id}, {name: historyId, var: history_id}, {name: executionId, var: execution_id}, {name: stepId, var: step_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, history_id: $history_id, execution_id: $execution_id, step_id: $step_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a PerfMetricsSummary resource. Returns the existing one if it has already been created. May return any of the following error code(s): - NOT_FOUND - The containing Step does not exist
#
# POST /toolresults/v1beta3/projects/{projectId}/histories/{historyId}/executions/{executionId}/steps/{stepId}/perfMetricsSummary
# Returns: record<appStartTime: record<fullyDrawnTime: record<nanos: int, seconds: string>, initialDisplayTime: record<nanos: int, seconds: string>>, executionId: string, graphicsStats: record<buckets: list<record>, highInputLatencyCount: string, jankyFrames: string, missedVsyncCount: string, p50Millis: string, p90Millis: string, p95Millis: string, p99Millis: string, slowBitmapUploadCount: string, slowDrawCount: string, slowUiThreadCount: string, totalFrames: string>, historyId: string, perfEnvironment: record<cpuInfo: record<cpuProcessor: string, cpuSpeedInGhz: float, numberOfCores: int>, memoryInfo: record<memoryCapInKibibyte: string, memoryTotalInKibibyte: string>>, perfMetrics: list<string>, projectId: string, stepId: string>
# operationId: toolresults.projects.histories.executions.steps.perfMetricsSummary.create
export def "toolresults-projects-histories-executions-steps-perf-metrics-summary-create" [
  project_id: string
  history_id: string
  execution_id: string
  step_id: string
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
  --app-start-time: record # shape: {fullyDrawnTime?: record, initialDisplayTime?: record}
  --body-execution-id: string # A tool results execution ID. @OutputOnly (spec name: executionId)
  --graphics-stats: record # Graphics statistics for the App. The information is collected from 'adb shell dumpsys graphicsstats'. For more info see: https://developer.android.com/training/testing/performance.html Statistics will only be present for API 23+. — shape: {buckets?: list, highInputLatencyCount?: string, jankyFrames?: string, missedVsyncCount?: string, p50Millis?: string, p90Millis?: string, p95Millis?: string, p99Millis?: string, slowBitmapUploadCount?: string, slowDrawCount?: string, slowUiThreadCount?: string, totalFrames?: string}
  --body-history-id: string # A tool results history ID. @OutputOnly (spec name: historyId)
  --perf-environment: record # Encapsulates performance environment info — shape: {cpuInfo?: record, memoryInfo?: record}
  --perf-metrics: list<string> # Set of resource collected
  --body-project-id: string # The cloud project @OutputOnly (spec name: projectId)
  --body-step-id: string # A tool results step ID. @OutputOnly (spec name: stepId)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/toolresults/v1beta3/projects/{projectId}/histories/{historyId}/executions/{executionId}/steps/{stepId}/perfMetricsSummary"
    path_params: [{name: projectId, var: project_id}, {name: historyId, var: history_id}, {name: executionId, var: execution_id}, {name: stepId, var: step_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: appStartTime, var: app_start_time}, {name: executionId, var: body_execution_id}, {name: graphicsStats, var: graphics_stats}, {name: historyId, var: body_history_id}, {name: perfEnvironment, var: perf_environment}, {name: perfMetrics, var: perf_metrics}, {name: projectId, var: body_project_id}, {name: stepId, var: body_step_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, history_id: $history_id, execution_id: $execution_id, step_id: $step_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, app_start_time: $app_start_time, body_execution_id: $body_execution_id, graphics_stats: $graphics_stats, body_history_id: $body_history_id, perf_environment: $perf_environment, perf_metrics: $perf_metrics, body_project_id: $body_project_id, body_step_id: $body_step_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists PerfSampleSeries for a given Step. The request provides an optional filter which specifies one or more PerfMetricsType to include in the result; if none returns all. The resulting PerfSampleSeries are sorted by ids. May return any of the following canonical error codes: - NOT_FOUND - The containing Step does not exist
#
# GET /toolresults/v1beta3/projects/{projectId}/histories/{historyId}/executions/{executionId}/steps/{stepId}/perfSampleSeries
# Returns: record<perfSampleSeries: table<basicPerfSampleSeries: record, executionId: string, historyId: string, projectId: string, sampleSeriesId: string, stepId: string>>
# operationId: toolresults.projects.histories.executions.steps.perfSampleSeries.list
export def "toolresults-projects-histories-executions-steps-perf-sample-series-list" [
  project_id: string
  history_id: string
  execution_id: string
  step_id: string
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
  --filter: list<string> # Specify one or more PerfMetricType values such as CPU to filter the result
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/toolresults/v1beta3/projects/{projectId}/histories/{historyId}/executions/{executionId}/steps/{stepId}/perfSampleSeries"
    path_params: [{name: projectId, var: project_id}, {name: historyId, var: history_id}, {name: executionId, var: execution_id}, {name: stepId, var: step_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: filter, var: filter, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, history_id: $history_id, execution_id: $execution_id, step_id: $step_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, filter: $filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a PerfSampleSeries. May return any of the following error code(s): - ALREADY_EXISTS - PerfMetricSummary already exists for the given Step - NOT_FOUND - The containing Step does not exist
#
# POST /toolresults/v1beta3/projects/{projectId}/histories/{historyId}/executions/{executionId}/steps/{stepId}/perfSampleSeries
# Returns: record<basicPerfSampleSeries: record<perfMetricType: string, perfUnit: string, sampleSeriesLabel: string>, executionId: string, historyId: string, projectId: string, sampleSeriesId: string, stepId: string>
# operationId: toolresults.projects.histories.executions.steps.perfSampleSeries.create
export def "toolresults-projects-histories-executions-steps-perf-sample-series-create" [
  project_id: string
  history_id: string
  execution_id: string
  step_id: string
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
  --basic-perf-sample-series: record # Encapsulates the metadata for basic sample series represented by a line chart — shape: {perfMetricType?: "perfMetricTypeUnspecified"|"memory"|"cpu"|"network"|"graphics", perfUnit?: "perfUnitUnspecified"|"kibibyte"|"percent"|"bytesPerSecond"|"framesPerSecond"|"byte", sampleSeriesLabel?: "sampleSeriesTypeUnspecified"|"memoryRssPrivate"|"memoryRssShared"|"memoryRssTotal"|"memoryTotal"|"cpuUser"|"cpuKernel"|"cpuTotal"|"ntBytesTransferred"|"ntBytesReceived"|"networkSent"|"networkReceived"|"graphicsFrameRate"}
  --body-execution-id: string # A tool results execution ID. @OutputOnly (spec name: executionId)
  --body-history-id: string # A tool results history ID. @OutputOnly (spec name: historyId)
  --body-project-id: string # The cloud project @OutputOnly (spec name: projectId)
  --sample-series-id: string # A sample series id @OutputOnly
  --body-step-id: string # A tool results step ID. @OutputOnly (spec name: stepId)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/toolresults/v1beta3/projects/{projectId}/histories/{historyId}/executions/{executionId}/steps/{stepId}/perfSampleSeries"
    path_params: [{name: projectId, var: project_id}, {name: historyId, var: history_id}, {name: executionId, var: execution_id}, {name: stepId, var: step_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: basicPerfSampleSeries, var: basic_perf_sample_series}, {name: executionId, var: body_execution_id}, {name: historyId, var: body_history_id}, {name: projectId, var: body_project_id}, {name: sampleSeriesId, var: sample_series_id}, {name: stepId, var: body_step_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, history_id: $history_id, execution_id: $execution_id, step_id: $step_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, basic_perf_sample_series: $basic_perf_sample_series, body_execution_id: $body_execution_id, body_history_id: $body_history_id, body_project_id: $body_project_id, sample_series_id: $sample_series_id, body_step_id: $body_step_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a PerfSampleSeries. May return any of the following error code(s): - NOT_FOUND - The specified PerfSampleSeries does not exist
#
# GET /toolresults/v1beta3/projects/{projectId}/histories/{historyId}/executions/{executionId}/steps/{stepId}/perfSampleSeries/{sampleSeriesId}
# Returns: record<basicPerfSampleSeries: record<perfMetricType: string, perfUnit: string, sampleSeriesLabel: string>, executionId: string, historyId: string, projectId: string, sampleSeriesId: string, stepId: string>
# operationId: toolresults.projects.histories.executions.steps.perfSampleSeries.get
export def "toolresults-projects-histories-executions-steps-perf-sample-series-get" [
  project_id: string
  history_id: string
  execution_id: string
  step_id: string
  sample_series_id: string
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
    path: "/toolresults/v1beta3/projects/{projectId}/histories/{historyId}/executions/{executionId}/steps/{stepId}/perfSampleSeries/{sampleSeriesId}"
    path_params: [{name: projectId, var: project_id}, {name: historyId, var: history_id}, {name: executionId, var: execution_id}, {name: stepId, var: step_id}, {name: sampleSeriesId, var: sample_series_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, history_id: $history_id, execution_id: $execution_id, step_id: $step_id, sample_series_id: $sample_series_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the Performance Samples of a given Sample Series - The list results are sorted by timestamps ascending - The default page size is 500 samples; and maximum size allowed 5000 - The response token indicates the last returned PerfSample timestamp - When the results size exceeds the page size, submit a subsequent request including the page token to return the rest of the samples up to the page limit May return any of the following canonical error codes: - OUT_OF_RANGE - The specified request page_token is out of valid range - NOT_FOUND - The containing PerfSampleSeries does not exist
#
# GET /toolresults/v1beta3/projects/{projectId}/histories/{historyId}/executions/{executionId}/steps/{stepId}/perfSampleSeries/{sampleSeriesId}/samples
# Returns: record<nextPageToken: string, perfSamples: table<sampleTime: record, value: float>>
# operationId: toolresults.projects.histories.executions.steps.perfSampleSeries.samples.list
export def "toolresults-projects-histories-executions-steps-perf-sample-series-samples-list" [
  project_id: string
  history_id: string
  execution_id: string
  step_id: string
  sample_series_id: string
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
  --page-size: int # The default page size is 500 samples, and the maximum size is 5000. If the page_size is greater than 5000, the effective page size will be 5000
  --page-token: string # Optional, the next_page_token returned in the previous response
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/toolresults/v1beta3/projects/{projectId}/histories/{historyId}/executions/{executionId}/steps/{stepId}/perfSampleSeries/{sampleSeriesId}/samples"
    path_params: [{name: projectId, var: project_id}, {name: historyId, var: history_id}, {name: executionId, var: execution_id}, {name: stepId, var: step_id}, {name: sampleSeriesId, var: sample_series_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, history_id: $history_id, execution_id: $execution_id, step_id: $step_id, sample_series_id: $sample_series_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a batch of PerfSamples - a client can submit multiple batches of Perf Samples through repeated calls to this method in order to split up a large request payload - duplicates and existing timestamp entries will be ignored. - the batch operation may partially succeed - the set of elements successfully inserted is returned in the response (omits items which already existed in the database). May return any of the following canonical error codes: - NOT_FOUND - The containing PerfSampleSeries does not exist
#
# POST /toolresults/v1beta3/projects/{projectId}/histories/{historyId}/executions/{executionId}/steps/{stepId}/perfSampleSeries/{sampleSeriesId}/samples:batchCreate
# Returns: record<perfSamples: table<sampleTime: record, value: float>>
# operationId: toolresults.projects.histories.executions.steps.perfSampleSeries.samples.batchCreate
export def "toolresults-projects-histories-executions-steps-perf-sample-series-samples-batch-create" [
  project_id: string
  history_id: string
  execution_id: string
  step_id: string
  sample_series_id: string
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
  --perf-samples: list # The set of PerfSamples to create should not include existing timestamps — item shape: {sampleTime?: record, value?: float}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/toolresults/v1beta3/projects/{projectId}/histories/{historyId}/executions/{executionId}/steps/{stepId}/perfSampleSeries/{sampleSeriesId}/samples:batchCreate"
    path_params: [{name: projectId, var: project_id}, {name: historyId, var: history_id}, {name: executionId, var: execution_id}, {name: stepId, var: step_id}, {name: sampleSeriesId, var: sample_series_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: perfSamples, var: perf_samples}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, history_id: $history_id, execution_id: $execution_id, step_id: $step_id, sample_series_id: $sample_series_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, perf_samples: $perf_samples
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists Test Cases attached to a Step. Experimental test cases API. Still in active development. May return any of the following canonical error codes: - PERMISSION_DENIED - if the user is not authorized to write to project - INVALID_ARGUMENT - if the request is malformed - NOT_FOUND - if the containing Step does not exist
#
# GET /toolresults/v1beta3/projects/{projectId}/histories/{historyId}/executions/{executionId}/steps/{stepId}/testCases
# Returns: record<nextPageToken: string, testCases: table<elapsedTime: record, endTime: record, skippedMessage: string, stackTraces: list, startTime: record, status: string, testCaseId: string, testCaseReference: record, toolOutputs: list>>
# operationId: toolresults.projects.histories.executions.steps.testCases.list
export def "toolresults-projects-histories-executions-steps-test-cases-list" [
  project_id: string
  history_id: string
  execution_id: string
  step_id: string
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
  --page-size: int # The maximum number of TestCases to fetch. Default value: 100. The server will use this default if the field is not set or has a value of 0. Optional.
  --page-token: string # A continuation token to resume the query at the next item. Optional.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/toolresults/v1beta3/projects/{projectId}/histories/{historyId}/executions/{executionId}/steps/{stepId}/testCases"
    path_params: [{name: projectId, var: project_id}, {name: historyId, var: history_id}, {name: executionId, var: execution_id}, {name: stepId, var: step_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, history_id: $history_id, execution_id: $execution_id, step_id: $step_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets details of a Test Case for a Step. Experimental test cases API. Still in active development. May return any of the following canonical error codes: - PERMISSION_DENIED - if the user is not authorized to write to project - INVALID_ARGUMENT - if the request is malformed - NOT_FOUND - if the containing Test Case does not exist
#
# GET /toolresults/v1beta3/projects/{projectId}/histories/{historyId}/executions/{executionId}/steps/{stepId}/testCases/{testCaseId}
# Returns: record<elapsedTime: record<nanos: int, seconds: string>, endTime: record<nanos: int, seconds: string>, skippedMessage: string, stackTraces: table<exception: string>, startTime: record<nanos: int, seconds: string>, status: string, testCaseId: string, testCaseReference: record<className: string, name: string, testSuiteName: string>, toolOutputs: table<creationTime: record, output: record, testCase: record>>
# operationId: toolresults.projects.histories.executions.steps.testCases.get
export def "toolresults-projects-histories-executions-steps-test-cases-get" [
  project_id: string
  history_id: string
  execution_id: string
  step_id: string
  test_case_id: string
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
    path: "/toolresults/v1beta3/projects/{projectId}/histories/{historyId}/executions/{executionId}/steps/{stepId}/testCases/{testCaseId}"
    path_params: [{name: projectId, var: project_id}, {name: historyId, var: history_id}, {name: executionId, var: execution_id}, {name: stepId, var: step_id}, {name: testCaseId, var: test_case_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, history_id: $history_id, execution_id: $execution_id, step_id: $step_id, test_case_id: $test_case_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists thumbnails of images attached to a step. May return any of the following canonical error codes: - PERMISSION_DENIED - if the user is not authorized to read from the project, or from any of the images - INVALID_ARGUMENT - if the request is malformed - NOT_FOUND - if the step does not exist, or if any of the images do not exist
#
# GET /toolresults/v1beta3/projects/{projectId}/histories/{historyId}/executions/{executionId}/steps/{stepId}/thumbnails
# Returns: record<nextPageToken: string, thumbnails: table<error: record, sourceImage: record, stepId: string, thumbnail: record>>
# operationId: toolresults.projects.histories.executions.steps.thumbnails.list
export def "toolresults-projects-histories-executions-steps-thumbnails-list" [
  project_id: string
  history_id: string
  execution_id: string
  step_id: string
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
  --page-size: int # The maximum number of thumbnails to fetch. Default value: 50. The server will use this default if the field is not set or has a value of 0. Optional.
  --page-token: string # A continuation token to resume the query at the next item. Optional.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/toolresults/v1beta3/projects/{projectId}/histories/{historyId}/executions/{executionId}/steps/{stepId}/thumbnails"
    path_params: [{name: projectId, var: project_id}, {name: historyId, var: history_id}, {name: executionId, var: execution_id}, {name: stepId, var: step_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, history_id: $history_id, execution_id: $execution_id, step_id: $step_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Publish xml files to an existing Step. May return any of the following canonical error codes: - PERMISSION_DENIED - if the user is not authorized to write project - INVALID_ARGUMENT - if the request is malformed - FAILED_PRECONDITION - if the requested state transition is illegal, e.g. try to upload a duplicate xml file or a file too large. - NOT_FOUND - if the containing Execution does not exist
#
# POST /toolresults/v1beta3/projects/{projectId}/histories/{historyId}/executions/{executionId}/steps/{stepId}:publishXunitXmlFiles
# Returns: record<completionTime: record<nanos: int, seconds: string>, creationTime: record<nanos: int, seconds: string>, description: string, deviceUsageDuration: record<nanos: int, seconds: string>, dimensionValue: table<key: string, value: string>, hasImages: bool, labels: table<key: string, value: string>, multiStep: record<multistepNumber: int, primaryStep: record<individualOutcome: list, rollUp: string>, primaryStepId: string>, name: string, outcome: record<failureDetail: record<crashed: bool, deviceOutOfMemory: bool, failedRoboscript: bool, notInstalled: bool, otherNativeCrash: bool, timedOut: bool, unableToCrawl: bool>, inconclusiveDetail: record<abortedByUser: bool, hasErrorLogs: bool, infrastructureFailure: bool>, skippedDetail: record<incompatibleAppVersion: bool, incompatibleArchitecture: bool, incompatibleDevice: bool>, successDetail: record<otherNativeCrash: bool>, summary: string>, runDuration: record<nanos: int, seconds: string>, state: string, stepId: string, testExecutionStep: record<testIssues: list<record>, testSuiteOverviews: list<record>, testTiming: record<testProcessDuration: record>, toolExecution: record<commandLineArguments: list, exitCode: record, toolLogs: list, toolOutputs: list>>, toolExecutionStep: record<toolExecution: record<commandLineArguments: list, exitCode: record, toolLogs: list, toolOutputs: list>>>
# operationId: toolresults.projects.histories.executions.steps.publishXunitXmlFiles
export def "toolresults-projects-histories-executions-steps-publish-xunit-xml-files" [
  project_id: string
  history_id: string
  execution_id: string
  step_id: string
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
  --xunit-xml-files: list # URI of the Xunit XML files to publish. The maximum size of the file this reference is pointing to is 50MB. Required. — item shape: {fileUri?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/toolresults/v1beta3/projects/{projectId}/histories/{historyId}/executions/{executionId}/steps/{stepId}:publishXunitXmlFiles"
    path_params: [{name: projectId, var: project_id}, {name: historyId, var: history_id}, {name: executionId, var: execution_id}, {name: stepId, var: step_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: xunitXmlFiles, var: xunit_xml_files}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, history_id: $history_id, execution_id: $execution_id, step_id: $step_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, xunit_xml_files: $xunit_xml_files
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the Tool Results settings for a project. May return any of the following canonical error codes: - PERMISSION_DENIED - if the user is not authorized to read from project
#
# GET /toolresults/v1beta3/projects/{projectId}/settings
# Returns: record<defaultBucket: string, name: string>
# operationId: toolresults.projects.getSettings
export def "toolresults-projects-get-settings" [
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
    path: "/toolresults/v1beta3/projects/{projectId}/settings"
    path_params: [{name: projectId, var: project_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates resources for settings which have not yet been set. Currently, this creates a single resource: a Google Cloud Storage bucket, to be used as the default bucket for this project. The bucket is created in an FTL-own storage project. Except for in rare cases, calling this method in parallel from multiple clients will only create a single bucket. In order to avoid unnecessary storage charges, the bucket is configured to automatically delete objects older than 90 days. The bucket is created with the following permissions: - Owner access for owners of central storage project (FTL-owned) - Writer access for owners/editors of customer project - Reader access for viewers of customer project The default ACL on objects created in the bucket is: - Owner access for owners of central storage project - Reader access for owners/editors/viewers of customer project See Google Cloud Storage documentation for more details. If there is already a default bucket set and the project can access the bucket, this call does nothing. However, if the project doesn't have the permission to access the bucket or the bucket is deleted, a new bucket will be created. May return any canonical error codes, including the following: - PERMISSION_DENIED - if the user is not authorized to write to project - Any error code raised by Google Cloud Storage
#
# POST /toolresults/v1beta3/projects/{projectId}:initializeSettings
# Returns: record<defaultBucket: string, name: string>
# operationId: toolresults.projects.initializeSettings
export def "toolresults-projects-initialize-settings" [
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
    method: post
    path: "/toolresults/v1beta3/projects/{projectId}:initializeSettings"
    path_params: [{name: projectId, var: project_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists accessibility clusters for a given Step May return any of the following canonical error codes: - PERMISSION_DENIED - if the user is not authorized to read project - INVALID_ARGUMENT - if the request is malformed - FAILED_PRECONDITION - if an argument in the request happens to be invalid; e.g. if the locale format is incorrect - NOT_FOUND - if the containing Step does not exist
#
# GET /toolresults/v1beta3/{name}:accessibilityClusters
# Returns: record<clusters: table<category: string, suggestions: list>, name: string>
# operationId: toolresults.projects.histories.executions.steps.accessibilityClusters
export def "toolresults-projects-histories-executions-steps-accessibility-clusters" [
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
  --locale: string # The accepted format is the canonical Unicode format with hyphen as a delimiter. Language must be lowercase, Language Script - Capitalized, Region - UPPERCASE. See http://www.unicode.org/reports/tr35/#Unicode_locale_identifier for details. Required.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/toolresults/v1beta3/{name}:accessibilityClusters"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: locale, var: locale}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, locale: $locale
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
