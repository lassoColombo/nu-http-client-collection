# Auto-generated client for DevTestLabsClient v2018-09-15
# Source: https://api.apis.guru/v2/specs/azure.com/devtestlabs-DTL/2018-09-15/swagger.json
# Auth: --token flag or $env.DEVTESTLABSCLIENT_TOKEN

const CLIENT = {
  base_url: "https://management.azure.com"
  token_env_var: "DEVTESTLABSCLIENT_TOKEN"
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
def file-upload-options-completer [] { ["None" "UploadFilesAndGenerateSasTokens"] }
def event-name-completer [] { ["AutoShutdown" "Cost"] }
def host-caching-completer [] { ["None" "ReadOnly" "ReadWrite"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    provider-operations-list: "record<nextLink: string, value: table<display: record, name: string>>"
    labs-list-by-subscription: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    operations-get: "record<error: record<code: string, message: string>, status: string, statusCode: string>"
    global-schedules-list-by-subscription: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    labs-list-by-resource-group: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    artifact-sources-list: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    arm-templates-list: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    arm-templates-get: "record<properties: record<contents: record, createdDate: string, description: string, displayName: string, enabled: bool, icon: string, parametersValueFilesInfo: list<record>, publisher: string>, id: string, location: string, name: string, tags: record, type: string>"
    artifacts-list: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    artifacts-get: "record<properties: record<createdDate: string, description: string, filePath: string, icon: string, parameters: record, publisher: string, targetOsType: string, title: string>, id: string, location: string, name: string, tags: record, type: string>"
    artifacts-generate-arm-template: "record<parameters: record, template: record>"
    artifact-sources-get: "record<properties: record<armTemplateFolderPath: string, branchRef: string, createdDate: string, displayName: string, folderPath: string, provisioningState: string, securityToken: string, sourceType: string, status: string, uniqueIdentifier: string, uri: string>, id: string, location: string, name: string, tags: record, type: string>"
    artifact-sources-update: "record<properties: record<armTemplateFolderPath: string, branchRef: string, createdDate: string, displayName: string, folderPath: string, provisioningState: string, securityToken: string, sourceType: string, status: string, uniqueIdentifier: string, uri: string>, id: string, location: string, name: string, tags: record, type: string>"
    artifact-sources-create-or-update: "record<properties: record<armTemplateFolderPath: string, branchRef: string, createdDate: string, displayName: string, folderPath: string, provisioningState: string, securityToken: string, sourceType: string, status: string, uniqueIdentifier: string, uri: string>, id: string, location: string, name: string, tags: record, type: string>"
    costs-get: "record<properties: record<createdDate: string, currencyCode: string, endDateTime: string, labCostDetails: list<record>, labCostSummary: record<estimatedLabCost: float>, provisioningState: string, resourceCosts: list<record>, startDateTime: string, targetCost: record<costThresholds: list, cycleEndDateTime: string, cycleStartDateTime: string, cycleType: string, status: string, target: int>, uniqueIdentifier: string>, id: string, location: string, name: string, tags: record, type: string>"
    costs-create-or-update: "record<properties: record<createdDate: string, currencyCode: string, endDateTime: string, labCostDetails: list<record>, labCostSummary: record<estimatedLabCost: float>, provisioningState: string, resourceCosts: list<record>, startDateTime: string, targetCost: record<costThresholds: list, cycleEndDateTime: string, cycleStartDateTime: string, cycleType: string, status: string, target: int>, uniqueIdentifier: string>, id: string, location: string, name: string, tags: record, type: string>"
    custom-images-list: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    custom-images-get: "record<properties: record<author: string, creationDate: string, customImagePlan: record<id: string, offer: string, publisher: string>, dataDiskStorageInfo: list<record>, description: string, isPlanAuthorized: bool, managedImageId: string, managedSnapshotId: string, provisioningState: string, uniqueIdentifier: string, vhd: record<imageName: string, osType: string, sysPrep: bool>, vm: record<linuxOsInfo: record, sourceVmId: string, windowsOsInfo: record>>, id: string, location: string, name: string, tags: record, type: string>"
    custom-images-update: "record<properties: record<author: string, creationDate: string, customImagePlan: record<id: string, offer: string, publisher: string>, dataDiskStorageInfo: list<record>, description: string, isPlanAuthorized: bool, managedImageId: string, managedSnapshotId: string, provisioningState: string, uniqueIdentifier: string, vhd: record<imageName: string, osType: string, sysPrep: bool>, vm: record<linuxOsInfo: record, sourceVmId: string, windowsOsInfo: record>>, id: string, location: string, name: string, tags: record, type: string>"
    custom-images-create-or-update: "record<properties: record<author: string, creationDate: string, customImagePlan: record<id: string, offer: string, publisher: string>, dataDiskStorageInfo: list<record>, description: string, isPlanAuthorized: bool, managedImageId: string, managedSnapshotId: string, provisioningState: string, uniqueIdentifier: string, vhd: record<imageName: string, osType: string, sysPrep: bool>, vm: record<linuxOsInfo: record, sourceVmId: string, windowsOsInfo: record>>, id: string, location: string, name: string, tags: record, type: string>"
    formulas-list: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    formulas-get: "record<properties: record<author: string, creationDate: string, description: string, formulaContent: record<location: string, name: string, properties: record, tags: record>, osType: string, provisioningState: string, uniqueIdentifier: string, vm: record<labVmId: string>>, id: string, location: string, name: string, tags: record, type: string>"
    formulas-update: "record<properties: record<author: string, creationDate: string, description: string, formulaContent: record<location: string, name: string, properties: record, tags: record>, osType: string, provisioningState: string, uniqueIdentifier: string, vm: record<labVmId: string>>, id: string, location: string, name: string, tags: record, type: string>"
    formulas-create-or-update: "record<properties: record<author: string, creationDate: string, description: string, formulaContent: record<location: string, name: string, properties: record, tags: record>, osType: string, provisioningState: string, uniqueIdentifier: string, vm: record<labVmId: string>>, id: string, location: string, name: string, tags: record, type: string>"
    gallery-images-list: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    notification-channels-list: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    notification-channels-get: "record<properties: record<createdDate: string, description: string, emailRecipient: string, events: list<record>, notificationLocale: string, provisioningState: string, uniqueIdentifier: string, webHookUrl: string>, id: string, location: string, name: string, tags: record, type: string>"
    notification-channels-update: "record<properties: record<createdDate: string, description: string, emailRecipient: string, events: list<record>, notificationLocale: string, provisioningState: string, uniqueIdentifier: string, webHookUrl: string>, id: string, location: string, name: string, tags: record, type: string>"
    notification-channels-create-or-update: "record<properties: record<createdDate: string, description: string, emailRecipient: string, events: list<record>, notificationLocale: string, provisioningState: string, uniqueIdentifier: string, webHookUrl: string>, id: string, location: string, name: string, tags: record, type: string>"
    policy-sets-evaluate-policies: "record<results: table<hasError: bool, policyViolations: list>>"
    policies-list: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    policies-get: "record<properties: record<createdDate: string, description: string, evaluatorType: string, factData: string, factName: string, provisioningState: string, status: string, threshold: string, uniqueIdentifier: string>, id: string, location: string, name: string, tags: record, type: string>"
    policies-update: "record<properties: record<createdDate: string, description: string, evaluatorType: string, factData: string, factName: string, provisioningState: string, status: string, threshold: string, uniqueIdentifier: string>, id: string, location: string, name: string, tags: record, type: string>"
    policies-create-or-update: "record<properties: record<createdDate: string, description: string, evaluatorType: string, factData: string, factName: string, provisioningState: string, status: string, threshold: string, uniqueIdentifier: string>, id: string, location: string, name: string, tags: record, type: string>"
    schedules-list: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    schedules-get: "record<properties: record<createdDate: string, dailyRecurrence: record<time: string>, hourlyRecurrence: record<minute: int>, notificationSettings: record<emailRecipient: string, notificationLocale: string, status: string, timeInMinutes: int, webhookUrl: string>, provisioningState: string, status: string, targetResourceId: string, taskType: string, timeZoneId: string, uniqueIdentifier: string, weeklyRecurrence: record<time: string, weekdays: list>>, id: string, location: string, name: string, tags: record, type: string>"
    schedules-update: "record<properties: record<createdDate: string, dailyRecurrence: record<time: string>, hourlyRecurrence: record<minute: int>, notificationSettings: record<emailRecipient: string, notificationLocale: string, status: string, timeInMinutes: int, webhookUrl: string>, provisioningState: string, status: string, targetResourceId: string, taskType: string, timeZoneId: string, uniqueIdentifier: string, weeklyRecurrence: record<time: string, weekdays: list>>, id: string, location: string, name: string, tags: record, type: string>"
    schedules-create-or-update: "record<properties: record<createdDate: string, dailyRecurrence: record<time: string>, hourlyRecurrence: record<minute: int>, notificationSettings: record<emailRecipient: string, notificationLocale: string, status: string, timeInMinutes: int, webhookUrl: string>, provisioningState: string, status: string, targetResourceId: string, taskType: string, timeZoneId: string, uniqueIdentifier: string, weeklyRecurrence: record<time: string, weekdays: list>>, id: string, location: string, name: string, tags: record, type: string>"
    schedules-list-applicable: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    service-runners-get: "record<identity: record<clientSecretUrl: string, principalId: string, tenantId: string, type: string>, id: string, location: string, name: string, tags: record, type: string>"
    service-runners-create-or-update: "record<identity: record<clientSecretUrl: string, principalId: string, tenantId: string, type: string>, id: string, location: string, name: string, tags: record, type: string>"
    users-list: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    users-get: "record<properties: record<createdDate: string, identity: record<appId: string, objectId: string, principalId: string, principalName: string, tenantId: string>, provisioningState: string, secretStore: record<keyVaultId: string, keyVaultUri: string>, uniqueIdentifier: string>, id: string, location: string, name: string, tags: record, type: string>"
    users-update: "record<properties: record<createdDate: string, identity: record<appId: string, objectId: string, principalId: string, principalName: string, tenantId: string>, provisioningState: string, secretStore: record<keyVaultId: string, keyVaultUri: string>, uniqueIdentifier: string>, id: string, location: string, name: string, tags: record, type: string>"
    users-create-or-update: "record<properties: record<createdDate: string, identity: record<appId: string, objectId: string, principalId: string, principalName: string, tenantId: string>, provisioningState: string, secretStore: record<keyVaultId: string, keyVaultUri: string>, uniqueIdentifier: string>, id: string, location: string, name: string, tags: record, type: string>"
    disks-list: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    disks-get: "record<properties: record<createdDate: string, diskBlobName: string, diskSizeGiB: int, diskType: string, diskUri: string, hostCaching: string, leasedByLabVmId: string, managedDiskId: string, provisioningState: string, uniqueIdentifier: string>, id: string, location: string, name: string, tags: record, type: string>"
    disks-update: "record<properties: record<createdDate: string, diskBlobName: string, diskSizeGiB: int, diskType: string, diskUri: string, hostCaching: string, leasedByLabVmId: string, managedDiskId: string, provisioningState: string, uniqueIdentifier: string>, id: string, location: string, name: string, tags: record, type: string>"
    disks-create-or-update: "record<properties: record<createdDate: string, diskBlobName: string, diskSizeGiB: int, diskType: string, diskUri: string, hostCaching: string, leasedByLabVmId: string, managedDiskId: string, provisioningState: string, uniqueIdentifier: string>, id: string, location: string, name: string, tags: record, type: string>"
    environments-list: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    environments-get: "record<properties: record<armTemplateDisplayName: string, createdByUser: string, deploymentProperties: record<armTemplateId: string, parameters: list>, provisioningState: string, resourceGroupId: string, uniqueIdentifier: string>, id: string, location: string, name: string, tags: record, type: string>"
    environments-update: "record<properties: record<armTemplateDisplayName: string, createdByUser: string, deploymentProperties: record<armTemplateId: string, parameters: list>, provisioningState: string, resourceGroupId: string, uniqueIdentifier: string>, id: string, location: string, name: string, tags: record, type: string>"
    environments-create-or-update: "record<properties: record<armTemplateDisplayName: string, createdByUser: string, deploymentProperties: record<armTemplateId: string, parameters: list>, provisioningState: string, resourceGroupId: string, uniqueIdentifier: string>, id: string, location: string, name: string, tags: record, type: string>"
    secrets-list: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    secrets-get: "record<properties: record<provisioningState: string, uniqueIdentifier: string, value: string>, id: string, location: string, name: string, tags: record, type: string>"
    secrets-update: "record<properties: record<provisioningState: string, uniqueIdentifier: string, value: string>, id: string, location: string, name: string, tags: record, type: string>"
    secrets-create-or-update: "record<properties: record<provisioningState: string, uniqueIdentifier: string, value: string>, id: string, location: string, name: string, tags: record, type: string>"
    service-fabrics-list: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    service-fabrics-get: "record<properties: record<applicableSchedule: record<properties: record, id: string, location: string, name: string, tags: record, type: string>, environmentId: string, externalServiceFabricId: string, provisioningState: string, uniqueIdentifier: string>, id: string, location: string, name: string, tags: record, type: string>"
    service-fabrics-update: "record<properties: record<applicableSchedule: record<properties: record, id: string, location: string, name: string, tags: record, type: string>, environmentId: string, externalServiceFabricId: string, provisioningState: string, uniqueIdentifier: string>, id: string, location: string, name: string, tags: record, type: string>"
    service-fabrics-create-or-update: "record<properties: record<applicableSchedule: record<properties: record, id: string, location: string, name: string, tags: record, type: string>, environmentId: string, externalServiceFabricId: string, provisioningState: string, uniqueIdentifier: string>, id: string, location: string, name: string, tags: record, type: string>"
    service-fabrics-list-applicable-schedules: "record<properties: record<labVmsShutdown: record<properties: record, id: string, location: string, name: string, tags: record, type: string>, labVmsStartup: record<properties: record, id: string, location: string, name: string, tags: record, type: string>>, id: string, location: string, name: string, tags: record, type: string>"
    service-fabric-schedules-list: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    service-fabric-schedules-get: "record<properties: record<createdDate: string, dailyRecurrence: record<time: string>, hourlyRecurrence: record<minute: int>, notificationSettings: record<emailRecipient: string, notificationLocale: string, status: string, timeInMinutes: int, webhookUrl: string>, provisioningState: string, status: string, targetResourceId: string, taskType: string, timeZoneId: string, uniqueIdentifier: string, weeklyRecurrence: record<time: string, weekdays: list>>, id: string, location: string, name: string, tags: record, type: string>"
    service-fabric-schedules-update: "record<properties: record<createdDate: string, dailyRecurrence: record<time: string>, hourlyRecurrence: record<minute: int>, notificationSettings: record<emailRecipient: string, notificationLocale: string, status: string, timeInMinutes: int, webhookUrl: string>, provisioningState: string, status: string, targetResourceId: string, taskType: string, timeZoneId: string, uniqueIdentifier: string, weeklyRecurrence: record<time: string, weekdays: list>>, id: string, location: string, name: string, tags: record, type: string>"
    service-fabric-schedules-create-or-update: "record<properties: record<createdDate: string, dailyRecurrence: record<time: string>, hourlyRecurrence: record<minute: int>, notificationSettings: record<emailRecipient: string, notificationLocale: string, status: string, timeInMinutes: int, webhookUrl: string>, provisioningState: string, status: string, targetResourceId: string, taskType: string, timeZoneId: string, uniqueIdentifier: string, weeklyRecurrence: record<time: string, weekdays: list>>, id: string, location: string, name: string, tags: record, type: string>"
    virtual-machines-list: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    virtual-machines-get: "record<properties: record<allowClaim: bool, applicableSchedule: record<properties: record, id: string, location: string, name: string, tags: record, type: string>, artifactDeploymentStatus: record<artifactsApplied: int, deploymentStatus: string, totalArtifacts: int>, artifacts: list<record>, computeId: string, computeVm: record<dataDiskIds: list, dataDisks: list, networkInterfaceId: string, osDiskId: string, osType: string, statuses: list, vmSize: string>, createdByUser: string, createdByUserId: string, createdDate: string, customImageId: string, dataDiskParameters: list<record>, disallowPublicIpAddress: bool, environmentId: string, expirationDate: string, fqdn: string, galleryImageReference: record<offer: string, osType: string, publisher: string, sku: string, version: string>, isAuthenticationWithSshKey: bool, labSubnetName: string, labVirtualNetworkId: string, lastKnownPowerState: string, networkInterface: record<dnsName: string, privateIpAddress: string, publicIpAddress: string, publicIpAddressId: string, rdpAuthority: string, sharedPublicIpAddressConfiguration: record, sshAuthority: string, subnetId: string, virtualNetworkId: string>, notes: string, osType: string, ownerObjectId: string, ownerUserPrincipalName: string, password: string, planId: string, provisioningState: string, scheduleParameters: list<record>, size: string, sshKey: string, storageType: string, uniqueIdentifier: string, userName: string, virtualMachineCreationSource: string>, id: string, location: string, name: string, tags: record, type: string>"
    virtual-machines-update: "record<properties: record<allowClaim: bool, applicableSchedule: record<properties: record, id: string, location: string, name: string, tags: record, type: string>, artifactDeploymentStatus: record<artifactsApplied: int, deploymentStatus: string, totalArtifacts: int>, artifacts: list<record>, computeId: string, computeVm: record<dataDiskIds: list, dataDisks: list, networkInterfaceId: string, osDiskId: string, osType: string, statuses: list, vmSize: string>, createdByUser: string, createdByUserId: string, createdDate: string, customImageId: string, dataDiskParameters: list<record>, disallowPublicIpAddress: bool, environmentId: string, expirationDate: string, fqdn: string, galleryImageReference: record<offer: string, osType: string, publisher: string, sku: string, version: string>, isAuthenticationWithSshKey: bool, labSubnetName: string, labVirtualNetworkId: string, lastKnownPowerState: string, networkInterface: record<dnsName: string, privateIpAddress: string, publicIpAddress: string, publicIpAddressId: string, rdpAuthority: string, sharedPublicIpAddressConfiguration: record, sshAuthority: string, subnetId: string, virtualNetworkId: string>, notes: string, osType: string, ownerObjectId: string, ownerUserPrincipalName: string, password: string, planId: string, provisioningState: string, scheduleParameters: list<record>, size: string, sshKey: string, storageType: string, uniqueIdentifier: string, userName: string, virtualMachineCreationSource: string>, id: string, location: string, name: string, tags: record, type: string>"
    virtual-machines-create-or-update: "record<properties: record<allowClaim: bool, applicableSchedule: record<properties: record, id: string, location: string, name: string, tags: record, type: string>, artifactDeploymentStatus: record<artifactsApplied: int, deploymentStatus: string, totalArtifacts: int>, artifacts: list<record>, computeId: string, computeVm: record<dataDiskIds: list, dataDisks: list, networkInterfaceId: string, osDiskId: string, osType: string, statuses: list, vmSize: string>, createdByUser: string, createdByUserId: string, createdDate: string, customImageId: string, dataDiskParameters: list<record>, disallowPublicIpAddress: bool, environmentId: string, expirationDate: string, fqdn: string, galleryImageReference: record<offer: string, osType: string, publisher: string, sku: string, version: string>, isAuthenticationWithSshKey: bool, labSubnetName: string, labVirtualNetworkId: string, lastKnownPowerState: string, networkInterface: record<dnsName: string, privateIpAddress: string, publicIpAddress: string, publicIpAddressId: string, rdpAuthority: string, sharedPublicIpAddressConfiguration: record, sshAuthority: string, subnetId: string, virtualNetworkId: string>, notes: string, osType: string, ownerObjectId: string, ownerUserPrincipalName: string, password: string, planId: string, provisioningState: string, scheduleParameters: list<record>, size: string, sshKey: string, storageType: string, uniqueIdentifier: string, userName: string, virtualMachineCreationSource: string>, id: string, location: string, name: string, tags: record, type: string>"
    virtual-machines-get-rdp-file-contents: "record<contents: string>"
    virtual-machines-list-applicable-schedules: "record<properties: record<labVmsShutdown: record<properties: record, id: string, location: string, name: string, tags: record, type: string>, labVmsStartup: record<properties: record, id: string, location: string, name: string, tags: record, type: string>>, id: string, location: string, name: string, tags: record, type: string>"
    virtual-machine-schedules-list: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    virtual-machine-schedules-get: "record<properties: record<createdDate: string, dailyRecurrence: record<time: string>, hourlyRecurrence: record<minute: int>, notificationSettings: record<emailRecipient: string, notificationLocale: string, status: string, timeInMinutes: int, webhookUrl: string>, provisioningState: string, status: string, targetResourceId: string, taskType: string, timeZoneId: string, uniqueIdentifier: string, weeklyRecurrence: record<time: string, weekdays: list>>, id: string, location: string, name: string, tags: record, type: string>"
    virtual-machine-schedules-update: "record<properties: record<createdDate: string, dailyRecurrence: record<time: string>, hourlyRecurrence: record<minute: int>, notificationSettings: record<emailRecipient: string, notificationLocale: string, status: string, timeInMinutes: int, webhookUrl: string>, provisioningState: string, status: string, targetResourceId: string, taskType: string, timeZoneId: string, uniqueIdentifier: string, weeklyRecurrence: record<time: string, weekdays: list>>, id: string, location: string, name: string, tags: record, type: string>"
    virtual-machine-schedules-create-or-update: "record<properties: record<createdDate: string, dailyRecurrence: record<time: string>, hourlyRecurrence: record<minute: int>, notificationSettings: record<emailRecipient: string, notificationLocale: string, status: string, timeInMinutes: int, webhookUrl: string>, provisioningState: string, status: string, targetResourceId: string, taskType: string, timeZoneId: string, uniqueIdentifier: string, weeklyRecurrence: record<time: string, weekdays: list>>, id: string, location: string, name: string, tags: record, type: string>"
    virtual-networks-list: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    virtual-networks-get: "record<properties: record<allowedSubnets: list<record>, createdDate: string, description: string, externalProviderResourceId: string, externalSubnets: list<record>, provisioningState: string, subnetOverrides: list<record>, uniqueIdentifier: string>, id: string, location: string, name: string, tags: record, type: string>"
    virtual-networks-update: "record<properties: record<allowedSubnets: list<record>, createdDate: string, description: string, externalProviderResourceId: string, externalSubnets: list<record>, provisioningState: string, subnetOverrides: list<record>, uniqueIdentifier: string>, id: string, location: string, name: string, tags: record, type: string>"
    virtual-networks-create-or-update: "record<properties: record<allowedSubnets: list<record>, createdDate: string, description: string, externalProviderResourceId: string, externalSubnets: list<record>, provisioningState: string, subnetOverrides: list<record>, uniqueIdentifier: string>, id: string, location: string, name: string, tags: record, type: string>"
    labs-get: "record<properties: record<announcement: record<enabled: string, expirationDate: string, expired: bool, markdown: string, provisioningState: string, title: string, uniqueIdentifier: string>, artifactsStorageAccount: string, createdDate: string, defaultPremiumStorageAccount: string, defaultStorageAccount: string, environmentPermission: string, extendedProperties: record, labStorageType: string, loadBalancerId: string, mandatoryArtifactsResourceIdsLinux: list<string>, mandatoryArtifactsResourceIdsWindows: list<string>, networkSecurityGroupId: string, premiumDataDiskStorageAccount: string, premiumDataDisks: string, provisioningState: string, publicIpId: string, support: record<enabled: string, markdown: string>, uniqueIdentifier: string, vaultName: string, vmCreationResourceGroup: string>, id: string, location: string, name: string, tags: record, type: string>"
    labs-update: "record<properties: record<announcement: record<enabled: string, expirationDate: string, expired: bool, markdown: string, provisioningState: string, title: string, uniqueIdentifier: string>, artifactsStorageAccount: string, createdDate: string, defaultPremiumStorageAccount: string, defaultStorageAccount: string, environmentPermission: string, extendedProperties: record, labStorageType: string, loadBalancerId: string, mandatoryArtifactsResourceIdsLinux: list<string>, mandatoryArtifactsResourceIdsWindows: list<string>, networkSecurityGroupId: string, premiumDataDiskStorageAccount: string, premiumDataDisks: string, provisioningState: string, publicIpId: string, support: record<enabled: string, markdown: string>, uniqueIdentifier: string, vaultName: string, vmCreationResourceGroup: string>, id: string, location: string, name: string, tags: record, type: string>"
    labs-create-or-update: "record<properties: record<announcement: record<enabled: string, expirationDate: string, expired: bool, markdown: string, provisioningState: string, title: string, uniqueIdentifier: string>, artifactsStorageAccount: string, createdDate: string, defaultPremiumStorageAccount: string, defaultStorageAccount: string, environmentPermission: string, extendedProperties: record, labStorageType: string, loadBalancerId: string, mandatoryArtifactsResourceIdsLinux: list<string>, mandatoryArtifactsResourceIdsWindows: list<string>, networkSecurityGroupId: string, premiumDataDiskStorageAccount: string, premiumDataDisks: string, provisioningState: string, publicIpId: string, support: record<enabled: string, markdown: string>, uniqueIdentifier: string, vaultName: string, vmCreationResourceGroup: string>, id: string, location: string, name: string, tags: record, type: string>"
    labs-generate-upload-uri: "record<uploadUri: string>"
    labs-list-vhds: "record<nextLink: string, value: table<id: string>>"
    global-schedules-list-by-resource-group: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    global-schedules-get: "record<properties: record<createdDate: string, dailyRecurrence: record<time: string>, hourlyRecurrence: record<minute: int>, notificationSettings: record<emailRecipient: string, notificationLocale: string, status: string, timeInMinutes: int, webhookUrl: string>, provisioningState: string, status: string, targetResourceId: string, taskType: string, timeZoneId: string, uniqueIdentifier: string, weeklyRecurrence: record<time: string, weekdays: list>>, id: string, location: string, name: string, tags: record, type: string>"
    global-schedules-update: "record<properties: record<createdDate: string, dailyRecurrence: record<time: string>, hourlyRecurrence: record<minute: int>, notificationSettings: record<emailRecipient: string, notificationLocale: string, status: string, timeInMinutes: int, webhookUrl: string>, provisioningState: string, status: string, targetResourceId: string, taskType: string, timeZoneId: string, uniqueIdentifier: string, weeklyRecurrence: record<time: string, weekdays: list>>, id: string, location: string, name: string, tags: record, type: string>"
    global-schedules-create-or-update: "record<properties: record<createdDate: string, dailyRecurrence: record<time: string>, hourlyRecurrence: record<minute: int>, notificationSettings: record<emailRecipient: string, notificationLocale: string, status: string, timeInMinutes: int, webhookUrl: string>, provisioningState: string, status: string, targetResourceId: string, taskType: string, timeZoneId: string, uniqueIdentifier: string, weeklyRecurrence: record<time: string, weekdays: list>>, id: string, location: string, name: string, tags: record, type: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["provider-operations-list" "labs-list-by-subscription" "operations-get" "global-schedules-list-by-subscription" "labs-list-by-resource-group" "artifact-sources-list" "arm-templates-list" "arm-templates-get" "artifacts-list" "artifacts-get" "artifacts-generate-arm-template" "artifact-sources-delete" "artifact-sources-get" "artifact-sources-update" "artifact-sources-create-or-update" "costs-get" "costs-create-or-update" "custom-images-list" "custom-images-delete" "custom-images-get" "custom-images-update" "custom-images-create-or-update" "formulas-list" "formulas-delete" "formulas-get" "formulas-update" "formulas-create-or-update" "gallery-images-list" "notification-channels-list" "notification-channels-delete" "notification-channels-get" "notification-channels-update" "notification-channels-create-or-update" "notification-channels-notify" "policy-sets-evaluate-policies" "policies-list" "policies-delete" "policies-get" "policies-update" "policies-create-or-update" "schedules-list" "schedules-delete" "schedules-get" "schedules-update" "schedules-create-or-update" "schedules-execute" "schedules-list-applicable" "service-runners-delete" "service-runners-get" "service-runners-create-or-update" "users-list" "users-delete" "users-get" "users-update" "users-create-or-update" "disks-list" "disks-delete" "disks-get" "disks-update" "disks-create-or-update" "disks-attach" "disks-detach" "environments-list" "environments-delete" "environments-get" "environments-update" "environments-create-or-update" "secrets-list" "secrets-delete" "secrets-get" "secrets-update" "secrets-create-or-update" "service-fabrics-list" "service-fabrics-delete" "service-fabrics-get" "service-fabrics-update" "service-fabrics-create-or-update" "service-fabrics-list-applicable-schedules" "service-fabrics-start" "service-fabrics-stop" "service-fabric-schedules-list" "service-fabric-schedules-delete" "service-fabric-schedules-get" "service-fabric-schedules-update" "service-fabric-schedules-create-or-update" "service-fabric-schedules-execute" "virtual-machines-list" "virtual-machines-delete" "virtual-machines-get" "virtual-machines-update" "virtual-machines-create-or-update" "virtual-machines-add-data-disk" "virtual-machines-apply-artifacts" "virtual-machines-claim" "virtual-machines-detach-data-disk" "virtual-machines-get-rdp-file-contents" "virtual-machines-list-applicable-schedules" "virtual-machines-redeploy" "virtual-machines-resize" "virtual-machines-restart" "virtual-machines-start" "virtual-machines-stop" "virtual-machines-transfer-disks" "virtual-machines-un-claim" "virtual-machine-schedules-list" "virtual-machine-schedules-delete" "virtual-machine-schedules-get" "virtual-machine-schedules-update" "virtual-machine-schedules-create-or-update" "virtual-machine-schedules-execute" "virtual-networks-list" "virtual-networks-delete" "virtual-networks-get" "virtual-networks-update" "virtual-networks-create-or-update" "labs-delete" "labs-get" "labs-update" "labs-create-or-update" "labs-claim-any-vm" "labs-create-environment" "labs-export-resource-usage" "labs-generate-upload-uri" "labs-import-virtual-machine" "labs-list-vhds" "global-schedules-list-by-resource-group" "global-schedules-delete" "global-schedules-get" "global-schedules-update" "global-schedules-create-or-update" "global-schedules-execute" "global-schedules-retarget" "commands"] | sort) } | get name | first)
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

# Result of the request to list REST API operations
#
# GET /providers/Microsoft.DevTestLab/operations
# Returns: record<nextLink: string, value: table<display: record, name: string>>
# operationId: ProviderOperations_List
export def "provider-operations-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.DevTestLab/operations"
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List labs in a subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.DevTestLab/labs
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: Labs_ListBySubscription
export def "labs-list-by-subscription" [
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
  --expand: string # Specify the $expand query. Example: 'properties($select=defaultStorageAccount)'
  --filter: string # The filter to apply to the operation. Example: '$filter=contains(name,'myName')
  --top: int # The maximum number of resources to return from the operation. Example: '$top=10' (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation. Example: '$orderby=name desc'
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.DevTestLab/labs"
    path_params: [{name: subscriptionId, var: subscription_id}]
    query: [{name: "$expand", var: expand}, {name: "$filter", var: filter}, {name: "$top", var: top}, {name: "$orderby", var: orderby}, {name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, expand: $expand, filter: $filter, top: $top, orderby: $orderby, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get operation.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.DevTestLab/locations/{locationName}/operations/{name}
# Returns: record<error: record<code: string, message: string>, status: string, statusCode: string>
# operationId: Operations_Get
export def "operations-get" [
  subscription_id: string
  location_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.DevTestLab/locations/{locationName}/operations/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: locationName, var: location_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, location_name: $location_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List schedules in a subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.DevTestLab/schedules
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: GlobalSchedules_ListBySubscription
export def "global-schedules-list-by-subscription" [
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
  --expand: string # Specify the $expand query. Example: 'properties($select=status)'
  --filter: string # The filter to apply to the operation. Example: '$filter=contains(name,'myName')
  --top: int # The maximum number of resources to return from the operation. Example: '$top=10' (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation. Example: '$orderby=name desc'
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.DevTestLab/schedules"
    path_params: [{name: subscriptionId, var: subscription_id}]
    query: [{name: "$expand", var: expand}, {name: "$filter", var: filter}, {name: "$top", var: top}, {name: "$orderby", var: orderby}, {name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, expand: $expand, filter: $filter, top: $top, orderby: $orderby, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List labs in a resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: Labs_ListByResourceGroup
export def "labs-list-by-resource-group" [
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
  --expand: string # Specify the $expand query. Example: 'properties($select=defaultStorageAccount)'
  --filter: string # The filter to apply to the operation. Example: '$filter=contains(name,'myName')
  --top: int # The maximum number of resources to return from the operation. Example: '$top=10' (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation. Example: '$orderby=name desc'
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}]
    query: [{name: "$expand", var: expand}, {name: "$filter", var: filter}, {name: "$top", var: top}, {name: "$orderby", var: orderby}, {name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, expand: $expand, filter: $filter, top: $top, orderby: $orderby, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List artifact sources in a given lab.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/artifactsources
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: ArtifactSources_List
export def "artifact-sources-list" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=displayName)'
  --filter: string # The filter to apply to the operation. Example: '$filter=contains(name,'myName')
  --top: int # The maximum number of resources to return from the operation. Example: '$top=10' (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation. Example: '$orderby=name desc'
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/artifactsources"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}]
    query: [{name: "$expand", var: expand}, {name: "$filter", var: filter}, {name: "$top", var: top}, {name: "$orderby", var: orderby}, {name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, expand: $expand, filter: $filter, top: $top, orderby: $orderby, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List azure resource manager templates in a given artifact source.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/artifactsources/{artifactSourceName}/armtemplates
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: ArmTemplates_List
export def "arm-templates-list" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  artifact_source_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=displayName)'
  --filter: string # The filter to apply to the operation. Example: '$filter=contains(name,'myName')
  --top: int # The maximum number of resources to return from the operation. Example: '$top=10' (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation. Example: '$orderby=name desc'
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/artifactsources/{artifactSourceName}/armtemplates"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: artifactSourceName, var: artifact_source_name}]
    query: [{name: "$expand", var: expand}, {name: "$filter", var: filter}, {name: "$top", var: top}, {name: "$orderby", var: orderby}, {name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, artifact_source_name: $artifact_source_name, expand: $expand, filter: $filter, top: $top, orderby: $orderby, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get azure resource manager template.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/artifactsources/{artifactSourceName}/armtemplates/{name}
# Returns: record<properties: record<contents: record, createdDate: string, description: string, displayName: string, enabled: bool, icon: string, parametersValueFilesInfo: list<record>, publisher: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: ArmTemplates_Get
export def "arm-templates-get" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  artifact_source_name: string
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
  --expand: string # Specify the $expand query. Example: 'properties($select=displayName)'
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/artifactsources/{artifactSourceName}/armtemplates/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: artifactSourceName, var: artifact_source_name}, {name: name, var: name}]
    query: [{name: "$expand", var: expand}, {name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, artifact_source_name: $artifact_source_name, name: $name, expand: $expand, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List artifacts in a given artifact source.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/artifactsources/{artifactSourceName}/artifacts
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: Artifacts_List
export def "artifacts-list" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  artifact_source_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=title)'
  --filter: string # The filter to apply to the operation. Example: '$filter=contains(name,'myName')
  --top: int # The maximum number of resources to return from the operation. Example: '$top=10' (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation. Example: '$orderby=name desc'
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/artifactsources/{artifactSourceName}/artifacts"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: artifactSourceName, var: artifact_source_name}]
    query: [{name: "$expand", var: expand}, {name: "$filter", var: filter}, {name: "$top", var: top}, {name: "$orderby", var: orderby}, {name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, artifact_source_name: $artifact_source_name, expand: $expand, filter: $filter, top: $top, orderby: $orderby, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get artifact.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/artifactsources/{artifactSourceName}/artifacts/{name}
# Returns: record<properties: record<createdDate: string, description: string, filePath: string, icon: string, parameters: record, publisher: string, targetOsType: string, title: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: Artifacts_Get
export def "artifacts-get" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  artifact_source_name: string
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
  --expand: string # Specify the $expand query. Example: 'properties($select=title)'
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/artifactsources/{artifactSourceName}/artifacts/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: artifactSourceName, var: artifact_source_name}, {name: name, var: name}]
    query: [{name: "$expand", var: expand}, {name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, artifact_source_name: $artifact_source_name, name: $name, expand: $expand, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generates an ARM template for the given artifact, uploads the required files to a storage account, and validates the generated artifact.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/artifactsources/{artifactSourceName}/artifacts/{name}/generateArmTemplate
# Returns: record<parameters: record, template: record>
# operationId: Artifacts_GenerateArmTemplate
export def "artifacts-generate-arm-template" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  artifact_source_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
  --file-upload-options: string@file-upload-options-completer # Options for uploading the files for the artifact. UploadFilesAndGenerateSasTokens is the default value.
  --location: string # The location of the virtual machine.
  --parameters: list # The parameters of the ARM template. — item shape: {name?: string, value?: string}
  --virtual-machine-name: string # The resource name of the virtual machine.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/artifactsources/{artifactSourceName}/artifacts/{name}/generateArmTemplate"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: artifactSourceName, var: artifact_source_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: fileUploadOptions, var: file_upload_options}, {name: location, var: location}, {name: parameters, var: parameters}, {name: virtualMachineName, var: virtual_machine_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, artifact_source_name: $artifact_source_name, name: $name, api_version: $api_version, file_upload_options: $file_upload_options, location: $location, parameters: $parameters, virtual_machine_name: $virtual_machine_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete artifact source.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/artifactsources/{name}
# operationId: ArtifactSources_Delete
export def "artifact-sources-delete" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/artifactsources/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get artifact source.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/artifactsources/{name}
# Returns: record<properties: record<armTemplateFolderPath: string, branchRef: string, createdDate: string, displayName: string, folderPath: string, provisioningState: string, securityToken: string, sourceType: string, status: string, uniqueIdentifier: string, uri: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: ArtifactSources_Get
export def "artifact-sources-get" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
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
  --expand: string # Specify the $expand query. Example: 'properties($select=displayName)'
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/artifactsources/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: name, var: name}]
    query: [{name: "$expand", var: expand}, {name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, name: $name, expand: $expand, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Allows modifying tags of artifact sources. All other properties will be ignored.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/artifactsources/{name}
# Returns: record<properties: record<armTemplateFolderPath: string, branchRef: string, createdDate: string, displayName: string, folderPath: string, provisioningState: string, securityToken: string, sourceType: string, status: string, uniqueIdentifier: string, uri: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: ArtifactSources_Update
export def "artifact-sources-update" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
  --properties: record # Properties of an artifact source. — shape: {armTemplateFolderPath?: string, branchRef?: string, displayName?: string, folderPath?: string, securityToken?: string, sourceType?: "VsoGit"|"GitHub", status?: "Enabled"|"Disabled", uri?: string}
  --tags: record # The tags of the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/artifactsources/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, name: $name, api_version: $api_version, properties: $properties, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create or replace an existing artifact source.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/artifactsources/{name}
# Returns: record<properties: record<armTemplateFolderPath: string, branchRef: string, createdDate: string, displayName: string, folderPath: string, provisioningState: string, securityToken: string, sourceType: string, status: string, uniqueIdentifier: string, uri: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: ArtifactSources_CreateOrUpdate
export def "artifact-sources-create-or-update" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
  properties: record # Properties of an artifact source. — shape: {armTemplateFolderPath?: string, branchRef?: string, displayName?: string, folderPath?: string, securityToken?: string, sourceType?: "VsoGit"|"GitHub", status?: "Enabled"|"Disabled", uri?: string}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/artifactsources/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, name: $name, api_version: $api_version, properties: $properties, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get cost.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/costs/{name}
# Returns: record<properties: record<createdDate: string, currencyCode: string, endDateTime: string, labCostDetails: list<record>, labCostSummary: record<estimatedLabCost: float>, provisioningState: string, resourceCosts: list<record>, startDateTime: string, targetCost: record<costThresholds: list, cycleEndDateTime: string, cycleStartDateTime: string, cycleType: string, status: string, target: int>, uniqueIdentifier: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: Costs_Get
export def "costs-get" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
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
  --expand: string # Specify the $expand query. Example: 'properties($expand=labCostDetails)'
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/costs/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: name, var: name}]
    query: [{name: "$expand", var: expand}, {name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, name: $name, expand: $expand, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create or replace an existing cost.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/costs/{name}
# Returns: record<properties: record<createdDate: string, currencyCode: string, endDateTime: string, labCostDetails: list<record>, labCostSummary: record<estimatedLabCost: float>, provisioningState: string, resourceCosts: list<record>, startDateTime: string, targetCost: record<costThresholds: list, cycleEndDateTime: string, cycleStartDateTime: string, cycleType: string, status: string, target: int>, uniqueIdentifier: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: Costs_CreateOrUpdate
export def "costs-create-or-update" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
  properties: record # Properties of a cost item. — shape: {createdDate?: string, currencyCode?: string, endDateTime?: string, labCostSummary?: record, startDateTime?: string, targetCost?: record}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/costs/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, name: $name, api_version: $api_version, properties: $properties, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List custom images in a given lab.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/customimages
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: CustomImages_List
export def "custom-images-list" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=vm)'
  --filter: string # The filter to apply to the operation. Example: '$filter=contains(name,'myName')
  --top: int # The maximum number of resources to return from the operation. Example: '$top=10' (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation. Example: '$orderby=name desc'
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/customimages"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}]
    query: [{name: "$expand", var: expand}, {name: "$filter", var: filter}, {name: "$top", var: top}, {name: "$orderby", var: orderby}, {name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, expand: $expand, filter: $filter, top: $top, orderby: $orderby, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete custom image. This operation can take a while to complete.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/customimages/{name}
# operationId: CustomImages_Delete
export def "custom-images-delete" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/customimages/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200, 202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get custom image.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/customimages/{name}
# Returns: record<properties: record<author: string, creationDate: string, customImagePlan: record<id: string, offer: string, publisher: string>, dataDiskStorageInfo: list<record>, description: string, isPlanAuthorized: bool, managedImageId: string, managedSnapshotId: string, provisioningState: string, uniqueIdentifier: string, vhd: record<imageName: string, osType: string, sysPrep: bool>, vm: record<linuxOsInfo: record, sourceVmId: string, windowsOsInfo: record>>, id: string, location: string, name: string, tags: record, type: string>
# operationId: CustomImages_Get
export def "custom-images-get" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
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
  --expand: string # Specify the $expand query. Example: 'properties($select=vm)'
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/customimages/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: name, var: name}]
    query: [{name: "$expand", var: expand}, {name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, name: $name, expand: $expand, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Allows modifying tags of custom images. All other properties will be ignored.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/customimages/{name}
# Returns: record<properties: record<author: string, creationDate: string, customImagePlan: record<id: string, offer: string, publisher: string>, dataDiskStorageInfo: list<record>, description: string, isPlanAuthorized: bool, managedImageId: string, managedSnapshotId: string, provisioningState: string, uniqueIdentifier: string, vhd: record<imageName: string, osType: string, sysPrep: bool>, vm: record<linuxOsInfo: record, sourceVmId: string, windowsOsInfo: record>>, id: string, location: string, name: string, tags: record, type: string>
# operationId: CustomImages_Update
export def "custom-images-update" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
  --properties: record # Properties of a custom image. — shape: {author?: string, customImagePlan?: record, dataDiskStorageInfo?: list, description?: string, isPlanAuthorized?: bool, managedImageId?: string, managedSnapshotId?: string, vhd?: record, vm?: record}
  --tags: record # The tags of the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/customimages/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, name: $name, api_version: $api_version, properties: $properties, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create or replace an existing custom image. This operation can take a while to complete.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/customimages/{name}
# Returns: record<properties: record<author: string, creationDate: string, customImagePlan: record<id: string, offer: string, publisher: string>, dataDiskStorageInfo: list<record>, description: string, isPlanAuthorized: bool, managedImageId: string, managedSnapshotId: string, provisioningState: string, uniqueIdentifier: string, vhd: record<imageName: string, osType: string, sysPrep: bool>, vm: record<linuxOsInfo: record, sourceVmId: string, windowsOsInfo: record>>, id: string, location: string, name: string, tags: record, type: string>
# operationId: CustomImages_CreateOrUpdate
export def "custom-images-create-or-update" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
  properties: record # Properties of a custom image. — shape: {author?: string, customImagePlan?: record, dataDiskStorageInfo?: list, description?: string, isPlanAuthorized?: bool, managedImageId?: string, managedSnapshotId?: string, vhd?: record, vm?: record}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/customimages/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, name: $name, api_version: $api_version, properties: $properties, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List formulas in a given lab.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/formulas
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: Formulas_List
export def "formulas-list" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=description)'
  --filter: string # The filter to apply to the operation. Example: '$filter=contains(name,'myName')
  --top: int # The maximum number of resources to return from the operation. Example: '$top=10' (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation. Example: '$orderby=name desc'
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/formulas"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}]
    query: [{name: "$expand", var: expand}, {name: "$filter", var: filter}, {name: "$top", var: top}, {name: "$orderby", var: orderby}, {name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, expand: $expand, filter: $filter, top: $top, orderby: $orderby, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete formula.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/formulas/{name}
# operationId: Formulas_Delete
export def "formulas-delete" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/formulas/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get formula.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/formulas/{name}
# Returns: record<properties: record<author: string, creationDate: string, description: string, formulaContent: record<location: string, name: string, properties: record, tags: record>, osType: string, provisioningState: string, uniqueIdentifier: string, vm: record<labVmId: string>>, id: string, location: string, name: string, tags: record, type: string>
# operationId: Formulas_Get
export def "formulas-get" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
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
  --expand: string # Specify the $expand query. Example: 'properties($select=description)'
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/formulas/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: name, var: name}]
    query: [{name: "$expand", var: expand}, {name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, name: $name, expand: $expand, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Allows modifying tags of formulas. All other properties will be ignored.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/formulas/{name}
# Returns: record<properties: record<author: string, creationDate: string, description: string, formulaContent: record<location: string, name: string, properties: record, tags: record>, osType: string, provisioningState: string, uniqueIdentifier: string, vm: record<labVmId: string>>, id: string, location: string, name: string, tags: record, type: string>
# operationId: Formulas_Update
export def "formulas-update" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
  --properties: record # Properties of a formula. — shape: {author?: string, description?: string, formulaContent?: record, osType?: string, vm?: record}
  --tags: record # The tags of the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/formulas/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, name: $name, api_version: $api_version, properties: $properties, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create or replace an existing formula. This operation can take a while to complete.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/formulas/{name}
# Returns: record<properties: record<author: string, creationDate: string, description: string, formulaContent: record<location: string, name: string, properties: record, tags: record>, osType: string, provisioningState: string, uniqueIdentifier: string, vm: record<labVmId: string>>, id: string, location: string, name: string, tags: record, type: string>
# operationId: Formulas_CreateOrUpdate
export def "formulas-create-or-update" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
  properties: record # Properties of a formula. — shape: {author?: string, description?: string, formulaContent?: record, osType?: string, vm?: record}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/formulas/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, name: $name, api_version: $api_version, properties: $properties, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List gallery images in a given lab.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/galleryimages
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: GalleryImages_List
export def "gallery-images-list" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=author)'
  --filter: string # The filter to apply to the operation. Example: '$filter=contains(name,'myName')
  --top: int # The maximum number of resources to return from the operation. Example: '$top=10' (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation. Example: '$orderby=name desc'
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/galleryimages"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}]
    query: [{name: "$expand", var: expand}, {name: "$filter", var: filter}, {name: "$top", var: top}, {name: "$orderby", var: orderby}, {name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, expand: $expand, filter: $filter, top: $top, orderby: $orderby, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List notification channels in a given lab.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/notificationchannels
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: NotificationChannels_List
export def "notification-channels-list" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=webHookUrl)'
  --filter: string # The filter to apply to the operation. Example: '$filter=contains(name,'myName')
  --top: int # The maximum number of resources to return from the operation. Example: '$top=10' (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation. Example: '$orderby=name desc'
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/notificationchannels"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}]
    query: [{name: "$expand", var: expand}, {name: "$filter", var: filter}, {name: "$top", var: top}, {name: "$orderby", var: orderby}, {name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, expand: $expand, filter: $filter, top: $top, orderby: $orderby, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete notification channel.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/notificationchannels/{name}
# operationId: NotificationChannels_Delete
export def "notification-channels-delete" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/notificationchannels/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get notification channel.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/notificationchannels/{name}
# Returns: record<properties: record<createdDate: string, description: string, emailRecipient: string, events: list<record>, notificationLocale: string, provisioningState: string, uniqueIdentifier: string, webHookUrl: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: NotificationChannels_Get
export def "notification-channels-get" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
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
  --expand: string # Specify the $expand query. Example: 'properties($select=webHookUrl)'
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/notificationchannels/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: name, var: name}]
    query: [{name: "$expand", var: expand}, {name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, name: $name, expand: $expand, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Allows modifying tags of notification channels. All other properties will be ignored.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/notificationchannels/{name}
# Returns: record<properties: record<createdDate: string, description: string, emailRecipient: string, events: list<record>, notificationLocale: string, provisioningState: string, uniqueIdentifier: string, webHookUrl: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: NotificationChannels_Update
export def "notification-channels-update" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
  --properties: record # Properties of a schedule. — shape: {description?: string, emailRecipient?: string, events?: list, notificationLocale?: string, webHookUrl?: string}
  --tags: record # The tags of the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/notificationchannels/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, name: $name, api_version: $api_version, properties: $properties, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create or replace an existing notification channel.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/notificationchannels/{name}
# Returns: record<properties: record<createdDate: string, description: string, emailRecipient: string, events: list<record>, notificationLocale: string, provisioningState: string, uniqueIdentifier: string, webHookUrl: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: NotificationChannels_CreateOrUpdate
export def "notification-channels-create-or-update" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
  properties: record # Properties of a schedule. — shape: {description?: string, emailRecipient?: string, events?: list, notificationLocale?: string, webHookUrl?: string}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/notificationchannels/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, name: $name, api_version: $api_version, properties: $properties, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send notification to provided channel.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/notificationchannels/{name}/notify
# operationId: NotificationChannels_Notify
export def "notification-channels-notify" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
  --event-name: string@event-name-completer # The type of event (i.e. AutoShutdown, Cost)
  --json-payload: string # Properties for the notification in json format.
]: any -> any {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/notificationchannels/{name}/notify"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: eventName, var: event_name}, {name: jsonPayload, var: json_payload}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, name: $name, api_version: $api_version, event_name: $event_name, json_payload: $json_payload
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Evaluates lab policy.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/policysets/{name}/evaluatePolicies
# Returns: record<results: table<hasError: bool, policyViolations: list>>
# operationId: PolicySets_EvaluatePolicies
export def "policy-sets-evaluate-policies" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
  --policies: list # Policies to evaluate. — item shape: {factData?: string, factName?: string, userObjectId?: string, valueOffset?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/policysets/{name}/evaluatePolicies"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: policies, var: policies}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, name: $name, api_version: $api_version, policies: $policies
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List policies in a given policy set.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/policysets/{policySetName}/policies
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: Policies_List
export def "policies-list" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  policy_set_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=description)'
  --filter: string # The filter to apply to the operation. Example: '$filter=contains(name,'myName')
  --top: int # The maximum number of resources to return from the operation. Example: '$top=10' (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation. Example: '$orderby=name desc'
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/policysets/{policySetName}/policies"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: policySetName, var: policy_set_name}]
    query: [{name: "$expand", var: expand}, {name: "$filter", var: filter}, {name: "$top", var: top}, {name: "$orderby", var: orderby}, {name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, policy_set_name: $policy_set_name, expand: $expand, filter: $filter, top: $top, orderby: $orderby, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete policy.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/policysets/{policySetName}/policies/{name}
# operationId: Policies_Delete
export def "policies-delete" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  policy_set_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/policysets/{policySetName}/policies/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: policySetName, var: policy_set_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, policy_set_name: $policy_set_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get policy.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/policysets/{policySetName}/policies/{name}
# Returns: record<properties: record<createdDate: string, description: string, evaluatorType: string, factData: string, factName: string, provisioningState: string, status: string, threshold: string, uniqueIdentifier: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: Policies_Get
export def "policies-get" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  policy_set_name: string
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
  --expand: string # Specify the $expand query. Example: 'properties($select=description)'
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/policysets/{policySetName}/policies/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: policySetName, var: policy_set_name}, {name: name, var: name}]
    query: [{name: "$expand", var: expand}, {name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, policy_set_name: $policy_set_name, name: $name, expand: $expand, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Allows modifying tags of policies. All other properties will be ignored.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/policysets/{policySetName}/policies/{name}
# Returns: record<properties: record<createdDate: string, description: string, evaluatorType: string, factData: string, factName: string, provisioningState: string, status: string, threshold: string, uniqueIdentifier: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: Policies_Update
export def "policies-update" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  policy_set_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
  --properties: record # Properties of a Policy. — shape: {description?: string, evaluatorType?: "AllowedValuesPolicy"|"MaxValuePolicy", factData?: string, factName?: "UserOwnedLabVmCount"|"UserOwnedLabPremiumVmCount"|"LabVmCount"|"LabPremiumVmCount"|"LabVmSize"|"GalleryImage"|"UserOwnedLabVmCountInSubnet"|"LabTargetCost"|"EnvironmentTemplate"|"ScheduleEditPermission", status?: "Enabled"|"Disabled", threshold?: string}
  --tags: record # The tags of the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/policysets/{policySetName}/policies/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: policySetName, var: policy_set_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, policy_set_name: $policy_set_name, name: $name, api_version: $api_version, properties: $properties, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create or replace an existing policy.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/policysets/{policySetName}/policies/{name}
# Returns: record<properties: record<createdDate: string, description: string, evaluatorType: string, factData: string, factName: string, provisioningState: string, status: string, threshold: string, uniqueIdentifier: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: Policies_CreateOrUpdate
export def "policies-create-or-update" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  policy_set_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
  properties: record # Properties of a Policy. — shape: {description?: string, evaluatorType?: "AllowedValuesPolicy"|"MaxValuePolicy", factData?: string, factName?: "UserOwnedLabVmCount"|"UserOwnedLabPremiumVmCount"|"LabVmCount"|"LabPremiumVmCount"|"LabVmSize"|"GalleryImage"|"UserOwnedLabVmCountInSubnet"|"LabTargetCost"|"EnvironmentTemplate"|"ScheduleEditPermission", status?: "Enabled"|"Disabled", threshold?: string}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/policysets/{policySetName}/policies/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: policySetName, var: policy_set_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, policy_set_name: $policy_set_name, name: $name, api_version: $api_version, properties: $properties, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List schedules in a given lab.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/schedules
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: Schedules_List
export def "schedules-list" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=status)'
  --filter: string # The filter to apply to the operation. Example: '$filter=contains(name,'myName')
  --top: int # The maximum number of resources to return from the operation. Example: '$top=10' (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation. Example: '$orderby=name desc'
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/schedules"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}]
    query: [{name: "$expand", var: expand}, {name: "$filter", var: filter}, {name: "$top", var: top}, {name: "$orderby", var: orderby}, {name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, expand: $expand, filter: $filter, top: $top, orderby: $orderby, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete schedule.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/schedules/{name}
# operationId: Schedules_Delete
export def "schedules-delete" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/schedules/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get schedule.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/schedules/{name}
# Returns: record<properties: record<createdDate: string, dailyRecurrence: record<time: string>, hourlyRecurrence: record<minute: int>, notificationSettings: record<emailRecipient: string, notificationLocale: string, status: string, timeInMinutes: int, webhookUrl: string>, provisioningState: string, status: string, targetResourceId: string, taskType: string, timeZoneId: string, uniqueIdentifier: string, weeklyRecurrence: record<time: string, weekdays: list>>, id: string, location: string, name: string, tags: record, type: string>
# operationId: Schedules_Get
export def "schedules-get" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
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
  --expand: string # Specify the $expand query. Example: 'properties($select=status)'
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/schedules/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: name, var: name}]
    query: [{name: "$expand", var: expand}, {name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, name: $name, expand: $expand, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Allows modifying tags of schedules. All other properties will be ignored.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/schedules/{name}
# Returns: record<properties: record<createdDate: string, dailyRecurrence: record<time: string>, hourlyRecurrence: record<minute: int>, notificationSettings: record<emailRecipient: string, notificationLocale: string, status: string, timeInMinutes: int, webhookUrl: string>, provisioningState: string, status: string, targetResourceId: string, taskType: string, timeZoneId: string, uniqueIdentifier: string, weeklyRecurrence: record<time: string, weekdays: list>>, id: string, location: string, name: string, tags: record, type: string>
# operationId: Schedules_Update
export def "schedules-update" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
  --properties: record # Properties of a schedule. — shape: {dailyRecurrence?: record, hourlyRecurrence?: record, notificationSettings?: record, status?: "Enabled"|"Disabled", targetResourceId?: string, taskType?: string, timeZoneId?: string, weeklyRecurrence?: record}
  --tags: record # The tags of the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/schedules/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, name: $name, api_version: $api_version, properties: $properties, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create or replace an existing schedule.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/schedules/{name}
# Returns: record<properties: record<createdDate: string, dailyRecurrence: record<time: string>, hourlyRecurrence: record<minute: int>, notificationSettings: record<emailRecipient: string, notificationLocale: string, status: string, timeInMinutes: int, webhookUrl: string>, provisioningState: string, status: string, targetResourceId: string, taskType: string, timeZoneId: string, uniqueIdentifier: string, weeklyRecurrence: record<time: string, weekdays: list>>, id: string, location: string, name: string, tags: record, type: string>
# operationId: Schedules_CreateOrUpdate
export def "schedules-create-or-update" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
  properties: record # Properties of a schedule. — shape: {dailyRecurrence?: record, hourlyRecurrence?: record, notificationSettings?: record, status?: "Enabled"|"Disabled", targetResourceId?: string, taskType?: string, timeZoneId?: string, weeklyRecurrence?: record}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/schedules/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, name: $name, api_version: $api_version, properties: $properties, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Execute a schedule. This operation can take a while to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/schedules/{name}/execute
# operationId: Schedules_Execute
export def "schedules-execute" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> any {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/schedules/{name}/execute"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all applicable schedules
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/schedules/{name}/listApplicable
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: Schedules_ListApplicable
export def "schedules-list-applicable" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/schedules/{name}/listApplicable"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete service runner.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/servicerunners/{name}
# operationId: ServiceRunners_Delete
export def "service-runners-delete" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/servicerunners/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get service runner.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/servicerunners/{name}
# Returns: record<identity: record<clientSecretUrl: string, principalId: string, tenantId: string, type: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: ServiceRunners_Get
export def "service-runners-get" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/servicerunners/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create or replace an existing service runner.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/servicerunners/{name}
# Returns: record<identity: record<clientSecretUrl: string, principalId: string, tenantId: string, type: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: ServiceRunners_CreateOrUpdate
export def "service-runners-create-or-update" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
  --identity: record # Properties of a managed identity — shape: {clientSecretUrl?: string, principalId?: string, tenantId?: string, type?: string}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/servicerunners/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: identity, var: identity}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, name: $name, api_version: $api_version, identity: $identity, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List user profiles in a given lab.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: Users_List
export def "users-list" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=identity)'
  --filter: string # The filter to apply to the operation. Example: '$filter=contains(name,'myName')
  --top: int # The maximum number of resources to return from the operation. Example: '$top=10' (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation. Example: '$orderby=name desc'
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}]
    query: [{name: "$expand", var: expand}, {name: "$filter", var: filter}, {name: "$top", var: top}, {name: "$orderby", var: orderby}, {name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, expand: $expand, filter: $filter, top: $top, orderby: $orderby, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete user profile. This operation can take a while to complete.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{name}
# operationId: Users_Delete
export def "users-delete" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200, 202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get user profile.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{name}
# Returns: record<properties: record<createdDate: string, identity: record<appId: string, objectId: string, principalId: string, principalName: string, tenantId: string>, provisioningState: string, secretStore: record<keyVaultId: string, keyVaultUri: string>, uniqueIdentifier: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: Users_Get
export def "users-get" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
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
  --expand: string # Specify the $expand query. Example: 'properties($select=identity)'
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: name, var: name}]
    query: [{name: "$expand", var: expand}, {name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, name: $name, expand: $expand, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Allows modifying tags of user profiles. All other properties will be ignored.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{name}
# Returns: record<properties: record<createdDate: string, identity: record<appId: string, objectId: string, principalId: string, principalName: string, tenantId: string>, provisioningState: string, secretStore: record<keyVaultId: string, keyVaultUri: string>, uniqueIdentifier: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: Users_Update
export def "users-update" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
  --properties: record # Properties of a lab user profile. — shape: {identity?: record, secretStore?: record}
  --tags: record # The tags of the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, name: $name, api_version: $api_version, properties: $properties, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create or replace an existing user profile. This operation can take a while to complete.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{name}
# Returns: record<properties: record<createdDate: string, identity: record<appId: string, objectId: string, principalId: string, principalName: string, tenantId: string>, provisioningState: string, secretStore: record<keyVaultId: string, keyVaultUri: string>, uniqueIdentifier: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: Users_CreateOrUpdate
export def "users-create-or-update" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
  --properties: record # Properties of a lab user profile. — shape: {identity?: record, secretStore?: record}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, name: $name, api_version: $api_version, properties: $properties, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List disks in a given user profile.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/disks
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: Disks_List
export def "disks-list" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  user_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=diskType)'
  --filter: string # The filter to apply to the operation. Example: '$filter=contains(name,'myName')
  --top: int # The maximum number of resources to return from the operation. Example: '$top=10' (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation. Example: '$orderby=name desc'
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/disks"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: userName, var: user_name}]
    query: [{name: "$expand", var: expand}, {name: "$filter", var: filter}, {name: "$top", var: top}, {name: "$orderby", var: orderby}, {name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, user_name: $user_name, expand: $expand, filter: $filter, top: $top, orderby: $orderby, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete disk. This operation can take a while to complete.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/disks/{name}
# operationId: Disks_Delete
export def "disks-delete" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  user_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/disks/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: userName, var: user_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200, 202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, user_name: $user_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get disk.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/disks/{name}
# Returns: record<properties: record<createdDate: string, diskBlobName: string, diskSizeGiB: int, diskType: string, diskUri: string, hostCaching: string, leasedByLabVmId: string, managedDiskId: string, provisioningState: string, uniqueIdentifier: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: Disks_Get
export def "disks-get" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  user_name: string
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
  --expand: string # Specify the $expand query. Example: 'properties($select=diskType)'
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/disks/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: userName, var: user_name}, {name: name, var: name}]
    query: [{name: "$expand", var: expand}, {name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, user_name: $user_name, name: $name, expand: $expand, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Allows modifying tags of disks. All other properties will be ignored.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/disks/{name}
# Returns: record<properties: record<createdDate: string, diskBlobName: string, diskSizeGiB: int, diskType: string, diskUri: string, hostCaching: string, leasedByLabVmId: string, managedDiskId: string, provisioningState: string, uniqueIdentifier: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: Disks_Update
export def "disks-update" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  user_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
  --properties: record # Properties of a disk. — shape: {diskBlobName?: string, diskSizeGiB?: int, diskType?: "Standard"|"Premium"|"StandardSSD", diskUri?: string, hostCaching?: string, leasedByLabVmId?: string, managedDiskId?: string}
  --tags: record # The tags of the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/disks/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: userName, var: user_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, user_name: $user_name, name: $name, api_version: $api_version, properties: $properties, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create or replace an existing disk. This operation can take a while to complete.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/disks/{name}
# Returns: record<properties: record<createdDate: string, diskBlobName: string, diskSizeGiB: int, diskType: string, diskUri: string, hostCaching: string, leasedByLabVmId: string, managedDiskId: string, provisioningState: string, uniqueIdentifier: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: Disks_CreateOrUpdate
export def "disks-create-or-update" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  user_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
  properties: record # Properties of a disk. — shape: {diskBlobName?: string, diskSizeGiB?: int, diskType?: "Standard"|"Premium"|"StandardSSD", diskUri?: string, hostCaching?: string, leasedByLabVmId?: string, managedDiskId?: string}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/disks/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: userName, var: user_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, user_name: $user_name, name: $name, api_version: $api_version, properties: $properties, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Attach and create the lease of the disk to the virtual machine. This operation can take a while to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/disks/{name}/attach
# operationId: Disks_Attach
export def "disks-attach" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  user_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
  --leased-by-lab-vm-id: string # The resource ID of the Lab virtual machine to which the disk is attached.
]: any -> any {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/disks/{name}/attach"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: userName, var: user_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: leasedByLabVmId, var: leased_by_lab_vm_id}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, user_name: $user_name, name: $name, api_version: $api_version, leased_by_lab_vm_id: $leased_by_lab_vm_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Detach and break the lease of the disk attached to the virtual machine. This operation can take a while to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/disks/{name}/detach
# operationId: Disks_Detach
export def "disks-detach" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  user_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
  --leased-by-lab-vm-id: string # The resource ID of the Lab VM to which the disk is attached.
]: any -> any {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/disks/{name}/detach"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: userName, var: user_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: leasedByLabVmId, var: leased_by_lab_vm_id}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, user_name: $user_name, name: $name, api_version: $api_version, leased_by_lab_vm_id: $leased_by_lab_vm_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List environments in a given user profile.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/environments
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: Environments_List
export def "environments-list" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  user_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=deploymentProperties)'
  --filter: string # The filter to apply to the operation. Example: '$filter=contains(name,'myName')
  --top: int # The maximum number of resources to return from the operation. Example: '$top=10' (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation. Example: '$orderby=name desc'
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/environments"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: userName, var: user_name}]
    query: [{name: "$expand", var: expand}, {name: "$filter", var: filter}, {name: "$top", var: top}, {name: "$orderby", var: orderby}, {name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, user_name: $user_name, expand: $expand, filter: $filter, top: $top, orderby: $orderby, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete environment. This operation can take a while to complete.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/environments/{name}
# operationId: Environments_Delete
export def "environments-delete" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  user_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/environments/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: userName, var: user_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200, 202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, user_name: $user_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get environment.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/environments/{name}
# Returns: record<properties: record<armTemplateDisplayName: string, createdByUser: string, deploymentProperties: record<armTemplateId: string, parameters: list>, provisioningState: string, resourceGroupId: string, uniqueIdentifier: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: Environments_Get
export def "environments-get" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  user_name: string
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
  --expand: string # Specify the $expand query. Example: 'properties($select=deploymentProperties)'
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/environments/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: userName, var: user_name}, {name: name, var: name}]
    query: [{name: "$expand", var: expand}, {name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, user_name: $user_name, name: $name, expand: $expand, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Allows modifying tags of environments. All other properties will be ignored.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/environments/{name}
# Returns: record<properties: record<armTemplateDisplayName: string, createdByUser: string, deploymentProperties: record<armTemplateId: string, parameters: list>, provisioningState: string, resourceGroupId: string, uniqueIdentifier: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: Environments_Update
export def "environments-update" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  user_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
  --properties: record # Properties of an environment. — shape: {armTemplateDisplayName?: string, deploymentProperties?: record}
  --tags: record # The tags of the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/environments/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: userName, var: user_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, user_name: $user_name, name: $name, api_version: $api_version, properties: $properties, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create or replace an existing environment. This operation can take a while to complete.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/environments/{name}
# Returns: record<properties: record<armTemplateDisplayName: string, createdByUser: string, deploymentProperties: record<armTemplateId: string, parameters: list>, provisioningState: string, resourceGroupId: string, uniqueIdentifier: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: Environments_CreateOrUpdate
export def "environments-create-or-update" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  user_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
  properties: record # Properties of an environment. — shape: {armTemplateDisplayName?: string, deploymentProperties?: record}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/environments/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: userName, var: user_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, user_name: $user_name, name: $name, api_version: $api_version, properties: $properties, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List secrets in a given user profile.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/secrets
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: Secrets_List
export def "secrets-list" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  user_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=value)'
  --filter: string # The filter to apply to the operation. Example: '$filter=contains(name,'myName')
  --top: int # The maximum number of resources to return from the operation. Example: '$top=10' (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation. Example: '$orderby=name desc'
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/secrets"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: userName, var: user_name}]
    query: [{name: "$expand", var: expand}, {name: "$filter", var: filter}, {name: "$top", var: top}, {name: "$orderby", var: orderby}, {name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, user_name: $user_name, expand: $expand, filter: $filter, top: $top, orderby: $orderby, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete secret.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/secrets/{name}
# operationId: Secrets_Delete
export def "secrets-delete" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  user_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/secrets/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: userName, var: user_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, user_name: $user_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get secret.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/secrets/{name}
# Returns: record<properties: record<provisioningState: string, uniqueIdentifier: string, value: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: Secrets_Get
export def "secrets-get" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  user_name: string
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
  --expand: string # Specify the $expand query. Example: 'properties($select=value)'
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/secrets/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: userName, var: user_name}, {name: name, var: name}]
    query: [{name: "$expand", var: expand}, {name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, user_name: $user_name, name: $name, expand: $expand, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Allows modifying tags of secrets. All other properties will be ignored.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/secrets/{name}
# Returns: record<properties: record<provisioningState: string, uniqueIdentifier: string, value: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: Secrets_Update
export def "secrets-update" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  user_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
  --properties: record # Properties of a secret. — shape: {value?: string}
  --tags: record # The tags of the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/secrets/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: userName, var: user_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, user_name: $user_name, name: $name, api_version: $api_version, properties: $properties, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create or replace an existing secret. This operation can take a while to complete.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/secrets/{name}
# Returns: record<properties: record<provisioningState: string, uniqueIdentifier: string, value: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: Secrets_CreateOrUpdate
export def "secrets-create-or-update" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  user_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
  properties: record # Properties of a secret. — shape: {value?: string}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/secrets/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: userName, var: user_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, user_name: $user_name, name: $name, api_version: $api_version, properties: $properties, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List service fabrics in a given user profile.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/servicefabrics
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: ServiceFabrics_List
export def "service-fabrics-list" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  user_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($expand=applicableSchedule)'
  --filter: string # The filter to apply to the operation. Example: '$filter=contains(name,'myName')
  --top: int # The maximum number of resources to return from the operation. Example: '$top=10' (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation. Example: '$orderby=name desc'
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/servicefabrics"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: userName, var: user_name}]
    query: [{name: "$expand", var: expand}, {name: "$filter", var: filter}, {name: "$top", var: top}, {name: "$orderby", var: orderby}, {name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, user_name: $user_name, expand: $expand, filter: $filter, top: $top, orderby: $orderby, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete service fabric. This operation can take a while to complete.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/servicefabrics/{name}
# operationId: ServiceFabrics_Delete
export def "service-fabrics-delete" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  user_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/servicefabrics/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: userName, var: user_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200, 202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, user_name: $user_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get service fabric.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/servicefabrics/{name}
# Returns: record<properties: record<applicableSchedule: record<properties: record, id: string, location: string, name: string, tags: record, type: string>, environmentId: string, externalServiceFabricId: string, provisioningState: string, uniqueIdentifier: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: ServiceFabrics_Get
export def "service-fabrics-get" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  user_name: string
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
  --expand: string # Specify the $expand query. Example: 'properties($expand=applicableSchedule)'
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/servicefabrics/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: userName, var: user_name}, {name: name, var: name}]
    query: [{name: "$expand", var: expand}, {name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, user_name: $user_name, name: $name, expand: $expand, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Allows modifying tags of service fabrics. All other properties will be ignored.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/servicefabrics/{name}
# Returns: record<properties: record<applicableSchedule: record<properties: record, id: string, location: string, name: string, tags: record, type: string>, environmentId: string, externalServiceFabricId: string, provisioningState: string, uniqueIdentifier: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: ServiceFabrics_Update
export def "service-fabrics-update" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  user_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
  --properties: record # Properties of a service fabric. — shape: {environmentId?: string, externalServiceFabricId?: string}
  --tags: record # The tags of the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/servicefabrics/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: userName, var: user_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, user_name: $user_name, name: $name, api_version: $api_version, properties: $properties, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create or replace an existing service fabric. This operation can take a while to complete.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/servicefabrics/{name}
# Returns: record<properties: record<applicableSchedule: record<properties: record, id: string, location: string, name: string, tags: record, type: string>, environmentId: string, externalServiceFabricId: string, provisioningState: string, uniqueIdentifier: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: ServiceFabrics_CreateOrUpdate
export def "service-fabrics-create-or-update" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  user_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
  properties: record # Properties of a service fabric. — shape: {applicableSchedule?: record, environmentId?: string, externalServiceFabricId?: string}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/servicefabrics/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: userName, var: user_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, user_name: $user_name, name: $name, api_version: $api_version, properties: $properties, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the applicable start/stop schedules, if any.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/servicefabrics/{name}/listApplicableSchedules
# Returns: record<properties: record<labVmsShutdown: record<properties: record, id: string, location: string, name: string, tags: record, type: string>, labVmsStartup: record<properties: record, id: string, location: string, name: string, tags: record, type: string>>, id: string, location: string, name: string, tags: record, type: string>
# operationId: ServiceFabrics_ListApplicableSchedules
export def "service-fabrics-list-applicable-schedules" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  user_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/servicefabrics/{name}/listApplicableSchedules"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: userName, var: user_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, user_name: $user_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Start a service fabric. This operation can take a while to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/servicefabrics/{name}/start
# operationId: ServiceFabrics_Start
export def "service-fabrics-start" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  user_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> any {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/servicefabrics/{name}/start"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: userName, var: user_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, user_name: $user_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stop a service fabric This operation can take a while to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/servicefabrics/{name}/stop
# operationId: ServiceFabrics_Stop
export def "service-fabrics-stop" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  user_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> any {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/servicefabrics/{name}/stop"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: userName, var: user_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, user_name: $user_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List schedules in a given service fabric.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/servicefabrics/{serviceFabricName}/schedules
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: ServiceFabricSchedules_List
export def "service-fabric-schedules-list" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  user_name: string
  service_fabric_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=status)'
  --filter: string # The filter to apply to the operation. Example: '$filter=contains(name,'myName')
  --top: int # The maximum number of resources to return from the operation. Example: '$top=10' (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation. Example: '$orderby=name desc'
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/servicefabrics/{serviceFabricName}/schedules"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: userName, var: user_name}, {name: serviceFabricName, var: service_fabric_name}]
    query: [{name: "$expand", var: expand}, {name: "$filter", var: filter}, {name: "$top", var: top}, {name: "$orderby", var: orderby}, {name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, user_name: $user_name, service_fabric_name: $service_fabric_name, expand: $expand, filter: $filter, top: $top, orderby: $orderby, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete schedule.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/servicefabrics/{serviceFabricName}/schedules/{name}
# operationId: ServiceFabricSchedules_Delete
export def "service-fabric-schedules-delete" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  user_name: string
  service_fabric_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/servicefabrics/{serviceFabricName}/schedules/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: userName, var: user_name}, {name: serviceFabricName, var: service_fabric_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, user_name: $user_name, service_fabric_name: $service_fabric_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get schedule.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/servicefabrics/{serviceFabricName}/schedules/{name}
# Returns: record<properties: record<createdDate: string, dailyRecurrence: record<time: string>, hourlyRecurrence: record<minute: int>, notificationSettings: record<emailRecipient: string, notificationLocale: string, status: string, timeInMinutes: int, webhookUrl: string>, provisioningState: string, status: string, targetResourceId: string, taskType: string, timeZoneId: string, uniqueIdentifier: string, weeklyRecurrence: record<time: string, weekdays: list>>, id: string, location: string, name: string, tags: record, type: string>
# operationId: ServiceFabricSchedules_Get
export def "service-fabric-schedules-get" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  user_name: string
  service_fabric_name: string
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
  --expand: string # Specify the $expand query. Example: 'properties($select=status)'
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/servicefabrics/{serviceFabricName}/schedules/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: userName, var: user_name}, {name: serviceFabricName, var: service_fabric_name}, {name: name, var: name}]
    query: [{name: "$expand", var: expand}, {name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, user_name: $user_name, service_fabric_name: $service_fabric_name, name: $name, expand: $expand, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Allows modifying tags of schedules. All other properties will be ignored.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/servicefabrics/{serviceFabricName}/schedules/{name}
# Returns: record<properties: record<createdDate: string, dailyRecurrence: record<time: string>, hourlyRecurrence: record<minute: int>, notificationSettings: record<emailRecipient: string, notificationLocale: string, status: string, timeInMinutes: int, webhookUrl: string>, provisioningState: string, status: string, targetResourceId: string, taskType: string, timeZoneId: string, uniqueIdentifier: string, weeklyRecurrence: record<time: string, weekdays: list>>, id: string, location: string, name: string, tags: record, type: string>
# operationId: ServiceFabricSchedules_Update
export def "service-fabric-schedules-update" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  user_name: string
  service_fabric_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
  --properties: record # Properties of a schedule. — shape: {dailyRecurrence?: record, hourlyRecurrence?: record, notificationSettings?: record, status?: "Enabled"|"Disabled", targetResourceId?: string, taskType?: string, timeZoneId?: string, weeklyRecurrence?: record}
  --tags: record # The tags of the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/servicefabrics/{serviceFabricName}/schedules/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: userName, var: user_name}, {name: serviceFabricName, var: service_fabric_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, user_name: $user_name, service_fabric_name: $service_fabric_name, name: $name, api_version: $api_version, properties: $properties, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create or replace an existing schedule.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/servicefabrics/{serviceFabricName}/schedules/{name}
# Returns: record<properties: record<createdDate: string, dailyRecurrence: record<time: string>, hourlyRecurrence: record<minute: int>, notificationSettings: record<emailRecipient: string, notificationLocale: string, status: string, timeInMinutes: int, webhookUrl: string>, provisioningState: string, status: string, targetResourceId: string, taskType: string, timeZoneId: string, uniqueIdentifier: string, weeklyRecurrence: record<time: string, weekdays: list>>, id: string, location: string, name: string, tags: record, type: string>
# operationId: ServiceFabricSchedules_CreateOrUpdate
export def "service-fabric-schedules-create-or-update" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  user_name: string
  service_fabric_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
  properties: record # Properties of a schedule. — shape: {dailyRecurrence?: record, hourlyRecurrence?: record, notificationSettings?: record, status?: "Enabled"|"Disabled", targetResourceId?: string, taskType?: string, timeZoneId?: string, weeklyRecurrence?: record}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/servicefabrics/{serviceFabricName}/schedules/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: userName, var: user_name}, {name: serviceFabricName, var: service_fabric_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, user_name: $user_name, service_fabric_name: $service_fabric_name, name: $name, api_version: $api_version, properties: $properties, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Execute a schedule. This operation can take a while to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/servicefabrics/{serviceFabricName}/schedules/{name}/execute
# operationId: ServiceFabricSchedules_Execute
export def "service-fabric-schedules-execute" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  user_name: string
  service_fabric_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> any {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/servicefabrics/{serviceFabricName}/schedules/{name}/execute"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: userName, var: user_name}, {name: serviceFabricName, var: service_fabric_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, user_name: $user_name, service_fabric_name: $service_fabric_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List virtual machines in a given lab.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: VirtualMachines_List
export def "virtual-machines-list" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($expand=artifacts,computeVm,networkInterface,applicableSchedule)'
  --filter: string # The filter to apply to the operation. Example: '$filter=contains(name,'myName')
  --top: int # The maximum number of resources to return from the operation. Example: '$top=10' (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation. Example: '$orderby=name desc'
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}]
    query: [{name: "$expand", var: expand}, {name: "$filter", var: filter}, {name: "$top", var: top}, {name: "$orderby", var: orderby}, {name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, expand: $expand, filter: $filter, top: $top, orderby: $orderby, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete virtual machine. This operation can take a while to complete.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{name}
# operationId: VirtualMachines_Delete
export def "virtual-machines-delete" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200, 202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get virtual machine.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{name}
# Returns: record<properties: record<allowClaim: bool, applicableSchedule: record<properties: record, id: string, location: string, name: string, tags: record, type: string>, artifactDeploymentStatus: record<artifactsApplied: int, deploymentStatus: string, totalArtifacts: int>, artifacts: list<record>, computeId: string, computeVm: record<dataDiskIds: list, dataDisks: list, networkInterfaceId: string, osDiskId: string, osType: string, statuses: list, vmSize: string>, createdByUser: string, createdByUserId: string, createdDate: string, customImageId: string, dataDiskParameters: list<record>, disallowPublicIpAddress: bool, environmentId: string, expirationDate: string, fqdn: string, galleryImageReference: record<offer: string, osType: string, publisher: string, sku: string, version: string>, isAuthenticationWithSshKey: bool, labSubnetName: string, labVirtualNetworkId: string, lastKnownPowerState: string, networkInterface: record<dnsName: string, privateIpAddress: string, publicIpAddress: string, publicIpAddressId: string, rdpAuthority: string, sharedPublicIpAddressConfiguration: record, sshAuthority: string, subnetId: string, virtualNetworkId: string>, notes: string, osType: string, ownerObjectId: string, ownerUserPrincipalName: string, password: string, planId: string, provisioningState: string, scheduleParameters: list<record>, size: string, sshKey: string, storageType: string, uniqueIdentifier: string, userName: string, virtualMachineCreationSource: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: VirtualMachines_Get
export def "virtual-machines-get" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
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
  --expand: string # Specify the $expand query. Example: 'properties($expand=artifacts,computeVm,networkInterface,applicableSchedule)'
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: name, var: name}]
    query: [{name: "$expand", var: expand}, {name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, name: $name, expand: $expand, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Allows modifying tags of virtual machines. All other properties will be ignored.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{name}
# Returns: record<properties: record<allowClaim: bool, applicableSchedule: record<properties: record, id: string, location: string, name: string, tags: record, type: string>, artifactDeploymentStatus: record<artifactsApplied: int, deploymentStatus: string, totalArtifacts: int>, artifacts: list<record>, computeId: string, computeVm: record<dataDiskIds: list, dataDisks: list, networkInterfaceId: string, osDiskId: string, osType: string, statuses: list, vmSize: string>, createdByUser: string, createdByUserId: string, createdDate: string, customImageId: string, dataDiskParameters: list<record>, disallowPublicIpAddress: bool, environmentId: string, expirationDate: string, fqdn: string, galleryImageReference: record<offer: string, osType: string, publisher: string, sku: string, version: string>, isAuthenticationWithSshKey: bool, labSubnetName: string, labVirtualNetworkId: string, lastKnownPowerState: string, networkInterface: record<dnsName: string, privateIpAddress: string, publicIpAddress: string, publicIpAddressId: string, rdpAuthority: string, sharedPublicIpAddressConfiguration: record, sshAuthority: string, subnetId: string, virtualNetworkId: string>, notes: string, osType: string, ownerObjectId: string, ownerUserPrincipalName: string, password: string, planId: string, provisioningState: string, scheduleParameters: list<record>, size: string, sshKey: string, storageType: string, uniqueIdentifier: string, userName: string, virtualMachineCreationSource: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: VirtualMachines_Update
export def "virtual-machines-update" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
  --properties: record # Properties of a virtual machine. — shape: {allowClaim?: bool, artifactDeploymentStatus?: record, artifacts?: list, computeId?: string, createdByUser?: string, createdByUserId?: string, createdDate?: string, customImageId?: string, dataDiskParameters?: list, disallowPublicIpAddress?: bool, environmentId?: string, expirationDate?: string, fqdn?: string, galleryImageReference?: record, isAuthenticationWithSshKey?: bool, labSubnetName?: string, labVirtualNetworkId?: string, lastKnownPowerState?: string, networkInterface?: record, ... (12 more fields)}
  --tags: record # The tags of the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, name: $name, api_version: $api_version, properties: $properties, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create or replace an existing virtual machine. This operation can take a while to complete.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{name}
# Returns: record<properties: record<allowClaim: bool, applicableSchedule: record<properties: record, id: string, location: string, name: string, tags: record, type: string>, artifactDeploymentStatus: record<artifactsApplied: int, deploymentStatus: string, totalArtifacts: int>, artifacts: list<record>, computeId: string, computeVm: record<dataDiskIds: list, dataDisks: list, networkInterfaceId: string, osDiskId: string, osType: string, statuses: list, vmSize: string>, createdByUser: string, createdByUserId: string, createdDate: string, customImageId: string, dataDiskParameters: list<record>, disallowPublicIpAddress: bool, environmentId: string, expirationDate: string, fqdn: string, galleryImageReference: record<offer: string, osType: string, publisher: string, sku: string, version: string>, isAuthenticationWithSshKey: bool, labSubnetName: string, labVirtualNetworkId: string, lastKnownPowerState: string, networkInterface: record<dnsName: string, privateIpAddress: string, publicIpAddress: string, publicIpAddressId: string, rdpAuthority: string, sharedPublicIpAddressConfiguration: record, sshAuthority: string, subnetId: string, virtualNetworkId: string>, notes: string, osType: string, ownerObjectId: string, ownerUserPrincipalName: string, password: string, planId: string, provisioningState: string, scheduleParameters: list<record>, size: string, sshKey: string, storageType: string, uniqueIdentifier: string, userName: string, virtualMachineCreationSource: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: VirtualMachines_CreateOrUpdate
export def "virtual-machines-create-or-update" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
  properties: record # Properties of a virtual machine. — shape: {allowClaim?: bool, applicableSchedule?: record, artifactDeploymentStatus?: record, artifacts?: list, computeId?: string, computeVm?: record, createdByUser?: string, createdByUserId?: string, createdDate?: string, customImageId?: string, dataDiskParameters?: list, disallowPublicIpAddress?: bool, environmentId?: string, expirationDate?: string, fqdn?: string, galleryImageReference?: record, isAuthenticationWithSshKey?: bool, labSubnetName?: string, labVirtualNetworkId?: string, ... (14 more fields)}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, name: $name, api_version: $api_version, properties: $properties, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Attach a new or existing data disk to virtual machine. This operation can take a while to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{name}/addDataDisk
# operationId: VirtualMachines_AddDataDisk
export def "virtual-machines-add-data-disk" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
  --attach-new-data-disk-options: record # Properties to attach new disk to the Virtual Machine. — shape: {diskName?: string, diskSizeGiB?: int, diskType?: "Standard"|"Premium"|"StandardSSD"}
  --existing-lab-disk-id: string # Specifies the existing lab disk id to attach to virtual machine.
  --host-caching: string@host-caching-completer # Caching option for a data disk (i.e. None, ReadOnly, ReadWrite).
]: any -> any {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{name}/addDataDisk"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: attachNewDataDiskOptions, var: attach_new_data_disk_options}, {name: existingLabDiskId, var: existing_lab_disk_id}, {name: hostCaching, var: host_caching}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, name: $name, api_version: $api_version, attach_new_data_disk_options: $attach_new_data_disk_options, existing_lab_disk_id: $existing_lab_disk_id, host_caching: $host_caching
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Apply artifacts to virtual machine. This operation can take a while to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{name}/applyArtifacts
# operationId: VirtualMachines_ApplyArtifacts
export def "virtual-machines-apply-artifacts" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
  --artifacts: list # The list of artifacts to apply. — item shape: {artifactId?: string, artifactTitle?: string, deploymentStatusMessage?: string, installTime?: string, parameters?: list, status?: string, vmExtensionStatusMessage?: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{name}/applyArtifacts"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: artifacts, var: artifacts}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, name: $name, api_version: $api_version, artifacts: $artifacts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Take ownership of an existing virtual machine This operation can take a while to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{name}/claim
# operationId: VirtualMachines_Claim
export def "virtual-machines-claim" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> any {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{name}/claim"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Detach the specified disk from the virtual machine. This operation can take a while to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{name}/detachDataDisk
# operationId: VirtualMachines_DetachDataDisk
export def "virtual-machines-detach-data-disk" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
  --existing-lab-disk-id: string # Specifies the disk resource ID to detach from virtual machine.
]: any -> any {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{name}/detachDataDisk"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: existingLabDiskId, var: existing_lab_disk_id}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, name: $name, api_version: $api_version, existing_lab_disk_id: $existing_lab_disk_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a string that represents the contents of the RDP file for the virtual machine
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{name}/getRdpFileContents
# Returns: record<contents: string>
# operationId: VirtualMachines_GetRdpFileContents
export def "virtual-machines-get-rdp-file-contents" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{name}/getRdpFileContents"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the applicable start/stop schedules, if any.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{name}/listApplicableSchedules
# Returns: record<properties: record<labVmsShutdown: record<properties: record, id: string, location: string, name: string, tags: record, type: string>, labVmsStartup: record<properties: record, id: string, location: string, name: string, tags: record, type: string>>, id: string, location: string, name: string, tags: record, type: string>
# operationId: VirtualMachines_ListApplicableSchedules
export def "virtual-machines-list-applicable-schedules" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{name}/listApplicableSchedules"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Redeploy a virtual machine This operation can take a while to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{name}/redeploy
# operationId: VirtualMachines_Redeploy
export def "virtual-machines-redeploy" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> any {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{name}/redeploy"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resize Virtual Machine. This operation can take a while to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{name}/resize
# operationId: VirtualMachines_Resize
export def "virtual-machines-resize" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
  --size: string # Specifies the size of the virtual machine.
]: any -> any {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{name}/resize"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: size, var: size}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, name: $name, api_version: $api_version, size: $size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Restart a virtual machine. This operation can take a while to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{name}/restart
# operationId: VirtualMachines_Restart
export def "virtual-machines-restart" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> any {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{name}/restart"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Start a virtual machine. This operation can take a while to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{name}/start
# operationId: VirtualMachines_Start
export def "virtual-machines-start" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> any {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{name}/start"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stop a virtual machine This operation can take a while to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{name}/stop
# operationId: VirtualMachines_Stop
export def "virtual-machines-stop" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> any {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{name}/stop"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Transfers all data disks attached to the virtual machine to be owned by the current user. This operation can take a while to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{name}/transferDisks
# operationId: VirtualMachines_TransferDisks
export def "virtual-machines-transfer-disks" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> any {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{name}/transferDisks"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Release ownership of an existing virtual machine This operation can take a while to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{name}/unClaim
# operationId: VirtualMachines_UnClaim
export def "virtual-machines-un-claim" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> any {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{name}/unClaim"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List schedules in a given virtual machine.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{virtualMachineName}/schedules
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: VirtualMachineSchedules_List
export def "virtual-machine-schedules-list" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  virtual_machine_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=status)'
  --filter: string # The filter to apply to the operation. Example: '$filter=contains(name,'myName')
  --top: int # The maximum number of resources to return from the operation. Example: '$top=10' (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation. Example: '$orderby=name desc'
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{virtualMachineName}/schedules"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: virtualMachineName, var: virtual_machine_name}]
    query: [{name: "$expand", var: expand}, {name: "$filter", var: filter}, {name: "$top", var: top}, {name: "$orderby", var: orderby}, {name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, virtual_machine_name: $virtual_machine_name, expand: $expand, filter: $filter, top: $top, orderby: $orderby, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete schedule.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{virtualMachineName}/schedules/{name}
# operationId: VirtualMachineSchedules_Delete
export def "virtual-machine-schedules-delete" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  virtual_machine_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{virtualMachineName}/schedules/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: virtualMachineName, var: virtual_machine_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, virtual_machine_name: $virtual_machine_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get schedule.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{virtualMachineName}/schedules/{name}
# Returns: record<properties: record<createdDate: string, dailyRecurrence: record<time: string>, hourlyRecurrence: record<minute: int>, notificationSettings: record<emailRecipient: string, notificationLocale: string, status: string, timeInMinutes: int, webhookUrl: string>, provisioningState: string, status: string, targetResourceId: string, taskType: string, timeZoneId: string, uniqueIdentifier: string, weeklyRecurrence: record<time: string, weekdays: list>>, id: string, location: string, name: string, tags: record, type: string>
# operationId: VirtualMachineSchedules_Get
export def "virtual-machine-schedules-get" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  virtual_machine_name: string
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
  --expand: string # Specify the $expand query. Example: 'properties($select=status)'
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{virtualMachineName}/schedules/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: virtualMachineName, var: virtual_machine_name}, {name: name, var: name}]
    query: [{name: "$expand", var: expand}, {name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, virtual_machine_name: $virtual_machine_name, name: $name, expand: $expand, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Allows modifying tags of schedules. All other properties will be ignored.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{virtualMachineName}/schedules/{name}
# Returns: record<properties: record<createdDate: string, dailyRecurrence: record<time: string>, hourlyRecurrence: record<minute: int>, notificationSettings: record<emailRecipient: string, notificationLocale: string, status: string, timeInMinutes: int, webhookUrl: string>, provisioningState: string, status: string, targetResourceId: string, taskType: string, timeZoneId: string, uniqueIdentifier: string, weeklyRecurrence: record<time: string, weekdays: list>>, id: string, location: string, name: string, tags: record, type: string>
# operationId: VirtualMachineSchedules_Update
export def "virtual-machine-schedules-update" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  virtual_machine_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
  --properties: record # Properties of a schedule. — shape: {dailyRecurrence?: record, hourlyRecurrence?: record, notificationSettings?: record, status?: "Enabled"|"Disabled", targetResourceId?: string, taskType?: string, timeZoneId?: string, weeklyRecurrence?: record}
  --tags: record # The tags of the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{virtualMachineName}/schedules/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: virtualMachineName, var: virtual_machine_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, virtual_machine_name: $virtual_machine_name, name: $name, api_version: $api_version, properties: $properties, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create or replace an existing schedule.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{virtualMachineName}/schedules/{name}
# Returns: record<properties: record<createdDate: string, dailyRecurrence: record<time: string>, hourlyRecurrence: record<minute: int>, notificationSettings: record<emailRecipient: string, notificationLocale: string, status: string, timeInMinutes: int, webhookUrl: string>, provisioningState: string, status: string, targetResourceId: string, taskType: string, timeZoneId: string, uniqueIdentifier: string, weeklyRecurrence: record<time: string, weekdays: list>>, id: string, location: string, name: string, tags: record, type: string>
# operationId: VirtualMachineSchedules_CreateOrUpdate
export def "virtual-machine-schedules-create-or-update" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  virtual_machine_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
  properties: record # Properties of a schedule. — shape: {dailyRecurrence?: record, hourlyRecurrence?: record, notificationSettings?: record, status?: "Enabled"|"Disabled", targetResourceId?: string, taskType?: string, timeZoneId?: string, weeklyRecurrence?: record}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{virtualMachineName}/schedules/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: virtualMachineName, var: virtual_machine_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, virtual_machine_name: $virtual_machine_name, name: $name, api_version: $api_version, properties: $properties, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Execute a schedule. This operation can take a while to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{virtualMachineName}/schedules/{name}/execute
# operationId: VirtualMachineSchedules_Execute
export def "virtual-machine-schedules-execute" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  virtual_machine_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> any {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{virtualMachineName}/schedules/{name}/execute"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: virtualMachineName, var: virtual_machine_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, virtual_machine_name: $virtual_machine_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List virtual networks in a given lab.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualnetworks
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: VirtualNetworks_List
export def "virtual-networks-list" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($expand=externalSubnets)'
  --filter: string # The filter to apply to the operation. Example: '$filter=contains(name,'myName')
  --top: int # The maximum number of resources to return from the operation. Example: '$top=10' (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation. Example: '$orderby=name desc'
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualnetworks"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}]
    query: [{name: "$expand", var: expand}, {name: "$filter", var: filter}, {name: "$top", var: top}, {name: "$orderby", var: orderby}, {name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, expand: $expand, filter: $filter, top: $top, orderby: $orderby, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete virtual network. This operation can take a while to complete.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualnetworks/{name}
# operationId: VirtualNetworks_Delete
export def "virtual-networks-delete" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualnetworks/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200, 202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get virtual network.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualnetworks/{name}
# Returns: record<properties: record<allowedSubnets: list<record>, createdDate: string, description: string, externalProviderResourceId: string, externalSubnets: list<record>, provisioningState: string, subnetOverrides: list<record>, uniqueIdentifier: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: VirtualNetworks_Get
export def "virtual-networks-get" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
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
  --expand: string # Specify the $expand query. Example: 'properties($expand=externalSubnets)'
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualnetworks/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: name, var: name}]
    query: [{name: "$expand", var: expand}, {name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, name: $name, expand: $expand, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Allows modifying tags of virtual networks. All other properties will be ignored.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualnetworks/{name}
# Returns: record<properties: record<allowedSubnets: list<record>, createdDate: string, description: string, externalProviderResourceId: string, externalSubnets: list<record>, provisioningState: string, subnetOverrides: list<record>, uniqueIdentifier: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: VirtualNetworks_Update
export def "virtual-networks-update" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
  --properties: record # Properties of a virtual network. — shape: {allowedSubnets?: list, description?: string, externalProviderResourceId?: string, subnetOverrides?: list}
  --tags: record # The tags of the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualnetworks/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, name: $name, api_version: $api_version, properties: $properties, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create or replace an existing virtual network. This operation can take a while to complete.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualnetworks/{name}
# Returns: record<properties: record<allowedSubnets: list<record>, createdDate: string, description: string, externalProviderResourceId: string, externalSubnets: list<record>, provisioningState: string, subnetOverrides: list<record>, uniqueIdentifier: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: VirtualNetworks_CreateOrUpdate
export def "virtual-networks-create-or-update" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
  --properties: record # Properties of a virtual network. — shape: {allowedSubnets?: list, description?: string, externalProviderResourceId?: string, subnetOverrides?: list}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualnetworks/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labName, var: lab_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_name: $lab_name, name: $name, api_version: $api_version, properties: $properties, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete lab. This operation can take a while to complete.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{name}
# operationId: Labs_Delete
export def "labs-delete" [
  subscription_id: string
  resource_group_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200, 202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get lab.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{name}
# Returns: record<properties: record<announcement: record<enabled: string, expirationDate: string, expired: bool, markdown: string, provisioningState: string, title: string, uniqueIdentifier: string>, artifactsStorageAccount: string, createdDate: string, defaultPremiumStorageAccount: string, defaultStorageAccount: string, environmentPermission: string, extendedProperties: record, labStorageType: string, loadBalancerId: string, mandatoryArtifactsResourceIdsLinux: list<string>, mandatoryArtifactsResourceIdsWindows: list<string>, networkSecurityGroupId: string, premiumDataDiskStorageAccount: string, premiumDataDisks: string, provisioningState: string, publicIpId: string, support: record<enabled: string, markdown: string>, uniqueIdentifier: string, vaultName: string, vmCreationResourceGroup: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: Labs_Get
export def "labs-get" [
  subscription_id: string
  resource_group_name: string
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
  --expand: string # Specify the $expand query. Example: 'properties($select=defaultStorageAccount)'
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: "$expand", var: expand}, {name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, expand: $expand, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Allows modifying tags of labs. All other properties will be ignored.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{name}
# Returns: record<properties: record<announcement: record<enabled: string, expirationDate: string, expired: bool, markdown: string, provisioningState: string, title: string, uniqueIdentifier: string>, artifactsStorageAccount: string, createdDate: string, defaultPremiumStorageAccount: string, defaultStorageAccount: string, environmentPermission: string, extendedProperties: record, labStorageType: string, loadBalancerId: string, mandatoryArtifactsResourceIdsLinux: list<string>, mandatoryArtifactsResourceIdsWindows: list<string>, networkSecurityGroupId: string, premiumDataDiskStorageAccount: string, premiumDataDisks: string, provisioningState: string, publicIpId: string, support: record<enabled: string, markdown: string>, uniqueIdentifier: string, vaultName: string, vmCreationResourceGroup: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: Labs_Update
export def "labs-update" [
  subscription_id: string
  resource_group_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
  --properties: record # Properties of a lab. — shape: {announcement?: record, environmentPermission?: "Reader"|"Contributor", extendedProperties?: record, labStorageType?: "Standard"|"Premium"|"StandardSSD", mandatoryArtifactsResourceIdsLinux?: list<string>, mandatoryArtifactsResourceIdsWindows?: list<string>, premiumDataDisks?: "Disabled"|"Enabled", support?: record}
  --tags: record # The tags of the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version, properties: $properties, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create or replace an existing lab. This operation can take a while to complete.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{name}
# Returns: record<properties: record<announcement: record<enabled: string, expirationDate: string, expired: bool, markdown: string, provisioningState: string, title: string, uniqueIdentifier: string>, artifactsStorageAccount: string, createdDate: string, defaultPremiumStorageAccount: string, defaultStorageAccount: string, environmentPermission: string, extendedProperties: record, labStorageType: string, loadBalancerId: string, mandatoryArtifactsResourceIdsLinux: list<string>, mandatoryArtifactsResourceIdsWindows: list<string>, networkSecurityGroupId: string, premiumDataDiskStorageAccount: string, premiumDataDisks: string, provisioningState: string, publicIpId: string, support: record<enabled: string, markdown: string>, uniqueIdentifier: string, vaultName: string, vmCreationResourceGroup: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: Labs_CreateOrUpdate
export def "labs-create-or-update" [
  subscription_id: string
  resource_group_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
  --properties: record # Properties of a lab. — shape: {announcement?: record, environmentPermission?: "Reader"|"Contributor", extendedProperties?: record, labStorageType?: "Standard"|"Premium"|"StandardSSD", mandatoryArtifactsResourceIdsLinux?: list<string>, mandatoryArtifactsResourceIdsWindows?: list<string>, premiumDataDisks?: "Disabled"|"Enabled", support?: record}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version, properties: $properties, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Claim a random claimable virtual machine in the lab. This operation can take a while to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{name}/claimAnyVm
# operationId: Labs_ClaimAnyVm
export def "labs-claim-any-vm" [
  subscription_id: string
  resource_group_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> any {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{name}/claimAnyVm"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create virtual machines in a lab. This operation can take a while to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{name}/createEnvironment
# operationId: Labs_CreateEnvironment
export def "labs-create-environment" [
  subscription_id: string
  resource_group_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
  --location: string # The location of the new virtual machine or environment
  --body-name: string # The name of the virtual machine or environment (spec name: name)
  --properties: record # Properties for virtual machine creation. — shape: {allowClaim?: bool, artifactDeploymentStatus?: record, artifacts?: list, bulkCreationParameters?: record, computeId?: string, createdByUser?: string, createdByUserId?: string, createdDate?: string, customImageId?: string, dataDiskParameters?: list, disallowPublicIpAddress?: bool, environmentId?: string, expirationDate?: string, fqdn?: string, galleryImageReference?: record, isAuthenticationWithSshKey?: bool, labSubnetName?: string, labVirtualNetworkId?: string, lastKnownPowerState?: string, ... (13 more fields)}
  --tags: record # The tags of the resource.
]: any -> any {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{name}/createEnvironment"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: location, var: location}, {name: name, var: body_name}, {name: properties, var: properties}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version, location: $location, body_name: $body_name, properties: $properties, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Exports the lab resource usage into a storage account This operation can take a while to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{name}/exportResourceUsage
# operationId: Labs_ExportResourceUsage
export def "labs-export-resource-usage" [
  subscription_id: string
  resource_group_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
  --blob-storage-absolute-sas-uri: string # The blob storage absolute sas uri with write permission to the container which the usage data needs to be uploaded to.
  --usage-start-date: string # The start time of the usage. If not provided, usage will be reported since the beginning of data collection. (format: date-time)
]: any -> any {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{name}/exportResourceUsage"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: blobStorageAbsoluteSasUri, var: blob_storage_absolute_sas_uri}, {name: usageStartDate, var: usage_start_date}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version, blob_storage_absolute_sas_uri: $blob_storage_absolute_sas_uri, usage_start_date: $usage_start_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generate a URI for uploading custom disk images to a Lab.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{name}/generateUploadUri
# Returns: record<uploadUri: string>
# operationId: Labs_GenerateUploadUri
export def "labs-generate-upload-uri" [
  subscription_id: string
  resource_group_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
  --blob-name: string # The blob name of the upload URI.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{name}/generateUploadUri"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: blobName, var: blob_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version, blob_name: $blob_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Import a virtual machine into a different lab. This operation can take a while to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{name}/importVirtualMachine
# operationId: Labs_ImportVirtualMachine
export def "labs-import-virtual-machine" [
  subscription_id: string
  resource_group_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
  --destination-virtual-machine-name: string # The name of the virtual machine in the destination lab
  --source-virtual-machine-resource-id: string # The full resource ID of the virtual machine to be imported.
]: any -> any {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{name}/importVirtualMachine"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: destinationVirtualMachineName, var: destination_virtual_machine_name}, {name: sourceVirtualMachineResourceId, var: source_virtual_machine_resource_id}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version, destination_virtual_machine_name: $destination_virtual_machine_name, source_virtual_machine_resource_id: $source_virtual_machine_resource_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List disk images available for custom image creation.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{name}/listVhds
# Returns: record<nextLink: string, value: table<id: string>>
# operationId: Labs_ListVhds
export def "labs-list-vhds" [
  subscription_id: string
  resource_group_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{name}/listVhds"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List schedules in a resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/schedules
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: GlobalSchedules_ListByResourceGroup
export def "global-schedules-list-by-resource-group" [
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
  --expand: string # Specify the $expand query. Example: 'properties($select=status)'
  --filter: string # The filter to apply to the operation. Example: '$filter=contains(name,'myName')
  --top: int # The maximum number of resources to return from the operation. Example: '$top=10' (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation. Example: '$orderby=name desc'
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/schedules"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}]
    query: [{name: "$expand", var: expand}, {name: "$filter", var: filter}, {name: "$top", var: top}, {name: "$orderby", var: orderby}, {name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, expand: $expand, filter: $filter, top: $top, orderby: $orderby, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete schedule.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/schedules/{name}
# operationId: GlobalSchedules_Delete
export def "global-schedules-delete" [
  subscription_id: string
  resource_group_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/schedules/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get schedule.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/schedules/{name}
# Returns: record<properties: record<createdDate: string, dailyRecurrence: record<time: string>, hourlyRecurrence: record<minute: int>, notificationSettings: record<emailRecipient: string, notificationLocale: string, status: string, timeInMinutes: int, webhookUrl: string>, provisioningState: string, status: string, targetResourceId: string, taskType: string, timeZoneId: string, uniqueIdentifier: string, weeklyRecurrence: record<time: string, weekdays: list>>, id: string, location: string, name: string, tags: record, type: string>
# operationId: GlobalSchedules_Get
export def "global-schedules-get" [
  subscription_id: string
  resource_group_name: string
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
  --expand: string # Specify the $expand query. Example: 'properties($select=status)'
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/schedules/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: "$expand", var: expand}, {name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, expand: $expand, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Allows modifying tags of schedules. All other properties will be ignored.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/schedules/{name}
# Returns: record<properties: record<createdDate: string, dailyRecurrence: record<time: string>, hourlyRecurrence: record<minute: int>, notificationSettings: record<emailRecipient: string, notificationLocale: string, status: string, timeInMinutes: int, webhookUrl: string>, provisioningState: string, status: string, targetResourceId: string, taskType: string, timeZoneId: string, uniqueIdentifier: string, weeklyRecurrence: record<time: string, weekdays: list>>, id: string, location: string, name: string, tags: record, type: string>
# operationId: GlobalSchedules_Update
export def "global-schedules-update" [
  subscription_id: string
  resource_group_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
  --properties: record # Properties of a schedule. — shape: {dailyRecurrence?: record, hourlyRecurrence?: record, notificationSettings?: record, status?: "Enabled"|"Disabled", targetResourceId?: string, taskType?: string, timeZoneId?: string, weeklyRecurrence?: record}
  --tags: record # The tags of the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/schedules/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version, properties: $properties, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create or replace an existing schedule.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/schedules/{name}
# Returns: record<properties: record<createdDate: string, dailyRecurrence: record<time: string>, hourlyRecurrence: record<minute: int>, notificationSettings: record<emailRecipient: string, notificationLocale: string, status: string, timeInMinutes: int, webhookUrl: string>, provisioningState: string, status: string, targetResourceId: string, taskType: string, timeZoneId: string, uniqueIdentifier: string, weeklyRecurrence: record<time: string, weekdays: list>>, id: string, location: string, name: string, tags: record, type: string>
# operationId: GlobalSchedules_CreateOrUpdate
export def "global-schedules-create-or-update" [
  subscription_id: string
  resource_group_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
  properties: record # Properties of a schedule. — shape: {dailyRecurrence?: record, hourlyRecurrence?: record, notificationSettings?: record, status?: "Enabled"|"Disabled", targetResourceId?: string, taskType?: string, timeZoneId?: string, weeklyRecurrence?: record}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/schedules/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version, properties: $properties, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Execute a schedule. This operation can take a while to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/schedules/{name}/execute
# operationId: GlobalSchedules_Execute
export def "global-schedules-execute" [
  subscription_id: string
  resource_group_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
]: nothing -> any {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/schedules/{name}/execute"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a schedule's target resource Id. This operation can take a while to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/schedules/{name}/retarget
# operationId: GlobalSchedules_Retarget
export def "global-schedules-retarget" [
  subscription_id: string
  resource_group_name: string
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
  --api-version: string # Client API version. (required, default: 2018-09-15)
  --current-resource-id: string # The resource Id of the virtual machine on which the schedule operates
  --target-resource-id: string # The resource Id of the virtual machine that the schedule should be retargeted to
]: any -> any {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/schedules/{name}/retarget"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-09-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: currentResourceId, var: current_resource_id}, {name: targetResourceId, var: target_resource_id}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version, current_resource_id: $current_resource_id, target_resource_id: $target_resource_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
