# Auto-generated client for MIMIC REST API v21.00
# Source: https://api.apis.guru/v2/specs/gambitcomm.local/mimic/21.00/openapi.json
# Auth: --token flag or $env.MIMIC_REST_API_TOKEN

const CLIENT = {
  base_url: "http://gambitcomm.local"
  token_env_var: "MIMIC_REST_API_TOKEN"
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

def base-url-completer [] { ["http://gambitcomm.local" "http://127.0.0.1"] }
def auth-scheme-completer [] { ["basic" "basic-credentials"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    access-add: "string"
    access-del: "string"
    access-get-acldb: "string"
    access-get-admindir: "string"
    access-get-adminuser: "string"
    access-get-enabled: "string"
    access-list: "table<access_mask: string, agent_range: string, user: string>"
    access-load: "list<string>"
    access-save: "list<string>"
    access-set-acldb: "string"
    access-set-enabled: "string"
    new: "string"
    from-add: "string"
    from-del: "string"
    from-list: "table<IP: string, port: int>"
    get-changed: "int"
    get-config-changed: "int"
    get-delay: "int"
    get-drops: "int"
    get-host: "string"
    get-inform-timeout: "int"
    get-interface: "string"
    get-mask: "string"
    get-mibs: "table<device: string, mib: string, scenario: int>"
    get-number-starts: "int"
    get-oiddir: "string"
    get-owner: "string"
    get-pdusize: "int"
    get-port: "string"
    get-privdir: "string"
    get-protocols: "list<string>"
    get-read-community: "string"
    get-scen: "int"
    get-sim: "string"
    get-starttime: "string"
    get-agent-state: "int"
    get-state-changed: "int"
    get-statistics: "list<int>"
    get-trace: "int"
    get-validate: "int"
    get-write-community: "string"
    halt: "string"
    add-ipalias: "string"
    del-ipalias: "string"
    list-ipaliases: "table<IP: string, interface: string, mask: string, port: int>"
    start-ipalias: "string"
    status-ipalias: "string"
    stop-ipalias: "string"
    pause-now: "string"
    protocol-coap-get-args: "record"
    protocol-coap-get-config: "record<keystore: string, primary_port: int, rule: string, secure_port: int>"
    protocol-coap-get-statistics: "list<int>"
    protocol-coap-get-trace: "record<keystore: string, primary_port: int, rule: string, secure_port: int>"
    protocol-coap-set-config: "string"
    protocol-coap-set-trace: "string"
    protocol-dhcp-get-args: "record"
    protocol-dhcp-get-config: "record<add_options: string, classid: string, hwaddr: string, script: string>"
    protocol-dhcp-get-statistics: "list<int>"
    protocol-dhcp-get-trace: "record<add_options: string, classid: string, hwaddr: string, script: string>"
    protocol-dhcp-params: "list<record>"
    protocol-dhcp-set-config: "string"
    protocol-dhcp-set-trace: "string"
    protocol-ipmi-get-args: "record"
    protocol-ipmi-get-config: "record<primary_port: int, secure_port: int, version: string>"
    protocol-ipmi-get-statistics: "list<int>"
    protocol-ipmi-get-trace: "record<primary_port: int, secure_port: int, version: string>"
    protocol-ipmi-get-attr: "string"
    protocol-ipmi-set-config: "string"
    protocol-ipmi-set-trace: "string"
    protocol-ipmi-set-attr: "string"
    protocol-mqtt-client-get-protstate: "list<int>"
    protocol-mqtt-client-get-state: "list<int>"
    protocol-mqtt-client-message-card: "list<int>"
    protocol-mqtt-client-message-get: "list<string>"
    protocol-mqtt-client-message-set: "list<string>"
    protocol-mqtt-client-resubscribe: "string"
    protocol-mqtt-client-runtime-abort: "list<string>"
    protocol-mqtt-client-runtime-connect: "list<string>"
    protocol-mqtt-client-runtime-disconnect: "list<string>"
    protocol-mqtt-client-set-broker: "list<int>"
    protocol-mqtt-client-set-cleansession: "list<int>"
    protocol-mqtt-client-set-clientid: "list<int>"
    protocol-mqtt-client-set-keepalive: "list<int>"
    protocol-mqtt-client-set-on-disconnect: "list<int>"
    protocol-mqtt-client-set-password: "list<int>"
    protocol-mqtt-client-set-port: "list<int>"
    protocol-mqtt-client-set-username: "list<int>"
    protocol-mqtt-client-set-willmsg: "list<int>"
    protocol-mqtt-client-set-willqos: "list<int>"
    protocol-mqtt-client-set-willretain: "list<int>"
    protocol-mqtt-client-set-willtopic: "list<int>"
    protocol-mqtt-client-subscribe-card: "list<int>"
    protocol-mqtt-client-subscribe-get: "list<string>"
    protocol-mqtt-client-subscribe-set: "list<string>"
    protocol-mqtt-client-unsubscribe: "string"
    protocol-mqtt-get-args: "record"
    protocol-mqtt-get-config: "record<broker: string, clientid: string, filename: string, is_tls: string, password: string, port: int, tls_conf_filename: string, username: string, version: string>"
    protocol-mqtt-get-statistics: "list<int>"
    protocol-mqtt-get-trace: "record<broker: string, clientid: string, filename: string, is_tls: string, password: string, port: int, tls_conf_filename: string, username: string, version: string>"
    protocol-mqtt-set-config: "string"
    protocol-mqtt-set-trace: "string"
    protocol-netflow-change-dfs: "string"
    protocol-netflow-change-tfs: "string"
    protocol-netflow-change-attr: "string"
    protocol-netflow-list: "list<record>"
    protocol-netflow-get-args: "record"
    protocol-netflow-get-config: "record<bundleflowsets: int, collector: string, collectorport: int, filename: string>"
    protocol-netflow-get-statistics: "list<int>"
    protocol-netflow-get-trace: "record<bundleflowsets: int, collector: string, collectorport: int, filename: string>"
    protocol-netflow-halt: "string"
    protocol-netflow-reload: "string"
    protocol-netflow-resume: "string"
    protocol-netflow-set-collector: "string"
    protocol-netflow-set-config: "string"
    protocol-netflow-set-file-name: "string"
    protocol-netflow-set-trace: "string"
    protocol-proxy-get-args: "record"
    protocol-proxy-get-config: "record<TCP_NODELAY: int, client_to_server: string, disconnect_delay: int, max_connects: int, portno: int, pre_connect: string, server_to_client: string, target: string, transport: string>"
    protocol-proxy-get-statistics: "list<int>"
    protocol-proxy-get-trace: "record<TCP_NODELAY: int, client_to_server: string, disconnect_delay: int, max_connects: int, portno: int, pre_connect: string, server_to_client: string, target: string, transport: string>"
    protocol-proxy-port-add: "string"
    protocol-proxy-port-isstarted: "string"
    protocol-proxy-port-list: "list<int>"
    protocol-proxy-port-remove: "string"
    protocol-proxy-port-start: "string"
    protocol-proxy-port-stop: "string"
    protocol-proxy-set-config: "string"
    protocol-proxy-set-trace: "string"
    protocol-sflow-get-args: "record"
    protocol-sflow-get-config: "record<collector: string, collectorport: int, encoding_type: string, filename: string, flows_per_min: int, include_samples: string, records_per_sample: string, samples_per_datagram: string>"
    protocol-sflow-get-statistics: "list<int>"
    protocol-sflow-get-trace: "record<collector: string, collectorport: int, encoding_type: string, filename: string, flows_per_min: int, include_samples: string, records_per_sample: string, samples_per_datagram: string>"
    protocol-sflow-halt: "string"
    protocol-sflow-reload: "string"
    protocol-sflow-resume: "string"
    protocol-sflow-set-config: "string"
    protocol-sflow-set-trace: "string"
    protocol-snmptcp-get-args: "record"
    protocol-snmptcp-get-config: "record<connections: int>"
    protocol-snmptcp-get-statistics: "list<int>"
    protocol-snmptcp-get-trace: "record<connections: int>"
    protocol-snmptcp-ipalias-disable: "string"
    protocol-snmptcp-ipalias-enable: "string"
    protocol-snmptcp-ipalias-isenabled: "string"
    protocol-snmptcp-ipalias-list: "table<IP: string, interface: string, mask: string, port: int>"
    protocol-snmptcp-set-config: "string"
    protocol-snmptcp-set-trace: "string"
    protocol-snmpv3-access-add: "string"
    protocol-snmpv3-access-clear: "string"
    protocol-snmpv3-access-del: "string"
    protocol-snmpv3-access-list: "list<string>"
    protocol-snmpv3-get-config: "record<context_engine_id: string, engine_id: string, usm_db: string, vacm_db: string>"
    protocol-snmpv3-get-context-engineid: "string"
    protocol-snmpv3-get-engineboots: "int"
    protocol-snmpv3-get-engineid: "string"
    protocol-snmpv3-get-enginetime: "int"
    protocol-snmpv3-group-add: "string"
    protocol-snmpv3-group-clear: "string"
    protocol-snmpv3-group-del: "string"
    protocol-snmpv3-group-list: "list<string>"
    protocol-snmpv3-set-config: "string"
    protocol-snmpv3-user-add: "string"
    protocol-snmpv3-user-clear: "string"
    protocol-snmpv3-user-del: "string"
    protocol-snmpv3-user-list: "list<string>"
    protocol-snmpv3-usm-save: "list<string>"
    protocol-snmpv3-usm-saveas: "list<string>"
    protocol-snmpv3-vacm-save: "list<string>"
    protocol-snmpv3-vacm-saveas: "list<string>"
    protocol-snmpv3-view-add: "string"
    protocol-snmpv3-view-clear: "string"
    protocol-snmpv3-view-del: "string"
    protocol-snmpv3-view-list: "list<string>"
    protocol-ssh-get-args: "record"
    protocol-ssh-get-config: "record<port: int, version: string>"
    protocol-ssh-get-statistics: "list<int>"
    protocol-ssh-get-trace: "record<port: int, version: string>"
    protocol-ssh-ipalias-disable: "string"
    protocol-ssh-ipalias-enable: "string"
    protocol-ssh-ipalias-isenabled: "string"
    protocol-ssh-ipalias-list: "table<IP: string, interface: string, mask: string, port: int>"
    protocol-ssh-set-config: "string"
    protocol-ssh-set-trace: "string"
    protocol-syslog-get-args: "record"
    protocol-syslog-get-config: "record<client: string, hostname: string, localport: int, separator: string, sequence: int, server: string, serverport: int, timestamp: string>"
    protocol-syslog-get-statistics: "list<int>"
    protocol-syslog-get-trace: "record<client: string, hostname: string, localport: int, separator: string, sequence: int, server: string, serverport: int, timestamp: string>"
    protocol-syslog-get-attr: "string"
    protocol-syslog-send: "string"
    protocol-syslog-set-config: "string"
    protocol-syslog-set-trace: "string"
    protocol-syslog-set-attr: "string"
    protocol-telnet-connection-logon: "list<string>"
    protocol-telnet-connection-request: "list<string>"
    protocol-telnet-connection-signal: "list<string>"
    protocol-telnet-get-args: "record"
    protocol-telnet-get-config: "record<keymap: string, paging_prompt: string, port: int, prompt: string, rule: string, userdb: string>"
    protocol-telnet-get-statistics: "list<int>"
    protocol-telnet-get-trace: "record<keymap: string, paging_prompt: string, port: int, prompt: string, rule: string, userdb: string>"
    protocol-telnet-ipalias-disable: "string"
    protocol-telnet-ipalias-enable: "string"
    protocol-telnet-ipalias-isenabled: "string"
    protocol-telnet-ipalias-list: "table<IP: string, interface: string, mask: string, port: int>"
    protocol-telnet-server-get-connections: "list<int>"
    protocol-telnet-server-get-keymap: "list<string>"
    protocol-telnet-server-get-rulesdb: "list<string>"
    protocol-telnet-server-get-state: "list<int>"
    protocol-telnet-server-get-userdb: "list<string>"
    protocol-telnet-server-get-users: "table<groups: list<string>, hasPassword: int, password: string, username: string>"
    protocol-telnet-set-config: "string"
    protocol-telnet-set-trace: "string"
    protocol-tftp-get-args: "record"
    protocol-tftp-get-config: "record<cache: int, client: string, dstfile: string, mode: string, port: int, retries: int, script: string, server: string, srcfile: string, timeout: int, trace: string>"
    protocol-tftp-get-statistics: "list<int>"
    protocol-tftp-get-trace: "record<cache: int, client: string, dstfile: string, mode: string, port: int, retries: int, script: string, server: string, srcfile: string, timeout: int, trace: string>"
    protocol-tftp-session-read: "list<int>"
    protocol-tftp-session-write: "list<int>"
    protocol-tftp-set-config: "string"
    protocol-tftp-set-trace: "string"
    protocol-tftp-session-get-parameter: "string"
    protocol-tftp-session-set-parameter: "string"
    protocol-tftp-session-start: "string"
    protocol-tftp-session-status: "string"
    protocol-tftp-session-stop: "string"
    protocol-tod-get-args: "record"
    protocol-tod-get-config: "record<port: int, retries: int, script: string, server: string, timeout: int>"
    protocol-tod-get-statistics: "list<int>"
    protocol-tod-get-trace: "record<port: int, retries: int, script: string, server: string, timeout: int>"
    protocol-tod-gettime: "list<string>"
    protocol-tod-set-config: "string"
    protocol-tod-set-trace: "string"
    protocol-web-get-args: "record"
    protocol-web-get-config: "record<is_persistent_connections: int, password: string, port: int, rule: string, username: string, wsdl: string>"
    protocol-web-get-statistics: "list<int>"
    protocol-web-get-trace: "record<is_persistent_connections: int, password: string, port: int, rule: string, username: string, wsdl: string>"
    protocol-web-port-add: "string"
    protocol-web-port-exists: "list<string>"
    protocol-web-port-remove: "string"
    protocol-web-port-set: "string"
    protocol-web-port-start: "string"
    protocol-web-port-stop: "string"
    protocol-web-set-config: "string"
    protocol-web-set-trace: "string"
    protocol-get-config: "record"
    reload: "string"
    agent-remove: "string"
    resume: "string"
    put-mimic-agent-agent-num-save: "string"
    set-delay: "int"
    set-drops: "int"
    set-host: "string"
    set-inform-timeout: "int"
    set-interface: "string"
    set-mask: "string"
    set-mibs: "string"
    set-oiddir: "string"
    set-owner: "string"
    set-pdusize: "int"
    set-port: "string"
    set-privdir: "string"
    set-protocols: "list<int>"
    set-read-community: "string"
    set-starttime: "string"
    set-trace: "int"
    set-validate: "int"
    set-write-community: "string"
    put-mimic-agent-agent-num-start: "string"
    stop: "string"
    agent-store-copy: "string"
    agent-store-exists: "string"
    agent-store-get: "string"
    agent-store-list: "list<string>"
    agent-store-lreplace: "string"
    agent-store-persists: "string"
    agent-store-set: "string"
    agent-store-unset: "string"
    add-timer-script: "string"
    del-timer-script: "string"
    list-timer-scripts: "table<arg: string, interval: int, script: string>"
    trap-config-add: "string"
    trap-config-del: "string"
    trap-config-list: "table<IP: string, port: int>"
    trap-list: "list<string>"
    add: "string"
    eval-value: "string"
    get-value: "string"
    get-info: "string"
    get-instances: "list<string>"
    get-objects: "list<string>"
    meval-value: "list<string>"
    mget-value: "list<string>"
    get-mib: "string"
    mset-value: "string"
    munset-value: "string"
    get-name: "string"
    get-oid: "string"
    remove: "string"
    set-value: "string"
    split-oid: "list<string>"
    get-state: "string"
    set-state: "string"
    unset-value: "string"
    get-variables: "list<string>"
    cfg-new: "record"
    get-active-data-list: "list<int>"
    get-active-list: "list<int>"
    get-cfgfile: "record"
    get-cfg-file-changed: "record"
    get-changed-config-list: "list<int>"
    get-changed-state-list: "table<agentNum: int, state: int>"
    get-clients: "record"
    get-configured-list: "list<int>"
    get-interfaces: "record"
    get-last: "int"
    get-log: "record"
    get-max: "int"
    get-netaddr: "record"
    get-netdev: "record"
    get-product: "record"
    get-daemon-protocols: "record"
    get-return: "record"
    get-version: "string"
    cfg-load: "record"
    mget-info: "list<record>"
    protocol-coap-get-stats-hdr: "list<string>"
    protocol-dhcp-get-stats-hdr: "list<string>"
    protocol-ipmi-get-stats-hdr: "list<string>"
    protocol-mqtt-get-stats-hdr: "list<string>"
    protocol-netflow-get-stats-hdr: "list<string>"
    protocol-proxy-get-stats-hdr: "list<string>"
    protocol-sflow-get-stats-hdr: "list<string>"
    protocol-snmptcp-get-stats-hdr: "list<string>"
    protocol-ssh-get-stats-hdr: "list<string>"
    protocol-syslog-get-stats-hdr: "list<string>"
    protocol-telnet-get-stats-hdr: "list<string>"
    protocol-tftp-get-stats-hdr: "list<string>"
    protocol-tod-get-stats-hdr: "list<string>"
    protocol-web-get-stats-hdr: "list<string>"
    cfg-save: "record"
    cfg-saveas: "record"
    set-log: "string"
    set-netdev: "record"
    store-save: "record"
    start-all-agents: "record"
    stop-all-agents: "record"
    store-exists: "string"
    store-get: "string"
    store-list: "list<string>"
    store-lreplace: "string"
    store-persists: "string"
    store-set: "string"
    store-unset: "string"
    terminate: "record"
    add-daemon-timer-script: "string"
    del-daemon-timer-script: "string"
    list-daemon-timer-scripts: "table<arg: string, interval: int, script: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["access-add" "access-del" "access-get-acldb" "access-get-admindir" "access-get-adminuser" "access-get-enabled" "access-list" "access-load" "access-save" "access-set-acldb" "access-set-enabled" "new" "from-add" "from-del" "from-list" "get-changed" "get-config-changed" "get-delay" "get-drops" "get-host" "get-inform-timeout" "get-interface" "get-mask" "get-mibs" "get-number-starts" "get-oiddir" "get-owner" "get-pdusize" "get-port" "get-privdir" "get-protocols" "get-read-community" "get-scen" "get-sim" "get-starttime" "get-agent-state" "get-state-changed" "get-statistics" "get-trace" "get-validate" "get-write-community" "halt" "add-ipalias" "del-ipalias" "list-ipaliases" "start-ipalias" "status-ipalias" "stop-ipalias" "pause-now" "protocol-coap-get-args" "protocol-coap-get-config" "protocol-coap-get-statistics" "protocol-coap-get-trace" "protocol-coap-set-config" "protocol-coap-set-trace" "protocol-dhcp-get-args" "protocol-dhcp-get-config" "protocol-dhcp-get-statistics" "protocol-dhcp-get-trace" "protocol-dhcp-params" "protocol-dhcp-set-config" "protocol-dhcp-set-trace" "protocol-ipmi-get-args" "protocol-ipmi-get-config" "protocol-ipmi-get-statistics" "protocol-ipmi-get-trace" "protocol-ipmi-get-attr" "protocol-ipmi-set-config" "protocol-ipmi-set-trace" "protocol-ipmi-set-attr" "protocol-mqtt-client-get-protstate" "protocol-mqtt-client-get-state" "protocol-mqtt-client-message-card" "protocol-mqtt-client-message-get" "protocol-mqtt-client-message-set" "protocol-mqtt-client-resubscribe" "protocol-mqtt-client-runtime-abort" "protocol-mqtt-client-runtime-connect" "protocol-mqtt-client-runtime-disconnect" "protocol-mqtt-client-set-broker" "protocol-mqtt-client-set-cleansession" "protocol-mqtt-client-set-clientid" "protocol-mqtt-client-set-keepalive" "protocol-mqtt-client-set-on-disconnect" "protocol-mqtt-client-set-password" "protocol-mqtt-client-set-port" "protocol-mqtt-client-set-username" "protocol-mqtt-client-set-willmsg" "protocol-mqtt-client-set-willqos" "protocol-mqtt-client-set-willretain" "protocol-mqtt-client-set-willtopic" "protocol-mqtt-client-subscribe-card" "protocol-mqtt-client-subscribe-get" "protocol-mqtt-client-subscribe-set" "protocol-mqtt-client-unsubscribe" "protocol-mqtt-get-args" "protocol-mqtt-get-config" "protocol-mqtt-get-statistics" "protocol-mqtt-get-trace" "protocol-mqtt-set-config" "protocol-mqtt-set-trace" "protocol-netflow-change-dfs" "protocol-netflow-change-tfs" "protocol-netflow-change-attr" "protocol-netflow-list" "protocol-netflow-get-args" "protocol-netflow-get-config" "protocol-netflow-get-statistics" "protocol-netflow-get-trace" "protocol-netflow-halt" "protocol-netflow-reload" "protocol-netflow-resume" "protocol-netflow-set-collector" "protocol-netflow-set-config" "protocol-netflow-set-file-name" "protocol-netflow-set-trace" "protocol-proxy-get-args" "protocol-proxy-get-config" "protocol-proxy-get-statistics" "protocol-proxy-get-trace" "protocol-proxy-port-add" "protocol-proxy-port-isstarted" "protocol-proxy-port-list" "protocol-proxy-port-remove" "protocol-proxy-port-start" "protocol-proxy-port-stop" "protocol-proxy-set-config" "protocol-proxy-set-trace" "protocol-sflow-get-args" "protocol-sflow-get-config" "protocol-sflow-get-statistics" "protocol-sflow-get-trace" "protocol-sflow-halt" "protocol-sflow-reload" "protocol-sflow-resume" "protocol-sflow-set-config" "protocol-sflow-set-trace" "protocol-snmptcp-get-args" "protocol-snmptcp-get-config" "protocol-snmptcp-get-statistics" "protocol-snmptcp-get-trace" "protocol-snmptcp-ipalias-disable" "protocol-snmptcp-ipalias-enable" "protocol-snmptcp-ipalias-isenabled" "protocol-snmptcp-ipalias-list" "protocol-snmptcp-set-config" "protocol-snmptcp-set-trace" "protocol-snmpv3-access-add" "protocol-snmpv3-access-clear" "protocol-snmpv3-access-del" "protocol-snmpv3-access-list" "protocol-snmpv3-get-config" "protocol-snmpv3-get-context-engineid" "protocol-snmpv3-get-engineboots" "protocol-snmpv3-get-engineid" "protocol-snmpv3-get-enginetime" "protocol-snmpv3-group-add" "protocol-snmpv3-group-clear" "protocol-snmpv3-group-del" "protocol-snmpv3-group-list" "protocol-snmpv3-set-config" "protocol-snmpv3-user-add" "protocol-snmpv3-user-clear" "protocol-snmpv3-user-del" "protocol-snmpv3-user-list" "protocol-snmpv3-usm-save" "protocol-snmpv3-usm-saveas" "protocol-snmpv3-vacm-save" "protocol-snmpv3-vacm-saveas" "protocol-snmpv3-view-add" "protocol-snmpv3-view-clear" "protocol-snmpv3-view-del" "protocol-snmpv3-view-list" "protocol-ssh-get-args" "protocol-ssh-get-config" "protocol-ssh-get-statistics" "protocol-ssh-get-trace" "protocol-ssh-ipalias-disable" "protocol-ssh-ipalias-enable" "protocol-ssh-ipalias-isenabled" "protocol-ssh-ipalias-list" "protocol-ssh-set-config" "protocol-ssh-set-trace" "protocol-syslog-get-args" "protocol-syslog-get-config" "protocol-syslog-get-statistics" "protocol-syslog-get-trace" "protocol-syslog-get-attr" "protocol-syslog-send" "protocol-syslog-set-config" "protocol-syslog-set-trace" "protocol-syslog-set-attr" "protocol-telnet-connection-logon" "protocol-telnet-connection-request" "protocol-telnet-connection-signal" "protocol-telnet-get-args" "protocol-telnet-get-config" "protocol-telnet-get-statistics" "protocol-telnet-get-trace" "protocol-telnet-ipalias-disable" "protocol-telnet-ipalias-enable" "protocol-telnet-ipalias-isenabled" "protocol-telnet-ipalias-list" "protocol-telnet-server-get-connections" "protocol-telnet-server-get-keymap" "protocol-telnet-server-get-rulesdb" "protocol-telnet-server-get-state" "protocol-telnet-server-get-userdb" "protocol-telnet-server-get-users" "protocol-telnet-set-config" "protocol-telnet-set-trace" "protocol-tftp-get-args" "protocol-tftp-get-config" "protocol-tftp-get-statistics" "protocol-tftp-get-trace" "protocol-tftp-session-read" "protocol-tftp-session-write" "protocol-tftp-set-config" "protocol-tftp-set-trace" "protocol-tftp-session-get-parameter" "protocol-tftp-session-set-parameter" "protocol-tftp-session-start" "protocol-tftp-session-status" "protocol-tftp-session-stop" "protocol-tod-get-args" "protocol-tod-get-config" "protocol-tod-get-statistics" "protocol-tod-get-trace" "protocol-tod-gettime" "protocol-tod-set-config" "protocol-tod-set-trace" "protocol-web-get-args" "protocol-web-get-config" "protocol-web-get-statistics" "protocol-web-get-trace" "protocol-web-port-add" "protocol-web-port-exists" "protocol-web-port-remove" "protocol-web-port-set" "protocol-web-port-start" "protocol-web-port-stop" "protocol-web-set-config" "protocol-web-set-trace" "protocol-get-config" "reload" "agent-remove" "resume" "put-mimic-agent-agent-num-save" "set-delay" "set-drops" "set-host" "set-inform-timeout" "set-interface" "set-mask" "set-mibs" "set-oiddir" "set-owner" "set-pdusize" "set-port" "set-privdir" "set-protocols" "set-read-community" "set-starttime" "set-trace" "set-validate" "set-write-community" "put-mimic-agent-agent-num-start" "stop" "agent-store-copy" "agent-store-exists" "agent-store-get" "agent-store-list" "agent-store-lreplace" "agent-store-persists" "agent-store-set" "agent-store-unset" "add-timer-script" "del-timer-script" "list-timer-scripts" "trap-config-add" "trap-config-del" "trap-config-list" "trap-list" "add" "eval-value" "get-value" "get-info" "get-instances" "get-objects" "meval-value" "mget-value" "get-mib" "mset-value" "munset-value" "get-name" "get-oid" "remove" "set-value" "split-oid" "get-state" "set-state" "unset-value" "get-variables" "cfg-new" "get-active-data-list" "get-active-list" "get-cfgfile" "get-cfg-file-changed" "get-changed-config-list" "get-changed-state-list" "get-clients" "get-configured-list" "get-interfaces" "get-last" "get-log" "get-max" "get-netaddr" "get-netdev" "get-product" "get-daemon-protocols" "get-return" "get-version" "cfg-load" "mget-info" "protocol-coap-get-stats-hdr" "protocol-dhcp-get-stats-hdr" "protocol-ipmi-get-stats-hdr" "protocol-mqtt-get-stats-hdr" "protocol-netflow-get-stats-hdr" "protocol-proxy-get-stats-hdr" "protocol-sflow-get-stats-hdr" "protocol-snmptcp-get-stats-hdr" "protocol-ssh-get-stats-hdr" "protocol-syslog-get-stats-hdr" "protocol-telnet-get-stats-hdr" "protocol-tftp-get-stats-hdr" "protocol-tod-get-stats-hdr" "protocol-web-get-stats-hdr" "cfg-save" "cfg-saveas" "set-log" "set-netdev" "store-save" "start-all-agents" "stop-all-agents" "store-exists" "store-get" "store-list" "store-lreplace" "store-persists" "store-set" "store-unset" "terminate" "add-daemon-timer-script" "del-daemon-timer-script" "list-daemon-timer-scripts" "commands"] | sort) } | get name | first)
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

# Adds/Overwrites the user entry in the access control database.
#
# POST /mimic/access/add/{user}/{agents}/{mask}
# Returns: string
# operationId: access_add
export def "access-add" [
  user: string
  agents: string
  mask: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: post
    path: "/mimic/access/add/{user}/{agents}/{mask}"
    path_params: [{name: user, var: user}, {name: agents, var: agents}, {name: mask, var: mask}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    user: $user, agents: $agents, mask: $mask
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Clears a users entry from access control database.
#
# DELETE /mimic/access/del/{user}
# Returns: string
# operationId: access_del
export def "access-del" [
  user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/mimic/access/del/{user}"
    path_params: [{name: user, var: user}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    user: $user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the current access control database in use.
#
# GET /mimic/access/get/acldb
# Returns: string
# operationId: access_get_acldb
export def "access-get-acldb" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/mimic/access/get/acldb"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the current admin directory.
#
# GET /mimic/access/get/admindir
# Returns: string
# operationId: access_get_admindir
export def "access-get-admindir" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/mimic/access/get/admindir"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the current administrator.
#
# GET /mimic/access/get/adminuser
# Returns: string
# operationId: access_get_adminuser
export def "access-get-adminuser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/mimic/access/get/adminuser"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the state of access control checking.
#
# GET /mimic/access/get/enabled
# Returns: string
# operationId: access_get_enabled
export def "access-get-enabled" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/mimic/access/get/enabled"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns an array of entries.
#
# GET /mimic/access/list
# Returns: table<access_mask: string, agent_range: string, user: string>
# operationId: access_list
export def "access-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/access/list"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Loads the specified file for access control data.
#
# PUT /mimic/access/load/{filename}
# Returns: list<string>
# operationId: access_load
export def "access-load" [
  filename: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: put
    path: "/mimic/access/load/{filename}"
    path_params: [{name: filename, var: filename}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    filename: $filename
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Saves current access control data in specified file.
#
# PUT /mimic/access/save/{filename}
# Returns: list<string>
# operationId: access_save
export def "access-save" [
  filename: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: put
    path: "/mimic/access/save/{filename}"
    path_params: [{name: filename, var: filename}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    filename: $filename
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Allows setting the name of the current access control database.
#
# PUT /mimic/access/set/acldb/{databaseName}
# Returns: string
# operationId: access_set_acldb
export def "access-set-acldb" [
  database_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/access/set/acldb/{databaseName}"
    path_params: [{name: databaseName, var: database_name}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    database_name: $database_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Allows the user to enable/disable the access control check.
#
# PUT /mimic/access/set/enabled/{enabledOrNot}
# Returns: string
# operationId: access_set_enabled
export def "access-set-enabled" [
  enabled_or_not: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/access/set/enabled/{enabledOrNot}"
    path_params: [{name: enabledOrNot, var: enabled_or_not}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    enabled_or_not: $enabled_or_not
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add an agent.
#
# POST /mimic/agent/{agentNum}/add/{IP}
# Returns: string
# operationId: new
export def "new" [
  agent_num: int
  ip: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> any {
  $in | http-request {
    method: post
    path: "/mimic/agent/{agentNum}/add/{IP}"
    path_params: [{name: agentNum, var: agent_num}, {name: IP, var: ip}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, ip: $ip, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a source address that the agent will accept messages from.
#
# POST /mimic/agent/{agentNum}/from/add/{IP}/{port}
# Returns: string
# operationId: from_add
export def "from-add" [
  agent_num: int
  ip: string
  port: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: post
    path: "/mimic/agent/{agentNum}/from/add/{IP}/{port}"
    path_params: [{name: agentNum, var: agent_num}, {name: IP, var: ip}, {name: port, var: port}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, ip: $ip, port: $port
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# delete a source address that the agent will accept messages from.
#
# DELETE /mimic/agent/{agentNum}/from/delete/{IP}/{port}
# Returns: string
# operationId: from_del
export def "from-del" [
  agent_num: int
  ip: string
  port: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/mimic/agent/{agentNum}/from/delete/{IP}/{port}"
    path_params: [{name: agentNum, var: agent_num}, {name: IP, var: ip}, {name: port, var: port}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, ip: $ip, port: $port
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the source addresses that the agent will accept messages from.
#
# GET /mimic/agent/{agentNum}/from/list
# Returns: table<IP: string, port: int>
# operationId: from_list
export def "from-list" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/from/list"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# has the agent value space changed?
#
# GET /mimic/agent/{agentNum}/get/changed
# Returns: int
# operationId: get_changed
export def "get-changed" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/get/changed"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# has the lab configuration changed?
#
# GET /mimic/agent/{agentNum}/get/config_changed
# Returns: int
# operationId: get_config_changed
export def "get-config-changed" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/get/config_changed"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# one-way transit delay in msec.
#
# GET /mimic/agent/{agentNum}/get/delay
# Returns: int
# operationId: get_delay
export def "get-delay" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/get/delay"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# drop rate (every N-th PDU). 0 means no drops.
#
# GET /mimic/agent/{agentNum}/get/drops
# Returns: int
# operationId: get_drops
export def "get-drops" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/get/drops"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# host address of the agent.
#
# GET /mimic/agent/{agentNum}/get/host
# Returns: string
# operationId: get_host
export def "get-host" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/get/host"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# timeout in seconds for retransmitting INFORM PDUs.
#
# GET /mimic/agent/{agentNum}/get/inform_timeout
# Returns: int
# operationId: get_inform_timeout
export def "get-inform-timeout" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/get/inform_timeout"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# network interface card for the agent.
#
# GET /mimic/agent/{agentNum}/get/interface
# Returns: string
# operationId: get_interface
export def "get-interface" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/get/interface"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# subnet mask of the agent.
#
# GET /mimic/agent/{agentNum}/get/mask
# Returns: string
# operationId: get_mask
export def "get-mask" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/get/mask"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# set of MIBs, simulations and scenarios
#
# GET /mimic/agent/{agentNum}/get/mibs
# Returns: table<device: string, mib: string, scenario: int>
# operationId: get_mibs
export def "get-mibs" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/get/mibs"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# number of starts for the agent.
#
# GET /mimic/agent/{agentNum}/get/num_starts
# Returns: int
# operationId: get_number_starts
export def "get-number-starts" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/get/num_starts"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# MIB directory of the agent.
#
# GET /mimic/agent/{agentNum}/get/oiddir
# Returns: string
# operationId: get_oiddir
export def "get-oiddir" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/get/oiddir"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# owner of the agent.
#
# GET /mimic/agent/{agentNum}/get/owner
# Returns: string
# operationId: get_owner
export def "get-owner" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/get/owner"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# maximum PDU size.
#
# GET /mimic/agent/{agentNum}/get/pdusize
# Returns: int
# operationId: get_pdusize
export def "get-pdusize" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/get/pdusize"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# port number
#
# GET /mimic/agent/{agentNum}/get/port
# Returns: string
# operationId: get_port
export def "get-port" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/get/port"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# private directory of the agent.
#
# GET /mimic/agent/{agentNum}/get/privdir
# Returns: string
# operationId: get_privdir
export def "get-privdir" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/get/privdir"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# protocols supported by agent
#
# GET /mimic/agent/{agentNum}/get/protocol
# Returns: list<string>
# operationId: get_protocols
export def "get-protocols" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/get/protocol"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# read community string
#
# GET /mimic/agent/{agentNum}/get/read
# Returns: string
# operationId: get_read_community
export def "get-read-community" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/get/read"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# first scenario name
#
# GET /mimic/agent/{agentNum}/get/scen
# Returns: int
# operationId: get_scen
export def "get-scen" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/get/scen"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# first simulation name
#
# GET /mimic/agent/{agentNum}/get/sim
# Returns: string
# operationId: get_sim
export def "get-sim" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/get/sim"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# relative start time
#
# GET /mimic/agent/{agentNum}/get/start
# Returns: string
# operationId: get_starttime
export def "get-starttime" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/get/start"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# current running state of the agent
#
# GET /mimic/agent/{agentNum}/get/state
# Returns: int
# operationId: get_agent_state
export def "get-agent-state" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/get/state"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# has the agent state changed?
#
# GET /mimic/agent/{agentNum}/get/state_changed
# Returns: int
# operationId: get_state_changed
export def "get-state-changed" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/get/state_changed"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# current statistics of the agent instance
#
# GET /mimic/agent/{agentNum}/get/statistics
# Returns: list<int>
# operationId: get_statistics
export def "get-statistics" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/get/statistics"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# SNMP PDU tracing
#
# GET /mimic/agent/{agentNum}/get/trace
# Returns: int
# operationId: get_trace
export def "get-trace" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/get/trace"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# SNMP SET validation policy.
#
# GET /mimic/agent/{agentNum}/get/validate
# Returns: int
# operationId: get_validate
export def "get-validate" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/get/validate"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# write community string
#
# GET /mimic/agent/{agentNum}/get/write
# Returns: string
# operationId: get_write_community
export def "get-write-community" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/get/write"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Halt the current agent.
#
# PUT /mimic/agent/{agentNum}/halt
# Returns: string
# operationId: halt
export def "halt" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/halt"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a new ipalias for the agent.
#
# POST /mimic/agent/{agentNum}/ipalias/add/{IP}/{port}/{mask}/{interface}
# Returns: string
# operationId: add_ipalias
export def "add-ipalias" [
  agent_num: int
  ip: string
  port: int
  mask: string
  interface: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: post
    path: "/mimic/agent/{agentNum}/ipalias/add/{IP}/{port}/{mask}/{interface}"
    path_params: [{name: agentNum, var: agent_num}, {name: IP, var: ip}, {name: port, var: port}, {name: mask, var: mask}, {name: interface, var: interface}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, ip: $ip, port: $port, mask: $mask, interface: $interface
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an existing ipalias from the agent.
#
# DELETE /mimic/agent/{agentNum}/ipalias/delete/{IP}/{port}
# Returns: string
# operationId: del_ipalias
export def "del-ipalias" [
  agent_num: int
  ip: string
  port: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/mimic/agent/{agentNum}/ipalias/delete/{IP}/{port}"
    path_params: [{name: agentNum, var: agent_num}, {name: IP, var: ip}, {name: port, var: port}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, ip: $ip, port: $port
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all the additional ipaliases configured for the agent.
#
# GET /mimic/agent/{agentNum}/ipalias/list
# Returns: table<IP: string, interface: string, mask: string, port: int>
# operationId: list_ipaliases
export def "list-ipaliases" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/ipalias/list"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts an existing ipalias for the agent.
#
# PUT /mimic/agent/{agentNum}/ipalias/start/{IP}/{port}
# Returns: string
# operationId: start_ipalias
export def "start-ipalias" [
  agent_num: int
  ip: string
  port: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/ipalias/start/{IP}/{port}"
    path_params: [{name: agentNum, var: agent_num}, {name: IP, var: ip}, {name: port, var: port}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, ip: $ip, port: $port
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the status (0=down, 1=up) of an existing ipalias for the agent.
#
# GET /mimic/agent/{agentNum}/ipalias/status/{IP}/{port}
# Returns: string
# operationId: status_ipalias
export def "status-ipalias" [
  agent_num: int
  ip: string
  port: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/ipalias/status/{IP}/{port}"
    path_params: [{name: agentNum, var: agent_num}, {name: IP, var: ip}, {name: port, var: port}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, ip: $ip, port: $port
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stops an existing ipalias for the agent.
#
# PUT /mimic/agent/{agentNum}/ipalias/stop/{IP}/{port}
# Returns: string
# operationId: stop_ipalias
export def "stop-ipalias" [
  agent_num: int
  ip: string
  port: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/ipalias/stop/{IP}/{port}"
    path_params: [{name: agentNum, var: agent_num}, {name: IP, var: ip}, {name: port, var: port}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, ip: $ip, port: $port
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Pause the current agent.
#
# PUT /mimic/agent/{agentNum}/pause
# Returns: string
# operationId: pause_now
export def "pause-now" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/pause"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the agent's COAP argument structure
#
# GET /mimic/agent/{agentNum}/protocol/msg/coap/get/args
# Returns: record
# operationId: protocol_coap_get_args
export def "protocol-coap-get-args" [
  agent_num: int
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
    path: "/mimic/agent/{agentNum}/protocol/msg/coap/get/args"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the agent's COAP configuration
#
# GET /mimic/agent/{agentNum}/protocol/msg/coap/get/config
# Returns: record<keystore: string, primary_port: int, rule: string, secure_port: int>
# operationId: protocol_coap_get_config
export def "protocol-coap-get-config" [
  agent_num: int
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
    path: "/mimic/agent/{agentNum}/protocol/msg/coap/get/config"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the agent's COAP statistics
#
# GET /mimic/agent/{agentNum}/protocol/msg/coap/get/statistics
# Returns: list<int>
# operationId: protocol_coap_get_statistics
export def "protocol-coap-get-statistics" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/protocol/msg/coap/get/statistics"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the agent's COAP traffic tracing
#
# GET /mimic/agent/{agentNum}/protocol/msg/coap/get/trace
# Returns: record<keystore: string, primary_port: int, rule: string, secure_port: int>
# operationId: protocol_coap_get_trace
export def "protocol-coap-get-trace" [
  agent_num: int
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
    path: "/mimic/agent/{agentNum}/protocol/msg/coap/get/trace"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the agent's COAP configuration
#
# PUT /mimic/agent/{agentNum}/protocol/msg/coap/set/config/{argument}/{value}
# Returns: string
# operationId: protocol_coap_set_config
export def "protocol-coap-set-config" [
  agent_num: int
  argument: string
  value: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/coap/set/config/{argument}/{value}"
    path_params: [{name: agentNum, var: agent_num}, {name: argument, var: argument}, {name: value, var: value}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, argument: $argument, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the agent's COAP traffic tracing
#
# PUT /mimic/agent/{agentNum}/protocol/msg/coap/set/trace/{enableOrNot}
# Returns: string
# operationId: protocol_coap_set_trace
export def "protocol-coap-set-trace" [
  agent_num: int
  enable_or_not: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/coap/set/trace/{enableOrNot}"
    path_params: [{name: agentNum, var: agent_num}, {name: enableOrNot, var: enable_or_not}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, enable_or_not: $enable_or_not
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the agent's DHCP argument structure
#
# GET /mimic/agent/{agentNum}/protocol/msg/dhcp/get/args
# Returns: record
# operationId: protocol_dhcp_get_args
export def "protocol-dhcp-get-args" [
  agent_num: int
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
    path: "/mimic/agent/{agentNum}/protocol/msg/dhcp/get/args"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the agent's DHCP configuration
#
# GET /mimic/agent/{agentNum}/protocol/msg/dhcp/get/config
# Returns: record<add_options: string, classid: string, hwaddr: string, script: string>
# operationId: protocol_dhcp_get_config
export def "protocol-dhcp-get-config" [
  agent_num: int
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
    path: "/mimic/agent/{agentNum}/protocol/msg/dhcp/get/config"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the agent's DHCP statistics
#
# GET /mimic/agent/{agentNum}/protocol/msg/dhcp/get/statistics
# Returns: list<int>
# operationId: protocol_dhcp_get_statistics
export def "protocol-dhcp-get-statistics" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/protocol/msg/dhcp/get/statistics"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the agent's DHCP traffic tracing
#
# GET /mimic/agent/{agentNum}/protocol/msg/dhcp/get/trace
# Returns: record<add_options: string, classid: string, hwaddr: string, script: string>
# operationId: protocol_dhcp_get_trace
export def "protocol-dhcp-get-trace" [
  agent_num: int
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
    path: "/mimic/agent/{agentNum}/protocol/msg/dhcp/get/trace"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the parameters configured by the server in its DHCP-OFFER message
#
# GET /mimic/agent/{agentNum}/protocol/msg/dhcp/params
# Returns: list<record>
# operationId: protocol_dhcp_params
export def "protocol-dhcp-params" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/protocol/msg/dhcp/params"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the agent's DHCP configuration
#
# PUT /mimic/agent/{agentNum}/protocol/msg/dhcp/set/config/{argument}/{value}
# Returns: string
# operationId: protocol_dhcp_set_config
export def "protocol-dhcp-set-config" [
  agent_num: int
  argument: string
  value: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/dhcp/set/config/{argument}/{value}"
    path_params: [{name: agentNum, var: agent_num}, {name: argument, var: argument}, {name: value, var: value}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, argument: $argument, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the agent's DHCP traffic tracing
#
# PUT /mimic/agent/{agentNum}/protocol/msg/dhcp/set/trace/{enableOrNot}
# Returns: string
# operationId: protocol_dhcp_set_trace
export def "protocol-dhcp-set-trace" [
  agent_num: int
  enable_or_not: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/dhcp/set/trace/{enableOrNot}"
    path_params: [{name: agentNum, var: agent_num}, {name: enableOrNot, var: enable_or_not}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, enable_or_not: $enable_or_not
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the agent's IPMI argument structure
#
# GET /mimic/agent/{agentNum}/protocol/msg/ipmi/get/args
# Returns: record
# operationId: protocol_ipmi_get_args
export def "protocol-ipmi-get-args" [
  agent_num: int
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
    path: "/mimic/agent/{agentNum}/protocol/msg/ipmi/get/args"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the agent's IPMI configuration
#
# GET /mimic/agent/{agentNum}/protocol/msg/ipmi/get/config
# Returns: record<primary_port: int, secure_port: int, version: string>
# operationId: protocol_ipmi_get_config
export def "protocol-ipmi-get-config" [
  agent_num: int
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
    path: "/mimic/agent/{agentNum}/protocol/msg/ipmi/get/config"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the agent's IPMI statistics
#
# GET /mimic/agent/{agentNum}/protocol/msg/ipmi/get/statistics
# Returns: list<int>
# operationId: protocol_ipmi_get_statistics
export def "protocol-ipmi-get-statistics" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/protocol/msg/ipmi/get/statistics"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the agent's IPMI traffic tracing
#
# GET /mimic/agent/{agentNum}/protocol/msg/ipmi/get/trace
# Returns: record<primary_port: int, secure_port: int, version: string>
# operationId: protocol_ipmi_get_trace
export def "protocol-ipmi-get-trace" [
  agent_num: int
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
    path: "/mimic/agent/{agentNum}/protocol/msg/ipmi/get/trace"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the outgoing message's attributes
#
# GET /mimic/agent/{agentNum}/protocol/msg/ipmi/get/{attr}
# Returns: string
# operationId: protocol_ipmi_get_attr
export def "protocol-ipmi-get-attr" [
  agent_num: int
  attr: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/protocol/msg/ipmi/get/{attr}"
    path_params: [{name: agentNum, var: agent_num}, {name: attr, var: attr}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, attr: $attr
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the agent's IPMI configuration
#
# PUT /mimic/agent/{agentNum}/protocol/msg/ipmi/set/config/{argument}/{value}
# Returns: string
# operationId: protocol_ipmi_set_config
export def "protocol-ipmi-set-config" [
  agent_num: int
  argument: string
  value: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/ipmi/set/config/{argument}/{value}"
    path_params: [{name: agentNum, var: agent_num}, {name: argument, var: argument}, {name: value, var: value}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, argument: $argument, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the agent's IPMI traffic tracing
#
# PUT /mimic/agent/{agentNum}/protocol/msg/ipmi/set/trace/{enableOrNot}
# Returns: string
# operationId: protocol_ipmi_set_trace
export def "protocol-ipmi-set-trace" [
  agent_num: int
  enable_or_not: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/ipmi/set/trace/{enableOrNot}"
    path_params: [{name: agentNum, var: agent_num}, {name: enableOrNot, var: enable_or_not}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, enable_or_not: $enable_or_not
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the outgoing message's attributes
#
# PUT /mimic/agent/{agentNum}/protocol/msg/ipmi/set/{attr}/{value}
# Returns: string
# operationId: protocol_ipmi_set_attr
export def "protocol-ipmi-set-attr" [
  agent_num: int
  attr: string
  value: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/ipmi/set/{attr}/{value}"
    path_params: [{name: agentNum, var: agent_num}, {name: attr, var: attr}, {name: value, var: value}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, attr: $attr, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the agent's MQTT TCP connection state
#
# GET /mimic/agent/{agentNum}/protocol/msg/mqtt/client/get/protstate
# Returns: list<int>
# operationId: protocol_mqtt_client_get_protstate
export def "protocol-mqtt-client-get-protstate" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/protocol/msg/mqtt/client/get/protstate"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the agent's MQTT state
#
# GET /mimic/agent/{agentNum}/protocol/msg/mqtt/client/get/state
# Returns: list<int>
# operationId: protocol_mqtt_client_get_state
export def "protocol-mqtt-client-get-state" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/protocol/msg/mqtt/client/get/state"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the agent's current messages' cardinality
#
# GET /mimic/agent/{agentNum}/protocol/msg/mqtt/client/message/card
# Returns: list<int>
# operationId: protocol_mqtt_client_message_card
export def "protocol-mqtt-client-message-card" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/protocol/msg/mqtt/client/message/card"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the agent's message attributes
#
# GET /mimic/agent/{agentNum}/protocol/msg/mqtt/client/message/get/{msgNum}/{attr}
# Returns: list<string>
# operationId: protocol_mqtt_client_message_get
export def "protocol-mqtt-client-message-get" [
  agent_num: int
  msg_num: int
  attr: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/protocol/msg/mqtt/client/message/get/{msgNum}/{attr}"
    path_params: [{name: agentNum, var: agent_num}, {name: msgNum, var: msg_num}, {name: attr, var: attr}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, msg_num: $msg_num, attr: $attr
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the agent's message attributes
#
# PUT /mimic/agent/{agentNum}/protocol/msg/mqtt/client/message/set/{msgNum}/{attr}/{value}
# Returns: list<string>
# operationId: protocol_mqtt_client_message_set
export def "protocol-mqtt-client-message-set" [
  agent_num: int
  msg_num: int
  attr: string
  value: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/mqtt/client/message/set/{msgNum}/{attr}/{value}"
    path_params: [{name: agentNum, var: agent_num}, {name: msgNum, var: msg_num}, {name: attr, var: attr}, {name: value, var: value}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, msg_num: $msg_num, attr: $attr, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Restart receiving messages from a subcription of the agent
#
# PUT /mimic/agent/{agentNum}/protocol/msg/mqtt/client/resubscribe/{subNum}
# Returns: string
# operationId: protocol_mqtt_client_resubscribe
export def "protocol-mqtt-client-resubscribe" [
  agent_num: int
  sub_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/mqtt/client/resubscribe/{subNum}"
    path_params: [{name: agentNum, var: agent_num}, {name: subNum, var: sub_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, sub_num: $sub_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Abort agent's MQTT TCP session without sending DISCONNECT command
#
# PUT /mimic/agent/{agentNum}/protocol/msg/mqtt/client/runtime/abort
# Returns: list<string>
# operationId: protocol_mqtt_client_runtime_abort
export def "protocol-mqtt-client-runtime-abort" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/mqtt/client/runtime/abort"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Start agent's MQTT TCP session
#
# PUT /mimic/agent/{agentNum}/protocol/msg/mqtt/client/runtime/connect
# Returns: list<string>
# operationId: protocol_mqtt_client_runtime_connect
export def "protocol-mqtt-client-runtime-connect" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/mqtt/client/runtime/connect"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disconnect agent's MQTT TCP session by sending DISCONNECT command
#
# PUT /mimic/agent/{agentNum}/protocol/msg/mqtt/client/runtime/disconnect
# Returns: list<string>
# operationId: protocol_mqtt_client_runtime_disconnect
export def "protocol-mqtt-client-runtime-disconnect" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/mqtt/client/runtime/disconnect"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the agent's MQTT TCP connection target broker
#
# PUT /mimic/agent/{agentNum}/protocol/msg/mqtt/client/set/broker/{brokerAddr}
# Returns: list<int>
# operationId: protocol_mqtt_client_set_broker
export def "protocol-mqtt-client-set-broker" [
  agent_num: int
  broker_addr: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/mqtt/client/set/broker/{brokerAddr}"
    path_params: [{name: agentNum, var: agent_num}, {name: brokerAddr, var: broker_addr}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, broker_addr: $broker_addr
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the agent's MQTT session
#
# PUT /mimic/agent/{agentNum}/protocol/msg/mqtt/client/set/cleansession/{cleanOrNot}
# Returns: list<int>
# operationId: protocol_mqtt_client_set_cleansession
export def "protocol-mqtt-client-set-cleansession" [
  agent_num: int
  clean_or_not: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/mqtt/client/set/cleansession/{cleanOrNot}"
    path_params: [{name: agentNum, var: agent_num}, {name: cleanOrNot, var: clean_or_not}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, clean_or_not: $clean_or_not
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the agent's MQTT client ID
#
# PUT /mimic/agent/{agentNum}/protocol/msg/mqtt/client/set/clientid/{clientID}
# Returns: list<int>
# operationId: protocol_mqtt_client_set_clientid
export def "protocol-mqtt-client-set-clientid" [
  agent_num: int
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/mqtt/client/set/clientid/{clientID}"
    path_params: [{name: agentNum, var: agent_num}, {name: clientID, var: client_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, client_id: $client_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the agent's MQTT TCP keepalive
#
# PUT /mimic/agent/{agentNum}/protocol/msg/mqtt/client/set/keepalive/{aliveTime}
# Returns: list<int>
# operationId: protocol_mqtt_client_set_keepalive
export def "protocol-mqtt-client-set-keepalive" [
  agent_num: int
  alive_time: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/mqtt/client/set/keepalive/{aliveTime}"
    path_params: [{name: agentNum, var: agent_num}, {name: aliveTime, var: alive_time}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, alive_time: $alive_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the agent's MQTT disconnection action
#
# PUT /mimic/agent/{agentNum}/protocol/msg/mqtt/client/set/on_disconnect/{action}
# Returns: list<int>
# operationId: protocol_mqtt_client_set_on_disconnect
export def "protocol-mqtt-client-set-on-disconnect" [
  agent_num: int
  action: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/mqtt/client/set/on_disconnect/{action}"
    path_params: [{name: agentNum, var: agent_num}, {name: action, var: action}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, action: $action
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the agent's MQTT client password
#
# PUT /mimic/agent/{agentNum}/protocol/msg/mqtt/client/set/password/{password}
# Returns: list<int>
# operationId: protocol_mqtt_client_set_password
export def "protocol-mqtt-client-set-password" [
  agent_num: int
  password: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/mqtt/client/set/password/{password}"
    path_params: [{name: agentNum, var: agent_num}, {name: password, var: password}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, password: $password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the agent's MQTT TCP connection target port
#
# PUT /mimic/agent/{agentNum}/protocol/msg/mqtt/client/set/port/{port}
# Returns: list<int>
# operationId: protocol_mqtt_client_set_port
export def "protocol-mqtt-client-set-port" [
  agent_num: int
  port: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/mqtt/client/set/port/{port}"
    path_params: [{name: agentNum, var: agent_num}, {name: port, var: port}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, port: $port
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the agent's MQTT client username
#
# PUT /mimic/agent/{agentNum}/protocol/msg/mqtt/client/set/username/{username}
# Returns: list<int>
# operationId: protocol_mqtt_client_set_username
export def "protocol-mqtt-client-set-username" [
  agent_num: int
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/mqtt/client/set/username/{username}"
    path_params: [{name: agentNum, var: agent_num}, {name: username, var: username}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the agent's MQTT client's will
#
# PUT /mimic/agent/{agentNum}/protocol/msg/mqtt/client/set/willmsg/{msg}
# Returns: list<int>
# operationId: protocol_mqtt_client_set_willmsg
export def "protocol-mqtt-client-set-willmsg" [
  agent_num: int
  msg: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/mqtt/client/set/willmsg/{msg}"
    path_params: [{name: agentNum, var: agent_num}, {name: msg, var: msg}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, msg: $msg
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the agent's MQTT will message's QOS field
#
# PUT /mimic/agent/{agentNum}/protocol/msg/mqtt/client/set/willqos/{qos}
# Returns: list<int>
# operationId: protocol_mqtt_client_set_willqos
export def "protocol-mqtt-client-set-willqos" [
  agent_num: int
  qos: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/mqtt/client/set/willqos/{qos}"
    path_params: [{name: agentNum, var: agent_num}, {name: qos, var: qos}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, qos: $qos
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the agent's MQTT retained will
#
# PUT /mimic/agent/{agentNum}/protocol/msg/mqtt/client/set/willretain/{retain}
# Returns: list<int>
# operationId: protocol_mqtt_client_set_willretain
export def "protocol-mqtt-client-set-willretain" [
  agent_num: int
  retain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/mqtt/client/set/willretain/{retain}"
    path_params: [{name: agentNum, var: agent_num}, {name: retain, var: retain}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, retain: $retain
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the agent's MQTT client will's topic
#
# PUT /mimic/agent/{agentNum}/protocol/msg/mqtt/client/set/willtopic/{topic}
# Returns: list<int>
# operationId: protocol_mqtt_client_set_willtopic
export def "protocol-mqtt-client-set-willtopic" [
  agent_num: int
  topic: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/mqtt/client/set/willtopic/{topic}"
    path_params: [{name: agentNum, var: agent_num}, {name: topic, var: topic}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, topic: $topic
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the agent's current subscriptions' cardinality
#
# GET /mimic/agent/{agentNum}/protocol/msg/mqtt/client/subscribe/card
# Returns: list<int>
# operationId: protocol_mqtt_client_subscribe_card
export def "protocol-mqtt-client-subscribe-card" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/protocol/msg/mqtt/client/subscribe/card"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the agent's subscription attributes
#
# GET /mimic/agent/{agentNum}/protocol/msg/mqtt/client/subscribe/get/{subNum}/{attr}
# Returns: list<string>
# operationId: protocol_mqtt_client_subscribe_get
export def "protocol-mqtt-client-subscribe-get" [
  agent_num: int
  sub_num: int
  attr: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/protocol/msg/mqtt/client/subscribe/get/{subNum}/{attr}"
    path_params: [{name: agentNum, var: agent_num}, {name: subNum, var: sub_num}, {name: attr, var: attr}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, sub_num: $sub_num, attr: $attr
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the agent's subscribe attributes
#
# PUT /mimic/agent/{agentNum}/protocol/msg/mqtt/client/subscribe/set/{subNum}/{attr}/{value}
# Returns: list<string>
# operationId: protocol_mqtt_client_subscribe_set
export def "protocol-mqtt-client-subscribe-set" [
  agent_num: int
  sub_num: int
  attr: string
  value: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/mqtt/client/subscribe/set/{subNum}/{attr}/{value}"
    path_params: [{name: agentNum, var: agent_num}, {name: subNum, var: sub_num}, {name: attr, var: attr}, {name: value, var: value}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, sub_num: $sub_num, attr: $attr, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stops receiving messages from a subcription of the agent
#
# PUT /mimic/agent/{agentNum}/protocol/msg/mqtt/client/unsubscribe/{subNum}
# Returns: string
# operationId: protocol_mqtt_client_unsubscribe
export def "protocol-mqtt-client-unsubscribe" [
  agent_num: int
  sub_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/mqtt/client/unsubscribe/{subNum}"
    path_params: [{name: agentNum, var: agent_num}, {name: subNum, var: sub_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, sub_num: $sub_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the agent's MQTT argument structure
#
# GET /mimic/agent/{agentNum}/protocol/msg/mqtt/get/args
# Returns: record
# operationId: protocol_mqtt_get_args
export def "protocol-mqtt-get-args" [
  agent_num: int
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
    path: "/mimic/agent/{agentNum}/protocol/msg/mqtt/get/args"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the agent's MQTT configuration
#
# GET /mimic/agent/{agentNum}/protocol/msg/mqtt/get/config
# Returns: record<broker: string, clientid: string, filename: string, is_tls: string, password: string, port: int, tls_conf_filename: string, username: string, version: string>
# operationId: protocol_mqtt_get_config
export def "protocol-mqtt-get-config" [
  agent_num: int
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
    path: "/mimic/agent/{agentNum}/protocol/msg/mqtt/get/config"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the agent's MQTT statistics
#
# GET /mimic/agent/{agentNum}/protocol/msg/mqtt/get/statistics
# Returns: list<int>
# operationId: protocol_mqtt_get_statistics
export def "protocol-mqtt-get-statistics" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/protocol/msg/mqtt/get/statistics"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the agent's MQTT traffic tracing
#
# GET /mimic/agent/{agentNum}/protocol/msg/mqtt/get/trace
# Returns: record<broker: string, clientid: string, filename: string, is_tls: string, password: string, port: int, tls_conf_filename: string, username: string, version: string>
# operationId: protocol_mqtt_get_trace
export def "protocol-mqtt-get-trace" [
  agent_num: int
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
    path: "/mimic/agent/{agentNum}/protocol/msg/mqtt/get/trace"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the agent's MQTT configuration
#
# PUT /mimic/agent/{agentNum}/protocol/msg/mqtt/set/config/{argument}/{value}
# Returns: string
# operationId: protocol_mqtt_set_config
export def "protocol-mqtt-set-config" [
  agent_num: int
  argument: string
  value: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/mqtt/set/config/{argument}/{value}"
    path_params: [{name: agentNum, var: agent_num}, {name: argument, var: argument}, {name: value, var: value}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, argument: $argument, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the agent's MQTT traffic tracing
#
# PUT /mimic/agent/{agentNum}/protocol/msg/mqtt/set/trace/{enableOrNot}
# Returns: string
# operationId: protocol_mqtt_set_trace
export def "protocol-mqtt-set-trace" [
  agent_num: int
  enable_or_not: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/mqtt/set/trace/{enableOrNot}"
    path_params: [{name: agentNum, var: agent_num}, {name: enableOrNot, var: enable_or_not}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, enable_or_not: $enable_or_not
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change NETFLOW data export interval
#
# PUT /mimic/agent/{agentNum}/protocol/msg/netflow/flow/change/dfs_interval/{interval}
# Returns: string
# operationId: protocol_netflow_change_dfs
export def "protocol-netflow-change-dfs" [
  agent_num: int
  interval: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/netflow/flow/change/dfs_interval/{interval}"
    path_params: [{name: agentNum, var: agent_num}, {name: interval, var: interval}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, interval: $interval
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change NETFLOW template export interval
#
# PUT /mimic/agent/{agentNum}/protocol/msg/netflow/flow/change/tfs_interval/{interval}
# Returns: string
# operationId: protocol_netflow_change_tfs
export def "protocol-netflow-change-tfs" [
  agent_num: int
  interval: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/netflow/flow/change/tfs_interval/{interval}"
    path_params: [{name: agentNum, var: agent_num}, {name: interval, var: interval}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, interval: $interval
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change NETFLOW export attributes
#
# PUT /mimic/agent/{agentNum}/protocol/msg/netflow/flow/change/{flowset-uid}/{field-num}/{attr}/{value}
# Returns: string
# operationId: protocol_netflow_change_attr
export def "protocol-netflow-change-attr" [
  agent_num: int
  flowset_uid: int
  field_num: int
  attr: string
  value: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/netflow/flow/change/{flowset-uid}/{field-num}/{attr}/{value}"
    path_params: [{name: agentNum, var: agent_num}, {name: flowset-uid, var: flowset_uid}, {name: field-num, var: field_num}, {name: attr, var: attr}, {name: value, var: value}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, flowset_uid: $flowset_uid, field_num: $field_num, attr: $attr, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show list of NETFLOW exports
#
# GET /mimic/agent/{agentNum}/protocol/msg/netflow/flow/list
# Returns: list<record>
# operationId: protocol_netflow_list
export def "protocol-netflow-list" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/protocol/msg/netflow/flow/list"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the agent's NETFLOW argument structure
#
# GET /mimic/agent/{agentNum}/protocol/msg/netflow/get/args
# Returns: record
# operationId: protocol_netflow_get_args
export def "protocol-netflow-get-args" [
  agent_num: int
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
    path: "/mimic/agent/{agentNum}/protocol/msg/netflow/get/args"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the agent's NETFLOW configuration
#
# GET /mimic/agent/{agentNum}/protocol/msg/netflow/get/config
# Returns: record<bundleflowsets: int, collector: string, collectorport: int, filename: string>
# operationId: protocol_netflow_get_config
export def "protocol-netflow-get-config" [
  agent_num: int
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
    path: "/mimic/agent/{agentNum}/protocol/msg/netflow/get/config"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the agent's NETFLOW statistics
#
# GET /mimic/agent/{agentNum}/protocol/msg/netflow/get/statistics
# Returns: list<int>
# operationId: protocol_netflow_get_statistics
export def "protocol-netflow-get-statistics" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/protocol/msg/netflow/get/statistics"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the agent's NETFLOW traffic tracing
#
# GET /mimic/agent/{agentNum}/protocol/msg/netflow/get/trace
# Returns: record<bundleflowsets: int, collector: string, collectorport: int, filename: string>
# operationId: protocol_netflow_get_trace
export def "protocol-netflow-get-trace" [
  agent_num: int
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
    path: "/mimic/agent/{agentNum}/protocol/msg/netflow/get/trace"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Halt NETFLOW traffic
#
# PUT /mimic/agent/{agentNum}/protocol/msg/netflow/halt
# Returns: string
# operationId: protocol_netflow_halt
export def "protocol-netflow-halt" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/netflow/halt"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reload NETFLOW configuration before resuming traffic
#
# PUT /mimic/agent/{agentNum}/protocol/msg/netflow/reload
# Returns: string
# operationId: protocol_netflow_reload
export def "protocol-netflow-reload" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/netflow/reload"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resuming traffic
#
# PUT /mimic/agent/{agentNum}/protocol/msg/netflow/resume
# Returns: string
# operationId: protocol_netflow_resume
export def "protocol-netflow-resume" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/netflow/resume"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Swap NETFLOW collector
#
# PUT /mimic/agent/{agentNum}/protocol/msg/netflow/set/collector/{collectorIP}
# Returns: string
# operationId: protocol_netflow_set_collector
export def "protocol-netflow-set-collector" [
  agent_num: int
  collector_ip: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/netflow/set/collector/{collectorIP}"
    path_params: [{name: agentNum, var: agent_num}, {name: collectorIP, var: collector_ip}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, collector_ip: $collector_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the agent's NETFLOW configuration
#
# PUT /mimic/agent/{agentNum}/protocol/msg/netflow/set/config/{argument}/{value}
# Returns: string
# operationId: protocol_netflow_set_config
export def "protocol-netflow-set-config" [
  agent_num: int
  argument: string
  value: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/netflow/set/config/{argument}/{value}"
    path_params: [{name: agentNum, var: agent_num}, {name: argument, var: argument}, {name: value, var: value}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, argument: $argument, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Swap NETFLOW configuration file
#
# PUT /mimic/agent/{agentNum}/protocol/msg/netflow/set/filename/{fileName}
# Returns: string
# operationId: protocol_netflow_set_fileName
export def "protocol-netflow-set-file-name" [
  agent_num: int
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/netflow/set/filename/{fileName}"
    path_params: [{name: agentNum, var: agent_num}, {name: fileName, var: file_name}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, file_name: $file_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the agent's NETFLOW traffic tracing
#
# PUT /mimic/agent/{agentNum}/protocol/msg/netflow/set/trace/{enableOrNot}
# Returns: string
# operationId: protocol_netflow_set_trace
export def "protocol-netflow-set-trace" [
  agent_num: int
  enable_or_not: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/netflow/set/trace/{enableOrNot}"
    path_params: [{name: agentNum, var: agent_num}, {name: enableOrNot, var: enable_or_not}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, enable_or_not: $enable_or_not
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the agent's PROXY argument structure
#
# GET /mimic/agent/{agentNum}/protocol/msg/proxy/get/args
# Returns: record
# operationId: protocol_proxy_get_args
export def "protocol-proxy-get-args" [
  agent_num: int
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
    path: "/mimic/agent/{agentNum}/protocol/msg/proxy/get/args"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the agent's PROXY configuration
#
# GET /mimic/agent/{agentNum}/protocol/msg/proxy/get/config
# Returns: record<TCP_NODELAY: int, client_to_server: string, disconnect_delay: int, max_connects: int, portno: int, pre_connect: string, server_to_client: string, target: string, transport: string>
# operationId: protocol_proxy_get_config
export def "protocol-proxy-get-config" [
  agent_num: int
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
    path: "/mimic/agent/{agentNum}/protocol/msg/proxy/get/config"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the agent's PROXY statistics
#
# GET /mimic/agent/{agentNum}/protocol/msg/proxy/get/statistics
# Returns: list<int>
# operationId: protocol_proxy_get_statistics
export def "protocol-proxy-get-statistics" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/protocol/msg/proxy/get/statistics"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the agent's PROXY traffic tracing
#
# GET /mimic/agent/{agentNum}/protocol/msg/proxy/get/trace
# Returns: record<TCP_NODELAY: int, client_to_server: string, disconnect_delay: int, max_connects: int, portno: int, pre_connect: string, server_to_client: string, target: string, transport: string>
# operationId: protocol_proxy_get_trace
export def "protocol-proxy-get-trace" [
  agent_num: int
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
    path: "/mimic/agent/{agentNum}/protocol/msg/proxy/get/trace"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add individual proxy target on the agent and the simulator host
#
# POST /mimic/agent/{agentNum}/protocol/msg/proxy/port/add/{port}/{target}/{targetPort}
# Returns: string
# operationId: protocol_proxy_port_add
export def "protocol-proxy-port-add" [
  agent_num: int
  port: int
  target: string
  target_port: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: post
    path: "/mimic/agent/{agentNum}/protocol/msg/proxy/port/add/{port}/{target}/{targetPort}"
    path_params: [{name: agentNum, var: agent_num}, {name: port, var: port}, {name: target, var: target}, {name: targetPort, var: target_port}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, port: $port, target: $target, target_port: $target_port
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check individual target
#
# GET /mimic/agent/{agentNum}/protocol/msg/proxy/port/isStarted/{port}
# Returns: string
# operationId: protocol_proxy_port_isstarted
export def "protocol-proxy-port-isstarted" [
  agent_num: int
  port: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/protocol/msg/proxy/port/isStarted/{port}"
    path_params: [{name: agentNum, var: agent_num}, {name: port, var: port}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, port: $port
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all proxy targets
#
# GET /mimic/agent/{agentNum}/protocol/msg/proxy/port/list
# Returns: list<int>
# operationId: protocol_proxy_port_list
export def "protocol-proxy-port-list" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/protocol/msg/proxy/port/list"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove individual proxy target on the agent and the simulator host
#
# DELETE /mimic/agent/{agentNum}/protocol/msg/proxy/port/remove/{port}
# Returns: string
# operationId: protocol_proxy_port_remove
export def "protocol-proxy-port-remove" [
  agent_num: int
  port: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/mimic/agent/{agentNum}/protocol/msg/proxy/port/remove/{port}"
    path_params: [{name: agentNum, var: agent_num}, {name: port, var: port}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, port: $port
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Start additional target
#
# PUT /mimic/agent/{agentNum}/protocol/msg/proxy/port/start/{port}
# Returns: string
# operationId: protocol_proxy_port_start
export def "protocol-proxy-port-start" [
  agent_num: int
  port: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/proxy/port/start/{port}"
    path_params: [{name: agentNum, var: agent_num}, {name: port, var: port}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, port: $port
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stop additional target
#
# PUT /mimic/agent/{agentNum}/protocol/msg/proxy/port/stop/{port}
# Returns: string
# operationId: protocol_proxy_port_stop
export def "protocol-proxy-port-stop" [
  agent_num: int
  port: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/proxy/port/stop/{port}"
    path_params: [{name: agentNum, var: agent_num}, {name: port, var: port}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, port: $port
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the agent's PROXY configuration
#
# PUT /mimic/agent/{agentNum}/protocol/msg/proxy/set/config/{argument}/{value}
# Returns: string
# operationId: protocol_proxy_set_config
export def "protocol-proxy-set-config" [
  agent_num: int
  argument: string
  value: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/proxy/set/config/{argument}/{value}"
    path_params: [{name: agentNum, var: agent_num}, {name: argument, var: argument}, {name: value, var: value}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, argument: $argument, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the agent's PROXY traffic tracing
#
# PUT /mimic/agent/{agentNum}/protocol/msg/proxy/set/trace/{enableOrNot}
# Returns: string
# operationId: protocol_proxy_set_trace
export def "protocol-proxy-set-trace" [
  agent_num: int
  enable_or_not: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/proxy/set/trace/{enableOrNot}"
    path_params: [{name: agentNum, var: agent_num}, {name: enableOrNot, var: enable_or_not}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, enable_or_not: $enable_or_not
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the agent's SFLOW argument structure
#
# GET /mimic/agent/{agentNum}/protocol/msg/sflow/get/args
# Returns: record
# operationId: protocol_sflow_get_args
export def "protocol-sflow-get-args" [
  agent_num: int
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
    path: "/mimic/agent/{agentNum}/protocol/msg/sflow/get/args"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the agent's SFLOW configuration
#
# GET /mimic/agent/{agentNum}/protocol/msg/sflow/get/config
# Returns: record<collector: string, collectorport: int, encoding_type: string, filename: string, flows_per_min: int, include_samples: string, records_per_sample: string, samples_per_datagram: string>
# operationId: protocol_sflow_get_config
export def "protocol-sflow-get-config" [
  agent_num: int
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
    path: "/mimic/agent/{agentNum}/protocol/msg/sflow/get/config"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the agent's SFLOW statistics
#
# GET /mimic/agent/{agentNum}/protocol/msg/sflow/get/statistics
# Returns: list<int>
# operationId: protocol_sflow_get_statistics
export def "protocol-sflow-get-statistics" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/protocol/msg/sflow/get/statistics"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the agent's SFLOW traffic tracing
#
# GET /mimic/agent/{agentNum}/protocol/msg/sflow/get/trace
# Returns: record<collector: string, collectorport: int, encoding_type: string, filename: string, flows_per_min: int, include_samples: string, records_per_sample: string, samples_per_datagram: string>
# operationId: protocol_sflow_get_trace
export def "protocol-sflow-get-trace" [
  agent_num: int
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
    path: "/mimic/agent/{agentNum}/protocol/msg/sflow/get/trace"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Halt SFLOW traffic
#
# PUT /mimic/agent/{agentNum}/protocol/msg/sflow/halt
# Returns: string
# operationId: protocol_sflow_halt
export def "protocol-sflow-halt" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/sflow/halt"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reload SFLOW configuration before resuming traffic
#
# PUT /mimic/agent/{agentNum}/protocol/msg/sflow/reload
# Returns: string
# operationId: protocol_sflow_reload
export def "protocol-sflow-reload" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/sflow/reload"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resuming traffic
#
# PUT /mimic/agent/{agentNum}/protocol/msg/sflow/resume
# Returns: string
# operationId: protocol_sflow_resume
export def "protocol-sflow-resume" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/sflow/resume"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the agent's SFLOW configuration
#
# PUT /mimic/agent/{agentNum}/protocol/msg/sflow/set/config/{argument}/{value}
# Returns: string
# operationId: protocol_sflow_set_config
export def "protocol-sflow-set-config" [
  agent_num: int
  argument: string
  value: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/sflow/set/config/{argument}/{value}"
    path_params: [{name: agentNum, var: agent_num}, {name: argument, var: argument}, {name: value, var: value}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, argument: $argument, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the agent's SFLOW traffic tracing
#
# PUT /mimic/agent/{agentNum}/protocol/msg/sflow/set/trace/{enableOrNot}
# Returns: string
# operationId: protocol_sflow_set_trace
export def "protocol-sflow-set-trace" [
  agent_num: int
  enable_or_not: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/sflow/set/trace/{enableOrNot}"
    path_params: [{name: agentNum, var: agent_num}, {name: enableOrNot, var: enable_or_not}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, enable_or_not: $enable_or_not
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the agent's SNMPTCP argument structure
#
# GET /mimic/agent/{agentNum}/protocol/msg/snmptcp/get/args
# Returns: record
# operationId: protocol_snmptcp_get_args
export def "protocol-snmptcp-get-args" [
  agent_num: int
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
    path: "/mimic/agent/{agentNum}/protocol/msg/snmptcp/get/args"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the agent's SNMPTCP configuration
#
# GET /mimic/agent/{agentNum}/protocol/msg/snmptcp/get/config
# Returns: record<connections: int>
# operationId: protocol_snmptcp_get_config
export def "protocol-snmptcp-get-config" [
  agent_num: int
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
    path: "/mimic/agent/{agentNum}/protocol/msg/snmptcp/get/config"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the agent's SNMPTCP statistics
#
# GET /mimic/agent/{agentNum}/protocol/msg/snmptcp/get/statistics
# Returns: list<int>
# operationId: protocol_snmptcp_get_statistics
export def "protocol-snmptcp-get-statistics" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/protocol/msg/snmptcp/get/statistics"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the agent's SNMPTCP traffic tracing
#
# GET /mimic/agent/{agentNum}/protocol/msg/snmptcp/get/trace
# Returns: record<connections: int>
# operationId: protocol_snmptcp_get_trace
export def "protocol-snmptcp-get-trace" [
  agent_num: int
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
    path: "/mimic/agent/{agentNum}/protocol/msg/snmptcp/get/trace"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disable individual IP aliases on the agent and the simulator host
#
# PUT /mimic/agent/{agentNum}/protocol/msg/snmptcp/ipalias/disable/{ipaddress}/{port}
# Returns: string
# operationId: protocol_snmptcp_ipalias_disable
export def "protocol-snmptcp-ipalias-disable" [
  agent_num: int
  ipaddress: string
  port: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/snmptcp/ipalias/disable/{ipaddress}/{port}"
    path_params: [{name: agentNum, var: agent_num}, {name: ipaddress, var: ipaddress}, {name: port, var: port}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, ipaddress: $ipaddress, port: $port
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enable individual IP aliases on the agent and the simulator host
#
# PUT /mimic/agent/{agentNum}/protocol/msg/snmptcp/ipalias/enable/{ipaddress}/{port}
# Returns: string
# operationId: protocol_snmptcp_ipalias_enable
export def "protocol-snmptcp-ipalias-enable" [
  agent_num: int
  ipaddress: string
  port: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/snmptcp/ipalias/enable/{ipaddress}/{port}"
    path_params: [{name: agentNum, var: agent_num}, {name: ipaddress, var: ipaddress}, {name: port, var: port}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, ipaddress: $ipaddress, port: $port
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check individual IP aliases on the agent and the simulator host
#
# GET /mimic/agent/{agentNum}/protocol/msg/snmptcp/ipalias/isenabled/{ipaddress}/{port}
# Returns: string
# operationId: protocol_snmptcp_ipalias_isenabled
export def "protocol-snmptcp-ipalias-isenabled" [
  agent_num: int
  ipaddress: string
  port: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/protocol/msg/snmptcp/ipalias/isenabled/{ipaddress}/{port}"
    path_params: [{name: agentNum, var: agent_num}, {name: ipaddress, var: ipaddress}, {name: port, var: port}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, ipaddress: $ipaddress, port: $port
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all IP aliases on the agent and the simulator host
#
# GET /mimic/agent/{agentNum}/protocol/msg/snmptcp/ipalias/list
# Returns: table<IP: string, interface: string, mask: string, port: int>
# operationId: protocol_snmptcp_ipalias_list
export def "protocol-snmptcp-ipalias-list" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/protocol/msg/snmptcp/ipalias/list"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the agent's SNMPTCP configuration
#
# PUT /mimic/agent/{agentNum}/protocol/msg/snmptcp/set/config/{argument}/{value}
# Returns: string
# operationId: protocol_snmptcp_set_config
export def "protocol-snmptcp-set-config" [
  agent_num: int
  argument: string
  value: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/snmptcp/set/config/{argument}/{value}"
    path_params: [{name: agentNum, var: agent_num}, {name: argument, var: argument}, {name: value, var: value}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, argument: $argument, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the agent's SNMPTCP traffic tracing
#
# PUT /mimic/agent/{agentNum}/protocol/msg/snmptcp/set/trace/{enableOrNot}
# Returns: string
# operationId: protocol_snmptcp_set_trace
export def "protocol-snmptcp-set-trace" [
  agent_num: int
  enable_or_not: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/snmptcp/set/trace/{enableOrNot}"
    path_params: [{name: agentNum, var: agent_num}, {name: enableOrNot, var: enable_or_not}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, enable_or_not: $enable_or_not
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a new access entry with the specified parameters.
#
# POST /mimic/agent/{agentNum}/protocol/msg/snmpv3/access/add/{groupName}/{prefix}/{securityModel}/{securityLevel}/{contextMatch}/{readView}/{writeView}/{notifyView}
# Returns: string
# operationId: protocol_snmpv3_access_add
export def "protocol-snmpv3-access-add" [
  agent_num: int
  group_name: string
  prefix: string
  security_model: string
  security_level: string
  context_match: string
  read_view: string
  write_view: string
  notify_view: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: post
    path: "/mimic/agent/{agentNum}/protocol/msg/snmpv3/access/add/{groupName}/{prefix}/{securityModel}/{securityLevel}/{contextMatch}/{readView}/{writeView}/{notifyView}"
    path_params: [{name: agentNum, var: agent_num}, {name: groupName, var: group_name}, {name: prefix, var: prefix}, {name: securityModel, var: security_model}, {name: securityLevel, var: security_level}, {name: contextMatch, var: context_match}, {name: readView, var: read_view}, {name: writeView, var: write_view}, {name: notifyView, var: notify_view}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, group_name: $group_name, prefix: $prefix, security_model: $security_model, security_level: $security_level, context_match: $context_match, read_view: $read_view, write_view: $write_view, notify_view: $notify_view
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Clears all access entries.
#
# DELETE /mimic/agent/{agentNum}/protocol/msg/snmpv3/access/clear
# Returns: string
# operationId: protocol_snmpv3_access_clear
export def "protocol-snmpv3-access-clear" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/mimic/agent/{agentNum}/protocol/msg/snmpv3/access/clear"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified access entry.
#
# DELETE /mimic/agent/{agentNum}/protocol/msg/snmpv3/access/del/{accessName}
# Returns: string
# operationId: protocol_snmpv3_access_del
export def "protocol-snmpv3-access-del" [
  agent_num: int
  access_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/mimic/agent/{agentNum}/protocol/msg/snmpv3/access/del/{accessName}"
    path_params: [{name: agentNum, var: agent_num}, {name: accessName, var: access_name}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, access_name: $access_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the current acccess entries as an array of strings.
#
# GET /mimic/agent/{agentNum}/protocol/msg/snmpv3/access/list
# Returns: list<string>
# operationId: protocol_snmpv3_access_list
export def "protocol-snmpv3-access-list" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/protocol/msg/snmpv3/access/list"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the SNMPv3 configuration.
#
# GET /mimic/agent/{agentNum}/protocol/msg/snmpv3/get/config
# Returns: record<context_engine_id: string, engine_id: string, usm_db: string, vacm_db: string>
# operationId: protocol_snmpv3_get_config
export def "protocol-snmpv3-get-config" [
  agent_num: int
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
    path: "/mimic/agent/{agentNum}/protocol/msg/snmpv3/get/config"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the contextEngineID for the agent instance.
#
# GET /mimic/agent/{agentNum}/protocol/msg/snmpv3/get/context_engineid
# Returns: string
# operationId: protocol_snmpv3_get_context_engineid
export def "protocol-snmpv3-get-context-engineid" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/protocol/msg/snmpv3/get/context_engineid"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the number of times the agent has been restarted.
#
# GET /mimic/agent/{agentNum}/protocol/msg/snmpv3/get/engineboots
# Returns: int
# operationId: protocol_snmpv3_get_engineboots
export def "protocol-snmpv3-get-engineboots" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/protocol/msg/snmpv3/get/engineboots"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# For started agents, retrieves the current engineID in use by the snmpv3 module.
#
# GET /mimic/agent/{agentNum}/protocol/msg/snmpv3/get/engineid
# Returns: string
# operationId: protocol_snmpv3_get_engineid
export def "protocol-snmpv3-get-engineid" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/protocol/msg/snmpv3/get/engineid"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the time in seconds for which the agent has been running.
#
# GET /mimic/agent/{agentNum}/protocol/msg/snmpv3/get/enginetime
# Returns: int
# operationId: protocol_snmpv3_get_enginetime
export def "protocol-snmpv3-get-enginetime" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/protocol/msg/snmpv3/get/enginetime"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a new group entry with the specified parameters.
#
# POST /mimic/agent/{agentNum}/protocol/msg/snmpv3/group/add/{groupName}/{securityModel}/{securityName}
# Returns: string
# operationId: protocol_snmpv3_group_add
export def "protocol-snmpv3-group-add" [
  agent_num: int
  group_name: string
  security_model: string
  security_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: post
    path: "/mimic/agent/{agentNum}/protocol/msg/snmpv3/group/add/{groupName}/{securityModel}/{securityName}"
    path_params: [{name: agentNum, var: agent_num}, {name: groupName, var: group_name}, {name: securityModel, var: security_model}, {name: securityName, var: security_name}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, group_name: $group_name, security_model: $security_model, security_name: $security_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Clears all group entries.
#
# DELETE /mimic/agent/{agentNum}/protocol/msg/snmpv3/group/clear
# Returns: string
# operationId: protocol_snmpv3_group_clear
export def "protocol-snmpv3-group-clear" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/mimic/agent/{agentNum}/protocol/msg/snmpv3/group/clear"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified group entry.
#
# DELETE /mimic/agent/{agentNum}/protocol/msg/snmpv3/group/del/{groupName}
# Returns: string
# operationId: protocol_snmpv3_group_del
export def "protocol-snmpv3-group-del" [
  agent_num: int
  group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/mimic/agent/{agentNum}/protocol/msg/snmpv3/group/del/{groupName}"
    path_params: [{name: agentNum, var: agent_num}, {name: groupName, var: group_name}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, group_name: $group_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the current group entries as an array of strings.
#
# GET /mimic/agent/{agentNum}/protocol/msg/snmpv3/group/list
# Returns: list<string>
# operationId: protocol_snmpv3_group_list
export def "protocol-snmpv3-group-list" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/protocol/msg/snmpv3/group/list"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Changes the SNMPv3 configuration.
#
# PUT /mimic/agent/{agentNum}/protocol/msg/snmpv3/set/config/{parameter}/{value}
# Returns: string
# operationId: protocol_snmpv3_set_config
export def "protocol-snmpv3-set-config" [
  agent_num: int
  parameter: string
  value: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/snmpv3/set/config/{parameter}/{value}"
    path_params: [{name: agentNum, var: agent_num}, {name: parameter, var: parameter}, {name: value, var: value}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, parameter: $parameter, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a new user entry with the specified parameters.
#
# POST /mimic/agent/{agentNum}/protocol/msg/snmpv3/user/add/{userName}/{securityName}/{authProtocol}/{authKey}/{privProtocol}/{privKey}
# Returns: string
# operationId: protocol_snmpv3_user_add
export def "protocol-snmpv3-user-add" [
  agent_num: int
  user_name: string
  security_name: string
  auth_protocol: string
  auth_key: string
  priv_protocol: string
  priv_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: post
    path: "/mimic/agent/{agentNum}/protocol/msg/snmpv3/user/add/{userName}/{securityName}/{authProtocol}/{authKey}/{privProtocol}/{privKey}"
    path_params: [{name: agentNum, var: agent_num}, {name: userName, var: user_name}, {name: securityName, var: security_name}, {name: authProtocol, var: auth_protocol}, {name: authKey, var: auth_key}, {name: privProtocol, var: priv_protocol}, {name: privKey, var: priv_key}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, user_name: $user_name, security_name: $security_name, auth_protocol: $auth_protocol, auth_key: $auth_key, priv_protocol: $priv_protocol, priv_key: $priv_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Clears all user entries.
#
# DELETE /mimic/agent/{agentNum}/protocol/msg/snmpv3/user/clear
# Returns: string
# operationId: protocol_snmpv3_user_clear
export def "protocol-snmpv3-user-clear" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/mimic/agent/{agentNum}/protocol/msg/snmpv3/user/clear"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified user entry.
#
# DELETE /mimic/agent/{agentNum}/protocol/msg/snmpv3/user/del/{userName}
# Returns: string
# operationId: protocol_snmpv3_user_del
export def "protocol-snmpv3-user-del" [
  agent_num: int
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/mimic/agent/{agentNum}/protocol/msg/snmpv3/user/del/{userName}"
    path_params: [{name: agentNum, var: agent_num}, {name: userName, var: user_name}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, user_name: $user_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the current user entries as a Tcl list.
#
# GET /mimic/agent/{agentNum}/protocol/msg/snmpv3/user/list
# Returns: list<string>
# operationId: protocol_snmpv3_user_list
export def "protocol-snmpv3-user-list" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/protocol/msg/snmpv3/user/list"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Saves current user settings in the currently loaded USM config file.
#
# PUT /mimic/agent/{agentNum}/protocol/msg/snmpv3/usm/save
# Returns: list<string>
# operationId: protocol_snmpv3_usm_save
export def "protocol-snmpv3-usm-save" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/snmpv3/usm/save"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Saves current user settings in the specified USM config file.
#
# PUT /mimic/agent/{agentNum}/protocol/msg/snmpv3/usm/saveas/{filename}
# Returns: list<string>
# operationId: protocol_snmpv3_usm_saveas
export def "protocol-snmpv3-usm-saveas" [
  agent_num: int
  filename: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/snmpv3/usm/saveas/{filename}"
    path_params: [{name: agentNum, var: agent_num}, {name: filename, var: filename}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, filename: $filename
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Saves current group, access, view settings in the currently loaded VACM config file.
#
# PUT /mimic/agent/{agentNum}/protocol/msg/snmpv3/vacm/save
# Returns: list<string>
# operationId: protocol_snmpv3_vacm_save
export def "protocol-snmpv3-vacm-save" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/snmpv3/vacm/save"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Saves current group, access, view settings in the specified VACM config file.
#
# PUT /mimic/agent/{agentNum}/protocol/msg/snmpv3/vacm/saveas/{filename}
# Returns: list<string>
# operationId: protocol_snmpv3_vacm_saveas
export def "protocol-snmpv3-vacm-saveas" [
  agent_num: int
  filename: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/snmpv3/vacm/saveas/{filename}"
    path_params: [{name: agentNum, var: agent_num}, {name: filename, var: filename}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, filename: $filename
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a new view entry with the specified parameters.
#
# POST /mimic/agent/{agentNum}/protocol/msg/snmpv3/view/add/{viewName}/{viewType}/{subtree}/{mask}
# Returns: string
# operationId: protocol_snmpv3_view_add
export def "protocol-snmpv3-view-add" [
  agent_num: int
  view_name: string
  view_type: string
  subtree: string
  mask: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: post
    path: "/mimic/agent/{agentNum}/protocol/msg/snmpv3/view/add/{viewName}/{viewType}/{subtree}/{mask}"
    path_params: [{name: agentNum, var: agent_num}, {name: viewName, var: view_name}, {name: viewType, var: view_type}, {name: subtree, var: subtree}, {name: mask, var: mask}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, view_name: $view_name, view_type: $view_type, subtree: $subtree, mask: $mask
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Clears all view entries.
#
# DELETE /mimic/agent/{agentNum}/protocol/msg/snmpv3/view/clear
# Returns: string
# operationId: protocol_snmpv3_view_clear
export def "protocol-snmpv3-view-clear" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/mimic/agent/{agentNum}/protocol/msg/snmpv3/view/clear"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified view entry.
#
# DELETE /mimic/agent/{agentNum}/protocol/msg/snmpv3/view/del/{viewName}
# Returns: string
# operationId: protocol_snmpv3_view_del
export def "protocol-snmpv3-view-del" [
  agent_num: int
  view_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/mimic/agent/{agentNum}/protocol/msg/snmpv3/view/del/{viewName}"
    path_params: [{name: agentNum, var: agent_num}, {name: viewName, var: view_name}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, view_name: $view_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the current view entries as an array of strings.
#
# GET /mimic/agent/{agentNum}/protocol/msg/snmpv3/view/list
# Returns: list<string>
# operationId: protocol_snmpv3_view_list
export def "protocol-snmpv3-view-list" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/protocol/msg/snmpv3/view/list"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the agent's SSH argument structure
#
# GET /mimic/agent/{agentNum}/protocol/msg/ssh/get/args
# Returns: record
# operationId: protocol_ssh_get_args
export def "protocol-ssh-get-args" [
  agent_num: int
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
    path: "/mimic/agent/{agentNum}/protocol/msg/ssh/get/args"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the agent's SSH configuration
#
# GET /mimic/agent/{agentNum}/protocol/msg/ssh/get/config
# Returns: record<port: int, version: string>
# operationId: protocol_ssh_get_config
export def "protocol-ssh-get-config" [
  agent_num: int
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
    path: "/mimic/agent/{agentNum}/protocol/msg/ssh/get/config"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the agent's SSH statistics
#
# GET /mimic/agent/{agentNum}/protocol/msg/ssh/get/statistics
# Returns: list<int>
# operationId: protocol_ssh_get_statistics
export def "protocol-ssh-get-statistics" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/protocol/msg/ssh/get/statistics"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the agent's SSH traffic tracing
#
# GET /mimic/agent/{agentNum}/protocol/msg/ssh/get/trace
# Returns: record<port: int, version: string>
# operationId: protocol_ssh_get_trace
export def "protocol-ssh-get-trace" [
  agent_num: int
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
    path: "/mimic/agent/{agentNum}/protocol/msg/ssh/get/trace"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disable individual IP aliases on the agent and the simulator host
#
# PUT /mimic/agent/{agentNum}/protocol/msg/ssh/ipalias/disable/{ipaddress}/{port}
# Returns: string
# operationId: protocol_ssh_ipalias_disable
export def "protocol-ssh-ipalias-disable" [
  agent_num: int
  ipaddress: string
  port: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/ssh/ipalias/disable/{ipaddress}/{port}"
    path_params: [{name: agentNum, var: agent_num}, {name: ipaddress, var: ipaddress}, {name: port, var: port}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, ipaddress: $ipaddress, port: $port
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enable individual IP aliases on the agent and the simulator host
#
# PUT /mimic/agent/{agentNum}/protocol/msg/ssh/ipalias/enable/{ipaddress}/{port}
# Returns: string
# operationId: protocol_ssh_ipalias_enable
export def "protocol-ssh-ipalias-enable" [
  agent_num: int
  ipaddress: string
  port: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/ssh/ipalias/enable/{ipaddress}/{port}"
    path_params: [{name: agentNum, var: agent_num}, {name: ipaddress, var: ipaddress}, {name: port, var: port}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, ipaddress: $ipaddress, port: $port
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check individual IP aliases on the agent and the simulator host
#
# GET /mimic/agent/{agentNum}/protocol/msg/ssh/ipalias/isenabled/{ipaddress}/{port}
# Returns: string
# operationId: protocol_ssh_ipalias_isenabled
export def "protocol-ssh-ipalias-isenabled" [
  agent_num: int
  ipaddress: string
  port: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/protocol/msg/ssh/ipalias/isenabled/{ipaddress}/{port}"
    path_params: [{name: agentNum, var: agent_num}, {name: ipaddress, var: ipaddress}, {name: port, var: port}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, ipaddress: $ipaddress, port: $port
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all IP aliases on the agent and the simulator host
#
# GET /mimic/agent/{agentNum}/protocol/msg/ssh/ipalias/list
# Returns: table<IP: string, interface: string, mask: string, port: int>
# operationId: protocol_ssh_ipalias_list
export def "protocol-ssh-ipalias-list" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/protocol/msg/ssh/ipalias/list"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the agent's SSH configuration
#
# PUT /mimic/agent/{agentNum}/protocol/msg/ssh/set/config/{argument}/{value}
# Returns: string
# operationId: protocol_ssh_set_config
export def "protocol-ssh-set-config" [
  agent_num: int
  argument: string
  value: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/ssh/set/config/{argument}/{value}"
    path_params: [{name: agentNum, var: agent_num}, {name: argument, var: argument}, {name: value, var: value}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, argument: $argument, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the agent's SSH traffic tracing
#
# PUT /mimic/agent/{agentNum}/protocol/msg/ssh/set/trace/{enableOrNot}
# Returns: string
# operationId: protocol_ssh_set_trace
export def "protocol-ssh-set-trace" [
  agent_num: int
  enable_or_not: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/ssh/set/trace/{enableOrNot}"
    path_params: [{name: agentNum, var: agent_num}, {name: enableOrNot, var: enable_or_not}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, enable_or_not: $enable_or_not
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the agent's SYSLOG argument structure
#
# GET /mimic/agent/{agentNum}/protocol/msg/syslog/get/args
# Returns: record
# operationId: protocol_syslog_get_args
export def "protocol-syslog-get-args" [
  agent_num: int
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
    path: "/mimic/agent/{agentNum}/protocol/msg/syslog/get/args"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the agent's SYSLOG configuration
#
# GET /mimic/agent/{agentNum}/protocol/msg/syslog/get/config
# Returns: record<client: string, hostname: string, localport: int, separator: string, sequence: int, server: string, serverport: int, timestamp: string>
# operationId: protocol_syslog_get_config
export def "protocol-syslog-get-config" [
  agent_num: int
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
    path: "/mimic/agent/{agentNum}/protocol/msg/syslog/get/config"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the agent's SYSLOG statistics
#
# GET /mimic/agent/{agentNum}/protocol/msg/syslog/get/statistics
# Returns: list<int>
# operationId: protocol_syslog_get_statistics
export def "protocol-syslog-get-statistics" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/protocol/msg/syslog/get/statistics"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the agent's SYSLOG traffic tracing
#
# GET /mimic/agent/{agentNum}/protocol/msg/syslog/get/trace
# Returns: record<client: string, hostname: string, localport: int, separator: string, sequence: int, server: string, serverport: int, timestamp: string>
# operationId: protocol_syslog_get_trace
export def "protocol-syslog-get-trace" [
  agent_num: int
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
    path: "/mimic/agent/{agentNum}/protocol/msg/syslog/get/trace"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the outgoing message's attributes
#
# GET /mimic/agent/{agentNum}/protocol/msg/syslog/get/{attr}
# Returns: string
# operationId: protocol_syslog_get_attr
export def "protocol-syslog-get-attr" [
  agent_num: int
  attr: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/protocol/msg/syslog/get/{attr}"
    path_params: [{name: agentNum, var: agent_num}, {name: attr, var: attr}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, attr: $attr
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the agent's SYSLOG traffic tracing
#
# POST /mimic/agent/{agentNum}/protocol/msg/syslog/send/{pri}
# Returns: string
# operationId: protocol_syslog_send
export def "protocol-syslog-send" [
  agent_num: int
  pri: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hostname: string
  --message: string
  --separator: string
  --sequence: string
  --timestamp: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/mimic/agent/{agentNum}/protocol/msg/syslog/send/{pri}"
    path_params: [{name: agentNum, var: agent_num}, {name: pri, var: pri}]
    body: {content_type: "application/json", kind: json, fields: [{name: hostname, var: hostname}, {name: message, var: message}, {name: separator, var: separator}, {name: sequence, var: sequence}, {name: timestamp, var: timestamp}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, pri: $pri, hostname: $hostname, message: $message, separator: $separator, sequence: $sequence, timestamp: $timestamp
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the agent's SYSLOG configuration
#
# PUT /mimic/agent/{agentNum}/protocol/msg/syslog/set/config/{argument}/{value}
# Returns: string
# operationId: protocol_syslog_set_config
export def "protocol-syslog-set-config" [
  agent_num: int
  argument: string
  value: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/syslog/set/config/{argument}/{value}"
    path_params: [{name: agentNum, var: agent_num}, {name: argument, var: argument}, {name: value, var: value}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, argument: $argument, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the agent's SYSLOG traffic tracing
#
# PUT /mimic/agent/{agentNum}/protocol/msg/syslog/set/trace/{enableOrNot}
# Returns: string
# operationId: protocol_syslog_set_trace
export def "protocol-syslog-set-trace" [
  agent_num: int
  enable_or_not: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/syslog/set/trace/{enableOrNot}"
    path_params: [{name: agentNum, var: agent_num}, {name: enableOrNot, var: enable_or_not}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, enable_or_not: $enable_or_not
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the outgoing message's attributes
#
# PUT /mimic/agent/{agentNum}/protocol/msg/syslog/set/{attr}/{value}
# Returns: string
# operationId: protocol_syslog_set_attr
export def "protocol-syslog-set-attr" [
  agent_num: int
  attr: string
  value: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/syslog/set/{attr}/{value}"
    path_params: [{name: agentNum, var: agent_num}, {name: attr, var: attr}, {name: value, var: value}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, attr: $attr, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Changes the connection's current logon.
#
# PUT /mimic/agent/{agentNum}/protocol/msg/telnet/connection/logon/{connectionID}/{user}/{password}
# Returns: list<string>
# operationId: protocol_telnet_connection_logon
export def "protocol-telnet-connection-logon" [
  agent_num: int
  connection_id: int
  user: string
  password: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/telnet/connection/logon/{connectionID}/{user}/{password}"
    path_params: [{name: agentNum, var: agent_num}, {name: connectionID, var: connection_id}, {name: user, var: user}, {name: password, var: password}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, connection_id: $connection_id, user: $user, password: $password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Executes the command asynchronously .
#
# PUT /mimic/agent/{agentNum}/protocol/msg/telnet/connection/request/{connectionID}/{command}
# Returns: list<string>
# operationId: protocol_telnet_connection_request
export def "protocol-telnet-connection-request" [
  agent_num: int
  connection_id: int
  command: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/telnet/connection/request/{connectionID}/{command}"
    path_params: [{name: agentNum, var: agent_num}, {name: connectionID, var: connection_id}, {name: command, var: command}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, connection_id: $connection_id, command: $command
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Triggers the asynchronous signal event with the specified signal name
#
# PUT /mimic/agent/{agentNum}/protocol/msg/telnet/connection/signal/{connectionID}/{signalName}
# Returns: list<string>
# operationId: protocol_telnet_connection_signal
export def "protocol-telnet-connection-signal" [
  agent_num: int
  connection_id: int
  signal_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/telnet/connection/signal/{connectionID}/{signalName}"
    path_params: [{name: agentNum, var: agent_num}, {name: connectionID, var: connection_id}, {name: signalName, var: signal_name}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, connection_id: $connection_id, signal_name: $signal_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the agent's TELNET argument structure
#
# GET /mimic/agent/{agentNum}/protocol/msg/telnet/get/args
# Returns: record
# operationId: protocol_telnet_get_args
export def "protocol-telnet-get-args" [
  agent_num: int
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
    path: "/mimic/agent/{agentNum}/protocol/msg/telnet/get/args"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the agent's TELNET configuration
#
# GET /mimic/agent/{agentNum}/protocol/msg/telnet/get/config
# Returns: record<keymap: string, paging_prompt: string, port: int, prompt: string, rule: string, userdb: string>
# operationId: protocol_telnet_get_config
export def "protocol-telnet-get-config" [
  agent_num: int
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
    path: "/mimic/agent/{agentNum}/protocol/msg/telnet/get/config"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the agent's TELNET statistics
#
# GET /mimic/agent/{agentNum}/protocol/msg/telnet/get/statistics
# Returns: list<int>
# operationId: protocol_telnet_get_statistics
export def "protocol-telnet-get-statistics" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/protocol/msg/telnet/get/statistics"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the agent's TELNET traffic tracing
#
# GET /mimic/agent/{agentNum}/protocol/msg/telnet/get/trace
# Returns: record<keymap: string, paging_prompt: string, port: int, prompt: string, rule: string, userdb: string>
# operationId: protocol_telnet_get_trace
export def "protocol-telnet-get-trace" [
  agent_num: int
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
    path: "/mimic/agent/{agentNum}/protocol/msg/telnet/get/trace"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disable individual IP aliases on the agent and the simulator host
#
# PUT /mimic/agent/{agentNum}/protocol/msg/telnet/ipalias/disable/{ipaddress}/{port}
# Returns: string
# operationId: protocol_telnet_ipalias_disable
export def "protocol-telnet-ipalias-disable" [
  agent_num: int
  ipaddress: string
  port: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/telnet/ipalias/disable/{ipaddress}/{port}"
    path_params: [{name: agentNum, var: agent_num}, {name: ipaddress, var: ipaddress}, {name: port, var: port}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, ipaddress: $ipaddress, port: $port
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enable individual IP aliases on the agent and the simulator host
#
# PUT /mimic/agent/{agentNum}/protocol/msg/telnet/ipalias/enable/{ipaddress}/{port}
# Returns: string
# operationId: protocol_telnet_ipalias_enable
export def "protocol-telnet-ipalias-enable" [
  agent_num: int
  ipaddress: string
  port: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/telnet/ipalias/enable/{ipaddress}/{port}"
    path_params: [{name: agentNum, var: agent_num}, {name: ipaddress, var: ipaddress}, {name: port, var: port}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, ipaddress: $ipaddress, port: $port
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check individual IP aliases on the agent and the simulator host
#
# GET /mimic/agent/{agentNum}/protocol/msg/telnet/ipalias/isenabled/{ipaddress}/{port}
# Returns: string
# operationId: protocol_telnet_ipalias_isenabled
export def "protocol-telnet-ipalias-isenabled" [
  agent_num: int
  ipaddress: string
  port: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/protocol/msg/telnet/ipalias/isenabled/{ipaddress}/{port}"
    path_params: [{name: agentNum, var: agent_num}, {name: ipaddress, var: ipaddress}, {name: port, var: port}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, ipaddress: $ipaddress, port: $port
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all IP aliases on the agent and the simulator host
#
# GET /mimic/agent/{agentNum}/protocol/msg/telnet/ipalias/list
# Returns: table<IP: string, interface: string, mask: string, port: int>
# operationId: protocol_telnet_ipalias_list
export def "protocol-telnet-ipalias-list" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/protocol/msg/telnet/ipalias/list"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the agent's TELNET connections
#
# GET /mimic/agent/{agentNum}/protocol/msg/telnet/server/get/connections
# Returns: list<int>
# operationId: protocol_telnet_server_get_connections
export def "protocol-telnet-server-get-connections" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/protocol/msg/telnet/server/get/connections"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the agent's TELNET keymap file name
#
# GET /mimic/agent/{agentNum}/protocol/msg/telnet/server/get/keymap
# Returns: list<string>
# operationId: protocol_telnet_server_get_keymap
export def "protocol-telnet-server-get-keymap" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/protocol/msg/telnet/server/get/keymap"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the agent's TELNET rules db file name
#
# GET /mimic/agent/{agentNum}/protocol/msg/telnet/server/get/rulesdb
# Returns: list<string>
# operationId: protocol_telnet_server_get_rulesdb
export def "protocol-telnet-server-get-rulesdb" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/protocol/msg/telnet/server/get/rulesdb"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the agent's TELNET server state
#
# GET /mimic/agent/{agentNum}/protocol/msg/telnet/server/get/state
# Returns: list<int>
# operationId: protocol_telnet_server_get_state
export def "protocol-telnet-server-get-state" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/protocol/msg/telnet/server/get/state"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the agent's TELNET user db file name
#
# GET /mimic/agent/{agentNum}/protocol/msg/telnet/server/get/userdb
# Returns: list<string>
# operationId: protocol_telnet_server_get_userdb
export def "protocol-telnet-server-get-userdb" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/protocol/msg/telnet/server/get/userdb"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the agent's TELNET users
#
# GET /mimic/agent/{agentNum}/protocol/msg/telnet/server/get/users
# Returns: table<groups: list<string>, hasPassword: int, password: string, username: string>
# operationId: protocol_telnet_server_get_users
export def "protocol-telnet-server-get-users" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/protocol/msg/telnet/server/get/users"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the agent's TELNET configuration
#
# PUT /mimic/agent/{agentNum}/protocol/msg/telnet/set/config/{argument}/{value}
# Returns: string
# operationId: protocol_telnet_set_config
export def "protocol-telnet-set-config" [
  agent_num: int
  argument: string
  value: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/telnet/set/config/{argument}/{value}"
    path_params: [{name: agentNum, var: agent_num}, {name: argument, var: argument}, {name: value, var: value}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, argument: $argument, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the agent's TELNET traffic tracing
#
# PUT /mimic/agent/{agentNum}/protocol/msg/telnet/set/trace/{enableOrNot}
# Returns: string
# operationId: protocol_telnet_set_trace
export def "protocol-telnet-set-trace" [
  agent_num: int
  enable_or_not: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/telnet/set/trace/{enableOrNot}"
    path_params: [{name: agentNum, var: agent_num}, {name: enableOrNot, var: enable_or_not}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, enable_or_not: $enable_or_not
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the agent's TFTP argument structure
#
# GET /mimic/agent/{agentNum}/protocol/msg/tftp/get/args
# Returns: record
# operationId: protocol_tftp_get_args
export def "protocol-tftp-get-args" [
  agent_num: int
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
    path: "/mimic/agent/{agentNum}/protocol/msg/tftp/get/args"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the agent's TFTP configuration
#
# GET /mimic/agent/{agentNum}/protocol/msg/tftp/get/config
# Returns: record<cache: int, client: string, dstfile: string, mode: string, port: int, retries: int, script: string, server: string, srcfile: string, timeout: int, trace: string>
# operationId: protocol_tftp_get_config
export def "protocol-tftp-get-config" [
  agent_num: int
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
    path: "/mimic/agent/{agentNum}/protocol/msg/tftp/get/config"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the agent's TFTP statistics
#
# GET /mimic/agent/{agentNum}/protocol/msg/tftp/get/statistics
# Returns: list<int>
# operationId: protocol_tftp_get_statistics
export def "protocol-tftp-get-statistics" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/protocol/msg/tftp/get/statistics"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the agent's TFTP traffic tracing
#
# GET /mimic/agent/{agentNum}/protocol/msg/tftp/get/trace
# Returns: record<cache: int, client: string, dstfile: string, mode: string, port: int, retries: int, script: string, server: string, srcfile: string, timeout: int, trace: string>
# operationId: protocol_tftp_get_trace
export def "protocol-tftp-get-trace" [
  agent_num: int
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
    path: "/mimic/agent/{agentNum}/protocol/msg/tftp/get/trace"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a read session to download srcfile from server
#
# POST /mimic/agent/{agentNum}/protocol/msg/tftp/session/read/server/{srcfile}
# Returns: list<int>
# operationId: protocol_tftp_session_read
export def "protocol-tftp-session-read" [
  agent_num: int
  srcfile: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: post
    path: "/mimic/agent/{agentNum}/protocol/msg/tftp/session/read/server/{srcfile}"
    path_params: [{name: agentNum, var: agent_num}, {name: srcfile, var: srcfile}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, srcfile: $srcfile
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a read session to upload srcfile to server
#
# POST /mimic/agent/{agentNum}/protocol/msg/tftp/session/write/server/{srcfile}
# Returns: list<int>
# operationId: protocol_tftp_session_write
export def "protocol-tftp-session-write" [
  agent_num: int
  srcfile: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: post
    path: "/mimic/agent/{agentNum}/protocol/msg/tftp/session/write/server/{srcfile}"
    path_params: [{name: agentNum, var: agent_num}, {name: srcfile, var: srcfile}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, srcfile: $srcfile
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the agent's TFTP configuration
#
# PUT /mimic/agent/{agentNum}/protocol/msg/tftp/set/config/{argument}/{value}
# Returns: string
# operationId: protocol_tftp_set_config
export def "protocol-tftp-set-config" [
  agent_num: int
  argument: string
  value: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/tftp/set/config/{argument}/{value}"
    path_params: [{name: agentNum, var: agent_num}, {name: argument, var: argument}, {name: value, var: value}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, argument: $argument, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the agent's TFTP traffic tracing
#
# PUT /mimic/agent/{agentNum}/protocol/msg/tftp/set/trace/{enableOrNot}
# Returns: string
# operationId: protocol_tftp_set_trace
export def "protocol-tftp-set-trace" [
  agent_num: int
  enable_or_not: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/tftp/set/trace/{enableOrNot}"
    path_params: [{name: agentNum, var: agent_num}, {name: enableOrNot, var: enable_or_not}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, enable_or_not: $enable_or_not
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show a parameter of a TFTP sesssion
#
# GET /mimic/agent/{agentNum}/protocol/msg/tftp/{sessionID}/get/{parameter}
# Returns: string
# operationId: protocol_tftp_session_get_parameter
export def "protocol-tftp-session-get-parameter" [
  agent_num: int
  session_id: string
  parameter: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/protocol/msg/tftp/{sessionID}/get/{parameter}"
    path_params: [{name: agentNum, var: agent_num}, {name: sessionID, var: session_id}, {name: parameter, var: parameter}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, session_id: $session_id, parameter: $parameter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set a parameter of a TFTP sesssion
#
# PUT /mimic/agent/{agentNum}/protocol/msg/tftp/{sessionID}/set/{parameter}/{value}
# Returns: string
# operationId: protocol_tftp_session_set_parameter
export def "protocol-tftp-session-set-parameter" [
  agent_num: int
  session_id: string
  parameter: string
  value: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/tftp/{sessionID}/set/{parameter}/{value}"
    path_params: [{name: agentNum, var: agent_num}, {name: sessionID, var: session_id}, {name: parameter, var: parameter}, {name: value, var: value}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, session_id: $session_id, parameter: $parameter, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Start a TFTP sesssion
#
# PUT /mimic/agent/{agentNum}/protocol/msg/tftp/{sessionID}/start
# Returns: string
# operationId: protocol_tftp_session_start
export def "protocol-tftp-session-start" [
  agent_num: int
  session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/tftp/{sessionID}/start"
    path_params: [{name: agentNum, var: agent_num}, {name: sessionID, var: session_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, session_id: $session_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check a TFTP sesssion's status
#
# GET /mimic/agent/{agentNum}/protocol/msg/tftp/{sessionID}/status
# Returns: string
# operationId: protocol_tftp_session_status
export def "protocol-tftp-session-status" [
  agent_num: int
  session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/protocol/msg/tftp/{sessionID}/status"
    path_params: [{name: agentNum, var: agent_num}, {name: sessionID, var: session_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, session_id: $session_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stop a TFTP sesssion
#
# PUT /mimic/agent/{agentNum}/protocol/msg/tftp/{sessionID}/stop
# Returns: string
# operationId: protocol_tftp_session_stop
export def "protocol-tftp-session-stop" [
  agent_num: int
  session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/tftp/{sessionID}/stop"
    path_params: [{name: agentNum, var: agent_num}, {name: sessionID, var: session_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, session_id: $session_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the agent's TOD argument structure
#
# GET /mimic/agent/{agentNum}/protocol/msg/tod/get/args
# Returns: record
# operationId: protocol_tod_get_args
export def "protocol-tod-get-args" [
  agent_num: int
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
    path: "/mimic/agent/{agentNum}/protocol/msg/tod/get/args"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the agent's TOD configuration
#
# GET /mimic/agent/{agentNum}/protocol/msg/tod/get/config
# Returns: record<port: int, retries: int, script: string, server: string, timeout: int>
# operationId: protocol_tod_get_config
export def "protocol-tod-get-config" [
  agent_num: int
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
    path: "/mimic/agent/{agentNum}/protocol/msg/tod/get/config"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the agent's TOD statistics
#
# GET /mimic/agent/{agentNum}/protocol/msg/tod/get/statistics
# Returns: list<int>
# operationId: protocol_tod_get_statistics
export def "protocol-tod-get-statistics" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/protocol/msg/tod/get/statistics"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the agent's TOD traffic tracing
#
# GET /mimic/agent/{agentNum}/protocol/msg/tod/get/trace
# Returns: record<port: int, retries: int, script: string, server: string, timeout: int>
# operationId: protocol_tod_get_trace
export def "protocol-tod-get-trace" [
  agent_num: int
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
    path: "/mimic/agent/{agentNum}/protocol/msg/tod/get/trace"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve TOD time
#
# GET /mimic/agent/{agentNum}/protocol/msg/tod/gettime/server/{serverAddr}/port/{portNum}/script/{scriptName}/timeout/{timeSec}/retries/{numRetries}
# Returns: list<string>
# operationId: protocol_tod_gettime
export def "protocol-tod-gettime" [
  agent_num: int
  server_addr: string
  port_num: int
  script_name: string
  time_sec: int
  num_retries: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/protocol/msg/tod/gettime/server/{serverAddr}/port/{portNum}/script/{scriptName}/timeout/{timeSec}/retries/{numRetries}"
    path_params: [{name: agentNum, var: agent_num}, {name: serverAddr, var: server_addr}, {name: portNum, var: port_num}, {name: scriptName, var: script_name}, {name: timeSec, var: time_sec}, {name: numRetries, var: num_retries}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, server_addr: $server_addr, port_num: $port_num, script_name: $script_name, time_sec: $time_sec, num_retries: $num_retries
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the agent's TOD configuration
#
# PUT /mimic/agent/{agentNum}/protocol/msg/tod/set/config/{argument}/{value}
# Returns: string
# operationId: protocol_tod_set_config
export def "protocol-tod-set-config" [
  agent_num: int
  argument: string
  value: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/tod/set/config/{argument}/{value}"
    path_params: [{name: agentNum, var: agent_num}, {name: argument, var: argument}, {name: value, var: value}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, argument: $argument, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the agent's TOD traffic tracing
#
# PUT /mimic/agent/{agentNum}/protocol/msg/tod/set/trace/{enableOrNot}
# Returns: string
# operationId: protocol_tod_set_trace
export def "protocol-tod-set-trace" [
  agent_num: int
  enable_or_not: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/tod/set/trace/{enableOrNot}"
    path_params: [{name: agentNum, var: agent_num}, {name: enableOrNot, var: enable_or_not}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, enable_or_not: $enable_or_not
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the agent's WEB argument structure
#
# GET /mimic/agent/{agentNum}/protocol/msg/web/get/args
# Returns: record
# operationId: protocol_web_get_args
export def "protocol-web-get-args" [
  agent_num: int
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
    path: "/mimic/agent/{agentNum}/protocol/msg/web/get/args"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the agent's WEB configuration
#
# GET /mimic/agent/{agentNum}/protocol/msg/web/get/config
# Returns: record<is_persistent_connections: int, password: string, port: int, rule: string, username: string, wsdl: string>
# operationId: protocol_web_get_config
export def "protocol-web-get-config" [
  agent_num: int
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
    path: "/mimic/agent/{agentNum}/protocol/msg/web/get/config"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the agent's WEB statistics
#
# GET /mimic/agent/{agentNum}/protocol/msg/web/get/statistics
# Returns: list<int>
# operationId: protocol_web_get_statistics
export def "protocol-web-get-statistics" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/protocol/msg/web/get/statistics"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the agent's WEB traffic tracing
#
# GET /mimic/agent/{agentNum}/protocol/msg/web/get/trace
# Returns: record<is_persistent_connections: int, password: string, port: int, rule: string, username: string, wsdl: string>
# operationId: protocol_web_get_trace
export def "protocol-web-get-trace" [
  agent_num: int
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
    path: "/mimic/agent/{agentNum}/protocol/msg/web/get/trace"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add the agent's WEB port
#
# POST /mimic/agent/{agentNum}/protocol/msg/web/port/add/{port}
# Returns: string
# operationId: protocol_web_port_add
export def "protocol-web-port-add" [
  agent_num: int
  port: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: post
    path: "/mimic/agent/{agentNum}/protocol/msg/web/port/add/{port}"
    path_params: [{name: agentNum, var: agent_num}, {name: port, var: port}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, port: $port
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the agent's WEB port
#
# GET /mimic/agent/{agentNum}/protocol/msg/web/port/exists/{port}
# Returns: list<string>
# operationId: protocol_web_port_exists
export def "protocol-web-port-exists" [
  agent_num: int
  port: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/protocol/msg/web/port/exists/{port}"
    path_params: [{name: agentNum, var: agent_num}, {name: port, var: port}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, port: $port
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove the agent's WEB port
#
# DELETE /mimic/agent/{agentNum}/protocol/msg/web/port/remove/{port}
# Returns: string
# operationId: protocol_web_port_remove
export def "protocol-web-port-remove" [
  agent_num: int
  port: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/mimic/agent/{agentNum}/protocol/msg/web/port/remove/{port}"
    path_params: [{name: agentNum, var: agent_num}, {name: port, var: port}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, port: $port
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the agent's WEB port attribute
#
# PUT /mimic/agent/{agentNum}/protocol/msg/web/port/set/{port}/{protocol}/{version}
# Returns: string
# operationId: protocol_web_port_set
export def "protocol-web-port-set" [
  agent_num: int
  port: int
  protocol: string
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
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/web/port/set/{port}/{protocol}/{version}"
    path_params: [{name: agentNum, var: agent_num}, {name: port, var: port}, {name: protocol, var: protocol}, {name: version, var: version}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, port: $port, protocol: $protocol, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Start the agent's WEB port
#
# PUT /mimic/agent/{agentNum}/protocol/msg/web/port/start/{port}
# Returns: string
# operationId: protocol_web_port_start
export def "protocol-web-port-start" [
  agent_num: int
  port: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/web/port/start/{port}"
    path_params: [{name: agentNum, var: agent_num}, {name: port, var: port}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, port: $port
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stop the agent's WEB port
#
# PUT /mimic/agent/{agentNum}/protocol/msg/web/port/stop/{port}
# Returns: string
# operationId: protocol_web_port_stop
export def "protocol-web-port-stop" [
  agent_num: int
  port: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/web/port/stop/{port}"
    path_params: [{name: agentNum, var: agent_num}, {name: port, var: port}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, port: $port
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the agent's WEB configuration
#
# PUT /mimic/agent/{agentNum}/protocol/msg/web/set/config/{argument}/{value}
# Returns: string
# operationId: protocol_web_set_config
export def "protocol-web-set-config" [
  agent_num: int
  argument: string
  value: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/web/set/config/{argument}/{value}"
    path_params: [{name: agentNum, var: agent_num}, {name: argument, var: argument}, {name: value, var: value}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, argument: $argument, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the agent's WEB traffic tracing
#
# PUT /mimic/agent/{agentNum}/protocol/msg/web/set/trace/{enableOrNot}
# Returns: string
# operationId: protocol_web_set_trace
export def "protocol-web-set-trace" [
  agent_num: int
  enable_or_not: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/protocol/msg/web/set/trace/{enableOrNot}"
    path_params: [{name: agentNum, var: agent_num}, {name: enableOrNot, var: enable_or_not}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, enable_or_not: $enable_or_not
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the protocol's configuration.
#
# GET /mimic/agent/{agentNum}/protocol/{prot}/get/config
# Returns: record
# operationId: protocol_get_config
export def "protocol-get-config" [
  agent_num: int
  prot: string
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
    path: "/mimic/agent/{agentNum}/protocol/{prot}/get/config"
    path_params: [{name: agentNum, var: agent_num}, {name: prot, var: prot}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, prot: $prot
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reload the current agent.
#
# PUT /mimic/agent/{agentNum}/reload
# Returns: string
# operationId: reload
export def "reload" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/reload"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove the current agent.
#
# DELETE /mimic/agent/{agentNum}/remove
# Returns: string
# operationId: agent_remove
export def "agent-remove" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/mimic/agent/{agentNum}/remove"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resume the current agent.
#
# PUT /mimic/agent/{agentNum}/resume
# Returns: string
# operationId: resume
export def "resume" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/resume"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Save agent MIB values.
#
# PUT /mimic/agent/{agentNum}/save
# Returns: string
# operationId: save
export def "put-mimic-agent-agent-num-save" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/save"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# one-way transit delay in msec
#
# PUT /mimic/agent/{agentNum}/set/delay/{delay}
# Returns: int
# operationId: set_delay
export def "set-delay" [
  agent_num: int
  delay: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/set/delay/{delay}"
    path_params: [{name: agentNum, var: agent_num}, {name: delay, var: delay}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, delay: $delay
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# drop rate (every N-th PDU)
#
# PUT /mimic/agent/{agentNum}/set/drops/{drops}
# Returns: int
# operationId: set_drops
export def "set-drops" [
  agent_num: int
  drops: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/set/drops/{drops}"
    path_params: [{name: agentNum, var: agent_num}, {name: drops, var: drops}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, drops: $drops
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# host address of the agent.
#
# PUT /mimic/agent/{agentNum}/set/host/{host}
# Returns: string
# operationId: set_host
export def "set-host" [
  agent_num: int
  host: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/set/host/{host}"
    path_params: [{name: agentNum, var: agent_num}, {name: host, var: host}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, host: $host
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# timeout in seconds for retransmitting INFORM PDUs
#
# PUT /mimic/agent/{agentNum}/set/inform_timeout/{inform_timeout}
# Returns: int
# operationId: set_inform_timeout
export def "set-inform-timeout" [
  agent_num: int
  inform_timeout: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/set/inform_timeout/{inform_timeout}"
    path_params: [{name: agentNum, var: agent_num}, {name: inform_timeout, var: inform_timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, inform_timeout: $inform_timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# network interface card for the agent
#
# PUT /mimic/agent/{agentNum}/set/interface/{interface}
# Returns: string
# operationId: set_interface
export def "set-interface" [
  agent_num: int
  interface: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/set/interface/{interface}"
    path_params: [{name: agentNum, var: agent_num}, {name: interface, var: interface}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, interface: $interface
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# subnet mask of the agent.
#
# PUT /mimic/agent/{agentNum}/set/mask/{mask}
# Returns: string
# operationId: set_mask
export def "set-mask" [
  agent_num: int
  mask: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/set/mask/{mask}"
    path_params: [{name: agentNum, var: agent_num}, {name: mask, var: mask}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, mask: $mask
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# set of MIBs, simulations and scenarios
#
# PUT /mimic/agent/{agentNum}/set/mibs
# Returns: string
# operationId: set_mibs
export def "set-mibs" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> any {
  $in | http-request {
    method: put
    path: "/mimic/agent/{agentNum}/set/mibs"
    path_params: [{name: agentNum, var: agent_num}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# MIB directory of the agent.
#
# PUT /mimic/agent/{agentNum}/set/oiddir/{oiddir}
# Returns: string
# operationId: set_oiddir
export def "set-oiddir" [
  agent_num: int
  oiddir: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/set/oiddir/{oiddir}"
    path_params: [{name: agentNum, var: agent_num}, {name: oiddir, var: oiddir}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, oiddir: $oiddir
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# owner of the agent
#
# PUT /mimic/agent/{agentNum}/set/owner/{owner}
# Returns: string
# operationId: set_owner
export def "set-owner" [
  agent_num: int
  owner: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/set/owner/{owner}"
    path_params: [{name: agentNum, var: agent_num}, {name: owner, var: owner}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, owner: $owner
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# maximum PDU size
#
# PUT /mimic/agent/{agentNum}/set/pdusize/{pdusize}
# Returns: int
# operationId: set_pdusize
export def "set-pdusize" [
  agent_num: int
  pdusize: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/set/pdusize/{pdusize}"
    path_params: [{name: agentNum, var: agent_num}, {name: pdusize, var: pdusize}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, pdusize: $pdusize
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# port number
#
# PUT /mimic/agent/{agentNum}/set/port/{port}
# Returns: string
# operationId: set_port
export def "set-port" [
  agent_num: int
  port: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/set/port/{port}"
    path_params: [{name: agentNum, var: agent_num}, {name: port, var: port}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, port: $port
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# private directory of the agent.
#
# PUT /mimic/agent/{agentNum}/set/privdir/{privdir}
# Returns: string
# operationId: set_privdir
export def "set-privdir" [
  agent_num: int
  privdir: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/set/privdir/{privdir}"
    path_params: [{name: agentNum, var: agent_num}, {name: privdir, var: privdir}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, privdir: $privdir
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# protocols supported by agent as a comma-separated list
#
# PUT /mimic/agent/{agentNum}/set/protocol
# Returns: list<int>
# operationId: set_protocols
export def "set-protocols" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: put
    path: "/mimic/agent/{agentNum}/set/protocol"
    path_params: [{name: agentNum, var: agent_num}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# read community string
#
# PUT /mimic/agent/{agentNum}/set/read/{read}
# Returns: string
# operationId: set_read_community
export def "set-read-community" [
  agent_num: int
  read: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/set/read/{read}"
    path_params: [{name: agentNum, var: agent_num}, {name: read, var: read}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, read: $read
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# relative start time
#
# PUT /mimic/agent/{agentNum}/set/start/{start}
# Returns: string
# operationId: set_starttime
export def "set-starttime" [
  agent_num: int
  start: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/set/start/{start}"
    path_params: [{name: agentNum, var: agent_num}, {name: start, var: start}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, start: $start
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# SNMP PDU tracing
#
# PUT /mimic/agent/{agentNum}/set/trace/{trace}
# Returns: int
# operationId: set_trace
export def "set-trace" [
  agent_num: int
  trace: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/set/trace/{trace}"
    path_params: [{name: agentNum, var: agent_num}, {name: trace, var: trace}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, trace: $trace
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# SNMP SET validation policy
#
# PUT /mimic/agent/{agentNum}/set/validate/{validate}
# Returns: int
# operationId: set_validate
export def "set-validate" [
  agent_num: int
  validate: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/set/validate/{validate}"
    path_params: [{name: agentNum, var: agent_num}, {name: validate, var: validate}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, validate: $validate
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# write community string
#
# PUT /mimic/agent/{agentNum}/set/write/{write}
# Returns: string
# operationId: set_write_community
export def "set-write-community" [
  agent_num: int
  write: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/set/write/{write}"
    path_params: [{name: agentNum, var: agent_num}, {name: write, var: write}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, write: $write
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Start the current agent.
#
# PUT /mimic/agent/{agentNum}/start
# Returns: string
# operationId: start
export def "put-mimic-agent-agent-num-start" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/start"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the agent's primary IP address
#
# PUT /mimic/agent/{agentNum}/stop
# Returns: string
# operationId: stop
export def "stop" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/stop"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This command copies the variable store from the other agent to this agent.
#
# PUT /mimic/agent/{agentNum}/store/copy/{otherAgent}
# Returns: string
# operationId: agent_store_copy
export def "agent-store-copy" [
  agent_num: int
  other_agent: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/store/copy/{otherAgent}"
    path_params: [{name: agentNum, var: agent_num}, {name: otherAgent, var: other_agent}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, other_agent: $other_agent
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This command can be used as a predicate to ascertain the existence of a given variable.
#
# GET /mimic/agent/{agentNum}/store/exists/{var}
# Returns: string
# operationId: agent_store_exists
export def "agent-store-exists" [
  agent_num: int
  var: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/store/exists/{var}"
    path_params: [{name: agentNum, var: agent_num}, {name: var, var: var}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, var: $var
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetches the value associated with a variable.
#
# GET /mimic/agent/{agentNum}/store/get/{var}
# Returns: string
# operationId: agent_store_get
export def "agent-store-get" [
  agent_num: int
  var: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/store/get/{var}"
    path_params: [{name: agentNum, var: agent_num}, {name: var, var: var}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, var: $var
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This command will return the list of variables in the said scope.
#
# GET /mimic/agent/{agentNum}/store/list
# Returns: list<string>
# operationId: agent_store_list
export def "agent-store-list" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/store/list"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# These commands treat the variable as a list, and allow to replace an entry in the list at the specified index with the specified value. The variable has to already exist.
#
# PUT /mimic/agent/{agentNum}/store/lreplace/{var}/{index}
# Returns: string
# operationId: agent_store_lreplace
export def "agent-store-lreplace" [
  agent_num: int
  var: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/mimic/agent/{agentNum}/store/lreplace/{var}/{index}"
    path_params: [{name: agentNum, var: agent_num}, {name: var, var: var}, {name: index, var: index}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, var: $var, index: $index, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This command can be used as a predicate to ascertain the persistence of a given variable.
#
# GET /mimic/agent/{agentNum}/store/persists/{var}
# Returns: string
# operationId: agent_store_persists
export def "agent-store-persists" [
  agent_num: int
  var: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/store/persists/{var}"
    path_params: [{name: agentNum, var: agent_num}, {name: var, var: var}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, var: $var
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# These commands allow the creation of a new variable, or changing an existing value.
#
# PUT /mimic/agent/{agentNum}/store/set/{var}/{persist}
# Returns: string
# operationId: agent_store_set
export def "agent-store-set" [
  agent_num: int
  var: string
  persist: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/mimic/agent/{agentNum}/store/set/{var}/{persist}"
    path_params: [{name: agentNum, var: agent_num}, {name: var, var: var}, {name: persist, var: persist}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, var: $var, persist: $persist, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a variable which is currently defined.
#
# PUT /mimic/agent/{agentNum}/store/unset/{var}
# Returns: string
# operationId: agent_store_unset
export def "agent-store-unset" [
  agent_num: int
  var: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/store/unset/{var}"
    path_params: [{name: agentNum, var: agent_num}, {name: var, var: var}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, var: $var
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a new timer script to be executed at specified interval (in msec) with the specified argument.
#
# POST /mimic/agent/{agentNum}/timer/script/add/{script}/{interval}/{arg}
# Returns: string
# operationId: add_timer_script
export def "add-timer-script" [
  agent_num: int
  script: string
  interval: int
  arg: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: post
    path: "/mimic/agent/{agentNum}/timer/script/add/{script}/{interval}/{arg}"
    path_params: [{name: agentNum, var: agent_num}, {name: script, var: script}, {name: interval, var: interval}, {name: arg, var: arg}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, script: $script, interval: $interval, arg: $arg
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a timer script from the execution list.
#
# DELETE /mimic/agent/{agentNum}/timer/script/delete/{script}/{interval}/{arg}
# Returns: string
# operationId: del_timer_script
export def "del-timer-script" [
  agent_num: int
  script: string
  interval: int
  arg: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/mimic/agent/{agentNum}/timer/script/delete/{script}/{interval}/{arg}"
    path_params: [{name: agentNum, var: agent_num}, {name: script, var: script}, {name: interval, var: interval}, {name: arg, var: arg}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, script: $script, interval: $interval, arg: $arg
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the timer scripts currently running along with the their intervals.
#
# GET /mimic/agent/{agentNum}/timer/script/list
# Returns: table<arg: string, interval: int, script: string>
# operationId: list_timer_scripts
export def "list-timer-scripts" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/timer/script/list"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a trap destination to the set of destinations.
#
# POST /mimic/agent/{agentNum}/trap/config/add/{IP}/{port}
# Returns: string
# operationId: trap_config_add
export def "trap-config-add" [
  agent_num: int
  ip: string
  port: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: post
    path: "/mimic/agent/{agentNum}/trap/config/add/{IP}/{port}"
    path_params: [{name: agentNum, var: agent_num}, {name: IP, var: ip}, {name: port, var: port}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, ip: $ip, port: $port
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a trap destination from the set of destinations.
#
# DELETE /mimic/agent/{agentNum}/trap/config/delete/{IP}/{port}
# Returns: string
# operationId: trap_config_del
export def "trap-config-del" [
  agent_num: int
  ip: string
  port: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/mimic/agent/{agentNum}/trap/config/delete/{IP}/{port}"
    path_params: [{name: agentNum, var: agent_num}, {name: IP, var: ip}, {name: port, var: port}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, ip: $ip, port: $port
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the set of trap destinations for this agent instance.
#
# GET /mimic/agent/{agentNum}/trap/config/list
# Returns: table<IP: string, port: int>
# operationId: trap_config_list
export def "trap-config-list" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/trap/config/list"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the outstanding asynchronous traps for this agent instance.
#
# GET /mimic/agent/{agentNum}/trap/list
# Returns: list<string>
# operationId: trap_list
export def "trap-list" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/trap/list"
    path_params: [{name: agentNum, var: agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add an entry to a table.
#
# POST /mimic/agent/{agentNum}/value/add/{object}/{instance}
# Returns: string
# operationId: add
export def "add" [
  agent_num: int
  object: string
  instance: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: post
    path: "/mimic/agent/{agentNum}/value/add/{object}/{instance}"
    path_params: [{name: agentNum, var: agent_num}, {name: object, var: object}, {name: instance, var: instance}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, object: $object, instance: $instance
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Evaluate the values of the specified instance instance for each specified MIB object object and return it as it would through SNMP requests.
#
# GET /mimic/agent/{agentNum}/value/eval/{object}/{instance}
# Returns: string
# operationId: eval_value
export def "eval-value" [
  agent_num: int
  object: string
  instance: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/value/eval/{object}/{instance}"
    path_params: [{name: agentNum, var: agent_num}, {name: object, var: object}, {name: instance, var: instance}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, object: $object, instance: $instance
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a variable in the Value Space.
#
# GET /mimic/agent/{agentNum}/value/get/{object}/{instance}/{variable}
# Returns: string
# operationId: get_value
export def "get-value" [
  agent_num: int
  object: string
  instance: string
  variable: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/value/get/{object}/{instance}/{variable}"
    path_params: [{name: agentNum, var: agent_num}, {name: object, var: object}, {name: instance, var: instance}, {name: variable, var: variable}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, object: $object, instance: $instance, variable: $variable
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return the syntactical information for the specified object, such as type, size, range, enumerations, and ACCESS.
#
# GET /mimic/agent/{agentNum}/value/info/{object}
# Returns: string
# operationId: get_info
export def "get-info" [
  agent_num: int
  object: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/value/info/{object}"
    path_params: [{name: agentNum, var: agent_num}, {name: object, var: object}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, object: $object
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Display the MIB object instances for the specified object.
#
# GET /mimic/agent/{agentNum}/value/instances/{object}
# Returns: list<string>
# operationId: get_instances
export def "get-instances" [
  agent_num: int
  object: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/value/instances/{object}"
    path_params: [{name: agentNum, var: agent_num}, {name: object, var: object}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, object: $object
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Display the MIB objects below the current position
#
# GET /mimic/agent/{agentNum}/value/list/{OID}
# Returns: list<string>
# operationId: get_objects
export def "get-objects" [
  agent_num: int
  oid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/value/list/{OID}"
    path_params: [{name: agentNum, var: agent_num}, {name: OID, var: oid}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, oid: $oid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Evaluate the values of the specified instance instance for each specified MIB object object and return it as it would through SNMP requests.
#
# GET /mimic/agent/{agentNum}/value/meval/{objInsArray}
# Returns: list<string>
# operationId: meval_value
export def "meval-value" [
  agent_num: int
  obj_ins_array: list
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/value/meval/{objInsArray}"
    path_params: [{name: agentNum, var: agent_num}, {name: objInsArray, var: obj_ins_array, encode: array}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, obj_ins_array: $obj_ins_array
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get multiple variables in the Value Space.
#
# GET /mimic/agent/{agentNum}/value/mget/{objInsVarArray}
# Returns: list<string>
# operationId: mget_value
export def "mget-value" [
  agent_num: int
  obj_ins_var_array: list
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/value/mget/{objInsVarArray}"
    path_params: [{name: agentNum, var: agent_num}, {name: objInsVarArray, var: obj_ins_var_array, encode: array}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, obj_ins_var_array: $obj_ins_var_array
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return the MIB that defines the specified object.
#
# GET /mimic/agent/{agentNum}/value/mib/{object}
# Returns: string
# operationId: get_mib
export def "get-mib" [
  agent_num: int
  object: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/value/mib/{object}"
    path_params: [{name: agentNum, var: agent_num}, {name: object, var: object}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, object: $object
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set multiple variables in the Value Space.
#
# PUT /mimic/agent/{agentNum}/value/mset
# Returns: string
# operationId: mset_value
export def "mset-value" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> any {
  $in | http-request {
    method: put
    path: "/mimic/agent/{agentNum}/value/mset"
    path_params: [{name: agentNum, var: agent_num}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unset multiple variables in the Value Space
#
# PUT /mimic/agent/{agentNum}/value/munset
# Returns: string
# operationId: munset_value
export def "munset-value" [
  agent_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> any {
  $in | http-request {
    method: put
    path: "/mimic/agent/{agentNum}/value/munset"
    path_params: [{name: agentNum, var: agent_num}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return the symbolic name of the specified object identifier.
#
# GET /mimic/agent/{agentNum}/value/name/{OID}
# Returns: string
# operationId: get_name
export def "get-name" [
  agent_num: int
  oid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/value/name/{OID}"
    path_params: [{name: agentNum, var: agent_num}, {name: OID, var: oid}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, oid: $oid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return the numeric OID of the specified object.
#
# GET /mimic/agent/{agentNum}/value/oid/{object}
# Returns: string
# operationId: get_oid
export def "get-oid" [
  agent_num: int
  object: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/value/oid/{object}"
    path_params: [{name: agentNum, var: agent_num}, {name: object, var: object}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, object: $object
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove an entry from a table.
#
# DELETE /mimic/agent/{agentNum}/value/remove/{object}/{instance}
# Returns: string
# operationId: remove
export def "remove" [
  agent_num: int
  object: string
  instance: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/mimic/agent/{agentNum}/value/remove/{object}/{instance}"
    path_params: [{name: agentNum, var: agent_num}, {name: object, var: object}, {name: instance, var: instance}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, object: $object, instance: $instance
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set a variable in the Value Space.
#
# PUT /mimic/agent/{agentNum}/value/set/{object}/{instance}/{variable}
# Returns: string
# operationId: set_value
export def "set-value" [
  agent_num: int
  object: string
  instance: string
  variable: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/mimic/agent/{agentNum}/value/set/{object}/{instance}/{variable}"
    path_params: [{name: agentNum, var: agent_num}, {name: object, var: object}, {name: instance, var: instance}, {name: variable, var: variable}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, object: $object, instance: $instance, variable: $variable, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Split the numerical OID into the object OID and instance OID.
#
# GET /mimic/agent/{agentNum}/value/split/{OID}
# Returns: list<string>
# operationId: split_oid
export def "split-oid" [
  agent_num: int
  oid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/value/split/{OID}"
    path_params: [{name: agentNum, var: agent_num}, {name: OID, var: oid}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, oid: $oid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the state of a MIB object object.
#
# GET /mimic/agent/{agentNum}/value/state/get/{object}
# Returns: string
# operationId: get_state
export def "get-state" [
  agent_num: int
  object: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/value/state/get/{object}"
    path_params: [{name: agentNum, var: agent_num}, {name: object, var: object}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, object: $object
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the state of a MIB object object
#
# PUT /mimic/agent/{agentNum}/value/state/set/{object}/{state}
# Returns: string
# operationId: set_state
export def "set-state" [
  agent_num: int
  object: string
  state: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/value/state/set/{object}/{state}"
    path_params: [{name: agentNum, var: agent_num}, {name: object, var: object}, {name: state, var: state}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, object: $object, state: $state
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unset a variable in the Value Space in order to free its memory.
#
# PUT /mimic/agent/{agentNum}/value/unset/{object}/{instance}/{variable}
# Returns: string
# operationId: unset_value
export def "unset-value" [
  agent_num: int
  object: string
  instance: string
  variable: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/agent/{agentNum}/value/unset/{object}/{instance}/{variable}"
    path_params: [{name: agentNum, var: agent_num}, {name: object, var: object}, {name: instance, var: instance}, {name: variable, var: variable}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, object: $object, instance: $instance, variable: $variable
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Display the variables for the specified instance instance for the specified MIB object object
#
# GET /mimic/agent/{agentNum}/value/variables/{object}/{instance}
# Returns: list<string>
# operationId: get_variables
export def "get-variables" [
  agent_num: int
  object: string
  instance: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/agent/{agentNum}/value/variables/{object}/{instance}"
    path_params: [{name: agentNum, var: agent_num}, {name: object, var: object}, {name: instance, var: instance}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    agent_num: $agent_num, object: $object, instance: $instance
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Clear the lab configuration.
#
# PUT /mimic/clear/{firstAgentNum}/{lastAgentNum}
# Returns: record
# operationId: cfg_new
export def "cfg-new" [
  first_agent_num: int
  last_agent_num: int
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
    method: put
    path: "/mimic/clear/{firstAgentNum}/{lastAgentNum}"
    path_params: [{name: firstAgentNum, var: first_agent_num}, {name: lastAgentNum, var: last_agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    first_agent_num: $first_agent_num, last_agent_num: $last_agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The list of {agentnum {statistics}} for agents that are currently active and whose statistics have changed since the last invocation of this command.
#
# GET /mimic/get/active_data_list
# Returns: list<int>
# operationId: get_active_data_list
export def "get-active-data-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/get/active_data_list"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The list of {agentnum} that are currently active (running or paused).
#
# GET /mimic/get/active_list
# Returns: list<int>
# operationId: get_active_list
export def "get-active-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/get/active_list"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The currently loaded lab configuration file for the particular user.
#
# GET /mimic/get/cfgfile
# Returns: record
# operationId: get_cfgfile
export def "get-cfgfile" [
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
    path: "/mimic/get/cfgfile"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This predicate indicates if the currently loaded agent configuration file has changed.
#
# GET /mimic/get/cfgfile_changed
# Returns: record
# operationId: get_cfg_file_changed
export def "get-cfg-file-changed" [
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
    path: "/mimic/get/cfgfile_changed"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The list of {agentnum} for which a configurable parameter changed.
#
# GET /mimic/get/changed_config_list
# Returns: list<int>
# operationId: get_changed_config_list
export def "get-changed-config-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/get/changed_config_list"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The list of {agentnum state} for which the state changed.
#
# GET /mimic/get/changed_state_list
# Returns: table<agentNum: int, state: int>
# operationId: get_changed_state_list
export def "get-changed-state-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/get/changed_state_list"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The number of clients currently connected to the daemon.
#
# GET /mimic/get/clients
# Returns: record
# operationId: get_clients
export def "get-clients" [
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
    path: "/mimic/get/clients"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The list of {agentnum} that are currently configured.
#
# GET /mimic/get/configured_list
# Returns: list<int>
# operationId: get_configured_list
export def "get-configured-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/get/configured_list"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The set of network interfaces that can be used for simulations.
#
# GET /mimic/get/interfaces
# Returns: record
# operationId: get_interfaces
export def "get-interfaces" [
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
    path: "/mimic/get/interfaces"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The last configured agent instance.
#
# GET /mimic/get/last
# Returns: int
# operationId: get_last
export def "get-last" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/mimic/get/last"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The current log file for the Simulator.
#
# GET /mimic/get/log
# Returns: record
# operationId: get_log
export def "get-log" [
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
    path: "/mimic/get/log"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The maximum number of agent instances.
#
# GET /mimic/get/max
# Returns: int
# operationId: get_max
export def "get-max" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/mimic/get/max"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The network address of the host where the MIMIC simulator is running.
#
# GET /mimic/get/netaddr
# Returns: record
# operationId: get_netaddr
export def "get-netaddr" [
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
    path: "/mimic/get/netaddr"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The default network device to be used for agent addresses.
#
# GET /mimic/get/netdev
# Returns: record
# operationId: get_netdev
export def "get-netdev" [
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
    path: "/mimic/get/netdev"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The product number that is licensed.
#
# GET /mimic/get/product
# Returns: record
# operationId: get_product
export def "get-product" [
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
    path: "/mimic/get/product"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The set of protocols supported by the Simulator.
#
# GET /mimic/get/protocols
# Returns: record
# operationId: get_daemon_protocols
export def "get-daemon-protocols" [
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
    path: "/mimic/get/protocols"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The return mode.
#
# GET /mimic/get/return
# Returns: record
# operationId: get_return
export def "get-return" [
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
    path: "/mimic/get/return"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The version of the MIMIC command interface.
#
# GET /mimic/get/version
# Returns: string
# operationId: get_version
export def "get-version" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/mimic/get/version"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Load the lab configuration file file.
#
# PUT /mimic/load/{cfgFile}/{firstAgentNum}/{lastAgentNum}/{startAgentNum}
# Returns: record
# operationId: cfg_load
export def "cfg-load" [
  cfg_file: string
  first_agent_num: int
  last_agent_num: int
  start_agent_num: int
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
    method: put
    path: "/mimic/load/{cfgFile}/{firstAgentNum}/{lastAgentNum}/{startAgentNum}"
    path_params: [{name: cfgFile, var: cfg_file}, {name: firstAgentNum, var: first_agent_num}, {name: lastAgentNum, var: last_agent_num}, {name: startAgentNum, var: start_agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    cfg_file: $cfg_file, first_agent_num: $first_agent_num, last_agent_num: $last_agent_num, start_agent_num: $start_agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get multiple sets of information about MIMIC, where infoArray is one of the parameters defined in the mimic get command.
#
# GET /mimic/mget/{infoArray}
# Returns: list<record>
# operationId: mget_info
export def "mget-info" [
  info_array: list<string>
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/mget/{infoArray}"
    path_params: [{name: infoArray, var: info_array, encode: array}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    info_array: $info_array
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the COAP statistics headers
#
# GET /mimic/protocol/msg/coap/get/stats_hdr
# Returns: list<string>
# operationId: protocol_coap_get_stats_hdr
export def "protocol-coap-get-stats-hdr" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/protocol/msg/coap/get/stats_hdr"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the DHCP statistics headers
#
# GET /mimic/protocol/msg/dhcp/get/stats_hdr
# Returns: list<string>
# operationId: protocol_dhcp_get_stats_hdr
export def "protocol-dhcp-get-stats-hdr" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/protocol/msg/dhcp/get/stats_hdr"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the IPMI statistics headers
#
# GET /mimic/protocol/msg/ipmi/get/stats_hdr
# Returns: list<string>
# operationId: protocol_ipmi_get_stats_hdr
export def "protocol-ipmi-get-stats-hdr" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/protocol/msg/ipmi/get/stats_hdr"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the MQTT statistics headers
#
# GET /mimic/protocol/msg/mqtt/get/stats_hdr
# Returns: list<string>
# operationId: protocol_mqtt_get_stats_hdr
export def "protocol-mqtt-get-stats-hdr" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/protocol/msg/mqtt/get/stats_hdr"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the NETFLOW statistics headers
#
# GET /mimic/protocol/msg/netflow/get/stats_hdr
# Returns: list<string>
# operationId: protocol_netflow_get_stats_hdr
export def "protocol-netflow-get-stats-hdr" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/protocol/msg/netflow/get/stats_hdr"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the PROXY statistics headers
#
# GET /mimic/protocol/msg/proxy/get/stats_hdr
# Returns: list<string>
# operationId: protocol_proxy_get_stats_hdr
export def "protocol-proxy-get-stats-hdr" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/protocol/msg/proxy/get/stats_hdr"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the SFLOW statistics headers
#
# GET /mimic/protocol/msg/sflow/get/stats_hdr
# Returns: list<string>
# operationId: protocol_sflow_get_stats_hdr
export def "protocol-sflow-get-stats-hdr" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/protocol/msg/sflow/get/stats_hdr"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the SNMPTCP statistics headers
#
# GET /mimic/protocol/msg/snmptcp/get/stats_hdr
# Returns: list<string>
# operationId: protocol_snmptcp_get_stats_hdr
export def "protocol-snmptcp-get-stats-hdr" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/protocol/msg/snmptcp/get/stats_hdr"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the SSH statistics headers
#
# GET /mimic/protocol/msg/ssh/get/stats_hdr
# Returns: list<string>
# operationId: protocol_ssh_get_stats_hdr
export def "protocol-ssh-get-stats-hdr" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/protocol/msg/ssh/get/stats_hdr"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the SYSLOG statistics headers
#
# GET /mimic/protocol/msg/syslog/get/stats_hdr
# Returns: list<string>
# operationId: protocol_syslog_get_stats_hdr
export def "protocol-syslog-get-stats-hdr" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/protocol/msg/syslog/get/stats_hdr"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the TELNET statistics headers
#
# GET /mimic/protocol/msg/telnet/get/stats_hdr
# Returns: list<string>
# operationId: protocol_telnet_get_stats_hdr
export def "protocol-telnet-get-stats-hdr" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/protocol/msg/telnet/get/stats_hdr"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the TFTP statistics headers
#
# GET /mimic/protocol/msg/tftp/get/stats_hdr
# Returns: list<string>
# operationId: protocol_tftp_get_stats_hdr
export def "protocol-tftp-get-stats-hdr" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/protocol/msg/tftp/get/stats_hdr"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the TOD statistics headers
#
# GET /mimic/protocol/msg/tod/get/stats_hdr
# Returns: list<string>
# operationId: protocol_tod_get_stats_hdr
export def "protocol-tod-get-stats-hdr" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/protocol/msg/tod/get/stats_hdr"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the WEB statistics headers
#
# GET /mimic/protocol/msg/web/get/stats_hdr
# Returns: list<string>
# operationId: protocol_web_get_stats_hdr
export def "protocol-web-get-stats-hdr" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/protocol/msg/web/get/stats_hdr"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Save the lab configuration.
#
# PUT /mimic/save
# Returns: record
# operationId: cfg_save
export def "cfg-save" [
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
    method: put
    path: "/mimic/save"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Save the lab configuration in file.
#
# PUT /mimic/saveas/{cfgFile}/{firstAgentNum}/{lastAgentNum}
# Returns: record
# operationId: cfg_saveas
export def "cfg-saveas" [
  cfg_file: string
  first_agent_num: int
  last_agent_num: int
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
    method: put
    path: "/mimic/saveas/{cfgFile}/{firstAgentNum}/{lastAgentNum}"
    path_params: [{name: cfgFile, var: cfg_file}, {name: firstAgentNum, var: first_agent_num}, {name: lastAgentNum, var: last_agent_num}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    cfg_file: $cfg_file, first_agent_num: $first_agent_num, last_agent_num: $last_agent_num
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The current log file for the Simulator.
#
# PUT /mimic/set/log
# Returns: string
# operationId: set_log
export def "set-log" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/mimic/set/log"
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The network address of the host where the MIMIC simulator is running.
#
# PUT /mimic/set/netdev
# Returns: record
# operationId: set_netdev
export def "set-netdev" [
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
    method: put
    path: "/mimic/set/netdev"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This operation flushes all global objects which need to be made persistent to disk.
#
# PUT /mimic/set/persistent
# Returns: record
# operationId: store_save
export def "store-save" [
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
    method: put
    path: "/mimic/set/persistent"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Start MIMIC.
#
# PUT /mimic/start
# Returns: record
# operationId: start_all_agents
export def "start-all-agents" [
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
    method: put
    path: "/mimic/start"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stop MIMIC.
#
# PUT /mimic/stop
# Returns: record
# operationId: stop_all_agents
export def "stop-all-agents" [
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
    method: put
    path: "/mimic/stop"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This command can be used as a predicate to ascertain the existence of a given variable.
#
# GET /mimic/store/exists/{var}
# Returns: string
# operationId: store_exists
export def "store-exists" [
  var: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/mimic/store/exists/{var}"
    path_params: [{name: var, var: var}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    var: $var
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetches the value associated with a variable.
#
# GET /mimic/store/get/{var}
# Returns: string
# operationId: store_get
export def "store-get" [
  var: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/mimic/store/get/{var}"
    path_params: [{name: var, var: var}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    var: $var
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This command will return the list of variables in the said scope.
#
# GET /mimic/store/list
# Returns: list<string>
# operationId: store_list
export def "store-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/store/list"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# These commands treat the variable as a list, and allow to replace an entry in the list at the specified index with the specified value. The variable has to already exist.
#
# PUT /mimic/store/lreplace/{var}/{index}
# Returns: string
# operationId: store_lreplace
export def "store-lreplace" [
  var: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/mimic/store/lreplace/{var}/{index}"
    path_params: [{name: var, var: var}, {name: index, var: index}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    var: $var, index: $index, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This command can be used as a predicate to ascertain the persistence of a given variable.
#
# GET /mimic/store/persists/{var}
# Returns: string
# operationId: store_persists
export def "store-persists" [
  var: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/mimic/store/persists/{var}"
    path_params: [{name: var, var: var}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    var: $var
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the variable store for the global storage
#
# PUT /mimic/store/set/{var}/{persist}
# Returns: string
# operationId: store_set
export def "store-set" [
  var: string
  persist: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/mimic/store/set/{var}/{persist}"
    path_params: [{name: var, var: var}, {name: persist, var: persist}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    var: $var, persist: $persist, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a variable which is currently defined.
#
# PUT /mimic/store/unset/{var}
# Returns: string
# operationId: store_unset
export def "store-unset" [
  var: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: put
    path: "/mimic/store/unset/{var}"
    path_params: [{name: var, var: var}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    var: $var
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Terminate the MIMIC daemon.
#
# PUT /mimic/terminate
# Returns: record
# operationId: terminate
export def "terminate" [
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
    method: put
    path: "/mimic/terminate"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a new timer script to be executed at specified interval (in msec) with the specified argument.
#
# POST /mimic/timer/script/add/{script}/{interval}/{arg}
# Returns: string
# operationId: add_daemon_timer_script
export def "add-daemon-timer-script" [
  script: string
  interval: int
  arg: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: post
    path: "/mimic/timer/script/add/{script}/{interval}/{arg}"
    path_params: [{name: script, var: script}, {name: interval, var: interval}, {name: arg, var: arg}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    script: $script, interval: $interval, arg: $arg
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a timer script from the execution list.
#
# DELETE /mimic/timer/script/delete/{script}/{interval}/{arg}
# Returns: string
# operationId: del_daemon_timer_script
export def "del-daemon-timer-script" [
  script: string
  interval: int
  arg: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/mimic/timer/script/delete/{script}/{interval}/{arg}"
    path_params: [{name: script, var: script}, {name: interval, var: interval}, {name: arg, var: arg}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    script: $script, interval: $interval, arg: $arg
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the timer scripts currently running along with the their intervals.
#
# GET /mimic/timer/script/list
# Returns: table<arg: string, interval: int, script: string>
# operationId: list_daemon_timer_scripts
export def "list-daemon-timer-scripts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mimic/timer/script/list"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
