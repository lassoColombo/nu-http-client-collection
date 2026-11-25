# Auto-generated client for Twilio - Chat v1.42.0
# Source: https://api.apis.guru/v2/specs/twilio.com/twilio_chat_v1/1.42.0/openapi.json
# Auth: --token flag or $env.TWILIO_CHAT_TOKEN

const CLIENT = {
  base_url: "https://chat.twilio.com"
  token_env_var: "TWILIO_CHAT_TOKEN"
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

def base-url-completer [] { ["https://chat.twilio.com"] }
def auth-scheme-completer [] { ["basic" "basic-credentials"] }

# Completers for enum parameters
def type-completer [] { ["apn" "fcm" "gcm"] }
def type-completer-1 [] { ["private" "public"] }
def order-completer [] { ["asc" "desc"] }
def type-completer-2 [] { ["channel" "deployment"] }
def webhook-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def webhooks-on-channel-add-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def webhooks-on-channel-added-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def webhooks-on-channel-destroy-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def webhooks-on-channel-destroyed-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def webhooks-on-channel-update-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def webhooks-on-channel-updated-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def webhooks-on-member-add-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def webhooks-on-member-added-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def webhooks-on-member-remove-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def webhooks-on-member-removed-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def webhooks-on-message-remove-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def webhooks-on-message-removed-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def webhooks-on-message-send-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def webhooks-on-message-sent-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def webhooks-on-message-update-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def webhooks-on-message-updated-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    list-credential: "record<credentials: table<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sandbox: string, sid: string, type: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    create-credential: "record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sandbox: string, sid: string, type: string, url: string>"
    fetch-credential: "record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sandbox: string, sid: string, type: string, url: string>"
    update-credential: "record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sandbox: string, sid: string, type: string, url: string>"
    list-service: "record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, services: table<account_sid: string, consumption_report_interval: int, date_created: string, date_updated: string, default_channel_creator_role_sid: string, default_channel_role_sid: string, default_service_role_sid: string, friendly_name: string, limits: any, links: record, notifications: any, post_webhook_url: string, pre_webhook_url: string, reachability_enabled: bool, read_status_enabled: bool, sid: string, typing_indicator_timeout: int, url: string, webhook_filters: list, webhook_method: string, webhooks: any>>"
    create-service: "record<account_sid: string, consumption_report_interval: int, date_created: string, date_updated: string, default_channel_creator_role_sid: string, default_channel_role_sid: string, default_service_role_sid: string, friendly_name: string, limits: any, links: record, notifications: any, post_webhook_url: string, pre_webhook_url: string, reachability_enabled: bool, read_status_enabled: bool, sid: string, typing_indicator_timeout: int, url: string, webhook_filters: list<string>, webhook_method: string, webhooks: any>"
    list-channel: "record<channels: table<account_sid: string, attributes: string, created_by: string, date_created: string, date_updated: string, friendly_name: string, links: record, members_count: int, messages_count: int, service_sid: string, sid: string, type: string, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    create-channel: "record<account_sid: string, attributes: string, created_by: string, date_created: string, date_updated: string, friendly_name: string, links: record, members_count: int, messages_count: int, service_sid: string, sid: string, type: string, unique_name: string, url: string>"
    list-invite: "record<invites: table<account_sid: string, channel_sid: string, created_by: string, date_created: string, date_updated: string, identity: string, role_sid: string, service_sid: string, sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    create-invite: "record<account_sid: string, channel_sid: string, created_by: string, date_created: string, date_updated: string, identity: string, role_sid: string, service_sid: string, sid: string, url: string>"
    fetch-invite: "record<account_sid: string, channel_sid: string, created_by: string, date_created: string, date_updated: string, identity: string, role_sid: string, service_sid: string, sid: string, url: string>"
    list-member: "record<members: table<account_sid: string, channel_sid: string, date_created: string, date_updated: string, identity: string, last_consumed_message_index: int, last_consumption_timestamp: string, role_sid: string, service_sid: string, sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    create-member: "record<account_sid: string, channel_sid: string, date_created: string, date_updated: string, identity: string, last_consumed_message_index: int, last_consumption_timestamp: string, role_sid: string, service_sid: string, sid: string, url: string>"
    fetch-member: "record<account_sid: string, channel_sid: string, date_created: string, date_updated: string, identity: string, last_consumed_message_index: int, last_consumption_timestamp: string, role_sid: string, service_sid: string, sid: string, url: string>"
    update-member: "record<account_sid: string, channel_sid: string, date_created: string, date_updated: string, identity: string, last_consumed_message_index: int, last_consumption_timestamp: string, role_sid: string, service_sid: string, sid: string, url: string>"
    list-message: "record<messages: table<account_sid: string, attributes: string, body: string, channel_sid: string, date_created: string, date_updated: string, from: string, index: int, service_sid: string, sid: string, to: string, url: string, was_edited: bool>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    create-message: "record<account_sid: string, attributes: string, body: string, channel_sid: string, date_created: string, date_updated: string, from: string, index: int, service_sid: string, sid: string, to: string, url: string, was_edited: bool>"
    fetch-message: "record<account_sid: string, attributes: string, body: string, channel_sid: string, date_created: string, date_updated: string, from: string, index: int, service_sid: string, sid: string, to: string, url: string, was_edited: bool>"
    update-message: "record<account_sid: string, attributes: string, body: string, channel_sid: string, date_created: string, date_updated: string, from: string, index: int, service_sid: string, sid: string, to: string, url: string, was_edited: bool>"
    fetch-channel: "record<account_sid: string, attributes: string, created_by: string, date_created: string, date_updated: string, friendly_name: string, links: record, members_count: int, messages_count: int, service_sid: string, sid: string, type: string, unique_name: string, url: string>"
    update-channel: "record<account_sid: string, attributes: string, created_by: string, date_created: string, date_updated: string, friendly_name: string, links: record, members_count: int, messages_count: int, service_sid: string, sid: string, type: string, unique_name: string, url: string>"
    list-role: "record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, roles: table<account_sid: string, date_created: string, date_updated: string, friendly_name: string, permissions: list, service_sid: string, sid: string, type: string, url: string>>"
    create-role: "record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, permissions: list<string>, service_sid: string, sid: string, type: string, url: string>"
    fetch-role: "record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, permissions: list<string>, service_sid: string, sid: string, type: string, url: string>"
    update-role: "record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, permissions: list<string>, service_sid: string, sid: string, type: string, url: string>"
    list-user: "record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, users: table<account_sid: string, attributes: string, date_created: string, date_updated: string, friendly_name: string, identity: string, is_notifiable: bool, is_online: bool, joined_channels_count: int, links: record, role_sid: string, service_sid: string, sid: string, url: string>>"
    create-user: "record<account_sid: string, attributes: string, date_created: string, date_updated: string, friendly_name: string, identity: string, is_notifiable: bool, is_online: bool, joined_channels_count: int, links: record, role_sid: string, service_sid: string, sid: string, url: string>"
    fetch-user: "record<account_sid: string, attributes: string, date_created: string, date_updated: string, friendly_name: string, identity: string, is_notifiable: bool, is_online: bool, joined_channels_count: int, links: record, role_sid: string, service_sid: string, sid: string, url: string>"
    update-user: "record<account_sid: string, attributes: string, date_created: string, date_updated: string, friendly_name: string, identity: string, is_notifiable: bool, is_online: bool, joined_channels_count: int, links: record, role_sid: string, service_sid: string, sid: string, url: string>"
    list-user-channel: "record<channels: table<account_sid: string, channel_sid: string, last_consumed_message_index: int, links: record, member_sid: string, service_sid: string, status: string, unread_messages_count: int>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    fetch-service: "record<account_sid: string, consumption_report_interval: int, date_created: string, date_updated: string, default_channel_creator_role_sid: string, default_channel_role_sid: string, default_service_role_sid: string, friendly_name: string, limits: any, links: record, notifications: any, post_webhook_url: string, pre_webhook_url: string, reachability_enabled: bool, read_status_enabled: bool, sid: string, typing_indicator_timeout: int, url: string, webhook_filters: list<string>, webhook_method: string, webhooks: any>"
    update-service: "record<account_sid: string, consumption_report_interval: int, date_created: string, date_updated: string, default_channel_creator_role_sid: string, default_channel_role_sid: string, default_service_role_sid: string, friendly_name: string, limits: any, links: record, notifications: any, post_webhook_url: string, pre_webhook_url: string, reachability_enabled: bool, read_status_enabled: bool, sid: string, typing_indicator_timeout: int, url: string, webhook_filters: list<string>, webhook_method: string, webhooks: any>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["list-credential" "create-credential" "delete-credential" "fetch-credential" "update-credential" "list-service" "create-service" "list-channel" "create-channel" "list-invite" "create-invite" "delete-invite" "fetch-invite" "list-member" "create-member" "delete-member" "fetch-member" "update-member" "list-message" "create-message" "delete-message" "fetch-message" "update-message" "delete-channel" "fetch-channel" "update-channel" "list-role" "create-role" "delete-role" "fetch-role" "update-role" "list-user" "create-user" "delete-user" "fetch-user" "update-user" "list-user-channel" "delete-service" "fetch-service" "update-service" "commands"] | sort) } | get name | first)
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
    base_url: "https://chat.twilio.com"
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
  --api-key: string # [GCM only] The API key for the project that was obtained from the Google Developer console for your GCM Service application credential.
  --certificate: string # [APN only] The URL encoded representation of the certificate. For example, `-----BEGIN CERTIFICATE----- MIIFnTCCBIWgAwIBAgIIAjy9H849+E8wDQYJKoZIhvcNAQEFBQAwgZYxCzAJBgNV.....A== -----END CERTIFICATE-----`
  --friendly-name: string # A descriptive string that you create to describe the new resource. It can be up to 64 characters long.
  --private-key: string # [APN only] The URL encoded representation of the private key. For example, `-----BEGIN RSA PRIVATE KEY----- MIIEpQIBAAKCAQEAuyf/lNrH9ck8DmNyo3fGgvCI1l9s+cmBY3WIz+cUDqmxiieR. -----END RSA PRIVATE KEY-----`
  --sandbox: oneof<nothing, bool> # [APN only] Whether to send the credential to sandbox APNs. Can be `true` to send to sandbox APNs or `false` to send to production.
  --secret: string # [FCM only] The **Server key** of your project from the Firebase console, found under Settings / Cloud messaging.
  type: string@type-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Credentials"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: ApiKey, var: api_key}, {name: Certificate, var: certificate}, {name: FriendlyName, var: friendly_name}, {name: PrivateKey, var: private_key}, {name: Sandbox, var: sandbox}, {name: Secret, var: secret}, {name: Type, var: type}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://chat.twilio.com"
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
    base_url: "https://chat.twilio.com"
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
    base_url: "https://chat.twilio.com"
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
  --api-key: string # [GCM only] The API key for the project that was obtained from the Google Developer console for your GCM Service application credential.
  --certificate: string # [APN only] The URL encoded representation of the certificate. For example, `-----BEGIN CERTIFICATE----- MIIFnTCCBIWgAwIBAgIIAjy9H849+E8wDQYJKoZIhvcNAQEFBQAwgZYxCzAJBgNV.....A== -----END CERTIFICATE-----`
  --friendly-name: string # A descriptive string that you create to describe the resource. It can be up to 64 characters long.
  --private-key: string # [APN only] The URL encoded representation of the private key. For example, `-----BEGIN RSA PRIVATE KEY----- MIIEpQIBAAKCAQEAuyf/lNrH9ck8DmNyo3fGgvCI1l9s+cmBY3WIz+cUDqmxiieR. -----END RSA PRIVATE KEY-----`
  --sandbox: oneof<nothing, bool> # [APN only] Whether to send the credential to sandbox APNs. Can be `true` to send to sandbox APNs or `false` to send to production.
  --secret: string # [FCM only] The **Server key** of your project from the Firebase console, found under Settings / Cloud messaging.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Credentials/{Sid}"
    path_params: [{name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: ApiKey, var: api_key}, {name: Certificate, var: certificate}, {name: FriendlyName, var: friendly_name}, {name: PrivateKey, var: private_key}, {name: Sandbox, var: sandbox}, {name: Secret, var: secret}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://chat.twilio.com"
    auth: basic
  } {
    sid: $sid, api_key: $api_key, certificate: $certificate, friendly_name: $friendly_name, private_key: $private_key, sandbox: $sandbox, secret: $secret
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Services
#
# Returns: record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, services: table<account_sid: string, consumption_report_interval: int, date_created: string, date_updated: string, default_channel_creator_role_sid: string, default_channel_role_sid: string, default_service_role_sid: string, friendly_name: string, limits: any, links: record, notifications: any, post_webhook_url: string, pre_webhook_url: string, reachability_enabled: bool, read_status_enabled: bool, sid: string, typing_indicator_timeout: int, url: string, webhook_filters: list, webhook_method: string, webhooks: any>>
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
    base_url: "https://chat.twilio.com"
    auth: basic
  } {
    page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Services
#
# Returns: record<account_sid: string, consumption_report_interval: int, date_created: string, date_updated: string, default_channel_creator_role_sid: string, default_channel_role_sid: string, default_service_role_sid: string, friendly_name: string, limits: any, links: record, notifications: any, post_webhook_url: string, pre_webhook_url: string, reachability_enabled: bool, read_status_enabled: bool, sid: string, typing_indicator_timeout: int, url: string, webhook_filters: list<string>, webhook_method: string, webhooks: any>
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
  friendly_name: string # A descriptive string that you create to describe the resource. It can be up to 64 characters long.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Services"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: FriendlyName, var: friendly_name}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://chat.twilio.com"
    auth: basic
  } {
    friendly_name: $friendly_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Services/{ServiceSid}/Channels
#
# Returns: record<channels: table<account_sid: string, attributes: string, created_by: string, date_created: string, date_updated: string, friendly_name: string, links: record, members_count: int, messages_count: int, service_sid: string, sid: string, type: string, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListChannel
export def "list-channel" [
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
  --type: list<string> # The visibility of the Channels to read. Can be: `public` or `private` and defaults to `public`.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/Services/{ServiceSid}/Channels"
    path_params: [{name: ServiceSid, var: service_sid}]
    query: [{name: Type, var: type, style: multi}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://chat.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, type: $type, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Services/{ServiceSid}/Channels
#
# Returns: record<account_sid: string, attributes: string, created_by: string, date_created: string, date_updated: string, friendly_name: string, links: record, members_count: int, messages_count: int, service_sid: string, sid: string, type: string, unique_name: string, url: string>
# operationId: CreateChannel
export def "create-channel" [
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
  --attributes: string # A valid JSON string that contains application-specific data.
  --friendly-name: string # A descriptive string that you create to describe the new resource. It can be up to 64 characters long.
  --type: string@type-completer-1
  --unique-name: string # An application-defined string that uniquely identifies the resource. It can be used to address the resource in place of the resource's `sid` in the URL. This value must be 64 characters or less in length and be unique within the Service.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Services/{ServiceSid}/Channels"
    path_params: [{name: ServiceSid, var: service_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Attributes, var: attributes}, {name: FriendlyName, var: friendly_name}, {name: Type, var: type}, {name: UniqueName, var: unique_name}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://chat.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, attributes: $attributes, friendly_name: $friendly_name, type: $type, unique_name: $unique_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Services/{ServiceSid}/Channels/{ChannelSid}/Invites
#
# Returns: record<invites: table<account_sid: string, channel_sid: string, created_by: string, date_created: string, date_updated: string, identity: string, role_sid: string, service_sid: string, sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListInvite
export def "list-invite" [
  service_sid: string
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
  --identity: list<string> # The [User](https://www.twilio.com/docs/api/chat/rest/v1/user)'s `identity` value of the resources to read. See [access tokens](https://www.twilio.com/docs/api/chat/guides/create-tokens) for more details.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/Services/{ServiceSid}/Channels/{ChannelSid}/Invites"
    path_params: [{name: ServiceSid, var: service_sid}, {name: ChannelSid, var: channel_sid}]
    query: [{name: Identity, var: identity, style: multi}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://chat.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, channel_sid: $channel_sid, identity: $identity, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Services/{ServiceSid}/Channels/{ChannelSid}/Invites
#
# Returns: record<account_sid: string, channel_sid: string, created_by: string, date_created: string, date_updated: string, identity: string, role_sid: string, service_sid: string, sid: string, url: string>
# operationId: CreateInvite
export def "create-invite" [
  service_sid: string
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
  identity: string # The `identity` value that uniquely identifies the new resource's [User](https://www.twilio.com/docs/api/chat/rest/v1/user) within the [Service](https://www.twilio.com/docs/api/chat/rest/v1/service). See [access tokens](https://www.twilio.com/docs/api/chat/guides/create-tokens) for more info.
  --role-sid: string # The SID of the [Role](https://www.twilio.com/docs/api/chat/rest/roles) assigned to the new member.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Services/{ServiceSid}/Channels/{ChannelSid}/Invites"
    path_params: [{name: ServiceSid, var: service_sid}, {name: ChannelSid, var: channel_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Identity, var: identity}, {name: RoleSid, var: role_sid}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://chat.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, channel_sid: $channel_sid, identity: $identity, role_sid: $role_sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/Services/{ServiceSid}/Channels/{ChannelSid}/Invites/{Sid}
#
# operationId: DeleteInvite
export def "delete-invite" [
  service_sid: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/v1/Services/{ServiceSid}/Channels/{ChannelSid}/Invites/{Sid}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: ChannelSid, var: channel_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://chat.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, channel_sid: $channel_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Services/{ServiceSid}/Channels/{ChannelSid}/Invites/{Sid}
#
# Returns: record<account_sid: string, channel_sid: string, created_by: string, date_created: string, date_updated: string, identity: string, role_sid: string, service_sid: string, sid: string, url: string>
# operationId: FetchInvite
export def "fetch-invite" [
  service_sid: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/Services/{ServiceSid}/Channels/{ChannelSid}/Invites/{Sid}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: ChannelSid, var: channel_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://chat.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, channel_sid: $channel_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Services/{ServiceSid}/Channels/{ChannelSid}/Members
#
# Returns: record<members: table<account_sid: string, channel_sid: string, date_created: string, date_updated: string, identity: string, last_consumed_message_index: int, last_consumption_timestamp: string, role_sid: string, service_sid: string, sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListMember
export def "list-member" [
  service_sid: string
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
  --identity: list<string> # The [User](https://www.twilio.com/docs/api/chat/rest/v1/user)'s `identity` value of the resources to read. See [access tokens](https://www.twilio.com/docs/api/chat/guides/create-tokens) for more details.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/Services/{ServiceSid}/Channels/{ChannelSid}/Members"
    path_params: [{name: ServiceSid, var: service_sid}, {name: ChannelSid, var: channel_sid}]
    query: [{name: Identity, var: identity, style: multi}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://chat.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, channel_sid: $channel_sid, identity: $identity, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Services/{ServiceSid}/Channels/{ChannelSid}/Members
#
# Returns: record<account_sid: string, channel_sid: string, date_created: string, date_updated: string, identity: string, last_consumed_message_index: int, last_consumption_timestamp: string, role_sid: string, service_sid: string, sid: string, url: string>
# operationId: CreateMember
export def "create-member" [
  service_sid: string
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
  identity: string # The `identity` value that uniquely identifies the new resource's [User](https://www.twilio.com/docs/api/chat/rest/v1/user) within the [Service](https://www.twilio.com/docs/api/chat/rest/services). See [access tokens](https://www.twilio.com/docs/api/chat/guides/create-tokens) for more details.
  --role-sid: string # The SID of the [Role](https://www.twilio.com/docs/api/chat/rest/roles) to assign to the member. The default roles are those specified on the [Service](https://www.twilio.com/docs/chat/api/services).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Services/{ServiceSid}/Channels/{ChannelSid}/Members"
    path_params: [{name: ServiceSid, var: service_sid}, {name: ChannelSid, var: channel_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Identity, var: identity}, {name: RoleSid, var: role_sid}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://chat.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, channel_sid: $channel_sid, identity: $identity, role_sid: $role_sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/Services/{ServiceSid}/Channels/{ChannelSid}/Members/{Sid}
#
# operationId: DeleteMember
export def "delete-member" [
  service_sid: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/v1/Services/{ServiceSid}/Channels/{ChannelSid}/Members/{Sid}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: ChannelSid, var: channel_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://chat.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, channel_sid: $channel_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Services/{ServiceSid}/Channels/{ChannelSid}/Members/{Sid}
#
# Returns: record<account_sid: string, channel_sid: string, date_created: string, date_updated: string, identity: string, last_consumed_message_index: int, last_consumption_timestamp: string, role_sid: string, service_sid: string, sid: string, url: string>
# operationId: FetchMember
export def "fetch-member" [
  service_sid: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/Services/{ServiceSid}/Channels/{ChannelSid}/Members/{Sid}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: ChannelSid, var: channel_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://chat.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, channel_sid: $channel_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Services/{ServiceSid}/Channels/{ChannelSid}/Members/{Sid}
#
# Returns: record<account_sid: string, channel_sid: string, date_created: string, date_updated: string, identity: string, last_consumed_message_index: int, last_consumption_timestamp: string, role_sid: string, service_sid: string, sid: string, url: string>
# operationId: UpdateMember
export def "update-member" [
  service_sid: string
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
  --last-consumed-message-index: int # The index of the last [Message](https://www.twilio.com/docs/api/chat/rest/messages) that the Member has read within the [Channel](https://www.twilio.com/docs/api/chat/rest/channels). (nullable)
  --role-sid: string # The SID of the [Role](https://www.twilio.com/docs/api/chat/rest/roles) to assign to the member. The default roles are those specified on the [Service](https://www.twilio.com/docs/chat/api/services).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Services/{ServiceSid}/Channels/{ChannelSid}/Members/{Sid}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: ChannelSid, var: channel_sid}, {name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: LastConsumedMessageIndex, var: last_consumed_message_index}, {name: RoleSid, var: role_sid}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://chat.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, channel_sid: $channel_sid, sid: $sid, last_consumed_message_index: $last_consumed_message_index, role_sid: $role_sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Services/{ServiceSid}/Channels/{ChannelSid}/Messages
#
# Returns: record<messages: table<account_sid: string, attributes: string, body: string, channel_sid: string, date_created: string, date_updated: string, from: string, index: int, service_sid: string, sid: string, to: string, url: string, was_edited: bool>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListMessage
export def "list-message" [
  service_sid: string
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
  --order: string@order-completer # The sort order of the returned messages. Can be: `asc` (ascending) or `desc` (descending) with `asc` as the default.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/Services/{ServiceSid}/Channels/{ChannelSid}/Messages"
    path_params: [{name: ServiceSid, var: service_sid}, {name: ChannelSid, var: channel_sid}]
    query: [{name: Order, var: order}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://chat.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, channel_sid: $channel_sid, order: $order, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Services/{ServiceSid}/Channels/{ChannelSid}/Messages
#
# Returns: record<account_sid: string, attributes: string, body: string, channel_sid: string, date_created: string, date_updated: string, from: string, index: int, service_sid: string, sid: string, to: string, url: string, was_edited: bool>
# operationId: CreateMessage
export def "create-message" [
  service_sid: string
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
  --attributes: string # A valid JSON string that contains application-specific data.
  body: string # The message to send to the channel. Can also be an empty string or `null`, which sets the value as an empty string. You can send structured data in the body by serializing it as a string.
  --from: string # The [identity](https://www.twilio.com/docs/api/chat/guides/identity) of the new message's author. The default value is `system`.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Services/{ServiceSid}/Channels/{ChannelSid}/Messages"
    path_params: [{name: ServiceSid, var: service_sid}, {name: ChannelSid, var: channel_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Attributes, var: attributes}, {name: Body, var: body}, {name: From, var: from}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://chat.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, channel_sid: $channel_sid, attributes: $attributes, body: $body, from: $from
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/Services/{ServiceSid}/Channels/{ChannelSid}/Messages/{Sid}
#
# operationId: DeleteMessage
export def "delete-message" [
  service_sid: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/v1/Services/{ServiceSid}/Channels/{ChannelSid}/Messages/{Sid}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: ChannelSid, var: channel_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://chat.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, channel_sid: $channel_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Services/{ServiceSid}/Channels/{ChannelSid}/Messages/{Sid}
#
# Returns: record<account_sid: string, attributes: string, body: string, channel_sid: string, date_created: string, date_updated: string, from: string, index: int, service_sid: string, sid: string, to: string, url: string, was_edited: bool>
# operationId: FetchMessage
export def "fetch-message" [
  service_sid: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/Services/{ServiceSid}/Channels/{ChannelSid}/Messages/{Sid}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: ChannelSid, var: channel_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://chat.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, channel_sid: $channel_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Services/{ServiceSid}/Channels/{ChannelSid}/Messages/{Sid}
#
# Returns: record<account_sid: string, attributes: string, body: string, channel_sid: string, date_created: string, date_updated: string, from: string, index: int, service_sid: string, sid: string, to: string, url: string, was_edited: bool>
# operationId: UpdateMessage
export def "update-message" [
  service_sid: string
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
  --attributes: string # A valid JSON string that contains application-specific data.
  --body: string # The message to send to the channel. Can also be an empty string or `null`, which sets the value as an empty string. You can send structured data in the body by serializing it as a string.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Services/{ServiceSid}/Channels/{ChannelSid}/Messages/{Sid}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: ChannelSid, var: channel_sid}, {name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Attributes, var: attributes}, {name: Body, var: body}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://chat.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, channel_sid: $channel_sid, sid: $sid, attributes: $attributes, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/Services/{ServiceSid}/Channels/{Sid}
#
# operationId: DeleteChannel
export def "delete-channel" [
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
    path: "/v1/Services/{ServiceSid}/Channels/{Sid}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://chat.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Services/{ServiceSid}/Channels/{Sid}
#
# Returns: record<account_sid: string, attributes: string, created_by: string, date_created: string, date_updated: string, friendly_name: string, links: record, members_count: int, messages_count: int, service_sid: string, sid: string, type: string, unique_name: string, url: string>
# operationId: FetchChannel
export def "fetch-channel" [
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
    path: "/v1/Services/{ServiceSid}/Channels/{Sid}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://chat.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Services/{ServiceSid}/Channels/{Sid}
#
# Returns: record<account_sid: string, attributes: string, created_by: string, date_created: string, date_updated: string, friendly_name: string, links: record, members_count: int, messages_count: int, service_sid: string, sid: string, type: string, unique_name: string, url: string>
# operationId: UpdateChannel
export def "update-channel" [
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
  --attributes: string # A valid JSON string that contains application-specific data.
  --friendly-name: string # A descriptive string that you create to describe the resource. It can be up to 64 characters long.
  --unique-name: string # An application-defined string that uniquely identifies the resource. It can be used to address the resource in place of the resource's `sid` in the URL. This value must be 64 characters or less in length and be unique within the Service.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Services/{ServiceSid}/Channels/{Sid}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Attributes, var: attributes}, {name: FriendlyName, var: friendly_name}, {name: UniqueName, var: unique_name}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://chat.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, sid: $sid, attributes: $attributes, friendly_name: $friendly_name, unique_name: $unique_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Services/{ServiceSid}/Roles
#
# Returns: record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, roles: table<account_sid: string, date_created: string, date_updated: string, friendly_name: string, permissions: list, service_sid: string, sid: string, type: string, url: string>>
# operationId: ListRole
export def "list-role" [
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
    path: "/v1/Services/{ServiceSid}/Roles"
    path_params: [{name: ServiceSid, var: service_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://chat.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Services/{ServiceSid}/Roles
#
# Returns: record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, permissions: list<string>, service_sid: string, sid: string, type: string, url: string>
# operationId: CreateRole
export def "create-role" [
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
  friendly_name: string # A descriptive string that you create to describe the new resource. It can be up to 64 characters long.
  permission: list<string> # A permission that you grant to the new role. Only one permission can be granted per parameter. To assign more than one permission, repeat this parameter for each permission value. The values for this parameter depend on the role's `type` and are described in the documentation.
  type: string@type-completer-2
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Services/{ServiceSid}/Roles"
    path_params: [{name: ServiceSid, var: service_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: FriendlyName, var: friendly_name}, {name: Permission, var: permission}, {name: Type, var: type}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://chat.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, friendly_name: $friendly_name, permission: $permission, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/Services/{ServiceSid}/Roles/{Sid}
#
# operationId: DeleteRole
export def "delete-role" [
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
    path: "/v1/Services/{ServiceSid}/Roles/{Sid}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://chat.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Services/{ServiceSid}/Roles/{Sid}
#
# Returns: record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, permissions: list<string>, service_sid: string, sid: string, type: string, url: string>
# operationId: FetchRole
export def "fetch-role" [
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
    path: "/v1/Services/{ServiceSid}/Roles/{Sid}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://chat.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Services/{ServiceSid}/Roles/{Sid}
#
# Returns: record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, permissions: list<string>, service_sid: string, sid: string, type: string, url: string>
# operationId: UpdateRole
export def "update-role" [
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
  permission: list<string> # A permission that you grant to the role. Only one permission can be granted per parameter. To assign more than one permission, repeat this parameter for each permission value. The values for this parameter depend on the role's `type` and are described in the documentation.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Services/{ServiceSid}/Roles/{Sid}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Permission, var: permission}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://chat.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, sid: $sid, permission: $permission
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Services/{ServiceSid}/Users
#
# Returns: record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, users: table<account_sid: string, attributes: string, date_created: string, date_updated: string, friendly_name: string, identity: string, is_notifiable: bool, is_online: bool, joined_channels_count: int, links: record, role_sid: string, service_sid: string, sid: string, url: string>>
# operationId: ListUser
export def "list-user" [
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
    path: "/v1/Services/{ServiceSid}/Users"
    path_params: [{name: ServiceSid, var: service_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://chat.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Services/{ServiceSid}/Users
#
# Returns: record<account_sid: string, attributes: string, date_created: string, date_updated: string, friendly_name: string, identity: string, is_notifiable: bool, is_online: bool, joined_channels_count: int, links: record, role_sid: string, service_sid: string, sid: string, url: string>
# operationId: CreateUser
export def "create-user" [
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
  --attributes: string # A valid JSON string that contains application-specific data.
  --friendly-name: string # A descriptive string that you create to describe the new resource. This value is often used for display purposes.
  identity: string # The `identity` value that uniquely identifies the new resource's [User](https://www.twilio.com/docs/api/chat/rest/v1/user) within the [Service](https://www.twilio.com/docs/api/chat/rest/v1/service). This value is often a username or email address. See the Identity documentation for more details.
  --role-sid: string # The SID of the [Role](https://www.twilio.com/docs/api/chat/rest/roles) assigned to the new User.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Services/{ServiceSid}/Users"
    path_params: [{name: ServiceSid, var: service_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Attributes, var: attributes}, {name: FriendlyName, var: friendly_name}, {name: Identity, var: identity}, {name: RoleSid, var: role_sid}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://chat.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, attributes: $attributes, friendly_name: $friendly_name, identity: $identity, role_sid: $role_sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/Services/{ServiceSid}/Users/{Sid}
#
# operationId: DeleteUser
export def "delete-user" [
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
    path: "/v1/Services/{ServiceSid}/Users/{Sid}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://chat.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Services/{ServiceSid}/Users/{Sid}
#
# Returns: record<account_sid: string, attributes: string, date_created: string, date_updated: string, friendly_name: string, identity: string, is_notifiable: bool, is_online: bool, joined_channels_count: int, links: record, role_sid: string, service_sid: string, sid: string, url: string>
# operationId: FetchUser
export def "fetch-user" [
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
    path: "/v1/Services/{ServiceSid}/Users/{Sid}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://chat.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Services/{ServiceSid}/Users/{Sid}
#
# Returns: record<account_sid: string, attributes: string, date_created: string, date_updated: string, friendly_name: string, identity: string, is_notifiable: bool, is_online: bool, joined_channels_count: int, links: record, role_sid: string, service_sid: string, sid: string, url: string>
# operationId: UpdateUser
export def "update-user" [
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
  --attributes: string # A valid JSON string that contains application-specific data.
  --friendly-name: string # A descriptive string that you create to describe the resource. It is often used for display purposes.
  --role-sid: string # The SID of the [Role](https://www.twilio.com/docs/api/chat/rest/roles) assigned to this user.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Services/{ServiceSid}/Users/{Sid}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Attributes, var: attributes}, {name: FriendlyName, var: friendly_name}, {name: RoleSid, var: role_sid}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://chat.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, sid: $sid, attributes: $attributes, friendly_name: $friendly_name, role_sid: $role_sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all Channels for a given User.
#
# GET /v1/Services/{ServiceSid}/Users/{UserSid}/Channels
# Returns: record<channels: table<account_sid: string, channel_sid: string, last_consumed_message_index: int, links: record, member_sid: string, service_sid: string, status: string, unread_messages_count: int>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListUserChannel
export def "list-user-channel" [
  service_sid: string
  user_sid: string
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
    path: "/v1/Services/{ServiceSid}/Users/{UserSid}/Channels"
    path_params: [{name: ServiceSid, var: service_sid}, {name: UserSid, var: user_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://chat.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, user_sid: $user_sid, page_size: $page_size, page: $page, page_token: $page_token
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
    base_url: "https://chat.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Services/{Sid}
#
# Returns: record<account_sid: string, consumption_report_interval: int, date_created: string, date_updated: string, default_channel_creator_role_sid: string, default_channel_role_sid: string, default_service_role_sid: string, friendly_name: string, limits: any, links: record, notifications: any, post_webhook_url: string, pre_webhook_url: string, reachability_enabled: bool, read_status_enabled: bool, sid: string, typing_indicator_timeout: int, url: string, webhook_filters: list<string>, webhook_method: string, webhooks: any>
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
    base_url: "https://chat.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Services/{Sid}
#
# Returns: record<account_sid: string, consumption_report_interval: int, date_created: string, date_updated: string, default_channel_creator_role_sid: string, default_channel_role_sid: string, default_service_role_sid: string, friendly_name: string, limits: any, links: record, notifications: any, post_webhook_url: string, pre_webhook_url: string, reachability_enabled: bool, read_status_enabled: bool, sid: string, typing_indicator_timeout: int, url: string, webhook_filters: list<string>, webhook_method: string, webhooks: any>
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
  --consumption-report-interval: int # DEPRECATED. The interval in seconds between consumption reports submission batches from client endpoints.
  --default-channel-creator-role-sid: string # The channel role assigned to a channel creator when they join a new channel. See the [Roles endpoint](https://www.twilio.com/docs/chat/api/roles) for more details.
  --default-channel-role-sid: string # The channel role assigned to users when they are added to a channel. See the [Roles endpoint](https://www.twilio.com/docs/chat/api/roles) for more details.
  --default-service-role-sid: string # The service role assigned to users when they are added to the service. See the [Roles endpoint](https://www.twilio.com/docs/chat/api/roles) for more details.
  --friendly-name: string # A descriptive string that you create to describe the resource. It can be up to 64 characters long.
  --limits-channel-members: int # The maximum number of Members that can be added to Channels within this Service. Can be up to 1,000.
  --limits-user-channels: int # The maximum number of Channels Users can be a Member of within this Service. Can be up to 1,000.
  --notifications-added-to-channel-enabled: oneof<nothing, bool> # Whether to send a notification when a member is added to a channel. Can be: `true` or `false` and the default is `false`.
  --notifications-added-to-channel-template: string # The template to use to create the notification text displayed when a member is added to a channel and `notifications.added_to_channel.enabled` is `true`.
  --notifications-invited-to-channel-enabled: oneof<nothing, bool> # Whether to send a notification when a user is invited to a channel. Can be: `true` or `false` and the default is `false`.
  --notifications-invited-to-channel-template: string # The template to use to create the notification text displayed when a user is invited to a channel and `notifications.invited_to_channel.enabled` is `true`.
  --notifications-new-message-enabled: oneof<nothing, bool> # Whether to send a notification when a new message is added to a channel. Can be: `true` or `false` and the default is `false`.
  --notifications-new-message-template: string # The template to use to create the notification text displayed when a new message is added to a channel and `notifications.new_message.enabled` is `true`.
  --notifications-removed-from-channel-enabled: oneof<nothing, bool> # Whether to send a notification to a user when they are removed from a channel. Can be: `true` or `false` and the default is `false`.
  --notifications-removed-from-channel-template: string # The template to use to create the notification text displayed to a user when they are removed from a channel and `notifications.removed_from_channel.enabled` is `true`.
  --post-webhook-url: string # The URL for post-event webhooks, which are called by using the `webhook_method`. See [Webhook Events](https://www.twilio.com/docs/api/chat/webhooks) for more details. (format: uri)
  --pre-webhook-url: string # The URL for pre-event webhooks, which are called by using the `webhook_method`. See [Webhook Events](https://www.twilio.com/docs/api/chat/webhooks) for more details. (format: uri)
  --reachability-enabled: oneof<nothing, bool> # Whether to enable the [Reachability Indicator](https://www.twilio.com/docs/chat/reachability-indicator) for this Service instance. The default is `false`.
  --read-status-enabled: oneof<nothing, bool> # Whether to enable the [Message Consumption Horizon](https://www.twilio.com/docs/chat/consumption-horizon) feature. The default is `true`.
  --typing-indicator-timeout: int # How long in seconds after a `started typing` event until clients should assume that user is no longer typing, even if no `ended typing` message was received. The default is 5 seconds.
  --webhook-filters: list<string> # The list of WebHook events that are enabled for this Service instance. See [Webhook Events](https://www.twilio.com/docs/chat/webhook-events) for more details.
  --webhook-method: string@webhook-method-completer # The HTTP method to use for calls to the `pre_webhook_url` and `post_webhook_url` webhooks. Can be: `POST` or `GET` and the default is `POST`. See [Webhook Events](https://www.twilio.com/docs/chat/webhook-events) for more details. (format: http-method)
  --webhooks-on-channel-add-method: string@webhooks-on-channel-add-method-completer # The HTTP method to use when calling the `webhooks.on_channel_add.url`. (format: http-method)
  --webhooks-on-channel-add-url: string # The URL of the webhook to call in response to the `on_channel_add` event using the `webhooks.on_channel_add.method` HTTP method. (format: uri)
  --webhooks-on-channel-added-method: string@webhooks-on-channel-added-method-completer # The URL of the webhook to call in response to the `on_channel_added` event`. (format: http-method)
  --webhooks-on-channel-added-url: string # The URL of the webhook to call in response to the `on_channel_added` event using the `webhooks.on_channel_added.method` HTTP method. (format: uri)
  --webhooks-on-channel-destroy-method: string@webhooks-on-channel-destroy-method-completer # The HTTP method to use when calling the `webhooks.on_channel_destroy.url`. (format: http-method)
  --webhooks-on-channel-destroy-url: string # The URL of the webhook to call in response to the `on_channel_destroy` event using the `webhooks.on_channel_destroy.method` HTTP method. (format: uri)
  --webhooks-on-channel-destroyed-method: string@webhooks-on-channel-destroyed-method-completer # The HTTP method to use when calling the `webhooks.on_channel_destroyed.url`. (format: http-method)
  --webhooks-on-channel-destroyed-url: string # The URL of the webhook to call in response to the `on_channel_added` event using the `webhooks.on_channel_destroyed.method` HTTP method. (format: uri)
  --webhooks-on-channel-update-method: string@webhooks-on-channel-update-method-completer # The HTTP method to use when calling the `webhooks.on_channel_update.url`. (format: http-method)
  --webhooks-on-channel-update-url: string # The URL of the webhook to call in response to the `on_channel_update` event using the `webhooks.on_channel_update.method` HTTP method. (format: uri)
  --webhooks-on-channel-updated-method: string@webhooks-on-channel-updated-method-completer # The HTTP method to use when calling the `webhooks.on_channel_updated.url`. (format: http-method)
  --webhooks-on-channel-updated-url: string # The URL of the webhook to call in response to the `on_channel_updated` event using the `webhooks.on_channel_updated.method` HTTP method. (format: uri)
  --webhooks-on-member-add-method: string@webhooks-on-member-add-method-completer # The HTTP method to use when calling the `webhooks.on_member_add.url`. (format: http-method)
  --webhooks-on-member-add-url: string # The URL of the webhook to call in response to the `on_member_add` event using the `webhooks.on_member_add.method` HTTP method. (format: uri)
  --webhooks-on-member-added-method: string@webhooks-on-member-added-method-completer # The HTTP method to use when calling the `webhooks.on_channel_updated.url`. (format: http-method)
  --webhooks-on-member-added-url: string # The URL of the webhook to call in response to the `on_channel_updated` event using the `webhooks.on_channel_updated.method` HTTP method. (format: uri)
  --webhooks-on-member-remove-method: string@webhooks-on-member-remove-method-completer # The HTTP method to use when calling the `webhooks.on_member_remove.url`. (format: http-method)
  --webhooks-on-member-remove-url: string # The URL of the webhook to call in response to the `on_member_remove` event using the `webhooks.on_member_remove.method` HTTP method. (format: uri)
  --webhooks-on-member-removed-method: string@webhooks-on-member-removed-method-completer # The HTTP method to use when calling the `webhooks.on_member_removed.url`. (format: http-method)
  --webhooks-on-member-removed-url: string # The URL of the webhook to call in response to the `on_member_removed` event using the `webhooks.on_member_removed.method` HTTP method. (format: uri)
  --webhooks-on-message-remove-method: string@webhooks-on-message-remove-method-completer # The HTTP method to use when calling the `webhooks.on_message_remove.url`. (format: http-method)
  --webhooks-on-message-remove-url: string # The URL of the webhook to call in response to the `on_message_remove` event using the `webhooks.on_message_remove.method` HTTP method. (format: uri)
  --webhooks-on-message-removed-method: string@webhooks-on-message-removed-method-completer # The HTTP method to use when calling the `webhooks.on_message_removed.url`. (format: http-method)
  --webhooks-on-message-removed-url: string # The URL of the webhook to call in response to the `on_message_removed` event using the `webhooks.on_message_removed.method` HTTP method. (format: uri)
  --webhooks-on-message-send-method: string@webhooks-on-message-send-method-completer # The HTTP method to use when calling the `webhooks.on_message_send.url`. (format: http-method)
  --webhooks-on-message-send-url: string # The URL of the webhook to call in response to the `on_message_send` event using the `webhooks.on_message_send.method` HTTP method. (format: uri)
  --webhooks-on-message-sent-method: string@webhooks-on-message-sent-method-completer # The URL of the webhook to call in response to the `on_message_sent` event`. (format: http-method)
  --webhooks-on-message-sent-url: string # The URL of the webhook to call in response to the `on_message_sent` event using the `webhooks.on_message_sent.method` HTTP method. (format: uri)
  --webhooks-on-message-update-method: string@webhooks-on-message-update-method-completer # The HTTP method to use when calling the `webhooks.on_message_update.url`. (format: http-method)
  --webhooks-on-message-update-url: string # The URL of the webhook to call in response to the `on_message_update` event using the `webhooks.on_message_update.method` HTTP method. (format: uri)
  --webhooks-on-message-updated-method: string@webhooks-on-message-updated-method-completer # The HTTP method to use when calling the `webhooks.on_message_updated.url`. (format: http-method)
  --webhooks-on-message-updated-url: string # The URL of the webhook to call in response to the `on_message_updated` event using the `webhooks.on_message_updated.method` HTTP method. (format: uri)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Services/{Sid}"
    path_params: [{name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: ConsumptionReportInterval, var: consumption_report_interval}, {name: DefaultChannelCreatorRoleSid, var: default_channel_creator_role_sid}, {name: DefaultChannelRoleSid, var: default_channel_role_sid}, {name: DefaultServiceRoleSid, var: default_service_role_sid}, {name: FriendlyName, var: friendly_name}, {name: "Limits.ChannelMembers", var: limits_channel_members}, {name: "Limits.UserChannels", var: limits_user_channels}, {name: "Notifications.AddedToChannel.Enabled", var: notifications_added_to_channel_enabled}, {name: "Notifications.AddedToChannel.Template", var: notifications_added_to_channel_template}, {name: "Notifications.InvitedToChannel.Enabled", var: notifications_invited_to_channel_enabled}, {name: "Notifications.InvitedToChannel.Template", var: notifications_invited_to_channel_template}, {name: "Notifications.NewMessage.Enabled", var: notifications_new_message_enabled}, {name: "Notifications.NewMessage.Template", var: notifications_new_message_template}, {name: "Notifications.RemovedFromChannel.Enabled", var: notifications_removed_from_channel_enabled}, {name: "Notifications.RemovedFromChannel.Template", var: notifications_removed_from_channel_template}, {name: PostWebhookUrl, var: post_webhook_url}, {name: PreWebhookUrl, var: pre_webhook_url}, {name: ReachabilityEnabled, var: reachability_enabled}, {name: ReadStatusEnabled, var: read_status_enabled}, {name: TypingIndicatorTimeout, var: typing_indicator_timeout}, {name: WebhookFilters, var: webhook_filters}, {name: WebhookMethod, var: webhook_method}, {name: "Webhooks.OnChannelAdd.Method", var: webhooks_on_channel_add_method}, {name: "Webhooks.OnChannelAdd.Url", var: webhooks_on_channel_add_url}, {name: "Webhooks.OnChannelAdded.Method", var: webhooks_on_channel_added_method}, {name: "Webhooks.OnChannelAdded.Url", var: webhooks_on_channel_added_url}, {name: "Webhooks.OnChannelDestroy.Method", var: webhooks_on_channel_destroy_method}, {name: "Webhooks.OnChannelDestroy.Url", var: webhooks_on_channel_destroy_url}, {name: "Webhooks.OnChannelDestroyed.Method", var: webhooks_on_channel_destroyed_method}, {name: "Webhooks.OnChannelDestroyed.Url", var: webhooks_on_channel_destroyed_url}, {name: "Webhooks.OnChannelUpdate.Method", var: webhooks_on_channel_update_method}, {name: "Webhooks.OnChannelUpdate.Url", var: webhooks_on_channel_update_url}, {name: "Webhooks.OnChannelUpdated.Method", var: webhooks_on_channel_updated_method}, {name: "Webhooks.OnChannelUpdated.Url", var: webhooks_on_channel_updated_url}, {name: "Webhooks.OnMemberAdd.Method", var: webhooks_on_member_add_method}, {name: "Webhooks.OnMemberAdd.Url", var: webhooks_on_member_add_url}, {name: "Webhooks.OnMemberAdded.Method", var: webhooks_on_member_added_method}, {name: "Webhooks.OnMemberAdded.Url", var: webhooks_on_member_added_url}, {name: "Webhooks.OnMemberRemove.Method", var: webhooks_on_member_remove_method}, {name: "Webhooks.OnMemberRemove.Url", var: webhooks_on_member_remove_url}, {name: "Webhooks.OnMemberRemoved.Method", var: webhooks_on_member_removed_method}, {name: "Webhooks.OnMemberRemoved.Url", var: webhooks_on_member_removed_url}, {name: "Webhooks.OnMessageRemove.Method", var: webhooks_on_message_remove_method}, {name: "Webhooks.OnMessageRemove.Url", var: webhooks_on_message_remove_url}, {name: "Webhooks.OnMessageRemoved.Method", var: webhooks_on_message_removed_method}, {name: "Webhooks.OnMessageRemoved.Url", var: webhooks_on_message_removed_url}, {name: "Webhooks.OnMessageSend.Method", var: webhooks_on_message_send_method}, {name: "Webhooks.OnMessageSend.Url", var: webhooks_on_message_send_url}, {name: "Webhooks.OnMessageSent.Method", var: webhooks_on_message_sent_method}, {name: "Webhooks.OnMessageSent.Url", var: webhooks_on_message_sent_url}, {name: "Webhooks.OnMessageUpdate.Method", var: webhooks_on_message_update_method}, {name: "Webhooks.OnMessageUpdate.Url", var: webhooks_on_message_update_url}, {name: "Webhooks.OnMessageUpdated.Method", var: webhooks_on_message_updated_method}, {name: "Webhooks.OnMessageUpdated.Url", var: webhooks_on_message_updated_url}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://chat.twilio.com"
    auth: basic
  } {
    sid: $sid, consumption_report_interval: $consumption_report_interval, default_channel_creator_role_sid: $default_channel_creator_role_sid, default_channel_role_sid: $default_channel_role_sid, default_service_role_sid: $default_service_role_sid, friendly_name: $friendly_name, limits_channel_members: $limits_channel_members, limits_user_channels: $limits_user_channels, notifications_added_to_channel_enabled: $notifications_added_to_channel_enabled, notifications_added_to_channel_template: $notifications_added_to_channel_template, notifications_invited_to_channel_enabled: $notifications_invited_to_channel_enabled, notifications_invited_to_channel_template: $notifications_invited_to_channel_template, notifications_new_message_enabled: $notifications_new_message_enabled, notifications_new_message_template: $notifications_new_message_template, notifications_removed_from_channel_enabled: $notifications_removed_from_channel_enabled, notifications_removed_from_channel_template: $notifications_removed_from_channel_template, post_webhook_url: $post_webhook_url, pre_webhook_url: $pre_webhook_url, reachability_enabled: $reachability_enabled, read_status_enabled: $read_status_enabled, typing_indicator_timeout: $typing_indicator_timeout, webhook_filters: $webhook_filters, webhook_method: $webhook_method, webhooks_on_channel_add_method: $webhooks_on_channel_add_method, webhooks_on_channel_add_url: $webhooks_on_channel_add_url, webhooks_on_channel_added_method: $webhooks_on_channel_added_method, webhooks_on_channel_added_url: $webhooks_on_channel_added_url, webhooks_on_channel_destroy_method: $webhooks_on_channel_destroy_method, webhooks_on_channel_destroy_url: $webhooks_on_channel_destroy_url, webhooks_on_channel_destroyed_method: $webhooks_on_channel_destroyed_method, webhooks_on_channel_destroyed_url: $webhooks_on_channel_destroyed_url, webhooks_on_channel_update_method: $webhooks_on_channel_update_method, webhooks_on_channel_update_url: $webhooks_on_channel_update_url, webhooks_on_channel_updated_method: $webhooks_on_channel_updated_method, webhooks_on_channel_updated_url: $webhooks_on_channel_updated_url, webhooks_on_member_add_method: $webhooks_on_member_add_method, webhooks_on_member_add_url: $webhooks_on_member_add_url, webhooks_on_member_added_method: $webhooks_on_member_added_method, webhooks_on_member_added_url: $webhooks_on_member_added_url, webhooks_on_member_remove_method: $webhooks_on_member_remove_method, webhooks_on_member_remove_url: $webhooks_on_member_remove_url, webhooks_on_member_removed_method: $webhooks_on_member_removed_method, webhooks_on_member_removed_url: $webhooks_on_member_removed_url, webhooks_on_message_remove_method: $webhooks_on_message_remove_method, webhooks_on_message_remove_url: $webhooks_on_message_remove_url, webhooks_on_message_removed_method: $webhooks_on_message_removed_method, webhooks_on_message_removed_url: $webhooks_on_message_removed_url, webhooks_on_message_send_method: $webhooks_on_message_send_method, webhooks_on_message_send_url: $webhooks_on_message_send_url, webhooks_on_message_sent_method: $webhooks_on_message_sent_method, webhooks_on_message_sent_url: $webhooks_on_message_sent_url, webhooks_on_message_update_method: $webhooks_on_message_update_method, webhooks_on_message_update_url: $webhooks_on_message_update_url, webhooks_on_message_updated_method: $webhooks_on_message_updated_method, webhooks_on_message_updated_url: $webhooks_on_message_updated_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
