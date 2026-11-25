# Auto-generated client for Telnyx API v2.0.0
# Source: https://api.apis.guru/v2/specs/telnyx.com/2.0.0/openapi.json
# Auth: --token flag or $env.TELNYX_API_TOKEN

const CLIENT = {
  base_url: "https://api.telnyx.com/v2"
  token_env_var: "TELNYX_API_TOKEN"
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

def base-url-completer [] { ["https://api.telnyx.com/v2"] }
def auth-scheme-completer [] { ["bearer" "none"] }

# Completers for enum parameters
def status-completer [] { ["disabled" "enabled" "standby"] }
def action-completer [] { ["activate" "deactivate"] }
def sort-completer [] { ["business_name" "created_at" "first_name" "last_name" "street_address"] }
def sort-completer-1 [] { ["-active" "-created_at" "-name" "-short_name" "-updated_at" "active" "created_at" "name" "short_name" "updated_at"] }
def filter-number-type-completer [] { ["toll-free"] }
def filter-number-type-completer-1 [] { ["local" "mobile" "national" "toll-free"] }
def sort-completer-2 [] { ["active" "connection_name" "created_at"] }
def anchorsite-override-completer [] { ["Ashburn, VA" "Chicago, IL" "Latency" "San Jose, CA"] }
def dtmf-type-completer [] { ["Inband" "RFC 2833" "SIP INFO"] }
def webhook-api-version-completer [] { ["1" "2"] }
def filter-status-completer [] { ["delivered" "failed"] }
def filter-type-completer [] { ["command" "webhook"] }
def answering-machine-detection-completer [] { ["detect" "detect_beep" "detect_words" "disabled" "greeting_end"] }
def webhook-url-method-completer [] { ["GET" "POST"] }
def stream-type-completer [] { ["decrypted" "raw"] }
def language-completer [] { ["arb" "cmn-CN" "cy-GB" "da-DK" "de-DE" "en-AU" "en-GB" "en-GB-WLS" "en-IN" "en-US" "es-ES" "es-MX" "es-US" "fr-CA" "fr-FR" "hi-IN" "is-IS" "it-IT" "ja-JP" "ko-KR" "nb-NO" "nl-NL" "pl-PL" "pt-BR" "pt-PT" "ro-RO" "ru-RU" "sv-SE" "tr-TR"] }
def payload-type-completer [] { ["ssml" "text"] }
def service-level-completer [] { ["basic" "premium"] }
def voice-completer [] { ["female" "male"] }
def channels-completer [] { ["dual" "single"] }
def format-completer [] { ["mp3" "wav"] }
def cause-completer [] { ["CALL_REJECTED" "USER_BUSY"] }
def language-completer-1 [] { ["de" "en" "es" "fr" "it" "pl"] }
def comment-record-type-completer [] { ["number_order" "number_order_phone_number" "sub_number_order"] }
def beep-enabled-completer [] { ["always" "never" "on_enter" "on_exit"] }
def supervisor-role-completer [] { ["barge" "monitor" "none" "whisper"] }
def anchorsite-override-completer-1 [] { ["Amsterdam, Netherlands" "Ashburn, VA" "Chicago, IL" "Frankfurt, Germany" "Latency" "London, UK" "San Jose, CA" "Sydney, Australia" "Toronto, Canada" "Vancouver, Canada"] }
def encrypted-media-completer [] { ["SRTP" "ZRTP"] }
def sip-uri-calling-preference-completer [] { ["disabled" "internal" "unrestricted"] }
def accept-completer [] { ["*" "application/json"] }
def transport-protocol-completer [] { ["TCP" "TLS" "UDP"] }
def filter-number-type-completer-2 [] { ["did" "toll-free"] }
def filter-phone-number-type-completer [] { ["landline" "local" "mobile" "national" "shared_cost" "toll_free"] }
def filter-country-code-completer [] { ["CA" "GB" "US"] }
def filter-group-by-completer [] { ["locality" "national_destination_code" "npa" "nxx" "rate_center"] }
def sort-completer-3 [] { ["created_at" "email"] }
def accept-completer-1 [] { ["*/*" "application/json"] }
def direction-completer [] { ["INBOUND" "OUTBOUND"] }
def status-completer-1 [] { ["DELIVERED" "DLR_TIMEOUT" "DLR_UNCONFIRMED" "FAILED" "GW_REJECT" "GW_TIMEOUT" "RECEIVED"] }
def message-type-completer [] { ["audio" "contacts" "document" "hsm" "image" "location" "template" "text" "unknown" "video" "voice"] }
def product-completer [] { ["ALPHANUMERIC_ID" "LONG_CODE" "RCS" "SHORT_CODE" "SHORT_CODE_FTEU" "TOLL_FREE"] }
def type-completer [] { ["MMS" "SMS"] }
def time-frame-completer [] { ["1h" "24h" "30d" "3d" "3h" "7d"] }
def webhook-api-version-completer-1 [] { ["1" "2" "2010-04-01"] }
def filter-channel-type-id-eq-completer [] { ["email" "sms" "voice" "webhook"] }
def channel-type-id-completer [] { ["email" "sms" "voice" "webhook"] }
def filter-associated-record-type-eq-completer [] { ["account" "phone_number"] }
def filter-status-eq-completer [] { ["delete-pending" "delete-received" "delete-submitted" "deleted" "enable-pending" "enable-received" "enable-submtited" "enabled"] }
def type-completer-1 [] { ["caller-name" "carrier"] }
def filter-status-completer-1 [] { ["completed" "failed" "in-progress"] }
def filter-type-completer-1 [] { ["sim_card_network_preferences"] }
def sort-completer-4 [] { ["-created_at" "-enabled" "-name" "-service_plan" "-traffic_type" "-usage_payment_method" "created_at" "enabled" "name" "service_plan" "traffic_type" "usage_payment_method"] }
def service-plan-completer [] { ["global" "international" "us"] }
def traffic-type-completer [] { ["conversational" "short_duration"] }
def usage-payment-method-completer [] { ["rate-deck" "tariff"] }
def filter-type-completer-2 [] { ["delete_phone_number_block"] }
def filter-status-completer-2 [] { ["completed" "failed" "in_progress" "pending"] }
def sort-completer-5 [] { ["created_at"] }
def filter-status-completer-3 [] { ["active" "deleted" "emergency_only" "port_failed" "port_out_pending" "port_pending" "ported_out" "purchase_failed" "purchase_pending"] }
def filter-usage-payment-method-completer [] { ["channel" "pay-per-minute"] }
def sort-completer-6 [] { ["connection_name" "phone_number" "purchased_at" "usage_payment_method"] }
def filter-type-completer-3 [] { ["delete_phone_numbers" "update_emergency_settings" "update_phone_numbers"] }
def number-level-routing-completer [] { ["disabled" "enabled"] }
def usage-payment-method-completer-1 [] { ["channel" "pay-per-minute"] }
def filter-misc-type-completer [] { ["full" "partial"] }
def sort-completer-7 [] { ["-activation_settings.foc_datetime_requested" "-created_at" "activation_settings.foc_datetime_requested" "created_at"] }
def filter-activation-status-completer [] { ["Activate RDY" "Active" "Cancel Pending" "Canceled" "Concurred" "Concurrence Sent" "Conflict" "Disconnect Pending" "Failed" "New" "Old" "Pending" "Sending"] }
def filter-portability-status-completer [] { ["confirmed" "pending" "provisional"] }
def filter-status-completer-4 [] { ["authorized" "canceled" "pending" "ported" "rejected" "rejected-pending"] }
def status-completer-2 [] { ["authorized" "rejected"] }
def aggregation-type-completer [] { ["BILLING_GROUP" "CONNECTION" "NO_AGGREGATION" "TAG"] }
def product-breakdown-completer [] { ["COUNTRY" "DID_VS_TOLL_FREE" "DID_VS_TOLL_FREE_PER_COUNTRY" "NO_BREAKDOWN"] }
def aggregation-type-completer-1 [] { ["NO_AGGREGATION" "PROFILE" "TAGS"] }
def message-type-completer-1 [] { ["MMS" "SMS"] }
def sort-completer-8 [] { ["created_at" "name" "updated_at"] }
def filter-phone-number-type-completer-1 [] { ["local" "national" "toll-free"] }
def filter-action-completer [] { ["ordering" "porting"] }
def sort-completer-9 [] { ["action" "country_code" "locality" "phone_number_type"] }
def filter-type-completer-4 [] { ["remove_private_wireless_gateway" "set_private_wireless_gateway"] }
def status-callback-method-completer [] { ["get" "post"] }
def voice-method-completer [] { ["get" "post"] }
def currency-completer [] { ["AUD" "CAD" "EUR" "GBP" "USD"] }
def filter-status-eq-completer-1 [] { ["delivered" "failed"] }
def blocking-completer [] { ["no_wait" "wait"] }
def type-completer-2 [] { ["audio" "contacts" "document" "hsm" "image" "location" "template" "text" "unknown" "video" "voice"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    delete-bulk-telephony-credential: "record<data: record<credentials: int>>"
    update-bulk-telephony-credential: "record<data: record<credentials: int>>"
    create-bulk-telephony-credential: "record<data: record<credentials: int>>"
    bulk-sim-card-network-preferences: "record<data: table<created_at: string, mobile_operator_networks_preferences: list, ota_updates: list, record_type: string, sim_card_id: string, updated_at: string>, errors: table<code: string, detail: string, meta: record, source: record, title: string>>"
    sim-card-register: "record<data: table<created_at: string, iccid: string, id: string, imsi: string, msisdn: string, record_type: string, sim_card_group_id: string, status: string, tags: list, updated_at: string>, errors: table<code: string, detail: string, meta: record, source: record, title: string>>"
    bulk-credential-action: "record<data: record<credentials: int>>"
    find-addresss: "record<data: table<address_book: bool, administrative_area: string, borough: string, business_name: string, country_code: string, created_at: string, customer_reference: string, extended_address: string, first_name: string, id: string, last_name: string, locality: string, neighborhood: string, phone_number: string, postal_code: string, record_type: string, street_address: string, updated_at: string, validate_address: bool>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    create-address: "record<data: record<address_book: bool, administrative_area: string, borough: string, business_name: string, country_code: string, created_at: string, customer_reference: string, extended_address: string, first_name: string, id: string, last_name: string, locality: string, neighborhood: string, phone_number: string, postal_code: string, record_type: string, street_address: string, updated_at: string, validate_address: bool>>"
    validate-address: "record<data: record<errors: list<record>, record_type: string, result: string, suggested: record<administrative_area: string, country_code: string, extended_address: string, locality: string, postal_code: string, street_address: string>>>"
    delete-address: "record<data: record<address_book: bool, administrative_area: string, borough: string, business_name: string, country_code: string, created_at: string, customer_reference: string, extended_address: string, first_name: string, id: string, last_name: string, locality: string, neighborhood: string, phone_number: string, postal_code: string, record_type: string, street_address: string, updated_at: string, validate_address: bool>>"
    get-address: "record<data: record<address_book: bool, administrative_area: string, borough: string, business_name: string, country_code: string, created_at: string, customer_reference: string, extended_address: string, first_name: string, id: string, last_name: string, locality: string, neighborhood: string, phone_number: string, postal_code: string, record_type: string, street_address: string, updated_at: string, validate_address: bool>>"
    find-authentication-providers: "record<data: table<active: bool, created_at: string, id: string, name: string, organization_id: string, record_type: string, settings: record, short_name: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    create-authentication-provider: "record<data: record<active: bool, created_at: string, id: string, name: string, organization_id: string, record_type: string, settings: record<assertion_consumer_service_url: string, idp_cert_fingerprint: string, idp_cert_fingerprint_algorithm: string, idp_entity_id: string, idp_sso_target_url: string, name_identifier_format: string, service_provider_entity_id: string>, short_name: string, updated_at: string>>"
    delete-authentication-provider: "record<data: record<active: bool, created_at: string, id: string, name: string, organization_id: string, record_type: string, settings: record<assertion_consumer_service_url: string, idp_cert_fingerprint: string, idp_cert_fingerprint_algorithm: string, idp_entity_id: string, idp_sso_target_url: string, name_identifier_format: string, service_provider_entity_id: string>, short_name: string, updated_at: string>>"
    get-authentication-provider: "record<data: record<active: bool, created_at: string, id: string, name: string, organization_id: string, record_type: string, settings: record<assertion_consumer_service_url: string, idp_cert_fingerprint: string, idp_cert_fingerprint_algorithm: string, idp_entity_id: string, idp_sso_target_url: string, name_identifier_format: string, service_provider_entity_id: string>, short_name: string, updated_at: string>>"
    update-authentication-provider: "record<data: record<active: bool, created_at: string, id: string, name: string, organization_id: string, record_type: string, settings: record<assertion_consumer_service_url: string, idp_cert_fingerprint: string, idp_cert_fingerprint_algorithm: string, idp_entity_id: string, idp_sso_target_url: string, name_identifier_format: string, service_provider_entity_id: string>, short_name: string, updated_at: string>>"
    list-available-phone-number-blocks: "record<data: table<cost_information: record, features: list, range: int, record_type: string, region_information: list, starting_number: string>, meta: record<best_effort_results: int, total_results: int>>"
    list-available-phone-numbers: "record<data: table<best_effort: bool, cost_information: record, features: list, phone_number: string, quickship: bool, record_type: string, region_information: list, reservable: bool, vanity_format: string>, meta: record<best_effort_results: int, total_results: int>>"
    get-user-balance: "record<data: record<available_credit: string, balance: string, credit_limit: string, currency: string, record_type: string>>"
    list-billing-groups: "record<data: table<created_at: string, deleted_at: string, id: string, name: string, organization_id: string, record_type: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    create-billing-group: "record<data: record<created_at: string, deleted_at: string, id: string, name: string, organization_id: string, record_type: string, updated_at: string>>"
    delete-billing-group: "record<data: record<created_at: string, deleted_at: string, id: string, name: string, organization_id: string, record_type: string, updated_at: string>>"
    retrieve-billing-group: "record<data: record<created_at: string, deleted_at: string, id: string, name: string, organization_id: string, record_type: string, updated_at: string>>"
    update-billing-group: "record<data: record<created_at: string, deleted_at: string, id: string, name: string, organization_id: string, record_type: string, updated_at: string>>"
    list-call-control-applications: "record<data: table<active: bool, anchorsite_override: string, application_name: string, created_at: string, dtmf_type: string, first_command_timeout: bool, first_command_timeout_secs: int, id: string, inbound: record, outbound: record, record_type: string, updated_at: string, webhook_api_version: string, webhook_event_failover_url: string, webhook_event_url: string, webhook_timeout_secs: int>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    create-call-control-application: "record<data: record<active: bool, anchorsite_override: string, application_name: string, created_at: string, dtmf_type: string, first_command_timeout: bool, first_command_timeout_secs: int, id: string, inbound: record<channel_limit: int, sip_subdomain: string, sip_subdomain_receive_settings: string>, outbound: record<channel_limit: int, outbound_voice_profile_id: string>, record_type: string, updated_at: string, webhook_api_version: string, webhook_event_failover_url: string, webhook_event_url: string, webhook_timeout_secs: int>>"
    delete-call-control-application: "record<data: record<active: bool, anchorsite_override: string, application_name: string, created_at: string, dtmf_type: string, first_command_timeout: bool, first_command_timeout_secs: int, id: string, inbound: record<channel_limit: int, sip_subdomain: string, sip_subdomain_receive_settings: string>, outbound: record<channel_limit: int, outbound_voice_profile_id: string>, record_type: string, updated_at: string, webhook_api_version: string, webhook_event_failover_url: string, webhook_event_url: string, webhook_timeout_secs: int>>"
    retrieve-call-control-application: "record<data: record<active: bool, anchorsite_override: string, application_name: string, created_at: string, dtmf_type: string, first_command_timeout: bool, first_command_timeout_secs: int, id: string, inbound: record<channel_limit: int, sip_subdomain: string, sip_subdomain_receive_settings: string>, outbound: record<channel_limit: int, outbound_voice_profile_id: string>, record_type: string, updated_at: string, webhook_api_version: string, webhook_event_failover_url: string, webhook_event_url: string, webhook_timeout_secs: int>>"
    update-call-control-application: "record<data: record<active: bool, anchorsite_override: string, application_name: string, created_at: string, dtmf_type: string, first_command_timeout: bool, first_command_timeout_secs: int, id: string, inbound: record<channel_limit: int, sip_subdomain: string, sip_subdomain_receive_settings: string>, outbound: record<channel_limit: int, outbound_voice_profile_id: string>, record_type: string, updated_at: string, webhook_api_version: string, webhook_event_failover_url: string, webhook_event_url: string, webhook_timeout_secs: int>>"
    list-call-events: "record<data: table<call_leg_id: string, call_session_id: string, event_timestamp: string, metadata: record, name: string, record_type: string, type: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    call-dial: "record<data: record<call_control_id: string, call_leg_id: string, call_session_id: string, is_alive: bool, record_type: string>>"
    retrieve-call-status: "record<data: record<call_control_id: string, call_leg_id: string, call_session_id: string, is_alive: bool, record_type: string>>"
    call-answer: "record<data: record<result: string>>"
    call-bridge: "record<data: record<result: string>>"
    call-enqueue: "record<data: record<result: string>>"
    call-fork-start: "record<data: record<result: string>>"
    call-fork-stop: "record<data: record<result: string>>"
    call-gather-stop: "record<data: record<result: string>>"
    call-gather-using-audio: "record<data: record<result: string>>"
    call-gather-using-speak: "record<data: record<result: string>>"
    call-hangup: "record<data: record<result: string>>"
    leave-queue: "record<data: record<result: string>>"
    call-playback-start: "record<data: record<result: string>>"
    call-playback-stop: "record<data: record<result: string>>"
    call-record-pause: "record<data: record<result: string>>"
    call-record-resume: "record<data: record<result: string>>"
    call-record-start: "record<data: record<result: string>>"
    call-record-stop: "record<data: record<result: string>>"
    call-refer: "record<data: record<result: string>>"
    call-reject: "record<data: record<result: string>>"
    call-send-dtmf: "record<data: record<result: string>>"
    call-speak: "record<data: record<result: string>>"
    call-transcription-start: "record<data: record<result: string>>"
    call-transcription-stop: "record<data: record<result: string>>"
    call-transfer: "record<data: record<result: string>>"
    list-comments: "record<data: table<body: string, comment_record_id: string, comment_record_type: string, commenter: string, commenter_type: string, created_at: string, id: string, read_at: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    create-comment: "record<data: record<body: string, comment_record_id: string, comment_record_type: string, commenter: string, commenter_type: string, created_at: string, id: string, read_at: string, updated_at: string>>"
    retrieve-comment: "record<data: record<body: string, comment_record_id: string, comment_record_type: string, commenter: string, commenter_type: string, created_at: string, id: string, read_at: string, updated_at: string>>"
    mark-comment-read: "record<data: record<body: string, comment_record_id: string, comment_record_type: string, commenter: string, commenter_type: string, created_at: string, id: string, read_at: string, updated_at: string>>"
    list-conferences: "record<data: table<connection_id: string, created_at: string, end_reason: string, ended_by: record, expires_at: string, id: string, name: string, record_type: string, region: string, status: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    create-conference: "record<data: record<connection_id: string, created_at: string, end_reason: string, ended_by: record<call_control_id: string, call_session_id: string>, expires_at: string, id: string, name: string, record_type: string, region: string, status: string, updated_at: string>>"
    list-conference-participants: "record<data: table<call_control_id: string, call_leg_id: string, conference: record, created_at: string, end_conference_on_exit: bool, id: string, muted: bool, on_hold: bool, record_type: string, soft_end_conference_on_exit: bool, status: string, updated_at: string, whisper_call_control_ids: list>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    retrieve-conference: "record<data: record<connection_id: string, created_at: string, end_reason: string, ended_by: record<call_control_id: string, call_session_id: string>, expires_at: string, id: string, name: string, record_type: string, region: string, status: string, updated_at: string>>"
    conference-dial-participant-in: "record<data: record<result: string>>"
    conference-hold-participants: "record<data: record<result: string>>"
    conference-join: "record<data: record<result: string>>"
    conference-leave: "record<data: record<result: string>>"
    conference-mute-participants: "record<data: record<result: string>>"
    conference-play-audio: "record<data: record<result: string>>"
    conference-start-recording: "record<data: record<result: string>>"
    conference-stop-recording: "record<data: record<result: string>>"
    conference-speak-text: "record<data: record<result: string>>"
    conference-stop-audio: "record<data: record<result: string>>"
    conference-unhold-participants: "record<data: record<result: string>>"
    conference-unmute-participants: "record<data: record<result: string>>"
    conference-update: "record<data: record<result: string>>"
    list-connections: "record<data: table<active: bool, anchorsite_override: string, connection_name: string, created_at: string, id: string, outbound_voice_profile_id: string, record_type: string, updated_at: string, webhook_api_version: string, webhook_event_failover_url: string, webhook_event_url: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    retrieve-connection: "record<data: record<active: bool, anchorsite_override: string, connection_name: string, created_at: string, id: string, outbound_voice_profile_id: string, record_type: string, updated_at: string, webhook_api_version: string, webhook_event_failover_url: string, webhook_event_url: string>>"
    list-credential-connections: "record<data: table<active: bool, anchorsite_override: string, connection_name: string, created_at: string, default_on_hold_comfort_noise_enabled: bool, dtmf_type: string, encode_contact_header_enabled: bool, encrypted_media: string, id: string, inbound: record, onnet_t38_passthrough_enabled: bool, outbound: record, password: string, record_type: string, rtcp_settings: record, sip_uri_calling_preference: string, updated_at: string, user_name: string, webhook_api_version: string, webhook_event_failover_url: string, webhook_event_url: string, webhook_timeout_secs: int>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    create-credential-connection: "record<data: record<active: bool, anchorsite_override: string, connection_name: string, created_at: string, default_on_hold_comfort_noise_enabled: bool, dtmf_type: string, encode_contact_header_enabled: bool, encrypted_media: string, id: string, inbound: record<ani_number_format: string, channel_limit: int, codecs: list, dnis_number_format: string, generate_ringback_tone: bool, isup_headers_enabled: bool, prack_enabled: bool, privacy_zone_enabled: bool, sip_compact_headers_enabled: bool, timeout_1xx_secs: int, timeout_2xx_secs: string>, onnet_t38_passthrough_enabled: bool, outbound: record<ani_override: string, ani_override_type: string, call_parking_enabled: bool, channel_limit: int, generate_ringback_tone: bool, instant_ringback_enabled: bool, localization: string, outbound_voice_profile_id: string, t38_reinvite_source: string>, password: string, record_type: string, rtcp_settings: record<capture_enabled: bool, port: any, report_frequency_secs: int>, sip_uri_calling_preference: string, updated_at: string, user_name: string, webhook_api_version: string, webhook_event_failover_url: string, webhook_event_url: string, webhook_timeout_secs: int>>"
    delete-credential-connection: "record<data: record<active: bool, anchorsite_override: string, connection_name: string, created_at: string, default_on_hold_comfort_noise_enabled: bool, dtmf_type: string, encode_contact_header_enabled: bool, encrypted_media: string, id: string, inbound: record<ani_number_format: string, channel_limit: int, codecs: list, dnis_number_format: string, generate_ringback_tone: bool, isup_headers_enabled: bool, prack_enabled: bool, privacy_zone_enabled: bool, sip_compact_headers_enabled: bool, timeout_1xx_secs: int, timeout_2xx_secs: string>, onnet_t38_passthrough_enabled: bool, outbound: record<ani_override: string, ani_override_type: string, call_parking_enabled: bool, channel_limit: int, generate_ringback_tone: bool, instant_ringback_enabled: bool, localization: string, outbound_voice_profile_id: string, t38_reinvite_source: string>, password: string, record_type: string, rtcp_settings: record<capture_enabled: bool, port: any, report_frequency_secs: int>, sip_uri_calling_preference: string, updated_at: string, user_name: string, webhook_api_version: string, webhook_event_failover_url: string, webhook_event_url: string, webhook_timeout_secs: int>>"
    retrieve-credential-connection: "record<data: record<active: bool, anchorsite_override: string, connection_name: string, created_at: string, default_on_hold_comfort_noise_enabled: bool, dtmf_type: string, encode_contact_header_enabled: bool, encrypted_media: string, id: string, inbound: record<ani_number_format: string, channel_limit: int, codecs: list, dnis_number_format: string, generate_ringback_tone: bool, isup_headers_enabled: bool, prack_enabled: bool, privacy_zone_enabled: bool, sip_compact_headers_enabled: bool, timeout_1xx_secs: int, timeout_2xx_secs: string>, onnet_t38_passthrough_enabled: bool, outbound: record<ani_override: string, ani_override_type: string, call_parking_enabled: bool, channel_limit: int, generate_ringback_tone: bool, instant_ringback_enabled: bool, localization: string, outbound_voice_profile_id: string, t38_reinvite_source: string>, password: string, record_type: string, rtcp_settings: record<capture_enabled: bool, port: any, report_frequency_secs: int>, sip_uri_calling_preference: string, updated_at: string, user_name: string, webhook_api_version: string, webhook_event_failover_url: string, webhook_event_url: string, webhook_timeout_secs: int>>"
    update-credential-connection: "record<data: record<active: bool, anchorsite_override: string, connection_name: string, created_at: string, default_on_hold_comfort_noise_enabled: bool, dtmf_type: string, encode_contact_header_enabled: bool, encrypted_media: string, id: string, inbound: record<ani_number_format: string, channel_limit: int, codecs: list, dnis_number_format: string, generate_ringback_tone: bool, isup_headers_enabled: bool, prack_enabled: bool, privacy_zone_enabled: bool, sip_compact_headers_enabled: bool, timeout_1xx_secs: int, timeout_2xx_secs: string>, onnet_t38_passthrough_enabled: bool, outbound: record<ani_override: string, ani_override_type: string, call_parking_enabled: bool, channel_limit: int, generate_ringback_tone: bool, instant_ringback_enabled: bool, localization: string, outbound_voice_profile_id: string, t38_reinvite_source: string>, password: string, record_type: string, rtcp_settings: record<capture_enabled: bool, port: any, report_frequency_secs: int>, sip_uri_calling_preference: string, updated_at: string, user_name: string, webhook_api_version: string, webhook_event_failover_url: string, webhook_event_url: string, webhook_timeout_secs: int>>"
    detail-records-search: "record<data: list<record>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    list-document-links: "record<data: table<created_at: string, id: string, record_type: string, updated_at: string, document_id: string, linked_record_type: string, linked_resource_id: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    list-documents: "record<data: table<created_at: string, id: string, record_type: string, updated_at: string, content_type: string, filename: string, sha256: string, size: record, status: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    create-document: "record<data: record<created_at: string, id: string, record_type: string, updated_at: string, content_type: string, filename: string, sha256: string, size: record<amount: int, unit: string>, status: string>>"
    delete-document: "record<data: record<created_at: string, id: string, record_type: string, updated_at: string, content_type: string, filename: string, sha256: string, size: record<amount: int, unit: string>, status: string>>"
    retrieve-document: "record<data: record<created_at: string, id: string, record_type: string, updated_at: string, content_type: string, filename: string, sha256: string, size: record<amount: int, unit: string>, status: string>>"
    update-document: "record<data: record<created_at: string, id: string, record_type: string, updated_at: string, content_type: string, filename: string, sha256: string, size: record<amount: int, unit: string>, status: string>>"
    download-doc-service-document: "binary"
    list-fax-applications: "record<data: table<active: bool, anchorsite_override: string, application_name: string, created_at: string, id: string, inbound: record, outbound: record, record_type: string, updated_at: string, webhook_event_failover_url: string, webhook_event_url: string, webhook_timeout_secs: int>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    create-fax-application: "record<data: record<active: bool, anchorsite_override: string, application_name: string, created_at: string, id: string, inbound: record<channel_limit: int, sip_subdomain: string, sip_subdomain_receive_settings: string>, outbound: record<channel_limit: int, outbound_voice_profile_id: string>, record_type: string, updated_at: string, webhook_event_failover_url: string, webhook_event_url: string, webhook_timeout_secs: int>>"
    delete-fax-application: "record<data: record<active: bool, anchorsite_override: string, application_name: string, created_at: string, id: string, inbound: record<channel_limit: int, sip_subdomain: string, sip_subdomain_receive_settings: string>, outbound: record<channel_limit: int, outbound_voice_profile_id: string>, record_type: string, updated_at: string, webhook_event_failover_url: string, webhook_event_url: string, webhook_timeout_secs: int>>"
    get-fax-application: "record<data: record<active: bool, anchorsite_override: string, application_name: string, created_at: string, id: string, inbound: record<channel_limit: int, sip_subdomain: string, sip_subdomain_receive_settings: string>, outbound: record<channel_limit: int, outbound_voice_profile_id: string>, record_type: string, updated_at: string, webhook_event_failover_url: string, webhook_event_url: string, webhook_timeout_secs: int>>"
    update-fax-application: "record<data: record<active: bool, anchorsite_override: string, application_name: string, created_at: string, id: string, inbound: record<channel_limit: int, sip_subdomain: string, sip_subdomain_receive_settings: string>, outbound: record<channel_limit: int, outbound_voice_profile_id: string>, record_type: string, updated_at: string, webhook_event_failover_url: string, webhook_event_url: string, webhook_timeout_secs: int>>"
    list-faxes: "record<data: table<connection_id: string, created_at: string, direction: string, from: string, id: string, media_name: string, media_url: string, quality: string, record_type: string, status: string, store_media: bool, stored_media_url: string, to: string, updated_at: string, webhook_failover_url: string, webhook_url: string>, meta: record>"
    send-fax: "record<data: record<connection_id: string, created_at: string, direction: string, from: string, id: string, media_name: string, media_url: string, quality: string, record_type: string, status: string, store_media: bool, stored_media_url: string, to: string, updated_at: string, webhook_failover_url: string, webhook_url: string>>"
    view-fax: "record<data: record<connection_id: string, created_at: string, direction: string, from: string, id: string, media_name: string, media_url: string, quality: string, record_type: string, status: string, store_media: bool, stored_media_url: string, to: string, updated_at: string, webhook_failover_url: string, webhook_url: string>>"
    refresh-fax: "record<result: string>"
    list-fqdn-connections: "record<data: table<active: bool, anchorsite_override: string, connection_name: string, created_at: string, default_on_hold_comfort_noise_enabled: bool, dtmf_type: string, encode_contact_header_enabled: bool, encrypted_media: string, id: string, inbound: record, onnet_t38_passthrough_enabled: bool, record_type: string, rtcp_settings: record, transport_protocol: string, updated_at: string, webhook_api_version: string, webhook_event_failover_url: string, webhook_event_url: string, webhook_timeout_secs: int>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    create-fqdn-connection: "record<data: record<active: bool, anchorsite_override: string, connection_name: string, created_at: string, default_on_hold_comfort_noise_enabled: bool, dtmf_type: string, encode_contact_header_enabled: bool, encrypted_media: string, id: string, inbound: record<ani_number_format: string, channel_limit: int, codecs: list, default_routing_method: string, dnis_number_format: string, generate_ringback_tone: bool, isup_headers_enabled: bool, prack_enabled: bool, privacy_zone_enabled: bool, sip_compact_headers_enabled: bool, sip_region: string, sip_subdomain: string, sip_subdomain_receive_settings: string, timeout_1xx_secs: int, timeout_2xx_secs: int>, onnet_t38_passthrough_enabled: bool, record_type: string, rtcp_settings: record<capture_enabled: bool, port: any, report_frequency_secs: int>, transport_protocol: string, updated_at: string, webhook_api_version: string, webhook_event_failover_url: string, webhook_event_url: string, webhook_timeout_secs: int>>"
    delete-fqdn-connection: "record<data: record<active: bool, anchorsite_override: string, connection_name: string, created_at: string, default_on_hold_comfort_noise_enabled: bool, dtmf_type: string, encode_contact_header_enabled: bool, encrypted_media: string, id: string, inbound: record<ani_number_format: string, channel_limit: int, codecs: list, default_routing_method: string, dnis_number_format: string, generate_ringback_tone: bool, isup_headers_enabled: bool, prack_enabled: bool, privacy_zone_enabled: bool, sip_compact_headers_enabled: bool, sip_region: string, sip_subdomain: string, sip_subdomain_receive_settings: string, timeout_1xx_secs: int, timeout_2xx_secs: int>, onnet_t38_passthrough_enabled: bool, record_type: string, rtcp_settings: record<capture_enabled: bool, port: any, report_frequency_secs: int>, transport_protocol: string, updated_at: string, webhook_api_version: string, webhook_event_failover_url: string, webhook_event_url: string, webhook_timeout_secs: int>>"
    retrieve-fqdn-connection: "record<data: record<active: bool, anchorsite_override: string, connection_name: string, created_at: string, default_on_hold_comfort_noise_enabled: bool, dtmf_type: string, encode_contact_header_enabled: bool, encrypted_media: string, id: string, inbound: record<ani_number_format: string, channel_limit: int, codecs: list, default_routing_method: string, dnis_number_format: string, generate_ringback_tone: bool, isup_headers_enabled: bool, prack_enabled: bool, privacy_zone_enabled: bool, sip_compact_headers_enabled: bool, sip_region: string, sip_subdomain: string, sip_subdomain_receive_settings: string, timeout_1xx_secs: int, timeout_2xx_secs: int>, onnet_t38_passthrough_enabled: bool, record_type: string, rtcp_settings: record<capture_enabled: bool, port: any, report_frequency_secs: int>, transport_protocol: string, updated_at: string, webhook_api_version: string, webhook_event_failover_url: string, webhook_event_url: string, webhook_timeout_secs: int>>"
    update-fqdn-connection: "record<data: record<active: bool, anchorsite_override: string, connection_name: string, created_at: string, default_on_hold_comfort_noise_enabled: bool, dtmf_type: string, encode_contact_header_enabled: bool, encrypted_media: string, id: string, inbound: record<ani_number_format: string, channel_limit: int, codecs: list, default_routing_method: string, dnis_number_format: string, generate_ringback_tone: bool, isup_headers_enabled: bool, prack_enabled: bool, privacy_zone_enabled: bool, sip_compact_headers_enabled: bool, sip_region: string, sip_subdomain: string, sip_subdomain_receive_settings: string, timeout_1xx_secs: int, timeout_2xx_secs: int>, onnet_t38_passthrough_enabled: bool, record_type: string, rtcp_settings: record<capture_enabled: bool, port: any, report_frequency_secs: int>, transport_protocol: string, updated_at: string, webhook_api_version: string, webhook_event_failover_url: string, webhook_event_url: string, webhook_timeout_secs: int>>"
    list-fqdns: "record<data: table<connection_id: string, created_at: string, dns_record_type: string, fqdn: string, id: string, port: int, record_type: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    create-fqdn: "record<data: record<connection_id: string, created_at: string, dns_record_type: string, fqdn: string, id: string, port: int, record_type: string, updated_at: string>>"
    delete-fqdn: "record<data: record<connection_id: string, created_at: string, dns_record_type: string, fqdn: string, id: string, port: int, record_type: string, updated_at: string>>"
    retrieve-fqdn: "record<data: record<connection_id: string, created_at: string, dns_record_type: string, fqdn: string, id: string, port: int, record_type: string, updated_at: string>>"
    update-fqdn: "record<data: record<connection_id: string, created_at: string, dns_record_type: string, fqdn: string, id: string, port: int, record_type: string, updated_at: string>>"
    create-inventory-coverage-request: "record<data: table<count: int, coverage_type: string, group: string, group_type: string, number_range: int, number_type: string, phone_number_type: string, record_type: string>, meta: record<total_results: int>>"
    list-ip-connections: "record<data: table<active: bool, anchorsite_override: string, connection_name: string, created_at: string, default_on_hold_comfort_noise_enabled: bool, dtmf_type: string, encode_contact_header_enabled: bool, encrypted_media: string, id: string, inbound: record, onnet_t38_passthrough_enabled: bool, outbound: record, record_type: string, rtcp_settings: record, transport_protocol: string, updated_at: string, webhook_api_version: string, webhook_event_failover_url: string, webhook_event_url: string, webhook_timeout_secs: int>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    create-ip-connection: "record<data: record<active: bool, anchorsite_override: string, connection_name: string, created_at: string, default_on_hold_comfort_noise_enabled: bool, dtmf_type: string, encode_contact_header_enabled: bool, encrypted_media: string, id: string, inbound: record<ani_number_format: string, channel_limit: int, codecs: list, default_primary_ip_id: string, default_routing_method: string, default_secondary_ip_id: string, default_tertiary_ip_id: string, dnis_number_format: string, generate_ringback_tone: bool, isup_headers_enabled: bool, prack_enabled: bool, privacy_zone_enabled: bool, sip_compact_headers_enabled: bool, sip_region: string, sip_subdomain: string, sip_subdomain_receive_settings: string, timeout_1xx_secs: int, timeout_2xx_secs: int>, onnet_t38_passthrough_enabled: bool, outbound: record<ani_override: string, ani_override_type: string, call_parking_enabled: bool, channel_limit: int, generate_ringback_tone: bool, instant_ringback_enabled: bool, ip_authentication_method: string, ip_authentication_token: string, localization: string, outbound_voice_profile_id: string, t38_reinvite_source: string, tech_prefix: string>, record_type: string, rtcp_settings: record<capture_enabled: bool, port: any, report_frequency_secs: int>, transport_protocol: string, updated_at: string, webhook_api_version: string, webhook_event_failover_url: string, webhook_event_url: string, webhook_timeout_secs: int>>"
    delete-ip-connection: "record<data: record<active: bool, anchorsite_override: string, connection_name: string, created_at: string, default_on_hold_comfort_noise_enabled: bool, dtmf_type: string, encode_contact_header_enabled: bool, encrypted_media: string, id: string, inbound: record<ani_number_format: string, channel_limit: int, codecs: list, default_primary_ip_id: string, default_routing_method: string, default_secondary_ip_id: string, default_tertiary_ip_id: string, dnis_number_format: string, generate_ringback_tone: bool, isup_headers_enabled: bool, prack_enabled: bool, privacy_zone_enabled: bool, sip_compact_headers_enabled: bool, sip_region: string, sip_subdomain: string, sip_subdomain_receive_settings: string, timeout_1xx_secs: int, timeout_2xx_secs: int>, onnet_t38_passthrough_enabled: bool, outbound: record<ani_override: string, ani_override_type: string, call_parking_enabled: bool, channel_limit: int, generate_ringback_tone: bool, instant_ringback_enabled: bool, ip_authentication_method: string, ip_authentication_token: string, localization: string, outbound_voice_profile_id: string, t38_reinvite_source: string, tech_prefix: string>, record_type: string, rtcp_settings: record<capture_enabled: bool, port: any, report_frequency_secs: int>, transport_protocol: string, updated_at: string, webhook_api_version: string, webhook_event_failover_url: string, webhook_event_url: string, webhook_timeout_secs: int>>"
    retrieve-ip-connection: "record<data: record<active: bool, anchorsite_override: string, connection_name: string, created_at: string, default_on_hold_comfort_noise_enabled: bool, dtmf_type: string, encode_contact_header_enabled: bool, encrypted_media: string, id: string, inbound: record<ani_number_format: string, channel_limit: int, codecs: list, default_primary_ip_id: string, default_routing_method: string, default_secondary_ip_id: string, default_tertiary_ip_id: string, dnis_number_format: string, generate_ringback_tone: bool, isup_headers_enabled: bool, prack_enabled: bool, privacy_zone_enabled: bool, sip_compact_headers_enabled: bool, sip_region: string, sip_subdomain: string, sip_subdomain_receive_settings: string, timeout_1xx_secs: int, timeout_2xx_secs: int>, onnet_t38_passthrough_enabled: bool, outbound: record<ani_override: string, ani_override_type: string, call_parking_enabled: bool, channel_limit: int, generate_ringback_tone: bool, instant_ringback_enabled: bool, ip_authentication_method: string, ip_authentication_token: string, localization: string, outbound_voice_profile_id: string, t38_reinvite_source: string, tech_prefix: string>, record_type: string, rtcp_settings: record<capture_enabled: bool, port: any, report_frequency_secs: int>, transport_protocol: string, updated_at: string, webhook_api_version: string, webhook_event_failover_url: string, webhook_event_url: string, webhook_timeout_secs: int>>"
    update-ip-connection: "record<data: record<active: bool, anchorsite_override: string, connection_name: string, created_at: string, default_on_hold_comfort_noise_enabled: bool, dtmf_type: string, encode_contact_header_enabled: bool, encrypted_media: string, id: string, inbound: record<ani_number_format: string, channel_limit: int, codecs: list, default_primary_ip_id: string, default_routing_method: string, default_secondary_ip_id: string, default_tertiary_ip_id: string, dnis_number_format: string, generate_ringback_tone: bool, isup_headers_enabled: bool, prack_enabled: bool, privacy_zone_enabled: bool, sip_compact_headers_enabled: bool, sip_region: string, sip_subdomain: string, sip_subdomain_receive_settings: string, timeout_1xx_secs: int, timeout_2xx_secs: int>, onnet_t38_passthrough_enabled: bool, outbound: record<ani_override: string, ani_override_type: string, call_parking_enabled: bool, channel_limit: int, generate_ringback_tone: bool, instant_ringback_enabled: bool, ip_authentication_method: string, ip_authentication_token: string, localization: string, outbound_voice_profile_id: string, t38_reinvite_source: string, tech_prefix: string>, record_type: string, rtcp_settings: record<capture_enabled: bool, port: any, report_frequency_secs: int>, transport_protocol: string, updated_at: string, webhook_api_version: string, webhook_event_failover_url: string, webhook_event_url: string, webhook_timeout_secs: int>>"
    list-ips: "record<data: table<connection_id: string, created_at: string, id: string, ip_address: string, port: int, record_type: string, updated_at: string>>"
    create-ip: "record<data: record<connection_id: string, created_at: string, id: string, ip_address: string, port: int, record_type: string, updated_at: string>>"
    delete-ip: "record<data: record<connection_id: string, created_at: string, id: string, ip_address: string, port: int, record_type: string, updated_at: string>>"
    retrieve-ip: "record<data: record<connection_id: string, created_at: string, id: string, ip_address: string, port: int, record_type: string, updated_at: string>>"
    update-ip: "record<data: record<connection_id: string, created_at: string, id: string, ip_address: string, port: int, record_type: string, updated_at: string>>"
    create-ledger-billing-group-report: "record<data: record<created_at: string, id: string, organization_id: string, record_type: string, report_url: string, status: string, updated_at: string>>"
    retrieve-ledger-billing-group-report: "record<data: record<created_at: string, id: string, organization_id: string, record_type: string, report_url: string, status: string, updated_at: string>>"
    list-managed-accounts: "record<data: table<api_key: string, api_token: string, api_user: string, balance: record, created_at: string, email: string, id: string, manager_account_id: string, organization_name: string, record_type: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    create-managed-account: "record<data: record<api_key: string, api_token: string, api_user: string, balance: record<available_credit: string, balance: string, credit_limit: string, currency: string, record_type: string>, created_at: string, email: string, id: string, manager_account_id: string, organization_name: string, record_type: string, updated_at: string>>"
    retrieve-managed-account: "record<data: record<api_key: string, api_token: string, api_user: string, balance: record<available_credit: string, balance: string, credit_limit: string, currency: string, record_type: string>, created_at: string, email: string, id: string, manager_account_id: string, organization_name: string, record_type: string, updated_at: string>>"
    disable-managed-account: "record<data: record<api_key: string, api_token: string, api_user: string, balance: record<available_credit: string, balance: string, credit_limit: string, currency: string, record_type: string>, created_at: string, email: string, id: string, manager_account_id: string, organization_name: string, record_type: string, updated_at: string>>"
    enable-managed-account: "record<data: record<api_key: string, api_token: string, api_user: string, balance: record<available_credit: string, balance: string, credit_limit: string, currency: string, record_type: string>, created_at: string, email: string, id: string, manager_account_id: string, organization_name: string, record_type: string, updated_at: string>>"
    list-media: "record<data: table<created_at: string, expires_at: string, media_name: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    create-media: "record<data: record<created_at: string, expires_at: string, media_name: string, updated_at: string>>"
    get-media: "record<data: record<created_at: string, expires_at: string, media_name: string, updated_at: string>>"
    update-media: "record<data: record<created_at: string, expires_at: string, media_name: string, updated_at: string>>"
    download-media: "binary"
    get-paginated-mdrs: "record<data: table<cld: string, cli: string, cost: string, created_at: string, currency: string, direction: string, id: string, message_type: string, parts: float, profile_name: string, rate: string, record_type: string, status: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    get-mdr-message-body: "record<data: record<message_body: string, record_type: string>>"
    create-message: "record<data: record<completed_at: string, cost: record<amount: string, currency: string>, direction: string, encoding: string, errors: list<record>, from: record<carrier: string, line_type: string, phone_number: string>, id: string, media: list<record>, messaging_profile_id: string, organization_id: string, parts: int, received_at: string, record_type: string, sent_at: string, subject: string, tags: list<string>, text: string, to: list<record>, type: string, valid_until: string, webhook_failover_url: string, webhook_url: string>>"
    create-long-code-message: "record<data: record<completed_at: string, cost: record<amount: string, currency: string>, direction: string, encoding: string, errors: list<record>, from: record<carrier: string, line_type: string, phone_number: string>, id: string, media: list<record>, messaging_profile_id: string, organization_id: string, parts: int, received_at: string, record_type: string, sent_at: string, subject: string, tags: list<string>, text: string, to: list<record>, type: string, valid_until: string, webhook_failover_url: string, webhook_url: string>>"
    create-number-pool-message: "record<data: record<completed_at: string, cost: record<amount: string, currency: string>, direction: string, encoding: string, errors: list<record>, from: record<carrier: string, line_type: string, phone_number: string>, id: string, media: list<record>, messaging_profile_id: string, organization_id: string, parts: int, received_at: string, record_type: string, sent_at: string, subject: string, tags: list<string>, text: string, to: list<record>, type: string, valid_until: string, webhook_failover_url: string, webhook_url: string>>"
    create-short-code-message: "record<data: record<completed_at: string, cost: record<amount: string, currency: string>, direction: string, encoding: string, errors: list<record>, from: record<carrier: string, line_type: string, phone_number: string>, id: string, media: list<record>, messaging_profile_id: string, organization_id: string, parts: int, received_at: string, record_type: string, sent_at: string, subject: string, tags: list<string>, text: string, to: list<record>, type: string, valid_until: string, webhook_failover_url: string, webhook_url: string>>"
    retrieve-message: "record<data: record<completed_at: string, cost: record<amount: string, currency: string>, direction: string, encoding: string, errors: list<record>, from: record<carrier: string, line_type: string, phone_number: string>, id: string, media: list<record>, messaging_profile_id: string, organization_id: string, parts: int, received_at: string, record_type: string, sent_at: string, subject: string, tags: list<string>, text: string, to: list<record>, type: string, valid_until: string, webhook_failover_url: string, webhook_url: string>>"
    list-messaging-hosted-number-order: "record<data: table<id: string, messaging_profile_id: string, phone_numbers: list, record_type: string, status: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    create-messaging-hosted-number-order: "record<data: record<id: string, messaging_profile_id: string, phone_numbers: list<record>, record_type: string, status: string>>"
    retrieve-messaging-hosted-number-order: "record<data: record<id: string, messaging_profile_id: string, phone_numbers: list<record>, record_type: string, status: string>>"
    upload-file-messaging-hosted-number-order: "record<data: record<id: string, messaging_profile_id: string, phone_numbers: list<record>, record_type: string, status: string>>"
    delete-messaging-hosted-number: "record<data: record<id: string, phone_number: string, record_type: string, status: string>>"
    list-messaging-profile-metrics: "record<data: table<inbound: record, messaging_profile_id: string, outbound: record, phone_numbers: float, record_type: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    list-messaging-profiles: "record<data: table<created_at: string, enabled: bool, id: string, name: string, number_pool_settings: record, record_type: string, updated_at: string, url_shortener_settings: record, v1_secret: string, webhook_api_version: string, webhook_failover_url: string, webhook_url: string, whitelisted_destinations: list>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    create-messaging-profile: "record<data: record<created_at: string, enabled: bool, id: string, name: string, number_pool_settings: record<geomatch: bool, long_code_weight: float, skip_unhealthy: bool, sticky_sender: bool, toll_free_weight: float>, record_type: string, updated_at: string, url_shortener_settings: record<domain: string, prefix: string, replace_blacklist_only: bool, send_webhooks: bool>, v1_secret: string, webhook_api_version: string, webhook_failover_url: string, webhook_url: string, whitelisted_destinations: list<string>>>"
    delete-messaging-profile: "record<data: record<created_at: string, enabled: bool, id: string, name: string, number_pool_settings: record<geomatch: bool, long_code_weight: float, skip_unhealthy: bool, sticky_sender: bool, toll_free_weight: float>, record_type: string, updated_at: string, url_shortener_settings: record<domain: string, prefix: string, replace_blacklist_only: bool, send_webhooks: bool>, v1_secret: string, webhook_api_version: string, webhook_failover_url: string, webhook_url: string, whitelisted_destinations: list<string>>>"
    retrieve-messaging-profile: "record<data: record<created_at: string, enabled: bool, id: string, name: string, number_pool_settings: record<geomatch: bool, long_code_weight: float, skip_unhealthy: bool, sticky_sender: bool, toll_free_weight: float>, record_type: string, updated_at: string, url_shortener_settings: record<domain: string, prefix: string, replace_blacklist_only: bool, send_webhooks: bool>, v1_secret: string, webhook_api_version: string, webhook_failover_url: string, webhook_url: string, whitelisted_destinations: list<string>>>"
    update-messaging-profile: "record<data: record<created_at: string, enabled: bool, id: string, name: string, number_pool_settings: record<geomatch: bool, long_code_weight: float, skip_unhealthy: bool, sticky_sender: bool, toll_free_weight: float>, record_type: string, updated_at: string, url_shortener_settings: record<domain: string, prefix: string, replace_blacklist_only: bool, send_webhooks: bool>, v1_secret: string, webhook_api_version: string, webhook_failover_url: string, webhook_url: string, whitelisted_destinations: list<string>>>"
    retrieve-messaging-profile-detailed-metrics: "record<data: record<detailed: list<record>, overview: record<inbound: record, messaging_profile_id: string, outbound: record, phone_numbers: float, record_type: string>>>"
    list-messaging-profile-phone-numbers: "record<data: table<country_code: string, created_at: string, eligible_messaging_products: list, features: record, health: record, id: string, messaging_product: string, messaging_profile_id: string, phone_number: string, record_type: string, traffic_type: string, type: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    list-messaging-profile-short-codes: "record<data: table<country_code: string, created_at: string, id: string, messaging_profile_id: string, record_type: string, short_code: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    list-messaging-url-domains: "record<data: table<id: string, record_type: string, url_domain: string, use_case: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    mobile-operator-networks-get: "record<data: table<country_code: string, id: string, mcc: string, mnc: string, name: string, record_type: string, tadig: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    list-notification-channels: "record<data: table<channel_destination: string, channel_type_id: string, created_at: string, id: string, notification_profile_id: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    create-notification-channels: "record<data: record<channel_destination: string, channel_type_id: string, created_at: string, id: string, notification_profile_id: string, updated_at: string>>"
    delete-notification-channel: "record<data: record<channel_destination: string, channel_type_id: string, created_at: string, id: string, notification_profile_id: string, updated_at: string>>"
    retrieve-notification-channel: "record<data: record<channel_destination: string, channel_type_id: string, created_at: string, id: string, notification_profile_id: string, updated_at: string>>"
    update-notification-channel: "record<data: record<channel_destination: string, channel_type_id: string, created_at: string, id: string, notification_profile_id: string, updated_at: string>>"
    find-notifications-events-conditions: "record<data: table<allow_multiple_channels: bool, associated_record_type: string, asynchronous: bool, created_at: string, description: string, enabled: bool, id: string, name: string, notification_event_id: string, parameters: list, supported_channels: list, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    find-notifications-events: "record<data: table<created_at: string, enabled: bool, id: string, name: string, notification_category: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    find-notifications-profiles: "record<data: table<created_at: string, id: string, name: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    create-notification-profile: "record<data: record<created_at: string, id: string, name: string, updated_at: string>>"
    delete-notification-profile: "record<data: record<created_at: string, id: string, name: string, updated_at: string>>"
    retrieve-notification-profile: "record<data: record<created_at: string, id: string, name: string, updated_at: string>>"
    update-notification-profile: "record<data: record<created_at: string, id: string, name: string, updated_at: string>>"
    list-notification-settings: "record<data: table<associated_record_type: string, associated_record_type_value: string, created_at: string, id: string, notification_channel_id: string, notification_event_condition_id: string, notification_profile_id: string, parameters: list, status: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    create-notification-setting: "record<data: record<associated_record_type: string, associated_record_type_value: string, created_at: string, id: string, notification_channel_id: string, notification_event_condition_id: string, notification_profile_id: string, parameters: list<record>, status: string, updated_at: string>>"
    delete-notification-setting: "record<data: record<associated_record_type: string, associated_record_type_value: string, created_at: string, id: string, notification_channel_id: string, notification_event_condition_id: string, notification_profile_id: string, parameters: list<record>, status: string, updated_at: string>>"
    retrieve-notification-setting: "record<data: record<associated_record_type: string, associated_record_type_value: string, created_at: string, id: string, notification_channel_id: string, notification_event_condition_id: string, notification_profile_id: string, parameters: list<record>, status: string, updated_at: string>>"
    list-number-block-orders: "record<data: table<connection_id: string, created_at: string, customer_reference: string, id: string, messaging_profile_id: string, phone_numbers_count: int, range: int, record_type: string, requirements_met: bool, starting_number: string, status: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    create-number-block-order: "record<data: record<connection_id: string, created_at: string, customer_reference: string, id: string, messaging_profile_id: string, phone_numbers_count: int, range: int, record_type: string, requirements_met: bool, starting_number: string, status: string, updated_at: string>>"
    retrieve-number-block-order: "record<data: record<connection_id: string, created_at: string, customer_reference: string, id: string, messaging_profile_id: string, phone_numbers_count: int, range: int, record_type: string, requirements_met: bool, starting_number: string, status: string, updated_at: string>>"
    number-lookup: "record<data: record<caller_name: record<caller_name: string, error_code: string>, carrier: record<error_code: string, mobile_country_code: string, mobile_network_code: string, name: string, type: string>, country_code: string, fraud: string, national_format: string, phone_number: string, portability: record<altspid: string, altspid_carrier_name: string, altspid_carrier_type: string, city: string, line_type: string, lrn: string, ocn: string, ported_date: string, ported_status: string, spid: string, spid_carrier_name: string, spid_carrier_type: string, state: string>, record_type: string>>"
    list-number-order-documents: "record<data: table<created_at: string, customer_reference: string, file_id: string, id: string, record_type: string, requirement_type: string, requirements_id: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    create-number-order-document: "record<data: record<created_at: string, customer_reference: string, file_id: string, id: string, record_type: string, requirement_type: string, requirements_id: string>>"
    retrieve-number-order-document: "record<data: record<created_at: string, customer_reference: string, file_id: string, id: string, record_type: string, requirement_type: string, requirements_id: string>>"
    update-number-order-document: "record<data: record<created_at: string, customer_reference: string, file_id: string, id: string, record_type: string, requirement_type: string, requirements_id: string>>"
    retrieve-number-order-phone-numbers: "record<data: table<country_code: string, id: string, order_request_id: string, phone_number: string, phone_number_type: string, record_type: string, regulatory_requirements: list, requirements_met: bool, status: string, sub_number_order_id: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    retrieve-number-order-phone-number: "record<data: record<country_code: string, id: string, order_request_id: string, phone_number: string, phone_number_type: string, record_type: string, regulatory_requirements: list<record>, requirements_met: bool, status: string, sub_number_order_id: string>>"
    update-number-order-phone-number: "record<data: record<country_code: string, id: string, order_request_id: string, phone_number: string, phone_number_type: string, record_type: string, regulatory_requirements: list<record>, requirements_met: bool, status: string, sub_number_order_id: string>>"
    list-number-orders: "record<data: table<billing_group_id: string, connection_id: string, created_at: string, customer_reference: string, id: string, messaging_profile_id: string, phone_numbers_count: int, record_type: string, requirements_met: bool, status: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    create-number-order: "record<data: record<billing_group_id: string, connection_id: string, created_at: string, customer_reference: string, id: string, messaging_profile_id: string, phone_numbers_count: int, record_type: string, requirements_met: bool, status: string, updated_at: string, phone_numbers: list<record>>>"
    retrieve-number-order: "record<data: record<billing_group_id: string, connection_id: string, created_at: string, customer_reference: string, id: string, messaging_profile_id: string, phone_numbers_count: int, record_type: string, requirements_met: bool, status: string, updated_at: string, phone_numbers: list<record>>>"
    update-number-order: "record<data: record<billing_group_id: string, connection_id: string, created_at: string, customer_reference: string, id: string, messaging_profile_id: string, phone_numbers_count: int, record_type: string, requirements_met: bool, status: string, updated_at: string, phone_numbers: list<record>>>"
    list-number-reservations: "record<data: table<created_at: string, customer_reference: string, id: string, phone_numbers: list, record_type: string, status: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    create-number-reservation: "record<data: record<created_at: string, customer_reference: string, id: string, phone_numbers: list<record>, record_type: string, status: string, updated_at: string>>"
    retrieve-number-reservation: "record<data: record<created_at: string, customer_reference: string, id: string, phone_numbers: list<record>, record_type: string, status: string, updated_at: string>>"
    extend-number-reservation-expiry-time: "record<data: record<created_at: string, customer_reference: string, id: string, phone_numbers: list<record>, record_type: string, status: string, updated_at: string>>"
    ota-updates-list: "record<data: table<created_at: string, id: string, record_type: string, sim_card_id: string, status: string, type: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    ota-update-get: "record<data: record<created_at: string, id: string, record_type: string, settings: record<mobile_operator_networks_preferences: list>, sim_card_id: string, status: string, type: string, updated_at: string>>"
    list-outbound-voice-profiles: "record<data: table<billing_group_id: string, call_recording: record, concurrent_call_limit: int, connections_count: int, created_at: string, daily_spend_limit: string, daily_spend_limit_enabled: bool, enabled: bool, id: string, max_destination_rate: float, name: string, record_type: string, service_plan: string, tags: list, traffic_type: string, updated_at: string, usage_payment_method: string, whitelisted_destinations: list>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    create-outbound-voice-profile: "record<data: record<billing_group_id: string, call_recording: record<call_recording_caller_phone_numbers: list, call_recording_channels: string, call_recording_format: string, call_recording_type: string>, concurrent_call_limit: int, connections_count: int, created_at: string, daily_spend_limit: string, daily_spend_limit_enabled: bool, enabled: bool, id: string, max_destination_rate: float, name: string, record_type: string, service_plan: string, tags: list<string>, traffic_type: string, updated_at: string, usage_payment_method: string, whitelisted_destinations: list<string>>>"
    delete-outbound-voice-profile: "record<data: record<billing_group_id: string, call_recording: record<call_recording_caller_phone_numbers: list, call_recording_channels: string, call_recording_format: string, call_recording_type: string>, concurrent_call_limit: int, connections_count: int, created_at: string, daily_spend_limit: string, daily_spend_limit_enabled: bool, enabled: bool, id: string, max_destination_rate: float, name: string, record_type: string, service_plan: string, tags: list<string>, traffic_type: string, updated_at: string, usage_payment_method: string, whitelisted_destinations: list<string>>>"
    retrieve-outbound-voice-profile: "record<data: record<billing_group_id: string, call_recording: record<call_recording_caller_phone_numbers: list, call_recording_channels: string, call_recording_format: string, call_recording_type: string>, concurrent_call_limit: int, connections_count: int, created_at: string, daily_spend_limit: string, daily_spend_limit_enabled: bool, enabled: bool, id: string, max_destination_rate: float, name: string, record_type: string, service_plan: string, tags: list<string>, traffic_type: string, updated_at: string, usage_payment_method: string, whitelisted_destinations: list<string>>>"
    update-outbound-voice-profile: "record<data: record<billing_group_id: string, call_recording: record<call_recording_caller_phone_numbers: list, call_recording_channels: string, call_recording_format: string, call_recording_type: string>, concurrent_call_limit: int, connections_count: int, created_at: string, daily_spend_limit: string, daily_spend_limit_enabled: bool, enabled: bool, id: string, max_destination_rate: float, name: string, record_type: string, service_plan: string, tags: list<string>, traffic_type: string, updated_at: string, usage_payment_method: string, whitelisted_destinations: list<string>>>"
    list-phone-number-blocks-jobs: "record<data: table<created_at: string, etc: string, failed_operations: list, id: string, record_type: string, status: string, successful_operations: list, type: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    create-phone-number-blocks-job-delete-phone-number-block: "record<data: record<created_at: string, etc: string, failed_operations: list<record>, id: string, record_type: string, status: string, successful_operations: list<record>, type: string, updated_at: string>>"
    retrieve-phone-number-blocks-job: "record<data: record<created_at: string, etc: string, failed_operations: list<record>, id: string, record_type: string, status: string, successful_operations: list<record>, type: string, updated_at: string>>"
    list-phone-numbers: "record<data: table<billing_group_id: string, call_forwarding_enabled: bool, call_recording_enabled: bool, caller_id_name_enabled: bool, cnam_listing_enabled: bool, connection_id: string, connection_name: string, created_at: string, customer_reference: string, emergency_address_id: string, emergency_enabled: bool, external_pin: string, id: string, messaging_profile_id: string, messaging_profile_name: string, number_level_routing: string, phone_number: string, phone_number_type: string, purchased_at: string, record_type: string, status: string, t38_fax_gateway_enabled: bool, tags: list>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    list-csv-downloads: "record<data: table<id: string, record_type: string, status: string, url: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    create-csv-download: "record<data: table<id: string, record_type: string, status: string, url: string>>"
    retrieve-csv-download: "record<data: table<id: string, record_type: string, status: string, url: string>>"
    list-outbound-channels: "record<data: record<channels: int, record_type: string>>"
    update-outbound-channels: "record<data: record<channels: int, record_type: string>>"
    list-phone-numbers-jobs: "record<data: table<created_at: string, etc: string, failed_operations: list, id: string, pending_operations: list, record_type: string, status: string, successful_operations: list, type: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    create-phone-numbers-job-delete-phone-numbers: "record<data: record<created_at: string, etc: string, failed_operations: list<record>, id: string, pending_operations: list<record>, record_type: string, status: string, successful_operations: list<record>, type: string, updated_at: string>>"
    create-phone-numbers-job-update-emergency-settings: "record<data: record<created_at: string, etc: string, failed_operations: list<record>, id: string, pending_operations: list<record>, record_type: string, status: string, successful_operations: list<record>, type: string, updated_at: string>>"
    create-phone-numbers-job-update-phone-number: "record<data: record<created_at: string, etc: string, failed_operations: list<record>, id: string, pending_operations: list<record>, record_type: string, status: string, successful_operations: list<record>, type: string, updated_at: string>>"
    retrieve-phone-numbers-job: "record<data: record<created_at: string, etc: string, failed_operations: list<record>, id: string, pending_operations: list<record>, record_type: string, status: string, successful_operations: list<record>, type: string, updated_at: string>>"
    list-phone-numbers-with-messaging-settings: "record<data: table<country_code: string, created_at: string, eligible_messaging_products: list, features: record, health: record, id: string, messaging_product: string, messaging_profile_id: string, phone_number: string, record_type: string, traffic_type: string, type: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    list-phone-numbers-with-voice-settings: "record<data: table<call_forwarding: record, call_recording: record, cnam_listing: record, connection_id: string, customer_reference: string, emergency: record, id: string, media_features: record, phone_number: string, record_type: string, tech_prefix_enabled: bool, translated_number: string, usage_payment_method: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    delete-phone-number: "record<data: record<billing_group_id: string, call_forwarding_enabled: bool, call_recording_enabled: bool, caller_id_name_enabled: bool, cnam_listing_enabled: bool, connection_id: string, connection_name: string, created_at: string, customer_reference: string, emergency_address_id: string, emergency_enabled: bool, external_pin: string, id: string, messaging_profile_id: string, messaging_profile_name: string, number_level_routing: string, phone_number: string, phone_number_type: string, purchased_at: string, record_type: string, status: string, t38_fax_gateway_enabled: bool, tags: list<string>, updated_at: string>>"
    retrieve-phone-number: "record<data: record<billing_group_id: string, call_forwarding_enabled: bool, call_recording_enabled: bool, caller_id_name_enabled: bool, cnam_listing_enabled: bool, connection_id: string, connection_name: string, created_at: string, customer_reference: string, emergency_address_id: string, emergency_enabled: bool, external_pin: string, id: string, messaging_profile_id: string, messaging_profile_name: string, number_level_routing: string, phone_number: string, phone_number_type: string, purchased_at: string, record_type: string, status: string, t38_fax_gateway_enabled: bool, tags: list<string>>>"
    update-phone-number: "record<data: record<billing_group_id: string, call_forwarding_enabled: bool, call_recording_enabled: bool, caller_id_name_enabled: bool, cnam_listing_enabled: bool, connection_id: string, connection_name: string, created_at: string, customer_reference: string, emergency_address_id: string, emergency_enabled: bool, external_pin: string, id: string, messaging_profile_id: string, messaging_profile_name: string, number_level_routing: string, phone_number: string, phone_number_type: string, purchased_at: string, record_type: string, status: string, t38_fax_gateway_enabled: bool, tags: list<string>>>"
    enable-emergency-phone-number: "record<data: record<call_forwarding: record<call_forwarding_enabled: bool, forwarding_type: string, forwards_to: string>, call_recording: record<inbound_call_recording_channels: string, inbound_call_recording_enabled: bool, inbound_call_recording_format: string>, cnam_listing: record<cnam_listing_details: string, cnam_listing_enabled: bool>, connection_id: string, customer_reference: string, emergency: record<emergency_address_id: string, emergency_enabled: bool, emergency_status: string>, id: string, media_features: record<accept_any_rtp_packets_enabled: bool, media_handling_mode: string, rtp_auto_adjust_enabled: bool, t38_fax_gateway_enabled: bool>, phone_number: string, record_type: string, tech_prefix_enabled: bool, translated_number: string, usage_payment_method: string>>"
    retrieve-phone-number-with-messaging-settings: "record<data: record<country_code: string, created_at: string, eligible_messaging_products: list<string>, features: record<mms: record, sms: record>, health: record<inbound_outbound_ratio: float, message_count: int, spam_ratio: float, success_ratio: float>, id: string, messaging_product: string, messaging_profile_id: string, phone_number: string, record_type: string, traffic_type: string, type: string, updated_at: string>>"
    update-phone-number-with-messaging-settings: "record<data: record<country_code: string, created_at: string, eligible_messaging_products: list<string>, features: record<mms: record, sms: record>, health: record<inbound_outbound_ratio: float, message_count: int, spam_ratio: float, success_ratio: float>, id: string, messaging_product: string, messaging_profile_id: string, phone_number: string, record_type: string, traffic_type: string, type: string, updated_at: string>>"
    retrieve-phone-number-with-voice-settings: "record<data: record<call_forwarding: record<call_forwarding_enabled: bool, forwarding_type: string, forwards_to: string>, call_recording: record<inbound_call_recording_channels: string, inbound_call_recording_enabled: bool, inbound_call_recording_format: string>, cnam_listing: record<cnam_listing_details: string, cnam_listing_enabled: bool>, connection_id: string, customer_reference: string, emergency: record<emergency_address_id: string, emergency_enabled: bool, emergency_status: string>, id: string, media_features: record<accept_any_rtp_packets_enabled: bool, media_handling_mode: string, rtp_auto_adjust_enabled: bool, t38_fax_gateway_enabled: bool>, phone_number: string, record_type: string, tech_prefix_enabled: bool, translated_number: string, usage_payment_method: string>>"
    update-phone-number-with-voice-settings: "record<data: record<call_forwarding: record<call_forwarding_enabled: bool, forwarding_type: string, forwards_to: string>, call_recording: record<inbound_call_recording_channels: string, inbound_call_recording_enabled: bool, inbound_call_recording_format: string>, cnam_listing: record<cnam_listing_details: string, cnam_listing_enabled: bool>, connection_id: string, customer_reference: string, emergency: record<emergency_address_id: string, emergency_enabled: bool, emergency_status: string>, id: string, media_features: record<accept_any_rtp_packets_enabled: bool, media_handling_mode: string, rtp_auto_adjust_enabled: bool, t38_fax_gateway_enabled: bool>, phone_number: string, record_type: string, tech_prefix_enabled: bool, translated_number: string, usage_payment_method: string>>"
    post-portability-check: "record<data: table<fast_portable: bool, not_portable_reason: string, phone_number: string, portable: bool, record_type: string>>"
    list-porting-orders: "record<data: table<activation_settings: record, created_at: string, end_user: record, id: string, misc: record, old_service_provider_ocn: string, phone_number_configuration: record, porting_phone_numbers_count: int, record_type: string, requirements: list, status: record, support_key: string, updated_at: string, user_feedback: record, user_reference: string, webhook_url: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    create-porting-order: "record<data: table<activation_settings: record, created_at: string, end_user: record, id: string, misc: record, old_service_provider_ocn: string, phone_number_configuration: record, porting_phone_numbers_count: int, record_type: string, requirements: list, status: record, support_key: string, updated_at: string, user_feedback: record, user_reference: string, webhook_url: string>>"
    list-porting-orders-exception-types: "record<data: table<code: string, description: string>>"
    delete-porting-order: "record<data: record<activation_settings: record<activation_status: string, fast_port_eligible: bool, foc_datetime_actual: string, foc_datetime_requested: string>, created_at: string, end_user: record<admin: record, location: record>, id: string, misc: record<new_billing_phone_number: string, remaining_numbers_action: string, type: string>, old_service_provider_ocn: string, phone_number_configuration: record<connection_id: string, emergency_address_id: string, messaging_profile_id: string, tags: list>, porting_phone_numbers_count: int, record_type: string, requirements: list<record>, status: record<details: list, value: string>, support_key: string, updated_at: string, user_feedback: record<user_comment: string, user_rating: int>, user_reference: string, webhook_url: string>, meta: record<phone_numbers_url: string>>"
    get-porting-order: "record<data: record<activation_settings: record<activation_status: string, fast_port_eligible: bool, foc_datetime_actual: string, foc_datetime_requested: string>, created_at: string, end_user: record<admin: record, location: record>, id: string, misc: record<new_billing_phone_number: string, remaining_numbers_action: string, type: string>, old_service_provider_ocn: string, phone_number_configuration: record<connection_id: string, emergency_address_id: string, messaging_profile_id: string, tags: list>, porting_phone_numbers_count: int, record_type: string, requirements: list<record>, status: record<details: list, value: string>, support_key: string, updated_at: string, user_feedback: record<user_comment: string, user_rating: int>, user_reference: string, webhook_url: string>, meta: record<phone_numbers_url: string>>"
    update-porting-order: "record<data: record<activation_settings: record<activation_status: string, fast_port_eligible: bool, foc_datetime_actual: string, foc_datetime_requested: string>, created_at: string, end_user: record<admin: record, location: record>, id: string, misc: record<new_billing_phone_number: string, remaining_numbers_action: string, type: string>, old_service_provider_ocn: string, phone_number_configuration: record<connection_id: string, emergency_address_id: string, messaging_profile_id: string, tags: list>, porting_phone_numbers_count: int, record_type: string, requirements: list<record>, status: record<details: list, value: string>, support_key: string, updated_at: string, user_feedback: record<user_comment: string, user_rating: int>, user_reference: string, webhook_url: string>, meta: record<phone_numbers_url: string>>"
    activate-porting-order: "record<data: record<created_at: string, id: string, record_type: string, status: string, updated_at: string>>"
    cancel-porting-order: "record<data: record<activation_settings: record<activation_status: string, fast_port_eligible: bool, foc_datetime_actual: string, foc_datetime_requested: string>, created_at: string, end_user: record<admin: record, location: record>, id: string, misc: record<new_billing_phone_number: string, remaining_numbers_action: string, type: string>, old_service_provider_ocn: string, phone_number_configuration: record<connection_id: string, emergency_address_id: string, messaging_profile_id: string, tags: list>, porting_phone_numbers_count: int, record_type: string, requirements: list<record>, status: record<details: list, value: string>, support_key: string, updated_at: string, user_feedback: record<user_comment: string, user_rating: int>, user_reference: string, webhook_url: string>, meta: record<phone_numbers_url: string>>"
    confirm-porting-order: "record<data: record<activation_settings: record<activation_status: string, fast_port_eligible: bool, foc_datetime_actual: string, foc_datetime_requested: string>, created_at: string, end_user: record<admin: record, location: record>, id: string, misc: record<new_billing_phone_number: string, remaining_numbers_action: string, type: string>, old_service_provider_ocn: string, phone_number_configuration: record<connection_id: string, emergency_address_id: string, messaging_profile_id: string, tags: list>, porting_phone_numbers_count: int, record_type: string, requirements: list<record>, status: record<details: list, value: string>, support_key: string, updated_at: string, user_feedback: record<user_comment: string, user_rating: int>, user_reference: string, webhook_url: string>, meta: record<phone_numbers_url: string>>"
    list-porting-orders-activation-jobs: "record<data: table<created_at: string, id: string, record_type: string, status: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    get-porting-orders-activation-job: "record<data: record<created_at: string, id: string, record_type: string, status: string, updated_at: string>>"
    list-porting-orders-comments: "record<data: table<body: string, created_at: string, id: string, porting_order_id: string, record_type: string, user_type: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    create-porting-order-comment: "record<data: record<body: string, created_at: string, id: string, porting_order_id: string, record_type: string, user_type: string>>"
    get-porting-order-loa-template: "binary"
    get-porting-phone-numbers: "record<data: table<id: string, phone_number: string, record_type: string, regulatory_group_id: string, regulatory_requirements: list, requirements_met: bool, status: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    list-portout-request: "record<data: table<carrier_name: string, created_at: string, foc_date: string, id: string, phone_numbers: list, record_type: string, requested_foc_date: string, spid: string, status: string, updated_at: string>, meta: record<page_number: float, page_size: float, total_pages: float, total_results: float>>"
    find-portout-request: "record<data: record<carrier_name: string, created_at: string, foc_date: string, id: string, phone_numbers: list<string>, record_type: string, requested_foc_date: string, spid: string, status: string, updated_at: string>>"
    find-portout-comments: "record<data: table<body: string, created_at: string, id: string, portout_id: string, record_type: string, user_id: string>, meta: record<page_number: float, page_size: float, total_pages: float, total_results: float>>"
    post-port-request-comment: "record<data: record<body: string, created_at: string, id: string, portout_id: string, record_type: string, user_id: string>>"
    update-portout-request: "record<data: record<carrier_name: string, created_at: string, foc_date: string, id: string, phone_numbers: list<string>, record_type: string, requested_foc_date: string, spid: string, status: string, updated_at: string>>"
    get-private-wireless-gateways: "record<data: table<created_at: string, id: string, ip_range: string, name: string, network_id: string, record_type: string, region_code: string, status: record, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    create-private-wireless-gateway: "record<data: record<created_at: string, id: string, ip_range: string, name: string, network_id: string, record_type: string, region_code: string, status: record<error_code: string, error_description: string, value: string>, updated_at: string>>"
    delete-private-wireless-gateway: "record<data: record<created_at: string, id: string, ip_range: string, name: string, network_id: string, record_type: string, region_code: string, status: record<error_code: string, error_description: string, value: string>, updated_at: string>>"
    get-private-wireless-gateway: "record<data: record<created_at: string, id: string, ip_range: string, name: string, network_id: string, record_type: string, region_code: string, status: record<error_code: string, error_description: string, value: string>, updated_at: string>>"
    retrieve-call-queue: "record<data: record<average_wait_time_secs: int, created_at: string, current_size: int, id: string, max_size: int, name: string, record_type: string, updated_at: string>>"
    list-queue-calls: "record<data: table<call_control_id: string, call_leg_id: string, call_session_id: string, connection_id: string, enqueued_at: string, from: string, queue_id: string, queue_position: int, record_type: string, to: string, wait_time_secs: int>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    retrieve-call-from-queue: "record<data: record<call_control_id: string, call_leg_id: string, call_session_id: string, connection_id: string, enqueued_at: string, from: string, queue_id: string, queue_position: int, record_type: string, to: string, wait_time_secs: int>>"
    list-recordings: "record<data: table<call_leg_id: string, call_session_id: string, channels: string, conference_id: string, created_at: string, download_urls: record, duration_millis: int, id: string, record_type: string, recording_ended_at: string, recording_started_at: string, source: string, status: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    retrieve-recording: "record<data: record<call_leg_id: string, call_session_id: string, channels: string, conference_id: string, created_at: string, download_urls: record<mp3: string, wav: string>, duration_millis: int, id: string, record_type: string, recording_ended_at: string, recording_started_at: string, source: string, status: string, updated_at: string>>"
    get-cdr-requests: "record<data: table<connections: list, created_at: string, directions: list, end_date: string, filters: list, id: string, profiles: string, record_type: string, record_types: list, report_name: string, report_url: string, start_date: string, status: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    submit-mdr-request: "record<data: record<connections: list<int>, created_at: string, directions: list<string>, end_date: string, filters: list<record>, id: string, profiles: string, record_type: string, record_types: list<string>, report_name: string, report_url: string, start_date: string, status: string, updated_at: string>>"
    delete-mdr-request: "record<data: record<connections: list<int>, created_at: string, directions: list<string>, end_date: string, filters: list<record>, id: string, profiles: string, record_type: string, record_types: list<string>, report_name: string, report_url: string, start_date: string, status: string, updated_at: string>>"
    get-mdr-request: "record<data: record<connections: list<int>, created_at: string, directions: list<string>, end_date: string, filters: list<record>, id: string, profiles: string, record_type: string, record_types: list<string>, report_name: string, report_url: string, start_date: string, status: string, updated_at: string>>"
    get-usage-report-sync: "record<data: record<aggregation_type: string, connections: list<int>, created_at: string, end_time: string, id: string, product_breakdown: string, record_type: string, report_url: string, result: record, start_time: string, status: string, updated_at: string>>"
    get-usage-reports: "record<data: table<aggregation_type: string, connections: list, created_at: string, end_date: string, id: string, profiles: string, record_type: string, report_url: string, result: list, start_date: string, status: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    submit-usage-report: "record<data: record<aggregation_type: string, connections: list<int>, created_at: string, end_date: string, id: string, profiles: string, record_type: string, report_url: string, result: list<record>, start_date: string, status: string, updated_at: string>>"
    get-usage-report-sync-1: "record<data: record<aggregation_type: string, connections: list<int>, created_at: string, end_date: string, id: string, profiles: string, record_type: string, report_url: string, result: list<record>, start_date: string, status: string, updated_at: string>>"
    delete-usage-report: "record<data: record<aggregation_type: string, connections: list<int>, created_at: string, end_date: string, id: string, profiles: string, record_type: string, report_url: string, result: list<record>, start_date: string, status: string, updated_at: string>>"
    get-usage-report: "record<data: record<aggregation_type: string, connections: list<int>, created_at: string, end_date: string, id: string, profiles: string, record_type: string, report_url: string, result: list<record>, start_date: string, status: string, updated_at: string>>"
    get-reports-mdrs: "record<data: table<cld: string, cli: string, cost: string, created_at: string, currency: string, direction: string, id: string, message_type: string, parts: float, profile_name: string, rate: string, record_type: string, status: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    get-paginated-wdrs: "record<data: table<cost: record, created_at: string, downlink_data: record, duration_seconds: float, id: string, imsi: string, mcc: string, mnc: string, phone_number: string, rate: record, record_type: string, sim_card_id: string, sim_group_id: string, sim_group_name: string, uplink_data: record>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    doc-reqs-list-requirement-types: "record<data: table<acceptance_criteria: record, created_at: string, description: string, example: string, id: string, name: string, record_type: string, type: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    doc-reqs-retrieve-requirement-type: "record<data: record<acceptance_criteria: record<locality_limit: string, time_limit: string>, created_at: string, description: string, example: string, id: string, name: string, record_type: string, type: string, updated_at: string>>"
    list-requirements: "record<data: table<action: string, country_code: string, created_at: string, id: string, locality: string, phone_number_type: string, record_type: string, requirements_types: list, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    doc-reqs-retrieve-document-requirements: "record<data: record<action: string, country_code: string, created_at: string, id: string, locality: string, phone_number_type: string, record_type: string, requirements_types: list<record>, updated_at: string>>"
    list-room-participants: "record<data: table<context: string, id: string, joined_at: string, left_at: string, record_type: string, session_id: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    view-room-participant: "record<data: record<context: string, id: string, joined_at: string, left_at: string, record_type: string, session_id: string, updated_at: string>>"
    list-room-sessions: "record<data: table<active: bool, created_at: string, ended_at: string, id: string, participants: list, record_type: string, room_id: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    view-room-session: "record<data: record<active: bool, created_at: string, ended_at: string, id: string, participants: list<record>, record_type: string, room_id: string, updated_at: string>>"
    nested-list-room-participants: "record<data: table<context: string, id: string, joined_at: string, left_at: string, record_type: string, session_id: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    list-rooms: "record<data: table<active_session_id: string, created_at: string, id: string, max_participants: int, record_type: string, sessions: list, unique_name: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    create-room: "record<data: record<active_session_id: string, created_at: string, id: string, max_participants: int, record_type: string, sessions: list<record>, unique_name: string, updated_at: string>>"
    view-room: "record<data: record<active_session_id: string, created_at: string, id: string, max_participants: int, record_type: string, sessions: list<record>, unique_name: string, updated_at: string>>"
    create-room-client-token: "record<data: record<refresh_token: string, refresh_token_expires_at: string, token: string, token_expires_at: string>>"
    refresh-room-client-token: "record<data: record<token: string, token_expires_at: string>>"
    nested-list-room-sessions: "record<data: table<active: bool, created_at: string, ended_at: string, id: string, participants: list, record_type: string, room_id: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    list-short-codes: "record<data: table<country_code: string, created_at: string, id: string, messaging_profile_id: string, record_type: string, short_code: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    retrieve-short-code: "record<data: record<country_code: string, created_at: string, id: string, messaging_profile_id: string, record_type: string, short_code: string, updated_at: string>>"
    update-short-code: "record<data: record<country_code: string, created_at: string, id: string, messaging_profile_id: string, record_type: string, short_code: string, updated_at: string>>"
    sim-card-group-actions-get: "record<data: table<created_at: string, id: string, record_type: string, settings: record, sim_card_group_id: string, status: string, type: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    sim-card-group-action-get: "record<data: record<created_at: string, id: string, record_type: string, settings: record<private_wireless_gateway_id: string>, sim_card_group_id: string, status: string, type: string, updated_at: string>>"
    sim-card-groups-get-all: "record<data: table<consumed_data: record, created_at: string, data_limit: int, default: bool, id: string, name: string, private_wireless_gateway_id: string, record_type: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    sim-card-groups-post: "record<data: record<consumed_data: record<amount: int, unit: string>, created_at: string, data_limit: int, default: bool, id: string, name: string, private_wireless_gateway_id: string, record_type: string, updated_at: string>>"
    sim-card-group-delete: "record<data: record<consumed_data: record<amount: int, unit: string>, created_at: string, data_limit: int, default: bool, id: string, name: string, private_wireless_gateway_id: string, record_type: string, updated_at: string>>"
    sim-card-groups-get: "record<data: record<consumed_data: record<amount: int, unit: string>, created_at: string, data_limit: int, default: bool, id: string, name: string, private_wireless_gateway_id: string, record_type: string, updated_at: string>>"
    sim-card-group-update: "record<data: record<consumed_data: record<amount: int, unit: string>, created_at: string, data_limit: int, default: bool, id: string, name: string, private_wireless_gateway_id: string, record_type: string, updated_at: string>>"
    remove-sim-card-group-private-wireless-gateway: "record<data: record<created_at: string, id: string, record_type: string, settings: record<private_wireless_gateway_id: string>, sim_card_group_id: string, status: string, type: string, updated_at: string>>"
    set-sim-card-group-private-wireless-gateway: "record<data: record<created_at: string, id: string, record_type: string, settings: record<private_wireless_gateway_id: string>, sim_card_group_id: string, status: string, type: string, updated_at: string>>"
    sim-card-orders-preview: "record<data: record<quantity: int, record_type: string, shipping_cost: record<amount: string, currency: string>, sim_cards_cost: record<amount: string, currency: string>, total_cost: record<amount: string, currency: string>>>"
    sim-card-orders-get: "record<data: table<cost: record, created_at: string, id: string, order_address: record, quantity: int, record_type: string, status: string, tracking_url: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    sim-card-orders-post: "record<data: record<cost: record<amount: string, currency: string>, created_at: string, id: string, order_address: record<administrative_area: string, country_code: string, extended_address: string, id: string, locality: string, postal_code: string, street_address: string>, quantity: int, record_type: string, status: string, tracking_url: string, updated_at: string>>"
    sim-card-order-get: "record<data: record<cost: record<amount: string, currency: string>, created_at: string, id: string, order_address: record<administrative_area: string, country_code: string, extended_address: string, id: string, locality: string, postal_code: string, street_address: string>, quantity: int, record_type: string, status: string, tracking_url: string, updated_at: string>>"
    sim-cards-get: "record<data: table<created_at: string, iccid: string, id: string, imsi: string, msisdn: string, record_type: string, sim_card_group_id: string, status: string, tags: list, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    post-validate-registration-codes: "record<data: table<invalid_detail: string, record_type: string, registration_code: string, valid: bool>>"
    sim-card-delete: "record<data: record<created_at: string, iccid: string, id: string, imsi: string, ipv4: string, ipv6: string, msisdn: string, record_type: string, sim_card_group_id: string, status: string, tags: list<string>, updated_at: string>>"
    sim-card-get: "record<data: record<created_at: string, iccid: string, id: string, imsi: string, ipv4: string, ipv6: string, msisdn: string, record_type: string, sim_card_group_id: string, status: string, tags: list<string>, updated_at: string>>"
    sim-card-update: "record<data: record<created_at: string, iccid: string, id: string, imsi: string, ipv4: string, ipv6: string, msisdn: string, record_type: string, sim_card_group_id: string, status: string, tags: list<string>, updated_at: string>>"
    sim-card-disable: "record<data: record<created_at: string, iccid: string, id: string, imsi: string, msisdn: string, record_type: string, sim_card_group_id: string, status: string, tags: list<string>, updated_at: string>>"
    sim-card-enable: "record<data: record<created_at: string, iccid: string, id: string, imsi: string, msisdn: string, record_type: string, sim_card_group_id: string, status: string, tags: list<string>, updated_at: string>>"
    sim-card-set-standby: "record<data: record<created_at: string, iccid: string, id: string, imsi: string, msisdn: string, record_type: string, sim_card_group_id: string, status: string, tags: list<string>, updated_at: string>>"
    sim-card-network-preferences-delete: "record<data: record<created_at: string, mobile_operator_networks_preferences: list<record>, ota_updates: list<record>, record_type: string, sim_card_id: string, updated_at: string>>"
    sim-card-network-preferences-get: "record<data: record<created_at: string, mobile_operator_networks_preferences: list<record>, ota_updates: list<record>, record_type: string, sim_card_id: string, updated_at: string>>"
    sim-card-network-preferences-put: "record<data: record<created_at: string, mobile_operator_networks_preferences: list<record>, ota_updates: list<record>, record_type: string, sim_card_id: string, updated_at: string>>"
    sim-card-public-ip-delete: "record<data: record<created_at: string, ip: string, record_type: string, sim_card_id: string, status: record<error_code: string, error_description: string, value: string>, type: string, updated_at: string>>"
    sim-card-public-ip-get: "record<data: record<created_at: string, ip: string, record_type: string, sim_card_id: string, status: record<error_code: string, error_description: string, value: string>, type: string, updated_at: string>>"
    sim-card-public-ip-post: "record<data: record<created_at: string, ip: string, record_type: string, sim_card_id: string, status: record<error_code: string, error_description: string, value: string>, type: string, updated_at: string>>"
    wireless-connectivity-logs-get: "record<data: table<apn: string, id: int, imei: string, imsi: string, ipv4: string, ipv6: string, log_type: string, mobile_country_code: string, mobile_network_code: string, radio_access_technology: string, record_type: string, sim_card_id: string, start_time: string, state: string, stop_time: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    list-sub-number-orders: "record<data: table<country_code: string, created_at: string, id: string, order_request_id: string, phone_number_type: string, phone_numbers_count: int, record_type: string, regulatory_requirements: list, requirements_met: bool, updated_at: string, user_id: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    retrieve-sub-number-order: "record<data: record<country_code: string, created_at: string, id: string, order_request_id: string, phone_number_type: string, phone_numbers_count: int, record_type: string, regulatory_requirements: list<record>, requirements_met: bool, updated_at: string, user_id: string>>"
    update-sub-number-order: "record<data: record<country_code: string, created_at: string, id: string, order_request_id: string, phone_number_type: string, phone_numbers_count: int, record_type: string, regulatory_requirements: list<record>, requirements_met: bool, updated_at: string, user_id: string>>"
    find-telephony-credentials: "record<data: table<created_at: string, expired: bool, expires_at: string, id: string, name: string, record_type: string, resource_id: string, sip_password: string, sip_username: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    create-telephony-credential: "record<data: record<created_at: string, expired: bool, expires_at: string, id: string, name: string, record_type: string, resource_id: string, sip_password: string, sip_username: string, updated_at: string>>"
    list-tags: "record<data: table<amount: int, tag: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    delete-telephony-credential: "record<data: record<created_at: string, expired: bool, expires_at: string, id: string, name: string, record_type: string, resource_id: string, sip_password: string, sip_username: string, updated_at: string>>"
    get-telephony-credential: "record<data: record<created_at: string, expired: bool, expires_at: string, id: string, name: string, record_type: string, resource_id: string, sip_password: string, sip_username: string, updated_at: string>>"
    update-telephony-credential: "record<data: record<created_at: string, expired: bool, expires_at: string, id: string, name: string, record_type: string, resource_id: string, sip_password: string, sip_username: string, updated_at: string>>"
    telephony-credential-action: "record<data: record<created_at: string, expired: bool, expires_at: string, id: string, name: string, record_type: string, resource_id: string, sip_password: string, sip_username: string, updated_at: string>>"
    create-telephony-credential-token: "string"
    find-texml-applications: "record<data: table<active: bool, anchorsite_override: string, created_at: string, dtmf_type: string, first_command_timeout: bool, first_command_timeout_secs: int, friendly_name: string, id: string, inbound: record, outbound: record, record_type: string, status_callback: string, status_callback_method: string, updated_at: string, voice_fallback_url: string, voice_method: string, voice_url: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    create-texml-application: "record<data: record<active: bool, anchorsite_override: string, created_at: string, dtmf_type: string, first_command_timeout: bool, first_command_timeout_secs: int, friendly_name: string, id: string, inbound: record<channel_limit: int, sip_subdomain: string, sip_subdomain_receive_settings: string>, outbound: record<channel_limit: int, outbound_voice_profile_id: string>, record_type: string, status_callback: string, status_callback_method: string, updated_at: string, voice_fallback_url: string, voice_method: string, voice_url: string>>"
    delete-texml-application: "record<data: record<active: bool, anchorsite_override: string, created_at: string, dtmf_type: string, first_command_timeout: bool, first_command_timeout_secs: int, friendly_name: string, id: string, inbound: record<channel_limit: int, sip_subdomain: string, sip_subdomain_receive_settings: string>, outbound: record<channel_limit: int, outbound_voice_profile_id: string>, record_type: string, status_callback: string, status_callback_method: string, updated_at: string, voice_fallback_url: string, voice_method: string, voice_url: string>>"
    get-texml-application: "record<data: record<active: bool, anchorsite_override: string, created_at: string, dtmf_type: string, first_command_timeout: bool, first_command_timeout_secs: int, friendly_name: string, id: string, inbound: record<channel_limit: int, sip_subdomain: string, sip_subdomain_receive_settings: string>, outbound: record<channel_limit: int, outbound_voice_profile_id: string>, record_type: string, status_callback: string, status_callback_method: string, updated_at: string, voice_fallback_url: string, voice_method: string, voice_url: string>>"
    update-texml-application: "record<data: record<active: bool, anchorsite_override: string, created_at: string, dtmf_type: string, first_command_timeout: bool, first_command_timeout_secs: int, friendly_name: string, id: string, inbound: record<channel_limit: int, sip_subdomain: string, sip_subdomain_receive_settings: string>, outbound: record<channel_limit: int, outbound_voice_profile_id: string>, record_type: string, status_callback: string, status_callback_method: string, updated_at: string, voice_fallback_url: string, voice_method: string, voice_url: string>>"
    list-verifications: "record<data: table<call_timeout_secs: int, created_at: string, id: string, phone_number: string, record_type: string, status: string, timeout_secs: int, updated_at: string, verification_type: string, verify_profile_id: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    verify-verification-code: "record<data: record<phone_number: string, response_code: string>>"
    create-verification-call: "record<data: record<call_timeout_secs: int, created_at: string, id: string, phone_number: string, record_type: string, status: string, timeout_secs: int, updated_at: string, verification_type: string, verify_profile_id: string>>"
    create-verification-flashcall: "record<data: record<call_timeout_secs: int, created_at: string, id: string, phone_number: string, record_type: string, status: string, timeout_secs: int, updated_at: string, verification_type: string, verify_profile_id: string>>"
    create-verification-psd2: "record<data: record<call_timeout_secs: int, created_at: string, id: string, phone_number: string, record_type: string, status: string, timeout_secs: int, updated_at: string, verification_type: string, verify_profile_id: string>>"
    create-verification-sms: "record<data: record<call_timeout_secs: int, created_at: string, id: string, phone_number: string, record_type: string, status: string, timeout_secs: int, updated_at: string, verification_type: string, verify_profile_id: string>>"
    create-verification-whatsapp: "record<data: record<call_timeout_secs: int, created_at: string, id: string, phone_number: string, record_type: string, status: string, timeout_secs: int, updated_at: string, verification_type: string, verify_profile_id: string>>"
    retrieve-verification: "record<data: record<call_timeout_secs: int, created_at: string, id: string, phone_number: string, record_type: string, status: string, timeout_secs: int, updated_at: string, verification_type: string, verify_profile_id: string>>"
    list-verify-profiles: "record<data: table<call: record, created_at: string, flashcall: record, id: string, language: string, name: string, psd2: record, record_type: string, sms: record, updated_at: string, webhook_failover_url: string, webhook_url: string, whatsapp: record>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    create-verify-profile: "record<data: record<call: record<default_call_timeout_secs: int, default_verification_timeout_secs: int, speech_template: string>, created_at: string, flashcall: record<default_verification_timeout_secs: int>, id: string, language: string, name: string, psd2: record<default_verification_timeout_secs: int>, record_type: string, sms: record<default_verification_timeout_secs: int, messaging_enabled: bool, messaging_template: string, rcs_enabled: bool, vsms_enabled: bool>, updated_at: string, webhook_failover_url: string, webhook_url: string, whatsapp: record<app_name: string, default_verification_timeout_secs: int>>>"
    delete-verify-profile: "record<data: record<call: record<default_call_timeout_secs: int, default_verification_timeout_secs: int, speech_template: string>, created_at: string, flashcall: record<default_verification_timeout_secs: int>, id: string, language: string, name: string, psd2: record<default_verification_timeout_secs: int>, record_type: string, sms: record<default_verification_timeout_secs: int, messaging_enabled: bool, messaging_template: string, rcs_enabled: bool, vsms_enabled: bool>, updated_at: string, webhook_failover_url: string, webhook_url: string, whatsapp: record<app_name: string, default_verification_timeout_secs: int>>>"
    retrieve-verify-profile: "record<data: record<call: record<default_call_timeout_secs: int, default_verification_timeout_secs: int, speech_template: string>, created_at: string, flashcall: record<default_verification_timeout_secs: int>, id: string, language: string, name: string, psd2: record<default_verification_timeout_secs: int>, record_type: string, sms: record<default_verification_timeout_secs: int, messaging_enabled: bool, messaging_template: string, rcs_enabled: bool, vsms_enabled: bool>, updated_at: string, webhook_failover_url: string, webhook_url: string, whatsapp: record<app_name: string, default_verification_timeout_secs: int>>>"
    update-verify-profile: "record<data: record<call: record<default_call_timeout_secs: int, default_verification_timeout_secs: int, speech_template: string>, created_at: string, flashcall: record<default_verification_timeout_secs: int>, id: string, language: string, name: string, psd2: record<default_verification_timeout_secs: int>, record_type: string, sms: record<default_verification_timeout_secs: int, messaging_enabled: bool, messaging_template: string, rcs_enabled: bool, vsms_enabled: bool>, updated_at: string, webhook_failover_url: string, webhook_url: string, whatsapp: record<app_name: string, default_verification_timeout_secs: int>>>"
    get-webhook-deliveries: "record<data: table<attempts: list, finished_at: string, id: string, record_type: string, started_at: string, status: string, user_id: string, webhook: record>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    get-webhook-delivery: "record<data: record<attempts: list<record>, finished_at: string, id: string, record_type: string, started_at: string, status: string, user_id: string, webhook: record<event_type: string, id: string, occurred_at: string, payload: record, record_type: string>>>"
    check-contact: "record<data: table<id: string, input: string, record_type: string, status: string>>"
    get-requests: "record<data: table<created_at: string, download_link: string, end_date: string, id: string, record_type: string, start_date: string, status: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>"
    submit-request: "record<data: record<created_at: string, download_link: string, end_date: string, id: string, record_type: string, start_date: string, status: string>>"
    delete-request: "record<data: record<created_at: string, download_link: string, end_date: string, id: string, record_type: string, start_date: string, status: string>>"
    get-request: "record<data: record<created_at: string, download_link: string, end_date: string, id: string, record_type: string, start_date: string, status: string>>"
    upload-media: "record<data: table<id: string, record_type: string>>"
    get-whatsapp-media-whatsapp-user-id-media-id: "binary"
    send-message: "record<data: record<id: string, record_type: string>>"
    get-usage-aggregations-sync: "record<data: table<cost: record, count: string, direction: string, message_type: string, recipient_country_code: string, record_type: string, status: string, telnyx_fee: record, whatsapp_fee: record>>"
    get-user: "record<data: record<id: string, record_type: string, webhook_url: string>>"
    get-wdr-reports: "record<data: table<created_at: string, end_time: string, id: string, record_type: string, report_url: string, start_time: string, status: string, updated_at: string>>"
    create-wdr-report: "record<data: record<created_at: string, end_time: string, id: string, record_type: string, report_url: string, start_time: string, status: string, updated_at: string>>"
    delete-wdr-report: "record<data: record<created_at: string, end_time: string, id: string, record_type: string, report_url: string, start_time: string, status: string, updated_at: string>>"
    get-wdr-report: "record<data: record<created_at: string, end_time: string, id: string, record_type: string, report_url: string, start_time: string, status: string, updated_at: string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["delete-bulk-telephony-credential" "update-bulk-telephony-credential" "create-bulk-telephony-credential" "bulk-sim-card-network-preferences" "sim-card-register" "bulk-credential-action" "find-addresss" "create-address" "validate-address" "delete-address" "get-address" "find-authentication-providers" "create-authentication-provider" "delete-authentication-provider" "get-authentication-provider" "update-authentication-provider" "list-available-phone-number-blocks" "list-available-phone-numbers" "get-user-balance" "list-billing-groups" "create-billing-group" "delete-billing-group" "retrieve-billing-group" "update-billing-group" "list-call-control-applications" "create-call-control-application" "delete-call-control-application" "retrieve-call-control-application" "update-call-control-application" "list-call-events" "call-dial" "retrieve-call-status" "call-answer" "call-bridge" "call-enqueue" "call-fork-start" "call-fork-stop" "call-gather-stop" "call-gather-using-audio" "call-gather-using-speak" "call-hangup" "leave-queue" "call-playback-start" "call-playback-stop" "call-record-pause" "call-record-resume" "call-record-start" "call-record-stop" "call-refer" "call-reject" "call-send-dtmf" "call-speak" "call-transcription-start" "call-transcription-stop" "call-transfer" "list-comments" "create-comment" "retrieve-comment" "mark-comment-read" "list-conferences" "create-conference" "list-conference-participants" "retrieve-conference" "conference-dial-participant-in" "conference-hold-participants" "conference-join" "conference-leave" "conference-mute-participants" "conference-play-audio" "conference-start-recording" "conference-stop-recording" "conference-speak-text" "conference-stop-audio" "conference-unhold-participants" "conference-unmute-participants" "conference-update" "list-connections" "retrieve-connection" "list-credential-connections" "create-credential-connection" "delete-credential-connection" "retrieve-credential-connection" "update-credential-connection" "detail-records-search" "list-document-links" "list-documents" "create-document" "delete-document" "retrieve-document" "update-document" "download-doc-service-document" "list-fax-applications" "create-fax-application" "delete-fax-application" "get-fax-application" "update-fax-application" "list-faxes" "send-fax" "delete-fax" "view-fax" "refresh-fax" "list-fqdn-connections" "create-fqdn-connection" "delete-fqdn-connection" "retrieve-fqdn-connection" "update-fqdn-connection" "list-fqdns" "create-fqdn" "delete-fqdn" "retrieve-fqdn" "update-fqdn" "create-inventory-coverage-request" "list-ip-connections" "create-ip-connection" "delete-ip-connection" "retrieve-ip-connection" "update-ip-connection" "list-ips" "create-ip" "delete-ip" "retrieve-ip" "update-ip" "create-ledger-billing-group-report" "retrieve-ledger-billing-group-report" "list-managed-accounts" "create-managed-account" "retrieve-managed-account" "disable-managed-account" "enable-managed-account" "list-media" "create-media" "delete-media" "get-media" "update-media" "download-media" "get-paginated-mdrs" "get-mdr-message-body" "create-message" "create-long-code-message" "create-number-pool-message" "create-short-code-message" "retrieve-message" "list-messaging-hosted-number-order" "create-messaging-hosted-number-order" "retrieve-messaging-hosted-number-order" "upload-file-messaging-hosted-number-order" "delete-messaging-hosted-number" "list-messaging-profile-metrics" "list-messaging-profiles" "create-messaging-profile" "delete-messaging-profile" "retrieve-messaging-profile" "update-messaging-profile" "retrieve-messaging-profile-detailed-metrics" "list-messaging-profile-phone-numbers" "list-messaging-profile-short-codes" "list-messaging-url-domains" "mobile-operator-networks-get" "list-notification-channels" "create-notification-channels" "delete-notification-channel" "retrieve-notification-channel" "update-notification-channel" "find-notifications-events-conditions" "find-notifications-events" "find-notifications-profiles" "create-notification-profile" "delete-notification-profile" "retrieve-notification-profile" "update-notification-profile" "list-notification-settings" "create-notification-setting" "delete-notification-setting" "retrieve-notification-setting" "list-number-block-orders" "create-number-block-order" "retrieve-number-block-order" "number-lookup" "list-number-order-documents" "create-number-order-document" "retrieve-number-order-document" "update-number-order-document" "retrieve-number-order-phone-numbers" "retrieve-number-order-phone-number" "update-number-order-phone-number" "list-number-orders" "create-number-order" "retrieve-number-order" "update-number-order" "list-number-reservations" "create-number-reservation" "retrieve-number-reservation" "extend-number-reservation-expiry-time" "ota-updates-list" "ota-update-get" "list-outbound-voice-profiles" "create-outbound-voice-profile" "delete-outbound-voice-profile" "retrieve-outbound-voice-profile" "update-outbound-voice-profile" "list-phone-number-blocks-jobs" "create-phone-number-blocks-job-delete-phone-number-block" "retrieve-phone-number-blocks-job" "list-phone-numbers" "list-csv-downloads" "create-csv-download" "retrieve-csv-download" "list-outbound-channels" "update-outbound-channels" "list-phone-numbers-jobs" "create-phone-numbers-job-delete-phone-numbers" "create-phone-numbers-job-update-emergency-settings" "create-phone-numbers-job-update-phone-number" "retrieve-phone-numbers-job" "list-phone-numbers-with-messaging-settings" "list-phone-numbers-with-voice-settings" "delete-phone-number" "retrieve-phone-number" "update-phone-number" "enable-emergency-phone-number" "retrieve-phone-number-with-messaging-settings" "update-phone-number-with-messaging-settings" "retrieve-phone-number-with-voice-settings" "update-phone-number-with-voice-settings" "post-portability-check" "list-porting-orders" "create-porting-order" "list-porting-orders-exception-types" "delete-porting-order" "get-porting-order" "update-porting-order" "activate-porting-order" "cancel-porting-order" "confirm-porting-order" "list-porting-orders-activation-jobs" "get-porting-orders-activation-job" "list-porting-orders-comments" "create-porting-order-comment" "get-porting-order-loa-template" "get-porting-phone-numbers" "list-portout-request" "find-portout-request" "find-portout-comments" "post-port-request-comment" "update-portout-request" "get-private-wireless-gateways" "create-private-wireless-gateway" "delete-private-wireless-gateway" "get-private-wireless-gateway" "retrieve-call-queue" "list-queue-calls" "retrieve-call-from-queue" "list-recordings" "retrieve-recording" "get-cdr-requests" "submit-mdr-request" "delete-mdr-request" "get-mdr-request" "get-usage-report-sync" "get-usage-reports" "submit-usage-report" "get-usage-report-sync-1" "delete-usage-report" "get-usage-report" "get-reports-mdrs" "get-paginated-wdrs" "doc-reqs-list-requirement-types" "doc-reqs-retrieve-requirement-type" "list-requirements" "doc-reqs-retrieve-document-requirements" "list-room-participants" "view-room-participant" "list-room-sessions" "view-room-session" "nested-list-room-participants" "list-rooms" "create-room" "delete-room" "view-room" "create-room-client-token" "refresh-room-client-token" "nested-list-room-sessions" "list-short-codes" "retrieve-short-code" "update-short-code" "sim-card-group-actions-get" "sim-card-group-action-get" "sim-card-groups-get-all" "sim-card-groups-post" "sim-card-group-delete" "sim-card-groups-get" "sim-card-group-update" "remove-sim-card-group-private-wireless-gateway" "set-sim-card-group-private-wireless-gateway" "sim-card-orders-preview" "sim-card-orders-get" "sim-card-orders-post" "sim-card-order-get" "sim-cards-get" "post-validate-registration-codes" "sim-card-delete" "sim-card-get" "sim-card-update" "sim-card-disable" "sim-card-enable" "sim-card-set-standby" "sim-card-network-preferences-delete" "sim-card-network-preferences-get" "sim-card-network-preferences-put" "sim-card-public-ip-delete" "sim-card-public-ip-get" "sim-card-public-ip-post" "wireless-connectivity-logs-get" "list-sub-number-orders" "retrieve-sub-number-order" "update-sub-number-order" "find-telephony-credentials" "create-telephony-credential" "list-tags" "delete-telephony-credential" "get-telephony-credential" "update-telephony-credential" "telephony-credential-action" "create-telephony-credential-token" "find-texml-applications" "create-texml-application" "delete-texml-application" "get-texml-application" "update-texml-application" "list-verifications" "verify-verification-code" "create-verification-call" "create-verification-flashcall" "create-verification-psd2" "create-verification-sms" "create-verification-whatsapp" "retrieve-verification" "list-verify-profiles" "create-verify-profile" "delete-verify-profile" "retrieve-verify-profile" "update-verify-profile" "get-webhook-deliveries" "get-webhook-delivery" "check-contact" "get-requests" "submit-request" "delete-request" "get-request" "upload-media" "delete-whatsapp-media-whatsapp-user-id-media-id" "get-whatsapp-media-whatsapp-user-id-media-id" "send-message" "mark-message-as-read" "get-usage-aggregations-sync" "get-user" "update-whats-app-webhook" "get-wdr-reports" "create-wdr-report" "delete-wdr-report" "get-wdr-report" "commands"] | sort) } | get name | first)
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

# Delete several credentials
#
# DELETE /actions/bulk/telephony_credentials
# Returns: record<data: record<credentials: int>>
# operationId: DeleteBulkTelephonyCredential
export def "delete-bulk-telephony-credential" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-tag: string # Filter by tag, required by bulk operations. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/actions/bulk/telephony_credentials"
    query: [{name: "filter[tag]", var: filter_tag, required: true}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    filter_tag: $filter_tag
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update several credentials
#
# PATCH /actions/bulk/telephony_credentials
# Returns: record<data: record<credentials: int>>
# operationId: UpdateBulkTelephonyCredential
export def "update-bulk-telephony-credential" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-tag: string # Filter by tag, required by bulk operations. (required)
  --amount: int # Amount of credentials to be created. A single tag can hold at maximum 1000 credentials (e.g. 100)
  connection_id: string # Identifies the connection this credential is associated with. (e.g. 1234567890)
  --name: string # A default name for all credentials. (e.g. Default Credentials)
  tag: string # Tags a credential for bulk operations. A single tag can hold at maximum 1000 credentials. (e.g. My Credentials)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/actions/bulk/telephony_credentials"
    query: [{name: "filter[tag]", var: filter_tag, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: amount, var: amount}, {name: connection_id, var: connection_id}, {name: name, var: name}, {name: tag, var: tag}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    filter_tag: $filter_tag, amount: $amount, connection_id: $connection_id, name: $name, tag: $tag
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates several credentials
#
# POST /actions/bulk/telephony_credentials
# Returns: record<data: record<credentials: int>>
# operationId: CreateBulkTelephonyCredential
export def "create-bulk-telephony-credential" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --amount: int # Amount of credentials to be created. A single tag can hold at maximum 1000 credentials (e.g. 100)
  connection_id: string # Identifies the connection this credential is associated with. (e.g. 1234567890)
  --name: string # A default name for all credentials. (e.g. Default Credentials)
  tag: string # Tags a credential for bulk operations. A single tag can hold at maximum 1000 credentials. (e.g. My Credentials)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/actions/bulk/telephony_credentials"
    body: {content_type: "application/json", kind: json, fields: [{name: amount, var: amount}, {name: connection_id, var: connection_id}, {name: name, var: name}, {name: tag, var: tag}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    amount: $amount, connection_id: $connection_id, name: $name, tag: $tag
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Bulk Network Preferences for SIM cards
#
# PUT /actions/network_preferences/sim_cards
# Returns: record<data: table<created_at: string, mobile_operator_networks_preferences: list, ota_updates: list, record_type: string, sim_card_id: string, updated_at: string>, errors: table<code: string, detail: string, meta: record, source: record, title: string>>
# operationId: BulkSIMCardNetworkPreferences
export def "bulk-sim-card-network-preferences" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mobile-operator-networks-preferences: list # A list of mobile operator networks and the priority that should be applied when the SIM is connecting to the network. — item shape: {mobile_operator_network_id?: string, priority?: int}
  --sim-card-ids: list<string> # e.g. [6b14e151-8493-4fa1-8664-1cc4e6d14158, 6b14e151-8493-4fa1-8664-1cc4e6d14158]
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/actions/network_preferences/sim_cards"
    body: {content_type: "application/json", kind: json, fields: [{name: mobile_operator_networks_preferences, var: mobile_operator_networks_preferences}, {name: sim_card_ids, var: sim_card_ids}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    mobile_operator_networks_preferences: $mobile_operator_networks_preferences, sim_card_ids: $sim_card_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Register SIM cards
#
# POST /actions/register/sim_cards
# Returns: record<data: table<created_at: string, iccid: string, id: string, imsi: string, msisdn: string, record_type: string, sim_card_group_id: string, status: string, tags: list, updated_at: string>, errors: table<code: string, detail: string, meta: record, source: record, title: string>>
# operationId: SimCardRegister
export def "sim-card-register" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  registration_codes: list<string> # e.g. [0000000001, 0000000002, 0000000003]
  --sim-card-group-id: string # The group SIMCardGroup identification. This attribute can be null when it's present in an associated resource. (format: uuid, e.g. 6a09cdc3-8948-47f0-aa62-74ac943d6c58)
  --status: string@status-completer # Status on which the SIM card will be set after being successful registered. (default: enabled, e.g. standby)
  --tags: list<string> # Searchable tags associated with the SIM card (e.g. [personal, customers, active-customers])
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/actions/register/sim_cards"
    body: {content_type: "application/json", kind: json, fields: [{name: registration_codes, var: registration_codes}, {name: sim_card_group_id, var: sim_card_group_id}, {name: status, var: status}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    registration_codes: $registration_codes, sim_card_group_id: $sim_card_group_id, status: $status, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Perform activate or deactivate action on all credentials filtered by the provided tag.
#
# POST /actions/{action}/telephony_credentials
# Returns: record<data: record<credentials: int>>
# operationId: BulkCredentialAction
export def "bulk-credential-action" [
  action: string@action-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-tag: string # Filter by tag, required by bulk operations. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/actions/{action}/telephony_credentials"
    path_params: [{name: action, var: action}]
    query: [{name: "filter[tag]", var: filter_tag, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    action: $action, filter_tag: $filter_tag
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all addresses
#
# GET /addresses
# Returns: record<data: table<address_book: bool, administrative_area: string, borough: string, business_name: string, country_code: string, created_at: string, customer_reference: string, extended_address: string, first_name: string, id: string, last_name: string, locality: string, neighborhood: string, phone_number: string, postal_code: string, record_type: string, street_address: string, updated_at: string, validate_address: bool>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: findAddresss
export def "find-addresss" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
  --filter-customer-reference-eq: string # Filter addresses via the customer reference set. Matching is not case-sensitive.
  --filter-customer-reference-contains: string # If present, addresses with customer_reference containing the given value will be returned. Matching is not case-sensitive.
  --filter-used-as-emergency: string # If set as 'true', only addresses used as the emergency address for at least one active phone-number will be returned. When set to 'false', the opposite happens: only addresses not used as the emergency address from phone-numbers will be returned. (default: null)
  --filter-street-address-contains: string # If present, addresses with street_address containing the given value will be returned. Matching is not case-sensitive. Requires at least three characters. (default: null)
  --filter-address-book-eq: string # If present, only returns results with the address_book flag set to the given value. (default: null)
  --sort: string@sort-completer # Specifies the sort order for results. By default sorting direction is ascending. To have the results sorted in descending order add the - prefix. That is: street_address: sorts the result by the street_address field in ascending order. -street_address: sorts the result by the street_address field in descending order. If not given, results are sorted by created_at in descending order. (default: created_at, e.g. street_address)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/addresses"
    query: [{name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}, {name: "filter[customer_reference][eq]", var: filter_customer_reference_eq}, {name: "filter[customer_reference][contains]", var: filter_customer_reference_contains}, {name: "filter[used_as_emergency]", var: filter_used_as_emergency}, {name: "filter[street_address][contains]", var: filter_street_address_contains}, {name: "filter[address_book][eq]", var: filter_address_book_eq}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_number: $page_number, page_size: $page_size, filter_customer_reference_eq: $filter_customer_reference_eq, filter_customer_reference_contains: $filter_customer_reference_contains, filter_used_as_emergency: $filter_used_as_emergency, filter_street_address_contains: $filter_street_address_contains, filter_address_book_eq: $filter_address_book_eq, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an address
#
# POST /addresses
# Returns: record<data: record<address_book: bool, administrative_area: string, borough: string, business_name: string, country_code: string, created_at: string, customer_reference: string, extended_address: string, first_name: string, id: string, last_name: string, locality: string, neighborhood: string, phone_number: string, postal_code: string, record_type: string, street_address: string, updated_at: string, validate_address: bool>>
# operationId: CreateAddress
export def "create-address" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address-book: oneof<nothing, bool> # Indicates whether or not the address should be considered part of your list of addresses that appear for regular use. (default: true, e.g. false)
  --administrative-area: string # The locality of the address. For US addresses, this corresponds to the state of the address. (e.g. IL)
  --borough: string # The borough of the address. This field is not used for addresses in the US but is used for some international addresses. (e.g. Guadalajara)
  business_name: string # The business name associated with the address. An address must have either a first last name or a business name. (e.g. Toy-O'Kon)
  country_code: string # The two-character (ISO 3166-1 alpha-2) country code of the address. (e.g. US)
  --customer-reference: string # A customer reference string for customer look ups. (e.g. MY REF 001)
  --extended-address: string # Additional street address information about the address such as, but not limited to, unit number or apartment number. (e.g. #504)
  first_name: string # The first name associated with the address. An address must have either a first last name or a business name. (e.g. Alfred)
  last_name: string # The last name associated with the address. An address must have either a first last name or a business name. (e.g. Foster)
  locality: string # The locality of the address. For US addresses, this corresponds to the city of the address. (e.g. Chicago)
  --neighborhood: string # The neighborhood of the address. This field is not used for addresses in the US but is used for some international addresses. (e.g. Ciudad de los deportes)
  --phone-number: string # The phone number associated with the address. (e.g. +12125559000)
  --postal-code: string # The postal code of the address. (e.g. 60654)
  street_address: string # The primary street address information about the address. (e.g. 311 W Superior Street)
  --validate-address: oneof<nothing, bool> # Indicates whether or not the address should be validated for emergency use upon creation or not. This should be left with the default value of `true` unless you have used the `/addresses/actions/validate` endpoint to validate the address separately prior to creation. If an address is not validated for emergency use upon creation and it is not valid, it will not be able to be used for emergency services. (default: true, e.g. true)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/addresses"
    body: {content_type: "application/json", kind: json, fields: [{name: address_book, var: address_book}, {name: administrative_area, var: administrative_area}, {name: borough, var: borough}, {name: business_name, var: business_name}, {name: country_code, var: country_code}, {name: customer_reference, var: customer_reference}, {name: extended_address, var: extended_address}, {name: first_name, var: first_name}, {name: last_name, var: last_name}, {name: locality, var: locality}, {name: neighborhood, var: neighborhood}, {name: phone_number, var: phone_number}, {name: postal_code, var: postal_code}, {name: street_address, var: street_address}, {name: validate_address, var: validate_address}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    address_book: $address_book, administrative_area: $administrative_area, borough: $borough, business_name: $business_name, country_code: $country_code, customer_reference: $customer_reference, extended_address: $extended_address, first_name: $first_name, last_name: $last_name, locality: $locality, neighborhood: $neighborhood, phone_number: $phone_number, postal_code: $postal_code, street_address: $street_address, validate_address: $validate_address
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Validate an address
#
# POST /addresses/actions/validate
# Returns: record<data: record<errors: list<record>, record_type: string, result: string, suggested: record<administrative_area: string, country_code: string, extended_address: string, locality: string, postal_code: string, street_address: string>>>
# operationId: validateAddress
export def "validate-address" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --administrative-area: string # The locality of the address. For US addresses, this corresponds to the state of the address. (e.g. IL)
  country_code: string # The two-character (ISO 3166-1 alpha-2) country code of the address. (e.g. US)
  --extended-address: string # Additional street address information about the address such as, but not limited to, unit number or apartment number. (e.g. #504)
  --locality: string # The locality of the address. For US addresses, this corresponds to the city of the address. (e.g. Chicago)
  postal_code: string # The postal code of the address. (e.g. 60654)
  street_address: string # The primary street address information about the address. (e.g. 311 W Superior Street)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/addresses/actions/validate"
    body: {content_type: "application/json", kind: json, fields: [{name: administrative_area, var: administrative_area}, {name: country_code, var: country_code}, {name: extended_address, var: extended_address}, {name: locality, var: locality}, {name: postal_code, var: postal_code}, {name: street_address, var: street_address}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    administrative_area: $administrative_area, country_code: $country_code, extended_address: $extended_address, locality: $locality, postal_code: $postal_code, street_address: $street_address
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an address
#
# DELETE /addresses/{id}
# Returns: record<data: record<address_book: bool, administrative_area: string, borough: string, business_name: string, country_code: string, created_at: string, customer_reference: string, extended_address: string, first_name: string, id: string, last_name: string, locality: string, neighborhood: string, phone_number: string, postal_code: string, record_type: string, street_address: string, updated_at: string, validate_address: bool>>
# operationId: DeleteAddress
export def "delete-address" [
  id: string
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
    method: delete
    path: "/addresses/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an address
#
# GET /addresses/{id}
# Returns: record<data: record<address_book: bool, administrative_area: string, borough: string, business_name: string, country_code: string, created_at: string, customer_reference: string, extended_address: string, first_name: string, id: string, last_name: string, locality: string, neighborhood: string, phone_number: string, postal_code: string, record_type: string, street_address: string, updated_at: string, validate_address: bool>>
# operationId: getAddress
export def "get-address" [
  id: string
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
    path: "/addresses/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all SSO authentication providers
#
# GET /authentication_providers
# Returns: record<data: table<active: bool, created_at: string, id: string, name: string, organization_id: string, record_type: string, settings: record, short_name: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: findAuthenticationProviders
export def "find-authentication-providers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
  --sort: string@sort-completer-1 # Specifies the sort order for results. By default sorting direction is ascending. To have the results sorted in descending order add the - prefix. That is: name: sorts the result by the name field in ascending order. -name: sorts the result by the name field in descending order. If not given, results are sorted by created_at in descending order. (default: -created_at, e.g. name)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/authentication_providers"
    query: [{name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_number: $page_number, page_size: $page_size, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an authentication provider
#
# POST /authentication_providers
# Returns: record<data: record<active: bool, created_at: string, id: string, name: string, organization_id: string, record_type: string, settings: record<assertion_consumer_service_url: string, idp_cert_fingerprint: string, idp_cert_fingerprint_algorithm: string, idp_entity_id: string, idp_sso_target_url: string, name_identifier_format: string, service_provider_entity_id: string>, short_name: string, updated_at: string>>
# operationId: CreateAuthenticationProvider
export def "create-authentication-provider" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # The active status of the authentication provider (default: true, e.g. true)
  name: string # The name associated with the authentication provider. (e.g. Okta)
  settings: record # The settings associated with the authentication provider. — shape: {idp_cert_fingerprint: string, idp_cert_fingerprint_algorithm?: "sha1"|"sha256"|"sha384"|"sha512", idp_entity_id: string, idp_sso_target_url: string}
  --settings-url: string # The URL for the identity provider metadata file to populate the settings automatically. If the settings attribute is provided, that will be used instead. (e.g. https://myorg.myidp.com/saml/metadata)
  short_name: string # The short name associated with the authentication provider. This must be unique and URL-friendly, as it's going to be part of the login URL. (e.g. myorg)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/authentication_providers"
    body: {content_type: "application/json", kind: json, fields: [{name: active, var: active}, {name: name, var: name}, {name: settings, var: settings}, {name: settings_url, var: settings_url}, {name: short_name, var: short_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    active: $active, name: $name, settings: $settings, settings_url: $settings_url, short_name: $short_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an authentication provider
#
# DELETE /authentication_providers/{id}
# Returns: record<data: record<active: bool, created_at: string, id: string, name: string, organization_id: string, record_type: string, settings: record<assertion_consumer_service_url: string, idp_cert_fingerprint: string, idp_cert_fingerprint_algorithm: string, idp_entity_id: string, idp_sso_target_url: string, name_identifier_format: string, service_provider_entity_id: string>, short_name: string, updated_at: string>>
# operationId: DeleteAuthenticationProvider
export def "delete-authentication-provider" [
  id: string
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
    method: delete
    path: "/authentication_providers/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an authentication provider
#
# GET /authentication_providers/{id}
# Returns: record<data: record<active: bool, created_at: string, id: string, name: string, organization_id: string, record_type: string, settings: record<assertion_consumer_service_url: string, idp_cert_fingerprint: string, idp_cert_fingerprint_algorithm: string, idp_entity_id: string, idp_sso_target_url: string, name_identifier_format: string, service_provider_entity_id: string>, short_name: string, updated_at: string>>
# operationId: getAuthenticationProvider
export def "get-authentication-provider" [
  id: string
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
    path: "/authentication_providers/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a authentication provider
#
# PATCH /authentication_providers/{id}
# Returns: record<data: record<active: bool, created_at: string, id: string, name: string, organization_id: string, record_type: string, settings: record<assertion_consumer_service_url: string, idp_cert_fingerprint: string, idp_cert_fingerprint_algorithm: string, idp_entity_id: string, idp_sso_target_url: string, name_identifier_format: string, service_provider_entity_id: string>, short_name: string, updated_at: string>>
# operationId: updateAuthenticationProvider
export def "update-authentication-provider" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # The active status of the authentication provider (default: true, e.g. true)
  --name: string # The name associated with the authentication provider. (e.g. Okta)
  --settings: record # The settings associated with the authentication provider. — shape: {idp_cert_fingerprint: string, idp_cert_fingerprint_algorithm?: "sha1"|"sha256"|"sha384"|"sha512", idp_entity_id: string, idp_sso_target_url: string}
  --settings-url: string # The URL for the identity provider metadata file to populate the settings automatically. If the settings attribute is provided, that will be used instead. (e.g. https://myorg.myidp.com/saml/metadata)
  --short-name: string # The short name associated with the authentication provider. This must be unique and URL-friendly, as it's going to be part of the login URL. (e.g. myorg)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/authentication_providers/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: active, var: active}, {name: name, var: name}, {name: settings, var: settings}, {name: settings_url, var: settings_url}, {name: short_name, var: short_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, active: $active, name: $name, settings: $settings, settings_url: $settings_url, short_name: $short_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List available phone number blocks
#
# GET /available_phone_number_blocks
# Returns: record<data: table<cost_information: record, features: list, range: int, record_type: string, region_information: list, starting_number: string>, meta: record<best_effort_results: int, total_results: int>>
# operationId: listAvailablePhoneNumberBlocks
export def "list-available-phone-number-blocks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-phone-number-starts-with: string # Filter number blocks that start with a pattern (meant to be used after `national_destination_code` filter has been set). (e.g. 201)
  --filter-phone-number-ends-with: string # Filter numbers ending with a pattern. (e.g. 8000)
  --filter-phone-number-contains: string # Filter numbers containing a pattern. (e.g. 456)
  --filter-locality: string # Filter phone numbers by city.
  --filter-administrative-area: string # Filter phone numbers by US state/CA province. (e.g. IL)
  --filter-country-code: string # Filter phone numbers by ISO alpha-2 country code. (e.g. US)
  --filter-national-destination-code: string # Filter by the national destination code of the number. This filter is only applicable to North American numbers.
  --filter-rate-center: string # Filter phone numbers by NANP rate center. This filter is only applicable to North American numbers. (e.g. CHICAGO HEIGHTS)
  --filter-number-type: string@filter-number-type-completer # Filter phone numbers by number type. (e.g. toll-free)
  --filter-features: list<string> # Filter if the phone number should be used for voice, fax, mms, sms, emergency. (e.g. voice,sms)
  --filter-minimum-block-size: int # Filter number blocks by minimum blocks size (e.g. 100)
  --filter-limit: int # Limits the number of results. (e.g. 100)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/available_phone_number_blocks"
    query: [{name: "filter[phone_number][starts_with]", var: filter_phone_number_starts_with}, {name: "filter[phone_number][ends_with]", var: filter_phone_number_ends_with}, {name: "filter[phone_number][contains]", var: filter_phone_number_contains}, {name: "filter[locality]", var: filter_locality}, {name: "filter[administrative_area]", var: filter_administrative_area}, {name: "filter[country_code]", var: filter_country_code}, {name: "filter[national_destination_code]", var: filter_national_destination_code}, {name: "filter[rate_center]", var: filter_rate_center}, {name: "filter[number_type]", var: filter_number_type}, {name: "filter[features]", var: filter_features, style: multi}, {name: "filter[minimum_block_size]", var: filter_minimum_block_size}, {name: "filter[limit]", var: filter_limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter_phone_number_starts_with: $filter_phone_number_starts_with, filter_phone_number_ends_with: $filter_phone_number_ends_with, filter_phone_number_contains: $filter_phone_number_contains, filter_locality: $filter_locality, filter_administrative_area: $filter_administrative_area, filter_country_code: $filter_country_code, filter_national_destination_code: $filter_national_destination_code, filter_rate_center: $filter_rate_center, filter_number_type: $filter_number_type, filter_features: $filter_features, filter_minimum_block_size: $filter_minimum_block_size, filter_limit: $filter_limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List available phone numbers
#
# GET /available_phone_numbers
# Returns: record<data: table<best_effort: bool, cost_information: record, features: list, phone_number: string, quickship: bool, record_type: string, region_information: list, reservable: bool, vanity_format: string>, meta: record<best_effort_results: int, total_results: int>>
# operationId: listAvailablePhoneNumbers
export def "list-available-phone-numbers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-phone-number-starts-with: string # Filter numbers starting with a pattern (meant to be used after `national_destination_code` filter has been set).
  --filter-phone-number-ends-with: string # Filter numbers ending with a pattern.
  --filter-phone-number-contains: string # Filter numbers containing a pattern.
  --filter-locality: string # Filter phone numbers by city.
  --filter-administrative-area: string # Filter phone numbers by US state/CA province. (e.g. IL)
  --filter-country-code: string # Filter phone numbers by ISO alpha-2 country code. (e.g. US)
  --filter-national-destination-code: string # Filter by the national destination code of the number. This filter is only applicable to North American numbers.
  --filter-rate-center: string # Filter phone numbers by NANP rate center. This filter is only applicable to North American numbers. (e.g. CHICAGO HEIGHTS)
  --filter-number-type: string@filter-number-type-completer-1 # Filter phone numbers by number type. (e.g. local)
  --filter-features: list<string> # Filter if the phone number should be used for voice, fax, mms, sms, emergency. (e.g. voice,sms)
  --filter-limit: int # Limits the number of results. (e.g. 100)
  --filter-best-effort: oneof<nothing, bool> # Filter to determine if best effort results should be included. (e.g. false)
  --filter-quickship: oneof<nothing, bool> # Filter to exclude phone numbers that need additional time after to purchase to receive phone calls. (e.g. true)
  --filter-reservable: oneof<nothing, bool> # Filter to exclude phone numbers that cannot be reserved before purchase. (e.g. true)
  --filter-exclude-held-numbers: oneof<nothing, bool> # Filter to exclude phone numbers that are currently on hold for your account. (e.g. false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/available_phone_numbers"
    query: [{name: "filter[phone_number][starts_with]", var: filter_phone_number_starts_with}, {name: "filter[phone_number][ends_with]", var: filter_phone_number_ends_with}, {name: "filter[phone_number][contains]", var: filter_phone_number_contains}, {name: "filter[locality]", var: filter_locality}, {name: "filter[administrative_area]", var: filter_administrative_area}, {name: "filter[country_code]", var: filter_country_code}, {name: "filter[national_destination_code]", var: filter_national_destination_code}, {name: "filter[rate_center]", var: filter_rate_center}, {name: "filter[number_type]", var: filter_number_type}, {name: "filter[features]", var: filter_features, style: multi}, {name: "filter[limit]", var: filter_limit}, {name: "filter[best_effort]", var: filter_best_effort}, {name: "filter[quickship]", var: filter_quickship}, {name: "filter[reservable]", var: filter_reservable}, {name: "filter[exclude_held_numbers]", var: filter_exclude_held_numbers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter_phone_number_starts_with: $filter_phone_number_starts_with, filter_phone_number_ends_with: $filter_phone_number_ends_with, filter_phone_number_contains: $filter_phone_number_contains, filter_locality: $filter_locality, filter_administrative_area: $filter_administrative_area, filter_country_code: $filter_country_code, filter_national_destination_code: $filter_national_destination_code, filter_rate_center: $filter_rate_center, filter_number_type: $filter_number_type, filter_features: $filter_features, filter_limit: $filter_limit, filter_best_effort: $filter_best_effort, filter_quickship: $filter_quickship, filter_reservable: $filter_reservable, filter_exclude_held_numbers: $filter_exclude_held_numbers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve user balance details
#
# GET /balance
# Returns: record<data: record<available_credit: string, balance: string, credit_limit: string, currency: string, record_type: string>>
# operationId: getUserBalance
export def "get-user-balance" [
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
    path: "/balance"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all billing groups
#
# GET /billing_groups
# Returns: record<data: table<created_at: string, deleted_at: string, id: string, name: string, organization_id: string, record_type: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: listBillingGroups
export def "list-billing-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/billing_groups"
    query: [{name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_number: $page_number, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a billing group
#
# POST /billing_groups
# Returns: record<data: record<created_at: string, deleted_at: string, id: string, name: string, organization_id: string, record_type: string, updated_at: string>>
# operationId: createBillingGroup
export def "create-billing-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # A name for the billing group
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/billing_groups"
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a billing group
#
# DELETE /billing_groups/{id}
# Returns: record<data: record<created_at: string, deleted_at: string, id: string, name: string, organization_id: string, record_type: string, updated_at: string>>
# operationId: deleteBillingGroup
export def "delete-billing-group" [
  id: string
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
    method: delete
    path: "/billing_groups/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a billing group
#
# GET /billing_groups/{id}
# Returns: record<data: record<created_at: string, deleted_at: string, id: string, name: string, organization_id: string, record_type: string, updated_at: string>>
# operationId: retrieveBillingGroup
export def "retrieve-billing-group" [
  id: string
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
    path: "/billing_groups/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a billing group
#
# PATCH /billing_groups/{id}
# Returns: record<data: record<created_at: string, deleted_at: string, id: string, name: string, organization_id: string, record_type: string, updated_at: string>>
# operationId: updateBillingGroup
export def "update-billing-group" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # A name for the billing group
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/billing_groups/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List call control applications
#
# GET /call_control_applications
# Returns: record<data: table<active: bool, anchorsite_override: string, application_name: string, created_at: string, dtmf_type: string, first_command_timeout: bool, first_command_timeout_secs: int, id: string, inbound: record, outbound: record, record_type: string, updated_at: string, webhook_api_version: string, webhook_event_failover_url: string, webhook_event_url: string, webhook_timeout_secs: int>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: listCallControlApplications
export def "list-call-control-applications" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
  --filter-application-name-contains: string # If present, applications with application_name containing the given value will be returned. Matching is not case-sensitive. Requires at least three characters. (default: null)
  --filter-outbound-voice-profile-id: string # Identifies the associated outbound voice profile. (format: int64, e.g. 1293384261075731499)
  --sort: string@sort-completer-2 # Specifies the sort order for results. By default sorting direction is ascending. To have the results sorted in descending order add the - prefix. That is: connection_name: sorts the result by the connection_name field in ascending order. -connection_name: sorts the result by the connection_name field in descending order. If not given, results are sorted by created_at in descending order. (default: created_at, e.g. connection_name)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/call_control_applications"
    query: [{name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}, {name: "filter[application_name][contains]", var: filter_application_name_contains}, {name: "filter[outbound_voice_profile_id]", var: filter_outbound_voice_profile_id}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_number: $page_number, page_size: $page_size, filter_application_name_contains: $filter_application_name_contains, filter_outbound_voice_profile_id: $filter_outbound_voice_profile_id, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a call control application
#
# POST /call_control_applications
# Returns: record<data: record<active: bool, anchorsite_override: string, application_name: string, created_at: string, dtmf_type: string, first_command_timeout: bool, first_command_timeout_secs: int, id: string, inbound: record<channel_limit: int, sip_subdomain: string, sip_subdomain_receive_settings: string>, outbound: record<channel_limit: int, outbound_voice_profile_id: string>, record_type: string, updated_at: string, webhook_api_version: string, webhook_event_failover_url: string, webhook_event_url: string, webhook_timeout_secs: int>>
# operationId: createCallControlApplication
export def "create-call-control-application" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # Specifies whether the connection can be used. (default: true)
  --anchorsite-override: string@anchorsite-override-completer # Latency directs Telnyx to route media through the site with the lowest round-trip time to the user's connection. Telnyx calculates this time using ICMP ping messages. This can be disabled by specifying a site to handle all media. (default: "Latency", e.g. "Amsterdam, Netherlands")
  application_name: string # A user-assigned name to help manage the application. (e.g. call-router)
  --dtmf-type: string@dtmf-type-completer # Sets the type of DTMF digits sent from Telnyx to this Connection. Note that DTMF digits sent to Telnyx will be accepted in all formats. (default: RFC 2833, e.g. Inband)
  --first-command-timeout: oneof<nothing, bool> # Specifies whether calls to phone numbers associated with this connection should hangup after timing out. (default: false, e.g. true)
  --first-command-timeout-secs: int # Specifies how many seconds to wait before timing out a dial command. (default: 30, e.g. 10)
  --inbound: record # shape: {channel_limit?: int, sip_subdomain?: string, sip_subdomain_receive_settings?: "only_my_connections"|"from_anyone"}
  --outbound: record # shape: {channel_limit?: int, outbound_voice_profile_id?: string}
  --webhook-api-version: string@webhook-api-version-completer # Determines which webhook format will be used, Telnyx API v1 or v2. (default: 1, e.g. 1)
  --webhook-event-failover-url: string # The failover URL where webhooks related to this connection will be sent if sending to the primary URL fails. Must include a scheme, such as 'https'. (nullable, format: url, default: "", e.g. https://failover.example.com)
  webhook_event_url: string # The URL where webhooks related to this connection will be sent. Must include a scheme, such as 'https'. (format: url, e.g. https://example.com)
  --webhook-timeout-secs: int # Specifies how many seconds to wait before timing out a webhook. (nullable, e.g. 25)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/call_control_applications"
    body: {content_type: "application/json", kind: json, fields: [{name: active, var: active}, {name: anchorsite_override, var: anchorsite_override}, {name: application_name, var: application_name}, {name: dtmf_type, var: dtmf_type}, {name: first_command_timeout, var: first_command_timeout}, {name: first_command_timeout_secs, var: first_command_timeout_secs}, {name: inbound, var: inbound}, {name: outbound, var: outbound}, {name: webhook_api_version, var: webhook_api_version}, {name: webhook_event_failover_url, var: webhook_event_failover_url}, {name: webhook_event_url, var: webhook_event_url}, {name: webhook_timeout_secs, var: webhook_timeout_secs}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    active: $active, anchorsite_override: $anchorsite_override, application_name: $application_name, dtmf_type: $dtmf_type, first_command_timeout: $first_command_timeout, first_command_timeout_secs: $first_command_timeout_secs, inbound: $inbound, outbound: $outbound, webhook_api_version: $webhook_api_version, webhook_event_failover_url: $webhook_event_failover_url, webhook_event_url: $webhook_event_url, webhook_timeout_secs: $webhook_timeout_secs
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a call control application
#
# DELETE /call_control_applications/{id}
# Returns: record<data: record<active: bool, anchorsite_override: string, application_name: string, created_at: string, dtmf_type: string, first_command_timeout: bool, first_command_timeout_secs: int, id: string, inbound: record<channel_limit: int, sip_subdomain: string, sip_subdomain_receive_settings: string>, outbound: record<channel_limit: int, outbound_voice_profile_id: string>, record_type: string, updated_at: string, webhook_api_version: string, webhook_event_failover_url: string, webhook_event_url: string, webhook_timeout_secs: int>>
# operationId: deleteCallControlApplication
export def "delete-call-control-application" [
  id: string
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
    method: delete
    path: "/call_control_applications/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a call control application
#
# GET /call_control_applications/{id}
# Returns: record<data: record<active: bool, anchorsite_override: string, application_name: string, created_at: string, dtmf_type: string, first_command_timeout: bool, first_command_timeout_secs: int, id: string, inbound: record<channel_limit: int, sip_subdomain: string, sip_subdomain_receive_settings: string>, outbound: record<channel_limit: int, outbound_voice_profile_id: string>, record_type: string, updated_at: string, webhook_api_version: string, webhook_event_failover_url: string, webhook_event_url: string, webhook_timeout_secs: int>>
# operationId: retrieveCallControlApplication
export def "retrieve-call-control-application" [
  id: string
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
    path: "/call_control_applications/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a call control application
#
# PATCH /call_control_applications/{id}
# Returns: record<data: record<active: bool, anchorsite_override: string, application_name: string, created_at: string, dtmf_type: string, first_command_timeout: bool, first_command_timeout_secs: int, id: string, inbound: record<channel_limit: int, sip_subdomain: string, sip_subdomain_receive_settings: string>, outbound: record<channel_limit: int, outbound_voice_profile_id: string>, record_type: string, updated_at: string, webhook_api_version: string, webhook_event_failover_url: string, webhook_event_url: string, webhook_timeout_secs: int>>
# operationId: updateCallControlApplication
export def "update-call-control-application" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # Specifies whether the connection can be used. (default: true)
  --anchorsite-override: string@anchorsite-override-completer # Latency directs Telnyx to route media through the site with the lowest round-trip time to the user's connection. Telnyx calculates this time using ICMP ping messages. This can be disabled by specifying a site to handle all media. (default: "Latency", e.g. "Amsterdam, Netherlands")
  application_name: string # A user-assigned name to help manage the application. (e.g. call-router)
  --dtmf-type: string@dtmf-type-completer # Sets the type of DTMF digits sent from Telnyx to this Connection. Note that DTMF digits sent to Telnyx will be accepted in all formats. (default: RFC 2833, e.g. Inband)
  --first-command-timeout: oneof<nothing, bool> # Specifies whether calls to phone numbers associated with this connection should hangup after timing out. (default: false, e.g. true)
  --first-command-timeout-secs: int # Specifies how many seconds to wait before timing out a dial command. (default: 30, e.g. 10)
  --inbound: record # shape: {channel_limit?: int, sip_subdomain?: string, sip_subdomain_receive_settings?: "only_my_connections"|"from_anyone"}
  --outbound: record # shape: {channel_limit?: int, outbound_voice_profile_id?: string}
  --webhook-api-version: string@webhook-api-version-completer # Determines which webhook format will be used, Telnyx API v1 or v2. (default: 1, e.g. 1)
  --webhook-event-failover-url: string # The failover URL where webhooks related to this connection will be sent if sending to the primary URL fails. Must include a scheme, such as 'https'. (nullable, format: url, default: "", e.g. https://failover.example.com)
  webhook_event_url: string # The URL where webhooks related to this connection will be sent. Must include a scheme, such as 'https'. (format: url, e.g. https://example.com)
  --webhook-timeout-secs: int # Specifies how many seconds to wait before timing out a webhook. (nullable, e.g. 25)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/call_control_applications/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: active, var: active}, {name: anchorsite_override, var: anchorsite_override}, {name: application_name, var: application_name}, {name: dtmf_type, var: dtmf_type}, {name: first_command_timeout, var: first_command_timeout}, {name: first_command_timeout_secs, var: first_command_timeout_secs}, {name: inbound, var: inbound}, {name: outbound, var: outbound}, {name: webhook_api_version, var: webhook_api_version}, {name: webhook_event_failover_url, var: webhook_event_failover_url}, {name: webhook_event_url, var: webhook_event_url}, {name: webhook_timeout_secs, var: webhook_timeout_secs}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, active: $active, anchorsite_override: $anchorsite_override, application_name: $application_name, dtmf_type: $dtmf_type, first_command_timeout: $first_command_timeout, first_command_timeout_secs: $first_command_timeout_secs, inbound: $inbound, outbound: $outbound, webhook_api_version: $webhook_api_version, webhook_event_failover_url: $webhook_event_failover_url, webhook_event_url: $webhook_event_url, webhook_timeout_secs: $webhook_timeout_secs
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List call events
#
# GET /call_events
# Returns: record<data: table<call_leg_id: string, call_session_id: string, event_timestamp: string, metadata: record, name: string, record_type: string, type: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: listCallEvents
export def "list-call-events" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-call-leg-id: string # The unique identifier of an individual call leg. (format: uuid)
  --filter-call-session-id: string # The unique identifier of the call control session. A session may include multiple call leg events. (format: uuid)
  --filter-status: string@filter-status-completer # Event status (e.g. delivered)
  --filter-type: string@filter-type-completer # Event type (e.g. webhook)
  --filter-event-timestamp-gt: string # Event timestamp: greater than (e.g. 2019-03-29T11:10:00Z)
  --filter-event-timestamp-gte: string # Event timestamp: greater than or equal (e.g. 2019-03-29T11:10:00Z)
  --filter-event-timestamp-lt: string # Event timestamp: lower than (e.g. 2019-03-29T11:10:00Z)
  --filter-event-timestamp-lte: string # Event timestamp: lower than or equal (e.g. 2019-03-29T11:10:00Z)
  --filter-event-timestamp-eq: string # Event timestamp: equal (e.g. 2019-03-29T11:10:00Z)
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/call_events"
    query: [{name: "filter[call_leg_id]", var: filter_call_leg_id}, {name: "filter[call_session_id]", var: filter_call_session_id}, {name: "filter[status]", var: filter_status}, {name: "filter[type]", var: filter_type}, {name: "filter[event_timestamp][gt]", var: filter_event_timestamp_gt}, {name: "filter[event_timestamp][gte]", var: filter_event_timestamp_gte}, {name: "filter[event_timestamp][lt]", var: filter_event_timestamp_lt}, {name: "filter[event_timestamp][lte]", var: filter_event_timestamp_lte}, {name: "filter[event_timestamp][eq]", var: filter_event_timestamp_eq}, {name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter_call_leg_id: $filter_call_leg_id, filter_call_session_id: $filter_call_session_id, filter_status: $filter_status, filter_type: $filter_type, filter_event_timestamp_gt: $filter_event_timestamp_gt, filter_event_timestamp_gte: $filter_event_timestamp_gte, filter_event_timestamp_lt: $filter_event_timestamp_lt, filter_event_timestamp_lte: $filter_event_timestamp_lte, filter_event_timestamp_eq: $filter_event_timestamp_eq, page_number: $page_number, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Dial
#
# POST /calls
# Returns: record<data: record<call_control_id: string, call_leg_id: string, call_session_id: string, is_alive: bool, record_type: string>>
# operationId: callDial
export def "call-dial" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --answering-machine-detection: string@answering-machine-detection-completer # Enables Answering Machine Detection. When a call is answered, Telnyx runs real-time detection to determine if it was picked up by a human or a machine and sends an `call.machine.detection.ended` webhook with the analysis result. If 'greeting_end' or 'detect_words' is used and a 'machine' is detected, you will receive another 'call.machine.greeting.ended' webhook when the answering machine greeting ends with a beep or silence. If `detect_beep` is used, you will only receive 'call.machine.greeting.ended' if a beep is detected. (default: disabled)
  --answering-machine-detection-config: record # Optional configuration parameters to modify 'answering_machine_detection' performance. — shape: {after_greeting_silence_millis?: int, between_words_silence_millis?: int, greeting_duration_millis?: int, greeting_silence_duration_millis?: int, greeting_total_analysis_time_millis?: int, initial_silence_millis?: int, maximum_number_of_words?: int, maximum_word_length_millis?: int, silence_threshold?: int, total_analysis_time_millis?: int}
  --audio-url: string # The URL of a file to be played back to the callee when the call is answered. The URL can point to either a WAV or MP3 file. media_name and audio_url cannot be used together in one request. (e.g. http://example.com/message.wav)
  --billing-group-id: string # Use this field to set the Billing Group ID for the call. Must be a valid and existing Billing Group ID. (format: uuid, e.g. f5586561-8ff0-4291-a0ac-84fe544797bd)
  --client-state: string # Use this field to add state to every subsequent webhook. It must be a valid Base-64 encoded string. (e.g. aGF2ZSBhIG5pY2UgZGF5ID1d)
  --command-id: string # Use this field to avoid duplicate commands. Telnyx will ignore commands with the same `command_id`. (e.g. 891510ac-f3e4-11e8-af5b-de00688a4901)
  connection_id: string # The ID of the Call Control App (formerly ID of the connection) to be used when dialing the destination.
  --custom-headers: list # Custom headers to be added to the SIP INVITE. (e.g. [{name: head_1, value: val_1}, {name: head_2, value: val_2}]) — item shape: {name: string, value: string}
  from: string # The `from` number to be used as the caller id presented to the destination (`to` number). The number should be in +E164 format. This attribute will default to the `from` number of the original call if omitted. (e.g. +18005550101)
  --from-display-name: string # The `from_display_name` string to be used as the caller id name (SIP From Display Name) presented to the destination (`to` number). The string should have a maximum of 128 characters, containing only letters, numbers, spaces, and -_~!.+ special characters. If ommited, the display name will be the same as the number in the `from` field. (e.g. Company Name)
  --link-to: string # Use another call's control id for sharing the same call session id (e.g. ilditnZK_eVysupV21KzmzN_sM29ygfauQojpm4BgFtfX5hXAcjotg==)
  --media-name: string # The media_name of a file to be played back to the callee when the call is answered. The media_name must point to a file previously uploaded to api.telnyx.com/v2/media by the same user/organization. The file must either be a WAV or MP3 file. (e.g. my_media_uploaded_to_media_storage_api)
  --sip-auth-password: string # SIP Authentication password used for SIP challenges.
  --sip-auth-username: string # SIP Authentication username used for SIP challenges.
  --time-limit-secs: int # Sets the maximum duration of a Call Control Leg in seconds. If the time limit is reached, the call will hangup and a `call.hangup` webhook with a `hangup_cause` of `time_limit` will be sent. For example, by setting a time limit of 120 seconds, a Call Leg will be automatically terminated two minutes after being answered. The default time limit is 14400 seconds or 4 hours and this is also the maximum allowed call length. (format: int32, default: 14400, e.g. 600)
  --timeout-secs: int # The number of seconds that Telnyx will wait for the call to be answered by the destination to which it is being called. If the timeout is reached before an answer is received, the call will hangup and a `call.hangup` webhook with a `hangup_cause` of `timeout` will be sent. Minimum value is 5 seconds. Maximum value is 120 seconds. (format: int32, default: 30, e.g. 60)
  to: string # The DID or SIP URI to dial out to. (e.g. +18005550100 or sip:username@sip.telnyx.com)
  --webhook-url: string # Use this field to override the URL for which Telnyx will send subsequent webhooks to for this call. (e.g. https://www.example.com/server-b/)
  --webhook-url-method: string@webhook-url-method-completer # HTTP request type used for `webhook_url`. (default: POST, e.g. GET)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/calls"
    body: {content_type: "application/json", kind: json, fields: [{name: answering_machine_detection, var: answering_machine_detection}, {name: answering_machine_detection_config, var: answering_machine_detection_config}, {name: audio_url, var: audio_url}, {name: billing_group_id, var: billing_group_id}, {name: client_state, var: client_state}, {name: command_id, var: command_id}, {name: connection_id, var: connection_id}, {name: custom_headers, var: custom_headers}, {name: from, var: from}, {name: from_display_name, var: from_display_name}, {name: link_to, var: link_to}, {name: media_name, var: media_name}, {name: sip_auth_password, var: sip_auth_password}, {name: sip_auth_username, var: sip_auth_username}, {name: time_limit_secs, var: time_limit_secs}, {name: timeout_secs, var: timeout_secs}, {name: to, var: to}, {name: webhook_url, var: webhook_url}, {name: webhook_url_method, var: webhook_url_method}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    answering_machine_detection: $answering_machine_detection, answering_machine_detection_config: $answering_machine_detection_config, audio_url: $audio_url, billing_group_id: $billing_group_id, client_state: $client_state, command_id: $command_id, connection_id: $connection_id, custom_headers: $custom_headers, from: $from, from_display_name: $from_display_name, link_to: $link_to, media_name: $media_name, sip_auth_password: $sip_auth_password, sip_auth_username: $sip_auth_username, time_limit_secs: $time_limit_secs, timeout_secs: $timeout_secs, to: $to, webhook_url: $webhook_url, webhook_url_method: $webhook_url_method
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a call status
#
# GET /calls/{call_control_id}
# Returns: record<data: record<call_control_id: string, call_leg_id: string, call_session_id: string, is_alive: bool, record_type: string>>
# operationId: retrieveCallStatus
export def "retrieve-call-status" [
  call_control_id: string
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
    path: "/calls/{call_control_id}"
    path_params: [{name: call_control_id, var: call_control_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    call_control_id: $call_control_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Answer call
#
# POST /calls/{call_control_id}/actions/answer
# Returns: record<data: record<result: string>>
# operationId: callAnswer
export def "call-answer" [
  call_control_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --billing-group-id: string # Use this field to set the Billing Group ID for the call. Must be a valid and existing Billing Group ID. (format: uuid, e.g. f5586561-8ff0-4291-a0ac-84fe544797bd)
  --client-state: string # Use this field to add state to every subsequent webhook. It must be a valid Base-64 encoded string. (e.g. aGF2ZSBhIG5pY2UgZGF5ID1d)
  --command-id: string # Use this field to avoid duplicate commands. Telnyx will ignore commands with the same `command_id`. (e.g. 891510ac-f3e4-11e8-af5b-de00688a4901)
  --webhook-url: string # Use this field to override the URL for which Telnyx will send subsequent webhooks to for this call. (e.g. https://www.example.com/server-b/)
  --webhook-url-method: string@webhook-url-method-completer # HTTP request type used for `webhook_url`. (default: POST, e.g. GET)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/calls/{call_control_id}/actions/answer"
    path_params: [{name: call_control_id, var: call_control_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: billing_group_id, var: billing_group_id}, {name: client_state, var: client_state}, {name: command_id, var: command_id}, {name: webhook_url, var: webhook_url}, {name: webhook_url_method, var: webhook_url_method}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    call_control_id: $call_control_id, billing_group_id: $billing_group_id, client_state: $client_state, command_id: $command_id, webhook_url: $webhook_url, webhook_url_method: $webhook_url_method
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Bridge calls
#
# POST /calls/{call_control_id}/actions/bridge
# Returns: record<data: record<result: string>>
# operationId: callBridge
export def "call-bridge" [
  call_control_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-call-control-id: string # The Call Control ID of the call you want to bridge with. (e.g. v2:T02llQxIyaRkhfRKxgAP8nY511EhFLizdvdUKJiSw8d6A9BborherQ) (spec name: call_control_id)
  --client-state: string # Use this field to add state to every subsequent webhook. It must be a valid Base-64 encoded string. (e.g. aGF2ZSBhIG5pY2UgZGF5ID1d)
  --command-id: string # Use this field to avoid duplicate commands. Telnyx will ignore commands with the same `command_id`. (e.g. 891510ac-f3e4-11e8-af5b-de00688a4901)
  --park-after-unbridge: string # Specifies behavior after the bridge ends (i.e. the opposite leg either hangs up or is transferred). If supplied with the value `self`, the current leg will be parked after unbridge. If not set, the default behavior is to hang up the leg. (e.g. self)
  --queue: string # The name of the queue you want to bridge with, can't be used together with call_control_id parameter. Bridging with a queue means bridging with the first call in the queue. The call will always be removed from the queue regardless of whether bridging succeeds. Returns an error when the queue is empty. (e.g. support)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/calls/{call_control_id}/actions/bridge"
    path_params: [{name: call_control_id, var: call_control_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: call_control_id, var: body_call_control_id, required: true}, {name: client_state, var: client_state}, {name: command_id, var: command_id}, {name: park_after_unbridge, var: park_after_unbridge}, {name: queue, var: queue}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    call_control_id: $call_control_id, body_call_control_id: $body_call_control_id, client_state: $client_state, command_id: $command_id, park_after_unbridge: $park_after_unbridge, queue: $queue
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enqueue call
#
# POST /calls/{call_control_id}/actions/enqueue
# Returns: record<data: record<result: string>>
# operationId: callEnqueue
export def "call-enqueue" [
  call_control_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-state: string # Use this field to add state to every subsequent webhook. It must be a valid Base-64 encoded string. (e.g. aGF2ZSBhIG5pY2UgZGF5ID1d)
  --command-id: string # Use this field to avoid duplicate commands. Telnyx will ignore commands with the same `command_id`. (e.g. 891510ac-f3e4-11e8-af5b-de00688a4901)
  --max-size: int # The maximum number of calls allowed in the queue at a given time. Can't be modified for an existing queue. (default: 100, e.g. 200)
  --max-wait-time-secs: int # The number of seconds after which the call will be removed from the queue. (e.g. 600)
  --queue-name: string # The name of the queue the call should be put in. If a queue with a given name doesn't exist yet it will be created. (e.g. tier_1_support)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/calls/{call_control_id}/actions/enqueue"
    path_params: [{name: call_control_id, var: call_control_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: client_state, var: client_state}, {name: command_id, var: command_id}, {name: max_size, var: max_size}, {name: max_wait_time_secs, var: max_wait_time_secs}, {name: queue_name, var: queue_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    call_control_id: $call_control_id, client_state: $client_state, command_id: $command_id, max_size: $max_size, max_wait_time_secs: $max_wait_time_secs, queue_name: $queue_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Forking start
#
# POST /calls/{call_control_id}/actions/fork_start
# Returns: record<data: record<result: string>>
# operationId: callForkStart
export def "call-fork-start" [
  call_control_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-state: string # Use this field to add state to every subsequent webhook. It must be a valid Base-64 encoded string. (e.g. aGF2ZSBhIG5pY2UgZGF5ID1d)
  --command-id: string # Use this field to avoid duplicate commands. Telnyx will ignore commands with the same `command_id`. (e.g. 891510ac-f3e4-11e8-af5b-de00688a4901)
  --rx: string # The network target, <udp:ip_address:port>, where the call's incoming RTP media packets should be forwarded. (e.g. 192.0.2.1:9000)
  --stream-type: string@stream-type-completer # Optionally specify a media type to stream. If `decrpyted` selected, Telnyx will decrypt incoming SIP media before forking to the target. `rx` and `tx` are required fields if `decrypted` selected. (default: raw, e.g. decrypted)
  --target: string # The network target, <udp:ip_address:port>, where the call's RTP media packets should be forwarded. Both incoming and outgoing media packets will be delivered to the specified target, and information about the stream will be included in the encapsulation protocol header, including the direction (0 = inbound; 1 = outbound), leg (0 = A-leg; 1 = B-leg), and call_leg_id. (e.g. udp:192.0.2.1:9000)
  --tx: string # The network target, <udp:ip_address:port>, where the call's outgoing RTP media packets should be forwarded. (e.g. 192.0.2.1:9001)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/calls/{call_control_id}/actions/fork_start"
    path_params: [{name: call_control_id, var: call_control_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: client_state, var: client_state}, {name: command_id, var: command_id}, {name: rx, var: rx}, {name: stream_type, var: stream_type}, {name: target, var: target}, {name: tx, var: tx}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    call_control_id: $call_control_id, client_state: $client_state, command_id: $command_id, rx: $rx, stream_type: $stream_type, target: $target, tx: $tx
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Forking stop
#
# POST /calls/{call_control_id}/actions/fork_stop
# Returns: record<data: record<result: string>>
# operationId: callForkStop
export def "call-fork-stop" [
  call_control_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-state: string # Use this field to add state to every subsequent webhook. It must be a valid Base-64 encoded string. (e.g. aGF2ZSBhIG5pY2UgZGF5ID1d)
  --command-id: string # Use this field to avoid duplicate commands. Telnyx will ignore commands with the same `command_id`. (e.g. 891510ac-f3e4-11e8-af5b-de00688a4901)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/calls/{call_control_id}/actions/fork_stop"
    path_params: [{name: call_control_id, var: call_control_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: client_state, var: client_state}, {name: command_id, var: command_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    call_control_id: $call_control_id, client_state: $client_state, command_id: $command_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gather stop
#
# POST /calls/{call_control_id}/actions/gather_stop
# Returns: record<data: record<result: string>>
# operationId: callGatherStop
export def "call-gather-stop" [
  call_control_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-state: string # Use this field to add state to every subsequent webhook. It must be a valid Base-64 encoded string. (e.g. aGF2ZSBhIG5pY2UgZGF5ID1d)
  --command-id: string # Use this field to avoid duplicate commands. Telnyx will ignore commands with the same `command_id`. (e.g. 891510ac-f3e4-11e8-af5b-de00688a4901)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/calls/{call_control_id}/actions/gather_stop"
    path_params: [{name: call_control_id, var: call_control_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: client_state, var: client_state}, {name: command_id, var: command_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    call_control_id: $call_control_id, client_state: $client_state, command_id: $command_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gather using audio
#
# POST /calls/{call_control_id}/actions/gather_using_audio
# Returns: record<data: record<result: string>>
# operationId: callGatherUsingAudio
export def "call-gather-using-audio" [
  call_control_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --audio-url: string # The URL of a file to be played back at the beginning of each prompt. The URL can point to either a WAV or MP3 file. media_name and audio_url cannot be used together in one request. (e.g. http://example.com/message.wav)
  --client-state: string # Use this field to add state to every subsequent webhook. It must be a valid Base-64 encoded string. (e.g. aGF2ZSBhIG5pY2UgZGF5ID1d)
  --command-id: string # Use this field to avoid duplicate commands. Telnyx will ignore commands with the same `command_id`. (e.g. 891510ac-f3e4-11e8-af5b-de00688a4901)
  --inter-digit-timeout-millis: int # The number of milliseconds to wait for input between digits. (format: int32, default: 5000, e.g. 10000)
  --invalid-audio-url: string # The URL of a file to play when digits don't match the `valid_digits` parameter or the number of digits is not between `min` and `max`. The URL can point to either a WAV or MP3 file. invalid_media_name and invalid_audio_url cannot be used together in one request. (e.g. http://example.com/invalid.wav)
  --invalid-media-name: string # The media_name of a file to be played back when digits don't match the `valid_digits` parameter or the number of digits is not between `min` and `max`. The media_name must point to a file previously uploaded to api.telnyx.com/v2/media by the same user/organization. The file must either be a WAV or MP3 file. (e.g. my_media_uploaded_to_media_storage_api)
  --maximum-digits: int # The maximum number of digits to fetch. This parameter has a maximum value of 128. (format: int32, default: 128, e.g. 10)
  --maximum-tries: int # The maximum number of times the file should be played if there is no input from the user on the call. (format: int32, default: 3, e.g. 3)
  --media-name: string # The media_name of a file to be played back at the beginning of each prompt. The media_name must point to a file previously uploaded to api.telnyx.com/v2/media by the same user/organization. The file must either be a WAV or MP3 file. (e.g. my_media_uploaded_to_media_storage_api)
  --minimum-digits: int # The minimum number of digits to fetch. This parameter has a minimum value of 1. (format: int32, default: 1, e.g. 1)
  --terminating-digit: string # The digit used to terminate input if fewer than `maximum_digits` digits have been gathered. (default: #, e.g. #)
  --timeout-millis: int # The number of milliseconds to wait for a DTMF response after file playback ends before a replaying the sound file. (format: int32, default: 60000, e.g. 60000)
  --valid-digits: string # A list of all digits accepted as valid. (default: 0123456789#*, e.g. 123)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/calls/{call_control_id}/actions/gather_using_audio"
    path_params: [{name: call_control_id, var: call_control_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: audio_url, var: audio_url}, {name: client_state, var: client_state}, {name: command_id, var: command_id}, {name: inter_digit_timeout_millis, var: inter_digit_timeout_millis}, {name: invalid_audio_url, var: invalid_audio_url}, {name: invalid_media_name, var: invalid_media_name}, {name: maximum_digits, var: maximum_digits}, {name: maximum_tries, var: maximum_tries}, {name: media_name, var: media_name}, {name: minimum_digits, var: minimum_digits}, {name: terminating_digit, var: terminating_digit}, {name: timeout_millis, var: timeout_millis}, {name: valid_digits, var: valid_digits}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    call_control_id: $call_control_id, audio_url: $audio_url, client_state: $client_state, command_id: $command_id, inter_digit_timeout_millis: $inter_digit_timeout_millis, invalid_audio_url: $invalid_audio_url, invalid_media_name: $invalid_media_name, maximum_digits: $maximum_digits, maximum_tries: $maximum_tries, media_name: $media_name, minimum_digits: $minimum_digits, terminating_digit: $terminating_digit, timeout_millis: $timeout_millis, valid_digits: $valid_digits
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gather using speak
#
# POST /calls/{call_control_id}/actions/gather_using_speak
# Returns: record<data: record<result: string>>
# operationId: callGatherUsingSpeak
export def "call-gather-using-speak" [
  call_control_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-state: string # Use this field to add state to every subsequent webhook. It must be a valid Base-64 encoded string. (e.g. aGF2ZSBhIG5pY2UgZGF5ID1d)
  --command-id: string # Use this field to avoid duplicate commands. Telnyx will ignore commands with the same `command_id`. (e.g. 891510ac-f3e4-11e8-af5b-de00688a4901)
  --inter-digit-timeout-millis: int # The number of milliseconds to wait for input between digits. (format: int32, default: 5000, e.g. 10000)
  --invalid-payload: string # The text or SSML to be converted into speech when digits don't match the `valid_digits` parameter or the number of digits is not between `min` and `max`. There is a 5,000 character limit. (e.g. Say this on the call)
  language: string@language-completer # The language you want spoken. (e.g. en-US)
  --maximum-digits: int # The maximum number of digits to fetch. This parameter has a maximum value of 128. (format: int32, default: 128, e.g. 10)
  --maximum-tries: int # The maximum number of times that a file should be played back if there is no input from the user on the call. (format: int32, default: 3, e.g. 3)
  --minimum-digits: int # The minimum number of digits to fetch. This parameter has a minimum value of 1. (format: int32, default: 1, e.g. 1)
  payload: string # The text or SSML to be converted into speech. There is a 5,000 character limit. (e.g. Say this on the call)
  --payload-type: string@payload-type-completer # The type of the provided payload. The payload can either be plain text, or Speech Synthesis Markup Language (SSML). (default: text, e.g. ssml)
  --service-level: string@service-level-completer # This parameter impacts speech quality, language options and payload types. When using `basic`, only the `en-US` language and payload type `text` are allowed. (default: premium, e.g. premium)
  --terminating-digit: string # The digit used to terminate input if fewer than `maximum_digits` digits have been gathered. (default: #, e.g. #)
  --timeout-millis: int # The number of milliseconds to wait for a DTMF response after speak ends before a replaying the sound file. (format: int32, default: 60000, e.g. 60000)
  --valid-digits: string # A list of all digits accepted as valid. (default: 0123456789#*, e.g. 123)
  voice: string@voice-completer # The gender of the voice used to speak back the text. (e.g. female)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/calls/{call_control_id}/actions/gather_using_speak"
    path_params: [{name: call_control_id, var: call_control_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: client_state, var: client_state}, {name: command_id, var: command_id}, {name: inter_digit_timeout_millis, var: inter_digit_timeout_millis}, {name: invalid_payload, var: invalid_payload}, {name: language, var: language}, {name: maximum_digits, var: maximum_digits}, {name: maximum_tries, var: maximum_tries}, {name: minimum_digits, var: minimum_digits}, {name: payload, var: payload}, {name: payload_type, var: payload_type}, {name: service_level, var: service_level}, {name: terminating_digit, var: terminating_digit}, {name: timeout_millis, var: timeout_millis}, {name: valid_digits, var: valid_digits}, {name: voice, var: voice}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    call_control_id: $call_control_id, client_state: $client_state, command_id: $command_id, inter_digit_timeout_millis: $inter_digit_timeout_millis, invalid_payload: $invalid_payload, language: $language, maximum_digits: $maximum_digits, maximum_tries: $maximum_tries, minimum_digits: $minimum_digits, payload: $payload, payload_type: $payload_type, service_level: $service_level, terminating_digit: $terminating_digit, timeout_millis: $timeout_millis, valid_digits: $valid_digits, voice: $voice
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Hangup call
#
# POST /calls/{call_control_id}/actions/hangup
# Returns: record<data: record<result: string>>
# operationId: callHangup
export def "call-hangup" [
  call_control_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-state: string # Use this field to add state to every subsequent webhook. It must be a valid Base-64 encoded string. (e.g. aGF2ZSBhIG5pY2UgZGF5ID1d)
  --command-id: string # Use this field to avoid duplicate commands. Telnyx will ignore commands with the same `command_id`. (e.g. 891510ac-f3e4-11e8-af5b-de00688a4901)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/calls/{call_control_id}/actions/hangup"
    path_params: [{name: call_control_id, var: call_control_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: client_state, var: client_state}, {name: command_id, var: command_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    call_control_id: $call_control_id, client_state: $client_state, command_id: $command_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove call from a queue
#
# POST /calls/{call_control_id}/actions/leave_queue
# Returns: record<data: record<result: string>>
# operationId: leaveQueue
export def "leave-queue" [
  call_control_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-state: string # Use this field to add state to every subsequent webhook. It must be a valid Base-64 encoded string. (e.g. aGF2ZSBhIG5pY2UgZGF5ID1d)
  --command-id: string # Use this field to avoid duplicate commands. Telnyx will ignore commands with the same `command_id`. (e.g. 891510ac-f3e4-11e8-af5b-de00688a4901)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/calls/{call_control_id}/actions/leave_queue"
    path_params: [{name: call_control_id, var: call_control_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: client_state, var: client_state}, {name: command_id, var: command_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    call_control_id: $call_control_id, client_state: $client_state, command_id: $command_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Play audio URL
#
# POST /calls/{call_control_id}/actions/playback_start
# Returns: record<data: record<result: string>>
# operationId: callPlaybackStart
export def "call-playback-start" [
  call_control_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --audio-url: string # The URL of a file to be played back on the call. The URL can point to either a WAV or MP3 file. media_name and audio_url cannot be used together in one request. (e.g. http://example.com/message.wav)
  --client-state: string # Use this field to add state to every subsequent webhook. It must be a valid Base-64 encoded string. (e.g. aGF2ZSBhIG5pY2UgZGF5ID1d)
  --command-id: string # Use this field to avoid duplicate commands. Telnyx will ignore commands with the same `command_id`. (e.g. 891510ac-f3e4-11e8-af5b-de00688a4901)
  --loop: any
  --media-name: string # The media_name of a file to be played back on the call. The media_name must point to a file previously uploaded to api.telnyx.com/v2/media by the same user/organization. The file must either be a WAV or MP3 file. (e.g. my_media_uploaded_to_media_storage_api)
  --overlay: oneof<nothing, bool> # When enabled, audio will be mixed on top of any other audio that is actively being played back. Note that `overlay: true` will only work if there is another audio file already being played on the call. (default: false, e.g. true)
  --stop: string # When specified, it stops the current audio being played. Specify `current` to stop the current audio being played, and to play the next file in the queue. Specify `all` to stop the current audio file being played and to also clear all audio files from the queue. (default: all, e.g. current)
  --target-legs: string # Specifies the leg or legs on which audio will be played. If supplied, the value must be either `self`, `opposite` or `both`. (default: self, e.g. self)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/calls/{call_control_id}/actions/playback_start"
    path_params: [{name: call_control_id, var: call_control_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: audio_url, var: audio_url}, {name: client_state, var: client_state}, {name: command_id, var: command_id}, {name: loop, var: loop}, {name: media_name, var: media_name}, {name: overlay, var: overlay}, {name: stop, var: stop}, {name: target_legs, var: target_legs}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    call_control_id: $call_control_id, audio_url: $audio_url, client_state: $client_state, command_id: $command_id, loop: $loop, media_name: $media_name, overlay: $overlay, stop: $stop, target_legs: $target_legs
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stop audio playback
#
# POST /calls/{call_control_id}/actions/playback_stop
# Returns: record<data: record<result: string>>
# operationId: callPlaybackStop
export def "call-playback-stop" [
  call_control_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-state: string # Use this field to add state to every subsequent webhook. It must be a valid Base-64 encoded string. (e.g. aGF2ZSBhIG5pY2UgZGF5ID1d)
  --command-id: string # Use this field to avoid duplicate commands. Telnyx will ignore commands with the same `command_id`. (e.g. 891510ac-f3e4-11e8-af5b-de00688a4901)
  --stop: string # Use `current` to stop only the current audio or `all` to stop all audios in the queue. (default: all, e.g. current)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/calls/{call_control_id}/actions/playback_stop"
    path_params: [{name: call_control_id, var: call_control_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: client_state, var: client_state}, {name: command_id, var: command_id}, {name: stop, var: stop}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    call_control_id: $call_control_id, client_state: $client_state, command_id: $command_id, stop: $stop
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Record pause
#
# POST /calls/{call_control_id}/actions/record_pause
# Returns: record<data: record<result: string>>
# operationId: callRecordPause
export def "call-record-pause" [
  call_control_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-state: string # Use this field to add state to every subsequent webhook. It must be a valid Base-64 encoded string. (e.g. aGF2ZSBhIG5pY2UgZGF5ID1d)
  --command-id: string # Use this field to avoid duplicate commands. Telnyx will ignore commands with the same `command_id`. (e.g. 891510ac-f3e4-11e8-af5b-de00688a4901)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/calls/{call_control_id}/actions/record_pause"
    path_params: [{name: call_control_id, var: call_control_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: client_state, var: client_state}, {name: command_id, var: command_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    call_control_id: $call_control_id, client_state: $client_state, command_id: $command_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Record resume
#
# POST /calls/{call_control_id}/actions/record_resume
# Returns: record<data: record<result: string>>
# operationId: callRecordResume
export def "call-record-resume" [
  call_control_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-state: string # Use this field to add state to every subsequent webhook. It must be a valid Base-64 encoded string. (e.g. aGF2ZSBhIG5pY2UgZGF5ID1d)
  --command-id: string # Use this field to avoid duplicate commands. Telnyx will ignore commands with the same `command_id`. (e.g. 891510ac-f3e4-11e8-af5b-de00688a4901)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/calls/{call_control_id}/actions/record_resume"
    path_params: [{name: call_control_id, var: call_control_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: client_state, var: client_state}, {name: command_id, var: command_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    call_control_id: $call_control_id, client_state: $client_state, command_id: $command_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Recording start
#
# POST /calls/{call_control_id}/actions/record_start
# Returns: record<data: record<result: string>>
# operationId: callRecordStart
export def "call-record-start" [
  call_control_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  channels: string@channels-completer # When `dual`, final audio file will be stereo recorded with the first leg on channel A, and the rest on channel B. (e.g. single)
  --client-state: string # Use this field to add state to every subsequent webhook. It must be a valid Base-64 encoded string. (e.g. aGF2ZSBhIG5pY2UgZGF5ID1d)
  --command-id: string # Use this field to avoid duplicate commands. Telnyx will ignore commands with the same `command_id`. (e.g. 891510ac-f3e4-11e8-af5b-de00688a4901)
  format: string@format-completer # The audio file format used when storing the call recording. Can be either `mp3` or `wav`. (e.g. mp3)
  --max-length: int # Defines the maximum length for the recording in seconds. Minimum value is 0. Maximum value is 14400. Default is 0 (infinite) (format: int32, default: 0, e.g. 100)
  --play-beep: oneof<nothing, bool> # If enabled, a beep sound will be played at the start of a recording. (e.g. true)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/calls/{call_control_id}/actions/record_start"
    path_params: [{name: call_control_id, var: call_control_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: channels, var: channels}, {name: client_state, var: client_state}, {name: command_id, var: command_id}, {name: format, var: format}, {name: max_length, var: max_length}, {name: play_beep, var: play_beep}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    call_control_id: $call_control_id, channels: $channels, client_state: $client_state, command_id: $command_id, format: $format, max_length: $max_length, play_beep: $play_beep
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Recording stop
#
# POST /calls/{call_control_id}/actions/record_stop
# Returns: record<data: record<result: string>>
# operationId: callRecordStop
export def "call-record-stop" [
  call_control_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-state: string # Use this field to add state to every subsequent webhook. It must be a valid Base-64 encoded string. (e.g. aGF2ZSBhIG5pY2UgZGF5ID1d)
  --command-id: string # Use this field to avoid duplicate commands. Telnyx will ignore commands with the same `command_id`. (e.g. 891510ac-f3e4-11e8-af5b-de00688a4901)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/calls/{call_control_id}/actions/record_stop"
    path_params: [{name: call_control_id, var: call_control_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: client_state, var: client_state}, {name: command_id, var: command_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    call_control_id: $call_control_id, client_state: $client_state, command_id: $command_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# SIP Refer a call
#
# POST /calls/{call_control_id}/actions/refer
# Returns: record<data: record<result: string>>
# operationId: callRefer
export def "call-refer" [
  call_control_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-state: string # Use this field to add state to every subsequent webhook. It must be a valid Base-64 encoded string. (e.g. aGF2ZSBhIG5pY2UgZGF5ID1d)
  --command-id: string # Use this field to avoid execution of duplicate commands. Telnyx will ignore subsequent commands with the same `command_id` as one that has already been executed. (e.g. 891510ac-f3e4-11e8-af5b-de00688a4901)
  --custom-headers: list # Custom headers to be added to the SIP INVITE. (e.g. [{name: head_1, value: val_1}, {name: head_2, value: val_2}]) — item shape: {name: string, value: string}
  sip_address: string # The SIP URI to which the call will be referred to. (e.g. sip:username@sip.non-telnyx-address.com)
  --sip-auth-password: string # SIP Authentication password used for SIP challenges.
  --sip-auth-username: string # SIP Authentication username used for SIP challenges.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/calls/{call_control_id}/actions/refer"
    path_params: [{name: call_control_id, var: call_control_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: client_state, var: client_state}, {name: command_id, var: command_id}, {name: custom_headers, var: custom_headers}, {name: sip_address, var: sip_address}, {name: sip_auth_password, var: sip_auth_password}, {name: sip_auth_username, var: sip_auth_username}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    call_control_id: $call_control_id, client_state: $client_state, command_id: $command_id, custom_headers: $custom_headers, sip_address: $sip_address, sip_auth_password: $sip_auth_password, sip_auth_username: $sip_auth_username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reject a call
#
# POST /calls/{call_control_id}/actions/reject
# Returns: record<data: record<result: string>>
# operationId: callReject
export def "call-reject" [
  call_control_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  cause: string@cause-completer # Cause for call rejection. (e.g. USER_BUSY)
  --client-state: string # Use this field to add state to every subsequent webhook. It must be a valid Base-64 encoded string. (e.g. aGF2ZSBhIG5pY2UgZGF5ID1d)
  --command-id: string # Use this field to avoid duplicate commands. Telnyx will ignore commands with the same `command_id`. (e.g. 891510ac-f3e4-11e8-af5b-de00688a4901)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/calls/{call_control_id}/actions/reject"
    path_params: [{name: call_control_id, var: call_control_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: cause, var: cause}, {name: client_state, var: client_state}, {name: command_id, var: command_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    call_control_id: $call_control_id, cause: $cause, client_state: $client_state, command_id: $command_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send DTMF
#
# POST /calls/{call_control_id}/actions/send_dtmf
# Returns: record<data: record<result: string>>
# operationId: callSendDTMF
export def "call-send-dtmf" [
  call_control_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-state: string # Use this field to add state to every subsequent webhook. It must be a valid Base-64 encoded string. (e.g. aGF2ZSBhIG5pY2UgZGF5ID1d)
  --command-id: string # Use this field to avoid duplicate commands. Telnyx will ignore commands with the same `command_id`. (e.g. 891510ac-f3e4-11e8-af5b-de00688a4901)
  digits: string # DTMF digits to send. Valid digits are 0-9, A-D, *, and #. Pauses can be added using w (0.5s) and W (1s). (e.g. 1www2WABCDw9)
  --duration-millis: int # Specifies for how many milliseconds each digit will be played in the audio stream. Ranges from 100 to 500ms (format: int32, default: 250, e.g. 500)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/calls/{call_control_id}/actions/send_dtmf"
    path_params: [{name: call_control_id, var: call_control_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: client_state, var: client_state}, {name: command_id, var: command_id}, {name: digits, var: digits}, {name: duration_millis, var: duration_millis}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    call_control_id: $call_control_id, client_state: $client_state, command_id: $command_id, digits: $digits, duration_millis: $duration_millis
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Speak text
#
# POST /calls/{call_control_id}/actions/speak
# Returns: record<data: record<result: string>>
# operationId: callSpeak
export def "call-speak" [
  call_control_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-state: string # Use this field to add state to every subsequent webhook. It must be a valid Base-64 encoded string. (e.g. aGF2ZSBhIG5pY2UgZGF5ID1d)
  --command-id: string # Use this field to avoid duplicate commands. Telnyx will ignore commands with the same `command_id`. (e.g. 891510ac-f3e4-11e8-af5b-de00688a4901)
  language: string@language-completer # The language you want spoken. (e.g. en-US)
  payload: string # The text or SSML to be converted into speech. There is a 5,000 character limit. (e.g. Say this on the call)
  --payload-type: string@payload-type-completer # The type of the provided payload. The payload can either be plain text, or Speech Synthesis Markup Language (SSML). (default: text, e.g. ssml)
  --service-level: string@service-level-completer # This parameter impacts speech quality, language options and payload types. When using `basic`, only the `en-US` language and payload type `text` are allowed. (default: premium, e.g. premium)
  --stop: string # When specified, it stops the current audio being played. Specify `current` to stop the current audio being played, and to play the next file in the queue. Specify `all` to stop the current audio file being played and to also clear all audio files from the queue. (e.g. current)
  voice: string@voice-completer # The gender of the voice used to speak back the text. (e.g. female)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/calls/{call_control_id}/actions/speak"
    path_params: [{name: call_control_id, var: call_control_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: client_state, var: client_state}, {name: command_id, var: command_id}, {name: language, var: language}, {name: payload, var: payload}, {name: payload_type, var: payload_type}, {name: service_level, var: service_level}, {name: stop, var: stop}, {name: voice, var: voice}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    call_control_id: $call_control_id, client_state: $client_state, command_id: $command_id, language: $language, payload: $payload, payload_type: $payload_type, service_level: $service_level, stop: $stop, voice: $voice
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Transcription start
#
# POST /calls/{call_control_id}/actions/transcription_start
# Returns: record<data: record<result: string>>
# operationId: callTranscriptionStart
export def "call-transcription-start" [
  call_control_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-state: string # Use this field to add state to every subsequent webhook. It must be a valid Base-64 encoded string. (e.g. aGF2ZSBhIG5pY2UgZGF5ID1d)
  --command-id: string # Use this field to avoid duplicate commands. Telnyx will ignore commands with the same `command_id`. (e.g. 891510ac-f3e4-11e8-af5b-de00688a4901)
  --language: string@language-completer-1 # Language to use for speech recognition (default: en, e.g. en)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/calls/{call_control_id}/actions/transcription_start"
    path_params: [{name: call_control_id, var: call_control_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: client_state, var: client_state}, {name: command_id, var: command_id}, {name: language, var: language}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    call_control_id: $call_control_id, client_state: $client_state, command_id: $command_id, language: $language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Transcription stop
#
# POST /calls/{call_control_id}/actions/transcription_stop
# Returns: record<data: record<result: string>>
# operationId: callTranscriptionStop
export def "call-transcription-stop" [
  call_control_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-state: string # Use this field to add state to every subsequent webhook. It must be a valid Base-64 encoded string. (e.g. aGF2ZSBhIG5pY2UgZGF5ID1d)
  --command-id: string # Use this field to avoid duplicate commands. Telnyx will ignore commands with the same `command_id`. (e.g. 891510ac-f3e4-11e8-af5b-de00688a4901)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/calls/{call_control_id}/actions/transcription_stop"
    path_params: [{name: call_control_id, var: call_control_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: client_state, var: client_state}, {name: command_id, var: command_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    call_control_id: $call_control_id, client_state: $client_state, command_id: $command_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Transfer call
#
# POST /calls/{call_control_id}/actions/transfer
# Returns: record<data: record<result: string>>
# operationId: callTransfer
export def "call-transfer" [
  call_control_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --answering-machine-detection: string@answering-machine-detection-completer # Enables Answering Machine Detection. When a call is answered, Telnyx runs real-time detection to determine if it was picked up by a human or a machine and sends an `call.machine.detection.ended` webhook with the analysis result. If 'greeting_end' or 'detect_words' is used and a 'machine' is detected, you will receive another 'call.machine.greeting.ended' webhook when the answering machine greeting ends with a beep or silence. If `detect_beep` is used, you will only receive 'call.machine.greeting.ended' if a beep is detected. (default: disabled)
  --answering-machine-detection-config: record # Optional configuration parameters to modify 'answering_machine_detection' performance. — shape: {after_greeting_silence_millis?: int, between_words_silence_millis?: int, greeting_duration_millis?: int, greeting_silence_duration_millis?: int, greeting_total_analysis_time_millis?: int, initial_silence_millis?: int, maximum_number_of_words?: int, maximum_word_length_millis?: int, silence_threshold?: int, total_analysis_time_millis?: int}
  --audio-url: string # The URL of a file to be played back when the transfer destination answers before bridging the call. The URL can point to either a WAV or MP3 file. media_name and audio_url cannot be used together in one request. (e.g. http://example.com/message.wav)
  --client-state: string # Use this field to add state to every subsequent webhook. It must be a valid Base-64 encoded string. (e.g. aGF2ZSBhIG5pY2UgZGF5ID1d)
  --command-id: string # Use this field to avoid duplicate commands. Telnyx will ignore commands with the same `command_id`. (e.g. 891510ac-f3e4-11e8-af5b-de00688a4901)
  --custom-headers: list # Custom headers to be added to the SIP INVITE. (e.g. [{name: head_1, value: val_1}, {name: head_2, value: val_2}]) — item shape: {name: string, value: string}
  --from: string # The `from` number to be used as the caller id presented to the destination (`to` number). The number should be in +E164 format. This attribute will default to the `from` number of the original call if omitted. (e.g. +18005550101)
  --from-display-name: string # The `from_display_name` string to be used as the caller id name (SIP From Display Name) presented to the destination (`to` number). The string should have a maximum of 128 characters, containing only letters, numbers, spaces, and -_~!.+ special characters. If ommited, the display name will be the same as the number in the `from` field. (e.g. Company Name)
  --media-name: string # The media_name of a file to be played back when the transfer destination answers before bridging the call. The media_name must point to a file previously uploaded to api.telnyx.com/v2/media by the same user/organization. The file must either be a WAV or MP3 file. (e.g. my_media_uploaded_to_media_storage_api)
  --sip-auth-password: string # SIP Authentication password used for SIP challenges. (e.g. password)
  --sip-auth-username: string # SIP Authentication username used for SIP challenges. (e.g. username)
  --target-leg-client-state: string # Use this field to add state to every subsequent webhook for the new leg. It must be a valid Base-64 encoded string. (e.g. aGF2ZSBhIG5pY2UgZGF5ID1d)
  --time-limit-secs: int # Sets the maximum duration of a Call Control Leg in seconds. If the time limit is reached, the call will hangup and a `call.hangup` webhook with a `hangup_cause` of `time_limit` will be sent. For example, by setting a time limit of 120 seconds, a Call Leg will be automatically terminated two minutes after being answered. The default time limit is 14400 seconds or 4 hours and this is also the maximum allowed call length. (format: int32, default: 14400, e.g. 600)
  --timeout-secs: int # The number of seconds that Telnyx will wait for the call to be answered by the destination to which it is being transferred. If the timeout is reached before an answer is received, the call will hangup and a `call.hangup` webhook with a `hangup_cause` of `timeout` will be sent. Minimum value is 5 seconds. Maximum value is 120 seconds. (format: int32, default: 30, e.g. 60)
  to: string # The DID or SIP URI to dial out and bridge to the given call. (e.g. +18005550100 or sip:username@sip.telnyx.com)
  --webhook-url: string # Use this field to override the URL for which Telnyx will send subsequent webhooks to for this call. (e.g. https://www.example.com/server-b/)
  --webhook-url-method: string@webhook-url-method-completer # HTTP request type used for `webhook_url`. (default: POST, e.g. GET)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/calls/{call_control_id}/actions/transfer"
    path_params: [{name: call_control_id, var: call_control_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: answering_machine_detection, var: answering_machine_detection}, {name: answering_machine_detection_config, var: answering_machine_detection_config}, {name: audio_url, var: audio_url}, {name: client_state, var: client_state}, {name: command_id, var: command_id}, {name: custom_headers, var: custom_headers}, {name: from, var: from}, {name: from_display_name, var: from_display_name}, {name: media_name, var: media_name}, {name: sip_auth_password, var: sip_auth_password}, {name: sip_auth_username, var: sip_auth_username}, {name: target_leg_client_state, var: target_leg_client_state}, {name: time_limit_secs, var: time_limit_secs}, {name: timeout_secs, var: timeout_secs}, {name: to, var: to}, {name: webhook_url, var: webhook_url}, {name: webhook_url_method, var: webhook_url_method}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    call_control_id: $call_control_id, answering_machine_detection: $answering_machine_detection, answering_machine_detection_config: $answering_machine_detection_config, audio_url: $audio_url, client_state: $client_state, command_id: $command_id, custom_headers: $custom_headers, from: $from, from_display_name: $from_display_name, media_name: $media_name, sip_auth_password: $sip_auth_password, sip_auth_username: $sip_auth_username, target_leg_client_state: $target_leg_client_state, time_limit_secs: $time_limit_secs, timeout_secs: $timeout_secs, to: $to, webhook_url: $webhook_url, webhook_url_method: $webhook_url_method
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all comments
#
# GET /comments
# Returns: record<data: table<body: string, comment_record_id: string, comment_record_type: string, commenter: string, commenter_type: string, created_at: string, id: string, read_at: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: listComments
export def "list-comments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-comment-record-type: string # Record type that the comment relates to i.e number_order, sub_number_order or number_order_phone_number (required, e.g. sub_number_order)
  --filter-comment-record-id: string # ID of the record the comments relate to (required, e.g. 8ffb3622-7c6b-4ccc-b65f-7a3dc0099576)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/comments"
    query: [{name: "filter[comment_record_type]", var: filter_comment_record_type, required: true}, {name: "filter[comment_record_id]", var: filter_comment_record_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter_comment_record_type: $filter_comment_record_type, filter_comment_record_id: $filter_comment_record_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a comment
#
# POST /comments
# Returns: record<data: record<body: string, comment_record_id: string, comment_record_type: string, commenter: string, commenter_type: string, created_at: string, id: string, read_at: string, updated_at: string>>
# operationId: createComment
export def "create-comment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: string # e.g. Hi there, ....
  --comment-record-id: string # format: uuid, e.g. 8ffb3622-7c6b-4ccc-b65f-7a3dc0099576
  --comment-record-type: string@comment-record-type-completer # e.g. sub_number_order
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/comments"
    body: {content_type: "application/json", kind: json, fields: [{name: body, var: body}, {name: comment_record_id, var: comment_record_id}, {name: comment_record_type, var: comment_record_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    body: $body, comment_record_id: $comment_record_id, comment_record_type: $comment_record_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a comment
#
# GET /comments/{id}
# Returns: record<data: record<body: string, comment_record_id: string, comment_record_type: string, commenter: string, commenter_type: string, created_at: string, id: string, read_at: string, updated_at: string>>
# operationId: retrieveComment
export def "retrieve-comment" [
  id: string
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
    path: "/comments/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Mark a comment as read
#
# PATCH /comments/{id}/read
# Returns: record<data: record<body: string, comment_record_id: string, comment_record_type: string, commenter: string, commenter_type: string, created_at: string, id: string, read_at: string, updated_at: string>>
# operationId: markCommentRead
export def "mark-comment-read" [
  id: string
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
    method: patch
    path: "/comments/{id}/read"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List conferences
#
# GET /conferences
# Returns: record<data: table<connection_id: string, created_at: string, end_reason: string, ended_by: record, expires_at: string, id: string, name: string, record_type: string, region: string, status: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: listConferences
export def "list-conferences" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-name: string # If present, conferences will be filtered to those with a matching `name` attribute. Matching is case-sensitive
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/conferences"
    query: [{name: "filter[name]", var: filter_name}, {name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter_name: $filter_name, page_number: $page_number, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create conference
#
# POST /conferences
# Returns: record<data: record<connection_id: string, created_at: string, end_reason: string, ended_by: record<call_control_id: string, call_session_id: string>, expires_at: string, id: string, name: string, record_type: string, region: string, status: string, updated_at: string>>
# operationId: createConference
export def "create-conference" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --beep-enabled: string@beep-enabled-completer # Whether a beep sound should be played when participants join and/or leave the conference. (default: never, e.g. on_exit)
  call_control_id: string # Unique identifier and token for controlling the call (e.g. v2:T02llQxIyaRkhfRKxgAP8nY511EhFLizdvdUKJiSw8d6A9BborherQczRrZvZakpWxBlpw48KyZQ==)
  --client-state: string # Use this field to add state to every subsequent webhook. It must be a valid Base-64 encoded string. (e.g. aGF2ZSBhIG5pY2UgZGF5ID1d)
  --comfort-noise: oneof<nothing, bool> # Toggle background comfort noise. (default: true, e.g. false)
  --command-id: string # Use this field to avoid execution of duplicate commands. Telnyx will ignore subsequent commands with the same `command_id` as one that has already been executed. (e.g. 891510ac-f3e4-11e8-af5b-de00688a4901)
  --duration-minutes: int # Time length (minutes) after which the conference will end. (e.g. 5)
  --hold-audio-url: string # The URL of a file to be played to participants joining the conference. The URL can point to either a WAV or MP3 file. hold_media_name and hold_audio_url cannot be used together in one request. Takes effect only when "start_conference_on_create" is set to "false". (e.g. http://example.com/message.wav)
  --hold-media-name: string # The media_name of a file to be played to participants joining the conference. The media_name must point to a file previously uploaded to api.telnyx.com/v2/media by the same user/organization. The file must either be a WAV or MP3 file. Takes effect only when "start_conference_on_create" is set to "false". (e.g. my_media_uploaded_to_media_storage_api)
  name: string # Name of the conference (e.g. Business)
  --start-conference-on-create: oneof<nothing, bool> # Whether the conference should be started on creation. If the conference isn't started all participants that join are automatically put on hold. Defaults to "true". (e.g. false)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/conferences"
    body: {content_type: "application/json", kind: json, fields: [{name: beep_enabled, var: beep_enabled}, {name: call_control_id, var: call_control_id}, {name: client_state, var: client_state}, {name: comfort_noise, var: comfort_noise}, {name: command_id, var: command_id}, {name: duration_minutes, var: duration_minutes}, {name: hold_audio_url, var: hold_audio_url}, {name: hold_media_name, var: hold_media_name}, {name: name, var: name}, {name: start_conference_on_create, var: start_conference_on_create}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    beep_enabled: $beep_enabled, call_control_id: $call_control_id, client_state: $client_state, comfort_noise: $comfort_noise, command_id: $command_id, duration_minutes: $duration_minutes, hold_audio_url: $hold_audio_url, hold_media_name: $hold_media_name, name: $name, start_conference_on_create: $start_conference_on_create
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List conference participants
#
# GET /conferences/{conference_id}/participants
# Returns: record<data: table<call_control_id: string, call_leg_id: string, conference: record, created_at: string, end_conference_on_exit: bool, id: string, muted: bool, on_hold: bool, record_type: string, soft_end_conference_on_exit: bool, status: string, updated_at: string, whisper_call_control_ids: list>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: listConferenceParticipants
export def "list-conference-participants" [
  conference_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-muted: oneof<nothing, bool> # If present, participants will be filtered to those who are/are not muted
  --filter-on-hold: oneof<nothing, bool> # If present, participants will be filtered to those who are/are not put on hold
  --filter-whispering: oneof<nothing, bool> # If present, participants will be filtered to those who are whispering or are not
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/conferences/{conference_id}/participants"
    path_params: [{name: conference_id, var: conference_id}]
    query: [{name: "filter[muted]", var: filter_muted}, {name: "filter[on_hold]", var: filter_on_hold}, {name: "filter[whispering]", var: filter_whispering}, {name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    conference_id: $conference_id, filter_muted: $filter_muted, filter_on_hold: $filter_on_hold, filter_whispering: $filter_whispering, page_number: $page_number, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a conference
#
# GET /conferences/{id}
# Returns: record<data: record<connection_id: string, created_at: string, end_reason: string, ended_by: record<call_control_id: string, call_session_id: string>, expires_at: string, id: string, name: string, record_type: string, region: string, status: string, updated_at: string>>
# operationId: retrieveConference
export def "retrieve-conference" [
  id: string
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
    path: "/conferences/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Dial a new participant into a conference
#
# POST /conferences/{id}/actions/dial_participant
# Returns: record<data: record<result: string>>
# operationId: conferenceDialParticipantIn
export def "conference-dial-participant-in" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  call_control_id: string # Unique identifier and token for controlling the call (e.g. v2:T02llQxIyaRkhfRKxgAP8nY511EhFLizdvdUKJiSw8d6A9BborherQczRrZvZakpWxBlpw48KyZQ==)
  --client-state: string # Use this field to add state to every subsequent webhook. It must be a valid Base-64 encoded string. (e.g. aGF2ZSBhIG5pY2UgZGF5ID1d)
  --command-id: string # Use this field to avoid execution of duplicate commands. Telnyx will ignore subsequent commands with the same `command_id` as one that has already been executed. (e.g. 891510ac-f3e4-11e8-af5b-de00688a4901)
  from: string # The `from` number to be used as the caller id presented to the destination (`to` number). (e.g. +18005550101)
  --hold: oneof<nothing, bool> # Whether the participant should be put on hold immediately after joining the conference. (default: false, e.g. true)
  --hold-audio-url: string # The URL of a file to be played to the participant when they are put on hold after joining the conference. If media_name is also supplied, this is currently ignored. Takes effect only when "start_conference_on_create" is set to "false". This property takes effect only if "hold" is set to "true". (e.g. http://example.com/message.wav)
  --hold-media-name: string # The media_name of a file to be played to the participant when they are put on hold after joining the conference. The media_name must point to a file previously uploaded to api.telnyx.com/v2/media by the same user/organization. The file must either be a WAV or MP3 file. Takes effect only when "start_conference_on_create" is set to "false". This property takes effect only if "hold" is set to "true". (e.g. my_media_uploaded_to_media_storage_api)
  --mute: oneof<nothing, bool> # Whether the participant should be muted immediately after joining the conference. (default: false, e.g. false)
  --start-conference-on-enter: oneof<nothing, bool> # Whether the conference should be started after the participant joins the conference. (default: false, e.g. true)
  --supervisor-role: string@supervisor-role-completer # Sets the joining participant as a supervisor for the conference. A conference can have multiple supervisors. "barge" means the supervisor enters the conference as a normal participant. This is the same as "none". "monitor" means the supervisor is muted but can hear all participants. "whisper" means that only the specified "whisper_call_control_ids" can hear the supervisor. Defaults to "none". (e.g. whisper)
  to: string # The DID or SIP URI to dial out and bridge to the given call. (e.g. +18005550100 or sip:username@sip.telnyx.com)
  --whisper-call-control-ids: list<string> # Array of unique call_control_ids the joining supervisor can whisper to. If none provided, the supervisor will join the conference as a monitoring participant only. (e.g. [v2:Sg1xxxQ_U3ixxxyXT_VDNI3xxxazZdg6Vxxxs4-GNYxxxVaJPOhFMRQ, v2:qqpb0mmvd-ovhhBr0BUQQn0fld5jIboaaX3-De0DkqXHzbf8d75xkw])
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/conferences/{id}/actions/dial_participant"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: call_control_id, var: call_control_id}, {name: client_state, var: client_state}, {name: command_id, var: command_id}, {name: from, var: from}, {name: hold, var: hold}, {name: hold_audio_url, var: hold_audio_url}, {name: hold_media_name, var: hold_media_name}, {name: mute, var: mute}, {name: start_conference_on_enter, var: start_conference_on_enter}, {name: supervisor_role, var: supervisor_role}, {name: to, var: to}, {name: whisper_call_control_ids, var: whisper_call_control_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, call_control_id: $call_control_id, client_state: $client_state, command_id: $command_id, from: $from, hold: $hold, hold_audio_url: $hold_audio_url, hold_media_name: $hold_media_name, mute: $mute, start_conference_on_enter: $start_conference_on_enter, supervisor_role: $supervisor_role, to: $to, whisper_call_control_ids: $whisper_call_control_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Hold conference participants
#
# POST /conferences/{id}/actions/hold
# Returns: record<data: record<result: string>>
# operationId: conferenceHoldParticipants
export def "conference-hold-participants" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --audio-url: string # The URL of a file to be played to the participants when they are put on hold. media_name and audio_url cannot be used together in one request. (e.g. http://example.com/message.wav)
  --call-control-ids: list<string> # List of unique identifiers and tokens for controlling the call. When empty all participants will be placed on hold.
  --media-name: string # The media_name of a file to be played to the participants when they are put on hold. The media_name must point to a file previously uploaded to api.telnyx.com/v2/media by the same user/organization. The file must either be a WAV or MP3 file. (e.g. my_media_uploaded_to_media_storage_api)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/conferences/{id}/actions/hold"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: audio_url, var: audio_url}, {name: call_control_ids, var: call_control_ids}, {name: media_name, var: media_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, audio_url: $audio_url, call_control_ids: $call_control_ids, media_name: $media_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Join a conference
#
# POST /conferences/{id}/actions/join
# Returns: record<data: record<result: string>>
# operationId: conferenceJoin
export def "conference-join" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --beep-enabled: string@beep-enabled-completer # Whether a beep sound should be played when the participant joins and/or leaves the conference. Can be used to override the conference-level setting. (e.g. on_exit)
  call_control_id: string # Unique identifier and token for controlling the call (e.g. v2:T02llQxIyaRkhfRKxgAP8nY511EhFLizdvdUKJiSw8d6A9BborherQczRrZvZakpWxBlpw48KyZQ==)
  --client-state: string # Use this field to add state to every subsequent webhook. It must be a valid Base-64 encoded string. (e.g. aGF2ZSBhIG5pY2UgZGF5ID1d)
  --command-id: string # Use this field to avoid execution of duplicate commands. Telnyx will ignore subsequent commands with the same `command_id` as one that has already been executed. (e.g. 891510ac-f3e4-11e8-af5b-de00688a4901)
  --end-conference-on-exit: oneof<nothing, bool> # Whether the conference should end and all remaining participants be hung up after the participant leaves the conference. Defaults to "false". (e.g. true)
  --hold: oneof<nothing, bool> # Whether the participant should be put on hold immediately after joining the conference. Defaults to "false". (e.g. true)
  --hold-audio-url: string # The URL of a file to be played to the participant when they are put on hold after joining the conference. hold_media_name and hold_audio_url cannot be used together in one request. Takes effect only when "start_conference_on_create" is set to "false". This property takes effect only if "hold" is set to "true". (e.g. http://example.com/message.wav)
  --hold-media-name: string # The media_name of a file to be played to the participant when they are put on hold after joining the conference. The media_name must point to a file previously uploaded to api.telnyx.com/v2/media by the same user/organization. The file must either be a WAV or MP3 file. Takes effect only when "start_conference_on_create" is set to "false". This property takes effect only if "hold" is set to "true". (e.g. my_media_uploaded_to_media_storage_api)
  --mute: oneof<nothing, bool> # Whether the participant should be muted immediately after joining the conference. Defaults to "false". (e.g. true)
  --soft-end-conference-on-exit: oneof<nothing, bool> # Whether the conference should end after the participant leaves the conference. NOTE this doesn't hang up the other participants. Defaults to "false". (e.g. true)
  --start-conference-on-enter: oneof<nothing, bool> # Whether the conference should be started after the participant joins the conference. Defaults to "false". (e.g. true)
  --supervisor-role: string@supervisor-role-completer # Sets the joining participant as a supervisor for the conference. A conference can have multiple supervisors. "barge" means the supervisor enters the conference as a normal participant. This is the same as "none". "monitor" means the supervisor is muted but can hear all participants. "whisper" means that only the specified "whisper_call_control_ids" can hear the supervisor. Defaults to "none". (e.g. whisper)
  --whisper-call-control-ids: list<string> # Array of unique call_control_ids the joining supervisor can whisper to. If none provided, the supervisor will join the conference as a monitoring participant only. (e.g. [v2:Sg1xxxQ_U3ixxxyXT_VDNI3xxxazZdg6Vxxxs4-GNYxxxVaJPOhFMRQ, v2:qqpb0mmvd-ovhhBr0BUQQn0fld5jIboaaX3-De0DkqXHzbf8d75xkw])
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/conferences/{id}/actions/join"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: beep_enabled, var: beep_enabled}, {name: call_control_id, var: call_control_id}, {name: client_state, var: client_state}, {name: command_id, var: command_id}, {name: end_conference_on_exit, var: end_conference_on_exit}, {name: hold, var: hold}, {name: hold_audio_url, var: hold_audio_url}, {name: hold_media_name, var: hold_media_name}, {name: mute, var: mute}, {name: soft_end_conference_on_exit, var: soft_end_conference_on_exit}, {name: start_conference_on_enter, var: start_conference_on_enter}, {name: supervisor_role, var: supervisor_role}, {name: whisper_call_control_ids, var: whisper_call_control_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, beep_enabled: $beep_enabled, call_control_id: $call_control_id, client_state: $client_state, command_id: $command_id, end_conference_on_exit: $end_conference_on_exit, hold: $hold, hold_audio_url: $hold_audio_url, hold_media_name: $hold_media_name, mute: $mute, soft_end_conference_on_exit: $soft_end_conference_on_exit, start_conference_on_enter: $start_conference_on_enter, supervisor_role: $supervisor_role, whisper_call_control_ids: $whisper_call_control_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Leave a conference
#
# POST /conferences/{id}/actions/leave
# Returns: record<data: record<result: string>>
# operationId: conferenceLeave
export def "conference-leave" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --beep-enabled: string@beep-enabled-completer # Whether a beep sound should be played when the participant leaves the conference. Can be used to override the conference-level setting. (e.g. on_exit)
  call_control_id: string # Unique identifier and token for controlling the call (e.g. f91269aa-61d1-417f-97b3-10e020e8bc47)
  --command-id: string # Use this field to avoid execution of duplicate commands. Telnyx will ignore subsequent commands with the same `command_id` as one that has already been executed. (e.g. 891510ac-f3e4-11e8-af5b-de00688a4901)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/conferences/{id}/actions/leave"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: beep_enabled, var: beep_enabled}, {name: call_control_id, var: call_control_id}, {name: command_id, var: command_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, beep_enabled: $beep_enabled, call_control_id: $call_control_id, command_id: $command_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Mute conference participants
#
# POST /conferences/{id}/actions/mute
# Returns: record<data: record<result: string>>
# operationId: conferenceMuteParticipants
export def "conference-mute-participants" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --call-control-ids: list<string> # Array of unique identifiers and tokens for controlling the call. When empty all participants will be muted.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/conferences/{id}/actions/mute"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: call_control_ids, var: call_control_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, call_control_ids: $call_control_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Play audio to conference participants
#
# POST /conferences/{id}/actions/play
# Returns: record<data: record<result: string>>
# operationId: conferencePlayAudio
export def "conference-play-audio" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --audio-url: string # The URL of a file to be played back in the conference. media_name and audio_url cannot be used together in one request. (e.g. http://example.com/message.wav)
  --call-control-ids: list<string> # List of call control ids identifying participants the audio file should be played to. If not given, the audio file will be played to the entire conference.
  --loop: any
  --media-name: string # The media_name of a file to be played back in the conference. The media_name must point to a file previously uploaded to api.telnyx.com/v2/media by the same user/organization. The file must either be a WAV or MP3 file. (e.g. my_media_uploaded_to_media_storage_api)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/conferences/{id}/actions/play"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: audio_url, var: audio_url}, {name: call_control_ids, var: call_control_ids}, {name: loop, var: loop}, {name: media_name, var: media_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, audio_url: $audio_url, call_control_ids: $call_control_ids, loop: $loop, media_name: $media_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Conference recording start
#
# POST /conferences/{id}/actions/record_start
# Returns: record<data: record<result: string>>
# operationId: conferenceStartRecording
export def "conference-start-recording" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  channels: string@channels-completer # When `dual`, final audio file will be stereo recorded with the first leg on channel A, and the rest on channel B. (e.g. single)
  --client-state: string # Use this field to add state to every subsequent webhook. It must be a valid Base-64 encoded string. (e.g. aGF2ZSBhIG5pY2UgZGF5ID1d)
  --command-id: string # Use this field to avoid duplicate commands. Telnyx will ignore commands with the same `command_id`. (e.g. 891510ac-f3e4-11e8-af5b-de00688a4901)
  format: string@format-completer # The audio file format used when storing the call recording. Can be either `mp3` or `wav`. (e.g. mp3)
  --max-length: int # Defines the maximum length for the recording in seconds. Minimum value is 0. Maximum value is 14400. Default is 0 (infinite) (format: int32, default: 0, e.g. 100)
  --play-beep: oneof<nothing, bool> # If enabled, a beep sound will be played at the start of a recording. (e.g. true)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/conferences/{id}/actions/record_start"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: channels, var: channels}, {name: client_state, var: client_state}, {name: command_id, var: command_id}, {name: format, var: format}, {name: max_length, var: max_length}, {name: play_beep, var: play_beep}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, channels: $channels, client_state: $client_state, command_id: $command_id, format: $format, max_length: $max_length, play_beep: $play_beep
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Conference recording stop
#
# POST /conferences/{id}/actions/record_stop
# Returns: record<data: record<result: string>>
# operationId: conferenceStopRecording
export def "conference-stop-recording" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-state: string # Use this field to add state to every subsequent webhook. It must be a valid Base-64 encoded string. (e.g. aGF2ZSBhIG5pY2UgZGF5ID1d)
  --command-id: string # Use this field to avoid duplicate commands. Telnyx will ignore commands with the same `command_id`. (e.g. 891510ac-f3e4-11e8-af5b-de00688a4901)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/conferences/{id}/actions/record_stop"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: client_state, var: client_state}, {name: command_id, var: command_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, client_state: $client_state, command_id: $command_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Speak text to conference participants
#
# POST /conferences/{id}/actions/speak
# Returns: record<data: record<result: string>>
# operationId: conferenceSpeakText
export def "conference-speak-text" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --call-control-ids: list<string> # Call Control IDs of participants who will hear the spoken text. When empty all participants will hear the spoken text.
  --command-id: string # Use this field to avoid execution of duplicate commands. Telnyx will ignore subsequent commands with the same `command_id` as one that has already been executed. (e.g. 891510ac-f3e4-11e8-af5b-de00688a4901)
  language: string@language-completer # The language used to speak the text. (e.g. en-US)
  payload: string # The text or SSML to be converted into speech. There is a 5,000 character limit. (e.g. Say this to participants)
  --payload-type: string@payload-type-completer # The type of the provided payload. The payload can either be plain text, or Speech Synthesis Markup Language (SSML). (default: text, e.g. ssml)
  voice: string@voice-completer # The gender of the voice used to speak the text. (e.g. female)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/conferences/{id}/actions/speak"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: call_control_ids, var: call_control_ids}, {name: command_id, var: command_id}, {name: language, var: language}, {name: payload, var: payload}, {name: payload_type, var: payload_type}, {name: voice, var: voice}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, call_control_ids: $call_control_ids, command_id: $command_id, language: $language, payload: $payload, payload_type: $payload_type, voice: $voice
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stop audio being played on the conference
#
# POST /conferences/{id}/actions/stop
# Returns: record<data: record<result: string>>
# operationId: conferenceStopAudio
export def "conference-stop-audio" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --call-control-ids: list<string> # List of call control ids identifying participants the audio file should stop be played to. If not given, the audio will be stoped to the entire conference.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/conferences/{id}/actions/stop"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: call_control_ids, var: call_control_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, call_control_ids: $call_control_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unhold conference participants
#
# POST /conferences/{id}/actions/unhold
# Returns: record<data: record<result: string>>
# operationId: conferenceUnholdParticipants
export def "conference-unhold-participants" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  call_control_ids: list<string> # List of unique identifiers and tokens for controlling the call. Enter each call control ID to be unheld.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/conferences/{id}/actions/unhold"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: call_control_ids, var: call_control_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, call_control_ids: $call_control_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unmute conference participants
#
# POST /conferences/{id}/actions/unmute
# Returns: record<data: record<result: string>>
# operationId: conferenceUnmuteParticipants
export def "conference-unmute-participants" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --call-control-ids: list<string> # List of unique identifiers and tokens for controlling the call. Enter each call control ID to be unmuted. When empty all participants will be unmuted.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/conferences/{id}/actions/unmute"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: call_control_ids, var: call_control_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, call_control_ids: $call_control_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update conference participant
#
# POST /conferences/{id}/actions/update
# Returns: record<data: record<result: string>>
# operationId: conferenceUpdate
export def "conference-update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  call_control_id: string # Unique identifier and token for controlling the call (e.g. v2:T02llQxIyaRkhfRKxgAP8nY511EhFLizdvdUKJiSw8d6A9BborherQczRrZvZakpWxBlpw48KyZQ==)
  --command-id: string # Use this field to avoid execution of duplicate commands. Telnyx will ignore subsequent commands with the same `command_id` as one that has already been executed. (e.g. 891510ac-f3e4-11e8-af5b-de00688a4901)
  supervisor_role: string@supervisor-role-completer # Sets the participant as a supervisor for the conference. A conference can have multiple supervisors. "barge" means the supervisor enters the conference as a normal participant. This is the same as "none". "monitor" means the supervisor is muted but can hear all participants. "whisper" means that only the specified "whisper_call_control_ids" can hear the supervisor. Defaults to "none". (e.g. whisper)
  --whisper-call-control-ids: list<string> # Array of unique call_control_ids the supervisor can whisper to. If none provided, the supervisor will join the conference as a monitoring participant only. (e.g. [v2:Sg1xxxQ_U3ixxxyXT_VDNI3xxxazZdg6Vxxxs4-GNYxxxVaJPOhFMRQ, v2:qqpb0mmvd-ovhhBr0BUQQn0fld5jIboaaX3-De0DkqXHzbf8d75xkw])
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/conferences/{id}/actions/update"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: call_control_id, var: call_control_id}, {name: command_id, var: command_id}, {name: supervisor_role, var: supervisor_role}, {name: whisper_call_control_ids, var: whisper_call_control_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, call_control_id: $call_control_id, command_id: $command_id, supervisor_role: $supervisor_role, whisper_call_control_ids: $whisper_call_control_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List connections
#
# GET /connections
# Returns: record<data: table<active: bool, anchorsite_override: string, connection_name: string, created_at: string, id: string, outbound_voice_profile_id: string, record_type: string, updated_at: string, webhook_api_version: string, webhook_event_failover_url: string, webhook_event_url: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: listConnections
export def "list-connections" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
  --filter-connection-name-contains: string # If present, connections with connection_name containing the given value will be returned. Matching is not case-sensitive. Requires at least three characters.
  --filter-outbound-voice-profile-id: string # Identifies the associated outbound voice profile. (format: int64, e.g. 1293384261075731499)
  --sort: string@sort-completer-2 # Specifies the sort order for results. By default sorting direction is ascending. To have the results sorted in descending order add the - prefix. That is: connection_name: sorts the result by the connection_name field in ascending order. -connection_name: sorts the result by the connection_name field in descending order. If not given, results are sorted by created_at in descending order. (default: created_at, e.g. connection_name)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/connections"
    query: [{name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}, {name: "filter[connection_name][contains]", var: filter_connection_name_contains}, {name: "filter[outbound_voice_profile_id]", var: filter_outbound_voice_profile_id}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_number: $page_number, page_size: $page_size, filter_connection_name_contains: $filter_connection_name_contains, filter_outbound_voice_profile_id: $filter_outbound_voice_profile_id, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a connection
#
# GET /connections/{id}
# Returns: record<data: record<active: bool, anchorsite_override: string, connection_name: string, created_at: string, id: string, outbound_voice_profile_id: string, record_type: string, updated_at: string, webhook_api_version: string, webhook_event_failover_url: string, webhook_event_url: string>>
# operationId: retrieveConnection
export def "retrieve-connection" [
  id: string
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
    path: "/connections/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List credential connections
#
# GET /credential_connections
# Returns: record<data: table<active: bool, anchorsite_override: string, connection_name: string, created_at: string, default_on_hold_comfort_noise_enabled: bool, dtmf_type: string, encode_contact_header_enabled: bool, encrypted_media: string, id: string, inbound: record, onnet_t38_passthrough_enabled: bool, outbound: record, password: string, record_type: string, rtcp_settings: record, sip_uri_calling_preference: string, updated_at: string, user_name: string, webhook_api_version: string, webhook_event_failover_url: string, webhook_event_url: string, webhook_timeout_secs: int>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: listCredentialConnections
export def "list-credential-connections" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
  --filter-connection-name-contains: string # If present, connections with connection_name containing the given value will be returned. Matching is not case-sensitive. Requires at least three characters.
  --filter-outbound-outbound-voice-profile-id: string # Identifies the associated outbound voice profile. (format: int64, e.g. 1293384261075731499)
  --sort: string@sort-completer-2 # Specifies the sort order for results. By default sorting direction is ascending. To have the results sorted in descending order add the - prefix. That is: connection_name: sorts the result by the connection_name field in ascending order. -connection_name: sorts the result by the connection_name field in descending order. If not given, results are sorted by created_at in descending order. (default: created_at, e.g. connection_name)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/credential_connections"
    query: [{name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}, {name: "filter[connection_name][contains]", var: filter_connection_name_contains}, {name: "filter[outbound.outbound_voice_profile_id]", var: filter_outbound_outbound_voice_profile_id}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_number: $page_number, page_size: $page_size, filter_connection_name_contains: $filter_connection_name_contains, filter_outbound_outbound_voice_profile_id: $filter_outbound_outbound_voice_profile_id, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a credential connection
#
# POST /credential_connections
# Returns: record<data: record<active: bool, anchorsite_override: string, connection_name: string, created_at: string, default_on_hold_comfort_noise_enabled: bool, dtmf_type: string, encode_contact_header_enabled: bool, encrypted_media: string, id: string, inbound: record<ani_number_format: string, channel_limit: int, codecs: list, dnis_number_format: string, generate_ringback_tone: bool, isup_headers_enabled: bool, prack_enabled: bool, privacy_zone_enabled: bool, sip_compact_headers_enabled: bool, timeout_1xx_secs: int, timeout_2xx_secs: string>, onnet_t38_passthrough_enabled: bool, outbound: record<ani_override: string, ani_override_type: string, call_parking_enabled: bool, channel_limit: int, generate_ringback_tone: bool, instant_ringback_enabled: bool, localization: string, outbound_voice_profile_id: string, t38_reinvite_source: string>, password: string, record_type: string, rtcp_settings: record<capture_enabled: bool, port: any, report_frequency_secs: int>, sip_uri_calling_preference: string, updated_at: string, user_name: string, webhook_api_version: string, webhook_event_failover_url: string, webhook_event_url: string, webhook_timeout_secs: int>>
# operationId: createCredentialConnection
export def "create-credential-connection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # Defaults to true
  --anchorsite-override: string@anchorsite-override-completer-1 # `Latency` directs Telnyx to route media through the site with the lowest round-trip time to the user's connection. Telnyx calculates this time using ICMP ping messages. This can be disabled by specifying a site to handle all media. (default: Latency, e.g. Amsterdam, Netherlands)
  connection_name: string
  --default-on-hold-comfort-noise-enabled: oneof<nothing, bool> # When enabled, Telnyx will generate comfort noise when you place the call on hold. If disabled, you will need to generate comfort noise or on hold music to avoid RTP timeout. (default: false)
  --dtmf-type: string@dtmf-type-completer # Sets the type of DTMF digits sent from Telnyx to this Connection. Note that DTMF digits sent to Telnyx will be accepted in all formats. (default: RFC 2833, e.g. Inband)
  --encode-contact-header-enabled: oneof<nothing, bool> # Encode the SIP contact header sent by Telnyx to avoid issues for NAT or ALG scenarios. (default: false)
  --encrypted-media: string@encrypted-media-completer # Enable use of SRTP or ZRTP for encryption. Valid values are those listed or null. Cannot be set to non-null if the transport_portocol is TLS. (nullable, e.g. SRTP)
  --inbound: record # e.g. {ani_number_format: +E.164, channel_limit: 10, codecs: G722, default_routing_method: sequential, dnis_number_format: +e164, generate_ringback_tone: true, isup_headers_enabled: true, prack_enabled: true, privacy_zone_enabled: true, sip_compact_headers_enabled: true, timeout_1xx_secs: 10, timeout_2xx_secs: 20} — shape: {ani_number_format?: "+E.164"|"E.164"|"+E.164-national"|"E.164-national", channel_limit?: int, codecs?: list<string>, dnis_number_format?: "+e164"|"e164"|"national"|"sip_username", generate_ringback_tone?: bool, isup_headers_enabled?: bool, prack_enabled?: bool, privacy_zone_enabled?: bool, sip_compact_headers_enabled?: bool, timeout_1xx_secs?: int, timeout_2xx_secs?: string}
  --onnet-t38-passthrough-enabled: oneof<nothing, bool> # Enable on-net T38 if you prefer the sender and receiver negotiating T38 directly if both are on the Telnyx network. If this is disabled, Telnyx will be able to use T38 on just one leg of the call depending on each leg's settings. (default: false)
  --outbound: record # e.g. {ani_override: always, call_parking_enabled: true, channel_limit: 10, generate_ringback_tone: true, instant_ringback_enabled: true, localization: US, outbound_voice_profile_id: 1293384261075731499, t38_reinvite_source: telnyx} — shape: {ani_override?: string, ani_override_type?: "always"|"normal"|"emergency", call_parking_enabled?: bool, channel_limit?: int, generate_ringback_tone?: bool, instant_ringback_enabled?: bool, localization?: string, outbound_voice_profile_id?: string, t38_reinvite_source?: "telnyx"|"customer"|"disabled"|"passthru"|"caller-passthru"|"callee-passthru"}
  password: string # The password to be used as part of the credentials. Must be 8 to 128 characters long. (e.g. my123secure456password789)
  --rtcp-settings: record # e.g. {capture_enabled: true, port: rtcp-mux, report_frequency_secs: 10} — shape: {capture_enabled?: bool, port?: "rtcp-mux"|"rtp+1", report_frequency_secs?: int}
  --sip-uri-calling-preference: string@sip-uri-calling-preference-completer # This feature enables inbound SIP URI calls to your Credential Auth Connection. If enabled for all (unrestricted) then anyone who calls the SIP URI <your-username>@telnyx.com will be connected to your Connection. You can also choose to allow only calls that are originated on any Connections under your account (internal). (default: disabled)
  user_name: string # The user name to be used as part of the credentials. Must be 4-32 characters long and alphanumeric values only (no spaces or special characters). (e.g. myusername123)
  --webhook-api-version: string@webhook-api-version-completer # Determines which webhook format will be used, Telnyx API v1 or v2. (default: 1, e.g. 1)
  --webhook-event-failover-url: string # The failover URL where webhooks related to this connection will be sent if sending to the primary URL fails. Must include a scheme, such as 'https'. (nullable, format: url, default: "", e.g. https://failover.example.com)
  --webhook-event-url: string # The URL where webhooks related to this connection will be sent. Must include a scheme, such as 'https'. (format: url, e.g. https://example.com)
  --webhook-timeout-secs: int # Specifies how many seconds to wait before timing out a webhook. (nullable, e.g. 25)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/credential_connections"
    body: {content_type: "application/json", kind: json, fields: [{name: active, var: active}, {name: anchorsite_override, var: anchorsite_override}, {name: connection_name, var: connection_name}, {name: default_on_hold_comfort_noise_enabled, var: default_on_hold_comfort_noise_enabled}, {name: dtmf_type, var: dtmf_type}, {name: encode_contact_header_enabled, var: encode_contact_header_enabled}, {name: encrypted_media, var: encrypted_media}, {name: inbound, var: inbound}, {name: onnet_t38_passthrough_enabled, var: onnet_t38_passthrough_enabled}, {name: outbound, var: outbound}, {name: password, var: password}, {name: rtcp_settings, var: rtcp_settings}, {name: sip_uri_calling_preference, var: sip_uri_calling_preference}, {name: user_name, var: user_name}, {name: webhook_api_version, var: webhook_api_version}, {name: webhook_event_failover_url, var: webhook_event_failover_url}, {name: webhook_event_url, var: webhook_event_url}, {name: webhook_timeout_secs, var: webhook_timeout_secs}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    active: $active, anchorsite_override: $anchorsite_override, connection_name: $connection_name, default_on_hold_comfort_noise_enabled: $default_on_hold_comfort_noise_enabled, dtmf_type: $dtmf_type, encode_contact_header_enabled: $encode_contact_header_enabled, encrypted_media: $encrypted_media, inbound: $inbound, onnet_t38_passthrough_enabled: $onnet_t38_passthrough_enabled, outbound: $outbound, password: $password, rtcp_settings: $rtcp_settings, sip_uri_calling_preference: $sip_uri_calling_preference, user_name: $user_name, webhook_api_version: $webhook_api_version, webhook_event_failover_url: $webhook_event_failover_url, webhook_event_url: $webhook_event_url, webhook_timeout_secs: $webhook_timeout_secs
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a credential connection
#
# DELETE /credential_connections/{id}
# Returns: record<data: record<active: bool, anchorsite_override: string, connection_name: string, created_at: string, default_on_hold_comfort_noise_enabled: bool, dtmf_type: string, encode_contact_header_enabled: bool, encrypted_media: string, id: string, inbound: record<ani_number_format: string, channel_limit: int, codecs: list, dnis_number_format: string, generate_ringback_tone: bool, isup_headers_enabled: bool, prack_enabled: bool, privacy_zone_enabled: bool, sip_compact_headers_enabled: bool, timeout_1xx_secs: int, timeout_2xx_secs: string>, onnet_t38_passthrough_enabled: bool, outbound: record<ani_override: string, ani_override_type: string, call_parking_enabled: bool, channel_limit: int, generate_ringback_tone: bool, instant_ringback_enabled: bool, localization: string, outbound_voice_profile_id: string, t38_reinvite_source: string>, password: string, record_type: string, rtcp_settings: record<capture_enabled: bool, port: any, report_frequency_secs: int>, sip_uri_calling_preference: string, updated_at: string, user_name: string, webhook_api_version: string, webhook_event_failover_url: string, webhook_event_url: string, webhook_timeout_secs: int>>
# operationId: deleteCredentialConnection
export def "delete-credential-connection" [
  id: string
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
    method: delete
    path: "/credential_connections/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a credential connection
#
# GET /credential_connections/{id}
# Returns: record<data: record<active: bool, anchorsite_override: string, connection_name: string, created_at: string, default_on_hold_comfort_noise_enabled: bool, dtmf_type: string, encode_contact_header_enabled: bool, encrypted_media: string, id: string, inbound: record<ani_number_format: string, channel_limit: int, codecs: list, dnis_number_format: string, generate_ringback_tone: bool, isup_headers_enabled: bool, prack_enabled: bool, privacy_zone_enabled: bool, sip_compact_headers_enabled: bool, timeout_1xx_secs: int, timeout_2xx_secs: string>, onnet_t38_passthrough_enabled: bool, outbound: record<ani_override: string, ani_override_type: string, call_parking_enabled: bool, channel_limit: int, generate_ringback_tone: bool, instant_ringback_enabled: bool, localization: string, outbound_voice_profile_id: string, t38_reinvite_source: string>, password: string, record_type: string, rtcp_settings: record<capture_enabled: bool, port: any, report_frequency_secs: int>, sip_uri_calling_preference: string, updated_at: string, user_name: string, webhook_api_version: string, webhook_event_failover_url: string, webhook_event_url: string, webhook_timeout_secs: int>>
# operationId: retrieveCredentialConnection
export def "retrieve-credential-connection" [
  id: string
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
    path: "/credential_connections/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a credential connection
#
# PATCH /credential_connections/{id}
# Returns: record<data: record<active: bool, anchorsite_override: string, connection_name: string, created_at: string, default_on_hold_comfort_noise_enabled: bool, dtmf_type: string, encode_contact_header_enabled: bool, encrypted_media: string, id: string, inbound: record<ani_number_format: string, channel_limit: int, codecs: list, dnis_number_format: string, generate_ringback_tone: bool, isup_headers_enabled: bool, prack_enabled: bool, privacy_zone_enabled: bool, sip_compact_headers_enabled: bool, timeout_1xx_secs: int, timeout_2xx_secs: string>, onnet_t38_passthrough_enabled: bool, outbound: record<ani_override: string, ani_override_type: string, call_parking_enabled: bool, channel_limit: int, generate_ringback_tone: bool, instant_ringback_enabled: bool, localization: string, outbound_voice_profile_id: string, t38_reinvite_source: string>, password: string, record_type: string, rtcp_settings: record<capture_enabled: bool, port: any, report_frequency_secs: int>, sip_uri_calling_preference: string, updated_at: string, user_name: string, webhook_api_version: string, webhook_event_failover_url: string, webhook_event_url: string, webhook_timeout_secs: int>>
# operationId: updateCredentialConnection
export def "update-credential-connection" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # Defaults to true
  --anchorsite-override: string@anchorsite-override-completer-1 # `Latency` directs Telnyx to route media through the site with the lowest round-trip time to the user's connection. Telnyx calculates this time using ICMP ping messages. This can be disabled by specifying a site to handle all media. (default: Latency, e.g. Amsterdam, Netherlands)
  --connection-name: string
  --default-on-hold-comfort-noise-enabled: oneof<nothing, bool> # When enabled, Telnyx will generate comfort noise when you place the call on hold. If disabled, you will need to generate comfort noise or on hold music to avoid RTP timeout. (default: false)
  --dtmf-type: string@dtmf-type-completer # Sets the type of DTMF digits sent from Telnyx to this Connection. Note that DTMF digits sent to Telnyx will be accepted in all formats. (default: RFC 2833, e.g. Inband)
  --encode-contact-header-enabled: oneof<nothing, bool> # Encode the SIP contact header sent by Telnyx to avoid issues for NAT or ALG scenarios. (default: false)
  --encrypted-media: string@encrypted-media-completer # Enable use of SRTP or ZRTP for encryption. Valid values are those listed or null. Cannot be set to non-null if the transport_portocol is TLS. (nullable, e.g. SRTP)
  --inbound: record # e.g. {ani_number_format: +E.164, channel_limit: 10, codecs: G722, default_routing_method: sequential, dnis_number_format: +e164, generate_ringback_tone: true, isup_headers_enabled: true, prack_enabled: true, privacy_zone_enabled: true, sip_compact_headers_enabled: true, timeout_1xx_secs: 10, timeout_2xx_secs: 20} — shape: {ani_number_format?: "+E.164"|"E.164"|"+E.164-national"|"E.164-national", channel_limit?: int, codecs?: list<string>, dnis_number_format?: "+e164"|"e164"|"national"|"sip_username", generate_ringback_tone?: bool, isup_headers_enabled?: bool, prack_enabled?: bool, privacy_zone_enabled?: bool, sip_compact_headers_enabled?: bool, timeout_1xx_secs?: int, timeout_2xx_secs?: string}
  --onnet-t38-passthrough-enabled: oneof<nothing, bool> # Enable on-net T38 if you prefer the sender and receiver negotiating T38 directly if both are on the Telnyx network. If this is disabled, Telnyx will be able to use T38 on just one leg of the call depending on each leg's settings. (default: false)
  --outbound: record # e.g. {ani_override: always, call_parking_enabled: true, channel_limit: 10, generate_ringback_tone: true, instant_ringback_enabled: true, localization: US, outbound_voice_profile_id: 1293384261075731499, t38_reinvite_source: telnyx} — shape: {ani_override?: string, ani_override_type?: "always"|"normal"|"emergency", call_parking_enabled?: bool, channel_limit?: int, generate_ringback_tone?: bool, instant_ringback_enabled?: bool, localization?: string, outbound_voice_profile_id?: string, t38_reinvite_source?: "telnyx"|"customer"|"disabled"|"passthru"|"caller-passthru"|"callee-passthru"}
  --password: string # The password to be used as part of the credentials. Must be 8 to 128 characters long. (e.g. my123secure456password789)
  --rtcp-settings: record # e.g. {capture_enabled: true, port: rtcp-mux, report_frequency_secs: 10} — shape: {capture_enabled?: bool, port?: "rtcp-mux"|"rtp+1", report_frequency_secs?: int}
  --sip-uri-calling-preference: string@sip-uri-calling-preference-completer # This feature enables inbound SIP URI calls to your Credential Auth Connection. If enabled for all (unrestricted) then anyone who calls the SIP URI <your-username>@telnyx.com will be connected to your Connection. You can also choose to allow only calls that are originated on any Connections under your account (internal). (default: disabled)
  --user-name: string # The user name to be used as part of the credentials. Must be 4-32 characters long and alphanumeric values only (no spaces or special characters). (e.g. myusername123)
  --webhook-api-version: string@webhook-api-version-completer # Determines which webhook format will be used, Telnyx API v1 or v2. (default: 1, e.g. 1)
  --webhook-event-failover-url: string # The failover URL where webhooks related to this connection will be sent if sending to the primary URL fails. Must include a scheme, such as 'https'. (nullable, format: url, default: "", e.g. https://failover.example.com)
  --webhook-event-url: string # The URL where webhooks related to this connection will be sent. Must include a scheme, such as 'https'. (format: url, e.g. https://example.com)
  --webhook-timeout-secs: int # Specifies how many seconds to wait before timing out a webhook. (nullable, e.g. 25)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/credential_connections/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: active, var: active}, {name: anchorsite_override, var: anchorsite_override}, {name: connection_name, var: connection_name}, {name: default_on_hold_comfort_noise_enabled, var: default_on_hold_comfort_noise_enabled}, {name: dtmf_type, var: dtmf_type}, {name: encode_contact_header_enabled, var: encode_contact_header_enabled}, {name: encrypted_media, var: encrypted_media}, {name: inbound, var: inbound}, {name: onnet_t38_passthrough_enabled, var: onnet_t38_passthrough_enabled}, {name: outbound, var: outbound}, {name: password, var: password}, {name: rtcp_settings, var: rtcp_settings}, {name: sip_uri_calling_preference, var: sip_uri_calling_preference}, {name: user_name, var: user_name}, {name: webhook_api_version, var: webhook_api_version}, {name: webhook_event_failover_url, var: webhook_event_failover_url}, {name: webhook_event_url, var: webhook_event_url}, {name: webhook_timeout_secs, var: webhook_timeout_secs}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, active: $active, anchorsite_override: $anchorsite_override, connection_name: $connection_name, default_on_hold_comfort_noise_enabled: $default_on_hold_comfort_noise_enabled, dtmf_type: $dtmf_type, encode_contact_header_enabled: $encode_contact_header_enabled, encrypted_media: $encrypted_media, inbound: $inbound, onnet_t38_passthrough_enabled: $onnet_t38_passthrough_enabled, outbound: $outbound, password: $password, rtcp_settings: $rtcp_settings, sip_uri_calling_preference: $sip_uri_calling_preference, user_name: $user_name, webhook_api_version: $webhook_api_version, webhook_event_failover_url: $webhook_event_failover_url, webhook_event_url: $webhook_event_url, webhook_timeout_secs: $webhook_timeout_secs
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search detail records
#
# GET /detail_records
# Returns: record<data: list<record>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: DetailRecordsSearch
export def "detail-records-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-record-type: string # Filter by the given record type (required)
  --filter-date-range: string # Filter by the given user-friendly date range
  --filter: record # Filter records
  --page-number: int # Page number (format: int32, default: 1)
  --page-size: int # Page size (format: int32, default: 20)
  --sort: list<string> # Specifies the sort order for results
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/detail_records"
    query: [{name: "filter[record_type]", var: filter_record_type, required: true}, {name: "filter[date_range]", var: filter_date_range}, {name: filter, var: filter, style: multi}, {name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}, {name: sort, var: sort, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter_record_type: $filter_record_type, filter_date_range: $filter_date_range, filter: $filter, page_number: $page_number, page_size: $page_size, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all document links
#
# GET /document_links
# Returns: record<data: table<created_at: string, id: string, record_type: string, updated_at: string, document_id: string, linked_record_type: string, linked_resource_id: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: listDocumentLinks
export def "list-document-links" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
  --filter-document-id: string # Identifies the associated document to filter on. (format: uuid, e.g. 6a09cdc3-8948-47f0-aa62-74ac943d6c58)
  --filter-linked-record-type: string # The `linked_record_type` of the document to filter on. (e.g. porting_order)
  --filter-linked-resource-id: string # The `linked_resource_id` of the document to filter on. (format: uuid, e.g. 6a09cdc3-8948-47f0-aa62-74ac943d6c58)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/document_links"
    query: [{name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}, {name: "filter[document_id]", var: filter_document_id}, {name: "filter[linked_record_type]", var: filter_linked_record_type}, {name: "filter[linked_resource_id]", var: filter_linked_resource_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_number: $page_number, page_size: $page_size, filter_document_id: $filter_document_id, filter_linked_record_type: $filter_linked_record_type, filter_linked_resource_id: $filter_linked_resource_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all documents
#
# GET /documents
# Returns: record<data: table<created_at: string, id: string, record_type: string, updated_at: string, content_type: string, filename: string, sha256: string, size: record, status: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: listDocuments
export def "list-documents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/documents"
    query: [{name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_number: $page_number, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload a document
#
# POST /documents
# Returns: record<data: record<created_at: string, id: string, record_type: string, updated_at: string, content_type: string, filename: string, sha256: string, size: record<amount: int, unit: string>, status: string>>
# operationId: createDocument
export def "create-document" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --url: string # If the file is already hosted publicly, you can provide a URL and have the documents service fetch it for you. (e.g. https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf)
  --file: string # The Base64 encoded contents of the file you are uploading. (format: byte, e.g. [Base64 encoded content])
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/documents"
    body: {content_type: "application/json", kind: json, fields: [{name: url, var: url}, {name: file, var: file}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    url: $url, file: $file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a document
#
# DELETE /documents/{id}
# Returns: record<data: record<created_at: string, id: string, record_type: string, updated_at: string, content_type: string, filename: string, sha256: string, size: record<amount: int, unit: string>, status: string>>
# operationId: deleteDocument
export def "delete-document" [
  id: string
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
    method: delete
    path: "/documents/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a document
#
# GET /documents/{id}
# Returns: record<data: record<created_at: string, id: string, record_type: string, updated_at: string, content_type: string, filename: string, sha256: string, size: record<amount: int, unit: string>, status: string>>
# operationId: retrieveDocument
export def "retrieve-document" [
  id: string
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
    path: "/documents/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a document
#
# PATCH /documents/{id}
# Returns: record<data: record<created_at: string, id: string, record_type: string, updated_at: string, content_type: string, filename: string, sha256: string, size: record<amount: int, unit: string>, status: string>>
# operationId: updateDocument
export def "update-document" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filename: string # The filename of the document. (e.g. test-document.pdf)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/documents/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: filename, var: filename}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, filename: $filename
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download a document
#
# GET /documents/{id}/download
# Returns: binary
# operationId: downloadDocServiceDocument
export def "download-doc-service-document" [
  id: string
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
]: nothing -> any {
  http-request {
    method: get
    path: "/documents/{id}/download"
    path_params: [{name: id, var: id}]
    accept: ["*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List all Fax Applications
#
# GET /fax_applications
# Returns: record<data: table<active: bool, anchorsite_override: string, application_name: string, created_at: string, id: string, inbound: record, outbound: record, record_type: string, updated_at: string, webhook_event_failover_url: string, webhook_event_url: string, webhook_timeout_secs: int>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: listFaxApplications
export def "list-fax-applications" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
  --filter-application-name-contains: string # If present, applications with application_name containing the given value will be returned. Matching is not case-sensitive. Requires at least three characters. (default: null)
  --filter-outbound-voice-profile-id: string # Identifies the associated outbound voice profile. (format: int64, e.g. 1293384261075731499)
  --sort: string@sort-completer-2 # Specifies the sort order for results. By default sorting direction is ascending. To have the results sorted in descending order add the - prefix. That is: connection_name: sorts the result by the connection_name field in ascending order. -connection_name: sorts the result by the connection_name field in descending order. If not given, results are sorted by created_at in descending order. (default: created_at, e.g. connection_name)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/fax_applications"
    query: [{name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}, {name: "filter[application_name][contains]", var: filter_application_name_contains}, {name: "filter[outbound_voice_profile_id]", var: filter_outbound_voice_profile_id}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_number: $page_number, page_size: $page_size, filter_application_name_contains: $filter_application_name_contains, filter_outbound_voice_profile_id: $filter_outbound_voice_profile_id, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a Fax Application
#
# POST /fax_applications
# Returns: record<data: record<active: bool, anchorsite_override: string, application_name: string, created_at: string, id: string, inbound: record<channel_limit: int, sip_subdomain: string, sip_subdomain_receive_settings: string>, outbound: record<channel_limit: int, outbound_voice_profile_id: string>, record_type: string, updated_at: string, webhook_event_failover_url: string, webhook_event_url: string, webhook_timeout_secs: int>>
# operationId: CreateFaxApplication
export def "create-fax-application" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # Specifies whether the connection can be used. (default: true, e.g. false)
  --anchorsite-override: string@anchorsite-override-completer-1 # `Latency` directs Telnyx to route media through the site with the lowest round-trip time to the user's connection. Telnyx calculates this time using ICMP ping messages. This can be disabled by specifying a site to handle all media. (default: Latency, e.g. Amsterdam, Netherlands)
  application_name: string # A user-assigned name to help manage the application. (e.g. call-router)
  --inbound: record # shape: {channel_limit?: int, sip_subdomain?: string, sip_subdomain_receive_settings?: "only_my_connections"|"from_anyone"}
  --outbound: record # shape: {channel_limit?: int, outbound_voice_profile_id?: string}
  --webhook-event-failover-url: string # The failover URL where webhooks related to this connection will be sent if sending to the primary URL fails. Must include a scheme, such as 'https'. (nullable, format: url, default: "", e.g. https://failover.example.com)
  webhook_event_url: string # The URL where webhooks related to this connection will be sent. Must include a scheme, such as 'https'. (format: url, e.g. https://example.com)
  --webhook-timeout-secs: int # Specifies how many seconds to wait before timing out a webhook. (nullable, e.g. 25)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/fax_applications"
    body: {content_type: "application/json", kind: json, fields: [{name: active, var: active}, {name: anchorsite_override, var: anchorsite_override}, {name: application_name, var: application_name}, {name: inbound, var: inbound}, {name: outbound, var: outbound}, {name: webhook_event_failover_url, var: webhook_event_failover_url}, {name: webhook_event_url, var: webhook_event_url}, {name: webhook_timeout_secs, var: webhook_timeout_secs}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    active: $active, anchorsite_override: $anchorsite_override, application_name: $application_name, inbound: $inbound, outbound: $outbound, webhook_event_failover_url: $webhook_event_failover_url, webhook_event_url: $webhook_event_url, webhook_timeout_secs: $webhook_timeout_secs
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a Fax Application
#
# DELETE /fax_applications/{id}
# Returns: record<data: record<active: bool, anchorsite_override: string, application_name: string, created_at: string, id: string, inbound: record<channel_limit: int, sip_subdomain: string, sip_subdomain_receive_settings: string>, outbound: record<channel_limit: int, outbound_voice_profile_id: string>, record_type: string, updated_at: string, webhook_event_failover_url: string, webhook_event_url: string, webhook_timeout_secs: int>>
# operationId: DeleteFaxApplication
export def "delete-fax-application" [
  id: string
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
    method: delete
    path: "/fax_applications/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a Fax Application
#
# GET /fax_applications/{id}
# Returns: record<data: record<active: bool, anchorsite_override: string, application_name: string, created_at: string, id: string, inbound: record<channel_limit: int, sip_subdomain: string, sip_subdomain_receive_settings: string>, outbound: record<channel_limit: int, outbound_voice_profile_id: string>, record_type: string, updated_at: string, webhook_event_failover_url: string, webhook_event_url: string, webhook_timeout_secs: int>>
# operationId: getFaxApplication
export def "get-fax-application" [
  id: string
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
    path: "/fax_applications/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a Fax Application
#
# PATCH /fax_applications/{id}
# Returns: record<data: record<active: bool, anchorsite_override: string, application_name: string, created_at: string, id: string, inbound: record<channel_limit: int, sip_subdomain: string, sip_subdomain_receive_settings: string>, outbound: record<channel_limit: int, outbound_voice_profile_id: string>, record_type: string, updated_at: string, webhook_event_failover_url: string, webhook_event_url: string, webhook_timeout_secs: int>>
# operationId: UpdateFaxApplication
export def "update-fax-application" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # Specifies whether the connection can be used. (default: true, e.g. false)
  --anchorsite-override: string@anchorsite-override-completer-1 # `Latency` directs Telnyx to route media through the site with the lowest round-trip time to the user's connection. Telnyx calculates this time using ICMP ping messages. This can be disabled by specifying a site to handle all media. (default: Latency, e.g. Amsterdam, Netherlands)
  application_name: string # A user-assigned name to help manage the application. (e.g. call-router)
  --inbound: record # shape: {channel_limit?: int, sip_subdomain?: string, sip_subdomain_receive_settings?: "only_my_connections"|"from_anyone"}
  --outbound: record # shape: {channel_limit?: int, outbound_voice_profile_id?: string}
  --webhook-event-failover-url: string # The failover URL where webhooks related to this connection will be sent if sending to the primary URL fails. Must include a scheme, such as 'https'. (nullable, format: url, default: "", e.g. https://failover.example.com)
  webhook_event_url: string # The URL where webhooks related to this connection will be sent. Must include a scheme, such as 'https'. (format: url, e.g. https://example.com)
  --webhook-timeout-secs: int # Specifies how many seconds to wait before timing out a webhook. (nullable, e.g. 25)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/fax_applications/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: active, var: active}, {name: anchorsite_override, var: anchorsite_override}, {name: application_name, var: application_name}, {name: inbound, var: inbound}, {name: outbound, var: outbound}, {name: webhook_event_failover_url, var: webhook_event_failover_url}, {name: webhook_event_url, var: webhook_event_url}, {name: webhook_timeout_secs, var: webhook_timeout_secs}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, active: $active, anchorsite_override: $anchorsite_override, application_name: $application_name, inbound: $inbound, outbound: $outbound, webhook_event_failover_url: $webhook_event_failover_url, webhook_event_url: $webhook_event_url, webhook_timeout_secs: $webhook_timeout_secs
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View a list of faxes
#
# GET /faxes
# Returns: record<data: table<connection_id: string, created_at: string, direction: string, from: string, id: string, media_name: string, media_url: string, quality: string, record_type: string, status: string, store_media: bool, stored_media_url: string, to: string, updated_at: string, webhook_failover_url: string, webhook_url: string>, meta: record>
# operationId: ListFaxes
export def "list-faxes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-created-at-gte: string # ISO 8601 date time for filtering faxes created after or on that date (format: date-time, e.g. 2020-02-02T22:25:27.521992Z)
  --filter-created-at-gt: string # ISO 8601 date time for filtering faxes created after that date (format: date-time, e.g. 2020-02-02T22:25:27.521992Z)
  --filter-created-at-lte: string # ISO 8601 formatted date time for filtering faxes created on or before that date (format: date-time, e.g. 2020-02-02T22:25:27.521992Z)
  --filter-created-at-lt: string # ISO 8601 formatted date time for filtering faxes created before that date (format: date-time, e.g. 2020-02-02T22:25:27.521992Z)
  --filter-direction-eq: string # The direction, inbound or outbound, for filtering faxes sent from this account (e.g. inbound)
  --filter-from-eq: string # The phone number, in E.164 format for filtering faxes sent from this number (e.g. +13127367276)
  --page-size: int # Number of fax resourcxes for the single page returned (e.g. 2)
  --page-number: int # Number of the page to be retrieved (e.g. 2)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/faxes"
    query: [{name: "filter[created_at][gte]", var: filter_created_at_gte}, {name: "filter[created_at][gt]", var: filter_created_at_gt}, {name: "filter[created_at][lte]", var: filter_created_at_lte}, {name: "filter[created_at][lt]", var: filter_created_at_lt}, {name: "filter[direction][eq]", var: filter_direction_eq}, {name: "filter[from][eq]", var: filter_from_eq}, {name: "page[size]", var: page_size}, {name: "page[number]", var: page_number}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter_created_at_gte: $filter_created_at_gte, filter_created_at_gt: $filter_created_at_gt, filter_created_at_lte: $filter_created_at_lte, filter_created_at_lt: $filter_created_at_lt, filter_direction_eq: $filter_direction_eq, filter_from_eq: $filter_from_eq, page_size: $page_size, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send a fax
#
# POST /faxes
# Returns: record<data: record<connection_id: string, created_at: string, direction: string, from: string, id: string, media_name: string, media_url: string, quality: string, record_type: string, status: string, store_media: bool, stored_media_url: string, to: string, updated_at: string, webhook_failover_url: string, webhook_url: string>>
# operationId: SendFax
export def "send-fax" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  connection_id: string # The connection ID to send the fax with. (e.g. 234423)
  from: string # The phone number, in E.164 format, the fax will be sent from. (e.g. +13125790015)
  --media-name: string # The media_name of a file to be used for the fax's media. The media_name must point to a file previously uploaded to api.telnyx.com/v2/media by the same user/organization. media_url and media_name can't be submitted together. (e.g. my_media_uploaded_to_media_storage_api)
  --media-url: string # The URL to the PDF used for the fax's media. media_url and media_name can't be submitted together. (e.g. https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf)
  --quality: string # The quality of the fax. Can be normal, high, very_high. (default: high, e.g. high)
  --store-media: oneof<nothing, bool> # Should fax media be stored on temporary URL. It does not support media_name, they can't be submitted together. (default: false)
  to: string # The phone number, in E.164 format, the fax will be sent to or SIP URI. (e.g. +13127367276)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/faxes"
    body: {content_type: "application/json", kind: json, fields: [{name: connection_id, var: connection_id}, {name: from, var: from}, {name: media_name, var: media_name}, {name: media_url, var: media_url}, {name: quality, var: quality}, {name: store_media, var: store_media}, {name: to, var: to}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    connection_id: $connection_id, from: $from, media_name: $media_name, media_url: $media_url, quality: $quality, store_media: $store_media, to: $to
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a fax
#
# DELETE /faxes/{id}
# operationId: DeleteFax
export def "delete-fax" [
  id: string
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
    path: "/faxes/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View a fax
#
# GET /faxes/{id}
# Returns: record<data: record<connection_id: string, created_at: string, direction: string, from: string, id: string, media_name: string, media_url: string, quality: string, record_type: string, status: string, store_media: bool, stored_media_url: string, to: string, updated_at: string, webhook_failover_url: string, webhook_url: string>>
# operationId: ViewFax
export def "view-fax" [
  id: string
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
    path: "/faxes/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Refresh a fax
#
# POST /faxes/{id}/actions/refresh
# Returns: record<result: string>
# operationId: RefreshFax
export def "refresh-fax" [
  id: string
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
    method: post
    path: "/faxes/{id}/actions/refresh"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List FQDN connections
#
# GET /fqdn_connections
# Returns: record<data: table<active: bool, anchorsite_override: string, connection_name: string, created_at: string, default_on_hold_comfort_noise_enabled: bool, dtmf_type: string, encode_contact_header_enabled: bool, encrypted_media: string, id: string, inbound: record, onnet_t38_passthrough_enabled: bool, record_type: string, rtcp_settings: record, transport_protocol: string, updated_at: string, webhook_api_version: string, webhook_event_failover_url: string, webhook_event_url: string, webhook_timeout_secs: int>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: listFqdnConnections
export def "list-fqdn-connections" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
  --filter-connection-name-contains: string # If present, connections with connection_name containing the given value will be returned. Matching is not case-sensitive. Requires at least three characters.
  --sort: string@sort-completer-2 # Specifies the sort order for results. By default sorting direction is ascending. To have the results sorted in descending order add the - prefix. That is: connection_name: sorts the result by the connection_name field in ascending order. -connection_name: sorts the result by the connection_name field in descending order. If not given, results are sorted by created_at in descending order. (default: created_at, e.g. connection_name)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/fqdn_connections"
    query: [{name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}, {name: "filter[connection_name][contains]", var: filter_connection_name_contains}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_number: $page_number, page_size: $page_size, filter_connection_name_contains: $filter_connection_name_contains, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an FQDN connection
#
# POST /fqdn_connections
# Returns: record<data: record<active: bool, anchorsite_override: string, connection_name: string, created_at: string, default_on_hold_comfort_noise_enabled: bool, dtmf_type: string, encode_contact_header_enabled: bool, encrypted_media: string, id: string, inbound: record<ani_number_format: string, channel_limit: int, codecs: list, default_routing_method: string, dnis_number_format: string, generate_ringback_tone: bool, isup_headers_enabled: bool, prack_enabled: bool, privacy_zone_enabled: bool, sip_compact_headers_enabled: bool, sip_region: string, sip_subdomain: string, sip_subdomain_receive_settings: string, timeout_1xx_secs: int, timeout_2xx_secs: int>, onnet_t38_passthrough_enabled: bool, record_type: string, rtcp_settings: record<capture_enabled: bool, port: any, report_frequency_secs: int>, transport_protocol: string, updated_at: string, webhook_api_version: string, webhook_event_failover_url: string, webhook_event_url: string, webhook_timeout_secs: int>>
# operationId: createFqdnConnection
export def "create-fqdn-connection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # Defaults to true (default: true)
  --anchorsite-override: string@anchorsite-override-completer-1 # `Latency` directs Telnyx to route media through the site with the lowest round-trip time to the user's connection. Telnyx calculates this time using ICMP ping messages. This can be disabled by specifying a site to handle all media. (default: Latency, e.g. Amsterdam, Netherlands)
  connection_name: string
  --default-on-hold-comfort-noise-enabled: oneof<nothing, bool> # When enabled, Telnyx will generate comfort noise when you place the call on hold. If disabled, you will need to generate comfort noise or on hold music to avoid RTP timeout. (default: true)
  --dtmf-type: string@dtmf-type-completer # Sets the type of DTMF digits sent from Telnyx to this Connection. Note that DTMF digits sent to Telnyx will be accepted in all formats. (default: RFC 2833, e.g. Inband)
  --encode-contact-header-enabled: oneof<nothing, bool> # Encode the SIP contact header sent by Telnyx to avoid issues for NAT or ALG scenarios. (default: false)
  --encrypted-media: string@encrypted-media-completer # Enable use of SRTP or ZRTP for encryption. Valid values are those listed or null. Cannot be set to non-null if the transport_portocol is TLS. (nullable, e.g. SRTP)
  --inbound: record # e.g. {ani_number_format: +E.164, channel_limit: 10, codecs: [G722], default_routing_method: sequential, dnis_number_format: +e164, generate_ringback_tone: true, isup_headers_enabled: true, prack_enabled: true, privacy_zone_enabled: true, sip_compact_headers_enabled: true, sip_region: US, sip_subdomain: test, sip_subdomain_receive_settings: only_my_connections, timeout_1xx_secs: 10, timeout_2xx_secs: 20} — shape: {ani_number_format?: "+E.164"|"E.164"|"+E.164-national"|"E.164-national", channel_limit?: int, codecs?: list<string>, default_routing_method?: "sequential"|"round-robin", dnis_number_format?: "+e164"|"e164"|"national"|"sip_username", generate_ringback_tone?: bool, isup_headers_enabled?: bool, prack_enabled?: bool, privacy_zone_enabled?: bool, sip_compact_headers_enabled?: bool, sip_region?: "US"|"Europe"|"Australia", sip_subdomain?: string, ... (3 more fields)}
  --onnet-t38-passthrough-enabled: oneof<nothing, bool> # Enable on-net T38 if you prefer the sender and receiver negotiating T38 directly if both are on the Telnyx network. If this is disabled, Telnyx will be able to use T38 on just one leg of the call depending on each leg's settings. (default: false)
  --rtcp-settings: record # e.g. {capture_enabled: true, port: rtcp-mux, report_frequency_secs: 10} — shape: {capture_enabled?: bool, port?: "rtcp-mux"|"rtp+1", report_frequency_secs?: int}
  --transport-protocol: string@transport-protocol-completer # One of UDP, TLS, or TCP. Applies only to connections with IP authentication or FQDN authentication. (default: UDP)
  --webhook-api-version: string@webhook-api-version-completer # Determines which webhook format will be used, Telnyx API v1 or v2. (default: 1, e.g. 1)
  --webhook-event-failover-url: string # The failover URL where webhooks related to this connection will be sent if sending to the primary URL fails. Must include a scheme, such as 'https'. (nullable, format: url, default: "", e.g. https://failover.example.com)
  --webhook-event-url: string # The URL where webhooks related to this connection will be sent. Must include a scheme, such as 'https'. (format: url, e.g. https://example.com)
  --webhook-timeout-secs: int # Specifies how many seconds to wait before timing out a webhook. (nullable, e.g. 25)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/fqdn_connections"
    body: {content_type: "application/json", kind: json, fields: [{name: active, var: active}, {name: anchorsite_override, var: anchorsite_override}, {name: connection_name, var: connection_name}, {name: default_on_hold_comfort_noise_enabled, var: default_on_hold_comfort_noise_enabled}, {name: dtmf_type, var: dtmf_type}, {name: encode_contact_header_enabled, var: encode_contact_header_enabled}, {name: encrypted_media, var: encrypted_media}, {name: inbound, var: inbound}, {name: onnet_t38_passthrough_enabled, var: onnet_t38_passthrough_enabled}, {name: rtcp_settings, var: rtcp_settings}, {name: transport_protocol, var: transport_protocol}, {name: webhook_api_version, var: webhook_api_version}, {name: webhook_event_failover_url, var: webhook_event_failover_url}, {name: webhook_event_url, var: webhook_event_url}, {name: webhook_timeout_secs, var: webhook_timeout_secs}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    active: $active, anchorsite_override: $anchorsite_override, connection_name: $connection_name, default_on_hold_comfort_noise_enabled: $default_on_hold_comfort_noise_enabled, dtmf_type: $dtmf_type, encode_contact_header_enabled: $encode_contact_header_enabled, encrypted_media: $encrypted_media, inbound: $inbound, onnet_t38_passthrough_enabled: $onnet_t38_passthrough_enabled, rtcp_settings: $rtcp_settings, transport_protocol: $transport_protocol, webhook_api_version: $webhook_api_version, webhook_event_failover_url: $webhook_event_failover_url, webhook_event_url: $webhook_event_url, webhook_timeout_secs: $webhook_timeout_secs
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an FQDN connection
#
# DELETE /fqdn_connections/{id}
# Returns: record<data: record<active: bool, anchorsite_override: string, connection_name: string, created_at: string, default_on_hold_comfort_noise_enabled: bool, dtmf_type: string, encode_contact_header_enabled: bool, encrypted_media: string, id: string, inbound: record<ani_number_format: string, channel_limit: int, codecs: list, default_routing_method: string, dnis_number_format: string, generate_ringback_tone: bool, isup_headers_enabled: bool, prack_enabled: bool, privacy_zone_enabled: bool, sip_compact_headers_enabled: bool, sip_region: string, sip_subdomain: string, sip_subdomain_receive_settings: string, timeout_1xx_secs: int, timeout_2xx_secs: int>, onnet_t38_passthrough_enabled: bool, record_type: string, rtcp_settings: record<capture_enabled: bool, port: any, report_frequency_secs: int>, transport_protocol: string, updated_at: string, webhook_api_version: string, webhook_event_failover_url: string, webhook_event_url: string, webhook_timeout_secs: int>>
# operationId: deleteFqdnConnection
export def "delete-fqdn-connection" [
  id: string
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
    method: delete
    path: "/fqdn_connections/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an FQDN connection
#
# GET /fqdn_connections/{id}
# Returns: record<data: record<active: bool, anchorsite_override: string, connection_name: string, created_at: string, default_on_hold_comfort_noise_enabled: bool, dtmf_type: string, encode_contact_header_enabled: bool, encrypted_media: string, id: string, inbound: record<ani_number_format: string, channel_limit: int, codecs: list, default_routing_method: string, dnis_number_format: string, generate_ringback_tone: bool, isup_headers_enabled: bool, prack_enabled: bool, privacy_zone_enabled: bool, sip_compact_headers_enabled: bool, sip_region: string, sip_subdomain: string, sip_subdomain_receive_settings: string, timeout_1xx_secs: int, timeout_2xx_secs: int>, onnet_t38_passthrough_enabled: bool, record_type: string, rtcp_settings: record<capture_enabled: bool, port: any, report_frequency_secs: int>, transport_protocol: string, updated_at: string, webhook_api_version: string, webhook_event_failover_url: string, webhook_event_url: string, webhook_timeout_secs: int>>
# operationId: retrieveFqdnConnection
export def "retrieve-fqdn-connection" [
  id: string
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
    path: "/fqdn_connections/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an FQDN connection
#
# PATCH /fqdn_connections/{id}
# Returns: record<data: record<active: bool, anchorsite_override: string, connection_name: string, created_at: string, default_on_hold_comfort_noise_enabled: bool, dtmf_type: string, encode_contact_header_enabled: bool, encrypted_media: string, id: string, inbound: record<ani_number_format: string, channel_limit: int, codecs: list, default_routing_method: string, dnis_number_format: string, generate_ringback_tone: bool, isup_headers_enabled: bool, prack_enabled: bool, privacy_zone_enabled: bool, sip_compact_headers_enabled: bool, sip_region: string, sip_subdomain: string, sip_subdomain_receive_settings: string, timeout_1xx_secs: int, timeout_2xx_secs: int>, onnet_t38_passthrough_enabled: bool, record_type: string, rtcp_settings: record<capture_enabled: bool, port: any, report_frequency_secs: int>, transport_protocol: string, updated_at: string, webhook_api_version: string, webhook_event_failover_url: string, webhook_event_url: string, webhook_timeout_secs: int>>
# operationId: updateFqdnConnection
export def "update-fqdn-connection" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # Defaults to true
  --anchorsite-override: string@anchorsite-override-completer-1 # `Latency` directs Telnyx to route media through the site with the lowest round-trip time to the user's connection. Telnyx calculates this time using ICMP ping messages. This can be disabled by specifying a site to handle all media. (default: Latency, e.g. Amsterdam, Netherlands)
  --connection-name: string
  --default-on-hold-comfort-noise-enabled: oneof<nothing, bool> # When enabled, Telnyx will generate comfort noise when you place the call on hold. If disabled, you will need to generate comfort noise or on hold music to avoid RTP timeout. (default: true)
  --dtmf-type: string@dtmf-type-completer # Sets the type of DTMF digits sent from Telnyx to this Connection. Note that DTMF digits sent to Telnyx will be accepted in all formats. (default: RFC 2833, e.g. Inband)
  --encode-contact-header-enabled: oneof<nothing, bool> # Encode the SIP contact header sent by Telnyx to avoid issues for NAT or ALG scenarios. (default: false)
  --encrypted-media: string@encrypted-media-completer # Enable use of SRTP or ZRTP for encryption. Valid values are those listed or null. Cannot be set to non-null if the transport_portocol is TLS. (nullable, e.g. SRTP)
  --inbound: record # e.g. {ani_number_format: +E.164, channel_limit: 10, codecs: [G722], default_routing_method: sequential, dnis_number_format: +e164, generate_ringback_tone: true, isup_headers_enabled: true, prack_enabled: true, privacy_zone_enabled: true, sip_compact_headers_enabled: true, sip_region: US, sip_subdomain: test, sip_subdomain_receive_settings: only_my_connections, timeout_1xx_secs: 10, timeout_2xx_secs: 20} — shape: {ani_number_format?: "+E.164"|"E.164"|"+E.164-national"|"E.164-national", channel_limit?: int, codecs?: list<string>, default_routing_method?: "sequential"|"round-robin", dnis_number_format?: "+e164"|"e164"|"national"|"sip_username", generate_ringback_tone?: bool, isup_headers_enabled?: bool, prack_enabled?: bool, privacy_zone_enabled?: bool, sip_compact_headers_enabled?: bool, sip_region?: "US"|"Europe"|"Australia", sip_subdomain?: string, ... (3 more fields)}
  --onnet-t38-passthrough-enabled: oneof<nothing, bool> # Enable on-net T38 if you prefer that the sender and receiver negotiate T38 directly when both are on the Telnyx network. If this is disabled, Telnyx will be able to use T38 on just one leg of the call according to each leg's settings. (default: false)
  --rtcp-settings: record # e.g. {capture_enabled: true, port: rtcp-mux, report_frequency_secs: 10} — shape: {capture_enabled?: bool, port?: "rtcp-mux"|"rtp+1", report_frequency_secs?: int}
  --transport-protocol: string@transport-protocol-completer # One of UDP, TLS, or TCP. Applies only to connections with IP authentication or FQDN authentication. (default: UDP)
  --webhook-api-version: string@webhook-api-version-completer # Determines which webhook format will be used, Telnyx API v1 or v2. (default: 1, e.g. 1)
  --webhook-event-failover-url: string # The failover URL where webhooks related to this connection will be sent if sending to the primary URL fails. Must include a scheme, such as 'https'. (nullable, format: url, default: "", e.g. https://failover.example.com)
  --webhook-event-url: string # The URL where webhooks related to this connection will be sent. Must include a scheme, such as 'https'. (format: url, e.g. https://example.com)
  --webhook-timeout-secs: int # Specifies how many seconds to wait before timing out a webhook. (nullable, e.g. 25)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/fqdn_connections/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: active, var: active}, {name: anchorsite_override, var: anchorsite_override}, {name: connection_name, var: connection_name}, {name: default_on_hold_comfort_noise_enabled, var: default_on_hold_comfort_noise_enabled}, {name: dtmf_type, var: dtmf_type}, {name: encode_contact_header_enabled, var: encode_contact_header_enabled}, {name: encrypted_media, var: encrypted_media}, {name: inbound, var: inbound}, {name: onnet_t38_passthrough_enabled, var: onnet_t38_passthrough_enabled}, {name: rtcp_settings, var: rtcp_settings}, {name: transport_protocol, var: transport_protocol}, {name: webhook_api_version, var: webhook_api_version}, {name: webhook_event_failover_url, var: webhook_event_failover_url}, {name: webhook_event_url, var: webhook_event_url}, {name: webhook_timeout_secs, var: webhook_timeout_secs}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, active: $active, anchorsite_override: $anchorsite_override, connection_name: $connection_name, default_on_hold_comfort_noise_enabled: $default_on_hold_comfort_noise_enabled, dtmf_type: $dtmf_type, encode_contact_header_enabled: $encode_contact_header_enabled, encrypted_media: $encrypted_media, inbound: $inbound, onnet_t38_passthrough_enabled: $onnet_t38_passthrough_enabled, rtcp_settings: $rtcp_settings, transport_protocol: $transport_protocol, webhook_api_version: $webhook_api_version, webhook_event_failover_url: $webhook_event_failover_url, webhook_event_url: $webhook_event_url, webhook_timeout_secs: $webhook_timeout_secs
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List FQDNs
#
# GET /fqdns
# Returns: record<data: table<connection_id: string, created_at: string, dns_record_type: string, fqdn: string, id: string, port: int, record_type: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: listFqdns
export def "list-fqdns" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
  --filter-connection-id: string # ID of the FQDN connection to which the FQDN belongs.
  --filter-fqdn: string # FQDN represented by the resource. (e.g. example.com)
  --filter-port: int # Port to use when connecting to the FQDN. (e.g. 5060)
  --filter-dns-record-type: string # DNS record type used by the FQDN. (e.g. a)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/fqdns"
    query: [{name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}, {name: "filter[connection_id]", var: filter_connection_id}, {name: "filter[fqdn]", var: filter_fqdn}, {name: "filter[port]", var: filter_port}, {name: "filter[dns_record_type]", var: filter_dns_record_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_number: $page_number, page_size: $page_size, filter_connection_id: $filter_connection_id, filter_fqdn: $filter_fqdn, filter_port: $filter_port, filter_dns_record_type: $filter_dns_record_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an FQDN
#
# POST /fqdns
# Returns: record<data: record<connection_id: string, created_at: string, dns_record_type: string, fqdn: string, id: string, port: int, record_type: string, updated_at: string>>
# operationId: createFqdn
export def "create-fqdn" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  connection_id: string # ID of the FQDN connection to which this IP should be attached.
  dns_record_type: string # The DNS record type for the FQDN. For cases where a port is not set, the DNS record type must be 'srv'. For cases where a port is set, the DNS record type must be 'a'. If the DNS record type is 'a' and a port is not specified, 5060 will be used. (e.g. a)
  fqdn: string # FQDN represented by this resource. (e.g. example.com)
  --port: int # Port to use when connecting to this FQDN. (nullable, default: 5060, e.g. 5060)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/fqdns"
    body: {content_type: "application/json", kind: json, fields: [{name: connection_id, var: connection_id}, {name: dns_record_type, var: dns_record_type}, {name: fqdn, var: fqdn}, {name: port, var: port}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    connection_id: $connection_id, dns_record_type: $dns_record_type, fqdn: $fqdn, port: $port
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an FQDN
#
# DELETE /fqdns/{id}
# Returns: record<data: record<connection_id: string, created_at: string, dns_record_type: string, fqdn: string, id: string, port: int, record_type: string, updated_at: string>>
# operationId: deleteFqdn
export def "delete-fqdn" [
  id: string
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
    method: delete
    path: "/fqdns/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an FQDN
#
# GET /fqdns/{id}
# Returns: record<data: record<connection_id: string, created_at: string, dns_record_type: string, fqdn: string, id: string, port: int, record_type: string, updated_at: string>>
# operationId: retrieveFqdn
export def "retrieve-fqdn" [
  id: string
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
    path: "/fqdns/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an FQDN
#
# PATCH /fqdns/{id}
# Returns: record<data: record<connection_id: string, created_at: string, dns_record_type: string, fqdn: string, id: string, port: int, record_type: string, updated_at: string>>
# operationId: updateFqdn
export def "update-fqdn" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --connection-id: string # ID of the FQDN connection to which this IP should be attached.
  --dns-record-type: string # The DNS record type for the FQDN. For cases where a port is not set, the DNS record type must be 'srv'. For cases where a port is set, the DNS record type must be 'a'. If the DNS record type is 'a' and a port is not specified, 5060 will be used. (e.g. a)
  --fqdn: string # FQDN represented by this resource. (e.g. example.com)
  --port: int # Port to use when connecting to this FQDN. (nullable, default: 5060, e.g. 5060)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/fqdns/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: connection_id, var: connection_id}, {name: dns_record_type, var: dns_record_type}, {name: fqdn, var: fqdn}, {name: port, var: port}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, connection_id: $connection_id, dns_record_type: $dns_record_type, fqdn: $fqdn, port: $port
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an inventory coverage request
#
# GET /inventory_coverage
# Returns: record<data: table<count: int, coverage_type: string, group: string, group_type: string, number_range: int, number_type: string, phone_number_type: string, record_type: string>, meta: record<total_results: int>>
# operationId: createInventoryCoverageRequest
export def "create-inventory-coverage-request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-npa: int # e.g. 318
  --filter-nxx: int # e.g. 202
  --filter-administrative-area: string # e.g. LA
  --filter-number-type: string@filter-number-type-completer-2 # e.g. did
  --filter-phone-number-type: string@filter-phone-number-type-completer # e.g. local
  --filter-country-code: string@filter-country-code-completer # e.g. US
  --filter-count: oneof<nothing, bool> # e.g. true
  --filter-group-by: string@filter-group-by-completer # required, e.g. nxx
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/inventory_coverage"
    query: [{name: "filter[npa]", var: filter_npa}, {name: "filter[nxx]", var: filter_nxx}, {name: "filter[administrative_area]", var: filter_administrative_area}, {name: "filter[number_type]", var: filter_number_type}, {name: "filter[phone_number_type]", var: filter_phone_number_type}, {name: "filter[country_code]", var: filter_country_code}, {name: "filter[count]", var: filter_count}, {name: "filter[groupBy]", var: filter_group_by, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter_npa: $filter_npa, filter_nxx: $filter_nxx, filter_administrative_area: $filter_administrative_area, filter_number_type: $filter_number_type, filter_phone_number_type: $filter_phone_number_type, filter_country_code: $filter_country_code, filter_count: $filter_count, filter_group_by: $filter_group_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Ip connections
#
# GET /ip_connections
# Returns: record<data: table<active: bool, anchorsite_override: string, connection_name: string, created_at: string, default_on_hold_comfort_noise_enabled: bool, dtmf_type: string, encode_contact_header_enabled: bool, encrypted_media: string, id: string, inbound: record, onnet_t38_passthrough_enabled: bool, outbound: record, record_type: string, rtcp_settings: record, transport_protocol: string, updated_at: string, webhook_api_version: string, webhook_event_failover_url: string, webhook_event_url: string, webhook_timeout_secs: int>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: listIpConnections
export def "list-ip-connections" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
  --filter-connection-name-contains: string # If present, connections with connection_name containing the given value will be returned. Matching is not case-sensitive. Requires at least three characters.
  --filter-outbound-outbound-voice-profile-id: string # Identifies the associated outbound voice profile. (format: int64, e.g. 1293384261075731499)
  --sort: string@sort-completer-2 # Specifies the sort order for results. By default sorting direction is ascending. To have the results sorted in descending order add the - prefix. That is: connection_name: sorts the result by the connection_name field in ascending order. -connection_name: sorts the result by the connection_name field in descending order. If not given, results are sorted by created_at in descending order. (default: created_at, e.g. connection_name)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/ip_connections"
    query: [{name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}, {name: "filter[connection_name][contains]", var: filter_connection_name_contains}, {name: "filter[outbound.outbound_voice_profile_id]", var: filter_outbound_outbound_voice_profile_id}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_number: $page_number, page_size: $page_size, filter_connection_name_contains: $filter_connection_name_contains, filter_outbound_outbound_voice_profile_id: $filter_outbound_outbound_voice_profile_id, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an Ip connection
#
# POST /ip_connections
# Returns: record<data: record<active: bool, anchorsite_override: string, connection_name: string, created_at: string, default_on_hold_comfort_noise_enabled: bool, dtmf_type: string, encode_contact_header_enabled: bool, encrypted_media: string, id: string, inbound: record<ani_number_format: string, channel_limit: int, codecs: list, default_primary_ip_id: string, default_routing_method: string, default_secondary_ip_id: string, default_tertiary_ip_id: string, dnis_number_format: string, generate_ringback_tone: bool, isup_headers_enabled: bool, prack_enabled: bool, privacy_zone_enabled: bool, sip_compact_headers_enabled: bool, sip_region: string, sip_subdomain: string, sip_subdomain_receive_settings: string, timeout_1xx_secs: int, timeout_2xx_secs: int>, onnet_t38_passthrough_enabled: bool, outbound: record<ani_override: string, ani_override_type: string, call_parking_enabled: bool, channel_limit: int, generate_ringback_tone: bool, instant_ringback_enabled: bool, ip_authentication_method: string, ip_authentication_token: string, localization: string, outbound_voice_profile_id: string, t38_reinvite_source: string, tech_prefix: string>, record_type: string, rtcp_settings: record<capture_enabled: bool, port: any, report_frequency_secs: int>, transport_protocol: string, updated_at: string, webhook_api_version: string, webhook_event_failover_url: string, webhook_event_url: string, webhook_timeout_secs: int>>
# operationId: createIpConnection
export def "create-ip-connection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # Defaults to true (e.g. true)
  --anchorsite-override: string@anchorsite-override-completer-1 # `Latency` directs Telnyx to route media through the site with the lowest round-trip time to the user's connection. Telnyx calculates this time using ICMP ping messages. This can be disabled by specifying a site to handle all media. (default: Latency, e.g. Amsterdam, Netherlands)
  --connection-name: string # e.g. string
  --default-on-hold-comfort-noise-enabled: oneof<nothing, bool> # When enabled, Telnyx will generate comfort noise when you place the call on hold. If disabled, you will need to generate comfort noise or on hold music to avoid RTP timeout. (default: true, e.g. true)
  --dtmf-type: string@dtmf-type-completer # Sets the type of DTMF digits sent from Telnyx to this Connection. Note that DTMF digits sent to Telnyx will be accepted in all formats. (default: RFC 2833, e.g. Inband)
  --encode-contact-header-enabled: oneof<nothing, bool> # Encode the SIP contact header sent by Telnyx to avoid issues for NAT or ALG scenarios. (default: false, e.g. true)
  --encrypted-media: string@encrypted-media-completer # Enable use of SRTP or ZRTP for encryption. Valid values are those listed or null. Cannot be set to non-null if the transport_portocol is TLS. (nullable, e.g. SRTP)
  --inbound: record # e.g. {ani_number_format: +E.164, channel_limit: 10, codecs: G722, default_routing_method: sequential, dnis_number_format: +e164, generate_ringback_tone: true, isup_headers_enabled: true, prack_enabled: true, privacy_zone_enabled: true, sip_compact_headers_enabled: true, sip_region: US, sip_subdomain: test, sip_subdomain_receive_settings: only_my_connections, timeout_1xx_secs: 10, timeout_2xx_secs: 20} — shape: {ani_number_format?: "+E.164"|"E.164"|"+E.164-national"|"E.164-national", channel_limit?: int, codecs?: list<string>, default_routing_method?: "sequential"|"round-robin", dnis_number_format?: "+e164"|"e164"|"national"|"sip_username", generate_ringback_tone?: bool, isup_headers_enabled?: bool, prack_enabled?: bool, privacy_zone_enabled?: bool, sip_compact_headers_enabled?: bool, sip_region?: "US"|"Europe"|"Australia", sip_subdomain?: string, ... (3 more fields)}
  --onnet-t38-passthrough-enabled: oneof<nothing, bool> # Enable on-net T38 if you prefer the sender and receiver negotiating T38 directly if both are on the Telnyx network. If this is disabled, Telnyx will be able to use T38 on just one leg of the call depending on each leg's settings. (default: false, e.g. false)
  --outbound: record # e.g. {ani_override: string, ani_override_type: always, call_parking_enabled: true, channel_limit: 10, generate_ringback_tone: true, instant_ringback_enabled: true, ip_authentication_method: token, ip_authentication_token: string, localization: string, outbound_voice_profile_id: 1293384261075731499, t38_reinvite_source: telnyx, tech_prefix: string} — shape: {ani_override?: string, ani_override_type?: "always"|"normal"|"emergency", call_parking_enabled?: bool, channel_limit?: int, generate_ringback_tone?: bool, instant_ringback_enabled?: bool, ip_authentication_method?: "tech-prefixp-charge-info"|"token", ip_authentication_token?: string, localization?: string, outbound_voice_profile_id?: string, t38_reinvite_source?: "telnyx"|"customer"|"disabled"|"passthru"|"caller-passthru"|"callee-passthru", tech_prefix?: string}
  --rtcp-settings: record # e.g. {capture_enabled: true, port: rtcp-mux, report_frequency_secs: 10} — shape: {capture_enabled?: bool, port?: "rtcp-mux"|"rtp+1", report_frequency_secs?: int}
  --transport-protocol: string@transport-protocol-completer # One of UDP, TLS, or TCP. Applies only to connections with IP authentication or FQDN authentication. (default: UDP, e.g. UDP)
  --webhook-api-version: string@webhook-api-version-completer # Determines which webhook format will be used, Telnyx API v1 or v2. (default: 1, e.g. 1)
  --webhook-event-failover-url: string # The failover URL where webhooks related to this connection will be sent if sending to the primary URL fails. Must include a scheme, such as 'https'. (nullable, format: url, default: "", e.g. https://failover.example.com)
  --webhook-event-url: string # The URL where webhooks related to this connection will be sent. Must include a scheme, such as 'https'. (format: url, e.g. https://example.com)
  --webhook-timeout-secs: int # Specifies how many seconds to wait before timing out a webhook. (nullable, e.g. 25)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ip_connections"
    body: {content_type: "application/json", kind: json, fields: [{name: active, var: active}, {name: anchorsite_override, var: anchorsite_override}, {name: connection_name, var: connection_name}, {name: default_on_hold_comfort_noise_enabled, var: default_on_hold_comfort_noise_enabled}, {name: dtmf_type, var: dtmf_type}, {name: encode_contact_header_enabled, var: encode_contact_header_enabled}, {name: encrypted_media, var: encrypted_media}, {name: inbound, var: inbound}, {name: onnet_t38_passthrough_enabled, var: onnet_t38_passthrough_enabled}, {name: outbound, var: outbound}, {name: rtcp_settings, var: rtcp_settings}, {name: transport_protocol, var: transport_protocol}, {name: webhook_api_version, var: webhook_api_version}, {name: webhook_event_failover_url, var: webhook_event_failover_url}, {name: webhook_event_url, var: webhook_event_url}, {name: webhook_timeout_secs, var: webhook_timeout_secs}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    active: $active, anchorsite_override: $anchorsite_override, connection_name: $connection_name, default_on_hold_comfort_noise_enabled: $default_on_hold_comfort_noise_enabled, dtmf_type: $dtmf_type, encode_contact_header_enabled: $encode_contact_header_enabled, encrypted_media: $encrypted_media, inbound: $inbound, onnet_t38_passthrough_enabled: $onnet_t38_passthrough_enabled, outbound: $outbound, rtcp_settings: $rtcp_settings, transport_protocol: $transport_protocol, webhook_api_version: $webhook_api_version, webhook_event_failover_url: $webhook_event_failover_url, webhook_event_url: $webhook_event_url, webhook_timeout_secs: $webhook_timeout_secs
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an Ip connection
#
# DELETE /ip_connections/{id}
# Returns: record<data: record<active: bool, anchorsite_override: string, connection_name: string, created_at: string, default_on_hold_comfort_noise_enabled: bool, dtmf_type: string, encode_contact_header_enabled: bool, encrypted_media: string, id: string, inbound: record<ani_number_format: string, channel_limit: int, codecs: list, default_primary_ip_id: string, default_routing_method: string, default_secondary_ip_id: string, default_tertiary_ip_id: string, dnis_number_format: string, generate_ringback_tone: bool, isup_headers_enabled: bool, prack_enabled: bool, privacy_zone_enabled: bool, sip_compact_headers_enabled: bool, sip_region: string, sip_subdomain: string, sip_subdomain_receive_settings: string, timeout_1xx_secs: int, timeout_2xx_secs: int>, onnet_t38_passthrough_enabled: bool, outbound: record<ani_override: string, ani_override_type: string, call_parking_enabled: bool, channel_limit: int, generate_ringback_tone: bool, instant_ringback_enabled: bool, ip_authentication_method: string, ip_authentication_token: string, localization: string, outbound_voice_profile_id: string, t38_reinvite_source: string, tech_prefix: string>, record_type: string, rtcp_settings: record<capture_enabled: bool, port: any, report_frequency_secs: int>, transport_protocol: string, updated_at: string, webhook_api_version: string, webhook_event_failover_url: string, webhook_event_url: string, webhook_timeout_secs: int>>
# operationId: deleteIpConnection
export def "delete-ip-connection" [
  id: string
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
    method: delete
    path: "/ip_connections/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an Ip connection
#
# GET /ip_connections/{id}
# Returns: record<data: record<active: bool, anchorsite_override: string, connection_name: string, created_at: string, default_on_hold_comfort_noise_enabled: bool, dtmf_type: string, encode_contact_header_enabled: bool, encrypted_media: string, id: string, inbound: record<ani_number_format: string, channel_limit: int, codecs: list, default_primary_ip_id: string, default_routing_method: string, default_secondary_ip_id: string, default_tertiary_ip_id: string, dnis_number_format: string, generate_ringback_tone: bool, isup_headers_enabled: bool, prack_enabled: bool, privacy_zone_enabled: bool, sip_compact_headers_enabled: bool, sip_region: string, sip_subdomain: string, sip_subdomain_receive_settings: string, timeout_1xx_secs: int, timeout_2xx_secs: int>, onnet_t38_passthrough_enabled: bool, outbound: record<ani_override: string, ani_override_type: string, call_parking_enabled: bool, channel_limit: int, generate_ringback_tone: bool, instant_ringback_enabled: bool, ip_authentication_method: string, ip_authentication_token: string, localization: string, outbound_voice_profile_id: string, t38_reinvite_source: string, tech_prefix: string>, record_type: string, rtcp_settings: record<capture_enabled: bool, port: any, report_frequency_secs: int>, transport_protocol: string, updated_at: string, webhook_api_version: string, webhook_event_failover_url: string, webhook_event_url: string, webhook_timeout_secs: int>>
# operationId: retrieveIpConnection
export def "retrieve-ip-connection" [
  id: string
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
    path: "/ip_connections/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an Ip connection
#
# PATCH /ip_connections/{id}
# Returns: record<data: record<active: bool, anchorsite_override: string, connection_name: string, created_at: string, default_on_hold_comfort_noise_enabled: bool, dtmf_type: string, encode_contact_header_enabled: bool, encrypted_media: string, id: string, inbound: record<ani_number_format: string, channel_limit: int, codecs: list, default_primary_ip_id: string, default_routing_method: string, default_secondary_ip_id: string, default_tertiary_ip_id: string, dnis_number_format: string, generate_ringback_tone: bool, isup_headers_enabled: bool, prack_enabled: bool, privacy_zone_enabled: bool, sip_compact_headers_enabled: bool, sip_region: string, sip_subdomain: string, sip_subdomain_receive_settings: string, timeout_1xx_secs: int, timeout_2xx_secs: int>, onnet_t38_passthrough_enabled: bool, outbound: record<ani_override: string, ani_override_type: string, call_parking_enabled: bool, channel_limit: int, generate_ringback_tone: bool, instant_ringback_enabled: bool, ip_authentication_method: string, ip_authentication_token: string, localization: string, outbound_voice_profile_id: string, t38_reinvite_source: string, tech_prefix: string>, record_type: string, rtcp_settings: record<capture_enabled: bool, port: any, report_frequency_secs: int>, transport_protocol: string, updated_at: string, webhook_api_version: string, webhook_event_failover_url: string, webhook_event_url: string, webhook_timeout_secs: int>>
# operationId: updateIpConnection
export def "update-ip-connection" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # Defaults to true
  --anchorsite-override: string@anchorsite-override-completer-1 # `Latency` directs Telnyx to route media through the site with the lowest round-trip time to the user's connection. Telnyx calculates this time using ICMP ping messages. This can be disabled by specifying a site to handle all media. (default: Latency, e.g. Amsterdam, Netherlands)
  --connection-name: string
  --default-on-hold-comfort-noise-enabled: oneof<nothing, bool> # When enabled, Telnyx will generate comfort noise when you place the call on hold. If disabled, you will need to generate comfort noise or on hold music to avoid RTP timeout. (default: true)
  --dtmf-type: string@dtmf-type-completer # Sets the type of DTMF digits sent from Telnyx to this Connection. Note that DTMF digits sent to Telnyx will be accepted in all formats. (default: RFC 2833, e.g. Inband)
  --encode-contact-header-enabled: oneof<nothing, bool> # Encode the SIP contact header sent by Telnyx to avoid issues for NAT or ALG scenarios. (default: false)
  --encrypted-media: string@encrypted-media-completer # Enable use of SRTP or ZRTP for encryption. Valid values are those listed or null. Cannot be set to non-null if the transport_portocol is TLS. (nullable, e.g. SRTP)
  --inbound: record # e.g. {ani_number_format: +E.164, channel_limit: 10, codecs: G722, default_primary_ip_id: 192.168.0.0, default_routing_method: sequential, default_secondary_ip_id: 192.168.0.0, default_tertiary_ip_id: 192.168.0.0, dns_number_format: +e164, generate_ringback_tone: true, isup_headers_enabled: true, prack_enabled: true, privacy_zone_enabled: true, sip_compact_headers_enabled: true, sip_region: US, sip_subdomain: test, sip_subdomain_receive_settings: only_my_connections, timeout_1xx_secs: 10, timeout_2xx_secs: 20} — shape: {ani_number_format?: "+E.164"|"E.164"|"+E.164-national"|"E.164-national", channel_limit?: int, codecs?: list<string>, default_primary_ip_id?: string, default_routing_method?: "sequential"|"round-robin", default_secondary_ip_id?: string, default_tertiary_ip_id?: string, dnis_number_format?: "+e164"|"e164"|"national"|"sip_username", generate_ringback_tone?: bool, isup_headers_enabled?: bool, prack_enabled?: bool, privacy_zone_enabled?: bool, sip_compact_headers_enabled?: bool, ... (5 more fields)}
  --onnet-t38-passthrough-enabled: oneof<nothing, bool> # Enable on-net T38 if you prefer the sender and receiver negotiating T38 directly if both are on the Telnyx network. If this is disabled, Telnyx will be able to use T38 on just one leg of the call depending on each leg's settings. (default: false)
  --outbound: record # e.g. {ani_override: string, ani_override_type: always, call_parking_enabled: true, channel_limit: 10, generate_ringback_tone: true, instant_ringback_enabled: true, ip_authentication_method: token, ip_authentication_token: string, localization: string, outbound_voice_profile_id: 1293384261075731499, t38_reinvite_source: telnyx, tech_prefix: string} — shape: {ani_override?: string, ani_override_type?: "always"|"normal"|"emergency", call_parking_enabled?: bool, channel_limit?: int, generate_ringback_tone?: bool, instant_ringback_enabled?: bool, ip_authentication_method?: "tech-prefixp-charge-info"|"token", ip_authentication_token?: string, localization?: string, outbound_voice_profile_id?: string, t38_reinvite_source?: "telnyx"|"customer"|"disabled"|"passthru"|"caller-passthru"|"callee-passthru", tech_prefix?: string}
  --rtcp-settings: record # e.g. {capture_enabled: true, port: rtcp-mux, report_frequency_secs: 10} — shape: {capture_enabled?: bool, port?: "rtcp-mux"|"rtp+1", report_frequency_secs?: int}
  --transport-protocol: string@transport-protocol-completer # One of UDP, TLS, or TCP. Applies only to connections with IP authentication or FQDN authentication. (default: UDP)
  --webhook-api-version: string@webhook-api-version-completer # Determines which webhook format will be used, Telnyx API v1 or v2. (default: 1, e.g. 1)
  --webhook-event-failover-url: string # The failover URL where webhooks related to this connection will be sent if sending to the primary URL fails. Must include a scheme, such as 'https'. (nullable, format: url, default: "", e.g. https://failover.example.com)
  --webhook-event-url: string # The URL where webhooks related to this connection will be sent. Must include a scheme, such as 'https'. (format: url, e.g. https://example.com)
  --webhook-timeout-secs: int # Specifies how many seconds to wait before timing out a webhook. (nullable, e.g. 25)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/ip_connections/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: active, var: active}, {name: anchorsite_override, var: anchorsite_override}, {name: connection_name, var: connection_name}, {name: default_on_hold_comfort_noise_enabled, var: default_on_hold_comfort_noise_enabled}, {name: dtmf_type, var: dtmf_type}, {name: encode_contact_header_enabled, var: encode_contact_header_enabled}, {name: encrypted_media, var: encrypted_media}, {name: inbound, var: inbound}, {name: onnet_t38_passthrough_enabled, var: onnet_t38_passthrough_enabled}, {name: outbound, var: outbound}, {name: rtcp_settings, var: rtcp_settings}, {name: transport_protocol, var: transport_protocol}, {name: webhook_api_version, var: webhook_api_version}, {name: webhook_event_failover_url, var: webhook_event_failover_url}, {name: webhook_event_url, var: webhook_event_url}, {name: webhook_timeout_secs, var: webhook_timeout_secs}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, active: $active, anchorsite_override: $anchorsite_override, connection_name: $connection_name, default_on_hold_comfort_noise_enabled: $default_on_hold_comfort_noise_enabled, dtmf_type: $dtmf_type, encode_contact_header_enabled: $encode_contact_header_enabled, encrypted_media: $encrypted_media, inbound: $inbound, onnet_t38_passthrough_enabled: $onnet_t38_passthrough_enabled, outbound: $outbound, rtcp_settings: $rtcp_settings, transport_protocol: $transport_protocol, webhook_api_version: $webhook_api_version, webhook_event_failover_url: $webhook_event_failover_url, webhook_event_url: $webhook_event_url, webhook_timeout_secs: $webhook_timeout_secs
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Ips
#
# GET /ips
# Returns: record<data: table<connection_id: string, created_at: string, id: string, ip_address: string, port: int, record_type: string, updated_at: string>>
# operationId: listIps
export def "list-ips" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
  --filter-connection-id: string # ID of the IP Connection to which this IP should be attached.
  --filter-ip-address: string # IP adddress represented by this resource. (e.g. 192.168.0.0)
  --filter-port: int # Port to use when connecting to this IP. (e.g. 5060)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/ips"
    query: [{name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}, {name: "filter[connection_id]", var: filter_connection_id}, {name: "filter[ip_address]", var: filter_ip_address}, {name: "filter[port]", var: filter_port}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_number: $page_number, page_size: $page_size, filter_connection_id: $filter_connection_id, filter_ip_address: $filter_ip_address, filter_port: $filter_port
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an Ip
#
# POST /ips
# Returns: record<data: record<connection_id: string, created_at: string, id: string, ip_address: string, port: int, record_type: string, updated_at: string>>
# operationId: createIp
export def "create-ip" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --connection-id: string # ID of the IP Connection to which this IP should be attached.
  ip_address: string # IP adddress represented by this resource. (e.g. 192.168.0.0)
  --port: int # Port to use when connecting to this IP. (default: 5060, e.g. 5060)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ips"
    body: {content_type: "application/json", kind: json, fields: [{name: connection_id, var: connection_id}, {name: ip_address, var: ip_address}, {name: port, var: port}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    connection_id: $connection_id, ip_address: $ip_address, port: $port
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an Ip
#
# DELETE /ips/{id}
# Returns: record<data: record<connection_id: string, created_at: string, id: string, ip_address: string, port: int, record_type: string, updated_at: string>>
# operationId: deleteIp
export def "delete-ip" [
  id: string
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
    method: delete
    path: "/ips/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an Ip
#
# GET /ips/{id}
# Returns: record<data: record<connection_id: string, created_at: string, id: string, ip_address: string, port: int, record_type: string, updated_at: string>>
# operationId: retrieveIp
export def "retrieve-ip" [
  id: string
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
    path: "/ips/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an Ip
#
# PATCH /ips/{id}
# Returns: record<data: record<connection_id: string, created_at: string, id: string, ip_address: string, port: int, record_type: string, updated_at: string>>
# operationId: updateIp
export def "update-ip" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --connection-id: string # ID of the IP Connection to which this IP should be attached.
  ip_address: string # IP adddress represented by this resource. (e.g. 192.168.0.0)
  --port: int # Port to use when connecting to this IP. (default: 5060, e.g. 5060)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/ips/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: connection_id, var: connection_id}, {name: ip_address, var: ip_address}, {name: port, var: port}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, connection_id: $connection_id, ip_address: $ip_address, port: $port
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a ledger billing group report
#
# POST /ledger_billing_group_reports
# Returns: record<data: record<created_at: string, id: string, organization_id: string, record_type: string, report_url: string, status: string, updated_at: string>>
# operationId: createLedgerBillingGroupReport
export def "create-ledger-billing-group-report" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --month: int # Month of the ledger billing group report (e.g. 10)
  --year: int # Year of the ledger billing group report (e.g. 2019)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ledger_billing_group_reports"
    body: {content_type: "application/json", kind: json, fields: [{name: month, var: month}, {name: year, var: year}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    month: $month, year: $year
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a ledger billing group report
#
# GET /ledger_billing_group_reports/{id}
# Returns: record<data: record<created_at: string, id: string, organization_id: string, record_type: string, report_url: string, status: string, updated_at: string>>
# operationId: retrieveLedgerBillingGroupReport
export def "retrieve-ledger-billing-group-report" [
  id: string
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
    path: "/ledger_billing_group_reports/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists accounts managed by the current user.
#
# GET /managed_accounts
# Returns: record<data: table<api_key: string, api_token: string, api_user: string, balance: record, created_at: string, email: string, id: string, manager_account_id: string, organization_name: string, record_type: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: listManagedAccounts
export def "list-managed-accounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
  --filter-email-contains: string # If present, email containing the given value will be returned. Matching is not case-sensitive. Requires at least three characters. (default: null)
  --filter-email-eq: string # If present, only returns results with the email matching exactly the value given. (default: null)
  --sort: string@sort-completer-3 # Specifies the sort order for results. By default sorting direction is ascending. To have the results sorted in descending order add the - prefix. That is: email: sorts the result by the email field in ascending order. -email: sorts the result by the email field in descending order. If not given, results are sorted by created_at in descending order. (default: created_at, e.g. email)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/managed_accounts"
    query: [{name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}, {name: "filter[email][contains]", var: filter_email_contains}, {name: "filter[email][eq]", var: filter_email_eq}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_number: $page_number, page_size: $page_size, filter_email_contains: $filter_email_contains, filter_email_eq: $filter_email_eq, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new managed account.
#
# POST /managed_accounts
# Returns: record<data: record<api_key: string, api_token: string, api_user: string, balance: record<available_credit: string, balance: string, credit_limit: string, currency: string, record_type: string>, created_at: string, email: string, id: string, manager_account_id: string, organization_name: string, record_type: string, updated_at: string>>
# operationId: createManagedAccount
export def "create-managed-account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  business_name: string # The name of the business for which the new managed account is being created, that will be used as the managed accounts's organization's name. (e.g. Larry's Cat Food Inc)
  --email: string # The email address for the managed account. If not provided, the email address will be generated based on the email address of the manager account. (e.g. new_managed_account@customer.org)
  --password: string # Password for the managed account. If a password is not supplied, the account will not be able to be signed into directly. (A password reset may still be performed later to enable sign-in via password.) (e.g. 3jVjLq!tMuWKyWx4NN*CvhnB)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/managed_accounts"
    body: {content_type: "application/json", kind: json, fields: [{name: business_name, var: business_name}, {name: email, var: email}, {name: password, var: password}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    business_name: $business_name, email: $email, password: $password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a managed account
#
# GET /managed_accounts/{id}
# Returns: record<data: record<api_key: string, api_token: string, api_user: string, balance: record<available_credit: string, balance: string, credit_limit: string, currency: string, record_type: string>, created_at: string, email: string, id: string, manager_account_id: string, organization_name: string, record_type: string, updated_at: string>>
# operationId: retrieveManagedAccount
export def "retrieve-managed-account" [
  id: string
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
    path: "/managed_accounts/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disables a managed account
#
# POST /managed_accounts/{id}/actions/disable
# Returns: record<data: record<api_key: string, api_token: string, api_user: string, balance: record<available_credit: string, balance: string, credit_limit: string, currency: string, record_type: string>, created_at: string, email: string, id: string, manager_account_id: string, organization_name: string, record_type: string, updated_at: string>>
# operationId: disableManagedAccount
export def "disable-managed-account" [
  id: string
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
    method: post
    path: "/managed_accounts/{id}/actions/disable"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enables a managed account
#
# POST /managed_accounts/{id}/actions/enable
# Returns: record<data: record<api_key: string, api_token: string, api_user: string, balance: record<available_credit: string, balance: string, credit_limit: string, currency: string, record_type: string>, created_at: string, email: string, id: string, manager_account_id: string, organization_name: string, record_type: string, updated_at: string>>
# operationId: enableManagedAccount
export def "enable-managed-account" [
  id: string
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
    method: post
    path: "/managed_accounts/{id}/actions/enable"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List uploaded media
#
# GET /media
# Returns: record<data: table<created_at: string, expires_at: string, media_name: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: listMedia
export def "list-media" [
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
    path: "/media"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload media
#
# POST /media
# Returns: record<data: record<created_at: string, expires_at: string, media_name: string, updated_at: string>>
# operationId: createMedia
export def "create-media" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --media-name: string # The unique identifier of a file. (e.g. my_file)
  media_url: string # The URL where the media to be stored in Telnyx network is currently hosted. The maximum allowed size is 20 MB. (e.g. http://www.example.com/audio.mp3)
  --ttl-secs: int # The number of seconds after which the media resource will be deleted, defaults to 2 days. (e.g. 86400)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/media"
    body: {content_type: "application/json", kind: json, fields: [{name: media_name, var: media_name}, {name: media_url, var: media_url}, {name: ttl_secs, var: ttl_secs}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    media_name: $media_name, media_url: $media_url, ttl_secs: $ttl_secs
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes stored media
#
# DELETE /media/{media_name}
# operationId: deleteMedia
export def "delete-media" [
  media_name: string
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
    path: "/media/{media_name}"
    path_params: [{name: media_name, var: media_name}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    media_name: $media_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve stored media
#
# GET /media/{media_name}
# Returns: record<data: record<created_at: string, expires_at: string, media_name: string, updated_at: string>>
# operationId: getMedia
export def "get-media" [
  media_name: string
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
    path: "/media/{media_name}"
    path_params: [{name: media_name, var: media_name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    media_name: $media_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update stored media
#
# PUT /media/{media_name}
# Returns: record<data: record<created_at: string, expires_at: string, media_name: string, updated_at: string>>
# operationId: updateMedia
export def "update-media" [
  media_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --media-url: string # The URL where the media to be stored in Telnyx network is currently hosted. The maximum allowed size is 20 MB. (e.g. http://www.example.com/audio.mp3)
  --ttl-secs: int # The number of seconds after which the media resource will be deleted, defaults to 2 days. (e.g. 86400)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/media/{media_name}"
    path_params: [{name: media_name, var: media_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: media_url, var: media_url}, {name: ttl_secs, var: ttl_secs}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    media_name: $media_name, media_url: $media_url, ttl_secs: $ttl_secs
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download stored media
#
# GET /media/{media_name}/download
# Returns: binary
# operationId: downloadMedia
export def "download-media" [
  media_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> any {
  http-request {
    method: get
    path: "/media/{media_name}/download"
    path_params: [{name: media_name, var: media_name}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    media_name: $media_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Fetch messaging detail records.
#
# GET /message_detail_records
# Returns: record<data: table<cld: string, cli: string, cost: string, created_at: string, currency: string, direction: string, id: string, message_type: string, parts: float, profile_name: string, rate: string, record_type: string, status: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: getPaginatedMdrs
export def "get-paginated-mdrs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # Start date (required, format: date-time, e.g. 2020-07-01T00:00:00-06:00)
  --end-date: string # End date (required, format: date-time, e.g. 2020-07-01T00:00:00-06:00)
  --id: string # e.g. e093fbe0-5bde-11eb-ae93-0242ac130002
  --direction: string@direction-completer
  --outbound-profile-id: string # e.g. 30ef55db-c4a2-4c4a-9804-a68077973d07
  --cld: string # e.g. +15551237654
  --cli: string # e.g. +15551237654
  --status: string@status-completer-1 # e.g. DELIVERED
  --message-type: string@message-type-completer # default: text
  --country-iso: string # e.g. US
  --error: string # e.g. 40001
  --normalized-carrier: string # e.g. Verizon
  --tag: string # e.g. Tag1
  --mcc: string # e.g. 204
  --mnc: string # e.g. 01
  --product: string@product-completer # e.g. LONG_CODE
  --page-number: int # Page number (format: int32, default: 1)
  --page-size: int # Size of the page (format: int32, default: 20)
  --sort: list<string> # default: created_at, e.g. created_at
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/message_detail_records"
    query: [{name: start_date, var: start_date, required: true}, {name: end_date, var: end_date, required: true}, {name: id, var: id}, {name: direction, var: direction}, {name: outbound_profile_id, var: outbound_profile_id}, {name: cld, var: cld}, {name: cli, var: cli}, {name: status, var: status}, {name: message_type, var: message_type}, {name: country_iso, var: country_iso}, {name: error, var: error}, {name: normalized_carrier, var: normalized_carrier}, {name: tag, var: tag}, {name: mcc, var: mcc}, {name: mnc, var: mnc}, {name: product, var: product}, {name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}, {name: sort, var: sort, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    start_date: $start_date, end_date: $end_date, id: $id, direction: $direction, outbound_profile_id: $outbound_profile_id, cld: $cld, cli: $cli, status: $status, message_type: $message_type, country_iso: $country_iso, error: $error, normalized_carrier: $normalized_carrier, tag: $tag, mcc: $mcc, mnc: $mnc, product: $product, page_number: $page_number, page_size: $page_size, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch message body by id.
#
# GET /message_detail_records/{id}/message_body
# Returns: record<data: record<message_body: string, record_type: string>>
# operationId: getMdrMessageBody
export def "get-mdr-message-body" [
  id: string
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
    path: "/message_detail_records/{id}/message_body"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send a message
#
# POST /messages
# Returns: record<data: record<completed_at: string, cost: record<amount: string, currency: string>, direction: string, encoding: string, errors: list<record>, from: record<carrier: string, line_type: string, phone_number: string>, id: string, media: list<record>, messaging_profile_id: string, organization_id: string, parts: int, received_at: string, record_type: string, sent_at: string, subject: string, tags: list<string>, text: string, to: list<record>, type: string, valid_until: string, webhook_failover_url: string, webhook_url: string>>
# operationId: createMessage
export def "create-message" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-detect: oneof<nothing, bool> # Automatically detect if an SMS message is unusually long and exceeds a recommended limit of message parts. (default: false)
  --from: string # Sending address (+E.164 formatted phone number, alphanumeric sender ID, or short code). **Required if sending with a phone number, short code, or alphanumeric sender ID.** (format: address)
  --media-urls: list<string> # A list of media URLs. The total media size must be less than 1 MB. **Required for MMS**
  --messaging-profile-id: string # Unique identifier for a messaging profile. **Required if sending via number pool or with an alphanumeric sender ID.**
  --subject: string # Subject of multimedia message
  --text: string # Message body (i.e., content) as a non-empty string. **Required for SMS**
  to: string # Receiving address (+E.164 formatted phone number or short code). (format: address, e.g. +E.164)
  --type: string@type-completer # The protocol for sending the message, either SMS or MMS.
  --use-profile-webhooks: oneof<nothing, bool> # If the profile this number is associated with has webhooks, use them for delivery notifications. If webhooks are also specified on the message itself, they will be attempted first, then those on the profile. (default: true)
  --webhook-failover-url: string # The failover URL where webhooks related to this message will be sent if sending to the primary URL fails. (format: url)
  --webhook-url: string # The URL where webhooks related to this message will be sent. (format: url)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/messages"
    body: {content_type: "application/json", kind: json, fields: [{name: auto_detect, var: auto_detect}, {name: from, var: from}, {name: media_urls, var: media_urls}, {name: messaging_profile_id, var: messaging_profile_id}, {name: subject, var: subject}, {name: text, var: text}, {name: to, var: to}, {name: type, var: type}, {name: use_profile_webhooks, var: use_profile_webhooks}, {name: webhook_failover_url, var: webhook_failover_url}, {name: webhook_url, var: webhook_url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    auto_detect: $auto_detect, from: $from, media_urls: $media_urls, messaging_profile_id: $messaging_profile_id, subject: $subject, text: $text, to: $to, type: $type, use_profile_webhooks: $use_profile_webhooks, webhook_failover_url: $webhook_failover_url, webhook_url: $webhook_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send a long code message
#
# POST /messages/long_code
# Returns: record<data: record<completed_at: string, cost: record<amount: string, currency: string>, direction: string, encoding: string, errors: list<record>, from: record<carrier: string, line_type: string, phone_number: string>, id: string, media: list<record>, messaging_profile_id: string, organization_id: string, parts: int, received_at: string, record_type: string, sent_at: string, subject: string, tags: list<string>, text: string, to: list<record>, type: string, valid_until: string, webhook_failover_url: string, webhook_url: string>>
# operationId: createLongCodeMessage
export def "create-long-code-message" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-detect: oneof<nothing, bool> # Automatically detect if an SMS message is unusually long and exceeds a recommended limit of message parts. (default: false)
  from: string # Phone number, in +E.164 format, used to send the message. (format: address)
  --media-urls: list<string> # A list of media URLs. The total media size must be less than 1 MB. **Required for MMS**
  --subject: string # Subject of multimedia message
  --text: string # Message body (i.e., content) as a non-empty string. **Required for SMS**
  to: string # Receiving address (+E.164 formatted phone number or short code). (format: address, e.g. +E.164)
  --type: string@type-completer # The protocol for sending the message, either SMS or MMS.
  --use-profile-webhooks: oneof<nothing, bool> # If the profile this number is associated with has webhooks, use them for delivery notifications. If webhooks are also specified on the message itself, they will be attempted first, then those on the profile. (default: true)
  --webhook-failover-url: string # The failover URL where webhooks related to this message will be sent if sending to the primary URL fails. (format: url)
  --webhook-url: string # The URL where webhooks related to this message will be sent. (format: url)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/messages/long_code"
    body: {content_type: "application/json", kind: json, fields: [{name: auto_detect, var: auto_detect}, {name: from, var: from}, {name: media_urls, var: media_urls}, {name: subject, var: subject}, {name: text, var: text}, {name: to, var: to}, {name: type, var: type}, {name: use_profile_webhooks, var: use_profile_webhooks}, {name: webhook_failover_url, var: webhook_failover_url}, {name: webhook_url, var: webhook_url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    auto_detect: $auto_detect, from: $from, media_urls: $media_urls, subject: $subject, text: $text, to: $to, type: $type, use_profile_webhooks: $use_profile_webhooks, webhook_failover_url: $webhook_failover_url, webhook_url: $webhook_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send a message using number pool
#
# POST /messages/number_pool
# Returns: record<data: record<completed_at: string, cost: record<amount: string, currency: string>, direction: string, encoding: string, errors: list<record>, from: record<carrier: string, line_type: string, phone_number: string>, id: string, media: list<record>, messaging_profile_id: string, organization_id: string, parts: int, received_at: string, record_type: string, sent_at: string, subject: string, tags: list<string>, text: string, to: list<record>, type: string, valid_until: string, webhook_failover_url: string, webhook_url: string>>
# operationId: createNumberPoolMessage
export def "create-number-pool-message" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-detect: oneof<nothing, bool> # Automatically detect if an SMS message is unusually long and exceeds a recommended limit of message parts. (default: false)
  --media-urls: list<string> # A list of media URLs. The total media size must be less than 1 MB. **Required for MMS**
  messaging_profile_id: string # Unique identifier for a messaging profile.
  --subject: string # Subject of multimedia message
  --text: string # Message body (i.e., content) as a non-empty string. **Required for SMS**
  to: string # Receiving address (+E.164 formatted phone number or short code). (format: address, e.g. +E.164)
  --type: string@type-completer # The protocol for sending the message, either SMS or MMS.
  --use-profile-webhooks: oneof<nothing, bool> # If the profile this number is associated with has webhooks, use them for delivery notifications. If webhooks are also specified on the message itself, they will be attempted first, then those on the profile. (default: true)
  --webhook-failover-url: string # The failover URL where webhooks related to this message will be sent if sending to the primary URL fails. (format: url)
  --webhook-url: string # The URL where webhooks related to this message will be sent. (format: url)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/messages/number_pool"
    body: {content_type: "application/json", kind: json, fields: [{name: auto_detect, var: auto_detect}, {name: media_urls, var: media_urls}, {name: messaging_profile_id, var: messaging_profile_id}, {name: subject, var: subject}, {name: text, var: text}, {name: to, var: to}, {name: type, var: type}, {name: use_profile_webhooks, var: use_profile_webhooks}, {name: webhook_failover_url, var: webhook_failover_url}, {name: webhook_url, var: webhook_url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    auto_detect: $auto_detect, media_urls: $media_urls, messaging_profile_id: $messaging_profile_id, subject: $subject, text: $text, to: $to, type: $type, use_profile_webhooks: $use_profile_webhooks, webhook_failover_url: $webhook_failover_url, webhook_url: $webhook_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send a short code message
#
# POST /messages/short_code
# Returns: record<data: record<completed_at: string, cost: record<amount: string, currency: string>, direction: string, encoding: string, errors: list<record>, from: record<carrier: string, line_type: string, phone_number: string>, id: string, media: list<record>, messaging_profile_id: string, organization_id: string, parts: int, received_at: string, record_type: string, sent_at: string, subject: string, tags: list<string>, text: string, to: list<record>, type: string, valid_until: string, webhook_failover_url: string, webhook_url: string>>
# operationId: createShortCodeMessage
export def "create-short-code-message" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-detect: oneof<nothing, bool> # Automatically detect if an SMS message is unusually long and exceeds a recommended limit of message parts. (default: false)
  from: string # Phone number, in +E.164 format, used to send the message. (format: address)
  --media-urls: list<string> # A list of media URLs. The total media size must be less than 1 MB. **Required for MMS**
  --subject: string # Subject of multimedia message
  --text: string # Message body (i.e., content) as a non-empty string. **Required for SMS**
  to: string # Receiving address (+E.164 formatted phone number or short code). (format: address, e.g. +E.164)
  --type: string@type-completer # The protocol for sending the message, either SMS or MMS.
  --use-profile-webhooks: oneof<nothing, bool> # If the profile this number is associated with has webhooks, use them for delivery notifications. If webhooks are also specified on the message itself, they will be attempted first, then those on the profile. (default: true)
  --webhook-failover-url: string # The failover URL where webhooks related to this message will be sent if sending to the primary URL fails. (format: url)
  --webhook-url: string # The URL where webhooks related to this message will be sent. (format: url)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/messages/short_code"
    body: {content_type: "application/json", kind: json, fields: [{name: auto_detect, var: auto_detect}, {name: from, var: from}, {name: media_urls, var: media_urls}, {name: subject, var: subject}, {name: text, var: text}, {name: to, var: to}, {name: type, var: type}, {name: use_profile_webhooks, var: use_profile_webhooks}, {name: webhook_failover_url, var: webhook_failover_url}, {name: webhook_url, var: webhook_url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    auto_detect: $auto_detect, from: $from, media_urls: $media_urls, subject: $subject, text: $text, to: $to, type: $type, use_profile_webhooks: $use_profile_webhooks, webhook_failover_url: $webhook_failover_url, webhook_url: $webhook_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a message
#
# GET /messages/{id}
# Returns: record<data: record<completed_at: string, cost: record<amount: string, currency: string>, direction: string, encoding: string, errors: list<record>, from: record<carrier: string, line_type: string, phone_number: string>, id: string, media: list<record>, messaging_profile_id: string, organization_id: string, parts: int, received_at: string, record_type: string, sent_at: string, subject: string, tags: list<string>, text: string, to: list<record>, type: string, valid_until: string, webhook_failover_url: string, webhook_url: string>>
# operationId: retrieveMessage
export def "retrieve-message" [
  id: string
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
    path: "/messages/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List messaging hosted number orders
#
# GET /messaging_hosted_number_orders
# Returns: record<data: table<id: string, messaging_profile_id: string, phone_numbers: list, record_type: string, status: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: listMessagingHostedNumberOrder
export def "list-messaging-hosted-number-order" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/messaging_hosted_number_orders"
    query: [{name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_number: $page_number, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a messaging hosted number order
#
# POST /messaging_hosted_number_orders
# Returns: record<data: record<id: string, messaging_profile_id: string, phone_numbers: list<record>, record_type: string, status: string>>
# operationId: createMessagingHostedNumberOrder
export def "create-messaging-hosted-number-order" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --messaging-profile-id: string # Automatically associate the number with this messaging profile ID when the order is complete.
  --phone-numbers: list<string> # Phone numbers to be used for hosted messaging.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/messaging_hosted_number_orders"
    body: {content_type: "application/json", kind: json, fields: [{name: messaging_profile_id, var: messaging_profile_id}, {name: phone_numbers, var: phone_numbers}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    messaging_profile_id: $messaging_profile_id, phone_numbers: $phone_numbers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a messaging hosted number order
#
# GET /messaging_hosted_number_orders/{id}
# Returns: record<data: record<id: string, messaging_profile_id: string, phone_numbers: list<record>, record_type: string, status: string>>
# operationId: retrieveMessagingHostedNumberOrder
export def "retrieve-messaging-hosted-number-order" [
  id: string
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
    path: "/messaging_hosted_number_orders/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload file required for a messaging hosted number order
#
# POST /messaging_hosted_number_orders/{id}/actions/file_upload
# Returns: record<data: record<id: string, messaging_profile_id: string, phone_numbers: list<record>, record_type: string, status: string>>
# operationId: uploadFileMessagingHostedNumberOrder
export def "upload-file-messaging-hosted-number-order" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --bill: string # Must be the last month's bill with proof of ownership of all of the numbers in the order in PDF format. (format: binary)
  --loa: string # Must be a signed LOA for the numbers in the order in PDF format. (format: binary)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/messaging_hosted_number_orders/{id}/actions/file_upload"
    path_params: [{name: id, var: id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: bill, var: bill}, {name: loa, var: loa}], files: [bill, loa]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, bill: $bill, loa: $loa
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a messaging hosted number
#
# DELETE /messaging_hosted_numbers/{id}
# Returns: record<data: record<id: string, phone_number: string, record_type: string, status: string>>
# operationId: deleteMessagingHostedNumber
export def "delete-messaging-hosted-number" [
  id: string
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
    method: delete
    path: "/messaging_hosted_numbers/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List messaging profile metrics
#
# GET /messaging_profile_metrics
# Returns: record<data: table<inbound: record, messaging_profile_id: string, outbound: record, phone_numbers: float, record_type: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: listMessagingProfileMetrics
export def "list-messaging-profile-metrics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
  --id: string # The id of the messaging profile(s) to retrieve (format: uuid)
  --time-frame: string@time-frame-completer # The timeframe for which you'd like to retrieve metrics. (default: 24h)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/messaging_profile_metrics"
    query: [{name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}, {name: id, var: id}, {name: time_frame, var: time_frame}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_number: $page_number, page_size: $page_size, id: $id, time_frame: $time_frame
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List messaging profiles
#
# GET /messaging_profiles
# Returns: record<data: table<created_at: string, enabled: bool, id: string, name: string, number_pool_settings: record, record_type: string, updated_at: string, url_shortener_settings: record, v1_secret: string, webhook_api_version: string, webhook_failover_url: string, webhook_url: string, whitelisted_destinations: list>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: listMessagingProfiles
export def "list-messaging-profiles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/messaging_profiles"
    query: [{name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_number: $page_number, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a messaging profile
#
# POST /messaging_profiles
# Returns: record<data: record<created_at: string, enabled: bool, id: string, name: string, number_pool_settings: record<geomatch: bool, long_code_weight: float, skip_unhealthy: bool, sticky_sender: bool, toll_free_weight: float>, record_type: string, updated_at: string, url_shortener_settings: record<domain: string, prefix: string, replace_blacklist_only: bool, send_webhooks: bool>, v1_secret: string, webhook_api_version: string, webhook_failover_url: string, webhook_url: string, whitelisted_destinations: list<string>>>
# operationId: createMessagingProfile
export def "create-messaging-profile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool> # Specifies whether the messaging profile is enabled or not. (default: true)
  name: string # A user friendly name for the messaging profile.
  --number-pool-settings: record # Number Pool allows you to send messages from a pool of numbers of different types, assigning weights to each type. The pool consists of all the long code and toll free numbers assigned to the messaging profile. To disable this feature, set the object field to `null`. (nullable, e.g. {geomatch: false, long_code_weight: 1, skip_unhealthy: true, sticky_sender: false, toll_free_weight: 10}) — shape: {geomatch?: bool, long_code_weight: float, skip_unhealthy: bool, sticky_sender?: bool, toll_free_weight: float}
  --url-shortener-settings: record # The URL shortener feature allows automatic replacement of URLs that were generated using a public URL shortener service. Some examples include bit.do, bit.ly, goo.gl, ht.ly, is.gd, ow.ly, rebrand.ly, t.co, tiny.cc, and tinyurl.com. Such URLs are replaced with with links generated by Telnyx. The use of custom links can improve branding and message deliverability. To disable this feature, set the object field to `null`. (nullable, e.g. {domain: example.ex, prefix: , replace_blacklist_only: true, send_webhooks: false}) — shape: {domain: string, prefix?: string, replace_blacklist_only?: bool, send_webhooks?: bool}
  --webhook-api-version: string@webhook-api-version-completer-1 # Determines which webhook format will be used, Telnyx API v1, v2, or a legacy 2010-04-01 format. (default: 2)
  --webhook-failover-url: string # The failover URL where webhooks related to this messaging profile will be sent if sending to the primary URL fails. (nullable, format: url, default: "")
  --webhook-url: string # The URL where webhooks related to this messaging profile will be sent. (nullable, format: url, default: "")
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/messaging_profiles"
    body: {content_type: "application/json", kind: json, fields: [{name: enabled, var: enabled}, {name: name, var: name}, {name: number_pool_settings, var: number_pool_settings}, {name: url_shortener_settings, var: url_shortener_settings}, {name: webhook_api_version, var: webhook_api_version}, {name: webhook_failover_url, var: webhook_failover_url}, {name: webhook_url, var: webhook_url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    enabled: $enabled, name: $name, number_pool_settings: $number_pool_settings, url_shortener_settings: $url_shortener_settings, webhook_api_version: $webhook_api_version, webhook_failover_url: $webhook_failover_url, webhook_url: $webhook_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a messaging profile
#
# DELETE /messaging_profiles/{id}
# Returns: record<data: record<created_at: string, enabled: bool, id: string, name: string, number_pool_settings: record<geomatch: bool, long_code_weight: float, skip_unhealthy: bool, sticky_sender: bool, toll_free_weight: float>, record_type: string, updated_at: string, url_shortener_settings: record<domain: string, prefix: string, replace_blacklist_only: bool, send_webhooks: bool>, v1_secret: string, webhook_api_version: string, webhook_failover_url: string, webhook_url: string, whitelisted_destinations: list<string>>>
# operationId: deleteMessagingProfile
export def "delete-messaging-profile" [
  id: string
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
    method: delete
    path: "/messaging_profiles/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a messaging profile
#
# GET /messaging_profiles/{id}
# Returns: record<data: record<created_at: string, enabled: bool, id: string, name: string, number_pool_settings: record<geomatch: bool, long_code_weight: float, skip_unhealthy: bool, sticky_sender: bool, toll_free_weight: float>, record_type: string, updated_at: string, url_shortener_settings: record<domain: string, prefix: string, replace_blacklist_only: bool, send_webhooks: bool>, v1_secret: string, webhook_api_version: string, webhook_failover_url: string, webhook_url: string, whitelisted_destinations: list<string>>>
# operationId: retrieveMessagingProfile
export def "retrieve-messaging-profile" [
  id: string
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
    path: "/messaging_profiles/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a messaging profile
#
# PATCH /messaging_profiles/{id}
# Returns: record<data: record<created_at: string, enabled: bool, id: string, name: string, number_pool_settings: record<geomatch: bool, long_code_weight: float, skip_unhealthy: bool, sticky_sender: bool, toll_free_weight: float>, record_type: string, updated_at: string, url_shortener_settings: record<domain: string, prefix: string, replace_blacklist_only: bool, send_webhooks: bool>, v1_secret: string, webhook_api_version: string, webhook_failover_url: string, webhook_url: string, whitelisted_destinations: list<string>>>
# operationId: updateMessagingProfile
export def "update-messaging-profile" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool> # Specifies whether the messaging profile is enabled or not.
  --name: string # A user friendly name for the messaging profile.
  --number-pool-settings: record # Number Pool allows you to send messages from a pool of numbers of different types, assigning weights to each type. The pool consists of all the long code and toll free numbers assigned to the messaging profile. To disable this feature, set the object field to `null`. (nullable, e.g. {geomatch: false, long_code_weight: 1, skip_unhealthy: true, sticky_sender: false, toll_free_weight: 10}) — shape: {geomatch?: bool, long_code_weight: float, skip_unhealthy: bool, sticky_sender?: bool, toll_free_weight: float}
  --url-shortener-settings: record # The URL shortener feature allows automatic replacement of URLs that were generated using a public URL shortener service. Some examples include bit.do, bit.ly, goo.gl, ht.ly, is.gd, ow.ly, rebrand.ly, t.co, tiny.cc, and tinyurl.com. Such URLs are replaced with with links generated by Telnyx. The use of custom links can improve branding and message deliverability. To disable this feature, set the object field to `null`. (nullable, e.g. {domain: example.ex, prefix: , replace_blacklist_only: true, send_webhooks: false}) — shape: {domain: string, prefix?: string, replace_blacklist_only?: bool, send_webhooks?: bool}
  --v1-secret: string # Secret used to authenticate with v1 endpoints.
  --webhook-api-version: string@webhook-api-version-completer-1 # Determines which webhook format will be used, Telnyx API v1, v2, or a legacy 2010-04-01 format.
  --webhook-failover-url: string # The failover URL where webhooks related to this messaging profile will be sent if sending to the primary URL fails. (nullable, format: url)
  --webhook-url: string # The URL where webhooks related to this messaging profile will be sent. (nullable, format: url)
  --whitelisted-destinations: list<string> # Destinations to which the messaging profile is allowed to send. If set to `null`, all destinations will be allowed. Setting a value of `["*"]` has the equivalent effect. The elements in the list must be valid ISO 3166-1 alpha-2 country codes. (nullable)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/messaging_profiles/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: enabled, var: enabled}, {name: name, var: name}, {name: number_pool_settings, var: number_pool_settings}, {name: url_shortener_settings, var: url_shortener_settings}, {name: v1_secret, var: v1_secret}, {name: webhook_api_version, var: webhook_api_version}, {name: webhook_failover_url, var: webhook_failover_url}, {name: webhook_url, var: webhook_url}, {name: whitelisted_destinations, var: whitelisted_destinations}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, enabled: $enabled, name: $name, number_pool_settings: $number_pool_settings, url_shortener_settings: $url_shortener_settings, v1_secret: $v1_secret, webhook_api_version: $webhook_api_version, webhook_failover_url: $webhook_failover_url, webhook_url: $webhook_url, whitelisted_destinations: $whitelisted_destinations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve messaging profile metrics
#
# GET /messaging_profiles/{id}/metrics
# Returns: record<data: record<detailed: list<record>, overview: record<inbound: record, messaging_profile_id: string, outbound: record, phone_numbers: float, record_type: string>>>
# operationId: retrieveMessagingProfileDetailedMetrics
export def "retrieve-messaging-profile-detailed-metrics" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --time-frame: string@time-frame-completer # The timeframe for which you'd like to retrieve metrics. (default: 24h)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/messaging_profiles/{id}/metrics"
    path_params: [{name: id, var: id}]
    query: [{name: time_frame, var: time_frame}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, time_frame: $time_frame
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List phone numbers associated with a messaging profile
#
# GET /messaging_profiles/{id}/phone_numbers
# Returns: record<data: table<country_code: string, created_at: string, eligible_messaging_products: list, features: record, health: record, id: string, messaging_product: string, messaging_profile_id: string, phone_number: string, record_type: string, traffic_type: string, type: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: listMessagingProfilePhoneNumbers
export def "list-messaging-profile-phone-numbers" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/messaging_profiles/{id}/phone_numbers"
    path_params: [{name: id, var: id}]
    query: [{name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, page_number: $page_number, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List short codes associated with a messaging profile
#
# GET /messaging_profiles/{id}/short_codes
# Returns: record<data: table<country_code: string, created_at: string, id: string, messaging_profile_id: string, record_type: string, short_code: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: listMessagingProfileShortCodes
export def "list-messaging-profile-short-codes" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/messaging_profiles/{id}/short_codes"
    path_params: [{name: id, var: id}]
    query: [{name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, page_number: $page_number, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List messaging URL domains
#
# GET /messaging_url_domains
# Returns: record<data: table<id: string, record_type: string, url_domain: string, use_case: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: listMessagingUrlDomains
export def "list-messaging-url-domains" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/messaging_url_domains"
    query: [{name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_number: $page_number, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List mobile operator networks
#
# GET /mobile_operator_networks
# Returns: record<data: table<country_code: string, id: string, mcc: string, mnc: string, name: string, record_type: string, tadig: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: MobileOperatorNetworksGet
export def "mobile-operator-networks-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
  --filter-name-starts-with: string # Filter by name starting with. (e.g. AT)
  --filter-name-contains: string # Filter by name containing match. (e.g. T&T)
  --filter-name-ends-with: string # Filter by name ending with. (e.g. T)
  --filter-country-code: string # Filter by exact country_code. (e.g. US)
  --filter-mcc: string # Filter by exact MCC. (e.g. 310)
  --filter-mnc: string # Filter by exact MNC. (e.g. 410)
  --filter-tadig: string # Filter by exact TADIG. (e.g. USACG)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/mobile_operator_networks"
    query: [{name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}, {name: "filter[name][starts_with]", var: filter_name_starts_with}, {name: "filter[name][contains]", var: filter_name_contains}, {name: "filter[name][ends_with]", var: filter_name_ends_with}, {name: "filter[country_code]", var: filter_country_code}, {name: "filter[mcc]", var: filter_mcc}, {name: "filter[mnc]", var: filter_mnc}, {name: "filter[tadig]", var: filter_tadig}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_number: $page_number, page_size: $page_size, filter_name_starts_with: $filter_name_starts_with, filter_name_contains: $filter_name_contains, filter_name_ends_with: $filter_name_ends_with, filter_country_code: $filter_country_code, filter_mcc: $filter_mcc, filter_mnc: $filter_mnc, filter_tadig: $filter_tadig
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List notification channels
#
# GET /notification_channels
# Returns: record<data: table<channel_destination: string, channel_type_id: string, created_at: string, id: string, notification_profile_id: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: listNotificationChannels
export def "list-notification-channels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
  --filter-channel-type-id-eq: string@filter-channel-type-id-eq-completer # Filter by the id of a channel type (e.g. webhook)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/notification_channels"
    query: [{name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}, {name: "filter[channel_type_id][eq]", var: filter_channel_type_id_eq}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_number: $page_number, page_size: $page_size, filter_channel_type_id_eq: $filter_channel_type_id_eq
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a notification channel
#
# POST /notification_channels
# Returns: record<data: record<channel_destination: string, channel_type_id: string, created_at: string, id: string, notification_profile_id: string, updated_at: string>>
# operationId: createNotificationChannels
export def "create-notification-channels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --channel-destination: string # The destination associated with the channel type. (e.g. +13125550000)
  --channel-type-id: string@channel-type-id-completer # A Channel Type ID
  --notification-profile-id: string # A UUID reference to the associated Notification Profile. (e.g. 12455643-3cf1-4683-ad23-1cd32f7d5e0a)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/notification_channels"
    body: {content_type: "application/json", kind: json, fields: [{name: channel_destination, var: channel_destination}, {name: channel_type_id, var: channel_type_id}, {name: notification_profile_id, var: notification_profile_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel_destination: $channel_destination, channel_type_id: $channel_type_id, notification_profile_id: $notification_profile_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a notification channel
#
# DELETE /notification_channels/{id}
# Returns: record<data: record<channel_destination: string, channel_type_id: string, created_at: string, id: string, notification_profile_id: string, updated_at: string>>
# operationId: deleteNotificationChannel
export def "delete-notification-channel" [
  id: string
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
    method: delete
    path: "/notification_channels/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a notification channel
#
# GET /notification_channels/{id}
# Returns: record<data: record<channel_destination: string, channel_type_id: string, created_at: string, id: string, notification_profile_id: string, updated_at: string>>
# operationId: retrieveNotificationChannel
export def "retrieve-notification-channel" [
  id: string
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
    path: "/notification_channels/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a notification channel
#
# PATCH /notification_channels/{id}
# Returns: record<data: record<channel_destination: string, channel_type_id: string, created_at: string, id: string, notification_profile_id: string, updated_at: string>>
# operationId: updateNotificationChannel
export def "update-notification-channel" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --channel-destination: string # The destination associated with the channel type. (e.g. +13125550000)
  --channel-type-id: string@channel-type-id-completer # A Channel Type ID
  --notification-profile-id: string # A UUID reference to the associated Notification Profile. (e.g. 12455643-3cf1-4683-ad23-1cd32f7d5e0a)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/notification_channels/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: channel_destination, var: channel_destination}, {name: channel_type_id, var: channel_type_id}, {name: notification_profile_id, var: notification_profile_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, channel_destination: $channel_destination, channel_type_id: $channel_type_id, notification_profile_id: $notification_profile_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all Notifications Events Conditions
#
# GET /notification_event_conditions
# Returns: record<data: table<allow_multiple_channels: bool, associated_record_type: string, asynchronous: bool, created_at: string, description: string, enabled: bool, id: string, name: string, notification_event_id: string, parameters: list, supported_channels: list, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: findNotificationsEventsConditions
export def "find-notifications-events-conditions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
  --filter-associated-record-type-eq: string@filter-associated-record-type-eq-completer # Filter by the associated record type (e.g. phone_number)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/notification_event_conditions"
    query: [{name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}, {name: "filter[associated_record_type][eq]", var: filter_associated_record_type_eq}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_number: $page_number, page_size: $page_size, filter_associated_record_type_eq: $filter_associated_record_type_eq
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all Notifications Events
#
# GET /notification_events
# Returns: record<data: table<created_at: string, enabled: bool, id: string, name: string, notification_category: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: findNotificationsEvents
export def "find-notifications-events" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/notification_events"
    query: [{name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_number: $page_number, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all Notifications Profiles
#
# GET /notification_profiles
# Returns: record<data: table<created_at: string, id: string, name: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: findNotificationsProfiles
export def "find-notifications-profiles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/notification_profiles"
    query: [{name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_number: $page_number, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a notification profile
#
# POST /notification_profiles
# Returns: record<data: record<created_at: string, id: string, name: string, updated_at: string>>
# operationId: createNotificationProfile
export def "create-notification-profile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # A human readable name.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/notification_profiles"
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a notification profile
#
# DELETE /notification_profiles/{id}
# Returns: record<data: record<created_at: string, id: string, name: string, updated_at: string>>
# operationId: deleteNotificationProfile
export def "delete-notification-profile" [
  id: string
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
    method: delete
    path: "/notification_profiles/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a notification profile
#
# GET /notification_profiles/{id}
# Returns: record<data: record<created_at: string, id: string, name: string, updated_at: string>>
# operationId: retrieveNotificationProfile
export def "retrieve-notification-profile" [
  id: string
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
    path: "/notification_profiles/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a notification profile
#
# PATCH /notification_profiles/{id}
# Returns: record<data: record<created_at: string, id: string, name: string, updated_at: string>>
# operationId: updateNotificationProfile
export def "update-notification-profile" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # A human readable name.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/notification_profiles/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List notification settings
#
# GET /notification_settings
# Returns: record<data: table<associated_record_type: string, associated_record_type_value: string, created_at: string, id: string, notification_channel_id: string, notification_event_condition_id: string, notification_profile_id: string, parameters: list, status: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: listNotificationSettings
export def "list-notification-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
  --filter-notification-profile-id-eq: string # Filter by the id of a notification profile (e.g. 12455643-3cf1-4683-ad23-1cd32f7d5e0a)
  --filter-notification-channel-eq: string # Filter by the id of a notification channel (e.g. 12455643-3cf1-4683-ad23-1cd32f7d5e0a)
  --filter-notification-event-condition-id-eq: string # Filter by the id of a notification channel (e.g. 12455643-3cf1-4683-ad23-1cd32f7d5e0a)
  --filter-associated-record-type-eq: string@filter-associated-record-type-eq-completer # Filter by the associated record type (e.g. phone_number)
  --filter-status-eq: string@filter-status-eq-completer # The status of a notification setting (e.g. enable-received)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/notification_settings"
    query: [{name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}, {name: "filter[notification_profile_id][eq]", var: filter_notification_profile_id_eq}, {name: "filter[notification_channel][eq]", var: filter_notification_channel_eq}, {name: "filter[notification_event_condition_id][eq]", var: filter_notification_event_condition_id_eq}, {name: "filter[associated_record_type][eq]", var: filter_associated_record_type_eq}, {name: "filter[status][eq]", var: filter_status_eq}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_number: $page_number, page_size: $page_size, filter_notification_profile_id_eq: $filter_notification_profile_id_eq, filter_notification_channel_eq: $filter_notification_channel_eq, filter_notification_event_condition_id_eq: $filter_notification_event_condition_id_eq, filter_associated_record_type_eq: $filter_associated_record_type_eq, filter_status_eq: $filter_status_eq
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a Notification Setting
#
# POST /notification_settings
# Returns: record<data: record<associated_record_type: string, associated_record_type_value: string, created_at: string, id: string, notification_channel_id: string, notification_event_condition_id: string, notification_profile_id: string, parameters: list<record>, status: string, updated_at: string>>
# operationId: createNotificationSetting
export def "create-notification-setting" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --notification-channel-id: string # A UUID reference to the associated Notification Channel. (e.g. 12455643-3cf1-4683-ad23-1cd32f7d5e0a)
  --notification-event-condition-id: string # A UUID reference to the associated Notification Event Condition. (e.g. 70c7c5cb-dce2-4124-accb-870d39dbe852)
  --notification-profile-id: string # A UUID reference to the associated Notification Profile. (e.g. 12455643-3cf1-4683-ad23-1cd32f7d5e0a)
  --parameters: list # item shape: {name?: string, value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/notification_settings"
    body: {content_type: "application/json", kind: json, fields: [{name: notification_channel_id, var: notification_channel_id}, {name: notification_event_condition_id, var: notification_event_condition_id}, {name: notification_profile_id, var: notification_profile_id}, {name: parameters, var: parameters}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    notification_channel_id: $notification_channel_id, notification_event_condition_id: $notification_event_condition_id, notification_profile_id: $notification_profile_id, parameters: $parameters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a notification setting
#
# DELETE /notification_settings/{id}
# Returns: record<data: record<associated_record_type: string, associated_record_type_value: string, created_at: string, id: string, notification_channel_id: string, notification_event_condition_id: string, notification_profile_id: string, parameters: list<record>, status: string, updated_at: string>>
# operationId: deleteNotificationSetting
export def "delete-notification-setting" [
  id: string
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
    method: delete
    path: "/notification_settings/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a notification setting
#
# GET /notification_settings/{id}
# Returns: record<data: record<associated_record_type: string, associated_record_type_value: string, created_at: string, id: string, notification_channel_id: string, notification_event_condition_id: string, notification_profile_id: string, parameters: list<record>, status: string, updated_at: string>>
# operationId: retrieveNotificationSetting
export def "retrieve-notification-setting" [
  id: string
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
    path: "/notification_settings/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List number block orders
#
# GET /number_block_orders
# Returns: record<data: table<connection_id: string, created_at: string, customer_reference: string, id: string, messaging_profile_id: string, phone_numbers_count: int, range: int, record_type: string, requirements_met: bool, starting_number: string, status: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: listNumberBlockOrders
export def "list-number-block-orders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-status: string # Filter number block orders by status. (e.g. pending)
  --filter-created-at-gt: string # Filter number block orders later than this value. (e.g. 2018-01-01T00:00:00.000000Z)
  --filter-created-at-lt: string # Filter number block orders earlier than this value. (e.g. 2018-01-01T00:00:00.000000Z)
  --filter-phone-numbers-starting-number: string # Filter number block orders having these phone numbers. (e.g. +19705555000)
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/number_block_orders"
    query: [{name: "filter[status]", var: filter_status}, {name: "filter[created_at][gt]", var: filter_created_at_gt}, {name: "filter[created_at][lt]", var: filter_created_at_lt}, {name: "filter[phone_numbers.starting_number]", var: filter_phone_numbers_starting_number}, {name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter_status: $filter_status, filter_created_at_gt: $filter_created_at_gt, filter_created_at_lt: $filter_created_at_lt, filter_phone_numbers_starting_number: $filter_phone_numbers_starting_number, page_number: $page_number, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a number block order
#
# POST /number_block_orders
# Returns: record<data: record<connection_id: string, created_at: string, customer_reference: string, id: string, messaging_profile_id: string, phone_numbers_count: int, range: int, record_type: string, requirements_met: bool, starting_number: string, status: string, updated_at: string>>
# operationId: createNumberBlockOrder
export def "create-number-block-order" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --connection-id: string # Identifies the connection associated with this phone number. (e.g. 346789098765567)
  --customer-reference: string # A customer reference string for customer look ups. (e.g. MY REF 001)
  --messaging-profile-id: string # Identifies the messaging profile associated with the phone number. (e.g. abc85f64-5717-4562-b3fc-2c9600)
  range: int # The phone number range included in the block. (e.g. 10)
  starting_number: string # Starting phone number block (format: e164_phone_number, e.g. +19705555000)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/number_block_orders"
    body: {content_type: "application/json", kind: json, fields: [{name: connection_id, var: connection_id}, {name: customer_reference, var: customer_reference}, {name: messaging_profile_id, var: messaging_profile_id}, {name: range, var: range}, {name: starting_number, var: starting_number}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    connection_id: $connection_id, customer_reference: $customer_reference, messaging_profile_id: $messaging_profile_id, range: $range, starting_number: $starting_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a number block order
#
# GET /number_block_orders/{number_block_order_id}
# Returns: record<data: record<connection_id: string, created_at: string, customer_reference: string, id: string, messaging_profile_id: string, phone_numbers_count: int, range: int, record_type: string, requirements_met: bool, starting_number: string, status: string, updated_at: string>>
# operationId: retrieveNumberBlockOrder
export def "retrieve-number-block-order" [
  number_block_order_id: string
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
    path: "/number_block_orders/{number_block_order_id}"
    path_params: [{name: number_block_order_id, var: number_block_order_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    number_block_order_id: $number_block_order_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lookup phone number data
#
# GET /number_lookup/{phone_number}
# Returns: record<data: record<caller_name: record<caller_name: string, error_code: string>, carrier: record<error_code: string, mobile_country_code: string, mobile_network_code: string, name: string, type: string>, country_code: string, fraud: string, national_format: string, phone_number: string, portability: record<altspid: string, altspid_carrier_name: string, altspid_carrier_type: string, city: string, line_type: string, lrn: string, ocn: string, ported_date: string, ported_status: string, spid: string, spid_carrier_name: string, spid_carrier_type: string, state: string>, record_type: string>>
# operationId: NumberLookup
export def "number-lookup" [
  phone_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string@type-completer-1 # Specifies the type of number lookup to be performed
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/number_lookup/{phone_number}"
    path_params: [{name: phone_number, var: phone_number}]
    query: [{name: type, var: type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    phone_number: $phone_number, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List number order documents
#
# GET /number_order_documents
# Returns: record<data: table<created_at: string, customer_reference: string, file_id: string, id: string, record_type: string, requirement_type: string, requirements_id: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: listNumberOrderDocuments
export def "list-number-order-documents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-requirement-id: string # Filter number order documents by `requirement_id`.
  --filter-created-at-gt: string # Filter number order documents after this datetime.
  --filter-created-at-lt: string # Filter number order documents from before this datetime.
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/number_order_documents"
    query: [{name: "filter[requirement_id]", var: filter_requirement_id}, {name: "filter[created_at][gt]", var: filter_created_at_gt}, {name: "filter[created_at][lt]", var: filter_created_at_lt}, {name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter_requirement_id: $filter_requirement_id, filter_created_at_gt: $filter_created_at_gt, filter_created_at_lt: $filter_created_at_lt, page_number: $page_number, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a number order document
#
# POST /number_order_documents
# Returns: record<data: record<created_at: string, customer_reference: string, file_id: string, id: string, record_type: string, requirement_type: string, requirements_id: string>>
# operationId: createNumberOrderDocument
export def "create-number-order-document" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --customer-reference: string # A customer reference string for customer look ups. (e.g. MY REF 001)
  --file-id: string # The id of the file to associate as a number order document. (e.g. 1e3c5822-0362-4702-8e46-5a129f0d3976)
  --requirements-id: string # Unique id for a requirement. (e.g. 36aaf27d-986b-493c-bd1b-de16af2e4292)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/number_order_documents"
    body: {content_type: "application/json", kind: json, fields: [{name: customer_reference, var: customer_reference}, {name: file_id, var: file_id}, {name: requirements_id, var: requirements_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer_reference: $customer_reference, file_id: $file_id, requirements_id: $requirements_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a number order document
#
# GET /number_order_documents/{number_order_document_id}
# Returns: record<data: record<created_at: string, customer_reference: string, file_id: string, id: string, record_type: string, requirement_type: string, requirements_id: string>>
# operationId: retrieveNumberOrderDocument
export def "retrieve-number-order-document" [
  number_order_document_id: string
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
    path: "/number_order_documents/{number_order_document_id}"
    path_params: [{name: number_order_document_id, var: number_order_document_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    number_order_document_id: $number_order_document_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a number order document
#
# PATCH /number_order_documents/{number_order_document_id}
# Returns: record<data: record<created_at: string, customer_reference: string, file_id: string, id: string, record_type: string, requirement_type: string, requirements_id: string>>
# operationId: updateNumberOrderDocument
export def "update-number-order-document" [
  number_order_document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --customer-reference: string # A customer reference string for customer look ups. (e.g. MY REF 001)
  --file-id: string # The id of the file to associate as a number order document. (e.g. 1e3c5822-0362-4702-8e46-5a129f0d3976)
  --requirements-id: string # Unique id for a requirement. (e.g. 36aaf27d-986b-493c-bd1b-de16af2e4292)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/number_order_documents/{number_order_document_id}"
    path_params: [{name: number_order_document_id, var: number_order_document_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: customer_reference, var: customer_reference}, {name: file_id, var: file_id}, {name: requirements_id, var: requirements_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    number_order_document_id: $number_order_document_id, customer_reference: $customer_reference, file_id: $file_id, requirements_id: $requirements_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of phone numbers associated to orders
#
# GET /number_order_phone_numbers
# Returns: record<data: table<country_code: string, id: string, order_request_id: string, phone_number: string, phone_number_type: string, record_type: string, regulatory_requirements: list, requirements_met: bool, status: string, sub_number_order_id: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: retrieveNumberOrderPhoneNumbers
export def "retrieve-number-order-phone-numbers" [
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
    path: "/number_order_phone_numbers"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a number order phone number.
#
# GET /number_order_phone_numbers/{number_order_phone_number_id}
# Returns: record<data: record<country_code: string, id: string, order_request_id: string, phone_number: string, phone_number_type: string, record_type: string, regulatory_requirements: list<record>, requirements_met: bool, status: string, sub_number_order_id: string>>
# operationId: retrieveNumberOrderPhoneNumber
export def "retrieve-number-order-phone-number" [
  number_order_phone_number_id: string
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
    path: "/number_order_phone_numbers/{number_order_phone_number_id}"
    path_params: [{name: number_order_phone_number_id, var: number_order_phone_number_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    number_order_phone_number_id: $number_order_phone_number_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a number order phone number.
#
# PATCH /number_order_phone_numbers/{number_order_phone_number_id}
# Returns: record<data: record<country_code: string, id: string, order_request_id: string, phone_number: string, phone_number_type: string, record_type: string, regulatory_requirements: list<record>, requirements_met: bool, status: string, sub_number_order_id: string>>
# operationId: updateNumberOrderPhoneNumber
export def "update-number-order-phone-number" [
  number_order_phone_number_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --regulatory-requirements: list # item shape: {field_value?: string, requirement_id?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/number_order_phone_numbers/{number_order_phone_number_id}"
    path_params: [{name: number_order_phone_number_id, var: number_order_phone_number_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: regulatory_requirements, var: regulatory_requirements}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    number_order_phone_number_id: $number_order_phone_number_id, regulatory_requirements: $regulatory_requirements
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List number orders
#
# GET /number_orders
# Returns: record<data: table<billing_group_id: string, connection_id: string, created_at: string, customer_reference: string, id: string, messaging_profile_id: string, phone_numbers_count: int, record_type: string, requirements_met: bool, status: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: listNumberOrders
export def "list-number-orders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-status: string # Filter number orders by status.
  --filter-created-at-gt: string # Filter number orders later than this value.
  --filter-created-at-lt: string # Filter number orders earlier than this value.
  --filter-phone-numbers-count: string # Filter number order with this amount of numbers
  --filter-customer-reference: string # Filter number orders via the customer reference set.
  --filter-requirements-met: oneof<nothing, bool> # Filter number orders by requirements met.
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/number_orders"
    query: [{name: "filter[status]", var: filter_status}, {name: "filter[created_at][gt]", var: filter_created_at_gt}, {name: "filter[created_at][lt]", var: filter_created_at_lt}, {name: "filter[phone_numbers_count]", var: filter_phone_numbers_count}, {name: "filter[customer_reference]", var: filter_customer_reference}, {name: "filter[requirements_met]", var: filter_requirements_met}, {name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter_status: $filter_status, filter_created_at_gt: $filter_created_at_gt, filter_created_at_lt: $filter_created_at_lt, filter_phone_numbers_count: $filter_phone_numbers_count, filter_customer_reference: $filter_customer_reference, filter_requirements_met: $filter_requirements_met, page_number: $page_number, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a number order
#
# POST /number_orders
# Returns: record<data: record<billing_group_id: string, connection_id: string, created_at: string, customer_reference: string, id: string, messaging_profile_id: string, phone_numbers_count: int, record_type: string, requirements_met: bool, status: string, updated_at: string, phone_numbers: list<record>>>
# operationId: createNumberOrder
export def "create-number-order" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --billing-group-id: string # Identifies the billing group associated with the phone number. (e.g. abc85f64-5717-4562-b3fc-2c9600)
  --connection-id: string # Identifies the connection associated with this phone number. (e.g. 346789098765567)
  --customer-reference: string # A customer reference string for customer look ups. (e.g. MY REF 001)
  --messaging-profile-id: string # Identifies the messaging profile associated with the phone number. (e.g. abc85f64-5717-4562-b3fc-2c9600)
  --phone-numbers: list # item shape: {phone_number?: string, regulatory_requirements?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/number_orders"
    body: {content_type: "application/json", kind: json, fields: [{name: billing_group_id, var: billing_group_id}, {name: connection_id, var: connection_id}, {name: customer_reference, var: customer_reference}, {name: messaging_profile_id, var: messaging_profile_id}, {name: phone_numbers, var: phone_numbers}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_group_id: $billing_group_id, connection_id: $connection_id, customer_reference: $customer_reference, messaging_profile_id: $messaging_profile_id, phone_numbers: $phone_numbers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a number order
#
# GET /number_orders/{number_order_id}
# Returns: record<data: record<billing_group_id: string, connection_id: string, created_at: string, customer_reference: string, id: string, messaging_profile_id: string, phone_numbers_count: int, record_type: string, requirements_met: bool, status: string, updated_at: string, phone_numbers: list<record>>>
# operationId: retrieveNumberOrder
export def "retrieve-number-order" [
  number_order_id: string
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
    path: "/number_orders/{number_order_id}"
    path_params: [{name: number_order_id, var: number_order_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    number_order_id: $number_order_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a number order
#
# PATCH /number_orders/{number_order_id}
# Returns: record<data: record<billing_group_id: string, connection_id: string, created_at: string, customer_reference: string, id: string, messaging_profile_id: string, phone_numbers_count: int, record_type: string, requirements_met: bool, status: string, updated_at: string, phone_numbers: list<record>>>
# operationId: updateNumberOrder
export def "update-number-order" [
  number_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --customer-reference: string # A customer reference string for customer look ups. (e.g. MY REF 001)
  --phone-numbers: list # item shape: {phone_number?: string, regulatory_requirements?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/number_orders/{number_order_id}"
    path_params: [{name: number_order_id, var: number_order_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: customer_reference, var: customer_reference}, {name: phone_numbers, var: phone_numbers}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    number_order_id: $number_order_id, customer_reference: $customer_reference, phone_numbers: $phone_numbers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List number reservations
#
# GET /number_reservations
# Returns: record<data: table<created_at: string, customer_reference: string, id: string, phone_numbers: list, record_type: string, status: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: listNumberReservations
export def "list-number-reservations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-status: string # Filter number reservations by status.
  --filter-created-at-gt: string # Filter number reservations later than this value.
  --filter-created-at-lt: string # Filter number reservations earlier than this value.
  --filter-phone-numbers-phone-number: string # Filter number reservations having these phone numbers.
  --filter-customer-reference: string # Filter number reservations via the customer reference set.
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/number_reservations"
    query: [{name: "filter[status]", var: filter_status}, {name: "filter[created_at][gt]", var: filter_created_at_gt}, {name: "filter[created_at][lt]", var: filter_created_at_lt}, {name: "filter[phone_numbers.phone_number]", var: filter_phone_numbers_phone_number}, {name: "filter[customer_reference]", var: filter_customer_reference}, {name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter_status: $filter_status, filter_created_at_gt: $filter_created_at_gt, filter_created_at_lt: $filter_created_at_lt, filter_phone_numbers_phone_number: $filter_phone_numbers_phone_number, filter_customer_reference: $filter_customer_reference, page_number: $page_number, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a number reservation
#
# POST /number_reservations
# Returns: record<data: record<created_at: string, customer_reference: string, id: string, phone_numbers: list<record>, record_type: string, status: string, updated_at: string>>
# operationId: createNumberReservation
export def "create-number-reservation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --customer-reference: string # A customer reference string for customer look ups. (e.g. MY REF 001)
  --phone-numbers: list # item shape: {phone_number?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/number_reservations"
    body: {content_type: "application/json", kind: json, fields: [{name: customer_reference, var: customer_reference}, {name: phone_numbers, var: phone_numbers}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer_reference: $customer_reference, phone_numbers: $phone_numbers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a number reservation
#
# GET /number_reservations/{number_reservation_id}
# Returns: record<data: record<created_at: string, customer_reference: string, id: string, phone_numbers: list<record>, record_type: string, status: string, updated_at: string>>
# operationId: retrieveNumberReservation
export def "retrieve-number-reservation" [
  number_reservation_id: string
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
    path: "/number_reservations/{number_reservation_id}"
    path_params: [{name: number_reservation_id, var: number_reservation_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    number_reservation_id: $number_reservation_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Extend a number reservation
#
# POST /number_reservations/{number_reservation_id}/actions/extend
# Returns: record<data: record<created_at: string, customer_reference: string, id: string, phone_numbers: list<record>, record_type: string, status: string, updated_at: string>>
# operationId: extendNumberReservationExpiryTime
export def "extend-number-reservation-expiry-time" [
  number_reservation_id: string
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
    method: post
    path: "/number_reservations/{number_reservation_id}/actions/extend"
    path_params: [{name: number_reservation_id, var: number_reservation_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    number_reservation_id: $number_reservation_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List OTA updates
#
# GET /ota_updates
# Returns: record<data: table<created_at: string, id: string, record_type: string, sim_card_id: string, status: string, type: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: OTAUpdatesList
export def "ota-updates-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
  --filter-status: string@filter-status-completer-1 # Filter by a specific status of the resource's lifecycle. (e.g. in-progress)
  --filter-sim-card-id: string # The SIM card identification UUID.
  --filter-type: string@filter-type-completer-1 # Filter by type. (e.g. sim_card_network_preferences)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/ota_updates"
    query: [{name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}, {name: "filter[status]", var: filter_status}, {name: "filter[sim_card_id]", var: filter_sim_card_id}, {name: "filter[type]", var: filter_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_number: $page_number, page_size: $page_size, filter_status: $filter_status, filter_sim_card_id: $filter_sim_card_id, filter_type: $filter_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get OTA update
#
# GET /ota_updates/{id}
# Returns: record<data: record<created_at: string, id: string, record_type: string, settings: record<mobile_operator_networks_preferences: list>, sim_card_id: string, status: string, type: string, updated_at: string>>
# operationId: OTAUpdateGET
export def "ota-update-get" [
  id: string
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
    path: "/ota_updates/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all outbound voice profiles
#
# GET /outbound_voice_profiles
# Returns: record<data: table<billing_group_id: string, call_recording: record, concurrent_call_limit: int, connections_count: int, created_at: string, daily_spend_limit: string, daily_spend_limit_enabled: bool, enabled: bool, id: string, max_destination_rate: float, name: string, record_type: string, service_plan: string, tags: list, traffic_type: string, updated_at: string, usage_payment_method: string, whitelisted_destinations: list>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: listOutboundVoiceProfiles
export def "list-outbound-voice-profiles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
  --filter-name-contains: string # Optional filter on outbound voice profile name. (e.g. office-profile)
  --sort: string@sort-completer-4 # Specifies the sort order for results. By default sorting direction is ascending. To have the results sorted in descending order add the - prefix. That is: name: sorts the result by the name field in ascending order. -name: sorts the result by the name field in descending order. (default: -created_at, e.g. name)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/outbound_voice_profiles"
    query: [{name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}, {name: "filter[name][contains]", var: filter_name_contains}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_number: $page_number, page_size: $page_size, filter_name_contains: $filter_name_contains, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an outbound voice profile
#
# POST /outbound_voice_profiles
# Returns: record<data: record<billing_group_id: string, call_recording: record<call_recording_caller_phone_numbers: list, call_recording_channels: string, call_recording_format: string, call_recording_type: string>, concurrent_call_limit: int, connections_count: int, created_at: string, daily_spend_limit: string, daily_spend_limit_enabled: bool, enabled: bool, id: string, max_destination_rate: float, name: string, record_type: string, service_plan: string, tags: list<string>, traffic_type: string, updated_at: string, usage_payment_method: string, whitelisted_destinations: list<string>>>
# operationId: createOutboundVoiceProfile
export def "create-outbound-voice-profile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --billing-group-id: string # The ID of the billing group associated with the outbound proflile. Defaults to null (for no group assigned). (nullable, format: uuid, e.g. 6a09cdc3-8948-47f0-aa62-74ac943d6c58)
  --call-recording: record # e.g. {call_recording_caller_phone_numbers: [+19705555098], call_recording_channels: dual, call_recording_format: mp3, call_recording_type: by_caller_phone_number} — shape: {call_recording_caller_phone_numbers?: list<string>, call_recording_channels?: "single"|"dual", call_recording_format?: "wav"|"mp3", call_recording_type?: "all"|"none"|"by_caller_phone_number"}
  --concurrent-call-limit: int # Must be no more than your global concurrent call limit. Null means no limit. (nullable, e.g. 10)
  --daily-spend-limit: string # The maximum amount of usage charges, in USD, you want Telnyx to allow on this outbound voice profile in a day before disallowing new calls. (e.g. 100.00)
  --daily-spend-limit-enabled: oneof<nothing, bool> # Specifies whether to enforce the daily_spend_limit on this outbound voice profile. (default: false, e.g. true)
  --enabled: oneof<nothing, bool> # Specifies whether the outbound voice profile can be used. Disabled profiles will result in outbound calls being blocked for the associated Connections. (default: true, e.g. true)
  --max-destination-rate: float # Maximum rate (price per minute) for a Destination to be allowed when making outbound calls.
  name: string # A user-supplied name to help with organization. (e.g. office)
  --service-plan: string@service-plan-completer # Indicates the coverage of the termination regions. International and Global are the same but International may only be used for high volume/short duration Outbound Voice Profiles. (default: global, e.g. global)
  --tags: list<string> # e.g. [office-profile]
  --traffic-type: string@traffic-type-completer # Specifies the type of traffic allowed in this profile. (default: conversational, e.g. conversational)
  --usage-payment-method: string@usage-payment-method-completer # Setting for how costs for outbound profile are calculated. (default: rate-deck, e.g. tariff)
  --whitelisted-destinations: list<string> # The list of destinations you want to be able to call using this outbound voice profile formatted in alpha2. (default: [US, CA], e.g. [US, BR, AU])
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/outbound_voice_profiles"
    body: {content_type: "application/json", kind: json, fields: [{name: billing_group_id, var: billing_group_id}, {name: call_recording, var: call_recording}, {name: concurrent_call_limit, var: concurrent_call_limit}, {name: daily_spend_limit, var: daily_spend_limit}, {name: daily_spend_limit_enabled, var: daily_spend_limit_enabled}, {name: enabled, var: enabled}, {name: max_destination_rate, var: max_destination_rate}, {name: name, var: name}, {name: service_plan, var: service_plan}, {name: tags, var: tags}, {name: traffic_type, var: traffic_type}, {name: usage_payment_method, var: usage_payment_method}, {name: whitelisted_destinations, var: whitelisted_destinations}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_group_id: $billing_group_id, call_recording: $call_recording, concurrent_call_limit: $concurrent_call_limit, daily_spend_limit: $daily_spend_limit, daily_spend_limit_enabled: $daily_spend_limit_enabled, enabled: $enabled, max_destination_rate: $max_destination_rate, name: $name, service_plan: $service_plan, tags: $tags, traffic_type: $traffic_type, usage_payment_method: $usage_payment_method, whitelisted_destinations: $whitelisted_destinations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an outbound voice profile
#
# DELETE /outbound_voice_profiles/{id}
# Returns: record<data: record<billing_group_id: string, call_recording: record<call_recording_caller_phone_numbers: list, call_recording_channels: string, call_recording_format: string, call_recording_type: string>, concurrent_call_limit: int, connections_count: int, created_at: string, daily_spend_limit: string, daily_spend_limit_enabled: bool, enabled: bool, id: string, max_destination_rate: float, name: string, record_type: string, service_plan: string, tags: list<string>, traffic_type: string, updated_at: string, usage_payment_method: string, whitelisted_destinations: list<string>>>
# operationId: deleteOutboundVoiceProfile
export def "delete-outbound-voice-profile" [
  id: string
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
    method: delete
    path: "/outbound_voice_profiles/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an outbound voice profile
#
# GET /outbound_voice_profiles/{id}
# Returns: record<data: record<billing_group_id: string, call_recording: record<call_recording_caller_phone_numbers: list, call_recording_channels: string, call_recording_format: string, call_recording_type: string>, concurrent_call_limit: int, connections_count: int, created_at: string, daily_spend_limit: string, daily_spend_limit_enabled: bool, enabled: bool, id: string, max_destination_rate: float, name: string, record_type: string, service_plan: string, tags: list<string>, traffic_type: string, updated_at: string, usage_payment_method: string, whitelisted_destinations: list<string>>>
# operationId: retrieveOutboundVoiceProfile
export def "retrieve-outbound-voice-profile" [
  id: string
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
    path: "/outbound_voice_profiles/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing outbound voice profile.
#
# PATCH /outbound_voice_profiles/{id}
# Returns: record<data: record<billing_group_id: string, call_recording: record<call_recording_caller_phone_numbers: list, call_recording_channels: string, call_recording_format: string, call_recording_type: string>, concurrent_call_limit: int, connections_count: int, created_at: string, daily_spend_limit: string, daily_spend_limit_enabled: bool, enabled: bool, id: string, max_destination_rate: float, name: string, record_type: string, service_plan: string, tags: list<string>, traffic_type: string, updated_at: string, usage_payment_method: string, whitelisted_destinations: list<string>>>
# operationId: updateOutboundVoiceProfile
export def "update-outbound-voice-profile" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --billing-group-id: string # The ID of the billing group associated with the outbound proflile. Defaults to null (for no group assigned). (nullable, format: uuid, e.g. 6a09cdc3-8948-47f0-aa62-74ac943d6c58)
  --call-recording: record # e.g. {call_recording_caller_phone_numbers: [+19705555098], call_recording_channels: dual, call_recording_format: mp3, call_recording_type: by_caller_phone_number} — shape: {call_recording_caller_phone_numbers?: list<string>, call_recording_channels?: "single"|"dual", call_recording_format?: "wav"|"mp3", call_recording_type?: "all"|"none"|"by_caller_phone_number"}
  --concurrent-call-limit: int # Must be no more than your global concurrent call limit. Null means no limit. (nullable, e.g. 10)
  --daily-spend-limit: string # The maximum amount of usage charges, in USD, you want Telnyx to allow on this outbound voice profile in a day before disallowing new calls. (e.g. 100.00)
  --daily-spend-limit-enabled: oneof<nothing, bool> # Specifies whether to enforce the daily_spend_limit on this outbound voice profile. (default: false, e.g. true)
  --enabled: oneof<nothing, bool> # Specifies whether the outbound voice profile can be used. Disabled profiles will result in outbound calls being blocked for the associated Connections. (default: true, e.g. true)
  --max-destination-rate: float # Maximum rate (price per minute) for a Destination to be allowed when making outbound calls.
  name: string # A user-supplied name to help with organization. (e.g. office)
  --service-plan: string@service-plan-completer # Indicates the coverage of the termination regions. International and Global are the same but International may only be used for high volume/short duration Outbound Voice Profiles. (default: global, e.g. global)
  --tags: list<string> # e.g. [office-profile]
  --traffic-type: string@traffic-type-completer # Specifies the type of traffic allowed in this profile. (default: conversational, e.g. conversational)
  --usage-payment-method: string@usage-payment-method-completer # Setting for how costs for outbound profile are calculated. (default: rate-deck, e.g. tariff)
  --whitelisted-destinations: list<string> # The list of destinations you want to be able to call using this outbound voice profile formatted in alpha2. (default: [US, CA], e.g. [US, BR, AU])
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/outbound_voice_profiles/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: billing_group_id, var: billing_group_id}, {name: call_recording, var: call_recording}, {name: concurrent_call_limit, var: concurrent_call_limit}, {name: daily_spend_limit, var: daily_spend_limit}, {name: daily_spend_limit_enabled, var: daily_spend_limit_enabled}, {name: enabled, var: enabled}, {name: max_destination_rate, var: max_destination_rate}, {name: name, var: name}, {name: service_plan, var: service_plan}, {name: tags, var: tags}, {name: traffic_type, var: traffic_type}, {name: usage_payment_method, var: usage_payment_method}, {name: whitelisted_destinations, var: whitelisted_destinations}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, billing_group_id: $billing_group_id, call_recording: $call_recording, concurrent_call_limit: $concurrent_call_limit, daily_spend_limit: $daily_spend_limit, daily_spend_limit_enabled: $daily_spend_limit_enabled, enabled: $enabled, max_destination_rate: $max_destination_rate, name: $name, service_plan: $service_plan, tags: $tags, traffic_type: $traffic_type, usage_payment_method: $usage_payment_method, whitelisted_destinations: $whitelisted_destinations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the phone number blocks jobs
#
# GET /phone_number_blocks/jobs
# Returns: record<data: table<created_at: string, etc: string, failed_operations: list, id: string, record_type: string, status: string, successful_operations: list, type: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: listPhoneNumberBlocksJobs
export def "list-phone-number-blocks-jobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-type: string@filter-type-completer-2 # Filter the phone number blocks jobs by type. (e.g. delete_phone_number_block)
  --filter-status: string@filter-status-completer-2 # Filter the phone number blocks jobs by status. (e.g. in_progress)
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
  --sort: string@sort-completer-5 # Specifies the sort order for results. If not given, results are sorted by created_at in descending order. (e.g. created_at)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/phone_number_blocks/jobs"
    query: [{name: "filter[type]", var: filter_type}, {name: "filter[status]", var: filter_status}, {name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter_type: $filter_type, filter_status: $filter_status, page_number: $page_number, page_size: $page_size, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes all numbers associated with a phone number block
#
# POST /phone_number_blocks/jobs/delete_phone_number_block
# Returns: record<data: record<created_at: string, etc: string, failed_operations: list<record>, id: string, record_type: string, status: string, successful_operations: list<record>, type: string, updated_at: string>>
# operationId: createPhoneNumberBlocksJobDeletePhoneNumberBlock
export def "create-phone-number-blocks-job-delete-phone-number-block" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  phone_number_block_id: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/phone_number_blocks/jobs/delete_phone_number_block"
    body: {content_type: "application/json", kind: json, fields: [{name: phone_number_block_id, var: phone_number_block_id}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    phone_number_block_id: $phone_number_block_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a phone number blocks job
#
# GET /phone_number_blocks/jobs/{id}
# Returns: record<data: record<created_at: string, etc: string, failed_operations: list<record>, id: string, record_type: string, status: string, successful_operations: list<record>, type: string, updated_at: string>>
# operationId: retrievePhoneNumberBlocksJob
export def "retrieve-phone-number-blocks-job" [
  id: string
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
    path: "/phone_number_blocks/jobs/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List phone numbers
#
# GET /phone_numbers
# Returns: record<data: table<billing_group_id: string, call_forwarding_enabled: bool, call_recording_enabled: bool, caller_id_name_enabled: bool, cnam_listing_enabled: bool, connection_id: string, connection_name: string, created_at: string, customer_reference: string, emergency_address_id: string, emergency_enabled: bool, external_pin: string, id: string, messaging_profile_id: string, messaging_profile_name: string, number_level_routing: string, phone_number: string, phone_number_type: string, purchased_at: string, record_type: string, status: string, t38_fax_gateway_enabled: bool, tags: list>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: listPhoneNumbers
export def "list-phone-numbers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
  --filter-tag: string # Filter by phone number tags.
  --filter-phone-number: string # Filter by phone number. Requires at least three digits. Non-numerical characters will result in no values being returned.
  --filter-status: string@filter-status-completer-3 # Filter by phone number status. (e.g. active)
  --filter-voice-connection-name-contains: string # Filter contains connection name. Requires at least three characters. (e.g. test)
  --filter-voice-connection-name-starts-with: string # Filter starts with connection name. Requires at least three characters. (e.g. test)
  --filter-voice-connection-name-ends-with: string # Filter ends with connection name. Requires at least three characters. (e.g. test)
  --filter-voice-connection-name-eq: string # Filter by connection name. (e.g. test)
  --filter-usage-payment-method: string@filter-usage-payment-method-completer # Filter by usage_payment_method. (e.g. channel)
  --filter-billing-group-id: string # Filter by the billing_group_id associated with phone numbers. To filter to only phone numbers that have no billing group associated them, set the value of this filter to the string 'null'. (e.g. 62e4bf2e-c278-4282-b524-488d9c9c43b2)
  --filter-emergency-address-id: string # Filter by the emergency_address_id associated with phone numbers. To filter only phone numbers that have no emergency address associated with them, set the value of this filter to the string 'null'. (format: int64, e.g. 9102160989215728032)
  --filter-customer-reference: string # Filter numbers via the customer_reference set.
  --sort: string@sort-completer-6 # Specifies the sort order for results. If not given, results are sorted by created_at in descending order. (e.g. connection_name)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/phone_numbers"
    query: [{name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}, {name: "filter[tag]", var: filter_tag}, {name: "filter[phone_number]", var: filter_phone_number}, {name: "filter[status]", var: filter_status}, {name: "filter[voice.connection_name][contains]", var: filter_voice_connection_name_contains}, {name: "filter[voice.connection_name][starts_with]", var: filter_voice_connection_name_starts_with}, {name: "filter[voice.connection_name][ends_with]", var: filter_voice_connection_name_ends_with}, {name: "filter[voice.connection_name][eq]", var: filter_voice_connection_name_eq}, {name: "filter[usage_payment_method]", var: filter_usage_payment_method}, {name: "filter[billing_group_id]", var: filter_billing_group_id}, {name: "filter[emergency_address_id]", var: filter_emergency_address_id}, {name: "filter[customer_reference]", var: filter_customer_reference}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_number: $page_number, page_size: $page_size, filter_tag: $filter_tag, filter_phone_number: $filter_phone_number, filter_status: $filter_status, filter_voice_connection_name_contains: $filter_voice_connection_name_contains, filter_voice_connection_name_starts_with: $filter_voice_connection_name_starts_with, filter_voice_connection_name_ends_with: $filter_voice_connection_name_ends_with, filter_voice_connection_name_eq: $filter_voice_connection_name_eq, filter_usage_payment_method: $filter_usage_payment_method, filter_billing_group_id: $filter_billing_group_id, filter_emergency_address_id: $filter_emergency_address_id, filter_customer_reference: $filter_customer_reference, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List CSV downloads
#
# GET /phone_numbers/csv_downloads
# Returns: record<data: table<id: string, record_type: string, status: string, url: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: listCsvDownloads
export def "list-csv-downloads" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/phone_numbers/csv_downloads"
    query: [{name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_number: $page_number, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a CSV download
#
# POST /phone_numbers/csv_downloads
# Returns: record<data: table<id: string, record_type: string, status: string, url: string>>
# operationId: createCsvDownload
export def "create-csv-download" [
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
    method: post
    path: "/phone_numbers/csv_downloads"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a CSV download
#
# GET /phone_numbers/csv_downloads/{id}
# Returns: record<data: table<id: string, record_type: string, status: string, url: string>>
# operationId: retrieveCsvDownload
export def "retrieve-csv-download" [
  id: string
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
    path: "/phone_numbers/csv_downloads/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve your inbound channels
#
# GET /phone_numbers/inbound_channels
# Returns: record<data: record<channels: int, record_type: string>>
# operationId: listOutboundChannels
export def "list-outbound-channels" [
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
    path: "/phone_numbers/inbound_channels"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update inbound channels
#
# PATCH /phone_numbers/inbound_channels
# Returns: record<data: record<channels: int, record_type: string>>
# operationId: updateOutboundChannels
export def "update-outbound-channels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  channels: int # The new number of concurrent channels for the account (e.g. 7)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/phone_numbers/inbound_channels"
    body: {content_type: "application/json", kind: json, fields: [{name: channels, var: channels}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channels: $channels
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the phone numbers jobs
#
# GET /phone_numbers/jobs
# Returns: record<data: table<created_at: string, etc: string, failed_operations: list, id: string, pending_operations: list, record_type: string, status: string, successful_operations: list, type: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: listPhoneNumbersJobs
export def "list-phone-numbers-jobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-type: string@filter-type-completer-3 # Filter the phone number jobs by type. (e.g. update_emergency_settings)
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
  --sort: string@sort-completer-5 # Specifies the sort order for results. If not given, results are sorted by created_at in descending order. (e.g. created_at)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/phone_numbers/jobs"
    query: [{name: "filter[type]", var: filter_type}, {name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter_type: $filter_type, page_number: $page_number, page_size: $page_size, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a batch of numbers
#
# POST /phone_numbers/jobs/delete_phone_numbers
# Returns: record<data: record<created_at: string, etc: string, failed_operations: list<record>, id: string, pending_operations: list<record>, record_type: string, status: string, successful_operations: list<record>, type: string, updated_at: string>>
# operationId: createPhoneNumbersJobDeletePhoneNumbers
export def "create-phone-numbers-job-delete-phone-numbers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  phone_numbers: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/phone_numbers/jobs/delete_phone_numbers"
    body: {content_type: "application/json", kind: json, fields: [{name: phone_numbers, var: phone_numbers}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    phone_numbers: $phone_numbers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the emergency settings from a batch of numbers
#
# POST /phone_numbers/jobs/update_emergency_settings
# Returns: record<data: record<created_at: string, etc: string, failed_operations: list<record>, id: string, pending_operations: list<record>, record_type: string, status: string, successful_operations: list<record>, type: string, updated_at: string>>
# operationId: createPhoneNumbersJobUpdateEmergencySettings
export def "create-phone-numbers-job-update-emergency-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  emergency_address_id: string # Identifies the address to be used with emergency services. (format: int64)
  --emergency-enabled: oneof<nothing, bool> # Indicates whether to enable emergency services on this number.
  phone_numbers: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/phone_numbers/jobs/update_emergency_settings"
    body: {content_type: "application/json", kind: json, fields: [{name: emergency_address_id, var: emergency_address_id}, {name: emergency_enabled, var: emergency_enabled, required: true}, {name: phone_numbers, var: phone_numbers}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    emergency_address_id: $emergency_address_id, emergency_enabled: $emergency_enabled, phone_numbers: $phone_numbers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a batch of numbers
#
# POST /phone_numbers/jobs/update_phone_numbers
# Returns: record<data: record<created_at: string, etc: string, failed_operations: list<record>, id: string, pending_operations: list<record>, record_type: string, status: string, successful_operations: list<record>, type: string, updated_at: string>>
# operationId: createPhoneNumbersJobUpdatePhoneNumber
export def "create-phone-numbers-job-update-phone-number" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --billing-group-id: string # Identifies the billing group associated with the phone number.
  --connection-id: string # Identifies the connection associated with the phone number.
  --customer-reference: string # A customer reference string for customer look ups. (e.g. MY REF 001)
  --external-pin: string # If someone attempts to port your phone number away from Telnyx and your phone number has an external PIN set, we will attempt to verify that you provided the correct external PIN to the winning carrier. Note that not all carriers cooperate with this security mechanism.
  phone_numbers: list<string> # Array of phone number ids and/or phone numbers in E164 format to update
  --tags: list<string> # A list of user-assigned tags to help organize phone numbers.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/phone_numbers/jobs/update_phone_numbers"
    body: {content_type: "application/json", kind: json, fields: [{name: billing_group_id, var: billing_group_id}, {name: connection_id, var: connection_id}, {name: customer_reference, var: customer_reference}, {name: external_pin, var: external_pin}, {name: phone_numbers, var: phone_numbers}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    billing_group_id: $billing_group_id, connection_id: $connection_id, customer_reference: $customer_reference, external_pin: $external_pin, phone_numbers: $phone_numbers, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a phone numbers job
#
# GET /phone_numbers/jobs/{id}
# Returns: record<data: record<created_at: string, etc: string, failed_operations: list<record>, id: string, pending_operations: list<record>, record_type: string, status: string, successful_operations: list<record>, type: string, updated_at: string>>
# operationId: retrievePhoneNumbersJob
export def "retrieve-phone-numbers-job" [
  id: string
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
    path: "/phone_numbers/jobs/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List phone numbers with messaging settings
#
# GET /phone_numbers/messaging
# Returns: record<data: table<country_code: string, created_at: string, eligible_messaging_products: list, features: record, health: record, id: string, messaging_product: string, messaging_profile_id: string, phone_number: string, record_type: string, traffic_type: string, type: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: listPhoneNumbersWithMessagingSettings
export def "list-phone-numbers-with-messaging-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/phone_numbers/messaging"
    query: [{name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_number: $page_number, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List phone numbers with voice settings
#
# GET /phone_numbers/voice
# Returns: record<data: table<call_forwarding: record, call_recording: record, cnam_listing: record, connection_id: string, customer_reference: string, emergency: record, id: string, media_features: record, phone_number: string, record_type: string, tech_prefix_enabled: bool, translated_number: string, usage_payment_method: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: listPhoneNumbersWithVoiceSettings
export def "list-phone-numbers-with-voice-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
  --filter-phone-number: string # Filter by phone number. Requires at least three digits. Non-numerical characters will result in no values being returned.
  --filter-connection-name-contains: string # Filter contains connection name. Requires at least three characters. (e.g. test)
  --filter-customer-reference: string # Filter numbers via the customer_reference set.
  --filter-usage-payment-method: string@filter-usage-payment-method-completer # Filter by usage_payment_method. (e.g. channel)
  --sort: string@sort-completer-6 # Specifies the sort order for results. If not given, results are sorted by created_at in descending order. (e.g. connection_name)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/phone_numbers/voice"
    query: [{name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}, {name: "filter[phone_number]", var: filter_phone_number}, {name: "filter[connection_name][contains]", var: filter_connection_name_contains}, {name: "filter[customer_reference]", var: filter_customer_reference}, {name: "filter[usage_payment_method]", var: filter_usage_payment_method}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_number: $page_number, page_size: $page_size, filter_phone_number: $filter_phone_number, filter_connection_name_contains: $filter_connection_name_contains, filter_customer_reference: $filter_customer_reference, filter_usage_payment_method: $filter_usage_payment_method, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a phone number
#
# DELETE /phone_numbers/{id}
# Returns: record<data: record<billing_group_id: string, call_forwarding_enabled: bool, call_recording_enabled: bool, caller_id_name_enabled: bool, cnam_listing_enabled: bool, connection_id: string, connection_name: string, created_at: string, customer_reference: string, emergency_address_id: string, emergency_enabled: bool, external_pin: string, id: string, messaging_profile_id: string, messaging_profile_name: string, number_level_routing: string, phone_number: string, phone_number_type: string, purchased_at: string, record_type: string, status: string, t38_fax_gateway_enabled: bool, tags: list<string>, updated_at: string>>
# operationId: deletePhoneNumber
export def "delete-phone-number" [
  id: string
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
    method: delete
    path: "/phone_numbers/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a phone number
#
# GET /phone_numbers/{id}
# Returns: record<data: record<billing_group_id: string, call_forwarding_enabled: bool, call_recording_enabled: bool, caller_id_name_enabled: bool, cnam_listing_enabled: bool, connection_id: string, connection_name: string, created_at: string, customer_reference: string, emergency_address_id: string, emergency_enabled: bool, external_pin: string, id: string, messaging_profile_id: string, messaging_profile_name: string, number_level_routing: string, phone_number: string, phone_number_type: string, purchased_at: string, record_type: string, status: string, t38_fax_gateway_enabled: bool, tags: list<string>>>
# operationId: retrievePhoneNumber
export def "retrieve-phone-number" [
  id: string
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
    path: "/phone_numbers/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a phone number
#
# PATCH /phone_numbers/{id}
# Returns: record<data: record<billing_group_id: string, call_forwarding_enabled: bool, call_recording_enabled: bool, caller_id_name_enabled: bool, cnam_listing_enabled: bool, connection_id: string, connection_name: string, created_at: string, customer_reference: string, emergency_address_id: string, emergency_enabled: bool, external_pin: string, id: string, messaging_profile_id: string, messaging_profile_name: string, number_level_routing: string, phone_number: string, phone_number_type: string, purchased_at: string, record_type: string, status: string, t38_fax_gateway_enabled: bool, tags: list<string>>>
# operationId: updatePhoneNumber
export def "update-phone-number" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --billing-group-id: string # Identifies the billing group associated with the phone number.
  --connection-id: string # Identifies the connection associated with the phone number.
  --customer-reference: string # A customer reference string for customer look ups. (e.g. MY REF 001)
  --external-pin: string # If someone attempts to port your phone number away from Telnyx and your phone number has an external PIN set, we will attempt to verify that you provided the correct external PIN to the winning carrier. Note that not all carriers cooperate with this security mechanism.
  --number-level-routing: string@number-level-routing-completer # Specifies whether the number can have overrides to the routing settings on itself (enabled) or if it uses the associated connection for all routing settings (disabled). Defaults to enabled but will be changed to disabled in the future. There are performance advantages to using disabled and setting all routing information at the connection level. (default: enabled)
  --tags: list<string> # A list of user-assigned tags to help organize phone numbers.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/phone_numbers/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: billing_group_id, var: billing_group_id}, {name: connection_id, var: connection_id}, {name: customer_reference, var: customer_reference}, {name: external_pin, var: external_pin}, {name: number_level_routing, var: number_level_routing}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, billing_group_id: $billing_group_id, connection_id: $connection_id, customer_reference: $customer_reference, external_pin: $external_pin, number_level_routing: $number_level_routing, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enable emergency for a phone number
#
# POST /phone_numbers/{id}/actions/enable_emergency
# Returns: record<data: record<call_forwarding: record<call_forwarding_enabled: bool, forwarding_type: string, forwards_to: string>, call_recording: record<inbound_call_recording_channels: string, inbound_call_recording_enabled: bool, inbound_call_recording_format: string>, cnam_listing: record<cnam_listing_details: string, cnam_listing_enabled: bool>, connection_id: string, customer_reference: string, emergency: record<emergency_address_id: string, emergency_enabled: bool, emergency_status: string>, id: string, media_features: record<accept_any_rtp_packets_enabled: bool, media_handling_mode: string, rtp_auto_adjust_enabled: bool, t38_fax_gateway_enabled: bool>, phone_number: string, record_type: string, tech_prefix_enabled: bool, translated_number: string, usage_payment_method: string>>
# operationId: enableEmergencyPhoneNumber
export def "enable-emergency-phone-number" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  emergency_address_id: string # Identifies the address to be used with emergency services. (format: int64)
  --emergency-enabled: oneof<nothing, bool> # Indicates whether to enable emergency services on this number.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/phone_numbers/{id}/actions/enable_emergency"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: emergency_address_id, var: emergency_address_id}, {name: emergency_enabled, var: emergency_enabled, required: true}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    id: $id, emergency_address_id: $emergency_address_id, emergency_enabled: $emergency_enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a phone number with messaging settings
#
# GET /phone_numbers/{id}/messaging
# Returns: record<data: record<country_code: string, created_at: string, eligible_messaging_products: list<string>, features: record<mms: record, sms: record>, health: record<inbound_outbound_ratio: float, message_count: int, spam_ratio: float, success_ratio: float>, id: string, messaging_product: string, messaging_profile_id: string, phone_number: string, record_type: string, traffic_type: string, type: string, updated_at: string>>
# operationId: retrievePhoneNumberWithMessagingSettings
export def "retrieve-phone-number-with-messaging-settings" [
  id: string
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
    path: "/phone_numbers/{id}/messaging"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a phone number with messaging settings
#
# PATCH /phone_numbers/{id}/messaging
# Returns: record<data: record<country_code: string, created_at: string, eligible_messaging_products: list<string>, features: record<mms: record, sms: record>, health: record<inbound_outbound_ratio: float, message_count: int, spam_ratio: float, success_ratio: float>, id: string, messaging_product: string, messaging_profile_id: string, phone_number: string, record_type: string, traffic_type: string, type: string, updated_at: string>>
# operationId: updatePhoneNumberWithMessagingSettings
export def "update-phone-number-with-messaging-settings" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --messaging-product: string # The requested messaging product the number should be on (e.g. P2P)
  --messaging-profile-id: string # Unique identifier for a messaging profile.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/phone_numbers/{id}/messaging"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: messaging_product, var: messaging_product}, {name: messaging_profile_id, var: messaging_profile_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, messaging_product: $messaging_product, messaging_profile_id: $messaging_profile_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a phone number with voice settings
#
# GET /phone_numbers/{id}/voice
# Returns: record<data: record<call_forwarding: record<call_forwarding_enabled: bool, forwarding_type: string, forwards_to: string>, call_recording: record<inbound_call_recording_channels: string, inbound_call_recording_enabled: bool, inbound_call_recording_format: string>, cnam_listing: record<cnam_listing_details: string, cnam_listing_enabled: bool>, connection_id: string, customer_reference: string, emergency: record<emergency_address_id: string, emergency_enabled: bool, emergency_status: string>, id: string, media_features: record<accept_any_rtp_packets_enabled: bool, media_handling_mode: string, rtp_auto_adjust_enabled: bool, t38_fax_gateway_enabled: bool>, phone_number: string, record_type: string, tech_prefix_enabled: bool, translated_number: string, usage_payment_method: string>>
# operationId: retrievePhoneNumberWithVoiceSettings
export def "retrieve-phone-number-with-voice-settings" [
  id: string
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
    path: "/phone_numbers/{id}/voice"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a phone number with voice settings
#
# PATCH /phone_numbers/{id}/voice
# Returns: record<data: record<call_forwarding: record<call_forwarding_enabled: bool, forwarding_type: string, forwards_to: string>, call_recording: record<inbound_call_recording_channels: string, inbound_call_recording_enabled: bool, inbound_call_recording_format: string>, cnam_listing: record<cnam_listing_details: string, cnam_listing_enabled: bool>, connection_id: string, customer_reference: string, emergency: record<emergency_address_id: string, emergency_enabled: bool, emergency_status: string>, id: string, media_features: record<accept_any_rtp_packets_enabled: bool, media_handling_mode: string, rtp_auto_adjust_enabled: bool, t38_fax_gateway_enabled: bool>, phone_number: string, record_type: string, tech_prefix_enabled: bool, translated_number: string, usage_payment_method: string>>
# operationId: updatePhoneNumberWithVoiceSettings
export def "update-phone-number-with-voice-settings" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --call-forwarding: record # The call forwarding settings for a phone number. (e.g. {call_forwarding_enabled: true, forwarding_type: always, forwards_to: +13035559123}) — shape: {call_forwarding_enabled?: bool, forwarding_type?: "always"|"on_failure", forwards_to?: string}
  --call-recording: record # The call recording settings for a phone number. (e.g. {inbound_call_recording_channels: single, inbound_call_recording_enabled: true, inbound_call_recording_format: wav}) — shape: {inbound_call_recording_channels?: "single"|"dual", inbound_call_recording_enabled?: bool, inbound_call_recording_format?: "wav"|"mp3"}
  --cnam-listing: record # The CNAM listing settings for a phone number. (e.g. {cnam_listing_details: example, cnam_listing_enabled: true}) — shape: {cnam_listing_details?: string, cnam_listing_enabled?: bool}
  --media-features: record # The media features settings for a phone number. (e.g. {accept_any_rtp_packets_enabled: true, media_handling_mode: default, rtp_auto_adjust_enabled: true, t38_fax_gateway_enabled: true}) — shape: {accept_any_rtp_packets_enabled?: bool, media_handling_mode?: "default"|"proxy", rtp_auto_adjust_enabled?: bool, t38_fax_gateway_enabled?: bool}
  --tech-prefix-enabled: oneof<nothing, bool> # Controls whether a tech prefix is enabled for this phone number. (default: false)
  --translated-number: string # This field allows you to rewrite the destination number of an inbound call before the call is routed to you. The value of this field may be any alphanumeric value, and the value will replace the number originally dialed.
  --usage-payment-method: string@usage-payment-method-completer-1 # Controls whether a number is billed per minute or uses your concurrent channels. (default: pay-per-minute)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/phone_numbers/{id}/voice"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: call_forwarding, var: call_forwarding}, {name: call_recording, var: call_recording}, {name: cnam_listing, var: cnam_listing}, {name: media_features, var: media_features}, {name: tech_prefix_enabled, var: tech_prefix_enabled}, {name: translated_number, var: translated_number}, {name: usage_payment_method, var: usage_payment_method}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, call_forwarding: $call_forwarding, call_recording: $call_recording, cnam_listing: $cnam_listing, media_features: $media_features, tech_prefix_enabled: $tech_prefix_enabled, translated_number: $translated_number, usage_payment_method: $usage_payment_method
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Run a portability check
#
# POST /portability_checks
# Returns: record<data: table<fast_portable: bool, not_portable_reason: string, phone_number: string, portable: bool, record_type: string>>
# operationId: postPortabilityCheck
export def "post-portability-check" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --phone-numbers: list<string> # The list of +E.164 formatted phone numbers to check for portability (e.g. [+13035550000, +13035550001, +13035550002])
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/portability_checks"
    body: {content_type: "application/json", kind: json, fields: [{name: phone_numbers, var: phone_numbers}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    phone_numbers: $phone_numbers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all porting orders
#
# GET /porting_orders
# Returns: record<data: table<activation_settings: record, created_at: string, end_user: record, id: string, misc: record, old_service_provider_ocn: string, phone_number_configuration: record, porting_phone_numbers_count: int, record_type: string, requirements: list, status: record, support_key: string, updated_at: string, user_feedback: record, user_reference: string, webhook_url: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: listPortingOrders
export def "list-porting-orders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
  --include-phone-numbers: oneof<nothing, bool> # Include the first 50 phone number objects in the results (default: true)
  --filter-status: record # Filter results by status
  --filter-customer-reference: string # Filter results by user reference (e.g. 123abc)
  --filter-phone-numbers-country-code: string # Filter results by country ISO 3166-1 alpha-2 code (e.g. US)
  --filter-phone-numbers-carrier-name: string # Filter results by old service provider (e.g. Telnyx)
  --filter-misc-type: string@filter-misc-type-completer # Filter results by porting order type (e.g. full)
  --filter-end-user-admin-entity-name: string # Filter results by person or company name (e.g. Porter McPortersen)
  --filter-end-user-admin-auth-person-name: string # Filter results by authorized person (e.g. Admin McPortersen)
  --filter-activation-settings-fast-port-eligible: oneof<nothing, bool> # Filter results by fast port eligible (e.g. false)
  --filter-activation-settings-foc-datetime-requested-gt: string # Filter results by foc date later than this value (e.g. 2021-03-25T10:00:00.000Z)
  --filter-activation-settings-foc-datetime-requested-lt: string # Filter results by foc date earlier than this value (e.g. 2021-03-25T10:00:00.000Z)
  --sort: string@sort-completer-7 # Specifies the sort order for results. If not given, results are sorted by created_at in descending order. (e.g. created_at)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/porting_orders"
    query: [{name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}, {name: include_phone_numbers, var: include_phone_numbers}, {name: "filter[status]", var: filter_status, style: multi}, {name: "filter[customer_reference]", var: filter_customer_reference}, {name: "filter[phone_numbers][country_code]", var: filter_phone_numbers_country_code}, {name: "filter[phone_numbers][carrier_name]", var: filter_phone_numbers_carrier_name}, {name: "filter[misc][type]", var: filter_misc_type}, {name: "filter[end_user][admin][entity_name]", var: filter_end_user_admin_entity_name}, {name: "filter[end_user][admin][auth_person_name]", var: filter_end_user_admin_auth_person_name}, {name: "filter[activation_settings][fast_port_eligible]", var: filter_activation_settings_fast_port_eligible}, {name: "filter[activation_settings][foc_datetime_requested][gt]", var: filter_activation_settings_foc_datetime_requested_gt}, {name: "filter[activation_settings][foc_datetime_requested][lt]", var: filter_activation_settings_foc_datetime_requested_lt}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_number: $page_number, page_size: $page_size, include_phone_numbers: $include_phone_numbers, filter_status: $filter_status, filter_customer_reference: $filter_customer_reference, filter_phone_numbers_country_code: $filter_phone_numbers_country_code, filter_phone_numbers_carrier_name: $filter_phone_numbers_carrier_name, filter_misc_type: $filter_misc_type, filter_end_user_admin_entity_name: $filter_end_user_admin_entity_name, filter_end_user_admin_auth_person_name: $filter_end_user_admin_auth_person_name, filter_activation_settings_fast_port_eligible: $filter_activation_settings_fast_port_eligible, filter_activation_settings_foc_datetime_requested_gt: $filter_activation_settings_foc_datetime_requested_gt, filter_activation_settings_foc_datetime_requested_lt: $filter_activation_settings_foc_datetime_requested_lt, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a porting order
#
# POST /porting_orders
# Returns: record<data: table<activation_settings: record, created_at: string, end_user: record, id: string, misc: record, old_service_provider_ocn: string, phone_number_configuration: record, porting_phone_numbers_count: int, record_type: string, requirements: list, status: record, support_key: string, updated_at: string, user_feedback: record, user_reference: string, webhook_url: string>>
# operationId: createPortingOrder
export def "create-porting-order" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  phone_numbers: list<string> # The list of +E.164 formatted phone numbers (e.g. [+13035550000, +13035550001, +13035550002])
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/porting_orders"
    body: {content_type: "application/json", kind: json, fields: [{name: phone_numbers, var: phone_numbers}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    phone_numbers: $phone_numbers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all exception types
#
# GET /porting_orders/exception_types
# Returns: record<data: table<code: string, description: string>>
# operationId: listPortingOrdersExceptionTypes
export def "list-porting-orders-exception-types" [
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
    path: "/porting_orders/exception_types"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request cancellation
#
# DELETE /porting_orders/{id}
# Returns: record<data: record<activation_settings: record<activation_status: string, fast_port_eligible: bool, foc_datetime_actual: string, foc_datetime_requested: string>, created_at: string, end_user: record<admin: record, location: record>, id: string, misc: record<new_billing_phone_number: string, remaining_numbers_action: string, type: string>, old_service_provider_ocn: string, phone_number_configuration: record<connection_id: string, emergency_address_id: string, messaging_profile_id: string, tags: list>, porting_phone_numbers_count: int, record_type: string, requirements: list<record>, status: record<details: list, value: string>, support_key: string, updated_at: string, user_feedback: record<user_comment: string, user_rating: int>, user_reference: string, webhook_url: string>, meta: record<phone_numbers_url: string>>
# operationId: deletePortingOrder
export def "delete-porting-order" [
  id: string
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
    method: delete
    path: "/porting_orders/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a porting order
#
# GET /porting_orders/{id}
# Returns: record<data: record<activation_settings: record<activation_status: string, fast_port_eligible: bool, foc_datetime_actual: string, foc_datetime_requested: string>, created_at: string, end_user: record<admin: record, location: record>, id: string, misc: record<new_billing_phone_number: string, remaining_numbers_action: string, type: string>, old_service_provider_ocn: string, phone_number_configuration: record<connection_id: string, emergency_address_id: string, messaging_profile_id: string, tags: list>, porting_phone_numbers_count: int, record_type: string, requirements: list<record>, status: record<details: list, value: string>, support_key: string, updated_at: string, user_feedback: record<user_comment: string, user_rating: int>, user_reference: string, webhook_url: string>, meta: record<phone_numbers_url: string>>
# operationId: getPortingOrder
export def "get-porting-order" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-phone-numbers: oneof<nothing, bool> # Include the first 50 phone number objects in the results (default: true)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/porting_orders/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: include_phone_numbers, var: include_phone_numbers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, include_phone_numbers: $include_phone_numbers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit a porting order
#
# PATCH /porting_orders/{id}
# Returns: record<data: record<activation_settings: record<activation_status: string, fast_port_eligible: bool, foc_datetime_actual: string, foc_datetime_requested: string>, created_at: string, end_user: record<admin: record, location: record>, id: string, misc: record<new_billing_phone_number: string, remaining_numbers_action: string, type: string>, old_service_provider_ocn: string, phone_number_configuration: record<connection_id: string, emergency_address_id: string, messaging_profile_id: string, tags: list>, porting_phone_numbers_count: int, record_type: string, requirements: list<record>, status: record<details: list, value: string>, support_key: string, updated_at: string, user_feedback: record<user_comment: string, user_rating: int>, user_reference: string, webhook_url: string>, meta: record<phone_numbers_url: string>>
# operationId: updatePortingOrder
export def "update-porting-order" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --activation-settings: record # shape: {foc_datetime_requested?: string}
  --customer-reference: string
  --end-user: record # shape: {admin?: record, location?: record}
  --misc: record # shape: {new_billing_phone_number?: string, remaining_numbers_action?: "keep"|"disconnect", type?: "full"|"partial"}
  --phone-number-configuration: record # shape: {connection_id?: string, emergency_address_id?: string, messaging_profile_id?: string, tags?: list<string>}
  --requirements: list # List of requirements for porting numbers. — item shape: {field_value: string, requirement_type_id: string}
  --user-feedback: record # shape: {user_comment?: string, user_rating?: int}
  --webhook-url: string # format: uri
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/porting_orders/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: activation_settings, var: activation_settings}, {name: customer_reference, var: customer_reference}, {name: end_user, var: end_user}, {name: misc, var: misc}, {name: phone_number_configuration, var: phone_number_configuration}, {name: requirements, var: requirements}, {name: user_feedback, var: user_feedback}, {name: webhook_url, var: webhook_url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, activation_settings: $activation_settings, customer_reference: $customer_reference, end_user: $end_user, misc: $misc, phone_number_configuration: $phone_number_configuration, requirements: $requirements, user_feedback: $user_feedback, webhook_url: $webhook_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Activates every number on a porting order.
#
# POST /porting_orders/{id}/actions/activate
# Returns: record<data: record<created_at: string, id: string, record_type: string, status: string, updated_at: string>>
# operationId: activatePortingOrder
export def "activate-porting-order" [
  id: string
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
    method: post
    path: "/porting_orders/{id}/actions/activate"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancel this porting order
#
# POST /porting_orders/{id}/actions/cancel
# Returns: record<data: record<activation_settings: record<activation_status: string, fast_port_eligible: bool, foc_datetime_actual: string, foc_datetime_requested: string>, created_at: string, end_user: record<admin: record, location: record>, id: string, misc: record<new_billing_phone_number: string, remaining_numbers_action: string, type: string>, old_service_provider_ocn: string, phone_number_configuration: record<connection_id: string, emergency_address_id: string, messaging_profile_id: string, tags: list>, porting_phone_numbers_count: int, record_type: string, requirements: list<record>, status: record<details: list, value: string>, support_key: string, updated_at: string, user_feedback: record<user_comment: string, user_rating: int>, user_reference: string, webhook_url: string>, meta: record<phone_numbers_url: string>>
# operationId: cancelPortingOrder
export def "cancel-porting-order" [
  id: string
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
    method: post
    path: "/porting_orders/{id}/actions/cancel"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Confirms the porting order is ready to be actioned.
#
# POST /porting_orders/{id}/actions/confirm
# Returns: record<data: record<activation_settings: record<activation_status: string, fast_port_eligible: bool, foc_datetime_actual: string, foc_datetime_requested: string>, created_at: string, end_user: record<admin: record, location: record>, id: string, misc: record<new_billing_phone_number: string, remaining_numbers_action: string, type: string>, old_service_provider_ocn: string, phone_number_configuration: record<connection_id: string, emergency_address_id: string, messaging_profile_id: string, tags: list>, porting_phone_numbers_count: int, record_type: string, requirements: list<record>, status: record<details: list, value: string>, support_key: string, updated_at: string, user_feedback: record<user_comment: string, user_rating: int>, user_reference: string, webhook_url: string>, meta: record<phone_numbers_url: string>>
# operationId: confirmPortingOrder
export def "confirm-porting-order" [
  id: string
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
    method: post
    path: "/porting_orders/{id}/actions/confirm"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all porting activation jobs
#
# GET /porting_orders/{id}/activation_jobs
# Returns: record<data: table<created_at: string, id: string, record_type: string, status: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: listPortingOrdersActivationJobs
export def "list-porting-orders-activation-jobs" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/porting_orders/{id}/activation_jobs"
    path_params: [{name: id, var: id}]
    query: [{name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, page_number: $page_number, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a porting activation job
#
# GET /porting_orders/{id}/activation_jobs/{activationJobId}
# Returns: record<data: record<created_at: string, id: string, record_type: string, status: string, updated_at: string>>
# operationId: getPortingOrdersActivationJob
export def "get-porting-orders-activation-job" [
  id: string
  activation_job_id: string
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
    path: "/porting_orders/{id}/activation_jobs/{activationJobId}"
    path_params: [{name: id, var: id}, {name: activationJobId, var: activation_job_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, activation_job_id: $activation_job_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all comments of a porting order
#
# GET /porting_orders/{id}/comments
# Returns: record<data: table<body: string, created_at: string, id: string, porting_order_id: string, record_type: string, user_type: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: listPortingOrdersComments
export def "list-porting-orders-comments" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/porting_orders/{id}/comments"
    path_params: [{name: id, var: id}]
    query: [{name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, page_number: $page_number, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a comment for a porting order
#
# POST /porting_orders/{id}/comments
# Returns: record<data: record<body: string, created_at: string, id: string, porting_order_id: string, record_type: string, user_type: string>>
# operationId: createPortingOrderComment
export def "create-porting-order-comment" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: string # e.g. Please, let me know when the port completes
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/porting_orders/{id}/comments"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: body, var: body}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download a porting order loa template
#
# GET /porting_orders/{id}/loa_template
# Returns: binary
# operationId: getPortingOrderLOATemplate
export def "get-porting-order-loa-template" [
  id: string
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
    path: "/porting_orders/{id}/loa_template"
    path_params: [{name: id, var: id}]
    accept: ["application/pdf"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all porting phone numbers
#
# GET /porting_phone_numbers
# Returns: record<data: table<id: string, phone_number: string, record_type: string, regulatory_group_id: string, regulatory_requirements: list, requirements_met: bool, status: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
export def "get-porting-phone-numbers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
  --filter-porting-order-id: string # Filter results by porting order id (format: uuid)
  --filter-phone-number: string # Filter results by phone number
  --filter-activation-status: string@filter-activation-status-completer # Filter results by activation status (e.g. Active)
  --filter-portability-status: string@filter-portability-status-completer # Filter results by portability status (e.g. confirmed)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/porting_phone_numbers"
    query: [{name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}, {name: "filter[porting_order_id]", var: filter_porting_order_id}, {name: "filter[phone_number]", var: filter_phone_number}, {name: "filter[activation_status]", var: filter_activation_status}, {name: "filter[portability_status]", var: filter_portability_status}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_number: $page_number, page_size: $page_size, filter_porting_order_id: $filter_porting_order_id, filter_phone_number: $filter_phone_number, filter_activation_status: $filter_activation_status, filter_portability_status: $filter_portability_status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of portout requests
#
# GET /portouts
# Returns: record<data: table<carrier_name: string, created_at: string, foc_date: string, id: string, phone_numbers: list, record_type: string, requested_foc_date: string, spid: string, status: string, updated_at: string>, meta: record<page_number: float, page_size: float, total_pages: float, total_results: float>>
# operationId: listPortoutRequest
export def "list-portout-request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-carrier-name: string # Filter by new carrier name.
  --filter-spid: string # Filter by new carrier spid.
  --filter-status: string@filter-status-completer-4 # Filter by portout status.
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/portouts"
    query: [{name: "filter[carrier_name]", var: filter_carrier_name}, {name: "filter[spid]", var: filter_spid}, {name: "filter[status]", var: filter_status}, {name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter_carrier_name: $filter_carrier_name, filter_spid: $filter_spid, filter_status: $filter_status, page_number: $page_number, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a portout request
#
# GET /portouts/{id}
# Returns: record<data: record<carrier_name: string, created_at: string, foc_date: string, id: string, phone_numbers: list<string>, record_type: string, requested_foc_date: string, spid: string, status: string, updated_at: string>>
# operationId: findPortoutRequest
export def "find-portout-request" [
  id: string
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
    path: "/portouts/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all comments for a portout request
#
# GET /portouts/{id}/comments
# Returns: record<data: table<body: string, created_at: string, id: string, portout_id: string, record_type: string, user_id: string>, meta: record<page_number: float, page_size: float, total_pages: float, total_results: float>>
# operationId: findPortoutComments
export def "find-portout-comments" [
  id: string
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
    path: "/portouts/{id}/comments"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a comment on a portout request
#
# POST /portouts/{id}/comments
# Returns: record<data: record<body: string, created_at: string, id: string, portout_id: string, record_type: string, user_id: string>>
# operationId: postPortRequestComment
export def "post-port-request-comment" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: string # Comment to post on this portout request
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/portouts/{id}/comments"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: body, var: body}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Status
#
# PATCH /portouts/{id}/{status}
# Returns: record<data: record<carrier_name: string, created_at: string, foc_date: string, id: string, phone_numbers: list<string>, record_type: string, requested_foc_date: string, spid: string, status: string, updated_at: string>>
# operationId: updatePortoutRequest
export def "update-portout-request" [
  id: string
  status: string@status-completer-2
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
    method: patch
    path: "/portouts/{id}/{status}"
    path_params: [{name: id, var: id}, {name: status, var: status}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all Private Wireless Gateways
#
# GET /private_wireless_gateways
# Returns: record<data: table<created_at: string, id: string, ip_range: string, name: string, network_id: string, record_type: string, region_code: string, status: record, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: getPrivateWirelessGateways
export def "get-private-wireless-gateways" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
  --filter-name: string # The name of the Private Wireless Gateway. (e.g. my private gateway)
  --filter-ip-range: string # The IP address range of the Private Wireless Gateway. (e.g. 192.168.0.0/24)
  --filter-region-code: string # The name of the region where the Private Wireless Gateway is deployed. (e.g. ashburn-va)
  --filter-created-at: string # Private Wireless Gateway resource creation date. (e.g. 2018-02-02T22:25:27.521Z)
  --filter-updated-at: string # When the Private Wireless Gateway was last updated. (e.g. 2018-02-02T22:25:27.521Z)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/private_wireless_gateways"
    query: [{name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}, {name: "filter[name]", var: filter_name}, {name: "filter[ip_range]", var: filter_ip_range}, {name: "filter[region_code]", var: filter_region_code}, {name: "filter[created_at]", var: filter_created_at}, {name: "filter[updated_at]", var: filter_updated_at}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_number: $page_number, page_size: $page_size, filter_name: $filter_name, filter_ip_range: $filter_ip_range, filter_region_code: $filter_region_code, filter_created_at: $filter_created_at, filter_updated_at: $filter_updated_at
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a Private Wireless Gateway
#
# POST /private_wireless_gateways
# Returns: record<data: record<created_at: string, id: string, ip_range: string, name: string, network_id: string, record_type: string, region_code: string, status: record<error_code: string, error_description: string, value: string>, updated_at: string>>
# operationId: createPrivateWirelessGateway
export def "create-private-wireless-gateway" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The private wireless gateway name. (e.g. My private wireless gateway)
  network_id: string # The identification of the related network resource. (format: uuid, e.g. 6a09cdc3-8948-47f0-aa62-74ac943d6c58)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/private_wireless_gateways"
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: network_id, var: network_id}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    name: $name, network_id: $network_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a Private Wireless Gateway
#
# DELETE /private_wireless_gateways/{id}
# Returns: record<data: record<created_at: string, id: string, ip_range: string, name: string, network_id: string, record_type: string, region_code: string, status: record<error_code: string, error_description: string, value: string>, updated_at: string>>
# operationId: deletePrivateWirelessGateway
export def "delete-private-wireless-gateway" [
  id: string
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
    method: delete
    path: "/private_wireless_gateways/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a Private Wireless Gateway
#
# GET /private_wireless_gateways/{id}
# Returns: record<data: record<created_at: string, id: string, ip_range: string, name: string, network_id: string, record_type: string, region_code: string, status: record<error_code: string, error_description: string, value: string>, updated_at: string>>
# operationId: getPrivateWirelessGateway
export def "get-private-wireless-gateway" [
  id: string
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
    path: "/private_wireless_gateways/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a call queue
#
# GET /queues/{queue_name}
# Returns: record<data: record<average_wait_time_secs: int, created_at: string, current_size: int, id: string, max_size: int, name: string, record_type: string, updated_at: string>>
# operationId: retrieveCallQueue
export def "retrieve-call-queue" [
  queue_name: string
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
    path: "/queues/{queue_name}"
    path_params: [{name: queue_name, var: queue_name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    queue_name: $queue_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve calls from a queue
#
# GET /queues/{queue_name}/calls
# Returns: record<data: table<call_control_id: string, call_leg_id: string, call_session_id: string, connection_id: string, enqueued_at: string, from: string, queue_id: string, queue_position: int, record_type: string, to: string, wait_time_secs: int>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: listQueueCalls
export def "list-queue-calls" [
  queue_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/queues/{queue_name}/calls"
    path_params: [{name: queue_name, var: queue_name}]
    query: [{name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    queue_name: $queue_name, page_number: $page_number, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a call from a queue
#
# GET /queues/{queue_name}/calls/{call_control_id}
# Returns: record<data: record<call_control_id: string, call_leg_id: string, call_session_id: string, connection_id: string, enqueued_at: string, from: string, queue_id: string, queue_position: int, record_type: string, to: string, wait_time_secs: int>>
# operationId: retrieveCallFromQueue
export def "retrieve-call-from-queue" [
  queue_name: string
  call_control_id: string
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
    path: "/queues/{queue_name}/calls/{call_control_id}"
    path_params: [{name: queue_name, var: queue_name}, {name: call_control_id, var: call_control_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    queue_name: $queue_name, call_control_id: $call_control_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List recordings
#
# GET /recordings
# Returns: record<data: table<call_leg_id: string, call_session_id: string, channels: string, conference_id: string, created_at: string, download_urls: record, duration_millis: int, id: string, record_type: string, recording_ended_at: string, recording_started_at: string, source: string, status: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: listRecordings
export def "list-recordings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-conference-id: string # Return only recordings associated with a given conference (e.g. 428c31b6-7af4-4bcb-b7f5-5013ef9657c1)
  --filter-created-at-gte: string # Return only recordings created later than or at given ISO 8601 datetime (e.g. 2019-03-29T11:10:00Z)
  --filter-created-at-lte: string # Return only recordings created earlier than or at given ISO 8601 datetime (e.g. 2019-03-29T11:10:00Z)
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/recordings"
    query: [{name: "filter[conference_id]", var: filter_conference_id}, {name: "filter[created_at][gte]", var: filter_created_at_gte}, {name: "filter[created_at][lte]", var: filter_created_at_lte}, {name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter_conference_id: $filter_conference_id, filter_created_at_gte: $filter_created_at_gte, filter_created_at_lte: $filter_created_at_lte, page_number: $page_number, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a recording
#
# GET /recordings/{id}
# Returns: record<data: record<call_leg_id: string, call_session_id: string, channels: string, conference_id: string, created_at: string, download_urls: record<mp3: string, wav: string>, duration_millis: int, id: string, record_type: string, recording_ended_at: string, recording_started_at: string, source: string, status: string, updated_at: string>>
# operationId: retrieveRecording
export def "retrieve-recording" [
  id: string
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
    path: "/recordings/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch all previous requests for messaging detail reports. Messaging detail reports are reports for pulling all messaging records.
#
# GET /reports/batch_mdr_reports
# Returns: record<data: table<connections: list, created_at: string, directions: list, end_date: string, filters: list, id: string, profiles: string, record_type: string, record_types: list, report_name: string, report_url: string, start_date: string, status: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: getCdrRequests
export def "get-cdr-requests" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # Page number (format: int32, default: 1)
  --page-size: int # Size of the page (format: int32, default: 20)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/reports/batch_mdr_reports"
    query: [{name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_number: $page_number, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Submit a request for new messaging detail report. Messaging detail report pulls all raw messaging data according to defined filters.
#
# POST /reports/batch_mdr_reports
# Returns: record<data: record<connections: list<int>, created_at: string, directions: list<string>, end_date: string, filters: list<record>, id: string, profiles: string, record_type: string, record_types: list<string>, report_name: string, report_url: string, start_date: string, status: string, updated_at: string>>
# operationId: submitMdrRequest
export def "submit-mdr-request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --connections: list<int>
  --directions: list<string>
  end_date: string # format: date-time, e.g. 2020-07-01T00:00:00-06:00
  --filters: list # item shape: {billing_group?: string, cld?: string, cld_filter?: "contains"|"starts_with"|"ends_with", cli?: string, cli_filter?: "contains"|"starts_with"|"ends_with", filter_type?: "and"|"or", tags_list?: string}
  --include-message-body: oneof<nothing, bool> # e.g. true
  --profiles: string # e.g. My profile
  --record-types: list<string>
  --report-name: string
  start_date: string # format: date-time, e.g. 2020-07-01T00:00:00-06:00
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/reports/batch_mdr_reports"
    body: {content_type: "application/json", kind: json, fields: [{name: connections, var: connections}, {name: directions, var: directions}, {name: end_date, var: end_date}, {name: filters, var: filters}, {name: include_message_body, var: include_message_body}, {name: profiles, var: profiles}, {name: record_types, var: record_types}, {name: report_name, var: report_name}, {name: start_date, var: start_date}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    connections: $connections, directions: $directions, end_date: $end_date, filters: $filters, include_message_body: $include_message_body, profiles: $profiles, record_types: $record_types, report_name: $report_name, start_date: $start_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete generated messaging detail report by id
#
# DELETE /reports/batch_mdr_reports/{id}
# Returns: record<data: record<connections: list<int>, created_at: string, directions: list<string>, end_date: string, filters: list<record>, id: string, profiles: string, record_type: string, record_types: list<string>, report_name: string, report_url: string, start_date: string, status: string, updated_at: string>>
# operationId: deleteMdrRequest
export def "delete-mdr-request" [
  id: string
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
    method: delete
    path: "/reports/batch_mdr_reports/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch single messaging detail report by id.
#
# GET /reports/batch_mdr_reports/{id}
# Returns: record<data: record<connections: list<int>, created_at: string, directions: list<string>, end_date: string, filters: list<record>, id: string, profiles: string, record_type: string, record_types: list<string>, report_name: string, report_url: string, start_date: string, status: string, updated_at: string>>
# operationId: getMdrRequest
export def "get-mdr-request" [
  id: string
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
    path: "/reports/batch_mdr_reports/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generate and fetch voice usage report synchronously. This endpoint will both generate and fetch the voice report over a specified time period. No polling is necessary but the response may take up to a couple of minutes.
#
# GET /reports/cdr_usage_reports/sync
# Returns: record<data: record<aggregation_type: string, connections: list<int>, created_at: string, end_time: string, id: string, product_breakdown: string, record_type: string, report_url: string, result: record, start_time: string, status: string, updated_at: string>>
# operationId: getUsageReportSync
export def "get-usage-report-sync" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # format: date-time, e.g. 2020-07-01T00:00:00-06:00
  --end-date: string # format: date-time, e.g. 2020-07-01T00:00:00-06:00
  --aggregation-type: string@aggregation-type-completer # required, e.g. no_aggregation
  --product-breakdown: string@product-breakdown-completer # required, e.g. no_breakdown
  --connections: list<float> # e.g. 1234567890123
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/reports/cdr_usage_reports/sync"
    query: [{name: start_date, var: start_date}, {name: end_date, var: end_date}, {name: aggregation_type, var: aggregation_type, required: true}, {name: product_breakdown, var: product_breakdown, required: true}, {name: connections, var: connections, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    start_date: $start_date, end_date: $end_date, aggregation_type: $aggregation_type, product_breakdown: $product_breakdown, connections: $connections
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch all messaging usage reports. Usage reports are aggregated messaging data for specified time period and breakdown
#
# GET /reports/mdr_usage_reports
# Returns: record<data: table<aggregation_type: string, connections: list, created_at: string, end_date: string, id: string, profiles: string, record_type: string, report_url: string, result: list, start_date: string, status: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: getUsageReports
export def "get-usage-reports" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # Page number (format: int32, default: 1)
  --page-size: int # Size of the page (format: int32, default: 20)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/reports/mdr_usage_reports"
    query: [{name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_number: $page_number, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Submit request for new new messaging usage report. This endpoint will pull and aggregate messaging data in specified time period.
#
# POST /reports/mdr_usage_reports
# Returns: record<data: record<aggregation_type: string, connections: list<int>, created_at: string, end_date: string, id: string, profiles: string, record_type: string, report_url: string, result: list<record>, start_date: string, status: string, updated_at: string>>
# operationId: submitUsageReport
export def "submit-usage-report" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  aggregation_type: string@aggregation-type-completer-1
  end_date: string # format: date-time, e.g. 2020-07-01T00:00:00-06:00
  --profiles: string # e.g. My profile
  start_date: string # format: date-time, e.g. 2020-07-01T00:00:00-06:00
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/reports/mdr_usage_reports"
    body: {content_type: "application/json", kind: json, fields: [{name: aggregation_type, var: aggregation_type}, {name: end_date, var: end_date}, {name: profiles, var: profiles}, {name: start_date, var: start_date}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aggregation_type: $aggregation_type, end_date: $end_date, profiles: $profiles, start_date: $start_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generate and fetch messaging usage report synchronously. This endpoint will both generate and fetch the messaging report over a specified time period. No polling is necessary but the response may take up to a couple of minutes.
#
# GET /reports/mdr_usage_reports/sync
# Returns: record<data: record<aggregation_type: string, connections: list<int>, created_at: string, end_date: string, id: string, profiles: string, record_type: string, report_url: string, result: list<record>, start_date: string, status: string, updated_at: string>>
# operationId: getUsageReportSync_1
export def "get-usage-report-sync-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # format: date-time, e.g. 2020-07-01T00:00:00-06:00
  --end-date: string # format: date-time, e.g. 2020-07-01T00:00:00-06:00
  --aggregation-type: string@aggregation-type-completer-1 # required, e.g. profile
  --profiles: list<string> # e.g. My profile
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/reports/mdr_usage_reports/sync"
    query: [{name: start_date, var: start_date}, {name: end_date, var: end_date}, {name: aggregation_type, var: aggregation_type, required: true}, {name: profiles, var: profiles, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    start_date: $start_date, end_date: $end_date, aggregation_type: $aggregation_type, profiles: $profiles
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete messaging usage report by id
#
# DELETE /reports/mdr_usage_reports/{id}
# Returns: record<data: record<aggregation_type: string, connections: list<int>, created_at: string, end_date: string, id: string, profiles: string, record_type: string, report_url: string, result: list<record>, start_date: string, status: string, updated_at: string>>
# operationId: deleteUsageReport
export def "delete-usage-report" [
  id: string
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
    method: delete
    path: "/reports/mdr_usage_reports/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a single messaging usage report by id
#
# GET /reports/mdr_usage_reports/{id}
# Returns: record<data: record<aggregation_type: string, connections: list<int>, created_at: string, end_date: string, id: string, profiles: string, record_type: string, report_url: string, result: list<record>, start_date: string, status: string, updated_at: string>>
# operationId: getUsageReport
export def "get-usage-report" [
  id: string
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
    path: "/reports/mdr_usage_reports/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch all Mdr records
#
# GET /reports/mdrs
# Returns: record<data: table<cld: string, cli: string, cost: string, created_at: string, currency: string, direction: string, id: string, message_type: string, parts: float, profile_name: string, rate: string, record_type: string, status: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
export def "get-reports-mdrs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # Pagination start date
  --end-date: string # Pagination end date
  --id: string # e.g. e093fbe0-5bde-11eb-ae93-0242ac130002
  --direction: string@direction-completer # e.g. INBOUND
  --profile: string # e.g. My profile
  --cld: string # e.g. +15551237654
  --cli: string # e.g. +15551237654
  --status: string@status-completer-1 # e.g. DELIVERED
  --message-type: string@message-type-completer-1 # e.g. SMS
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/reports/mdrs"
    query: [{name: start_date, var: start_date}, {name: end_date, var: end_date}, {name: id, var: id}, {name: direction, var: direction}, {name: profile, var: profile}, {name: cld, var: cld}, {name: cli, var: cli}, {name: status, var: status}, {name: message_type, var: message_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    start_date: $start_date, end_date: $end_date, id: $id, direction: $direction, profile: $profile, cld: $cld, cli: $cli, status: $status, message_type: $message_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch all Wdr records
#
# GET /reports/wdrs
# Returns: record<data: table<cost: record, created_at: string, downlink_data: record, duration_seconds: float, id: string, imsi: string, mcc: string, mnc: string, phone_number: string, rate: record, record_type: string, sim_card_id: string, sim_group_id: string, sim_group_name: string, uplink_data: record>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: getPaginatedWdrs
export def "get-paginated-wdrs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # Start date (e.g. 2021-05-01T00:00:00Z)
  --end-date: string # End date (e.g. 2021-06-01T00:00:00Z)
  --id: string # e.g. e093fbe0-5bde-11eb-ae93-0242ac130002
  --mcc: string # e.g. 204
  --mnc: string # e.g. 01
  --imsi: string # e.g. 123456
  --sim-group-name: string # e.g. sim name
  --sim-group-id: string # e.g. f05a189f-7c46-4531-ac56-1460dc465a42
  --sim-card-id: string # e.g. 877f80a6-e5b2-4687-9a04-88076265720f
  --phone-number: string # e.g. +12345678910
  --page-number: int # Page number (format: int32, default: 1)
  --page-size: int # Size of the page (format: int32, default: 20)
  --sort: list<string> # default: created_at, e.g. created_at
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/reports/wdrs"
    query: [{name: start_date, var: start_date}, {name: end_date, var: end_date}, {name: id, var: id}, {name: mcc, var: mcc}, {name: mnc, var: mnc}, {name: imsi, var: imsi}, {name: sim_group_name, var: sim_group_name}, {name: sim_group_id, var: sim_group_id}, {name: sim_card_id, var: sim_card_id}, {name: phone_number, var: phone_number}, {name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}, {name: sort, var: sort, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    start_date: $start_date, end_date: $end_date, id: $id, mcc: $mcc, mnc: $mnc, imsi: $imsi, sim_group_name: $sim_group_name, sim_group_id: $sim_group_id, sim_card_id: $sim_card_id, phone_number: $phone_number, page_number: $page_number, page_size: $page_size, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all requirement types
#
# GET /requirement_types
# Returns: record<data: table<acceptance_criteria: record, created_at: string, description: string, example: string, id: string, name: string, record_type: string, type: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: docReqsListRequirementTypes
export def "doc-reqs-list-requirement-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-name-contains: string # Filters requirement types to those whose name contains a certain string. (e.g. utility bill)
  --sort: string@sort-completer-8 # Specifies the sort order for results. If you want to sort by a field in ascending order, include it as a sort parameter. If you want to sort in descending order, prepend a `-` in front of the field name. (e.g. country_code)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/requirement_types"
    query: [{name: "filter[name][contains]", var: filter_name_contains}, {name: "sort[]", var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter_name_contains: $filter_name_contains, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a requirement types
#
# GET /requirement_types/{id}
# Returns: record<data: record<acceptance_criteria: record<locality_limit: string, time_limit: string>, created_at: string, description: string, example: string, id: string, name: string, record_type: string, type: string, updated_at: string>>
# operationId: docReqsRetrieveRequirementType
export def "doc-reqs-retrieve-requirement-type" [
  id: string
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
    path: "/requirement_types/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all requirements
#
# GET /requirements
# Returns: record<data: table<action: string, country_code: string, created_at: string, id: string, locality: string, phone_number_type: string, record_type: string, requirements_types: list, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: listRequirements
export def "list-requirements" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-country-code: string # Filters results to those applying to a 2-character (ISO 3166-1 alpha-2) country code (e.g. US)
  --filter-phone-number-type: string@filter-phone-number-type-completer-1 # Filters results to those applying to a specific `phone_number_type` (e.g. local)
  --filter-action: string@filter-action-completer # Filters requirements to those applying to a specific action. (e.g. porting)
  --sort: string@sort-completer-9 # Specifies the sort order for results. If you want to sort by a field in ascending order, include it as a sort parameter. If you want to sort in descending order, prepend a `-` in front of the field name. (e.g. country_code)
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/requirements"
    query: [{name: "filter[country_code]", var: filter_country_code}, {name: "filter[phone_number_type]", var: filter_phone_number_type}, {name: "filter[action]", var: filter_action}, {name: "sort[]", var: sort}, {name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter_country_code: $filter_country_code, filter_phone_number_type: $filter_phone_number_type, filter_action: $filter_action, sort: $sort, page_number: $page_number, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a document requirement
#
# GET /requirements/{id}
# Returns: record<data: record<action: string, country_code: string, created_at: string, id: string, locality: string, phone_number_type: string, record_type: string, requirements_types: list<record>, updated_at: string>>
# operationId: docReqsRetrieveDocumentRequirements
export def "doc-reqs-retrieve-document-requirements" [
  id: string
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
    path: "/requirements/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View a list of room participants.
#
# GET /room_participants
# Returns: record<data: table<context: string, id: string, joined_at: string, left_at: string, record_type: string, session_id: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: ListRoomParticipants
export def "list-room-participants" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-date-joined-at-eq: string # ISO 8601 date for filtering room participants that joined on that date. (format: date, e.g. 2021-04-25)
  --filter-date-joined-at-gte: string # ISO 8601 date for filtering room participants that joined after that date. (format: date, e.g. 2021-04-25)
  --filter-date-joined-at-lte: string # ISO 8601 date for filtering room participants that joined before that date. (format: date, e.g. 2021-04-25)
  --filter-date-updated-at-eq: string # ISO 8601 date for filtering room participants updated on that date. (format: date, e.g. 2021-04-25)
  --filter-date-updated-at-gte: string # ISO 8601 date for filtering room participants updated after that date. (format: date, e.g. 2021-04-25)
  --filter-date-updated-at-lte: string # ISO 8601 date for filtering room participants updated before that date. (format: date, e.g. 2021-04-25)
  --filter-date-left-at-eq: string # ISO 8601 date for filtering room participants that left on that date. (format: date, e.g. 2021-04-25)
  --filter-date-left-at-gte: string # ISO 8601 date for filtering room participants that left after that date. (format: date, e.g. 2021-04-25)
  --filter-date-left-at-lte: string # ISO 8601 date for filtering room participants that left before that date. (format: date, e.g. 2021-04-25)
  --filter-context: string # Filter room participants based on the context. (e.g. Alice)
  --filter-session-id: string # Session_id for filtering room participants. (e.g. 0ccc7b54-4df3-4bca-a65a-3da1ecc777f0)
  --page-size: int # The size of the page. (default: 20)
  --page-number: int # The page number to load. (default: 1)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/room_participants"
    query: [{name: "filter[date_joined_at][eq]", var: filter_date_joined_at_eq}, {name: "filter[date_joined_at][gte]", var: filter_date_joined_at_gte}, {name: "filter[date_joined_at][lte]", var: filter_date_joined_at_lte}, {name: "filter[date_updated_at][eq]", var: filter_date_updated_at_eq}, {name: "filter[date_updated_at][gte]", var: filter_date_updated_at_gte}, {name: "filter[date_updated_at][lte]", var: filter_date_updated_at_lte}, {name: "filter[date_left_at][eq]", var: filter_date_left_at_eq}, {name: "filter[date_left_at][gte]", var: filter_date_left_at_gte}, {name: "filter[date_left_at][lte]", var: filter_date_left_at_lte}, {name: "filter[context]", var: filter_context}, {name: "filter[session_id]", var: filter_session_id}, {name: "page[size]", var: page_size}, {name: "page[number]", var: page_number}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter_date_joined_at_eq: $filter_date_joined_at_eq, filter_date_joined_at_gte: $filter_date_joined_at_gte, filter_date_joined_at_lte: $filter_date_joined_at_lte, filter_date_updated_at_eq: $filter_date_updated_at_eq, filter_date_updated_at_gte: $filter_date_updated_at_gte, filter_date_updated_at_lte: $filter_date_updated_at_lte, filter_date_left_at_eq: $filter_date_left_at_eq, filter_date_left_at_gte: $filter_date_left_at_gte, filter_date_left_at_lte: $filter_date_left_at_lte, filter_context: $filter_context, filter_session_id: $filter_session_id, page_size: $page_size, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View a room participant.
#
# GET /room_participants/{room_participant_id}
# Returns: record<data: record<context: string, id: string, joined_at: string, left_at: string, record_type: string, session_id: string, updated_at: string>>
# operationId: ViewRoomParticipant
export def "view-room-participant" [
  room_participant_id: string
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
    path: "/room_participants/{room_participant_id}"
    path_params: [{name: room_participant_id, var: room_participant_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    room_participant_id: $room_participant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View a list of room sessions.
#
# GET /room_sessions
# Returns: record<data: table<active: bool, created_at: string, ended_at: string, id: string, participants: list, record_type: string, room_id: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: ListRoomSessions
export def "list-room-sessions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-date-created-at-eq: string # ISO 8601 date for filtering room sessions created on that date. (format: date, e.g. 2021-04-25)
  --filter-date-created-at-gte: string # ISO 8601 date for filtering room sessions created after that date. (format: date, e.g. 2021-04-25)
  --filter-date-created-at-lte: string # ISO 8601 date for filtering room sessions created before that date. (format: date, e.g. 2021-04-25)
  --filter-date-updated-at-eq: string # ISO 8601 date for filtering room sessions updated on that date. (format: date, e.g. 2021-04-25)
  --filter-date-updated-at-gte: string # ISO 8601 date for filtering room sessions updated after that date. (format: date, e.g. 2021-04-25)
  --filter-date-updated-at-lte: string # ISO 8601 date for filtering room sessions updated before that date. (format: date, e.g. 2021-04-25)
  --filter-date-ended-at-eq: string # ISO 8601 date for filtering room sessions ended on that date. (format: date, e.g. 2021-04-25)
  --filter-date-ended-at-gte: string # ISO 8601 date for filtering room sessions ended after that date. (format: date, e.g. 2021-04-25)
  --filter-date-ended-at-lte: string # ISO 8601 date for filtering room sessions ended before that date. (format: date, e.g. 2021-04-25)
  --filter-room-id: string # Room_id for filtering room sessions. (e.g. 0ccc7b54-4df3-4bca-a65a-3da1ecc777f0)
  --filter-active: oneof<nothing, bool> # Filter active or inactive room sessions. (e.g. true)
  --include-participants: oneof<nothing, bool> # To decide if room participants should be included in the response. (e.g. true)
  --page-size: int # The size of the page. (default: 20)
  --page-number: int # The page number to load. (default: 1)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/room_sessions"
    query: [{name: "filter[date_created_at][eq]", var: filter_date_created_at_eq}, {name: "filter[date_created_at][gte]", var: filter_date_created_at_gte}, {name: "filter[date_created_at][lte]", var: filter_date_created_at_lte}, {name: "filter[date_updated_at][eq]", var: filter_date_updated_at_eq}, {name: "filter[date_updated_at][gte]", var: filter_date_updated_at_gte}, {name: "filter[date_updated_at][lte]", var: filter_date_updated_at_lte}, {name: "filter[date_ended_at][eq]", var: filter_date_ended_at_eq}, {name: "filter[date_ended_at][gte]", var: filter_date_ended_at_gte}, {name: "filter[date_ended_at][lte]", var: filter_date_ended_at_lte}, {name: "filter[room_id]", var: filter_room_id}, {name: "filter[active]", var: filter_active}, {name: include_participants, var: include_participants}, {name: "page[size]", var: page_size}, {name: "page[number]", var: page_number}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter_date_created_at_eq: $filter_date_created_at_eq, filter_date_created_at_gte: $filter_date_created_at_gte, filter_date_created_at_lte: $filter_date_created_at_lte, filter_date_updated_at_eq: $filter_date_updated_at_eq, filter_date_updated_at_gte: $filter_date_updated_at_gte, filter_date_updated_at_lte: $filter_date_updated_at_lte, filter_date_ended_at_eq: $filter_date_ended_at_eq, filter_date_ended_at_gte: $filter_date_ended_at_gte, filter_date_ended_at_lte: $filter_date_ended_at_lte, filter_room_id: $filter_room_id, filter_active: $filter_active, include_participants: $include_participants, page_size: $page_size, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View a room session.
#
# GET /room_sessions/{room_session_id}
# Returns: record<data: record<active: bool, created_at: string, ended_at: string, id: string, participants: list<record>, record_type: string, room_id: string, updated_at: string>>
# operationId: ViewRoomSession
export def "view-room-session" [
  room_session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-participants: oneof<nothing, bool> # To decide if room participants should be included in the response. (e.g. true)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/room_sessions/{room_session_id}"
    path_params: [{name: room_session_id, var: room_session_id}]
    query: [{name: include_participants, var: include_participants}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    room_session_id: $room_session_id, include_participants: $include_participants
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View a list of room participants.
#
# GET /room_sessions/{room_session_id}/participants
# Returns: record<data: table<context: string, id: string, joined_at: string, left_at: string, record_type: string, session_id: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: NestedListRoomParticipants
export def "nested-list-room-participants" [
  room_session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-date-joined-at-eq: string # ISO 8601 date for filtering room participants that joined on that date. (format: date, e.g. 2021-04-25)
  --filter-date-joined-at-gte: string # ISO 8601 date for filtering room participants that joined after that date. (format: date, e.g. 2021-04-25)
  --filter-date-joined-at-lte: string # ISO 8601 date for filtering room participants that joined before that date. (format: date, e.g. 2021-04-25)
  --filter-date-updated-at-eq: string # ISO 8601 date for filtering room participants updated on that date. (format: date, e.g. 2021-04-25)
  --filter-date-updated-at-gte: string # ISO 8601 date for filtering room participants updated after that date. (format: date, e.g. 2021-04-25)
  --filter-date-updated-at-lte: string # ISO 8601 date for filtering room participants updated before that date. (format: date, e.g. 2021-04-25)
  --filter-date-left-at-eq: string # ISO 8601 date for filtering room participants that left on that date. (format: date, e.g. 2021-04-25)
  --filter-date-left-at-gte: string # ISO 8601 date for filtering room participants that left after that date. (format: date, e.g. 2021-04-25)
  --filter-date-left-at-lte: string # ISO 8601 date for filtering room participants that left before that date. (format: date, e.g. 2021-04-25)
  --filter-context: string # Filter room participants based on the context. (e.g. Alice)
  --page-size: int # The size of the page. (default: 20)
  --page-number: int # The page number to load. (default: 1)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/room_sessions/{room_session_id}/participants"
    path_params: [{name: room_session_id, var: room_session_id}]
    query: [{name: "filter[date_joined_at][eq]", var: filter_date_joined_at_eq}, {name: "filter[date_joined_at][gte]", var: filter_date_joined_at_gte}, {name: "filter[date_joined_at][lte]", var: filter_date_joined_at_lte}, {name: "filter[date_updated_at][eq]", var: filter_date_updated_at_eq}, {name: "filter[date_updated_at][gte]", var: filter_date_updated_at_gte}, {name: "filter[date_updated_at][lte]", var: filter_date_updated_at_lte}, {name: "filter[date_left_at][eq]", var: filter_date_left_at_eq}, {name: "filter[date_left_at][gte]", var: filter_date_left_at_gte}, {name: "filter[date_left_at][lte]", var: filter_date_left_at_lte}, {name: "filter[context]", var: filter_context}, {name: "page[size]", var: page_size}, {name: "page[number]", var: page_number}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    room_session_id: $room_session_id, filter_date_joined_at_eq: $filter_date_joined_at_eq, filter_date_joined_at_gte: $filter_date_joined_at_gte, filter_date_joined_at_lte: $filter_date_joined_at_lte, filter_date_updated_at_eq: $filter_date_updated_at_eq, filter_date_updated_at_gte: $filter_date_updated_at_gte, filter_date_updated_at_lte: $filter_date_updated_at_lte, filter_date_left_at_eq: $filter_date_left_at_eq, filter_date_left_at_gte: $filter_date_left_at_gte, filter_date_left_at_lte: $filter_date_left_at_lte, filter_context: $filter_context, page_size: $page_size, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View a list of rooms.
#
# GET /rooms
# Returns: record<data: table<active_session_id: string, created_at: string, id: string, max_participants: int, record_type: string, sessions: list, unique_name: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: ListRooms
export def "list-rooms" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-date-created-at-eq: string # ISO 8601 date for filtering rooms created on that date. (format: date, e.g. 2021-04-25)
  --filter-date-created-at-gte: string # ISO 8601 date for filtering rooms created after that date. (format: date, e.g. 2021-04-25)
  --filter-date-created-at-lte: string # ISO 8601 date for filtering rooms created before that date. (format: date, e.g. 2021-04-25)
  --filter-date-updated-at-eq: string # ISO 8601 date for filtering rooms updated on that date. (format: date, e.g. 2021-04-25)
  --filter-date-updated-at-gte: string # ISO 8601 date for filtering rooms updated after that date. (format: date, e.g. 2021-04-25)
  --filter-date-updated-at-lte: string # ISO 8601 date for filtering rooms updated before that date. (format: date, e.g. 2021-04-25)
  --filter-unique-name: string # Unique_name for filtering rooms. (e.g. my_video_room)
  --include-sessions: oneof<nothing, bool> # To decide if room sessions should be included in the response. (e.g. true)
  --page-size: int # The size of the page. (default: 20)
  --page-number: int # The page number to load. (default: 1)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rooms"
    query: [{name: "filter[date_created_at][eq]", var: filter_date_created_at_eq}, {name: "filter[date_created_at][gte]", var: filter_date_created_at_gte}, {name: "filter[date_created_at][lte]", var: filter_date_created_at_lte}, {name: "filter[date_updated_at][eq]", var: filter_date_updated_at_eq}, {name: "filter[date_updated_at][gte]", var: filter_date_updated_at_gte}, {name: "filter[date_updated_at][lte]", var: filter_date_updated_at_lte}, {name: "filter[unique_name]", var: filter_unique_name}, {name: include_sessions, var: include_sessions}, {name: "page[size]", var: page_size}, {name: "page[number]", var: page_number}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter_date_created_at_eq: $filter_date_created_at_eq, filter_date_created_at_gte: $filter_date_created_at_gte, filter_date_created_at_lte: $filter_date_created_at_lte, filter_date_updated_at_eq: $filter_date_updated_at_eq, filter_date_updated_at_gte: $filter_date_updated_at_gte, filter_date_updated_at_lte: $filter_date_updated_at_lte, filter_unique_name: $filter_unique_name, include_sessions: $include_sessions, page_size: $page_size, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a room.
#
# POST /rooms
# Returns: record<data: record<active_session_id: string, created_at: string, id: string, max_participants: int, record_type: string, sessions: list<record>, unique_name: string, updated_at: string>>
# operationId: CreateRoom
export def "create-room" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-participants: int # The maximum amount of participants allowed in a room. If new participants try to join after that limit is reached, their request will be rejected. (default: 10, e.g. 10)
  --unique-name: string # The unique (within the Telnyx account scope) name of the room. (e.g. My room)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/rooms"
    body: {content_type: "application/json", kind: json, fields: [{name: max_participants, var: max_participants}, {name: unique_name, var: unique_name}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    max_participants: $max_participants, unique_name: $unique_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a room.
#
# DELETE /rooms/{room_id}
# operationId: DeleteRoom
export def "delete-room" [
  room_id: string
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
    path: "/rooms/{room_id}"
    path_params: [{name: room_id, var: room_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    room_id: $room_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View a room.
#
# GET /rooms/{room_id}
# Returns: record<data: record<active_session_id: string, created_at: string, id: string, max_participants: int, record_type: string, sessions: list<record>, unique_name: string, updated_at: string>>
# operationId: ViewRoom
export def "view-room" [
  room_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-sessions: oneof<nothing, bool> # To decide if room sessions should be included in the response. (e.g. true)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rooms/{room_id}"
    path_params: [{name: room_id, var: room_id}]
    query: [{name: include_sessions, var: include_sessions}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    room_id: $room_id, include_sessions: $include_sessions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Client Token to join a room.
#
# POST /rooms/{room_id}/actions/generate_join_client_token
# Returns: record<data: record<refresh_token: string, refresh_token_expires_at: string, token: string, token_expires_at: string>>
# operationId: CreateRoomClientToken
export def "create-room-client-token" [
  room_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --refresh-token-ttl-secs: int # The time to live in seconds of the Refresh Token, after that time the Refresh Token is invalid and can't be used to refresh Client Token. (default: 3600, e.g. 3600)
  --token-ttl-secs: int # The time to live in seconds of the Client Token, after that time the Client Token is invalid and can't be used to join a Room. (default: 600, e.g. 600)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/rooms/{room_id}/actions/generate_join_client_token"
    path_params: [{name: room_id, var: room_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: refresh_token_ttl_secs, var: refresh_token_ttl_secs}, {name: token_ttl_secs, var: token_ttl_secs}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    room_id: $room_id, refresh_token_ttl_secs: $refresh_token_ttl_secs, token_ttl_secs: $token_ttl_secs
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Refresh Client Token to join a room.
#
# POST /rooms/{room_id}/actions/refresh_client_token
# Returns: record<data: record<token: string, token_expires_at: string>>
# operationId: RefreshRoomClientToken
export def "refresh-room-client-token" [
  room_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  refresh_token: string # format: jwt, e.g. eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJ0ZWxueXhfdGVsZXBob255IiwiZXhwIjoxNTkwMDEwMTQzLCJpYXQiOjE1ODc1OTA5NDMsImlzcyI6InRlbG55eF90ZWxlcGhvbnkiLCJqdGkiOiJiOGM3NDgzNy1kODllLTRhNjUtOWNmMi0zNGM3YTZmYTYwYzgiLCJuYmYiOjE1ODc1OTA5NDIsInN1YiI6IjVjN2FjN2QwLWRiNjUtNGYxMS05OGUxLWVlYzBkMWQ1YzZhZSIsInRlbF90b2tlbiI6InJqX1pra1pVT1pNeFpPZk9tTHBFVUIzc2lVN3U2UmpaRmVNOXMtZ2JfeENSNTZXRktGQUppTXlGMlQ2Q0JSbWxoX1N5MGlfbGZ5VDlBSThzRWlmOE1USUlzenl6U2xfYURuRzQ4YU81MHlhSEd1UlNZYlViU1ltOVdJaVEwZz09IiwidHlwIjoiYWNjZXNzIn0.gNEwzTow5MLLPLQENytca7pUN79PmPj6FyqZWW06ZeEmesxYpwKh0xRtA0TzLh6CDYIRHrI8seofOO0YFGDhpQ
  --token-ttl-secs: int # The time to live in seconds of the Client Token, after that time the Client Token is invalid and can't be used to join a Room. (default: 600, e.g. 600)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/rooms/{room_id}/actions/refresh_client_token"
    path_params: [{name: room_id, var: room_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: refresh_token, var: refresh_token}, {name: token_ttl_secs, var: token_ttl_secs}]}
    accept: ["application/json"]
    ok: [201]
    auth: none
  } {
    room_id: $room_id, refresh_token: $refresh_token, token_ttl_secs: $token_ttl_secs
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View a list of room sessions.
#
# GET /rooms/{room_id}/sessions
# Returns: record<data: table<active: bool, created_at: string, ended_at: string, id: string, participants: list, record_type: string, room_id: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: NestedListRoomSessions
export def "nested-list-room-sessions" [
  room_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-date-created-at-eq: string # ISO 8601 date for filtering room sessions created on that date. (format: date, e.g. 2021-04-25)
  --filter-date-created-at-gte: string # ISO 8601 date for filtering room sessions created after that date. (format: date, e.g. 2021-04-25)
  --filter-date-created-at-lte: string # ISO 8601 date for filtering room sessions created before that date. (format: date, e.g. 2021-04-25)
  --filter-date-updated-at-eq: string # ISO 8601 date for filtering room sessions updated on that date. (format: date, e.g. 2021-04-25)
  --filter-date-updated-at-gte: string # ISO 8601 date for filtering room sessions updated after that date. (format: date, e.g. 2021-04-25)
  --filter-date-updated-at-lte: string # ISO 8601 date for filtering room sessions updated before that date. (format: date, e.g. 2021-04-25)
  --filter-date-ended-at-eq: string # ISO 8601 date for filtering room sessions ended on that date. (format: date, e.g. 2021-04-25)
  --filter-date-ended-at-gte: string # ISO 8601 date for filtering room sessions ended after that date. (format: date, e.g. 2021-04-25)
  --filter-date-ended-at-lte: string # ISO 8601 date for filtering room sessions ended before that date. (format: date, e.g. 2021-04-25)
  --filter-active: oneof<nothing, bool> # Filter active or inactive room sessions. (e.g. true)
  --include-participants: oneof<nothing, bool> # To decide if room participants should be included in the response. (e.g. true)
  --page-size: int # The size of the page. (default: 20)
  --page-number: int # The page number to load. (default: 1)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rooms/{room_id}/sessions"
    path_params: [{name: room_id, var: room_id}]
    query: [{name: "filter[date_created_at][eq]", var: filter_date_created_at_eq}, {name: "filter[date_created_at][gte]", var: filter_date_created_at_gte}, {name: "filter[date_created_at][lte]", var: filter_date_created_at_lte}, {name: "filter[date_updated_at][eq]", var: filter_date_updated_at_eq}, {name: "filter[date_updated_at][gte]", var: filter_date_updated_at_gte}, {name: "filter[date_updated_at][lte]", var: filter_date_updated_at_lte}, {name: "filter[date_ended_at][eq]", var: filter_date_ended_at_eq}, {name: "filter[date_ended_at][gte]", var: filter_date_ended_at_gte}, {name: "filter[date_ended_at][lte]", var: filter_date_ended_at_lte}, {name: "filter[active]", var: filter_active}, {name: include_participants, var: include_participants}, {name: "page[size]", var: page_size}, {name: "page[number]", var: page_number}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    room_id: $room_id, filter_date_created_at_eq: $filter_date_created_at_eq, filter_date_created_at_gte: $filter_date_created_at_gte, filter_date_created_at_lte: $filter_date_created_at_lte, filter_date_updated_at_eq: $filter_date_updated_at_eq, filter_date_updated_at_gte: $filter_date_updated_at_gte, filter_date_updated_at_lte: $filter_date_updated_at_lte, filter_date_ended_at_eq: $filter_date_ended_at_eq, filter_date_ended_at_gte: $filter_date_ended_at_gte, filter_date_ended_at_lte: $filter_date_ended_at_lte, filter_active: $filter_active, include_participants: $include_participants, page_size: $page_size, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List short codes
#
# GET /short_codes
# Returns: record<data: table<country_code: string, created_at: string, id: string, messaging_profile_id: string, record_type: string, short_code: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: listShortCodes
export def "list-short-codes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
  --filter-messaging-profile-id: string # Filter by Messaging Profile ID. Use the string `null` for phone numbers without assigned profiles. A synonym for the `/messaging_profiles/{id}/short_codes` endpoint when querying about an extant profile.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/short_codes"
    query: [{name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}, {name: "filter[messaging_profile_id]", var: filter_messaging_profile_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_number: $page_number, page_size: $page_size, filter_messaging_profile_id: $filter_messaging_profile_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a short code
#
# GET /short_codes/{id}
# Returns: record<data: record<country_code: string, created_at: string, id: string, messaging_profile_id: string, record_type: string, short_code: string, updated_at: string>>
# operationId: retrieveShortCode
export def "retrieve-short-code" [
  id: string
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
    path: "/short_codes/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update short code
#
# PATCH /short_codes/{id}
# Returns: record<data: record<country_code: string, created_at: string, id: string, messaging_profile_id: string, record_type: string, short_code: string, updated_at: string>>
# operationId: updateShortCode
export def "update-short-code" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  messaging_profile_id: string # Unique identifier for a messaging profile.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/short_codes/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: messaging_profile_id, var: messaging_profile_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, messaging_profile_id: $messaging_profile_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List SIM card group actions
#
# GET /sim_card_group_actions
# Returns: record<data: table<created_at: string, id: string, record_type: string, settings: record, sim_card_group_id: string, status: string, type: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: SimCardGroupActionsGet
export def "sim-card-group-actions-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
  --filter-sim-card-group-id: string # A valid SIM card group ID. (format: uuid, e.g. 47a1c2b0-cc7b-4ab1-bb98-b33fb0fc61b9)
  --filter-status: string@filter-status-completer-1 # Filter by a specific status of the resource's lifecycle. (e.g. in-progress)
  --filter-type: string@filter-type-completer-4 # Filter by action type. (e.g. set_private_wireless_gateway)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/sim_card_group_actions"
    query: [{name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}, {name: "filter[sim_card_group_id]", var: filter_sim_card_group_id}, {name: "filter[status]", var: filter_status}, {name: "filter[type]", var: filter_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_number: $page_number, page_size: $page_size, filter_sim_card_group_id: $filter_sim_card_group_id, filter_status: $filter_status, filter_type: $filter_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get SIM card group action details
#
# GET /sim_card_group_actions/{id}
# Returns: record<data: record<created_at: string, id: string, record_type: string, settings: record<private_wireless_gateway_id: string>, sim_card_group_id: string, status: string, type: string, updated_at: string>>
# operationId: SimCardGroupActionGet
export def "sim-card-group-action-get" [
  id: string
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
    path: "/sim_card_group_actions/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all SIM card groups
#
# GET /sim_card_groups
# Returns: record<data: table<consumed_data: record, created_at: string, data_limit: int, default: bool, id: string, name: string, private_wireless_gateway_id: string, record_type: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: SimCardGroupsGetAll
export def "sim-card-groups-get-all" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
  --filter-name: string # A valid SIM card group name. (format: uuid, e.g. My Test Group)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/sim_card_groups"
    query: [{name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}, {name: "filter[name]", var: filter_name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_number: $page_number, page_size: $page_size, filter_name: $filter_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a SIM card group
#
# POST /sim_card_groups
# Returns: record<data: record<consumed_data: record<amount: int, unit: string>, created_at: string, data_limit: int, default: bool, id: string, name: string, private_wireless_gateway_id: string, record_type: string, updated_at: string>>
# operationId: SimCardGroupsPost
export def "sim-card-groups-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --data-limit: int # Upper limit on the amount of data the SIM cards, within the group, can use. (e.g. 2048)
  name: string # A user friendly name for the SIM card group. (e.g. My Test Group)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sim_card_groups"
    body: {content_type: "application/json", kind: json, fields: [{name: data_limit, var: data_limit}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    data_limit: $data_limit, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a SIM card group
#
# DELETE /sim_card_groups/{id}
# Returns: record<data: record<consumed_data: record<amount: int, unit: string>, created_at: string, data_limit: int, default: bool, id: string, name: string, private_wireless_gateway_id: string, record_type: string, updated_at: string>>
# operationId: SimCardGroupDelete
export def "sim-card-group-delete" [
  id: string
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
    method: delete
    path: "/sim_card_groups/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get SIM card group
#
# GET /sim_card_groups/{id}
# Returns: record<data: record<consumed_data: record<amount: int, unit: string>, created_at: string, data_limit: int, default: bool, id: string, name: string, private_wireless_gateway_id: string, record_type: string, updated_at: string>>
# operationId: SimCardGroupsGet
export def "sim-card-groups-get" [
  id: string
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
    path: "/sim_card_groups/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a SIM card group
#
# PATCH /sim_card_groups/{id}
# Returns: record<data: record<consumed_data: record<amount: int, unit: string>, created_at: string, data_limit: int, default: bool, id: string, name: string, private_wireless_gateway_id: string, record_type: string, updated_at: string>>
# operationId: SimCardGroupUpdate
export def "sim-card-group-update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --data-limit: int # Upper limit on the amount of data the SIM cards, within the group, can use. (e.g. 2048)
  --name: string # A user friendly name for the SIM card group. (e.g. My Test Group)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/sim_card_groups/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: data_limit, var: data_limit}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, data_limit: $data_limit, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request Private Wireless Gateway removal from SIM card group
#
# POST /sim_card_groups/{id}/actions/remove_private_wireless_gateway
# Returns: record<data: record<created_at: string, id: string, record_type: string, settings: record<private_wireless_gateway_id: string>, sim_card_group_id: string, status: string, type: string, updated_at: string>>
# operationId: RemoveSIMCardGroupPrivateWirelessGateway
export def "remove-sim-card-group-private-wireless-gateway" [
  id: string
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
    method: post
    path: "/sim_card_groups/{id}/actions/remove_private_wireless_gateway"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request Private Wireless Gateway assignment for SIM card group
#
# POST /sim_card_groups/{id}/actions/set_private_wireless_gateway
# Returns: record<data: record<created_at: string, id: string, record_type: string, settings: record<private_wireless_gateway_id: string>, sim_card_group_id: string, status: string, type: string, updated_at: string>>
# operationId: SetSIMCardGroupPrivateWirelessGateway
export def "set-sim-card-group-private-wireless-gateway" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  private_wireless_gateway_id: string # The identification of the related Private Wireless Gateway resource. (format: uuid, e.g. 6a09cdc3-8948-47f0-aa62-74ac943d6c58)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sim_card_groups/{id}/actions/set_private_wireless_gateway"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: private_wireless_gateway_id, var: private_wireless_gateway_id}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    id: $id, private_wireless_gateway_id: $private_wireless_gateway_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Preview SIM card orders
#
# POST /sim_card_order_preview
# Returns: record<data: record<quantity: int, record_type: string, shipping_cost: record<amount: string, currency: string>, sim_cards_cost: record<amount: string, currency: string>, total_cost: record<amount: string, currency: string>>>
# operationId: SimCardOrdersPreview
export def "sim-card-orders-preview" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  address_id: string # Uniquely identifies the address for the order. (format: int64, e.g. 1293384261075731499)
  quantity: int # The amount of SIM cards that the user would like to purchase in the SIM card order. (e.g. 21)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sim_card_order_preview"
    body: {content_type: "application/json", kind: json, fields: [{name: address_id, var: address_id}, {name: quantity, var: quantity}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    address_id: $address_id, quantity: $quantity
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all SIM card orders
#
# GET /sim_card_orders
# Returns: record<data: table<cost: record, created_at: string, id: string, order_address: record, quantity: int, record_type: string, status: string, tracking_url: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: SimCardOrdersGet
export def "sim-card-orders-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-created-at: string # Filter by ISO 8601 formatted date-time string matching resource creation date-time. (format: datetime, e.g. 2018-02-02T22:25:27.521Z)
  --filter-updated-at: string # Filter by ISO 8601 formatted date-time string matching resource last update date-time. (format: datetime, e.g. 2018-02-02T22:25:27.521Z)
  --filter-quantity: int # Filter orders by how many SIM cards were ordered. (e.g. 21)
  --filter-cost-amount: string # The total monetary amount of the order. (e.g. 2.53)
  --filter-cost-currency: string # Filter by ISO 4217 currency string. (e.g. USD)
  --filter-address-id: string # Uniquely identifies the address for the order. (format: int64, e.g. 1293384261075731499)
  --filter-address-street-address: string # Returns entries with matching name of the street where the address is located. (e.g. 311 W Superior St)
  --filter-address-extended-address: string # Returns entries with matching name of the supplemental field for address information. (e.g. Suite 504)
  --filter-address-locality: string # Filter by the name of the city where the address is located. (e.g. Chicago)
  --filter-address-administrative-area: string # Filter by state or province where the address is located. (e.g. IL)
  --filter-address-country-code: string # Filter by the mobile operator two-character (ISO 3166-1 alpha-2) origin country code. (e.g. US)
  --filter-address-postal-code: string # Filter by postal code for the address. (e.g. 60654)
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/sim_card_orders"
    query: [{name: "filter[created_at]", var: filter_created_at}, {name: "filter[updated_at]", var: filter_updated_at}, {name: "filter[quantity]", var: filter_quantity}, {name: "filter[cost.amount]", var: filter_cost_amount}, {name: "filter[cost.currency]", var: filter_cost_currency}, {name: "filter[address.id]", var: filter_address_id}, {name: "filter[address.street_address]", var: filter_address_street_address}, {name: "filter[address.extended_address]", var: filter_address_extended_address}, {name: "filter[address.locality]", var: filter_address_locality}, {name: "filter[address.administrative_area]", var: filter_address_administrative_area}, {name: "filter[address.country_code]", var: filter_address_country_code}, {name: "filter[address.postal_code]", var: filter_address_postal_code}, {name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter_created_at: $filter_created_at, filter_updated_at: $filter_updated_at, filter_quantity: $filter_quantity, filter_cost_amount: $filter_cost_amount, filter_cost_currency: $filter_cost_currency, filter_address_id: $filter_address_id, filter_address_street_address: $filter_address_street_address, filter_address_extended_address: $filter_address_extended_address, filter_address_locality: $filter_address_locality, filter_address_administrative_area: $filter_address_administrative_area, filter_address_country_code: $filter_address_country_code, filter_address_postal_code: $filter_address_postal_code, page_number: $page_number, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a SIM card order
#
# POST /sim_card_orders
# Returns: record<data: record<cost: record<amount: string, currency: string>, created_at: string, id: string, order_address: record<administrative_area: string, country_code: string, extended_address: string, id: string, locality: string, postal_code: string, street_address: string>, quantity: int, record_type: string, status: string, tracking_url: string, updated_at: string>>
# operationId: SimCardOrdersPost
export def "sim-card-orders-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  address_id: string # Uniquely identifies the address for the order. (format: int64, e.g. 1293384261075731499)
  quantity: int # The amount of SIM cards to order. (e.g. 23)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sim_card_orders"
    body: {content_type: "application/json", kind: json, fields: [{name: address_id, var: address_id}, {name: quantity, var: quantity}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    address_id: $address_id, quantity: $quantity
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a single SIM card order
#
# GET /sim_card_orders/{id}
# Returns: record<data: record<cost: record<amount: string, currency: string>, created_at: string, id: string, order_address: record<administrative_area: string, country_code: string, extended_address: string, id: string, locality: string, postal_code: string, street_address: string>, quantity: int, record_type: string, status: string, tracking_url: string, updated_at: string>>
# operationId: SimCardOrderGet
export def "sim-card-order-get" [
  id: string
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
    path: "/sim_card_orders/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all SIM cards
#
# GET /sim_cards
# Returns: record<data: table<created_at: string, iccid: string, id: string, imsi: string, msisdn: string, record_type: string, sim_card_group_id: string, status: string, tags: list, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: SimCardsGet
export def "sim-cards-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
  --include-sim-card-group: oneof<nothing, bool> # It includes the associated SIM card group object in the response when present. (default: false, e.g. true)
  --filter-sim-card-group-id: string # A valid SIM card group ID. (format: uuid, e.g. 47a1c2b0-cc7b-4ab1-bb98-b33fb0fc61b9)
  --filter-tags: list<string> # A list of SIM card tags to filter on. If the SIM card contains all of the given tags they will be found. For example, if the SIM cards have the following tags: ['customers', 'staff', 'test'] ['test'] ['customers'] Searching for ['customers', 'test'] returns only the first because it's the only one with both tags. Searching for test returns the first two SIMs, because both of them have such tag. Searching for customers returns the first and last SIMs. (e.g. [personal, customers, active-customers])
  --filter-iccid: string # A search string to partially match for the SIM card's ICCID. (e.g. 89310410106543789301)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/sim_cards"
    query: [{name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}, {name: include_sim_card_group, var: include_sim_card_group}, {name: "filter[sim_card_group_id]", var: filter_sim_card_group_id}, {name: "filter[tags]", var: filter_tags, style: multi}, {name: "filter[iccid]", var: filter_iccid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_number: $page_number, page_size: $page_size, include_sim_card_group: $include_sim_card_group, filter_sim_card_group_id: $filter_sim_card_group_id, filter_tags: $filter_tags, filter_iccid: $filter_iccid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Validate SIM cards registration codes
#
# POST /sim_cards/actions/validate_registration_codes
# Returns: record<data: table<invalid_detail: string, record_type: string, registration_code: string, valid: bool>>
# operationId: postValidateRegistrationCodes
export def "post-validate-registration-codes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --registration-codes: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sim_cards/actions/validate_registration_codes"
    body: {content_type: "application/json", kind: json, fields: [{name: registration_codes, var: registration_codes}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    registration_codes: $registration_codes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a SIM card
#
# DELETE /sim_cards/{id}
# Returns: record<data: record<created_at: string, iccid: string, id: string, imsi: string, ipv4: string, ipv6: string, msisdn: string, record_type: string, sim_card_group_id: string, status: string, tags: list<string>, updated_at: string>>
# operationId: SimCardDelete
export def "sim-card-delete" [
  id: string
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
    method: delete
    path: "/sim_cards/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get SIM card
#
# GET /sim_cards/{id}
# Returns: record<data: record<created_at: string, iccid: string, id: string, imsi: string, ipv4: string, ipv6: string, msisdn: string, record_type: string, sim_card_group_id: string, status: string, tags: list<string>, updated_at: string>>
# operationId: SimCardGet
export def "sim-card-get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-sim-card-group: oneof<nothing, bool> # It includes the associated SIM card group object in the response when present. (default: false, e.g. true)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/sim_cards/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: include_sim_card_group, var: include_sim_card_group}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, include_sim_card_group: $include_sim_card_group
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a SIM card
#
# PATCH /sim_cards/{id}
# Returns: record<data: record<created_at: string, iccid: string, id: string, imsi: string, ipv4: string, ipv6: string, msisdn: string, record_type: string, sim_card_group_id: string, status: string, tags: list<string>, updated_at: string>>
# operationId: SimCardUpdate
export def "sim-card-update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sim-card-group-id: string # The group SIMCardGroup identification. This attribute can be null when it's present in an associated resource. (format: uuid, e.g. 6a09cdc3-8948-47f0-aa62-74ac943d6c58)
  --tags: list<string> # Searchable tags associated with the SIM card (e.g. [personal, customers, active-customers])
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/sim_cards/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: sim_card_group_id, var: sim_card_group_id}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, sim_card_group_id: $sim_card_group_id, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request a SIM card disable
#
# POST /sim_cards/{id}/actions/disable
# Returns: record<data: record<created_at: string, iccid: string, id: string, imsi: string, msisdn: string, record_type: string, sim_card_group_id: string, status: string, tags: list<string>, updated_at: string>>
# operationId: SimCardDisable
export def "sim-card-disable" [
  id: string
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
    method: post
    path: "/sim_cards/{id}/actions/disable"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request a SIM card enable
#
# POST /sim_cards/{id}/actions/enable
# Returns: record<data: record<created_at: string, iccid: string, id: string, imsi: string, msisdn: string, record_type: string, sim_card_group_id: string, status: string, tags: list<string>, updated_at: string>>
# operationId: SimCardEnable
export def "sim-card-enable" [
  id: string
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
    method: post
    path: "/sim_cards/{id}/actions/enable"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request setting a SIM card to standby
#
# POST /sim_cards/{id}/actions/set_standby
# Returns: record<data: record<created_at: string, iccid: string, id: string, imsi: string, msisdn: string, record_type: string, sim_card_group_id: string, status: string, tags: list<string>, updated_at: string>>
# operationId: SimCardSetStandby
export def "sim-card-set-standby" [
  id: string
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
    method: post
    path: "/sim_cards/{id}/actions/set_standby"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE network preferences
#
# DELETE /sim_cards/{sim_card_id}/network_preferences
# Returns: record<data: record<created_at: string, mobile_operator_networks_preferences: list<record>, ota_updates: list<record>, record_type: string, sim_card_id: string, updated_at: string>>
# operationId: SIMCardNetworkPreferencesDelete
export def "sim-card-network-preferences-delete" [
  sim_card_id: string
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
    method: delete
    path: "/sim_cards/{sim_card_id}/network_preferences"
    path_params: [{name: sim_card_id, var: sim_card_id}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    sim_card_id: $sim_card_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get network preferences
#
# GET /sim_cards/{sim_card_id}/network_preferences
# Returns: record<data: record<created_at: string, mobile_operator_networks_preferences: list<record>, ota_updates: list<record>, record_type: string, sim_card_id: string, updated_at: string>>
# operationId: SIMCardNetworkPreferencesGet
export def "sim-card-network-preferences-get" [
  sim_card_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-ota-updates: oneof<nothing, bool> # It includes the associated OTA update objects in the response when present. (default: false, e.g. true)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/sim_cards/{sim_card_id}/network_preferences"
    path_params: [{name: sim_card_id, var: sim_card_id}]
    query: [{name: include_ota_updates, var: include_ota_updates}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    sim_card_id: $sim_card_id, include_ota_updates: $include_ota_updates
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set network preferences
#
# PUT /sim_cards/{sim_card_id}/network_preferences
# Returns: record<data: record<created_at: string, mobile_operator_networks_preferences: list<record>, ota_updates: list<record>, record_type: string, sim_card_id: string, updated_at: string>>
# operationId: SIMCardNetworkPreferencesPut
export def "sim-card-network-preferences-put" [
  sim_card_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mobile-operator-networks-preferences: list # A list of mobile operator networks and the priority that should be applied when the SIM is connecting to the network. — item shape: {mobile_operator_network_id?: string, priority?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/sim_cards/{sim_card_id}/network_preferences"
    path_params: [{name: sim_card_id, var: sim_card_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: mobile_operator_networks_preferences, var: mobile_operator_networks_preferences}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    sim_card_id: $sim_card_id, mobile_operator_networks_preferences: $mobile_operator_networks_preferences
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete SIM card public IP
#
# DELETE /sim_cards/{sim_card_id}/public_ip
# Returns: record<data: record<created_at: string, ip: string, record_type: string, sim_card_id: string, status: record<error_code: string, error_description: string, value: string>, type: string, updated_at: string>>
# operationId: SIMCardPublicIPDelete
export def "sim-card-public-ip-delete" [
  sim_card_id: string
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
    method: delete
    path: "/sim_cards/{sim_card_id}/public_ip"
    path_params: [{name: sim_card_id, var: sim_card_id}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    sim_card_id: $sim_card_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get SIM card public IP definition
#
# GET /sim_cards/{sim_card_id}/public_ip
# Returns: record<data: record<created_at: string, ip: string, record_type: string, sim_card_id: string, status: record<error_code: string, error_description: string, value: string>, type: string, updated_at: string>>
# operationId: SIMCardPublicIPGet
export def "sim-card-public-ip-get" [
  sim_card_id: string
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
    path: "/sim_cards/{sim_card_id}/public_ip"
    path_params: [{name: sim_card_id, var: sim_card_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    sim_card_id: $sim_card_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set SIM card public IP
#
# POST /sim_cards/{sim_card_id}/public_ip
# Returns: record<data: record<created_at: string, ip: string, record_type: string, sim_card_id: string, status: record<error_code: string, error_description: string, value: string>, type: string, updated_at: string>>
# operationId: SIMCardPublicIPPost
export def "sim-card-public-ip-post" [
  sim_card_id: string
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
    method: post
    path: "/sim_cards/{sim_card_id}/public_ip"
    path_params: [{name: sim_card_id, var: sim_card_id}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    sim_card_id: $sim_card_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List wireless connectivity logs
#
# GET /sim_cards/{sim_card_id}/wireless_connectivity_logs
# Returns: record<data: table<apn: string, id: int, imei: string, imsi: string, ipv4: string, ipv6: string, log_type: string, mobile_country_code: string, mobile_network_code: string, radio_access_technology: string, record_type: string, sim_card_id: string, start_time: string, state: string, stop_time: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: WirelessConnectivityLogsGet
export def "wireless-connectivity-logs-get" [
  sim_card_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/sim_cards/{sim_card_id}/wireless_connectivity_logs"
    path_params: [{name: sim_card_id, var: sim_card_id}]
    query: [{name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    sim_card_id: $sim_card_id, page_number: $page_number, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List sub number orders
#
# GET /sub_number_orders
# Returns: record<data: table<country_code: string, created_at: string, id: string, order_request_id: string, phone_number_type: string, phone_numbers_count: int, record_type: string, regulatory_requirements: list, requirements_met: bool, updated_at: string, user_id: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: listSubNumberOrders
export def "list-sub-number-orders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-user-id: string # User ID of the user who owns the sub number order (format: uuid, e.g. d70873cd-7c98-401a-81b6-b1ae08246995)
  --filter-order-request-id: string # ID of the number order the sub number order belongs to (format: uuid, e.g. 12ade33a-21c0-473b-b055-b3c836e1c293)
  --filter-country-code: string # ISO alpha-2 country code. (e.g. US)
  --filter-phone-number-type: string # Phone Number Type (e.g. local)
  --filter-phone-numbers-count: int # Amount of numbers in the sub number order (e.g. 1)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/sub_number_orders"
    query: [{name: "filter[user_id]", var: filter_user_id}, {name: "filter[order_request_id]", var: filter_order_request_id}, {name: "filter[country_code]", var: filter_country_code}, {name: "filter[phone_number_type]", var: filter_phone_number_type}, {name: "filter[phone_numbers_count]", var: filter_phone_numbers_count}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter_user_id: $filter_user_id, filter_order_request_id: $filter_order_request_id, filter_country_code: $filter_country_code, filter_phone_number_type: $filter_phone_number_type, filter_phone_numbers_count: $filter_phone_numbers_count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a sub number order
#
# GET /sub_number_orders/{sub_number_order_id}
# Returns: record<data: record<country_code: string, created_at: string, id: string, order_request_id: string, phone_number_type: string, phone_numbers_count: int, record_type: string, regulatory_requirements: list<record>, requirements_met: bool, updated_at: string, user_id: string>>
# operationId: retrieveSubNumberOrder
export def "retrieve-sub-number-order" [
  sub_number_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-include-phone-numbers: oneof<nothing, bool> # Include the first 50 phone number objects in the results (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/sub_number_orders/{sub_number_order_id}"
    path_params: [{name: sub_number_order_id, var: sub_number_order_id}]
    query: [{name: "filter[include_phone_numbers]", var: filter_include_phone_numbers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    sub_number_order_id: $sub_number_order_id, filter_include_phone_numbers: $filter_include_phone_numbers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a sub number order
#
# PATCH /sub_number_orders/{sub_number_order_id}
# Returns: record<data: record<country_code: string, created_at: string, id: string, order_request_id: string, phone_number_type: string, phone_numbers_count: int, record_type: string, regulatory_requirements: list<record>, requirements_met: bool, updated_at: string, user_id: string>>
# operationId: updateSubNumberOrder
export def "update-sub-number-order" [
  sub_number_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --regulatory-requirements: list # item shape: {field_value?: string, requirement_id?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/sub_number_orders/{sub_number_order_id}"
    path_params: [{name: sub_number_order_id, var: sub_number_order_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: regulatory_requirements, var: regulatory_requirements}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    sub_number_order_id: $sub_number_order_id, regulatory_requirements: $regulatory_requirements
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all credentials
#
# GET /telephony_credentials
# Returns: record<data: table<created_at: string, expired: bool, expires_at: string, id: string, name: string, record_type: string, resource_id: string, sip_password: string, sip_username: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: findTelephonyCredentials
export def "find-telephony-credentials" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
  --filter-tag: string # Filter by tag
  --filter-name: string # Filter by name
  --filter-status: string # Filter by status
  --filter-resource-id: string # Filter by resource_id
  --filter-sip-username: string # Filter by sip_username
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/telephony_credentials"
    query: [{name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}, {name: "filter[tag]", var: filter_tag}, {name: "filter[name]", var: filter_name}, {name: "filter[status]", var: filter_status}, {name: "filter[resource_id]", var: filter_resource_id}, {name: "filter[sip_username]", var: filter_sip_username}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_number: $page_number, page_size: $page_size, filter_tag: $filter_tag, filter_name: $filter_name, filter_status: $filter_status, filter_resource_id: $filter_resource_id, filter_sip_username: $filter_sip_username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a credential
#
# POST /telephony_credentials
# Returns: record<data: record<created_at: string, expired: bool, expires_at: string, id: string, name: string, record_type: string, resource_id: string, sip_password: string, sip_username: string, updated_at: string>>
# operationId: CreateTelephonyCredential
export def "create-telephony-credential" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  connection_id: string # Identifies the Credential Connection this credential is associated with. (e.g. 1234567890)
  --expires-at: string # ISO-8601 formatted date indicating when the credential will expire. (e.g. 2018-02-02T22:25:27.521Z)
  --name: string
  --tag: string # Tags a credential to filter for bulk operations. A single tag can hold at maximum 1000 credentials. (e.g. some_tag)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/telephony_credentials"
    body: {content_type: "application/json", kind: json, fields: [{name: connection_id, var: connection_id}, {name: expires_at, var: expires_at}, {name: name, var: name}, {name: tag, var: tag}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    connection_id: $connection_id, expires_at: $expires_at, name: $name, tag: $tag
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all tags
#
# GET /telephony_credentials/tags
# Returns: record<data: table<amount: int, tag: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: listTags
export def "list-tags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/telephony_credentials/tags"
    query: [{name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_number: $page_number, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a credential
#
# DELETE /telephony_credentials/{id}
# Returns: record<data: record<created_at: string, expired: bool, expires_at: string, id: string, name: string, record_type: string, resource_id: string, sip_password: string, sip_username: string, updated_at: string>>
# operationId: DeleteTelephonyCredential
export def "delete-telephony-credential" [
  id: string
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
    method: delete
    path: "/telephony_credentials/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a credential
#
# GET /telephony_credentials/{id}
# Returns: record<data: record<created_at: string, expired: bool, expires_at: string, id: string, name: string, record_type: string, resource_id: string, sip_password: string, sip_username: string, updated_at: string>>
# operationId: getTelephonyCredential
export def "get-telephony-credential" [
  id: string
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
    path: "/telephony_credentials/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a credential
#
# PATCH /telephony_credentials/{id}
# Returns: record<data: record<created_at: string, expired: bool, expires_at: string, id: string, name: string, record_type: string, resource_id: string, sip_password: string, sip_username: string, updated_at: string>>
# operationId: UpdateTelephonyCredential
export def "update-telephony-credential" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --connection-id: string # Identifies the Credential Connection this credential is associated with. (e.g. 987654321)
  --expires-at: string # ISO-8601 formatted date indicating when the credential will expire. (e.g. 2018-02-02T22:25:27.521Z)
  --name: string
  --tag: string # Tags a credential to filter for bulk operations. A single tag can hold at maximum 1000 credentials. (e.g. some_tag)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/telephony_credentials/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: connection_id, var: connection_id}, {name: expires_at, var: expires_at}, {name: name, var: name}, {name: tag, var: tag}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, connection_id: $connection_id, expires_at: $expires_at, name: $name, tag: $tag
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Perform activate or deactivate action on provided Credential
#
# POST /telephony_credentials/{id}/actions/{action}
# Returns: record<data: record<created_at: string, expired: bool, expires_at: string, id: string, name: string, record_type: string, resource_id: string, sip_password: string, sip_username: string, updated_at: string>>
# operationId: telephonyCredentialAction
export def "telephony-credential-action" [
  id: string
  action: string@action-completer
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
    method: post
    path: "/telephony_credentials/{id}/actions/{action}"
    path_params: [{name: id, var: id}, {name: action, var: action}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, action: $action
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an Access Token.
#
# POST /telephony_credentials/{id}/token
# Returns: string
# operationId: CreateTelephonyCredentialToken
export def "create-telephony-credential-token" [
  id: string
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
    path: "/telephony_credentials/{id}/token"
    path_params: [{name: id, var: id}]
    accept: ["text/plain"]
    ok: [201]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all TeXML Applications
#
# GET /texml_applications
# Returns: record<data: table<active: bool, anchorsite_override: string, created_at: string, dtmf_type: string, first_command_timeout: bool, first_command_timeout_secs: int, friendly_name: string, id: string, inbound: record, outbound: record, record_type: string, status_callback: string, status_callback_method: string, updated_at: string, voice_fallback_url: string, voice_method: string, voice_url: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: findTexmlApplications
export def "find-texml-applications" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
  --filter-friendly-name-contains: string # If present, applications with friendly_name containing the given value will be returned. Matching is not case-sensitive. Requires at least three characters. (default: null)
  --filter-outbound-voice-profile-id: string # Identifies the associated outbound voice profile. (format: int64, e.g. 1293384261075731499)
  --sort: string@sort-completer-2 # Specifies the sort order for results. By default sorting direction is ascending. To have the results sorted in descending order add the - prefix. That is: connection_name: sorts the result by the connection_name field in ascending order. -connection_name: sorts the result by the connection_name field in descending order. If not given, results are sorted by created_at in descending order. (default: created_at, e.g. connection_name)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/texml_applications"
    query: [{name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}, {name: "filter[friendly_name][contains]", var: filter_friendly_name_contains}, {name: "filter[outbound_voice_profile_id]", var: filter_outbound_voice_profile_id}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_number: $page_number, page_size: $page_size, filter_friendly_name_contains: $filter_friendly_name_contains, filter_outbound_voice_profile_id: $filter_outbound_voice_profile_id, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a TeXML Application
#
# POST /texml_applications
# Returns: record<data: record<active: bool, anchorsite_override: string, created_at: string, dtmf_type: string, first_command_timeout: bool, first_command_timeout_secs: int, friendly_name: string, id: string, inbound: record<channel_limit: int, sip_subdomain: string, sip_subdomain_receive_settings: string>, outbound: record<channel_limit: int, outbound_voice_profile_id: string>, record_type: string, status_callback: string, status_callback_method: string, updated_at: string, voice_fallback_url: string, voice_method: string, voice_url: string>>
# operationId: CreateTexmlApplication
export def "create-texml-application" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # Specifies whether the connection can be used. (default: true, e.g. false)
  --anchorsite-override: string@anchorsite-override-completer-1 # `Latency` directs Telnyx to route media through the site with the lowest round-trip time to the user's connection. Telnyx calculates this time using ICMP ping messages. This can be disabled by specifying a site to handle all media. (default: Latency, e.g. Amsterdam, Netherlands)
  --dtmf-type: string@dtmf-type-completer # Sets the type of DTMF digits sent from Telnyx to this Connection. Note that DTMF digits sent to Telnyx will be accepted in all formats. (default: RFC 2833, e.g. Inband)
  --first-command-timeout: oneof<nothing, bool> # Specifies whether calls to phone numbers associated with this connection should hangup after timing out. (default: false, e.g. true)
  --first-command-timeout-secs: int # Specifies how many seconds to wait before timing out a dial command. (default: 30, e.g. 10)
  friendly_name: string # A user-assigned name to help manage the application. (e.g. call-router)
  --inbound: record # shape: {channel_limit?: int, sip_subdomain?: string, sip_subdomain_receive_settings?: "only_my_connections"|"from_anyone"}
  --outbound: record # shape: {channel_limit?: int, outbound_voice_profile_id?: string}
  --status-callback: string # URL for Telnyx to send requests to containing information about call progress events. (format: url, e.g. https://example.com)
  --status-callback-method: string@status-callback-method-completer # HTTP request method Telnyx should use when requesting the status_callback URL. (default: post, e.g. get)
  --voice-fallback-url: string # URL to which Telnyx will deliver your XML Translator webhooks if we get an error response from your voice_url. (format: url, e.g. https://fallback.example.com)
  --voice-method: string@voice-method-completer # HTTP request method Telnyx will use to interact with your XML Translator webhooks. Either 'get' or 'post'. (default: post, e.g. get)
  voice_url: string # URL to which Telnyx will deliver your XML Translator webhooks. (format: url, e.g. https://example.com)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/texml_applications"
    body: {content_type: "application/json", kind: json, fields: [{name: active, var: active}, {name: anchorsite_override, var: anchorsite_override}, {name: dtmf_type, var: dtmf_type}, {name: first_command_timeout, var: first_command_timeout}, {name: first_command_timeout_secs, var: first_command_timeout_secs}, {name: friendly_name, var: friendly_name}, {name: inbound, var: inbound}, {name: outbound, var: outbound}, {name: status_callback, var: status_callback}, {name: status_callback_method, var: status_callback_method}, {name: voice_fallback_url, var: voice_fallback_url}, {name: voice_method, var: voice_method}, {name: voice_url, var: voice_url}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    active: $active, anchorsite_override: $anchorsite_override, dtmf_type: $dtmf_type, first_command_timeout: $first_command_timeout, first_command_timeout_secs: $first_command_timeout_secs, friendly_name: $friendly_name, inbound: $inbound, outbound: $outbound, status_callback: $status_callback, status_callback_method: $status_callback_method, voice_fallback_url: $voice_fallback_url, voice_method: $voice_method, voice_url: $voice_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a TeXML Application
#
# DELETE /texml_applications/{id}
# Returns: record<data: record<active: bool, anchorsite_override: string, created_at: string, dtmf_type: string, first_command_timeout: bool, first_command_timeout_secs: int, friendly_name: string, id: string, inbound: record<channel_limit: int, sip_subdomain: string, sip_subdomain_receive_settings: string>, outbound: record<channel_limit: int, outbound_voice_profile_id: string>, record_type: string, status_callback: string, status_callback_method: string, updated_at: string, voice_fallback_url: string, voice_method: string, voice_url: string>>
# operationId: DeleteTexmlApplication
export def "delete-texml-application" [
  id: string
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
    method: delete
    path: "/texml_applications/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a TeXML Application
#
# GET /texml_applications/{id}
# Returns: record<data: record<active: bool, anchorsite_override: string, created_at: string, dtmf_type: string, first_command_timeout: bool, first_command_timeout_secs: int, friendly_name: string, id: string, inbound: record<channel_limit: int, sip_subdomain: string, sip_subdomain_receive_settings: string>, outbound: record<channel_limit: int, outbound_voice_profile_id: string>, record_type: string, status_callback: string, status_callback_method: string, updated_at: string, voice_fallback_url: string, voice_method: string, voice_url: string>>
# operationId: getTexmlApplication
export def "get-texml-application" [
  id: string
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
    path: "/texml_applications/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a TeXML Application
#
# PATCH /texml_applications/{id}
# Returns: record<data: record<active: bool, anchorsite_override: string, created_at: string, dtmf_type: string, first_command_timeout: bool, first_command_timeout_secs: int, friendly_name: string, id: string, inbound: record<channel_limit: int, sip_subdomain: string, sip_subdomain_receive_settings: string>, outbound: record<channel_limit: int, outbound_voice_profile_id: string>, record_type: string, status_callback: string, status_callback_method: string, updated_at: string, voice_fallback_url: string, voice_method: string, voice_url: string>>
# operationId: UpdateTexmlApplication
export def "update-texml-application" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # Specifies whether the connection can be used. (default: true, e.g. false)
  --anchorsite-override: string@anchorsite-override-completer-1 # `Latency` directs Telnyx to route media through the site with the lowest round-trip time to the user's connection. Telnyx calculates this time using ICMP ping messages. This can be disabled by specifying a site to handle all media. (default: Latency, e.g. Amsterdam, Netherlands)
  --dtmf-type: string@dtmf-type-completer # Sets the type of DTMF digits sent from Telnyx to this Connection. Note that DTMF digits sent to Telnyx will be accepted in all formats. (default: RFC 2833, e.g. Inband)
  --first-command-timeout: oneof<nothing, bool> # Specifies whether calls to phone numbers associated with this connection should hangup after timing out. (default: false, e.g. true)
  --first-command-timeout-secs: int # Specifies how many seconds to wait before timing out a dial command. (default: 30, e.g. 10)
  friendly_name: string # A user-assigned name to help manage the application. (e.g. call-router)
  --inbound: record # shape: {channel_limit?: int, sip_subdomain?: string, sip_subdomain_receive_settings?: "only_my_connections"|"from_anyone"}
  --outbound: record # shape: {channel_limit?: int, outbound_voice_profile_id?: string}
  --status-callback: string # URL for Telnyx to send requests to containing information about call progress events. (format: url, e.g. https://example.com)
  --status-callback-method: string@status-callback-method-completer # HTTP request method Telnyx should use when requesting the status_callback URL. (default: post, e.g. get)
  --voice-fallback-url: string # URL to which Telnyx will deliver your XML Translator webhooks if we get an error response from your voice_url. (format: url, e.g. https://fallback.example.com)
  --voice-method: string@voice-method-completer # HTTP request method Telnyx will use to interact with your XML Translator webhooks. Either 'get' or 'post'. (default: post, e.g. get)
  voice_url: string # URL to which Telnyx will deliver your XML Translator webhooks. (format: url, e.g. https://example.com)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/texml_applications/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: active, var: active}, {name: anchorsite_override, var: anchorsite_override}, {name: dtmf_type, var: dtmf_type}, {name: first_command_timeout, var: first_command_timeout}, {name: first_command_timeout_secs, var: first_command_timeout_secs}, {name: friendly_name, var: friendly_name}, {name: inbound, var: inbound}, {name: outbound, var: outbound}, {name: status_callback, var: status_callback}, {name: status_callback_method, var: status_callback_method}, {name: voice_fallback_url, var: voice_fallback_url}, {name: voice_method, var: voice_method}, {name: voice_url, var: voice_url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, active: $active, anchorsite_override: $anchorsite_override, dtmf_type: $dtmf_type, first_command_timeout: $first_command_timeout, first_command_timeout_secs: $first_command_timeout_secs, friendly_name: $friendly_name, inbound: $inbound, outbound: $outbound, status_callback: $status_callback, status_callback_method: $status_callback_method, voice_fallback_url: $voice_fallback_url, voice_method: $voice_method, voice_url: $voice_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List verifications by phone number
#
# GET /verifications/by_phone_number/{phone_number}
# Returns: record<data: table<call_timeout_secs: int, created_at: string, id: string, phone_number: string, record_type: string, status: string, timeout_secs: int, updated_at: string, verification_type: string, verify_profile_id: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: listVerifications
export def "list-verifications" [
  phone_number: string
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
    path: "/verifications/by_phone_number/{phone_number}"
    path_params: [{name: phone_number, var: phone_number}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    phone_number: $phone_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Submit a verification code
#
# POST /verifications/by_phone_number/{phone_number}/actions/verify
# Returns: record<data: record<phone_number: string, response_code: string>>
# operationId: verifyVerificationCode
export def "verify-verification-code" [
  phone_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  code: string # This is the code the user submits for verification. (e.g. 17686)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/verifications/by_phone_number/{phone_number}/actions/verify"
    path_params: [{name: phone_number, var: phone_number}]
    body: {content_type: "application/json", kind: json, fields: [{name: code, var: code}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    phone_number: $phone_number, code: $code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Trigger a Call verification
#
# POST /verifications/call
# Returns: record<data: record<call_timeout_secs: int, created_at: string, id: string, phone_number: string, record_type: string, status: string, timeout_secs: int, updated_at: string, verification_type: string, verify_profile_id: string>>
# operationId: createVerificationCall
export def "create-verification-call" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --call-timeout-secs: int # Must be less than the profile's default_verification_timeout_secs or timeout_secs, whichever is lesser. (e.g. 30)
  phone_number: string # +E164 formatted phone number. (e.g. +13035551234)
  --timeout-secs: int # The number of seconds the verification code is valid for. (e.g. 300)
  verify_profile_id: string # The identifier of the associated Verify profile. (format: uuid, e.g. 12ade33a-21c0-473b-b055-b3c836e1c292)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/verifications/call"
    body: {content_type: "application/json", kind: json, fields: [{name: call_timeout_secs, var: call_timeout_secs}, {name: phone_number, var: phone_number}, {name: timeout_secs, var: timeout_secs}, {name: verify_profile_id, var: verify_profile_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    call_timeout_secs: $call_timeout_secs, phone_number: $phone_number, timeout_secs: $timeout_secs, verify_profile_id: $verify_profile_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Trigger a Flash call verification
#
# POST /verifications/flashcall
# Returns: record<data: record<call_timeout_secs: int, created_at: string, id: string, phone_number: string, record_type: string, status: string, timeout_secs: int, updated_at: string, verification_type: string, verify_profile_id: string>>
# operationId: createVerificationFlashcall
export def "create-verification-flashcall" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  phone_number: string # +E164 formatted phone number. (e.g. +13035551234)
  --timeout-secs: int # The number of seconds the verification code is valid for. (e.g. 300)
  verify_profile_id: string # The identifier of the associated Verify profile. (format: uuid, e.g. 12ade33a-21c0-473b-b055-b3c836e1c292)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/verifications/flashcall"
    body: {content_type: "application/json", kind: json, fields: [{name: phone_number, var: phone_number}, {name: timeout_secs, var: timeout_secs}, {name: verify_profile_id, var: verify_profile_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    phone_number: $phone_number, timeout_secs: $timeout_secs, verify_profile_id: $verify_profile_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Trigger a PSD2 verification
#
# POST /verifications/psd2
# Returns: record<data: record<call_timeout_secs: int, created_at: string, id: string, phone_number: string, record_type: string, status: string, timeout_secs: int, updated_at: string, verification_type: string, verify_profile_id: string>>
# operationId: createVerificationPSD2
export def "create-verification-psd2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  amount: string # e.g. 99.99
  currency: string@currency-completer # The supported currencies. (e.g. USD)
  payee: string # e.g. Acme Corp Inc. LTD
  phone_number: string # +E164 formatted phone number. (e.g. +13035551234)
  --timeout-secs: int # The number of seconds the verification code is valid for. (e.g. 300)
  verify_profile_id: string # The identifier of the associated Verify profile. (format: uuid, e.g. 12ade33a-21c0-473b-b055-b3c836e1c292)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/verifications/psd2"
    body: {content_type: "application/json", kind: json, fields: [{name: amount, var: amount}, {name: currency, var: currency}, {name: payee, var: payee}, {name: phone_number, var: phone_number}, {name: timeout_secs, var: timeout_secs}, {name: verify_profile_id, var: verify_profile_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    amount: $amount, currency: $currency, payee: $payee, phone_number: $phone_number, timeout_secs: $timeout_secs, verify_profile_id: $verify_profile_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Trigger a SMS verification
#
# POST /verifications/sms
# Returns: record<data: record<call_timeout_secs: int, created_at: string, id: string, phone_number: string, record_type: string, status: string, timeout_secs: int, updated_at: string, verification_type: string, verify_profile_id: string>>
# operationId: createVerificationSMS
export def "create-verification-sms" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  phone_number: string # +E164 formatted phone number. (e.g. +13035551234)
  --timeout-secs: int # The number of seconds the verification code is valid for. (e.g. 300)
  verify_profile_id: string # The identifier of the associated Verify profile. (format: uuid, e.g. 12ade33a-21c0-473b-b055-b3c836e1c292)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/verifications/sms"
    body: {content_type: "application/json", kind: json, fields: [{name: phone_number, var: phone_number}, {name: timeout_secs, var: timeout_secs}, {name: verify_profile_id, var: verify_profile_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    phone_number: $phone_number, timeout_secs: $timeout_secs, verify_profile_id: $verify_profile_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Trigger a Whatsapp verification
#
# POST /verifications/whatsapp
# Returns: record<data: record<call_timeout_secs: int, created_at: string, id: string, phone_number: string, record_type: string, status: string, timeout_secs: int, updated_at: string, verification_type: string, verify_profile_id: string>>
# operationId: createVerificationWhatsapp
export def "create-verification-whatsapp" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  phone_number: string # +E164 formatted phone number. (e.g. +13035551234)
  --timeout-secs: int # The number of seconds the verification code is valid for. (e.g. 300)
  verify_profile_id: string # The identifier of the associated Verify profile. (format: uuid, e.g. 12ade33a-21c0-473b-b055-b3c836e1c292)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/verifications/whatsapp"
    body: {content_type: "application/json", kind: json, fields: [{name: phone_number, var: phone_number}, {name: timeout_secs, var: timeout_secs}, {name: verify_profile_id, var: verify_profile_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    phone_number: $phone_number, timeout_secs: $timeout_secs, verify_profile_id: $verify_profile_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a verification
#
# GET /verifications/{verification_id}
# Returns: record<data: record<call_timeout_secs: int, created_at: string, id: string, phone_number: string, record_type: string, status: string, timeout_secs: int, updated_at: string, verification_type: string, verify_profile_id: string>>
# operationId: retrieveVerification
export def "retrieve-verification" [
  verification_id: string
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
    path: "/verifications/{verification_id}"
    path_params: [{name: verification_id, var: verification_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    verification_id: $verification_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all Verify profiles
#
# GET /verify_profiles
# Returns: record<data: table<call: record, created_at: string, flashcall: record, id: string, language: string, name: string, psd2: record, record_type: string, sms: record, updated_at: string, webhook_failover_url: string, webhook_url: string, whatsapp: record>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: listVerifyProfiles
export def "list-verify-profiles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-name: string
  --page-size: int # default: 25
  --page-number: int # default: 1
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/verify_profiles"
    query: [{name: "filter[name]", var: filter_name}, {name: "page[size]", var: page_size}, {name: "page[number]", var: page_number}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter_name: $filter_name, page_size: $page_size, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a Verify profile
#
# POST /verify_profiles
# Returns: record<data: record<call: record<default_call_timeout_secs: int, default_verification_timeout_secs: int, speech_template: string>, created_at: string, flashcall: record<default_verification_timeout_secs: int>, id: string, language: string, name: string, psd2: record<default_verification_timeout_secs: int>, record_type: string, sms: record<default_verification_timeout_secs: int, messaging_enabled: bool, messaging_template: string, rcs_enabled: bool, vsms_enabled: bool>, updated_at: string, webhook_failover_url: string, webhook_url: string, whatsapp: record<app_name: string, default_verification_timeout_secs: int>>>
# operationId: createVerifyProfile
export def "create-verify-profile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --call: record # shape: {default_call_timeout_secs?: int, default_verification_timeout_secs?: int, speech_template?: string}
  --flashcall: record # shape: {default_verification_timeout_secs?: int}
  --language: string # e.g. en-US
  name: string # e.g. Test Profile
  --psd2: record # shape: {default_verification_timeout_secs?: int}
  --sms: record # shape: {default_verification_timeout_secs?: int, messaging_enabled?: bool, messaging_template?: string, rcs_enabled?: bool, vsms_enabled?: bool}
  --webhook-failover-url: string # e.g. http://example.com/webhook/failover
  --webhook-url: string # e.g. http://example.com/webhook
  --whatsapp: record # shape: {app_name?: string, default_verification_timeout_secs?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/verify_profiles"
    body: {content_type: "application/json", kind: json, fields: [{name: call, var: call}, {name: flashcall, var: flashcall}, {name: language, var: language}, {name: name, var: name}, {name: psd2, var: psd2}, {name: sms, var: sms}, {name: webhook_failover_url, var: webhook_failover_url}, {name: webhook_url, var: webhook_url}, {name: whatsapp, var: whatsapp}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    call: $call, flashcall: $flashcall, language: $language, name: $name, psd2: $psd2, sms: $sms, webhook_failover_url: $webhook_failover_url, webhook_url: $webhook_url, whatsapp: $whatsapp
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a Verify profile
#
# DELETE /verify_profiles/{verify_profile_id}
# Returns: record<data: record<call: record<default_call_timeout_secs: int, default_verification_timeout_secs: int, speech_template: string>, created_at: string, flashcall: record<default_verification_timeout_secs: int>, id: string, language: string, name: string, psd2: record<default_verification_timeout_secs: int>, record_type: string, sms: record<default_verification_timeout_secs: int, messaging_enabled: bool, messaging_template: string, rcs_enabled: bool, vsms_enabled: bool>, updated_at: string, webhook_failover_url: string, webhook_url: string, whatsapp: record<app_name: string, default_verification_timeout_secs: int>>>
# operationId: deleteVerifyProfile
export def "delete-verify-profile" [
  verify_profile_id: string
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
    method: delete
    path: "/verify_profiles/{verify_profile_id}"
    path_params: [{name: verify_profile_id, var: verify_profile_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    verify_profile_id: $verify_profile_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a Verify profile
#
# GET /verify_profiles/{verify_profile_id}
# Returns: record<data: record<call: record<default_call_timeout_secs: int, default_verification_timeout_secs: int, speech_template: string>, created_at: string, flashcall: record<default_verification_timeout_secs: int>, id: string, language: string, name: string, psd2: record<default_verification_timeout_secs: int>, record_type: string, sms: record<default_verification_timeout_secs: int, messaging_enabled: bool, messaging_template: string, rcs_enabled: bool, vsms_enabled: bool>, updated_at: string, webhook_failover_url: string, webhook_url: string, whatsapp: record<app_name: string, default_verification_timeout_secs: int>>>
# operationId: retrieveVerifyProfile
export def "retrieve-verify-profile" [
  verify_profile_id: string
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
    path: "/verify_profiles/{verify_profile_id}"
    path_params: [{name: verify_profile_id, var: verify_profile_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    verify_profile_id: $verify_profile_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a Verify profile
#
# PATCH /verify_profiles/{verify_profile_id}
# Returns: record<data: record<call: record<default_call_timeout_secs: int, default_verification_timeout_secs: int, speech_template: string>, created_at: string, flashcall: record<default_verification_timeout_secs: int>, id: string, language: string, name: string, psd2: record<default_verification_timeout_secs: int>, record_type: string, sms: record<default_verification_timeout_secs: int, messaging_enabled: bool, messaging_template: string, rcs_enabled: bool, vsms_enabled: bool>, updated_at: string, webhook_failover_url: string, webhook_url: string, whatsapp: record<app_name: string, default_verification_timeout_secs: int>>>
# operationId: updateVerifyProfile
export def "update-verify-profile" [
  verify_profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --call: record # shape: {default_call_timeout_secs?: int, default_verification_timeout_secs?: int, speech_template?: string}
  --flashcall: record # shape: {default_verification_timeout_secs?: int}
  --language: string # e.g. en-US
  --name: string # e.g. Test Profile
  --psd2: record # shape: {default_verification_timeout_secs?: int}
  --sms: record # shape: {default_verification_timeout_secs?: int, messaging_enabled?: bool, messaging_template?: string, rcs_enabled?: bool, vsms_enabled?: bool}
  --webhook-failover-url: string # e.g. http://example.com/webhook/failover
  --webhook-url: string # e.g. http://example.com/webhook
  --whatsapp: record # shape: {app_name?: string, default_verification_timeout_secs?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/verify_profiles/{verify_profile_id}"
    path_params: [{name: verify_profile_id, var: verify_profile_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: call, var: call}, {name: flashcall, var: flashcall}, {name: language, var: language}, {name: name, var: name}, {name: psd2, var: psd2}, {name: sms, var: sms}, {name: webhook_failover_url, var: webhook_failover_url}, {name: webhook_url, var: webhook_url}, {name: whatsapp, var: whatsapp}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    verify_profile_id: $verify_profile_id, call: $call, flashcall: $flashcall, language: $language, name: $name, psd2: $psd2, sms: $sms, webhook_failover_url: $webhook_failover_url, webhook_url: $webhook_url, whatsapp: $whatsapp
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List webhook deliveries
#
# GET /webhook_deliveries
# Returns: record<data: table<attempts: list, finished_at: string, id: string, record_type: string, started_at: string, status: string, user_id: string, webhook: record>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: getWebhookDeliveries
export def "get-webhook-deliveries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-status-eq: string@filter-status-eq-completer-1 # Return only webhook_deliveries matching the given `status` (e.g. delivered)
  --filter-webhook-contains: string # Return only webhook deliveries whose `webhook` component contains the given text (e.g. call.initiated)
  --filter-attempts-contains: string # Return only webhook_deliveries whose `attempts` component contains the given text (e.g. https://fallback.example.com/webhooks)
  --filter-started-at-gte: string # Return only webhook_deliveries whose delivery started later than or at given ISO 8601 datetime (e.g. 2019-03-29T11:10:00Z)
  --filter-started-at-lte: string # Return only webhook_deliveries whose delivery started earlier than or at given ISO 8601 datetime (e.g. 2019-03-29T11:10:00Z)
  --filter-finished-at-gte: string # Return only webhook_deliveries whose delivery finished later than or at given ISO 8601 datetime (e.g. 2019-03-29T11:10:00Z)
  --filter-finished-at-lte: string # Return only webhook_deliveries whose delivery finished earlier than or at given ISO 8601 datetime (e.g. 2019-03-29T11:10:00Z)
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/webhook_deliveries"
    query: [{name: "filter[status][eq]", var: filter_status_eq}, {name: "filter[webhook][contains]", var: filter_webhook_contains}, {name: "filter[attempts][contains]", var: filter_attempts_contains}, {name: "filter[started_at][gte]", var: filter_started_at_gte}, {name: "filter[started_at][lte]", var: filter_started_at_lte}, {name: "filter[finished_at][gte]", var: filter_finished_at_gte}, {name: "filter[finished_at][lte]", var: filter_finished_at_lte}, {name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter_status_eq: $filter_status_eq, filter_webhook_contains: $filter_webhook_contains, filter_attempts_contains: $filter_attempts_contains, filter_started_at_gte: $filter_started_at_gte, filter_started_at_lte: $filter_started_at_lte, filter_finished_at_gte: $filter_finished_at_gte, filter_finished_at_lte: $filter_finished_at_lte, page_number: $page_number, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find webhook_delivery details by ID
#
# GET /webhook_deliveries/{id}
# Returns: record<data: record<attempts: list<record>, finished_at: string, id: string, record_type: string, started_at: string, status: string, user_id: string, webhook: record<event_type: string, id: string, occurred_at: string, payload: record, record_type: string>>>
# operationId: getWebhookDelivery
export def "get-webhook-delivery" [
  id: string
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
    path: "/webhook_deliveries/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check Contact
#
# POST /whatsapp_contacts
# Returns: record<data: table<id: string, input: string, record_type: string, status: string>>
# operationId: checkContact
export def "check-contact" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --blocking: string@blocking-completer # Blocking determines whether the request should wait for the processing to complete (synchronous) or not (asynchronous). (default: no_wait)
  contacts: list<string> # Array of contact phone numbers. The numbers can be in any standard telephone number format.
  whatsapp_user_id: string # The sender's WhatsApp ID.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/whatsapp_contacts"
    body: {content_type: "application/json", kind: json, fields: [{name: blocking, var: blocking}, {name: contacts, var: contacts}, {name: whatsapp_user_id, var: whatsapp_user_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    blocking: $blocking, contacts: $contacts, whatsapp_user_id: $whatsapp_user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch all previous requests for WhatsApp detail reports. WhatsApp detail reports are reports for pulling all WhatsApp records.
#
# GET /whatsapp_detail_record_reports
# Returns: record<data: table<created_at: string, download_link: string, end_date: string, id: string, record_type: string, start_date: string, status: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>>
# operationId: getRequests
export def "get-requests" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # Page number (format: int32, default: 1)
  --page-size: int # Size of the page (format: int32, default: 20)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/whatsapp_detail_record_reports"
    query: [{name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_number: $page_number, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Submit a request for new WhatsApp detail report. WhatsApp detail report pulls all raw WhatsApp data according to defined filters.
#
# POST /whatsapp_detail_record_reports
# Returns: record<data: record<created_at: string, download_link: string, end_date: string, id: string, record_type: string, start_date: string, status: string>>
# operationId: submitRequest
export def "submit-request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  end_date: string # format: date-time, e.g. 2021-05-01T00:00:00-06:00
  start_date: string # format: date-time, e.g. 2021-05-01T00:00:00-06:00
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/whatsapp_detail_record_reports"
    body: {content_type: "application/json", kind: json, fields: [{name: end_date, var: end_date}, {name: start_date, var: start_date}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    end_date: $end_date, start_date: $start_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete generated WhatsApp detail report by id
#
# DELETE /whatsapp_detail_record_reports/{id}
# Returns: record<data: record<created_at: string, download_link: string, end_date: string, id: string, record_type: string, start_date: string, status: string>>
# operationId: deleteRequest
export def "delete-request" [
  id: string
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
    method: delete
    path: "/whatsapp_detail_record_reports/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch single whatsapp detail report by id.
#
# GET /whatsapp_detail_record_reports/{id}
# Returns: record<data: record<created_at: string, download_link: string, end_date: string, id: string, record_type: string, start_date: string, status: string>>
# operationId: getRequest
export def "get-request" [
  id: string
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
    path: "/whatsapp_detail_record_reports/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload Media
#
# POST /whatsapp_media
# Returns: record<data: table<id: string, record_type: string>>
# operationId: uploadMedia
export def "upload-media" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  media_content_type: string # The content-type of the uplaoded media.
  upload_file: string # The media to store with WhatsApp. (format: binary)
  whatsapp_user_id: string # The user's WhatsApp ID.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/whatsapp_media"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: media_content_type, var: media_content_type}, {name: upload_file, var: upload_file}, {name: whatsapp_user_id, var: whatsapp_user_id}], files: [upload_file]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    media_content_type: $media_content_type, upload_file: $upload_file, whatsapp_user_id: $whatsapp_user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Media
#
# DELETE /whatsapp_media/{whatsapp_user_id}/{media_id}
export def "delete-whatsapp-media-whatsapp-user-id-media-id" [
  whatsapp_user_id: string
  media_id: string
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
    path: "/whatsapp_media/{whatsapp_user_id}/{media_id}"
    path_params: [{name: whatsapp_user_id, var: whatsapp_user_id}, {name: media_id, var: media_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    whatsapp_user_id: $whatsapp_user_id, media_id: $media_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download Media
#
# GET /whatsapp_media/{whatsapp_user_id}/{media_id}
# Returns: binary
export def "get-whatsapp-media-whatsapp-user-id-media-id" [
  whatsapp_user_id: string
  media_id: string
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
]: nothing -> any {
  http-request {
    method: get
    path: "/whatsapp_media/{whatsapp_user_id}/{media_id}"
    path_params: [{name: whatsapp_user_id, var: whatsapp_user_id}, {name: media_id, var: media_id}]
    accept: ["*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    whatsapp_user_id: $whatsapp_user_id, media_id: $media_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Send Message
#
# POST /whatsapp_messages
# Returns: record<data: record<id: string, record_type: string>>
# operationId: sendMessage
export def "send-message" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --audio: record # The media object containing audio details. (e.g. {id: f043afd0-f0ae-4b9c-ab3d-696fb4c8cd68}) — shape: {id?: string, link?: string}
  --contacts: list # item shape: {addresses?: list, birthday?: string, emails?: list, ims?: list<string>, name?: record, org?: record, phones?: list, urls?: list}
  --document: record # The media object containing a document reference (e.g. {caption: Very important document, filename: example.pdf, id: f043afd0-f0ae-4b9c-ab3d-696fb4c8cd68}) — shape: {caption?: string, filename?: string, id?: string, link?: string}
  --hsm: record # The containing element for the message content — Indicates that the message is highly structured. Parameters contained within provide the structure. (e.g. {element_name: hello_world, language: {code: en, policy: deterministic}, localizable_params: [{default: 1234}], namespace: business_a_namespace}) — shape: {element_name: string, language: record, localizable_params: list, namespace: string}
  --image: record # The media object containing an image (e.g. {caption: My cool media!, id: f043afd0-f0ae-4b9c-ab3d-696fb4c8cd68}) — shape: {caption?: string, id?: string, link?: string}
  --location: record # e.g. {address: <Location's Address>, latitude: <Latitude>, longitude: <Longitude>, name: <Location Name>} — shape: {address: string, latitude: string, longitude: string, name: string}
  --preview-url: oneof<nothing, bool> # Specifying preview_url in the request is optional when not including a URL in your message. To include a URL preview, set preview_url to true in the message body and make sure the URL begins with http:// or https://.
  --template: record # shape: {components?: list, language: record, name: string, namespace: string}
  --text: record # e.g. {body: <Message Text>} — shape: {body: string}
  to: string # The WhatsApp ID (phone number) returned from contacts endpoint.
  --type: string@type-completer-2 # type of the message (default: text)
  --video: record # The media object containing a video (e.g. {caption: My cool media!, id: f043afd0-f0ae-4b9c-ab3d-696fb4c8cd68}) — shape: {caption?: string, id?: string, link?: string}
  whatsapp_user_id: string # The sender's WhatsApp ID.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/whatsapp_messages"
    body: {content_type: "application/json", kind: json, fields: [{name: audio, var: audio}, {name: contacts, var: contacts}, {name: document, var: document}, {name: hsm, var: hsm}, {name: image, var: image}, {name: location, var: location}, {name: preview_url, var: preview_url}, {name: template, var: template}, {name: text, var: text}, {name: to, var: to}, {name: type, var: type}, {name: video, var: video}, {name: whatsapp_user_id, var: whatsapp_user_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    audio: $audio, contacts: $contacts, document: $document, hsm: $hsm, image: $image, location: $location, preview_url: $preview_url, template: $template, text: $text, to: $to, type: $type, video: $video, whatsapp_user_id: $whatsapp_user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Mark Message As Read
#
# PATCH /whatsapp_messages/{message_id}
# operationId: markMessageAsRead
export def "mark-message-as-read" [
  message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  status: string # default: read
  whatsapp_user_id: string # The user's WhatsApp ID. (e.g. 15125551212)
]: any -> any {
  $in | http-request {
    method: patch
    path: "/whatsapp_messages/{message_id}"
    path_params: [{name: message_id, var: message_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: status, var: status}, {name: whatsapp_user_id, var: whatsapp_user_id}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    message_id: $message_id, status: $status, whatsapp_user_id: $whatsapp_user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generate and fetch WhatsApp usage aggregations synchronously. This endpoint will both generate and fetch the WhatsApp aggregations over a specified time period.
#
# GET /whatsapp_usage_aggregations
# Returns: record<data: table<cost: record, count: string, direction: string, message_type: string, recipient_country_code: string, record_type: string, status: string, telnyx_fee: record, whatsapp_fee: record>>
# operationId: getUsageAggregationsSync
export def "get-usage-aggregations-sync" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # format: date-time, e.g. 2020-07-01T00:00:00-06:00
  --end-date: string # format: date-time, e.g. 2020-07-01T00:00:00-06:00
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/whatsapp_usage_aggregations"
    query: [{name: start_date, var: start_date}, {name: end_date, var: end_date}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    start_date: $start_date, end_date: $end_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get User
#
# GET /whatsapp_users/{whatsapp_user_id}
# Returns: record<data: record<id: string, record_type: string, webhook_url: string>>
# operationId: getUser
export def "get-user" [
  whatsapp_user_id: string
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
    path: "/whatsapp_users/{whatsapp_user_id}"
    path_params: [{name: whatsapp_user_id, var: whatsapp_user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    whatsapp_user_id: $whatsapp_user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update WhatsApp User
#
# PATCH /whatsapp_users/{whatsapp_user_id}
# operationId: updateWhatsAppWebhook
export def "update-whats-app-webhook" [
  whatsapp_user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  webhook_url: string # The desired URL to set for your WhatsApp webhook endpoint. (e.g. https://mywebhook.com/example/endpoint)
]: any -> any {
  $in | http-request {
    method: patch
    path: "/whatsapp_users/{whatsapp_user_id}"
    path_params: [{name: whatsapp_user_id, var: whatsapp_user_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: webhook_url, var: webhook_url}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    whatsapp_user_id: $whatsapp_user_id, webhook_url: $webhook_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all Wireless Detail Records (WDRs) Reports
#
# GET /wireless/detail_records_reports
# Returns: record<data: table<created_at: string, end_time: string, id: string, record_type: string, report_url: string, start_time: string, status: string, updated_at: string>>
# operationId: getWdrReports
export def "get-wdr-reports" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/wireless/detail_records_reports"
    query: [{name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_number: $page_number, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a Wireless Detail Records (WDRs) Report
#
# POST /wireless/detail_records_reports
# Returns: record<data: record<created_at: string, end_time: string, id: string, record_type: string, report_url: string, start_time: string, status: string, updated_at: string>>
# operationId: createWdrReport
export def "create-wdr-report" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --end-time: string # ISO 8601 formatted date-time indicating the end time. (e.g. 2018-02-02T22:25:27.521Z)
  --start-time: string # ISO 8601 formatted date-time indicating the start time. (e.g. 2018-02-02T22:25:27.521Z)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/wireless/detail_records_reports"
    body: {content_type: "application/json", kind: json, fields: [{name: end_time, var: end_time}, {name: start_time, var: start_time}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    end_time: $end_time, start_time: $start_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a Wireless Detail Record (WDR) Report
#
# DELETE /wireless/detail_records_reports/{id}
# Returns: record<data: record<created_at: string, end_time: string, id: string, record_type: string, report_url: string, start_time: string, status: string, updated_at: string>>
# operationId: deleteWdrReport
export def "delete-wdr-report" [
  id: string
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
    method: delete
    path: "/wireless/detail_records_reports/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a Wireless Detail Record (WDR) Report
#
# GET /wireless/detail_records_reports/{id}
# Returns: record<data: record<created_at: string, end_time: string, id: string, record_type: string, report_url: string, start_time: string, status: string, updated_at: string>>
# operationId: getWdrReport
export def "get-wdr-report" [
  id: string
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
    path: "/wireless/detail_records_reports/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
