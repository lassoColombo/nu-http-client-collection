# Auto-generated client for iotHubClient v2019-07-01-preview
# Source: https://api.apis.guru/v2/specs/azure.com/iothub/2019-07-01-preview/swagger.json
# Auth: --token flag or $env.IOTHUBCLIENT_TOKEN

const CLIENT = {
  base_url: "https://management.azure.com"
  token_env_var: "IOTHUBCLIENT_TOKEN"
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
def routing-source-completer [] { ["DeviceJobLifecycleEvents" "DeviceLifecycleEvents" "DeviceMessages" "DigitalTwinChangeEvents" "Invalid" "TwinChangeEvents"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    operations-list: "record<nextLink: string, value: table<display: record, name: string>>"
    iot-hub-resource-list-by-subscription: "record<nextLink: string, value: table<etag: string, properties: record, sku: record, id: string, location: string, name: string, tags: record, type: string>>"
    iot-hub-resource-check-name-availability: "record<message: string, nameAvailable: bool, reason: string>"
    resource-provider-common-get-subscription-quota: "record<nextLink: string, value: table<currentValue: int, id: string, limit: int, name: record, type: string, unit: string>>"
    iot-hub-resource-list-by-resource-group: "record<nextLink: string, value: table<etag: string, properties: record, sku: record, id: string, location: string, name: string, tags: record, type: string>>"
    iot-hub-resource-test-all-routes: "record<routes: table<properties: record>>"
    iot-hub-resource-test-route: "record<details: record<compilationErrors: list<record>>, result: string>"
    iot-hub-resource-get-endpoint-health: "record<nextLink: string, value: table<endpointId: string, healthStatus: string>>"
    iot-hub-resource-delete: "record<etag: string, properties: record<authorizationPolicies: list<record>, cloudToDevice: record<defaultTtlAsIso8601: string, feedback: record, maxDeliveryCount: int>, comments: string, deviceStreams: record<streamingEndpoints: list>, enableFileUploadNotifications: bool, eventHubEndpoints: record, features: string, hostName: string, ipFilterRules: list<record>, locations: list<record>, messagingEndpoints: record, provisioningState: string, routing: record<endpoints: record, enrichments: list, fallbackRoute: record, routes: list>, state: string, storageEndpoints: record>, sku: record<capacity: int, name: string, tier: string>, id: string, location: string, name: string, tags: record, type: string>"
    iot-hub-resource-get: "record<etag: string, properties: record<authorizationPolicies: list<record>, cloudToDevice: record<defaultTtlAsIso8601: string, feedback: record, maxDeliveryCount: int>, comments: string, deviceStreams: record<streamingEndpoints: list>, enableFileUploadNotifications: bool, eventHubEndpoints: record, features: string, hostName: string, ipFilterRules: list<record>, locations: list<record>, messagingEndpoints: record, provisioningState: string, routing: record<endpoints: record, enrichments: list, fallbackRoute: record, routes: list>, state: string, storageEndpoints: record>, sku: record<capacity: int, name: string, tier: string>, id: string, location: string, name: string, tags: record, type: string>"
    iot-hub-resource-update: "record<etag: string, properties: record<authorizationPolicies: list<record>, cloudToDevice: record<defaultTtlAsIso8601: string, feedback: record, maxDeliveryCount: int>, comments: string, deviceStreams: record<streamingEndpoints: list>, enableFileUploadNotifications: bool, eventHubEndpoints: record, features: string, hostName: string, ipFilterRules: list<record>, locations: list<record>, messagingEndpoints: record, provisioningState: string, routing: record<endpoints: record, enrichments: list, fallbackRoute: record, routes: list>, state: string, storageEndpoints: record>, sku: record<capacity: int, name: string, tier: string>, id: string, location: string, name: string, tags: record, type: string>"
    iot-hub-resource-create-or-update: "record<etag: string, properties: record<authorizationPolicies: list<record>, cloudToDevice: record<defaultTtlAsIso8601: string, feedback: record, maxDeliveryCount: int>, comments: string, deviceStreams: record<streamingEndpoints: list>, enableFileUploadNotifications: bool, eventHubEndpoints: record, features: string, hostName: string, ipFilterRules: list<record>, locations: list<record>, messagingEndpoints: record, provisioningState: string, routing: record<endpoints: record, enrichments: list, fallbackRoute: record, routes: list>, state: string, storageEndpoints: record>, sku: record<capacity: int, name: string, tier: string>, id: string, location: string, name: string, tags: record, type: string>"
    iot-hub-resource-get-keys-for-key-name: "record<keyName: string, primaryKey: string, rights: string, secondaryKey: string>"
    iot-hub-resource-get-stats: "record<disabledDeviceCount: int, enabledDeviceCount: int, totalDeviceCount: int>"
    certificates-list-by-iot-hub: "record<value: table<etag: string, id: string, name: string, properties: record, type: string>>"
    certificates-get: "record<etag: string, id: string, name: string, properties: record<certificate: string, created: string, expiry: string, isVerified: bool, subject: string, thumbprint: string, updated: string>, type: string>"
    certificates-create-or-update: "record<etag: string, id: string, name: string, properties: record<certificate: string, created: string, expiry: string, isVerified: bool, subject: string, thumbprint: string, updated: string>, type: string>"
    certificates-generate-verification-code: "record<etag: string, id: string, name: string, properties: record<certificate: string, created: string, expiry: string, isVerified: bool, subject: string, thumbprint: string, updated: string, verificationCode: string>, type: string>"
    certificates-verify: "record<etag: string, id: string, name: string, properties: record<certificate: string, created: string, expiry: string, isVerified: bool, subject: string, thumbprint: string, updated: string>, type: string>"
    iot-hub-resource-list-event-hub-consumer-groups: "record<nextLink: string, value: table<etag: string, id: string, name: string, properties: record, type: string>>"
    iot-hub-resource-get-event-hub-consumer-group: "record<etag: string, id: string, name: string, properties: record, type: string>"
    iot-hub-resource-create-event-hub-consumer-group: "record<etag: string, id: string, name: string, properties: record, type: string>"
    iot-hub-resource-export-devices: "record<endTimeUtc: string, failureReason: string, jobId: string, parentJobId: string, startTimeUtc: string, status: string, statusMessage: string, type: string>"
    iot-hub-resource-import-devices: "record<endTimeUtc: string, failureReason: string, jobId: string, parentJobId: string, startTimeUtc: string, status: string, statusMessage: string, type: string>"
    iot-hub-resource-list-jobs: "record<nextLink: string, value: table<endTimeUtc: string, failureReason: string, jobId: string, parentJobId: string, startTimeUtc: string, status: string, statusMessage: string, type: string>>"
    iot-hub-resource-get-job: "record<endTimeUtc: string, failureReason: string, jobId: string, parentJobId: string, startTimeUtc: string, status: string, statusMessage: string, type: string>"
    iot-hub-resource-list-keys: "record<nextLink: string, value: table<keyName: string, primaryKey: string, rights: string, secondaryKey: string>>"
    iot-hub-resource-get-quota-metrics: "record<nextLink: string, value: table<currentValue: int, maxValue: int, name: string>>"
    iot-hub-resource-get-valid-skus: "record<nextLink: string, value: table<capacity: record, resourceType: string, sku: record>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["operations-list" "iot-hub-resource-list-by-subscription" "iot-hub-resource-check-name-availability" "resource-provider-common-get-subscription-quota" "iot-hub-resource-list-by-resource-group" "iot-hub-manual-failover" "iot-hub-resource-test-all-routes" "iot-hub-resource-test-route" "iot-hub-resource-get-endpoint-health" "iot-hub-resource-delete" "iot-hub-resource-get" "iot-hub-resource-update" "iot-hub-resource-create-or-update" "iot-hub-resource-get-keys-for-key-name" "iot-hub-resource-get-stats" "certificates-list-by-iot-hub" "certificates-delete" "certificates-get" "certificates-create-or-update" "certificates-generate-verification-code" "certificates-verify" "iot-hub-resource-list-event-hub-consumer-groups" "iot-hub-resource-delete-event-hub-consumer-group" "iot-hub-resource-get-event-hub-consumer-group" "iot-hub-resource-create-event-hub-consumer-group" "iot-hub-resource-export-devices" "iot-hub-resource-import-devices" "iot-hub-resource-list-jobs" "iot-hub-resource-get-job" "iot-hub-resource-list-keys" "iot-hub-resource-get-quota-metrics" "iot-hub-resource-get-valid-skus" "commands"] | sort) } | get name | first)
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

# Lists all of the available IoT Hub REST API operations.
#
# GET /providers/Microsoft.Devices/operations
# Returns: record<nextLink: string, value: table<display: record, name: string>>
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
  --api-version: string # The version of the API. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Devices/operations"
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the IoT hubs in a subscription
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Devices/IotHubs
# Returns: record<nextLink: string, value: table<etag: string, properties: record, sku: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: IotHubResource_ListBySubscription
export def "iot-hub-resource-list-by-subscription" [
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
  --api-version: string # The version of the API. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.Devices/IotHubs"
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

# Check if an IoT hub name is available
#
# POST /subscriptions/{subscriptionId}/providers/Microsoft.Devices/checkNameAvailability
# Returns: record<message: string, nameAvailable: bool, reason: string>
# operationId: IotHubResource_CheckNameAvailability
export def "iot-hub-resource-check-name-availability" [
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
  --api-version: string # The version of the API. (required)
  name: string # The name of the IoT hub to check.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.Devices/checkNameAvailability"
    path_params: [{name: subscriptionId, var: subscription_id}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, api_version: $api_version, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the number of iot hubs in the subscription
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Devices/usages
# Returns: record<nextLink: string, value: table<currentValue: int, id: string, limit: int, name: record, type: string, unit: string>>
# operationId: ResourceProviderCommon_GetSubscriptionQuota
export def "resource-provider-common-get-subscription-quota" [
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
  --api-version: string # The version of the API. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.Devices/usages"
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

# Get all the IoT hubs in a resource group
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Devices/IotHubs
# Returns: record<nextLink: string, value: table<etag: string, properties: record, sku: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: IotHubResource_ListByResourceGroup
export def "iot-hub-resource-list-by-resource-group" [
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
  --api-version: string # The version of the API. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Devices/IotHubs"
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

# Manual Failover Fail over
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Devices/IotHubs/{iotHubName}/failover
# operationId: IotHub_ManualFailover
export def "iot-hub-manual-failover" [
  subscription_id: string
  resource_group_name: string
  iot_hub_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API. (required)
  failover_region: string # Region the hub will be failed over to
]: any -> any {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Devices/IotHubs/{iotHubName}/failover"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: iotHubName, var: iot_hub_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: failoverRegion, var: failover_region}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, iot_hub_name: $iot_hub_name, api_version: $api_version, failover_region: $failover_region
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Test all routes
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Devices/IotHubs/{iotHubName}/routing/routes/$testall
# Returns: record<routes: table<properties: record>>
# operationId: IotHubResource_TestAllRoutes
export def "iot-hub-resource-test-all-routes" [
  subscription_id: string
  resource_group_name: string
  iot_hub_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API. (required)
  --message: record # Routing message — shape: {appProperties?: record, body?: string, systemProperties?: record}
  --routing-source: string@routing-source-completer # Routing source
  --twin: record # Twin reference input parameter. This is an optional parameter — shape: {properties?: any, tags?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Devices/IotHubs/{iotHubName}/routing/routes/$testall"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: iotHubName, var: iot_hub_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: message, var: message}, {name: routingSource, var: routing_source}, {name: twin, var: twin}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, iot_hub_name: $iot_hub_name, api_version: $api_version, message: $message, routing_source: $routing_source, twin: $twin
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Test the new route
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Devices/IotHubs/{iotHubName}/routing/routes/$testnew
# Returns: record<details: record<compilationErrors: list<record>>, result: string>
# operationId: IotHubResource_TestRoute
export def "iot-hub-resource-test-route" [
  subscription_id: string
  resource_group_name: string
  iot_hub_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API. (required)
  --message: record # Routing message — shape: {appProperties?: record, body?: string, systemProperties?: record}
  route: record # The properties of a routing rule that your IoT hub uses to route messages to endpoints. — shape: {condition?: string, endpointNames: list<string>, isEnabled: bool, name: string, source: "Invalid"|"DeviceMessages"|"TwinChangeEvents"|"DeviceLifecycleEvents"|"DeviceJobLifecycleEvents"|"DigitalTwinChangeEvents"}
  --twin: record # Twin reference input parameter. This is an optional parameter — shape: {properties?: any, tags?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Devices/IotHubs/{iotHubName}/routing/routes/$testnew"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: iotHubName, var: iot_hub_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: message, var: message}, {name: route, var: route}, {name: twin, var: twin}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, iot_hub_name: $iot_hub_name, api_version: $api_version, message: $message, route: $route, twin: $twin
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the health for routing endpoints
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Devices/IotHubs/{iotHubName}/routingEndpointsHealth
# Returns: record<nextLink: string, value: table<endpointId: string, healthStatus: string>>
# operationId: IotHubResource_GetEndpointHealth
export def "iot-hub-resource-get-endpoint-health" [
  subscription_id: string
  resource_group_name: string
  iot_hub_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Devices/IotHubs/{iotHubName}/routingEndpointsHealth"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: iotHubName, var: iot_hub_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, iot_hub_name: $iot_hub_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an IoT hub
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Devices/IotHubs/{resourceName}
# Returns: record<etag: string, properties: record<authorizationPolicies: list<record>, cloudToDevice: record<defaultTtlAsIso8601: string, feedback: record, maxDeliveryCount: int>, comments: string, deviceStreams: record<streamingEndpoints: list>, enableFileUploadNotifications: bool, eventHubEndpoints: record, features: string, hostName: string, ipFilterRules: list<record>, locations: list<record>, messagingEndpoints: record, provisioningState: string, routing: record<endpoints: record, enrichments: list, fallbackRoute: record, routes: list>, state: string, storageEndpoints: record>, sku: record<capacity: int, name: string, tier: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: IotHubResource_Delete
export def "iot-hub-resource-delete" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Devices/IotHubs/{resourceName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the non-security related metadata of an IoT hub
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Devices/IotHubs/{resourceName}
# Returns: record<etag: string, properties: record<authorizationPolicies: list<record>, cloudToDevice: record<defaultTtlAsIso8601: string, feedback: record, maxDeliveryCount: int>, comments: string, deviceStreams: record<streamingEndpoints: list>, enableFileUploadNotifications: bool, eventHubEndpoints: record, features: string, hostName: string, ipFilterRules: list<record>, locations: list<record>, messagingEndpoints: record, provisioningState: string, routing: record<endpoints: record, enrichments: list, fallbackRoute: record, routes: list>, state: string, storageEndpoints: record>, sku: record<capacity: int, name: string, tier: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: IotHubResource_Get
export def "iot-hub-resource-get" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Devices/IotHubs/{resourceName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing IoT Hubs tags.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Devices/IotHubs/{resourceName}
# Returns: record<etag: string, properties: record<authorizationPolicies: list<record>, cloudToDevice: record<defaultTtlAsIso8601: string, feedback: record, maxDeliveryCount: int>, comments: string, deviceStreams: record<streamingEndpoints: list>, enableFileUploadNotifications: bool, eventHubEndpoints: record, features: string, hostName: string, ipFilterRules: list<record>, locations: list<record>, messagingEndpoints: record, provisioningState: string, routing: record<endpoints: record, enrichments: list, fallbackRoute: record, routes: list>, state: string, storageEndpoints: record>, sku: record<capacity: int, name: string, tier: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: IotHubResource_Update
export def "iot-hub-resource-update" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API. (required)
  --tags: any # Resource tags
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Devices/IotHubs/{resourceName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, api_version: $api_version, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create or update the metadata of an IoT hub.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Devices/IotHubs/{resourceName}
# Returns: record<etag: string, properties: record<authorizationPolicies: list<record>, cloudToDevice: record<defaultTtlAsIso8601: string, feedback: record, maxDeliveryCount: int>, comments: string, deviceStreams: record<streamingEndpoints: list>, enableFileUploadNotifications: bool, eventHubEndpoints: record, features: string, hostName: string, ipFilterRules: list<record>, locations: list<record>, messagingEndpoints: record, provisioningState: string, routing: record<endpoints: record, enrichments: list, fallbackRoute: record, routes: list>, state: string, storageEndpoints: record>, sku: record<capacity: int, name: string, tier: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: IotHubResource_CreateOrUpdate
export def "iot-hub-resource-create-or-update" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API. (required)
  --if-match: string # ETag of the IoT Hub. Do not specify for creating a brand new IoT Hub. Required to update an existing IoT Hub.
  --etag: string # The Etag field is *not* required. If it is provided in the response body, it must also be provided as a header per the normal ETag convention.
  --properties: record # The properties of an IoT hub. — shape: {authorizationPolicies?: list, cloudToDevice?: record, comments?: string, deviceStreams?: record, enableFileUploadNotifications?: bool, eventHubEndpoints?: record, features?: "None"|"DeviceManagement", ipFilterRules?: list, messagingEndpoints?: record, routing?: record, storageEndpoints?: record}
  sku: record # Information about the SKU of the IoT hub. — shape: {capacity?: int, name: "F1"|"S1"|"S2"|"S3"|"B1"|"B2"|"B3"}
  location: string # The resource location.
  --tags: record # The resource tags.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Devices/IotHubs/{resourceName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}]
    query: [{name: api-version, var: api_version, required: true}]
    header: [{name: If-Match, var: if_match}]
    body: {content_type: "application/json", kind: json, fields: [{name: etag, var: etag}, {name: properties, var: properties}, {name: sku, var: sku}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, api_version: $api_version, if_match: $if_match, etag: $etag, properties: $properties, sku: $sku, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a shared access policy by name from an IoT hub. For more information, see: https://docs.microsoft.com/azure/iot-hub/iot-hub-devguide-security
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Devices/IotHubs/{resourceName}/IotHubKeys/{keyName}/listkeys
# Returns: record<keyName: string, primaryKey: string, rights: string, secondaryKey: string>
# operationId: IotHubResource_GetKeysForKeyName
export def "iot-hub-resource-get-keys-for-key-name" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  key_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Devices/IotHubs/{resourceName}/IotHubKeys/{keyName}/listkeys"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: keyName, var: key_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, key_name: $key_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the statistics from an IoT hub
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Devices/IotHubs/{resourceName}/IotHubStats
# Returns: record<disabledDeviceCount: int, enabledDeviceCount: int, totalDeviceCount: int>
# operationId: IotHubResource_GetStats
export def "iot-hub-resource-get-stats" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Devices/IotHubs/{resourceName}/IotHubStats"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the certificate list.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Devices/IotHubs/{resourceName}/certificates
# Returns: record<value: table<etag: string, id: string, name: string, properties: record, type: string>>
# operationId: Certificates_ListByIotHub
export def "certificates-list-by-iot-hub" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Devices/IotHubs/{resourceName}/certificates"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an X509 certificate.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Devices/IotHubs/{resourceName}/certificates/{certificateName}
# operationId: Certificates_Delete
export def "certificates-delete" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  certificate_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API. (required)
  --if-match: string # ETag of the Certificate. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Devices/IotHubs/{resourceName}/certificates/{certificateName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: certificateName, var: certificate_name}]
    query: [{name: api-version, var: api_version, required: true}]
    header: [{name: If-Match, var: if_match, required: true}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, certificate_name: $certificate_name, api_version: $api_version, if_match: $if_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the certificate.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Devices/IotHubs/{resourceName}/certificates/{certificateName}
# Returns: record<etag: string, id: string, name: string, properties: record<certificate: string, created: string, expiry: string, isVerified: bool, subject: string, thumbprint: string, updated: string>, type: string>
# operationId: Certificates_Get
export def "certificates-get" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  certificate_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Devices/IotHubs/{resourceName}/certificates/{certificateName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: certificateName, var: certificate_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, certificate_name: $certificate_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload the certificate to the IoT hub.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Devices/IotHubs/{resourceName}/certificates/{certificateName}
# Returns: record<etag: string, id: string, name: string, properties: record<certificate: string, created: string, expiry: string, isVerified: bool, subject: string, thumbprint: string, updated: string>, type: string>
# operationId: Certificates_CreateOrUpdate
export def "certificates-create-or-update" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  certificate_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API. (required)
  --if-match: string # ETag of the Certificate. Do not specify for creating a brand new certificate. Required to update an existing certificate.
  --certificate: string # base-64 representation of the X509 leaf certificate .cer file or just .pem file content.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Devices/IotHubs/{resourceName}/certificates/{certificateName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: certificateName, var: certificate_name}]
    query: [{name: api-version, var: api_version, required: true}]
    header: [{name: If-Match, var: if_match}]
    body: {content_type: "application/json", kind: json, fields: [{name: certificate, var: certificate}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, certificate_name: $certificate_name, api_version: $api_version, if_match: $if_match, certificate: $certificate
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generate verification code for proof of possession flow.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Devices/IotHubs/{resourceName}/certificates/{certificateName}/generateVerificationCode
# Returns: record<etag: string, id: string, name: string, properties: record<certificate: string, created: string, expiry: string, isVerified: bool, subject: string, thumbprint: string, updated: string, verificationCode: string>, type: string>
# operationId: Certificates_GenerateVerificationCode
export def "certificates-generate-verification-code" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  certificate_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API. (required)
  --if-match: string # ETag of the Certificate. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Devices/IotHubs/{resourceName}/certificates/{certificateName}/generateVerificationCode"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: certificateName, var: certificate_name}]
    query: [{name: api-version, var: api_version, required: true}]
    header: [{name: If-Match, var: if_match, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, certificate_name: $certificate_name, api_version: $api_version, if_match: $if_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Verify certificate's private key possession.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Devices/IotHubs/{resourceName}/certificates/{certificateName}/verify
# Returns: record<etag: string, id: string, name: string, properties: record<certificate: string, created: string, expiry: string, isVerified: bool, subject: string, thumbprint: string, updated: string>, type: string>
# operationId: Certificates_Verify
export def "certificates-verify" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  certificate_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API. (required)
  --if-match: string # ETag of the Certificate. (required)
  --certificate: string # base-64 representation of X509 certificate .cer file or just .pem file content.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Devices/IotHubs/{resourceName}/certificates/{certificateName}/verify"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: certificateName, var: certificate_name}]
    query: [{name: api-version, var: api_version, required: true}]
    header: [{name: If-Match, var: if_match, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: certificate, var: certificate}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, certificate_name: $certificate_name, api_version: $api_version, if_match: $if_match, certificate: $certificate
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of the consumer groups in the Event Hub-compatible device-to-cloud endpoint in an IoT hub
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Devices/IotHubs/{resourceName}/eventHubEndpoints/{eventHubEndpointName}/ConsumerGroups
# Returns: record<nextLink: string, value: table<etag: string, id: string, name: string, properties: record, type: string>>
# operationId: IotHubResource_ListEventHubConsumerGroups
export def "iot-hub-resource-list-event-hub-consumer-groups" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  event_hub_endpoint_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Devices/IotHubs/{resourceName}/eventHubEndpoints/{eventHubEndpointName}/ConsumerGroups"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: eventHubEndpointName, var: event_hub_endpoint_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, event_hub_endpoint_name: $event_hub_endpoint_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a consumer group from an Event Hub-compatible endpoint in an IoT hub
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Devices/IotHubs/{resourceName}/eventHubEndpoints/{eventHubEndpointName}/ConsumerGroups/{name}
# operationId: IotHubResource_DeleteEventHubConsumerGroup
export def "iot-hub-resource-delete-event-hub-consumer-group" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  event_hub_endpoint_name: string
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
  --api-version: string # The version of the API. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Devices/IotHubs/{resourceName}/eventHubEndpoints/{eventHubEndpointName}/ConsumerGroups/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: eventHubEndpointName, var: event_hub_endpoint_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, event_hub_endpoint_name: $event_hub_endpoint_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a consumer group from the Event Hub-compatible device-to-cloud endpoint for an IoT hub
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Devices/IotHubs/{resourceName}/eventHubEndpoints/{eventHubEndpointName}/ConsumerGroups/{name}
# Returns: record<etag: string, id: string, name: string, properties: record, type: string>
# operationId: IotHubResource_GetEventHubConsumerGroup
export def "iot-hub-resource-get-event-hub-consumer-group" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  event_hub_endpoint_name: string
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
  --api-version: string # The version of the API. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Devices/IotHubs/{resourceName}/eventHubEndpoints/{eventHubEndpointName}/ConsumerGroups/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: eventHubEndpointName, var: event_hub_endpoint_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, event_hub_endpoint_name: $event_hub_endpoint_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a consumer group to an Event Hub-compatible endpoint in an IoT hub
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Devices/IotHubs/{resourceName}/eventHubEndpoints/{eventHubEndpointName}/ConsumerGroups/{name}
# Returns: record<etag: string, id: string, name: string, properties: record, type: string>
# operationId: IotHubResource_CreateEventHubConsumerGroup
export def "iot-hub-resource-create-event-hub-consumer-group" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  event_hub_endpoint_name: string
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
  --api-version: string # The version of the API. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Devices/IotHubs/{resourceName}/eventHubEndpoints/{eventHubEndpointName}/ConsumerGroups/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: eventHubEndpointName, var: event_hub_endpoint_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, event_hub_endpoint_name: $event_hub_endpoint_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Exports all the device identities in the IoT hub identity registry to an Azure Storage blob container. For more information, see: https://docs.microsoft.com/azure/iot-hub/iot-hub-devguide-identity-registry#import-and-export-device-identities
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Devices/IotHubs/{resourceName}/exportDevices
# Returns: record<endTimeUtc: string, failureReason: string, jobId: string, parentJobId: string, startTimeUtc: string, status: string, statusMessage: string, type: string>
# operationId: IotHubResource_ExportDevices
export def "iot-hub-resource-export-devices" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API. (required)
  --exclude-keys: oneof<nothing, bool> # The value indicating whether keys should be excluded during export.
  export_blob_container_uri: string # The export blob container URI.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Devices/IotHubs/{resourceName}/exportDevices"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: excludeKeys, var: exclude_keys, required: true}, {name: exportBlobContainerUri, var: export_blob_container_uri}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, api_version: $api_version, exclude_keys: $exclude_keys, export_blob_container_uri: $export_blob_container_uri
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Import, update, or delete device identities in the IoT hub identity registry from a blob. For more information, see: https://docs.microsoft.com/azure/iot-hub/iot-hub-devguide-identity-registry#import-and-export-device-identities
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Devices/IotHubs/{resourceName}/importDevices
# Returns: record<endTimeUtc: string, failureReason: string, jobId: string, parentJobId: string, startTimeUtc: string, status: string, statusMessage: string, type: string>
# operationId: IotHubResource_ImportDevices
export def "iot-hub-resource-import-devices" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API. (required)
  input_blob_container_uri: string # The input blob container URI.
  output_blob_container_uri: string # The output blob container URI.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Devices/IotHubs/{resourceName}/importDevices"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: inputBlobContainerUri, var: input_blob_container_uri}, {name: outputBlobContainerUri, var: output_blob_container_uri}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, api_version: $api_version, input_blob_container_uri: $input_blob_container_uri, output_blob_container_uri: $output_blob_container_uri
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of all the jobs in an IoT hub. For more information, see: https://docs.microsoft.com/azure/iot-hub/iot-hub-devguide-identity-registry
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Devices/IotHubs/{resourceName}/jobs
# Returns: record<nextLink: string, value: table<endTimeUtc: string, failureReason: string, jobId: string, parentJobId: string, startTimeUtc: string, status: string, statusMessage: string, type: string>>
# operationId: IotHubResource_ListJobs
export def "iot-hub-resource-list-jobs" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Devices/IotHubs/{resourceName}/jobs"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the details of a job from an IoT hub. For more information, see: https://docs.microsoft.com/azure/iot-hub/iot-hub-devguide-identity-registry
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Devices/IotHubs/{resourceName}/jobs/{jobId}
# Returns: record<endTimeUtc: string, failureReason: string, jobId: string, parentJobId: string, startTimeUtc: string, status: string, statusMessage: string, type: string>
# operationId: IotHubResource_GetJob
export def "iot-hub-resource-get-job" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Devices/IotHubs/{resourceName}/jobs/{jobId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: jobId, var: job_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, job_id: $job_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the security metadata for an IoT hub. For more information, see: https://docs.microsoft.com/azure/iot-hub/iot-hub-devguide-security
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Devices/IotHubs/{resourceName}/listkeys
# Returns: record<nextLink: string, value: table<keyName: string, primaryKey: string, rights: string, secondaryKey: string>>
# operationId: IotHubResource_ListKeys
export def "iot-hub-resource-list-keys" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Devices/IotHubs/{resourceName}/listkeys"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the quota metrics for an IoT hub
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Devices/IotHubs/{resourceName}/quotaMetrics
# Returns: record<nextLink: string, value: table<currentValue: int, maxValue: int, name: string>>
# operationId: IotHubResource_GetQuotaMetrics
export def "iot-hub-resource-get-quota-metrics" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Devices/IotHubs/{resourceName}/quotaMetrics"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the list of valid SKUs for an IoT hub
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Devices/IotHubs/{resourceName}/skus
# Returns: record<nextLink: string, value: table<capacity: record, resourceType: string, sku: record>>
# operationId: IotHubResource_GetValidSkus
export def "iot-hub-resource-get-valid-skus" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Devices/IotHubs/{resourceName}/skus"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
