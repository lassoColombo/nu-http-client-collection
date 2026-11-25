# Auto-generated client for Twilio - Flex v1.42.0
# Source: https://api.apis.guru/v2/specs/twilio.com/twilio_flex_v1/1.42.0/openapi.json
# Auth: --token flag or $env.TWILIO_FLEX_TOKEN

const CLIENT = {
  base_url: "https://flex-api.twilio.com"
  token_env_var: "TWILIO_FLEX_TOKEN"
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

def base-url-completer [] { ["https://flex-api.twilio.com"] }
def auth-scheme-completer [] { ["basic" "basic-credentials"] }

# Completers for enum parameters
def channel-type-completer [] { ["custom" "facebook" "line" "sms" "web" "whatsapp"] }
def integration-type-completer [] { ["external" "studio" "task"] }
def type-completer [] { ["agent" "customer" "external" "supervisor" "unknown"] }
def status-completer [] { ["closed" "wrapup"] }
def chat-status-completer [] { ["inactive"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    list-channel: "record<flex_chat_channels: table<account_sid: string, date_created: string, date_updated: string, flex_flow_sid: string, sid: string, task_sid: string, url: string, user_sid: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    create-channel: "record<account_sid: string, date_created: string, date_updated: string, flex_flow_sid: string, sid: string, task_sid: string, url: string, user_sid: string>"
    fetch-channel: "record<account_sid: string, date_created: string, date_updated: string, flex_flow_sid: string, sid: string, task_sid: string, url: string, user_sid: string>"
    fetch-configuration: "record<account_sid: string, attributes: any, call_recording_enabled: bool, call_recording_webhook_url: string, channel_configs: list<any>, chat_service_instance_sid: string, crm_attributes: any, crm_callback_url: string, crm_enabled: bool, crm_fallback_url: string, crm_type: string, date_created: string, date_updated: string, debugger_integration: any, flex_insights_drilldown: bool, flex_insights_hr: any, flex_service_instance_sid: string, flex_ui_status_report: any, flex_url: string, integrations: list<any>, markdown: any, messaging_service_instance_sid: string, notifications: any, outbound_call_flows: any, plugin_service_attributes: any, plugin_service_enabled: bool, public_attributes: any, queue_stats_configuration: any, runtime_domain: string, serverless_service_sids: list<string>, service_version: string, status: string, taskrouter_offline_activity_sid: string, taskrouter_skills: list<any>, taskrouter_target_taskqueue_sid: string, taskrouter_target_workflow_sid: string, taskrouter_taskqueues: list<any>, taskrouter_worker_attributes: any, taskrouter_worker_channels: any, taskrouter_workspace_sid: string, ui_attributes: any, ui_dependencies: any, ui_language: string, ui_version: string, url: string>"
    list-flex-flow: "record<flex_flows: table<account_sid: string, channel_type: string, chat_service_sid: string, contact_identity: string, date_created: string, date_updated: string, enabled: bool, friendly_name: string, integration: any, integration_type: string, janitor_enabled: bool, long_lived: bool, sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    create-flex-flow: "record<account_sid: string, channel_type: string, chat_service_sid: string, contact_identity: string, date_created: string, date_updated: string, enabled: bool, friendly_name: string, integration: any, integration_type: string, janitor_enabled: bool, long_lived: bool, sid: string, url: string>"
    fetch-flex-flow: "record<account_sid: string, channel_type: string, chat_service_sid: string, contact_identity: string, date_created: string, date_updated: string, enabled: bool, friendly_name: string, integration: any, integration_type: string, janitor_enabled: bool, long_lived: bool, sid: string, url: string>"
    update-flex-flow: "record<account_sid: string, channel_type: string, chat_service_sid: string, contact_identity: string, date_created: string, date_updated: string, enabled: bool, friendly_name: string, integration: any, integration_type: string, janitor_enabled: bool, long_lived: bool, sid: string, url: string>"
    list-insights-conversations: "record<conversations: table<account_id: string, conversation_id: string, segment_count: int, segments: list>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    list-insights-assessments: "record<assessments: table<account_sid: string, agent_id: string, answer_id: string, answer_text: string, assessment: any, assessment_id: string, offset: float, report: bool, segment_id: string, timestamp: float, url: string, user_email: string, user_name: string, weight: float>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    create-insights-assessments: "record<account_sid: string, agent_id: string, answer_id: string, answer_text: string, assessment: any, assessment_id: string, offset: float, report: bool, segment_id: string, timestamp: float, url: string, user_email: string, user_name: string, weight: float>"
    list-insights-assessments-comment: "record<comments: table<account_sid: string, agent_id: string, assessment_id: string, comment: any, offset: float, report: bool, segment_id: string, timestamp: float, url: string, user_email: string, user_name: string, weight: float>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    create-insights-assessments-comment: "record<account_sid: string, agent_id: string, assessment_id: string, comment: any, offset: float, report: bool, segment_id: string, timestamp: float, url: string, user_email: string, user_name: string, weight: float>"
    update-insights-assessments: "record<account_sid: string, agent_id: string, answer_id: string, answer_text: string, assessment: any, assessment_id: string, offset: float, report: bool, segment_id: string, timestamp: float, url: string, user_email: string, user_name: string, weight: float>"
    list-insights-questionnaires-category: "record<categories: table<account_sid: string, category_id: string, name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    create-insights-questionnaires-category: "record<account_sid: string, category_id: string, name: string, url: string>"
    update-insights-questionnaires-category: "record<account_sid: string, category_id: string, name: string, url: string>"
    list-insights-questionnaires: "record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, questionnaires: table<account_sid: string, active: bool, description: string, id: string, name: string, questions: list, url: string>>"
    create-insights-questionnaires: "record<account_sid: string, active: bool, description: string, id: string, name: string, questions: list<any>, url: string>"
    fetch-insights-questionnaires: "record<account_sid: string, active: bool, description: string, id: string, name: string, questions: list<any>, url: string>"
    update-insights-questionnaires: "record<account_sid: string, active: bool, description: string, id: string, name: string, questions: list<any>, url: string>"
    list-insights-questionnaires-question: "record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, questions: table<account_sid: string, allow_na: bool, answer_set: any, answer_set_id: string, category: any, description: string, question: string, question_id: string, url: string, usage: int>>"
    create-insights-questionnaires-question: "record<account_sid: string, allow_na: bool, answer_set: any, answer_set_id: string, category: any, description: string, question: string, question_id: string, url: string, usage: int>"
    update-insights-questionnaires-question: "record<account_sid: string, allow_na: bool, answer_set: any, answer_set_id: string, category: any, description: string, question: string, question_id: string, url: string, usage: int>"
    fetch-insights-settings-answersets: "record<account_sid: string, answer_set_categories: any, answer_sets: any, not_applicable: any, url: string>"
    fetch-insights-settings-comment: "record<account_sid: string, comments: any, url: string>"
    list-insights-segments: "record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, segments: table<account_id: string, agent_id: string, agent_link: string, agent_name: string, agent_phone: string, agent_team_name: string, agent_team_name_in_hierarchy: string, assessment_percentage: any, assessment_type: any, customer_link: string, customer_name: string, customer_phone: string, date: string, external_contact: string, external_id: string, external_segment_link: string, external_segment_link_id: string, media: any, queue: string, segment_id: string, segment_recording_offset: string, url: string>>"
    fetch-insights-segments: "record<account_id: string, agent_id: string, agent_link: string, agent_name: string, agent_phone: string, agent_team_name: string, agent_team_name_in_hierarchy: string, assessment_percentage: any, assessment_type: any, customer_link: string, customer_name: string, customer_phone: string, date: string, external_contact: string, external_id: string, external_segment_link: string, external_segment_link_id: string, media: any, queue: string, segment_id: string, segment_recording_offset: string, url: string>"
    create-insights-session: "record<base_url: string, session_expiry: string, session_id: string, url: string, workspace_id: string>"
    fetch-insights-user-roles: "record<roles: list<string>, url: string>"
    create-interaction: "record<channel: any, links: record, routing: any, sid: string, url: string>"
    list-interaction-channel: "record<channels: table<error_code: int, error_message: string, interaction_sid: string, links: record, sid: string, status: string, type: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    list-interaction-channel-invite: "record<invites: table<channel_sid: string, interaction_sid: string, routing: any, sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    create-interaction-channel-invite: "record<channel_sid: string, interaction_sid: string, routing: any, sid: string, url: string>"
    list-interaction-channel-participant: "record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, participants: table<channel_sid: string, interaction_sid: string, sid: string, type: string, url: string>>"
    create-interaction-channel-participant: "record<channel_sid: string, interaction_sid: string, sid: string, type: string, url: string>"
    update-interaction-channel-participant: "record<channel_sid: string, interaction_sid: string, sid: string, type: string, url: string>"
    fetch-interaction-channel: "record<error_code: int, error_message: string, interaction_sid: string, links: record, sid: string, status: string, type: string, url: string>"
    update-interaction-channel: "record<error_code: int, error_message: string, interaction_sid: string, links: record, sid: string, status: string, type: string, url: string>"
    fetch-interaction: "record<channel: any, links: record, routing: any, sid: string, url: string>"
    list-web-channel: "record<flex_chat_channels: table<account_sid: string, date_created: string, date_updated: string, flex_flow_sid: string, sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    create-web-channel: "record<account_sid: string, date_created: string, date_updated: string, flex_flow_sid: string, sid: string, url: string>"
    fetch-web-channel: "record<account_sid: string, date_created: string, date_updated: string, flex_flow_sid: string, sid: string, url: string>"
    update-web-channel: "record<account_sid: string, date_created: string, date_updated: string, flex_flow_sid: string, sid: string, url: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["list-channel" "create-channel" "delete-channel" "fetch-channel" "fetch-configuration" "list-flex-flow" "create-flex-flow" "delete-flex-flow" "fetch-flex-flow" "update-flex-flow" "list-insights-conversations" "list-insights-assessments" "create-insights-assessments" "list-insights-assessments-comment" "create-insights-assessments-comment" "update-insights-assessments" "list-insights-questionnaires-category" "create-insights-questionnaires-category" "delete-insights-questionnaires-category" "update-insights-questionnaires-category" "list-insights-questionnaires" "create-insights-questionnaires" "delete-insights-questionnaires" "fetch-insights-questionnaires" "update-insights-questionnaires" "list-insights-questionnaires-question" "create-insights-questionnaires-question" "delete-insights-questionnaires-question" "update-insights-questionnaires-question" "fetch-insights-settings-answersets" "fetch-insights-settings-comment" "list-insights-segments" "fetch-insights-segments" "create-insights-session" "fetch-insights-user-roles" "create-interaction" "list-interaction-channel" "list-interaction-channel-invite" "create-interaction-channel-invite" "list-interaction-channel-participant" "create-interaction-channel-participant" "update-interaction-channel-participant" "fetch-interaction-channel" "update-interaction-channel" "fetch-interaction" "list-web-channel" "create-web-channel" "delete-web-channel" "fetch-web-channel" "update-web-channel" "commands"] | sort) } | get name | first)
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

# GET /v1/Channels
#
# Returns: record<flex_chat_channels: table<account_sid: string, date_created: string, date_updated: string, flex_flow_sid: string, sid: string, task_sid: string, url: string, user_sid: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListChannel
export def "list-channel" [
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
    path: "/v1/Channels"
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://flex-api.twilio.com"
    auth: basic
  } {
    page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Channels
#
# Returns: record<account_sid: string, date_created: string, date_updated: string, flex_flow_sid: string, sid: string, task_sid: string, url: string, user_sid: string>
# operationId: CreateChannel
export def "create-channel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  chat_friendly_name: string # The chat channel's friendly name.
  --chat-unique-name: string # The chat channel's unique name.
  chat_user_friendly_name: string # The chat participant's friendly name.
  flex_flow_sid: string # The SID of the Flex Flow.
  identity: string # The `identity` value that uniquely identifies the new resource's chat User.
  --long-lived: oneof<nothing, bool> # Whether to create the channel as long-lived.
  --pre-engagement-data: string # The pre-engagement data.
  --target: string # The Target Contact Identity, for example the phone number of an SMS.
  --task-attributes: string # The Task attributes to be added for the TaskRouter Task.
  --task-sid: string # The SID of the TaskRouter Task. Only valid when integration type is `task`. `null` for integration types `studio` & `external`
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Channels"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: ChatFriendlyName, var: chat_friendly_name}, {name: ChatUniqueName, var: chat_unique_name}, {name: ChatUserFriendlyName, var: chat_user_friendly_name}, {name: FlexFlowSid, var: flex_flow_sid}, {name: Identity, var: identity}, {name: LongLived, var: long_lived}, {name: PreEngagementData, var: pre_engagement_data}, {name: Target, var: target}, {name: TaskAttributes, var: task_attributes}, {name: TaskSid, var: task_sid}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://flex-api.twilio.com"
    auth: basic
  } {
    chat_friendly_name: $chat_friendly_name, chat_unique_name: $chat_unique_name, chat_user_friendly_name: $chat_user_friendly_name, flex_flow_sid: $flex_flow_sid, identity: $identity, long_lived: $long_lived, pre_engagement_data: $pre_engagement_data, target: $target, task_attributes: $task_attributes, task_sid: $task_sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/Channels/{Sid}
#
# operationId: DeleteChannel
export def "delete-channel" [
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
    path: "/v1/Channels/{Sid}"
    path_params: [{name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://flex-api.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Channels/{Sid}
#
# Returns: record<account_sid: string, date_created: string, date_updated: string, flex_flow_sid: string, sid: string, task_sid: string, url: string, user_sid: string>
# operationId: FetchChannel
export def "fetch-channel" [
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
    path: "/v1/Channels/{Sid}"
    path_params: [{name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://flex-api.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Configuration
#
# Returns: record<account_sid: string, attributes: any, call_recording_enabled: bool, call_recording_webhook_url: string, channel_configs: list<any>, chat_service_instance_sid: string, crm_attributes: any, crm_callback_url: string, crm_enabled: bool, crm_fallback_url: string, crm_type: string, date_created: string, date_updated: string, debugger_integration: any, flex_insights_drilldown: bool, flex_insights_hr: any, flex_service_instance_sid: string, flex_ui_status_report: any, flex_url: string, integrations: list<any>, markdown: any, messaging_service_instance_sid: string, notifications: any, outbound_call_flows: any, plugin_service_attributes: any, plugin_service_enabled: bool, public_attributes: any, queue_stats_configuration: any, runtime_domain: string, serverless_service_sids: list<string>, service_version: string, status: string, taskrouter_offline_activity_sid: string, taskrouter_skills: list<any>, taskrouter_target_taskqueue_sid: string, taskrouter_target_workflow_sid: string, taskrouter_taskqueues: list<any>, taskrouter_worker_attributes: any, taskrouter_worker_channels: any, taskrouter_workspace_sid: string, ui_attributes: any, ui_dependencies: any, ui_language: string, ui_version: string, url: string>
# operationId: FetchConfiguration
export def "fetch-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ui-version: string # The Pinned UI version of the Configuration resource to fetch.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/Configuration"
    query: [{name: UiVersion, var: ui_version}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://flex-api.twilio.com"
    auth: basic
  } {
    ui_version: $ui_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/FlexFlows
#
# Returns: record<flex_flows: table<account_sid: string, channel_type: string, chat_service_sid: string, contact_identity: string, date_created: string, date_updated: string, enabled: bool, friendly_name: string, integration: any, integration_type: string, janitor_enabled: bool, long_lived: bool, sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListFlexFlow
export def "list-flex-flow" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --friendly-name: string # The `friendly_name` of the Flex Flow resources to read.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/FlexFlows"
    query: [{name: FriendlyName, var: friendly_name}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://flex-api.twilio.com"
    auth: basic
  } {
    friendly_name: $friendly_name, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/FlexFlows
#
# Returns: record<account_sid: string, channel_type: string, chat_service_sid: string, contact_identity: string, date_created: string, date_updated: string, enabled: bool, friendly_name: string, integration: any, integration_type: string, janitor_enabled: bool, long_lived: bool, sid: string, url: string>
# operationId: CreateFlexFlow
export def "create-flex-flow" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  channel_type: string@channel-type-completer
  chat_service_sid: string # The SID of the chat service.
  --contact-identity: string # The channel contact's Identity.
  --enabled: oneof<nothing, bool> # Whether the new Flex Flow is enabled.
  friendly_name: string # A descriptive string that you create to describe the Flex Flow resource.
  --integration-channel: string # The Task Channel SID (TCXXXX) or unique name (e.g., `sms`) to use for the Task that will be created. Applicable and required when `integrationType` is `task`. The default value is `default`.
  --integration-creation-on-message: oneof<nothing, bool> # In the context of outbound messaging, defines whether to create a Task immediately (and therefore reserve the conversation to current agent), or delay Task creation until the customer sends the first response. Set to false to create immediately, true to delay Task creation. This setting is only applicable for outbound messaging.
  --integration-flow-sid: string # The SID of the Studio Flow. Required when `integrationType` is `studio`.
  --integration-priority: int # The Task priority of a new Task. The default priority is 0. Optional when `integrationType` is `task`, not applicable otherwise.
  --integration-retry-count: int # The number of times to retry the Studio Flow or webhook in case of failure. Takes integer values from 0 to 3 with the default being 3. Optional when `integrationType` is `studio` or `external`, not applicable otherwise.
  --integration-timeout: int # The Task timeout in seconds for a new Task. Default is 86,400 seconds (24 hours). Optional when `integrationType` is `task`, not applicable otherwise.
  --integration-url: string # The URL of the external webhook. Required when `integrationType` is `external`. (format: uri)
  --integration-workflow-sid: string # The Workflow SID for a new Task. Required when `integrationType` is `task`.
  --integration-workspace-sid: string # The Workspace SID for a new Task. Required when `integrationType` is `task`.
  --integration-type: string@integration-type-completer
  --janitor-enabled: oneof<nothing, bool> # When enabled, the Messaging Channel Janitor will remove active Proxy sessions if the associated Task is deleted outside of the Flex UI. Defaults to `false`.
  --long-lived: oneof<nothing, bool> # When enabled, Flex will keep the chat channel active so that it may be used for subsequent interactions with a contact identity. Defaults to `false`.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/FlexFlows"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: ChannelType, var: channel_type}, {name: ChatServiceSid, var: chat_service_sid}, {name: ContactIdentity, var: contact_identity}, {name: Enabled, var: enabled}, {name: FriendlyName, var: friendly_name}, {name: "Integration.Channel", var: integration_channel}, {name: "Integration.CreationOnMessage", var: integration_creation_on_message}, {name: "Integration.FlowSid", var: integration_flow_sid}, {name: "Integration.Priority", var: integration_priority}, {name: "Integration.RetryCount", var: integration_retry_count}, {name: "Integration.Timeout", var: integration_timeout}, {name: "Integration.Url", var: integration_url}, {name: "Integration.WorkflowSid", var: integration_workflow_sid}, {name: "Integration.WorkspaceSid", var: integration_workspace_sid}, {name: IntegrationType, var: integration_type}, {name: JanitorEnabled, var: janitor_enabled}, {name: LongLived, var: long_lived}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://flex-api.twilio.com"
    auth: basic
  } {
    channel_type: $channel_type, chat_service_sid: $chat_service_sid, contact_identity: $contact_identity, enabled: $enabled, friendly_name: $friendly_name, integration_channel: $integration_channel, integration_creation_on_message: $integration_creation_on_message, integration_flow_sid: $integration_flow_sid, integration_priority: $integration_priority, integration_retry_count: $integration_retry_count, integration_timeout: $integration_timeout, integration_url: $integration_url, integration_workflow_sid: $integration_workflow_sid, integration_workspace_sid: $integration_workspace_sid, integration_type: $integration_type, janitor_enabled: $janitor_enabled, long_lived: $long_lived
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/FlexFlows/{Sid}
#
# operationId: DeleteFlexFlow
export def "delete-flex-flow" [
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
    path: "/v1/FlexFlows/{Sid}"
    path_params: [{name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://flex-api.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/FlexFlows/{Sid}
#
# Returns: record<account_sid: string, channel_type: string, chat_service_sid: string, contact_identity: string, date_created: string, date_updated: string, enabled: bool, friendly_name: string, integration: any, integration_type: string, janitor_enabled: bool, long_lived: bool, sid: string, url: string>
# operationId: FetchFlexFlow
export def "fetch-flex-flow" [
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
    path: "/v1/FlexFlows/{Sid}"
    path_params: [{name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://flex-api.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/FlexFlows/{Sid}
#
# Returns: record<account_sid: string, channel_type: string, chat_service_sid: string, contact_identity: string, date_created: string, date_updated: string, enabled: bool, friendly_name: string, integration: any, integration_type: string, janitor_enabled: bool, long_lived: bool, sid: string, url: string>
# operationId: UpdateFlexFlow
export def "update-flex-flow" [
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
  --channel-type: string@channel-type-completer
  --chat-service-sid: string # The SID of the chat service.
  --contact-identity: string # The channel contact's Identity.
  --enabled: oneof<nothing, bool> # Whether the new Flex Flow is enabled.
  --friendly-name: string # A descriptive string that you create to describe the Flex Flow resource.
  --integration-channel: string # The Task Channel SID (TCXXXX) or unique name (e.g., `sms`) to use for the Task that will be created. Applicable and required when `integrationType` is `task`. The default value is `default`.
  --integration-creation-on-message: oneof<nothing, bool> # In the context of outbound messaging, defines whether to create a Task immediately (and therefore reserve the conversation to current agent), or delay Task creation until the customer sends the first response. Set to false to create immediately, true to delay Task creation. This setting is only applicable for outbound messaging.
  --integration-flow-sid: string # The SID of the Studio Flow. Required when `integrationType` is `studio`.
  --integration-priority: int # The Task priority of a new Task. The default priority is 0. Optional when `integrationType` is `task`, not applicable otherwise.
  --integration-retry-count: int # The number of times to retry the Studio Flow or webhook in case of failure. Takes integer values from 0 to 3 with the default being 3. Optional when `integrationType` is `studio` or `external`, not applicable otherwise.
  --integration-timeout: int # The Task timeout in seconds for a new Task. Default is 86,400 seconds (24 hours). Optional when `integrationType` is `task`, not applicable otherwise.
  --integration-url: string # The URL of the external webhook. Required when `integrationType` is `external`. (format: uri)
  --integration-workflow-sid: string # The Workflow SID for a new Task. Required when `integrationType` is `task`.
  --integration-workspace-sid: string # The Workspace SID for a new Task. Required when `integrationType` is `task`.
  --integration-type: string@integration-type-completer
  --janitor-enabled: oneof<nothing, bool> # When enabled, the Messaging Channel Janitor will remove active Proxy sessions if the associated Task is deleted outside of the Flex UI. Defaults to `false`.
  --long-lived: oneof<nothing, bool> # When enabled, Flex will keep the chat channel active so that it may be used for subsequent interactions with a contact identity. Defaults to `false`.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/FlexFlows/{Sid}"
    path_params: [{name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: ChannelType, var: channel_type}, {name: ChatServiceSid, var: chat_service_sid}, {name: ContactIdentity, var: contact_identity}, {name: Enabled, var: enabled}, {name: FriendlyName, var: friendly_name}, {name: "Integration.Channel", var: integration_channel}, {name: "Integration.CreationOnMessage", var: integration_creation_on_message}, {name: "Integration.FlowSid", var: integration_flow_sid}, {name: "Integration.Priority", var: integration_priority}, {name: "Integration.RetryCount", var: integration_retry_count}, {name: "Integration.Timeout", var: integration_timeout}, {name: "Integration.Url", var: integration_url}, {name: "Integration.WorkflowSid", var: integration_workflow_sid}, {name: "Integration.WorkspaceSid", var: integration_workspace_sid}, {name: IntegrationType, var: integration_type}, {name: JanitorEnabled, var: janitor_enabled}, {name: LongLived, var: long_lived}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://flex-api.twilio.com"
    auth: basic
  } {
    sid: $sid, channel_type: $channel_type, chat_service_sid: $chat_service_sid, contact_identity: $contact_identity, enabled: $enabled, friendly_name: $friendly_name, integration_channel: $integration_channel, integration_creation_on_message: $integration_creation_on_message, integration_flow_sid: $integration_flow_sid, integration_priority: $integration_priority, integration_retry_count: $integration_retry_count, integration_timeout: $integration_timeout, integration_url: $integration_url, integration_workflow_sid: $integration_workflow_sid, integration_workspace_sid: $integration_workspace_sid, integration_type: $integration_type, janitor_enabled: $janitor_enabled, long_lived: $long_lived
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# To get conversation with segment id
#
# GET /v1/Insights/Conversations
# Returns: record<conversations: table<account_id: string, conversation_id: string, segment_count: int, segments: list>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListInsightsConversations
export def "list-insights-conversations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --segment-id: string # Unique Id of the segment for which conversation details needs to be fetched
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
  --hdr-token: string # The Token HTTP request header (spec name: Token)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/Insights/Conversations"
    query: [{name: SegmentId, var: segment_id}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    header: [{name: Token, var: hdr_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://flex-api.twilio.com"
    auth: basic
  } {
    segment_id: $segment_id, page_size: $page_size, page: $page, page_token: $page_token, hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get assessments done for a conversation by logged in user
#
# GET /v1/Insights/QM/Assessments
# Returns: record<assessments: table<account_sid: string, agent_id: string, answer_id: string, answer_text: string, assessment: any, assessment_id: string, offset: float, report: bool, segment_id: string, timestamp: float, url: string, user_email: string, user_name: string, weight: float>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListInsightsAssessments
export def "list-insights-assessments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --segment-id: string # The id of the segment.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
  --hdr-token: string # The Token HTTP request header (spec name: Token)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/Insights/QM/Assessments"
    query: [{name: SegmentId, var: segment_id}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    header: [{name: Token, var: hdr_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://flex-api.twilio.com"
    auth: basic
  } {
    segment_id: $segment_id, page_size: $page_size, page: $page, page_token: $page_token, hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add assessments against conversation to dynamo db. Used in assessments screen by user. Users can select the questionnaire and pick up answers for each and every question.
#
# POST /v1/Insights/QM/Assessments
# Returns: record<account_sid: string, agent_id: string, answer_id: string, answer_text: string, assessment: any, assessment_id: string, offset: float, report: bool, segment_id: string, timestamp: float, url: string, user_email: string, user_name: string, weight: float>
# operationId: CreateInsightsAssessments
export def "create-insights-assessments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # The Token HTTP request header (spec name: Token)
  agent_id: string # The id of the Agent
  answer_id: string # The id of the answer selected by user
  answer_text: string # The answer text selected by user
  category_id: string # The id of the category
  category_name: string # The name of the category
  metric_id: string # The question Id selected for assessment
  metric_name: string # The question name of the assessment
  offset: float # The offset of the conversation.
  questionnaire_id: string # Questionnaire Id of the associated question
  segment_id: string # Segment Id of the conversation
  user_email: string # Email of the user assessing conversation
  user_name: string # Name of the user assessing conversation
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Insights/QM/Assessments"
    header: [{name: Token, var: hdr_token}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: AgentId, var: agent_id}, {name: AnswerId, var: answer_id}, {name: AnswerText, var: answer_text}, {name: CategoryId, var: category_id}, {name: CategoryName, var: category_name}, {name: MetricId, var: metric_id}, {name: MetricName, var: metric_name}, {name: Offset, var: offset}, {name: QuestionnaireId, var: questionnaire_id}, {name: SegmentId, var: segment_id}, {name: UserEmail, var: user_email}, {name: UserName, var: user_name}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://flex-api.twilio.com"
    auth: basic
  } {
    hdr_token: $hdr_token, agent_id: $agent_id, answer_id: $answer_id, answer_text: $answer_text, category_id: $category_id, category_name: $category_name, metric_id: $metric_id, metric_name: $metric_name, offset: $offset, questionnaire_id: $questionnaire_id, segment_id: $segment_id, user_email: $user_email, user_name: $user_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# To create a comment assessment for a conversation
#
# GET /v1/Insights/QM/Assessments/Comments
# Returns: record<comments: table<account_sid: string, agent_id: string, assessment_id: string, comment: any, offset: float, report: bool, segment_id: string, timestamp: float, url: string, user_email: string, user_name: string, weight: float>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListInsightsAssessmentsComment
export def "list-insights-assessments-comment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --segment-id: string # The id of the segment.
  --agent-id: string # The id of the agent.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
  --hdr-token: string # The Token HTTP request header (spec name: Token)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/Insights/QM/Assessments/Comments"
    query: [{name: SegmentId, var: segment_id}, {name: AgentId, var: agent_id}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    header: [{name: Token, var: hdr_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://flex-api.twilio.com"
    auth: basic
  } {
    segment_id: $segment_id, agent_id: $agent_id, page_size: $page_size, page: $page, page_token: $page_token, hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# To create a comment assessment for a conversation
#
# POST /v1/Insights/QM/Assessments/Comments
# Returns: record<account_sid: string, agent_id: string, assessment_id: string, comment: any, offset: float, report: bool, segment_id: string, timestamp: float, url: string, user_email: string, user_name: string, weight: float>
# operationId: CreateInsightsAssessmentsComment
export def "create-insights-assessments-comment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # The Token HTTP request header (spec name: Token)
  agent_id: string # The id of the agent.
  category_id: string # The ID of the category
  category_name: string # The name of the category
  comment: string # The Assessment comment.
  offset: float # The offset
  segment_id: string # The id of the segment.
  user_email: string # The email id of the user.
  user_name: string # The name of the user.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Insights/QM/Assessments/Comments"
    header: [{name: Token, var: hdr_token}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: AgentId, var: agent_id}, {name: CategoryId, var: category_id}, {name: CategoryName, var: category_name}, {name: Comment, var: comment}, {name: Offset, var: offset}, {name: SegmentId, var: segment_id}, {name: UserEmail, var: user_email}, {name: UserName, var: user_name}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://flex-api.twilio.com"
    auth: basic
  } {
    hdr_token: $hdr_token, agent_id: $agent_id, category_id: $category_id, category_name: $category_name, comment: $comment, offset: $offset, segment_id: $segment_id, user_email: $user_email, user_name: $user_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a specific Assessment assessed earlier
#
# POST /v1/Insights/QM/Assessments/{AssessmentId}
# Returns: record<account_sid: string, agent_id: string, answer_id: string, answer_text: string, assessment: any, assessment_id: string, offset: float, report: bool, segment_id: string, timestamp: float, url: string, user_email: string, user_name: string, weight: float>
# operationId: UpdateInsightsAssessments
export def "update-insights-assessments" [
  assessment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # The Token HTTP request header (spec name: Token)
  answer_id: string # The id of the answer selected by user
  answer_text: string # The answer text selected by user
  offset: float # The offset of the conversation
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Insights/QM/Assessments/{AssessmentId}"
    path_params: [{name: AssessmentId, var: assessment_id}]
    header: [{name: Token, var: hdr_token}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: AnswerId, var: answer_id}, {name: AnswerText, var: answer_text}, {name: Offset, var: offset}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://flex-api.twilio.com"
    auth: basic
  } {
    assessment_id: $assessment_id, hdr_token: $hdr_token, answer_id: $answer_id, answer_text: $answer_text, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# To get all the categories
#
# GET /v1/Insights/QM/Categories
# Returns: record<categories: table<account_sid: string, category_id: string, name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListInsightsQuestionnairesCategory
export def "list-insights-questionnaires-category" [
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
  --hdr-token: string # The Token HTTP request header (spec name: Token)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/Insights/QM/Categories"
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    header: [{name: Token, var: hdr_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://flex-api.twilio.com"
    auth: basic
  } {
    page_size: $page_size, page: $page, page_token: $page_token, hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# To create a category for Questions
#
# POST /v1/Insights/QM/Categories
# Returns: record<account_sid: string, category_id: string, name: string, url: string>
# operationId: CreateInsightsQuestionnairesCategory
export def "create-insights-questionnaires-category" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # The Token HTTP request header (spec name: Token)
  name: string # The name of this category.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Insights/QM/Categories"
    header: [{name: Token, var: hdr_token}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://flex-api.twilio.com"
    auth: basic
  } {
    hdr_token: $hdr_token, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/Insights/QM/Categories/{CategoryId}
#
# operationId: DeleteInsightsQuestionnairesCategory
export def "delete-insights-questionnaires-category" [
  category_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # The Token HTTP request header (spec name: Token)
]: nothing -> any {
  http-request {
    method: delete
    path: "/v1/Insights/QM/Categories/{CategoryId}"
    path_params: [{name: CategoryId, var: category_id}]
    header: [{name: Token, var: hdr_token}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://flex-api.twilio.com"
    auth: basic
  } {
    category_id: $category_id, hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# To update the category for Questions
#
# POST /v1/Insights/QM/Categories/{CategoryId}
# Returns: record<account_sid: string, category_id: string, name: string, url: string>
# operationId: UpdateInsightsQuestionnairesCategory
export def "update-insights-questionnaires-category" [
  category_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # The Token HTTP request header (spec name: Token)
  name: string # The name of this category.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Insights/QM/Categories/{CategoryId}"
    path_params: [{name: CategoryId, var: category_id}]
    header: [{name: Token, var: hdr_token}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://flex-api.twilio.com"
    auth: basic
  } {
    category_id: $category_id, hdr_token: $hdr_token, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# To get all questionnaires with questions
#
# GET /v1/Insights/QM/Questionnaires
# Returns: record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, questionnaires: table<account_sid: string, active: bool, description: string, id: string, name: string, questions: list, url: string>>
# operationId: ListInsightsQuestionnaires
export def "list-insights-questionnaires" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-inactive: oneof<nothing, bool> # Flag indicating whether to include inactive questionnaires or not
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
  --hdr-token: string # The Token HTTP request header (spec name: Token)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/Insights/QM/Questionnaires"
    query: [{name: IncludeInactive, var: include_inactive}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    header: [{name: Token, var: hdr_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://flex-api.twilio.com"
    auth: basic
  } {
    include_inactive: $include_inactive, page_size: $page_size, page: $page, page_token: $page_token, hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# To create a Questionnaire
#
# POST /v1/Insights/QM/Questionnaires
# Returns: record<account_sid: string, active: bool, description: string, id: string, name: string, questions: list<any>, url: string>
# operationId: CreateInsightsQuestionnaires
export def "create-insights-questionnaires" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # The Token HTTP request header (spec name: Token)
  --active: oneof<nothing, bool> # The flag to enable or disable questionnaire
  --description: string # The description of this questionnaire
  name: string # The name of this questionnaire
  --question-ids: list<string> # The list of questions ids under a questionnaire
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Insights/QM/Questionnaires"
    header: [{name: Token, var: hdr_token}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Active, var: active}, {name: Description, var: description}, {name: Name, var: name}, {name: QuestionIds, var: question_ids}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://flex-api.twilio.com"
    auth: basic
  } {
    hdr_token: $hdr_token, active: $active, description: $description, name: $name, question_ids: $question_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# To delete the questionnaire
#
# DELETE /v1/Insights/QM/Questionnaires/{Id}
# operationId: DeleteInsightsQuestionnaires
export def "delete-insights-questionnaires" [
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
  --hdr-token: string # The Token HTTP request header (spec name: Token)
]: nothing -> any {
  http-request {
    method: delete
    path: "/v1/Insights/QM/Questionnaires/{Id}"
    path_params: [{name: Id, var: id}]
    header: [{name: Token, var: hdr_token}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://flex-api.twilio.com"
    auth: basic
  } {
    id: $id, hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# To get the Questionnaire Detail
#
# GET /v1/Insights/QM/Questionnaires/{Id}
# Returns: record<account_sid: string, active: bool, description: string, id: string, name: string, questions: list<any>, url: string>
# operationId: FetchInsightsQuestionnaires
export def "fetch-insights-questionnaires" [
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
  --hdr-token: string # The Token HTTP request header (spec name: Token)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/Insights/QM/Questionnaires/{Id}"
    path_params: [{name: Id, var: id}]
    header: [{name: Token, var: hdr_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://flex-api.twilio.com"
    auth: basic
  } {
    id: $id, hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# To update the questionnaire
#
# POST /v1/Insights/QM/Questionnaires/{Id}
# Returns: record<account_sid: string, active: bool, description: string, id: string, name: string, questions: list<any>, url: string>
# operationId: UpdateInsightsQuestionnaires
export def "update-insights-questionnaires" [
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
  --hdr-token: string # The Token HTTP request header (spec name: Token)
  --active: oneof<nothing, bool> # The flag to enable or disable questionnaire
  --description: string # The description of this questionnaire
  --name: string # The name of this questionnaire
  --question-ids: list<string> # The list of questions ids under a questionnaire
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Insights/QM/Questionnaires/{Id}"
    path_params: [{name: Id, var: id}]
    header: [{name: Token, var: hdr_token}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Active, var: active, required: true}, {name: Description, var: description}, {name: Name, var: name}, {name: QuestionIds, var: question_ids}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://flex-api.twilio.com"
    auth: basic
  } {
    id: $id, hdr_token: $hdr_token, active: $active, description: $description, name: $name, question_ids: $question_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# To get all the question for the given categories
#
# GET /v1/Insights/QM/Questions
# Returns: record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, questions: table<account_sid: string, allow_na: bool, answer_set: any, answer_set_id: string, category: any, description: string, question: string, question_id: string, url: string, usage: int>>
# operationId: ListInsightsQuestionnairesQuestion
export def "list-insights-questionnaires-question" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category-id: list<string> # The list of category IDs
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
  --hdr-token: string # The Token HTTP request header (spec name: Token)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/Insights/QM/Questions"
    query: [{name: CategoryId, var: category_id, style: multi}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    header: [{name: Token, var: hdr_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://flex-api.twilio.com"
    auth: basic
  } {
    category_id: $category_id, page_size: $page_size, page: $page, page_token: $page_token, hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# To create a question for a Category
#
# POST /v1/Insights/QM/Questions
# Returns: record<account_sid: string, allow_na: bool, answer_set: any, answer_set_id: string, category: any, description: string, question: string, question_id: string, url: string, usage: int>
# operationId: CreateInsightsQuestionnairesQuestion
export def "create-insights-questionnaires-question" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # The Token HTTP request header (spec name: Token)
  --allow-na: oneof<nothing, bool> # The flag to enable for disable NA for answer.
  answer_set_id: string # The answer_set for the question.
  category_id: string # The ID of the category
  --description: string # The description for the question.
  question: string # The question.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Insights/QM/Questions"
    header: [{name: Token, var: hdr_token}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: AllowNa, var: allow_na, required: true}, {name: AnswerSetId, var: answer_set_id}, {name: CategoryId, var: category_id}, {name: Description, var: description}, {name: Question, var: question}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://flex-api.twilio.com"
    auth: basic
  } {
    hdr_token: $hdr_token, allow_na: $allow_na, answer_set_id: $answer_set_id, category_id: $category_id, description: $description, question: $question
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/Insights/QM/Questions/{QuestionId}
#
# operationId: DeleteInsightsQuestionnairesQuestion
export def "delete-insights-questionnaires-question" [
  question_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # The Token HTTP request header (spec name: Token)
]: nothing -> any {
  http-request {
    method: delete
    path: "/v1/Insights/QM/Questions/{QuestionId}"
    path_params: [{name: QuestionId, var: question_id}]
    header: [{name: Token, var: hdr_token}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://flex-api.twilio.com"
    auth: basic
  } {
    question_id: $question_id, hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# To update the question
#
# POST /v1/Insights/QM/Questions/{QuestionId}
# Returns: record<account_sid: string, allow_na: bool, answer_set: any, answer_set_id: string, category: any, description: string, question: string, question_id: string, url: string, usage: int>
# operationId: UpdateInsightsQuestionnairesQuestion
export def "update-insights-questionnaires-question" [
  question_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # The Token HTTP request header (spec name: Token)
  --allow-na: oneof<nothing, bool> # The flag to enable for disable NA for answer.
  --answer-set-id: string # The answer_set for the question.
  --category-id: string # The ID of the category
  --description: string # The description for the question.
  --question: string # The question.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Insights/QM/Questions/{QuestionId}"
    path_params: [{name: QuestionId, var: question_id}]
    header: [{name: Token, var: hdr_token}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: AllowNa, var: allow_na, required: true}, {name: AnswerSetId, var: answer_set_id}, {name: CategoryId, var: category_id}, {name: Description, var: description}, {name: Question, var: question}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://flex-api.twilio.com"
    auth: basic
  } {
    question_id: $question_id, hdr_token: $hdr_token, allow_na: $allow_na, answer_set_id: $answer_set_id, category_id: $category_id, description: $description, question: $question
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# To get the Answer Set Settings for an Account
#
# GET /v1/Insights/QM/Settings/AnswerSets
# Returns: record<account_sid: string, answer_set_categories: any, answer_sets: any, not_applicable: any, url: string>
# operationId: FetchInsightsSettingsAnswersets
export def "fetch-insights-settings-answersets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # The Token HTTP request header (spec name: Token)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/Insights/QM/Settings/AnswerSets"
    header: [{name: Token, var: hdr_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://flex-api.twilio.com"
    auth: basic
  } {
    hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# To get the Comment Settings for an Account
#
# GET /v1/Insights/QM/Settings/CommentTags
# Returns: record<account_sid: string, comments: any, url: string>
# operationId: FetchInsightsSettingsComment
export def "fetch-insights-settings-comment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # The Token HTTP request header (spec name: Token)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/Insights/QM/Settings/CommentTags"
    header: [{name: Token, var: hdr_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://flex-api.twilio.com"
    auth: basic
  } {
    hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# To get segments for given reservation Ids
#
# GET /v1/Insights/Segments
# Returns: record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, segments: table<account_id: string, agent_id: string, agent_link: string, agent_name: string, agent_phone: string, agent_team_name: string, agent_team_name_in_hierarchy: string, assessment_percentage: any, assessment_type: any, customer_link: string, customer_name: string, customer_phone: string, date: string, external_contact: string, external_id: string, external_segment_link: string, external_segment_link_id: string, media: any, queue: string, segment_id: string, segment_recording_offset: string, url: string>>
# operationId: ListInsightsSegments
export def "list-insights-segments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --reservation-id: list<string> # The list of reservation Ids
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
  --hdr-token: string # The Token HTTP request header (spec name: Token)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/Insights/Segments"
    query: [{name: ReservationId, var: reservation_id, style: multi}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    header: [{name: Token, var: hdr_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://flex-api.twilio.com"
    auth: basic
  } {
    reservation_id: $reservation_id, page_size: $page_size, page: $page, page_token: $page_token, hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# To get the Segments of an Account
#
# GET /v1/Insights/Segments/{SegmentId}
# Returns: record<account_id: string, agent_id: string, agent_link: string, agent_name: string, agent_phone: string, agent_team_name: string, agent_team_name_in_hierarchy: string, assessment_percentage: any, assessment_type: any, customer_link: string, customer_name: string, customer_phone: string, date: string, external_contact: string, external_id: string, external_segment_link: string, external_segment_link_id: string, media: any, queue: string, segment_id: string, segment_recording_offset: string, url: string>
# operationId: FetchInsightsSegments
export def "fetch-insights-segments" [
  segment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # The Token HTTP request header (spec name: Token)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/Insights/Segments/{SegmentId}"
    path_params: [{name: SegmentId, var: segment_id}]
    header: [{name: Token, var: hdr_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://flex-api.twilio.com"
    auth: basic
  } {
    segment_id: $segment_id, hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# To obtain session details for fetching reports and dashboards
#
# POST /v1/Insights/Session
# Returns: record<base_url: string, session_expiry: string, session_id: string, url: string, workspace_id: string>
# operationId: CreateInsightsSession
export def "create-insights-session" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The Authorization HTTP request header
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/v1/Insights/Session"
    header: [{name: Authorization, var: authorization}]
    accept: ["application/json"]
    ok: [201]
    base_url: "https://flex-api.twilio.com"
    auth: basic
  } {
    authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This is used by Flex UI and Quality Management to fetch the Flex Insights roles for the user
#
# GET /v1/Insights/UserRoles
# Returns: record<roles: list<string>, url: string>
# operationId: FetchInsightsUserRoles
export def "fetch-insights-user-roles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The Authorization HTTP request header
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/Insights/UserRoles"
    header: [{name: Authorization, var: authorization}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://flex-api.twilio.com"
    auth: basic
  } {
    authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new Interaction.
#
# POST /v1/Interactions
# Returns: record<channel: any, links: record, routing: any, sid: string, url: string>
# operationId: CreateInteraction
export def "create-interaction" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  channel: any # The Interaction's channel.
  routing: any # The Interaction's routing logic.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Interactions"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Channel, var: channel}, {name: Routing, var: routing}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://flex-api.twilio.com"
    auth: basic
  } {
    channel: $channel, routing: $routing
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all Channels for an Interaction.
#
# GET /v1/Interactions/{InteractionSid}/Channels
# Returns: record<channels: table<error_code: int, error_message: string, interaction_sid: string, links: record, sid: string, status: string, type: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListInteractionChannel
export def "list-interaction-channel" [
  interaction_sid: string
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
    path: "/v1/Interactions/{InteractionSid}/Channels"
    path_params: [{name: InteractionSid, var: interaction_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://flex-api.twilio.com"
    auth: basic
  } {
    interaction_sid: $interaction_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all Invites for a Channel.
#
# GET /v1/Interactions/{InteractionSid}/Channels/{ChannelSid}/Invites
# Returns: record<invites: table<channel_sid: string, interaction_sid: string, routing: any, sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListInteractionChannelInvite
export def "list-interaction-channel-invite" [
  interaction_sid: string
  channel_sid: string
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
    path: "/v1/Interactions/{InteractionSid}/Channels/{ChannelSid}/Invites"
    path_params: [{name: InteractionSid, var: interaction_sid}, {name: ChannelSid, var: channel_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://flex-api.twilio.com"
    auth: basic
  } {
    interaction_sid: $interaction_sid, channel_sid: $channel_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Invite an Agent or a TaskQueue to a Channel.
#
# POST /v1/Interactions/{InteractionSid}/Channels/{ChannelSid}/Invites
# Returns: record<channel_sid: string, interaction_sid: string, routing: any, sid: string, url: string>
# operationId: CreateInteractionChannelInvite
export def "create-interaction-channel-invite" [
  interaction_sid: string
  channel_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  routing: any # The Interaction's routing logic.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Interactions/{InteractionSid}/Channels/{ChannelSid}/Invites"
    path_params: [{name: InteractionSid, var: interaction_sid}, {name: ChannelSid, var: channel_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Routing, var: routing}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://flex-api.twilio.com"
    auth: basic
  } {
    interaction_sid: $interaction_sid, channel_sid: $channel_sid, routing: $routing
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all Participants for a Channel.
#
# GET /v1/Interactions/{InteractionSid}/Channels/{ChannelSid}/Participants
# Returns: record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, participants: table<channel_sid: string, interaction_sid: string, sid: string, type: string, url: string>>
# operationId: ListInteractionChannelParticipant
export def "list-interaction-channel-participant" [
  interaction_sid: string
  channel_sid: string
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
    path: "/v1/Interactions/{InteractionSid}/Channels/{ChannelSid}/Participants"
    path_params: [{name: InteractionSid, var: interaction_sid}, {name: ChannelSid, var: channel_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://flex-api.twilio.com"
    auth: basic
  } {
    interaction_sid: $interaction_sid, channel_sid: $channel_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a Participant to a Channel.
#
# POST /v1/Interactions/{InteractionSid}/Channels/{ChannelSid}/Participants
# Returns: record<channel_sid: string, interaction_sid: string, sid: string, type: string, url: string>
# operationId: CreateInteractionChannelParticipant
export def "create-interaction-channel-participant" [
  interaction_sid: string
  channel_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  media_properties: any # JSON representing the Media Properties for the new Participant.
  type: string@type-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Interactions/{InteractionSid}/Channels/{ChannelSid}/Participants"
    path_params: [{name: InteractionSid, var: interaction_sid}, {name: ChannelSid, var: channel_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: MediaProperties, var: media_properties}, {name: Type, var: type}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://flex-api.twilio.com"
    auth: basic
  } {
    interaction_sid: $interaction_sid, channel_sid: $channel_sid, media_properties: $media_properties, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing Channel Participant.
#
# POST /v1/Interactions/{InteractionSid}/Channels/{ChannelSid}/Participants/{Sid}
# Returns: record<channel_sid: string, interaction_sid: string, sid: string, type: string, url: string>
# operationId: UpdateInteractionChannelParticipant
export def "update-interaction-channel-participant" [
  interaction_sid: string
  channel_sid: string
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
  status: string@status-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Interactions/{InteractionSid}/Channels/{ChannelSid}/Participants/{Sid}"
    path_params: [{name: InteractionSid, var: interaction_sid}, {name: ChannelSid, var: channel_sid}, {name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://flex-api.twilio.com"
    auth: basic
  } {
    interaction_sid: $interaction_sid, channel_sid: $channel_sid, sid: $sid, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a Channel for an Interaction.
#
# GET /v1/Interactions/{InteractionSid}/Channels/{Sid}
# Returns: record<error_code: int, error_message: string, interaction_sid: string, links: record, sid: string, status: string, type: string, url: string>
# operationId: FetchInteractionChannel
export def "fetch-interaction-channel" [
  interaction_sid: string
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
    path: "/v1/Interactions/{InteractionSid}/Channels/{Sid}"
    path_params: [{name: InteractionSid, var: interaction_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://flex-api.twilio.com"
    auth: basic
  } {
    interaction_sid: $interaction_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing Interaction Channel.
#
# POST /v1/Interactions/{InteractionSid}/Channels/{Sid}
# Returns: record<error_code: int, error_message: string, interaction_sid: string, links: record, sid: string, status: string, type: string, url: string>
# operationId: UpdateInteractionChannel
export def "update-interaction-channel" [
  interaction_sid: string
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
  --routing: any # Optional. The state of associated tasks. If not specified, all tasks will be set to `wrapping`.
  status: string@status-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Interactions/{InteractionSid}/Channels/{Sid}"
    path_params: [{name: InteractionSid, var: interaction_sid}, {name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Routing, var: routing}, {name: Status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://flex-api.twilio.com"
    auth: basic
  } {
    interaction_sid: $interaction_sid, sid: $sid, routing: $routing, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Interactions/{Sid}
#
# Returns: record<channel: any, links: record, routing: any, sid: string, url: string>
# operationId: FetchInteraction
export def "fetch-interaction" [
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
    path: "/v1/Interactions/{Sid}"
    path_params: [{name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://flex-api.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/WebChannels
#
# Returns: record<flex_chat_channels: table<account_sid: string, date_created: string, date_updated: string, flex_flow_sid: string, sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListWebChannel
export def "list-web-channel" [
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
    path: "/v1/WebChannels"
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://flex-api.twilio.com"
    auth: basic
  } {
    page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/WebChannels
#
# Returns: record<account_sid: string, date_created: string, date_updated: string, flex_flow_sid: string, sid: string, url: string>
# operationId: CreateWebChannel
export def "create-web-channel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  chat_friendly_name: string # The chat channel's friendly name.
  --chat-unique-name: string # The chat channel's unique name.
  customer_friendly_name: string # The chat participant's friendly name.
  flex_flow_sid: string # The SID of the Flex Flow.
  identity: string # The chat identity.
  --pre-engagement-data: string # The pre-engagement data.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/WebChannels"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: ChatFriendlyName, var: chat_friendly_name}, {name: ChatUniqueName, var: chat_unique_name}, {name: CustomerFriendlyName, var: customer_friendly_name}, {name: FlexFlowSid, var: flex_flow_sid}, {name: Identity, var: identity}, {name: PreEngagementData, var: pre_engagement_data}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://flex-api.twilio.com"
    auth: basic
  } {
    chat_friendly_name: $chat_friendly_name, chat_unique_name: $chat_unique_name, customer_friendly_name: $customer_friendly_name, flex_flow_sid: $flex_flow_sid, identity: $identity, pre_engagement_data: $pre_engagement_data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/WebChannels/{Sid}
#
# operationId: DeleteWebChannel
export def "delete-web-channel" [
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
    path: "/v1/WebChannels/{Sid}"
    path_params: [{name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://flex-api.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/WebChannels/{Sid}
#
# Returns: record<account_sid: string, date_created: string, date_updated: string, flex_flow_sid: string, sid: string, url: string>
# operationId: FetchWebChannel
export def "fetch-web-channel" [
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
    path: "/v1/WebChannels/{Sid}"
    path_params: [{name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://flex-api.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/WebChannels/{Sid}
#
# Returns: record<account_sid: string, date_created: string, date_updated: string, flex_flow_sid: string, sid: string, url: string>
# operationId: UpdateWebChannel
export def "update-web-channel" [
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
  --chat-status: string@chat-status-completer
  --post-engagement-data: string # The post-engagement data.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/WebChannels/{Sid}"
    path_params: [{name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: ChatStatus, var: chat_status}, {name: PostEngagementData, var: post_engagement_data}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://flex-api.twilio.com"
    auth: basic
  } {
    sid: $sid, chat_status: $chat_status, post_engagement_data: $post_engagement_data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
