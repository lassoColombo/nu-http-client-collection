# Auto-generated client for Twilio - Verify v1.42.0
# Source: https://api.apis.guru/v2/specs/twilio.com/twilio_verify_v2/1.42.0/openapi.json
# Auth: --token flag or $env.TWILIO_VERIFY_TOKEN

const CLIENT = {
  base_url: "https://verify.twilio.com"
  token_env_var: "TWILIO_VERIFY_TOKEN"
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

def base-url-completer [] { ["https://verify.twilio.com"] }
def auth-scheme-completer [] { ["basic" "basic-credentials"] }

# Completers for enum parameters
def channel-completer [] { ["call" "email" "sms" "whatsapp"] }
def status-completer [] { ["converted" "unconverted"] }
def form-type-completer [] { ["form-push"] }
def factor-type-completer [] { ["push"] }
def status-completer-1 [] { ["approved" "denied" "expired" "pending"] }
def order-completer [] { ["asc" "desc"] }
def config-alg-completer [] { ["sha1" "sha256" "sha512"] }
def config-notification-platform-completer [] { ["apn" "fcm" "none"] }
def factor-type-completer-1 [] { ["push" "totp"] }
def status-completer-2 [] { ["approved" "canceled"] }
def status-completer-3 [] { ["disabled" "enabled"] }
def version-completer [] { ["v1" "v2"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    list-verification-attempt: "record<attempts: table<account_sid: string, channel: string, channel_data: any, conversion_status: string, date_created: string, date_updated: string, price: any, service_sid: string, sid: string, url: string, verification_sid: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    fetch-verification-attempts-summary: "record<conversion_rate_percentage: float, total_attempts: int, total_converted: int, total_unconverted: int, url: string>"
    fetch-verification-attempt: "record<account_sid: string, channel: string, channel_data: any, conversion_status: string, date_created: string, date_updated: string, price: any, service_sid: string, sid: string, url: string, verification_sid: string>"
    fetch-form: "record<form_meta: any, form_type: string, forms: any, url: string>"
    create-safelist: "record<phone_number: string, sid: string, url: string>"
    fetch-safelist: "record<phone_number: string, sid: string, url: string>"
    list-service: "record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, services: table<account_sid: string, code_length: int, custom_code_enabled: bool, date_created: string, date_updated: string, default_template_sid: string, do_not_share_warning_enabled: bool, dtmf_input_required: bool, friendly_name: string, links: record, lookup_enabled: bool, psd2_enabled: bool, push: any, sid: string, skip_sms_to_landlines: bool, totp: any, tts_name: string, url: string>>"
    create-service: "record<account_sid: string, code_length: int, custom_code_enabled: bool, date_created: string, date_updated: string, default_template_sid: string, do_not_share_warning_enabled: bool, dtmf_input_required: bool, friendly_name: string, links: record, lookup_enabled: bool, psd2_enabled: bool, push: any, sid: string, skip_sms_to_landlines: bool, totp: any, tts_name: string, url: string>"
    create-access-token: "record<account_sid: string, date_created: string, entity_identity: string, factor_friendly_name: string, factor_type: string, service_sid: string, sid: string, token: string, ttl: int, url: string>"
    fetch-access-token: "record<account_sid: string, date_created: string, entity_identity: string, factor_friendly_name: string, factor_type: string, service_sid: string, sid: string, token: string, ttl: int, url: string>"
    list-entity: "record<entities: table<account_sid: string, date_created: string, date_updated: string, identity: string, links: record, service_sid: string, sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    create-entity: "record<account_sid: string, date_created: string, date_updated: string, identity: string, links: record, service_sid: string, sid: string, url: string>"
    fetch-entity: "record<account_sid: string, date_created: string, date_updated: string, identity: string, links: record, service_sid: string, sid: string, url: string>"
    list-challenge: "record<challenges: table<account_sid: string, date_created: string, date_responded: string, date_updated: string, details: any, entity_sid: string, expiration_date: string, factor_sid: string, factor_type: string, hidden_details: any, identity: string, links: record, metadata: any, responded_reason: string, service_sid: string, sid: string, status: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    create-challenge: "record<account_sid: string, date_created: string, date_responded: string, date_updated: string, details: any, entity_sid: string, expiration_date: string, factor_sid: string, factor_type: string, hidden_details: any, identity: string, links: record, metadata: any, responded_reason: string, service_sid: string, sid: string, status: string, url: string>"
    create-notification: "record<account_sid: string, challenge_sid: string, date_created: string, entity_sid: string, identity: string, priority: string, service_sid: string, sid: string, ttl: int>"
    fetch-challenge: "record<account_sid: string, date_created: string, date_responded: string, date_updated: string, details: any, entity_sid: string, expiration_date: string, factor_sid: string, factor_type: string, hidden_details: any, identity: string, links: record, metadata: any, responded_reason: string, service_sid: string, sid: string, status: string, url: string>"
    update-challenge: "record<account_sid: string, date_created: string, date_responded: string, date_updated: string, details: any, entity_sid: string, expiration_date: string, factor_sid: string, factor_type: string, hidden_details: any, identity: string, links: record, metadata: any, responded_reason: string, service_sid: string, sid: string, status: string, url: string>"
    list-factor: "record<factors: table<account_sid: string, config: any, date_created: string, date_updated: string, entity_sid: string, factor_type: string, friendly_name: string, identity: string, metadata: any, service_sid: string, sid: string, status: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    create-new-factor: "record<account_sid: string, binding: any, config: any, date_created: string, date_updated: string, entity_sid: string, factor_type: string, friendly_name: string, identity: string, metadata: any, service_sid: string, sid: string, status: string, url: string>"
    fetch-factor: "record<account_sid: string, config: any, date_created: string, date_updated: string, entity_sid: string, factor_type: string, friendly_name: string, identity: string, metadata: any, service_sid: string, sid: string, status: string, url: string>"
    update-factor: "record<account_sid: string, config: any, date_created: string, date_updated: string, entity_sid: string, factor_type: string, friendly_name: string, identity: string, metadata: any, service_sid: string, sid: string, status: string, url: string>"
    list-messaging-configuration: "record<messaging_configurations: table<account_sid: string, country: string, date_created: string, date_updated: string, messaging_service_sid: string, service_sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    create-messaging-configuration: "record<account_sid: string, country: string, date_created: string, date_updated: string, messaging_service_sid: string, service_sid: string, url: string>"
    fetch-messaging-configuration: "record<account_sid: string, country: string, date_created: string, date_updated: string, messaging_service_sid: string, service_sid: string, url: string>"
    update-messaging-configuration: "record<account_sid: string, country: string, date_created: string, date_updated: string, messaging_service_sid: string, service_sid: string, url: string>"
    list-rate-limit: "record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, rate_limits: table<account_sid: string, date_created: string, date_updated: string, description: string, links: record, service_sid: string, sid: string, unique_name: string, url: string>>"
    create-rate-limit: "record<account_sid: string, date_created: string, date_updated: string, description: string, links: record, service_sid: string, sid: string, unique_name: string, url: string>"
    list-bucket: "record<buckets: table<account_sid: string, date_created: string, date_updated: string, interval: int, max: int, rate_limit_sid: string, service_sid: string, sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    create-bucket: "record<account_sid: string, date_created: string, date_updated: string, interval: int, max: int, rate_limit_sid: string, service_sid: string, sid: string, url: string>"
    fetch-bucket: "record<account_sid: string, date_created: string, date_updated: string, interval: int, max: int, rate_limit_sid: string, service_sid: string, sid: string, url: string>"
    update-bucket: "record<account_sid: string, date_created: string, date_updated: string, interval: int, max: int, rate_limit_sid: string, service_sid: string, sid: string, url: string>"
    fetch-rate-limit: "record<account_sid: string, date_created: string, date_updated: string, description: string, links: record, service_sid: string, sid: string, unique_name: string, url: string>"
    update-rate-limit: "record<account_sid: string, date_created: string, date_updated: string, description: string, links: record, service_sid: string, sid: string, unique_name: string, url: string>"
    create-verification-check: "record<account_sid: string, amount: string, channel: string, date_created: string, date_updated: string, payee: string, service_sid: string, sid: string, sna_attempts_error_codes: list<any>, status: string, to: string, valid: bool>"
    create-verification: "record<account_sid: string, amount: string, channel: string, date_created: string, date_updated: string, lookup: any, payee: string, send_code_attempts: list<any>, service_sid: string, sid: string, sna: any, status: string, to: string, url: string, valid: bool>"
    fetch-verification: "record<account_sid: string, amount: string, channel: string, date_created: string, date_updated: string, lookup: any, payee: string, send_code_attempts: list<any>, service_sid: string, sid: string, sna: any, status: string, to: string, url: string, valid: bool>"
    update-verification: "record<account_sid: string, amount: string, channel: string, date_created: string, date_updated: string, lookup: any, payee: string, send_code_attempts: list<any>, service_sid: string, sid: string, sna: any, status: string, to: string, url: string, valid: bool>"
    list-webhook: "record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, webhooks: table<account_sid: string, date_created: string, date_updated: string, event_types: list, friendly_name: string, service_sid: string, sid: string, status: string, url: string, version: string, webhook_method: string, webhook_url: string>>"
    create-webhook: "record<account_sid: string, date_created: string, date_updated: string, event_types: list<string>, friendly_name: string, service_sid: string, sid: string, status: string, url: string, version: string, webhook_method: string, webhook_url: string>"
    fetch-webhook: "record<account_sid: string, date_created: string, date_updated: string, event_types: list<string>, friendly_name: string, service_sid: string, sid: string, status: string, url: string, version: string, webhook_method: string, webhook_url: string>"
    update-webhook: "record<account_sid: string, date_created: string, date_updated: string, event_types: list<string>, friendly_name: string, service_sid: string, sid: string, status: string, url: string, version: string, webhook_method: string, webhook_url: string>"
    fetch-service: "record<account_sid: string, code_length: int, custom_code_enabled: bool, date_created: string, date_updated: string, default_template_sid: string, do_not_share_warning_enabled: bool, dtmf_input_required: bool, friendly_name: string, links: record, lookup_enabled: bool, psd2_enabled: bool, push: any, sid: string, skip_sms_to_landlines: bool, totp: any, tts_name: string, url: string>"
    update-service: "record<account_sid: string, code_length: int, custom_code_enabled: bool, date_created: string, date_updated: string, default_template_sid: string, do_not_share_warning_enabled: bool, dtmf_input_required: bool, friendly_name: string, links: record, lookup_enabled: bool, psd2_enabled: bool, push: any, sid: string, skip_sms_to_landlines: bool, totp: any, tts_name: string, url: string>"
    list-verification-template: "record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, templates: table<account_sid: string, channels: list, friendly_name: string, sid: string, translations: any>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["list-verification-attempt" "fetch-verification-attempts-summary" "fetch-verification-attempt" "fetch-form" "create-safelist" "delete-safelist" "fetch-safelist" "list-service" "create-service" "create-access-token" "fetch-access-token" "list-entity" "create-entity" "delete-entity" "fetch-entity" "list-challenge" "create-challenge" "create-notification" "fetch-challenge" "update-challenge" "list-factor" "create-new-factor" "delete-factor" "fetch-factor" "update-factor" "list-messaging-configuration" "create-messaging-configuration" "delete-messaging-configuration" "fetch-messaging-configuration" "update-messaging-configuration" "list-rate-limit" "create-rate-limit" "list-bucket" "create-bucket" "delete-bucket" "fetch-bucket" "update-bucket" "delete-rate-limit" "fetch-rate-limit" "update-rate-limit" "create-verification-check" "create-verification" "fetch-verification" "update-verification" "list-webhook" "create-webhook" "delete-webhook" "fetch-webhook" "update-webhook" "delete-service" "fetch-service" "update-service" "list-verification-template" "commands"] | sort) } | get name | first)
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

# List all the verification attempts for a given Account.
#
# GET /v2/Attempts
# Returns: record<attempts: table<account_sid: string, channel: string, channel_data: any, conversion_status: string, date_created: string, date_updated: string, price: any, service_sid: string, sid: string, url: string, verification_sid: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListVerificationAttempt
export def "list-verification-attempt" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-created-after: string # Datetime filter used to query Verification Attempts created after this datetime. Given as GMT in RFC 2822 format. (format: date-time)
  --date-created-before: string # Datetime filter used to query Verification Attempts created before this datetime. Given as GMT in RFC 2822 format. (format: date-time)
  --channel-data-to: string # Destination of a verification. It is phone number in E.164 format.
  --country: string # Filter used to query Verification Attempts sent to the specified destination country. (format: iso-country-code)
  --channel: string@channel-completer # Filter used to query Verification Attempts by communication channel. Valid values are `SMS` and `CALL`
  --verify-service-sid: string # Filter used to query Verification Attempts by verify service. Only attempts of the provided SID will be returned.
  --verification-sid: string # Filter used to return all the Verification Attempts of a single verification. Only attempts of the provided verification SID will be returned.
  --status: string@status-completer # Filter used to query Verification Attempts by conversion status. Valid values are `UNCONVERTED`, for attempts that were not converted, and `CONVERTED`, for attempts that were confirmed.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/Attempts"
    query: [{name: DateCreatedAfter, var: date_created_after}, {name: DateCreatedBefore, var: date_created_before}, {name: "ChannelData.To", var: channel_data_to}, {name: Country, var: country}, {name: Channel, var: channel}, {name: VerifyServiceSid, var: verify_service_sid}, {name: VerificationSid, var: verification_sid}, {name: Status, var: status}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://verify.twilio.com"
    auth: basic
  } {
    date_created_after: $date_created_after, date_created_before: $date_created_before, channel_data_to: $channel_data_to, country: $country, channel: $channel, verify_service_sid: $verify_service_sid, verification_sid: $verification_sid, status: $status, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a summary of how many attempts were made and how many were converted.
#
# GET /v2/Attempts/Summary
# Returns: record<conversion_rate_percentage: float, total_attempts: int, total_converted: int, total_unconverted: int, url: string>
# operationId: FetchVerificationAttemptsSummary
export def "fetch-verification-attempts-summary" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --verify-service-sid: string # Filter used to consider only Verification Attempts of the given verify service on the summary aggregation.
  --date-created-after: string # Datetime filter used to consider only Verification Attempts created after this datetime on the summary aggregation. Given as GMT in RFC 2822 format. (format: date-time)
  --date-created-before: string # Datetime filter used to consider only Verification Attempts created before this datetime on the summary aggregation. Given as GMT in RFC 2822 format. (format: date-time)
  --country: string # Filter used to consider only Verification Attempts sent to the specified destination country on the summary aggregation. (format: iso-country-code)
  --channel: string@channel-completer # Filter Verification Attempts considered on the summary aggregation by communication channel. Valid values are `SMS` and `CALL`
  --destination-prefix: string # Filter the Verification Attempts considered on the summary aggregation by Destination prefix. It is the prefix of a phone number in E.164 format.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/Attempts/Summary"
    query: [{name: VerifyServiceSid, var: verify_service_sid}, {name: DateCreatedAfter, var: date_created_after}, {name: DateCreatedBefore, var: date_created_before}, {name: Country, var: country}, {name: Channel, var: channel}, {name: DestinationPrefix, var: destination_prefix}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://verify.twilio.com"
    auth: basic
  } {
    verify_service_sid: $verify_service_sid, date_created_after: $date_created_after, date_created_before: $date_created_before, country: $country, channel: $channel, destination_prefix: $destination_prefix
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a specific verification attempt.
#
# GET /v2/Attempts/{Sid}
# Returns: record<account_sid: string, channel: string, channel_data: any, conversion_status: string, date_created: string, date_updated: string, price: any, service_sid: string, sid: string, url: string, verification_sid: string>
# operationId: FetchVerificationAttempt
export def "fetch-verification-attempt" [
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
    path: "/v2/Attempts/{Sid}"
    path_params: [{name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://verify.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch the forms for a specific Form Type.
#
# GET /v2/Forms/{FormType}
# Returns: record<form_meta: any, form_type: string, forms: any, url: string>
# operationId: FetchForm
export def "fetch-form" [
  form_type: string@form-type-completer
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
    path: "/v2/Forms/{FormType}"
    path_params: [{name: FormType, var: form_type}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://verify.twilio.com"
    auth: basic
  } {
    form_type: $form_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a new phone number to SafeList.
#
# POST /v2/SafeList/Numbers
# Returns: record<phone_number: string, sid: string, url: string>
# operationId: CreateSafelist
export def "create-safelist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  phone_number: string # The phone number to be added in SafeList. Phone numbers must be in [E.164 format](https://www.twilio.com/docs/glossary/what-e164).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/SafeList/Numbers"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: PhoneNumber, var: phone_number}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://verify.twilio.com"
    auth: basic
  } {
    phone_number: $phone_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a phone number from SafeList.
#
# DELETE /v2/SafeList/Numbers/{PhoneNumber}
# operationId: DeleteSafelist
export def "delete-safelist" [
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/v2/SafeList/Numbers/{PhoneNumber}"
    path_params: [{name: PhoneNumber, var: phone_number}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://verify.twilio.com"
    auth: basic
  } {
    phone_number: $phone_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check if a phone number exists in SafeList.
#
# GET /v2/SafeList/Numbers/{PhoneNumber}
# Returns: record<phone_number: string, sid: string, url: string>
# operationId: FetchSafelist
export def "fetch-safelist" [
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
    path: "/v2/SafeList/Numbers/{PhoneNumber}"
    path_params: [{name: PhoneNumber, var: phone_number}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://verify.twilio.com"
    auth: basic
  } {
    phone_number: $phone_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of all Verification Services for an account.
#
# GET /v2/Services
# Returns: record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, services: table<account_sid: string, code_length: int, custom_code_enabled: bool, date_created: string, date_updated: string, default_template_sid: string, do_not_share_warning_enabled: bool, dtmf_input_required: bool, friendly_name: string, links: record, lookup_enabled: bool, psd2_enabled: bool, push: any, sid: string, skip_sms_to_landlines: bool, totp: any, tts_name: string, url: string>>
# operationId: ListService
export def "list-service" [
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
    path: "/v2/Services"
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://verify.twilio.com"
    auth: basic
  } {
    page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new Verification Service.
#
# POST /v2/Services
# Returns: record<account_sid: string, code_length: int, custom_code_enabled: bool, date_created: string, date_updated: string, default_template_sid: string, do_not_share_warning_enabled: bool, dtmf_input_required: bool, friendly_name: string, links: record, lookup_enabled: bool, psd2_enabled: bool, push: any, sid: string, skip_sms_to_landlines: bool, totp: any, tts_name: string, url: string>
# operationId: CreateService
export def "create-service" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --code-length: int # The length of the verification code to generate. Must be an integer value between 4 and 10, inclusive.
  --custom-code-enabled: oneof<nothing, bool> # Whether to allow sending verifications with a custom code instead of a randomly generated one. Not available for all customers.
  --default-template-sid: string # The default message [template](https://www.twilio.com/docs/verify/api/templates). Will be used for all SMS verifications unless explicitly overriden. SMS channel only.
  --do-not-share-warning-enabled: oneof<nothing, bool> # Whether to add a security warning at the end of an SMS verification body. Disabled by default and applies only to SMS. Example SMS body: `Your AppName verification code is: 1234. Don’t share this code with anyone; our employees will never ask for the code`
  --dtmf-input-required: oneof<nothing, bool> # Whether to ask the user to press a number before delivering the verify code in a phone call.
  friendly_name: string # A descriptive string that you create to describe the verification service. It can be up to 32 characters long. **This value should not contain PII.**
  --lookup-enabled: oneof<nothing, bool> # Whether to perform a lookup with each verification started and return info about the phone number.
  --psd2-enabled: oneof<nothing, bool> # Whether to pass PSD2 transaction parameters when starting a verification.
  --push-apn-credential-sid: string # Optional configuration for the Push factors. Set the APN Credential for this service. This will allow to send push notifications to iOS devices. See [Credential Resource](https://www.twilio.com/docs/notify/api/credential-resource)
  --push-fcm-credential-sid: string # Optional configuration for the Push factors. Set the FCM Credential for this service. This will allow to send push notifications to Android devices. See [Credential Resource](https://www.twilio.com/docs/notify/api/credential-resource)
  --push-include-date: oneof<nothing, bool> # Optional configuration for the Push factors. If true, include the date in the Challenge's response. Otherwise, the date is omitted from the response. See [Challenge](https://www.twilio.com/docs/verify/api/challenge) resource’s details parameter for more info. Default: false. **Deprecated** do not use this parameter. This timestamp value is the same one as the one found in `date_created`, please use that one instead.
  --skip-sms-to-landlines: oneof<nothing, bool> # Whether to skip sending SMS verifications to landlines. Requires `lookup_enabled`.
  --totp-code-length: int # Optional configuration for the TOTP factors. Number of digits for generated TOTP codes. Must be between 3 and 8, inclusive. Defaults to 6
  --totp-issuer: string # Optional configuration for the TOTP factors. Set TOTP Issuer for this service. This will allow to configure the issuer of the TOTP URI. Defaults to the service friendly name if not provided.
  --totp-skew: int # Optional configuration for the TOTP factors. The number of time-steps, past and future, that are valid for validation of TOTP codes. Must be between 0 and 2, inclusive. Defaults to 1
  --totp-time-step: int # Optional configuration for the TOTP factors. Defines how often, in seconds, are TOTP codes generated. i.e, a new TOTP code is generated every time_step seconds. Must be between 20 and 60 seconds, inclusive. Defaults to 30 seconds
  --tts-name: string # The name of an alternative text-to-speech service to use in phone calls. Applies only to TTS languages.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/Services"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: CodeLength, var: code_length}, {name: CustomCodeEnabled, var: custom_code_enabled}, {name: DefaultTemplateSid, var: default_template_sid}, {name: DoNotShareWarningEnabled, var: do_not_share_warning_enabled}, {name: DtmfInputRequired, var: dtmf_input_required}, {name: FriendlyName, var: friendly_name}, {name: LookupEnabled, var: lookup_enabled}, {name: Psd2Enabled, var: psd2_enabled}, {name: "Push.ApnCredentialSid", var: push_apn_credential_sid}, {name: "Push.FcmCredentialSid", var: push_fcm_credential_sid}, {name: "Push.IncludeDate", var: push_include_date}, {name: SkipSmsToLandlines, var: skip_sms_to_landlines}, {name: "Totp.CodeLength", var: totp_code_length}, {name: "Totp.Issuer", var: totp_issuer}, {name: "Totp.Skew", var: totp_skew}, {name: "Totp.TimeStep", var: totp_time_step}, {name: TtsName, var: tts_name}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://verify.twilio.com"
    auth: basic
  } {
    code_length: $code_length, custom_code_enabled: $custom_code_enabled, default_template_sid: $default_template_sid, do_not_share_warning_enabled: $do_not_share_warning_enabled, dtmf_input_required: $dtmf_input_required, friendly_name: $friendly_name, lookup_enabled: $lookup_enabled, psd2_enabled: $psd2_enabled, push_apn_credential_sid: $push_apn_credential_sid, push_fcm_credential_sid: $push_fcm_credential_sid, push_include_date: $push_include_date, skip_sms_to_landlines: $skip_sms_to_landlines, totp_code_length: $totp_code_length, totp_issuer: $totp_issuer, totp_skew: $totp_skew, totp_time_step: $totp_time_step, tts_name: $tts_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new enrollment Access Token for the Entity
#
# POST /v2/Services/{ServiceSid}/AccessTokens
# Returns: record<account_sid: string, date_created: string, entity_identity: string, factor_friendly_name: string, factor_type: string, service_sid: string, sid: string, token: string, ttl: int, url: string>
# operationId: CreateAccessToken
export def "create-access-token" [
  service_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --factor-friendly-name: string # The friendly name of the factor that is going to be created with this access token
  factor_type: string@factor-type-completer
  identity: string # The unique external identifier for the Entity of the Service. This identifier should be immutable, not PII, and generated by your external system, such as your user's UUID, GUID, or SID.
  --ttl: int # How long, in seconds, the access token is valid. Can be an integer between 60 and 300. Default is 60.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/Services/{ServiceSid}/AccessTokens"
    path_params: [{name: ServiceSid, var: service_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: FactorFriendlyName, var: factor_friendly_name}, {name: FactorType, var: factor_type}, {name: Identity, var: identity}, {name: Ttl, var: ttl}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://verify.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, factor_friendly_name: $factor_friendly_name, factor_type: $factor_type, identity: $identity, ttl: $ttl
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch an Access Token for the Entity
#
# GET /v2/Services/{ServiceSid}/AccessTokens/{Sid}
# Returns: record<account_sid: string, date_created: string, entity_identity: string, factor_friendly_name: string, factor_type: string, service_sid: string, sid: string, token: string, ttl: int, url: string>
# operationId: FetchAccessToken
export def "fetch-access-token" [
  service_sid: string
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
    path: "/v2/Services/{ServiceSid}/AccessTokens/{Sid}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://verify.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of all Entities for a Service.
#
# GET /v2/Services/{ServiceSid}/Entities
# Returns: record<entities: table<account_sid: string, date_created: string, date_updated: string, identity: string, links: record, service_sid: string, sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListEntity
export def "list-entity" [
  service_sid: string
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
    path: "/v2/Services/{ServiceSid}/Entities"
    path_params: [{name: ServiceSid, var: service_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://verify.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new Entity for the Service
#
# POST /v2/Services/{ServiceSid}/Entities
# Returns: record<account_sid: string, date_created: string, date_updated: string, identity: string, links: record, service_sid: string, sid: string, url: string>
# operationId: CreateEntity
export def "create-entity" [
  service_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  identity: string # The unique external identifier for the Entity of the Service. This identifier should be immutable, not PII, length between 8 and 64 characters, and generated by your external system, such as your user's UUID, GUID, or SID. It can only contain dash (-) separated alphanumeric characters.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/Services/{ServiceSid}/Entities"
    path_params: [{name: ServiceSid, var: service_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Identity, var: identity}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://verify.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, identity: $identity
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a specific Entity.
#
# DELETE /v2/Services/{ServiceSid}/Entities/{Identity}
# operationId: DeleteEntity
export def "delete-entity" [
  service_sid: string
  identity: string
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
    path: "/v2/Services/{ServiceSid}/Entities/{Identity}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: Identity, var: identity}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://verify.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, identity: $identity
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a specific Entity.
#
# GET /v2/Services/{ServiceSid}/Entities/{Identity}
# Returns: record<account_sid: string, date_created: string, date_updated: string, identity: string, links: record, service_sid: string, sid: string, url: string>
# operationId: FetchEntity
export def "fetch-entity" [
  service_sid: string
  identity: string
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
    path: "/v2/Services/{ServiceSid}/Entities/{Identity}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: Identity, var: identity}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://verify.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, identity: $identity
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of all Challenges for a Factor.
#
# GET /v2/Services/{ServiceSid}/Entities/{Identity}/Challenges
# Returns: record<challenges: table<account_sid: string, date_created: string, date_responded: string, date_updated: string, details: any, entity_sid: string, expiration_date: string, factor_sid: string, factor_type: string, hidden_details: any, identity: string, links: record, metadata: any, responded_reason: string, service_sid: string, sid: string, status: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListChallenge
export def "list-challenge" [
  service_sid: string
  identity: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --factor-sid: string # The unique SID identifier of the Factor.
  --status: string@status-completer-1 # The Status of the Challenges to fetch. One of `pending`, `expired`, `approved` or `denied`.
  --order: string@order-completer # The desired sort order of the Challenges list. One of `asc` or `desc` for ascending and descending respectively. Defaults to `asc`.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/Services/{ServiceSid}/Entities/{Identity}/Challenges"
    path_params: [{name: ServiceSid, var: service_sid}, {name: Identity, var: identity}]
    query: [{name: FactorSid, var: factor_sid}, {name: Status, var: status}, {name: Order, var: order}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://verify.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, identity: $identity, factor_sid: $factor_sid, status: $status, order: $order, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new Challenge for the Factor
#
# POST /v2/Services/{ServiceSid}/Entities/{Identity}/Challenges
# Returns: record<account_sid: string, date_created: string, date_responded: string, date_updated: string, details: any, entity_sid: string, expiration_date: string, factor_sid: string, factor_type: string, hidden_details: any, identity: string, links: record, metadata: any, responded_reason: string, service_sid: string, sid: string, status: string, url: string>
# operationId: CreateChallenge
export def "create-challenge" [
  service_sid: string
  identity: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auth-payload: string # Optional payload used to verify the Challenge upon creation. Only used with a Factor of type `totp` to carry the TOTP code that needs to be verified. For `TOTP` this value must be between 3 and 8 characters long.
  --details-fields: list # A list of objects that describe the Fields included in the Challenge. Each object contains the label and value of the field, the label can be up to 36 characters in length and the value can be up to 128 characters in length. Used when `factor_type` is `push`. There can be up to 20 details fields.
  --details-message: string # Shown to the user when the push notification arrives. Required when `factor_type` is `push`. Can be up to 256 characters in length
  --expiration-date: string # The date-time when this Challenge expires, given in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format. The default value is five (5) minutes after Challenge creation. The max value is sixty (60) minutes after creation. (format: date-time)
  factor_sid: string # The unique SID identifier of the Factor.
  --hidden-details: any # Details provided to give context about the Challenge. Not shown to the end user. It must be a stringified JSON with only strings values eg. `{"ip": "172.168.1.234"}`. Can be up to 1024 characters in length
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/Services/{ServiceSid}/Entities/{Identity}/Challenges"
    path_params: [{name: ServiceSid, var: service_sid}, {name: Identity, var: identity}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: AuthPayload, var: auth_payload}, {name: "Details.Fields", var: details_fields}, {name: "Details.Message", var: details_message}, {name: ExpirationDate, var: expiration_date}, {name: FactorSid, var: factor_sid}, {name: HiddenDetails, var: hidden_details}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://verify.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, identity: $identity, auth_payload: $auth_payload, details_fields: $details_fields, details_message: $details_message, expiration_date: $expiration_date, factor_sid: $factor_sid, hidden_details: $hidden_details
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new Notification for the corresponding Challenge
#
# POST /v2/Services/{ServiceSid}/Entities/{Identity}/Challenges/{ChallengeSid}/Notifications
# Returns: record<account_sid: string, challenge_sid: string, date_created: string, entity_sid: string, identity: string, priority: string, service_sid: string, sid: string, ttl: int>
# operationId: CreateNotification
export def "create-notification" [
  service_sid: string
  identity: string
  challenge_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ttl: int # How long, in seconds, the notification is valid. Can be an integer between 0 and 300. Default is 300. Delivery is attempted until the TTL elapses, even if the device is offline. 0 means that the notification delivery is attempted immediately, only once, and is not stored for future delivery.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/Services/{ServiceSid}/Entities/{Identity}/Challenges/{ChallengeSid}/Notifications"
    path_params: [{name: ServiceSid, var: service_sid}, {name: Identity, var: identity}, {name: ChallengeSid, var: challenge_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Ttl, var: ttl}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://verify.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, identity: $identity, challenge_sid: $challenge_sid, ttl: $ttl
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a specific Challenge.
#
# GET /v2/Services/{ServiceSid}/Entities/{Identity}/Challenges/{Sid}
# Returns: record<account_sid: string, date_created: string, date_responded: string, date_updated: string, details: any, entity_sid: string, expiration_date: string, factor_sid: string, factor_type: string, hidden_details: any, identity: string, links: record, metadata: any, responded_reason: string, service_sid: string, sid: string, status: string, url: string>
# operationId: FetchChallenge
export def "fetch-challenge" [
  service_sid: string
  identity: string
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
    path: "/v2/Services/{ServiceSid}/Entities/{Identity}/Challenges/{Sid}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: Identity, var: identity}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://verify.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, identity: $identity, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Verify a specific Challenge.
#
# POST /v2/Services/{ServiceSid}/Entities/{Identity}/Challenges/{Sid}
# Returns: record<account_sid: string, date_created: string, date_responded: string, date_updated: string, details: any, entity_sid: string, expiration_date: string, factor_sid: string, factor_type: string, hidden_details: any, identity: string, links: record, metadata: any, responded_reason: string, service_sid: string, sid: string, status: string, url: string>
# operationId: UpdateChallenge
export def "update-challenge" [
  service_sid: string
  identity: string
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
  --auth-payload: string # The optional payload needed to verify the Challenge. E.g., a TOTP would use the numeric code. For `TOTP` this value must be between 3 and 8 characters long. For `Push` this value can be up to 5456 characters in length
  --metadata: any # Custom metadata associated with the challenge. This is added by the Device/SDK directly to allow for the inclusion of device information. It must be a stringified JSON with only strings values eg. `{"os": "Android"}`. Can be up to 1024 characters in length.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/Services/{ServiceSid}/Entities/{Identity}/Challenges/{Sid}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: Identity, var: identity}, {name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: AuthPayload, var: auth_payload}, {name: Metadata, var: metadata}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://verify.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, identity: $identity, sid: $sid, auth_payload: $auth_payload, metadata: $metadata
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of all Factors for an Entity.
#
# GET /v2/Services/{ServiceSid}/Entities/{Identity}/Factors
# Returns: record<factors: table<account_sid: string, config: any, date_created: string, date_updated: string, entity_sid: string, factor_type: string, friendly_name: string, identity: string, metadata: any, service_sid: string, sid: string, status: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListFactor
export def "list-factor" [
  service_sid: string
  identity: string
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
    path: "/v2/Services/{ServiceSid}/Entities/{Identity}/Factors"
    path_params: [{name: ServiceSid, var: service_sid}, {name: Identity, var: identity}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://verify.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, identity: $identity, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new Factor for the Entity
#
# POST /v2/Services/{ServiceSid}/Entities/{Identity}/Factors
# Returns: record<account_sid: string, binding: any, config: any, date_created: string, date_updated: string, entity_sid: string, factor_type: string, friendly_name: string, identity: string, metadata: any, service_sid: string, sid: string, status: string, url: string>
# operationId: CreateNewFactor
export def "create-new-factor" [
  service_sid: string
  identity: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --binding-alg: string # The algorithm used when `factor_type` is `push`. Algorithm supported: `ES256`
  --binding-public-key: string # The Ecdsa public key in PKIX, ASN.1 DER format encoded in Base64. Required when `factor_type` is `push`
  --binding-secret: string # The shared secret for TOTP factors encoded in Base32. This can be provided when creating the Factor, otherwise it will be generated. Used when `factor_type` is `totp`
  --config-alg: string@config-alg-completer
  --config-app-id: string # The ID that uniquely identifies your app in the Google or Apple store, such as `com.example.myapp`. It can be up to 100 characters long. Required when `factor_type` is `push`.
  --config-code-length: int # Number of digits for generated TOTP codes. Must be between 3 and 8, inclusive. The default value is defined at the service level in the property `totp.code_length`. If not configured defaults to 6. Used when `factor_type` is `totp`
  --config-notification-platform: string@config-notification-platform-completer
  --config-notification-token: string # For APN, the device token. For FCM, the registration token. It is used to send the push notifications. Must be between 32 and 255 characters long. Required when `factor_type` is `push`.
  --config-sdk-version: string # The Verify Push SDK version used to configure the factor Required when `factor_type` is `push`
  --config-skew: int # The number of time-steps, past and future, that are valid for validation of TOTP codes. Must be between 0 and 2, inclusive. The default value is defined at the service level in the property `totp.skew`. If not configured defaults to 1. Used when `factor_type` is `totp`
  --config-time-step: int # Defines how often, in seconds, are TOTP codes generated. i.e, a new TOTP code is generated every time_step seconds. Must be between 20 and 60 seconds, inclusive. The default value is defined at the service level in the property `totp.time_step`. Defaults to 30 seconds if not configured. Used when `factor_type` is `totp`
  factor_type: string@factor-type-completer-1
  friendly_name: string # The friendly name of this Factor. This can be any string up to 64 characters, meant for humans to distinguish between Factors. For `factor_type` `push`, this could be a device name. For `factor_type` `totp`, this value is used as the “account name” in constructing the `binding.uri` property. At the same time, we recommend avoiding providing PII.
  --metadata: any # Custom metadata associated with the factor. This is added by the Device/SDK directly to allow for the inclusion of device information. It must be a stringified JSON with only strings values eg. `{"os": "Android"}`. Can be up to 1024 characters in length.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/Services/{ServiceSid}/Entities/{Identity}/Factors"
    path_params: [{name: ServiceSid, var: service_sid}, {name: Identity, var: identity}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: "Binding.Alg", var: binding_alg}, {name: "Binding.PublicKey", var: binding_public_key}, {name: "Binding.Secret", var: binding_secret}, {name: "Config.Alg", var: config_alg}, {name: "Config.AppId", var: config_app_id}, {name: "Config.CodeLength", var: config_code_length}, {name: "Config.NotificationPlatform", var: config_notification_platform}, {name: "Config.NotificationToken", var: config_notification_token}, {name: "Config.SdkVersion", var: config_sdk_version}, {name: "Config.Skew", var: config_skew}, {name: "Config.TimeStep", var: config_time_step}, {name: FactorType, var: factor_type}, {name: FriendlyName, var: friendly_name}, {name: Metadata, var: metadata}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://verify.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, identity: $identity, binding_alg: $binding_alg, binding_public_key: $binding_public_key, binding_secret: $binding_secret, config_alg: $config_alg, config_app_id: $config_app_id, config_code_length: $config_code_length, config_notification_platform: $config_notification_platform, config_notification_token: $config_notification_token, config_sdk_version: $config_sdk_version, config_skew: $config_skew, config_time_step: $config_time_step, factor_type: $factor_type, friendly_name: $friendly_name, metadata: $metadata
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a specific Factor.
#
# DELETE /v2/Services/{ServiceSid}/Entities/{Identity}/Factors/{Sid}
# operationId: DeleteFactor
export def "delete-factor" [
  service_sid: string
  identity: string
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
    path: "/v2/Services/{ServiceSid}/Entities/{Identity}/Factors/{Sid}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: Identity, var: identity}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://verify.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, identity: $identity, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a specific Factor.
#
# GET /v2/Services/{ServiceSid}/Entities/{Identity}/Factors/{Sid}
# Returns: record<account_sid: string, config: any, date_created: string, date_updated: string, entity_sid: string, factor_type: string, friendly_name: string, identity: string, metadata: any, service_sid: string, sid: string, status: string, url: string>
# operationId: FetchFactor
export def "fetch-factor" [
  service_sid: string
  identity: string
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
    path: "/v2/Services/{ServiceSid}/Entities/{Identity}/Factors/{Sid}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: Identity, var: identity}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://verify.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, identity: $identity, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a specific Factor. This endpoint can be used to Verify a Factor if passed an `AuthPayload` param.
#
# POST /v2/Services/{ServiceSid}/Entities/{Identity}/Factors/{Sid}
# Returns: record<account_sid: string, config: any, date_created: string, date_updated: string, entity_sid: string, factor_type: string, friendly_name: string, identity: string, metadata: any, service_sid: string, sid: string, status: string, url: string>
# operationId: UpdateFactor
export def "update-factor" [
  service_sid: string
  identity: string
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
  --auth-payload: string # The optional payload needed to verify the Factor for the first time. E.g. for a TOTP, the numeric code.
  --config-alg: string@config-alg-completer
  --config-code-length: int # Number of digits for generated TOTP codes. Must be between 3 and 8, inclusive
  --config-notification-platform: string # The transport technology used to generate the Notification Token. Can be `apn`, `fcm` or `none`. Required when `factor_type` is `push`.
  --config-notification-token: string # For APN, the device token. For FCM, the registration token. It is used to send the push notifications. Required when `factor_type` is `push`. If specified, this value must be between 32 and 255 characters long.
  --config-sdk-version: string # The Verify Push SDK version used to configure the factor
  --config-skew: int # The number of time-steps, past and future, that are valid for validation of TOTP codes. Must be between 0 and 2, inclusive
  --config-time-step: int # Defines how often, in seconds, are TOTP codes generated. i.e, a new TOTP code is generated every time_step seconds. Must be between 20 and 60 seconds, inclusive
  --friendly-name: string # The new friendly name of this Factor. It can be up to 64 characters.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/Services/{ServiceSid}/Entities/{Identity}/Factors/{Sid}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: Identity, var: identity}, {name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: AuthPayload, var: auth_payload}, {name: "Config.Alg", var: config_alg}, {name: "Config.CodeLength", var: config_code_length}, {name: "Config.NotificationPlatform", var: config_notification_platform}, {name: "Config.NotificationToken", var: config_notification_token}, {name: "Config.SdkVersion", var: config_sdk_version}, {name: "Config.Skew", var: config_skew}, {name: "Config.TimeStep", var: config_time_step}, {name: FriendlyName, var: friendly_name}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://verify.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, identity: $identity, sid: $sid, auth_payload: $auth_payload, config_alg: $config_alg, config_code_length: $config_code_length, config_notification_platform: $config_notification_platform, config_notification_token: $config_notification_token, config_sdk_version: $config_sdk_version, config_skew: $config_skew, config_time_step: $config_time_step, friendly_name: $friendly_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of all Messaging Configurations for a Service.
#
# GET /v2/Services/{ServiceSid}/MessagingConfigurations
# Returns: record<messaging_configurations: table<account_sid: string, country: string, date_created: string, date_updated: string, messaging_service_sid: string, service_sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListMessagingConfiguration
export def "list-messaging-configuration" [
  service_sid: string
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
    path: "/v2/Services/{ServiceSid}/MessagingConfigurations"
    path_params: [{name: ServiceSid, var: service_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://verify.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new MessagingConfiguration for a service.
#
# POST /v2/Services/{ServiceSid}/MessagingConfigurations
# Returns: record<account_sid: string, country: string, date_created: string, date_updated: string, messaging_service_sid: string, service_sid: string, url: string>
# operationId: CreateMessagingConfiguration
export def "create-messaging-configuration" [
  service_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  country: string # The [ISO-3166-1](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2) country code of the country this configuration will be applied to. If this is a global configuration, Country will take the value `all`.
  messaging_service_sid: string # The SID of the [Messaging Service](https://www.twilio.com/docs/sms/services/api) to be used to send SMS to the country of this configuration.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/Services/{ServiceSid}/MessagingConfigurations"
    path_params: [{name: ServiceSid, var: service_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Country, var: country}, {name: MessagingServiceSid, var: messaging_service_sid}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://verify.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, country: $country, messaging_service_sid: $messaging_service_sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a specific MessagingConfiguration.
#
# DELETE /v2/Services/{ServiceSid}/MessagingConfigurations/{Country}
# operationId: DeleteMessagingConfiguration
export def "delete-messaging-configuration" [
  service_sid: string
  country: string
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
    path: "/v2/Services/{ServiceSid}/MessagingConfigurations/{Country}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: Country, var: country}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://verify.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, country: $country
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a specific MessagingConfiguration.
#
# GET /v2/Services/{ServiceSid}/MessagingConfigurations/{Country}
# Returns: record<account_sid: string, country: string, date_created: string, date_updated: string, messaging_service_sid: string, service_sid: string, url: string>
# operationId: FetchMessagingConfiguration
export def "fetch-messaging-configuration" [
  service_sid: string
  country: string
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
    path: "/v2/Services/{ServiceSid}/MessagingConfigurations/{Country}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: Country, var: country}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://verify.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, country: $country
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a specific MessagingConfiguration
#
# POST /v2/Services/{ServiceSid}/MessagingConfigurations/{Country}
# Returns: record<account_sid: string, country: string, date_created: string, date_updated: string, messaging_service_sid: string, service_sid: string, url: string>
# operationId: UpdateMessagingConfiguration
export def "update-messaging-configuration" [
  service_sid: string
  country: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  messaging_service_sid: string # The SID of the [Messaging Service](https://www.twilio.com/docs/sms/services/api) to be used to send SMS to the country of this configuration.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/Services/{ServiceSid}/MessagingConfigurations/{Country}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: Country, var: country}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: MessagingServiceSid, var: messaging_service_sid}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://verify.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, country: $country, messaging_service_sid: $messaging_service_sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of all Rate Limits for a service.
#
# GET /v2/Services/{ServiceSid}/RateLimits
# Returns: record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, rate_limits: table<account_sid: string, date_created: string, date_updated: string, description: string, links: record, service_sid: string, sid: string, unique_name: string, url: string>>
# operationId: ListRateLimit
export def "list-rate-limit" [
  service_sid: string
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
    path: "/v2/Services/{ServiceSid}/RateLimits"
    path_params: [{name: ServiceSid, var: service_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://verify.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new Rate Limit for a Service
#
# POST /v2/Services/{ServiceSid}/RateLimits
# Returns: record<account_sid: string, date_created: string, date_updated: string, description: string, links: record, service_sid: string, sid: string, unique_name: string, url: string>
# operationId: CreateRateLimit
export def "create-rate-limit" [
  service_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # Description of this Rate Limit
  unique_name: string # Provides a unique and addressable name to be assigned to this Rate Limit, assigned by the developer, to be optionally used in addition to SID. **This value should not contain PII.**
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/Services/{ServiceSid}/RateLimits"
    path_params: [{name: ServiceSid, var: service_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Description, var: description}, {name: UniqueName, var: unique_name}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://verify.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, description: $description, unique_name: $unique_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of all Buckets for a Rate Limit.
#
# GET /v2/Services/{ServiceSid}/RateLimits/{RateLimitSid}/Buckets
# Returns: record<buckets: table<account_sid: string, date_created: string, date_updated: string, interval: int, max: int, rate_limit_sid: string, service_sid: string, sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListBucket
export def "list-bucket" [
  service_sid: string
  rate_limit_sid: string
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
    path: "/v2/Services/{ServiceSid}/RateLimits/{RateLimitSid}/Buckets"
    path_params: [{name: ServiceSid, var: service_sid}, {name: RateLimitSid, var: rate_limit_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://verify.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, rate_limit_sid: $rate_limit_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new Bucket for a Rate Limit
#
# POST /v2/Services/{ServiceSid}/RateLimits/{RateLimitSid}/Buckets
# Returns: record<account_sid: string, date_created: string, date_updated: string, interval: int, max: int, rate_limit_sid: string, service_sid: string, sid: string, url: string>
# operationId: CreateBucket
export def "create-bucket" [
  service_sid: string
  rate_limit_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  interval: int # Number of seconds that the rate limit will be enforced over.
  max: int # Maximum number of requests permitted in during the interval.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/Services/{ServiceSid}/RateLimits/{RateLimitSid}/Buckets"
    path_params: [{name: ServiceSid, var: service_sid}, {name: RateLimitSid, var: rate_limit_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Interval, var: interval}, {name: Max, var: max}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://verify.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, rate_limit_sid: $rate_limit_sid, interval: $interval, max: $max
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a specific Bucket.
#
# DELETE /v2/Services/{ServiceSid}/RateLimits/{RateLimitSid}/Buckets/{Sid}
# operationId: DeleteBucket
export def "delete-bucket" [
  service_sid: string
  rate_limit_sid: string
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
    path: "/v2/Services/{ServiceSid}/RateLimits/{RateLimitSid}/Buckets/{Sid}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: RateLimitSid, var: rate_limit_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://verify.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, rate_limit_sid: $rate_limit_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a specific Bucket.
#
# GET /v2/Services/{ServiceSid}/RateLimits/{RateLimitSid}/Buckets/{Sid}
# Returns: record<account_sid: string, date_created: string, date_updated: string, interval: int, max: int, rate_limit_sid: string, service_sid: string, sid: string, url: string>
# operationId: FetchBucket
export def "fetch-bucket" [
  service_sid: string
  rate_limit_sid: string
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
    path: "/v2/Services/{ServiceSid}/RateLimits/{RateLimitSid}/Buckets/{Sid}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: RateLimitSid, var: rate_limit_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://verify.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, rate_limit_sid: $rate_limit_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a specific Bucket.
#
# POST /v2/Services/{ServiceSid}/RateLimits/{RateLimitSid}/Buckets/{Sid}
# Returns: record<account_sid: string, date_created: string, date_updated: string, interval: int, max: int, rate_limit_sid: string, service_sid: string, sid: string, url: string>
# operationId: UpdateBucket
export def "update-bucket" [
  service_sid: string
  rate_limit_sid: string
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
  --interval: int # Number of seconds that the rate limit will be enforced over.
  --max: int # Maximum number of requests permitted in during the interval.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/Services/{ServiceSid}/RateLimits/{RateLimitSid}/Buckets/{Sid}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: RateLimitSid, var: rate_limit_sid}, {name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Interval, var: interval}, {name: Max, var: max}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://verify.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, rate_limit_sid: $rate_limit_sid, sid: $sid, interval: $interval, max: $max
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a specific Rate Limit.
#
# DELETE /v2/Services/{ServiceSid}/RateLimits/{Sid}
# operationId: DeleteRateLimit
export def "delete-rate-limit" [
  service_sid: string
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
    path: "/v2/Services/{ServiceSid}/RateLimits/{Sid}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://verify.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a specific Rate Limit.
#
# GET /v2/Services/{ServiceSid}/RateLimits/{Sid}
# Returns: record<account_sid: string, date_created: string, date_updated: string, description: string, links: record, service_sid: string, sid: string, unique_name: string, url: string>
# operationId: FetchRateLimit
export def "fetch-rate-limit" [
  service_sid: string
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
    path: "/v2/Services/{ServiceSid}/RateLimits/{Sid}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://verify.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a specific Rate Limit.
#
# POST /v2/Services/{ServiceSid}/RateLimits/{Sid}
# Returns: record<account_sid: string, date_created: string, date_updated: string, description: string, links: record, service_sid: string, sid: string, unique_name: string, url: string>
# operationId: UpdateRateLimit
export def "update-rate-limit" [
  service_sid: string
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
  --description: string # Description of this Rate Limit
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/Services/{ServiceSid}/RateLimits/{Sid}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Description, var: description}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://verify.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, sid: $sid, description: $description
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# challenge a specific Verification Check.
#
# POST /v2/Services/{ServiceSid}/VerificationCheck
# Returns: record<account_sid: string, amount: string, channel: string, date_created: string, date_updated: string, payee: string, service_sid: string, sid: string, sna_attempts_error_codes: list<any>, status: string, to: string, valid: bool>
# operationId: CreateVerificationCheck
export def "create-verification-check" [
  service_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --amount: string # The amount of the associated PSD2 compliant transaction. Requires the PSD2 Service flag enabled.
  --code: string # The 4-10 character string being verified.
  --payee: string # The payee of the associated PSD2 compliant transaction. Requires the PSD2 Service flag enabled.
  --to: string # The phone number or [email](https://www.twilio.com/docs/verify/email) to verify. Either this parameter or the `verification_sid` must be specified. Phone numbers must be in [E.164 format](https://www.twilio.com/docs/glossary/what-e164).
  --verification-sid: string # A SID that uniquely identifies the Verification Check. Either this parameter or the `to` phone number/[email](https://www.twilio.com/docs/verify/email) must be specified.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/Services/{ServiceSid}/VerificationCheck"
    path_params: [{name: ServiceSid, var: service_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Amount, var: amount}, {name: Code, var: code}, {name: Payee, var: payee}, {name: To, var: to}, {name: VerificationSid, var: verification_sid}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://verify.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, amount: $amount, code: $code, payee: $payee, to: $to, verification_sid: $verification_sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new Verification using a Service
#
# POST /v2/Services/{ServiceSid}/Verifications
# Returns: record<account_sid: string, amount: string, channel: string, date_created: string, date_updated: string, lookup: any, payee: string, send_code_attempts: list<any>, service_sid: string, sid: string, sna: any, status: string, to: string, url: string, valid: bool>
# operationId: CreateVerification
export def "create-verification" [
  service_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --amount: string # The amount of the associated PSD2 compliant transaction. Requires the PSD2 Service flag enabled.
  --app-hash: string # Your [App Hash](https://developers.google.com/identity/sms-retriever/verify#computing_your_apps_hash_string) to be appended at the end of your verification SMS body. Applies only to SMS. Example SMS body: `<#> Your AppName verification code is: 1234 He42w354ol9`.
  channel: string # The verification method to use. One of: [`email`](https://www.twilio.com/docs/verify/email), `sms`, `whatsapp`, `call`, `sna` or `auto`.
  --channel-configuration: any # [`email`](https://www.twilio.com/docs/verify/email) channel configuration in json format. The fields 'from' and 'from_name' are optional but if included the 'from' field must have a valid email address.
  --custom-code: string # A pre-generated code to use for verification. The code can be between 4 and 10 characters, inclusive.
  --custom-friendly-name: string # A custom user defined friendly name that overwrites the existing one in the verification message
  --custom-message: string # The text of a custom message to use for the verification.
  --device-ip: string # Strongly encouraged if using the auto channel. The IP address of the client's device. If provided, it has to be a valid IPv4 or IPv6 address.
  --locale: string # Locale will automatically resolve based on phone number country code for SMS, WhatsApp, and call channel verifications. It will fallback to English or the template’s default translation if the selected translation is not available. This parameter will override the automatic locale resolution. [See supported languages and more information here](https://www.twilio.com/docs/verify/supported-languages).
  --payee: string # The payee of the associated PSD2 compliant transaction. Requires the PSD2 Service flag enabled.
  --rate-limits: any # The custom key-value pairs of Programmable Rate Limits. Keys correspond to `unique_name` fields defined when [creating your Rate Limit](https://www.twilio.com/docs/verify/api/service-rate-limits). Associated value pairs represent values in the request that you are rate limiting on. You may include multiple Rate Limit values in each request.
  --send-digits: string # The digits to send after a phone call is answered, for example, to dial an extension. For more information, see the Programmable Voice documentation of [sendDigits](https://www.twilio.com/docs/voice/twiml/number#attributes-sendDigits).
  --template-custom-substitutions: string # A stringified JSON object in which the keys are the template's special variables and the values are the variables substitutions.
  --template-sid: string # The message [template](https://www.twilio.com/docs/verify/api/templates). If provided, will override the default template for the Service. SMS and Voice channels only.
  to: string # The phone number or [email](https://www.twilio.com/docs/verify/email) to verify. Phone numbers must be in [E.164 format](https://www.twilio.com/docs/glossary/what-e164).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/Services/{ServiceSid}/Verifications"
    path_params: [{name: ServiceSid, var: service_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Amount, var: amount}, {name: AppHash, var: app_hash}, {name: Channel, var: channel}, {name: ChannelConfiguration, var: channel_configuration}, {name: CustomCode, var: custom_code}, {name: CustomFriendlyName, var: custom_friendly_name}, {name: CustomMessage, var: custom_message}, {name: DeviceIp, var: device_ip}, {name: Locale, var: locale}, {name: Payee, var: payee}, {name: RateLimits, var: rate_limits}, {name: SendDigits, var: send_digits}, {name: TemplateCustomSubstitutions, var: template_custom_substitutions}, {name: TemplateSid, var: template_sid}, {name: To, var: to}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://verify.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, amount: $amount, app_hash: $app_hash, channel: $channel, channel_configuration: $channel_configuration, custom_code: $custom_code, custom_friendly_name: $custom_friendly_name, custom_message: $custom_message, device_ip: $device_ip, locale: $locale, payee: $payee, rate_limits: $rate_limits, send_digits: $send_digits, template_custom_substitutions: $template_custom_substitutions, template_sid: $template_sid, to: $to
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a specific Verification
#
# GET /v2/Services/{ServiceSid}/Verifications/{Sid}
# Returns: record<account_sid: string, amount: string, channel: string, date_created: string, date_updated: string, lookup: any, payee: string, send_code_attempts: list<any>, service_sid: string, sid: string, sna: any, status: string, to: string, url: string, valid: bool>
# operationId: FetchVerification
export def "fetch-verification" [
  service_sid: string
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
    path: "/v2/Services/{ServiceSid}/Verifications/{Sid}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://verify.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a Verification status
#
# POST /v2/Services/{ServiceSid}/Verifications/{Sid}
# Returns: record<account_sid: string, amount: string, channel: string, date_created: string, date_updated: string, lookup: any, payee: string, send_code_attempts: list<any>, service_sid: string, sid: string, sna: any, status: string, to: string, url: string, valid: bool>
# operationId: UpdateVerification
export def "update-verification" [
  service_sid: string
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
  status: string@status-completer-2
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/Services/{ServiceSid}/Verifications/{Sid}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://verify.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, sid: $sid, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of all Webhooks for a Service.
#
# GET /v2/Services/{ServiceSid}/Webhooks
# Returns: record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, webhooks: table<account_sid: string, date_created: string, date_updated: string, event_types: list, friendly_name: string, service_sid: string, sid: string, status: string, url: string, version: string, webhook_method: string, webhook_url: string>>
# operationId: ListWebhook
export def "list-webhook" [
  service_sid: string
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
    path: "/v2/Services/{ServiceSid}/Webhooks"
    path_params: [{name: ServiceSid, var: service_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://verify.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new Webhook for the Service
#
# POST /v2/Services/{ServiceSid}/Webhooks
# Returns: record<account_sid: string, date_created: string, date_updated: string, event_types: list<string>, friendly_name: string, service_sid: string, sid: string, status: string, url: string, version: string, webhook_method: string, webhook_url: string>
# operationId: CreateWebhook
export def "create-webhook" [
  service_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  event_types: list<string> # The array of events that this Webhook is subscribed to. Possible event types: `*, factor.deleted, factor.created, factor.verified, challenge.approved, challenge.denied`
  friendly_name: string # The string that you assigned to describe the webhook. **This value should not contain PII.**
  --status: string@status-completer-3
  --version: string@version-completer
  webhook_url: string # The URL associated with this Webhook.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/Services/{ServiceSid}/Webhooks"
    path_params: [{name: ServiceSid, var: service_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: EventTypes, var: event_types}, {name: FriendlyName, var: friendly_name}, {name: Status, var: status}, {name: Version, var: version}, {name: WebhookUrl, var: webhook_url}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://verify.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, event_types: $event_types, friendly_name: $friendly_name, status: $status, version: $version, webhook_url: $webhook_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a specific Webhook.
#
# DELETE /v2/Services/{ServiceSid}/Webhooks/{Sid}
# operationId: DeleteWebhook
export def "delete-webhook" [
  service_sid: string
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
    path: "/v2/Services/{ServiceSid}/Webhooks/{Sid}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://verify.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a specific Webhook.
#
# GET /v2/Services/{ServiceSid}/Webhooks/{Sid}
# Returns: record<account_sid: string, date_created: string, date_updated: string, event_types: list<string>, friendly_name: string, service_sid: string, sid: string, status: string, url: string, version: string, webhook_method: string, webhook_url: string>
# operationId: FetchWebhook
export def "fetch-webhook" [
  service_sid: string
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
    path: "/v2/Services/{ServiceSid}/Webhooks/{Sid}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://verify.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v2/Services/{ServiceSid}/Webhooks/{Sid}
#
# Returns: record<account_sid: string, date_created: string, date_updated: string, event_types: list<string>, friendly_name: string, service_sid: string, sid: string, status: string, url: string, version: string, webhook_method: string, webhook_url: string>
# operationId: UpdateWebhook
export def "update-webhook" [
  service_sid: string
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
  --event-types: list<string> # The array of events that this Webhook is subscribed to. Possible event types: `*, factor.deleted, factor.created, factor.verified, challenge.approved, challenge.denied`
  --friendly-name: string # The string that you assigned to describe the webhook. **This value should not contain PII.**
  --status: string@status-completer-3
  --version: string@version-completer
  --webhook-url: string # The URL associated with this Webhook.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/Services/{ServiceSid}/Webhooks/{Sid}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: EventTypes, var: event_types}, {name: FriendlyName, var: friendly_name}, {name: Status, var: status}, {name: Version, var: version}, {name: WebhookUrl, var: webhook_url}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://verify.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, sid: $sid, event_types: $event_types, friendly_name: $friendly_name, status: $status, version: $version, webhook_url: $webhook_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a specific Verification Service Instance.
#
# DELETE /v2/Services/{Sid}
# operationId: DeleteService
export def "delete-service" [
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
    path: "/v2/Services/{Sid}"
    path_params: [{name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://verify.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch specific Verification Service Instance.
#
# GET /v2/Services/{Sid}
# Returns: record<account_sid: string, code_length: int, custom_code_enabled: bool, date_created: string, date_updated: string, default_template_sid: string, do_not_share_warning_enabled: bool, dtmf_input_required: bool, friendly_name: string, links: record, lookup_enabled: bool, psd2_enabled: bool, push: any, sid: string, skip_sms_to_landlines: bool, totp: any, tts_name: string, url: string>
# operationId: FetchService
export def "fetch-service" [
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
    path: "/v2/Services/{Sid}"
    path_params: [{name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://verify.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a specific Verification Service.
#
# POST /v2/Services/{Sid}
# Returns: record<account_sid: string, code_length: int, custom_code_enabled: bool, date_created: string, date_updated: string, default_template_sid: string, do_not_share_warning_enabled: bool, dtmf_input_required: bool, friendly_name: string, links: record, lookup_enabled: bool, psd2_enabled: bool, push: any, sid: string, skip_sms_to_landlines: bool, totp: any, tts_name: string, url: string>
# operationId: UpdateService
export def "update-service" [
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
  --code-length: int # The length of the verification code to generate. Must be an integer value between 4 and 10, inclusive.
  --custom-code-enabled: oneof<nothing, bool> # Whether to allow sending verifications with a custom code instead of a randomly generated one. Not available for all customers.
  --default-template-sid: string # The default message [template](https://www.twilio.com/docs/verify/api/templates). Will be used for all SMS verifications unless explicitly overriden. SMS channel only.
  --do-not-share-warning-enabled: oneof<nothing, bool> # Whether to add a privacy warning at the end of an SMS. **Disabled by default and applies only for SMS.**
  --dtmf-input-required: oneof<nothing, bool> # Whether to ask the user to press a number before delivering the verify code in a phone call.
  --friendly-name: string # A descriptive string that you create to describe the verification service. It can be up to 32 characters long. **This value should not contain PII.**
  --lookup-enabled: oneof<nothing, bool> # Whether to perform a lookup with each verification started and return info about the phone number.
  --psd2-enabled: oneof<nothing, bool> # Whether to pass PSD2 transaction parameters when starting a verification.
  --push-apn-credential-sid: string # Optional configuration for the Push factors. Set the APN Credential for this service. This will allow to send push notifications to iOS devices. See [Credential Resource](https://www.twilio.com/docs/notify/api/credential-resource)
  --push-fcm-credential-sid: string # Optional configuration for the Push factors. Set the FCM Credential for this service. This will allow to send push notifications to Android devices. See [Credential Resource](https://www.twilio.com/docs/notify/api/credential-resource)
  --push-include-date: oneof<nothing, bool> # Optional configuration for the Push factors. If true, include the date in the Challenge's response. Otherwise, the date is omitted from the response. See [Challenge](https://www.twilio.com/docs/verify/api/challenge) resource’s details parameter for more info. Default: false. **Deprecated** do not use this parameter.
  --skip-sms-to-landlines: oneof<nothing, bool> # Whether to skip sending SMS verifications to landlines. Requires `lookup_enabled`.
  --totp-code-length: int # Optional configuration for the TOTP factors. Number of digits for generated TOTP codes. Must be between 3 and 8, inclusive. Defaults to 6
  --totp-issuer: string # Optional configuration for the TOTP factors. Set TOTP Issuer for this service. This will allow to configure the issuer of the TOTP URI.
  --totp-skew: int # Optional configuration for the TOTP factors. The number of time-steps, past and future, that are valid for validation of TOTP codes. Must be between 0 and 2, inclusive. Defaults to 1
  --totp-time-step: int # Optional configuration for the TOTP factors. Defines how often, in seconds, are TOTP codes generated. i.e, a new TOTP code is generated every time_step seconds. Must be between 20 and 60 seconds, inclusive. Defaults to 30 seconds
  --tts-name: string # The name of an alternative text-to-speech service to use in phone calls. Applies only to TTS languages.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/Services/{Sid}"
    path_params: [{name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: CodeLength, var: code_length}, {name: CustomCodeEnabled, var: custom_code_enabled}, {name: DefaultTemplateSid, var: default_template_sid}, {name: DoNotShareWarningEnabled, var: do_not_share_warning_enabled}, {name: DtmfInputRequired, var: dtmf_input_required}, {name: FriendlyName, var: friendly_name}, {name: LookupEnabled, var: lookup_enabled}, {name: Psd2Enabled, var: psd2_enabled}, {name: "Push.ApnCredentialSid", var: push_apn_credential_sid}, {name: "Push.FcmCredentialSid", var: push_fcm_credential_sid}, {name: "Push.IncludeDate", var: push_include_date}, {name: SkipSmsToLandlines, var: skip_sms_to_landlines}, {name: "Totp.CodeLength", var: totp_code_length}, {name: "Totp.Issuer", var: totp_issuer}, {name: "Totp.Skew", var: totp_skew}, {name: "Totp.TimeStep", var: totp_time_step}, {name: TtsName, var: tts_name}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://verify.twilio.com"
    auth: basic
  } {
    sid: $sid, code_length: $code_length, custom_code_enabled: $custom_code_enabled, default_template_sid: $default_template_sid, do_not_share_warning_enabled: $do_not_share_warning_enabled, dtmf_input_required: $dtmf_input_required, friendly_name: $friendly_name, lookup_enabled: $lookup_enabled, psd2_enabled: $psd2_enabled, push_apn_credential_sid: $push_apn_credential_sid, push_fcm_credential_sid: $push_fcm_credential_sid, push_include_date: $push_include_date, skip_sms_to_landlines: $skip_sms_to_landlines, totp_code_length: $totp_code_length, totp_issuer: $totp_issuer, totp_skew: $totp_skew, totp_time_step: $totp_time_step, tts_name: $tts_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all the available templates for a given Account.
#
# GET /v2/Templates
# Returns: record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, templates: table<account_sid: string, channels: list, friendly_name: string, sid: string, translations: any>>
# operationId: ListVerificationTemplate
export def "list-verification-template" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --friendly-name: string # String filter used to query templates with a given friendly name.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/Templates"
    query: [{name: FriendlyName, var: friendly_name}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://verify.twilio.com"
    auth: basic
  } {
    friendly_name: $friendly_name, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
