# Auto-generated client for Twilio - Sync v1.42.0
# Source: https://api.apis.guru/v2/specs/twilio.com/twilio_sync_v1/1.42.0/openapi.json
# Auth: --token flag or $env.TWILIO_SYNC_TOKEN

const CLIENT = {
  base_url: "https://sync.twilio.com"
  token_env_var: "TWILIO_SYNC_TOKEN"
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

def base-url-completer [] { ["https://sync.twilio.com"] }
def auth-scheme-completer [] { ["basic" "basic-credentials"] }

# Completers for enum parameters
def order-completer [] { ["asc" "desc"] }
def bounds-completer [] { ["exclusive" "inclusive"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    list-service: "record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, services: table<account_sid: string, acl_enabled: bool, date_created: string, date_updated: string, friendly_name: string, links: record, reachability_debouncing_enabled: bool, reachability_debouncing_window: int, reachability_webhooks_enabled: bool, sid: string, unique_name: string, url: string, webhook_url: string, webhooks_from_rest_enabled: bool>>"
    create-service: "record<account_sid: string, acl_enabled: bool, date_created: string, date_updated: string, friendly_name: string, links: record, reachability_debouncing_enabled: bool, reachability_debouncing_window: int, reachability_webhooks_enabled: bool, sid: string, unique_name: string, url: string, webhook_url: string, webhooks_from_rest_enabled: bool>"
    list-document: "record<documents: table<account_sid: string, created_by: string, data: any, date_created: string, date_expires: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    create-document: "record<account_sid: string, created_by: string, data: any, date_created: string, date_expires: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string>"
    list-document-permission: "record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, permissions: table<account_sid: string, document_sid: string, identity: string, manage: bool, read: bool, service_sid: string, url: string, write: bool>>"
    fetch-document-permission: "record<account_sid: string, document_sid: string, identity: string, manage: bool, read: bool, service_sid: string, url: string, write: bool>"
    update-document-permission: "record<account_sid: string, document_sid: string, identity: string, manage: bool, read: bool, service_sid: string, url: string, write: bool>"
    fetch-document: "record<account_sid: string, created_by: string, data: any, date_created: string, date_expires: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string>"
    update-document: "record<account_sid: string, created_by: string, data: any, date_created: string, date_expires: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string>"
    list-sync-list: "record<lists: table<account_sid: string, created_by: string, date_created: string, date_expires: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    create-sync-list: "record<account_sid: string, created_by: string, date_created: string, date_expires: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string>"
    list-sync-list-item: "record<items: table<account_sid: string, created_by: string, data: any, date_created: string, date_expires: string, date_updated: string, index: int, list_sid: string, revision: string, service_sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    create-sync-list-item: "record<account_sid: string, created_by: string, data: any, date_created: string, date_expires: string, date_updated: string, index: int, list_sid: string, revision: string, service_sid: string, url: string>"
    fetch-sync-list-item: "record<account_sid: string, created_by: string, data: any, date_created: string, date_expires: string, date_updated: string, index: int, list_sid: string, revision: string, service_sid: string, url: string>"
    update-sync-list-item: "record<account_sid: string, created_by: string, data: any, date_created: string, date_expires: string, date_updated: string, index: int, list_sid: string, revision: string, service_sid: string, url: string>"
    list-sync-list-permission: "record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, permissions: table<account_sid: string, identity: string, list_sid: string, manage: bool, read: bool, service_sid: string, url: string, write: bool>>"
    fetch-sync-list-permission: "record<account_sid: string, identity: string, list_sid: string, manage: bool, read: bool, service_sid: string, url: string, write: bool>"
    update-sync-list-permission: "record<account_sid: string, identity: string, list_sid: string, manage: bool, read: bool, service_sid: string, url: string, write: bool>"
    fetch-sync-list: "record<account_sid: string, created_by: string, date_created: string, date_expires: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string>"
    update-sync-list: "record<account_sid: string, created_by: string, date_created: string, date_expires: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string>"
    list-sync-map: "record<maps: table<account_sid: string, created_by: string, date_created: string, date_expires: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    create-sync-map: "record<account_sid: string, created_by: string, date_created: string, date_expires: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string>"
    list-sync-map-item: "record<items: table<account_sid: string, created_by: string, data: any, date_created: string, date_expires: string, date_updated: string, key: string, map_sid: string, revision: string, service_sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    create-sync-map-item: "record<account_sid: string, created_by: string, data: any, date_created: string, date_expires: string, date_updated: string, key: string, map_sid: string, revision: string, service_sid: string, url: string>"
    fetch-sync-map-item: "record<account_sid: string, created_by: string, data: any, date_created: string, date_expires: string, date_updated: string, key: string, map_sid: string, revision: string, service_sid: string, url: string>"
    update-sync-map-item: "record<account_sid: string, created_by: string, data: any, date_created: string, date_expires: string, date_updated: string, key: string, map_sid: string, revision: string, service_sid: string, url: string>"
    list-sync-map-permission: "record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, permissions: table<account_sid: string, identity: string, manage: bool, map_sid: string, read: bool, service_sid: string, url: string, write: bool>>"
    fetch-sync-map-permission: "record<account_sid: string, identity: string, manage: bool, map_sid: string, read: bool, service_sid: string, url: string, write: bool>"
    update-sync-map-permission: "record<account_sid: string, identity: string, manage: bool, map_sid: string, read: bool, service_sid: string, url: string, write: bool>"
    fetch-sync-map: "record<account_sid: string, created_by: string, date_created: string, date_expires: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string>"
    update-sync-map: "record<account_sid: string, created_by: string, date_created: string, date_expires: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string>"
    list-sync-stream: "record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, streams: table<account_sid: string, created_by: string, date_created: string, date_expires: string, date_updated: string, links: record, service_sid: string, sid: string, unique_name: string, url: string>>"
    create-sync-stream: "record<account_sid: string, created_by: string, date_created: string, date_expires: string, date_updated: string, links: record, service_sid: string, sid: string, unique_name: string, url: string>"
    fetch-sync-stream: "record<account_sid: string, created_by: string, date_created: string, date_expires: string, date_updated: string, links: record, service_sid: string, sid: string, unique_name: string, url: string>"
    update-sync-stream: "record<account_sid: string, created_by: string, date_created: string, date_expires: string, date_updated: string, links: record, service_sid: string, sid: string, unique_name: string, url: string>"
    create-stream-message: "record<data: any, sid: string>"
    fetch-service: "record<account_sid: string, acl_enabled: bool, date_created: string, date_updated: string, friendly_name: string, links: record, reachability_debouncing_enabled: bool, reachability_debouncing_window: int, reachability_webhooks_enabled: bool, sid: string, unique_name: string, url: string, webhook_url: string, webhooks_from_rest_enabled: bool>"
    update-service: "record<account_sid: string, acl_enabled: bool, date_created: string, date_updated: string, friendly_name: string, links: record, reachability_debouncing_enabled: bool, reachability_debouncing_window: int, reachability_webhooks_enabled: bool, sid: string, unique_name: string, url: string, webhook_url: string, webhooks_from_rest_enabled: bool>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["list-service" "create-service" "list-document" "create-document" "list-document-permission" "delete-document-permission" "fetch-document-permission" "update-document-permission" "delete-document" "fetch-document" "update-document" "list-sync-list" "create-sync-list" "list-sync-list-item" "create-sync-list-item" "delete-sync-list-item" "fetch-sync-list-item" "update-sync-list-item" "list-sync-list-permission" "delete-sync-list-permission" "fetch-sync-list-permission" "update-sync-list-permission" "delete-sync-list" "fetch-sync-list" "update-sync-list" "list-sync-map" "create-sync-map" "list-sync-map-item" "create-sync-map-item" "delete-sync-map-item" "fetch-sync-map-item" "update-sync-map-item" "list-sync-map-permission" "delete-sync-map-permission" "fetch-sync-map-permission" "update-sync-map-permission" "delete-sync-map" "fetch-sync-map" "update-sync-map" "list-sync-stream" "create-sync-stream" "delete-sync-stream" "fetch-sync-stream" "update-sync-stream" "create-stream-message" "delete-service" "fetch-service" "update-service" "commands"] | sort) } | get name | first)
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

# GET /v1/Services
#
# Returns: record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, services: table<account_sid: string, acl_enabled: bool, date_created: string, date_updated: string, friendly_name: string, links: record, reachability_debouncing_enabled: bool, reachability_debouncing_window: int, reachability_webhooks_enabled: bool, sid: string, unique_name: string, url: string, webhook_url: string, webhooks_from_rest_enabled: bool>>
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
    base_url: "https://sync.twilio.com"
    auth: basic
  } {
    page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Services
#
# Returns: record<account_sid: string, acl_enabled: bool, date_created: string, date_updated: string, friendly_name: string, links: record, reachability_debouncing_enabled: bool, reachability_debouncing_window: int, reachability_webhooks_enabled: bool, sid: string, unique_name: string, url: string, webhook_url: string, webhooks_from_rest_enabled: bool>
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
  --acl-enabled: oneof<nothing, bool> # Whether token identities in the Service must be granted access to Sync objects by using the [Permissions](https://www.twilio.com/docs/sync/api/sync-permissions) resource.
  --friendly-name: string # A string that you assign to describe the resource.
  --reachability-debouncing-enabled: oneof<nothing, bool> # Whether every `endpoint_disconnected` event should occur after a configurable delay. The default is `false`, where the `endpoint_disconnected` event occurs immediately after disconnection. When `true`, intervening reconnections can prevent the `endpoint_disconnected` event.
  --reachability-debouncing-window: int # The reachability event delay in milliseconds if `reachability_debouncing_enabled` = `true`. Must be between 1,000 and 30,000 and defaults to 5,000. This is the number of milliseconds after the last running client disconnects, and a Sync identity is declared offline, before the `webhook_url` is called if all endpoints remain offline. A reconnection from the same identity by any endpoint during this interval prevents the call to `webhook_url`.
  --reachability-webhooks-enabled: oneof<nothing, bool> # Whether the service instance should call `webhook_url` when client endpoints connect to Sync. The default is `false`.
  --webhook-url: string # The URL we should call when Sync objects are manipulated. (format: uri)
  --webhooks-from-rest-enabled: oneof<nothing, bool> # Whether the Service instance should call `webhook_url` when the REST API is used to update Sync objects. The default is `false`.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Services"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: AclEnabled, var: acl_enabled}, {name: FriendlyName, var: friendly_name}, {name: ReachabilityDebouncingEnabled, var: reachability_debouncing_enabled}, {name: ReachabilityDebouncingWindow, var: reachability_debouncing_window}, {name: ReachabilityWebhooksEnabled, var: reachability_webhooks_enabled}, {name: WebhookUrl, var: webhook_url}, {name: WebhooksFromRestEnabled, var: webhooks_from_rest_enabled}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://sync.twilio.com"
    auth: basic
  } {
    acl_enabled: $acl_enabled, friendly_name: $friendly_name, reachability_debouncing_enabled: $reachability_debouncing_enabled, reachability_debouncing_window: $reachability_debouncing_window, reachability_webhooks_enabled: $reachability_webhooks_enabled, webhook_url: $webhook_url, webhooks_from_rest_enabled: $webhooks_from_rest_enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Services/{ServiceSid}/Documents
#
# Returns: record<documents: table<account_sid: string, created_by: string, data: any, date_created: string, date_expires: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListDocument
export def "list-document" [
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
    path: "/v1/Services/{ServiceSid}/Documents"
    path_params: [{name: ServiceSid, var: service_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://sync.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Services/{ServiceSid}/Documents
#
# Returns: record<account_sid: string, created_by: string, data: any, date_created: string, date_expires: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string>
# operationId: CreateDocument
export def "create-document" [
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
  --data: any # A JSON string that represents an arbitrary, schema-less object that the Sync Document stores. Can be up to 16 KiB in length.
  --ttl: int # How long, [in seconds](https://www.twilio.com/docs/sync/limits#sync-payload-limits), before the Sync Document expires and is deleted (the Sync Document's time-to-live).
  --unique-name: string # An application-defined string that uniquely identifies the Sync Document
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Services/{ServiceSid}/Documents"
    path_params: [{name: ServiceSid, var: service_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Data, var: data}, {name: Ttl, var: ttl}, {name: UniqueName, var: unique_name}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://sync.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, data: $data, ttl: $ttl, unique_name: $unique_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of all Permissions applying to a Sync Document.
#
# GET /v1/Services/{ServiceSid}/Documents/{DocumentSid}/Permissions
# Returns: record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, permissions: table<account_sid: string, document_sid: string, identity: string, manage: bool, read: bool, service_sid: string, url: string, write: bool>>
# operationId: ListDocumentPermission
export def "list-document-permission" [
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
    path: "/v1/Services/{ServiceSid}/Documents/{DocumentSid}/Permissions"
    path_params: [{name: ServiceSid, var: service_sid}, {name: DocumentSid, var: document_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://sync.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, document_sid: $document_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a specific Sync Document Permission.
#
# DELETE /v1/Services/{ServiceSid}/Documents/{DocumentSid}/Permissions/{Identity}
# operationId: DeleteDocumentPermission
export def "delete-document-permission" [
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
    path: "/v1/Services/{ServiceSid}/Documents/{DocumentSid}/Permissions/{Identity}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: DocumentSid, var: document_sid}, {name: Identity, var: identity}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://sync.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, document_sid: $document_sid, identity: $identity
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a specific Sync Document Permission.
#
# GET /v1/Services/{ServiceSid}/Documents/{DocumentSid}/Permissions/{Identity}
# Returns: record<account_sid: string, document_sid: string, identity: string, manage: bool, read: bool, service_sid: string, url: string, write: bool>
# operationId: FetchDocumentPermission
export def "fetch-document-permission" [
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
    path: "/v1/Services/{ServiceSid}/Documents/{DocumentSid}/Permissions/{Identity}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: DocumentSid, var: document_sid}, {name: Identity, var: identity}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://sync.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, document_sid: $document_sid, identity: $identity
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an identity's access to a specific Sync Document.
#
# POST /v1/Services/{ServiceSid}/Documents/{DocumentSid}/Permissions/{Identity}
# Returns: record<account_sid: string, document_sid: string, identity: string, manage: bool, read: bool, service_sid: string, url: string, write: bool>
# operationId: UpdateDocumentPermission
export def "update-document-permission" [
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
  --manage: oneof<nothing, bool> # Whether the identity can delete the Sync Document. Default value is `false`.
  --read: oneof<nothing, bool> # Whether the identity can read the Sync Document. Default value is `false`.
  --write: oneof<nothing, bool> # Whether the identity can update the Sync Document. Default value is `false`.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Services/{ServiceSid}/Documents/{DocumentSid}/Permissions/{Identity}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: DocumentSid, var: document_sid}, {name: Identity, var: identity}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Manage, var: manage, required: true}, {name: Read, var: read, required: true}, {name: Write, var: write, required: true}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://sync.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, document_sid: $document_sid, identity: $identity, manage: $manage, read: $read, write: $write
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/Services/{ServiceSid}/Documents/{Sid}
#
# operationId: DeleteDocument
export def "delete-document" [
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
    path: "/v1/Services/{ServiceSid}/Documents/{Sid}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://sync.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Services/{ServiceSid}/Documents/{Sid}
#
# Returns: record<account_sid: string, created_by: string, data: any, date_created: string, date_expires: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string>
# operationId: FetchDocument
export def "fetch-document" [
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
    path: "/v1/Services/{ServiceSid}/Documents/{Sid}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://sync.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Services/{ServiceSid}/Documents/{Sid}
#
# Returns: record<account_sid: string, created_by: string, data: any, date_created: string, date_expires: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string>
# operationId: UpdateDocument
export def "update-document" [
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
  --data: any # A JSON string that represents an arbitrary, schema-less object that the Sync Document stores. Can be up to 16 KiB in length.
  --ttl: int # How long, [in seconds](https://www.twilio.com/docs/sync/limits#sync-payload-limits), before the Sync Document expires and is deleted (time-to-live).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Services/{ServiceSid}/Documents/{Sid}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: Sid, var: sid}]
    header: [{name: If-Match, var: if_match}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Data, var: data}, {name: Ttl, var: ttl}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://sync.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, sid: $sid, if_match: $if_match, data: $data, ttl: $ttl
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Services/{ServiceSid}/Lists
#
# Returns: record<lists: table<account_sid: string, created_by: string, date_created: string, date_expires: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListSyncList
export def "list-sync-list" [
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
    path: "/v1/Services/{ServiceSid}/Lists"
    path_params: [{name: ServiceSid, var: service_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://sync.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Services/{ServiceSid}/Lists
#
# Returns: record<account_sid: string, created_by: string, date_created: string, date_expires: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string>
# operationId: CreateSyncList
export def "create-sync-list" [
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
  --collection-ttl: int # How long, [in seconds](https://www.twilio.com/docs/sync/limits#sync-payload-limits), before the Sync List expires (time-to-live) and is deleted.
  --ttl: int # Alias for collection_ttl. If both are provided, this value is ignored.
  --unique-name: string # An application-defined string that uniquely identifies the resource. This value must be unique within its Service and it can be up to 320 characters long. The `unique_name` value can be used as an alternative to the `sid` in the URL path to address the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Services/{ServiceSid}/Lists"
    path_params: [{name: ServiceSid, var: service_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: CollectionTtl, var: collection_ttl}, {name: Ttl, var: ttl}, {name: UniqueName, var: unique_name}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://sync.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, collection_ttl: $collection_ttl, ttl: $ttl, unique_name: $unique_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Services/{ServiceSid}/Lists/{ListSid}/Items
#
# Returns: record<items: table<account_sid: string, created_by: string, data: any, date_created: string, date_expires: string, date_updated: string, index: int, list_sid: string, revision: string, service_sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListSyncListItem
export def "list-sync-list-item" [
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
  --order: string@order-completer # How to order the List Items returned by their `index` value. Can be: `asc` (ascending) or `desc` (descending) and the default is ascending.
  --from: string # The `index` of the first Sync List Item resource to read. See also `bounds`.
  --bounds: string@bounds-completer # Whether to include the List Item referenced by the `from` parameter. Can be: `inclusive` to include the List Item referenced by the `from` parameter or `exclusive` to start with the next List Item. The default value is `inclusive`.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/Services/{ServiceSid}/Lists/{ListSid}/Items"
    path_params: [{name: ServiceSid, var: service_sid}, {name: ListSid, var: list_sid}]
    query: [{name: Order, var: order}, {name: From, var: from}, {name: Bounds, var: bounds}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://sync.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, list_sid: $list_sid, order: $order, from: $from, bounds: $bounds, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Services/{ServiceSid}/Lists/{ListSid}/Items
#
# Returns: record<account_sid: string, created_by: string, data: any, date_created: string, date_expires: string, date_updated: string, index: int, list_sid: string, revision: string, service_sid: string, url: string>
# operationId: CreateSyncListItem
export def "create-sync-list-item" [
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
  --collection-ttl: int # How long, [in seconds](https://www.twilio.com/docs/sync/limits#sync-payload-limits), before the List Item's parent Sync List expires (time-to-live) and is deleted.
  data: any # A JSON string that represents an arbitrary, schema-less object that the List Item stores. Can be up to 16 KiB in length.
  --item-ttl: int # How long, [in seconds](https://www.twilio.com/docs/sync/limits#sync-payload-limits), before the List Item expires (time-to-live) and is deleted.
  --ttl: int # An alias for `item_ttl`. If both parameters are provided, this value is ignored.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Services/{ServiceSid}/Lists/{ListSid}/Items"
    path_params: [{name: ServiceSid, var: service_sid}, {name: ListSid, var: list_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: CollectionTtl, var: collection_ttl}, {name: Data, var: data}, {name: ItemTtl, var: item_ttl}, {name: Ttl, var: ttl}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://sync.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, list_sid: $list_sid, collection_ttl: $collection_ttl, data: $data, item_ttl: $item_ttl, ttl: $ttl
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/Services/{ServiceSid}/Lists/{ListSid}/Items/{Index}
#
# operationId: DeleteSyncListItem
export def "delete-sync-list-item" [
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
  --if-match: string # If provided, applies this mutation if (and only if) the “revision” field of this [map item] matches the provided value. This matches the semantics of (and is implemented with) the HTTP [If-Match header](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/If-Match).
]: nothing -> any {
  http-request {
    method: delete
    path: "/v1/Services/{ServiceSid}/Lists/{ListSid}/Items/{Index}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: ListSid, var: list_sid}, {name: Index, var: index}]
    header: [{name: If-Match, var: if_match}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://sync.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, list_sid: $list_sid, index: $index, if_match: $if_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Services/{ServiceSid}/Lists/{ListSid}/Items/{Index}
#
# Returns: record<account_sid: string, created_by: string, data: any, date_created: string, date_expires: string, date_updated: string, index: int, list_sid: string, revision: string, service_sid: string, url: string>
# operationId: FetchSyncListItem
export def "fetch-sync-list-item" [
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
    path: "/v1/Services/{ServiceSid}/Lists/{ListSid}/Items/{Index}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: ListSid, var: list_sid}, {name: Index, var: index}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://sync.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, list_sid: $list_sid, index: $index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Services/{ServiceSid}/Lists/{ListSid}/Items/{Index}
#
# Returns: record<account_sid: string, created_by: string, data: any, date_created: string, date_expires: string, date_updated: string, index: int, list_sid: string, revision: string, service_sid: string, url: string>
# operationId: UpdateSyncListItem
export def "update-sync-list-item" [
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
  --if-match: string # If provided, applies this mutation if (and only if) the “revision” field of this [map item] matches the provided value. This matches the semantics of (and is implemented with) the HTTP [If-Match header](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/If-Match).
  --collection-ttl: int # How long, [in seconds](https://www.twilio.com/docs/sync/limits#sync-payload-limits), before the List Item's parent Sync List expires (time-to-live) and is deleted. This parameter can only be used when the List Item's `data` or `ttl` is updated in the same request.
  --data: any # A JSON string that represents an arbitrary, schema-less object that the List Item stores. Can be up to 16 KiB in length.
  --item-ttl: int # How long, [in seconds](https://www.twilio.com/docs/sync/limits#sync-payload-limits), before the List Item expires (time-to-live) and is deleted.
  --ttl: int # An alias for `item_ttl`. If both parameters are provided, this value is ignored.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Services/{ServiceSid}/Lists/{ListSid}/Items/{Index}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: ListSid, var: list_sid}, {name: Index, var: index}]
    header: [{name: If-Match, var: if_match}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: CollectionTtl, var: collection_ttl}, {name: Data, var: data}, {name: ItemTtl, var: item_ttl}, {name: Ttl, var: ttl}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://sync.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, list_sid: $list_sid, index: $index, if_match: $if_match, collection_ttl: $collection_ttl, data: $data, item_ttl: $item_ttl, ttl: $ttl
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of all Permissions applying to a Sync List.
#
# GET /v1/Services/{ServiceSid}/Lists/{ListSid}/Permissions
# Returns: record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, permissions: table<account_sid: string, identity: string, list_sid: string, manage: bool, read: bool, service_sid: string, url: string, write: bool>>
# operationId: ListSyncListPermission
export def "list-sync-list-permission" [
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
    path: "/v1/Services/{ServiceSid}/Lists/{ListSid}/Permissions"
    path_params: [{name: ServiceSid, var: service_sid}, {name: ListSid, var: list_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://sync.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, list_sid: $list_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a specific Sync List Permission.
#
# DELETE /v1/Services/{ServiceSid}/Lists/{ListSid}/Permissions/{Identity}
# operationId: DeleteSyncListPermission
export def "delete-sync-list-permission" [
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
    path: "/v1/Services/{ServiceSid}/Lists/{ListSid}/Permissions/{Identity}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: ListSid, var: list_sid}, {name: Identity, var: identity}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://sync.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, list_sid: $list_sid, identity: $identity
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a specific Sync List Permission.
#
# GET /v1/Services/{ServiceSid}/Lists/{ListSid}/Permissions/{Identity}
# Returns: record<account_sid: string, identity: string, list_sid: string, manage: bool, read: bool, service_sid: string, url: string, write: bool>
# operationId: FetchSyncListPermission
export def "fetch-sync-list-permission" [
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
    path: "/v1/Services/{ServiceSid}/Lists/{ListSid}/Permissions/{Identity}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: ListSid, var: list_sid}, {name: Identity, var: identity}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://sync.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, list_sid: $list_sid, identity: $identity
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an identity's access to a specific Sync List.
#
# POST /v1/Services/{ServiceSid}/Lists/{ListSid}/Permissions/{Identity}
# Returns: record<account_sid: string, identity: string, list_sid: string, manage: bool, read: bool, service_sid: string, url: string, write: bool>
# operationId: UpdateSyncListPermission
export def "update-sync-list-permission" [
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
  --manage: oneof<nothing, bool> # Whether the identity can delete the Sync List. Default value is `false`.
  --read: oneof<nothing, bool> # Whether the identity can read the Sync List and its Items. Default value is `false`.
  --write: oneof<nothing, bool> # Whether the identity can create, update, and delete Items in the Sync List. Default value is `false`.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Services/{ServiceSid}/Lists/{ListSid}/Permissions/{Identity}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: ListSid, var: list_sid}, {name: Identity, var: identity}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Manage, var: manage, required: true}, {name: Read, var: read, required: true}, {name: Write, var: write, required: true}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://sync.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, list_sid: $list_sid, identity: $identity, manage: $manage, read: $read, write: $write
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/Services/{ServiceSid}/Lists/{Sid}
#
# operationId: DeleteSyncList
export def "delete-sync-list" [
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
    path: "/v1/Services/{ServiceSid}/Lists/{Sid}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://sync.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Services/{ServiceSid}/Lists/{Sid}
#
# Returns: record<account_sid: string, created_by: string, date_created: string, date_expires: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string>
# operationId: FetchSyncList
export def "fetch-sync-list" [
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
    path: "/v1/Services/{ServiceSid}/Lists/{Sid}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://sync.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Services/{ServiceSid}/Lists/{Sid}
#
# Returns: record<account_sid: string, created_by: string, date_created: string, date_expires: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string>
# operationId: UpdateSyncList
export def "update-sync-list" [
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
  --collection-ttl: int # How long, [in seconds](https://www.twilio.com/docs/sync/limits#sync-payload-limits), before the Sync List expires (time-to-live) and is deleted.
  --ttl: int # An alias for `collection_ttl`. If both are provided, this value is ignored.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Services/{ServiceSid}/Lists/{Sid}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: CollectionTtl, var: collection_ttl}, {name: Ttl, var: ttl}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://sync.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, sid: $sid, collection_ttl: $collection_ttl, ttl: $ttl
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Services/{ServiceSid}/Maps
#
# Returns: record<maps: table<account_sid: string, created_by: string, date_created: string, date_expires: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListSyncMap
export def "list-sync-map" [
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
    path: "/v1/Services/{ServiceSid}/Maps"
    path_params: [{name: ServiceSid, var: service_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://sync.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Services/{ServiceSid}/Maps
#
# Returns: record<account_sid: string, created_by: string, date_created: string, date_expires: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string>
# operationId: CreateSyncMap
export def "create-sync-map" [
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
  --collection-ttl: int # How long, [in seconds](https://www.twilio.com/docs/sync/limits#sync-payload-limits), before the Sync Map expires (time-to-live) and is deleted.
  --ttl: int # An alias for `collection_ttl`. If both parameters are provided, this value is ignored.
  --unique-name: string # An application-defined string that uniquely identifies the resource. It can be used as an alternative to the `sid` in the URL path to address the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Services/{ServiceSid}/Maps"
    path_params: [{name: ServiceSid, var: service_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: CollectionTtl, var: collection_ttl}, {name: Ttl, var: ttl}, {name: UniqueName, var: unique_name}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://sync.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, collection_ttl: $collection_ttl, ttl: $ttl, unique_name: $unique_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Services/{ServiceSid}/Maps/{MapSid}/Items
#
# Returns: record<items: table<account_sid: string, created_by: string, data: any, date_created: string, date_expires: string, date_updated: string, key: string, map_sid: string, revision: string, service_sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListSyncMapItem
export def "list-sync-map-item" [
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
  --order: string@order-completer # How to order the Map Items returned by their `key` value. Can be: `asc` (ascending) or `desc` (descending) and the default is ascending. Map Items are [ordered lexicographically](https://en.wikipedia.org/wiki/Lexicographical_order) by Item key.
  --from: string # The `key` of the first Sync Map Item resource to read. See also `bounds`.
  --bounds: string@bounds-completer # Whether to include the Map Item referenced by the `from` parameter. Can be: `inclusive` to include the Map Item referenced by the `from` parameter or `exclusive` to start with the next Map Item. The default value is `inclusive`.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/Services/{ServiceSid}/Maps/{MapSid}/Items"
    path_params: [{name: ServiceSid, var: service_sid}, {name: MapSid, var: map_sid}]
    query: [{name: Order, var: order}, {name: From, var: from}, {name: Bounds, var: bounds}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://sync.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, map_sid: $map_sid, order: $order, from: $from, bounds: $bounds, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Services/{ServiceSid}/Maps/{MapSid}/Items
#
# Returns: record<account_sid: string, created_by: string, data: any, date_created: string, date_expires: string, date_updated: string, key: string, map_sid: string, revision: string, service_sid: string, url: string>
# operationId: CreateSyncMapItem
export def "create-sync-map-item" [
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
  --collection-ttl: int # How long, [in seconds](https://www.twilio.com/docs/sync/limits#sync-payload-limits), before the Map Item's parent Sync Map expires (time-to-live) and is deleted.
  data: any # A JSON string that represents an arbitrary, schema-less object that the Map Item stores. Can be up to 16 KiB in length.
  --item-ttl: int # How long, [in seconds](https://www.twilio.com/docs/sync/limits#sync-payload-limits), before the Map Item expires (time-to-live) and is deleted.
  key: string # The unique, user-defined key for the Map Item. Can be up to 320 characters long.
  --ttl: int # An alias for `item_ttl`. If both parameters are provided, this value is ignored.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Services/{ServiceSid}/Maps/{MapSid}/Items"
    path_params: [{name: ServiceSid, var: service_sid}, {name: MapSid, var: map_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: CollectionTtl, var: collection_ttl}, {name: Data, var: data}, {name: ItemTtl, var: item_ttl}, {name: Key, var: key}, {name: Ttl, var: ttl}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://sync.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, map_sid: $map_sid, collection_ttl: $collection_ttl, data: $data, item_ttl: $item_ttl, key: $key, ttl: $ttl
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/Services/{ServiceSid}/Maps/{MapSid}/Items/{Key}
#
# operationId: DeleteSyncMapItem
export def "delete-sync-map-item" [
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
  --if-match: string # If provided, applies this mutation if (and only if) the “revision” field of this [map item] matches the provided value. This matches the semantics of (and is implemented with) the HTTP [If-Match header](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/If-Match).
]: nothing -> any {
  http-request {
    method: delete
    path: "/v1/Services/{ServiceSid}/Maps/{MapSid}/Items/{Key}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: MapSid, var: map_sid}, {name: Key, var: key}]
    header: [{name: If-Match, var: if_match}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://sync.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, map_sid: $map_sid, key: $key, if_match: $if_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Services/{ServiceSid}/Maps/{MapSid}/Items/{Key}
#
# Returns: record<account_sid: string, created_by: string, data: any, date_created: string, date_expires: string, date_updated: string, key: string, map_sid: string, revision: string, service_sid: string, url: string>
# operationId: FetchSyncMapItem
export def "fetch-sync-map-item" [
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
    path: "/v1/Services/{ServiceSid}/Maps/{MapSid}/Items/{Key}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: MapSid, var: map_sid}, {name: Key, var: key}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://sync.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, map_sid: $map_sid, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Services/{ServiceSid}/Maps/{MapSid}/Items/{Key}
#
# Returns: record<account_sid: string, created_by: string, data: any, date_created: string, date_expires: string, date_updated: string, key: string, map_sid: string, revision: string, service_sid: string, url: string>
# operationId: UpdateSyncMapItem
export def "update-sync-map-item" [
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
  --if-match: string # If provided, applies this mutation if (and only if) the “revision” field of this [map item] matches the provided value. This matches the semantics of (and is implemented with) the HTTP [If-Match header](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/If-Match).
  --collection-ttl: int # How long, [in seconds](https://www.twilio.com/docs/sync/limits#sync-payload-limits), before the Map Item's parent Sync Map expires (time-to-live) and is deleted. This parameter can only be used when the Map Item's `data` or `ttl` is updated in the same request.
  --data: any # A JSON string that represents an arbitrary, schema-less object that the Map Item stores. Can be up to 16 KiB in length.
  --item-ttl: int # How long, [in seconds](https://www.twilio.com/docs/sync/limits#sync-payload-limits), before the Map Item expires (time-to-live) and is deleted.
  --ttl: int # An alias for `item_ttl`. If both parameters are provided, this value is ignored.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Services/{ServiceSid}/Maps/{MapSid}/Items/{Key}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: MapSid, var: map_sid}, {name: Key, var: key}]
    header: [{name: If-Match, var: if_match}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: CollectionTtl, var: collection_ttl}, {name: Data, var: data}, {name: ItemTtl, var: item_ttl}, {name: Ttl, var: ttl}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://sync.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, map_sid: $map_sid, key: $key, if_match: $if_match, collection_ttl: $collection_ttl, data: $data, item_ttl: $item_ttl, ttl: $ttl
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of all Permissions applying to a Sync Map.
#
# GET /v1/Services/{ServiceSid}/Maps/{MapSid}/Permissions
# Returns: record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, permissions: table<account_sid: string, identity: string, manage: bool, map_sid: string, read: bool, service_sid: string, url: string, write: bool>>
# operationId: ListSyncMapPermission
export def "list-sync-map-permission" [
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
    path: "/v1/Services/{ServiceSid}/Maps/{MapSid}/Permissions"
    path_params: [{name: ServiceSid, var: service_sid}, {name: MapSid, var: map_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://sync.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, map_sid: $map_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a specific Sync Map Permission.
#
# DELETE /v1/Services/{ServiceSid}/Maps/{MapSid}/Permissions/{Identity}
# operationId: DeleteSyncMapPermission
export def "delete-sync-map-permission" [
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
    path: "/v1/Services/{ServiceSid}/Maps/{MapSid}/Permissions/{Identity}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: MapSid, var: map_sid}, {name: Identity, var: identity}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://sync.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, map_sid: $map_sid, identity: $identity
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a specific Sync Map Permission.
#
# GET /v1/Services/{ServiceSid}/Maps/{MapSid}/Permissions/{Identity}
# Returns: record<account_sid: string, identity: string, manage: bool, map_sid: string, read: bool, service_sid: string, url: string, write: bool>
# operationId: FetchSyncMapPermission
export def "fetch-sync-map-permission" [
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
    path: "/v1/Services/{ServiceSid}/Maps/{MapSid}/Permissions/{Identity}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: MapSid, var: map_sid}, {name: Identity, var: identity}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://sync.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, map_sid: $map_sid, identity: $identity
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an identity's access to a specific Sync Map.
#
# POST /v1/Services/{ServiceSid}/Maps/{MapSid}/Permissions/{Identity}
# Returns: record<account_sid: string, identity: string, manage: bool, map_sid: string, read: bool, service_sid: string, url: string, write: bool>
# operationId: UpdateSyncMapPermission
export def "update-sync-map-permission" [
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
  --manage: oneof<nothing, bool> # Whether the identity can delete the Sync Map. Default value is `false`.
  --read: oneof<nothing, bool> # Whether the identity can read the Sync Map and its Items. Default value is `false`.
  --write: oneof<nothing, bool> # Whether the identity can create, update, and delete Items in the Sync Map. Default value is `false`.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Services/{ServiceSid}/Maps/{MapSid}/Permissions/{Identity}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: MapSid, var: map_sid}, {name: Identity, var: identity}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Manage, var: manage, required: true}, {name: Read, var: read, required: true}, {name: Write, var: write, required: true}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://sync.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, map_sid: $map_sid, identity: $identity, manage: $manage, read: $read, write: $write
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/Services/{ServiceSid}/Maps/{Sid}
#
# operationId: DeleteSyncMap
export def "delete-sync-map" [
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
    path: "/v1/Services/{ServiceSid}/Maps/{Sid}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://sync.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Services/{ServiceSid}/Maps/{Sid}
#
# Returns: record<account_sid: string, created_by: string, date_created: string, date_expires: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string>
# operationId: FetchSyncMap
export def "fetch-sync-map" [
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
    path: "/v1/Services/{ServiceSid}/Maps/{Sid}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://sync.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Services/{ServiceSid}/Maps/{Sid}
#
# Returns: record<account_sid: string, created_by: string, date_created: string, date_expires: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string>
# operationId: UpdateSyncMap
export def "update-sync-map" [
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
  --collection-ttl: int # How long, [in seconds](https://www.twilio.com/docs/sync/limits#sync-payload-limits), before the Sync Map expires (time-to-live) and is deleted.
  --ttl: int # An alias for `collection_ttl`. If both parameters are provided, this value is ignored.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Services/{ServiceSid}/Maps/{Sid}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: CollectionTtl, var: collection_ttl}, {name: Ttl, var: ttl}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://sync.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, sid: $sid, collection_ttl: $collection_ttl, ttl: $ttl
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of all Streams in a Service Instance.
#
# GET /v1/Services/{ServiceSid}/Streams
# Returns: record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, streams: table<account_sid: string, created_by: string, date_created: string, date_expires: string, date_updated: string, links: record, service_sid: string, sid: string, unique_name: string, url: string>>
# operationId: ListSyncStream
export def "list-sync-stream" [
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
    path: "/v1/Services/{ServiceSid}/Streams"
    path_params: [{name: ServiceSid, var: service_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://sync.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new Stream.
#
# POST /v1/Services/{ServiceSid}/Streams
# Returns: record<account_sid: string, created_by: string, date_created: string, date_expires: string, date_updated: string, links: record, service_sid: string, sid: string, unique_name: string, url: string>
# operationId: CreateSyncStream
export def "create-sync-stream" [
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
  --ttl: int # How long, [in seconds](https://www.twilio.com/docs/sync/limits#sync-payload-limits), before the Stream expires and is deleted (time-to-live).
  --unique-name: string # An application-defined string that uniquely identifies the resource. This value must be unique within its Service and it can be up to 320 characters long. The `unique_name` value can be used as an alternative to the `sid` in the URL path to address the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Services/{ServiceSid}/Streams"
    path_params: [{name: ServiceSid, var: service_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Ttl, var: ttl}, {name: UniqueName, var: unique_name}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://sync.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, ttl: $ttl, unique_name: $unique_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a specific Stream.
#
# DELETE /v1/Services/{ServiceSid}/Streams/{Sid}
# operationId: DeleteSyncStream
export def "delete-sync-stream" [
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
    path: "/v1/Services/{ServiceSid}/Streams/{Sid}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://sync.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a specific Stream.
#
# GET /v1/Services/{ServiceSid}/Streams/{Sid}
# Returns: record<account_sid: string, created_by: string, date_created: string, date_expires: string, date_updated: string, links: record, service_sid: string, sid: string, unique_name: string, url: string>
# operationId: FetchSyncStream
export def "fetch-sync-stream" [
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
    path: "/v1/Services/{ServiceSid}/Streams/{Sid}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://sync.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a specific Stream.
#
# POST /v1/Services/{ServiceSid}/Streams/{Sid}
# Returns: record<account_sid: string, created_by: string, date_created: string, date_expires: string, date_updated: string, links: record, service_sid: string, sid: string, unique_name: string, url: string>
# operationId: UpdateSyncStream
export def "update-sync-stream" [
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
  --ttl: int # How long, [in seconds](https://www.twilio.com/docs/sync/limits#sync-payload-limits), before the Stream expires and is deleted (time-to-live).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Services/{ServiceSid}/Streams/{Sid}"
    path_params: [{name: ServiceSid, var: service_sid}, {name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Ttl, var: ttl}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://sync.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, sid: $sid, ttl: $ttl
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new Stream Message.
#
# POST /v1/Services/{ServiceSid}/Streams/{StreamSid}/Messages
# Returns: record<data: any, sid: string>
# operationId: CreateStreamMessage
export def "create-stream-message" [
  service_sid: string
  stream_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  data: any # A JSON string that represents an arbitrary, schema-less object that makes up the Stream Message body. Can be up to 4 KiB in length.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Services/{ServiceSid}/Streams/{StreamSid}/Messages"
    path_params: [{name: ServiceSid, var: service_sid}, {name: StreamSid, var: stream_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Data, var: data}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://sync.twilio.com"
    auth: basic
  } {
    service_sid: $service_sid, stream_sid: $stream_sid, data: $data
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
    base_url: "https://sync.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Services/{Sid}
#
# Returns: record<account_sid: string, acl_enabled: bool, date_created: string, date_updated: string, friendly_name: string, links: record, reachability_debouncing_enabled: bool, reachability_debouncing_window: int, reachability_webhooks_enabled: bool, sid: string, unique_name: string, url: string, webhook_url: string, webhooks_from_rest_enabled: bool>
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
    base_url: "https://sync.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Services/{Sid}
#
# Returns: record<account_sid: string, acl_enabled: bool, date_created: string, date_updated: string, friendly_name: string, links: record, reachability_debouncing_enabled: bool, reachability_debouncing_window: int, reachability_webhooks_enabled: bool, sid: string, unique_name: string, url: string, webhook_url: string, webhooks_from_rest_enabled: bool>
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
  --acl-enabled: oneof<nothing, bool> # Whether token identities in the Service must be granted access to Sync objects by using the [Permissions](https://www.twilio.com/docs/sync/api/sync-permissions) resource.
  --friendly-name: string # A string that you assign to describe the resource.
  --reachability-debouncing-enabled: oneof<nothing, bool> # Whether every `endpoint_disconnected` event should occur after a configurable delay. The default is `false`, where the `endpoint_disconnected` event occurs immediately after disconnection. When `true`, intervening reconnections can prevent the `endpoint_disconnected` event.
  --reachability-debouncing-window: int # The reachability event delay in milliseconds if `reachability_debouncing_enabled` = `true`. Must be between 1,000 and 30,000 and defaults to 5,000. This is the number of milliseconds after the last running client disconnects, and a Sync identity is declared offline, before the webhook is called if all endpoints remain offline. A reconnection from the same identity by any endpoint during this interval prevents the webhook from being called.
  --reachability-webhooks-enabled: oneof<nothing, bool> # Whether the service instance should call `webhook_url` when client endpoints connect to Sync. The default is `false`.
  --webhook-url: string # The URL we should call when Sync objects are manipulated. (format: uri)
  --webhooks-from-rest-enabled: oneof<nothing, bool> # Whether the Service instance should call `webhook_url` when the REST API is used to update Sync objects. The default is `false`.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Services/{Sid}"
    path_params: [{name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: AclEnabled, var: acl_enabled}, {name: FriendlyName, var: friendly_name}, {name: ReachabilityDebouncingEnabled, var: reachability_debouncing_enabled}, {name: ReachabilityDebouncingWindow, var: reachability_debouncing_window}, {name: ReachabilityWebhooksEnabled, var: reachability_webhooks_enabled}, {name: WebhookUrl, var: webhook_url}, {name: WebhooksFromRestEnabled, var: webhooks_from_rest_enabled}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://sync.twilio.com"
    auth: basic
  } {
    sid: $sid, acl_enabled: $acl_enabled, friendly_name: $friendly_name, reachability_debouncing_enabled: $reachability_debouncing_enabled, reachability_debouncing_window: $reachability_debouncing_window, reachability_webhooks_enabled: $reachability_webhooks_enabled, webhook_url: $webhook_url, webhooks_from_rest_enabled: $webhooks_from_rest_enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
