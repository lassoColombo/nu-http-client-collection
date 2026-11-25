# Auto-generated client for NetworkManagementClient v2019-07-01
# Source: https://api.apis.guru/v2/specs/azure.com/network-virtualNetworkGateway/2019-07-01/swagger.json
# Auth: --token flag or $env.NETWORKMANAGEMENTCLIENT_TOKEN

const CLIENT = {
  base_url: "https://management.azure.com"
  token_env_var: "NETWORKMANAGEMENTCLIENT_TOKEN"
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

def base-url-completer [] { ["https://management.azure.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def authentication-method-completer [] { ["EAPMSCHAPv2" "EAPTLS"] }
def processor-architecture-completer [] { ["Amd64" "X86"] }
def dh-group-completer [] { ["DHGroup1" "DHGroup14" "DHGroup2" "DHGroup2048" "DHGroup24" "ECP256" "ECP384" "None"] }
def ike-encryption-completer [] { ["AES128" "AES192" "AES256" "DES" "DES3" "GCMAES128" "GCMAES256"] }
def ike-integrity-completer [] { ["GCMAES128" "GCMAES256" "MD5" "SHA1" "SHA256" "SHA384"] }
def ipsec-encryption-completer [] { ["AES128" "AES192" "AES256" "DES" "DES3" "GCMAES128" "GCMAES192" "GCMAES256" "None"] }
def ipsec-integrity-completer [] { ["GCMAES128" "GCMAES192" "GCMAES256" "MD5" "SHA1" "SHA256"] }
def pfs-group-completer [] { ["ECP256" "ECP384" "None" "PFS1" "PFS14" "PFS2" "PFS2048" "PFS24" "PFSMM"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    virtual-network-gateway-connections-list: "record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    virtual-network-gateway-connections-get: "record<etag: string, properties: record<authorizationKey: string, connectionProtocol: string, connectionStatus: string, connectionType: string, egressBytesTransferred: int, enableBgp: bool, expressRouteGatewayBypass: bool, ingressBytesTransferred: int, ipsecPolicies: list<record>, localNetworkGateway2: record<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>, peer: record<id: string>, provisioningState: string, resourceGuid: string, routingWeight: int, sharedKey: string, trafficSelectorPolicies: list<record>, tunnelConnectionStatus: list<record>, usePolicyBasedTrafficSelectors: bool, virtualNetworkGateway1: record<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>, virtualNetworkGateway2: record<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>, id: string, location: string, name: string, tags: record, type: string>"
    virtual-network-gateway-connections-update-tags: "record<etag: string, properties: record<authorizationKey: string, connectionProtocol: string, connectionStatus: string, connectionType: string, egressBytesTransferred: int, enableBgp: bool, expressRouteGatewayBypass: bool, ingressBytesTransferred: int, ipsecPolicies: list<record>, localNetworkGateway2: record<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>, peer: record<id: string>, provisioningState: string, resourceGuid: string, routingWeight: int, sharedKey: string, trafficSelectorPolicies: list<record>, tunnelConnectionStatus: list<record>, usePolicyBasedTrafficSelectors: bool, virtualNetworkGateway1: record<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>, virtualNetworkGateway2: record<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>, id: string, location: string, name: string, tags: record, type: string>"
    virtual-network-gateway-connections-create-or-update: "record<etag: string, properties: record<authorizationKey: string, connectionProtocol: string, connectionStatus: string, connectionType: string, egressBytesTransferred: int, enableBgp: bool, expressRouteGatewayBypass: bool, ingressBytesTransferred: int, ipsecPolicies: list<record>, localNetworkGateway2: record<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>, peer: record<id: string>, provisioningState: string, resourceGuid: string, routingWeight: int, sharedKey: string, trafficSelectorPolicies: list<record>, tunnelConnectionStatus: list<record>, usePolicyBasedTrafficSelectors: bool, virtualNetworkGateway1: record<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>, virtualNetworkGateway2: record<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>, id: string, location: string, name: string, tags: record, type: string>"
    virtual-network-gateway-connections-get-shared-key: "record<value: string, id: string>"
    virtual-network-gateway-connections-set-shared-key: "record<value: string, id: string>"
    virtual-network-gateway-connections-reset-shared-key: "record<keyLength: int>"
    virtual-network-gateway-connections-start-packet-capture: "string"
    virtual-network-gateway-connections-stop-packet-capture: "string"
    virtual-network-gateways-vpn-device-configuration-script: "string"
    local-network-gateways-list: "record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    local-network-gateways-get: "record<etag: string, properties: record<bgpSettings: record<asn: int, bgpPeeringAddress: string, peerWeight: int>, gatewayIpAddress: string, localNetworkAddressSpace: record<addressPrefixes: list>, provisioningState: string, resourceGuid: string>, id: string, location: string, name: string, tags: record, type: string>"
    local-network-gateways-update-tags: "record<etag: string, properties: record<bgpSettings: record<asn: int, bgpPeeringAddress: string, peerWeight: int>, gatewayIpAddress: string, localNetworkAddressSpace: record<addressPrefixes: list>, provisioningState: string, resourceGuid: string>, id: string, location: string, name: string, tags: record, type: string>"
    local-network-gateways-create-or-update: "record<etag: string, properties: record<bgpSettings: record<asn: int, bgpPeeringAddress: string, peerWeight: int>, gatewayIpAddress: string, localNetworkAddressSpace: record<addressPrefixes: list>, provisioningState: string, resourceGuid: string>, id: string, location: string, name: string, tags: record, type: string>"
    virtual-network-gateways-list: "record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    virtual-network-gateways-get: "record<etag: string, properties: record<activeActive: bool, bgpSettings: record<asn: int, bgpPeeringAddress: string, peerWeight: int>, customRoutes: record<addressPrefixes: list>, enableBgp: bool, gatewayDefaultSite: record<id: string>, gatewayType: string, ipConfigurations: list<record>, provisioningState: string, resourceGuid: string, sku: record<capacity: int, name: string, tier: string>, vpnClientConfiguration: record<aadAudience: string, aadIssuer: string, aadTenant: string, radiusServerAddress: string, radiusServerSecret: string, vpnClientAddressPool: record, vpnClientIpsecPolicies: list, vpnClientProtocols: list, vpnClientRevokedCertificates: list, vpnClientRootCertificates: list>, vpnGatewayGeneration: string, vpnType: string>, id: string, location: string, name: string, tags: record, type: string>"
    virtual-network-gateways-update-tags: "record<etag: string, properties: record<activeActive: bool, bgpSettings: record<asn: int, bgpPeeringAddress: string, peerWeight: int>, customRoutes: record<addressPrefixes: list>, enableBgp: bool, gatewayDefaultSite: record<id: string>, gatewayType: string, ipConfigurations: list<record>, provisioningState: string, resourceGuid: string, sku: record<capacity: int, name: string, tier: string>, vpnClientConfiguration: record<aadAudience: string, aadIssuer: string, aadTenant: string, radiusServerAddress: string, radiusServerSecret: string, vpnClientAddressPool: record, vpnClientIpsecPolicies: list, vpnClientProtocols: list, vpnClientRevokedCertificates: list, vpnClientRootCertificates: list>, vpnGatewayGeneration: string, vpnType: string>, id: string, location: string, name: string, tags: record, type: string>"
    virtual-network-gateways-create-or-update: "record<etag: string, properties: record<activeActive: bool, bgpSettings: record<asn: int, bgpPeeringAddress: string, peerWeight: int>, customRoutes: record<addressPrefixes: list>, enableBgp: bool, gatewayDefaultSite: record<id: string>, gatewayType: string, ipConfigurations: list<record>, provisioningState: string, resourceGuid: string, sku: record<capacity: int, name: string, tier: string>, vpnClientConfiguration: record<aadAudience: string, aadIssuer: string, aadTenant: string, radiusServerAddress: string, radiusServerSecret: string, vpnClientAddressPool: record, vpnClientIpsecPolicies: list, vpnClientProtocols: list, vpnClientRevokedCertificates: list, vpnClientRootCertificates: list>, vpnGatewayGeneration: string, vpnType: string>, id: string, location: string, name: string, tags: record, type: string>"
    virtual-network-gateways-list-connections: "record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    virtual-network-gateways-generatevpnclientpackage: "string"
    virtual-network-gateways-generate-vpn-profile: "string"
    virtual-network-gateways-get-advertised-routes: "record<value: table<asPath: string, localAddress: string, network: string, nextHop: string, origin: string, sourcePeer: string, weight: int>>"
    virtual-network-gateways-get-bgp-peer-status: "record<value: table<asn: int, connectedDuration: string, localAddress: string, messagesReceived: int, messagesSent: int, neighbor: string, routesReceived: int, state: string>>"
    virtual-network-gateways-get-learned-routes: "record<value: table<asPath: string, localAddress: string, network: string, nextHop: string, origin: string, sourcePeer: string, weight: int>>"
    virtual-network-gateways-get-vpnclient-connection-health: "record<value: table<egressBytesTransferred: int, egressPacketsTransferred: int, ingressBytesTransferred: int, ingressPacketsTransferred: int, maxBandwidth: int, maxPacketsPerSecond: int, privateIpAddress: string, publicIpAddress: string, vpnConnectionDuration: int, vpnConnectionId: string, vpnConnectionTime: string, vpnUserName: string>>"
    virtual-network-gateways-get-vpnclient-ipsec-parameters: "record<dhGroup: string, ikeEncryption: string, ikeIntegrity: string, ipsecEncryption: string, ipsecIntegrity: string, pfsGroup: string, saDataSizeKilobytes: int, saLifeTimeSeconds: int>"
    virtual-network-gateways-get-vpn-profile-package-url: "string"
    virtual-network-gateways-reset: "record<etag: string, properties: record<activeActive: bool, bgpSettings: record<asn: int, bgpPeeringAddress: string, peerWeight: int>, customRoutes: record<addressPrefixes: list>, enableBgp: bool, gatewayDefaultSite: record<id: string>, gatewayType: string, ipConfigurations: list<record>, provisioningState: string, resourceGuid: string, sku: record<capacity: int, name: string, tier: string>, vpnClientConfiguration: record<aadAudience: string, aadIssuer: string, aadTenant: string, radiusServerAddress: string, radiusServerSecret: string, vpnClientAddressPool: record, vpnClientIpsecPolicies: list, vpnClientProtocols: list, vpnClientRevokedCertificates: list, vpnClientRootCertificates: list>, vpnGatewayGeneration: string, vpnType: string>, id: string, location: string, name: string, tags: record, type: string>"
    virtual-network-gateways-set-vpnclient-ipsec-parameters: "record<dhGroup: string, ikeEncryption: string, ikeIntegrity: string, ipsecEncryption: string, ipsecIntegrity: string, pfsGroup: string, saDataSizeKilobytes: int, saLifeTimeSeconds: int>"
    virtual-network-gateways-start-packet-capture: "string"
    virtual-network-gateways-stop-packet-capture: "string"
    virtual-network-gateways-supported-vpn-devices: "string"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["virtual-network-gateway-connections-list" "virtual-network-gateway-connections-delete" "virtual-network-gateway-connections-get" "virtual-network-gateway-connections-update-tags" "virtual-network-gateway-connections-create-or-update" "virtual-network-gateway-connections-get-shared-key" "virtual-network-gateway-connections-set-shared-key" "virtual-network-gateway-connections-reset-shared-key" "virtual-network-gateway-connections-start-packet-capture" "virtual-network-gateway-connections-stop-packet-capture" "virtual-network-gateways-vpn-device-configuration-script" "local-network-gateways-list" "local-network-gateways-delete" "local-network-gateways-get" "local-network-gateways-update-tags" "local-network-gateways-create-or-update" "virtual-network-gateways-list" "virtual-network-gateways-delete" "virtual-network-gateways-get" "virtual-network-gateways-update-tags" "virtual-network-gateways-create-or-update" "virtual-network-gateways-list-connections" "virtual-network-gateways-generatevpnclientpackage" "virtual-network-gateways-generate-vpn-profile" "virtual-network-gateways-get-advertised-routes" "virtual-network-gateways-get-bgp-peer-status" "virtual-network-gateways-get-learned-routes" "virtual-network-gateways-get-vpnclient-connection-health" "virtual-network-gateways-get-vpnclient-ipsec-parameters" "virtual-network-gateways-get-vpn-profile-package-url" "virtual-network-gateways-reset" "virtual-network-gateways-reset-vpn-client-shared-key" "virtual-network-gateways-set-vpnclient-ipsec-parameters" "virtual-network-gateways-start-packet-capture" "virtual-network-gateways-stop-packet-capture" "virtual-network-gateways-supported-vpn-devices" "commands"] | sort) } | get name | first)
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

# The List VirtualNetworkGatewayConnections operation retrieves all the virtual network gateways connections created.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/connections
# Returns: record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: VirtualNetworkGatewayConnections_List
export def "virtual-network-gateway-connections-list" [
  subscription_id: string
  resource_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/connections"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified virtual network Gateway connection.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/connections/{virtualNetworkGatewayConnectionName}
# operationId: VirtualNetworkGatewayConnections_Delete
export def "virtual-network-gateway-connections-delete" [
  subscription_id: string
  resource_group_name: string
  virtual_network_gateway_connection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/connections/{virtualNetworkGatewayConnectionName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: virtualNetworkGatewayConnectionName, var: virtual_network_gateway_connection_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_network_gateway_connection_name: $virtual_network_gateway_connection_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the specified virtual network gateway connection by resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/connections/{virtualNetworkGatewayConnectionName}
# Returns: record<etag: string, properties: record<authorizationKey: string, connectionProtocol: string, connectionStatus: string, connectionType: string, egressBytesTransferred: int, enableBgp: bool, expressRouteGatewayBypass: bool, ingressBytesTransferred: int, ipsecPolicies: list<record>, localNetworkGateway2: record<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>, peer: record<id: string>, provisioningState: string, resourceGuid: string, routingWeight: int, sharedKey: string, trafficSelectorPolicies: list<record>, tunnelConnectionStatus: list<record>, usePolicyBasedTrafficSelectors: bool, virtualNetworkGateway1: record<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>, virtualNetworkGateway2: record<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>, id: string, location: string, name: string, tags: record, type: string>
# operationId: VirtualNetworkGatewayConnections_Get
export def "virtual-network-gateway-connections-get" [
  subscription_id: string
  resource_group_name: string
  virtual_network_gateway_connection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/connections/{virtualNetworkGatewayConnectionName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: virtualNetworkGatewayConnectionName, var: virtual_network_gateway_connection_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_network_gateway_connection_name: $virtual_network_gateway_connection_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a virtual network gateway connection tags.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/connections/{virtualNetworkGatewayConnectionName}
# Returns: record<etag: string, properties: record<authorizationKey: string, connectionProtocol: string, connectionStatus: string, connectionType: string, egressBytesTransferred: int, enableBgp: bool, expressRouteGatewayBypass: bool, ingressBytesTransferred: int, ipsecPolicies: list<record>, localNetworkGateway2: record<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>, peer: record<id: string>, provisioningState: string, resourceGuid: string, routingWeight: int, sharedKey: string, trafficSelectorPolicies: list<record>, tunnelConnectionStatus: list<record>, usePolicyBasedTrafficSelectors: bool, virtualNetworkGateway1: record<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>, virtualNetworkGateway2: record<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>, id: string, location: string, name: string, tags: record, type: string>
# operationId: VirtualNetworkGatewayConnections_UpdateTags
export def "virtual-network-gateway-connections-update-tags" [
  subscription_id: string
  resource_group_name: string
  virtual_network_gateway_connection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required)
  --tags: record # Resource tags.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/connections/{virtualNetworkGatewayConnectionName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: virtualNetworkGatewayConnectionName, var: virtual_network_gateway_connection_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_network_gateway_connection_name: $virtual_network_gateway_connection_name, api_version: $api_version, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates or updates a virtual network gateway connection in the specified resource group.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/connections/{virtualNetworkGatewayConnectionName}
# Returns: record<etag: string, properties: record<authorizationKey: string, connectionProtocol: string, connectionStatus: string, connectionType: string, egressBytesTransferred: int, enableBgp: bool, expressRouteGatewayBypass: bool, ingressBytesTransferred: int, ipsecPolicies: list<record>, localNetworkGateway2: record<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>, peer: record<id: string>, provisioningState: string, resourceGuid: string, routingWeight: int, sharedKey: string, trafficSelectorPolicies: list<record>, tunnelConnectionStatus: list<record>, usePolicyBasedTrafficSelectors: bool, virtualNetworkGateway1: record<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>, virtualNetworkGateway2: record<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>, id: string, location: string, name: string, tags: record, type: string>
# operationId: VirtualNetworkGatewayConnections_CreateOrUpdate
export def "virtual-network-gateway-connections-create-or-update" [
  subscription_id: string
  resource_group_name: string
  virtual_network_gateway_connection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required)
  --etag: string # A unique read-only string that changes whenever the resource is updated.
  properties: any # VirtualNetworkGatewayConnection properties. — shape: {authorizationKey?: string, connectionProtocol?: "IKEv2"|"IKEv1", connectionStatus?: "Unknown"|"Connecting"|"Connected"|"NotConnected", connectionType: "IPsec"|"Vnet2Vnet"|"ExpressRoute"|"VPNClient", enableBgp?: bool, expressRouteGatewayBypass?: bool, ipsecPolicies?: list, localNetworkGateway2?: any, peer?: any, resourceGuid?: string, routingWeight?: int, sharedKey?: string, trafficSelectorPolicies?: list, usePolicyBasedTrafficSelectors?: bool, virtualNetworkGateway1: any, ... (1 more fields)}
  --id: string # Resource ID.
  --location: string # Resource location.
  --tags: record # Resource tags.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/connections/{virtualNetworkGatewayConnectionName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: virtualNetworkGatewayConnectionName, var: virtual_network_gateway_connection_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: etag, var: etag}, {name: properties, var: properties}, {name: id, var: id}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_network_gateway_connection_name: $virtual_network_gateway_connection_name, api_version: $api_version, etag: $etag, properties: $properties, id: $id, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The Get VirtualNetworkGatewayConnectionSharedKey operation retrieves information about the specified virtual network gateway connection shared key through Network resource provider.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/connections/{virtualNetworkGatewayConnectionName}/sharedkey
# Returns: record<value: string, id: string>
# operationId: VirtualNetworkGatewayConnections_GetSharedKey
export def "virtual-network-gateway-connections-get-shared-key" [
  subscription_id: string
  resource_group_name: string
  virtual_network_gateway_connection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/connections/{virtualNetworkGatewayConnectionName}/sharedkey"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: virtualNetworkGatewayConnectionName, var: virtual_network_gateway_connection_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_network_gateway_connection_name: $virtual_network_gateway_connection_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The Put VirtualNetworkGatewayConnectionSharedKey operation sets the virtual network gateway connection shared key for passed virtual network gateway connection in the specified resource group through Network resource provider.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/connections/{virtualNetworkGatewayConnectionName}/sharedkey
# Returns: record<value: string, id: string>
# operationId: VirtualNetworkGatewayConnections_SetSharedKey
export def "virtual-network-gateway-connections-set-shared-key" [
  subscription_id: string
  resource_group_name: string
  virtual_network_gateway_connection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required)
  value: string # The virtual network connection shared key value.
  --id: string # Resource ID.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/connections/{virtualNetworkGatewayConnectionName}/sharedkey"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: virtualNetworkGatewayConnectionName, var: virtual_network_gateway_connection_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}, {name: id, var: id}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_network_gateway_connection_name: $virtual_network_gateway_connection_name, api_version: $api_version, value: $value, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The VirtualNetworkGatewayConnectionResetSharedKey operation resets the virtual network gateway connection shared key for passed virtual network gateway connection in the specified resource group through Network resource provider.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/connections/{virtualNetworkGatewayConnectionName}/sharedkey/reset
# Returns: record<keyLength: int>
# operationId: VirtualNetworkGatewayConnections_ResetSharedKey
export def "virtual-network-gateway-connections-reset-shared-key" [
  subscription_id: string
  resource_group_name: string
  virtual_network_gateway_connection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required)
  key_length: int # The virtual network connection reset shared key length, should between 1 and 128. (format: int32)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/connections/{virtualNetworkGatewayConnectionName}/sharedkey/reset"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: virtualNetworkGatewayConnectionName, var: virtual_network_gateway_connection_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: keyLength, var: key_length}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_network_gateway_connection_name: $virtual_network_gateway_connection_name, api_version: $api_version, key_length: $key_length
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts packet capture on virtual network gateway connection in the specified resource group.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/connections/{virtualNetworkGatewayConnectionName}/startPacketCapture
# Returns: string
# operationId: VirtualNetworkGatewayConnections_StartPacketCapture
export def "virtual-network-gateway-connections-start-packet-capture" [
  subscription_id: string
  resource_group_name: string
  virtual_network_gateway_connection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required)
  --filter-data: string # Start Packet capture parameters.
]: any -> any {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/connections/{virtualNetworkGatewayConnectionName}/startPacketCapture"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: virtualNetworkGatewayConnectionName, var: virtual_network_gateway_connection_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: filterData, var: filter_data}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_network_gateway_connection_name: $virtual_network_gateway_connection_name, api_version: $api_version, filter_data: $filter_data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stops packet capture on virtual network gateway connection in the specified resource group.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/connections/{virtualNetworkGatewayConnectionName}/stopPacketCapture
# Returns: string
# operationId: VirtualNetworkGatewayConnections_StopPacketCapture
export def "virtual-network-gateway-connections-stop-packet-capture" [
  subscription_id: string
  resource_group_name: string
  virtual_network_gateway_connection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required)
  --sas-url: string # SAS url for packet capture on virtual network gateway.
]: any -> any {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/connections/{virtualNetworkGatewayConnectionName}/stopPacketCapture"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: virtualNetworkGatewayConnectionName, var: virtual_network_gateway_connection_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: sasUrl, var: sas_url}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_network_gateway_connection_name: $virtual_network_gateway_connection_name, api_version: $api_version, sas_url: $sas_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a xml format representation for vpn device configuration script.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/connections/{virtualNetworkGatewayConnectionName}/vpndeviceconfigurationscript
# Returns: string
# operationId: VirtualNetworkGateways_VpnDeviceConfigurationScript
export def "virtual-network-gateways-vpn-device-configuration-script" [
  subscription_id: string
  resource_group_name: string
  virtual_network_gateway_connection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required)
  --device-family: string # The device family for the vpn device.
  --firmware-version: string # The firmware version for the vpn device.
  --vendor: string # The vendor for the vpn device.
]: any -> any {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/connections/{virtualNetworkGatewayConnectionName}/vpndeviceconfigurationscript"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: virtualNetworkGatewayConnectionName, var: virtual_network_gateway_connection_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: deviceFamily, var: device_family}, {name: firmwareVersion, var: firmware_version}, {name: vendor, var: vendor}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_network_gateway_connection_name: $virtual_network_gateway_connection_name, api_version: $api_version, device_family: $device_family, firmware_version: $firmware_version, vendor: $vendor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all the local network gateways in a resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/localNetworkGateways
# Returns: record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: LocalNetworkGateways_List
export def "local-network-gateways-list" [
  subscription_id: string
  resource_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/localNetworkGateways"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified local network gateway.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/localNetworkGateways/{localNetworkGatewayName}
# operationId: LocalNetworkGateways_Delete
export def "local-network-gateways-delete" [
  subscription_id: string
  resource_group_name: string
  local_network_gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/localNetworkGateways/{localNetworkGatewayName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: localNetworkGatewayName, var: local_network_gateway_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, local_network_gateway_name: $local_network_gateway_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the specified local network gateway in a resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/localNetworkGateways/{localNetworkGatewayName}
# Returns: record<etag: string, properties: record<bgpSettings: record<asn: int, bgpPeeringAddress: string, peerWeight: int>, gatewayIpAddress: string, localNetworkAddressSpace: record<addressPrefixes: list>, provisioningState: string, resourceGuid: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: LocalNetworkGateways_Get
export def "local-network-gateways-get" [
  subscription_id: string
  resource_group_name: string
  local_network_gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/localNetworkGateways/{localNetworkGatewayName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: localNetworkGatewayName, var: local_network_gateway_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, local_network_gateway_name: $local_network_gateway_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a local network gateway tags.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/localNetworkGateways/{localNetworkGatewayName}
# Returns: record<etag: string, properties: record<bgpSettings: record<asn: int, bgpPeeringAddress: string, peerWeight: int>, gatewayIpAddress: string, localNetworkAddressSpace: record<addressPrefixes: list>, provisioningState: string, resourceGuid: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: LocalNetworkGateways_UpdateTags
export def "local-network-gateways-update-tags" [
  subscription_id: string
  resource_group_name: string
  local_network_gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required)
  --tags: record # Resource tags.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/localNetworkGateways/{localNetworkGatewayName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: localNetworkGatewayName, var: local_network_gateway_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, local_network_gateway_name: $local_network_gateway_name, api_version: $api_version, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates or updates a local network gateway in the specified resource group.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/localNetworkGateways/{localNetworkGatewayName}
# Returns: record<etag: string, properties: record<bgpSettings: record<asn: int, bgpPeeringAddress: string, peerWeight: int>, gatewayIpAddress: string, localNetworkAddressSpace: record<addressPrefixes: list>, provisioningState: string, resourceGuid: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: LocalNetworkGateways_CreateOrUpdate
export def "local-network-gateways-create-or-update" [
  subscription_id: string
  resource_group_name: string
  local_network_gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required)
  --etag: string # A unique read-only string that changes whenever the resource is updated.
  properties: any # LocalNetworkGateway properties. — shape: {bgpSettings?: any, gatewayIpAddress?: string, localNetworkAddressSpace?: any, resourceGuid?: string}
  --id: string # Resource ID.
  --location: string # Resource location.
  --tags: record # Resource tags.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/localNetworkGateways/{localNetworkGatewayName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: localNetworkGatewayName, var: local_network_gateway_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: etag, var: etag}, {name: properties, var: properties}, {name: id, var: id}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, local_network_gateway_name: $local_network_gateway_name, api_version: $api_version, etag: $etag, properties: $properties, id: $id, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all virtual network gateways by resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworkGateways
# Returns: record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: VirtualNetworkGateways_List
export def "virtual-network-gateways-list" [
  subscription_id: string
  resource_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworkGateways"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified virtual network gateway.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworkGateways/{virtualNetworkGatewayName}
# operationId: VirtualNetworkGateways_Delete
export def "virtual-network-gateways-delete" [
  subscription_id: string
  resource_group_name: string
  virtual_network_gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworkGateways/{virtualNetworkGatewayName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: virtualNetworkGatewayName, var: virtual_network_gateway_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_network_gateway_name: $virtual_network_gateway_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the specified virtual network gateway by resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworkGateways/{virtualNetworkGatewayName}
# Returns: record<etag: string, properties: record<activeActive: bool, bgpSettings: record<asn: int, bgpPeeringAddress: string, peerWeight: int>, customRoutes: record<addressPrefixes: list>, enableBgp: bool, gatewayDefaultSite: record<id: string>, gatewayType: string, ipConfigurations: list<record>, provisioningState: string, resourceGuid: string, sku: record<capacity: int, name: string, tier: string>, vpnClientConfiguration: record<aadAudience: string, aadIssuer: string, aadTenant: string, radiusServerAddress: string, radiusServerSecret: string, vpnClientAddressPool: record, vpnClientIpsecPolicies: list, vpnClientProtocols: list, vpnClientRevokedCertificates: list, vpnClientRootCertificates: list>, vpnGatewayGeneration: string, vpnType: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: VirtualNetworkGateways_Get
export def "virtual-network-gateways-get" [
  subscription_id: string
  resource_group_name: string
  virtual_network_gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworkGateways/{virtualNetworkGatewayName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: virtualNetworkGatewayName, var: virtual_network_gateway_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_network_gateway_name: $virtual_network_gateway_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a virtual network gateway tags.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworkGateways/{virtualNetworkGatewayName}
# Returns: record<etag: string, properties: record<activeActive: bool, bgpSettings: record<asn: int, bgpPeeringAddress: string, peerWeight: int>, customRoutes: record<addressPrefixes: list>, enableBgp: bool, gatewayDefaultSite: record<id: string>, gatewayType: string, ipConfigurations: list<record>, provisioningState: string, resourceGuid: string, sku: record<capacity: int, name: string, tier: string>, vpnClientConfiguration: record<aadAudience: string, aadIssuer: string, aadTenant: string, radiusServerAddress: string, radiusServerSecret: string, vpnClientAddressPool: record, vpnClientIpsecPolicies: list, vpnClientProtocols: list, vpnClientRevokedCertificates: list, vpnClientRootCertificates: list>, vpnGatewayGeneration: string, vpnType: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: VirtualNetworkGateways_UpdateTags
export def "virtual-network-gateways-update-tags" [
  subscription_id: string
  resource_group_name: string
  virtual_network_gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required)
  --tags: record # Resource tags.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworkGateways/{virtualNetworkGatewayName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: virtualNetworkGatewayName, var: virtual_network_gateway_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_network_gateway_name: $virtual_network_gateway_name, api_version: $api_version, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates or updates a virtual network gateway in the specified resource group.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworkGateways/{virtualNetworkGatewayName}
# Returns: record<etag: string, properties: record<activeActive: bool, bgpSettings: record<asn: int, bgpPeeringAddress: string, peerWeight: int>, customRoutes: record<addressPrefixes: list>, enableBgp: bool, gatewayDefaultSite: record<id: string>, gatewayType: string, ipConfigurations: list<record>, provisioningState: string, resourceGuid: string, sku: record<capacity: int, name: string, tier: string>, vpnClientConfiguration: record<aadAudience: string, aadIssuer: string, aadTenant: string, radiusServerAddress: string, radiusServerSecret: string, vpnClientAddressPool: record, vpnClientIpsecPolicies: list, vpnClientProtocols: list, vpnClientRevokedCertificates: list, vpnClientRootCertificates: list>, vpnGatewayGeneration: string, vpnType: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: VirtualNetworkGateways_CreateOrUpdate
export def "virtual-network-gateways-create-or-update" [
  subscription_id: string
  resource_group_name: string
  virtual_network_gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required)
  --etag: string # A unique read-only string that changes whenever the resource is updated.
  properties: any # VirtualNetworkGateway properties. — shape: {activeActive?: bool, bgpSettings?: any, customRoutes?: any, enableBgp?: bool, gatewayDefaultSite?: any, gatewayType?: "Vpn"|"ExpressRoute", ipConfigurations?: list, resourceGuid?: string, sku?: any, vpnClientConfiguration?: any, vpnGatewayGeneration?: "None"|"Generation1"|"Generation2", vpnType?: "PolicyBased"|"RouteBased"}
  --id: string # Resource ID.
  --location: string # Resource location.
  --tags: record # Resource tags.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworkGateways/{virtualNetworkGatewayName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: virtualNetworkGatewayName, var: virtual_network_gateway_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: etag, var: etag}, {name: properties, var: properties}, {name: id, var: id}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_network_gateway_name: $virtual_network_gateway_name, api_version: $api_version, etag: $etag, properties: $properties, id: $id, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all the connections in a virtual network gateway.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworkGateways/{virtualNetworkGatewayName}/connections
# Returns: record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: VirtualNetworkGateways_ListConnections
export def "virtual-network-gateways-list-connections" [
  subscription_id: string
  resource_group_name: string
  virtual_network_gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworkGateways/{virtualNetworkGatewayName}/connections"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: virtualNetworkGatewayName, var: virtual_network_gateway_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_network_gateway_name: $virtual_network_gateway_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generates VPN client package for P2S client of the virtual network gateway in the specified resource group.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworkGateways/{virtualNetworkGatewayName}/generatevpnclientpackage
# Returns: string
# operationId: VirtualNetworkGateways_Generatevpnclientpackage
export def "virtual-network-gateways-generatevpnclientpackage" [
  subscription_id: string
  resource_group_name: string
  virtual_network_gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required)
  --authentication-method: string@authentication-method-completer # VPN client authentication method.
  --client-root-certificates: list<string> # A list of client root certificates public certificate data encoded as Base-64 strings. Optional parameter for external radius based authentication with EAPTLS.
  --processor-architecture: string@processor-architecture-completer # VPN client Processor Architecture.
  --radius-server-auth-certificate: string # The public certificate data for the radius server authentication certificate as a Base-64 encoded string. Required only if external radius authentication has been configured with EAPTLS authentication.
]: any -> any {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworkGateways/{virtualNetworkGatewayName}/generatevpnclientpackage"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: virtualNetworkGatewayName, var: virtual_network_gateway_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: authenticationMethod, var: authentication_method}, {name: clientRootCertificates, var: client_root_certificates}, {name: processorArchitecture, var: processor_architecture}, {name: radiusServerAuthCertificate, var: radius_server_auth_certificate}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_network_gateway_name: $virtual_network_gateway_name, api_version: $api_version, authentication_method: $authentication_method, client_root_certificates: $client_root_certificates, processor_architecture: $processor_architecture, radius_server_auth_certificate: $radius_server_auth_certificate
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generates VPN profile for P2S client of the virtual network gateway in the specified resource group. Used for IKEV2 and radius based authentication.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworkGateways/{virtualNetworkGatewayName}/generatevpnprofile
# Returns: string
# operationId: VirtualNetworkGateways_GenerateVpnProfile
export def "virtual-network-gateways-generate-vpn-profile" [
  subscription_id: string
  resource_group_name: string
  virtual_network_gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required)
  --authentication-method: string@authentication-method-completer # VPN client authentication method.
  --client-root-certificates: list<string> # A list of client root certificates public certificate data encoded as Base-64 strings. Optional parameter for external radius based authentication with EAPTLS.
  --processor-architecture: string@processor-architecture-completer # VPN client Processor Architecture.
  --radius-server-auth-certificate: string # The public certificate data for the radius server authentication certificate as a Base-64 encoded string. Required only if external radius authentication has been configured with EAPTLS authentication.
]: any -> any {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworkGateways/{virtualNetworkGatewayName}/generatevpnprofile"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: virtualNetworkGatewayName, var: virtual_network_gateway_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: authenticationMethod, var: authentication_method}, {name: clientRootCertificates, var: client_root_certificates}, {name: processorArchitecture, var: processor_architecture}, {name: radiusServerAuthCertificate, var: radius_server_auth_certificate}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_network_gateway_name: $virtual_network_gateway_name, api_version: $api_version, authentication_method: $authentication_method, client_root_certificates: $client_root_certificates, processor_architecture: $processor_architecture, radius_server_auth_certificate: $radius_server_auth_certificate
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This operation retrieves a list of routes the virtual network gateway is advertising to the specified peer.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworkGateways/{virtualNetworkGatewayName}/getAdvertisedRoutes
# Returns: record<value: table<asPath: string, localAddress: string, network: string, nextHop: string, origin: string, sourcePeer: string, weight: int>>
# operationId: VirtualNetworkGateways_GetAdvertisedRoutes
export def "virtual-network-gateways-get-advertised-routes" [
  subscription_id: string
  resource_group_name: string
  virtual_network_gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --peer: string # The IP address of the peer. (required)
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworkGateways/{virtualNetworkGatewayName}/getAdvertisedRoutes"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: virtualNetworkGatewayName, var: virtual_network_gateway_name}]
    query: [{name: peer, var: peer, required: true}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_network_gateway_name: $virtual_network_gateway_name, peer: $peer, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The GetBgpPeerStatus operation retrieves the status of all BGP peers.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworkGateways/{virtualNetworkGatewayName}/getBgpPeerStatus
# Returns: record<value: table<asn: int, connectedDuration: string, localAddress: string, messagesReceived: int, messagesSent: int, neighbor: string, routesReceived: int, state: string>>
# operationId: VirtualNetworkGateways_GetBgpPeerStatus
export def "virtual-network-gateways-get-bgp-peer-status" [
  subscription_id: string
  resource_group_name: string
  virtual_network_gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --peer: string # The IP address of the peer to retrieve the status of.
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworkGateways/{virtualNetworkGatewayName}/getBgpPeerStatus"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: virtualNetworkGatewayName, var: virtual_network_gateway_name}]
    query: [{name: peer, var: peer}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_network_gateway_name: $virtual_network_gateway_name, peer: $peer, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This operation retrieves a list of routes the virtual network gateway has learned, including routes learned from BGP peers.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworkGateways/{virtualNetworkGatewayName}/getLearnedRoutes
# Returns: record<value: table<asPath: string, localAddress: string, network: string, nextHop: string, origin: string, sourcePeer: string, weight: int>>
# operationId: VirtualNetworkGateways_GetLearnedRoutes
export def "virtual-network-gateways-get-learned-routes" [
  subscription_id: string
  resource_group_name: string
  virtual_network_gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworkGateways/{virtualNetworkGatewayName}/getLearnedRoutes"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: virtualNetworkGatewayName, var: virtual_network_gateway_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_network_gateway_name: $virtual_network_gateway_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get VPN client connection health detail per P2S client connection of the virtual network gateway in the specified resource group.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworkGateways/{virtualNetworkGatewayName}/getVpnClientConnectionHealth
# Returns: record<value: table<egressBytesTransferred: int, egressPacketsTransferred: int, ingressBytesTransferred: int, ingressPacketsTransferred: int, maxBandwidth: int, maxPacketsPerSecond: int, privateIpAddress: string, publicIpAddress: string, vpnConnectionDuration: int, vpnConnectionId: string, vpnConnectionTime: string, vpnUserName: string>>
# operationId: VirtualNetworkGateways_GetVpnclientConnectionHealth
export def "virtual-network-gateways-get-vpnclient-connection-health" [
  subscription_id: string
  resource_group_name: string
  virtual_network_gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworkGateways/{virtualNetworkGatewayName}/getVpnClientConnectionHealth"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: virtualNetworkGatewayName, var: virtual_network_gateway_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_network_gateway_name: $virtual_network_gateway_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The Get VpnclientIpsecParameters operation retrieves information about the vpnclient ipsec policy for P2S client of virtual network gateway in the specified resource group through Network resource provider.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworkGateways/{virtualNetworkGatewayName}/getvpnclientipsecparameters
# Returns: record<dhGroup: string, ikeEncryption: string, ikeIntegrity: string, ipsecEncryption: string, ipsecIntegrity: string, pfsGroup: string, saDataSizeKilobytes: int, saLifeTimeSeconds: int>
# operationId: VirtualNetworkGateways_GetVpnclientIpsecParameters
export def "virtual-network-gateways-get-vpnclient-ipsec-parameters" [
  subscription_id: string
  resource_group_name: string
  virtual_network_gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworkGateways/{virtualNetworkGatewayName}/getvpnclientipsecparameters"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: virtualNetworkGatewayName, var: virtual_network_gateway_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_network_gateway_name: $virtual_network_gateway_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets pre-generated VPN profile for P2S client of the virtual network gateway in the specified resource group. The profile needs to be generated first using generateVpnProfile.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworkGateways/{virtualNetworkGatewayName}/getvpnprofilepackageurl
# Returns: string
# operationId: VirtualNetworkGateways_GetVpnProfilePackageUrl
export def "virtual-network-gateways-get-vpn-profile-package-url" [
  subscription_id: string
  resource_group_name: string
  virtual_network_gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworkGateways/{virtualNetworkGatewayName}/getvpnprofilepackageurl"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: virtualNetworkGatewayName, var: virtual_network_gateway_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_network_gateway_name: $virtual_network_gateway_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resets the primary of the virtual network gateway in the specified resource group.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworkGateways/{virtualNetworkGatewayName}/reset
# Returns: record<etag: string, properties: record<activeActive: bool, bgpSettings: record<asn: int, bgpPeeringAddress: string, peerWeight: int>, customRoutes: record<addressPrefixes: list>, enableBgp: bool, gatewayDefaultSite: record<id: string>, gatewayType: string, ipConfigurations: list<record>, provisioningState: string, resourceGuid: string, sku: record<capacity: int, name: string, tier: string>, vpnClientConfiguration: record<aadAudience: string, aadIssuer: string, aadTenant: string, radiusServerAddress: string, radiusServerSecret: string, vpnClientAddressPool: record, vpnClientIpsecPolicies: list, vpnClientProtocols: list, vpnClientRevokedCertificates: list, vpnClientRootCertificates: list>, vpnGatewayGeneration: string, vpnType: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: VirtualNetworkGateways_Reset
export def "virtual-network-gateways-reset" [
  subscription_id: string
  resource_group_name: string
  virtual_network_gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --gateway-vip: string # Virtual network gateway vip address supplied to the begin reset of the active-active feature enabled gateway.
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworkGateways/{virtualNetworkGatewayName}/reset"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: virtualNetworkGatewayName, var: virtual_network_gateway_name}]
    query: [{name: gatewayVip, var: gateway_vip}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_network_gateway_name: $virtual_network_gateway_name, gateway_vip: $gateway_vip, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resets the VPN client shared key of the virtual network gateway in the specified resource group.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworkGateways/{virtualNetworkGatewayName}/resetvpnclientsharedkey
# operationId: VirtualNetworkGateways_ResetVpnClientSharedKey
export def "virtual-network-gateways-reset-vpn-client-shared-key" [
  subscription_id: string
  resource_group_name: string
  virtual_network_gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworkGateways/{virtualNetworkGatewayName}/resetvpnclientsharedkey"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: virtualNetworkGatewayName, var: virtual_network_gateway_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_network_gateway_name: $virtual_network_gateway_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The Set VpnclientIpsecParameters operation sets the vpnclient ipsec policy for P2S client of virtual network gateway in the specified resource group through Network resource provider.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworkGateways/{virtualNetworkGatewayName}/setvpnclientipsecparameters
# Returns: record<dhGroup: string, ikeEncryption: string, ikeIntegrity: string, ipsecEncryption: string, ipsecIntegrity: string, pfsGroup: string, saDataSizeKilobytes: int, saLifeTimeSeconds: int>
# operationId: VirtualNetworkGateways_SetVpnclientIpsecParameters
export def "virtual-network-gateways-set-vpnclient-ipsec-parameters" [
  subscription_id: string
  resource_group_name: string
  virtual_network_gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required)
  dh_group: string@dh-group-completer # The DH Groups used in IKE Phase 1 for initial SA.
  ike_encryption: string@ike-encryption-completer # The IKE encryption algorithm (IKE phase 2).
  ike_integrity: string@ike-integrity-completer # The IKE integrity algorithm (IKE phase 2).
  ipsec_encryption: string@ipsec-encryption-completer # The IPSec encryption algorithm (IKE phase 1).
  ipsec_integrity: string@ipsec-integrity-completer # The IPSec integrity algorithm (IKE phase 1).
  pfs_group: string@pfs-group-completer # The Pfs Groups used in IKE Phase 2 for new child SA.
  sa_data_size_kilobytes: int # The IPSec Security Association (also called Quick Mode or Phase 2 SA) payload size in KB for P2S client.. (format: int32)
  sa_life_time_seconds: int # The IPSec Security Association (also called Quick Mode or Phase 2 SA) lifetime in seconds for P2S client. (format: int32)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworkGateways/{virtualNetworkGatewayName}/setvpnclientipsecparameters"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: virtualNetworkGatewayName, var: virtual_network_gateway_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: dhGroup, var: dh_group}, {name: ikeEncryption, var: ike_encryption}, {name: ikeIntegrity, var: ike_integrity}, {name: ipsecEncryption, var: ipsec_encryption}, {name: ipsecIntegrity, var: ipsec_integrity}, {name: pfsGroup, var: pfs_group}, {name: saDataSizeKilobytes, var: sa_data_size_kilobytes}, {name: saLifeTimeSeconds, var: sa_life_time_seconds}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_network_gateway_name: $virtual_network_gateway_name, api_version: $api_version, dh_group: $dh_group, ike_encryption: $ike_encryption, ike_integrity: $ike_integrity, ipsec_encryption: $ipsec_encryption, ipsec_integrity: $ipsec_integrity, pfs_group: $pfs_group, sa_data_size_kilobytes: $sa_data_size_kilobytes, sa_life_time_seconds: $sa_life_time_seconds
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts packet capture on virtual network gateway in the specified resource group.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworkGateways/{virtualNetworkGatewayName}/startPacketCapture
# Returns: string
# operationId: VirtualNetworkGateways_StartPacketCapture
export def "virtual-network-gateways-start-packet-capture" [
  subscription_id: string
  resource_group_name: string
  virtual_network_gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required)
  --filter-data: string # Start Packet capture parameters.
]: any -> any {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworkGateways/{virtualNetworkGatewayName}/startPacketCapture"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: virtualNetworkGatewayName, var: virtual_network_gateway_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: filterData, var: filter_data}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_network_gateway_name: $virtual_network_gateway_name, api_version: $api_version, filter_data: $filter_data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stops packet capture on virtual network gateway in the specified resource group.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworkGateways/{virtualNetworkGatewayName}/stopPacketCapture
# Returns: string
# operationId: VirtualNetworkGateways_StopPacketCapture
export def "virtual-network-gateways-stop-packet-capture" [
  subscription_id: string
  resource_group_name: string
  virtual_network_gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required)
  --sas-url: string # SAS url for packet capture on virtual network gateway.
]: any -> any {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworkGateways/{virtualNetworkGatewayName}/stopPacketCapture"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: virtualNetworkGatewayName, var: virtual_network_gateway_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: sasUrl, var: sas_url}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_network_gateway_name: $virtual_network_gateway_name, api_version: $api_version, sas_url: $sas_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a xml format representation for supported vpn devices.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworkGateways/{virtualNetworkGatewayName}/supportedvpndevices
# Returns: string
# operationId: VirtualNetworkGateways_SupportedVpnDevices
export def "virtual-network-gateways-supported-vpn-devices" [
  subscription_id: string
  resource_group_name: string
  virtual_network_gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworkGateways/{virtualNetworkGatewayName}/supportedvpndevices"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: virtualNetworkGatewayName, var: virtual_network_gateway_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_network_gateway_name: $virtual_network_gateway_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
