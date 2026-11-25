# Auto-generated client for Pims v1.0
# Source: https://api.apis.guru/v2/specs/pims.io/1.0/swagger.json
# Auth: --token flag or $env.PIMS_TOKEN

const CLIENT = {
  base_url: "https://demo.pims.io/api/v1"
  token_env_var: "PIMS_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: basic, in: header, header_name: Authorization, prefix: Basic}
    {name: basic-credentials, in: header, header_name: Authorization, prefix: Basic, base64: true}
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

def base-url-completer [] { ["https://demo.pims.io/api/v1"] }
def auth-scheme-completer [] { ["basic" "basic-credentials"] }

# Completers for enum parameters
def sort-completer [] { ["-label" "-order" "label" "order"] }
def accept-language-completer [] { ["de" "en" "fr"] }
def sort-completer-1 [] { ["-city" "-datetime" "-label" "-venue_label" "city" "datetime" "label" "venue_label"] }
def sort-completer-2 [] { ["-date" "date"] }
def sort-completer-3 [] { ["-date" "-total_cost" "date" "total_cost"] }
def type-completer [] { ["LGS" "TOU"] }
def sort-completer-4 [] { ["-first_date" "-label" "-last_date" "first_date" "label" "last_date"] }
def type-completer-1 [] { ["FES" "SAL"] }
def sort-completer-5 [] { ["-city" "-country" "-label" "city" "country" "label"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    fetch-all-categories: "table<id: int, ignored: bool, label: string, last_update_timestamp: int, short_label: string>"
    fetch-one-category: "record<id: int, ignored: bool, label: string, last_update_timestamp: int, short_label: string>"
    fetch-all-channels: "table<id: int, ignored: bool, label: string, last_update_timestamp: int, short_label: string>"
    fetch-one-channel: "record<id: int, ignored: bool, label: string, last_update_timestamp: int, short_label: string>"
    fetch-all-events: "table<break_even: int, cancellation_date: string, contract: record<partner: record, type: record>, costing_capacity: int, creation_timestamp: int, currency: string, datetime: string, free: bool, general_sales_date: string, id: int, input_type: record<id: string, label: string>, label: string, last_update_timestamp: int, max_capacity: int, presales_date: string, series_id: int, sold_out_date: string, venue: record<alternative_labels: list, city: string, country_code: string, creation_timestamp: int, first_address: string, id: int, label: string, last_update_timestamp: int, major_city: string, second_address: string, type: record, zip_code: string>>"
    fetch-one-event: "record<break_even: int, cancellation_date: string, contract: record<partner: record<id: int, label: string>, type: record<id: string, label: string>>, costing_capacity: int, creation_timestamp: int, currency: string, datetime: string, free: bool, general_sales_date: string, id: int, input_type: record<id: string, label: string>, label: string, last_update_timestamp: int, max_capacity: int, presales_date: string, series_id: int, sold_out_date: string, venue: record<alternative_labels: list<string>, city: string, country_code: string, creation_timestamp: int, first_address: string, id: int, label: string, last_update_timestamp: int, major_city: string, second_address: string, type: record<id: string, label: string>, zip_code: string>>"
    fetch-all-events-capacities: "table<date: string, event_categories: list<record>, id: int>"
    fetch-one-event-capacity: "record<date: string, event_categories: table<comps: int, holds: int, id: int, kills: int, sellable_capacity: int, total_capacity: int>, id: int>"
    fetch-all-events-categories: "table<category: record<id: int, ignored: bool, label: string, last_update_timestamp: int, short_label: string>, event_price_ranges: list<record>, id: int, ignored: bool>"
    fetch-one-event-category: "record<category: record<id: int, ignored: bool, label: string, last_update_timestamp: int, short_label: string>, event_price_ranges: table<base_price: float, currency: string, id: int, ignored: bool, price_range: record, public_price: float>, id: int, ignored: bool>"
    fetch-all-events-channels: "table<channel: record<id: int, ignored: bool, label: string, last_update_timestamp: int, short_label: string>, id: int, ignored: bool>"
    fetch-one-event-channel: "record<channel: record<id: int, ignored: bool, label: string, last_update_timestamp: int, short_label: string>, id: int, ignored: bool>"
    fetch-all-events-promotions: "table<applied_to: list<record>, comments: string, cost: record<currency: string, exchange: string, quantity: float, state: record, type: record, unit_cost: float, valorized_quantity: float, valorized_unit_cost: float>, end_date: string, file: string, id: int, label: string, start_date: string, supplier: record<id: int, label: string>, type: record<family: record, id: string, label: string>>"
    fetch-all-ticket-counts: "table<approved: bool, comment: string, currency: string, date: string, final: bool, gross: float, id: int, reservations: int, sales: int>"
    fetch-all-detailed-ticket-counts: "table<approved: bool, comment: string, date: string, event_channels: list<record>, final: bool, id: int>"
    fetch-one-detailed-ticket-count: "record<approved: bool, comment: string, date: string, event_channels: table<event_categories: list, id: int>, final: bool, id: int>"
    fetch-one-ticket-count: "record<approved: bool, comment: string, currency: string, date: string, final: bool, gross: float, id: int, reservations: int, sales: int>"
    fetch-all-price-ranges: "table<id: int, ignored: bool, label: string, last_update_timestamp: int, short_label: string>"
    fetch-one-price-range: "record<alternative_labels: list<string>, city: string, country_code: string, creation_timestamp: int, first_address: string, id: int, label: string, last_update_timestamp: int, major_city: string, second_address: string, type: record<id: string, label: string>, zip_code: string>"
    fetch-all-promotions: "table<applied_to: list<record>, comments: string, cost: record<currency: string, exchange: string, quantity: float, state: record, type: record, unit_cost: float, valorized_quantity: float, valorized_unit_cost: float>, end_date: string, file: string, id: int, label: string, start_date: string, supplier: record<id: int, label: string>, type: record<family: record, id: string, label: string>>"
    fetch-one-promotion: "record<applied_to: table<event_id: int, quantity: float, series_id: int, unit_cost: float, valorized_quantity: float, valorized_unit_cost: float>, comments: string, cost: record<currency: string, exchange: string, quantity: float, state: record<id: string, label: string>, type: record<id: string, label: string>, unit_cost: float, valorized_quantity: float, valorized_unit_cost: float>, end_date: string, file: string, id: int, label: string, start_date: string, supplier: record<id: int, label: string>, type: record<family: record<id: string, label: string>, id: string, label: string>>"
    fetch-all-series: "table<contract: record<partner: record, type: record>, costing_capacity: int, creation_timestamp: int, first_date: string, id: int, label: string, last_date: string, last_update_timestamp: int, type: record<id: string, label: string>, venue: record<alternative_labels: list, city: string, country_code: string, creation_timestamp: int, first_address: string, id: int, label: string, last_update_timestamp: int, major_city: string, second_address: string, type: record, zip_code: string>>"
    fetch-one-series: "record<contract: record<partner: record<id: int, label: string>, type: record<id: string, label: string>>, costing_capacity: int, creation_timestamp: int, first_date: string, id: int, label: string, last_date: string, last_update_timestamp: int, type: record<id: string, label: string>, venue: record<alternative_labels: list<string>, city: string, country_code: string, creation_timestamp: int, first_address: string, id: int, label: string, last_update_timestamp: int, major_city: string, second_address: string, type: record<id: string, label: string>, zip_code: string>>"
    fetch-all-series-events: "table<break_even: int, cancellation_date: string, contract: record<partner: record, type: record>, costing_capacity: int, creation_timestamp: int, currency: string, datetime: string, free: bool, general_sales_date: string, id: int, input_type: record<id: string, label: string>, label: string, last_update_timestamp: int, max_capacity: int, presales_date: string, series_id: int, sold_out_date: string, venue: record<alternative_labels: list, city: string, country_code: string, creation_timestamp: int, first_address: string, id: int, label: string, last_update_timestamp: int, major_city: string, second_address: string, type: record, zip_code: string>>"
    fetch-all-series-promotions: "table<applied_to: list<record>, comments: string, cost: record<currency: string, exchange: string, quantity: float, state: record, type: record, unit_cost: float, valorized_quantity: float, valorized_unit_cost: float>, end_date: string, file: string, id: int, label: string, start_date: string, supplier: record<id: int, label: string>, type: record<family: record, id: string, label: string>>"
    fetch-all-venues: "table<alternative_labels: list<string>, city: string, country_code: string, creation_timestamp: int, first_address: string, id: int, label: string, last_update_timestamp: int, major_city: string, second_address: string, type: record<id: string, label: string>, zip_code: string>"
    fetch-one-venue: "record<alternative_labels: list<string>, city: string, country_code: string, creation_timestamp: int, first_address: string, id: int, label: string, last_update_timestamp: int, major_city: string, second_address: string, type: record<id: string, label: string>, zip_code: string>"
    fetch-all-venues-events: "table<break_even: int, cancellation_date: string, contract: record<partner: record, type: record>, costing_capacity: int, creation_timestamp: int, currency: string, datetime: string, free: bool, general_sales_date: string, id: int, input_type: record<id: string, label: string>, label: string, last_update_timestamp: int, max_capacity: int, presales_date: string, series_id: int, sold_out_date: string, venue: record<alternative_labels: list, city: string, country_code: string, creation_timestamp: int, first_address: string, id: int, label: string, last_update_timestamp: int, major_city: string, second_address: string, type: record, zip_code: string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["fetch-all-categories" "fetch-one-category" "fetch-all-channels" "fetch-one-channel" "fetch-all-events" "fetch-one-event" "fetch-all-events-capacities" "fetch-one-event-capacity" "fetch-all-events-categories" "fetch-one-event-category" "fetch-all-events-channels" "fetch-one-event-channel" "fetch-all-events-promotions" "fetch-all-ticket-counts" "fetch-all-detailed-ticket-counts" "fetch-one-detailed-ticket-count" "fetch-one-ticket-count" "fetch-all-price-ranges" "fetch-one-price-range" "fetch-all-promotions" "fetch-one-promotion" "fetch-all-series" "fetch-one-series" "fetch-all-series-events" "fetch-all-series-promotions" "fetch-all-venues" "fetch-one-venue" "fetch-all-venues-events" "commands"] | sort) } | get name | first)
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

# Find all categories
#
# GET /categories
# Returns: table<id: int, ignored: bool, label: string, last_update_timestamp: int, short_label: string>
# operationId: fetchAllCategories
export def "fetch-all-categories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --label: string # Find only the categories whose label/short label contains this value.
  --show-ignored: oneof<nothing, bool> # If set to `false`, show only the categories which are not ignored. If set to `true`, show all categories. (default: false)
  --sort: string@sort-completer # Sort the categories in the corresponding order. (default: order)
  --page-size: int # Pagination size, i.e. maximum number of items to be displayed in the response. (format: int32, default: 25)
  --accept-language: string@accept-language-completer # Language used for the translatable labels. (default: en)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/categories"
    query: [{name: label, var: label}, {name: show_ignored, var: show_ignored}, {name: sort, var: sort}, {name: page_size, var: page_size}]
    header: [{name: Accept-Language, var: accept_language}]
    accept: ["application/hal+json"]
    ok: [200]
    auth: basic
  } {
    label: $label, show_ignored: $show_ignored, sort: $sort, page_size: $page_size, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get one category by ID
#
# GET /categories/{category_id}
# Returns: record<id: int, ignored: bool, label: string, last_update_timestamp: int, short_label: string>
# operationId: fetchOneCategory
export def "fetch-one-category" [
  category_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string@accept-language-completer # Language used for the translatable labels. (default: en)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/categories/{category_id}"
    path_params: [{name: category_id, var: category_id}]
    header: [{name: Accept-Language, var: accept_language}]
    accept: ["application/hal+json"]
    ok: [200]
    auth: basic
  } {
    category_id: $category_id, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find all channels
#
# GET /channels
# Returns: table<id: int, ignored: bool, label: string, last_update_timestamp: int, short_label: string>
# operationId: fetchAllChannels
export def "fetch-all-channels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --label: string # Find only the channels whose label contains this value.
  --show-ignored: oneof<nothing, bool> # If set to `false`, show only the channels which are not ignored. If set to `true`, show all channels. (default: false)
  --sort: string@sort-completer # Sort the channels in the corresponding order. (default: label)
  --page-size: int # Pagination size, i.e. maximum number of items to be displayed in the response. (format: int32, default: 25)
  --accept-language: string@accept-language-completer # Language used for the translatable labels. (default: en)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/channels"
    query: [{name: label, var: label}, {name: show_ignored, var: show_ignored}, {name: sort, var: sort}, {name: page_size, var: page_size}]
    header: [{name: Accept-Language, var: accept_language}]
    accept: ["application/hal+json"]
    ok: [200]
    auth: basic
  } {
    label: $label, show_ignored: $show_ignored, sort: $sort, page_size: $page_size, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get one channel by ID
#
# GET /channels/{channel_id}
# Returns: record<id: int, ignored: bool, label: string, last_update_timestamp: int, short_label: string>
# operationId: fetchOneChannel
export def "fetch-one-channel" [
  channel_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string@accept-language-completer # Language used for the translatable labels. (default: en)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/channels/{channel_id}"
    path_params: [{name: channel_id, var: channel_id}]
    header: [{name: Accept-Language, var: accept_language}]
    accept: ["application/hal+json"]
    ok: [200]
    auth: basic
  } {
    channel_id: $channel_id, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find all events
#
# GET /events
# Returns: table<break_even: int, cancellation_date: string, contract: record<partner: record, type: record>, costing_capacity: int, creation_timestamp: int, currency: string, datetime: string, free: bool, general_sales_date: string, id: int, input_type: record<id: string, label: string>, label: string, last_update_timestamp: int, max_capacity: int, presales_date: string, series_id: int, sold_out_date: string, venue: record<alternative_labels: list, city: string, country_code: string, creation_timestamp: int, first_address: string, id: int, label: string, last_update_timestamp: int, major_city: string, second_address: string, type: record, zip_code: string>>
# operationId: fetchAllEvents
export def "fetch-all-events" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --label: string # Find only the events whose label contains this value.
  --from-datetime: string # Find only the events starting after this date. (format: date)
  --to-datetime: string # Find only the events starting before this date. (format: date)
  --city: string # Find only the events whose venue city (or metropolitan area) contains this value.
  --sort: string@sort-completer-1 # Sort the events in the corresponding order. (default: label)
  --page-size: int # Pagination size, i.e. maximum number of items to be displayed in the response. (format: int32, default: 25)
  --accept-language: string@accept-language-completer # Language used for the translatable labels. (default: en)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/events"
    query: [{name: label, var: label}, {name: from_datetime, var: from_datetime}, {name: to_datetime, var: to_datetime}, {name: city, var: city}, {name: sort, var: sort}, {name: page_size, var: page_size}]
    header: [{name: Accept-Language, var: accept_language}]
    accept: ["application/hal+json"]
    ok: [200]
    auth: basic
  } {
    label: $label, from_datetime: $from_datetime, to_datetime: $to_datetime, city: $city, sort: $sort, page_size: $page_size, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get one event by ID
#
# GET /events/{event_id}
# Returns: record<break_even: int, cancellation_date: string, contract: record<partner: record<id: int, label: string>, type: record<id: string, label: string>>, costing_capacity: int, creation_timestamp: int, currency: string, datetime: string, free: bool, general_sales_date: string, id: int, input_type: record<id: string, label: string>, label: string, last_update_timestamp: int, max_capacity: int, presales_date: string, series_id: int, sold_out_date: string, venue: record<alternative_labels: list<string>, city: string, country_code: string, creation_timestamp: int, first_address: string, id: int, label: string, last_update_timestamp: int, major_city: string, second_address: string, type: record<id: string, label: string>, zip_code: string>>
# operationId: fetchOneEvent
export def "fetch-one-event" [
  event_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string@accept-language-completer # Language used for the translatable labels. (default: en)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/events/{event_id}"
    path_params: [{name: event_id, var: event_id}]
    header: [{name: Accept-Language, var: accept_language}]
    accept: ["application/hal+json"]
    ok: [200]
    auth: basic
  } {
    event_id: $event_id, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find all capacities for one event
#
# GET /events/{event_id}/capacities
# Returns: table<date: string, event_categories: list<record>, id: int>
# operationId: fetchAllEventsCapacities
export def "fetch-all-events-capacities" [
  event_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --show-ignored: oneof<nothing, bool> # If set to `false`, show only the [event-]categories which are not ignored. If set to `true`, show everything. (default: false)
  --sort: string@sort-completer-2 # Sort the capacities in the corresponding order. (default: date)
  --page-size: int # Pagination size, i.e. maximum number of items to be displayed in the response. (format: int32, default: 25)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/events/{event_id}/capacities"
    path_params: [{name: event_id, var: event_id}]
    query: [{name: show_ignored, var: show_ignored}, {name: sort, var: sort}, {name: page_size, var: page_size}]
    accept: ["application/hal+json"]
    ok: [200]
    auth: basic
  } {
    event_id: $event_id, show_ignored: $show_ignored, sort: $sort, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get one capacity by ID
#
# GET /events/{event_id}/capacities/{capacity_id}
# Returns: record<date: string, event_categories: table<comps: int, holds: int, id: int, kills: int, sellable_capacity: int, total_capacity: int>, id: int>
# operationId: fetchOneEventCapacity
export def "fetch-one-event-capacity" [
  event_id: int
  capacity_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --show-ignored: oneof<nothing, bool> # If set to `false`, show only the [event-]categories which are not ignored. If set to `true`, show everything. (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/events/{event_id}/capacities/{capacity_id}"
    path_params: [{name: event_id, var: event_id}, {name: capacity_id, var: capacity_id}]
    query: [{name: show_ignored, var: show_ignored}]
    accept: ["application/hal+json"]
    ok: [200]
    auth: basic
  } {
    event_id: $event_id, capacity_id: $capacity_id, show_ignored: $show_ignored
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find all categories for one event
#
# GET /events/{event_id}/categories
# Returns: table<category: record<id: int, ignored: bool, label: string, last_update_timestamp: int, short_label: string>, event_price_ranges: list<record>, id: int, ignored: bool>
# operationId: fetchAllEventsCategories
export def "fetch-all-events-categories" [
  event_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --show-ignored: oneof<nothing, bool> # If set to `false`, show only the [event-]categories/[event-]price ranges which are not ignored. If set to `true`, show everything. (default: false)
  --page-size: int # Pagination size, i.e. maximum number of items to be displayed in the response. (format: int32, default: 25)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/events/{event_id}/categories"
    path_params: [{name: event_id, var: event_id}]
    query: [{name: show_ignored, var: show_ignored}, {name: page_size, var: page_size}]
    accept: ["application/hal+json"]
    ok: [200]
    auth: basic
  } {
    event_id: $event_id, show_ignored: $show_ignored, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get one event category by ID
#
# GET /events/{event_id}/categories/{category_id}
# Returns: record<category: record<id: int, ignored: bool, label: string, last_update_timestamp: int, short_label: string>, event_price_ranges: table<base_price: float, currency: string, id: int, ignored: bool, price_range: record, public_price: float>, id: int, ignored: bool>
# operationId: fetchOneEventCategory
export def "fetch-one-event-category" [
  event_id: int
  category_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --show-ignored: oneof<nothing, bool> # If set to `false`, show only the embedded [event-]price ranges which are not ignored. If set to `true`, show everything. (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/events/{event_id}/categories/{category_id}"
    path_params: [{name: event_id, var: event_id}, {name: category_id, var: category_id}]
    query: [{name: show_ignored, var: show_ignored}]
    accept: ["application/hal+json"]
    ok: [200]
    auth: basic
  } {
    event_id: $event_id, category_id: $category_id, show_ignored: $show_ignored
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find all channels for one event
#
# GET /events/{event_id}/channels
# Returns: table<channel: record<id: int, ignored: bool, label: string, last_update_timestamp: int, short_label: string>, id: int, ignored: bool>
# operationId: fetchAllEventsChannels
export def "fetch-all-events-channels" [
  event_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --show-ignored: oneof<nothing, bool> # If set to `false`, show only the [event-]channels which are not ignored. If set to `true`, show everything. (default: false)
  --page-size: int # Pagination size, i.e. maximum number of items to be displayed in the response. (format: int32, default: 25)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/events/{event_id}/channels"
    path_params: [{name: event_id, var: event_id}]
    query: [{name: show_ignored, var: show_ignored}, {name: page_size, var: page_size}]
    accept: ["application/hal+json"]
    ok: [200]
    auth: basic
  } {
    event_id: $event_id, show_ignored: $show_ignored, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get one event channel by ID
#
# GET /events/{event_id}/channels/{channel_id}
# Returns: record<channel: record<id: int, ignored: bool, label: string, last_update_timestamp: int, short_label: string>, id: int, ignored: bool>
# operationId: fetchOneEventChannel
export def "fetch-one-event-channel" [
  event_id: int
  channel_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/events/{event_id}/channels/{channel_id}"
    path_params: [{name: event_id, var: event_id}, {name: channel_id, var: channel_id}]
    accept: ["application/hal+json"]
    ok: [200]
    auth: basic
  } {
    event_id: $event_id, channel_id: $channel_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find all promotions for one event
#
# GET /events/{event_id}/promotions
# Returns: table<applied_to: list<record>, comments: string, cost: record<currency: string, exchange: string, quantity: float, state: record, type: record, unit_cost: float, valorized_quantity: float, valorized_unit_cost: float>, end_date: string, file: string, id: int, label: string, start_date: string, supplier: record<id: int, label: string>, type: record<family: record, id: string, label: string>>
# operationId: fetchAllEventsPromotions
export def "fetch-all-events-promotions" [
  event_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --label: string # Find only the promotions whose label contains this value.
  --from-date: string # Find only the promotions starting after this date. (format: date)
  --to-date: string # Find only the promotions ending before this date. (format: date)
  --type: string # Find only the promotions whose type is equal to this value.
  --family: string # Find only the promotions whose family is equal to this value.
  --sort: string@sort-completer-3 # Sort the promotions in the corresponding order. (default: date)
  --page-size: int # Pagination size, i.e. maximum number of items to be displayed in the response. (format: int32, default: 25)
  --accept-language: string@accept-language-completer # Language used for the translatable labels. (default: en)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/events/{event_id}/promotions"
    path_params: [{name: event_id, var: event_id}]
    query: [{name: label, var: label}, {name: from_date, var: from_date}, {name: to_date, var: to_date}, {name: type, var: type}, {name: family, var: family}, {name: sort, var: sort}, {name: page_size, var: page_size}]
    header: [{name: Accept-Language, var: accept_language}]
    accept: ["application/hal+json"]
    ok: [200]
    auth: basic
  } {
    event_id: $event_id, label: $label, from_date: $from_date, to_date: $to_date, type: $type, family: $family, sort: $sort, page_size: $page_size, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find all ticket counts for one event
#
# GET /events/{event_id}/ticket-counts
# Returns: table<approved: bool, comment: string, currency: string, date: string, final: bool, gross: float, id: int, reservations: int, sales: int>
# operationId: fetchAllTicketCounts
export def "fetch-all-ticket-counts" [
  event_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --from-date: string # Find only the ticket counts after this date. (format: date)
  --to-date: string # Find only the ticket counts before this date. (format: date)
  --show-ignored: oneof<nothing, bool> # If set to `false`, show only the [event-]categories/[event-]price ranges/[event]channels which are not ignored. If set to `true`, show everything. (default: false)
  --show-not-approved: oneof<nothing, bool> # If set to `false`, show only the approved ticket counts. If set to `true`, show all the ticket counts. (default: false)
  --sort: string@sort-completer-2 # Sort the ticket counts in the corresponding order. (default: date)
  --page-size: int # Pagination size, i.e. maximum number of items to be displayed in the response. (format: int32, default: 25)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/events/{event_id}/ticket-counts"
    path_params: [{name: event_id, var: event_id}]
    query: [{name: from_date, var: from_date}, {name: to_date, var: to_date}, {name: show_ignored, var: show_ignored}, {name: show_not_approved, var: show_not_approved}, {name: sort, var: sort}, {name: page_size, var: page_size}]
    accept: ["application/hal+json"]
    ok: [200]
    auth: basic
  } {
    event_id: $event_id, from_date: $from_date, to_date: $to_date, show_ignored: $show_ignored, show_not_approved: $show_not_approved, sort: $sort, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find all detailed ticket counts for one event
#
# GET /events/{event_id}/ticket-counts/detailed
# Returns: table<approved: bool, comment: string, date: string, event_channels: list<record>, final: bool, id: int>
# operationId: fetchAllDetailedTicketCounts
export def "fetch-all-detailed-ticket-counts" [
  event_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --from-date: string # Find only the ticket counts after this date. (format: date)
  --to-date: string # Find only the ticket counts before this date. (format: date)
  --show-ignored: oneof<nothing, bool> # If set to `false`, show only the [event-]categories/[event-]price ranges/[event]channels which are not ignored. If set to `true`, show everything. (default: false)
  --show-not-approved: oneof<nothing, bool> # If set to `false`, show only the approved ticket counts. If set to `true`, show all the ticket counts. (default: false)
  --sort: string@sort-completer-2 # Sort the ticket counts in the corresponding order. (default: date)
  --page-size: int # Pagination size, i.e. maximum number of items to be displayed in the response. (format: int32, default: 25)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/events/{event_id}/ticket-counts/detailed"
    path_params: [{name: event_id, var: event_id}]
    query: [{name: from_date, var: from_date}, {name: to_date, var: to_date}, {name: show_ignored, var: show_ignored}, {name: show_not_approved, var: show_not_approved}, {name: sort, var: sort}, {name: page_size, var: page_size}]
    accept: ["application/hal+json"]
    ok: [200]
    auth: basic
  } {
    event_id: $event_id, from_date: $from_date, to_date: $to_date, show_ignored: $show_ignored, show_not_approved: $show_not_approved, sort: $sort, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get one detailed ticket count by ID
#
# GET /events/{event_id}/ticket-counts/detailed/{ticket_count_id}
# Returns: record<approved: bool, comment: string, date: string, event_channels: table<event_categories: list, id: int>, final: bool, id: int>
# operationId: fetchOneDetailedTicketCount
export def "fetch-one-detailed-ticket-count" [
  event_id: int
  ticket_count_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --show-ignored: oneof<nothing, bool> # If set to `false`, show only the [event-]categories/[event-]price ranges/[event]channels which are not ignored. If set to `true`, show everything. (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/events/{event_id}/ticket-counts/detailed/{ticket_count_id}"
    path_params: [{name: event_id, var: event_id}, {name: ticket_count_id, var: ticket_count_id}]
    query: [{name: show_ignored, var: show_ignored}]
    accept: ["application/hal+json"]
    ok: [200]
    auth: basic
  } {
    event_id: $event_id, ticket_count_id: $ticket_count_id, show_ignored: $show_ignored
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get one ticket count by ID
#
# GET /events/{event_id}/ticket-counts/{ticket_count_id}
# Returns: record<approved: bool, comment: string, currency: string, date: string, final: bool, gross: float, id: int, reservations: int, sales: int>
# operationId: fetchOneTicketCount
export def "fetch-one-ticket-count" [
  event_id: int
  ticket_count_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --show-ignored: oneof<nothing, bool> # If set to `false`, show only the [event-]categories/[event-]price ranges/[event]channels which are not ignored. If set to `true`, show everything. (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/events/{event_id}/ticket-counts/{ticket_count_id}"
    path_params: [{name: event_id, var: event_id}, {name: ticket_count_id, var: ticket_count_id}]
    query: [{name: show_ignored, var: show_ignored}]
    accept: ["application/hal+json"]
    ok: [200]
    auth: basic
  } {
    event_id: $event_id, ticket_count_id: $ticket_count_id, show_ignored: $show_ignored
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find all price ranges
#
# GET /price-ranges
# Returns: table<id: int, ignored: bool, label: string, last_update_timestamp: int, short_label: string>
# operationId: fetchAllPriceRanges
export def "fetch-all-price-ranges" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --label: string # Find only the price ranges whose label contains this value.
  --show-ignored: oneof<nothing, bool> # If set to `false`, show only the price ranges which are not ignored. If set to `true`, show all price ranges. (default: false)
  --sort: string@sort-completer # Sort the price ranges in the corresponding order. (default: label)
  --page-size: int # Pagination size, i.e. maximum number of items to be displayed in the response. (format: int32, default: 25)
  --accept-language: string@accept-language-completer # Language used for the translatable labels. (default: en)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/price-ranges"
    query: [{name: label, var: label}, {name: show_ignored, var: show_ignored}, {name: sort, var: sort}, {name: page_size, var: page_size}]
    header: [{name: Accept-Language, var: accept_language}]
    accept: ["application/hal+json"]
    ok: [200]
    auth: basic
  } {
    label: $label, show_ignored: $show_ignored, sort: $sort, page_size: $page_size, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get one price range by ID
#
# GET /price-ranges/{price_range_id}
# Returns: record<alternative_labels: list<string>, city: string, country_code: string, creation_timestamp: int, first_address: string, id: int, label: string, last_update_timestamp: int, major_city: string, second_address: string, type: record<id: string, label: string>, zip_code: string>
# operationId: fetchOnePriceRange
export def "fetch-one-price-range" [
  price_range_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string@accept-language-completer # Language used for the translatable labels. (default: en)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/price-ranges/{price_range_id}"
    path_params: [{name: price_range_id, var: price_range_id}]
    header: [{name: Accept-Language, var: accept_language}]
    accept: ["application/hal+json"]
    ok: [200]
    auth: basic
  } {
    price_range_id: $price_range_id, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find all promotions
#
# GET /promotions
# Returns: table<applied_to: list<record>, comments: string, cost: record<currency: string, exchange: string, quantity: float, state: record, type: record, unit_cost: float, valorized_quantity: float, valorized_unit_cost: float>, end_date: string, file: string, id: int, label: string, start_date: string, supplier: record<id: int, label: string>, type: record<family: record, id: string, label: string>>
# operationId: fetchAllPromotions
export def "fetch-all-promotions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --label: string # Find only the promotions whose label contains this value.
  --from-date: string # Find only the promotions starting after this date. (format: date)
  --to-date: string # Find only the promotions ending before this date. (format: date)
  --type: string # Find only the promotions whose type is equal to this value.
  --family: string # Find only the promotions whose family is equal to this value.
  --sort: string@sort-completer-3 # Sort the promotions in the corresponding order. (default: date)
  --page-size: int # Pagination size, i.e. maximum number of items to be displayed in the response. (format: int32, default: 25)
  --accept-language: string@accept-language-completer # Language used for the translatable labels. (default: en)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/promotions"
    query: [{name: label, var: label}, {name: from_date, var: from_date}, {name: to_date, var: to_date}, {name: type, var: type}, {name: family, var: family}, {name: sort, var: sort}, {name: page_size, var: page_size}]
    header: [{name: Accept-Language, var: accept_language}]
    accept: ["application/hal+json"]
    ok: [200]
    auth: basic
  } {
    label: $label, from_date: $from_date, to_date: $to_date, type: $type, family: $family, sort: $sort, page_size: $page_size, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get one promotion by ID
#
# GET /promotions/{promotion_id}
# Returns: record<applied_to: table<event_id: int, quantity: float, series_id: int, unit_cost: float, valorized_quantity: float, valorized_unit_cost: float>, comments: string, cost: record<currency: string, exchange: string, quantity: float, state: record<id: string, label: string>, type: record<id: string, label: string>, unit_cost: float, valorized_quantity: float, valorized_unit_cost: float>, end_date: string, file: string, id: int, label: string, start_date: string, supplier: record<id: int, label: string>, type: record<family: record<id: string, label: string>, id: string, label: string>>
# operationId: fetchOnePromotion
export def "fetch-one-promotion" [
  promotion_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string@accept-language-completer # Language used for the translatable labels. (default: en)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/promotions/{promotion_id}"
    path_params: [{name: promotion_id, var: promotion_id}]
    header: [{name: Accept-Language, var: accept_language}]
    accept: ["application/hal+json"]
    ok: [200]
    auth: basic
  } {
    promotion_id: $promotion_id, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find all series
#
# GET /series
# Returns: table<contract: record<partner: record, type: record>, costing_capacity: int, creation_timestamp: int, first_date: string, id: int, label: string, last_date: string, last_update_timestamp: int, type: record<id: string, label: string>, venue: record<alternative_labels: list, city: string, country_code: string, creation_timestamp: int, first_address: string, id: int, label: string, last_update_timestamp: int, major_city: string, second_address: string, type: record, zip_code: string>>
# operationId: fetchAllSeries
export def "fetch-all-series" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --label: string # Find only the venues whose label contains this value.
  --from-date: string # Find only the series starting after this date. (format: date)
  --to-date: string # Find only the series ending before this date. (format: date)
  --type: string@type-completer # Find only the series whose type is equal to this value.
  --sort: string@sort-completer-4 # Sort the series in the corresponding order. (default: first_date)
  --page-size: int # Pagination size, i.e. maximum number of items to be displayed in the response. (format: int32, default: 25)
  --accept-language: string@accept-language-completer # Language used for the translatable labels. (default: en)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/series"
    query: [{name: label, var: label}, {name: from_date, var: from_date}, {name: to_date, var: to_date}, {name: type, var: type}, {name: sort, var: sort}, {name: page_size, var: page_size}]
    header: [{name: Accept-Language, var: accept_language}]
    accept: ["application/hal+json"]
    ok: [200]
    auth: basic
  } {
    label: $label, from_date: $from_date, to_date: $to_date, type: $type, sort: $sort, page_size: $page_size, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get one series by ID
#
# GET /series/{series_id}
# Returns: record<contract: record<partner: record<id: int, label: string>, type: record<id: string, label: string>>, costing_capacity: int, creation_timestamp: int, first_date: string, id: int, label: string, last_date: string, last_update_timestamp: int, type: record<id: string, label: string>, venue: record<alternative_labels: list<string>, city: string, country_code: string, creation_timestamp: int, first_address: string, id: int, label: string, last_update_timestamp: int, major_city: string, second_address: string, type: record<id: string, label: string>, zip_code: string>>
# operationId: fetchOneSeries
export def "fetch-one-series" [
  series_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string@accept-language-completer # Language used for the translatable labels. (default: en)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/series/{series_id}"
    path_params: [{name: series_id, var: series_id}]
    header: [{name: Accept-Language, var: accept_language}]
    accept: ["application/hal+json"]
    ok: [200]
    auth: basic
  } {
    series_id: $series_id, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find all events for one series
#
# GET /series/{series_id}/events
# Returns: table<break_even: int, cancellation_date: string, contract: record<partner: record, type: record>, costing_capacity: int, creation_timestamp: int, currency: string, datetime: string, free: bool, general_sales_date: string, id: int, input_type: record<id: string, label: string>, label: string, last_update_timestamp: int, max_capacity: int, presales_date: string, series_id: int, sold_out_date: string, venue: record<alternative_labels: list, city: string, country_code: string, creation_timestamp: int, first_address: string, id: int, label: string, last_update_timestamp: int, major_city: string, second_address: string, type: record, zip_code: string>>
# operationId: fetchAllSeriesEvents
export def "fetch-all-series-events" [
  series_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --from-datetime: string # Find only the events starting after this date. (format: date)
  --to-datetime: string # Find only the events starting before this date. (format: date)
  --city: string # Find only the events whose venue city (or metropolitan area) contains this value.
  --sort: string@sort-completer-1 # Sort the events in the corresponding order. (default: label)
  --page-size: int # Pagination size, i.e. maximum number of items to be displayed in the response. (format: int32, default: 25)
  --accept-language: string@accept-language-completer # Language used for the translatable labels. (default: en)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/series/{series_id}/events"
    path_params: [{name: series_id, var: series_id}]
    query: [{name: from_datetime, var: from_datetime}, {name: to_datetime, var: to_datetime}, {name: city, var: city}, {name: sort, var: sort}, {name: page_size, var: page_size}]
    header: [{name: Accept-Language, var: accept_language}]
    accept: ["application/hal+json"]
    ok: [200]
    auth: basic
  } {
    series_id: $series_id, from_datetime: $from_datetime, to_datetime: $to_datetime, city: $city, sort: $sort, page_size: $page_size, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find all promotions for one series
#
# GET /series/{series_id}/promotions
# Returns: table<applied_to: list<record>, comments: string, cost: record<currency: string, exchange: string, quantity: float, state: record, type: record, unit_cost: float, valorized_quantity: float, valorized_unit_cost: float>, end_date: string, file: string, id: int, label: string, start_date: string, supplier: record<id: int, label: string>, type: record<family: record, id: string, label: string>>
# operationId: fetchAllSeriesPromotions
export def "fetch-all-series-promotions" [
  series_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --label: string # Find only the promotions whose label contains this value.
  --from-date: string # Find only the promotions starting after this date. (format: date)
  --to-date: string # Find only the promotions ending before this date. (format: date)
  --type: string # Find only the promotions whose type is equal to this value.
  --family: string # Find only the promotions whose family is equal to this value.
  --sort: string@sort-completer-3 # Sort the promotions in the corresponding order. (default: date)
  --page-size: int # Pagination size, i.e. maximum number of items to be displayed in the response. (format: int32, default: 25)
  --accept-language: string@accept-language-completer # Language used for the translatable labels. (default: en)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/series/{series_id}/promotions"
    path_params: [{name: series_id, var: series_id}]
    query: [{name: label, var: label}, {name: from_date, var: from_date}, {name: to_date, var: to_date}, {name: type, var: type}, {name: family, var: family}, {name: sort, var: sort}, {name: page_size, var: page_size}]
    header: [{name: Accept-Language, var: accept_language}]
    accept: ["application/hal+json"]
    ok: [200]
    auth: basic
  } {
    series_id: $series_id, label: $label, from_date: $from_date, to_date: $to_date, type: $type, family: $family, sort: $sort, page_size: $page_size, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find all venues
#
# GET /venues
# Returns: table<alternative_labels: list<string>, city: string, country_code: string, creation_timestamp: int, first_address: string, id: int, label: string, last_update_timestamp: int, major_city: string, second_address: string, type: record<id: string, label: string>, zip_code: string>
# operationId: fetchAllVenues
export def "fetch-all-venues" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --label: string # Find only the venues whose label contains this value.
  --city: string # Find only the venues whose city contains this value.
  --country-code: string # Find only the venues whose country_code is equal to this value.
  --type: string@type-completer-1 # Find only the venues whose type is equal to this value.
  --sort: string@sort-completer-5 # Sort the venues in the corresponding order. (default: label)
  --page-size: int # Pagination size, i.e. maximum number of items to be displayed in the response. (format: int32, default: 25)
  --accept-language: string@accept-language-completer # Language used for the translatable labels. (default: en)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/venues"
    query: [{name: label, var: label}, {name: city, var: city}, {name: country_code, var: country_code}, {name: type, var: type}, {name: sort, var: sort}, {name: page_size, var: page_size}]
    header: [{name: Accept-Language, var: accept_language}]
    accept: ["application/hal+json"]
    ok: [200]
    auth: basic
  } {
    label: $label, city: $city, country_code: $country_code, type: $type, sort: $sort, page_size: $page_size, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get one venue by ID
#
# GET /venues/{venue_id}
# Returns: record<alternative_labels: list<string>, city: string, country_code: string, creation_timestamp: int, first_address: string, id: int, label: string, last_update_timestamp: int, major_city: string, second_address: string, type: record<id: string, label: string>, zip_code: string>
# operationId: fetchOneVenue
export def "fetch-one-venue" [
  venue_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string@accept-language-completer # Language used for the translatable labels. (default: en)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/venues/{venue_id}"
    path_params: [{name: venue_id, var: venue_id}]
    header: [{name: Accept-Language, var: accept_language}]
    accept: ["application/hal+json"]
    ok: [200]
    auth: basic
  } {
    venue_id: $venue_id, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find all events for one venue
#
# GET /venues/{venue_id}/events
# Returns: table<break_even: int, cancellation_date: string, contract: record<partner: record, type: record>, costing_capacity: int, creation_timestamp: int, currency: string, datetime: string, free: bool, general_sales_date: string, id: int, input_type: record<id: string, label: string>, label: string, last_update_timestamp: int, max_capacity: int, presales_date: string, series_id: int, sold_out_date: string, venue: record<alternative_labels: list, city: string, country_code: string, creation_timestamp: int, first_address: string, id: int, label: string, last_update_timestamp: int, major_city: string, second_address: string, type: record, zip_code: string>>
# operationId: fetchAllVenuesEvents
export def "fetch-all-venues-events" [
  venue_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --from-datetime: string # Find only the events starting after this date. (format: date)
  --to-datetime: string # Find only the events starting before this date. (format: date)
  --city: string # Find only the events whose venue city (or metropolitan area) contains this value.
  --sort: string@sort-completer-1 # Sort the events in the corresponding order. (default: label)
  --page-size: int # Pagination size, i.e. maximum number of items to be displayed in the response. (format: int32, default: 25)
  --accept-language: string@accept-language-completer # Language used for the translatable labels. (default: en)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/venues/{venue_id}/events"
    path_params: [{name: venue_id, var: venue_id}]
    query: [{name: from_datetime, var: from_datetime}, {name: to_datetime, var: to_datetime}, {name: city, var: city}, {name: sort, var: sort}, {name: page_size, var: page_size}]
    header: [{name: Accept-Language, var: accept_language}]
    accept: ["application/hal+json"]
    ok: [200]
    auth: basic
  } {
    venue_id: $venue_id, from_datetime: $from_datetime, to_datetime: $to_datetime, city: $city, sort: $sort, page_size: $page_size, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
