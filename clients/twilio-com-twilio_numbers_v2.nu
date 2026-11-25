# Auto-generated client for Twilio - Numbers v1.42.0
# Source: https://api.apis.guru/v2/specs/twilio.com/twilio_numbers_v2/1.42.0/openapi.json
# Auth: --token flag or $env.TWILIO_NUMBERS_TOKEN

const CLIENT = {
  base_url: "https://numbers.twilio.com"
  token_env_var: "TWILIO_NUMBERS_TOKEN"
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

def base-url-completer [] { ["https://numbers.twilio.com"] }
def auth-scheme-completer [] { ["basic" "basic-credentials"] }

# Completers for enum parameters
def status-completer [] { ["draft" "in-review" "pending-review" "provisionally-approved" "twilio-approved" "twilio-rejected"] }
def sort-by-completer [] { ["date-updated" "valid-until"] }
def sort-direction-completer [] { ["ASC" "DESC"] }
def end-user-type-completer [] { ["business" "individual"] }
def type-completer [] { ["business" "individual"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    list-bundle: "record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, results: table<account_sid: string, date_created: string, date_updated: string, email: string, friendly_name: string, links: record, regulation_sid: string, sid: string, status: string, status_callback: string, url: string, valid_until: string>>"
    create-bundle: "record<account_sid: string, date_created: string, date_updated: string, email: string, friendly_name: string, links: record, regulation_sid: string, sid: string, status: string, status_callback: string, url: string, valid_until: string>"
    list-bundle-copy: "record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, results: table<account_sid: string, date_created: string, date_updated: string, email: string, friendly_name: string, regulation_sid: string, sid: string, status: string, status_callback: string, valid_until: string>>"
    create-bundle-copy: "record<account_sid: string, date_created: string, date_updated: string, email: string, friendly_name: string, regulation_sid: string, sid: string, status: string, status_callback: string, valid_until: string>"
    list-evaluation: "record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, results: table<account_sid: string, bundle_sid: string, date_created: string, regulation_sid: string, results: list, sid: string, status: string, url: string>>"
    create-evaluation: "record<account_sid: string, bundle_sid: string, date_created: string, regulation_sid: string, results: list<any>, sid: string, status: string, url: string>"
    fetch-evaluation: "record<account_sid: string, bundle_sid: string, date_created: string, regulation_sid: string, results: list<any>, sid: string, status: string, url: string>"
    list-item-assignment: "record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, results: table<account_sid: string, bundle_sid: string, date_created: string, object_sid: string, sid: string, url: string>>"
    create-item-assignment: "record<account_sid: string, bundle_sid: string, date_created: string, object_sid: string, sid: string, url: string>"
    fetch-item-assignment: "record<account_sid: string, bundle_sid: string, date_created: string, object_sid: string, sid: string, url: string>"
    create-replace-items: "record<account_sid: string, date_created: string, date_updated: string, email: string, friendly_name: string, regulation_sid: string, sid: string, status: string, status_callback: string, valid_until: string>"
    fetch-bundle: "record<account_sid: string, date_created: string, date_updated: string, email: string, friendly_name: string, links: record, regulation_sid: string, sid: string, status: string, status_callback: string, url: string, valid_until: string>"
    update-bundle: "record<account_sid: string, date_created: string, date_updated: string, email: string, friendly_name: string, links: record, regulation_sid: string, sid: string, status: string, status_callback: string, url: string, valid_until: string>"
    list-end-user-type: "record<end_user_types: table<fields: list, friendly_name: string, machine_name: string, sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    fetch-end-user-type: "record<fields: list<any>, friendly_name: string, machine_name: string, sid: string, url: string>"
    list-end-user: "record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, results: table<account_sid: string, attributes: any, date_created: string, date_updated: string, friendly_name: string, sid: string, type: string, url: string>>"
    create-end-user: "record<account_sid: string, attributes: any, date_created: string, date_updated: string, friendly_name: string, sid: string, type: string, url: string>"
    fetch-end-user: "record<account_sid: string, attributes: any, date_created: string, date_updated: string, friendly_name: string, sid: string, type: string, url: string>"
    update-end-user: "record<account_sid: string, attributes: any, date_created: string, date_updated: string, friendly_name: string, sid: string, type: string, url: string>"
    list-regulation: "record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, results: table<end_user_type: string, friendly_name: string, iso_country: string, number_type: string, requirements: any, sid: string, url: string>>"
    fetch-regulation: "record<end_user_type: string, friendly_name: string, iso_country: string, number_type: string, requirements: any, sid: string, url: string>"
    list-supporting-document-type: "record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, supporting_document_types: table<fields: list, friendly_name: string, machine_name: string, sid: string, url: string>>"
    fetch-supporting-document-type: "record<fields: list<any>, friendly_name: string, machine_name: string, sid: string, url: string>"
    list-supporting-document: "record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, results: table<account_sid: string, attributes: any, date_created: string, date_updated: string, failure_reason: string, friendly_name: string, mime_type: string, sid: string, status: string, type: string, url: string>>"
    create-supporting-document: "record<account_sid: string, attributes: any, date_created: string, date_updated: string, failure_reason: string, friendly_name: string, mime_type: string, sid: string, status: string, type: string, url: string>"
    fetch-supporting-document: "record<account_sid: string, attributes: any, date_created: string, date_updated: string, failure_reason: string, friendly_name: string, mime_type: string, sid: string, status: string, type: string, url: string>"
    update-supporting-document: "record<account_sid: string, attributes: any, date_created: string, date_updated: string, failure_reason: string, friendly_name: string, mime_type: string, sid: string, status: string, type: string, url: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["list-bundle" "create-bundle" "list-bundle-copy" "create-bundle-copy" "list-evaluation" "create-evaluation" "fetch-evaluation" "list-item-assignment" "create-item-assignment" "delete-item-assignment" "fetch-item-assignment" "create-replace-items" "delete-bundle" "fetch-bundle" "update-bundle" "list-end-user-type" "fetch-end-user-type" "list-end-user" "create-end-user" "delete-end-user" "fetch-end-user" "update-end-user" "list-regulation" "fetch-regulation" "list-supporting-document-type" "fetch-supporting-document-type" "list-supporting-document" "create-supporting-document" "delete-supporting-document" "fetch-supporting-document" "update-supporting-document" "commands"] | sort) } | get name | first)
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

# Retrieve a list of all Bundles for an account.
#
# GET /v2/RegulatoryCompliance/Bundles
# Returns: record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, results: table<account_sid: string, date_created: string, date_updated: string, email: string, friendly_name: string, links: record, regulation_sid: string, sid: string, status: string, status_callback: string, url: string, valid_until: string>>
# operationId: ListBundle
export def "list-bundle" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer # The verification status of the Bundle resource. Please refer to [Bundle Statuses](https://www.twilio.com/docs/phone-numbers/regulatory/api/bundles#bundle-statuses) for more details.
  --friendly-name: string # The string that you assigned to describe the resource. The column can contain 255 variable characters.
  --regulation-sid: string # The unique string of a [Regulation resource](https://www.twilio.com/docs/phone-numbers/regulatory/api/regulations) that is associated to the Bundle resource.
  --iso-country: string # The 2-digit [ISO country code](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2) of the Bundle's phone number country ownership request.
  --number-type: string # The type of phone number of the Bundle's ownership request. Can be `local`, `mobile`, `national`, or `tollfree`.
  --has-valid-until-date: oneof<nothing, bool> # Indicates that the Bundle is a valid Bundle until a specified expiration date.
  --sort-by: string@sort-by-completer # Can be `valid-until` or `date-updated`. Defaults to `date-created`.
  --sort-direction: string@sort-direction-completer # Default is `DESC`. Can be `ASC` or `DESC`.
  --valid-until-date: string # Date to filter Bundles having their `valid_until_date` before or after the specified date. Can be `ValidUntilDate>=` or `ValidUntilDate<=`. Both can be used in conjunction as well. [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) is the acceptable date format. (format: date-time)
  --qp-valid-until-date: string # Date to filter Bundles having their `valid_until_date` before or after the specified date. Can be `ValidUntilDate>=` or `ValidUntilDate<=`. Both can be used in conjunction as well. [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) is the acceptable date format. (format: date-time) (spec name: ValidUntilDate<)
  --qp-valid-until-date-2: string # Date to filter Bundles having their `valid_until_date` before or after the specified date. Can be `ValidUntilDate>=` or `ValidUntilDate<=`. Both can be used in conjunction as well. [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) is the acceptable date format. (format: date-time) (spec name: ValidUntilDate>)
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/RegulatoryCompliance/Bundles"
    query: [{name: Status, var: status}, {name: FriendlyName, var: friendly_name}, {name: RegulationSid, var: regulation_sid}, {name: IsoCountry, var: iso_country}, {name: NumberType, var: number_type}, {name: HasValidUntilDate, var: has_valid_until_date}, {name: SortBy, var: sort_by}, {name: SortDirection, var: sort_direction}, {name: ValidUntilDate, var: valid_until_date}, {name: "ValidUntilDate<", var: qp_valid_until_date}, {name: "ValidUntilDate>", var: qp_valid_until_date_2}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://numbers.twilio.com"
    auth: basic
  } {
    status: $status, friendly_name: $friendly_name, regulation_sid: $regulation_sid, iso_country: $iso_country, number_type: $number_type, has_valid_until_date: $has_valid_until_date, sort_by: $sort_by, sort_direction: $sort_direction, valid_until_date: $valid_until_date, qp_valid_until_date: $qp_valid_until_date, qp_valid_until_date_2: $qp_valid_until_date_2, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new Bundle.
#
# POST /v2/RegulatoryCompliance/Bundles
# Returns: record<account_sid: string, date_created: string, date_updated: string, email: string, friendly_name: string, links: record, regulation_sid: string, sid: string, status: string, status_callback: string, url: string, valid_until: string>
# operationId: CreateBundle
export def "create-bundle" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # The email address that will receive updates when the Bundle resource changes status.
  --end-user-type: string@end-user-type-completer
  friendly_name: string # The string that you assigned to describe the resource.
  --iso-country: string # The [ISO country code](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2) of the Bundle's phone number country ownership request.
  --number-type: string # The type of phone number of the Bundle's ownership request. Can be `local`, `mobile`, `national`, or `toll free`.
  --regulation-sid: string # The unique string of a regulation that is associated to the Bundle resource.
  --status-callback: string # The URL we call to inform your application of status changes. (format: uri)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/RegulatoryCompliance/Bundles"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Email, var: email}, {name: EndUserType, var: end_user_type}, {name: FriendlyName, var: friendly_name}, {name: IsoCountry, var: iso_country}, {name: NumberType, var: number_type}, {name: RegulationSid, var: regulation_sid}, {name: StatusCallback, var: status_callback}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://numbers.twilio.com"
    auth: basic
  } {
    email: $email, end_user_type: $end_user_type, friendly_name: $friendly_name, iso_country: $iso_country, number_type: $number_type, regulation_sid: $regulation_sid, status_callback: $status_callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of all Bundles Copies for a Bundle.
#
# GET /v2/RegulatoryCompliance/Bundles/{BundleSid}/Copies
# Returns: record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, results: table<account_sid: string, date_created: string, date_updated: string, email: string, friendly_name: string, regulation_sid: string, sid: string, status: string, status_callback: string, valid_until: string>>
# operationId: ListBundleCopy
export def "list-bundle-copy" [
  bundle_sid: string
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
    path: "/v2/RegulatoryCompliance/Bundles/{BundleSid}/Copies"
    path_params: [{name: BundleSid, var: bundle_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://numbers.twilio.com"
    auth: basic
  } {
    bundle_sid: $bundle_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new copy of a Bundle. It will internally create copies of all the bundle items (identities and documents) of the original bundle
#
# POST /v2/RegulatoryCompliance/Bundles/{BundleSid}/Copies
# Returns: record<account_sid: string, date_created: string, date_updated: string, email: string, friendly_name: string, regulation_sid: string, sid: string, status: string, status_callback: string, valid_until: string>
# operationId: CreateBundleCopy
export def "create-bundle-copy" [
  bundle_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --friendly-name: string # The string that you assigned to describe the copied bundle.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/RegulatoryCompliance/Bundles/{BundleSid}/Copies"
    path_params: [{name: BundleSid, var: bundle_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: FriendlyName, var: friendly_name}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://numbers.twilio.com"
    auth: basic
  } {
    bundle_sid: $bundle_sid, friendly_name: $friendly_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of Evaluations associated to the Bundle resource.
#
# GET /v2/RegulatoryCompliance/Bundles/{BundleSid}/Evaluations
# Returns: record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, results: table<account_sid: string, bundle_sid: string, date_created: string, regulation_sid: string, results: list, sid: string, status: string, url: string>>
# operationId: ListEvaluation
export def "list-evaluation" [
  bundle_sid: string
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
    path: "/v2/RegulatoryCompliance/Bundles/{BundleSid}/Evaluations"
    path_params: [{name: BundleSid, var: bundle_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://numbers.twilio.com"
    auth: basic
  } {
    bundle_sid: $bundle_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an evaluation for a bundle
#
# POST /v2/RegulatoryCompliance/Bundles/{BundleSid}/Evaluations
# Returns: record<account_sid: string, bundle_sid: string, date_created: string, regulation_sid: string, results: list<any>, sid: string, status: string, url: string>
# operationId: CreateEvaluation
export def "create-evaluation" [
  bundle_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/v2/RegulatoryCompliance/Bundles/{BundleSid}/Evaluations"
    path_params: [{name: BundleSid, var: bundle_sid}]
    accept: ["application/json"]
    ok: [201]
    base_url: "https://numbers.twilio.com"
    auth: basic
  } {
    bundle_sid: $bundle_sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch specific Evaluation Instance.
#
# GET /v2/RegulatoryCompliance/Bundles/{BundleSid}/Evaluations/{Sid}
# Returns: record<account_sid: string, bundle_sid: string, date_created: string, regulation_sid: string, results: list<any>, sid: string, status: string, url: string>
# operationId: FetchEvaluation
export def "fetch-evaluation" [
  bundle_sid: string
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
    path: "/v2/RegulatoryCompliance/Bundles/{BundleSid}/Evaluations/{Sid}"
    path_params: [{name: BundleSid, var: bundle_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://numbers.twilio.com"
    auth: basic
  } {
    bundle_sid: $bundle_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of all Assigned Items for an account.
#
# GET /v2/RegulatoryCompliance/Bundles/{BundleSid}/ItemAssignments
# Returns: record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, results: table<account_sid: string, bundle_sid: string, date_created: string, object_sid: string, sid: string, url: string>>
# operationId: ListItemAssignment
export def "list-item-assignment" [
  bundle_sid: string
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
    path: "/v2/RegulatoryCompliance/Bundles/{BundleSid}/ItemAssignments"
    path_params: [{name: BundleSid, var: bundle_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://numbers.twilio.com"
    auth: basic
  } {
    bundle_sid: $bundle_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new Assigned Item.
#
# POST /v2/RegulatoryCompliance/Bundles/{BundleSid}/ItemAssignments
# Returns: record<account_sid: string, bundle_sid: string, date_created: string, object_sid: string, sid: string, url: string>
# operationId: CreateItemAssignment
export def "create-item-assignment" [
  bundle_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  object_sid: string # The SID of an object bag that holds information of the different items.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/RegulatoryCompliance/Bundles/{BundleSid}/ItemAssignments"
    path_params: [{name: BundleSid, var: bundle_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: ObjectSid, var: object_sid}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://numbers.twilio.com"
    auth: basic
  } {
    bundle_sid: $bundle_sid, object_sid: $object_sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove an Assignment Item Instance.
#
# DELETE /v2/RegulatoryCompliance/Bundles/{BundleSid}/ItemAssignments/{Sid}
# operationId: DeleteItemAssignment
export def "delete-item-assignment" [
  bundle_sid: string
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
    path: "/v2/RegulatoryCompliance/Bundles/{BundleSid}/ItemAssignments/{Sid}"
    path_params: [{name: BundleSid, var: bundle_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://numbers.twilio.com"
    auth: basic
  } {
    bundle_sid: $bundle_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch specific Assigned Item Instance.
#
# GET /v2/RegulatoryCompliance/Bundles/{BundleSid}/ItemAssignments/{Sid}
# Returns: record<account_sid: string, bundle_sid: string, date_created: string, object_sid: string, sid: string, url: string>
# operationId: FetchItemAssignment
export def "fetch-item-assignment" [
  bundle_sid: string
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
    path: "/v2/RegulatoryCompliance/Bundles/{BundleSid}/ItemAssignments/{Sid}"
    path_params: [{name: BundleSid, var: bundle_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://numbers.twilio.com"
    auth: basic
  } {
    bundle_sid: $bundle_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Replaces all bundle items in the target bundle (specified in the path) with all the bundle items of the source bundle (specified by the from_bundle_sid body param)
#
# POST /v2/RegulatoryCompliance/Bundles/{BundleSid}/ReplaceItems
# Returns: record<account_sid: string, date_created: string, date_updated: string, email: string, friendly_name: string, regulation_sid: string, sid: string, status: string, status_callback: string, valid_until: string>
# operationId: CreateReplaceItems
export def "create-replace-items" [
  bundle_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  from_bundle_sid: string # The source bundle sid to copy the item assignments from.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/RegulatoryCompliance/Bundles/{BundleSid}/ReplaceItems"
    path_params: [{name: BundleSid, var: bundle_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: FromBundleSid, var: from_bundle_sid}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://numbers.twilio.com"
    auth: basic
  } {
    bundle_sid: $bundle_sid, from_bundle_sid: $from_bundle_sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a specific Bundle.
#
# DELETE /v2/RegulatoryCompliance/Bundles/{Sid}
# operationId: DeleteBundle
export def "delete-bundle" [
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
    path: "/v2/RegulatoryCompliance/Bundles/{Sid}"
    path_params: [{name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://numbers.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a specific Bundle instance.
#
# GET /v2/RegulatoryCompliance/Bundles/{Sid}
# Returns: record<account_sid: string, date_created: string, date_updated: string, email: string, friendly_name: string, links: record, regulation_sid: string, sid: string, status: string, status_callback: string, url: string, valid_until: string>
# operationId: FetchBundle
export def "fetch-bundle" [
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
    path: "/v2/RegulatoryCompliance/Bundles/{Sid}"
    path_params: [{name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://numbers.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a Bundle in an account.
#
# POST /v2/RegulatoryCompliance/Bundles/{Sid}
# Returns: record<account_sid: string, date_created: string, date_updated: string, email: string, friendly_name: string, links: record, regulation_sid: string, sid: string, status: string, status_callback: string, url: string, valid_until: string>
# operationId: UpdateBundle
export def "update-bundle" [
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
  --email: string # The email address that will receive updates when the Bundle resource changes status.
  --friendly-name: string # The string that you assigned to describe the resource.
  --status: string@status-completer
  --status-callback: string # The URL we call to inform your application of status changes. (format: uri)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/RegulatoryCompliance/Bundles/{Sid}"
    path_params: [{name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Email, var: email}, {name: FriendlyName, var: friendly_name}, {name: Status, var: status}, {name: StatusCallback, var: status_callback}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://numbers.twilio.com"
    auth: basic
  } {
    sid: $sid, email: $email, friendly_name: $friendly_name, status: $status, status_callback: $status_callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of all End-User Types.
#
# GET /v2/RegulatoryCompliance/EndUserTypes
# Returns: record<end_user_types: table<fields: list, friendly_name: string, machine_name: string, sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListEndUserType
export def "list-end-user-type" [
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
    path: "/v2/RegulatoryCompliance/EndUserTypes"
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://numbers.twilio.com"
    auth: basic
  } {
    page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a specific End-User Type Instance.
#
# GET /v2/RegulatoryCompliance/EndUserTypes/{Sid}
# Returns: record<fields: list<any>, friendly_name: string, machine_name: string, sid: string, url: string>
# operationId: FetchEndUserType
export def "fetch-end-user-type" [
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
    path: "/v2/RegulatoryCompliance/EndUserTypes/{Sid}"
    path_params: [{name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://numbers.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of all End User for an account.
#
# GET /v2/RegulatoryCompliance/EndUsers
# Returns: record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, results: table<account_sid: string, attributes: any, date_created: string, date_updated: string, friendly_name: string, sid: string, type: string, url: string>>
# operationId: ListEndUser
export def "list-end-user" [
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
    path: "/v2/RegulatoryCompliance/EndUsers"
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://numbers.twilio.com"
    auth: basic
  } {
    page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new End User.
#
# POST /v2/RegulatoryCompliance/EndUsers
# Returns: record<account_sid: string, attributes: any, date_created: string, date_updated: string, friendly_name: string, sid: string, type: string, url: string>
# operationId: CreateEndUser
export def "create-end-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: any # The set of parameters that are the attributes of the End User resource which are derived End User Types.
  friendly_name: string # The string that you assigned to describe the resource.
  type: string@type-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/RegulatoryCompliance/EndUsers"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Attributes, var: attributes}, {name: FriendlyName, var: friendly_name}, {name: Type, var: type}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://numbers.twilio.com"
    auth: basic
  } {
    attributes: $attributes, friendly_name: $friendly_name, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a specific End User.
#
# DELETE /v2/RegulatoryCompliance/EndUsers/{Sid}
# operationId: DeleteEndUser
export def "delete-end-user" [
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
    path: "/v2/RegulatoryCompliance/EndUsers/{Sid}"
    path_params: [{name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://numbers.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch specific End User Instance.
#
# GET /v2/RegulatoryCompliance/EndUsers/{Sid}
# Returns: record<account_sid: string, attributes: any, date_created: string, date_updated: string, friendly_name: string, sid: string, type: string, url: string>
# operationId: FetchEndUser
export def "fetch-end-user" [
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
    path: "/v2/RegulatoryCompliance/EndUsers/{Sid}"
    path_params: [{name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://numbers.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing End User.
#
# POST /v2/RegulatoryCompliance/EndUsers/{Sid}
# Returns: record<account_sid: string, attributes: any, date_created: string, date_updated: string, friendly_name: string, sid: string, type: string, url: string>
# operationId: UpdateEndUser
export def "update-end-user" [
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
  --attributes: any # The set of parameters that are the attributes of the End User resource which are derived End User Types.
  --friendly-name: string # The string that you assigned to describe the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/RegulatoryCompliance/EndUsers/{Sid}"
    path_params: [{name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Attributes, var: attributes}, {name: FriendlyName, var: friendly_name}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://numbers.twilio.com"
    auth: basic
  } {
    sid: $sid, attributes: $attributes, friendly_name: $friendly_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of all Regulations.
#
# GET /v2/RegulatoryCompliance/Regulations
# Returns: record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, results: table<end_user_type: string, friendly_name: string, iso_country: string, number_type: string, requirements: any, sid: string, url: string>>
# operationId: ListRegulation
export def "list-regulation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --end-user-type: string@end-user-type-completer # The type of End User the regulation requires - can be `individual` or `business`.
  --iso-country: string # The ISO country code of the phone number's country.
  --number-type: string # The type of phone number that the regulatory requiremnt is restricting.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/RegulatoryCompliance/Regulations"
    query: [{name: EndUserType, var: end_user_type}, {name: IsoCountry, var: iso_country}, {name: NumberType, var: number_type}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://numbers.twilio.com"
    auth: basic
  } {
    end_user_type: $end_user_type, iso_country: $iso_country, number_type: $number_type, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch specific Regulation Instance.
#
# GET /v2/RegulatoryCompliance/Regulations/{Sid}
# Returns: record<end_user_type: string, friendly_name: string, iso_country: string, number_type: string, requirements: any, sid: string, url: string>
# operationId: FetchRegulation
export def "fetch-regulation" [
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
    path: "/v2/RegulatoryCompliance/Regulations/{Sid}"
    path_params: [{name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://numbers.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of all Supporting Document Types.
#
# GET /v2/RegulatoryCompliance/SupportingDocumentTypes
# Returns: record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, supporting_document_types: table<fields: list, friendly_name: string, machine_name: string, sid: string, url: string>>
# operationId: ListSupportingDocumentType
export def "list-supporting-document-type" [
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
    path: "/v2/RegulatoryCompliance/SupportingDocumentTypes"
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://numbers.twilio.com"
    auth: basic
  } {
    page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a specific Supporting Document Type Instance.
#
# GET /v2/RegulatoryCompliance/SupportingDocumentTypes/{Sid}
# Returns: record<fields: list<any>, friendly_name: string, machine_name: string, sid: string, url: string>
# operationId: FetchSupportingDocumentType
export def "fetch-supporting-document-type" [
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
    path: "/v2/RegulatoryCompliance/SupportingDocumentTypes/{Sid}"
    path_params: [{name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://numbers.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of all Supporting Document for an account.
#
# GET /v2/RegulatoryCompliance/SupportingDocuments
# Returns: record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, results: table<account_sid: string, attributes: any, date_created: string, date_updated: string, failure_reason: string, friendly_name: string, mime_type: string, sid: string, status: string, type: string, url: string>>
# operationId: ListSupportingDocument
export def "list-supporting-document" [
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
    path: "/v2/RegulatoryCompliance/SupportingDocuments"
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://numbers.twilio.com"
    auth: basic
  } {
    page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new Supporting Document.
#
# POST /v2/RegulatoryCompliance/SupportingDocuments
# Returns: record<account_sid: string, attributes: any, date_created: string, date_updated: string, failure_reason: string, friendly_name: string, mime_type: string, sid: string, status: string, type: string, url: string>
# operationId: CreateSupportingDocument
export def "create-supporting-document" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: any # The set of parameters that are the attributes of the Supporting Documents resource which are derived Supporting Document Types.
  friendly_name: string # The string that you assigned to describe the resource.
  type: string # The type of the Supporting Document.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/RegulatoryCompliance/SupportingDocuments"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Attributes, var: attributes}, {name: FriendlyName, var: friendly_name}, {name: Type, var: type}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://numbers.twilio.com"
    auth: basic
  } {
    attributes: $attributes, friendly_name: $friendly_name, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a specific Supporting Document.
#
# DELETE /v2/RegulatoryCompliance/SupportingDocuments/{Sid}
# operationId: DeleteSupportingDocument
export def "delete-supporting-document" [
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
    path: "/v2/RegulatoryCompliance/SupportingDocuments/{Sid}"
    path_params: [{name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://numbers.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch specific Supporting Document Instance.
#
# GET /v2/RegulatoryCompliance/SupportingDocuments/{Sid}
# Returns: record<account_sid: string, attributes: any, date_created: string, date_updated: string, failure_reason: string, friendly_name: string, mime_type: string, sid: string, status: string, type: string, url: string>
# operationId: FetchSupportingDocument
export def "fetch-supporting-document" [
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
    path: "/v2/RegulatoryCompliance/SupportingDocuments/{Sid}"
    path_params: [{name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://numbers.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing Supporting Document.
#
# POST /v2/RegulatoryCompliance/SupportingDocuments/{Sid}
# Returns: record<account_sid: string, attributes: any, date_created: string, date_updated: string, failure_reason: string, friendly_name: string, mime_type: string, sid: string, status: string, type: string, url: string>
# operationId: UpdateSupportingDocument
export def "update-supporting-document" [
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
  --attributes: any # The set of parameters that are the attributes of the Supporting Document resource which are derived Supporting Document Types.
  --friendly-name: string # The string that you assigned to describe the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/RegulatoryCompliance/SupportingDocuments/{Sid}"
    path_params: [{name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Attributes, var: attributes}, {name: FriendlyName, var: friendly_name}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://numbers.twilio.com"
    auth: basic
  } {
    sid: $sid, attributes: $attributes, friendly_name: $friendly_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
