# Auto-generated client for hetras Booking API Version 0 v0
# Source: https://api.apis.guru/v2/specs/hetras-certification.net/booking/v0/swagger.json
# Auth: --token flag or $env.HETRAS_BOOKING_API_VERSION_0_TOKEN

const CLIENT = {
  base_url: "https://api.hetras-certification.net"
  token_env_var: "HETRAS_BOOKING_API_VERSION_0_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: []
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

def base-url-completer [] { ["https://api.hetras-certification.net"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def expand-completer [] { ["Breakdown" "None"] }
def accept-completer [] { ["application/json" "text/json"] }
def expand-completer-1 [] { ["RoomTypes"] }
def inlinecount-completer [] { ["AllPages" "None"] }
def status-completer [] { ["Cancelled" "Definite" "Tentative"] }
def date-filter-completer [] { ["ArrivalDate" "CreationDate" "DepartureDate" "ModificationDate" "StayDate"] }
def exclude-completer [] { ["Customers"] }
def payment-method-completer [] { ["Cash" "ChargeToCompany" "Check" "CreditCard" "DebitCard" "DigitalPayment" "Miscellaneous" "None" "Token" "Voucher" "WireTransfer"] }
def expand-completer-2 [] { ["None" "RoomRates"] }
def exclude-completer-1 [] { ["Customers" "None"] }
def condition-completer [] { ["Any" "Clean" "CleanNotInspected" "Dirty"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    addons-get: "record<addon_services: table<breakdown: list, code: string, description: string, frequency: string, name: string, rate_mode: string, total_stay: record>, adults: int, arrival_date: string, departure_date: string, hotel_id: int, hotel_name: string, rate_plan: record<code: string, description: string, name: string>, room: record<description: string, name: string, room_number: int, type: string>, rooms: int>"
    availability-get: "record<_count: int, _links: record, daily_availabilities: table<business_day: string, house_level: record, room_types: list>, hotel: record<code: string, id: int, name: string>>"
    blocks-get-blocks-async: "record"
    blocks-get-blocks-count-async: "record<_count: int>"
    blocks-get-single-block-async: "record"
    bookings-get-bookings: "record<_count: int, _links: record, bookings: table<_links: record, confirmation_id: string, created: string, reservations: list, updated: string>>"
    bookings-create-booking: "record<_warnings: list<string>, confirmation_id: string, reservation_id: int>"
    bookings-get-bookings-count: "record<_count: int>"
    bookings-get-booking: "record<reservations: table<_warnings: list, addon_services: list, adults: int, arrival_date: string, balance: float, block: record, cancellation_id: string, cancellation_policies: list, channel_code: string, checkin_time: string, checkout_time: string, comment: string, company: record, confirmation_id: string, contact: record, created: string, currency: string, departure_date: string, external_id: string, general_policies: list, guarantee: record, guests: list, hotel_id: int, labels: list, market_code: string, noshow_policy: record, payment_method: string, rate_plan: record, reservation_number: int, reservation_status: string, room: record, room_rates: list, rooms: int, services: list, subchannel_code: string, total_stay: record, updated: string>>"
    bookings-get-reservation: "record<_warnings: list<string>, addon_services: list<string>, adults: int, arrival_date: string, balance: float, block: record<_links: record, code: string, name: string>, cancellation_id: string, cancellation_policies: table<description: string, fee: float, fee_date: string>, channel_code: string, checkin_time: string, checkout_time: string, comment: string, company: record<company_id: string>, confirmation_id: string, contact: record<_links: record, customer_id: string>, created: string, currency: string, departure_date: string, external_id: string, general_policies: table<description: string, name: string>, guarantee: record<guarantee_type: string, valid_token: bool>, guests: table<_links: record, customer_id: string, email: string, first_name: string, gender: string, last_name: string, mailing_address: record, nationality: string, phone: string, primary: bool, subscribed_consents: list, title: string>, hotel_id: int, labels: list<string>, market_code: string, noshow_policy: record<description: string, fee: float>, payment_method: string, rate_plan: record<code: string, description: string, name: string>, reservation_number: int, reservation_status: string, room: record<_links: record, description: string, name: string, number: string, room_type: record<_links: record, code: string, description: string, name: string>>, room_rates: table<addon_services: list, date: string, excluded_tax: float, included_services: list, included_tax: float, rate: float, room_type: string>, rooms: int, services: table<code: string, description: string, frequency: string, is_addon: bool, name: string>, subchannel_code: string, total_stay: record<addon_services: list<record>, excluded_tax: float, included_services: list<string>, included_tax: float, rate: float>, updated: string>"
    bookings-patch: "record"
    bookings-post-room-assignment: "record<_warnings: list<string>, room_number: string>"
    bookings-cancel-reservation: "record<_warnings: list<string>, balance: float, cancellation_fee: float, cancellation_id: string>"
    bookings-check-in: "record<_warnings: list<string>>"
    bookings-check-out: "record<_warnings: list<string>>"
    bookings-payment-token: "record<_warnings: list<string>>"
    bookings-terminal-authorization: "record<_warnings: list<string>>"
    daily-rates-get-daily-rates: "record<_count: int, _links: record, daily_rates: table<business_day: string, offers: list>, hotel: record<_links: record, code: string, id: int, name: string>, policies: record<cancellation_policies: list<record>, guarantee_types: list<record>, noshow_policies: list<record>>, rateplans: table<_links: record, code: string, currency: string, name: string>, room_types: table<_links: record, code: string, name: string>>"
    rates-get: "record<arrival_date: string, departure_date: string, hotel_id: int, hotel_name: string, rate_plans: table<code: string, description: string, name: string>, room_offers: table<offers: list, room_type: string>, rooms: table<description: string, name: string, room_number: int, type: string>, services: table<code: string, description: string, frequency: string, is_addon: bool, name: string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["addons-get" "availability-get" "blocks-get-blocks-async" "blocks-get-blocks-count-async" "blocks-get-single-block-async" "bookings-get-bookings" "bookings-create-booking" "bookings-get-bookings-count" "bookings-get-booking" "bookings-get-reservation" "bookings-patch" "bookings-post-room-assignment" "bookings-cancel-reservation" "bookings-check-in" "bookings-check-out" "bookings-payment-token" "bookings-terminal-authorization" "daily-rates-get-daily-rates" "rates-get" "commands"] | sort) } | get name | first)
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

# Get a list of offers for addon services for the specified guest stay details.
#
# GET /api/booking/v0/addons
# Returns: record<addon_services: table<breakdown: list, code: string, description: string, frequency: string, name: string, rate_mode: string, total_stay: record>, adults: int, arrival_date: string, departure_date: string, hotel_id: int, hotel_name: string, rate_plan: record<code: string, description: string, name: string>, room: record<description: string, name: string, room_number: int, type: string>, rooms: int>
# operationId: Addons_Get
export def "addons-get" [
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
  --hotel-id: int # Specifies the hotel id to request offers for. (required, format: int32)
  --arrival-date: string # Date from when the addon service will be booked to the reservation in the ISO-8601 format "YYYY-MM-DD". (required, format: date-time)
  --departure-date: string # Date until when the addon service will be booked to the reservation in the ISO-8601 format "YYYY-MM-DD". This is usually the departure date of the reservation. (required, format: date-time)
  --channel-code: string # Channel Code the rate plan needs to be configured for. (required)
  --adults: string # Number of adults per room. (required, format: byte)
  --rooms: string # Number of rooms. (required, format: byte)
  --room-type: string # Only return offers for the specified room type code. (required)
  --rate-plan-code: string # Only return offers for the specified rate plan code. (required)
  --expand: string@expand-completer # Expand the rates breakdown if required.
  --app-id: string # Application identifier (required)
  --app-key: string # Application key. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/booking/v0/addons"
    query: [{name: hotelId, var: hotel_id, required: true}, {name: arrivalDate, var: arrival_date, required: true}, {name: departureDate, var: departure_date, required: true}, {name: channelCode, var: channel_code, required: true}, {name: adults, var: adults, required: true}, {name: rooms, var: rooms, required: true}, {name: roomType, var: room_type, required: true}, {name: ratePlanCode, var: rate_plan_code, required: true}, {name: expand, var: expand}]
    header: [{name: App-Id, var: app_id, required: true}, {name: App-Key, var: app_key, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    hotel_id: $hotel_id, arrival_date: $arrival_date, departure_date: $departure_date, channel_code: $channel_code, adults: $adults, rooms: $rooms, room_type: $room_type, rate_plan_code: $rate_plan_code, expand: $expand, app_id: $app_id, app_key: $app_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the availability and occupancy for a specific hotel and timespan.
#
# GET /api/booking/v0/availability
# Returns: record<_count: int, _links: record, daily_availabilities: table<business_day: string, house_level: record, room_types: list>, hotel: record<code: string, id: int, name: string>>
# operationId: Availability_Get
export def "availability-get" [
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
  --hotel-id: int # Specifies the hotel id to request the availability for. (required, format: int32)
  --from: string # Defines the first business day you would like to get availability numbers for. (required, format: date-time)
  --to: string # Defines the last business day you would like to get availability numbers for. The maximum time span between from´and to is limited to 365 days. (required, format: date-time)
  --expand: string@expand-completer-1 # You can expand the room types breakdown per business day for the availibility numbers if need be.
  --skip: int # Amount of items to skip. (format: int32)
  --top: int # Amount of items to select. (format: int32)
  --inlinecount: string@inlinecount-completer # Return total number of items for a given filter criteria.
  --app-id: string # Application identifier (required)
  --app-key: string # Application key. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/booking/v0/availability"
    query: [{name: hotelId, var: hotel_id, required: true}, {name: from, var: from, required: true}, {name: to, var: to, required: true}, {name: expand, var: expand}, {name: skip, var: skip}, {name: top, var: top}, {name: inlinecount, var: inlinecount}]
    header: [{name: App-Id, var: app_id, required: true}, {name: App-Key, var: app_key, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    hotel_id: $hotel_id, from: $from, to: $to, expand: $expand, skip: $skip, top: $top, inlinecount: $inlinecount, app_id: $app_id, app_key: $app_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets a list of blocks.
#
# GET /api/booking/v0/blocks
# Returns: record
# operationId: Blocks_GetBlocksAsync
export def "blocks-get-blocks-async" [
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
  --hotel-id: int # Only return blocks for this specific hotel. (format: int32)
  --group-code: string # Filter the blocks by the specified group code
  --from: string # Return all blocks where the block's last_departure is greater than specified date. (format: date-time)
  --to: string # Return all blocks where the block's last_departure is less than specified date. (format: date-time)
  --status: string@status-completer # Return all blocks where the block status is one of the specified values.
  --rate-plan-codes: list<string> # Return all blocks that have related the specified comma-separated rate plans.
  --count-details: oneof<nothing, bool> # If true it will include also details of block count per each room type.
  --skip: int # Amount of items to skip. (format: int32)
  --top: int # Amount of items to select. (format: int32)
  --inlinecount: string@inlinecount-completer # Return total number of items for a given filter criteria.
  --app-id: string # Application identifier (required)
  --app-key: string # Application key. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/booking/v0/blocks"
    query: [{name: hotelId, var: hotel_id}, {name: groupCode, var: group_code}, {name: from, var: from}, {name: to, var: to}, {name: status, var: status}, {name: ratePlanCodes, var: rate_plan_codes, style: csv}, {name: countDetails, var: count_details}, {name: skip, var: skip}, {name: top, var: top}, {name: inlinecount, var: inlinecount}]
    header: [{name: App-Id, var: app_id, required: true}, {name: App-Key, var: app_key, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200, 204]
    auth: bearer
  } {
    hotel_id: $hotel_id, group_code: $group_code, from: $from, to: $to, status: $status, rate_plan_codes: $rate_plan_codes, count_details: $count_details, skip: $skip, top: $top, inlinecount: $inlinecount, app_id: $app_id, app_key: $app_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get total blocks count that match the given filter criteria.
#
# GET /api/booking/v0/blocks/$count
# Returns: record<_count: int>
# operationId: Blocks_GetBlocksCountAsync
export def "blocks-get-blocks-count-async" [
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
  --hotel-id: int # Only return blocks for this specific hotel. (format: int32)
  --group-code: string # Filter the blocks by the specified group code
  --from: string # Return all blocks where the block's last_departure is greater than specified date. (format: date-time)
  --to: string # Return all blocks where the block's last_departure is less than specified date. (format: date-time)
  --status: string@status-completer # Return all blocks where the block status is one of the specified values.
  --rate-plan-codes: list<string> # Return all blocks that have related the specified comma-separated rate plans.
  --count-details: oneof<nothing, bool> # If true it will include also details of block count per each room type.
  --app-id: string # Application identifier (required)
  --app-key: string # Application key. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/booking/v0/blocks/$count"
    query: [{name: hotelId, var: hotel_id}, {name: groupCode, var: group_code}, {name: from, var: from}, {name: to, var: to}, {name: status, var: status}, {name: ratePlanCodes, var: rate_plan_codes, style: csv}, {name: countDetails, var: count_details}]
    header: [{name: App-Id, var: app_id, required: true}, {name: App-Key, var: app_key, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    hotel_id: $hotel_id, group_code: $group_code, from: $from, to: $to, status: $status, rate_plan_codes: $rate_plan_codes, count_details: $count_details, app_id: $app_id, app_key: $app_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the details for a specific block.
#
# GET /api/booking/v0/blocks/{blockCode}
# Returns: record
# operationId: Blocks_GetSingleBlockAsync
export def "blocks-get-single-block-async" [
  block_code: string
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
  --app-id: string # Application identifier (required)
  --app-key: string # Application key. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/booking/v0/blocks/{blockCode}"
    path_params: [{name: blockCode, var: block_code}]
    header: [{name: App-Id, var: app_id, required: true}, {name: App-Key, var: app_key, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    block_code: $block_code, app_id: $app_id, app_key: $app_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Find bookings matching the given filter criteria.
#
# GET /api/booking/v0/bookings
# Returns: record<_count: int, _links: record, bookings: table<_links: record, confirmation_id: string, created: string, reservations: list, updated: string>>
# operationId: Bookings_GetBookings
export def "bookings-get-bookings" [
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
  --hotel-id: int # Only return bookings for this specific hotel. (format: int32)
  --cancellation-id: string # Return bookings for this cancellation id.
  --reservation-number: int # Return bookings matching this reservation number. Please note that reservation numbers are only unique within a hotel. If you don´t specify a hotel filter at the same time you could get back multiple bookings from different hotels. (format: int32)
  --customer-name: string # Return all bookings where the first or lastname of one of the guests or the contact contains the specified value. The search is executed case insensitive and also stripping of any whitespaces.
  --customer-email: string # Return all bookings where the primary email address of one of the guests or the contact contains the specified value. The search is executed case insensitive and also stripping of any whitespaces.
  --customer-id: string # Return all bookings the id of one of the guests or the contact matches the specified value.
  --room-number: string # Return all bookings having the specified room number assigned.
  --external-id: string # Return all bookings exactly matching the specified external id. This filter is case sensitive.
  --company-name: string # Return all bookings where the name of the linked company or travel agent profile contains the specified value. The search is executed case insensitive and also stripping of any whitespaces.
  --company-id: string # Return all bookings the id of the company or travel agent profile matches the specified value.
  --company-email: string # Return all bookings where the primary email address of the company or the travel agent profile contains the specified value. The search is executed case insensitive and also stripping of any whitespaces.
  --block-code: string # Return all bookings where the block code matches the specified value.
  --reservation-statuses: list<string> # Return all bookings where the reservation status is one of the specified values.
  --market-codes: list<string> # Return all bookings where the market code is one of the specified values.
  --channel-codes: list<string> # Return all bookings where the channel code is one of the specified values.
  --sub-channel-codes: list<string> # Return all bookings where the subchannel code is one of the specified values.
  --room-types: list<string> # Return all bookings where the room type is one of the specified values.
  --rate-plan-codes: list<string> # Return all bookings where the rate plan code is one of the specified values.
  --labels: list<string> # Return all reservations with at least one of the specified labels.
  --from: string # Start date for the selected date filter. If you select arrival date as date filter the bookings returned will have at least one reservation arriving on the specified date or later. (format: date-time)
  --to: string # End date for the selected date filter. If you select arrival date as date filter the bookings returned will have at least one reservation arriving on the specified date or earlier. (format: date-time)
  --date-filter: string@date-filter-completer # Select a date field you want to filter bookings by. Only one filter at a time can be applied. The to and from dates will then define the time range.
  --exclude: string@exclude-completer # To be able to request reservations without personal data based on GDPR.
  --skip: int # Amount of items to skip. (format: int32)
  --top: int # Amount of items to select. (format: int32)
  --inlinecount: string@inlinecount-completer # Return total number of items for a given filter criteria.
  --app-id: string # Application identifier (required)
  --app-key: string # Application key. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/booking/v0/bookings"
    query: [{name: hotelId, var: hotel_id}, {name: cancellationId, var: cancellation_id}, {name: reservationNumber, var: reservation_number}, {name: customerName, var: customer_name}, {name: customerEmail, var: customer_email}, {name: customerId, var: customer_id}, {name: roomNumber, var: room_number}, {name: externalId, var: external_id}, {name: companyName, var: company_name}, {name: companyId, var: company_id}, {name: companyEmail, var: company_email}, {name: blockCode, var: block_code}, {name: reservationStatuses, var: reservation_statuses, style: csv}, {name: marketCodes, var: market_codes, style: csv}, {name: channelCodes, var: channel_codes, style: csv}, {name: subChannelCodes, var: sub_channel_codes, style: csv}, {name: roomTypes, var: room_types, style: csv}, {name: ratePlanCodes, var: rate_plan_codes, style: csv}, {name: labels, var: labels, style: csv}, {name: from, var: from}, {name: to, var: to}, {name: dateFilter, var: date_filter}, {name: exclude, var: exclude}, {name: skip, var: skip}, {name: top, var: top}, {name: inlinecount, var: inlinecount}]
    header: [{name: App-Id, var: app_id, required: true}, {name: App-Key, var: app_key, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200, 204]
    auth: bearer
  } {
    hotel_id: $hotel_id, cancellation_id: $cancellation_id, reservation_number: $reservation_number, customer_name: $customer_name, customer_email: $customer_email, customer_id: $customer_id, room_number: $room_number, external_id: $external_id, company_name: $company_name, company_id: $company_id, company_email: $company_email, block_code: $block_code, reservation_statuses: $reservation_statuses, market_codes: $market_codes, channel_codes: $channel_codes, sub_channel_codes: $sub_channel_codes, room_types: $room_types, rate_plan_codes: $rate_plan_codes, labels: $labels, from: $from, to: $to, date_filter: $date_filter, exclude: $exclude, skip: $skip, top: $top, inlinecount: $inlinecount, app_id: $app_id, app_key: $app_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a new booking.
#
# POST /api/booking/v0/bookings
# Returns: record<_warnings: list<string>, confirmation_id: string, reservation_id: int>
# operationId: Bookings_CreateBooking
export def "bookings-create-booking" [
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
  --send-confirmation: oneof<nothing, bool> # Whether to send a confirmation email to the primary guest
  --app-id: string # Application identifier (required)
  --app-key: string # Application key. (required)
  --addons: list<string> # A list of addon service codes that should be booked for all reservations of this booking
  --adults: int # The number of adults per room (format: int32)
  --arrival-date: string # The arrival date of the guests (format: date-time)
  --channel-code: string # The channel code for this reservation. You can find available channels in the codes for the hotel.
  --comment: string # The comment you want to add for this reservation
  --company: record # shape: {company_id?: string}
  --contact: record # shape: {customer_id?: string}
  --departure-date: string # The departure date of the guests (format: date-time)
  --external-id: string # The external id for this reservation. You can put here your own id used by you or the external system you integrate hetras with
  --group-code: string # The group code based on which the reservation will be created.
  --guarantee: record # shape: {guarantee_type?: "PM4Hold"|"PM6Hold"|"GuaranteeToCreditCard"|"GuaranteeToGuestAccount"|"GuaranteeByTravelAgent"|"GuaranteeByCompany"|"Deposit"|"Voucher"|"Prepayment"|"NonGuaranteed"|"Tentative"|"Waitlist", token?: record}
  --guests: list # A list of guests with some basic guest details — item shape: {consent_subscribe?: list<string>, consent_unsubscribe?: list<string>, customer_id?: string, email?: string, first_name?: string, gender?: "Unspecified"|"Male"|"Female", last_name?: string, mailing_address?: record, nationality?: string, phone?: string, primary?: bool, title?: string}
  hotel_id: int # The id of the hotel this reservation is valid for (format: int32)
  --payment-method: string@payment-method-completer # The payment method for this reservation
  --prepay-discount: float # If you create a booking for a rateplan requiring prepayment this amount will be deducted from the booking value before the prepayment will be taken. This feature is useful when the booker redeems a gift voucher and you want to only capture the remaining amount from the guest´s credit card (format: double)
  --rate-plan: string # The rate plan code this reservation is related to
  --room-type: string # The room type code this reservation is related to
  --rooms: int # The number of rooms this reservation is for. After a multi-room booking is done there will be one reservation in hetras for all rooms. The hotel staff then will split this reservation into one reservation per room to be able to check in the guests (format: int32)
  --travel-agent: record # shape: {company_id?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/booking/v0/bookings"
    query: [{name: sendConfirmation, var: send_confirmation}]
    header: [{name: App-Id, var: app_id, required: true}, {name: App-Key, var: app_key, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: addons, var: addons}, {name: adults, var: adults}, {name: arrival_date, var: arrival_date}, {name: channel_code, var: channel_code}, {name: comment, var: comment}, {name: company, var: company}, {name: contact, var: contact}, {name: departure_date, var: departure_date}, {name: external_id, var: external_id}, {name: group_code, var: group_code}, {name: guarantee, var: guarantee}, {name: guests, var: guests}, {name: hotel_id, var: hotel_id}, {name: payment_method, var: payment_method}, {name: prepay_discount, var: prepay_discount}, {name: rate_plan, var: rate_plan}, {name: room_type, var: room_type}, {name: rooms, var: rooms}, {name: travel_agent, var: travel_agent}]}
    accept: ["application/json", "text/json"]
    ok: [201]
    auth: bearer
  } {
    send_confirmation: $send_confirmation, app_id: $app_id, app_key: $app_key, addons: $addons, adults: $adults, arrival_date: $arrival_date, channel_code: $channel_code, comment: $comment, company: $company, contact: $contact, departure_date: $departure_date, external_id: $external_id, group_code: $group_code, guarantee: $guarantee, guests: $guests, hotel_id: $hotel_id, payment_method: $payment_method, prepay_discount: $prepay_discount, rate_plan: $rate_plan, room_type: $room_type, rooms: $rooms, travel_agent: $travel_agent
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get total count of bookings matchung the given filter criteria.
#
# GET /api/booking/v0/bookings/$count
# Returns: record<_count: int>
# operationId: Bookings_GetBookingsCount
export def "bookings-get-bookings-count" [
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
  --hotel-id: int # Only return bookings for this specific hotel. (format: int32)
  --cancellation-id: string # Return bookings for this cancellation id.
  --reservation-number: int # Return bookings matching this reservation number. Please note that reservation numbers are only unique within a hotel. If you don´t specify a hotel filter at the same time you could get back multiple bookings from different hotels. (format: int32)
  --customer-name: string # Return all bookings where the first or lastname of one of the guests or the contact contains the specified value. The search is executed case insensitive and also stripping of any whitespaces.
  --customer-email: string # Return all bookings where the primary email address of one of the guests or the contact contains the specified value. The search is executed case insensitive and also stripping of any whitespaces.
  --customer-id: string # Return all bookings the id of one of the guests or the contact matches the specified value.
  --room-number: string # Return all bookings having the specified room number assigned.
  --external-id: string # Return all bookings exactly matching the specified external id. This filter is case sensitive.
  --company-name: string # Return all bookings where the name of the linked company or travel agent profile contains the specified value. The search is executed case insensitive and also stripping of any whitespaces.
  --company-id: string # Return all bookings the id of the company or travel agent profile matches the specified value.
  --company-email: string # Return all bookings where the primary email address of the company or the travel agent profile contains the specified value. The search is executed case insensitive and also stripping of any whitespaces.
  --block-code: string # Return all bookings where the block code matches the specified value.
  --reservation-statuses: list<string> # Return all bookings where the reservation status is one of the specified values.
  --market-codes: list<string> # Return all bookings where the market code is one of the specified values.
  --channel-codes: list<string> # Return all bookings where the channel code is one of the specified values.
  --sub-channel-codes: list<string> # Return all bookings where the subchannel code is one of the specified values.
  --room-types: list<string> # Return all bookings where the room type is one of the specified values.
  --rate-plan-codes: list<string> # Return all bookings where the rate plan code is one of the specified values.
  --labels: list<string> # Return all reservations with at least one of the specified labels.
  --from: string # Start date for the selected date filter. If you select arrival date as date filter the bookings returned will have at least one reservation arriving on the specified date or later. (format: date-time)
  --to: string # End date for the selected date filter. If you select arrival date as date filter the bookings returned will have at least one reservation arriving on the specified date or earlier. (format: date-time)
  --date-filter: string@date-filter-completer # Select a date field you want to filter bookings by. Only one filter at a time can be applied. The to and from dates will then define the time range.
  --exclude: string@exclude-completer # To be able to request reservations without personal data based on GDPR.
  --app-id: string # Application identifier (required)
  --app-key: string # Application key. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/booking/v0/bookings/$count"
    query: [{name: hotelId, var: hotel_id}, {name: cancellationId, var: cancellation_id}, {name: reservationNumber, var: reservation_number}, {name: customerName, var: customer_name}, {name: customerEmail, var: customer_email}, {name: customerId, var: customer_id}, {name: roomNumber, var: room_number}, {name: externalId, var: external_id}, {name: companyName, var: company_name}, {name: companyId, var: company_id}, {name: companyEmail, var: company_email}, {name: blockCode, var: block_code}, {name: reservationStatuses, var: reservation_statuses, style: csv}, {name: marketCodes, var: market_codes, style: csv}, {name: channelCodes, var: channel_codes, style: csv}, {name: subChannelCodes, var: sub_channel_codes, style: csv}, {name: roomTypes, var: room_types, style: csv}, {name: ratePlanCodes, var: rate_plan_codes, style: csv}, {name: labels, var: labels, style: csv}, {name: from, var: from}, {name: to, var: to}, {name: dateFilter, var: date_filter}, {name: exclude, var: exclude}]
    header: [{name: App-Id, var: app_id, required: true}, {name: App-Key, var: app_key, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    hotel_id: $hotel_id, cancellation_id: $cancellation_id, reservation_number: $reservation_number, customer_name: $customer_name, customer_email: $customer_email, customer_id: $customer_id, room_number: $room_number, external_id: $external_id, company_name: $company_name, company_id: $company_id, company_email: $company_email, block_code: $block_code, reservation_statuses: $reservation_statuses, market_codes: $market_codes, channel_codes: $channel_codes, sub_channel_codes: $sub_channel_codes, room_types: $room_types, rate_plan_codes: $rate_plan_codes, labels: $labels, from: $from, to: $to, date_filter: $date_filter, exclude: $exclude, app_id: $app_id, app_key: $app_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Load all reservations for one booking by confirmation id.
#
# GET /api/booking/v0/bookings/{confirmationId}
# Returns: record<reservations: table<_warnings: list, addon_services: list, adults: int, arrival_date: string, balance: float, block: record, cancellation_id: string, cancellation_policies: list, channel_code: string, checkin_time: string, checkout_time: string, comment: string, company: record, confirmation_id: string, contact: record, created: string, currency: string, departure_date: string, external_id: string, general_policies: list, guarantee: record, guests: list, hotel_id: int, labels: list, market_code: string, noshow_policy: record, payment_method: string, rate_plan: record, reservation_number: int, reservation_status: string, room: record, room_rates: list, rooms: int, services: list, subchannel_code: string, total_stay: record, updated: string>>
# operationId: Bookings_GetBooking
export def "bookings-get-booking" [
  confirmation_id: string
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
  --expand: string@expand-completer-2 # Specifies the expand type.
  --exclude: string@exclude-completer-1 # Specifies the exclude type.
  --app-id: string # Application identifier (required)
  --app-key: string # Application key. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/booking/v0/bookings/{confirmationId}"
    path_params: [{name: confirmationId, var: confirmation_id}]
    query: [{name: expand, var: expand}, {name: exclude, var: exclude}]
    header: [{name: App-Id, var: app_id, required: true}, {name: App-Key, var: app_key, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    confirmation_id: $confirmation_id, expand: $expand, exclude: $exclude, app_id: $app_id, app_key: $app_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Load a specific reservation from a booking.
#
# GET /api/booking/v0/bookings/{confirmationId}/reservations/{reservationNumber}
# Returns: record<_warnings: list<string>, addon_services: list<string>, adults: int, arrival_date: string, balance: float, block: record<_links: record, code: string, name: string>, cancellation_id: string, cancellation_policies: table<description: string, fee: float, fee_date: string>, channel_code: string, checkin_time: string, checkout_time: string, comment: string, company: record<company_id: string>, confirmation_id: string, contact: record<_links: record, customer_id: string>, created: string, currency: string, departure_date: string, external_id: string, general_policies: table<description: string, name: string>, guarantee: record<guarantee_type: string, valid_token: bool>, guests: table<_links: record, customer_id: string, email: string, first_name: string, gender: string, last_name: string, mailing_address: record, nationality: string, phone: string, primary: bool, subscribed_consents: list, title: string>, hotel_id: int, labels: list<string>, market_code: string, noshow_policy: record<description: string, fee: float>, payment_method: string, rate_plan: record<code: string, description: string, name: string>, reservation_number: int, reservation_status: string, room: record<_links: record, description: string, name: string, number: string, room_type: record<_links: record, code: string, description: string, name: string>>, room_rates: table<addon_services: list, date: string, excluded_tax: float, included_services: list, included_tax: float, rate: float, room_type: string>, rooms: int, services: table<code: string, description: string, frequency: string, is_addon: bool, name: string>, subchannel_code: string, total_stay: record<addon_services: list<record>, excluded_tax: float, included_services: list<string>, included_tax: float, rate: float>, updated: string>
# operationId: Bookings_GetReservation
export def "bookings-get-reservation" [
  confirmation_id: string
  reservation_number: int
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
  --expand: string@expand-completer-2 # Specifies the expand type.
  --exclude: string@exclude-completer-1 # Specifies the exclude type.
  --app-id: string # Application identifier (required)
  --app-key: string # Application key. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/booking/v0/bookings/{confirmationId}/reservations/{reservationNumber}"
    path_params: [{name: confirmationId, var: confirmation_id}, {name: reservationNumber, var: reservation_number}]
    query: [{name: expand, var: expand}, {name: exclude, var: exclude}]
    header: [{name: App-Id, var: app_id, required: true}, {name: App-Key, var: app_key, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    confirmation_id: $confirmation_id, reservation_number: $reservation_number, expand: $expand, exclude: $exclude, app_id: $app_id, app_key: $app_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Partially updates a reservation.
#
# PATCH /api/booking/v0/bookings/{confirmationId}/reservations/{reservationNumber}
# Returns: record
# operationId: Bookings_Patch
export def "bookings-patch" [
  confirmation_id: string
  reservation_number: int
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
  --app-id: string # Application identifier (required)
  --app-key: string # Application key. (required)
  --body: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/api/booking/v0/bookings/{confirmationId}/reservations/{reservationNumber}"
    path_params: [{name: confirmationId, var: confirmation_id}, {name: reservationNumber, var: reservation_number}]
    header: [{name: App-Id, var: app_id, required: true}, {name: App-Key, var: app_key, required: true}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    confirmation_id: $confirmation_id, reservation_number: $reservation_number, app_id: $app_id, app_key: $app_key, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Assign a room to a reservation.
#
# POST /api/booking/v0/bookings/{confirmationId}/reservations/{reservationNumber}/assign_room
# Returns: record<_warnings: list<string>, room_number: string>
# operationId: Bookings_PostRoomAssignment
export def "bookings-post-room-assignment" [
  confirmation_id: string
  reservation_number: int
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
  --app-id: string # Application identifier (required)
  --app-key: string # Application key. (required)
  --amenities: list<string> # Ensure the assigned room will have all the amenities specified. You can provide a comma seperated list of amenity codes.
  --condition: string@condition-completer # Here you can define to limit the list of assignable rooms based on their current condition. This is only applicable if the underlying reservation is due to arrive on the current business day. If not set by default only clean rooms will be assigned.
  --include-out-of-service: oneof<nothing, bool> # Sometimes you might want to assign rooms which are out of service (small repair needed) if no other rooms are available anymore. If you set include_out_of_service to true even those rooms will be considered. The default is false.
  --locations: list<string> # Ensure the assigned room will have at least one of the specified locations. You can provide a comma seperated list of location codes.
  --respect-guest-preferences: oneof<nothing, bool> # Defines if the preferences for locations, amenities and views of the primary guest should be taken into account. All defined preferences in the guest profile override any of the criteria defined in the request body. The default is false.
  --room-number: string # If you define a specific room number this room will be assigned if not assigned to another reservation, has proper room type and is not OutOfOrder or OutOfInventory for the stay duration of the underlying reservaton. If set all other filter criteria will be ignored.
  --views: list<string> # Ensure the assigned room will have at least one of the specified views. You can provide a comma seperated list of view codes.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/booking/v0/bookings/{confirmationId}/reservations/{reservationNumber}/assign_room"
    path_params: [{name: confirmationId, var: confirmation_id}, {name: reservationNumber, var: reservation_number}]
    header: [{name: App-Id, var: app_id, required: true}, {name: App-Key, var: app_key, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: amenities, var: amenities}, {name: condition, var: condition}, {name: include_out_of_service, var: include_out_of_service}, {name: locations, var: locations}, {name: respect_guest_preferences, var: respect_guest_preferences}, {name: room_number, var: room_number}, {name: views, var: views}]}
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    confirmation_id: $confirmation_id, reservation_number: $reservation_number, app_id: $app_id, app_key: $app_key, amenities: $amenities, condition: $condition, include_out_of_service: $include_out_of_service, locations: $locations, respect_guest_preferences: $respect_guest_preferences, room_number: $room_number, views: $views
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Cancel one reservation.
#
# POST /api/booking/v0/bookings/{confirmationId}/reservations/{reservationNumber}/cancel
# Returns: record<_warnings: list<string>, balance: float, cancellation_fee: float, cancellation_id: string>
# operationId: Bookings_CancelReservation
export def "bookings-cancel-reservation" [
  confirmation_id: string
  reservation_number: int
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
  --send-confirmation: oneof<nothing, bool> # Whether to send a confirmation email to the primary guest
  --app-id: string # Application identifier (required)
  --app-key: string # Application key. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/api/booking/v0/bookings/{confirmationId}/reservations/{reservationNumber}/cancel"
    path_params: [{name: confirmationId, var: confirmation_id}, {name: reservationNumber, var: reservation_number}]
    query: [{name: sendConfirmation, var: send_confirmation}]
    header: [{name: App-Id, var: app_id, required: true}, {name: App-Key, var: app_key, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    confirmation_id: $confirmation_id, reservation_number: $reservation_number, send_confirmation: $send_confirmation, app_id: $app_id, app_key: $app_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Performs a check in operation for a reservation.
#
# POST /api/booking/v0/bookings/{confirmationId}/reservations/{reservationNumber}/check_in
# Returns: record<_warnings: list<string>>
# operationId: Bookings_CheckIn
export def "bookings-check-in" [
  confirmation_id: string
  reservation_number: int
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
  --app-id: string # Application identifier (required)
  --app-key: string # Application key. (required)
  --client-identity: string # Client identity
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/booking/v0/bookings/{confirmationId}/reservations/{reservationNumber}/check_in"
    path_params: [{name: confirmationId, var: confirmation_id}, {name: reservationNumber, var: reservation_number}]
    header: [{name: App-Id, var: app_id, required: true}, {name: App-Key, var: app_key, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: client_identity, var: client_identity}]}
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    confirmation_id: $confirmation_id, reservation_number: $reservation_number, app_id: $app_id, app_key: $app_key, client_identity: $client_identity
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Performs a check out operation for a reservation.
#
# POST /api/booking/v0/bookings/{confirmationId}/reservations/{reservationNumber}/check_out
# Returns: record<_warnings: list<string>>
# operationId: Bookings_CheckOut
export def "bookings-check-out" [
  confirmation_id: string
  reservation_number: int
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
  --app-id: string # Application identifier (required)
  --app-key: string # Application key. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/api/booking/v0/bookings/{confirmationId}/reservations/{reservationNumber}/check_out"
    path_params: [{name: confirmationId, var: confirmation_id}, {name: reservationNumber, var: reservation_number}]
    header: [{name: App-Id, var: app_id, required: true}, {name: App-Key, var: app_key, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    confirmation_id: $confirmation_id, reservation_number: $reservation_number, app_id: $app_id, app_key: $app_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Post a payment token for a reservation.
#
# PUT /api/booking/v0/bookings/{confirmationId}/reservations/{reservationNumber}/payment_token
# Returns: record<_warnings: list<string>>
# operationId: Bookings_PaymentToken
export def "bookings-payment-token" [
  confirmation_id: string
  reservation_number: int
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
  --app-id: string # Application identifier (required)
  --app-key: string # Application key. (required)
  --authorization: record # shape: {amount?: float, expiry_date?: string, merchant_reference: string, reference: string, shopper_reference: string}
  --no-authorization-required: oneof<nothing, bool> # Whether hetras should skip authorization using the provided token when no authorization details are supplied. Optional flag, defaults to false.
  payment_token: string # The token you get from the payment service provider
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/booking/v0/bookings/{confirmationId}/reservations/{reservationNumber}/payment_token"
    path_params: [{name: confirmationId, var: confirmation_id}, {name: reservationNumber, var: reservation_number}]
    header: [{name: App-Id, var: app_id, required: true}, {name: App-Key, var: app_key, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: authorization, var: authorization}, {name: no_authorization_required, var: no_authorization_required}, {name: payment_token, var: payment_token}]}
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    confirmation_id: $confirmation_id, reservation_number: $reservation_number, app_id: $app_id, app_key: $app_key, authorization: $authorization, no_authorization_required: $no_authorization_required, payment_token: $payment_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Performs a chip and pin credit card authorization for a reservation.
#
# POST /api/booking/v0/bookings/{confirmationId}/reservations/{reservationNumber}/pre_authorize
# Returns: record<_warnings: list<string>>
# operationId: Bookings_TerminalAuthorization
export def "bookings-terminal-authorization" [
  confirmation_id: string
  reservation_number: int
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
  --app-id: string # Application identifier (required)
  --app-key: string # Application key. (required)
  --amount-to-authorize: float # The amount to authorize (format: double)
  --client-identity: string # Client identity
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/booking/v0/bookings/{confirmationId}/reservations/{reservationNumber}/pre_authorize"
    path_params: [{name: confirmationId, var: confirmation_id}, {name: reservationNumber, var: reservation_number}]
    header: [{name: App-Id, var: app_id, required: true}, {name: App-Key, var: app_key, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: amount_to_authorize, var: amount_to_authorize}, {name: client_identity, var: client_identity}]}
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    confirmation_id: $confirmation_id, reservation_number: $reservation_number, app_id: $app_id, app_key: $app_key, amount_to_authorize: $amount_to_authorize, client_identity: $client_identity
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a list of daily rates given a hotel Id, a channel code and a date range.
#
# GET /api/booking/v0/daily_rates
# Returns: record<_count: int, _links: record, daily_rates: table<business_day: string, offers: list>, hotel: record<_links: record, code: string, id: int, name: string>, policies: record<cancellation_policies: list<record>, guarantee_types: list<record>, noshow_policies: list<record>>, rateplans: table<_links: record, code: string, currency: string, name: string>, room_types: table<_links: record, code: string, name: string>>
# operationId: DailyRates_GetDailyRates
export def "daily-rates-get-daily-rates" [
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
  --hotel-id: int # Define the hotel id to request the availability for. (required, format: int32)
  --from: string # Define the first business day you would like to get availability numbers for. The day should not be in the past. (required, format: date-time)
  --to: string # Define the last business day you would like to get rates for (inclusive). The maximum time span between 'From' and 'To' is limited to 365 days. This can't be less than the 'From' date. (required, format: date-time)
  --channel-code: string # Define the channel code in order to look up the rates for. (required)
  --expand: list<string> # Define the sections you want to expand and get informed about rates for.
  --rate-plan-codes: list<string> # Define the codes of rate plans to show in the response. A list of comma ',' separated rate plan codes.
  --skip: int # Amount of items to skip. (format: int32)
  --top: int # Amount of items to select. (format: int32)
  --inlinecount: string@inlinecount-completer # Return total number of items for a given filter criteria.
  --app-id: string # Application identifier (required)
  --app-key: string # Application key. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/booking/v0/daily_rates"
    query: [{name: hotelId, var: hotel_id, required: true}, {name: from, var: from, required: true}, {name: to, var: to, required: true}, {name: channelCode, var: channel_code, required: true}, {name: expand, var: expand, style: csv}, {name: ratePlanCodes, var: rate_plan_codes, style: csv}, {name: skip, var: skip}, {name: top, var: top}, {name: inlinecount, var: inlinecount}]
    header: [{name: App-Id, var: app_id, required: true}, {name: App-Key, var: app_key, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200, 204]
    auth: bearer
  } {
    hotel_id: $hotel_id, from: $from, to: $to, channel_code: $channel_code, expand: $expand, rate_plan_codes: $rate_plan_codes, skip: $skip, top: $top, inlinecount: $inlinecount, app_id: $app_id, app_key: $app_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a list of room offers for the specified guest stay details.
#
# GET /api/booking/v0/rates
# Returns: record<arrival_date: string, departure_date: string, hotel_id: int, hotel_name: string, rate_plans: table<code: string, description: string, name: string>, room_offers: table<offers: list, room_type: string>, rooms: table<description: string, name: string, room_number: int, type: string>, services: table<code: string, description: string, frequency: string, is_addon: bool, name: string>>
# operationId: Rates_Get
export def "rates-get" [
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
  --hotel-id: int # Specifies the hotel id to request offers for. (required, format: int32)
  --arrival-date: string # Date of arrival for the guest in the ISO-8601 format "YYYY-MM-DD". (required, format: date-time)
  --departure-date: string # Date of departure for the guest in the ISO-8601 format "YYYY-MM-DD". (required, format: date-time)
  --channel-code: string # Channel Code the rate plan needs to be configured for. (required)
  --adults: string # Number of adults per room. (required, format: byte)
  --rooms: string # Number of rooms (default is 1). (format: byte)
  --room-type: string # Only return offers with rates for the specified room type code.
  --rate-plan-code: string # Only return offers for the specified room type code.
  --group-code: string # Only return offers for the specified group code.
  --expand: string@expand-completer # Expand the rates breakdown if required.
  --app-id: string # Application identifier (required)
  --app-key: string # Application key. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/booking/v0/rates"
    query: [{name: hotelId, var: hotel_id, required: true}, {name: arrivalDate, var: arrival_date, required: true}, {name: departureDate, var: departure_date, required: true}, {name: channelCode, var: channel_code, required: true}, {name: adults, var: adults, required: true}, {name: rooms, var: rooms}, {name: roomType, var: room_type}, {name: ratePlanCode, var: rate_plan_code}, {name: groupCode, var: group_code}, {name: expand, var: expand}]
    header: [{name: App-Id, var: app_id, required: true}, {name: App-Key, var: app_key, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    hotel_id: $hotel_id, arrival_date: $arrival_date, departure_date: $departure_date, channel_code: $channel_code, adults: $adults, rooms: $rooms, room_type: $room_type, rate_plan_code: $rate_plan_code, group_code: $group_code, expand: $expand, app_id: $app_id, app_key: $app_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}
