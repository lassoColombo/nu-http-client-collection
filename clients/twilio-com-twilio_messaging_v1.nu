# Auto-generated client for Twilio - Messaging v1.42.0
# Source: https://api.apis.guru/v2/specs/twilio.com/twilio_messaging_v1/1.42.0/openapi.json
# Auth: --token flag or $env.TWILIO_MESSAGING_TOKEN

const CLIENT = {
  base_url: "https://messaging.twilio.com"
  token_env_var: "TWILIO_MESSAGING_TOKEN"
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

def base-url-completer [] { ["https://messaging.twilio.com"] }
def auth-scheme-completer [] { ["basic" "basic-credentials"] }

# Completers for enum parameters
def fallback-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def inbound-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def scan-message-content-completer [] { ["disable" "enable" "inherit"] }
def status-completer [] { ["IN_REVIEW" "PENDING_REVIEW" "TWILIO_APPROVED" "TWILIO_REJECTED"] }
def opt-in-type-completer [] { ["MOBILE_QR_CODE" "PAPER_FORM" "VERBAL" "VIA_TEXT" "WEB_FORM"] }
def vetting-provider-completer [] { ["campaign-verify"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    fetch-domain-cert-v4: "record<cert_in_validation: any, certificate_sid: string, date_created: string, date_expires: string, date_updated: string, domain_name: string, domain_sid: string, url: string>"
    update-domain-cert-v4: "record<cert_in_validation: any, certificate_sid: string, date_created: string, date_expires: string, date_updated: string, domain_name: string, domain_sid: string, url: string>"
    fetch-domain-config: "record<callback_url: string, config_sid: string, date_created: string, date_updated: string, domain_sid: string, fallback_url: string, url: string>"
    update-domain-config: "record<callback_url: string, config_sid: string, date_created: string, date_updated: string, domain_sid: string, fallback_url: string, url: string>"
    create-linkshortening-messaging-service: "record<domain_sid: string, messaging_service_sid: string, url: string>"
    fetch-domain-config-messaging-service: "record<callback_url: string, config_sid: string, date_created: string, date_updated: string, domain_sid: string, fallback_url: string, messaging_service_sid: string, url: string>"
    list-service: "record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, services: table<account_sid: string, area_code_geomatch: bool, date_created: string, date_updated: string, fallback_method: string, fallback_to_long_code: bool, fallback_url: string, friendly_name: string, inbound_method: string, inbound_request_url: string, links: record, mms_converter: bool, scan_message_content: string, sid: string, smart_encoding: bool, status_callback: string, sticky_sender: bool, synchronous_validation: bool, url: string, us_app_to_person_registered: bool, use_inbound_webhook_on_number: bool, usecase: string, validity_period: int>>"
    create-service: "record<account_sid: string, area_code_geomatch: bool, date_created: string, date_updated: string, fallback_method: string, fallback_to_long_code: bool, fallback_url: string, friendly_name: string, inbound_method: string, inbound_request_url: string, links: record, mms_converter: bool, scan_message_content: string, sid: string, smart_encoding: bool, status_callback: string, sticky_sender: bool, synchronous_validation: bool, url: string, us_app_to_person_registered: bool, use_inbound_webhook_on_number: bool, usecase: string, validity_period: int>"
    create-external-campaign: "record<account_sid: string, campaign_id: string, date_created: string, messaging_service_sid: string, sid: string>"
    fetch-usecase: "record<usecases: list<any>>"
    list-us-app-to-person: "record<compliance: table<account_sid: string, brand_registration_sid: string, campaign_id: string, campaign_status: string, date_created: string, date_updated: string, description: string, has_embedded_links: bool, has_embedded_phone: bool, help_keywords: list, help_message: string, is_externally_registered: bool, message_flow: string, message_samples: list, messaging_service_sid: string, mock: bool, opt_in_keywords: list, opt_in_message: string, opt_out_keywords: list, opt_out_message: string, rate_limits: any, sid: string, url: string, us_app_to_person_usecase: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    create-us-app-to-person: "record<account_sid: string, brand_registration_sid: string, campaign_id: string, campaign_status: string, date_created: string, date_updated: string, description: string, has_embedded_links: bool, has_embedded_phone: bool, help_keywords: list<string>, help_message: string, is_externally_registered: bool, message_flow: string, message_samples: list<string>, messaging_service_sid: string, mock: bool, opt_in_keywords: list<string>, opt_in_message: string, opt_out_keywords: list<string>, opt_out_message: string, rate_limits: any, sid: string, url: string, us_app_to_person_usecase: string>"
    fetch-us-app-to-person-usecase: "record<us_app_to_person_usecases: list<any>>"
    fetch-us-app-to-person: "record<account_sid: string, brand_registration_sid: string, campaign_id: string, campaign_status: string, date_created: string, date_updated: string, description: string, has_embedded_links: bool, has_embedded_phone: bool, help_keywords: list<string>, help_message: string, is_externally_registered: bool, message_flow: string, message_samples: list<string>, messaging_service_sid: string, mock: bool, opt_in_keywords: list<string>, opt_in_message: string, opt_out_keywords: list<string>, opt_out_message: string, rate_limits: any, sid: string, url: string, us_app_to_person_usecase: string>"
    list-alpha-sender: "record<alpha_senders: table<account_sid: string, alpha_sender: string, capabilities: list, date_created: string, date_updated: string, service_sid: string, sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    create-alpha-sender: "record<account_sid: string, alpha_sender: string, capabilities: list<string>, date_created: string, date_updated: string, service_sid: string, sid: string, url: string>"
    fetch-alpha-sender: "record<account_sid: string, alpha_sender: string, capabilities: list<string>, date_created: string, date_updated: string, service_sid: string, sid: string, url: string>"
    list-phone-number: "record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, phone_numbers: table<account_sid: string, capabilities: list, country_code: string, date_created: string, date_updated: string, phone_number: string, service_sid: string, sid: string, url: string>>"
    create-phone-number: "record<account_sid: string, capabilities: list<string>, country_code: string, date_created: string, date_updated: string, phone_number: string, service_sid: string, sid: string, url: string>"
    fetch-phone-number: "record<account_sid: string, capabilities: list<string>, country_code: string, date_created: string, date_updated: string, phone_number: string, service_sid: string, sid: string, url: string>"
    list-short-code: "record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, short_codes: table<account_sid: string, capabilities: list, country_code: string, date_created: string, date_updated: string, service_sid: string, short_code: string, sid: string, url: string>>"
    create-short-code: "record<account_sid: string, capabilities: list<string>, country_code: string, date_created: string, date_updated: string, service_sid: string, short_code: string, sid: string, url: string>"
    fetch-short-code: "record<account_sid: string, capabilities: list<string>, country_code: string, date_created: string, date_updated: string, service_sid: string, short_code: string, sid: string, url: string>"
    fetch-service: "record<account_sid: string, area_code_geomatch: bool, date_created: string, date_updated: string, fallback_method: string, fallback_to_long_code: bool, fallback_url: string, friendly_name: string, inbound_method: string, inbound_request_url: string, links: record, mms_converter: bool, scan_message_content: string, sid: string, smart_encoding: bool, status_callback: string, sticky_sender: bool, synchronous_validation: bool, url: string, us_app_to_person_registered: bool, use_inbound_webhook_on_number: bool, usecase: string, validity_period: int>"
    update-service: "record<account_sid: string, area_code_geomatch: bool, date_created: string, date_updated: string, fallback_method: string, fallback_to_long_code: bool, fallback_url: string, friendly_name: string, inbound_method: string, inbound_request_url: string, links: record, mms_converter: bool, scan_message_content: string, sid: string, smart_encoding: bool, status_callback: string, sticky_sender: bool, synchronous_validation: bool, url: string, us_app_to_person_registered: bool, use_inbound_webhook_on_number: bool, usecase: string, validity_period: int>"
    list-tollfree-verification: "record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, verifications: table<account_sid: string, additional_information: string, business_city: string, business_contact_email: string, business_contact_first_name: string, business_contact_last_name: string, business_contact_phone: string, business_country: string, business_name: string, business_postal_code: string, business_state_province_region: string, business_street_address: string, business_street_address2: string, business_website: string, customer_profile_sid: string, date_created: string, date_updated: string, error_code: int, external_reference_id: string, message_volume: string, notification_email: string, opt_in_image_urls: list, opt_in_type: string, production_message_sample: string, regulated_item_sid: string, rejection_reason: string, resource_links: any, sid: string, status: string, tollfree_phone_number_sid: string, trust_product_sid: string, url: string, use_case_categories: list, use_case_summary: string>>"
    create-tollfree-verification: "record<account_sid: string, additional_information: string, business_city: string, business_contact_email: string, business_contact_first_name: string, business_contact_last_name: string, business_contact_phone: string, business_country: string, business_name: string, business_postal_code: string, business_state_province_region: string, business_street_address: string, business_street_address2: string, business_website: string, customer_profile_sid: string, date_created: string, date_updated: string, error_code: int, external_reference_id: string, message_volume: string, notification_email: string, opt_in_image_urls: list<string>, opt_in_type: string, production_message_sample: string, regulated_item_sid: string, rejection_reason: string, resource_links: any, sid: string, status: string, tollfree_phone_number_sid: string, trust_product_sid: string, url: string, use_case_categories: list<string>, use_case_summary: string>"
    fetch-tollfree-verification: "record<account_sid: string, additional_information: string, business_city: string, business_contact_email: string, business_contact_first_name: string, business_contact_last_name: string, business_contact_phone: string, business_country: string, business_name: string, business_postal_code: string, business_state_province_region: string, business_street_address: string, business_street_address2: string, business_website: string, customer_profile_sid: string, date_created: string, date_updated: string, error_code: int, external_reference_id: string, message_volume: string, notification_email: string, opt_in_image_urls: list<string>, opt_in_type: string, production_message_sample: string, regulated_item_sid: string, rejection_reason: string, resource_links: any, sid: string, status: string, tollfree_phone_number_sid: string, trust_product_sid: string, url: string, use_case_categories: list<string>, use_case_summary: string>"
    update-tollfree-verification: "record<account_sid: string, additional_information: string, business_city: string, business_contact_email: string, business_contact_first_name: string, business_contact_last_name: string, business_contact_phone: string, business_country: string, business_name: string, business_postal_code: string, business_state_province_region: string, business_street_address: string, business_street_address2: string, business_website: string, customer_profile_sid: string, date_created: string, date_updated: string, error_code: int, external_reference_id: string, message_volume: string, notification_email: string, opt_in_image_urls: list<string>, opt_in_type: string, production_message_sample: string, regulated_item_sid: string, rejection_reason: string, resource_links: any, sid: string, status: string, tollfree_phone_number_sid: string, trust_product_sid: string, url: string, use_case_categories: list<string>, use_case_summary: string>"
    list-brand-registrations: "record<data: table<a2p_profile_bundle_sid: string, account_sid: string, brand_feedback: list, brand_score: int, brand_type: string, customer_profile_bundle_sid: string, date_created: string, date_updated: string, failure_reason: string, government_entity: bool, identity_status: string, links: record, mock: bool, russell_3000: bool, sid: string, skip_automatic_sec_vet: bool, status: string, tax_exempt_status: string, tcr_id: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    create-brand-registrations: "record<a2p_profile_bundle_sid: string, account_sid: string, brand_feedback: list<string>, brand_score: int, brand_type: string, customer_profile_bundle_sid: string, date_created: string, date_updated: string, failure_reason: string, government_entity: bool, identity_status: string, links: record, mock: bool, russell_3000: bool, sid: string, skip_automatic_sec_vet: bool, status: string, tax_exempt_status: string, tcr_id: string, url: string>"
    create-brand-registration-otp: "record<account_sid: string, brand_registration_sid: string>"
    list-brand-vetting: "record<data: table<account_sid: string, brand_sid: string, brand_vetting_sid: string, date_created: string, date_updated: string, url: string, vetting_class: string, vetting_id: string, vetting_provider: string, vetting_status: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    create-brand-vetting: "record<account_sid: string, brand_sid: string, brand_vetting_sid: string, date_created: string, date_updated: string, url: string, vetting_class: string, vetting_id: string, vetting_provider: string, vetting_status: string>"
    fetch-brand-vetting: "record<account_sid: string, brand_sid: string, brand_vetting_sid: string, date_created: string, date_updated: string, url: string, vetting_class: string, vetting_id: string, vetting_provider: string, vetting_status: string>"
    fetch-brand-registrations: "record<a2p_profile_bundle_sid: string, account_sid: string, brand_feedback: list<string>, brand_score: int, brand_type: string, customer_profile_bundle_sid: string, date_created: string, date_updated: string, failure_reason: string, government_entity: bool, identity_status: string, links: record, mock: bool, russell_3000: bool, sid: string, skip_automatic_sec_vet: bool, status: string, tax_exempt_status: string, tcr_id: string, url: string>"
    update-brand-registrations: "record<a2p_profile_bundle_sid: string, account_sid: string, brand_feedback: list<string>, brand_score: int, brand_type: string, customer_profile_bundle_sid: string, date_created: string, date_updated: string, failure_reason: string, government_entity: bool, identity_status: string, links: record, mock: bool, russell_3000: bool, sid: string, skip_automatic_sec_vet: bool, status: string, tax_exempt_status: string, tcr_id: string, url: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["fetch-deactivation" "delete-domain-cert-v4" "fetch-domain-cert-v4" "update-domain-cert-v4" "fetch-domain-config" "update-domain-config" "delete-linkshortening-messaging-service" "create-linkshortening-messaging-service" "fetch-domain-config-messaging-service" "list-service" "create-service" "create-external-campaign" "fetch-usecase" "list-us-app-to-person" "create-us-app-to-person" "fetch-us-app-to-person-usecase" "delete-us-app-to-person" "fetch-us-app-to-person" "list-alpha-sender" "create-alpha-sender" "delete-alpha-sender" "fetch-alpha-sender" "list-phone-number" "create-phone-number" "delete-phone-number" "fetch-phone-number" "list-short-code" "create-short-code" "delete-short-code" "fetch-short-code" "delete-service" "fetch-service" "update-service" "list-tollfree-verification" "create-tollfree-verification" "fetch-tollfree-verification" "update-tollfree-verification" "list-brand-registrations" "create-brand-registrations" "create-brand-registration-otp" "list-brand-vetting" "create-brand-vetting" "fetch-brand-vetting" "fetch-brand-registrations" "update-brand-registrations" "commands"] | sort) } | get name | first)
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

# Fetch a list of all United States numbers that have been deactivated on a specific date.
#
# GET /v1/Deactivations
# operationId: FetchDeactivation
export def "fetch-deactivation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date: string # The request will return a list of all United States Phone Numbers that were deactivated on the day specified by this parameter. This date should be specified in YYYY-MM-DD format. (format: date)
]: nothing -> any {
  http-request {
    method: get
    path: "/v1/Deactivations"
    query: [{name: Date, var: date}]
    accept: ["application/json"]
    ok: [307]
    base_url: "https://messaging.twilio.com"
    auth: basic
  } {
    date: $date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/LinkShortening/Domains/{DomainSid}/Certificate
#
# operationId: DeleteDomainCertV4
export def "delete-domain-cert-v4" [
  domain_sid: string
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
    path: "/v1/LinkShortening/Domains/{DomainSid}/Certificate"
    path_params: [{name: DomainSid, var: domain_sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://messaging.twilio.com"
    auth: basic
  } {
    domain_sid: $domain_sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/LinkShortening/Domains/{DomainSid}/Certificate
#
# Returns: record<cert_in_validation: any, certificate_sid: string, date_created: string, date_expires: string, date_updated: string, domain_name: string, domain_sid: string, url: string>
# operationId: FetchDomainCertV4
export def "fetch-domain-cert-v4" [
  domain_sid: string
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
    path: "/v1/LinkShortening/Domains/{DomainSid}/Certificate"
    path_params: [{name: DomainSid, var: domain_sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://messaging.twilio.com"
    auth: basic
  } {
    domain_sid: $domain_sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/LinkShortening/Domains/{DomainSid}/Certificate
#
# Returns: record<cert_in_validation: any, certificate_sid: string, date_created: string, date_expires: string, date_updated: string, domain_name: string, domain_sid: string, url: string>
# operationId: UpdateDomainCertV4
export def "update-domain-cert-v4" [
  domain_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  tls_cert: string # Contains the full TLS certificate and private for this domain in PEM format: https://en.wikipedia.org/wiki/Privacy-Enhanced_Mail. Twilio uses this information to process HTTPS traffic sent to your domain.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/LinkShortening/Domains/{DomainSid}/Certificate"
    path_params: [{name: DomainSid, var: domain_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: TlsCert, var: tls_cert}]}
    accept: ["application/json"]
    ok: [200, 201]
    base_url: "https://messaging.twilio.com"
    auth: basic
  } {
    domain_sid: $domain_sid, tls_cert: $tls_cert
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/LinkShortening/Domains/{DomainSid}/Config
#
# Returns: record<callback_url: string, config_sid: string, date_created: string, date_updated: string, domain_sid: string, fallback_url: string, url: string>
# operationId: FetchDomainConfig
export def "fetch-domain-config" [
  domain_sid: string
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
    path: "/v1/LinkShortening/Domains/{DomainSid}/Config"
    path_params: [{name: DomainSid, var: domain_sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://messaging.twilio.com"
    auth: basic
  } {
    domain_sid: $domain_sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/LinkShortening/Domains/{DomainSid}/Config
#
# Returns: record<callback_url: string, config_sid: string, date_created: string, date_updated: string, domain_sid: string, fallback_url: string, url: string>
# operationId: UpdateDomainConfig
export def "update-domain-config" [
  domain_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --callback-url: string # URL to receive click events to your webhook whenever the recipients click on the shortened links (format: uri)
  --fallback-url: string # Any requests we receive to this domain that do not match an existing shortened message will be redirected to the fallback url. These will likely be either expired messages, random misdirected traffic, or intentional scraping. (format: uri)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/LinkShortening/Domains/{DomainSid}/Config"
    path_params: [{name: DomainSid, var: domain_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: CallbackUrl, var: callback_url}, {name: FallbackUrl, var: fallback_url}]}
    accept: ["application/json"]
    ok: [200, 201]
    base_url: "https://messaging.twilio.com"
    auth: basic
  } {
    domain_sid: $domain_sid, callback_url: $callback_url, fallback_url: $fallback_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/LinkShortening/Domains/{DomainSid}/MessagingServices/{MessagingServiceSid}
#
# operationId: DeleteLinkshorteningMessagingService
export def "delete-linkshortening-messaging-service" [
  domain_sid: string
  messaging_service_sid: string
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
    path: "/v1/LinkShortening/Domains/{DomainSid}/MessagingServices/{MessagingServiceSid}"
    path_params: [{name: DomainSid, var: domain_sid}, {name: MessagingServiceSid, var: messaging_service_sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://messaging.twilio.com"
    auth: basic
  } {
    domain_sid: $domain_sid, messaging_service_sid: $messaging_service_sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/LinkShortening/Domains/{DomainSid}/MessagingServices/{MessagingServiceSid}
#
# Returns: record<domain_sid: string, messaging_service_sid: string, url: string>
# operationId: CreateLinkshorteningMessagingService
export def "create-linkshortening-messaging-service" [
  domain_sid: string
  messaging_service_sid: string
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
    path: "/v1/LinkShortening/Domains/{DomainSid}/MessagingServices/{MessagingServiceSid}"
    path_params: [{name: DomainSid, var: domain_sid}, {name: MessagingServiceSid, var: messaging_service_sid}]
    accept: ["application/json"]
    ok: [201]
    base_url: "https://messaging.twilio.com"
    auth: basic
  } {
    domain_sid: $domain_sid, messaging_service_sid: $messaging_service_sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/LinkShortening/MessagingService/{MessagingServiceSid}/DomainConfig
#
# Returns: record<callback_url: string, config_sid: string, date_created: string, date_updated: string, domain_sid: string, fallback_url: string, messaging_service_sid: string, url: string>
# operationId: FetchDomainConfigMessagingService
export def "fetch-domain-config-messaging-service" [
  messaging_service_sid: string
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
    path: "/v1/LinkShortening/MessagingService/{MessagingServiceSid}/DomainConfig"
    path_params: [{name: MessagingServiceSid, var: messaging_service_sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://messaging.twilio.com"
    auth: basic
  } {
    messaging_service_sid: $messaging_service_sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Services
#
# Returns: record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, services: table<account_sid: string, area_code_geomatch: bool, date_created: string, date_updated: string, fallback_method: string, fallback_to_long_code: bool, fallback_url: string, friendly_name: string, inbound_method: string, inbound_request_url: string, links: record, mms_converter: bool, scan_message_content: string, sid: string, smart_encoding: bool, status_callback: string, sticky_sender: bool, synchronous_validation: bool, url: string, us_app_to_person_registered: bool, use_inbound_webhook_on_number: bool, usecase: string, validity_period: int>>
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
    path: "/v1/Services"
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://messaging.twilio.com"
    auth: basic
  } {
    page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Services
#
# Returns: record<account_sid: string, area_code_geomatch: bool, date_created: string, date_updated: string, fallback_method: string, fallback_to_long_code: bool, fallback_url: string, friendly_name: string, inbound_method: string, inbound_request_url: string, links: record, mms_converter: bool, scan_message_content: string, sid: string, smart_encoding: bool, status_callback: string, sticky_sender: bool, synchronous_validation: bool, url: string, us_app_to_person_registered: bool, use_inbound_webhook_on_number: bool, usecase: string, validity_period: int>
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
  --area-code-geomatch: oneof<nothing, bool> # Whether to enable [Area Code Geomatch](https://www.twilio.com/docs/sms/services#area-code-geomatch) on the Service Instance.
  --fallback-method: string@fallback-method-completer # The HTTP method we should use to call `fallback_url`. Can be: `GET` or `POST`. (format: http-method)
  --fallback-to-long-code: oneof<nothing, bool> # Whether to enable [Fallback to Long Code](https://www.twilio.com/docs/sms/services#fallback-to-long-code) for messages sent through the Service instance.
  --fallback-url: string # The URL that we call using `fallback_method` if an error occurs while retrieving or executing the TwiML from the Inbound Request URL. If the `use_inbound_webhook_on_number` field is enabled then the webhook url defined on the phone number will override the `fallback_url` defined for the Messaging Service. (format: uri)
  friendly_name: string # A descriptive string that you create to describe the resource. It can be up to 64 characters long.
  --inbound-method: string@inbound-method-completer # The HTTP method we should use to call `inbound_request_url`. Can be `GET` or `POST` and the default is `POST`. (format: http-method)
  --inbound-request-url: string # The URL we call using `inbound_method` when a message is received by any phone number or short code in the Service. When this property is `null`, receiving inbound messages is disabled. All messages sent to the Twilio phone number or short code will not be logged and received on the Account. If the `use_inbound_webhook_on_number` field is enabled then the webhook url defined on the phone number will override the `inbound_request_url` defined for the Messaging Service. (format: uri)
  --mms-converter: oneof<nothing, bool> # Whether to enable the [MMS Converter](https://www.twilio.com/docs/sms/services#mms-converter) for messages sent through the Service instance.
  --scan-message-content: string@scan-message-content-completer
  --smart-encoding: oneof<nothing, bool> # Whether to enable [Smart Encoding](https://www.twilio.com/docs/sms/services#smart-encoding) for messages sent through the Service instance.
  --status-callback: string # The URL we should call to [pass status updates](https://www.twilio.com/docs/sms/api/message-resource#message-status-values) about message delivery. (format: uri)
  --sticky-sender: oneof<nothing, bool> # Whether to enable [Sticky Sender](https://www.twilio.com/docs/sms/services#sticky-sender) on the Service instance.
  --synchronous-validation: oneof<nothing, bool> # Reserved.
  --use-inbound-webhook-on-number: oneof<nothing, bool> # A boolean value that indicates either the webhook url configured on the phone number will be used or `inbound_request_url`/`fallback_url` url will be called when a message is received from the phone number. If this field is enabled then the webhook url defined on the phone number will override the `inbound_request_url`/`fallback_url` defined for the Messaging Service.
  --usecase: string # A string that describes the scenario in which the Messaging Service will be used. Examples: [notification, marketing, verification, poll ..].
  --validity-period: int # How long, in seconds, messages sent from the Service are valid. Can be an integer from `1` to `14,400`.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Services"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: AreaCodeGeomatch, var: area_code_geomatch}, {name: FallbackMethod, var: fallback_method}, {name: FallbackToLongCode, var: fallback_to_long_code}, {name: FallbackUrl, var: fallback_url}, {name: FriendlyName, var: friendly_name}, {name: InboundMethod, var: inbound_method}, {name: InboundRequestUrl, var: inbound_request_url}, {name: MmsConverter, var: mms_converter}, {name: ScanMessageContent, var: scan_message_content}, {name: SmartEncoding, var: smart_encoding}, {name: StatusCallback, var: status_callback}, {name: StickySender, var: sticky_sender}, {name: SynchronousValidation, var: synchronous_validation}, {name: UseInboundWebhookOnNumber, var: use_inbound_webhook_on_number}, {name: Usecase, var: usecase}, {name: ValidityPeriod, var: validity_period}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://messaging.twilio.com"
    auth: basic
  } {
    area_code_geomatch: $area_code_geomatch, fallback_method: $fallback_method, fallback_to_long_code: $fallback_to_long_code, fallback_url: $fallback_url, friendly_name: $friendly_name, inbound_method: $inbound_method, inbound_request_url: $inbound_request_url, mms_converter: $mms_converter, scan_message_content: $scan_message_content, smart_encoding: $smart_encoding, status_callback: $status_callback, sticky_sender: $sticky_sender, synchronous_validation: $synchronous_validation, use_inbound_webhook_on_number: $use_inbound_webhook_on_number, usecase: $usecase, validity_period: $validity_period
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Services/PreregisteredUsa2p
#
# Returns: record<account_sid: string, campaign_id: string, date_created: string, messaging_service_sid: string, sid: string>
# operationId: CreateExternalCampaign
export def "create-external-campaign" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  campaign_id: string # ID of the preregistered campaign.
  messaging_service_sid: string # The SID of the [Messaging Service](https://www.twilio.com/docs/messaging/services/api) that the resource is associated with.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Services/PreregisteredUsa2p"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: CampaignId, var: campaign_id}, {name: MessagingServiceSid, var: messaging_service_sid}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://messaging.twilio.com"
    auth: basic
  } {
    campaign_id: $campaign_id, messaging_service_sid: $messaging_service_sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Services/Usecases
#
# Returns: record<usecases: list<any>>
# operationId: FetchUsecase
export def "fetch-usecase" [
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
    path: "/v1/Services/Usecases"
    accept: ["application/json"]
    ok: [200]
    base_url: "https://messaging.twilio.com"
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Services/{MessagingServiceSid}/Compliance/Usa2p
#
# Returns: record<compliance: table<account_sid: string, brand_registration_sid: string, campaign_id: string, campaign_status: string, date_created: string, date_updated: string, description: string, has_embedded_links: bool, has_embedded_phone: bool, help_keywords: list, help_message: string, is_externally_registered: bool, message_flow: string, message_samples: list, messaging_service_sid: string, mock: bool, opt_in_keywords: list, opt_in_message: string, opt_out_keywords: list, opt_out_message: string, rate_limits: any, sid: string, url: string, us_app_to_person_usecase: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListUsAppToPerson
export def "list-us-app-to-person" [
  messaging_service_sid: string
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
    path: "/v1/Services/{MessagingServiceSid}/Compliance/Usa2p"
    path_params: [{name: MessagingServiceSid, var: messaging_service_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://messaging.twilio.com"
    auth: basic
  } {
    messaging_service_sid: $messaging_service_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Services/{MessagingServiceSid}/Compliance/Usa2p
#
# Returns: record<account_sid: string, brand_registration_sid: string, campaign_id: string, campaign_status: string, date_created: string, date_updated: string, description: string, has_embedded_links: bool, has_embedded_phone: bool, help_keywords: list<string>, help_message: string, is_externally_registered: bool, message_flow: string, message_samples: list<string>, messaging_service_sid: string, mock: bool, opt_in_keywords: list<string>, opt_in_message: string, opt_out_keywords: list<string>, opt_out_message: string, rate_limits: any, sid: string, url: string, us_app_to_person_usecase: string>
# operationId: CreateUsAppToPerson
export def "create-us-app-to-person" [
  messaging_service_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  brand_registration_sid: string # A2P Brand Registration SID
  description: string # A short description of what this SMS campaign does. Min length: 40 characters. Max length: 4096 characters.
  --has-embedded-links: oneof<nothing, bool> # Indicates that this SMS campaign will send messages that contain links.
  --has-embedded-phone: oneof<nothing, bool> # Indicates that this SMS campaign will send messages that contain phone numbers.
  --help-keywords: list<string> # End users should be able to text in a keyword to receive help. Those keywords must be provided as part of the campaign registration request. This field is required if managing help keywords yourself (i.e. not using Twilio's Default or Advanced Opt Out features). Values must be alphanumeric. 255 character maximum.
  --help-message: string # When customers receive the help keywords from their end users, Twilio customers are expected to send back an auto-generated response; this may include the brand name and additional support contact information. This field is required if managing help keywords yourself (i.e. not using Twilio's Default or Advanced Opt Out features). 20 character minimum. 320 character maximum.
  message_flow: string # Required for all Campaigns. Details around how a consumer opts-in to their campaign, therefore giving consent to receive their messages. If multiple opt-in methods can be used for the same campaign, they must all be listed. 40 character minimum. 2048 character maximum.
  message_samples: list<string> # Message samples, at least 1 and up to 5 sample messages (at least 2 for sole proprietor), >=20 chars, <=1024 chars each.
  --opt-in-keywords: list<string> # If end users can text in a keyword to start receiving messages from this campaign, those keywords must be provided. This field is required if end users can text in a keyword to start receiving messages from this campaign. Values must be alphanumeric. 255 character maximum.
  --opt-in-message: string # If end users can text in a keyword to start receiving messages from this campaign, the auto-reply messages sent to the end users must be provided. The opt-in response should include the Brand name, confirmation of opt-in enrollment to a recurring message campaign, how to get help, and clear description of how to opt-out. This field is required if end users can text in a keyword to start receiving messages from this campaign. 20 character minimum. 320 character maximum.
  --opt-out-keywords: list<string> # End users should be able to text in a keyword to stop receiving messages from this campaign. Those keywords must be provided. This field is required if managing opt out keywords yourself (i.e. not using Twilio's Default or Advanced Opt Out features). Values must be alphanumeric. 255 character maximum.
  --opt-out-message: string # Upon receiving the opt-out keywords from the end users, Twilio customers are expected to send back an auto-generated response, which must provide acknowledgment of the opt-out request and confirmation that no further messages will be sent. It is also recommended that these opt-out messages include the brand name. This field is required if managing opt out keywords yourself (i.e. not using Twilio's Default or Advanced Opt Out features). 20 character minimum. 320 character maximum.
  us_app_to_person_usecase: string # A2P Campaign Use Case. Examples: [ 2FA, EMERGENCY, MARKETING..]
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Services/{MessagingServiceSid}/Compliance/Usa2p"
    path_params: [{name: MessagingServiceSid, var: messaging_service_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: BrandRegistrationSid, var: brand_registration_sid}, {name: Description, var: description}, {name: HasEmbeddedLinks, var: has_embedded_links, required: true}, {name: HasEmbeddedPhone, var: has_embedded_phone, required: true}, {name: HelpKeywords, var: help_keywords}, {name: HelpMessage, var: help_message}, {name: MessageFlow, var: message_flow}, {name: MessageSamples, var: message_samples}, {name: OptInKeywords, var: opt_in_keywords}, {name: OptInMessage, var: opt_in_message}, {name: OptOutKeywords, var: opt_out_keywords}, {name: OptOutMessage, var: opt_out_message}, {name: UsAppToPersonUsecase, var: us_app_to_person_usecase}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://messaging.twilio.com"
    auth: basic
  } {
    messaging_service_sid: $messaging_service_sid, brand_registration_sid: $brand_registration_sid, description: $description, has_embedded_links: $has_embedded_links, has_embedded_phone: $has_embedded_phone, help_keywords: $help_keywords, help_message: $help_message, message_flow: $message_flow, message_samples: $message_samples, opt_in_keywords: $opt_in_keywords, opt_in_message: $opt_in_message, opt_out_keywords: $opt_out_keywords, opt_out_message: $opt_out_message, us_app_to_person_usecase: $us_app_to_person_usecase
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Services/{MessagingServiceSid}/Compliance/Usa2p/Usecases
#
# Returns: record<us_app_to_person_usecases: list<any>>
# operationId: FetchUsAppToPersonUsecase
export def "fetch-us-app-to-person-usecase" [
  messaging_service_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --brand-registration-sid: string # The unique string to identify the A2P brand.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/Services/{MessagingServiceSid}/Compliance/Usa2p/Usecases"
    path_params: [{name: MessagingServiceSid, var: messaging_service_sid}]
    query: [{name: BrandRegistrationSid, var: brand_registration_sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://messaging.twilio.com"
    auth: basic
  } {
    messaging_service_sid: $messaging_service_sid, brand_registration_sid: $brand_registration_sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/Services/{MessagingServiceSid}/Compliance/Usa2p/{Sid}
#
# operationId: DeleteUsAppToPerson
export def "delete-us-app-to-person" [
  messaging_service_sid: string
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
    path: "/v1/Services/{MessagingServiceSid}/Compliance/Usa2p/{Sid}"
    path_params: [{name: MessagingServiceSid, var: messaging_service_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://messaging.twilio.com"
    auth: basic
  } {
    messaging_service_sid: $messaging_service_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Services/{MessagingServiceSid}/Compliance/Usa2p/{Sid}
#
# Returns: record<account_sid: string, brand_registration_sid: string, campaign_id: string, campaign_status: string, date_created: string, date_updated: string, description: string, has_embedded_links: bool, has_embedded_phone: bool, help_keywords: list<string>, help_message: string, is_externally_registered: bool, message_flow: string, message_samples: list<string>, messaging_service_sid: string, mock: bool, opt_in_keywords: list<string>, opt_in_message: string, opt_out_keywords: list<string>, opt_out_message: string, rate_limits: any, sid: string, url: string, us_app_to_person_usecase: string>
# operationId: FetchUsAppToPerson
export def "fetch-us-app-to-person" [
  messaging_service_sid: string
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
    path: "/v1/Services/{MessagingServiceSid}/Compliance/Usa2p/{Sid}"
    path_params: [{name: MessagingServiceSid, var: messaging_service_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://messaging.twilio.com"
    auth: basic
  } {
    messaging_service_sid: $messaging_service_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Services/{ServiceSid}/AlphaSenders
#
# Returns: record<alpha_senders: table<account_sid: string, alpha_sender: string, capabilities: list, date_created: string, date_updated: string, service_sid: string, sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListAlphaSender
export def "list-alpha-sender" [
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
    path: "/v1/Services/{ServiceSid}/AlphaSenders"
    path_params: [{name: ServiceSid, var: service_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://messaging.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Services/{ServiceSid}/AlphaSenders
#
# Returns: record<account_sid: string, alpha_sender: string, capabilities: list<string>, date_created: string, date_updated: string, service_sid: string, sid: string, url: string>
# operationId: CreateAlphaSender
export def "create-alpha-sender" [
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
  alpha_sender: string # The Alphanumeric Sender ID string. Can be up to 11 characters long. Valid characters are A-Z, a-z, 0-9, space, hyphen `-`, plus `+`, underscore `_` and ampersand `&`. This value cannot contain only numbers.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Services/{ServiceSid}/AlphaSenders"
    path_params: [{name: ServiceSid, var: service_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: AlphaSender, var: alpha_sender}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://messaging.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, alpha_sender: $alpha_sender
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/Services/{ServiceSid}/AlphaSenders/{Sid}
#
# operationId: DeleteAlphaSender
export def "delete-alpha-sender" [
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
    path: "/v1/Services/{ServiceSid}/AlphaSenders/{Sid}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://messaging.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Services/{ServiceSid}/AlphaSenders/{Sid}
#
# Returns: record<account_sid: string, alpha_sender: string, capabilities: list<string>, date_created: string, date_updated: string, service_sid: string, sid: string, url: string>
# operationId: FetchAlphaSender
export def "fetch-alpha-sender" [
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
    path: "/v1/Services/{ServiceSid}/AlphaSenders/{Sid}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://messaging.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Services/{ServiceSid}/PhoneNumbers
#
# Returns: record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, phone_numbers: table<account_sid: string, capabilities: list, country_code: string, date_created: string, date_updated: string, phone_number: string, service_sid: string, sid: string, url: string>>
# operationId: ListPhoneNumber
export def "list-phone-number" [
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
    path: "/v1/Services/{ServiceSid}/PhoneNumbers"
    path_params: [{name: ServiceSid, var: service_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://messaging.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Services/{ServiceSid}/PhoneNumbers
#
# Returns: record<account_sid: string, capabilities: list<string>, country_code: string, date_created: string, date_updated: string, phone_number: string, service_sid: string, sid: string, url: string>
# operationId: CreatePhoneNumber
export def "create-phone-number" [
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
  phone_number_sid: string # The SID of the Phone Number being added to the Service.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Services/{ServiceSid}/PhoneNumbers"
    path_params: [{name: ServiceSid, var: service_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: PhoneNumberSid, var: phone_number_sid}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://messaging.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, phone_number_sid: $phone_number_sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/Services/{ServiceSid}/PhoneNumbers/{Sid}
#
# operationId: DeletePhoneNumber
export def "delete-phone-number" [
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
    path: "/v1/Services/{ServiceSid}/PhoneNumbers/{Sid}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://messaging.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Services/{ServiceSid}/PhoneNumbers/{Sid}
#
# Returns: record<account_sid: string, capabilities: list<string>, country_code: string, date_created: string, date_updated: string, phone_number: string, service_sid: string, sid: string, url: string>
# operationId: FetchPhoneNumber
export def "fetch-phone-number" [
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
    path: "/v1/Services/{ServiceSid}/PhoneNumbers/{Sid}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://messaging.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Services/{ServiceSid}/ShortCodes
#
# Returns: record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, short_codes: table<account_sid: string, capabilities: list, country_code: string, date_created: string, date_updated: string, service_sid: string, short_code: string, sid: string, url: string>>
# operationId: ListShortCode
export def "list-short-code" [
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
    path: "/v1/Services/{ServiceSid}/ShortCodes"
    path_params: [{name: ServiceSid, var: service_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://messaging.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Services/{ServiceSid}/ShortCodes
#
# Returns: record<account_sid: string, capabilities: list<string>, country_code: string, date_created: string, date_updated: string, service_sid: string, short_code: string, sid: string, url: string>
# operationId: CreateShortCode
export def "create-short-code" [
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
  short_code_sid: string # The SID of the ShortCode resource being added to the Service.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Services/{ServiceSid}/ShortCodes"
    path_params: [{name: ServiceSid, var: service_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: ShortCodeSid, var: short_code_sid}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://messaging.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, short_code_sid: $short_code_sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/Services/{ServiceSid}/ShortCodes/{Sid}
#
# operationId: DeleteShortCode
export def "delete-short-code" [
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
    path: "/v1/Services/{ServiceSid}/ShortCodes/{Sid}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://messaging.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Services/{ServiceSid}/ShortCodes/{Sid}
#
# Returns: record<account_sid: string, capabilities: list<string>, country_code: string, date_created: string, date_updated: string, service_sid: string, short_code: string, sid: string, url: string>
# operationId: FetchShortCode
export def "fetch-short-code" [
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
    path: "/v1/Services/{ServiceSid}/ShortCodes/{Sid}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://messaging.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, sid: $sid
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
    base_url: "https://messaging.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Services/{Sid}
#
# Returns: record<account_sid: string, area_code_geomatch: bool, date_created: string, date_updated: string, fallback_method: string, fallback_to_long_code: bool, fallback_url: string, friendly_name: string, inbound_method: string, inbound_request_url: string, links: record, mms_converter: bool, scan_message_content: string, sid: string, smart_encoding: bool, status_callback: string, sticky_sender: bool, synchronous_validation: bool, url: string, us_app_to_person_registered: bool, use_inbound_webhook_on_number: bool, usecase: string, validity_period: int>
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
    base_url: "https://messaging.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Services/{Sid}
#
# Returns: record<account_sid: string, area_code_geomatch: bool, date_created: string, date_updated: string, fallback_method: string, fallback_to_long_code: bool, fallback_url: string, friendly_name: string, inbound_method: string, inbound_request_url: string, links: record, mms_converter: bool, scan_message_content: string, sid: string, smart_encoding: bool, status_callback: string, sticky_sender: bool, synchronous_validation: bool, url: string, us_app_to_person_registered: bool, use_inbound_webhook_on_number: bool, usecase: string, validity_period: int>
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
  --area-code-geomatch: oneof<nothing, bool> # Whether to enable [Area Code Geomatch](https://www.twilio.com/docs/sms/services#area-code-geomatch) on the Service Instance.
  --fallback-method: string@fallback-method-completer # The HTTP method we should use to call `fallback_url`. Can be: `GET` or `POST`. (format: http-method)
  --fallback-to-long-code: oneof<nothing, bool> # Whether to enable [Fallback to Long Code](https://www.twilio.com/docs/sms/services#fallback-to-long-code) for messages sent through the Service instance.
  --fallback-url: string # The URL that we call using `fallback_method` if an error occurs while retrieving or executing the TwiML from the Inbound Request URL. If the `use_inbound_webhook_on_number` field is enabled then the webhook url defined on the phone number will override the `fallback_url` defined for the Messaging Service. (format: uri)
  --friendly-name: string # A descriptive string that you create to describe the resource. It can be up to 64 characters long.
  --inbound-method: string@inbound-method-completer # The HTTP method we should use to call `inbound_request_url`. Can be `GET` or `POST` and the default is `POST`. (format: http-method)
  --inbound-request-url: string # The URL we call using `inbound_method` when a message is received by any phone number or short code in the Service. When this property is `null`, receiving inbound messages is disabled. All messages sent to the Twilio phone number or short code will not be logged and received on the Account. If the `use_inbound_webhook_on_number` field is enabled then the webhook url defined on the phone number will override the `inbound_request_url` defined for the Messaging Service. (format: uri)
  --mms-converter: oneof<nothing, bool> # Whether to enable the [MMS Converter](https://www.twilio.com/docs/sms/services#mms-converter) for messages sent through the Service instance.
  --scan-message-content: string@scan-message-content-completer
  --smart-encoding: oneof<nothing, bool> # Whether to enable [Smart Encoding](https://www.twilio.com/docs/sms/services#smart-encoding) for messages sent through the Service instance.
  --status-callback: string # The URL we should call to [pass status updates](https://www.twilio.com/docs/sms/api/message-resource#message-status-values) about message delivery. (format: uri)
  --sticky-sender: oneof<nothing, bool> # Whether to enable [Sticky Sender](https://www.twilio.com/docs/sms/services#sticky-sender) on the Service instance.
  --synchronous-validation: oneof<nothing, bool> # Reserved.
  --use-inbound-webhook-on-number: oneof<nothing, bool> # A boolean value that indicates either the webhook url configured on the phone number will be used or `inbound_request_url`/`fallback_url` url will be called when a message is received from the phone number. If this field is enabled then the webhook url defined on the phone number will override the `inbound_request_url`/`fallback_url` defined for the Messaging Service.
  --usecase: string # A string that describes the scenario in which the Messaging Service will be used. Examples: [notification, marketing, verification, poll ..]
  --validity-period: int # How long, in seconds, messages sent from the Service are valid. Can be an integer from `1` to `14,400`.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Services/{Sid}"
    path_params: [{name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: AreaCodeGeomatch, var: area_code_geomatch}, {name: FallbackMethod, var: fallback_method}, {name: FallbackToLongCode, var: fallback_to_long_code}, {name: FallbackUrl, var: fallback_url}, {name: FriendlyName, var: friendly_name}, {name: InboundMethod, var: inbound_method}, {name: InboundRequestUrl, var: inbound_request_url}, {name: MmsConverter, var: mms_converter}, {name: ScanMessageContent, var: scan_message_content}, {name: SmartEncoding, var: smart_encoding}, {name: StatusCallback, var: status_callback}, {name: StickySender, var: sticky_sender}, {name: SynchronousValidation, var: synchronous_validation}, {name: UseInboundWebhookOnNumber, var: use_inbound_webhook_on_number}, {name: Usecase, var: usecase}, {name: ValidityPeriod, var: validity_period}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://messaging.twilio.com"
    auth: basic
  } {
    sid: $sid, area_code_geomatch: $area_code_geomatch, fallback_method: $fallback_method, fallback_to_long_code: $fallback_to_long_code, fallback_url: $fallback_url, friendly_name: $friendly_name, inbound_method: $inbound_method, inbound_request_url: $inbound_request_url, mms_converter: $mms_converter, scan_message_content: $scan_message_content, smart_encoding: $smart_encoding, status_callback: $status_callback, sticky_sender: $sticky_sender, synchronous_validation: $synchronous_validation, use_inbound_webhook_on_number: $use_inbound_webhook_on_number, usecase: $usecase, validity_period: $validity_period
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Tollfree/Verifications
#
# Returns: record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, verifications: table<account_sid: string, additional_information: string, business_city: string, business_contact_email: string, business_contact_first_name: string, business_contact_last_name: string, business_contact_phone: string, business_country: string, business_name: string, business_postal_code: string, business_state_province_region: string, business_street_address: string, business_street_address2: string, business_website: string, customer_profile_sid: string, date_created: string, date_updated: string, error_code: int, external_reference_id: string, message_volume: string, notification_email: string, opt_in_image_urls: list, opt_in_type: string, production_message_sample: string, regulated_item_sid: string, rejection_reason: string, resource_links: any, sid: string, status: string, tollfree_phone_number_sid: string, trust_product_sid: string, url: string, use_case_categories: list, use_case_summary: string>>
# operationId: ListTollfreeVerification
export def "list-tollfree-verification" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tollfree-phone-number-sid: string # The SID of the Phone Number associated with the Tollfree Verification.
  --status: string@status-completer # The compliance status of the Tollfree Verification record.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/Tollfree/Verifications"
    query: [{name: TollfreePhoneNumberSid, var: tollfree_phone_number_sid}, {name: Status, var: status}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://messaging.twilio.com"
    auth: basic
  } {
    tollfree_phone_number_sid: $tollfree_phone_number_sid, status: $status, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Tollfree/Verifications
#
# Returns: record<account_sid: string, additional_information: string, business_city: string, business_contact_email: string, business_contact_first_name: string, business_contact_last_name: string, business_contact_phone: string, business_country: string, business_name: string, business_postal_code: string, business_state_province_region: string, business_street_address: string, business_street_address2: string, business_website: string, customer_profile_sid: string, date_created: string, date_updated: string, error_code: int, external_reference_id: string, message_volume: string, notification_email: string, opt_in_image_urls: list<string>, opt_in_type: string, production_message_sample: string, regulated_item_sid: string, rejection_reason: string, resource_links: any, sid: string, status: string, tollfree_phone_number_sid: string, trust_product_sid: string, url: string, use_case_categories: list<string>, use_case_summary: string>
# operationId: CreateTollfreeVerification
export def "create-tollfree-verification" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --additional-information: string # Additional information to be provided for verification.
  --business-city: string # The city of the business or organization using the Tollfree number.
  --business-contact-email: string # The email address of the contact for the business or organization using the Tollfree number.
  --business-contact-first-name: string # The first name of the contact for the business or organization using the Tollfree number.
  --business-contact-last-name: string # The last name of the contact for the business or organization using the Tollfree number.
  --business-contact-phone: string # The phone number of the contact for the business or organization using the Tollfree number. (format: phone-number)
  --business-country: string # The country of the business or organization using the Tollfree number.
  business_name: string # The name of the business or organization using the Tollfree number.
  --business-postal-code: string # The postal code of the business or organization using the Tollfree number.
  --business-state-province-region: string # The state/province/region of the business or organization using the Tollfree number.
  --business-street-address: string # The address of the business or organization using the Tollfree number.
  --business-street-address2: string # The address of the business or organization using the Tollfree number.
  business_website: string # The website of the business or organization using the Tollfree number.
  --customer-profile-sid: string # Customer's Profile Bundle BundleSid.
  --external-reference-id: string # An optional external reference ID supplied by customer and echoed back on status retrieval.
  message_volume: string # Estimate monthly volume of messages from the Tollfree Number.
  notification_email: string # The email address to receive the notification about the verification result. .
  opt_in_image_urls: list<string> # Link to an image that shows the opt-in workflow. Multiple images allowed and must be a publicly hosted URL.
  opt_in_type: string@opt-in-type-completer
  production_message_sample: string # An example of message content, i.e. a sample message.
  tollfree_phone_number_sid: string # The SID of the Phone Number associated with the Tollfree Verification.
  use_case_categories: list<string> # The category of the use case for the Tollfree Number. List as many are applicable..
  use_case_summary: string # Use this to further explain how messaging is used by the business or organization.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Tollfree/Verifications"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: AdditionalInformation, var: additional_information}, {name: BusinessCity, var: business_city}, {name: BusinessContactEmail, var: business_contact_email}, {name: BusinessContactFirstName, var: business_contact_first_name}, {name: BusinessContactLastName, var: business_contact_last_name}, {name: BusinessContactPhone, var: business_contact_phone}, {name: BusinessCountry, var: business_country}, {name: BusinessName, var: business_name}, {name: BusinessPostalCode, var: business_postal_code}, {name: BusinessStateProvinceRegion, var: business_state_province_region}, {name: BusinessStreetAddress, var: business_street_address}, {name: BusinessStreetAddress2, var: business_street_address2}, {name: BusinessWebsite, var: business_website}, {name: CustomerProfileSid, var: customer_profile_sid}, {name: ExternalReferenceId, var: external_reference_id}, {name: MessageVolume, var: message_volume}, {name: NotificationEmail, var: notification_email}, {name: OptInImageUrls, var: opt_in_image_urls}, {name: OptInType, var: opt_in_type}, {name: ProductionMessageSample, var: production_message_sample}, {name: TollfreePhoneNumberSid, var: tollfree_phone_number_sid}, {name: UseCaseCategories, var: use_case_categories}, {name: UseCaseSummary, var: use_case_summary}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://messaging.twilio.com"
    auth: basic
  } {
    additional_information: $additional_information, business_city: $business_city, business_contact_email: $business_contact_email, business_contact_first_name: $business_contact_first_name, business_contact_last_name: $business_contact_last_name, business_contact_phone: $business_contact_phone, business_country: $business_country, business_name: $business_name, business_postal_code: $business_postal_code, business_state_province_region: $business_state_province_region, business_street_address: $business_street_address, business_street_address2: $business_street_address2, business_website: $business_website, customer_profile_sid: $customer_profile_sid, external_reference_id: $external_reference_id, message_volume: $message_volume, notification_email: $notification_email, opt_in_image_urls: $opt_in_image_urls, opt_in_type: $opt_in_type, production_message_sample: $production_message_sample, tollfree_phone_number_sid: $tollfree_phone_number_sid, use_case_categories: $use_case_categories, use_case_summary: $use_case_summary
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Tollfree/Verifications/{Sid}
#
# Returns: record<account_sid: string, additional_information: string, business_city: string, business_contact_email: string, business_contact_first_name: string, business_contact_last_name: string, business_contact_phone: string, business_country: string, business_name: string, business_postal_code: string, business_state_province_region: string, business_street_address: string, business_street_address2: string, business_website: string, customer_profile_sid: string, date_created: string, date_updated: string, error_code: int, external_reference_id: string, message_volume: string, notification_email: string, opt_in_image_urls: list<string>, opt_in_type: string, production_message_sample: string, regulated_item_sid: string, rejection_reason: string, resource_links: any, sid: string, status: string, tollfree_phone_number_sid: string, trust_product_sid: string, url: string, use_case_categories: list<string>, use_case_summary: string>
# operationId: FetchTollfreeVerification
export def "fetch-tollfree-verification" [
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
    path: "/v1/Tollfree/Verifications/{Sid}"
    path_params: [{name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://messaging.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Tollfree/Verifications/{Sid}
#
# Returns: record<account_sid: string, additional_information: string, business_city: string, business_contact_email: string, business_contact_first_name: string, business_contact_last_name: string, business_contact_phone: string, business_country: string, business_name: string, business_postal_code: string, business_state_province_region: string, business_street_address: string, business_street_address2: string, business_website: string, customer_profile_sid: string, date_created: string, date_updated: string, error_code: int, external_reference_id: string, message_volume: string, notification_email: string, opt_in_image_urls: list<string>, opt_in_type: string, production_message_sample: string, regulated_item_sid: string, rejection_reason: string, resource_links: any, sid: string, status: string, tollfree_phone_number_sid: string, trust_product_sid: string, url: string, use_case_categories: list<string>, use_case_summary: string>
# operationId: UpdateTollfreeVerification
export def "update-tollfree-verification" [
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
  --additional-information: string # Additional information to be provided for verification.
  --business-city: string # The city of the business or organization using the Tollfree number.
  --business-contact-email: string # The email address of the contact for the business or organization using the Tollfree number.
  --business-contact-first-name: string # The first name of the contact for the business or organization using the Tollfree number.
  --business-contact-last-name: string # The last name of the contact for the business or organization using the Tollfree number.
  --business-contact-phone: string # The phone number of the contact for the business or organization using the Tollfree number. (format: phone-number)
  --business-country: string # The country of the business or organization using the Tollfree number.
  --business-name: string # The name of the business or organization using the Tollfree number.
  --business-postal-code: string # The postal code of the business or organization using the Tollfree number.
  --business-state-province-region: string # The state/province/region of the business or organization using the Tollfree number.
  --business-street-address: string # The address of the business or organization using the Tollfree number.
  --business-street-address2: string # The address of the business or organization using the Tollfree number.
  --business-website: string # The website of the business or organization using the Tollfree number.
  --message-volume: string # Estimate monthly volume of messages from the Tollfree Number.
  --notification-email: string # The email address to receive the notification about the verification result. .
  --opt-in-image-urls: list<string> # Link to an image that shows the opt-in workflow. Multiple images allowed and must be a publicly hosted URL.
  --opt-in-type: string@opt-in-type-completer
  --production-message-sample: string # An example of message content, i.e. a sample message.
  --use-case-categories: list<string> # The category of the use case for the Tollfree Number. List as many are applicable..
  --use-case-summary: string # Use this to further explain how messaging is used by the business or organization.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Tollfree/Verifications/{Sid}"
    path_params: [{name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: AdditionalInformation, var: additional_information}, {name: BusinessCity, var: business_city}, {name: BusinessContactEmail, var: business_contact_email}, {name: BusinessContactFirstName, var: business_contact_first_name}, {name: BusinessContactLastName, var: business_contact_last_name}, {name: BusinessContactPhone, var: business_contact_phone}, {name: BusinessCountry, var: business_country}, {name: BusinessName, var: business_name}, {name: BusinessPostalCode, var: business_postal_code}, {name: BusinessStateProvinceRegion, var: business_state_province_region}, {name: BusinessStreetAddress, var: business_street_address}, {name: BusinessStreetAddress2, var: business_street_address2}, {name: BusinessWebsite, var: business_website}, {name: MessageVolume, var: message_volume}, {name: NotificationEmail, var: notification_email}, {name: OptInImageUrls, var: opt_in_image_urls}, {name: OptInType, var: opt_in_type}, {name: ProductionMessageSample, var: production_message_sample}, {name: UseCaseCategories, var: use_case_categories}, {name: UseCaseSummary, var: use_case_summary}]}
    accept: ["application/json"]
    ok: [202]
    base_url: "https://messaging.twilio.com"
    auth: basic
  } {
    sid: $sid, additional_information: $additional_information, business_city: $business_city, business_contact_email: $business_contact_email, business_contact_first_name: $business_contact_first_name, business_contact_last_name: $business_contact_last_name, business_contact_phone: $business_contact_phone, business_country: $business_country, business_name: $business_name, business_postal_code: $business_postal_code, business_state_province_region: $business_state_province_region, business_street_address: $business_street_address, business_street_address2: $business_street_address2, business_website: $business_website, message_volume: $message_volume, notification_email: $notification_email, opt_in_image_urls: $opt_in_image_urls, opt_in_type: $opt_in_type, production_message_sample: $production_message_sample, use_case_categories: $use_case_categories, use_case_summary: $use_case_summary
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/a2p/BrandRegistrations
#
# Returns: record<data: table<a2p_profile_bundle_sid: string, account_sid: string, brand_feedback: list, brand_score: int, brand_type: string, customer_profile_bundle_sid: string, date_created: string, date_updated: string, failure_reason: string, government_entity: bool, identity_status: string, links: record, mock: bool, russell_3000: bool, sid: string, skip_automatic_sec_vet: bool, status: string, tax_exempt_status: string, tcr_id: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListBrandRegistrations
export def "list-brand-registrations" [
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
    path: "/v1/a2p/BrandRegistrations"
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://messaging.twilio.com"
    auth: basic
  } {
    page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/a2p/BrandRegistrations
#
# Returns: record<a2p_profile_bundle_sid: string, account_sid: string, brand_feedback: list<string>, brand_score: int, brand_type: string, customer_profile_bundle_sid: string, date_created: string, date_updated: string, failure_reason: string, government_entity: bool, identity_status: string, links: record, mock: bool, russell_3000: bool, sid: string, skip_automatic_sec_vet: bool, status: string, tax_exempt_status: string, tcr_id: string, url: string>
# operationId: CreateBrandRegistrations
export def "create-brand-registrations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  a2p_profile_bundle_sid: string # A2P Messaging Profile Bundle Sid.
  --brand-type: string # Type of brand being created. One of: "STANDARD", "SOLE_PROPRIETOR". SOLE_PROPRIETOR is for low volume, SOLE_PROPRIETOR use cases. STANDARD is for all other use cases.
  customer_profile_bundle_sid: string # Customer Profile Bundle Sid.
  --mock: oneof<nothing, bool> # A boolean that specifies whether brand should be a mock or not. If true, brand will be registered as a mock brand. Defaults to false if no value is provided.
  --skip-automatic-sec-vet: oneof<nothing, bool> # A flag to disable automatic secondary vetting for brands which it would otherwise be done.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/a2p/BrandRegistrations"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: A2PProfileBundleSid, var: a2p_profile_bundle_sid}, {name: BrandType, var: brand_type}, {name: CustomerProfileBundleSid, var: customer_profile_bundle_sid}, {name: Mock, var: mock}, {name: SkipAutomaticSecVet, var: skip_automatic_sec_vet}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://messaging.twilio.com"
    auth: basic
  } {
    a2p_profile_bundle_sid: $a2p_profile_bundle_sid, brand_type: $brand_type, customer_profile_bundle_sid: $customer_profile_bundle_sid, mock: $mock, skip_automatic_sec_vet: $skip_automatic_sec_vet
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/a2p/BrandRegistrations/{BrandRegistrationSid}/SmsOtp
#
# Returns: record<account_sid: string, brand_registration_sid: string>
# operationId: CreateBrandRegistrationOtp
export def "create-brand-registration-otp" [
  brand_registration_sid: string
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
    path: "/v1/a2p/BrandRegistrations/{BrandRegistrationSid}/SmsOtp"
    path_params: [{name: BrandRegistrationSid, var: brand_registration_sid}]
    accept: ["application/json"]
    ok: [201]
    base_url: "https://messaging.twilio.com"
    auth: basic
  } {
    brand_registration_sid: $brand_registration_sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/a2p/BrandRegistrations/{BrandSid}/Vettings
#
# Returns: record<data: table<account_sid: string, brand_sid: string, brand_vetting_sid: string, date_created: string, date_updated: string, url: string, vetting_class: string, vetting_id: string, vetting_provider: string, vetting_status: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListBrandVetting
export def "list-brand-vetting" [
  brand_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vetting-provider: string@vetting-provider-completer # The third-party provider of the vettings to read
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/a2p/BrandRegistrations/{BrandSid}/Vettings"
    path_params: [{name: BrandSid, var: brand_sid}]
    query: [{name: VettingProvider, var: vetting_provider}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://messaging.twilio.com"
    auth: basic
  } {
    brand_sid: $brand_sid, vetting_provider: $vetting_provider, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/a2p/BrandRegistrations/{BrandSid}/Vettings
#
# Returns: record<account_sid: string, brand_sid: string, brand_vetting_sid: string, date_created: string, date_updated: string, url: string, vetting_class: string, vetting_id: string, vetting_provider: string, vetting_status: string>
# operationId: CreateBrandVetting
export def "create-brand-vetting" [
  brand_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vetting-id: string # The unique ID of the vetting
  vetting_provider: string@vetting-provider-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/a2p/BrandRegistrations/{BrandSid}/Vettings"
    path_params: [{name: BrandSid, var: brand_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: VettingId, var: vetting_id}, {name: VettingProvider, var: vetting_provider}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://messaging.twilio.com"
    auth: basic
  } {
    brand_sid: $brand_sid, vetting_id: $vetting_id, vetting_provider: $vetting_provider
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/a2p/BrandRegistrations/{BrandSid}/Vettings/{BrandVettingSid}
#
# Returns: record<account_sid: string, brand_sid: string, brand_vetting_sid: string, date_created: string, date_updated: string, url: string, vetting_class: string, vetting_id: string, vetting_provider: string, vetting_status: string>
# operationId: FetchBrandVetting
export def "fetch-brand-vetting" [
  brand_sid: string
  brand_vetting_sid: string
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
    path: "/v1/a2p/BrandRegistrations/{BrandSid}/Vettings/{BrandVettingSid}"
    path_params: [{name: BrandSid, var: brand_sid}, {name: BrandVettingSid, var: brand_vetting_sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://messaging.twilio.com"
    auth: basic
  } {
    brand_sid: $brand_sid, brand_vetting_sid: $brand_vetting_sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/a2p/BrandRegistrations/{Sid}
#
# Returns: record<a2p_profile_bundle_sid: string, account_sid: string, brand_feedback: list<string>, brand_score: int, brand_type: string, customer_profile_bundle_sid: string, date_created: string, date_updated: string, failure_reason: string, government_entity: bool, identity_status: string, links: record, mock: bool, russell_3000: bool, sid: string, skip_automatic_sec_vet: bool, status: string, tax_exempt_status: string, tcr_id: string, url: string>
# operationId: FetchBrandRegistrations
export def "fetch-brand-registrations" [
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
    path: "/v1/a2p/BrandRegistrations/{Sid}"
    path_params: [{name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://messaging.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/a2p/BrandRegistrations/{Sid}
#
# Returns: record<a2p_profile_bundle_sid: string, account_sid: string, brand_feedback: list<string>, brand_score: int, brand_type: string, customer_profile_bundle_sid: string, date_created: string, date_updated: string, failure_reason: string, government_entity: bool, identity_status: string, links: record, mock: bool, russell_3000: bool, sid: string, skip_automatic_sec_vet: bool, status: string, tax_exempt_status: string, tcr_id: string, url: string>
# operationId: UpdateBrandRegistrations
export def "update-brand-registrations" [
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
    method: post
    path: "/v1/a2p/BrandRegistrations/{Sid}"
    path_params: [{name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [202]
    base_url: "https://messaging.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
