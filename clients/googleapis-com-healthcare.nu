# Auto-generated client for Cloud Healthcare API v1beta1
# Source: https://api.apis.guru/v2/specs/googleapis.com/healthcare/v1beta1/openapi.json
# Auth: --token flag or $env.CLOUD_HEALTHCARE_API_TOKEN

const CLIENT = {
  base_url: "https://healthcare.googleapis.com"
  token_env_var: "CLOUD_HEALTHCARE_API_TOKEN"
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

def base-url-completer [] { ["https://healthcare.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def response-view-completer [] { ["BASIC" "FULL" "RESPONSE_VIEW_UNSPECIFIED"] }
def view-completer [] { ["BASIC" "FULL" "MESSAGE_VIEW_UNSPECIFIED" "PARSED_ONLY" "RAW_ONLY" "SCHEMATIZED_ONLY"] }
def view-completer-1 [] { ["ANNOTATION_VIEW_BASIC" "ANNOTATION_VIEW_FULL" "ANNOTATION_VIEW_UNSPECIFIED"] }
def category-completer [] { ["CATEGORY_UNSPECIFIED" "REQUEST" "RESOURCE"] }
def state-completer [] { ["ACTIVE" "ARCHIVED" "DRAFT" "REJECTED" "REVOKED" "STATE_UNSPECIFIED"] }
def complex-data-type-reference-parsing-completer [] { ["COMPLEX_DATA_TYPE_REFERENCE_PARSING_UNSPECIFIED" "DISABLED" "ENABLED"] }
def version-completer [] { ["DSTU2" "R4" "STU3" "VERSION_UNSPECIFIED"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    healthcare-projects-locations-datasets-consent-stores-check-data-access: "record<consentDetails: record, consented: bool>"
    healthcare-projects-locations-datasets-consent-stores-evaluate-user-consents: "record<nextPageToken: string, results: table<consentDetails: record, consented: bool, dataId: string>>"
    healthcare-projects-locations-datasets-consent-stores-query-accessible-data: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    healthcare-projects-locations-datasets-hl7-v2-stores-messages-delete: "record"
    healthcare-projects-locations-datasets-operations-get: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    healthcare-projects-locations-datasets-hl7-v2-stores-messages-patch: "record<createTime: string, data: string, labels: record, messageType: string, name: string, parsedData: record<segments: list<record>>, patientIds: table<type: string, value: string>, schematizedData: record<data: string, error: string>, sendFacility: string, sendTime: string>"
    healthcare-projects-locations-datasets-fhir-stores-fhir-update: "record<contentType: string, data: string, extensions: list<record>>"
    healthcare-projects-locations-datasets-fhir-stores-fhir-patient-everything: "record<contentType: string, data: string, extensions: list<record>>"
    healthcare-projects-locations-datasets-fhir-stores-fhir-resource-purge: "record"
    healthcare-projects-locations-datasets-fhir-stores-fhir-concept-map-translate: "record<contentType: string, data: string, extensions: list<record>>"
    healthcare-projects-locations-datasets-fhir-stores-fhir-history: "record<contentType: string, data: string, extensions: list<record>>"
    healthcare-projects-locations-datasets-fhir-stores-fhir-capabilities: "record<contentType: string, data: string, extensions: list<record>>"
    healthcare-projects-locations-list: "record<locations: table<displayName: string, labels: record, locationId: string, metadata: record, name: string>, nextPageToken: string>"
    healthcare-projects-locations-datasets-operations-list: "record<nextPageToken: string, operations: table<done: bool, error: record, metadata: record, name: string, response: record>>"
    healthcare-projects-locations-datasets-consent-stores-consents-activate: "record<consentArtifact: string, expireTime: string, metadata: record, name: string, policies: table<authorizationRule: record, resourceAttributes: list>, revisionCreateTime: string, revisionId: string, state: string, ttl: string, userId: string>"
    healthcare-projects-locations-datasets-consent-stores-user-data-mappings-archive: "record"
    healthcare-projects-locations-datasets-operations-cancel: "record"
    healthcare-projects-locations-datasets-fhir-stores-configure-search: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    healthcare-projects-locations-datasets-consent-stores-consents-delete-revision: "record"
    healthcare-projects-locations-datasets-annotation-stores-evaluate: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    healthcare-projects-locations-datasets-hl7-v2-stores-export: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    healthcare-projects-locations-datasets-fhir-stores-get-fhir-store-metrics: "record<metrics: table<count: string, resourceType: string, structuredStorageSizeBytes: string>, name: string>"
    healthcare-projects-locations-datasets-hl7-v2-stores-import: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    healthcare-projects-locations-datasets-consent-stores-consents-list-revisions: "record<consents: table<consentArtifact: string, expireTime: string, metadata: record, name: string, policies: list, revisionCreateTime: string, revisionId: string, state: string, ttl: string, userId: string>, nextPageToken: string>"
    healthcare-projects-locations-datasets-consent-stores-consents-reject: "record<consentArtifact: string, expireTime: string, metadata: record, name: string, policies: table<authorizationRule: record, resourceAttributes: list>, revisionCreateTime: string, revisionId: string, state: string, ttl: string, userId: string>"
    healthcare-projects-locations-datasets-consent-stores-consents-revoke: "record<consentArtifact: string, expireTime: string, metadata: record, name: string, policies: table<authorizationRule: record, resourceAttributes: list>, revisionCreateTime: string, revisionId: string, state: string, ttl: string, userId: string>"
    healthcare-projects-locations-services-nlp-analyze-entities: "record<entities: table<entityId: string, preferredTerm: string, vocabularyCodes: list>, entityMentions: table<certaintyAssessment: record, confidence: float, linkedEntities: list, mentionId: string, subject: record, temporalAssessment: record, text: record, type: string>, relationships: table<confidence: float, objectId: string, subjectId: string>>"
    healthcare-projects-locations-datasets-annotation-stores-list: "record<annotationStores: table<labels: record, name: string>, nextPageToken: string>"
    healthcare-projects-locations-datasets-annotation-stores-create: "record<labels: record, name: string>"
    healthcare-projects-locations-datasets-annotation-stores-annotations-list: "record<annotations: table<annotationSource: record, customData: record, imageAnnotation: record, name: string, resourceAnnotation: record, textAnnotation: record>, nextPageToken: string>"
    healthcare-projects-locations-datasets-annotation-stores-annotations-create: "record<annotationSource: record<cloudHealthcareSource: record<name: string>>, customData: record, imageAnnotation: record<boundingPolys: list<record>, frameIndex: int>, name: string, resourceAnnotation: record<label: string>, textAnnotation: record<details: record>>"
    healthcare-projects-locations-datasets-consent-stores-attribute-definitions-list: "record<attributeDefinitions: table<allowedValues: list, category: string, consentDefaultValues: list, dataMappingDefaultValue: string, description: string, name: string>, nextPageToken: string>"
    healthcare-projects-locations-datasets-consent-stores-attribute-definitions-create: "record<allowedValues: list<string>, category: string, consentDefaultValues: list<string>, dataMappingDefaultValue: string, description: string, name: string>"
    healthcare-projects-locations-datasets-consent-stores-consent-artifacts-list: "record<consentArtifacts: table<consentContentScreenshots: list, consentContentVersion: string, guardianSignature: record, metadata: record, name: string, userId: string, userSignature: record, witnessSignature: record>, nextPageToken: string>"
    healthcare-projects-locations-datasets-consent-stores-consent-artifacts-create: "record<consentContentScreenshots: table<gcsUri: string, rawBytes: string>, consentContentVersion: string, guardianSignature: record<image: record<gcsUri: string, rawBytes: string>, metadata: record, signatureTime: string, userId: string>, metadata: record, name: string, userId: string, userSignature: record<image: record<gcsUri: string, rawBytes: string>, metadata: record, signatureTime: string, userId: string>, witnessSignature: record<image: record<gcsUri: string, rawBytes: string>, metadata: record, signatureTime: string, userId: string>>"
    healthcare-projects-locations-datasets-consent-stores-list: "record<consentStores: table<defaultConsentTtl: string, enableConsentCreateOnUpdate: bool, labels: record, name: string>, nextPageToken: string>"
    healthcare-projects-locations-datasets-consent-stores-create: "record<defaultConsentTtl: string, enableConsentCreateOnUpdate: bool, labels: record, name: string>"
    healthcare-projects-locations-datasets-consent-stores-consents-list: "record<consents: table<consentArtifact: string, expireTime: string, metadata: record, name: string, policies: list, revisionCreateTime: string, revisionId: string, state: string, ttl: string, userId: string>, nextPageToken: string>"
    healthcare-projects-locations-datasets-consent-stores-consents-create: "record<consentArtifact: string, expireTime: string, metadata: record, name: string, policies: table<authorizationRule: record, resourceAttributes: list>, revisionCreateTime: string, revisionId: string, state: string, ttl: string, userId: string>"
    healthcare-projects-locations-datasets-list: "record<datasets: table<name: string, timeZone: string>, nextPageToken: string>"
    healthcare-projects-locations-datasets-create: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    healthcare-projects-locations-datasets-dicom-stores-list: "record<dicomStores: table<labels: record, name: string, notificationConfig: record, streamConfigs: list>, nextPageToken: string>"
    healthcare-projects-locations-datasets-dicom-stores-create: "record<labels: record, name: string, notificationConfig: record<pubsubTopic: string, sendForBulkImport: bool>, streamConfigs: table<bigqueryDestination: record>>"
    healthcare-projects-locations-datasets-dicom-stores-studies-series-instances-delete: "record"
    healthcare-projects-locations-datasets-dicom-stores-studies-series-instances-frames-retrieve-rendered: "record<contentType: string, data: string, extensions: list<record>>"
    healthcare-projects-locations-datasets-dicom-stores-studies-store-instances: "record<contentType: string, data: string, extensions: list<record>>"
    healthcare-projects-locations-datasets-fhir-stores-fhir-execute-bundle: "record<contentType: string, data: string, extensions: list<record>>"
    healthcare-projects-locations-datasets-fhir-stores-fhir-resource-incoming-references: "record<contentType: string, data: string, extensions: list<record>>"
    healthcare-projects-locations-datasets-fhir-stores-fhir-concept-map-search-translate: "record<contentType: string, data: string, extensions: list<record>>"
    healthcare-projects-locations-datasets-fhir-stores-fhir-observation-lastn: "record<contentType: string, data: string, extensions: list<record>>"
    healthcare-projects-locations-datasets-fhir-stores-fhir-search: "record<contentType: string, data: string, extensions: list<record>>"
    healthcare-projects-locations-datasets-fhir-stores-fhir-search-type: "record<contentType: string, data: string, extensions: list<record>>"
    healthcare-projects-locations-datasets-fhir-stores-fhir-conditional-delete: "record"
    healthcare-projects-locations-datasets-fhir-stores-fhir-conditional-patch: "record<contentType: string, data: string, extensions: list<record>>"
    healthcare-projects-locations-datasets-fhir-stores-fhir-create: "record<contentType: string, data: string, extensions: list<record>>"
    healthcare-projects-locations-datasets-fhir-stores-fhir-conditional-update: "record<contentType: string, data: string, extensions: list<record>>"
    healthcare-projects-locations-datasets-fhir-stores-fhir-resource-validate: "record<contentType: string, data: string, extensions: list<record>>"
    healthcare-projects-locations-datasets-fhir-stores-list: "record<fhirStores: table<complexDataTypeReferenceParsing: string, defaultSearchHandlingStrict: bool, disableReferentialIntegrity: bool, disableResourceVersioning: bool, enableUpdateCreate: bool, labels: record, name: string, notificationConfig: record, notificationConfigs: list, searchConfig: record, streamConfigs: list, validationConfig: record, version: string>, nextPageToken: string>"
    healthcare-projects-locations-datasets-fhir-stores-create: "record<complexDataTypeReferenceParsing: string, defaultSearchHandlingStrict: bool, disableReferentialIntegrity: bool, disableResourceVersioning: bool, enableUpdateCreate: bool, labels: record, name: string, notificationConfig: record<pubsubTopic: string, sendForBulkImport: bool>, notificationConfigs: table<pubsubTopic: string, sendFullResource: bool>, searchConfig: record<searchParameters: list<record>>, streamConfigs: table<bigqueryDestination: record, deidentifiedStoreDestination: record, resourceTypes: list>, validationConfig: record<disableFhirpathValidation: bool, disableProfileValidation: bool, disableReferenceTypeValidation: bool, disableRequiredFieldValidation: bool, enabledImplementationGuides: list<string>>, version: string>"
    healthcare-projects-locations-datasets-hl7-v2-stores-list: "record<hl7V2Stores: table<labels: record, name: string, notificationConfig: record, notificationConfigs: list, parserConfig: record, rejectDuplicateMessage: bool>, nextPageToken: string>"
    healthcare-projects-locations-datasets-hl7-v2-stores-create: "record<labels: record, name: string, notificationConfig: record<pubsubTopic: string, sendForBulkImport: bool>, notificationConfigs: table<filter: string, pubsubTopic: string>, parserConfig: record<allowNullHeader: bool, schema: record<ignoreMinOccurs: bool, schemas: list, schematizedParsingType: string, types: list, unexpectedSegmentHandling: string>, segmentTerminator: string, version: string>, rejectDuplicateMessage: bool>"
    healthcare-projects-locations-datasets-hl7-v2-stores-messages-list: "record<hl7V2Messages: table<createTime: string, data: string, labels: record, messageType: string, name: string, parsedData: record, patientIds: list, schematizedData: record, sendFacility: string, sendTime: string>, nextPageToken: string>"
    healthcare-projects-locations-datasets-hl7-v2-stores-messages-create: "record<createTime: string, data: string, labels: record, messageType: string, name: string, parsedData: record<segments: list<record>>, patientIds: table<type: string, value: string>, schematizedData: record<data: string, error: string>, sendFacility: string, sendTime: string>"
    healthcare-projects-locations-datasets-hl7-v2-stores-messages-batch-get: "record<messages: table<createTime: string, data: string, labels: record, messageType: string, name: string, parsedData: record, patientIds: list, schematizedData: record, sendFacility: string, sendTime: string>>"
    healthcare-projects-locations-datasets-hl7-v2-stores-messages-ingest: "record<hl7Ack: string, message: record<createTime: string, data: string, labels: record, messageType: string, name: string, parsedData: record<segments: list>, patientIds: list<record>, schematizedData: record<data: string, error: string>, sendFacility: string, sendTime: string>>"
    healthcare-projects-locations-datasets-consent-stores-user-data-mappings-list: "record<nextPageToken: string, userDataMappings: table<archiveTime: string, archived: bool, dataId: string, name: string, resourceAttributes: list, userId: string>>"
    healthcare-projects-locations-datasets-consent-stores-user-data-mappings-create: "record<archiveTime: string, archived: bool, dataId: string, name: string, resourceAttributes: table<attributeDefinitionId: string, values: list>, userId: string>"
    healthcare-projects-locations-datasets-hl7-v2-stores-get-iam-policy: "record<auditConfigs: table<auditLogConfigs: list, service: string>, bindings: table<condition: record, members: list, role: string>, etag: string, version: int>"
    healthcare-projects-locations-datasets-hl7-v2-stores-set-iam-policy: "record<auditConfigs: table<auditLogConfigs: list, service: string>, bindings: table<condition: record, members: list, role: string>, etag: string, version: int>"
    healthcare-projects-locations-datasets-hl7-v2-stores-test-iam-permissions: "record<permissions: list<string>>"
    healthcare-projects-locations-datasets-deidentify: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    healthcare-projects-locations-datasets-fhir-stores-deidentify: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["healthcare-projects-locations-datasets-consent-stores-check-data-access" "healthcare-projects-locations-datasets-consent-stores-evaluate-user-consents" "healthcare-projects-locations-datasets-consent-stores-query-accessible-data" "healthcare-projects-locations-datasets-hl7-v2-stores-messages-delete" "healthcare-projects-locations-datasets-operations-get" "healthcare-projects-locations-datasets-hl7-v2-stores-messages-patch" "healthcare-projects-locations-datasets-fhir-stores-fhir-update" "healthcare-projects-locations-datasets-fhir-stores-fhir-patient-everything" "healthcare-projects-locations-datasets-fhir-stores-fhir-resource-purge" "healthcare-projects-locations-datasets-fhir-stores-fhir-concept-map-translate" "healthcare-projects-locations-datasets-fhir-stores-fhir-history" "healthcare-projects-locations-datasets-fhir-stores-fhir-capabilities" "healthcare-projects-locations-list" "healthcare-projects-locations-datasets-operations-list" "healthcare-projects-locations-datasets-consent-stores-consents-activate" "healthcare-projects-locations-datasets-consent-stores-user-data-mappings-archive" "healthcare-projects-locations-datasets-operations-cancel" "healthcare-projects-locations-datasets-fhir-stores-configure-search" "healthcare-projects-locations-datasets-consent-stores-consents-delete-revision" "healthcare-projects-locations-datasets-annotation-stores-evaluate" "healthcare-projects-locations-datasets-hl7-v2-stores-export" "healthcare-projects-locations-datasets-fhir-stores-get-fhir-store-metrics" "healthcare-projects-locations-datasets-hl7-v2-stores-import" "healthcare-projects-locations-datasets-consent-stores-consents-list-revisions" "healthcare-projects-locations-datasets-consent-stores-consents-reject" "healthcare-projects-locations-datasets-consent-stores-consents-revoke" "healthcare-projects-locations-services-nlp-analyze-entities" "healthcare-projects-locations-datasets-annotation-stores-list" "healthcare-projects-locations-datasets-annotation-stores-create" "healthcare-projects-locations-datasets-annotation-stores-annotations-list" "healthcare-projects-locations-datasets-annotation-stores-annotations-create" "healthcare-projects-locations-datasets-consent-stores-attribute-definitions-list" "healthcare-projects-locations-datasets-consent-stores-attribute-definitions-create" "healthcare-projects-locations-datasets-consent-stores-consent-artifacts-list" "healthcare-projects-locations-datasets-consent-stores-consent-artifacts-create" "healthcare-projects-locations-datasets-consent-stores-list" "healthcare-projects-locations-datasets-consent-stores-create" "healthcare-projects-locations-datasets-consent-stores-consents-list" "healthcare-projects-locations-datasets-consent-stores-consents-create" "healthcare-projects-locations-datasets-list" "healthcare-projects-locations-datasets-create" "healthcare-projects-locations-datasets-dicom-stores-list" "healthcare-projects-locations-datasets-dicom-stores-create" "healthcare-projects-locations-datasets-dicom-stores-studies-series-instances-delete" "healthcare-projects-locations-datasets-dicom-stores-studies-series-instances-frames-retrieve-rendered" "healthcare-projects-locations-datasets-dicom-stores-studies-store-instances" "healthcare-projects-locations-datasets-fhir-stores-fhir-execute-bundle" "healthcare-projects-locations-datasets-fhir-stores-fhir-resource-incoming-references" "healthcare-projects-locations-datasets-fhir-stores-fhir-concept-map-search-translate" "healthcare-projects-locations-datasets-fhir-stores-fhir-observation-lastn" "healthcare-projects-locations-datasets-fhir-stores-fhir-search" "healthcare-projects-locations-datasets-fhir-stores-fhir-search-type" "healthcare-projects-locations-datasets-fhir-stores-fhir-conditional-delete" "healthcare-projects-locations-datasets-fhir-stores-fhir-conditional-patch" "healthcare-projects-locations-datasets-fhir-stores-fhir-create" "healthcare-projects-locations-datasets-fhir-stores-fhir-conditional-update" "healthcare-projects-locations-datasets-fhir-stores-fhir-resource-validate" "healthcare-projects-locations-datasets-fhir-stores-list" "healthcare-projects-locations-datasets-fhir-stores-create" "healthcare-projects-locations-datasets-hl7-v2-stores-list" "healthcare-projects-locations-datasets-hl7-v2-stores-create" "healthcare-projects-locations-datasets-hl7-v2-stores-messages-list" "healthcare-projects-locations-datasets-hl7-v2-stores-messages-create" "healthcare-projects-locations-datasets-hl7-v2-stores-messages-batch-get" "healthcare-projects-locations-datasets-hl7-v2-stores-messages-ingest" "healthcare-projects-locations-datasets-consent-stores-user-data-mappings-list" "healthcare-projects-locations-datasets-consent-stores-user-data-mappings-create" "healthcare-projects-locations-datasets-hl7-v2-stores-get-iam-policy" "healthcare-projects-locations-datasets-hl7-v2-stores-set-iam-policy" "healthcare-projects-locations-datasets-hl7-v2-stores-test-iam-permissions" "healthcare-projects-locations-datasets-deidentify" "healthcare-projects-locations-datasets-fhir-stores-deidentify" "commands"] | sort) } | get name | first)
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

# Checks if a particular data_id of a User data mapping in the specified consent store is consented for the specified use.
#
# POST /v1beta1/{consentStore}:checkDataAccess
# Returns: record<consentDetails: record, consented: bool>
# operationId: healthcare.projects.locations.datasets.consentStores.checkDataAccess
export def "healthcare-projects-locations-datasets-consent-stores-check-data-access" [
  consent_store: string
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
  --consent-list: record # List of resource names of Consent resources. — shape: {consents?: list<string>}
  --data-id: string # Required. The unique identifier of the resource to check access for. This identifier must correspond to a User data mapping in the given consent store.
  --request-attributes: record # The values of request attributes associated with this access request.
  --response-view: string@response-view-completer # Optional. The view for CheckDataAccessResponse. If unspecified, defaults to `BASIC` and returns `consented` as `TRUE` or `FALSE`.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{consentStore}:checkDataAccess"
    path_params: [{name: consentStore, var: consent_store}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: consentList, var: consent_list}, {name: dataId, var: data_id}, {name: requestAttributes, var: request_attributes}, {name: responseView, var: response_view}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    consent_store: $consent_store, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, consent_list: $consent_list, data_id: $data_id, request_attributes: $request_attributes, response_view: $response_view
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Evaluates the user's Consents for all matching User data mappings. Note: User data mappings are indexed asynchronously, which can cause a slight delay between the time mappings are created or updated and when they are included in EvaluateUserConsents results.
#
# POST /v1beta1/{consentStore}:evaluateUserConsents
# Returns: record<nextPageToken: string, results: table<consentDetails: record, consented: bool, dataId: string>>
# operationId: healthcare.projects.locations.datasets.consentStores.evaluateUserConsents
export def "healthcare-projects-locations-datasets-consent-stores-evaluate-user-consents" [
  consent_store: string
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
  --consent-list: record # List of resource names of Consent resources. — shape: {consents?: list<string>}
  --page-size: int # Optional. Limit on the number of User data mappings to return in a single response. If not specified, 100 is used. May not be larger than 1000. (format: int32)
  --page-token: string # Optional. Token to retrieve the next page of results, or empty to get the first page.
  --request-attributes: record # Required. The values of request attributes associated with this access request.
  --resource-attributes: record # Optional. The values of resource attributes associated with the resources being requested. If no values are specified, then all resources are queried.
  --response-view: string@response-view-completer # Optional. The view for EvaluateUserConsentsResponse. If unspecified, defaults to `BASIC` and returns `consented` as `TRUE` or `FALSE`.
  --user-id: string # Required. User ID to evaluate consents for.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{consentStore}:evaluateUserConsents"
    path_params: [{name: consentStore, var: consent_store}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: consentList, var: consent_list}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}, {name: requestAttributes, var: request_attributes}, {name: resourceAttributes, var: resource_attributes}, {name: responseView, var: response_view}, {name: userId, var: user_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    consent_store: $consent_store, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, consent_list: $consent_list, page_size: $page_size, page_token: $page_token, request_attributes: $request_attributes, resource_attributes: $resource_attributes, response_view: $response_view, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Queries all data_ids that are consented for a specified use in the given consent store and writes them to a specified destination. The returned Operation includes a progress counter for the number of User data mappings processed. If the request is successful, a detailed response is returned of type QueryAccessibleDataResponse, contained in the response field when the operation finishes. The metadata field type is OperationMetadata. Errors are logged to Cloud Logging (see [Viewing error logs in Cloud Logging](https://cloud.google.com/healthcare/docs/how-tos/logging)). For example, the following sample log entry shows a `failed to evaluate consent policy` error that occurred during a QueryAccessibleData call to consent store `projects/{project_id}/locations/{location_id}/datasets/{dataset_id}/consentStores/{consent_store_id}`. ```json jsonPayload: { @type: "type.googleapis.com/google.cloud.healthcare.logging.QueryAccessibleDataLogEntry" error: { code: 9 message: "failed to evaluate consent policy" } resourceName: "projects/{project_id}/locations/{location_id}/datasets/{dataset_id}/consentStores/{consent_store_id}/consents/{consent_id}" } logName: "projects/{project_id}/logs/healthcare.googleapis.com%2Fquery_accessible_data" operation: { id: "projects/{project_id}/locations/{location_id}/datasets/{dataset_id}/operations/{operation_id}" producer: "healthcare.googleapis.com/QueryAccessibleData" } receiveTimestamp: "TIMESTAMP" resource: { labels: { consent_store_id: "{consent_store_id}" dataset_id: "{dataset_id}" location: "{location_id}" project_id: "{project_id}" } type: "healthcare_consent_store" } severity: "ERROR" timestamp: "TIMESTAMP" ```
#
# POST /v1beta1/{consentStore}:queryAccessibleData
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: healthcare.projects.locations.datasets.consentStores.queryAccessibleData
export def "healthcare-projects-locations-datasets-consent-stores-query-accessible-data" [
  consent_store: string
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
  --gcs-destination: record # The Cloud Storage location for export. — shape: {uriPrefix?: string}
  --request-attributes: record # The values of request attributes associated with this access request.
  --resource-attributes: record # Optional. The values of resource attributes associated with the type of resources being requested. If no values are specified, then all resource types are included in the output.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{consentStore}:queryAccessibleData"
    path_params: [{name: consentStore, var: consent_store}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: gcsDestination, var: gcs_destination}, {name: requestAttributes, var: request_attributes}, {name: resourceAttributes, var: resource_attributes}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    consent_store: $consent_store, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, gcs_destination: $gcs_destination, request_attributes: $request_attributes, resource_attributes: $resource_attributes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an HL7v2 message.
#
# DELETE /v1beta1/{name}
# Returns: record
# operationId: healthcare.projects.locations.datasets.hl7V2Stores.messages.delete
export def "healthcare-projects-locations-datasets-hl7-v2-stores-messages-delete" [
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
    path: "/v1beta1/{name}"
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

# Gets the latest state of a long-running operation. Clients can use this method to poll the operation result at intervals as recommended by the API service.
#
# GET /v1beta1/{name}
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: healthcare.projects.locations.datasets.operations.get
export def "healthcare-projects-locations-datasets-operations-get" [
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
  --view: string@view-completer # Specifies which parts of the Message resource to return in the response. When unspecified, equivalent to FULL.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta1/{name}"
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

# Update the message. The contents of the message in Message.data and data extracted from the contents such as Message.create_time can't be altered. Only the Message.labels field is allowed to be updated. The labels in the request are merged with the existing set of labels. Existing labels with the same keys are updated.
#
# PATCH /v1beta1/{name}
# Returns: record<createTime: string, data: string, labels: record, messageType: string, name: string, parsedData: record<segments: list<record>>, patientIds: table<type: string, value: string>, schematizedData: record<data: string, error: string>, sendFacility: string, sendTime: string>
# operationId: healthcare.projects.locations.datasets.hl7V2Stores.messages.patch
export def "healthcare-projects-locations-datasets-hl7-v2-stores-messages-patch" [
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
  --update-mask: string # The update mask applies to the resource. For the `FieldMask` definition, see https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#fieldmask
  --data: string # Raw message bytes. (format: byte)
  --labels: record # User-supplied key-value pairs used to organize HL7v2 stores. Label keys must be between 1 and 63 characters long, have a UTF-8 encoding of maximum 128 bytes, and must conform to the following PCRE regular expression: \p{Ll}\p{Lo}{0,62} Label values are optional, must be between 1 and 63 characters long, have a UTF-8 encoding of maximum 128 bytes, and must conform to the following PCRE regular expression: [\p{Ll}\p{Lo}\p{N}_-]{0,63} No more than 64 labels can be associated with a given store.
  --message-type: string # The message type for this message. MSH-9.1.
  --body-name: string # Resource name of the Message, of the form `projects/{project_id}/locations/{location_id}/datasets/{dataset_id}/hl7V2Stores/{hl7_v2_store_id}/messages/{message_id}`. Assigned by the server. (spec name: name)
  --parsed-data: record # The content of an HL7v2 message in a structured format. — shape: {segments?: list}
  --patient-ids: list # All patient IDs listed in the PID-2, PID-3, and PID-4 segments of this message. — item shape: {type?: string, value?: string}
  --schematized-data: record # The content of an HL7v2 message in a structured format as specified by a schema. — shape: {data?: string, error?: string}
  --send-facility: string # The hospital that this message came from. MSH-4.
  --send-time: string # The datetime the sending application sent this message. MSH-7. (format: google-datetime)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1beta1/{name}"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: updateMask, var: update_mask}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}, {name: labels, var: labels}, {name: messageType, var: message_type}, {name: name, var: body_name}, {name: parsedData, var: parsed_data}, {name: patientIds, var: patient_ids}, {name: schematizedData, var: schematized_data}, {name: sendFacility, var: send_facility}, {name: sendTime, var: send_time}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, update_mask: $update_mask, data: $data, labels: $labels, message_type: $message_type, body_name: $body_name, parsed_data: $parsed_data, patient_ids: $patient_ids, schematized_data: $schematized_data, send_facility: $send_facility, send_time: $send_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the entire contents of a resource. Implements the FHIR standard update interaction ([DSTU2](https://hl7.org/implement/standards/fhir/DSTU2/http.html#update), [STU3](https://hl7.org/implement/standards/fhir/STU3/http.html#update), [R4](https://hl7.org/implement/standards/fhir/R4/http.html#update)). If the specified resource does not exist and the FHIR store has enable_update_create set, creates the resource with the client-specified ID. It is strongly advised not to include or encode any sensitive data such as patient identifiers in client-specified resource IDs. Those IDs are part of the FHIR resource path recorded in Cloud Audit Logs and Pub/Sub notifications. Those IDs can also be contained in reference fields within other resources. The request body must contain a JSON-encoded FHIR resource, and the request headers must contain `Content-Type: application/fhir+json`. The resource must contain an `id` element having an identical value to the ID in the REST path of the request. On success, the response body contains a JSON-encoded representation of the updated resource, including the server-assigned version ID. Errors generated by the FHIR store contain a JSON-encoded `OperationOutcome` resource describing the reason for the error. If the request cannot be mapped to a valid API method on a FHIR store, a generic GCP error might be returned instead. For samples that show how to call `update`, see [Updating a FHIR resource](https://cloud.google.com/healthcare/docs/how-tos/fhir-resources#updating_a_fhir_resource).
#
# PUT /v1beta1/{name}
# Returns: record<contentType: string, data: string, extensions: list<record>>
# operationId: healthcare.projects.locations.datasets.fhirStores.fhir.update
export def "healthcare-projects-locations-datasets-fhir-stores-fhir-update" [
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
  --content-type: string # The HTTP Content-Type header value specifying the content type of the body.
  --data: string # The HTTP request/response body as raw binary. (format: byte)
  --extensions: list # Application specific response metadata. Must be set in the first response for streaming APIs.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1beta1/{name}"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: contentType, var: content_type}, {name: data, var: data}, {name: extensions, var: extensions}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, content_type: $content_type, data: $data, extensions: $extensions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a Patient resource and resources related to that patient. Implements the FHIR extended operation Patient-everything ([DSTU2](https://hl7.org/implement/standards/fhir/DSTU2/patient-operations.html#everything), [STU3](https://hl7.org/implement/standards/fhir/STU3/patient-operations.html#everything), [R4](https://hl7.org/implement/standards/fhir/R4/patient-operations.html#everything)). On success, the response body contains a JSON-encoded representation of a `Bundle` resource of type `searchset`, containing the results of the operation. Errors generated by the FHIR store contain a JSON-encoded `OperationOutcome` resource describing the reason for the error. If the request cannot be mapped to a valid API method on a FHIR store, a generic GCP error might be returned instead. The resources in scope for the response are: * The patient resource itself. * All the resources directly referenced by the patient resource. * Resources directly referencing the patient resource that meet the inclusion criteria. The inclusion criteria are based on the membership rules in the patient compartment definition ([DSTU2](https://hl7.org/fhir/DSTU2/compartment-patient.html), [STU3](http://www.hl7.org/fhir/stu3/compartmentdefinition-patient.html), [R4](https://hl7.org/fhir/R4/compartmentdefinition-patient.html)), which details the eligible resource types and referencing search parameters. For samples that show how to call `Patient-everything`, see [Getting all patient compartment resources](https://cloud.google.com/healthcare/docs/how-tos/fhir-resources#getting_all_patient_compartment_resources).
#
# GET /v1beta1/{name}/$everything
# Returns: record<contentType: string, data: string, extensions: list<record>>
# operationId: healthcare.projects.locations.datasets.fhirStores.fhir.Patient-everything
export def "healthcare-projects-locations-datasets-fhir-stores-fhir-patient-everything" [
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
  --count: int # Maximum number of resources in a page. If not specified, 100 is used. May not be larger than 1000.
  --page-token: string # Used to retrieve the next or previous page of results when using pagination. Set `_page_token` to the value of _page_token set in next or previous page links' url. Next and previous page are returned in the response bundle's links field, where `link.relation` is "previous" or "next". Omit `_page_token` if no previous request has been made.
  --since: string # If provided, only resources updated after this time are returned. The time uses the format YYYY-MM-DDThh:mm:ss.sss+zz:zz. For example, `2015-02-07T13:28:17.239+02:00` or `2017-01-01T00:00:00Z`. The time must be specified to the second and include a time zone.
  --type: string # String of comma-delimited FHIR resource types. If provided, only resources of the specified resource type(s) are returned. Specifying multiple `_type` parameters isn't supported. For example, the result of `_type=Observation&_type=Encounter` is undefined. Use `_type=Observation,Encounter` instead.
  --end: string # The response includes records prior to the end date. The date uses the format YYYY-MM-DD. If no end date is provided, all records subsequent to the start date are in scope.
  --start: string # The response includes records subsequent to the start date. The date uses the format YYYY-MM-DD. If no start date is provided, all records prior to the end date are in scope.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta1/{name}/$everything"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: _count, var: count}, {name: _page_token, var: page_token}, {name: _since, var: since}, {name: _type, var: type}, {name: end, var: end}, {name: start, var: start}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, count: $count, page_token: $page_token, since: $since, type: $type, end: $end, start: $start
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes all the historical versions of a resource (excluding the current version) from the FHIR store. To remove all versions of a resource, first delete the current version and then call this method. This is not a FHIR standard operation. For samples that show how to call `Resource-purge`, see [Deleting historical versions of a FHIR resource](https://cloud.google.com/healthcare/docs/how-tos/fhir-resources#deleting_historical_versions_of_a_fhir_resource).
#
# DELETE /v1beta1/{name}/$purge
# Returns: record
# operationId: healthcare.projects.locations.datasets.fhirStores.fhir.Resource-purge
export def "healthcare-projects-locations-datasets-fhir-stores-fhir-resource-purge" [
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
    path: "/v1beta1/{name}/$purge"
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

# Translates a code from one value set to another using a concept map. You can provide your own concept maps to translate any code system to another code system. Implements the FHIR standard $translate operation ([DSTU2](https://www.hl7.org/fhir/DSTU2/operation-conceptmap-translate.html), [STU3](https://www.hl7.org/fhir/STU3/operation-conceptmap-translate.html), [R4](https://www.hl7.org/fhir/R4/operation-conceptmap-translate.html)). On success, the response body contains a JSON-encoded representation of a FHIR Parameters resource, which includes the translation result. Errors generated by the FHIR store contain a JSON-encoded `OperationOutcome` resource describing the reason for the error. If the request cannot be mapped to a valid API method on a FHIR store, a generic GCP error might be returned instead.
#
# GET /v1beta1/{name}/$translate
# Returns: record<contentType: string, data: string, extensions: list<record>>
# operationId: healthcare.projects.locations.datasets.fhirStores.fhir.ConceptMap-translate
export def "healthcare-projects-locations-datasets-fhir-stores-fhir-concept-map-translate" [
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
  --code: string # The code to translate.
  --concept-map-version: string # The version of the concept map to use. If unset, the most current version is used.
  --system: string # The system for the code to be translated.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta1/{name}/$translate"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: code, var: code}, {name: conceptMapVersion, var: concept_map_version}, {name: system, var: system}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, code: $code, concept_map_version: $concept_map_version, system: $system
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all the versions of a resource (including the current version and deleted versions) from the FHIR store. Implements the per-resource form of the FHIR standard history interaction ([DSTU2](https://hl7.org/implement/standards/fhir/DSTU2/http.html#history), [STU3](https://hl7.org/implement/standards/fhir/STU3/http.html#history), [R4](https://hl7.org/implement/standards/fhir/R4/http.html#history)). On success, the response body contains a JSON-encoded representation of a `Bundle` resource of type `history`, containing the version history sorted from most recent to oldest versions. Errors generated by the FHIR store contain a JSON-encoded `OperationOutcome` resource describing the reason for the error. If the request cannot be mapped to a valid API method on a FHIR store, a generic GCP error might be returned instead. For samples that show how to call `history`, see [Listing FHIR resource versions](https://cloud.google.com/healthcare/docs/how-tos/fhir-resources#listing_fhir_resource_versions).
#
# GET /v1beta1/{name}/_history
# Returns: record<contentType: string, data: string, extensions: list<record>>
# operationId: healthcare.projects.locations.datasets.fhirStores.fhir.history
export def "healthcare-projects-locations-datasets-fhir-stores-fhir-history" [
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
  --at: string # Only include resource versions that were current at some point during the time period specified in the date time value. The date parameter format is yyyy-mm-ddThh:mm:ss[Z|(+|-)hh:mm] Clients may specify any of the following: * An entire year: `_at=2019` * An entire month: `_at=2019-01` * A specific day: `_at=2019-01-20` * A specific second: `_at=2018-12-31T23:59:58Z`
  --count: int # The maximum number of search results on a page. If not specified, 100 is used. May not be larger than 1000.
  --page-token: string # Used to retrieve the first, previous, next, or last page of resource versions when using pagination. Value should be set to the value of `_page_token` set in next or previous page links' URLs. Next and previous page are returned in the response bundle's links field, where `link.relation` is "previous" or "next". Omit `_page_token` if no previous request has been made.
  --since: string # Only include resource versions that were created at or after the given instant in time. The instant in time uses the format YYYY-MM-DDThh:mm:ss.sss+zz:zz (for example 2015-02-07T13:28:17.239+02:00 or 2017-01-01T00:00:00Z). The time must be specified to the second and include a time zone.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta1/{name}/_history"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: _at, var: at}, {name: _count, var: count}, {name: _page_token, var: page_token}, {name: _since, var: since}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, at: $at, count: $count, page_token: $page_token, since: $since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the FHIR capability statement ([STU3](https://hl7.org/implement/standards/fhir/STU3/capabilitystatement.html), [R4](https://hl7.org/implement/standards/fhir/R4/capabilitystatement.html)), or the [conformance statement](https://hl7.org/implement/standards/fhir/DSTU2/conformance.html) in the DSTU2 case for the store, which contains a description of functionality supported by the server. Implements the FHIR standard capabilities interaction ([STU3](https://hl7.org/implement/standards/fhir/STU3/http.html#capabilities), [R4](https://hl7.org/implement/standards/fhir/R4/http.html#capabilities)), or the [conformance interaction](https://hl7.org/implement/standards/fhir/DSTU2/http.html#conformance) in the DSTU2 case. On success, the response body contains a JSON-encoded representation of a `CapabilityStatement` resource.
#
# GET /v1beta1/{name}/fhir/metadata
# Returns: record<contentType: string, data: string, extensions: list<record>>
# operationId: healthcare.projects.locations.datasets.fhirStores.fhir.capabilities
export def "healthcare-projects-locations-datasets-fhir-stores-fhir-capabilities" [
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
    path: "/v1beta1/{name}/fhir/metadata"
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

# Lists information about the supported locations for this service.
#
# GET /v1beta1/{name}/locations
# Returns: record<locations: table<displayName: string, labels: record, locationId: string, metadata: record, name: string>, nextPageToken: string>
# operationId: healthcare.projects.locations.list
export def "healthcare-projects-locations-list" [
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
  --filter: string # A filter to narrow down results to a preferred subset. The filtering language accepts strings like `"displayName=tokyo"`, and is documented in more detail in [AIP-160](https://google.aip.dev/160).
  --page-size: int # The maximum number of results to return. If not set, the service selects a default.
  --page-token: string # A page token received from the `next_page_token` field in the response. Send that page token to receive the subsequent page.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta1/{name}/locations"
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

# Lists operations that match the specified filter in the request. If the server doesn't support this method, it returns `UNIMPLEMENTED`.
#
# GET /v1beta1/{name}/operations
# Returns: record<nextPageToken: string, operations: table<done: bool, error: record, metadata: record, name: string, response: record>>
# operationId: healthcare.projects.locations.datasets.operations.list
export def "healthcare-projects-locations-datasets-operations-list" [
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
    path: "/v1beta1/{name}/operations"
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

# Activates the latest revision of the specified Consent by committing a new revision with `state` updated to `ACTIVE`. If the latest revision of the specified Consent is in the `ACTIVE` state, no new revision is committed. A FAILED_PRECONDITION error occurs if the latest revision of the specified consent is in the `REJECTED` or `REVOKED` state.
#
# POST /v1beta1/{name}:activate
# Returns: record<consentArtifact: string, expireTime: string, metadata: record, name: string, policies: table<authorizationRule: record, resourceAttributes: list>, revisionCreateTime: string, revisionId: string, state: string, ttl: string, userId: string>
# operationId: healthcare.projects.locations.datasets.consentStores.consents.activate
export def "healthcare-projects-locations-datasets-consent-stores-consents-activate" [
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
  --consent-artifact: string # Required. The resource name of the Consent artifact that contains documentation of the user's consent, of the form `projects/{project_id}/locations/{location_id}/datasets/{dataset_id}/consentStores/{consent_store_id}/consentArtifacts/{consent_artifact_id}`. If the draft Consent had a Consent artifact, this Consent artifact overwrites it.
  --expire-time: string # Timestamp in UTC of when this Consent is considered expired. (format: google-datetime)
  --ttl: string # The time to live for this Consent from when it is marked as active. (format: google-duration)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{name}:activate"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: consentArtifact, var: consent_artifact}, {name: expireTime, var: expire_time}, {name: ttl, var: ttl}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, consent_artifact: $consent_artifact, expire_time: $expire_time, ttl: $ttl
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Archives the specified User data mapping.
#
# POST /v1beta1/{name}:archive
# Returns: record
# operationId: healthcare.projects.locations.datasets.consentStores.userDataMappings.archive
export def "healthcare-projects-locations-datasets-consent-stores-user-data-mappings-archive" [
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
    path: "/v1beta1/{name}:archive"
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

# Starts asynchronous cancellation on a long-running operation. The server makes a best effort to cancel the operation, but success is not guaranteed. If the server doesn't support this method, it returns `google.rpc.Code.UNIMPLEMENTED`. Clients can use Operations.GetOperation or other methods to check whether the cancellation succeeded or whether the operation completed despite cancellation. On successful cancellation, the operation is not deleted; instead, it becomes an operation with an Operation.error value with a google.rpc.Status.code of 1, corresponding to `Code.CANCELLED`.
#
# POST /v1beta1/{name}:cancel
# Returns: record
# operationId: healthcare.projects.locations.datasets.operations.cancel
export def "healthcare-projects-locations-datasets-operations-cancel" [
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
    path: "/v1beta1/{name}:cancel"
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

# Configure the search parameters for the FHIR store and reindex resources in the FHIR store according to the defined search parameters. The search parameters provided in this request will replace any previous search configuration. The target SearchParameter resources need to exist in the store before calling ConfigureSearch, otherwise an error will occur. This method returns an Operation that can be used to track the progress of the reindexing by calling GetOperation.
#
# POST /v1beta1/{name}:configureSearch
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: healthcare.projects.locations.datasets.fhirStores.configureSearch
export def "healthcare-projects-locations-datasets-fhir-stores-configure-search" [
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
  --canonical-urls: list<string> # The canonical URLs of the search parameters that are intended to be used for the FHIR store. See https://www.hl7.org/fhir/references.html#canonical for explanation on FHIR canonical urls
  --validate-only: oneof<nothing, bool> # If `validate_only` is set to true, the method will compile all the search parameters without actually setting the search config for the store and triggering the reindex.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{name}:configureSearch"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: canonicalUrls, var: canonical_urls}, {name: validateOnly, var: validate_only}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, canonical_urls: $canonical_urls, validate_only: $validate_only
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified revision of a Consent. An INVALID_ARGUMENT error occurs if the specified revision is the latest revision.
#
# DELETE /v1beta1/{name}:deleteRevision
# Returns: record
# operationId: healthcare.projects.locations.datasets.consentStores.consents.deleteRevision
export def "healthcare-projects-locations-datasets-consent-stores-consents-delete-revision" [
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
    path: "/v1beta1/{name}:deleteRevision"
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

# Evaluate an Annotation store against a ground truth Annotation store. When the operation finishes successfully, a detailed response is returned of type EvaluateAnnotationStoreResponse, contained in the response. The metadata field type is OperationMetadata. Errors are logged to Cloud Logging (see [Viewing error logs in Cloud Logging](https://cloud.google.com/healthcare/docs/how-tos/logging)).
#
# POST /v1beta1/{name}:evaluate
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: healthcare.projects.locations.datasets.annotationStores.evaluate
export def "healthcare-projects-locations-datasets-annotation-stores-evaluate" [
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
  --bigquery-destination: record # The BigQuery table for export. — shape: {force?: bool, schemaType?: "SCHEMA_TYPE_UNSPECIFIED"|"SIMPLE", tableUri?: string, writeDisposition?: "WRITE_DISPOSITION_UNSPECIFIED"|"WRITE_EMPTY"|"WRITE_TRUNCATE"|"WRITE_APPEND"}
  --eval-info-type-mapping: record # Optional. InfoType mapping for `eval_store`. Different resources can map to the same infoType. For example, `PERSON_NAME`, `PERSON`, `NAME`, and `HUMAN` are different. To map all of these into a single infoType (such as `PERSON_NAME`), specify the following mapping: ``` info_type_mapping["PERSON"] = "PERSON_NAME" info_type_mapping["NAME"] = "PERSON_NAME" info_type_mapping["HUMAN"] = "PERSON_NAME" ``` Unmentioned infoTypes, such as `DATE`, are treated as identity mapping. For example: ``` info_type_mapping["DATE"] = "DATE" ``` InfoTypes are case-insensitive.
  --golden-info-type-mapping: record # Optional. Similar to `eval_info_type_mapping`, infoType mapping for `golden_store`.
  --golden-store: string # The Annotation store to use as ground truth, in the format of `projects/{project_id}/locations/{location_id}/datasets/{dataset_id}/annotationStores/{annotation_store_id}`.
  --info-type-config: record # Specifies how to use infoTypes for evaluation. For example, a user might only want to evaluate `PERSON`, `LOCATION`, and `AGE`. — shape: {evaluateList?: record, ignoreList?: record, strictMatching?: bool}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{name}:evaluate"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: bigqueryDestination, var: bigquery_destination}, {name: evalInfoTypeMapping, var: eval_info_type_mapping}, {name: goldenInfoTypeMapping, var: golden_info_type_mapping}, {name: goldenStore, var: golden_store}, {name: infoTypeConfig, var: info_type_config}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, bigquery_destination: $bigquery_destination, eval_info_type_mapping: $eval_info_type_mapping, golden_info_type_mapping: $golden_info_type_mapping, golden_store: $golden_store, info_type_config: $info_type_config
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Exports the messages to a destination. To filter messages to be exported, define a filter using the start and end time, relative to the message generation time (MSH.7). This API returns an Operation that can be used to track the status of the job by calling GetOperation. Immediate fatal errors appear in the error field. Otherwise, when the operation finishes, a detailed response of type ExportMessagesResponse is returned in the response field. The metadata field type for this operation is OperationMetadata.
#
# POST /v1beta1/{name}:export
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: healthcare.projects.locations.datasets.hl7V2Stores.export
export def "healthcare-projects-locations-datasets-hl7-v2-stores-export" [
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
  --end-time: string # The end of the range in `send_time` (MSH.7, https://www.hl7.org/documentcenter/public_temp_2E58C1F9-1C23-BA17-0C6126475344DA9D/wg/conf/HL7MSH.htm) to process. If not specified, the time when the export is scheduled is used. This value has to come after the `start_time` defined below. Only messages whose `send_time` lies in the range `start_time` (inclusive) to `end_time` (exclusive) are exported. (format: google-datetime)
  --gcs-destination: record # The Cloud Storage output destination. The Cloud Healthcare Service Agent requires the `roles/storage.objectAdmin` Cloud IAM roles on the Cloud Storage location. — shape: {contentStructure?: "CONTENT_STRUCTURE_UNSPECIFIED"|"MESSAGE_JSON", messageView?: "MESSAGE_VIEW_UNSPECIFIED"|"RAW_ONLY"|"PARSED_ONLY"|"FULL"|"SCHEMATIZED_ONLY"|"BASIC", uriPrefix?: string}
  --start-time: string # The start of the range in `send_time` (MSH.7, https://www.hl7.org/documentcenter/public_temp_2E58C1F9-1C23-BA17-0C6126475344DA9D/wg/conf/HL7MSH.htm) to process. If not specified, the UNIX epoch (1970-01-01T00:00:00Z) is used. This value has to come before the `end_time` defined below. Only messages whose `send_time` lies in the range `start_time` (inclusive) to `end_time` (exclusive) are exported. (format: google-datetime)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{name}:export"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: endTime, var: end_time}, {name: gcsDestination, var: gcs_destination}, {name: startTime, var: start_time}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, end_time: $end_time, gcs_destination: $gcs_destination, start_time: $start_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets metrics associated with the FHIR store.
#
# GET /v1beta1/{name}:getFHIRStoreMetrics
# Returns: record<metrics: table<count: string, resourceType: string, structuredStorageSizeBytes: string>, name: string>
# operationId: healthcare.projects.locations.datasets.fhirStores.getFHIRStoreMetrics
export def "healthcare-projects-locations-datasets-fhir-stores-get-fhir-store-metrics" [
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
    path: "/v1beta1/{name}:getFHIRStoreMetrics"
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

# Import messages to the HL7v2 store by loading data from the specified sources. This method is optimized to load large quantities of data using import semantics that ignore some HL7v2 store configuration options and are not suitable for all use cases. It is primarily intended to load data into an empty HL7v2 store that is not being used by other clients. An existing message will be overwritten if a duplicate message is imported. A duplicate message is a message with the same raw bytes as a message that already exists in this HL7v2 store. When a message is overwritten, its labels will also be overwritten. The import operation is idempotent unless the input data contains multiple valid messages with the same raw bytes but different labels. In that case, after the import completes, the store contains exactly one message with those raw bytes but there is no ordering guarantee on which version of the labels it has. The operation result counters do not count duplicated raw bytes as an error and count one success for each message in the input, which might result in a success count larger than the number of messages in the HL7v2 store. If some messages fail to import, for example due to parsing errors, successfully imported messages are not rolled back. This method returns an Operation that can be used to track the status of the import by calling GetOperation. Immediate fatal errors appear in the error field, errors are also logged to Cloud Logging (see [Viewing error logs in Cloud Logging](https://cloud.google.com/healthcare/docs/how-tos/logging)). Otherwise, when the operation finishes, a response of type ImportMessagesResponse is returned in the response field. The metadata field type for this operation is OperationMetadata.
#
# POST /v1beta1/{name}:import
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: healthcare.projects.locations.datasets.hl7V2Stores.import
export def "healthcare-projects-locations-datasets-hl7-v2-stores-import" [
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
  --gcs-source: record # Specifies the configuration for importing data from Cloud Storage. — shape: {uri?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{name}:import"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: gcsSource, var: gcs_source}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, gcs_source: $gcs_source
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the revisions of the specified Consent in reverse chronological order.
#
# GET /v1beta1/{name}:listRevisions
# Returns: record<consents: table<consentArtifact: string, expireTime: string, metadata: record, name: string, policies: list, revisionCreateTime: string, revisionId: string, state: string, ttl: string, userId: string>, nextPageToken: string>
# operationId: healthcare.projects.locations.datasets.consentStores.consents.listRevisions
export def "healthcare-projects-locations-datasets-consent-stores-consents-list-revisions" [
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
  --filter: string # Optional. Restricts the revisions returned to those matching a filter. The following syntax is available: * A string field value can be written as text inside quotation marks, for example `"query text"`. The only valid relational operation for text fields is equality (`=`), where text is searched within the field, rather than having the field be equal to the text. For example, `"Comment = great"` returns messages with `great` in the comment field. * A number field value can be written as an integer, a decimal, or an exponential. The valid relational operators for number fields are the equality operator (`=`), along with the less than/greater than operators (`<`, `<=`, `>`, `>=`). Note that there is no inequality (`!=`) operator. You can prepend the `NOT` operator to an expression to negate it. * A date field value must be written in `yyyy-mm-dd` form. Fields with date and time use the RFC3339 time format. Leading zeros are required for one-digit months and days. The valid relational operators for date fields are the equality operator (`=`) , along with the less than/greater than operators (`<`, `<=`, `>`, `>=`). Note that there is no inequality (`!=`) operator. You can prepend the `NOT` operator to an expression to negate it. * Multiple field query expressions can be combined in one query by adding `AND` or `OR` operators between the expressions. If a boolean operator appears within a quoted string, it is not treated as special, it's just another part of the character string to be matched. You can prepend the `NOT` operator to an expression to negate it. Fields/functions available for filtering are: - user_id. For example, `filter='user_id="user123"'`. - consent_artifact - state - revision_create_time - metadata. For example, `filter=Metadata(\"testkey\")=\"value\"` or `filter=HasMetadata(\"testkey\")`.
  --page-size: int # Optional. Limit on the number of revisions to return in a single response. If not specified, 100 is used. May not be larger than 1000.
  --page-token: string # Optional. Token to retrieve the next page of results or empty if there are no more results in the list.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta1/{name}:listRevisions"
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

# Rejects the latest revision of the specified Consent by committing a new revision with `state` updated to `REJECTED`. If the latest revision of the specified Consent is in the `REJECTED` state, no new revision is committed. A FAILED_PRECONDITION error occurs if the latest revision of the specified Consent is in the `ACTIVE` or `REVOKED` state.
#
# POST /v1beta1/{name}:reject
# Returns: record<consentArtifact: string, expireTime: string, metadata: record, name: string, policies: table<authorizationRule: record, resourceAttributes: list>, revisionCreateTime: string, revisionId: string, state: string, ttl: string, userId: string>
# operationId: healthcare.projects.locations.datasets.consentStores.consents.reject
export def "healthcare-projects-locations-datasets-consent-stores-consents-reject" [
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
  --consent-artifact: string # Optional. The resource name of the Consent artifact that contains documentation of the user's rejection of the draft Consent, of the form `projects/{project_id}/locations/{location_id}/datasets/{dataset_id}/consentStores/{consent_store_id}/consentArtifacts/{consent_artifact_id}`. If the draft Consent had a Consent artifact, this Consent artifact overwrites it.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{name}:reject"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: consentArtifact, var: consent_artifact}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, consent_artifact: $consent_artifact
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Revokes the latest revision of the specified Consent by committing a new revision with `state` updated to `REVOKED`. If the latest revision of the specified Consent is in the `REVOKED` state, no new revision is committed. A FAILED_PRECONDITION error occurs if the latest revision of the given consent is in `DRAFT` or `REJECTED` state.
#
# POST /v1beta1/{name}:revoke
# Returns: record<consentArtifact: string, expireTime: string, metadata: record, name: string, policies: table<authorizationRule: record, resourceAttributes: list>, revisionCreateTime: string, revisionId: string, state: string, ttl: string, userId: string>
# operationId: healthcare.projects.locations.datasets.consentStores.consents.revoke
export def "healthcare-projects-locations-datasets-consent-stores-consents-revoke" [
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
  --consent-artifact: string # Optional. The resource name of the Consent artifact that contains proof of the user's revocation of the Consent, of the form `projects/{project_id}/locations/{location_id}/datasets/{dataset_id}/consentStores/{consent_store_id}/consentArtifacts/{consent_artifact_id}`.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{name}:revoke"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: consentArtifact, var: consent_artifact}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, consent_artifact: $consent_artifact
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Analyze heathcare entity in a document. Its response includes the recognized entity mentions and the relationships between them. AnalyzeEntities uses context aware models to detect entities. This method can only analyze documents written in English.
#
# POST /v1beta1/{nlpService}:analyzeEntities
# Returns: record<entities: table<entityId: string, preferredTerm: string, vocabularyCodes: list>, entityMentions: table<certaintyAssessment: record, confidence: float, linkedEntities: list, mentionId: string, subject: record, temporalAssessment: record, text: record, type: string>, relationships: table<confidence: float, objectId: string, subjectId: string>>
# operationId: healthcare.projects.locations.services.nlp.analyzeEntities
export def "healthcare-projects-locations-services-nlp-analyze-entities" [
  nlp_service: string
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
  --document-content: string # document_content is a document to be annotated.
  --licensed-vocabularies: list<string> # A list of licensed vocabularies to use in the request, in addition to the default unlicensed vocabularies.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{nlpService}:analyzeEntities"
    path_params: [{name: nlpService, var: nlp_service}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: documentContent, var: document_content}, {name: licensedVocabularies, var: licensed_vocabularies}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    nlp_service: $nlp_service, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, document_content: $document_content, licensed_vocabularies: $licensed_vocabularies
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the Annotation stores in the given dataset for a source store.
#
# GET /v1beta1/{parent}/annotationStores
# Returns: record<annotationStores: table<labels: record, name: string>, nextPageToken: string>
# operationId: healthcare.projects.locations.datasets.annotationStores.list
export def "healthcare-projects-locations-datasets-annotation-stores-list" [
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
  --filter: string # Restricts stores returned to those matching a filter. The following syntax is available: * A string field value can be written as text inside quotation marks, for example `"query text"`. The only valid relational operation for text fields is equality (`=`), where text is searched within the field, rather than having the field be equal to the text. For example, `"Comment = great"` returns messages with `great` in the comment field. * A number field value can be written as an integer, a decimal, or an exponential. The valid relational operators for number fields are the equality operator (`=`), along with the less than/greater than operators (`<`, `<=`, `>`, `>=`). Note that there is no inequality (`!=`) operator. You can prepend the `NOT` operator to an expression to negate it. * A date field value must be written in `yyyy-mm-dd` form. Fields with date and time use the RFC3339 time format. Leading zeros are required for one-digit months and days. The valid relational operators for date fields are the equality operator (`=`) , along with the less than/greater than operators (`<`, `<=`, `>`, `>=`). Note that there is no inequality (`!=`) operator. You can prepend the `NOT` operator to an expression to negate it. * Multiple field query expressions can be combined in one query by adding `AND` or `OR` operators between the expressions. If a boolean operator appears within a quoted string, it is not treated as special, it's just another part of the character string to be matched. You can prepend the `NOT` operator to an expression to negate it. Only filtering on labels is supported, for example `labels.key=value`.
  --page-size: int # Limit on the number of Annotation stores to return in a single response. If not specified, 100 is used. May not be larger than 1000.
  --page-token: string # The next_page_token value returned from the previous List request, if any.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta1/{parent}/annotationStores"
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

# Creates a new Annotation store within the parent dataset.
#
# POST /v1beta1/{parent}/annotationStores
# Returns: record<labels: record, name: string>
# operationId: healthcare.projects.locations.datasets.annotationStores.create
export def "healthcare-projects-locations-datasets-annotation-stores-create" [
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
  --annotation-store-id: string # The ID of the Annotation store that is being created. The string must match the following regex: `[\p{L}\p{N}_\-\.]{1,256}`.
  --labels: record # Optional. User-supplied key-value pairs used to organize Annotation stores. Label keys must be between 1 and 63 characters long, have a UTF-8 encoding of maximum 128 bytes, and must conform to the following PCRE regular expression: \p{Ll}\p{Lo}{0,62} Label values must be between 1 and 63 characters long, have a UTF-8 encoding of maximum 128 bytes, and must conform to the following PCRE regular expression: [\p{Ll}\p{Lo}\p{N}_-]{0,63} No more than 64 labels can be associated with a given store.
  --name: string # Resource name of the Annotation store, of the form `projects/{project_id}/locations/{location_id}/datasets/{dataset_id}/annotationStores/{annotation_store_id}`.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{parent}/annotationStores"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: annotationStoreId, var: annotation_store_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: labels, var: labels}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, annotation_store_id: $annotation_store_id, labels: $labels, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the Annotations in the given Annotation store for a source resource.
#
# GET /v1beta1/{parent}/annotations
# Returns: record<annotations: table<annotationSource: record, customData: record, imageAnnotation: record, name: string, resourceAnnotation: record, textAnnotation: record>, nextPageToken: string>
# operationId: healthcare.projects.locations.datasets.annotationStores.annotations.list
export def "healthcare-projects-locations-datasets-annotation-stores-annotations-list" [
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
  --filter: string # Restricts Annotations returned to those matching a filter. Functions available for filtering are: - `matches("annotation_source.cloud_healthcare_source.name", substring)`. Filter on `cloud_healthcare_source.name`. For example: `matches("annotation_source.cloud_healthcare_source.name", "some source")`. - `matches("annotation", substring)`. Filter on all fields of annotation. For example: `matches("annotation", "some-content")`. - `type("text")`, `type("image")`, `type("resource")`. Filter on the type of annotation `data`.
  --page-size: int # Limit on the number of Annotations to return in a single response. If not specified, 100 is used. May not be larger than 1000.
  --page-token: string # The next_page_token value returned from the previous List request, if any.
  --view: string@view-completer-1 # Controls which fields are populated in the response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta1/{parent}/annotations"
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

# Creates a new Annotation record. It is valid to create Annotation objects for the same source more than once since a unique ID is assigned to each record by this service.
#
# POST /v1beta1/{parent}/annotations
# Returns: record<annotationSource: record<cloudHealthcareSource: record<name: string>>, customData: record, imageAnnotation: record<boundingPolys: list<record>, frameIndex: int>, name: string, resourceAnnotation: record<label: string>, textAnnotation: record<details: record>>
# operationId: healthcare.projects.locations.datasets.annotationStores.annotations.create
export def "healthcare-projects-locations-datasets-annotation-stores-annotations-create" [
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
  --annotation-source: record # AnnotationSource holds the source information of the annotation. — shape: {cloudHealthcareSource?: record}
  --custom-data: record # Additional information for this annotation record, such as annotator and verifier information or study campaign.
  --image-annotation: record # Image annotation. — shape: {boundingPolys?: list, frameIndex?: int}
  --name: string # Resource name of the Annotation, of the form `projects/{project_id}/locations/{location_id}/datasets/{dataset_id}/annotationStores/{annotation_store_id}/annotations/{annotation_id}`.
  --resource-annotation: record # Resource level annotation. — shape: {label?: string}
  --text-annotation: record # A TextAnnotation specifies a text range that includes sensitive information. — shape: {details?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{parent}/annotations"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: annotationSource, var: annotation_source}, {name: customData, var: custom_data}, {name: imageAnnotation, var: image_annotation}, {name: name, var: name}, {name: resourceAnnotation, var: resource_annotation}, {name: textAnnotation, var: text_annotation}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, annotation_source: $annotation_source, custom_data: $custom_data, image_annotation: $image_annotation, name: $name, resource_annotation: $resource_annotation, text_annotation: $text_annotation
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the Attribute definitions in the specified consent store.
#
# GET /v1beta1/{parent}/attributeDefinitions
# Returns: record<attributeDefinitions: table<allowedValues: list, category: string, consentDefaultValues: list, dataMappingDefaultValue: string, description: string, name: string>, nextPageToken: string>
# operationId: healthcare.projects.locations.datasets.consentStores.attributeDefinitions.list
export def "healthcare-projects-locations-datasets-consent-stores-attribute-definitions-list" [
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
  --filter: string # Optional. Restricts the attributes returned to those matching a filter. The following syntax is available: * A string field value can be written as text inside quotation marks, for example `"query text"`. The only valid relational operation for text fields is equality (`=`), where text is searched within the field, rather than having the field be equal to the text. For example, `"Comment = great"` returns messages with `great` in the comment field. * A number field value can be written as an integer, a decimal, or an exponential. The valid relational operators for number fields are the equality operator (`=`), along with the less than/greater than operators (`<`, `<=`, `>`, `>=`). Note that there is no inequality (`!=`) operator. You can prepend the `NOT` operator to an expression to negate it. * A date field value must be written in `yyyy-mm-dd` form. Fields with date and time use the RFC3339 time format. Leading zeros are required for one-digit months and days. The valid relational operators for date fields are the equality operator (`=`) , along with the less than/greater than operators (`<`, `<=`, `>`, `>=`). Note that there is no inequality (`!=`) operator. You can prepend the `NOT` operator to an expression to negate it. * Multiple field query expressions can be combined in one query by adding `AND` or `OR` operators between the expressions. If a boolean operator appears within a quoted string, it is not treated as special, it's just another part of the character string to be matched. You can prepend the `NOT` operator to an expression to negate it. The only field available for filtering is `category`. For example, `filter=category=\"REQUEST\"`.
  --page-size: int # Optional. Limit on the number of Attribute definitions to return in a single response. If not specified, 100 is used. May not be larger than 1000.
  --page-token: string # Optional. Token to retrieve the next page of results or empty to get the first page.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta1/{parent}/attributeDefinitions"
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

# Creates a new Attribute definition in the parent consent store.
#
# POST /v1beta1/{parent}/attributeDefinitions
# Returns: record<allowedValues: list<string>, category: string, consentDefaultValues: list<string>, dataMappingDefaultValue: string, description: string, name: string>
# operationId: healthcare.projects.locations.datasets.consentStores.attributeDefinitions.create
export def "healthcare-projects-locations-datasets-consent-stores-attribute-definitions-create" [
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
  --attribute-definition-id: string # Required. The ID of the Attribute definition to create. The string must match the following regex: `_a-zA-Z{0,255}` and must not be a reserved keyword within the Common Expression Language as listed on https://github.com/google/cel-spec/blob/master/doc/langdef.md.
  --allowed-values: list<string> # Required. Possible values for the attribute. The number of allowed values must not exceed 500. An empty list is invalid. The list can only be expanded after creation.
  --category: string@category-completer # Required. The category of the attribute. The value of this field cannot be changed after creation.
  --consent-default-values: list<string> # Optional. Default values of the attribute in Consents. If no default values are specified, it defaults to an empty value.
  --data-mapping-default-value: string # Optional. Default value of the attribute in User data mappings. If no default value is specified, it defaults to an empty value. This field is only applicable to attributes of the category `RESOURCE`.
  --description: string # Optional. A description of the attribute.
  --name: string # Resource name of the Attribute definition, of the form `projects/{project_id}/locations/{location_id}/datasets/{dataset_id}/consentStores/{consent_store_id}/attributeDefinitions/{attribute_definition_id}`. Cannot be changed after creation.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{parent}/attributeDefinitions"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: attributeDefinitionId, var: attribute_definition_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: allowedValues, var: allowed_values}, {name: category, var: category}, {name: consentDefaultValues, var: consent_default_values}, {name: dataMappingDefaultValue, var: data_mapping_default_value}, {name: description, var: description}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, attribute_definition_id: $attribute_definition_id, allowed_values: $allowed_values, category: $category, consent_default_values: $consent_default_values, data_mapping_default_value: $data_mapping_default_value, description: $description, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the Consent artifacts in the specified consent store.
#
# GET /v1beta1/{parent}/consentArtifacts
# Returns: record<consentArtifacts: table<consentContentScreenshots: list, consentContentVersion: string, guardianSignature: record, metadata: record, name: string, userId: string, userSignature: record, witnessSignature: record>, nextPageToken: string>
# operationId: healthcare.projects.locations.datasets.consentStores.consentArtifacts.list
export def "healthcare-projects-locations-datasets-consent-stores-consent-artifacts-list" [
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
  --filter: string # Optional. Restricts the artifacts returned to those matching a filter. The following syntax is available: * A string field value can be written as text inside quotation marks, for example `"query text"`. The only valid relational operation for text fields is equality (`=`), where text is searched within the field, rather than having the field be equal to the text. For example, `"Comment = great"` returns messages with `great` in the comment field. * A number field value can be written as an integer, a decimal, or an exponential. The valid relational operators for number fields are the equality operator (`=`), along with the less than/greater than operators (`<`, `<=`, `>`, `>=`). Note that there is no inequality (`!=`) operator. You can prepend the `NOT` operator to an expression to negate it. * A date field value must be written in `yyyy-mm-dd` form. Fields with date and time use the RFC3339 time format. Leading zeros are required for one-digit months and days. The valid relational operators for date fields are the equality operator (`=`) , along with the less than/greater than operators (`<`, `<=`, `>`, `>=`). Note that there is no inequality (`!=`) operator. You can prepend the `NOT` operator to an expression to negate it. * Multiple field query expressions can be combined in one query by adding `AND` or `OR` operators between the expressions. If a boolean operator appears within a quoted string, it is not treated as special, it's just another part of the character string to be matched. You can prepend the `NOT` operator to an expression to negate it. The fields available for filtering are: - user_id. For example, `filter=user_id=\"user123\"`. - consent_content_version - metadata. For example, `filter=Metadata(\"testkey\")=\"value\"` or `filter=HasMetadata(\"testkey\")`.
  --page-size: int # Optional. Limit on the number of consent artifacts to return in a single response. If not specified, 100 is used. May not be larger than 1000.
  --page-token: string # Optional. The next_page_token value returned from the previous List request, if any.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta1/{parent}/consentArtifacts"
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

# Creates a new Consent artifact in the parent consent store.
#
# POST /v1beta1/{parent}/consentArtifacts
# Returns: record<consentContentScreenshots: table<gcsUri: string, rawBytes: string>, consentContentVersion: string, guardianSignature: record<image: record<gcsUri: string, rawBytes: string>, metadata: record, signatureTime: string, userId: string>, metadata: record, name: string, userId: string, userSignature: record<image: record<gcsUri: string, rawBytes: string>, metadata: record, signatureTime: string, userId: string>, witnessSignature: record<image: record<gcsUri: string, rawBytes: string>, metadata: record, signatureTime: string, userId: string>>
# operationId: healthcare.projects.locations.datasets.consentStores.consentArtifacts.create
export def "healthcare-projects-locations-datasets-consent-stores-consent-artifacts-create" [
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
  --consent-content-screenshots: list # Optional. Screenshots, PDFs, or other binary information documenting the user's consent. — item shape: {gcsUri?: string, rawBytes?: string}
  --consent-content-version: string # Optional. An string indicating the version of the consent information shown to the user.
  --guardian-signature: record # User signature. — shape: {image?: record, metadata?: record, signatureTime?: string, userId?: string}
  --metadata: record # Optional. Metadata associated with the Consent artifact. For example, the consent locale or user agent version.
  --name: string # Resource name of the Consent artifact, of the form `projects/{project_id}/locations/{location_id}/datasets/{dataset_id}/consentStores/{consent_store_id}/consentArtifacts/{consent_artifact_id}`. Cannot be changed after creation.
  --user-id: string # Required. User's UUID provided by the client.
  --user-signature: record # User signature. — shape: {image?: record, metadata?: record, signatureTime?: string, userId?: string}
  --witness-signature: record # User signature. — shape: {image?: record, metadata?: record, signatureTime?: string, userId?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{parent}/consentArtifacts"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: consentContentScreenshots, var: consent_content_screenshots}, {name: consentContentVersion, var: consent_content_version}, {name: guardianSignature, var: guardian_signature}, {name: metadata, var: metadata}, {name: name, var: name}, {name: userId, var: user_id}, {name: userSignature, var: user_signature}, {name: witnessSignature, var: witness_signature}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, consent_content_screenshots: $consent_content_screenshots, consent_content_version: $consent_content_version, guardian_signature: $guardian_signature, metadata: $metadata, name: $name, user_id: $user_id, user_signature: $user_signature, witness_signature: $witness_signature
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the consent stores in the specified dataset.
#
# GET /v1beta1/{parent}/consentStores
# Returns: record<consentStores: table<defaultConsentTtl: string, enableConsentCreateOnUpdate: bool, labels: record, name: string>, nextPageToken: string>
# operationId: healthcare.projects.locations.datasets.consentStores.list
export def "healthcare-projects-locations-datasets-consent-stores-list" [
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
  --filter: string # Optional. Restricts the stores returned to those matching a filter. The following syntax is available: * A string field value can be written as text inside quotation marks, for example `"query text"`. The only valid relational operation for text fields is equality (`=`), where text is searched within the field, rather than having the field be equal to the text. For example, `"Comment = great"` returns messages with `great` in the comment field. * A number field value can be written as an integer, a decimal, or an exponential. The valid relational operators for number fields are the equality operator (`=`), along with the less than/greater than operators (`<`, `<=`, `>`, `>=`). Note that there is no inequality (`!=`) operator. You can prepend the `NOT` operator to an expression to negate it. * A date field value must be written in `yyyy-mm-dd` form. Fields with date and time use the RFC3339 time format. Leading zeros are required for one-digit months and days. The valid relational operators for date fields are the equality operator (`=`) , along with the less than/greater than operators (`<`, `<=`, `>`, `>=`). Note that there is no inequality (`!=`) operator. You can prepend the `NOT` operator to an expression to negate it. * Multiple field query expressions can be combined in one query by adding `AND` or `OR` operators between the expressions. If a boolean operator appears within a quoted string, it is not treated as special, it's just another part of the character string to be matched. You can prepend the `NOT` operator to an expression to negate it. Only filtering on labels is supported. For example, `filter=labels.key=value`.
  --page-size: int # Optional. Limit on the number of consent stores to return in a single response. If not specified, 100 is used. May not be larger than 1000.
  --page-token: string # Optional. Token to retrieve the next page of results, or empty to get the first page.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta1/{parent}/consentStores"
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

# Creates a new consent store in the parent dataset. Attempting to create a consent store with the same ID as an existing store fails with an ALREADY_EXISTS error.
#
# POST /v1beta1/{parent}/consentStores
# Returns: record<defaultConsentTtl: string, enableConsentCreateOnUpdate: bool, labels: record, name: string>
# operationId: healthcare.projects.locations.datasets.consentStores.create
export def "healthcare-projects-locations-datasets-consent-stores-create" [
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
  --consent-store-id: string # Required. The ID of the consent store to create. The string must match the following regex: `[\p{L}\p{N}_\-\.]{1,256}`. Cannot be changed after creation.
  --default-consent-ttl: string # Optional. Default time to live for Consents created in this store. Must be at least 24 hours. Updating this field will not affect the expiration time of existing consents. (format: google-duration)
  --enable-consent-create-on-update: oneof<nothing, bool> # Optional. If `true`, UpdateConsent creates the Consent if it does not already exist. If unspecified, defaults to `false`.
  --labels: record # Optional. User-supplied key-value pairs used to organize consent stores. Label keys must be between 1 and 63 characters long, have a UTF-8 encoding of maximum 128 bytes, and must conform to the following PCRE regular expression: \p{Ll}\p{Lo}{0,62}. Label values must be between 1 and 63 characters long, have a UTF-8 encoding of maximum 128 bytes, and must conform to the following PCRE regular expression: [\p{Ll}\p{Lo}\p{N}_-]{0,63}. No more than 64 labels can be associated with a given store. For more information: https://cloud.google.com/healthcare/docs/how-tos/labeling-resources
  --name: string # Resource name of the consent store, of the form `projects/{project_id}/locations/{location_id}/datasets/{dataset_id}/consentStores/{consent_store_id}`. Cannot be changed after creation.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{parent}/consentStores"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: consentStoreId, var: consent_store_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: defaultConsentTtl, var: default_consent_ttl}, {name: enableConsentCreateOnUpdate, var: enable_consent_create_on_update}, {name: labels, var: labels}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, consent_store_id: $consent_store_id, default_consent_ttl: $default_consent_ttl, enable_consent_create_on_update: $enable_consent_create_on_update, labels: $labels, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the Consent in the given consent store, returning each Consent's latest revision.
#
# GET /v1beta1/{parent}/consents
# Returns: record<consents: table<consentArtifact: string, expireTime: string, metadata: record, name: string, policies: list, revisionCreateTime: string, revisionId: string, state: string, ttl: string, userId: string>, nextPageToken: string>
# operationId: healthcare.projects.locations.datasets.consentStores.consents.list
export def "healthcare-projects-locations-datasets-consent-stores-consents-list" [
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
  --filter: string # Optional. Restricts the consents returned to those matching a filter. The following syntax is available: * A string field value can be written as text inside quotation marks, for example `"query text"`. The only valid relational operation for text fields is equality (`=`), where text is searched within the field, rather than having the field be equal to the text. For example, `"Comment = great"` returns messages with `great` in the comment field. * A number field value can be written as an integer, a decimal, or an exponential. The valid relational operators for number fields are the equality operator (`=`), along with the less than/greater than operators (`<`, `<=`, `>`, `>=`). Note that there is no inequality (`!=`) operator. You can prepend the `NOT` operator to an expression to negate it. * A date field value must be written in `yyyy-mm-dd` form. Fields with date and time use the RFC3339 time format. Leading zeros are required for one-digit months and days. The valid relational operators for date fields are the equality operator (`=`) , along with the less than/greater than operators (`<`, `<=`, `>`, `>=`). Note that there is no inequality (`!=`) operator. You can prepend the `NOT` operator to an expression to negate it. * Multiple field query expressions can be combined in one query by adding `AND` or `OR` operators between the expressions. If a boolean operator appears within a quoted string, it is not treated as special, it's just another part of the character string to be matched. You can prepend the `NOT` operator to an expression to negate it. The fields available for filtering are: - user_id. For example, `filter='user_id="user123"'`. - consent_artifact - state - revision_create_time - metadata. For example, `filter=Metadata(\"testkey\")=\"value\"` or `filter=HasMetadata(\"testkey\")`.
  --page-size: int # Optional. Limit on the number of Consents to return in a single response. If not specified, 100 is used. May not be larger than 1000.
  --page-token: string # Optional. The next_page_token value returned from the previous List request, if any.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta1/{parent}/consents"
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

# Creates a new Consent in the parent consent store.
#
# POST /v1beta1/{parent}/consents
# Returns: record<consentArtifact: string, expireTime: string, metadata: record, name: string, policies: table<authorizationRule: record, resourceAttributes: list>, revisionCreateTime: string, revisionId: string, state: string, ttl: string, userId: string>
# operationId: healthcare.projects.locations.datasets.consentStores.consents.create
export def "healthcare-projects-locations-datasets-consent-stores-consents-create" [
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
  --consent-artifact: string # Required. The resource name of the Consent artifact that contains proof of the end user's consent, of the form `projects/{project_id}/locations/{location_id}/datasets/{dataset_id}/consentStores/{consent_store_id}/consentArtifacts/{consent_artifact_id}`.
  --expire-time: string # Timestamp in UTC of when this Consent is considered expired. (format: google-datetime)
  --metadata: record # Optional. User-supplied key-value pairs used to organize Consent resources. Metadata keys must: - be between 1 and 63 characters long - have a UTF-8 encoding of maximum 128 bytes - begin with a letter - consist of up to 63 characters including lowercase letters, numeric characters, underscores, and dashes Metadata values must be: - be between 1 and 63 characters long - have a UTF-8 encoding of maximum 128 bytes - consist of up to 63 characters including lowercase letters, numeric characters, underscores, and dashes No more than 64 metadata entries can be associated with a given consent.
  --name: string # Resource name of the Consent, of the form `projects/{project_id}/locations/{location_id}/datasets/{dataset_id}/consentStores/{consent_store_id}/consents/{consent_id}`. Cannot be changed after creation.
  --policies: list # Optional. Represents a user's consent in terms of the resources that can be accessed and under what conditions. — item shape: {authorizationRule?: record, resourceAttributes?: list}
  --state: string@state-completer # Required. Indicates the current state of this Consent.
  --ttl: string # Input only. The time to live for this Consent from when it is created. (format: google-duration)
  --user-id: string # Required. User's UUID provided by the client.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{parent}/consents"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: consentArtifact, var: consent_artifact}, {name: expireTime, var: expire_time}, {name: metadata, var: metadata}, {name: name, var: name}, {name: policies, var: policies}, {name: state, var: state}, {name: ttl, var: ttl}, {name: userId, var: user_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, consent_artifact: $consent_artifact, expire_time: $expire_time, metadata: $metadata, name: $name, policies: $policies, state: $state, ttl: $ttl, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the health datasets in the current project.
#
# GET /v1beta1/{parent}/datasets
# Returns: record<datasets: table<name: string, timeZone: string>, nextPageToken: string>
# operationId: healthcare.projects.locations.datasets.list
export def "healthcare-projects-locations-datasets-list" [
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
  --page-size: int # The maximum number of items to return. If not specified, 100 is used. May not be larger than 1000.
  --page-token: string # The next_page_token value returned from a previous List request, if any.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta1/{parent}/datasets"
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

# Creates a new health dataset. Results are returned through the Operation interface which returns either an `Operation.response` which contains a Dataset or `Operation.error`. The metadata field type is OperationMetadata.
#
# POST /v1beta1/{parent}/datasets
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: healthcare.projects.locations.datasets.create
export def "healthcare-projects-locations-datasets-create" [
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
  --dataset-id: string # The ID of the dataset that is being created. The string must match the following regex: `[\p{L}\p{N}_\-\.]{1,256}`.
  --name: string # Resource name of the dataset, of the form `projects/{project_id}/locations/{location_id}/datasets/{dataset_id}`.
  --time-zone: string # The default timezone used by this dataset. Must be a either a valid IANA time zone name such as "America/New_York" or empty, which defaults to UTC. This is used for parsing times in resources, such as HL7 messages, where no explicit timezone is specified.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{parent}/datasets"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: datasetId, var: dataset_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: timeZone, var: time_zone}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, dataset_id: $dataset_id, name: $name, time_zone: $time_zone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the DICOM stores in the given dataset.
#
# GET /v1beta1/{parent}/dicomStores
# Returns: record<dicomStores: table<labels: record, name: string, notificationConfig: record, streamConfigs: list>, nextPageToken: string>
# operationId: healthcare.projects.locations.datasets.dicomStores.list
export def "healthcare-projects-locations-datasets-dicom-stores-list" [
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
  --filter: string # Restricts stores returned to those matching a filter. The following syntax is available: * A string field value can be written as text inside quotation marks, for example `"query text"`. The only valid relational operation for text fields is equality (`=`), where text is searched within the field, rather than having the field be equal to the text. For example, `"Comment = great"` returns messages with `great` in the comment field. * A number field value can be written as an integer, a decimal, or an exponential. The valid relational operators for number fields are the equality operator (`=`), along with the less than/greater than operators (`<`, `<=`, `>`, `>=`). Note that there is no inequality (`!=`) operator. You can prepend the `NOT` operator to an expression to negate it. * A date field value must be written in `yyyy-mm-dd` form. Fields with date and time use the RFC3339 time format. Leading zeros are required for one-digit months and days. The valid relational operators for date fields are the equality operator (`=`) , along with the less than/greater than operators (`<`, `<=`, `>`, `>=`). Note that there is no inequality (`!=`) operator. You can prepend the `NOT` operator to an expression to negate it. * Multiple field query expressions can be combined in one query by adding `AND` or `OR` operators between the expressions. If a boolean operator appears within a quoted string, it is not treated as special, it's just another part of the character string to be matched. You can prepend the `NOT` operator to an expression to negate it. Only filtering on labels is supported. For example, `labels.key=value`.
  --page-size: int # Limit on the number of DICOM stores to return in a single response. If not specified, 100 is used. May not be larger than 1000.
  --page-token: string # The next_page_token value returned from the previous List request, if any.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta1/{parent}/dicomStores"
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

# Creates a new DICOM store within the parent dataset.
#
# POST /v1beta1/{parent}/dicomStores
# Returns: record<labels: record, name: string, notificationConfig: record<pubsubTopic: string, sendForBulkImport: bool>, streamConfigs: table<bigqueryDestination: record>>
# operationId: healthcare.projects.locations.datasets.dicomStores.create
export def "healthcare-projects-locations-datasets-dicom-stores-create" [
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
  --dicom-store-id: string # The ID of the DICOM store that is being created. Any string value up to 256 characters in length.
  --labels: record # User-supplied key-value pairs used to organize DICOM stores. Label keys must be between 1 and 63 characters long, have a UTF-8 encoding of maximum 128 bytes, and must conform to the following PCRE regular expression: \p{Ll}\p{Lo}{0,62} Label values are optional, must be between 1 and 63 characters long, have a UTF-8 encoding of maximum 128 bytes, and must conform to the following PCRE regular expression: [\p{Ll}\p{Lo}\p{N}_-]{0,63} No more than 64 labels can be associated with a given store.
  --name: string # Resource name of the DICOM store, of the form `projects/{project_id}/locations/{location_id}/datasets/{dataset_id}/dicomStores/{dicom_store_id}`.
  --notification-config: record # Specifies where to send notifications upon changes to a data store. — shape: {pubsubTopic?: string, sendForBulkImport?: bool}
  --stream-configs: list # A list of streaming configs used to configure the destination of streaming exports for every DICOM instance insertion in this DICOM store. After a new config is added to `stream_configs`, DICOM instance insertions are streamed to the new destination. When a config is removed from `stream_configs`, the server stops streaming to that destination. Each config must contain a unique destination. — item shape: {bigqueryDestination?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{parent}/dicomStores"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: dicomStoreId, var: dicom_store_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: labels, var: labels}, {name: name, var: name}, {name: notificationConfig, var: notification_config}, {name: streamConfigs, var: stream_configs}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, dicom_store_id: $dicom_store_id, labels: $labels, name: $name, notification_config: $notification_config, stream_configs: $stream_configs
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DeleteInstance deletes an instance associated with the given study, series, and SOP Instance UID. Delete requests are equivalent to the GET requests specified in the Retrieve transaction. Study and series search results can take a few seconds to be updated after an instance is deleted using DeleteInstance. For samples that show how to call DeleteInstance, see [Deleting a study, series, or instance](https://cloud.google.com/healthcare/docs/how-tos/dicomweb#deleting_a_study_series_or_instance).
#
# DELETE /v1beta1/{parent}/dicomWeb/{dicomWebPath}
# Returns: record
# operationId: healthcare.projects.locations.datasets.dicomStores.studies.series.instances.delete
export def "healthcare-projects-locations-datasets-dicom-stores-studies-series-instances-delete" [
  parent: string
  dicom_web_path: string
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
    path: "/v1beta1/{parent}/dicomWeb/{dicomWebPath}"
    path_params: [{name: parent, var: parent}, {name: dicomWebPath, var: dicom_web_path}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, dicom_web_path: $dicom_web_path, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# RetrieveRenderedFrames returns instances associated with the given study, series, SOP Instance UID and frame numbers in an acceptable Rendered Media Type. See [RetrieveTransaction](http://dicom.nema.org/medical/dicom/current/output/html/part18.html#sect_10.4). For details on the implementation of RetrieveRenderedFrames, see [Rendered resources](https://cloud.google.com/healthcare/docs/dicom#rendered_resources) in the Cloud Healthcare API conformance statement. For samples that show how to call RetrieveRenderedFrames, see [Retrieving consumer image formats](https://cloud.google.com/healthcare/docs/how-tos/dicomweb#retrieving_consumer_image_formats).
#
# GET /v1beta1/{parent}/dicomWeb/{dicomWebPath}
# Returns: record<contentType: string, data: string, extensions: list<record>>
# operationId: healthcare.projects.locations.datasets.dicomStores.studies.series.instances.frames.retrieveRendered
export def "healthcare-projects-locations-datasets-dicom-stores-studies-series-instances-frames-retrieve-rendered" [
  parent: string
  dicom_web_path: string
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
    path: "/v1beta1/{parent}/dicomWeb/{dicomWebPath}"
    path_params: [{name: parent, var: parent}, {name: dicomWebPath, var: dicom_web_path}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, dicom_web_path: $dicom_web_path, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# StoreInstances stores DICOM instances associated with study instance unique identifiers (SUID). See [Store Transaction](http://dicom.nema.org/medical/dicom/current/output/html/part18.html#sect_10.5). For details on the implementation of StoreInstances, see [Store transaction](https://cloud.google.com/healthcare/docs/dicom#store_transaction) in the Cloud Healthcare API conformance statement. For samples that show how to call StoreInstances, see [Storing DICOM data](https://cloud.google.com/healthcare/docs/how-tos/dicomweb#storing_dicom_data).
#
# POST /v1beta1/{parent}/dicomWeb/{dicomWebPath}
# Returns: record<contentType: string, data: string, extensions: list<record>>
# operationId: healthcare.projects.locations.datasets.dicomStores.studies.storeInstances
export def "healthcare-projects-locations-datasets-dicom-stores-studies-store-instances" [
  parent: string
  dicom_web_path: string
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
  --content-type: string # The HTTP Content-Type header value specifying the content type of the body.
  --data: string # The HTTP request/response body as raw binary. (format: byte)
  --extensions: list # Application specific response metadata. Must be set in the first response for streaming APIs.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{parent}/dicomWeb/{dicomWebPath}"
    path_params: [{name: parent, var: parent}, {name: dicomWebPath, var: dicom_web_path}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: contentType, var: content_type}, {name: data, var: data}, {name: extensions, var: extensions}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, dicom_web_path: $dicom_web_path, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, content_type: $content_type, data: $data, extensions: $extensions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Executes all the requests in the given Bundle. Implements the FHIR standard batch/transaction interaction ([DSTU2](https://hl7.org/implement/standards/fhir/DSTU2/http.html#transaction), [STU3](https://hl7.org/implement/standards/fhir/STU3/http.html#transaction), [R4](https://hl7.org/implement/standards/fhir/R4/http.html#transaction)). Supports all interactions within a bundle, except search. This method accepts Bundles of type `batch` and `transaction`, processing them according to the batch processing rules ([DSTU2](https://hl7.org/implement/standards/fhir/DSTU2/http.html#2.1.0.16.1), [STU3](https://hl7.org/implement/standards/fhir/STU3/http.html#2.21.0.17.1), [R4](https://hl7.org/implement/standards/fhir/R4/http.html#brules)) and transaction processing rules ([DSTU2](https://hl7.org/implement/standards/fhir/DSTU2/http.html#2.1.0.16.2), [STU3](https://hl7.org/implement/standards/fhir/STU3/http.html#2.21.0.17.2), [R4](https://hl7.org/implement/standards/fhir/R4/http.html#trules)). The request body must contain a JSON-encoded FHIR `Bundle` resource, and the request headers must contain `Content-Type: application/fhir+json`. For a batch bundle or a successful transaction, the response body contains a JSON-encoded representation of a `Bundle` resource of type `batch-response` or `transaction-response` containing one entry for each entry in the request, with the outcome of processing the entry. In the case of an error for a transaction bundle, the response body contains a JSON-encoded `OperationOutcome` resource describing the reason for the error. If the request cannot be mapped to a valid API method on a FHIR store, a generic GCP error might be returned instead. This method checks permissions for each request in the bundle. The `executeBundle` permission is required to call this method, but you must also grant sufficient permissions to execute the individual requests in the bundle. For example, if the bundle contains a request to create a FHIR resource, the caller must also have been granted the `healthcare.fhirResources.create` permission. You can use audit logs to view the permissions for `executeBundle` and each request in the bundle. For more information, see [Viewing Cloud Audit logs](https://cloud.google.com/healthcare-api/docs/how-tos/audit-logging). For samples that show how to call `executeBundle`, see [Managing FHIR resources using FHIR bundles](https://cloud.google.com/healthcare/docs/how-tos/fhir-bundles).
#
# POST /v1beta1/{parent}/fhir
# Returns: record<contentType: string, data: string, extensions: list<record>>
# operationId: healthcare.projects.locations.datasets.fhirStores.fhir.executeBundle
export def "healthcare-projects-locations-datasets-fhir-stores-fhir-execute-bundle" [
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
  --content-type: string # The HTTP Content-Type header value specifying the content type of the body.
  --data: string # The HTTP request/response body as raw binary. (format: byte)
  --extensions: list # Application specific response metadata. Must be set in the first response for streaming APIs.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{parent}/fhir"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: contentType, var: content_type}, {name: data, var: data}, {name: extensions, var: extensions}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, content_type: $content_type, data: $data, extensions: $extensions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all incoming references to a given target FHIR resource. Can also get all incoming references when the target resource does not exist, for example, if the target has been deleted. On success, the response body contains a Bundle with type `searchset`, where each entry in the Bundle contains the full content of the resource. If the operation fails, an `OperationOutcome` is returned describing the failure. If the request cannot be mapped to a valid API method on a FHIR store, a generic Google Cloud error might be returned instead.
#
# GET /v1beta1/{parent}/fhir/$references
# Returns: record<contentType: string, data: string, extensions: list<record>>
# operationId: healthcare.projects.locations.datasets.fhirStores.fhir.Resource-incoming-references
export def "healthcare-projects-locations-datasets-fhir-stores-fhir-resource-incoming-references" [
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
  --count: int # Maximum number of resources in a page. If not specified, 100 is used. May not be larger than 1000.
  --page-token: string # Used to retrieve the next page of results when using pagination. Set `_page_token` to the value of _page_token set in next page links' url. Next page are returned in the response bundle's links field, where `link.relation` is "next". Omit `_page_token` if no previous request has been made.
  --summary: string # Used to simplify the representation of the returned resources. `_summary=text` returns only the `text`, `id`, and `meta` top-level fields. `_summary=data` removes the `text` field and returns all other fields. `_summary=false` returns all parts of the resource(s). Either not providing this parameter or providing an empty value to this parameter also returns all parts of the resource(s).
  --type: string # String of comma-delimited FHIR resource types. If provided, only resources of the specified resource type(s) are returned. If not provided or an empty value is provided, no filter on the returned resource type(s) is applied.
  --target: string # Required. The target whose incoming references are requested. This param is required and must not be empty. It uses the format "ResourceType/ResourceID", for example, target=ResourceType/ResourceID.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta1/{parent}/fhir/$references"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: _count, var: count}, {name: _page_token, var: page_token}, {name: _summary, var: summary}, {name: _type, var: type}, {name: target, var: target}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, count: $count, page_token: $page_token, summary: $summary, type: $type, target: $target
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Translates a code from one value set to another by searching for appropriate concept maps. Implements the FHIR standard $translate operation ([DSTU2](https://www.hl7.org/fhir/DSTU2/operation-conceptmap-translate.html), [STU3](https://www.hl7.org/fhir/STU3/operation-conceptmap-translate.html), [R4](https://www.hl7.org/fhir/R4/operation-conceptmap-translate.html)). On success, the response body contains a JSON-encoded representation of a FHIR Parameters resource, which includes the translation result. Errors generated by the FHIR store contain a JSON-encoded `OperationOutcome` resource describing the reason for the error. If the request cannot be mapped to a valid API method on a FHIR store, a generic GCP error might be returned instead.
#
# GET /v1beta1/{parent}/fhir/ConceptMap/$translate
# Returns: record<contentType: string, data: string, extensions: list<record>>
# operationId: healthcare.projects.locations.datasets.fhirStores.fhir.ConceptMap-search-translate
export def "healthcare-projects-locations-datasets-fhir-stores-fhir-concept-map-search-translate" [
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
  --code: string # The code to translate.
  --concept-map-version: string # The version of the concept map to use. If unset, the most current version is used.
  --source: string # The source value set of the concept map to be used. If unset, target is used to search for concept maps.
  --system: string # The system for the code to be translated.
  --target: string # The target value set of the concept map to be used. If unset, source is used to search for concept maps.
  --url: string # The canonical url of the concept map to use. If unset, the source and target is used to search for concept maps.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta1/{parent}/fhir/ConceptMap/$translate"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: code, var: code}, {name: conceptMapVersion, var: concept_map_version}, {name: source, var: source}, {name: system, var: system}, {name: target, var: target}, {name: url, var: url}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, code: $code, concept_map_version: $concept_map_version, source: $source, system: $system, target: $target, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the N most recent `Observation` resources for a subject matching search criteria specified as query parameters, grouped by `Observation.code`, sorted from most recent to oldest. Implements the FHIR extended operation Observation-lastn ([STU3](https://hl7.org/implement/standards/fhir/STU3/observation-operations.html#lastn), [R4](https://hl7.org/implement/standards/fhir/R4/observation-operations.html#lastn)). DSTU2 doesn't define the Observation-lastn method, but the server supports it the same way it supports STU3. Search terms are provided as query parameters following the same pattern as the search method. The following search parameters must be provided: - `subject` or `patient` to specify a subject for the Observation. - `code`, `category` or any of the composite parameters that include `code`. Any other valid Observation search parameters can also be provided. This operation accepts an additional query parameter `max`, which specifies N, the maximum number of Observations to return from each group, with a default of 1. Searches with over 1000 results are rejected. Results are counted before grouping and limiting the results with `max`. To stay within the limit, constrain these searches using Observation search parameters such as `_lastUpdated` or `date`. On success, the response body contains a JSON-encoded representation of a `Bundle` resource of type `searchset`, containing the results of the operation. Errors generated by the FHIR store contain a JSON-encoded `OperationOutcome` resource describing the reason for the error. If the request cannot be mapped to a valid API method on a FHIR store, a generic GCP error might be returned instead.
#
# GET /v1beta1/{parent}/fhir/Observation/$lastn
# Returns: record<contentType: string, data: string, extensions: list<record>>
# operationId: healthcare.projects.locations.datasets.fhirStores.fhir.Observation-lastn
export def "healthcare-projects-locations-datasets-fhir-stores-fhir-observation-lastn" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta1/{parent}/fhir/Observation/$lastn"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Searches for resources in the given FHIR store according to criteria specified as query parameters. Implements the FHIR standard search interaction ([DSTU2](https://hl7.org/implement/standards/fhir/DSTU2/http.html#search), [STU3](https://hl7.org/implement/standards/fhir/STU3/http.html#search), [R4](https://hl7.org/implement/standards/fhir/R4/http.html#search)) using the search semantics described in the FHIR Search specification ([DSTU2](https://hl7.org/implement/standards/fhir/DSTU2/search.html), [STU3](https://hl7.org/implement/standards/fhir/STU3/search.html), [R4](https://hl7.org/implement/standards/fhir/R4/search.html)). Supports four methods of search defined by the specification: * `GET [base]?[parameters]` to search across all resources. * `GET [base]/[type]?[parameters]` to search resources of a specified type. * `POST [base]/_search?[parameters]` as an alternate form having the same semantics as the `GET` method across all resources. * `POST [base]/[type]/_search?[parameters]` as an alternate form having the same semantics as the `GET` method for the specified type. The `GET` and `POST` methods do not support compartment searches. The `POST` method does not support `application/x-www-form-urlencoded` search parameters. On success, the response body contains a JSON-encoded representation of a `Bundle` resource of type `searchset`, containing the results of the search. Errors generated by the FHIR store contain a JSON-encoded `OperationOutcome` resource describing the reason for the error. If the request cannot be mapped to a valid API method on a FHIR store, a generic GCP error might be returned instead. The server's capability statement, retrieved through capabilities, indicates what search parameters are supported on each FHIR resource. A list of all search parameters defined by the specification can be found in the FHIR Search Parameter Registry ([STU3](https://hl7.org/implement/standards/fhir/STU3/searchparameter-registry.html), [R4](https://hl7.org/implement/standards/fhir/R4/searchparameter-registry.html)). FHIR search parameters for DSTU2 can be found on each resource's definition page. Supported search modifiers: `:missing`, `:exact`, `:contains`, `:text`, `:in`, `:not-in`, `:above`, `:below`, `:[type]`, `:not`, and `recurse` (DSTU2 and STU3) or `:iterate` (R4). Supported search result parameters: `_sort`, `_count`, `_include`, `_revinclude`, `_summary=text`, `_summary=data`, and `_elements`. The maximum number of search results returned defaults to 100, which can be overridden by the `_count` parameter up to a maximum limit of 1000. The server might return fewer resources than requested to prevent excessively large responses. If there are additional results, the returned `Bundle` contains a link of `relation` "next", which has a `_page_token` parameter for an opaque pagination token that can be used to retrieve the next page. Resources with a total size larger than 5MB or a field count larger than 50,000 might not be fully searchable as the server might trim its generated search index in those cases. Note: FHIR resources are indexed asynchronously, so there might be a slight delay between the time a resource is created or changes and when the change is reflected in search results. For samples and detailed information, see [Searching for FHIR resources](https://cloud.google.com/healthcare/docs/how-tos/fhir-search) and [Advanced FHIR search features](https://cloud.google.com/healthcare/docs/how-tos/fhir-advanced-search).
#
# POST /v1beta1/{parent}/fhir/_search
# Returns: record<contentType: string, data: string, extensions: list<record>>
# operationId: healthcare.projects.locations.datasets.fhirStores.fhir.search
export def "healthcare-projects-locations-datasets-fhir-stores-fhir-search" [
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
  --resource-type: string # The FHIR resource type to search, such as Patient or Observation. For a complete list, see the FHIR Resource Index ([DSTU2](https://hl7.org/implement/standards/fhir/DSTU2/resourcelist.html), [STU3](https://hl7.org/implement/standards/fhir/STU3/resourcelist.html), [R4](https://hl7.org/implement/standards/fhir/R4/resourcelist.html)).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{parent}/fhir/_search"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: resourceType, var: resource_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, resource_type: $resource_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Searches for resources in the given FHIR store according to criteria specified as query parameters. Implements the FHIR standard search interaction ([DSTU2](https://hl7.org/implement/standards/fhir/DSTU2/http.html#search), [STU3](https://hl7.org/implement/standards/fhir/STU3/http.html#search), [R4](https://hl7.org/implement/standards/fhir/R4/http.html#search)) using the search semantics described in the FHIR Search specification ([DSTU2](https://hl7.org/implement/standards/fhir/DSTU2/search.html), [STU3](https://hl7.org/implement/standards/fhir/STU3/search.html), [R4](https://hl7.org/implement/standards/fhir/R4/search.html)). Supports four methods of search defined by the specification: * `GET [base]?[parameters]` to search across all resources. * `GET [base]/[type]?[parameters]` to search resources of a specified type. * `POST [base]/_search?[parameters]` as an alternate form having the same semantics as the `GET` method across all resources. * `POST [base]/[type]/_search?[parameters]` as an alternate form having the same semantics as the `GET` method for the specified type. The `GET` and `POST` methods do not support compartment searches. The `POST` method does not support `application/x-www-form-urlencoded` search parameters. On success, the response body contains a JSON-encoded representation of a `Bundle` resource of type `searchset`, containing the results of the search. Errors generated by the FHIR store contain a JSON-encoded `OperationOutcome` resource describing the reason for the error. If the request cannot be mapped to a valid API method on a FHIR store, a generic GCP error might be returned instead. The server's capability statement, retrieved through capabilities, indicates what search parameters are supported on each FHIR resource. A list of all search parameters defined by the specification can be found in the FHIR Search Parameter Registry ([STU3](https://hl7.org/implement/standards/fhir/STU3/searchparameter-registry.html), [R4](https://hl7.org/implement/standards/fhir/R4/searchparameter-registry.html)). FHIR search parameters for DSTU2 can be found on each resource's definition page. Supported search modifiers: `:missing`, `:exact`, `:contains`, `:text`, `:in`, `:not-in`, `:above`, `:below`, `:[type]`, `:not`, and `recurse` (DSTU2 and STU3) or `:iterate` (R4). Supported search result parameters: `_sort`, `_count`, `_include`, `_revinclude`, `_summary=text`, `_summary=data`, and `_elements`. The maximum number of search results returned defaults to 100, which can be overridden by the `_count` parameter up to a maximum limit of 1000. The server might return fewer resources than requested to prevent excessively large responses. If there are additional results, the returned `Bundle` contains a link of `relation` "next", which has a `_page_token` parameter for an opaque pagination token that can be used to retrieve the next page. Resources with a total size larger than 5MB or a field count larger than 50,000 might not be fully searchable as the server might trim its generated search index in those cases. Note: FHIR resources are indexed asynchronously, so there might be a slight delay between the time a resource is created or changes and when the change is reflected in search results. For samples and detailed information, see [Searching for FHIR resources](https://cloud.google.com/healthcare/docs/how-tos/fhir-search) and [Advanced FHIR search features](https://cloud.google.com/healthcare/docs/how-tos/fhir-advanced-search).
#
# POST /v1beta1/{parent}/fhir/{resourceType}/_search
# Returns: record<contentType: string, data: string, extensions: list<record>>
# operationId: healthcare.projects.locations.datasets.fhirStores.fhir.search-type
export def "healthcare-projects-locations-datasets-fhir-stores-fhir-search-type" [
  parent: string
  resource_type: string
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
  --body-resource-type: string # The FHIR resource type to search, such as Patient or Observation. For a complete list, see the FHIR Resource Index ([DSTU2](https://hl7.org/implement/standards/fhir/DSTU2/resourcelist.html), [STU3](https://hl7.org/implement/standards/fhir/STU3/resourcelist.html), [R4](https://hl7.org/implement/standards/fhir/R4/resourcelist.html)). (spec name: resourceType)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{parent}/fhir/{resourceType}/_search"
    path_params: [{name: parent, var: parent}, {name: resourceType, var: resource_type}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: resourceType, var: body_resource_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, resource_type: $resource_type, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body_resource_type: $body_resource_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes FHIR resources that match a search query. Implements the FHIR standard conditional delete interaction ([DSTU2](https://hl7.org/implement/standards/fhir/DSTU2/http.html#2.1.0.12.1), [STU3](https://hl7.org/implement/standards/fhir/STU3/http.html#2.21.0.13.1), [R4](https://hl7.org/implement/standards/fhir/R4/http.html#3.1.0.7.1)). If multiple resources match, all matching resources are deleted. Search terms are provided as query parameters following the same pattern as the search method. Not all FHIR resources that match the search query might be deleted because, by default, a maximum of 100 FHIR resources can be deleted. The number of FHIR resources that can be deleted depends on the page size of the returned resources, which you can control using the `_count` query parameter. Even when using `_count`, you can delete a maximum 1,000 FHIR resources per each call of `conditionalDelete`. Note: Unless resource versioning is disabled by setting the disable_resource_versioning flag on the FHIR store, the deleted resources are moved to a history repository that can still be retrieved through vread and related methods, unless they are removed by the purge method. This method requires the`healthcare.fhirStores.searchResources` and `healthcare.fhirResources.delete` permissions on the parent FHIR store. For samples that show how to call `conditionalDelete`, see [Conditionally deleting a FHIR resource](https://cloud.google.com/healthcare/docs/how-tos/fhir-resources#conditionally_deleting_a_fhir_resource).
#
# DELETE /v1beta1/{parent}/fhir/{type}
# Returns: record
# operationId: healthcare.projects.locations.datasets.fhirStores.fhir.conditionalDelete
export def "healthcare-projects-locations-datasets-fhir-stores-fhir-conditional-delete" [
  parent: string
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
    path: "/v1beta1/{parent}/fhir/{type}"
    path_params: [{name: parent, var: parent}, {name: type, var: type}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, type: $type, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# If a resource is found based on the search criteria specified in the query parameters, updates part of that resource by applying the operations specified in a [JSON Patch](http://jsonpatch.com/) document. Implements the FHIR standard conditional patch interaction ([STU3](https://hl7.org/implement/standards/fhir/STU3/http.html#patch), [R4](https://hl7.org/implement/standards/fhir/R4/http.html#patch)). DSTU2 doesn't define a conditional patch method, but the server supports it in the same way it supports STU3. Search terms are provided as query parameters following the same pattern as the search method. If the search criteria identify more than one match, the request returns a `412 Precondition Failed` error. The request body must contain a JSON Patch document, and the request headers must contain `Content-Type: application/json-patch+json`. On success, the response body contains a JSON-encoded representation of the updated resource, including the server-assigned version ID. Errors generated by the FHIR store contain a JSON-encoded `OperationOutcome` resource describing the reason for the error. If the request cannot be mapped to a valid API method on a FHIR store, a generic GCP error might be returned instead. This method requires the`healthcare.fhirStores.searchResources` permission on the parent FHIR store and the `healthcare.fhirResources.patch` permission on the requested FHIR store resource. For samples that show how to call `conditionalPatch`, see [Conditionally patching a FHIR resource](https://cloud.google.com/healthcare/docs/how-tos/fhir-resources#conditionally_patching_a_fhir_resource).
#
# PATCH /v1beta1/{parent}/fhir/{type}
# Returns: record<contentType: string, data: string, extensions: list<record>>
# operationId: healthcare.projects.locations.datasets.fhirStores.fhir.conditionalPatch
export def "healthcare-projects-locations-datasets-fhir-stores-fhir-conditional-patch" [
  parent: string
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
  --content-type: string # The HTTP Content-Type header value specifying the content type of the body.
  --data: string # The HTTP request/response body as raw binary. (format: byte)
  --extensions: list # Application specific response metadata. Must be set in the first response for streaming APIs.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1beta1/{parent}/fhir/{type}"
    path_params: [{name: parent, var: parent}, {name: type, var: type}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: contentType, var: content_type}, {name: data, var: data}, {name: extensions, var: extensions}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, type: $type, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, content_type: $content_type, data: $data, extensions: $extensions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a FHIR resource. Implements the FHIR standard create interaction ([DSTU2](https://hl7.org/implement/standards/fhir/DSTU2/http.html#create), [STU3](https://hl7.org/implement/standards/fhir/STU3/http.html#create), [R4](https://hl7.org/implement/standards/fhir/R4/http.html#create)), which creates a new resource with a server-assigned resource ID. Also supports the FHIR standard conditional create interaction ([DSTU2](https://hl7.org/implement/standards/fhir/DSTU2/http.html#ccreate), [STU3](https://hl7.org/implement/standards/fhir/STU3/http.html#ccreate), [R4](https://hl7.org/implement/standards/fhir/R4/http.html#ccreate)), specified by supplying an `If-None-Exist` header containing a FHIR search query. If no resources match this search query, the server processes the create operation as normal. The request body must contain a JSON-encoded FHIR resource, and the request headers must contain `Content-Type: application/fhir+json`. On success, the response body contains a JSON-encoded representation of the resource as it was created on the server, including the server-assigned resource ID and version ID. Errors generated by the FHIR store contain a JSON-encoded `OperationOutcome` resource describing the reason for the error. If the request cannot be mapped to a valid API method on a FHIR store, a generic GCP error might be returned instead. For samples that show how to call `create`, see [Creating a FHIR resource](https://cloud.google.com/healthcare/docs/how-tos/fhir-resources#creating_a_fhir_resource).
#
# POST /v1beta1/{parent}/fhir/{type}
# Returns: record<contentType: string, data: string, extensions: list<record>>
# operationId: healthcare.projects.locations.datasets.fhirStores.fhir.create
export def "healthcare-projects-locations-datasets-fhir-stores-fhir-create" [
  parent: string
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
  --content-type: string # The HTTP Content-Type header value specifying the content type of the body.
  --data: string # The HTTP request/response body as raw binary. (format: byte)
  --extensions: list # Application specific response metadata. Must be set in the first response for streaming APIs.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{parent}/fhir/{type}"
    path_params: [{name: parent, var: parent}, {name: type, var: type}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: contentType, var: content_type}, {name: data, var: data}, {name: extensions, var: extensions}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, type: $type, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, content_type: $content_type, data: $data, extensions: $extensions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# If a resource is found based on the search criteria specified in the query parameters, updates the entire contents of that resource. Implements the FHIR standard conditional update interaction ([DSTU2](https://hl7.org/implement/standards/fhir/DSTU2/http.html#2.1.0.10.2), [STU3](https://hl7.org/implement/standards/fhir/STU3/http.html#cond-update), [R4](https://hl7.org/implement/standards/fhir/R4/http.html#cond-update)). Search terms are provided as query parameters following the same pattern as the search method. If the search criteria identify more than one match, the request returns a `412 Precondition Failed` error. If the search criteria identify zero matches, and the supplied resource body contains an `id`, and the FHIR store has enable_update_create set, creates the resource with the client-specified ID. It is strongly advised not to include or encode any sensitive data such as patient identifiers in client-specified resource IDs. Those IDs are part of the FHIR resource path recorded in Cloud Audit Logs and Pub/Sub notifications. Those IDs can also be contained in reference fields within other resources. If the search criteria identify zero matches, and the supplied resource body does not contain an `id`, the resource is created with a server-assigned ID as per the create method. The request body must contain a JSON-encoded FHIR resource, and the request headers must contain `Content-Type: application/fhir+json`. On success, the response body contains a JSON-encoded representation of the updated resource, including the server-assigned version ID. Errors generated by the FHIR store contain a JSON-encoded `OperationOutcome` resource describing the reason for the error. If the request cannot be mapped to a valid API method on a FHIR store, a generic GCP error might be returned instead. This method requires the`healthcare.fhirStores.searchResources` and `healthcare.fhirResources.update` permissions on the parent FHIR store. For samples that show how to call `conditionalUpdate`, see [Conditionally updating a FHIR resource](https://cloud.google.com/healthcare/docs/how-tos/fhir-resources#conditionally_updating_a_fhir_resource).
#
# PUT /v1beta1/{parent}/fhir/{type}
# Returns: record<contentType: string, data: string, extensions: list<record>>
# operationId: healthcare.projects.locations.datasets.fhirStores.fhir.conditionalUpdate
export def "healthcare-projects-locations-datasets-fhir-stores-fhir-conditional-update" [
  parent: string
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
  --content-type: string # The HTTP Content-Type header value specifying the content type of the body.
  --data: string # The HTTP request/response body as raw binary. (format: byte)
  --extensions: list # Application specific response metadata. Must be set in the first response for streaming APIs.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1beta1/{parent}/fhir/{type}"
    path_params: [{name: parent, var: parent}, {name: type, var: type}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: contentType, var: content_type}, {name: data, var: data}, {name: extensions, var: extensions}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, type: $type, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, content_type: $content_type, data: $data, extensions: $extensions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Validates an input FHIR resource's conformance to its profiles and the profiles configured on the FHIR store. Implements the FHIR extended operation $validate ([DSTU2](http://hl7.org/implement/standards/fhir/DSTU2/resource-operations.html#validate), [STU3](http://hl7.org/implement/standards/fhir/STU3/resource-operations.html#validate), or [R4](http://hl7.org/implement/standards/fhir/R4/resource-operation-validate.html)). The request body must contain a JSON-encoded FHIR resource, and the request headers must contain `Content-Type: application/fhir+json`. The `Parameters` input syntax is not supported. The `profile` query parameter can be used to request that the resource only be validated against a specific profile. If a profile with the given URL cannot be found in the FHIR store then an error is returned. Errors generated by validation contain a JSON-encoded `OperationOutcome` resource describing the reason for the error. If the request cannot be mapped to a valid API method on a FHIR store, a generic GCP error might be returned instead.
#
# POST /v1beta1/{parent}/fhir/{type}/$validate
# Returns: record<contentType: string, data: string, extensions: list<record>>
# operationId: healthcare.projects.locations.datasets.fhirStores.fhir.Resource-validate
export def "healthcare-projects-locations-datasets-fhir-stores-fhir-resource-validate" [
  parent: string
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
  --profile: string # The canonical URL of a profile that this resource should be validated against. For example, to validate a Patient resource against the US Core Patient profile this parameter would be `http://hl7.org/fhir/us/core/StructureDefinition/us-core-patient`. A StructureDefinition with this canonical URL must exist in the FHIR store.
  --content-type: string # The HTTP Content-Type header value specifying the content type of the body.
  --data: string # The HTTP request/response body as raw binary. (format: byte)
  --extensions: list # Application specific response metadata. Must be set in the first response for streaming APIs.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{parent}/fhir/{type}/$validate"
    path_params: [{name: parent, var: parent}, {name: type, var: type}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: profile, var: profile}]
    body: {content_type: "application/json", kind: json, fields: [{name: contentType, var: content_type}, {name: data, var: data}, {name: extensions, var: extensions}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, type: $type, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, profile: $profile, content_type: $content_type, data: $data, extensions: $extensions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the FHIR stores in the given dataset.
#
# GET /v1beta1/{parent}/fhirStores
# Returns: record<fhirStores: table<complexDataTypeReferenceParsing: string, defaultSearchHandlingStrict: bool, disableReferentialIntegrity: bool, disableResourceVersioning: bool, enableUpdateCreate: bool, labels: record, name: string, notificationConfig: record, notificationConfigs: list, searchConfig: record, streamConfigs: list, validationConfig: record, version: string>, nextPageToken: string>
# operationId: healthcare.projects.locations.datasets.fhirStores.list
export def "healthcare-projects-locations-datasets-fhir-stores-list" [
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
  --filter: string # Restricts stores returned to those matching a filter. The following syntax is available: * A string field value can be written as text inside quotation marks, for example `"query text"`. The only valid relational operation for text fields is equality (`=`), where text is searched within the field, rather than having the field be equal to the text. For example, `"Comment = great"` returns messages with `great` in the comment field. * A number field value can be written as an integer, a decimal, or an exponential. The valid relational operators for number fields are the equality operator (`=`), along with the less than/greater than operators (`<`, `<=`, `>`, `>=`). Note that there is no inequality (`!=`) operator. You can prepend the `NOT` operator to an expression to negate it. * A date field value must be written in `yyyy-mm-dd` form. Fields with date and time use the RFC3339 time format. Leading zeros are required for one-digit months and days. The valid relational operators for date fields are the equality operator (`=`) , along with the less than/greater than operators (`<`, `<=`, `>`, `>=`). Note that there is no inequality (`!=`) operator. You can prepend the `NOT` operator to an expression to negate it. * Multiple field query expressions can be combined in one query by adding `AND` or `OR` operators between the expressions. If a boolean operator appears within a quoted string, it is not treated as special, it's just another part of the character string to be matched. You can prepend the `NOT` operator to an expression to negate it. Only filtering on labels is supported, for example `labels.key=value`.
  --page-size: int # Limit on the number of FHIR stores to return in a single response. If not specified, 100 is used. May not be larger than 1000.
  --page-token: string # The next_page_token value returned from the previous List request, if any.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta1/{parent}/fhirStores"
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

# Creates a new FHIR store within the parent dataset.
#
# POST /v1beta1/{parent}/fhirStores
# Returns: record<complexDataTypeReferenceParsing: string, defaultSearchHandlingStrict: bool, disableReferentialIntegrity: bool, disableResourceVersioning: bool, enableUpdateCreate: bool, labels: record, name: string, notificationConfig: record<pubsubTopic: string, sendForBulkImport: bool>, notificationConfigs: table<pubsubTopic: string, sendFullResource: bool>, searchConfig: record<searchParameters: list<record>>, streamConfigs: table<bigqueryDestination: record, deidentifiedStoreDestination: record, resourceTypes: list>, validationConfig: record<disableFhirpathValidation: bool, disableProfileValidation: bool, disableReferenceTypeValidation: bool, disableRequiredFieldValidation: bool, enabledImplementationGuides: list<string>>, version: string>
# operationId: healthcare.projects.locations.datasets.fhirStores.create
export def "healthcare-projects-locations-datasets-fhir-stores-create" [
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
  --fhir-store-id: string # The ID of the FHIR store that is being created. The string must match the following regex: `[\p{L}\p{N}_\-\.]{1,256}`.
  --complex-data-type-reference-parsing: string@complex-data-type-reference-parsing-completer # Enable parsing of references within complex FHIR data types such as Extensions. If this value is set to ENABLED, then features like referential integrity and Bundle reference rewriting apply to all references. If this flag has not been specified the behavior of the FHIR store will not change, references in complex data types will not be parsed. New stores will have this value set to ENABLED after a notification period. Warning: turning on this flag causes processing existing resources to fail if they contain references to non-existent resources.
  --default-search-handling-strict: oneof<nothing, bool> # If true, overrides the default search behavior for this FHIR store to `handling=strict` which returns an error for unrecognized search parameters. If false, uses the FHIR specification default `handling=lenient` which ignores unrecognized search parameters. The handling can always be changed from the default on an individual API call by setting the HTTP header `Prefer: handling=strict` or `Prefer: handling=lenient`.
  --disable-referential-integrity: oneof<nothing, bool> # Immutable. Whether to disable referential integrity in this FHIR store. This field is immutable after FHIR store creation. The default value is false, meaning that the API enforces referential integrity and fails the requests that result in inconsistent state in the FHIR store. When this field is set to true, the API skips referential integrity checks. Consequently, operations that rely on references, such as GetPatientEverything, do not return all the results if broken references exist.
  --disable-resource-versioning: oneof<nothing, bool> # Immutable. Whether to disable resource versioning for this FHIR store. This field can not be changed after the creation of FHIR store. If set to false, which is the default behavior, all write operations cause historical versions to be recorded automatically. The historical versions can be fetched through the history APIs, but cannot be updated. If set to true, no historical versions are kept. The server sends errors for attempts to read the historical versions.
  --enable-update-create: oneof<nothing, bool> # Whether this FHIR store has the [updateCreate capability](https://www.hl7.org/fhir/capabilitystatement-definitions.html#CapabilityStatement.rest.resource.updateCreate). This determines if the client can use an Update operation to create a new resource with a client-specified ID. If false, all IDs are server-assigned through the Create operation and attempts to update a non-existent resource return errors. It is strongly advised not to include or encode any sensitive data such as patient identifiers in client-specified resource IDs. Those IDs are part of the FHIR resource path recorded in Cloud audit logs and Pub/Sub notifications. Those IDs can also be contained in reference fields within other resources.
  --labels: record # User-supplied key-value pairs used to organize FHIR stores. Label keys must be between 1 and 63 characters long, have a UTF-8 encoding of maximum 128 bytes, and must conform to the following PCRE regular expression: \p{Ll}\p{Lo}{0,62} Label values are optional, must be between 1 and 63 characters long, have a UTF-8 encoding of maximum 128 bytes, and must conform to the following PCRE regular expression: [\p{Ll}\p{Lo}\p{N}_-]{0,63} No more than 64 labels can be associated with a given store.
  --name: string # Output only. Resource name of the FHIR store, of the form `projects/{project_id}/datasets/{dataset_id}/fhirStores/{fhir_store_id}`.
  --notification-config: record # Specifies where to send notifications upon changes to a data store. — shape: {pubsubTopic?: string, sendForBulkImport?: bool}
  --notification-configs: list # Specifies where and whether to send notifications upon changes to a Fhir store. — item shape: {pubsubTopic?: string, sendFullResource?: bool}
  --search-config: record # Contains the configuration for FHIR search. — shape: {searchParameters?: list}
  --stream-configs: list # A list of streaming configs that configure the destinations of streaming export for every resource mutation in this FHIR store. Each store is allowed to have up to 10 streaming configs. After a new config is added, the next resource mutation is streamed to the new location in addition to the existing ones. When a location is removed from the list, the server stops streaming to that location. Before adding a new config, you must add the required [`bigquery.dataEditor`](https://cloud.google.com/bigquery/docs/access-control#bigquery.dataEditor) role to your project's **Cloud Healthcare Service Agent** [service account](https://cloud.google.com/iam/docs/service-accounts). Some lag (typically on the order of dozens of seconds) is expected before the results show up in the streaming destination. — item shape: {bigqueryDestination?: record, deidentifiedStoreDestination?: record, resourceTypes?: list<string>}
  --validation-config: record # Contains the configuration for FHIR profiles and validation. — shape: {disableFhirpathValidation?: bool, disableProfileValidation?: bool, disableReferenceTypeValidation?: bool, disableRequiredFieldValidation?: bool, enabledImplementationGuides?: list<string>}
  --version: string@version-completer # Immutable. The FHIR specification version that this FHIR store supports natively. This field is immutable after store creation. Requests are rejected if they contain FHIR resources of a different version. Version is required for every FHIR store.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{parent}/fhirStores"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: fhirStoreId, var: fhir_store_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: complexDataTypeReferenceParsing, var: complex_data_type_reference_parsing}, {name: defaultSearchHandlingStrict, var: default_search_handling_strict}, {name: disableReferentialIntegrity, var: disable_referential_integrity}, {name: disableResourceVersioning, var: disable_resource_versioning}, {name: enableUpdateCreate, var: enable_update_create}, {name: labels, var: labels}, {name: name, var: name}, {name: notificationConfig, var: notification_config}, {name: notificationConfigs, var: notification_configs}, {name: searchConfig, var: search_config}, {name: streamConfigs, var: stream_configs}, {name: validationConfig, var: validation_config}, {name: version, var: version}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, fhir_store_id: $fhir_store_id, complex_data_type_reference_parsing: $complex_data_type_reference_parsing, default_search_handling_strict: $default_search_handling_strict, disable_referential_integrity: $disable_referential_integrity, disable_resource_versioning: $disable_resource_versioning, enable_update_create: $enable_update_create, labels: $labels, name: $name, notification_config: $notification_config, notification_configs: $notification_configs, search_config: $search_config, stream_configs: $stream_configs, validation_config: $validation_config, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the HL7v2 stores in the given dataset.
#
# GET /v1beta1/{parent}/hl7V2Stores
# Returns: record<hl7V2Stores: table<labels: record, name: string, notificationConfig: record, notificationConfigs: list, parserConfig: record, rejectDuplicateMessage: bool>, nextPageToken: string>
# operationId: healthcare.projects.locations.datasets.hl7V2Stores.list
export def "healthcare-projects-locations-datasets-hl7-v2-stores-list" [
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
  --filter: string # Restricts stores returned to those matching a filter. The following syntax is available: * A string field value can be written as text inside quotation marks, for example `"query text"`. The only valid relational operation for text fields is equality (`=`), where text is searched within the field, rather than having the field be equal to the text. For example, `"Comment = great"` returns messages with `great` in the comment field. * A number field value can be written as an integer, a decimal, or an exponential. The valid relational operators for number fields are the equality operator (`=`), along with the less than/greater than operators (`<`, `<=`, `>`, `>=`). Note that there is no inequality (`!=`) operator. You can prepend the `NOT` operator to an expression to negate it. * A date field value must be written in `yyyy-mm-dd` form. Fields with date and time use the RFC3339 time format. Leading zeros are required for one-digit months and days. The valid relational operators for date fields are the equality operator (`=`) , along with the less than/greater than operators (`<`, `<=`, `>`, `>=`). Note that there is no inequality (`!=`) operator. You can prepend the `NOT` operator to an expression to negate it. * Multiple field query expressions can be combined in one query by adding `AND` or `OR` operators between the expressions. If a boolean operator appears within a quoted string, it is not treated as special, it's just another part of the character string to be matched. You can prepend the `NOT` operator to an expression to negate it. Only filtering on labels is supported. For example, `labels.key=value`.
  --page-size: int # Limit on the number of HL7v2 stores to return in a single response. If not specified, 100 is used. May not be larger than 1000.
  --page-token: string # The next_page_token value returned from the previous List request, if any.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta1/{parent}/hl7V2Stores"
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

# Creates a new HL7v2 store within the parent dataset.
#
# POST /v1beta1/{parent}/hl7V2Stores
# Returns: record<labels: record, name: string, notificationConfig: record<pubsubTopic: string, sendForBulkImport: bool>, notificationConfigs: table<filter: string, pubsubTopic: string>, parserConfig: record<allowNullHeader: bool, schema: record<ignoreMinOccurs: bool, schemas: list, schematizedParsingType: string, types: list, unexpectedSegmentHandling: string>, segmentTerminator: string, version: string>, rejectDuplicateMessage: bool>
# operationId: healthcare.projects.locations.datasets.hl7V2Stores.create
export def "healthcare-projects-locations-datasets-hl7-v2-stores-create" [
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
  --hl7-v2-store-id: string # The ID of the HL7v2 store that is being created. The string must match the following regex: `[\p{L}\p{N}_\-\.]{1,256}`.
  --labels: record # User-supplied key-value pairs used to organize HL7v2 stores. Label keys must be between 1 and 63 characters long, have a UTF-8 encoding of maximum 128 bytes, and must conform to the following PCRE regular expression: \p{Ll}\p{Lo}{0,62} Label values are optional, must be between 1 and 63 characters long, have a UTF-8 encoding of maximum 128 bytes, and must conform to the following PCRE regular expression: [\p{Ll}\p{Lo}\p{N}_-]{0,63} No more than 64 labels can be associated with a given store.
  --name: string # Resource name of the HL7v2 store, of the form `projects/{project_id}/locations/{location_id}/datasets/{dataset_id}/hl7V2Stores/{hl7v2_store_id}`.
  --notification-config: record # Specifies where to send notifications upon changes to a data store. — shape: {pubsubTopic?: string, sendForBulkImport?: bool}
  --notification-configs: list # A list of notification configs. Each configuration uses a filter to determine whether to publish a message (both Ingest & Create) on the corresponding notification destination. Only the message name is sent as part of the notification. Supplied by the client. — item shape: {filter?: string, pubsubTopic?: string}
  --parser-config: record # The configuration for the parser. It determines how the server parses the messages. — shape: {allowNullHeader?: bool, schema?: record, segmentTerminator?: string, version?: "PARSER_VERSION_UNSPECIFIED"|"V1"|"V2"|"V3"}
  --reject-duplicate-message: oneof<nothing, bool> # Determines whether to reject duplicate messages. A duplicate message is a message with the same raw bytes as a message that has already been ingested/created in this HL7v2 store. The default value is false, meaning that the store accepts the duplicate messages and it also returns the same ACK message in the IngestMessageResponse as has been returned previously. Note that only one resource is created in the store. When this field is set to true, CreateMessage/IngestMessage requests with a duplicate message will be rejected by the store, and IngestMessageErrorDetail returns a NACK message upon rejection.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{parent}/hl7V2Stores"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: hl7V2StoreId, var: hl7_v2_store_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: labels, var: labels}, {name: name, var: name}, {name: notificationConfig, var: notification_config}, {name: notificationConfigs, var: notification_configs}, {name: parserConfig, var: parser_config}, {name: rejectDuplicateMessage, var: reject_duplicate_message}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, hl7_v2_store_id: $hl7_v2_store_id, labels: $labels, name: $name, notification_config: $notification_config, notification_configs: $notification_configs, parser_config: $parser_config, reject_duplicate_message: $reject_duplicate_message
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all the messages in the given HL7v2 store with support for filtering. Note: HL7v2 messages are indexed asynchronously, so there might be a slight delay between the time a message is created and when it can be found through a filter.
#
# GET /v1beta1/{parent}/messages
# Returns: record<hl7V2Messages: table<createTime: string, data: string, labels: record, messageType: string, name: string, parsedData: record, patientIds: list, schematizedData: record, sendFacility: string, sendTime: string>, nextPageToken: string>
# operationId: healthcare.projects.locations.datasets.hl7V2Stores.messages.list
export def "healthcare-projects-locations-datasets-hl7-v2-stores-messages-list" [
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
  --filter: string # Restricts messages returned to those matching a filter. The following syntax is available: * A string field value can be written as text inside quotation marks, for example `"query text"`. The only valid relational operation for text fields is equality (`=`), where text is searched within the field, rather than having the field be equal to the text. For example, `"Comment = great"` returns messages with `great` in the comment field. * A number field value can be written as an integer, a decimal, or an exponential. The valid relational operators for number fields are the equality operator (`=`), along with the less than/greater than operators (`<`, `<=`, `>`, `>=`). Note that there is no inequality (`!=`) operator. You can prepend the `NOT` operator to an expression to negate it. * A date field value must be written in `yyyy-mm-dd` form. Fields with date and time use the RFC3339 time format. Leading zeros are required for one-digit months and days. The valid relational operators for date fields are the equality operator (`=`) , along with the less than/greater than operators (`<`, `<=`, `>`, `>=`). Note that there is no inequality (`!=`) operator. You can prepend the `NOT` operator to an expression to negate it. * Multiple field query expressions can be combined in one query by adding `AND` or `OR` operators between the expressions. If a boolean operator appears within a quoted string, it is not treated as special, it's just another part of the character string to be matched. You can prepend the `NOT` operator to an expression to negate it. Fields/functions available for filtering are: * `message_type`, from the MSH-9.1 field. For example, `NOT message_type = "ADT"`. * `send_date` or `sendDate`, the YYYY-MM-DD date the message was sent in the dataset's time_zone, from the MSH-7 segment. For example, `send_date < "2017-01-02"`. * `send_time`, the timestamp when the message was sent, using the RFC3339 time format for comparisons, from the MSH-7 segment. For example, `send_time < "2017-01-02T00:00:00-05:00"`. * `create_time`, the timestamp when the message was created in the HL7v2 store. Use the RFC3339 time format for comparisons. For example, `create_time < "2017-01-02T00:00:00-05:00"`. * `send_facility`, the care center that the message came from, from the MSH-4 segment. For example, `send_facility = "ABC"`. * `PatientId(value, type)`, which matches if the message lists a patient having an ID of the given value and type in the PID-2, PID-3, or PID-4 segments. For example, `PatientId("123456", "MRN")`. * `labels.x`, a string value of the label with key `x` as set using the Message.labels map. For example, `labels."priority"="high"`. The operator `:*` can be used to assert the existence of a label. For example, `labels."priority":*`.
  --order-by: string # Orders messages returned by the specified order_by clause. Syntax: https://cloud.google.com/apis/design/design_patterns#sorting_order Fields available for ordering are: * `send_time`
  --page-size: int # Limit on the number of messages to return in a single response. If not specified, 100 is used. May not be larger than 1000.
  --page-token: string # The next_page_token value returned from the previous List request, if any.
  --view: string@view-completer # Specifies the parts of the Message to return in the response. When unspecified, equivalent to BASIC. Setting this to anything other than BASIC with a `page_size` larger than the default can generate a large response, which impacts the performance of this method.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta1/{parent}/messages"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: filter, var: filter}, {name: orderBy, var: order_by}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}, {name: view, var: view}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, filter: $filter, order_by: $order_by, page_size: $page_size, page_token: $page_token, view: $view
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Parses and stores an HL7v2 message. This method triggers an asynchronous notification to any Pub/Sub topic configured in Hl7V2Store.Hl7V2NotificationConfig, if the filtering matches the message. If an MLLP adapter is configured to listen to a Pub/Sub topic, the adapter transmits the message when a notification is received.
#
# POST /v1beta1/{parent}/messages
# Returns: record<createTime: string, data: string, labels: record, messageType: string, name: string, parsedData: record<segments: list<record>>, patientIds: table<type: string, value: string>, schematizedData: record<data: string, error: string>, sendFacility: string, sendTime: string>
# operationId: healthcare.projects.locations.datasets.hl7V2Stores.messages.create
export def "healthcare-projects-locations-datasets-hl7-v2-stores-messages-create" [
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
  --message: record # A complete HL7v2 message. See [Introduction to HL7 Standards] (https://www.hl7.org/implement/standards/index.cfm?ref=common) for details on the standard. — shape: {data?: string, labels?: record, messageType?: string, name?: string, parsedData?: record, patientIds?: list, schematizedData?: record, sendFacility?: string, sendTime?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{parent}/messages"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: message, var: message}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, message: $message
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets multiple messages in the given HL7v2 store.
#
# GET /v1beta1/{parent}/messages:batchGet
# Returns: record<messages: table<createTime: string, data: string, labels: record, messageType: string, name: string, parsedData: record, patientIds: list, schematizedData: record, sendFacility: string, sendTime: string>>
# operationId: healthcare.projects.locations.datasets.hl7V2Stores.messages.batchGet
export def "healthcare-projects-locations-datasets-hl7-v2-stores-messages-batch-get" [
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
  --ids: list<string> # The resource id of the HL7v2 messages to retrieve in the format: `{message_id}`, where the full resource name is `{parent}/messages/{message_id}` A maximum of 100 messages can be retrieved in a batch. All 'ids' have to be under parent.
  --view: string@view-completer # Specifies the parts of the Messages resource to return in the response. When unspecified, equivalent to BASIC.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta1/{parent}/messages:batchGet"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: ids, var: ids, style: multi}, {name: view, var: view}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, ids: $ids, view: $view
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Parses and stores an HL7v2 message. This method triggers an asynchronous notification to any Pub/Sub topic configured in Hl7V2Store.Hl7V2NotificationConfig, if the filtering matches the message. If an MLLP adapter is configured to listen to a Pub/Sub topic, the adapter transmits the message when a notification is received. If the method is successful, it generates a response containing an HL7v2 acknowledgment (`ACK`) message. If the method encounters an error, it returns a negative acknowledgment (`NACK`) message. This behavior is suitable for replying to HL7v2 interface systems that expect these acknowledgments.
#
# POST /v1beta1/{parent}/messages:ingest
# Returns: record<hl7Ack: string, message: record<createTime: string, data: string, labels: record, messageType: string, name: string, parsedData: record<segments: list>, patientIds: list<record>, schematizedData: record<data: string, error: string>, sendFacility: string, sendTime: string>>
# operationId: healthcare.projects.locations.datasets.hl7V2Stores.messages.ingest
export def "healthcare-projects-locations-datasets-hl7-v2-stores-messages-ingest" [
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
  --message: record # A complete HL7v2 message. See [Introduction to HL7 Standards] (https://www.hl7.org/implement/standards/index.cfm?ref=common) for details on the standard. — shape: {data?: string, labels?: record, messageType?: string, name?: string, parsedData?: record, patientIds?: list, schematizedData?: record, sendFacility?: string, sendTime?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{parent}/messages:ingest"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: message, var: message}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, message: $message
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the User data mappings in the specified consent store.
#
# GET /v1beta1/{parent}/userDataMappings
# Returns: record<nextPageToken: string, userDataMappings: table<archiveTime: string, archived: bool, dataId: string, name: string, resourceAttributes: list, userId: string>>
# operationId: healthcare.projects.locations.datasets.consentStores.userDataMappings.list
export def "healthcare-projects-locations-datasets-consent-stores-user-data-mappings-list" [
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
  --filter: string # Optional. Restricts the user data mappings returned to those matching a filter. The following syntax is available: * A string field value can be written as text inside quotation marks, for example `"query text"`. The only valid relational operation for text fields is equality (`=`), where text is searched within the field, rather than having the field be equal to the text. For example, `"Comment = great"` returns messages with `great` in the comment field. * A number field value can be written as an integer, a decimal, or an exponential. The valid relational operators for number fields are the equality operator (`=`), along with the less than/greater than operators (`<`, `<=`, `>`, `>=`). Note that there is no inequality (`!=`) operator. You can prepend the `NOT` operator to an expression to negate it. * A date field value must be written in `yyyy-mm-dd` form. Fields with date and time use the RFC3339 time format. Leading zeros are required for one-digit months and days. The valid relational operators for date fields are the equality operator (`=`) , along with the less than/greater than operators (`<`, `<=`, `>`, `>=`). Note that there is no inequality (`!=`) operator. You can prepend the `NOT` operator to an expression to negate it. * Multiple field query expressions can be combined in one query by adding `AND` or `OR` operators between the expressions. If a boolean operator appears within a quoted string, it is not treated as special, it's just another part of the character string to be matched. You can prepend the `NOT` operator to an expression to negate it. The fields available for filtering are: - data_id - user_id. For example, `filter=user_id=\"user123\"`. - archived - archive_time
  --page-size: int # Optional. Limit on the number of User data mappings to return in a single response. If not specified, 100 is used. May not be larger than 1000.
  --page-token: string # Optional. Token to retrieve the next page of results, or empty to get the first page.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta1/{parent}/userDataMappings"
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

# Creates a new User data mapping in the parent consent store.
#
# POST /v1beta1/{parent}/userDataMappings
# Returns: record<archiveTime: string, archived: bool, dataId: string, name: string, resourceAttributes: table<attributeDefinitionId: string, values: list>, userId: string>
# operationId: healthcare.projects.locations.datasets.consentStores.userDataMappings.create
export def "healthcare-projects-locations-datasets-consent-stores-user-data-mappings-create" [
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
  --data-id: string # Required. A unique identifier for the mapped resource.
  --name: string # Resource name of the User data mapping, of the form `projects/{project_id}/locations/{location_id}/datasets/{dataset_id}/consentStores/{consent_store_id}/userDataMappings/{user_data_mapping_id}`.
  --resource-attributes: list # Attributes of the resource. Only explicitly set attributes are displayed here. Attribute definitions with defaults set implicitly apply to these User data mappings. Attributes listed here must be single valued, that is, exactly one value is specified for the field "values" in each Attribute. — item shape: {attributeDefinitionId?: string, values?: list<string>}
  --user-id: string # Required. User's UUID provided by the client.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{parent}/userDataMappings"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: dataId, var: data_id}, {name: name, var: name}, {name: resourceAttributes, var: resource_attributes}, {name: userId, var: user_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, data_id: $data_id, name: $name, resource_attributes: $resource_attributes, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the access control policy for a resource. Returns an empty policy if the resource exists and does not have a policy set.
#
# GET /v1beta1/{resource}:getIamPolicy
# Returns: record<auditConfigs: table<auditLogConfigs: list, service: string>, bindings: table<condition: record, members: list, role: string>, etag: string, version: int>
# operationId: healthcare.projects.locations.datasets.hl7V2Stores.getIamPolicy
export def "healthcare-projects-locations-datasets-hl7-v2-stores-get-iam-policy" [
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
  --options-requested-policy-version: int # Optional. The maximum policy version that will be used to format the policy. Valid values are 0, 1, and 3. Requests specifying an invalid value will be rejected. Requests for policies with any conditional role bindings must specify version 3. Policies with no conditional role bindings may specify any valid value or leave the field unset. The policy in the response might use the policy version that you specified, or it might use a lower policy version. For example, if you specify version 3, but the policy has no conditional role bindings, the response uses version 1. To learn which resources support conditions in their IAM policies, see the [IAM documentation](https://cloud.google.com/iam/help/conditions/resource-policies).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta1/{resource}:getIamPolicy"
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

# Sets the access control policy on the specified resource. Replaces any existing policy. Can return `NOT_FOUND`, `INVALID_ARGUMENT`, and `PERMISSION_DENIED` errors.
#
# POST /v1beta1/{resource}:setIamPolicy
# Returns: record<auditConfigs: table<auditLogConfigs: list, service: string>, bindings: table<condition: record, members: list, role: string>, etag: string, version: int>
# operationId: healthcare.projects.locations.datasets.hl7V2Stores.setIamPolicy
export def "healthcare-projects-locations-datasets-hl7-v2-stores-set-iam-policy" [
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
  --policy: record # An Identity and Access Management (IAM) policy, which specifies access controls for Google Cloud resources. A `Policy` is a collection of `bindings`. A `binding` binds one or more `members`, or principals, to a single `role`. Principals can be user accounts, service accounts, Google groups, and domains (such as G Suite). A `role` is a named list of permissions; each `role` can be an IAM predefined role or a user-created custom role. For some types of Google Cloud resources, a `binding` can also specify a `condition`, which is a logical expression that allows access to a resource only if the expression evaluates to `true`. A condition can add constraints based on attributes of the request, the resource, or both. To learn which resources support conditions in their IAM policies, see the [IAM documentation](https://cloud.google.com/iam/help/conditions/resource-policies). **JSON example:** { "bindings": [ { "role": "roles/resourcemanager.organizationAdmin", "members": [ "user:mike@example.com", "group:admins@example.com", "domain:google.com", "serviceAccount:my-project-id@appspot.gserviceaccount.com" ] }, { "role": "roles/resourcemanager.organizationViewer", "members": [ "user:eve@example.com" ], "condition": { "title": "expirable access", "description": "Does not grant access after Sep 2020", "expression": "request.time < timestamp('2020-10-01T00:00:00.000Z')", } } ], "etag": "BwWWja0YfJA=", "version": 3 } **YAML example:** bindings: - members: - user:mike@example.com - group:admins@example.com - domain:google.com - serviceAccount:my-project-id@appspot.gserviceaccount.com role: roles/resourcemanager.organizationAdmin - members: - user:eve@example.com role: roles/resourcemanager.organizationViewer condition: title: expirable access description: Does not grant access after Sep 2020 expression: request.time < timestamp('2020-10-01T00:00:00.000Z') etag: BwWWja0YfJA= version: 3 For a description of IAM and its features, see the [IAM documentation](https://cloud.google.com/iam/docs/). — shape: {auditConfigs?: list, bindings?: list, etag?: string, version?: int}
  --update-mask: string # OPTIONAL: A FieldMask specifying which fields of the policy to modify. Only the fields in the mask will be modified. If no mask is provided, the following default mask is used: `paths: "bindings, etag"` (format: google-fieldmask)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{resource}:setIamPolicy"
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

# Returns permissions that a caller has on the specified resource. If the resource does not exist, this will return an empty set of permissions, not a `NOT_FOUND` error. Note: This operation is designed to be used for building permission-aware UIs and command-line tools, not for authorization checking. This operation may "fail open" without warning.
#
# POST /v1beta1/{resource}:testIamPermissions
# Returns: record<permissions: list<string>>
# operationId: healthcare.projects.locations.datasets.hl7V2Stores.testIamPermissions
export def "healthcare-projects-locations-datasets-hl7-v2-stores-test-iam-permissions" [
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
  --permissions: list<string> # The set of permissions to check for the `resource`. Permissions with wildcards (such as `*` or `storage.*`) are not allowed. For more information see [IAM Overview](https://cloud.google.com/iam/docs/overview#permissions).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{resource}:testIamPermissions"
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

# Creates a new dataset containing de-identified data from the source dataset. The metadata field type is OperationMetadata. If the request is successful, the response field type is DeidentifySummary. The LRO result may still be successful if de-identification fails for some resources. The new de-identified dataset will not contain these failed resources. The number of resources processed are tracked in Operation.metadata. Error details are logged to Cloud Logging. For more information, see [Viewing error logs in Cloud Logging](https://cloud.google.com/healthcare/docs/how-tos/logging).
#
# POST /v1beta1/{sourceDataset}:deidentify
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: healthcare.projects.locations.datasets.deidentify
export def "healthcare-projects-locations-datasets-deidentify" [
  source_dataset: string
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
  --config: record # Configures de-id options specific to different types of content. Each submessage customizes the handling of an https://tools.ietf.org/html/rfc6838 media type or subtype. Configs are applied in a nested manner at runtime. — shape: {annotation?: record, dicom?: record, dicomTagConfig?: record, fhir?: record, fhirFieldConfig?: record, image?: record, operationMetadata?: record, text?: record}
  --destination-dataset: string # The name of the dataset resource to create and write the redacted data to. * The destination dataset must not exist. * The destination dataset must be in the same location as the source dataset. De-identifying data across multiple locations is not supported.
  --gcs-config-uri: string # Cloud Storage location to read the JSON cloud.healthcare.deidentify.DeidentifyConfig from, overriding the default config. Must be of the form `gs://{bucket_id}/path/to/object`. The Cloud Storage location must grant the Cloud IAM role `roles/storage.objectViewer` to the project's Cloud Healthcare Service Agent service account. Only one of `config` and `gcs_config_uri` can be specified.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{sourceDataset}:deidentify"
    path_params: [{name: sourceDataset, var: source_dataset}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: config, var: config}, {name: destinationDataset, var: destination_dataset}, {name: gcsConfigUri, var: gcs_config_uri}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    source_dataset: $source_dataset, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, config: $config, destination_dataset: $destination_dataset, gcs_config_uri: $gcs_config_uri
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# De-identifies data from the source store and writes it to the destination store. The metadata field type is OperationMetadata. If the request is successful, the response field type is DeidentifyFhirStoreSummary. The number of resources processed are tracked in Operation.metadata. Error details are logged to Cloud Logging. For more information, see [Viewing error logs in Cloud Logging](https://cloud.google.com/healthcare/docs/how-tos/logging).
#
# POST /v1beta1/{sourceStore}:deidentify
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: healthcare.projects.locations.datasets.fhirStores.deidentify
export def "healthcare-projects-locations-datasets-fhir-stores-deidentify" [
  source_store: string
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
  --config: record # Configures de-id options specific to different types of content. Each submessage customizes the handling of an https://tools.ietf.org/html/rfc6838 media type or subtype. Configs are applied in a nested manner at runtime. — shape: {annotation?: record, dicom?: record, dicomTagConfig?: record, fhir?: record, fhirFieldConfig?: record, image?: record, operationMetadata?: record, text?: record}
  --destination-store: string # The name of the FHIR store to create and write the redacted data to. For example, `projects/{project_id}/locations/{location_id}/datasets/{dataset_id}/fhirStores/{fhir_store_id}`. * The destination dataset must exist. * The source dataset and destination dataset must both reside in the same location. De-identifying data across multiple locations is not supported. * The destination FHIR store must exist. * The caller must have the healthcare.fhirResources.update permission to write to the destination FHIR store.
  --gcs-config-uri: string # Cloud Storage location to read the JSON cloud.healthcare.deidentify.DeidentifyConfig from, overriding the default config. Must be of the form `gs://{bucket_id}/path/to/object`. The Cloud Storage location must grant the Cloud IAM role `roles/storage.objectViewer` to the project's Cloud Healthcare Service Agent service account. Only one of `config` and `gcs_config_uri` can be specified.
  --resource-filter: record # Filter configuration. — shape: {resources?: record}
  --skip-modified-resources: oneof<nothing, bool> # If true, skips resources that are created or modified after the de-identify operation is created.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{sourceStore}:deidentify"
    path_params: [{name: sourceStore, var: source_store}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: config, var: config}, {name: destinationStore, var: destination_store}, {name: gcsConfigUri, var: gcs_config_uri}, {name: resourceFilter, var: resource_filter}, {name: skipModifiedResources, var: skip_modified_resources}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    source_store: $source_store, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, config: $config, destination_store: $destination_store, gcs_config_uri: $gcs_config_uri, resource_filter: $resource_filter, skip_modified_resources: $skip_modified_resources
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
