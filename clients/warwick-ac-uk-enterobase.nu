# Auto-generated client for Enterobase-API v2.0
# Source: https://api.apis.guru/v2/specs/warwick.ac.uk/enterobase/v2.0/openapi.json
# Auth: --token flag or $env.ENTEROBASE_API_TOKEN

const CLIENT = {
  base_url: "https://api.apis.guru"
  token_env_var: "ENTEROBASE_API_TOKEN"
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

def base-url-completer [] { ["https://api.apis.guru"] }
def auth-scheme-completer [] { ["basic" "basic-credentials"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {}
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-api-v2-0" "get-api-v2-0-login" "get-api-v2-0-lookup" "get-api-v2-0-lookup-barcode" "post-api-v2-0-lookup-barcode" "get-api-v2-0-database-assemblies" "get-api-v2-0-database-assemblies-barcode" "post-api-v2-0-database-assemblies-barcode" "put-api-v2-0-database-assemblies-barcode" "get-api-v2-0-database-schemes" "get-api-v2-0-database-schemes-barcode" "post-api-v2-0-database-schemes-barcode" "put-api-v2-0-database-schemes-barcode" "get-api-v2-0-database-straindata" "get-api-v2-0-database-strains" "get-api-v2-0-database-strains-barcode" "post-api-v2-0-database-strains-barcode" "put-api-v2-0-database-strains-barcode" "get-api-v2-0-database-strainsversion" "get-api-v2-0-database-traces" "get-api-v2-0-database-traces-barcode" "post-api-v2-0-database-traces-barcode" "put-api-v2-0-database-traces-barcode" "get-api-v2-0-database-scheme-alleles" "get-api-v2-0-database-scheme-loci" "get-api-v2-0-database-scheme-sts" "commands"] | sort) } | get name | first)
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

# Top level information about EnteroBase databases
#
# GET /api/v2.0
export def "get-api-v2-0" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --prefix: string # Database prefix, e.g. SAL for Salmonella
  --name: string # Species database name (senterica, ecoli, yersinia, mcatarrhalis) for Salmonella, Escherichia, Yersinia, Moraxella respectively
  --description: string # Database description
]: nothing -> any {
  http-request {
    method: get
    path: "/api/v2.0"
    query: [{name: prefix, var: prefix}, {name: name, var: name}, {name: description, var: description}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    prefix: $prefix, name: $name, description: $description
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Login endpoint, refresh your API token
#
# GET /api/v2.0/login
export def "get-api-v2-0-login" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --username: string # EnteroBase username
  --password: string # EnteroBase Password
]: nothing -> any {
  http-request {
    method: get
    path: "/api/v2.0/login"
    query: [{name: username, var: username}, {name: password, var: password}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    username: $username, password: $password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generic endpoint for lookup list of barcodes
#
# GET /api/v2.0/lookup
export def "get-api-v2-0-lookup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --barcode: string # Unique barcode for Traces records, __ e.g. SAL_AA0001AA_ST
]: nothing -> any {
  http-request {
    method: get
    path: "/api/v2.0/lookup"
    query: [{name: barcode, var: barcode}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    barcode: $barcode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generic endpoint for lookup of barcodes
#
# GET /api/v2.0/lookup/{barcode}
export def "get-api-v2-0-lookup-barcode" [
  barcode: string
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
    path: "/api/v2.0/lookup/{barcode}"
    path_params: [{name: barcode, var: barcode}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    barcode: $barcode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generic endpoint for lookup of barcodes
#
# POST /api/v2.0/lookup/{barcode}
export def "post-api-v2-0-lookup-barcode" [
  barcode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-barcode: string # (spec name: barcode)
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v2.0/lookup/{barcode}"
    path_params: [{name: barcode, var: barcode}]
    body: {content_type: "application/json", kind: json, fields: [{name: barcode, var: body_barcode}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    barcode: $barcode, body_barcode: $body_barcode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Genome assemblies
#
# GET /api/v2.0/{database}/assemblies
export def "get-api-v2-0-database-assemblies" [
  database: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --orderby: string # Field to order by. Default: barcode (default: barcode)
  --only-fields: list<string>
  --barcode: list<string> # Unique barcode for Traces records, __AS e.g. SAL_AA0001AA_AS
  --n50: int # format: int32
  --top-species: string
  --uberstrain: string
  --version: int # format: int32
  --limit: int # Number of results per page (format: int32, default: 50)
  --reldate: int # format: int32
  --offset: int # Cursor position in results (format: int32, default: 0)
  --assembly-status: string
  --sortorder: string # Order of search results: asc or desc (default: asc)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/v2.0/{database}/assemblies"
    path_params: [{name: database, var: database}]
    query: [{name: orderby, var: orderby}, {name: only_fields, var: only_fields, style: multi}, {name: barcode, var: barcode, style: multi}, {name: n50, var: n50}, {name: top_species, var: top_species}, {name: uberstrain, var: uberstrain}, {name: version, var: version}, {name: limit, var: limit}, {name: reldate, var: reldate}, {name: offset, var: offset}, {name: assembly_status, var: assembly_status}, {name: sortorder, var: sortorder}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    database: $database, orderby: $orderby, only_fields: $only_fields, barcode: $barcode, n50: $n50, top_species: $top_species, uberstrain: $uberstrain, version: $version, limit: $limit, reldate: $reldate, offset: $offset, assembly_status: $assembly_status, sortorder: $sortorder
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Genome assemblies
#
# GET /api/v2.0/{database}/assemblies/{barcode}
export def "get-api-v2-0-database-assemblies-barcode" [
  database: string
  barcode: string
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
    path: "/api/v2.0/{database}/assemblies/{barcode}"
    path_params: [{name: database, var: database}, {name: barcode, var: barcode}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    database: $database, barcode: $barcode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Genome assemblies
#
# POST /api/v2.0/{database}/assemblies/{barcode}
export def "post-api-v2-0-database-assemblies-barcode" [
  database: string
  barcode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --assembly-status: string
  --body-barcode: list<string> # (spec name: barcode)
  --limit: int # format: int32, default: 50
  --n50: int # format: int32
  --offset: int # format: int32, default: 0
  --only-fields: list<string>
  --orderby: string # default: barcode
  --reldate: int # format: int32
  --sortorder: string # default: asc
  --top-species: string
  --uberstrain: string
  --version: int # format: int32
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v2.0/{database}/assemblies/{barcode}"
    path_params: [{name: database, var: database}, {name: barcode, var: barcode}]
    body: {content_type: "application/json", kind: json, fields: [{name: assembly_status, var: assembly_status}, {name: barcode, var: body_barcode}, {name: limit, var: limit}, {name: n50, var: n50}, {name: offset, var: offset}, {name: only_fields, var: only_fields}, {name: orderby, var: orderby}, {name: reldate, var: reldate}, {name: sortorder, var: sortorder}, {name: top_species, var: top_species}, {name: uberstrain, var: uberstrain}, {name: version, var: version}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    database: $database, barcode: $barcode, assembly_status: $assembly_status, body_barcode: $body_barcode, limit: $limit, n50: $n50, offset: $offset, only_fields: $only_fields, orderby: $orderby, reldate: $reldate, sortorder: $sortorder, top_species: $top_species, uberstrain: $uberstrain, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Genome assemblies
#
# PUT /api/v2.0/{database}/assemblies/{barcode}
export def "put-api-v2-0-database-assemblies-barcode" [
  database: string
  barcode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --assembly-status: string
  --body-barcode: list<string> # (spec name: barcode)
  --limit: int # format: int32, default: 50
  --n50: int # format: int32
  --offset: int # format: int32, default: 0
  --only-fields: list<string>
  --orderby: string # default: barcode
  --reldate: int # format: int32
  --sortorder: string # default: asc
  --top-species: string
  --uberstrain: string
  --version: int # format: int32
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v2.0/{database}/assemblies/{barcode}"
    path_params: [{name: database, var: database}, {name: barcode, var: barcode}]
    body: {content_type: "application/json", kind: json, fields: [{name: assembly_status, var: assembly_status}, {name: barcode, var: body_barcode}, {name: limit, var: limit}, {name: n50, var: n50}, {name: offset, var: offset}, {name: only_fields, var: only_fields}, {name: orderby, var: orderby}, {name: reldate, var: reldate}, {name: sortorder, var: sortorder}, {name: top_species, var: top_species}, {name: uberstrain, var: uberstrain}, {name: version, var: version}]}
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    database: $database, barcode: $barcode, assembly_status: $assembly_status, body_barcode: $body_barcode, limit: $limit, n50: $n50, offset: $offset, only_fields: $only_fields, orderby: $orderby, reldate: $reldate, sortorder: $sortorder, top_species: $top_species, uberstrain: $uberstrain, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Genotyping schemes
#
# GET /api/v2.0/{database}/schemes
export def "get-api-v2-0-database-schemes" [
  database: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --orderby: string # Field to order by. Default: barcode (default: barcode)
  --scheme-name: string
  --created: string # format: date-time
  --lastmodified: string # format: date-time
  --barcode: list<string> # Unique barcode for Strain records, _ e.g. SAL_AA0001AA
  --label: string
  --only-fields: list<string>
  --version: int # format: int32
  --limit: int # Number of results per page (format: int32, default: 50)
  --sortorder: string # Order of search results: asc or desc (default: asc)
  --offset: int # Cursor position in results (format: int32, default: 0)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/v2.0/{database}/schemes"
    path_params: [{name: database, var: database}]
    query: [{name: orderby, var: orderby}, {name: scheme_name, var: scheme_name}, {name: created, var: created}, {name: lastmodified, var: lastmodified}, {name: barcode, var: barcode, style: multi}, {name: label, var: label}, {name: only_fields, var: only_fields, style: multi}, {name: version, var: version}, {name: limit, var: limit}, {name: sortorder, var: sortorder}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    database: $database, orderby: $orderby, scheme_name: $scheme_name, created: $created, lastmodified: $lastmodified, barcode: $barcode, label: $label, only_fields: $only_fields, version: $version, limit: $limit, sortorder: $sortorder, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Genotyping schemes
#
# GET /api/v2.0/{database}/schemes/{barcode}
export def "get-api-v2-0-database-schemes-barcode" [
  database: string
  barcode: string
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
    path: "/api/v2.0/{database}/schemes/{barcode}"
    path_params: [{name: database, var: database}, {name: barcode, var: barcode}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    database: $database, barcode: $barcode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Genotyping schemes
#
# POST /api/v2.0/{database}/schemes/{barcode}
export def "post-api-v2-0-database-schemes-barcode" [
  database: string
  barcode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-barcode: list<string> # (spec name: barcode)
  --created: string # format: date-time
  --label: string
  --lastmodified: string # format: date-time
  --limit: int # format: int32, default: 50
  --offset: int # format: int32, default: 0
  --only-fields: list<string>
  --orderby: string # default: barcode
  --scheme-name: string
  --sortorder: string # default: asc
  --version: int # format: int32
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v2.0/{database}/schemes/{barcode}"
    path_params: [{name: database, var: database}, {name: barcode, var: barcode}]
    body: {content_type: "application/json", kind: json, fields: [{name: barcode, var: body_barcode}, {name: created, var: created}, {name: label, var: label}, {name: lastmodified, var: lastmodified}, {name: limit, var: limit}, {name: offset, var: offset}, {name: only_fields, var: only_fields}, {name: orderby, var: orderby}, {name: scheme_name, var: scheme_name}, {name: sortorder, var: sortorder}, {name: version, var: version}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    database: $database, barcode: $barcode, body_barcode: $body_barcode, created: $created, label: $label, lastmodified: $lastmodified, limit: $limit, offset: $offset, only_fields: $only_fields, orderby: $orderby, scheme_name: $scheme_name, sortorder: $sortorder, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Genotyping schemes
#
# PUT /api/v2.0/{database}/schemes/{barcode}
export def "put-api-v2-0-database-schemes-barcode" [
  database: string
  barcode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-barcode: list<string> # (spec name: barcode)
  --created: string # format: date-time
  --label: string
  --lastmodified: string # format: date-time
  --limit: int # format: int32, default: 50
  --offset: int # format: int32, default: 0
  --only-fields: list<string>
  --orderby: string # default: barcode
  --scheme-name: string
  --sortorder: string # default: asc
  --version: int # format: int32
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v2.0/{database}/schemes/{barcode}"
    path_params: [{name: database, var: database}, {name: barcode, var: barcode}]
    body: {content_type: "application/json", kind: json, fields: [{name: barcode, var: body_barcode}, {name: created, var: created}, {name: label, var: label}, {name: lastmodified, var: lastmodified}, {name: limit, var: limit}, {name: offset, var: offset}, {name: only_fields, var: only_fields}, {name: orderby, var: orderby}, {name: scheme_name, var: scheme_name}, {name: sortorder, var: sortorder}, {name: version, var: version}]}
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    database: $database, barcode: $barcode, body_barcode: $body_barcode, created: $created, label: $label, lastmodified: $lastmodified, limit: $limit, offset: $offset, only_fields: $only_fields, orderby: $orderby, scheme_name: $scheme_name, sortorder: $sortorder, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Strain data
#
# GET /api/v2.0/{database}/straindata
export def "get-api-v2-0-database-straindata" [
  database: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --comment: string
  --secondary-sample-accession: string
  --my-strains: oneof<nothing, bool>
  --offset: int # Cursor position in results (format: int32, default: 0)
  --serotype: string
  --n50: int # format: int32
  --county: string
  --only-fields: list<string>
  --postcode: string
  --lab-contact: string
  --substrains: oneof<nothing, bool>
  --custom-fields: string
  --city: string
  --strain-name: string
  --collection-date: int # format: int32
  --collection-month: int # format: int32
  --reldate: int # format: int32
  --continent: string
  --source-details: string
  --version: int # format: int32
  --latitude: float # format: float
  --email: string
  --source-niche: string
  --barcode: list<string> # Unique barcode for Traces records, __AS e.g. SAL_AA0001AA_AS
  --uberstrain: string
  --sortorder: string # Order of search results: asc or desc (default: asc)
  --collection-year: int # format: int32
  --orderby: string # Field to order by. Default: strain barcode
  --assembly-status: string
  --source-type: string
  --country: string
  --region: string
  --longitude: float # format: float
  --sample-accession: string
  --limit: int # Number of results per page (format: int32, default: 50)
  --top-species: string
  --collection-time: string
]: nothing -> any {
  http-request {
    method: get
    path: "/api/v2.0/{database}/straindata"
    path_params: [{name: database, var: database}]
    query: [{name: comment, var: comment}, {name: secondary_sample_accession, var: secondary_sample_accession}, {name: my_strains, var: my_strains}, {name: offset, var: offset}, {name: serotype, var: serotype}, {name: n50, var: n50}, {name: county, var: county}, {name: only_fields, var: only_fields, style: multi}, {name: postcode, var: postcode}, {name: lab_contact, var: lab_contact}, {name: substrains, var: substrains}, {name: custom_fields, var: custom_fields}, {name: city, var: city}, {name: strain_name, var: strain_name}, {name: collection_date, var: collection_date}, {name: collection_month, var: collection_month}, {name: reldate, var: reldate}, {name: continent, var: continent}, {name: source_details, var: source_details}, {name: version, var: version}, {name: latitude, var: latitude}, {name: email, var: email}, {name: source_niche, var: source_niche}, {name: barcode, var: barcode, style: multi}, {name: uberstrain, var: uberstrain}, {name: sortorder, var: sortorder}, {name: collection_year, var: collection_year}, {name: orderby, var: orderby}, {name: assembly_status, var: assembly_status}, {name: source_type, var: source_type}, {name: country, var: country}, {name: region, var: region}, {name: longitude, var: longitude}, {name: sample_accession, var: sample_accession}, {name: limit, var: limit}, {name: top_species, var: top_species}, {name: collection_time, var: collection_time}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    database: $database, comment: $comment, secondary_sample_accession: $secondary_sample_accession, my_strains: $my_strains, offset: $offset, serotype: $serotype, n50: $n50, county: $county, only_fields: $only_fields, postcode: $postcode, lab_contact: $lab_contact, substrains: $substrains, custom_fields: $custom_fields, city: $city, strain_name: $strain_name, collection_date: $collection_date, collection_month: $collection_month, reldate: $reldate, continent: $continent, source_details: $source_details, version: $version, latitude: $latitude, email: $email, source_niche: $source_niche, barcode: $barcode, uberstrain: $uberstrain, sortorder: $sortorder, collection_year: $collection_year, orderby: $orderby, assembly_status: $assembly_status, source_type: $source_type, country: $country, region: $region, longitude: $longitude, sample_accession: $sample_accession, limit: $limit, top_species: $top_species, collection_time: $collection_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Strain metadata
#
# GET /api/v2.0/{database}/strains
export def "get-api-v2-0-database-strains" [
  database: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --comment: string
  --secondary-sample-accession: string
  --antigenic-formulas: string
  --my-strains: oneof<nothing, bool>
  --serotype: string
  --county: string
  --only-fields: list<string>
  --postcode: string
  --lab-contact: string
  --substrains: oneof<nothing, bool>
  --city: string
  --strain-name: string
  --collection-date: int # format: int32
  --collection-month: int # format: int32
  --reldate: int # format: int32
  --continent: string
  --source-details: string
  --version: int # format: int32
  --latitude: float # format: float
  --assembly-barcode: string
  --source-niche: string
  --barcode: list<string> # Unique barcode for Strain records, _ e.g. SAL_AA0001AA
  --uberstrain: string
  --sortorder: string # Order of search results: asc or desc (default: asc)
  --offset: int # Cursor position in results (format: int32, default: 0)
  --collection-year: int # format: int32
  --orderby: string # Field to order by. Default: barcode (default: barcode)
  --return-all: oneof<nothing, bool>
  --source-type: string
  --country: string
  --region: string
  --longitude: float # format: float
  --sample-accession: string
  --limit: int # Number of results per page (format: int32, default: 50)
  --collection-time: string
]: nothing -> any {
  http-request {
    method: get
    path: "/api/v2.0/{database}/strains"
    path_params: [{name: database, var: database}]
    query: [{name: comment, var: comment}, {name: secondary_sample_accession, var: secondary_sample_accession}, {name: antigenic_formulas, var: antigenic_formulas}, {name: my_strains, var: my_strains}, {name: serotype, var: serotype}, {name: county, var: county}, {name: only_fields, var: only_fields, style: multi}, {name: postcode, var: postcode}, {name: lab_contact, var: lab_contact}, {name: substrains, var: substrains}, {name: city, var: city}, {name: strain_name, var: strain_name}, {name: collection_date, var: collection_date}, {name: collection_month, var: collection_month}, {name: reldate, var: reldate}, {name: continent, var: continent}, {name: source_details, var: source_details}, {name: version, var: version}, {name: latitude, var: latitude}, {name: assembly_barcode, var: assembly_barcode}, {name: source_niche, var: source_niche}, {name: barcode, var: barcode, style: multi}, {name: uberstrain, var: uberstrain}, {name: sortorder, var: sortorder}, {name: offset, var: offset}, {name: collection_year, var: collection_year}, {name: orderby, var: orderby}, {name: return_all, var: return_all}, {name: source_type, var: source_type}, {name: country, var: country}, {name: region, var: region}, {name: longitude, var: longitude}, {name: sample_accession, var: sample_accession}, {name: limit, var: limit}, {name: collection_time, var: collection_time}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    database: $database, comment: $comment, secondary_sample_accession: $secondary_sample_accession, antigenic_formulas: $antigenic_formulas, my_strains: $my_strains, serotype: $serotype, county: $county, only_fields: $only_fields, postcode: $postcode, lab_contact: $lab_contact, substrains: $substrains, city: $city, strain_name: $strain_name, collection_date: $collection_date, collection_month: $collection_month, reldate: $reldate, continent: $continent, source_details: $source_details, version: $version, latitude: $latitude, assembly_barcode: $assembly_barcode, source_niche: $source_niche, barcode: $barcode, uberstrain: $uberstrain, sortorder: $sortorder, offset: $offset, collection_year: $collection_year, orderby: $orderby, return_all: $return_all, source_type: $source_type, country: $country, region: $region, longitude: $longitude, sample_accession: $sample_accession, limit: $limit, collection_time: $collection_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Strain metadata
#
# GET /api/v2.0/{database}/strains/{barcode}
export def "get-api-v2-0-database-strains-barcode" [
  database: string
  barcode: string
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
    path: "/api/v2.0/{database}/strains/{barcode}"
    path_params: [{name: database, var: database}, {name: barcode, var: barcode}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    database: $database, barcode: $barcode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Strain metadata
#
# POST /api/v2.0/{database}/strains/{barcode}
export def "post-api-v2-0-database-strains-barcode" [
  database: string
  barcode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --antigenic-formulas: string
  --assembly-barcode: string
  --body-barcode: list<string> # (spec name: barcode)
  --city: string
  --collection-date: int # format: int32
  --collection-month: int # format: int32
  --collection-time: string
  --collection-year: int # format: int32
  --comment: string
  --continent: string
  --country: string
  --county: string
  --lab-contact: string
  --latitude: float # format: float
  --limit: int # format: int32, default: 50
  --longitude: float # format: float
  --my-strains: oneof<nothing, bool>
  --offset: int # format: int32, default: 0
  --only-fields: list<string>
  --orderby: string # default: barcode
  --postcode: string
  --region: string
  --reldate: int # format: int32
  --return-all: oneof<nothing, bool>
  --sample-accession: string
  --secondary-sample-accession: string
  --serotype: string
  --sortorder: string # default: asc
  --source-details: string
  --source-niche: string
  --source-type: string
  --strain-name: string
  --substrains: oneof<nothing, bool>
  --uberstrain: string
  --version: int # format: int32
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v2.0/{database}/strains/{barcode}"
    path_params: [{name: database, var: database}, {name: barcode, var: barcode}]
    body: {content_type: "application/json", kind: json, fields: [{name: antigenic_formulas, var: antigenic_formulas}, {name: assembly_barcode, var: assembly_barcode}, {name: barcode, var: body_barcode}, {name: city, var: city}, {name: collection_date, var: collection_date}, {name: collection_month, var: collection_month}, {name: collection_time, var: collection_time}, {name: collection_year, var: collection_year}, {name: comment, var: comment}, {name: continent, var: continent}, {name: country, var: country}, {name: county, var: county}, {name: lab_contact, var: lab_contact}, {name: latitude, var: latitude}, {name: limit, var: limit}, {name: longitude, var: longitude}, {name: my_strains, var: my_strains}, {name: offset, var: offset}, {name: only_fields, var: only_fields}, {name: orderby, var: orderby}, {name: postcode, var: postcode}, {name: region, var: region}, {name: reldate, var: reldate}, {name: return_all, var: return_all}, {name: sample_accession, var: sample_accession}, {name: secondary_sample_accession, var: secondary_sample_accession}, {name: serotype, var: serotype}, {name: sortorder, var: sortorder}, {name: source_details, var: source_details}, {name: source_niche, var: source_niche}, {name: source_type, var: source_type}, {name: strain_name, var: strain_name}, {name: substrains, var: substrains}, {name: uberstrain, var: uberstrain}, {name: version, var: version}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    database: $database, barcode: $barcode, antigenic_formulas: $antigenic_formulas, assembly_barcode: $assembly_barcode, body_barcode: $body_barcode, city: $city, collection_date: $collection_date, collection_month: $collection_month, collection_time: $collection_time, collection_year: $collection_year, comment: $comment, continent: $continent, country: $country, county: $county, lab_contact: $lab_contact, latitude: $latitude, limit: $limit, longitude: $longitude, my_strains: $my_strains, offset: $offset, only_fields: $only_fields, orderby: $orderby, postcode: $postcode, region: $region, reldate: $reldate, return_all: $return_all, sample_accession: $sample_accession, secondary_sample_accession: $secondary_sample_accession, serotype: $serotype, sortorder: $sortorder, source_details: $source_details, source_niche: $source_niche, source_type: $source_type, strain_name: $strain_name, substrains: $substrains, uberstrain: $uberstrain, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Strain metadata
#
# PUT /api/v2.0/{database}/strains/{barcode}
export def "put-api-v2-0-database-strains-barcode" [
  database: string
  barcode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --antigenic-formulas: string
  --assembly-barcode: string
  --body-barcode: list<string> # (spec name: barcode)
  --city: string
  --collection-date: int # format: int32
  --collection-month: int # format: int32
  --collection-time: string
  --collection-year: int # format: int32
  --comment: string
  --continent: string
  --country: string
  --county: string
  --lab-contact: string
  --latitude: float # format: float
  --limit: int # format: int32, default: 50
  --longitude: float # format: float
  --my-strains: oneof<nothing, bool>
  --offset: int # format: int32, default: 0
  --only-fields: list<string>
  --orderby: string # default: barcode
  --postcode: string
  --region: string
  --reldate: int # format: int32
  --return-all: oneof<nothing, bool>
  --sample-accession: string
  --secondary-sample-accession: string
  --serotype: string
  --sortorder: string # default: asc
  --source-details: string
  --source-niche: string
  --source-type: string
  --strain-name: string
  --substrains: oneof<nothing, bool>
  --uberstrain: string
  --version: int # format: int32
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v2.0/{database}/strains/{barcode}"
    path_params: [{name: database, var: database}, {name: barcode, var: barcode}]
    body: {content_type: "application/json", kind: json, fields: [{name: antigenic_formulas, var: antigenic_formulas}, {name: assembly_barcode, var: assembly_barcode}, {name: barcode, var: body_barcode}, {name: city, var: city}, {name: collection_date, var: collection_date}, {name: collection_month, var: collection_month}, {name: collection_time, var: collection_time}, {name: collection_year, var: collection_year}, {name: comment, var: comment}, {name: continent, var: continent}, {name: country, var: country}, {name: county, var: county}, {name: lab_contact, var: lab_contact}, {name: latitude, var: latitude}, {name: limit, var: limit}, {name: longitude, var: longitude}, {name: my_strains, var: my_strains}, {name: offset, var: offset}, {name: only_fields, var: only_fields}, {name: orderby, var: orderby}, {name: postcode, var: postcode}, {name: region, var: region}, {name: reldate, var: reldate}, {name: return_all, var: return_all}, {name: sample_accession, var: sample_accession}, {name: secondary_sample_accession, var: secondary_sample_accession}, {name: serotype, var: serotype}, {name: sortorder, var: sortorder}, {name: source_details, var: source_details}, {name: source_niche, var: source_niche}, {name: source_type, var: source_type}, {name: strain_name, var: strain_name}, {name: substrains, var: substrains}, {name: uberstrain, var: uberstrain}, {name: version, var: version}]}
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    database: $database, barcode: $barcode, antigenic_formulas: $antigenic_formulas, assembly_barcode: $assembly_barcode, body_barcode: $body_barcode, city: $city, collection_date: $collection_date, collection_month: $collection_month, collection_time: $collection_time, collection_year: $collection_year, comment: $comment, continent: $continent, country: $country, county: $county, lab_contact: $lab_contact, latitude: $latitude, limit: $limit, longitude: $longitude, my_strains: $my_strains, offset: $offset, only_fields: $only_fields, orderby: $orderby, postcode: $postcode, region: $region, reldate: $reldate, return_all: $return_all, sample_accession: $sample_accession, secondary_sample_accession: $secondary_sample_accession, serotype: $serotype, sortorder: $sortorder, source_details: $source_details, source_niche: $source_niche, source_type: $source_type, strain_name: $strain_name, substrains: $substrains, uberstrain: $uberstrain, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Strain previous metadata
#
# GET /api/v2.0/{database}/strainsversion
export def "get-api-v2-0-database-strainsversion" [
  database: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --comment: string
  --secondary-sample-accession: string
  --antigenic-formulas: string
  --my-strains: oneof<nothing, bool>
  --serotype: string
  --county: string
  --only-fields: list<string>
  --postcode: string
  --lab-contact: string
  --substrains: oneof<nothing, bool>
  --city: string
  --strain-name: string
  --collection-date: int # format: int32
  --collection-month: int # format: int32
  --reldate: int # format: int32
  --continent: string
  --source-details: string
  --version: int # format: int32
  --latitude: float # format: float
  --assembly-barcode: string
  --source-niche: string
  --barcode: list<string> # Unique barcode for Strain records, _ e.g. SAL_AA0001AA
  --uberstrain: string
  --sortorder: string # Order of search results: asc or desc (default: asc)
  --offset: int # Cursor position in results (format: int32, default: 0)
  --collection-year: int # format: int32
  --orderby: string # Field to order by. Default: barcode (default: barcode)
  --return-all: oneof<nothing, bool>
  --source-type: string
  --country: string
  --region: string
  --longitude: float # format: float
  --sample-accession: string
  --limit: int # Number of results per page (format: int32, default: 50)
  --collection-time: string
]: nothing -> any {
  http-request {
    method: get
    path: "/api/v2.0/{database}/strainsversion"
    path_params: [{name: database, var: database}]
    query: [{name: comment, var: comment}, {name: secondary_sample_accession, var: secondary_sample_accession}, {name: antigenic_formulas, var: antigenic_formulas}, {name: my_strains, var: my_strains}, {name: serotype, var: serotype}, {name: county, var: county}, {name: only_fields, var: only_fields, style: multi}, {name: postcode, var: postcode}, {name: lab_contact, var: lab_contact}, {name: substrains, var: substrains}, {name: city, var: city}, {name: strain_name, var: strain_name}, {name: collection_date, var: collection_date}, {name: collection_month, var: collection_month}, {name: reldate, var: reldate}, {name: continent, var: continent}, {name: source_details, var: source_details}, {name: version, var: version}, {name: latitude, var: latitude}, {name: assembly_barcode, var: assembly_barcode}, {name: source_niche, var: source_niche}, {name: barcode, var: barcode, style: multi}, {name: uberstrain, var: uberstrain}, {name: sortorder, var: sortorder}, {name: offset, var: offset}, {name: collection_year, var: collection_year}, {name: orderby, var: orderby}, {name: return_all, var: return_all}, {name: source_type, var: source_type}, {name: country, var: country}, {name: region, var: region}, {name: longitude, var: longitude}, {name: sample_accession, var: sample_accession}, {name: limit, var: limit}, {name: collection_time, var: collection_time}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    database: $database, comment: $comment, secondary_sample_accession: $secondary_sample_accession, antigenic_formulas: $antigenic_formulas, my_strains: $my_strains, serotype: $serotype, county: $county, only_fields: $only_fields, postcode: $postcode, lab_contact: $lab_contact, substrains: $substrains, city: $city, strain_name: $strain_name, collection_date: $collection_date, collection_month: $collection_month, reldate: $reldate, continent: $continent, source_details: $source_details, version: $version, latitude: $latitude, assembly_barcode: $assembly_barcode, source_niche: $source_niche, barcode: $barcode, uberstrain: $uberstrain, sortorder: $sortorder, offset: $offset, collection_year: $collection_year, orderby: $orderby, return_all: $return_all, source_type: $source_type, country: $country, region: $region, longitude: $longitude, sample_accession: $sample_accession, limit: $limit, collection_time: $collection_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Traces (sequence-reads) metadata
#
# GET /api/v2.0/{database}/traces
export def "get-api-v2-0-database-traces" [
  database: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --orderby: string # Field to order by. Default: barcode (default: barcode)
  --barcode: list<string> # Unique barcode for Traces records, __TR e.g. SAL_AA0001AA_TR
  --only-fields: list<string>
  --limit: int # Number of results per page (format: int32, default: 50)
  --sortorder: string # Order of search results: asc or desc (default: asc)
  --offset: int # Cursor position in results (format: int32, default: 0)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/v2.0/{database}/traces"
    path_params: [{name: database, var: database}]
    query: [{name: orderby, var: orderby}, {name: barcode, var: barcode, style: multi}, {name: only_fields, var: only_fields, style: multi}, {name: limit, var: limit}, {name: sortorder, var: sortorder}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    database: $database, orderby: $orderby, barcode: $barcode, only_fields: $only_fields, limit: $limit, sortorder: $sortorder, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Traces (sequence-reads) metadata
#
# GET /api/v2.0/{database}/traces/{barcode}
export def "get-api-v2-0-database-traces-barcode" [
  database: string
  barcode: string
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
    path: "/api/v2.0/{database}/traces/{barcode}"
    path_params: [{name: database, var: database}, {name: barcode, var: barcode}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    database: $database, barcode: $barcode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Traces (sequence-reads) metadata
#
# POST /api/v2.0/{database}/traces/{barcode}
export def "post-api-v2-0-database-traces-barcode" [
  database: string
  barcode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-barcode: list<string> # (spec name: barcode)
  --limit: int # format: int32, default: 50
  --offset: int # format: int32, default: 0
  --only-fields: list<string>
  --orderby: string # default: barcode
  --sortorder: string # default: asc
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v2.0/{database}/traces/{barcode}"
    path_params: [{name: database, var: database}, {name: barcode, var: barcode}]
    body: {content_type: "application/json", kind: json, fields: [{name: barcode, var: body_barcode}, {name: limit, var: limit}, {name: offset, var: offset}, {name: only_fields, var: only_fields}, {name: orderby, var: orderby}, {name: sortorder, var: sortorder}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    database: $database, barcode: $barcode, body_barcode: $body_barcode, limit: $limit, offset: $offset, only_fields: $only_fields, orderby: $orderby, sortorder: $sortorder
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Traces (sequence-reads) metadata
#
# PUT /api/v2.0/{database}/traces/{barcode}
export def "put-api-v2-0-database-traces-barcode" [
  database: string
  barcode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-barcode: list<string> # (spec name: barcode)
  --limit: int # format: int32, default: 50
  --offset: int # format: int32, default: 0
  --only-fields: list<string>
  --orderby: string # default: barcode
  --sortorder: string # default: asc
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v2.0/{database}/traces/{barcode}"
    path_params: [{name: database, var: database}, {name: barcode, var: barcode}]
    body: {content_type: "application/json", kind: json, fields: [{name: barcode, var: body_barcode}, {name: limit, var: limit}, {name: offset, var: offset}, {name: only_fields, var: only_fields}, {name: orderby, var: orderby}, {name: sortorder, var: sortorder}]}
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    database: $database, barcode: $barcode, body_barcode: $body_barcode, limit: $limit, offset: $offset, only_fields: $only_fields, orderby: $orderby, sortorder: $sortorder
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Alleles data
#
# GET /api/v2.0/{database}/{scheme}/alleles
export def "get-api-v2-0-database-scheme-alleles" [
  database: string
  scheme: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allele-id: string
  --seq: string
  --barcode: list<string> # Unique barcode for Strain records, _ e.g. SAL_AA0001AA
  --reldate: int # format: int32
  --locus: string # required
  --only-fields: list<string>
  --limit: int # format: int32, default: 50
  --offset: int # format: int32, default: 0
]: nothing -> any {
  http-request {
    method: get
    path: "/api/v2.0/{database}/{scheme}/alleles"
    path_params: [{name: database, var: database}, {name: scheme, var: scheme}]
    query: [{name: allele_id, var: allele_id}, {name: seq, var: seq}, {name: barcode, var: barcode, style: multi}, {name: reldate, var: reldate}, {name: locus, var: locus, required: true}, {name: only_fields, var: only_fields, style: multi}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    database: $database, scheme: $scheme, allele_id: $allele_id, seq: $seq, barcode: $barcode, reldate: $reldate, locus: $locus, only_fields: $only_fields, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Loci
#
# GET /api/v2.0/{database}/{scheme}/loci
export def "get-api-v2-0-database-scheme-loci" [
  database: string
  scheme: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --barcode: list<string> # Unique barcode for Strain records, _ e.g. SAL_AA0001AA
  --locus: string
  --only-fields: list<string>
  --create-time: string # format: date-time
  --limit: int # format: int32, default: 50
  --offset: int # format: int32, default: 0
  --qp-scheme: string # (spec name: scheme)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/v2.0/{database}/{scheme}/loci"
    path_params: [{name: database, var: database}, {name: scheme, var: scheme}]
    query: [{name: barcode, var: barcode, style: multi}, {name: locus, var: locus}, {name: only_fields, var: only_fields, style: multi}, {name: create_time, var: create_time}, {name: limit, var: limit}, {name: offset, var: offset}, {name: scheme, var: qp_scheme}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    database: $database, scheme: $scheme, barcode: $barcode, locus: $locus, only_fields: $only_fields, create_time: $create_time, limit: $limit, offset: $offset, qp_scheme: $qp_scheme
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ST profile data
#
# GET /api/v2.0/{database}/{scheme}/sts
export def "get-api-v2-0-database-scheme-sts" [
  database: string
  scheme: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --st-id: string
  --qp-scheme: string # (spec name: scheme)
  --show-alleles: oneof<nothing, bool>
  --barcode: list<string> # Unique barcode for Strain records, _ e.g. SAL_AA0001AA
  --only-fields: list<string>
  --limit: int # format: int32, default: 50
  --reldate: int # format: int32
  --offset: int # format: int32, default: 0
]: nothing -> any {
  http-request {
    method: get
    path: "/api/v2.0/{database}/{scheme}/sts"
    path_params: [{name: database, var: database}, {name: scheme, var: scheme}]
    query: [{name: st_id, var: st_id}, {name: scheme, var: qp_scheme}, {name: show_alleles, var: show_alleles}, {name: barcode, var: barcode, style: multi}, {name: only_fields, var: only_fields, style: multi}, {name: limit, var: limit}, {name: reldate, var: reldate}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    database: $database, scheme: $scheme, st_id: $st_id, qp_scheme: $qp_scheme, show_alleles: $show_alleles, barcode: $barcode, only_fields: $only_fields, limit: $limit, reldate: $reldate, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
