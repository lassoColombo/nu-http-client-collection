# Auto-generated client for BatchService v2019-08-01.10.0
# Source: https://api.apis.guru/v2/specs/azure.com/batch-BatchService/2019-08-01.10.0/swagger.json
# Auth: --token flag or $env.BATCHSERVICE_TOKEN

const CLIENT = {
  base_url: "{batchUrl}"
  token_env_var: "BATCHSERVICE_TOKEN"
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

def base-url-completer [] { ["{batchUrl}"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def certificate-format-completer [] { ["cer" "pfx"] }
def on-all-tasks-complete-completer [] { ["noaction" "terminatejob"] }
def on-task-failure-completer [] { ["noaction" "performexitoptionsjobaction"] }
def disable-tasks-completer [] { ["requeue" "terminate" "wait"] }
def accept-completer [] { ["application/json" "application/octet-stream"] }
def node-disable-scheduling-option-completer [] { ["requeue" "taskcompletion" "terminate"] }
def node-reboot-option-completer [] { ["requeue" "retaineddata" "taskcompletion" "terminate"] }
def node-reimage-option-completer [] { ["requeue" "retaineddata" "taskcompletion" "terminate"] }
def node-deallocation-option-completer [] { ["requeue" "retaineddata" "taskcompletion" "terminate"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    application-list: "record<\"odata.nextLink\": string, value: table<displayName: string, id: string, versions: list>>"
    application-get: "record<displayName: string, id: string, versions: list<string>>"
    certificate-list: "record<\"odata.nextLink\": string, value: table<deleteCertificateError: record, previousState: string, previousStateTransitionTime: string, publicData: string, state: string, stateTransitionTime: string, thumbprint: string, thumbprintAlgorithm: string, url: string>>"
    certificate-get: "record<deleteCertificateError: record<code: string, message: string, values: list<record>>, previousState: string, previousStateTransitionTime: string, publicData: string, state: string, stateTransitionTime: string, thumbprint: string, thumbprintAlgorithm: string, url: string>"
    job-list: "record<\"odata.nextLink\": string, value: table<commonEnvironmentSettings: list, constraints: record, creationTime: string, displayName: string, eTag: string, executionInfo: record, id: string, jobManagerTask: record, jobPreparationTask: record, jobReleaseTask: record, lastModified: string, metadata: list, networkConfiguration: record, onAllTasksComplete: string, onTaskFailure: string, poolInfo: record, previousState: string, previousStateTransitionTime: string, priority: int, state: string, stateTransitionTime: string, stats: record, url: string, usesTaskDependencies: bool>>"
    job-get: "record<commonEnvironmentSettings: table<name: string, value: string>, constraints: record<maxTaskRetryCount: int, maxWallClockTime: string>, creationTime: string, displayName: string, eTag: string, executionInfo: record<endTime: string, poolId: string, schedulingError: record<category: string, code: string, details: list, message: string>, startTime: string, terminateReason: string>, id: string, jobManagerTask: record<allowLowPriorityNode: bool, applicationPackageReferences: list<record>, authenticationTokenSettings: record<access: list>, commandLine: string, constraints: record<maxTaskRetryCount: int, maxWallClockTime: string, retentionTime: string>, containerSettings: record<containerRunOptions: string, imageName: string, registry: record, workingDirectory: string>, displayName: string, environmentSettings: list<record>, id: string, killJobOnCompletion: bool, outputFiles: list<record>, resourceFiles: list<record>, runExclusive: bool, userIdentity: record<autoUser: record, username: string>>, jobPreparationTask: record<commandLine: string, constraints: record<maxTaskRetryCount: int, maxWallClockTime: string, retentionTime: string>, containerSettings: record<containerRunOptions: string, imageName: string, registry: record, workingDirectory: string>, environmentSettings: list<record>, id: string, rerunOnNodeRebootAfterSuccess: bool, resourceFiles: list<record>, userIdentity: record<autoUser: record, username: string>, waitForSuccess: bool>, jobReleaseTask: record<commandLine: string, containerSettings: record<containerRunOptions: string, imageName: string, registry: record, workingDirectory: string>, environmentSettings: list<record>, id: string, maxWallClockTime: string, resourceFiles: list<record>, retentionTime: string, userIdentity: record<autoUser: record, username: string>>, lastModified: string, metadata: table<name: string, value: string>, networkConfiguration: record<subnetId: string>, onAllTasksComplete: string, onTaskFailure: string, poolInfo: record<autoPoolSpecification: record<autoPoolIdPrefix: string, keepAlive: bool, pool: record, poolLifetimeOption: string>, poolId: string>, previousState: string, previousStateTransitionTime: string, priority: int, state: string, stateTransitionTime: string, stats: record<kernelCPUTime: string, lastUpdateTime: string, numFailedTasks: int, numSucceededTasks: int, numTaskRetries: int, readIOGiB: float, readIOps: int, startTime: string, url: string, userCPUTime: string, waitTime: string, wallClockTime: string, writeIOGiB: float, writeIOps: int>, url: string, usesTaskDependencies: bool>"
    task-add-collection: "record<value: table<eTag: string, error: record, lastModified: string, location: string, status: string, taskId: string>>"
    job-list-preparation-and-release-task-status: "record<\"odata.nextLink\": string, value: table<jobPreparationTaskExecutionInfo: record, jobReleaseTaskExecutionInfo: record, nodeId: string, nodeUrl: string, poolId: string>>"
    job-get-task-counts: "record<active: int, completed: int, failed: int, running: int, succeeded: int>"
    task-list: "record<\"odata.nextLink\": string, value: table<affinityInfo: record, applicationPackageReferences: list, authenticationTokenSettings: record, commandLine: string, constraints: record, containerSettings: record, creationTime: string, dependsOn: record, displayName: string, eTag: string, environmentSettings: list, executionInfo: record, exitConditions: record, id: string, lastModified: string, multiInstanceSettings: record, nodeInfo: record, outputFiles: list, previousState: string, previousStateTransitionTime: string, resourceFiles: list, state: string, stateTransitionTime: string, stats: record, url: string, userIdentity: record>>"
    task-get: "record<affinityInfo: record<affinityId: string>, applicationPackageReferences: table<applicationId: string, version: string>, authenticationTokenSettings: record<access: list<string>>, commandLine: string, constraints: record<maxTaskRetryCount: int, maxWallClockTime: string, retentionTime: string>, containerSettings: record<containerRunOptions: string, imageName: string, registry: record<password: string, registryServer: string, username: string>, workingDirectory: string>, creationTime: string, dependsOn: record<taskIdRanges: list<record>, taskIds: list<string>>, displayName: string, eTag: string, environmentSettings: table<name: string, value: string>, executionInfo: record<containerInfo: record<containerId: string, error: string, state: string>, endTime: string, exitCode: int, failureInfo: record<category: string, code: string, details: list, message: string>, lastRequeueTime: string, lastRetryTime: string, requeueCount: int, result: string, retryCount: int, startTime: string>, exitConditions: record<default: record<dependencyAction: string, jobAction: string>, exitCodeRanges: list<record>, exitCodes: list<record>, fileUploadError: record<dependencyAction: string, jobAction: string>, preProcessingError: record<dependencyAction: string, jobAction: string>>, id: string, lastModified: string, multiInstanceSettings: record<commonResourceFiles: list<record>, coordinationCommandLine: string, numberOfInstances: int>, nodeInfo: record<affinityId: string, nodeId: string, nodeUrl: string, poolId: string, taskRootDirectory: string, taskRootDirectoryUrl: string>, outputFiles: table<destination: record, filePattern: string, uploadOptions: record>, previousState: string, previousStateTransitionTime: string, resourceFiles: table<autoStorageContainerName: string, blobPrefix: string, fileMode: string, filePath: string, httpUrl: string, storageContainerUrl: string>, state: string, stateTransitionTime: string, stats: record<kernelCPUTime: string, lastUpdateTime: string, readIOGiB: float, readIOps: int, startTime: string, url: string, userCPUTime: string, waitTime: string, wallClockTime: string, writeIOGiB: float, writeIOps: int>, url: string, userIdentity: record<autoUser: record<elevationLevel: string, scope: string>, username: string>>"
    file-list-from-task: "record<\"odata.nextLink\": string, value: table<isDirectory: bool, name: string, properties: record, url: string>>"
    file-get-from-task: "binary"
    file-get-properties-from-task: "record"
    task-list-subtasks: "record<value: table<containerInfo: record, endTime: string, exitCode: int, failureInfo: record, id: int, nodeInfo: record, previousState: string, previousStateTransitionTime: string, result: string, startTime: string, state: string, stateTransitionTime: string>>"
    job-schedule-list: "record<\"odata.nextLink\": string, value: table<creationTime: string, displayName: string, eTag: string, executionInfo: record, id: string, jobSpecification: record, lastModified: string, metadata: list, previousState: string, previousStateTransitionTime: string, schedule: record, state: string, stateTransitionTime: string, stats: record, url: string>>"
    job-schedule-get: "record<creationTime: string, displayName: string, eTag: string, executionInfo: record<endTime: string, nextRunTime: string, recentJob: record<id: string, url: string>>, id: string, jobSpecification: record<commonEnvironmentSettings: list<record>, constraints: record<maxTaskRetryCount: int, maxWallClockTime: string>, displayName: string, jobManagerTask: record<allowLowPriorityNode: bool, applicationPackageReferences: list, authenticationTokenSettings: record, commandLine: string, constraints: record, containerSettings: record, displayName: string, environmentSettings: list, id: string, killJobOnCompletion: bool, outputFiles: list, resourceFiles: list, runExclusive: bool, userIdentity: record>, jobPreparationTask: record<commandLine: string, constraints: record, containerSettings: record, environmentSettings: list, id: string, rerunOnNodeRebootAfterSuccess: bool, resourceFiles: list, userIdentity: record, waitForSuccess: bool>, jobReleaseTask: record<commandLine: string, containerSettings: record, environmentSettings: list, id: string, maxWallClockTime: string, resourceFiles: list, retentionTime: string, userIdentity: record>, metadata: list<record>, networkConfiguration: record<subnetId: string>, onAllTasksComplete: string, onTaskFailure: string, poolInfo: record<autoPoolSpecification: record, poolId: string>, priority: int, usesTaskDependencies: bool>, lastModified: string, metadata: table<name: string, value: string>, previousState: string, previousStateTransitionTime: string, schedule: record<doNotRunAfter: string, doNotRunUntil: string, recurrenceInterval: string, startWindow: string>, state: string, stateTransitionTime: string, stats: record<kernelCPUTime: string, lastUpdateTime: string, numFailedTasks: int, numSucceededTasks: int, numTaskRetries: int, readIOGiB: float, readIOps: int, startTime: string, url: string, userCPUTime: string, waitTime: string, wallClockTime: string, writeIOGiB: float, writeIOps: int>, url: string>"
    job-schedule-exists: "record"
    job-list-from-job-schedule: "record<\"odata.nextLink\": string, value: table<commonEnvironmentSettings: list, constraints: record, creationTime: string, displayName: string, eTag: string, executionInfo: record, id: string, jobManagerTask: record, jobPreparationTask: record, jobReleaseTask: record, lastModified: string, metadata: list, networkConfiguration: record, onAllTasksComplete: string, onTaskFailure: string, poolInfo: record, previousState: string, previousStateTransitionTime: string, priority: int, state: string, stateTransitionTime: string, stats: record, url: string, usesTaskDependencies: bool>>"
    job-get-all-lifetime-statistics: "record<kernelCPUTime: string, lastUpdateTime: string, numFailedTasks: int, numSucceededTasks: int, numTaskRetries: int, readIOGiB: float, readIOps: int, startTime: string, url: string, userCPUTime: string, waitTime: string, wallClockTime: string, writeIOGiB: float, writeIOps: int>"
    pool-get-all-lifetime-statistics: "record<lastUpdateTime: string, resourceStats: record<avgCPUPercentage: float, avgDiskGiB: float, avgMemoryGiB: float, diskReadGiB: float, diskReadIOps: int, diskWriteGiB: float, diskWriteIOps: int, lastUpdateTime: string, networkReadGiB: float, networkWriteGiB: float, peakDiskGiB: float, peakMemoryGiB: float, startTime: string>, startTime: string, url: string, usageStats: record<dedicatedCoreTime: string, lastUpdateTime: string, startTime: string>>"
    account-list-pool-node-counts: "record<\"odata.nextLink\": string, value: table<dedicated: record, lowPriority: record, poolId: string>>"
    pool-list: "record<\"odata.nextLink\": string, value: table<allocationState: string, allocationStateTransitionTime: string, applicationLicenses: list, applicationPackageReferences: list, autoScaleEvaluationInterval: string, autoScaleFormula: string, autoScaleRun: record, certificateReferences: list, cloudServiceConfiguration: record, creationTime: string, currentDedicatedNodes: int, currentLowPriorityNodes: int, displayName: string, eTag: string, enableAutoScale: bool, enableInterNodeCommunication: bool, id: string, lastModified: string, maxTasksPerNode: int, metadata: list, mountConfiguration: list, networkConfiguration: record, resizeErrors: list, resizeTimeout: string, startTask: record, state: string, stateTransitionTime: string, stats: record, targetDedicatedNodes: int, targetLowPriorityNodes: int, taskSchedulingPolicy: record, url: string, userAccounts: list, virtualMachineConfiguration: record, vmSize: string>>"
    pool-get: "record<allocationState: string, allocationStateTransitionTime: string, applicationLicenses: list<string>, applicationPackageReferences: table<applicationId: string, version: string>, autoScaleEvaluationInterval: string, autoScaleFormula: string, autoScaleRun: record<error: record<code: string, message: string, values: list>, results: string, timestamp: string>, certificateReferences: table<storeLocation: string, storeName: string, thumbprint: string, thumbprintAlgorithm: string, visibility: list>, cloudServiceConfiguration: record<osFamily: string, osVersion: string>, creationTime: string, currentDedicatedNodes: int, currentLowPriorityNodes: int, displayName: string, eTag: string, enableAutoScale: bool, enableInterNodeCommunication: bool, id: string, lastModified: string, maxTasksPerNode: int, metadata: table<name: string, value: string>, mountConfiguration: table<azureBlobFileSystemConfiguration: record, azureFileShareConfiguration: record, cifsMountConfiguration: record, nfsMountConfiguration: record>, networkConfiguration: record<dynamicVNetAssignmentScope: string, endpointConfiguration: record<inboundNATPools: list>, publicIPs: list<string>, subnetId: string>, resizeErrors: table<code: string, message: string, values: list>, resizeTimeout: string, startTask: record<commandLine: string, containerSettings: record<containerRunOptions: string, imageName: string, registry: record, workingDirectory: string>, environmentSettings: list<record>, maxTaskRetryCount: int, resourceFiles: list<record>, userIdentity: record<autoUser: record, username: string>, waitForSuccess: bool>, state: string, stateTransitionTime: string, stats: record<lastUpdateTime: string, resourceStats: record<avgCPUPercentage: float, avgDiskGiB: float, avgMemoryGiB: float, diskReadGiB: float, diskReadIOps: int, diskWriteGiB: float, diskWriteIOps: int, lastUpdateTime: string, networkReadGiB: float, networkWriteGiB: float, peakDiskGiB: float, peakMemoryGiB: float, startTime: string>, startTime: string, url: string, usageStats: record<dedicatedCoreTime: string, lastUpdateTime: string, startTime: string>>, targetDedicatedNodes: int, targetLowPriorityNodes: int, taskSchedulingPolicy: record<nodeFillType: string>, url: string, userAccounts: table<elevationLevel: string, linuxUserConfiguration: record, name: string, password: string, windowsUserConfiguration: record>, virtualMachineConfiguration: record<containerConfiguration: record<containerImageNames: list, containerRegistries: list, type: string>, dataDisks: list<record>, imageReference: record<offer: string, publisher: string, sku: string, version: string, virtualMachineImageId: string>, licenseType: string, nodeAgentSKUId: string, windowsConfiguration: record<enableAutomaticUpdates: bool>>, vmSize: string>"
    pool-exists: "record"
    pool-evaluate-auto-scale: "record<error: record<code: string, message: string, values: list<record>>, results: string, timestamp: string>"
    compute-node-list: "record<\"odata.nextLink\": string, value: table<affinityId: string, allocationTime: string, certificateReferences: list, endpointConfiguration: record, errors: list, id: string, ipAddress: string, isDedicated: bool, lastBootTime: string, nodeAgentInfo: record, recentTasks: list, runningTasksCount: int, schedulingState: string, startTask: record, startTaskInfo: record, state: string, stateTransitionTime: string, totalTasksRun: int, totalTasksSucceeded: int, url: string, vmSize: string>>"
    compute-node-get: "record<affinityId: string, allocationTime: string, certificateReferences: table<storeLocation: string, storeName: string, thumbprint: string, thumbprintAlgorithm: string, visibility: list>, endpointConfiguration: record<inboundEndpoints: list<record>>, errors: table<code: string, errorDetails: list, message: string>, id: string, ipAddress: string, isDedicated: bool, lastBootTime: string, nodeAgentInfo: record<lastUpdateTime: string, version: string>, recentTasks: table<executionInfo: record, jobId: string, subtaskId: int, taskId: string, taskState: string, taskUrl: string>, runningTasksCount: int, schedulingState: string, startTask: record<commandLine: string, containerSettings: record<containerRunOptions: string, imageName: string, registry: record, workingDirectory: string>, environmentSettings: list<record>, maxTaskRetryCount: int, resourceFiles: list<record>, userIdentity: record<autoUser: record, username: string>, waitForSuccess: bool>, startTaskInfo: record<containerInfo: record<containerId: string, error: string, state: string>, endTime: string, exitCode: int, failureInfo: record<category: string, code: string, details: list, message: string>, lastRetryTime: string, result: string, retryCount: int, startTime: string, state: string>, state: string, stateTransitionTime: string, totalTasksRun: int, totalTasksSucceeded: int, url: string, vmSize: string>"
    file-list-from-compute-node: "record<\"odata.nextLink\": string, value: table<isDirectory: bool, name: string, properties: record, url: string>>"
    file-get-from-compute-node: "binary"
    file-get-properties-from-compute-node: "record"
    compute-node-get-remote-desktop: "binary"
    compute-node-get-remote-login-settings: "record<remoteLoginIPAddress: string, remoteLoginPort: int>"
    compute-node-upload-batch-service-logs: "record<numberOfFilesUploaded: int, virtualDirectoryName: string>"
    pool-list-usage-metrics: "record<\"odata.nextLink\": string, value: table<endTime: string, poolId: string, startTime: string, totalCoreHours: float, vmSize: string>>"
    account-list-supported-images: "record<\"odata.nextLink\": string, value: table<batchSupportEndOfLife: string, capabilities: list, imageReference: record, nodeAgentSKUId: string, osType: string, verificationType: string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["application-list" "application-get" "certificate-list" "certificate-add" "certificate-delete" "certificate-get" "certificate-cancel-deletion" "job-list" "job-add" "job-delete" "job-get" "job-patch" "job-update" "task-add-collection" "job-disable" "job-enable" "job-list-preparation-and-release-task-status" "job-get-task-counts" "task-list" "task-add" "task-delete" "task-get" "task-update" "file-list-from-task" "file-delete-from-task" "file-get-from-task" "file-get-properties-from-task" "task-reactivate" "task-list-subtasks" "task-terminate" "job-terminate" "job-schedule-list" "job-schedule-add" "job-schedule-delete" "job-schedule-get" "job-schedule-exists" "job-schedule-patch" "job-schedule-update" "job-schedule-disable" "job-schedule-enable" "job-list-from-job-schedule" "job-schedule-terminate" "job-get-all-lifetime-statistics" "pool-get-all-lifetime-statistics" "account-list-pool-node-counts" "pool-list" "pool-add" "pool-delete" "pool-get" "pool-exists" "pool-patch" "pool-disable-auto-scale" "pool-enable-auto-scale" "pool-evaluate-auto-scale" "compute-node-list" "compute-node-get" "compute-node-disable-scheduling" "compute-node-enable-scheduling" "file-list-from-compute-node" "file-delete-from-compute-node" "file-get-from-compute-node" "file-get-properties-from-compute-node" "compute-node-get-remote-desktop" "compute-node-reboot" "compute-node-reimage" "compute-node-get-remote-login-settings" "compute-node-upload-batch-service-logs" "compute-node-add-user" "compute-node-delete-user" "compute-node-update-user" "pool-remove-nodes" "pool-resize" "pool-stop-resize" "pool-update-properties" "pool-list-usage-metrics" "account-list-supported-images" "commands"] | sort) } | get name | first)
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

# Lists all of the applications available in the specified Account.
#
# GET /applications
# Returns: record<"odata.nextLink": string, value: table<displayName: string, id: string, versions: list>>
# operationId: Application_List
export def "application-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxresults: int # The maximum number of items to return in the response. A maximum of 1000 applications can be returned. (format: int32, default: 1000)
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/applications"
    query: [{name: maxresults, var: maxresults}, {name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    maxresults: $maxresults, timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the specified Application.
#
# GET /applications/{applicationId}
# Returns: record<displayName: string, id: string, versions: list<string>>
# operationId: Application_Get
export def "application-get" [
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
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/applications/{applicationId}"
    path_params: [{name: applicationId, var: application_id}]
    query: [{name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all of the Certificates that have been added to the specified Account.
#
# GET /certificates
# Returns: record<"odata.nextLink": string, value: table<deleteCertificateError: record, previousState: string, previousStateTransitionTime: string, publicData: string, state: string, stateTransitionTime: string, thumbprint: string, thumbprintAlgorithm: string, url: string>>
# operationId: Certificate_List
export def "certificate-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # An OData $filter clause. For more information on constructing this filter, see https://docs.microsoft.com/en-us/rest/api/batchservice/odata-filters-in-batch#list-certificates.
  --select: string # An OData $select clause.
  --maxresults: int # The maximum number of items to return in the response. A maximum of 1000 Certificates can be returned. (format: int32, default: 1000)
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/certificates"
    query: [{name: "$filter", var: filter}, {name: "$select", var: select}, {name: maxresults, var: maxresults}, {name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter: $filter, select: $select, maxresults: $maxresults, timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a Certificate to the specified Account.
#
# POST /certificates
# operationId: Certificate_Add
export def "certificate-add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
  --certificate-format: string@certificate-format-completer
  data: string
  --password: string # This is required if the Certificate format is pfx. It should be omitted if the Certificate format is cer.
  thumbprint: string
  thumbprint_algorithm: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/certificates"
    query: [{name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}]
    body: {content_type: "application/json; odata=minimalmetadata", kind: json, fields: [{name: certificateFormat, var: certificate_format}, {name: data, var: data}, {name: password, var: password}, {name: thumbprint, var: thumbprint}, {name: thumbprintAlgorithm, var: thumbprint_algorithm}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date, certificate_format: $certificate_format, data: $data, password: $password, thumbprint: $thumbprint, thumbprint_algorithm: $thumbprint_algorithm
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a Certificate from the specified Account.
#
# DELETE /certificates(thumbprintAlgorithm={thumbprintAlgorithm},thumbprint={thumbprint})
# operationId: Certificate_Delete
export def "certificate-delete" [
  thumbprint_algorithm: string
  thumbprint: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
]: nothing -> any {
  http-request {
    method: delete
    path: "/certificates(thumbprintAlgorithm={thumbprintAlgorithm},thumbprint={thumbprint})"
    path_params: [{name: thumbprintAlgorithm, var: thumbprint_algorithm}, {name: thumbprint, var: thumbprint}]
    query: [{name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    thumbprint_algorithm: $thumbprint_algorithm, thumbprint: $thumbprint, timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the specified Certificate.
#
# GET /certificates(thumbprintAlgorithm={thumbprintAlgorithm},thumbprint={thumbprint})
# Returns: record<deleteCertificateError: record<code: string, message: string, values: list<record>>, previousState: string, previousStateTransitionTime: string, publicData: string, state: string, stateTransitionTime: string, thumbprint: string, thumbprintAlgorithm: string, url: string>
# operationId: Certificate_Get
export def "certificate-get" [
  thumbprint_algorithm: string
  thumbprint: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: string # An OData $select clause.
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/certificates(thumbprintAlgorithm={thumbprintAlgorithm},thumbprint={thumbprint})"
    path_params: [{name: thumbprintAlgorithm, var: thumbprint_algorithm}, {name: thumbprint, var: thumbprint}]
    query: [{name: "$select", var: select}, {name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    thumbprint_algorithm: $thumbprint_algorithm, thumbprint: $thumbprint, select: $select, timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancels a failed deletion of a Certificate from the specified Account.
#
# POST /certificates(thumbprintAlgorithm={thumbprintAlgorithm},thumbprint={thumbprint})/canceldelete
# operationId: Certificate_CancelDeletion
export def "certificate-cancel-deletion" [
  thumbprint_algorithm: string
  thumbprint: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
]: nothing -> any {
  http-request {
    method: post
    path: "/certificates(thumbprintAlgorithm={thumbprintAlgorithm},thumbprint={thumbprint})/canceldelete"
    path_params: [{name: thumbprintAlgorithm, var: thumbprint_algorithm}, {name: thumbprint, var: thumbprint}]
    query: [{name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    thumbprint_algorithm: $thumbprint_algorithm, thumbprint: $thumbprint, timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all of the Jobs in the specified Account.
#
# GET /jobs
# Returns: record<"odata.nextLink": string, value: table<commonEnvironmentSettings: list, constraints: record, creationTime: string, displayName: string, eTag: string, executionInfo: record, id: string, jobManagerTask: record, jobPreparationTask: record, jobReleaseTask: record, lastModified: string, metadata: list, networkConfiguration: record, onAllTasksComplete: string, onTaskFailure: string, poolInfo: record, previousState: string, previousStateTransitionTime: string, priority: int, state: string, stateTransitionTime: string, stats: record, url: string, usesTaskDependencies: bool>>
# operationId: Job_List
export def "job-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # An OData $filter clause. For more information on constructing this filter, see https://docs.microsoft.com/en-us/rest/api/batchservice/odata-filters-in-batch#list-jobs.
  --select: string # An OData $select clause.
  --expand: string # An OData $expand clause.
  --maxresults: int # The maximum number of items to return in the response. A maximum of 1000 Jobs can be returned. (format: int32, default: 1000)
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/jobs"
    query: [{name: "$filter", var: filter}, {name: "$select", var: select}, {name: "$expand", var: expand}, {name: maxresults, var: maxresults}, {name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter: $filter, select: $select, expand: $expand, maxresults: $maxresults, timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a Job to the specified Account.
#
# POST /jobs
# operationId: Job_Add
export def "job-add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
  --common-environment-settings: list # Individual Tasks can override an environment setting specified here by specifying the same setting name with a different value. — item shape: {name: string, value?: string}
  --constraints: any # shape: {maxTaskRetryCount?: int, maxWallClockTime?: string}
  --display-name: string # The display name need not be unique and can contain any Unicode characters up to a maximum length of 1024.
  id: string # The ID can contain any combination of alphanumeric characters including hyphens and underscores, and cannot contain more than 64 characters. The ID is case-preserving and case-insensitive (that is, you may not have two IDs within an Account that differ only by case).
  --job-manager-task: any # The Job Manager Task is automatically started when the Job is created. The Batch service tries to schedule the Job Manager Task before any other Tasks in the Job. When shrinking a Pool, the Batch service tries to preserve Nodes where Job Manager Tasks are running for as long as possible (that is, Compute Nodes running 'normal' Tasks are removed before Compute Nodes running Job Manager Tasks). When a Job Manager Task fails and needs to be restarted, the system tries to schedule it at the highest priority. If there are no idle Compute Nodes available, the system may terminate one of the running Tasks in the Pool and return it to the queue in order to make room for the Job Manager Task to restart. Note that a Job Manager Task in one Job does not have priority over Tasks in other Jobs. Across Jobs, only Job level priorities are observed. For example, if a Job Manager in a priority 0 Job needs to be restarted, it will not displace Tasks of a priority 1 Job. Batch will retry Tasks when a recovery operation is triggered on a Node. Examples of recovery operations include (but are not limited to) when an unhealthy Node is rebooted or a Compute Node disappeared due to host failure. Retries due to recovery operations are independent of and are not counted against the maxTaskRetryCount. Even if the maxTaskRetryCount is 0, an internal retry due to a recovery operation may occur. Because of this, all Tasks should be idempotent. This means Tasks need to tolerate being interrupted and restarted without causing any corruption or duplicate data. The best practice for long running Tasks is to use some form of checkpointing. — shape: {allowLowPriorityNode?: bool, applicationPackageReferences?: list, authenticationTokenSettings?: any, commandLine: string, constraints?: any, containerSettings?: any, displayName?: string, environmentSettings?: list, id: string, killJobOnCompletion?: bool, outputFiles?: list, resourceFiles?: list, runExclusive?: bool, userIdentity?: any}
  --job-preparation-task: any # You can use Job Preparation to prepare a Node to run Tasks for the Job. Activities commonly performed in Job Preparation include: Downloading common resource files used by all the Tasks in the Job. The Job Preparation Task can download these common resource files to the shared location on the Node. (AZ_BATCH_NODE_ROOT_DIR\shared), or starting a local service on the Node so that all Tasks of that Job can communicate with it. If the Job Preparation Task fails (that is, exhausts its retry count before exiting with exit code 0), Batch will not run Tasks of this Job on the Node. The Compute Node remains ineligible to run Tasks of this Job until it is reimaged. The Compute Node remains active and can be used for other Jobs. The Job Preparation Task can run multiple times on the same Node. Therefore, you should write the Job Preparation Task to handle re-execution. If the Node is rebooted, the Job Preparation Task is run again on the Compute Node before scheduling any other Task of the Job, if rerunOnNodeRebootAfterSuccess is true or if the Job Preparation Task did not previously complete. If the Node is reimaged, the Job Preparation Task is run again before scheduling any Task of the Job. Batch will retry Tasks when a recovery operation is triggered on a Node. Examples of recovery operations include (but are not limited to) when an unhealthy Node is rebooted or a Compute Node disappeared due to host failure. Retries due to recovery operations are independent of and are not counted against the maxTaskRetryCount. Even if the maxTaskRetryCount is 0, an internal retry due to a recovery operation may occur. Because of this, all Tasks should be idempotent. This means Tasks need to tolerate being interrupted and restarted without causing any corruption or duplicate data. The best practice for long running Tasks is to use some form of checkpointing. — shape: {commandLine: string, constraints?: any, containerSettings?: any, environmentSettings?: list, id?: string, rerunOnNodeRebootAfterSuccess?: bool, resourceFiles?: list, userIdentity?: any, waitForSuccess?: bool}
  --job-release-task: any # The Job Release Task runs when the Job ends, because of one of the following: The user calls the Terminate Job API, or the Delete Job API while the Job is still active, the Job's maximum wall clock time constraint is reached, and the Job is still active, or the Job's Job Manager Task completed, and the Job is configured to terminate when the Job Manager completes. The Job Release Task runs on each Node where Tasks of the Job have run and the Job Preparation Task ran and completed. If you reimage a Node after it has run the Job Preparation Task, and the Job ends without any further Tasks of the Job running on that Node (and hence the Job Preparation Task does not re-run), then the Job Release Task does not run on that Compute Node. If a Node reboots while the Job Release Task is still running, the Job Release Task runs again when the Compute Node starts up. The Job is not marked as complete until all Job Release Tasks have completed. The Job Release Task runs in the background. It does not occupy a scheduling slot; that is, it does not count towards the maxTasksPerNode limit specified on the Pool. — shape: {commandLine: string, containerSettings?: any, environmentSettings?: list, id?: string, maxWallClockTime?: string, resourceFiles?: list, retentionTime?: string, userIdentity?: any}
  --metadata: list # The Batch service does not assign any meaning to metadata; it is solely for the use of user code. — item shape: {name: string, value: string}
  --network-configuration: any # shape: {subnetId: string}
  --on-all-tasks-complete: string@on-all-tasks-complete-completer
  --on-task-failure: string@on-task-failure-completer # A Task is considered to have failed if has a failureInfo. A failureInfo is set if the Task completes with a non-zero exit code after exhausting its retry count, or if there was an error starting the Task, for example due to a resource file download error. The default is noaction.
  pool_info: any # shape: {autoPoolSpecification?: any, poolId?: string}
  --priority: int # Priority values can range from -1000 to 1000, with -1000 being the lowest priority and 1000 being the highest priority. The default value is 0. (format: int32)
  --uses-task-dependencies: oneof<nothing, bool>
]: any -> any {
  $in | http-request {
    method: post
    path: "/jobs"
    query: [{name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}]
    body: {content_type: "application/json; odata=minimalmetadata", kind: json, fields: [{name: commonEnvironmentSettings, var: common_environment_settings}, {name: constraints, var: constraints}, {name: displayName, var: display_name}, {name: id, var: id}, {name: jobManagerTask, var: job_manager_task}, {name: jobPreparationTask, var: job_preparation_task}, {name: jobReleaseTask, var: job_release_task}, {name: metadata, var: metadata}, {name: networkConfiguration, var: network_configuration}, {name: onAllTasksComplete, var: on_all_tasks_complete}, {name: onTaskFailure, var: on_task_failure}, {name: poolInfo, var: pool_info}, {name: priority, var: priority}, {name: usesTaskDependencies, var: uses_task_dependencies}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date, common_environment_settings: $common_environment_settings, constraints: $constraints, display_name: $display_name, id: $id, job_manager_task: $job_manager_task, job_preparation_task: $job_preparation_task, job_release_task: $job_release_task, metadata: $metadata, network_configuration: $network_configuration, on_all_tasks_complete: $on_all_tasks_complete, on_task_failure: $on_task_failure, pool_info: $pool_info, priority: $priority, uses_task_dependencies: $uses_task_dependencies
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a Job.
#
# DELETE /jobs/{jobId}
# operationId: Job_Delete
export def "job-delete" [
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
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
  --if-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --if-none-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --if-modified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time. (format: date-time-rfc1123)
  --if-unmodified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time. (format: date-time-rfc1123)
]: nothing -> any {
  http-request {
    method: delete
    path: "/jobs/{jobId}"
    path_params: [{name: jobId, var: job_id}]
    query: [{name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}, {name: If-Match, var: if_match}, {name: If-None-Match, var: if_none_match}, {name: If-Modified-Since, var: if_modified_since}, {name: If-Unmodified-Since, var: if_unmodified_since}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    job_id: $job_id, timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date, if_match: $if_match, if_none_match: $if_none_match, if_modified_since: $if_modified_since, if_unmodified_since: $if_unmodified_since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the specified Job.
#
# GET /jobs/{jobId}
# Returns: record<commonEnvironmentSettings: table<name: string, value: string>, constraints: record<maxTaskRetryCount: int, maxWallClockTime: string>, creationTime: string, displayName: string, eTag: string, executionInfo: record<endTime: string, poolId: string, schedulingError: record<category: string, code: string, details: list, message: string>, startTime: string, terminateReason: string>, id: string, jobManagerTask: record<allowLowPriorityNode: bool, applicationPackageReferences: list<record>, authenticationTokenSettings: record<access: list>, commandLine: string, constraints: record<maxTaskRetryCount: int, maxWallClockTime: string, retentionTime: string>, containerSettings: record<containerRunOptions: string, imageName: string, registry: record, workingDirectory: string>, displayName: string, environmentSettings: list<record>, id: string, killJobOnCompletion: bool, outputFiles: list<record>, resourceFiles: list<record>, runExclusive: bool, userIdentity: record<autoUser: record, username: string>>, jobPreparationTask: record<commandLine: string, constraints: record<maxTaskRetryCount: int, maxWallClockTime: string, retentionTime: string>, containerSettings: record<containerRunOptions: string, imageName: string, registry: record, workingDirectory: string>, environmentSettings: list<record>, id: string, rerunOnNodeRebootAfterSuccess: bool, resourceFiles: list<record>, userIdentity: record<autoUser: record, username: string>, waitForSuccess: bool>, jobReleaseTask: record<commandLine: string, containerSettings: record<containerRunOptions: string, imageName: string, registry: record, workingDirectory: string>, environmentSettings: list<record>, id: string, maxWallClockTime: string, resourceFiles: list<record>, retentionTime: string, userIdentity: record<autoUser: record, username: string>>, lastModified: string, metadata: table<name: string, value: string>, networkConfiguration: record<subnetId: string>, onAllTasksComplete: string, onTaskFailure: string, poolInfo: record<autoPoolSpecification: record<autoPoolIdPrefix: string, keepAlive: bool, pool: record, poolLifetimeOption: string>, poolId: string>, previousState: string, previousStateTransitionTime: string, priority: int, state: string, stateTransitionTime: string, stats: record<kernelCPUTime: string, lastUpdateTime: string, numFailedTasks: int, numSucceededTasks: int, numTaskRetries: int, readIOGiB: float, readIOps: int, startTime: string, url: string, userCPUTime: string, waitTime: string, wallClockTime: string, writeIOGiB: float, writeIOps: int>, url: string, usesTaskDependencies: bool>
# operationId: Job_Get
export def "job-get" [
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
  --select: string # An OData $select clause.
  --expand: string # An OData $expand clause.
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
  --if-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --if-none-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --if-modified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time. (format: date-time-rfc1123)
  --if-unmodified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time. (format: date-time-rfc1123)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/jobs/{jobId}"
    path_params: [{name: jobId, var: job_id}]
    query: [{name: "$select", var: select}, {name: "$expand", var: expand}, {name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}, {name: If-Match, var: if_match}, {name: If-None-Match, var: if_none_match}, {name: If-Modified-Since, var: if_modified_since}, {name: If-Unmodified-Since, var: if_unmodified_since}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    job_id: $job_id, select: $select, expand: $expand, timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date, if_match: $if_match, if_none_match: $if_none_match, if_modified_since: $if_modified_since, if_unmodified_since: $if_unmodified_since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the properties of the specified Job.
#
# PATCH /jobs/{jobId}
# operationId: Job_Patch
export def "job-patch" [
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
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
  --if-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --if-none-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --if-modified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time. (format: date-time-rfc1123)
  --if-unmodified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time. (format: date-time-rfc1123)
  --constraints: any # shape: {maxTaskRetryCount?: int, maxWallClockTime?: string}
  --metadata: list # If omitted, the existing Job metadata is left unchanged. — item shape: {name: string, value: string}
  --on-all-tasks-complete: string@on-all-tasks-complete-completer
  --pool-info: any # shape: {autoPoolSpecification?: any, poolId?: string}
  --priority: int # Priority values can range from -1000 to 1000, with -1000 being the lowest priority and 1000 being the highest priority. If omitted, the priority of the Job is left unchanged. (format: int32)
]: any -> any {
  $in | http-request {
    method: patch
    path: "/jobs/{jobId}"
    path_params: [{name: jobId, var: job_id}]
    query: [{name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}, {name: If-Match, var: if_match}, {name: If-None-Match, var: if_none_match}, {name: If-Modified-Since, var: if_modified_since}, {name: If-Unmodified-Since, var: if_unmodified_since}]
    body: {content_type: "application/json; odata=minimalmetadata", kind: json, fields: [{name: constraints, var: constraints}, {name: metadata, var: metadata}, {name: onAllTasksComplete, var: on_all_tasks_complete}, {name: poolInfo, var: pool_info}, {name: priority, var: priority}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    job_id: $job_id, timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date, if_match: $if_match, if_none_match: $if_none_match, if_modified_since: $if_modified_since, if_unmodified_since: $if_unmodified_since, constraints: $constraints, metadata: $metadata, on_all_tasks_complete: $on_all_tasks_complete, pool_info: $pool_info, priority: $priority
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the properties of the specified Job.
#
# PUT /jobs/{jobId}
# operationId: Job_Update
export def "job-update" [
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
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
  --if-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --if-none-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --if-modified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time. (format: date-time-rfc1123)
  --if-unmodified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time. (format: date-time-rfc1123)
  --constraints: any # shape: {maxTaskRetryCount?: int, maxWallClockTime?: string}
  --metadata: list # If omitted, it takes the default value of an empty list; in effect, any existing metadata is deleted. — item shape: {name: string, value: string}
  --on-all-tasks-complete: string@on-all-tasks-complete-completer
  pool_info: any # shape: {autoPoolSpecification?: any, poolId?: string}
  --priority: int # Priority values can range from -1000 to 1000, with -1000 being the lowest priority and 1000 being the highest priority. If omitted, it is set to the default value 0. (format: int32)
]: any -> any {
  $in | http-request {
    method: put
    path: "/jobs/{jobId}"
    path_params: [{name: jobId, var: job_id}]
    query: [{name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}, {name: If-Match, var: if_match}, {name: If-None-Match, var: if_none_match}, {name: If-Modified-Since, var: if_modified_since}, {name: If-Unmodified-Since, var: if_unmodified_since}]
    body: {content_type: "application/json; odata=minimalmetadata", kind: json, fields: [{name: constraints, var: constraints}, {name: metadata, var: metadata}, {name: onAllTasksComplete, var: on_all_tasks_complete}, {name: poolInfo, var: pool_info}, {name: priority, var: priority}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    job_id: $job_id, timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date, if_match: $if_match, if_none_match: $if_none_match, if_modified_since: $if_modified_since, if_unmodified_since: $if_unmodified_since, constraints: $constraints, metadata: $metadata, on_all_tasks_complete: $on_all_tasks_complete, pool_info: $pool_info, priority: $priority
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a collection of Tasks to the specified Job.
#
# POST /jobs/{jobId}/addtaskcollection
# Returns: record<value: table<eTag: string, error: record, lastModified: string, location: string, status: string, taskId: string>>
# operationId: Task_AddCollection
export def "task-add-collection" [
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
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
  value: list # The total serialized size of this collection must be less than 1MB. If it is greater than 1MB (for example if each Task has 100's of resource files or environment variables), the request will fail with code 'RequestBodyTooLarge' and should be retried again with fewer Tasks. — item shape: {affinityInfo?: any, applicationPackageReferences?: list, authenticationTokenSettings?: any, commandLine: string, constraints?: any, containerSettings?: any, dependsOn?: any, displayName?: string, environmentSettings?: list, exitConditions?: any, id: string, multiInstanceSettings?: any, outputFiles?: list, resourceFiles?: list, userIdentity?: any}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/jobs/{jobId}/addtaskcollection"
    path_params: [{name: jobId, var: job_id}]
    query: [{name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}]
    body: {content_type: "application/json; odata=minimalmetadata", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    job_id: $job_id, timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disables the specified Job, preventing new Tasks from running.
#
# POST /jobs/{jobId}/disable
# operationId: Job_Disable
export def "job-disable" [
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
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
  --if-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --if-none-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --if-modified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time. (format: date-time-rfc1123)
  --if-unmodified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time. (format: date-time-rfc1123)
  disable_tasks: string@disable-tasks-completer
]: any -> any {
  $in | http-request {
    method: post
    path: "/jobs/{jobId}/disable"
    path_params: [{name: jobId, var: job_id}]
    query: [{name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}, {name: If-Match, var: if_match}, {name: If-None-Match, var: if_none_match}, {name: If-Modified-Since, var: if_modified_since}, {name: If-Unmodified-Since, var: if_unmodified_since}]
    body: {content_type: "application/json; odata=minimalmetadata", kind: json, fields: [{name: disableTasks, var: disable_tasks}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    job_id: $job_id, timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date, if_match: $if_match, if_none_match: $if_none_match, if_modified_since: $if_modified_since, if_unmodified_since: $if_unmodified_since, disable_tasks: $disable_tasks
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enables the specified Job, allowing new Tasks to run.
#
# POST /jobs/{jobId}/enable
# operationId: Job_Enable
export def "job-enable" [
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
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
  --if-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --if-none-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --if-modified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time. (format: date-time-rfc1123)
  --if-unmodified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time. (format: date-time-rfc1123)
]: nothing -> any {
  http-request {
    method: post
    path: "/jobs/{jobId}/enable"
    path_params: [{name: jobId, var: job_id}]
    query: [{name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}, {name: If-Match, var: if_match}, {name: If-None-Match, var: if_none_match}, {name: If-Modified-Since, var: if_modified_since}, {name: If-Unmodified-Since, var: if_unmodified_since}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    job_id: $job_id, timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date, if_match: $if_match, if_none_match: $if_none_match, if_modified_since: $if_modified_since, if_unmodified_since: $if_unmodified_since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the execution status of the Job Preparation and Job Release Task for the specified Job across the Compute Nodes where the Job has run.
#
# GET /jobs/{jobId}/jobpreparationandreleasetaskstatus
# Returns: record<"odata.nextLink": string, value: table<jobPreparationTaskExecutionInfo: record, jobReleaseTaskExecutionInfo: record, nodeId: string, nodeUrl: string, poolId: string>>
# operationId: Job_ListPreparationAndReleaseTaskStatus
export def "job-list-preparation-and-release-task-status" [
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
  --filter: string # An OData $filter clause. For more information on constructing this filter, see https://docs.microsoft.com/en-us/rest/api/batchservice/odata-filters-in-batch#list-job-preparation-and-release-status.
  --select: string # An OData $select clause.
  --maxresults: int # The maximum number of items to return in the response. A maximum of 1000 Tasks can be returned. (format: int32, default: 1000)
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/jobs/{jobId}/jobpreparationandreleasetaskstatus"
    path_params: [{name: jobId, var: job_id}]
    query: [{name: "$filter", var: filter}, {name: "$select", var: select}, {name: maxresults, var: maxresults}, {name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    job_id: $job_id, filter: $filter, select: $select, maxresults: $maxresults, timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the Task counts for the specified Job.
#
# GET /jobs/{jobId}/taskcounts
# Returns: record<active: int, completed: int, failed: int, running: int, succeeded: int>
# operationId: Job_GetTaskCounts
export def "job-get-task-counts" [
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
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/jobs/{jobId}/taskcounts"
    path_params: [{name: jobId, var: job_id}]
    query: [{name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    job_id: $job_id, timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all of the Tasks that are associated with the specified Job.
#
# GET /jobs/{jobId}/tasks
# Returns: record<"odata.nextLink": string, value: table<affinityInfo: record, applicationPackageReferences: list, authenticationTokenSettings: record, commandLine: string, constraints: record, containerSettings: record, creationTime: string, dependsOn: record, displayName: string, eTag: string, environmentSettings: list, executionInfo: record, exitConditions: record, id: string, lastModified: string, multiInstanceSettings: record, nodeInfo: record, outputFiles: list, previousState: string, previousStateTransitionTime: string, resourceFiles: list, state: string, stateTransitionTime: string, stats: record, url: string, userIdentity: record>>
# operationId: Task_List
export def "task-list" [
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
  --filter: string # An OData $filter clause. For more information on constructing this filter, see https://docs.microsoft.com/en-us/rest/api/batchservice/odata-filters-in-batch#list-tasks.
  --select: string # An OData $select clause.
  --expand: string # An OData $expand clause.
  --maxresults: int # The maximum number of items to return in the response. A maximum of 1000 Tasks can be returned. (format: int32, default: 1000)
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/jobs/{jobId}/tasks"
    path_params: [{name: jobId, var: job_id}]
    query: [{name: "$filter", var: filter}, {name: "$select", var: select}, {name: "$expand", var: expand}, {name: maxresults, var: maxresults}, {name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    job_id: $job_id, filter: $filter, select: $select, expand: $expand, maxresults: $maxresults, timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a Task to the specified Job.
#
# POST /jobs/{jobId}/tasks
# operationId: Task_Add
export def "task-add" [
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
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
  --affinity-info: any # shape: {affinityId: string}
  --application-package-references: list # Application packages are downloaded and deployed to a shared directory, not the Task working directory. Therefore, if a referenced package is already on the Node, and is up to date, then it is not re-downloaded; the existing copy on the Compute Node is used. If a referenced Package cannot be installed, for example because the package has been deleted or because download failed, the Task fails. — item shape: {applicationId: string, version?: string}
  --authentication-token-settings: any # shape: {access?: list<string>}
  command_line: string # For multi-instance Tasks, the command line is executed as the primary Task, after the primary Task and all subtasks have finished executing the coordination command line. The command line does not run under a shell, and therefore cannot take advantage of shell features such as environment variable expansion. If you want to take advantage of such features, you should invoke the shell in the command line, for example using "cmd /c MyCommand" in Windows or "/bin/sh -c MyCommand" in Linux. If the command line refers to file paths, it should use a relative path (relative to the Task working directory), or use the Batch provided environment variable (https://docs.microsoft.com/en-us/azure/batch/batch-compute-node-environment-variables).
  --constraints: any # shape: {maxTaskRetryCount?: int, maxWallClockTime?: string, retentionTime?: string}
  --container-settings: any # shape: {containerRunOptions?: string, imageName: string, registry?: any, workingDirectory?: "taskWorkingDirectory"|"containerImageDefault"}
  --depends-on: any # shape: {taskIdRanges?: list, taskIds?: list<string>}
  --display-name: string # The display name need not be unique and can contain any Unicode characters up to a maximum length of 1024.
  --environment-settings: list # item shape: {name: string, value?: string}
  --exit-conditions: any # shape: {default?: any, exitCodeRanges?: list, exitCodes?: list, fileUploadError?: any, preProcessingError?: any}
  id: string # The ID can contain any combination of alphanumeric characters including hyphens and underscores, and cannot contain more than 64 characters. The ID is case-preserving and case-insensitive (that is, you may not have two IDs within a Job that differ only by case).
  --multi-instance-settings: any # Multi-instance Tasks are commonly used to support MPI Tasks. In the MPI case, if any of the subtasks fail (for example due to exiting with a non-zero exit code) the entire multi-instance Task fails. The multi-instance Task is then terminated and retried, up to its retry limit. — shape: {commonResourceFiles?: list, coordinationCommandLine: string, numberOfInstances?: int}
  --output-files: list # For multi-instance Tasks, the files will only be uploaded from the Compute Node on which the primary Task is executed. — item shape: {destination: any, filePattern: string, uploadOptions: any}
  --resource-files: list # For multi-instance Tasks, the resource files will only be downloaded to the Compute Node on which the primary Task is executed. There is a maximum size for the list of resource files. When the max size is exceeded, the request will fail and the response error code will be RequestEntityTooLarge. If this occurs, the collection of ResourceFiles must be reduced in size. This can be achieved using .zip files, Application Packages, or Docker Containers. — item shape: {autoStorageContainerName?: string, blobPrefix?: string, fileMode?: string, filePath?: string, httpUrl?: string, storageContainerUrl?: string}
  --user-identity: any # Specify either the userName or autoUser property, but not both. — shape: {autoUser?: any, username?: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/jobs/{jobId}/tasks"
    path_params: [{name: jobId, var: job_id}]
    query: [{name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}]
    body: {content_type: "application/json; odata=minimalmetadata", kind: json, fields: [{name: affinityInfo, var: affinity_info}, {name: applicationPackageReferences, var: application_package_references}, {name: authenticationTokenSettings, var: authentication_token_settings}, {name: commandLine, var: command_line}, {name: constraints, var: constraints}, {name: containerSettings, var: container_settings}, {name: dependsOn, var: depends_on}, {name: displayName, var: display_name}, {name: environmentSettings, var: environment_settings}, {name: exitConditions, var: exit_conditions}, {name: id, var: id}, {name: multiInstanceSettings, var: multi_instance_settings}, {name: outputFiles, var: output_files}, {name: resourceFiles, var: resource_files}, {name: userIdentity, var: user_identity}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    job_id: $job_id, timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date, affinity_info: $affinity_info, application_package_references: $application_package_references, authentication_token_settings: $authentication_token_settings, command_line: $command_line, constraints: $constraints, container_settings: $container_settings, depends_on: $depends_on, display_name: $display_name, environment_settings: $environment_settings, exit_conditions: $exit_conditions, id: $id, multi_instance_settings: $multi_instance_settings, output_files: $output_files, resource_files: $resource_files, user_identity: $user_identity
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a Task from the specified Job.
#
# DELETE /jobs/{jobId}/tasks/{taskId}
# operationId: Task_Delete
export def "task-delete" [
  job_id: string
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
  --if-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --if-none-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --if-modified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time. (format: date-time-rfc1123)
  --if-unmodified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time. (format: date-time-rfc1123)
]: nothing -> any {
  http-request {
    method: delete
    path: "/jobs/{jobId}/tasks/{taskId}"
    path_params: [{name: jobId, var: job_id}, {name: taskId, var: task_id}]
    query: [{name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}, {name: If-Match, var: if_match}, {name: If-None-Match, var: if_none_match}, {name: If-Modified-Since, var: if_modified_since}, {name: If-Unmodified-Since, var: if_unmodified_since}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    job_id: $job_id, task_id: $task_id, timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date, if_match: $if_match, if_none_match: $if_none_match, if_modified_since: $if_modified_since, if_unmodified_since: $if_unmodified_since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the specified Task.
#
# GET /jobs/{jobId}/tasks/{taskId}
# Returns: record<affinityInfo: record<affinityId: string>, applicationPackageReferences: table<applicationId: string, version: string>, authenticationTokenSettings: record<access: list<string>>, commandLine: string, constraints: record<maxTaskRetryCount: int, maxWallClockTime: string, retentionTime: string>, containerSettings: record<containerRunOptions: string, imageName: string, registry: record<password: string, registryServer: string, username: string>, workingDirectory: string>, creationTime: string, dependsOn: record<taskIdRanges: list<record>, taskIds: list<string>>, displayName: string, eTag: string, environmentSettings: table<name: string, value: string>, executionInfo: record<containerInfo: record<containerId: string, error: string, state: string>, endTime: string, exitCode: int, failureInfo: record<category: string, code: string, details: list, message: string>, lastRequeueTime: string, lastRetryTime: string, requeueCount: int, result: string, retryCount: int, startTime: string>, exitConditions: record<default: record<dependencyAction: string, jobAction: string>, exitCodeRanges: list<record>, exitCodes: list<record>, fileUploadError: record<dependencyAction: string, jobAction: string>, preProcessingError: record<dependencyAction: string, jobAction: string>>, id: string, lastModified: string, multiInstanceSettings: record<commonResourceFiles: list<record>, coordinationCommandLine: string, numberOfInstances: int>, nodeInfo: record<affinityId: string, nodeId: string, nodeUrl: string, poolId: string, taskRootDirectory: string, taskRootDirectoryUrl: string>, outputFiles: table<destination: record, filePattern: string, uploadOptions: record>, previousState: string, previousStateTransitionTime: string, resourceFiles: table<autoStorageContainerName: string, blobPrefix: string, fileMode: string, filePath: string, httpUrl: string, storageContainerUrl: string>, state: string, stateTransitionTime: string, stats: record<kernelCPUTime: string, lastUpdateTime: string, readIOGiB: float, readIOps: int, startTime: string, url: string, userCPUTime: string, waitTime: string, wallClockTime: string, writeIOGiB: float, writeIOps: int>, url: string, userIdentity: record<autoUser: record<elevationLevel: string, scope: string>, username: string>>
# operationId: Task_Get
export def "task-get" [
  job_id: string
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: string # An OData $select clause.
  --expand: string # An OData $expand clause.
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
  --if-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --if-none-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --if-modified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time. (format: date-time-rfc1123)
  --if-unmodified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time. (format: date-time-rfc1123)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/jobs/{jobId}/tasks/{taskId}"
    path_params: [{name: jobId, var: job_id}, {name: taskId, var: task_id}]
    query: [{name: "$select", var: select}, {name: "$expand", var: expand}, {name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}, {name: If-Match, var: if_match}, {name: If-None-Match, var: if_none_match}, {name: If-Modified-Since, var: if_modified_since}, {name: If-Unmodified-Since, var: if_unmodified_since}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    job_id: $job_id, task_id: $task_id, select: $select, expand: $expand, timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date, if_match: $if_match, if_none_match: $if_none_match, if_modified_since: $if_modified_since, if_unmodified_since: $if_unmodified_since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the properties of the specified Task.
#
# PUT /jobs/{jobId}/tasks/{taskId}
# operationId: Task_Update
export def "task-update" [
  job_id: string
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
  --if-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --if-none-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --if-modified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time. (format: date-time-rfc1123)
  --if-unmodified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time. (format: date-time-rfc1123)
  --constraints: any # shape: {maxTaskRetryCount?: int, maxWallClockTime?: string, retentionTime?: string}
]: any -> any {
  $in | http-request {
    method: put
    path: "/jobs/{jobId}/tasks/{taskId}"
    path_params: [{name: jobId, var: job_id}, {name: taskId, var: task_id}]
    query: [{name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}, {name: If-Match, var: if_match}, {name: If-None-Match, var: if_none_match}, {name: If-Modified-Since, var: if_modified_since}, {name: If-Unmodified-Since, var: if_unmodified_since}]
    body: {content_type: "application/json; odata=minimalmetadata", kind: json, fields: [{name: constraints, var: constraints}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    job_id: $job_id, task_id: $task_id, timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date, if_match: $if_match, if_none_match: $if_none_match, if_modified_since: $if_modified_since, if_unmodified_since: $if_unmodified_since, constraints: $constraints
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the files in a Task's directory on its Compute Node.
#
# GET /jobs/{jobId}/tasks/{taskId}/files
# Returns: record<"odata.nextLink": string, value: table<isDirectory: bool, name: string, properties: record, url: string>>
# operationId: File_ListFromTask
export def "file-list-from-task" [
  job_id: string
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # An OData $filter clause. For more information on constructing this filter, see https://docs.microsoft.com/en-us/rest/api/batchservice/odata-filters-in-batch#list-task-files.
  --recursive: oneof<nothing, bool> # Whether to list children of the Task directory. This parameter can be used in combination with the filter parameter to list specific type of files.
  --maxresults: int # The maximum number of items to return in the response. A maximum of 1000 files can be returned. (format: int32, default: 1000)
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/jobs/{jobId}/tasks/{taskId}/files"
    path_params: [{name: jobId, var: job_id}, {name: taskId, var: task_id}]
    query: [{name: "$filter", var: filter}, {name: recursive, var: recursive}, {name: maxresults, var: maxresults}, {name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    job_id: $job_id, task_id: $task_id, filter: $filter, recursive: $recursive, maxresults: $maxresults, timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified Task file from the Compute Node where the Task ran.
#
# DELETE /jobs/{jobId}/tasks/{taskId}/files/{filePath}
# operationId: File_DeleteFromTask
export def "file-delete-from-task" [
  job_id: string
  task_id: string
  file_path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --recursive: oneof<nothing, bool> # Whether to delete children of a directory. If the filePath parameter represents a directory instead of a file, you can set recursive to true to delete the directory and all of the files and subdirectories in it. If recursive is false then the directory must be empty or deletion will fail.
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
]: nothing -> any {
  http-request {
    method: delete
    path: "/jobs/{jobId}/tasks/{taskId}/files/{filePath}"
    path_params: [{name: jobId, var: job_id}, {name: taskId, var: task_id}, {name: filePath, var: file_path}]
    query: [{name: recursive, var: recursive}, {name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    job_id: $job_id, task_id: $task_id, file_path: $file_path, recursive: $recursive, timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the content of the specified Task file.
#
# GET /jobs/{jobId}/tasks/{taskId}/files/{filePath}
# Returns: binary
# operationId: File_GetFromTask
export def "file-get-from-task" [
  job_id: string
  task_id: string
  file_path: string
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
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
  --ocp-range: string # The byte range to be retrieved. The default is to retrieve the entire file. The format is bytes=startRange-endRange.
  --if-modified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time. (format: date-time-rfc1123)
  --if-unmodified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time. (format: date-time-rfc1123)
]: nothing -> any {
  http-request {
    method: get
    path: "/jobs/{jobId}/tasks/{taskId}/files/{filePath}"
    path_params: [{name: jobId, var: job_id}, {name: taskId, var: task_id}, {name: filePath, var: file_path}]
    query: [{name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}, {name: ocp-range, var: ocp_range}, {name: If-Modified-Since, var: if_modified_since}, {name: If-Unmodified-Since, var: if_unmodified_since}]
    accept: ["application/json", "application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    job_id: $job_id, task_id: $task_id, file_path: $file_path, timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date, ocp_range: $ocp_range, if_modified_since: $if_modified_since, if_unmodified_since: $if_unmodified_since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the properties of the specified Task file.
#
# HEAD /jobs/{jobId}/tasks/{taskId}/files/{filePath}
# Returns: record
# operationId: File_GetPropertiesFromTask
export def "file-get-properties-from-task" [
  job_id: string
  task_id: string
  file_path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
  --if-modified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time. (format: date-time-rfc1123)
  --if-unmodified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time. (format: date-time-rfc1123)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: head
    path: "/jobs/{jobId}/tasks/{taskId}/files/{filePath}"
    path_params: [{name: jobId, var: job_id}, {name: taskId, var: task_id}, {name: filePath, var: file_path}]
    query: [{name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}, {name: If-Modified-Since, var: if_modified_since}, {name: If-Unmodified-Since, var: if_unmodified_since}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    job_id: $job_id, task_id: $task_id, file_path: $file_path, timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date, if_modified_since: $if_modified_since, if_unmodified_since: $if_unmodified_since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reactivates a Task, allowing it to run again even if its retry count has been exhausted.
#
# POST /jobs/{jobId}/tasks/{taskId}/reactivate
# operationId: Task_Reactivate
export def "task-reactivate" [
  job_id: string
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
  --if-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --if-none-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --if-modified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time. (format: date-time-rfc1123)
  --if-unmodified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time. (format: date-time-rfc1123)
]: nothing -> any {
  http-request {
    method: post
    path: "/jobs/{jobId}/tasks/{taskId}/reactivate"
    path_params: [{name: jobId, var: job_id}, {name: taskId, var: task_id}]
    query: [{name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}, {name: If-Match, var: if_match}, {name: If-None-Match, var: if_none_match}, {name: If-Modified-Since, var: if_modified_since}, {name: If-Unmodified-Since, var: if_unmodified_since}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    job_id: $job_id, task_id: $task_id, timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date, if_match: $if_match, if_none_match: $if_none_match, if_modified_since: $if_modified_since, if_unmodified_since: $if_unmodified_since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all of the subtasks that are associated with the specified multi-instance Task.
#
# GET /jobs/{jobId}/tasks/{taskId}/subtasksinfo
# Returns: record<value: table<containerInfo: record, endTime: string, exitCode: int, failureInfo: record, id: int, nodeInfo: record, previousState: string, previousStateTransitionTime: string, result: string, startTime: string, state: string, stateTransitionTime: string>>
# operationId: Task_ListSubtasks
export def "task-list-subtasks" [
  job_id: string
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: string # An OData $select clause.
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/jobs/{jobId}/tasks/{taskId}/subtasksinfo"
    path_params: [{name: jobId, var: job_id}, {name: taskId, var: task_id}]
    query: [{name: "$select", var: select}, {name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    job_id: $job_id, task_id: $task_id, select: $select, timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Terminates the specified Task.
#
# POST /jobs/{jobId}/tasks/{taskId}/terminate
# operationId: Task_Terminate
export def "task-terminate" [
  job_id: string
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
  --if-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --if-none-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --if-modified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time. (format: date-time-rfc1123)
  --if-unmodified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time. (format: date-time-rfc1123)
]: nothing -> any {
  http-request {
    method: post
    path: "/jobs/{jobId}/tasks/{taskId}/terminate"
    path_params: [{name: jobId, var: job_id}, {name: taskId, var: task_id}]
    query: [{name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}, {name: If-Match, var: if_match}, {name: If-None-Match, var: if_none_match}, {name: If-Modified-Since, var: if_modified_since}, {name: If-Unmodified-Since, var: if_unmodified_since}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    job_id: $job_id, task_id: $task_id, timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date, if_match: $if_match, if_none_match: $if_none_match, if_modified_since: $if_modified_since, if_unmodified_since: $if_unmodified_since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Terminates the specified Job, marking it as completed.
#
# POST /jobs/{jobId}/terminate
# operationId: Job_Terminate
export def "job-terminate" [
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
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
  --if-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --if-none-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --if-modified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time. (format: date-time-rfc1123)
  --if-unmodified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time. (format: date-time-rfc1123)
  --terminate-reason: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/jobs/{jobId}/terminate"
    path_params: [{name: jobId, var: job_id}]
    query: [{name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}, {name: If-Match, var: if_match}, {name: If-None-Match, var: if_none_match}, {name: If-Modified-Since, var: if_modified_since}, {name: If-Unmodified-Since, var: if_unmodified_since}]
    body: {content_type: "application/json; odata=minimalmetadata", kind: json, fields: [{name: terminateReason, var: terminate_reason}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    job_id: $job_id, timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date, if_match: $if_match, if_none_match: $if_none_match, if_modified_since: $if_modified_since, if_unmodified_since: $if_unmodified_since, terminate_reason: $terminate_reason
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all of the Job Schedules in the specified Account.
#
# GET /jobschedules
# Returns: record<"odata.nextLink": string, value: table<creationTime: string, displayName: string, eTag: string, executionInfo: record, id: string, jobSpecification: record, lastModified: string, metadata: list, previousState: string, previousStateTransitionTime: string, schedule: record, state: string, stateTransitionTime: string, stats: record, url: string>>
# operationId: JobSchedule_List
export def "job-schedule-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # An OData $filter clause. For more information on constructing this filter, see https://docs.microsoft.com/en-us/rest/api/batchservice/odata-filters-in-batch#list-job-schedules.
  --select: string # An OData $select clause.
  --expand: string # An OData $expand clause.
  --maxresults: int # The maximum number of items to return in the response. A maximum of 1000 Job Schedules can be returned. (format: int32, default: 1000)
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/jobschedules"
    query: [{name: "$filter", var: filter}, {name: "$select", var: select}, {name: "$expand", var: expand}, {name: maxresults, var: maxresults}, {name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter: $filter, select: $select, expand: $expand, maxresults: $maxresults, timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a Job Schedule to the specified Account.
#
# POST /jobschedules
# operationId: JobSchedule_Add
export def "job-schedule-add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
  --display-name: string # The display name need not be unique and can contain any Unicode characters up to a maximum length of 1024.
  id: string # The ID can contain any combination of alphanumeric characters including hyphens and underscores, and cannot contain more than 64 characters. The ID is case-preserving and case-insensitive (that is, you may not have two IDs within an Account that differ only by case).
  job_specification: any # shape: {commonEnvironmentSettings?: list, constraints?: any, displayName?: string, jobManagerTask?: any, jobPreparationTask?: any, jobReleaseTask?: any, metadata?: list, networkConfiguration?: any, onAllTasksComplete?: "noaction"|"terminatejob", onTaskFailure?: "noaction"|"performexitoptionsjobaction", poolInfo: any, priority?: int, usesTaskDependencies?: bool}
  --metadata: list # The Batch service does not assign any meaning to metadata; it is solely for the use of user code. — item shape: {name: string, value: string}
  schedule: any # shape: {doNotRunAfter?: string, doNotRunUntil?: string, recurrenceInterval?: string, startWindow?: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/jobschedules"
    query: [{name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}]
    body: {content_type: "application/json; odata=minimalmetadata", kind: json, fields: [{name: displayName, var: display_name}, {name: id, var: id}, {name: jobSpecification, var: job_specification}, {name: metadata, var: metadata}, {name: schedule, var: schedule}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date, display_name: $display_name, id: $id, job_specification: $job_specification, metadata: $metadata, schedule: $schedule
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a Job Schedule from the specified Account.
#
# DELETE /jobschedules/{jobScheduleId}
# operationId: JobSchedule_Delete
export def "job-schedule-delete" [
  job_schedule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
  --if-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --if-none-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --if-modified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time. (format: date-time-rfc1123)
  --if-unmodified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time. (format: date-time-rfc1123)
]: nothing -> any {
  http-request {
    method: delete
    path: "/jobschedules/{jobScheduleId}"
    path_params: [{name: jobScheduleId, var: job_schedule_id}]
    query: [{name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}, {name: If-Match, var: if_match}, {name: If-None-Match, var: if_none_match}, {name: If-Modified-Since, var: if_modified_since}, {name: If-Unmodified-Since, var: if_unmodified_since}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    job_schedule_id: $job_schedule_id, timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date, if_match: $if_match, if_none_match: $if_none_match, if_modified_since: $if_modified_since, if_unmodified_since: $if_unmodified_since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the specified Job Schedule.
#
# GET /jobschedules/{jobScheduleId}
# Returns: record<creationTime: string, displayName: string, eTag: string, executionInfo: record<endTime: string, nextRunTime: string, recentJob: record<id: string, url: string>>, id: string, jobSpecification: record<commonEnvironmentSettings: list<record>, constraints: record<maxTaskRetryCount: int, maxWallClockTime: string>, displayName: string, jobManagerTask: record<allowLowPriorityNode: bool, applicationPackageReferences: list, authenticationTokenSettings: record, commandLine: string, constraints: record, containerSettings: record, displayName: string, environmentSettings: list, id: string, killJobOnCompletion: bool, outputFiles: list, resourceFiles: list, runExclusive: bool, userIdentity: record>, jobPreparationTask: record<commandLine: string, constraints: record, containerSettings: record, environmentSettings: list, id: string, rerunOnNodeRebootAfterSuccess: bool, resourceFiles: list, userIdentity: record, waitForSuccess: bool>, jobReleaseTask: record<commandLine: string, containerSettings: record, environmentSettings: list, id: string, maxWallClockTime: string, resourceFiles: list, retentionTime: string, userIdentity: record>, metadata: list<record>, networkConfiguration: record<subnetId: string>, onAllTasksComplete: string, onTaskFailure: string, poolInfo: record<autoPoolSpecification: record, poolId: string>, priority: int, usesTaskDependencies: bool>, lastModified: string, metadata: table<name: string, value: string>, previousState: string, previousStateTransitionTime: string, schedule: record<doNotRunAfter: string, doNotRunUntil: string, recurrenceInterval: string, startWindow: string>, state: string, stateTransitionTime: string, stats: record<kernelCPUTime: string, lastUpdateTime: string, numFailedTasks: int, numSucceededTasks: int, numTaskRetries: int, readIOGiB: float, readIOps: int, startTime: string, url: string, userCPUTime: string, waitTime: string, wallClockTime: string, writeIOGiB: float, writeIOps: int>, url: string>
# operationId: JobSchedule_Get
export def "job-schedule-get" [
  job_schedule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: string # An OData $select clause.
  --expand: string # An OData $expand clause.
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
  --if-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --if-none-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --if-modified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time. (format: date-time-rfc1123)
  --if-unmodified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time. (format: date-time-rfc1123)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/jobschedules/{jobScheduleId}"
    path_params: [{name: jobScheduleId, var: job_schedule_id}]
    query: [{name: "$select", var: select}, {name: "$expand", var: expand}, {name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}, {name: If-Match, var: if_match}, {name: If-None-Match, var: if_none_match}, {name: If-Modified-Since, var: if_modified_since}, {name: If-Unmodified-Since, var: if_unmodified_since}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    job_schedule_id: $job_schedule_id, select: $select, expand: $expand, timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date, if_match: $if_match, if_none_match: $if_none_match, if_modified_since: $if_modified_since, if_unmodified_since: $if_unmodified_since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Checks the specified Job Schedule exists.
#
# HEAD /jobschedules/{jobScheduleId}
# Returns: record
# operationId: JobSchedule_Exists
export def "job-schedule-exists" [
  job_schedule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
  --if-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --if-none-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --if-modified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time. (format: date-time-rfc1123)
  --if-unmodified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time. (format: date-time-rfc1123)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: head
    path: "/jobschedules/{jobScheduleId}"
    path_params: [{name: jobScheduleId, var: job_schedule_id}]
    query: [{name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}, {name: If-Match, var: if_match}, {name: If-None-Match, var: if_none_match}, {name: If-Modified-Since, var: if_modified_since}, {name: If-Unmodified-Since, var: if_unmodified_since}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    job_schedule_id: $job_schedule_id, timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date, if_match: $if_match, if_none_match: $if_none_match, if_modified_since: $if_modified_since, if_unmodified_since: $if_unmodified_since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the properties of the specified Job Schedule.
#
# PATCH /jobschedules/{jobScheduleId}
# operationId: JobSchedule_Patch
export def "job-schedule-patch" [
  job_schedule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
  --if-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --if-none-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --if-modified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time. (format: date-time-rfc1123)
  --if-unmodified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time. (format: date-time-rfc1123)
  --job-specification: any # shape: {commonEnvironmentSettings?: list, constraints?: any, displayName?: string, jobManagerTask?: any, jobPreparationTask?: any, jobReleaseTask?: any, metadata?: list, networkConfiguration?: any, onAllTasksComplete?: "noaction"|"terminatejob", onTaskFailure?: "noaction"|"performexitoptionsjobaction", poolInfo: any, priority?: int, usesTaskDependencies?: bool}
  --metadata: list # If you do not specify this element, existing metadata is left unchanged. — item shape: {name: string, value: string}
  --schedule: any # shape: {doNotRunAfter?: string, doNotRunUntil?: string, recurrenceInterval?: string, startWindow?: string}
]: any -> any {
  $in | http-request {
    method: patch
    path: "/jobschedules/{jobScheduleId}"
    path_params: [{name: jobScheduleId, var: job_schedule_id}]
    query: [{name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}, {name: If-Match, var: if_match}, {name: If-None-Match, var: if_none_match}, {name: If-Modified-Since, var: if_modified_since}, {name: If-Unmodified-Since, var: if_unmodified_since}]
    body: {content_type: "application/json; odata=minimalmetadata", kind: json, fields: [{name: jobSpecification, var: job_specification}, {name: metadata, var: metadata}, {name: schedule, var: schedule}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    job_schedule_id: $job_schedule_id, timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date, if_match: $if_match, if_none_match: $if_none_match, if_modified_since: $if_modified_since, if_unmodified_since: $if_unmodified_since, job_specification: $job_specification, metadata: $metadata, schedule: $schedule
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the properties of the specified Job Schedule.
#
# PUT /jobschedules/{jobScheduleId}
# operationId: JobSchedule_Update
export def "job-schedule-update" [
  job_schedule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
  --if-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --if-none-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --if-modified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time. (format: date-time-rfc1123)
  --if-unmodified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time. (format: date-time-rfc1123)
  job_specification: any # shape: {commonEnvironmentSettings?: list, constraints?: any, displayName?: string, jobManagerTask?: any, jobPreparationTask?: any, jobReleaseTask?: any, metadata?: list, networkConfiguration?: any, onAllTasksComplete?: "noaction"|"terminatejob", onTaskFailure?: "noaction"|"performexitoptionsjobaction", poolInfo: any, priority?: int, usesTaskDependencies?: bool}
  --metadata: list # If you do not specify this element, it takes the default value of an empty list; in effect, any existing metadata is deleted. — item shape: {name: string, value: string}
  schedule: any # shape: {doNotRunAfter?: string, doNotRunUntil?: string, recurrenceInterval?: string, startWindow?: string}
]: any -> any {
  $in | http-request {
    method: put
    path: "/jobschedules/{jobScheduleId}"
    path_params: [{name: jobScheduleId, var: job_schedule_id}]
    query: [{name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}, {name: If-Match, var: if_match}, {name: If-None-Match, var: if_none_match}, {name: If-Modified-Since, var: if_modified_since}, {name: If-Unmodified-Since, var: if_unmodified_since}]
    body: {content_type: "application/json; odata=minimalmetadata", kind: json, fields: [{name: jobSpecification, var: job_specification}, {name: metadata, var: metadata}, {name: schedule, var: schedule}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    job_schedule_id: $job_schedule_id, timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date, if_match: $if_match, if_none_match: $if_none_match, if_modified_since: $if_modified_since, if_unmodified_since: $if_unmodified_since, job_specification: $job_specification, metadata: $metadata, schedule: $schedule
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disables a Job Schedule.
#
# POST /jobschedules/{jobScheduleId}/disable
# operationId: JobSchedule_Disable
export def "job-schedule-disable" [
  job_schedule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
  --if-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --if-none-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --if-modified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time. (format: date-time-rfc1123)
  --if-unmodified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time. (format: date-time-rfc1123)
]: nothing -> any {
  http-request {
    method: post
    path: "/jobschedules/{jobScheduleId}/disable"
    path_params: [{name: jobScheduleId, var: job_schedule_id}]
    query: [{name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}, {name: If-Match, var: if_match}, {name: If-None-Match, var: if_none_match}, {name: If-Modified-Since, var: if_modified_since}, {name: If-Unmodified-Since, var: if_unmodified_since}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    job_schedule_id: $job_schedule_id, timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date, if_match: $if_match, if_none_match: $if_none_match, if_modified_since: $if_modified_since, if_unmodified_since: $if_unmodified_since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enables a Job Schedule.
#
# POST /jobschedules/{jobScheduleId}/enable
# operationId: JobSchedule_Enable
export def "job-schedule-enable" [
  job_schedule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
  --if-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --if-none-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --if-modified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time. (format: date-time-rfc1123)
  --if-unmodified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time. (format: date-time-rfc1123)
]: nothing -> any {
  http-request {
    method: post
    path: "/jobschedules/{jobScheduleId}/enable"
    path_params: [{name: jobScheduleId, var: job_schedule_id}]
    query: [{name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}, {name: If-Match, var: if_match}, {name: If-None-Match, var: if_none_match}, {name: If-Modified-Since, var: if_modified_since}, {name: If-Unmodified-Since, var: if_unmodified_since}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    job_schedule_id: $job_schedule_id, timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date, if_match: $if_match, if_none_match: $if_none_match, if_modified_since: $if_modified_since, if_unmodified_since: $if_unmodified_since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the Jobs that have been created under the specified Job Schedule.
#
# GET /jobschedules/{jobScheduleId}/jobs
# Returns: record<"odata.nextLink": string, value: table<commonEnvironmentSettings: list, constraints: record, creationTime: string, displayName: string, eTag: string, executionInfo: record, id: string, jobManagerTask: record, jobPreparationTask: record, jobReleaseTask: record, lastModified: string, metadata: list, networkConfiguration: record, onAllTasksComplete: string, onTaskFailure: string, poolInfo: record, previousState: string, previousStateTransitionTime: string, priority: int, state: string, stateTransitionTime: string, stats: record, url: string, usesTaskDependencies: bool>>
# operationId: Job_ListFromJobSchedule
export def "job-list-from-job-schedule" [
  job_schedule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # An OData $filter clause. For more information on constructing this filter, see https://docs.microsoft.com/en-us/rest/api/batchservice/odata-filters-in-batch#list-jobs-in-a-job-schedule.
  --select: string # An OData $select clause.
  --expand: string # An OData $expand clause.
  --maxresults: int # The maximum number of items to return in the response. A maximum of 1000 Jobs can be returned. (format: int32, default: 1000)
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/jobschedules/{jobScheduleId}/jobs"
    path_params: [{name: jobScheduleId, var: job_schedule_id}]
    query: [{name: "$filter", var: filter}, {name: "$select", var: select}, {name: "$expand", var: expand}, {name: maxresults, var: maxresults}, {name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    job_schedule_id: $job_schedule_id, filter: $filter, select: $select, expand: $expand, maxresults: $maxresults, timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Terminates a Job Schedule.
#
# POST /jobschedules/{jobScheduleId}/terminate
# operationId: JobSchedule_Terminate
export def "job-schedule-terminate" [
  job_schedule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
  --if-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --if-none-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --if-modified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time. (format: date-time-rfc1123)
  --if-unmodified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time. (format: date-time-rfc1123)
]: nothing -> any {
  http-request {
    method: post
    path: "/jobschedules/{jobScheduleId}/terminate"
    path_params: [{name: jobScheduleId, var: job_schedule_id}]
    query: [{name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}, {name: If-Match, var: if_match}, {name: If-None-Match, var: if_none_match}, {name: If-Modified-Since, var: if_modified_since}, {name: If-Unmodified-Since, var: if_unmodified_since}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    job_schedule_id: $job_schedule_id, timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date, if_match: $if_match, if_none_match: $if_none_match, if_modified_since: $if_modified_since, if_unmodified_since: $if_unmodified_since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets lifetime summary statistics for all of the Jobs in the specified Account.
#
# GET /lifetimejobstats
# Returns: record<kernelCPUTime: string, lastUpdateTime: string, numFailedTasks: int, numSucceededTasks: int, numTaskRetries: int, readIOGiB: float, readIOps: int, startTime: string, url: string, userCPUTime: string, waitTime: string, wallClockTime: string, writeIOGiB: float, writeIOps: int>
# operationId: Job_GetAllLifetimeStatistics
export def "job-get-all-lifetime-statistics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/lifetimejobstats"
    query: [{name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets lifetime summary statistics for all of the Pools in the specified Account.
#
# GET /lifetimepoolstats
# Returns: record<lastUpdateTime: string, resourceStats: record<avgCPUPercentage: float, avgDiskGiB: float, avgMemoryGiB: float, diskReadGiB: float, diskReadIOps: int, diskWriteGiB: float, diskWriteIOps: int, lastUpdateTime: string, networkReadGiB: float, networkWriteGiB: float, peakDiskGiB: float, peakMemoryGiB: float, startTime: string>, startTime: string, url: string, usageStats: record<dedicatedCoreTime: string, lastUpdateTime: string, startTime: string>>
# operationId: Pool_GetAllLifetimeStatistics
export def "pool-get-all-lifetime-statistics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/lifetimepoolstats"
    query: [{name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the number of Compute Nodes in each state, grouped by Pool.
#
# GET /nodecounts
# Returns: record<"odata.nextLink": string, value: table<dedicated: record, lowPriority: record, poolId: string>>
# operationId: Account_ListPoolNodeCounts
export def "account-list-pool-node-counts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # An OData $filter clause. For more information on constructing this filter, see https://docs.microsoft.com/en-us/rest/api/batchservice/odata-filters-in-batch.
  --maxresults: int # The maximum number of items to return in the response. (format: int32, default: 10)
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/nodecounts"
    query: [{name: "$filter", var: filter}, {name: maxresults, var: maxresults}, {name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter: $filter, maxresults: $maxresults, timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all of the Pools in the specified Account.
#
# GET /pools
# Returns: record<"odata.nextLink": string, value: table<allocationState: string, allocationStateTransitionTime: string, applicationLicenses: list, applicationPackageReferences: list, autoScaleEvaluationInterval: string, autoScaleFormula: string, autoScaleRun: record, certificateReferences: list, cloudServiceConfiguration: record, creationTime: string, currentDedicatedNodes: int, currentLowPriorityNodes: int, displayName: string, eTag: string, enableAutoScale: bool, enableInterNodeCommunication: bool, id: string, lastModified: string, maxTasksPerNode: int, metadata: list, mountConfiguration: list, networkConfiguration: record, resizeErrors: list, resizeTimeout: string, startTask: record, state: string, stateTransitionTime: string, stats: record, targetDedicatedNodes: int, targetLowPriorityNodes: int, taskSchedulingPolicy: record, url: string, userAccounts: list, virtualMachineConfiguration: record, vmSize: string>>
# operationId: Pool_List
export def "pool-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # An OData $filter clause. For more information on constructing this filter, see https://docs.microsoft.com/en-us/rest/api/batchservice/odata-filters-in-batch#list-pools.
  --select: string # An OData $select clause.
  --expand: string # An OData $expand clause.
  --maxresults: int # The maximum number of items to return in the response. A maximum of 1000 Pools can be returned. (format: int32, default: 1000)
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/pools"
    query: [{name: "$filter", var: filter}, {name: "$select", var: select}, {name: "$expand", var: expand}, {name: maxresults, var: maxresults}, {name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter: $filter, select: $select, expand: $expand, maxresults: $maxresults, timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a Pool to the specified Account.
#
# POST /pools
# operationId: Pool_Add
export def "pool-add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
  --application-licenses: list<string> # The list of application licenses must be a subset of available Batch service application licenses. If a license is requested which is not supported, Pool creation will fail.
  --application-package-references: list # Changes to Package references affect all new Nodes joining the Pool, but do not affect Compute Nodes that are already in the Pool until they are rebooted or reimaged. There is a maximum of 10 Package references on any given Pool. — item shape: {applicationId: string, version?: string}
  --auto-scale-evaluation-interval: string # The default value is 15 minutes. The minimum and maximum value are 5 minutes and 168 hours respectively. If you specify a value less than 5 minutes or greater than 168 hours, the Batch service returns an error; if you are calling the REST API directly, the HTTP status code is 400 (Bad Request). (format: duration)
  --auto-scale-formula: string # This property must not be specified if enableAutoScale is set to false. It is required if enableAutoScale is set to true. The formula is checked for validity before the Pool is created. If the formula is not valid, the Batch service rejects the request with detailed error information. For more information about specifying this formula, see 'Automatically scale Compute Nodes in an Azure Batch Pool' (https://azure.microsoft.com/documentation/articles/batch-automatic-scaling/).
  --certificate-references: list # For Windows Nodes, the Batch service installs the Certificates to the specified Certificate store and location. For Linux Compute Nodes, the Certificates are stored in a directory inside the Task working directory and an environment variable AZ_BATCH_CERTIFICATES_DIR is supplied to the Task to query for this location. For Certificates with visibility of 'remoteUser', a 'certs' directory is created in the user's home directory (e.g., /home/{user-name}/certs) and Certificates are placed in that directory. — item shape: {storeLocation?: "currentuser"|"localmachine", storeName?: string, thumbprint: string, thumbprintAlgorithm: string, visibility?: list<string>}
  --cloud-service-configuration: any # shape: {osFamily: string, osVersion?: string}
  --display-name: string # The display name need not be unique and can contain any Unicode characters up to a maximum length of 1024.
  --enable-auto-scale: oneof<nothing, bool> # If false, at least one of targetDedicateNodes and targetLowPriorityNodes must be specified. If true, the autoScaleFormula property is required and the Pool automatically resizes according to the formula. The default value is false.
  --enable-inter-node-communication: oneof<nothing, bool> # Enabling inter-node communication limits the maximum size of the Pool due to deployment restrictions on the Compute Nodes of the Pool. This may result in the Pool not reaching its desired size. The default value is false.
  id: string # The ID can contain any combination of alphanumeric characters including hyphens and underscores, and cannot contain more than 64 characters. The ID is case-preserving and case-insensitive (that is, you may not have two Pool IDs within an Account that differ only by case).
  --max-tasks-per-node: int # The default value is 1. The maximum value is the smaller of 4 times the number of cores of the vmSize of the Pool or 256. (format: int32)
  --metadata: list # The Batch service does not assign any meaning to metadata; it is solely for the use of user code. — item shape: {name: string, value: string}
  --mount-configuration: list # Mount the storage using Azure fileshare, NFS, CIFS or Blobfuse based file system. — item shape: {azureBlobFileSystemConfiguration?: any, azureFileShareConfiguration?: any, cifsMountConfiguration?: any, nfsMountConfiguration?: any}
  --network-configuration: any # The network configuration for a Pool. — shape: {dynamicVNetAssignmentScope?: "none"|"job", endpointConfiguration?: any, publicIPs?: list<string>, subnetId?: string}
  --resize-timeout: string # This timeout applies only to manual scaling; it has no effect when enableAutoScale is set to true. The default value is 15 minutes. The minimum value is 5 minutes. If you specify a value less than 5 minutes, the Batch service returns an error; if you are calling the REST API directly, the HTTP status code is 400 (Bad Request). (format: duration)
  --start-task: any # Batch will retry Tasks when a recovery operation is triggered on a Node. Examples of recovery operations include (but are not limited to) when an unhealthy Node is rebooted or a Compute Node disappeared due to host failure. Retries due to recovery operations are independent of and are not counted against the maxTaskRetryCount. Even if the maxTaskRetryCount is 0, an internal retry due to a recovery operation may occur. Because of this, all Tasks should be idempotent. This means Tasks need to tolerate being interrupted and restarted without causing any corruption or duplicate data. The best practice for long running Tasks is to use some form of checkpointing. In some cases the StartTask may be re-run even though the Compute Node was not rebooted. Special care should be taken to avoid StartTasks which create breakaway process or install/launch services from the StartTask working directory, as this will block Batch from being able to re-run the StartTask. — shape: {commandLine: string, containerSettings?: any, environmentSettings?: list, maxTaskRetryCount?: int, resourceFiles?: list, userIdentity?: any, waitForSuccess?: bool}
  --target-dedicated-nodes: int # This property must not be specified if enableAutoScale is set to true. If enableAutoScale is set to false, then you must set either targetDedicatedNodes, targetLowPriorityNodes, or both. (format: int32)
  --target-low-priority-nodes: int # This property must not be specified if enableAutoScale is set to true. If enableAutoScale is set to false, then you must set either targetDedicatedNodes, targetLowPriorityNodes, or both. (format: int32)
  --task-scheduling-policy: any # shape: {nodeFillType: "spread"|"pack"}
  --user-accounts: list # item shape: {elevationLevel?: "nonadmin"|"admin", linuxUserConfiguration?: any, name: string, password: string, windowsUserConfiguration?: any}
  --virtual-machine-configuration: any # shape: {containerConfiguration?: any, dataDisks?: list, imageReference: any, licenseType?: string, nodeAgentSKUId: string, windowsConfiguration?: any}
  vm_size: string # For information about available sizes of virtual machines for Cloud Services Pools (pools created with cloudServiceConfiguration), see Sizes for Cloud Services (https://azure.microsoft.com/documentation/articles/cloud-services-sizes-specs/). Batch supports all Cloud Services VM sizes except ExtraSmall, A1V2 and A2V2. For information about available VM sizes for Pools using Images from the Virtual Machines Marketplace (pools created with virtualMachineConfiguration) see Sizes for Virtual Machines (Linux) (https://azure.microsoft.com/documentation/articles/virtual-machines-linux-sizes/) or Sizes for Virtual Machines (Windows) (https://azure.microsoft.com/documentation/articles/virtual-machines-windows-sizes/). Batch supports all Azure VM sizes except STANDARD_A0 and those with premium storage (STANDARD_GS, STANDARD_DS, and STANDARD_DSV2 series).
]: any -> any {
  $in | http-request {
    method: post
    path: "/pools"
    query: [{name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}]
    body: {content_type: "application/json; odata=minimalmetadata", kind: json, fields: [{name: applicationLicenses, var: application_licenses}, {name: applicationPackageReferences, var: application_package_references}, {name: autoScaleEvaluationInterval, var: auto_scale_evaluation_interval}, {name: autoScaleFormula, var: auto_scale_formula}, {name: certificateReferences, var: certificate_references}, {name: cloudServiceConfiguration, var: cloud_service_configuration}, {name: displayName, var: display_name}, {name: enableAutoScale, var: enable_auto_scale}, {name: enableInterNodeCommunication, var: enable_inter_node_communication}, {name: id, var: id}, {name: maxTasksPerNode, var: max_tasks_per_node}, {name: metadata, var: metadata}, {name: mountConfiguration, var: mount_configuration}, {name: networkConfiguration, var: network_configuration}, {name: resizeTimeout, var: resize_timeout}, {name: startTask, var: start_task}, {name: targetDedicatedNodes, var: target_dedicated_nodes}, {name: targetLowPriorityNodes, var: target_low_priority_nodes}, {name: taskSchedulingPolicy, var: task_scheduling_policy}, {name: userAccounts, var: user_accounts}, {name: virtualMachineConfiguration, var: virtual_machine_configuration}, {name: vmSize, var: vm_size}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date, application_licenses: $application_licenses, application_package_references: $application_package_references, auto_scale_evaluation_interval: $auto_scale_evaluation_interval, auto_scale_formula: $auto_scale_formula, certificate_references: $certificate_references, cloud_service_configuration: $cloud_service_configuration, display_name: $display_name, enable_auto_scale: $enable_auto_scale, enable_inter_node_communication: $enable_inter_node_communication, id: $id, max_tasks_per_node: $max_tasks_per_node, metadata: $metadata, mount_configuration: $mount_configuration, network_configuration: $network_configuration, resize_timeout: $resize_timeout, start_task: $start_task, target_dedicated_nodes: $target_dedicated_nodes, target_low_priority_nodes: $target_low_priority_nodes, task_scheduling_policy: $task_scheduling_policy, user_accounts: $user_accounts, virtual_machine_configuration: $virtual_machine_configuration, vm_size: $vm_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a Pool from the specified Account.
#
# DELETE /pools/{poolId}
# operationId: Pool_Delete
export def "pool-delete" [
  pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
  --if-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --if-none-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --if-modified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time. (format: date-time-rfc1123)
  --if-unmodified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time. (format: date-time-rfc1123)
]: nothing -> any {
  http-request {
    method: delete
    path: "/pools/{poolId}"
    path_params: [{name: poolId, var: pool_id}]
    query: [{name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}, {name: If-Match, var: if_match}, {name: If-None-Match, var: if_none_match}, {name: If-Modified-Since, var: if_modified_since}, {name: If-Unmodified-Since, var: if_unmodified_since}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    pool_id: $pool_id, timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date, if_match: $if_match, if_none_match: $if_none_match, if_modified_since: $if_modified_since, if_unmodified_since: $if_unmodified_since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the specified Pool.
#
# GET /pools/{poolId}
# Returns: record<allocationState: string, allocationStateTransitionTime: string, applicationLicenses: list<string>, applicationPackageReferences: table<applicationId: string, version: string>, autoScaleEvaluationInterval: string, autoScaleFormula: string, autoScaleRun: record<error: record<code: string, message: string, values: list>, results: string, timestamp: string>, certificateReferences: table<storeLocation: string, storeName: string, thumbprint: string, thumbprintAlgorithm: string, visibility: list>, cloudServiceConfiguration: record<osFamily: string, osVersion: string>, creationTime: string, currentDedicatedNodes: int, currentLowPriorityNodes: int, displayName: string, eTag: string, enableAutoScale: bool, enableInterNodeCommunication: bool, id: string, lastModified: string, maxTasksPerNode: int, metadata: table<name: string, value: string>, mountConfiguration: table<azureBlobFileSystemConfiguration: record, azureFileShareConfiguration: record, cifsMountConfiguration: record, nfsMountConfiguration: record>, networkConfiguration: record<dynamicVNetAssignmentScope: string, endpointConfiguration: record<inboundNATPools: list>, publicIPs: list<string>, subnetId: string>, resizeErrors: table<code: string, message: string, values: list>, resizeTimeout: string, startTask: record<commandLine: string, containerSettings: record<containerRunOptions: string, imageName: string, registry: record, workingDirectory: string>, environmentSettings: list<record>, maxTaskRetryCount: int, resourceFiles: list<record>, userIdentity: record<autoUser: record, username: string>, waitForSuccess: bool>, state: string, stateTransitionTime: string, stats: record<lastUpdateTime: string, resourceStats: record<avgCPUPercentage: float, avgDiskGiB: float, avgMemoryGiB: float, diskReadGiB: float, diskReadIOps: int, diskWriteGiB: float, diskWriteIOps: int, lastUpdateTime: string, networkReadGiB: float, networkWriteGiB: float, peakDiskGiB: float, peakMemoryGiB: float, startTime: string>, startTime: string, url: string, usageStats: record<dedicatedCoreTime: string, lastUpdateTime: string, startTime: string>>, targetDedicatedNodes: int, targetLowPriorityNodes: int, taskSchedulingPolicy: record<nodeFillType: string>, url: string, userAccounts: table<elevationLevel: string, linuxUserConfiguration: record, name: string, password: string, windowsUserConfiguration: record>, virtualMachineConfiguration: record<containerConfiguration: record<containerImageNames: list, containerRegistries: list, type: string>, dataDisks: list<record>, imageReference: record<offer: string, publisher: string, sku: string, version: string, virtualMachineImageId: string>, licenseType: string, nodeAgentSKUId: string, windowsConfiguration: record<enableAutomaticUpdates: bool>>, vmSize: string>
# operationId: Pool_Get
export def "pool-get" [
  pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: string # An OData $select clause.
  --expand: string # An OData $expand clause.
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
  --if-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --if-none-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --if-modified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time. (format: date-time-rfc1123)
  --if-unmodified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time. (format: date-time-rfc1123)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/pools/{poolId}"
    path_params: [{name: poolId, var: pool_id}]
    query: [{name: "$select", var: select}, {name: "$expand", var: expand}, {name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}, {name: If-Match, var: if_match}, {name: If-None-Match, var: if_none_match}, {name: If-Modified-Since, var: if_modified_since}, {name: If-Unmodified-Since, var: if_unmodified_since}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pool_id: $pool_id, select: $select, expand: $expand, timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date, if_match: $if_match, if_none_match: $if_none_match, if_modified_since: $if_modified_since, if_unmodified_since: $if_unmodified_since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets basic properties of a Pool.
#
# HEAD /pools/{poolId}
# Returns: record
# operationId: Pool_Exists
export def "pool-exists" [
  pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
  --if-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --if-none-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --if-modified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time. (format: date-time-rfc1123)
  --if-unmodified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time. (format: date-time-rfc1123)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: head
    path: "/pools/{poolId}"
    path_params: [{name: poolId, var: pool_id}]
    query: [{name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}, {name: If-Match, var: if_match}, {name: If-None-Match, var: if_none_match}, {name: If-Modified-Since, var: if_modified_since}, {name: If-Unmodified-Since, var: if_unmodified_since}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pool_id: $pool_id, timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date, if_match: $if_match, if_none_match: $if_none_match, if_modified_since: $if_modified_since, if_unmodified_since: $if_unmodified_since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the properties of the specified Pool.
#
# PATCH /pools/{poolId}
# operationId: Pool_Patch
export def "pool-patch" [
  pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
  --if-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --if-none-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --if-modified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time. (format: date-time-rfc1123)
  --if-unmodified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time. (format: date-time-rfc1123)
  --application-package-references: list # Changes to Package references affect all new Nodes joining the Pool, but do not affect Compute Nodes that are already in the Pool until they are rebooted or reimaged. If this element is present, it replaces any existing Package references. If you specify an empty collection, then all Package references are removed from the Pool. If omitted, any existing Package references are left unchanged. — item shape: {applicationId: string, version?: string}
  --certificate-references: list # If this element is present, it replaces any existing Certificate references configured on the Pool. If omitted, any existing Certificate references are left unchanged. For Windows Nodes, the Batch service installs the Certificates to the specified Certificate store and location. For Linux Compute Nodes, the Certificates are stored in a directory inside the Task working directory and an environment variable AZ_BATCH_CERTIFICATES_DIR is supplied to the Task to query for this location. For Certificates with visibility of 'remoteUser', a 'certs' directory is created in the user's home directory (e.g., /home/{user-name}/certs) and Certificates are placed in that directory. — item shape: {storeLocation?: "currentuser"|"localmachine", storeName?: string, thumbprint: string, thumbprintAlgorithm: string, visibility?: list<string>}
  --metadata: list # If this element is present, it replaces any existing metadata configured on the Pool. If you specify an empty collection, any metadata is removed from the Pool. If omitted, any existing metadata is left unchanged. — item shape: {name: string, value: string}
  --start-task: any # Batch will retry Tasks when a recovery operation is triggered on a Node. Examples of recovery operations include (but are not limited to) when an unhealthy Node is rebooted or a Compute Node disappeared due to host failure. Retries due to recovery operations are independent of and are not counted against the maxTaskRetryCount. Even if the maxTaskRetryCount is 0, an internal retry due to a recovery operation may occur. Because of this, all Tasks should be idempotent. This means Tasks need to tolerate being interrupted and restarted without causing any corruption or duplicate data. The best practice for long running Tasks is to use some form of checkpointing. In some cases the StartTask may be re-run even though the Compute Node was not rebooted. Special care should be taken to avoid StartTasks which create breakaway process or install/launch services from the StartTask working directory, as this will block Batch from being able to re-run the StartTask. — shape: {commandLine: string, containerSettings?: any, environmentSettings?: list, maxTaskRetryCount?: int, resourceFiles?: list, userIdentity?: any, waitForSuccess?: bool}
]: any -> any {
  $in | http-request {
    method: patch
    path: "/pools/{poolId}"
    path_params: [{name: poolId, var: pool_id}]
    query: [{name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}, {name: If-Match, var: if_match}, {name: If-None-Match, var: if_none_match}, {name: If-Modified-Since, var: if_modified_since}, {name: If-Unmodified-Since, var: if_unmodified_since}]
    body: {content_type: "application/json; odata=minimalmetadata", kind: json, fields: [{name: applicationPackageReferences, var: application_package_references}, {name: certificateReferences, var: certificate_references}, {name: metadata, var: metadata}, {name: startTask, var: start_task}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pool_id: $pool_id, timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date, if_match: $if_match, if_none_match: $if_none_match, if_modified_since: $if_modified_since, if_unmodified_since: $if_unmodified_since, application_package_references: $application_package_references, certificate_references: $certificate_references, metadata: $metadata, start_task: $start_task
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disables automatic scaling for a Pool.
#
# POST /pools/{poolId}/disableautoscale
# operationId: Pool_DisableAutoScale
export def "pool-disable-auto-scale" [
  pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
]: nothing -> any {
  http-request {
    method: post
    path: "/pools/{poolId}/disableautoscale"
    path_params: [{name: poolId, var: pool_id}]
    query: [{name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pool_id: $pool_id, timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enables automatic scaling for a Pool.
#
# POST /pools/{poolId}/enableautoscale
# operationId: Pool_EnableAutoScale
export def "pool-enable-auto-scale" [
  pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
  --if-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --if-none-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --if-modified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time. (format: date-time-rfc1123)
  --if-unmodified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time. (format: date-time-rfc1123)
  --auto-scale-evaluation-interval: string # The default value is 15 minutes. The minimum and maximum value are 5 minutes and 168 hours respectively. If you specify a value less than 5 minutes or greater than 168 hours, the Batch service rejects the request with an invalid property value error; if you are calling the REST API directly, the HTTP status code is 400 (Bad Request). If you specify a new interval, then the existing autoscale evaluation schedule will be stopped and a new autoscale evaluation schedule will be started, with its starting time being the time when this request was issued. (format: duration)
  --auto-scale-formula: string # The formula is checked for validity before it is applied to the Pool. If the formula is not valid, the Batch service rejects the request with detailed error information. For more information about specifying this formula, see Automatically scale Compute Nodes in an Azure Batch Pool (https://azure.microsoft.com/en-us/documentation/articles/batch-automatic-scaling).
]: any -> any {
  $in | http-request {
    method: post
    path: "/pools/{poolId}/enableautoscale"
    path_params: [{name: poolId, var: pool_id}]
    query: [{name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}, {name: If-Match, var: if_match}, {name: If-None-Match, var: if_none_match}, {name: If-Modified-Since, var: if_modified_since}, {name: If-Unmodified-Since, var: if_unmodified_since}]
    body: {content_type: "application/json; odata=minimalmetadata", kind: json, fields: [{name: autoScaleEvaluationInterval, var: auto_scale_evaluation_interval}, {name: autoScaleFormula, var: auto_scale_formula}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pool_id: $pool_id, timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date, if_match: $if_match, if_none_match: $if_none_match, if_modified_since: $if_modified_since, if_unmodified_since: $if_unmodified_since, auto_scale_evaluation_interval: $auto_scale_evaluation_interval, auto_scale_formula: $auto_scale_formula
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the result of evaluating an automatic scaling formula on the Pool.
#
# POST /pools/{poolId}/evaluateautoscale
# Returns: record<error: record<code: string, message: string, values: list<record>>, results: string, timestamp: string>
# operationId: Pool_EvaluateAutoScale
export def "pool-evaluate-auto-scale" [
  pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
  auto_scale_formula: string # The formula is validated and its results calculated, but it is not applied to the Pool. To apply the formula to the Pool, 'Enable automatic scaling on a Pool'. For more information about specifying this formula, see Automatically scale Compute Nodes in an Azure Batch Pool (https://azure.microsoft.com/en-us/documentation/articles/batch-automatic-scaling).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/pools/{poolId}/evaluateautoscale"
    path_params: [{name: poolId, var: pool_id}]
    query: [{name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}]
    body: {content_type: "application/json; odata=minimalmetadata", kind: json, fields: [{name: autoScaleFormula, var: auto_scale_formula}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pool_id: $pool_id, timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date, auto_scale_formula: $auto_scale_formula
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the Compute Nodes in the specified Pool.
#
# GET /pools/{poolId}/nodes
# Returns: record<"odata.nextLink": string, value: table<affinityId: string, allocationTime: string, certificateReferences: list, endpointConfiguration: record, errors: list, id: string, ipAddress: string, isDedicated: bool, lastBootTime: string, nodeAgentInfo: record, recentTasks: list, runningTasksCount: int, schedulingState: string, startTask: record, startTaskInfo: record, state: string, stateTransitionTime: string, totalTasksRun: int, totalTasksSucceeded: int, url: string, vmSize: string>>
# operationId: ComputeNode_List
export def "compute-node-list" [
  pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # An OData $filter clause. For more information on constructing this filter, see https://docs.microsoft.com/en-us/rest/api/batchservice/odata-filters-in-batch#list-nodes-in-a-pool.
  --select: string # An OData $select clause.
  --maxresults: int # The maximum number of items to return in the response. A maximum of 1000 Compute Nodes can be returned. (format: int32, default: 1000)
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/pools/{poolId}/nodes"
    path_params: [{name: poolId, var: pool_id}]
    query: [{name: "$filter", var: filter}, {name: "$select", var: select}, {name: maxresults, var: maxresults}, {name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pool_id: $pool_id, filter: $filter, select: $select, maxresults: $maxresults, timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the specified Compute Node.
#
# GET /pools/{poolId}/nodes/{nodeId}
# Returns: record<affinityId: string, allocationTime: string, certificateReferences: table<storeLocation: string, storeName: string, thumbprint: string, thumbprintAlgorithm: string, visibility: list>, endpointConfiguration: record<inboundEndpoints: list<record>>, errors: table<code: string, errorDetails: list, message: string>, id: string, ipAddress: string, isDedicated: bool, lastBootTime: string, nodeAgentInfo: record<lastUpdateTime: string, version: string>, recentTasks: table<executionInfo: record, jobId: string, subtaskId: int, taskId: string, taskState: string, taskUrl: string>, runningTasksCount: int, schedulingState: string, startTask: record<commandLine: string, containerSettings: record<containerRunOptions: string, imageName: string, registry: record, workingDirectory: string>, environmentSettings: list<record>, maxTaskRetryCount: int, resourceFiles: list<record>, userIdentity: record<autoUser: record, username: string>, waitForSuccess: bool>, startTaskInfo: record<containerInfo: record<containerId: string, error: string, state: string>, endTime: string, exitCode: int, failureInfo: record<category: string, code: string, details: list, message: string>, lastRetryTime: string, result: string, retryCount: int, startTime: string, state: string>, state: string, stateTransitionTime: string, totalTasksRun: int, totalTasksSucceeded: int, url: string, vmSize: string>
# operationId: ComputeNode_Get
export def "compute-node-get" [
  pool_id: string
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: string # An OData $select clause.
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/pools/{poolId}/nodes/{nodeId}"
    path_params: [{name: poolId, var: pool_id}, {name: nodeId, var: node_id}]
    query: [{name: "$select", var: select}, {name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pool_id: $pool_id, node_id: $node_id, select: $select, timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disables Task scheduling on the specified Compute Node.
#
# POST /pools/{poolId}/nodes/{nodeId}/disablescheduling
# operationId: ComputeNode_DisableScheduling
export def "compute-node-disable-scheduling" [
  pool_id: string
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
  --node-disable-scheduling-option: string@node-disable-scheduling-option-completer # The default value is requeue.
]: any -> any {
  $in | http-request {
    method: post
    path: "/pools/{poolId}/nodes/{nodeId}/disablescheduling"
    path_params: [{name: poolId, var: pool_id}, {name: nodeId, var: node_id}]
    query: [{name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}]
    body: {content_type: "application/json; odata=minimalmetadata", kind: json, fields: [{name: nodeDisableSchedulingOption, var: node_disable_scheduling_option}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pool_id: $pool_id, node_id: $node_id, timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date, node_disable_scheduling_option: $node_disable_scheduling_option
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enables Task scheduling on the specified Compute Node.
#
# POST /pools/{poolId}/nodes/{nodeId}/enablescheduling
# operationId: ComputeNode_EnableScheduling
export def "compute-node-enable-scheduling" [
  pool_id: string
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
]: nothing -> any {
  http-request {
    method: post
    path: "/pools/{poolId}/nodes/{nodeId}/enablescheduling"
    path_params: [{name: poolId, var: pool_id}, {name: nodeId, var: node_id}]
    query: [{name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pool_id: $pool_id, node_id: $node_id, timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all of the files in Task directories on the specified Compute Node.
#
# GET /pools/{poolId}/nodes/{nodeId}/files
# Returns: record<"odata.nextLink": string, value: table<isDirectory: bool, name: string, properties: record, url: string>>
# operationId: File_ListFromComputeNode
export def "file-list-from-compute-node" [
  pool_id: string
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # An OData $filter clause. For more information on constructing this filter, see https://docs.microsoft.com/en-us/rest/api/batchservice/odata-filters-in-batch#list-compute-node-files.
  --recursive: oneof<nothing, bool> # Whether to list children of a directory.
  --maxresults: int # The maximum number of items to return in the response. A maximum of 1000 files can be returned. (format: int32, default: 1000)
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/pools/{poolId}/nodes/{nodeId}/files"
    path_params: [{name: poolId, var: pool_id}, {name: nodeId, var: node_id}]
    query: [{name: "$filter", var: filter}, {name: recursive, var: recursive}, {name: maxresults, var: maxresults}, {name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pool_id: $pool_id, node_id: $node_id, filter: $filter, recursive: $recursive, maxresults: $maxresults, timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified file from the Compute Node.
#
# DELETE /pools/{poolId}/nodes/{nodeId}/files/{filePath}
# operationId: File_DeleteFromComputeNode
export def "file-delete-from-compute-node" [
  pool_id: string
  node_id: string
  file_path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --recursive: oneof<nothing, bool> # Whether to delete children of a directory. If the filePath parameter represents a directory instead of a file, you can set recursive to true to delete the directory and all of the files and subdirectories in it. If recursive is false then the directory must be empty or deletion will fail.
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
]: nothing -> any {
  http-request {
    method: delete
    path: "/pools/{poolId}/nodes/{nodeId}/files/{filePath}"
    path_params: [{name: poolId, var: pool_id}, {name: nodeId, var: node_id}, {name: filePath, var: file_path}]
    query: [{name: recursive, var: recursive}, {name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pool_id: $pool_id, node_id: $node_id, file_path: $file_path, recursive: $recursive, timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the content of the specified Compute Node file.
#
# GET /pools/{poolId}/nodes/{nodeId}/files/{filePath}
# Returns: binary
# operationId: File_GetFromComputeNode
export def "file-get-from-compute-node" [
  pool_id: string
  node_id: string
  file_path: string
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
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
  --ocp-range: string # The byte range to be retrieved. The default is to retrieve the entire file. The format is bytes=startRange-endRange.
  --if-modified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time. (format: date-time-rfc1123)
  --if-unmodified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time. (format: date-time-rfc1123)
]: nothing -> any {
  http-request {
    method: get
    path: "/pools/{poolId}/nodes/{nodeId}/files/{filePath}"
    path_params: [{name: poolId, var: pool_id}, {name: nodeId, var: node_id}, {name: filePath, var: file_path}]
    query: [{name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}, {name: ocp-range, var: ocp_range}, {name: If-Modified-Since, var: if_modified_since}, {name: If-Unmodified-Since, var: if_unmodified_since}]
    accept: ["application/json", "application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    pool_id: $pool_id, node_id: $node_id, file_path: $file_path, timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date, ocp_range: $ocp_range, if_modified_since: $if_modified_since, if_unmodified_since: $if_unmodified_since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the properties of the specified Compute Node file.
#
# HEAD /pools/{poolId}/nodes/{nodeId}/files/{filePath}
# Returns: record
# operationId: File_GetPropertiesFromComputeNode
export def "file-get-properties-from-compute-node" [
  pool_id: string
  node_id: string
  file_path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
  --if-modified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time. (format: date-time-rfc1123)
  --if-unmodified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time. (format: date-time-rfc1123)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: head
    path: "/pools/{poolId}/nodes/{nodeId}/files/{filePath}"
    path_params: [{name: poolId, var: pool_id}, {name: nodeId, var: node_id}, {name: filePath, var: file_path}]
    query: [{name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}, {name: If-Modified-Since, var: if_modified_since}, {name: If-Unmodified-Since, var: if_unmodified_since}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pool_id: $pool_id, node_id: $node_id, file_path: $file_path, timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date, if_modified_since: $if_modified_since, if_unmodified_since: $if_unmodified_since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the Remote Desktop Protocol file for the specified Compute Node.
#
# GET /pools/{poolId}/nodes/{nodeId}/rdp
# Returns: binary
# operationId: ComputeNode_GetRemoteDesktop
export def "compute-node-get-remote-desktop" [
  pool_id: string
  node_id: string
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
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
]: nothing -> any {
  http-request {
    method: get
    path: "/pools/{poolId}/nodes/{nodeId}/rdp"
    path_params: [{name: poolId, var: pool_id}, {name: nodeId, var: node_id}]
    query: [{name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}]
    accept: ["application/json", "application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    pool_id: $pool_id, node_id: $node_id, timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Restarts the specified Compute Node.
#
# POST /pools/{poolId}/nodes/{nodeId}/reboot
# operationId: ComputeNode_Reboot
export def "compute-node-reboot" [
  pool_id: string
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
  --node-reboot-option: string@node-reboot-option-completer # The default value is requeue.
]: any -> any {
  $in | http-request {
    method: post
    path: "/pools/{poolId}/nodes/{nodeId}/reboot"
    path_params: [{name: poolId, var: pool_id}, {name: nodeId, var: node_id}]
    query: [{name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}]
    body: {content_type: "application/json; odata=minimalmetadata", kind: json, fields: [{name: nodeRebootOption, var: node_reboot_option}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    pool_id: $pool_id, node_id: $node_id, timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date, node_reboot_option: $node_reboot_option
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reinstalls the operating system on the specified Compute Node.
#
# POST /pools/{poolId}/nodes/{nodeId}/reimage
# operationId: ComputeNode_Reimage
export def "compute-node-reimage" [
  pool_id: string
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
  --node-reimage-option: string@node-reimage-option-completer # The default value is requeue.
]: any -> any {
  $in | http-request {
    method: post
    path: "/pools/{poolId}/nodes/{nodeId}/reimage"
    path_params: [{name: poolId, var: pool_id}, {name: nodeId, var: node_id}]
    query: [{name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}]
    body: {content_type: "application/json; odata=minimalmetadata", kind: json, fields: [{name: nodeReimageOption, var: node_reimage_option}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    pool_id: $pool_id, node_id: $node_id, timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date, node_reimage_option: $node_reimage_option
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the settings required for remote login to a Compute Node.
#
# GET /pools/{poolId}/nodes/{nodeId}/remoteloginsettings
# Returns: record<remoteLoginIPAddress: string, remoteLoginPort: int>
# operationId: ComputeNode_GetRemoteLoginSettings
export def "compute-node-get-remote-login-settings" [
  pool_id: string
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/pools/{poolId}/nodes/{nodeId}/remoteloginsettings"
    path_params: [{name: poolId, var: pool_id}, {name: nodeId, var: node_id}]
    query: [{name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pool_id: $pool_id, node_id: $node_id, timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload Azure Batch service log files from the specified Compute Node to Azure Blob Storage.
#
# POST /pools/{poolId}/nodes/{nodeId}/uploadbatchservicelogs
# Returns: record<numberOfFilesUploaded: int, virtualDirectoryName: string>
# operationId: ComputeNode_UploadBatchServiceLogs
export def "compute-node-upload-batch-service-logs" [
  pool_id: string
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
  container_url: string # The URL must include a Shared Access Signature (SAS) granting write permissions to the container. The SAS duration must allow enough time for the upload to finish. The start time for SAS is optional and recommended to not be specified.
  --end-time: string # Any log file containing a log message in the time range will be uploaded. This means that the operation might retrieve more logs than have been requested since the entire log file is always uploaded, but the operation should not retrieve fewer logs than have been requested. If omitted, the default is to upload all logs available after the startTime. (format: date-time)
  start_time: string # Any log file containing a log message in the time range will be uploaded. This means that the operation might retrieve more logs than have been requested since the entire log file is always uploaded, but the operation should not retrieve fewer logs than have been requested. (format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/pools/{poolId}/nodes/{nodeId}/uploadbatchservicelogs"
    path_params: [{name: poolId, var: pool_id}, {name: nodeId, var: node_id}]
    query: [{name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}]
    body: {content_type: "application/json; odata=minimalmetadata", kind: json, fields: [{name: containerUrl, var: container_url}, {name: endTime, var: end_time}, {name: startTime, var: start_time}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pool_id: $pool_id, node_id: $node_id, timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date, container_url: $container_url, end_time: $end_time, start_time: $start_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a user Account to the specified Compute Node.
#
# POST /pools/{poolId}/nodes/{nodeId}/users
# operationId: ComputeNode_AddUser
export def "compute-node-add-user" [
  pool_id: string
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
  --expiry-time: string # If omitted, the default is 1 day from the current time. For Linux Compute Nodes, the expiryTime has a precision up to a day. (format: date-time)
  --is-admin: oneof<nothing, bool> # The default value is false.
  name: string
  --password: string # The password is required for Windows Compute Nodes (those created with 'cloudServiceConfiguration', or created with 'virtualMachineConfiguration' using a Windows Image reference). For Linux Compute Nodes, the password can optionally be specified along with the sshPublicKey property.
  --ssh-public-key: string # The public key should be compatible with OpenSSH encoding and should be base 64 encoded. This property can be specified only for Linux Compute Nodes. If this is specified for a Windows Compute Node, then the Batch service rejects the request; if you are calling the REST API directly, the HTTP status code is 400 (Bad Request).
]: any -> any {
  $in | http-request {
    method: post
    path: "/pools/{poolId}/nodes/{nodeId}/users"
    path_params: [{name: poolId, var: pool_id}, {name: nodeId, var: node_id}]
    query: [{name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}]
    body: {content_type: "application/json; odata=minimalmetadata", kind: json, fields: [{name: expiryTime, var: expiry_time}, {name: isAdmin, var: is_admin}, {name: name, var: name}, {name: password, var: password}, {name: sshPublicKey, var: ssh_public_key}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    pool_id: $pool_id, node_id: $node_id, timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date, expiry_time: $expiry_time, is_admin: $is_admin, name: $name, password: $password, ssh_public_key: $ssh_public_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a user Account from the specified Compute Node.
#
# DELETE /pools/{poolId}/nodes/{nodeId}/users/{userName}
# operationId: ComputeNode_DeleteUser
export def "compute-node-delete-user" [
  pool_id: string
  node_id: string
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
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
]: nothing -> any {
  http-request {
    method: delete
    path: "/pools/{poolId}/nodes/{nodeId}/users/{userName}"
    path_params: [{name: poolId, var: pool_id}, {name: nodeId, var: node_id}, {name: userName, var: user_name}]
    query: [{name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pool_id: $pool_id, node_id: $node_id, user_name: $user_name, timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the password and expiration time of a user Account on the specified Compute Node.
#
# PUT /pools/{poolId}/nodes/{nodeId}/users/{userName}
# operationId: ComputeNode_UpdateUser
export def "compute-node-update-user" [
  pool_id: string
  node_id: string
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
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
  --expiry-time: string # If omitted, the default is 1 day from the current time. For Linux Compute Nodes, the expiryTime has a precision up to a day. (format: date-time)
  --password: string # The password is required for Windows Compute Nodes (those created with 'cloudServiceConfiguration', or created with 'virtualMachineConfiguration' using a Windows Image reference). For Linux Compute Nodes, the password can optionally be specified along with the sshPublicKey property. If omitted, any existing password is removed.
  --ssh-public-key: string # The public key should be compatible with OpenSSH encoding and should be base 64 encoded. This property can be specified only for Linux Compute Nodes. If this is specified for a Windows Compute Node, then the Batch service rejects the request; if you are calling the REST API directly, the HTTP status code is 400 (Bad Request). If omitted, any existing SSH public key is removed.
]: any -> any {
  $in | http-request {
    method: put
    path: "/pools/{poolId}/nodes/{nodeId}/users/{userName}"
    path_params: [{name: poolId, var: pool_id}, {name: nodeId, var: node_id}, {name: userName, var: user_name}]
    query: [{name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}]
    body: {content_type: "application/json; odata=minimalmetadata", kind: json, fields: [{name: expiryTime, var: expiry_time}, {name: password, var: password}, {name: sshPublicKey, var: ssh_public_key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pool_id: $pool_id, node_id: $node_id, user_name: $user_name, timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date, expiry_time: $expiry_time, password: $password, ssh_public_key: $ssh_public_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes Compute Nodes from the specified Pool.
#
# POST /pools/{poolId}/removenodes
# operationId: Pool_RemoveNodes
export def "pool-remove-nodes" [
  pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
  --if-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --if-none-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --if-modified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time. (format: date-time-rfc1123)
  --if-unmodified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time. (format: date-time-rfc1123)
  --node-deallocation-option: string@node-deallocation-option-completer # The default value is requeue.
  node_list: list<string>
  --resize-timeout: string # The default value is 15 minutes. The minimum value is 5 minutes. If you specify a value less than 5 minutes, the Batch service returns an error; if you are calling the REST API directly, the HTTP status code is 400 (Bad Request). (format: duration)
]: any -> any {
  $in | http-request {
    method: post
    path: "/pools/{poolId}/removenodes"
    path_params: [{name: poolId, var: pool_id}]
    query: [{name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}, {name: If-Match, var: if_match}, {name: If-None-Match, var: if_none_match}, {name: If-Modified-Since, var: if_modified_since}, {name: If-Unmodified-Since, var: if_unmodified_since}]
    body: {content_type: "application/json; odata=minimalmetadata", kind: json, fields: [{name: nodeDeallocationOption, var: node_deallocation_option}, {name: nodeList, var: node_list}, {name: resizeTimeout, var: resize_timeout}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    pool_id: $pool_id, timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date, if_match: $if_match, if_none_match: $if_none_match, if_modified_since: $if_modified_since, if_unmodified_since: $if_unmodified_since, node_deallocation_option: $node_deallocation_option, node_list: $node_list, resize_timeout: $resize_timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Changes the number of Compute Nodes that are assigned to a Pool.
#
# POST /pools/{poolId}/resize
# operationId: Pool_Resize
export def "pool-resize" [
  pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
  --if-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --if-none-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --if-modified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time. (format: date-time-rfc1123)
  --if-unmodified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time. (format: date-time-rfc1123)
  --node-deallocation-option: string@node-deallocation-option-completer # The default value is requeue.
  --resize-timeout: string # The default value is 15 minutes. The minimum value is 5 minutes. If you specify a value less than 5 minutes, the Batch service returns an error; if you are calling the REST API directly, the HTTP status code is 400 (Bad Request). (format: duration)
  --target-dedicated-nodes: int # format: int32
  --target-low-priority-nodes: int # format: int32
]: any -> any {
  $in | http-request {
    method: post
    path: "/pools/{poolId}/resize"
    path_params: [{name: poolId, var: pool_id}]
    query: [{name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}, {name: If-Match, var: if_match}, {name: If-None-Match, var: if_none_match}, {name: If-Modified-Since, var: if_modified_since}, {name: If-Unmodified-Since, var: if_unmodified_since}]
    body: {content_type: "application/json; odata=minimalmetadata", kind: json, fields: [{name: nodeDeallocationOption, var: node_deallocation_option}, {name: resizeTimeout, var: resize_timeout}, {name: targetDedicatedNodes, var: target_dedicated_nodes}, {name: targetLowPriorityNodes, var: target_low_priority_nodes}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    pool_id: $pool_id, timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date, if_match: $if_match, if_none_match: $if_none_match, if_modified_since: $if_modified_since, if_unmodified_since: $if_unmodified_since, node_deallocation_option: $node_deallocation_option, resize_timeout: $resize_timeout, target_dedicated_nodes: $target_dedicated_nodes, target_low_priority_nodes: $target_low_priority_nodes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stops an ongoing resize operation on the Pool.
#
# POST /pools/{poolId}/stopresize
# operationId: Pool_StopResize
export def "pool-stop-resize" [
  pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
  --if-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service exactly matches the value specified by the client.
  --if-none-match: string # An ETag value associated with the version of the resource known to the client. The operation will be performed only if the resource's current ETag on the service does not match the value specified by the client.
  --if-modified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has been modified since the specified time. (format: date-time-rfc1123)
  --if-unmodified-since: string # A timestamp indicating the last modified time of the resource known to the client. The operation will be performed only if the resource on the service has not been modified since the specified time. (format: date-time-rfc1123)
]: nothing -> any {
  http-request {
    method: post
    path: "/pools/{poolId}/stopresize"
    path_params: [{name: poolId, var: pool_id}]
    query: [{name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}, {name: If-Match, var: if_match}, {name: If-None-Match, var: if_none_match}, {name: If-Modified-Since, var: if_modified_since}, {name: If-Unmodified-Since, var: if_unmodified_since}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    pool_id: $pool_id, timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date, if_match: $if_match, if_none_match: $if_none_match, if_modified_since: $if_modified_since, if_unmodified_since: $if_unmodified_since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the properties of the specified Pool.
#
# POST /pools/{poolId}/updateproperties
# operationId: Pool_UpdateProperties
export def "pool-update-properties" [
  pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
  application_package_references: list # The list replaces any existing Application Package references on the Pool. Changes to Application Package references affect all new Compute Nodes joining the Pool, but do not affect Compute Nodes that are already in the Pool until they are rebooted or reimaged. There is a maximum of 10 Application Package references on any given Pool. If omitted, or if you specify an empty collection, any existing Application Packages references are removed from the Pool. A maximum of 10 references may be specified on a given Pool. — item shape: {applicationId: string, version?: string}
  certificate_references: list # This list replaces any existing Certificate references configured on the Pool. If you specify an empty collection, any existing Certificate references are removed from the Pool. For Windows Nodes, the Batch service installs the Certificates to the specified Certificate store and location. For Linux Compute Nodes, the Certificates are stored in a directory inside the Task working directory and an environment variable AZ_BATCH_CERTIFICATES_DIR is supplied to the Task to query for this location. For Certificates with visibility of 'remoteUser', a 'certs' directory is created in the user's home directory (e.g., /home/{user-name}/certs) and Certificates are placed in that directory. — item shape: {storeLocation?: "currentuser"|"localmachine", storeName?: string, thumbprint: string, thumbprintAlgorithm: string, visibility?: list<string>}
  metadata: list # This list replaces any existing metadata configured on the Pool. If omitted, or if you specify an empty collection, any existing metadata is removed from the Pool. — item shape: {name: string, value: string}
  --start-task: any # Batch will retry Tasks when a recovery operation is triggered on a Node. Examples of recovery operations include (but are not limited to) when an unhealthy Node is rebooted or a Compute Node disappeared due to host failure. Retries due to recovery operations are independent of and are not counted against the maxTaskRetryCount. Even if the maxTaskRetryCount is 0, an internal retry due to a recovery operation may occur. Because of this, all Tasks should be idempotent. This means Tasks need to tolerate being interrupted and restarted without causing any corruption or duplicate data. The best practice for long running Tasks is to use some form of checkpointing. In some cases the StartTask may be re-run even though the Compute Node was not rebooted. Special care should be taken to avoid StartTasks which create breakaway process or install/launch services from the StartTask working directory, as this will block Batch from being able to re-run the StartTask. — shape: {commandLine: string, containerSettings?: any, environmentSettings?: list, maxTaskRetryCount?: int, resourceFiles?: list, userIdentity?: any, waitForSuccess?: bool}
]: any -> any {
  $in | http-request {
    method: post
    path: "/pools/{poolId}/updateproperties"
    path_params: [{name: poolId, var: pool_id}]
    query: [{name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}]
    body: {content_type: "application/json; odata=minimalmetadata", kind: json, fields: [{name: applicationPackageReferences, var: application_package_references}, {name: certificateReferences, var: certificate_references}, {name: metadata, var: metadata}, {name: startTask, var: start_task}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    pool_id: $pool_id, timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date, application_package_references: $application_package_references, certificate_references: $certificate_references, metadata: $metadata, start_task: $start_task
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the usage metrics, aggregated by Pool across individual time intervals, for the specified Account.
#
# GET /poolusagemetrics
# Returns: record<"odata.nextLink": string, value: table<endTime: string, poolId: string, startTime: string, totalCoreHours: float, vmSize: string>>
# operationId: Pool_ListUsageMetrics
export def "pool-list-usage-metrics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --starttime: string # The earliest time from which to include metrics. This must be at least two and a half hours before the current time. If not specified this defaults to the start time of the last aggregation interval currently available. (format: date-time)
  --endtime: string # The latest time from which to include metrics. This must be at least two hours before the current time. If not specified this defaults to the end time of the last aggregation interval currently available. (format: date-time)
  --filter: string # An OData $filter clause. For more information on constructing this filter, see https://docs.microsoft.com/en-us/rest/api/batchservice/odata-filters-in-batch#list-account-usage-metrics.
  --maxresults: int # The maximum number of items to return in the response. A maximum of 1000 results will be returned. (format: int32, default: 1000)
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/poolusagemetrics"
    query: [{name: starttime, var: starttime}, {name: endtime, var: endtime}, {name: "$filter", var: filter}, {name: maxresults, var: maxresults}, {name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    starttime: $starttime, endtime: $endtime, filter: $filter, maxresults: $maxresults, timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all Virtual Machine Images supported by the Azure Batch service.
#
# GET /supportedimages
# Returns: record<"odata.nextLink": string, value: table<batchSupportEndOfLife: string, capabilities: list, imageReference: record, nodeAgentSKUId: string, osType: string, verificationType: string>>
# operationId: Account_ListSupportedImages
export def "account-list-supported-images" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # An OData $filter clause. For more information on constructing this filter, see https://docs.microsoft.com/en-us/rest/api/batchservice/odata-filters-in-batch#list-support-images.
  --maxresults: int # The maximum number of items to return in the response. A maximum of 1000 results will be returned. (format: int32, default: 1000)
  --timeout: int # The maximum time that the server can spend processing the request, in seconds. The default is 30 seconds. (format: int32, default: 30)
  --api-version: string # Client API Version. (required)
  --client-request-id: string # The caller-generated request identity, in the form of a GUID with no decoration such as curly braces, e.g. 9C4D50EE-2D56-4CD3-8152-34347DC9F2B0. (format: uuid)
  --return-client-request-id: oneof<nothing, bool> # Whether the server should return the client-request-id in the response. (default: false)
  --ocp-date: string # The time the request was issued. Client libraries typically set this to the current system clock time; set it explicitly if you are calling the REST API directly. (format: date-time-rfc1123)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/supportedimages"
    query: [{name: "$filter", var: filter}, {name: maxresults, var: maxresults}, {name: timeout, var: timeout}, {name: api-version, var: api_version, required: true}]
    header: [{name: client-request-id, var: client_request_id}, {name: return-client-request-id, var: return_client_request_id}, {name: ocp-date, var: ocp_date}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter: $filter, maxresults: $maxresults, timeout: $timeout, api_version: $api_version, client_request_id: $client_request_id, return_client_request_id: $return_client_request_id, ocp_date: $ocp_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
