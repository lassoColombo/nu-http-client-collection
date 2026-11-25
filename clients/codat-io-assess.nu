# Auto-generated client for Assess API v1.0
# Source: https://api.apis.guru/v2/specs/codat.io/assess/1.0/openapi.json
# Auth: --token flag or $env.ASSESS_API_TOKEN

const CLIENT = {
  base_url: "https://api.codat.io"
  token_env_var: "ASSESS_API_TOKEN"
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

def base-url-completer [] { ["https://api.codat.io"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def data-type-completer [] { ["accountTransactions" "bankAccounts" "banking-accounts" "banking-transactions"] }
def report-type-completer [] { ["audit" "enhancedFinancials"] }
def period-unit-completer [] { ["Day" "Month" "Week" "Year"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-accounts-for-enhanced-balance-sheet: "record<reportInfo: record<companyName: string, currency: string, generatedDate: string, reportName: string>, reportItems: table<accountCategory: record, accountId: string, accountName: string, balance: float, date: string>>"
    get-enhanced-cash-flow-transactions: "record<dataSources: table<accounts: list>, reportInfo: record<companyName: string, generatedDate: string, pageNumber: int, pageSize: int, reportName: string, totalResults: int>, reportItems: table<transactions: list>>"
    get-enhanced-invoices-report: "record<reportInfo: record<companyName: string, generatedDate: string, pageNumber: int, pageSize: int, reportName: string, totalResults: int>, reportItems: table<invoices: list>>"
    get-accounts-for-enhanced-profit-and-loss: "record<reportInfo: record<companyName: string, currency: string, generatedDate: string, reportName: string>, reportItems: table<accountCategory: record, accountId: string, accountName: string, balance: float, date: string>>"
    list-available-account-categories: "table<detailType: string, subtype: string, type: string, detailTypeDescription: string, detailTypeDisplayName: string, subtypeDisplayName: string>"
    get-data-integrity-details: "record<results: table<amount: float, connectionId: string, currency: string, date: string, description: string, id: string, matches: list, type: string>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>"
    get-data-integrity-status: "record<metadata: table<type: string, amounts: record, connectionIds: record, dates: record, statusInfo: record>>"
    get-data-integrity-summaries: "record<summaries: table<type: string, byAmount: record, byCount: record>>"
    get-excel-report-generation-status: "record<errorMessage: string, fileSize: int, inProgress: bool, lastGenerated: string, lastInvocationId: string, queued: string, reportType: string, success: bool>"
    generate-excel-report: "record<errorMessage: string, fileSize: int, inProgress: bool, lastGenerated: string, lastInvocationId: string, queued: string, reportType: string, success: bool>"
    get-excel-report: "record"
    download-excel-report: "record"
    get-accounting-marketing-metrics: "record<dimensions: table<displayName: string, index: int, items: list, type: string>, errors: table<details: record, message: string, type: string>, measures: table<displayName: string, index: int, type: string, units: string>, reportData: table<components: list, dimension: int, dimensionDisplayName: string, item: int, itemDisplayName: string, measures: list>, reportInfo: record>"
    list-accounts-categories: "record<results: table<accountRef: record, confirmed: record, suggested: record>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>"
    update-accounts-categories: "table<accountRef: record<id: string, name: string>, confirmed: record<detailType: string, subtype: string, type: string, modifiedDate: string>, suggested: record<detailType: string, subtype: string, type: string, modifiedDate: string>>"
    get-account-category: "record<accountRef: record<id: string, name: string>, confirmed: record<detailType: string, subtype: string, type: string, modifiedDate: string>, suggested: record<detailType: string, subtype: string, type: string, modifiedDate: string>>"
    update-account-category: "record<accountRef: record<id: string, name: string>, confirmed: record<detailType: string, subtype: string, type: string, modifiedDate: string>, suggested: record<detailType: string, subtype: string, type: string, modifiedDate: string>>"
    get-commerce-customer-retention-metrics: "record<dimensions: table<displayName: string, index: int, items: list, type: string>, errors: table<details: record, message: string, type: string>, measures: table<displayName: string, index: int, type: string, units: string>, reportData: table<components: list, dimension: int, dimensionDisplayName: string, item: int, itemDisplayName: string, measures: list>, reportInfo: record>"
    get-commerce-lifetime-value-metrics: "record<dimensions: table<displayName: string, index: int, items: list, type: string>, errors: table<details: record, message: string, type: string>, measures: table<displayName: string, index: int, type: string, units: string>, reportData: table<components: list, dimension: int, dimensionDisplayName: string, item: int, itemDisplayName: string, measures: list>, reportInfo: record>"
    get-commerce-orders-metrics: "record<dimensions: table<displayName: string, index: int, items: list, type: string>, errors: table<details: record, message: string, type: string>, measures: table<displayName: string, index: int, type: string, units: string>, reportData: table<components: list, dimension: int, dimensionDisplayName: string, item: int, itemDisplayName: string, measures: list>, reportInfo: record>"
    get-commerce-refunds-metrics: "record<dimensions: table<displayName: string, index: int, items: list, type: string>, errors: table<details: record, message: string, type: string>, measures: table<displayName: string, index: int, type: string, units: string>, reportData: table<components: list, dimension: int, dimensionDisplayName: string, item: int, itemDisplayName: string, measures: list>, reportInfo: record>"
    get-commerce-revenue-metrics: "record<dimensions: table<displayName: string, index: int, items: list, type: string>, errors: table<details: record, message: string, type: string>, measures: table<displayName: string, index: int, type: string, units: string>, reportData: table<components: list, dimension: int, dimensionDisplayName: string, item: int, itemDisplayName: string, measures: list>, reportInfo: record>"
    get-enhanced-balance-sheet: "record<dimensions: table<displayName: string, index: int, items: list, type: string>, errors: table<details: record, message: string, type: string>, measures: table<displayName: string, index: int, type: string, units: string>, reportData: table<components: list, dimension: int, dimensionDisplayName: string, item: int, itemDisplayName: string, measures: list>, reportInfo: record>"
    get-enhanced-profit-and-loss: "record<dimensions: table<displayName: string, index: int, items: list, type: string>, errors: table<details: record, message: string, type: string>, measures: table<displayName: string, index: int, type: string, units: string>, reportData: table<components: list, dimension: int, dimensionDisplayName: string, item: int, itemDisplayName: string, measures: list>, reportInfo: record>"
    get-enhanced-financial-metrics: "record<currency: string, errors: table<message: string, type: string>, metrics: table<errors: list, key: string, metricUnit: string, name: string, periods: list>, periodUnit: string>"
    get-recurring-revenue-metrics: "record<dimensions: table<displayName: string, index: int, items: list, type: string>, errors: table<details: record, message: string, type: string>, measures: table<displayName: string, index: int, type: string, units: string>, reportData: table<components: list, dimension: int, dimensionDisplayName: string, item: int, itemDisplayName: string, measures: list>, reportInfo: record>"
    request-recurring-revenue-metrics: "record<dimensions: table<displayName: string, index: int, items: list, type: string>, errors: table<details: record, message: string, type: string>, measures: table<displayName: string, index: int, type: string, units: string>, reportData: table<components: list, dimension: int, dimensionDisplayName: string, item: int, itemDisplayName: string, measures: list>, reportInfo: record>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-accounts-for-enhanced-balance-sheet" "get-enhanced-cash-flow-transactions" "get-enhanced-invoices-report" "get-accounts-for-enhanced-profit-and-loss" "list-available-account-categories" "get-data-integrity-details" "get-data-integrity-status" "get-data-integrity-summaries" "get-excel-report-generation-status" "generate-excel-report" "get-excel-report" "download-excel-report" "get-accounting-marketing-metrics" "list-accounts-categories" "update-accounts-categories" "get-account-category" "update-account-category" "get-commerce-customer-retention-metrics" "get-commerce-lifetime-value-metrics" "get-commerce-orders-metrics" "get-commerce-refunds-metrics" "get-commerce-revenue-metrics" "get-enhanced-balance-sheet" "get-enhanced-profit-and-loss" "get-enhanced-financial-metrics" "get-recurring-revenue-metrics" "request-recurring-revenue-metrics" "commands"] | sort) } | get name | first)
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

# Enhanced Balance Sheet Accounts
#
# GET /companies/{companyId}/reports/enhancedBalanceSheet/accounts
# Returns: record<reportInfo: record<companyName: string, currency: string, generatedDate: string, reportName: string>, reportItems: table<accountCategory: record, accountId: string, accountName: string, balance: float, date: string>>
# operationId: get-accounts-for-enhanced-balance-sheet
export def "get-accounts-for-enhanced-balance-sheet" [
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --report-date: string # The date in which the report is created up to. Users must specify a specific date, however the response will be provided for the full month. (required, e.g. 29-09-2020)
  --number-of-periods: int # The number of periods to return. There will be no pagination as a query parameter, however Codat will limit the number of periods to request to 12 periods. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/companies/{companyId}/reports/enhancedBalanceSheet/accounts"
    path_params: [{name: companyId, var: company_id}]
    query: [{name: reportDate, var: report_date, required: true}, {name: numberOfPeriods, var: number_of_periods, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, report_date: $report_date, number_of_periods: $number_of_periods
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get enhanced cash flow report
#
# GET /companies/{companyId}/reports/enhancedCashFlow/transactions
# Returns: record<dataSources: table<accounts: list>, reportInfo: record<companyName: string, generatedDate: string, pageNumber: int, pageSize: int, reportName: string, totalResults: int>, reportItems: table<transactions: list>>
# operationId: get-enhanced-cash-flow-transactions
export def "get-enhanced-cash-flow-transactions" [
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (required, format: int32, default: 1, e.g. 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100, e.g. 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/companies/{companyId}/reports/enhancedCashFlow/transactions"
    path_params: [{name: companyId, var: company_id}]
    query: [{name: page, var: page, required: true, default: 1}, {name: pageSize, var: page_size}, {name: query, var: query}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, page: $page, page_size: $page_size, query: $query
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enhanced Invoices Report
#
# GET /companies/{companyId}/reports/enhancedInvoices
# Returns: record<reportInfo: record<companyName: string, generatedDate: string, pageNumber: int, pageSize: int, reportName: string, totalResults: int>, reportItems: table<invoices: list>>
# operationId: get-enhanced-invoices-report
export def "get-enhanced-invoices-report" [
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (required, format: int32, default: 1, e.g. 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100, e.g. 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/companies/{companyId}/reports/enhancedInvoices"
    path_params: [{name: companyId, var: company_id}]
    query: [{name: page, var: page, required: true, default: 1}, {name: pageSize, var: page_size}, {name: query, var: query}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, page: $page, page_size: $page_size, query: $query
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enhanced Profit and Loss Accounts
#
# GET /companies/{companyId}/reports/enhancedProfitAndLoss/accounts
# Returns: record<reportInfo: record<companyName: string, currency: string, generatedDate: string, reportName: string>, reportItems: table<accountCategory: record, accountId: string, accountName: string, balance: float, date: string>>
# operationId: get-accounts-for-enhanced-profit-and-loss
export def "get-accounts-for-enhanced-profit-and-loss" [
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --report-date: string # The date in which the report is created up to. Users must specify a specific date, however the response will be provided for the full month. (required, e.g. 29-09-2020)
  --number-of-periods: int # The number of periods to return. There will be no pagination as a query parameter, however Codat will limit the number of periods to request to 12 periods. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/companies/{companyId}/reports/enhancedProfitAndLoss/accounts"
    path_params: [{name: companyId, var: company_id}]
    query: [{name: reportDate, var: report_date, required: true}, {name: numberOfPeriods, var: number_of_periods, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, report_date: $report_date, number_of_periods: $number_of_periods
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List account categories
#
# GET /data/assess/accounts/categories
# DEPRECATED
# Returns: table<detailType: string, subtype: string, type: string, detailTypeDescription: string, detailTypeDisplayName: string, subtypeDisplayName: string>
# operationId: list-available-account-categories
@deprecated
export def "list-available-account-categories" [
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
    path: "/data/assess/accounts/categories"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists data integrity details for date type
#
# GET /data/companies/{companyId}/assess/dataTypes/{dataType}/dataIntegrity/details
# Returns: record<results: table<amount: float, connectionId: string, currency: string, date: string, description: string, id: string, matches: list, type: string>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>
# operationId: get-data-integrity-details
export def "get-data-integrity-details" [
  company_id: string
  data_type: string@data-type-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (required, format: int32, default: 1, e.g. 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100, e.g. 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results). (e.g. -modifiedDate)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/data/companies/{companyId}/assess/dataTypes/{dataType}/dataIntegrity/details"
    path_params: [{name: companyId, var: company_id}, {name: dataType, var: data_type}]
    query: [{name: page, var: page, required: true, default: 1}, {name: pageSize, var: page_size}, {name: query, var: query}, {name: orderBy, var: order_by}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, data_type: $data_type, page: $page, page_size: $page_size, query: $query, order_by: $order_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get data integrity status
#
# GET /data/companies/{companyId}/assess/dataTypes/{dataType}/dataIntegrity/status
# Returns: record<metadata: table<type: string, amounts: record, connectionIds: record, dates: record, statusInfo: record>>
# operationId: get-data-integrity-status
export def "get-data-integrity-status" [
  company_id: string
  data_type: string@data-type-completer
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
    path: "/data/companies/{companyId}/assess/dataTypes/{dataType}/dataIntegrity/status"
    path_params: [{name: companyId, var: company_id}, {name: dataType, var: data_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, data_type: $data_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get data integrity summary
#
# GET /data/companies/{companyId}/assess/dataTypes/{dataType}/dataIntegrity/summaries
# Returns: record<summaries: table<type: string, byAmount: record, byCount: record>>
# operationId: get-data-integrity-summaries
export def "get-data-integrity-summaries" [
  company_id: string
  data_type: string@data-type-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/data/companies/{companyId}/assess/dataTypes/{dataType}/dataIntegrity/summaries"
    path_params: [{name: companyId, var: company_id}, {name: dataType, var: data_type}]
    query: [{name: query, var: query}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, data_type: $data_type, query: $query
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get status of Excel report
#
# GET /data/companies/{companyId}/assess/excel
# Returns: record<errorMessage: string, fileSize: int, inProgress: bool, lastGenerated: string, lastInvocationId: string, queued: string, reportType: string, success: bool>
# operationId: get-excel-report-generation-status
export def "get-excel-report-generation-status" [
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --report-type: string@report-type-completer # The type of report you want to generate and download. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/data/companies/{companyId}/assess/excel"
    path_params: [{name: companyId, var: company_id}]
    query: [{name: reportType, var: report_type, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, report_type: $report_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generate an Excel report
#
# POST /data/companies/{companyId}/assess/excel
# Returns: record<errorMessage: string, fileSize: int, inProgress: bool, lastGenerated: string, lastInvocationId: string, queued: string, reportType: string, success: bool>
# operationId: generate-excel-report
export def "generate-excel-report" [
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --report-type: string@report-type-completer # The type of report you want to generate and download. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/data/companies/{companyId}/assess/excel"
    path_params: [{name: companyId, var: company_id}]
    query: [{name: reportType, var: report_type, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, report_type: $report_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download generated excel report
#
# GET /data/companies/{companyId}/assess/excel/download
# Returns: record
# operationId: get-excel-report
export def "get-excel-report" [
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --report-type: string@report-type-completer # The type of report you want to generate and download. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/data/companies/{companyId}/assess/excel/download"
    path_params: [{name: companyId, var: company_id}]
    query: [{name: reportType, var: report_type, required: true}]
    accept: ["application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, report_type: $report_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download generated excel report
#
# POST /data/companies/{companyId}/assess/excel/download
# DEPRECATED
# Returns: record
# operationId: download-excel-report
@deprecated
export def "download-excel-report" [
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --report-type: string@report-type-completer # The type of report you want to generate and download. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/data/companies/{companyId}/assess/excel/download"
    path_params: [{name: companyId, var: company_id}]
    query: [{name: reportType, var: report_type, required: true}]
    accept: ["application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, report_type: $report_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the marketing metrics from an accounting source for a given company.
#
# GET /data/companies/{companyId}/connections/{connectionId}/assess/accountingMetrics/marketing
# Returns: record<dimensions: table<displayName: string, index: int, items: list, type: string>, errors: table<details: record, message: string, type: string>, measures: table<displayName: string, index: int, type: string, units: string>, reportData: table<components: list, dimension: int, dimensionDisplayName: string, item: int, itemDisplayName: string, measures: list>, reportInfo: record>
# operationId: get-accounting-marketing-metrics
export def "get-accounting-marketing-metrics" [
  company_id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --report-date: string # The date in which the report is created up to. Users must specify a specific date, however the response will be provided for the full month. (required, e.g. 29-09-2020)
  --period-length: int # The number of months per period. E.g. 2 = 2 months per period. (required)
  --number-of-periods: int # The number of periods to return. There will be no pagination as a query parameter, however Codat will limit the number of periods to request to 12 periods. (required)
  --period-unit: string@period-unit-completer # The period unit of time returned. (required)
  --include-display-names: oneof<nothing, bool> # Shows the dimensionDisplayName and itemDisplayName in measures to make the report data human-readable.
  --show-input-values: oneof<nothing, bool> # If set to true, then the system includes the input values within the response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/data/companies/{companyId}/connections/{connectionId}/assess/accountingMetrics/marketing"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}]
    query: [{name: reportDate, var: report_date, required: true}, {name: periodLength, var: period_length, required: true}, {name: numberOfPeriods, var: number_of_periods, required: true}, {name: periodUnit, var: period_unit, required: true}, {name: includeDisplayNames, var: include_display_names}, {name: showInputValues, var: show_input_values}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, report_date: $report_date, period_length: $period_length, number_of_periods: $number_of_periods, period_unit: $period_unit, include_display_names: $include_display_names, show_input_values: $show_input_values
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List suggested and confirmed account categories
#
# GET /data/companies/{companyId}/connections/{connectionId}/assess/accounts/categories
# DEPRECATED
# Returns: record<results: table<accountRef: record, confirmed: record, suggested: record>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>
# operationId: list-accounts-categories
@deprecated
export def "list-accounts-categories" [
  company_id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (required, format: int32, default: 1, e.g. 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100, e.g. 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results). (e.g. -modifiedDate)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/data/companies/{companyId}/connections/{connectionId}/assess/accounts/categories"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}]
    query: [{name: page, var: page, required: true, default: 1}, {name: pageSize, var: page_size}, {name: query, var: query}, {name: orderBy, var: order_by}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, page: $page, page_size: $page_size, query: $query, order_by: $order_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Confirm categories for accounts
#
# PATCH /data/companies/{companyId}/connections/{connectionId}/assess/accounts/categories
# DEPRECATED
# Returns: table<accountRef: record<id: string, name: string>, confirmed: record<detailType: string, subtype: string, type: string, modifiedDate: string>, suggested: record<detailType: string, subtype: string, type: string, modifiedDate: string>>
# operationId: update-accounts-categories
@deprecated
export def "update-accounts-categories" [
  company_id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --categories: list # List of confirmed account categories set manually by the user. — item shape: {accountRef?: record, confirmed?: record}
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/data/companies/{companyId}/connections/{connectionId}/assess/accounts/categories"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: categories, var: categories}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, categories: $categories
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get suggested and/or confirmed category for a specific account
#
# GET /data/companies/{companyId}/connections/{connectionId}/assess/accounts/{accountId}/categories
# DEPRECATED
# Returns: record<accountRef: record<id: string, name: string>, confirmed: record<detailType: string, subtype: string, type: string, modifiedDate: string>, suggested: record<detailType: string, subtype: string, type: string, modifiedDate: string>>
# operationId: get-account-category
@deprecated
export def "get-account-category" [
  company_id: string
  connection_id: string
  account_id: string
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
    path: "/data/companies/{companyId}/connections/{connectionId}/assess/accounts/{accountId}/categories"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}, {name: accountId, var: account_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, account_id: $account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Patch account categories
#
# PATCH /data/companies/{companyId}/connections/{connectionId}/assess/accounts/{accountId}/categories
# DEPRECATED
# Returns: record<accountRef: record<id: string, name: string>, confirmed: record<detailType: string, subtype: string, type: string, modifiedDate: string>, suggested: record<detailType: string, subtype: string, type: string, modifiedDate: string>>
# operationId: update-account-category
@deprecated
export def "update-account-category" [
  company_id: string
  connection_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  confirmed: record # shape: {detailType?: string, subtype?: string, type?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/data/companies/{companyId}/connections/{connectionId}/assess/accounts/{accountId}/categories"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}, {name: accountId, var: account_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: confirmed, var: confirmed}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, account_id: $account_id, confirmed: $confirmed
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the customer retention metrics for a specific company.
#
# GET /data/companies/{companyId}/connections/{connectionId}/assess/commerceMetrics/customerRetention
# Returns: record<dimensions: table<displayName: string, index: int, items: list, type: string>, errors: table<details: record, message: string, type: string>, measures: table<displayName: string, index: int, type: string, units: string>, reportData: table<components: list, dimension: int, dimensionDisplayName: string, item: int, itemDisplayName: string, measures: list>, reportInfo: record>
# operationId: get-commerce-customer-retention-metrics
export def "get-commerce-customer-retention-metrics" [
  company_id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --report-date: string # The date in which the report is created up to. Users must specify a specific date, however the response will be provided for the full month. (required, e.g. 29-09-2020)
  --period-length: int # The number of months per period. E.g. 2 = 2 months per period. (required)
  --number-of-periods: int # The number of periods to return. There will be no pagination as a query parameter, however Codat will limit the number of periods to request to 12 periods. (required)
  --period-unit: string@period-unit-completer # The period unit of time returned. (required)
  --include-display-names: oneof<nothing, bool> # Shows the dimensionDisplayName and itemDisplayName in measures to make the report data human-readable.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/data/companies/{companyId}/connections/{connectionId}/assess/commerceMetrics/customerRetention"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}]
    query: [{name: reportDate, var: report_date, required: true}, {name: periodLength, var: period_length, required: true}, {name: numberOfPeriods, var: number_of_periods, required: true}, {name: periodUnit, var: period_unit, required: true}, {name: includeDisplayNames, var: include_display_names}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, report_date: $report_date, period_length: $period_length, number_of_periods: $number_of_periods, period_unit: $period_unit, include_display_names: $include_display_names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the lifetime value metric for a specific company.
#
# GET /data/companies/{companyId}/connections/{connectionId}/assess/commerceMetrics/lifetimeValue
# Returns: record<dimensions: table<displayName: string, index: int, items: list, type: string>, errors: table<details: record, message: string, type: string>, measures: table<displayName: string, index: int, type: string, units: string>, reportData: table<components: list, dimension: int, dimensionDisplayName: string, item: int, itemDisplayName: string, measures: list>, reportInfo: record>
# operationId: get-commerce-lifetime-value-metrics
export def "get-commerce-lifetime-value-metrics" [
  company_id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --report-date: string # The date in which the report is created up to. Users must specify a specific date, however the response will be provided for the full month. (required, e.g. 29-09-2020)
  --period-length: int # The number of months per period. E.g. 2 = 2 months per period. (required)
  --number-of-periods: int # The number of periods to return. There will be no pagination as a query parameter, however Codat will limit the number of periods to request to 12 periods. (required)
  --period-unit: string@period-unit-completer # The period unit of time returned. (required)
  --include-display-names: oneof<nothing, bool> # Shows the dimensionDisplayName and itemDisplayName in measures to make the report data human-readable.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/data/companies/{companyId}/connections/{connectionId}/assess/commerceMetrics/lifetimeValue"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}]
    query: [{name: reportDate, var: report_date, required: true}, {name: periodLength, var: period_length, required: true}, {name: numberOfPeriods, var: number_of_periods, required: true}, {name: periodUnit, var: period_unit, required: true}, {name: includeDisplayNames, var: include_display_names}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, report_date: $report_date, period_length: $period_length, number_of_periods: $number_of_periods, period_unit: $period_unit, include_display_names: $include_display_names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get order information for a specific company
#
# GET /data/companies/{companyId}/connections/{connectionId}/assess/commerceMetrics/orders
# Returns: record<dimensions: table<displayName: string, index: int, items: list, type: string>, errors: table<details: record, message: string, type: string>, measures: table<displayName: string, index: int, type: string, units: string>, reportData: table<components: list, dimension: int, dimensionDisplayName: string, item: int, itemDisplayName: string, measures: list>, reportInfo: record>
# operationId: get-commerce-orders-metrics
export def "get-commerce-orders-metrics" [
  company_id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --report-date: string # The date in which the report is created up to. Users must specify a specific date, however the response will be provided for the full month. (required, e.g. 29-09-2020)
  --period-length: int # The number of months per period. E.g. 2 = 2 months per period. (required)
  --number-of-periods: int # The number of periods to return. There will be no pagination as a query parameter, however Codat will limit the number of periods to request to 12 periods. (required)
  --period-unit: string@period-unit-completer # The period unit of time returned. (required)
  --include-display-names: oneof<nothing, bool> # Shows the dimensionDisplayName and itemDisplayName in measures to make the report data human-readable.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/data/companies/{companyId}/connections/{connectionId}/assess/commerceMetrics/orders"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}]
    query: [{name: reportDate, var: report_date, required: true}, {name: periodLength, var: period_length, required: true}, {name: numberOfPeriods, var: number_of_periods, required: true}, {name: periodUnit, var: period_unit, required: true}, {name: includeDisplayNames, var: include_display_names}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, report_date: $report_date, period_length: $period_length, number_of_periods: $number_of_periods, period_unit: $period_unit, include_display_names: $include_display_names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the refunds information for a specific company
#
# GET /data/companies/{companyId}/connections/{connectionId}/assess/commerceMetrics/refunds
# Returns: record<dimensions: table<displayName: string, index: int, items: list, type: string>, errors: table<details: record, message: string, type: string>, measures: table<displayName: string, index: int, type: string, units: string>, reportData: table<components: list, dimension: int, dimensionDisplayName: string, item: int, itemDisplayName: string, measures: list>, reportInfo: record>
# operationId: get-commerce-refunds-metrics
export def "get-commerce-refunds-metrics" [
  company_id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --report-date: string # The date in which the report is created up to. Users must specify a specific date, however the response will be provided for the full month. (required, e.g. 29-09-2020)
  --period-length: int # The number of months per period. E.g. 2 = 2 months per period. (required)
  --number-of-periods: int # The number of periods to return. There will be no pagination as a query parameter, however Codat will limit the number of periods to request to 12 periods. (required)
  --period-unit: string@period-unit-completer # The period unit of time returned. (required)
  --include-display-names: oneof<nothing, bool> # Shows the dimensionDisplayName and itemDisplayName in measures to make the report data human-readable.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/data/companies/{companyId}/connections/{connectionId}/assess/commerceMetrics/refunds"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}]
    query: [{name: reportDate, var: report_date, required: true}, {name: periodLength, var: period_length, required: true}, {name: numberOfPeriods, var: number_of_periods, required: true}, {name: periodUnit, var: period_unit, required: true}, {name: includeDisplayNames, var: include_display_names}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, report_date: $report_date, period_length: $period_length, number_of_periods: $number_of_periods, period_unit: $period_unit, include_display_names: $include_display_names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Commerce Revenue Metrics
#
# GET /data/companies/{companyId}/connections/{connectionId}/assess/commerceMetrics/revenue
# Returns: record<dimensions: table<displayName: string, index: int, items: list, type: string>, errors: table<details: record, message: string, type: string>, measures: table<displayName: string, index: int, type: string, units: string>, reportData: table<components: list, dimension: int, dimensionDisplayName: string, item: int, itemDisplayName: string, measures: list>, reportInfo: record>
# operationId: get-commerce-revenue-metrics
export def "get-commerce-revenue-metrics" [
  company_id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --report-date: string # The date in which the report is created up to. Users must specify a specific date, however the response will be provided for the full month. (required, e.g. 29-09-2020)
  --period-length: int # The number of months per period. E.g. 2 = 2 months per period. (required)
  --number-of-periods: int # The number of periods to return. There will be no pagination as a query parameter, however Codat will limit the number of periods to request to 12 periods. (required)
  --period-unit: string@period-unit-completer # The period unit of time returned. (required)
  --include-display-names: oneof<nothing, bool> # Shows the dimensionDisplayName and itemDisplayName in measures to make the report data human-readable.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/data/companies/{companyId}/connections/{connectionId}/assess/commerceMetrics/revenue"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}]
    query: [{name: reportDate, var: report_date, required: true}, {name: periodLength, var: period_length, required: true}, {name: numberOfPeriods, var: number_of_periods, required: true}, {name: periodUnit, var: period_unit, required: true}, {name: includeDisplayNames, var: include_display_names}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, report_date: $report_date, period_length: $period_length, number_of_periods: $number_of_periods, period_unit: $period_unit, include_display_names: $include_display_names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enhanced Balance Sheet
#
# GET /data/companies/{companyId}/connections/{connectionId}/assess/enhancedBalanceSheet
# DEPRECATED
# Returns: record<dimensions: table<displayName: string, index: int, items: list, type: string>, errors: table<details: record, message: string, type: string>, measures: table<displayName: string, index: int, type: string, units: string>, reportData: table<components: list, dimension: int, dimensionDisplayName: string, item: int, itemDisplayName: string, measures: list>, reportInfo: record>
# operationId: get-enhanced-balance-sheet
@deprecated
export def "get-enhanced-balance-sheet" [
  company_id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --report-date: string # The date in which the report is created up to. Users must specify a specific date, however the response will be provided for the full month. (required, e.g. 29-09-2020)
  --period-length: int # The number of months per period. E.g. 2 = 2 months per period. (required)
  --number-of-periods: int # The number of periods to return. There will be no pagination as a query parameter, however Codat will limit the number of periods to request to 12 periods. (required)
  --include-display-names: oneof<nothing, bool> # Shows the dimensionDisplayName and itemDisplayName in measures to make the report data human-readable.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/data/companies/{companyId}/connections/{connectionId}/assess/enhancedBalanceSheet"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}]
    query: [{name: reportDate, var: report_date, required: true}, {name: periodLength, var: period_length, required: true}, {name: numberOfPeriods, var: number_of_periods, required: true}, {name: includeDisplayNames, var: include_display_names}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, report_date: $report_date, period_length: $period_length, number_of_periods: $number_of_periods, include_display_names: $include_display_names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enhanced Profit and Loss
#
# GET /data/companies/{companyId}/connections/{connectionId}/assess/enhancedProfitAndLoss
# DEPRECATED
# Returns: record<dimensions: table<displayName: string, index: int, items: list, type: string>, errors: table<details: record, message: string, type: string>, measures: table<displayName: string, index: int, type: string, units: string>, reportData: table<components: list, dimension: int, dimensionDisplayName: string, item: int, itemDisplayName: string, measures: list>, reportInfo: record>
# operationId: get-enhanced-profit-and-loss
@deprecated
export def "get-enhanced-profit-and-loss" [
  company_id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --report-date: string # The date in which the report is created up to. Users must specify a specific date, however the response will be provided for the full month. (required, e.g. 29-09-2020)
  --period-length: int # The number of months per period. E.g. 2 = 2 months per period. (required)
  --number-of-periods: int # The number of periods to return. There will be no pagination as a query parameter, however Codat will limit the number of periods to request to 12 periods. (required)
  --include-display-names: oneof<nothing, bool> # Shows the dimensionDisplayName and itemDisplayName in measures to make the report data human-readable.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/data/companies/{companyId}/connections/{connectionId}/assess/enhancedProfitAndLoss"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}]
    query: [{name: reportDate, var: report_date, required: true}, {name: periodLength, var: period_length, required: true}, {name: numberOfPeriods, var: number_of_periods, required: true}, {name: includeDisplayNames, var: include_display_names}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, report_date: $report_date, period_length: $period_length, number_of_periods: $number_of_periods, include_display_names: $include_display_names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List financial metrics
#
# GET /data/companies/{companyId}/connections/{connectionId}/assess/financialMetrics
# DEPRECATED
# Returns: record<currency: string, errors: table<message: string, type: string>, metrics: table<errors: list, key: string, metricUnit: string, name: string, periods: list>, periodUnit: string>
# operationId: get-enhanced-financial-metrics
@deprecated
export def "get-enhanced-financial-metrics" [
  company_id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --report-date: string # The date in which the report is created up to. Users must specify a specific date, however the response will be provided for the full month. (required, e.g. 29-09-2020)
  --period-length: int # The number of months per period. E.g. 2 = 2 months per period. (required)
  --number-of-periods: int # The number of periods to return. There will be no pagination as a query parameter, however Codat will limit the number of periods to request to 12 periods. (required)
  --show-metric-inputs: oneof<nothing, bool> # If set to true, then the system includes the input values within the response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/data/companies/{companyId}/connections/{connectionId}/assess/financialMetrics"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}]
    query: [{name: reportDate, var: report_date, required: true}, {name: periodLength, var: period_length, required: true}, {name: numberOfPeriods, var: number_of_periods, required: true}, {name: showMetricInputs, var: show_metric_inputs}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, report_date: $report_date, period_length: $period_length, number_of_periods: $number_of_periods, show_metric_inputs: $show_metric_inputs
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get key metrics for subscription revenue
#
# GET /data/companies/{companyId}/connections/{connectionId}/assess/subscriptions/mrr
# Returns: record<dimensions: table<displayName: string, index: int, items: list, type: string>, errors: table<details: record, message: string, type: string>, measures: table<displayName: string, index: int, type: string, units: string>, reportData: table<components: list, dimension: int, dimensionDisplayName: string, item: int, itemDisplayName: string, measures: list>, reportInfo: record>
# operationId: get-recurring-revenue-metrics
export def "get-recurring-revenue-metrics" [
  company_id: string
  connection_id: string
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
    path: "/data/companies/{companyId}/connections/{connectionId}/assess/subscriptions/mrr"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request production of key subscription revenue metrics
#
# GET /data/companies/{companyId}/connections/{connectionId}/assess/subscriptions/process
# Returns: record<dimensions: table<displayName: string, index: int, items: list, type: string>, errors: table<details: record, message: string, type: string>, measures: table<displayName: string, index: int, type: string, units: string>, reportData: table<components: list, dimension: int, dimensionDisplayName: string, item: int, itemDisplayName: string, measures: list>, reportInfo: record>
# operationId: request-recurring-revenue-metrics
export def "request-recurring-revenue-metrics" [
  company_id: string
  connection_id: string
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
    path: "/data/companies/{companyId}/connections/{connectionId}/assess/subscriptions/process"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
