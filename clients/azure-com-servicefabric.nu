# Auto-generated client for Service Fabric Client APIs v6.5.0.36
# Source: https://api.apis.guru/v2/specs/azure.com/servicefabric/6.5.0.36/swagger.json
# Auth: --token flag or $env.SERVICE_FABRIC_CLIENT_APIS_TOKEN

const CLIENT = {
  base_url: "http://azure.local:19080"
  token_env_var: "SERVICE_FABRIC_CLIENT_APIS_TOKEN"
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

def base-url-completer [] { ["http://azure.local:19080" "https://azure.local:19080"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def api-version-completer [] { ["6.0"] }
def preparing-health-check-state-completer [] { ["InProgress" "NotStarted" "Skipped" "Succeeded" "TimedOut"] }
def restoring-health-check-state-completer [] { ["InProgress" "NotStarted" "Skipped" "Succeeded" "TimedOut"] }
def result-status-completer [] { ["Cancelled" "Failed" "Interrupted" "Invalid" "Pending" "Succeeded"] }
def state-completer [] { ["Approved" "Claimed" "Completed" "Created" "Executing" "Invalid" "Preparing" "Restoring"] }
def api-version-completer-1 [] { ["6.4"] }
def health-state-completer [] { ["Error" "Invalid" "Ok" "Unknown" "Warning"] }
def upgrade-kind-completer [] { ["Invalid" "Rolling" "Rolling_ForceRestart"] }
def rolling-upgrade-mode-completer [] { ["Invalid" "Monitored" "UnmonitoredAuto" "UnmonitoredManual"] }
def sort-order-completer [] { ["Default" "Invalid" "Lexicographical" "Numeric" "ReverseLexicographical" "ReverseNumeric"] }
def upgrade-kind-completer-1 [] { ["Invalid" "Rolling"] }
def api-version-completer-2 [] { ["6.2"] }
def kind-completer [] { ["ExternalStore" "ImageStorePath" "Invalid"] }
def api-version-completer-3 [] { ["6.1"] }
def default-move-cost-completer [] { ["High" "Low" "Medium" "Zero"] }
def service-kind-completer [] { ["Invalid" "Stateful" "Stateless"] }
def service-package-activation-mode-completer [] { ["ExclusiveProcess" "SharedProcess"] }
def api-version-completer-4 [] { ["6.0-preview"] }
def api-version-completer-5 [] { ["6.4-preview"] }
def api-version-completer-6 [] { ["6.2-preview"] }
def node-transition-type-completer [] { ["Invalid" "Start" "Stop"] }
def data-loss-mode-completer [] { ["FullDataLoss" "Invalid" "PartialDataLoss"] }
def quorum-loss-mode-completer [] { ["AllReplicas" "Invalid" "QuorumReplicas"] }
def restart-partition-mode-completer [] { ["AllReplicasOrInstances" "Invalid" "OnlyActiveSecondaries"] }
def api-version-completer-7 [] { ["6.5"] }
def api-version-completer-8 [] { ["6.3"] }
def node-status-filter-completer [] { ["all" "default" "disabled" "disabling" "down" "enabling" "removed" "unknown" "up"] }
def deactivation-intent-completer [] { ["Pause" "RemoveData" "Restart"] }
def create-fabric-dump-completer [] { ["False" "True"] }
def service-kind-completer-1 [] { ["Stateful" "Stateless"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    cancel-repair-task: "record<Version: string>"
    create-repair-task: "record<Version: string>"
    force-approve-repair-task: "record<Version: string>"
    get-aad-metadata: "record<metadata: record<authority: string, client: string, cluster: string, login: string, redirect: string, tenant: string>, type: string>"
    get-cluster-configuration: "record<ClusterConfiguration: string>"
    get-cluster-configuration-upgrade-status: "record<ConfigVersion: string, Details: string, ProgressStatus: int, UpgradeState: string>"
    get-cluster-health: "record<ApplicationHealthStates: table<Name: string, AggregatedHealthState: string>, NodeHealthStates: table<Id: record, Name: string, AggregatedHealthState: string>, AggregatedHealthState: string, HealthEvents: table<IsExpired: bool, LastErrorTransitionAt: string, LastModifiedUtcTimestamp: string, LastOkTransitionAt: string, LastWarningTransitionAt: string, SourceUtcTimestamp: string, Description: string, HealthState: string, Property: string, RemoveWhenExpired: bool, SequenceNumber: string, SourceId: string, TimeToLiveInMilliSeconds: string>, HealthStatistics: record<HealthStateCountList: list<record>>, UnhealthyEvaluations: table<HealthEvaluation: record>>"
    get-cluster-health-using-policy: "record<ApplicationHealthStates: table<Name: string, AggregatedHealthState: string>, NodeHealthStates: table<Id: record, Name: string, AggregatedHealthState: string>, AggregatedHealthState: string, HealthEvents: table<IsExpired: bool, LastErrorTransitionAt: string, LastModifiedUtcTimestamp: string, LastOkTransitionAt: string, LastWarningTransitionAt: string, SourceUtcTimestamp: string, Description: string, HealthState: string, Property: string, RemoveWhenExpired: bool, SequenceNumber: string, SourceId: string, TimeToLiveInMilliSeconds: string>, HealthStatistics: record<HealthStateCountList: list<record>>, UnhealthyEvaluations: table<HealthEvaluation: record>>"
    get-cluster-health-chunk: "record<ApplicationHealthStateChunks: record<Items: list<record>, TotalCount: int>, HealthState: string, NodeHealthStateChunks: record<Items: list<record>, TotalCount: int>>"
    get-cluster-health-chunk-using-policy-and-advanced-filters: "record<ApplicationHealthStateChunks: record<Items: list<record>, TotalCount: int>, HealthState: string, NodeHealthStateChunks: record<Items: list<record>, TotalCount: int>>"
    get-cluster-manifest: "record<Manifest: string>"
    get-cluster-version: "record<Version: string>"
    get-cluster-load: "record<LastBalancingEndTimeUtc: string, LastBalancingStartTimeUtc: string, LoadMetricInformation: table<Action: string, ActivityThreshold: string, BalancingThreshold: string, BufferedClusterCapacityRemaining: string, ClusterBufferedCapacity: string, ClusterCapacity: string, ClusterCapacityRemaining: string, ClusterLoad: string, ClusterRemainingBufferedCapacity: string, ClusterRemainingCapacity: string, CurrentClusterLoad: string, DeviationAfter: string, DeviationBefore: string, IsBalancedAfter: bool, IsBalancedBefore: bool, IsClusterCapacityViolation: bool, MaxNodeLoadNodeId: record, MaxNodeLoadValue: string, MaximumNodeLoad: string, MinNodeLoadNodeId: record, MinNodeLoadValue: string, MinimumNodeLoad: string, Name: string, NodeBufferPercentage: string, PlannedLoadRemoval: string>>"
    get-provisioned-fabric-code-version-info-list: "table<CodeVersion: string>"
    get-provisioned-fabric-config-version-info-list: "table<ConfigVersion: string>"
    get-repair-task-list: "table<Action: string, Description: string, Executor: string, ExecutorData: string, Flags: int, History: record<ApprovedUtcTimestamp: string, ClaimedUtcTimestamp: string, CompletedUtcTimestamp: string, CreatedUtcTimestamp: string, ExecutingUtcTimestamp: string, PreparingHealthCheckEndUtcTimestamp: string, PreparingHealthCheckStartUtcTimestamp: string, PreparingUtcTimestamp: string, RestoringHealthCheckEndUtcTimestamp: string, RestoringHealthCheckStartUtcTimestamp: string, RestoringUtcTimestamp: string>, Impact: record<Kind: string>, PerformPreparingHealthCheck: bool, PerformRestoringHealthCheck: bool, PreparingHealthCheckState: string, RestoringHealthCheckState: string, ResultCode: int, ResultDetails: string, ResultStatus: string, State: string, Target: record<Kind: string>, TaskId: string, Version: string>"
    get-upgrade-orchestration-service-state: "record<ServiceState: string>"
    get-cluster-upgrade-progress: "record<CodeVersion: string, ConfigVersion: string, CurrentUpgradeDomainProgress: record<DomainName: string, NodeUpgradeProgressList: list<record>>, FailureReason: string, FailureTimestampUtc: string, NextUpgradeDomain: string, RollingUpgradeMode: string, StartTimestampUtc: string, UnhealthyEvaluations: table<HealthEvaluation: record>, UpgradeDescription: record<ApplicationHealthPolicyMap: list<record>, ClusterHealthPolicy: record<ApplicationTypeHealthPolicyMap: list, ConsiderWarningAsError: bool, MaxPercentUnhealthyApplications: int, MaxPercentUnhealthyNodes: int>, ClusterUpgradeHealthPolicy: record<MaxPercentDeltaUnhealthyNodes: int, MaxPercentUpgradeDomainDeltaUnhealthyNodes: int>, CodeVersion: string, ConfigVersion: string, EnableDeltaHealthEvaluation: bool, ForceRestart: bool, MonitoringPolicy: record<FailureAction: string, HealthCheckRetryTimeoutInMilliseconds: string, HealthCheckStableDurationInMilliseconds: string, HealthCheckWaitDurationInMilliseconds: string, UpgradeDomainTimeoutInMilliseconds: string, UpgradeTimeoutInMilliseconds: string>, RollingUpgradeMode: string, SortOrder: string, UpgradeKind: string, UpgradeReplicaSetCheckTimeoutInSeconds: int>, UpgradeDomainDurationInMilliseconds: string, UpgradeDomainProgressAtFailure: record<DomainName: string, NodeUpgradeProgressList: list<record>>, UpgradeDomains: table<Name: string, State: string>, UpgradeDurationInMilliseconds: string, UpgradeState: string>"
    invoke-infrastructure-command: "binary"
    invoke-infrastructure-query: "binary"
    set-upgrade-orchestration-service-state: "record<CurrentCodeVersion: string, CurrentManifestVersion: string, PendingUpgradeType: string, TargetCodeVersion: string, TargetManifestVersion: string>"
    update-repair-execution-state: "record<Version: string>"
    update-repair-task-health-policy: "record<Version: string>"
    get-application-type-info-list: "record<ContinuationToken: string, Items: table<ApplicationTypeDefinitionKind: string, DefaultParameterList: list, Name: string, Status: string, StatusDetails: string, Version: string>>"
    get-application-type-info-list-by-name: "record<ContinuationToken: string, Items: table<ApplicationTypeDefinitionKind: string, DefaultParameterList: list, Name: string, Status: string, StatusDetails: string, Version: string>>"
    get-application-manifest: "record<Manifest: string>"
    get-service-manifest: "record<Manifest: string>"
    get-service-type-info-list: "table<IsServiceGroup: bool, ServiceManifestName: string, ServiceManifestVersion: string, ServiceTypeDescription: record<Extensions: list, IsStateful: bool, Kind: string, LoadMetrics: list, PlacementConstraints: string, ServicePlacementPolicies: list, ServiceTypeName: string>>"
    get-service-type-info-by-name: "record<IsServiceGroup: bool, ServiceManifestName: string, ServiceManifestVersion: string, ServiceTypeDescription: record<Extensions: list<record>, IsStateful: bool, Kind: string, LoadMetrics: list<record>, PlacementConstraints: string, ServicePlacementPolicies: list<record>, ServiceTypeName: string>>"
    get-application-info-list: "record<ContinuationToken: string, Items: table<ApplicationDefinitionKind: string, HealthState: string, Id: string, Name: string, Parameters: list, Status: string, TypeName: string, TypeVersion: string>>"
    get-application-info: "record<ApplicationDefinitionKind: string, HealthState: string, Id: string, Name: string, Parameters: table<Key: string, Value: string>, Status: string, TypeName: string, TypeVersion: string>"
    get-application-backup-configuration-info: "record<ContinuationToken: string, Items: table<Kind: string, PolicyInheritedFrom: string, PolicyName: string, SuspensionInfo: record>>"
    get-application-backup-list: "record<ContinuationToken: string, Items: table<ApplicationName: string, BackupChainId: string, BackupId: string, BackupLocation: string, BackupType: string, CreationTimeUtc: string, EpochOfLastBackupRecord: record, FailureError: record, LsnOfLastBackupRecord: string, PartitionInformation: record, ServiceManifestVersion: string, ServiceName: string>>"
    get-application-health: "record<DeployedApplicationHealthStates: table<ApplicationName: string, NodeName: string, AggregatedHealthState: string>, Name: string, ServiceHealthStates: table<ServiceName: string, AggregatedHealthState: string>, AggregatedHealthState: string, HealthEvents: table<IsExpired: bool, LastErrorTransitionAt: string, LastModifiedUtcTimestamp: string, LastOkTransitionAt: string, LastWarningTransitionAt: string, SourceUtcTimestamp: string, Description: string, HealthState: string, Property: string, RemoveWhenExpired: bool, SequenceNumber: string, SourceId: string, TimeToLiveInMilliSeconds: string>, HealthStatistics: record<HealthStateCountList: list<record>>, UnhealthyEvaluations: table<HealthEvaluation: record>>"
    get-application-health-using-policy: "record<DeployedApplicationHealthStates: table<ApplicationName: string, NodeName: string, AggregatedHealthState: string>, Name: string, ServiceHealthStates: table<ServiceName: string, AggregatedHealthState: string>, AggregatedHealthState: string, HealthEvents: table<IsExpired: bool, LastErrorTransitionAt: string, LastModifiedUtcTimestamp: string, LastOkTransitionAt: string, LastWarningTransitionAt: string, SourceUtcTimestamp: string, Description: string, HealthState: string, Property: string, RemoveWhenExpired: bool, SequenceNumber: string, SourceId: string, TimeToLiveInMilliSeconds: string>, HealthStatistics: record<HealthStateCountList: list<record>>, UnhealthyEvaluations: table<HealthEvaluation: record>>"
    get-application-load-info: "record<ApplicationLoadMetricInformation: table<MaximumCapacity: int, Name: string, ReservationCapacity: int, TotalApplicationCapacity: int>, Id: string, MaximumNodes: int, MinimumNodes: int, NodeCount: int>"
    get-service-info-list: "record<ContinuationToken: string, Items: table<HealthState: string, Id: string, IsServiceGroup: bool, ManifestVersion: string, Name: string, ServiceKind: string, ServiceStatus: string, TypeName: string>>"
    get-service-info: "record<HealthState: string, Id: string, IsServiceGroup: bool, ManifestVersion: string, Name: string, ServiceKind: string, ServiceStatus: string, TypeName: string>"
    get-application-upgrade: "record<CurrentUpgradeDomainProgress: record<DomainName: string, NodeUpgradeProgressList: list<record>>, FailureReason: string, FailureTimestampUtc: string, Name: string, NextUpgradeDomain: string, RollingUpgradeMode: string, StartTimestampUtc: string, TargetApplicationTypeVersion: string, TypeName: string, UnhealthyEvaluations: table<HealthEvaluation: record>, UpgradeDescription: record<ApplicationHealthPolicy: record<ConsiderWarningAsError: bool, DefaultServiceTypeHealthPolicy: record, MaxPercentUnhealthyDeployedApplications: int, ServiceTypeHealthPolicyMap: list>, ForceRestart: bool, MonitoringPolicy: record<FailureAction: string, HealthCheckRetryTimeoutInMilliseconds: string, HealthCheckStableDurationInMilliseconds: string, HealthCheckWaitDurationInMilliseconds: string, UpgradeDomainTimeoutInMilliseconds: string, UpgradeTimeoutInMilliseconds: string>, Name: string, Parameters: list<record>, RollingUpgradeMode: string, SortOrder: string, TargetApplicationTypeVersion: string, UpgradeKind: string, UpgradeReplicaSetCheckTimeoutInSeconds: int>, UpgradeDomainDurationInMilliseconds: string, UpgradeDomainProgressAtFailure: record<DomainName: string, NodeUpgradeProgressList: list<record>>, UpgradeDomains: table<Name: string, State: string>, UpgradeDurationInMilliseconds: string, UpgradeState: string, UpgradeStatusDetails: string>"
    get-backups-from-backup-location: "record<ContinuationToken: string, Items: table<ApplicationName: string, BackupChainId: string, BackupId: string, BackupLocation: string, BackupType: string, CreationTimeUtc: string, EpochOfLastBackupRecord: record, FailureError: record, LsnOfLastBackupRecord: string, PartitionInformation: record, ServiceManifestVersion: string, ServiceName: string>>"
    get-backup-policy-list: "record<ContinuationToken: string, Items: table<AutoRestoreOnDataLoss: bool, MaxIncrementalBackups: int, Name: string, RetentionPolicy: record, Schedule: record, Storage: record>>"
    get-backup-policy-by-name: "record<AutoRestoreOnDataLoss: bool, MaxIncrementalBackups: int, Name: string, RetentionPolicy: record<RetentionPolicyType: string>, Schedule: record<ScheduleKind: string>, Storage: record<FriendlyName: string, StorageKind: string>>"
    get-all-entities-backed-up-by-policy: "record<ContinuationToken: string, Items: table<EntityKind: string>>"
    get-compose-deployment-status-list: "record<ContinuationToken: string, Items: table<ApplicationName: string, Name: string, Status: string, StatusDetails: string>>"
    get-compose-deployment-status: "record<ApplicationName: string, Name: string, Status: string, StatusDetails: string>"
    get-compose-deployment-upgrade-progress: "record<ApplicationHealthPolicy: record<ConsiderWarningAsError: bool, DefaultServiceTypeHealthPolicy: record<MaxPercentUnhealthyPartitionsPerService: int, MaxPercentUnhealthyReplicasPerPartition: int, MaxPercentUnhealthyServices: int>, MaxPercentUnhealthyDeployedApplications: int, ServiceTypeHealthPolicyMap: list<record>>, ApplicationName: string, ApplicationUnhealthyEvaluations: table<HealthEvaluation: record>, ApplicationUpgradeStatusDetails: string, CurrentUpgradeDomainDuration: string, CurrentUpgradeDomainProgress: record<DomainName: string, NodeUpgradeProgressList: list<record>>, DeploymentName: string, FailureReason: string, FailureTimestampUtc: string, ForceRestart: bool, MonitoringPolicy: record<FailureAction: string, HealthCheckRetryTimeoutInMilliseconds: string, HealthCheckStableDurationInMilliseconds: string, HealthCheckWaitDurationInMilliseconds: string, UpgradeDomainTimeoutInMilliseconds: string, UpgradeTimeoutInMilliseconds: string>, RollingUpgradeMode: string, StartTimestampUtc: string, TargetApplicationTypeVersion: string, UpgradeDomainProgressAtFailure: record<DomainName: string, NodeUpgradeProgressList: list<record>>, UpgradeDuration: string, UpgradeKind: string, UpgradeReplicaSetCheckTimeoutInSeconds: int, UpgradeState: string, UpgradeStatusDetails: string>"
    get-applications-event-list: "table<ApplicationId: string, Category: string, EventInstanceId: string, HasCorrelatedEvents: bool, Kind: string, TimeStamp: string>"
    get-application-event-list: "table<ApplicationId: string, Category: string, EventInstanceId: string, HasCorrelatedEvents: bool, Kind: string, TimeStamp: string>"
    get-cluster-event-list: "table<Category: string, EventInstanceId: string, HasCorrelatedEvents: bool, Kind: string, TimeStamp: string>"
    get-containers-event-list: "table<Category: string, EventInstanceId: string, HasCorrelatedEvents: bool, Kind: string, TimeStamp: string>"
    get-correlated-event-list: "table<Category: string, EventInstanceId: string, HasCorrelatedEvents: bool, Kind: string, TimeStamp: string>"
    get-nodes-event-list: "table<NodeName: string, Category: string, EventInstanceId: string, HasCorrelatedEvents: bool, Kind: string, TimeStamp: string>"
    get-node-event-list: "table<NodeName: string, Category: string, EventInstanceId: string, HasCorrelatedEvents: bool, Kind: string, TimeStamp: string>"
    get-partitions-event-list: "table<PartitionId: string, Category: string, EventInstanceId: string, HasCorrelatedEvents: bool, Kind: string, TimeStamp: string>"
    get-partition-event-list: "table<PartitionId: string, Category: string, EventInstanceId: string, HasCorrelatedEvents: bool, Kind: string, TimeStamp: string>"
    get-partition-replicas-event-list: "table<PartitionId: string, ReplicaId: int, Category: string, EventInstanceId: string, HasCorrelatedEvents: bool, Kind: string, TimeStamp: string>"
    get-partition-replica-event-list: "table<PartitionId: string, ReplicaId: int, Category: string, EventInstanceId: string, HasCorrelatedEvents: bool, Kind: string, TimeStamp: string>"
    get-services-event-list: "table<ServiceId: string, Category: string, EventInstanceId: string, HasCorrelatedEvents: bool, Kind: string, TimeStamp: string>"
    get-service-event-list: "table<ServiceId: string, Category: string, EventInstanceId: string, HasCorrelatedEvents: bool, Kind: string, TimeStamp: string>"
    get-fault-operation-list: "table<OperationId: string, State: string, Type: string>"
    get-node-transition-progress: "record<NodeTransitionResult: record<ErrorCode: int, NodeResult: record<NodeInstanceId: string, NodeName: string>>, State: string>"
    get-data-loss-progress: "record<InvokeDataLossResult: record<ErrorCode: int, SelectedPartition: record<PartitionId: string, ServiceName: string>>, State: string>"
    get-quorum-loss-progress: "record<InvokeQuorumLossResult: record<ErrorCode: int, SelectedPartition: record<PartitionId: string, ServiceName: string>>, State: string>"
    get-partition-restart-progress: "record<RestartPartitionResult: record<ErrorCode: int, SelectedPartition: record<PartitionId: string, ServiceName: string>>, State: string>"
    get-image-store-root-content: "record<StoreFiles: table<FileSize: string, FileVersion: record, ModifiedDate: string, StoreRelativePath: string>, StoreFolders: table<FileCount: string, StoreRelativePath: string>>"
    get-image-store-root-folder-size: "record<FolderSize: string, StoreRelativePath: string>"
    get-image-store-upload-session-by-id: "record<UploadSessions: table<ExpectedRanges: list, FileSize: string, ModifiedDate: string, SessionId: string, StoreRelativePath: string>>"
    get-image-store-content: "record<StoreFiles: table<FileSize: string, FileVersion: record, ModifiedDate: string, StoreRelativePath: string>, StoreFolders: table<FileCount: string, StoreRelativePath: string>>"
    get-image-store-folder-size: "record<FolderSize: string, StoreRelativePath: string>"
    get-image-store-upload-session-by-path: "record<UploadSessions: table<ExpectedRanges: list, FileSize: string, ModifiedDate: string, SessionId: string, StoreRelativePath: string>>"
    get-property-info-list: "record<ContinuationToken: string, IsConsistent: bool, Properties: table<Metadata: record, Name: string, Value: record>>"
    submit-property-batch: "record<Properties: any, Kind: string>"
    get-property-info: "record<Metadata: record<CustomTypeId: string, LastModifiedUtcTimestamp: string, Parent: string, SequenceNumber: string, SizeInBytes: int, TypeId: string>, Name: string, Value: record<Kind: string>>"
    get-sub-name-info-list: "record<ContinuationToken: string, IsConsistent: bool, SubNames: list<string>>"
    get-node-info-list: "record<ContinuationToken: string, Items: table<CodeVersion: string, ConfigVersion: string, FaultDomain: string, HealthState: string, Id: record, InstanceId: string, IpAddressOrFQDN: string, IsSeedNode: bool, IsStopped: bool, Name: string, NodeDeactivationInfo: record, NodeDownAt: string, NodeDownTimeInSeconds: string, NodeStatus: string, NodeUpAt: string, NodeUpTimeInSeconds: string, Type: string, UpgradeDomain: string>>"
    get-node-info: "record<CodeVersion: string, ConfigVersion: string, FaultDomain: string, HealthState: string, Id: record<Id: string>, InstanceId: string, IpAddressOrFQDN: string, IsSeedNode: bool, IsStopped: bool, Name: string, NodeDeactivationInfo: record<NodeDeactivationIntent: string, NodeDeactivationStatus: string, NodeDeactivationTask: list<record>, PendingSafetyChecks: list<record>>, NodeDownAt: string, NodeDownTimeInSeconds: string, NodeStatus: string, NodeUpAt: string, NodeUpTimeInSeconds: string, Type: string, UpgradeDomain: string>"
    get-deployed-application-info-list: "record<ContinuationToken: string, Items: table<HealthState: string, Id: string, LogDirectory: string, Name: string, Status: string, TempDirectory: string, TypeName: string, WorkDirectory: string>>"
    get-deployed-application-info: "record<HealthState: string, Id: string, LogDirectory: string, Name: string, Status: string, TempDirectory: string, TypeName: string, WorkDirectory: string>"
    get-deployed-code-package-info-list: "table<HostIsolationMode: string, HostType: string, MainEntryPoint: record<CodePackageEntryPointStatistics: record, EntryPointLocation: string, InstanceId: string, NextActivationTime: string, ProcessId: string, RunAsUserName: string, Status: string>, Name: string, RunFrequencyInterval: string, ServiceManifestName: string, ServicePackageActivationId: string, SetupEntryPoint: record<CodePackageEntryPointStatistics: record, EntryPointLocation: string, InstanceId: string, NextActivationTime: string, ProcessId: string, RunAsUserName: string, Status: string>, Status: string, Version: string>"
    invoke-container-api: "record<ContainerApiResult: record<Body: string, Content-Encoding: string, Content-Type: string, Status: int>>"
    get-container-logs-deployed-on-node: "record<Content: string>"
    get-deployed-application-health: "record<DeployedServicePackageHealthStates: table<ApplicationName: string, NodeName: string, ServiceManifestName: string, ServicePackageActivationId: string, AggregatedHealthState: string>, Name: string, NodeName: string, AggregatedHealthState: string, HealthEvents: table<IsExpired: bool, LastErrorTransitionAt: string, LastModifiedUtcTimestamp: string, LastOkTransitionAt: string, LastWarningTransitionAt: string, SourceUtcTimestamp: string, Description: string, HealthState: string, Property: string, RemoveWhenExpired: bool, SequenceNumber: string, SourceId: string, TimeToLiveInMilliSeconds: string>, HealthStatistics: record<HealthStateCountList: list<record>>, UnhealthyEvaluations: table<HealthEvaluation: record>>"
    get-deployed-application-health-using-policy: "record<DeployedServicePackageHealthStates: table<ApplicationName: string, NodeName: string, ServiceManifestName: string, ServicePackageActivationId: string, AggregatedHealthState: string>, Name: string, NodeName: string, AggregatedHealthState: string, HealthEvents: table<IsExpired: bool, LastErrorTransitionAt: string, LastModifiedUtcTimestamp: string, LastOkTransitionAt: string, LastWarningTransitionAt: string, SourceUtcTimestamp: string, Description: string, HealthState: string, Property: string, RemoveWhenExpired: bool, SequenceNumber: string, SourceId: string, TimeToLiveInMilliSeconds: string>, HealthStatistics: record<HealthStateCountList: list<record>>, UnhealthyEvaluations: table<HealthEvaluation: record>>"
    get-deployed-service-replica-info-list: "table<Address: string, CodePackageName: string, HostProcessId: string, PartitionId: string, ReplicaStatus: string, ServiceKind: string, ServiceManifestName: string, ServiceName: string, ServicePackageActivationId: string, ServiceTypeName: string>"
    get-deployed-service-package-info-list: "table<Name: string, ServicePackageActivationId: string, Status: string, Version: string>"
    get-deployed-service-package-info-list-by-name: "table<Name: string, ServicePackageActivationId: string, Status: string, Version: string>"
    get-deployed-service-package-health: "record<ApplicationName: string, NodeName: string, ServiceManifestName: string, AggregatedHealthState: string, HealthEvents: table<IsExpired: bool, LastErrorTransitionAt: string, LastModifiedUtcTimestamp: string, LastOkTransitionAt: string, LastWarningTransitionAt: string, SourceUtcTimestamp: string, Description: string, HealthState: string, Property: string, RemoveWhenExpired: bool, SequenceNumber: string, SourceId: string, TimeToLiveInMilliSeconds: string>, HealthStatistics: record<HealthStateCountList: list<record>>, UnhealthyEvaluations: table<HealthEvaluation: record>>"
    get-deployed-service-package-health-using-policy: "record<ApplicationName: string, NodeName: string, ServiceManifestName: string, AggregatedHealthState: string, HealthEvents: table<IsExpired: bool, LastErrorTransitionAt: string, LastModifiedUtcTimestamp: string, LastOkTransitionAt: string, LastWarningTransitionAt: string, SourceUtcTimestamp: string, Description: string, HealthState: string, Property: string, RemoveWhenExpired: bool, SequenceNumber: string, SourceId: string, TimeToLiveInMilliSeconds: string>, HealthStatistics: record<HealthStateCountList: list<record>>, UnhealthyEvaluations: table<HealthEvaluation: record>>"
    get-deployed-service-type-info-list: "table<CodePackageName: string, ServiceManifestName: string, ServicePackageActivationId: string, ServiceTypeName: string, Status: string>"
    get-deployed-service-type-info-by-name: "table<CodePackageName: string, ServiceManifestName: string, ServicePackageActivationId: string, ServiceTypeName: string, Status: string>"
    get-node-health: "record<Name: string, AggregatedHealthState: string, HealthEvents: table<IsExpired: bool, LastErrorTransitionAt: string, LastModifiedUtcTimestamp: string, LastOkTransitionAt: string, LastWarningTransitionAt: string, SourceUtcTimestamp: string, Description: string, HealthState: string, Property: string, RemoveWhenExpired: bool, SequenceNumber: string, SourceId: string, TimeToLiveInMilliSeconds: string>, HealthStatistics: record<HealthStateCountList: list<record>>, UnhealthyEvaluations: table<HealthEvaluation: record>>"
    get-node-health-using-policy: "record<Name: string, AggregatedHealthState: string, HealthEvents: table<IsExpired: bool, LastErrorTransitionAt: string, LastModifiedUtcTimestamp: string, LastOkTransitionAt: string, LastWarningTransitionAt: string, SourceUtcTimestamp: string, Description: string, HealthState: string, Property: string, RemoveWhenExpired: bool, SequenceNumber: string, SourceId: string, TimeToLiveInMilliSeconds: string>, HealthStatistics: record<HealthStateCountList: list<record>>, UnhealthyEvaluations: table<HealthEvaluation: record>>"
    get-node-load-info: "record<NodeLoadMetricInformation: table<BufferedNodeCapacityRemaining: string, CurrentNodeLoad: string, IsCapacityViolation: bool, Name: string, NodeBufferedCapacity: string, NodeCapacity: string, NodeCapacityRemaining: string, NodeLoad: string, NodeRemainingBufferedCapacity: string, NodeRemainingCapacity: string, PlannedNodeLoadRemoval: string>, NodeName: string>"
    get-deployed-service-replica-detail-info-by-partition-id: "record<CurrentServiceOperation: string, CurrentServiceOperationStartTimeUtc: string, PartitionId: string, ReportedLoad: table<CurrentValue: string, LastReportedUtc: string, Name: string, Value: int>, ServiceKind: string, ServiceName: string>"
    get-deployed-service-replica-detail-info: "record<CurrentServiceOperation: string, CurrentServiceOperationStartTimeUtc: string, PartitionId: string, ReportedLoad: table<CurrentValue: string, LastReportedUtc: string, Name: string, Value: int>, ServiceKind: string, ServiceName: string>"
    get-partition-info: "record<HealthState: string, PartitionInformation: record<Id: string, ServicePartitionKind: string>, PartitionStatus: string, ServiceKind: string>"
    get-partition-backup-configuration-info: "record<PartitionId: string, ServiceName: string, Kind: string, PolicyInheritedFrom: string, PolicyName: string, SuspensionInfo: record<IsSuspended: bool, SuspensionInheritedFrom: string>>"
    get-partition-backup-progress: "record<BackupId: string, BackupLocation: string, BackupState: string, EpochOfLastBackupRecord: record<ConfigurationVersion: string, DataLossVersion: string>, FailureError: record<Code: string, Message: string>, LsnOfLastBackupRecord: string, TimeStampUtc: string>"
    get-partition-backup-list: "record<ContinuationToken: string, Items: table<ApplicationName: string, BackupChainId: string, BackupId: string, BackupLocation: string, BackupType: string, CreationTimeUtc: string, EpochOfLastBackupRecord: record, FailureError: record, LsnOfLastBackupRecord: string, PartitionInformation: record, ServiceManifestVersion: string, ServiceName: string>>"
    get-partition-health: "record<PartitionId: string, ReplicaHealthStates: table<PartitionId: string, ServiceKind: string, AggregatedHealthState: string>, AggregatedHealthState: string, HealthEvents: table<IsExpired: bool, LastErrorTransitionAt: string, LastModifiedUtcTimestamp: string, LastOkTransitionAt: string, LastWarningTransitionAt: string, SourceUtcTimestamp: string, Description: string, HealthState: string, Property: string, RemoveWhenExpired: bool, SequenceNumber: string, SourceId: string, TimeToLiveInMilliSeconds: string>, HealthStatistics: record<HealthStateCountList: list<record>>, UnhealthyEvaluations: table<HealthEvaluation: record>>"
    get-partition-health-using-policy: "record<PartitionId: string, ReplicaHealthStates: table<PartitionId: string, ServiceKind: string, AggregatedHealthState: string>, AggregatedHealthState: string, HealthEvents: table<IsExpired: bool, LastErrorTransitionAt: string, LastModifiedUtcTimestamp: string, LastOkTransitionAt: string, LastWarningTransitionAt: string, SourceUtcTimestamp: string, Description: string, HealthState: string, Property: string, RemoveWhenExpired: bool, SequenceNumber: string, SourceId: string, TimeToLiveInMilliSeconds: string>, HealthStatistics: record<HealthStateCountList: list<record>>, UnhealthyEvaluations: table<HealthEvaluation: record>>"
    get-partition-load-information: "record<PartitionId: string, PrimaryLoadMetricReports: table<CurrentValue: string, LastReportedUtc: string, Name: string, Value: string>, SecondaryLoadMetricReports: table<CurrentValue: string, LastReportedUtc: string, Name: string, Value: string>>"
    get-replica-info-list: "record<ContinuationToken: string, Items: table<Address: string, HealthState: string, LastInBuildDurationInSeconds: string, NodeName: string, ReplicaStatus: string, ServiceKind: string>>"
    get-replica-info: "record<Address: string, HealthState: string, LastInBuildDurationInSeconds: string, NodeName: string, ReplicaStatus: string, ServiceKind: string>"
    get-replica-health: "record<PartitionId: string, ServiceKind: string, AggregatedHealthState: string, HealthEvents: table<IsExpired: bool, LastErrorTransitionAt: string, LastModifiedUtcTimestamp: string, LastOkTransitionAt: string, LastWarningTransitionAt: string, SourceUtcTimestamp: string, Description: string, HealthState: string, Property: string, RemoveWhenExpired: bool, SequenceNumber: string, SourceId: string, TimeToLiveInMilliSeconds: string>, HealthStatistics: record<HealthStateCountList: list<record>>, UnhealthyEvaluations: table<HealthEvaluation: record>>"
    get-replica-health-using-policy: "record<PartitionId: string, ServiceKind: string, AggregatedHealthState: string, HealthEvents: table<IsExpired: bool, LastErrorTransitionAt: string, LastModifiedUtcTimestamp: string, LastOkTransitionAt: string, LastWarningTransitionAt: string, SourceUtcTimestamp: string, Description: string, HealthState: string, Property: string, RemoveWhenExpired: bool, SequenceNumber: string, SourceId: string, TimeToLiveInMilliSeconds: string>, HealthStatistics: record<HealthStateCountList: list<record>>, UnhealthyEvaluations: table<HealthEvaluation: record>>"
    get-partition-restore-progress: "record<FailureError: record<Code: string, Message: string>, RestoreState: string, RestoredEpoch: record<ConfigurationVersion: string, DataLossVersion: string>, RestoredLsn: string, TimeStampUtc: string>"
    get-service-name-info: "record<Id: string, Name: string>"
    mesh-application-list: "record<ContinuationToken: string, Items: table<identity: record, name: string, properties: record>>"
    mesh-application-get: "record<identity: record<principalId: string, tenantId: string, tokenServiceEndpoint: string, type: string, userAssignedIdentities: record>, name: string, properties: record<debugParams: string, description: string, diagnostics: record<defaultSinkRefs: list, enabled: bool, sinks: list>, healthState: string, serviceNames: list<string>, services: list<record>, status: string, statusDetails: string, unhealthyEvaluation: string>>"
    mesh-application-create-or-update: "record<identity: record<principalId: string, tenantId: string, tokenServiceEndpoint: string, type: string, userAssignedIdentities: record>, name: string, properties: record<debugParams: string, description: string, diagnostics: record<defaultSinkRefs: list, enabled: bool, sinks: list>, healthState: string, serviceNames: list<string>, services: list<record>, status: string, statusDetails: string, unhealthyEvaluation: string>>"
    mesh-service-list: "record<ContinuationToken: string, Items: table<name: string, properties: record>>"
    mesh-service-get: "record<name: string, properties: record<codePackages: list<record>, diagnostics: record<enabled: bool, sinkRefs: list>, networkRefs: list<record>, osType: string, autoScalingPolicies: list<record>, description: string, healthState: string, identityRefs: list<record>, replicaCount: int, status: string, statusDetails: string, unhealthyEvaluation: string>>"
    mesh-service-replica-list: "record<ContinuationToken: string, Items: table<replicaName: string, codePackages: list, diagnostics: record, networkRefs: list, osType: string>>"
    mesh-service-replica-get: "record<replicaName: string, codePackages: table<commands: list, diagnostics: record, endpoints: list, entrypoint: string, environmentVariables: list, image: string, imageRegistryCredential: record, instanceView: record, labels: list, name: string, reliableCollectionsRefs: list, resources: record, settings: list, volumeRefs: list, volumes: list>, diagnostics: record<enabled: bool, sinkRefs: list<string>>, networkRefs: table<endpointRefs: list, name: string>, osType: string>"
    mesh-code-package-get-container-logs: "record<Content: string>"
    mesh-gateway-list: "record<ContinuationToken: string, Items: table<name: string, properties: record>>"
    mesh-gateway-get: "record<name: string, properties: record<description: string, destinationNetwork: record<endpointRefs: list, name: string>, http: list<record>, ipAddress: string, sourceNetwork: record<endpointRefs: list, name: string>, status: string, statusDetails: string, tcp: list<record>>>"
    mesh-gateway-create-or-update: "record<name: string, properties: record<description: string, destinationNetwork: record<endpointRefs: list, name: string>, http: list<record>, ipAddress: string, sourceNetwork: record<endpointRefs: list, name: string>, status: string, statusDetails: string, tcp: list<record>>>"
    mesh-network-list: "record<ContinuationToken: string, Items: table<name: string, properties: record>>"
    mesh-network-get: "record<name: string, properties: record<description: string, status: string, statusDetails: string, kind: string>>"
    mesh-network-create-or-update: "record<name: string, properties: record<description: string, status: string, statusDetails: string, kind: string>>"
    mesh-secret-list: "record<ContinuationToken: string, Items: table<name: string, properties: record>>"
    mesh-secret-get: "record<name: string, properties: record<contentType: string, description: string, status: string, statusDetails: string, kind: string>>"
    mesh-secret-create-or-update: "record<name: string, properties: record<contentType: string, description: string, status: string, statusDetails: string, kind: string>>"
    mesh-secret-value-list: "record<ContinuationToken: string, Items: table<name: string, properties: record>>"
    mesh-secret-value-get: "record<name: string, properties: record<value: string>>"
    mesh-secret-value-add-value: "record<name: string, properties: record<value: string>>"
    mesh-secret-value-show: "record<value: string>"
    mesh-volume-list: "record<ContinuationToken: string, Items: table<name: string, properties: record>>"
    mesh-volume-get: "record<name: string, properties: record<azureFileParameters: record<accountKey: string, accountName: string, shareName: string>, description: string, provider: string, status: string, statusDetails: string>>"
    mesh-volume-create-or-update: "record<name: string, properties: record<azureFileParameters: record<accountKey: string, accountName: string, shareName: string>, description: string, provider: string, status: string, statusDetails: string>>"
    get-application-name-info: "record<Id: string, Name: string>"
    get-service-backup-configuration-info: "record<ContinuationToken: string, Items: table<Kind: string, PolicyInheritedFrom: string, PolicyName: string, SuspensionInfo: record>>"
    get-service-backup-list: "record<ContinuationToken: string, Items: table<ApplicationName: string, BackupChainId: string, BackupId: string, BackupLocation: string, BackupType: string, CreationTimeUtc: string, EpochOfLastBackupRecord: record, FailureError: record, LsnOfLastBackupRecord: string, PartitionInformation: record, ServiceManifestVersion: string, ServiceName: string>>"
    get-service-description: "record<ApplicationName: string, CorrelationScheme: table<Scheme: string, ServiceName: string>, DefaultMoveCost: string, InitializationData: list<int>, IsDefaultMoveCostSpecified: bool, PartitionDescription: record<PartitionScheme: string>, PlacementConstraints: string, ScalingPolicies: table<ScalingMechanism: record, ScalingTrigger: record>, ServiceDnsName: string, ServiceKind: string, ServiceLoadMetrics: table<DefaultLoad: int, Name: string, PrimaryDefaultLoad: int, SecondaryDefaultLoad: int, Weight: string>, ServiceName: string, ServicePackageActivationMode: string, ServicePlacementPolicies: table<Type: string>, ServiceTypeName: string>"
    get-service-health: "record<Name: string, PartitionHealthStates: table<PartitionId: string, AggregatedHealthState: string>, AggregatedHealthState: string, HealthEvents: table<IsExpired: bool, LastErrorTransitionAt: string, LastModifiedUtcTimestamp: string, LastOkTransitionAt: string, LastWarningTransitionAt: string, SourceUtcTimestamp: string, Description: string, HealthState: string, Property: string, RemoveWhenExpired: bool, SequenceNumber: string, SourceId: string, TimeToLiveInMilliSeconds: string>, HealthStatistics: record<HealthStateCountList: list<record>>, UnhealthyEvaluations: table<HealthEvaluation: record>>"
    get-service-health-using-policy: "record<Name: string, PartitionHealthStates: table<PartitionId: string, AggregatedHealthState: string>, AggregatedHealthState: string, HealthEvents: table<IsExpired: bool, LastErrorTransitionAt: string, LastModifiedUtcTimestamp: string, LastOkTransitionAt: string, LastWarningTransitionAt: string, SourceUtcTimestamp: string, Description: string, HealthState: string, Property: string, RemoveWhenExpired: bool, SequenceNumber: string, SourceId: string, TimeToLiveInMilliSeconds: string>, HealthStatistics: record<HealthStateCountList: list<record>>, UnhealthyEvaluations: table<HealthEvaluation: record>>"
    get-partition-info-list: "record<ContinuationToken: string, Items: table<HealthState: string, PartitionInformation: record, PartitionStatus: string, ServiceKind: string>>"
    get-unplaced-replica-information: "record<PartitionId: string, ServiceName: string, UnplacedReplicaDetails: list<string>>"
    resolve-service: "record<Endpoints: table<Address: string, Kind: string>, Name: string, PartitionInformation: record<Id: string, ServicePartitionKind: string>, Version: string>"
    get-chaos: "record<ChaosParameters: record<ChaosTargetFilter: record<ApplicationInclusionList: list, NodeTypeInclusionList: list>, ClusterHealthPolicy: record<ApplicationTypeHealthPolicyMap: list, ConsiderWarningAsError: bool, MaxPercentUnhealthyApplications: int, MaxPercentUnhealthyNodes: int>, Context: record<Map: any>, EnableMoveReplicaFaults: bool, MaxClusterStabilizationTimeoutInSeconds: int, MaxConcurrentFaults: int, TimeToRunInSeconds: string, WaitTimeBetweenFaultsInSeconds: int, WaitTimeBetweenIterationsInSeconds: int>, ScheduleStatus: string, Status: string>"
    get-chaos-events: "record<ContinuationToken: string, History: table<ChaosEvent: record>>"
    get-chaos-schedule: "record<Schedule: record<ChaosParametersDictionary: list<record>, ExpiryDate: string, Jobs: list<record>, StartDate: string>, Version: int>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["cancel-repair-task" "create-repair-task" "delete-repair-task" "force-approve-repair-task" "get-aad-metadata" "get-cluster-configuration" "get-cluster-configuration-upgrade-status" "get-cluster-health" "get-cluster-health-using-policy" "get-cluster-health-chunk" "get-cluster-health-chunk-using-policy-and-advanced-filters" "get-cluster-manifest" "get-cluster-version" "get-cluster-load" "get-provisioned-fabric-code-version-info-list" "get-provisioned-fabric-config-version-info-list" "get-repair-task-list" "get-upgrade-orchestration-service-state" "get-cluster-upgrade-progress" "invoke-infrastructure-command" "invoke-infrastructure-query" "resume-cluster-upgrade" "provision-cluster" "recover-all-partitions" "recover-system-partitions" "report-cluster-health" "rollback-cluster-upgrade" "set-upgrade-orchestration-service-state" "start-cluster-configuration-upgrade" "toggle-verbose-service-placement-health-reporting" "unprovision-cluster" "update-repair-execution-state" "update-repair-task-health-policy" "update-cluster-upgrade" "start-cluster-upgrade" "get-application-type-info-list" "provision-application-type" "get-application-type-info-list-by-name" "get-application-manifest" "get-service-manifest" "get-service-type-info-list" "get-service-type-info-by-name" "unprovision-application-type" "get-application-info-list" "create-application" "get-application-info" "delete-application" "disable-application-backup" "enable-application-backup" "get-application-backup-configuration-info" "get-application-backup-list" "get-application-health" "get-application-health-using-policy" "get-application-load-info" "get-service-info-list" "create-service" "create-service-from-template" "get-service-info" "get-application-upgrade" "resume-application-upgrade" "report-application-health" "resume-application-backup" "rollback-application-upgrade" "suspend-application-backup" "update-application-upgrade" "start-application-upgrade" "get-backups-from-backup-location" "get-backup-policy-list" "create-backup-policy" "get-backup-policy-by-name" "delete-backup-policy" "get-all-entities-backed-up-by-policy" "update-backup-policy" "get-compose-deployment-status-list" "create-compose-deployment" "get-compose-deployment-status" "remove-compose-deployment" "get-compose-deployment-upgrade-progress" "start-rollback-compose-deployment-upgrade" "start-compose-deployment-upgrade" "get-applications-event-list" "get-application-event-list" "get-cluster-event-list" "get-containers-event-list" "get-correlated-event-list" "get-nodes-event-list" "get-node-event-list" "get-partitions-event-list" "get-partition-event-list" "get-partition-replicas-event-list" "get-partition-replica-event-list" "get-services-event-list" "get-service-event-list" "get-fault-operation-list" "cancel-operation" "get-node-transition-progress" "start-node-transition" "get-data-loss-progress" "get-quorum-loss-progress" "get-partition-restart-progress" "start-data-loss" "start-quorum-loss" "start-partition-restart" "get-image-store-root-content" "commit-image-store-upload-session" "copy-image-store-content" "delete-image-store-upload-session" "get-image-store-root-folder-size" "get-image-store-upload-session-by-id" "delete-image-store-content" "get-image-store-content" "upload-file" "get-image-store-folder-size" "get-image-store-upload-session-by-path" "upload-file-chunk" "create-name" "delete-name" "get-name-exists-info" "get-property-info-list" "submit-property-batch" "delete-property" "get-property-info" "put-property" "get-sub-name-info-list" "get-node-info-list" "get-node-info" "enable-node" "disable-node" "deploy-service-package-to-node" "get-deployed-application-info-list" "get-deployed-application-info" "get-deployed-code-package-info-list" "invoke-container-api" "get-container-logs-deployed-on-node" "restart-deployed-code-package" "get-deployed-application-health" "get-deployed-application-health-using-policy" "get-deployed-service-replica-info-list" "get-deployed-service-package-info-list" "get-deployed-service-package-info-list-by-name" "get-deployed-service-package-health" "get-deployed-service-package-health-using-policy" "report-deployed-service-package-health" "get-deployed-service-type-info-list" "get-deployed-service-type-info-by-name" "report-deployed-application-health" "get-node-health" "get-node-health-using-policy" "get-node-load-info" "get-deployed-service-replica-detail-info-by-partition-id" "remove-replica" "get-deployed-service-replica-detail-info" "restart-replica" "remove-node-state" "report-node-health" "restart-node" "get-partition-info" "backup-partition" "disable-partition-backup" "enable-partition-backup" "get-partition-backup-configuration-info" "get-partition-backup-progress" "get-partition-backup-list" "get-partition-health" "get-partition-health-using-policy" "get-partition-load-information" "get-replica-info-list" "get-replica-info" "get-replica-health" "get-replica-health-using-policy" "report-replica-health" "get-partition-restore-progress" "get-service-name-info" "move-primary-replica" "move-secondary-replica" "recover-partition" "report-partition-health" "reset-partition-load" "restore-partition" "resume-partition-backup" "suspend-partition-backup" "mesh-application-list" "mesh-application-delete" "mesh-application-get" "mesh-application-create-or-update" "mesh-service-list" "mesh-service-get" "mesh-service-replica-list" "mesh-service-replica-get" "mesh-code-package-get-container-logs" "mesh-gateway-list" "mesh-gateway-delete" "mesh-gateway-get" "mesh-gateway-create-or-update" "mesh-network-list" "mesh-network-delete" "mesh-network-get" "mesh-network-create-or-update" "mesh-secret-list" "mesh-secret-delete" "mesh-secret-get" "mesh-secret-create-or-update" "mesh-secret-value-list" "mesh-secret-value-delete" "mesh-secret-value-get" "mesh-secret-value-add-value" "mesh-secret-value-show" "mesh-volume-list" "mesh-volume-delete" "mesh-volume-get" "mesh-volume-create-or-update" "recover-service-partitions" "delete-service" "disable-service-backup" "enable-service-backup" "get-application-name-info" "get-service-backup-configuration-info" "get-service-backup-list" "get-service-description" "get-service-health" "get-service-health-using-policy" "get-partition-info-list" "get-unplaced-replica-information" "report-service-health" "resolve-service" "resume-service-backup" "suspend-service-backup" "update-service" "get-chaos" "start-chaos" "stop-chaos" "get-chaos-events" "get-chaos-schedule" "post-chaos-schedule" "commands"] | sort) } | get name | first)
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

# Requests the cancellation of the given repair task.
#
# POST /$/CancelRepairTask
# Returns: record<Version: string>
# operationId: CancelRepairTask
export def "cancel-repair-task" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --request-abort: oneof<nothing, bool> # _True_ if the repair should be stopped as soon as possible even if it has already started executing. _False_ if the repair should be cancelled only if execution has not yet started.
  task_id: string # The ID of the repair task.
  --version: string # The current version number of the repair task. If non-zero, then the request will only succeed if this value matches the actual current version of the repair task. If zero, then no version check is performed.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/$/CancelRepairTask"
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}]
    body: {content_type: "application/json", kind: json, fields: [{name: RequestAbort, var: request_abort}, {name: TaskId, var: task_id}, {name: Version, var: version}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, request_abort: $request_abort, task_id: $task_id, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new repair task.
#
# POST /$/CreateRepairTask
# Returns: record<Version: string>
# operationId: CreateRepairTask
export def "create-repair-task" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  action: string # The requested repair action. Must be specified when the repair task is created, and is immutable once set.
  --description: string # A description of the purpose of the repair task, or other informational details. May be set when the repair task is created, and is immutable once set.
  --executor: string # The name of the repair executor. Must be specified in Claimed and later states, and is immutable once set.
  --executor-data: string # A data string that the repair executor can use to store its internal state.
  --flags: int # A bitwise-OR of the following values, which gives additional details about the status of the repair task. - 1 - Cancellation of the repair has been requested - 2 - Abort of the repair has been requested - 4 - Approval of the repair was forced via client request
  --history: any # A record of the times when the repair task entered each state. This type supports the Service Fabric platform; it is not meant to be used directly from your code. — shape: {ApprovedUtcTimestamp?: string, ClaimedUtcTimestamp?: string, CompletedUtcTimestamp?: string, CreatedUtcTimestamp?: string, ExecutingUtcTimestamp?: string, PreparingHealthCheckEndUtcTimestamp?: string, PreparingHealthCheckStartUtcTimestamp?: string, PreparingUtcTimestamp?: string, RestoringHealthCheckEndUtcTimestamp?: string, RestoringHealthCheckStartUtcTimestamp?: string, RestoringUtcTimestamp?: string}
  --impact: any # Describes the expected impact of executing a repair task. This type supports the Service Fabric platform; it is not meant to be used directly from your code. — shape: {Kind: "Invalid"|"Node"}
  --perform-preparing-health-check: oneof<nothing, bool> # A value to determine if health checks will be performed when the repair task enters the Preparing state.
  --perform-restoring-health-check: oneof<nothing, bool> # A value to determine if health checks will be performed when the repair task enters the Restoring state.
  --preparing-health-check-state: string@preparing-health-check-state-completer # Specifies the workflow state of a repair task's health check. This type supports the Service Fabric platform; it is not meant to be used directly from your code.
  --restoring-health-check-state: string@restoring-health-check-state-completer # Specifies the workflow state of a repair task's health check. This type supports the Service Fabric platform; it is not meant to be used directly from your code.
  --result-code: int # A numeric value providing additional details about the result of the repair task execution. May be specified in the Restoring and later states, and is immutable once set.
  --result-details: string # A string providing additional details about the result of the repair task execution. May be specified in the Restoring and later states, and is immutable once set.
  --result-status: string@result-status-completer # A value describing the overall result of the repair task execution. Must be specified in the Restoring and later states, and is immutable once set.
  state: string@state-completer # The workflow state of the repair task. Valid initial states are Created, Claimed, and Preparing.
  --target: any # Describes the entities targeted by a repair action. This type supports the Service Fabric platform; it is not meant to be used directly from your code. — shape: {Kind: "Invalid"|"Node"}
  task_id: string # The ID of the repair task.
  --version: string # The version of the repair task. When creating a new repair task, the version must be set to zero. When updating a repair task, the version is used for optimistic concurrency checks. If the version is set to zero, the update will not check for write conflicts. If the version is set to a non-zero value, then the update will only succeed if the actual current version of the repair task matches this value.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/$/CreateRepairTask"
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Action, var: action}, {name: Description, var: description}, {name: Executor, var: executor}, {name: ExecutorData, var: executor_data}, {name: Flags, var: flags}, {name: History, var: history}, {name: Impact, var: impact}, {name: PerformPreparingHealthCheck, var: perform_preparing_health_check}, {name: PerformRestoringHealthCheck, var: perform_restoring_health_check}, {name: PreparingHealthCheckState, var: preparing_health_check_state}, {name: RestoringHealthCheckState, var: restoring_health_check_state}, {name: ResultCode, var: result_code}, {name: ResultDetails, var: result_details}, {name: ResultStatus, var: result_status}, {name: State, var: state}, {name: Target, var: target}, {name: TaskId, var: task_id}, {name: Version, var: version}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, action: $action, description: $description, executor: $executor, executor_data: $executor_data, flags: $flags, history: $history, impact: $impact, perform_preparing_health_check: $perform_preparing_health_check, perform_restoring_health_check: $perform_restoring_health_check, preparing_health_check_state: $preparing_health_check_state, restoring_health_check_state: $restoring_health_check_state, result_code: $result_code, result_details: $result_details, result_status: $result_status, state: $state, target: $target, task_id: $task_id, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a completed repair task.
#
# POST /$/DeleteRepairTask
# operationId: DeleteRepairTask
export def "delete-repair-task" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  task_id: string # The ID of the completed repair task to be deleted.
  --version: string # The current version number of the repair task. If non-zero, then the request will only succeed if this value matches the actual current version of the repair task. If zero, then no version check is performed.
]: any -> any {
  $in | http-request {
    method: post
    path: "/$/DeleteRepairTask"
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}]
    body: {content_type: "application/json", kind: json, fields: [{name: TaskId, var: task_id}, {name: Version, var: version}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, task_id: $task_id, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Forces the approval of the given repair task.
#
# POST /$/ForceApproveRepairTask
# Returns: record<Version: string>
# operationId: ForceApproveRepairTask
export def "force-approve-repair-task" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  task_id: string # The ID of the repair task.
  --version: string # The current version number of the repair task. If non-zero, then the request will only succeed if this value matches the actual current version of the repair task. If zero, then no version check is performed.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/$/ForceApproveRepairTask"
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}]
    body: {content_type: "application/json", kind: json, fields: [{name: TaskId, var: task_id}, {name: Version, var: version}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, task_id: $task_id, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the Azure Active Directory metadata used for secured connection to cluster.
#
# GET /$/GetAadMetadata
# Returns: record<metadata: record<authority: string, client: string, cluster: string, login: string, redirect: string, tenant: string>, type: string>
# operationId: GetAadMetadata
export def "get-aad-metadata" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/$/GetAadMetadata"
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the Service Fabric standalone cluster configuration.
#
# GET /$/GetClusterConfiguration
# Returns: record<ClusterConfiguration: string>
# operationId: GetClusterConfiguration
export def "get-cluster-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --configuration-api-version: string # The API version of the Standalone cluster json configuration. (required)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/$/GetClusterConfiguration"
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: ConfigurationApiVersion, var: configuration_api_version, required: true}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, configuration_api_version: $configuration_api_version, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the cluster configuration upgrade status of a Service Fabric standalone cluster.
#
# GET /$/GetClusterConfigurationUpgradeStatus
# Returns: record<ConfigVersion: string, Details: string, ProgressStatus: int, UpgradeState: string>
# operationId: GetClusterConfigurationUpgradeStatus
export def "get-cluster-configuration-upgrade-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/$/GetClusterConfigurationUpgradeStatus"
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the health of a Service Fabric cluster.
#
# GET /$/GetClusterHealth
# Returns: record<ApplicationHealthStates: table<Name: string, AggregatedHealthState: string>, NodeHealthStates: table<Id: record, Name: string, AggregatedHealthState: string>, AggregatedHealthState: string, HealthEvents: table<IsExpired: bool, LastErrorTransitionAt: string, LastModifiedUtcTimestamp: string, LastOkTransitionAt: string, LastWarningTransitionAt: string, SourceUtcTimestamp: string, Description: string, HealthState: string, Property: string, RemoveWhenExpired: bool, SequenceNumber: string, SourceId: string, TimeToLiveInMilliSeconds: string>, HealthStatistics: record<HealthStateCountList: list<record>>, UnhealthyEvaluations: table<HealthEvaluation: record>>
# operationId: GetClusterHealth
export def "get-cluster-health" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --nodes-health-state-filter: int # Allows filtering of the node health state objects returned in the result of cluster health query based on their health state. The possible values for this parameter include integer value of one of the following health states. Only nodes that match the filter are returned. All nodes are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these values obtained using bitwise 'OR' operator. For example, if the provided value is 6 then health state of nodes with HealthState value of OK (2) and Warning (4) are returned. - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --applications-health-state-filter: int # Allows filtering of the application health state objects returned in the result of cluster health query based on their health state. The possible values for this parameter include integer value obtained from members or bitwise operations on members of HealthStateFilter enumeration. Only applications that match the filter are returned. All applications are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these values obtained using bitwise 'OR' operator. For example, if the provided value is 6 then health state of applications with HealthState value of OK (2) and Warning (4) are returned. - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --events-health-state-filter: int # Allows filtering the collection of HealthEvent objects returned based on health state. The possible values for this parameter include integer value of one of the following health states. Only events that match the filter are returned. All events are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these values, obtained using the bitwise 'OR' operator. For example, If the provided value is 6 then all of the events with HealthState value of OK (2) and Warning (4) are returned. - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --exclude-health-statistics: oneof<nothing, bool> # Indicates whether the health statistics should be returned as part of the query result. False by default. The statistics show the number of children entities in health state Ok, Warning, and Error. (default: false)
  --include-system-application-health-statistics: oneof<nothing, bool> # Indicates whether the health statistics should include the fabric:/System application health statistics. False by default. If IncludeSystemApplicationHealthStatistics is set to true, the health statistics include the entities that belong to the fabric:/System application. Otherwise, the query result includes health statistics only for user applications. The health statistics must be included in the query result for this parameter to be applied. (default: false)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/$/GetClusterHealth"
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: NodesHealthStateFilter, var: nodes_health_state_filter}, {name: ApplicationsHealthStateFilter, var: applications_health_state_filter}, {name: EventsHealthStateFilter, var: events_health_state_filter}, {name: ExcludeHealthStatistics, var: exclude_health_statistics}, {name: IncludeSystemApplicationHealthStatistics, var: include_system_application_health_statistics}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, nodes_health_state_filter: $nodes_health_state_filter, applications_health_state_filter: $applications_health_state_filter, events_health_state_filter: $events_health_state_filter, exclude_health_statistics: $exclude_health_statistics, include_system_application_health_statistics: $include_system_application_health_statistics, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the health of a Service Fabric cluster using the specified policy.
#
# POST /$/GetClusterHealth
# Returns: record<ApplicationHealthStates: table<Name: string, AggregatedHealthState: string>, NodeHealthStates: table<Id: record, Name: string, AggregatedHealthState: string>, AggregatedHealthState: string, HealthEvents: table<IsExpired: bool, LastErrorTransitionAt: string, LastModifiedUtcTimestamp: string, LastOkTransitionAt: string, LastWarningTransitionAt: string, SourceUtcTimestamp: string, Description: string, HealthState: string, Property: string, RemoveWhenExpired: bool, SequenceNumber: string, SourceId: string, TimeToLiveInMilliSeconds: string>, HealthStatistics: record<HealthStateCountList: list<record>>, UnhealthyEvaluations: table<HealthEvaluation: record>>
# operationId: GetClusterHealthUsingPolicy
export def "get-cluster-health-using-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --nodes-health-state-filter: int # Allows filtering of the node health state objects returned in the result of cluster health query based on their health state. The possible values for this parameter include integer value of one of the following health states. Only nodes that match the filter are returned. All nodes are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these values obtained using bitwise 'OR' operator. For example, if the provided value is 6 then health state of nodes with HealthState value of OK (2) and Warning (4) are returned. - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --applications-health-state-filter: int # Allows filtering of the application health state objects returned in the result of cluster health query based on their health state. The possible values for this parameter include integer value obtained from members or bitwise operations on members of HealthStateFilter enumeration. Only applications that match the filter are returned. All applications are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these values obtained using bitwise 'OR' operator. For example, if the provided value is 6 then health state of applications with HealthState value of OK (2) and Warning (4) are returned. - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --events-health-state-filter: int # Allows filtering the collection of HealthEvent objects returned based on health state. The possible values for this parameter include integer value of one of the following health states. Only events that match the filter are returned. All events are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these values, obtained using the bitwise 'OR' operator. For example, If the provided value is 6 then all of the events with HealthState value of OK (2) and Warning (4) are returned. - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --exclude-health-statistics: oneof<nothing, bool> # Indicates whether the health statistics should be returned as part of the query result. False by default. The statistics show the number of children entities in health state Ok, Warning, and Error. (default: false)
  --include-system-application-health-statistics: oneof<nothing, bool> # Indicates whether the health statistics should include the fabric:/System application health statistics. False by default. If IncludeSystemApplicationHealthStatistics is set to true, the health statistics include the entities that belong to the fabric:/System application. Otherwise, the query result includes health statistics only for user applications. The health statistics must be included in the query result for this parameter to be applied. (default: false)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --application-health-policy-map: list # Defines a map that contains specific application health policies for different applications. Each entry specifies as key the application name and as value an ApplicationHealthPolicy used to evaluate the application health. If an application is not specified in the map, the application health evaluation uses the ApplicationHealthPolicy found in its application manifest or the default application health policy (if no health policy is defined in the manifest). The map is empty by default. — item shape: {Key: string, Value: any}
  --cluster-health-policy: any # Defines a health policy used to evaluate the health of the cluster or of a cluster node. — shape: {ApplicationTypeHealthPolicyMap?: list, ConsiderWarningAsError?: bool, MaxPercentUnhealthyApplications?: int, MaxPercentUnhealthyNodes?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/$/GetClusterHealth"
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: NodesHealthStateFilter, var: nodes_health_state_filter}, {name: ApplicationsHealthStateFilter, var: applications_health_state_filter}, {name: EventsHealthStateFilter, var: events_health_state_filter}, {name: ExcludeHealthStatistics, var: exclude_health_statistics}, {name: IncludeSystemApplicationHealthStatistics, var: include_system_application_health_statistics}, {name: timeout, var: timeout}]
    body: {content_type: "application/json", kind: json, fields: [{name: ApplicationHealthPolicyMap, var: application_health_policy_map}, {name: ClusterHealthPolicy, var: cluster_health_policy}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, nodes_health_state_filter: $nodes_health_state_filter, applications_health_state_filter: $applications_health_state_filter, events_health_state_filter: $events_health_state_filter, exclude_health_statistics: $exclude_health_statistics, include_system_application_health_statistics: $include_system_application_health_statistics, timeout: $timeout, application_health_policy_map: $application_health_policy_map, cluster_health_policy: $cluster_health_policy
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the health of a Service Fabric cluster using health chunks.
#
# GET /$/GetClusterHealthChunk
# Returns: record<ApplicationHealthStateChunks: record<Items: list<record>, TotalCount: int>, HealthState: string, NodeHealthStateChunks: record<Items: list<record>, TotalCount: int>>
# operationId: GetClusterHealthChunk
export def "get-cluster-health-chunk" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/$/GetClusterHealthChunk"
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the health of a Service Fabric cluster using health chunks.
#
# POST /$/GetClusterHealthChunk
# Returns: record<ApplicationHealthStateChunks: record<Items: list<record>, TotalCount: int>, HealthState: string, NodeHealthStateChunks: record<Items: list<record>, TotalCount: int>>
# operationId: GetClusterHealthChunkUsingPolicyAndAdvancedFilters
export def "get-cluster-health-chunk-using-policy-and-advanced-filters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --application-filters: list # Defines a list of filters that specify which applications to be included in the returned cluster health chunk. If no filters are specified, no applications are returned. All the applications are used to evaluate the cluster's aggregated health state, regardless of the input filters. The cluster health chunk query may specify multiple application filters. For example, it can specify a filter to return all applications with health state Error and another filter to always include applications of a specified application type. — item shape: {ApplicationNameFilter?: string, ApplicationTypeNameFilter?: string, DeployedApplicationFilters?: list, HealthStateFilter?: int, ServiceFilters?: list}
  --application-health-policies: any # Defines the application health policy map used to evaluate the health of an application or one of its children entities. — shape: {ApplicationHealthPolicyMap?: list}
  --cluster-health-policy: any # Defines a health policy used to evaluate the health of the cluster or of a cluster node. — shape: {ApplicationTypeHealthPolicyMap?: list, ConsiderWarningAsError?: bool, MaxPercentUnhealthyApplications?: int, MaxPercentUnhealthyNodes?: int}
  --node-filters: list # Defines a list of filters that specify which nodes to be included in the returned cluster health chunk. If no filters are specified, no nodes are returned. All the nodes are used to evaluate the cluster's aggregated health state, regardless of the input filters. The cluster health chunk query may specify multiple node filters. For example, it can specify a filter to return all nodes with health state Error and another filter to always include a node identified by its NodeName. — item shape: {HealthStateFilter?: int, NodeNameFilter?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/$/GetClusterHealthChunk"
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: timeout, var: timeout}]
    body: {content_type: "application/json", kind: json, fields: [{name: ApplicationFilters, var: application_filters}, {name: ApplicationHealthPolicies, var: application_health_policies}, {name: ClusterHealthPolicy, var: cluster_health_policy}, {name: NodeFilters, var: node_filters}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, timeout: $timeout, application_filters: $application_filters, application_health_policies: $application_health_policies, cluster_health_policy: $cluster_health_policy, node_filters: $node_filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the Service Fabric cluster manifest.
#
# GET /$/GetClusterManifest
# Returns: record<Manifest: string>
# operationId: GetClusterManifest
export def "get-cluster-manifest" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/$/GetClusterManifest"
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the current Service Fabric cluster version.
#
# GET /$/GetClusterVersion
# Returns: record<Version: string>
# operationId: GetClusterVersion
export def "get-cluster-version" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/$/GetClusterVersion"
    query: [{name: api-version, var: api_version, required: true, default: "6.4"}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the load of a Service Fabric cluster.
#
# GET /$/GetLoadInformation
# Returns: record<LastBalancingEndTimeUtc: string, LastBalancingStartTimeUtc: string, LoadMetricInformation: table<Action: string, ActivityThreshold: string, BalancingThreshold: string, BufferedClusterCapacityRemaining: string, ClusterBufferedCapacity: string, ClusterCapacity: string, ClusterCapacityRemaining: string, ClusterLoad: string, ClusterRemainingBufferedCapacity: string, ClusterRemainingCapacity: string, CurrentClusterLoad: string, DeviationAfter: string, DeviationBefore: string, IsBalancedAfter: bool, IsBalancedBefore: bool, IsClusterCapacityViolation: bool, MaxNodeLoadNodeId: record, MaxNodeLoadValue: string, MaximumNodeLoad: string, MinNodeLoadNodeId: record, MinNodeLoadValue: string, MinimumNodeLoad: string, Name: string, NodeBufferPercentage: string, PlannedLoadRemoval: string>>
# operationId: GetClusterLoad
export def "get-cluster-load" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/$/GetLoadInformation"
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of fabric code versions that are provisioned in a Service Fabric cluster.
#
# GET /$/GetProvisionedCodeVersions
# Returns: table<CodeVersion: string>
# operationId: GetProvisionedFabricCodeVersionInfoList
export def "get-provisioned-fabric-code-version-info-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --code-version: string # The product version of Service Fabric.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/$/GetProvisionedCodeVersions"
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: CodeVersion, var: code_version}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, code_version: $code_version, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of fabric config versions that are provisioned in a Service Fabric cluster.
#
# GET /$/GetProvisionedConfigVersions
# Returns: table<ConfigVersion: string>
# operationId: GetProvisionedFabricConfigVersionInfoList
export def "get-provisioned-fabric-config-version-info-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --config-version: string # The config version of Service Fabric.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/$/GetProvisionedConfigVersions"
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: ConfigVersion, var: config_version}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, config_version: $config_version, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of repair tasks matching the given filters.
#
# GET /$/GetRepairTaskList
# Returns: table<Action: string, Description: string, Executor: string, ExecutorData: string, Flags: int, History: record<ApprovedUtcTimestamp: string, ClaimedUtcTimestamp: string, CompletedUtcTimestamp: string, CreatedUtcTimestamp: string, ExecutingUtcTimestamp: string, PreparingHealthCheckEndUtcTimestamp: string, PreparingHealthCheckStartUtcTimestamp: string, PreparingUtcTimestamp: string, RestoringHealthCheckEndUtcTimestamp: string, RestoringHealthCheckStartUtcTimestamp: string, RestoringUtcTimestamp: string>, Impact: record<Kind: string>, PerformPreparingHealthCheck: bool, PerformRestoringHealthCheck: bool, PreparingHealthCheckState: string, RestoringHealthCheckState: string, ResultCode: int, ResultDetails: string, ResultStatus: string, State: string, Target: record<Kind: string>, TaskId: string, Version: string>
# operationId: GetRepairTaskList
export def "get-repair-task-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --task-id-filter: string # The repair task ID prefix to be matched.
  --state-filter: int # A bitwise-OR of the following values, specifying which task states should be included in the result list. - 1 - Created - 2 - Claimed - 4 - Preparing - 8 - Approved - 16 - Executing - 32 - Restoring - 64 - Completed
  --executor-filter: string # The name of the repair executor whose claimed tasks should be included in the list.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/$/GetRepairTaskList"
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: TaskIdFilter, var: task_id_filter}, {name: StateFilter, var: state_filter}, {name: ExecutorFilter, var: executor_filter}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, task_id_filter: $task_id_filter, state_filter: $state_filter, executor_filter: $executor_filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the service state of Service Fabric Upgrade Orchestration Service.
#
# GET /$/GetUpgradeOrchestrationServiceState
# Returns: record<ServiceState: string>
# operationId: GetUpgradeOrchestrationServiceState
export def "get-upgrade-orchestration-service-state" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/$/GetUpgradeOrchestrationServiceState"
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the progress of the current cluster upgrade.
#
# GET /$/GetUpgradeProgress
# Returns: record<CodeVersion: string, ConfigVersion: string, CurrentUpgradeDomainProgress: record<DomainName: string, NodeUpgradeProgressList: list<record>>, FailureReason: string, FailureTimestampUtc: string, NextUpgradeDomain: string, RollingUpgradeMode: string, StartTimestampUtc: string, UnhealthyEvaluations: table<HealthEvaluation: record>, UpgradeDescription: record<ApplicationHealthPolicyMap: list<record>, ClusterHealthPolicy: record<ApplicationTypeHealthPolicyMap: list, ConsiderWarningAsError: bool, MaxPercentUnhealthyApplications: int, MaxPercentUnhealthyNodes: int>, ClusterUpgradeHealthPolicy: record<MaxPercentDeltaUnhealthyNodes: int, MaxPercentUpgradeDomainDeltaUnhealthyNodes: int>, CodeVersion: string, ConfigVersion: string, EnableDeltaHealthEvaluation: bool, ForceRestart: bool, MonitoringPolicy: record<FailureAction: string, HealthCheckRetryTimeoutInMilliseconds: string, HealthCheckStableDurationInMilliseconds: string, HealthCheckWaitDurationInMilliseconds: string, UpgradeDomainTimeoutInMilliseconds: string, UpgradeTimeoutInMilliseconds: string>, RollingUpgradeMode: string, SortOrder: string, UpgradeKind: string, UpgradeReplicaSetCheckTimeoutInSeconds: int>, UpgradeDomainDurationInMilliseconds: string, UpgradeDomainProgressAtFailure: record<DomainName: string, NodeUpgradeProgressList: list<record>>, UpgradeDomains: table<Name: string, State: string>, UpgradeDurationInMilliseconds: string, UpgradeState: string>
# operationId: GetClusterUpgradeProgress
export def "get-cluster-upgrade-progress" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/$/GetUpgradeProgress"
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Invokes an administrative command on the given Infrastructure Service instance.
#
# POST /$/InvokeInfrastructureCommand
# Returns: binary
# operationId: InvokeInfrastructureCommand
export def "invoke-infrastructure-command" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --command: string # The text of the command to be invoked. The content of the command is infrastructure-specific. (required)
  --service-id: string # The identity of the infrastructure service. This is the full name of the infrastructure service without the 'fabric:' URI scheme. This parameter required only for the cluster that has more than one instance of infrastructure service running.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> any {
  http-request {
    method: post
    path: "/$/InvokeInfrastructureCommand"
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: Command, var: command, required: true}, {name: ServiceId, var: service_id}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, command: $command, service_id: $service_id, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Invokes a read-only query on the given infrastructure service instance.
#
# GET /$/InvokeInfrastructureQuery
# Returns: binary
# operationId: InvokeInfrastructureQuery
export def "invoke-infrastructure-query" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --command: string # The text of the command to be invoked. The content of the command is infrastructure-specific. (required)
  --service-id: string # The identity of the infrastructure service. This is the full name of the infrastructure service without the 'fabric:' URI scheme. This parameter required only for the cluster that has more than one instance of infrastructure service running.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> any {
  http-request {
    method: get
    path: "/$/InvokeInfrastructureQuery"
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: Command, var: command, required: true}, {name: ServiceId, var: service_id}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, command: $command, service_id: $service_id, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Make the cluster upgrade move on to the next upgrade domain.
#
# POST /$/MoveToNextUpgradeDomain
# operationId: ResumeClusterUpgrade
export def "resume-cluster-upgrade" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  upgrade_domain: string # The next upgrade domain for this cluster upgrade.
]: any -> any {
  $in | http-request {
    method: post
    path: "/$/MoveToNextUpgradeDomain"
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: timeout, var: timeout}]
    body: {content_type: "application/json", kind: json, fields: [{name: UpgradeDomain, var: upgrade_domain}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, timeout: $timeout, upgrade_domain: $upgrade_domain
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provision the code or configuration packages of a Service Fabric cluster.
#
# POST /$/Provision
# operationId: ProvisionCluster
export def "provision-cluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --cluster-manifest-file-path: string # The cluster manifest file path.
  --code-file-path: string # The cluster code package file path.
]: any -> any {
  $in | http-request {
    method: post
    path: "/$/Provision"
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: timeout, var: timeout}]
    body: {content_type: "application/json", kind: json, fields: [{name: ClusterManifestFilePath, var: cluster_manifest_file_path}, {name: CodeFilePath, var: code_file_path}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, timeout: $timeout, cluster_manifest_file_path: $cluster_manifest_file_path, code_file_path: $code_file_path
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Indicates to the Service Fabric cluster that it should attempt to recover any services (including system services) which are currently stuck in quorum loss.
#
# POST /$/RecoverAllPartitions
# operationId: RecoverAllPartitions
export def "recover-all-partitions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> any {
  http-request {
    method: post
    path: "/$/RecoverAllPartitions"
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Indicates to the Service Fabric cluster that it should attempt to recover the system services that are currently stuck in quorum loss.
#
# POST /$/RecoverSystemPartitions
# operationId: RecoverSystemPartitions
export def "recover-system-partitions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> any {
  http-request {
    method: post
    path: "/$/RecoverSystemPartitions"
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sends a health report on the Service Fabric cluster.
#
# POST /$/ReportClusterHealth
# operationId: ReportClusterHealth
export def "report-cluster-health" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --immediate: oneof<nothing, bool> # A flag that indicates whether the report should be sent immediately. A health report is sent to a Service Fabric gateway Application, which forwards to the health store. If Immediate is set to true, the report is sent immediately from HTTP Gateway to the health store, regardless of the fabric client settings that the HTTP Gateway Application is using. This is useful for critical reports that should be sent as soon as possible. Depending on timing and other conditions, sending the report may still fail, for example if the HTTP Gateway is closed or the message doesn't reach the Gateway. If Immediate is set to false, the report is sent based on the health client settings from the HTTP Gateway. Therefore, it will be batched according to the HealthReportSendInterval configuration. This is the recommended setting because it allows the health client to optimize health reporting messages to health store as well as health report processing. By default, reports are not sent immediately. (default: false)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --description: string # The description of the health information. It represents free text used to add human readable information about the report. The maximum string length for the description is 4096 characters. If the provided string is longer, it will be automatically truncated. When truncated, the last characters of the description contain a marker "[Truncated]", and total string size is 4096 characters. The presence of the marker indicates to users that truncation occurred. Note that when truncated, the description has less than 4096 characters from the original string.
  health_state: string@health-state-completer # The health state of a Service Fabric entity such as Cluster, Node, Application, Service, Partition, Replica etc.
  property: string # The property of the health information. An entity can have health reports for different properties. The property is a string and not a fixed enumeration to allow the reporter flexibility to categorize the state condition that triggers the report. For example, a reporter with SourceId "LocalWatchdog" can monitor the state of the available disk on a node, so it can report "AvailableDisk" property on that node. The same reporter can monitor the node connectivity, so it can report a property "Connectivity" on the same node. In the health store, these reports are treated as separate health events for the specified node. Together with the SourceId, the property uniquely identifies the health information.
  --remove-when-expired: oneof<nothing, bool> # Value that indicates whether the report is removed from health store when it expires. If set to true, the report is removed from the health store after it expires. If set to false, the report is treated as an error when expired. The value of this property is false by default. When clients report periodically, they should set RemoveWhenExpired false (default). This way, if the reporter has issues (e.g. deadlock) and can't report, the entity is evaluated at error when the health report expires. This flags the entity as being in Error health state.
  --sequence-number: string # The sequence number for this health report as a numeric string. The report sequence number is used by the health store to detect stale reports. If not specified, a sequence number is auto-generated by the health client when a report is added.
  source_id: string # The source name that identifies the client/watchdog/system component that generated the health information.
  --time-to-live-in-milli-seconds: string # The duration for which this health report is valid. This field uses ISO8601 format for specifying the duration. When clients report periodically, they should send reports with higher frequency than time to live. If clients report on transition, they can set the time to live to infinite. When time to live expires, the health event that contains the health information is either removed from health store, if RemoveWhenExpired is true, or evaluated at error, if RemoveWhenExpired false. If not specified, time to live defaults to infinite value. (format: duration)
]: any -> any {
  $in | http-request {
    method: post
    path: "/$/ReportClusterHealth"
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: Immediate, var: immediate}, {name: timeout, var: timeout}]
    body: {content_type: "application/json", kind: json, fields: [{name: Description, var: description}, {name: HealthState, var: health_state}, {name: Property, var: property}, {name: RemoveWhenExpired, var: remove_when_expired}, {name: SequenceNumber, var: sequence_number}, {name: SourceId, var: source_id}, {name: TimeToLiveInMilliSeconds, var: time_to_live_in_milli_seconds}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, immediate: $immediate, timeout: $timeout, description: $description, health_state: $health_state, property: $property, remove_when_expired: $remove_when_expired, sequence_number: $sequence_number, source_id: $source_id, time_to_live_in_milli_seconds: $time_to_live_in_milli_seconds
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Roll back the upgrade of a Service Fabric cluster.
#
# POST /$/RollbackUpgrade
# operationId: RollbackClusterUpgrade
export def "rollback-cluster-upgrade" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> any {
  http-request {
    method: post
    path: "/$/RollbackUpgrade"
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    api_version: $api_version, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the service state of Service Fabric Upgrade Orchestration Service.
#
# POST /$/SetUpgradeOrchestrationServiceState
# Returns: record<CurrentCodeVersion: string, CurrentManifestVersion: string, PendingUpgradeType: string, TargetCodeVersion: string, TargetManifestVersion: string>
# operationId: SetUpgradeOrchestrationServiceState
export def "set-upgrade-orchestration-service-state" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --service-state: string # The state of Service Fabric Upgrade Orchestration Service.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/$/SetUpgradeOrchestrationServiceState"
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: timeout, var: timeout}]
    body: {content_type: "application/json", kind: json, fields: [{name: ServiceState, var: service_state}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, timeout: $timeout, service_state: $service_state
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Start upgrading the configuration of a Service Fabric standalone cluster.
#
# POST /$/StartClusterConfigurationUpgrade
# operationId: StartClusterConfigurationUpgrade
export def "start-cluster-configuration-upgrade" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --application-health-policies: any # Defines the application health policy map used to evaluate the health of an application or one of its children entities. — shape: {ApplicationHealthPolicyMap?: list}
  cluster_config: string # The cluster configuration as a JSON string. For example, [this file](https://github.com/Azure-Samples/service-fabric-dotnet-standalone-cluster-configuration/blob/master/Samples/ClusterConfig.Unsecure.DevCluster.json) contains JSON describing the [nodes and other properties of the cluster](https://docs.microsoft.com/azure/service-fabric/service-fabric-cluster-manifest).
  --health-check-retry-timeout: string # The length of time between attempts to perform health checks if the application or cluster is not healthy. (format: duration, default: PT0H0M0S)
  --health-check-stable-duration-in-seconds: string # The length of time that the application or cluster must remain healthy before the upgrade proceeds to the next upgrade domain. (format: duration, default: PT0H0M0S)
  --health-check-wait-duration-in-seconds: string # The length of time to wait after completing an upgrade domain before starting the health checks process. (format: duration, default: PT0H0M0S)
  --max-percent-delta-unhealthy-nodes: int # The maximum allowed percentage of delta health degradation during the upgrade. Allowed values are integer values from zero to 100. (default: 0)
  --max-percent-unhealthy-applications: int # The maximum allowed percentage of unhealthy applications during the upgrade. Allowed values are integer values from zero to 100. (default: 0)
  --max-percent-unhealthy-nodes: int # The maximum allowed percentage of unhealthy nodes during the upgrade. Allowed values are integer values from zero to 100. (default: 0)
  --max-percent-upgrade-domain-delta-unhealthy-nodes: int # The maximum allowed percentage of upgrade domain delta health degradation during the upgrade. Allowed values are integer values from zero to 100. (default: 0)
  --upgrade-domain-timeout-in-seconds: string # The timeout for the upgrade domain. (format: duration, default: PT0H0M0S)
  --upgrade-timeout-in-seconds: string # The upgrade timeout. (format: duration, default: PT0H0M0S)
]: any -> any {
  $in | http-request {
    method: post
    path: "/$/StartClusterConfigurationUpgrade"
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: timeout, var: timeout}]
    body: {content_type: "application/json", kind: json, fields: [{name: ApplicationHealthPolicies, var: application_health_policies}, {name: ClusterConfig, var: cluster_config}, {name: HealthCheckRetryTimeout, var: health_check_retry_timeout}, {name: HealthCheckStableDurationInSeconds, var: health_check_stable_duration_in_seconds}, {name: HealthCheckWaitDurationInSeconds, var: health_check_wait_duration_in_seconds}, {name: MaxPercentDeltaUnhealthyNodes, var: max_percent_delta_unhealthy_nodes}, {name: MaxPercentUnhealthyApplications, var: max_percent_unhealthy_applications}, {name: MaxPercentUnhealthyNodes, var: max_percent_unhealthy_nodes}, {name: MaxPercentUpgradeDomainDeltaUnhealthyNodes, var: max_percent_upgrade_domain_delta_unhealthy_nodes}, {name: UpgradeDomainTimeoutInSeconds, var: upgrade_domain_timeout_in_seconds}, {name: UpgradeTimeoutInSeconds, var: upgrade_timeout_in_seconds}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    api_version: $api_version, timeout: $timeout, application_health_policies: $application_health_policies, cluster_config: $cluster_config, health_check_retry_timeout: $health_check_retry_timeout, health_check_stable_duration_in_seconds: $health_check_stable_duration_in_seconds, health_check_wait_duration_in_seconds: $health_check_wait_duration_in_seconds, max_percent_delta_unhealthy_nodes: $max_percent_delta_unhealthy_nodes, max_percent_unhealthy_applications: $max_percent_unhealthy_applications, max_percent_unhealthy_nodes: $max_percent_unhealthy_nodes, max_percent_upgrade_domain_delta_unhealthy_nodes: $max_percent_upgrade_domain_delta_unhealthy_nodes, upgrade_domain_timeout_in_seconds: $upgrade_domain_timeout_in_seconds, upgrade_timeout_in_seconds: $upgrade_timeout_in_seconds
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Changes the verbosity of service placement health reporting.
#
# POST /$/ToggleVerboseServicePlacementHealthReporting
# operationId: ToggleVerboseServicePlacementHealthReporting
export def "toggle-verbose-service-placement-health-reporting" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.4)
  --enabled: oneof<nothing, bool> # The verbosity of service placement health reporting. (required)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> any {
  http-request {
    method: post
    path: "/$/ToggleVerboseServicePlacementHealthReporting"
    query: [{name: api-version, var: api_version, required: true, default: "6.4"}, {name: Enabled, var: enabled, required: true}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, enabled: $enabled, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unprovision the code or configuration packages of a Service Fabric cluster.
#
# POST /$/Unprovision
# operationId: UnprovisionCluster
export def "unprovision-cluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --code-version: string # The cluster code package version.
  --config-version: string # The cluster manifest version.
]: any -> any {
  $in | http-request {
    method: post
    path: "/$/Unprovision"
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: timeout, var: timeout}]
    body: {content_type: "application/json", kind: json, fields: [{name: CodeVersion, var: code_version}, {name: ConfigVersion, var: config_version}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, timeout: $timeout, code_version: $code_version, config_version: $config_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the execution state of a repair task.
#
# POST /$/UpdateRepairExecutionState
# Returns: record<Version: string>
# operationId: UpdateRepairExecutionState
export def "update-repair-execution-state" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  action: string # The requested repair action. Must be specified when the repair task is created, and is immutable once set.
  --description: string # A description of the purpose of the repair task, or other informational details. May be set when the repair task is created, and is immutable once set.
  --executor: string # The name of the repair executor. Must be specified in Claimed and later states, and is immutable once set.
  --executor-data: string # A data string that the repair executor can use to store its internal state.
  --flags: int # A bitwise-OR of the following values, which gives additional details about the status of the repair task. - 1 - Cancellation of the repair has been requested - 2 - Abort of the repair has been requested - 4 - Approval of the repair was forced via client request
  --history: any # A record of the times when the repair task entered each state. This type supports the Service Fabric platform; it is not meant to be used directly from your code. — shape: {ApprovedUtcTimestamp?: string, ClaimedUtcTimestamp?: string, CompletedUtcTimestamp?: string, CreatedUtcTimestamp?: string, ExecutingUtcTimestamp?: string, PreparingHealthCheckEndUtcTimestamp?: string, PreparingHealthCheckStartUtcTimestamp?: string, PreparingUtcTimestamp?: string, RestoringHealthCheckEndUtcTimestamp?: string, RestoringHealthCheckStartUtcTimestamp?: string, RestoringUtcTimestamp?: string}
  --impact: any # Describes the expected impact of executing a repair task. This type supports the Service Fabric platform; it is not meant to be used directly from your code. — shape: {Kind: "Invalid"|"Node"}
  --perform-preparing-health-check: oneof<nothing, bool> # A value to determine if health checks will be performed when the repair task enters the Preparing state.
  --perform-restoring-health-check: oneof<nothing, bool> # A value to determine if health checks will be performed when the repair task enters the Restoring state.
  --preparing-health-check-state: string@preparing-health-check-state-completer # Specifies the workflow state of a repair task's health check. This type supports the Service Fabric platform; it is not meant to be used directly from your code.
  --restoring-health-check-state: string@restoring-health-check-state-completer # Specifies the workflow state of a repair task's health check. This type supports the Service Fabric platform; it is not meant to be used directly from your code.
  --result-code: int # A numeric value providing additional details about the result of the repair task execution. May be specified in the Restoring and later states, and is immutable once set.
  --result-details: string # A string providing additional details about the result of the repair task execution. May be specified in the Restoring and later states, and is immutable once set.
  --result-status: string@result-status-completer # A value describing the overall result of the repair task execution. Must be specified in the Restoring and later states, and is immutable once set.
  state: string@state-completer # The workflow state of the repair task. Valid initial states are Created, Claimed, and Preparing.
  --target: any # Describes the entities targeted by a repair action. This type supports the Service Fabric platform; it is not meant to be used directly from your code. — shape: {Kind: "Invalid"|"Node"}
  task_id: string # The ID of the repair task.
  --version: string # The version of the repair task. When creating a new repair task, the version must be set to zero. When updating a repair task, the version is used for optimistic concurrency checks. If the version is set to zero, the update will not check for write conflicts. If the version is set to a non-zero value, then the update will only succeed if the actual current version of the repair task matches this value.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/$/UpdateRepairExecutionState"
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Action, var: action}, {name: Description, var: description}, {name: Executor, var: executor}, {name: ExecutorData, var: executor_data}, {name: Flags, var: flags}, {name: History, var: history}, {name: Impact, var: impact}, {name: PerformPreparingHealthCheck, var: perform_preparing_health_check}, {name: PerformRestoringHealthCheck, var: perform_restoring_health_check}, {name: PreparingHealthCheckState, var: preparing_health_check_state}, {name: RestoringHealthCheckState, var: restoring_health_check_state}, {name: ResultCode, var: result_code}, {name: ResultDetails, var: result_details}, {name: ResultStatus, var: result_status}, {name: State, var: state}, {name: Target, var: target}, {name: TaskId, var: task_id}, {name: Version, var: version}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, action: $action, description: $description, executor: $executor, executor_data: $executor_data, flags: $flags, history: $history, impact: $impact, perform_preparing_health_check: $perform_preparing_health_check, perform_restoring_health_check: $perform_restoring_health_check, preparing_health_check_state: $preparing_health_check_state, restoring_health_check_state: $restoring_health_check_state, result_code: $result_code, result_details: $result_details, result_status: $result_status, state: $state, target: $target, task_id: $task_id, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the health policy of the given repair task.
#
# POST /$/UpdateRepairTaskHealthPolicy
# Returns: record<Version: string>
# operationId: UpdateRepairTaskHealthPolicy
export def "update-repair-task-health-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --perform-preparing-health-check: oneof<nothing, bool> # A boolean indicating if health check is to be performed in the Preparing stage of the repair task. If not specified the existing value should not be altered. Otherwise, specify the desired new value.
  --perform-restoring-health-check: oneof<nothing, bool> # A boolean indicating if health check is to be performed in the Restoring stage of the repair task. If not specified the existing value should not be altered. Otherwise, specify the desired new value.
  task_id: string # The ID of the repair task to be updated.
  --version: string # The current version number of the repair task. If non-zero, then the request will only succeed if this value matches the actual current value of the repair task. If zero, then no version check is performed.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/$/UpdateRepairTaskHealthPolicy"
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}]
    body: {content_type: "application/json", kind: json, fields: [{name: PerformPreparingHealthCheck, var: perform_preparing_health_check}, {name: PerformRestoringHealthCheck, var: perform_restoring_health_check}, {name: TaskId, var: task_id}, {name: Version, var: version}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, perform_preparing_health_check: $perform_preparing_health_check, perform_restoring_health_check: $perform_restoring_health_check, task_id: $task_id, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the upgrade parameters of a Service Fabric cluster upgrade.
#
# POST /$/UpdateUpgrade
# operationId: UpdateClusterUpgrade
export def "update-cluster-upgrade" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --application-health-policy-map: any # Defines the application health policy map used to evaluate the health of an application or one of its children entities. — shape: {ApplicationHealthPolicyMap?: list}
  --cluster-health-policy: any # Defines a health policy used to evaluate the health of the cluster or of a cluster node. — shape: {ApplicationTypeHealthPolicyMap?: list, ConsiderWarningAsError?: bool, MaxPercentUnhealthyApplications?: int, MaxPercentUnhealthyNodes?: int}
  --cluster-upgrade-health-policy: any # Defines a health policy used to evaluate the health of the cluster during a cluster upgrade. — shape: {MaxPercentDeltaUnhealthyNodes?: int, MaxPercentUpgradeDomainDeltaUnhealthyNodes?: int}
  --enable-delta-health-evaluation: oneof<nothing, bool> # When true, enables delta health evaluation rather than absolute health evaluation after completion of each upgrade domain.
  --update-description: any # Describes the parameters for updating a rolling upgrade of application or cluster. — shape: {FailureAction?: "Invalid"|"Rollback"|"Manual", ForceRestart?: bool, HealthCheckRetryTimeoutInMilliseconds?: string, HealthCheckStableDurationInMilliseconds?: string, HealthCheckWaitDurationInMilliseconds?: string, ReplicaSetCheckTimeoutInMilliseconds?: int, RollingUpgradeMode: "Invalid"|"UnmonitoredAuto"|"UnmonitoredManual"|"Monitored", UpgradeDomainTimeoutInMilliseconds?: string, UpgradeTimeoutInMilliseconds?: string}
  --upgrade-kind: string@upgrade-kind-completer # The type of upgrade out of the following possible values. (default: Rolling)
]: any -> any {
  $in | http-request {
    method: post
    path: "/$/UpdateUpgrade"
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: timeout, var: timeout}]
    body: {content_type: "application/json", kind: json, fields: [{name: ApplicationHealthPolicyMap, var: application_health_policy_map}, {name: ClusterHealthPolicy, var: cluster_health_policy}, {name: ClusterUpgradeHealthPolicy, var: cluster_upgrade_health_policy}, {name: EnableDeltaHealthEvaluation, var: enable_delta_health_evaluation}, {name: UpdateDescription, var: update_description}, {name: UpgradeKind, var: upgrade_kind}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, timeout: $timeout, application_health_policy_map: $application_health_policy_map, cluster_health_policy: $cluster_health_policy, cluster_upgrade_health_policy: $cluster_upgrade_health_policy, enable_delta_health_evaluation: $enable_delta_health_evaluation, update_description: $update_description, upgrade_kind: $upgrade_kind
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Start upgrading the code or configuration version of a Service Fabric cluster.
#
# POST /$/Upgrade
# operationId: StartClusterUpgrade
export def "start-cluster-upgrade" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --application-health-policy-map: any # Defines the application health policy map used to evaluate the health of an application or one of its children entities. — shape: {ApplicationHealthPolicyMap?: list}
  --cluster-health-policy: any # Defines a health policy used to evaluate the health of the cluster or of a cluster node. — shape: {ApplicationTypeHealthPolicyMap?: list, ConsiderWarningAsError?: bool, MaxPercentUnhealthyApplications?: int, MaxPercentUnhealthyNodes?: int}
  --cluster-upgrade-health-policy: any # Defines a health policy used to evaluate the health of the cluster during a cluster upgrade. — shape: {MaxPercentDeltaUnhealthyNodes?: int, MaxPercentUpgradeDomainDeltaUnhealthyNodes?: int}
  --code-version: string # The cluster code version.
  --config-version: string # The cluster configuration version.
  --enable-delta-health-evaluation: oneof<nothing, bool> # When true, enables delta health evaluation rather than absolute health evaluation after completion of each upgrade domain.
  --force-restart: oneof<nothing, bool> # If true, then processes are forcefully restarted during upgrade even when the code version has not changed (the upgrade only changes configuration or data). (default: false)
  --monitoring-policy: any # Describes the parameters for monitoring an upgrade in Monitored mode. — shape: {FailureAction?: "Invalid"|"Rollback"|"Manual", HealthCheckRetryTimeoutInMilliseconds?: string, HealthCheckStableDurationInMilliseconds?: string, HealthCheckWaitDurationInMilliseconds?: string, UpgradeDomainTimeoutInMilliseconds?: string, UpgradeTimeoutInMilliseconds?: string}
  --rolling-upgrade-mode: string@rolling-upgrade-mode-completer # The mode used to monitor health during a rolling upgrade. The values are UnmonitoredAuto, UnmonitoredManual, and Monitored. (default: UnmonitoredAuto)
  --sort-order: string@sort-order-completer # Defines the order in which an upgrade proceeds through the cluster. (default: Default)
  --upgrade-kind: string@upgrade-kind-completer-1 # The kind of upgrade out of the following possible values. (default: Rolling)
  --upgrade-replica-set-check-timeout-in-seconds: int # The maximum amount of time to block processing of an upgrade domain and prevent loss of availability when there are unexpected issues. When this timeout expires, processing of the upgrade domain will proceed regardless of availability loss issues. The timeout is reset at the start of each upgrade domain. Valid values are between 0 and 42949672925 inclusive. (unsigned 32-bit integer). (format: int64, default: 42949672925)
]: any -> any {
  $in | http-request {
    method: post
    path: "/$/Upgrade"
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: timeout, var: timeout}]
    body: {content_type: "application/json", kind: json, fields: [{name: ApplicationHealthPolicyMap, var: application_health_policy_map}, {name: ClusterHealthPolicy, var: cluster_health_policy}, {name: ClusterUpgradeHealthPolicy, var: cluster_upgrade_health_policy}, {name: CodeVersion, var: code_version}, {name: ConfigVersion, var: config_version}, {name: EnableDeltaHealthEvaluation, var: enable_delta_health_evaluation}, {name: ForceRestart, var: force_restart}, {name: MonitoringPolicy, var: monitoring_policy}, {name: RollingUpgradeMode, var: rolling_upgrade_mode}, {name: SortOrder, var: sort_order}, {name: UpgradeKind, var: upgrade_kind}, {name: UpgradeReplicaSetCheckTimeoutInSeconds, var: upgrade_replica_set_check_timeout_in_seconds}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    api_version: $api_version, timeout: $timeout, application_health_policy_map: $application_health_policy_map, cluster_health_policy: $cluster_health_policy, cluster_upgrade_health_policy: $cluster_upgrade_health_policy, code_version: $code_version, config_version: $config_version, enable_delta_health_evaluation: $enable_delta_health_evaluation, force_restart: $force_restart, monitoring_policy: $monitoring_policy, rolling_upgrade_mode: $rolling_upgrade_mode, sort_order: $sort_order, upgrade_kind: $upgrade_kind, upgrade_replica_set_check_timeout_in_seconds: $upgrade_replica_set_check_timeout_in_seconds
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the list of application types in the Service Fabric cluster.
#
# GET /ApplicationTypes
# Returns: record<ContinuationToken: string, Items: table<ApplicationTypeDefinitionKind: string, DefaultParameterList: list, Name: string, Status: string, StatusDetails: string, Version: string>>
# operationId: GetApplicationTypeInfoList
export def "get-application-type-info-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --application-type-definition-kind-filter: int # Used to filter on ApplicationTypeDefinitionKind which is the mechanism used to define a Service Fabric application type. - Default - Default value, which performs the same function as selecting "All". The value is 0. - All - Filter that matches input with any ApplicationTypeDefinitionKind value. The value is 65535. - ServiceFabricApplicationPackage - Filter that matches input with ApplicationTypeDefinitionKind value ServiceFabricApplicationPackage. The value is 1. - Compose - Filter that matches input with ApplicationTypeDefinitionKind value Compose. The value is 2. (default: 0)
  --exclude-application-parameters: oneof<nothing, bool> # The flag that specifies whether application parameters will be excluded from the result. (default: false)
  --continuation-token: string # The continuation token parameter is used to obtain next set of results. A continuation token with a non-empty value is included in the response of the API when the results from the system do not fit in a single response. When this value is passed to the next API call, the API returns next set of results. If there are no further results, then the continuation token does not contain a value. The value of this parameter should not be URL encoded.
  --max-results: int # The maximum number of results to be returned as part of the paged queries. This parameter defines the upper bound on the number of results returned. The results returned can be less than the specified maximum results if they do not fit in the message as per the max message size restrictions defined in the configuration. If this parameter is zero or not specified, the paged query includes as many results as possible that fit in the return message. (format: int64, default: 0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/ApplicationTypes"
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: ApplicationTypeDefinitionKindFilter, var: application_type_definition_kind_filter}, {name: ExcludeApplicationParameters, var: exclude_application_parameters}, {name: ContinuationToken, var: continuation_token}, {name: MaxResults, var: max_results}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, application_type_definition_kind_filter: $application_type_definition_kind_filter, exclude_application_parameters: $exclude_application_parameters, continuation_token: $continuation_token, max_results: $max_results, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provisions or registers a Service Fabric application type with the cluster using the '.sfpkg' package in the external store or using the application package in the image store.
#
# POST /ApplicationTypes/$/Provision
# Discriminator (request): Kind
# operationId: ProvisionApplicationType
export def "provision-application-type" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-2 # The version of the API. This parameter is required and its value must be '6.2'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.2)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --async: oneof<nothing, bool> # Indicates whether or not provisioning should occur asynchronously. When set to true, the provision operation returns when the request is accepted by the system, and the provision operation continues without any timeout limit. The default value is false. For large application packages, we recommend setting the value to true.
  kind: string@kind-completer # The kind of application type registration or provision requested. The application package can be registered or provisioned either from the image store or from an external store. Following are the kinds of the application type provision.
]: any -> any {
  $in | http-request {
    method: post
    path: "/ApplicationTypes/$/Provision"
    query: [{name: api-version, var: api_version, required: true, default: "6.2"}, {name: timeout, var: timeout}]
    body: {content_type: "application/json", kind: json, fields: [{name: Async, var: async, required: true}, {name: Kind, var: kind}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    api_version: $api_version, timeout: $timeout, async: $async, kind: $kind
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the list of application types in the Service Fabric cluster matching exactly the specified name.
#
# GET /ApplicationTypes/{applicationTypeName}
# Returns: record<ContinuationToken: string, Items: table<ApplicationTypeDefinitionKind: string, DefaultParameterList: list, Name: string, Status: string, StatusDetails: string, Version: string>>
# operationId: GetApplicationTypeInfoListByName
export def "get-application-type-info-list-by-name" [
  application_type_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --application-type-version: string # The version of the application type.
  --exclude-application-parameters: oneof<nothing, bool> # The flag that specifies whether application parameters will be excluded from the result. (default: false)
  --continuation-token: string # The continuation token parameter is used to obtain next set of results. A continuation token with a non-empty value is included in the response of the API when the results from the system do not fit in a single response. When this value is passed to the next API call, the API returns next set of results. If there are no further results, then the continuation token does not contain a value. The value of this parameter should not be URL encoded.
  --max-results: int # The maximum number of results to be returned as part of the paged queries. This parameter defines the upper bound on the number of results returned. The results returned can be less than the specified maximum results if they do not fit in the message as per the max message size restrictions defined in the configuration. If this parameter is zero or not specified, the paged query includes as many results as possible that fit in the return message. (format: int64, default: 0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/ApplicationTypes/{applicationTypeName}"
    path_params: [{name: applicationTypeName, var: application_type_name}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: ApplicationTypeVersion, var: application_type_version}, {name: ExcludeApplicationParameters, var: exclude_application_parameters}, {name: ContinuationToken, var: continuation_token}, {name: MaxResults, var: max_results}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_type_name: $application_type_name, api_version: $api_version, application_type_version: $application_type_version, exclude_application_parameters: $exclude_application_parameters, continuation_token: $continuation_token, max_results: $max_results, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the manifest describing an application type.
#
# GET /ApplicationTypes/{applicationTypeName}/$/GetApplicationManifest
# Returns: record<Manifest: string>
# operationId: GetApplicationManifest
export def "get-application-manifest" [
  application_type_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --application-type-version: string # The version of the application type. (required)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/ApplicationTypes/{applicationTypeName}/$/GetApplicationManifest"
    path_params: [{name: applicationTypeName, var: application_type_name}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: ApplicationTypeVersion, var: application_type_version, required: true}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_type_name: $application_type_name, api_version: $api_version, application_type_version: $application_type_version, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the manifest describing a service type.
#
# GET /ApplicationTypes/{applicationTypeName}/$/GetServiceManifest
# Returns: record<Manifest: string>
# operationId: GetServiceManifest
export def "get-service-manifest" [
  application_type_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --application-type-version: string # The version of the application type. (required)
  --service-manifest-name: string # The name of a service manifest registered as part of an application type in a Service Fabric cluster. (required)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/ApplicationTypes/{applicationTypeName}/$/GetServiceManifest"
    path_params: [{name: applicationTypeName, var: application_type_name}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: ApplicationTypeVersion, var: application_type_version, required: true}, {name: ServiceManifestName, var: service_manifest_name, required: true}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_type_name: $application_type_name, api_version: $api_version, application_type_version: $application_type_version, service_manifest_name: $service_manifest_name, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the list containing the information about service types that are supported by a provisioned application type in a Service Fabric cluster.
#
# GET /ApplicationTypes/{applicationTypeName}/$/GetServiceTypes
# Returns: table<IsServiceGroup: bool, ServiceManifestName: string, ServiceManifestVersion: string, ServiceTypeDescription: record<Extensions: list, IsStateful: bool, Kind: string, LoadMetrics: list, PlacementConstraints: string, ServicePlacementPolicies: list, ServiceTypeName: string>>
# operationId: GetServiceTypeInfoList
export def "get-service-type-info-list" [
  application_type_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --application-type-version: string # The version of the application type. (required)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/ApplicationTypes/{applicationTypeName}/$/GetServiceTypes"
    path_params: [{name: applicationTypeName, var: application_type_name}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: ApplicationTypeVersion, var: application_type_version, required: true}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_type_name: $application_type_name, api_version: $api_version, application_type_version: $application_type_version, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the information about a specific service type that is supported by a provisioned application type in a Service Fabric cluster.
#
# GET /ApplicationTypes/{applicationTypeName}/$/GetServiceTypes/{serviceTypeName}
# Returns: record<IsServiceGroup: bool, ServiceManifestName: string, ServiceManifestVersion: string, ServiceTypeDescription: record<Extensions: list<record>, IsStateful: bool, Kind: string, LoadMetrics: list<record>, PlacementConstraints: string, ServicePlacementPolicies: list<record>, ServiceTypeName: string>>
# operationId: GetServiceTypeInfoByName
export def "get-service-type-info-by-name" [
  application_type_name: string
  service_type_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --application-type-version: string # The version of the application type. (required)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/ApplicationTypes/{applicationTypeName}/$/GetServiceTypes/{serviceTypeName}"
    path_params: [{name: applicationTypeName, var: application_type_name}, {name: serviceTypeName, var: service_type_name}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: ApplicationTypeVersion, var: application_type_version, required: true}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    application_type_name: $application_type_name, service_type_name: $service_type_name, api_version: $api_version, application_type_version: $application_type_version, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes or unregisters a Service Fabric application type from the cluster.
#
# POST /ApplicationTypes/{applicationTypeName}/$/Unprovision
# operationId: UnprovisionApplicationType
export def "unprovision-application-type" [
  application_type_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  application_type_version: string # The version of the application type as defined in the application manifest.
  --async: oneof<nothing, bool> # The flag indicating whether or not unprovision should occur asynchronously. When set to true, the unprovision operation returns when the request is accepted by the system, and the unprovision operation continues without any timeout limit. The default value is false. However, we recommend setting it to true for large application packages that were provisioned.
]: any -> any {
  $in | http-request {
    method: post
    path: "/ApplicationTypes/{applicationTypeName}/$/Unprovision"
    path_params: [{name: applicationTypeName, var: application_type_name}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: timeout, var: timeout}]
    body: {content_type: "application/json", kind: json, fields: [{name: ApplicationTypeVersion, var: application_type_version}, {name: Async, var: async}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    application_type_name: $application_type_name, api_version: $api_version, timeout: $timeout, application_type_version: $application_type_version, async: $async
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the list of applications created in the Service Fabric cluster that match the specified filters.
#
# GET /Applications
# Returns: record<ContinuationToken: string, Items: table<ApplicationDefinitionKind: string, HealthState: string, Id: string, Name: string, Parameters: list, Status: string, TypeName: string, TypeVersion: string>>
# operationId: GetApplicationInfoList
export def "get-application-info-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-3 # The version of the API. This parameter is required and its value must be '6.1'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.1)
  --application-definition-kind-filter: int # Used to filter on ApplicationDefinitionKind, which is the mechanism used to define a Service Fabric application. - Default - Default value, which performs the same function as selecting "All". The value is 0. - All - Filter that matches input with any ApplicationDefinitionKind value. The value is 65535. - ServiceFabricApplicationDescription - Filter that matches input with ApplicationDefinitionKind value ServiceFabricApplicationDescription. The value is 1. - Compose - Filter that matches input with ApplicationDefinitionKind value Compose. The value is 2. (default: 0)
  --application-type-name: string # The application type name used to filter the applications to query for. This value should not contain the application type version.
  --exclude-application-parameters: oneof<nothing, bool> # The flag that specifies whether application parameters will be excluded from the result. (default: false)
  --continuation-token: string # The continuation token parameter is used to obtain next set of results. A continuation token with a non-empty value is included in the response of the API when the results from the system do not fit in a single response. When this value is passed to the next API call, the API returns next set of results. If there are no further results, then the continuation token does not contain a value. The value of this parameter should not be URL encoded.
  --max-results: int # The maximum number of results to be returned as part of the paged queries. This parameter defines the upper bound on the number of results returned. The results returned can be less than the specified maximum results if they do not fit in the message as per the max message size restrictions defined in the configuration. If this parameter is zero or not specified, the paged query includes as many results as possible that fit in the return message. (format: int64, default: 0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Applications"
    query: [{name: api-version, var: api_version, required: true, default: "6.1"}, {name: ApplicationDefinitionKindFilter, var: application_definition_kind_filter}, {name: ApplicationTypeName, var: application_type_name}, {name: ExcludeApplicationParameters, var: exclude_application_parameters}, {name: ContinuationToken, var: continuation_token}, {name: MaxResults, var: max_results}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, application_definition_kind_filter: $application_definition_kind_filter, application_type_name: $application_type_name, exclude_application_parameters: $exclude_application_parameters, continuation_token: $continuation_token, max_results: $max_results, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a Service Fabric application.
#
# POST /Applications/$/Create
# operationId: CreateApplication
export def "create-application" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --application-capacity: any # Describes capacity information for services of this application. This description can be used for describing the following. - Reserving the capacity for the services on the nodes - Limiting the total number of nodes that services of this application can run on - Limiting the custom capacity metrics to limit the total consumption of this metric by the services of this application — shape: {ApplicationMetrics?: list, MaximumNodes?: int, MinimumNodes?: int}
  --managed-application-identity: any # Managed application identity description. — shape: {ManagedIdentities?: list, TokenServiceEndpoint?: string}
  name: string # The name of the application, including the 'fabric:' URI scheme.
  --parameter-list: list # List of application parameters with overridden values from their default values specified in the application manifest. — item shape: {Key: string, Value: string}
  type_name: string # The application type name as defined in the application manifest.
  type_version: string # The version of the application type as defined in the application manifest.
]: any -> any {
  $in | http-request {
    method: post
    path: "/Applications/$/Create"
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: timeout, var: timeout}]
    body: {content_type: "application/json", kind: json, fields: [{name: ApplicationCapacity, var: application_capacity}, {name: ManagedApplicationIdentity, var: managed_application_identity}, {name: Name, var: name}, {name: ParameterList, var: parameter_list}, {name: TypeName, var: type_name}, {name: TypeVersion, var: type_version}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    api_version: $api_version, timeout: $timeout, application_capacity: $application_capacity, managed_application_identity: $managed_application_identity, name: $name, parameter_list: $parameter_list, type_name: $type_name, type_version: $type_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about a Service Fabric application.
#
# GET /Applications/{applicationId}
# Returns: record<ApplicationDefinitionKind: string, HealthState: string, Id: string, Name: string, Parameters: table<Key: string, Value: string>, Status: string, TypeName: string, TypeVersion: string>
# operationId: GetApplicationInfo
export def "get-application-info" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --exclude-application-parameters: oneof<nothing, bool> # The flag that specifies whether application parameters will be excluded from the result. (default: false)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Applications/{applicationId}"
    path_params: [{name: applicationId, var: application_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: ExcludeApplicationParameters, var: exclude_application_parameters}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    application_id: $application_id, api_version: $api_version, exclude_application_parameters: $exclude_application_parameters, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an existing Service Fabric application.
#
# POST /Applications/{applicationId}/$/Delete
# operationId: DeleteApplication
export def "delete-application" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --force-remove: oneof<nothing, bool> # Remove a Service Fabric application or service forcefully without going through the graceful shutdown sequence. This parameter can be used to forcefully delete an application or service for which delete is timing out due to issues in the service code that prevents graceful close of replicas.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> any {
  http-request {
    method: post
    path: "/Applications/{applicationId}/$/Delete"
    path_params: [{name: applicationId, var: application_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: ForceRemove, var: force_remove}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, api_version: $api_version, force_remove: $force_remove, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disables periodic backup of Service Fabric application.
#
# POST /Applications/{applicationId}/$/DisableBackup
# operationId: DisableApplicationBackup
export def "disable-application-backup" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --clean-backup: oneof<nothing, bool> # Boolean flag to delete backups. It can be set to true for deleting all the backups which were created for the backup entity that is getting disabled for backup.
]: any -> any {
  $in | http-request {
    method: post
    path: "/Applications/{applicationId}/$/DisableBackup"
    path_params: [{name: applicationId, var: application_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.4"}, {name: timeout, var: timeout}]
    body: {content_type: "application/json", kind: json, fields: [{name: CleanBackup, var: clean_backup, required: true}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    application_id: $application_id, api_version: $api_version, timeout: $timeout, clean_backup: $clean_backup
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enables periodic backup of stateful partitions under this Service Fabric application.
#
# POST /Applications/{applicationId}/$/EnableBackup
# operationId: EnableApplicationBackup
export def "enable-application-backup" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  backup_policy_name: string # Name of the backup policy to be used for enabling periodic backups.
]: any -> any {
  $in | http-request {
    method: post
    path: "/Applications/{applicationId}/$/EnableBackup"
    path_params: [{name: applicationId, var: application_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.4"}, {name: timeout, var: timeout}]
    body: {content_type: "application/json", kind: json, fields: [{name: BackupPolicyName, var: backup_policy_name}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    application_id: $application_id, api_version: $api_version, timeout: $timeout, backup_policy_name: $backup_policy_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the Service Fabric application backup configuration information.
#
# GET /Applications/{applicationId}/$/GetBackupConfigurationInfo
# Returns: record<ContinuationToken: string, Items: table<Kind: string, PolicyInheritedFrom: string, PolicyName: string, SuspensionInfo: record>>
# operationId: GetApplicationBackupConfigurationInfo
export def "get-application-backup-configuration-info" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.4)
  --continuation-token: string # The continuation token parameter is used to obtain next set of results. A continuation token with a non-empty value is included in the response of the API when the results from the system do not fit in a single response. When this value is passed to the next API call, the API returns next set of results. If there are no further results, then the continuation token does not contain a value. The value of this parameter should not be URL encoded.
  --max-results: int # The maximum number of results to be returned as part of the paged queries. This parameter defines the upper bound on the number of results returned. The results returned can be less than the specified maximum results if they do not fit in the message as per the max message size restrictions defined in the configuration. If this parameter is zero or not specified, the paged query includes as many results as possible that fit in the return message. (format: int64, default: 0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Applications/{applicationId}/$/GetBackupConfigurationInfo"
    path_params: [{name: applicationId, var: application_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.4"}, {name: ContinuationToken, var: continuation_token}, {name: MaxResults, var: max_results}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, api_version: $api_version, continuation_token: $continuation_token, max_results: $max_results, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the list of backups available for every partition in this application.
#
# GET /Applications/{applicationId}/$/GetBackups
# Returns: record<ContinuationToken: string, Items: table<ApplicationName: string, BackupChainId: string, BackupId: string, BackupLocation: string, BackupType: string, CreationTimeUtc: string, EpochOfLastBackupRecord: record, FailureError: record, LsnOfLastBackupRecord: string, PartitionInformation: record, ServiceManifestVersion: string, ServiceName: string>>
# operationId: GetApplicationBackupList
export def "get-application-backup-list" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --latest: oneof<nothing, bool> # Specifies whether to get only the most recent backup available for a partition for the specified time range. (default: false)
  --start-date-time-filter: string # Specify the start date time from which to enumerate backups, in datetime format. The date time must be specified in ISO8601 format. This is an optional parameter. If not specified, all backups from the beginning are enumerated. (format: date-time)
  --end-date-time-filter: string # Specify the end date time till which to enumerate backups, in datetime format. The date time must be specified in ISO8601 format. This is an optional parameter. If not specified, enumeration is done till the most recent backup. (format: date-time)
  --continuation-token: string # The continuation token parameter is used to obtain next set of results. A continuation token with a non-empty value is included in the response of the API when the results from the system do not fit in a single response. When this value is passed to the next API call, the API returns next set of results. If there are no further results, then the continuation token does not contain a value. The value of this parameter should not be URL encoded.
  --max-results: int # The maximum number of results to be returned as part of the paged queries. This parameter defines the upper bound on the number of results returned. The results returned can be less than the specified maximum results if they do not fit in the message as per the max message size restrictions defined in the configuration. If this parameter is zero or not specified, the paged query includes as many results as possible that fit in the return message. (format: int64, default: 0)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Applications/{applicationId}/$/GetBackups"
    path_params: [{name: applicationId, var: application_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.4"}, {name: timeout, var: timeout}, {name: Latest, var: latest}, {name: StartDateTimeFilter, var: start_date_time_filter}, {name: EndDateTimeFilter, var: end_date_time_filter}, {name: ContinuationToken, var: continuation_token}, {name: MaxResults, var: max_results}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, api_version: $api_version, timeout: $timeout, latest: $latest, start_date_time_filter: $start_date_time_filter, end_date_time_filter: $end_date_time_filter, continuation_token: $continuation_token, max_results: $max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the health of the service fabric application.
#
# GET /Applications/{applicationId}/$/GetHealth
# Returns: record<DeployedApplicationHealthStates: table<ApplicationName: string, NodeName: string, AggregatedHealthState: string>, Name: string, ServiceHealthStates: table<ServiceName: string, AggregatedHealthState: string>, AggregatedHealthState: string, HealthEvents: table<IsExpired: bool, LastErrorTransitionAt: string, LastModifiedUtcTimestamp: string, LastOkTransitionAt: string, LastWarningTransitionAt: string, SourceUtcTimestamp: string, Description: string, HealthState: string, Property: string, RemoveWhenExpired: bool, SequenceNumber: string, SourceId: string, TimeToLiveInMilliSeconds: string>, HealthStatistics: record<HealthStateCountList: list<record>>, UnhealthyEvaluations: table<HealthEvaluation: record>>
# operationId: GetApplicationHealth
export def "get-application-health" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --events-health-state-filter: int # Allows filtering the collection of HealthEvent objects returned based on health state. The possible values for this parameter include integer value of one of the following health states. Only events that match the filter are returned. All events are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these values, obtained using the bitwise 'OR' operator. For example, If the provided value is 6 then all of the events with HealthState value of OK (2) and Warning (4) are returned. - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --deployed-applications-health-state-filter: int # Allows filtering of the deployed applications health state objects returned in the result of application health query based on their health state. The possible values for this parameter include integer value of one of the following health states. Only deployed applications that match the filter will be returned. All deployed applications are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these values, obtained using bitwise 'OR' operator. For example, if the provided value is 6 then health state of deployed applications with HealthState value of OK (2) and Warning (4) are returned. - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --services-health-state-filter: int # Allows filtering of the services health state objects returned in the result of services health query based on their health state. The possible values for this parameter include integer value of one of the following health states. Only services that match the filter are returned. All services are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these values, obtained using bitwise 'OR' operator. For example, if the provided value is 6 then health state of services with HealthState value of OK (2) and Warning (4) will be returned. - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --exclude-health-statistics: oneof<nothing, bool> # Indicates whether the health statistics should be returned as part of the query result. False by default. The statistics show the number of children entities in health state Ok, Warning, and Error. (default: false)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Applications/{applicationId}/$/GetHealth"
    path_params: [{name: applicationId, var: application_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: EventsHealthStateFilter, var: events_health_state_filter}, {name: DeployedApplicationsHealthStateFilter, var: deployed_applications_health_state_filter}, {name: ServicesHealthStateFilter, var: services_health_state_filter}, {name: ExcludeHealthStatistics, var: exclude_health_statistics}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, api_version: $api_version, events_health_state_filter: $events_health_state_filter, deployed_applications_health_state_filter: $deployed_applications_health_state_filter, services_health_state_filter: $services_health_state_filter, exclude_health_statistics: $exclude_health_statistics, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the health of a Service Fabric application using the specified policy.
#
# POST /Applications/{applicationId}/$/GetHealth
# Returns: record<DeployedApplicationHealthStates: table<ApplicationName: string, NodeName: string, AggregatedHealthState: string>, Name: string, ServiceHealthStates: table<ServiceName: string, AggregatedHealthState: string>, AggregatedHealthState: string, HealthEvents: table<IsExpired: bool, LastErrorTransitionAt: string, LastModifiedUtcTimestamp: string, LastOkTransitionAt: string, LastWarningTransitionAt: string, SourceUtcTimestamp: string, Description: string, HealthState: string, Property: string, RemoveWhenExpired: bool, SequenceNumber: string, SourceId: string, TimeToLiveInMilliSeconds: string>, HealthStatistics: record<HealthStateCountList: list<record>>, UnhealthyEvaluations: table<HealthEvaluation: record>>
# operationId: GetApplicationHealthUsingPolicy
export def "get-application-health-using-policy" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --events-health-state-filter: int # Allows filtering the collection of HealthEvent objects returned based on health state. The possible values for this parameter include integer value of one of the following health states. Only events that match the filter are returned. All events are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these values, obtained using the bitwise 'OR' operator. For example, If the provided value is 6 then all of the events with HealthState value of OK (2) and Warning (4) are returned. - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --deployed-applications-health-state-filter: int # Allows filtering of the deployed applications health state objects returned in the result of application health query based on their health state. The possible values for this parameter include integer value of one of the following health states. Only deployed applications that match the filter will be returned. All deployed applications are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these values, obtained using bitwise 'OR' operator. For example, if the provided value is 6 then health state of deployed applications with HealthState value of OK (2) and Warning (4) are returned. - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --services-health-state-filter: int # Allows filtering of the services health state objects returned in the result of services health query based on their health state. The possible values for this parameter include integer value of one of the following health states. Only services that match the filter are returned. All services are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these values, obtained using bitwise 'OR' operator. For example, if the provided value is 6 then health state of services with HealthState value of OK (2) and Warning (4) will be returned. - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --exclude-health-statistics: oneof<nothing, bool> # Indicates whether the health statistics should be returned as part of the query result. False by default. The statistics show the number of children entities in health state Ok, Warning, and Error. (default: false)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --consider-warning-as-error: oneof<nothing, bool> # Indicates whether warnings are treated with the same severity as errors. (default: false)
  --default-service-type-health-policy: any # Represents the health policy used to evaluate the health of services belonging to a service type. — shape: {MaxPercentUnhealthyPartitionsPerService?: int, MaxPercentUnhealthyReplicasPerPartition?: int, MaxPercentUnhealthyServices?: int}
  --max-percent-unhealthy-deployed-applications: int # The maximum allowed percentage of unhealthy deployed applications. Allowed values are Byte values from zero to 100. The percentage represents the maximum tolerated percentage of deployed applications that can be unhealthy before the application is considered in error. This is calculated by dividing the number of unhealthy deployed applications over the number of nodes where the application is currently deployed on in the cluster. The computation rounds up to tolerate one failure on small numbers of nodes. Default percentage is zero. (default: 0)
  --service-type-health-policy-map: list # Defines a ServiceTypeHealthPolicy per service type name. The entries in the map replace the default service type health policy for each specified service type. For example, in an application that contains both a stateless gateway service type and a stateful engine service type, the health policies for the stateless and stateful services can be configured differently. With policy per service type, there's more granular control of the health of the service. If no policy is specified for a service type name, the DefaultServiceTypeHealthPolicy is used for evaluation. — item shape: {Key: string, Value: any}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Applications/{applicationId}/$/GetHealth"
    path_params: [{name: applicationId, var: application_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: EventsHealthStateFilter, var: events_health_state_filter}, {name: DeployedApplicationsHealthStateFilter, var: deployed_applications_health_state_filter}, {name: ServicesHealthStateFilter, var: services_health_state_filter}, {name: ExcludeHealthStatistics, var: exclude_health_statistics}, {name: timeout, var: timeout}]
    body: {content_type: "application/json", kind: json, fields: [{name: ConsiderWarningAsError, var: consider_warning_as_error}, {name: DefaultServiceTypeHealthPolicy, var: default_service_type_health_policy}, {name: MaxPercentUnhealthyDeployedApplications, var: max_percent_unhealthy_deployed_applications}, {name: ServiceTypeHealthPolicyMap, var: service_type_health_policy_map}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, api_version: $api_version, events_health_state_filter: $events_health_state_filter, deployed_applications_health_state_filter: $deployed_applications_health_state_filter, services_health_state_filter: $services_health_state_filter, exclude_health_statistics: $exclude_health_statistics, timeout: $timeout, consider_warning_as_error: $consider_warning_as_error, default_service_type_health_policy: $default_service_type_health_policy, max_percent_unhealthy_deployed_applications: $max_percent_unhealthy_deployed_applications, service_type_health_policy_map: $service_type_health_policy_map
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets load information about a Service Fabric application.
#
# GET /Applications/{applicationId}/$/GetLoadInformation
# Returns: record<ApplicationLoadMetricInformation: table<MaximumCapacity: int, Name: string, ReservationCapacity: int, TotalApplicationCapacity: int>, Id: string, MaximumNodes: int, MinimumNodes: int, NodeCount: int>
# operationId: GetApplicationLoadInfo
export def "get-application-load-info" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Applications/{applicationId}/$/GetLoadInformation"
    path_params: [{name: applicationId, var: application_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    application_id: $application_id, api_version: $api_version, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the information about all services belonging to the application specified by the application ID.
#
# GET /Applications/{applicationId}/$/GetServices
# Returns: record<ContinuationToken: string, Items: table<HealthState: string, Id: string, IsServiceGroup: bool, ManifestVersion: string, Name: string, ServiceKind: string, ServiceStatus: string, TypeName: string>>
# operationId: GetServiceInfoList
export def "get-service-info-list" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --service-type-name: string # The service type name used to filter the services to query for.
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --continuation-token: string # The continuation token parameter is used to obtain next set of results. A continuation token with a non-empty value is included in the response of the API when the results from the system do not fit in a single response. When this value is passed to the next API call, the API returns next set of results. If there are no further results, then the continuation token does not contain a value. The value of this parameter should not be URL encoded.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Applications/{applicationId}/$/GetServices"
    path_params: [{name: applicationId, var: application_id}]
    query: [{name: ServiceTypeName, var: service_type_name}, {name: api-version, var: api_version, required: true, default: "6.0"}, {name: ContinuationToken, var: continuation_token}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, service_type_name: $service_type_name, api_version: $api_version, continuation_token: $continuation_token, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates the specified Service Fabric service.
#
# POST /Applications/{applicationId}/$/GetServices/$/Create
# Discriminator (request): ServiceKind
# operationId: CreateService
export def "create-service" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --application-name: string # The name of the application, including the 'fabric:' URI scheme.
  --correlation-scheme: list # A list that describes the correlation of the service with other services. — item shape: {Scheme: "Invalid"|"Affinity"|"AlignedAffinity"|"NonAlignedAffinity", ServiceName: string}
  --default-move-cost: string@default-move-cost-completer # Specifies the move cost for the service.
  --initialization-data: list<int> # Array of bytes to be sent as an integer array. Each element of array is a number between 0 and 255.
  --is-default-move-cost-specified: oneof<nothing, bool> # Indicates if the DefaultMoveCost property is specified.
  partition_description: any # Describes how the service is partitioned. — shape: {PartitionScheme: "Invalid"|"Singleton"|"UniformInt64Range"|"Named"}
  --placement-constraints: string # The placement constraints as a string. Placement constraints are boolean expressions on node properties and allow for restricting a service to particular nodes based on the service requirements. For example, to place a service on nodes where NodeType is blue specify the following: "NodeColor == blue)".
  --scaling-policies: list # A list that describes the scaling policies. — item shape: {ScalingMechanism: any, ScalingTrigger: any}
  --service-dns-name: string # The DNS name of the service. It requires the DNS system service to be enabled in Service Fabric cluster.
  service_kind: string@service-kind-completer # The kind of service (Stateless or Stateful).
  --service-load-metrics: list # The service load metrics is given as an array of ServiceLoadMetricDescription objects. — item shape: {DefaultLoad?: int, Name: string, PrimaryDefaultLoad?: int, SecondaryDefaultLoad?: int, Weight?: "Zero"|"Low"|"Medium"|"High"}
  service_name: string # The full name of the service with 'fabric:' URI scheme.
  --service-package-activation-mode: string@service-package-activation-mode-completer # The activation mode of service package to be used for a Service Fabric service. This is specified at the time of creating the Service.
  --service-placement-policies: list # A list that describes the correlation of the service with other services. — item shape: {Type: "Invalid"|"InvalidDomain"|"RequireDomain"|"PreferPrimaryDomain"|"RequireDomainDistribution"|"NonPartiallyPlaceService"}
  service_type_name: string # Name of the service type as specified in the service manifest.
]: any -> any {
  $in | http-request {
    method: post
    path: "/Applications/{applicationId}/$/GetServices/$/Create"
    path_params: [{name: applicationId, var: application_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: timeout, var: timeout}]
    body: {content_type: "application/json", kind: json, fields: [{name: ApplicationName, var: application_name}, {name: CorrelationScheme, var: correlation_scheme}, {name: DefaultMoveCost, var: default_move_cost}, {name: InitializationData, var: initialization_data}, {name: IsDefaultMoveCostSpecified, var: is_default_move_cost_specified}, {name: PartitionDescription, var: partition_description}, {name: PlacementConstraints, var: placement_constraints}, {name: ScalingPolicies, var: scaling_policies}, {name: ServiceDnsName, var: service_dns_name}, {name: ServiceKind, var: service_kind}, {name: ServiceLoadMetrics, var: service_load_metrics}, {name: ServiceName, var: service_name}, {name: ServicePackageActivationMode, var: service_package_activation_mode}, {name: ServicePlacementPolicies, var: service_placement_policies}, {name: ServiceTypeName, var: service_type_name}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    application_id: $application_id, api_version: $api_version, timeout: $timeout, application_name: $application_name, correlation_scheme: $correlation_scheme, default_move_cost: $default_move_cost, initialization_data: $initialization_data, is_default_move_cost_specified: $is_default_move_cost_specified, partition_description: $partition_description, placement_constraints: $placement_constraints, scaling_policies: $scaling_policies, service_dns_name: $service_dns_name, service_kind: $service_kind, service_load_metrics: $service_load_metrics, service_name: $service_name, service_package_activation_mode: $service_package_activation_mode, service_placement_policies: $service_placement_policies, service_type_name: $service_type_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a Service Fabric service from the service template.
#
# POST /Applications/{applicationId}/$/GetServices/$/CreateFromTemplate
# operationId: CreateServiceFromTemplate
export def "create-service-from-template" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  application_name: string # The name of the application, including the 'fabric:' URI scheme.
  --initialization-data: list<int> # Array of bytes to be sent as an integer array. Each element of array is a number between 0 and 255.
  --service-dns-name: string # The DNS name of the service. It requires the DNS system service to be enabled in Service Fabric cluster.
  service_name: string # The full name of the service with 'fabric:' URI scheme.
  --service-package-activation-mode: string@service-package-activation-mode-completer # The activation mode of service package to be used for a Service Fabric service. This is specified at the time of creating the Service.
  service_type_name: string # Name of the service type as specified in the service manifest.
]: any -> any {
  $in | http-request {
    method: post
    path: "/Applications/{applicationId}/$/GetServices/$/CreateFromTemplate"
    path_params: [{name: applicationId, var: application_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: timeout, var: timeout}]
    body: {content_type: "application/json", kind: json, fields: [{name: ApplicationName, var: application_name}, {name: InitializationData, var: initialization_data}, {name: ServiceDnsName, var: service_dns_name}, {name: ServiceName, var: service_name}, {name: ServicePackageActivationMode, var: service_package_activation_mode}, {name: ServiceTypeName, var: service_type_name}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    application_id: $application_id, api_version: $api_version, timeout: $timeout, application_name: $application_name, initialization_data: $initialization_data, service_dns_name: $service_dns_name, service_name: $service_name, service_package_activation_mode: $service_package_activation_mode, service_type_name: $service_type_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the information about the specific service belonging to the Service Fabric application.
#
# GET /Applications/{applicationId}/$/GetServices/{serviceId}
# Discriminator (response): ServiceKind
# Returns: record<HealthState: string, Id: string, IsServiceGroup: bool, ManifestVersion: string, Name: string, ServiceKind: string, ServiceStatus: string, TypeName: string>
# operationId: GetServiceInfo
export def "get-service-info" [
  application_id: string
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Applications/{applicationId}/$/GetServices/{serviceId}"
    path_params: [{name: applicationId, var: application_id}, {name: serviceId, var: service_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    application_id: $application_id, service_id: $service_id, api_version: $api_version, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets details for the latest upgrade performed on this application.
#
# GET /Applications/{applicationId}/$/GetUpgradeProgress
# Returns: record<CurrentUpgradeDomainProgress: record<DomainName: string, NodeUpgradeProgressList: list<record>>, FailureReason: string, FailureTimestampUtc: string, Name: string, NextUpgradeDomain: string, RollingUpgradeMode: string, StartTimestampUtc: string, TargetApplicationTypeVersion: string, TypeName: string, UnhealthyEvaluations: table<HealthEvaluation: record>, UpgradeDescription: record<ApplicationHealthPolicy: record<ConsiderWarningAsError: bool, DefaultServiceTypeHealthPolicy: record, MaxPercentUnhealthyDeployedApplications: int, ServiceTypeHealthPolicyMap: list>, ForceRestart: bool, MonitoringPolicy: record<FailureAction: string, HealthCheckRetryTimeoutInMilliseconds: string, HealthCheckStableDurationInMilliseconds: string, HealthCheckWaitDurationInMilliseconds: string, UpgradeDomainTimeoutInMilliseconds: string, UpgradeTimeoutInMilliseconds: string>, Name: string, Parameters: list<record>, RollingUpgradeMode: string, SortOrder: string, TargetApplicationTypeVersion: string, UpgradeKind: string, UpgradeReplicaSetCheckTimeoutInSeconds: int>, UpgradeDomainDurationInMilliseconds: string, UpgradeDomainProgressAtFailure: record<DomainName: string, NodeUpgradeProgressList: list<record>>, UpgradeDomains: table<Name: string, State: string>, UpgradeDurationInMilliseconds: string, UpgradeState: string, UpgradeStatusDetails: string>
# operationId: GetApplicationUpgrade
export def "get-application-upgrade" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Applications/{applicationId}/$/GetUpgradeProgress"
    path_params: [{name: applicationId, var: application_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, api_version: $api_version, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resumes upgrading an application in the Service Fabric cluster.
#
# POST /Applications/{applicationId}/$/MoveToNextUpgradeDomain
# operationId: ResumeApplicationUpgrade
export def "resume-application-upgrade" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  upgrade_domain_name: string # The name of the upgrade domain in which to resume the upgrade.
]: any -> any {
  $in | http-request {
    method: post
    path: "/Applications/{applicationId}/$/MoveToNextUpgradeDomain"
    path_params: [{name: applicationId, var: application_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: timeout, var: timeout}]
    body: {content_type: "application/json", kind: json, fields: [{name: UpgradeDomainName, var: upgrade_domain_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, api_version: $api_version, timeout: $timeout, upgrade_domain_name: $upgrade_domain_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sends a health report on the Service Fabric application.
#
# POST /Applications/{applicationId}/$/ReportHealth
# operationId: ReportApplicationHealth
export def "report-application-health" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --immediate: oneof<nothing, bool> # A flag that indicates whether the report should be sent immediately. A health report is sent to a Service Fabric gateway Application, which forwards to the health store. If Immediate is set to true, the report is sent immediately from HTTP Gateway to the health store, regardless of the fabric client settings that the HTTP Gateway Application is using. This is useful for critical reports that should be sent as soon as possible. Depending on timing and other conditions, sending the report may still fail, for example if the HTTP Gateway is closed or the message doesn't reach the Gateway. If Immediate is set to false, the report is sent based on the health client settings from the HTTP Gateway. Therefore, it will be batched according to the HealthReportSendInterval configuration. This is the recommended setting because it allows the health client to optimize health reporting messages to health store as well as health report processing. By default, reports are not sent immediately. (default: false)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --description: string # The description of the health information. It represents free text used to add human readable information about the report. The maximum string length for the description is 4096 characters. If the provided string is longer, it will be automatically truncated. When truncated, the last characters of the description contain a marker "[Truncated]", and total string size is 4096 characters. The presence of the marker indicates to users that truncation occurred. Note that when truncated, the description has less than 4096 characters from the original string.
  health_state: string@health-state-completer # The health state of a Service Fabric entity such as Cluster, Node, Application, Service, Partition, Replica etc.
  property: string # The property of the health information. An entity can have health reports for different properties. The property is a string and not a fixed enumeration to allow the reporter flexibility to categorize the state condition that triggers the report. For example, a reporter with SourceId "LocalWatchdog" can monitor the state of the available disk on a node, so it can report "AvailableDisk" property on that node. The same reporter can monitor the node connectivity, so it can report a property "Connectivity" on the same node. In the health store, these reports are treated as separate health events for the specified node. Together with the SourceId, the property uniquely identifies the health information.
  --remove-when-expired: oneof<nothing, bool> # Value that indicates whether the report is removed from health store when it expires. If set to true, the report is removed from the health store after it expires. If set to false, the report is treated as an error when expired. The value of this property is false by default. When clients report periodically, they should set RemoveWhenExpired false (default). This way, if the reporter has issues (e.g. deadlock) and can't report, the entity is evaluated at error when the health report expires. This flags the entity as being in Error health state.
  --sequence-number: string # The sequence number for this health report as a numeric string. The report sequence number is used by the health store to detect stale reports. If not specified, a sequence number is auto-generated by the health client when a report is added.
  source_id: string # The source name that identifies the client/watchdog/system component that generated the health information.
  --time-to-live-in-milli-seconds: string # The duration for which this health report is valid. This field uses ISO8601 format for specifying the duration. When clients report periodically, they should send reports with higher frequency than time to live. If clients report on transition, they can set the time to live to infinite. When time to live expires, the health event that contains the health information is either removed from health store, if RemoveWhenExpired is true, or evaluated at error, if RemoveWhenExpired false. If not specified, time to live defaults to infinite value. (format: duration)
]: any -> any {
  $in | http-request {
    method: post
    path: "/Applications/{applicationId}/$/ReportHealth"
    path_params: [{name: applicationId, var: application_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: Immediate, var: immediate}, {name: timeout, var: timeout}]
    body: {content_type: "application/json", kind: json, fields: [{name: Description, var: description}, {name: HealthState, var: health_state}, {name: Property, var: property}, {name: RemoveWhenExpired, var: remove_when_expired}, {name: SequenceNumber, var: sequence_number}, {name: SourceId, var: source_id}, {name: TimeToLiveInMilliSeconds, var: time_to_live_in_milli_seconds}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, api_version: $api_version, immediate: $immediate, timeout: $timeout, description: $description, health_state: $health_state, property: $property, remove_when_expired: $remove_when_expired, sequence_number: $sequence_number, source_id: $source_id, time_to_live_in_milli_seconds: $time_to_live_in_milli_seconds
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resumes periodic backup of a Service Fabric application which was previously suspended.
#
# POST /Applications/{applicationId}/$/ResumeBackup
# operationId: ResumeApplicationBackup
export def "resume-application-backup" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> any {
  http-request {
    method: post
    path: "/Applications/{applicationId}/$/ResumeBackup"
    path_params: [{name: applicationId, var: application_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.4"}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    application_id: $application_id, api_version: $api_version, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts rolling back the currently on-going upgrade of an application in the Service Fabric cluster.
#
# POST /Applications/{applicationId}/$/RollbackUpgrade
# operationId: RollbackApplicationUpgrade
export def "rollback-application-upgrade" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> any {
  http-request {
    method: post
    path: "/Applications/{applicationId}/$/RollbackUpgrade"
    path_params: [{name: applicationId, var: application_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, api_version: $api_version, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Suspends periodic backup for the specified Service Fabric application.
#
# POST /Applications/{applicationId}/$/SuspendBackup
# operationId: SuspendApplicationBackup
export def "suspend-application-backup" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> any {
  http-request {
    method: post
    path: "/Applications/{applicationId}/$/SuspendBackup"
    path_params: [{name: applicationId, var: application_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.4"}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    application_id: $application_id, api_version: $api_version, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an ongoing application upgrade in the Service Fabric cluster.
#
# POST /Applications/{applicationId}/$/UpdateUpgrade
# operationId: UpdateApplicationUpgrade
export def "update-application-upgrade" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --application-health-policy: any # Defines a health policy used to evaluate the health of an application or one of its children entities. — shape: {ConsiderWarningAsError?: bool, DefaultServiceTypeHealthPolicy?: any, MaxPercentUnhealthyDeployedApplications?: int, ServiceTypeHealthPolicyMap?: list}
  name: string # The name of the application, including the 'fabric:' URI scheme.
  --update-description: any # Describes the parameters for updating a rolling upgrade of application or cluster. — shape: {FailureAction?: "Invalid"|"Rollback"|"Manual", ForceRestart?: bool, HealthCheckRetryTimeoutInMilliseconds?: string, HealthCheckStableDurationInMilliseconds?: string, HealthCheckWaitDurationInMilliseconds?: string, ReplicaSetCheckTimeoutInMilliseconds?: int, RollingUpgradeMode: "Invalid"|"UnmonitoredAuto"|"UnmonitoredManual"|"Monitored", UpgradeDomainTimeoutInMilliseconds?: string, UpgradeTimeoutInMilliseconds?: string}
  upgrade_kind: string@upgrade-kind-completer-1 # The kind of upgrade out of the following possible values. (default: Rolling)
]: any -> any {
  $in | http-request {
    method: post
    path: "/Applications/{applicationId}/$/UpdateUpgrade"
    path_params: [{name: applicationId, var: application_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: timeout, var: timeout}]
    body: {content_type: "application/json", kind: json, fields: [{name: ApplicationHealthPolicy, var: application_health_policy}, {name: Name, var: name}, {name: UpdateDescription, var: update_description}, {name: UpgradeKind, var: upgrade_kind}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, api_version: $api_version, timeout: $timeout, application_health_policy: $application_health_policy, name: $name, update_description: $update_description, upgrade_kind: $upgrade_kind
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts upgrading an application in the Service Fabric cluster.
#
# POST /Applications/{applicationId}/$/Upgrade
# operationId: StartApplicationUpgrade
export def "start-application-upgrade" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --application-health-policy: any # Defines a health policy used to evaluate the health of an application or one of its children entities. — shape: {ConsiderWarningAsError?: bool, DefaultServiceTypeHealthPolicy?: any, MaxPercentUnhealthyDeployedApplications?: int, ServiceTypeHealthPolicyMap?: list}
  --force-restart: oneof<nothing, bool> # If true, then processes are forcefully restarted during upgrade even when the code version has not changed (the upgrade only changes configuration or data). (default: false)
  --monitoring-policy: any # Describes the parameters for monitoring an upgrade in Monitored mode. — shape: {FailureAction?: "Invalid"|"Rollback"|"Manual", HealthCheckRetryTimeoutInMilliseconds?: string, HealthCheckStableDurationInMilliseconds?: string, HealthCheckWaitDurationInMilliseconds?: string, UpgradeDomainTimeoutInMilliseconds?: string, UpgradeTimeoutInMilliseconds?: string}
  name: string # The name of the target application, including the 'fabric:' URI scheme.
  --parameters: list # List of application parameters with overridden values from their default values specified in the application manifest. — item shape: {Key: string, Value: string}
  --rolling-upgrade-mode: string@rolling-upgrade-mode-completer # The mode used to monitor health during a rolling upgrade. The values are UnmonitoredAuto, UnmonitoredManual, and Monitored. (default: UnmonitoredAuto)
  --sort-order: string@sort-order-completer # Defines the order in which an upgrade proceeds through the cluster. (default: Default)
  target_application_type_version: string # The target application type version (found in the application manifest) for the application upgrade.
  upgrade_kind: string@upgrade-kind-completer-1 # The kind of upgrade out of the following possible values. (default: Rolling)
  --upgrade-replica-set-check-timeout-in-seconds: int # The maximum amount of time to block processing of an upgrade domain and prevent loss of availability when there are unexpected issues. When this timeout expires, processing of the upgrade domain will proceed regardless of availability loss issues. The timeout is reset at the start of each upgrade domain. Valid values are between 0 and 42949672925 inclusive. (unsigned 32-bit integer). (format: int64, default: 42949672925)
]: any -> any {
  $in | http-request {
    method: post
    path: "/Applications/{applicationId}/$/Upgrade"
    path_params: [{name: applicationId, var: application_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: timeout, var: timeout}]
    body: {content_type: "application/json", kind: json, fields: [{name: ApplicationHealthPolicy, var: application_health_policy}, {name: ForceRestart, var: force_restart}, {name: MonitoringPolicy, var: monitoring_policy}, {name: Name, var: name}, {name: Parameters, var: parameters}, {name: RollingUpgradeMode, var: rolling_upgrade_mode}, {name: SortOrder, var: sort_order}, {name: TargetApplicationTypeVersion, var: target_application_type_version}, {name: UpgradeKind, var: upgrade_kind}, {name: UpgradeReplicaSetCheckTimeoutInSeconds, var: upgrade_replica_set_check_timeout_in_seconds}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, api_version: $api_version, timeout: $timeout, application_health_policy: $application_health_policy, force_restart: $force_restart, monitoring_policy: $monitoring_policy, name: $name, parameters: $parameters, rolling_upgrade_mode: $rolling_upgrade_mode, sort_order: $sort_order, target_application_type_version: $target_application_type_version, upgrade_kind: $upgrade_kind, upgrade_replica_set_check_timeout_in_seconds: $upgrade_replica_set_check_timeout_in_seconds
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the list of backups available for the specified backed up entity at the specified backup location.
#
# POST /BackupRestore/$/GetBackups
# Returns: record<ContinuationToken: string, Items: table<ApplicationName: string, BackupChainId: string, BackupId: string, BackupLocation: string, BackupType: string, CreationTimeUtc: string, EpochOfLastBackupRecord: record, FailureError: record, LsnOfLastBackupRecord: string, PartitionInformation: record, ServiceManifestVersion: string, ServiceName: string>>
# operationId: GetBackupsFromBackupLocation
export def "get-backups-from-backup-location" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --continuation-token: string # The continuation token parameter is used to obtain next set of results. A continuation token with a non-empty value is included in the response of the API when the results from the system do not fit in a single response. When this value is passed to the next API call, the API returns next set of results. If there are no further results, then the continuation token does not contain a value. The value of this parameter should not be URL encoded.
  --max-results: int # The maximum number of results to be returned as part of the paged queries. This parameter defines the upper bound on the number of results returned. The results returned can be less than the specified maximum results if they do not fit in the message as per the max message size restrictions defined in the configuration. If this parameter is zero or not specified, the paged query includes as many results as possible that fit in the return message. (format: int64, default: 0)
  backup_entity: any # Describes the Service Fabric entity that is configured for backup. — shape: {EntityKind: "Invalid"|"Partition"|"Service"|"Application"}
  --end-date-time-filter: string # Specifies the end date time in ISO8601 till which to enumerate backups. If not specified, backups are enumerated till the end. (format: date-time)
  --latest: oneof<nothing, bool> # If specified as true, gets the most recent backup (within the specified time range) for every partition under the specified backup entity. (default: false)
  --start-date-time-filter: string # Specifies the start date time in ISO8601 from which to enumerate backups. If not specified, backups are enumerated from the beginning. (format: date-time)
  storage: any # Describes the parameters for the backup storage. — shape: {FriendlyName?: string, StorageKind: "Invalid"|"FileShare"|"AzureBlobStore"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/BackupRestore/$/GetBackups"
    query: [{name: api-version, var: api_version, required: true, default: "6.4"}, {name: timeout, var: timeout}, {name: ContinuationToken, var: continuation_token}, {name: MaxResults, var: max_results}]
    body: {content_type: "application/json", kind: json, fields: [{name: BackupEntity, var: backup_entity}, {name: EndDateTimeFilter, var: end_date_time_filter}, {name: Latest, var: latest}, {name: StartDateTimeFilter, var: start_date_time_filter}, {name: Storage, var: storage}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, timeout: $timeout, continuation_token: $continuation_token, max_results: $max_results, backup_entity: $backup_entity, end_date_time_filter: $end_date_time_filter, latest: $latest, start_date_time_filter: $start_date_time_filter, storage: $storage
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all the backup policies configured.
#
# GET /BackupRestore/BackupPolicies
# Returns: record<ContinuationToken: string, Items: table<AutoRestoreOnDataLoss: bool, MaxIncrementalBackups: int, Name: string, RetentionPolicy: record, Schedule: record, Storage: record>>
# operationId: GetBackupPolicyList
export def "get-backup-policy-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.4)
  --continuation-token: string # The continuation token parameter is used to obtain next set of results. A continuation token with a non-empty value is included in the response of the API when the results from the system do not fit in a single response. When this value is passed to the next API call, the API returns next set of results. If there are no further results, then the continuation token does not contain a value. The value of this parameter should not be URL encoded.
  --max-results: int # The maximum number of results to be returned as part of the paged queries. This parameter defines the upper bound on the number of results returned. The results returned can be less than the specified maximum results if they do not fit in the message as per the max message size restrictions defined in the configuration. If this parameter is zero or not specified, the paged query includes as many results as possible that fit in the return message. (format: int64, default: 0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/BackupRestore/BackupPolicies"
    query: [{name: api-version, var: api_version, required: true, default: "6.4"}, {name: ContinuationToken, var: continuation_token}, {name: MaxResults, var: max_results}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, continuation_token: $continuation_token, max_results: $max_results, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a backup policy.
#
# POST /BackupRestore/BackupPolicies/$/Create
# operationId: CreateBackupPolicy
export def "create-backup-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --auto-restore-on-data-loss: oneof<nothing, bool> # Specifies whether to trigger restore automatically using the latest available backup in case the partition experiences a data loss event.
  max_incremental_backups: int # Defines the maximum number of incremental backups to be taken between two full backups. This is just the upper limit. A full backup may be taken before specified number of incremental backups are completed in one of the following conditions - The replica has never taken a full backup since it has become primary, - Some of the log records since the last backup has been truncated, or - Replica passed the MaxAccumulatedBackupLogSizeInMB limit.
  name: string # The unique name identifying this backup policy.
  --retention-policy: any # Describes the retention policy configured. — shape: {RetentionPolicyType: "Basic"|"Invalid"}
  schedule: any # Describes the backup schedule parameters. — shape: {ScheduleKind: "Invalid"|"TimeBased"|"FrequencyBased"}
  storage: any # Describes the parameters for the backup storage. — shape: {FriendlyName?: string, StorageKind: "Invalid"|"FileShare"|"AzureBlobStore"}
]: any -> any {
  $in | http-request {
    method: post
    path: "/BackupRestore/BackupPolicies/$/Create"
    query: [{name: api-version, var: api_version, required: true, default: "6.4"}, {name: timeout, var: timeout}]
    body: {content_type: "application/json", kind: json, fields: [{name: AutoRestoreOnDataLoss, var: auto_restore_on_data_loss, required: true}, {name: MaxIncrementalBackups, var: max_incremental_backups}, {name: Name, var: name}, {name: RetentionPolicy, var: retention_policy}, {name: Schedule, var: schedule}, {name: Storage, var: storage}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    api_version: $api_version, timeout: $timeout, auto_restore_on_data_loss: $auto_restore_on_data_loss, max_incremental_backups: $max_incremental_backups, name: $name, retention_policy: $retention_policy, schedule: $schedule, storage: $storage
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a particular backup policy by name.
#
# GET /BackupRestore/BackupPolicies/{backupPolicyName}
# Returns: record<AutoRestoreOnDataLoss: bool, MaxIncrementalBackups: int, Name: string, RetentionPolicy: record<RetentionPolicyType: string>, Schedule: record<ScheduleKind: string>, Storage: record<FriendlyName: string, StorageKind: string>>
# operationId: GetBackupPolicyByName
export def "get-backup-policy-by-name" [
  backup_policy_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/BackupRestore/BackupPolicies/{backupPolicyName}"
    path_params: [{name: backupPolicyName, var: backup_policy_name}]
    query: [{name: api-version, var: api_version, required: true, default: "6.4"}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    backup_policy_name: $backup_policy_name, api_version: $api_version, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the backup policy.
#
# POST /BackupRestore/BackupPolicies/{backupPolicyName}/$/Delete
# operationId: DeleteBackupPolicy
export def "delete-backup-policy" [
  backup_policy_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> any {
  http-request {
    method: post
    path: "/BackupRestore/BackupPolicies/{backupPolicyName}/$/Delete"
    path_params: [{name: backupPolicyName, var: backup_policy_name}]
    query: [{name: api-version, var: api_version, required: true, default: "6.4"}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    backup_policy_name: $backup_policy_name, api_version: $api_version, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the list of backup entities that are associated with this policy.
#
# GET /BackupRestore/BackupPolicies/{backupPolicyName}/$/GetBackupEnabledEntities
# Returns: record<ContinuationToken: string, Items: table<EntityKind: string>>
# operationId: GetAllEntitiesBackedUpByPolicy
export def "get-all-entities-backed-up-by-policy" [
  backup_policy_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.4)
  --continuation-token: string # The continuation token parameter is used to obtain next set of results. A continuation token with a non-empty value is included in the response of the API when the results from the system do not fit in a single response. When this value is passed to the next API call, the API returns next set of results. If there are no further results, then the continuation token does not contain a value. The value of this parameter should not be URL encoded.
  --max-results: int # The maximum number of results to be returned as part of the paged queries. This parameter defines the upper bound on the number of results returned. The results returned can be less than the specified maximum results if they do not fit in the message as per the max message size restrictions defined in the configuration. If this parameter is zero or not specified, the paged query includes as many results as possible that fit in the return message. (format: int64, default: 0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/BackupRestore/BackupPolicies/{backupPolicyName}/$/GetBackupEnabledEntities"
    path_params: [{name: backupPolicyName, var: backup_policy_name}]
    query: [{name: api-version, var: api_version, required: true, default: "6.4"}, {name: ContinuationToken, var: continuation_token}, {name: MaxResults, var: max_results}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    backup_policy_name: $backup_policy_name, api_version: $api_version, continuation_token: $continuation_token, max_results: $max_results, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the backup policy.
#
# POST /BackupRestore/BackupPolicies/{backupPolicyName}/$/Update
# operationId: UpdateBackupPolicy
export def "update-backup-policy" [
  backup_policy_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --auto-restore-on-data-loss: oneof<nothing, bool> # Specifies whether to trigger restore automatically using the latest available backup in case the partition experiences a data loss event.
  max_incremental_backups: int # Defines the maximum number of incremental backups to be taken between two full backups. This is just the upper limit. A full backup may be taken before specified number of incremental backups are completed in one of the following conditions - The replica has never taken a full backup since it has become primary, - Some of the log records since the last backup has been truncated, or - Replica passed the MaxAccumulatedBackupLogSizeInMB limit.
  name: string # The unique name identifying this backup policy.
  --retention-policy: any # Describes the retention policy configured. — shape: {RetentionPolicyType: "Basic"|"Invalid"}
  schedule: any # Describes the backup schedule parameters. — shape: {ScheduleKind: "Invalid"|"TimeBased"|"FrequencyBased"}
  storage: any # Describes the parameters for the backup storage. — shape: {FriendlyName?: string, StorageKind: "Invalid"|"FileShare"|"AzureBlobStore"}
]: any -> any {
  $in | http-request {
    method: post
    path: "/BackupRestore/BackupPolicies/{backupPolicyName}/$/Update"
    path_params: [{name: backupPolicyName, var: backup_policy_name}]
    query: [{name: api-version, var: api_version, required: true, default: "6.4"}, {name: timeout, var: timeout}]
    body: {content_type: "application/json", kind: json, fields: [{name: AutoRestoreOnDataLoss, var: auto_restore_on_data_loss, required: true}, {name: MaxIncrementalBackups, var: max_incremental_backups}, {name: Name, var: name}, {name: RetentionPolicy, var: retention_policy}, {name: Schedule, var: schedule}, {name: Storage, var: storage}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    backup_policy_name: $backup_policy_name, api_version: $api_version, timeout: $timeout, auto_restore_on_data_loss: $auto_restore_on_data_loss, max_incremental_backups: $max_incremental_backups, name: $name, retention_policy: $retention_policy, schedule: $schedule, storage: $storage
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the list of compose deployments created in the Service Fabric cluster.
#
# GET /ComposeDeployments
# Returns: record<ContinuationToken: string, Items: table<ApplicationName: string, Name: string, Status: string, StatusDetails: string>>
# operationId: GetComposeDeploymentStatusList
export def "get-compose-deployment-status-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-4 # The version of the API. This parameter is required and its value must be '"6.0-preview'. (required, default: 6.0-preview)
  --continuation-token: string # The continuation token parameter is used to obtain next set of results. A continuation token with a non-empty value is included in the response of the API when the results from the system do not fit in a single response. When this value is passed to the next API call, the API returns next set of results. If there are no further results, then the continuation token does not contain a value. The value of this parameter should not be URL encoded.
  --max-results: int # The maximum number of results to be returned as part of the paged queries. This parameter defines the upper bound on the number of results returned. The results returned can be less than the specified maximum results if they do not fit in the message as per the max message size restrictions defined in the configuration. If this parameter is zero or not specified, the paged query includes as many results as possible that fit in the return message. (format: int64, default: 0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/ComposeDeployments"
    query: [{name: api-version, var: api_version, required: true, default: "6.0-preview"}, {name: ContinuationToken, var: continuation_token}, {name: MaxResults, var: max_results}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, continuation_token: $continuation_token, max_results: $max_results, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a Service Fabric compose deployment.
#
# PUT /ComposeDeployments/$/Create
# operationId: CreateComposeDeployment
export def "create-compose-deployment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-4 # The version of the API. This parameter is required and its value must be '"6.0-preview'. (required, default: 6.0-preview)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  compose_file_content: string # The content of the compose file that describes the deployment to create.
  deployment_name: string # The name of the deployment.
  --registry-credential: any # Credential information to connect to container registry. — shape: {PasswordEncrypted?: bool, RegistryPassword?: string, RegistryUserName?: string}
]: any -> any {
  $in | http-request {
    method: put
    path: "/ComposeDeployments/$/Create"
    query: [{name: api-version, var: api_version, required: true, default: "6.0-preview"}, {name: timeout, var: timeout}]
    body: {content_type: "application/json", kind: json, fields: [{name: ComposeFileContent, var: compose_file_content}, {name: DeploymentName, var: deployment_name}, {name: RegistryCredential, var: registry_credential}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    api_version: $api_version, timeout: $timeout, compose_file_content: $compose_file_content, deployment_name: $deployment_name, registry_credential: $registry_credential
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about a Service Fabric compose deployment.
#
# GET /ComposeDeployments/{deploymentName}
# Returns: record<ApplicationName: string, Name: string, Status: string, StatusDetails: string>
# operationId: GetComposeDeploymentStatus
export def "get-compose-deployment-status" [
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-4 # The version of the API. This parameter is required and its value must be '"6.0-preview'. (required, default: 6.0-preview)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/ComposeDeployments/{deploymentName}"
    path_params: [{name: deploymentName, var: deployment_name}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0-preview"}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    deployment_name: $deployment_name, api_version: $api_version, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an existing Service Fabric compose deployment from cluster.
#
# POST /ComposeDeployments/{deploymentName}/$/Delete
# operationId: RemoveComposeDeployment
export def "remove-compose-deployment" [
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-4 # The version of the API. This parameter is required and its value must be '"6.0-preview'. (required, default: 6.0-preview)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> any {
  http-request {
    method: post
    path: "/ComposeDeployments/{deploymentName}/$/Delete"
    path_params: [{name: deploymentName, var: deployment_name}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0-preview"}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    deployment_name: $deployment_name, api_version: $api_version, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets details for the latest upgrade performed on this Service Fabric compose deployment.
#
# GET /ComposeDeployments/{deploymentName}/$/GetUpgradeProgress
# Returns: record<ApplicationHealthPolicy: record<ConsiderWarningAsError: bool, DefaultServiceTypeHealthPolicy: record<MaxPercentUnhealthyPartitionsPerService: int, MaxPercentUnhealthyReplicasPerPartition: int, MaxPercentUnhealthyServices: int>, MaxPercentUnhealthyDeployedApplications: int, ServiceTypeHealthPolicyMap: list<record>>, ApplicationName: string, ApplicationUnhealthyEvaluations: table<HealthEvaluation: record>, ApplicationUpgradeStatusDetails: string, CurrentUpgradeDomainDuration: string, CurrentUpgradeDomainProgress: record<DomainName: string, NodeUpgradeProgressList: list<record>>, DeploymentName: string, FailureReason: string, FailureTimestampUtc: string, ForceRestart: bool, MonitoringPolicy: record<FailureAction: string, HealthCheckRetryTimeoutInMilliseconds: string, HealthCheckStableDurationInMilliseconds: string, HealthCheckWaitDurationInMilliseconds: string, UpgradeDomainTimeoutInMilliseconds: string, UpgradeTimeoutInMilliseconds: string>, RollingUpgradeMode: string, StartTimestampUtc: string, TargetApplicationTypeVersion: string, UpgradeDomainProgressAtFailure: record<DomainName: string, NodeUpgradeProgressList: list<record>>, UpgradeDuration: string, UpgradeKind: string, UpgradeReplicaSetCheckTimeoutInSeconds: int, UpgradeState: string, UpgradeStatusDetails: string>
# operationId: GetComposeDeploymentUpgradeProgress
export def "get-compose-deployment-upgrade-progress" [
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-4 # The version of the API. This parameter is required and its value must be '"6.0-preview'. (required, default: 6.0-preview)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/ComposeDeployments/{deploymentName}/$/GetUpgradeProgress"
    path_params: [{name: deploymentName, var: deployment_name}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0-preview"}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    deployment_name: $deployment_name, api_version: $api_version, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts rolling back a compose deployment upgrade in the Service Fabric cluster.
#
# POST /ComposeDeployments/{deploymentName}/$/RollbackUpgrade
# operationId: StartRollbackComposeDeploymentUpgrade
export def "start-rollback-compose-deployment-upgrade" [
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (required, default: 6.4-preview)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> any {
  http-request {
    method: post
    path: "/ComposeDeployments/{deploymentName}/$/RollbackUpgrade"
    path_params: [{name: deploymentName, var: deployment_name}]
    query: [{name: api-version, var: api_version, required: true, default: "6.4-preview"}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    deployment_name: $deployment_name, api_version: $api_version, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts upgrading a compose deployment in the Service Fabric cluster.
#
# POST /ComposeDeployments/{deploymentName}/$/Upgrade
# operationId: StartComposeDeploymentUpgrade
export def "start-compose-deployment-upgrade" [
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-4 # The version of the API. This parameter is required and its value must be '"6.0-preview'. (required, default: 6.0-preview)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --application-health-policy: any # Defines a health policy used to evaluate the health of an application or one of its children entities. — shape: {ConsiderWarningAsError?: bool, DefaultServiceTypeHealthPolicy?: any, MaxPercentUnhealthyDeployedApplications?: int, ServiceTypeHealthPolicyMap?: list}
  compose_file_content: string # The content of the compose file that describes the deployment to create.
  --body-deployment-name: string # The name of the deployment. (spec name: DeploymentName)
  --force-restart: oneof<nothing, bool> # If true, then processes are forcefully restarted during upgrade even when the code version has not changed (the upgrade only changes configuration or data). (default: false)
  --monitoring-policy: any # Describes the parameters for monitoring an upgrade in Monitored mode. — shape: {FailureAction?: "Invalid"|"Rollback"|"Manual", HealthCheckRetryTimeoutInMilliseconds?: string, HealthCheckStableDurationInMilliseconds?: string, HealthCheckWaitDurationInMilliseconds?: string, UpgradeDomainTimeoutInMilliseconds?: string, UpgradeTimeoutInMilliseconds?: string}
  --registry-credential: any # Credential information to connect to container registry. — shape: {PasswordEncrypted?: bool, RegistryPassword?: string, RegistryUserName?: string}
  --rolling-upgrade-mode: string@rolling-upgrade-mode-completer # The mode used to monitor health during a rolling upgrade. The values are UnmonitoredAuto, UnmonitoredManual, and Monitored. (default: UnmonitoredAuto)
  upgrade_kind: string@upgrade-kind-completer-1 # The kind of upgrade out of the following possible values. (default: Rolling)
  --upgrade-replica-set-check-timeout-in-seconds: int # The maximum amount of time to block processing of an upgrade domain and prevent loss of availability when there are unexpected issues. When this timeout expires, processing of the upgrade domain will proceed regardless of availability loss issues. The timeout is reset at the start of each upgrade domain. Valid values are between 0 and 42949672925 inclusive. (unsigned 32-bit integer). (format: int64, default: 42949672925)
]: any -> any {
  $in | http-request {
    method: post
    path: "/ComposeDeployments/{deploymentName}/$/Upgrade"
    path_params: [{name: deploymentName, var: deployment_name}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0-preview"}, {name: timeout, var: timeout}]
    body: {content_type: "application/json", kind: json, fields: [{name: ApplicationHealthPolicy, var: application_health_policy}, {name: ComposeFileContent, var: compose_file_content}, {name: DeploymentName, var: body_deployment_name, required: true}, {name: ForceRestart, var: force_restart}, {name: MonitoringPolicy, var: monitoring_policy}, {name: RegistryCredential, var: registry_credential}, {name: RollingUpgradeMode, var: rolling_upgrade_mode}, {name: UpgradeKind, var: upgrade_kind}, {name: UpgradeReplicaSetCheckTimeoutInSeconds, var: upgrade_replica_set_check_timeout_in_seconds}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    deployment_name: $deployment_name, api_version: $api_version, timeout: $timeout, application_health_policy: $application_health_policy, compose_file_content: $compose_file_content, body_deployment_name: $body_deployment_name, force_restart: $force_restart, monitoring_policy: $monitoring_policy, registry_credential: $registry_credential, rolling_upgrade_mode: $rolling_upgrade_mode, upgrade_kind: $upgrade_kind, upgrade_replica_set_check_timeout_in_seconds: $upgrade_replica_set_check_timeout_in_seconds
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all Applications-related events.
#
# GET /EventsStore/Applications/Events
# Returns: table<ApplicationId: string, Category: string, EventInstanceId: string, HasCorrelatedEvents: bool, Kind: string, TimeStamp: string>
# operationId: GetApplicationsEventList
export def "get-applications-event-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --start-time-utc: string # The start time of a lookup query in ISO UTC yyyy-MM-ddTHH:mm:ssZ. (required)
  --end-time-utc: string # The end time of a lookup query in ISO UTC yyyy-MM-ddTHH:mm:ssZ. (required)
  --events-types-filter: string # This is a comma separated string specifying the types of FabricEvents that should only be included in the response.
  --exclude-analysis-events: oneof<nothing, bool> # This param disables the retrieval of AnalysisEvents if true is passed.
  --skip-correlation-lookup: oneof<nothing, bool> # This param disables the search of CorrelatedEvents information if true is passed. otherwise the CorrelationEvents get processed and HasCorrelatedEvents field in every FabricEvent gets populated.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/EventsStore/Applications/Events"
    query: [{name: api-version, var: api_version, required: true, default: "6.4"}, {name: timeout, var: timeout}, {name: StartTimeUtc, var: start_time_utc, required: true}, {name: EndTimeUtc, var: end_time_utc, required: true}, {name: EventsTypesFilter, var: events_types_filter}, {name: ExcludeAnalysisEvents, var: exclude_analysis_events}, {name: SkipCorrelationLookup, var: skip_correlation_lookup}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, timeout: $timeout, start_time_utc: $start_time_utc, end_time_utc: $end_time_utc, events_types_filter: $events_types_filter, exclude_analysis_events: $exclude_analysis_events, skip_correlation_lookup: $skip_correlation_lookup
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets an Application-related events.
#
# GET /EventsStore/Applications/{applicationId}/$/Events
# Returns: table<ApplicationId: string, Category: string, EventInstanceId: string, HasCorrelatedEvents: bool, Kind: string, TimeStamp: string>
# operationId: GetApplicationEventList
export def "get-application-event-list" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --start-time-utc: string # The start time of a lookup query in ISO UTC yyyy-MM-ddTHH:mm:ssZ. (required)
  --end-time-utc: string # The end time of a lookup query in ISO UTC yyyy-MM-ddTHH:mm:ssZ. (required)
  --events-types-filter: string # This is a comma separated string specifying the types of FabricEvents that should only be included in the response.
  --exclude-analysis-events: oneof<nothing, bool> # This param disables the retrieval of AnalysisEvents if true is passed.
  --skip-correlation-lookup: oneof<nothing, bool> # This param disables the search of CorrelatedEvents information if true is passed. otherwise the CorrelationEvents get processed and HasCorrelatedEvents field in every FabricEvent gets populated.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/EventsStore/Applications/{applicationId}/$/Events"
    path_params: [{name: applicationId, var: application_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.4"}, {name: timeout, var: timeout}, {name: StartTimeUtc, var: start_time_utc, required: true}, {name: EndTimeUtc, var: end_time_utc, required: true}, {name: EventsTypesFilter, var: events_types_filter}, {name: ExcludeAnalysisEvents, var: exclude_analysis_events}, {name: SkipCorrelationLookup, var: skip_correlation_lookup}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, api_version: $api_version, timeout: $timeout, start_time_utc: $start_time_utc, end_time_utc: $end_time_utc, events_types_filter: $events_types_filter, exclude_analysis_events: $exclude_analysis_events, skip_correlation_lookup: $skip_correlation_lookup
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all Cluster-related events.
#
# GET /EventsStore/Cluster/Events
# Returns: table<Category: string, EventInstanceId: string, HasCorrelatedEvents: bool, Kind: string, TimeStamp: string>
# operationId: GetClusterEventList
export def "get-cluster-event-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --start-time-utc: string # The start time of a lookup query in ISO UTC yyyy-MM-ddTHH:mm:ssZ. (required)
  --end-time-utc: string # The end time of a lookup query in ISO UTC yyyy-MM-ddTHH:mm:ssZ. (required)
  --events-types-filter: string # This is a comma separated string specifying the types of FabricEvents that should only be included in the response.
  --exclude-analysis-events: oneof<nothing, bool> # This param disables the retrieval of AnalysisEvents if true is passed.
  --skip-correlation-lookup: oneof<nothing, bool> # This param disables the search of CorrelatedEvents information if true is passed. otherwise the CorrelationEvents get processed and HasCorrelatedEvents field in every FabricEvent gets populated.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/EventsStore/Cluster/Events"
    query: [{name: api-version, var: api_version, required: true, default: "6.4"}, {name: timeout, var: timeout}, {name: StartTimeUtc, var: start_time_utc, required: true}, {name: EndTimeUtc, var: end_time_utc, required: true}, {name: EventsTypesFilter, var: events_types_filter}, {name: ExcludeAnalysisEvents, var: exclude_analysis_events}, {name: SkipCorrelationLookup, var: skip_correlation_lookup}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, timeout: $timeout, start_time_utc: $start_time_utc, end_time_utc: $end_time_utc, events_types_filter: $events_types_filter, exclude_analysis_events: $exclude_analysis_events, skip_correlation_lookup: $skip_correlation_lookup
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all Containers-related events.
#
# GET /EventsStore/Containers/Events
# Returns: table<Category: string, EventInstanceId: string, HasCorrelatedEvents: bool, Kind: string, TimeStamp: string>
# operationId: GetContainersEventList
export def "get-containers-event-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-6 # The version of the API. This parameter is required and its value must be '6.2-preview'. (required, default: 6.2-preview)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --start-time-utc: string # The start time of a lookup query in ISO UTC yyyy-MM-ddTHH:mm:ssZ. (required)
  --end-time-utc: string # The end time of a lookup query in ISO UTC yyyy-MM-ddTHH:mm:ssZ. (required)
  --events-types-filter: string # This is a comma separated string specifying the types of FabricEvents that should only be included in the response.
  --exclude-analysis-events: oneof<nothing, bool> # This param disables the retrieval of AnalysisEvents if true is passed.
  --skip-correlation-lookup: oneof<nothing, bool> # This param disables the search of CorrelatedEvents information if true is passed. otherwise the CorrelationEvents get processed and HasCorrelatedEvents field in every FabricEvent gets populated.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/EventsStore/Containers/Events"
    query: [{name: api-version, var: api_version, required: true, default: "6.2-preview"}, {name: timeout, var: timeout}, {name: StartTimeUtc, var: start_time_utc, required: true}, {name: EndTimeUtc, var: end_time_utc, required: true}, {name: EventsTypesFilter, var: events_types_filter}, {name: ExcludeAnalysisEvents, var: exclude_analysis_events}, {name: SkipCorrelationLookup, var: skip_correlation_lookup}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, timeout: $timeout, start_time_utc: $start_time_utc, end_time_utc: $end_time_utc, events_types_filter: $events_types_filter, exclude_analysis_events: $exclude_analysis_events, skip_correlation_lookup: $skip_correlation_lookup
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all correlated events for a given event.
#
# GET /EventsStore/CorrelatedEvents/{eventInstanceId}/$/Events
# Returns: table<Category: string, EventInstanceId: string, HasCorrelatedEvents: bool, Kind: string, TimeStamp: string>
# operationId: GetCorrelatedEventList
export def "get-correlated-event-list" [
  event_instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/EventsStore/CorrelatedEvents/{eventInstanceId}/$/Events"
    path_params: [{name: eventInstanceId, var: event_instance_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.4"}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    event_instance_id: $event_instance_id, api_version: $api_version, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all Nodes-related Events.
#
# GET /EventsStore/Nodes/Events
# Returns: table<NodeName: string, Category: string, EventInstanceId: string, HasCorrelatedEvents: bool, Kind: string, TimeStamp: string>
# operationId: GetNodesEventList
export def "get-nodes-event-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --start-time-utc: string # The start time of a lookup query in ISO UTC yyyy-MM-ddTHH:mm:ssZ. (required)
  --end-time-utc: string # The end time of a lookup query in ISO UTC yyyy-MM-ddTHH:mm:ssZ. (required)
  --events-types-filter: string # This is a comma separated string specifying the types of FabricEvents that should only be included in the response.
  --exclude-analysis-events: oneof<nothing, bool> # This param disables the retrieval of AnalysisEvents if true is passed.
  --skip-correlation-lookup: oneof<nothing, bool> # This param disables the search of CorrelatedEvents information if true is passed. otherwise the CorrelationEvents get processed and HasCorrelatedEvents field in every FabricEvent gets populated.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/EventsStore/Nodes/Events"
    query: [{name: api-version, var: api_version, required: true, default: "6.4"}, {name: timeout, var: timeout}, {name: StartTimeUtc, var: start_time_utc, required: true}, {name: EndTimeUtc, var: end_time_utc, required: true}, {name: EventsTypesFilter, var: events_types_filter}, {name: ExcludeAnalysisEvents, var: exclude_analysis_events}, {name: SkipCorrelationLookup, var: skip_correlation_lookup}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, timeout: $timeout, start_time_utc: $start_time_utc, end_time_utc: $end_time_utc, events_types_filter: $events_types_filter, exclude_analysis_events: $exclude_analysis_events, skip_correlation_lookup: $skip_correlation_lookup
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a Node-related events.
#
# GET /EventsStore/Nodes/{nodeName}/$/Events
# Returns: table<NodeName: string, Category: string, EventInstanceId: string, HasCorrelatedEvents: bool, Kind: string, TimeStamp: string>
# operationId: GetNodeEventList
export def "get-node-event-list" [
  node_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --start-time-utc: string # The start time of a lookup query in ISO UTC yyyy-MM-ddTHH:mm:ssZ. (required)
  --end-time-utc: string # The end time of a lookup query in ISO UTC yyyy-MM-ddTHH:mm:ssZ. (required)
  --events-types-filter: string # This is a comma separated string specifying the types of FabricEvents that should only be included in the response.
  --exclude-analysis-events: oneof<nothing, bool> # This param disables the retrieval of AnalysisEvents if true is passed.
  --skip-correlation-lookup: oneof<nothing, bool> # This param disables the search of CorrelatedEvents information if true is passed. otherwise the CorrelationEvents get processed and HasCorrelatedEvents field in every FabricEvent gets populated.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/EventsStore/Nodes/{nodeName}/$/Events"
    path_params: [{name: nodeName, var: node_name}]
    query: [{name: api-version, var: api_version, required: true, default: "6.4"}, {name: timeout, var: timeout}, {name: StartTimeUtc, var: start_time_utc, required: true}, {name: EndTimeUtc, var: end_time_utc, required: true}, {name: EventsTypesFilter, var: events_types_filter}, {name: ExcludeAnalysisEvents, var: exclude_analysis_events}, {name: SkipCorrelationLookup, var: skip_correlation_lookup}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    node_name: $node_name, api_version: $api_version, timeout: $timeout, start_time_utc: $start_time_utc, end_time_utc: $end_time_utc, events_types_filter: $events_types_filter, exclude_analysis_events: $exclude_analysis_events, skip_correlation_lookup: $skip_correlation_lookup
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all Partitions-related events.
#
# GET /EventsStore/Partitions/Events
# Returns: table<PartitionId: string, Category: string, EventInstanceId: string, HasCorrelatedEvents: bool, Kind: string, TimeStamp: string>
# operationId: GetPartitionsEventList
export def "get-partitions-event-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --start-time-utc: string # The start time of a lookup query in ISO UTC yyyy-MM-ddTHH:mm:ssZ. (required)
  --end-time-utc: string # The end time of a lookup query in ISO UTC yyyy-MM-ddTHH:mm:ssZ. (required)
  --events-types-filter: string # This is a comma separated string specifying the types of FabricEvents that should only be included in the response.
  --exclude-analysis-events: oneof<nothing, bool> # This param disables the retrieval of AnalysisEvents if true is passed.
  --skip-correlation-lookup: oneof<nothing, bool> # This param disables the search of CorrelatedEvents information if true is passed. otherwise the CorrelationEvents get processed and HasCorrelatedEvents field in every FabricEvent gets populated.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/EventsStore/Partitions/Events"
    query: [{name: api-version, var: api_version, required: true, default: "6.4"}, {name: timeout, var: timeout}, {name: StartTimeUtc, var: start_time_utc, required: true}, {name: EndTimeUtc, var: end_time_utc, required: true}, {name: EventsTypesFilter, var: events_types_filter}, {name: ExcludeAnalysisEvents, var: exclude_analysis_events}, {name: SkipCorrelationLookup, var: skip_correlation_lookup}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, timeout: $timeout, start_time_utc: $start_time_utc, end_time_utc: $end_time_utc, events_types_filter: $events_types_filter, exclude_analysis_events: $exclude_analysis_events, skip_correlation_lookup: $skip_correlation_lookup
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a Partition-related events.
#
# GET /EventsStore/Partitions/{partitionId}/$/Events
# Returns: table<PartitionId: string, Category: string, EventInstanceId: string, HasCorrelatedEvents: bool, Kind: string, TimeStamp: string>
# operationId: GetPartitionEventList
export def "get-partition-event-list" [
  partition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --start-time-utc: string # The start time of a lookup query in ISO UTC yyyy-MM-ddTHH:mm:ssZ. (required)
  --end-time-utc: string # The end time of a lookup query in ISO UTC yyyy-MM-ddTHH:mm:ssZ. (required)
  --events-types-filter: string # This is a comma separated string specifying the types of FabricEvents that should only be included in the response.
  --exclude-analysis-events: oneof<nothing, bool> # This param disables the retrieval of AnalysisEvents if true is passed.
  --skip-correlation-lookup: oneof<nothing, bool> # This param disables the search of CorrelatedEvents information if true is passed. otherwise the CorrelationEvents get processed and HasCorrelatedEvents field in every FabricEvent gets populated.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/EventsStore/Partitions/{partitionId}/$/Events"
    path_params: [{name: partitionId, var: partition_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.4"}, {name: timeout, var: timeout}, {name: StartTimeUtc, var: start_time_utc, required: true}, {name: EndTimeUtc, var: end_time_utc, required: true}, {name: EventsTypesFilter, var: events_types_filter}, {name: ExcludeAnalysisEvents, var: exclude_analysis_events}, {name: SkipCorrelationLookup, var: skip_correlation_lookup}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    partition_id: $partition_id, api_version: $api_version, timeout: $timeout, start_time_utc: $start_time_utc, end_time_utc: $end_time_utc, events_types_filter: $events_types_filter, exclude_analysis_events: $exclude_analysis_events, skip_correlation_lookup: $skip_correlation_lookup
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all Replicas-related events for a Partition.
#
# GET /EventsStore/Partitions/{partitionId}/$/Replicas/Events
# Returns: table<PartitionId: string, ReplicaId: int, Category: string, EventInstanceId: string, HasCorrelatedEvents: bool, Kind: string, TimeStamp: string>
# operationId: GetPartitionReplicasEventList
export def "get-partition-replicas-event-list" [
  partition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --start-time-utc: string # The start time of a lookup query in ISO UTC yyyy-MM-ddTHH:mm:ssZ. (required)
  --end-time-utc: string # The end time of a lookup query in ISO UTC yyyy-MM-ddTHH:mm:ssZ. (required)
  --events-types-filter: string # This is a comma separated string specifying the types of FabricEvents that should only be included in the response.
  --exclude-analysis-events: oneof<nothing, bool> # This param disables the retrieval of AnalysisEvents if true is passed.
  --skip-correlation-lookup: oneof<nothing, bool> # This param disables the search of CorrelatedEvents information if true is passed. otherwise the CorrelationEvents get processed and HasCorrelatedEvents field in every FabricEvent gets populated.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/EventsStore/Partitions/{partitionId}/$/Replicas/Events"
    path_params: [{name: partitionId, var: partition_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.4"}, {name: timeout, var: timeout}, {name: StartTimeUtc, var: start_time_utc, required: true}, {name: EndTimeUtc, var: end_time_utc, required: true}, {name: EventsTypesFilter, var: events_types_filter}, {name: ExcludeAnalysisEvents, var: exclude_analysis_events}, {name: SkipCorrelationLookup, var: skip_correlation_lookup}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    partition_id: $partition_id, api_version: $api_version, timeout: $timeout, start_time_utc: $start_time_utc, end_time_utc: $end_time_utc, events_types_filter: $events_types_filter, exclude_analysis_events: $exclude_analysis_events, skip_correlation_lookup: $skip_correlation_lookup
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a Partition Replica-related events.
#
# GET /EventsStore/Partitions/{partitionId}/$/Replicas/{replicaId}/$/Events
# Returns: table<PartitionId: string, ReplicaId: int, Category: string, EventInstanceId: string, HasCorrelatedEvents: bool, Kind: string, TimeStamp: string>
# operationId: GetPartitionReplicaEventList
export def "get-partition-replica-event-list" [
  partition_id: string
  replica_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --start-time-utc: string # The start time of a lookup query in ISO UTC yyyy-MM-ddTHH:mm:ssZ. (required)
  --end-time-utc: string # The end time of a lookup query in ISO UTC yyyy-MM-ddTHH:mm:ssZ. (required)
  --events-types-filter: string # This is a comma separated string specifying the types of FabricEvents that should only be included in the response.
  --exclude-analysis-events: oneof<nothing, bool> # This param disables the retrieval of AnalysisEvents if true is passed.
  --skip-correlation-lookup: oneof<nothing, bool> # This param disables the search of CorrelatedEvents information if true is passed. otherwise the CorrelationEvents get processed and HasCorrelatedEvents field in every FabricEvent gets populated.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/EventsStore/Partitions/{partitionId}/$/Replicas/{replicaId}/$/Events"
    path_params: [{name: partitionId, var: partition_id}, {name: replicaId, var: replica_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.4"}, {name: timeout, var: timeout}, {name: StartTimeUtc, var: start_time_utc, required: true}, {name: EndTimeUtc, var: end_time_utc, required: true}, {name: EventsTypesFilter, var: events_types_filter}, {name: ExcludeAnalysisEvents, var: exclude_analysis_events}, {name: SkipCorrelationLookup, var: skip_correlation_lookup}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    partition_id: $partition_id, replica_id: $replica_id, api_version: $api_version, timeout: $timeout, start_time_utc: $start_time_utc, end_time_utc: $end_time_utc, events_types_filter: $events_types_filter, exclude_analysis_events: $exclude_analysis_events, skip_correlation_lookup: $skip_correlation_lookup
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all Services-related events.
#
# GET /EventsStore/Services/Events
# Returns: table<ServiceId: string, Category: string, EventInstanceId: string, HasCorrelatedEvents: bool, Kind: string, TimeStamp: string>
# operationId: GetServicesEventList
export def "get-services-event-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --start-time-utc: string # The start time of a lookup query in ISO UTC yyyy-MM-ddTHH:mm:ssZ. (required)
  --end-time-utc: string # The end time of a lookup query in ISO UTC yyyy-MM-ddTHH:mm:ssZ. (required)
  --events-types-filter: string # This is a comma separated string specifying the types of FabricEvents that should only be included in the response.
  --exclude-analysis-events: oneof<nothing, bool> # This param disables the retrieval of AnalysisEvents if true is passed.
  --skip-correlation-lookup: oneof<nothing, bool> # This param disables the search of CorrelatedEvents information if true is passed. otherwise the CorrelationEvents get processed and HasCorrelatedEvents field in every FabricEvent gets populated.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/EventsStore/Services/Events"
    query: [{name: api-version, var: api_version, required: true, default: "6.4"}, {name: timeout, var: timeout}, {name: StartTimeUtc, var: start_time_utc, required: true}, {name: EndTimeUtc, var: end_time_utc, required: true}, {name: EventsTypesFilter, var: events_types_filter}, {name: ExcludeAnalysisEvents, var: exclude_analysis_events}, {name: SkipCorrelationLookup, var: skip_correlation_lookup}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, timeout: $timeout, start_time_utc: $start_time_utc, end_time_utc: $end_time_utc, events_types_filter: $events_types_filter, exclude_analysis_events: $exclude_analysis_events, skip_correlation_lookup: $skip_correlation_lookup
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a Service-related events.
#
# GET /EventsStore/Services/{serviceId}/$/Events
# Returns: table<ServiceId: string, Category: string, EventInstanceId: string, HasCorrelatedEvents: bool, Kind: string, TimeStamp: string>
# operationId: GetServiceEventList
export def "get-service-event-list" [
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --start-time-utc: string # The start time of a lookup query in ISO UTC yyyy-MM-ddTHH:mm:ssZ. (required)
  --end-time-utc: string # The end time of a lookup query in ISO UTC yyyy-MM-ddTHH:mm:ssZ. (required)
  --events-types-filter: string # This is a comma separated string specifying the types of FabricEvents that should only be included in the response.
  --exclude-analysis-events: oneof<nothing, bool> # This param disables the retrieval of AnalysisEvents if true is passed.
  --skip-correlation-lookup: oneof<nothing, bool> # This param disables the search of CorrelatedEvents information if true is passed. otherwise the CorrelationEvents get processed and HasCorrelatedEvents field in every FabricEvent gets populated.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/EventsStore/Services/{serviceId}/$/Events"
    path_params: [{name: serviceId, var: service_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.4"}, {name: timeout, var: timeout}, {name: StartTimeUtc, var: start_time_utc, required: true}, {name: EndTimeUtc, var: end_time_utc, required: true}, {name: EventsTypesFilter, var: events_types_filter}, {name: ExcludeAnalysisEvents, var: exclude_analysis_events}, {name: SkipCorrelationLookup, var: skip_correlation_lookup}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_id: $service_id, api_version: $api_version, timeout: $timeout, start_time_utc: $start_time_utc, end_time_utc: $end_time_utc, events_types_filter: $events_types_filter, exclude_analysis_events: $exclude_analysis_events, skip_correlation_lookup: $skip_correlation_lookup
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of user-induced fault operations filtered by provided input.
#
# GET /Faults/
# Returns: table<OperationId: string, State: string, Type: string>
# operationId: GetFaultOperationList
export def "get-fault-operation-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --type-filter: int # Used to filter on OperationType for user-induced operations. - 65535 - select all - 1 - select PartitionDataLoss. - 2 - select PartitionQuorumLoss. - 4 - select PartitionRestart. - 8 - select NodeTransition. (required, default: 65535)
  --state-filter: int # Used to filter on OperationState's for user-induced operations. - 65535 - select All - 1 - select Running - 2 - select RollingBack - 8 - select Completed - 16 - select Faulted - 32 - select Cancelled - 64 - select ForceCancelled (required, default: 65535)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/Faults/"
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: TypeFilter, var: type_filter, required: true, default: 65535}, {name: StateFilter, var: state_filter, required: true, default: 65535}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, type_filter: $type_filter, state_filter: $state_filter, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancels a user-induced fault operation.
#
# POST /Faults/$/Cancel
# operationId: CancelOperation
export def "cancel-operation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --operation-id: string # A GUID that identifies a call of this API. This is passed into the corresponding GetProgress API (required, format: uuid)
  --force: oneof<nothing, bool> # Indicates whether to gracefully roll back and clean up internal system state modified by executing the user-induced operation. (required, default: false)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> any {
  http-request {
    method: post
    path: "/Faults/$/Cancel"
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: OperationId, var: operation_id, required: true}, {name: Force, var: force, required: true, default: false}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, operation_id: $operation_id, force: $force, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the progress of an operation started using StartNodeTransition.
#
# GET /Faults/Nodes/{nodeName}/$/GetTransitionProgress
# Returns: record<NodeTransitionResult: record<ErrorCode: int, NodeResult: record<NodeInstanceId: string, NodeName: string>>, State: string>
# operationId: GetNodeTransitionProgress
export def "get-node-transition-progress" [
  node_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --operation-id: string # A GUID that identifies a call of this API. This is passed into the corresponding GetProgress API (required, format: uuid)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Faults/Nodes/{nodeName}/$/GetTransitionProgress"
    path_params: [{name: nodeName, var: node_name}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: OperationId, var: operation_id, required: true}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    node_name: $node_name, api_version: $api_version, operation_id: $operation_id, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts or stops a cluster node.
#
# POST /Faults/Nodes/{nodeName}/$/StartTransition/
# operationId: StartNodeTransition
export def "start-node-transition" [
  node_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --operation-id: string # A GUID that identifies a call of this API. This is passed into the corresponding GetProgress API (required, format: uuid)
  --node-transition-type: string@node-transition-type-completer # Indicates the type of transition to perform. NodeTransitionType.Start will start a stopped node. NodeTransitionType.Stop will stop a node that is up. (required)
  --node-instance-id: string # The node instance ID of the target node. This can be determined through GetNodeInfo API. (required)
  --stop-duration-in-seconds: int # The duration, in seconds, to keep the node stopped. The minimum value is 600, the maximum is 14400. After this time expires, the node will automatically come back up. (required, format: int32)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> any {
  http-request {
    method: post
    path: "/Faults/Nodes/{nodeName}/$/StartTransition/"
    path_params: [{name: nodeName, var: node_name}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: OperationId, var: operation_id, required: true}, {name: NodeTransitionType, var: node_transition_type, required: true}, {name: NodeInstanceId, var: node_instance_id, required: true}, {name: StopDurationInSeconds, var: stop_duration_in_seconds, required: true}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    node_name: $node_name, api_version: $api_version, operation_id: $operation_id, node_transition_type: $node_transition_type, node_instance_id: $node_instance_id, stop_duration_in_seconds: $stop_duration_in_seconds, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the progress of a partition data loss operation started using the StartDataLoss API.
#
# GET /Faults/Services/{serviceId}/$/GetPartitions/{partitionId}/$/GetDataLossProgress
# Returns: record<InvokeDataLossResult: record<ErrorCode: int, SelectedPartition: record<PartitionId: string, ServiceName: string>>, State: string>
# operationId: GetDataLossProgress
export def "get-data-loss-progress" [
  service_id: string
  partition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --operation-id: string # A GUID that identifies a call of this API. This is passed into the corresponding GetProgress API (required, format: uuid)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Faults/Services/{serviceId}/$/GetPartitions/{partitionId}/$/GetDataLossProgress"
    path_params: [{name: serviceId, var: service_id}, {name: partitionId, var: partition_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: OperationId, var: operation_id, required: true}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_id: $service_id, partition_id: $partition_id, api_version: $api_version, operation_id: $operation_id, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the progress of a quorum loss operation on a partition started using the StartQuorumLoss API.
#
# GET /Faults/Services/{serviceId}/$/GetPartitions/{partitionId}/$/GetQuorumLossProgress
# Returns: record<InvokeQuorumLossResult: record<ErrorCode: int, SelectedPartition: record<PartitionId: string, ServiceName: string>>, State: string>
# operationId: GetQuorumLossProgress
export def "get-quorum-loss-progress" [
  service_id: string
  partition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --operation-id: string # A GUID that identifies a call of this API. This is passed into the corresponding GetProgress API (required, format: uuid)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Faults/Services/{serviceId}/$/GetPartitions/{partitionId}/$/GetQuorumLossProgress"
    path_params: [{name: serviceId, var: service_id}, {name: partitionId, var: partition_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: OperationId, var: operation_id, required: true}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_id: $service_id, partition_id: $partition_id, api_version: $api_version, operation_id: $operation_id, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the progress of a PartitionRestart operation started using StartPartitionRestart.
#
# GET /Faults/Services/{serviceId}/$/GetPartitions/{partitionId}/$/GetRestartProgress
# Returns: record<RestartPartitionResult: record<ErrorCode: int, SelectedPartition: record<PartitionId: string, ServiceName: string>>, State: string>
# operationId: GetPartitionRestartProgress
export def "get-partition-restart-progress" [
  service_id: string
  partition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --operation-id: string # A GUID that identifies a call of this API. This is passed into the corresponding GetProgress API (required, format: uuid)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Faults/Services/{serviceId}/$/GetPartitions/{partitionId}/$/GetRestartProgress"
    path_params: [{name: serviceId, var: service_id}, {name: partitionId, var: partition_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: OperationId, var: operation_id, required: true}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_id: $service_id, partition_id: $partition_id, api_version: $api_version, operation_id: $operation_id, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API will induce data loss for the specified partition. It will trigger a call to the OnDataLossAsync API of the partition.
#
# POST /Faults/Services/{serviceId}/$/GetPartitions/{partitionId}/$/StartDataLoss
# operationId: StartDataLoss
export def "start-data-loss" [
  service_id: string
  partition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --operation-id: string # A GUID that identifies a call of this API. This is passed into the corresponding GetProgress API (required, format: uuid)
  --data-loss-mode: string@data-loss-mode-completer # This enum is passed to the StartDataLoss API to indicate what type of data loss to induce. (required)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> any {
  http-request {
    method: post
    path: "/Faults/Services/{serviceId}/$/GetPartitions/{partitionId}/$/StartDataLoss"
    path_params: [{name: serviceId, var: service_id}, {name: partitionId, var: partition_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: OperationId, var: operation_id, required: true}, {name: DataLossMode, var: data_loss_mode, required: true}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    service_id: $service_id, partition_id: $partition_id, api_version: $api_version, operation_id: $operation_id, data_loss_mode: $data_loss_mode, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Induces quorum loss for a given stateful service partition.
#
# POST /Faults/Services/{serviceId}/$/GetPartitions/{partitionId}/$/StartQuorumLoss
# operationId: StartQuorumLoss
export def "start-quorum-loss" [
  service_id: string
  partition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --operation-id: string # A GUID that identifies a call of this API. This is passed into the corresponding GetProgress API (required, format: uuid)
  --quorum-loss-mode: string@quorum-loss-mode-completer # This enum is passed to the StartQuorumLoss API to indicate what type of quorum loss to induce. (required)
  --quorum-loss-duration: int # The amount of time for which the partition will be kept in quorum loss. This must be specified in seconds. (required)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> any {
  http-request {
    method: post
    path: "/Faults/Services/{serviceId}/$/GetPartitions/{partitionId}/$/StartQuorumLoss"
    path_params: [{name: serviceId, var: service_id}, {name: partitionId, var: partition_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: OperationId, var: operation_id, required: true}, {name: QuorumLossMode, var: quorum_loss_mode, required: true}, {name: QuorumLossDuration, var: quorum_loss_duration, required: true}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    service_id: $service_id, partition_id: $partition_id, api_version: $api_version, operation_id: $operation_id, quorum_loss_mode: $quorum_loss_mode, quorum_loss_duration: $quorum_loss_duration, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API will restart some or all replicas or instances of the specified partition.
#
# POST /Faults/Services/{serviceId}/$/GetPartitions/{partitionId}/$/StartRestart
# operationId: StartPartitionRestart
export def "start-partition-restart" [
  service_id: string
  partition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --operation-id: string # A GUID that identifies a call of this API. This is passed into the corresponding GetProgress API (required, format: uuid)
  --restart-partition-mode: string@restart-partition-mode-completer # Describe which partitions to restart. (required)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> any {
  http-request {
    method: post
    path: "/Faults/Services/{serviceId}/$/GetPartitions/{partitionId}/$/StartRestart"
    path_params: [{name: serviceId, var: service_id}, {name: partitionId, var: partition_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: OperationId, var: operation_id, required: true}, {name: RestartPartitionMode, var: restart_partition_mode, required: true}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    service_id: $service_id, partition_id: $partition_id, api_version: $api_version, operation_id: $operation_id, restart_partition_mode: $restart_partition_mode, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the content information at the root of the image store.
#
# GET /ImageStore
# Returns: record<StoreFiles: table<FileSize: string, FileVersion: record, ModifiedDate: string, StoreRelativePath: string>, StoreFolders: table<FileCount: string, StoreRelativePath: string>>
# operationId: GetImageStoreRootContent
export def "get-image-store-root-content" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/ImageStore"
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Commit an image store upload session.
#
# POST /ImageStore/$/CommitUploadSession
# operationId: CommitImageStoreUploadSession
export def "commit-image-store-upload-session" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --session-id: string # A GUID generated by the user for a file uploading. It identifies an image store upload session which keeps track of all file chunks until it is committed. (required, format: uuid)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> any {
  http-request {
    method: post
    path: "/ImageStore/$/CommitUploadSession"
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: session-id, var: session_id, required: true}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, session_id: $session_id, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Copies image store content internally
#
# POST /ImageStore/$/Copy
# operationId: CopyImageStoreContent
export def "copy-image-store-content" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --check-mark-file: oneof<nothing, bool> # Indicates whether to check mark file during copying. The property is true if checking mark file is required, false otherwise. The mark file is used to check whether the folder is well constructed. If the property is true and mark file does not exist, the copy is skipped.
  remote_destination: string # The relative path of destination image store content to be copied to.
  remote_source: string # The relative path of source image store content to be copied from.
  --skip-files: list<string> # The list of the file names to be skipped for copying.
]: any -> any {
  $in | http-request {
    method: post
    path: "/ImageStore/$/Copy"
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: timeout, var: timeout}]
    body: {content_type: "application/json", kind: json, fields: [{name: CheckMarkFile, var: check_mark_file}, {name: RemoteDestination, var: remote_destination}, {name: RemoteSource, var: remote_source}, {name: SkipFiles, var: skip_files}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, timeout: $timeout, check_mark_file: $check_mark_file, remote_destination: $remote_destination, remote_source: $remote_source, skip_files: $skip_files
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancels an image store upload session.
#
# DELETE /ImageStore/$/DeleteUploadSession
# operationId: DeleteImageStoreUploadSession
export def "delete-image-store-upload-session" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --session-id: string # A GUID generated by the user for a file uploading. It identifies an image store upload session which keeps track of all file chunks until it is committed. (required, format: uuid)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> any {
  http-request {
    method: delete
    path: "/ImageStore/$/DeleteUploadSession"
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: session-id, var: session_id, required: true}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, session_id: $session_id, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the folder size at the root of the image store.
#
# GET /ImageStore/$/FolderSize
# Returns: record<FolderSize: string, StoreRelativePath: string>
# operationId: GetImageStoreRootFolderSize
export def "get-image-store-root-folder-size" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-7 # The version of the API. This parameter is required and its value must be '6.5'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.5)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/ImageStore/$/FolderSize"
    query: [{name: api-version, var: api_version, required: true, default: "6.5"}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the image store upload session by ID.
#
# GET /ImageStore/$/GetUploadSession
# Returns: record<UploadSessions: table<ExpectedRanges: list, FileSize: string, ModifiedDate: string, SessionId: string, StoreRelativePath: string>>
# operationId: GetImageStoreUploadSessionById
export def "get-image-store-upload-session-by-id" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --session-id: string # A GUID generated by the user for a file uploading. It identifies an image store upload session which keeps track of all file chunks until it is committed. (required, format: uuid)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/ImageStore/$/GetUploadSession"
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: session-id, var: session_id, required: true}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, session_id: $session_id, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes existing image store content.
#
# DELETE /ImageStore/{contentPath}
# operationId: DeleteImageStoreContent
export def "delete-image-store-content" [
  content_path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> any {
  http-request {
    method: delete
    path: "/ImageStore/{contentPath}"
    path_params: [{name: contentPath, var: content_path}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    content_path: $content_path, api_version: $api_version, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the image store content information.
#
# GET /ImageStore/{contentPath}
# Returns: record<StoreFiles: table<FileSize: string, FileVersion: record, ModifiedDate: string, StoreRelativePath: string>, StoreFolders: table<FileCount: string, StoreRelativePath: string>>
# operationId: GetImageStoreContent
export def "get-image-store-content" [
  content_path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-2 # The version of the API. This parameter is required and its value must be '6.2'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.2)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/ImageStore/{contentPath}"
    path_params: [{name: contentPath, var: content_path}]
    query: [{name: api-version, var: api_version, required: true, default: "6.2"}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    content_path: $content_path, api_version: $api_version, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Uploads contents of the file to the image store.
#
# PUT /ImageStore/{contentPath}
# operationId: UploadFile
export def "upload-file" [
  content_path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> any {
  http-request {
    method: put
    path: "/ImageStore/{contentPath}"
    path_params: [{name: contentPath, var: content_path}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    content_path: $content_path, api_version: $api_version, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the size of a folder in image store
#
# GET /ImageStore/{contentPath}/$/FolderSize
# Returns: record<FolderSize: string, StoreRelativePath: string>
# operationId: GetImageStoreFolderSize
export def "get-image-store-folder-size" [
  content_path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-7 # The version of the API. This parameter is required and its value must be '6.5'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.5)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/ImageStore/{contentPath}/$/FolderSize"
    path_params: [{name: contentPath, var: content_path}]
    query: [{name: api-version, var: api_version, required: true, default: "6.5"}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    content_path: $content_path, api_version: $api_version, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the image store upload session by relative path.
#
# GET /ImageStore/{contentPath}/$/GetUploadSession
# Returns: record<UploadSessions: table<ExpectedRanges: list, FileSize: string, ModifiedDate: string, SessionId: string, StoreRelativePath: string>>
# operationId: GetImageStoreUploadSessionByPath
export def "get-image-store-upload-session-by-path" [
  content_path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/ImageStore/{contentPath}/$/GetUploadSession"
    path_params: [{name: contentPath, var: content_path}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    content_path: $content_path, api_version: $api_version, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Uploads a file chunk to the image store relative path.
#
# PUT /ImageStore/{contentPath}/$/UploadChunk
# operationId: UploadFileChunk
export def "upload-file-chunk" [
  content_path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --session-id: string # A GUID generated by the user for a file uploading. It identifies an image store upload session which keeps track of all file chunks until it is committed. (required, format: uuid)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --content-range: string # When uploading file chunks to the image store, the Content-Range header field need to be configured and sent with a request. The format should looks like "bytes {First-Byte-Position}-{Last-Byte-Position}/{File-Length}". For example, Content-Range:bytes 300-5000/20000 indicates that user is sending bytes 300 through 5,000 and the total file length is 20,000 bytes. (required)
]: nothing -> any {
  http-request {
    method: put
    path: "/ImageStore/{contentPath}/$/UploadChunk"
    path_params: [{name: contentPath, var: content_path}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: session-id, var: session_id, required: true}, {name: timeout, var: timeout}]
    header: [{name: Content-Range, var: content_range, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    content_path: $content_path, api_version: $api_version, session_id: $session_id, timeout: $timeout, content_range: $content_range
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a Service Fabric name.
#
# POST /Names/$/Create
# operationId: CreateName
export def "create-name" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  name: string # The Service Fabric name, including the 'fabric:' URI scheme.
]: any -> any {
  $in | http-request {
    method: post
    path: "/Names/$/Create"
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: timeout, var: timeout}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    api_version: $api_version, timeout: $timeout, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a Service Fabric name.
#
# DELETE /Names/{nameId}
# operationId: DeleteName
export def "delete-name" [
  name_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> any {
  http-request {
    method: delete
    path: "/Names/{nameId}"
    path_params: [{name: nameId, var: name_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name_id: $name_id, api_version: $api_version, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns whether the Service Fabric name exists.
#
# GET /Names/{nameId}
# operationId: GetNameExistsInfo
export def "get-name-exists-info" [
  name_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> any {
  http-request {
    method: get
    path: "/Names/{nameId}"
    path_params: [{name: nameId, var: name_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name_id: $name_id, api_version: $api_version, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information on all Service Fabric properties under a given name.
#
# GET /Names/{nameId}/$/GetProperties
# Returns: record<ContinuationToken: string, IsConsistent: bool, Properties: table<Metadata: record, Name: string, Value: record>>
# operationId: GetPropertyInfoList
export def "get-property-info-list" [
  name_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --include-values: oneof<nothing, bool> # Allows specifying whether to include the values of the properties returned. True if values should be returned with the metadata; False to return only property metadata. (default: false)
  --continuation-token: string # The continuation token parameter is used to obtain next set of results. A continuation token with a non-empty value is included in the response of the API when the results from the system do not fit in a single response. When this value is passed to the next API call, the API returns next set of results. If there are no further results, then the continuation token does not contain a value. The value of this parameter should not be URL encoded.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Names/{nameId}/$/GetProperties"
    path_params: [{name: nameId, var: name_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: IncludeValues, var: include_values}, {name: ContinuationToken, var: continuation_token}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name_id: $name_id, api_version: $api_version, include_values: $include_values, continuation_token: $continuation_token, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Submits a property batch.
#
# POST /Names/{nameId}/$/GetProperties/$/SubmitBatch
# Returns: record<Properties: any, Kind: string>
# operationId: SubmitPropertyBatch
export def "submit-property-batch" [
  name_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --operations: list # A list of the property batch operations to be executed. — item shape: {Kind: "Invalid"|"Put"|"Get"|"CheckExists"|"CheckSequence"|"Delete"|"CheckValue", PropertyName: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Names/{nameId}/$/GetProperties/$/SubmitBatch"
    path_params: [{name: nameId, var: name_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: timeout, var: timeout}]
    body: {content_type: "application/json", kind: json, fields: [{name: Operations, var: operations}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name_id: $name_id, api_version: $api_version, timeout: $timeout, operations: $operations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified Service Fabric property.
#
# DELETE /Names/{nameId}/$/GetProperty
# operationId: DeleteProperty
export def "delete-property" [
  name_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --property-name: string # Specifies the name of the property to get. (required)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> any {
  http-request {
    method: delete
    path: "/Names/{nameId}/$/GetProperty"
    path_params: [{name: nameId, var: name_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: PropertyName, var: property_name, required: true}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name_id: $name_id, api_version: $api_version, property_name: $property_name, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the specified Service Fabric property.
#
# GET /Names/{nameId}/$/GetProperty
# Discriminator (response): Kind
# Returns: record<Metadata: record<CustomTypeId: string, LastModifiedUtcTimestamp: string, Parent: string, SequenceNumber: string, SizeInBytes: int, TypeId: string>, Name: string, Value: record<Kind: string>>
# operationId: GetPropertyInfo
export def "get-property-info" [
  name_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --property-name: string # Specifies the name of the property to get. (required)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Names/{nameId}/$/GetProperty"
    path_params: [{name: nameId, var: name_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: PropertyName, var: property_name, required: true}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name_id: $name_id, api_version: $api_version, property_name: $property_name, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates or updates a Service Fabric property.
#
# PUT /Names/{nameId}/$/GetProperty
# operationId: PutProperty
export def "put-property" [
  name_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --custom-type-id: string # The property's custom type ID. Using this property, the user is able to tag the type of the value of the property.
  property_name: string # The name of the Service Fabric property.
  value: any # Describes a Service Fabric property value. — shape: {Kind: "Invalid"|"Binary"|"Int64"|"Double"|"String"|"Guid"}
]: any -> any {
  $in | http-request {
    method: put
    path: "/Names/{nameId}/$/GetProperty"
    path_params: [{name: nameId, var: name_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: timeout, var: timeout}]
    body: {content_type: "application/json", kind: json, fields: [{name: CustomTypeId, var: custom_type_id}, {name: PropertyName, var: property_name}, {name: Value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name_id: $name_id, api_version: $api_version, timeout: $timeout, custom_type_id: $custom_type_id, property_name: $property_name, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enumerates all the Service Fabric names under a given name.
#
# GET /Names/{nameId}/$/GetSubNames
# Returns: record<ContinuationToken: string, IsConsistent: bool, SubNames: list<string>>
# operationId: GetSubNameInfoList
export def "get-sub-name-info-list" [
  name_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --recursive: oneof<nothing, bool> # Allows specifying that the search performed should be recursive. (default: false)
  --continuation-token: string # The continuation token parameter is used to obtain next set of results. A continuation token with a non-empty value is included in the response of the API when the results from the system do not fit in a single response. When this value is passed to the next API call, the API returns next set of results. If there are no further results, then the continuation token does not contain a value. The value of this parameter should not be URL encoded.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Names/{nameId}/$/GetSubNames"
    path_params: [{name: nameId, var: name_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: Recursive, var: recursive}, {name: ContinuationToken, var: continuation_token}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name_id: $name_id, api_version: $api_version, recursive: $recursive, continuation_token: $continuation_token, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the list of nodes in the Service Fabric cluster.
#
# GET /Nodes
# Returns: record<ContinuationToken: string, Items: table<CodeVersion: string, ConfigVersion: string, FaultDomain: string, HealthState: string, Id: record, InstanceId: string, IpAddressOrFQDN: string, IsSeedNode: bool, IsStopped: bool, Name: string, NodeDeactivationInfo: record, NodeDownAt: string, NodeDownTimeInSeconds: string, NodeStatus: string, NodeUpAt: string, NodeUpTimeInSeconds: string, Type: string, UpgradeDomain: string>>
# operationId: GetNodeInfoList
export def "get-node-info-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-8 # The version of the API. This parameter is required and its value must be '6.3'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.3)
  --continuation-token: string # The continuation token parameter is used to obtain next set of results. A continuation token with a non-empty value is included in the response of the API when the results from the system do not fit in a single response. When this value is passed to the next API call, the API returns next set of results. If there are no further results, then the continuation token does not contain a value. The value of this parameter should not be URL encoded.
  --node-status-filter: string@node-status-filter-completer # Allows filtering the nodes based on the NodeStatus. Only the nodes that are matching the specified filter value will be returned. The filter value can be one of the following. (default: default)
  --max-results: int # The maximum number of results to be returned as part of the paged queries. This parameter defines the upper bound on the number of results returned. The results returned can be less than the specified maximum results if they do not fit in the message as per the max message size restrictions defined in the configuration. If this parameter is zero or not specified, the paged query includes as many results as possible that fit in the return message. (format: int64, default: 0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Nodes"
    query: [{name: api-version, var: api_version, required: true, default: "6.3"}, {name: ContinuationToken, var: continuation_token}, {name: NodeStatusFilter, var: node_status_filter}, {name: MaxResults, var: max_results}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, continuation_token: $continuation_token, node_status_filter: $node_status_filter, max_results: $max_results, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the information about a specific node in the Service Fabric cluster.
#
# GET /Nodes/{nodeName}
# Returns: record<CodeVersion: string, ConfigVersion: string, FaultDomain: string, HealthState: string, Id: record<Id: string>, InstanceId: string, IpAddressOrFQDN: string, IsSeedNode: bool, IsStopped: bool, Name: string, NodeDeactivationInfo: record<NodeDeactivationIntent: string, NodeDeactivationStatus: string, NodeDeactivationTask: list<record>, PendingSafetyChecks: list<record>>, NodeDownAt: string, NodeDownTimeInSeconds: string, NodeStatus: string, NodeUpAt: string, NodeUpTimeInSeconds: string, Type: string, UpgradeDomain: string>
# operationId: GetNodeInfo
export def "get-node-info" [
  node_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Nodes/{nodeName}"
    path_params: [{name: nodeName, var: node_name}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    node_name: $node_name, api_version: $api_version, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Activate a Service Fabric cluster node that is currently deactivated.
#
# POST /Nodes/{nodeName}/$/Activate
# operationId: EnableNode
export def "enable-node" [
  node_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> any {
  http-request {
    method: post
    path: "/Nodes/{nodeName}/$/Activate"
    path_params: [{name: nodeName, var: node_name}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    node_name: $node_name, api_version: $api_version, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deactivate a Service Fabric cluster node with the specified deactivation intent.
#
# POST /Nodes/{nodeName}/$/Deactivate
# operationId: DisableNode
export def "disable-node" [
  node_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --deactivation-intent: string@deactivation-intent-completer # Describes the intent or reason for deactivating the node. The possible values are following.
]: any -> any {
  $in | http-request {
    method: post
    path: "/Nodes/{nodeName}/$/Deactivate"
    path_params: [{name: nodeName, var: node_name}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: timeout, var: timeout}]
    body: {content_type: "application/json", kind: json, fields: [{name: DeactivationIntent, var: deactivation_intent}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    node_name: $node_name, api_version: $api_version, timeout: $timeout, deactivation_intent: $deactivation_intent
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Downloads all of the code packages associated with specified service manifest on the specified node.
#
# POST /Nodes/{nodeName}/$/DeployServicePackage
# operationId: DeployServicePackageToNode
export def "deploy-service-package-to-node" [
  node_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  application_type_name: string # The application type name as defined in the application manifest.
  application_type_version: string # The version of the application type as defined in the application manifest.
  --body-node-name: string # The name of a Service Fabric node. (spec name: NodeName)
  --package-sharing-policy: list # List of package sharing policy information. — item shape: {PackageSharingScope?: "None"|"All"|"Code"|"Config"|"Data", SharedPackageName?: string}
  service_manifest_name: string # The name of the service manifest.
]: any -> any {
  $in | http-request {
    method: post
    path: "/Nodes/{nodeName}/$/DeployServicePackage"
    path_params: [{name: nodeName, var: node_name}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: timeout, var: timeout}]
    body: {content_type: "application/json", kind: json, fields: [{name: ApplicationTypeName, var: application_type_name}, {name: ApplicationTypeVersion, var: application_type_version}, {name: NodeName, var: body_node_name, required: true}, {name: PackageSharingPolicy, var: package_sharing_policy}, {name: ServiceManifestName, var: service_manifest_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    node_name: $node_name, api_version: $api_version, timeout: $timeout, application_type_name: $application_type_name, application_type_version: $application_type_version, body_node_name: $body_node_name, package_sharing_policy: $package_sharing_policy, service_manifest_name: $service_manifest_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the list of applications deployed on a Service Fabric node.
#
# GET /Nodes/{nodeName}/$/GetApplications
# Returns: record<ContinuationToken: string, Items: table<HealthState: string, Id: string, LogDirectory: string, Name: string, Status: string, TempDirectory: string, TypeName: string, WorkDirectory: string>>
# operationId: GetDeployedApplicationInfoList
export def "get-deployed-application-info-list" [
  node_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-3 # The version of the API. This parameter is required and its value must be '6.1'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.1)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --include-health-state: oneof<nothing, bool> # Include the health state of an entity. If this parameter is false or not specified, then the health state returned is "Unknown". When set to true, the query goes in parallel to the node and the health system service before the results are merged. As a result, the query is more expensive and may take a longer time. (default: false)
  --continuation-token: string # The continuation token parameter is used to obtain next set of results. A continuation token with a non-empty value is included in the response of the API when the results from the system do not fit in a single response. When this value is passed to the next API call, the API returns next set of results. If there are no further results, then the continuation token does not contain a value. The value of this parameter should not be URL encoded.
  --max-results: int # The maximum number of results to be returned as part of the paged queries. This parameter defines the upper bound on the number of results returned. The results returned can be less than the specified maximum results if they do not fit in the message as per the max message size restrictions defined in the configuration. If this parameter is zero or not specified, the paged query includes as many results as possible that fit in the return message. (format: int64, default: 0)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Nodes/{nodeName}/$/GetApplications"
    path_params: [{name: nodeName, var: node_name}]
    query: [{name: api-version, var: api_version, required: true, default: "6.1"}, {name: timeout, var: timeout}, {name: IncludeHealthState, var: include_health_state}, {name: ContinuationToken, var: continuation_token}, {name: MaxResults, var: max_results}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    node_name: $node_name, api_version: $api_version, timeout: $timeout, include_health_state: $include_health_state, continuation_token: $continuation_token, max_results: $max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the information about an application deployed on a Service Fabric node.
#
# GET /Nodes/{nodeName}/$/GetApplications/{applicationId}
# Returns: record<HealthState: string, Id: string, LogDirectory: string, Name: string, Status: string, TempDirectory: string, TypeName: string, WorkDirectory: string>
# operationId: GetDeployedApplicationInfo
export def "get-deployed-application-info" [
  node_name: string
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-3 # The version of the API. This parameter is required and its value must be '6.1'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.1)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --include-health-state: oneof<nothing, bool> # Include the health state of an entity. If this parameter is false or not specified, then the health state returned is "Unknown". When set to true, the query goes in parallel to the node and the health system service before the results are merged. As a result, the query is more expensive and may take a longer time. (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Nodes/{nodeName}/$/GetApplications/{applicationId}"
    path_params: [{name: nodeName, var: node_name}, {name: applicationId, var: application_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.1"}, {name: timeout, var: timeout}, {name: IncludeHealthState, var: include_health_state}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    node_name: $node_name, application_id: $application_id, api_version: $api_version, timeout: $timeout, include_health_state: $include_health_state
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the list of code packages deployed on a Service Fabric node.
#
# GET /Nodes/{nodeName}/$/GetApplications/{applicationId}/$/GetCodePackages
# Returns: table<HostIsolationMode: string, HostType: string, MainEntryPoint: record<CodePackageEntryPointStatistics: record, EntryPointLocation: string, InstanceId: string, NextActivationTime: string, ProcessId: string, RunAsUserName: string, Status: string>, Name: string, RunFrequencyInterval: string, ServiceManifestName: string, ServicePackageActivationId: string, SetupEntryPoint: record<CodePackageEntryPointStatistics: record, EntryPointLocation: string, InstanceId: string, NextActivationTime: string, ProcessId: string, RunAsUserName: string, Status: string>, Status: string, Version: string>
# operationId: GetDeployedCodePackageInfoList
export def "get-deployed-code-package-info-list" [
  node_name: string
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --service-manifest-name: string # The name of a service manifest registered as part of an application type in a Service Fabric cluster.
  --code-package-name: string # The name of code package specified in service manifest registered as part of an application type in a Service Fabric cluster.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/Nodes/{nodeName}/$/GetApplications/{applicationId}/$/GetCodePackages"
    path_params: [{name: nodeName, var: node_name}, {name: applicationId, var: application_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: ServiceManifestName, var: service_manifest_name}, {name: CodePackageName, var: code_package_name}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    node_name: $node_name, application_id: $application_id, api_version: $api_version, service_manifest_name: $service_manifest_name, code_package_name: $code_package_name, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Invoke container API on a container deployed on a Service Fabric node.
#
# POST /Nodes/{nodeName}/$/GetApplications/{applicationId}/$/GetCodePackages/$/ContainerApi
# Returns: record<ContainerApiResult: record<Body: string, Content-Encoding: string, Content-Type: string, Status: int>>
# operationId: InvokeContainerApi
export def "invoke-container-api" [
  node_name: string
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-2 # The version of the API. This parameter is required and its value must be '6.2'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.2)
  --service-manifest-name: string # The name of a service manifest registered as part of an application type in a Service Fabric cluster. (required)
  --code-package-name: string # The name of code package specified in service manifest registered as part of an application type in a Service Fabric cluster. (required)
  --code-package-instance-id: string # ID that uniquely identifies a code package instance deployed on a service fabric node. (required)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --body: string # HTTP request body of container REST API
  --content-type: string # Content type of container REST API request, defaults to "application/json"
  --http-verb: string # HTTP verb of container REST API, defaults to "GET"
  uri_path: string # URI path of container REST API
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Nodes/{nodeName}/$/GetApplications/{applicationId}/$/GetCodePackages/$/ContainerApi"
    path_params: [{name: nodeName, var: node_name}, {name: applicationId, var: application_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.2"}, {name: ServiceManifestName, var: service_manifest_name, required: true}, {name: CodePackageName, var: code_package_name, required: true}, {name: CodePackageInstanceId, var: code_package_instance_id, required: true}, {name: timeout, var: timeout}]
    body: {content_type: "application/json", kind: json, fields: [{name: Body, var: body}, {name: Content-Type, var: content_type}, {name: HttpVerb, var: http_verb}, {name: UriPath, var: uri_path}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    node_name: $node_name, application_id: $application_id, api_version: $api_version, service_manifest_name: $service_manifest_name, code_package_name: $code_package_name, code_package_instance_id: $code_package_instance_id, timeout: $timeout, body: $body, content_type: $content_type, http_verb: $http_verb, uri_path: $uri_path
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the container logs for container deployed on a Service Fabric node.
#
# GET /Nodes/{nodeName}/$/GetApplications/{applicationId}/$/GetCodePackages/$/ContainerLogs
# Returns: record<Content: string>
# operationId: GetContainerLogsDeployedOnNode
export def "get-container-logs-deployed-on-node" [
  node_name: string
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-2 # The version of the API. This parameter is required and its value must be '6.2'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.2)
  --service-manifest-name: string # The name of a service manifest registered as part of an application type in a Service Fabric cluster. (required)
  --code-package-name: string # The name of code package specified in service manifest registered as part of an application type in a Service Fabric cluster. (required)
  --tail: string # Number of lines to show from the end of the logs. Default is 100. 'all' to show the complete logs.
  --previous: oneof<nothing, bool> # Specifies whether to get container logs from exited/dead containers of the code package instance. (default: false)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Nodes/{nodeName}/$/GetApplications/{applicationId}/$/GetCodePackages/$/ContainerLogs"
    path_params: [{name: nodeName, var: node_name}, {name: applicationId, var: application_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.2"}, {name: ServiceManifestName, var: service_manifest_name, required: true}, {name: CodePackageName, var: code_package_name, required: true}, {name: Tail, var: tail}, {name: Previous, var: previous}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    node_name: $node_name, application_id: $application_id, api_version: $api_version, service_manifest_name: $service_manifest_name, code_package_name: $code_package_name, tail: $tail, previous: $previous, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Restarts a code package deployed on a Service Fabric node in a cluster.
#
# POST /Nodes/{nodeName}/$/GetApplications/{applicationId}/$/GetCodePackages/$/Restart
# operationId: RestartDeployedCodePackage
export def "restart-deployed-code-package" [
  node_name: string
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  code_package_instance_id: string # The instance ID for current running entry point. For a code package setup entry point (if specified) runs first and after it finishes main entry point is started. Each time entry point executable is run, its instance id will change.
  code_package_name: string # The name of the code package defined in the service manifest.
  service_manifest_name: string # The name of the service manifest.
  --service-package-activation-id: string # The ActivationId of a deployed service package. If ServicePackageActivationMode specified at the time of creating the service is 'SharedProcess' (or if it is not specified, in which case it defaults to 'SharedProcess'), then value of ServicePackageActivationId is always an empty string.
]: any -> any {
  $in | http-request {
    method: post
    path: "/Nodes/{nodeName}/$/GetApplications/{applicationId}/$/GetCodePackages/$/Restart"
    path_params: [{name: nodeName, var: node_name}, {name: applicationId, var: application_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: timeout, var: timeout}]
    body: {content_type: "application/json", kind: json, fields: [{name: CodePackageInstanceId, var: code_package_instance_id}, {name: CodePackageName, var: code_package_name}, {name: ServiceManifestName, var: service_manifest_name}, {name: ServicePackageActivationId, var: service_package_activation_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    node_name: $node_name, application_id: $application_id, api_version: $api_version, timeout: $timeout, code_package_instance_id: $code_package_instance_id, code_package_name: $code_package_name, service_manifest_name: $service_manifest_name, service_package_activation_id: $service_package_activation_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the information about health of an application deployed on a Service Fabric node.
#
# GET /Nodes/{nodeName}/$/GetApplications/{applicationId}/$/GetHealth
# Returns: record<DeployedServicePackageHealthStates: table<ApplicationName: string, NodeName: string, ServiceManifestName: string, ServicePackageActivationId: string, AggregatedHealthState: string>, Name: string, NodeName: string, AggregatedHealthState: string, HealthEvents: table<IsExpired: bool, LastErrorTransitionAt: string, LastModifiedUtcTimestamp: string, LastOkTransitionAt: string, LastWarningTransitionAt: string, SourceUtcTimestamp: string, Description: string, HealthState: string, Property: string, RemoveWhenExpired: bool, SequenceNumber: string, SourceId: string, TimeToLiveInMilliSeconds: string>, HealthStatistics: record<HealthStateCountList: list<record>>, UnhealthyEvaluations: table<HealthEvaluation: record>>
# operationId: GetDeployedApplicationHealth
export def "get-deployed-application-health" [
  node_name: string
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --events-health-state-filter: int # Allows filtering the collection of HealthEvent objects returned based on health state. The possible values for this parameter include integer value of one of the following health states. Only events that match the filter are returned. All events are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these values, obtained using the bitwise 'OR' operator. For example, If the provided value is 6 then all of the events with HealthState value of OK (2) and Warning (4) are returned. - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --deployed-service-packages-health-state-filter: int # Allows filtering of the deployed service package health state objects returned in the result of deployed application health query based on their health state. The possible values for this parameter include integer value of one of the following health states. Only deployed service packages that match the filter are returned. All deployed service packages are used to evaluate the aggregated health state of the deployed application. If not specified, all entries are returned. The state values are flag-based enumeration, so the value can be a combination of these values, obtained using the bitwise 'OR' operator. For example, if the provided value is 6 then health state of service packages with HealthState value of OK (2) and Warning (4) are returned. - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --exclude-health-statistics: oneof<nothing, bool> # Indicates whether the health statistics should be returned as part of the query result. False by default. The statistics show the number of children entities in health state Ok, Warning, and Error. (default: false)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Nodes/{nodeName}/$/GetApplications/{applicationId}/$/GetHealth"
    path_params: [{name: nodeName, var: node_name}, {name: applicationId, var: application_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: EventsHealthStateFilter, var: events_health_state_filter}, {name: DeployedServicePackagesHealthStateFilter, var: deployed_service_packages_health_state_filter}, {name: ExcludeHealthStatistics, var: exclude_health_statistics}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    node_name: $node_name, application_id: $application_id, api_version: $api_version, events_health_state_filter: $events_health_state_filter, deployed_service_packages_health_state_filter: $deployed_service_packages_health_state_filter, exclude_health_statistics: $exclude_health_statistics, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the information about health of an application deployed on a Service Fabric node. using the specified policy.
#
# POST /Nodes/{nodeName}/$/GetApplications/{applicationId}/$/GetHealth
# Returns: record<DeployedServicePackageHealthStates: table<ApplicationName: string, NodeName: string, ServiceManifestName: string, ServicePackageActivationId: string, AggregatedHealthState: string>, Name: string, NodeName: string, AggregatedHealthState: string, HealthEvents: table<IsExpired: bool, LastErrorTransitionAt: string, LastModifiedUtcTimestamp: string, LastOkTransitionAt: string, LastWarningTransitionAt: string, SourceUtcTimestamp: string, Description: string, HealthState: string, Property: string, RemoveWhenExpired: bool, SequenceNumber: string, SourceId: string, TimeToLiveInMilliSeconds: string>, HealthStatistics: record<HealthStateCountList: list<record>>, UnhealthyEvaluations: table<HealthEvaluation: record>>
# operationId: GetDeployedApplicationHealthUsingPolicy
export def "get-deployed-application-health-using-policy" [
  node_name: string
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --events-health-state-filter: int # Allows filtering the collection of HealthEvent objects returned based on health state. The possible values for this parameter include integer value of one of the following health states. Only events that match the filter are returned. All events are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these values, obtained using the bitwise 'OR' operator. For example, If the provided value is 6 then all of the events with HealthState value of OK (2) and Warning (4) are returned. - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --deployed-service-packages-health-state-filter: int # Allows filtering of the deployed service package health state objects returned in the result of deployed application health query based on their health state. The possible values for this parameter include integer value of one of the following health states. Only deployed service packages that match the filter are returned. All deployed service packages are used to evaluate the aggregated health state of the deployed application. If not specified, all entries are returned. The state values are flag-based enumeration, so the value can be a combination of these values, obtained using the bitwise 'OR' operator. For example, if the provided value is 6 then health state of service packages with HealthState value of OK (2) and Warning (4) are returned. - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --exclude-health-statistics: oneof<nothing, bool> # Indicates whether the health statistics should be returned as part of the query result. False by default. The statistics show the number of children entities in health state Ok, Warning, and Error. (default: false)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --consider-warning-as-error: oneof<nothing, bool> # Indicates whether warnings are treated with the same severity as errors. (default: false)
  --default-service-type-health-policy: any # Represents the health policy used to evaluate the health of services belonging to a service type. — shape: {MaxPercentUnhealthyPartitionsPerService?: int, MaxPercentUnhealthyReplicasPerPartition?: int, MaxPercentUnhealthyServices?: int}
  --max-percent-unhealthy-deployed-applications: int # The maximum allowed percentage of unhealthy deployed applications. Allowed values are Byte values from zero to 100. The percentage represents the maximum tolerated percentage of deployed applications that can be unhealthy before the application is considered in error. This is calculated by dividing the number of unhealthy deployed applications over the number of nodes where the application is currently deployed on in the cluster. The computation rounds up to tolerate one failure on small numbers of nodes. Default percentage is zero. (default: 0)
  --service-type-health-policy-map: list # Defines a ServiceTypeHealthPolicy per service type name. The entries in the map replace the default service type health policy for each specified service type. For example, in an application that contains both a stateless gateway service type and a stateful engine service type, the health policies for the stateless and stateful services can be configured differently. With policy per service type, there's more granular control of the health of the service. If no policy is specified for a service type name, the DefaultServiceTypeHealthPolicy is used for evaluation. — item shape: {Key: string, Value: any}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Nodes/{nodeName}/$/GetApplications/{applicationId}/$/GetHealth"
    path_params: [{name: nodeName, var: node_name}, {name: applicationId, var: application_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: EventsHealthStateFilter, var: events_health_state_filter}, {name: DeployedServicePackagesHealthStateFilter, var: deployed_service_packages_health_state_filter}, {name: ExcludeHealthStatistics, var: exclude_health_statistics}, {name: timeout, var: timeout}]
    body: {content_type: "application/json", kind: json, fields: [{name: ConsiderWarningAsError, var: consider_warning_as_error}, {name: DefaultServiceTypeHealthPolicy, var: default_service_type_health_policy}, {name: MaxPercentUnhealthyDeployedApplications, var: max_percent_unhealthy_deployed_applications}, {name: ServiceTypeHealthPolicyMap, var: service_type_health_policy_map}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    node_name: $node_name, application_id: $application_id, api_version: $api_version, events_health_state_filter: $events_health_state_filter, deployed_service_packages_health_state_filter: $deployed_service_packages_health_state_filter, exclude_health_statistics: $exclude_health_statistics, timeout: $timeout, consider_warning_as_error: $consider_warning_as_error, default_service_type_health_policy: $default_service_type_health_policy, max_percent_unhealthy_deployed_applications: $max_percent_unhealthy_deployed_applications, service_type_health_policy_map: $service_type_health_policy_map
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the list of replicas deployed on a Service Fabric node.
#
# GET /Nodes/{nodeName}/$/GetApplications/{applicationId}/$/GetReplicas
# Returns: table<Address: string, CodePackageName: string, HostProcessId: string, PartitionId: string, ReplicaStatus: string, ServiceKind: string, ServiceManifestName: string, ServiceName: string, ServicePackageActivationId: string, ServiceTypeName: string>
# operationId: GetDeployedServiceReplicaInfoList
export def "get-deployed-service-replica-info-list" [
  node_name: string
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --partition-id: string # The identity of the partition. (format: uuid)
  --service-manifest-name: string # The name of a service manifest registered as part of an application type in a Service Fabric cluster.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/Nodes/{nodeName}/$/GetApplications/{applicationId}/$/GetReplicas"
    path_params: [{name: nodeName, var: node_name}, {name: applicationId, var: application_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: PartitionId, var: partition_id}, {name: ServiceManifestName, var: service_manifest_name}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    node_name: $node_name, application_id: $application_id, api_version: $api_version, partition_id: $partition_id, service_manifest_name: $service_manifest_name, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the list of service packages deployed on a Service Fabric node.
#
# GET /Nodes/{nodeName}/$/GetApplications/{applicationId}/$/GetServicePackages
# Returns: table<Name: string, ServicePackageActivationId: string, Status: string, Version: string>
# operationId: GetDeployedServicePackageInfoList
export def "get-deployed-service-package-info-list" [
  node_name: string
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/Nodes/{nodeName}/$/GetApplications/{applicationId}/$/GetServicePackages"
    path_params: [{name: nodeName, var: node_name}, {name: applicationId, var: application_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    node_name: $node_name, application_id: $application_id, api_version: $api_version, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the list of service packages deployed on a Service Fabric node matching exactly the specified name.
#
# GET /Nodes/{nodeName}/$/GetApplications/{applicationId}/$/GetServicePackages/{servicePackageName}
# Returns: table<Name: string, ServicePackageActivationId: string, Status: string, Version: string>
# operationId: GetDeployedServicePackageInfoListByName
export def "get-deployed-service-package-info-list-by-name" [
  node_name: string
  application_id: string
  service_package_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/Nodes/{nodeName}/$/GetApplications/{applicationId}/$/GetServicePackages/{servicePackageName}"
    path_params: [{name: nodeName, var: node_name}, {name: applicationId, var: application_id}, {name: servicePackageName, var: service_package_name}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    node_name: $node_name, application_id: $application_id, service_package_name: $service_package_name, api_version: $api_version, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the information about health of a service package for a specific application deployed for a Service Fabric node and application.
#
# GET /Nodes/{nodeName}/$/GetApplications/{applicationId}/$/GetServicePackages/{servicePackageName}/$/GetHealth
# Returns: record<ApplicationName: string, NodeName: string, ServiceManifestName: string, AggregatedHealthState: string, HealthEvents: table<IsExpired: bool, LastErrorTransitionAt: string, LastModifiedUtcTimestamp: string, LastOkTransitionAt: string, LastWarningTransitionAt: string, SourceUtcTimestamp: string, Description: string, HealthState: string, Property: string, RemoveWhenExpired: bool, SequenceNumber: string, SourceId: string, TimeToLiveInMilliSeconds: string>, HealthStatistics: record<HealthStateCountList: list<record>>, UnhealthyEvaluations: table<HealthEvaluation: record>>
# operationId: GetDeployedServicePackageHealth
export def "get-deployed-service-package-health" [
  node_name: string
  application_id: string
  service_package_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --events-health-state-filter: int # Allows filtering the collection of HealthEvent objects returned based on health state. The possible values for this parameter include integer value of one of the following health states. Only events that match the filter are returned. All events are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these values, obtained using the bitwise 'OR' operator. For example, If the provided value is 6 then all of the events with HealthState value of OK (2) and Warning (4) are returned. - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Nodes/{nodeName}/$/GetApplications/{applicationId}/$/GetServicePackages/{servicePackageName}/$/GetHealth"
    path_params: [{name: nodeName, var: node_name}, {name: applicationId, var: application_id}, {name: servicePackageName, var: service_package_name}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: EventsHealthStateFilter, var: events_health_state_filter}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    node_name: $node_name, application_id: $application_id, service_package_name: $service_package_name, api_version: $api_version, events_health_state_filter: $events_health_state_filter, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the information about health of service package for a specific application deployed on a Service Fabric node using the specified policy.
#
# POST /Nodes/{nodeName}/$/GetApplications/{applicationId}/$/GetServicePackages/{servicePackageName}/$/GetHealth
# Returns: record<ApplicationName: string, NodeName: string, ServiceManifestName: string, AggregatedHealthState: string, HealthEvents: table<IsExpired: bool, LastErrorTransitionAt: string, LastModifiedUtcTimestamp: string, LastOkTransitionAt: string, LastWarningTransitionAt: string, SourceUtcTimestamp: string, Description: string, HealthState: string, Property: string, RemoveWhenExpired: bool, SequenceNumber: string, SourceId: string, TimeToLiveInMilliSeconds: string>, HealthStatistics: record<HealthStateCountList: list<record>>, UnhealthyEvaluations: table<HealthEvaluation: record>>
# operationId: GetDeployedServicePackageHealthUsingPolicy
export def "get-deployed-service-package-health-using-policy" [
  node_name: string
  application_id: string
  service_package_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --events-health-state-filter: int # Allows filtering the collection of HealthEvent objects returned based on health state. The possible values for this parameter include integer value of one of the following health states. Only events that match the filter are returned. All events are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these values, obtained using the bitwise 'OR' operator. For example, If the provided value is 6 then all of the events with HealthState value of OK (2) and Warning (4) are returned. - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --consider-warning-as-error: oneof<nothing, bool> # Indicates whether warnings are treated with the same severity as errors. (default: false)
  --default-service-type-health-policy: any # Represents the health policy used to evaluate the health of services belonging to a service type. — shape: {MaxPercentUnhealthyPartitionsPerService?: int, MaxPercentUnhealthyReplicasPerPartition?: int, MaxPercentUnhealthyServices?: int}
  --max-percent-unhealthy-deployed-applications: int # The maximum allowed percentage of unhealthy deployed applications. Allowed values are Byte values from zero to 100. The percentage represents the maximum tolerated percentage of deployed applications that can be unhealthy before the application is considered in error. This is calculated by dividing the number of unhealthy deployed applications over the number of nodes where the application is currently deployed on in the cluster. The computation rounds up to tolerate one failure on small numbers of nodes. Default percentage is zero. (default: 0)
  --service-type-health-policy-map: list # Defines a ServiceTypeHealthPolicy per service type name. The entries in the map replace the default service type health policy for each specified service type. For example, in an application that contains both a stateless gateway service type and a stateful engine service type, the health policies for the stateless and stateful services can be configured differently. With policy per service type, there's more granular control of the health of the service. If no policy is specified for a service type name, the DefaultServiceTypeHealthPolicy is used for evaluation. — item shape: {Key: string, Value: any}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Nodes/{nodeName}/$/GetApplications/{applicationId}/$/GetServicePackages/{servicePackageName}/$/GetHealth"
    path_params: [{name: nodeName, var: node_name}, {name: applicationId, var: application_id}, {name: servicePackageName, var: service_package_name}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: EventsHealthStateFilter, var: events_health_state_filter}, {name: timeout, var: timeout}]
    body: {content_type: "application/json", kind: json, fields: [{name: ConsiderWarningAsError, var: consider_warning_as_error}, {name: DefaultServiceTypeHealthPolicy, var: default_service_type_health_policy}, {name: MaxPercentUnhealthyDeployedApplications, var: max_percent_unhealthy_deployed_applications}, {name: ServiceTypeHealthPolicyMap, var: service_type_health_policy_map}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    node_name: $node_name, application_id: $application_id, service_package_name: $service_package_name, api_version: $api_version, events_health_state_filter: $events_health_state_filter, timeout: $timeout, consider_warning_as_error: $consider_warning_as_error, default_service_type_health_policy: $default_service_type_health_policy, max_percent_unhealthy_deployed_applications: $max_percent_unhealthy_deployed_applications, service_type_health_policy_map: $service_type_health_policy_map
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sends a health report on the Service Fabric deployed service package.
#
# POST /Nodes/{nodeName}/$/GetApplications/{applicationId}/$/GetServicePackages/{servicePackageName}/$/ReportHealth
# operationId: ReportDeployedServicePackageHealth
export def "report-deployed-service-package-health" [
  node_name: string
  application_id: string
  service_package_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --immediate: oneof<nothing, bool> # A flag that indicates whether the report should be sent immediately. A health report is sent to a Service Fabric gateway Application, which forwards to the health store. If Immediate is set to true, the report is sent immediately from HTTP Gateway to the health store, regardless of the fabric client settings that the HTTP Gateway Application is using. This is useful for critical reports that should be sent as soon as possible. Depending on timing and other conditions, sending the report may still fail, for example if the HTTP Gateway is closed or the message doesn't reach the Gateway. If Immediate is set to false, the report is sent based on the health client settings from the HTTP Gateway. Therefore, it will be batched according to the HealthReportSendInterval configuration. This is the recommended setting because it allows the health client to optimize health reporting messages to health store as well as health report processing. By default, reports are not sent immediately. (default: false)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --description: string # The description of the health information. It represents free text used to add human readable information about the report. The maximum string length for the description is 4096 characters. If the provided string is longer, it will be automatically truncated. When truncated, the last characters of the description contain a marker "[Truncated]", and total string size is 4096 characters. The presence of the marker indicates to users that truncation occurred. Note that when truncated, the description has less than 4096 characters from the original string.
  health_state: string@health-state-completer # The health state of a Service Fabric entity such as Cluster, Node, Application, Service, Partition, Replica etc.
  property: string # The property of the health information. An entity can have health reports for different properties. The property is a string and not a fixed enumeration to allow the reporter flexibility to categorize the state condition that triggers the report. For example, a reporter with SourceId "LocalWatchdog" can monitor the state of the available disk on a node, so it can report "AvailableDisk" property on that node. The same reporter can monitor the node connectivity, so it can report a property "Connectivity" on the same node. In the health store, these reports are treated as separate health events for the specified node. Together with the SourceId, the property uniquely identifies the health information.
  --remove-when-expired: oneof<nothing, bool> # Value that indicates whether the report is removed from health store when it expires. If set to true, the report is removed from the health store after it expires. If set to false, the report is treated as an error when expired. The value of this property is false by default. When clients report periodically, they should set RemoveWhenExpired false (default). This way, if the reporter has issues (e.g. deadlock) and can't report, the entity is evaluated at error when the health report expires. This flags the entity as being in Error health state.
  --sequence-number: string # The sequence number for this health report as a numeric string. The report sequence number is used by the health store to detect stale reports. If not specified, a sequence number is auto-generated by the health client when a report is added.
  source_id: string # The source name that identifies the client/watchdog/system component that generated the health information.
  --time-to-live-in-milli-seconds: string # The duration for which this health report is valid. This field uses ISO8601 format for specifying the duration. When clients report periodically, they should send reports with higher frequency than time to live. If clients report on transition, they can set the time to live to infinite. When time to live expires, the health event that contains the health information is either removed from health store, if RemoveWhenExpired is true, or evaluated at error, if RemoveWhenExpired false. If not specified, time to live defaults to infinite value. (format: duration)
]: any -> any {
  $in | http-request {
    method: post
    path: "/Nodes/{nodeName}/$/GetApplications/{applicationId}/$/GetServicePackages/{servicePackageName}/$/ReportHealth"
    path_params: [{name: nodeName, var: node_name}, {name: applicationId, var: application_id}, {name: servicePackageName, var: service_package_name}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: Immediate, var: immediate}, {name: timeout, var: timeout}]
    body: {content_type: "application/json", kind: json, fields: [{name: Description, var: description}, {name: HealthState, var: health_state}, {name: Property, var: property}, {name: RemoveWhenExpired, var: remove_when_expired}, {name: SequenceNumber, var: sequence_number}, {name: SourceId, var: source_id}, {name: TimeToLiveInMilliSeconds, var: time_to_live_in_milli_seconds}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    node_name: $node_name, application_id: $application_id, service_package_name: $service_package_name, api_version: $api_version, immediate: $immediate, timeout: $timeout, description: $description, health_state: $health_state, property: $property, remove_when_expired: $remove_when_expired, sequence_number: $sequence_number, source_id: $source_id, time_to_live_in_milli_seconds: $time_to_live_in_milli_seconds
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the list containing the information about service types from the applications deployed on a node in a Service Fabric cluster.
#
# GET /Nodes/{nodeName}/$/GetApplications/{applicationId}/$/GetServiceTypes
# Returns: table<CodePackageName: string, ServiceManifestName: string, ServicePackageActivationId: string, ServiceTypeName: string, Status: string>
# operationId: GetDeployedServiceTypeInfoList
export def "get-deployed-service-type-info-list" [
  node_name: string
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --service-manifest-name: string # The name of the service manifest to filter the list of deployed service type information. If specified, the response will only contain the information about service types that are defined in this service manifest.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/Nodes/{nodeName}/$/GetApplications/{applicationId}/$/GetServiceTypes"
    path_params: [{name: nodeName, var: node_name}, {name: applicationId, var: application_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: ServiceManifestName, var: service_manifest_name}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    node_name: $node_name, application_id: $application_id, api_version: $api_version, service_manifest_name: $service_manifest_name, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the information about a specified service type of the application deployed on a node in a Service Fabric cluster.
#
# GET /Nodes/{nodeName}/$/GetApplications/{applicationId}/$/GetServiceTypes/{serviceTypeName}
# Returns: table<CodePackageName: string, ServiceManifestName: string, ServicePackageActivationId: string, ServiceTypeName: string, Status: string>
# operationId: GetDeployedServiceTypeInfoByName
export def "get-deployed-service-type-info-by-name" [
  node_name: string
  application_id: string
  service_type_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --service-manifest-name: string # The name of the service manifest to filter the list of deployed service type information. If specified, the response will only contain the information about service types that are defined in this service manifest.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/Nodes/{nodeName}/$/GetApplications/{applicationId}/$/GetServiceTypes/{serviceTypeName}"
    path_params: [{name: nodeName, var: node_name}, {name: applicationId, var: application_id}, {name: serviceTypeName, var: service_type_name}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: ServiceManifestName, var: service_manifest_name}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    node_name: $node_name, application_id: $application_id, service_type_name: $service_type_name, api_version: $api_version, service_manifest_name: $service_manifest_name, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sends a health report on the Service Fabric application deployed on a Service Fabric node.
#
# POST /Nodes/{nodeName}/$/GetApplications/{applicationId}/$/ReportHealth
# operationId: ReportDeployedApplicationHealth
export def "report-deployed-application-health" [
  node_name: string
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --immediate: oneof<nothing, bool> # A flag that indicates whether the report should be sent immediately. A health report is sent to a Service Fabric gateway Application, which forwards to the health store. If Immediate is set to true, the report is sent immediately from HTTP Gateway to the health store, regardless of the fabric client settings that the HTTP Gateway Application is using. This is useful for critical reports that should be sent as soon as possible. Depending on timing and other conditions, sending the report may still fail, for example if the HTTP Gateway is closed or the message doesn't reach the Gateway. If Immediate is set to false, the report is sent based on the health client settings from the HTTP Gateway. Therefore, it will be batched according to the HealthReportSendInterval configuration. This is the recommended setting because it allows the health client to optimize health reporting messages to health store as well as health report processing. By default, reports are not sent immediately. (default: false)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --description: string # The description of the health information. It represents free text used to add human readable information about the report. The maximum string length for the description is 4096 characters. If the provided string is longer, it will be automatically truncated. When truncated, the last characters of the description contain a marker "[Truncated]", and total string size is 4096 characters. The presence of the marker indicates to users that truncation occurred. Note that when truncated, the description has less than 4096 characters from the original string.
  health_state: string@health-state-completer # The health state of a Service Fabric entity such as Cluster, Node, Application, Service, Partition, Replica etc.
  property: string # The property of the health information. An entity can have health reports for different properties. The property is a string and not a fixed enumeration to allow the reporter flexibility to categorize the state condition that triggers the report. For example, a reporter with SourceId "LocalWatchdog" can monitor the state of the available disk on a node, so it can report "AvailableDisk" property on that node. The same reporter can monitor the node connectivity, so it can report a property "Connectivity" on the same node. In the health store, these reports are treated as separate health events for the specified node. Together with the SourceId, the property uniquely identifies the health information.
  --remove-when-expired: oneof<nothing, bool> # Value that indicates whether the report is removed from health store when it expires. If set to true, the report is removed from the health store after it expires. If set to false, the report is treated as an error when expired. The value of this property is false by default. When clients report periodically, they should set RemoveWhenExpired false (default). This way, if the reporter has issues (e.g. deadlock) and can't report, the entity is evaluated at error when the health report expires. This flags the entity as being in Error health state.
  --sequence-number: string # The sequence number for this health report as a numeric string. The report sequence number is used by the health store to detect stale reports. If not specified, a sequence number is auto-generated by the health client when a report is added.
  source_id: string # The source name that identifies the client/watchdog/system component that generated the health information.
  --time-to-live-in-milli-seconds: string # The duration for which this health report is valid. This field uses ISO8601 format for specifying the duration. When clients report periodically, they should send reports with higher frequency than time to live. If clients report on transition, they can set the time to live to infinite. When time to live expires, the health event that contains the health information is either removed from health store, if RemoveWhenExpired is true, or evaluated at error, if RemoveWhenExpired false. If not specified, time to live defaults to infinite value. (format: duration)
]: any -> any {
  $in | http-request {
    method: post
    path: "/Nodes/{nodeName}/$/GetApplications/{applicationId}/$/ReportHealth"
    path_params: [{name: nodeName, var: node_name}, {name: applicationId, var: application_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: Immediate, var: immediate}, {name: timeout, var: timeout}]
    body: {content_type: "application/json", kind: json, fields: [{name: Description, var: description}, {name: HealthState, var: health_state}, {name: Property, var: property}, {name: RemoveWhenExpired, var: remove_when_expired}, {name: SequenceNumber, var: sequence_number}, {name: SourceId, var: source_id}, {name: TimeToLiveInMilliSeconds, var: time_to_live_in_milli_seconds}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    node_name: $node_name, application_id: $application_id, api_version: $api_version, immediate: $immediate, timeout: $timeout, description: $description, health_state: $health_state, property: $property, remove_when_expired: $remove_when_expired, sequence_number: $sequence_number, source_id: $source_id, time_to_live_in_milli_seconds: $time_to_live_in_milli_seconds
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the health of a Service Fabric node.
#
# GET /Nodes/{nodeName}/$/GetHealth
# Returns: record<Name: string, AggregatedHealthState: string, HealthEvents: table<IsExpired: bool, LastErrorTransitionAt: string, LastModifiedUtcTimestamp: string, LastOkTransitionAt: string, LastWarningTransitionAt: string, SourceUtcTimestamp: string, Description: string, HealthState: string, Property: string, RemoveWhenExpired: bool, SequenceNumber: string, SourceId: string, TimeToLiveInMilliSeconds: string>, HealthStatistics: record<HealthStateCountList: list<record>>, UnhealthyEvaluations: table<HealthEvaluation: record>>
# operationId: GetNodeHealth
export def "get-node-health" [
  node_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --events-health-state-filter: int # Allows filtering the collection of HealthEvent objects returned based on health state. The possible values for this parameter include integer value of one of the following health states. Only events that match the filter are returned. All events are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these values, obtained using the bitwise 'OR' operator. For example, If the provided value is 6 then all of the events with HealthState value of OK (2) and Warning (4) are returned. - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Nodes/{nodeName}/$/GetHealth"
    path_params: [{name: nodeName, var: node_name}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: EventsHealthStateFilter, var: events_health_state_filter}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    node_name: $node_name, api_version: $api_version, events_health_state_filter: $events_health_state_filter, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the health of a Service Fabric node, by using the specified health policy.
#
# POST /Nodes/{nodeName}/$/GetHealth
# Returns: record<Name: string, AggregatedHealthState: string, HealthEvents: table<IsExpired: bool, LastErrorTransitionAt: string, LastModifiedUtcTimestamp: string, LastOkTransitionAt: string, LastWarningTransitionAt: string, SourceUtcTimestamp: string, Description: string, HealthState: string, Property: string, RemoveWhenExpired: bool, SequenceNumber: string, SourceId: string, TimeToLiveInMilliSeconds: string>, HealthStatistics: record<HealthStateCountList: list<record>>, UnhealthyEvaluations: table<HealthEvaluation: record>>
# operationId: GetNodeHealthUsingPolicy
export def "get-node-health-using-policy" [
  node_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --events-health-state-filter: int # Allows filtering the collection of HealthEvent objects returned based on health state. The possible values for this parameter include integer value of one of the following health states. Only events that match the filter are returned. All events are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these values, obtained using the bitwise 'OR' operator. For example, If the provided value is 6 then all of the events with HealthState value of OK (2) and Warning (4) are returned. - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --application-type-health-policy-map: list # Defines a map with max percentage unhealthy applications for specific application types. Each entry specifies as key the application type name and as value an integer that represents the MaxPercentUnhealthyApplications percentage used to evaluate the applications of the specified application type. The application type health policy map can be used during cluster health evaluation to describe special application types. The application types included in the map are evaluated against the percentage specified in the map, and not with the global MaxPercentUnhealthyApplications defined in the cluster health policy. The applications of application types specified in the map are not counted against the global pool of applications. For example, if some applications of a type are critical, the cluster administrator can add an entry to the map for that application type and assign it a value of 0% (that is, do not tolerate any failures). All other applications can be evaluated with MaxPercentUnhealthyApplications set to 20% to tolerate some failures out of the thousands of application instances. The application type health policy map is used only if the cluster manifest enables application type health evaluation using the configuration entry for HealthManager/EnableApplicationTypeHealthEvaluation. — item shape: {Key: string, Value: int}
  --consider-warning-as-error: oneof<nothing, bool> # Indicates whether warnings are treated with the same severity as errors. (default: false)
  --max-percent-unhealthy-applications: int # The maximum allowed percentage of unhealthy applications before reporting an error. For example, to allow 10% of applications to be unhealthy, this value would be 10. The percentage represents the maximum tolerated percentage of applications that can be unhealthy before the cluster is considered in error. If the percentage is respected but there is at least one unhealthy application, the health is evaluated as Warning. This is calculated by dividing the number of unhealthy applications over the total number of application instances in the cluster, excluding applications of application types that are included in the ApplicationTypeHealthPolicyMap. The computation rounds up to tolerate one failure on small numbers of applications. Default percentage is zero. (default: 0)
  --max-percent-unhealthy-nodes: int # The maximum allowed percentage of unhealthy nodes before reporting an error. For example, to allow 10% of nodes to be unhealthy, this value would be 10. The percentage represents the maximum tolerated percentage of nodes that can be unhealthy before the cluster is considered in error. If the percentage is respected but there is at least one unhealthy node, the health is evaluated as Warning. The percentage is calculated by dividing the number of unhealthy nodes over the total number of nodes in the cluster. The computation rounds up to tolerate one failure on small numbers of nodes. Default percentage is zero. In large clusters, some nodes will always be down or out for repairs, so this percentage should be configured to tolerate that. (default: 0)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Nodes/{nodeName}/$/GetHealth"
    path_params: [{name: nodeName, var: node_name}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: EventsHealthStateFilter, var: events_health_state_filter}, {name: timeout, var: timeout}]
    body: {content_type: "application/json", kind: json, fields: [{name: ApplicationTypeHealthPolicyMap, var: application_type_health_policy_map}, {name: ConsiderWarningAsError, var: consider_warning_as_error}, {name: MaxPercentUnhealthyApplications, var: max_percent_unhealthy_applications}, {name: MaxPercentUnhealthyNodes, var: max_percent_unhealthy_nodes}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    node_name: $node_name, api_version: $api_version, events_health_state_filter: $events_health_state_filter, timeout: $timeout, application_type_health_policy_map: $application_type_health_policy_map, consider_warning_as_error: $consider_warning_as_error, max_percent_unhealthy_applications: $max_percent_unhealthy_applications, max_percent_unhealthy_nodes: $max_percent_unhealthy_nodes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the load information of a Service Fabric node.
#
# GET /Nodes/{nodeName}/$/GetLoadInformation
# Returns: record<NodeLoadMetricInformation: table<BufferedNodeCapacityRemaining: string, CurrentNodeLoad: string, IsCapacityViolation: bool, Name: string, NodeBufferedCapacity: string, NodeCapacity: string, NodeCapacityRemaining: string, NodeLoad: string, NodeRemainingBufferedCapacity: string, NodeRemainingCapacity: string, PlannedNodeLoadRemoval: string>, NodeName: string>
# operationId: GetNodeLoadInfo
export def "get-node-load-info" [
  node_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Nodes/{nodeName}/$/GetLoadInformation"
    path_params: [{name: nodeName, var: node_name}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    node_name: $node_name, api_version: $api_version, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the details of replica deployed on a Service Fabric node.
#
# GET /Nodes/{nodeName}/$/GetPartitions/{partitionId}/$/GetReplicas
# Discriminator (response): ServiceKind
# Returns: record<CurrentServiceOperation: string, CurrentServiceOperationStartTimeUtc: string, PartitionId: string, ReportedLoad: table<CurrentValue: string, LastReportedUtc: string, Name: string, Value: int>, ServiceKind: string, ServiceName: string>
# operationId: GetDeployedServiceReplicaDetailInfoByPartitionId
export def "get-deployed-service-replica-detail-info-by-partition-id" [
  node_name: string
  partition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Nodes/{nodeName}/$/GetPartitions/{partitionId}/$/GetReplicas"
    path_params: [{name: nodeName, var: node_name}, {name: partitionId, var: partition_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    node_name: $node_name, partition_id: $partition_id, api_version: $api_version, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a service replica running on a node.
#
# POST /Nodes/{nodeName}/$/GetPartitions/{partitionId}/$/GetReplicas/{replicaId}/$/Delete
# operationId: RemoveReplica
export def "remove-replica" [
  node_name: string
  partition_id: string
  replica_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --force-remove: oneof<nothing, bool> # Remove a Service Fabric application or service forcefully without going through the graceful shutdown sequence. This parameter can be used to forcefully delete an application or service for which delete is timing out due to issues in the service code that prevents graceful close of replicas.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> any {
  http-request {
    method: post
    path: "/Nodes/{nodeName}/$/GetPartitions/{partitionId}/$/GetReplicas/{replicaId}/$/Delete"
    path_params: [{name: nodeName, var: node_name}, {name: partitionId, var: partition_id}, {name: replicaId, var: replica_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: ForceRemove, var: force_remove}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    node_name: $node_name, partition_id: $partition_id, replica_id: $replica_id, api_version: $api_version, force_remove: $force_remove, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the details of replica deployed on a Service Fabric node.
#
# GET /Nodes/{nodeName}/$/GetPartitions/{partitionId}/$/GetReplicas/{replicaId}/$/GetDetail
# Discriminator (response): ServiceKind
# Returns: record<CurrentServiceOperation: string, CurrentServiceOperationStartTimeUtc: string, PartitionId: string, ReportedLoad: table<CurrentValue: string, LastReportedUtc: string, Name: string, Value: int>, ServiceKind: string, ServiceName: string>
# operationId: GetDeployedServiceReplicaDetailInfo
export def "get-deployed-service-replica-detail-info" [
  node_name: string
  partition_id: string
  replica_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Nodes/{nodeName}/$/GetPartitions/{partitionId}/$/GetReplicas/{replicaId}/$/GetDetail"
    path_params: [{name: nodeName, var: node_name}, {name: partitionId, var: partition_id}, {name: replicaId, var: replica_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    node_name: $node_name, partition_id: $partition_id, replica_id: $replica_id, api_version: $api_version, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Restarts a service replica of a persisted service running on a node.
#
# POST /Nodes/{nodeName}/$/GetPartitions/{partitionId}/$/GetReplicas/{replicaId}/$/Restart
# operationId: RestartReplica
export def "restart-replica" [
  node_name: string
  partition_id: string
  replica_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> any {
  http-request {
    method: post
    path: "/Nodes/{nodeName}/$/GetPartitions/{partitionId}/$/GetReplicas/{replicaId}/$/Restart"
    path_params: [{name: nodeName, var: node_name}, {name: partitionId, var: partition_id}, {name: replicaId, var: replica_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    node_name: $node_name, partition_id: $partition_id, replica_id: $replica_id, api_version: $api_version, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Notifies Service Fabric that the persisted state on a node has been permanently removed or lost.
#
# POST /Nodes/{nodeName}/$/RemoveNodeState
# operationId: RemoveNodeState
export def "remove-node-state" [
  node_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> any {
  http-request {
    method: post
    path: "/Nodes/{nodeName}/$/RemoveNodeState"
    path_params: [{name: nodeName, var: node_name}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    node_name: $node_name, api_version: $api_version, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sends a health report on the Service Fabric node.
#
# POST /Nodes/{nodeName}/$/ReportHealth
# operationId: ReportNodeHealth
export def "report-node-health" [
  node_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --immediate: oneof<nothing, bool> # A flag that indicates whether the report should be sent immediately. A health report is sent to a Service Fabric gateway Application, which forwards to the health store. If Immediate is set to true, the report is sent immediately from HTTP Gateway to the health store, regardless of the fabric client settings that the HTTP Gateway Application is using. This is useful for critical reports that should be sent as soon as possible. Depending on timing and other conditions, sending the report may still fail, for example if the HTTP Gateway is closed or the message doesn't reach the Gateway. If Immediate is set to false, the report is sent based on the health client settings from the HTTP Gateway. Therefore, it will be batched according to the HealthReportSendInterval configuration. This is the recommended setting because it allows the health client to optimize health reporting messages to health store as well as health report processing. By default, reports are not sent immediately. (default: false)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --description: string # The description of the health information. It represents free text used to add human readable information about the report. The maximum string length for the description is 4096 characters. If the provided string is longer, it will be automatically truncated. When truncated, the last characters of the description contain a marker "[Truncated]", and total string size is 4096 characters. The presence of the marker indicates to users that truncation occurred. Note that when truncated, the description has less than 4096 characters from the original string.
  health_state: string@health-state-completer # The health state of a Service Fabric entity such as Cluster, Node, Application, Service, Partition, Replica etc.
  property: string # The property of the health information. An entity can have health reports for different properties. The property is a string and not a fixed enumeration to allow the reporter flexibility to categorize the state condition that triggers the report. For example, a reporter with SourceId "LocalWatchdog" can monitor the state of the available disk on a node, so it can report "AvailableDisk" property on that node. The same reporter can monitor the node connectivity, so it can report a property "Connectivity" on the same node. In the health store, these reports are treated as separate health events for the specified node. Together with the SourceId, the property uniquely identifies the health information.
  --remove-when-expired: oneof<nothing, bool> # Value that indicates whether the report is removed from health store when it expires. If set to true, the report is removed from the health store after it expires. If set to false, the report is treated as an error when expired. The value of this property is false by default. When clients report periodically, they should set RemoveWhenExpired false (default). This way, if the reporter has issues (e.g. deadlock) and can't report, the entity is evaluated at error when the health report expires. This flags the entity as being in Error health state.
  --sequence-number: string # The sequence number for this health report as a numeric string. The report sequence number is used by the health store to detect stale reports. If not specified, a sequence number is auto-generated by the health client when a report is added.
  source_id: string # The source name that identifies the client/watchdog/system component that generated the health information.
  --time-to-live-in-milli-seconds: string # The duration for which this health report is valid. This field uses ISO8601 format for specifying the duration. When clients report periodically, they should send reports with higher frequency than time to live. If clients report on transition, they can set the time to live to infinite. When time to live expires, the health event that contains the health information is either removed from health store, if RemoveWhenExpired is true, or evaluated at error, if RemoveWhenExpired false. If not specified, time to live defaults to infinite value. (format: duration)
]: any -> any {
  $in | http-request {
    method: post
    path: "/Nodes/{nodeName}/$/ReportHealth"
    path_params: [{name: nodeName, var: node_name}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: Immediate, var: immediate}, {name: timeout, var: timeout}]
    body: {content_type: "application/json", kind: json, fields: [{name: Description, var: description}, {name: HealthState, var: health_state}, {name: Property, var: property}, {name: RemoveWhenExpired, var: remove_when_expired}, {name: SequenceNumber, var: sequence_number}, {name: SourceId, var: source_id}, {name: TimeToLiveInMilliSeconds, var: time_to_live_in_milli_seconds}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    node_name: $node_name, api_version: $api_version, immediate: $immediate, timeout: $timeout, description: $description, health_state: $health_state, property: $property, remove_when_expired: $remove_when_expired, sequence_number: $sequence_number, source_id: $source_id, time_to_live_in_milli_seconds: $time_to_live_in_milli_seconds
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Restarts a Service Fabric cluster node.
#
# POST /Nodes/{nodeName}/$/Restart
# operationId: RestartNode
export def "restart-node" [
  node_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --create-fabric-dump: string@create-fabric-dump-completer # Specify True to create a dump of the fabric node process. This is case-sensitive. (default: False)
  node_instance_id: string # The instance ID of the target node. If instance ID is specified the node is restarted only if it matches with the current instance of the node. A default value of "0" would match any instance ID. The instance ID can be obtained using get node query. (default: 0)
]: any -> any {
  $in | http-request {
    method: post
    path: "/Nodes/{nodeName}/$/Restart"
    path_params: [{name: nodeName, var: node_name}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: timeout, var: timeout}]
    body: {content_type: "application/json", kind: json, fields: [{name: CreateFabricDump, var: create_fabric_dump}, {name: NodeInstanceId, var: node_instance_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    node_name: $node_name, api_version: $api_version, timeout: $timeout, create_fabric_dump: $create_fabric_dump, node_instance_id: $node_instance_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the information about a Service Fabric partition.
#
# GET /Partitions/{partitionId}
# Discriminator (response): ServiceKind
# Returns: record<HealthState: string, PartitionInformation: record<Id: string, ServicePartitionKind: string>, PartitionStatus: string, ServiceKind: string>
# operationId: GetPartitionInfo
export def "get-partition-info" [
  partition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Partitions/{partitionId}"
    path_params: [{name: partitionId, var: partition_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    partition_id: $partition_id, api_version: $api_version, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Triggers backup of the partition's state.
#
# POST /Partitions/{partitionId}/$/Backup
# operationId: BackupPartition
export def "backup-partition" [
  partition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --backup-timeout: int # Specifies the maximum amount of time, in minutes, to wait for the backup operation to complete. Post that, the operation completes with timeout error. However, in certain corner cases it could be that though the operation returns back timeout, the backup actually goes through. In case of timeout error, its recommended to invoke this operation again with a greater timeout value. The default value for the same is 10 minutes. (default: 10)
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --backup-storage: any # Describes the parameters for the backup storage. — shape: {FriendlyName?: string, StorageKind: "Invalid"|"FileShare"|"AzureBlobStore"}
]: any -> any {
  $in | http-request {
    method: post
    path: "/Partitions/{partitionId}/$/Backup"
    path_params: [{name: partitionId, var: partition_id}]
    query: [{name: BackupTimeout, var: backup_timeout}, {name: api-version, var: api_version, required: true, default: "6.4"}, {name: timeout, var: timeout}]
    body: {content_type: "application/json", kind: json, fields: [{name: BackupStorage, var: backup_storage}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    partition_id: $partition_id, backup_timeout: $backup_timeout, api_version: $api_version, timeout: $timeout, backup_storage: $backup_storage
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disables periodic backup of Service Fabric partition which was previously enabled.
#
# POST /Partitions/{partitionId}/$/DisableBackup
# operationId: DisablePartitionBackup
export def "disable-partition-backup" [
  partition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --clean-backup: oneof<nothing, bool> # Boolean flag to delete backups. It can be set to true for deleting all the backups which were created for the backup entity that is getting disabled for backup.
]: any -> any {
  $in | http-request {
    method: post
    path: "/Partitions/{partitionId}/$/DisableBackup"
    path_params: [{name: partitionId, var: partition_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.4"}, {name: timeout, var: timeout}]
    body: {content_type: "application/json", kind: json, fields: [{name: CleanBackup, var: clean_backup, required: true}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    partition_id: $partition_id, api_version: $api_version, timeout: $timeout, clean_backup: $clean_backup
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enables periodic backup of the stateful persisted partition.
#
# POST /Partitions/{partitionId}/$/EnableBackup
# operationId: EnablePartitionBackup
export def "enable-partition-backup" [
  partition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  backup_policy_name: string # Name of the backup policy to be used for enabling periodic backups.
]: any -> any {
  $in | http-request {
    method: post
    path: "/Partitions/{partitionId}/$/EnableBackup"
    path_params: [{name: partitionId, var: partition_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.4"}, {name: timeout, var: timeout}]
    body: {content_type: "application/json", kind: json, fields: [{name: BackupPolicyName, var: backup_policy_name}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    partition_id: $partition_id, api_version: $api_version, timeout: $timeout, backup_policy_name: $backup_policy_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the partition backup configuration information
#
# GET /Partitions/{partitionId}/$/GetBackupConfigurationInfo
# Returns: record<PartitionId: string, ServiceName: string, Kind: string, PolicyInheritedFrom: string, PolicyName: string, SuspensionInfo: record<IsSuspended: bool, SuspensionInheritedFrom: string>>
# operationId: GetPartitionBackupConfigurationInfo
export def "get-partition-backup-configuration-info" [
  partition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Partitions/{partitionId}/$/GetBackupConfigurationInfo"
    path_params: [{name: partitionId, var: partition_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.4"}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    partition_id: $partition_id, api_version: $api_version, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets details for the latest backup triggered for this partition.
#
# GET /Partitions/{partitionId}/$/GetBackupProgress
# Returns: record<BackupId: string, BackupLocation: string, BackupState: string, EpochOfLastBackupRecord: record<ConfigurationVersion: string, DataLossVersion: string>, FailureError: record<Code: string, Message: string>, LsnOfLastBackupRecord: string, TimeStampUtc: string>
# operationId: GetPartitionBackupProgress
export def "get-partition-backup-progress" [
  partition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Partitions/{partitionId}/$/GetBackupProgress"
    path_params: [{name: partitionId, var: partition_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.4"}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    partition_id: $partition_id, api_version: $api_version, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the list of backups available for the specified partition.
#
# GET /Partitions/{partitionId}/$/GetBackups
# Returns: record<ContinuationToken: string, Items: table<ApplicationName: string, BackupChainId: string, BackupId: string, BackupLocation: string, BackupType: string, CreationTimeUtc: string, EpochOfLastBackupRecord: record, FailureError: record, LsnOfLastBackupRecord: string, PartitionInformation: record, ServiceManifestVersion: string, ServiceName: string>>
# operationId: GetPartitionBackupList
export def "get-partition-backup-list" [
  partition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --latest: oneof<nothing, bool> # Specifies whether to get only the most recent backup available for a partition for the specified time range. (default: false)
  --start-date-time-filter: string # Specify the start date time from which to enumerate backups, in datetime format. The date time must be specified in ISO8601 format. This is an optional parameter. If not specified, all backups from the beginning are enumerated. (format: date-time)
  --end-date-time-filter: string # Specify the end date time till which to enumerate backups, in datetime format. The date time must be specified in ISO8601 format. This is an optional parameter. If not specified, enumeration is done till the most recent backup. (format: date-time)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Partitions/{partitionId}/$/GetBackups"
    path_params: [{name: partitionId, var: partition_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.4"}, {name: timeout, var: timeout}, {name: Latest, var: latest}, {name: StartDateTimeFilter, var: start_date_time_filter}, {name: EndDateTimeFilter, var: end_date_time_filter}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    partition_id: $partition_id, api_version: $api_version, timeout: $timeout, latest: $latest, start_date_time_filter: $start_date_time_filter, end_date_time_filter: $end_date_time_filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the health of the specified Service Fabric partition.
#
# GET /Partitions/{partitionId}/$/GetHealth
# Returns: record<PartitionId: string, ReplicaHealthStates: table<PartitionId: string, ServiceKind: string, AggregatedHealthState: string>, AggregatedHealthState: string, HealthEvents: table<IsExpired: bool, LastErrorTransitionAt: string, LastModifiedUtcTimestamp: string, LastOkTransitionAt: string, LastWarningTransitionAt: string, SourceUtcTimestamp: string, Description: string, HealthState: string, Property: string, RemoveWhenExpired: bool, SequenceNumber: string, SourceId: string, TimeToLiveInMilliSeconds: string>, HealthStatistics: record<HealthStateCountList: list<record>>, UnhealthyEvaluations: table<HealthEvaluation: record>>
# operationId: GetPartitionHealth
export def "get-partition-health" [
  partition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --events-health-state-filter: int # Allows filtering the collection of HealthEvent objects returned based on health state. The possible values for this parameter include integer value of one of the following health states. Only events that match the filter are returned. All events are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these values, obtained using the bitwise 'OR' operator. For example, If the provided value is 6 then all of the events with HealthState value of OK (2) and Warning (4) are returned. - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --replicas-health-state-filter: int # Allows filtering the collection of ReplicaHealthState objects on the partition. The value can be obtained from members or bitwise operations on members of HealthStateFilter. Only replicas that match the filter will be returned. All replicas will be used to evaluate the aggregated health state. If not specified, all entries will be returned.The state values are flag-based enumeration, so the value could be a combination of these values obtained using bitwise 'OR' operator. For example, If the provided value is 6 then all of the events with HealthState value of OK (2) and Warning (4) will be returned. The possible values for this parameter include integer value of one of the following health states. - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --exclude-health-statistics: oneof<nothing, bool> # Indicates whether the health statistics should be returned as part of the query result. False by default. The statistics show the number of children entities in health state Ok, Warning, and Error. (default: false)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Partitions/{partitionId}/$/GetHealth"
    path_params: [{name: partitionId, var: partition_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: EventsHealthStateFilter, var: events_health_state_filter}, {name: ReplicasHealthStateFilter, var: replicas_health_state_filter}, {name: ExcludeHealthStatistics, var: exclude_health_statistics}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    partition_id: $partition_id, api_version: $api_version, events_health_state_filter: $events_health_state_filter, replicas_health_state_filter: $replicas_health_state_filter, exclude_health_statistics: $exclude_health_statistics, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the health of the specified Service Fabric partition, by using the specified health policy.
#
# POST /Partitions/{partitionId}/$/GetHealth
# Returns: record<PartitionId: string, ReplicaHealthStates: table<PartitionId: string, ServiceKind: string, AggregatedHealthState: string>, AggregatedHealthState: string, HealthEvents: table<IsExpired: bool, LastErrorTransitionAt: string, LastModifiedUtcTimestamp: string, LastOkTransitionAt: string, LastWarningTransitionAt: string, SourceUtcTimestamp: string, Description: string, HealthState: string, Property: string, RemoveWhenExpired: bool, SequenceNumber: string, SourceId: string, TimeToLiveInMilliSeconds: string>, HealthStatistics: record<HealthStateCountList: list<record>>, UnhealthyEvaluations: table<HealthEvaluation: record>>
# operationId: GetPartitionHealthUsingPolicy
export def "get-partition-health-using-policy" [
  partition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --events-health-state-filter: int # Allows filtering the collection of HealthEvent objects returned based on health state. The possible values for this parameter include integer value of one of the following health states. Only events that match the filter are returned. All events are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these values, obtained using the bitwise 'OR' operator. For example, If the provided value is 6 then all of the events with HealthState value of OK (2) and Warning (4) are returned. - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --replicas-health-state-filter: int # Allows filtering the collection of ReplicaHealthState objects on the partition. The value can be obtained from members or bitwise operations on members of HealthStateFilter. Only replicas that match the filter will be returned. All replicas will be used to evaluate the aggregated health state. If not specified, all entries will be returned.The state values are flag-based enumeration, so the value could be a combination of these values obtained using bitwise 'OR' operator. For example, If the provided value is 6 then all of the events with HealthState value of OK (2) and Warning (4) will be returned. The possible values for this parameter include integer value of one of the following health states. - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --exclude-health-statistics: oneof<nothing, bool> # Indicates whether the health statistics should be returned as part of the query result. False by default. The statistics show the number of children entities in health state Ok, Warning, and Error. (default: false)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --consider-warning-as-error: oneof<nothing, bool> # Indicates whether warnings are treated with the same severity as errors. (default: false)
  --default-service-type-health-policy: any # Represents the health policy used to evaluate the health of services belonging to a service type. — shape: {MaxPercentUnhealthyPartitionsPerService?: int, MaxPercentUnhealthyReplicasPerPartition?: int, MaxPercentUnhealthyServices?: int}
  --max-percent-unhealthy-deployed-applications: int # The maximum allowed percentage of unhealthy deployed applications. Allowed values are Byte values from zero to 100. The percentage represents the maximum tolerated percentage of deployed applications that can be unhealthy before the application is considered in error. This is calculated by dividing the number of unhealthy deployed applications over the number of nodes where the application is currently deployed on in the cluster. The computation rounds up to tolerate one failure on small numbers of nodes. Default percentage is zero. (default: 0)
  --service-type-health-policy-map: list # Defines a ServiceTypeHealthPolicy per service type name. The entries in the map replace the default service type health policy for each specified service type. For example, in an application that contains both a stateless gateway service type and a stateful engine service type, the health policies for the stateless and stateful services can be configured differently. With policy per service type, there's more granular control of the health of the service. If no policy is specified for a service type name, the DefaultServiceTypeHealthPolicy is used for evaluation. — item shape: {Key: string, Value: any}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Partitions/{partitionId}/$/GetHealth"
    path_params: [{name: partitionId, var: partition_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: EventsHealthStateFilter, var: events_health_state_filter}, {name: ReplicasHealthStateFilter, var: replicas_health_state_filter}, {name: ExcludeHealthStatistics, var: exclude_health_statistics}, {name: timeout, var: timeout}]
    body: {content_type: "application/json", kind: json, fields: [{name: ConsiderWarningAsError, var: consider_warning_as_error}, {name: DefaultServiceTypeHealthPolicy, var: default_service_type_health_policy}, {name: MaxPercentUnhealthyDeployedApplications, var: max_percent_unhealthy_deployed_applications}, {name: ServiceTypeHealthPolicyMap, var: service_type_health_policy_map}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    partition_id: $partition_id, api_version: $api_version, events_health_state_filter: $events_health_state_filter, replicas_health_state_filter: $replicas_health_state_filter, exclude_health_statistics: $exclude_health_statistics, timeout: $timeout, consider_warning_as_error: $consider_warning_as_error, default_service_type_health_policy: $default_service_type_health_policy, max_percent_unhealthy_deployed_applications: $max_percent_unhealthy_deployed_applications, service_type_health_policy_map: $service_type_health_policy_map
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the load information of the specified Service Fabric partition.
#
# GET /Partitions/{partitionId}/$/GetLoadInformation
# Returns: record<PartitionId: string, PrimaryLoadMetricReports: table<CurrentValue: string, LastReportedUtc: string, Name: string, Value: string>, SecondaryLoadMetricReports: table<CurrentValue: string, LastReportedUtc: string, Name: string, Value: string>>
# operationId: GetPartitionLoadInformation
export def "get-partition-load-information" [
  partition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Partitions/{partitionId}/$/GetLoadInformation"
    path_params: [{name: partitionId, var: partition_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    partition_id: $partition_id, api_version: $api_version, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the information about replicas of a Service Fabric service partition.
#
# GET /Partitions/{partitionId}/$/GetReplicas
# Returns: record<ContinuationToken: string, Items: table<Address: string, HealthState: string, LastInBuildDurationInSeconds: string, NodeName: string, ReplicaStatus: string, ServiceKind: string>>
# operationId: GetReplicaInfoList
export def "get-replica-info-list" [
  partition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --continuation-token: string # The continuation token parameter is used to obtain next set of results. A continuation token with a non-empty value is included in the response of the API when the results from the system do not fit in a single response. When this value is passed to the next API call, the API returns next set of results. If there are no further results, then the continuation token does not contain a value. The value of this parameter should not be URL encoded.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Partitions/{partitionId}/$/GetReplicas"
    path_params: [{name: partitionId, var: partition_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: ContinuationToken, var: continuation_token}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    partition_id: $partition_id, api_version: $api_version, continuation_token: $continuation_token, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the information about a replica of a Service Fabric partition.
#
# GET /Partitions/{partitionId}/$/GetReplicas/{replicaId}
# Discriminator (response): ServiceKind
# Returns: record<Address: string, HealthState: string, LastInBuildDurationInSeconds: string, NodeName: string, ReplicaStatus: string, ServiceKind: string>
# operationId: GetReplicaInfo
export def "get-replica-info" [
  partition_id: string
  replica_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Partitions/{partitionId}/$/GetReplicas/{replicaId}"
    path_params: [{name: partitionId, var: partition_id}, {name: replicaId, var: replica_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    partition_id: $partition_id, replica_id: $replica_id, api_version: $api_version, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the health of a Service Fabric stateful service replica or stateless service instance.
#
# GET /Partitions/{partitionId}/$/GetReplicas/{replicaId}/$/GetHealth
# Discriminator (response): ServiceKind
# Returns: record<PartitionId: string, ServiceKind: string, AggregatedHealthState: string, HealthEvents: table<IsExpired: bool, LastErrorTransitionAt: string, LastModifiedUtcTimestamp: string, LastOkTransitionAt: string, LastWarningTransitionAt: string, SourceUtcTimestamp: string, Description: string, HealthState: string, Property: string, RemoveWhenExpired: bool, SequenceNumber: string, SourceId: string, TimeToLiveInMilliSeconds: string>, HealthStatistics: record<HealthStateCountList: list<record>>, UnhealthyEvaluations: table<HealthEvaluation: record>>
# operationId: GetReplicaHealth
export def "get-replica-health" [
  partition_id: string
  replica_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --events-health-state-filter: int # Allows filtering the collection of HealthEvent objects returned based on health state. The possible values for this parameter include integer value of one of the following health states. Only events that match the filter are returned. All events are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these values, obtained using the bitwise 'OR' operator. For example, If the provided value is 6 then all of the events with HealthState value of OK (2) and Warning (4) are returned. - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Partitions/{partitionId}/$/GetReplicas/{replicaId}/$/GetHealth"
    path_params: [{name: partitionId, var: partition_id}, {name: replicaId, var: replica_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: EventsHealthStateFilter, var: events_health_state_filter}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    partition_id: $partition_id, replica_id: $replica_id, api_version: $api_version, events_health_state_filter: $events_health_state_filter, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the health of a Service Fabric stateful service replica or stateless service instance using the specified policy.
#
# POST /Partitions/{partitionId}/$/GetReplicas/{replicaId}/$/GetHealth
# Discriminator (response): ServiceKind
# Returns: record<PartitionId: string, ServiceKind: string, AggregatedHealthState: string, HealthEvents: table<IsExpired: bool, LastErrorTransitionAt: string, LastModifiedUtcTimestamp: string, LastOkTransitionAt: string, LastWarningTransitionAt: string, SourceUtcTimestamp: string, Description: string, HealthState: string, Property: string, RemoveWhenExpired: bool, SequenceNumber: string, SourceId: string, TimeToLiveInMilliSeconds: string>, HealthStatistics: record<HealthStateCountList: list<record>>, UnhealthyEvaluations: table<HealthEvaluation: record>>
# operationId: GetReplicaHealthUsingPolicy
export def "get-replica-health-using-policy" [
  partition_id: string
  replica_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --events-health-state-filter: int # Allows filtering the collection of HealthEvent objects returned based on health state. The possible values for this parameter include integer value of one of the following health states. Only events that match the filter are returned. All events are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these values, obtained using the bitwise 'OR' operator. For example, If the provided value is 6 then all of the events with HealthState value of OK (2) and Warning (4) are returned. - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --consider-warning-as-error: oneof<nothing, bool> # Indicates whether warnings are treated with the same severity as errors. (default: false)
  --default-service-type-health-policy: any # Represents the health policy used to evaluate the health of services belonging to a service type. — shape: {MaxPercentUnhealthyPartitionsPerService?: int, MaxPercentUnhealthyReplicasPerPartition?: int, MaxPercentUnhealthyServices?: int}
  --max-percent-unhealthy-deployed-applications: int # The maximum allowed percentage of unhealthy deployed applications. Allowed values are Byte values from zero to 100. The percentage represents the maximum tolerated percentage of deployed applications that can be unhealthy before the application is considered in error. This is calculated by dividing the number of unhealthy deployed applications over the number of nodes where the application is currently deployed on in the cluster. The computation rounds up to tolerate one failure on small numbers of nodes. Default percentage is zero. (default: 0)
  --service-type-health-policy-map: list # Defines a ServiceTypeHealthPolicy per service type name. The entries in the map replace the default service type health policy for each specified service type. For example, in an application that contains both a stateless gateway service type and a stateful engine service type, the health policies for the stateless and stateful services can be configured differently. With policy per service type, there's more granular control of the health of the service. If no policy is specified for a service type name, the DefaultServiceTypeHealthPolicy is used for evaluation. — item shape: {Key: string, Value: any}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Partitions/{partitionId}/$/GetReplicas/{replicaId}/$/GetHealth"
    path_params: [{name: partitionId, var: partition_id}, {name: replicaId, var: replica_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: EventsHealthStateFilter, var: events_health_state_filter}, {name: timeout, var: timeout}]
    body: {content_type: "application/json", kind: json, fields: [{name: ConsiderWarningAsError, var: consider_warning_as_error}, {name: DefaultServiceTypeHealthPolicy, var: default_service_type_health_policy}, {name: MaxPercentUnhealthyDeployedApplications, var: max_percent_unhealthy_deployed_applications}, {name: ServiceTypeHealthPolicyMap, var: service_type_health_policy_map}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    partition_id: $partition_id, replica_id: $replica_id, api_version: $api_version, events_health_state_filter: $events_health_state_filter, timeout: $timeout, consider_warning_as_error: $consider_warning_as_error, default_service_type_health_policy: $default_service_type_health_policy, max_percent_unhealthy_deployed_applications: $max_percent_unhealthy_deployed_applications, service_type_health_policy_map: $service_type_health_policy_map
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sends a health report on the Service Fabric replica.
#
# POST /Partitions/{partitionId}/$/GetReplicas/{replicaId}/$/ReportHealth
# operationId: ReportReplicaHealth
export def "report-replica-health" [
  partition_id: string
  replica_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --service-kind: string@service-kind-completer-1 # The kind of service replica (Stateless or Stateful) for which the health is being reported. Following are the possible values. (required, default: Stateful)
  --immediate: oneof<nothing, bool> # A flag that indicates whether the report should be sent immediately. A health report is sent to a Service Fabric gateway Application, which forwards to the health store. If Immediate is set to true, the report is sent immediately from HTTP Gateway to the health store, regardless of the fabric client settings that the HTTP Gateway Application is using. This is useful for critical reports that should be sent as soon as possible. Depending on timing and other conditions, sending the report may still fail, for example if the HTTP Gateway is closed or the message doesn't reach the Gateway. If Immediate is set to false, the report is sent based on the health client settings from the HTTP Gateway. Therefore, it will be batched according to the HealthReportSendInterval configuration. This is the recommended setting because it allows the health client to optimize health reporting messages to health store as well as health report processing. By default, reports are not sent immediately. (default: false)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --description: string # The description of the health information. It represents free text used to add human readable information about the report. The maximum string length for the description is 4096 characters. If the provided string is longer, it will be automatically truncated. When truncated, the last characters of the description contain a marker "[Truncated]", and total string size is 4096 characters. The presence of the marker indicates to users that truncation occurred. Note that when truncated, the description has less than 4096 characters from the original string.
  health_state: string@health-state-completer # The health state of a Service Fabric entity such as Cluster, Node, Application, Service, Partition, Replica etc.
  property: string # The property of the health information. An entity can have health reports for different properties. The property is a string and not a fixed enumeration to allow the reporter flexibility to categorize the state condition that triggers the report. For example, a reporter with SourceId "LocalWatchdog" can monitor the state of the available disk on a node, so it can report "AvailableDisk" property on that node. The same reporter can monitor the node connectivity, so it can report a property "Connectivity" on the same node. In the health store, these reports are treated as separate health events for the specified node. Together with the SourceId, the property uniquely identifies the health information.
  --remove-when-expired: oneof<nothing, bool> # Value that indicates whether the report is removed from health store when it expires. If set to true, the report is removed from the health store after it expires. If set to false, the report is treated as an error when expired. The value of this property is false by default. When clients report periodically, they should set RemoveWhenExpired false (default). This way, if the reporter has issues (e.g. deadlock) and can't report, the entity is evaluated at error when the health report expires. This flags the entity as being in Error health state.
  --sequence-number: string # The sequence number for this health report as a numeric string. The report sequence number is used by the health store to detect stale reports. If not specified, a sequence number is auto-generated by the health client when a report is added.
  source_id: string # The source name that identifies the client/watchdog/system component that generated the health information.
  --time-to-live-in-milli-seconds: string # The duration for which this health report is valid. This field uses ISO8601 format for specifying the duration. When clients report periodically, they should send reports with higher frequency than time to live. If clients report on transition, they can set the time to live to infinite. When time to live expires, the health event that contains the health information is either removed from health store, if RemoveWhenExpired is true, or evaluated at error, if RemoveWhenExpired false. If not specified, time to live defaults to infinite value. (format: duration)
]: any -> any {
  $in | http-request {
    method: post
    path: "/Partitions/{partitionId}/$/GetReplicas/{replicaId}/$/ReportHealth"
    path_params: [{name: partitionId, var: partition_id}, {name: replicaId, var: replica_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: ServiceKind, var: service_kind, required: true, default: Stateful}, {name: Immediate, var: immediate}, {name: timeout, var: timeout}]
    body: {content_type: "application/json", kind: json, fields: [{name: Description, var: description}, {name: HealthState, var: health_state}, {name: Property, var: property}, {name: RemoveWhenExpired, var: remove_when_expired}, {name: SequenceNumber, var: sequence_number}, {name: SourceId, var: source_id}, {name: TimeToLiveInMilliSeconds, var: time_to_live_in_milli_seconds}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    partition_id: $partition_id, replica_id: $replica_id, api_version: $api_version, service_kind: $service_kind, immediate: $immediate, timeout: $timeout, description: $description, health_state: $health_state, property: $property, remove_when_expired: $remove_when_expired, sequence_number: $sequence_number, source_id: $source_id, time_to_live_in_milli_seconds: $time_to_live_in_milli_seconds
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets details for the latest restore operation triggered for this partition.
#
# GET /Partitions/{partitionId}/$/GetRestoreProgress
# Returns: record<FailureError: record<Code: string, Message: string>, RestoreState: string, RestoredEpoch: record<ConfigurationVersion: string, DataLossVersion: string>, RestoredLsn: string, TimeStampUtc: string>
# operationId: GetPartitionRestoreProgress
export def "get-partition-restore-progress" [
  partition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Partitions/{partitionId}/$/GetRestoreProgress"
    path_params: [{name: partitionId, var: partition_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.4"}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    partition_id: $partition_id, api_version: $api_version, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the name of the Service Fabric service for a partition.
#
# GET /Partitions/{partitionId}/$/GetServiceName
# Returns: record<Id: string, Name: string>
# operationId: GetServiceNameInfo
export def "get-service-name-info" [
  partition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Partitions/{partitionId}/$/GetServiceName"
    path_params: [{name: partitionId, var: partition_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    partition_id: $partition_id, api_version: $api_version, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Moves the primary replica of a partition of a stateful service.
#
# POST /Partitions/{partitionId}/$/MovePrimaryReplica
# operationId: MovePrimaryReplica
export def "move-primary-replica" [
  partition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-7 # The version of the API. This parameter is required and its value must be '6.5'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.5)
  --node-name: string # The name of the node.
  --ignore-constraints: oneof<nothing, bool> # Ignore constraints when moving a replica. If this parameter is not specified, all constraints are honored. (default: false)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> any {
  http-request {
    method: post
    path: "/Partitions/{partitionId}/$/MovePrimaryReplica"
    path_params: [{name: partitionId, var: partition_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.5"}, {name: NodeName, var: node_name}, {name: IgnoreConstraints, var: ignore_constraints}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    partition_id: $partition_id, api_version: $api_version, node_name: $node_name, ignore_constraints: $ignore_constraints, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Moves the secondary replica of a partition of a stateful service.
#
# POST /Partitions/{partitionId}/$/MoveSecondaryReplica
# operationId: MoveSecondaryReplica
export def "move-secondary-replica" [
  partition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-7 # The version of the API. This parameter is required and its value must be '6.5'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.5)
  --current-node-name: string # The name of the source node for secondary replica move. (required)
  --new-node-name: string # The name of the target node for secondary replica move. If not specified, replica is moved to a random node.
  --ignore-constraints: oneof<nothing, bool> # Ignore constraints when moving a replica. If this parameter is not specified, all constraints are honored. (default: false)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> any {
  http-request {
    method: post
    path: "/Partitions/{partitionId}/$/MoveSecondaryReplica"
    path_params: [{name: partitionId, var: partition_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.5"}, {name: CurrentNodeName, var: current_node_name, required: true}, {name: NewNodeName, var: new_node_name}, {name: IgnoreConstraints, var: ignore_constraints}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    partition_id: $partition_id, api_version: $api_version, current_node_name: $current_node_name, new_node_name: $new_node_name, ignore_constraints: $ignore_constraints, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Indicates to the Service Fabric cluster that it should attempt to recover a specific partition that is currently stuck in quorum loss.
#
# POST /Partitions/{partitionId}/$/Recover
# operationId: RecoverPartition
export def "recover-partition" [
  partition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> any {
  http-request {
    method: post
    path: "/Partitions/{partitionId}/$/Recover"
    path_params: [{name: partitionId, var: partition_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    partition_id: $partition_id, api_version: $api_version, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sends a health report on the Service Fabric partition.
#
# POST /Partitions/{partitionId}/$/ReportHealth
# operationId: ReportPartitionHealth
export def "report-partition-health" [
  partition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --immediate: oneof<nothing, bool> # A flag that indicates whether the report should be sent immediately. A health report is sent to a Service Fabric gateway Application, which forwards to the health store. If Immediate is set to true, the report is sent immediately from HTTP Gateway to the health store, regardless of the fabric client settings that the HTTP Gateway Application is using. This is useful for critical reports that should be sent as soon as possible. Depending on timing and other conditions, sending the report may still fail, for example if the HTTP Gateway is closed or the message doesn't reach the Gateway. If Immediate is set to false, the report is sent based on the health client settings from the HTTP Gateway. Therefore, it will be batched according to the HealthReportSendInterval configuration. This is the recommended setting because it allows the health client to optimize health reporting messages to health store as well as health report processing. By default, reports are not sent immediately. (default: false)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --description: string # The description of the health information. It represents free text used to add human readable information about the report. The maximum string length for the description is 4096 characters. If the provided string is longer, it will be automatically truncated. When truncated, the last characters of the description contain a marker "[Truncated]", and total string size is 4096 characters. The presence of the marker indicates to users that truncation occurred. Note that when truncated, the description has less than 4096 characters from the original string.
  health_state: string@health-state-completer # The health state of a Service Fabric entity such as Cluster, Node, Application, Service, Partition, Replica etc.
  property: string # The property of the health information. An entity can have health reports for different properties. The property is a string and not a fixed enumeration to allow the reporter flexibility to categorize the state condition that triggers the report. For example, a reporter with SourceId "LocalWatchdog" can monitor the state of the available disk on a node, so it can report "AvailableDisk" property on that node. The same reporter can monitor the node connectivity, so it can report a property "Connectivity" on the same node. In the health store, these reports are treated as separate health events for the specified node. Together with the SourceId, the property uniquely identifies the health information.
  --remove-when-expired: oneof<nothing, bool> # Value that indicates whether the report is removed from health store when it expires. If set to true, the report is removed from the health store after it expires. If set to false, the report is treated as an error when expired. The value of this property is false by default. When clients report periodically, they should set RemoveWhenExpired false (default). This way, if the reporter has issues (e.g. deadlock) and can't report, the entity is evaluated at error when the health report expires. This flags the entity as being in Error health state.
  --sequence-number: string # The sequence number for this health report as a numeric string. The report sequence number is used by the health store to detect stale reports. If not specified, a sequence number is auto-generated by the health client when a report is added.
  source_id: string # The source name that identifies the client/watchdog/system component that generated the health information.
  --time-to-live-in-milli-seconds: string # The duration for which this health report is valid. This field uses ISO8601 format for specifying the duration. When clients report periodically, they should send reports with higher frequency than time to live. If clients report on transition, they can set the time to live to infinite. When time to live expires, the health event that contains the health information is either removed from health store, if RemoveWhenExpired is true, or evaluated at error, if RemoveWhenExpired false. If not specified, time to live defaults to infinite value. (format: duration)
]: any -> any {
  $in | http-request {
    method: post
    path: "/Partitions/{partitionId}/$/ReportHealth"
    path_params: [{name: partitionId, var: partition_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: Immediate, var: immediate}, {name: timeout, var: timeout}]
    body: {content_type: "application/json", kind: json, fields: [{name: Description, var: description}, {name: HealthState, var: health_state}, {name: Property, var: property}, {name: RemoveWhenExpired, var: remove_when_expired}, {name: SequenceNumber, var: sequence_number}, {name: SourceId, var: source_id}, {name: TimeToLiveInMilliSeconds, var: time_to_live_in_milli_seconds}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    partition_id: $partition_id, api_version: $api_version, immediate: $immediate, timeout: $timeout, description: $description, health_state: $health_state, property: $property, remove_when_expired: $remove_when_expired, sequence_number: $sequence_number, source_id: $source_id, time_to_live_in_milli_seconds: $time_to_live_in_milli_seconds
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resets the current load of a Service Fabric partition.
#
# POST /Partitions/{partitionId}/$/ResetLoad
# operationId: ResetPartitionLoad
export def "reset-partition-load" [
  partition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> any {
  http-request {
    method: post
    path: "/Partitions/{partitionId}/$/ResetLoad"
    path_params: [{name: partitionId, var: partition_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    partition_id: $partition_id, api_version: $api_version, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Triggers restore of the state of the partition using the specified restore partition description.
#
# POST /Partitions/{partitionId}/$/Restore
# operationId: RestorePartition
export def "restore-partition" [
  partition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --restore-timeout: int # Specifies the maximum amount of time to wait, in minutes, for the restore operation to complete. Post that, the operation returns back with timeout error. However, in certain corner cases it could be that the restore operation goes through even though it completes with timeout. In case of timeout error, its recommended to invoke this operation again with a greater timeout value. the default value for the same is 10 minutes. (default: 10)
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  backup_id: string # Unique backup ID. (format: uuid)
  backup_location: string # Location of the backup relative to the backup storage specified/ configured.
  --backup-storage: any # Describes the parameters for the backup storage. — shape: {FriendlyName?: string, StorageKind: "Invalid"|"FileShare"|"AzureBlobStore"}
]: any -> any {
  $in | http-request {
    method: post
    path: "/Partitions/{partitionId}/$/Restore"
    path_params: [{name: partitionId, var: partition_id}]
    query: [{name: RestoreTimeout, var: restore_timeout}, {name: api-version, var: api_version, required: true, default: "6.4"}, {name: timeout, var: timeout}]
    body: {content_type: "application/json", kind: json, fields: [{name: BackupId, var: backup_id}, {name: BackupLocation, var: backup_location}, {name: BackupStorage, var: backup_storage}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    partition_id: $partition_id, restore_timeout: $restore_timeout, api_version: $api_version, timeout: $timeout, backup_id: $backup_id, backup_location: $backup_location, backup_storage: $backup_storage
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resumes periodic backup of partition which was previously suspended.
#
# POST /Partitions/{partitionId}/$/ResumeBackup
# operationId: ResumePartitionBackup
export def "resume-partition-backup" [
  partition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> any {
  http-request {
    method: post
    path: "/Partitions/{partitionId}/$/ResumeBackup"
    path_params: [{name: partitionId, var: partition_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.4"}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    partition_id: $partition_id, api_version: $api_version, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Suspends periodic backup for the specified partition.
#
# POST /Partitions/{partitionId}/$/SuspendBackup
# operationId: SuspendPartitionBackup
export def "suspend-partition-backup" [
  partition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> any {
  http-request {
    method: post
    path: "/Partitions/{partitionId}/$/SuspendBackup"
    path_params: [{name: partitionId, var: partition_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.4"}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    partition_id: $partition_id, api_version: $api_version, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all the application resources.
#
# GET /Resources/Applications
# Returns: record<ContinuationToken: string, Items: table<identity: record, name: string, properties: record>>
# operationId: MeshApplication_List
export def "mesh-application-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (required, default: 6.4-preview)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Resources/Applications"
    query: [{name: api-version, var: api_version, required: true, default: "6.4-preview"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the Application resource.
#
# DELETE /Resources/Applications/{applicationResourceName}
# operationId: MeshApplication_Delete
export def "mesh-application-delete" [
  application_resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (required, default: 6.4-preview)
]: nothing -> any {
  http-request {
    method: delete
    path: "/Resources/Applications/{applicationResourceName}"
    path_params: [{name: applicationResourceName, var: application_resource_name}]
    query: [{name: api-version, var: api_version, required: true, default: "6.4-preview"}]
    accept: ["application/json"]
    ok: [200, 202, 204]
    auth: bearer
  } {
    application_resource_name: $application_resource_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the Application resource with the given name.
#
# GET /Resources/Applications/{applicationResourceName}
# Returns: record<identity: record<principalId: string, tenantId: string, tokenServiceEndpoint: string, type: string, userAssignedIdentities: record>, name: string, properties: record<debugParams: string, description: string, diagnostics: record<defaultSinkRefs: list, enabled: bool, sinks: list>, healthState: string, serviceNames: list<string>, services: list<record>, status: string, statusDetails: string, unhealthyEvaluation: string>>
# operationId: MeshApplication_Get
export def "mesh-application-get" [
  application_resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (required, default: 6.4-preview)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Resources/Applications/{applicationResourceName}"
    path_params: [{name: applicationResourceName, var: application_resource_name}]
    query: [{name: api-version, var: api_version, required: true, default: "6.4-preview"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_resource_name: $application_resource_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates or updates a Application resource.
#
# PUT /Resources/Applications/{applicationResourceName}
# Returns: record<identity: record<principalId: string, tenantId: string, tokenServiceEndpoint: string, type: string, userAssignedIdentities: record>, name: string, properties: record<debugParams: string, description: string, diagnostics: record<defaultSinkRefs: list, enabled: bool, sinks: list>, healthState: string, serviceNames: list<string>, services: list<record>, status: string, statusDetails: string, unhealthyEvaluation: string>>
# operationId: MeshApplication_CreateOrUpdate
export def "mesh-application-create-or-update" [
  application_resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (required, default: 6.4-preview)
  --identity: any # Information describing the identities associated with this application. — shape: {principalId?: string, tenantId?: string, tokenServiceEndpoint?: string, type: string, userAssignedIdentities?: record}
  name: string # Name of the Application resource.
  properties: any # Describes properties of a application resource. — shape: {debugParams?: string, description?: string, diagnostics?: any, healthState?: "Invalid"|"Ok"|"Warning"|"Error"|"Unknown", services?: list, status?: "Unknown"|"Ready"|"Upgrading"|"Creating"|"Deleting"|"Failed"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/Resources/Applications/{applicationResourceName}"
    path_params: [{name: applicationResourceName, var: application_resource_name}]
    query: [{name: api-version, var: api_version, required: true, default: "6.4-preview"}]
    body: {content_type: "application/json", kind: json, fields: [{name: identity, var: identity}, {name: name, var: name}, {name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 201, 202]
    auth: bearer
  } {
    application_resource_name: $application_resource_name, api_version: $api_version, identity: $identity, name: $name, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all the service resources.
#
# GET /Resources/Applications/{applicationResourceName}/Services
# Returns: record<ContinuationToken: string, Items: table<name: string, properties: record>>
# operationId: MeshService_List
export def "mesh-service-list" [
  application_resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (required, default: 6.4-preview)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Resources/Applications/{applicationResourceName}/Services"
    path_params: [{name: applicationResourceName, var: application_resource_name}]
    query: [{name: api-version, var: api_version, required: true, default: "6.4-preview"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_resource_name: $application_resource_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the Service resource with the given name.
#
# GET /Resources/Applications/{applicationResourceName}/Services/{serviceResourceName}
# Returns: record<name: string, properties: record<codePackages: list<record>, diagnostics: record<enabled: bool, sinkRefs: list>, networkRefs: list<record>, osType: string, autoScalingPolicies: list<record>, description: string, healthState: string, identityRefs: list<record>, replicaCount: int, status: string, statusDetails: string, unhealthyEvaluation: string>>
# operationId: MeshService_Get
export def "mesh-service-get" [
  application_resource_name: string
  service_resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (required, default: 6.4-preview)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Resources/Applications/{applicationResourceName}/Services/{serviceResourceName}"
    path_params: [{name: applicationResourceName, var: application_resource_name}, {name: serviceResourceName, var: service_resource_name}]
    query: [{name: api-version, var: api_version, required: true, default: "6.4-preview"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_resource_name: $application_resource_name, service_resource_name: $service_resource_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all the replicas of a service.
#
# GET /Resources/Applications/{applicationResourceName}/Services/{serviceResourceName}/Replicas
# Returns: record<ContinuationToken: string, Items: table<replicaName: string, codePackages: list, diagnostics: record, networkRefs: list, osType: string>>
# operationId: MeshServiceReplica_List
export def "mesh-service-replica-list" [
  application_resource_name: string
  service_resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (required, default: 6.4-preview)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Resources/Applications/{applicationResourceName}/Services/{serviceResourceName}/Replicas"
    path_params: [{name: applicationResourceName, var: application_resource_name}, {name: serviceResourceName, var: service_resource_name}]
    query: [{name: api-version, var: api_version, required: true, default: "6.4-preview"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_resource_name: $application_resource_name, service_resource_name: $service_resource_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the given replica of the service of an application.
#
# GET /Resources/Applications/{applicationResourceName}/Services/{serviceResourceName}/Replicas/{replicaName}
# Returns: record<replicaName: string, codePackages: table<commands: list, diagnostics: record, endpoints: list, entrypoint: string, environmentVariables: list, image: string, imageRegistryCredential: record, instanceView: record, labels: list, name: string, reliableCollectionsRefs: list, resources: record, settings: list, volumeRefs: list, volumes: list>, diagnostics: record<enabled: bool, sinkRefs: list<string>>, networkRefs: table<endpointRefs: list, name: string>, osType: string>
# operationId: MeshServiceReplica_Get
export def "mesh-service-replica-get" [
  application_resource_name: string
  service_resource_name: string
  replica_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (required, default: 6.4-preview)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Resources/Applications/{applicationResourceName}/Services/{serviceResourceName}/Replicas/{replicaName}"
    path_params: [{name: applicationResourceName, var: application_resource_name}, {name: serviceResourceName, var: service_resource_name}, {name: replicaName, var: replica_name}]
    query: [{name: api-version, var: api_version, required: true, default: "6.4-preview"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_resource_name: $application_resource_name, service_resource_name: $service_resource_name, replica_name: $replica_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the logs from the container.
#
# GET /Resources/Applications/{applicationResourceName}/Services/{serviceResourceName}/Replicas/{replicaName}/CodePackages/{codePackageName}/Logs
# Returns: record<Content: string>
# operationId: MeshCodePackage_GetContainerLogs
export def "mesh-code-package-get-container-logs" [
  application_resource_name: string
  service_resource_name: string
  replica_name: string
  code_package_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (required, default: 6.4-preview)
  --tail: string # Number of lines to show from the end of the logs. Default is 100. 'all' to show the complete logs.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Resources/Applications/{applicationResourceName}/Services/{serviceResourceName}/Replicas/{replicaName}/CodePackages/{codePackageName}/Logs"
    path_params: [{name: applicationResourceName, var: application_resource_name}, {name: serviceResourceName, var: service_resource_name}, {name: replicaName, var: replica_name}, {name: codePackageName, var: code_package_name}]
    query: [{name: api-version, var: api_version, required: true, default: "6.4-preview"}, {name: Tail, var: tail}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_resource_name: $application_resource_name, service_resource_name: $service_resource_name, replica_name: $replica_name, code_package_name: $code_package_name, api_version: $api_version, tail: $tail
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all the gateway resources.
#
# GET /Resources/Gateways
# Returns: record<ContinuationToken: string, Items: table<name: string, properties: record>>
# operationId: MeshGateway_List
export def "mesh-gateway-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (required, default: 6.4-preview)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Resources/Gateways"
    query: [{name: api-version, var: api_version, required: true, default: "6.4-preview"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the Gateway resource.
#
# DELETE /Resources/Gateways/{gatewayResourceName}
# operationId: MeshGateway_Delete
export def "mesh-gateway-delete" [
  gateway_resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (required, default: 6.4-preview)
]: nothing -> any {
  http-request {
    method: delete
    path: "/Resources/Gateways/{gatewayResourceName}"
    path_params: [{name: gatewayResourceName, var: gateway_resource_name}]
    query: [{name: api-version, var: api_version, required: true, default: "6.4-preview"}]
    accept: ["application/json"]
    ok: [200, 202, 204]
    auth: bearer
  } {
    gateway_resource_name: $gateway_resource_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the Gateway resource with the given name.
#
# GET /Resources/Gateways/{gatewayResourceName}
# Returns: record<name: string, properties: record<description: string, destinationNetwork: record<endpointRefs: list, name: string>, http: list<record>, ipAddress: string, sourceNetwork: record<endpointRefs: list, name: string>, status: string, statusDetails: string, tcp: list<record>>>
# operationId: MeshGateway_Get
export def "mesh-gateway-get" [
  gateway_resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (required, default: 6.4-preview)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Resources/Gateways/{gatewayResourceName}"
    path_params: [{name: gatewayResourceName, var: gateway_resource_name}]
    query: [{name: api-version, var: api_version, required: true, default: "6.4-preview"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    gateway_resource_name: $gateway_resource_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates or updates a Gateway resource.
#
# PUT /Resources/Gateways/{gatewayResourceName}
# Returns: record<name: string, properties: record<description: string, destinationNetwork: record<endpointRefs: list, name: string>, http: list<record>, ipAddress: string, sourceNetwork: record<endpointRefs: list, name: string>, status: string, statusDetails: string, tcp: list<record>>>
# operationId: MeshGateway_CreateOrUpdate
export def "mesh-gateway-create-or-update" [
  gateway_resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (required, default: 6.4-preview)
  name: string # Name of the Gateway resource.
  properties: any # Describes properties of a gateway resource. — shape: {description?: string, destinationNetwork: any, http?: list, sourceNetwork: any, status?: "Unknown"|"Ready"|"Upgrading"|"Creating"|"Deleting"|"Failed", tcp?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/Resources/Gateways/{gatewayResourceName}"
    path_params: [{name: gatewayResourceName, var: gateway_resource_name}]
    query: [{name: api-version, var: api_version, required: true, default: "6.4-preview"}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 201, 202]
    auth: bearer
  } {
    gateway_resource_name: $gateway_resource_name, api_version: $api_version, name: $name, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all the network resources.
#
# GET /Resources/Networks
# Returns: record<ContinuationToken: string, Items: table<name: string, properties: record>>
# operationId: MeshNetwork_List
export def "mesh-network-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (required, default: 6.4-preview)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Resources/Networks"
    query: [{name: api-version, var: api_version, required: true, default: "6.4-preview"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the Network resource.
#
# DELETE /Resources/Networks/{networkResourceName}
# operationId: MeshNetwork_Delete
export def "mesh-network-delete" [
  network_resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (required, default: 6.4-preview)
]: nothing -> any {
  http-request {
    method: delete
    path: "/Resources/Networks/{networkResourceName}"
    path_params: [{name: networkResourceName, var: network_resource_name}]
    query: [{name: api-version, var: api_version, required: true, default: "6.4-preview"}]
    accept: ["application/json"]
    ok: [200, 202, 204]
    auth: bearer
  } {
    network_resource_name: $network_resource_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the Network resource with the given name.
#
# GET /Resources/Networks/{networkResourceName}
# Returns: record<name: string, properties: record<description: string, status: string, statusDetails: string, kind: string>>
# operationId: MeshNetwork_Get
export def "mesh-network-get" [
  network_resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (required, default: 6.4-preview)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Resources/Networks/{networkResourceName}"
    path_params: [{name: networkResourceName, var: network_resource_name}]
    query: [{name: api-version, var: api_version, required: true, default: "6.4-preview"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    network_resource_name: $network_resource_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates or updates a Network resource.
#
# PUT /Resources/Networks/{networkResourceName}
# Returns: record<name: string, properties: record<description: string, status: string, statusDetails: string, kind: string>>
# operationId: MeshNetwork_CreateOrUpdate
export def "mesh-network-create-or-update" [
  network_resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (required, default: 6.4-preview)
  name: string # Name of the Network resource.
  properties: record # Describes properties of a network resource. — shape: {description?: string, status?: "Unknown"|"Ready"|"Upgrading"|"Creating"|"Deleting"|"Failed", kind: "Local"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/Resources/Networks/{networkResourceName}"
    path_params: [{name: networkResourceName, var: network_resource_name}]
    query: [{name: api-version, var: api_version, required: true, default: "6.4-preview"}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 201, 202]
    auth: bearer
  } {
    network_resource_name: $network_resource_name, api_version: $api_version, name: $name, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all the secret resources.
#
# GET /Resources/Secrets
# Returns: record<ContinuationToken: string, Items: table<name: string, properties: record>>
# operationId: MeshSecret_List
export def "mesh-secret-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (required, default: 6.4-preview)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Resources/Secrets"
    query: [{name: api-version, var: api_version, required: true, default: "6.4-preview"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the Secret resource.
#
# DELETE /Resources/Secrets/{secretResourceName}
# operationId: MeshSecret_Delete
export def "mesh-secret-delete" [
  secret_resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (required, default: 6.4-preview)
]: nothing -> any {
  http-request {
    method: delete
    path: "/Resources/Secrets/{secretResourceName}"
    path_params: [{name: secretResourceName, var: secret_resource_name}]
    query: [{name: api-version, var: api_version, required: true, default: "6.4-preview"}]
    accept: ["application/json"]
    ok: [200, 202, 204]
    auth: bearer
  } {
    secret_resource_name: $secret_resource_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the Secret resource with the given name.
#
# GET /Resources/Secrets/{secretResourceName}
# Returns: record<name: string, properties: record<contentType: string, description: string, status: string, statusDetails: string, kind: string>>
# operationId: MeshSecret_Get
export def "mesh-secret-get" [
  secret_resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (required, default: 6.4-preview)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Resources/Secrets/{secretResourceName}"
    path_params: [{name: secretResourceName, var: secret_resource_name}]
    query: [{name: api-version, var: api_version, required: true, default: "6.4-preview"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    secret_resource_name: $secret_resource_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates or updates a Secret resource.
#
# PUT /Resources/Secrets/{secretResourceName}
# Returns: record<name: string, properties: record<contentType: string, description: string, status: string, statusDetails: string, kind: string>>
# operationId: MeshSecret_CreateOrUpdate
export def "mesh-secret-create-or-update" [
  secret_resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (required, default: 6.4-preview)
  name: string # Name of the Secret resource.
  properties: record # Describes the properties of a secret resource. — shape: {contentType?: string, description?: string, status?: "Unknown"|"Ready"|"Upgrading"|"Creating"|"Deleting"|"Failed", kind: "inlinedValue"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/Resources/Secrets/{secretResourceName}"
    path_params: [{name: secretResourceName, var: secret_resource_name}]
    query: [{name: api-version, var: api_version, required: true, default: "6.4-preview"}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 201, 202]
    auth: bearer
  } {
    secret_resource_name: $secret_resource_name, api_version: $api_version, name: $name, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List names of all values of the specified secret resource.
#
# GET /Resources/Secrets/{secretResourceName}/values
# Returns: record<ContinuationToken: string, Items: table<name: string, properties: record>>
# operationId: MeshSecretValue_List
export def "mesh-secret-value-list" [
  secret_resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (required, default: 6.4-preview)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Resources/Secrets/{secretResourceName}/values"
    path_params: [{name: secretResourceName, var: secret_resource_name}]
    query: [{name: api-version, var: api_version, required: true, default: "6.4-preview"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    secret_resource_name: $secret_resource_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified value of the named secret resource.
#
# DELETE /Resources/Secrets/{secretResourceName}/values/{secretValueResourceName}
# operationId: MeshSecretValue_Delete
export def "mesh-secret-value-delete" [
  secret_resource_name: string
  secret_value_resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (required, default: 6.4-preview)
]: nothing -> any {
  http-request {
    method: delete
    path: "/Resources/Secrets/{secretResourceName}/values/{secretValueResourceName}"
    path_params: [{name: secretResourceName, var: secret_resource_name}, {name: secretValueResourceName, var: secret_value_resource_name}]
    query: [{name: api-version, var: api_version, required: true, default: "6.4-preview"}]
    accept: ["application/json"]
    ok: [200, 202, 204]
    auth: bearer
  } {
    secret_resource_name: $secret_resource_name, secret_value_resource_name: $secret_value_resource_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the specified secret value resource.
#
# GET /Resources/Secrets/{secretResourceName}/values/{secretValueResourceName}
# Returns: record<name: string, properties: record<value: string>>
# operationId: MeshSecretValue_Get
export def "mesh-secret-value-get" [
  secret_resource_name: string
  secret_value_resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (required, default: 6.4-preview)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Resources/Secrets/{secretResourceName}/values/{secretValueResourceName}"
    path_params: [{name: secretResourceName, var: secret_resource_name}, {name: secretValueResourceName, var: secret_value_resource_name}]
    query: [{name: api-version, var: api_version, required: true, default: "6.4-preview"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    secret_resource_name: $secret_resource_name, secret_value_resource_name: $secret_value_resource_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds the specified value as a new version of the specified secret resource.
#
# PUT /Resources/Secrets/{secretResourceName}/values/{secretValueResourceName}
# Returns: record<name: string, properties: record<value: string>>
# operationId: MeshSecretValue_AddValue
export def "mesh-secret-value-add-value" [
  secret_resource_name: string
  secret_value_resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (required, default: 6.4-preview)
  name: string # Version identifier of the secret value.
  properties: record # This type describes properties of a secret value resource. — shape: {value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/Resources/Secrets/{secretResourceName}/values/{secretValueResourceName}"
    path_params: [{name: secretResourceName, var: secret_resource_name}, {name: secretValueResourceName, var: secret_value_resource_name}]
    query: [{name: api-version, var: api_version, required: true, default: "6.4-preview"}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 201, 202]
    auth: bearer
  } {
    secret_resource_name: $secret_resource_name, secret_value_resource_name: $secret_value_resource_name, api_version: $api_version, name: $name, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the specified value of the secret resource.
#
# POST /Resources/Secrets/{secretResourceName}/values/{secretValueResourceName}/list_value
# Returns: record<value: string>
# operationId: MeshSecretValue_Show
export def "mesh-secret-value-show" [
  secret_resource_name: string
  secret_value_resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (required, default: 6.4-preview)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/Resources/Secrets/{secretResourceName}/values/{secretValueResourceName}/list_value"
    path_params: [{name: secretResourceName, var: secret_resource_name}, {name: secretValueResourceName, var: secret_value_resource_name}]
    query: [{name: api-version, var: api_version, required: true, default: "6.4-preview"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    secret_resource_name: $secret_resource_name, secret_value_resource_name: $secret_value_resource_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all the volume resources.
#
# GET /Resources/Volumes
# Returns: record<ContinuationToken: string, Items: table<name: string, properties: record>>
# operationId: MeshVolume_List
export def "mesh-volume-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (required, default: 6.4-preview)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Resources/Volumes"
    query: [{name: api-version, var: api_version, required: true, default: "6.4-preview"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the Volume resource.
#
# DELETE /Resources/Volumes/{volumeResourceName}
# operationId: MeshVolume_Delete
export def "mesh-volume-delete" [
  volume_resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (required, default: 6.4-preview)
]: nothing -> any {
  http-request {
    method: delete
    path: "/Resources/Volumes/{volumeResourceName}"
    path_params: [{name: volumeResourceName, var: volume_resource_name}]
    query: [{name: api-version, var: api_version, required: true, default: "6.4-preview"}]
    accept: ["application/json"]
    ok: [200, 202, 204]
    auth: bearer
  } {
    volume_resource_name: $volume_resource_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the Volume resource with the given name.
#
# GET /Resources/Volumes/{volumeResourceName}
# Returns: record<name: string, properties: record<azureFileParameters: record<accountKey: string, accountName: string, shareName: string>, description: string, provider: string, status: string, statusDetails: string>>
# operationId: MeshVolume_Get
export def "mesh-volume-get" [
  volume_resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (required, default: 6.4-preview)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Resources/Volumes/{volumeResourceName}"
    path_params: [{name: volumeResourceName, var: volume_resource_name}]
    query: [{name: api-version, var: api_version, required: true, default: "6.4-preview"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    volume_resource_name: $volume_resource_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates or updates a Volume resource.
#
# PUT /Resources/Volumes/{volumeResourceName}
# Returns: record<name: string, properties: record<azureFileParameters: record<accountKey: string, accountName: string, shareName: string>, description: string, provider: string, status: string, statusDetails: string>>
# operationId: MeshVolume_CreateOrUpdate
export def "mesh-volume-create-or-update" [
  volume_resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (required, default: 6.4-preview)
  name: string # Name of the Volume resource.
  properties: any # Describes properties of a volume resource. — shape: {azureFileParameters?: any, description?: string, provider: "SFAzureFile", status?: "Unknown"|"Ready"|"Upgrading"|"Creating"|"Deleting"|"Failed"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/Resources/Volumes/{volumeResourceName}"
    path_params: [{name: volumeResourceName, var: volume_resource_name}]
    query: [{name: api-version, var: api_version, required: true, default: "6.4-preview"}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 201, 202]
    auth: bearer
  } {
    volume_resource_name: $volume_resource_name, api_version: $api_version, name: $name, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Indicates to the Service Fabric cluster that it should attempt to recover the specified service that is currently stuck in quorum loss.
#
# POST /Services/$/{serviceId}/$/GetPartitions/$/Recover
# operationId: RecoverServicePartitions
export def "recover-service-partitions" [
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> any {
  http-request {
    method: post
    path: "/Services/$/{serviceId}/$/GetPartitions/$/Recover"
    path_params: [{name: serviceId, var: service_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_id: $service_id, api_version: $api_version, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an existing Service Fabric service.
#
# POST /Services/{serviceId}/$/Delete
# operationId: DeleteService
export def "delete-service" [
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --force-remove: oneof<nothing, bool> # Remove a Service Fabric application or service forcefully without going through the graceful shutdown sequence. This parameter can be used to forcefully delete an application or service for which delete is timing out due to issues in the service code that prevents graceful close of replicas.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> any {
  http-request {
    method: post
    path: "/Services/{serviceId}/$/Delete"
    path_params: [{name: serviceId, var: service_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: ForceRemove, var: force_remove}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_id: $service_id, api_version: $api_version, force_remove: $force_remove, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disables periodic backup of Service Fabric service which was previously enabled.
#
# POST /Services/{serviceId}/$/DisableBackup
# operationId: DisableServiceBackup
export def "disable-service-backup" [
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --clean-backup: oneof<nothing, bool> # Boolean flag to delete backups. It can be set to true for deleting all the backups which were created for the backup entity that is getting disabled for backup.
]: any -> any {
  $in | http-request {
    method: post
    path: "/Services/{serviceId}/$/DisableBackup"
    path_params: [{name: serviceId, var: service_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.4"}, {name: timeout, var: timeout}]
    body: {content_type: "application/json", kind: json, fields: [{name: CleanBackup, var: clean_backup, required: true}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    service_id: $service_id, api_version: $api_version, timeout: $timeout, clean_backup: $clean_backup
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enables periodic backup of stateful partitions under this Service Fabric service.
#
# POST /Services/{serviceId}/$/EnableBackup
# operationId: EnableServiceBackup
export def "enable-service-backup" [
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  backup_policy_name: string # Name of the backup policy to be used for enabling periodic backups.
]: any -> any {
  $in | http-request {
    method: post
    path: "/Services/{serviceId}/$/EnableBackup"
    path_params: [{name: serviceId, var: service_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.4"}, {name: timeout, var: timeout}]
    body: {content_type: "application/json", kind: json, fields: [{name: BackupPolicyName, var: backup_policy_name}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    service_id: $service_id, api_version: $api_version, timeout: $timeout, backup_policy_name: $backup_policy_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the name of the Service Fabric application for a service.
#
# GET /Services/{serviceId}/$/GetApplicationName
# Returns: record<Id: string, Name: string>
# operationId: GetApplicationNameInfo
export def "get-application-name-info" [
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Services/{serviceId}/$/GetApplicationName"
    path_params: [{name: serviceId, var: service_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_id: $service_id, api_version: $api_version, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the Service Fabric service backup configuration information.
#
# GET /Services/{serviceId}/$/GetBackupConfigurationInfo
# Returns: record<ContinuationToken: string, Items: table<Kind: string, PolicyInheritedFrom: string, PolicyName: string, SuspensionInfo: record>>
# operationId: GetServiceBackupConfigurationInfo
export def "get-service-backup-configuration-info" [
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.4)
  --continuation-token: string # The continuation token parameter is used to obtain next set of results. A continuation token with a non-empty value is included in the response of the API when the results from the system do not fit in a single response. When this value is passed to the next API call, the API returns next set of results. If there are no further results, then the continuation token does not contain a value. The value of this parameter should not be URL encoded.
  --max-results: int # The maximum number of results to be returned as part of the paged queries. This parameter defines the upper bound on the number of results returned. The results returned can be less than the specified maximum results if they do not fit in the message as per the max message size restrictions defined in the configuration. If this parameter is zero or not specified, the paged query includes as many results as possible that fit in the return message. (format: int64, default: 0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Services/{serviceId}/$/GetBackupConfigurationInfo"
    path_params: [{name: serviceId, var: service_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.4"}, {name: ContinuationToken, var: continuation_token}, {name: MaxResults, var: max_results}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_id: $service_id, api_version: $api_version, continuation_token: $continuation_token, max_results: $max_results, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the list of backups available for every partition in this service.
#
# GET /Services/{serviceId}/$/GetBackups
# Returns: record<ContinuationToken: string, Items: table<ApplicationName: string, BackupChainId: string, BackupId: string, BackupLocation: string, BackupType: string, CreationTimeUtc: string, EpochOfLastBackupRecord: record, FailureError: record, LsnOfLastBackupRecord: string, PartitionInformation: record, ServiceManifestVersion: string, ServiceName: string>>
# operationId: GetServiceBackupList
export def "get-service-backup-list" [
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --latest: oneof<nothing, bool> # Specifies whether to get only the most recent backup available for a partition for the specified time range. (default: false)
  --start-date-time-filter: string # Specify the start date time from which to enumerate backups, in datetime format. The date time must be specified in ISO8601 format. This is an optional parameter. If not specified, all backups from the beginning are enumerated. (format: date-time)
  --end-date-time-filter: string # Specify the end date time till which to enumerate backups, in datetime format. The date time must be specified in ISO8601 format. This is an optional parameter. If not specified, enumeration is done till the most recent backup. (format: date-time)
  --continuation-token: string # The continuation token parameter is used to obtain next set of results. A continuation token with a non-empty value is included in the response of the API when the results from the system do not fit in a single response. When this value is passed to the next API call, the API returns next set of results. If there are no further results, then the continuation token does not contain a value. The value of this parameter should not be URL encoded.
  --max-results: int # The maximum number of results to be returned as part of the paged queries. This parameter defines the upper bound on the number of results returned. The results returned can be less than the specified maximum results if they do not fit in the message as per the max message size restrictions defined in the configuration. If this parameter is zero or not specified, the paged query includes as many results as possible that fit in the return message. (format: int64, default: 0)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Services/{serviceId}/$/GetBackups"
    path_params: [{name: serviceId, var: service_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.4"}, {name: timeout, var: timeout}, {name: Latest, var: latest}, {name: StartDateTimeFilter, var: start_date_time_filter}, {name: EndDateTimeFilter, var: end_date_time_filter}, {name: ContinuationToken, var: continuation_token}, {name: MaxResults, var: max_results}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_id: $service_id, api_version: $api_version, timeout: $timeout, latest: $latest, start_date_time_filter: $start_date_time_filter, end_date_time_filter: $end_date_time_filter, continuation_token: $continuation_token, max_results: $max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the description of an existing Service Fabric service.
#
# GET /Services/{serviceId}/$/GetDescription
# Discriminator (response): ServiceKind
# Returns: record<ApplicationName: string, CorrelationScheme: table<Scheme: string, ServiceName: string>, DefaultMoveCost: string, InitializationData: list<int>, IsDefaultMoveCostSpecified: bool, PartitionDescription: record<PartitionScheme: string>, PlacementConstraints: string, ScalingPolicies: table<ScalingMechanism: record, ScalingTrigger: record>, ServiceDnsName: string, ServiceKind: string, ServiceLoadMetrics: table<DefaultLoad: int, Name: string, PrimaryDefaultLoad: int, SecondaryDefaultLoad: int, Weight: string>, ServiceName: string, ServicePackageActivationMode: string, ServicePlacementPolicies: table<Type: string>, ServiceTypeName: string>
# operationId: GetServiceDescription
export def "get-service-description" [
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Services/{serviceId}/$/GetDescription"
    path_params: [{name: serviceId, var: service_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_id: $service_id, api_version: $api_version, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the health of the specified Service Fabric service.
#
# GET /Services/{serviceId}/$/GetHealth
# Returns: record<Name: string, PartitionHealthStates: table<PartitionId: string, AggregatedHealthState: string>, AggregatedHealthState: string, HealthEvents: table<IsExpired: bool, LastErrorTransitionAt: string, LastModifiedUtcTimestamp: string, LastOkTransitionAt: string, LastWarningTransitionAt: string, SourceUtcTimestamp: string, Description: string, HealthState: string, Property: string, RemoveWhenExpired: bool, SequenceNumber: string, SourceId: string, TimeToLiveInMilliSeconds: string>, HealthStatistics: record<HealthStateCountList: list<record>>, UnhealthyEvaluations: table<HealthEvaluation: record>>
# operationId: GetServiceHealth
export def "get-service-health" [
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --events-health-state-filter: int # Allows filtering the collection of HealthEvent objects returned based on health state. The possible values for this parameter include integer value of one of the following health states. Only events that match the filter are returned. All events are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these values, obtained using the bitwise 'OR' operator. For example, If the provided value is 6 then all of the events with HealthState value of OK (2) and Warning (4) are returned. - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --partitions-health-state-filter: int # Allows filtering of the partitions health state objects returned in the result of service health query based on their health state. The possible values for this parameter include integer value of one of the following health states. Only partitions that match the filter are returned. All partitions are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these value obtained using bitwise 'OR' operator. For example, if the provided value is 6 then health state of partitions with HealthState value of OK (2) and Warning (4) will be returned. - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --exclude-health-statistics: oneof<nothing, bool> # Indicates whether the health statistics should be returned as part of the query result. False by default. The statistics show the number of children entities in health state Ok, Warning, and Error. (default: false)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Services/{serviceId}/$/GetHealth"
    path_params: [{name: serviceId, var: service_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: EventsHealthStateFilter, var: events_health_state_filter}, {name: PartitionsHealthStateFilter, var: partitions_health_state_filter}, {name: ExcludeHealthStatistics, var: exclude_health_statistics}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_id: $service_id, api_version: $api_version, events_health_state_filter: $events_health_state_filter, partitions_health_state_filter: $partitions_health_state_filter, exclude_health_statistics: $exclude_health_statistics, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the health of the specified Service Fabric service, by using the specified health policy.
#
# POST /Services/{serviceId}/$/GetHealth
# Returns: record<Name: string, PartitionHealthStates: table<PartitionId: string, AggregatedHealthState: string>, AggregatedHealthState: string, HealthEvents: table<IsExpired: bool, LastErrorTransitionAt: string, LastModifiedUtcTimestamp: string, LastOkTransitionAt: string, LastWarningTransitionAt: string, SourceUtcTimestamp: string, Description: string, HealthState: string, Property: string, RemoveWhenExpired: bool, SequenceNumber: string, SourceId: string, TimeToLiveInMilliSeconds: string>, HealthStatistics: record<HealthStateCountList: list<record>>, UnhealthyEvaluations: table<HealthEvaluation: record>>
# operationId: GetServiceHealthUsingPolicy
export def "get-service-health-using-policy" [
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --events-health-state-filter: int # Allows filtering the collection of HealthEvent objects returned based on health state. The possible values for this parameter include integer value of one of the following health states. Only events that match the filter are returned. All events are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these values, obtained using the bitwise 'OR' operator. For example, If the provided value is 6 then all of the events with HealthState value of OK (2) and Warning (4) are returned. - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --partitions-health-state-filter: int # Allows filtering of the partitions health state objects returned in the result of service health query based on their health state. The possible values for this parameter include integer value of one of the following health states. Only partitions that match the filter are returned. All partitions are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these value obtained using bitwise 'OR' operator. For example, if the provided value is 6 then health state of partitions with HealthState value of OK (2) and Warning (4) will be returned. - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --exclude-health-statistics: oneof<nothing, bool> # Indicates whether the health statistics should be returned as part of the query result. False by default. The statistics show the number of children entities in health state Ok, Warning, and Error. (default: false)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --consider-warning-as-error: oneof<nothing, bool> # Indicates whether warnings are treated with the same severity as errors. (default: false)
  --default-service-type-health-policy: any # Represents the health policy used to evaluate the health of services belonging to a service type. — shape: {MaxPercentUnhealthyPartitionsPerService?: int, MaxPercentUnhealthyReplicasPerPartition?: int, MaxPercentUnhealthyServices?: int}
  --max-percent-unhealthy-deployed-applications: int # The maximum allowed percentage of unhealthy deployed applications. Allowed values are Byte values from zero to 100. The percentage represents the maximum tolerated percentage of deployed applications that can be unhealthy before the application is considered in error. This is calculated by dividing the number of unhealthy deployed applications over the number of nodes where the application is currently deployed on in the cluster. The computation rounds up to tolerate one failure on small numbers of nodes. Default percentage is zero. (default: 0)
  --service-type-health-policy-map: list # Defines a ServiceTypeHealthPolicy per service type name. The entries in the map replace the default service type health policy for each specified service type. For example, in an application that contains both a stateless gateway service type and a stateful engine service type, the health policies for the stateless and stateful services can be configured differently. With policy per service type, there's more granular control of the health of the service. If no policy is specified for a service type name, the DefaultServiceTypeHealthPolicy is used for evaluation. — item shape: {Key: string, Value: any}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Services/{serviceId}/$/GetHealth"
    path_params: [{name: serviceId, var: service_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: EventsHealthStateFilter, var: events_health_state_filter}, {name: PartitionsHealthStateFilter, var: partitions_health_state_filter}, {name: ExcludeHealthStatistics, var: exclude_health_statistics}, {name: timeout, var: timeout}]
    body: {content_type: "application/json", kind: json, fields: [{name: ConsiderWarningAsError, var: consider_warning_as_error}, {name: DefaultServiceTypeHealthPolicy, var: default_service_type_health_policy}, {name: MaxPercentUnhealthyDeployedApplications, var: max_percent_unhealthy_deployed_applications}, {name: ServiceTypeHealthPolicyMap, var: service_type_health_policy_map}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_id: $service_id, api_version: $api_version, events_health_state_filter: $events_health_state_filter, partitions_health_state_filter: $partitions_health_state_filter, exclude_health_statistics: $exclude_health_statistics, timeout: $timeout, consider_warning_as_error: $consider_warning_as_error, default_service_type_health_policy: $default_service_type_health_policy, max_percent_unhealthy_deployed_applications: $max_percent_unhealthy_deployed_applications, service_type_health_policy_map: $service_type_health_policy_map
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the list of partitions of a Service Fabric service.
#
# GET /Services/{serviceId}/$/GetPartitions
# Returns: record<ContinuationToken: string, Items: table<HealthState: string, PartitionInformation: record, PartitionStatus: string, ServiceKind: string>>
# operationId: GetPartitionInfoList
export def "get-partition-info-list" [
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.4)
  --continuation-token: string # The continuation token parameter is used to obtain next set of results. A continuation token with a non-empty value is included in the response of the API when the results from the system do not fit in a single response. When this value is passed to the next API call, the API returns next set of results. If there are no further results, then the continuation token does not contain a value. The value of this parameter should not be URL encoded.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Services/{serviceId}/$/GetPartitions"
    path_params: [{name: serviceId, var: service_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.4"}, {name: ContinuationToken, var: continuation_token}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_id: $service_id, api_version: $api_version, continuation_token: $continuation_token, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the information about unplaced replica of the service.
#
# GET /Services/{serviceId}/$/GetUnplacedReplicaInformation
# Returns: record<PartitionId: string, ServiceName: string, UnplacedReplicaDetails: list<string>>
# operationId: GetUnplacedReplicaInformation
export def "get-unplaced-replica-information" [
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.4)
  --partition-id: string # The identity of the partition. (format: uuid)
  --only-query-primaries: oneof<nothing, bool> # Indicates that unplaced replica information will be queries only for primary replicas. (default: false)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Services/{serviceId}/$/GetUnplacedReplicaInformation"
    path_params: [{name: serviceId, var: service_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.4"}, {name: PartitionId, var: partition_id}, {name: OnlyQueryPrimaries, var: only_query_primaries}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_id: $service_id, api_version: $api_version, partition_id: $partition_id, only_query_primaries: $only_query_primaries, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sends a health report on the Service Fabric service.
#
# POST /Services/{serviceId}/$/ReportHealth
# operationId: ReportServiceHealth
export def "report-service-health" [
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --immediate: oneof<nothing, bool> # A flag that indicates whether the report should be sent immediately. A health report is sent to a Service Fabric gateway Application, which forwards to the health store. If Immediate is set to true, the report is sent immediately from HTTP Gateway to the health store, regardless of the fabric client settings that the HTTP Gateway Application is using. This is useful for critical reports that should be sent as soon as possible. Depending on timing and other conditions, sending the report may still fail, for example if the HTTP Gateway is closed or the message doesn't reach the Gateway. If Immediate is set to false, the report is sent based on the health client settings from the HTTP Gateway. Therefore, it will be batched according to the HealthReportSendInterval configuration. This is the recommended setting because it allows the health client to optimize health reporting messages to health store as well as health report processing. By default, reports are not sent immediately. (default: false)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --description: string # The description of the health information. It represents free text used to add human readable information about the report. The maximum string length for the description is 4096 characters. If the provided string is longer, it will be automatically truncated. When truncated, the last characters of the description contain a marker "[Truncated]", and total string size is 4096 characters. The presence of the marker indicates to users that truncation occurred. Note that when truncated, the description has less than 4096 characters from the original string.
  health_state: string@health-state-completer # The health state of a Service Fabric entity such as Cluster, Node, Application, Service, Partition, Replica etc.
  property: string # The property of the health information. An entity can have health reports for different properties. The property is a string and not a fixed enumeration to allow the reporter flexibility to categorize the state condition that triggers the report. For example, a reporter with SourceId "LocalWatchdog" can monitor the state of the available disk on a node, so it can report "AvailableDisk" property on that node. The same reporter can monitor the node connectivity, so it can report a property "Connectivity" on the same node. In the health store, these reports are treated as separate health events for the specified node. Together with the SourceId, the property uniquely identifies the health information.
  --remove-when-expired: oneof<nothing, bool> # Value that indicates whether the report is removed from health store when it expires. If set to true, the report is removed from the health store after it expires. If set to false, the report is treated as an error when expired. The value of this property is false by default. When clients report periodically, they should set RemoveWhenExpired false (default). This way, if the reporter has issues (e.g. deadlock) and can't report, the entity is evaluated at error when the health report expires. This flags the entity as being in Error health state.
  --sequence-number: string # The sequence number for this health report as a numeric string. The report sequence number is used by the health store to detect stale reports. If not specified, a sequence number is auto-generated by the health client when a report is added.
  source_id: string # The source name that identifies the client/watchdog/system component that generated the health information.
  --time-to-live-in-milli-seconds: string # The duration for which this health report is valid. This field uses ISO8601 format for specifying the duration. When clients report periodically, they should send reports with higher frequency than time to live. If clients report on transition, they can set the time to live to infinite. When time to live expires, the health event that contains the health information is either removed from health store, if RemoveWhenExpired is true, or evaluated at error, if RemoveWhenExpired false. If not specified, time to live defaults to infinite value. (format: duration)
]: any -> any {
  $in | http-request {
    method: post
    path: "/Services/{serviceId}/$/ReportHealth"
    path_params: [{name: serviceId, var: service_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: Immediate, var: immediate}, {name: timeout, var: timeout}]
    body: {content_type: "application/json", kind: json, fields: [{name: Description, var: description}, {name: HealthState, var: health_state}, {name: Property, var: property}, {name: RemoveWhenExpired, var: remove_when_expired}, {name: SequenceNumber, var: sequence_number}, {name: SourceId, var: source_id}, {name: TimeToLiveInMilliSeconds, var: time_to_live_in_milli_seconds}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_id: $service_id, api_version: $api_version, immediate: $immediate, timeout: $timeout, description: $description, health_state: $health_state, property: $property, remove_when_expired: $remove_when_expired, sequence_number: $sequence_number, source_id: $source_id, time_to_live_in_milli_seconds: $time_to_live_in_milli_seconds
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resolve a Service Fabric partition.
#
# GET /Services/{serviceId}/$/ResolvePartition
# Returns: record<Endpoints: table<Address: string, Kind: string>, Name: string, PartitionInformation: record<Id: string, ServicePartitionKind: string>, Version: string>
# operationId: ResolveService
export def "resolve-service" [
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --partition-key-type: int # Key type for the partition. This parameter is required if the partition scheme for the service is Int64Range or Named. The possible values are following. - None (1) - Indicates that the PartitionKeyValue parameter is not specified. This is valid for the partitions with partitioning scheme as Singleton. This is the default value. The value is 1. - Int64Range (2) - Indicates that the PartitionKeyValue parameter is an int64 partition key. This is valid for the partitions with partitioning scheme as Int64Range. The value is 2. - Named (3) - Indicates that the PartitionKeyValue parameter is a name of the partition. This is valid for the partitions with partitioning scheme as Named. The value is 3.
  --partition-key-value: string # Partition key. This is required if the partition scheme for the service is Int64Range or Named. This is not the partition ID, but rather, either the integer key value, or the name of the partition ID. For example, if your service is using ranged partitions from 0 to 10, then they PartitionKeyValue would be an integer in that range. Query service description to see the range or name.
  --previous-rsp-version: string # The value in the Version field of the response that was received previously. This is required if the user knows that the result that was gotten previously is stale.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Services/{serviceId}/$/ResolvePartition"
    path_params: [{name: serviceId, var: service_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: PartitionKeyType, var: partition_key_type}, {name: PartitionKeyValue, var: partition_key_value}, {name: PreviousRspVersion, var: previous_rsp_version}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_id: $service_id, api_version: $api_version, partition_key_type: $partition_key_type, partition_key_value: $partition_key_value, previous_rsp_version: $previous_rsp_version, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resumes periodic backup of a Service Fabric service which was previously suspended.
#
# POST /Services/{serviceId}/$/ResumeBackup
# operationId: ResumeServiceBackup
export def "resume-service-backup" [
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> any {
  http-request {
    method: post
    path: "/Services/{serviceId}/$/ResumeBackup"
    path_params: [{name: serviceId, var: service_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.4"}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    service_id: $service_id, api_version: $api_version, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Suspends periodic backup for the specified Service Fabric service.
#
# POST /Services/{serviceId}/$/SuspendBackup
# operationId: SuspendServiceBackup
export def "suspend-service-backup" [
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> any {
  http-request {
    method: post
    path: "/Services/{serviceId}/$/SuspendBackup"
    path_params: [{name: serviceId, var: service_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.4"}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    service_id: $service_id, api_version: $api_version, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a Service Fabric service using the specified update description.
#
# POST /Services/{serviceId}/$/Update
# Discriminator (request): ServiceKind
# operationId: UpdateService
export def "update-service" [
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --correlation-scheme: list # A list that describes the correlation of the service with other services. — item shape: {Scheme: "Invalid"|"Affinity"|"AlignedAffinity"|"NonAlignedAffinity", ServiceName: string}
  --default-move-cost: string@default-move-cost-completer # Specifies the move cost for the service.
  --flags: string # Flags indicating whether other properties are set. Each of the associated properties corresponds to a flag, specified below, which, if set, indicate that the property is specified. This property can be a combination of those flags obtained using bitwise 'OR' operator. For example, if the provided value is 6 then the flags for ReplicaRestartWaitDuration (2) and QuorumLossWaitDuration (4) are set. - None - Does not indicate any other properties are set. The value is zero. - TargetReplicaSetSize/InstanceCount - Indicates whether the TargetReplicaSetSize property (for Stateful services) or the InstanceCount property (for Stateless services) is set. The value is 1. - ReplicaRestartWaitDuration - Indicates the ReplicaRestartWaitDuration property is set. The value is 2. - QuorumLossWaitDuration - Indicates the QuorumLossWaitDuration property is set. The value is 4. - StandByReplicaKeepDuration - Indicates the StandByReplicaKeepDuration property is set. The value is 8. - MinReplicaSetSize - Indicates the MinReplicaSetSize property is set. The value is 16. - PlacementConstraints - Indicates the PlacementConstraints property is set. The value is 32. - PlacementPolicyList - Indicates the ServicePlacementPolicies property is set. The value is 64. - Correlation - Indicates the CorrelationScheme property is set. The value is 128. - Metrics - Indicates the ServiceLoadMetrics property is set. The value is 256. - DefaultMoveCost - Indicates the DefaultMoveCost property is set. The value is 512. - ScalingPolicy - Indicates the ScalingPolicies property is set. The value is 1024.
  --load-metrics: list # The service load metrics is given as an array of ServiceLoadMetricDescription objects. — item shape: {DefaultLoad?: int, Name: string, PrimaryDefaultLoad?: int, SecondaryDefaultLoad?: int, Weight?: "Zero"|"Low"|"Medium"|"High"}
  --placement-constraints: string # The placement constraints as a string. Placement constraints are boolean expressions on node properties and allow for restricting a service to particular nodes based on the service requirements. For example, to place a service on nodes where NodeType is blue specify the following: "NodeColor == blue)".
  --scaling-policies: list # A list that describes the scaling policies. — item shape: {ScalingMechanism: any, ScalingTrigger: any}
  service_kind: string@service-kind-completer # The kind of service (Stateless or Stateful).
  --service-placement-policies: list # A list that describes the correlation of the service with other services. — item shape: {Type: "Invalid"|"InvalidDomain"|"RequireDomain"|"PreferPrimaryDomain"|"RequireDomainDistribution"|"NonPartiallyPlaceService"}
]: any -> any {
  $in | http-request {
    method: post
    path: "/Services/{serviceId}/$/Update"
    path_params: [{name: serviceId, var: service_id}]
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: timeout, var: timeout}]
    body: {content_type: "application/json", kind: json, fields: [{name: CorrelationScheme, var: correlation_scheme}, {name: DefaultMoveCost, var: default_move_cost}, {name: Flags, var: flags}, {name: LoadMetrics, var: load_metrics}, {name: PlacementConstraints, var: placement_constraints}, {name: ScalingPolicies, var: scaling_policies}, {name: ServiceKind, var: service_kind}, {name: ServicePlacementPolicies, var: service_placement_policies}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_id: $service_id, api_version: $api_version, timeout: $timeout, correlation_scheme: $correlation_scheme, default_move_cost: $default_move_cost, flags: $flags, load_metrics: $load_metrics, placement_constraints: $placement_constraints, scaling_policies: $scaling_policies, service_kind: $service_kind, service_placement_policies: $service_placement_policies
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the status of Chaos.
#
# GET /Tools/Chaos
# Returns: record<ChaosParameters: record<ChaosTargetFilter: record<ApplicationInclusionList: list, NodeTypeInclusionList: list>, ClusterHealthPolicy: record<ApplicationTypeHealthPolicyMap: list, ConsiderWarningAsError: bool, MaxPercentUnhealthyApplications: int, MaxPercentUnhealthyNodes: int>, Context: record<Map: any>, EnableMoveReplicaFaults: bool, MaxClusterStabilizationTimeoutInSeconds: int, MaxConcurrentFaults: int, TimeToRunInSeconds: string, WaitTimeBetweenFaultsInSeconds: int, WaitTimeBetweenIterationsInSeconds: int>, ScheduleStatus: string, Status: string>
# operationId: GetChaos
export def "get-chaos" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-2 # The version of the API. This parameter is required and its value must be '6.2'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.2)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Tools/Chaos"
    query: [{name: api-version, var: api_version, required: true, default: "6.2"}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts Chaos in the cluster.
#
# POST /Tools/Chaos/$/Start
# operationId: StartChaos
export def "start-chaos" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --chaos-target-filter: any # Defines all filters for targeted Chaos faults, for example, faulting only certain node types or faulting only certain applications. If ChaosTargetFilter is not used, Chaos faults all cluster entities. If ChaosTargetFilter is used, Chaos faults only the entities that meet the ChaosTargetFilter specification. NodeTypeInclusionList and ApplicationInclusionList allow a union semantics only. It is not possible to specify an intersection of NodeTypeInclusionList and ApplicationInclusionList. For example, it is not possible to specify "fault this application only when it is on that node type." Once an entity is included in either NodeTypeInclusionList or ApplicationInclusionList, that entity cannot be excluded using ChaosTargetFilter. Even if applicationX does not appear in ApplicationInclusionList, in some Chaos iteration applicationX can be faulted because it happens to be on a node of nodeTypeY that is included in NodeTypeInclusionList. If both NodeTypeInclusionList and ApplicationInclusionList are null or empty, an ArgumentException is thrown. — shape: {ApplicationInclusionList?: list<string>, NodeTypeInclusionList?: list<string>}
  --cluster-health-policy: any # Defines a health policy used to evaluate the health of the cluster or of a cluster node. — shape: {ApplicationTypeHealthPolicyMap?: list, ConsiderWarningAsError?: bool, MaxPercentUnhealthyApplications?: int, MaxPercentUnhealthyNodes?: int}
  --context: any # Describes a map, which is a collection of (string, string) type key-value pairs. The map can be used to record information about the Chaos run. There cannot be more than 100 such pairs and each string (key or value) can be at most 4095 characters long. This map is set by the starter of the Chaos run to optionally store the context about the specific run. — shape: {Map?: any}
  --enable-move-replica-faults: oneof<nothing, bool> # Enables or disables the move primary and move secondary faults. (default: true)
  --max-cluster-stabilization-timeout-in-seconds: int # The maximum amount of time to wait for all cluster entities to become stable and healthy. Chaos executes in iterations and at the start of each iteration it validates the health of cluster entities. During validation if a cluster entity is not stable and healthy within MaxClusterStabilizationTimeoutInSeconds, Chaos generates a validation failed event. (format: int64, default: 60)
  --max-concurrent-faults: int # MaxConcurrentFaults is the maximum number of concurrent faults induced per iteration. Chaos executes in iterations and two consecutive iterations are separated by a validation phase. The higher the concurrency, the more aggressive the injection of faults, leading to inducing more complex series of states to uncover bugs. The recommendation is to start with a value of 2 or 3 and to exercise caution while moving up. (format: int64, default: 1)
  --time-to-run-in-seconds: string # Total time (in seconds) for which Chaos will run before automatically stopping. The maximum allowed value is 4,294,967,295 (System.UInt32.MaxValue). (default: 4294967295)
  --wait-time-between-faults-in-seconds: int # Wait time (in seconds) between consecutive faults within a single iteration. The larger the value, the lower the overlapping between faults and the simpler the sequence of state transitions that the cluster goes through. The recommendation is to start with a value between 1 and 5 and exercise caution while moving up. (format: int64, default: 20)
  --wait-time-between-iterations-in-seconds: int # Time-separation (in seconds) between two consecutive iterations of Chaos. The larger the value, the lower the fault injection rate. (format: int64, default: 30)
]: any -> any {
  $in | http-request {
    method: post
    path: "/Tools/Chaos/$/Start"
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: timeout, var: timeout}]
    body: {content_type: "application/json", kind: json, fields: [{name: ChaosTargetFilter, var: chaos_target_filter}, {name: ClusterHealthPolicy, var: cluster_health_policy}, {name: Context, var: context}, {name: EnableMoveReplicaFaults, var: enable_move_replica_faults}, {name: MaxClusterStabilizationTimeoutInSeconds, var: max_cluster_stabilization_timeout_in_seconds}, {name: MaxConcurrentFaults, var: max_concurrent_faults}, {name: TimeToRunInSeconds, var: time_to_run_in_seconds}, {name: WaitTimeBetweenFaultsInSeconds, var: wait_time_between_faults_in_seconds}, {name: WaitTimeBetweenIterationsInSeconds, var: wait_time_between_iterations_in_seconds}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, timeout: $timeout, chaos_target_filter: $chaos_target_filter, cluster_health_policy: $cluster_health_policy, context: $context, enable_move_replica_faults: $enable_move_replica_faults, max_cluster_stabilization_timeout_in_seconds: $max_cluster_stabilization_timeout_in_seconds, max_concurrent_faults: $max_concurrent_faults, time_to_run_in_seconds: $time_to_run_in_seconds, wait_time_between_faults_in_seconds: $wait_time_between_faults_in_seconds, wait_time_between_iterations_in_seconds: $wait_time_between_iterations_in_seconds
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stops Chaos if it is running in the cluster and put the Chaos Schedule in a stopped state.
#
# POST /Tools/Chaos/$/Stop
# operationId: StopChaos
export def "stop-chaos" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> any {
  http-request {
    method: post
    path: "/Tools/Chaos/$/Stop"
    query: [{name: api-version, var: api_version, required: true, default: "6.0"}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the next segment of the Chaos events based on the continuation token or the time range.
#
# GET /Tools/Chaos/Events
# Returns: record<ContinuationToken: string, History: table<ChaosEvent: record>>
# operationId: GetChaosEvents
export def "get-chaos-events" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-2 # The version of the API. This parameter is required and its value must be '6.2'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.2)
  --continuation-token: string # The continuation token parameter is used to obtain next set of results. A continuation token with a non-empty value is included in the response of the API when the results from the system do not fit in a single response. When this value is passed to the next API call, the API returns next set of results. If there are no further results, then the continuation token does not contain a value. The value of this parameter should not be URL encoded.
  --start-time-utc: string # The Windows file time representing the start time of the time range for which a Chaos report is to be generated. Consult [DateTime.ToFileTimeUtc Method](https://msdn.microsoft.com/library/system.datetime.tofiletimeutc(v=vs.110).aspx) for details.
  --end-time-utc: string # The Windows file time representing the end time of the time range for which a Chaos report is to be generated. Consult [DateTime.ToFileTimeUtc Method](https://msdn.microsoft.com/library/system.datetime.tofiletimeutc(v=vs.110).aspx) for details.
  --max-results: int # The maximum number of results to be returned as part of the paged queries. This parameter defines the upper bound on the number of results returned. The results returned can be less than the specified maximum results if they do not fit in the message as per the max message size restrictions defined in the configuration. If this parameter is zero or not specified, the paged query includes as many results as possible that fit in the return message. (format: int64, default: 0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Tools/Chaos/Events"
    query: [{name: api-version, var: api_version, required: true, default: "6.2"}, {name: ContinuationToken, var: continuation_token}, {name: StartTimeUtc, var: start_time_utc}, {name: EndTimeUtc, var: end_time_utc}, {name: MaxResults, var: max_results}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, continuation_token: $continuation_token, start_time_utc: $start_time_utc, end_time_utc: $end_time_utc, max_results: $max_results, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the Chaos Schedule defining when and how to run Chaos.
#
# GET /Tools/Chaos/Schedule
# Returns: record<Schedule: record<ChaosParametersDictionary: list<record>, ExpiryDate: string, Jobs: list<record>, StartDate: string>, Version: int>
# operationId: GetChaosSchedule
export def "get-chaos-schedule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-2 # The version of the API. This parameter is required and its value must be '6.2'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.2)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Tools/Chaos/Schedule"
    query: [{name: api-version, var: api_version, required: true, default: "6.2"}, {name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the schedule used by Chaos.
#
# POST /Tools/Chaos/Schedule
# operationId: PostChaosSchedule
export def "post-chaos-schedule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-2 # The version of the API. This parameter is required and its value must be '6.2'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (required, default: 6.2)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --schedule: any # Defines the schedule used by Chaos. — shape: {ChaosParametersDictionary?: list, ExpiryDate?: string, Jobs?: list, StartDate?: string}
  --version: int # The version number of the Schedule. (format: int32)
]: any -> any {
  $in | http-request {
    method: post
    path: "/Tools/Chaos/Schedule"
    query: [{name: api-version, var: api_version, required: true, default: "6.2"}, {name: timeout, var: timeout}]
    body: {content_type: "application/json", kind: json, fields: [{name: Schedule, var: schedule}, {name: Version, var: version}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, timeout: $timeout, schedule: $schedule, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
