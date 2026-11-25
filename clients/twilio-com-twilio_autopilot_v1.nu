# Auto-generated client for Twilio - Autopilot v1.42.0
# Source: https://api.apis.guru/v2/specs/twilio.com/twilio_autopilot_v1/1.42.0/openapi.json
# Auth: --token flag or $env.TWILIO_AUTOPILOT_TOKEN

const CLIENT = {
  base_url: "https://autopilot.twilio.com"
  token_env_var: "TWILIO_AUTOPILOT_TOKEN"
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

def base-url-completer [] { ["https://autopilot.twilio.com"] }
def auth-scheme-completer [] { ["basic" "basic-credentials"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    list-assistant: "record<assistants: table<account_sid: string, callback_events: string, callback_url: string, date_created: string, date_updated: string, development_stage: string, friendly_name: string, latest_model_build_sid: string, links: record, log_queries: bool, needs_model_build: bool, sid: string, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    create-assistant: "record<account_sid: string, callback_events: string, callback_url: string, date_created: string, date_updated: string, development_stage: string, friendly_name: string, latest_model_build_sid: string, links: record, log_queries: bool, needs_model_build: bool, sid: string, unique_name: string, url: string>"
    update-restore-assistant: "record<account_sid: string, callback_events: string, callback_url: string, date_created: string, date_updated: string, development_stage: string, friendly_name: string, latest_model_build_sid: string, log_queries: bool, needs_model_build: bool, sid: string, unique_name: string>"
    fetch-defaults: "record<account_sid: string, assistant_sid: string, data: any, url: string>"
    update-defaults: "record<account_sid: string, assistant_sid: string, data: any, url: string>"
    fetch-dialogue: "record<account_sid: string, assistant_sid: string, data: any, sid: string, url: string>"
    list-field-type: "record<field_types: table<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    create-field-type: "record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string>"
    list-field-value: "record<field_values: table<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, field_type_sid: string, language: string, sid: string, synonym_of: string, url: string, value: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    create-field-value: "record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, field_type_sid: string, language: string, sid: string, synonym_of: string, url: string, value: string>"
    fetch-field-value: "record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, field_type_sid: string, language: string, sid: string, synonym_of: string, url: string, value: string>"
    fetch-field-type: "record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string>"
    update-field-type: "record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string>"
    list-model-build: "record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, model_builds: table<account_sid: string, assistant_sid: string, build_duration: int, date_created: string, date_updated: string, error_code: int, sid: string, status: string, unique_name: string, url: string>>"
    create-model-build: "record<account_sid: string, assistant_sid: string, build_duration: int, date_created: string, date_updated: string, error_code: int, sid: string, status: string, unique_name: string, url: string>"
    fetch-model-build: "record<account_sid: string, assistant_sid: string, build_duration: int, date_created: string, date_updated: string, error_code: int, sid: string, status: string, unique_name: string, url: string>"
    update-model-build: "record<account_sid: string, assistant_sid: string, build_duration: int, date_created: string, date_updated: string, error_code: int, sid: string, status: string, unique_name: string, url: string>"
    list-query: "record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, queries: table<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, dialogue_sid: string, language: string, model_build_sid: string, query: string, results: any, sample_sid: string, sid: string, source_channel: string, status: string, url: string>>"
    create-query: "record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, dialogue_sid: string, language: string, model_build_sid: string, query: string, results: any, sample_sid: string, sid: string, source_channel: string, status: string, url: string>"
    fetch-query: "record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, dialogue_sid: string, language: string, model_build_sid: string, query: string, results: any, sample_sid: string, sid: string, source_channel: string, status: string, url: string>"
    update-query: "record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, dialogue_sid: string, language: string, model_build_sid: string, query: string, results: any, sample_sid: string, sid: string, source_channel: string, status: string, url: string>"
    fetch-style-sheet: "record<account_sid: string, assistant_sid: string, data: any, url: string>"
    update-style-sheet: "record<account_sid: string, assistant_sid: string, data: any, url: string>"
    list-task: "record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, tasks: table<account_sid: string, actions_url: string, assistant_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string>>"
    create-task: "record<account_sid: string, actions_url: string, assistant_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string>"
    fetch-task: "record<account_sid: string, actions_url: string, assistant_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string>"
    update-task: "record<account_sid: string, actions_url: string, assistant_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string>"
    fetch-task-actions: "record<account_sid: string, assistant_sid: string, data: any, task_sid: string, url: string>"
    update-task-actions: "record<account_sid: string, assistant_sid: string, data: any, task_sid: string, url: string>"
    list-field: "record<fields: table<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, field_type: string, sid: string, task_sid: string, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    create-field: "record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, field_type: string, sid: string, task_sid: string, unique_name: string, url: string>"
    fetch-field: "record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, field_type: string, sid: string, task_sid: string, unique_name: string, url: string>"
    list-sample: "record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, samples: table<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, language: string, sid: string, source_channel: string, tagged_text: string, task_sid: string, url: string>>"
    create-sample: "record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, language: string, sid: string, source_channel: string, tagged_text: string, task_sid: string, url: string>"
    fetch-sample: "record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, language: string, sid: string, source_channel: string, tagged_text: string, task_sid: string, url: string>"
    update-sample: "record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, language: string, sid: string, source_channel: string, tagged_text: string, task_sid: string, url: string>"
    fetch-task-statistics: "record<account_sid: string, assistant_sid: string, fields_count: int, samples_count: int, task_sid: string, url: string>"
    list-webhook: "record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, webhooks: table<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, events: string, sid: string, unique_name: string, url: string, webhook_method: string, webhook_url: string>>"
    create-webhook: "record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, events: string, sid: string, unique_name: string, url: string, webhook_method: string, webhook_url: string>"
    fetch-webhook: "record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, events: string, sid: string, unique_name: string, url: string, webhook_method: string, webhook_url: string>"
    update-webhook: "record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, events: string, sid: string, unique_name: string, url: string, webhook_method: string, webhook_url: string>"
    fetch-assistant: "record<account_sid: string, callback_events: string, callback_url: string, date_created: string, date_updated: string, development_stage: string, friendly_name: string, latest_model_build_sid: string, links: record, log_queries: bool, needs_model_build: bool, sid: string, unique_name: string, url: string>"
    update-assistant: "record<account_sid: string, callback_events: string, callback_url: string, date_created: string, date_updated: string, development_stage: string, friendly_name: string, latest_model_build_sid: string, links: record, log_queries: bool, needs_model_build: bool, sid: string, unique_name: string, url: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["list-assistant" "create-assistant" "update-restore-assistant" "fetch-defaults" "update-defaults" "fetch-dialogue" "list-field-type" "create-field-type" "list-field-value" "create-field-value" "delete-field-value" "fetch-field-value" "delete-field-type" "fetch-field-type" "update-field-type" "list-model-build" "create-model-build" "delete-model-build" "fetch-model-build" "update-model-build" "list-query" "create-query" "delete-query" "fetch-query" "update-query" "fetch-style-sheet" "update-style-sheet" "list-task" "create-task" "delete-task" "fetch-task" "update-task" "fetch-task-actions" "update-task-actions" "list-field" "create-field" "delete-field" "fetch-field" "list-sample" "create-sample" "delete-sample" "fetch-sample" "update-sample" "fetch-task-statistics" "list-webhook" "create-webhook" "delete-webhook" "fetch-webhook" "update-webhook" "delete-assistant" "fetch-assistant" "update-assistant" "commands"] | sort) } | get name | first)
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

# GET /v1/Assistants
#
# Returns: record<assistants: table<account_sid: string, callback_events: string, callback_url: string, date_created: string, date_updated: string, development_stage: string, friendly_name: string, latest_model_build_sid: string, links: record, log_queries: bool, needs_model_build: bool, sid: string, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListAssistant
export def "list-assistant" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/Assistants"
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://autopilot.twilio.com"
    auth: basic
  } {
    page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Assistants
#
# Returns: record<account_sid: string, callback_events: string, callback_url: string, date_created: string, date_updated: string, development_stage: string, friendly_name: string, latest_model_build_sid: string, links: record, log_queries: bool, needs_model_build: bool, sid: string, unique_name: string, url: string>
# operationId: CreateAssistant
export def "create-assistant" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --callback-events: string # Reserved.
  --callback-url: string # Reserved. (format: uri)
  --defaults: any # A JSON object that defines the Assistant's [default tasks](https://www.twilio.com/docs/autopilot/api/assistant/defaults) for various scenarios, including initiation actions and fallback tasks.
  --friendly-name: string # A descriptive string that you create to describe the new resource. It is not unique and can be up to 255 characters long.
  --log-queries: oneof<nothing, bool> # Whether queries should be logged and kept after training. Can be: `true` or `false` and defaults to `true`. If `true`, queries are stored for 30 days, and then deleted. If `false`, no queries are stored.
  --style-sheet: any # The JSON string that defines the Assistant's [style sheet](https://www.twilio.com/docs/autopilot/api/assistant/stylesheet)
  --unique-name: string # An application-defined string that uniquely identifies the new resource. It can be used as an alternative to the `sid` in the URL path to address the resource. The first 64 characters must be unique.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Assistants"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: CallbackEvents, var: callback_events}, {name: CallbackUrl, var: callback_url}, {name: Defaults, var: defaults}, {name: FriendlyName, var: friendly_name}, {name: LogQueries, var: log_queries}, {name: StyleSheet, var: style_sheet}, {name: UniqueName, var: unique_name}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://autopilot.twilio.com"
    auth: basic
  } {
    callback_events: $callback_events, callback_url: $callback_url, defaults: $defaults, friendly_name: $friendly_name, log_queries: $log_queries, style_sheet: $style_sheet, unique_name: $unique_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Assistants/Restore
#
# Returns: record<account_sid: string, callback_events: string, callback_url: string, date_created: string, date_updated: string, development_stage: string, friendly_name: string, latest_model_build_sid: string, log_queries: bool, needs_model_build: bool, sid: string, unique_name: string>
# operationId: UpdateRestoreAssistant
export def "update-restore-assistant" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assistant: string # The Twilio-provided string that uniquely identifies the Assistant resource to restore.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Assistants/Restore"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Assistant, var: assistant}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://autopilot.twilio.com"
    auth: basic
  } {
    assistant: $assistant
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Assistants/{AssistantSid}/Defaults
#
# Returns: record<account_sid: string, assistant_sid: string, data: any, url: string>
# operationId: FetchDefaults
export def "fetch-defaults" [
  assistant_sid: string
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
    path: "/v1/Assistants/{AssistantSid}/Defaults"
    path_params: [{name: AssistantSid, var: assistant_sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://autopilot.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Assistants/{AssistantSid}/Defaults
#
# Returns: record<account_sid: string, assistant_sid: string, data: any, url: string>
# operationId: UpdateDefaults
export def "update-defaults" [
  assistant_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --defaults: any # A JSON string that describes the default task links for the `assistant_initiation`, `collect`, and `fallback` situations.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Assistants/{AssistantSid}/Defaults"
    path_params: [{name: AssistantSid, var: assistant_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Defaults, var: defaults}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://autopilot.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, defaults: $defaults
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Assistants/{AssistantSid}/Dialogues/{Sid}
#
# Returns: record<account_sid: string, assistant_sid: string, data: any, sid: string, url: string>
# operationId: FetchDialogue
export def "fetch-dialogue" [
  assistant_sid: string
  sid: string
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
    path: "/v1/Assistants/{AssistantSid}/Dialogues/{Sid}"
    path_params: [{name: AssistantSid, var: assistant_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://autopilot.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Assistants/{AssistantSid}/FieldTypes
#
# Returns: record<field_types: table<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListFieldType
export def "list-field-type" [
  assistant_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/Assistants/{AssistantSid}/FieldTypes"
    path_params: [{name: AssistantSid, var: assistant_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://autopilot.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Assistants/{AssistantSid}/FieldTypes
#
# Returns: record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string>
# operationId: CreateFieldType
export def "create-field-type" [
  assistant_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --friendly-name: string # A descriptive string that you create to describe the new resource. It is not unique and can be up to 255 characters long.
  unique_name: string # An application-defined string that uniquely identifies the new resource. It can be used as an alternative to the `sid` in the URL path to address the resource. The first 64 characters must be unique.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Assistants/{AssistantSid}/FieldTypes"
    path_params: [{name: AssistantSid, var: assistant_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: FriendlyName, var: friendly_name}, {name: UniqueName, var: unique_name}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://autopilot.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, friendly_name: $friendly_name, unique_name: $unique_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Assistants/{AssistantSid}/FieldTypes/{FieldTypeSid}/FieldValues
#
# Returns: record<field_values: table<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, field_type_sid: string, language: string, sid: string, synonym_of: string, url: string, value: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListFieldValue
export def "list-field-value" [
  assistant_sid: string
  field_type_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --language: string # The [ISO language-country](https://docs.oracle.com/cd/E13214_01/wli/docs92/xref/xqisocodes.html) tag that specifies the language of the value. Currently supported tags: `en-US`
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/Assistants/{AssistantSid}/FieldTypes/{FieldTypeSid}/FieldValues"
    path_params: [{name: AssistantSid, var: assistant_sid}, {name: FieldTypeSid, var: field_type_sid}]
    query: [{name: Language, var: language}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://autopilot.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, field_type_sid: $field_type_sid, language: $language, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Assistants/{AssistantSid}/FieldTypes/{FieldTypeSid}/FieldValues
#
# Returns: record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, field_type_sid: string, language: string, sid: string, synonym_of: string, url: string, value: string>
# operationId: CreateFieldValue
export def "create-field-value" [
  assistant_sid: string
  field_type_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  language: string # The [ISO language-country](https://docs.oracle.com/cd/E13214_01/wli/docs92/xref/xqisocodes.html) tag that specifies the language of the value. Currently supported tags: `en-US`
  --synonym-of: string # The string value that indicates which word the field value is a synonym of.
  value: string # The Field Value data.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Assistants/{AssistantSid}/FieldTypes/{FieldTypeSid}/FieldValues"
    path_params: [{name: AssistantSid, var: assistant_sid}, {name: FieldTypeSid, var: field_type_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Language, var: language}, {name: SynonymOf, var: synonym_of}, {name: Value, var: value}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://autopilot.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, field_type_sid: $field_type_sid, language: $language, synonym_of: $synonym_of, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/Assistants/{AssistantSid}/FieldTypes/{FieldTypeSid}/FieldValues/{Sid}
#
# operationId: DeleteFieldValue
export def "delete-field-value" [
  assistant_sid: string
  field_type_sid: string
  sid: string
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
    path: "/v1/Assistants/{AssistantSid}/FieldTypes/{FieldTypeSid}/FieldValues/{Sid}"
    path_params: [{name: AssistantSid, var: assistant_sid}, {name: FieldTypeSid, var: field_type_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://autopilot.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, field_type_sid: $field_type_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Assistants/{AssistantSid}/FieldTypes/{FieldTypeSid}/FieldValues/{Sid}
#
# Returns: record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, field_type_sid: string, language: string, sid: string, synonym_of: string, url: string, value: string>
# operationId: FetchFieldValue
export def "fetch-field-value" [
  assistant_sid: string
  field_type_sid: string
  sid: string
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
    path: "/v1/Assistants/{AssistantSid}/FieldTypes/{FieldTypeSid}/FieldValues/{Sid}"
    path_params: [{name: AssistantSid, var: assistant_sid}, {name: FieldTypeSid, var: field_type_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://autopilot.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, field_type_sid: $field_type_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/Assistants/{AssistantSid}/FieldTypes/{Sid}
#
# operationId: DeleteFieldType
export def "delete-field-type" [
  assistant_sid: string
  sid: string
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
    path: "/v1/Assistants/{AssistantSid}/FieldTypes/{Sid}"
    path_params: [{name: AssistantSid, var: assistant_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://autopilot.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Assistants/{AssistantSid}/FieldTypes/{Sid}
#
# Returns: record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string>
# operationId: FetchFieldType
export def "fetch-field-type" [
  assistant_sid: string
  sid: string
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
    path: "/v1/Assistants/{AssistantSid}/FieldTypes/{Sid}"
    path_params: [{name: AssistantSid, var: assistant_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://autopilot.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Assistants/{AssistantSid}/FieldTypes/{Sid}
#
# Returns: record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string>
# operationId: UpdateFieldType
export def "update-field-type" [
  assistant_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --friendly-name: string # A descriptive string that you create to describe the resource. It is not unique and can be up to 255 characters long.
  --unique-name: string # An application-defined string that uniquely identifies the resource. It can be used as an alternative to the `sid` in the URL path to address the resource. The first 64 characters must be unique.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Assistants/{AssistantSid}/FieldTypes/{Sid}"
    path_params: [{name: AssistantSid, var: assistant_sid}, {name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: FriendlyName, var: friendly_name}, {name: UniqueName, var: unique_name}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://autopilot.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, sid: $sid, friendly_name: $friendly_name, unique_name: $unique_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Assistants/{AssistantSid}/ModelBuilds
#
# Returns: record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, model_builds: table<account_sid: string, assistant_sid: string, build_duration: int, date_created: string, date_updated: string, error_code: int, sid: string, status: string, unique_name: string, url: string>>
# operationId: ListModelBuild
export def "list-model-build" [
  assistant_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/Assistants/{AssistantSid}/ModelBuilds"
    path_params: [{name: AssistantSid, var: assistant_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://autopilot.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Assistants/{AssistantSid}/ModelBuilds
#
# Returns: record<account_sid: string, assistant_sid: string, build_duration: int, date_created: string, date_updated: string, error_code: int, sid: string, status: string, unique_name: string, url: string>
# operationId: CreateModelBuild
export def "create-model-build" [
  assistant_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status-callback: string # The URL we should call using a POST method to send status information to your application. (format: uri)
  --unique-name: string # An application-defined string that uniquely identifies the new resource. This value must be a unique string of no more than 64 characters. It can be used as an alternative to the `sid` in the URL path to address the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Assistants/{AssistantSid}/ModelBuilds"
    path_params: [{name: AssistantSid, var: assistant_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: StatusCallback, var: status_callback}, {name: UniqueName, var: unique_name}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://autopilot.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, status_callback: $status_callback, unique_name: $unique_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/Assistants/{AssistantSid}/ModelBuilds/{Sid}
#
# operationId: DeleteModelBuild
export def "delete-model-build" [
  assistant_sid: string
  sid: string
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
    path: "/v1/Assistants/{AssistantSid}/ModelBuilds/{Sid}"
    path_params: [{name: AssistantSid, var: assistant_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://autopilot.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Assistants/{AssistantSid}/ModelBuilds/{Sid}
#
# Returns: record<account_sid: string, assistant_sid: string, build_duration: int, date_created: string, date_updated: string, error_code: int, sid: string, status: string, unique_name: string, url: string>
# operationId: FetchModelBuild
export def "fetch-model-build" [
  assistant_sid: string
  sid: string
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
    path: "/v1/Assistants/{AssistantSid}/ModelBuilds/{Sid}"
    path_params: [{name: AssistantSid, var: assistant_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://autopilot.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Assistants/{AssistantSid}/ModelBuilds/{Sid}
#
# Returns: record<account_sid: string, assistant_sid: string, build_duration: int, date_created: string, date_updated: string, error_code: int, sid: string, status: string, unique_name: string, url: string>
# operationId: UpdateModelBuild
export def "update-model-build" [
  assistant_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --unique-name: string # An application-defined string that uniquely identifies the resource. This value must be a unique string of no more than 64 characters. It can be used as an alternative to the `sid` in the URL path to address the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Assistants/{AssistantSid}/ModelBuilds/{Sid}"
    path_params: [{name: AssistantSid, var: assistant_sid}, {name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: UniqueName, var: unique_name}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://autopilot.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, sid: $sid, unique_name: $unique_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Assistants/{AssistantSid}/Queries
#
# Returns: record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, queries: table<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, dialogue_sid: string, language: string, model_build_sid: string, query: string, results: any, sample_sid: string, sid: string, source_channel: string, status: string, url: string>>
# operationId: ListQuery
export def "list-query" [
  assistant_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --language: string # The [ISO language-country](https://docs.oracle.com/cd/E13214_01/wli/docs92/xref/xqisocodes.html) string that specifies the language used by the Query resources to read. For example: `en-US`.
  --model-build: string # The SID or unique name of the [Model Build](https://www.twilio.com/docs/autopilot/api/model-build) to be queried.
  --status: string # The status of the resources to read. Can be: `pending-review`, `reviewed`, or `discarded`
  --dialogue-sid: string # The SID of the [Dialogue](https://www.twilio.com/docs/autopilot/api/dialogue).
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/Assistants/{AssistantSid}/Queries"
    path_params: [{name: AssistantSid, var: assistant_sid}]
    query: [{name: Language, var: language}, {name: ModelBuild, var: model_build}, {name: Status, var: status}, {name: DialogueSid, var: dialogue_sid}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://autopilot.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, language: $language, model_build: $model_build, status: $status, dialogue_sid: $dialogue_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Assistants/{AssistantSid}/Queries
#
# Returns: record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, dialogue_sid: string, language: string, model_build_sid: string, query: string, results: any, sample_sid: string, sid: string, source_channel: string, status: string, url: string>
# operationId: CreateQuery
export def "create-query" [
  assistant_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  language: string # The [ISO language-country](https://docs.oracle.com/cd/E13214_01/wli/docs92/xref/xqisocodes.html) string that specifies the language used for the new query. For example: `en-US`.
  --model-build: string # The SID or unique name of the [Model Build](https://www.twilio.com/docs/autopilot/api/model-build) to be queried.
  query: string # The end-user's natural language input. It can be up to 2048 characters long.
  --tasks: string # The list of tasks to limit the new query to. Tasks are expressed as a comma-separated list of task `unique_name` values. For example, `task-unique_name-1, task-unique_name-2`. Listing specific tasks is useful to constrain the paths that a user can take.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Assistants/{AssistantSid}/Queries"
    path_params: [{name: AssistantSid, var: assistant_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Language, var: language}, {name: ModelBuild, var: model_build}, {name: Query, var: query}, {name: Tasks, var: tasks}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://autopilot.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, language: $language, model_build: $model_build, query: $query, tasks: $tasks
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/Assistants/{AssistantSid}/Queries/{Sid}
#
# operationId: DeleteQuery
export def "delete-query" [
  assistant_sid: string
  sid: string
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
    path: "/v1/Assistants/{AssistantSid}/Queries/{Sid}"
    path_params: [{name: AssistantSid, var: assistant_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://autopilot.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Assistants/{AssistantSid}/Queries/{Sid}
#
# Returns: record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, dialogue_sid: string, language: string, model_build_sid: string, query: string, results: any, sample_sid: string, sid: string, source_channel: string, status: string, url: string>
# operationId: FetchQuery
export def "fetch-query" [
  assistant_sid: string
  sid: string
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
    path: "/v1/Assistants/{AssistantSid}/Queries/{Sid}"
    path_params: [{name: AssistantSid, var: assistant_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://autopilot.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Assistants/{AssistantSid}/Queries/{Sid}
#
# Returns: record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, dialogue_sid: string, language: string, model_build_sid: string, query: string, results: any, sample_sid: string, sid: string, source_channel: string, status: string, url: string>
# operationId: UpdateQuery
export def "update-query" [
  assistant_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sample-sid: string # The SID of an optional reference to the [Sample](https://www.twilio.com/docs/autopilot/api/task-sample) created from the query.
  --status: string # The new status of the resource. Can be: `pending-review`, `reviewed`, or `discarded`
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Assistants/{AssistantSid}/Queries/{Sid}"
    path_params: [{name: AssistantSid, var: assistant_sid}, {name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: SampleSid, var: sample_sid}, {name: Status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://autopilot.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, sid: $sid, sample_sid: $sample_sid, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns Style sheet JSON object for the Assistant
#
# GET /v1/Assistants/{AssistantSid}/StyleSheet
# Returns: record<account_sid: string, assistant_sid: string, data: any, url: string>
# operationId: FetchStyleSheet
export def "fetch-style-sheet" [
  assistant_sid: string
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
    path: "/v1/Assistants/{AssistantSid}/StyleSheet"
    path_params: [{name: AssistantSid, var: assistant_sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://autopilot.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the style sheet for an Assistant identified by `assistant_sid`.
#
# POST /v1/Assistants/{AssistantSid}/StyleSheet
# Returns: record<account_sid: string, assistant_sid: string, data: any, url: string>
# operationId: UpdateStyleSheet
export def "update-style-sheet" [
  assistant_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --style-sheet: any # The JSON string that describes the style sheet object.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Assistants/{AssistantSid}/StyleSheet"
    path_params: [{name: AssistantSid, var: assistant_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: StyleSheet, var: style_sheet}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://autopilot.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, style_sheet: $style_sheet
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Assistants/{AssistantSid}/Tasks
#
# Returns: record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, tasks: table<account_sid: string, actions_url: string, assistant_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string>>
# operationId: ListTask
export def "list-task" [
  assistant_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/Assistants/{AssistantSid}/Tasks"
    path_params: [{name: AssistantSid, var: assistant_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://autopilot.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Assistants/{AssistantSid}/Tasks
#
# Returns: record<account_sid: string, actions_url: string, assistant_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string>
# operationId: CreateTask
export def "create-task" [
  assistant_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --actions: any # The JSON string that specifies the [actions](https://www.twilio.com/docs/autopilot/actions) that instruct the Assistant on how to perform the task. It is optional and not unique.
  --actions-url: string # The URL from which the Assistant can fetch actions. (format: uri)
  --friendly-name: string # A descriptive string that you create to describe the new resource. It is not unique and can be up to 255 characters long.
  unique_name: string # An application-defined string that uniquely identifies the new resource. It can be used as an alternative to the `sid` in the URL path to address the resource. This value must be unique and 64 characters or less in length.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Assistants/{AssistantSid}/Tasks"
    path_params: [{name: AssistantSid, var: assistant_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Actions, var: actions}, {name: ActionsUrl, var: actions_url}, {name: FriendlyName, var: friendly_name}, {name: UniqueName, var: unique_name}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://autopilot.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, actions: $actions, actions_url: $actions_url, friendly_name: $friendly_name, unique_name: $unique_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/Assistants/{AssistantSid}/Tasks/{Sid}
#
# operationId: DeleteTask
export def "delete-task" [
  assistant_sid: string
  sid: string
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
    path: "/v1/Assistants/{AssistantSid}/Tasks/{Sid}"
    path_params: [{name: AssistantSid, var: assistant_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://autopilot.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Assistants/{AssistantSid}/Tasks/{Sid}
#
# Returns: record<account_sid: string, actions_url: string, assistant_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string>
# operationId: FetchTask
export def "fetch-task" [
  assistant_sid: string
  sid: string
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
    path: "/v1/Assistants/{AssistantSid}/Tasks/{Sid}"
    path_params: [{name: AssistantSid, var: assistant_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://autopilot.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Assistants/{AssistantSid}/Tasks/{Sid}
#
# Returns: record<account_sid: string, actions_url: string, assistant_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string>
# operationId: UpdateTask
export def "update-task" [
  assistant_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --actions: any # The JSON string that specifies the [actions](https://www.twilio.com/docs/autopilot/actions) that instruct the Assistant on how to perform the task.
  --actions-url: string # The URL from which the Assistant can fetch actions. (format: uri)
  --friendly-name: string # A descriptive string that you create to describe the resource. It is not unique and can be up to 255 characters long.
  --unique-name: string # An application-defined string that uniquely identifies the resource. This value must be 64 characters or less in length and be unique. It can be used as an alternative to the `sid` in the URL path to address the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Assistants/{AssistantSid}/Tasks/{Sid}"
    path_params: [{name: AssistantSid, var: assistant_sid}, {name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Actions, var: actions}, {name: ActionsUrl, var: actions_url}, {name: FriendlyName, var: friendly_name}, {name: UniqueName, var: unique_name}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://autopilot.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, sid: $sid, actions: $actions, actions_url: $actions_url, friendly_name: $friendly_name, unique_name: $unique_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns JSON actions for the Task.
#
# GET /v1/Assistants/{AssistantSid}/Tasks/{TaskSid}/Actions
# Returns: record<account_sid: string, assistant_sid: string, data: any, task_sid: string, url: string>
# operationId: FetchTaskActions
export def "fetch-task-actions" [
  assistant_sid: string
  task_sid: string
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
    path: "/v1/Assistants/{AssistantSid}/Tasks/{TaskSid}/Actions"
    path_params: [{name: AssistantSid, var: assistant_sid}, {name: TaskSid, var: task_sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://autopilot.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, task_sid: $task_sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the actions of an Task identified by {TaskSid} or {TaskUniqueName}.
#
# POST /v1/Assistants/{AssistantSid}/Tasks/{TaskSid}/Actions
# Returns: record<account_sid: string, assistant_sid: string, data: any, task_sid: string, url: string>
# operationId: UpdateTaskActions
export def "update-task-actions" [
  assistant_sid: string
  task_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --actions: any # The JSON string that specifies the [actions](https://www.twilio.com/docs/autopilot/actions) that instruct the Assistant on how to perform the task.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Assistants/{AssistantSid}/Tasks/{TaskSid}/Actions"
    path_params: [{name: AssistantSid, var: assistant_sid}, {name: TaskSid, var: task_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Actions, var: actions}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://autopilot.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, task_sid: $task_sid, actions: $actions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Assistants/{AssistantSid}/Tasks/{TaskSid}/Fields
#
# Returns: record<fields: table<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, field_type: string, sid: string, task_sid: string, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListField
export def "list-field" [
  assistant_sid: string
  task_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/Assistants/{AssistantSid}/Tasks/{TaskSid}/Fields"
    path_params: [{name: AssistantSid, var: assistant_sid}, {name: TaskSid, var: task_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://autopilot.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, task_sid: $task_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Assistants/{AssistantSid}/Tasks/{TaskSid}/Fields
#
# Returns: record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, field_type: string, sid: string, task_sid: string, unique_name: string, url: string>
# operationId: CreateField
export def "create-field" [
  assistant_sid: string
  task_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  field_type: string # The Field Type of the new field. Can be: a [Built-in Field Type](https://www.twilio.com/docs/autopilot/built-in-field-types), the `unique_name`, or the `sid` of a custom Field Type.
  unique_name: string # An application-defined string that uniquely identifies the new resource. This value must be a unique string of no more than 64 characters. It can be used as an alternative to the `sid` in the URL path to address the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Assistants/{AssistantSid}/Tasks/{TaskSid}/Fields"
    path_params: [{name: AssistantSid, var: assistant_sid}, {name: TaskSid, var: task_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: FieldType, var: field_type}, {name: UniqueName, var: unique_name}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://autopilot.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, task_sid: $task_sid, field_type: $field_type, unique_name: $unique_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/Assistants/{AssistantSid}/Tasks/{TaskSid}/Fields/{Sid}
#
# operationId: DeleteField
export def "delete-field" [
  assistant_sid: string
  task_sid: string
  sid: string
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
    path: "/v1/Assistants/{AssistantSid}/Tasks/{TaskSid}/Fields/{Sid}"
    path_params: [{name: AssistantSid, var: assistant_sid}, {name: TaskSid, var: task_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://autopilot.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, task_sid: $task_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Assistants/{AssistantSid}/Tasks/{TaskSid}/Fields/{Sid}
#
# Returns: record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, field_type: string, sid: string, task_sid: string, unique_name: string, url: string>
# operationId: FetchField
export def "fetch-field" [
  assistant_sid: string
  task_sid: string
  sid: string
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
    path: "/v1/Assistants/{AssistantSid}/Tasks/{TaskSid}/Fields/{Sid}"
    path_params: [{name: AssistantSid, var: assistant_sid}, {name: TaskSid, var: task_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://autopilot.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, task_sid: $task_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Assistants/{AssistantSid}/Tasks/{TaskSid}/Samples
#
# Returns: record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, samples: table<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, language: string, sid: string, source_channel: string, tagged_text: string, task_sid: string, url: string>>
# operationId: ListSample
export def "list-sample" [
  assistant_sid: string
  task_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --language: string # The [ISO language-country](https://docs.oracle.com/cd/E13214_01/wli/docs92/xref/xqisocodes.html) string that specifies the language used for the sample. For example: `en-US`.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/Assistants/{AssistantSid}/Tasks/{TaskSid}/Samples"
    path_params: [{name: AssistantSid, var: assistant_sid}, {name: TaskSid, var: task_sid}]
    query: [{name: Language, var: language}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://autopilot.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, task_sid: $task_sid, language: $language, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Assistants/{AssistantSid}/Tasks/{TaskSid}/Samples
#
# Returns: record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, language: string, sid: string, source_channel: string, tagged_text: string, task_sid: string, url: string>
# operationId: CreateSample
export def "create-sample" [
  assistant_sid: string
  task_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  language: string # The [ISO language-country](https://docs.oracle.com/cd/E13214_01/wli/docs92/xref/xqisocodes.html) string that specifies the language used for the new sample. For example: `en-US`.
  --source-channel: string # The communication channel from which the new sample was captured. Can be: `voice`, `sms`, `chat`, `alexa`, `google-assistant`, `slack`, or null if not included.
  tagged_text: string # The text example of how end users might express the task. The sample can contain [Field tag blocks](https://www.twilio.com/docs/autopilot/api/task-sample#field-tagging).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Assistants/{AssistantSid}/Tasks/{TaskSid}/Samples"
    path_params: [{name: AssistantSid, var: assistant_sid}, {name: TaskSid, var: task_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Language, var: language}, {name: SourceChannel, var: source_channel}, {name: TaggedText, var: tagged_text}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://autopilot.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, task_sid: $task_sid, language: $language, source_channel: $source_channel, tagged_text: $tagged_text
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/Assistants/{AssistantSid}/Tasks/{TaskSid}/Samples/{Sid}
#
# operationId: DeleteSample
export def "delete-sample" [
  assistant_sid: string
  task_sid: string
  sid: string
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
    path: "/v1/Assistants/{AssistantSid}/Tasks/{TaskSid}/Samples/{Sid}"
    path_params: [{name: AssistantSid, var: assistant_sid}, {name: TaskSid, var: task_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://autopilot.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, task_sid: $task_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Assistants/{AssistantSid}/Tasks/{TaskSid}/Samples/{Sid}
#
# Returns: record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, language: string, sid: string, source_channel: string, tagged_text: string, task_sid: string, url: string>
# operationId: FetchSample
export def "fetch-sample" [
  assistant_sid: string
  task_sid: string
  sid: string
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
    path: "/v1/Assistants/{AssistantSid}/Tasks/{TaskSid}/Samples/{Sid}"
    path_params: [{name: AssistantSid, var: assistant_sid}, {name: TaskSid, var: task_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://autopilot.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, task_sid: $task_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Assistants/{AssistantSid}/Tasks/{TaskSid}/Samples/{Sid}
#
# Returns: record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, language: string, sid: string, source_channel: string, tagged_text: string, task_sid: string, url: string>
# operationId: UpdateSample
export def "update-sample" [
  assistant_sid: string
  task_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --language: string # The [ISO language-country](https://docs.oracle.com/cd/E13214_01/wli/docs92/xref/xqisocodes.html) string that specifies the language used for the sample. For example: `en-US`.
  --source-channel: string # The communication channel from which the sample was captured. Can be: `voice`, `sms`, `chat`, `alexa`, `google-assistant`, `slack`, or null if not included.
  --tagged-text: string # The text example of how end users might express the task. The sample can contain [Field tag blocks](https://www.twilio.com/docs/autopilot/api/task-sample#field-tagging).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Assistants/{AssistantSid}/Tasks/{TaskSid}/Samples/{Sid}"
    path_params: [{name: AssistantSid, var: assistant_sid}, {name: TaskSid, var: task_sid}, {name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Language, var: language}, {name: SourceChannel, var: source_channel}, {name: TaggedText, var: tagged_text}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://autopilot.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, task_sid: $task_sid, sid: $sid, language: $language, source_channel: $source_channel, tagged_text: $tagged_text
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Assistants/{AssistantSid}/Tasks/{TaskSid}/Statistics
#
# Returns: record<account_sid: string, assistant_sid: string, fields_count: int, samples_count: int, task_sid: string, url: string>
# operationId: FetchTaskStatistics
export def "fetch-task-statistics" [
  assistant_sid: string
  task_sid: string
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
    path: "/v1/Assistants/{AssistantSid}/Tasks/{TaskSid}/Statistics"
    path_params: [{name: AssistantSid, var: assistant_sid}, {name: TaskSid, var: task_sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://autopilot.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, task_sid: $task_sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Assistants/{AssistantSid}/Webhooks
#
# Returns: record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, webhooks: table<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, events: string, sid: string, unique_name: string, url: string, webhook_method: string, webhook_url: string>>
# operationId: ListWebhook
export def "list-webhook" [
  assistant_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/Assistants/{AssistantSid}/Webhooks"
    path_params: [{name: AssistantSid, var: assistant_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://autopilot.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Assistants/{AssistantSid}/Webhooks
#
# Returns: record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, events: string, sid: string, unique_name: string, url: string, webhook_method: string, webhook_url: string>
# operationId: CreateWebhook
export def "create-webhook" [
  assistant_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  events: string # The list of space-separated events that this Webhook will subscribe to.
  unique_name: string # An application-defined string that uniquely identifies the new resource. It can be used as an alternative to the `sid` in the URL path to address the resource. This value must be unique and 64 characters or less in length.
  --webhook-method: string # The method to be used when calling the webhook's URL.
  webhook_url: string # The URL associated with this Webhook. (format: uri)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Assistants/{AssistantSid}/Webhooks"
    path_params: [{name: AssistantSid, var: assistant_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Events, var: events}, {name: UniqueName, var: unique_name}, {name: WebhookMethod, var: webhook_method}, {name: WebhookUrl, var: webhook_url}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://autopilot.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, events: $events, unique_name: $unique_name, webhook_method: $webhook_method, webhook_url: $webhook_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/Assistants/{AssistantSid}/Webhooks/{Sid}
#
# operationId: DeleteWebhook
export def "delete-webhook" [
  assistant_sid: string
  sid: string
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
    path: "/v1/Assistants/{AssistantSid}/Webhooks/{Sid}"
    path_params: [{name: AssistantSid, var: assistant_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://autopilot.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Assistants/{AssistantSid}/Webhooks/{Sid}
#
# Returns: record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, events: string, sid: string, unique_name: string, url: string, webhook_method: string, webhook_url: string>
# operationId: FetchWebhook
export def "fetch-webhook" [
  assistant_sid: string
  sid: string
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
    path: "/v1/Assistants/{AssistantSid}/Webhooks/{Sid}"
    path_params: [{name: AssistantSid, var: assistant_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://autopilot.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Assistants/{AssistantSid}/Webhooks/{Sid}
#
# Returns: record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, events: string, sid: string, unique_name: string, url: string, webhook_method: string, webhook_url: string>
# operationId: UpdateWebhook
export def "update-webhook" [
  assistant_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --events: string # The list of space-separated events that this Webhook will subscribe to.
  --unique-name: string # An application-defined string that uniquely identifies the new resource. It can be used as an alternative to the `sid` in the URL path to address the resource. This value must be unique and 64 characters or less in length.
  --webhook-method: string # The method to be used when calling the webhook's URL.
  --webhook-url: string # The URL associated with this Webhook. (format: uri)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Assistants/{AssistantSid}/Webhooks/{Sid}"
    path_params: [{name: AssistantSid, var: assistant_sid}, {name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Events, var: events}, {name: UniqueName, var: unique_name}, {name: WebhookMethod, var: webhook_method}, {name: WebhookUrl, var: webhook_url}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://autopilot.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, sid: $sid, events: $events, unique_name: $unique_name, webhook_method: $webhook_method, webhook_url: $webhook_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/Assistants/{Sid}
#
# operationId: DeleteAssistant
export def "delete-assistant" [
  sid: string
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
    path: "/v1/Assistants/{Sid}"
    path_params: [{name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://autopilot.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Assistants/{Sid}
#
# Returns: record<account_sid: string, callback_events: string, callback_url: string, date_created: string, date_updated: string, development_stage: string, friendly_name: string, latest_model_build_sid: string, links: record, log_queries: bool, needs_model_build: bool, sid: string, unique_name: string, url: string>
# operationId: FetchAssistant
export def "fetch-assistant" [
  sid: string
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
    path: "/v1/Assistants/{Sid}"
    path_params: [{name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://autopilot.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Assistants/{Sid}
#
# Returns: record<account_sid: string, callback_events: string, callback_url: string, date_created: string, date_updated: string, development_stage: string, friendly_name: string, latest_model_build_sid: string, links: record, log_queries: bool, needs_model_build: bool, sid: string, unique_name: string, url: string>
# operationId: UpdateAssistant
export def "update-assistant" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --callback-events: string # Reserved.
  --callback-url: string # Reserved. (format: uri)
  --defaults: any # A JSON object that defines the Assistant's [default tasks](https://www.twilio.com/docs/autopilot/api/assistant/defaults) for various scenarios, including initiation actions and fallback tasks.
  --development-stage: string # A string describing the state of the assistant.
  --friendly-name: string # A descriptive string that you create to describe the resource. It is not unique and can be up to 255 characters long.
  --log-queries: oneof<nothing, bool> # Whether queries should be logged and kept after training. Can be: `true` or `false` and defaults to `true`. If `true`, queries are stored for 30 days, and then deleted. If `false`, no queries are stored.
  --style-sheet: any # The JSON string that defines the Assistant's [style sheet](https://www.twilio.com/docs/autopilot/api/assistant/stylesheet)
  --unique-name: string # An application-defined string that uniquely identifies the resource. It can be used as an alternative to the `sid` in the URL path to address the resource. The first 64 characters must be unique.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Assistants/{Sid}"
    path_params: [{name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: CallbackEvents, var: callback_events}, {name: CallbackUrl, var: callback_url}, {name: Defaults, var: defaults}, {name: DevelopmentStage, var: development_stage}, {name: FriendlyName, var: friendly_name}, {name: LogQueries, var: log_queries}, {name: StyleSheet, var: style_sheet}, {name: UniqueName, var: unique_name}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://autopilot.twilio.com"
    auth: basic
  } {
    sid: $sid, callback_events: $callback_events, callback_url: $callback_url, defaults: $defaults, development_stage: $development_stage, friendly_name: $friendly_name, log_queries: $log_queries, style_sheet: $style_sheet, unique_name: $unique_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
