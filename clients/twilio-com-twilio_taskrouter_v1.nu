# Auto-generated client for Twilio - Taskrouter v1.42.0
# Source: https://api.apis.guru/v2/specs/twilio.com/twilio_taskrouter_v1/1.42.0/openapi.json
# Auth: --token flag or $env.TWILIO_TASKROUTER_TOKEN

const CLIENT = {
  base_url: "https://taskrouter.twilio.com"
  token_env_var: "TWILIO_TASKROUTER_TOKEN"
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

def base-url-completer [] { ["https://taskrouter.twilio.com"] }
def auth-scheme-completer [] { ["basic" "basic-credentials"] }

# Completers for enum parameters
def prioritize-queue-order-completer [] { ["FIFO" "LIFO"] }
def task-order-completer [] { ["FIFO" "LIFO"] }
def assignment-status-completer [] { ["assigned" "canceled" "completed" "pending" "reserved" "wrapping"] }
def reservation-status-completer [] { ["accepted" "canceled" "completed" "pending" "rejected" "rescinded" "timeout" "wrapping"] }
def conference-recording-status-callback-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def conference-status-callback-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def recording-status-callback-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def status-callback-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def supervisor-mode-completer [] { ["barge" "monitor" "whisper"] }
def wait-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    list-workspace: "record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, workspaces: table<account_sid: string, date_created: string, date_updated: string, default_activity_name: string, default_activity_sid: string, event_callback_url: string, events_filter: string, friendly_name: string, links: record, multi_task_enabled: bool, prioritize_queue_order: string, sid: string, timeout_activity_name: string, timeout_activity_sid: string, url: string>>"
    create-workspace: "record<account_sid: string, date_created: string, date_updated: string, default_activity_name: string, default_activity_sid: string, event_callback_url: string, events_filter: string, friendly_name: string, links: record, multi_task_enabled: bool, prioritize_queue_order: string, sid: string, timeout_activity_name: string, timeout_activity_sid: string, url: string>"
    fetch-workspace: "record<account_sid: string, date_created: string, date_updated: string, default_activity_name: string, default_activity_sid: string, event_callback_url: string, events_filter: string, friendly_name: string, links: record, multi_task_enabled: bool, prioritize_queue_order: string, sid: string, timeout_activity_name: string, timeout_activity_sid: string, url: string>"
    update-workspace: "record<account_sid: string, date_created: string, date_updated: string, default_activity_name: string, default_activity_sid: string, event_callback_url: string, events_filter: string, friendly_name: string, links: record, multi_task_enabled: bool, prioritize_queue_order: string, sid: string, timeout_activity_name: string, timeout_activity_sid: string, url: string>"
    list-activity: "record<activities: table<account_sid: string, available: bool, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, url: string, workspace_sid: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    create-activity: "record<account_sid: string, available: bool, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, url: string, workspace_sid: string>"
    fetch-activity: "record<account_sid: string, available: bool, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, url: string, workspace_sid: string>"
    update-activity: "record<account_sid: string, available: bool, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, url: string, workspace_sid: string>"
    fetch-workspace-cumulative-statistics: "record<account_sid: string, avg_task_acceptance_time: int, end_time: string, reservations_accepted: int, reservations_canceled: int, reservations_created: int, reservations_rejected: int, reservations_rescinded: int, reservations_timed_out: int, split_by_wait_time: any, start_time: string, tasks_canceled: int, tasks_completed: int, tasks_created: int, tasks_deleted: int, tasks_moved: int, tasks_timed_out_in_workflow: int, url: string, wait_duration_until_accepted: any, wait_duration_until_canceled: any, workspace_sid: string>"
    list-event: "record<events: table<account_sid: string, actor_sid: string, actor_type: string, actor_url: string, description: string, event_data: any, event_date: string, event_date_ms: int, event_type: string, resource_sid: string, resource_type: string, resource_url: string, sid: string, source: string, source_ip_address: string, url: string, workspace_sid: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    fetch-event: "record<account_sid: string, actor_sid: string, actor_type: string, actor_url: string, description: string, event_data: any, event_date: string, event_date_ms: int, event_type: string, resource_sid: string, resource_type: string, resource_url: string, sid: string, source: string, source_ip_address: string, url: string, workspace_sid: string>"
    fetch-workspace-real-time-statistics: "record<account_sid: string, activity_statistics: list<any>, longest_task_waiting_age: int, longest_task_waiting_sid: string, tasks_by_priority: any, tasks_by_status: any, total_tasks: int, total_workers: int, url: string, workspace_sid: string>"
    fetch-workspace-statistics: "record<account_sid: string, cumulative: any, realtime: any, url: string, workspace_sid: string>"
    list-task-channel: "record<channels: table<account_sid: string, channel_optimized_routing: bool, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string, workspace_sid: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    create-task-channel: "record<account_sid: string, channel_optimized_routing: bool, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string, workspace_sid: string>"
    fetch-task-channel: "record<account_sid: string, channel_optimized_routing: bool, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string, workspace_sid: string>"
    update-task-channel: "record<account_sid: string, channel_optimized_routing: bool, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string, workspace_sid: string>"
    list-task-queue: "record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, task_queues: table<account_sid: string, assignment_activity_name: string, assignment_activity_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, max_reserved_workers: int, reservation_activity_name: string, reservation_activity_sid: string, sid: string, target_workers: string, task_order: string, url: string, workspace_sid: string>>"
    create-task-queue: "record<account_sid: string, assignment_activity_name: string, assignment_activity_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, max_reserved_workers: int, reservation_activity_name: string, reservation_activity_sid: string, sid: string, target_workers: string, task_order: string, url: string, workspace_sid: string>"
    list-task-queues-statistics: "record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, task_queues_statistics: table<account_sid: string, cumulative: any, realtime: any, task_queue_sid: string, workspace_sid: string>>"
    fetch-task-queue: "record<account_sid: string, assignment_activity_name: string, assignment_activity_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, max_reserved_workers: int, reservation_activity_name: string, reservation_activity_sid: string, sid: string, target_workers: string, task_order: string, url: string, workspace_sid: string>"
    update-task-queue: "record<account_sid: string, assignment_activity_name: string, assignment_activity_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, max_reserved_workers: int, reservation_activity_name: string, reservation_activity_sid: string, sid: string, target_workers: string, task_order: string, url: string, workspace_sid: string>"
    fetch-task-queue-cumulative-statistics: "record<account_sid: string, avg_task_acceptance_time: int, end_time: string, reservations_accepted: int, reservations_canceled: int, reservations_created: int, reservations_rejected: int, reservations_rescinded: int, reservations_timed_out: int, split_by_wait_time: any, start_time: string, task_queue_sid: string, tasks_canceled: int, tasks_completed: int, tasks_deleted: int, tasks_entered: int, tasks_moved: int, url: string, wait_duration_in_queue_until_accepted: any, wait_duration_until_accepted: any, wait_duration_until_canceled: any, workspace_sid: string>"
    fetch-task-queue-real-time-statistics: "record<account_sid: string, activity_statistics: list<any>, longest_relative_task_age_in_queue: int, longest_relative_task_sid_in_queue: string, longest_task_waiting_age: int, longest_task_waiting_sid: string, task_queue_sid: string, tasks_by_priority: any, tasks_by_status: any, total_available_workers: int, total_eligible_workers: int, total_tasks: int, url: string, workspace_sid: string>"
    fetch-task-queue-statistics: "record<account_sid: string, cumulative: any, realtime: any, task_queue_sid: string, url: string, workspace_sid: string>"
    list-task: "record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, tasks: table<account_sid: string, addons: string, age: int, assignment_status: string, attributes: string, date_created: string, date_updated: string, links: record, priority: int, reason: string, sid: string, task_channel_sid: string, task_channel_unique_name: string, task_queue_entered_date: string, task_queue_friendly_name: string, task_queue_sid: string, timeout: int, url: string, workflow_friendly_name: string, workflow_sid: string, workspace_sid: string>>"
    create-task: "record<account_sid: string, addons: string, age: int, assignment_status: string, attributes: string, date_created: string, date_updated: string, links: record, priority: int, reason: string, sid: string, task_channel_sid: string, task_channel_unique_name: string, task_queue_entered_date: string, task_queue_friendly_name: string, task_queue_sid: string, timeout: int, url: string, workflow_friendly_name: string, workflow_sid: string, workspace_sid: string>"
    fetch-task: "record<account_sid: string, addons: string, age: int, assignment_status: string, attributes: string, date_created: string, date_updated: string, links: record, priority: int, reason: string, sid: string, task_channel_sid: string, task_channel_unique_name: string, task_queue_entered_date: string, task_queue_friendly_name: string, task_queue_sid: string, timeout: int, url: string, workflow_friendly_name: string, workflow_sid: string, workspace_sid: string>"
    update-task: "record<account_sid: string, addons: string, age: int, assignment_status: string, attributes: string, date_created: string, date_updated: string, links: record, priority: int, reason: string, sid: string, task_channel_sid: string, task_channel_unique_name: string, task_queue_entered_date: string, task_queue_friendly_name: string, task_queue_sid: string, timeout: int, url: string, workflow_friendly_name: string, workflow_sid: string, workspace_sid: string>"
    list-task-reservation: "record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, reservations: table<account_sid: string, date_created: string, date_updated: string, links: record, reservation_status: string, sid: string, task_sid: string, url: string, worker_name: string, worker_sid: string, workspace_sid: string>>"
    fetch-task-reservation: "record<account_sid: string, date_created: string, date_updated: string, links: record, reservation_status: string, sid: string, task_sid: string, url: string, worker_name: string, worker_sid: string, workspace_sid: string>"
    update-task-reservation: "record<account_sid: string, date_created: string, date_updated: string, links: record, reservation_status: string, sid: string, task_sid: string, url: string, worker_name: string, worker_sid: string, workspace_sid: string>"
    list-worker: "record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, workers: table<account_sid: string, activity_name: string, activity_sid: string, attributes: string, available: bool, date_created: string, date_status_changed: string, date_updated: string, friendly_name: string, links: record, sid: string, url: string, workspace_sid: string>>"
    create-worker: "record<account_sid: string, activity_name: string, activity_sid: string, attributes: string, available: bool, date_created: string, date_status_changed: string, date_updated: string, friendly_name: string, links: record, sid: string, url: string, workspace_sid: string>"
    fetch-workers-cumulative-statistics: "record<account_sid: string, activity_durations: list<any>, end_time: string, reservations_accepted: int, reservations_canceled: int, reservations_created: int, reservations_rejected: int, reservations_rescinded: int, reservations_timed_out: int, start_time: string, url: string, workspace_sid: string>"
    fetch-workers-real-time-statistics: "record<account_sid: string, activity_statistics: list<any>, total_workers: int, url: string, workspace_sid: string>"
    fetch-worker-statistics: "record<account_sid: string, cumulative: any, realtime: any, url: string, workspace_sid: string>"
    fetch-worker: "record<account_sid: string, activity_name: string, activity_sid: string, attributes: string, available: bool, date_created: string, date_status_changed: string, date_updated: string, friendly_name: string, links: record, sid: string, url: string, workspace_sid: string>"
    update-worker: "record<account_sid: string, activity_name: string, activity_sid: string, attributes: string, available: bool, date_created: string, date_status_changed: string, date_updated: string, friendly_name: string, links: record, sid: string, url: string, workspace_sid: string>"
    list-worker-channel: "record<channels: table<account_sid: string, assigned_tasks: int, available: bool, available_capacity_percentage: int, configured_capacity: int, date_created: string, date_updated: string, sid: string, task_channel_sid: string, task_channel_unique_name: string, url: string, worker_sid: string, workspace_sid: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    fetch-worker-channel: "record<account_sid: string, assigned_tasks: int, available: bool, available_capacity_percentage: int, configured_capacity: int, date_created: string, date_updated: string, sid: string, task_channel_sid: string, task_channel_unique_name: string, url: string, worker_sid: string, workspace_sid: string>"
    update-worker-channel: "record<account_sid: string, assigned_tasks: int, available: bool, available_capacity_percentage: int, configured_capacity: int, date_created: string, date_updated: string, sid: string, task_channel_sid: string, task_channel_unique_name: string, url: string, worker_sid: string, workspace_sid: string>"
    list-worker-reservation: "record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, reservations: table<account_sid: string, date_created: string, date_updated: string, links: record, reservation_status: string, sid: string, task_sid: string, url: string, worker_name: string, worker_sid: string, workspace_sid: string>>"
    fetch-worker-reservation: "record<account_sid: string, date_created: string, date_updated: string, links: record, reservation_status: string, sid: string, task_sid: string, url: string, worker_name: string, worker_sid: string, workspace_sid: string>"
    update-worker-reservation: "record<account_sid: string, date_created: string, date_updated: string, links: record, reservation_status: string, sid: string, task_sid: string, url: string, worker_name: string, worker_sid: string, workspace_sid: string>"
    fetch-worker-instance-statistics: "record<account_sid: string, cumulative: any, url: string, worker_sid: string, workspace_sid: string>"
    list-workflow: "record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, workflows: table<account_sid: string, assignment_callback_url: string, configuration: string, date_created: string, date_updated: string, document_content_type: string, fallback_assignment_callback_url: string, friendly_name: string, links: record, sid: string, task_reservation_timeout: int, url: string, workspace_sid: string>>"
    create-workflow: "record<account_sid: string, assignment_callback_url: string, configuration: string, date_created: string, date_updated: string, document_content_type: string, fallback_assignment_callback_url: string, friendly_name: string, links: record, sid: string, task_reservation_timeout: int, url: string, workspace_sid: string>"
    fetch-workflow: "record<account_sid: string, assignment_callback_url: string, configuration: string, date_created: string, date_updated: string, document_content_type: string, fallback_assignment_callback_url: string, friendly_name: string, links: record, sid: string, task_reservation_timeout: int, url: string, workspace_sid: string>"
    update-workflow: "record<account_sid: string, assignment_callback_url: string, configuration: string, date_created: string, date_updated: string, document_content_type: string, fallback_assignment_callback_url: string, friendly_name: string, links: record, sid: string, task_reservation_timeout: int, url: string, workspace_sid: string>"
    fetch-workflow-cumulative-statistics: "record<account_sid: string, avg_task_acceptance_time: int, end_time: string, reservations_accepted: int, reservations_canceled: int, reservations_created: int, reservations_rejected: int, reservations_rescinded: int, reservations_timed_out: int, split_by_wait_time: any, start_time: string, tasks_canceled: int, tasks_completed: int, tasks_deleted: int, tasks_entered: int, tasks_moved: int, tasks_timed_out_in_workflow: int, url: string, wait_duration_until_accepted: any, wait_duration_until_canceled: any, workflow_sid: string, workspace_sid: string>"
    fetch-workflow-real-time-statistics: "record<account_sid: string, longest_task_waiting_age: int, longest_task_waiting_sid: string, tasks_by_priority: any, tasks_by_status: any, total_tasks: int, url: string, workflow_sid: string, workspace_sid: string>"
    fetch-workflow-statistics: "record<account_sid: string, cumulative: any, realtime: any, url: string, workflow_sid: string, workspace_sid: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["list-workspace" "create-workspace" "delete-workspace" "fetch-workspace" "update-workspace" "list-activity" "create-activity" "delete-activity" "fetch-activity" "update-activity" "fetch-workspace-cumulative-statistics" "list-event" "fetch-event" "fetch-workspace-real-time-statistics" "fetch-workspace-statistics" "list-task-channel" "create-task-channel" "delete-task-channel" "fetch-task-channel" "update-task-channel" "list-task-queue" "create-task-queue" "list-task-queues-statistics" "delete-task-queue" "fetch-task-queue" "update-task-queue" "fetch-task-queue-cumulative-statistics" "fetch-task-queue-real-time-statistics" "fetch-task-queue-statistics" "list-task" "create-task" "delete-task" "fetch-task" "update-task" "list-task-reservation" "fetch-task-reservation" "update-task-reservation" "list-worker" "create-worker" "fetch-workers-cumulative-statistics" "fetch-workers-real-time-statistics" "fetch-worker-statistics" "delete-worker" "fetch-worker" "update-worker" "list-worker-channel" "fetch-worker-channel" "update-worker-channel" "list-worker-reservation" "fetch-worker-reservation" "update-worker-reservation" "fetch-worker-instance-statistics" "list-workflow" "create-workflow" "delete-workflow" "fetch-workflow" "update-workflow" "fetch-workflow-cumulative-statistics" "fetch-workflow-real-time-statistics" "fetch-workflow-statistics" "commands"] | sort) } | get name | first)
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

# GET /v1/Workspaces
#
# Returns: record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, workspaces: table<account_sid: string, date_created: string, date_updated: string, default_activity_name: string, default_activity_sid: string, event_callback_url: string, events_filter: string, friendly_name: string, links: record, multi_task_enabled: bool, prioritize_queue_order: string, sid: string, timeout_activity_name: string, timeout_activity_sid: string, url: string>>
# operationId: ListWorkspace
export def "list-workspace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --friendly-name: string # The `friendly_name` of the Workspace resources to read. For example `Customer Support` or `2014 Election Campaign`.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/Workspaces"
    query: [{name: FriendlyName, var: friendly_name}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://taskrouter.twilio.com"
    auth: basic
  } {
    friendly_name: $friendly_name, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Workspaces
#
# Returns: record<account_sid: string, date_created: string, date_updated: string, default_activity_name: string, default_activity_sid: string, event_callback_url: string, events_filter: string, friendly_name: string, links: record, multi_task_enabled: bool, prioritize_queue_order: string, sid: string, timeout_activity_name: string, timeout_activity_sid: string, url: string>
# operationId: CreateWorkspace
export def "create-workspace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --event-callback-url: string # The URL we should call when an event occurs. If provided, the Workspace will publish events to this URL, for example, to collect data for reporting. See [Workspace Events](https://www.twilio.com/docs/taskrouter/api/event) for more information. This parameter supports Twilio's [Webhooks (HTTP callbacks) Connection Overrides](https://www.twilio.com/docs/usage/webhooks/webhooks-connection-overrides). (format: uri)
  --events-filter: string # The list of Workspace events for which to call event_callback_url. For example, if `EventsFilter=task.created, task.canceled, worker.activity.update`, then TaskRouter will call event_callback_url only when a task is created, canceled, or a Worker activity is updated.
  friendly_name: string # A descriptive string that you create to describe the Workspace resource. It can be up to 64 characters long. For example: `Customer Support` or `2014 Election Campaign`.
  --multi-task-enabled: oneof<nothing, bool> # Whether to enable multi-tasking. Can be: `true` to enable multi-tasking, or `false` to disable it. However, all workspaces should be created as multi-tasking. The default is `true`. Multi-tasking allows Workers to handle multiple Tasks simultaneously. When enabled (`true`), each Worker can receive parallel reservations up to the per-channel maximums defined in the Workers section. In single-tasking mode (legacy mode), each Worker will only receive a new reservation when the previous task is completed. Learn more at [Multitasking](https://www.twilio.com/docs/taskrouter/multitasking).
  --prioritize-queue-order: string@prioritize-queue-order-completer
  --template: string # An available template name. Can be: `NONE` or `FIFO` and the default is `NONE`. Pre-configures the Workspace with the Workflow and Activities specified in the template. `NONE` will create a Workspace with only a set of default activities. `FIFO` will configure TaskRouter with a set of default activities and a single TaskQueue for first-in, first-out distribution, which can be useful when you are getting started with TaskRouter.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Workspaces"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: EventCallbackUrl, var: event_callback_url}, {name: EventsFilter, var: events_filter}, {name: FriendlyName, var: friendly_name}, {name: MultiTaskEnabled, var: multi_task_enabled}, {name: PrioritizeQueueOrder, var: prioritize_queue_order}, {name: Template, var: template}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://taskrouter.twilio.com"
    auth: basic
  } {
    event_callback_url: $event_callback_url, events_filter: $events_filter, friendly_name: $friendly_name, multi_task_enabled: $multi_task_enabled, prioritize_queue_order: $prioritize_queue_order, template: $template
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/Workspaces/{Sid}
#
# operationId: DeleteWorkspace
export def "delete-workspace" [
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
    path: "/v1/Workspaces/{Sid}"
    path_params: [{name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://taskrouter.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Workspaces/{Sid}
#
# Returns: record<account_sid: string, date_created: string, date_updated: string, default_activity_name: string, default_activity_sid: string, event_callback_url: string, events_filter: string, friendly_name: string, links: record, multi_task_enabled: bool, prioritize_queue_order: string, sid: string, timeout_activity_name: string, timeout_activity_sid: string, url: string>
# operationId: FetchWorkspace
export def "fetch-workspace" [
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
    path: "/v1/Workspaces/{Sid}"
    path_params: [{name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://taskrouter.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Workspaces/{Sid}
#
# Returns: record<account_sid: string, date_created: string, date_updated: string, default_activity_name: string, default_activity_sid: string, event_callback_url: string, events_filter: string, friendly_name: string, links: record, multi_task_enabled: bool, prioritize_queue_order: string, sid: string, timeout_activity_name: string, timeout_activity_sid: string, url: string>
# operationId: UpdateWorkspace
export def "update-workspace" [
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
  --default-activity-sid: string # The SID of the Activity that will be used when new Workers are created in the Workspace.
  --event-callback-url: string # The URL we should call when an event occurs. See [Workspace Events](https://www.twilio.com/docs/taskrouter/api/event) for more information. This parameter supports Twilio's [Webhooks (HTTP callbacks) Connection Overrides](https://www.twilio.com/docs/usage/webhooks/webhooks-connection-overrides). (format: uri)
  --events-filter: string # The list of Workspace events for which to call event_callback_url. For example if `EventsFilter=task.created,task.canceled,worker.activity.update`, then TaskRouter will call event_callback_url only when a task is created, canceled, or a Worker activity is updated.
  --friendly-name: string # A descriptive string that you create to describe the Workspace resource. For example: `Sales Call Center` or `Customer Support Team`.
  --multi-task-enabled: oneof<nothing, bool> # Whether to enable multi-tasking. Can be: `true` to enable multi-tasking, or `false` to disable it. However, all workspaces should be maintained as multi-tasking. There is no default when omitting this parameter. A multi-tasking Workspace can't be updated to single-tasking unless it is not a Flex Project and another (legacy) single-tasking Workspace exists. Multi-tasking allows Workers to handle multiple Tasks simultaneously. In multi-tasking mode, each Worker can receive parallel reservations up to the per-channel maximums defined in the Workers section. In single-tasking mode (legacy mode), each Worker will only receive a new reservation when the previous task is completed. Learn more at [Multitasking](https://www.twilio.com/docs/taskrouter/multitasking).
  --prioritize-queue-order: string@prioritize-queue-order-completer
  --timeout-activity-sid: string # The SID of the Activity that will be assigned to a Worker when a Task reservation times out without a response.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Workspaces/{Sid}"
    path_params: [{name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: DefaultActivitySid, var: default_activity_sid}, {name: EventCallbackUrl, var: event_callback_url}, {name: EventsFilter, var: events_filter}, {name: FriendlyName, var: friendly_name}, {name: MultiTaskEnabled, var: multi_task_enabled}, {name: PrioritizeQueueOrder, var: prioritize_queue_order}, {name: TimeoutActivitySid, var: timeout_activity_sid}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://taskrouter.twilio.com"
    auth: basic
  } {
    sid: $sid, default_activity_sid: $default_activity_sid, event_callback_url: $event_callback_url, events_filter: $events_filter, friendly_name: $friendly_name, multi_task_enabled: $multi_task_enabled, prioritize_queue_order: $prioritize_queue_order, timeout_activity_sid: $timeout_activity_sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Workspaces/{WorkspaceSid}/Activities
#
# Returns: record<activities: table<account_sid: string, available: bool, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, url: string, workspace_sid: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListActivity
export def "list-activity" [
  workspace_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --friendly-name: string # The `friendly_name` of the Activity resources to read.
  --available: string # Whether return only Activity resources that are available or unavailable. A value of `true` returns only available activities. Values of '1' or `yes` also indicate `true`. All other values represent `false` and return activities that are unavailable.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/Workspaces/{WorkspaceSid}/Activities"
    path_params: [{name: WorkspaceSid, var: workspace_sid}]
    query: [{name: FriendlyName, var: friendly_name}, {name: Available, var: available}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://taskrouter.twilio.com"
    auth: basic
  } {
    workspace_sid: $workspace_sid, friendly_name: $friendly_name, available: $available, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Workspaces/{WorkspaceSid}/Activities
#
# Returns: record<account_sid: string, available: bool, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, url: string, workspace_sid: string>
# operationId: CreateActivity
export def "create-activity" [
  workspace_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --available: oneof<nothing, bool> # Whether the Worker should be eligible to receive a Task when it occupies the Activity. A value of `true`, `1`, or `yes` specifies the Activity is available. All other values specify that it is not. The value cannot be changed after the Activity is created.
  friendly_name: string # A descriptive string that you create to describe the Activity resource. It can be up to 64 characters long. These names are used to calculate and expose statistics about Workers, and provide visibility into the state of each Worker. Examples of friendly names include: `on-call`, `break`, and `email`.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Workspaces/{WorkspaceSid}/Activities"
    path_params: [{name: WorkspaceSid, var: workspace_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Available, var: available}, {name: FriendlyName, var: friendly_name}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://taskrouter.twilio.com"
    auth: basic
  } {
    workspace_sid: $workspace_sid, available: $available, friendly_name: $friendly_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/Workspaces/{WorkspaceSid}/Activities/{Sid}
#
# operationId: DeleteActivity
export def "delete-activity" [
  workspace_sid: string
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
    path: "/v1/Workspaces/{WorkspaceSid}/Activities/{Sid}"
    path_params: [{name: WorkspaceSid, var: workspace_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://taskrouter.twilio.com"
    auth: basic
  } {
    workspace_sid: $workspace_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Workspaces/{WorkspaceSid}/Activities/{Sid}
#
# Returns: record<account_sid: string, available: bool, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, url: string, workspace_sid: string>
# operationId: FetchActivity
export def "fetch-activity" [
  workspace_sid: string
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
    path: "/v1/Workspaces/{WorkspaceSid}/Activities/{Sid}"
    path_params: [{name: WorkspaceSid, var: workspace_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://taskrouter.twilio.com"
    auth: basic
  } {
    workspace_sid: $workspace_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Workspaces/{WorkspaceSid}/Activities/{Sid}
#
# Returns: record<account_sid: string, available: bool, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, url: string, workspace_sid: string>
# operationId: UpdateActivity
export def "update-activity" [
  workspace_sid: string
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
  --friendly-name: string # A descriptive string that you create to describe the Activity resource. It can be up to 64 characters long. These names are used to calculate and expose statistics about Workers, and provide visibility into the state of each Worker. Examples of friendly names include: `on-call`, `break`, and `email`.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Workspaces/{WorkspaceSid}/Activities/{Sid}"
    path_params: [{name: WorkspaceSid, var: workspace_sid}, {name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: FriendlyName, var: friendly_name}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://taskrouter.twilio.com"
    auth: basic
  } {
    workspace_sid: $workspace_sid, sid: $sid, friendly_name: $friendly_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Workspaces/{WorkspaceSid}/CumulativeStatistics
#
# Returns: record<account_sid: string, avg_task_acceptance_time: int, end_time: string, reservations_accepted: int, reservations_canceled: int, reservations_created: int, reservations_rejected: int, reservations_rescinded: int, reservations_timed_out: int, split_by_wait_time: any, start_time: string, tasks_canceled: int, tasks_completed: int, tasks_created: int, tasks_deleted: int, tasks_moved: int, tasks_timed_out_in_workflow: int, url: string, wait_duration_until_accepted: any, wait_duration_until_canceled: any, workspace_sid: string>
# operationId: FetchWorkspaceCumulativeStatistics
export def "fetch-workspace-cumulative-statistics" [
  workspace_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --end-date: string # Only include usage that occurred on or before this date, specified in GMT as an [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) date-time. (format: date-time)
  --minutes: int # Only calculate statistics since this many minutes in the past. The default 15 minutes. This is helpful for displaying statistics for the last 15 minutes, 240 minutes (4 hours), and 480 minutes (8 hours) to see trends.
  --start-date: string # Only calculate statistics from this date and time and later, specified in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format. (format: date-time)
  --task-channel: string # Only calculate cumulative statistics on this TaskChannel. Can be the TaskChannel's SID or its `unique_name`, such as `voice`, `sms`, or `default`.
  --split-by-wait-time: string # A comma separated list of values that describes the thresholds, in seconds, to calculate statistics on. For each threshold specified, the number of Tasks canceled and reservations accepted above and below the specified thresholds in seconds are computed. For example, `5,30` would show splits of Tasks that were canceled or accepted before and after 5 seconds and before and after 30 seconds. This can be used to show short abandoned Tasks or Tasks that failed to meet an SLA. TaskRouter will calculate statistics on up to 10,000 Tasks for any given threshold.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/Workspaces/{WorkspaceSid}/CumulativeStatistics"
    path_params: [{name: WorkspaceSid, var: workspace_sid}]
    query: [{name: EndDate, var: end_date}, {name: Minutes, var: minutes}, {name: StartDate, var: start_date}, {name: TaskChannel, var: task_channel}, {name: SplitByWaitTime, var: split_by_wait_time}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://taskrouter.twilio.com"
    auth: basic
  } {
    workspace_sid: $workspace_sid, end_date: $end_date, minutes: $minutes, start_date: $start_date, task_channel: $task_channel, split_by_wait_time: $split_by_wait_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Workspaces/{WorkspaceSid}/Events
#
# Returns: record<events: table<account_sid: string, actor_sid: string, actor_type: string, actor_url: string, description: string, event_data: any, event_date: string, event_date_ms: int, event_type: string, resource_sid: string, resource_type: string, resource_url: string, sid: string, source: string, source_ip_address: string, url: string, workspace_sid: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListEvent
export def "list-event" [
  workspace_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --end-date: string # Only include Events that occurred on or before this date, specified in GMT as an [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) date-time. (format: date-time)
  --event-type: string # The type of Events to read. Returns only Events of the type specified.
  --minutes: int # The period of events to read in minutes. Returns only Events that occurred since this many minutes in the past. The default is `15` minutes. Task Attributes for Events occuring more 43,200 minutes ago will be redacted.
  --reservation-sid: string # The SID of the Reservation with the Events to read. Returns only Events that pertain to the specified Reservation.
  --start-date: string # Only include Events from on or after this date and time, specified in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format. Task Attributes for Events older than 30 days will be redacted. (format: date-time)
  --task-queue-sid: string # The SID of the TaskQueue with the Events to read. Returns only the Events that pertain to the specified TaskQueue.
  --task-sid: string # The SID of the Task with the Events to read. Returns only the Events that pertain to the specified Task.
  --worker-sid: string # The SID of the Worker with the Events to read. Returns only the Events that pertain to the specified Worker.
  --workflow-sid: string # The SID of the Workflow with the Events to read. Returns only the Events that pertain to the specified Workflow.
  --task-channel: string # The TaskChannel with the Events to read. Returns only the Events that pertain to the specified TaskChannel.
  --sid: string # The SID of the Event resource to read.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/Workspaces/{WorkspaceSid}/Events"
    path_params: [{name: WorkspaceSid, var: workspace_sid}]
    query: [{name: EndDate, var: end_date}, {name: EventType, var: event_type}, {name: Minutes, var: minutes}, {name: ReservationSid, var: reservation_sid}, {name: StartDate, var: start_date}, {name: TaskQueueSid, var: task_queue_sid}, {name: TaskSid, var: task_sid}, {name: WorkerSid, var: worker_sid}, {name: WorkflowSid, var: workflow_sid}, {name: TaskChannel, var: task_channel}, {name: Sid, var: sid}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://taskrouter.twilio.com"
    auth: basic
  } {
    workspace_sid: $workspace_sid, end_date: $end_date, event_type: $event_type, minutes: $minutes, reservation_sid: $reservation_sid, start_date: $start_date, task_queue_sid: $task_queue_sid, task_sid: $task_sid, worker_sid: $worker_sid, workflow_sid: $workflow_sid, task_channel: $task_channel, sid: $sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Workspaces/{WorkspaceSid}/Events/{Sid}
#
# Returns: record<account_sid: string, actor_sid: string, actor_type: string, actor_url: string, description: string, event_data: any, event_date: string, event_date_ms: int, event_type: string, resource_sid: string, resource_type: string, resource_url: string, sid: string, source: string, source_ip_address: string, url: string, workspace_sid: string>
# operationId: FetchEvent
export def "fetch-event" [
  workspace_sid: string
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
    path: "/v1/Workspaces/{WorkspaceSid}/Events/{Sid}"
    path_params: [{name: WorkspaceSid, var: workspace_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://taskrouter.twilio.com"
    auth: basic
  } {
    workspace_sid: $workspace_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Workspaces/{WorkspaceSid}/RealTimeStatistics
#
# Returns: record<account_sid: string, activity_statistics: list<any>, longest_task_waiting_age: int, longest_task_waiting_sid: string, tasks_by_priority: any, tasks_by_status: any, total_tasks: int, total_workers: int, url: string, workspace_sid: string>
# operationId: FetchWorkspaceRealTimeStatistics
export def "fetch-workspace-real-time-statistics" [
  workspace_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --task-channel: string # Only calculate real-time statistics on this TaskChannel. Can be the TaskChannel's SID or its `unique_name`, such as `voice`, `sms`, or `default`.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/Workspaces/{WorkspaceSid}/RealTimeStatistics"
    path_params: [{name: WorkspaceSid, var: workspace_sid}]
    query: [{name: TaskChannel, var: task_channel}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://taskrouter.twilio.com"
    auth: basic
  } {
    workspace_sid: $workspace_sid, task_channel: $task_channel
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Workspaces/{WorkspaceSid}/Statistics
#
# Returns: record<account_sid: string, cumulative: any, realtime: any, url: string, workspace_sid: string>
# operationId: FetchWorkspaceStatistics
export def "fetch-workspace-statistics" [
  workspace_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --minutes: int # Only calculate statistics since this many minutes in the past. The default 15 minutes. This is helpful for displaying statistics for the last 15 minutes, 240 minutes (4 hours), and 480 minutes (8 hours) to see trends.
  --start-date: string # Only calculate statistics from this date and time and later, specified in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format. (format: date-time)
  --end-date: string # Only calculate statistics from this date and time and earlier, specified in GMT as an [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) date-time. (format: date-time)
  --task-channel: string # Only calculate statistics on this TaskChannel. Can be the TaskChannel's SID or its `unique_name`, such as `voice`, `sms`, or `default`.
  --split-by-wait-time: string # A comma separated list of values that describes the thresholds, in seconds, to calculate statistics on. For each threshold specified, the number of Tasks canceled and reservations accepted above and below the specified thresholds in seconds are computed. For example, `5,30` would show splits of Tasks that were canceled or accepted before and after 5 seconds and before and after 30 seconds. This can be used to show short abandoned Tasks or Tasks that failed to meet an SLA.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/Workspaces/{WorkspaceSid}/Statistics"
    path_params: [{name: WorkspaceSid, var: workspace_sid}]
    query: [{name: Minutes, var: minutes}, {name: StartDate, var: start_date}, {name: EndDate, var: end_date}, {name: TaskChannel, var: task_channel}, {name: SplitByWaitTime, var: split_by_wait_time}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://taskrouter.twilio.com"
    auth: basic
  } {
    workspace_sid: $workspace_sid, minutes: $minutes, start_date: $start_date, end_date: $end_date, task_channel: $task_channel, split_by_wait_time: $split_by_wait_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Workspaces/{WorkspaceSid}/TaskChannels
#
# Returns: record<channels: table<account_sid: string, channel_optimized_routing: bool, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string, workspace_sid: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListTaskChannel
export def "list-task-channel" [
  workspace_sid: string
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
    path: "/v1/Workspaces/{WorkspaceSid}/TaskChannels"
    path_params: [{name: WorkspaceSid, var: workspace_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://taskrouter.twilio.com"
    auth: basic
  } {
    workspace_sid: $workspace_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Workspaces/{WorkspaceSid}/TaskChannels
#
# Returns: record<account_sid: string, channel_optimized_routing: bool, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string, workspace_sid: string>
# operationId: CreateTaskChannel
export def "create-task-channel" [
  workspace_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --channel-optimized-routing: oneof<nothing, bool> # Whether the Task Channel should prioritize Workers that have been idle. If `true`, Workers that have been idle the longest are prioritized.
  friendly_name: string # A descriptive string that you create to describe the Task Channel. It can be up to 64 characters long.
  unique_name: string # An application-defined string that uniquely identifies the Task Channel, such as `voice` or `sms`.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Workspaces/{WorkspaceSid}/TaskChannels"
    path_params: [{name: WorkspaceSid, var: workspace_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: ChannelOptimizedRouting, var: channel_optimized_routing}, {name: FriendlyName, var: friendly_name}, {name: UniqueName, var: unique_name}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://taskrouter.twilio.com"
    auth: basic
  } {
    workspace_sid: $workspace_sid, channel_optimized_routing: $channel_optimized_routing, friendly_name: $friendly_name, unique_name: $unique_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/Workspaces/{WorkspaceSid}/TaskChannels/{Sid}
#
# operationId: DeleteTaskChannel
export def "delete-task-channel" [
  workspace_sid: string
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
    path: "/v1/Workspaces/{WorkspaceSid}/TaskChannels/{Sid}"
    path_params: [{name: WorkspaceSid, var: workspace_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://taskrouter.twilio.com"
    auth: basic
  } {
    workspace_sid: $workspace_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Workspaces/{WorkspaceSid}/TaskChannels/{Sid}
#
# Returns: record<account_sid: string, channel_optimized_routing: bool, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string, workspace_sid: string>
# operationId: FetchTaskChannel
export def "fetch-task-channel" [
  workspace_sid: string
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
    path: "/v1/Workspaces/{WorkspaceSid}/TaskChannels/{Sid}"
    path_params: [{name: WorkspaceSid, var: workspace_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://taskrouter.twilio.com"
    auth: basic
  } {
    workspace_sid: $workspace_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Workspaces/{WorkspaceSid}/TaskChannels/{Sid}
#
# Returns: record<account_sid: string, channel_optimized_routing: bool, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string, workspace_sid: string>
# operationId: UpdateTaskChannel
export def "update-task-channel" [
  workspace_sid: string
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
  --channel-optimized-routing: oneof<nothing, bool> # Whether the TaskChannel should prioritize Workers that have been idle. If `true`, Workers that have been idle the longest are prioritized.
  --friendly-name: string # A descriptive string that you create to describe the Task Channel. It can be up to 64 characters long.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Workspaces/{WorkspaceSid}/TaskChannels/{Sid}"
    path_params: [{name: WorkspaceSid, var: workspace_sid}, {name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: ChannelOptimizedRouting, var: channel_optimized_routing}, {name: FriendlyName, var: friendly_name}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://taskrouter.twilio.com"
    auth: basic
  } {
    workspace_sid: $workspace_sid, sid: $sid, channel_optimized_routing: $channel_optimized_routing, friendly_name: $friendly_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Workspaces/{WorkspaceSid}/TaskQueues
#
# Returns: record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, task_queues: table<account_sid: string, assignment_activity_name: string, assignment_activity_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, max_reserved_workers: int, reservation_activity_name: string, reservation_activity_sid: string, sid: string, target_workers: string, task_order: string, url: string, workspace_sid: string>>
# operationId: ListTaskQueue
export def "list-task-queue" [
  workspace_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --friendly-name: string # The `friendly_name` of the TaskQueue resources to read.
  --evaluate-worker-attributes: string # The attributes of the Workers to read. Returns the TaskQueues with Workers that match the attributes specified in this parameter.
  --worker-sid: string # The SID of the Worker with the TaskQueue resources to read.
  --ordering: string # Sorting parameter for TaskQueues
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/Workspaces/{WorkspaceSid}/TaskQueues"
    path_params: [{name: WorkspaceSid, var: workspace_sid}]
    query: [{name: FriendlyName, var: friendly_name}, {name: EvaluateWorkerAttributes, var: evaluate_worker_attributes}, {name: WorkerSid, var: worker_sid}, {name: Ordering, var: ordering}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://taskrouter.twilio.com"
    auth: basic
  } {
    workspace_sid: $workspace_sid, friendly_name: $friendly_name, evaluate_worker_attributes: $evaluate_worker_attributes, worker_sid: $worker_sid, ordering: $ordering, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Workspaces/{WorkspaceSid}/TaskQueues
#
# Returns: record<account_sid: string, assignment_activity_name: string, assignment_activity_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, max_reserved_workers: int, reservation_activity_name: string, reservation_activity_sid: string, sid: string, target_workers: string, task_order: string, url: string, workspace_sid: string>
# operationId: CreateTaskQueue
export def "create-task-queue" [
  workspace_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --assignment-activity-sid: string # The SID of the Activity to assign Workers when a task is assigned to them.
  friendly_name: string # A descriptive string that you create to describe the TaskQueue. For example `Support-Tier 1`, `Sales`, or `Escalation`.
  --max-reserved-workers: int # The maximum number of Workers to reserve for the assignment of a Task in the queue. Can be an integer between 1 and 50, inclusive and defaults to 1.
  --reservation-activity-sid: string # The SID of the Activity to assign Workers when a task is reserved for them.
  --target-workers: string # A string that describes the Worker selection criteria for any Tasks that enter the TaskQueue. For example, `'"language" == "spanish"'`. The default value is `1==1`. If this value is empty, Tasks will wait in the TaskQueue until they are deleted or moved to another TaskQueue. For more information about Worker selection, see [Describing Worker selection criteria](https://www.twilio.com/docs/taskrouter/api/taskqueues#target-workers).
  --task-order: string@task-order-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Workspaces/{WorkspaceSid}/TaskQueues"
    path_params: [{name: WorkspaceSid, var: workspace_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: AssignmentActivitySid, var: assignment_activity_sid}, {name: FriendlyName, var: friendly_name}, {name: MaxReservedWorkers, var: max_reserved_workers}, {name: ReservationActivitySid, var: reservation_activity_sid}, {name: TargetWorkers, var: target_workers}, {name: TaskOrder, var: task_order}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://taskrouter.twilio.com"
    auth: basic
  } {
    workspace_sid: $workspace_sid, assignment_activity_sid: $assignment_activity_sid, friendly_name: $friendly_name, max_reserved_workers: $max_reserved_workers, reservation_activity_sid: $reservation_activity_sid, target_workers: $target_workers, task_order: $task_order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Workspaces/{WorkspaceSid}/TaskQueues/Statistics
#
# Returns: record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, task_queues_statistics: table<account_sid: string, cumulative: any, realtime: any, task_queue_sid: string, workspace_sid: string>>
# operationId: ListTaskQueuesStatistics
export def "list-task-queues-statistics" [
  workspace_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --end-date: string # Only calculate statistics from this date and time and earlier, specified in GMT as an [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) date-time. (format: date-time)
  --friendly-name: string # The `friendly_name` of the TaskQueue statistics to read.
  --minutes: int # Only calculate statistics since this many minutes in the past. The default is 15 minutes.
  --start-date: string # Only calculate statistics from this date and time and later, specified in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format. (format: date-time)
  --task-channel: string # Only calculate statistics on this TaskChannel. Can be the TaskChannel's SID or its `unique_name`, such as `voice`, `sms`, or `default`.
  --split-by-wait-time: string # A comma separated list of values that describes the thresholds, in seconds, to calculate statistics on. For each threshold specified, the number of Tasks canceled and reservations accepted above and below the specified thresholds in seconds are computed.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/Workspaces/{WorkspaceSid}/TaskQueues/Statistics"
    path_params: [{name: WorkspaceSid, var: workspace_sid}]
    query: [{name: EndDate, var: end_date}, {name: FriendlyName, var: friendly_name}, {name: Minutes, var: minutes}, {name: StartDate, var: start_date}, {name: TaskChannel, var: task_channel}, {name: SplitByWaitTime, var: split_by_wait_time}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://taskrouter.twilio.com"
    auth: basic
  } {
    workspace_sid: $workspace_sid, end_date: $end_date, friendly_name: $friendly_name, minutes: $minutes, start_date: $start_date, task_channel: $task_channel, split_by_wait_time: $split_by_wait_time, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/Workspaces/{WorkspaceSid}/TaskQueues/{Sid}
#
# operationId: DeleteTaskQueue
export def "delete-task-queue" [
  workspace_sid: string
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
    path: "/v1/Workspaces/{WorkspaceSid}/TaskQueues/{Sid}"
    path_params: [{name: WorkspaceSid, var: workspace_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://taskrouter.twilio.com"
    auth: basic
  } {
    workspace_sid: $workspace_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Workspaces/{WorkspaceSid}/TaskQueues/{Sid}
#
# Returns: record<account_sid: string, assignment_activity_name: string, assignment_activity_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, max_reserved_workers: int, reservation_activity_name: string, reservation_activity_sid: string, sid: string, target_workers: string, task_order: string, url: string, workspace_sid: string>
# operationId: FetchTaskQueue
export def "fetch-task-queue" [
  workspace_sid: string
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
    path: "/v1/Workspaces/{WorkspaceSid}/TaskQueues/{Sid}"
    path_params: [{name: WorkspaceSid, var: workspace_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://taskrouter.twilio.com"
    auth: basic
  } {
    workspace_sid: $workspace_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Workspaces/{WorkspaceSid}/TaskQueues/{Sid}
#
# Returns: record<account_sid: string, assignment_activity_name: string, assignment_activity_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, max_reserved_workers: int, reservation_activity_name: string, reservation_activity_sid: string, sid: string, target_workers: string, task_order: string, url: string, workspace_sid: string>
# operationId: UpdateTaskQueue
export def "update-task-queue" [
  workspace_sid: string
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
  --assignment-activity-sid: string # The SID of the Activity to assign Workers when a task is assigned for them.
  --friendly-name: string # A descriptive string that you create to describe the TaskQueue. For example `Support-Tier 1`, `Sales`, or `Escalation`.
  --max-reserved-workers: int # The maximum number of Workers to create reservations for the assignment of a task while in the queue. Maximum of 50.
  --reservation-activity-sid: string # The SID of the Activity to assign Workers when a task is reserved for them.
  --target-workers: string # A string describing the Worker selection criteria for any Tasks that enter the TaskQueue. For example '"language" == "spanish"' If no TargetWorkers parameter is provided, Tasks will wait in the queue until they are either deleted or moved to another queue. Additional examples on how to describing Worker selection criteria below.
  --task-order: string@task-order-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Workspaces/{WorkspaceSid}/TaskQueues/{Sid}"
    path_params: [{name: WorkspaceSid, var: workspace_sid}, {name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: AssignmentActivitySid, var: assignment_activity_sid}, {name: FriendlyName, var: friendly_name}, {name: MaxReservedWorkers, var: max_reserved_workers}, {name: ReservationActivitySid, var: reservation_activity_sid}, {name: TargetWorkers, var: target_workers}, {name: TaskOrder, var: task_order}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://taskrouter.twilio.com"
    auth: basic
  } {
    workspace_sid: $workspace_sid, sid: $sid, assignment_activity_sid: $assignment_activity_sid, friendly_name: $friendly_name, max_reserved_workers: $max_reserved_workers, reservation_activity_sid: $reservation_activity_sid, target_workers: $target_workers, task_order: $task_order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Workspaces/{WorkspaceSid}/TaskQueues/{TaskQueueSid}/CumulativeStatistics
#
# Returns: record<account_sid: string, avg_task_acceptance_time: int, end_time: string, reservations_accepted: int, reservations_canceled: int, reservations_created: int, reservations_rejected: int, reservations_rescinded: int, reservations_timed_out: int, split_by_wait_time: any, start_time: string, task_queue_sid: string, tasks_canceled: int, tasks_completed: int, tasks_deleted: int, tasks_entered: int, tasks_moved: int, url: string, wait_duration_in_queue_until_accepted: any, wait_duration_until_accepted: any, wait_duration_until_canceled: any, workspace_sid: string>
# operationId: FetchTaskQueueCumulativeStatistics
export def "fetch-task-queue-cumulative-statistics" [
  workspace_sid: string
  task_queue_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --end-date: string # Only calculate statistics from this date and time and earlier, specified in GMT as an [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) date-time. (format: date-time)
  --minutes: int # Only calculate statistics since this many minutes in the past. The default is 15 minutes.
  --start-date: string # Only calculate statistics from this date and time and later, specified in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format. (format: date-time)
  --task-channel: string # Only calculate cumulative statistics on this TaskChannel. Can be the TaskChannel's SID or its `unique_name`, such as `voice`, `sms`, or `default`.
  --split-by-wait-time: string # A comma separated list of values that describes the thresholds, in seconds, to calculate statistics on. For each threshold specified, the number of Tasks canceled and reservations accepted above and below the specified thresholds in seconds are computed. TaskRouter will calculate statistics on up to 10,000 Tasks/Reservations for any given threshold.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/Workspaces/{WorkspaceSid}/TaskQueues/{TaskQueueSid}/CumulativeStatistics"
    path_params: [{name: WorkspaceSid, var: workspace_sid}, {name: TaskQueueSid, var: task_queue_sid}]
    query: [{name: EndDate, var: end_date}, {name: Minutes, var: minutes}, {name: StartDate, var: start_date}, {name: TaskChannel, var: task_channel}, {name: SplitByWaitTime, var: split_by_wait_time}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://taskrouter.twilio.com"
    auth: basic
  } {
    workspace_sid: $workspace_sid, task_queue_sid: $task_queue_sid, end_date: $end_date, minutes: $minutes, start_date: $start_date, task_channel: $task_channel, split_by_wait_time: $split_by_wait_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Workspaces/{WorkspaceSid}/TaskQueues/{TaskQueueSid}/RealTimeStatistics
#
# Returns: record<account_sid: string, activity_statistics: list<any>, longest_relative_task_age_in_queue: int, longest_relative_task_sid_in_queue: string, longest_task_waiting_age: int, longest_task_waiting_sid: string, task_queue_sid: string, tasks_by_priority: any, tasks_by_status: any, total_available_workers: int, total_eligible_workers: int, total_tasks: int, url: string, workspace_sid: string>
# operationId: FetchTaskQueueRealTimeStatistics
export def "fetch-task-queue-real-time-statistics" [
  workspace_sid: string
  task_queue_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --task-channel: string # The TaskChannel for which to fetch statistics. Can be the TaskChannel's SID or its `unique_name`, such as `voice`, `sms`, or `default`.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/Workspaces/{WorkspaceSid}/TaskQueues/{TaskQueueSid}/RealTimeStatistics"
    path_params: [{name: WorkspaceSid, var: workspace_sid}, {name: TaskQueueSid, var: task_queue_sid}]
    query: [{name: TaskChannel, var: task_channel}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://taskrouter.twilio.com"
    auth: basic
  } {
    workspace_sid: $workspace_sid, task_queue_sid: $task_queue_sid, task_channel: $task_channel
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Workspaces/{WorkspaceSid}/TaskQueues/{TaskQueueSid}/Statistics
#
# Returns: record<account_sid: string, cumulative: any, realtime: any, task_queue_sid: string, url: string, workspace_sid: string>
# operationId: FetchTaskQueueStatistics
export def "fetch-task-queue-statistics" [
  workspace_sid: string
  task_queue_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --end-date: string # Only calculate statistics from this date and time and earlier, specified in GMT as an [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) date-time. (format: date-time)
  --minutes: int # Only calculate statistics since this many minutes in the past. The default is 15 minutes.
  --start-date: string # Only calculate statistics from this date and time and later, specified in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format. (format: date-time)
  --task-channel: string # Only calculate real-time and cumulative statistics for the specified TaskChannel. Can be the TaskChannel's SID or its `unique_name`, such as `voice`, `sms`, or `default`.
  --split-by-wait-time: string # A comma separated list of values that describes the thresholds, in seconds, to calculate statistics on. For each threshold specified, the number of Tasks canceled and reservations accepted above and below the specified thresholds in seconds are computed.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/Workspaces/{WorkspaceSid}/TaskQueues/{TaskQueueSid}/Statistics"
    path_params: [{name: WorkspaceSid, var: workspace_sid}, {name: TaskQueueSid, var: task_queue_sid}]
    query: [{name: EndDate, var: end_date}, {name: Minutes, var: minutes}, {name: StartDate, var: start_date}, {name: TaskChannel, var: task_channel}, {name: SplitByWaitTime, var: split_by_wait_time}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://taskrouter.twilio.com"
    auth: basic
  } {
    workspace_sid: $workspace_sid, task_queue_sid: $task_queue_sid, end_date: $end_date, minutes: $minutes, start_date: $start_date, task_channel: $task_channel, split_by_wait_time: $split_by_wait_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Workspaces/{WorkspaceSid}/Tasks
#
# Returns: record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, tasks: table<account_sid: string, addons: string, age: int, assignment_status: string, attributes: string, date_created: string, date_updated: string, links: record, priority: int, reason: string, sid: string, task_channel_sid: string, task_channel_unique_name: string, task_queue_entered_date: string, task_queue_friendly_name: string, task_queue_sid: string, timeout: int, url: string, workflow_friendly_name: string, workflow_sid: string, workspace_sid: string>>
# operationId: ListTask
export def "list-task" [
  workspace_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --priority: int # The priority value of the Tasks to read. Returns the list of all Tasks in the Workspace with the specified priority.
  --assignment-status: list<string> # The `assignment_status` of the Tasks you want to read. Can be: `pending`, `reserved`, `assigned`, `canceled`, `wrapping`, or `completed`. Returns all Tasks in the Workspace with the specified `assignment_status`.
  --workflow-sid: string # The SID of the Workflow with the Tasks to read. Returns the Tasks controlled by the Workflow identified by this SID.
  --workflow-name: string # The friendly name of the Workflow with the Tasks to read. Returns the Tasks controlled by the Workflow identified by this friendly name.
  --task-queue-sid: string # The SID of the TaskQueue with the Tasks to read. Returns the Tasks waiting in the TaskQueue identified by this SID.
  --task-queue-name: string # The `friendly_name` of the TaskQueue with the Tasks to read. Returns the Tasks waiting in the TaskQueue identified by this friendly name.
  --evaluate-task-attributes: string # The attributes of the Tasks to read. Returns the Tasks that match the attributes specified in this parameter.
  --ordering: string # How to order the returned Task resources. y default, Tasks are sorted by ascending DateCreated. This value is specified as: `Attribute:Order`, where `Attribute` can be either `Priority` or `DateCreated` and `Order` can be either `asc` or `desc`. For example, `Priority:desc` returns Tasks ordered in descending order of their Priority. Multiple sort orders can be specified in a comma-separated list such as `Priority:desc,DateCreated:asc`, which returns the Tasks in descending Priority order and ascending DateCreated Order.
  --has-addons: oneof<nothing, bool> # Whether to read Tasks with addons. If `true`, returns only Tasks with addons. If `false`, returns only Tasks without addons.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/Workspaces/{WorkspaceSid}/Tasks"
    path_params: [{name: WorkspaceSid, var: workspace_sid}]
    query: [{name: Priority, var: priority}, {name: AssignmentStatus, var: assignment_status, style: multi}, {name: WorkflowSid, var: workflow_sid}, {name: WorkflowName, var: workflow_name}, {name: TaskQueueSid, var: task_queue_sid}, {name: TaskQueueName, var: task_queue_name}, {name: EvaluateTaskAttributes, var: evaluate_task_attributes}, {name: Ordering, var: ordering}, {name: HasAddons, var: has_addons}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://taskrouter.twilio.com"
    auth: basic
  } {
    workspace_sid: $workspace_sid, priority: $priority, assignment_status: $assignment_status, workflow_sid: $workflow_sid, workflow_name: $workflow_name, task_queue_sid: $task_queue_sid, task_queue_name: $task_queue_name, evaluate_task_attributes: $evaluate_task_attributes, ordering: $ordering, has_addons: $has_addons, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Workspaces/{WorkspaceSid}/Tasks
#
# Returns: record<account_sid: string, addons: string, age: int, assignment_status: string, attributes: string, date_created: string, date_updated: string, links: record, priority: int, reason: string, sid: string, task_channel_sid: string, task_channel_unique_name: string, task_queue_entered_date: string, task_queue_friendly_name: string, task_queue_sid: string, timeout: int, url: string, workflow_friendly_name: string, workflow_sid: string, workspace_sid: string>
# operationId: CreateTask
export def "create-task" [
  workspace_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: string # A URL-encoded JSON string with the attributes of the new task. This value is passed to the Workflow's `assignment_callback_url` when the Task is assigned to a Worker. For example: `{ "task_type": "call", "twilio_call_sid": "CAxxx", "customer_ticket_number": "12345" }`.
  --priority: int # The priority to assign the new task and override the default. When supplied, the new Task will have this priority unless it matches a Workflow Target with a Priority set. When not supplied, the new Task will have the priority of the matching Workflow Target. Value can be 0 to 2^31^ (2,147,483,647).
  --task-channel: string # When MultiTasking is enabled, specify the TaskChannel by passing either its `unique_name` or `sid`. Default value is `default`.
  --timeout: int # The amount of time in seconds the new task can live before being assigned. Can be up to a maximum of 2 weeks (1,209,600 seconds). The default value is 24 hours (86,400 seconds). On timeout, the `task.canceled` event will fire with description `Task TTL Exceeded`.
  --workflow-sid: string # The SID of the Workflow that you would like to handle routing for the new Task. If there is only one Workflow defined for the Workspace that you are posting the new task to, this parameter is optional.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Workspaces/{WorkspaceSid}/Tasks"
    path_params: [{name: WorkspaceSid, var: workspace_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Attributes, var: attributes}, {name: Priority, var: priority}, {name: TaskChannel, var: task_channel}, {name: Timeout, var: timeout}, {name: WorkflowSid, var: workflow_sid}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://taskrouter.twilio.com"
    auth: basic
  } {
    workspace_sid: $workspace_sid, attributes: $attributes, priority: $priority, task_channel: $task_channel, timeout: $timeout, workflow_sid: $workflow_sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/Workspaces/{WorkspaceSid}/Tasks/{Sid}
#
# operationId: DeleteTask
export def "delete-task" [
  workspace_sid: string
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
  --if-match: string # If provided, deletes this Task if (and only if) the [ETag](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/ETag) header of the Task matches the provided value. This matches the semantics of (and is implemented with) the HTTP [If-Match header](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/If-Match).
]: nothing -> any {
  http-request {
    method: delete
    path: "/v1/Workspaces/{WorkspaceSid}/Tasks/{Sid}"
    path_params: [{name: WorkspaceSid, var: workspace_sid}, {name: Sid, var: sid}]
    header: [{name: If-Match, var: if_match}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://taskrouter.twilio.com"
    auth: basic
  } {
    workspace_sid: $workspace_sid, sid: $sid, if_match: $if_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Workspaces/{WorkspaceSid}/Tasks/{Sid}
#
# Returns: record<account_sid: string, addons: string, age: int, assignment_status: string, attributes: string, date_created: string, date_updated: string, links: record, priority: int, reason: string, sid: string, task_channel_sid: string, task_channel_unique_name: string, task_queue_entered_date: string, task_queue_friendly_name: string, task_queue_sid: string, timeout: int, url: string, workflow_friendly_name: string, workflow_sid: string, workspace_sid: string>
# operationId: FetchTask
export def "fetch-task" [
  workspace_sid: string
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
    path: "/v1/Workspaces/{WorkspaceSid}/Tasks/{Sid}"
    path_params: [{name: WorkspaceSid, var: workspace_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://taskrouter.twilio.com"
    auth: basic
  } {
    workspace_sid: $workspace_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Workspaces/{WorkspaceSid}/Tasks/{Sid}
#
# Returns: record<account_sid: string, addons: string, age: int, assignment_status: string, attributes: string, date_created: string, date_updated: string, links: record, priority: int, reason: string, sid: string, task_channel_sid: string, task_channel_unique_name: string, task_queue_entered_date: string, task_queue_friendly_name: string, task_queue_sid: string, timeout: int, url: string, workflow_friendly_name: string, workflow_sid: string, workspace_sid: string>
# operationId: UpdateTask
export def "update-task" [
  workspace_sid: string
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
  --if-match: string # If provided, applies this mutation if (and only if) the [ETag](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/ETag) header of the Task matches the provided value. This matches the semantics of (and is implemented with) the HTTP [If-Match header](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/If-Match).
  --assignment-status: string@assignment-status-completer
  --attributes: string # The JSON string that describes the custom attributes of the task.
  --priority: int # The Task's new priority value. When supplied, the Task takes on the specified priority unless it matches a Workflow Target with a Priority set. Value can be 0 to 2^31^ (2,147,483,647).
  --reason: string # The reason that the Task was canceled or completed. This parameter is required only if the Task is canceled or completed. Setting this value queues the task for deletion and logs the reason.
  --task-channel: string # When MultiTasking is enabled, specify the TaskChannel with the task to update. Can be the TaskChannel's SID or its `unique_name`, such as `voice`, `sms`, or `default`.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Workspaces/{WorkspaceSid}/Tasks/{Sid}"
    path_params: [{name: WorkspaceSid, var: workspace_sid}, {name: Sid, var: sid}]
    header: [{name: If-Match, var: if_match}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: AssignmentStatus, var: assignment_status}, {name: Attributes, var: attributes}, {name: Priority, var: priority}, {name: Reason, var: reason}, {name: TaskChannel, var: task_channel}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://taskrouter.twilio.com"
    auth: basic
  } {
    workspace_sid: $workspace_sid, sid: $sid, if_match: $if_match, assignment_status: $assignment_status, attributes: $attributes, priority: $priority, reason: $reason, task_channel: $task_channel
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Workspaces/{WorkspaceSid}/Tasks/{TaskSid}/Reservations
#
# Returns: record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, reservations: table<account_sid: string, date_created: string, date_updated: string, links: record, reservation_status: string, sid: string, task_sid: string, url: string, worker_name: string, worker_sid: string, workspace_sid: string>>
# operationId: ListTaskReservation
export def "list-task-reservation" [
  workspace_sid: string
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
  --reservation-status: string@reservation-status-completer # Returns the list of reservations for a task with a specified ReservationStatus. Can be: `pending`, `accepted`, `rejected`, or `timeout`.
  --worker-sid: string # The SID of the reserved Worker resource to read.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/Workspaces/{WorkspaceSid}/Tasks/{TaskSid}/Reservations"
    path_params: [{name: WorkspaceSid, var: workspace_sid}, {name: TaskSid, var: task_sid}]
    query: [{name: ReservationStatus, var: reservation_status}, {name: WorkerSid, var: worker_sid}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://taskrouter.twilio.com"
    auth: basic
  } {
    workspace_sid: $workspace_sid, task_sid: $task_sid, reservation_status: $reservation_status, worker_sid: $worker_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Workspaces/{WorkspaceSid}/Tasks/{TaskSid}/Reservations/{Sid}
#
# Returns: record<account_sid: string, date_created: string, date_updated: string, links: record, reservation_status: string, sid: string, task_sid: string, url: string, worker_name: string, worker_sid: string, workspace_sid: string>
# operationId: FetchTaskReservation
export def "fetch-task-reservation" [
  workspace_sid: string
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
    path: "/v1/Workspaces/{WorkspaceSid}/Tasks/{TaskSid}/Reservations/{Sid}"
    path_params: [{name: WorkspaceSid, var: workspace_sid}, {name: TaskSid, var: task_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://taskrouter.twilio.com"
    auth: basic
  } {
    workspace_sid: $workspace_sid, task_sid: $task_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Workspaces/{WorkspaceSid}/Tasks/{TaskSid}/Reservations/{Sid}
#
# Returns: record<account_sid: string, date_created: string, date_updated: string, links: record, reservation_status: string, sid: string, task_sid: string, url: string, worker_name: string, worker_sid: string, workspace_sid: string>
# operationId: UpdateTaskReservation
export def "update-task-reservation" [
  workspace_sid: string
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
  --if-match: string # The If-Match HTTP request header
  --beep: string # Whether to play a notification beep when the participant joins or when to play a beep. Can be: `true`, `false`, `onEnter`, or `onExit`. The default value is `true`.
  --beep-on-customer-entrance: oneof<nothing, bool> # Whether to play a notification beep when the customer joins.
  --call-accept: oneof<nothing, bool> # Whether to accept a reservation when executing a Call instruction.
  --call-from: string # The Caller ID of the outbound call when executing a Call instruction.
  --call-record: string # Whether to record both legs of a call when executing a Call instruction or which leg to record.
  --call-status-callback-url: string # The URL to call for the completed call event when executing a Call instruction. (format: uri)
  --call-timeout: int # Timeout for call when executing a Call instruction.
  --call-to: string # The Contact URI of the worker when executing a Call instruction. Can be the URI of the Twilio Client, the SIP URI for Programmable SIP, or the [E.164](https://www.twilio.com/docs/glossary/what-e164) formatted phone number, depending on the destination.
  --call-url: string # TwiML URI executed on answering the worker's leg as a result of the Call instruction. (format: uri)
  --conference-record: string # Whether to record the conference the participant is joining or when to record the conference. Can be: `true`, `false`, `record-from-start`, and `do-not-record`. The default value is `false`.
  --conference-recording-status-callback: string # The URL we should call using the `conference_recording_status_callback_method` when the conference recording is available. (format: uri)
  --conference-recording-status-callback-method: string@conference-recording-status-callback-method-completer # The HTTP method we should use to call `conference_recording_status_callback`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --conference-status-callback: string # The URL we should call using the `conference_status_callback_method` when the conference events in `conference_status_callback_event` occur. Only the value set by the first participant to join the conference is used. Subsequent `conference_status_callback` values are ignored. (format: uri)
  --conference-status-callback-event: list<string> # The conference status events that we will send to `conference_status_callback`. Can be: `start`, `end`, `join`, `leave`, `mute`, `hold`, `speaker`.
  --conference-status-callback-method: string@conference-status-callback-method-completer # The HTTP method we should use to call `conference_status_callback`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --conference-trim: string # How to trim the leading and trailing silence from your recorded conference audio files. Can be: `trim-silence` or `do-not-trim` and defaults to `trim-silence`.
  --dequeue-from: string # The Caller ID of the call to the worker when executing a Dequeue instruction.
  --dequeue-post-work-activity-sid: string # The SID of the Activity resource to start after executing a Dequeue instruction.
  --dequeue-record: string # Whether to record both legs of a call when executing a Dequeue instruction or which leg to record.
  --dequeue-status-callback-event: list<string> # The Call progress events sent via webhooks as a result of a Dequeue instruction.
  --dequeue-status-callback-url: string # The Callback URL for completed call event when executing a Dequeue instruction. (format: uri)
  --dequeue-timeout: int # Timeout for call when executing a Dequeue instruction.
  --dequeue-to: string # The Contact URI of the worker when executing a Dequeue instruction. Can be the URI of the Twilio Client, the SIP URI for Programmable SIP, or the [E.164](https://www.twilio.com/docs/glossary/what-e164) formatted phone number, depending on the destination.
  --early-media: oneof<nothing, bool> # Whether to allow an agent to hear the state of the outbound call, including ringing or disconnect messages. The default is `true`.
  --end-conference-on-customer-exit: oneof<nothing, bool> # Whether to end the conference when the customer leaves.
  --end-conference-on-exit: oneof<nothing, bool> # Whether to end the conference when the agent leaves.
  --from: string # The Caller ID of the call to the worker when executing a Conference instruction.
  --instruction: string # The assignment instruction for reservation.
  --max-participants: int # The maximum number of participants in the conference. Can be a positive integer from `2` to `250`. The default value is `250`.
  --muted: oneof<nothing, bool> # Whether the agent is muted in the conference. The default is `false`.
  --post-work-activity-sid: string # The new worker activity SID after executing a Conference instruction.
  --record: oneof<nothing, bool> # Whether to record the participant and their conferences, including the time between conferences. The default is `false`.
  --recording-channels: string # The recording channels for the final recording. Can be: `mono` or `dual` and the default is `mono`.
  --recording-status-callback: string # The URL that we should call using the `recording_status_callback_method` when the recording status changes. (format: uri)
  --recording-status-callback-method: string@recording-status-callback-method-completer # The HTTP method we should use when we call `recording_status_callback`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --redirect-accept: oneof<nothing, bool> # Whether the reservation should be accepted when executing a Redirect instruction.
  --redirect-call-sid: string # The Call SID of the call parked in the queue when executing a Redirect instruction.
  --redirect-url: string # TwiML URI to redirect the call to when executing the Redirect instruction. (format: uri)
  --region: string # The [region](https://support.twilio.com/hc/en-us/articles/223132167-How-global-low-latency-routing-and-region-selection-work-for-conferences-and-Client-calls) where we should mix the recorded audio. Can be:`us1`, `ie1`, `de1`, `sg1`, `br1`, `au1`, or `jp1`.
  --reservation-status: string@reservation-status-completer
  --sip-auth-password: string # The SIP password for authentication.
  --sip-auth-username: string # The SIP username used for authentication.
  --start-conference-on-enter: oneof<nothing, bool> # Whether to start the conference when the participant joins, if it has not already started. The default is `true`. If `false` and the conference has not started, the participant is muted and hears background music until another participant starts the conference.
  --status-callback: string # The URL we should call using the `status_callback_method` to send status information to your application. (format: uri)
  --status-callback-event: list<string> # The call progress events that we will send to `status_callback`. Can be: `initiated`, `ringing`, `answered`, or `completed`.
  --status-callback-method: string@status-callback-method-completer # The HTTP method we should use to call `status_callback`. Can be: `POST` or `GET` and the default is `POST`. (format: http-method)
  --supervisor: string # The Supervisor SID/URI when executing the Supervise instruction.
  --supervisor-mode: string@supervisor-mode-completer
  --timeout: int # Timeout for call when executing a Conference instruction.
  --to: string # The Contact URI of the worker when executing a Conference instruction. Can be the URI of the Twilio Client, the SIP URI for Programmable SIP, or the [E.164](https://www.twilio.com/docs/glossary/what-e164) formatted phone number, depending on the destination.
  --wait-method: string@wait-method-completer # The HTTP method we should use to call `wait_url`. Can be `GET` or `POST` and the default is `POST`. When using a static audio file, this should be `GET` so that we can cache the file. (format: http-method)
  --wait-url: string # The URL we should call using the `wait_method` for the music to play while participants are waiting for the conference to start. The default value is the URL of our standard hold music. [Learn more about hold music](https://www.twilio.com/labs/twimlets/holdmusic). (format: uri)
  --worker-activity-sid: string # The new worker activity SID if rejecting a reservation.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Workspaces/{WorkspaceSid}/Tasks/{TaskSid}/Reservations/{Sid}"
    path_params: [{name: WorkspaceSid, var: workspace_sid}, {name: TaskSid, var: task_sid}, {name: Sid, var: sid}]
    header: [{name: If-Match, var: if_match}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Beep, var: beep}, {name: BeepOnCustomerEntrance, var: beep_on_customer_entrance}, {name: CallAccept, var: call_accept}, {name: CallFrom, var: call_from}, {name: CallRecord, var: call_record}, {name: CallStatusCallbackUrl, var: call_status_callback_url}, {name: CallTimeout, var: call_timeout}, {name: CallTo, var: call_to}, {name: CallUrl, var: call_url}, {name: ConferenceRecord, var: conference_record}, {name: ConferenceRecordingStatusCallback, var: conference_recording_status_callback}, {name: ConferenceRecordingStatusCallbackMethod, var: conference_recording_status_callback_method}, {name: ConferenceStatusCallback, var: conference_status_callback}, {name: ConferenceStatusCallbackEvent, var: conference_status_callback_event}, {name: ConferenceStatusCallbackMethod, var: conference_status_callback_method}, {name: ConferenceTrim, var: conference_trim}, {name: DequeueFrom, var: dequeue_from}, {name: DequeuePostWorkActivitySid, var: dequeue_post_work_activity_sid}, {name: DequeueRecord, var: dequeue_record}, {name: DequeueStatusCallbackEvent, var: dequeue_status_callback_event}, {name: DequeueStatusCallbackUrl, var: dequeue_status_callback_url}, {name: DequeueTimeout, var: dequeue_timeout}, {name: DequeueTo, var: dequeue_to}, {name: EarlyMedia, var: early_media}, {name: EndConferenceOnCustomerExit, var: end_conference_on_customer_exit}, {name: EndConferenceOnExit, var: end_conference_on_exit}, {name: From, var: from}, {name: Instruction, var: instruction}, {name: MaxParticipants, var: max_participants}, {name: Muted, var: muted}, {name: PostWorkActivitySid, var: post_work_activity_sid}, {name: Record, var: record}, {name: RecordingChannels, var: recording_channels}, {name: RecordingStatusCallback, var: recording_status_callback}, {name: RecordingStatusCallbackMethod, var: recording_status_callback_method}, {name: RedirectAccept, var: redirect_accept}, {name: RedirectCallSid, var: redirect_call_sid}, {name: RedirectUrl, var: redirect_url}, {name: Region, var: region}, {name: ReservationStatus, var: reservation_status}, {name: SipAuthPassword, var: sip_auth_password}, {name: SipAuthUsername, var: sip_auth_username}, {name: StartConferenceOnEnter, var: start_conference_on_enter}, {name: StatusCallback, var: status_callback}, {name: StatusCallbackEvent, var: status_callback_event}, {name: StatusCallbackMethod, var: status_callback_method}, {name: Supervisor, var: supervisor}, {name: SupervisorMode, var: supervisor_mode}, {name: Timeout, var: timeout}, {name: To, var: to}, {name: WaitMethod, var: wait_method}, {name: WaitUrl, var: wait_url}, {name: WorkerActivitySid, var: worker_activity_sid}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://taskrouter.twilio.com"
    auth: basic
  } {
    workspace_sid: $workspace_sid, task_sid: $task_sid, sid: $sid, if_match: $if_match, beep: $beep, beep_on_customer_entrance: $beep_on_customer_entrance, call_accept: $call_accept, call_from: $call_from, call_record: $call_record, call_status_callback_url: $call_status_callback_url, call_timeout: $call_timeout, call_to: $call_to, call_url: $call_url, conference_record: $conference_record, conference_recording_status_callback: $conference_recording_status_callback, conference_recording_status_callback_method: $conference_recording_status_callback_method, conference_status_callback: $conference_status_callback, conference_status_callback_event: $conference_status_callback_event, conference_status_callback_method: $conference_status_callback_method, conference_trim: $conference_trim, dequeue_from: $dequeue_from, dequeue_post_work_activity_sid: $dequeue_post_work_activity_sid, dequeue_record: $dequeue_record, dequeue_status_callback_event: $dequeue_status_callback_event, dequeue_status_callback_url: $dequeue_status_callback_url, dequeue_timeout: $dequeue_timeout, dequeue_to: $dequeue_to, early_media: $early_media, end_conference_on_customer_exit: $end_conference_on_customer_exit, end_conference_on_exit: $end_conference_on_exit, from: $from, instruction: $instruction, max_participants: $max_participants, muted: $muted, post_work_activity_sid: $post_work_activity_sid, record: $record, recording_channels: $recording_channels, recording_status_callback: $recording_status_callback, recording_status_callback_method: $recording_status_callback_method, redirect_accept: $redirect_accept, redirect_call_sid: $redirect_call_sid, redirect_url: $redirect_url, region: $region, reservation_status: $reservation_status, sip_auth_password: $sip_auth_password, sip_auth_username: $sip_auth_username, start_conference_on_enter: $start_conference_on_enter, status_callback: $status_callback, status_callback_event: $status_callback_event, status_callback_method: $status_callback_method, supervisor: $supervisor, supervisor_mode: $supervisor_mode, timeout: $timeout, to: $to, wait_method: $wait_method, wait_url: $wait_url, worker_activity_sid: $worker_activity_sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Workspaces/{WorkspaceSid}/Workers
#
# Returns: record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, workers: table<account_sid: string, activity_name: string, activity_sid: string, attributes: string, available: bool, date_created: string, date_status_changed: string, date_updated: string, friendly_name: string, links: record, sid: string, url: string, workspace_sid: string>>
# operationId: ListWorker
export def "list-worker" [
  workspace_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --activity-name: string # The `activity_name` of the Worker resources to read.
  --activity-sid: string # The `activity_sid` of the Worker resources to read.
  --available: string # Whether to return only Worker resources that are available or unavailable. Can be `true`, `1`, or `yes` to return Worker resources that are available, and `false`, or any value returns the Worker resources that are not available.
  --friendly-name: string # The `friendly_name` of the Worker resources to read.
  --target-workers-expression: string # Filter by Workers that would match an expression on a TaskQueue. This is helpful for debugging which Workers would match a potential queue.
  --task-queue-name: string # The `friendly_name` of the TaskQueue that the Workers to read are eligible for.
  --task-queue-sid: string # The SID of the TaskQueue that the Workers to read are eligible for.
  --ordering: string # Sorting parameter for Workers
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/Workspaces/{WorkspaceSid}/Workers"
    path_params: [{name: WorkspaceSid, var: workspace_sid}]
    query: [{name: ActivityName, var: activity_name}, {name: ActivitySid, var: activity_sid}, {name: Available, var: available}, {name: FriendlyName, var: friendly_name}, {name: TargetWorkersExpression, var: target_workers_expression}, {name: TaskQueueName, var: task_queue_name}, {name: TaskQueueSid, var: task_queue_sid}, {name: Ordering, var: ordering}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://taskrouter.twilio.com"
    auth: basic
  } {
    workspace_sid: $workspace_sid, activity_name: $activity_name, activity_sid: $activity_sid, available: $available, friendly_name: $friendly_name, target_workers_expression: $target_workers_expression, task_queue_name: $task_queue_name, task_queue_sid: $task_queue_sid, ordering: $ordering, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Workspaces/{WorkspaceSid}/Workers
#
# Returns: record<account_sid: string, activity_name: string, activity_sid: string, attributes: string, available: bool, date_created: string, date_status_changed: string, date_updated: string, friendly_name: string, links: record, sid: string, url: string, workspace_sid: string>
# operationId: CreateWorker
export def "create-worker" [
  workspace_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --activity-sid: string # The SID of a valid Activity that will describe the new Worker's initial state. See [Activities](https://www.twilio.com/docs/taskrouter/api/activity) for more information. If not provided, the new Worker's initial state is the `default_activity_sid` configured on the Workspace.
  --attributes: string # A valid JSON string that describes the new Worker. For example: `{ "email": "Bob@example.com", "phone": "+5095551234" }`. This data is passed to the `assignment_callback_url` when TaskRouter assigns a Task to the Worker. Defaults to {}.
  friendly_name: string # A descriptive string that you create to describe the new Worker. It can be up to 64 characters long.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Workspaces/{WorkspaceSid}/Workers"
    path_params: [{name: WorkspaceSid, var: workspace_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: ActivitySid, var: activity_sid}, {name: Attributes, var: attributes}, {name: FriendlyName, var: friendly_name}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://taskrouter.twilio.com"
    auth: basic
  } {
    workspace_sid: $workspace_sid, activity_sid: $activity_sid, attributes: $attributes, friendly_name: $friendly_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Workspaces/{WorkspaceSid}/Workers/CumulativeStatistics
#
# Returns: record<account_sid: string, activity_durations: list<any>, end_time: string, reservations_accepted: int, reservations_canceled: int, reservations_created: int, reservations_rejected: int, reservations_rescinded: int, reservations_timed_out: int, start_time: string, url: string, workspace_sid: string>
# operationId: FetchWorkersCumulativeStatistics
export def "fetch-workers-cumulative-statistics" [
  workspace_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --end-date: string # Only calculate statistics from this date and time and earlier, specified in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format. (format: date-time)
  --minutes: int # Only calculate statistics since this many minutes in the past. The default 15 minutes. This is helpful for displaying statistics for the last 15 minutes, 240 minutes (4 hours), and 480 minutes (8 hours) to see trends.
  --start-date: string # Only calculate statistics from this date and time and later, specified in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format. (format: date-time)
  --task-channel: string # Only calculate cumulative statistics on this TaskChannel. Can be the TaskChannel's SID or its `unique_name`, such as `voice`, `sms`, or `default`.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/Workspaces/{WorkspaceSid}/Workers/CumulativeStatistics"
    path_params: [{name: WorkspaceSid, var: workspace_sid}]
    query: [{name: EndDate, var: end_date}, {name: Minutes, var: minutes}, {name: StartDate, var: start_date}, {name: TaskChannel, var: task_channel}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://taskrouter.twilio.com"
    auth: basic
  } {
    workspace_sid: $workspace_sid, end_date: $end_date, minutes: $minutes, start_date: $start_date, task_channel: $task_channel
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Workspaces/{WorkspaceSid}/Workers/RealTimeStatistics
#
# Returns: record<account_sid: string, activity_statistics: list<any>, total_workers: int, url: string, workspace_sid: string>
# operationId: FetchWorkersRealTimeStatistics
export def "fetch-workers-real-time-statistics" [
  workspace_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --task-channel: string # Only calculate real-time statistics on this TaskChannel. Can be the TaskChannel's SID or its `unique_name`, such as `voice`, `sms`, or `default`.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/Workspaces/{WorkspaceSid}/Workers/RealTimeStatistics"
    path_params: [{name: WorkspaceSid, var: workspace_sid}]
    query: [{name: TaskChannel, var: task_channel}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://taskrouter.twilio.com"
    auth: basic
  } {
    workspace_sid: $workspace_sid, task_channel: $task_channel
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Workspaces/{WorkspaceSid}/Workers/Statistics
#
# Returns: record<account_sid: string, cumulative: any, realtime: any, url: string, workspace_sid: string>
# operationId: FetchWorkerStatistics
export def "fetch-worker-statistics" [
  workspace_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --minutes: int # Only calculate statistics since this many minutes in the past. The default 15 minutes. This is helpful for displaying statistics for the last 15 minutes, 240 minutes (4 hours), and 480 minutes (8 hours) to see trends.
  --start-date: string # Only calculate statistics from this date and time and later, specified in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format. (format: date-time)
  --end-date: string # Only calculate statistics from this date and time and earlier, specified in GMT as an [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) date-time. (format: date-time)
  --task-queue-sid: string # The SID of the TaskQueue for which to fetch Worker statistics.
  --task-queue-name: string # The `friendly_name` of the TaskQueue for which to fetch Worker statistics.
  --friendly-name: string # Only include Workers with `friendly_name` values that match this parameter.
  --task-channel: string # Only calculate statistics on this TaskChannel. Can be the TaskChannel's SID or its `unique_name`, such as `voice`, `sms`, or `default`.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/Workspaces/{WorkspaceSid}/Workers/Statistics"
    path_params: [{name: WorkspaceSid, var: workspace_sid}]
    query: [{name: Minutes, var: minutes}, {name: StartDate, var: start_date}, {name: EndDate, var: end_date}, {name: TaskQueueSid, var: task_queue_sid}, {name: TaskQueueName, var: task_queue_name}, {name: FriendlyName, var: friendly_name}, {name: TaskChannel, var: task_channel}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://taskrouter.twilio.com"
    auth: basic
  } {
    workspace_sid: $workspace_sid, minutes: $minutes, start_date: $start_date, end_date: $end_date, task_queue_sid: $task_queue_sid, task_queue_name: $task_queue_name, friendly_name: $friendly_name, task_channel: $task_channel
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/Workspaces/{WorkspaceSid}/Workers/{Sid}
#
# operationId: DeleteWorker
export def "delete-worker" [
  workspace_sid: string
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
  --if-match: string # The If-Match HTTP request header
]: nothing -> any {
  http-request {
    method: delete
    path: "/v1/Workspaces/{WorkspaceSid}/Workers/{Sid}"
    path_params: [{name: WorkspaceSid, var: workspace_sid}, {name: Sid, var: sid}]
    header: [{name: If-Match, var: if_match}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://taskrouter.twilio.com"
    auth: basic
  } {
    workspace_sid: $workspace_sid, sid: $sid, if_match: $if_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Workspaces/{WorkspaceSid}/Workers/{Sid}
#
# Returns: record<account_sid: string, activity_name: string, activity_sid: string, attributes: string, available: bool, date_created: string, date_status_changed: string, date_updated: string, friendly_name: string, links: record, sid: string, url: string, workspace_sid: string>
# operationId: FetchWorker
export def "fetch-worker" [
  workspace_sid: string
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
    path: "/v1/Workspaces/{WorkspaceSid}/Workers/{Sid}"
    path_params: [{name: WorkspaceSid, var: workspace_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://taskrouter.twilio.com"
    auth: basic
  } {
    workspace_sid: $workspace_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Workspaces/{WorkspaceSid}/Workers/{Sid}
#
# Returns: record<account_sid: string, activity_name: string, activity_sid: string, attributes: string, available: bool, date_created: string, date_status_changed: string, date_updated: string, friendly_name: string, links: record, sid: string, url: string, workspace_sid: string>
# operationId: UpdateWorker
export def "update-worker" [
  workspace_sid: string
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
  --if-match: string # The If-Match HTTP request header
  --activity-sid: string # The SID of a valid Activity that will describe the Worker's initial state. See [Activities](https://www.twilio.com/docs/taskrouter/api/activity) for more information.
  --attributes: string # The JSON string that describes the Worker. For example: `{ "email": "Bob@example.com", "phone": "+5095551234" }`. This data is passed to the `assignment_callback_url` when TaskRouter assigns a Task to the Worker. Defaults to {}.
  --friendly-name: string # A descriptive string that you create to describe the Worker. It can be up to 64 characters long.
  --reject-pending-reservations: oneof<nothing, bool> # Whether to reject the Worker's pending reservations. This option is only valid if the Worker's new [Activity](https://www.twilio.com/docs/taskrouter/api/activity) resource has its `availability` property set to `False`.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Workspaces/{WorkspaceSid}/Workers/{Sid}"
    path_params: [{name: WorkspaceSid, var: workspace_sid}, {name: Sid, var: sid}]
    header: [{name: If-Match, var: if_match}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: ActivitySid, var: activity_sid}, {name: Attributes, var: attributes}, {name: FriendlyName, var: friendly_name}, {name: RejectPendingReservations, var: reject_pending_reservations}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://taskrouter.twilio.com"
    auth: basic
  } {
    workspace_sid: $workspace_sid, sid: $sid, if_match: $if_match, activity_sid: $activity_sid, attributes: $attributes, friendly_name: $friendly_name, reject_pending_reservations: $reject_pending_reservations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Workspaces/{WorkspaceSid}/Workers/{WorkerSid}/Channels
#
# Returns: record<channels: table<account_sid: string, assigned_tasks: int, available: bool, available_capacity_percentage: int, configured_capacity: int, date_created: string, date_updated: string, sid: string, task_channel_sid: string, task_channel_unique_name: string, url: string, worker_sid: string, workspace_sid: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListWorkerChannel
export def "list-worker-channel" [
  workspace_sid: string
  worker_sid: string
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
    path: "/v1/Workspaces/{WorkspaceSid}/Workers/{WorkerSid}/Channels"
    path_params: [{name: WorkspaceSid, var: workspace_sid}, {name: WorkerSid, var: worker_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://taskrouter.twilio.com"
    auth: basic
  } {
    workspace_sid: $workspace_sid, worker_sid: $worker_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Workspaces/{WorkspaceSid}/Workers/{WorkerSid}/Channels/{Sid}
#
# Returns: record<account_sid: string, assigned_tasks: int, available: bool, available_capacity_percentage: int, configured_capacity: int, date_created: string, date_updated: string, sid: string, task_channel_sid: string, task_channel_unique_name: string, url: string, worker_sid: string, workspace_sid: string>
# operationId: FetchWorkerChannel
export def "fetch-worker-channel" [
  workspace_sid: string
  worker_sid: string
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
    path: "/v1/Workspaces/{WorkspaceSid}/Workers/{WorkerSid}/Channels/{Sid}"
    path_params: [{name: WorkspaceSid, var: workspace_sid}, {name: WorkerSid, var: worker_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://taskrouter.twilio.com"
    auth: basic
  } {
    workspace_sid: $workspace_sid, worker_sid: $worker_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Workspaces/{WorkspaceSid}/Workers/{WorkerSid}/Channels/{Sid}
#
# Returns: record<account_sid: string, assigned_tasks: int, available: bool, available_capacity_percentage: int, configured_capacity: int, date_created: string, date_updated: string, sid: string, task_channel_sid: string, task_channel_unique_name: string, url: string, worker_sid: string, workspace_sid: string>
# operationId: UpdateWorkerChannel
export def "update-worker-channel" [
  workspace_sid: string
  worker_sid: string
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
  --available: oneof<nothing, bool> # Whether the WorkerChannel is available. Set to `false` to prevent the Worker from receiving any new Tasks of this TaskChannel type.
  --capacity: int # The total number of Tasks that the Worker should handle for the TaskChannel type. TaskRouter creates reservations for Tasks of this TaskChannel type up to the specified capacity. If the capacity is 0, no new reservations will be created.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Workspaces/{WorkspaceSid}/Workers/{WorkerSid}/Channels/{Sid}"
    path_params: [{name: WorkspaceSid, var: workspace_sid}, {name: WorkerSid, var: worker_sid}, {name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Available, var: available}, {name: Capacity, var: capacity}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://taskrouter.twilio.com"
    auth: basic
  } {
    workspace_sid: $workspace_sid, worker_sid: $worker_sid, sid: $sid, available: $available, capacity: $capacity
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Workspaces/{WorkspaceSid}/Workers/{WorkerSid}/Reservations
#
# Returns: record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, reservations: table<account_sid: string, date_created: string, date_updated: string, links: record, reservation_status: string, sid: string, task_sid: string, url: string, worker_name: string, worker_sid: string, workspace_sid: string>>
# operationId: ListWorkerReservation
export def "list-worker-reservation" [
  workspace_sid: string
  worker_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --reservation-status: string@reservation-status-completer # Returns the list of reservations for a worker with a specified ReservationStatus. Can be: `pending`, `accepted`, `rejected`, `timeout`, `canceled`, or `rescinded`.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/Workspaces/{WorkspaceSid}/Workers/{WorkerSid}/Reservations"
    path_params: [{name: WorkspaceSid, var: workspace_sid}, {name: WorkerSid, var: worker_sid}]
    query: [{name: ReservationStatus, var: reservation_status}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://taskrouter.twilio.com"
    auth: basic
  } {
    workspace_sid: $workspace_sid, worker_sid: $worker_sid, reservation_status: $reservation_status, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Workspaces/{WorkspaceSid}/Workers/{WorkerSid}/Reservations/{Sid}
#
# Returns: record<account_sid: string, date_created: string, date_updated: string, links: record, reservation_status: string, sid: string, task_sid: string, url: string, worker_name: string, worker_sid: string, workspace_sid: string>
# operationId: FetchWorkerReservation
export def "fetch-worker-reservation" [
  workspace_sid: string
  worker_sid: string
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
    path: "/v1/Workspaces/{WorkspaceSid}/Workers/{WorkerSid}/Reservations/{Sid}"
    path_params: [{name: WorkspaceSid, var: workspace_sid}, {name: WorkerSid, var: worker_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://taskrouter.twilio.com"
    auth: basic
  } {
    workspace_sid: $workspace_sid, worker_sid: $worker_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Workspaces/{WorkspaceSid}/Workers/{WorkerSid}/Reservations/{Sid}
#
# Returns: record<account_sid: string, date_created: string, date_updated: string, links: record, reservation_status: string, sid: string, task_sid: string, url: string, worker_name: string, worker_sid: string, workspace_sid: string>
# operationId: UpdateWorkerReservation
export def "update-worker-reservation" [
  workspace_sid: string
  worker_sid: string
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
  --if-match: string # The If-Match HTTP request header
  --beep: string # Whether to play a notification beep when the participant joins or when to play a beep. Can be: `true`, `false`, `onEnter`, or `onExit`. The default value is `true`.
  --beep-on-customer-entrance: oneof<nothing, bool> # Whether to play a notification beep when the customer joins.
  --call-accept: oneof<nothing, bool> # Whether to accept a reservation when executing a Call instruction.
  --call-from: string # The Caller ID of the outbound call when executing a Call instruction.
  --call-record: string # Whether to record both legs of a call when executing a Call instruction.
  --call-status-callback-url: string # The URL to call for the completed call event when executing a Call instruction. (format: uri)
  --call-timeout: int # The timeout for a call when executing a Call instruction.
  --call-to: string # The contact URI of the worker when executing a Call instruction. Can be the URI of the Twilio Client, the SIP URI for Programmable SIP, or the [E.164](https://www.twilio.com/docs/glossary/what-e164) formatted phone number, depending on the destination.
  --call-url: string # TwiML URI executed on answering the worker's leg as a result of the Call instruction. (format: uri)
  --conference-record: string # Whether to record the conference the participant is joining or when to record the conference. Can be: `true`, `false`, `record-from-start`, and `do-not-record`. The default value is `false`.
  --conference-recording-status-callback: string # The URL we should call using the `conference_recording_status_callback_method` when the conference recording is available. (format: uri)
  --conference-recording-status-callback-method: string@conference-recording-status-callback-method-completer # The HTTP method we should use to call `conference_recording_status_callback`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --conference-status-callback: string # The URL we should call using the `conference_status_callback_method` when the conference events in `conference_status_callback_event` occur. Only the value set by the first participant to join the conference is used. Subsequent `conference_status_callback` values are ignored. (format: uri)
  --conference-status-callback-event: list<string> # The conference status events that we will send to `conference_status_callback`. Can be: `start`, `end`, `join`, `leave`, `mute`, `hold`, `speaker`.
  --conference-status-callback-method: string@conference-status-callback-method-completer # The HTTP method we should use to call `conference_status_callback`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --conference-trim: string # Whether to trim leading and trailing silence from your recorded conference audio files. Can be: `trim-silence` or `do-not-trim` and defaults to `trim-silence`.
  --dequeue-from: string # The caller ID of the call to the worker when executing a Dequeue instruction.
  --dequeue-post-work-activity-sid: string # The SID of the Activity resource to start after executing a Dequeue instruction.
  --dequeue-record: string # Whether to record both legs of a call when executing a Dequeue instruction or which leg to record.
  --dequeue-status-callback-event: list<string> # The call progress events sent via webhooks as a result of a Dequeue instruction.
  --dequeue-status-callback-url: string # The callback URL for completed call event when executing a Dequeue instruction. (format: uri)
  --dequeue-timeout: int # The timeout for call when executing a Dequeue instruction.
  --dequeue-to: string # The contact URI of the worker when executing a Dequeue instruction. Can be the URI of the Twilio Client, the SIP URI for Programmable SIP, or the [E.164](https://www.twilio.com/docs/glossary/what-e164) formatted phone number, depending on the destination.
  --early-media: oneof<nothing, bool> # Whether to allow an agent to hear the state of the outbound call, including ringing or disconnect messages. The default is `true`.
  --end-conference-on-customer-exit: oneof<nothing, bool> # Whether to end the conference when the customer leaves.
  --end-conference-on-exit: oneof<nothing, bool> # Whether to end the conference when the agent leaves.
  --from: string # The caller ID of the call to the worker when executing a Conference instruction.
  --instruction: string # The assignment instruction for the reservation.
  --max-participants: int # The maximum number of participants allowed in the conference. Can be a positive integer from `2` to `250`. The default value is `250`.
  --muted: oneof<nothing, bool> # Whether the agent is muted in the conference. Defaults to `false`.
  --post-work-activity-sid: string # The new worker activity SID after executing a Conference instruction.
  --record: oneof<nothing, bool> # Whether to record the participant and their conferences, including the time between conferences. Can be `true` or `false` and the default is `false`.
  --recording-channels: string # The recording channels for the final recording. Can be: `mono` or `dual` and the default is `mono`.
  --recording-status-callback: string # The URL that we should call using the `recording_status_callback_method` when the recording status changes. (format: uri)
  --recording-status-callback-method: string@recording-status-callback-method-completer # The HTTP method we should use when we call `recording_status_callback`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --redirect-accept: oneof<nothing, bool> # Whether the reservation should be accepted when executing a Redirect instruction.
  --redirect-call-sid: string # The Call SID of the call parked in the queue when executing a Redirect instruction.
  --redirect-url: string # TwiML URI to redirect the call to when executing the Redirect instruction. (format: uri)
  --region: string # The [region](https://support.twilio.com/hc/en-us/articles/223132167-How-global-low-latency-routing-and-region-selection-work-for-conferences-and-Client-calls) where we should mix the recorded audio. Can be:`us1`, `ie1`, `de1`, `sg1`, `br1`, `au1`, or `jp1`.
  --reservation-status: string@reservation-status-completer
  --sip-auth-password: string # The SIP password for authentication.
  --sip-auth-username: string # The SIP username used for authentication.
  --start-conference-on-enter: oneof<nothing, bool> # Whether to start the conference when the participant joins, if it has not already started. Can be: `true` or `false` and the default is `true`. If `false` and the conference has not started, the participant is muted and hears background music until another participant starts the conference.
  --status-callback: string # The URL we should call using the `status_callback_method` to send status information to your application. (format: uri)
  --status-callback-event: list<string> # The call progress events that we will send to `status_callback`. Can be: `initiated`, `ringing`, `answered`, or `completed`.
  --status-callback-method: string@status-callback-method-completer # The HTTP method we should use to call `status_callback`. Can be: `POST` or `GET` and the default is `POST`. (format: http-method)
  --timeout: int # The timeout for a call when executing a Conference instruction.
  --to: string # The Contact URI of the worker when executing a Conference instruction. Can be the URI of the Twilio Client, the SIP URI for Programmable SIP, or the [E.164](https://www.twilio.com/docs/glossary/what-e164) formatted phone number, depending on the destination.
  --wait-method: string@wait-method-completer # The HTTP method we should use to call `wait_url`. Can be `GET` or `POST` and the default is `POST`. When using a static audio file, this should be `GET` so that we can cache the file. (format: http-method)
  --wait-url: string # The URL we should call using the `wait_method` for the music to play while participants are waiting for the conference to start. The default value is the URL of our standard hold music. [Learn more about hold music](https://www.twilio.com/labs/twimlets/holdmusic). (format: uri)
  --worker-activity-sid: string # The new worker activity SID if rejecting a reservation.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Workspaces/{WorkspaceSid}/Workers/{WorkerSid}/Reservations/{Sid}"
    path_params: [{name: WorkspaceSid, var: workspace_sid}, {name: WorkerSid, var: worker_sid}, {name: Sid, var: sid}]
    header: [{name: If-Match, var: if_match}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Beep, var: beep}, {name: BeepOnCustomerEntrance, var: beep_on_customer_entrance}, {name: CallAccept, var: call_accept}, {name: CallFrom, var: call_from}, {name: CallRecord, var: call_record}, {name: CallStatusCallbackUrl, var: call_status_callback_url}, {name: CallTimeout, var: call_timeout}, {name: CallTo, var: call_to}, {name: CallUrl, var: call_url}, {name: ConferenceRecord, var: conference_record}, {name: ConferenceRecordingStatusCallback, var: conference_recording_status_callback}, {name: ConferenceRecordingStatusCallbackMethod, var: conference_recording_status_callback_method}, {name: ConferenceStatusCallback, var: conference_status_callback}, {name: ConferenceStatusCallbackEvent, var: conference_status_callback_event}, {name: ConferenceStatusCallbackMethod, var: conference_status_callback_method}, {name: ConferenceTrim, var: conference_trim}, {name: DequeueFrom, var: dequeue_from}, {name: DequeuePostWorkActivitySid, var: dequeue_post_work_activity_sid}, {name: DequeueRecord, var: dequeue_record}, {name: DequeueStatusCallbackEvent, var: dequeue_status_callback_event}, {name: DequeueStatusCallbackUrl, var: dequeue_status_callback_url}, {name: DequeueTimeout, var: dequeue_timeout}, {name: DequeueTo, var: dequeue_to}, {name: EarlyMedia, var: early_media}, {name: EndConferenceOnCustomerExit, var: end_conference_on_customer_exit}, {name: EndConferenceOnExit, var: end_conference_on_exit}, {name: From, var: from}, {name: Instruction, var: instruction}, {name: MaxParticipants, var: max_participants}, {name: Muted, var: muted}, {name: PostWorkActivitySid, var: post_work_activity_sid}, {name: Record, var: record}, {name: RecordingChannels, var: recording_channels}, {name: RecordingStatusCallback, var: recording_status_callback}, {name: RecordingStatusCallbackMethod, var: recording_status_callback_method}, {name: RedirectAccept, var: redirect_accept}, {name: RedirectCallSid, var: redirect_call_sid}, {name: RedirectUrl, var: redirect_url}, {name: Region, var: region}, {name: ReservationStatus, var: reservation_status}, {name: SipAuthPassword, var: sip_auth_password}, {name: SipAuthUsername, var: sip_auth_username}, {name: StartConferenceOnEnter, var: start_conference_on_enter}, {name: StatusCallback, var: status_callback}, {name: StatusCallbackEvent, var: status_callback_event}, {name: StatusCallbackMethod, var: status_callback_method}, {name: Timeout, var: timeout}, {name: To, var: to}, {name: WaitMethod, var: wait_method}, {name: WaitUrl, var: wait_url}, {name: WorkerActivitySid, var: worker_activity_sid}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://taskrouter.twilio.com"
    auth: basic
  } {
    workspace_sid: $workspace_sid, worker_sid: $worker_sid, sid: $sid, if_match: $if_match, beep: $beep, beep_on_customer_entrance: $beep_on_customer_entrance, call_accept: $call_accept, call_from: $call_from, call_record: $call_record, call_status_callback_url: $call_status_callback_url, call_timeout: $call_timeout, call_to: $call_to, call_url: $call_url, conference_record: $conference_record, conference_recording_status_callback: $conference_recording_status_callback, conference_recording_status_callback_method: $conference_recording_status_callback_method, conference_status_callback: $conference_status_callback, conference_status_callback_event: $conference_status_callback_event, conference_status_callback_method: $conference_status_callback_method, conference_trim: $conference_trim, dequeue_from: $dequeue_from, dequeue_post_work_activity_sid: $dequeue_post_work_activity_sid, dequeue_record: $dequeue_record, dequeue_status_callback_event: $dequeue_status_callback_event, dequeue_status_callback_url: $dequeue_status_callback_url, dequeue_timeout: $dequeue_timeout, dequeue_to: $dequeue_to, early_media: $early_media, end_conference_on_customer_exit: $end_conference_on_customer_exit, end_conference_on_exit: $end_conference_on_exit, from: $from, instruction: $instruction, max_participants: $max_participants, muted: $muted, post_work_activity_sid: $post_work_activity_sid, record: $record, recording_channels: $recording_channels, recording_status_callback: $recording_status_callback, recording_status_callback_method: $recording_status_callback_method, redirect_accept: $redirect_accept, redirect_call_sid: $redirect_call_sid, redirect_url: $redirect_url, region: $region, reservation_status: $reservation_status, sip_auth_password: $sip_auth_password, sip_auth_username: $sip_auth_username, start_conference_on_enter: $start_conference_on_enter, status_callback: $status_callback, status_callback_event: $status_callback_event, status_callback_method: $status_callback_method, timeout: $timeout, to: $to, wait_method: $wait_method, wait_url: $wait_url, worker_activity_sid: $worker_activity_sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Workspaces/{WorkspaceSid}/Workers/{WorkerSid}/Statistics
#
# Returns: record<account_sid: string, cumulative: any, url: string, worker_sid: string, workspace_sid: string>
# operationId: FetchWorkerInstanceStatistics
export def "fetch-worker-instance-statistics" [
  workspace_sid: string
  worker_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --minutes: int # Only calculate statistics since this many minutes in the past. The default 15 minutes. This is helpful for displaying statistics for the last 15 minutes, 240 minutes (4 hours), and 480 minutes (8 hours) to see trends.
  --start-date: string # Only calculate statistics from this date and time and later, specified in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format. (format: date-time)
  --end-date: string # Only include usage that occurred on or before this date, specified in GMT as an [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) date-time. (format: date-time)
  --task-channel: string # Only calculate statistics on this TaskChannel. Can be the TaskChannel's SID or its `unique_name`, such as `voice`, `sms`, or `default`.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/Workspaces/{WorkspaceSid}/Workers/{WorkerSid}/Statistics"
    path_params: [{name: WorkspaceSid, var: workspace_sid}, {name: WorkerSid, var: worker_sid}]
    query: [{name: Minutes, var: minutes}, {name: StartDate, var: start_date}, {name: EndDate, var: end_date}, {name: TaskChannel, var: task_channel}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://taskrouter.twilio.com"
    auth: basic
  } {
    workspace_sid: $workspace_sid, worker_sid: $worker_sid, minutes: $minutes, start_date: $start_date, end_date: $end_date, task_channel: $task_channel
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Workspaces/{WorkspaceSid}/Workflows
#
# Returns: record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, workflows: table<account_sid: string, assignment_callback_url: string, configuration: string, date_created: string, date_updated: string, document_content_type: string, fallback_assignment_callback_url: string, friendly_name: string, links: record, sid: string, task_reservation_timeout: int, url: string, workspace_sid: string>>
# operationId: ListWorkflow
export def "list-workflow" [
  workspace_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --friendly-name: string # The `friendly_name` of the Workflow resources to read.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/Workspaces/{WorkspaceSid}/Workflows"
    path_params: [{name: WorkspaceSid, var: workspace_sid}]
    query: [{name: FriendlyName, var: friendly_name}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://taskrouter.twilio.com"
    auth: basic
  } {
    workspace_sid: $workspace_sid, friendly_name: $friendly_name, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Workspaces/{WorkspaceSid}/Workflows
#
# Returns: record<account_sid: string, assignment_callback_url: string, configuration: string, date_created: string, date_updated: string, document_content_type: string, fallback_assignment_callback_url: string, friendly_name: string, links: record, sid: string, task_reservation_timeout: int, url: string, workspace_sid: string>
# operationId: CreateWorkflow
export def "create-workflow" [
  workspace_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --assignment-callback-url: string # The URL from your application that will process task assignment events. See [Handling Task Assignment Callback](https://www.twilio.com/docs/taskrouter/handle-assignment-callbacks) for more details. (format: uri)
  configuration: string # A JSON string that contains the rules to apply to the Workflow. See [Configuring Workflows](https://www.twilio.com/docs/taskrouter/workflow-configuration) for more information.
  --fallback-assignment-callback-url: string # The URL that we should call when a call to the `assignment_callback_url` fails. (format: uri)
  friendly_name: string # A descriptive string that you create to describe the Workflow resource. For example, `Inbound Call Workflow` or `2014 Outbound Campaign`.
  --task-reservation-timeout: int # How long TaskRouter will wait for a confirmation response from your application after it assigns a Task to a Worker. Can be up to `86,400` (24 hours) and the default is `120`.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Workspaces/{WorkspaceSid}/Workflows"
    path_params: [{name: WorkspaceSid, var: workspace_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: AssignmentCallbackUrl, var: assignment_callback_url}, {name: Configuration, var: configuration}, {name: FallbackAssignmentCallbackUrl, var: fallback_assignment_callback_url}, {name: FriendlyName, var: friendly_name}, {name: TaskReservationTimeout, var: task_reservation_timeout}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://taskrouter.twilio.com"
    auth: basic
  } {
    workspace_sid: $workspace_sid, assignment_callback_url: $assignment_callback_url, configuration: $configuration, fallback_assignment_callback_url: $fallback_assignment_callback_url, friendly_name: $friendly_name, task_reservation_timeout: $task_reservation_timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/Workspaces/{WorkspaceSid}/Workflows/{Sid}
#
# operationId: DeleteWorkflow
export def "delete-workflow" [
  workspace_sid: string
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
    path: "/v1/Workspaces/{WorkspaceSid}/Workflows/{Sid}"
    path_params: [{name: WorkspaceSid, var: workspace_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://taskrouter.twilio.com"
    auth: basic
  } {
    workspace_sid: $workspace_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Workspaces/{WorkspaceSid}/Workflows/{Sid}
#
# Returns: record<account_sid: string, assignment_callback_url: string, configuration: string, date_created: string, date_updated: string, document_content_type: string, fallback_assignment_callback_url: string, friendly_name: string, links: record, sid: string, task_reservation_timeout: int, url: string, workspace_sid: string>
# operationId: FetchWorkflow
export def "fetch-workflow" [
  workspace_sid: string
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
    path: "/v1/Workspaces/{WorkspaceSid}/Workflows/{Sid}"
    path_params: [{name: WorkspaceSid, var: workspace_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://taskrouter.twilio.com"
    auth: basic
  } {
    workspace_sid: $workspace_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Workspaces/{WorkspaceSid}/Workflows/{Sid}
#
# Returns: record<account_sid: string, assignment_callback_url: string, configuration: string, date_created: string, date_updated: string, document_content_type: string, fallback_assignment_callback_url: string, friendly_name: string, links: record, sid: string, task_reservation_timeout: int, url: string, workspace_sid: string>
# operationId: UpdateWorkflow
export def "update-workflow" [
  workspace_sid: string
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
  --assignment-callback-url: string # The URL from your application that will process task assignment events. See [Handling Task Assignment Callback](https://www.twilio.com/docs/taskrouter/handle-assignment-callbacks) for more details. (format: uri)
  --configuration: string # A JSON string that contains the rules to apply to the Workflow. See [Configuring Workflows](https://www.twilio.com/docs/taskrouter/workflow-configuration) for more information.
  --fallback-assignment-callback-url: string # The URL that we should call when a call to the `assignment_callback_url` fails. (format: uri)
  --friendly-name: string # A descriptive string that you create to describe the Workflow resource. For example, `Inbound Call Workflow` or `2014 Outbound Campaign`.
  --re-evaluate-tasks: string # Whether or not to re-evaluate Tasks. The default is `false`, which means Tasks in the Workflow will not be processed through the assignment loop again.
  --task-reservation-timeout: int # How long TaskRouter will wait for a confirmation response from your application after it assigns a Task to a Worker. Can be up to `86,400` (24 hours) and the default is `120`.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Workspaces/{WorkspaceSid}/Workflows/{Sid}"
    path_params: [{name: WorkspaceSid, var: workspace_sid}, {name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: AssignmentCallbackUrl, var: assignment_callback_url}, {name: Configuration, var: configuration}, {name: FallbackAssignmentCallbackUrl, var: fallback_assignment_callback_url}, {name: FriendlyName, var: friendly_name}, {name: ReEvaluateTasks, var: re_evaluate_tasks}, {name: TaskReservationTimeout, var: task_reservation_timeout}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://taskrouter.twilio.com"
    auth: basic
  } {
    workspace_sid: $workspace_sid, sid: $sid, assignment_callback_url: $assignment_callback_url, configuration: $configuration, fallback_assignment_callback_url: $fallback_assignment_callback_url, friendly_name: $friendly_name, re_evaluate_tasks: $re_evaluate_tasks, task_reservation_timeout: $task_reservation_timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Workspaces/{WorkspaceSid}/Workflows/{WorkflowSid}/CumulativeStatistics
#
# Returns: record<account_sid: string, avg_task_acceptance_time: int, end_time: string, reservations_accepted: int, reservations_canceled: int, reservations_created: int, reservations_rejected: int, reservations_rescinded: int, reservations_timed_out: int, split_by_wait_time: any, start_time: string, tasks_canceled: int, tasks_completed: int, tasks_deleted: int, tasks_entered: int, tasks_moved: int, tasks_timed_out_in_workflow: int, url: string, wait_duration_until_accepted: any, wait_duration_until_canceled: any, workflow_sid: string, workspace_sid: string>
# operationId: FetchWorkflowCumulativeStatistics
export def "fetch-workflow-cumulative-statistics" [
  workspace_sid: string
  workflow_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --end-date: string # Only include usage that occurred on or before this date, specified in GMT as an [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) date-time. (format: date-time)
  --minutes: int # Only calculate statistics since this many minutes in the past. The default 15 minutes. This is helpful for displaying statistics for the last 15 minutes, 240 minutes (4 hours), and 480 minutes (8 hours) to see trends.
  --start-date: string # Only calculate statistics from this date and time and later, specified in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format. (format: date-time)
  --task-channel: string # Only calculate cumulative statistics on this TaskChannel. Can be the TaskChannel's SID or its `unique_name`, such as `voice`, `sms`, or `default`.
  --split-by-wait-time: string # A comma separated list of values that describes the thresholds, in seconds, to calculate statistics on. For each threshold specified, the number of Tasks canceled and reservations accepted above and below the specified thresholds in seconds are computed. For example, `5,30` would show splits of Tasks that were canceled or accepted before and after 5 seconds and before and after 30 seconds. This can be used to show short abandoned Tasks or Tasks that failed to meet an SLA. TaskRouter will calculate statistics on up to 10,000 Tasks for any given threshold.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/Workspaces/{WorkspaceSid}/Workflows/{WorkflowSid}/CumulativeStatistics"
    path_params: [{name: WorkspaceSid, var: workspace_sid}, {name: WorkflowSid, var: workflow_sid}]
    query: [{name: EndDate, var: end_date}, {name: Minutes, var: minutes}, {name: StartDate, var: start_date}, {name: TaskChannel, var: task_channel}, {name: SplitByWaitTime, var: split_by_wait_time}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://taskrouter.twilio.com"
    auth: basic
  } {
    workspace_sid: $workspace_sid, workflow_sid: $workflow_sid, end_date: $end_date, minutes: $minutes, start_date: $start_date, task_channel: $task_channel, split_by_wait_time: $split_by_wait_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Workspaces/{WorkspaceSid}/Workflows/{WorkflowSid}/RealTimeStatistics
#
# Returns: record<account_sid: string, longest_task_waiting_age: int, longest_task_waiting_sid: string, tasks_by_priority: any, tasks_by_status: any, total_tasks: int, url: string, workflow_sid: string, workspace_sid: string>
# operationId: FetchWorkflowRealTimeStatistics
export def "fetch-workflow-real-time-statistics" [
  workspace_sid: string
  workflow_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --task-channel: string # Only calculate real-time statistics on this TaskChannel. Can be the TaskChannel's SID or its `unique_name`, such as `voice`, `sms`, or `default`.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/Workspaces/{WorkspaceSid}/Workflows/{WorkflowSid}/RealTimeStatistics"
    path_params: [{name: WorkspaceSid, var: workspace_sid}, {name: WorkflowSid, var: workflow_sid}]
    query: [{name: TaskChannel, var: task_channel}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://taskrouter.twilio.com"
    auth: basic
  } {
    workspace_sid: $workspace_sid, workflow_sid: $workflow_sid, task_channel: $task_channel
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Workspaces/{WorkspaceSid}/Workflows/{WorkflowSid}/Statistics
#
# Returns: record<account_sid: string, cumulative: any, realtime: any, url: string, workflow_sid: string, workspace_sid: string>
# operationId: FetchWorkflowStatistics
export def "fetch-workflow-statistics" [
  workspace_sid: string
  workflow_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --minutes: int # Only calculate statistics since this many minutes in the past. The default 15 minutes. This is helpful for displaying statistics for the last 15 minutes, 240 minutes (4 hours), and 480 minutes (8 hours) to see trends.
  --start-date: string # Only calculate statistics from this date and time and later, specified in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format. (format: date-time)
  --end-date: string # Only calculate statistics from this date and time and earlier, specified in GMT as an [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) date-time. (format: date-time)
  --task-channel: string # Only calculate real-time statistics on this TaskChannel. Can be the TaskChannel's SID or its `unique_name`, such as `voice`, `sms`, or `default`.
  --split-by-wait-time: string # A comma separated list of values that describes the thresholds, in seconds, to calculate statistics on. For each threshold specified, the number of Tasks canceled and reservations accepted above and below the specified thresholds in seconds are computed. For example, `5,30` would show splits of Tasks that were canceled or accepted before and after 5 seconds and before and after 30 seconds. This can be used to show short abandoned Tasks or Tasks that failed to meet an SLA.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/Workspaces/{WorkspaceSid}/Workflows/{WorkflowSid}/Statistics"
    path_params: [{name: WorkspaceSid, var: workspace_sid}, {name: WorkflowSid, var: workflow_sid}]
    query: [{name: Minutes, var: minutes}, {name: StartDate, var: start_date}, {name: EndDate, var: end_date}, {name: TaskChannel, var: task_channel}, {name: SplitByWaitTime, var: split_by_wait_time}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://taskrouter.twilio.com"
    auth: basic
  } {
    workspace_sid: $workspace_sid, workflow_sid: $workflow_sid, minutes: $minutes, start_date: $start_date, end_date: $end_date, task_channel: $task_channel, split_by_wait_time: $split_by_wait_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
