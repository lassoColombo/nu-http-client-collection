# Auto-generated client for Cloud Deployment Manager V2 API v2beta
# Source: https://api.apis.guru/v2/specs/googleapis.com/deploymentmanager/v2beta/openapi.json
# Auth: --token flag or $env.CLOUD_DEPLOYMENT_MANAGER_V2_API_TOKEN

const CLIENT = {
  base_url: "https://deploymentmanager.googleapis.com"
  token_env_var: "CLOUD_DEPLOYMENT_MANAGER_V2_API_TOKEN"
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

def base-url-completer [] { ["https://deploymentmanager.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def status-completer [] { ["DEPRECATED" "EXPERIMENTAL" "SUPPORTED" "UNKNOWN_STATUS"] }
def create-policy-completer [] { ["ACQUIRE" "CREATE" "CREATE_OR_ACQUIRE"] }
def delete-policy-completer [] { ["ABANDON" "DELETE"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    deploymentmanager-composite-types-list: "record<compositeTypes: table<description: string, id: string, insertTime: string, labels: list, name: string, operation: record, selfLink: string, status: string, templateContents: record>, nextPageToken: string>"
    deploymentmanager-composite-types-insert: "record<clientOperationId: string, creationTimestamp: string, description: string, endTime: string, error: record<errors: list<record>>, httpErrorMessage: string, httpErrorStatusCode: int, id: string, insertTime: string, kind: string, name: string, operationGroupId: string, operationType: string, progress: int, region: string, selfLink: string, startTime: string, status: string, statusMessage: string, targetId: string, targetLink: string, user: string, warnings: table<code: string, data: list, message: string>, zone: string>"
    deploymentmanager-composite-types-delete: "record<clientOperationId: string, creationTimestamp: string, description: string, endTime: string, error: record<errors: list<record>>, httpErrorMessage: string, httpErrorStatusCode: int, id: string, insertTime: string, kind: string, name: string, operationGroupId: string, operationType: string, progress: int, region: string, selfLink: string, startTime: string, status: string, statusMessage: string, targetId: string, targetLink: string, user: string, warnings: table<code: string, data: list, message: string>, zone: string>"
    deploymentmanager-composite-types-get: "record<description: string, id: string, insertTime: string, labels: table<key: string, value: string>, name: string, operation: record<clientOperationId: string, creationTimestamp: string, description: string, endTime: string, error: record<errors: list>, httpErrorMessage: string, httpErrorStatusCode: int, id: string, insertTime: string, kind: string, name: string, operationGroupId: string, operationType: string, progress: int, region: string, selfLink: string, startTime: string, status: string, statusMessage: string, targetId: string, targetLink: string, user: string, warnings: list<record>, zone: string>, selfLink: string, status: string, templateContents: record<imports: list<record>, interpreter: string, mainTemplate: string, schema: string, template: string>>"
    deploymentmanager-composite-types-patch: "record<clientOperationId: string, creationTimestamp: string, description: string, endTime: string, error: record<errors: list<record>>, httpErrorMessage: string, httpErrorStatusCode: int, id: string, insertTime: string, kind: string, name: string, operationGroupId: string, operationType: string, progress: int, region: string, selfLink: string, startTime: string, status: string, statusMessage: string, targetId: string, targetLink: string, user: string, warnings: table<code: string, data: list, message: string>, zone: string>"
    deploymentmanager-composite-types-update: "record<clientOperationId: string, creationTimestamp: string, description: string, endTime: string, error: record<errors: list<record>>, httpErrorMessage: string, httpErrorStatusCode: int, id: string, insertTime: string, kind: string, name: string, operationGroupId: string, operationType: string, progress: int, region: string, selfLink: string, startTime: string, status: string, statusMessage: string, targetId: string, targetLink: string, user: string, warnings: table<code: string, data: list, message: string>, zone: string>"
    deploymentmanager-deployments-list: "record<deployments: table<description: string, fingerprint: string, id: string, insertTime: string, labels: list, manifest: string, name: string, operation: record, selfLink: string, target: record, update: record, updateTime: string>, nextPageToken: string>"
    deploymentmanager-deployments-insert: "record<clientOperationId: string, creationTimestamp: string, description: string, endTime: string, error: record<errors: list<record>>, httpErrorMessage: string, httpErrorStatusCode: int, id: string, insertTime: string, kind: string, name: string, operationGroupId: string, operationType: string, progress: int, region: string, selfLink: string, startTime: string, status: string, statusMessage: string, targetId: string, targetLink: string, user: string, warnings: table<code: string, data: list, message: string>, zone: string>"
    deploymentmanager-deployments-delete: "record<clientOperationId: string, creationTimestamp: string, description: string, endTime: string, error: record<errors: list<record>>, httpErrorMessage: string, httpErrorStatusCode: int, id: string, insertTime: string, kind: string, name: string, operationGroupId: string, operationType: string, progress: int, region: string, selfLink: string, startTime: string, status: string, statusMessage: string, targetId: string, targetLink: string, user: string, warnings: table<code: string, data: list, message: string>, zone: string>"
    deploymentmanager-deployments-get: "record<description: string, fingerprint: string, id: string, insertTime: string, labels: table<key: string, value: string>, manifest: string, name: string, operation: record<clientOperationId: string, creationTimestamp: string, description: string, endTime: string, error: record<errors: list>, httpErrorMessage: string, httpErrorStatusCode: int, id: string, insertTime: string, kind: string, name: string, operationGroupId: string, operationType: string, progress: int, region: string, selfLink: string, startTime: string, status: string, statusMessage: string, targetId: string, targetLink: string, user: string, warnings: list<record>, zone: string>, selfLink: string, target: record<config: record<content: string>, imports: list<record>>, update: record<description: string, labels: list<record>, manifest: string>, updateTime: string>"
    deploymentmanager-deployments-patch: "record<clientOperationId: string, creationTimestamp: string, description: string, endTime: string, error: record<errors: list<record>>, httpErrorMessage: string, httpErrorStatusCode: int, id: string, insertTime: string, kind: string, name: string, operationGroupId: string, operationType: string, progress: int, region: string, selfLink: string, startTime: string, status: string, statusMessage: string, targetId: string, targetLink: string, user: string, warnings: table<code: string, data: list, message: string>, zone: string>"
    deploymentmanager-deployments-update: "record<clientOperationId: string, creationTimestamp: string, description: string, endTime: string, error: record<errors: list<record>>, httpErrorMessage: string, httpErrorStatusCode: int, id: string, insertTime: string, kind: string, name: string, operationGroupId: string, operationType: string, progress: int, region: string, selfLink: string, startTime: string, status: string, statusMessage: string, targetId: string, targetLink: string, user: string, warnings: table<code: string, data: list, message: string>, zone: string>"
    deploymentmanager-deployments-cancel-preview: "record<clientOperationId: string, creationTimestamp: string, description: string, endTime: string, error: record<errors: list<record>>, httpErrorMessage: string, httpErrorStatusCode: int, id: string, insertTime: string, kind: string, name: string, operationGroupId: string, operationType: string, progress: int, region: string, selfLink: string, startTime: string, status: string, statusMessage: string, targetId: string, targetLink: string, user: string, warnings: table<code: string, data: list, message: string>, zone: string>"
    deploymentmanager-manifests-list: "record<manifests: table<config: record, expandedConfig: string, id: string, imports: list, insertTime: string, layout: string, manifestSizeBytes: string, manifestSizeLimitBytes: string, name: string, selfLink: string>, nextPageToken: string>"
    deploymentmanager-manifests-get: "record<config: record<content: string>, expandedConfig: string, id: string, imports: table<content: string, name: string>, insertTime: string, layout: string, manifestSizeBytes: string, manifestSizeLimitBytes: string, name: string, selfLink: string>"
    deploymentmanager-resources-list: "record<nextPageToken: string, resources: table<accessControl: record, finalProperties: string, id: string, insertTime: string, manifest: string, name: string, properties: string, type: string, update: record, updateTime: string, url: string, warnings: list>>"
    deploymentmanager-resources-get: "record<accessControl: record<gcpIamPolicy: string>, finalProperties: string, id: string, insertTime: string, manifest: string, name: string, properties: string, type: string, update: record<accessControl: record<gcpIamPolicy: string>, error: record<errors: list>, finalProperties: string, intent: string, manifest: string, properties: string, state: string, warnings: list<record>>, updateTime: string, url: string, warnings: table<code: string, data: list, message: string>>"
    deploymentmanager-deployments-stop: "record<clientOperationId: string, creationTimestamp: string, description: string, endTime: string, error: record<errors: list<record>>, httpErrorMessage: string, httpErrorStatusCode: int, id: string, insertTime: string, kind: string, name: string, operationGroupId: string, operationType: string, progress: int, region: string, selfLink: string, startTime: string, status: string, statusMessage: string, targetId: string, targetLink: string, user: string, warnings: table<code: string, data: list, message: string>, zone: string>"
    deploymentmanager-deployments-get-iam-policy: "record<auditConfigs: table<auditLogConfigs: list, service: string>, bindings: table<condition: record, members: list, role: string>, etag: string, version: int>"
    deploymentmanager-deployments-set-iam-policy: "record<auditConfigs: table<auditLogConfigs: list, service: string>, bindings: table<condition: record, members: list, role: string>, etag: string, version: int>"
    deploymentmanager-deployments-test-iam-permissions: "record<permissions: list<string>>"
    deploymentmanager-operations-list: "record<nextPageToken: string, operations: table<clientOperationId: string, creationTimestamp: string, description: string, endTime: string, error: record, httpErrorMessage: string, httpErrorStatusCode: int, id: string, insertTime: string, kind: string, name: string, operationGroupId: string, operationType: string, progress: int, region: string, selfLink: string, startTime: string, status: string, statusMessage: string, targetId: string, targetLink: string, user: string, warnings: list, zone: string>>"
    deploymentmanager-operations-get: "record<clientOperationId: string, creationTimestamp: string, description: string, endTime: string, error: record<errors: list<record>>, httpErrorMessage: string, httpErrorStatusCode: int, id: string, insertTime: string, kind: string, name: string, operationGroupId: string, operationType: string, progress: int, region: string, selfLink: string, startTime: string, status: string, statusMessage: string, targetId: string, targetLink: string, user: string, warnings: table<code: string, data: list, message: string>, zone: string>"
    deploymentmanager-type-providers-list: "record<nextPageToken: string, typeProviders: table<collectionOverrides: list, credential: record, customCertificateAuthorityRoots: list, description: string, descriptorUrl: string, id: string, insertTime: string, labels: list, name: string, operation: record, options: record, selfLink: string>>"
    deploymentmanager-type-providers-insert: "record<clientOperationId: string, creationTimestamp: string, description: string, endTime: string, error: record<errors: list<record>>, httpErrorMessage: string, httpErrorStatusCode: int, id: string, insertTime: string, kind: string, name: string, operationGroupId: string, operationType: string, progress: int, region: string, selfLink: string, startTime: string, status: string, statusMessage: string, targetId: string, targetLink: string, user: string, warnings: table<code: string, data: list, message: string>, zone: string>"
    deploymentmanager-type-providers-delete: "record<clientOperationId: string, creationTimestamp: string, description: string, endTime: string, error: record<errors: list<record>>, httpErrorMessage: string, httpErrorStatusCode: int, id: string, insertTime: string, kind: string, name: string, operationGroupId: string, operationType: string, progress: int, region: string, selfLink: string, startTime: string, status: string, statusMessage: string, targetId: string, targetLink: string, user: string, warnings: table<code: string, data: list, message: string>, zone: string>"
    deploymentmanager-type-providers-get: "record<collectionOverrides: table<collection: string, options: record>, credential: record<basicAuth: record<password: string, user: string>, serviceAccount: record<email: string>, useProjectDefault: bool>, customCertificateAuthorityRoots: list<string>, description: string, descriptorUrl: string, id: string, insertTime: string, labels: table<key: string, value: string>, name: string, operation: record<clientOperationId: string, creationTimestamp: string, description: string, endTime: string, error: record<errors: list>, httpErrorMessage: string, httpErrorStatusCode: int, id: string, insertTime: string, kind: string, name: string, operationGroupId: string, operationType: string, progress: int, region: string, selfLink: string, startTime: string, status: string, statusMessage: string, targetId: string, targetLink: string, user: string, warnings: list<record>, zone: string>, options: record<asyncOptions: list<record>, inputMappings: list<record>, validationOptions: record<schemaValidation: string, undeclaredProperties: string>, virtualProperties: string>, selfLink: string>"
    deploymentmanager-type-providers-patch: "record<clientOperationId: string, creationTimestamp: string, description: string, endTime: string, error: record<errors: list<record>>, httpErrorMessage: string, httpErrorStatusCode: int, id: string, insertTime: string, kind: string, name: string, operationGroupId: string, operationType: string, progress: int, region: string, selfLink: string, startTime: string, status: string, statusMessage: string, targetId: string, targetLink: string, user: string, warnings: table<code: string, data: list, message: string>, zone: string>"
    deploymentmanager-type-providers-update: "record<clientOperationId: string, creationTimestamp: string, description: string, endTime: string, error: record<errors: list<record>>, httpErrorMessage: string, httpErrorStatusCode: int, id: string, insertTime: string, kind: string, name: string, operationGroupId: string, operationType: string, progress: int, region: string, selfLink: string, startTime: string, status: string, statusMessage: string, targetId: string, targetLink: string, user: string, warnings: table<code: string, data: list, message: string>, zone: string>"
    deploymentmanager-type-providers-list-types: "record<nextPageToken: string, types: table<description: string, documentationLink: string, kind: string, name: string, schema: record, selfLink: string, title: string>>"
    deploymentmanager-type-providers-get-type: "record<description: string, documentationLink: string, kind: string, name: string, schema: record<input: string, output: string>, selfLink: string, title: string>"
    deploymentmanager-types-list: "record<nextPageToken: string, types: table<base: record, description: string, id: string, insertTime: string, labels: list, name: string, operation: record, selfLink: string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["deploymentmanager-composite-types-list" "deploymentmanager-composite-types-insert" "deploymentmanager-composite-types-delete" "deploymentmanager-composite-types-get" "deploymentmanager-composite-types-patch" "deploymentmanager-composite-types-update" "deploymentmanager-deployments-list" "deploymentmanager-deployments-insert" "deploymentmanager-deployments-delete" "deploymentmanager-deployments-get" "deploymentmanager-deployments-patch" "deploymentmanager-deployments-update" "deploymentmanager-deployments-cancel-preview" "deploymentmanager-manifests-list" "deploymentmanager-manifests-get" "deploymentmanager-resources-list" "deploymentmanager-resources-get" "deploymentmanager-deployments-stop" "deploymentmanager-deployments-get-iam-policy" "deploymentmanager-deployments-set-iam-policy" "deploymentmanager-deployments-test-iam-permissions" "deploymentmanager-operations-list" "deploymentmanager-operations-get" "deploymentmanager-type-providers-list" "deploymentmanager-type-providers-insert" "deploymentmanager-type-providers-delete" "deploymentmanager-type-providers-get" "deploymentmanager-type-providers-patch" "deploymentmanager-type-providers-update" "deploymentmanager-type-providers-list-types" "deploymentmanager-type-providers-get-type" "deploymentmanager-types-list" "commands"] | sort) } | get name | first)
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

# Lists all composite types for Deployment Manager.
#
# GET /deploymentmanager/v2beta/projects/{project}/global/compositeTypes
# Returns: record<compositeTypes: table<description: string, id: string, insertTime: string, labels: list, name: string, operation: record, selfLink: string, status: string, templateContents: record>, nextPageToken: string>
# operationId: deploymentmanager.compositeTypes.list
export def "deploymentmanager-composite-types-list" [
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --filter: string # A filter expression that filters resources listed in the response. Most Compute resources support two types of filter expressions: expressions that support regular expressions and expressions that follow API improvement proposal AIP-160. If you want to use AIP-160, your expression must specify the field name, an operator, and the value that you want to use for filtering. The value must be a string, a number, or a boolean. The operator must be either `=`, `!=`, `>`, `<`, `<=`, `>=` or `:`. For example, if you are filtering Compute Engine instances, you can exclude instances named `example-instance` by specifying `name != example-instance`. The `:` operator can be used with string fields to match substrings. For non-string fields it is equivalent to the `=` operator. The `:*` comparison can be used to test whether a key has been defined. For example, to find all objects with `owner` label use: ``` labels.owner:* ``` You can also filter nested fields. For example, you could specify `scheduling.automaticRestart = false` to include instances only if they are not scheduled for automatic restarts. You can use filtering on nested fields to filter based on resource labels. To filter on multiple expressions, provide each separate expression within parentheses. For example: ``` (scheduling.automaticRestart = true) (cpuPlatform = "Intel Skylake") ``` By default, each expression is an `AND` expression. However, you can include `AND` and `OR` expressions explicitly. For example: ``` (cpuPlatform = "Intel Skylake") OR (cpuPlatform = "Intel Broadwell") AND (scheduling.automaticRestart = true) ``` If you want to use a regular expression, use the `eq` (equal) or `ne` (not equal) operator against a single un-parenthesized expression with or without quotes or against multiple parenthesized expressions. Examples: `fieldname eq unquoted literal` `fieldname eq 'single quoted literal'` `fieldname eq "double quoted literal"` `(fieldname1 eq literal) (fieldname2 ne "literal")` The literal value is interpreted as a regular expression using Google RE2 library syntax. The literal value must match the entire field. For example, to filter for instances that do not end with name "instance", you would use `name ne .*instance`.
  --max-results: int # The maximum number of results per page that should be returned. If the number of available results is larger than `maxResults`, Compute Engine returns a `nextPageToken` that can be used to get the next page of results in subsequent list requests. Acceptable values are `0` to `500`, inclusive. (Default: `500`)
  --order-by: string # Sorts list results by a certain order. By default, results are returned in alphanumerical order based on the resource name. You can also sort results in descending order based on the creation timestamp using `orderBy="creationTimestamp desc"`. This sorts results based on the `creationTimestamp` field in reverse chronological order (newest result first). Use this to sort resources like operations so that the newest operation is returned first. Currently, only sorting by `name` or `creationTimestamp desc` is supported.
  --page-token: string # Specifies a page token to use. Set `pageToken` to the `nextPageToken` returned by a previous list request to get the next page of results.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/deploymentmanager/v2beta/projects/{project}/global/compositeTypes"
    path_params: [{name: project, var: project}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: filter, var: filter}, {name: maxResults, var: max_results}, {name: orderBy, var: order_by}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, filter: $filter, max_results: $max_results, order_by: $order_by, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a composite type.
#
# POST /deploymentmanager/v2beta/projects/{project}/global/compositeTypes
# Returns: record<clientOperationId: string, creationTimestamp: string, description: string, endTime: string, error: record<errors: list<record>>, httpErrorMessage: string, httpErrorStatusCode: int, id: string, insertTime: string, kind: string, name: string, operationGroupId: string, operationType: string, progress: int, region: string, selfLink: string, startTime: string, status: string, statusMessage: string, targetId: string, targetLink: string, user: string, warnings: table<code: string, data: list, message: string>, zone: string>
# operationId: deploymentmanager.compositeTypes.insert
export def "deploymentmanager-composite-types-insert" [
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --description: string # An optional textual description of the resource; provided by the client when the resource is created.
  --id: string # format: uint64
  --insert-time: string # Output only. Creation timestamp in RFC3339 text format.
  --labels: list # Map of labels; provided by the client when the resource is created or updated. Specifically: Label keys must be between 1 and 63 characters long and must conform to the following regular expression: `[a-z]([-a-z0-9]*[a-z0-9])?` Label values must be between 0 and 63 characters long and must conform to the regular expression `([a-z]([-a-z0-9]*[a-z0-9])?)?`. — item shape: {key?: string, value?: string}
  --name: string # Name of the composite type, must follow the expression: `[a-z]([-a-z0-9_.]{0,61}[a-z0-9])?`.
  --operation: record # Represents an Operation resource. Google Compute Engine has three Operation resources: * [Global](/compute/docs/reference/rest/{$api_version}/globalOperations) * [Regional](/compute/docs/reference/rest/{$api_version}/regionOperations) * [Zonal](/compute/docs/reference/rest/{$api_version}/zoneOperations) You can use an operation resource to manage asynchronous API requests. For more information, read Handling API responses. Operations can be global, regional or zonal. - For global operations, use the `globalOperations` resource. - For regional operations, use the `regionOperations` resource. - For zonal operations, use the `zonalOperations` resource. For more information, read Global, Regional, and Zonal Resources. — shape: {clientOperationId?: string, creationTimestamp?: string, description?: string, endTime?: string, error?: record, httpErrorMessage?: string, httpErrorStatusCode?: int, id?: string, insertTime?: string, kind?: string, name?: string, operationGroupId?: string, operationType?: string, progress?: int, region?: string, selfLink?: string, startTime?: string, status?: "PENDING"|"RUNNING"|"DONE", statusMessage?: string, targetId?: string, targetLink?: string, user?: string, warnings?: list, zone?: string}
  --self-link: string # Output only. Server defined URL for the resource.
  --status: string@status-completer
  --template-contents: record # Files that make up the template contents of a template type. — shape: {imports?: list, interpreter?: "UNKNOWN_INTERPRETER"|"PYTHON"|"JINJA", mainTemplate?: string, schema?: string, template?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/deploymentmanager/v2beta/projects/{project}/global/compositeTypes"
    path_params: [{name: project, var: project}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: id, var: id}, {name: insertTime, var: insert_time}, {name: labels, var: labels}, {name: name, var: name}, {name: operation, var: operation}, {name: selfLink, var: self_link}, {name: status, var: status}, {name: templateContents, var: template_contents}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, description: $description, id: $id, insert_time: $insert_time, labels: $labels, name: $name, operation: $operation, self_link: $self_link, status: $status, template_contents: $template_contents
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a composite type.
#
# DELETE /deploymentmanager/v2beta/projects/{project}/global/compositeTypes/{compositeType}
# Returns: record<clientOperationId: string, creationTimestamp: string, description: string, endTime: string, error: record<errors: list<record>>, httpErrorMessage: string, httpErrorStatusCode: int, id: string, insertTime: string, kind: string, name: string, operationGroupId: string, operationType: string, progress: int, region: string, selfLink: string, startTime: string, status: string, statusMessage: string, targetId: string, targetLink: string, user: string, warnings: table<code: string, data: list, message: string>, zone: string>
# operationId: deploymentmanager.compositeTypes.delete
export def "deploymentmanager-composite-types-delete" [
  project: string
  composite_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
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
    path: "/deploymentmanager/v2beta/projects/{project}/global/compositeTypes/{compositeType}"
    path_params: [{name: project, var: project}, {name: compositeType, var: composite_type}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, composite_type: $composite_type, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about a specific composite type.
#
# GET /deploymentmanager/v2beta/projects/{project}/global/compositeTypes/{compositeType}
# Returns: record<description: string, id: string, insertTime: string, labels: table<key: string, value: string>, name: string, operation: record<clientOperationId: string, creationTimestamp: string, description: string, endTime: string, error: record<errors: list>, httpErrorMessage: string, httpErrorStatusCode: int, id: string, insertTime: string, kind: string, name: string, operationGroupId: string, operationType: string, progress: int, region: string, selfLink: string, startTime: string, status: string, statusMessage: string, targetId: string, targetLink: string, user: string, warnings: list<record>, zone: string>, selfLink: string, status: string, templateContents: record<imports: list<record>, interpreter: string, mainTemplate: string, schema: string, template: string>>
# operationId: deploymentmanager.compositeTypes.get
export def "deploymentmanager-composite-types-get" [
  project: string
  composite_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
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
    path: "/deploymentmanager/v2beta/projects/{project}/global/compositeTypes/{compositeType}"
    path_params: [{name: project, var: project}, {name: compositeType, var: composite_type}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, composite_type: $composite_type, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Patches a composite type.
#
# PATCH /deploymentmanager/v2beta/projects/{project}/global/compositeTypes/{compositeType}
# Returns: record<clientOperationId: string, creationTimestamp: string, description: string, endTime: string, error: record<errors: list<record>>, httpErrorMessage: string, httpErrorStatusCode: int, id: string, insertTime: string, kind: string, name: string, operationGroupId: string, operationType: string, progress: int, region: string, selfLink: string, startTime: string, status: string, statusMessage: string, targetId: string, targetLink: string, user: string, warnings: table<code: string, data: list, message: string>, zone: string>
# operationId: deploymentmanager.compositeTypes.patch
export def "deploymentmanager-composite-types-patch" [
  project: string
  composite_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --description: string # An optional textual description of the resource; provided by the client when the resource is created.
  --id: string # format: uint64
  --insert-time: string # Output only. Creation timestamp in RFC3339 text format.
  --labels: list # Map of labels; provided by the client when the resource is created or updated. Specifically: Label keys must be between 1 and 63 characters long and must conform to the following regular expression: `[a-z]([-a-z0-9]*[a-z0-9])?` Label values must be between 0 and 63 characters long and must conform to the regular expression `([a-z]([-a-z0-9]*[a-z0-9])?)?`. — item shape: {key?: string, value?: string}
  --name: string # Name of the composite type, must follow the expression: `[a-z]([-a-z0-9_.]{0,61}[a-z0-9])?`.
  --operation: record # Represents an Operation resource. Google Compute Engine has three Operation resources: * [Global](/compute/docs/reference/rest/{$api_version}/globalOperations) * [Regional](/compute/docs/reference/rest/{$api_version}/regionOperations) * [Zonal](/compute/docs/reference/rest/{$api_version}/zoneOperations) You can use an operation resource to manage asynchronous API requests. For more information, read Handling API responses. Operations can be global, regional or zonal. - For global operations, use the `globalOperations` resource. - For regional operations, use the `regionOperations` resource. - For zonal operations, use the `zonalOperations` resource. For more information, read Global, Regional, and Zonal Resources. — shape: {clientOperationId?: string, creationTimestamp?: string, description?: string, endTime?: string, error?: record, httpErrorMessage?: string, httpErrorStatusCode?: int, id?: string, insertTime?: string, kind?: string, name?: string, operationGroupId?: string, operationType?: string, progress?: int, region?: string, selfLink?: string, startTime?: string, status?: "PENDING"|"RUNNING"|"DONE", statusMessage?: string, targetId?: string, targetLink?: string, user?: string, warnings?: list, zone?: string}
  --self-link: string # Output only. Server defined URL for the resource.
  --status: string@status-completer
  --template-contents: record # Files that make up the template contents of a template type. — shape: {imports?: list, interpreter?: "UNKNOWN_INTERPRETER"|"PYTHON"|"JINJA", mainTemplate?: string, schema?: string, template?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/deploymentmanager/v2beta/projects/{project}/global/compositeTypes/{compositeType}"
    path_params: [{name: project, var: project}, {name: compositeType, var: composite_type}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: id, var: id}, {name: insertTime, var: insert_time}, {name: labels, var: labels}, {name: name, var: name}, {name: operation, var: operation}, {name: selfLink, var: self_link}, {name: status, var: status}, {name: templateContents, var: template_contents}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, composite_type: $composite_type, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, description: $description, id: $id, insert_time: $insert_time, labels: $labels, name: $name, operation: $operation, self_link: $self_link, status: $status, template_contents: $template_contents
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a composite type.
#
# PUT /deploymentmanager/v2beta/projects/{project}/global/compositeTypes/{compositeType}
# Returns: record<clientOperationId: string, creationTimestamp: string, description: string, endTime: string, error: record<errors: list<record>>, httpErrorMessage: string, httpErrorStatusCode: int, id: string, insertTime: string, kind: string, name: string, operationGroupId: string, operationType: string, progress: int, region: string, selfLink: string, startTime: string, status: string, statusMessage: string, targetId: string, targetLink: string, user: string, warnings: table<code: string, data: list, message: string>, zone: string>
# operationId: deploymentmanager.compositeTypes.update
export def "deploymentmanager-composite-types-update" [
  project: string
  composite_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --description: string # An optional textual description of the resource; provided by the client when the resource is created.
  --id: string # format: uint64
  --insert-time: string # Output only. Creation timestamp in RFC3339 text format.
  --labels: list # Map of labels; provided by the client when the resource is created or updated. Specifically: Label keys must be between 1 and 63 characters long and must conform to the following regular expression: `[a-z]([-a-z0-9]*[a-z0-9])?` Label values must be between 0 and 63 characters long and must conform to the regular expression `([a-z]([-a-z0-9]*[a-z0-9])?)?`. — item shape: {key?: string, value?: string}
  --name: string # Name of the composite type, must follow the expression: `[a-z]([-a-z0-9_.]{0,61}[a-z0-9])?`.
  --operation: record # Represents an Operation resource. Google Compute Engine has three Operation resources: * [Global](/compute/docs/reference/rest/{$api_version}/globalOperations) * [Regional](/compute/docs/reference/rest/{$api_version}/regionOperations) * [Zonal](/compute/docs/reference/rest/{$api_version}/zoneOperations) You can use an operation resource to manage asynchronous API requests. For more information, read Handling API responses. Operations can be global, regional or zonal. - For global operations, use the `globalOperations` resource. - For regional operations, use the `regionOperations` resource. - For zonal operations, use the `zonalOperations` resource. For more information, read Global, Regional, and Zonal Resources. — shape: {clientOperationId?: string, creationTimestamp?: string, description?: string, endTime?: string, error?: record, httpErrorMessage?: string, httpErrorStatusCode?: int, id?: string, insertTime?: string, kind?: string, name?: string, operationGroupId?: string, operationType?: string, progress?: int, region?: string, selfLink?: string, startTime?: string, status?: "PENDING"|"RUNNING"|"DONE", statusMessage?: string, targetId?: string, targetLink?: string, user?: string, warnings?: list, zone?: string}
  --self-link: string # Output only. Server defined URL for the resource.
  --status: string@status-completer
  --template-contents: record # Files that make up the template contents of a template type. — shape: {imports?: list, interpreter?: "UNKNOWN_INTERPRETER"|"PYTHON"|"JINJA", mainTemplate?: string, schema?: string, template?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/deploymentmanager/v2beta/projects/{project}/global/compositeTypes/{compositeType}"
    path_params: [{name: project, var: project}, {name: compositeType, var: composite_type}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: id, var: id}, {name: insertTime, var: insert_time}, {name: labels, var: labels}, {name: name, var: name}, {name: operation, var: operation}, {name: selfLink, var: self_link}, {name: status, var: status}, {name: templateContents, var: template_contents}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, composite_type: $composite_type, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, description: $description, id: $id, insert_time: $insert_time, labels: $labels, name: $name, operation: $operation, self_link: $self_link, status: $status, template_contents: $template_contents
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all deployments for a given project.
#
# GET /deploymentmanager/v2beta/projects/{project}/global/deployments
# Returns: record<deployments: table<description: string, fingerprint: string, id: string, insertTime: string, labels: list, manifest: string, name: string, operation: record, selfLink: string, target: record, update: record, updateTime: string>, nextPageToken: string>
# operationId: deploymentmanager.deployments.list
export def "deploymentmanager-deployments-list" [
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --filter: string # A filter expression that filters resources listed in the response. Most Compute resources support two types of filter expressions: expressions that support regular expressions and expressions that follow API improvement proposal AIP-160. If you want to use AIP-160, your expression must specify the field name, an operator, and the value that you want to use for filtering. The value must be a string, a number, or a boolean. The operator must be either `=`, `!=`, `>`, `<`, `<=`, `>=` or `:`. For example, if you are filtering Compute Engine instances, you can exclude instances named `example-instance` by specifying `name != example-instance`. The `:` operator can be used with string fields to match substrings. For non-string fields it is equivalent to the `=` operator. The `:*` comparison can be used to test whether a key has been defined. For example, to find all objects with `owner` label use: ``` labels.owner:* ``` You can also filter nested fields. For example, you could specify `scheduling.automaticRestart = false` to include instances only if they are not scheduled for automatic restarts. You can use filtering on nested fields to filter based on resource labels. To filter on multiple expressions, provide each separate expression within parentheses. For example: ``` (scheduling.automaticRestart = true) (cpuPlatform = "Intel Skylake") ``` By default, each expression is an `AND` expression. However, you can include `AND` and `OR` expressions explicitly. For example: ``` (cpuPlatform = "Intel Skylake") OR (cpuPlatform = "Intel Broadwell") AND (scheduling.automaticRestart = true) ``` If you want to use a regular expression, use the `eq` (equal) or `ne` (not equal) operator against a single un-parenthesized expression with or without quotes or against multiple parenthesized expressions. Examples: `fieldname eq unquoted literal` `fieldname eq 'single quoted literal'` `fieldname eq "double quoted literal"` `(fieldname1 eq literal) (fieldname2 ne "literal")` The literal value is interpreted as a regular expression using Google RE2 library syntax. The literal value must match the entire field. For example, to filter for instances that do not end with name "instance", you would use `name ne .*instance`.
  --max-results: int # The maximum number of results per page that should be returned. If the number of available results is larger than `maxResults`, Compute Engine returns a `nextPageToken` that can be used to get the next page of results in subsequent list requests. Acceptable values are `0` to `500`, inclusive. (Default: `500`)
  --order-by: string # Sorts list results by a certain order. By default, results are returned in alphanumerical order based on the resource name. You can also sort results in descending order based on the creation timestamp using `orderBy="creationTimestamp desc"`. This sorts results based on the `creationTimestamp` field in reverse chronological order (newest result first). Use this to sort resources like operations so that the newest operation is returned first. Currently, only sorting by `name` or `creationTimestamp desc` is supported.
  --page-token: string # Specifies a page token to use. Set `pageToken` to the `nextPageToken` returned by a previous list request to get the next page of results.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/deploymentmanager/v2beta/projects/{project}/global/deployments"
    path_params: [{name: project, var: project}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: filter, var: filter}, {name: maxResults, var: max_results}, {name: orderBy, var: order_by}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, filter: $filter, max_results: $max_results, order_by: $order_by, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a deployment and all of the resources described by the deployment manifest.
#
# POST /deploymentmanager/v2beta/projects/{project}/global/deployments
# Returns: record<clientOperationId: string, creationTimestamp: string, description: string, endTime: string, error: record<errors: list<record>>, httpErrorMessage: string, httpErrorStatusCode: int, id: string, insertTime: string, kind: string, name: string, operationGroupId: string, operationType: string, progress: int, region: string, selfLink: string, startTime: string, status: string, statusMessage: string, targetId: string, targetLink: string, user: string, warnings: table<code: string, data: list, message: string>, zone: string>
# operationId: deploymentmanager.deployments.insert
export def "deploymentmanager-deployments-insert" [
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --create-policy: string@create-policy-completer # Sets the policy to use for creating new resources.
  --preview: oneof<nothing, bool> # If set to true, creates a deployment and creates "shell" resources but does not actually instantiate these resources. This allows you to preview what your deployment looks like. After previewing a deployment, you can deploy your resources by making a request with the `update()` method or you can use the `cancelPreview()` method to cancel the preview altogether. Note that the deployment will still exist after you cancel the preview and you must separately delete this deployment if you want to remove it.
  --description: string # An optional user-provided description of the deployment.
  --fingerprint: string # Provides a fingerprint to use in requests to modify a deployment, such as `update()`, `stop()`, and `cancelPreview()` requests. A fingerprint is a randomly generated value that must be provided with `update()`, `stop()`, and `cancelPreview()` requests to perform optimistic locking. This ensures optimistic concurrency so that only one request happens at a time. The fingerprint is initially generated by Deployment Manager and changes after every request to modify data. To get the latest fingerprint value, perform a `get()` request to a deployment. (format: byte)
  --id: string # format: uint64
  --insert-time: string # Output only. Creation timestamp in RFC3339 text format.
  --labels: list # Map of One Platform labels; provided by the client when the resource is created or updated. Specifically: Label keys must be between 1 and 63 characters long and must conform to the following regular expression: `[a-z]([-a-z0-9]*[a-z0-9])?` Label values must be between 0 and 63 characters long and must conform to the regular expression `([a-z]([-a-z0-9]*[a-z0-9])?)?`. — item shape: {key?: string, value?: string}
  --manifest: string # Output only. URL of the manifest representing the last manifest that was successfully deployed. If no manifest has been successfully deployed, this field will be absent.
  --name: string # Name of the resource; provided by the client when the resource is created. The name must be 1-63 characters long, and comply with RFC1035. Specifically, the name must be 1-63 characters long and match the regular expression `[a-z]([-a-z0-9]*[a-z0-9])?` which means the first character must be a lowercase letter, and all following characters must be a dash, lowercase letter, or digit, except the last character, which cannot be a dash.
  --operation: record # Represents an Operation resource. Google Compute Engine has three Operation resources: * [Global](/compute/docs/reference/rest/{$api_version}/globalOperations) * [Regional](/compute/docs/reference/rest/{$api_version}/regionOperations) * [Zonal](/compute/docs/reference/rest/{$api_version}/zoneOperations) You can use an operation resource to manage asynchronous API requests. For more information, read Handling API responses. Operations can be global, regional or zonal. - For global operations, use the `globalOperations` resource. - For regional operations, use the `regionOperations` resource. - For zonal operations, use the `zonalOperations` resource. For more information, read Global, Regional, and Zonal Resources. — shape: {clientOperationId?: string, creationTimestamp?: string, description?: string, endTime?: string, error?: record, httpErrorMessage?: string, httpErrorStatusCode?: int, id?: string, insertTime?: string, kind?: string, name?: string, operationGroupId?: string, operationType?: string, progress?: int, region?: string, selfLink?: string, startTime?: string, status?: "PENDING"|"RUNNING"|"DONE", statusMessage?: string, targetId?: string, targetLink?: string, user?: string, warnings?: list, zone?: string}
  --self-link: string # Output only. Server defined URL for the resource.
  --target: record # shape: {config?: record, imports?: list}
  --update: record # shape: {description?: string, labels?: list, manifest?: string}
  --update-time: string # Output only. Update timestamp in RFC3339 text format.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/deploymentmanager/v2beta/projects/{project}/global/deployments"
    path_params: [{name: project, var: project}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: createPolicy, var: create_policy}, {name: preview, var: preview}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: fingerprint, var: fingerprint}, {name: id, var: id}, {name: insertTime, var: insert_time}, {name: labels, var: labels}, {name: manifest, var: manifest}, {name: name, var: name}, {name: operation, var: operation}, {name: selfLink, var: self_link}, {name: target, var: target}, {name: update, var: update}, {name: updateTime, var: update_time}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, create_policy: $create_policy, preview: $preview, description: $description, fingerprint: $fingerprint, id: $id, insert_time: $insert_time, labels: $labels, manifest: $manifest, name: $name, operation: $operation, self_link: $self_link, target: $target, update: $update, update_time: $update_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a deployment and all of the resources in the deployment.
#
# DELETE /deploymentmanager/v2beta/projects/{project}/global/deployments/{deployment}
# Returns: record<clientOperationId: string, creationTimestamp: string, description: string, endTime: string, error: record<errors: list<record>>, httpErrorMessage: string, httpErrorStatusCode: int, id: string, insertTime: string, kind: string, name: string, operationGroupId: string, operationType: string, progress: int, region: string, selfLink: string, startTime: string, status: string, statusMessage: string, targetId: string, targetLink: string, user: string, warnings: table<code: string, data: list, message: string>, zone: string>
# operationId: deploymentmanager.deployments.delete
export def "deploymentmanager-deployments-delete" [
  project: string
  deployment: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --delete-policy: string@delete-policy-completer # Sets the policy to use for deleting resources.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/deploymentmanager/v2beta/projects/{project}/global/deployments/{deployment}"
    path_params: [{name: project, var: project}, {name: deployment, var: deployment}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: deletePolicy, var: delete_policy}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, deployment: $deployment, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, delete_policy: $delete_policy
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about a specific deployment.
#
# GET /deploymentmanager/v2beta/projects/{project}/global/deployments/{deployment}
# Returns: record<description: string, fingerprint: string, id: string, insertTime: string, labels: table<key: string, value: string>, manifest: string, name: string, operation: record<clientOperationId: string, creationTimestamp: string, description: string, endTime: string, error: record<errors: list>, httpErrorMessage: string, httpErrorStatusCode: int, id: string, insertTime: string, kind: string, name: string, operationGroupId: string, operationType: string, progress: int, region: string, selfLink: string, startTime: string, status: string, statusMessage: string, targetId: string, targetLink: string, user: string, warnings: list<record>, zone: string>, selfLink: string, target: record<config: record<content: string>, imports: list<record>>, update: record<description: string, labels: list<record>, manifest: string>, updateTime: string>
# operationId: deploymentmanager.deployments.get
export def "deploymentmanager-deployments-get" [
  project: string
  deployment: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
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
    path: "/deploymentmanager/v2beta/projects/{project}/global/deployments/{deployment}"
    path_params: [{name: project, var: project}, {name: deployment, var: deployment}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, deployment: $deployment, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Patches a deployment and all of the resources described by the deployment manifest.
#
# PATCH /deploymentmanager/v2beta/projects/{project}/global/deployments/{deployment}
# Returns: record<clientOperationId: string, creationTimestamp: string, description: string, endTime: string, error: record<errors: list<record>>, httpErrorMessage: string, httpErrorStatusCode: int, id: string, insertTime: string, kind: string, name: string, operationGroupId: string, operationType: string, progress: int, region: string, selfLink: string, startTime: string, status: string, statusMessage: string, targetId: string, targetLink: string, user: string, warnings: table<code: string, data: list, message: string>, zone: string>
# operationId: deploymentmanager.deployments.patch
export def "deploymentmanager-deployments-patch" [
  project: string
  deployment: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --create-policy: string@create-policy-completer # Sets the policy to use for creating new resources.
  --delete-policy: string@delete-policy-completer # Sets the policy to use for deleting resources.
  --preview: oneof<nothing, bool> # If set to true, updates the deployment and creates and updates the "shell" resources but does not actually alter or instantiate these resources. This allows you to preview what your deployment will look like. You can use this intent to preview how an update would affect your deployment. You must provide a `target.config` with a configuration if this is set to true. After previewing a deployment, you can deploy your resources by making a request with the `update()` or you can `cancelPreview()` to remove the preview altogether. Note that the deployment will still exist after you cancel the preview and you must separately delete this deployment if you want to remove it.
  --description: string # An optional user-provided description of the deployment.
  --fingerprint: string # Provides a fingerprint to use in requests to modify a deployment, such as `update()`, `stop()`, and `cancelPreview()` requests. A fingerprint is a randomly generated value that must be provided with `update()`, `stop()`, and `cancelPreview()` requests to perform optimistic locking. This ensures optimistic concurrency so that only one request happens at a time. The fingerprint is initially generated by Deployment Manager and changes after every request to modify data. To get the latest fingerprint value, perform a `get()` request to a deployment. (format: byte)
  --id: string # format: uint64
  --insert-time: string # Output only. Creation timestamp in RFC3339 text format.
  --labels: list # Map of One Platform labels; provided by the client when the resource is created or updated. Specifically: Label keys must be between 1 and 63 characters long and must conform to the following regular expression: `[a-z]([-a-z0-9]*[a-z0-9])?` Label values must be between 0 and 63 characters long and must conform to the regular expression `([a-z]([-a-z0-9]*[a-z0-9])?)?`. — item shape: {key?: string, value?: string}
  --manifest: string # Output only. URL of the manifest representing the last manifest that was successfully deployed. If no manifest has been successfully deployed, this field will be absent.
  --name: string # Name of the resource; provided by the client when the resource is created. The name must be 1-63 characters long, and comply with RFC1035. Specifically, the name must be 1-63 characters long and match the regular expression `[a-z]([-a-z0-9]*[a-z0-9])?` which means the first character must be a lowercase letter, and all following characters must be a dash, lowercase letter, or digit, except the last character, which cannot be a dash.
  --operation: record # Represents an Operation resource. Google Compute Engine has three Operation resources: * [Global](/compute/docs/reference/rest/{$api_version}/globalOperations) * [Regional](/compute/docs/reference/rest/{$api_version}/regionOperations) * [Zonal](/compute/docs/reference/rest/{$api_version}/zoneOperations) You can use an operation resource to manage asynchronous API requests. For more information, read Handling API responses. Operations can be global, regional or zonal. - For global operations, use the `globalOperations` resource. - For regional operations, use the `regionOperations` resource. - For zonal operations, use the `zonalOperations` resource. For more information, read Global, Regional, and Zonal Resources. — shape: {clientOperationId?: string, creationTimestamp?: string, description?: string, endTime?: string, error?: record, httpErrorMessage?: string, httpErrorStatusCode?: int, id?: string, insertTime?: string, kind?: string, name?: string, operationGroupId?: string, operationType?: string, progress?: int, region?: string, selfLink?: string, startTime?: string, status?: "PENDING"|"RUNNING"|"DONE", statusMessage?: string, targetId?: string, targetLink?: string, user?: string, warnings?: list, zone?: string}
  --self-link: string # Output only. Server defined URL for the resource.
  --target: record # shape: {config?: record, imports?: list}
  --update: record # shape: {description?: string, labels?: list, manifest?: string}
  --update-time: string # Output only. Update timestamp in RFC3339 text format.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/deploymentmanager/v2beta/projects/{project}/global/deployments/{deployment}"
    path_params: [{name: project, var: project}, {name: deployment, var: deployment}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: createPolicy, var: create_policy}, {name: deletePolicy, var: delete_policy}, {name: preview, var: preview}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: fingerprint, var: fingerprint}, {name: id, var: id}, {name: insertTime, var: insert_time}, {name: labels, var: labels}, {name: manifest, var: manifest}, {name: name, var: name}, {name: operation, var: operation}, {name: selfLink, var: self_link}, {name: target, var: target}, {name: update, var: update}, {name: updateTime, var: update_time}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, deployment: $deployment, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, create_policy: $create_policy, delete_policy: $delete_policy, preview: $preview, description: $description, fingerprint: $fingerprint, id: $id, insert_time: $insert_time, labels: $labels, manifest: $manifest, name: $name, operation: $operation, self_link: $self_link, target: $target, update: $update, update_time: $update_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a deployment and all of the resources described by the deployment manifest.
#
# PUT /deploymentmanager/v2beta/projects/{project}/global/deployments/{deployment}
# Returns: record<clientOperationId: string, creationTimestamp: string, description: string, endTime: string, error: record<errors: list<record>>, httpErrorMessage: string, httpErrorStatusCode: int, id: string, insertTime: string, kind: string, name: string, operationGroupId: string, operationType: string, progress: int, region: string, selfLink: string, startTime: string, status: string, statusMessage: string, targetId: string, targetLink: string, user: string, warnings: table<code: string, data: list, message: string>, zone: string>
# operationId: deploymentmanager.deployments.update
export def "deploymentmanager-deployments-update" [
  project: string
  deployment: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --create-policy: string@create-policy-completer # Sets the policy to use for creating new resources.
  --delete-policy: string@delete-policy-completer # Sets the policy to use for deleting resources.
  --preview: oneof<nothing, bool> # If set to true, updates the deployment and creates and updates the "shell" resources but does not actually alter or instantiate these resources. This allows you to preview what your deployment will look like. You can use this intent to preview how an update would affect your deployment. You must provide a `target.config` with a configuration if this is set to true. After previewing a deployment, you can deploy your resources by making a request with the `update()` or you can `cancelPreview()` to remove the preview altogether. Note that the deployment will still exist after you cancel the preview and you must separately delete this deployment if you want to remove it.
  --description: string # An optional user-provided description of the deployment.
  --fingerprint: string # Provides a fingerprint to use in requests to modify a deployment, such as `update()`, `stop()`, and `cancelPreview()` requests. A fingerprint is a randomly generated value that must be provided with `update()`, `stop()`, and `cancelPreview()` requests to perform optimistic locking. This ensures optimistic concurrency so that only one request happens at a time. The fingerprint is initially generated by Deployment Manager and changes after every request to modify data. To get the latest fingerprint value, perform a `get()` request to a deployment. (format: byte)
  --id: string # format: uint64
  --insert-time: string # Output only. Creation timestamp in RFC3339 text format.
  --labels: list # Map of One Platform labels; provided by the client when the resource is created or updated. Specifically: Label keys must be between 1 and 63 characters long and must conform to the following regular expression: `[a-z]([-a-z0-9]*[a-z0-9])?` Label values must be between 0 and 63 characters long and must conform to the regular expression `([a-z]([-a-z0-9]*[a-z0-9])?)?`. — item shape: {key?: string, value?: string}
  --manifest: string # Output only. URL of the manifest representing the last manifest that was successfully deployed. If no manifest has been successfully deployed, this field will be absent.
  --name: string # Name of the resource; provided by the client when the resource is created. The name must be 1-63 characters long, and comply with RFC1035. Specifically, the name must be 1-63 characters long and match the regular expression `[a-z]([-a-z0-9]*[a-z0-9])?` which means the first character must be a lowercase letter, and all following characters must be a dash, lowercase letter, or digit, except the last character, which cannot be a dash.
  --operation: record # Represents an Operation resource. Google Compute Engine has three Operation resources: * [Global](/compute/docs/reference/rest/{$api_version}/globalOperations) * [Regional](/compute/docs/reference/rest/{$api_version}/regionOperations) * [Zonal](/compute/docs/reference/rest/{$api_version}/zoneOperations) You can use an operation resource to manage asynchronous API requests. For more information, read Handling API responses. Operations can be global, regional or zonal. - For global operations, use the `globalOperations` resource. - For regional operations, use the `regionOperations` resource. - For zonal operations, use the `zonalOperations` resource. For more information, read Global, Regional, and Zonal Resources. — shape: {clientOperationId?: string, creationTimestamp?: string, description?: string, endTime?: string, error?: record, httpErrorMessage?: string, httpErrorStatusCode?: int, id?: string, insertTime?: string, kind?: string, name?: string, operationGroupId?: string, operationType?: string, progress?: int, region?: string, selfLink?: string, startTime?: string, status?: "PENDING"|"RUNNING"|"DONE", statusMessage?: string, targetId?: string, targetLink?: string, user?: string, warnings?: list, zone?: string}
  --self-link: string # Output only. Server defined URL for the resource.
  --target: record # shape: {config?: record, imports?: list}
  --update: record # shape: {description?: string, labels?: list, manifest?: string}
  --update-time: string # Output only. Update timestamp in RFC3339 text format.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/deploymentmanager/v2beta/projects/{project}/global/deployments/{deployment}"
    path_params: [{name: project, var: project}, {name: deployment, var: deployment}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: createPolicy, var: create_policy}, {name: deletePolicy, var: delete_policy}, {name: preview, var: preview}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: fingerprint, var: fingerprint}, {name: id, var: id}, {name: insertTime, var: insert_time}, {name: labels, var: labels}, {name: manifest, var: manifest}, {name: name, var: name}, {name: operation, var: operation}, {name: selfLink, var: self_link}, {name: target, var: target}, {name: update, var: update}, {name: updateTime, var: update_time}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, deployment: $deployment, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, create_policy: $create_policy, delete_policy: $delete_policy, preview: $preview, description: $description, fingerprint: $fingerprint, id: $id, insert_time: $insert_time, labels: $labels, manifest: $manifest, name: $name, operation: $operation, self_link: $self_link, target: $target, update: $update, update_time: $update_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancels and removes the preview currently associated with the deployment.
#
# POST /deploymentmanager/v2beta/projects/{project}/global/deployments/{deployment}/cancelPreview
# Returns: record<clientOperationId: string, creationTimestamp: string, description: string, endTime: string, error: record<errors: list<record>>, httpErrorMessage: string, httpErrorStatusCode: int, id: string, insertTime: string, kind: string, name: string, operationGroupId: string, operationType: string, progress: int, region: string, selfLink: string, startTime: string, status: string, statusMessage: string, targetId: string, targetLink: string, user: string, warnings: table<code: string, data: list, message: string>, zone: string>
# operationId: deploymentmanager.deployments.cancelPreview
export def "deploymentmanager-deployments-cancel-preview" [
  project: string
  deployment: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --fingerprint: string # Specifies a fingerprint for `cancelPreview()` requests. A fingerprint is a randomly generated value that must be provided in `cancelPreview()` requests to perform optimistic locking. This ensures optimistic concurrency so that the deployment does not have conflicting requests (e.g. if someone attempts to make a new update request while another user attempts to cancel a preview, this would prevent one of the requests). The fingerprint is initially generated by Deployment Manager and changes after every request to modify a deployment. To get the latest fingerprint value, perform a `get()` request on the deployment. (format: byte)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/deploymentmanager/v2beta/projects/{project}/global/deployments/{deployment}/cancelPreview"
    path_params: [{name: project, var: project}, {name: deployment, var: deployment}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: fingerprint, var: fingerprint}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, deployment: $deployment, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, fingerprint: $fingerprint
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all manifests for a given deployment.
#
# GET /deploymentmanager/v2beta/projects/{project}/global/deployments/{deployment}/manifests
# Returns: record<manifests: table<config: record, expandedConfig: string, id: string, imports: list, insertTime: string, layout: string, manifestSizeBytes: string, manifestSizeLimitBytes: string, name: string, selfLink: string>, nextPageToken: string>
# operationId: deploymentmanager.manifests.list
export def "deploymentmanager-manifests-list" [
  project: string
  deployment: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --filter: string # A filter expression that filters resources listed in the response. Most Compute resources support two types of filter expressions: expressions that support regular expressions and expressions that follow API improvement proposal AIP-160. If you want to use AIP-160, your expression must specify the field name, an operator, and the value that you want to use for filtering. The value must be a string, a number, or a boolean. The operator must be either `=`, `!=`, `>`, `<`, `<=`, `>=` or `:`. For example, if you are filtering Compute Engine instances, you can exclude instances named `example-instance` by specifying `name != example-instance`. The `:` operator can be used with string fields to match substrings. For non-string fields it is equivalent to the `=` operator. The `:*` comparison can be used to test whether a key has been defined. For example, to find all objects with `owner` label use: ``` labels.owner:* ``` You can also filter nested fields. For example, you could specify `scheduling.automaticRestart = false` to include instances only if they are not scheduled for automatic restarts. You can use filtering on nested fields to filter based on resource labels. To filter on multiple expressions, provide each separate expression within parentheses. For example: ``` (scheduling.automaticRestart = true) (cpuPlatform = "Intel Skylake") ``` By default, each expression is an `AND` expression. However, you can include `AND` and `OR` expressions explicitly. For example: ``` (cpuPlatform = "Intel Skylake") OR (cpuPlatform = "Intel Broadwell") AND (scheduling.automaticRestart = true) ``` If you want to use a regular expression, use the `eq` (equal) or `ne` (not equal) operator against a single un-parenthesized expression with or without quotes or against multiple parenthesized expressions. Examples: `fieldname eq unquoted literal` `fieldname eq 'single quoted literal'` `fieldname eq "double quoted literal"` `(fieldname1 eq literal) (fieldname2 ne "literal")` The literal value is interpreted as a regular expression using Google RE2 library syntax. The literal value must match the entire field. For example, to filter for instances that do not end with name "instance", you would use `name ne .*instance`.
  --max-results: int # The maximum number of results per page that should be returned. If the number of available results is larger than `maxResults`, Compute Engine returns a `nextPageToken` that can be used to get the next page of results in subsequent list requests. Acceptable values are `0` to `500`, inclusive. (Default: `500`)
  --order-by: string # Sorts list results by a certain order. By default, results are returned in alphanumerical order based on the resource name. You can also sort results in descending order based on the creation timestamp using `orderBy="creationTimestamp desc"`. This sorts results based on the `creationTimestamp` field in reverse chronological order (newest result first). Use this to sort resources like operations so that the newest operation is returned first. Currently, only sorting by `name` or `creationTimestamp desc` is supported.
  --page-token: string # Specifies a page token to use. Set `pageToken` to the `nextPageToken` returned by a previous list request to get the next page of results.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/deploymentmanager/v2beta/projects/{project}/global/deployments/{deployment}/manifests"
    path_params: [{name: project, var: project}, {name: deployment, var: deployment}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: filter, var: filter}, {name: maxResults, var: max_results}, {name: orderBy, var: order_by}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, deployment: $deployment, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, filter: $filter, max_results: $max_results, order_by: $order_by, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about a specific manifest.
#
# GET /deploymentmanager/v2beta/projects/{project}/global/deployments/{deployment}/manifests/{manifest}
# Returns: record<config: record<content: string>, expandedConfig: string, id: string, imports: table<content: string, name: string>, insertTime: string, layout: string, manifestSizeBytes: string, manifestSizeLimitBytes: string, name: string, selfLink: string>
# operationId: deploymentmanager.manifests.get
export def "deploymentmanager-manifests-get" [
  project: string
  deployment: string
  manifest: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
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
    path: "/deploymentmanager/v2beta/projects/{project}/global/deployments/{deployment}/manifests/{manifest}"
    path_params: [{name: project, var: project}, {name: deployment, var: deployment}, {name: manifest, var: manifest}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, deployment: $deployment, manifest: $manifest, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all resources in a given deployment.
#
# GET /deploymentmanager/v2beta/projects/{project}/global/deployments/{deployment}/resources
# Returns: record<nextPageToken: string, resources: table<accessControl: record, finalProperties: string, id: string, insertTime: string, manifest: string, name: string, properties: string, type: string, update: record, updateTime: string, url: string, warnings: list>>
# operationId: deploymentmanager.resources.list
export def "deploymentmanager-resources-list" [
  project: string
  deployment: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --filter: string # A filter expression that filters resources listed in the response. Most Compute resources support two types of filter expressions: expressions that support regular expressions and expressions that follow API improvement proposal AIP-160. If you want to use AIP-160, your expression must specify the field name, an operator, and the value that you want to use for filtering. The value must be a string, a number, or a boolean. The operator must be either `=`, `!=`, `>`, `<`, `<=`, `>=` or `:`. For example, if you are filtering Compute Engine instances, you can exclude instances named `example-instance` by specifying `name != example-instance`. The `:` operator can be used with string fields to match substrings. For non-string fields it is equivalent to the `=` operator. The `:*` comparison can be used to test whether a key has been defined. For example, to find all objects with `owner` label use: ``` labels.owner:* ``` You can also filter nested fields. For example, you could specify `scheduling.automaticRestart = false` to include instances only if they are not scheduled for automatic restarts. You can use filtering on nested fields to filter based on resource labels. To filter on multiple expressions, provide each separate expression within parentheses. For example: ``` (scheduling.automaticRestart = true) (cpuPlatform = "Intel Skylake") ``` By default, each expression is an `AND` expression. However, you can include `AND` and `OR` expressions explicitly. For example: ``` (cpuPlatform = "Intel Skylake") OR (cpuPlatform = "Intel Broadwell") AND (scheduling.automaticRestart = true) ``` If you want to use a regular expression, use the `eq` (equal) or `ne` (not equal) operator against a single un-parenthesized expression with or without quotes or against multiple parenthesized expressions. Examples: `fieldname eq unquoted literal` `fieldname eq 'single quoted literal'` `fieldname eq "double quoted literal"` `(fieldname1 eq literal) (fieldname2 ne "literal")` The literal value is interpreted as a regular expression using Google RE2 library syntax. The literal value must match the entire field. For example, to filter for instances that do not end with name "instance", you would use `name ne .*instance`.
  --max-results: int # The maximum number of results per page that should be returned. If the number of available results is larger than `maxResults`, Compute Engine returns a `nextPageToken` that can be used to get the next page of results in subsequent list requests. Acceptable values are `0` to `500`, inclusive. (Default: `500`)
  --order-by: string # Sorts list results by a certain order. By default, results are returned in alphanumerical order based on the resource name. You can also sort results in descending order based on the creation timestamp using `orderBy="creationTimestamp desc"`. This sorts results based on the `creationTimestamp` field in reverse chronological order (newest result first). Use this to sort resources like operations so that the newest operation is returned first. Currently, only sorting by `name` or `creationTimestamp desc` is supported.
  --page-token: string # Specifies a page token to use. Set `pageToken` to the `nextPageToken` returned by a previous list request to get the next page of results.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/deploymentmanager/v2beta/projects/{project}/global/deployments/{deployment}/resources"
    path_params: [{name: project, var: project}, {name: deployment, var: deployment}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: filter, var: filter}, {name: maxResults, var: max_results}, {name: orderBy, var: order_by}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, deployment: $deployment, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, filter: $filter, max_results: $max_results, order_by: $order_by, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about a single resource.
#
# GET /deploymentmanager/v2beta/projects/{project}/global/deployments/{deployment}/resources/{resource}
# Returns: record<accessControl: record<gcpIamPolicy: string>, finalProperties: string, id: string, insertTime: string, manifest: string, name: string, properties: string, type: string, update: record<accessControl: record<gcpIamPolicy: string>, error: record<errors: list>, finalProperties: string, intent: string, manifest: string, properties: string, state: string, warnings: list<record>>, updateTime: string, url: string, warnings: table<code: string, data: list, message: string>>
# operationId: deploymentmanager.resources.get
export def "deploymentmanager-resources-get" [
  project: string
  deployment: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/deploymentmanager/v2beta/projects/{project}/global/deployments/{deployment}/resources/{resource}"
    path_params: [{name: project, var: project}, {name: deployment, var: deployment}, {name: resource, var: resource}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, deployment: $deployment, resource: $resource, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stops an ongoing operation. This does not roll back any work that has already been completed, but prevents any new work from being started.
#
# POST /deploymentmanager/v2beta/projects/{project}/global/deployments/{deployment}/stop
# Returns: record<clientOperationId: string, creationTimestamp: string, description: string, endTime: string, error: record<errors: list<record>>, httpErrorMessage: string, httpErrorStatusCode: int, id: string, insertTime: string, kind: string, name: string, operationGroupId: string, operationType: string, progress: int, region: string, selfLink: string, startTime: string, status: string, statusMessage: string, targetId: string, targetLink: string, user: string, warnings: table<code: string, data: list, message: string>, zone: string>
# operationId: deploymentmanager.deployments.stop
export def "deploymentmanager-deployments-stop" [
  project: string
  deployment: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --fingerprint: string # Specifies a fingerprint for `stop()` requests. A fingerprint is a randomly generated value that must be provided in `stop()` requests to perform optimistic locking. This ensures optimistic concurrency so that the deployment does not have conflicting requests (e.g. if someone attempts to make a new update request while another user attempts to stop an ongoing update request, this would prevent a collision). The fingerprint is initially generated by Deployment Manager and changes after every request to modify a deployment. To get the latest fingerprint value, perform a `get()` request on the deployment. (format: byte)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/deploymentmanager/v2beta/projects/{project}/global/deployments/{deployment}/stop"
    path_params: [{name: project, var: project}, {name: deployment, var: deployment}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: fingerprint, var: fingerprint}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, deployment: $deployment, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, fingerprint: $fingerprint
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the access control policy for a resource. May be empty if no such policy or resource exists.
#
# GET /deploymentmanager/v2beta/projects/{project}/global/deployments/{resource}/getIamPolicy
# Returns: record<auditConfigs: table<auditLogConfigs: list, service: string>, bindings: table<condition: record, members: list, role: string>, etag: string, version: int>
# operationId: deploymentmanager.deployments.getIamPolicy
export def "deploymentmanager-deployments-get-iam-policy" [
  project: string
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
  --options-requested-policy-version: int # Requested IAM Policy version.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/deploymentmanager/v2beta/projects/{project}/global/deployments/{resource}/getIamPolicy"
    path_params: [{name: project, var: project}, {name: resource, var: resource}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: optionsRequestedPolicyVersion, var: options_requested_policy_version}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, resource: $resource, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, options_requested_policy_version: $options_requested_policy_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the access control policy on the specified resource. Replaces any existing policy.
#
# POST /deploymentmanager/v2beta/projects/{project}/global/deployments/{resource}/setIamPolicy
# Returns: record<auditConfigs: table<auditLogConfigs: list, service: string>, bindings: table<condition: record, members: list, role: string>, etag: string, version: int>
# operationId: deploymentmanager.deployments.setIamPolicy
export def "deploymentmanager-deployments-set-iam-policy" [
  project: string
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
  --bindings: list # Flatten Policy to create a backward compatible wire-format. Deprecated. Use 'policy' to specify bindings. — item shape: {condition?: record, members?: list<string>, role?: string}
  --etag: string # Flatten Policy to create a backward compatible wire-format. Deprecated. Use 'policy' to specify the etag. (format: byte)
  --policy: record # An Identity and Access Management (IAM) policy, which specifies access controls for Google Cloud resources. A `Policy` is a collection of `bindings`. A `binding` binds one or more `members`, or principals, to a single `role`. Principals can be user accounts, service accounts, Google groups, and domains (such as G Suite). A `role` is a named list of permissions; each `role` can be an IAM predefined role or a user-created custom role. For some types of Google Cloud resources, a `binding` can also specify a `condition`, which is a logical expression that allows access to a resource only if the expression evaluates to `true`. A condition can add constraints based on attributes of the request, the resource, or both. To learn which resources support conditions in their IAM policies, see the [IAM documentation](https://cloud.google.com/iam/help/conditions/resource-policies). **JSON example:** { "bindings": [ { "role": "roles/resourcemanager.organizationAdmin", "members": [ "user:mike@example.com", "group:admins@example.com", "domain:google.com", "serviceAccount:my-project-id@appspot.gserviceaccount.com" ] }, { "role": "roles/resourcemanager.organizationViewer", "members": [ "user:eve@example.com" ], "condition": { "title": "expirable access", "description": "Does not grant access after Sep 2020", "expression": "request.time < timestamp('2020-10-01T00:00:00.000Z')", } } ], "etag": "BwWWja0YfJA=", "version": 3 } **YAML example:** bindings: - members: - user:mike@example.com - group:admins@example.com - domain:google.com - serviceAccount:my-project-id@appspot.gserviceaccount.com role: roles/resourcemanager.organizationAdmin - members: - user:eve@example.com role: roles/resourcemanager.organizationViewer condition: title: expirable access description: Does not grant access after Sep 2020 expression: request.time < timestamp('2020-10-01T00:00:00.000Z') etag: BwWWja0YfJA= version: 3 For a description of IAM and its features, see the [IAM documentation](https://cloud.google.com/iam/docs/). — shape: {auditConfigs?: list, bindings?: list, etag?: string, version?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/deploymentmanager/v2beta/projects/{project}/global/deployments/{resource}/setIamPolicy"
    path_params: [{name: project, var: project}, {name: resource, var: resource}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: bindings, var: bindings}, {name: etag, var: etag}, {name: policy, var: policy}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, resource: $resource, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, bindings: $bindings, etag: $etag, policy: $policy
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns permissions that a caller has on the specified resource.
#
# POST /deploymentmanager/v2beta/projects/{project}/global/deployments/{resource}/testIamPermissions
# Returns: record<permissions: list<string>>
# operationId: deploymentmanager.deployments.testIamPermissions
export def "deploymentmanager-deployments-test-iam-permissions" [
  project: string
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
  --permissions: list<string> # The set of permissions to check for the 'resource'. Permissions with wildcards (such as '*' or 'storage.*') are not allowed.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/deploymentmanager/v2beta/projects/{project}/global/deployments/{resource}/testIamPermissions"
    path_params: [{name: project, var: project}, {name: resource, var: resource}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: permissions, var: permissions}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, resource: $resource, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, permissions: $permissions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all operations for a project.
#
# GET /deploymentmanager/v2beta/projects/{project}/global/operations
# Returns: record<nextPageToken: string, operations: table<clientOperationId: string, creationTimestamp: string, description: string, endTime: string, error: record, httpErrorMessage: string, httpErrorStatusCode: int, id: string, insertTime: string, kind: string, name: string, operationGroupId: string, operationType: string, progress: int, region: string, selfLink: string, startTime: string, status: string, statusMessage: string, targetId: string, targetLink: string, user: string, warnings: list, zone: string>>
# operationId: deploymentmanager.operations.list
export def "deploymentmanager-operations-list" [
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --filter: string # A filter expression that filters resources listed in the response. Most Compute resources support two types of filter expressions: expressions that support regular expressions and expressions that follow API improvement proposal AIP-160. If you want to use AIP-160, your expression must specify the field name, an operator, and the value that you want to use for filtering. The value must be a string, a number, or a boolean. The operator must be either `=`, `!=`, `>`, `<`, `<=`, `>=` or `:`. For example, if you are filtering Compute Engine instances, you can exclude instances named `example-instance` by specifying `name != example-instance`. The `:` operator can be used with string fields to match substrings. For non-string fields it is equivalent to the `=` operator. The `:*` comparison can be used to test whether a key has been defined. For example, to find all objects with `owner` label use: ``` labels.owner:* ``` You can also filter nested fields. For example, you could specify `scheduling.automaticRestart = false` to include instances only if they are not scheduled for automatic restarts. You can use filtering on nested fields to filter based on resource labels. To filter on multiple expressions, provide each separate expression within parentheses. For example: ``` (scheduling.automaticRestart = true) (cpuPlatform = "Intel Skylake") ``` By default, each expression is an `AND` expression. However, you can include `AND` and `OR` expressions explicitly. For example: ``` (cpuPlatform = "Intel Skylake") OR (cpuPlatform = "Intel Broadwell") AND (scheduling.automaticRestart = true) ``` If you want to use a regular expression, use the `eq` (equal) or `ne` (not equal) operator against a single un-parenthesized expression with or without quotes or against multiple parenthesized expressions. Examples: `fieldname eq unquoted literal` `fieldname eq 'single quoted literal'` `fieldname eq "double quoted literal"` `(fieldname1 eq literal) (fieldname2 ne "literal")` The literal value is interpreted as a regular expression using Google RE2 library syntax. The literal value must match the entire field. For example, to filter for instances that do not end with name "instance", you would use `name ne .*instance`.
  --max-results: int # The maximum number of results per page that should be returned. If the number of available results is larger than `maxResults`, Compute Engine returns a `nextPageToken` that can be used to get the next page of results in subsequent list requests. Acceptable values are `0` to `500`, inclusive. (Default: `500`)
  --order-by: string # Sorts list results by a certain order. By default, results are returned in alphanumerical order based on the resource name. You can also sort results in descending order based on the creation timestamp using `orderBy="creationTimestamp desc"`. This sorts results based on the `creationTimestamp` field in reverse chronological order (newest result first). Use this to sort resources like operations so that the newest operation is returned first. Currently, only sorting by `name` or `creationTimestamp desc` is supported.
  --page-token: string # Specifies a page token to use. Set `pageToken` to the `nextPageToken` returned by a previous list request to get the next page of results.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/deploymentmanager/v2beta/projects/{project}/global/operations"
    path_params: [{name: project, var: project}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: filter, var: filter}, {name: maxResults, var: max_results}, {name: orderBy, var: order_by}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, filter: $filter, max_results: $max_results, order_by: $order_by, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about a specific operation.
#
# GET /deploymentmanager/v2beta/projects/{project}/global/operations/{operation}
# Returns: record<clientOperationId: string, creationTimestamp: string, description: string, endTime: string, error: record<errors: list<record>>, httpErrorMessage: string, httpErrorStatusCode: int, id: string, insertTime: string, kind: string, name: string, operationGroupId: string, operationType: string, progress: int, region: string, selfLink: string, startTime: string, status: string, statusMessage: string, targetId: string, targetLink: string, user: string, warnings: table<code: string, data: list, message: string>, zone: string>
# operationId: deploymentmanager.operations.get
export def "deploymentmanager-operations-get" [
  project: string
  operation: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
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
    path: "/deploymentmanager/v2beta/projects/{project}/global/operations/{operation}"
    path_params: [{name: project, var: project}, {name: operation, var: operation}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, operation: $operation, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all resource type providers for Deployment Manager.
#
# GET /deploymentmanager/v2beta/projects/{project}/global/typeProviders
# Returns: record<nextPageToken: string, typeProviders: table<collectionOverrides: list, credential: record, customCertificateAuthorityRoots: list, description: string, descriptorUrl: string, id: string, insertTime: string, labels: list, name: string, operation: record, options: record, selfLink: string>>
# operationId: deploymentmanager.typeProviders.list
export def "deploymentmanager-type-providers-list" [
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --filter: string # A filter expression that filters resources listed in the response. Most Compute resources support two types of filter expressions: expressions that support regular expressions and expressions that follow API improvement proposal AIP-160. If you want to use AIP-160, your expression must specify the field name, an operator, and the value that you want to use for filtering. The value must be a string, a number, or a boolean. The operator must be either `=`, `!=`, `>`, `<`, `<=`, `>=` or `:`. For example, if you are filtering Compute Engine instances, you can exclude instances named `example-instance` by specifying `name != example-instance`. The `:` operator can be used with string fields to match substrings. For non-string fields it is equivalent to the `=` operator. The `:*` comparison can be used to test whether a key has been defined. For example, to find all objects with `owner` label use: ``` labels.owner:* ``` You can also filter nested fields. For example, you could specify `scheduling.automaticRestart = false` to include instances only if they are not scheduled for automatic restarts. You can use filtering on nested fields to filter based on resource labels. To filter on multiple expressions, provide each separate expression within parentheses. For example: ``` (scheduling.automaticRestart = true) (cpuPlatform = "Intel Skylake") ``` By default, each expression is an `AND` expression. However, you can include `AND` and `OR` expressions explicitly. For example: ``` (cpuPlatform = "Intel Skylake") OR (cpuPlatform = "Intel Broadwell") AND (scheduling.automaticRestart = true) ``` If you want to use a regular expression, use the `eq` (equal) or `ne` (not equal) operator against a single un-parenthesized expression with or without quotes or against multiple parenthesized expressions. Examples: `fieldname eq unquoted literal` `fieldname eq 'single quoted literal'` `fieldname eq "double quoted literal"` `(fieldname1 eq literal) (fieldname2 ne "literal")` The literal value is interpreted as a regular expression using Google RE2 library syntax. The literal value must match the entire field. For example, to filter for instances that do not end with name "instance", you would use `name ne .*instance`.
  --max-results: int # The maximum number of results per page that should be returned. If the number of available results is larger than `maxResults`, Compute Engine returns a `nextPageToken` that can be used to get the next page of results in subsequent list requests. Acceptable values are `0` to `500`, inclusive. (Default: `500`)
  --order-by: string # Sorts list results by a certain order. By default, results are returned in alphanumerical order based on the resource name. You can also sort results in descending order based on the creation timestamp using `orderBy="creationTimestamp desc"`. This sorts results based on the `creationTimestamp` field in reverse chronological order (newest result first). Use this to sort resources like operations so that the newest operation is returned first. Currently, only sorting by `name` or `creationTimestamp desc` is supported.
  --page-token: string # Specifies a page token to use. Set `pageToken` to the `nextPageToken` returned by a previous list request to get the next page of results.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/deploymentmanager/v2beta/projects/{project}/global/typeProviders"
    path_params: [{name: project, var: project}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: filter, var: filter}, {name: maxResults, var: max_results}, {name: orderBy, var: order_by}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, filter: $filter, max_results: $max_results, order_by: $order_by, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a type provider.
#
# POST /deploymentmanager/v2beta/projects/{project}/global/typeProviders
# Returns: record<clientOperationId: string, creationTimestamp: string, description: string, endTime: string, error: record<errors: list<record>>, httpErrorMessage: string, httpErrorStatusCode: int, id: string, insertTime: string, kind: string, name: string, operationGroupId: string, operationType: string, progress: int, region: string, selfLink: string, startTime: string, status: string, statusMessage: string, targetId: string, targetLink: string, user: string, warnings: table<code: string, data: list, message: string>, zone: string>
# operationId: deploymentmanager.typeProviders.insert
export def "deploymentmanager-type-providers-insert" [
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --collection-overrides: list # Allows resource handling overrides for specific collections — item shape: {collection?: string, options?: record}
  --credential: record # The credential used by Deployment Manager and TypeProvider. Only one of the options is permitted. — shape: {basicAuth?: record, serviceAccount?: record, useProjectDefault?: bool}
  --custom-certificate-authority-roots: list<string> # List of up to 2 custom certificate authority roots to use for TLS authentication when making calls on behalf of this type provider. If set, TLS authentication will exclusively use these roots instead of relying on publicly trusted certificate authorities when validating TLS certificate authenticity. The certificates must be in base64-encoded PEM format. The maximum size of each certificate must not exceed 10KB.
  --description: string # An optional textual description of the resource; provided by the client when the resource is created.
  --descriptor-url: string # Descriptor Url for the this type provider.
  --id: string # Output only. Unique identifier for the resource defined by the server. (format: uint64)
  --insert-time: string # Output only. Creation timestamp in RFC3339 text format.
  --labels: list # Map of One Platform labels; provided by the client when the resource is created or updated. Specifically: Label keys must be between 1 and 63 characters long and must conform to the following regular expression: `[a-z]([-a-z0-9]*[a-z0-9])?` Label values must be between 0 and 63 characters long and must conform to the regular expression `([a-z]([-a-z0-9]*[a-z0-9])?)?` — item shape: {key?: string, value?: string}
  --name: string # Name of the resource; provided by the client when the resource is created. The name must be 1-63 characters long, and comply with RFC1035. Specifically, the name must be 1-63 characters long and match the regular expression `[a-z]([-a-z0-9]*[a-z0-9])?` which means the first character must be a lowercase letter, and all following characters must be a dash, lowercase letter, or digit, except the last character, which cannot be a dash.
  --operation: record # Represents an Operation resource. Google Compute Engine has three Operation resources: * [Global](/compute/docs/reference/rest/{$api_version}/globalOperations) * [Regional](/compute/docs/reference/rest/{$api_version}/regionOperations) * [Zonal](/compute/docs/reference/rest/{$api_version}/zoneOperations) You can use an operation resource to manage asynchronous API requests. For more information, read Handling API responses. Operations can be global, regional or zonal. - For global operations, use the `globalOperations` resource. - For regional operations, use the `regionOperations` resource. - For zonal operations, use the `zonalOperations` resource. For more information, read Global, Regional, and Zonal Resources. — shape: {clientOperationId?: string, creationTimestamp?: string, description?: string, endTime?: string, error?: record, httpErrorMessage?: string, httpErrorStatusCode?: int, id?: string, insertTime?: string, kind?: string, name?: string, operationGroupId?: string, operationType?: string, progress?: int, region?: string, selfLink?: string, startTime?: string, status?: "PENDING"|"RUNNING"|"DONE", statusMessage?: string, targetId?: string, targetLink?: string, user?: string, warnings?: list, zone?: string}
  --options: record # Options allows customized resource handling by Deployment Manager. — shape: {asyncOptions?: list, inputMappings?: list, validationOptions?: record, virtualProperties?: string}
  --self-link: string # Output only. Self link for the type provider.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/deploymentmanager/v2beta/projects/{project}/global/typeProviders"
    path_params: [{name: project, var: project}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: collectionOverrides, var: collection_overrides}, {name: credential, var: credential}, {name: customCertificateAuthorityRoots, var: custom_certificate_authority_roots}, {name: description, var: description}, {name: descriptorUrl, var: descriptor_url}, {name: id, var: id}, {name: insertTime, var: insert_time}, {name: labels, var: labels}, {name: name, var: name}, {name: operation, var: operation}, {name: options, var: options}, {name: selfLink, var: self_link}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, collection_overrides: $collection_overrides, credential: $credential, custom_certificate_authority_roots: $custom_certificate_authority_roots, description: $description, descriptor_url: $descriptor_url, id: $id, insert_time: $insert_time, labels: $labels, name: $name, operation: $operation, options: $options, self_link: $self_link
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a type provider.
#
# DELETE /deploymentmanager/v2beta/projects/{project}/global/typeProviders/{typeProvider}
# Returns: record<clientOperationId: string, creationTimestamp: string, description: string, endTime: string, error: record<errors: list<record>>, httpErrorMessage: string, httpErrorStatusCode: int, id: string, insertTime: string, kind: string, name: string, operationGroupId: string, operationType: string, progress: int, region: string, selfLink: string, startTime: string, status: string, statusMessage: string, targetId: string, targetLink: string, user: string, warnings: table<code: string, data: list, message: string>, zone: string>
# operationId: deploymentmanager.typeProviders.delete
export def "deploymentmanager-type-providers-delete" [
  project: string
  type_provider: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
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
    path: "/deploymentmanager/v2beta/projects/{project}/global/typeProviders/{typeProvider}"
    path_params: [{name: project, var: project}, {name: typeProvider, var: type_provider}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, type_provider: $type_provider, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about a specific type provider.
#
# GET /deploymentmanager/v2beta/projects/{project}/global/typeProviders/{typeProvider}
# Returns: record<collectionOverrides: table<collection: string, options: record>, credential: record<basicAuth: record<password: string, user: string>, serviceAccount: record<email: string>, useProjectDefault: bool>, customCertificateAuthorityRoots: list<string>, description: string, descriptorUrl: string, id: string, insertTime: string, labels: table<key: string, value: string>, name: string, operation: record<clientOperationId: string, creationTimestamp: string, description: string, endTime: string, error: record<errors: list>, httpErrorMessage: string, httpErrorStatusCode: int, id: string, insertTime: string, kind: string, name: string, operationGroupId: string, operationType: string, progress: int, region: string, selfLink: string, startTime: string, status: string, statusMessage: string, targetId: string, targetLink: string, user: string, warnings: list<record>, zone: string>, options: record<asyncOptions: list<record>, inputMappings: list<record>, validationOptions: record<schemaValidation: string, undeclaredProperties: string>, virtualProperties: string>, selfLink: string>
# operationId: deploymentmanager.typeProviders.get
export def "deploymentmanager-type-providers-get" [
  project: string
  type_provider: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
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
    path: "/deploymentmanager/v2beta/projects/{project}/global/typeProviders/{typeProvider}"
    path_params: [{name: project, var: project}, {name: typeProvider, var: type_provider}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, type_provider: $type_provider, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Patches a type provider.
#
# PATCH /deploymentmanager/v2beta/projects/{project}/global/typeProviders/{typeProvider}
# Returns: record<clientOperationId: string, creationTimestamp: string, description: string, endTime: string, error: record<errors: list<record>>, httpErrorMessage: string, httpErrorStatusCode: int, id: string, insertTime: string, kind: string, name: string, operationGroupId: string, operationType: string, progress: int, region: string, selfLink: string, startTime: string, status: string, statusMessage: string, targetId: string, targetLink: string, user: string, warnings: table<code: string, data: list, message: string>, zone: string>
# operationId: deploymentmanager.typeProviders.patch
export def "deploymentmanager-type-providers-patch" [
  project: string
  type_provider: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --collection-overrides: list # Allows resource handling overrides for specific collections — item shape: {collection?: string, options?: record}
  --credential: record # The credential used by Deployment Manager and TypeProvider. Only one of the options is permitted. — shape: {basicAuth?: record, serviceAccount?: record, useProjectDefault?: bool}
  --custom-certificate-authority-roots: list<string> # List of up to 2 custom certificate authority roots to use for TLS authentication when making calls on behalf of this type provider. If set, TLS authentication will exclusively use these roots instead of relying on publicly trusted certificate authorities when validating TLS certificate authenticity. The certificates must be in base64-encoded PEM format. The maximum size of each certificate must not exceed 10KB.
  --description: string # An optional textual description of the resource; provided by the client when the resource is created.
  --descriptor-url: string # Descriptor Url for the this type provider.
  --id: string # Output only. Unique identifier for the resource defined by the server. (format: uint64)
  --insert-time: string # Output only. Creation timestamp in RFC3339 text format.
  --labels: list # Map of One Platform labels; provided by the client when the resource is created or updated. Specifically: Label keys must be between 1 and 63 characters long and must conform to the following regular expression: `[a-z]([-a-z0-9]*[a-z0-9])?` Label values must be between 0 and 63 characters long and must conform to the regular expression `([a-z]([-a-z0-9]*[a-z0-9])?)?` — item shape: {key?: string, value?: string}
  --name: string # Name of the resource; provided by the client when the resource is created. The name must be 1-63 characters long, and comply with RFC1035. Specifically, the name must be 1-63 characters long and match the regular expression `[a-z]([-a-z0-9]*[a-z0-9])?` which means the first character must be a lowercase letter, and all following characters must be a dash, lowercase letter, or digit, except the last character, which cannot be a dash.
  --operation: record # Represents an Operation resource. Google Compute Engine has three Operation resources: * [Global](/compute/docs/reference/rest/{$api_version}/globalOperations) * [Regional](/compute/docs/reference/rest/{$api_version}/regionOperations) * [Zonal](/compute/docs/reference/rest/{$api_version}/zoneOperations) You can use an operation resource to manage asynchronous API requests. For more information, read Handling API responses. Operations can be global, regional or zonal. - For global operations, use the `globalOperations` resource. - For regional operations, use the `regionOperations` resource. - For zonal operations, use the `zonalOperations` resource. For more information, read Global, Regional, and Zonal Resources. — shape: {clientOperationId?: string, creationTimestamp?: string, description?: string, endTime?: string, error?: record, httpErrorMessage?: string, httpErrorStatusCode?: int, id?: string, insertTime?: string, kind?: string, name?: string, operationGroupId?: string, operationType?: string, progress?: int, region?: string, selfLink?: string, startTime?: string, status?: "PENDING"|"RUNNING"|"DONE", statusMessage?: string, targetId?: string, targetLink?: string, user?: string, warnings?: list, zone?: string}
  --options: record # Options allows customized resource handling by Deployment Manager. — shape: {asyncOptions?: list, inputMappings?: list, validationOptions?: record, virtualProperties?: string}
  --self-link: string # Output only. Self link for the type provider.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/deploymentmanager/v2beta/projects/{project}/global/typeProviders/{typeProvider}"
    path_params: [{name: project, var: project}, {name: typeProvider, var: type_provider}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: collectionOverrides, var: collection_overrides}, {name: credential, var: credential}, {name: customCertificateAuthorityRoots, var: custom_certificate_authority_roots}, {name: description, var: description}, {name: descriptorUrl, var: descriptor_url}, {name: id, var: id}, {name: insertTime, var: insert_time}, {name: labels, var: labels}, {name: name, var: name}, {name: operation, var: operation}, {name: options, var: options}, {name: selfLink, var: self_link}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, type_provider: $type_provider, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, collection_overrides: $collection_overrides, credential: $credential, custom_certificate_authority_roots: $custom_certificate_authority_roots, description: $description, descriptor_url: $descriptor_url, id: $id, insert_time: $insert_time, labels: $labels, name: $name, operation: $operation, options: $options, self_link: $self_link
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a type provider.
#
# PUT /deploymentmanager/v2beta/projects/{project}/global/typeProviders/{typeProvider}
# Returns: record<clientOperationId: string, creationTimestamp: string, description: string, endTime: string, error: record<errors: list<record>>, httpErrorMessage: string, httpErrorStatusCode: int, id: string, insertTime: string, kind: string, name: string, operationGroupId: string, operationType: string, progress: int, region: string, selfLink: string, startTime: string, status: string, statusMessage: string, targetId: string, targetLink: string, user: string, warnings: table<code: string, data: list, message: string>, zone: string>
# operationId: deploymentmanager.typeProviders.update
export def "deploymentmanager-type-providers-update" [
  project: string
  type_provider: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --collection-overrides: list # Allows resource handling overrides for specific collections — item shape: {collection?: string, options?: record}
  --credential: record # The credential used by Deployment Manager and TypeProvider. Only one of the options is permitted. — shape: {basicAuth?: record, serviceAccount?: record, useProjectDefault?: bool}
  --custom-certificate-authority-roots: list<string> # List of up to 2 custom certificate authority roots to use for TLS authentication when making calls on behalf of this type provider. If set, TLS authentication will exclusively use these roots instead of relying on publicly trusted certificate authorities when validating TLS certificate authenticity. The certificates must be in base64-encoded PEM format. The maximum size of each certificate must not exceed 10KB.
  --description: string # An optional textual description of the resource; provided by the client when the resource is created.
  --descriptor-url: string # Descriptor Url for the this type provider.
  --id: string # Output only. Unique identifier for the resource defined by the server. (format: uint64)
  --insert-time: string # Output only. Creation timestamp in RFC3339 text format.
  --labels: list # Map of One Platform labels; provided by the client when the resource is created or updated. Specifically: Label keys must be between 1 and 63 characters long and must conform to the following regular expression: `[a-z]([-a-z0-9]*[a-z0-9])?` Label values must be between 0 and 63 characters long and must conform to the regular expression `([a-z]([-a-z0-9]*[a-z0-9])?)?` — item shape: {key?: string, value?: string}
  --name: string # Name of the resource; provided by the client when the resource is created. The name must be 1-63 characters long, and comply with RFC1035. Specifically, the name must be 1-63 characters long and match the regular expression `[a-z]([-a-z0-9]*[a-z0-9])?` which means the first character must be a lowercase letter, and all following characters must be a dash, lowercase letter, or digit, except the last character, which cannot be a dash.
  --operation: record # Represents an Operation resource. Google Compute Engine has three Operation resources: * [Global](/compute/docs/reference/rest/{$api_version}/globalOperations) * [Regional](/compute/docs/reference/rest/{$api_version}/regionOperations) * [Zonal](/compute/docs/reference/rest/{$api_version}/zoneOperations) You can use an operation resource to manage asynchronous API requests. For more information, read Handling API responses. Operations can be global, regional or zonal. - For global operations, use the `globalOperations` resource. - For regional operations, use the `regionOperations` resource. - For zonal operations, use the `zonalOperations` resource. For more information, read Global, Regional, and Zonal Resources. — shape: {clientOperationId?: string, creationTimestamp?: string, description?: string, endTime?: string, error?: record, httpErrorMessage?: string, httpErrorStatusCode?: int, id?: string, insertTime?: string, kind?: string, name?: string, operationGroupId?: string, operationType?: string, progress?: int, region?: string, selfLink?: string, startTime?: string, status?: "PENDING"|"RUNNING"|"DONE", statusMessage?: string, targetId?: string, targetLink?: string, user?: string, warnings?: list, zone?: string}
  --options: record # Options allows customized resource handling by Deployment Manager. — shape: {asyncOptions?: list, inputMappings?: list, validationOptions?: record, virtualProperties?: string}
  --self-link: string # Output only. Self link for the type provider.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/deploymentmanager/v2beta/projects/{project}/global/typeProviders/{typeProvider}"
    path_params: [{name: project, var: project}, {name: typeProvider, var: type_provider}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: collectionOverrides, var: collection_overrides}, {name: credential, var: credential}, {name: customCertificateAuthorityRoots, var: custom_certificate_authority_roots}, {name: description, var: description}, {name: descriptorUrl, var: descriptor_url}, {name: id, var: id}, {name: insertTime, var: insert_time}, {name: labels, var: labels}, {name: name, var: name}, {name: operation, var: operation}, {name: options, var: options}, {name: selfLink, var: self_link}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, type_provider: $type_provider, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, collection_overrides: $collection_overrides, credential: $credential, custom_certificate_authority_roots: $custom_certificate_authority_roots, description: $description, descriptor_url: $descriptor_url, id: $id, insert_time: $insert_time, labels: $labels, name: $name, operation: $operation, options: $options, self_link: $self_link
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all the type info for a TypeProvider.
#
# GET /deploymentmanager/v2beta/projects/{project}/global/typeProviders/{typeProvider}/types
# Returns: record<nextPageToken: string, types: table<description: string, documentationLink: string, kind: string, name: string, schema: record, selfLink: string, title: string>>
# operationId: deploymentmanager.typeProviders.listTypes
export def "deploymentmanager-type-providers-list-types" [
  project: string
  type_provider: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --filter: string # A filter expression that filters resources listed in the response. Most Compute resources support two types of filter expressions: expressions that support regular expressions and expressions that follow API improvement proposal AIP-160. If you want to use AIP-160, your expression must specify the field name, an operator, and the value that you want to use for filtering. The value must be a string, a number, or a boolean. The operator must be either `=`, `!=`, `>`, `<`, `<=`, `>=` or `:`. For example, if you are filtering Compute Engine instances, you can exclude instances named `example-instance` by specifying `name != example-instance`. The `:` operator can be used with string fields to match substrings. For non-string fields it is equivalent to the `=` operator. The `:*` comparison can be used to test whether a key has been defined. For example, to find all objects with `owner` label use: ``` labels.owner:* ``` You can also filter nested fields. For example, you could specify `scheduling.automaticRestart = false` to include instances only if they are not scheduled for automatic restarts. You can use filtering on nested fields to filter based on resource labels. To filter on multiple expressions, provide each separate expression within parentheses. For example: ``` (scheduling.automaticRestart = true) (cpuPlatform = "Intel Skylake") ``` By default, each expression is an `AND` expression. However, you can include `AND` and `OR` expressions explicitly. For example: ``` (cpuPlatform = "Intel Skylake") OR (cpuPlatform = "Intel Broadwell") AND (scheduling.automaticRestart = true) ``` If you want to use a regular expression, use the `eq` (equal) or `ne` (not equal) operator against a single un-parenthesized expression with or without quotes or against multiple parenthesized expressions. Examples: `fieldname eq unquoted literal` `fieldname eq 'single quoted literal'` `fieldname eq "double quoted literal"` `(fieldname1 eq literal) (fieldname2 ne "literal")` The literal value is interpreted as a regular expression using Google RE2 library syntax. The literal value must match the entire field. For example, to filter for instances that do not end with name "instance", you would use `name ne .*instance`.
  --max-results: int # The maximum number of results per page that should be returned. If the number of available results is larger than `maxResults`, Compute Engine returns a `nextPageToken` that can be used to get the next page of results in subsequent list requests. Acceptable values are `0` to `500`, inclusive. (Default: `500`)
  --order-by: string # Sorts list results by a certain order. By default, results are returned in alphanumerical order based on the resource name. You can also sort results in descending order based on the creation timestamp using `orderBy="creationTimestamp desc"`. This sorts results based on the `creationTimestamp` field in reverse chronological order (newest result first). Use this to sort resources like operations so that the newest operation is returned first. Currently, only sorting by `name` or `creationTimestamp desc` is supported.
  --page-token: string # Specifies a page token to use. Set `pageToken` to the `nextPageToken` returned by a previous list request to get the next page of results.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/deploymentmanager/v2beta/projects/{project}/global/typeProviders/{typeProvider}/types"
    path_params: [{name: project, var: project}, {name: typeProvider, var: type_provider}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: filter, var: filter}, {name: maxResults, var: max_results}, {name: orderBy, var: order_by}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, type_provider: $type_provider, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, filter: $filter, max_results: $max_results, order_by: $order_by, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a type info for a type provided by a TypeProvider.
#
# GET /deploymentmanager/v2beta/projects/{project}/global/typeProviders/{typeProvider}/types/{type}
# Returns: record<description: string, documentationLink: string, kind: string, name: string, schema: record<input: string, output: string>, selfLink: string, title: string>
# operationId: deploymentmanager.typeProviders.getType
export def "deploymentmanager-type-providers-get-type" [
  project: string
  type_provider: string
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
    method: get
    path: "/deploymentmanager/v2beta/projects/{project}/global/typeProviders/{typeProvider}/types/{type}"
    path_params: [{name: project, var: project}, {name: typeProvider, var: type_provider}, {name: type, var: type}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, type_provider: $type_provider, type: $type, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all resource types for Deployment Manager.
#
# GET /deploymentmanager/v2beta/projects/{project}/global/types
# Returns: record<nextPageToken: string, types: table<base: record, description: string, id: string, insertTime: string, labels: list, name: string, operation: record, selfLink: string>>
# operationId: deploymentmanager.types.list
export def "deploymentmanager-types-list" [
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --filter: string # A filter expression that filters resources listed in the response. Most Compute resources support two types of filter expressions: expressions that support regular expressions and expressions that follow API improvement proposal AIP-160. If you want to use AIP-160, your expression must specify the field name, an operator, and the value that you want to use for filtering. The value must be a string, a number, or a boolean. The operator must be either `=`, `!=`, `>`, `<`, `<=`, `>=` or `:`. For example, if you are filtering Compute Engine instances, you can exclude instances named `example-instance` by specifying `name != example-instance`. The `:` operator can be used with string fields to match substrings. For non-string fields it is equivalent to the `=` operator. The `:*` comparison can be used to test whether a key has been defined. For example, to find all objects with `owner` label use: ``` labels.owner:* ``` You can also filter nested fields. For example, you could specify `scheduling.automaticRestart = false` to include instances only if they are not scheduled for automatic restarts. You can use filtering on nested fields to filter based on resource labels. To filter on multiple expressions, provide each separate expression within parentheses. For example: ``` (scheduling.automaticRestart = true) (cpuPlatform = "Intel Skylake") ``` By default, each expression is an `AND` expression. However, you can include `AND` and `OR` expressions explicitly. For example: ``` (cpuPlatform = "Intel Skylake") OR (cpuPlatform = "Intel Broadwell") AND (scheduling.automaticRestart = true) ``` If you want to use a regular expression, use the `eq` (equal) or `ne` (not equal) operator against a single un-parenthesized expression with or without quotes or against multiple parenthesized expressions. Examples: `fieldname eq unquoted literal` `fieldname eq 'single quoted literal'` `fieldname eq "double quoted literal"` `(fieldname1 eq literal) (fieldname2 ne "literal")` The literal value is interpreted as a regular expression using Google RE2 library syntax. The literal value must match the entire field. For example, to filter for instances that do not end with name "instance", you would use `name ne .*instance`.
  --max-results: int # The maximum number of results per page that should be returned. If the number of available results is larger than `maxResults`, Compute Engine returns a `nextPageToken` that can be used to get the next page of results in subsequent list requests. Acceptable values are `0` to `500`, inclusive. (Default: `500`)
  --order-by: string # Sorts list results by a certain order. By default, results are returned in alphanumerical order based on the resource name. You can also sort results in descending order based on the creation timestamp using `orderBy="creationTimestamp desc"`. This sorts results based on the `creationTimestamp` field in reverse chronological order (newest result first). Use this to sort resources like operations so that the newest operation is returned first. Currently, only sorting by `name` or `creationTimestamp desc` is supported.
  --page-token: string # Specifies a page token to use. Set `pageToken` to the `nextPageToken` returned by a previous list request to get the next page of results.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/deploymentmanager/v2beta/projects/{project}/global/types"
    path_params: [{name: project, var: project}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: filter, var: filter}, {name: maxResults, var: max_results}, {name: orderBy, var: order_by}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, filter: $filter, max_results: $max_results, order_by: $order_by, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
