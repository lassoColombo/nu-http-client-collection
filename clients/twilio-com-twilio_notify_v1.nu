# Auto-generated client for Twilio - Notify v1.42.0
# Source: https://api.apis.guru/v2/specs/twilio.com/twilio_notify_v1/1.42.0/openapi.json
# Auth: --token flag or $env.TWILIO_NOTIFY_TOKEN

const CLIENT = {
  base_url: "https://notify.twilio.com"
  token_env_var: "TWILIO_NOTIFY_TOKEN"
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

def base-url-completer [] { ["https://notify.twilio.com"] }
def auth-scheme-completer [] { ["basic" "basic-credentials"] }

# Completers for enum parameters
def type-completer [] { ["apn" "fcm" "gcm"] }
def binding-type-completer [] { ["alexa" "apn" "facebook-messenger" "fcm" "gcm" "sms"] }
def priority-completer [] { ["high" "low"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    list-credential: "record<credentials: table<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sandbox: string, sid: string, type: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    create-credential: "record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sandbox: string, sid: string, type: string, url: string>"
    fetch-credential: "record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sandbox: string, sid: string, type: string, url: string>"
    update-credential: "record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sandbox: string, sid: string, type: string, url: string>"
    list-service: "record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, services: table<account_sid: string, alexa_skill_id: string, apn_credential_sid: string, date_created: string, date_updated: string, default_alexa_notification_protocol_version: string, default_apn_notification_protocol_version: string, default_fcm_notification_protocol_version: string, default_gcm_notification_protocol_version: string, delivery_callback_enabled: bool, delivery_callback_url: string, facebook_messenger_page_id: string, fcm_credential_sid: string, friendly_name: string, gcm_credential_sid: string, links: record, log_enabled: bool, messaging_service_sid: string, sid: string, url: string>>"
    create-service: "record<account_sid: string, alexa_skill_id: string, apn_credential_sid: string, date_created: string, date_updated: string, default_alexa_notification_protocol_version: string, default_apn_notification_protocol_version: string, default_fcm_notification_protocol_version: string, default_gcm_notification_protocol_version: string, delivery_callback_enabled: bool, delivery_callback_url: string, facebook_messenger_page_id: string, fcm_credential_sid: string, friendly_name: string, gcm_credential_sid: string, links: record, log_enabled: bool, messaging_service_sid: string, sid: string, url: string>"
    list-binding: "record<bindings: table<account_sid: string, address: string, binding_type: string, credential_sid: string, date_created: string, date_updated: string, endpoint: string, identity: string, links: record, notification_protocol_version: string, service_sid: string, sid: string, tags: list, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    create-binding: "record<account_sid: string, address: string, binding_type: string, credential_sid: string, date_created: string, date_updated: string, endpoint: string, identity: string, links: record, notification_protocol_version: string, service_sid: string, sid: string, tags: list<string>, url: string>"
    fetch-binding: "record<account_sid: string, address: string, binding_type: string, credential_sid: string, date_created: string, date_updated: string, endpoint: string, identity: string, links: record, notification_protocol_version: string, service_sid: string, sid: string, tags: list<string>, url: string>"
    create-notification: "record<account_sid: string, action: string, alexa: any, apn: any, body: string, data: any, date_created: string, facebook_messenger: any, fcm: any, gcm: any, identities: list<string>, priority: string, segments: list<string>, service_sid: string, sid: string, sms: any, sound: string, tags: list<string>, title: string, ttl: int>"
    fetch-service: "record<account_sid: string, alexa_skill_id: string, apn_credential_sid: string, date_created: string, date_updated: string, default_alexa_notification_protocol_version: string, default_apn_notification_protocol_version: string, default_fcm_notification_protocol_version: string, default_gcm_notification_protocol_version: string, delivery_callback_enabled: bool, delivery_callback_url: string, facebook_messenger_page_id: string, fcm_credential_sid: string, friendly_name: string, gcm_credential_sid: string, links: record, log_enabled: bool, messaging_service_sid: string, sid: string, url: string>"
    update-service: "record<account_sid: string, alexa_skill_id: string, apn_credential_sid: string, date_created: string, date_updated: string, default_alexa_notification_protocol_version: string, default_apn_notification_protocol_version: string, default_fcm_notification_protocol_version: string, default_gcm_notification_protocol_version: string, delivery_callback_enabled: bool, delivery_callback_url: string, facebook_messenger_page_id: string, fcm_credential_sid: string, friendly_name: string, gcm_credential_sid: string, links: record, log_enabled: bool, messaging_service_sid: string, sid: string, url: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["list-credential" "create-credential" "delete-credential" "fetch-credential" "update-credential" "list-service" "create-service" "list-binding" "create-binding" "delete-binding" "fetch-binding" "create-notification" "delete-service" "fetch-service" "update-service" "commands"] | sort) } | get name | first)
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

# GET /v1/Credentials
#
# Returns: record<credentials: table<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sandbox: string, sid: string, type: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListCredential
export def "list-credential" [
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
    path: "/v1/Credentials"
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://notify.twilio.com"
    auth: basic
  } {
    page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Credentials
#
# Returns: record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sandbox: string, sid: string, type: string, url: string>
# operationId: CreateCredential
export def "create-credential" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # [GCM only] The `Server key` of your project from Firebase console under Settings / Cloud messaging.
  --certificate: string # [APN only] The URL-encoded representation of the certificate. Strip everything outside of the headers, e.g. `-----BEGIN CERTIFICATE-----MIIFnTCCBIWgAwIBAgIIAjy9H849+E8wDQYJKoZIhvcNAQEFBQAwgZYxCzAJBgNV.....A==-----END CERTIFICATE-----`
  --friendly-name: string # A descriptive string that you create to describe the resource. It can be up to 64 characters long.
  --private-key: string # [APN only] The URL-encoded representation of the private key. Strip everything outside of the headers, e.g. `-----BEGIN RSA PRIVATE KEY-----MIIEpQIBAAKCAQEAuyf/lNrH9ck8DmNyo3fGgvCI1l9s+cmBY3WIz+cUDqmxiieR\n.-----END RSA PRIVATE KEY-----`
  --sandbox: oneof<nothing, bool> # [APN only] Whether to send the credential to sandbox APNs. Can be `true` to send to sandbox APNs or `false` to send to production.
  --secret: string # [FCM only] The `Server key` of your project from Firebase console under Settings / Cloud messaging.
  type: string@type-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Credentials"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: ApiKey, var: api_key}, {name: Certificate, var: certificate}, {name: FriendlyName, var: friendly_name}, {name: PrivateKey, var: private_key}, {name: Sandbox, var: sandbox}, {name: Secret, var: secret}, {name: Type, var: type}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://notify.twilio.com"
    auth: basic
  } {
    api_key: $api_key, certificate: $certificate, friendly_name: $friendly_name, private_key: $private_key, sandbox: $sandbox, secret: $secret, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/Credentials/{Sid}
#
# operationId: DeleteCredential
export def "delete-credential" [
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
    path: "/v1/Credentials/{Sid}"
    path_params: [{name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://notify.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Credentials/{Sid}
#
# Returns: record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sandbox: string, sid: string, type: string, url: string>
# operationId: FetchCredential
export def "fetch-credential" [
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
    path: "/v1/Credentials/{Sid}"
    path_params: [{name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://notify.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Credentials/{Sid}
#
# Returns: record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sandbox: string, sid: string, type: string, url: string>
# operationId: UpdateCredential
export def "update-credential" [
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
  --api-key: string # [GCM only] The `Server key` of your project from Firebase console under Settings / Cloud messaging.
  --certificate: string # [APN only] The URL-encoded representation of the certificate. Strip everything outside of the headers, e.g. `-----BEGIN CERTIFICATE-----MIIFnTCCBIWgAwIBAgIIAjy9H849+E8wDQYJKoZIhvcNAQEFBQAwgZYxCzAJBgNV.....A==-----END CERTIFICATE-----`
  --friendly-name: string # A descriptive string that you create to describe the resource. It can be up to 64 characters long.
  --private-key: string # [APN only] The URL-encoded representation of the private key. Strip everything outside of the headers, e.g. `-----BEGIN RSA PRIVATE KEY-----MIIEpQIBAAKCAQEAuyf/lNrH9ck8DmNyo3fGgvCI1l9s+cmBY3WIz+cUDqmxiieR\n.-----END RSA PRIVATE KEY-----`
  --sandbox: oneof<nothing, bool> # [APN only] Whether to send the credential to sandbox APNs. Can be `true` to send to sandbox APNs or `false` to send to production.
  --secret: string # [FCM only] The `Server key` of your project from Firebase console under Settings / Cloud messaging.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Credentials/{Sid}"
    path_params: [{name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: ApiKey, var: api_key}, {name: Certificate, var: certificate}, {name: FriendlyName, var: friendly_name}, {name: PrivateKey, var: private_key}, {name: Sandbox, var: sandbox}, {name: Secret, var: secret}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://notify.twilio.com"
    auth: basic
  } {
    sid: $sid, api_key: $api_key, certificate: $certificate, friendly_name: $friendly_name, private_key: $private_key, sandbox: $sandbox, secret: $secret
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Services
#
# Returns: record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, services: table<account_sid: string, alexa_skill_id: string, apn_credential_sid: string, date_created: string, date_updated: string, default_alexa_notification_protocol_version: string, default_apn_notification_protocol_version: string, default_fcm_notification_protocol_version: string, default_gcm_notification_protocol_version: string, delivery_callback_enabled: bool, delivery_callback_url: string, facebook_messenger_page_id: string, fcm_credential_sid: string, friendly_name: string, gcm_credential_sid: string, links: record, log_enabled: bool, messaging_service_sid: string, sid: string, url: string>>
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
  --friendly-name: string # The string that identifies the Service resources to read.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/Services"
    query: [{name: FriendlyName, var: friendly_name}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://notify.twilio.com"
    auth: basic
  } {
    friendly_name: $friendly_name, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Services
#
# Returns: record<account_sid: string, alexa_skill_id: string, apn_credential_sid: string, date_created: string, date_updated: string, default_alexa_notification_protocol_version: string, default_apn_notification_protocol_version: string, default_fcm_notification_protocol_version: string, default_gcm_notification_protocol_version: string, delivery_callback_enabled: bool, delivery_callback_url: string, facebook_messenger_page_id: string, fcm_credential_sid: string, friendly_name: string, gcm_credential_sid: string, links: record, log_enabled: bool, messaging_service_sid: string, sid: string, url: string>
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
  --alexa-skill-id: string # Deprecated.
  --apn-credential-sid: string # The SID of the [Credential](https://www.twilio.com/docs/notify/api/credential-resource) to use for APN Bindings.
  --default-alexa-notification-protocol-version: string # Deprecated.
  --default-apn-notification-protocol-version: string # The protocol version to use for sending APNS notifications. Can be overridden on a Binding by Binding basis when creating a [Binding](https://www.twilio.com/docs/notify/api/binding-resource) resource.
  --default-fcm-notification-protocol-version: string # The protocol version to use for sending FCM notifications. Can be overridden on a Binding by Binding basis when creating a [Binding](https://www.twilio.com/docs/notify/api/binding-resource) resource.
  --default-gcm-notification-protocol-version: string # The protocol version to use for sending GCM notifications. Can be overridden on a Binding by Binding basis when creating a [Binding](https://www.twilio.com/docs/notify/api/binding-resource) resource.
  --delivery-callback-enabled: oneof<nothing, bool> # Callback configuration that enables delivery callbacks, default false
  --delivery-callback-url: string # URL to send delivery status callback.
  --facebook-messenger-page-id: string # Deprecated.
  --fcm-credential-sid: string # The SID of the [Credential](https://www.twilio.com/docs/notify/api/credential-resource) to use for FCM Bindings.
  --friendly-name: string # A descriptive string that you create to describe the resource. It can be up to 64 characters long.
  --gcm-credential-sid: string # The SID of the [Credential](https://www.twilio.com/docs/notify/api/credential-resource) to use for GCM Bindings.
  --log-enabled: oneof<nothing, bool> # Whether to log notifications. Can be: `true` or `false` and the default is `true`.
  --messaging-service-sid: string # The SID of the [Messaging Service](https://www.twilio.com/docs/sms/send-messages#messaging-services) to use for SMS Bindings. This parameter must be set in order to send SMS notifications.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Services"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: AlexaSkillId, var: alexa_skill_id}, {name: ApnCredentialSid, var: apn_credential_sid}, {name: DefaultAlexaNotificationProtocolVersion, var: default_alexa_notification_protocol_version}, {name: DefaultApnNotificationProtocolVersion, var: default_apn_notification_protocol_version}, {name: DefaultFcmNotificationProtocolVersion, var: default_fcm_notification_protocol_version}, {name: DefaultGcmNotificationProtocolVersion, var: default_gcm_notification_protocol_version}, {name: DeliveryCallbackEnabled, var: delivery_callback_enabled}, {name: DeliveryCallbackUrl, var: delivery_callback_url}, {name: FacebookMessengerPageId, var: facebook_messenger_page_id}, {name: FcmCredentialSid, var: fcm_credential_sid}, {name: FriendlyName, var: friendly_name}, {name: GcmCredentialSid, var: gcm_credential_sid}, {name: LogEnabled, var: log_enabled}, {name: MessagingServiceSid, var: messaging_service_sid}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://notify.twilio.com"
    auth: basic
  } {
    alexa_skill_id: $alexa_skill_id, apn_credential_sid: $apn_credential_sid, default_alexa_notification_protocol_version: $default_alexa_notification_protocol_version, default_apn_notification_protocol_version: $default_apn_notification_protocol_version, default_fcm_notification_protocol_version: $default_fcm_notification_protocol_version, default_gcm_notification_protocol_version: $default_gcm_notification_protocol_version, delivery_callback_enabled: $delivery_callback_enabled, delivery_callback_url: $delivery_callback_url, facebook_messenger_page_id: $facebook_messenger_page_id, fcm_credential_sid: $fcm_credential_sid, friendly_name: $friendly_name, gcm_credential_sid: $gcm_credential_sid, log_enabled: $log_enabled, messaging_service_sid: $messaging_service_sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Services/{ServiceSid}/Bindings
#
# Returns: record<bindings: table<account_sid: string, address: string, binding_type: string, credential_sid: string, date_created: string, date_updated: string, endpoint: string, identity: string, links: record, notification_protocol_version: string, service_sid: string, sid: string, tags: list, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListBinding
export def "list-binding" [
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
  --start-date: string # Only include usage that has occurred on or after this date. Specify the date in GMT and format as `YYYY-MM-DD`. (format: date)
  --end-date: string # Only include usage that occurred on or before this date. Specify the date in GMT and format as `YYYY-MM-DD`. (format: date)
  --identity: list<string> # The [User](https://www.twilio.com/docs/chat/rest/user-resource)'s `identity` value of the resources to read.
  --tag: list<string> # Only list Bindings that have all of the specified Tags. The following implicit tags are available: `all`, `apn`, `fcm`, `gcm`, `sms`, `facebook-messenger`. Up to 5 tags are allowed.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/Services/{ServiceSid}/Bindings"
    path_params: [{name: ServiceSid, var: service_sid}]
    query: [{name: StartDate, var: start_date}, {name: EndDate, var: end_date}, {name: Identity, var: identity, style: multi}, {name: Tag, var: tag, style: multi}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://notify.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, start_date: $start_date, end_date: $end_date, identity: $identity, tag: $tag, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Services/{ServiceSid}/Bindings
#
# Returns: record<account_sid: string, address: string, binding_type: string, credential_sid: string, date_created: string, date_updated: string, endpoint: string, identity: string, links: record, notification_protocol_version: string, service_sid: string, sid: string, tags: list<string>, url: string>
# operationId: CreateBinding
export def "create-binding" [
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
  address: string # The channel-specific address. For APNS, the device token. For FCM and GCM, the registration token. For SMS, a phone number in E.164 format. For Facebook Messenger, the Messenger ID of the user or a phone number in E.164 format.
  binding_type: string@binding-type-completer
  --credential-sid: string # The SID of the [Credential](https://www.twilio.com/docs/notify/api/credential-resource) resource to be used to send notifications to this Binding. If present, this overrides the Credential specified in the Service resource. Applies to only `apn`, `fcm`, and `gcm` type Bindings.
  --endpoint: string # Deprecated.
  identity: string # The `identity` value that uniquely identifies the new resource's [User](https://www.twilio.com/docs/chat/rest/user-resource) within the [Service](https://www.twilio.com/docs/notify/api/service-resource). Up to 20 Bindings can be created for the same Identity in a given Service.
  --notification-protocol-version: string # The protocol version to use to send the notification. This defaults to the value of `default_xxxx_notification_protocol_version` for the protocol in the [Service](https://www.twilio.com/docs/notify/api/service-resource). The current version is `"3"` for `apn`, `fcm`, and `gcm` type Bindings. The parameter is not applicable to `sms` and `facebook-messenger` type Bindings as the data format is fixed.
  --tag: list<string> # A tag that can be used to select the Bindings to notify. Repeat this parameter to specify more than one tag, up to a total of 20 tags.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Services/{ServiceSid}/Bindings"
    path_params: [{name: ServiceSid, var: service_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Address, var: address}, {name: BindingType, var: binding_type}, {name: CredentialSid, var: credential_sid}, {name: Endpoint, var: endpoint}, {name: Identity, var: identity}, {name: NotificationProtocolVersion, var: notification_protocol_version}, {name: Tag, var: tag}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://notify.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, address: $address, binding_type: $binding_type, credential_sid: $credential_sid, endpoint: $endpoint, identity: $identity, notification_protocol_version: $notification_protocol_version, tag: $tag
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/Services/{ServiceSid}/Bindings/{Sid}
#
# operationId: DeleteBinding
export def "delete-binding" [
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
    path: "/v1/Services/{ServiceSid}/Bindings/{Sid}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://notify.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Services/{ServiceSid}/Bindings/{Sid}
#
# Returns: record<account_sid: string, address: string, binding_type: string, credential_sid: string, date_created: string, date_updated: string, endpoint: string, identity: string, links: record, notification_protocol_version: string, service_sid: string, sid: string, tags: list<string>, url: string>
# operationId: FetchBinding
export def "fetch-binding" [
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
    path: "/v1/Services/{ServiceSid}/Bindings/{Sid}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://notify.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Services/{ServiceSid}/Notifications
#
# Returns: record<account_sid: string, action: string, alexa: any, apn: any, body: string, data: any, date_created: string, facebook_messenger: any, fcm: any, gcm: any, identities: list<string>, priority: string, segments: list<string>, service_sid: string, sid: string, sms: any, sound: string, tags: list<string>, title: string, ttl: int>
# operationId: CreateNotification
export def "create-notification" [
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
  --action: string # The actions to display for the notification. For APNS, translates to the `aps.category` value. For GCM, translates to the `data.twi_action` value. For SMS, this parameter is not supported and is omitted from deliveries to those channels.
  --alexa: any # Deprecated.
  --apn: any # The APNS-specific payload that overrides corresponding attributes in the generic payload for APNS Bindings. This property maps to the APNS `Payload` item, therefore the `aps` key must be used to change standard attributes. Adds custom key-value pairs to the root of the dictionary. See the [APNS documentation](https://developer.apple.com/library/content/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/CommunicatingwithAPNs.html) for more details. We reserve keys that start with `twi_` for future use. Custom keys that start with `twi_` are not allowed.
  --body: string # The notification text. For FCM and GCM, translates to `data.twi_body`. For APNS, translates to `aps.alert.body`. For SMS, translates to `body`. SMS requires either this `body` value, or `media_urls` attribute defined in the `sms` parameter of the notification.
  --data: any # The custom key-value pairs of the notification's payload. For FCM and GCM, this value translates to `data` in the FCM and GCM payloads. FCM and GCM [reserve certain keys](https://firebase.google.com/docs/cloud-messaging/http-server-ref) that cannot be used in those channels. For APNS, attributes of `data` are inserted into the APNS payload as custom properties outside of the `aps` dictionary. In all channels, we reserve keys that start with `twi_` for future use. Custom keys that start with `twi_` are not allowed and are rejected as 400 Bad request with no delivery attempted. For SMS, this parameter is not supported and is omitted from deliveries to those channels.
  --delivery-callback-url: string # URL to send webhooks.
  --facebook-messenger: any # Deprecated.
  --fcm: any # The FCM-specific payload that overrides corresponding attributes in the generic payload for FCM Bindings. This property maps to the root JSON dictionary. See the [FCM documentation](https://firebase.google.com/docs/cloud-messaging/http-server-ref#downstream) for more details. Target parameters `to`, `registration_ids`, `condition`, and `notification_key` are not allowed in this parameter. We reserve keys that start with `twi_` for future use. Custom keys that start with `twi_` are not allowed. FCM also [reserves certain keys](https://firebase.google.com/docs/cloud-messaging/http-server-ref), which cannot be used in that channel.
  --gcm: any # The GCM-specific payload that overrides corresponding attributes in the generic payload for GCM Bindings. This property maps to the root JSON dictionary. See the [GCM documentation](https://firebase.google.com/docs/cloud-messaging/http-server-ref) for more details. Target parameters `to`, `registration_ids`, and `notification_key` are not allowed. We reserve keys that start with `twi_` for future use. Custom keys that start with `twi_` are not allowed. GCM also [reserves certain keys](https://firebase.google.com/docs/cloud-messaging/http-server-ref).
  --identity: list<string> # The `identity` value that uniquely identifies the new resource's [User](https://www.twilio.com/docs/chat/rest/user-resource) within the [Service](https://www.twilio.com/docs/notify/api/service-resource). Delivery will be attempted only to Bindings with an Identity in this list. No more than 20 items are allowed in this list.
  --priority: string@priority-completer
  --segment: list<string> # The Segment resource is deprecated. Use the `tag` parameter, instead.
  --sms: any # The SMS-specific payload that overrides corresponding attributes in the generic payload for SMS Bindings. Each attribute in this value maps to the corresponding `form` parameter of the Twilio [Message](https://www.twilio.com/docs/sms/send-messages) resource. These parameters of the Message resource are supported in snake case format: `body`, `media_urls`, `status_callback`, and `max_price`. The `status_callback` parameter overrides the corresponding parameter in the messaging service, if configured. The `media_urls` property expects a JSON array.
  --sound: string # The name of the sound to be played for the notification. For FCM and GCM, this Translates to `data.twi_sound`. For APNS, this translates to `aps.sound`. SMS does not support this property.
  --tag: list<string> # A tag that selects the Bindings to notify. Repeat this parameter to specify more than one tag, up to a total of 5 tags. The implicit tag `all` is available to notify all Bindings in a Service instance. Similarly, the implicit tags `apn`, `fcm`, `gcm`, `sms` and `facebook-messenger` are available to notify all Bindings in a specific channel.
  --title: string # The notification title. For FCM and GCM, this translates to the `data.twi_title` value. For APNS, this translates to the `aps.alert.title` value. SMS does not support this property. This field is not visible on iOS phones and tablets but appears on Apple Watch and Android devices.
  --to-binding: list<string> # The destination address specified as a JSON string. Multiple `to_binding` parameters can be included but the total size of the request entity should not exceed 1MB. This is typically sufficient for 10,000 phone numbers.
  --ttl: int # How long, in seconds, the notification is valid. Can be an integer between 0 and 2,419,200, which is 4 weeks, the default and the maximum supported time to live (TTL). Delivery should be attempted if the device is offline until the TTL elapses. Zero means that the notification delivery is attempted immediately, only once, and is not stored for future delivery. SMS does not support this property.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Services/{ServiceSid}/Notifications"
    path_params: [{name: ServiceSid, var: service_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Action, var: action}, {name: Alexa, var: alexa}, {name: Apn, var: apn}, {name: Body, var: body}, {name: Data, var: data}, {name: DeliveryCallbackUrl, var: delivery_callback_url}, {name: FacebookMessenger, var: facebook_messenger}, {name: Fcm, var: fcm}, {name: Gcm, var: gcm}, {name: Identity, var: identity}, {name: Priority, var: priority}, {name: Segment, var: segment}, {name: Sms, var: sms}, {name: Sound, var: sound}, {name: Tag, var: tag}, {name: Title, var: title}, {name: ToBinding, var: to_binding}, {name: Ttl, var: ttl}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://notify.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, action: $action, alexa: $alexa, apn: $apn, body: $body, data: $data, delivery_callback_url: $delivery_callback_url, facebook_messenger: $facebook_messenger, fcm: $fcm, gcm: $gcm, identity: $identity, priority: $priority, segment: $segment, sms: $sms, sound: $sound, tag: $tag, title: $title, to_binding: $to_binding, ttl: $ttl
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/Services/{Sid}
#
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
    path: "/v1/Services/{Sid}"
    path_params: [{name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://notify.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Services/{Sid}
#
# Returns: record<account_sid: string, alexa_skill_id: string, apn_credential_sid: string, date_created: string, date_updated: string, default_alexa_notification_protocol_version: string, default_apn_notification_protocol_version: string, default_fcm_notification_protocol_version: string, default_gcm_notification_protocol_version: string, delivery_callback_enabled: bool, delivery_callback_url: string, facebook_messenger_page_id: string, fcm_credential_sid: string, friendly_name: string, gcm_credential_sid: string, links: record, log_enabled: bool, messaging_service_sid: string, sid: string, url: string>
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
    path: "/v1/Services/{Sid}"
    path_params: [{name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://notify.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Services/{Sid}
#
# Returns: record<account_sid: string, alexa_skill_id: string, apn_credential_sid: string, date_created: string, date_updated: string, default_alexa_notification_protocol_version: string, default_apn_notification_protocol_version: string, default_fcm_notification_protocol_version: string, default_gcm_notification_protocol_version: string, delivery_callback_enabled: bool, delivery_callback_url: string, facebook_messenger_page_id: string, fcm_credential_sid: string, friendly_name: string, gcm_credential_sid: string, links: record, log_enabled: bool, messaging_service_sid: string, sid: string, url: string>
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
  --alexa-skill-id: string # Deprecated.
  --apn-credential-sid: string # The SID of the [Credential](https://www.twilio.com/docs/notify/api/credential-resource) to use for APN Bindings.
  --default-alexa-notification-protocol-version: string # Deprecated.
  --default-apn-notification-protocol-version: string # The protocol version to use for sending APNS notifications. Can be overridden on a Binding by Binding basis when creating a [Binding](https://www.twilio.com/docs/notify/api/binding-resource) resource.
  --default-fcm-notification-protocol-version: string # The protocol version to use for sending FCM notifications. Can be overridden on a Binding by Binding basis when creating a [Binding](https://www.twilio.com/docs/notify/api/binding-resource) resource.
  --default-gcm-notification-protocol-version: string # The protocol version to use for sending GCM notifications. Can be overridden on a Binding by Binding basis when creating a [Binding](https://www.twilio.com/docs/notify/api/binding-resource) resource.
  --delivery-callback-enabled: oneof<nothing, bool> # Callback configuration that enables delivery callbacks, default false
  --delivery-callback-url: string # URL to send delivery status callback.
  --facebook-messenger-page-id: string # Deprecated.
  --fcm-credential-sid: string # The SID of the [Credential](https://www.twilio.com/docs/notify/api/credential-resource) to use for FCM Bindings.
  --friendly-name: string # A descriptive string that you create to describe the resource. It can be up to 64 characters long.
  --gcm-credential-sid: string # The SID of the [Credential](https://www.twilio.com/docs/notify/api/credential-resource) to use for GCM Bindings.
  --log-enabled: oneof<nothing, bool> # Whether to log notifications. Can be: `true` or `false` and the default is `true`.
  --messaging-service-sid: string # The SID of the [Messaging Service](https://www.twilio.com/docs/sms/send-messages#messaging-services) to use for SMS Bindings. This parameter must be set in order to send SMS notifications.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Services/{Sid}"
    path_params: [{name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: AlexaSkillId, var: alexa_skill_id}, {name: ApnCredentialSid, var: apn_credential_sid}, {name: DefaultAlexaNotificationProtocolVersion, var: default_alexa_notification_protocol_version}, {name: DefaultApnNotificationProtocolVersion, var: default_apn_notification_protocol_version}, {name: DefaultFcmNotificationProtocolVersion, var: default_fcm_notification_protocol_version}, {name: DefaultGcmNotificationProtocolVersion, var: default_gcm_notification_protocol_version}, {name: DeliveryCallbackEnabled, var: delivery_callback_enabled}, {name: DeliveryCallbackUrl, var: delivery_callback_url}, {name: FacebookMessengerPageId, var: facebook_messenger_page_id}, {name: FcmCredentialSid, var: fcm_credential_sid}, {name: FriendlyName, var: friendly_name}, {name: GcmCredentialSid, var: gcm_credential_sid}, {name: LogEnabled, var: log_enabled}, {name: MessagingServiceSid, var: messaging_service_sid}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://notify.twilio.com"
    auth: basic
  } {
    sid: $sid, alexa_skill_id: $alexa_skill_id, apn_credential_sid: $apn_credential_sid, default_alexa_notification_protocol_version: $default_alexa_notification_protocol_version, default_apn_notification_protocol_version: $default_apn_notification_protocol_version, default_fcm_notification_protocol_version: $default_fcm_notification_protocol_version, default_gcm_notification_protocol_version: $default_gcm_notification_protocol_version, delivery_callback_enabled: $delivery_callback_enabled, delivery_callback_url: $delivery_callback_url, facebook_messenger_page_id: $facebook_messenger_page_id, fcm_credential_sid: $fcm_credential_sid, friendly_name: $friendly_name, gcm_credential_sid: $gcm_credential_sid, log_enabled: $log_enabled, messaging_service_sid: $messaging_service_sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
