# Auto-generated client for Twilio - Preview v1.42.0
# Source: https://api.apis.guru/v2/specs/twilio.com/twilio_preview/1.42.0/openapi.json
# Auth: --token flag or $env.TWILIO_PREVIEW_TOKEN

const CLIENT = {
  base_url: "https://preview.twilio.com"
  token_env_var: "TWILIO_PREVIEW_TOKEN"
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

def base-url-completer [] { ["https://preview.twilio.com"] }
def auth-scheme-completer [] { ["basic" "basic-credentials"] }

# Completers for enum parameters
def status-completer [] { ["canceled" "failed" "opened" "signed" "signing"] }
def status-completer-1 [] { ["action-required" "carrier-processing" "completed" "failed" "pending-loa" "pending-verification" "received" "testing" "verified"] }
def sms-fallback-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def sms-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def status-callback-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def verification-type-completer [] { ["phone-bill" "phone-call"] }
def order-completer [] { ["asc" "desc"] }
def bounds-completer [] { ["exclusive" "inclusive"] }
def commands-callback-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def voice-fallback-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def voice-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    list-deployed-devices-fleet: "record<fleets: table<account_sid: string, date_created: string, date_updated: string, default_deployment_sid: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    create-deployed-devices-fleet: "record<account_sid: string, date_created: string, date_updated: string, default_deployment_sid: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string>"
    list-deployed-devices-certificate: "record<certificates: table<account_sid: string, date_created: string, date_updated: string, device_sid: string, fleet_sid: string, friendly_name: string, sid: string, thumbprint: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    create-deployed-devices-certificate: "record<account_sid: string, date_created: string, date_updated: string, device_sid: string, fleet_sid: string, friendly_name: string, sid: string, thumbprint: string, url: string>"
    fetch-deployed-devices-certificate: "record<account_sid: string, date_created: string, date_updated: string, device_sid: string, fleet_sid: string, friendly_name: string, sid: string, thumbprint: string, url: string>"
    update-deployed-devices-certificate: "record<account_sid: string, date_created: string, date_updated: string, device_sid: string, fleet_sid: string, friendly_name: string, sid: string, thumbprint: string, url: string>"
    list-deployed-devices-deployment: "record<deployments: table<account_sid: string, date_created: string, date_updated: string, fleet_sid: string, friendly_name: string, sid: string, sync_service_sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    create-deployed-devices-deployment: "record<account_sid: string, date_created: string, date_updated: string, fleet_sid: string, friendly_name: string, sid: string, sync_service_sid: string, url: string>"
    fetch-deployed-devices-deployment: "record<account_sid: string, date_created: string, date_updated: string, fleet_sid: string, friendly_name: string, sid: string, sync_service_sid: string, url: string>"
    update-deployed-devices-deployment: "record<account_sid: string, date_created: string, date_updated: string, fleet_sid: string, friendly_name: string, sid: string, sync_service_sid: string, url: string>"
    list-deployed-devices-device: "record<devices: table<account_sid: string, date_authenticated: string, date_created: string, date_updated: string, deployment_sid: string, enabled: bool, fleet_sid: string, friendly_name: string, identity: string, sid: string, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    create-deployed-devices-device: "record<account_sid: string, date_authenticated: string, date_created: string, date_updated: string, deployment_sid: string, enabled: bool, fleet_sid: string, friendly_name: string, identity: string, sid: string, unique_name: string, url: string>"
    fetch-deployed-devices-device: "record<account_sid: string, date_authenticated: string, date_created: string, date_updated: string, deployment_sid: string, enabled: bool, fleet_sid: string, friendly_name: string, identity: string, sid: string, unique_name: string, url: string>"
    update-deployed-devices-device: "record<account_sid: string, date_authenticated: string, date_created: string, date_updated: string, deployment_sid: string, enabled: bool, fleet_sid: string, friendly_name: string, identity: string, sid: string, unique_name: string, url: string>"
    list-deployed-devices-key: "record<keys: table<account_sid: string, date_created: string, date_updated: string, device_sid: string, fleet_sid: string, friendly_name: string, secret: string, sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    create-deployed-devices-key: "record<account_sid: string, date_created: string, date_updated: string, device_sid: string, fleet_sid: string, friendly_name: string, secret: string, sid: string, url: string>"
    fetch-deployed-devices-key: "record<account_sid: string, date_created: string, date_updated: string, device_sid: string, fleet_sid: string, friendly_name: string, secret: string, sid: string, url: string>"
    update-deployed-devices-key: "record<account_sid: string, date_created: string, date_updated: string, device_sid: string, fleet_sid: string, friendly_name: string, secret: string, sid: string, url: string>"
    fetch-deployed-devices-fleet: "record<account_sid: string, date_created: string, date_updated: string, default_deployment_sid: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string>"
    update-deployed-devices-fleet: "record<account_sid: string, date_created: string, date_updated: string, default_deployment_sid: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string>"
    list-hosted-numbers-authorization-document: "record<items: table<address_sid: string, cc_emails: list, date_created: string, date_updated: string, email: string, links: record, sid: string, status: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    create-hosted-numbers-authorization-document: "record<address_sid: string, cc_emails: list<string>, date_created: string, date_updated: string, email: string, links: record, sid: string, status: string, url: string>"
    fetch-hosted-numbers-authorization-document: "record<address_sid: string, cc_emails: list<string>, date_created: string, date_updated: string, email: string, links: record, sid: string, status: string, url: string>"
    update-hosted-numbers-authorization-document: "record<address_sid: string, cc_emails: list<string>, date_created: string, date_updated: string, email: string, links: record, sid: string, status: string, url: string>"
    list-hosted-numbers-dependent-hosted-number-order: "record<items: table<account_sid: string, address_sid: string, call_delay: int, capabilities: record, cc_emails: list, date_created: string, date_updated: string, email: string, extension: string, failure_reason: string, friendly_name: string, incoming_phone_number_sid: string, phone_number: string, sid: string, signing_document_sid: string, status: string, unique_name: string, verification_attempts: int, verification_call_sids: list, verification_code: string, verification_document_sid: string, verification_type: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    list-hosted-numbers-hosted-number-order: "record<items: table<account_sid: string, address_sid: string, call_delay: int, capabilities: record, cc_emails: list, date_created: string, date_updated: string, email: string, extension: string, failure_reason: string, friendly_name: string, incoming_phone_number_sid: string, phone_number: string, sid: string, signing_document_sid: string, status: string, unique_name: string, url: string, verification_attempts: int, verification_call_sids: list, verification_code: string, verification_document_sid: string, verification_type: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    create-hosted-numbers-hosted-number-order: "record<account_sid: string, address_sid: string, call_delay: int, capabilities: record<fax: bool, mms: bool, sms: bool, voice: bool>, cc_emails: list<string>, date_created: string, date_updated: string, email: string, extension: string, failure_reason: string, friendly_name: string, incoming_phone_number_sid: string, phone_number: string, sid: string, signing_document_sid: string, status: string, unique_name: string, url: string, verification_attempts: int, verification_call_sids: list<string>, verification_code: string, verification_document_sid: string, verification_type: string>"
    fetch-hosted-numbers-hosted-number-order: "record<account_sid: string, address_sid: string, call_delay: int, capabilities: record<fax: bool, mms: bool, sms: bool, voice: bool>, cc_emails: list<string>, date_created: string, date_updated: string, email: string, extension: string, failure_reason: string, friendly_name: string, incoming_phone_number_sid: string, phone_number: string, sid: string, signing_document_sid: string, status: string, unique_name: string, url: string, verification_attempts: int, verification_call_sids: list<string>, verification_code: string, verification_document_sid: string, verification_type: string>"
    update-hosted-numbers-hosted-number-order: "record<account_sid: string, address_sid: string, call_delay: int, capabilities: record<fax: bool, mms: bool, sms: bool, voice: bool>, cc_emails: list<string>, date_created: string, date_updated: string, email: string, extension: string, failure_reason: string, friendly_name: string, incoming_phone_number_sid: string, phone_number: string, sid: string, signing_document_sid: string, status: string, unique_name: string, url: string, verification_attempts: int, verification_call_sids: list<string>, verification_code: string, verification_document_sid: string, verification_type: string>"
    list-sync-service: "record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, services: table<account_sid: string, acl_enabled: bool, date_created: string, date_updated: string, friendly_name: string, links: record, reachability_webhooks_enabled: bool, sid: string, url: string, webhook_url: string>>"
    create-sync-service: "record<account_sid: string, acl_enabled: bool, date_created: string, date_updated: string, friendly_name: string, links: record, reachability_webhooks_enabled: bool, sid: string, url: string, webhook_url: string>"
    list-sync-document: "record<documents: table<account_sid: string, created_by: string, data: any, date_created: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    create-sync-document: "record<account_sid: string, created_by: string, data: any, date_created: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string>"
    list-sync-document-permission: "record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, permissions: table<account_sid: string, document_sid: string, identity: string, manage: bool, read: bool, service_sid: string, url: string, write: bool>>"
    fetch-sync-document-permission: "record<account_sid: string, document_sid: string, identity: string, manage: bool, read: bool, service_sid: string, url: string, write: bool>"
    update-sync-document-permission: "record<account_sid: string, document_sid: string, identity: string, manage: bool, read: bool, service_sid: string, url: string, write: bool>"
    fetch-sync-document: "record<account_sid: string, created_by: string, data: any, date_created: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string>"
    update-sync-document: "record<account_sid: string, created_by: string, data: any, date_created: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string>"
    list-sync-sync-list: "record<lists: table<account_sid: string, created_by: string, date_created: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    create-sync-sync-list: "record<account_sid: string, created_by: string, date_created: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string>"
    list-sync-sync-list-item: "record<items: table<account_sid: string, created_by: string, data: any, date_created: string, date_updated: string, index: int, list_sid: string, revision: string, service_sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    create-sync-sync-list-item: "record<account_sid: string, created_by: string, data: any, date_created: string, date_updated: string, index: int, list_sid: string, revision: string, service_sid: string, url: string>"
    fetch-sync-sync-list-item: "record<account_sid: string, created_by: string, data: any, date_created: string, date_updated: string, index: int, list_sid: string, revision: string, service_sid: string, url: string>"
    update-sync-sync-list-item: "record<account_sid: string, created_by: string, data: any, date_created: string, date_updated: string, index: int, list_sid: string, revision: string, service_sid: string, url: string>"
    list-sync-sync-list-permission: "record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, permissions: table<account_sid: string, identity: string, list_sid: string, manage: bool, read: bool, service_sid: string, url: string, write: bool>>"
    fetch-sync-sync-list-permission: "record<account_sid: string, identity: string, list_sid: string, manage: bool, read: bool, service_sid: string, url: string, write: bool>"
    update-sync-sync-list-permission: "record<account_sid: string, identity: string, list_sid: string, manage: bool, read: bool, service_sid: string, url: string, write: bool>"
    fetch-sync-sync-list: "record<account_sid: string, created_by: string, date_created: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string>"
    list-sync-sync-map: "record<maps: table<account_sid: string, created_by: string, date_created: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    create-sync-sync-map: "record<account_sid: string, created_by: string, date_created: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string>"
    list-sync-sync-map-item: "record<items: table<account_sid: string, created_by: string, data: any, date_created: string, date_updated: string, key: string, map_sid: string, revision: string, service_sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    create-sync-sync-map-item: "record<account_sid: string, created_by: string, data: any, date_created: string, date_updated: string, key: string, map_sid: string, revision: string, service_sid: string, url: string>"
    fetch-sync-sync-map-item: "record<account_sid: string, created_by: string, data: any, date_created: string, date_updated: string, key: string, map_sid: string, revision: string, service_sid: string, url: string>"
    update-sync-sync-map-item: "record<account_sid: string, created_by: string, data: any, date_created: string, date_updated: string, key: string, map_sid: string, revision: string, service_sid: string, url: string>"
    list-sync-sync-map-permission: "record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, permissions: table<account_sid: string, identity: string, manage: bool, map_sid: string, read: bool, service_sid: string, url: string, write: bool>>"
    fetch-sync-sync-map-permission: "record<account_sid: string, identity: string, manage: bool, map_sid: string, read: bool, service_sid: string, url: string, write: bool>"
    update-sync-sync-map-permission: "record<account_sid: string, identity: string, manage: bool, map_sid: string, read: bool, service_sid: string, url: string, write: bool>"
    fetch-sync-sync-map: "record<account_sid: string, created_by: string, date_created: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string>"
    fetch-sync-service: "record<account_sid: string, acl_enabled: bool, date_created: string, date_updated: string, friendly_name: string, links: record, reachability_webhooks_enabled: bool, sid: string, url: string, webhook_url: string>"
    update-sync-service: "record<account_sid: string, acl_enabled: bool, date_created: string, date_updated: string, friendly_name: string, links: record, reachability_webhooks_enabled: bool, sid: string, url: string, webhook_url: string>"
    list-marketplace-available-add-on: "record<available_add_ons: table<configuration_schema: any, description: string, friendly_name: string, links: record, pricing_type: string, sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    list-marketplace-available-add-on-extension: "record<extensions: table<available_add_on_sid: string, friendly_name: string, product_name: string, sid: string, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    fetch-marketplace-available-add-on-extension: "record<available_add_on_sid: string, friendly_name: string, product_name: string, sid: string, unique_name: string, url: string>"
    fetch-marketplace-available-add-on: "record<configuration_schema: any, description: string, friendly_name: string, links: record, pricing_type: string, sid: string, url: string>"
    list-marketplace-installed-add-on: "record<installed_add_ons: table<account_sid: string, configuration: any, date_created: string, date_updated: string, description: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    create-marketplace-installed-add-on: "record<account_sid: string, configuration: any, date_created: string, date_updated: string, description: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string>"
    list-marketplace-installed-add-on-extension: "record<extensions: table<enabled: bool, friendly_name: string, installed_add_on_sid: string, product_name: string, sid: string, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    fetch-marketplace-installed-add-on-extension: "record<enabled: bool, friendly_name: string, installed_add_on_sid: string, product_name: string, sid: string, unique_name: string, url: string>"
    update-marketplace-installed-add-on-extension: "record<enabled: bool, friendly_name: string, installed_add_on_sid: string, product_name: string, sid: string, unique_name: string, url: string>"
    fetch-marketplace-installed-add-on: "record<account_sid: string, configuration: any, date_created: string, date_updated: string, description: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string>"
    update-marketplace-installed-add-on: "record<account_sid: string, configuration: any, date_created: string, date_updated: string, description: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string>"
    list-understand-assistant: "record<assistants: table<account_sid: string, callback_events: string, callback_url: string, date_created: string, date_updated: string, friendly_name: string, latest_model_build_sid: string, links: record, log_queries: bool, sid: string, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    create-understand-assistant: "record<account_sid: string, callback_events: string, callback_url: string, date_created: string, date_updated: string, friendly_name: string, latest_model_build_sid: string, links: record, log_queries: bool, sid: string, unique_name: string, url: string>"
    fetch-understand-dialogue: "record<account_sid: string, assistant_sid: string, data: any, sid: string, url: string>"
    fetch-understand-assistant-fallback-actions: "record<account_sid: string, assistant_sid: string, data: any, url: string>"
    update-understand-assistant-fallback-actions: "record<account_sid: string, assistant_sid: string, data: any, url: string>"
    list-understand-field-type: "record<field_types: table<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    create-understand-field-type: "record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string>"
    list-understand-field-value: "record<field_values: table<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, field_type_sid: string, language: string, sid: string, synonym_of: string, url: string, value: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    create-understand-field-value: "record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, field_type_sid: string, language: string, sid: string, synonym_of: string, url: string, value: string>"
    fetch-understand-field-value: "record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, field_type_sid: string, language: string, sid: string, synonym_of: string, url: string, value: string>"
    fetch-understand-field-type: "record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string>"
    update-understand-field-type: "record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string>"
    fetch-understand-assistant-initiation-actions: "record<account_sid: string, assistant_sid: string, data: any, url: string>"
    update-understand-assistant-initiation-actions: "record<account_sid: string, assistant_sid: string, data: any, url: string>"
    list-understand-model-build: "record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, model_builds: table<account_sid: string, assistant_sid: string, build_duration: int, date_created: string, date_updated: string, error_code: int, sid: string, status: string, unique_name: string, url: string>>"
    create-understand-model-build: "record<account_sid: string, assistant_sid: string, build_duration: int, date_created: string, date_updated: string, error_code: int, sid: string, status: string, unique_name: string, url: string>"
    fetch-understand-model-build: "record<account_sid: string, assistant_sid: string, build_duration: int, date_created: string, date_updated: string, error_code: int, sid: string, status: string, unique_name: string, url: string>"
    update-understand-model-build: "record<account_sid: string, assistant_sid: string, build_duration: int, date_created: string, date_updated: string, error_code: int, sid: string, status: string, unique_name: string, url: string>"
    list-understand-query: "record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, queries: table<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, language: string, model_build_sid: string, query: string, results: any, sample_sid: string, sid: string, source_channel: string, status: string, url: string>>"
    create-understand-query: "record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, language: string, model_build_sid: string, query: string, results: any, sample_sid: string, sid: string, source_channel: string, status: string, url: string>"
    fetch-understand-query: "record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, language: string, model_build_sid: string, query: string, results: any, sample_sid: string, sid: string, source_channel: string, status: string, url: string>"
    update-understand-query: "record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, language: string, model_build_sid: string, query: string, results: any, sample_sid: string, sid: string, source_channel: string, status: string, url: string>"
    fetch-understand-style-sheet: "record<account_sid: string, assistant_sid: string, data: any, url: string>"
    update-understand-style-sheet: "record<account_sid: string, assistant_sid: string, data: any, url: string>"
    list-understand-task: "record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, tasks: table<account_sid: string, actions_url: string, assistant_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string>>"
    create-understand-task: "record<account_sid: string, actions_url: string, assistant_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string>"
    fetch-understand-task: "record<account_sid: string, actions_url: string, assistant_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string>"
    update-understand-task: "record<account_sid: string, actions_url: string, assistant_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string>"
    fetch-understand-task-actions: "record<account_sid: string, assistant_sid: string, data: any, task_sid: string, url: string>"
    update-understand-task-actions: "record<account_sid: string, assistant_sid: string, data: any, task_sid: string, url: string>"
    list-understand-field: "record<fields: table<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, field_type: string, sid: string, task_sid: string, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    create-understand-field: "record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, field_type: string, sid: string, task_sid: string, unique_name: string, url: string>"
    fetch-understand-field: "record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, field_type: string, sid: string, task_sid: string, unique_name: string, url: string>"
    list-understand-sample: "record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, samples: table<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, language: string, sid: string, source_channel: string, tagged_text: string, task_sid: string, url: string>>"
    create-understand-sample: "record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, language: string, sid: string, source_channel: string, tagged_text: string, task_sid: string, url: string>"
    fetch-understand-sample: "record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, language: string, sid: string, source_channel: string, tagged_text: string, task_sid: string, url: string>"
    update-understand-sample: "record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, language: string, sid: string, source_channel: string, tagged_text: string, task_sid: string, url: string>"
    fetch-understand-task-statistics: "record<account_sid: string, assistant_sid: string, fields_count: int, samples_count: int, task_sid: string, url: string>"
    fetch-understand-assistant: "record<account_sid: string, callback_events: string, callback_url: string, date_created: string, date_updated: string, friendly_name: string, latest_model_build_sid: string, links: record, log_queries: bool, sid: string, unique_name: string, url: string>"
    update-understand-assistant: "record<account_sid: string, callback_events: string, callback_url: string, date_created: string, date_updated: string, friendly_name: string, latest_model_build_sid: string, links: record, log_queries: bool, sid: string, unique_name: string, url: string>"
    list-wireless-command: "record<commands: table<account_sid: string, command: string, command_mode: string, date_created: string, date_updated: string, device_sid: string, direction: string, sid: string, sim_sid: string, status: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    create-wireless-command: "record<account_sid: string, command: string, command_mode: string, date_created: string, date_updated: string, device_sid: string, direction: string, sid: string, sim_sid: string, status: string, url: string>"
    fetch-wireless-command: "record<account_sid: string, command: string, command_mode: string, date_created: string, date_updated: string, device_sid: string, direction: string, sid: string, sim_sid: string, status: string, url: string>"
    list-wireless-rate-plan: "record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, rate_plans: table<account_sid: string, data_enabled: bool, data_limit: int, data_metering: string, date_created: string, date_updated: string, friendly_name: string, international_roaming: list, messaging_enabled: bool, national_roaming_enabled: bool, sid: string, unique_name: string, url: string, voice_enabled: bool>>"
    create-wireless-rate-plan: "record<account_sid: string, data_enabled: bool, data_limit: int, data_metering: string, date_created: string, date_updated: string, friendly_name: string, international_roaming: list<string>, messaging_enabled: bool, national_roaming_enabled: bool, sid: string, unique_name: string, url: string, voice_enabled: bool>"
    fetch-wireless-rate-plan: "record<account_sid: string, data_enabled: bool, data_limit: int, data_metering: string, date_created: string, date_updated: string, friendly_name: string, international_roaming: list<string>, messaging_enabled: bool, national_roaming_enabled: bool, sid: string, unique_name: string, url: string, voice_enabled: bool>"
    update-wireless-rate-plan: "record<account_sid: string, data_enabled: bool, data_limit: int, data_metering: string, date_created: string, date_updated: string, friendly_name: string, international_roaming: list<string>, messaging_enabled: bool, national_roaming_enabled: bool, sid: string, unique_name: string, url: string, voice_enabled: bool>"
    list-wireless-sim: "record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, sims: table<account_sid: string, commands_callback_method: string, commands_callback_url: string, date_created: string, date_updated: string, e_id: string, friendly_name: string, iccid: string, links: record, rate_plan_sid: string, sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, status: string, unique_name: string, url: string, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_url: string>>"
    fetch-wireless-sim: "record<account_sid: string, commands_callback_method: string, commands_callback_url: string, date_created: string, date_updated: string, e_id: string, friendly_name: string, iccid: string, links: record, rate_plan_sid: string, sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, status: string, unique_name: string, url: string, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_url: string>"
    update-wireless-sim: "record<account_sid: string, commands_callback_method: string, commands_callback_url: string, date_created: string, date_updated: string, e_id: string, friendly_name: string, iccid: string, links: record, rate_plan_sid: string, sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, status: string, unique_name: string, url: string, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_url: string>"
    fetch-wireless-usage: "record<account_sid: string, commands_costs: any, commands_usage: any, data_costs: any, data_usage: any, period: any, sim_sid: string, sim_unique_name: string, url: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["list-deployed-devices-fleet" "create-deployed-devices-fleet" "list-deployed-devices-certificate" "create-deployed-devices-certificate" "delete-deployed-devices-certificate" "fetch-deployed-devices-certificate" "update-deployed-devices-certificate" "list-deployed-devices-deployment" "create-deployed-devices-deployment" "delete-deployed-devices-deployment" "fetch-deployed-devices-deployment" "update-deployed-devices-deployment" "list-deployed-devices-device" "create-deployed-devices-device" "delete-deployed-devices-device" "fetch-deployed-devices-device" "update-deployed-devices-device" "list-deployed-devices-key" "create-deployed-devices-key" "delete-deployed-devices-key" "fetch-deployed-devices-key" "update-deployed-devices-key" "delete-deployed-devices-fleet" "fetch-deployed-devices-fleet" "update-deployed-devices-fleet" "list-hosted-numbers-authorization-document" "create-hosted-numbers-authorization-document" "fetch-hosted-numbers-authorization-document" "update-hosted-numbers-authorization-document" "list-hosted-numbers-dependent-hosted-number-order" "list-hosted-numbers-hosted-number-order" "create-hosted-numbers-hosted-number-order" "delete-hosted-numbers-hosted-number-order" "fetch-hosted-numbers-hosted-number-order" "update-hosted-numbers-hosted-number-order" "list-sync-service" "create-sync-service" "list-sync-document" "create-sync-document" "list-sync-document-permission" "delete-sync-document-permission" "fetch-sync-document-permission" "update-sync-document-permission" "delete-sync-document" "fetch-sync-document" "update-sync-document" "list-sync-sync-list" "create-sync-sync-list" "list-sync-sync-list-item" "create-sync-sync-list-item" "delete-sync-sync-list-item" "fetch-sync-sync-list-item" "update-sync-sync-list-item" "list-sync-sync-list-permission" "delete-sync-sync-list-permission" "fetch-sync-sync-list-permission" "update-sync-sync-list-permission" "delete-sync-sync-list" "fetch-sync-sync-list" "list-sync-sync-map" "create-sync-sync-map" "list-sync-sync-map-item" "create-sync-sync-map-item" "delete-sync-sync-map-item" "fetch-sync-sync-map-item" "update-sync-sync-map-item" "list-sync-sync-map-permission" "delete-sync-sync-map-permission" "fetch-sync-sync-map-permission" "update-sync-sync-map-permission" "delete-sync-sync-map" "fetch-sync-sync-map" "delete-sync-service" "fetch-sync-service" "update-sync-service" "list-marketplace-available-add-on" "list-marketplace-available-add-on-extension" "fetch-marketplace-available-add-on-extension" "fetch-marketplace-available-add-on" "list-marketplace-installed-add-on" "create-marketplace-installed-add-on" "list-marketplace-installed-add-on-extension" "fetch-marketplace-installed-add-on-extension" "update-marketplace-installed-add-on-extension" "delete-marketplace-installed-add-on" "fetch-marketplace-installed-add-on" "update-marketplace-installed-add-on" "list-understand-assistant" "create-understand-assistant" "fetch-understand-dialogue" "fetch-understand-assistant-fallback-actions" "update-understand-assistant-fallback-actions" "list-understand-field-type" "create-understand-field-type" "list-understand-field-value" "create-understand-field-value" "delete-understand-field-value" "fetch-understand-field-value" "delete-understand-field-type" "fetch-understand-field-type" "update-understand-field-type" "fetch-understand-assistant-initiation-actions" "update-understand-assistant-initiation-actions" "list-understand-model-build" "create-understand-model-build" "delete-understand-model-build" "fetch-understand-model-build" "update-understand-model-build" "list-understand-query" "create-understand-query" "delete-understand-query" "fetch-understand-query" "update-understand-query" "fetch-understand-style-sheet" "update-understand-style-sheet" "list-understand-task" "create-understand-task" "delete-understand-task" "fetch-understand-task" "update-understand-task" "fetch-understand-task-actions" "update-understand-task-actions" "list-understand-field" "create-understand-field" "delete-understand-field" "fetch-understand-field" "list-understand-sample" "create-understand-sample" "delete-understand-sample" "fetch-understand-sample" "update-understand-sample" "fetch-understand-task-statistics" "delete-understand-assistant" "fetch-understand-assistant" "update-understand-assistant" "list-wireless-command" "create-wireless-command" "fetch-wireless-command" "list-wireless-rate-plan" "create-wireless-rate-plan" "delete-wireless-rate-plan" "fetch-wireless-rate-plan" "update-wireless-rate-plan" "list-wireless-sim" "fetch-wireless-sim" "update-wireless-sim" "fetch-wireless-usage" "commands"] | sort) } | get name | first)
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

# Retrieve a list of all Fleets belonging to your account.
#
# GET /DeployedDevices/Fleets
# Returns: record<fleets: table<account_sid: string, date_created: string, date_updated: string, default_deployment_sid: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListDeployedDevicesFleet
export def "list-deployed-devices-fleet" [
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
    path: "/DeployedDevices/Fleets"
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new Fleet for scoping of deployed devices within your account.
#
# POST /DeployedDevices/Fleets
# Returns: record<account_sid: string, date_created: string, date_updated: string, default_deployment_sid: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string>
# operationId: CreateDeployedDevicesFleet
export def "create-deployed-devices-fleet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --friendly-name: string # Provides a human readable descriptive text for this Fleet, up to 256 characters long.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/DeployedDevices/Fleets"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: FriendlyName, var: friendly_name}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    friendly_name: $friendly_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of all Certificate credentials belonging to the Fleet.
#
# GET /DeployedDevices/Fleets/{FleetSid}/Certificates
# Returns: record<certificates: table<account_sid: string, date_created: string, date_updated: string, device_sid: string, fleet_sid: string, friendly_name: string, sid: string, thumbprint: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListDeployedDevicesCertificate
export def "list-deployed-devices-certificate" [
  fleet_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --device-sid: string # Filters the resulting list of Certificates by a unique string identifier of an authenticated Device.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/DeployedDevices/Fleets/{FleetSid}/Certificates"
    path_params: [{name: FleetSid, var: fleet_sid}]
    query: [{name: DeviceSid, var: device_sid}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    fleet_sid: $fleet_sid, device_sid: $device_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enroll a new Certificate credential to the Fleet, optionally giving it a friendly name and assigning to a Device.
#
# POST /DeployedDevices/Fleets/{FleetSid}/Certificates
# Returns: record<account_sid: string, date_created: string, date_updated: string, device_sid: string, fleet_sid: string, friendly_name: string, sid: string, thumbprint: string, url: string>
# operationId: CreateDeployedDevicesCertificate
export def "create-deployed-devices-certificate" [
  fleet_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  certificate_data: string # Provides a URL encoded representation of the public certificate in PEM format.
  --device-sid: string # Provides the unique string identifier of an existing Device to become authenticated with this Certificate credential.
  --friendly-name: string # Provides a human readable descriptive text for this Certificate credential, up to 256 characters long.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/DeployedDevices/Fleets/{FleetSid}/Certificates"
    path_params: [{name: FleetSid, var: fleet_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: CertificateData, var: certificate_data}, {name: DeviceSid, var: device_sid}, {name: FriendlyName, var: friendly_name}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    fleet_sid: $fleet_sid, certificate_data: $certificate_data, device_sid: $device_sid, friendly_name: $friendly_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unregister a specific Certificate credential from the Fleet, effectively disallowing any inbound client connections that are presenting it.
#
# DELETE /DeployedDevices/Fleets/{FleetSid}/Certificates/{Sid}
# operationId: DeleteDeployedDevicesCertificate
export def "delete-deployed-devices-certificate" [
  fleet_sid: string
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
    path: "/DeployedDevices/Fleets/{FleetSid}/Certificates/{Sid}"
    path_params: [{name: FleetSid, var: fleet_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    fleet_sid: $fleet_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch information about a specific Certificate credential in the Fleet.
#
# GET /DeployedDevices/Fleets/{FleetSid}/Certificates/{Sid}
# Returns: record<account_sid: string, date_created: string, date_updated: string, device_sid: string, fleet_sid: string, friendly_name: string, sid: string, thumbprint: string, url: string>
# operationId: FetchDeployedDevicesCertificate
export def "fetch-deployed-devices-certificate" [
  fleet_sid: string
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
    path: "/DeployedDevices/Fleets/{FleetSid}/Certificates/{Sid}"
    path_params: [{name: FleetSid, var: fleet_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    fleet_sid: $fleet_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the given properties of a specific Certificate credential in the Fleet, giving it a friendly name or assigning to a Device.
#
# POST /DeployedDevices/Fleets/{FleetSid}/Certificates/{Sid}
# Returns: record<account_sid: string, date_created: string, date_updated: string, device_sid: string, fleet_sid: string, friendly_name: string, sid: string, thumbprint: string, url: string>
# operationId: UpdateDeployedDevicesCertificate
export def "update-deployed-devices-certificate" [
  fleet_sid: string
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
  --device-sid: string # Provides the unique string identifier of an existing Device to become authenticated with this Certificate credential.
  --friendly-name: string # Provides a human readable descriptive text for this Certificate credential, up to 256 characters long.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/DeployedDevices/Fleets/{FleetSid}/Certificates/{Sid}"
    path_params: [{name: FleetSid, var: fleet_sid}, {name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: DeviceSid, var: device_sid}, {name: FriendlyName, var: friendly_name}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    fleet_sid: $fleet_sid, sid: $sid, device_sid: $device_sid, friendly_name: $friendly_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of all Deployments belonging to the Fleet.
#
# GET /DeployedDevices/Fleets/{FleetSid}/Deployments
# Returns: record<deployments: table<account_sid: string, date_created: string, date_updated: string, fleet_sid: string, friendly_name: string, sid: string, sync_service_sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListDeployedDevicesDeployment
export def "list-deployed-devices-deployment" [
  fleet_sid: string
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
    path: "/DeployedDevices/Fleets/{FleetSid}/Deployments"
    path_params: [{name: FleetSid, var: fleet_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    fleet_sid: $fleet_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new Deployment in the Fleet, optionally giving it a friendly name and linking to a specific Twilio Sync service instance.
#
# POST /DeployedDevices/Fleets/{FleetSid}/Deployments
# Returns: record<account_sid: string, date_created: string, date_updated: string, fleet_sid: string, friendly_name: string, sid: string, sync_service_sid: string, url: string>
# operationId: CreateDeployedDevicesDeployment
export def "create-deployed-devices-deployment" [
  fleet_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --friendly-name: string # Provides a human readable descriptive text for this Deployment, up to 256 characters long.
  --sync-service-sid: string # Provides the unique string identifier of the Twilio Sync service instance that will be linked to and accessible by this Deployment.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/DeployedDevices/Fleets/{FleetSid}/Deployments"
    path_params: [{name: FleetSid, var: fleet_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: FriendlyName, var: friendly_name}, {name: SyncServiceSid, var: sync_service_sid}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    fleet_sid: $fleet_sid, friendly_name: $friendly_name, sync_service_sid: $sync_service_sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a specific Deployment from the Fleet, leaving associated devices effectively undeployed.
#
# DELETE /DeployedDevices/Fleets/{FleetSid}/Deployments/{Sid}
# operationId: DeleteDeployedDevicesDeployment
export def "delete-deployed-devices-deployment" [
  fleet_sid: string
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
    path: "/DeployedDevices/Fleets/{FleetSid}/Deployments/{Sid}"
    path_params: [{name: FleetSid, var: fleet_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    fleet_sid: $fleet_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch information about a specific Deployment in the Fleet.
#
# GET /DeployedDevices/Fleets/{FleetSid}/Deployments/{Sid}
# Returns: record<account_sid: string, date_created: string, date_updated: string, fleet_sid: string, friendly_name: string, sid: string, sync_service_sid: string, url: string>
# operationId: FetchDeployedDevicesDeployment
export def "fetch-deployed-devices-deployment" [
  fleet_sid: string
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
    path: "/DeployedDevices/Fleets/{FleetSid}/Deployments/{Sid}"
    path_params: [{name: FleetSid, var: fleet_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    fleet_sid: $fleet_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the given properties of a specific Deployment credential in the Fleet, giving it a friendly name or linking to a specific Twilio Sync service instance.
#
# POST /DeployedDevices/Fleets/{FleetSid}/Deployments/{Sid}
# Returns: record<account_sid: string, date_created: string, date_updated: string, fleet_sid: string, friendly_name: string, sid: string, sync_service_sid: string, url: string>
# operationId: UpdateDeployedDevicesDeployment
export def "update-deployed-devices-deployment" [
  fleet_sid: string
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
  --friendly-name: string # Provides a human readable descriptive text for this Deployment, up to 64 characters long
  --sync-service-sid: string # Provides the unique string identifier of the Twilio Sync service instance that will be linked to and accessible by this Deployment.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/DeployedDevices/Fleets/{FleetSid}/Deployments/{Sid}"
    path_params: [{name: FleetSid, var: fleet_sid}, {name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: FriendlyName, var: friendly_name}, {name: SyncServiceSid, var: sync_service_sid}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    fleet_sid: $fleet_sid, sid: $sid, friendly_name: $friendly_name, sync_service_sid: $sync_service_sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of all Devices belonging to the Fleet.
#
# GET /DeployedDevices/Fleets/{FleetSid}/Devices
# Returns: record<devices: table<account_sid: string, date_authenticated: string, date_created: string, date_updated: string, deployment_sid: string, enabled: bool, fleet_sid: string, friendly_name: string, identity: string, sid: string, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListDeployedDevicesDevice
export def "list-deployed-devices-device" [
  fleet_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --deployment-sid: string # Filters the resulting list of Devices by a unique string identifier of the Deployment they are associated with.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/DeployedDevices/Fleets/{FleetSid}/Devices"
    path_params: [{name: FleetSid, var: fleet_sid}]
    query: [{name: DeploymentSid, var: deployment_sid}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    fleet_sid: $fleet_sid, deployment_sid: $deployment_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new Device in the Fleet, optionally giving it a unique name, friendly name, and assigning to a Deployment and/or human identity.
#
# POST /DeployedDevices/Fleets/{FleetSid}/Devices
# Returns: record<account_sid: string, date_authenticated: string, date_created: string, date_updated: string, deployment_sid: string, enabled: bool, fleet_sid: string, friendly_name: string, identity: string, sid: string, unique_name: string, url: string>
# operationId: CreateDeployedDevicesDevice
export def "create-deployed-devices-device" [
  fleet_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --deployment-sid: string # Specifies the unique string identifier of the Deployment group that this Device is going to be associated with.
  --enabled: oneof<nothing, bool>
  --friendly-name: string # Provides a human readable descriptive text to be assigned to this Device, up to 256 characters long.
  --identity: string # Provides an arbitrary string identifier representing a human user to be associated with this Device, up to 256 characters long.
  --unique-name: string # Provides a unique and addressable name to be assigned to this Device, to be used in addition to SID, up to 128 characters long.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/DeployedDevices/Fleets/{FleetSid}/Devices"
    path_params: [{name: FleetSid, var: fleet_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: DeploymentSid, var: deployment_sid}, {name: Enabled, var: enabled}, {name: FriendlyName, var: friendly_name}, {name: Identity, var: identity}, {name: UniqueName, var: unique_name}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    fleet_sid: $fleet_sid, deployment_sid: $deployment_sid, enabled: $enabled, friendly_name: $friendly_name, identity: $identity, unique_name: $unique_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a specific Device from the Fleet, also removing it from associated Deployments.
#
# DELETE /DeployedDevices/Fleets/{FleetSid}/Devices/{Sid}
# operationId: DeleteDeployedDevicesDevice
export def "delete-deployed-devices-device" [
  fleet_sid: string
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
    path: "/DeployedDevices/Fleets/{FleetSid}/Devices/{Sid}"
    path_params: [{name: FleetSid, var: fleet_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    fleet_sid: $fleet_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch information about a specific Device in the Fleet.
#
# GET /DeployedDevices/Fleets/{FleetSid}/Devices/{Sid}
# Returns: record<account_sid: string, date_authenticated: string, date_created: string, date_updated: string, deployment_sid: string, enabled: bool, fleet_sid: string, friendly_name: string, identity: string, sid: string, unique_name: string, url: string>
# operationId: FetchDeployedDevicesDevice
export def "fetch-deployed-devices-device" [
  fleet_sid: string
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
    path: "/DeployedDevices/Fleets/{FleetSid}/Devices/{Sid}"
    path_params: [{name: FleetSid, var: fleet_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    fleet_sid: $fleet_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the given properties of a specific Device in the Fleet, giving it a friendly name, assigning to a Deployment, or a human identity.
#
# POST /DeployedDevices/Fleets/{FleetSid}/Devices/{Sid}
# Returns: record<account_sid: string, date_authenticated: string, date_created: string, date_updated: string, deployment_sid: string, enabled: bool, fleet_sid: string, friendly_name: string, identity: string, sid: string, unique_name: string, url: string>
# operationId: UpdateDeployedDevicesDevice
export def "update-deployed-devices-device" [
  fleet_sid: string
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
  --deployment-sid: string # Specifies the unique string identifier of the Deployment group that this Device is going to be associated with.
  --enabled: oneof<nothing, bool>
  --friendly-name: string # Provides a human readable descriptive text to be assigned to this Device, up to 256 characters long.
  --identity: string # Provides an arbitrary string identifier representing a human user to be associated with this Device, up to 256 characters long.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/DeployedDevices/Fleets/{FleetSid}/Devices/{Sid}"
    path_params: [{name: FleetSid, var: fleet_sid}, {name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: DeploymentSid, var: deployment_sid}, {name: Enabled, var: enabled}, {name: FriendlyName, var: friendly_name}, {name: Identity, var: identity}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    fleet_sid: $fleet_sid, sid: $sid, deployment_sid: $deployment_sid, enabled: $enabled, friendly_name: $friendly_name, identity: $identity
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of all Keys credentials belonging to the Fleet.
#
# GET /DeployedDevices/Fleets/{FleetSid}/Keys
# Returns: record<keys: table<account_sid: string, date_created: string, date_updated: string, device_sid: string, fleet_sid: string, friendly_name: string, secret: string, sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListDeployedDevicesKey
export def "list-deployed-devices-key" [
  fleet_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --device-sid: string # Filters the resulting list of Keys by a unique string identifier of an authenticated Device.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/DeployedDevices/Fleets/{FleetSid}/Keys"
    path_params: [{name: FleetSid, var: fleet_sid}]
    query: [{name: DeviceSid, var: device_sid}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    fleet_sid: $fleet_sid, device_sid: $device_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new Key credential in the Fleet, optionally giving it a friendly name and assigning to a Device.
#
# POST /DeployedDevices/Fleets/{FleetSid}/Keys
# Returns: record<account_sid: string, date_created: string, date_updated: string, device_sid: string, fleet_sid: string, friendly_name: string, secret: string, sid: string, url: string>
# operationId: CreateDeployedDevicesKey
export def "create-deployed-devices-key" [
  fleet_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --device-sid: string # Provides the unique string identifier of an existing Device to become authenticated with this Key credential.
  --friendly-name: string # Provides a human readable descriptive text for this Key credential, up to 256 characters long.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/DeployedDevices/Fleets/{FleetSid}/Keys"
    path_params: [{name: FleetSid, var: fleet_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: DeviceSid, var: device_sid}, {name: FriendlyName, var: friendly_name}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    fleet_sid: $fleet_sid, device_sid: $device_sid, friendly_name: $friendly_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a specific Key credential from the Fleet, effectively disallowing any inbound client connections that are presenting it.
#
# DELETE /DeployedDevices/Fleets/{FleetSid}/Keys/{Sid}
# operationId: DeleteDeployedDevicesKey
export def "delete-deployed-devices-key" [
  fleet_sid: string
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
    path: "/DeployedDevices/Fleets/{FleetSid}/Keys/{Sid}"
    path_params: [{name: FleetSid, var: fleet_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    fleet_sid: $fleet_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch information about a specific Key credential in the Fleet.
#
# GET /DeployedDevices/Fleets/{FleetSid}/Keys/{Sid}
# Returns: record<account_sid: string, date_created: string, date_updated: string, device_sid: string, fleet_sid: string, friendly_name: string, secret: string, sid: string, url: string>
# operationId: FetchDeployedDevicesKey
export def "fetch-deployed-devices-key" [
  fleet_sid: string
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
    path: "/DeployedDevices/Fleets/{FleetSid}/Keys/{Sid}"
    path_params: [{name: FleetSid, var: fleet_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    fleet_sid: $fleet_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the given properties of a specific Key credential in the Fleet, giving it a friendly name or assigning to a Device.
#
# POST /DeployedDevices/Fleets/{FleetSid}/Keys/{Sid}
# Returns: record<account_sid: string, date_created: string, date_updated: string, device_sid: string, fleet_sid: string, friendly_name: string, secret: string, sid: string, url: string>
# operationId: UpdateDeployedDevicesKey
export def "update-deployed-devices-key" [
  fleet_sid: string
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
  --device-sid: string # Provides the unique string identifier of an existing Device to become authenticated with this Key credential.
  --friendly-name: string # Provides a human readable descriptive text for this Key credential, up to 256 characters long.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/DeployedDevices/Fleets/{FleetSid}/Keys/{Sid}"
    path_params: [{name: FleetSid, var: fleet_sid}, {name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: DeviceSid, var: device_sid}, {name: FriendlyName, var: friendly_name}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    fleet_sid: $fleet_sid, sid: $sid, device_sid: $device_sid, friendly_name: $friendly_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a specific Fleet from your account, also destroys all nested resources: Devices, Deployments, Certificates, Keys.
#
# DELETE /DeployedDevices/Fleets/{Sid}
# operationId: DeleteDeployedDevicesFleet
export def "delete-deployed-devices-fleet" [
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
    path: "/DeployedDevices/Fleets/{Sid}"
    path_params: [{name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch information about a specific Fleet in your account.
#
# GET /DeployedDevices/Fleets/{Sid}
# Returns: record<account_sid: string, date_created: string, date_updated: string, default_deployment_sid: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string>
# operationId: FetchDeployedDevicesFleet
export def "fetch-deployed-devices-fleet" [
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
    path: "/DeployedDevices/Fleets/{Sid}"
    path_params: [{name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the friendly name property of a specific Fleet in your account.
#
# POST /DeployedDevices/Fleets/{Sid}
# Returns: record<account_sid: string, date_created: string, date_updated: string, default_deployment_sid: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string>
# operationId: UpdateDeployedDevicesFleet
export def "update-deployed-devices-fleet" [
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
  --default-deployment-sid: string # Provides a string identifier of a Deployment that is going to be used as a default one for this Fleet.
  --friendly-name: string # Provides a human readable descriptive text for this Fleet, up to 256 characters long.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/DeployedDevices/Fleets/{Sid}"
    path_params: [{name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: DefaultDeploymentSid, var: default_deployment_sid}, {name: FriendlyName, var: friendly_name}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    sid: $sid, default_deployment_sid: $default_deployment_sid, friendly_name: $friendly_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of AuthorizationDocuments belonging to the account initiating the request.
#
# GET /HostedNumbers/AuthorizationDocuments
# Returns: record<items: table<address_sid: string, cc_emails: list, date_created: string, date_updated: string, email: string, links: record, sid: string, status: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListHostedNumbersAuthorizationDocument
export def "list-hosted-numbers-authorization-document" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # Email that this AuthorizationDocument will be sent to for signing.
  --status: string@status-completer # Status of an instance resource. It can hold one of the values: 1. opened 2. signing, 3. signed LOA, 4. canceled, 5. failed. See the section entitled [Status Values](https://www.twilio.com/docs/api/phone-numbers/hosted-number-authorization-documents#status-values) for more information on each of these statuses.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/HostedNumbers/AuthorizationDocuments"
    query: [{name: Email, var: email}, {name: Status, var: status}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    email: $email, status: $status, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an AuthorizationDocument for authorizing the hosting of phone number capabilities on Twilio's platform.
#
# POST /HostedNumbers/AuthorizationDocuments
# Returns: record<address_sid: string, cc_emails: list<string>, date_created: string, date_updated: string, email: string, links: record, sid: string, status: string, url: string>
# operationId: CreateHostedNumbersAuthorizationDocument
export def "create-hosted-numbers-authorization-document" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  address_sid: string # A 34 character string that uniquely identifies the Address resource that is associated with this AuthorizationDocument.
  --cc-emails: list<string> # Email recipients who will be informed when an Authorization Document has been sent and signed.
  contact_phone_number: string # The contact phone number of the person authorized to sign the Authorization Document.
  contact_title: string # The title of the person authorized to sign the Authorization Document for this phone number.
  email: string # Email that this AuthorizationDocument will be sent to for signing.
  hosted_number_order_sids: list<string> # A list of HostedNumberOrder sids that this AuthorizationDocument will authorize for hosting phone number capabilities on Twilio's platform.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/HostedNumbers/AuthorizationDocuments"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: AddressSid, var: address_sid}, {name: CcEmails, var: cc_emails}, {name: ContactPhoneNumber, var: contact_phone_number}, {name: ContactTitle, var: contact_title}, {name: Email, var: email}, {name: HostedNumberOrderSids, var: hosted_number_order_sids}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    address_sid: $address_sid, cc_emails: $cc_emails, contact_phone_number: $contact_phone_number, contact_title: $contact_title, email: $email, hosted_number_order_sids: $hosted_number_order_sids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a specific AuthorizationDocument.
#
# GET /HostedNumbers/AuthorizationDocuments/{Sid}
# Returns: record<address_sid: string, cc_emails: list<string>, date_created: string, date_updated: string, email: string, links: record, sid: string, status: string, url: string>
# operationId: FetchHostedNumbersAuthorizationDocument
export def "fetch-hosted-numbers-authorization-document" [
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
    path: "/HostedNumbers/AuthorizationDocuments/{Sid}"
    path_params: [{name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a specific AuthorizationDocument.
#
# POST /HostedNumbers/AuthorizationDocuments/{Sid}
# Returns: record<address_sid: string, cc_emails: list<string>, date_created: string, date_updated: string, email: string, links: record, sid: string, status: string, url: string>
# operationId: UpdateHostedNumbersAuthorizationDocument
export def "update-hosted-numbers-authorization-document" [
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
  --address-sid: string # A 34 character string that uniquely identifies the Address resource that is associated with this AuthorizationDocument.
  --cc-emails: list<string> # Email recipients who will be informed when an Authorization Document has been sent and signed
  --contact-phone-number: string # The contact phone number of the person authorized to sign the Authorization Document.
  --contact-title: string # The title of the person authorized to sign the Authorization Document for this phone number.
  --email: string # Email that this AuthorizationDocument will be sent to for signing.
  --hosted-number-order-sids: list<string> # A list of HostedNumberOrder sids that this AuthorizationDocument will authorize for hosting phone number capabilities on Twilio's platform.
  --status: string@status-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/HostedNumbers/AuthorizationDocuments/{Sid}"
    path_params: [{name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: AddressSid, var: address_sid}, {name: CcEmails, var: cc_emails}, {name: ContactPhoneNumber, var: contact_phone_number}, {name: ContactTitle, var: contact_title}, {name: Email, var: email}, {name: HostedNumberOrderSids, var: hosted_number_order_sids}, {name: Status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    sid: $sid, address_sid: $address_sid, cc_emails: $cc_emails, contact_phone_number: $contact_phone_number, contact_title: $contact_title, email: $email, hosted_number_order_sids: $hosted_number_order_sids, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of dependent HostedNumberOrders belonging to the AuthorizationDocument.
#
# GET /HostedNumbers/AuthorizationDocuments/{SigningDocumentSid}/DependentHostedNumberOrders
# Returns: record<items: table<account_sid: string, address_sid: string, call_delay: int, capabilities: record, cc_emails: list, date_created: string, date_updated: string, email: string, extension: string, failure_reason: string, friendly_name: string, incoming_phone_number_sid: string, phone_number: string, sid: string, signing_document_sid: string, status: string, unique_name: string, verification_attempts: int, verification_call_sids: list, verification_code: string, verification_document_sid: string, verification_type: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListHostedNumbersDependentHostedNumberOrder
export def "list-hosted-numbers-dependent-hosted-number-order" [
  signing_document_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer-1 # Status of an instance resource. It can hold one of the values: 1. opened 2. signing, 3. signed LOA, 4. canceled, 5. failed. See the section entitled [Status Values](https://www.twilio.com/docs/api/phone-numbers/hosted-number-authorization-documents#status-values) for more information on each of these statuses.
  --phone-number: string # An E164 formatted phone number hosted by this HostedNumberOrder. (format: phone-number)
  --incoming-phone-number-sid: string # A 34 character string that uniquely identifies the IncomingPhoneNumber resource created by this HostedNumberOrder.
  --friendly-name: string # A human readable description of this resource, up to 64 characters.
  --unique-name: string # Provides a unique and addressable name to be assigned to this HostedNumberOrder, assigned by the developer, to be optionally used in addition to SID.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/HostedNumbers/AuthorizationDocuments/{SigningDocumentSid}/DependentHostedNumberOrders"
    path_params: [{name: SigningDocumentSid, var: signing_document_sid}]
    query: [{name: Status, var: status}, {name: PhoneNumber, var: phone_number}, {name: IncomingPhoneNumberSid, var: incoming_phone_number_sid}, {name: FriendlyName, var: friendly_name}, {name: UniqueName, var: unique_name}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    signing_document_sid: $signing_document_sid, status: $status, phone_number: $phone_number, incoming_phone_number_sid: $incoming_phone_number_sid, friendly_name: $friendly_name, unique_name: $unique_name, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of HostedNumberOrders belonging to the account initiating the request.
#
# GET /HostedNumbers/HostedNumberOrders
# Returns: record<items: table<account_sid: string, address_sid: string, call_delay: int, capabilities: record, cc_emails: list, date_created: string, date_updated: string, email: string, extension: string, failure_reason: string, friendly_name: string, incoming_phone_number_sid: string, phone_number: string, sid: string, signing_document_sid: string, status: string, unique_name: string, url: string, verification_attempts: int, verification_call_sids: list, verification_code: string, verification_document_sid: string, verification_type: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListHostedNumbersHostedNumberOrder
export def "list-hosted-numbers-hosted-number-order" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer-1 # The Status of this HostedNumberOrder. One of `received`, `pending-verification`, `verified`, `pending-loa`, `carrier-processing`, `testing`, `completed`, `failed`, or `action-required`.
  --phone-number: string # An E164 formatted phone number hosted by this HostedNumberOrder. (format: phone-number)
  --incoming-phone-number-sid: string # A 34 character string that uniquely identifies the IncomingPhoneNumber resource created by this HostedNumberOrder.
  --friendly-name: string # A human readable description of this resource, up to 64 characters.
  --unique-name: string # Provides a unique and addressable name to be assigned to this HostedNumberOrder, assigned by the developer, to be optionally used in addition to SID.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/HostedNumbers/HostedNumberOrders"
    query: [{name: Status, var: status}, {name: PhoneNumber, var: phone_number}, {name: IncomingPhoneNumberSid, var: incoming_phone_number_sid}, {name: FriendlyName, var: friendly_name}, {name: UniqueName, var: unique_name}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    status: $status, phone_number: $phone_number, incoming_phone_number_sid: $incoming_phone_number_sid, friendly_name: $friendly_name, unique_name: $unique_name, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Host a phone number's capability on Twilio's platform.
#
# POST /HostedNumbers/HostedNumberOrders
# Returns: record<account_sid: string, address_sid: string, call_delay: int, capabilities: record<fax: bool, mms: bool, sms: bool, voice: bool>, cc_emails: list<string>, date_created: string, date_updated: string, email: string, extension: string, failure_reason: string, friendly_name: string, incoming_phone_number_sid: string, phone_number: string, sid: string, signing_document_sid: string, status: string, unique_name: string, url: string, verification_attempts: int, verification_call_sids: list<string>, verification_code: string, verification_document_sid: string, verification_type: string>
# operationId: CreateHostedNumbersHostedNumberOrder
export def "create-hosted-numbers-hosted-number-order" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-sid: string # This defaults to the AccountSid of the authorization the user is using. This can be provided to specify a subaccount to add the HostedNumberOrder to.
  --address-sid: string # Optional. A 34 character string that uniquely identifies the Address resource that represents the address of the owner of this phone number.
  --cc-emails: list<string> # Optional. A list of emails that the LOA document for this HostedNumberOrder will be carbon copied to.
  --email: string # Optional. Email of the owner of this phone number that is being hosted.
  --friendly-name: string # A 64 character string that is a human readable text that describes this resource.
  phone_number: string # The number to host in [+E.164](https://en.wikipedia.org/wiki/E.164) format (format: phone-number)
  --sms-application-sid: string # Optional. The 34 character sid of the application Twilio should use to handle SMS messages sent to this number. If a `SmsApplicationSid` is present, Twilio will ignore all of the SMS urls above and use those set on the application.
  --sms-capability: oneof<nothing, bool> # Used to specify that the SMS capability will be hosted on Twilio's platform.
  --sms-fallback-method: string@sms-fallback-method-completer # The HTTP method that should be used to request the SmsFallbackUrl. Must be either `GET` or `POST`. This will be copied onto the IncomingPhoneNumber resource. (format: http-method)
  --sms-fallback-url: string # A URL that Twilio will request if an error occurs requesting or executing the TwiML defined by SmsUrl. This will be copied onto the IncomingPhoneNumber resource. (format: uri)
  --sms-method: string@sms-method-completer # The HTTP method that should be used to request the SmsUrl. Must be either `GET` or `POST`. This will be copied onto the IncomingPhoneNumber resource. (format: http-method)
  --sms-url: string # The URL that Twilio should request when somebody sends an SMS to the phone number. This will be copied onto the IncomingPhoneNumber resource. (format: uri)
  --status-callback-method: string@status-callback-method-completer # Optional. The Status Callback Method attached to the IncomingPhoneNumber resource. (format: http-method)
  --status-callback-url: string # Optional. The Status Callback URL attached to the IncomingPhoneNumber resource. (format: uri)
  --unique-name: string # Optional. Provides a unique and addressable name to be assigned to this HostedNumberOrder, assigned by the developer, to be optionally used in addition to SID.
  --verification-document-sid: string # Optional. The unique sid identifier of the Identity Document that represents the document for verifying ownership of the number to be hosted. Required when VerificationType is phone-bill.
  --verification-type: string@verification-type-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/HostedNumbers/HostedNumberOrders"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: AccountSid, var: account_sid}, {name: AddressSid, var: address_sid}, {name: CcEmails, var: cc_emails}, {name: Email, var: email}, {name: FriendlyName, var: friendly_name}, {name: PhoneNumber, var: phone_number}, {name: SmsApplicationSid, var: sms_application_sid}, {name: SmsCapability, var: sms_capability, required: true}, {name: SmsFallbackMethod, var: sms_fallback_method}, {name: SmsFallbackUrl, var: sms_fallback_url}, {name: SmsMethod, var: sms_method}, {name: SmsUrl, var: sms_url}, {name: StatusCallbackMethod, var: status_callback_method}, {name: StatusCallbackUrl, var: status_callback_url}, {name: UniqueName, var: unique_name}, {name: VerificationDocumentSid, var: verification_document_sid}, {name: VerificationType, var: verification_type}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, address_sid: $address_sid, cc_emails: $cc_emails, email: $email, friendly_name: $friendly_name, phone_number: $phone_number, sms_application_sid: $sms_application_sid, sms_capability: $sms_capability, sms_fallback_method: $sms_fallback_method, sms_fallback_url: $sms_fallback_url, sms_method: $sms_method, sms_url: $sms_url, status_callback_method: $status_callback_method, status_callback_url: $status_callback_url, unique_name: $unique_name, verification_document_sid: $verification_document_sid, verification_type: $verification_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancel the HostedNumberOrder (only available when the status is in `received`).
#
# DELETE /HostedNumbers/HostedNumberOrders/{Sid}
# operationId: DeleteHostedNumbersHostedNumberOrder
export def "delete-hosted-numbers-hosted-number-order" [
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
    path: "/HostedNumbers/HostedNumberOrders/{Sid}"
    path_params: [{name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a specific HostedNumberOrder.
#
# GET /HostedNumbers/HostedNumberOrders/{Sid}
# Returns: record<account_sid: string, address_sid: string, call_delay: int, capabilities: record<fax: bool, mms: bool, sms: bool, voice: bool>, cc_emails: list<string>, date_created: string, date_updated: string, email: string, extension: string, failure_reason: string, friendly_name: string, incoming_phone_number_sid: string, phone_number: string, sid: string, signing_document_sid: string, status: string, unique_name: string, url: string, verification_attempts: int, verification_call_sids: list<string>, verification_code: string, verification_document_sid: string, verification_type: string>
# operationId: FetchHostedNumbersHostedNumberOrder
export def "fetch-hosted-numbers-hosted-number-order" [
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
    path: "/HostedNumbers/HostedNumberOrders/{Sid}"
    path_params: [{name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a specific HostedNumberOrder.
#
# POST /HostedNumbers/HostedNumberOrders/{Sid}
# Returns: record<account_sid: string, address_sid: string, call_delay: int, capabilities: record<fax: bool, mms: bool, sms: bool, voice: bool>, cc_emails: list<string>, date_created: string, date_updated: string, email: string, extension: string, failure_reason: string, friendly_name: string, incoming_phone_number_sid: string, phone_number: string, sid: string, signing_document_sid: string, status: string, unique_name: string, url: string, verification_attempts: int, verification_call_sids: list<string>, verification_code: string, verification_document_sid: string, verification_type: string>
# operationId: UpdateHostedNumbersHostedNumberOrder
export def "update-hosted-numbers-hosted-number-order" [
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
  --call-delay: int # The number of seconds, between 0 and 60, to delay before initiating the verification call. Defaults to 0.
  --cc-emails: list<string> # Optional. A list of emails that LOA document for this HostedNumberOrder will be carbon copied to.
  --email: string # Email of the owner of this phone number that is being hosted.
  --extension: string # Digits to dial after connecting the verification call.
  --friendly-name: string # A 64 character string that is a human readable text that describes this resource.
  --status: string@status-completer-1
  --unique-name: string # Provides a unique and addressable name to be assigned to this HostedNumberOrder, assigned by the developer, to be optionally used in addition to SID.
  --verification-code: string # A verification code that is given to the user via a phone call to the phone number that is being hosted.
  --verification-document-sid: string # Optional. The unique sid identifier of the Identity Document that represents the document for verifying ownership of the number to be hosted. Required when VerificationType is phone-bill.
  --verification-type: string@verification-type-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/HostedNumbers/HostedNumberOrders/{Sid}"
    path_params: [{name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: CallDelay, var: call_delay}, {name: CcEmails, var: cc_emails}, {name: Email, var: email}, {name: Extension, var: extension}, {name: FriendlyName, var: friendly_name}, {name: Status, var: status}, {name: UniqueName, var: unique_name}, {name: VerificationCode, var: verification_code}, {name: VerificationDocumentSid, var: verification_document_sid}, {name: VerificationType, var: verification_type}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    sid: $sid, call_delay: $call_delay, cc_emails: $cc_emails, email: $email, extension: $extension, friendly_name: $friendly_name, status: $status, unique_name: $unique_name, verification_code: $verification_code, verification_document_sid: $verification_document_sid, verification_type: $verification_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /Sync/Services
#
# Returns: record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, services: table<account_sid: string, acl_enabled: bool, date_created: string, date_updated: string, friendly_name: string, links: record, reachability_webhooks_enabled: bool, sid: string, url: string, webhook_url: string>>
# operationId: ListSyncService
export def "list-sync-service" [
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
    path: "/Sync/Services"
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /Sync/Services
#
# Returns: record<account_sid: string, acl_enabled: bool, date_created: string, date_updated: string, friendly_name: string, links: record, reachability_webhooks_enabled: bool, sid: string, url: string, webhook_url: string>
# operationId: CreateSyncService
export def "create-sync-service" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --acl-enabled: oneof<nothing, bool>
  --friendly-name: string
  --reachability-webhooks-enabled: oneof<nothing, bool>
  --webhook-url: string # format: uri
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Sync/Services"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: AclEnabled, var: acl_enabled}, {name: FriendlyName, var: friendly_name}, {name: ReachabilityWebhooksEnabled, var: reachability_webhooks_enabled}, {name: WebhookUrl, var: webhook_url}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    acl_enabled: $acl_enabled, friendly_name: $friendly_name, reachability_webhooks_enabled: $reachability_webhooks_enabled, webhook_url: $webhook_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /Sync/Services/{ServiceSid}/Documents
#
# Returns: record<documents: table<account_sid: string, created_by: string, data: any, date_created: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListSyncDocument
export def "list-sync-document" [
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
    path: "/Sync/Services/{ServiceSid}/Documents"
    path_params: [{name: ServiceSid, var: service_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /Sync/Services/{ServiceSid}/Documents
#
# Returns: record<account_sid: string, created_by: string, data: any, date_created: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string>
# operationId: CreateSyncDocument
export def "create-sync-document" [
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
  --data: any
  --unique-name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Sync/Services/{ServiceSid}/Documents"
    path_params: [{name: ServiceSid, var: service_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Data, var: data}, {name: UniqueName, var: unique_name}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, data: $data, unique_name: $unique_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of all Permissions applying to a Sync Document.
#
# GET /Sync/Services/{ServiceSid}/Documents/{DocumentSid}/Permissions
# Returns: record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, permissions: table<account_sid: string, document_sid: string, identity: string, manage: bool, read: bool, service_sid: string, url: string, write: bool>>
# operationId: ListSyncDocumentPermission
export def "list-sync-document-permission" [
  service_sid: string
  document_sid: string
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
    path: "/Sync/Services/{ServiceSid}/Documents/{DocumentSid}/Permissions"
    path_params: [{name: ServiceSid, var: service_sid}, {name: DocumentSid, var: document_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, document_sid: $document_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a specific Sync Document Permission.
#
# DELETE /Sync/Services/{ServiceSid}/Documents/{DocumentSid}/Permissions/{Identity}
# operationId: DeleteSyncDocumentPermission
export def "delete-sync-document-permission" [
  service_sid: string
  document_sid: string
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
    path: "/Sync/Services/{ServiceSid}/Documents/{DocumentSid}/Permissions/{Identity}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: DocumentSid, var: document_sid}, {name: Identity, var: identity}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, document_sid: $document_sid, identity: $identity
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a specific Sync Document Permission.
#
# GET /Sync/Services/{ServiceSid}/Documents/{DocumentSid}/Permissions/{Identity}
# Returns: record<account_sid: string, document_sid: string, identity: string, manage: bool, read: bool, service_sid: string, url: string, write: bool>
# operationId: FetchSyncDocumentPermission
export def "fetch-sync-document-permission" [
  service_sid: string
  document_sid: string
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
    path: "/Sync/Services/{ServiceSid}/Documents/{DocumentSid}/Permissions/{Identity}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: DocumentSid, var: document_sid}, {name: Identity, var: identity}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, document_sid: $document_sid, identity: $identity
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an identity's access to a specific Sync Document.
#
# POST /Sync/Services/{ServiceSid}/Documents/{DocumentSid}/Permissions/{Identity}
# Returns: record<account_sid: string, document_sid: string, identity: string, manage: bool, read: bool, service_sid: string, url: string, write: bool>
# operationId: UpdateSyncDocumentPermission
export def "update-sync-document-permission" [
  service_sid: string
  document_sid: string
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
  --manage: oneof<nothing, bool> # Boolean flag specifying whether the identity can delete the Sync Document.
  --read: oneof<nothing, bool> # Boolean flag specifying whether the identity can read the Sync Document.
  --write: oneof<nothing, bool> # Boolean flag specifying whether the identity can update the Sync Document.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Sync/Services/{ServiceSid}/Documents/{DocumentSid}/Permissions/{Identity}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: DocumentSid, var: document_sid}, {name: Identity, var: identity}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Manage, var: manage, required: true}, {name: Read, var: read, required: true}, {name: Write, var: write, required: true}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, document_sid: $document_sid, identity: $identity, manage: $manage, read: $read, write: $write
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /Sync/Services/{ServiceSid}/Documents/{Sid}
#
# operationId: DeleteSyncDocument
export def "delete-sync-document" [
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
    path: "/Sync/Services/{ServiceSid}/Documents/{Sid}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /Sync/Services/{ServiceSid}/Documents/{Sid}
#
# Returns: record<account_sid: string, created_by: string, data: any, date_created: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string>
# operationId: FetchSyncDocument
export def "fetch-sync-document" [
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
    path: "/Sync/Services/{ServiceSid}/Documents/{Sid}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /Sync/Services/{ServiceSid}/Documents/{Sid}
#
# Returns: record<account_sid: string, created_by: string, data: any, date_created: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string>
# operationId: UpdateSyncDocument
export def "update-sync-document" [
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
  --if-match: string # The If-Match HTTP request header
  data: any
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Sync/Services/{ServiceSid}/Documents/{Sid}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: Sid, var: sid}]
    header: [{name: If-Match, var: if_match}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, sid: $sid, if_match: $if_match, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /Sync/Services/{ServiceSid}/Lists
#
# Returns: record<lists: table<account_sid: string, created_by: string, date_created: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListSyncSyncList
export def "list-sync-sync-list" [
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
    path: "/Sync/Services/{ServiceSid}/Lists"
    path_params: [{name: ServiceSid, var: service_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /Sync/Services/{ServiceSid}/Lists
#
# Returns: record<account_sid: string, created_by: string, date_created: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string>
# operationId: CreateSyncSyncList
export def "create-sync-sync-list" [
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
  --unique-name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Sync/Services/{ServiceSid}/Lists"
    path_params: [{name: ServiceSid, var: service_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: UniqueName, var: unique_name}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, unique_name: $unique_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /Sync/Services/{ServiceSid}/Lists/{ListSid}/Items
#
# Returns: record<items: table<account_sid: string, created_by: string, data: any, date_created: string, date_updated: string, index: int, list_sid: string, revision: string, service_sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListSyncSyncListItem
export def "list-sync-sync-list-item" [
  service_sid: string
  list_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --order: string@order-completer
  --from: string
  --bounds: string@bounds-completer
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Sync/Services/{ServiceSid}/Lists/{ListSid}/Items"
    path_params: [{name: ServiceSid, var: service_sid}, {name: ListSid, var: list_sid}]
    query: [{name: Order, var: order}, {name: From, var: from}, {name: Bounds, var: bounds}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, list_sid: $list_sid, order: $order, from: $from, bounds: $bounds, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /Sync/Services/{ServiceSid}/Lists/{ListSid}/Items
#
# Returns: record<account_sid: string, created_by: string, data: any, date_created: string, date_updated: string, index: int, list_sid: string, revision: string, service_sid: string, url: string>
# operationId: CreateSyncSyncListItem
export def "create-sync-sync-list-item" [
  service_sid: string
  list_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  data: any
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Sync/Services/{ServiceSid}/Lists/{ListSid}/Items"
    path_params: [{name: ServiceSid, var: service_sid}, {name: ListSid, var: list_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Data, var: data}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, list_sid: $list_sid, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /Sync/Services/{ServiceSid}/Lists/{ListSid}/Items/{Index}
#
# operationId: DeleteSyncSyncListItem
export def "delete-sync-sync-list-item" [
  service_sid: string
  list_sid: string
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
  --if-match: string # The If-Match HTTP request header
]: nothing -> any {
  http-request {
    method: delete
    path: "/Sync/Services/{ServiceSid}/Lists/{ListSid}/Items/{Index}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: ListSid, var: list_sid}, {name: Index, var: index}]
    header: [{name: If-Match, var: if_match}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, list_sid: $list_sid, index: $index, if_match: $if_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /Sync/Services/{ServiceSid}/Lists/{ListSid}/Items/{Index}
#
# Returns: record<account_sid: string, created_by: string, data: any, date_created: string, date_updated: string, index: int, list_sid: string, revision: string, service_sid: string, url: string>
# operationId: FetchSyncSyncListItem
export def "fetch-sync-sync-list-item" [
  service_sid: string
  list_sid: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Sync/Services/{ServiceSid}/Lists/{ListSid}/Items/{Index}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: ListSid, var: list_sid}, {name: Index, var: index}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, list_sid: $list_sid, index: $index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /Sync/Services/{ServiceSid}/Lists/{ListSid}/Items/{Index}
#
# Returns: record<account_sid: string, created_by: string, data: any, date_created: string, date_updated: string, index: int, list_sid: string, revision: string, service_sid: string, url: string>
# operationId: UpdateSyncSyncListItem
export def "update-sync-sync-list-item" [
  service_sid: string
  list_sid: string
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
  --if-match: string # The If-Match HTTP request header
  data: any
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Sync/Services/{ServiceSid}/Lists/{ListSid}/Items/{Index}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: ListSid, var: list_sid}, {name: Index, var: index}]
    header: [{name: If-Match, var: if_match}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, list_sid: $list_sid, index: $index, if_match: $if_match, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of all Permissions applying to a Sync List.
#
# GET /Sync/Services/{ServiceSid}/Lists/{ListSid}/Permissions
# Returns: record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, permissions: table<account_sid: string, identity: string, list_sid: string, manage: bool, read: bool, service_sid: string, url: string, write: bool>>
# operationId: ListSyncSyncListPermission
export def "list-sync-sync-list-permission" [
  service_sid: string
  list_sid: string
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
    path: "/Sync/Services/{ServiceSid}/Lists/{ListSid}/Permissions"
    path_params: [{name: ServiceSid, var: service_sid}, {name: ListSid, var: list_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, list_sid: $list_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a specific Sync List Permission.
#
# DELETE /Sync/Services/{ServiceSid}/Lists/{ListSid}/Permissions/{Identity}
# operationId: DeleteSyncSyncListPermission
export def "delete-sync-sync-list-permission" [
  service_sid: string
  list_sid: string
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
    path: "/Sync/Services/{ServiceSid}/Lists/{ListSid}/Permissions/{Identity}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: ListSid, var: list_sid}, {name: Identity, var: identity}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, list_sid: $list_sid, identity: $identity
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a specific Sync List Permission.
#
# GET /Sync/Services/{ServiceSid}/Lists/{ListSid}/Permissions/{Identity}
# Returns: record<account_sid: string, identity: string, list_sid: string, manage: bool, read: bool, service_sid: string, url: string, write: bool>
# operationId: FetchSyncSyncListPermission
export def "fetch-sync-sync-list-permission" [
  service_sid: string
  list_sid: string
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
    path: "/Sync/Services/{ServiceSid}/Lists/{ListSid}/Permissions/{Identity}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: ListSid, var: list_sid}, {name: Identity, var: identity}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, list_sid: $list_sid, identity: $identity
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an identity's access to a specific Sync List.
#
# POST /Sync/Services/{ServiceSid}/Lists/{ListSid}/Permissions/{Identity}
# Returns: record<account_sid: string, identity: string, list_sid: string, manage: bool, read: bool, service_sid: string, url: string, write: bool>
# operationId: UpdateSyncSyncListPermission
export def "update-sync-sync-list-permission" [
  service_sid: string
  list_sid: string
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
  --manage: oneof<nothing, bool> # Boolean flag specifying whether the identity can delete the Sync List.
  --read: oneof<nothing, bool> # Boolean flag specifying whether the identity can read the Sync List.
  --write: oneof<nothing, bool> # Boolean flag specifying whether the identity can create, update and delete Items of the Sync List.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Sync/Services/{ServiceSid}/Lists/{ListSid}/Permissions/{Identity}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: ListSid, var: list_sid}, {name: Identity, var: identity}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Manage, var: manage, required: true}, {name: Read, var: read, required: true}, {name: Write, var: write, required: true}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, list_sid: $list_sid, identity: $identity, manage: $manage, read: $read, write: $write
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /Sync/Services/{ServiceSid}/Lists/{Sid}
#
# operationId: DeleteSyncSyncList
export def "delete-sync-sync-list" [
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
    path: "/Sync/Services/{ServiceSid}/Lists/{Sid}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /Sync/Services/{ServiceSid}/Lists/{Sid}
#
# Returns: record<account_sid: string, created_by: string, date_created: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string>
# operationId: FetchSyncSyncList
export def "fetch-sync-sync-list" [
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
    path: "/Sync/Services/{ServiceSid}/Lists/{Sid}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /Sync/Services/{ServiceSid}/Maps
#
# Returns: record<maps: table<account_sid: string, created_by: string, date_created: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListSyncSyncMap
export def "list-sync-sync-map" [
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
    path: "/Sync/Services/{ServiceSid}/Maps"
    path_params: [{name: ServiceSid, var: service_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /Sync/Services/{ServiceSid}/Maps
#
# Returns: record<account_sid: string, created_by: string, date_created: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string>
# operationId: CreateSyncSyncMap
export def "create-sync-sync-map" [
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
  --unique-name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Sync/Services/{ServiceSid}/Maps"
    path_params: [{name: ServiceSid, var: service_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: UniqueName, var: unique_name}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, unique_name: $unique_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /Sync/Services/{ServiceSid}/Maps/{MapSid}/Items
#
# Returns: record<items: table<account_sid: string, created_by: string, data: any, date_created: string, date_updated: string, key: string, map_sid: string, revision: string, service_sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListSyncSyncMapItem
export def "list-sync-sync-map-item" [
  service_sid: string
  map_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --order: string@order-completer
  --from: string
  --bounds: string@bounds-completer
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Sync/Services/{ServiceSid}/Maps/{MapSid}/Items"
    path_params: [{name: ServiceSid, var: service_sid}, {name: MapSid, var: map_sid}]
    query: [{name: Order, var: order}, {name: From, var: from}, {name: Bounds, var: bounds}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, map_sid: $map_sid, order: $order, from: $from, bounds: $bounds, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /Sync/Services/{ServiceSid}/Maps/{MapSid}/Items
#
# Returns: record<account_sid: string, created_by: string, data: any, date_created: string, date_updated: string, key: string, map_sid: string, revision: string, service_sid: string, url: string>
# operationId: CreateSyncSyncMapItem
export def "create-sync-sync-map-item" [
  service_sid: string
  map_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  data: any
  key: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Sync/Services/{ServiceSid}/Maps/{MapSid}/Items"
    path_params: [{name: ServiceSid, var: service_sid}, {name: MapSid, var: map_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Data, var: data}, {name: Key, var: key}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, map_sid: $map_sid, data: $data, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /Sync/Services/{ServiceSid}/Maps/{MapSid}/Items/{Key}
#
# operationId: DeleteSyncSyncMapItem
export def "delete-sync-sync-map-item" [
  service_sid: string
  map_sid: string
  key: string
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
    path: "/Sync/Services/{ServiceSid}/Maps/{MapSid}/Items/{Key}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: MapSid, var: map_sid}, {name: Key, var: key}]
    header: [{name: If-Match, var: if_match}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, map_sid: $map_sid, key: $key, if_match: $if_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /Sync/Services/{ServiceSid}/Maps/{MapSid}/Items/{Key}
#
# Returns: record<account_sid: string, created_by: string, data: any, date_created: string, date_updated: string, key: string, map_sid: string, revision: string, service_sid: string, url: string>
# operationId: FetchSyncSyncMapItem
export def "fetch-sync-sync-map-item" [
  service_sid: string
  map_sid: string
  key: string
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
    path: "/Sync/Services/{ServiceSid}/Maps/{MapSid}/Items/{Key}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: MapSid, var: map_sid}, {name: Key, var: key}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, map_sid: $map_sid, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /Sync/Services/{ServiceSid}/Maps/{MapSid}/Items/{Key}
#
# Returns: record<account_sid: string, created_by: string, data: any, date_created: string, date_updated: string, key: string, map_sid: string, revision: string, service_sid: string, url: string>
# operationId: UpdateSyncSyncMapItem
export def "update-sync-sync-map-item" [
  service_sid: string
  map_sid: string
  key: string
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
  data: any
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Sync/Services/{ServiceSid}/Maps/{MapSid}/Items/{Key}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: MapSid, var: map_sid}, {name: Key, var: key}]
    header: [{name: If-Match, var: if_match}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, map_sid: $map_sid, key: $key, if_match: $if_match, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of all Permissions applying to a Sync Map.
#
# GET /Sync/Services/{ServiceSid}/Maps/{MapSid}/Permissions
# Returns: record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, permissions: table<account_sid: string, identity: string, manage: bool, map_sid: string, read: bool, service_sid: string, url: string, write: bool>>
# operationId: ListSyncSyncMapPermission
export def "list-sync-sync-map-permission" [
  service_sid: string
  map_sid: string
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
    path: "/Sync/Services/{ServiceSid}/Maps/{MapSid}/Permissions"
    path_params: [{name: ServiceSid, var: service_sid}, {name: MapSid, var: map_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, map_sid: $map_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a specific Sync Map Permission.
#
# DELETE /Sync/Services/{ServiceSid}/Maps/{MapSid}/Permissions/{Identity}
# operationId: DeleteSyncSyncMapPermission
export def "delete-sync-sync-map-permission" [
  service_sid: string
  map_sid: string
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
    path: "/Sync/Services/{ServiceSid}/Maps/{MapSid}/Permissions/{Identity}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: MapSid, var: map_sid}, {name: Identity, var: identity}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, map_sid: $map_sid, identity: $identity
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a specific Sync Map Permission.
#
# GET /Sync/Services/{ServiceSid}/Maps/{MapSid}/Permissions/{Identity}
# Returns: record<account_sid: string, identity: string, manage: bool, map_sid: string, read: bool, service_sid: string, url: string, write: bool>
# operationId: FetchSyncSyncMapPermission
export def "fetch-sync-sync-map-permission" [
  service_sid: string
  map_sid: string
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
    path: "/Sync/Services/{ServiceSid}/Maps/{MapSid}/Permissions/{Identity}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: MapSid, var: map_sid}, {name: Identity, var: identity}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, map_sid: $map_sid, identity: $identity
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an identity's access to a specific Sync Map.
#
# POST /Sync/Services/{ServiceSid}/Maps/{MapSid}/Permissions/{Identity}
# Returns: record<account_sid: string, identity: string, manage: bool, map_sid: string, read: bool, service_sid: string, url: string, write: bool>
# operationId: UpdateSyncSyncMapPermission
export def "update-sync-sync-map-permission" [
  service_sid: string
  map_sid: string
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
  --manage: oneof<nothing, bool> # Boolean flag specifying whether the identity can delete the Sync Map.
  --read: oneof<nothing, bool> # Boolean flag specifying whether the identity can read the Sync Map.
  --write: oneof<nothing, bool> # Boolean flag specifying whether the identity can create, update and delete Items of the Sync Map.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Sync/Services/{ServiceSid}/Maps/{MapSid}/Permissions/{Identity}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: MapSid, var: map_sid}, {name: Identity, var: identity}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Manage, var: manage, required: true}, {name: Read, var: read, required: true}, {name: Write, var: write, required: true}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, map_sid: $map_sid, identity: $identity, manage: $manage, read: $read, write: $write
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /Sync/Services/{ServiceSid}/Maps/{Sid}
#
# operationId: DeleteSyncSyncMap
export def "delete-sync-sync-map" [
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
    path: "/Sync/Services/{ServiceSid}/Maps/{Sid}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /Sync/Services/{ServiceSid}/Maps/{Sid}
#
# Returns: record<account_sid: string, created_by: string, date_created: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string>
# operationId: FetchSyncSyncMap
export def "fetch-sync-sync-map" [
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
    path: "/Sync/Services/{ServiceSid}/Maps/{Sid}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /Sync/Services/{Sid}
#
# operationId: DeleteSyncService
export def "delete-sync-service" [
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
    path: "/Sync/Services/{Sid}"
    path_params: [{name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /Sync/Services/{Sid}
#
# Returns: record<account_sid: string, acl_enabled: bool, date_created: string, date_updated: string, friendly_name: string, links: record, reachability_webhooks_enabled: bool, sid: string, url: string, webhook_url: string>
# operationId: FetchSyncService
export def "fetch-sync-service" [
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
    path: "/Sync/Services/{Sid}"
    path_params: [{name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /Sync/Services/{Sid}
#
# Returns: record<account_sid: string, acl_enabled: bool, date_created: string, date_updated: string, friendly_name: string, links: record, reachability_webhooks_enabled: bool, sid: string, url: string, webhook_url: string>
# operationId: UpdateSyncService
export def "update-sync-service" [
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
  --acl-enabled: oneof<nothing, bool>
  --friendly-name: string
  --reachability-webhooks-enabled: oneof<nothing, bool>
  --webhook-url: string # format: uri
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Sync/Services/{Sid}"
    path_params: [{name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: AclEnabled, var: acl_enabled}, {name: FriendlyName, var: friendly_name}, {name: ReachabilityWebhooksEnabled, var: reachability_webhooks_enabled}, {name: WebhookUrl, var: webhook_url}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    sid: $sid, acl_enabled: $acl_enabled, friendly_name: $friendly_name, reachability_webhooks_enabled: $reachability_webhooks_enabled, webhook_url: $webhook_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of Add-ons currently available to be installed.
#
# GET /marketplace/AvailableAddOns
# Returns: record<available_add_ons: table<configuration_schema: any, description: string, friendly_name: string, links: record, pricing_type: string, sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListMarketplaceAvailableAddOn
export def "list-marketplace-available-add-on" [
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
    path: "/marketplace/AvailableAddOns"
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of Extensions for the Available Add-on.
#
# GET /marketplace/AvailableAddOns/{AvailableAddOnSid}/Extensions
# Returns: record<extensions: table<available_add_on_sid: string, friendly_name: string, product_name: string, sid: string, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListMarketplaceAvailableAddOnExtension
export def "list-marketplace-available-add-on-extension" [
  available_add_on_sid: string
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
    path: "/marketplace/AvailableAddOns/{AvailableAddOnSid}/Extensions"
    path_params: [{name: AvailableAddOnSid, var: available_add_on_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    available_add_on_sid: $available_add_on_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch an instance of an Extension for the Available Add-on.
#
# GET /marketplace/AvailableAddOns/{AvailableAddOnSid}/Extensions/{Sid}
# Returns: record<available_add_on_sid: string, friendly_name: string, product_name: string, sid: string, unique_name: string, url: string>
# operationId: FetchMarketplaceAvailableAddOnExtension
export def "fetch-marketplace-available-add-on-extension" [
  available_add_on_sid: string
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
    path: "/marketplace/AvailableAddOns/{AvailableAddOnSid}/Extensions/{Sid}"
    path_params: [{name: AvailableAddOnSid, var: available_add_on_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    available_add_on_sid: $available_add_on_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch an instance of an Add-on currently available to be installed.
#
# GET /marketplace/AvailableAddOns/{Sid}
# Returns: record<configuration_schema: any, description: string, friendly_name: string, links: record, pricing_type: string, sid: string, url: string>
# operationId: FetchMarketplaceAvailableAddOn
export def "fetch-marketplace-available-add-on" [
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
    path: "/marketplace/AvailableAddOns/{Sid}"
    path_params: [{name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of Add-ons currently installed on this Account.
#
# GET /marketplace/InstalledAddOns
# Returns: record<installed_add_ons: table<account_sid: string, configuration: any, date_created: string, date_updated: string, description: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListMarketplaceInstalledAddOn
export def "list-marketplace-installed-add-on" [
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
    path: "/marketplace/InstalledAddOns"
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Install an Add-on for the Account specified.
#
# POST /marketplace/InstalledAddOns
# Returns: record<account_sid: string, configuration: any, date_created: string, date_updated: string, description: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string>
# operationId: CreateMarketplaceInstalledAddOn
export def "create-marketplace-installed-add-on" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-terms-of-service: oneof<nothing, bool> # Whether the Terms of Service were accepted.
  available_add_on_sid: string # The SID of the AvaliableAddOn to install.
  --configuration: any # The JSON object that represents the configuration of the new Add-on being installed.
  --unique-name: string # An application-defined string that uniquely identifies the resource. This value must be unique within the Account.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/marketplace/InstalledAddOns"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: AcceptTermsOfService, var: accept_terms_of_service, required: true}, {name: AvailableAddOnSid, var: available_add_on_sid}, {name: Configuration, var: configuration}, {name: UniqueName, var: unique_name}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    accept_terms_of_service: $accept_terms_of_service, available_add_on_sid: $available_add_on_sid, configuration: $configuration, unique_name: $unique_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of Extensions for the Installed Add-on.
#
# GET /marketplace/InstalledAddOns/{InstalledAddOnSid}/Extensions
# Returns: record<extensions: table<enabled: bool, friendly_name: string, installed_add_on_sid: string, product_name: string, sid: string, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListMarketplaceInstalledAddOnExtension
export def "list-marketplace-installed-add-on-extension" [
  installed_add_on_sid: string
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
    path: "/marketplace/InstalledAddOns/{InstalledAddOnSid}/Extensions"
    path_params: [{name: InstalledAddOnSid, var: installed_add_on_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    installed_add_on_sid: $installed_add_on_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch an instance of an Extension for the Installed Add-on.
#
# GET /marketplace/InstalledAddOns/{InstalledAddOnSid}/Extensions/{Sid}
# Returns: record<enabled: bool, friendly_name: string, installed_add_on_sid: string, product_name: string, sid: string, unique_name: string, url: string>
# operationId: FetchMarketplaceInstalledAddOnExtension
export def "fetch-marketplace-installed-add-on-extension" [
  installed_add_on_sid: string
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
    path: "/marketplace/InstalledAddOns/{InstalledAddOnSid}/Extensions/{Sid}"
    path_params: [{name: InstalledAddOnSid, var: installed_add_on_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    installed_add_on_sid: $installed_add_on_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an Extension for an Add-on installation.
#
# POST /marketplace/InstalledAddOns/{InstalledAddOnSid}/Extensions/{Sid}
# Returns: record<enabled: bool, friendly_name: string, installed_add_on_sid: string, product_name: string, sid: string, unique_name: string, url: string>
# operationId: UpdateMarketplaceInstalledAddOnExtension
export def "update-marketplace-installed-add-on-extension" [
  installed_add_on_sid: string
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
  --enabled: oneof<nothing, bool> # Whether the Extension should be invoked.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/marketplace/InstalledAddOns/{InstalledAddOnSid}/Extensions/{Sid}"
    path_params: [{name: InstalledAddOnSid, var: installed_add_on_sid}, {name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Enabled, var: enabled, required: true}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    installed_add_on_sid: $installed_add_on_sid, sid: $sid, enabled: $enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove an Add-on installation from your account
#
# DELETE /marketplace/InstalledAddOns/{Sid}
# operationId: DeleteMarketplaceInstalledAddOn
export def "delete-marketplace-installed-add-on" [
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
    path: "/marketplace/InstalledAddOns/{Sid}"
    path_params: [{name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch an instance of an Add-on currently installed on this Account.
#
# GET /marketplace/InstalledAddOns/{Sid}
# Returns: record<account_sid: string, configuration: any, date_created: string, date_updated: string, description: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string>
# operationId: FetchMarketplaceInstalledAddOn
export def "fetch-marketplace-installed-add-on" [
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
    path: "/marketplace/InstalledAddOns/{Sid}"
    path_params: [{name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an Add-on installation for the Account specified.
#
# POST /marketplace/InstalledAddOns/{Sid}
# Returns: record<account_sid: string, configuration: any, date_created: string, date_updated: string, description: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string>
# operationId: UpdateMarketplaceInstalledAddOn
export def "update-marketplace-installed-add-on" [
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
  --configuration: any # Valid JSON object that conform to the configuration schema exposed by the associated AvailableAddOn resource. This is only required by Add-ons that need to be configured
  --unique-name: string # An application-defined string that uniquely identifies the resource. This value must be unique within the Account.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/marketplace/InstalledAddOns/{Sid}"
    path_params: [{name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Configuration, var: configuration}, {name: UniqueName, var: unique_name}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    sid: $sid, configuration: $configuration, unique_name: $unique_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /understand/Assistants
#
# Returns: record<assistants: table<account_sid: string, callback_events: string, callback_url: string, date_created: string, date_updated: string, friendly_name: string, latest_model_build_sid: string, links: record, log_queries: bool, sid: string, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListUnderstandAssistant
export def "list-understand-assistant" [
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
    path: "/understand/Assistants"
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /understand/Assistants
#
# Returns: record<account_sid: string, callback_events: string, callback_url: string, date_created: string, date_updated: string, friendly_name: string, latest_model_build_sid: string, links: record, log_queries: bool, sid: string, unique_name: string, url: string>
# operationId: CreateUnderstandAssistant
export def "create-understand-assistant" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --callback-events: string # Space-separated list of callback events that will trigger callbacks.
  --callback-url: string # A user-provided URL to send event callbacks to. (format: uri)
  --fallback-actions: any # The JSON actions to be executed when the user's input is not recognized as matching any Task.
  --friendly-name: string # A text description for the Assistant. It is non-unique and can up to 255 characters long.
  --initiation-actions: any # The JSON actions to be executed on inbound phone calls when the Assistant has to say something first.
  --log-queries: oneof<nothing, bool> # A boolean that specifies whether queries should be logged for 30 days further training. If false, no queries will be stored, if true, queries will be stored for 30 days and deleted thereafter. Defaults to true if no value is provided.
  --style-sheet: any # The JSON object that holds the style sheet for the assistant
  --unique-name: string # A user-provided string that uniquely identifies this resource as an alternative to the sid. Unique up to 64 characters long.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/understand/Assistants"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: CallbackEvents, var: callback_events}, {name: CallbackUrl, var: callback_url}, {name: FallbackActions, var: fallback_actions}, {name: FriendlyName, var: friendly_name}, {name: InitiationActions, var: initiation_actions}, {name: LogQueries, var: log_queries}, {name: StyleSheet, var: style_sheet}, {name: UniqueName, var: unique_name}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    callback_events: $callback_events, callback_url: $callback_url, fallback_actions: $fallback_actions, friendly_name: $friendly_name, initiation_actions: $initiation_actions, log_queries: $log_queries, style_sheet: $style_sheet, unique_name: $unique_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /understand/Assistants/{AssistantSid}/Dialogues/{Sid}
#
# Returns: record<account_sid: string, assistant_sid: string, data: any, sid: string, url: string>
# operationId: FetchUnderstandDialogue
export def "fetch-understand-dialogue" [
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
    path: "/understand/Assistants/{AssistantSid}/Dialogues/{Sid}"
    path_params: [{name: AssistantSid, var: assistant_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /understand/Assistants/{AssistantSid}/FallbackActions
#
# Returns: record<account_sid: string, assistant_sid: string, data: any, url: string>
# operationId: FetchUnderstandAssistantFallbackActions
export def "fetch-understand-assistant-fallback-actions" [
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
    path: "/understand/Assistants/{AssistantSid}/FallbackActions"
    path_params: [{name: AssistantSid, var: assistant_sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /understand/Assistants/{AssistantSid}/FallbackActions
#
# Returns: record<account_sid: string, assistant_sid: string, data: any, url: string>
# operationId: UpdateUnderstandAssistantFallbackActions
export def "update-understand-assistant-fallback-actions" [
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
  --fallback-actions: any
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/understand/Assistants/{AssistantSid}/FallbackActions"
    path_params: [{name: AssistantSid, var: assistant_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: FallbackActions, var: fallback_actions}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, fallback_actions: $fallback_actions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /understand/Assistants/{AssistantSid}/FieldTypes
#
# Returns: record<field_types: table<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListUnderstandFieldType
export def "list-understand-field-type" [
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
    path: "/understand/Assistants/{AssistantSid}/FieldTypes"
    path_params: [{name: AssistantSid, var: assistant_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /understand/Assistants/{AssistantSid}/FieldTypes
#
# Returns: record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string>
# operationId: CreateUnderstandFieldType
export def "create-understand-field-type" [
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
  --friendly-name: string # A user-provided string that identifies this resource. It is non-unique and can up to 255 characters long.
  unique_name: string # A user-provided string that uniquely identifies this resource as an alternative to the sid. Unique up to 64 characters long.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/understand/Assistants/{AssistantSid}/FieldTypes"
    path_params: [{name: AssistantSid, var: assistant_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: FriendlyName, var: friendly_name}, {name: UniqueName, var: unique_name}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, friendly_name: $friendly_name, unique_name: $unique_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /understand/Assistants/{AssistantSid}/FieldTypes/{FieldTypeSid}/FieldValues
#
# Returns: record<field_values: table<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, field_type_sid: string, language: string, sid: string, synonym_of: string, url: string, value: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListUnderstandFieldValue
export def "list-understand-field-value" [
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
  --language: string # An ISO language-country string of the value. For example: *en-US*
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/understand/Assistants/{AssistantSid}/FieldTypes/{FieldTypeSid}/FieldValues"
    path_params: [{name: AssistantSid, var: assistant_sid}, {name: FieldTypeSid, var: field_type_sid}]
    query: [{name: Language, var: language}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, field_type_sid: $field_type_sid, language: $language, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /understand/Assistants/{AssistantSid}/FieldTypes/{FieldTypeSid}/FieldValues
#
# Returns: record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, field_type_sid: string, language: string, sid: string, synonym_of: string, url: string, value: string>
# operationId: CreateUnderstandFieldValue
export def "create-understand-field-value" [
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
  language: string # An ISO language-country string of the value.
  --synonym-of: string # A value that indicates this field value is a synonym of. Empty if the value is not a synonym.
  value: string # A user-provided string that uniquely identifies this resource as an alternative to the sid. Unique up to 64 characters long.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/understand/Assistants/{AssistantSid}/FieldTypes/{FieldTypeSid}/FieldValues"
    path_params: [{name: AssistantSid, var: assistant_sid}, {name: FieldTypeSid, var: field_type_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Language, var: language}, {name: SynonymOf, var: synonym_of}, {name: Value, var: value}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, field_type_sid: $field_type_sid, language: $language, synonym_of: $synonym_of, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /understand/Assistants/{AssistantSid}/FieldTypes/{FieldTypeSid}/FieldValues/{Sid}
#
# operationId: DeleteUnderstandFieldValue
export def "delete-understand-field-value" [
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
    path: "/understand/Assistants/{AssistantSid}/FieldTypes/{FieldTypeSid}/FieldValues/{Sid}"
    path_params: [{name: AssistantSid, var: assistant_sid}, {name: FieldTypeSid, var: field_type_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, field_type_sid: $field_type_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /understand/Assistants/{AssistantSid}/FieldTypes/{FieldTypeSid}/FieldValues/{Sid}
#
# Returns: record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, field_type_sid: string, language: string, sid: string, synonym_of: string, url: string, value: string>
# operationId: FetchUnderstandFieldValue
export def "fetch-understand-field-value" [
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
    path: "/understand/Assistants/{AssistantSid}/FieldTypes/{FieldTypeSid}/FieldValues/{Sid}"
    path_params: [{name: AssistantSid, var: assistant_sid}, {name: FieldTypeSid, var: field_type_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, field_type_sid: $field_type_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /understand/Assistants/{AssistantSid}/FieldTypes/{Sid}
#
# operationId: DeleteUnderstandFieldType
export def "delete-understand-field-type" [
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
    path: "/understand/Assistants/{AssistantSid}/FieldTypes/{Sid}"
    path_params: [{name: AssistantSid, var: assistant_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /understand/Assistants/{AssistantSid}/FieldTypes/{Sid}
#
# Returns: record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string>
# operationId: FetchUnderstandFieldType
export def "fetch-understand-field-type" [
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
    path: "/understand/Assistants/{AssistantSid}/FieldTypes/{Sid}"
    path_params: [{name: AssistantSid, var: assistant_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /understand/Assistants/{AssistantSid}/FieldTypes/{Sid}
#
# Returns: record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string>
# operationId: UpdateUnderstandFieldType
export def "update-understand-field-type" [
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
  --friendly-name: string # A user-provided string that identifies this resource. It is non-unique and can up to 255 characters long.
  --unique-name: string # A user-provided string that uniquely identifies this resource as an alternative to the sid. Unique up to 64 characters long.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/understand/Assistants/{AssistantSid}/FieldTypes/{Sid}"
    path_params: [{name: AssistantSid, var: assistant_sid}, {name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: FriendlyName, var: friendly_name}, {name: UniqueName, var: unique_name}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, sid: $sid, friendly_name: $friendly_name, unique_name: $unique_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /understand/Assistants/{AssistantSid}/InitiationActions
#
# Returns: record<account_sid: string, assistant_sid: string, data: any, url: string>
# operationId: FetchUnderstandAssistantInitiationActions
export def "fetch-understand-assistant-initiation-actions" [
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
    path: "/understand/Assistants/{AssistantSid}/InitiationActions"
    path_params: [{name: AssistantSid, var: assistant_sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /understand/Assistants/{AssistantSid}/InitiationActions
#
# Returns: record<account_sid: string, assistant_sid: string, data: any, url: string>
# operationId: UpdateUnderstandAssistantInitiationActions
export def "update-understand-assistant-initiation-actions" [
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
  --initiation-actions: any
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/understand/Assistants/{AssistantSid}/InitiationActions"
    path_params: [{name: AssistantSid, var: assistant_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: InitiationActions, var: initiation_actions}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, initiation_actions: $initiation_actions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /understand/Assistants/{AssistantSid}/ModelBuilds
#
# Returns: record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, model_builds: table<account_sid: string, assistant_sid: string, build_duration: int, date_created: string, date_updated: string, error_code: int, sid: string, status: string, unique_name: string, url: string>>
# operationId: ListUnderstandModelBuild
export def "list-understand-model-build" [
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
    path: "/understand/Assistants/{AssistantSid}/ModelBuilds"
    path_params: [{name: AssistantSid, var: assistant_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /understand/Assistants/{AssistantSid}/ModelBuilds
#
# Returns: record<account_sid: string, assistant_sid: string, build_duration: int, date_created: string, date_updated: string, error_code: int, sid: string, status: string, unique_name: string, url: string>
# operationId: CreateUnderstandModelBuild
export def "create-understand-model-build" [
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
  --status-callback: string # format: uri
  --unique-name: string # A user-provided string that uniquely identifies this resource as an alternative to the sid. Unique up to 64 characters long. For example: v0.1
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/understand/Assistants/{AssistantSid}/ModelBuilds"
    path_params: [{name: AssistantSid, var: assistant_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: StatusCallback, var: status_callback}, {name: UniqueName, var: unique_name}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, status_callback: $status_callback, unique_name: $unique_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /understand/Assistants/{AssistantSid}/ModelBuilds/{Sid}
#
# operationId: DeleteUnderstandModelBuild
export def "delete-understand-model-build" [
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
    path: "/understand/Assistants/{AssistantSid}/ModelBuilds/{Sid}"
    path_params: [{name: AssistantSid, var: assistant_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /understand/Assistants/{AssistantSid}/ModelBuilds/{Sid}
#
# Returns: record<account_sid: string, assistant_sid: string, build_duration: int, date_created: string, date_updated: string, error_code: int, sid: string, status: string, unique_name: string, url: string>
# operationId: FetchUnderstandModelBuild
export def "fetch-understand-model-build" [
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
    path: "/understand/Assistants/{AssistantSid}/ModelBuilds/{Sid}"
    path_params: [{name: AssistantSid, var: assistant_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /understand/Assistants/{AssistantSid}/ModelBuilds/{Sid}
#
# Returns: record<account_sid: string, assistant_sid: string, build_duration: int, date_created: string, date_updated: string, error_code: int, sid: string, status: string, unique_name: string, url: string>
# operationId: UpdateUnderstandModelBuild
export def "update-understand-model-build" [
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
  --unique-name: string # A user-provided string that uniquely identifies this resource as an alternative to the sid. Unique up to 64 characters long. For example: v0.1
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/understand/Assistants/{AssistantSid}/ModelBuilds/{Sid}"
    path_params: [{name: AssistantSid, var: assistant_sid}, {name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: UniqueName, var: unique_name}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, sid: $sid, unique_name: $unique_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /understand/Assistants/{AssistantSid}/Queries
#
# Returns: record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, queries: table<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, language: string, model_build_sid: string, query: string, results: any, sample_sid: string, sid: string, source_channel: string, status: string, url: string>>
# operationId: ListUnderstandQuery
export def "list-understand-query" [
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
  --language: string # An ISO language-country string of the sample.
  --model-build: string # The Model Build Sid or unique name of the Model Build to be queried.
  --status: string # A string that described the query status. The values can be: pending_review, reviewed, discarded
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/understand/Assistants/{AssistantSid}/Queries"
    path_params: [{name: AssistantSid, var: assistant_sid}]
    query: [{name: Language, var: language}, {name: ModelBuild, var: model_build}, {name: Status, var: status}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, language: $language, model_build: $model_build, status: $status, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /understand/Assistants/{AssistantSid}/Queries
#
# Returns: record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, language: string, model_build_sid: string, query: string, results: any, sample_sid: string, sid: string, source_channel: string, status: string, url: string>
# operationId: CreateUnderstandQuery
export def "create-understand-query" [
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
  --field: string # Constraints the query to a given Field with an task. Useful when you know the Field you are expecting. It accepts one field in the format *task-unique-name-1*:*field-unique-name*
  language: string # An ISO language-country string of the sample.
  --model-build: string # The Model Build Sid or unique name of the Model Build to be queried.
  query: string # A user-provided string that uniquely identifies this resource as an alternative to the sid. It can be up to 2048 characters long.
  --tasks: string # Constraints the query to a set of tasks. Useful when you need to constrain the paths the user can take. Tasks should be comma separated *task-unique-name-1*, *task-unique-name-2*
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/understand/Assistants/{AssistantSid}/Queries"
    path_params: [{name: AssistantSid, var: assistant_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Field, var: field}, {name: Language, var: language}, {name: ModelBuild, var: model_build}, {name: Query, var: query}, {name: Tasks, var: tasks}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, field: $field, language: $language, model_build: $model_build, query: $query, tasks: $tasks
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /understand/Assistants/{AssistantSid}/Queries/{Sid}
#
# operationId: DeleteUnderstandQuery
export def "delete-understand-query" [
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
    path: "/understand/Assistants/{AssistantSid}/Queries/{Sid}"
    path_params: [{name: AssistantSid, var: assistant_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /understand/Assistants/{AssistantSid}/Queries/{Sid}
#
# Returns: record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, language: string, model_build_sid: string, query: string, results: any, sample_sid: string, sid: string, source_channel: string, status: string, url: string>
# operationId: FetchUnderstandQuery
export def "fetch-understand-query" [
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
    path: "/understand/Assistants/{AssistantSid}/Queries/{Sid}"
    path_params: [{name: AssistantSid, var: assistant_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /understand/Assistants/{AssistantSid}/Queries/{Sid}
#
# Returns: record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, language: string, model_build_sid: string, query: string, results: any, sample_sid: string, sid: string, source_channel: string, status: string, url: string>
# operationId: UpdateUnderstandQuery
export def "update-understand-query" [
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
  --sample-sid: string # An optional reference to the Sample created from this query.
  --status: string # A string that described the query status. The values can be: pending_review, reviewed, discarded
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/understand/Assistants/{AssistantSid}/Queries/{Sid}"
    path_params: [{name: AssistantSid, var: assistant_sid}, {name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: SampleSid, var: sample_sid}, {name: Status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, sid: $sid, sample_sid: $sample_sid, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns Style sheet JSON object for this Assistant
#
# GET /understand/Assistants/{AssistantSid}/StyleSheet
# Returns: record<account_sid: string, assistant_sid: string, data: any, url: string>
# operationId: FetchUnderstandStyleSheet
export def "fetch-understand-style-sheet" [
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
    path: "/understand/Assistants/{AssistantSid}/StyleSheet"
    path_params: [{name: AssistantSid, var: assistant_sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the style sheet for an assistant identified by {AssistantSid} or {AssistantUniqueName}.
#
# POST /understand/Assistants/{AssistantSid}/StyleSheet
# Returns: record<account_sid: string, assistant_sid: string, data: any, url: string>
# operationId: UpdateUnderstandStyleSheet
export def "update-understand-style-sheet" [
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
  --style-sheet: any # The JSON Style sheet string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/understand/Assistants/{AssistantSid}/StyleSheet"
    path_params: [{name: AssistantSid, var: assistant_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: StyleSheet, var: style_sheet}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, style_sheet: $style_sheet
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /understand/Assistants/{AssistantSid}/Tasks
#
# Returns: record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, tasks: table<account_sid: string, actions_url: string, assistant_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string>>
# operationId: ListUnderstandTask
export def "list-understand-task" [
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
    path: "/understand/Assistants/{AssistantSid}/Tasks"
    path_params: [{name: AssistantSid, var: assistant_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /understand/Assistants/{AssistantSid}/Tasks
#
# Returns: record<account_sid: string, actions_url: string, assistant_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string>
# operationId: CreateUnderstandTask
export def "create-understand-task" [
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
  --actions: any # A user-provided JSON object encoded as a string to specify the actions for this task. It is optional and non-unique.
  --actions-url: string # User-provided HTTP endpoint where from the assistant fetches actions (format: uri)
  --friendly-name: string # A user-provided string that identifies this resource. It is non-unique and can up to 255 characters long.
  unique_name: string # A user-provided string that uniquely identifies this resource as an alternative to the sid. Unique up to 64 characters long.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/understand/Assistants/{AssistantSid}/Tasks"
    path_params: [{name: AssistantSid, var: assistant_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Actions, var: actions}, {name: ActionsUrl, var: actions_url}, {name: FriendlyName, var: friendly_name}, {name: UniqueName, var: unique_name}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, actions: $actions, actions_url: $actions_url, friendly_name: $friendly_name, unique_name: $unique_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /understand/Assistants/{AssistantSid}/Tasks/{Sid}
#
# operationId: DeleteUnderstandTask
export def "delete-understand-task" [
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
    path: "/understand/Assistants/{AssistantSid}/Tasks/{Sid}"
    path_params: [{name: AssistantSid, var: assistant_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /understand/Assistants/{AssistantSid}/Tasks/{Sid}
#
# Returns: record<account_sid: string, actions_url: string, assistant_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string>
# operationId: FetchUnderstandTask
export def "fetch-understand-task" [
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
    path: "/understand/Assistants/{AssistantSid}/Tasks/{Sid}"
    path_params: [{name: AssistantSid, var: assistant_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /understand/Assistants/{AssistantSid}/Tasks/{Sid}
#
# Returns: record<account_sid: string, actions_url: string, assistant_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string>
# operationId: UpdateUnderstandTask
export def "update-understand-task" [
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
  --actions: any # A user-provided JSON object encoded as a string to specify the actions for this task. It is optional and non-unique.
  --actions-url: string # User-provided HTTP endpoint where from the assistant fetches actions (format: uri)
  --friendly-name: string # A user-provided string that identifies this resource. It is non-unique and can up to 255 characters long.
  --unique-name: string # A user-provided string that uniquely identifies this resource as an alternative to the sid. Unique up to 64 characters long.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/understand/Assistants/{AssistantSid}/Tasks/{Sid}"
    path_params: [{name: AssistantSid, var: assistant_sid}, {name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Actions, var: actions}, {name: ActionsUrl, var: actions_url}, {name: FriendlyName, var: friendly_name}, {name: UniqueName, var: unique_name}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, sid: $sid, actions: $actions, actions_url: $actions_url, friendly_name: $friendly_name, unique_name: $unique_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns JSON actions for this Task.
#
# GET /understand/Assistants/{AssistantSid}/Tasks/{TaskSid}/Actions
# Returns: record<account_sid: string, assistant_sid: string, data: any, task_sid: string, url: string>
# operationId: FetchUnderstandTaskActions
export def "fetch-understand-task-actions" [
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
    path: "/understand/Assistants/{AssistantSid}/Tasks/{TaskSid}/Actions"
    path_params: [{name: AssistantSid, var: assistant_sid}, {name: TaskSid, var: task_sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, task_sid: $task_sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the actions of an Task identified by {TaskSid} or {TaskUniqueName}.
#
# POST /understand/Assistants/{AssistantSid}/Tasks/{TaskSid}/Actions
# Returns: record<account_sid: string, assistant_sid: string, data: any, task_sid: string, url: string>
# operationId: UpdateUnderstandTaskActions
export def "update-understand-task-actions" [
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
  --actions: any # The JSON actions that instruct the Assistant how to perform this task.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/understand/Assistants/{AssistantSid}/Tasks/{TaskSid}/Actions"
    path_params: [{name: AssistantSid, var: assistant_sid}, {name: TaskSid, var: task_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Actions, var: actions}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, task_sid: $task_sid, actions: $actions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /understand/Assistants/{AssistantSid}/Tasks/{TaskSid}/Fields
#
# Returns: record<fields: table<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, field_type: string, sid: string, task_sid: string, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListUnderstandField
export def "list-understand-field" [
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
    path: "/understand/Assistants/{AssistantSid}/Tasks/{TaskSid}/Fields"
    path_params: [{name: AssistantSid, var: assistant_sid}, {name: TaskSid, var: task_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, task_sid: $task_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /understand/Assistants/{AssistantSid}/Tasks/{TaskSid}/Fields
#
# Returns: record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, field_type: string, sid: string, task_sid: string, unique_name: string, url: string>
# operationId: CreateUnderstandField
export def "create-understand-field" [
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
  field_type: string # The unique name or sid of the FieldType. It can be any [Built-in Field Type](https://www.twilio.com/docs/assistant/api/built-in-field-types) or the unique_name or the Field Type sid of a custom Field Type.
  unique_name: string # A user-provided string that uniquely identifies this resource as an alternative to the sid. Unique up to 64 characters long.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/understand/Assistants/{AssistantSid}/Tasks/{TaskSid}/Fields"
    path_params: [{name: AssistantSid, var: assistant_sid}, {name: TaskSid, var: task_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: FieldType, var: field_type}, {name: UniqueName, var: unique_name}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, task_sid: $task_sid, field_type: $field_type, unique_name: $unique_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /understand/Assistants/{AssistantSid}/Tasks/{TaskSid}/Fields/{Sid}
#
# operationId: DeleteUnderstandField
export def "delete-understand-field" [
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
    path: "/understand/Assistants/{AssistantSid}/Tasks/{TaskSid}/Fields/{Sid}"
    path_params: [{name: AssistantSid, var: assistant_sid}, {name: TaskSid, var: task_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, task_sid: $task_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /understand/Assistants/{AssistantSid}/Tasks/{TaskSid}/Fields/{Sid}
#
# Returns: record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, field_type: string, sid: string, task_sid: string, unique_name: string, url: string>
# operationId: FetchUnderstandField
export def "fetch-understand-field" [
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
    path: "/understand/Assistants/{AssistantSid}/Tasks/{TaskSid}/Fields/{Sid}"
    path_params: [{name: AssistantSid, var: assistant_sid}, {name: TaskSid, var: task_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, task_sid: $task_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /understand/Assistants/{AssistantSid}/Tasks/{TaskSid}/Samples
#
# Returns: record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, samples: table<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, language: string, sid: string, source_channel: string, tagged_text: string, task_sid: string, url: string>>
# operationId: ListUnderstandSample
export def "list-understand-sample" [
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
  --language: string # An ISO language-country string of the sample.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/understand/Assistants/{AssistantSid}/Tasks/{TaskSid}/Samples"
    path_params: [{name: AssistantSid, var: assistant_sid}, {name: TaskSid, var: task_sid}]
    query: [{name: Language, var: language}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, task_sid: $task_sid, language: $language, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /understand/Assistants/{AssistantSid}/Tasks/{TaskSid}/Samples
#
# Returns: record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, language: string, sid: string, source_channel: string, tagged_text: string, task_sid: string, url: string>
# operationId: CreateUnderstandSample
export def "create-understand-sample" [
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
  language: string # An ISO language-country string of the sample.
  --source-channel: string # The communication channel the sample was captured. It can be: *voice*, *sms*, *chat*, *alexa*, *google-assistant*, or *slack*. If not included the value will be null
  tagged_text: string # The text example of how end-users may express this task. The sample may contain Field tag blocks.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/understand/Assistants/{AssistantSid}/Tasks/{TaskSid}/Samples"
    path_params: [{name: AssistantSid, var: assistant_sid}, {name: TaskSid, var: task_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Language, var: language}, {name: SourceChannel, var: source_channel}, {name: TaggedText, var: tagged_text}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, task_sid: $task_sid, language: $language, source_channel: $source_channel, tagged_text: $tagged_text
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /understand/Assistants/{AssistantSid}/Tasks/{TaskSid}/Samples/{Sid}
#
# operationId: DeleteUnderstandSample
export def "delete-understand-sample" [
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
    path: "/understand/Assistants/{AssistantSid}/Tasks/{TaskSid}/Samples/{Sid}"
    path_params: [{name: AssistantSid, var: assistant_sid}, {name: TaskSid, var: task_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, task_sid: $task_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /understand/Assistants/{AssistantSid}/Tasks/{TaskSid}/Samples/{Sid}
#
# Returns: record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, language: string, sid: string, source_channel: string, tagged_text: string, task_sid: string, url: string>
# operationId: FetchUnderstandSample
export def "fetch-understand-sample" [
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
    path: "/understand/Assistants/{AssistantSid}/Tasks/{TaskSid}/Samples/{Sid}"
    path_params: [{name: AssistantSid, var: assistant_sid}, {name: TaskSid, var: task_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, task_sid: $task_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /understand/Assistants/{AssistantSid}/Tasks/{TaskSid}/Samples/{Sid}
#
# Returns: record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, language: string, sid: string, source_channel: string, tagged_text: string, task_sid: string, url: string>
# operationId: UpdateUnderstandSample
export def "update-understand-sample" [
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
  --language: string # An ISO language-country string of the sample.
  --source-channel: string # The communication channel the sample was captured. It can be: *voice*, *sms*, *chat*, *alexa*, *google-assistant*, or *slack*. If not included the value will be null
  --tagged-text: string # The text example of how end-users may express this task. The sample may contain Field tag blocks.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/understand/Assistants/{AssistantSid}/Tasks/{TaskSid}/Samples/{Sid}"
    path_params: [{name: AssistantSid, var: assistant_sid}, {name: TaskSid, var: task_sid}, {name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Language, var: language}, {name: SourceChannel, var: source_channel}, {name: TaggedText, var: tagged_text}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, task_sid: $task_sid, sid: $sid, language: $language, source_channel: $source_channel, tagged_text: $tagged_text
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /understand/Assistants/{AssistantSid}/Tasks/{TaskSid}/Statistics
#
# Returns: record<account_sid: string, assistant_sid: string, fields_count: int, samples_count: int, task_sid: string, url: string>
# operationId: FetchUnderstandTaskStatistics
export def "fetch-understand-task-statistics" [
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
    path: "/understand/Assistants/{AssistantSid}/Tasks/{TaskSid}/Statistics"
    path_params: [{name: AssistantSid, var: assistant_sid}, {name: TaskSid, var: task_sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    assistant_sid: $assistant_sid, task_sid: $task_sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /understand/Assistants/{Sid}
#
# operationId: DeleteUnderstandAssistant
export def "delete-understand-assistant" [
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
    path: "/understand/Assistants/{Sid}"
    path_params: [{name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /understand/Assistants/{Sid}
#
# Returns: record<account_sid: string, callback_events: string, callback_url: string, date_created: string, date_updated: string, friendly_name: string, latest_model_build_sid: string, links: record, log_queries: bool, sid: string, unique_name: string, url: string>
# operationId: FetchUnderstandAssistant
export def "fetch-understand-assistant" [
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
    path: "/understand/Assistants/{Sid}"
    path_params: [{name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /understand/Assistants/{Sid}
#
# Returns: record<account_sid: string, callback_events: string, callback_url: string, date_created: string, date_updated: string, friendly_name: string, latest_model_build_sid: string, links: record, log_queries: bool, sid: string, unique_name: string, url: string>
# operationId: UpdateUnderstandAssistant
export def "update-understand-assistant" [
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
  --callback-events: string # Space-separated list of callback events that will trigger callbacks.
  --callback-url: string # A user-provided URL to send event callbacks to. (format: uri)
  --fallback-actions: any # The JSON actions to be executed when the user's input is not recognized as matching any Task.
  --friendly-name: string # A text description for the Assistant. It is non-unique and can up to 255 characters long.
  --initiation-actions: any # The JSON actions to be executed on inbound phone calls when the Assistant has to say something first.
  --log-queries: oneof<nothing, bool> # A boolean that specifies whether queries should be logged for 30 days further training. If false, no queries will be stored, if true, queries will be stored for 30 days and deleted thereafter. Defaults to true if no value is provided.
  --style-sheet: any # The JSON object that holds the style sheet for the assistant
  --unique-name: string # A user-provided string that uniquely identifies this resource as an alternative to the sid. Unique up to 64 characters long.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/understand/Assistants/{Sid}"
    path_params: [{name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: CallbackEvents, var: callback_events}, {name: CallbackUrl, var: callback_url}, {name: FallbackActions, var: fallback_actions}, {name: FriendlyName, var: friendly_name}, {name: InitiationActions, var: initiation_actions}, {name: LogQueries, var: log_queries}, {name: StyleSheet, var: style_sheet}, {name: UniqueName, var: unique_name}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    sid: $sid, callback_events: $callback_events, callback_url: $callback_url, fallback_actions: $fallback_actions, friendly_name: $friendly_name, initiation_actions: $initiation_actions, log_queries: $log_queries, style_sheet: $style_sheet, unique_name: $unique_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /wireless/Commands
#
# Returns: record<commands: table<account_sid: string, command: string, command_mode: string, date_created: string, date_updated: string, device_sid: string, direction: string, sid: string, sim_sid: string, status: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListWirelessCommand
export def "list-wireless-command" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --device: string
  --sim: string
  --status: string
  --direction: string
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/wireless/Commands"
    query: [{name: Device, var: device}, {name: Sim, var: sim}, {name: Status, var: status}, {name: Direction, var: direction}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    device: $device, sim: $sim, status: $status, direction: $direction, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /wireless/Commands
#
# Returns: record<account_sid: string, command: string, command_mode: string, date_created: string, date_updated: string, device_sid: string, direction: string, sid: string, sim_sid: string, status: string, url: string>
# operationId: CreateWirelessCommand
export def "create-wireless-command" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --callback-method: string
  --callback-url: string # format: uri
  command: string
  --command-mode: string
  --device: string
  --include-sid: string
  --sim: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/wireless/Commands"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: CallbackMethod, var: callback_method}, {name: CallbackUrl, var: callback_url}, {name: Command, var: command}, {name: CommandMode, var: command_mode}, {name: Device, var: device}, {name: IncludeSid, var: include_sid}, {name: Sim, var: sim}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    callback_method: $callback_method, callback_url: $callback_url, command: $command, command_mode: $command_mode, device: $device, include_sid: $include_sid, sim: $sim
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /wireless/Commands/{Sid}
#
# Returns: record<account_sid: string, command: string, command_mode: string, date_created: string, date_updated: string, device_sid: string, direction: string, sid: string, sim_sid: string, status: string, url: string>
# operationId: FetchWirelessCommand
export def "fetch-wireless-command" [
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
    path: "/wireless/Commands/{Sid}"
    path_params: [{name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /wireless/RatePlans
#
# Returns: record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, rate_plans: table<account_sid: string, data_enabled: bool, data_limit: int, data_metering: string, date_created: string, date_updated: string, friendly_name: string, international_roaming: list, messaging_enabled: bool, national_roaming_enabled: bool, sid: string, unique_name: string, url: string, voice_enabled: bool>>
# operationId: ListWirelessRatePlan
export def "list-wireless-rate-plan" [
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
    path: "/wireless/RatePlans"
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /wireless/RatePlans
#
# Returns: record<account_sid: string, data_enabled: bool, data_limit: int, data_metering: string, date_created: string, date_updated: string, friendly_name: string, international_roaming: list<string>, messaging_enabled: bool, national_roaming_enabled: bool, sid: string, unique_name: string, url: string, voice_enabled: bool>
# operationId: CreateWirelessRatePlan
export def "create-wireless-rate-plan" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --commands-enabled: oneof<nothing, bool>
  --data-enabled: oneof<nothing, bool>
  --data-limit: int
  --data-metering: string
  --friendly-name: string
  --international-roaming: list<string>
  --messaging-enabled: oneof<nothing, bool>
  --national-roaming-enabled: oneof<nothing, bool>
  --unique-name: string
  --voice-enabled: oneof<nothing, bool>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/wireless/RatePlans"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: CommandsEnabled, var: commands_enabled}, {name: DataEnabled, var: data_enabled}, {name: DataLimit, var: data_limit}, {name: DataMetering, var: data_metering}, {name: FriendlyName, var: friendly_name}, {name: InternationalRoaming, var: international_roaming}, {name: MessagingEnabled, var: messaging_enabled}, {name: NationalRoamingEnabled, var: national_roaming_enabled}, {name: UniqueName, var: unique_name}, {name: VoiceEnabled, var: voice_enabled}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    commands_enabled: $commands_enabled, data_enabled: $data_enabled, data_limit: $data_limit, data_metering: $data_metering, friendly_name: $friendly_name, international_roaming: $international_roaming, messaging_enabled: $messaging_enabled, national_roaming_enabled: $national_roaming_enabled, unique_name: $unique_name, voice_enabled: $voice_enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /wireless/RatePlans/{Sid}
#
# operationId: DeleteWirelessRatePlan
export def "delete-wireless-rate-plan" [
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
    path: "/wireless/RatePlans/{Sid}"
    path_params: [{name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /wireless/RatePlans/{Sid}
#
# Returns: record<account_sid: string, data_enabled: bool, data_limit: int, data_metering: string, date_created: string, date_updated: string, friendly_name: string, international_roaming: list<string>, messaging_enabled: bool, national_roaming_enabled: bool, sid: string, unique_name: string, url: string, voice_enabled: bool>
# operationId: FetchWirelessRatePlan
export def "fetch-wireless-rate-plan" [
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
    path: "/wireless/RatePlans/{Sid}"
    path_params: [{name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /wireless/RatePlans/{Sid}
#
# Returns: record<account_sid: string, data_enabled: bool, data_limit: int, data_metering: string, date_created: string, date_updated: string, friendly_name: string, international_roaming: list<string>, messaging_enabled: bool, national_roaming_enabled: bool, sid: string, unique_name: string, url: string, voice_enabled: bool>
# operationId: UpdateWirelessRatePlan
export def "update-wireless-rate-plan" [
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
  --friendly-name: string
  --unique-name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/wireless/RatePlans/{Sid}"
    path_params: [{name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: FriendlyName, var: friendly_name}, {name: UniqueName, var: unique_name}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    sid: $sid, friendly_name: $friendly_name, unique_name: $unique_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /wireless/Sims
#
# Returns: record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, sims: table<account_sid: string, commands_callback_method: string, commands_callback_url: string, date_created: string, date_updated: string, e_id: string, friendly_name: string, iccid: string, links: record, rate_plan_sid: string, sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, status: string, unique_name: string, url: string, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_url: string>>
# operationId: ListWirelessSim
export def "list-wireless-sim" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string
  --iccid: string
  --rate-plan: string
  --e-id: string
  --sim-registration-code: string
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/wireless/Sims"
    query: [{name: Status, var: status}, {name: Iccid, var: iccid}, {name: RatePlan, var: rate_plan}, {name: EId, var: e_id}, {name: SimRegistrationCode, var: sim_registration_code}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    status: $status, iccid: $iccid, rate_plan: $rate_plan, e_id: $e_id, sim_registration_code: $sim_registration_code, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /wireless/Sims/{Sid}
#
# Returns: record<account_sid: string, commands_callback_method: string, commands_callback_url: string, date_created: string, date_updated: string, e_id: string, friendly_name: string, iccid: string, links: record, rate_plan_sid: string, sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, status: string, unique_name: string, url: string, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_url: string>
# operationId: FetchWirelessSim
export def "fetch-wireless-sim" [
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
    path: "/wireless/Sims/{Sid}"
    path_params: [{name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /wireless/Sims/{Sid}
#
# Returns: record<account_sid: string, commands_callback_method: string, commands_callback_url: string, date_created: string, date_updated: string, e_id: string, friendly_name: string, iccid: string, links: record, rate_plan_sid: string, sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, status: string, unique_name: string, url: string, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_url: string>
# operationId: UpdateWirelessSim
export def "update-wireless-sim" [
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
  --callback-method: string
  --callback-url: string # format: uri
  --commands-callback-method: string@commands-callback-method-completer # format: http-method
  --commands-callback-url: string # format: uri
  --friendly-name: string
  --rate-plan: string
  --sms-fallback-method: string@sms-fallback-method-completer # format: http-method
  --sms-fallback-url: string # format: uri
  --sms-method: string@sms-method-completer # format: http-method
  --sms-url: string # format: uri
  --status: string
  --unique-name: string
  --voice-fallback-method: string@voice-fallback-method-completer # format: http-method
  --voice-fallback-url: string # format: uri
  --voice-method: string@voice-method-completer # format: http-method
  --voice-url: string # format: uri
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/wireless/Sims/{Sid}"
    path_params: [{name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: CallbackMethod, var: callback_method}, {name: CallbackUrl, var: callback_url}, {name: CommandsCallbackMethod, var: commands_callback_method}, {name: CommandsCallbackUrl, var: commands_callback_url}, {name: FriendlyName, var: friendly_name}, {name: RatePlan, var: rate_plan}, {name: SmsFallbackMethod, var: sms_fallback_method}, {name: SmsFallbackUrl, var: sms_fallback_url}, {name: SmsMethod, var: sms_method}, {name: SmsUrl, var: sms_url}, {name: Status, var: status}, {name: UniqueName, var: unique_name}, {name: VoiceFallbackMethod, var: voice_fallback_method}, {name: VoiceFallbackUrl, var: voice_fallback_url}, {name: VoiceMethod, var: voice_method}, {name: VoiceUrl, var: voice_url}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    sid: $sid, callback_method: $callback_method, callback_url: $callback_url, commands_callback_method: $commands_callback_method, commands_callback_url: $commands_callback_url, friendly_name: $friendly_name, rate_plan: $rate_plan, sms_fallback_method: $sms_fallback_method, sms_fallback_url: $sms_fallback_url, sms_method: $sms_method, sms_url: $sms_url, status: $status, unique_name: $unique_name, voice_fallback_method: $voice_fallback_method, voice_fallback_url: $voice_fallback_url, voice_method: $voice_method, voice_url: $voice_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /wireless/Sims/{SimSid}/Usage
#
# Returns: record<account_sid: string, commands_costs: any, commands_usage: any, data_costs: any, data_usage: any, period: any, sim_sid: string, sim_unique_name: string, url: string>
# operationId: FetchWirelessUsage
export def "fetch-wireless-usage" [
  sim_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --end: string
  --start: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/wireless/Sims/{SimSid}/Usage"
    path_params: [{name: SimSid, var: sim_sid}]
    query: [{name: End, var: end}, {name: Start, var: start}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://preview.twilio.com"
    auth: basic
  } {
    sim_sid: $sim_sid, end: $end, start: $start
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
