# Auto-generated client for GraphRbacManagementClient v1.6
# Source: https://api.apis.guru/v2/specs/windows.net/graphrbac/1.6/openapi.json
# Auth: --token flag or $env.GRAPHRBACMANAGEMENTCLIENT_TOKEN

const CLIENT = {
  base_url: "https://graph.windows.net"
  token_env_var: "GRAPHRBACMANAGEMENTCLIENT_TOKEN"
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

def base-url-completer [] { ["https://graph.windows.net"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "text/json"] }
def group-membership-claims-completer [] { ["All" "None" "SecurityGroup"] }
def mail-enabled-completer [] { ["false"] }
def security-enabled-completer [] { ["true"] }
def consent-type-completer [] { ["AllPrincipals" "Principal"] }
def user-type-completer [] { ["Guest" "Member"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    applications-list: "record<\"odata.nextLink\": string, value: table<allowGuestsSignIn: bool, allowPassthroughUsers: bool, appId: string, appLogoUrl: string, appPermissions: list, appRoles: list, availableToOtherTenants: bool, displayName: string, errorUrl: string, groupMembershipClaims: string, homepage: string, identifierUris: list, informationalUrls: record, isDeviceOnlyAuthSupported: bool, keyCredentials: list, knownClientApplications: list, logoutUrl: string, oauth2AllowImplicitFlow: bool, oauth2AllowUrlPathMatching: bool, oauth2Permissions: list, oauth2RequirePostResponse: bool, optionalClaims: record, orgRestrictions: list, passwordCredentials: list, preAuthorizedApplications: list, publicClient: bool, publisherDomain: string, replyUrls: list, requiredResourceAccess: list, samlMetadataUrl: string, signInAudience: string, wwwHomepage: string, deletionTimestamp: string, objectId: string, objectType: string>>"
    applications-create: "record<allowGuestsSignIn: bool, allowPassthroughUsers: bool, appId: string, appLogoUrl: string, appPermissions: list<string>, appRoles: table<allowedMemberTypes: list, description: string, displayName: string, id: string, isEnabled: bool, value: string>, availableToOtherTenants: bool, displayName: string, errorUrl: string, groupMembershipClaims: string, homepage: string, identifierUris: list<string>, informationalUrls: record<marketing: string, privacy: string, support: string, termsOfService: string>, isDeviceOnlyAuthSupported: bool, keyCredentials: table<customKeyIdentifier: string, endDate: string, keyId: string, startDate: string, type: string, usage: string, value: string>, knownClientApplications: list<string>, logoutUrl: string, oauth2AllowImplicitFlow: bool, oauth2AllowUrlPathMatching: bool, oauth2Permissions: table<adminConsentDescription: string, adminConsentDisplayName: string, id: string, isEnabled: bool, type: string, userConsentDescription: string, userConsentDisplayName: string, value: string>, oauth2RequirePostResponse: bool, optionalClaims: record<accessToken: list<record>, idToken: list<record>, samlToken: list<record>>, orgRestrictions: list<string>, passwordCredentials: table<customKeyIdentifier: string, endDate: string, keyId: string, startDate: string, value: string>, preAuthorizedApplications: table<appId: string, extensions: list, permissions: list>, publicClient: bool, publisherDomain: string, replyUrls: list<string>, requiredResourceAccess: table<resourceAccess: list, resourceAppId: string>, samlMetadataUrl: string, signInAudience: string, wwwHomepage: string, deletionTimestamp: string, objectId: string, objectType: string>"
    applications-get: "record<allowGuestsSignIn: bool, allowPassthroughUsers: bool, appId: string, appLogoUrl: string, appPermissions: list<string>, appRoles: table<allowedMemberTypes: list, description: string, displayName: string, id: string, isEnabled: bool, value: string>, availableToOtherTenants: bool, displayName: string, errorUrl: string, groupMembershipClaims: string, homepage: string, identifierUris: list<string>, informationalUrls: record<marketing: string, privacy: string, support: string, termsOfService: string>, isDeviceOnlyAuthSupported: bool, keyCredentials: table<customKeyIdentifier: string, endDate: string, keyId: string, startDate: string, type: string, usage: string, value: string>, knownClientApplications: list<string>, logoutUrl: string, oauth2AllowImplicitFlow: bool, oauth2AllowUrlPathMatching: bool, oauth2Permissions: table<adminConsentDescription: string, adminConsentDisplayName: string, id: string, isEnabled: bool, type: string, userConsentDescription: string, userConsentDisplayName: string, value: string>, oauth2RequirePostResponse: bool, optionalClaims: record<accessToken: list<record>, idToken: list<record>, samlToken: list<record>>, orgRestrictions: list<string>, passwordCredentials: table<customKeyIdentifier: string, endDate: string, keyId: string, startDate: string, value: string>, preAuthorizedApplications: table<appId: string, extensions: list, permissions: list>, publicClient: bool, publisherDomain: string, replyUrls: list<string>, requiredResourceAccess: table<resourceAccess: list, resourceAppId: string>, samlMetadataUrl: string, signInAudience: string, wwwHomepage: string, deletionTimestamp: string, objectId: string, objectType: string>"
    applications-list-key-credentials: "record<value: table<customKeyIdentifier: string, endDate: string, keyId: string, startDate: string, type: string, usage: string, value: string>>"
    applications-list-owners: "record<\"odata.nextLink\": string, value: table<deletionTimestamp: string, objectId: string, objectType: string>>"
    applications-list-password-credentials: "record<value: table<customKeyIdentifier: string, endDate: string, keyId: string, startDate: string, value: string>>"
    deleted-applications-list: "record<\"odata.nextLink\": string, value: table<allowGuestsSignIn: bool, allowPassthroughUsers: bool, appId: string, appLogoUrl: string, appPermissions: list, appRoles: list, availableToOtherTenants: bool, displayName: string, errorUrl: string, groupMembershipClaims: string, homepage: string, identifierUris: list, informationalUrls: record, isDeviceOnlyAuthSupported: bool, keyCredentials: list, knownClientApplications: list, logoutUrl: string, oauth2AllowImplicitFlow: bool, oauth2AllowUrlPathMatching: bool, oauth2Permissions: list, oauth2RequirePostResponse: bool, optionalClaims: record, orgRestrictions: list, passwordCredentials: list, preAuthorizedApplications: list, publicClient: bool, publisherDomain: string, replyUrls: list, requiredResourceAccess: list, samlMetadataUrl: string, signInAudience: string, wwwHomepage: string, deletionTimestamp: string, objectId: string, objectType: string>>"
    deleted-applications-restore: "record<allowGuestsSignIn: bool, allowPassthroughUsers: bool, appId: string, appLogoUrl: string, appPermissions: list<string>, appRoles: table<allowedMemberTypes: list, description: string, displayName: string, id: string, isEnabled: bool, value: string>, availableToOtherTenants: bool, displayName: string, errorUrl: string, groupMembershipClaims: string, homepage: string, identifierUris: list<string>, informationalUrls: record<marketing: string, privacy: string, support: string, termsOfService: string>, isDeviceOnlyAuthSupported: bool, keyCredentials: table<customKeyIdentifier: string, endDate: string, keyId: string, startDate: string, type: string, usage: string, value: string>, knownClientApplications: list<string>, logoutUrl: string, oauth2AllowImplicitFlow: bool, oauth2AllowUrlPathMatching: bool, oauth2Permissions: table<adminConsentDescription: string, adminConsentDisplayName: string, id: string, isEnabled: bool, type: string, userConsentDescription: string, userConsentDisplayName: string, value: string>, oauth2RequirePostResponse: bool, optionalClaims: record<accessToken: list<record>, idToken: list<record>, samlToken: list<record>>, orgRestrictions: list<string>, passwordCredentials: table<customKeyIdentifier: string, endDate: string, keyId: string, startDate: string, value: string>, preAuthorizedApplications: table<appId: string, extensions: list, permissions: list>, publicClient: bool, publisherDomain: string, replyUrls: list<string>, requiredResourceAccess: table<resourceAccess: list, resourceAppId: string>, samlMetadataUrl: string, signInAudience: string, wwwHomepage: string, deletionTimestamp: string, objectId: string, objectType: string>"
    domains-list: "record<value: table<authenticationType: string, isDefault: bool, isVerified: bool, name: string>>"
    domains-get: "record<authenticationType: string, isDefault: bool, isVerified: bool, name: string>"
    objects-get-objects-by-object-ids: "record<\"odata.nextLink\": string, value: table<deletionTimestamp: string, objectId: string, objectType: string>>"
    groups-list: "record<\"odata.nextLink\": string, value: table<displayName: string, mail: string, mailEnabled: bool, mailNickname: string, securityEnabled: bool, deletionTimestamp: string, objectId: string, objectType: string>>"
    groups-create: "record<displayName: string, mail: string, mailEnabled: bool, mailNickname: string, securityEnabled: bool, deletionTimestamp: string, objectId: string, objectType: string>"
    groups-get: "record<displayName: string, mail: string, mailEnabled: bool, mailNickname: string, securityEnabled: bool, deletionTimestamp: string, objectId: string, objectType: string>"
    groups-get-member-groups: "record<value: list<string>>"
    groups-get-group-members: "record<\"odata.nextLink\": string, value: table<deletionTimestamp: string, objectId: string, objectType: string>>"
    groups-list-owners: "record<\"odata.nextLink\": string, value: table<deletionTimestamp: string, objectId: string, objectType: string>>"
    groups-is-member-of: "record<value: bool>"
    signed-in-user-get: "record<accountEnabled: bool, displayName: string, givenName: string, immutableId: string, mail: string, mailNickname: string, signInNames: table<type: string, value: string>, surname: string, usageLocation: string, userPrincipalName: string, userType: string, deletionTimestamp: string, objectId: string, objectType: string>"
    signed-in-user-list-owned-objects: "record<\"odata.nextLink\": string, value: table<deletionTimestamp: string, objectId: string, objectType: string>>"
    o-auth2-permission-grant-list: "record<\"odata.nextLink\": string, value: table<clientId: string, consentType: string, expiryTime: string, objectId: string, \"odata.type\": string, principalId: string, resourceId: string, scope: string, startTime: string>>"
    o-auth2-permission-grant-create: "record<clientId: string, consentType: string, expiryTime: string, objectId: string, \"odata.type\": string, principalId: string, resourceId: string, scope: string, startTime: string>"
    service-principals-list: "record<\"odata.nextLink\": string, value: table<accountEnabled: bool, alternativeNames: list, appDisplayName: string, appId: string, appOwnerTenantId: string, appRoleAssignmentRequired: bool, appRoles: list, displayName: string, errorUrl: string, homepage: string, keyCredentials: list, logoutUrl: string, oauth2Permissions: list, passwordCredentials: list, preferredTokenSigningKeyThumbprint: string, publisherName: string, replyUrls: list, samlMetadataUrl: string, servicePrincipalNames: list, servicePrincipalType: string, tags: list, deletionTimestamp: string, objectId: string, objectType: string>>"
    service-principals-create: "record<accountEnabled: bool, alternativeNames: list<string>, appDisplayName: string, appId: string, appOwnerTenantId: string, appRoleAssignmentRequired: bool, appRoles: table<allowedMemberTypes: list, description: string, displayName: string, id: string, isEnabled: bool, value: string>, displayName: string, errorUrl: string, homepage: string, keyCredentials: table<customKeyIdentifier: string, endDate: string, keyId: string, startDate: string, type: string, usage: string, value: string>, logoutUrl: string, oauth2Permissions: table<adminConsentDescription: string, adminConsentDisplayName: string, id: string, isEnabled: bool, type: string, userConsentDescription: string, userConsentDisplayName: string, value: string>, passwordCredentials: table<customKeyIdentifier: string, endDate: string, keyId: string, startDate: string, value: string>, preferredTokenSigningKeyThumbprint: string, publisherName: string, replyUrls: list<string>, samlMetadataUrl: string, servicePrincipalNames: list<string>, servicePrincipalType: string, tags: list<string>, deletionTimestamp: string, objectId: string, objectType: string>"
    service-principals-get: "record<accountEnabled: bool, alternativeNames: list<string>, appDisplayName: string, appId: string, appOwnerTenantId: string, appRoleAssignmentRequired: bool, appRoles: table<allowedMemberTypes: list, description: string, displayName: string, id: string, isEnabled: bool, value: string>, displayName: string, errorUrl: string, homepage: string, keyCredentials: table<customKeyIdentifier: string, endDate: string, keyId: string, startDate: string, type: string, usage: string, value: string>, logoutUrl: string, oauth2Permissions: table<adminConsentDescription: string, adminConsentDisplayName: string, id: string, isEnabled: bool, type: string, userConsentDescription: string, userConsentDisplayName: string, value: string>, passwordCredentials: table<customKeyIdentifier: string, endDate: string, keyId: string, startDate: string, value: string>, preferredTokenSigningKeyThumbprint: string, publisherName: string, replyUrls: list<string>, samlMetadataUrl: string, servicePrincipalNames: list<string>, servicePrincipalType: string, tags: list<string>, deletionTimestamp: string, objectId: string, objectType: string>"
    service-principals-list-app-role-assigned-to: "record<\"odata.nextLink\": string, value: table<id: string, principalDisplayName: string, principalId: string, principalType: string, resourceDisplayName: string, resourceId: string, deletionTimestamp: string, objectId: string, objectType: string>>"
    service-principals-list-app-role-assignments: "record<\"odata.nextLink\": string, value: table<id: string, principalDisplayName: string, principalId: string, principalType: string, resourceDisplayName: string, resourceId: string, deletionTimestamp: string, objectId: string, objectType: string>>"
    service-principals-list-key-credentials: "record<value: table<customKeyIdentifier: string, endDate: string, keyId: string, startDate: string, type: string, usage: string, value: string>>"
    service-principals-list-owners: "record<\"odata.nextLink\": string, value: table<deletionTimestamp: string, objectId: string, objectType: string>>"
    service-principals-list-password-credentials: "record<value: table<customKeyIdentifier: string, endDate: string, keyId: string, startDate: string, value: string>>"
    applications-get-service-principals-id-by-app-id: "record<\"odata.metadata\": string, value: string>"
    users-list: "record<\"odata.nextLink\": string, value: table<accountEnabled: bool, displayName: string, givenName: string, immutableId: string, mail: string, mailNickname: string, signInNames: list, surname: string, usageLocation: string, userPrincipalName: string, userType: string, deletionTimestamp: string, objectId: string, objectType: string>>"
    users-create: "record<accountEnabled: bool, displayName: string, givenName: string, immutableId: string, mail: string, mailNickname: string, signInNames: table<type: string, value: string>, surname: string, usageLocation: string, userPrincipalName: string, userType: string, deletionTimestamp: string, objectId: string, objectType: string>"
    users-get-member-groups: "record<value: list<string>>"
    users-get: "record<accountEnabled: bool, displayName: string, givenName: string, immutableId: string, mail: string, mailNickname: string, signInNames: table<type: string, value: string>, surname: string, usageLocation: string, userPrincipalName: string, userType: string, deletionTimestamp: string, objectId: string, objectType: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["applications-list" "applications-create" "applications-delete" "applications-get" "applications-patch" "applications-add-owner" "applications-remove-owner" "applications-list-key-credentials" "applications-update-key-credentials" "applications-list-owners" "applications-list-password-credentials" "applications-update-password-credentials" "deleted-applications-list" "deleted-applications-hard-delete" "deleted-applications-restore" "domains-list" "domains-get" "objects-get-objects-by-object-ids" "groups-list" "groups-create" "groups-add-member" "groups-remove-member" "groups-delete" "groups-get" "groups-add-owner" "groups-remove-owner" "groups-get-member-groups" "groups-get-group-members" "groups-list-owners" "groups-is-member-of" "signed-in-user-get" "signed-in-user-list-owned-objects" "o-auth2-permission-grant-list" "o-auth2-permission-grant-create" "o-auth2-permission-grant-delete" "service-principals-list" "service-principals-create" "service-principals-delete" "service-principals-get" "service-principals-update" "service-principals-add-owner" "service-principals-remove-owner" "service-principals-list-app-role-assigned-to" "service-principals-list-app-role-assignments" "service-principals-list-key-credentials" "service-principals-update-key-credentials" "service-principals-list-owners" "service-principals-list-password-credentials" "service-principals-update-password-credentials" "applications-get-service-principals-id-by-app-id" "users-list" "users-create" "users-get-member-groups" "users-delete" "users-get" "users-update" "commands"] | sort) } | get name | first)
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

# Lists applications by filter parameters.
#
# GET /{tenantID}/applications
# Returns: record<"odata.nextLink": string, value: table<allowGuestsSignIn: bool, allowPassthroughUsers: bool, appId: string, appLogoUrl: string, appPermissions: list, appRoles: list, availableToOtherTenants: bool, displayName: string, errorUrl: string, groupMembershipClaims: string, homepage: string, identifierUris: list, informationalUrls: record, isDeviceOnlyAuthSupported: bool, keyCredentials: list, knownClientApplications: list, logoutUrl: string, oauth2AllowImplicitFlow: bool, oauth2AllowUrlPathMatching: bool, oauth2Permissions: list, oauth2RequirePostResponse: bool, optionalClaims: record, orgRestrictions: list, passwordCredentials: list, preAuthorizedApplications: list, publicClient: bool, publisherDomain: string, replyUrls: list, requiredResourceAccess: list, samlMetadataUrl: string, signInAudience: string, wwwHomepage: string, deletionTimestamp: string, objectId: string, objectType: string>>
# operationId: Applications_List
export def "applications-list" [
  tenant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --filter: string # The filters to apply to the operation.
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{tenantID}/applications"
    path_params: [{name: tenantID, var: tenant_id}]
    query: [{name: "$filter", var: filter}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    tenant_id: $tenant_id, filter: $filter, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a new application.
#
# POST /{tenantID}/applications
# Returns: record<allowGuestsSignIn: bool, allowPassthroughUsers: bool, appId: string, appLogoUrl: string, appPermissions: list<string>, appRoles: table<allowedMemberTypes: list, description: string, displayName: string, id: string, isEnabled: bool, value: string>, availableToOtherTenants: bool, displayName: string, errorUrl: string, groupMembershipClaims: string, homepage: string, identifierUris: list<string>, informationalUrls: record<marketing: string, privacy: string, support: string, termsOfService: string>, isDeviceOnlyAuthSupported: bool, keyCredentials: table<customKeyIdentifier: string, endDate: string, keyId: string, startDate: string, type: string, usage: string, value: string>, knownClientApplications: list<string>, logoutUrl: string, oauth2AllowImplicitFlow: bool, oauth2AllowUrlPathMatching: bool, oauth2Permissions: table<adminConsentDescription: string, adminConsentDisplayName: string, id: string, isEnabled: bool, type: string, userConsentDescription: string, userConsentDisplayName: string, value: string>, oauth2RequirePostResponse: bool, optionalClaims: record<accessToken: list<record>, idToken: list<record>, samlToken: list<record>>, orgRestrictions: list<string>, passwordCredentials: table<customKeyIdentifier: string, endDate: string, keyId: string, startDate: string, value: string>, preAuthorizedApplications: table<appId: string, extensions: list, permissions: list>, publicClient: bool, publisherDomain: string, replyUrls: list<string>, requiredResourceAccess: table<resourceAccess: list, resourceAppId: string>, samlMetadataUrl: string, signInAudience: string, wwwHomepage: string, deletionTimestamp: string, objectId: string, objectType: string>
# operationId: Applications_Create
export def "applications-create" [
  tenant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version. (required)
  display_name: string # The display name of the application.
  --identifier-uris: list<string> # A collection of URIs for the application.
  --allow-guests-sign-in: oneof<nothing, bool> # A property on the application to indicate if the application accepts other IDPs or not or partially accepts.
  --allow-passthrough-users: oneof<nothing, bool> # Indicates that the application supports pass through users who have no presence in the resource tenant.
  --app-logo-url: string # The url for the application logo image stored in a CDN.
  --app-permissions: list<string> # The application permissions.
  --app-roles: list # The collection of application roles that an application may declare. These roles can be assigned to users, groups or service principals. — item shape: {allowedMemberTypes?: list<string>, description?: string, displayName?: string, id?: string, isEnabled?: bool, value?: string}
  --available-to-other-tenants: oneof<nothing, bool> # Whether the application is available to other tenants.
  --error-url: string # A URL provided by the author of the application to report errors when using the application.
  --group-membership-claims: string@group-membership-claims-completer # Configures the groups claim issued in a user or OAuth 2.0 access token that the app expects.
  --homepage: string # The home page of the application.
  --informational-urls: record # Represents a group of URIs that provide terms of service, marketing, support and privacy policy information about an application. The default value for each string is null. — shape: {marketing?: string, privacy?: string, support?: string, termsOfService?: string}
  --is-device-only-auth-supported: oneof<nothing, bool> # Specifies whether this application supports device authentication without a user. The default is false.
  --key-credentials: list # A collection of KeyCredential objects. — item shape: {customKeyIdentifier?: string, endDate?: string, keyId?: string, startDate?: string, type?: string, usage?: string, value?: string}
  --known-client-applications: list<string> # Client applications that are tied to this resource application. Consent to any of the known client applications will result in implicit consent to the resource application through a combined consent dialog (showing the OAuth permission scopes required by the client and the resource).
  --logout-url: string # the url of the logout page
  --oauth2-allow-implicit-flow: oneof<nothing, bool> # Whether to allow implicit grant flow for OAuth2
  --oauth2-allow-url-path-matching: oneof<nothing, bool> # Specifies whether during a token Request Azure AD will allow path matching of the redirect URI against the applications collection of replyURLs. The default is false.
  --oauth2-permissions: list # The collection of OAuth 2.0 permission scopes that the web API (resource) application exposes to client applications. These permission scopes may be granted to client applications during consent. — item shape: {adminConsentDescription?: string, adminConsentDisplayName?: string, id?: string, isEnabled?: bool, type?: string, userConsentDescription?: string, userConsentDisplayName?: string, value?: string}
  --oauth2-require-post-response: oneof<nothing, bool> # Specifies whether, as part of OAuth 2.0 token requests, Azure AD will allow POST requests, as opposed to GET requests. The default is false, which specifies that only GET requests will be allowed.
  --optional-claims: record # Specifying the claims to be included in the token. — shape: {accessToken?: list, idToken?: list, samlToken?: list}
  --org-restrictions: list<string> # A list of tenants allowed to access application.
  --password-credentials: list # A collection of PasswordCredential objects — item shape: {customKeyIdentifier?: string, endDate?: string, keyId?: string, startDate?: string, value?: string}
  --pre-authorized-applications: list # list of pre-authorized applications. — item shape: {appId?: string, extensions?: list, permissions?: list}
  --public-client: oneof<nothing, bool> # Specifies whether this application is a public client (such as an installed application running on a mobile device). Default is false.
  --publisher-domain: string # Reliable domain which can be used to identify an application.
  --reply-urls: list<string> # A collection of reply URLs for the application.
  --required-resource-access: list # Specifies resources that this application requires access to and the set of OAuth permission scopes and application roles that it needs under each of those resources. This pre-configuration of required resource access drives the consent experience. — item shape: {resourceAccess: list, resourceAppId?: string}
  --saml-metadata-url: string # The URL to the SAML metadata for the application.
  --sign-in-audience: string # Audience for signing in to the application (AzureADMyOrganization, AzureADAllOrganizations, AzureADAndMicrosoftAccounts).
  --www-homepage: string # The primary Web page.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{tenantID}/applications"
    path_params: [{name: tenantID, var: tenant_id}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: displayName, var: display_name}, {name: identifierUris, var: identifier_uris}, {name: allowGuestsSignIn, var: allow_guests_sign_in}, {name: allowPassthroughUsers, var: allow_passthrough_users}, {name: appLogoUrl, var: app_logo_url}, {name: appPermissions, var: app_permissions}, {name: appRoles, var: app_roles}, {name: availableToOtherTenants, var: available_to_other_tenants}, {name: errorUrl, var: error_url}, {name: groupMembershipClaims, var: group_membership_claims}, {name: homepage, var: homepage}, {name: informationalUrls, var: informational_urls}, {name: isDeviceOnlyAuthSupported, var: is_device_only_auth_supported}, {name: keyCredentials, var: key_credentials}, {name: knownClientApplications, var: known_client_applications}, {name: logoutUrl, var: logout_url}, {name: oauth2AllowImplicitFlow, var: oauth2_allow_implicit_flow}, {name: oauth2AllowUrlPathMatching, var: oauth2_allow_url_path_matching}, {name: oauth2Permissions, var: oauth2_permissions}, {name: oauth2RequirePostResponse, var: oauth2_require_post_response}, {name: optionalClaims, var: optional_claims}, {name: orgRestrictions, var: org_restrictions}, {name: passwordCredentials, var: password_credentials}, {name: preAuthorizedApplications, var: pre_authorized_applications}, {name: publicClient, var: public_client}, {name: publisherDomain, var: publisher_domain}, {name: replyUrls, var: reply_urls}, {name: requiredResourceAccess, var: required_resource_access}, {name: samlMetadataUrl, var: saml_metadata_url}, {name: signInAudience, var: sign_in_audience}, {name: wwwHomepage, var: www_homepage}]}
    accept: ["application/json", "text/json"]
    ok: [201]
    auth: bearer
  } {
    tenant_id: $tenant_id, api_version: $api_version, display_name: $display_name, identifier_uris: $identifier_uris, allow_guests_sign_in: $allow_guests_sign_in, allow_passthrough_users: $allow_passthrough_users, app_logo_url: $app_logo_url, app_permissions: $app_permissions, app_roles: $app_roles, available_to_other_tenants: $available_to_other_tenants, error_url: $error_url, group_membership_claims: $group_membership_claims, homepage: $homepage, informational_urls: $informational_urls, is_device_only_auth_supported: $is_device_only_auth_supported, key_credentials: $key_credentials, known_client_applications: $known_client_applications, logout_url: $logout_url, oauth2_allow_implicit_flow: $oauth2_allow_implicit_flow, oauth2_allow_url_path_matching: $oauth2_allow_url_path_matching, oauth2_permissions: $oauth2_permissions, oauth2_require_post_response: $oauth2_require_post_response, optional_claims: $optional_claims, org_restrictions: $org_restrictions, password_credentials: $password_credentials, pre_authorized_applications: $pre_authorized_applications, public_client: $public_client, publisher_domain: $publisher_domain, reply_urls: $reply_urls, required_resource_access: $required_resource_access, saml_metadata_url: $saml_metadata_url, sign_in_audience: $sign_in_audience, www_homepage: $www_homepage
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete an application.
#
# DELETE /{tenantID}/applications/{applicationObjectId}
# operationId: Applications_Delete
export def "applications-delete" [
  tenant_id: string
  application_object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/{tenantID}/applications/{applicationObjectId}"
    path_params: [{name: tenantID, var: tenant_id}, {name: applicationObjectId, var: application_object_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [204]
    auth: bearer
  } {
    tenant_id: $tenant_id, application_object_id: $application_object_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get an application by object ID.
#
# GET /{tenantID}/applications/{applicationObjectId}
# Returns: record<allowGuestsSignIn: bool, allowPassthroughUsers: bool, appId: string, appLogoUrl: string, appPermissions: list<string>, appRoles: table<allowedMemberTypes: list, description: string, displayName: string, id: string, isEnabled: bool, value: string>, availableToOtherTenants: bool, displayName: string, errorUrl: string, groupMembershipClaims: string, homepage: string, identifierUris: list<string>, informationalUrls: record<marketing: string, privacy: string, support: string, termsOfService: string>, isDeviceOnlyAuthSupported: bool, keyCredentials: table<customKeyIdentifier: string, endDate: string, keyId: string, startDate: string, type: string, usage: string, value: string>, knownClientApplications: list<string>, logoutUrl: string, oauth2AllowImplicitFlow: bool, oauth2AllowUrlPathMatching: bool, oauth2Permissions: table<adminConsentDescription: string, adminConsentDisplayName: string, id: string, isEnabled: bool, type: string, userConsentDescription: string, userConsentDisplayName: string, value: string>, oauth2RequirePostResponse: bool, optionalClaims: record<accessToken: list<record>, idToken: list<record>, samlToken: list<record>>, orgRestrictions: list<string>, passwordCredentials: table<customKeyIdentifier: string, endDate: string, keyId: string, startDate: string, value: string>, preAuthorizedApplications: table<appId: string, extensions: list, permissions: list>, publicClient: bool, publisherDomain: string, replyUrls: list<string>, requiredResourceAccess: table<resourceAccess: list, resourceAppId: string>, samlMetadataUrl: string, signInAudience: string, wwwHomepage: string, deletionTimestamp: string, objectId: string, objectType: string>
# operationId: Applications_Get
export def "applications-get" [
  tenant_id: string
  application_object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{tenantID}/applications/{applicationObjectId}"
    path_params: [{name: tenantID, var: tenant_id}, {name: applicationObjectId, var: application_object_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    tenant_id: $tenant_id, application_object_id: $application_object_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update an existing application.
#
# PATCH /{tenantID}/applications/{applicationObjectId}
# operationId: Applications_Patch
export def "applications-patch" [
  tenant_id: string
  application_object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version. (required)
  --display-name: string # The display name of the application.
  --identifier-uris: list<string> # A collection of URIs for the application.
  --allow-guests-sign-in: oneof<nothing, bool> # A property on the application to indicate if the application accepts other IDPs or not or partially accepts.
  --allow-passthrough-users: oneof<nothing, bool> # Indicates that the application supports pass through users who have no presence in the resource tenant.
  --app-logo-url: string # The url for the application logo image stored in a CDN.
  --app-permissions: list<string> # The application permissions.
  --app-roles: list # The collection of application roles that an application may declare. These roles can be assigned to users, groups or service principals. — item shape: {allowedMemberTypes?: list<string>, description?: string, displayName?: string, id?: string, isEnabled?: bool, value?: string}
  --available-to-other-tenants: oneof<nothing, bool> # Whether the application is available to other tenants.
  --error-url: string # A URL provided by the author of the application to report errors when using the application.
  --group-membership-claims: string@group-membership-claims-completer # Configures the groups claim issued in a user or OAuth 2.0 access token that the app expects.
  --homepage: string # The home page of the application.
  --informational-urls: record # Represents a group of URIs that provide terms of service, marketing, support and privacy policy information about an application. The default value for each string is null. — shape: {marketing?: string, privacy?: string, support?: string, termsOfService?: string}
  --is-device-only-auth-supported: oneof<nothing, bool> # Specifies whether this application supports device authentication without a user. The default is false.
  --key-credentials: list # A collection of KeyCredential objects. — item shape: {customKeyIdentifier?: string, endDate?: string, keyId?: string, startDate?: string, type?: string, usage?: string, value?: string}
  --known-client-applications: list<string> # Client applications that are tied to this resource application. Consent to any of the known client applications will result in implicit consent to the resource application through a combined consent dialog (showing the OAuth permission scopes required by the client and the resource).
  --logout-url: string # the url of the logout page
  --oauth2-allow-implicit-flow: oneof<nothing, bool> # Whether to allow implicit grant flow for OAuth2
  --oauth2-allow-url-path-matching: oneof<nothing, bool> # Specifies whether during a token Request Azure AD will allow path matching of the redirect URI against the applications collection of replyURLs. The default is false.
  --oauth2-permissions: list # The collection of OAuth 2.0 permission scopes that the web API (resource) application exposes to client applications. These permission scopes may be granted to client applications during consent. — item shape: {adminConsentDescription?: string, adminConsentDisplayName?: string, id?: string, isEnabled?: bool, type?: string, userConsentDescription?: string, userConsentDisplayName?: string, value?: string}
  --oauth2-require-post-response: oneof<nothing, bool> # Specifies whether, as part of OAuth 2.0 token requests, Azure AD will allow POST requests, as opposed to GET requests. The default is false, which specifies that only GET requests will be allowed.
  --optional-claims: record # Specifying the claims to be included in the token. — shape: {accessToken?: list, idToken?: list, samlToken?: list}
  --org-restrictions: list<string> # A list of tenants allowed to access application.
  --password-credentials: list # A collection of PasswordCredential objects — item shape: {customKeyIdentifier?: string, endDate?: string, keyId?: string, startDate?: string, value?: string}
  --pre-authorized-applications: list # list of pre-authorized applications. — item shape: {appId?: string, extensions?: list, permissions?: list}
  --public-client: oneof<nothing, bool> # Specifies whether this application is a public client (such as an installed application running on a mobile device). Default is false.
  --publisher-domain: string # Reliable domain which can be used to identify an application.
  --reply-urls: list<string> # A collection of reply URLs for the application.
  --required-resource-access: list # Specifies resources that this application requires access to and the set of OAuth permission scopes and application roles that it needs under each of those resources. This pre-configuration of required resource access drives the consent experience. — item shape: {resourceAccess: list, resourceAppId?: string}
  --saml-metadata-url: string # The URL to the SAML metadata for the application.
  --sign-in-audience: string # Audience for signing in to the application (AzureADMyOrganization, AzureADAllOrganizations, AzureADAndMicrosoftAccounts).
  --www-homepage: string # The primary Web page.
]: any -> any {
  $in | http-request {
    method: patch
    path: "/{tenantID}/applications/{applicationObjectId}"
    path_params: [{name: tenantID, var: tenant_id}, {name: applicationObjectId, var: application_object_id}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: displayName, var: display_name}, {name: identifierUris, var: identifier_uris}, {name: allowGuestsSignIn, var: allow_guests_sign_in}, {name: allowPassthroughUsers, var: allow_passthrough_users}, {name: appLogoUrl, var: app_logo_url}, {name: appPermissions, var: app_permissions}, {name: appRoles, var: app_roles}, {name: availableToOtherTenants, var: available_to_other_tenants}, {name: errorUrl, var: error_url}, {name: groupMembershipClaims, var: group_membership_claims}, {name: homepage, var: homepage}, {name: informationalUrls, var: informational_urls}, {name: isDeviceOnlyAuthSupported, var: is_device_only_auth_supported}, {name: keyCredentials, var: key_credentials}, {name: knownClientApplications, var: known_client_applications}, {name: logoutUrl, var: logout_url}, {name: oauth2AllowImplicitFlow, var: oauth2_allow_implicit_flow}, {name: oauth2AllowUrlPathMatching, var: oauth2_allow_url_path_matching}, {name: oauth2Permissions, var: oauth2_permissions}, {name: oauth2RequirePostResponse, var: oauth2_require_post_response}, {name: optionalClaims, var: optional_claims}, {name: orgRestrictions, var: org_restrictions}, {name: passwordCredentials, var: password_credentials}, {name: preAuthorizedApplications, var: pre_authorized_applications}, {name: publicClient, var: public_client}, {name: publisherDomain, var: publisher_domain}, {name: replyUrls, var: reply_urls}, {name: requiredResourceAccess, var: required_resource_access}, {name: samlMetadataUrl, var: saml_metadata_url}, {name: signInAudience, var: sign_in_audience}, {name: wwwHomepage, var: www_homepage}]}
    accept: ["application/json", "text/json"]
    ok: [204]
    auth: bearer
  } {
    tenant_id: $tenant_id, application_object_id: $application_object_id, api_version: $api_version, display_name: $display_name, identifier_uris: $identifier_uris, allow_guests_sign_in: $allow_guests_sign_in, allow_passthrough_users: $allow_passthrough_users, app_logo_url: $app_logo_url, app_permissions: $app_permissions, app_roles: $app_roles, available_to_other_tenants: $available_to_other_tenants, error_url: $error_url, group_membership_claims: $group_membership_claims, homepage: $homepage, informational_urls: $informational_urls, is_device_only_auth_supported: $is_device_only_auth_supported, key_credentials: $key_credentials, known_client_applications: $known_client_applications, logout_url: $logout_url, oauth2_allow_implicit_flow: $oauth2_allow_implicit_flow, oauth2_allow_url_path_matching: $oauth2_allow_url_path_matching, oauth2_permissions: $oauth2_permissions, oauth2_require_post_response: $oauth2_require_post_response, optional_claims: $optional_claims, org_restrictions: $org_restrictions, password_credentials: $password_credentials, pre_authorized_applications: $pre_authorized_applications, public_client: $public_client, publisher_domain: $publisher_domain, reply_urls: $reply_urls, required_resource_access: $required_resource_access, saml_metadata_url: $saml_metadata_url, sign_in_audience: $sign_in_audience, www_homepage: $www_homepage
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add an owner to an application.
#
# POST /{tenantID}/applications/{applicationObjectId}/$links/owners
# operationId: Applications_AddOwner
export def "applications-add-owner" [
  tenant_id: string
  application_object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version. (required)
  url: string # A owner object URL, such as "https://graph.windows.net/0b1f9851-1bf0-433f-aec3-cb9272f093dc/directoryObjects/f260bbc4-c254-447b-94cf-293b5ec434dd", where "0b1f9851-1bf0-433f-aec3-cb9272f093dc" is the tenantId and "f260bbc4-c254-447b-94cf-293b5ec434dd" is the objectId of the owner (user, application, servicePrincipal, group) to be added.
]: any -> any {
  $in | http-request {
    method: post
    path: "/{tenantID}/applications/{applicationObjectId}/$links/owners"
    path_params: [{name: tenantID, var: tenant_id}, {name: applicationObjectId, var: application_object_id}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: url, var: url}]}
    accept: ["application/json", "text/json"]
    ok: [204]
    auth: bearer
  } {
    tenant_id: $tenant_id, application_object_id: $application_object_id, api_version: $api_version, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Remove a member from owners.
#
# DELETE /{tenantID}/applications/{applicationObjectId}/$links/owners/{ownerObjectId}
# operationId: Applications_RemoveOwner
export def "applications-remove-owner" [
  tenant_id: string
  application_object_id: string
  owner_object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/{tenantID}/applications/{applicationObjectId}/$links/owners/{ownerObjectId}"
    path_params: [{name: tenantID, var: tenant_id}, {name: applicationObjectId, var: application_object_id}, {name: ownerObjectId, var: owner_object_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [204]
    auth: bearer
  } {
    tenant_id: $tenant_id, application_object_id: $application_object_id, owner_object_id: $owner_object_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get the keyCredentials associated with an application.
#
# GET /{tenantID}/applications/{applicationObjectId}/keyCredentials
# Returns: record<value: table<customKeyIdentifier: string, endDate: string, keyId: string, startDate: string, type: string, usage: string, value: string>>
# operationId: Applications_ListKeyCredentials
export def "applications-list-key-credentials" [
  tenant_id: string
  application_object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{tenantID}/applications/{applicationObjectId}/keyCredentials"
    path_params: [{name: tenantID, var: tenant_id}, {name: applicationObjectId, var: application_object_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    tenant_id: $tenant_id, application_object_id: $application_object_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update the keyCredentials associated with an application.
#
# PATCH /{tenantID}/applications/{applicationObjectId}/keyCredentials
# operationId: Applications_UpdateKeyCredentials
export def "applications-update-key-credentials" [
  tenant_id: string
  application_object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version. (required)
  value: list # A collection of KeyCredentials. — item shape: {customKeyIdentifier?: string, endDate?: string, keyId?: string, startDate?: string, type?: string, usage?: string, value?: string}
]: any -> any {
  $in | http-request {
    method: patch
    path: "/{tenantID}/applications/{applicationObjectId}/keyCredentials"
    path_params: [{name: tenantID, var: tenant_id}, {name: applicationObjectId, var: application_object_id}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json", "text/json"]
    ok: [204]
    auth: bearer
  } {
    tenant_id: $tenant_id, application_object_id: $application_object_id, api_version: $api_version, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Directory objects that are owners of the application.
#
# GET /{tenantID}/applications/{applicationObjectId}/owners
# Returns: record<"odata.nextLink": string, value: table<deletionTimestamp: string, objectId: string, objectType: string>>
# operationId: Applications_ListOwners
export def "applications-list-owners" [
  tenant_id: string
  application_object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{tenantID}/applications/{applicationObjectId}/owners"
    path_params: [{name: tenantID, var: tenant_id}, {name: applicationObjectId, var: application_object_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    tenant_id: $tenant_id, application_object_id: $application_object_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get the passwordCredentials associated with an application.
#
# GET /{tenantID}/applications/{applicationObjectId}/passwordCredentials
# Returns: record<value: table<customKeyIdentifier: string, endDate: string, keyId: string, startDate: string, value: string>>
# operationId: Applications_ListPasswordCredentials
export def "applications-list-password-credentials" [
  tenant_id: string
  application_object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{tenantID}/applications/{applicationObjectId}/passwordCredentials"
    path_params: [{name: tenantID, var: tenant_id}, {name: applicationObjectId, var: application_object_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    tenant_id: $tenant_id, application_object_id: $application_object_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update passwordCredentials associated with an application.
#
# PATCH /{tenantID}/applications/{applicationObjectId}/passwordCredentials
# operationId: Applications_UpdatePasswordCredentials
export def "applications-update-password-credentials" [
  tenant_id: string
  application_object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version. (required)
  value: list # A collection of PasswordCredentials. — item shape: {customKeyIdentifier?: string, endDate?: string, keyId?: string, startDate?: string, value?: string}
]: any -> any {
  $in | http-request {
    method: patch
    path: "/{tenantID}/applications/{applicationObjectId}/passwordCredentials"
    path_params: [{name: tenantID, var: tenant_id}, {name: applicationObjectId, var: application_object_id}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json", "text/json"]
    ok: [204]
    auth: bearer
  } {
    tenant_id: $tenant_id, application_object_id: $application_object_id, api_version: $api_version, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets a list of deleted applications in the directory.
#
# GET /{tenantID}/deletedApplications
# Returns: record<"odata.nextLink": string, value: table<allowGuestsSignIn: bool, allowPassthroughUsers: bool, appId: string, appLogoUrl: string, appPermissions: list, appRoles: list, availableToOtherTenants: bool, displayName: string, errorUrl: string, groupMembershipClaims: string, homepage: string, identifierUris: list, informationalUrls: record, isDeviceOnlyAuthSupported: bool, keyCredentials: list, knownClientApplications: list, logoutUrl: string, oauth2AllowImplicitFlow: bool, oauth2AllowUrlPathMatching: bool, oauth2Permissions: list, oauth2RequirePostResponse: bool, optionalClaims: record, orgRestrictions: list, passwordCredentials: list, preAuthorizedApplications: list, publicClient: bool, publisherDomain: string, replyUrls: list, requiredResourceAccess: list, samlMetadataUrl: string, signInAudience: string, wwwHomepage: string, deletionTimestamp: string, objectId: string, objectType: string>>
# operationId: DeletedApplications_List
export def "deleted-applications-list" [
  tenant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --filter: string # The filter to apply to the operation.
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{tenantID}/deletedApplications"
    path_params: [{name: tenantID, var: tenant_id}]
    query: [{name: "$filter", var: filter}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    tenant_id: $tenant_id, filter: $filter, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Hard-delete an application.
#
# DELETE /{tenantID}/deletedApplications/{applicationObjectId}
# operationId: DeletedApplications_HardDelete
export def "deleted-applications-hard-delete" [
  tenant_id: string
  application_object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/{tenantID}/deletedApplications/{applicationObjectId}"
    path_params: [{name: tenantID, var: tenant_id}, {name: applicationObjectId, var: application_object_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [204]
    auth: bearer
  } {
    tenant_id: $tenant_id, application_object_id: $application_object_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Restores the deleted application in the directory.
#
# POST /{tenantID}/deletedApplications/{objectId}/restore
# Returns: record<allowGuestsSignIn: bool, allowPassthroughUsers: bool, appId: string, appLogoUrl: string, appPermissions: list<string>, appRoles: table<allowedMemberTypes: list, description: string, displayName: string, id: string, isEnabled: bool, value: string>, availableToOtherTenants: bool, displayName: string, errorUrl: string, groupMembershipClaims: string, homepage: string, identifierUris: list<string>, informationalUrls: record<marketing: string, privacy: string, support: string, termsOfService: string>, isDeviceOnlyAuthSupported: bool, keyCredentials: table<customKeyIdentifier: string, endDate: string, keyId: string, startDate: string, type: string, usage: string, value: string>, knownClientApplications: list<string>, logoutUrl: string, oauth2AllowImplicitFlow: bool, oauth2AllowUrlPathMatching: bool, oauth2Permissions: table<adminConsentDescription: string, adminConsentDisplayName: string, id: string, isEnabled: bool, type: string, userConsentDescription: string, userConsentDisplayName: string, value: string>, oauth2RequirePostResponse: bool, optionalClaims: record<accessToken: list<record>, idToken: list<record>, samlToken: list<record>>, orgRestrictions: list<string>, passwordCredentials: table<customKeyIdentifier: string, endDate: string, keyId: string, startDate: string, value: string>, preAuthorizedApplications: table<appId: string, extensions: list, permissions: list>, publicClient: bool, publisherDomain: string, replyUrls: list<string>, requiredResourceAccess: table<resourceAccess: list, resourceAppId: string>, samlMetadataUrl: string, signInAudience: string, wwwHomepage: string, deletionTimestamp: string, objectId: string, objectType: string>
# operationId: DeletedApplications_Restore
export def "deleted-applications-restore" [
  tenant_id: string
  object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/{tenantID}/deletedApplications/{objectId}/restore"
    path_params: [{name: tenantID, var: tenant_id}, {name: objectId, var: object_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    tenant_id: $tenant_id, object_id: $object_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets a list of domains for the current tenant.
#
# GET /{tenantID}/domains
# Returns: record<value: table<authenticationType: string, isDefault: bool, isVerified: bool, name: string>>
# operationId: Domains_List
export def "domains-list" [
  tenant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --filter: string # The filter to apply to the operation.
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{tenantID}/domains"
    path_params: [{name: tenantID, var: tenant_id}]
    query: [{name: "$filter", var: filter}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    tenant_id: $tenant_id, filter: $filter, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets a specific domain in the current tenant.
#
# GET /{tenantID}/domains/{domainName}
# Returns: record<authenticationType: string, isDefault: bool, isVerified: bool, name: string>
# operationId: Domains_Get
export def "domains-get" [
  tenant_id: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{tenantID}/domains/{domainName}"
    path_params: [{name: tenantID, var: tenant_id}, {name: domainName, var: domain_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    tenant_id: $tenant_id, domain_name: $domain_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the directory objects specified in a list of object IDs. You can also specify which resource collections (users, groups, etc.) should be searched by specifying the optional types parameter.
#
# POST /{tenantID}/getObjectsByObjectIds
# Returns: record<"odata.nextLink": string, value: table<deletionTimestamp: string, objectId: string, objectType: string>>
# operationId: Objects_GetObjectsByObjectIds
export def "objects-get-objects-by-object-ids" [
  tenant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version. (required)
  --include-directory-object-references: oneof<nothing, bool> # If true, also searches for object IDs in the partner tenant.
  --object-ids: list<string> # The requested object IDs.
  --types: list<string> # The requested object types.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{tenantID}/getObjectsByObjectIds"
    path_params: [{name: tenantID, var: tenant_id}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: includeDirectoryObjectReferences, var: include_directory_object_references}, {name: objectIds, var: object_ids}, {name: types, var: types}]}
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    tenant_id: $tenant_id, api_version: $api_version, include_directory_object_references: $include_directory_object_references, object_ids: $object_ids, types: $types
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets list of groups for the current tenant.
#
# GET /{tenantID}/groups
# Returns: record<"odata.nextLink": string, value: table<displayName: string, mail: string, mailEnabled: bool, mailNickname: string, securityEnabled: bool, deletionTimestamp: string, objectId: string, objectType: string>>
# operationId: Groups_List
export def "groups-list" [
  tenant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --filter: string # The filter to apply to the operation.
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{tenantID}/groups"
    path_params: [{name: tenantID, var: tenant_id}]
    query: [{name: "$filter", var: filter}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    tenant_id: $tenant_id, filter: $filter, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a group in the directory.
#
# POST /{tenantID}/groups
# Returns: record<displayName: string, mail: string, mailEnabled: bool, mailNickname: string, securityEnabled: bool, deletionTimestamp: string, objectId: string, objectType: string>
# operationId: Groups_Create
export def "groups-create" [
  tenant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version. (required)
  display_name: string # Group display name
  --mail-enabled: oneof<nothing, bool> # Whether the group is mail-enabled. Must be false. This is because only pure security groups can be created using the Graph API.
  mail_nickname: string # Mail nickname
  --security-enabled: oneof<nothing, bool> # Whether the group is a security group. Must be true. This is because only pure security groups can be created using the Graph API.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{tenantID}/groups"
    path_params: [{name: tenantID, var: tenant_id}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: displayName, var: display_name}, {name: mailEnabled, var: mail_enabled, required: true}, {name: mailNickname, var: mail_nickname}, {name: securityEnabled, var: security_enabled, required: true}]}
    accept: ["application/json", "text/json"]
    ok: [201]
    auth: bearer
  } {
    tenant_id: $tenant_id, api_version: $api_version, display_name: $display_name, mail_enabled: $mail_enabled, mail_nickname: $mail_nickname, security_enabled: $security_enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add a member to a group.
#
# POST /{tenantID}/groups/{groupObjectId}/$links/members
# operationId: Groups_AddMember
export def "groups-add-member" [
  tenant_id: string
  group_object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version. (required)
  url: string # A member object URL, such as "https://graph.windows.net/0b1f9851-1bf0-433f-aec3-cb9272f093dc/directoryObjects/f260bbc4-c254-447b-94cf-293b5ec434dd", where "0b1f9851-1bf0-433f-aec3-cb9272f093dc" is the tenantId and "f260bbc4-c254-447b-94cf-293b5ec434dd" is the objectId of the member (user, application, servicePrincipal, group) to be added.
]: any -> any {
  $in | http-request {
    method: post
    path: "/{tenantID}/groups/{groupObjectId}/$links/members"
    path_params: [{name: tenantID, var: tenant_id}, {name: groupObjectId, var: group_object_id}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: url, var: url}]}
    accept: ["application/json", "text/json"]
    ok: [204]
    auth: bearer
  } {
    tenant_id: $tenant_id, group_object_id: $group_object_id, api_version: $api_version, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Remove a member from a group.
#
# DELETE /{tenantID}/groups/{groupObjectId}/$links/members/{memberObjectId}
# operationId: Groups_RemoveMember
export def "groups-remove-member" [
  tenant_id: string
  group_object_id: string
  member_object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/{tenantID}/groups/{groupObjectId}/$links/members/{memberObjectId}"
    path_params: [{name: tenantID, var: tenant_id}, {name: groupObjectId, var: group_object_id}, {name: memberObjectId, var: member_object_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [204]
    auth: bearer
  } {
    tenant_id: $tenant_id, group_object_id: $group_object_id, member_object_id: $member_object_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a group from the directory.
#
# DELETE /{tenantID}/groups/{objectId}
# operationId: Groups_Delete
export def "groups-delete" [
  tenant_id: string
  object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/{tenantID}/groups/{objectId}"
    path_params: [{name: tenantID, var: tenant_id}, {name: objectId, var: object_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [204]
    auth: bearer
  } {
    tenant_id: $tenant_id, object_id: $object_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets group information from the directory.
#
# GET /{tenantID}/groups/{objectId}
# Returns: record<displayName: string, mail: string, mailEnabled: bool, mailNickname: string, securityEnabled: bool, deletionTimestamp: string, objectId: string, objectType: string>
# operationId: Groups_Get
export def "groups-get" [
  tenant_id: string
  object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{tenantID}/groups/{objectId}"
    path_params: [{name: tenantID, var: tenant_id}, {name: objectId, var: object_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    tenant_id: $tenant_id, object_id: $object_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add an owner to a group.
#
# POST /{tenantID}/groups/{objectId}/$links/owners
# operationId: Groups_AddOwner
export def "groups-add-owner" [
  tenant_id: string
  object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version. (required)
  url: string # A owner object URL, such as "https://graph.windows.net/0b1f9851-1bf0-433f-aec3-cb9272f093dc/directoryObjects/f260bbc4-c254-447b-94cf-293b5ec434dd", where "0b1f9851-1bf0-433f-aec3-cb9272f093dc" is the tenantId and "f260bbc4-c254-447b-94cf-293b5ec434dd" is the objectId of the owner (user, application, servicePrincipal, group) to be added.
]: any -> any {
  $in | http-request {
    method: post
    path: "/{tenantID}/groups/{objectId}/$links/owners"
    path_params: [{name: tenantID, var: tenant_id}, {name: objectId, var: object_id}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: url, var: url}]}
    accept: ["application/json", "text/json"]
    ok: [204]
    auth: bearer
  } {
    tenant_id: $tenant_id, object_id: $object_id, api_version: $api_version, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Remove a member from owners.
#
# DELETE /{tenantID}/groups/{objectId}/$links/owners/{ownerObjectId}
# operationId: Groups_RemoveOwner
export def "groups-remove-owner" [
  tenant_id: string
  object_id: string
  owner_object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/{tenantID}/groups/{objectId}/$links/owners/{ownerObjectId}"
    path_params: [{name: tenantID, var: tenant_id}, {name: objectId, var: object_id}, {name: ownerObjectId, var: owner_object_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [204]
    auth: bearer
  } {
    tenant_id: $tenant_id, object_id: $object_id, owner_object_id: $owner_object_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets a collection of object IDs of groups of which the specified group is a member.
#
# POST /{tenantID}/groups/{objectId}/getMemberGroups
# Returns: record<value: list<string>>
# operationId: Groups_GetMemberGroups
export def "groups-get-member-groups" [
  tenant_id: string
  object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version. (required)
  --security-enabled-only: oneof<nothing, bool> # If true, only membership in security-enabled groups should be checked. Otherwise, membership in all groups should be checked.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{tenantID}/groups/{objectId}/getMemberGroups"
    path_params: [{name: tenantID, var: tenant_id}, {name: objectId, var: object_id}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: securityEnabledOnly, var: security_enabled_only, required: true}]}
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    tenant_id: $tenant_id, object_id: $object_id, api_version: $api_version, security_enabled_only: $security_enabled_only
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the members of a group.
#
# GET /{tenantID}/groups/{objectId}/members
# Returns: record<"odata.nextLink": string, value: table<deletionTimestamp: string, objectId: string, objectType: string>>
# operationId: Groups_GetGroupMembers
export def "groups-get-group-members" [
  tenant_id: string
  object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{tenantID}/groups/{objectId}/members"
    path_params: [{name: tenantID, var: tenant_id}, {name: objectId, var: object_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    tenant_id: $tenant_id, object_id: $object_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Directory objects that are owners of the group.
#
# GET /{tenantID}/groups/{objectId}/owners
# Returns: record<"odata.nextLink": string, value: table<deletionTimestamp: string, objectId: string, objectType: string>>
# operationId: Groups_ListOwners
export def "groups-list-owners" [
  tenant_id: string
  object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{tenantID}/groups/{objectId}/owners"
    path_params: [{name: tenantID, var: tenant_id}, {name: objectId, var: object_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    tenant_id: $tenant_id, object_id: $object_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Checks whether the specified user, group, contact, or service principal is a direct or transitive member of the specified group.
#
# POST /{tenantID}/isMemberOf
# Returns: record<value: bool>
# operationId: Groups_IsMemberOf
export def "groups-is-member-of" [
  tenant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version. (required)
  group_id: string # The object ID of the group to check.
  member_id: string # The object ID of the contact, group, user, or service principal to check for membership in the specified group.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{tenantID}/isMemberOf"
    path_params: [{name: tenantID, var: tenant_id}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: groupId, var: group_id}, {name: memberId, var: member_id}]}
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    tenant_id: $tenant_id, api_version: $api_version, group_id: $group_id, member_id: $member_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the details for the currently logged-in user.
#
# GET /{tenantID}/me
# Returns: record<accountEnabled: bool, displayName: string, givenName: string, immutableId: string, mail: string, mailNickname: string, signInNames: table<type: string, value: string>, surname: string, usageLocation: string, userPrincipalName: string, userType: string, deletionTimestamp: string, objectId: string, objectType: string>
# operationId: SignedInUser_Get
export def "signed-in-user-get" [
  tenant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{tenantID}/me"
    path_params: [{name: tenantID, var: tenant_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    tenant_id: $tenant_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get the list of directory objects that are owned by the user.
#
# GET /{tenantID}/me/ownedObjects
# Returns: record<"odata.nextLink": string, value: table<deletionTimestamp: string, objectId: string, objectType: string>>
# operationId: SignedInUser_ListOwnedObjects
export def "signed-in-user-list-owned-objects" [
  tenant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{tenantID}/me/ownedObjects"
    path_params: [{name: tenantID, var: tenant_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    tenant_id: $tenant_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Queries OAuth2 permissions grants for the relevant SP ObjectId of an app.
#
# GET /{tenantID}/oauth2PermissionGrants
# Returns: record<"odata.nextLink": string, value: table<clientId: string, consentType: string, expiryTime: string, objectId: string, "odata.type": string, principalId: string, resourceId: string, scope: string, startTime: string>>
# operationId: OAuth2PermissionGrant_List
export def "o-auth2-permission-grant-list" [
  tenant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # This is the Service Principal ObjectId associated with the app (e.g. clientId+eq+'61ed44c3-5a1d-4639-a215-07f25129c6c3)
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{tenantID}/oauth2PermissionGrants"
    path_params: [{name: tenantID, var: tenant_id}]
    query: [{name: "$filter", var: filter}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tenant_id: $tenant_id, filter: $filter, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Grants OAuth2 permissions for the relevant resource Ids of an app.
#
# POST /{tenantID}/oauth2PermissionGrants
# Returns: record<clientId: string, consentType: string, expiryTime: string, objectId: string, "odata.type": string, principalId: string, resourceId: string, scope: string, startTime: string>
# operationId: OAuth2PermissionGrant_Create
export def "o-auth2-permission-grant-create" [
  tenant_id: string
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
  --client-id: string # The id of the resource's service principal granted consent to impersonate the user when accessing the resource (represented by the resourceId property).
  --consent-type: string@consent-type-completer # Indicates if consent was provided by the administrator (on behalf of the organization) or by an individual.
  --expiry-time: string # Expiry time for TTL
  --object-id: string # The id of the permission grant
  --odata-type: string # Microsoft.DirectoryServices.OAuth2PermissionGrant
  --principal-id: string # When consent type is Principal, this property specifies the id of the user that granted consent and applies only for that user.
  --resource-id: string # Object Id of the resource you want to grant
  --scope: string # Specifies the value of the scope claim that the resource application should expect in the OAuth 2.0 access token. For example, User.Read
  --start-time: string # Start time for TTL
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{tenantID}/oauth2PermissionGrants"
    path_params: [{name: tenantID, var: tenant_id}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: clientId, var: client_id}, {name: consentType, var: consent_type}, {name: expiryTime, var: expiry_time}, {name: objectId, var: object_id}, {name: "odata.type", var: odata_type}, {name: principalId, var: principal_id}, {name: resourceId, var: resource_id}, {name: scope, var: scope}, {name: startTime, var: start_time}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    tenant_id: $tenant_id, api_version: $api_version, client_id: $client_id, consent_type: $consent_type, expiry_time: $expiry_time, object_id: $object_id, odata_type: $odata_type, principal_id: $principal_id, resource_id: $resource_id, scope: $scope, start_time: $start_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a OAuth2 permission grant for the relevant resource Ids of an app.
#
# DELETE /{tenantID}/oauth2PermissionGrants/{objectId}
# operationId: OAuth2PermissionGrant_Delete
export def "o-auth2-permission-grant-delete" [
  tenant_id: string
  object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/{tenantID}/oauth2PermissionGrants/{objectId}"
    path_params: [{name: tenantID, var: tenant_id}, {name: objectId, var: object_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [204]
    auth: bearer
  } {
    tenant_id: $tenant_id, object_id: $object_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets a list of service principals from the current tenant.
#
# GET /{tenantID}/servicePrincipals
# Returns: record<"odata.nextLink": string, value: table<accountEnabled: bool, alternativeNames: list, appDisplayName: string, appId: string, appOwnerTenantId: string, appRoleAssignmentRequired: bool, appRoles: list, displayName: string, errorUrl: string, homepage: string, keyCredentials: list, logoutUrl: string, oauth2Permissions: list, passwordCredentials: list, preferredTokenSigningKeyThumbprint: string, publisherName: string, replyUrls: list, samlMetadataUrl: string, servicePrincipalNames: list, servicePrincipalType: string, tags: list, deletionTimestamp: string, objectId: string, objectType: string>>
# operationId: ServicePrincipals_List
export def "service-principals-list" [
  tenant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --filter: string # The filter to apply to the operation.
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{tenantID}/servicePrincipals"
    path_params: [{name: tenantID, var: tenant_id}]
    query: [{name: "$filter", var: filter}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    tenant_id: $tenant_id, filter: $filter, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Creates a service principal in the directory.
#
# POST /{tenantID}/servicePrincipals
# Returns: record<accountEnabled: bool, alternativeNames: list<string>, appDisplayName: string, appId: string, appOwnerTenantId: string, appRoleAssignmentRequired: bool, appRoles: table<allowedMemberTypes: list, description: string, displayName: string, id: string, isEnabled: bool, value: string>, displayName: string, errorUrl: string, homepage: string, keyCredentials: table<customKeyIdentifier: string, endDate: string, keyId: string, startDate: string, type: string, usage: string, value: string>, logoutUrl: string, oauth2Permissions: table<adminConsentDescription: string, adminConsentDisplayName: string, id: string, isEnabled: bool, type: string, userConsentDescription: string, userConsentDisplayName: string, value: string>, passwordCredentials: table<customKeyIdentifier: string, endDate: string, keyId: string, startDate: string, value: string>, preferredTokenSigningKeyThumbprint: string, publisherName: string, replyUrls: list<string>, samlMetadataUrl: string, servicePrincipalNames: list<string>, servicePrincipalType: string, tags: list<string>, deletionTimestamp: string, objectId: string, objectType: string>
# operationId: ServicePrincipals_Create
export def "service-principals-create" [
  tenant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version. (required)
  app_id: string # The application ID.
  --account-enabled: oneof<nothing, bool> # whether or not the service principal account is enabled
  --app-role-assignment-required: oneof<nothing, bool> # Specifies whether an AppRoleAssignment to a user or group is required before Azure AD will issue a user or access token to the application.
  --key-credentials: list # The collection of key credentials associated with the service principal. — item shape: {customKeyIdentifier?: string, endDate?: string, keyId?: string, startDate?: string, type?: string, usage?: string, value?: string}
  --password-credentials: list # The collection of password credentials associated with the service principal. — item shape: {customKeyIdentifier?: string, endDate?: string, keyId?: string, startDate?: string, value?: string}
  --service-principal-type: string # the type of the service principal
  --tags: list<string> # Optional list of tags that you can apply to your service principals. Not nullable.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{tenantID}/servicePrincipals"
    path_params: [{name: tenantID, var: tenant_id}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: appId, var: app_id}, {name: accountEnabled, var: account_enabled}, {name: appRoleAssignmentRequired, var: app_role_assignment_required}, {name: keyCredentials, var: key_credentials}, {name: passwordCredentials, var: password_credentials}, {name: servicePrincipalType, var: service_principal_type}, {name: tags, var: tags}]}
    accept: ["application/json", "text/json"]
    ok: [201]
    auth: bearer
  } {
    tenant_id: $tenant_id, api_version: $api_version, app_id: $app_id, account_enabled: $account_enabled, app_role_assignment_required: $app_role_assignment_required, key_credentials: $key_credentials, password_credentials: $password_credentials, service_principal_type: $service_principal_type, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Deletes a service principal from the directory.
#
# DELETE /{tenantID}/servicePrincipals/{objectId}
# operationId: ServicePrincipals_Delete
export def "service-principals-delete" [
  tenant_id: string
  object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/{tenantID}/servicePrincipals/{objectId}"
    path_params: [{name: tenantID, var: tenant_id}, {name: objectId, var: object_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [204]
    auth: bearer
  } {
    tenant_id: $tenant_id, object_id: $object_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets service principal information from the directory. Query by objectId or pass a filter to query by appId
#
# GET /{tenantID}/servicePrincipals/{objectId}
# Returns: record<accountEnabled: bool, alternativeNames: list<string>, appDisplayName: string, appId: string, appOwnerTenantId: string, appRoleAssignmentRequired: bool, appRoles: table<allowedMemberTypes: list, description: string, displayName: string, id: string, isEnabled: bool, value: string>, displayName: string, errorUrl: string, homepage: string, keyCredentials: table<customKeyIdentifier: string, endDate: string, keyId: string, startDate: string, type: string, usage: string, value: string>, logoutUrl: string, oauth2Permissions: table<adminConsentDescription: string, adminConsentDisplayName: string, id: string, isEnabled: bool, type: string, userConsentDescription: string, userConsentDisplayName: string, value: string>, passwordCredentials: table<customKeyIdentifier: string, endDate: string, keyId: string, startDate: string, value: string>, preferredTokenSigningKeyThumbprint: string, publisherName: string, replyUrls: list<string>, samlMetadataUrl: string, servicePrincipalNames: list<string>, servicePrincipalType: string, tags: list<string>, deletionTimestamp: string, objectId: string, objectType: string>
# operationId: ServicePrincipals_Get
export def "service-principals-get" [
  tenant_id: string
  object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{tenantID}/servicePrincipals/{objectId}"
    path_params: [{name: tenantID, var: tenant_id}, {name: objectId, var: object_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    tenant_id: $tenant_id, object_id: $object_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Updates a service principal in the directory.
#
# PATCH /{tenantID}/servicePrincipals/{objectId}
# operationId: ServicePrincipals_Update
export def "service-principals-update" [
  tenant_id: string
  object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version. (required)
  --account-enabled: oneof<nothing, bool> # whether or not the service principal account is enabled
  --app-role-assignment-required: oneof<nothing, bool> # Specifies whether an AppRoleAssignment to a user or group is required before Azure AD will issue a user or access token to the application.
  --key-credentials: list # The collection of key credentials associated with the service principal. — item shape: {customKeyIdentifier?: string, endDate?: string, keyId?: string, startDate?: string, type?: string, usage?: string, value?: string}
  --password-credentials: list # The collection of password credentials associated with the service principal. — item shape: {customKeyIdentifier?: string, endDate?: string, keyId?: string, startDate?: string, value?: string}
  --service-principal-type: string # the type of the service principal
  --tags: list<string> # Optional list of tags that you can apply to your service principals. Not nullable.
]: any -> any {
  $in | http-request {
    method: patch
    path: "/{tenantID}/servicePrincipals/{objectId}"
    path_params: [{name: tenantID, var: tenant_id}, {name: objectId, var: object_id}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountEnabled, var: account_enabled}, {name: appRoleAssignmentRequired, var: app_role_assignment_required}, {name: keyCredentials, var: key_credentials}, {name: passwordCredentials, var: password_credentials}, {name: servicePrincipalType, var: service_principal_type}, {name: tags, var: tags}]}
    accept: ["application/json", "text/json"]
    ok: [204]
    auth: bearer
  } {
    tenant_id: $tenant_id, object_id: $object_id, api_version: $api_version, account_enabled: $account_enabled, app_role_assignment_required: $app_role_assignment_required, key_credentials: $key_credentials, password_credentials: $password_credentials, service_principal_type: $service_principal_type, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add an owner to a service principal.
#
# POST /{tenantID}/servicePrincipals/{objectId}/$links/owners
# operationId: ServicePrincipals_AddOwner
export def "service-principals-add-owner" [
  tenant_id: string
  object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version. (required)
  url: string # A owner object URL, such as "https://graph.windows.net/0b1f9851-1bf0-433f-aec3-cb9272f093dc/directoryObjects/f260bbc4-c254-447b-94cf-293b5ec434dd", where "0b1f9851-1bf0-433f-aec3-cb9272f093dc" is the tenantId and "f260bbc4-c254-447b-94cf-293b5ec434dd" is the objectId of the owner (user, application, servicePrincipal, group) to be added.
]: any -> any {
  $in | http-request {
    method: post
    path: "/{tenantID}/servicePrincipals/{objectId}/$links/owners"
    path_params: [{name: tenantID, var: tenant_id}, {name: objectId, var: object_id}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: url, var: url}]}
    accept: ["application/json", "text/json"]
    ok: [204]
    auth: bearer
  } {
    tenant_id: $tenant_id, object_id: $object_id, api_version: $api_version, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Remove a member from owners.
#
# DELETE /{tenantID}/servicePrincipals/{objectId}/$links/owners/{ownerObjectId}
# operationId: ServicePrincipals_RemoveOwner
export def "service-principals-remove-owner" [
  tenant_id: string
  object_id: string
  owner_object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/{tenantID}/servicePrincipals/{objectId}/$links/owners/{ownerObjectId}"
    path_params: [{name: tenantID, var: tenant_id}, {name: objectId, var: object_id}, {name: ownerObjectId, var: owner_object_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [204]
    auth: bearer
  } {
    tenant_id: $tenant_id, object_id: $object_id, owner_object_id: $owner_object_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Principals (users, groups, and service principals) that are assigned to this service principal.
#
# GET /{tenantID}/servicePrincipals/{objectId}/appRoleAssignedTo
# Returns: record<"odata.nextLink": string, value: table<id: string, principalDisplayName: string, principalId: string, principalType: string, resourceDisplayName: string, resourceId: string, deletionTimestamp: string, objectId: string, objectType: string>>
# operationId: ServicePrincipals_ListAppRoleAssignedTo
export def "service-principals-list-app-role-assigned-to" [
  tenant_id: string
  object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{tenantID}/servicePrincipals/{objectId}/appRoleAssignedTo"
    path_params: [{name: tenantID, var: tenant_id}, {name: objectId, var: object_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    tenant_id: $tenant_id, object_id: $object_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Applications that the service principal is assigned to.
#
# GET /{tenantID}/servicePrincipals/{objectId}/appRoleAssignments
# Returns: record<"odata.nextLink": string, value: table<id: string, principalDisplayName: string, principalId: string, principalType: string, resourceDisplayName: string, resourceId: string, deletionTimestamp: string, objectId: string, objectType: string>>
# operationId: ServicePrincipals_ListAppRoleAssignments
export def "service-principals-list-app-role-assignments" [
  tenant_id: string
  object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{tenantID}/servicePrincipals/{objectId}/appRoleAssignments"
    path_params: [{name: tenantID, var: tenant_id}, {name: objectId, var: object_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    tenant_id: $tenant_id, object_id: $object_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get the keyCredentials associated with the specified service principal.
#
# GET /{tenantID}/servicePrincipals/{objectId}/keyCredentials
# Returns: record<value: table<customKeyIdentifier: string, endDate: string, keyId: string, startDate: string, type: string, usage: string, value: string>>
# operationId: ServicePrincipals_ListKeyCredentials
export def "service-principals-list-key-credentials" [
  tenant_id: string
  object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{tenantID}/servicePrincipals/{objectId}/keyCredentials"
    path_params: [{name: tenantID, var: tenant_id}, {name: objectId, var: object_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    tenant_id: $tenant_id, object_id: $object_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update the keyCredentials associated with a service principal.
#
# PATCH /{tenantID}/servicePrincipals/{objectId}/keyCredentials
# operationId: ServicePrincipals_UpdateKeyCredentials
export def "service-principals-update-key-credentials" [
  tenant_id: string
  object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version. (required)
  value: list # A collection of KeyCredentials. — item shape: {customKeyIdentifier?: string, endDate?: string, keyId?: string, startDate?: string, type?: string, usage?: string, value?: string}
]: any -> any {
  $in | http-request {
    method: patch
    path: "/{tenantID}/servicePrincipals/{objectId}/keyCredentials"
    path_params: [{name: tenantID, var: tenant_id}, {name: objectId, var: object_id}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json", "text/json"]
    ok: [204]
    auth: bearer
  } {
    tenant_id: $tenant_id, object_id: $object_id, api_version: $api_version, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Directory objects that are owners of this service principal.
#
# GET /{tenantID}/servicePrincipals/{objectId}/owners
# Returns: record<"odata.nextLink": string, value: table<deletionTimestamp: string, objectId: string, objectType: string>>
# operationId: ServicePrincipals_ListOwners
export def "service-principals-list-owners" [
  tenant_id: string
  object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{tenantID}/servicePrincipals/{objectId}/owners"
    path_params: [{name: tenantID, var: tenant_id}, {name: objectId, var: object_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    tenant_id: $tenant_id, object_id: $object_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the passwordCredentials associated with a service principal.
#
# GET /{tenantID}/servicePrincipals/{objectId}/passwordCredentials
# Returns: record<value: table<customKeyIdentifier: string, endDate: string, keyId: string, startDate: string, value: string>>
# operationId: ServicePrincipals_ListPasswordCredentials
export def "service-principals-list-password-credentials" [
  tenant_id: string
  object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{tenantID}/servicePrincipals/{objectId}/passwordCredentials"
    path_params: [{name: tenantID, var: tenant_id}, {name: objectId, var: object_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    tenant_id: $tenant_id, object_id: $object_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Updates the passwordCredentials associated with a service principal.
#
# PATCH /{tenantID}/servicePrincipals/{objectId}/passwordCredentials
# operationId: ServicePrincipals_UpdatePasswordCredentials
export def "service-principals-update-password-credentials" [
  tenant_id: string
  object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version. (required)
  value: list # A collection of PasswordCredentials. — item shape: {customKeyIdentifier?: string, endDate?: string, keyId?: string, startDate?: string, value?: string}
]: any -> any {
  $in | http-request {
    method: patch
    path: "/{tenantID}/servicePrincipals/{objectId}/passwordCredentials"
    path_params: [{name: tenantID, var: tenant_id}, {name: objectId, var: object_id}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json", "text/json"]
    ok: [204]
    auth: bearer
  } {
    tenant_id: $tenant_id, object_id: $object_id, api_version: $api_version, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets an object id for a given application id from the current tenant.
#
# GET /{tenantID}/servicePrincipalsByAppId/{applicationID}/objectId
# Returns: record<"odata.metadata": string, value: string>
# operationId: Applications_GetServicePrincipalsIdByAppId
export def "applications-get-service-principals-id-by-app-id" [
  tenant_id: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{tenantID}/servicePrincipalsByAppId/{applicationID}/objectId"
    path_params: [{name: tenantID, var: tenant_id}, {name: applicationID, var: application_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    tenant_id: $tenant_id, application_id: $application_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets list of users for the current tenant.
#
# GET /{tenantID}/users
# Returns: record<"odata.nextLink": string, value: table<accountEnabled: bool, displayName: string, givenName: string, immutableId: string, mail: string, mailNickname: string, signInNames: list, surname: string, usageLocation: string, userPrincipalName: string, userType: string, deletionTimestamp: string, objectId: string, objectType: string>>
# operationId: Users_List
export def "users-list" [
  tenant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --filter: string # The filter to apply to the operation.
  --expand: string # The expand value for the operation result.
  --top: int # (Optional) Set the maximum number of results per response. (default: 100)
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{tenantID}/users"
    path_params: [{name: tenantID, var: tenant_id}]
    query: [{name: "$filter", var: filter}, {name: "$expand", var: expand}, {name: "$top", var: top}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    tenant_id: $tenant_id, filter: $filter, expand: $expand, top: $top, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a new user.
#
# POST /{tenantID}/users
# Returns: record<accountEnabled: bool, displayName: string, givenName: string, immutableId: string, mail: string, mailNickname: string, signInNames: table<type: string, value: string>, surname: string, usageLocation: string, userPrincipalName: string, userType: string, deletionTimestamp: string, objectId: string, objectType: string>
# operationId: Users_Create
export def "users-create" [
  tenant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version. (required)
  --account-enabled: oneof<nothing, bool> # Whether the account is enabled.
  display_name: string # The display name of the user.
  --mail: string # The primary email address of the user.
  mail_nickname: string # The mail alias for the user.
  password_profile: record # The password profile associated with a user. — shape: {forceChangePasswordNextLogin?: bool, password: string}
  user_principal_name: string # The user principal name (someuser@contoso.com). It must contain one of the verified domains for the tenant.
  --given-name: string # The given name for the user.
  --immutable-id: string # This must be specified if you are using a federated domain for the user's userPrincipalName (UPN) property when creating a new user account. It is used to associate an on-premises Active Directory user account with their Azure AD user object.
  --surname: string # The user's surname (family name or last name).
  --usage-location: string # A two letter country code (ISO standard 3166). Required for users that will be assigned licenses due to legal requirement to check for availability of services in countries. Examples include: "US", "JP", and "GB".
  --user-type: string@user-type-completer # A string value that can be used to classify user types in your directory, such as 'Member' and 'Guest'.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{tenantID}/users"
    path_params: [{name: tenantID, var: tenant_id}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountEnabled, var: account_enabled, required: true}, {name: displayName, var: display_name}, {name: mail, var: mail}, {name: mailNickname, var: mail_nickname}, {name: passwordProfile, var: password_profile}, {name: userPrincipalName, var: user_principal_name}, {name: givenName, var: given_name}, {name: immutableId, var: immutable_id}, {name: surname, var: surname}, {name: usageLocation, var: usage_location}, {name: userType, var: user_type}]}
    accept: ["application/json", "text/json"]
    ok: [201]
    auth: bearer
  } {
    tenant_id: $tenant_id, api_version: $api_version, account_enabled: $account_enabled, display_name: $display_name, mail: $mail, mail_nickname: $mail_nickname, password_profile: $password_profile, user_principal_name: $user_principal_name, given_name: $given_name, immutable_id: $immutable_id, surname: $surname, usage_location: $usage_location, user_type: $user_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets a collection that contains the object IDs of the groups of which the user is a member.
#
# POST /{tenantID}/users/{objectId}/getMemberGroups
# Returns: record<value: list<string>>
# operationId: Users_GetMemberGroups
export def "users-get-member-groups" [
  tenant_id: string
  object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version. (required)
  --security-enabled-only: oneof<nothing, bool> # If true, only membership in security-enabled groups should be checked. Otherwise, membership in all groups should be checked.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{tenantID}/users/{objectId}/getMemberGroups"
    path_params: [{name: tenantID, var: tenant_id}, {name: objectId, var: object_id}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: securityEnabledOnly, var: security_enabled_only, required: true}]}
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    tenant_id: $tenant_id, object_id: $object_id, api_version: $api_version, security_enabled_only: $security_enabled_only
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a user.
#
# DELETE /{tenantID}/users/{upnOrObjectId}
# operationId: Users_Delete
export def "users-delete" [
  tenant_id: string
  upn_or_object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/{tenantID}/users/{upnOrObjectId}"
    path_params: [{name: tenantID, var: tenant_id}, {name: upnOrObjectId, var: upn_or_object_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [204]
    auth: bearer
  } {
    tenant_id: $tenant_id, upn_or_object_id: $upn_or_object_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets user information from the directory.
#
# GET /{tenantID}/users/{upnOrObjectId}
# Returns: record<accountEnabled: bool, displayName: string, givenName: string, immutableId: string, mail: string, mailNickname: string, signInNames: table<type: string, value: string>, surname: string, usageLocation: string, userPrincipalName: string, userType: string, deletionTimestamp: string, objectId: string, objectType: string>
# operationId: Users_Get
export def "users-get" [
  tenant_id: string
  upn_or_object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{tenantID}/users/{upnOrObjectId}"
    path_params: [{name: tenantID, var: tenant_id}, {name: upnOrObjectId, var: upn_or_object_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    tenant_id: $tenant_id, upn_or_object_id: $upn_or_object_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Updates a user.
#
# PATCH /{tenantID}/users/{upnOrObjectId}
# operationId: Users_Update
export def "users-update" [
  tenant_id: string
  upn_or_object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version. (required)
  --account-enabled: oneof<nothing, bool> # Whether the account is enabled.
  --display-name: string # The display name of the user.
  --mail: string # The primary email address of the user.
  --mail-nickname: string # The mail alias for the user.
  --password-profile: record # The password profile associated with a user. — shape: {forceChangePasswordNextLogin?: bool, password: string}
  --user-principal-name: string # The user principal name (someuser@contoso.com). It must contain one of the verified domains for the tenant.
  --given-name: string # The given name for the user.
  --immutable-id: string # This must be specified if you are using a federated domain for the user's userPrincipalName (UPN) property when creating a new user account. It is used to associate an on-premises Active Directory user account with their Azure AD user object.
  --surname: string # The user's surname (family name or last name).
  --usage-location: string # A two letter country code (ISO standard 3166). Required for users that will be assigned licenses due to legal requirement to check for availability of services in countries. Examples include: "US", "JP", and "GB".
  --user-type: string@user-type-completer # A string value that can be used to classify user types in your directory, such as 'Member' and 'Guest'.
]: any -> any {
  $in | http-request {
    method: patch
    path: "/{tenantID}/users/{upnOrObjectId}"
    path_params: [{name: tenantID, var: tenant_id}, {name: upnOrObjectId, var: upn_or_object_id}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountEnabled, var: account_enabled}, {name: displayName, var: display_name}, {name: mail, var: mail}, {name: mailNickname, var: mail_nickname}, {name: passwordProfile, var: password_profile}, {name: userPrincipalName, var: user_principal_name}, {name: givenName, var: given_name}, {name: immutableId, var: immutable_id}, {name: surname, var: surname}, {name: usageLocation, var: usage_location}, {name: userType, var: user_type}]}
    accept: ["application/json", "text/json"]
    ok: [204]
    auth: bearer
  } {
    tenant_id: $tenant_id, upn_or_object_id: $upn_or_object_id, api_version: $api_version, account_enabled: $account_enabled, display_name: $display_name, mail: $mail, mail_nickname: $mail_nickname, password_profile: $password_profile, user_principal_name: $user_principal_name, given_name: $given_name, immutable_id: $immutable_id, surname: $surname, usage_location: $usage_location, user_type: $user_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}
