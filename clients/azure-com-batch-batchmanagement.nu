# Auto-generated client for BatchManagement v2019-08-01
# Source: https://api.apis.guru/v2/specs/azure.com/batch-BatchManagement/2019-08-01/swagger.json
# Auth: --token flag or $env.BATCHMANAGEMENT_TOKEN

const CLIENT = {
  base_url: "https://management.azure.com"
  token_env_var: "BATCHMANAGEMENT_TOKEN"
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
def type-completer [] { ["Microsoft.Batch/batchAccounts"] }
def key-name-completer [] { ["Primary" "Secondary"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    operations-list: "record<nextLink: string, value: table<display: record, name: string, origin: string, properties: record>>"
    batch-account-list: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    location-check-name-availability: "record<message: string, nameAvailable: bool, reason: string>"
    location-get-quotas: "record<accountQuota: int>"
    batch-account-list-by-resource-group: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    batch-account-get: "record<properties: record<accountEndpoint: string, activeJobAndJobScheduleQuota: int, autoStorage: record<lastKeySync: string, storageAccountId: string>, dedicatedCoreQuota: int, dedicatedCoreQuotaPerVMFamily: list<record>, dedicatedCoreQuotaPerVMFamilyEnforced: bool, keyVaultReference: record<id: string, url: string>, lowPriorityCoreQuota: int, poolAllocationMode: string, poolQuota: int, provisioningState: string>, id: string, location: string, name: string, tags: record, type: string>"
    batch-account-update: "record<properties: record<accountEndpoint: string, activeJobAndJobScheduleQuota: int, autoStorage: record<lastKeySync: string, storageAccountId: string>, dedicatedCoreQuota: int, dedicatedCoreQuotaPerVMFamily: list<record>, dedicatedCoreQuotaPerVMFamilyEnforced: bool, keyVaultReference: record<id: string, url: string>, lowPriorityCoreQuota: int, poolAllocationMode: string, poolQuota: int, provisioningState: string>, id: string, location: string, name: string, tags: record, type: string>"
    batch-account-create: "record<properties: record<accountEndpoint: string, activeJobAndJobScheduleQuota: int, autoStorage: record<lastKeySync: string, storageAccountId: string>, dedicatedCoreQuota: int, dedicatedCoreQuotaPerVMFamily: list<record>, dedicatedCoreQuotaPerVMFamilyEnforced: bool, keyVaultReference: record<id: string, url: string>, lowPriorityCoreQuota: int, poolAllocationMode: string, poolQuota: int, provisioningState: string>, id: string, location: string, name: string, tags: record, type: string>"
    application-list: "record<nextLink: string, value: table<properties: record, etag: string, id: string, name: string, type: string>>"
    application-get: "record<properties: record<allowUpdates: bool, defaultVersion: string, displayName: string>, etag: string, id: string, name: string, type: string>"
    application-update: "record<properties: record<allowUpdates: bool, defaultVersion: string, displayName: string>, etag: string, id: string, name: string, type: string>"
    application-create: "record<properties: record<allowUpdates: bool, defaultVersion: string, displayName: string>, etag: string, id: string, name: string, type: string>"
    application-package-list: "record<nextLink: string, value: table<properties: record, etag: string, id: string, name: string, type: string>>"
    application-package-get: "record<properties: record<format: string, lastActivationTime: string, state: string, storageUrl: string, storageUrlExpiry: string>, etag: string, id: string, name: string, type: string>"
    application-package-create: "record<properties: record<format: string, lastActivationTime: string, state: string, storageUrl: string, storageUrlExpiry: string>, etag: string, id: string, name: string, type: string>"
    application-package-activate: "record<properties: record<format: string, lastActivationTime: string, state: string, storageUrl: string, storageUrlExpiry: string>, etag: string, id: string, name: string, type: string>"
    certificate-list-by-batch-account: "record<nextLink: string, value: table<properties: record, etag: string, id: string, name: string, type: string>>"
    certificate-get: "record<properties: record<deleteCertificateError: record<code: string, details: list, message: string, target: string>, previousProvisioningState: string, previousProvisioningStateTransitionTime: string, provisioningState: string, provisioningStateTransitionTime: string, publicData: string, format: string, thumbprint: string, thumbprintAlgorithm: string>, etag: string, id: string, name: string, type: string>"
    certificate-update: "record<properties: record<deleteCertificateError: record<code: string, details: list, message: string, target: string>, previousProvisioningState: string, previousProvisioningStateTransitionTime: string, provisioningState: string, provisioningStateTransitionTime: string, publicData: string, format: string, thumbprint: string, thumbprintAlgorithm: string>, etag: string, id: string, name: string, type: string>"
    certificate-create: "record<properties: record<deleteCertificateError: record<code: string, details: list, message: string, target: string>, previousProvisioningState: string, previousProvisioningStateTransitionTime: string, provisioningState: string, provisioningStateTransitionTime: string, publicData: string, format: string, thumbprint: string, thumbprintAlgorithm: string>, etag: string, id: string, name: string, type: string>"
    certificate-cancel-deletion: "record<properties: record<deleteCertificateError: record<code: string, details: list, message: string, target: string>, previousProvisioningState: string, previousProvisioningStateTransitionTime: string, provisioningState: string, provisioningStateTransitionTime: string, publicData: string, format: string, thumbprint: string, thumbprintAlgorithm: string>, etag: string, id: string, name: string, type: string>"
    batch-account-get-keys: "record<accountName: string, primary: string, secondary: string>"
    pool-list-by-batch-account: "record<nextLink: string, value: table<properties: record, etag: string, id: string, name: string, type: string>>"
    pool-get: "record<properties: record<allocationState: string, allocationStateTransitionTime: string, applicationLicenses: list<string>, applicationPackages: list<record>, autoScaleRun: record<error: record, evaluationTime: string, results: string>, certificates: list<record>, creationTime: string, currentDedicatedNodes: int, currentLowPriorityNodes: int, deploymentConfiguration: record<cloudServiceConfiguration: record, virtualMachineConfiguration: record>, displayName: string, interNodeCommunication: string, lastModified: string, maxTasksPerNode: int, metadata: list<record>, mountConfiguration: list<record>, networkConfiguration: record<endpointConfiguration: record, publicIPs: list, subnetId: string>, provisioningState: string, provisioningStateTransitionTime: string, resizeOperationStatus: record<errors: list, nodeDeallocationOption: string, resizeTimeout: string, startTime: string, targetDedicatedNodes: int, targetLowPriorityNodes: int>, scaleSettings: record<autoScale: record, fixedScale: record>, startTask: record<commandLine: string, containerSettings: record, environmentSettings: list, maxTaskRetryCount: int, resourceFiles: list, userIdentity: record, waitForSuccess: bool>, taskSchedulingPolicy: record<nodeFillType: string>, userAccounts: list<record>, vmSize: string>, etag: string, id: string, name: string, type: string>"
    pool-update: "record<properties: record<allocationState: string, allocationStateTransitionTime: string, applicationLicenses: list<string>, applicationPackages: list<record>, autoScaleRun: record<error: record, evaluationTime: string, results: string>, certificates: list<record>, creationTime: string, currentDedicatedNodes: int, currentLowPriorityNodes: int, deploymentConfiguration: record<cloudServiceConfiguration: record, virtualMachineConfiguration: record>, displayName: string, interNodeCommunication: string, lastModified: string, maxTasksPerNode: int, metadata: list<record>, mountConfiguration: list<record>, networkConfiguration: record<endpointConfiguration: record, publicIPs: list, subnetId: string>, provisioningState: string, provisioningStateTransitionTime: string, resizeOperationStatus: record<errors: list, nodeDeallocationOption: string, resizeTimeout: string, startTime: string, targetDedicatedNodes: int, targetLowPriorityNodes: int>, scaleSettings: record<autoScale: record, fixedScale: record>, startTask: record<commandLine: string, containerSettings: record, environmentSettings: list, maxTaskRetryCount: int, resourceFiles: list, userIdentity: record, waitForSuccess: bool>, taskSchedulingPolicy: record<nodeFillType: string>, userAccounts: list<record>, vmSize: string>, etag: string, id: string, name: string, type: string>"
    pool-create: "record<properties: record<allocationState: string, allocationStateTransitionTime: string, applicationLicenses: list<string>, applicationPackages: list<record>, autoScaleRun: record<error: record, evaluationTime: string, results: string>, certificates: list<record>, creationTime: string, currentDedicatedNodes: int, currentLowPriorityNodes: int, deploymentConfiguration: record<cloudServiceConfiguration: record, virtualMachineConfiguration: record>, displayName: string, interNodeCommunication: string, lastModified: string, maxTasksPerNode: int, metadata: list<record>, mountConfiguration: list<record>, networkConfiguration: record<endpointConfiguration: record, publicIPs: list, subnetId: string>, provisioningState: string, provisioningStateTransitionTime: string, resizeOperationStatus: record<errors: list, nodeDeallocationOption: string, resizeTimeout: string, startTime: string, targetDedicatedNodes: int, targetLowPriorityNodes: int>, scaleSettings: record<autoScale: record, fixedScale: record>, startTask: record<commandLine: string, containerSettings: record, environmentSettings: list, maxTaskRetryCount: int, resourceFiles: list, userIdentity: record, waitForSuccess: bool>, taskSchedulingPolicy: record<nodeFillType: string>, userAccounts: list<record>, vmSize: string>, etag: string, id: string, name: string, type: string>"
    pool-disable-auto-scale: "record<properties: record<allocationState: string, allocationStateTransitionTime: string, applicationLicenses: list<string>, applicationPackages: list<record>, autoScaleRun: record<error: record, evaluationTime: string, results: string>, certificates: list<record>, creationTime: string, currentDedicatedNodes: int, currentLowPriorityNodes: int, deploymentConfiguration: record<cloudServiceConfiguration: record, virtualMachineConfiguration: record>, displayName: string, interNodeCommunication: string, lastModified: string, maxTasksPerNode: int, metadata: list<record>, mountConfiguration: list<record>, networkConfiguration: record<endpointConfiguration: record, publicIPs: list, subnetId: string>, provisioningState: string, provisioningStateTransitionTime: string, resizeOperationStatus: record<errors: list, nodeDeallocationOption: string, resizeTimeout: string, startTime: string, targetDedicatedNodes: int, targetLowPriorityNodes: int>, scaleSettings: record<autoScale: record, fixedScale: record>, startTask: record<commandLine: string, containerSettings: record, environmentSettings: list, maxTaskRetryCount: int, resourceFiles: list, userIdentity: record, waitForSuccess: bool>, taskSchedulingPolicy: record<nodeFillType: string>, userAccounts: list<record>, vmSize: string>, etag: string, id: string, name: string, type: string>"
    pool-stop-resize: "record<properties: record<allocationState: string, allocationStateTransitionTime: string, applicationLicenses: list<string>, applicationPackages: list<record>, autoScaleRun: record<error: record, evaluationTime: string, results: string>, certificates: list<record>, creationTime: string, currentDedicatedNodes: int, currentLowPriorityNodes: int, deploymentConfiguration: record<cloudServiceConfiguration: record, virtualMachineConfiguration: record>, displayName: string, interNodeCommunication: string, lastModified: string, maxTasksPerNode: int, metadata: list<record>, mountConfiguration: list<record>, networkConfiguration: record<endpointConfiguration: record, publicIPs: list, subnetId: string>, provisioningState: string, provisioningStateTransitionTime: string, resizeOperationStatus: record<errors: list, nodeDeallocationOption: string, resizeTimeout: string, startTime: string, targetDedicatedNodes: int, targetLowPriorityNodes: int>, scaleSettings: record<autoScale: record, fixedScale: record>, startTask: record<commandLine: string, containerSettings: record, environmentSettings: list, maxTaskRetryCount: int, resourceFiles: list, userIdentity: record, waitForSuccess: bool>, taskSchedulingPolicy: record<nodeFillType: string>, userAccounts: list<record>, vmSize: string>, etag: string, id: string, name: string, type: string>"
    batch-account-regenerate-key: "record<accountName: string, primary: string, secondary: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["operations-list" "batch-account-list" "location-check-name-availability" "location-get-quotas" "batch-account-list-by-resource-group" "batch-account-delete" "batch-account-get" "batch-account-update" "batch-account-create" "application-list" "application-delete" "application-get" "application-update" "application-create" "application-package-list" "application-package-delete" "application-package-get" "application-package-create" "application-package-activate" "certificate-list-by-batch-account" "certificate-delete" "certificate-get" "certificate-update" "certificate-create" "certificate-cancel-deletion" "batch-account-get-keys" "pool-list-by-batch-account" "pool-delete" "pool-get" "pool-update" "pool-create" "pool-disable-auto-scale" "pool-stop-resize" "batch-account-regenerate-key" "batch-account-synchronize-auto-storage-keys" "commands"] | sort) } | get name | first)
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

# Lists available operations for the Microsoft.Batch provider
#
# GET /providers/Microsoft.Batch/operations
# Returns: record<nextLink: string, value: table<display: record, name: string, origin: string, properties: record>>
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
  --api-version: string # The API version to be used with the HTTP request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Batch/operations"
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the Batch accounts associated with the subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Batch/batchAccounts
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: BatchAccount_List
export def "batch-account-list" [
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
  --api-version: string # The API version to be used with the HTTP request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.Batch/batchAccounts"
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

# Checks whether the Batch account name is available in the specified region.
#
# POST /subscriptions/{subscriptionId}/providers/Microsoft.Batch/locations/{locationName}/checkNameAvailability
# Returns: record<message: string, nameAvailable: bool, reason: string>
# operationId: Location_CheckNameAvailability
export def "location-check-name-availability" [
  subscription_id: string
  location_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to be used with the HTTP request. (required)
  name: string # The name to check for availability
  type: string@type-completer # The resource type. Must be set to Microsoft.Batch/batchAccounts
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.Batch/locations/{locationName}/checkNameAvailability"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: locationName, var: location_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, location_name: $location_name, api_version: $api_version, name: $name, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the Batch service quotas for the specified subscription at the given location.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Batch/locations/{locationName}/quotas
# Returns: record<accountQuota: int>
# operationId: Location_GetQuotas
export def "location-get-quotas" [
  subscription_id: string
  location_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to be used with the HTTP request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.Batch/locations/{locationName}/quotas"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: locationName, var: location_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, location_name: $location_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the Batch accounts associated with the specified resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: BatchAccount_ListByResourceGroup
export def "batch-account-list-by-resource-group" [
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
  --api-version: string # The API version to be used with the HTTP request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts"
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

# Deletes the specified Batch account.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}
# operationId: BatchAccount_Delete
export def "batch-account-delete" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to be used with the HTTP request. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: accountName, var: account_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, account_name: $account_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the specified Batch account.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}
# Returns: record<properties: record<accountEndpoint: string, activeJobAndJobScheduleQuota: int, autoStorage: record<lastKeySync: string, storageAccountId: string>, dedicatedCoreQuota: int, dedicatedCoreQuotaPerVMFamily: list<record>, dedicatedCoreQuotaPerVMFamilyEnforced: bool, keyVaultReference: record<id: string, url: string>, lowPriorityCoreQuota: int, poolAllocationMode: string, poolQuota: int, provisioningState: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: BatchAccount_Get
export def "batch-account-get" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to be used with the HTTP request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: accountName, var: account_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, account_name: $account_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the properties of an existing Batch account.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}
# Returns: record<properties: record<accountEndpoint: string, activeJobAndJobScheduleQuota: int, autoStorage: record<lastKeySync: string, storageAccountId: string>, dedicatedCoreQuota: int, dedicatedCoreQuotaPerVMFamily: list<record>, dedicatedCoreQuotaPerVMFamilyEnforced: bool, keyVaultReference: record<id: string, url: string>, lowPriorityCoreQuota: int, poolAllocationMode: string, poolQuota: int, provisioningState: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: BatchAccount_Update
export def "batch-account-update" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to be used with the HTTP request. (required)
  --properties: any # The properties of a Batch account. — shape: {autoStorage?: any}
  --tags: record # The user-specified tags associated with the account.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: accountName, var: account_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, account_name: $account_name, api_version: $api_version, properties: $properties, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new Batch account with the specified parameters. Existing accounts cannot be updated with this API and should instead be updated with the Update Batch Account API.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}
# Returns: record<properties: record<accountEndpoint: string, activeJobAndJobScheduleQuota: int, autoStorage: record<lastKeySync: string, storageAccountId: string>, dedicatedCoreQuota: int, dedicatedCoreQuotaPerVMFamily: list<record>, dedicatedCoreQuotaPerVMFamilyEnforced: bool, keyVaultReference: record<id: string, url: string>, lowPriorityCoreQuota: int, poolAllocationMode: string, poolQuota: int, provisioningState: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: BatchAccount_Create
export def "batch-account-create" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to be used with the HTTP request. (required)
  location: string # The region in which to create the account.
  --properties: any # The properties of a Batch account. — shape: {autoStorage?: any, keyVaultReference?: any, poolAllocationMode?: "BatchService"|"UserSubscription"}
  --tags: record # The user-specified tags associated with the account.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: accountName, var: account_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: location, var: location}, {name: properties, var: properties}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, account_name: $account_name, api_version: $api_version, location: $location, properties: $properties, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all of the applications in the specified account.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/applications
# Returns: record<nextLink: string, value: table<properties: record, etag: string, id: string, name: string, type: string>>
# operationId: Application_List
export def "application-list" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxresults: int # The maximum number of items to return in the response. (format: int32)
  --api-version: string # The API version to be used with the HTTP request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/applications"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: accountName, var: account_name}]
    query: [{name: maxresults, var: maxresults}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, account_name: $account_name, maxresults: $maxresults, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an application.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/applications/{applicationName}
# operationId: Application_Delete
export def "application-delete" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  application_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to be used with the HTTP request. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/applications/{applicationName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: accountName, var: account_name}, {name: applicationName, var: application_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, account_name: $account_name, application_name: $application_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the specified application.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/applications/{applicationName}
# Returns: record<properties: record<allowUpdates: bool, defaultVersion: string, displayName: string>, etag: string, id: string, name: string, type: string>
# operationId: Application_Get
export def "application-get" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  application_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to be used with the HTTP request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/applications/{applicationName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: accountName, var: account_name}, {name: applicationName, var: application_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, account_name: $account_name, application_name: $application_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates settings for the specified application.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/applications/{applicationName}
# Returns: record<properties: record<allowUpdates: bool, defaultVersion: string, displayName: string>, etag: string, id: string, name: string, type: string>
# operationId: Application_Update
export def "application-update" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  application_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to be used with the HTTP request. (required)
  --properties: any # The properties associated with the Application. — shape: {allowUpdates?: bool, defaultVersion?: string, displayName?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/applications/{applicationName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: accountName, var: account_name}, {name: applicationName, var: application_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, account_name: $account_name, application_name: $application_name, api_version: $api_version, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds an application to the specified Batch account.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/applications/{applicationName}
# Returns: record<properties: record<allowUpdates: bool, defaultVersion: string, displayName: string>, etag: string, id: string, name: string, type: string>
# operationId: Application_Create
export def "application-create" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  application_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to be used with the HTTP request. (required)
  --properties: any # The properties associated with the Application. — shape: {allowUpdates?: bool, defaultVersion?: string, displayName?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/applications/{applicationName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: accountName, var: account_name}, {name: applicationName, var: application_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, account_name: $account_name, application_name: $application_name, api_version: $api_version, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all of the application packages in the specified application.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/applications/{applicationName}/versions
# Returns: record<nextLink: string, value: table<properties: record, etag: string, id: string, name: string, type: string>>
# operationId: ApplicationPackage_List
export def "application-package-list" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  application_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxresults: int # The maximum number of items to return in the response. (format: int32)
  --api-version: string # The API version to be used with the HTTP request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/applications/{applicationName}/versions"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: accountName, var: account_name}, {name: applicationName, var: application_name}]
    query: [{name: maxresults, var: maxresults}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, account_name: $account_name, application_name: $application_name, maxresults: $maxresults, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an application package record and its associated binary file.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/applications/{applicationName}/versions/{versionName}
# operationId: ApplicationPackage_Delete
export def "application-package-delete" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  application_name: string
  version_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to be used with the HTTP request. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/applications/{applicationName}/versions/{versionName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: accountName, var: account_name}, {name: applicationName, var: application_name}, {name: versionName, var: version_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, account_name: $account_name, application_name: $application_name, version_name: $version_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the specified application package.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/applications/{applicationName}/versions/{versionName}
# Returns: record<properties: record<format: string, lastActivationTime: string, state: string, storageUrl: string, storageUrlExpiry: string>, etag: string, id: string, name: string, type: string>
# operationId: ApplicationPackage_Get
export def "application-package-get" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  application_name: string
  version_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to be used with the HTTP request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/applications/{applicationName}/versions/{versionName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: accountName, var: account_name}, {name: applicationName, var: application_name}, {name: versionName, var: version_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, account_name: $account_name, application_name: $application_name, version_name: $version_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an application package record. The record contains the SAS where the package should be uploaded to. Once it is uploaded the `ApplicationPackage` needs to be activated using `ApplicationPackageActive` before it can be used.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/applications/{applicationName}/versions/{versionName}
# Returns: record<properties: record<format: string, lastActivationTime: string, state: string, storageUrl: string, storageUrlExpiry: string>, etag: string, id: string, name: string, type: string>
# operationId: ApplicationPackage_Create
export def "application-package-create" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  application_name: string
  version_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to be used with the HTTP request. (required)
  --properties: any # Properties of an application package
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/applications/{applicationName}/versions/{versionName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: accountName, var: account_name}, {name: applicationName, var: application_name}, {name: versionName, var: version_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, account_name: $account_name, application_name: $application_name, version_name: $version_name, api_version: $api_version, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Activates the specified application package. This should be done after the `ApplicationPackage` was created and uploaded. This needs to be done before an `ApplicationPackage` can be used on Pools or Tasks
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/applications/{applicationName}/versions/{versionName}/activate
# Returns: record<properties: record<format: string, lastActivationTime: string, state: string, storageUrl: string, storageUrlExpiry: string>, etag: string, id: string, name: string, type: string>
# operationId: ApplicationPackage_Activate
export def "application-package-activate" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  application_name: string
  version_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to be used with the HTTP request. (required)
  format: string # The format of the application package binary file.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/applications/{applicationName}/versions/{versionName}/activate"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: accountName, var: account_name}, {name: applicationName, var: application_name}, {name: versionName, var: version_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: format, var: format}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, account_name: $account_name, application_name: $application_name, version_name: $version_name, api_version: $api_version, format: $format
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all of the certificates in the specified account.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/certificates
# Returns: record<nextLink: string, value: table<properties: record, etag: string, id: string, name: string, type: string>>
# operationId: Certificate_ListByBatchAccount
export def "certificate-list-by-batch-account" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxresults: int # The maximum number of items to return in the response. (format: int32)
  --select: string # Comma separated list of properties that should be returned. e.g. "properties/provisioningState". Only top level properties under properties/ are valid for selection.
  --filter: string # OData filter expression. Valid properties for filtering are "properties/provisioningState", "properties/provisioningStateTransitionTime", "name".
  --api-version: string # The API version to be used with the HTTP request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/certificates"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: accountName, var: account_name}]
    query: [{name: maxresults, var: maxresults}, {name: "$select", var: select}, {name: "$filter", var: filter}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, account_name: $account_name, maxresults: $maxresults, select: $select, filter: $filter, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified certificate.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/certificates/{certificateName}
# operationId: Certificate_Delete
export def "certificate-delete" [
  subscription_id: string
  resource_group_name: string
  account_name: string
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
  --api-version: string # The API version to be used with the HTTP request. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/certificates/{certificateName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: accountName, var: account_name}, {name: certificateName, var: certificate_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, account_name: $account_name, certificate_name: $certificate_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the specified certificate.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/certificates/{certificateName}
# Returns: record<properties: record<deleteCertificateError: record<code: string, details: list, message: string, target: string>, previousProvisioningState: string, previousProvisioningStateTransitionTime: string, provisioningState: string, provisioningStateTransitionTime: string, publicData: string, format: string, thumbprint: string, thumbprintAlgorithm: string>, etag: string, id: string, name: string, type: string>
# operationId: Certificate_Get
export def "certificate-get" [
  subscription_id: string
  resource_group_name: string
  account_name: string
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
  --api-version: string # The API version to be used with the HTTP request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/certificates/{certificateName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: accountName, var: account_name}, {name: certificateName, var: certificate_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, account_name: $account_name, certificate_name: $certificate_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the properties of an existing certificate.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/certificates/{certificateName}
# Returns: record<properties: record<deleteCertificateError: record<code: string, details: list, message: string, target: string>, previousProvisioningState: string, previousProvisioningStateTransitionTime: string, provisioningState: string, provisioningStateTransitionTime: string, publicData: string, format: string, thumbprint: string, thumbprintAlgorithm: string>, etag: string, id: string, name: string, type: string>
# operationId: Certificate_Update
export def "certificate-update" [
  subscription_id: string
  resource_group_name: string
  account_name: string
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
  --api-version: string # The API version to be used with the HTTP request. (required)
  --if-match: string # The entity state (ETag) version of the certificate to update. This value can be omitted or set to "*" to apply the operation unconditionally.
  --properties: any # Certificate properties for create operations — shape: {data: string, password?: string, format?: "Pfx"|"Cer", thumbprint?: string, thumbprintAlgorithm?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/certificates/{certificateName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: accountName, var: account_name}, {name: certificateName, var: certificate_name}]
    query: [{name: api-version, var: api_version, required: true}]
    header: [{name: If-Match, var: if_match}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, account_name: $account_name, certificate_name: $certificate_name, api_version: $api_version, if_match: $if_match, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new certificate inside the specified account.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/certificates/{certificateName}
# Returns: record<properties: record<deleteCertificateError: record<code: string, details: list, message: string, target: string>, previousProvisioningState: string, previousProvisioningStateTransitionTime: string, provisioningState: string, provisioningStateTransitionTime: string, publicData: string, format: string, thumbprint: string, thumbprintAlgorithm: string>, etag: string, id: string, name: string, type: string>
# operationId: Certificate_Create
export def "certificate-create" [
  subscription_id: string
  resource_group_name: string
  account_name: string
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
  --api-version: string # The API version to be used with the HTTP request. (required)
  --if-match: string # The entity state (ETag) version of the certificate to update. A value of "*" can be used to apply the operation only if the certificate already exists. If omitted, this operation will always be applied.
  --if-none-match: string # Set to '*' to allow a new certificate to be created, but to prevent updating an existing certificate. Other values will be ignored.
  --properties: any # Certificate properties for create operations — shape: {data: string, password?: string, format?: "Pfx"|"Cer", thumbprint?: string, thumbprintAlgorithm?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/certificates/{certificateName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: accountName, var: account_name}, {name: certificateName, var: certificate_name}]
    query: [{name: api-version, var: api_version, required: true}]
    header: [{name: If-Match, var: if_match}, {name: If-None-Match, var: if_none_match}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, account_name: $account_name, certificate_name: $certificate_name, api_version: $api_version, if_match: $if_match, if_none_match: $if_none_match, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancels a failed deletion of a certificate from the specified account.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/certificates/{certificateName}/cancelDelete
# Returns: record<properties: record<deleteCertificateError: record<code: string, details: list, message: string, target: string>, previousProvisioningState: string, previousProvisioningStateTransitionTime: string, provisioningState: string, provisioningStateTransitionTime: string, publicData: string, format: string, thumbprint: string, thumbprintAlgorithm: string>, etag: string, id: string, name: string, type: string>
# operationId: Certificate_CancelDeletion
export def "certificate-cancel-deletion" [
  subscription_id: string
  resource_group_name: string
  account_name: string
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
  --api-version: string # The API version to be used with the HTTP request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/certificates/{certificateName}/cancelDelete"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: accountName, var: account_name}, {name: certificateName, var: certificate_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, account_name: $account_name, certificate_name: $certificate_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the account keys for the specified Batch account.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/listKeys
# Returns: record<accountName: string, primary: string, secondary: string>
# operationId: BatchAccount_GetKeys
export def "batch-account-get-keys" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to be used with the HTTP request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/listKeys"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: accountName, var: account_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, account_name: $account_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all of the pools in the specified account.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/pools
# Returns: record<nextLink: string, value: table<properties: record, etag: string, id: string, name: string, type: string>>
# operationId: Pool_ListByBatchAccount
export def "pool-list-by-batch-account" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxresults: int # The maximum number of items to return in the response. (format: int32)
  --select: string # Comma separated list of properties that should be returned. e.g. "properties/provisioningState". Only top level properties under properties/ are valid for selection.
  --filter: string # OData filter expression. Valid properties for filtering are: name properties/allocationState properties/allocationStateTransitionTime properties/creationTime properties/provisioningState properties/provisioningStateTransitionTime properties/lastModified properties/vmSize properties/interNodeCommunication properties/scaleSettings/autoScale properties/scaleSettings/fixedScale
  --api-version: string # The API version to be used with the HTTP request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/pools"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: accountName, var: account_name}]
    query: [{name: maxresults, var: maxresults}, {name: "$select", var: select}, {name: "$filter", var: filter}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, account_name: $account_name, maxresults: $maxresults, select: $select, filter: $filter, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified pool.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/pools/{poolName}
# operationId: Pool_Delete
export def "pool-delete" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  pool_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to be used with the HTTP request. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/pools/{poolName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: accountName, var: account_name}, {name: poolName, var: pool_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, account_name: $account_name, pool_name: $pool_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the specified pool.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/pools/{poolName}
# Returns: record<properties: record<allocationState: string, allocationStateTransitionTime: string, applicationLicenses: list<string>, applicationPackages: list<record>, autoScaleRun: record<error: record, evaluationTime: string, results: string>, certificates: list<record>, creationTime: string, currentDedicatedNodes: int, currentLowPriorityNodes: int, deploymentConfiguration: record<cloudServiceConfiguration: record, virtualMachineConfiguration: record>, displayName: string, interNodeCommunication: string, lastModified: string, maxTasksPerNode: int, metadata: list<record>, mountConfiguration: list<record>, networkConfiguration: record<endpointConfiguration: record, publicIPs: list, subnetId: string>, provisioningState: string, provisioningStateTransitionTime: string, resizeOperationStatus: record<errors: list, nodeDeallocationOption: string, resizeTimeout: string, startTime: string, targetDedicatedNodes: int, targetLowPriorityNodes: int>, scaleSettings: record<autoScale: record, fixedScale: record>, startTask: record<commandLine: string, containerSettings: record, environmentSettings: list, maxTaskRetryCount: int, resourceFiles: list, userIdentity: record, waitForSuccess: bool>, taskSchedulingPolicy: record<nodeFillType: string>, userAccounts: list<record>, vmSize: string>, etag: string, id: string, name: string, type: string>
# operationId: Pool_Get
export def "pool-get" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  pool_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to be used with the HTTP request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/pools/{poolName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: accountName, var: account_name}, {name: poolName, var: pool_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, account_name: $account_name, pool_name: $pool_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the properties of an existing pool.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/pools/{poolName}
# Returns: record<properties: record<allocationState: string, allocationStateTransitionTime: string, applicationLicenses: list<string>, applicationPackages: list<record>, autoScaleRun: record<error: record, evaluationTime: string, results: string>, certificates: list<record>, creationTime: string, currentDedicatedNodes: int, currentLowPriorityNodes: int, deploymentConfiguration: record<cloudServiceConfiguration: record, virtualMachineConfiguration: record>, displayName: string, interNodeCommunication: string, lastModified: string, maxTasksPerNode: int, metadata: list<record>, mountConfiguration: list<record>, networkConfiguration: record<endpointConfiguration: record, publicIPs: list, subnetId: string>, provisioningState: string, provisioningStateTransitionTime: string, resizeOperationStatus: record<errors: list, nodeDeallocationOption: string, resizeTimeout: string, startTime: string, targetDedicatedNodes: int, targetLowPriorityNodes: int>, scaleSettings: record<autoScale: record, fixedScale: record>, startTask: record<commandLine: string, containerSettings: record, environmentSettings: list, maxTaskRetryCount: int, resourceFiles: list, userIdentity: record, waitForSuccess: bool>, taskSchedulingPolicy: record<nodeFillType: string>, userAccounts: list<record>, vmSize: string>, etag: string, id: string, name: string, type: string>
# operationId: Pool_Update
export def "pool-update" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  pool_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to be used with the HTTP request. (required)
  --if-match: string # The entity state (ETag) version of the pool to update. This value can be omitted or set to "*" to apply the operation unconditionally.
  --properties: any # Pool properties. — shape: {applicationLicenses?: list<string>, applicationPackages?: list, autoScaleRun?: any, certificates?: list, deploymentConfiguration?: any, displayName?: string, interNodeCommunication?: "Enabled"|"Disabled", maxTasksPerNode?: int, metadata?: list, mountConfiguration?: list, networkConfiguration?: any, resizeOperationStatus?: any, scaleSettings?: any, startTask?: any, taskSchedulingPolicy?: any, userAccounts?: list, vmSize?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/pools/{poolName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: accountName, var: account_name}, {name: poolName, var: pool_name}]
    query: [{name: api-version, var: api_version, required: true}]
    header: [{name: If-Match, var: if_match}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, account_name: $account_name, pool_name: $pool_name, api_version: $api_version, if_match: $if_match, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new pool inside the specified account.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/pools/{poolName}
# Returns: record<properties: record<allocationState: string, allocationStateTransitionTime: string, applicationLicenses: list<string>, applicationPackages: list<record>, autoScaleRun: record<error: record, evaluationTime: string, results: string>, certificates: list<record>, creationTime: string, currentDedicatedNodes: int, currentLowPriorityNodes: int, deploymentConfiguration: record<cloudServiceConfiguration: record, virtualMachineConfiguration: record>, displayName: string, interNodeCommunication: string, lastModified: string, maxTasksPerNode: int, metadata: list<record>, mountConfiguration: list<record>, networkConfiguration: record<endpointConfiguration: record, publicIPs: list, subnetId: string>, provisioningState: string, provisioningStateTransitionTime: string, resizeOperationStatus: record<errors: list, nodeDeallocationOption: string, resizeTimeout: string, startTime: string, targetDedicatedNodes: int, targetLowPriorityNodes: int>, scaleSettings: record<autoScale: record, fixedScale: record>, startTask: record<commandLine: string, containerSettings: record, environmentSettings: list, maxTaskRetryCount: int, resourceFiles: list, userIdentity: record, waitForSuccess: bool>, taskSchedulingPolicy: record<nodeFillType: string>, userAccounts: list<record>, vmSize: string>, etag: string, id: string, name: string, type: string>
# operationId: Pool_Create
export def "pool-create" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  pool_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to be used with the HTTP request. (required)
  --if-match: string # The entity state (ETag) version of the pool to update. A value of "*" can be used to apply the operation only if the pool already exists. If omitted, this operation will always be applied.
  --if-none-match: string # Set to '*' to allow a new pool to be created, but to prevent updating an existing pool. Other values will be ignored.
  --properties: any # Pool properties. — shape: {applicationLicenses?: list<string>, applicationPackages?: list, autoScaleRun?: any, certificates?: list, deploymentConfiguration?: any, displayName?: string, interNodeCommunication?: "Enabled"|"Disabled", maxTasksPerNode?: int, metadata?: list, mountConfiguration?: list, networkConfiguration?: any, resizeOperationStatus?: any, scaleSettings?: any, startTask?: any, taskSchedulingPolicy?: any, userAccounts?: list, vmSize?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/pools/{poolName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: accountName, var: account_name}, {name: poolName, var: pool_name}]
    query: [{name: api-version, var: api_version, required: true}]
    header: [{name: If-Match, var: if_match}, {name: If-None-Match, var: if_none_match}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, account_name: $account_name, pool_name: $pool_name, api_version: $api_version, if_match: $if_match, if_none_match: $if_none_match, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disables automatic scaling for a pool.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/pools/{poolName}/disableAutoScale
# Returns: record<properties: record<allocationState: string, allocationStateTransitionTime: string, applicationLicenses: list<string>, applicationPackages: list<record>, autoScaleRun: record<error: record, evaluationTime: string, results: string>, certificates: list<record>, creationTime: string, currentDedicatedNodes: int, currentLowPriorityNodes: int, deploymentConfiguration: record<cloudServiceConfiguration: record, virtualMachineConfiguration: record>, displayName: string, interNodeCommunication: string, lastModified: string, maxTasksPerNode: int, metadata: list<record>, mountConfiguration: list<record>, networkConfiguration: record<endpointConfiguration: record, publicIPs: list, subnetId: string>, provisioningState: string, provisioningStateTransitionTime: string, resizeOperationStatus: record<errors: list, nodeDeallocationOption: string, resizeTimeout: string, startTime: string, targetDedicatedNodes: int, targetLowPriorityNodes: int>, scaleSettings: record<autoScale: record, fixedScale: record>, startTask: record<commandLine: string, containerSettings: record, environmentSettings: list, maxTaskRetryCount: int, resourceFiles: list, userIdentity: record, waitForSuccess: bool>, taskSchedulingPolicy: record<nodeFillType: string>, userAccounts: list<record>, vmSize: string>, etag: string, id: string, name: string, type: string>
# operationId: Pool_DisableAutoScale
export def "pool-disable-auto-scale" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  pool_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to be used with the HTTP request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/pools/{poolName}/disableAutoScale"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: accountName, var: account_name}, {name: poolName, var: pool_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, account_name: $account_name, pool_name: $pool_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stops an ongoing resize operation on the pool.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/pools/{poolName}/stopResize
# Returns: record<properties: record<allocationState: string, allocationStateTransitionTime: string, applicationLicenses: list<string>, applicationPackages: list<record>, autoScaleRun: record<error: record, evaluationTime: string, results: string>, certificates: list<record>, creationTime: string, currentDedicatedNodes: int, currentLowPriorityNodes: int, deploymentConfiguration: record<cloudServiceConfiguration: record, virtualMachineConfiguration: record>, displayName: string, interNodeCommunication: string, lastModified: string, maxTasksPerNode: int, metadata: list<record>, mountConfiguration: list<record>, networkConfiguration: record<endpointConfiguration: record, publicIPs: list, subnetId: string>, provisioningState: string, provisioningStateTransitionTime: string, resizeOperationStatus: record<errors: list, nodeDeallocationOption: string, resizeTimeout: string, startTime: string, targetDedicatedNodes: int, targetLowPriorityNodes: int>, scaleSettings: record<autoScale: record, fixedScale: record>, startTask: record<commandLine: string, containerSettings: record, environmentSettings: list, maxTaskRetryCount: int, resourceFiles: list, userIdentity: record, waitForSuccess: bool>, taskSchedulingPolicy: record<nodeFillType: string>, userAccounts: list<record>, vmSize: string>, etag: string, id: string, name: string, type: string>
# operationId: Pool_StopResize
export def "pool-stop-resize" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  pool_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to be used with the HTTP request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/pools/{poolName}/stopResize"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: accountName, var: account_name}, {name: poolName, var: pool_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, account_name: $account_name, pool_name: $pool_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Regenerates the specified account key for the Batch account.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/regenerateKeys
# Returns: record<accountName: string, primary: string, secondary: string>
# operationId: BatchAccount_RegenerateKey
export def "batch-account-regenerate-key" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to be used with the HTTP request. (required)
  key_name: string@key-name-completer # The type of account key to regenerate.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/regenerateKeys"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: accountName, var: account_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: keyName, var: key_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, account_name: $account_name, api_version: $api_version, key_name: $key_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Synchronizes access keys for the auto-storage account configured for the specified Batch account.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/syncAutoStorageKeys
# operationId: BatchAccount_SynchronizeAutoStorageKeys
export def "batch-account-synchronize-auto-storage-keys" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to be used with the HTTP request. (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/syncAutoStorageKeys"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: accountName, var: account_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, account_name: $account_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
