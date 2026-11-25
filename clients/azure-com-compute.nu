# Auto-generated client for ComputeManagementClient v2019-03-01
# Source: https://api.apis.guru/v2/specs/azure.com/compute/2019-03-01/swagger.json
# Auth: --token flag or $env.COMPUTEMANAGEMENTCLIENT_TOKEN

const CLIENT = {
  base_url: "https://management.azure.com"
  token_env_var: "COMPUTEMANAGEMENTCLIENT_TOKEN"
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
def interval-length-completer [] { ["FiveMins" "SixtyMins" "ThirtyMins" "ThreeMins"] }
def expand-completer [] { ["instanceView"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    operations-list: "record<value: table<display: record, name: string, origin: string>>"
    availability-sets-list-by-subscription: "record<nextLink: string, value: table<properties: record, sku: record, id: string, location: string, name: string, tags: record, type: string>>"
    dedicated-host-groups-list-by-subscription: "record<nextLink: string, value: table<properties: record, zones: list, id: string, location: string, name: string, tags: record, type: string>>"
    images-list: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    log-analytics-export-request-rate-by-interval: "record<properties: record<output: string>>"
    log-analytics-export-throttled-requests: "record<properties: record<output: string>>"
    virtual-machine-images-list-publishers: "table<location: string, name: string, tags: record, id: string>"
    virtual-machine-extension-images-list-types: "table<properties: record<computeRole: string, handlerSchema: string, operatingSystem: string, supportsMultipleExtensions: bool, vmScaleSetEnabled: bool>, id: string, location: string, name: string, tags: record, type: string>"
    virtual-machine-extension-images-list-versions: "table<properties: record<computeRole: string, handlerSchema: string, operatingSystem: string, supportsMultipleExtensions: bool, vmScaleSetEnabled: bool>, id: string, location: string, name: string, tags: record, type: string>"
    virtual-machine-extension-images-get: "record<properties: record<computeRole: string, handlerSchema: string, operatingSystem: string, supportsMultipleExtensions: bool, vmScaleSetEnabled: bool>, id: string, location: string, name: string, tags: record, type: string>"
    virtual-machine-images-list-offers: "table<location: string, name: string, tags: record, id: string>"
    virtual-machine-images-list-skus: "table<location: string, name: string, tags: record, id: string>"
    virtual-machine-images-list: "table<location: string, name: string, tags: record, id: string>"
    virtual-machine-images-get: "record<properties: record<automaticOSUpgradeProperties: record<automaticOSUpgradeSupported: bool>, dataDiskImages: list<record>, hyperVGeneration: string, osDiskImage: record<operatingSystem: string>, plan: record<name: string, product: string, publisher: string>>, location: string, name: string, tags: record, id: string>"
    usage-list: "record<nextLink: string, value: table<currentValue: int, limit: int, name: record, unit: string>>"
    virtual-machines-list-by-location: "record<nextLink: string, value: table<identity: record, plan: record, properties: record, resources: list, zones: list, id: string, location: string, name: string, tags: record, type: string>>"
    virtual-machine-sizes-list: "record<value: table<maxDataDiskCount: int, memoryInMB: int, name: string, numberOfCores: int, osDiskSizeInMB: int, resourceDiskSizeInMB: int>>"
    proximity-placement-groups-list-by-subscription: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    virtual-machine-scale-sets-list-all: "record<nextLink: string, value: table<identity: record, plan: record, properties: record, sku: record, zones: list, id: string, location: string, name: string, tags: record, type: string>>"
    virtual-machines-list-all: "record<nextLink: string, value: table<identity: record, plan: record, properties: record, resources: list, zones: list, id: string, location: string, name: string, tags: record, type: string>>"
    availability-sets-list: "record<nextLink: string, value: table<properties: record, sku: record, id: string, location: string, name: string, tags: record, type: string>>"
    availability-sets-get: "record<properties: record<platformFaultDomainCount: int, platformUpdateDomainCount: int, proximityPlacementGroup: record<id: string>, statuses: list<record>, virtualMachines: list<record>>, sku: record<capacity: int, name: string, tier: string>, id: string, location: string, name: string, tags: record, type: string>"
    availability-sets-update: "record<properties: record<platformFaultDomainCount: int, platformUpdateDomainCount: int, proximityPlacementGroup: record<id: string>, statuses: list<record>, virtualMachines: list<record>>, sku: record<capacity: int, name: string, tier: string>, id: string, location: string, name: string, tags: record, type: string>"
    availability-sets-create-or-update: "record<properties: record<platformFaultDomainCount: int, platformUpdateDomainCount: int, proximityPlacementGroup: record<id: string>, statuses: list<record>, virtualMachines: list<record>>, sku: record<capacity: int, name: string, tier: string>, id: string, location: string, name: string, tags: record, type: string>"
    availability-sets-list-available-sizes: "record<value: table<maxDataDiskCount: int, memoryInMB: int, name: string, numberOfCores: int, osDiskSizeInMB: int, resourceDiskSizeInMB: int>>"
    dedicated-host-groups-list-by-resource-group: "record<nextLink: string, value: table<properties: record, zones: list, id: string, location: string, name: string, tags: record, type: string>>"
    dedicated-host-groups-get: "record<properties: record<hosts: list<record>, platformFaultDomainCount: int>, zones: list<string>, id: string, location: string, name: string, tags: record, type: string>"
    dedicated-host-groups-update: "record<properties: record<hosts: list<record>, platformFaultDomainCount: int>, zones: list<string>, id: string, location: string, name: string, tags: record, type: string>"
    dedicated-host-groups-create-or-update: "record<properties: record<hosts: list<record>, platformFaultDomainCount: int>, zones: list<string>, id: string, location: string, name: string, tags: record, type: string>"
    dedicated-hosts-list-by-host-group: "record<nextLink: string, value: table<properties: record, sku: record, id: string, location: string, name: string, tags: record, type: string>>"
    dedicated-hosts-get: "record<properties: record<autoReplaceOnFailure: bool, hostId: string, instanceView: record<assetId: string, availableCapacity: record, statuses: list>, licenseType: string, platformFaultDomain: int, provisioningState: string, provisioningTime: string, virtualMachines: list<record>>, sku: record<capacity: int, name: string, tier: string>, id: string, location: string, name: string, tags: record, type: string>"
    dedicated-hosts-update: "record<properties: record<autoReplaceOnFailure: bool, hostId: string, instanceView: record<assetId: string, availableCapacity: record, statuses: list>, licenseType: string, platformFaultDomain: int, provisioningState: string, provisioningTime: string, virtualMachines: list<record>>, sku: record<capacity: int, name: string, tier: string>, id: string, location: string, name: string, tags: record, type: string>"
    dedicated-hosts-create-or-update: "record<properties: record<autoReplaceOnFailure: bool, hostId: string, instanceView: record<assetId: string, availableCapacity: record, statuses: list>, licenseType: string, platformFaultDomain: int, provisioningState: string, provisioningTime: string, virtualMachines: list<record>>, sku: record<capacity: int, name: string, tier: string>, id: string, location: string, name: string, tags: record, type: string>"
    images-list-by-resource-group: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    images-get: "record<properties: record<hyperVGeneration: string, provisioningState: string, sourceVirtualMachine: record<id: string>, storageProfile: record<dataDisks: list, osDisk: record, zoneResilient: bool>>, id: string, location: string, name: string, tags: record, type: string>"
    images-update: "record<properties: record<hyperVGeneration: string, provisioningState: string, sourceVirtualMachine: record<id: string>, storageProfile: record<dataDisks: list, osDisk: record, zoneResilient: bool>>, id: string, location: string, name: string, tags: record, type: string>"
    images-create-or-update: "record<properties: record<hyperVGeneration: string, provisioningState: string, sourceVirtualMachine: record<id: string>, storageProfile: record<dataDisks: list, osDisk: record, zoneResilient: bool>>, id: string, location: string, name: string, tags: record, type: string>"
    proximity-placement-groups-list-by-resource-group: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    proximity-placement-groups-get: "record<properties: record<availabilitySets: list<record>, proximityPlacementGroupType: string, virtualMachineScaleSets: list<record>, virtualMachines: list<record>>, id: string, location: string, name: string, tags: record, type: string>"
    proximity-placement-groups-update: "record<properties: record<availabilitySets: list<record>, proximityPlacementGroupType: string, virtualMachineScaleSets: list<record>, virtualMachines: list<record>>, id: string, location: string, name: string, tags: record, type: string>"
    proximity-placement-groups-create-or-update: "record<properties: record<availabilitySets: list<record>, proximityPlacementGroupType: string, virtualMachineScaleSets: list<record>, virtualMachines: list<record>>, id: string, location: string, name: string, tags: record, type: string>"
    virtual-machine-scale-sets-list: "record<nextLink: string, value: table<identity: record, plan: record, properties: record, sku: record, zones: list, id: string, location: string, name: string, tags: record, type: string>>"
    virtual-machine-scale-set-v-ms-list: "record<nextLink: string, value: table<instanceId: string, plan: record, properties: record, resources: list, sku: record, zones: list, id: string, location: string, name: string, tags: record, type: string>>"
    virtual-machine-scale-sets-get: "record<identity: record<principalId: string, tenantId: string, type: string, userAssignedIdentities: record>, plan: record<name: string, product: string, promotionCode: string, publisher: string>, properties: record<additionalCapabilities: record<ultraSSDEnabled: bool>, doNotRunExtensionsOnOverprovisionedVMs: bool, overprovision: bool, platformFaultDomainCount: int, provisioningState: string, proximityPlacementGroup: record<id: string>, scaleInPolicy: record<rules: list>, singlePlacementGroup: bool, uniqueId: string, upgradePolicy: record<automaticOSUpgradePolicy: record, mode: string, rollingUpgradePolicy: record>, virtualMachineProfile: record<billingProfile: record, diagnosticsProfile: record, evictionPolicy: string, extensionProfile: record, licenseType: string, networkProfile: record, osProfile: record, priority: string, scheduledEventsProfile: record, storageProfile: record>, zoneBalance: bool>, sku: record<capacity: int, name: string, tier: string>, zones: list<string>, id: string, location: string, name: string, tags: record, type: string>"
    virtual-machine-scale-sets-update: "record<identity: record<principalId: string, tenantId: string, type: string, userAssignedIdentities: record>, plan: record<name: string, product: string, promotionCode: string, publisher: string>, properties: record<additionalCapabilities: record<ultraSSDEnabled: bool>, doNotRunExtensionsOnOverprovisionedVMs: bool, overprovision: bool, platformFaultDomainCount: int, provisioningState: string, proximityPlacementGroup: record<id: string>, scaleInPolicy: record<rules: list>, singlePlacementGroup: bool, uniqueId: string, upgradePolicy: record<automaticOSUpgradePolicy: record, mode: string, rollingUpgradePolicy: record>, virtualMachineProfile: record<billingProfile: record, diagnosticsProfile: record, evictionPolicy: string, extensionProfile: record, licenseType: string, networkProfile: record, osProfile: record, priority: string, scheduledEventsProfile: record, storageProfile: record>, zoneBalance: bool>, sku: record<capacity: int, name: string, tier: string>, zones: list<string>, id: string, location: string, name: string, tags: record, type: string>"
    virtual-machine-scale-sets-create-or-update: "record<identity: record<principalId: string, tenantId: string, type: string, userAssignedIdentities: record>, plan: record<name: string, product: string, promotionCode: string, publisher: string>, properties: record<additionalCapabilities: record<ultraSSDEnabled: bool>, doNotRunExtensionsOnOverprovisionedVMs: bool, overprovision: bool, platformFaultDomainCount: int, provisioningState: string, proximityPlacementGroup: record<id: string>, scaleInPolicy: record<rules: list>, singlePlacementGroup: bool, uniqueId: string, upgradePolicy: record<automaticOSUpgradePolicy: record, mode: string, rollingUpgradePolicy: record>, virtualMachineProfile: record<billingProfile: record, diagnosticsProfile: record, evictionPolicy: string, extensionProfile: record, licenseType: string, networkProfile: record, osProfile: record, priority: string, scheduledEventsProfile: record, storageProfile: record>, zoneBalance: bool>, sku: record<capacity: int, name: string, tier: string>, zones: list<string>, id: string, location: string, name: string, tags: record, type: string>"
    virtual-machine-scale-set-extensions-list: "record<nextLink: string, value: table<name: string, properties: record, id: string>>"
    virtual-machine-scale-set-extensions-get: "record<name: string, properties: record<autoUpgradeMinorVersion: bool, forceUpdateTag: string, protectedSettings: record, provisionAfterExtensions: list<string>, provisioningState: string, publisher: string, settings: record, type: string, typeHandlerVersion: string>, id: string>"
    virtual-machine-scale-set-extensions-create-or-update: "record<name: string, properties: record<autoUpgradeMinorVersion: bool, forceUpdateTag: string, protectedSettings: record, provisionAfterExtensions: list<string>, provisioningState: string, publisher: string, settings: record, type: string, typeHandlerVersion: string>, id: string>"
    virtual-machine-scale-sets-force-recovery-service-fabric-platform-update-domain-walk: "record<nextPlatformUpdateDomain: int, walkPerformed: bool>"
    virtual-machine-scale-sets-get-instance-view: "record<extensions: table<name: string, statusesSummary: list>, statuses: table<code: string, displayStatus: string, level: string, message: string, time: string>, virtualMachine: record<statusesSummary: list<record>>>"
    virtual-machine-scale-sets-get-os-upgrade-history: "record<nextLink: string, value: table<location: string, properties: record, type: string>>"
    virtual-machine-scale-set-rolling-upgrades-get-latest: "record<properties: record<error: record<code: string, details: list, innererror: record, message: string, target: string>, policy: record<maxBatchInstancePercent: int, maxUnhealthyInstancePercent: int, maxUnhealthyUpgradedInstancePercent: int, pauseTimeBetweenBatches: string>, progress: record<failedInstanceCount: int, inProgressInstanceCount: int, pendingInstanceCount: int, successfulInstanceCount: int>, runningStatus: record<code: string, lastAction: string, lastActionTime: string, startTime: string>>, id: string, location: string, name: string, tags: record, type: string>"
    virtual-machine-scale-sets-list-skus: "record<nextLink: string, value: table<capacity: record, resourceType: string, sku: record>>"
    virtual-machine-scale-set-v-ms-get: "record<instanceId: string, plan: record<name: string, product: string, promotionCode: string, publisher: string>, properties: record<additionalCapabilities: record<ultraSSDEnabled: bool>, availabilitySet: record<id: string>, diagnosticsProfile: record<bootDiagnostics: record>, hardwareProfile: record<vmSize: string>, instanceView: record<bootDiagnostics: record, disks: list, extensions: list, maintenanceRedeployStatus: record, placementGroupId: string, platformFaultDomain: int, platformUpdateDomain: int, rdpThumbPrint: string, statuses: list, vmAgent: record, vmHealth: record>, latestModelApplied: bool, licenseType: string, modelDefinitionApplied: string, networkProfile: record<networkInterfaces: list>, networkProfileConfiguration: record<networkInterfaceConfigurations: list>, osProfile: record<adminPassword: string, adminUsername: string, allowExtensionOperations: bool, computerName: string, customData: string, linuxConfiguration: record, secrets: list, windowsConfiguration: record>, protectionPolicy: record<protectFromScaleIn: bool, protectFromScaleSetActions: bool>, provisioningState: string, storageProfile: record<dataDisks: list, imageReference: record, osDisk: record>, vmId: string>, resources: table<properties: record, id: string, location: string, name: string, tags: record, type: string>, sku: record<capacity: int, name: string, tier: string>, zones: list<string>, id: string, location: string, name: string, tags: record, type: string>"
    virtual-machine-scale-set-v-ms-update: "record<instanceId: string, plan: record<name: string, product: string, promotionCode: string, publisher: string>, properties: record<additionalCapabilities: record<ultraSSDEnabled: bool>, availabilitySet: record<id: string>, diagnosticsProfile: record<bootDiagnostics: record>, hardwareProfile: record<vmSize: string>, instanceView: record<bootDiagnostics: record, disks: list, extensions: list, maintenanceRedeployStatus: record, placementGroupId: string, platformFaultDomain: int, platformUpdateDomain: int, rdpThumbPrint: string, statuses: list, vmAgent: record, vmHealth: record>, latestModelApplied: bool, licenseType: string, modelDefinitionApplied: string, networkProfile: record<networkInterfaces: list>, networkProfileConfiguration: record<networkInterfaceConfigurations: list>, osProfile: record<adminPassword: string, adminUsername: string, allowExtensionOperations: bool, computerName: string, customData: string, linuxConfiguration: record, secrets: list, windowsConfiguration: record>, protectionPolicy: record<protectFromScaleIn: bool, protectFromScaleSetActions: bool>, provisioningState: string, storageProfile: record<dataDisks: list, imageReference: record, osDisk: record>, vmId: string>, resources: table<properties: record, id: string, location: string, name: string, tags: record, type: string>, sku: record<capacity: int, name: string, tier: string>, zones: list<string>, id: string, location: string, name: string, tags: record, type: string>"
    virtual-machine-scale-set-v-ms-get-instance-view: "record<bootDiagnostics: record<consoleScreenshotBlobUri: string, serialConsoleLogBlobUri: string, status: record<code: string, displayStatus: string, level: string, message: string, time: string>>, disks: table<encryptionSettings: list, name: string, statuses: list>, extensions: table<name: string, statuses: list, substatuses: list, type: string, typeHandlerVersion: string>, maintenanceRedeployStatus: record<isCustomerInitiatedMaintenanceAllowed: bool, lastOperationMessage: string, lastOperationResultCode: string, maintenanceWindowEndTime: string, maintenanceWindowStartTime: string, preMaintenanceWindowEndTime: string, preMaintenanceWindowStartTime: string>, placementGroupId: string, platformFaultDomain: int, platformUpdateDomain: int, rdpThumbPrint: string, statuses: table<code: string, displayStatus: string, level: string, message: string, time: string>, vmAgent: record<extensionHandlers: list<record>, statuses: list<record>, vmAgentVersion: string>, vmHealth: record<status: record<code: string, displayStatus: string, level: string, message: string, time: string>>>"
    virtual-machines-list: "record<nextLink: string, value: table<identity: record, plan: record, properties: record, resources: list, zones: list, id: string, location: string, name: string, tags: record, type: string>>"
    virtual-machines-get: "record<identity: record<principalId: string, tenantId: string, type: string, userAssignedIdentities: record>, plan: record<name: string, product: string, promotionCode: string, publisher: string>, properties: record<additionalCapabilities: record<ultraSSDEnabled: bool>, availabilitySet: record<id: string>, billingProfile: record<maxPrice: float>, diagnosticsProfile: record<bootDiagnostics: record>, evictionPolicy: string, hardwareProfile: record<vmSize: string>, host: record<id: string>, instanceView: record<bootDiagnostics: record, computerName: string, disks: list, extensions: list, hyperVGeneration: string, maintenanceRedeployStatus: record, osName: string, osVersion: string, platformFaultDomain: int, platformUpdateDomain: int, rdpThumbPrint: string, statuses: list, vmAgent: record>, licenseType: string, networkProfile: record<networkInterfaces: list>, osProfile: record<adminPassword: string, adminUsername: string, allowExtensionOperations: bool, computerName: string, customData: string, linuxConfiguration: record, secrets: list, windowsConfiguration: record>, priority: string, provisioningState: string, proximityPlacementGroup: record<id: string>, storageProfile: record<dataDisks: list, imageReference: record, osDisk: record>, virtualMachineScaleSet: record<id: string>, vmId: string>, resources: table<properties: record, id: string, location: string, name: string, tags: record, type: string>, zones: list<string>, id: string, location: string, name: string, tags: record, type: string>"
    virtual-machines-update: "record<identity: record<principalId: string, tenantId: string, type: string, userAssignedIdentities: record>, plan: record<name: string, product: string, promotionCode: string, publisher: string>, properties: record<additionalCapabilities: record<ultraSSDEnabled: bool>, availabilitySet: record<id: string>, billingProfile: record<maxPrice: float>, diagnosticsProfile: record<bootDiagnostics: record>, evictionPolicy: string, hardwareProfile: record<vmSize: string>, host: record<id: string>, instanceView: record<bootDiagnostics: record, computerName: string, disks: list, extensions: list, hyperVGeneration: string, maintenanceRedeployStatus: record, osName: string, osVersion: string, platformFaultDomain: int, platformUpdateDomain: int, rdpThumbPrint: string, statuses: list, vmAgent: record>, licenseType: string, networkProfile: record<networkInterfaces: list>, osProfile: record<adminPassword: string, adminUsername: string, allowExtensionOperations: bool, computerName: string, customData: string, linuxConfiguration: record, secrets: list, windowsConfiguration: record>, priority: string, provisioningState: string, proximityPlacementGroup: record<id: string>, storageProfile: record<dataDisks: list, imageReference: record, osDisk: record>, virtualMachineScaleSet: record<id: string>, vmId: string>, resources: table<properties: record, id: string, location: string, name: string, tags: record, type: string>, zones: list<string>, id: string, location: string, name: string, tags: record, type: string>"
    virtual-machines-create-or-update: "record<identity: record<principalId: string, tenantId: string, type: string, userAssignedIdentities: record>, plan: record<name: string, product: string, promotionCode: string, publisher: string>, properties: record<additionalCapabilities: record<ultraSSDEnabled: bool>, availabilitySet: record<id: string>, billingProfile: record<maxPrice: float>, diagnosticsProfile: record<bootDiagnostics: record>, evictionPolicy: string, hardwareProfile: record<vmSize: string>, host: record<id: string>, instanceView: record<bootDiagnostics: record, computerName: string, disks: list, extensions: list, hyperVGeneration: string, maintenanceRedeployStatus: record, osName: string, osVersion: string, platformFaultDomain: int, platformUpdateDomain: int, rdpThumbPrint: string, statuses: list, vmAgent: record>, licenseType: string, networkProfile: record<networkInterfaces: list>, osProfile: record<adminPassword: string, adminUsername: string, allowExtensionOperations: bool, computerName: string, customData: string, linuxConfiguration: record, secrets: list, windowsConfiguration: record>, priority: string, provisioningState: string, proximityPlacementGroup: record<id: string>, storageProfile: record<dataDisks: list, imageReference: record, osDisk: record>, virtualMachineScaleSet: record<id: string>, vmId: string>, resources: table<properties: record, id: string, location: string, name: string, tags: record, type: string>, zones: list<string>, id: string, location: string, name: string, tags: record, type: string>"
    virtual-machines-capture: "record<\"$schema\": string, contentVersion: string, parameters: record, resources: list<record>, id: string>"
    virtual-machine-extensions-list: "record<value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    virtual-machine-extensions-get: "record<properties: record<autoUpgradeMinorVersion: bool, forceUpdateTag: string, instanceView: record<name: string, statuses: list, substatuses: list, type: string, typeHandlerVersion: string>, protectedSettings: record, provisioningState: string, publisher: string, settings: record, type: string, typeHandlerVersion: string>, id: string, location: string, name: string, tags: record, type: string>"
    virtual-machine-extensions-update: "record<properties: record<autoUpgradeMinorVersion: bool, forceUpdateTag: string, instanceView: record<name: string, statuses: list, substatuses: list, type: string, typeHandlerVersion: string>, protectedSettings: record, provisioningState: string, publisher: string, settings: record, type: string, typeHandlerVersion: string>, id: string, location: string, name: string, tags: record, type: string>"
    virtual-machine-extensions-create-or-update: "record<properties: record<autoUpgradeMinorVersion: bool, forceUpdateTag: string, instanceView: record<name: string, statuses: list, substatuses: list, type: string, typeHandlerVersion: string>, protectedSettings: record, provisioningState: string, publisher: string, settings: record, type: string, typeHandlerVersion: string>, id: string, location: string, name: string, tags: record, type: string>"
    virtual-machines-instance-view: "record<bootDiagnostics: record<consoleScreenshotBlobUri: string, serialConsoleLogBlobUri: string, status: record<code: string, displayStatus: string, level: string, message: string, time: string>>, computerName: string, disks: table<encryptionSettings: list, name: string, statuses: list>, extensions: table<name: string, statuses: list, substatuses: list, type: string, typeHandlerVersion: string>, hyperVGeneration: string, maintenanceRedeployStatus: record<isCustomerInitiatedMaintenanceAllowed: bool, lastOperationMessage: string, lastOperationResultCode: string, maintenanceWindowEndTime: string, maintenanceWindowStartTime: string, preMaintenanceWindowEndTime: string, preMaintenanceWindowStartTime: string>, osName: string, osVersion: string, platformFaultDomain: int, platformUpdateDomain: int, rdpThumbPrint: string, statuses: table<code: string, displayStatus: string, level: string, message: string, time: string>, vmAgent: record<extensionHandlers: list<record>, statuses: list<record>, vmAgentVersion: string>>"
    virtual-machines-list-available-sizes: "record<value: table<maxDataDiskCount: int, memoryInMB: int, name: string, numberOfCores: int, osDiskSizeInMB: int, resourceDiskSizeInMB: int>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["operations-list" "availability-sets-list-by-subscription" "dedicated-host-groups-list-by-subscription" "images-list" "log-analytics-export-request-rate-by-interval" "log-analytics-export-throttled-requests" "virtual-machine-images-list-publishers" "virtual-machine-extension-images-list-types" "virtual-machine-extension-images-list-versions" "virtual-machine-extension-images-get" "virtual-machine-images-list-offers" "virtual-machine-images-list-skus" "virtual-machine-images-list" "virtual-machine-images-get" "usage-list" "virtual-machines-list-by-location" "virtual-machine-sizes-list" "proximity-placement-groups-list-by-subscription" "virtual-machine-scale-sets-list-all" "virtual-machines-list-all" "availability-sets-list" "availability-sets-delete" "availability-sets-get" "availability-sets-update" "availability-sets-create-or-update" "availability-sets-list-available-sizes" "dedicated-host-groups-list-by-resource-group" "dedicated-host-groups-delete" "dedicated-host-groups-get" "dedicated-host-groups-update" "dedicated-host-groups-create-or-update" "dedicated-hosts-list-by-host-group" "dedicated-hosts-delete" "dedicated-hosts-get" "dedicated-hosts-update" "dedicated-hosts-create-or-update" "images-list-by-resource-group" "images-delete" "images-get" "images-update" "images-create-or-update" "proximity-placement-groups-list-by-resource-group" "proximity-placement-groups-delete" "proximity-placement-groups-get" "proximity-placement-groups-update" "proximity-placement-groups-create-or-update" "virtual-machine-scale-sets-list" "virtual-machine-scale-set-v-ms-list" "virtual-machine-scale-sets-delete" "virtual-machine-scale-sets-get" "virtual-machine-scale-sets-update" "virtual-machine-scale-sets-create-or-update" "virtual-machine-scale-sets-convert-to-single-placement-group" "virtual-machine-scale-sets-deallocate" "virtual-machine-scale-sets-delete-instances" "virtual-machine-scale-set-rolling-upgrades-start-extension-upgrade" "virtual-machine-scale-set-extensions-list" "virtual-machine-scale-set-extensions-delete" "virtual-machine-scale-set-extensions-get" "virtual-machine-scale-set-extensions-create-or-update" "virtual-machine-scale-sets-force-recovery-service-fabric-platform-update-domain-walk" "virtual-machine-scale-sets-get-instance-view" "virtual-machine-scale-sets-update-instances" "virtual-machine-scale-set-rolling-upgrades-start-os-upgrade" "virtual-machine-scale-sets-get-os-upgrade-history" "virtual-machine-scale-sets-perform-maintenance" "virtual-machine-scale-sets-power-off" "virtual-machine-scale-sets-redeploy" "virtual-machine-scale-sets-reimage" "virtual-machine-scale-sets-reimage-all" "virtual-machine-scale-sets-restart" "virtual-machine-scale-set-rolling-upgrades-cancel" "virtual-machine-scale-set-rolling-upgrades-get-latest" "virtual-machine-scale-sets-list-skus" "virtual-machine-scale-sets-start" "virtual-machine-scale-set-v-ms-delete" "virtual-machine-scale-set-v-ms-get" "virtual-machine-scale-set-v-ms-update" "virtual-machine-scale-set-v-ms-deallocate" "virtual-machine-scale-set-v-ms-get-instance-view" "virtual-machine-scale-set-v-ms-perform-maintenance" "virtual-machine-scale-set-v-ms-power-off" "virtual-machine-scale-set-v-ms-redeploy" "virtual-machine-scale-set-v-ms-reimage" "virtual-machine-scale-set-v-ms-reimage-all" "virtual-machine-scale-set-v-ms-restart" "virtual-machine-scale-set-v-ms-start" "virtual-machines-list" "virtual-machines-delete" "virtual-machines-get" "virtual-machines-update" "virtual-machines-create-or-update" "virtual-machines-capture" "virtual-machines-convert-to-managed-disks" "virtual-machines-deallocate" "virtual-machine-extensions-list" "virtual-machine-extensions-delete" "virtual-machine-extensions-get" "virtual-machine-extensions-update" "virtual-machine-extensions-create-or-update" "virtual-machines-generalize" "virtual-machines-instance-view" "virtual-machines-perform-maintenance" "virtual-machines-power-off" "virtual-machines-redeploy" "virtual-machines-reimage" "virtual-machines-restart" "virtual-machines-start" "virtual-machines-list-available-sizes" "commands"] | sort) } | get name | first)
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

# Gets a list of compute operations.
#
# GET /providers/Microsoft.Compute/operations
# Returns: record<value: table<display: record, name: string, origin: string>>
# operationId: Operations_List
export def "operations-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Compute/operations"
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all availability sets in a subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Compute/availabilitySets
# Returns: record<nextLink: string, value: table<properties: record, sku: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: AvailabilitySets_ListBySubscription
export def "availability-sets-list-by-subscription" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --expand: string # The expand expression to apply to the operation.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.Compute/availabilitySets"
    path_params: [{name: subscriptionId, var: subscription_id}]
    query: [{name: api-version, var: api_version, required: true}, {name: "$expand", var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, api_version: $api_version, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all of the dedicated host groups in the subscription. Use the nextLink property in the response to get the next page of dedicated host groups.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Compute/hostGroups
# Returns: record<nextLink: string, value: table<properties: record, zones: list, id: string, location: string, name: string, tags: record, type: string>>
# operationId: DedicatedHostGroups_ListBySubscription
export def "dedicated-host-groups-list-by-subscription" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.Compute/hostGroups"
    path_params: [{name: subscriptionId, var: subscription_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the list of Images in the subscription. Use nextLink property in the response to get the next page of Images. Do this till nextLink is null to fetch all the Images.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Compute/images
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: Images_List
export def "images-list" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.Compute/images"
    path_params: [{name: subscriptionId, var: subscription_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Export logs that show Api requests made by this subscription in the given time window to show throttling activities.
#
# POST /subscriptions/{subscriptionId}/providers/Microsoft.Compute/locations/{location}/logAnalytics/apiAccess/getRequestRateByInterval
# Returns: record<properties: record<output: string>>
# operationId: LogAnalytics_ExportRequestRateByInterval
export def "log-analytics-export-request-rate-by-interval" [
  subscription_id: string
  location: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  interval_length: string@interval-length-completer # Interval value in minutes used to create LogAnalytics call rate logs.
  blob_container_sas_uri: string # SAS Uri of the logging blob container to which LogAnalytics Api writes output logs to.
  from_time: string # From time of the query (format: date-time)
  --group-by-operation-name: oneof<nothing, bool> # Group query result by Operation Name.
  --group-by-resource-name: oneof<nothing, bool> # Group query result by Resource Name.
  --group-by-throttle-policy: oneof<nothing, bool> # Group query result by Throttle Policy applied.
  to_time: string # To time of the query (format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.Compute/locations/{location}/logAnalytics/apiAccess/getRequestRateByInterval"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: location, var: location}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: intervalLength, var: interval_length}, {name: blobContainerSasUri, var: blob_container_sas_uri}, {name: fromTime, var: from_time}, {name: groupByOperationName, var: group_by_operation_name}, {name: groupByResourceName, var: group_by_resource_name}, {name: groupByThrottlePolicy, var: group_by_throttle_policy}, {name: toTime, var: to_time}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, location: $location, api_version: $api_version, interval_length: $interval_length, blob_container_sas_uri: $blob_container_sas_uri, from_time: $from_time, group_by_operation_name: $group_by_operation_name, group_by_resource_name: $group_by_resource_name, group_by_throttle_policy: $group_by_throttle_policy, to_time: $to_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Export logs that show total throttled Api requests for this subscription in the given time window.
#
# POST /subscriptions/{subscriptionId}/providers/Microsoft.Compute/locations/{location}/logAnalytics/apiAccess/getThrottledRequests
# Returns: record<properties: record<output: string>>
# operationId: LogAnalytics_ExportThrottledRequests
export def "log-analytics-export-throttled-requests" [
  subscription_id: string
  location: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  blob_container_sas_uri: string # SAS Uri of the logging blob container to which LogAnalytics Api writes output logs to.
  from_time: string # From time of the query (format: date-time)
  --group-by-operation-name: oneof<nothing, bool> # Group query result by Operation Name.
  --group-by-resource-name: oneof<nothing, bool> # Group query result by Resource Name.
  --group-by-throttle-policy: oneof<nothing, bool> # Group query result by Throttle Policy applied.
  to_time: string # To time of the query (format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.Compute/locations/{location}/logAnalytics/apiAccess/getThrottledRequests"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: location, var: location}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: blobContainerSasUri, var: blob_container_sas_uri}, {name: fromTime, var: from_time}, {name: groupByOperationName, var: group_by_operation_name}, {name: groupByResourceName, var: group_by_resource_name}, {name: groupByThrottlePolicy, var: group_by_throttle_policy}, {name: toTime, var: to_time}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, location: $location, api_version: $api_version, blob_container_sas_uri: $blob_container_sas_uri, from_time: $from_time, group_by_operation_name: $group_by_operation_name, group_by_resource_name: $group_by_resource_name, group_by_throttle_policy: $group_by_throttle_policy, to_time: $to_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of virtual machine image publishers for the specified Azure location.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Compute/locations/{location}/publishers
# Returns: table<location: string, name: string, tags: record, id: string>
# operationId: VirtualMachineImages_ListPublishers
export def "virtual-machine-images-list-publishers" [
  subscription_id: string
  location: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.Compute/locations/{location}/publishers"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: location, var: location}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, location: $location, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of virtual machine extension image types.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Compute/locations/{location}/publishers/{publisherName}/artifacttypes/vmextension/types
# Returns: table<properties: record<computeRole: string, handlerSchema: string, operatingSystem: string, supportsMultipleExtensions: bool, vmScaleSetEnabled: bool>, id: string, location: string, name: string, tags: record, type: string>
# operationId: VirtualMachineExtensionImages_ListTypes
export def "virtual-machine-extension-images-list-types" [
  subscription_id: string
  location: string
  publisher_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.Compute/locations/{location}/publishers/{publisherName}/artifacttypes/vmextension/types"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: location, var: location}, {name: publisherName, var: publisher_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, location: $location, publisher_name: $publisher_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of virtual machine extension image versions.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Compute/locations/{location}/publishers/{publisherName}/artifacttypes/vmextension/types/{type}/versions
# Returns: table<properties: record<computeRole: string, handlerSchema: string, operatingSystem: string, supportsMultipleExtensions: bool, vmScaleSetEnabled: bool>, id: string, location: string, name: string, tags: record, type: string>
# operationId: VirtualMachineExtensionImages_ListVersions
export def "virtual-machine-extension-images-list-versions" [
  subscription_id: string
  location: string
  publisher_name: string
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
  --filter: string # The filter to apply on the operation.
  --top: int # format: int32
  --orderby: string
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.Compute/locations/{location}/publishers/{publisherName}/artifacttypes/vmextension/types/{type}/versions"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: location, var: location}, {name: publisherName, var: publisher_name}, {name: type, var: type}]
    query: [{name: "$filter", var: filter}, {name: "$top", var: top}, {name: "$orderby", var: orderby}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, location: $location, publisher_name: $publisher_name, type: $type, filter: $filter, top: $top, orderby: $orderby, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a virtual machine extension image.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Compute/locations/{location}/publishers/{publisherName}/artifacttypes/vmextension/types/{type}/versions/{version}
# Returns: record<properties: record<computeRole: string, handlerSchema: string, operatingSystem: string, supportsMultipleExtensions: bool, vmScaleSetEnabled: bool>, id: string, location: string, name: string, tags: record, type: string>
# operationId: VirtualMachineExtensionImages_Get
export def "virtual-machine-extension-images-get" [
  subscription_id: string
  location: string
  publisher_name: string
  type: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.Compute/locations/{location}/publishers/{publisherName}/artifacttypes/vmextension/types/{type}/versions/{version}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: location, var: location}, {name: publisherName, var: publisher_name}, {name: type, var: type}, {name: version, var: version}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, location: $location, publisher_name: $publisher_name, type: $type, version: $version, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of virtual machine image offers for the specified location and publisher.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Compute/locations/{location}/publishers/{publisherName}/artifacttypes/vmimage/offers
# Returns: table<location: string, name: string, tags: record, id: string>
# operationId: VirtualMachineImages_ListOffers
export def "virtual-machine-images-list-offers" [
  subscription_id: string
  location: string
  publisher_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.Compute/locations/{location}/publishers/{publisherName}/artifacttypes/vmimage/offers"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: location, var: location}, {name: publisherName, var: publisher_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, location: $location, publisher_name: $publisher_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of virtual machine image SKUs for the specified location, publisher, and offer.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Compute/locations/{location}/publishers/{publisherName}/artifacttypes/vmimage/offers/{offer}/skus
# Returns: table<location: string, name: string, tags: record, id: string>
# operationId: VirtualMachineImages_ListSkus
export def "virtual-machine-images-list-skus" [
  subscription_id: string
  location: string
  publisher_name: string
  offer: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.Compute/locations/{location}/publishers/{publisherName}/artifacttypes/vmimage/offers/{offer}/skus"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: location, var: location}, {name: publisherName, var: publisher_name}, {name: offer, var: offer}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, location: $location, publisher_name: $publisher_name, offer: $offer, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of all virtual machine image versions for the specified location, publisher, offer, and SKU.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Compute/locations/{location}/publishers/{publisherName}/artifacttypes/vmimage/offers/{offer}/skus/{skus}/versions
# Returns: table<location: string, name: string, tags: record, id: string>
# operationId: VirtualMachineImages_List
export def "virtual-machine-images-list" [
  subscription_id: string
  location: string
  publisher_name: string
  offer: string
  skus: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # The filter to apply on the operation.
  --top: int # format: int32
  --orderby: string
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.Compute/locations/{location}/publishers/{publisherName}/artifacttypes/vmimage/offers/{offer}/skus/{skus}/versions"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: location, var: location}, {name: publisherName, var: publisher_name}, {name: offer, var: offer}, {name: skus, var: skus}]
    query: [{name: "$filter", var: filter}, {name: "$top", var: top}, {name: "$orderby", var: orderby}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, location: $location, publisher_name: $publisher_name, offer: $offer, skus: $skus, filter: $filter, top: $top, orderby: $orderby, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a virtual machine image.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Compute/locations/{location}/publishers/{publisherName}/artifacttypes/vmimage/offers/{offer}/skus/{skus}/versions/{version}
# Returns: record<properties: record<automaticOSUpgradeProperties: record<automaticOSUpgradeSupported: bool>, dataDiskImages: list<record>, hyperVGeneration: string, osDiskImage: record<operatingSystem: string>, plan: record<name: string, product: string, publisher: string>>, location: string, name: string, tags: record, id: string>
# operationId: VirtualMachineImages_Get
export def "virtual-machine-images-get" [
  subscription_id: string
  location: string
  publisher_name: string
  offer: string
  skus: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.Compute/locations/{location}/publishers/{publisherName}/artifacttypes/vmimage/offers/{offer}/skus/{skus}/versions/{version}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: location, var: location}, {name: publisherName, var: publisher_name}, {name: offer, var: offer}, {name: skus, var: skus}, {name: version, var: version}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, location: $location, publisher_name: $publisher_name, offer: $offer, skus: $skus, version: $version, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets, for the specified location, the current compute resource usage information as well as the limits for compute resources under the subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Compute/locations/{location}/usages
# Returns: record<nextLink: string, value: table<currentValue: int, limit: int, name: record, unit: string>>
# operationId: Usage_List
export def "usage-list" [
  subscription_id: string
  location: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.Compute/locations/{location}/usages"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: location, var: location}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, location: $location, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all the virtual machines under the specified subscription for the specified location.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Compute/locations/{location}/virtualMachines
# Returns: record<nextLink: string, value: table<identity: record, plan: record, properties: record, resources: list, zones: list, id: string, location: string, name: string, tags: record, type: string>>
# operationId: VirtualMachines_ListByLocation
export def "virtual-machines-list-by-location" [
  subscription_id: string
  location: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.Compute/locations/{location}/virtualMachines"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: location, var: location}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, location: $location, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API is deprecated. Use [Resources Skus](https://docs.microsoft.com/en-us/rest/api/compute/resourceskus/list)
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Compute/locations/{location}/vmSizes
# Returns: record<value: table<maxDataDiskCount: int, memoryInMB: int, name: string, numberOfCores: int, osDiskSizeInMB: int, resourceDiskSizeInMB: int>>
# operationId: VirtualMachineSizes_List
export def "virtual-machine-sizes-list" [
  subscription_id: string
  location: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.Compute/locations/{location}/vmSizes"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: location, var: location}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, location: $location, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all proximity placement groups in a subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Compute/proximityPlacementGroups
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: ProximityPlacementGroups_ListBySubscription
export def "proximity-placement-groups-list-by-subscription" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.Compute/proximityPlacementGroups"
    path_params: [{name: subscriptionId, var: subscription_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of all VM Scale Sets in the subscription, regardless of the associated resource group. Use nextLink property in the response to get the next page of VM Scale Sets. Do this till nextLink is null to fetch all the VM Scale Sets.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Compute/virtualMachineScaleSets
# Returns: record<nextLink: string, value: table<identity: record, plan: record, properties: record, sku: record, zones: list, id: string, location: string, name: string, tags: record, type: string>>
# operationId: VirtualMachineScaleSets_ListAll
export def "virtual-machine-scale-sets-list-all" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.Compute/virtualMachineScaleSets"
    path_params: [{name: subscriptionId, var: subscription_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all of the virtual machines in the specified subscription. Use the nextLink property in the response to get the next page of virtual machines.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Compute/virtualMachines
# Returns: record<nextLink: string, value: table<identity: record, plan: record, properties: record, resources: list, zones: list, id: string, location: string, name: string, tags: record, type: string>>
# operationId: VirtualMachines_ListAll
export def "virtual-machines-list-all" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.Compute/virtualMachines"
    path_params: [{name: subscriptionId, var: subscription_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all availability sets in a resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/availabilitySets
# Returns: record<nextLink: string, value: table<properties: record, sku: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: AvailabilitySets_List
export def "availability-sets-list" [
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
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/availabilitySets"
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

# Delete an availability set.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/availabilitySets/{availabilitySetName}
# operationId: AvailabilitySets_Delete
export def "availability-sets-delete" [
  subscription_id: string
  resource_group_name: string
  availability_set_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/availabilitySets/{availabilitySetName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: availabilitySetName, var: availability_set_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, availability_set_name: $availability_set_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about an availability set.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/availabilitySets/{availabilitySetName}
# Returns: record<properties: record<platformFaultDomainCount: int, platformUpdateDomainCount: int, proximityPlacementGroup: record<id: string>, statuses: list<record>, virtualMachines: list<record>>, sku: record<capacity: int, name: string, tier: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: AvailabilitySets_Get
export def "availability-sets-get" [
  subscription_id: string
  resource_group_name: string
  availability_set_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/availabilitySets/{availabilitySetName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: availabilitySetName, var: availability_set_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, availability_set_name: $availability_set_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an availability set.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/availabilitySets/{availabilitySetName}
# Returns: record<properties: record<platformFaultDomainCount: int, platformUpdateDomainCount: int, proximityPlacementGroup: record<id: string>, statuses: list<record>, virtualMachines: list<record>>, sku: record<capacity: int, name: string, tier: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: AvailabilitySets_Update
export def "availability-sets-update" [
  subscription_id: string
  resource_group_name: string
  availability_set_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --properties: any # The instance view of a resource. — shape: {platformFaultDomainCount?: int, platformUpdateDomainCount?: int, proximityPlacementGroup?: any, virtualMachines?: list}
  --sku: any # Describes a virtual machine scale set sku. — shape: {capacity?: int, name?: string, tier?: string}
  --tags: record # Resource tags
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/availabilitySets/{availabilitySetName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: availabilitySetName, var: availability_set_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: sku, var: sku}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, availability_set_name: $availability_set_name, api_version: $api_version, properties: $properties, sku: $sku, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create or update an availability set.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/availabilitySets/{availabilitySetName}
# Returns: record<properties: record<platformFaultDomainCount: int, platformUpdateDomainCount: int, proximityPlacementGroup: record<id: string>, statuses: list<record>, virtualMachines: list<record>>, sku: record<capacity: int, name: string, tier: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: AvailabilitySets_CreateOrUpdate
export def "availability-sets-create-or-update" [
  subscription_id: string
  resource_group_name: string
  availability_set_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --properties: any # The instance view of a resource. — shape: {platformFaultDomainCount?: int, platformUpdateDomainCount?: int, proximityPlacementGroup?: any, virtualMachines?: list}
  --sku: any # Describes a virtual machine scale set sku. — shape: {capacity?: int, name?: string, tier?: string}
  location: string # Resource location
  --tags: record # Resource tags
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/availabilitySets/{availabilitySetName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: availabilitySetName, var: availability_set_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: sku, var: sku}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, availability_set_name: $availability_set_name, api_version: $api_version, properties: $properties, sku: $sku, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all available virtual machine sizes that can be used to create a new virtual machine in an existing availability set.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/availabilitySets/{availabilitySetName}/vmSizes
# Returns: record<value: table<maxDataDiskCount: int, memoryInMB: int, name: string, numberOfCores: int, osDiskSizeInMB: int, resourceDiskSizeInMB: int>>
# operationId: AvailabilitySets_ListAvailableSizes
export def "availability-sets-list-available-sizes" [
  subscription_id: string
  resource_group_name: string
  availability_set_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/availabilitySets/{availabilitySetName}/vmSizes"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: availabilitySetName, var: availability_set_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, availability_set_name: $availability_set_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all of the dedicated host groups in the specified resource group. Use the nextLink property in the response to get the next page of dedicated host groups.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/hostGroups
# Returns: record<nextLink: string, value: table<properties: record, zones: list, id: string, location: string, name: string, tags: record, type: string>>
# operationId: DedicatedHostGroups_ListByResourceGroup
export def "dedicated-host-groups-list-by-resource-group" [
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
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/hostGroups"
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

# Delete a dedicated host group.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/hostGroups/{hostGroupName}
# operationId: DedicatedHostGroups_Delete
export def "dedicated-host-groups-delete" [
  subscription_id: string
  resource_group_name: string
  host_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/hostGroups/{hostGroupName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: hostGroupName, var: host_group_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, host_group_name: $host_group_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about a dedicated host group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/hostGroups/{hostGroupName}
# Returns: record<properties: record<hosts: list<record>, platformFaultDomainCount: int>, zones: list<string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: DedicatedHostGroups_Get
export def "dedicated-host-groups-get" [
  subscription_id: string
  resource_group_name: string
  host_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/hostGroups/{hostGroupName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: hostGroupName, var: host_group_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, host_group_name: $host_group_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an dedicated host group.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/hostGroups/{hostGroupName}
# Returns: record<properties: record<hosts: list<record>, platformFaultDomainCount: int>, zones: list<string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: DedicatedHostGroups_Update
export def "dedicated-host-groups-update" [
  subscription_id: string
  resource_group_name: string
  host_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --properties: any # Dedicated Host Group Properties. — shape: {platformFaultDomainCount: int}
  --zones: list<string> # Availability Zone to use for this host group. Only single zone is supported. The zone can be assigned only during creation. If not provided, the group supports all zones in the region. If provided, enforces each host in the group to be in the same zone.
  --tags: record # Resource tags
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/hostGroups/{hostGroupName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: hostGroupName, var: host_group_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: zones, var: zones}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, host_group_name: $host_group_name, api_version: $api_version, properties: $properties, zones: $zones, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create or update a dedicated host group. For details of Dedicated Host and Dedicated Host Groups please see [Dedicated Host Documentation] (https://go.microsoft.com/fwlink/?linkid=2082596)
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/hostGroups/{hostGroupName}
# Returns: record<properties: record<hosts: list<record>, platformFaultDomainCount: int>, zones: list<string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: DedicatedHostGroups_CreateOrUpdate
export def "dedicated-host-groups-create-or-update" [
  subscription_id: string
  resource_group_name: string
  host_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --properties: any # Dedicated Host Group Properties. — shape: {platformFaultDomainCount: int}
  --zones: list<string> # Availability Zone to use for this host group. Only single zone is supported. The zone can be assigned only during creation. If not provided, the group supports all zones in the region. If provided, enforces each host in the group to be in the same zone.
  location: string # Resource location
  --tags: record # Resource tags
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/hostGroups/{hostGroupName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: hostGroupName, var: host_group_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: zones, var: zones}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, host_group_name: $host_group_name, api_version: $api_version, properties: $properties, zones: $zones, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all of the dedicated hosts in the specified dedicated host group. Use the nextLink property in the response to get the next page of dedicated hosts.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/hostGroups/{hostGroupName}/hosts
# Returns: record<nextLink: string, value: table<properties: record, sku: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: DedicatedHosts_ListByHostGroup
export def "dedicated-hosts-list-by-host-group" [
  subscription_id: string
  resource_group_name: string
  host_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/hostGroups/{hostGroupName}/hosts"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: hostGroupName, var: host_group_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, host_group_name: $host_group_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a dedicated host.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/hostGroups/{hostGroupName}/hosts/{hostName}
# operationId: DedicatedHosts_Delete
export def "dedicated-hosts-delete" [
  subscription_id: string
  resource_group_name: string
  host_group_name: string
  host_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/hostGroups/{hostGroupName}/hosts/{hostName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: hostGroupName, var: host_group_name}, {name: hostName, var: host_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, host_group_name: $host_group_name, host_name: $host_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about a dedicated host.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/hostGroups/{hostGroupName}/hosts/{hostName}
# Returns: record<properties: record<autoReplaceOnFailure: bool, hostId: string, instanceView: record<assetId: string, availableCapacity: record, statuses: list>, licenseType: string, platformFaultDomain: int, provisioningState: string, provisioningTime: string, virtualMachines: list<record>>, sku: record<capacity: int, name: string, tier: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: DedicatedHosts_Get
export def "dedicated-hosts-get" [
  subscription_id: string
  resource_group_name: string
  host_group_name: string
  host_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string@expand-completer # The expand expression to apply on the operation.
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/hostGroups/{hostGroupName}/hosts/{hostName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: hostGroupName, var: host_group_name}, {name: hostName, var: host_name}]
    query: [{name: "$expand", var: expand}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, host_group_name: $host_group_name, host_name: $host_name, expand: $expand, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an dedicated host .
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/hostGroups/{hostGroupName}/hosts/{hostName}
# Returns: record<properties: record<autoReplaceOnFailure: bool, hostId: string, instanceView: record<assetId: string, availableCapacity: record, statuses: list>, licenseType: string, platformFaultDomain: int, provisioningState: string, provisioningTime: string, virtualMachines: list<record>>, sku: record<capacity: int, name: string, tier: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: DedicatedHosts_Update
export def "dedicated-hosts-update" [
  subscription_id: string
  resource_group_name: string
  host_group_name: string
  host_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --properties: any # Properties of the dedicated host. — shape: {autoReplaceOnFailure?: bool, instanceView?: any, licenseType?: "None"|"Windows_Server_Hybrid"|"Windows_Server_Perpetual", platformFaultDomain?: int}
  --tags: record # Resource tags
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/hostGroups/{hostGroupName}/hosts/{hostName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: hostGroupName, var: host_group_name}, {name: hostName, var: host_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, host_group_name: $host_group_name, host_name: $host_name, api_version: $api_version, properties: $properties, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create or update a dedicated host .
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/hostGroups/{hostGroupName}/hosts/{hostName}
# Returns: record<properties: record<autoReplaceOnFailure: bool, hostId: string, instanceView: record<assetId: string, availableCapacity: record, statuses: list>, licenseType: string, platformFaultDomain: int, provisioningState: string, provisioningTime: string, virtualMachines: list<record>>, sku: record<capacity: int, name: string, tier: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: DedicatedHosts_CreateOrUpdate
export def "dedicated-hosts-create-or-update" [
  subscription_id: string
  resource_group_name: string
  host_group_name: string
  host_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --properties: any # Properties of the dedicated host. — shape: {autoReplaceOnFailure?: bool, instanceView?: any, licenseType?: "None"|"Windows_Server_Hybrid"|"Windows_Server_Perpetual", platformFaultDomain?: int}
  sku: any # Describes a virtual machine scale set sku. — shape: {capacity?: int, name?: string, tier?: string}
  location: string # Resource location
  --tags: record # Resource tags
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/hostGroups/{hostGroupName}/hosts/{hostName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: hostGroupName, var: host_group_name}, {name: hostName, var: host_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: sku, var: sku}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, host_group_name: $host_group_name, host_name: $host_name, api_version: $api_version, properties: $properties, sku: $sku, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the list of images under a resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/images
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: Images_ListByResourceGroup
export def "images-list-by-resource-group" [
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
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/images"
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

# Deletes an Image.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/images/{imageName}
# operationId: Images_Delete
export def "images-delete" [
  subscription_id: string
  resource_group_name: string
  image_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/images/{imageName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: imageName, var: image_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, image_name: $image_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets an image.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/images/{imageName}
# Returns: record<properties: record<hyperVGeneration: string, provisioningState: string, sourceVirtualMachine: record<id: string>, storageProfile: record<dataDisks: list, osDisk: record, zoneResilient: bool>>, id: string, location: string, name: string, tags: record, type: string>
# operationId: Images_Get
export def "images-get" [
  subscription_id: string
  resource_group_name: string
  image_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # The expand expression to apply on the operation.
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/images/{imageName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: imageName, var: image_name}]
    query: [{name: "$expand", var: expand}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, image_name: $image_name, expand: $expand, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an image.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/images/{imageName}
# Returns: record<properties: record<hyperVGeneration: string, provisioningState: string, sourceVirtualMachine: record<id: string>, storageProfile: record<dataDisks: list, osDisk: record, zoneResilient: bool>>, id: string, location: string, name: string, tags: record, type: string>
# operationId: Images_Update
export def "images-update" [
  subscription_id: string
  resource_group_name: string
  image_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --properties: any # Describes the properties of an Image. — shape: {hyperVGeneration?: "V1"|"V2", sourceVirtualMachine?: any, storageProfile?: any}
  --tags: record # Resource tags
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/images/{imageName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: imageName, var: image_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, image_name: $image_name, api_version: $api_version, properties: $properties, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create or update an image.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/images/{imageName}
# Returns: record<properties: record<hyperVGeneration: string, provisioningState: string, sourceVirtualMachine: record<id: string>, storageProfile: record<dataDisks: list, osDisk: record, zoneResilient: bool>>, id: string, location: string, name: string, tags: record, type: string>
# operationId: Images_CreateOrUpdate
export def "images-create-or-update" [
  subscription_id: string
  resource_group_name: string
  image_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --properties: any # Describes the properties of an Image. — shape: {hyperVGeneration?: "V1"|"V2", sourceVirtualMachine?: any, storageProfile?: any}
  location: string # Resource location
  --tags: record # Resource tags
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/images/{imageName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: imageName, var: image_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, image_name: $image_name, api_version: $api_version, properties: $properties, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all proximity placement groups in a resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/proximityPlacementGroups
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: ProximityPlacementGroups_ListByResourceGroup
export def "proximity-placement-groups-list-by-resource-group" [
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
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/proximityPlacementGroups"
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

# Delete a proximity placement group.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/proximityPlacementGroups/{proximityPlacementGroupName}
# operationId: ProximityPlacementGroups_Delete
export def "proximity-placement-groups-delete" [
  subscription_id: string
  resource_group_name: string
  proximity_placement_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/proximityPlacementGroups/{proximityPlacementGroupName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: proximityPlacementGroupName, var: proximity_placement_group_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, proximity_placement_group_name: $proximity_placement_group_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about a proximity placement group .
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/proximityPlacementGroups/{proximityPlacementGroupName}
# Returns: record<properties: record<availabilitySets: list<record>, proximityPlacementGroupType: string, virtualMachineScaleSets: list<record>, virtualMachines: list<record>>, id: string, location: string, name: string, tags: record, type: string>
# operationId: ProximityPlacementGroups_Get
export def "proximity-placement-groups-get" [
  subscription_id: string
  resource_group_name: string
  proximity_placement_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/proximityPlacementGroups/{proximityPlacementGroupName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: proximityPlacementGroupName, var: proximity_placement_group_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, proximity_placement_group_name: $proximity_placement_group_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a proximity placement group.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/proximityPlacementGroups/{proximityPlacementGroupName}
# Returns: record<properties: record<availabilitySets: list<record>, proximityPlacementGroupType: string, virtualMachineScaleSets: list<record>, virtualMachines: list<record>>, id: string, location: string, name: string, tags: record, type: string>
# operationId: ProximityPlacementGroups_Update
export def "proximity-placement-groups-update" [
  subscription_id: string
  resource_group_name: string
  proximity_placement_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --tags: record # Resource tags
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/proximityPlacementGroups/{proximityPlacementGroupName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: proximityPlacementGroupName, var: proximity_placement_group_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, proximity_placement_group_name: $proximity_placement_group_name, api_version: $api_version, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create or update a proximity placement group.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/proximityPlacementGroups/{proximityPlacementGroupName}
# Returns: record<properties: record<availabilitySets: list<record>, proximityPlacementGroupType: string, virtualMachineScaleSets: list<record>, virtualMachines: list<record>>, id: string, location: string, name: string, tags: record, type: string>
# operationId: ProximityPlacementGroups_CreateOrUpdate
export def "proximity-placement-groups-create-or-update" [
  subscription_id: string
  resource_group_name: string
  proximity_placement_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --properties: any # Describes the properties of a Proximity Placement Group. — shape: {proximityPlacementGroupType?: "Standard"|"Ultra"}
  location: string # Resource location
  --tags: record # Resource tags
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/proximityPlacementGroups/{proximityPlacementGroupName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: proximityPlacementGroupName, var: proximity_placement_group_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, proximity_placement_group_name: $proximity_placement_group_name, api_version: $api_version, properties: $properties, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of all VM scale sets under a resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets
# Returns: record<nextLink: string, value: table<identity: record, plan: record, properties: record, sku: record, zones: list, id: string, location: string, name: string, tags: record, type: string>>
# operationId: VirtualMachineScaleSets_List
export def "virtual-machine-scale-sets-list" [
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
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets"
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

# Gets a list of all virtual machines in a VM scale sets.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{virtualMachineScaleSetName}/virtualMachines
# Returns: record<nextLink: string, value: table<instanceId: string, plan: record, properties: record, resources: list, sku: record, zones: list, id: string, location: string, name: string, tags: record, type: string>>
# operationId: VirtualMachineScaleSetVMs_List
export def "virtual-machine-scale-set-v-ms-list" [
  subscription_id: string
  resource_group_name: string
  virtual_machine_scale_set_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # The filter to apply to the operation.
  --select: string # The list parameters.
  --expand: string # The expand expression to apply to the operation.
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{virtualMachineScaleSetName}/virtualMachines"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: virtualMachineScaleSetName, var: virtual_machine_scale_set_name}]
    query: [{name: "$filter", var: filter}, {name: "$select", var: select}, {name: "$expand", var: expand}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_machine_scale_set_name: $virtual_machine_scale_set_name, filter: $filter, select: $select, expand: $expand, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a VM scale set.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}
# operationId: VirtualMachineScaleSets_Delete
export def "virtual-machine-scale-sets-delete" [
  subscription_id: string
  resource_group_name: string
  vm_scale_set_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vmScaleSetName, var: vm_scale_set_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vm_scale_set_name: $vm_scale_set_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Display information about a virtual machine scale set.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}
# Returns: record<identity: record<principalId: string, tenantId: string, type: string, userAssignedIdentities: record>, plan: record<name: string, product: string, promotionCode: string, publisher: string>, properties: record<additionalCapabilities: record<ultraSSDEnabled: bool>, doNotRunExtensionsOnOverprovisionedVMs: bool, overprovision: bool, platformFaultDomainCount: int, provisioningState: string, proximityPlacementGroup: record<id: string>, scaleInPolicy: record<rules: list>, singlePlacementGroup: bool, uniqueId: string, upgradePolicy: record<automaticOSUpgradePolicy: record, mode: string, rollingUpgradePolicy: record>, virtualMachineProfile: record<billingProfile: record, diagnosticsProfile: record, evictionPolicy: string, extensionProfile: record, licenseType: string, networkProfile: record, osProfile: record, priority: string, scheduledEventsProfile: record, storageProfile: record>, zoneBalance: bool>, sku: record<capacity: int, name: string, tier: string>, zones: list<string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: VirtualMachineScaleSets_Get
export def "virtual-machine-scale-sets-get" [
  subscription_id: string
  resource_group_name: string
  vm_scale_set_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vmScaleSetName, var: vm_scale_set_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vm_scale_set_name: $vm_scale_set_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a VM scale set.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}
# Returns: record<identity: record<principalId: string, tenantId: string, type: string, userAssignedIdentities: record>, plan: record<name: string, product: string, promotionCode: string, publisher: string>, properties: record<additionalCapabilities: record<ultraSSDEnabled: bool>, doNotRunExtensionsOnOverprovisionedVMs: bool, overprovision: bool, platformFaultDomainCount: int, provisioningState: string, proximityPlacementGroup: record<id: string>, scaleInPolicy: record<rules: list>, singlePlacementGroup: bool, uniqueId: string, upgradePolicy: record<automaticOSUpgradePolicy: record, mode: string, rollingUpgradePolicy: record>, virtualMachineProfile: record<billingProfile: record, diagnosticsProfile: record, evictionPolicy: string, extensionProfile: record, licenseType: string, networkProfile: record, osProfile: record, priority: string, scheduledEventsProfile: record, storageProfile: record>, zoneBalance: bool>, sku: record<capacity: int, name: string, tier: string>, zones: list<string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: VirtualMachineScaleSets_Update
export def "virtual-machine-scale-sets-update" [
  subscription_id: string
  resource_group_name: string
  vm_scale_set_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --identity: any # Identity for the virtual machine scale set. — shape: {type?: "SystemAssigned"|"UserAssigned"|"SystemAssigned, UserAssigned"|"None", userAssignedIdentities?: record}
  --plan: any # Specifies information about the marketplace image used to create the virtual machine. This element is only used for marketplace images. Before you can use a marketplace image from an API, you must enable the image for programmatic use. In the Azure portal, find the marketplace image that you want to use and then click **Want to deploy programmatically, Get Started ->**. Enter any required information and then click **Save**. — shape: {name?: string, product?: string, promotionCode?: string, publisher?: string}
  --properties: any # Describes the properties of a Virtual Machine Scale Set. — shape: {additionalCapabilities?: any, overprovision?: bool, scaleInPolicy?: any, singlePlacementGroup?: bool, upgradePolicy?: any, virtualMachineProfile?: any}
  --sku: any # Describes a virtual machine scale set sku. — shape: {capacity?: int, name?: string, tier?: string}
  --tags: record # Resource tags
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vmScaleSetName, var: vm_scale_set_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: identity, var: identity}, {name: plan, var: plan}, {name: properties, var: properties}, {name: sku, var: sku}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vm_scale_set_name: $vm_scale_set_name, api_version: $api_version, identity: $identity, plan: $plan, properties: $properties, sku: $sku, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create or update a VM scale set.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}
# Returns: record<identity: record<principalId: string, tenantId: string, type: string, userAssignedIdentities: record>, plan: record<name: string, product: string, promotionCode: string, publisher: string>, properties: record<additionalCapabilities: record<ultraSSDEnabled: bool>, doNotRunExtensionsOnOverprovisionedVMs: bool, overprovision: bool, platformFaultDomainCount: int, provisioningState: string, proximityPlacementGroup: record<id: string>, scaleInPolicy: record<rules: list>, singlePlacementGroup: bool, uniqueId: string, upgradePolicy: record<automaticOSUpgradePolicy: record, mode: string, rollingUpgradePolicy: record>, virtualMachineProfile: record<billingProfile: record, diagnosticsProfile: record, evictionPolicy: string, extensionProfile: record, licenseType: string, networkProfile: record, osProfile: record, priority: string, scheduledEventsProfile: record, storageProfile: record>, zoneBalance: bool>, sku: record<capacity: int, name: string, tier: string>, zones: list<string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: VirtualMachineScaleSets_CreateOrUpdate
export def "virtual-machine-scale-sets-create-or-update" [
  subscription_id: string
  resource_group_name: string
  vm_scale_set_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --identity: any # Identity for the virtual machine scale set. — shape: {type?: "SystemAssigned"|"UserAssigned"|"SystemAssigned, UserAssigned"|"None", userAssignedIdentities?: record}
  --plan: any # Specifies information about the marketplace image used to create the virtual machine. This element is only used for marketplace images. Before you can use a marketplace image from an API, you must enable the image for programmatic use. In the Azure portal, find the marketplace image that you want to use and then click **Want to deploy programmatically, Get Started ->**. Enter any required information and then click **Save**. — shape: {name?: string, product?: string, promotionCode?: string, publisher?: string}
  --properties: any # Describes the properties of a Virtual Machine Scale Set. — shape: {additionalCapabilities?: any, doNotRunExtensionsOnOverprovisionedVMs?: bool, overprovision?: bool, platformFaultDomainCount?: int, proximityPlacementGroup?: any, scaleInPolicy?: any, singlePlacementGroup?: bool, upgradePolicy?: any, virtualMachineProfile?: any, zoneBalance?: bool}
  --sku: any # Describes a virtual machine scale set sku. — shape: {capacity?: int, name?: string, tier?: string}
  --zones: list<string> # The virtual machine scale set zones.
  location: string # Resource location
  --tags: record # Resource tags
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vmScaleSetName, var: vm_scale_set_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: identity, var: identity}, {name: plan, var: plan}, {name: properties, var: properties}, {name: sku, var: sku}, {name: zones, var: zones}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vm_scale_set_name: $vm_scale_set_name, api_version: $api_version, identity: $identity, plan: $plan, properties: $properties, sku: $sku, zones: $zones, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Converts SinglePlacementGroup property to false for a existing virtual machine scale set.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}/convertToSinglePlacementGroup
# operationId: VirtualMachineScaleSets_ConvertToSinglePlacementGroup
export def "virtual-machine-scale-sets-convert-to-single-placement-group" [
  subscription_id: string
  resource_group_name: string
  vm_scale_set_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active-placement-group-id: string # Id of the placement group in which you want future virtual machine instances to be placed. To query placement group Id, please use Virtual Machine Scale Set VMs - Get API. If not provided, the platform will choose one with maximum number of virtual machine instances.
]: any -> any {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}/convertToSinglePlacementGroup"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vmScaleSetName, var: vm_scale_set_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: activePlacementGroupId, var: active_placement_group_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vm_scale_set_name: $vm_scale_set_name, active_placement_group_id: $active_placement_group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deallocates specific virtual machines in a VM scale set. Shuts down the virtual machines and releases the compute resources. You are not billed for the compute resources that this virtual machine scale set deallocates.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}/deallocate
# operationId: VirtualMachineScaleSets_Deallocate
export def "virtual-machine-scale-sets-deallocate" [
  subscription_id: string
  resource_group_name: string
  vm_scale_set_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --instance-ids: list<string> # The virtual machine scale set instance ids. Omitting the virtual machine scale set instance ids will result in the operation being performed on all virtual machines in the virtual machine scale set.
]: any -> any {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}/deallocate"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vmScaleSetName, var: vm_scale_set_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: instanceIds, var: instance_ids}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vm_scale_set_name: $vm_scale_set_name, api_version: $api_version, instance_ids: $instance_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes virtual machines in a VM scale set.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}/delete
# operationId: VirtualMachineScaleSets_DeleteInstances
export def "virtual-machine-scale-sets-delete-instances" [
  subscription_id: string
  resource_group_name: string
  vm_scale_set_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  instance_ids: list<string> # The virtual machine scale set instance ids.
]: any -> any {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}/delete"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vmScaleSetName, var: vm_scale_set_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: instanceIds, var: instance_ids}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vm_scale_set_name: $vm_scale_set_name, api_version: $api_version, instance_ids: $instance_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts a rolling upgrade to move all extensions for all virtual machine scale set instances to the latest available extension version. Instances which are already running the latest extension versions are not affected.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}/extensionRollingUpgrade
# operationId: VirtualMachineScaleSetRollingUpgrades_StartExtensionUpgrade
export def "virtual-machine-scale-set-rolling-upgrades-start-extension-upgrade" [
  subscription_id: string
  resource_group_name: string
  vm_scale_set_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}/extensionRollingUpgrade"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vmScaleSetName, var: vm_scale_set_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vm_scale_set_name: $vm_scale_set_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of all extensions in a VM scale set.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}/extensions
# Returns: record<nextLink: string, value: table<name: string, properties: record, id: string>>
# operationId: VirtualMachineScaleSetExtensions_List
export def "virtual-machine-scale-set-extensions-list" [
  subscription_id: string
  resource_group_name: string
  vm_scale_set_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}/extensions"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vmScaleSetName, var: vm_scale_set_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vm_scale_set_name: $vm_scale_set_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The operation to delete the extension.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}/extensions/{vmssExtensionName}
# operationId: VirtualMachineScaleSetExtensions_Delete
export def "virtual-machine-scale-set-extensions-delete" [
  subscription_id: string
  resource_group_name: string
  vm_scale_set_name: string
  vmss_extension_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}/extensions/{vmssExtensionName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vmScaleSetName, var: vm_scale_set_name}, {name: vmssExtensionName, var: vmss_extension_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vm_scale_set_name: $vm_scale_set_name, vmss_extension_name: $vmss_extension_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The operation to get the extension.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}/extensions/{vmssExtensionName}
# Returns: record<name: string, properties: record<autoUpgradeMinorVersion: bool, forceUpdateTag: string, protectedSettings: record, provisionAfterExtensions: list<string>, provisioningState: string, publisher: string, settings: record, type: string, typeHandlerVersion: string>, id: string>
# operationId: VirtualMachineScaleSetExtensions_Get
export def "virtual-machine-scale-set-extensions-get" [
  subscription_id: string
  resource_group_name: string
  vm_scale_set_name: string
  vmss_extension_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # The expand expression to apply on the operation.
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}/extensions/{vmssExtensionName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vmScaleSetName, var: vm_scale_set_name}, {name: vmssExtensionName, var: vmss_extension_name}]
    query: [{name: "$expand", var: expand}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vm_scale_set_name: $vm_scale_set_name, vmss_extension_name: $vmss_extension_name, expand: $expand, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The operation to create or update an extension.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}/extensions/{vmssExtensionName}
# Returns: record<name: string, properties: record<autoUpgradeMinorVersion: bool, forceUpdateTag: string, protectedSettings: record, provisionAfterExtensions: list<string>, provisioningState: string, publisher: string, settings: record, type: string, typeHandlerVersion: string>, id: string>
# operationId: VirtualMachineScaleSetExtensions_CreateOrUpdate
export def "virtual-machine-scale-set-extensions-create-or-update" [
  subscription_id: string
  resource_group_name: string
  vm_scale_set_name: string
  vmss_extension_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --name: string # The name of the extension.
  --properties: any # Describes the properties of a Virtual Machine Scale Set Extension. — shape: {autoUpgradeMinorVersion?: bool, forceUpdateTag?: string, protectedSettings?: record, provisionAfterExtensions?: list<string>, publisher?: string, settings?: record, type?: string, typeHandlerVersion?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}/extensions/{vmssExtensionName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vmScaleSetName, var: vm_scale_set_name}, {name: vmssExtensionName, var: vmss_extension_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vm_scale_set_name: $vm_scale_set_name, vmss_extension_name: $vmss_extension_name, api_version: $api_version, name: $name, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Manual platform update domain walk to update virtual machines in a service fabric virtual machine scale set.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}/forceRecoveryServiceFabricPlatformUpdateDomainWalk
# Returns: record<nextPlatformUpdateDomain: int, walkPerformed: bool>
# operationId: VirtualMachineScaleSets_ForceRecoveryServiceFabricPlatformUpdateDomainWalk
export def "virtual-machine-scale-sets-force-recovery-service-fabric-platform-update-domain-walk" [
  subscription_id: string
  resource_group_name: string
  vm_scale_set_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --platform-update-domain: int # The platform update domain for which a manual recovery walk is requested (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}/forceRecoveryServiceFabricPlatformUpdateDomainWalk"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vmScaleSetName, var: vm_scale_set_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: platformUpdateDomain, var: platform_update_domain, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vm_scale_set_name: $vm_scale_set_name, api_version: $api_version, platform_update_domain: $platform_update_domain
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the status of a VM scale set instance.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}/instanceView
# Returns: record<extensions: table<name: string, statusesSummary: list>, statuses: table<code: string, displayStatus: string, level: string, message: string, time: string>, virtualMachine: record<statusesSummary: list<record>>>
# operationId: VirtualMachineScaleSets_GetInstanceView
export def "virtual-machine-scale-sets-get-instance-view" [
  subscription_id: string
  resource_group_name: string
  vm_scale_set_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}/instanceView"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vmScaleSetName, var: vm_scale_set_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vm_scale_set_name: $vm_scale_set_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upgrades one or more virtual machines to the latest SKU set in the VM scale set model.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}/manualupgrade
# operationId: VirtualMachineScaleSets_UpdateInstances
export def "virtual-machine-scale-sets-update-instances" [
  subscription_id: string
  resource_group_name: string
  vm_scale_set_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  instance_ids: list<string> # The virtual machine scale set instance ids.
]: any -> any {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}/manualupgrade"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vmScaleSetName, var: vm_scale_set_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: instanceIds, var: instance_ids}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vm_scale_set_name: $vm_scale_set_name, api_version: $api_version, instance_ids: $instance_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts a rolling upgrade to move all virtual machine scale set instances to the latest available Platform Image OS version. Instances which are already running the latest available OS version are not affected.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}/osRollingUpgrade
# operationId: VirtualMachineScaleSetRollingUpgrades_StartOSUpgrade
export def "virtual-machine-scale-set-rolling-upgrades-start-os-upgrade" [
  subscription_id: string
  resource_group_name: string
  vm_scale_set_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}/osRollingUpgrade"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vmScaleSetName, var: vm_scale_set_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vm_scale_set_name: $vm_scale_set_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets list of OS upgrades on a VM scale set instance.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}/osUpgradeHistory
# Returns: record<nextLink: string, value: table<location: string, properties: record, type: string>>
# operationId: VirtualMachineScaleSets_GetOSUpgradeHistory
export def "virtual-machine-scale-sets-get-os-upgrade-history" [
  subscription_id: string
  resource_group_name: string
  vm_scale_set_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}/osUpgradeHistory"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vmScaleSetName, var: vm_scale_set_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vm_scale_set_name: $vm_scale_set_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Perform maintenance on one or more virtual machines in a VM scale set. Operation on instances which are not eligible for perform maintenance will be failed. Please refer to best practices for more details: https://docs.microsoft.com/en-us/azure/virtual-machine-scale-sets/virtual-machine-scale-sets-maintenance-notifications
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}/performMaintenance
# operationId: VirtualMachineScaleSets_PerformMaintenance
export def "virtual-machine-scale-sets-perform-maintenance" [
  subscription_id: string
  resource_group_name: string
  vm_scale_set_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --instance-ids: list<string> # The virtual machine scale set instance ids. Omitting the virtual machine scale set instance ids will result in the operation being performed on all virtual machines in the virtual machine scale set.
]: any -> any {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}/performMaintenance"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vmScaleSetName, var: vm_scale_set_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: instanceIds, var: instance_ids}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vm_scale_set_name: $vm_scale_set_name, api_version: $api_version, instance_ids: $instance_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Power off (stop) one or more virtual machines in a VM scale set. Note that resources are still attached and you are getting charged for the resources. Instead, use deallocate to release resources and avoid charges.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}/poweroff
# operationId: VirtualMachineScaleSets_PowerOff
export def "virtual-machine-scale-sets-power-off" [
  subscription_id: string
  resource_group_name: string
  vm_scale_set_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --skip-shutdown: oneof<nothing, bool> # The parameter to request non-graceful VM shutdown. True value for this flag indicates non-graceful shutdown whereas false indicates otherwise. Default value for this flag is false if not specified (default: false)
  --api-version: string # Client Api Version. (required)
  --instance-ids: list<string> # The virtual machine scale set instance ids. Omitting the virtual machine scale set instance ids will result in the operation being performed on all virtual machines in the virtual machine scale set.
]: any -> any {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}/poweroff"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vmScaleSetName, var: vm_scale_set_name}]
    query: [{name: skipShutdown, var: skip_shutdown}, {name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: instanceIds, var: instance_ids}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vm_scale_set_name: $vm_scale_set_name, skip_shutdown: $skip_shutdown, api_version: $api_version, instance_ids: $instance_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Shuts down all the virtual machines in the virtual machine scale set, moves them to a new node, and powers them back on.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}/redeploy
# operationId: VirtualMachineScaleSets_Redeploy
export def "virtual-machine-scale-sets-redeploy" [
  subscription_id: string
  resource_group_name: string
  vm_scale_set_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --instance-ids: list<string> # The virtual machine scale set instance ids. Omitting the virtual machine scale set instance ids will result in the operation being performed on all virtual machines in the virtual machine scale set.
]: any -> any {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}/redeploy"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vmScaleSetName, var: vm_scale_set_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: instanceIds, var: instance_ids}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vm_scale_set_name: $vm_scale_set_name, api_version: $api_version, instance_ids: $instance_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reimages (upgrade the operating system) one or more virtual machines in a VM scale set which don't have a ephemeral OS disk, for virtual machines who have a ephemeral OS disk the virtual machine is reset to initial state.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}/reimage
# operationId: VirtualMachineScaleSets_Reimage
export def "virtual-machine-scale-sets-reimage" [
  subscription_id: string
  resource_group_name: string
  vm_scale_set_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --instance-ids: list<string> # The virtual machine scale set instance ids. Omitting the virtual machine scale set instance ids will result in the operation being performed on all virtual machines in the virtual machine scale set.
  --temp-disk: oneof<nothing, bool> # Specifies whether to reimage temp disk. Default value: false. Note: This temp disk reimage parameter is only supported for VM/VMSS with Ephemeral OS disk.
]: any -> any {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}/reimage"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vmScaleSetName, var: vm_scale_set_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: instanceIds, var: instance_ids}, {name: tempDisk, var: temp_disk}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vm_scale_set_name: $vm_scale_set_name, api_version: $api_version, instance_ids: $instance_ids, temp_disk: $temp_disk
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reimages all the disks ( including data disks ) in the virtual machines in a VM scale set. This operation is only supported for managed disks.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}/reimageall
# operationId: VirtualMachineScaleSets_ReimageAll
export def "virtual-machine-scale-sets-reimage-all" [
  subscription_id: string
  resource_group_name: string
  vm_scale_set_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --instance-ids: list<string> # The virtual machine scale set instance ids. Omitting the virtual machine scale set instance ids will result in the operation being performed on all virtual machines in the virtual machine scale set.
]: any -> any {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}/reimageall"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vmScaleSetName, var: vm_scale_set_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: instanceIds, var: instance_ids}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vm_scale_set_name: $vm_scale_set_name, api_version: $api_version, instance_ids: $instance_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Restarts one or more virtual machines in a VM scale set.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}/restart
# operationId: VirtualMachineScaleSets_Restart
export def "virtual-machine-scale-sets-restart" [
  subscription_id: string
  resource_group_name: string
  vm_scale_set_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --instance-ids: list<string> # The virtual machine scale set instance ids. Omitting the virtual machine scale set instance ids will result in the operation being performed on all virtual machines in the virtual machine scale set.
]: any -> any {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}/restart"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vmScaleSetName, var: vm_scale_set_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: instanceIds, var: instance_ids}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vm_scale_set_name: $vm_scale_set_name, api_version: $api_version, instance_ids: $instance_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancels the current virtual machine scale set rolling upgrade.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}/rollingUpgrades/cancel
# operationId: VirtualMachineScaleSetRollingUpgrades_Cancel
export def "virtual-machine-scale-set-rolling-upgrades-cancel" [
  subscription_id: string
  resource_group_name: string
  vm_scale_set_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}/rollingUpgrades/cancel"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vmScaleSetName, var: vm_scale_set_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vm_scale_set_name: $vm_scale_set_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the status of the latest virtual machine scale set rolling upgrade.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}/rollingUpgrades/latest
# Returns: record<properties: record<error: record<code: string, details: list, innererror: record, message: string, target: string>, policy: record<maxBatchInstancePercent: int, maxUnhealthyInstancePercent: int, maxUnhealthyUpgradedInstancePercent: int, pauseTimeBetweenBatches: string>, progress: record<failedInstanceCount: int, inProgressInstanceCount: int, pendingInstanceCount: int, successfulInstanceCount: int>, runningStatus: record<code: string, lastAction: string, lastActionTime: string, startTime: string>>, id: string, location: string, name: string, tags: record, type: string>
# operationId: VirtualMachineScaleSetRollingUpgrades_GetLatest
export def "virtual-machine-scale-set-rolling-upgrades-get-latest" [
  subscription_id: string
  resource_group_name: string
  vm_scale_set_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}/rollingUpgrades/latest"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vmScaleSetName, var: vm_scale_set_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vm_scale_set_name: $vm_scale_set_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of SKUs available for your VM scale set, including the minimum and maximum VM instances allowed for each SKU.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}/skus
# Returns: record<nextLink: string, value: table<capacity: record, resourceType: string, sku: record>>
# operationId: VirtualMachineScaleSets_ListSkus
export def "virtual-machine-scale-sets-list-skus" [
  subscription_id: string
  resource_group_name: string
  vm_scale_set_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}/skus"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vmScaleSetName, var: vm_scale_set_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vm_scale_set_name: $vm_scale_set_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts one or more virtual machines in a VM scale set.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}/start
# operationId: VirtualMachineScaleSets_Start
export def "virtual-machine-scale-sets-start" [
  subscription_id: string
  resource_group_name: string
  vm_scale_set_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --instance-ids: list<string> # The virtual machine scale set instance ids. Omitting the virtual machine scale set instance ids will result in the operation being performed on all virtual machines in the virtual machine scale set.
]: any -> any {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}/start"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vmScaleSetName, var: vm_scale_set_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: instanceIds, var: instance_ids}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vm_scale_set_name: $vm_scale_set_name, api_version: $api_version, instance_ids: $instance_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a virtual machine from a VM scale set.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}/virtualmachines/{instanceId}
# operationId: VirtualMachineScaleSetVMs_Delete
export def "virtual-machine-scale-set-v-ms-delete" [
  subscription_id: string
  resource_group_name: string
  vm_scale_set_name: string
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}/virtualmachines/{instanceId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vmScaleSetName, var: vm_scale_set_name}, {name: instanceId, var: instance_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vm_scale_set_name: $vm_scale_set_name, instance_id: $instance_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a virtual machine from a VM scale set.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}/virtualmachines/{instanceId}
# Returns: record<instanceId: string, plan: record<name: string, product: string, promotionCode: string, publisher: string>, properties: record<additionalCapabilities: record<ultraSSDEnabled: bool>, availabilitySet: record<id: string>, diagnosticsProfile: record<bootDiagnostics: record>, hardwareProfile: record<vmSize: string>, instanceView: record<bootDiagnostics: record, disks: list, extensions: list, maintenanceRedeployStatus: record, placementGroupId: string, platformFaultDomain: int, platformUpdateDomain: int, rdpThumbPrint: string, statuses: list, vmAgent: record, vmHealth: record>, latestModelApplied: bool, licenseType: string, modelDefinitionApplied: string, networkProfile: record<networkInterfaces: list>, networkProfileConfiguration: record<networkInterfaceConfigurations: list>, osProfile: record<adminPassword: string, adminUsername: string, allowExtensionOperations: bool, computerName: string, customData: string, linuxConfiguration: record, secrets: list, windowsConfiguration: record>, protectionPolicy: record<protectFromScaleIn: bool, protectFromScaleSetActions: bool>, provisioningState: string, storageProfile: record<dataDisks: list, imageReference: record, osDisk: record>, vmId: string>, resources: table<properties: record, id: string, location: string, name: string, tags: record, type: string>, sku: record<capacity: int, name: string, tier: string>, zones: list<string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: VirtualMachineScaleSetVMs_Get
export def "virtual-machine-scale-set-v-ms-get" [
  subscription_id: string
  resource_group_name: string
  vm_scale_set_name: string
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string@expand-completer # The expand expression to apply on the operation.
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}/virtualmachines/{instanceId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vmScaleSetName, var: vm_scale_set_name}, {name: instanceId, var: instance_id}]
    query: [{name: "$expand", var: expand}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vm_scale_set_name: $vm_scale_set_name, instance_id: $instance_id, expand: $expand, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a virtual machine of a VM scale set.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}/virtualmachines/{instanceId}
# Returns: record<instanceId: string, plan: record<name: string, product: string, promotionCode: string, publisher: string>, properties: record<additionalCapabilities: record<ultraSSDEnabled: bool>, availabilitySet: record<id: string>, diagnosticsProfile: record<bootDiagnostics: record>, hardwareProfile: record<vmSize: string>, instanceView: record<bootDiagnostics: record, disks: list, extensions: list, maintenanceRedeployStatus: record, placementGroupId: string, platformFaultDomain: int, platformUpdateDomain: int, rdpThumbPrint: string, statuses: list, vmAgent: record, vmHealth: record>, latestModelApplied: bool, licenseType: string, modelDefinitionApplied: string, networkProfile: record<networkInterfaces: list>, networkProfileConfiguration: record<networkInterfaceConfigurations: list>, osProfile: record<adminPassword: string, adminUsername: string, allowExtensionOperations: bool, computerName: string, customData: string, linuxConfiguration: record, secrets: list, windowsConfiguration: record>, protectionPolicy: record<protectFromScaleIn: bool, protectFromScaleSetActions: bool>, provisioningState: string, storageProfile: record<dataDisks: list, imageReference: record, osDisk: record>, vmId: string>, resources: table<properties: record, id: string, location: string, name: string, tags: record, type: string>, sku: record<capacity: int, name: string, tier: string>, zones: list<string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: VirtualMachineScaleSetVMs_Update
export def "virtual-machine-scale-set-v-ms-update" [
  subscription_id: string
  resource_group_name: string
  vm_scale_set_name: string
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --plan: any # Specifies information about the marketplace image used to create the virtual machine. This element is only used for marketplace images. Before you can use a marketplace image from an API, you must enable the image for programmatic use. In the Azure portal, find the marketplace image that you want to use and then click **Want to deploy programmatically, Get Started ->**. Enter any required information and then click **Save**. — shape: {name?: string, product?: string, promotionCode?: string, publisher?: string}
  --properties: any # Describes the properties of a virtual machine scale set virtual machine. — shape: {additionalCapabilities?: any, availabilitySet?: any, diagnosticsProfile?: any, hardwareProfile?: any, instanceView?: any, licenseType?: string, networkProfile?: any, networkProfileConfiguration?: any, osProfile?: any, protectionPolicy?: any, storageProfile?: any}
  --sku: any # Describes a virtual machine scale set sku. — shape: {capacity?: int, name?: string, tier?: string}
  location: string # Resource location
  --tags: record # Resource tags
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}/virtualmachines/{instanceId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vmScaleSetName, var: vm_scale_set_name}, {name: instanceId, var: instance_id}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: plan, var: plan}, {name: properties, var: properties}, {name: sku, var: sku}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vm_scale_set_name: $vm_scale_set_name, instance_id: $instance_id, api_version: $api_version, plan: $plan, properties: $properties, sku: $sku, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deallocates a specific virtual machine in a VM scale set. Shuts down the virtual machine and releases the compute resources it uses. You are not billed for the compute resources of this virtual machine once it is deallocated.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}/virtualmachines/{instanceId}/deallocate
# operationId: VirtualMachineScaleSetVMs_Deallocate
export def "virtual-machine-scale-set-v-ms-deallocate" [
  subscription_id: string
  resource_group_name: string
  vm_scale_set_name: string
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}/virtualmachines/{instanceId}/deallocate"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vmScaleSetName, var: vm_scale_set_name}, {name: instanceId, var: instance_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vm_scale_set_name: $vm_scale_set_name, instance_id: $instance_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the status of a virtual machine from a VM scale set.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}/virtualmachines/{instanceId}/instanceView
# Returns: record<bootDiagnostics: record<consoleScreenshotBlobUri: string, serialConsoleLogBlobUri: string, status: record<code: string, displayStatus: string, level: string, message: string, time: string>>, disks: table<encryptionSettings: list, name: string, statuses: list>, extensions: table<name: string, statuses: list, substatuses: list, type: string, typeHandlerVersion: string>, maintenanceRedeployStatus: record<isCustomerInitiatedMaintenanceAllowed: bool, lastOperationMessage: string, lastOperationResultCode: string, maintenanceWindowEndTime: string, maintenanceWindowStartTime: string, preMaintenanceWindowEndTime: string, preMaintenanceWindowStartTime: string>, placementGroupId: string, platformFaultDomain: int, platformUpdateDomain: int, rdpThumbPrint: string, statuses: table<code: string, displayStatus: string, level: string, message: string, time: string>, vmAgent: record<extensionHandlers: list<record>, statuses: list<record>, vmAgentVersion: string>, vmHealth: record<status: record<code: string, displayStatus: string, level: string, message: string, time: string>>>
# operationId: VirtualMachineScaleSetVMs_GetInstanceView
export def "virtual-machine-scale-set-v-ms-get-instance-view" [
  subscription_id: string
  resource_group_name: string
  vm_scale_set_name: string
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}/virtualmachines/{instanceId}/instanceView"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vmScaleSetName, var: vm_scale_set_name}, {name: instanceId, var: instance_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vm_scale_set_name: $vm_scale_set_name, instance_id: $instance_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Performs maintenance on a virtual machine in a VM scale set.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}/virtualmachines/{instanceId}/performMaintenance
# operationId: VirtualMachineScaleSetVMs_PerformMaintenance
export def "virtual-machine-scale-set-v-ms-perform-maintenance" [
  subscription_id: string
  resource_group_name: string
  vm_scale_set_name: string
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}/virtualmachines/{instanceId}/performMaintenance"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vmScaleSetName, var: vm_scale_set_name}, {name: instanceId, var: instance_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vm_scale_set_name: $vm_scale_set_name, instance_id: $instance_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Power off (stop) a virtual machine in a VM scale set. Note that resources are still attached and you are getting charged for the resources. Instead, use deallocate to release resources and avoid charges.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}/virtualmachines/{instanceId}/poweroff
# operationId: VirtualMachineScaleSetVMs_PowerOff
export def "virtual-machine-scale-set-v-ms-power-off" [
  subscription_id: string
  resource_group_name: string
  vm_scale_set_name: string
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --skip-shutdown: oneof<nothing, bool> # The parameter to request non-graceful VM shutdown. True value for this flag indicates non-graceful shutdown whereas false indicates otherwise. Default value for this flag is false if not specified (default: false)
  --api-version: string # Client Api Version. (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}/virtualmachines/{instanceId}/poweroff"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vmScaleSetName, var: vm_scale_set_name}, {name: instanceId, var: instance_id}]
    query: [{name: skipShutdown, var: skip_shutdown}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vm_scale_set_name: $vm_scale_set_name, instance_id: $instance_id, skip_shutdown: $skip_shutdown, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Shuts down the virtual machine in the virtual machine scale set, moves it to a new node, and powers it back on.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}/virtualmachines/{instanceId}/redeploy
# operationId: VirtualMachineScaleSetVMs_Redeploy
export def "virtual-machine-scale-set-v-ms-redeploy" [
  subscription_id: string
  resource_group_name: string
  vm_scale_set_name: string
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}/virtualmachines/{instanceId}/redeploy"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vmScaleSetName, var: vm_scale_set_name}, {name: instanceId, var: instance_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vm_scale_set_name: $vm_scale_set_name, instance_id: $instance_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reimages (upgrade the operating system) a specific virtual machine in a VM scale set.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}/virtualmachines/{instanceId}/reimage
# operationId: VirtualMachineScaleSetVMs_Reimage
export def "virtual-machine-scale-set-v-ms-reimage" [
  subscription_id: string
  resource_group_name: string
  vm_scale_set_name: string
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --temp-disk: oneof<nothing, bool> # Specifies whether to reimage temp disk. Default value: false. Note: This temp disk reimage parameter is only supported for VM/VMSS with Ephemeral OS disk.
]: any -> any {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}/virtualmachines/{instanceId}/reimage"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vmScaleSetName, var: vm_scale_set_name}, {name: instanceId, var: instance_id}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: tempDisk, var: temp_disk}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vm_scale_set_name: $vm_scale_set_name, instance_id: $instance_id, api_version: $api_version, temp_disk: $temp_disk
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Allows you to re-image all the disks ( including data disks ) in the a VM scale set instance. This operation is only supported for managed disks.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}/virtualmachines/{instanceId}/reimageall
# operationId: VirtualMachineScaleSetVMs_ReimageAll
export def "virtual-machine-scale-set-v-ms-reimage-all" [
  subscription_id: string
  resource_group_name: string
  vm_scale_set_name: string
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}/virtualmachines/{instanceId}/reimageall"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vmScaleSetName, var: vm_scale_set_name}, {name: instanceId, var: instance_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vm_scale_set_name: $vm_scale_set_name, instance_id: $instance_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Restarts a virtual machine in a VM scale set.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}/virtualmachines/{instanceId}/restart
# operationId: VirtualMachineScaleSetVMs_Restart
export def "virtual-machine-scale-set-v-ms-restart" [
  subscription_id: string
  resource_group_name: string
  vm_scale_set_name: string
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}/virtualmachines/{instanceId}/restart"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vmScaleSetName, var: vm_scale_set_name}, {name: instanceId, var: instance_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vm_scale_set_name: $vm_scale_set_name, instance_id: $instance_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts a virtual machine in a VM scale set.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}/virtualmachines/{instanceId}/start
# operationId: VirtualMachineScaleSetVMs_Start
export def "virtual-machine-scale-set-v-ms-start" [
  subscription_id: string
  resource_group_name: string
  vm_scale_set_name: string
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{vmScaleSetName}/virtualmachines/{instanceId}/start"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vmScaleSetName, var: vm_scale_set_name}, {name: instanceId, var: instance_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vm_scale_set_name: $vm_scale_set_name, instance_id: $instance_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all of the virtual machines in the specified resource group. Use the nextLink property in the response to get the next page of virtual machines.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachines
# Returns: record<nextLink: string, value: table<identity: record, plan: record, properties: record, resources: list, zones: list, id: string, location: string, name: string, tags: record, type: string>>
# operationId: VirtualMachines_List
export def "virtual-machines-list" [
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
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachines"
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

# The operation to delete a virtual machine.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachines/{vmName}
# operationId: VirtualMachines_Delete
export def "virtual-machines-delete" [
  subscription_id: string
  resource_group_name: string
  vm_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachines/{vmName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vmName, var: vm_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vm_name: $vm_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about the model view or the instance view of a virtual machine.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachines/{vmName}
# Returns: record<identity: record<principalId: string, tenantId: string, type: string, userAssignedIdentities: record>, plan: record<name: string, product: string, promotionCode: string, publisher: string>, properties: record<additionalCapabilities: record<ultraSSDEnabled: bool>, availabilitySet: record<id: string>, billingProfile: record<maxPrice: float>, diagnosticsProfile: record<bootDiagnostics: record>, evictionPolicy: string, hardwareProfile: record<vmSize: string>, host: record<id: string>, instanceView: record<bootDiagnostics: record, computerName: string, disks: list, extensions: list, hyperVGeneration: string, maintenanceRedeployStatus: record, osName: string, osVersion: string, platformFaultDomain: int, platformUpdateDomain: int, rdpThumbPrint: string, statuses: list, vmAgent: record>, licenseType: string, networkProfile: record<networkInterfaces: list>, osProfile: record<adminPassword: string, adminUsername: string, allowExtensionOperations: bool, computerName: string, customData: string, linuxConfiguration: record, secrets: list, windowsConfiguration: record>, priority: string, provisioningState: string, proximityPlacementGroup: record<id: string>, storageProfile: record<dataDisks: list, imageReference: record, osDisk: record>, virtualMachineScaleSet: record<id: string>, vmId: string>, resources: table<properties: record, id: string, location: string, name: string, tags: record, type: string>, zones: list<string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: VirtualMachines_Get
export def "virtual-machines-get" [
  subscription_id: string
  resource_group_name: string
  vm_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string@expand-completer # The expand expression to apply on the operation.
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachines/{vmName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vmName, var: vm_name}]
    query: [{name: "$expand", var: expand}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vm_name: $vm_name, expand: $expand, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The operation to update a virtual machine.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachines/{vmName}
# Returns: record<identity: record<principalId: string, tenantId: string, type: string, userAssignedIdentities: record>, plan: record<name: string, product: string, promotionCode: string, publisher: string>, properties: record<additionalCapabilities: record<ultraSSDEnabled: bool>, availabilitySet: record<id: string>, billingProfile: record<maxPrice: float>, diagnosticsProfile: record<bootDiagnostics: record>, evictionPolicy: string, hardwareProfile: record<vmSize: string>, host: record<id: string>, instanceView: record<bootDiagnostics: record, computerName: string, disks: list, extensions: list, hyperVGeneration: string, maintenanceRedeployStatus: record, osName: string, osVersion: string, platformFaultDomain: int, platformUpdateDomain: int, rdpThumbPrint: string, statuses: list, vmAgent: record>, licenseType: string, networkProfile: record<networkInterfaces: list>, osProfile: record<adminPassword: string, adminUsername: string, allowExtensionOperations: bool, computerName: string, customData: string, linuxConfiguration: record, secrets: list, windowsConfiguration: record>, priority: string, provisioningState: string, proximityPlacementGroup: record<id: string>, storageProfile: record<dataDisks: list, imageReference: record, osDisk: record>, virtualMachineScaleSet: record<id: string>, vmId: string>, resources: table<properties: record, id: string, location: string, name: string, tags: record, type: string>, zones: list<string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: VirtualMachines_Update
export def "virtual-machines-update" [
  subscription_id: string
  resource_group_name: string
  vm_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --identity: any # Identity for the virtual machine. — shape: {type?: "SystemAssigned"|"UserAssigned"|"SystemAssigned, UserAssigned"|"None", userAssignedIdentities?: record}
  --plan: any # Specifies information about the marketplace image used to create the virtual machine. This element is only used for marketplace images. Before you can use a marketplace image from an API, you must enable the image for programmatic use. In the Azure portal, find the marketplace image that you want to use and then click **Want to deploy programmatically, Get Started ->**. Enter any required information and then click **Save**. — shape: {name?: string, product?: string, promotionCode?: string, publisher?: string}
  --properties: any # Describes the properties of a Virtual Machine. — shape: {additionalCapabilities?: any, availabilitySet?: any, billingProfile?: any, diagnosticsProfile?: any, evictionPolicy?: "Deallocate"|"Delete", hardwareProfile?: any, host?: any, instanceView?: any, licenseType?: string, networkProfile?: any, osProfile?: any, priority?: "Regular"|"Low", proximityPlacementGroup?: any, storageProfile?: any, virtualMachineScaleSet?: any}
  --zones: list<string> # The virtual machine zones.
  --tags: record # Resource tags
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachines/{vmName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vmName, var: vm_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: identity, var: identity}, {name: plan, var: plan}, {name: properties, var: properties}, {name: zones, var: zones}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vm_name: $vm_name, api_version: $api_version, identity: $identity, plan: $plan, properties: $properties, zones: $zones, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The operation to create or update a virtual machine.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachines/{vmName}
# Returns: record<identity: record<principalId: string, tenantId: string, type: string, userAssignedIdentities: record>, plan: record<name: string, product: string, promotionCode: string, publisher: string>, properties: record<additionalCapabilities: record<ultraSSDEnabled: bool>, availabilitySet: record<id: string>, billingProfile: record<maxPrice: float>, diagnosticsProfile: record<bootDiagnostics: record>, evictionPolicy: string, hardwareProfile: record<vmSize: string>, host: record<id: string>, instanceView: record<bootDiagnostics: record, computerName: string, disks: list, extensions: list, hyperVGeneration: string, maintenanceRedeployStatus: record, osName: string, osVersion: string, platformFaultDomain: int, platformUpdateDomain: int, rdpThumbPrint: string, statuses: list, vmAgent: record>, licenseType: string, networkProfile: record<networkInterfaces: list>, osProfile: record<adminPassword: string, adminUsername: string, allowExtensionOperations: bool, computerName: string, customData: string, linuxConfiguration: record, secrets: list, windowsConfiguration: record>, priority: string, provisioningState: string, proximityPlacementGroup: record<id: string>, storageProfile: record<dataDisks: list, imageReference: record, osDisk: record>, virtualMachineScaleSet: record<id: string>, vmId: string>, resources: table<properties: record, id: string, location: string, name: string, tags: record, type: string>, zones: list<string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: VirtualMachines_CreateOrUpdate
export def "virtual-machines-create-or-update" [
  subscription_id: string
  resource_group_name: string
  vm_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --identity: any # Identity for the virtual machine. — shape: {type?: "SystemAssigned"|"UserAssigned"|"SystemAssigned, UserAssigned"|"None", userAssignedIdentities?: record}
  --plan: any # Specifies information about the marketplace image used to create the virtual machine. This element is only used for marketplace images. Before you can use a marketplace image from an API, you must enable the image for programmatic use. In the Azure portal, find the marketplace image that you want to use and then click **Want to deploy programmatically, Get Started ->**. Enter any required information and then click **Save**. — shape: {name?: string, product?: string, promotionCode?: string, publisher?: string}
  --properties: any # Describes the properties of a Virtual Machine. — shape: {additionalCapabilities?: any, availabilitySet?: any, billingProfile?: any, diagnosticsProfile?: any, evictionPolicy?: "Deallocate"|"Delete", hardwareProfile?: any, host?: any, instanceView?: any, licenseType?: string, networkProfile?: any, osProfile?: any, priority?: "Regular"|"Low", proximityPlacementGroup?: any, storageProfile?: any, virtualMachineScaleSet?: any}
  --zones: list<string> # The virtual machine zones.
  location: string # Resource location
  --tags: record # Resource tags
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachines/{vmName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vmName, var: vm_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: identity, var: identity}, {name: plan, var: plan}, {name: properties, var: properties}, {name: zones, var: zones}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vm_name: $vm_name, api_version: $api_version, identity: $identity, plan: $plan, properties: $properties, zones: $zones, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Captures the VM by copying virtual hard disks of the VM and outputs a template that can be used to create similar VMs.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachines/{vmName}/capture
# Returns: record<"$schema": string, contentVersion: string, parameters: record, resources: list<record>, id: string>
# operationId: VirtualMachines_Capture
export def "virtual-machines-capture" [
  subscription_id: string
  resource_group_name: string
  vm_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  destination_container_name: string # The destination container name.
  --overwrite-vhds: oneof<nothing, bool> # Specifies whether to overwrite the destination virtual hard disk, in case of conflict.
  vhd_prefix: string # The captured virtual hard disk's name prefix.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachines/{vmName}/capture"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vmName, var: vm_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: destinationContainerName, var: destination_container_name}, {name: overwriteVhds, var: overwrite_vhds, required: true}, {name: vhdPrefix, var: vhd_prefix}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vm_name: $vm_name, api_version: $api_version, destination_container_name: $destination_container_name, overwrite_vhds: $overwrite_vhds, vhd_prefix: $vhd_prefix
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Converts virtual machine disks from blob-based to managed disks. Virtual machine must be stop-deallocated before invoking this operation.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachines/{vmName}/convertToManagedDisks
# operationId: VirtualMachines_ConvertToManagedDisks
export def "virtual-machines-convert-to-managed-disks" [
  subscription_id: string
  resource_group_name: string
  vm_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachines/{vmName}/convertToManagedDisks"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vmName, var: vm_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vm_name: $vm_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Shuts down the virtual machine and releases the compute resources. You are not billed for the compute resources that this virtual machine uses.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachines/{vmName}/deallocate
# operationId: VirtualMachines_Deallocate
export def "virtual-machines-deallocate" [
  subscription_id: string
  resource_group_name: string
  vm_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachines/{vmName}/deallocate"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vmName, var: vm_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vm_name: $vm_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The operation to get all extensions of a Virtual Machine.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachines/{vmName}/extensions
# Returns: record<value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: VirtualMachineExtensions_List
export def "virtual-machine-extensions-list" [
  subscription_id: string
  resource_group_name: string
  vm_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # The expand expression to apply on the operation.
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachines/{vmName}/extensions"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vmName, var: vm_name}]
    query: [{name: "$expand", var: expand}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vm_name: $vm_name, expand: $expand, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The operation to delete the extension.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachines/{vmName}/extensions/{vmExtensionName}
# operationId: VirtualMachineExtensions_Delete
export def "virtual-machine-extensions-delete" [
  subscription_id: string
  resource_group_name: string
  vm_name: string
  vm_extension_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachines/{vmName}/extensions/{vmExtensionName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vmName, var: vm_name}, {name: vmExtensionName, var: vm_extension_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vm_name: $vm_name, vm_extension_name: $vm_extension_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The operation to get the extension.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachines/{vmName}/extensions/{vmExtensionName}
# Returns: record<properties: record<autoUpgradeMinorVersion: bool, forceUpdateTag: string, instanceView: record<name: string, statuses: list, substatuses: list, type: string, typeHandlerVersion: string>, protectedSettings: record, provisioningState: string, publisher: string, settings: record, type: string, typeHandlerVersion: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: VirtualMachineExtensions_Get
export def "virtual-machine-extensions-get" [
  subscription_id: string
  resource_group_name: string
  vm_name: string
  vm_extension_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # The expand expression to apply on the operation.
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachines/{vmName}/extensions/{vmExtensionName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vmName, var: vm_name}, {name: vmExtensionName, var: vm_extension_name}]
    query: [{name: "$expand", var: expand}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vm_name: $vm_name, vm_extension_name: $vm_extension_name, expand: $expand, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The operation to update the extension.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachines/{vmName}/extensions/{vmExtensionName}
# Returns: record<properties: record<autoUpgradeMinorVersion: bool, forceUpdateTag: string, instanceView: record<name: string, statuses: list, substatuses: list, type: string, typeHandlerVersion: string>, protectedSettings: record, provisioningState: string, publisher: string, settings: record, type: string, typeHandlerVersion: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: VirtualMachineExtensions_Update
export def "virtual-machine-extensions-update" [
  subscription_id: string
  resource_group_name: string
  vm_name: string
  vm_extension_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --properties: any # Describes the properties of a Virtual Machine Extension. — shape: {autoUpgradeMinorVersion?: bool, forceUpdateTag?: string, protectedSettings?: record, publisher?: string, settings?: record, type?: string, typeHandlerVersion?: string}
  --tags: record # Resource tags
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachines/{vmName}/extensions/{vmExtensionName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vmName, var: vm_name}, {name: vmExtensionName, var: vm_extension_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vm_name: $vm_name, vm_extension_name: $vm_extension_name, api_version: $api_version, properties: $properties, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The operation to create or update the extension.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachines/{vmName}/extensions/{vmExtensionName}
# Returns: record<properties: record<autoUpgradeMinorVersion: bool, forceUpdateTag: string, instanceView: record<name: string, statuses: list, substatuses: list, type: string, typeHandlerVersion: string>, protectedSettings: record, provisioningState: string, publisher: string, settings: record, type: string, typeHandlerVersion: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: VirtualMachineExtensions_CreateOrUpdate
export def "virtual-machine-extensions-create-or-update" [
  subscription_id: string
  resource_group_name: string
  vm_name: string
  vm_extension_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --properties: any # Describes the properties of a Virtual Machine Extension. — shape: {autoUpgradeMinorVersion?: bool, forceUpdateTag?: string, instanceView?: any, protectedSettings?: record, publisher?: string, settings?: record, type?: string, typeHandlerVersion?: string}
  location: string # Resource location
  --tags: record # Resource tags
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachines/{vmName}/extensions/{vmExtensionName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vmName, var: vm_name}, {name: vmExtensionName, var: vm_extension_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vm_name: $vm_name, vm_extension_name: $vm_extension_name, api_version: $api_version, properties: $properties, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the state of the virtual machine to generalized.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachines/{vmName}/generalize
# operationId: VirtualMachines_Generalize
export def "virtual-machines-generalize" [
  subscription_id: string
  resource_group_name: string
  vm_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachines/{vmName}/generalize"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vmName, var: vm_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vm_name: $vm_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about the run-time state of a virtual machine.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachines/{vmName}/instanceView
# Returns: record<bootDiagnostics: record<consoleScreenshotBlobUri: string, serialConsoleLogBlobUri: string, status: record<code: string, displayStatus: string, level: string, message: string, time: string>>, computerName: string, disks: table<encryptionSettings: list, name: string, statuses: list>, extensions: table<name: string, statuses: list, substatuses: list, type: string, typeHandlerVersion: string>, hyperVGeneration: string, maintenanceRedeployStatus: record<isCustomerInitiatedMaintenanceAllowed: bool, lastOperationMessage: string, lastOperationResultCode: string, maintenanceWindowEndTime: string, maintenanceWindowStartTime: string, preMaintenanceWindowEndTime: string, preMaintenanceWindowStartTime: string>, osName: string, osVersion: string, platformFaultDomain: int, platformUpdateDomain: int, rdpThumbPrint: string, statuses: table<code: string, displayStatus: string, level: string, message: string, time: string>, vmAgent: record<extensionHandlers: list<record>, statuses: list<record>, vmAgentVersion: string>>
# operationId: VirtualMachines_InstanceView
export def "virtual-machines-instance-view" [
  subscription_id: string
  resource_group_name: string
  vm_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachines/{vmName}/instanceView"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vmName, var: vm_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vm_name: $vm_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The operation to perform maintenance on a virtual machine.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachines/{vmName}/performMaintenance
# operationId: VirtualMachines_PerformMaintenance
export def "virtual-machines-perform-maintenance" [
  subscription_id: string
  resource_group_name: string
  vm_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachines/{vmName}/performMaintenance"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vmName, var: vm_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vm_name: $vm_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The operation to power off (stop) a virtual machine. The virtual machine can be restarted with the same provisioned resources. You are still charged for this virtual machine.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachines/{vmName}/powerOff
# operationId: VirtualMachines_PowerOff
export def "virtual-machines-power-off" [
  subscription_id: string
  resource_group_name: string
  vm_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --skip-shutdown: oneof<nothing, bool> # The parameter to request non-graceful VM shutdown. True value for this flag indicates non-graceful shutdown whereas false indicates otherwise. Default value for this flag is false if not specified (default: false)
  --api-version: string # Client Api Version. (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachines/{vmName}/powerOff"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vmName, var: vm_name}]
    query: [{name: skipShutdown, var: skip_shutdown}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vm_name: $vm_name, skip_shutdown: $skip_shutdown, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Shuts down the virtual machine, moves it to a new node, and powers it back on.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachines/{vmName}/redeploy
# operationId: VirtualMachines_Redeploy
export def "virtual-machines-redeploy" [
  subscription_id: string
  resource_group_name: string
  vm_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachines/{vmName}/redeploy"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vmName, var: vm_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vm_name: $vm_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reimages the virtual machine which has an ephemeral OS disk back to its initial state.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachines/{vmName}/reimage
# operationId: VirtualMachines_Reimage
export def "virtual-machines-reimage" [
  subscription_id: string
  resource_group_name: string
  vm_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --temp-disk: oneof<nothing, bool> # Specifies whether to reimage temp disk. Default value: false. Note: This temp disk reimage parameter is only supported for VM/VMSS with Ephemeral OS disk.
]: any -> any {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachines/{vmName}/reimage"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vmName, var: vm_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: tempDisk, var: temp_disk}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vm_name: $vm_name, api_version: $api_version, temp_disk: $temp_disk
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The operation to restart a virtual machine.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachines/{vmName}/restart
# operationId: VirtualMachines_Restart
export def "virtual-machines-restart" [
  subscription_id: string
  resource_group_name: string
  vm_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachines/{vmName}/restart"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vmName, var: vm_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vm_name: $vm_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The operation to start a virtual machine.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachines/{vmName}/start
# operationId: VirtualMachines_Start
export def "virtual-machines-start" [
  subscription_id: string
  resource_group_name: string
  vm_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachines/{vmName}/start"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vmName, var: vm_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vm_name: $vm_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all available virtual machine sizes to which the specified virtual machine can be resized.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachines/{vmName}/vmSizes
# Returns: record<value: table<maxDataDiskCount: int, memoryInMB: int, name: string, numberOfCores: int, osDiskSizeInMB: int, resourceDiskSizeInMB: int>>
# operationId: VirtualMachines_ListAvailableSizes
export def "virtual-machines-list-available-sizes" [
  subscription_id: string
  resource_group_name: string
  vm_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachines/{vmName}/vmSizes"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vmName, var: vm_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vm_name: $vm_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
