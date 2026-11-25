# Auto-generated client for Twilio - Api v1.42.0
# Source: https://api.apis.guru/v2/specs/twilio.com/api/1.42.0/openapi.json
# Auth: --token flag or $env.TWILIO_API_TOKEN

const CLIENT = {
  base_url: "https://api.twilio.com"
  token_env_var: "TWILIO_API_TOKEN"
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

def base-url-completer [] { ["https://api.twilio.com"] }
def auth-scheme-completer [] { ["basic" "basic-credentials"] }

# Completers for enum parameters
def status-completer [] { ["active" "closed" "suspended"] }
def sms-fallback-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def sms-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def status-callback-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def voice-fallback-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def voice-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def status-completer-1 [] { ["busy" "canceled" "completed" "failed" "in-progress" "no-answer" "queued" "ringing"] }
def async-amd-status-callback-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def fallback-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def recording-status-callback-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def bank-account-type-completer [] { ["commercial-checking" "consumer-checking" "consumer-savings"] }
def payment-method-completer [] { ["ach-debit" "credit-card"] }
def token-type-completer [] { ["one-time" "reusable"] }
def capture-completer [] { ["bank-account-number" "bank-routing-number" "expiration-date" "payment-card-number" "postal-code" "security-code"] }
def status-completer-2 [] { ["cancel" "complete"] }
def status-completer-3 [] { ["absent" "completed" "in-progress" "paused" "processing" "stopped"] }
def track-completer [] { ["both_tracks" "inbound_track" "outbound_track"] }
def status-completer-4 [] { ["stopped"] }
def status-completer-5 [] { ["canceled" "completed"] }
def status-completer-6 [] { ["completed" "in-progress" "init"] }
def amd-status-callback-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def conference-recording-status-callback-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def conference-status-callback-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def wait-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def announce-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def hold-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def status-completer-7 [] { ["completed"] }
def deauthorize-callback-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def emergency-status-completer [] { ["Active" "Inactive"] }
def voice-receive-mode-completer [] { ["fax" "voice"] }
def address-retention-completer [] { ["retain"] }
def content-retention-completer [] { ["retain"] }
def schedule-type-completer [] { ["fixed"] }
def outcome-completer [] { ["confirmed" "unconfirmed"] }
def status-completer-8 [] { ["canceled"] }
def voice-status-callback-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def category-completer [] { ["a2p-registration-fees" "agent-conference" "amazon-polly" "answering-machine-detection" "authy-authentications" "authy-calls-outbound" "authy-monthly-fees" "authy-phone-intelligence" "authy-phone-verifications" "authy-sms-outbound" "call-progess-events" "calleridlookups" "calls" "calls-client" "calls-globalconference" "calls-inbound" "calls-inbound-local" "calls-inbound-mobile" "calls-inbound-tollfree" "calls-outbound" "calls-pay-verb-transactions" "calls-recordings" "calls-sip" "calls-sip-inbound" "calls-sip-outbound" "calls-transfers" "carrier-lookups" "conversations" "conversations-api-requests" "conversations-conversation-events" "conversations-endpoint-connectivity" "conversations-events" "conversations-participant-events" "conversations-participants" "cps" "flex-usage" "fraud-lookups" "group-rooms" "group-rooms-data-track" "group-rooms-encrypted-media-recorded" "group-rooms-media-downloaded" "group-rooms-media-recorded" "group-rooms-media-routed" "group-rooms-media-stored" "group-rooms-participant-minutes" "group-rooms-recorded-minutes" "imp-v1-usage" "lookups" "marketplace" "marketplace-algorithmia-named-entity-recognition" "marketplace-cadence-transcription" "marketplace-cadence-translation" "marketplace-capio-speech-to-text" "marketplace-convriza-ababa" "marketplace-deepgram-phrase-detector" "marketplace-digital-segment-business-info" "marketplace-facebook-offline-conversions" "marketplace-google-speech-to-text" "marketplace-ibm-watson-message-insights" "marketplace-ibm-watson-message-sentiment" "marketplace-ibm-watson-recording-analysis" "marketplace-ibm-watson-tone-analyzer" "marketplace-icehook-systems-scout" "marketplace-infogroup-dataaxle-bizinfo" "marketplace-keen-io-contact-center-analytics" "marketplace-marchex-cleancall" "marketplace-marchex-sentiment-analysis-for-sms" "marketplace-marketplace-nextcaller-social-id" "marketplace-mobile-commons-opt-out-classifier" "marketplace-nexiwave-voicemail-to-text" "marketplace-nextcaller-advanced-caller-identification" "marketplace-nomorobo-spam-score" "marketplace-payfone-tcpa-compliance" "marketplace-remeeting-automatic-speech-recognition" "marketplace-tcpa-defense-solutions-blacklist-feed" "marketplace-telo-opencnam" "marketplace-truecnam-true-spam" "marketplace-twilio-caller-name-lookup-us" "marketplace-twilio-carrier-information-lookup" "marketplace-voicebase-pci" "marketplace-voicebase-transcription" "marketplace-voicebase-transcription-custom-vocabulary" "marketplace-whitepages-pro-caller-identification" "marketplace-whitepages-pro-phone-intelligence" "marketplace-whitepages-pro-phone-reputation" "marketplace-wolfarm-spoken-results" "marketplace-wolfram-short-answer" "marketplace-ytica-contact-center-reporting-analytics" "mediastorage" "mms" "mms-inbound" "mms-inbound-longcode" "mms-inbound-shortcode" "mms-messages-carrierfees" "mms-outbound" "mms-outbound-longcode" "mms-outbound-shortcode" "monitor-reads" "monitor-storage" "monitor-writes" "notify" "notify-actions-attempts" "notify-channels" "number-format-lookups" "pchat" "pchat-users" "peer-to-peer-rooms-participant-minutes" "pfax" "pfax-minutes" "pfax-minutes-inbound" "pfax-minutes-outbound" "pfax-pages" "phonenumbers" "phonenumbers-cps" "phonenumbers-emergency" "phonenumbers-local" "phonenumbers-mobile" "phonenumbers-setups" "phonenumbers-tollfree" "premiumsupport" "proxy" "proxy-active-sessions" "pstnconnectivity" "pv" "pv-composition-media-downloaded" "pv-composition-media-encrypted" "pv-composition-media-stored" "pv-composition-minutes" "pv-recording-compositions" "pv-room-participants" "pv-room-participants-au1" "pv-room-participants-br1" "pv-room-participants-ie1" "pv-room-participants-jp1" "pv-room-participants-sg1" "pv-room-participants-us1" "pv-room-participants-us2" "pv-rooms" "pv-sip-endpoint-registrations" "recordings" "recordingstorage" "rooms-group-bandwidth" "rooms-group-minutes" "rooms-peer-to-peer-minutes" "shortcodes" "shortcodes-customerowned" "shortcodes-mms-enablement" "shortcodes-mps" "shortcodes-random" "shortcodes-uk" "shortcodes-vanity" "small-group-rooms" "small-group-rooms-data-track" "small-group-rooms-participant-minutes" "sms" "sms-inbound" "sms-inbound-longcode" "sms-inbound-shortcode" "sms-messages-carrierfees" "sms-messages-features" "sms-messages-features-senderid" "sms-outbound" "sms-outbound-content-inspection" "sms-outbound-longcode" "sms-outbound-shortcode" "speech-recognition" "studio-engagements" "sync" "sync-actions" "sync-endpoint-hours" "sync-endpoint-hours-above-daily-cap" "taskrouter-tasks" "totalprice" "transcriptions" "trunking-cps" "trunking-emergency-calls" "trunking-origination" "trunking-origination-local" "trunking-origination-mobile" "trunking-origination-tollfree" "trunking-recordings" "trunking-secure" "trunking-termination" "turnmegabytes" "turnmegabytes-australia" "turnmegabytes-brasil" "turnmegabytes-germany" "turnmegabytes-india" "turnmegabytes-ireland" "turnmegabytes-japan" "turnmegabytes-singapore" "turnmegabytes-useast" "turnmegabytes-uswest" "twilio-interconnect" "verify-push" "verify-totp" "verify-whatsapp-conversations-business-initiated" "video-recordings" "virtual-agent" "voice-insights" "voice-insights-client-insights-on-demand-minute" "voice-insights-ptsn-insights-on-demand-minute" "voice-insights-sip-interface-insights-on-demand-minute" "voice-insights-sip-trunking-insights-on-demand-minute" "wireless" "wireless-orders" "wireless-orders-artwork" "wireless-orders-bulk" "wireless-orders-esim" "wireless-orders-starter" "wireless-usage" "wireless-usage-commands" "wireless-usage-commands-africa" "wireless-usage-commands-asia" "wireless-usage-commands-centralandsouthamerica" "wireless-usage-commands-europe" "wireless-usage-commands-home" "wireless-usage-commands-northamerica" "wireless-usage-commands-oceania" "wireless-usage-commands-roaming" "wireless-usage-data" "wireless-usage-data-africa" "wireless-usage-data-asia" "wireless-usage-data-centralandsouthamerica" "wireless-usage-data-custom-additionalmb" "wireless-usage-data-custom-first5mb" "wireless-usage-data-domestic-roaming" "wireless-usage-data-europe" "wireless-usage-data-individual-additionalgb" "wireless-usage-data-individual-firstgb" "wireless-usage-data-international-roaming-canada" "wireless-usage-data-international-roaming-india" "wireless-usage-data-international-roaming-mexico" "wireless-usage-data-northamerica" "wireless-usage-data-oceania" "wireless-usage-data-pooled" "wireless-usage-data-pooled-downlink" "wireless-usage-data-pooled-uplink" "wireless-usage-mrc" "wireless-usage-mrc-custom" "wireless-usage-mrc-individual" "wireless-usage-mrc-pooled" "wireless-usage-mrc-suspended" "wireless-usage-sms" "wireless-usage-voice"] }
def recurring-completer [] { ["alltime" "daily" "monthly" "yearly"] }
def trigger-by-completer [] { ["count" "price" "usage"] }
def usage-category-completer [] { ["a2p-registration-fees" "agent-conference" "amazon-polly" "answering-machine-detection" "authy-authentications" "authy-calls-outbound" "authy-monthly-fees" "authy-phone-intelligence" "authy-phone-verifications" "authy-sms-outbound" "call-progess-events" "calleridlookups" "calls" "calls-client" "calls-globalconference" "calls-inbound" "calls-inbound-local" "calls-inbound-mobile" "calls-inbound-tollfree" "calls-outbound" "calls-pay-verb-transactions" "calls-recordings" "calls-sip" "calls-sip-inbound" "calls-sip-outbound" "calls-transfers" "carrier-lookups" "conversations" "conversations-api-requests" "conversations-conversation-events" "conversations-endpoint-connectivity" "conversations-events" "conversations-participant-events" "conversations-participants" "cps" "flex-usage" "fraud-lookups" "group-rooms" "group-rooms-data-track" "group-rooms-encrypted-media-recorded" "group-rooms-media-downloaded" "group-rooms-media-recorded" "group-rooms-media-routed" "group-rooms-media-stored" "group-rooms-participant-minutes" "group-rooms-recorded-minutes" "imp-v1-usage" "lookups" "marketplace" "marketplace-algorithmia-named-entity-recognition" "marketplace-cadence-transcription" "marketplace-cadence-translation" "marketplace-capio-speech-to-text" "marketplace-convriza-ababa" "marketplace-deepgram-phrase-detector" "marketplace-digital-segment-business-info" "marketplace-facebook-offline-conversions" "marketplace-google-speech-to-text" "marketplace-ibm-watson-message-insights" "marketplace-ibm-watson-message-sentiment" "marketplace-ibm-watson-recording-analysis" "marketplace-ibm-watson-tone-analyzer" "marketplace-icehook-systems-scout" "marketplace-infogroup-dataaxle-bizinfo" "marketplace-keen-io-contact-center-analytics" "marketplace-marchex-cleancall" "marketplace-marchex-sentiment-analysis-for-sms" "marketplace-marketplace-nextcaller-social-id" "marketplace-mobile-commons-opt-out-classifier" "marketplace-nexiwave-voicemail-to-text" "marketplace-nextcaller-advanced-caller-identification" "marketplace-nomorobo-spam-score" "marketplace-payfone-tcpa-compliance" "marketplace-remeeting-automatic-speech-recognition" "marketplace-tcpa-defense-solutions-blacklist-feed" "marketplace-telo-opencnam" "marketplace-truecnam-true-spam" "marketplace-twilio-caller-name-lookup-us" "marketplace-twilio-carrier-information-lookup" "marketplace-voicebase-pci" "marketplace-voicebase-transcription" "marketplace-voicebase-transcription-custom-vocabulary" "marketplace-whitepages-pro-caller-identification" "marketplace-whitepages-pro-phone-intelligence" "marketplace-whitepages-pro-phone-reputation" "marketplace-wolfarm-spoken-results" "marketplace-wolfram-short-answer" "marketplace-ytica-contact-center-reporting-analytics" "mediastorage" "mms" "mms-inbound" "mms-inbound-longcode" "mms-inbound-shortcode" "mms-messages-carrierfees" "mms-outbound" "mms-outbound-longcode" "mms-outbound-shortcode" "monitor-reads" "monitor-storage" "monitor-writes" "notify" "notify-actions-attempts" "notify-channels" "number-format-lookups" "pchat" "pchat-users" "peer-to-peer-rooms-participant-minutes" "pfax" "pfax-minutes" "pfax-minutes-inbound" "pfax-minutes-outbound" "pfax-pages" "phonenumbers" "phonenumbers-cps" "phonenumbers-emergency" "phonenumbers-local" "phonenumbers-mobile" "phonenumbers-setups" "phonenumbers-tollfree" "premiumsupport" "proxy" "proxy-active-sessions" "pstnconnectivity" "pv" "pv-composition-media-downloaded" "pv-composition-media-encrypted" "pv-composition-media-stored" "pv-composition-minutes" "pv-recording-compositions" "pv-room-participants" "pv-room-participants-au1" "pv-room-participants-br1" "pv-room-participants-ie1" "pv-room-participants-jp1" "pv-room-participants-sg1" "pv-room-participants-us1" "pv-room-participants-us2" "pv-rooms" "pv-sip-endpoint-registrations" "recordings" "recordingstorage" "rooms-group-bandwidth" "rooms-group-minutes" "rooms-peer-to-peer-minutes" "shortcodes" "shortcodes-customerowned" "shortcodes-mms-enablement" "shortcodes-mps" "shortcodes-random" "shortcodes-uk" "shortcodes-vanity" "small-group-rooms" "small-group-rooms-data-track" "small-group-rooms-participant-minutes" "sms" "sms-inbound" "sms-inbound-longcode" "sms-inbound-shortcode" "sms-messages-carrierfees" "sms-messages-features" "sms-messages-features-senderid" "sms-outbound" "sms-outbound-content-inspection" "sms-outbound-longcode" "sms-outbound-shortcode" "speech-recognition" "studio-engagements" "sync" "sync-actions" "sync-endpoint-hours" "sync-endpoint-hours-above-daily-cap" "taskrouter-tasks" "totalprice" "transcriptions" "trunking-cps" "trunking-emergency-calls" "trunking-origination" "trunking-origination-local" "trunking-origination-mobile" "trunking-origination-tollfree" "trunking-recordings" "trunking-secure" "trunking-termination" "turnmegabytes" "turnmegabytes-australia" "turnmegabytes-brasil" "turnmegabytes-germany" "turnmegabytes-india" "turnmegabytes-ireland" "turnmegabytes-japan" "turnmegabytes-singapore" "turnmegabytes-useast" "turnmegabytes-uswest" "twilio-interconnect" "verify-push" "verify-totp" "verify-whatsapp-conversations-business-initiated" "video-recordings" "virtual-agent" "voice-insights" "voice-insights-client-insights-on-demand-minute" "voice-insights-ptsn-insights-on-demand-minute" "voice-insights-sip-interface-insights-on-demand-minute" "voice-insights-sip-trunking-insights-on-demand-minute" "wireless" "wireless-orders" "wireless-orders-artwork" "wireless-orders-bulk" "wireless-orders-esim" "wireless-orders-starter" "wireless-usage" "wireless-usage-commands" "wireless-usage-commands-africa" "wireless-usage-commands-asia" "wireless-usage-commands-centralandsouthamerica" "wireless-usage-commands-europe" "wireless-usage-commands-home" "wireless-usage-commands-northamerica" "wireless-usage-commands-oceania" "wireless-usage-commands-roaming" "wireless-usage-data" "wireless-usage-data-africa" "wireless-usage-data-asia" "wireless-usage-data-centralandsouthamerica" "wireless-usage-data-custom-additionalmb" "wireless-usage-data-custom-first5mb" "wireless-usage-data-domestic-roaming" "wireless-usage-data-europe" "wireless-usage-data-individual-additionalgb" "wireless-usage-data-individual-firstgb" "wireless-usage-data-international-roaming-canada" "wireless-usage-data-international-roaming-india" "wireless-usage-data-international-roaming-mexico" "wireless-usage-data-northamerica" "wireless-usage-data-oceania" "wireless-usage-data-pooled" "wireless-usage-data-pooled-downlink" "wireless-usage-data-pooled-uplink" "wireless-usage-mrc" "wireless-usage-mrc-custom" "wireless-usage-mrc-individual" "wireless-usage-mrc-pooled" "wireless-usage-mrc-suspended" "wireless-usage-sms" "wireless-usage-voice"] }
def callback-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    list-account: "record<accounts: table<auth_token: string, date_created: string, date_updated: string, friendly_name: string, owner_account_sid: string, sid: string, status: string, subresource_uris: record, type: string, uri: string>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>"
    create-account: "record<auth_token: string, date_created: string, date_updated: string, friendly_name: string, owner_account_sid: string, sid: string, status: string, subresource_uris: record, type: string, uri: string>"
    list-address: "record<addresses: table<account_sid: string, city: string, customer_name: string, date_created: string, date_updated: string, emergency_enabled: bool, friendly_name: string, iso_country: string, postal_code: string, region: string, sid: string, street: string, street_secondary: string, uri: string, validated: bool, verified: bool>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>"
    create-address: "record<account_sid: string, city: string, customer_name: string, date_created: string, date_updated: string, emergency_enabled: bool, friendly_name: string, iso_country: string, postal_code: string, region: string, sid: string, street: string, street_secondary: string, uri: string, validated: bool, verified: bool>"
    list-dependent-phone-number: "record<dependent_phone_numbers: table<account_sid: string, address_requirements: string, api_version: string, capabilities: any, date_created: string, date_updated: string, emergency_address_sid: string, emergency_status: string, friendly_name: string, phone_number: string, sid: string, sms_application_sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, status_callback: string, status_callback_method: string, trunk_sid: string, uri: string, voice_application_sid: string, voice_caller_id_lookup: bool, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_url: string>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>"
    fetch-address: "record<account_sid: string, city: string, customer_name: string, date_created: string, date_updated: string, emergency_enabled: bool, friendly_name: string, iso_country: string, postal_code: string, region: string, sid: string, street: string, street_secondary: string, uri: string, validated: bool, verified: bool>"
    update-address: "record<account_sid: string, city: string, customer_name: string, date_created: string, date_updated: string, emergency_enabled: bool, friendly_name: string, iso_country: string, postal_code: string, region: string, sid: string, street: string, street_secondary: string, uri: string, validated: bool, verified: bool>"
    list-application: "record<applications: table<account_sid: string, api_version: string, date_created: string, date_updated: string, friendly_name: string, message_status_callback: string, public_application_connect_enabled: bool, sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_status_callback: string, sms_url: string, status_callback: string, status_callback_method: string, uri: string, voice_caller_id_lookup: bool, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_url: string>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>"
    create-application: "record<account_sid: string, api_version: string, date_created: string, date_updated: string, friendly_name: string, message_status_callback: string, public_application_connect_enabled: bool, sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_status_callback: string, sms_url: string, status_callback: string, status_callback_method: string, uri: string, voice_caller_id_lookup: bool, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_url: string>"
    fetch-application: "record<account_sid: string, api_version: string, date_created: string, date_updated: string, friendly_name: string, message_status_callback: string, public_application_connect_enabled: bool, sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_status_callback: string, sms_url: string, status_callback: string, status_callback_method: string, uri: string, voice_caller_id_lookup: bool, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_url: string>"
    update-application: "record<account_sid: string, api_version: string, date_created: string, date_updated: string, friendly_name: string, message_status_callback: string, public_application_connect_enabled: bool, sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_status_callback: string, sms_url: string, status_callback: string, status_callback_method: string, uri: string, voice_caller_id_lookup: bool, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_url: string>"
    list-authorized-connect-app: "record<authorized_connect_apps: table<account_sid: string, connect_app_company_name: string, connect_app_description: string, connect_app_friendly_name: string, connect_app_homepage_url: string, connect_app_sid: string, date_created: string, date_updated: string, permissions: list, uri: string>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>"
    fetch-authorized-connect-app: "record<account_sid: string, connect_app_company_name: string, connect_app_description: string, connect_app_friendly_name: string, connect_app_homepage_url: string, connect_app_sid: string, date_created: string, date_updated: string, permissions: list<string>, uri: string>"
    list-available-phone-number-country: "record<countries: table<beta: bool, country: string, country_code: string, subresource_uris: record, uri: string>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>"
    fetch-available-phone-number-country: "record<beta: bool, country: string, country_code: string, subresource_uris: record, uri: string>"
    list-available-phone-number-local: "record<available_phone_numbers: table<address_requirements: string, beta: bool, capabilities: record, friendly_name: string, iso_country: string, lata: string, latitude: float, locality: string, longitude: float, phone_number: string, postal_code: string, rate_center: string, region: string>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>"
    list-available-phone-number-machine-to-machine: "record<available_phone_numbers: table<address_requirements: string, beta: bool, capabilities: record, friendly_name: string, iso_country: string, lata: string, latitude: float, locality: string, longitude: float, phone_number: string, postal_code: string, rate_center: string, region: string>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>"
    list-available-phone-number-mobile: "record<available_phone_numbers: table<address_requirements: string, beta: bool, capabilities: record, friendly_name: string, iso_country: string, lata: string, latitude: float, locality: string, longitude: float, phone_number: string, postal_code: string, rate_center: string, region: string>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>"
    list-available-phone-number-national: "record<available_phone_numbers: table<address_requirements: string, beta: bool, capabilities: record, friendly_name: string, iso_country: string, lata: string, latitude: float, locality: string, longitude: float, phone_number: string, postal_code: string, rate_center: string, region: string>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>"
    list-available-phone-number-shared-cost: "record<available_phone_numbers: table<address_requirements: string, beta: bool, capabilities: record, friendly_name: string, iso_country: string, lata: string, latitude: float, locality: string, longitude: float, phone_number: string, postal_code: string, rate_center: string, region: string>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>"
    list-available-phone-number-toll-free: "record<available_phone_numbers: table<address_requirements: string, beta: bool, capabilities: record, friendly_name: string, iso_country: string, lata: string, latitude: float, locality: string, longitude: float, phone_number: string, postal_code: string, rate_center: string, region: string>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>"
    list-available-phone-number-voip: "record<available_phone_numbers: table<address_requirements: string, beta: bool, capabilities: record, friendly_name: string, iso_country: string, lata: string, latitude: float, locality: string, longitude: float, phone_number: string, postal_code: string, rate_center: string, region: string>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>"
    fetch-balance: "record<account_sid: string, balance: string, currency: string>"
    list-call: "record<calls: table<account_sid: string, answered_by: string, api_version: string, caller_name: string, date_created: string, date_updated: string, direction: string, duration: string, end_time: string, forwarded_from: string, from: string, from_formatted: string, group_sid: string, parent_call_sid: string, phone_number_sid: string, price: string, price_unit: string, queue_time: string, sid: string, start_time: string, status: string, subresource_uris: record, to: string, to_formatted: string, trunk_sid: string, uri: string>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>"
    create-call: "record<account_sid: string, answered_by: string, api_version: string, caller_name: string, date_created: string, date_updated: string, direction: string, duration: string, end_time: string, forwarded_from: string, from: string, from_formatted: string, group_sid: string, parent_call_sid: string, phone_number_sid: string, price: string, price_unit: string, queue_time: string, sid: string, start_time: string, status: string, subresource_uris: record, to: string, to_formatted: string, trunk_sid: string, uri: string>"
    create-call-feedback-summary: "record<account_sid: string, call_count: int, call_feedback_count: int, date_created: string, date_updated: string, end_date: string, include_subaccounts: bool, issues: list<any>, quality_score_average: float, quality_score_median: float, quality_score_standard_deviation: float, sid: string, start_date: string, status: string>"
    fetch-call-feedback-summary: "record<account_sid: string, call_count: int, call_feedback_count: int, date_created: string, date_updated: string, end_date: string, include_subaccounts: bool, issues: list<any>, quality_score_average: float, quality_score_median: float, quality_score_standard_deviation: float, sid: string, start_date: string, status: string>"
    list-call-event: "record<end: int, events: table<request: any, response: any>, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>"
    fetch-call-feedback: "record<account_sid: string, date_created: string, date_updated: string, issues: list<string>, quality_score: int, sid: string>"
    update-call-feedback: "record<account_sid: string, date_created: string, date_updated: string, issues: list<string>, quality_score: int, sid: string>"
    list-call-notification: "record<end: int, first_page_uri: string, next_page_uri: string, notifications: table<account_sid: string, api_version: string, call_sid: string, date_created: string, date_updated: string, error_code: string, log: string, message_date: string, message_text: string, more_info: string, request_method: string, request_url: string, sid: string, uri: string>, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>"
    fetch-call-notification: "record<account_sid: string, api_version: string, call_sid: string, date_created: string, date_updated: string, error_code: string, log: string, message_date: string, message_text: string, more_info: string, request_method: string, request_url: string, request_variables: string, response_body: string, response_headers: string, sid: string, uri: string>"
    create-payments: "record<account_sid: string, call_sid: string, date_created: string, date_updated: string, sid: string, uri: string>"
    update-payments: "record<account_sid: string, call_sid: string, date_created: string, date_updated: string, sid: string, uri: string>"
    list-call-recording: "record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, recordings: table<account_sid: string, api_version: string, call_sid: string, channels: int, conference_sid: string, date_created: string, date_updated: string, duration: string, encryption_details: any, error_code: int, price: float, price_unit: string, sid: string, source: string, start_time: string, status: string, track: string, uri: string>, start: int, uri: string>"
    create-call-recording: "record<account_sid: string, api_version: string, call_sid: string, channels: int, conference_sid: string, date_created: string, date_updated: string, duration: string, encryption_details: any, error_code: int, price: float, price_unit: string, sid: string, source: string, start_time: string, status: string, track: string, uri: string>"
    fetch-call-recording: "record<account_sid: string, api_version: string, call_sid: string, channels: int, conference_sid: string, date_created: string, date_updated: string, duration: string, encryption_details: any, error_code: int, price: float, price_unit: string, sid: string, source: string, start_time: string, status: string, track: string, uri: string>"
    update-call-recording: "record<account_sid: string, api_version: string, call_sid: string, channels: int, conference_sid: string, date_created: string, date_updated: string, duration: string, encryption_details: any, error_code: int, price: float, price_unit: string, sid: string, source: string, start_time: string, status: string, track: string, uri: string>"
    create-siprec: "record<account_sid: string, call_sid: string, date_updated: string, name: string, sid: string, status: string, uri: string>"
    update-siprec: "record<account_sid: string, call_sid: string, date_updated: string, name: string, sid: string, status: string, uri: string>"
    create-stream: "record<account_sid: string, call_sid: string, date_updated: string, name: string, sid: string, status: string, uri: string>"
    update-stream: "record<account_sid: string, call_sid: string, date_updated: string, name: string, sid: string, status: string, uri: string>"
    create-user-defined-message-subscription: "record<account_sid: string, call_sid: string, date_created: string, sid: string, uri: string>"
    create-user-defined-message: "record<account_sid: string, call_sid: string, date_created: string, sid: string>"
    fetch-call: "record<account_sid: string, answered_by: string, api_version: string, caller_name: string, date_created: string, date_updated: string, direction: string, duration: string, end_time: string, forwarded_from: string, from: string, from_formatted: string, group_sid: string, parent_call_sid: string, phone_number_sid: string, price: string, price_unit: string, queue_time: string, sid: string, start_time: string, status: string, subresource_uris: record, to: string, to_formatted: string, trunk_sid: string, uri: string>"
    update-call: "record<account_sid: string, answered_by: string, api_version: string, caller_name: string, date_created: string, date_updated: string, direction: string, duration: string, end_time: string, forwarded_from: string, from: string, from_formatted: string, group_sid: string, parent_call_sid: string, phone_number_sid: string, price: string, price_unit: string, queue_time: string, sid: string, start_time: string, status: string, subresource_uris: record, to: string, to_formatted: string, trunk_sid: string, uri: string>"
    list-conference: "record<conferences: table<account_sid: string, api_version: string, call_sid_ending_conference: string, date_created: string, date_updated: string, friendly_name: string, reason_conference_ended: string, region: string, sid: string, status: string, subresource_uris: record, uri: string>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>"
    list-participant: "record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, participants: table<account_sid: string, call_sid: string, call_sid_to_coach: string, coaching: bool, conference_sid: string, date_created: string, date_updated: string, end_conference_on_exit: bool, hold: bool, label: string, muted: bool, start_conference_on_enter: bool, status: string, uri: string>, previous_page_uri: string, start: int, uri: string>"
    create-participant: "record<account_sid: string, call_sid: string, call_sid_to_coach: string, coaching: bool, conference_sid: string, date_created: string, date_updated: string, end_conference_on_exit: bool, hold: bool, label: string, muted: bool, start_conference_on_enter: bool, status: string, uri: string>"
    fetch-participant: "record<account_sid: string, call_sid: string, call_sid_to_coach: string, coaching: bool, conference_sid: string, date_created: string, date_updated: string, end_conference_on_exit: bool, hold: bool, label: string, muted: bool, start_conference_on_enter: bool, status: string, uri: string>"
    update-participant: "record<account_sid: string, call_sid: string, call_sid_to_coach: string, coaching: bool, conference_sid: string, date_created: string, date_updated: string, end_conference_on_exit: bool, hold: bool, label: string, muted: bool, start_conference_on_enter: bool, status: string, uri: string>"
    list-conference-recording: "record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, recordings: table<account_sid: string, api_version: string, call_sid: string, channels: int, conference_sid: string, date_created: string, date_updated: string, duration: string, encryption_details: any, error_code: int, price: string, price_unit: string, sid: string, source: string, start_time: string, status: string, uri: string>, start: int, uri: string>"
    fetch-conference-recording: "record<account_sid: string, api_version: string, call_sid: string, channels: int, conference_sid: string, date_created: string, date_updated: string, duration: string, encryption_details: any, error_code: int, price: string, price_unit: string, sid: string, source: string, start_time: string, status: string, uri: string>"
    update-conference-recording: "record<account_sid: string, api_version: string, call_sid: string, channels: int, conference_sid: string, date_created: string, date_updated: string, duration: string, encryption_details: any, error_code: int, price: string, price_unit: string, sid: string, source: string, start_time: string, status: string, uri: string>"
    fetch-conference: "record<account_sid: string, api_version: string, call_sid_ending_conference: string, date_created: string, date_updated: string, friendly_name: string, reason_conference_ended: string, region: string, sid: string, status: string, subresource_uris: record, uri: string>"
    update-conference: "record<account_sid: string, api_version: string, call_sid_ending_conference: string, date_created: string, date_updated: string, friendly_name: string, reason_conference_ended: string, region: string, sid: string, status: string, subresource_uris: record, uri: string>"
    list-connect-app: "record<connect_apps: table<account_sid: string, authorize_redirect_url: string, company_name: string, deauthorize_callback_method: string, deauthorize_callback_url: string, description: string, friendly_name: string, homepage_url: string, permissions: list, sid: string, uri: string>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>"
    fetch-connect-app: "record<account_sid: string, authorize_redirect_url: string, company_name: string, deauthorize_callback_method: string, deauthorize_callback_url: string, description: string, friendly_name: string, homepage_url: string, permissions: list<string>, sid: string, uri: string>"
    update-connect-app: "record<account_sid: string, authorize_redirect_url: string, company_name: string, deauthorize_callback_method: string, deauthorize_callback_url: string, description: string, friendly_name: string, homepage_url: string, permissions: list<string>, sid: string, uri: string>"
    list-incoming-phone-number: "record<end: int, first_page_uri: string, incoming_phone_numbers: table<account_sid: string, address_requirements: string, address_sid: string, api_version: string, beta: bool, bundle_sid: string, capabilities: record, date_created: string, date_updated: string, emergency_address_sid: string, emergency_address_status: string, emergency_status: string, friendly_name: string, identity_sid: string, origin: string, phone_number: string, sid: string, sms_application_sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, status: string, status_callback: string, status_callback_method: string, trunk_sid: string, uri: string, voice_application_sid: string, voice_caller_id_lookup: bool, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_receive_mode: string, voice_url: string>, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>"
    create-incoming-phone-number: "record<account_sid: string, address_requirements: string, address_sid: string, api_version: string, beta: bool, bundle_sid: string, capabilities: record<fax: bool, mms: bool, sms: bool, voice: bool>, date_created: string, date_updated: string, emergency_address_sid: string, emergency_address_status: string, emergency_status: string, friendly_name: string, identity_sid: string, origin: string, phone_number: string, sid: string, sms_application_sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, status: string, status_callback: string, status_callback_method: string, trunk_sid: string, uri: string, voice_application_sid: string, voice_caller_id_lookup: bool, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_receive_mode: string, voice_url: string>"
    list-incoming-phone-number-local: "record<end: int, first_page_uri: string, incoming_phone_numbers: table<account_sid: string, address_requirements: string, address_sid: string, api_version: string, beta: bool, bundle_sid: string, capabilities: record, date_created: string, date_updated: string, emergency_address_sid: string, emergency_address_status: string, emergency_status: string, friendly_name: string, identity_sid: string, origin: string, phone_number: string, sid: string, sms_application_sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, status: string, status_callback: string, status_callback_method: string, trunk_sid: string, uri: string, voice_application_sid: string, voice_caller_id_lookup: bool, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_receive_mode: string, voice_url: string>, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>"
    create-incoming-phone-number-local: "record<account_sid: string, address_requirements: string, address_sid: string, api_version: string, beta: bool, bundle_sid: string, capabilities: record<fax: bool, mms: bool, sms: bool, voice: bool>, date_created: string, date_updated: string, emergency_address_sid: string, emergency_address_status: string, emergency_status: string, friendly_name: string, identity_sid: string, origin: string, phone_number: string, sid: string, sms_application_sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, status: string, status_callback: string, status_callback_method: string, trunk_sid: string, uri: string, voice_application_sid: string, voice_caller_id_lookup: bool, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_receive_mode: string, voice_url: string>"
    list-incoming-phone-number-mobile: "record<end: int, first_page_uri: string, incoming_phone_numbers: table<account_sid: string, address_requirements: string, address_sid: string, api_version: string, beta: bool, bundle_sid: string, capabilities: record, date_created: string, date_updated: string, emergency_address_sid: string, emergency_address_status: string, emergency_status: string, friendly_name: string, identity_sid: string, origin: string, phone_number: string, sid: string, sms_application_sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, status: string, status_callback: string, status_callback_method: string, trunk_sid: string, uri: string, voice_application_sid: string, voice_caller_id_lookup: bool, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_receive_mode: string, voice_url: string>, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>"
    create-incoming-phone-number-mobile: "record<account_sid: string, address_requirements: string, address_sid: string, api_version: string, beta: bool, bundle_sid: string, capabilities: record<fax: bool, mms: bool, sms: bool, voice: bool>, date_created: string, date_updated: string, emergency_address_sid: string, emergency_address_status: string, emergency_status: string, friendly_name: string, identity_sid: string, origin: string, phone_number: string, sid: string, sms_application_sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, status: string, status_callback: string, status_callback_method: string, trunk_sid: string, uri: string, voice_application_sid: string, voice_caller_id_lookup: bool, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_receive_mode: string, voice_url: string>"
    list-incoming-phone-number-toll-free: "record<end: int, first_page_uri: string, incoming_phone_numbers: table<account_sid: string, address_requirements: string, address_sid: string, api_version: string, beta: bool, bundle_sid: string, capabilities: record, date_created: string, date_updated: string, emergency_address_sid: string, emergency_address_status: string, emergency_status: string, friendly_name: string, identity_sid: string, origin: string, phone_number: string, sid: string, sms_application_sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, status: string, status_callback: string, status_callback_method: string, trunk_sid: string, uri: string, voice_application_sid: string, voice_caller_id_lookup: bool, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_receive_mode: string, voice_url: string>, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>"
    create-incoming-phone-number-toll-free: "record<account_sid: string, address_requirements: string, address_sid: string, api_version: string, beta: bool, bundle_sid: string, capabilities: record<fax: bool, mms: bool, sms: bool, voice: bool>, date_created: string, date_updated: string, emergency_address_sid: string, emergency_address_status: string, emergency_status: string, friendly_name: string, identity_sid: string, origin: string, phone_number: string, sid: string, sms_application_sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, status: string, status_callback: string, status_callback_method: string, trunk_sid: string, uri: string, voice_application_sid: string, voice_caller_id_lookup: bool, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_receive_mode: string, voice_url: string>"
    list-incoming-phone-number-assigned-add-on: "record<assigned_add_ons: table<account_sid: string, configuration: any, date_created: string, date_updated: string, description: string, friendly_name: string, resource_sid: string, sid: string, subresource_uris: record, unique_name: string, uri: string>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>"
    create-incoming-phone-number-assigned-add-on: "record<account_sid: string, configuration: any, date_created: string, date_updated: string, description: string, friendly_name: string, resource_sid: string, sid: string, subresource_uris: record, unique_name: string, uri: string>"
    list-incoming-phone-number-assigned-add-on-extension: "record<end: int, extensions: table<account_sid: string, assigned_add_on_sid: string, enabled: bool, friendly_name: string, product_name: string, resource_sid: string, sid: string, unique_name: string, uri: string>, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>"
    fetch-incoming-phone-number-assigned-add-on-extension: "record<account_sid: string, assigned_add_on_sid: string, enabled: bool, friendly_name: string, product_name: string, resource_sid: string, sid: string, unique_name: string, uri: string>"
    fetch-incoming-phone-number-assigned-add-on: "record<account_sid: string, configuration: any, date_created: string, date_updated: string, description: string, friendly_name: string, resource_sid: string, sid: string, subresource_uris: record, unique_name: string, uri: string>"
    fetch-incoming-phone-number: "record<account_sid: string, address_requirements: string, address_sid: string, api_version: string, beta: bool, bundle_sid: string, capabilities: record<fax: bool, mms: bool, sms: bool, voice: bool>, date_created: string, date_updated: string, emergency_address_sid: string, emergency_address_status: string, emergency_status: string, friendly_name: string, identity_sid: string, origin: string, phone_number: string, sid: string, sms_application_sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, status: string, status_callback: string, status_callback_method: string, trunk_sid: string, uri: string, voice_application_sid: string, voice_caller_id_lookup: bool, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_receive_mode: string, voice_url: string>"
    update-incoming-phone-number: "record<account_sid: string, address_requirements: string, address_sid: string, api_version: string, beta: bool, bundle_sid: string, capabilities: record<fax: bool, mms: bool, sms: bool, voice: bool>, date_created: string, date_updated: string, emergency_address_sid: string, emergency_address_status: string, emergency_status: string, friendly_name: string, identity_sid: string, origin: string, phone_number: string, sid: string, sms_application_sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, status: string, status_callback: string, status_callback_method: string, trunk_sid: string, uri: string, voice_application_sid: string, voice_caller_id_lookup: bool, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_receive_mode: string, voice_url: string>"
    list-key: "record<end: int, first_page_uri: string, keys: table<date_created: string, date_updated: string, friendly_name: string, sid: string>, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>"
    create-new-key: "record<date_created: string, date_updated: string, friendly_name: string, secret: string, sid: string>"
    fetch-key: "record<date_created: string, date_updated: string, friendly_name: string, sid: string>"
    update-key: "record<date_created: string, date_updated: string, friendly_name: string, sid: string>"
    list-message: "record<end: int, first_page_uri: string, messages: table<account_sid: string, api_version: string, body: string, date_created: string, date_sent: string, date_updated: string, direction: string, error_code: int, error_message: string, from: string, messaging_service_sid: string, num_media: string, num_segments: string, price: string, price_unit: string, sid: string, status: string, subresource_uris: record, to: string, uri: string>, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>"
    create-message: "record<account_sid: string, api_version: string, body: string, date_created: string, date_sent: string, date_updated: string, direction: string, error_code: int, error_message: string, from: string, messaging_service_sid: string, num_media: string, num_segments: string, price: string, price_unit: string, sid: string, status: string, subresource_uris: record, to: string, uri: string>"
    create-message-feedback: "record<account_sid: string, date_created: string, date_updated: string, message_sid: string, outcome: string, uri: string>"
    list-media: "record<end: int, first_page_uri: string, media_list: table<account_sid: string, content_type: string, date_created: string, date_updated: string, parent_sid: string, sid: string, uri: string>, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>"
    fetch-media: "record<account_sid: string, content_type: string, date_created: string, date_updated: string, parent_sid: string, sid: string, uri: string>"
    fetch-message: "record<account_sid: string, api_version: string, body: string, date_created: string, date_sent: string, date_updated: string, direction: string, error_code: int, error_message: string, from: string, messaging_service_sid: string, num_media: string, num_segments: string, price: string, price_unit: string, sid: string, status: string, subresource_uris: record, to: string, uri: string>"
    update-message: "record<account_sid: string, api_version: string, body: string, date_created: string, date_sent: string, date_updated: string, direction: string, error_code: int, error_message: string, from: string, messaging_service_sid: string, num_media: string, num_segments: string, price: string, price_unit: string, sid: string, status: string, subresource_uris: record, to: string, uri: string>"
    list-notification: "record<end: int, first_page_uri: string, next_page_uri: string, notifications: table<account_sid: string, api_version: string, call_sid: string, date_created: string, date_updated: string, error_code: string, log: string, message_date: string, message_text: string, more_info: string, request_method: string, request_url: string, sid: string, uri: string>, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>"
    fetch-notification: "record<account_sid: string, api_version: string, call_sid: string, date_created: string, date_updated: string, error_code: string, log: string, message_date: string, message_text: string, more_info: string, request_method: string, request_url: string, request_variables: string, response_body: string, response_headers: string, sid: string, uri: string>"
    list-outgoing-caller-id: "record<end: int, first_page_uri: string, next_page_uri: string, outgoing_caller_ids: table<account_sid: string, date_created: string, date_updated: string, friendly_name: string, phone_number: string, sid: string, uri: string>, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>"
    create-validation-request: "record<account_sid: string, call_sid: string, friendly_name: string, phone_number: string, validation_code: string>"
    fetch-outgoing-caller-id: "record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, phone_number: string, sid: string, uri: string>"
    update-outgoing-caller-id: "record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, phone_number: string, sid: string, uri: string>"
    list-queue: "record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, queues: table<account_sid: string, average_wait_time: int, current_size: int, date_created: string, date_updated: string, friendly_name: string, max_size: int, sid: string, uri: string>, start: int, uri: string>"
    create-queue: "record<account_sid: string, average_wait_time: int, current_size: int, date_created: string, date_updated: string, friendly_name: string, max_size: int, sid: string, uri: string>"
    list-member: "record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, queue_members: table<call_sid: string, date_enqueued: string, position: int, queue_sid: string, uri: string, wait_time: int>, start: int, uri: string>"
    fetch-member: "record<call_sid: string, date_enqueued: string, position: int, queue_sid: string, uri: string, wait_time: int>"
    update-member: "record<call_sid: string, date_enqueued: string, position: int, queue_sid: string, uri: string, wait_time: int>"
    fetch-queue: "record<account_sid: string, average_wait_time: int, current_size: int, date_created: string, date_updated: string, friendly_name: string, max_size: int, sid: string, uri: string>"
    update-queue: "record<account_sid: string, average_wait_time: int, current_size: int, date_created: string, date_updated: string, friendly_name: string, max_size: int, sid: string, uri: string>"
    list-recording: "record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, recordings: table<account_sid: string, api_version: string, call_sid: string, channels: int, conference_sid: string, date_created: string, date_updated: string, duration: string, encryption_details: any, error_code: int, media_url: string, price: string, price_unit: string, sid: string, source: string, start_time: string, status: string, subresource_uris: record, uri: string>, start: int, uri: string>"
    list-recording-transcription: "record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, transcriptions: table<account_sid: string, api_version: string, date_created: string, date_updated: string, duration: string, price: float, price_unit: string, recording_sid: string, sid: string, status: string, transcription_text: string, type: string, uri: string>, uri: string>"
    fetch-recording-transcription: "record<account_sid: string, api_version: string, date_created: string, date_updated: string, duration: string, price: float, price_unit: string, recording_sid: string, sid: string, status: string, transcription_text: string, type: string, uri: string>"
    list-recording-add-on-result: "record<add_on_results: table<account_sid: string, add_on_configuration_sid: string, add_on_sid: string, date_completed: string, date_created: string, date_updated: string, reference_sid: string, sid: string, status: string, subresource_uris: record>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>"
    list-recording-add-on-result-payload: "record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, payloads: table<account_sid: string, add_on_configuration_sid: string, add_on_result_sid: string, add_on_sid: string, content_type: string, date_created: string, date_updated: string, label: string, reference_sid: string, sid: string, subresource_uris: record>, previous_page_uri: string, start: int, uri: string>"
    fetch-recording-add-on-result-payload: "record<account_sid: string, add_on_configuration_sid: string, add_on_result_sid: string, add_on_sid: string, content_type: string, date_created: string, date_updated: string, label: string, reference_sid: string, sid: string, subresource_uris: record>"
    fetch-recording-add-on-result: "record<account_sid: string, add_on_configuration_sid: string, add_on_sid: string, date_completed: string, date_created: string, date_updated: string, reference_sid: string, sid: string, status: string, subresource_uris: record>"
    fetch-recording: "record<account_sid: string, api_version: string, call_sid: string, channels: int, conference_sid: string, date_created: string, date_updated: string, duration: string, encryption_details: any, error_code: int, media_url: string, price: string, price_unit: string, sid: string, source: string, start_time: string, status: string, subresource_uris: record, uri: string>"
    list-sip-credential-list: "record<credential_lists: table<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sid: string, subresource_uris: record, uri: string>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>"
    create-sip-credential-list: "record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sid: string, subresource_uris: record, uri: string>"
    list-sip-credential: "record<credentials: table<account_sid: string, credential_list_sid: string, date_created: string, date_updated: string, sid: string, uri: string, username: string>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>"
    create-sip-credential: "record<account_sid: string, credential_list_sid: string, date_created: string, date_updated: string, sid: string, uri: string, username: string>"
    fetch-sip-credential: "record<account_sid: string, credential_list_sid: string, date_created: string, date_updated: string, sid: string, uri: string, username: string>"
    update-sip-credential: "record<account_sid: string, credential_list_sid: string, date_created: string, date_updated: string, sid: string, uri: string, username: string>"
    fetch-sip-credential-list: "record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sid: string, subresource_uris: record, uri: string>"
    update-sip-credential-list: "record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sid: string, subresource_uris: record, uri: string>"
    list-sip-domain: "record<domains: table<account_sid: string, api_version: string, auth_type: string, byoc_trunk_sid: string, date_created: string, date_updated: string, domain_name: string, emergency_caller_sid: string, emergency_calling_enabled: bool, friendly_name: string, secure: bool, sid: string, sip_registration: bool, subresource_uris: record, uri: string, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_status_callback_method: string, voice_status_callback_url: string, voice_url: string>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>"
    create-sip-domain: "record<account_sid: string, api_version: string, auth_type: string, byoc_trunk_sid: string, date_created: string, date_updated: string, domain_name: string, emergency_caller_sid: string, emergency_calling_enabled: bool, friendly_name: string, secure: bool, sid: string, sip_registration: bool, subresource_uris: record, uri: string, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_status_callback_method: string, voice_status_callback_url: string, voice_url: string>"
    list-sip-auth-calls-credential-list-mapping: "record<contents: table<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sid: string>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>"
    create-sip-auth-calls-credential-list-mapping: "record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sid: string>"
    fetch-sip-auth-calls-credential-list-mapping: "record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sid: string>"
    list-sip-auth-calls-ip-access-control-list-mapping: "record<contents: table<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sid: string>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>"
    create-sip-auth-calls-ip-access-control-list-mapping: "record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sid: string>"
    fetch-sip-auth-calls-ip-access-control-list-mapping: "record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sid: string>"
    list-sip-auth-registrations-credential-list-mapping: "record<contents: table<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sid: string>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>"
    create-sip-auth-registrations-credential-list-mapping: "record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sid: string>"
    fetch-sip-auth-registrations-credential-list-mapping: "record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sid: string>"
    list-sip-credential-list-mapping: "record<credential_list_mappings: table<account_sid: string, date_created: string, date_updated: string, domain_sid: string, friendly_name: string, sid: string, uri: string>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>"
    create-sip-credential-list-mapping: "record<account_sid: string, date_created: string, date_updated: string, domain_sid: string, friendly_name: string, sid: string, uri: string>"
    fetch-sip-credential-list-mapping: "record<account_sid: string, date_created: string, date_updated: string, domain_sid: string, friendly_name: string, sid: string, uri: string>"
    list-sip-ip-access-control-list-mapping: "record<end: int, first_page_uri: string, ip_access_control_list_mappings: table<account_sid: string, date_created: string, date_updated: string, domain_sid: string, friendly_name: string, sid: string, uri: string>, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>"
    create-sip-ip-access-control-list-mapping: "record<account_sid: string, date_created: string, date_updated: string, domain_sid: string, friendly_name: string, sid: string, uri: string>"
    fetch-sip-ip-access-control-list-mapping: "record<account_sid: string, date_created: string, date_updated: string, domain_sid: string, friendly_name: string, sid: string, uri: string>"
    fetch-sip-domain: "record<account_sid: string, api_version: string, auth_type: string, byoc_trunk_sid: string, date_created: string, date_updated: string, domain_name: string, emergency_caller_sid: string, emergency_calling_enabled: bool, friendly_name: string, secure: bool, sid: string, sip_registration: bool, subresource_uris: record, uri: string, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_status_callback_method: string, voice_status_callback_url: string, voice_url: string>"
    update-sip-domain: "record<account_sid: string, api_version: string, auth_type: string, byoc_trunk_sid: string, date_created: string, date_updated: string, domain_name: string, emergency_caller_sid: string, emergency_calling_enabled: bool, friendly_name: string, secure: bool, sid: string, sip_registration: bool, subresource_uris: record, uri: string, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_status_callback_method: string, voice_status_callback_url: string, voice_url: string>"
    list-sip-ip-access-control-list: "record<end: int, first_page_uri: string, ip_access_control_lists: table<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sid: string, subresource_uris: record, uri: string>, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>"
    create-sip-ip-access-control-list: "record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sid: string, subresource_uris: record, uri: string>"
    list-sip-ip-address: "record<end: int, first_page_uri: string, ip_addresses: table<account_sid: string, cidr_prefix_length: int, date_created: string, date_updated: string, friendly_name: string, ip_access_control_list_sid: string, ip_address: string, sid: string, uri: string>, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>"
    create-sip-ip-address: "record<account_sid: string, cidr_prefix_length: int, date_created: string, date_updated: string, friendly_name: string, ip_access_control_list_sid: string, ip_address: string, sid: string, uri: string>"
    fetch-sip-ip-address: "record<account_sid: string, cidr_prefix_length: int, date_created: string, date_updated: string, friendly_name: string, ip_access_control_list_sid: string, ip_address: string, sid: string, uri: string>"
    update-sip-ip-address: "record<account_sid: string, cidr_prefix_length: int, date_created: string, date_updated: string, friendly_name: string, ip_access_control_list_sid: string, ip_address: string, sid: string, uri: string>"
    fetch-sip-ip-access-control-list: "record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sid: string, subresource_uris: record, uri: string>"
    update-sip-ip-access-control-list: "record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sid: string, subresource_uris: record, uri: string>"
    list-short-code: "record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, short_codes: table<account_sid: string, api_version: string, date_created: string, date_updated: string, friendly_name: string, short_code: string, sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, uri: string>, start: int, uri: string>"
    fetch-short-code: "record<account_sid: string, api_version: string, date_created: string, date_updated: string, friendly_name: string, short_code: string, sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, uri: string>"
    update-short-code: "record<account_sid: string, api_version: string, date_created: string, date_updated: string, friendly_name: string, short_code: string, sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, uri: string>"
    list-signing-key: "record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, signing_keys: table<date_created: string, date_updated: string, friendly_name: string, sid: string>, start: int, uri: string>"
    create-new-signing-key: "record<date_created: string, date_updated: string, friendly_name: string, secret: string, sid: string>"
    fetch-signing-key: "record<date_created: string, date_updated: string, friendly_name: string, sid: string>"
    update-signing-key: "record<date_created: string, date_updated: string, friendly_name: string, sid: string>"
    create-token: "record<account_sid: string, date_created: string, date_updated: string, ice_servers: table<credential: string, url: string, urls: string, username: string>, password: string, ttl: string, username: string>"
    list-transcription: "record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, transcriptions: table<account_sid: string, api_version: string, date_created: string, date_updated: string, duration: string, price: float, price_unit: string, recording_sid: string, sid: string, status: string, transcription_text: string, type: string, uri: string>, uri: string>"
    fetch-transcription: "record<account_sid: string, api_version: string, date_created: string, date_updated: string, duration: string, price: float, price_unit: string, recording_sid: string, sid: string, status: string, transcription_text: string, type: string, uri: string>"
    list-usage-record: "record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, usage_records: table<account_sid: string, api_version: string, as_of: string, category: string, count: string, count_unit: string, description: string, end_date: string, price: float, price_unit: string, start_date: string, subresource_uris: record, uri: string, usage: string, usage_unit: string>>"
    list-usage-record-all-time: "record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, usage_records: table<account_sid: string, api_version: string, as_of: string, category: string, count: string, count_unit: string, description: string, end_date: string, price: float, price_unit: string, start_date: string, subresource_uris: record, uri: string, usage: string, usage_unit: string>>"
    list-usage-record-daily: "record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, usage_records: table<account_sid: string, api_version: string, as_of: string, category: string, count: string, count_unit: string, description: string, end_date: string, price: float, price_unit: string, start_date: string, subresource_uris: record, uri: string, usage: string, usage_unit: string>>"
    list-usage-record-last-month: "record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, usage_records: table<account_sid: string, api_version: string, as_of: string, category: string, count: string, count_unit: string, description: string, end_date: string, price: float, price_unit: string, start_date: string, subresource_uris: record, uri: string, usage: string, usage_unit: string>>"
    list-usage-record-monthly: "record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, usage_records: table<account_sid: string, api_version: string, as_of: string, category: string, count: string, count_unit: string, description: string, end_date: string, price: float, price_unit: string, start_date: string, subresource_uris: record, uri: string, usage: string, usage_unit: string>>"
    list-usage-record-this-month: "record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, usage_records: table<account_sid: string, api_version: string, as_of: string, category: string, count: string, count_unit: string, description: string, end_date: string, price: float, price_unit: string, start_date: string, subresource_uris: record, uri: string, usage: string, usage_unit: string>>"
    list-usage-record-today: "record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, usage_records: table<account_sid: string, api_version: string, as_of: string, category: string, count: string, count_unit: string, description: string, end_date: string, price: float, price_unit: string, start_date: string, subresource_uris: record, uri: string, usage: string, usage_unit: string>>"
    list-usage-record-yearly: "record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, usage_records: table<account_sid: string, api_version: string, as_of: string, category: string, count: string, count_unit: string, description: string, end_date: string, price: float, price_unit: string, start_date: string, subresource_uris: record, uri: string, usage: string, usage_unit: string>>"
    list-usage-record-yesterday: "record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, usage_records: table<account_sid: string, api_version: string, as_of: string, category: string, count: string, count_unit: string, description: string, end_date: string, price: float, price_unit: string, start_date: string, subresource_uris: record, uri: string, usage: string, usage_unit: string>>"
    list-usage-trigger: "record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, usage_triggers: table<account_sid: string, api_version: string, callback_method: string, callback_url: string, current_value: string, date_created: string, date_fired: string, date_updated: string, friendly_name: string, recurring: string, sid: string, trigger_by: string, trigger_value: string, uri: string, usage_category: string, usage_record_uri: string>>"
    create-usage-trigger: "record<account_sid: string, api_version: string, callback_method: string, callback_url: string, current_value: string, date_created: string, date_fired: string, date_updated: string, friendly_name: string, recurring: string, sid: string, trigger_by: string, trigger_value: string, uri: string, usage_category: string, usage_record_uri: string>"
    fetch-usage-trigger: "record<account_sid: string, api_version: string, callback_method: string, callback_url: string, current_value: string, date_created: string, date_fired: string, date_updated: string, friendly_name: string, recurring: string, sid: string, trigger_by: string, trigger_value: string, uri: string, usage_category: string, usage_record_uri: string>"
    update-usage-trigger: "record<account_sid: string, api_version: string, callback_method: string, callback_url: string, current_value: string, date_created: string, date_fired: string, date_updated: string, friendly_name: string, recurring: string, sid: string, trigger_by: string, trigger_value: string, uri: string, usage_category: string, usage_record_uri: string>"
    fetch-account: "record<auth_token: string, date_created: string, date_updated: string, friendly_name: string, owner_account_sid: string, sid: string, status: string, subresource_uris: record, type: string, uri: string>"
    update-account: "record<auth_token: string, date_created: string, date_updated: string, friendly_name: string, owner_account_sid: string, sid: string, status: string, subresource_uris: record, type: string, uri: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["list-account" "create-account" "list-address" "create-address" "list-dependent-phone-number" "delete-address" "fetch-address" "update-address" "list-application" "create-application" "delete-application" "fetch-application" "update-application" "list-authorized-connect-app" "fetch-authorized-connect-app" "list-available-phone-number-country" "fetch-available-phone-number-country" "list-available-phone-number-local" "list-available-phone-number-machine-to-machine" "list-available-phone-number-mobile" "list-available-phone-number-national" "list-available-phone-number-shared-cost" "list-available-phone-number-toll-free" "list-available-phone-number-voip" "fetch-balance" "list-call" "create-call" "create-call-feedback-summary" "delete-call-feedback-summary" "fetch-call-feedback-summary" "list-call-event" "fetch-call-feedback" "update-call-feedback" "list-call-notification" "fetch-call-notification" "create-payments" "update-payments" "list-call-recording" "create-call-recording" "delete-call-recording" "fetch-call-recording" "update-call-recording" "create-siprec" "update-siprec" "create-stream" "update-stream" "create-user-defined-message-subscription" "delete-user-defined-message-subscription" "create-user-defined-message" "delete-call" "fetch-call" "update-call" "list-conference" "list-participant" "create-participant" "delete-participant" "fetch-participant" "update-participant" "list-conference-recording" "delete-conference-recording" "fetch-conference-recording" "update-conference-recording" "fetch-conference" "update-conference" "list-connect-app" "delete-connect-app" "fetch-connect-app" "update-connect-app" "list-incoming-phone-number" "create-incoming-phone-number" "list-incoming-phone-number-local" "create-incoming-phone-number-local" "list-incoming-phone-number-mobile" "create-incoming-phone-number-mobile" "list-incoming-phone-number-toll-free" "create-incoming-phone-number-toll-free" "list-incoming-phone-number-assigned-add-on" "create-incoming-phone-number-assigned-add-on" "list-incoming-phone-number-assigned-add-on-extension" "fetch-incoming-phone-number-assigned-add-on-extension" "delete-incoming-phone-number-assigned-add-on" "fetch-incoming-phone-number-assigned-add-on" "delete-incoming-phone-number" "fetch-incoming-phone-number" "update-incoming-phone-number" "list-key" "create-new-key" "delete-key" "fetch-key" "update-key" "list-message" "create-message" "create-message-feedback" "list-media" "delete-media" "fetch-media" "delete-message" "fetch-message" "update-message" "list-notification" "fetch-notification" "list-outgoing-caller-id" "create-validation-request" "delete-outgoing-caller-id" "fetch-outgoing-caller-id" "update-outgoing-caller-id" "list-queue" "create-queue" "list-member" "fetch-member" "update-member" "delete-queue" "fetch-queue" "update-queue" "list-recording" "list-recording-transcription" "delete-recording-transcription" "fetch-recording-transcription" "list-recording-add-on-result" "list-recording-add-on-result-payload" "delete-recording-add-on-result-payload" "fetch-recording-add-on-result-payload" "delete-recording-add-on-result" "fetch-recording-add-on-result" "delete-recording" "fetch-recording" "list-sip-credential-list" "create-sip-credential-list" "list-sip-credential" "create-sip-credential" "delete-sip-credential" "fetch-sip-credential" "update-sip-credential" "delete-sip-credential-list" "fetch-sip-credential-list" "update-sip-credential-list" "list-sip-domain" "create-sip-domain" "list-sip-auth-calls-credential-list-mapping" "create-sip-auth-calls-credential-list-mapping" "delete-sip-auth-calls-credential-list-mapping" "fetch-sip-auth-calls-credential-list-mapping" "list-sip-auth-calls-ip-access-control-list-mapping" "create-sip-auth-calls-ip-access-control-list-mapping" "delete-sip-auth-calls-ip-access-control-list-mapping" "fetch-sip-auth-calls-ip-access-control-list-mapping" "list-sip-auth-registrations-credential-list-mapping" "create-sip-auth-registrations-credential-list-mapping" "delete-sip-auth-registrations-credential-list-mapping" "fetch-sip-auth-registrations-credential-list-mapping" "list-sip-credential-list-mapping" "create-sip-credential-list-mapping" "delete-sip-credential-list-mapping" "fetch-sip-credential-list-mapping" "list-sip-ip-access-control-list-mapping" "create-sip-ip-access-control-list-mapping" "delete-sip-ip-access-control-list-mapping" "fetch-sip-ip-access-control-list-mapping" "delete-sip-domain" "fetch-sip-domain" "update-sip-domain" "list-sip-ip-access-control-list" "create-sip-ip-access-control-list" "list-sip-ip-address" "create-sip-ip-address" "delete-sip-ip-address" "fetch-sip-ip-address" "update-sip-ip-address" "delete-sip-ip-access-control-list" "fetch-sip-ip-access-control-list" "update-sip-ip-access-control-list" "list-short-code" "fetch-short-code" "update-short-code" "list-signing-key" "create-new-signing-key" "delete-signing-key" "fetch-signing-key" "update-signing-key" "create-token" "list-transcription" "delete-transcription" "fetch-transcription" "list-usage-record" "list-usage-record-all-time" "list-usage-record-daily" "list-usage-record-last-month" "list-usage-record-monthly" "list-usage-record-this-month" "list-usage-record-today" "list-usage-record-yearly" "list-usage-record-yesterday" "list-usage-trigger" "create-usage-trigger" "delete-usage-trigger" "fetch-usage-trigger" "update-usage-trigger" "fetch-account" "update-account" "commands"] | sort) } | get name | first)
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

# Retrieves a collection of Accounts belonging to the account used to make the request
#
# GET /2010-04-01/Accounts.json
# Returns: record<accounts: table<auth_token: string, date_created: string, date_updated: string, friendly_name: string, owner_account_sid: string, sid: string, status: string, subresource_uris: record, type: string, uri: string>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>
# operationId: ListAccount
export def "list-account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --friendly-name: string # Only return the Account resources with friendly names that exactly match this name.
  --status: string@status-completer # Only return Account resources with the given status. Can be `closed`, `suspended` or `active`.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2010-04-01/Accounts.json"
    query: [{name: FriendlyName, var: friendly_name}, {name: Status, var: status}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    friendly_name: $friendly_name, status: $status, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new Twilio Subaccount from the account making the request
#
# POST /2010-04-01/Accounts.json
# Returns: record<auth_token: string, date_created: string, date_updated: string, friendly_name: string, owner_account_sid: string, sid: string, status: string, subresource_uris: record, type: string, uri: string>
# operationId: CreateAccount
export def "create-account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --friendly-name: string # A human readable description of the account to create, defaults to `SubAccount Created at {YYYY-MM-DD HH:MM meridian}`
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2010-04-01/Accounts.json"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: FriendlyName, var: friendly_name}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    friendly_name: $friendly_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /2010-04-01/Accounts/{AccountSid}/Addresses.json
#
# Returns: record<addresses: table<account_sid: string, city: string, customer_name: string, date_created: string, date_updated: string, emergency_enabled: bool, friendly_name: string, iso_country: string, postal_code: string, region: string, sid: string, street: string, street_secondary: string, uri: string, validated: bool, verified: bool>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>
# operationId: ListAddress
export def "list-address" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --customer-name: string # The `customer_name` of the Address resources to read.
  --friendly-name: string # The string that identifies the Address resources to read.
  --iso-country: string # The ISO country code of the Address resources to read. (format: iso-country-code)
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2010-04-01/Accounts/{AccountSid}/Addresses.json"
    path_params: [{name: AccountSid, var: account_sid}]
    query: [{name: CustomerName, var: customer_name}, {name: FriendlyName, var: friendly_name}, {name: IsoCountry, var: iso_country}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, customer_name: $customer_name, friendly_name: $friendly_name, iso_country: $iso_country, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /2010-04-01/Accounts/{AccountSid}/Addresses.json
#
# Returns: record<account_sid: string, city: string, customer_name: string, date_created: string, date_updated: string, emergency_enabled: bool, friendly_name: string, iso_country: string, postal_code: string, region: string, sid: string, street: string, street_secondary: string, uri: string, validated: bool, verified: bool>
# operationId: CreateAddress
export def "create-address" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-correct-address: oneof<nothing, bool> # Whether we should automatically correct the address. Can be: `true` or `false` and the default is `true`. If empty or `true`, we will correct the address you provide if necessary. If `false`, we won't alter the address you provide.
  city: string # The city of the new address.
  customer_name: string # The name to associate with the new address.
  --emergency-enabled: oneof<nothing, bool> # Whether to enable emergency calling on the new address. Can be: `true` or `false`.
  --friendly-name: string # A descriptive string that you create to describe the new address. It can be up to 64 characters long.
  iso_country: string # The ISO country code of the new address. (format: iso-country-code)
  postal_code: string # The postal code of the new address.
  region: string # The state or region of the new address.
  street: string # The number and street address of the new address.
  --street-secondary: string # The additional number and street address of the address.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2010-04-01/Accounts/{AccountSid}/Addresses.json"
    path_params: [{name: AccountSid, var: account_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: AutoCorrectAddress, var: auto_correct_address}, {name: City, var: city}, {name: CustomerName, var: customer_name}, {name: EmergencyEnabled, var: emergency_enabled}, {name: FriendlyName, var: friendly_name}, {name: IsoCountry, var: iso_country}, {name: PostalCode, var: postal_code}, {name: Region, var: region}, {name: Street, var: street}, {name: StreetSecondary, var: street_secondary}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, auto_correct_address: $auto_correct_address, city: $city, customer_name: $customer_name, emergency_enabled: $emergency_enabled, friendly_name: $friendly_name, iso_country: $iso_country, postal_code: $postal_code, region: $region, street: $street, street_secondary: $street_secondary
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /2010-04-01/Accounts/{AccountSid}/Addresses/{AddressSid}/DependentPhoneNumbers.json
#
# Returns: record<dependent_phone_numbers: table<account_sid: string, address_requirements: string, api_version: string, capabilities: any, date_created: string, date_updated: string, emergency_address_sid: string, emergency_status: string, friendly_name: string, phone_number: string, sid: string, sms_application_sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, status_callback: string, status_callback_method: string, trunk_sid: string, uri: string, voice_application_sid: string, voice_caller_id_lookup: bool, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_url: string>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>
# operationId: ListDependentPhoneNumber
export def "list-dependent-phone-number" [
  account_sid: string
  address_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/Addresses/{AddressSid}/DependentPhoneNumbers.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: AddressSid, var: address_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, address_sid: $address_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /2010-04-01/Accounts/{AccountSid}/Addresses/{Sid}.json
#
# operationId: DeleteAddress
export def "delete-address" [
  account_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/Addresses/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /2010-04-01/Accounts/{AccountSid}/Addresses/{Sid}.json
#
# Returns: record<account_sid: string, city: string, customer_name: string, date_created: string, date_updated: string, emergency_enabled: bool, friendly_name: string, iso_country: string, postal_code: string, region: string, sid: string, street: string, street_secondary: string, uri: string, validated: bool, verified: bool>
# operationId: FetchAddress
export def "fetch-address" [
  account_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/Addresses/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /2010-04-01/Accounts/{AccountSid}/Addresses/{Sid}.json
#
# Returns: record<account_sid: string, city: string, customer_name: string, date_created: string, date_updated: string, emergency_enabled: bool, friendly_name: string, iso_country: string, postal_code: string, region: string, sid: string, street: string, street_secondary: string, uri: string, validated: bool, verified: bool>
# operationId: UpdateAddress
export def "update-address" [
  account_sid: string
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
  --auto-correct-address: oneof<nothing, bool> # Whether we should automatically correct the address. Can be: `true` or `false` and the default is `true`. If empty or `true`, we will correct the address you provide if necessary. If `false`, we won't alter the address you provide.
  --city: string # The city of the address.
  --customer-name: string # The name to associate with the address.
  --emergency-enabled: oneof<nothing, bool> # Whether to enable emergency calling on the address. Can be: `true` or `false`.
  --friendly-name: string # A descriptive string that you create to describe the address. It can be up to 64 characters long.
  --postal-code: string # The postal code of the address.
  --region: string # The state or region of the address.
  --street: string # The number and street address of the address.
  --street-secondary: string # The additional number and street address of the address.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2010-04-01/Accounts/{AccountSid}/Addresses/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: AutoCorrectAddress, var: auto_correct_address}, {name: City, var: city}, {name: CustomerName, var: customer_name}, {name: EmergencyEnabled, var: emergency_enabled}, {name: FriendlyName, var: friendly_name}, {name: PostalCode, var: postal_code}, {name: Region, var: region}, {name: Street, var: street}, {name: StreetSecondary, var: street_secondary}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, sid: $sid, auto_correct_address: $auto_correct_address, city: $city, customer_name: $customer_name, emergency_enabled: $emergency_enabled, friendly_name: $friendly_name, postal_code: $postal_code, region: $region, street: $street, street_secondary: $street_secondary
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of applications representing an application within the requesting account
#
# GET /2010-04-01/Accounts/{AccountSid}/Applications.json
# Returns: record<applications: table<account_sid: string, api_version: string, date_created: string, date_updated: string, friendly_name: string, message_status_callback: string, public_application_connect_enabled: bool, sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_status_callback: string, sms_url: string, status_callback: string, status_callback_method: string, uri: string, voice_caller_id_lookup: bool, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_url: string>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>
# operationId: ListApplication
export def "list-application" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --friendly-name: string # The string that identifies the Application resources to read.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2010-04-01/Accounts/{AccountSid}/Applications.json"
    path_params: [{name: AccountSid, var: account_sid}]
    query: [{name: FriendlyName, var: friendly_name}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, friendly_name: $friendly_name, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new application within your account
#
# POST /2010-04-01/Accounts/{AccountSid}/Applications.json
# Returns: record<account_sid: string, api_version: string, date_created: string, date_updated: string, friendly_name: string, message_status_callback: string, public_application_connect_enabled: bool, sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_status_callback: string, sms_url: string, status_callback: string, status_callback_method: string, uri: string, voice_caller_id_lookup: bool, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_url: string>
# operationId: CreateApplication
export def "create-application" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use to start a new TwiML session. Can be: `2010-04-01` or `2008-08-01`. The default value is the account's default API version.
  --friendly-name: string # A descriptive string that you create to describe the new application. It can be up to 64 characters long.
  --message-status-callback: string # The URL we should call using a POST method to send message status information to your application. (format: uri)
  --public-application-connect-enabled: oneof<nothing, bool> # Whether to allow other Twilio accounts to dial this applicaton using Dial verb. Can be: `true` or `false`.
  --sms-fallback-method: string@sms-fallback-method-completer # The HTTP method we should use to call `sms_fallback_url`. Can be: `GET` or `POST`. (format: http-method)
  --sms-fallback-url: string # The URL that we should call when an error occurs while retrieving or executing the TwiML from `sms_url`. (format: uri)
  --sms-method: string@sms-method-completer # The HTTP method we should use to call `sms_url`. Can be: `GET` or `POST`. (format: http-method)
  --sms-status-callback: string # The URL we should call using a POST method to send status information about SMS messages sent by the application. (format: uri)
  --sms-url: string # The URL we should call when the phone number receives an incoming SMS message. (format: uri)
  --status-callback: string # The URL we should call using the `status_callback_method` to send status information to your application. (format: uri)
  --status-callback-method: string@status-callback-method-completer # The HTTP method we should use to call `status_callback`. Can be: `GET` or `POST`. (format: http-method)
  --voice-caller-id-lookup: oneof<nothing, bool> # Whether we should look up the caller's caller-ID name from the CNAM database (additional charges apply). Can be: `true` or `false`.
  --voice-fallback-method: string@voice-fallback-method-completer # The HTTP method we should use to call `voice_fallback_url`. Can be: `GET` or `POST`. (format: http-method)
  --voice-fallback-url: string # The URL that we should call when an error occurs retrieving or executing the TwiML requested by `url`. (format: uri)
  --voice-method: string@voice-method-completer # The HTTP method we should use to call `voice_url`. Can be: `GET` or `POST`. (format: http-method)
  --voice-url: string # The URL we should call when the phone number assigned to this application receives a call. (format: uri)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2010-04-01/Accounts/{AccountSid}/Applications.json"
    path_params: [{name: AccountSid, var: account_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: ApiVersion, var: api_version}, {name: FriendlyName, var: friendly_name}, {name: MessageStatusCallback, var: message_status_callback}, {name: PublicApplicationConnectEnabled, var: public_application_connect_enabled}, {name: SmsFallbackMethod, var: sms_fallback_method}, {name: SmsFallbackUrl, var: sms_fallback_url}, {name: SmsMethod, var: sms_method}, {name: SmsStatusCallback, var: sms_status_callback}, {name: SmsUrl, var: sms_url}, {name: StatusCallback, var: status_callback}, {name: StatusCallbackMethod, var: status_callback_method}, {name: VoiceCallerIdLookup, var: voice_caller_id_lookup}, {name: VoiceFallbackMethod, var: voice_fallback_method}, {name: VoiceFallbackUrl, var: voice_fallback_url}, {name: VoiceMethod, var: voice_method}, {name: VoiceUrl, var: voice_url}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, api_version: $api_version, friendly_name: $friendly_name, message_status_callback: $message_status_callback, public_application_connect_enabled: $public_application_connect_enabled, sms_fallback_method: $sms_fallback_method, sms_fallback_url: $sms_fallback_url, sms_method: $sms_method, sms_status_callback: $sms_status_callback, sms_url: $sms_url, status_callback: $status_callback, status_callback_method: $status_callback_method, voice_caller_id_lookup: $voice_caller_id_lookup, voice_fallback_method: $voice_fallback_method, voice_fallback_url: $voice_fallback_url, voice_method: $voice_method, voice_url: $voice_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete the application by the specified application sid
#
# DELETE /2010-04-01/Accounts/{AccountSid}/Applications/{Sid}.json
# operationId: DeleteApplication
export def "delete-application" [
  account_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/Applications/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch the application specified by the provided sid
#
# GET /2010-04-01/Accounts/{AccountSid}/Applications/{Sid}.json
# Returns: record<account_sid: string, api_version: string, date_created: string, date_updated: string, friendly_name: string, message_status_callback: string, public_application_connect_enabled: bool, sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_status_callback: string, sms_url: string, status_callback: string, status_callback_method: string, uri: string, voice_caller_id_lookup: bool, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_url: string>
# operationId: FetchApplication
export def "fetch-application" [
  account_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/Applications/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the application's properties
#
# POST /2010-04-01/Accounts/{AccountSid}/Applications/{Sid}.json
# Returns: record<account_sid: string, api_version: string, date_created: string, date_updated: string, friendly_name: string, message_status_callback: string, public_application_connect_enabled: bool, sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_status_callback: string, sms_url: string, status_callback: string, status_callback_method: string, uri: string, voice_caller_id_lookup: bool, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_url: string>
# operationId: UpdateApplication
export def "update-application" [
  account_sid: string
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
  --api-version: string # The API version to use to start a new TwiML session. Can be: `2010-04-01` or `2008-08-01`. The default value is your account's default API version.
  --friendly-name: string # A descriptive string that you create to describe the resource. It can be up to 64 characters long.
  --message-status-callback: string # The URL we should call using a POST method to send message status information to your application. (format: uri)
  --public-application-connect-enabled: oneof<nothing, bool> # Whether to allow other Twilio accounts to dial this applicaton using Dial verb. Can be: `true` or `false`.
  --sms-fallback-method: string@sms-fallback-method-completer # The HTTP method we should use to call `sms_fallback_url`. Can be: `GET` or `POST`. (format: http-method)
  --sms-fallback-url: string # The URL that we should call when an error occurs while retrieving or executing the TwiML from `sms_url`. (format: uri)
  --sms-method: string@sms-method-completer # The HTTP method we should use to call `sms_url`. Can be: `GET` or `POST`. (format: http-method)
  --sms-status-callback: string # Same as message_status_callback: The URL we should call using a POST method to send status information about SMS messages sent by the application. Deprecated, included for backwards compatibility. (format: uri)
  --sms-url: string # The URL we should call when the phone number receives an incoming SMS message. (format: uri)
  --status-callback: string # The URL we should call using the `status_callback_method` to send status information to your application. (format: uri)
  --status-callback-method: string@status-callback-method-completer # The HTTP method we should use to call `status_callback`. Can be: `GET` or `POST`. (format: http-method)
  --voice-caller-id-lookup: oneof<nothing, bool> # Whether we should look up the caller's caller-ID name from the CNAM database (additional charges apply). Can be: `true` or `false`.
  --voice-fallback-method: string@voice-fallback-method-completer # The HTTP method we should use to call `voice_fallback_url`. Can be: `GET` or `POST`. (format: http-method)
  --voice-fallback-url: string # The URL that we should call when an error occurs retrieving or executing the TwiML requested by `url`. (format: uri)
  --voice-method: string@voice-method-completer # The HTTP method we should use to call `voice_url`. Can be: `GET` or `POST`. (format: http-method)
  --voice-url: string # The URL we should call when the phone number assigned to this application receives a call. (format: uri)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2010-04-01/Accounts/{AccountSid}/Applications/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: ApiVersion, var: api_version}, {name: FriendlyName, var: friendly_name}, {name: MessageStatusCallback, var: message_status_callback}, {name: PublicApplicationConnectEnabled, var: public_application_connect_enabled}, {name: SmsFallbackMethod, var: sms_fallback_method}, {name: SmsFallbackUrl, var: sms_fallback_url}, {name: SmsMethod, var: sms_method}, {name: SmsStatusCallback, var: sms_status_callback}, {name: SmsUrl, var: sms_url}, {name: StatusCallback, var: status_callback}, {name: StatusCallbackMethod, var: status_callback_method}, {name: VoiceCallerIdLookup, var: voice_caller_id_lookup}, {name: VoiceFallbackMethod, var: voice_fallback_method}, {name: VoiceFallbackUrl, var: voice_fallback_url}, {name: VoiceMethod, var: voice_method}, {name: VoiceUrl, var: voice_url}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, sid: $sid, api_version: $api_version, friendly_name: $friendly_name, message_status_callback: $message_status_callback, public_application_connect_enabled: $public_application_connect_enabled, sms_fallback_method: $sms_fallback_method, sms_fallback_url: $sms_fallback_url, sms_method: $sms_method, sms_status_callback: $sms_status_callback, sms_url: $sms_url, status_callback: $status_callback, status_callback_method: $status_callback_method, voice_caller_id_lookup: $voice_caller_id_lookup, voice_fallback_method: $voice_fallback_method, voice_fallback_url: $voice_fallback_url, voice_method: $voice_method, voice_url: $voice_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of authorized-connect-apps belonging to the account used to make the request
#
# GET /2010-04-01/Accounts/{AccountSid}/AuthorizedConnectApps.json
# Returns: record<authorized_connect_apps: table<account_sid: string, connect_app_company_name: string, connect_app_description: string, connect_app_friendly_name: string, connect_app_homepage_url: string, connect_app_sid: string, date_created: string, date_updated: string, permissions: list, uri: string>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>
# operationId: ListAuthorizedConnectApp
export def "list-authorized-connect-app" [
  account_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/AuthorizedConnectApps.json"
    path_params: [{name: AccountSid, var: account_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch an instance of an authorized-connect-app
#
# GET /2010-04-01/Accounts/{AccountSid}/AuthorizedConnectApps/{ConnectAppSid}.json
# Returns: record<account_sid: string, connect_app_company_name: string, connect_app_description: string, connect_app_friendly_name: string, connect_app_homepage_url: string, connect_app_sid: string, date_created: string, date_updated: string, permissions: list<string>, uri: string>
# operationId: FetchAuthorizedConnectApp
export def "fetch-authorized-connect-app" [
  account_sid: string
  connect_app_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/AuthorizedConnectApps/{ConnectAppSid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: ConnectAppSid, var: connect_app_sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, connect_app_sid: $connect_app_sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /2010-04-01/Accounts/{AccountSid}/AvailablePhoneNumbers.json
#
# Returns: record<countries: table<beta: bool, country: string, country_code: string, subresource_uris: record, uri: string>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>
# operationId: ListAvailablePhoneNumberCountry
export def "list-available-phone-number-country" [
  account_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/AvailablePhoneNumbers.json"
    path_params: [{name: AccountSid, var: account_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /2010-04-01/Accounts/{AccountSid}/AvailablePhoneNumbers/{CountryCode}.json
#
# Returns: record<beta: bool, country: string, country_code: string, subresource_uris: record, uri: string>
# operationId: FetchAvailablePhoneNumberCountry
export def "fetch-available-phone-number-country" [
  account_sid: string
  country_code: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/AvailablePhoneNumbers/{CountryCode}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: CountryCode, var: country_code}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, country_code: $country_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /2010-04-01/Accounts/{AccountSid}/AvailablePhoneNumbers/{CountryCode}/Local.json
#
# Returns: record<available_phone_numbers: table<address_requirements: string, beta: bool, capabilities: record, friendly_name: string, iso_country: string, lata: string, latitude: float, locality: string, longitude: float, phone_number: string, postal_code: string, rate_center: string, region: string>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>
# operationId: ListAvailablePhoneNumberLocal
export def "list-available-phone-number-local" [
  account_sid: string
  country_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --area-code: int # The area code of the phone numbers to read. Applies to only phone numbers in the US and Canada.
  --contains: string # The pattern on which to match phone numbers. Valid characters are `*`, `0-9`, `a-z`, and `A-Z`. The `*` character matches any single digit. For examples, see [Example 2](https://www.twilio.com/docs/phone-numbers/api/availablephonenumberlocal-resource?code-sample=code-find-phone-numbers-by-number-pattern) and [Example 3](https://www.twilio.com/docs/phone-numbers/api/availablephonenumberlocal-resource?code-sample=code-find-phone-numbers-by-character-pattern). If specified, this value must have at least two characters.
  --sms-enabled: oneof<nothing, bool> # Whether the phone numbers can receive text messages. Can be: `true` or `false`.
  --mms-enabled: oneof<nothing, bool> # Whether the phone numbers can receive MMS messages. Can be: `true` or `false`.
  --voice-enabled: oneof<nothing, bool> # Whether the phone numbers can receive calls. Can be: `true` or `false`.
  --exclude-all-address-required: oneof<nothing, bool> # Whether to exclude phone numbers that require an [Address](https://www.twilio.com/docs/usage/api/address). Can be: `true` or `false` and the default is `false`.
  --exclude-local-address-required: oneof<nothing, bool> # Whether to exclude phone numbers that require a local [Address](https://www.twilio.com/docs/usage/api/address). Can be: `true` or `false` and the default is `false`.
  --exclude-foreign-address-required: oneof<nothing, bool> # Whether to exclude phone numbers that require a foreign [Address](https://www.twilio.com/docs/usage/api/address). Can be: `true` or `false` and the default is `false`.
  --beta: oneof<nothing, bool> # Whether to read phone numbers that are new to the Twilio platform. Can be: `true` or `false` and the default is `true`.
  --near-number: string # Given a phone number, find a geographically close number within `distance` miles. Distance defaults to 25 miles. Applies to only phone numbers in the US and Canada. (format: phone-number)
  --near-lat-long: string # Given a latitude/longitude pair `lat,long` find geographically close numbers within `distance` miles. Applies to only phone numbers in the US and Canada.
  --distance: int # The search radius, in miles, for a `near_` query. Can be up to `500` and the default is `25`. Applies to only phone numbers in the US and Canada.
  --in-postal-code: string # Limit results to a particular postal code. Given a phone number, search within the same postal code as that number. Applies to only phone numbers in the US and Canada.
  --in-region: string # Limit results to a particular region, state, or province. Given a phone number, search within the same region as that number. Applies to only phone numbers in the US and Canada.
  --in-rate-center: string # Limit results to a specific rate center, or given a phone number search within the same rate center as that number. Requires `in_lata` to be set as well. Applies to only phone numbers in the US and Canada.
  --in-lata: string # Limit results to a specific local access and transport area ([LATA](https://en.wikipedia.org/wiki/Local_access_and_transport_area)). Given a phone number, search within the same [LATA](https://en.wikipedia.org/wiki/Local_access_and_transport_area) as that number. Applies to only phone numbers in the US and Canada.
  --in-locality: string # Limit results to a particular locality or city. Given a phone number, search within the same Locality as that number.
  --fax-enabled: oneof<nothing, bool> # Whether the phone numbers can receive faxes. Can be: `true` or `false`.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2010-04-01/Accounts/{AccountSid}/AvailablePhoneNumbers/{CountryCode}/Local.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: CountryCode, var: country_code}]
    query: [{name: AreaCode, var: area_code}, {name: Contains, var: contains}, {name: SmsEnabled, var: sms_enabled}, {name: MmsEnabled, var: mms_enabled}, {name: VoiceEnabled, var: voice_enabled}, {name: ExcludeAllAddressRequired, var: exclude_all_address_required}, {name: ExcludeLocalAddressRequired, var: exclude_local_address_required}, {name: ExcludeForeignAddressRequired, var: exclude_foreign_address_required}, {name: Beta, var: beta}, {name: NearNumber, var: near_number}, {name: NearLatLong, var: near_lat_long}, {name: Distance, var: distance}, {name: InPostalCode, var: in_postal_code}, {name: InRegion, var: in_region}, {name: InRateCenter, var: in_rate_center}, {name: InLata, var: in_lata}, {name: InLocality, var: in_locality}, {name: FaxEnabled, var: fax_enabled}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, country_code: $country_code, area_code: $area_code, contains: $contains, sms_enabled: $sms_enabled, mms_enabled: $mms_enabled, voice_enabled: $voice_enabled, exclude_all_address_required: $exclude_all_address_required, exclude_local_address_required: $exclude_local_address_required, exclude_foreign_address_required: $exclude_foreign_address_required, beta: $beta, near_number: $near_number, near_lat_long: $near_lat_long, distance: $distance, in_postal_code: $in_postal_code, in_region: $in_region, in_rate_center: $in_rate_center, in_lata: $in_lata, in_locality: $in_locality, fax_enabled: $fax_enabled, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /2010-04-01/Accounts/{AccountSid}/AvailablePhoneNumbers/{CountryCode}/MachineToMachine.json
#
# Returns: record<available_phone_numbers: table<address_requirements: string, beta: bool, capabilities: record, friendly_name: string, iso_country: string, lata: string, latitude: float, locality: string, longitude: float, phone_number: string, postal_code: string, rate_center: string, region: string>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>
# operationId: ListAvailablePhoneNumberMachineToMachine
export def "list-available-phone-number-machine-to-machine" [
  account_sid: string
  country_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --area-code: int # The area code of the phone numbers to read. Applies to only phone numbers in the US and Canada.
  --contains: string # The pattern on which to match phone numbers. Valid characters are `*`, `0-9`, `a-z`, and `A-Z`. The `*` character matches any single digit. For examples, see [Example 2](https://www.twilio.com/docs/phone-numbers/api/availablephonenumber-resource#local-get-basic-example-2) and [Example 3](https://www.twilio.com/docs/phone-numbers/api/availablephonenumber-resource#local-get-basic-example-3). If specified, this value must have at least two characters.
  --sms-enabled: oneof<nothing, bool> # Whether the phone numbers can receive text messages. Can be: `true` or `false`.
  --mms-enabled: oneof<nothing, bool> # Whether the phone numbers can receive MMS messages. Can be: `true` or `false`.
  --voice-enabled: oneof<nothing, bool> # Whether the phone numbers can receive calls. Can be: `true` or `false`.
  --exclude-all-address-required: oneof<nothing, bool> # Whether to exclude phone numbers that require an [Address](https://www.twilio.com/docs/usage/api/address). Can be: `true` or `false` and the default is `false`.
  --exclude-local-address-required: oneof<nothing, bool> # Whether to exclude phone numbers that require a local [Address](https://www.twilio.com/docs/usage/api/address). Can be: `true` or `false` and the default is `false`.
  --exclude-foreign-address-required: oneof<nothing, bool> # Whether to exclude phone numbers that require a foreign [Address](https://www.twilio.com/docs/usage/api/address). Can be: `true` or `false` and the default is `false`.
  --beta: oneof<nothing, bool> # Whether to read phone numbers that are new to the Twilio platform. Can be: `true` or `false` and the default is `true`.
  --near-number: string # Given a phone number, find a geographically close number within `distance` miles. Distance defaults to 25 miles. Applies to only phone numbers in the US and Canada. (format: phone-number)
  --near-lat-long: string # Given a latitude/longitude pair `lat,long` find geographically close numbers within `distance` miles. Applies to only phone numbers in the US and Canada.
  --distance: int # The search radius, in miles, for a `near_` query. Can be up to `500` and the default is `25`. Applies to only phone numbers in the US and Canada.
  --in-postal-code: string # Limit results to a particular postal code. Given a phone number, search within the same postal code as that number. Applies to only phone numbers in the US and Canada.
  --in-region: string # Limit results to a particular region, state, or province. Given a phone number, search within the same region as that number. Applies to only phone numbers in the US and Canada.
  --in-rate-center: string # Limit results to a specific rate center, or given a phone number search within the same rate center as that number. Requires `in_lata` to be set as well. Applies to only phone numbers in the US and Canada.
  --in-lata: string # Limit results to a specific local access and transport area ([LATA](https://en.wikipedia.org/wiki/Local_access_and_transport_area)). Given a phone number, search within the same [LATA](https://en.wikipedia.org/wiki/Local_access_and_transport_area) as that number. Applies to only phone numbers in the US and Canada.
  --in-locality: string # Limit results to a particular locality or city. Given a phone number, search within the same Locality as that number.
  --fax-enabled: oneof<nothing, bool> # Whether the phone numbers can receive faxes. Can be: `true` or `false`.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2010-04-01/Accounts/{AccountSid}/AvailablePhoneNumbers/{CountryCode}/MachineToMachine.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: CountryCode, var: country_code}]
    query: [{name: AreaCode, var: area_code}, {name: Contains, var: contains}, {name: SmsEnabled, var: sms_enabled}, {name: MmsEnabled, var: mms_enabled}, {name: VoiceEnabled, var: voice_enabled}, {name: ExcludeAllAddressRequired, var: exclude_all_address_required}, {name: ExcludeLocalAddressRequired, var: exclude_local_address_required}, {name: ExcludeForeignAddressRequired, var: exclude_foreign_address_required}, {name: Beta, var: beta}, {name: NearNumber, var: near_number}, {name: NearLatLong, var: near_lat_long}, {name: Distance, var: distance}, {name: InPostalCode, var: in_postal_code}, {name: InRegion, var: in_region}, {name: InRateCenter, var: in_rate_center}, {name: InLata, var: in_lata}, {name: InLocality, var: in_locality}, {name: FaxEnabled, var: fax_enabled}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, country_code: $country_code, area_code: $area_code, contains: $contains, sms_enabled: $sms_enabled, mms_enabled: $mms_enabled, voice_enabled: $voice_enabled, exclude_all_address_required: $exclude_all_address_required, exclude_local_address_required: $exclude_local_address_required, exclude_foreign_address_required: $exclude_foreign_address_required, beta: $beta, near_number: $near_number, near_lat_long: $near_lat_long, distance: $distance, in_postal_code: $in_postal_code, in_region: $in_region, in_rate_center: $in_rate_center, in_lata: $in_lata, in_locality: $in_locality, fax_enabled: $fax_enabled, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /2010-04-01/Accounts/{AccountSid}/AvailablePhoneNumbers/{CountryCode}/Mobile.json
#
# Returns: record<available_phone_numbers: table<address_requirements: string, beta: bool, capabilities: record, friendly_name: string, iso_country: string, lata: string, latitude: float, locality: string, longitude: float, phone_number: string, postal_code: string, rate_center: string, region: string>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>
# operationId: ListAvailablePhoneNumberMobile
export def "list-available-phone-number-mobile" [
  account_sid: string
  country_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --area-code: int # The area code of the phone numbers to read. Applies to only phone numbers in the US and Canada.
  --contains: string # The pattern on which to match phone numbers. Valid characters are `*`, `0-9`, `a-z`, and `A-Z`. The `*` character matches any single digit. For examples, see [Example 2](https://www.twilio.com/docs/phone-numbers/api/availablephonenumber-resource#local-get-basic-example-2) and [Example 3](https://www.twilio.com/docs/phone-numbers/api/availablephonenumber-resource#local-get-basic-example-3). If specified, this value must have at least two characters.
  --sms-enabled: oneof<nothing, bool> # Whether the phone numbers can receive text messages. Can be: `true` or `false`.
  --mms-enabled: oneof<nothing, bool> # Whether the phone numbers can receive MMS messages. Can be: `true` or `false`.
  --voice-enabled: oneof<nothing, bool> # Whether the phone numbers can receive calls. Can be: `true` or `false`.
  --exclude-all-address-required: oneof<nothing, bool> # Whether to exclude phone numbers that require an [Address](https://www.twilio.com/docs/usage/api/address). Can be: `true` or `false` and the default is `false`.
  --exclude-local-address-required: oneof<nothing, bool> # Whether to exclude phone numbers that require a local [Address](https://www.twilio.com/docs/usage/api/address). Can be: `true` or `false` and the default is `false`.
  --exclude-foreign-address-required: oneof<nothing, bool> # Whether to exclude phone numbers that require a foreign [Address](https://www.twilio.com/docs/usage/api/address). Can be: `true` or `false` and the default is `false`.
  --beta: oneof<nothing, bool> # Whether to read phone numbers that are new to the Twilio platform. Can be: `true` or `false` and the default is `true`.
  --near-number: string # Given a phone number, find a geographically close number within `distance` miles. Distance defaults to 25 miles. Applies to only phone numbers in the US and Canada. (format: phone-number)
  --near-lat-long: string # Given a latitude/longitude pair `lat,long` find geographically close numbers within `distance` miles. Applies to only phone numbers in the US and Canada.
  --distance: int # The search radius, in miles, for a `near_` query. Can be up to `500` and the default is `25`. Applies to only phone numbers in the US and Canada.
  --in-postal-code: string # Limit results to a particular postal code. Given a phone number, search within the same postal code as that number. Applies to only phone numbers in the US and Canada.
  --in-region: string # Limit results to a particular region, state, or province. Given a phone number, search within the same region as that number. Applies to only phone numbers in the US and Canada.
  --in-rate-center: string # Limit results to a specific rate center, or given a phone number search within the same rate center as that number. Requires `in_lata` to be set as well. Applies to only phone numbers in the US and Canada.
  --in-lata: string # Limit results to a specific local access and transport area ([LATA](https://en.wikipedia.org/wiki/Local_access_and_transport_area)). Given a phone number, search within the same [LATA](https://en.wikipedia.org/wiki/Local_access_and_transport_area) as that number. Applies to only phone numbers in the US and Canada.
  --in-locality: string # Limit results to a particular locality or city. Given a phone number, search within the same Locality as that number.
  --fax-enabled: oneof<nothing, bool> # Whether the phone numbers can receive faxes. Can be: `true` or `false`.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2010-04-01/Accounts/{AccountSid}/AvailablePhoneNumbers/{CountryCode}/Mobile.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: CountryCode, var: country_code}]
    query: [{name: AreaCode, var: area_code}, {name: Contains, var: contains}, {name: SmsEnabled, var: sms_enabled}, {name: MmsEnabled, var: mms_enabled}, {name: VoiceEnabled, var: voice_enabled}, {name: ExcludeAllAddressRequired, var: exclude_all_address_required}, {name: ExcludeLocalAddressRequired, var: exclude_local_address_required}, {name: ExcludeForeignAddressRequired, var: exclude_foreign_address_required}, {name: Beta, var: beta}, {name: NearNumber, var: near_number}, {name: NearLatLong, var: near_lat_long}, {name: Distance, var: distance}, {name: InPostalCode, var: in_postal_code}, {name: InRegion, var: in_region}, {name: InRateCenter, var: in_rate_center}, {name: InLata, var: in_lata}, {name: InLocality, var: in_locality}, {name: FaxEnabled, var: fax_enabled}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, country_code: $country_code, area_code: $area_code, contains: $contains, sms_enabled: $sms_enabled, mms_enabled: $mms_enabled, voice_enabled: $voice_enabled, exclude_all_address_required: $exclude_all_address_required, exclude_local_address_required: $exclude_local_address_required, exclude_foreign_address_required: $exclude_foreign_address_required, beta: $beta, near_number: $near_number, near_lat_long: $near_lat_long, distance: $distance, in_postal_code: $in_postal_code, in_region: $in_region, in_rate_center: $in_rate_center, in_lata: $in_lata, in_locality: $in_locality, fax_enabled: $fax_enabled, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /2010-04-01/Accounts/{AccountSid}/AvailablePhoneNumbers/{CountryCode}/National.json
#
# Returns: record<available_phone_numbers: table<address_requirements: string, beta: bool, capabilities: record, friendly_name: string, iso_country: string, lata: string, latitude: float, locality: string, longitude: float, phone_number: string, postal_code: string, rate_center: string, region: string>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>
# operationId: ListAvailablePhoneNumberNational
export def "list-available-phone-number-national" [
  account_sid: string
  country_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --area-code: int # The area code of the phone numbers to read. Applies to only phone numbers in the US and Canada.
  --contains: string # The pattern on which to match phone numbers. Valid characters are `*`, `0-9`, `a-z`, and `A-Z`. The `*` character matches any single digit. For examples, see [Example 2](https://www.twilio.com/docs/phone-numbers/api/availablephonenumber-resource#local-get-basic-example-2) and [Example 3](https://www.twilio.com/docs/phone-numbers/api/availablephonenumber-resource#local-get-basic-example-3). If specified, this value must have at least two characters.
  --sms-enabled: oneof<nothing, bool> # Whether the phone numbers can receive text messages. Can be: `true` or `false`.
  --mms-enabled: oneof<nothing, bool> # Whether the phone numbers can receive MMS messages. Can be: `true` or `false`.
  --voice-enabled: oneof<nothing, bool> # Whether the phone numbers can receive calls. Can be: `true` or `false`.
  --exclude-all-address-required: oneof<nothing, bool> # Whether to exclude phone numbers that require an [Address](https://www.twilio.com/docs/usage/api/address). Can be: `true` or `false` and the default is `false`.
  --exclude-local-address-required: oneof<nothing, bool> # Whether to exclude phone numbers that require a local [Address](https://www.twilio.com/docs/usage/api/address). Can be: `true` or `false` and the default is `false`.
  --exclude-foreign-address-required: oneof<nothing, bool> # Whether to exclude phone numbers that require a foreign [Address](https://www.twilio.com/docs/usage/api/address). Can be: `true` or `false` and the default is `false`.
  --beta: oneof<nothing, bool> # Whether to read phone numbers that are new to the Twilio platform. Can be: `true` or `false` and the default is `true`.
  --near-number: string # Given a phone number, find a geographically close number within `distance` miles. Distance defaults to 25 miles. Applies to only phone numbers in the US and Canada. (format: phone-number)
  --near-lat-long: string # Given a latitude/longitude pair `lat,long` find geographically close numbers within `distance` miles. Applies to only phone numbers in the US and Canada.
  --distance: int # The search radius, in miles, for a `near_` query. Can be up to `500` and the default is `25`. Applies to only phone numbers in the US and Canada.
  --in-postal-code: string # Limit results to a particular postal code. Given a phone number, search within the same postal code as that number. Applies to only phone numbers in the US and Canada.
  --in-region: string # Limit results to a particular region, state, or province. Given a phone number, search within the same region as that number. Applies to only phone numbers in the US and Canada.
  --in-rate-center: string # Limit results to a specific rate center, or given a phone number search within the same rate center as that number. Requires `in_lata` to be set as well. Applies to only phone numbers in the US and Canada.
  --in-lata: string # Limit results to a specific local access and transport area ([LATA](https://en.wikipedia.org/wiki/Local_access_and_transport_area)). Given a phone number, search within the same [LATA](https://en.wikipedia.org/wiki/Local_access_and_transport_area) as that number. Applies to only phone numbers in the US and Canada.
  --in-locality: string # Limit results to a particular locality or city. Given a phone number, search within the same Locality as that number.
  --fax-enabled: oneof<nothing, bool> # Whether the phone numbers can receive faxes. Can be: `true` or `false`.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2010-04-01/Accounts/{AccountSid}/AvailablePhoneNumbers/{CountryCode}/National.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: CountryCode, var: country_code}]
    query: [{name: AreaCode, var: area_code}, {name: Contains, var: contains}, {name: SmsEnabled, var: sms_enabled}, {name: MmsEnabled, var: mms_enabled}, {name: VoiceEnabled, var: voice_enabled}, {name: ExcludeAllAddressRequired, var: exclude_all_address_required}, {name: ExcludeLocalAddressRequired, var: exclude_local_address_required}, {name: ExcludeForeignAddressRequired, var: exclude_foreign_address_required}, {name: Beta, var: beta}, {name: NearNumber, var: near_number}, {name: NearLatLong, var: near_lat_long}, {name: Distance, var: distance}, {name: InPostalCode, var: in_postal_code}, {name: InRegion, var: in_region}, {name: InRateCenter, var: in_rate_center}, {name: InLata, var: in_lata}, {name: InLocality, var: in_locality}, {name: FaxEnabled, var: fax_enabled}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, country_code: $country_code, area_code: $area_code, contains: $contains, sms_enabled: $sms_enabled, mms_enabled: $mms_enabled, voice_enabled: $voice_enabled, exclude_all_address_required: $exclude_all_address_required, exclude_local_address_required: $exclude_local_address_required, exclude_foreign_address_required: $exclude_foreign_address_required, beta: $beta, near_number: $near_number, near_lat_long: $near_lat_long, distance: $distance, in_postal_code: $in_postal_code, in_region: $in_region, in_rate_center: $in_rate_center, in_lata: $in_lata, in_locality: $in_locality, fax_enabled: $fax_enabled, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /2010-04-01/Accounts/{AccountSid}/AvailablePhoneNumbers/{CountryCode}/SharedCost.json
#
# Returns: record<available_phone_numbers: table<address_requirements: string, beta: bool, capabilities: record, friendly_name: string, iso_country: string, lata: string, latitude: float, locality: string, longitude: float, phone_number: string, postal_code: string, rate_center: string, region: string>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>
# operationId: ListAvailablePhoneNumberSharedCost
export def "list-available-phone-number-shared-cost" [
  account_sid: string
  country_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --area-code: int # The area code of the phone numbers to read. Applies to only phone numbers in the US and Canada.
  --contains: string # The pattern on which to match phone numbers. Valid characters are `*`, `0-9`, `a-z`, and `A-Z`. The `*` character matches any single digit. For examples, see [Example 2](https://www.twilio.com/docs/phone-numbers/api/availablephonenumber-resource#local-get-basic-example-2) and [Example 3](https://www.twilio.com/docs/phone-numbers/api/availablephonenumber-resource#local-get-basic-example-3). If specified, this value must have at least two characters.
  --sms-enabled: oneof<nothing, bool> # Whether the phone numbers can receive text messages. Can be: `true` or `false`.
  --mms-enabled: oneof<nothing, bool> # Whether the phone numbers can receive MMS messages. Can be: `true` or `false`.
  --voice-enabled: oneof<nothing, bool> # Whether the phone numbers can receive calls. Can be: `true` or `false`.
  --exclude-all-address-required: oneof<nothing, bool> # Whether to exclude phone numbers that require an [Address](https://www.twilio.com/docs/usage/api/address). Can be: `true` or `false` and the default is `false`.
  --exclude-local-address-required: oneof<nothing, bool> # Whether to exclude phone numbers that require a local [Address](https://www.twilio.com/docs/usage/api/address). Can be: `true` or `false` and the default is `false`.
  --exclude-foreign-address-required: oneof<nothing, bool> # Whether to exclude phone numbers that require a foreign [Address](https://www.twilio.com/docs/usage/api/address). Can be: `true` or `false` and the default is `false`.
  --beta: oneof<nothing, bool> # Whether to read phone numbers that are new to the Twilio platform. Can be: `true` or `false` and the default is `true`.
  --near-number: string # Given a phone number, find a geographically close number within `distance` miles. Distance defaults to 25 miles. Applies to only phone numbers in the US and Canada. (format: phone-number)
  --near-lat-long: string # Given a latitude/longitude pair `lat,long` find geographically close numbers within `distance` miles. Applies to only phone numbers in the US and Canada.
  --distance: int # The search radius, in miles, for a `near_` query. Can be up to `500` and the default is `25`. Applies to only phone numbers in the US and Canada.
  --in-postal-code: string # Limit results to a particular postal code. Given a phone number, search within the same postal code as that number. Applies to only phone numbers in the US and Canada.
  --in-region: string # Limit results to a particular region, state, or province. Given a phone number, search within the same region as that number. Applies to only phone numbers in the US and Canada.
  --in-rate-center: string # Limit results to a specific rate center, or given a phone number search within the same rate center as that number. Requires `in_lata` to be set as well. Applies to only phone numbers in the US and Canada.
  --in-lata: string # Limit results to a specific local access and transport area ([LATA](https://en.wikipedia.org/wiki/Local_access_and_transport_area)). Given a phone number, search within the same [LATA](https://en.wikipedia.org/wiki/Local_access_and_transport_area) as that number. Applies to only phone numbers in the US and Canada.
  --in-locality: string # Limit results to a particular locality or city. Given a phone number, search within the same Locality as that number.
  --fax-enabled: oneof<nothing, bool> # Whether the phone numbers can receive faxes. Can be: `true` or `false`.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2010-04-01/Accounts/{AccountSid}/AvailablePhoneNumbers/{CountryCode}/SharedCost.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: CountryCode, var: country_code}]
    query: [{name: AreaCode, var: area_code}, {name: Contains, var: contains}, {name: SmsEnabled, var: sms_enabled}, {name: MmsEnabled, var: mms_enabled}, {name: VoiceEnabled, var: voice_enabled}, {name: ExcludeAllAddressRequired, var: exclude_all_address_required}, {name: ExcludeLocalAddressRequired, var: exclude_local_address_required}, {name: ExcludeForeignAddressRequired, var: exclude_foreign_address_required}, {name: Beta, var: beta}, {name: NearNumber, var: near_number}, {name: NearLatLong, var: near_lat_long}, {name: Distance, var: distance}, {name: InPostalCode, var: in_postal_code}, {name: InRegion, var: in_region}, {name: InRateCenter, var: in_rate_center}, {name: InLata, var: in_lata}, {name: InLocality, var: in_locality}, {name: FaxEnabled, var: fax_enabled}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, country_code: $country_code, area_code: $area_code, contains: $contains, sms_enabled: $sms_enabled, mms_enabled: $mms_enabled, voice_enabled: $voice_enabled, exclude_all_address_required: $exclude_all_address_required, exclude_local_address_required: $exclude_local_address_required, exclude_foreign_address_required: $exclude_foreign_address_required, beta: $beta, near_number: $near_number, near_lat_long: $near_lat_long, distance: $distance, in_postal_code: $in_postal_code, in_region: $in_region, in_rate_center: $in_rate_center, in_lata: $in_lata, in_locality: $in_locality, fax_enabled: $fax_enabled, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /2010-04-01/Accounts/{AccountSid}/AvailablePhoneNumbers/{CountryCode}/TollFree.json
#
# Returns: record<available_phone_numbers: table<address_requirements: string, beta: bool, capabilities: record, friendly_name: string, iso_country: string, lata: string, latitude: float, locality: string, longitude: float, phone_number: string, postal_code: string, rate_center: string, region: string>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>
# operationId: ListAvailablePhoneNumberTollFree
export def "list-available-phone-number-toll-free" [
  account_sid: string
  country_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --area-code: int # The area code of the phone numbers to read. Applies to only phone numbers in the US and Canada.
  --contains: string # The pattern on which to match phone numbers. Valid characters are `*`, `0-9`, `a-z`, and `A-Z`. The `*` character matches any single digit. For examples, see [Example 2](https://www.twilio.com/docs/phone-numbers/api/availablephonenumber-resource#local-get-basic-example-2) and [Example 3](https://www.twilio.com/docs/phone-numbers/api/availablephonenumber-resource#local-get-basic-example-3). If specified, this value must have at least two characters.
  --sms-enabled: oneof<nothing, bool> # Whether the phone numbers can receive text messages. Can be: `true` or `false`.
  --mms-enabled: oneof<nothing, bool> # Whether the phone numbers can receive MMS messages. Can be: `true` or `false`.
  --voice-enabled: oneof<nothing, bool> # Whether the phone numbers can receive calls. Can be: `true` or `false`.
  --exclude-all-address-required: oneof<nothing, bool> # Whether to exclude phone numbers that require an [Address](https://www.twilio.com/docs/usage/api/address). Can be: `true` or `false` and the default is `false`.
  --exclude-local-address-required: oneof<nothing, bool> # Whether to exclude phone numbers that require a local [Address](https://www.twilio.com/docs/usage/api/address). Can be: `true` or `false` and the default is `false`.
  --exclude-foreign-address-required: oneof<nothing, bool> # Whether to exclude phone numbers that require a foreign [Address](https://www.twilio.com/docs/usage/api/address). Can be: `true` or `false` and the default is `false`.
  --beta: oneof<nothing, bool> # Whether to read phone numbers that are new to the Twilio platform. Can be: `true` or `false` and the default is `true`.
  --near-number: string # Given a phone number, find a geographically close number within `distance` miles. Distance defaults to 25 miles. Applies to only phone numbers in the US and Canada. (format: phone-number)
  --near-lat-long: string # Given a latitude/longitude pair `lat,long` find geographically close numbers within `distance` miles. Applies to only phone numbers in the US and Canada.
  --distance: int # The search radius, in miles, for a `near_` query. Can be up to `500` and the default is `25`. Applies to only phone numbers in the US and Canada.
  --in-postal-code: string # Limit results to a particular postal code. Given a phone number, search within the same postal code as that number. Applies to only phone numbers in the US and Canada.
  --in-region: string # Limit results to a particular region, state, or province. Given a phone number, search within the same region as that number. Applies to only phone numbers in the US and Canada.
  --in-rate-center: string # Limit results to a specific rate center, or given a phone number search within the same rate center as that number. Requires `in_lata` to be set as well. Applies to only phone numbers in the US and Canada.
  --in-lata: string # Limit results to a specific local access and transport area ([LATA](https://en.wikipedia.org/wiki/Local_access_and_transport_area)). Given a phone number, search within the same [LATA](https://en.wikipedia.org/wiki/Local_access_and_transport_area) as that number. Applies to only phone numbers in the US and Canada.
  --in-locality: string # Limit results to a particular locality or city. Given a phone number, search within the same Locality as that number.
  --fax-enabled: oneof<nothing, bool> # Whether the phone numbers can receive faxes. Can be: `true` or `false`.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2010-04-01/Accounts/{AccountSid}/AvailablePhoneNumbers/{CountryCode}/TollFree.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: CountryCode, var: country_code}]
    query: [{name: AreaCode, var: area_code}, {name: Contains, var: contains}, {name: SmsEnabled, var: sms_enabled}, {name: MmsEnabled, var: mms_enabled}, {name: VoiceEnabled, var: voice_enabled}, {name: ExcludeAllAddressRequired, var: exclude_all_address_required}, {name: ExcludeLocalAddressRequired, var: exclude_local_address_required}, {name: ExcludeForeignAddressRequired, var: exclude_foreign_address_required}, {name: Beta, var: beta}, {name: NearNumber, var: near_number}, {name: NearLatLong, var: near_lat_long}, {name: Distance, var: distance}, {name: InPostalCode, var: in_postal_code}, {name: InRegion, var: in_region}, {name: InRateCenter, var: in_rate_center}, {name: InLata, var: in_lata}, {name: InLocality, var: in_locality}, {name: FaxEnabled, var: fax_enabled}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, country_code: $country_code, area_code: $area_code, contains: $contains, sms_enabled: $sms_enabled, mms_enabled: $mms_enabled, voice_enabled: $voice_enabled, exclude_all_address_required: $exclude_all_address_required, exclude_local_address_required: $exclude_local_address_required, exclude_foreign_address_required: $exclude_foreign_address_required, beta: $beta, near_number: $near_number, near_lat_long: $near_lat_long, distance: $distance, in_postal_code: $in_postal_code, in_region: $in_region, in_rate_center: $in_rate_center, in_lata: $in_lata, in_locality: $in_locality, fax_enabled: $fax_enabled, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /2010-04-01/Accounts/{AccountSid}/AvailablePhoneNumbers/{CountryCode}/Voip.json
#
# Returns: record<available_phone_numbers: table<address_requirements: string, beta: bool, capabilities: record, friendly_name: string, iso_country: string, lata: string, latitude: float, locality: string, longitude: float, phone_number: string, postal_code: string, rate_center: string, region: string>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>
# operationId: ListAvailablePhoneNumberVoip
export def "list-available-phone-number-voip" [
  account_sid: string
  country_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --area-code: int # The area code of the phone numbers to read. Applies to only phone numbers in the US and Canada.
  --contains: string # The pattern on which to match phone numbers. Valid characters are `*`, `0-9`, `a-z`, and `A-Z`. The `*` character matches any single digit. For examples, see [Example 2](https://www.twilio.com/docs/phone-numbers/api/availablephonenumber-resource#local-get-basic-example-2) and [Example 3](https://www.twilio.com/docs/phone-numbers/api/availablephonenumber-resource#local-get-basic-example-3). If specified, this value must have at least two characters.
  --sms-enabled: oneof<nothing, bool> # Whether the phone numbers can receive text messages. Can be: `true` or `false`.
  --mms-enabled: oneof<nothing, bool> # Whether the phone numbers can receive MMS messages. Can be: `true` or `false`.
  --voice-enabled: oneof<nothing, bool> # Whether the phone numbers can receive calls. Can be: `true` or `false`.
  --exclude-all-address-required: oneof<nothing, bool> # Whether to exclude phone numbers that require an [Address](https://www.twilio.com/docs/usage/api/address). Can be: `true` or `false` and the default is `false`.
  --exclude-local-address-required: oneof<nothing, bool> # Whether to exclude phone numbers that require a local [Address](https://www.twilio.com/docs/usage/api/address). Can be: `true` or `false` and the default is `false`.
  --exclude-foreign-address-required: oneof<nothing, bool> # Whether to exclude phone numbers that require a foreign [Address](https://www.twilio.com/docs/usage/api/address). Can be: `true` or `false` and the default is `false`.
  --beta: oneof<nothing, bool> # Whether to read phone numbers that are new to the Twilio platform. Can be: `true` or `false` and the default is `true`.
  --near-number: string # Given a phone number, find a geographically close number within `distance` miles. Distance defaults to 25 miles. Applies to only phone numbers in the US and Canada. (format: phone-number)
  --near-lat-long: string # Given a latitude/longitude pair `lat,long` find geographically close numbers within `distance` miles. Applies to only phone numbers in the US and Canada.
  --distance: int # The search radius, in miles, for a `near_` query. Can be up to `500` and the default is `25`. Applies to only phone numbers in the US and Canada.
  --in-postal-code: string # Limit results to a particular postal code. Given a phone number, search within the same postal code as that number. Applies to only phone numbers in the US and Canada.
  --in-region: string # Limit results to a particular region, state, or province. Given a phone number, search within the same region as that number. Applies to only phone numbers in the US and Canada.
  --in-rate-center: string # Limit results to a specific rate center, or given a phone number search within the same rate center as that number. Requires `in_lata` to be set as well. Applies to only phone numbers in the US and Canada.
  --in-lata: string # Limit results to a specific local access and transport area ([LATA](https://en.wikipedia.org/wiki/Local_access_and_transport_area)). Given a phone number, search within the same [LATA](https://en.wikipedia.org/wiki/Local_access_and_transport_area) as that number. Applies to only phone numbers in the US and Canada.
  --in-locality: string # Limit results to a particular locality or city. Given a phone number, search within the same Locality as that number.
  --fax-enabled: oneof<nothing, bool> # Whether the phone numbers can receive faxes. Can be: `true` or `false`.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2010-04-01/Accounts/{AccountSid}/AvailablePhoneNumbers/{CountryCode}/Voip.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: CountryCode, var: country_code}]
    query: [{name: AreaCode, var: area_code}, {name: Contains, var: contains}, {name: SmsEnabled, var: sms_enabled}, {name: MmsEnabled, var: mms_enabled}, {name: VoiceEnabled, var: voice_enabled}, {name: ExcludeAllAddressRequired, var: exclude_all_address_required}, {name: ExcludeLocalAddressRequired, var: exclude_local_address_required}, {name: ExcludeForeignAddressRequired, var: exclude_foreign_address_required}, {name: Beta, var: beta}, {name: NearNumber, var: near_number}, {name: NearLatLong, var: near_lat_long}, {name: Distance, var: distance}, {name: InPostalCode, var: in_postal_code}, {name: InRegion, var: in_region}, {name: InRateCenter, var: in_rate_center}, {name: InLata, var: in_lata}, {name: InLocality, var: in_locality}, {name: FaxEnabled, var: fax_enabled}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, country_code: $country_code, area_code: $area_code, contains: $contains, sms_enabled: $sms_enabled, mms_enabled: $mms_enabled, voice_enabled: $voice_enabled, exclude_all_address_required: $exclude_all_address_required, exclude_local_address_required: $exclude_local_address_required, exclude_foreign_address_required: $exclude_foreign_address_required, beta: $beta, near_number: $near_number, near_lat_long: $near_lat_long, distance: $distance, in_postal_code: $in_postal_code, in_region: $in_region, in_rate_center: $in_rate_center, in_lata: $in_lata, in_locality: $in_locality, fax_enabled: $fax_enabled, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch the balance for an Account based on Account Sid. Balance changes may not be reflected immediately. Child accounts do not contain balance information
#
# GET /2010-04-01/Accounts/{AccountSid}/Balance.json
# Returns: record<account_sid: string, balance: string, currency: string>
# operationId: FetchBalance
export def "fetch-balance" [
  account_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/Balance.json"
    path_params: [{name: AccountSid, var: account_sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a collection of calls made to and from your account
#
# GET /2010-04-01/Accounts/{AccountSid}/Calls.json
# Returns: record<calls: table<account_sid: string, answered_by: string, api_version: string, caller_name: string, date_created: string, date_updated: string, direction: string, duration: string, end_time: string, forwarded_from: string, from: string, from_formatted: string, group_sid: string, parent_call_sid: string, phone_number_sid: string, price: string, price_unit: string, queue_time: string, sid: string, start_time: string, status: string, subresource_uris: record, to: string, to_formatted: string, trunk_sid: string, uri: string>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>
# operationId: ListCall
export def "list-call" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --to: string # Only show calls made to this phone number, SIP address, Client identifier or SIM SID. (format: phone-number)
  --from: string # Only include calls from this phone number, SIP address, Client identifier or SIM SID. (format: phone-number)
  --parent-call-sid: string # Only include calls spawned by calls with this SID.
  --status: string@status-completer-1 # The status of the calls to include. Can be: `queued`, `ringing`, `in-progress`, `canceled`, `completed`, `failed`, `busy`, or `no-answer`.
  --start-time: string # Only include calls that started on this date. Specify a date as `YYYY-MM-DD` in GMT, for example: `2009-07-06`, to read only calls that started on this date. You can also specify an inequality, such as `StartTime<=YYYY-MM-DD`, to read calls that started on or before midnight of this date, and `StartTime>=YYYY-MM-DD` to read calls that started on or after midnight of this date. (format: date-time)
  --qp-start-time: string # Only include calls that started on this date. Specify a date as `YYYY-MM-DD` in GMT, for example: `2009-07-06`, to read only calls that started on this date. You can also specify an inequality, such as `StartTime<=YYYY-MM-DD`, to read calls that started on or before midnight of this date, and `StartTime>=YYYY-MM-DD` to read calls that started on or after midnight of this date. (format: date-time) (spec name: StartTime<)
  --qp-start-time-2: string # Only include calls that started on this date. Specify a date as `YYYY-MM-DD` in GMT, for example: `2009-07-06`, to read only calls that started on this date. You can also specify an inequality, such as `StartTime<=YYYY-MM-DD`, to read calls that started on or before midnight of this date, and `StartTime>=YYYY-MM-DD` to read calls that started on or after midnight of this date. (format: date-time) (spec name: StartTime>)
  --end-time: string # Only include calls that ended on this date. Specify a date as `YYYY-MM-DD` in GMT, for example: `2009-07-06`, to read only calls that ended on this date. You can also specify an inequality, such as `EndTime<=YYYY-MM-DD`, to read calls that ended on or before midnight of this date, and `EndTime>=YYYY-MM-DD` to read calls that ended on or after midnight of this date. (format: date-time)
  --qp-end-time: string # Only include calls that ended on this date. Specify a date as `YYYY-MM-DD` in GMT, for example: `2009-07-06`, to read only calls that ended on this date. You can also specify an inequality, such as `EndTime<=YYYY-MM-DD`, to read calls that ended on or before midnight of this date, and `EndTime>=YYYY-MM-DD` to read calls that ended on or after midnight of this date. (format: date-time) (spec name: EndTime<)
  --qp-end-time-2: string # Only include calls that ended on this date. Specify a date as `YYYY-MM-DD` in GMT, for example: `2009-07-06`, to read only calls that ended on this date. You can also specify an inequality, such as `EndTime<=YYYY-MM-DD`, to read calls that ended on or before midnight of this date, and `EndTime>=YYYY-MM-DD` to read calls that ended on or after midnight of this date. (format: date-time) (spec name: EndTime>)
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2010-04-01/Accounts/{AccountSid}/Calls.json"
    path_params: [{name: AccountSid, var: account_sid}]
    query: [{name: To, var: to}, {name: From, var: from}, {name: ParentCallSid, var: parent_call_sid}, {name: Status, var: status}, {name: StartTime, var: start_time}, {name: "StartTime<", var: qp_start_time}, {name: "StartTime>", var: qp_start_time_2}, {name: EndTime, var: end_time}, {name: "EndTime<", var: qp_end_time}, {name: "EndTime>", var: qp_end_time_2}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, to: $to, from: $from, parent_call_sid: $parent_call_sid, status: $status, start_time: $start_time, qp_start_time: $qp_start_time, qp_start_time_2: $qp_start_time_2, end_time: $end_time, qp_end_time: $qp_end_time, qp_end_time_2: $qp_end_time_2, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new outgoing call to phones, SIP-enabled endpoints or Twilio Client connections
#
# POST /2010-04-01/Accounts/{AccountSid}/Calls.json
# Returns: record<account_sid: string, answered_by: string, api_version: string, caller_name: string, date_created: string, date_updated: string, direction: string, duration: string, end_time: string, forwarded_from: string, from: string, from_formatted: string, group_sid: string, parent_call_sid: string, phone_number_sid: string, price: string, price_unit: string, queue_time: string, sid: string, start_time: string, status: string, subresource_uris: record, to: string, to_formatted: string, trunk_sid: string, uri: string>
# operationId: CreateCall
export def "create-call" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --application-sid: string # The SID of the Application resource that will handle the call, if the call will be handled by an application.
  --async-amd: string # Select whether to perform answering machine detection in the background. Default, blocks the execution of the call until Answering Machine Detection is completed. Can be: `true` or `false`.
  --async-amd-status-callback: string # The URL that we should call using the `async_amd_status_callback_method` to notify customer application whether the call was answered by human, machine or fax. (format: uri)
  --async-amd-status-callback-method: string@async-amd-status-callback-method-completer # The HTTP method we should use when calling the `async_amd_status_callback` URL. Can be: `GET` or `POST` and the default is `POST`. (format: http-method)
  --byoc: string # The SID of a BYOC (Bring Your Own Carrier) trunk to route this call with. Note that `byoc` is only meaningful when `to` is a phone number; it will otherwise be ignored. (Beta)
  --call-reason: string # The Reason for the outgoing call. Use it to specify the purpose of the call that is presented on the called party's phone. (Branded Calls Beta)
  --call-token: string # A token string needed to invoke a forwarded call. A call_token is generated when an incoming call is received on a Twilio number. Pass an incoming call's call_token value to a forwarded call via the call_token parameter when creating a new call. A forwarded call should bear the same CallerID of the original incoming call.
  --caller-id: string # The phone number, SIP address, or Client identifier that made this call. Phone numbers are in [E.164 format](https://wwnw.twilio.com/docs/glossary/what-e164) (e.g., +16175551212). SIP addresses are formatted as `name@company.com`.
  --fallback-method: string@fallback-method-completer # The HTTP method that we should use to request the `fallback_url`. Can be: `GET` or `POST` and the default is `POST`. If an `application_sid` parameter is present, this parameter is ignored. (format: http-method)
  --fallback-url: string # The URL that we call using the `fallback_method` if an error occurs when requesting or executing the TwiML at `url`. If an `application_sid` parameter is present, this parameter is ignored. (format: uri)
  from: string # The phone number or client identifier to use as the caller id. If using a phone number, it must be a Twilio number or a Verified [outgoing caller id](https://www.twilio.com/docs/voice/api/outgoing-caller-ids) for your account. If the `to` parameter is a phone number, `From` must also be a phone number. (format: endpoint)
  --machine-detection: string # Whether to detect if a human, answering machine, or fax has picked up the call. Can be: `Enable` or `DetectMessageEnd`. Use `Enable` if you would like us to return `AnsweredBy` as soon as the called party is identified. Use `DetectMessageEnd`, if you would like to leave a message on an answering machine. If `send_digits` is provided, this parameter is ignored. For more information, see [Answering Machine Detection](https://www.twilio.com/docs/voice/answering-machine-detection).
  --machine-detection-silence-timeout: int # The number of milliseconds of initial silence after which an `unknown` AnsweredBy result will be returned. Possible Values: 2000-10000. Default: 5000.
  --machine-detection-speech-end-threshold: int # The number of milliseconds of silence after speech activity at which point the speech activity is considered complete. Possible Values: 500-5000. Default: 1200.
  --machine-detection-speech-threshold: int # The number of milliseconds that is used as the measuring stick for the length of the speech activity, where durations lower than this value will be interpreted as a human and longer than this value as a machine. Possible Values: 1000-6000. Default: 2400.
  --machine-detection-timeout: int # The number of seconds that we should attempt to detect an answering machine before timing out and sending a voice request with `AnsweredBy` of `unknown`. The default timeout is 30 seconds.
  --method: string@method-completer # The HTTP method we should use when calling the `url` parameter's value. Can be: `GET` or `POST` and the default is `POST`. If an `application_sid` parameter is present, this parameter is ignored. (format: http-method)
  --record: oneof<nothing, bool> # Whether to record the call. Can be `true` to record the phone call, or `false` to not. The default is `false`. The `recording_url` is sent to the `status_callback` URL.
  --recording-channels: string # The number of channels in the final recording. Can be: `mono` or `dual`. The default is `mono`. `mono` records both legs of the call in a single channel of the recording file. `dual` records each leg to a separate channel of the recording file. The first channel of a dual-channel recording contains the parent call and the second channel contains the child call.
  --recording-status-callback: string # The URL that we call when the recording is available to be accessed.
  --recording-status-callback-event: list<string> # The recording status events that will trigger calls to the URL specified in `recording_status_callback`. Can be: `in-progress`, `completed` and `absent`. Defaults to `completed`. Separate multiple values with a space.
  --recording-status-callback-method: string@recording-status-callback-method-completer # The HTTP method we should use when calling the `recording_status_callback` URL. Can be: `GET` or `POST` and the default is `POST`. (format: http-method)
  --recording-track: string # The audio track to record for the call. Can be: `inbound`, `outbound` or `both`. The default is `both`. `inbound` records the audio that is received by Twilio. `outbound` records the audio that is generated from Twilio. `both` records the audio that is received and generated by Twilio.
  --send-digits: string # A string of keys to dial after connecting to the number, maximum of 32 digits. Valid digits in the string include: any digit (`0`-`9`), '`#`', '`*`' and '`w`', to insert a half second pause. For example, if you connected to a company phone number and wanted to pause for one second, and then dial extension 1234 followed by the pound key, the value of this parameter would be `ww1234#`. Remember to URL-encode this string, since the '`#`' character has special meaning in a URL. If both `SendDigits` and `MachineDetection` parameters are provided, then `MachineDetection` will be ignored.
  --sip-auth-password: string # The password required to authenticate the user account specified in `sip_auth_username`.
  --sip-auth-username: string # The username used to authenticate the caller making a SIP call.
  --status-callback: string # The URL we should call using the `status_callback_method` to send status information to your application. If no `status_callback_event` is specified, we will send the `completed` status. If an `application_sid` parameter is present, this parameter is ignored. URLs must contain a valid hostname (underscores are not permitted). (format: uri)
  --status-callback-event: list<string> # The call progress events that we will send to the `status_callback` URL. Can be: `initiated`, `ringing`, `answered`, and `completed`. If no event is specified, we send the `completed` status. If you want to receive multiple events, specify each one in a separate `status_callback_event` parameter. See the code sample for [monitoring call progress](https://www.twilio.com/docs/voice/api/call-resource?code-sample=code-create-a-call-resource-and-specify-a-statuscallbackevent&code-sdk-version=json). If an `application_sid` is present, this parameter is ignored.
  --status-callback-method: string@status-callback-method-completer # The HTTP method we should use when calling the `status_callback` URL. Can be: `GET` or `POST` and the default is `POST`. If an `application_sid` parameter is present, this parameter is ignored. (format: http-method)
  --time-limit: int # The maximum duration of the call in seconds. Constraints depend on account and configuration.
  --timeout: int # The integer number of seconds that we should allow the phone to ring before assuming there is no answer. The default is `60` seconds and the maximum is `600` seconds. For some call flows, we will add a 5-second buffer to the timeout value you provide. For this reason, a timeout value of 10 seconds could result in an actual timeout closer to 15 seconds. You can set this to a short time, such as `15` seconds, to hang up before reaching an answering machine or voicemail.
  to: string # The phone number, SIP address, or client identifier to call. (format: endpoint)
  --trim: string # Whether to trim any leading and trailing silence from the recording. Can be: `trim-silence` or `do-not-trim` and the default is `trim-silence`.
  --twiml: string # TwiML instructions for the call Twilio will use without fetching Twiml from url parameter. If both `twiml` and `url` are provided then `twiml` parameter will be ignored. Max 4000 characters. (format: twiml)
  --url: string # The absolute URL that returns the TwiML instructions for the call. We will call this URL using the `method` when the call connects. For more information, see the [Url Parameter](https://www.twilio.com/docs/voice/make-calls#specify-a-url-parameter) section in [Making Calls](https://www.twilio.com/docs/voice/make-calls). (format: uri)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2010-04-01/Accounts/{AccountSid}/Calls.json"
    path_params: [{name: AccountSid, var: account_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: ApplicationSid, var: application_sid}, {name: AsyncAmd, var: async_amd}, {name: AsyncAmdStatusCallback, var: async_amd_status_callback}, {name: AsyncAmdStatusCallbackMethod, var: async_amd_status_callback_method}, {name: Byoc, var: byoc}, {name: CallReason, var: call_reason}, {name: CallToken, var: call_token}, {name: CallerId, var: caller_id}, {name: FallbackMethod, var: fallback_method}, {name: FallbackUrl, var: fallback_url}, {name: From, var: from}, {name: MachineDetection, var: machine_detection}, {name: MachineDetectionSilenceTimeout, var: machine_detection_silence_timeout}, {name: MachineDetectionSpeechEndThreshold, var: machine_detection_speech_end_threshold}, {name: MachineDetectionSpeechThreshold, var: machine_detection_speech_threshold}, {name: MachineDetectionTimeout, var: machine_detection_timeout}, {name: Method, var: method}, {name: Record, var: record}, {name: RecordingChannels, var: recording_channels}, {name: RecordingStatusCallback, var: recording_status_callback}, {name: RecordingStatusCallbackEvent, var: recording_status_callback_event}, {name: RecordingStatusCallbackMethod, var: recording_status_callback_method}, {name: RecordingTrack, var: recording_track}, {name: SendDigits, var: send_digits}, {name: SipAuthPassword, var: sip_auth_password}, {name: SipAuthUsername, var: sip_auth_username}, {name: StatusCallback, var: status_callback}, {name: StatusCallbackEvent, var: status_callback_event}, {name: StatusCallbackMethod, var: status_callback_method}, {name: TimeLimit, var: time_limit}, {name: Timeout, var: timeout}, {name: To, var: to}, {name: Trim, var: trim}, {name: Twiml, var: twiml}, {name: Url, var: url}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, application_sid: $application_sid, async_amd: $async_amd, async_amd_status_callback: $async_amd_status_callback, async_amd_status_callback_method: $async_amd_status_callback_method, byoc: $byoc, call_reason: $call_reason, call_token: $call_token, caller_id: $caller_id, fallback_method: $fallback_method, fallback_url: $fallback_url, from: $from, machine_detection: $machine_detection, machine_detection_silence_timeout: $machine_detection_silence_timeout, machine_detection_speech_end_threshold: $machine_detection_speech_end_threshold, machine_detection_speech_threshold: $machine_detection_speech_threshold, machine_detection_timeout: $machine_detection_timeout, method: $method, record: $record, recording_channels: $recording_channels, recording_status_callback: $recording_status_callback, recording_status_callback_event: $recording_status_callback_event, recording_status_callback_method: $recording_status_callback_method, recording_track: $recording_track, send_digits: $send_digits, sip_auth_password: $sip_auth_password, sip_auth_username: $sip_auth_username, status_callback: $status_callback, status_callback_event: $status_callback_event, status_callback_method: $status_callback_method, time_limit: $time_limit, timeout: $timeout, to: $to, trim: $trim, twiml: $twiml, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a FeedbackSummary resource for a call
#
# POST /2010-04-01/Accounts/{AccountSid}/Calls/FeedbackSummary.json
# Returns: record<account_sid: string, call_count: int, call_feedback_count: int, date_created: string, date_updated: string, end_date: string, include_subaccounts: bool, issues: list<any>, quality_score_average: float, quality_score_median: float, quality_score_standard_deviation: float, sid: string, start_date: string, status: string>
# operationId: CreateCallFeedbackSummary
export def "create-call-feedback-summary" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  end_date: string # Only include feedback given on or before this date. Format is `YYYY-MM-DD` and specified in UTC. (format: date)
  --include-subaccounts: oneof<nothing, bool> # Whether to also include Feedback resources from all subaccounts. `true` includes feedback from all subaccounts and `false`, the default, includes feedback from only the specified account.
  start_date: string # Only include feedback given on or after this date. Format is `YYYY-MM-DD` and specified in UTC. (format: date)
  --status-callback: string # The URL that we will request when the feedback summary is complete. (format: uri)
  --status-callback-method: string@status-callback-method-completer # The HTTP method (`GET` or `POST`) we use to make the request to the `StatusCallback` URL. (format: http-method)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2010-04-01/Accounts/{AccountSid}/Calls/FeedbackSummary.json"
    path_params: [{name: AccountSid, var: account_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: EndDate, var: end_date}, {name: IncludeSubaccounts, var: include_subaccounts}, {name: StartDate, var: start_date}, {name: StatusCallback, var: status_callback}, {name: StatusCallbackMethod, var: status_callback_method}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, end_date: $end_date, include_subaccounts: $include_subaccounts, start_date: $start_date, status_callback: $status_callback, status_callback_method: $status_callback_method
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a FeedbackSummary resource from a call
#
# DELETE /2010-04-01/Accounts/{AccountSid}/Calls/FeedbackSummary/{Sid}.json
# operationId: DeleteCallFeedbackSummary
export def "delete-call-feedback-summary" [
  account_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/Calls/FeedbackSummary/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a FeedbackSummary resource from a call
#
# GET /2010-04-01/Accounts/{AccountSid}/Calls/FeedbackSummary/{Sid}.json
# Returns: record<account_sid: string, call_count: int, call_feedback_count: int, date_created: string, date_updated: string, end_date: string, include_subaccounts: bool, issues: list<any>, quality_score_average: float, quality_score_median: float, quality_score_standard_deviation: float, sid: string, start_date: string, status: string>
# operationId: FetchCallFeedbackSummary
export def "fetch-call-feedback-summary" [
  account_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/Calls/FeedbackSummary/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of all events for a call.
#
# GET /2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/Events.json
# Returns: record<end: int, events: table<request: any, response: any>, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>
# operationId: ListCallEvent
export def "list-call-event" [
  account_sid: string
  call_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/Events.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: CallSid, var: call_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, call_sid: $call_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a Feedback resource from a call
#
# GET /2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/Feedback.json
# Returns: record<account_sid: string, date_created: string, date_updated: string, issues: list<string>, quality_score: int, sid: string>
# operationId: FetchCallFeedback
export def "fetch-call-feedback" [
  account_sid: string
  call_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/Feedback.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: CallSid, var: call_sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, call_sid: $call_sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a Feedback resource for a call
#
# POST /2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/Feedback.json
# Returns: record<account_sid: string, date_created: string, date_updated: string, issues: list<string>, quality_score: int, sid: string>
# operationId: UpdateCallFeedback
export def "update-call-feedback" [
  account_sid: string
  call_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --issue: list<string> # One or more issues experienced during the call. The issues can be: `imperfect-audio`, `dropped-call`, `incorrect-caller-id`, `post-dial-delay`, `digits-not-captured`, `audio-latency`, `unsolicited-call`, or `one-way-audio`.
  --quality-score: int # The call quality expressed as an integer from `1` to `5` where `1` represents very poor call quality and `5` represents a perfect call.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/Feedback.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: CallSid, var: call_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Issue, var: issue}, {name: QualityScore, var: quality_score}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, call_sid: $call_sid, issue: $issue, quality_score: $quality_score
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/Notifications.json
#
# Returns: record<end: int, first_page_uri: string, next_page_uri: string, notifications: table<account_sid: string, api_version: string, call_sid: string, date_created: string, date_updated: string, error_code: string, log: string, message_date: string, message_text: string, more_info: string, request_method: string, request_url: string, sid: string, uri: string>, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>
# operationId: ListCallNotification
export def "list-call-notification" [
  account_sid: string
  call_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --log: int # Only read notifications of the specified log level. Can be: `0` to read only ERROR notifications or `1` to read only WARNING notifications. By default, all notifications are read.
  --message-date: string # Only show notifications for the specified date, formatted as `YYYY-MM-DD`. You can also specify an inequality, such as `<=YYYY-MM-DD` for messages logged at or before midnight on a date, or `>=YYYY-MM-DD` for messages logged at or after midnight on a date. (format: date)
  --qp-message-date: string # Only show notifications for the specified date, formatted as `YYYY-MM-DD`. You can also specify an inequality, such as `<=YYYY-MM-DD` for messages logged at or before midnight on a date, or `>=YYYY-MM-DD` for messages logged at or after midnight on a date. (format: date) (spec name: MessageDate<)
  --qp-message-date-2: string # Only show notifications for the specified date, formatted as `YYYY-MM-DD`. You can also specify an inequality, such as `<=YYYY-MM-DD` for messages logged at or before midnight on a date, or `>=YYYY-MM-DD` for messages logged at or after midnight on a date. (format: date) (spec name: MessageDate>)
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/Notifications.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: CallSid, var: call_sid}]
    query: [{name: Log, var: log}, {name: MessageDate, var: message_date}, {name: "MessageDate<", var: qp_message_date}, {name: "MessageDate>", var: qp_message_date_2}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, call_sid: $call_sid, log: $log, message_date: $message_date, qp_message_date: $qp_message_date, qp_message_date_2: $qp_message_date_2, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/Notifications/{Sid}.json
#
# Returns: record<account_sid: string, api_version: string, call_sid: string, date_created: string, date_updated: string, error_code: string, log: string, message_date: string, message_text: string, more_info: string, request_method: string, request_url: string, request_variables: string, response_body: string, response_headers: string, sid: string, uri: string>
# operationId: FetchCallNotification
export def "fetch-call-notification" [
  account_sid: string
  call_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/Notifications/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: CallSid, var: call_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, call_sid: $call_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# create an instance of payments. This will start a new payments session
#
# POST /2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/Payments.json
# Returns: record<account_sid: string, call_sid: string, date_created: string, date_updated: string, sid: string, uri: string>
# operationId: CreatePayments
export def "create-payments" [
  account_sid: string
  call_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --bank-account-type: string@bank-account-type-completer
  --charge-amount: float # A positive decimal value less than 1,000,000 to charge against the credit card or bank account. Default currency can be overwritten with `currency` field. Leave blank or set to 0 to tokenize.
  --currency: string # The currency of the `charge_amount`, formatted as [ISO 4127](http://www.iso.org/iso/home/standards/currency_codes.htm) format. The default value is `USD` and all values allowed from the Pay Connector are accepted.
  --description: string # The description can be used to provide more details regarding the transaction. This information is submitted along with the payment details to the Payment Connector which are then posted on the transactions.
  idempotency_key: string # A unique token that will be used to ensure that multiple API calls with the same information do not result in multiple transactions. This should be a unique string value per API call and can be a randomly generated.
  --input: string # A list of inputs that should be accepted. Currently only `dtmf` is supported. All digits captured during a pay session are redacted from the logs.
  --min-postal-code-length: int # A positive integer that is used to validate the length of the `PostalCode` inputted by the user. User must enter this many digits.
  --parameter: any # A single-level JSON object used to pass custom parameters to payment processors. (Required for ACH payments). The information that has to be included here depends on the Connector. [Read more](https://www.twilio.com/console/voice/pay-connectors).
  --payment-connector: string # This is the unique name corresponding to the Pay Connector installed in the Twilio Add-ons. Learn more about [ Connectors](https://www.twilio.com/console/voice/pay-connectors). The default value is `Default`.
  --payment-method: string@payment-method-completer
  --postal-code: oneof<nothing, bool> # Indicates whether the credit card postal code (zip code) is a required piece of payment information that must be provided by the caller. The default is `true`.
  --security-code: oneof<nothing, bool> # Indicates whether the credit card security code is a required piece of payment information that must be provided by the caller. The default is `true`.
  status_callback: string # Provide an absolute or relative URL to receive status updates regarding your Pay session. Read more about the [expected StatusCallback values](https://www.twilio.com/docs/voice/api/payment-resource#statuscallback) (format: uri)
  --timeout: int # The number of seconds that should wait for the caller to press a digit between each subsequent digit, after the first one, before moving on to validate the digits captured. The default is `5`, maximum is `600`.
  --token-type: string@token-type-completer
  --valid-card-types: string # Credit card types separated by space that Pay should accept. The default value is `visa mastercard amex`
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/Payments.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: CallSid, var: call_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: BankAccountType, var: bank_account_type}, {name: ChargeAmount, var: charge_amount}, {name: Currency, var: currency}, {name: Description, var: description}, {name: IdempotencyKey, var: idempotency_key}, {name: Input, var: input}, {name: MinPostalCodeLength, var: min_postal_code_length}, {name: Parameter, var: parameter}, {name: PaymentConnector, var: payment_connector}, {name: PaymentMethod, var: payment_method}, {name: PostalCode, var: postal_code}, {name: SecurityCode, var: security_code}, {name: StatusCallback, var: status_callback}, {name: Timeout, var: timeout}, {name: TokenType, var: token_type}, {name: ValidCardTypes, var: valid_card_types}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, call_sid: $call_sid, bank_account_type: $bank_account_type, charge_amount: $charge_amount, currency: $currency, description: $description, idempotency_key: $idempotency_key, input: $input, min_postal_code_length: $min_postal_code_length, parameter: $parameter, payment_connector: $payment_connector, payment_method: $payment_method, postal_code: $postal_code, security_code: $security_code, status_callback: $status_callback, timeout: $timeout, token_type: $token_type, valid_card_types: $valid_card_types
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# update an instance of payments with different phases of payment flows.
#
# POST /2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/Payments/{Sid}.json
# Returns: record<account_sid: string, call_sid: string, date_created: string, date_updated: string, sid: string, uri: string>
# operationId: UpdatePayments
export def "update-payments" [
  account_sid: string
  call_sid: string
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
  --capture: string@capture-completer
  idempotency_key: string # A unique token that will be used to ensure that multiple API calls with the same information do not result in multiple transactions. This should be a unique string value per API call and can be a randomly generated.
  --status: string@status-completer-2
  status_callback: string # Provide an absolute or relative URL to receive status updates regarding your Pay session. Read more about the [Update](https://www.twilio.com/docs/voice/api/payment-resource#statuscallback-update) and [Complete/Cancel](https://www.twilio.com/docs/voice/api/payment-resource#statuscallback-cancelcomplete) POST requests. (format: uri)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/Payments/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: CallSid, var: call_sid}, {name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Capture, var: capture}, {name: IdempotencyKey, var: idempotency_key}, {name: Status, var: status}, {name: StatusCallback, var: status_callback}]}
    accept: ["application/json"]
    ok: [202]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, call_sid: $call_sid, sid: $sid, capture: $capture, idempotency_key: $idempotency_key, status: $status, status_callback: $status_callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of recordings belonging to the call used to make the request
#
# GET /2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/Recordings.json
# Returns: record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, recordings: table<account_sid: string, api_version: string, call_sid: string, channels: int, conference_sid: string, date_created: string, date_updated: string, duration: string, encryption_details: any, error_code: int, price: float, price_unit: string, sid: string, source: string, start_time: string, status: string, track: string, uri: string>, start: int, uri: string>
# operationId: ListCallRecording
export def "list-call-recording" [
  account_sid: string
  call_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-created: string # The `date_created` value, specified as `YYYY-MM-DD`, of the resources to read. You can also specify inequality: `DateCreated<=YYYY-MM-DD` will return recordings generated at or before midnight on a given date, and `DateCreated>=YYYY-MM-DD` returns recordings generated at or after midnight on a date. (format: date)
  --qp-date-created: string # The `date_created` value, specified as `YYYY-MM-DD`, of the resources to read. You can also specify inequality: `DateCreated<=YYYY-MM-DD` will return recordings generated at or before midnight on a given date, and `DateCreated>=YYYY-MM-DD` returns recordings generated at or after midnight on a date. (format: date) (spec name: DateCreated<)
  --qp-date-created-2: string # The `date_created` value, specified as `YYYY-MM-DD`, of the resources to read. You can also specify inequality: `DateCreated<=YYYY-MM-DD` will return recordings generated at or before midnight on a given date, and `DateCreated>=YYYY-MM-DD` returns recordings generated at or after midnight on a date. (format: date) (spec name: DateCreated>)
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/Recordings.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: CallSid, var: call_sid}]
    query: [{name: DateCreated, var: date_created}, {name: "DateCreated<", var: qp_date_created}, {name: "DateCreated>", var: qp_date_created_2}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, call_sid: $call_sid, date_created: $date_created, qp_date_created: $qp_date_created, qp_date_created_2: $qp_date_created_2, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a recording for the call
#
# POST /2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/Recordings.json
# Returns: record<account_sid: string, api_version: string, call_sid: string, channels: int, conference_sid: string, date_created: string, date_updated: string, duration: string, encryption_details: any, error_code: int, price: float, price_unit: string, sid: string, source: string, start_time: string, status: string, track: string, uri: string>
# operationId: CreateCallRecording
export def "create-call-recording" [
  account_sid: string
  call_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --recording-channels: string # The number of channels used in the recording. Can be: `mono` or `dual` and the default is `mono`. `mono` records all parties of the call into one channel. `dual` records each party of a 2-party call into separate channels.
  --recording-status-callback: string # The URL we should call using the `recording_status_callback_method` on each recording event specified in `recording_status_callback_event`. For more information, see [RecordingStatusCallback parameters](https://www.twilio.com/docs/voice/api/recording#recordingstatuscallback). (format: uri)
  --recording-status-callback-event: list<string> # The recording status events on which we should call the `recording_status_callback` URL. Can be: `in-progress`, `completed` and `absent` and the default is `completed`. Separate multiple event values with a space.
  --recording-status-callback-method: string@recording-status-callback-method-completer # The HTTP method we should use to call `recording_status_callback`. Can be: `GET` or `POST` and the default is `POST`. (format: http-method)
  --recording-track: string # The audio track to record for the call. Can be: `inbound`, `outbound` or `both`. The default is `both`. `inbound` records the audio that is received by Twilio. `outbound` records the audio that is generated from Twilio. `both` records the audio that is received and generated by Twilio.
  --trim: string # Whether to trim any leading and trailing silence in the recording. Can be: `trim-silence` or `do-not-trim` and the default is `do-not-trim`. `trim-silence` trims the silence from the beginning and end of the recording and `do-not-trim` does not.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/Recordings.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: CallSid, var: call_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: RecordingChannels, var: recording_channels}, {name: RecordingStatusCallback, var: recording_status_callback}, {name: RecordingStatusCallbackEvent, var: recording_status_callback_event}, {name: RecordingStatusCallbackMethod, var: recording_status_callback_method}, {name: RecordingTrack, var: recording_track}, {name: Trim, var: trim}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, call_sid: $call_sid, recording_channels: $recording_channels, recording_status_callback: $recording_status_callback, recording_status_callback_event: $recording_status_callback_event, recording_status_callback_method: $recording_status_callback_method, recording_track: $recording_track, trim: $trim
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a recording from your account
#
# DELETE /2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/Recordings/{Sid}.json
# operationId: DeleteCallRecording
export def "delete-call-recording" [
  account_sid: string
  call_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/Recordings/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: CallSid, var: call_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, call_sid: $call_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch an instance of a recording for a call
#
# GET /2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/Recordings/{Sid}.json
# Returns: record<account_sid: string, api_version: string, call_sid: string, channels: int, conference_sid: string, date_created: string, date_updated: string, duration: string, encryption_details: any, error_code: int, price: float, price_unit: string, sid: string, source: string, start_time: string, status: string, track: string, uri: string>
# operationId: FetchCallRecording
export def "fetch-call-recording" [
  account_sid: string
  call_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/Recordings/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: CallSid, var: call_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, call_sid: $call_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Changes the status of the recording to paused, stopped, or in-progress. Note: Pass `Twilio.CURRENT` instead of recording sid to reference current active recording.
#
# POST /2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/Recordings/{Sid}.json
# Returns: record<account_sid: string, api_version: string, call_sid: string, channels: int, conference_sid: string, date_created: string, date_updated: string, duration: string, encryption_details: any, error_code: int, price: float, price_unit: string, sid: string, source: string, start_time: string, status: string, track: string, uri: string>
# operationId: UpdateCallRecording
export def "update-call-recording" [
  account_sid: string
  call_sid: string
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
  --pause-behavior: string # Whether to record during a pause. Can be: `skip` or `silence` and the default is `silence`. `skip` does not record during the pause period, while `silence` will replace the actual audio of the call with silence during the pause period. This parameter only applies when setting `status` is set to `paused`.
  status: string@status-completer-3
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/Recordings/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: CallSid, var: call_sid}, {name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: PauseBehavior, var: pause_behavior}, {name: Status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, call_sid: $call_sid, sid: $sid, pause_behavior: $pause_behavior, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a Siprec
#
# POST /2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/Siprec.json
# Returns: record<account_sid: string, call_sid: string, date_updated: string, name: string, sid: string, status: string, uri: string>
# operationId: CreateSiprec
export def "create-siprec" [
  account_sid: string
  call_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --connector-name: string # Unique name used when configuring the connector via Marketplace Add-on.
  --name: string # The user-specified name of this Siprec, if one was given when the Siprec was created. This may be used to stop the Siprec.
  --parameter1-name: string # Parameter name
  --parameter1-value: string # Parameter value
  --parameter10-name: string # Parameter name
  --parameter10-value: string # Parameter value
  --parameter11-name: string # Parameter name
  --parameter11-value: string # Parameter value
  --parameter12-name: string # Parameter name
  --parameter12-value: string # Parameter value
  --parameter13-name: string # Parameter name
  --parameter13-value: string # Parameter value
  --parameter14-name: string # Parameter name
  --parameter14-value: string # Parameter value
  --parameter15-name: string # Parameter name
  --parameter15-value: string # Parameter value
  --parameter16-name: string # Parameter name
  --parameter16-value: string # Parameter value
  --parameter17-name: string # Parameter name
  --parameter17-value: string # Parameter value
  --parameter18-name: string # Parameter name
  --parameter18-value: string # Parameter value
  --parameter19-name: string # Parameter name
  --parameter19-value: string # Parameter value
  --parameter2-name: string # Parameter name
  --parameter2-value: string # Parameter value
  --parameter20-name: string # Parameter name
  --parameter20-value: string # Parameter value
  --parameter21-name: string # Parameter name
  --parameter21-value: string # Parameter value
  --parameter22-name: string # Parameter name
  --parameter22-value: string # Parameter value
  --parameter23-name: string # Parameter name
  --parameter23-value: string # Parameter value
  --parameter24-name: string # Parameter name
  --parameter24-value: string # Parameter value
  --parameter25-name: string # Parameter name
  --parameter25-value: string # Parameter value
  --parameter26-name: string # Parameter name
  --parameter26-value: string # Parameter value
  --parameter27-name: string # Parameter name
  --parameter27-value: string # Parameter value
  --parameter28-name: string # Parameter name
  --parameter28-value: string # Parameter value
  --parameter29-name: string # Parameter name
  --parameter29-value: string # Parameter value
  --parameter3-name: string # Parameter name
  --parameter3-value: string # Parameter value
  --parameter30-name: string # Parameter name
  --parameter30-value: string # Parameter value
  --parameter31-name: string # Parameter name
  --parameter31-value: string # Parameter value
  --parameter32-name: string # Parameter name
  --parameter32-value: string # Parameter value
  --parameter33-name: string # Parameter name
  --parameter33-value: string # Parameter value
  --parameter34-name: string # Parameter name
  --parameter34-value: string # Parameter value
  --parameter35-name: string # Parameter name
  --parameter35-value: string # Parameter value
  --parameter36-name: string # Parameter name
  --parameter36-value: string # Parameter value
  --parameter37-name: string # Parameter name
  --parameter37-value: string # Parameter value
  --parameter38-name: string # Parameter name
  --parameter38-value: string # Parameter value
  --parameter39-name: string # Parameter name
  --parameter39-value: string # Parameter value
  --parameter4-name: string # Parameter name
  --parameter4-value: string # Parameter value
  --parameter40-name: string # Parameter name
  --parameter40-value: string # Parameter value
  --parameter41-name: string # Parameter name
  --parameter41-value: string # Parameter value
  --parameter42-name: string # Parameter name
  --parameter42-value: string # Parameter value
  --parameter43-name: string # Parameter name
  --parameter43-value: string # Parameter value
  --parameter44-name: string # Parameter name
  --parameter44-value: string # Parameter value
  --parameter45-name: string # Parameter name
  --parameter45-value: string # Parameter value
  --parameter46-name: string # Parameter name
  --parameter46-value: string # Parameter value
  --parameter47-name: string # Parameter name
  --parameter47-value: string # Parameter value
  --parameter48-name: string # Parameter name
  --parameter48-value: string # Parameter value
  --parameter49-name: string # Parameter name
  --parameter49-value: string # Parameter value
  --parameter5-name: string # Parameter name
  --parameter5-value: string # Parameter value
  --parameter50-name: string # Parameter name
  --parameter50-value: string # Parameter value
  --parameter51-name: string # Parameter name
  --parameter51-value: string # Parameter value
  --parameter52-name: string # Parameter name
  --parameter52-value: string # Parameter value
  --parameter53-name: string # Parameter name
  --parameter53-value: string # Parameter value
  --parameter54-name: string # Parameter name
  --parameter54-value: string # Parameter value
  --parameter55-name: string # Parameter name
  --parameter55-value: string # Parameter value
  --parameter56-name: string # Parameter name
  --parameter56-value: string # Parameter value
  --parameter57-name: string # Parameter name
  --parameter57-value: string # Parameter value
  --parameter58-name: string # Parameter name
  --parameter58-value: string # Parameter value
  --parameter59-name: string # Parameter name
  --parameter59-value: string # Parameter value
  --parameter6-name: string # Parameter name
  --parameter6-value: string # Parameter value
  --parameter60-name: string # Parameter name
  --parameter60-value: string # Parameter value
  --parameter61-name: string # Parameter name
  --parameter61-value: string # Parameter value
  --parameter62-name: string # Parameter name
  --parameter62-value: string # Parameter value
  --parameter63-name: string # Parameter name
  --parameter63-value: string # Parameter value
  --parameter64-name: string # Parameter name
  --parameter64-value: string # Parameter value
  --parameter65-name: string # Parameter name
  --parameter65-value: string # Parameter value
  --parameter66-name: string # Parameter name
  --parameter66-value: string # Parameter value
  --parameter67-name: string # Parameter name
  --parameter67-value: string # Parameter value
  --parameter68-name: string # Parameter name
  --parameter68-value: string # Parameter value
  --parameter69-name: string # Parameter name
  --parameter69-value: string # Parameter value
  --parameter7-name: string # Parameter name
  --parameter7-value: string # Parameter value
  --parameter70-name: string # Parameter name
  --parameter70-value: string # Parameter value
  --parameter71-name: string # Parameter name
  --parameter71-value: string # Parameter value
  --parameter72-name: string # Parameter name
  --parameter72-value: string # Parameter value
  --parameter73-name: string # Parameter name
  --parameter73-value: string # Parameter value
  --parameter74-name: string # Parameter name
  --parameter74-value: string # Parameter value
  --parameter75-name: string # Parameter name
  --parameter75-value: string # Parameter value
  --parameter76-name: string # Parameter name
  --parameter76-value: string # Parameter value
  --parameter77-name: string # Parameter name
  --parameter77-value: string # Parameter value
  --parameter78-name: string # Parameter name
  --parameter78-value: string # Parameter value
  --parameter79-name: string # Parameter name
  --parameter79-value: string # Parameter value
  --parameter8-name: string # Parameter name
  --parameter8-value: string # Parameter value
  --parameter80-name: string # Parameter name
  --parameter80-value: string # Parameter value
  --parameter81-name: string # Parameter name
  --parameter81-value: string # Parameter value
  --parameter82-name: string # Parameter name
  --parameter82-value: string # Parameter value
  --parameter83-name: string # Parameter name
  --parameter83-value: string # Parameter value
  --parameter84-name: string # Parameter name
  --parameter84-value: string # Parameter value
  --parameter85-name: string # Parameter name
  --parameter85-value: string # Parameter value
  --parameter86-name: string # Parameter name
  --parameter86-value: string # Parameter value
  --parameter87-name: string # Parameter name
  --parameter87-value: string # Parameter value
  --parameter88-name: string # Parameter name
  --parameter88-value: string # Parameter value
  --parameter89-name: string # Parameter name
  --parameter89-value: string # Parameter value
  --parameter9-name: string # Parameter name
  --parameter9-value: string # Parameter value
  --parameter90-name: string # Parameter name
  --parameter90-value: string # Parameter value
  --parameter91-name: string # Parameter name
  --parameter91-value: string # Parameter value
  --parameter92-name: string # Parameter name
  --parameter92-value: string # Parameter value
  --parameter93-name: string # Parameter name
  --parameter93-value: string # Parameter value
  --parameter94-name: string # Parameter name
  --parameter94-value: string # Parameter value
  --parameter95-name: string # Parameter name
  --parameter95-value: string # Parameter value
  --parameter96-name: string # Parameter name
  --parameter96-value: string # Parameter value
  --parameter97-name: string # Parameter name
  --parameter97-value: string # Parameter value
  --parameter98-name: string # Parameter name
  --parameter98-value: string # Parameter value
  --parameter99-name: string # Parameter name
  --parameter99-value: string # Parameter value
  --status-callback: string # Absolute URL of the status callback. (format: uri)
  --status-callback-method: string@status-callback-method-completer # The http method for the status_callback (one of GET, POST). (format: http-method)
  --track: string@track-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/Siprec.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: CallSid, var: call_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: ConnectorName, var: connector_name}, {name: Name, var: name}, {name: "Parameter1.Name", var: parameter1_name}, {name: "Parameter1.Value", var: parameter1_value}, {name: "Parameter10.Name", var: parameter10_name}, {name: "Parameter10.Value", var: parameter10_value}, {name: "Parameter11.Name", var: parameter11_name}, {name: "Parameter11.Value", var: parameter11_value}, {name: "Parameter12.Name", var: parameter12_name}, {name: "Parameter12.Value", var: parameter12_value}, {name: "Parameter13.Name", var: parameter13_name}, {name: "Parameter13.Value", var: parameter13_value}, {name: "Parameter14.Name", var: parameter14_name}, {name: "Parameter14.Value", var: parameter14_value}, {name: "Parameter15.Name", var: parameter15_name}, {name: "Parameter15.Value", var: parameter15_value}, {name: "Parameter16.Name", var: parameter16_name}, {name: "Parameter16.Value", var: parameter16_value}, {name: "Parameter17.Name", var: parameter17_name}, {name: "Parameter17.Value", var: parameter17_value}, {name: "Parameter18.Name", var: parameter18_name}, {name: "Parameter18.Value", var: parameter18_value}, {name: "Parameter19.Name", var: parameter19_name}, {name: "Parameter19.Value", var: parameter19_value}, {name: "Parameter2.Name", var: parameter2_name}, {name: "Parameter2.Value", var: parameter2_value}, {name: "Parameter20.Name", var: parameter20_name}, {name: "Parameter20.Value", var: parameter20_value}, {name: "Parameter21.Name", var: parameter21_name}, {name: "Parameter21.Value", var: parameter21_value}, {name: "Parameter22.Name", var: parameter22_name}, {name: "Parameter22.Value", var: parameter22_value}, {name: "Parameter23.Name", var: parameter23_name}, {name: "Parameter23.Value", var: parameter23_value}, {name: "Parameter24.Name", var: parameter24_name}, {name: "Parameter24.Value", var: parameter24_value}, {name: "Parameter25.Name", var: parameter25_name}, {name: "Parameter25.Value", var: parameter25_value}, {name: "Parameter26.Name", var: parameter26_name}, {name: "Parameter26.Value", var: parameter26_value}, {name: "Parameter27.Name", var: parameter27_name}, {name: "Parameter27.Value", var: parameter27_value}, {name: "Parameter28.Name", var: parameter28_name}, {name: "Parameter28.Value", var: parameter28_value}, {name: "Parameter29.Name", var: parameter29_name}, {name: "Parameter29.Value", var: parameter29_value}, {name: "Parameter3.Name", var: parameter3_name}, {name: "Parameter3.Value", var: parameter3_value}, {name: "Parameter30.Name", var: parameter30_name}, {name: "Parameter30.Value", var: parameter30_value}, {name: "Parameter31.Name", var: parameter31_name}, {name: "Parameter31.Value", var: parameter31_value}, {name: "Parameter32.Name", var: parameter32_name}, {name: "Parameter32.Value", var: parameter32_value}, {name: "Parameter33.Name", var: parameter33_name}, {name: "Parameter33.Value", var: parameter33_value}, {name: "Parameter34.Name", var: parameter34_name}, {name: "Parameter34.Value", var: parameter34_value}, {name: "Parameter35.Name", var: parameter35_name}, {name: "Parameter35.Value", var: parameter35_value}, {name: "Parameter36.Name", var: parameter36_name}, {name: "Parameter36.Value", var: parameter36_value}, {name: "Parameter37.Name", var: parameter37_name}, {name: "Parameter37.Value", var: parameter37_value}, {name: "Parameter38.Name", var: parameter38_name}, {name: "Parameter38.Value", var: parameter38_value}, {name: "Parameter39.Name", var: parameter39_name}, {name: "Parameter39.Value", var: parameter39_value}, {name: "Parameter4.Name", var: parameter4_name}, {name: "Parameter4.Value", var: parameter4_value}, {name: "Parameter40.Name", var: parameter40_name}, {name: "Parameter40.Value", var: parameter40_value}, {name: "Parameter41.Name", var: parameter41_name}, {name: "Parameter41.Value", var: parameter41_value}, {name: "Parameter42.Name", var: parameter42_name}, {name: "Parameter42.Value", var: parameter42_value}, {name: "Parameter43.Name", var: parameter43_name}, {name: "Parameter43.Value", var: parameter43_value}, {name: "Parameter44.Name", var: parameter44_name}, {name: "Parameter44.Value", var: parameter44_value}, {name: "Parameter45.Name", var: parameter45_name}, {name: "Parameter45.Value", var: parameter45_value}, {name: "Parameter46.Name", var: parameter46_name}, {name: "Parameter46.Value", var: parameter46_value}, {name: "Parameter47.Name", var: parameter47_name}, {name: "Parameter47.Value", var: parameter47_value}, {name: "Parameter48.Name", var: parameter48_name}, {name: "Parameter48.Value", var: parameter48_value}, {name: "Parameter49.Name", var: parameter49_name}, {name: "Parameter49.Value", var: parameter49_value}, {name: "Parameter5.Name", var: parameter5_name}, {name: "Parameter5.Value", var: parameter5_value}, {name: "Parameter50.Name", var: parameter50_name}, {name: "Parameter50.Value", var: parameter50_value}, {name: "Parameter51.Name", var: parameter51_name}, {name: "Parameter51.Value", var: parameter51_value}, {name: "Parameter52.Name", var: parameter52_name}, {name: "Parameter52.Value", var: parameter52_value}, {name: "Parameter53.Name", var: parameter53_name}, {name: "Parameter53.Value", var: parameter53_value}, {name: "Parameter54.Name", var: parameter54_name}, {name: "Parameter54.Value", var: parameter54_value}, {name: "Parameter55.Name", var: parameter55_name}, {name: "Parameter55.Value", var: parameter55_value}, {name: "Parameter56.Name", var: parameter56_name}, {name: "Parameter56.Value", var: parameter56_value}, {name: "Parameter57.Name", var: parameter57_name}, {name: "Parameter57.Value", var: parameter57_value}, {name: "Parameter58.Name", var: parameter58_name}, {name: "Parameter58.Value", var: parameter58_value}, {name: "Parameter59.Name", var: parameter59_name}, {name: "Parameter59.Value", var: parameter59_value}, {name: "Parameter6.Name", var: parameter6_name}, {name: "Parameter6.Value", var: parameter6_value}, {name: "Parameter60.Name", var: parameter60_name}, {name: "Parameter60.Value", var: parameter60_value}, {name: "Parameter61.Name", var: parameter61_name}, {name: "Parameter61.Value", var: parameter61_value}, {name: "Parameter62.Name", var: parameter62_name}, {name: "Parameter62.Value", var: parameter62_value}, {name: "Parameter63.Name", var: parameter63_name}, {name: "Parameter63.Value", var: parameter63_value}, {name: "Parameter64.Name", var: parameter64_name}, {name: "Parameter64.Value", var: parameter64_value}, {name: "Parameter65.Name", var: parameter65_name}, {name: "Parameter65.Value", var: parameter65_value}, {name: "Parameter66.Name", var: parameter66_name}, {name: "Parameter66.Value", var: parameter66_value}, {name: "Parameter67.Name", var: parameter67_name}, {name: "Parameter67.Value", var: parameter67_value}, {name: "Parameter68.Name", var: parameter68_name}, {name: "Parameter68.Value", var: parameter68_value}, {name: "Parameter69.Name", var: parameter69_name}, {name: "Parameter69.Value", var: parameter69_value}, {name: "Parameter7.Name", var: parameter7_name}, {name: "Parameter7.Value", var: parameter7_value}, {name: "Parameter70.Name", var: parameter70_name}, {name: "Parameter70.Value", var: parameter70_value}, {name: "Parameter71.Name", var: parameter71_name}, {name: "Parameter71.Value", var: parameter71_value}, {name: "Parameter72.Name", var: parameter72_name}, {name: "Parameter72.Value", var: parameter72_value}, {name: "Parameter73.Name", var: parameter73_name}, {name: "Parameter73.Value", var: parameter73_value}, {name: "Parameter74.Name", var: parameter74_name}, {name: "Parameter74.Value", var: parameter74_value}, {name: "Parameter75.Name", var: parameter75_name}, {name: "Parameter75.Value", var: parameter75_value}, {name: "Parameter76.Name", var: parameter76_name}, {name: "Parameter76.Value", var: parameter76_value}, {name: "Parameter77.Name", var: parameter77_name}, {name: "Parameter77.Value", var: parameter77_value}, {name: "Parameter78.Name", var: parameter78_name}, {name: "Parameter78.Value", var: parameter78_value}, {name: "Parameter79.Name", var: parameter79_name}, {name: "Parameter79.Value", var: parameter79_value}, {name: "Parameter8.Name", var: parameter8_name}, {name: "Parameter8.Value", var: parameter8_value}, {name: "Parameter80.Name", var: parameter80_name}, {name: "Parameter80.Value", var: parameter80_value}, {name: "Parameter81.Name", var: parameter81_name}, {name: "Parameter81.Value", var: parameter81_value}, {name: "Parameter82.Name", var: parameter82_name}, {name: "Parameter82.Value", var: parameter82_value}, {name: "Parameter83.Name", var: parameter83_name}, {name: "Parameter83.Value", var: parameter83_value}, {name: "Parameter84.Name", var: parameter84_name}, {name: "Parameter84.Value", var: parameter84_value}, {name: "Parameter85.Name", var: parameter85_name}, {name: "Parameter85.Value", var: parameter85_value}, {name: "Parameter86.Name", var: parameter86_name}, {name: "Parameter86.Value", var: parameter86_value}, {name: "Parameter87.Name", var: parameter87_name}, {name: "Parameter87.Value", var: parameter87_value}, {name: "Parameter88.Name", var: parameter88_name}, {name: "Parameter88.Value", var: parameter88_value}, {name: "Parameter89.Name", var: parameter89_name}, {name: "Parameter89.Value", var: parameter89_value}, {name: "Parameter9.Name", var: parameter9_name}, {name: "Parameter9.Value", var: parameter9_value}, {name: "Parameter90.Name", var: parameter90_name}, {name: "Parameter90.Value", var: parameter90_value}, {name: "Parameter91.Name", var: parameter91_name}, {name: "Parameter91.Value", var: parameter91_value}, {name: "Parameter92.Name", var: parameter92_name}, {name: "Parameter92.Value", var: parameter92_value}, {name: "Parameter93.Name", var: parameter93_name}, {name: "Parameter93.Value", var: parameter93_value}, {name: "Parameter94.Name", var: parameter94_name}, {name: "Parameter94.Value", var: parameter94_value}, {name: "Parameter95.Name", var: parameter95_name}, {name: "Parameter95.Value", var: parameter95_value}, {name: "Parameter96.Name", var: parameter96_name}, {name: "Parameter96.Value", var: parameter96_value}, {name: "Parameter97.Name", var: parameter97_name}, {name: "Parameter97.Value", var: parameter97_value}, {name: "Parameter98.Name", var: parameter98_name}, {name: "Parameter98.Value", var: parameter98_value}, {name: "Parameter99.Name", var: parameter99_name}, {name: "Parameter99.Value", var: parameter99_value}, {name: StatusCallback, var: status_callback}, {name: StatusCallbackMethod, var: status_callback_method}, {name: Track, var: track}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, call_sid: $call_sid, connector_name: $connector_name, name: $name, parameter1_name: $parameter1_name, parameter1_value: $parameter1_value, parameter10_name: $parameter10_name, parameter10_value: $parameter10_value, parameter11_name: $parameter11_name, parameter11_value: $parameter11_value, parameter12_name: $parameter12_name, parameter12_value: $parameter12_value, parameter13_name: $parameter13_name, parameter13_value: $parameter13_value, parameter14_name: $parameter14_name, parameter14_value: $parameter14_value, parameter15_name: $parameter15_name, parameter15_value: $parameter15_value, parameter16_name: $parameter16_name, parameter16_value: $parameter16_value, parameter17_name: $parameter17_name, parameter17_value: $parameter17_value, parameter18_name: $parameter18_name, parameter18_value: $parameter18_value, parameter19_name: $parameter19_name, parameter19_value: $parameter19_value, parameter2_name: $parameter2_name, parameter2_value: $parameter2_value, parameter20_name: $parameter20_name, parameter20_value: $parameter20_value, parameter21_name: $parameter21_name, parameter21_value: $parameter21_value, parameter22_name: $parameter22_name, parameter22_value: $parameter22_value, parameter23_name: $parameter23_name, parameter23_value: $parameter23_value, parameter24_name: $parameter24_name, parameter24_value: $parameter24_value, parameter25_name: $parameter25_name, parameter25_value: $parameter25_value, parameter26_name: $parameter26_name, parameter26_value: $parameter26_value, parameter27_name: $parameter27_name, parameter27_value: $parameter27_value, parameter28_name: $parameter28_name, parameter28_value: $parameter28_value, parameter29_name: $parameter29_name, parameter29_value: $parameter29_value, parameter3_name: $parameter3_name, parameter3_value: $parameter3_value, parameter30_name: $parameter30_name, parameter30_value: $parameter30_value, parameter31_name: $parameter31_name, parameter31_value: $parameter31_value, parameter32_name: $parameter32_name, parameter32_value: $parameter32_value, parameter33_name: $parameter33_name, parameter33_value: $parameter33_value, parameter34_name: $parameter34_name, parameter34_value: $parameter34_value, parameter35_name: $parameter35_name, parameter35_value: $parameter35_value, parameter36_name: $parameter36_name, parameter36_value: $parameter36_value, parameter37_name: $parameter37_name, parameter37_value: $parameter37_value, parameter38_name: $parameter38_name, parameter38_value: $parameter38_value, parameter39_name: $parameter39_name, parameter39_value: $parameter39_value, parameter4_name: $parameter4_name, parameter4_value: $parameter4_value, parameter40_name: $parameter40_name, parameter40_value: $parameter40_value, parameter41_name: $parameter41_name, parameter41_value: $parameter41_value, parameter42_name: $parameter42_name, parameter42_value: $parameter42_value, parameter43_name: $parameter43_name, parameter43_value: $parameter43_value, parameter44_name: $parameter44_name, parameter44_value: $parameter44_value, parameter45_name: $parameter45_name, parameter45_value: $parameter45_value, parameter46_name: $parameter46_name, parameter46_value: $parameter46_value, parameter47_name: $parameter47_name, parameter47_value: $parameter47_value, parameter48_name: $parameter48_name, parameter48_value: $parameter48_value, parameter49_name: $parameter49_name, parameter49_value: $parameter49_value, parameter5_name: $parameter5_name, parameter5_value: $parameter5_value, parameter50_name: $parameter50_name, parameter50_value: $parameter50_value, parameter51_name: $parameter51_name, parameter51_value: $parameter51_value, parameter52_name: $parameter52_name, parameter52_value: $parameter52_value, parameter53_name: $parameter53_name, parameter53_value: $parameter53_value, parameter54_name: $parameter54_name, parameter54_value: $parameter54_value, parameter55_name: $parameter55_name, parameter55_value: $parameter55_value, parameter56_name: $parameter56_name, parameter56_value: $parameter56_value, parameter57_name: $parameter57_name, parameter57_value: $parameter57_value, parameter58_name: $parameter58_name, parameter58_value: $parameter58_value, parameter59_name: $parameter59_name, parameter59_value: $parameter59_value, parameter6_name: $parameter6_name, parameter6_value: $parameter6_value, parameter60_name: $parameter60_name, parameter60_value: $parameter60_value, parameter61_name: $parameter61_name, parameter61_value: $parameter61_value, parameter62_name: $parameter62_name, parameter62_value: $parameter62_value, parameter63_name: $parameter63_name, parameter63_value: $parameter63_value, parameter64_name: $parameter64_name, parameter64_value: $parameter64_value, parameter65_name: $parameter65_name, parameter65_value: $parameter65_value, parameter66_name: $parameter66_name, parameter66_value: $parameter66_value, parameter67_name: $parameter67_name, parameter67_value: $parameter67_value, parameter68_name: $parameter68_name, parameter68_value: $parameter68_value, parameter69_name: $parameter69_name, parameter69_value: $parameter69_value, parameter7_name: $parameter7_name, parameter7_value: $parameter7_value, parameter70_name: $parameter70_name, parameter70_value: $parameter70_value, parameter71_name: $parameter71_name, parameter71_value: $parameter71_value, parameter72_name: $parameter72_name, parameter72_value: $parameter72_value, parameter73_name: $parameter73_name, parameter73_value: $parameter73_value, parameter74_name: $parameter74_name, parameter74_value: $parameter74_value, parameter75_name: $parameter75_name, parameter75_value: $parameter75_value, parameter76_name: $parameter76_name, parameter76_value: $parameter76_value, parameter77_name: $parameter77_name, parameter77_value: $parameter77_value, parameter78_name: $parameter78_name, parameter78_value: $parameter78_value, parameter79_name: $parameter79_name, parameter79_value: $parameter79_value, parameter8_name: $parameter8_name, parameter8_value: $parameter8_value, parameter80_name: $parameter80_name, parameter80_value: $parameter80_value, parameter81_name: $parameter81_name, parameter81_value: $parameter81_value, parameter82_name: $parameter82_name, parameter82_value: $parameter82_value, parameter83_name: $parameter83_name, parameter83_value: $parameter83_value, parameter84_name: $parameter84_name, parameter84_value: $parameter84_value, parameter85_name: $parameter85_name, parameter85_value: $parameter85_value, parameter86_name: $parameter86_name, parameter86_value: $parameter86_value, parameter87_name: $parameter87_name, parameter87_value: $parameter87_value, parameter88_name: $parameter88_name, parameter88_value: $parameter88_value, parameter89_name: $parameter89_name, parameter89_value: $parameter89_value, parameter9_name: $parameter9_name, parameter9_value: $parameter9_value, parameter90_name: $parameter90_name, parameter90_value: $parameter90_value, parameter91_name: $parameter91_name, parameter91_value: $parameter91_value, parameter92_name: $parameter92_name, parameter92_value: $parameter92_value, parameter93_name: $parameter93_name, parameter93_value: $parameter93_value, parameter94_name: $parameter94_name, parameter94_value: $parameter94_value, parameter95_name: $parameter95_name, parameter95_value: $parameter95_value, parameter96_name: $parameter96_name, parameter96_value: $parameter96_value, parameter97_name: $parameter97_name, parameter97_value: $parameter97_value, parameter98_name: $parameter98_name, parameter98_value: $parameter98_value, parameter99_name: $parameter99_name, parameter99_value: $parameter99_value, status_callback: $status_callback, status_callback_method: $status_callback_method, track: $track
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stop a Siprec using either the SID of the Siprec resource or the `name` used when creating the resource
#
# POST /2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/Siprec/{Sid}.json
# Returns: record<account_sid: string, call_sid: string, date_updated: string, name: string, sid: string, status: string, uri: string>
# operationId: UpdateSiprec
export def "update-siprec" [
  account_sid: string
  call_sid: string
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
  status: string@status-completer-4
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/Siprec/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: CallSid, var: call_sid}, {name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, call_sid: $call_sid, sid: $sid, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a Stream
#
# POST /2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/Streams.json
# Returns: record<account_sid: string, call_sid: string, date_updated: string, name: string, sid: string, status: string, uri: string>
# operationId: CreateStream
export def "create-stream" [
  account_sid: string
  call_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The user-specified name of this Stream, if one was given when the Stream was created. This may be used to stop the Stream.
  --parameter1-name: string # Parameter name
  --parameter1-value: string # Parameter value
  --parameter10-name: string # Parameter name
  --parameter10-value: string # Parameter value
  --parameter11-name: string # Parameter name
  --parameter11-value: string # Parameter value
  --parameter12-name: string # Parameter name
  --parameter12-value: string # Parameter value
  --parameter13-name: string # Parameter name
  --parameter13-value: string # Parameter value
  --parameter14-name: string # Parameter name
  --parameter14-value: string # Parameter value
  --parameter15-name: string # Parameter name
  --parameter15-value: string # Parameter value
  --parameter16-name: string # Parameter name
  --parameter16-value: string # Parameter value
  --parameter17-name: string # Parameter name
  --parameter17-value: string # Parameter value
  --parameter18-name: string # Parameter name
  --parameter18-value: string # Parameter value
  --parameter19-name: string # Parameter name
  --parameter19-value: string # Parameter value
  --parameter2-name: string # Parameter name
  --parameter2-value: string # Parameter value
  --parameter20-name: string # Parameter name
  --parameter20-value: string # Parameter value
  --parameter21-name: string # Parameter name
  --parameter21-value: string # Parameter value
  --parameter22-name: string # Parameter name
  --parameter22-value: string # Parameter value
  --parameter23-name: string # Parameter name
  --parameter23-value: string # Parameter value
  --parameter24-name: string # Parameter name
  --parameter24-value: string # Parameter value
  --parameter25-name: string # Parameter name
  --parameter25-value: string # Parameter value
  --parameter26-name: string # Parameter name
  --parameter26-value: string # Parameter value
  --parameter27-name: string # Parameter name
  --parameter27-value: string # Parameter value
  --parameter28-name: string # Parameter name
  --parameter28-value: string # Parameter value
  --parameter29-name: string # Parameter name
  --parameter29-value: string # Parameter value
  --parameter3-name: string # Parameter name
  --parameter3-value: string # Parameter value
  --parameter30-name: string # Parameter name
  --parameter30-value: string # Parameter value
  --parameter31-name: string # Parameter name
  --parameter31-value: string # Parameter value
  --parameter32-name: string # Parameter name
  --parameter32-value: string # Parameter value
  --parameter33-name: string # Parameter name
  --parameter33-value: string # Parameter value
  --parameter34-name: string # Parameter name
  --parameter34-value: string # Parameter value
  --parameter35-name: string # Parameter name
  --parameter35-value: string # Parameter value
  --parameter36-name: string # Parameter name
  --parameter36-value: string # Parameter value
  --parameter37-name: string # Parameter name
  --parameter37-value: string # Parameter value
  --parameter38-name: string # Parameter name
  --parameter38-value: string # Parameter value
  --parameter39-name: string # Parameter name
  --parameter39-value: string # Parameter value
  --parameter4-name: string # Parameter name
  --parameter4-value: string # Parameter value
  --parameter40-name: string # Parameter name
  --parameter40-value: string # Parameter value
  --parameter41-name: string # Parameter name
  --parameter41-value: string # Parameter value
  --parameter42-name: string # Parameter name
  --parameter42-value: string # Parameter value
  --parameter43-name: string # Parameter name
  --parameter43-value: string # Parameter value
  --parameter44-name: string # Parameter name
  --parameter44-value: string # Parameter value
  --parameter45-name: string # Parameter name
  --parameter45-value: string # Parameter value
  --parameter46-name: string # Parameter name
  --parameter46-value: string # Parameter value
  --parameter47-name: string # Parameter name
  --parameter47-value: string # Parameter value
  --parameter48-name: string # Parameter name
  --parameter48-value: string # Parameter value
  --parameter49-name: string # Parameter name
  --parameter49-value: string # Parameter value
  --parameter5-name: string # Parameter name
  --parameter5-value: string # Parameter value
  --parameter50-name: string # Parameter name
  --parameter50-value: string # Parameter value
  --parameter51-name: string # Parameter name
  --parameter51-value: string # Parameter value
  --parameter52-name: string # Parameter name
  --parameter52-value: string # Parameter value
  --parameter53-name: string # Parameter name
  --parameter53-value: string # Parameter value
  --parameter54-name: string # Parameter name
  --parameter54-value: string # Parameter value
  --parameter55-name: string # Parameter name
  --parameter55-value: string # Parameter value
  --parameter56-name: string # Parameter name
  --parameter56-value: string # Parameter value
  --parameter57-name: string # Parameter name
  --parameter57-value: string # Parameter value
  --parameter58-name: string # Parameter name
  --parameter58-value: string # Parameter value
  --parameter59-name: string # Parameter name
  --parameter59-value: string # Parameter value
  --parameter6-name: string # Parameter name
  --parameter6-value: string # Parameter value
  --parameter60-name: string # Parameter name
  --parameter60-value: string # Parameter value
  --parameter61-name: string # Parameter name
  --parameter61-value: string # Parameter value
  --parameter62-name: string # Parameter name
  --parameter62-value: string # Parameter value
  --parameter63-name: string # Parameter name
  --parameter63-value: string # Parameter value
  --parameter64-name: string # Parameter name
  --parameter64-value: string # Parameter value
  --parameter65-name: string # Parameter name
  --parameter65-value: string # Parameter value
  --parameter66-name: string # Parameter name
  --parameter66-value: string # Parameter value
  --parameter67-name: string # Parameter name
  --parameter67-value: string # Parameter value
  --parameter68-name: string # Parameter name
  --parameter68-value: string # Parameter value
  --parameter69-name: string # Parameter name
  --parameter69-value: string # Parameter value
  --parameter7-name: string # Parameter name
  --parameter7-value: string # Parameter value
  --parameter70-name: string # Parameter name
  --parameter70-value: string # Parameter value
  --parameter71-name: string # Parameter name
  --parameter71-value: string # Parameter value
  --parameter72-name: string # Parameter name
  --parameter72-value: string # Parameter value
  --parameter73-name: string # Parameter name
  --parameter73-value: string # Parameter value
  --parameter74-name: string # Parameter name
  --parameter74-value: string # Parameter value
  --parameter75-name: string # Parameter name
  --parameter75-value: string # Parameter value
  --parameter76-name: string # Parameter name
  --parameter76-value: string # Parameter value
  --parameter77-name: string # Parameter name
  --parameter77-value: string # Parameter value
  --parameter78-name: string # Parameter name
  --parameter78-value: string # Parameter value
  --parameter79-name: string # Parameter name
  --parameter79-value: string # Parameter value
  --parameter8-name: string # Parameter name
  --parameter8-value: string # Parameter value
  --parameter80-name: string # Parameter name
  --parameter80-value: string # Parameter value
  --parameter81-name: string # Parameter name
  --parameter81-value: string # Parameter value
  --parameter82-name: string # Parameter name
  --parameter82-value: string # Parameter value
  --parameter83-name: string # Parameter name
  --parameter83-value: string # Parameter value
  --parameter84-name: string # Parameter name
  --parameter84-value: string # Parameter value
  --parameter85-name: string # Parameter name
  --parameter85-value: string # Parameter value
  --parameter86-name: string # Parameter name
  --parameter86-value: string # Parameter value
  --parameter87-name: string # Parameter name
  --parameter87-value: string # Parameter value
  --parameter88-name: string # Parameter name
  --parameter88-value: string # Parameter value
  --parameter89-name: string # Parameter name
  --parameter89-value: string # Parameter value
  --parameter9-name: string # Parameter name
  --parameter9-value: string # Parameter value
  --parameter90-name: string # Parameter name
  --parameter90-value: string # Parameter value
  --parameter91-name: string # Parameter name
  --parameter91-value: string # Parameter value
  --parameter92-name: string # Parameter name
  --parameter92-value: string # Parameter value
  --parameter93-name: string # Parameter name
  --parameter93-value: string # Parameter value
  --parameter94-name: string # Parameter name
  --parameter94-value: string # Parameter value
  --parameter95-name: string # Parameter name
  --parameter95-value: string # Parameter value
  --parameter96-name: string # Parameter name
  --parameter96-value: string # Parameter value
  --parameter97-name: string # Parameter name
  --parameter97-value: string # Parameter value
  --parameter98-name: string # Parameter name
  --parameter98-value: string # Parameter value
  --parameter99-name: string # Parameter name
  --parameter99-value: string # Parameter value
  --status-callback: string # Absolute URL of the status callback. (format: uri)
  --status-callback-method: string@status-callback-method-completer # The http method for the status_callback (one of GET, POST). (format: http-method)
  --track: string@track-completer
  url: string # Relative or absolute url where WebSocket connection will be established. (format: uri)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/Streams.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: CallSid, var: call_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Name, var: name}, {name: "Parameter1.Name", var: parameter1_name}, {name: "Parameter1.Value", var: parameter1_value}, {name: "Parameter10.Name", var: parameter10_name}, {name: "Parameter10.Value", var: parameter10_value}, {name: "Parameter11.Name", var: parameter11_name}, {name: "Parameter11.Value", var: parameter11_value}, {name: "Parameter12.Name", var: parameter12_name}, {name: "Parameter12.Value", var: parameter12_value}, {name: "Parameter13.Name", var: parameter13_name}, {name: "Parameter13.Value", var: parameter13_value}, {name: "Parameter14.Name", var: parameter14_name}, {name: "Parameter14.Value", var: parameter14_value}, {name: "Parameter15.Name", var: parameter15_name}, {name: "Parameter15.Value", var: parameter15_value}, {name: "Parameter16.Name", var: parameter16_name}, {name: "Parameter16.Value", var: parameter16_value}, {name: "Parameter17.Name", var: parameter17_name}, {name: "Parameter17.Value", var: parameter17_value}, {name: "Parameter18.Name", var: parameter18_name}, {name: "Parameter18.Value", var: parameter18_value}, {name: "Parameter19.Name", var: parameter19_name}, {name: "Parameter19.Value", var: parameter19_value}, {name: "Parameter2.Name", var: parameter2_name}, {name: "Parameter2.Value", var: parameter2_value}, {name: "Parameter20.Name", var: parameter20_name}, {name: "Parameter20.Value", var: parameter20_value}, {name: "Parameter21.Name", var: parameter21_name}, {name: "Parameter21.Value", var: parameter21_value}, {name: "Parameter22.Name", var: parameter22_name}, {name: "Parameter22.Value", var: parameter22_value}, {name: "Parameter23.Name", var: parameter23_name}, {name: "Parameter23.Value", var: parameter23_value}, {name: "Parameter24.Name", var: parameter24_name}, {name: "Parameter24.Value", var: parameter24_value}, {name: "Parameter25.Name", var: parameter25_name}, {name: "Parameter25.Value", var: parameter25_value}, {name: "Parameter26.Name", var: parameter26_name}, {name: "Parameter26.Value", var: parameter26_value}, {name: "Parameter27.Name", var: parameter27_name}, {name: "Parameter27.Value", var: parameter27_value}, {name: "Parameter28.Name", var: parameter28_name}, {name: "Parameter28.Value", var: parameter28_value}, {name: "Parameter29.Name", var: parameter29_name}, {name: "Parameter29.Value", var: parameter29_value}, {name: "Parameter3.Name", var: parameter3_name}, {name: "Parameter3.Value", var: parameter3_value}, {name: "Parameter30.Name", var: parameter30_name}, {name: "Parameter30.Value", var: parameter30_value}, {name: "Parameter31.Name", var: parameter31_name}, {name: "Parameter31.Value", var: parameter31_value}, {name: "Parameter32.Name", var: parameter32_name}, {name: "Parameter32.Value", var: parameter32_value}, {name: "Parameter33.Name", var: parameter33_name}, {name: "Parameter33.Value", var: parameter33_value}, {name: "Parameter34.Name", var: parameter34_name}, {name: "Parameter34.Value", var: parameter34_value}, {name: "Parameter35.Name", var: parameter35_name}, {name: "Parameter35.Value", var: parameter35_value}, {name: "Parameter36.Name", var: parameter36_name}, {name: "Parameter36.Value", var: parameter36_value}, {name: "Parameter37.Name", var: parameter37_name}, {name: "Parameter37.Value", var: parameter37_value}, {name: "Parameter38.Name", var: parameter38_name}, {name: "Parameter38.Value", var: parameter38_value}, {name: "Parameter39.Name", var: parameter39_name}, {name: "Parameter39.Value", var: parameter39_value}, {name: "Parameter4.Name", var: parameter4_name}, {name: "Parameter4.Value", var: parameter4_value}, {name: "Parameter40.Name", var: parameter40_name}, {name: "Parameter40.Value", var: parameter40_value}, {name: "Parameter41.Name", var: parameter41_name}, {name: "Parameter41.Value", var: parameter41_value}, {name: "Parameter42.Name", var: parameter42_name}, {name: "Parameter42.Value", var: parameter42_value}, {name: "Parameter43.Name", var: parameter43_name}, {name: "Parameter43.Value", var: parameter43_value}, {name: "Parameter44.Name", var: parameter44_name}, {name: "Parameter44.Value", var: parameter44_value}, {name: "Parameter45.Name", var: parameter45_name}, {name: "Parameter45.Value", var: parameter45_value}, {name: "Parameter46.Name", var: parameter46_name}, {name: "Parameter46.Value", var: parameter46_value}, {name: "Parameter47.Name", var: parameter47_name}, {name: "Parameter47.Value", var: parameter47_value}, {name: "Parameter48.Name", var: parameter48_name}, {name: "Parameter48.Value", var: parameter48_value}, {name: "Parameter49.Name", var: parameter49_name}, {name: "Parameter49.Value", var: parameter49_value}, {name: "Parameter5.Name", var: parameter5_name}, {name: "Parameter5.Value", var: parameter5_value}, {name: "Parameter50.Name", var: parameter50_name}, {name: "Parameter50.Value", var: parameter50_value}, {name: "Parameter51.Name", var: parameter51_name}, {name: "Parameter51.Value", var: parameter51_value}, {name: "Parameter52.Name", var: parameter52_name}, {name: "Parameter52.Value", var: parameter52_value}, {name: "Parameter53.Name", var: parameter53_name}, {name: "Parameter53.Value", var: parameter53_value}, {name: "Parameter54.Name", var: parameter54_name}, {name: "Parameter54.Value", var: parameter54_value}, {name: "Parameter55.Name", var: parameter55_name}, {name: "Parameter55.Value", var: parameter55_value}, {name: "Parameter56.Name", var: parameter56_name}, {name: "Parameter56.Value", var: parameter56_value}, {name: "Parameter57.Name", var: parameter57_name}, {name: "Parameter57.Value", var: parameter57_value}, {name: "Parameter58.Name", var: parameter58_name}, {name: "Parameter58.Value", var: parameter58_value}, {name: "Parameter59.Name", var: parameter59_name}, {name: "Parameter59.Value", var: parameter59_value}, {name: "Parameter6.Name", var: parameter6_name}, {name: "Parameter6.Value", var: parameter6_value}, {name: "Parameter60.Name", var: parameter60_name}, {name: "Parameter60.Value", var: parameter60_value}, {name: "Parameter61.Name", var: parameter61_name}, {name: "Parameter61.Value", var: parameter61_value}, {name: "Parameter62.Name", var: parameter62_name}, {name: "Parameter62.Value", var: parameter62_value}, {name: "Parameter63.Name", var: parameter63_name}, {name: "Parameter63.Value", var: parameter63_value}, {name: "Parameter64.Name", var: parameter64_name}, {name: "Parameter64.Value", var: parameter64_value}, {name: "Parameter65.Name", var: parameter65_name}, {name: "Parameter65.Value", var: parameter65_value}, {name: "Parameter66.Name", var: parameter66_name}, {name: "Parameter66.Value", var: parameter66_value}, {name: "Parameter67.Name", var: parameter67_name}, {name: "Parameter67.Value", var: parameter67_value}, {name: "Parameter68.Name", var: parameter68_name}, {name: "Parameter68.Value", var: parameter68_value}, {name: "Parameter69.Name", var: parameter69_name}, {name: "Parameter69.Value", var: parameter69_value}, {name: "Parameter7.Name", var: parameter7_name}, {name: "Parameter7.Value", var: parameter7_value}, {name: "Parameter70.Name", var: parameter70_name}, {name: "Parameter70.Value", var: parameter70_value}, {name: "Parameter71.Name", var: parameter71_name}, {name: "Parameter71.Value", var: parameter71_value}, {name: "Parameter72.Name", var: parameter72_name}, {name: "Parameter72.Value", var: parameter72_value}, {name: "Parameter73.Name", var: parameter73_name}, {name: "Parameter73.Value", var: parameter73_value}, {name: "Parameter74.Name", var: parameter74_name}, {name: "Parameter74.Value", var: parameter74_value}, {name: "Parameter75.Name", var: parameter75_name}, {name: "Parameter75.Value", var: parameter75_value}, {name: "Parameter76.Name", var: parameter76_name}, {name: "Parameter76.Value", var: parameter76_value}, {name: "Parameter77.Name", var: parameter77_name}, {name: "Parameter77.Value", var: parameter77_value}, {name: "Parameter78.Name", var: parameter78_name}, {name: "Parameter78.Value", var: parameter78_value}, {name: "Parameter79.Name", var: parameter79_name}, {name: "Parameter79.Value", var: parameter79_value}, {name: "Parameter8.Name", var: parameter8_name}, {name: "Parameter8.Value", var: parameter8_value}, {name: "Parameter80.Name", var: parameter80_name}, {name: "Parameter80.Value", var: parameter80_value}, {name: "Parameter81.Name", var: parameter81_name}, {name: "Parameter81.Value", var: parameter81_value}, {name: "Parameter82.Name", var: parameter82_name}, {name: "Parameter82.Value", var: parameter82_value}, {name: "Parameter83.Name", var: parameter83_name}, {name: "Parameter83.Value", var: parameter83_value}, {name: "Parameter84.Name", var: parameter84_name}, {name: "Parameter84.Value", var: parameter84_value}, {name: "Parameter85.Name", var: parameter85_name}, {name: "Parameter85.Value", var: parameter85_value}, {name: "Parameter86.Name", var: parameter86_name}, {name: "Parameter86.Value", var: parameter86_value}, {name: "Parameter87.Name", var: parameter87_name}, {name: "Parameter87.Value", var: parameter87_value}, {name: "Parameter88.Name", var: parameter88_name}, {name: "Parameter88.Value", var: parameter88_value}, {name: "Parameter89.Name", var: parameter89_name}, {name: "Parameter89.Value", var: parameter89_value}, {name: "Parameter9.Name", var: parameter9_name}, {name: "Parameter9.Value", var: parameter9_value}, {name: "Parameter90.Name", var: parameter90_name}, {name: "Parameter90.Value", var: parameter90_value}, {name: "Parameter91.Name", var: parameter91_name}, {name: "Parameter91.Value", var: parameter91_value}, {name: "Parameter92.Name", var: parameter92_name}, {name: "Parameter92.Value", var: parameter92_value}, {name: "Parameter93.Name", var: parameter93_name}, {name: "Parameter93.Value", var: parameter93_value}, {name: "Parameter94.Name", var: parameter94_name}, {name: "Parameter94.Value", var: parameter94_value}, {name: "Parameter95.Name", var: parameter95_name}, {name: "Parameter95.Value", var: parameter95_value}, {name: "Parameter96.Name", var: parameter96_name}, {name: "Parameter96.Value", var: parameter96_value}, {name: "Parameter97.Name", var: parameter97_name}, {name: "Parameter97.Value", var: parameter97_value}, {name: "Parameter98.Name", var: parameter98_name}, {name: "Parameter98.Value", var: parameter98_value}, {name: "Parameter99.Name", var: parameter99_name}, {name: "Parameter99.Value", var: parameter99_value}, {name: StatusCallback, var: status_callback}, {name: StatusCallbackMethod, var: status_callback_method}, {name: Track, var: track}, {name: Url, var: url}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, call_sid: $call_sid, name: $name, parameter1_name: $parameter1_name, parameter1_value: $parameter1_value, parameter10_name: $parameter10_name, parameter10_value: $parameter10_value, parameter11_name: $parameter11_name, parameter11_value: $parameter11_value, parameter12_name: $parameter12_name, parameter12_value: $parameter12_value, parameter13_name: $parameter13_name, parameter13_value: $parameter13_value, parameter14_name: $parameter14_name, parameter14_value: $parameter14_value, parameter15_name: $parameter15_name, parameter15_value: $parameter15_value, parameter16_name: $parameter16_name, parameter16_value: $parameter16_value, parameter17_name: $parameter17_name, parameter17_value: $parameter17_value, parameter18_name: $parameter18_name, parameter18_value: $parameter18_value, parameter19_name: $parameter19_name, parameter19_value: $parameter19_value, parameter2_name: $parameter2_name, parameter2_value: $parameter2_value, parameter20_name: $parameter20_name, parameter20_value: $parameter20_value, parameter21_name: $parameter21_name, parameter21_value: $parameter21_value, parameter22_name: $parameter22_name, parameter22_value: $parameter22_value, parameter23_name: $parameter23_name, parameter23_value: $parameter23_value, parameter24_name: $parameter24_name, parameter24_value: $parameter24_value, parameter25_name: $parameter25_name, parameter25_value: $parameter25_value, parameter26_name: $parameter26_name, parameter26_value: $parameter26_value, parameter27_name: $parameter27_name, parameter27_value: $parameter27_value, parameter28_name: $parameter28_name, parameter28_value: $parameter28_value, parameter29_name: $parameter29_name, parameter29_value: $parameter29_value, parameter3_name: $parameter3_name, parameter3_value: $parameter3_value, parameter30_name: $parameter30_name, parameter30_value: $parameter30_value, parameter31_name: $parameter31_name, parameter31_value: $parameter31_value, parameter32_name: $parameter32_name, parameter32_value: $parameter32_value, parameter33_name: $parameter33_name, parameter33_value: $parameter33_value, parameter34_name: $parameter34_name, parameter34_value: $parameter34_value, parameter35_name: $parameter35_name, parameter35_value: $parameter35_value, parameter36_name: $parameter36_name, parameter36_value: $parameter36_value, parameter37_name: $parameter37_name, parameter37_value: $parameter37_value, parameter38_name: $parameter38_name, parameter38_value: $parameter38_value, parameter39_name: $parameter39_name, parameter39_value: $parameter39_value, parameter4_name: $parameter4_name, parameter4_value: $parameter4_value, parameter40_name: $parameter40_name, parameter40_value: $parameter40_value, parameter41_name: $parameter41_name, parameter41_value: $parameter41_value, parameter42_name: $parameter42_name, parameter42_value: $parameter42_value, parameter43_name: $parameter43_name, parameter43_value: $parameter43_value, parameter44_name: $parameter44_name, parameter44_value: $parameter44_value, parameter45_name: $parameter45_name, parameter45_value: $parameter45_value, parameter46_name: $parameter46_name, parameter46_value: $parameter46_value, parameter47_name: $parameter47_name, parameter47_value: $parameter47_value, parameter48_name: $parameter48_name, parameter48_value: $parameter48_value, parameter49_name: $parameter49_name, parameter49_value: $parameter49_value, parameter5_name: $parameter5_name, parameter5_value: $parameter5_value, parameter50_name: $parameter50_name, parameter50_value: $parameter50_value, parameter51_name: $parameter51_name, parameter51_value: $parameter51_value, parameter52_name: $parameter52_name, parameter52_value: $parameter52_value, parameter53_name: $parameter53_name, parameter53_value: $parameter53_value, parameter54_name: $parameter54_name, parameter54_value: $parameter54_value, parameter55_name: $parameter55_name, parameter55_value: $parameter55_value, parameter56_name: $parameter56_name, parameter56_value: $parameter56_value, parameter57_name: $parameter57_name, parameter57_value: $parameter57_value, parameter58_name: $parameter58_name, parameter58_value: $parameter58_value, parameter59_name: $parameter59_name, parameter59_value: $parameter59_value, parameter6_name: $parameter6_name, parameter6_value: $parameter6_value, parameter60_name: $parameter60_name, parameter60_value: $parameter60_value, parameter61_name: $parameter61_name, parameter61_value: $parameter61_value, parameter62_name: $parameter62_name, parameter62_value: $parameter62_value, parameter63_name: $parameter63_name, parameter63_value: $parameter63_value, parameter64_name: $parameter64_name, parameter64_value: $parameter64_value, parameter65_name: $parameter65_name, parameter65_value: $parameter65_value, parameter66_name: $parameter66_name, parameter66_value: $parameter66_value, parameter67_name: $parameter67_name, parameter67_value: $parameter67_value, parameter68_name: $parameter68_name, parameter68_value: $parameter68_value, parameter69_name: $parameter69_name, parameter69_value: $parameter69_value, parameter7_name: $parameter7_name, parameter7_value: $parameter7_value, parameter70_name: $parameter70_name, parameter70_value: $parameter70_value, parameter71_name: $parameter71_name, parameter71_value: $parameter71_value, parameter72_name: $parameter72_name, parameter72_value: $parameter72_value, parameter73_name: $parameter73_name, parameter73_value: $parameter73_value, parameter74_name: $parameter74_name, parameter74_value: $parameter74_value, parameter75_name: $parameter75_name, parameter75_value: $parameter75_value, parameter76_name: $parameter76_name, parameter76_value: $parameter76_value, parameter77_name: $parameter77_name, parameter77_value: $parameter77_value, parameter78_name: $parameter78_name, parameter78_value: $parameter78_value, parameter79_name: $parameter79_name, parameter79_value: $parameter79_value, parameter8_name: $parameter8_name, parameter8_value: $parameter8_value, parameter80_name: $parameter80_name, parameter80_value: $parameter80_value, parameter81_name: $parameter81_name, parameter81_value: $parameter81_value, parameter82_name: $parameter82_name, parameter82_value: $parameter82_value, parameter83_name: $parameter83_name, parameter83_value: $parameter83_value, parameter84_name: $parameter84_name, parameter84_value: $parameter84_value, parameter85_name: $parameter85_name, parameter85_value: $parameter85_value, parameter86_name: $parameter86_name, parameter86_value: $parameter86_value, parameter87_name: $parameter87_name, parameter87_value: $parameter87_value, parameter88_name: $parameter88_name, parameter88_value: $parameter88_value, parameter89_name: $parameter89_name, parameter89_value: $parameter89_value, parameter9_name: $parameter9_name, parameter9_value: $parameter9_value, parameter90_name: $parameter90_name, parameter90_value: $parameter90_value, parameter91_name: $parameter91_name, parameter91_value: $parameter91_value, parameter92_name: $parameter92_name, parameter92_value: $parameter92_value, parameter93_name: $parameter93_name, parameter93_value: $parameter93_value, parameter94_name: $parameter94_name, parameter94_value: $parameter94_value, parameter95_name: $parameter95_name, parameter95_value: $parameter95_value, parameter96_name: $parameter96_name, parameter96_value: $parameter96_value, parameter97_name: $parameter97_name, parameter97_value: $parameter97_value, parameter98_name: $parameter98_name, parameter98_value: $parameter98_value, parameter99_name: $parameter99_name, parameter99_value: $parameter99_value, status_callback: $status_callback, status_callback_method: $status_callback_method, track: $track, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stop a Stream using either the SID of the Stream resource or the `name` used when creating the resource
#
# POST /2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/Streams/{Sid}.json
# Returns: record<account_sid: string, call_sid: string, date_updated: string, name: string, sid: string, status: string, uri: string>
# operationId: UpdateStream
export def "update-stream" [
  account_sid: string
  call_sid: string
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
  status: string@status-completer-4
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/Streams/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: CallSid, var: call_sid}, {name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, call_sid: $call_sid, sid: $sid, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Subscribe to User Defined Messages for a given Call SID.
#
# POST /2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/UserDefinedMessageSubscriptions.json
# Returns: record<account_sid: string, call_sid: string, date_created: string, sid: string, uri: string>
# operationId: CreateUserDefinedMessageSubscription
export def "create-user-defined-message-subscription" [
  account_sid: string
  call_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  callback: string # The URL we should call using the `method` to send user defined events to your application. URLs must contain a valid hostname (underscores are not permitted). (format: uri)
  --idempotency-key: string # A unique string value to identify API call. This should be a unique string value per API call and can be a randomly generated.
  --method: string@method-completer # The HTTP method Twilio will use when requesting the above `Url`. Either `GET` or `POST`. Default is `POST`. (format: http-method)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/UserDefinedMessageSubscriptions.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: CallSid, var: call_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Callback, var: callback}, {name: IdempotencyKey, var: idempotency_key}, {name: Method, var: method}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, call_sid: $call_sid, callback: $callback, idempotency_key: $idempotency_key, method: $method
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a specific User Defined Message Subscription.
#
# DELETE /2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/UserDefinedMessageSubscriptions/{Sid}.json
# operationId: DeleteUserDefinedMessageSubscription
export def "delete-user-defined-message-subscription" [
  account_sid: string
  call_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/UserDefinedMessageSubscriptions/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: CallSid, var: call_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, call_sid: $call_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new User Defined Message for the given Call SID.
#
# POST /2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/UserDefinedMessages.json
# Returns: record<account_sid: string, call_sid: string, date_created: string, sid: string>
# operationId: CreateUserDefinedMessage
export def "create-user-defined-message" [
  account_sid: string
  call_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  content: string # The User Defined Message in the form of URL-encoded JSON string.
  --idempotency-key: string # A unique string value to identify API call. This should be a unique string value per API call and can be a randomly generated.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/UserDefinedMessages.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: CallSid, var: call_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Content, var: content}, {name: IdempotencyKey, var: idempotency_key}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, call_sid: $call_sid, content: $content, idempotency_key: $idempotency_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a Call record from your account. Once the record is deleted, it will no longer appear in the API and Account Portal logs.
#
# DELETE /2010-04-01/Accounts/{AccountSid}/Calls/{Sid}.json
# operationId: DeleteCall
export def "delete-call" [
  account_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/Calls/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch the call specified by the provided Call SID
#
# GET /2010-04-01/Accounts/{AccountSid}/Calls/{Sid}.json
# Returns: record<account_sid: string, answered_by: string, api_version: string, caller_name: string, date_created: string, date_updated: string, direction: string, duration: string, end_time: string, forwarded_from: string, from: string, from_formatted: string, group_sid: string, parent_call_sid: string, phone_number_sid: string, price: string, price_unit: string, queue_time: string, sid: string, start_time: string, status: string, subresource_uris: record, to: string, to_formatted: string, trunk_sid: string, uri: string>
# operationId: FetchCall
export def "fetch-call" [
  account_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/Calls/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Initiates a call redirect or terminates a call
#
# POST /2010-04-01/Accounts/{AccountSid}/Calls/{Sid}.json
# Returns: record<account_sid: string, answered_by: string, api_version: string, caller_name: string, date_created: string, date_updated: string, direction: string, duration: string, end_time: string, forwarded_from: string, from: string, from_formatted: string, group_sid: string, parent_call_sid: string, phone_number_sid: string, price: string, price_unit: string, queue_time: string, sid: string, start_time: string, status: string, subresource_uris: record, to: string, to_formatted: string, trunk_sid: string, uri: string>
# operationId: UpdateCall
export def "update-call" [
  account_sid: string
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
  --fallback-method: string@fallback-method-completer # The HTTP method that we should use to request the `fallback_url`. Can be: `GET` or `POST` and the default is `POST`. If an `application_sid` parameter is present, this parameter is ignored. (format: http-method)
  --fallback-url: string # The URL that we call using the `fallback_method` if an error occurs when requesting or executing the TwiML at `url`. If an `application_sid` parameter is present, this parameter is ignored. (format: uri)
  --method: string@method-completer # The HTTP method we should use when calling the `url`. Can be: `GET` or `POST` and the default is `POST`. If an `application_sid` parameter is present, this parameter is ignored. (format: http-method)
  --status: string@status-completer-5
  --status-callback: string # The URL we should call using the `status_callback_method` to send status information to your application. If no `status_callback_event` is specified, we will send the `completed` status. If an `application_sid` parameter is present, this parameter is ignored. URLs must contain a valid hostname (underscores are not permitted). (format: uri)
  --status-callback-method: string@status-callback-method-completer # The HTTP method we should use when requesting the `status_callback` URL. Can be: `GET` or `POST` and the default is `POST`. If an `application_sid` parameter is present, this parameter is ignored. (format: http-method)
  --time-limit: int # The maximum duration of the call in seconds. Constraints depend on account and configuration.
  --twiml: string # TwiML instructions for the call Twilio will use without fetching Twiml from url. Twiml and url parameters are mutually exclusive (format: twiml)
  --url: string # The absolute URL that returns the TwiML instructions for the call. We will call this URL using the `method` when the call connects. For more information, see the [Url Parameter](https://www.twilio.com/docs/voice/make-calls#specify-a-url-parameter) section in [Making Calls](https://www.twilio.com/docs/voice/make-calls). (format: uri)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2010-04-01/Accounts/{AccountSid}/Calls/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: FallbackMethod, var: fallback_method}, {name: FallbackUrl, var: fallback_url}, {name: Method, var: method}, {name: Status, var: status}, {name: StatusCallback, var: status_callback}, {name: StatusCallbackMethod, var: status_callback_method}, {name: TimeLimit, var: time_limit}, {name: Twiml, var: twiml}, {name: Url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, sid: $sid, fallback_method: $fallback_method, fallback_url: $fallback_url, method: $method, status: $status, status_callback: $status_callback, status_callback_method: $status_callback_method, time_limit: $time_limit, twiml: $twiml, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of conferences belonging to the account used to make the request
#
# GET /2010-04-01/Accounts/{AccountSid}/Conferences.json
# Returns: record<conferences: table<account_sid: string, api_version: string, call_sid_ending_conference: string, date_created: string, date_updated: string, friendly_name: string, reason_conference_ended: string, region: string, sid: string, status: string, subresource_uris: record, uri: string>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>
# operationId: ListConference
export def "list-conference" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-created: string # The `date_created` value, specified as `YYYY-MM-DD`, of the resources to read. To read conferences that started on or before midnight on a date, use `<=YYYY-MM-DD`, and to specify conferences that started on or after midnight on a date, use `>=YYYY-MM-DD`. (format: date)
  --qp-date-created: string # The `date_created` value, specified as `YYYY-MM-DD`, of the resources to read. To read conferences that started on or before midnight on a date, use `<=YYYY-MM-DD`, and to specify conferences that started on or after midnight on a date, use `>=YYYY-MM-DD`. (format: date) (spec name: DateCreated<)
  --qp-date-created-2: string # The `date_created` value, specified as `YYYY-MM-DD`, of the resources to read. To read conferences that started on or before midnight on a date, use `<=YYYY-MM-DD`, and to specify conferences that started on or after midnight on a date, use `>=YYYY-MM-DD`. (format: date) (spec name: DateCreated>)
  --date-updated: string # The `date_updated` value, specified as `YYYY-MM-DD`, of the resources to read. To read conferences that were last updated on or before midnight on a date, use `<=YYYY-MM-DD`, and to specify conferences that were last updated on or after midnight on a given date, use `>=YYYY-MM-DD`. (format: date)
  --qp-date-updated: string # The `date_updated` value, specified as `YYYY-MM-DD`, of the resources to read. To read conferences that were last updated on or before midnight on a date, use `<=YYYY-MM-DD`, and to specify conferences that were last updated on or after midnight on a given date, use `>=YYYY-MM-DD`. (format: date) (spec name: DateUpdated<)
  --qp-date-updated-2: string # The `date_updated` value, specified as `YYYY-MM-DD`, of the resources to read. To read conferences that were last updated on or before midnight on a date, use `<=YYYY-MM-DD`, and to specify conferences that were last updated on or after midnight on a given date, use `>=YYYY-MM-DD`. (format: date) (spec name: DateUpdated>)
  --friendly-name: string # The string that identifies the Conference resources to read.
  --status: string@status-completer-6 # The status of the resources to read. Can be: `init`, `in-progress`, or `completed`.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2010-04-01/Accounts/{AccountSid}/Conferences.json"
    path_params: [{name: AccountSid, var: account_sid}]
    query: [{name: DateCreated, var: date_created}, {name: "DateCreated<", var: qp_date_created}, {name: "DateCreated>", var: qp_date_created_2}, {name: DateUpdated, var: date_updated}, {name: "DateUpdated<", var: qp_date_updated}, {name: "DateUpdated>", var: qp_date_updated_2}, {name: FriendlyName, var: friendly_name}, {name: Status, var: status}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, date_created: $date_created, qp_date_created: $qp_date_created, qp_date_created_2: $qp_date_created_2, date_updated: $date_updated, qp_date_updated: $qp_date_updated, qp_date_updated_2: $qp_date_updated_2, friendly_name: $friendly_name, status: $status, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of participants belonging to the account used to make the request
#
# GET /2010-04-01/Accounts/{AccountSid}/Conferences/{ConferenceSid}/Participants.json
# Returns: record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, participants: table<account_sid: string, call_sid: string, call_sid_to_coach: string, coaching: bool, conference_sid: string, date_created: string, date_updated: string, end_conference_on_exit: bool, hold: bool, label: string, muted: bool, start_conference_on_enter: bool, status: string, uri: string>, previous_page_uri: string, start: int, uri: string>
# operationId: ListParticipant
export def "list-participant" [
  account_sid: string
  conference_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --muted: oneof<nothing, bool> # Whether to return only participants that are muted. Can be: `true` or `false`.
  --hold: oneof<nothing, bool> # Whether to return only participants that are on hold. Can be: `true` or `false`.
  --coaching: oneof<nothing, bool> # Whether to return only participants who are coaching another call. Can be: `true` or `false`.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2010-04-01/Accounts/{AccountSid}/Conferences/{ConferenceSid}/Participants.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: ConferenceSid, var: conference_sid}]
    query: [{name: Muted, var: muted}, {name: Hold, var: hold}, {name: Coaching, var: coaching}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, conference_sid: $conference_sid, muted: $muted, hold: $hold, coaching: $coaching, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /2010-04-01/Accounts/{AccountSid}/Conferences/{ConferenceSid}/Participants.json
#
# Returns: record<account_sid: string, call_sid: string, call_sid_to_coach: string, coaching: bool, conference_sid: string, date_created: string, date_updated: string, end_conference_on_exit: bool, hold: bool, label: string, muted: bool, start_conference_on_enter: bool, status: string, uri: string>
# operationId: CreateParticipant
export def "create-participant" [
  account_sid: string
  conference_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --amd-status-callback: string # The URL that we should call using the `amd_status_callback_method` to notify customer application whether the call was answered by human, machine or fax. (format: uri)
  --amd-status-callback-method: string@amd-status-callback-method-completer # The HTTP method we should use when calling the `amd_status_callback` URL. Can be: `GET` or `POST` and the default is `POST`. (format: http-method)
  --beep: string # Whether to play a notification beep to the conference when the participant joins. Can be: `true`, `false`, `onEnter`, or `onExit`. The default value is `true`.
  --byoc: string # The SID of a BYOC (Bring Your Own Carrier) trunk to route this call with. Note that `byoc` is only meaningful when `to` is a phone number; it will otherwise be ignored. (Beta)
  --call-reason: string # The Reason for the outgoing call. Use it to specify the purpose of the call that is presented on the called party's phone. (Branded Calls Beta)
  --call-sid-to-coach: string # The SID of the participant who is being `coached`. The participant being coached is the only participant who can hear the participant who is `coaching`.
  --caller-id: string # The phone number, Client identifier, or username portion of SIP address that made this call. Phone numbers are in [E.164](https://www.twilio.com/docs/glossary/what-e164) format (e.g., +16175551212). Client identifiers are formatted `client:name`. If using a phone number, it must be a Twilio number or a Verified [outgoing caller id](https://www.twilio.com/docs/voice/api/outgoing-caller-ids) for your account. If the `to` parameter is a phone number, `callerId` must also be a phone number. If `to` is sip address, this value of `callerId` should be a username portion to be used to populate the From header that is passed to the SIP endpoint.
  --coaching: oneof<nothing, bool> # Whether the participant is coaching another call. Can be: `true` or `false`. If not present, defaults to `false` unless `call_sid_to_coach` is defined. If `true`, `call_sid_to_coach` must be defined.
  --conference-record: string # Whether to record the conference the participant is joining. Can be: `true`, `false`, `record-from-start`, and `do-not-record`. The default value is `false`.
  --conference-recording-status-callback: string # The URL we should call using the `conference_recording_status_callback_method` when the conference recording is available. (format: uri)
  --conference-recording-status-callback-event: list<string> # The conference recording state changes that generate a call to `conference_recording_status_callback`. Can be: `in-progress`, `completed`, `failed`, and `absent`. Separate multiple values with a space, ex: `'in-progress completed failed'`
  --conference-recording-status-callback-method: string@conference-recording-status-callback-method-completer # The HTTP method we should use to call `conference_recording_status_callback`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --conference-status-callback: string # The URL we should call using the `conference_status_callback_method` when the conference events in `conference_status_callback_event` occur. Only the value set by the first participant to join the conference is used. Subsequent `conference_status_callback` values are ignored. (format: uri)
  --conference-status-callback-event: list<string> # The conference state changes that should generate a call to `conference_status_callback`. Can be: `start`, `end`, `join`, `leave`, `mute`, `hold`, `modify`, `speaker`, and `announcement`. Separate multiple values with a space. Defaults to `start end`.
  --conference-status-callback-method: string@conference-status-callback-method-completer # The HTTP method we should use to call `conference_status_callback`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --conference-trim: string # Whether to trim leading and trailing silence from your recorded conference audio files. Can be: `trim-silence` or `do-not-trim` and defaults to `trim-silence`.
  --early-media: oneof<nothing, bool> # Whether to allow an agent to hear the state of the outbound call, including ringing or disconnect messages. Can be: `true` or `false` and defaults to `true`.
  --end-conference-on-exit: oneof<nothing, bool> # Whether to end the conference when the participant leaves. Can be: `true` or `false` and defaults to `false`.
  from: string # The phone number, Client identifier, or username portion of SIP address that made this call. Phone numbers are in [E.164](https://www.twilio.com/docs/glossary/what-e164) format (e.g., +16175551212). Client identifiers are formatted `client:name`. If using a phone number, it must be a Twilio number or a Verified [outgoing caller id](https://www.twilio.com/docs/voice/api/outgoing-caller-ids) for your account. If the `to` parameter is a phone number, `from` must also be a phone number. If `to` is sip address, this value of `from` should be a username portion to be used to populate the P-Asserted-Identity header that is passed to the SIP endpoint. (format: endpoint)
  --jitter-buffer-size: string # Jitter buffer size for the connecting participant. Twilio will use this setting to apply Jitter Buffer before participant's audio is mixed into the conference. Can be: `off`, `small`, `medium`, and `large`. Default to `large`.
  --label: string # A label for this participant. If one is supplied, it may subsequently be used to fetch, update or delete the participant.
  --machine-detection: string # Whether to detect if a human, answering machine, or fax has picked up the call. Can be: `Enable` or `DetectMessageEnd`. Use `Enable` if you would like us to return `AnsweredBy` as soon as the called party is identified. Use `DetectMessageEnd`, if you would like to leave a message on an answering machine. If `send_digits` is provided, this parameter is ignored. For more information, see [Answering Machine Detection](https://www.twilio.com/docs/voice/answering-machine-detection).
  --machine-detection-silence-timeout: int # The number of milliseconds of initial silence after which an `unknown` AnsweredBy result will be returned. Possible Values: 2000-10000. Default: 5000.
  --machine-detection-speech-end-threshold: int # The number of milliseconds of silence after speech activity at which point the speech activity is considered complete. Possible Values: 500-5000. Default: 1200.
  --machine-detection-speech-threshold: int # The number of milliseconds that is used as the measuring stick for the length of the speech activity, where durations lower than this value will be interpreted as a human and longer than this value as a machine. Possible Values: 1000-6000. Default: 2400.
  --machine-detection-timeout: int # The number of seconds that we should attempt to detect an answering machine before timing out and sending a voice request with `AnsweredBy` of `unknown`. The default timeout is 30 seconds.
  --max-participants: int # The maximum number of participants in the conference. Can be a positive integer from `2` to `250`. The default value is `250`.
  --muted: oneof<nothing, bool> # Whether the agent is muted in the conference. Can be `true` or `false` and the default is `false`.
  --record: oneof<nothing, bool> # Whether to record the participant and their conferences, including the time between conferences. Can be `true` or `false` and the default is `false`.
  --recording-channels: string # The recording channels for the final recording. Can be: `mono` or `dual` and the default is `mono`.
  --recording-status-callback: string # The URL that we should call using the `recording_status_callback_method` when the recording status changes. (format: uri)
  --recording-status-callback-event: list<string> # The recording state changes that should generate a call to `recording_status_callback`. Can be: `started`, `in-progress`, `paused`, `resumed`, `stopped`, `completed`, `failed`, and `absent`. Separate multiple values with a space, ex: `'in-progress completed failed'`.
  --recording-status-callback-method: string@recording-status-callback-method-completer # The HTTP method we should use when we call `recording_status_callback`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --recording-track: string # The audio track to record for the call. Can be: `inbound`, `outbound` or `both`. The default is `both`. `inbound` records the audio that is received by Twilio. `outbound` records the audio that is sent from Twilio. `both` records the audio that is received and sent by Twilio.
  --region: string # The [region](https://support.twilio.com/hc/en-us/articles/223132167-How-global-low-latency-routing-and-region-selection-work-for-conferences-and-Client-calls) where we should mix the recorded audio. Can be:`us1`, `ie1`, `de1`, `sg1`, `br1`, `au1`, or `jp1`.
  --sip-auth-password: string # The SIP password for authentication.
  --sip-auth-username: string # The SIP username used for authentication.
  --start-conference-on-enter: oneof<nothing, bool> # Whether to start the conference when the participant joins, if it has not already started. Can be: `true` or `false` and the default is `true`. If `false` and the conference has not started, the participant is muted and hears background music until another participant starts the conference.
  --status-callback: string # The URL we should call using the `status_callback_method` to send status information to your application. (format: uri)
  --status-callback-event: list<string> # The conference state changes that should generate a call to `status_callback`. Can be: `initiated`, `ringing`, `answered`, and `completed`. Separate multiple values with a space. The default value is `completed`.
  --status-callback-method: string@status-callback-method-completer # The HTTP method we should use to call `status_callback`. Can be: `GET` and `POST` and defaults to `POST`. (format: http-method)
  --time-limit: int # The maximum duration of the call in seconds. Constraints depend on account and configuration.
  --timeout: int # The number of seconds that we should allow the phone to ring before assuming there is no answer. Can be an integer between `5` and `600`, inclusive. The default value is `60`. We always add a 5-second timeout buffer to outgoing calls, so value of 10 would result in an actual timeout that was closer to 15 seconds.
  to: string # The phone number, SIP address, or Client identifier that received this call. Phone numbers are in [E.164](https://www.twilio.com/docs/glossary/what-e164) format (e.g., +16175551212). SIP addresses are formatted as `sip:name@company.com`. Client identifiers are formatted `client:name`. [Custom parameters](https://www.twilio.com/docs/voice/api/conference-participant-resource#custom-parameters) may also be specified. (format: endpoint)
  --wait-method: string@wait-method-completer # The HTTP method we should use to call `wait_url`. Can be `GET` or `POST` and the default is `POST`. When using a static audio file, this should be `GET` so that we can cache the file. (format: http-method)
  --wait-url: string # The URL we should call using the `wait_method` for the music to play while participants are waiting for the conference to start. The default value is the URL of our standard hold music. [Learn more about hold music](https://www.twilio.com/labs/twimlets/holdmusic). (format: uri)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2010-04-01/Accounts/{AccountSid}/Conferences/{ConferenceSid}/Participants.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: ConferenceSid, var: conference_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: AmdStatusCallback, var: amd_status_callback}, {name: AmdStatusCallbackMethod, var: amd_status_callback_method}, {name: Beep, var: beep}, {name: Byoc, var: byoc}, {name: CallReason, var: call_reason}, {name: CallSidToCoach, var: call_sid_to_coach}, {name: CallerId, var: caller_id}, {name: Coaching, var: coaching}, {name: ConferenceRecord, var: conference_record}, {name: ConferenceRecordingStatusCallback, var: conference_recording_status_callback}, {name: ConferenceRecordingStatusCallbackEvent, var: conference_recording_status_callback_event}, {name: ConferenceRecordingStatusCallbackMethod, var: conference_recording_status_callback_method}, {name: ConferenceStatusCallback, var: conference_status_callback}, {name: ConferenceStatusCallbackEvent, var: conference_status_callback_event}, {name: ConferenceStatusCallbackMethod, var: conference_status_callback_method}, {name: ConferenceTrim, var: conference_trim}, {name: EarlyMedia, var: early_media}, {name: EndConferenceOnExit, var: end_conference_on_exit}, {name: From, var: from}, {name: JitterBufferSize, var: jitter_buffer_size}, {name: Label, var: label}, {name: MachineDetection, var: machine_detection}, {name: MachineDetectionSilenceTimeout, var: machine_detection_silence_timeout}, {name: MachineDetectionSpeechEndThreshold, var: machine_detection_speech_end_threshold}, {name: MachineDetectionSpeechThreshold, var: machine_detection_speech_threshold}, {name: MachineDetectionTimeout, var: machine_detection_timeout}, {name: MaxParticipants, var: max_participants}, {name: Muted, var: muted}, {name: Record, var: record}, {name: RecordingChannels, var: recording_channels}, {name: RecordingStatusCallback, var: recording_status_callback}, {name: RecordingStatusCallbackEvent, var: recording_status_callback_event}, {name: RecordingStatusCallbackMethod, var: recording_status_callback_method}, {name: RecordingTrack, var: recording_track}, {name: Region, var: region}, {name: SipAuthPassword, var: sip_auth_password}, {name: SipAuthUsername, var: sip_auth_username}, {name: StartConferenceOnEnter, var: start_conference_on_enter}, {name: StatusCallback, var: status_callback}, {name: StatusCallbackEvent, var: status_callback_event}, {name: StatusCallbackMethod, var: status_callback_method}, {name: TimeLimit, var: time_limit}, {name: Timeout, var: timeout}, {name: To, var: to}, {name: WaitMethod, var: wait_method}, {name: WaitUrl, var: wait_url}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, conference_sid: $conference_sid, amd_status_callback: $amd_status_callback, amd_status_callback_method: $amd_status_callback_method, beep: $beep, byoc: $byoc, call_reason: $call_reason, call_sid_to_coach: $call_sid_to_coach, caller_id: $caller_id, coaching: $coaching, conference_record: $conference_record, conference_recording_status_callback: $conference_recording_status_callback, conference_recording_status_callback_event: $conference_recording_status_callback_event, conference_recording_status_callback_method: $conference_recording_status_callback_method, conference_status_callback: $conference_status_callback, conference_status_callback_event: $conference_status_callback_event, conference_status_callback_method: $conference_status_callback_method, conference_trim: $conference_trim, early_media: $early_media, end_conference_on_exit: $end_conference_on_exit, from: $from, jitter_buffer_size: $jitter_buffer_size, label: $label, machine_detection: $machine_detection, machine_detection_silence_timeout: $machine_detection_silence_timeout, machine_detection_speech_end_threshold: $machine_detection_speech_end_threshold, machine_detection_speech_threshold: $machine_detection_speech_threshold, machine_detection_timeout: $machine_detection_timeout, max_participants: $max_participants, muted: $muted, record: $record, recording_channels: $recording_channels, recording_status_callback: $recording_status_callback, recording_status_callback_event: $recording_status_callback_event, recording_status_callback_method: $recording_status_callback_method, recording_track: $recording_track, region: $region, sip_auth_password: $sip_auth_password, sip_auth_username: $sip_auth_username, start_conference_on_enter: $start_conference_on_enter, status_callback: $status_callback, status_callback_event: $status_callback_event, status_callback_method: $status_callback_method, time_limit: $time_limit, timeout: $timeout, to: $to, wait_method: $wait_method, wait_url: $wait_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Kick a participant from a given conference
#
# DELETE /2010-04-01/Accounts/{AccountSid}/Conferences/{ConferenceSid}/Participants/{CallSid}.json
# operationId: DeleteParticipant
export def "delete-participant" [
  account_sid: string
  conference_sid: string
  call_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/Conferences/{ConferenceSid}/Participants/{CallSid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: ConferenceSid, var: conference_sid}, {name: CallSid, var: call_sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, conference_sid: $conference_sid, call_sid: $call_sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch an instance of a participant
#
# GET /2010-04-01/Accounts/{AccountSid}/Conferences/{ConferenceSid}/Participants/{CallSid}.json
# Returns: record<account_sid: string, call_sid: string, call_sid_to_coach: string, coaching: bool, conference_sid: string, date_created: string, date_updated: string, end_conference_on_exit: bool, hold: bool, label: string, muted: bool, start_conference_on_enter: bool, status: string, uri: string>
# operationId: FetchParticipant
export def "fetch-participant" [
  account_sid: string
  conference_sid: string
  call_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/Conferences/{ConferenceSid}/Participants/{CallSid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: ConferenceSid, var: conference_sid}, {name: CallSid, var: call_sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, conference_sid: $conference_sid, call_sid: $call_sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the properties of the participant
#
# POST /2010-04-01/Accounts/{AccountSid}/Conferences/{ConferenceSid}/Participants/{CallSid}.json
# Returns: record<account_sid: string, call_sid: string, call_sid_to_coach: string, coaching: bool, conference_sid: string, date_created: string, date_updated: string, end_conference_on_exit: bool, hold: bool, label: string, muted: bool, start_conference_on_enter: bool, status: string, uri: string>
# operationId: UpdateParticipant
export def "update-participant" [
  account_sid: string
  conference_sid: string
  call_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --announce-method: string@announce-method-completer # The HTTP method we should use to call `announce_url`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --announce-url: string # The URL we call using the `announce_method` for an announcement to the participant. The URL may return an MP3 file, a WAV file, or a TwiML document that contains ``, ``, ``, or `` verbs. (format: uri)
  --beep-on-exit: oneof<nothing, bool> # Whether to play a notification beep to the conference when the participant exits. Can be: `true` or `false`.
  --call-sid-to-coach: string # The SID of the participant who is being `coached`. The participant being coached is the only participant who can hear the participant who is `coaching`.
  --coaching: oneof<nothing, bool> # Whether the participant is coaching another call. Can be: `true` or `false`. If not present, defaults to `false` unless `call_sid_to_coach` is defined. If `true`, `call_sid_to_coach` must be defined.
  --end-conference-on-exit: oneof<nothing, bool> # Whether to end the conference when the participant leaves. Can be: `true` or `false` and defaults to `false`.
  --hold: oneof<nothing, bool> # Whether the participant should be on hold. Can be: `true` or `false`. `true` puts the participant on hold, and `false` lets them rejoin the conference.
  --hold-method: string@hold-method-completer # The HTTP method we should use to call `hold_url`. Can be: `GET` or `POST` and the default is `GET`. (format: http-method)
  --hold-url: string # The URL we call using the `hold_method` for music that plays when the participant is on hold. The URL may return an MP3 file, a WAV file, or a TwiML document that contains ``, ``, ``, or `` verbs. (format: uri)
  --muted: oneof<nothing, bool> # Whether the participant should be muted. Can be `true` or `false`. `true` will mute the participant, and `false` will un-mute them. Anything value other than `true` or `false` is interpreted as `false`.
  --wait-method: string@wait-method-completer # The HTTP method we should use to call `wait_url`. Can be `GET` or `POST` and the default is `POST`. When using a static audio file, this should be `GET` so that we can cache the file. (format: http-method)
  --wait-url: string # The URL we call using the `wait_method` for the music to play while participants are waiting for the conference to start. The URL may return an MP3 file, a WAV file, or a TwiML document that contains ``, ``, ``, or `` verbs. The default value is the URL of our standard hold music. [Learn more about hold music](https://www.twilio.com/labs/twimlets/holdmusic). (format: uri)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2010-04-01/Accounts/{AccountSid}/Conferences/{ConferenceSid}/Participants/{CallSid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: ConferenceSid, var: conference_sid}, {name: CallSid, var: call_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: AnnounceMethod, var: announce_method}, {name: AnnounceUrl, var: announce_url}, {name: BeepOnExit, var: beep_on_exit}, {name: CallSidToCoach, var: call_sid_to_coach}, {name: Coaching, var: coaching}, {name: EndConferenceOnExit, var: end_conference_on_exit}, {name: Hold, var: hold}, {name: HoldMethod, var: hold_method}, {name: HoldUrl, var: hold_url}, {name: Muted, var: muted}, {name: WaitMethod, var: wait_method}, {name: WaitUrl, var: wait_url}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, conference_sid: $conference_sid, call_sid: $call_sid, announce_method: $announce_method, announce_url: $announce_url, beep_on_exit: $beep_on_exit, call_sid_to_coach: $call_sid_to_coach, coaching: $coaching, end_conference_on_exit: $end_conference_on_exit, hold: $hold, hold_method: $hold_method, hold_url: $hold_url, muted: $muted, wait_method: $wait_method, wait_url: $wait_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of recordings belonging to the call used to make the request
#
# GET /2010-04-01/Accounts/{AccountSid}/Conferences/{ConferenceSid}/Recordings.json
# Returns: record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, recordings: table<account_sid: string, api_version: string, call_sid: string, channels: int, conference_sid: string, date_created: string, date_updated: string, duration: string, encryption_details: any, error_code: int, price: string, price_unit: string, sid: string, source: string, start_time: string, status: string, uri: string>, start: int, uri: string>
# operationId: ListConferenceRecording
export def "list-conference-recording" [
  account_sid: string
  conference_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-created: string # The `date_created` value, specified as `YYYY-MM-DD`, of the resources to read. You can also specify inequality: `DateCreated<=YYYY-MM-DD` will return recordings generated at or before midnight on a given date, and `DateCreated>=YYYY-MM-DD` returns recordings generated at or after midnight on a date. (format: date)
  --qp-date-created: string # The `date_created` value, specified as `YYYY-MM-DD`, of the resources to read. You can also specify inequality: `DateCreated<=YYYY-MM-DD` will return recordings generated at or before midnight on a given date, and `DateCreated>=YYYY-MM-DD` returns recordings generated at or after midnight on a date. (format: date) (spec name: DateCreated<)
  --qp-date-created-2: string # The `date_created` value, specified as `YYYY-MM-DD`, of the resources to read. You can also specify inequality: `DateCreated<=YYYY-MM-DD` will return recordings generated at or before midnight on a given date, and `DateCreated>=YYYY-MM-DD` returns recordings generated at or after midnight on a date. (format: date) (spec name: DateCreated>)
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2010-04-01/Accounts/{AccountSid}/Conferences/{ConferenceSid}/Recordings.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: ConferenceSid, var: conference_sid}]
    query: [{name: DateCreated, var: date_created}, {name: "DateCreated<", var: qp_date_created}, {name: "DateCreated>", var: qp_date_created_2}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, conference_sid: $conference_sid, date_created: $date_created, qp_date_created: $qp_date_created, qp_date_created_2: $qp_date_created_2, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a recording from your account
#
# DELETE /2010-04-01/Accounts/{AccountSid}/Conferences/{ConferenceSid}/Recordings/{Sid}.json
# operationId: DeleteConferenceRecording
export def "delete-conference-recording" [
  account_sid: string
  conference_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/Conferences/{ConferenceSid}/Recordings/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: ConferenceSid, var: conference_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, conference_sid: $conference_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch an instance of a recording for a call
#
# GET /2010-04-01/Accounts/{AccountSid}/Conferences/{ConferenceSid}/Recordings/{Sid}.json
# Returns: record<account_sid: string, api_version: string, call_sid: string, channels: int, conference_sid: string, date_created: string, date_updated: string, duration: string, encryption_details: any, error_code: int, price: string, price_unit: string, sid: string, source: string, start_time: string, status: string, uri: string>
# operationId: FetchConferenceRecording
export def "fetch-conference-recording" [
  account_sid: string
  conference_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/Conferences/{ConferenceSid}/Recordings/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: ConferenceSid, var: conference_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, conference_sid: $conference_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Changes the status of the recording to paused, stopped, or in-progress. Note: To use `Twilio.CURRENT`, pass it as recording sid.
#
# POST /2010-04-01/Accounts/{AccountSid}/Conferences/{ConferenceSid}/Recordings/{Sid}.json
# Returns: record<account_sid: string, api_version: string, call_sid: string, channels: int, conference_sid: string, date_created: string, date_updated: string, duration: string, encryption_details: any, error_code: int, price: string, price_unit: string, sid: string, source: string, start_time: string, status: string, uri: string>
# operationId: UpdateConferenceRecording
export def "update-conference-recording" [
  account_sid: string
  conference_sid: string
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
  --pause-behavior: string # Whether to record during a pause. Can be: `skip` or `silence` and the default is `silence`. `skip` does not record during the pause period, while `silence` will replace the actual audio of the call with silence during the pause period. This parameter only applies when setting `status` is set to `paused`.
  status: string@status-completer-3
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2010-04-01/Accounts/{AccountSid}/Conferences/{ConferenceSid}/Recordings/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: ConferenceSid, var: conference_sid}, {name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: PauseBehavior, var: pause_behavior}, {name: Status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, conference_sid: $conference_sid, sid: $sid, pause_behavior: $pause_behavior, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch an instance of a conference
#
# GET /2010-04-01/Accounts/{AccountSid}/Conferences/{Sid}.json
# Returns: record<account_sid: string, api_version: string, call_sid_ending_conference: string, date_created: string, date_updated: string, friendly_name: string, reason_conference_ended: string, region: string, sid: string, status: string, subresource_uris: record, uri: string>
# operationId: FetchConference
export def "fetch-conference" [
  account_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/Conferences/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /2010-04-01/Accounts/{AccountSid}/Conferences/{Sid}.json
#
# Returns: record<account_sid: string, api_version: string, call_sid_ending_conference: string, date_created: string, date_updated: string, friendly_name: string, reason_conference_ended: string, region: string, sid: string, status: string, subresource_uris: record, uri: string>
# operationId: UpdateConference
export def "update-conference" [
  account_sid: string
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
  --announce-method: string@announce-method-completer # The HTTP method used to call `announce_url`. Can be: `GET` or `POST` and the default is `POST` (format: http-method)
  --announce-url: string # The URL we should call to announce something into the conference. The URL may return an MP3 file, a WAV file, or a TwiML document that contains ``, ``, ``, or `` verbs. (format: uri)
  --status: string@status-completer-7
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2010-04-01/Accounts/{AccountSid}/Conferences/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: AnnounceMethod, var: announce_method}, {name: AnnounceUrl, var: announce_url}, {name: Status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, sid: $sid, announce_method: $announce_method, announce_url: $announce_url, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of connect-apps belonging to the account used to make the request
#
# GET /2010-04-01/Accounts/{AccountSid}/ConnectApps.json
# Returns: record<connect_apps: table<account_sid: string, authorize_redirect_url: string, company_name: string, deauthorize_callback_method: string, deauthorize_callback_url: string, description: string, friendly_name: string, homepage_url: string, permissions: list, sid: string, uri: string>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>
# operationId: ListConnectApp
export def "list-connect-app" [
  account_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/ConnectApps.json"
    path_params: [{name: AccountSid, var: account_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an instance of a connect-app
#
# DELETE /2010-04-01/Accounts/{AccountSid}/ConnectApps/{Sid}.json
# operationId: DeleteConnectApp
export def "delete-connect-app" [
  account_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/ConnectApps/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch an instance of a connect-app
#
# GET /2010-04-01/Accounts/{AccountSid}/ConnectApps/{Sid}.json
# Returns: record<account_sid: string, authorize_redirect_url: string, company_name: string, deauthorize_callback_method: string, deauthorize_callback_url: string, description: string, friendly_name: string, homepage_url: string, permissions: list<string>, sid: string, uri: string>
# operationId: FetchConnectApp
export def "fetch-connect-app" [
  account_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/ConnectApps/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a connect-app with the specified parameters
#
# POST /2010-04-01/Accounts/{AccountSid}/ConnectApps/{Sid}.json
# Returns: record<account_sid: string, authorize_redirect_url: string, company_name: string, deauthorize_callback_method: string, deauthorize_callback_url: string, description: string, friendly_name: string, homepage_url: string, permissions: list<string>, sid: string, uri: string>
# operationId: UpdateConnectApp
export def "update-connect-app" [
  account_sid: string
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
  --authorize-redirect-url: string # The URL to redirect the user to after we authenticate the user and obtain authorization to access the Connect App. (format: uri)
  --company-name: string # The company name to set for the Connect App.
  --deauthorize-callback-method: string@deauthorize-callback-method-completer # The HTTP method to use when calling `deauthorize_callback_url`. (format: http-method)
  --deauthorize-callback-url: string # The URL to call using the `deauthorize_callback_method` to de-authorize the Connect App. (format: uri)
  --description: string # A description of the Connect App.
  --friendly-name: string # A descriptive string that you create to describe the resource. It can be up to 64 characters long.
  --homepage-url: string # A public URL where users can obtain more information about this Connect App. (format: uri)
  --permissions: list<string> # A comma-separated list of the permissions you will request from the users of this ConnectApp. Can include: `get-all` and `post-all`.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2010-04-01/Accounts/{AccountSid}/ConnectApps/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: AuthorizeRedirectUrl, var: authorize_redirect_url}, {name: CompanyName, var: company_name}, {name: DeauthorizeCallbackMethod, var: deauthorize_callback_method}, {name: DeauthorizeCallbackUrl, var: deauthorize_callback_url}, {name: Description, var: description}, {name: FriendlyName, var: friendly_name}, {name: HomepageUrl, var: homepage_url}, {name: Permissions, var: permissions}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, sid: $sid, authorize_redirect_url: $authorize_redirect_url, company_name: $company_name, deauthorize_callback_method: $deauthorize_callback_method, deauthorize_callback_url: $deauthorize_callback_url, description: $description, friendly_name: $friendly_name, homepage_url: $homepage_url, permissions: $permissions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of incoming-phone-numbers belonging to the account used to make the request.
#
# GET /2010-04-01/Accounts/{AccountSid}/IncomingPhoneNumbers.json
# Returns: record<end: int, first_page_uri: string, incoming_phone_numbers: table<account_sid: string, address_requirements: string, address_sid: string, api_version: string, beta: bool, bundle_sid: string, capabilities: record, date_created: string, date_updated: string, emergency_address_sid: string, emergency_address_status: string, emergency_status: string, friendly_name: string, identity_sid: string, origin: string, phone_number: string, sid: string, sms_application_sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, status: string, status_callback: string, status_callback_method: string, trunk_sid: string, uri: string, voice_application_sid: string, voice_caller_id_lookup: bool, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_receive_mode: string, voice_url: string>, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>
# operationId: ListIncomingPhoneNumber
export def "list-incoming-phone-number" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --beta: oneof<nothing, bool> # Whether to include phone numbers new to the Twilio platform. Can be: `true` or `false` and the default is `true`.
  --friendly-name: string # A string that identifies the IncomingPhoneNumber resources to read.
  --phone-number: string # The phone numbers of the IncomingPhoneNumber resources to read. You can specify partial numbers and use '*' as a wildcard for any digit. (format: phone-number)
  --origin: string # Whether to include phone numbers based on their origin. Can be: `twilio` or `hosted`. By default, phone numbers of all origin are included.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2010-04-01/Accounts/{AccountSid}/IncomingPhoneNumbers.json"
    path_params: [{name: AccountSid, var: account_sid}]
    query: [{name: Beta, var: beta}, {name: FriendlyName, var: friendly_name}, {name: PhoneNumber, var: phone_number}, {name: Origin, var: origin}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, beta: $beta, friendly_name: $friendly_name, phone_number: $phone_number, origin: $origin, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Purchase a phone-number for the account.
#
# POST /2010-04-01/Accounts/{AccountSid}/IncomingPhoneNumbers.json
# Returns: record<account_sid: string, address_requirements: string, address_sid: string, api_version: string, beta: bool, bundle_sid: string, capabilities: record<fax: bool, mms: bool, sms: bool, voice: bool>, date_created: string, date_updated: string, emergency_address_sid: string, emergency_address_status: string, emergency_status: string, friendly_name: string, identity_sid: string, origin: string, phone_number: string, sid: string, sms_application_sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, status: string, status_callback: string, status_callback_method: string, trunk_sid: string, uri: string, voice_application_sid: string, voice_caller_id_lookup: bool, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_receive_mode: string, voice_url: string>
# operationId: CreateIncomingPhoneNumber
export def "create-incoming-phone-number" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address-sid: string # The SID of the Address resource we should associate with the new phone number. Some regions require addresses to meet local regulations.
  --api-version: string # The API version to use for incoming calls made to the new phone number. The default is `2010-04-01`.
  --area-code: string # The desired area code for your new incoming phone number. Can be any three-digit, US or Canada area code. We will provision an available phone number within this area code for you. **You must provide an `area_code` or a `phone_number`.** (US and Canada only).
  --bundle-sid: string # The SID of the Bundle resource that you associate with the phone number. Some regions require a Bundle to meet local Regulations.
  --emergency-address-sid: string # The SID of the emergency address configuration to use for emergency calling from the new phone number.
  --emergency-status: string@emergency-status-completer
  --friendly-name: string # A descriptive string that you created to describe the new phone number. It can be up to 64 characters long. By default, this is a formatted version of the new phone number.
  --identity-sid: string # The SID of the Identity resource that we should associate with the new phone number. Some regions require an identity to meet local regulations.
  --phone-number: string # The phone number to purchase specified in [E.164](https://www.twilio.com/docs/glossary/what-e164) format. E.164 phone numbers consist of a + followed by the country code and subscriber number without punctuation characters. For example, +14155551234. (format: phone-number)
  --sms-application-sid: string # The SID of the application that should handle SMS messages sent to the new phone number. If an `sms_application_sid` is present, we ignore all of the `sms_*_url` urls and use those set on the application.
  --sms-fallback-method: string@sms-fallback-method-completer # The HTTP method that we should use to call `sms_fallback_url`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --sms-fallback-url: string # The URL that we should call when an error occurs while requesting or executing the TwiML defined by `sms_url`. (format: uri)
  --sms-method: string@sms-method-completer # The HTTP method that we should use to call `sms_url`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --sms-url: string # The URL we should call when the new phone number receives an incoming SMS message. (format: uri)
  --status-callback: string # The URL we should call using the `status_callback_method` to send status information to your application. (format: uri)
  --status-callback-method: string@status-callback-method-completer # The HTTP method we should use to call `status_callback`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --trunk-sid: string # The SID of the Trunk we should use to handle calls to the new phone number. If a `trunk_sid` is present, we ignore all of the voice urls and voice applications and use only those set on the Trunk. Setting a `trunk_sid` will automatically delete your `voice_application_sid` and vice versa.
  --voice-application-sid: string # The SID of the application we should use to handle calls to the new phone number. If a `voice_application_sid` is present, we ignore all of the voice urls and use only those set on the application. Setting a `voice_application_sid` will automatically delete your `trunk_sid` and vice versa.
  --voice-caller-id-lookup: oneof<nothing, bool> # Whether to lookup the caller's name from the CNAM database and post it to your app. Can be: `true` or `false` and defaults to `false`.
  --voice-fallback-method: string@voice-fallback-method-completer # The HTTP method that we should use to call `voice_fallback_url`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --voice-fallback-url: string # The URL that we should call when an error occurs retrieving or executing the TwiML requested by `url`. (format: uri)
  --voice-method: string@voice-method-completer # The HTTP method that we should use to call `voice_url`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --voice-receive-mode: string@voice-receive-mode-completer
  --voice-url: string # The URL that we should call to answer a call to the new phone number. The `voice_url` will not be called if a `voice_application_sid` or a `trunk_sid` is set. (format: uri)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2010-04-01/Accounts/{AccountSid}/IncomingPhoneNumbers.json"
    path_params: [{name: AccountSid, var: account_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: AddressSid, var: address_sid}, {name: ApiVersion, var: api_version}, {name: AreaCode, var: area_code}, {name: BundleSid, var: bundle_sid}, {name: EmergencyAddressSid, var: emergency_address_sid}, {name: EmergencyStatus, var: emergency_status}, {name: FriendlyName, var: friendly_name}, {name: IdentitySid, var: identity_sid}, {name: PhoneNumber, var: phone_number}, {name: SmsApplicationSid, var: sms_application_sid}, {name: SmsFallbackMethod, var: sms_fallback_method}, {name: SmsFallbackUrl, var: sms_fallback_url}, {name: SmsMethod, var: sms_method}, {name: SmsUrl, var: sms_url}, {name: StatusCallback, var: status_callback}, {name: StatusCallbackMethod, var: status_callback_method}, {name: TrunkSid, var: trunk_sid}, {name: VoiceApplicationSid, var: voice_application_sid}, {name: VoiceCallerIdLookup, var: voice_caller_id_lookup}, {name: VoiceFallbackMethod, var: voice_fallback_method}, {name: VoiceFallbackUrl, var: voice_fallback_url}, {name: VoiceMethod, var: voice_method}, {name: VoiceReceiveMode, var: voice_receive_mode}, {name: VoiceUrl, var: voice_url}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, address_sid: $address_sid, api_version: $api_version, area_code: $area_code, bundle_sid: $bundle_sid, emergency_address_sid: $emergency_address_sid, emergency_status: $emergency_status, friendly_name: $friendly_name, identity_sid: $identity_sid, phone_number: $phone_number, sms_application_sid: $sms_application_sid, sms_fallback_method: $sms_fallback_method, sms_fallback_url: $sms_fallback_url, sms_method: $sms_method, sms_url: $sms_url, status_callback: $status_callback, status_callback_method: $status_callback_method, trunk_sid: $trunk_sid, voice_application_sid: $voice_application_sid, voice_caller_id_lookup: $voice_caller_id_lookup, voice_fallback_method: $voice_fallback_method, voice_fallback_url: $voice_fallback_url, voice_method: $voice_method, voice_receive_mode: $voice_receive_mode, voice_url: $voice_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /2010-04-01/Accounts/{AccountSid}/IncomingPhoneNumbers/Local.json
#
# Returns: record<end: int, first_page_uri: string, incoming_phone_numbers: table<account_sid: string, address_requirements: string, address_sid: string, api_version: string, beta: bool, bundle_sid: string, capabilities: record, date_created: string, date_updated: string, emergency_address_sid: string, emergency_address_status: string, emergency_status: string, friendly_name: string, identity_sid: string, origin: string, phone_number: string, sid: string, sms_application_sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, status: string, status_callback: string, status_callback_method: string, trunk_sid: string, uri: string, voice_application_sid: string, voice_caller_id_lookup: bool, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_receive_mode: string, voice_url: string>, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>
# operationId: ListIncomingPhoneNumberLocal
export def "list-incoming-phone-number-local" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --beta: oneof<nothing, bool> # Whether to include phone numbers new to the Twilio platform. Can be: `true` or `false` and the default is `true`.
  --friendly-name: string # A string that identifies the resources to read.
  --phone-number: string # The phone numbers of the IncomingPhoneNumber resources to read. You can specify partial numbers and use '*' as a wildcard for any digit. (format: phone-number)
  --origin: string # Whether to include phone numbers based on their origin. Can be: `twilio` or `hosted`. By default, phone numbers of all origin are included.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2010-04-01/Accounts/{AccountSid}/IncomingPhoneNumbers/Local.json"
    path_params: [{name: AccountSid, var: account_sid}]
    query: [{name: Beta, var: beta}, {name: FriendlyName, var: friendly_name}, {name: PhoneNumber, var: phone_number}, {name: Origin, var: origin}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, beta: $beta, friendly_name: $friendly_name, phone_number: $phone_number, origin: $origin, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /2010-04-01/Accounts/{AccountSid}/IncomingPhoneNumbers/Local.json
#
# Returns: record<account_sid: string, address_requirements: string, address_sid: string, api_version: string, beta: bool, bundle_sid: string, capabilities: record<fax: bool, mms: bool, sms: bool, voice: bool>, date_created: string, date_updated: string, emergency_address_sid: string, emergency_address_status: string, emergency_status: string, friendly_name: string, identity_sid: string, origin: string, phone_number: string, sid: string, sms_application_sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, status: string, status_callback: string, status_callback_method: string, trunk_sid: string, uri: string, voice_application_sid: string, voice_caller_id_lookup: bool, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_receive_mode: string, voice_url: string>
# operationId: CreateIncomingPhoneNumberLocal
export def "create-incoming-phone-number-local" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address-sid: string # The SID of the Address resource we should associate with the new phone number. Some regions require addresses to meet local regulations.
  --api-version: string # The API version to use for incoming calls made to the new phone number. The default is `2010-04-01`.
  --bundle-sid: string # The SID of the Bundle resource that you associate with the phone number. Some regions require a Bundle to meet local Regulations.
  --emergency-address-sid: string # The SID of the emergency address configuration to use for emergency calling from the new phone number.
  --emergency-status: string@emergency-status-completer
  --friendly-name: string # A descriptive string that you created to describe the new phone number. It can be up to 64 characters long. By default, this is a formatted version of the phone number.
  --identity-sid: string # The SID of the Identity resource that we should associate with the new phone number. Some regions require an identity to meet local regulations.
  phone_number: string # The phone number to purchase specified in [E.164](https://www.twilio.com/docs/glossary/what-e164) format. E.164 phone numbers consist of a + followed by the country code and subscriber number without punctuation characters. For example, +14155551234. (format: phone-number)
  --sms-application-sid: string # The SID of the application that should handle SMS messages sent to the new phone number. If an `sms_application_sid` is present, we ignore all of the `sms_*_url` urls and use those set on the application.
  --sms-fallback-method: string@sms-fallback-method-completer # The HTTP method that we should use to call `sms_fallback_url`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --sms-fallback-url: string # The URL that we should call when an error occurs while requesting or executing the TwiML defined by `sms_url`. (format: uri)
  --sms-method: string@sms-method-completer # The HTTP method that we should use to call `sms_url`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --sms-url: string # The URL we should call when the new phone number receives an incoming SMS message. (format: uri)
  --status-callback: string # The URL we should call using the `status_callback_method` to send status information to your application. (format: uri)
  --status-callback-method: string@status-callback-method-completer # The HTTP method we should use to call `status_callback`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --trunk-sid: string # The SID of the Trunk we should use to handle calls to the new phone number. If a `trunk_sid` is present, we ignore all of the voice urls and voice applications and use only those set on the Trunk. Setting a `trunk_sid` will automatically delete your `voice_application_sid` and vice versa.
  --voice-application-sid: string # The SID of the application we should use to handle calls to the new phone number. If a `voice_application_sid` is present, we ignore all of the voice urls and use only those set on the application. Setting a `voice_application_sid` will automatically delete your `trunk_sid` and vice versa.
  --voice-caller-id-lookup: oneof<nothing, bool> # Whether to lookup the caller's name from the CNAM database and post it to your app. Can be: `true` or `false` and defaults to `false`.
  --voice-fallback-method: string@voice-fallback-method-completer # The HTTP method that we should use to call `voice_fallback_url`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --voice-fallback-url: string # The URL that we should call when an error occurs retrieving or executing the TwiML requested by `url`. (format: uri)
  --voice-method: string@voice-method-completer # The HTTP method that we should use to call `voice_url`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --voice-receive-mode: string@voice-receive-mode-completer
  --voice-url: string # The URL that we should call to answer a call to the new phone number. The `voice_url` will not be called if a `voice_application_sid` or a `trunk_sid` is set. (format: uri)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2010-04-01/Accounts/{AccountSid}/IncomingPhoneNumbers/Local.json"
    path_params: [{name: AccountSid, var: account_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: AddressSid, var: address_sid}, {name: ApiVersion, var: api_version}, {name: BundleSid, var: bundle_sid}, {name: EmergencyAddressSid, var: emergency_address_sid}, {name: EmergencyStatus, var: emergency_status}, {name: FriendlyName, var: friendly_name}, {name: IdentitySid, var: identity_sid}, {name: PhoneNumber, var: phone_number}, {name: SmsApplicationSid, var: sms_application_sid}, {name: SmsFallbackMethod, var: sms_fallback_method}, {name: SmsFallbackUrl, var: sms_fallback_url}, {name: SmsMethod, var: sms_method}, {name: SmsUrl, var: sms_url}, {name: StatusCallback, var: status_callback}, {name: StatusCallbackMethod, var: status_callback_method}, {name: TrunkSid, var: trunk_sid}, {name: VoiceApplicationSid, var: voice_application_sid}, {name: VoiceCallerIdLookup, var: voice_caller_id_lookup}, {name: VoiceFallbackMethod, var: voice_fallback_method}, {name: VoiceFallbackUrl, var: voice_fallback_url}, {name: VoiceMethod, var: voice_method}, {name: VoiceReceiveMode, var: voice_receive_mode}, {name: VoiceUrl, var: voice_url}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, address_sid: $address_sid, api_version: $api_version, bundle_sid: $bundle_sid, emergency_address_sid: $emergency_address_sid, emergency_status: $emergency_status, friendly_name: $friendly_name, identity_sid: $identity_sid, phone_number: $phone_number, sms_application_sid: $sms_application_sid, sms_fallback_method: $sms_fallback_method, sms_fallback_url: $sms_fallback_url, sms_method: $sms_method, sms_url: $sms_url, status_callback: $status_callback, status_callback_method: $status_callback_method, trunk_sid: $trunk_sid, voice_application_sid: $voice_application_sid, voice_caller_id_lookup: $voice_caller_id_lookup, voice_fallback_method: $voice_fallback_method, voice_fallback_url: $voice_fallback_url, voice_method: $voice_method, voice_receive_mode: $voice_receive_mode, voice_url: $voice_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /2010-04-01/Accounts/{AccountSid}/IncomingPhoneNumbers/Mobile.json
#
# Returns: record<end: int, first_page_uri: string, incoming_phone_numbers: table<account_sid: string, address_requirements: string, address_sid: string, api_version: string, beta: bool, bundle_sid: string, capabilities: record, date_created: string, date_updated: string, emergency_address_sid: string, emergency_address_status: string, emergency_status: string, friendly_name: string, identity_sid: string, origin: string, phone_number: string, sid: string, sms_application_sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, status: string, status_callback: string, status_callback_method: string, trunk_sid: string, uri: string, voice_application_sid: string, voice_caller_id_lookup: bool, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_receive_mode: string, voice_url: string>, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>
# operationId: ListIncomingPhoneNumberMobile
export def "list-incoming-phone-number-mobile" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --beta: oneof<nothing, bool> # Whether to include phone numbers new to the Twilio platform. Can be: `true` or `false` and the default is `true`.
  --friendly-name: string # A string that identifies the resources to read.
  --phone-number: string # The phone numbers of the IncomingPhoneNumber resources to read. You can specify partial numbers and use '*' as a wildcard for any digit. (format: phone-number)
  --origin: string # Whether to include phone numbers based on their origin. Can be: `twilio` or `hosted`. By default, phone numbers of all origin are included.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2010-04-01/Accounts/{AccountSid}/IncomingPhoneNumbers/Mobile.json"
    path_params: [{name: AccountSid, var: account_sid}]
    query: [{name: Beta, var: beta}, {name: FriendlyName, var: friendly_name}, {name: PhoneNumber, var: phone_number}, {name: Origin, var: origin}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, beta: $beta, friendly_name: $friendly_name, phone_number: $phone_number, origin: $origin, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /2010-04-01/Accounts/{AccountSid}/IncomingPhoneNumbers/Mobile.json
#
# Returns: record<account_sid: string, address_requirements: string, address_sid: string, api_version: string, beta: bool, bundle_sid: string, capabilities: record<fax: bool, mms: bool, sms: bool, voice: bool>, date_created: string, date_updated: string, emergency_address_sid: string, emergency_address_status: string, emergency_status: string, friendly_name: string, identity_sid: string, origin: string, phone_number: string, sid: string, sms_application_sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, status: string, status_callback: string, status_callback_method: string, trunk_sid: string, uri: string, voice_application_sid: string, voice_caller_id_lookup: bool, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_receive_mode: string, voice_url: string>
# operationId: CreateIncomingPhoneNumberMobile
export def "create-incoming-phone-number-mobile" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address-sid: string # The SID of the Address resource we should associate with the new phone number. Some regions require addresses to meet local regulations.
  --api-version: string # The API version to use for incoming calls made to the new phone number. The default is `2010-04-01`.
  --bundle-sid: string # The SID of the Bundle resource that you associate with the phone number. Some regions require a Bundle to meet local Regulations.
  --emergency-address-sid: string # The SID of the emergency address configuration to use for emergency calling from the new phone number.
  --emergency-status: string@emergency-status-completer
  --friendly-name: string # A descriptive string that you created to describe the new phone number. It can be up to 64 characters long. By default, the is a formatted version of the phone number.
  --identity-sid: string # The SID of the Identity resource that we should associate with the new phone number. Some regions require an identity to meet local regulations.
  phone_number: string # The phone number to purchase specified in [E.164](https://www.twilio.com/docs/glossary/what-e164) format. E.164 phone numbers consist of a + followed by the country code and subscriber number without punctuation characters. For example, +14155551234. (format: phone-number)
  --sms-application-sid: string # The SID of the application that should handle SMS messages sent to the new phone number. If an `sms_application_sid` is present, we ignore all of the `sms_*_url` urls and use those of the application.
  --sms-fallback-method: string@sms-fallback-method-completer # The HTTP method that we should use to call `sms_fallback_url`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --sms-fallback-url: string # The URL that we should call when an error occurs while requesting or executing the TwiML defined by `sms_url`. (format: uri)
  --sms-method: string@sms-method-completer # The HTTP method that we should use to call `sms_url`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --sms-url: string # The URL we should call when the new phone number receives an incoming SMS message. (format: uri)
  --status-callback: string # The URL we should call using the `status_callback_method` to send status information to your application. (format: uri)
  --status-callback-method: string@status-callback-method-completer # The HTTP method we should use to call `status_callback`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --trunk-sid: string # The SID of the Trunk we should use to handle calls to the new phone number. If a `trunk_sid` is present, we ignore all of the voice urls and voice applications and use only those set on the Trunk. Setting a `trunk_sid` will automatically delete your `voice_application_sid` and vice versa.
  --voice-application-sid: string # The SID of the application we should use to handle calls to the new phone number. If a `voice_application_sid` is present, we ignore all of the voice urls and use only those set on the application. Setting a `voice_application_sid` will automatically delete your `trunk_sid` and vice versa.
  --voice-caller-id-lookup: oneof<nothing, bool> # Whether to lookup the caller's name from the CNAM database and post it to your app. Can be: `true` or `false` and defaults to `false`.
  --voice-fallback-method: string@voice-fallback-method-completer # The HTTP method that we should use to call `voice_fallback_url`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --voice-fallback-url: string # The URL that we should call when an error occurs retrieving or executing the TwiML requested by `url`. (format: uri)
  --voice-method: string@voice-method-completer # The HTTP method that we should use to call `voice_url`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --voice-receive-mode: string@voice-receive-mode-completer
  --voice-url: string # The URL that we should call to answer a call to the new phone number. The `voice_url` will not be called if a `voice_application_sid` or a `trunk_sid` is set. (format: uri)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2010-04-01/Accounts/{AccountSid}/IncomingPhoneNumbers/Mobile.json"
    path_params: [{name: AccountSid, var: account_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: AddressSid, var: address_sid}, {name: ApiVersion, var: api_version}, {name: BundleSid, var: bundle_sid}, {name: EmergencyAddressSid, var: emergency_address_sid}, {name: EmergencyStatus, var: emergency_status}, {name: FriendlyName, var: friendly_name}, {name: IdentitySid, var: identity_sid}, {name: PhoneNumber, var: phone_number}, {name: SmsApplicationSid, var: sms_application_sid}, {name: SmsFallbackMethod, var: sms_fallback_method}, {name: SmsFallbackUrl, var: sms_fallback_url}, {name: SmsMethod, var: sms_method}, {name: SmsUrl, var: sms_url}, {name: StatusCallback, var: status_callback}, {name: StatusCallbackMethod, var: status_callback_method}, {name: TrunkSid, var: trunk_sid}, {name: VoiceApplicationSid, var: voice_application_sid}, {name: VoiceCallerIdLookup, var: voice_caller_id_lookup}, {name: VoiceFallbackMethod, var: voice_fallback_method}, {name: VoiceFallbackUrl, var: voice_fallback_url}, {name: VoiceMethod, var: voice_method}, {name: VoiceReceiveMode, var: voice_receive_mode}, {name: VoiceUrl, var: voice_url}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, address_sid: $address_sid, api_version: $api_version, bundle_sid: $bundle_sid, emergency_address_sid: $emergency_address_sid, emergency_status: $emergency_status, friendly_name: $friendly_name, identity_sid: $identity_sid, phone_number: $phone_number, sms_application_sid: $sms_application_sid, sms_fallback_method: $sms_fallback_method, sms_fallback_url: $sms_fallback_url, sms_method: $sms_method, sms_url: $sms_url, status_callback: $status_callback, status_callback_method: $status_callback_method, trunk_sid: $trunk_sid, voice_application_sid: $voice_application_sid, voice_caller_id_lookup: $voice_caller_id_lookup, voice_fallback_method: $voice_fallback_method, voice_fallback_url: $voice_fallback_url, voice_method: $voice_method, voice_receive_mode: $voice_receive_mode, voice_url: $voice_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /2010-04-01/Accounts/{AccountSid}/IncomingPhoneNumbers/TollFree.json
#
# Returns: record<end: int, first_page_uri: string, incoming_phone_numbers: table<account_sid: string, address_requirements: string, address_sid: string, api_version: string, beta: bool, bundle_sid: string, capabilities: record, date_created: string, date_updated: string, emergency_address_sid: string, emergency_address_status: string, emergency_status: string, friendly_name: string, identity_sid: string, origin: string, phone_number: string, sid: string, sms_application_sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, status: string, status_callback: string, status_callback_method: string, trunk_sid: string, uri: string, voice_application_sid: string, voice_caller_id_lookup: bool, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_receive_mode: string, voice_url: string>, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>
# operationId: ListIncomingPhoneNumberTollFree
export def "list-incoming-phone-number-toll-free" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --beta: oneof<nothing, bool> # Whether to include phone numbers new to the Twilio platform. Can be: `true` or `false` and the default is `true`.
  --friendly-name: string # A string that identifies the resources to read.
  --phone-number: string # The phone numbers of the IncomingPhoneNumber resources to read. You can specify partial numbers and use '*' as a wildcard for any digit. (format: phone-number)
  --origin: string # Whether to include phone numbers based on their origin. Can be: `twilio` or `hosted`. By default, phone numbers of all origin are included.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2010-04-01/Accounts/{AccountSid}/IncomingPhoneNumbers/TollFree.json"
    path_params: [{name: AccountSid, var: account_sid}]
    query: [{name: Beta, var: beta}, {name: FriendlyName, var: friendly_name}, {name: PhoneNumber, var: phone_number}, {name: Origin, var: origin}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, beta: $beta, friendly_name: $friendly_name, phone_number: $phone_number, origin: $origin, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /2010-04-01/Accounts/{AccountSid}/IncomingPhoneNumbers/TollFree.json
#
# Returns: record<account_sid: string, address_requirements: string, address_sid: string, api_version: string, beta: bool, bundle_sid: string, capabilities: record<fax: bool, mms: bool, sms: bool, voice: bool>, date_created: string, date_updated: string, emergency_address_sid: string, emergency_address_status: string, emergency_status: string, friendly_name: string, identity_sid: string, origin: string, phone_number: string, sid: string, sms_application_sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, status: string, status_callback: string, status_callback_method: string, trunk_sid: string, uri: string, voice_application_sid: string, voice_caller_id_lookup: bool, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_receive_mode: string, voice_url: string>
# operationId: CreateIncomingPhoneNumberTollFree
export def "create-incoming-phone-number-toll-free" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address-sid: string # The SID of the Address resource we should associate with the new phone number. Some regions require addresses to meet local regulations.
  --api-version: string # The API version to use for incoming calls made to the new phone number. The default is `2010-04-01`.
  --bundle-sid: string # The SID of the Bundle resource that you associate with the phone number. Some regions require a Bundle to meet local Regulations.
  --emergency-address-sid: string # The SID of the emergency address configuration to use for emergency calling from the new phone number.
  --emergency-status: string@emergency-status-completer
  --friendly-name: string # A descriptive string that you created to describe the new phone number. It can be up to 64 characters long. By default, this is a formatted version of the phone number.
  --identity-sid: string # The SID of the Identity resource that we should associate with the new phone number. Some regions require an Identity to meet local regulations.
  phone_number: string # The phone number to purchase specified in [E.164](https://www.twilio.com/docs/glossary/what-e164) format. E.164 phone numbers consist of a + followed by the country code and subscriber number without punctuation characters. For example, +14155551234. (format: phone-number)
  --sms-application-sid: string # The SID of the application that should handle SMS messages sent to the new phone number. If an `sms_application_sid` is present, we ignore all `sms_*_url` values and use those of the application.
  --sms-fallback-method: string@sms-fallback-method-completer # The HTTP method that we should use to call `sms_fallback_url`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --sms-fallback-url: string # The URL that we should call when an error occurs while requesting or executing the TwiML defined by `sms_url`. (format: uri)
  --sms-method: string@sms-method-completer # The HTTP method that we should use to call `sms_url`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --sms-url: string # The URL we should call when the new phone number receives an incoming SMS message. (format: uri)
  --status-callback: string # The URL we should call using the `status_callback_method` to send status information to your application. (format: uri)
  --status-callback-method: string@status-callback-method-completer # The HTTP method we should use to call `status_callback`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --trunk-sid: string # The SID of the Trunk we should use to handle calls to the new phone number. If a `trunk_sid` is present, we ignore all of the voice urls and voice applications and use only those set on the Trunk. Setting a `trunk_sid` will automatically delete your `voice_application_sid` and vice versa.
  --voice-application-sid: string # The SID of the application we should use to handle calls to the new phone number. If a `voice_application_sid` is present, we ignore all of the voice urls and use those set on the application. Setting a `voice_application_sid` will automatically delete your `trunk_sid` and vice versa.
  --voice-caller-id-lookup: oneof<nothing, bool> # Whether to lookup the caller's name from the CNAM database and post it to your app. Can be: `true` or `false` and defaults to `false`.
  --voice-fallback-method: string@voice-fallback-method-completer # The HTTP method that we should use to call `voice_fallback_url`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --voice-fallback-url: string # The URL that we should call when an error occurs retrieving or executing the TwiML requested by `url`. (format: uri)
  --voice-method: string@voice-method-completer # The HTTP method that we should use to call `voice_url`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --voice-receive-mode: string@voice-receive-mode-completer
  --voice-url: string # The URL that we should call to answer a call to the new phone number. The `voice_url` will not be called if a `voice_application_sid` or a `trunk_sid` is set. (format: uri)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2010-04-01/Accounts/{AccountSid}/IncomingPhoneNumbers/TollFree.json"
    path_params: [{name: AccountSid, var: account_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: AddressSid, var: address_sid}, {name: ApiVersion, var: api_version}, {name: BundleSid, var: bundle_sid}, {name: EmergencyAddressSid, var: emergency_address_sid}, {name: EmergencyStatus, var: emergency_status}, {name: FriendlyName, var: friendly_name}, {name: IdentitySid, var: identity_sid}, {name: PhoneNumber, var: phone_number}, {name: SmsApplicationSid, var: sms_application_sid}, {name: SmsFallbackMethod, var: sms_fallback_method}, {name: SmsFallbackUrl, var: sms_fallback_url}, {name: SmsMethod, var: sms_method}, {name: SmsUrl, var: sms_url}, {name: StatusCallback, var: status_callback}, {name: StatusCallbackMethod, var: status_callback_method}, {name: TrunkSid, var: trunk_sid}, {name: VoiceApplicationSid, var: voice_application_sid}, {name: VoiceCallerIdLookup, var: voice_caller_id_lookup}, {name: VoiceFallbackMethod, var: voice_fallback_method}, {name: VoiceFallbackUrl, var: voice_fallback_url}, {name: VoiceMethod, var: voice_method}, {name: VoiceReceiveMode, var: voice_receive_mode}, {name: VoiceUrl, var: voice_url}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, address_sid: $address_sid, api_version: $api_version, bundle_sid: $bundle_sid, emergency_address_sid: $emergency_address_sid, emergency_status: $emergency_status, friendly_name: $friendly_name, identity_sid: $identity_sid, phone_number: $phone_number, sms_application_sid: $sms_application_sid, sms_fallback_method: $sms_fallback_method, sms_fallback_url: $sms_fallback_url, sms_method: $sms_method, sms_url: $sms_url, status_callback: $status_callback, status_callback_method: $status_callback_method, trunk_sid: $trunk_sid, voice_application_sid: $voice_application_sid, voice_caller_id_lookup: $voice_caller_id_lookup, voice_fallback_method: $voice_fallback_method, voice_fallback_url: $voice_fallback_url, voice_method: $voice_method, voice_receive_mode: $voice_receive_mode, voice_url: $voice_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of Add-on installations currently assigned to this Number.
#
# GET /2010-04-01/Accounts/{AccountSid}/IncomingPhoneNumbers/{ResourceSid}/AssignedAddOns.json
# Returns: record<assigned_add_ons: table<account_sid: string, configuration: any, date_created: string, date_updated: string, description: string, friendly_name: string, resource_sid: string, sid: string, subresource_uris: record, unique_name: string, uri: string>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>
# operationId: ListIncomingPhoneNumberAssignedAddOn
export def "list-incoming-phone-number-assigned-add-on" [
  account_sid: string
  resource_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/IncomingPhoneNumbers/{ResourceSid}/AssignedAddOns.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: ResourceSid, var: resource_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, resource_sid: $resource_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Assign an Add-on installation to the Number specified.
#
# POST /2010-04-01/Accounts/{AccountSid}/IncomingPhoneNumbers/{ResourceSid}/AssignedAddOns.json
# Returns: record<account_sid: string, configuration: any, date_created: string, date_updated: string, description: string, friendly_name: string, resource_sid: string, sid: string, subresource_uris: record, unique_name: string, uri: string>
# operationId: CreateIncomingPhoneNumberAssignedAddOn
export def "create-incoming-phone-number-assigned-add-on" [
  account_sid: string
  resource_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  installed_add_on_sid: string # The SID that identifies the Add-on installation.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2010-04-01/Accounts/{AccountSid}/IncomingPhoneNumbers/{ResourceSid}/AssignedAddOns.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: ResourceSid, var: resource_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: InstalledAddOnSid, var: installed_add_on_sid}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, resource_sid: $resource_sid, installed_add_on_sid: $installed_add_on_sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of Extensions for the Assigned Add-on.
#
# GET /2010-04-01/Accounts/{AccountSid}/IncomingPhoneNumbers/{ResourceSid}/AssignedAddOns/{AssignedAddOnSid}/Extensions.json
# Returns: record<end: int, extensions: table<account_sid: string, assigned_add_on_sid: string, enabled: bool, friendly_name: string, product_name: string, resource_sid: string, sid: string, unique_name: string, uri: string>, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>
# operationId: ListIncomingPhoneNumberAssignedAddOnExtension
export def "list-incoming-phone-number-assigned-add-on-extension" [
  account_sid: string
  resource_sid: string
  assigned_add_on_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/IncomingPhoneNumbers/{ResourceSid}/AssignedAddOns/{AssignedAddOnSid}/Extensions.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: ResourceSid, var: resource_sid}, {name: AssignedAddOnSid, var: assigned_add_on_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, resource_sid: $resource_sid, assigned_add_on_sid: $assigned_add_on_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch an instance of an Extension for the Assigned Add-on.
#
# GET /2010-04-01/Accounts/{AccountSid}/IncomingPhoneNumbers/{ResourceSid}/AssignedAddOns/{AssignedAddOnSid}/Extensions/{Sid}.json
# Returns: record<account_sid: string, assigned_add_on_sid: string, enabled: bool, friendly_name: string, product_name: string, resource_sid: string, sid: string, unique_name: string, uri: string>
# operationId: FetchIncomingPhoneNumberAssignedAddOnExtension
export def "fetch-incoming-phone-number-assigned-add-on-extension" [
  account_sid: string
  resource_sid: string
  assigned_add_on_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/IncomingPhoneNumbers/{ResourceSid}/AssignedAddOns/{AssignedAddOnSid}/Extensions/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: ResourceSid, var: resource_sid}, {name: AssignedAddOnSid, var: assigned_add_on_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, resource_sid: $resource_sid, assigned_add_on_sid: $assigned_add_on_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove the assignment of an Add-on installation from the Number specified.
#
# DELETE /2010-04-01/Accounts/{AccountSid}/IncomingPhoneNumbers/{ResourceSid}/AssignedAddOns/{Sid}.json
# operationId: DeleteIncomingPhoneNumberAssignedAddOn
export def "delete-incoming-phone-number-assigned-add-on" [
  account_sid: string
  resource_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/IncomingPhoneNumbers/{ResourceSid}/AssignedAddOns/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: ResourceSid, var: resource_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, resource_sid: $resource_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch an instance of an Add-on installation currently assigned to this Number.
#
# GET /2010-04-01/Accounts/{AccountSid}/IncomingPhoneNumbers/{ResourceSid}/AssignedAddOns/{Sid}.json
# Returns: record<account_sid: string, configuration: any, date_created: string, date_updated: string, description: string, friendly_name: string, resource_sid: string, sid: string, subresource_uris: record, unique_name: string, uri: string>
# operationId: FetchIncomingPhoneNumberAssignedAddOn
export def "fetch-incoming-phone-number-assigned-add-on" [
  account_sid: string
  resource_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/IncomingPhoneNumbers/{ResourceSid}/AssignedAddOns/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: ResourceSid, var: resource_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, resource_sid: $resource_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a phone-numbers belonging to the account used to make the request.
#
# DELETE /2010-04-01/Accounts/{AccountSid}/IncomingPhoneNumbers/{Sid}.json
# operationId: DeleteIncomingPhoneNumber
export def "delete-incoming-phone-number" [
  account_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/IncomingPhoneNumbers/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch an incoming-phone-number belonging to the account used to make the request.
#
# GET /2010-04-01/Accounts/{AccountSid}/IncomingPhoneNumbers/{Sid}.json
# Returns: record<account_sid: string, address_requirements: string, address_sid: string, api_version: string, beta: bool, bundle_sid: string, capabilities: record<fax: bool, mms: bool, sms: bool, voice: bool>, date_created: string, date_updated: string, emergency_address_sid: string, emergency_address_status: string, emergency_status: string, friendly_name: string, identity_sid: string, origin: string, phone_number: string, sid: string, sms_application_sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, status: string, status_callback: string, status_callback_method: string, trunk_sid: string, uri: string, voice_application_sid: string, voice_caller_id_lookup: bool, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_receive_mode: string, voice_url: string>
# operationId: FetchIncomingPhoneNumber
export def "fetch-incoming-phone-number" [
  account_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/IncomingPhoneNumbers/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an incoming-phone-number instance.
#
# POST /2010-04-01/Accounts/{AccountSid}/IncomingPhoneNumbers/{Sid}.json
# Returns: record<account_sid: string, address_requirements: string, address_sid: string, api_version: string, beta: bool, bundle_sid: string, capabilities: record<fax: bool, mms: bool, sms: bool, voice: bool>, date_created: string, date_updated: string, emergency_address_sid: string, emergency_address_status: string, emergency_status: string, friendly_name: string, identity_sid: string, origin: string, phone_number: string, sid: string, sms_application_sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, status: string, status_callback: string, status_callback_method: string, trunk_sid: string, uri: string, voice_application_sid: string, voice_caller_id_lookup: bool, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_receive_mode: string, voice_url: string>
# operationId: UpdateIncomingPhoneNumber
export def "update-incoming-phone-number" [
  account_sid: string
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
  --body-account-sid: string # The SID of the [Account](https://www.twilio.com/docs/iam/api/account) that created the IncomingPhoneNumber resource to update. For more information, see [Exchanging Numbers Between Subaccounts](https://www.twilio.com/docs/iam/api/subaccounts#exchanging-numbers). (spec name: AccountSid)
  --address-sid: string # The SID of the Address resource we should associate with the phone number. Some regions require addresses to meet local regulations.
  --api-version: string # The API version to use for incoming calls made to the phone number. The default is `2010-04-01`.
  --bundle-sid: string # The SID of the Bundle resource that you associate with the phone number. Some regions require a Bundle to meet local Regulations.
  --emergency-address-sid: string # The SID of the emergency address configuration to use for emergency calling from this phone number.
  --emergency-status: string@emergency-status-completer
  --friendly-name: string # A descriptive string that you created to describe this phone number. It can be up to 64 characters long. By default, this is a formatted version of the phone number.
  --identity-sid: string # The SID of the Identity resource that we should associate with the phone number. Some regions require an identity to meet local regulations.
  --sms-application-sid: string # The SID of the application that should handle SMS messages sent to the number. If an `sms_application_sid` is present, we ignore all of the `sms_*_url` urls and use those set on the application.
  --sms-fallback-method: string@sms-fallback-method-completer # The HTTP method that we should use to call `sms_fallback_url`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --sms-fallback-url: string # The URL that we should call when an error occurs while requesting or executing the TwiML defined by `sms_url`. (format: uri)
  --sms-method: string@sms-method-completer # The HTTP method that we should use to call `sms_url`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --sms-url: string # The URL we should call when the phone number receives an incoming SMS message. (format: uri)
  --status-callback: string # The URL we should call using the `status_callback_method` to send status information to your application. (format: uri)
  --status-callback-method: string@status-callback-method-completer # The HTTP method we should use to call `status_callback`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --trunk-sid: string # The SID of the Trunk we should use to handle phone calls to the phone number. If a `trunk_sid` is present, we ignore all of the voice urls and voice applications and use only those set on the Trunk. Setting a `trunk_sid` will automatically delete your `voice_application_sid` and vice versa.
  --voice-application-sid: string # The SID of the application we should use to handle phone calls to the phone number. If a `voice_application_sid` is present, we ignore all of the voice urls and use only those set on the application. Setting a `voice_application_sid` will automatically delete your `trunk_sid` and vice versa.
  --voice-caller-id-lookup: oneof<nothing, bool> # Whether to lookup the caller's name from the CNAM database and post it to your app. Can be: `true` or `false` and defaults to `false`.
  --voice-fallback-method: string@voice-fallback-method-completer # The HTTP method that we should use to call `voice_fallback_url`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --voice-fallback-url: string # The URL that we should call when an error occurs retrieving or executing the TwiML requested by `url`. (format: uri)
  --voice-method: string@voice-method-completer # The HTTP method that we should use to call `voice_url`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --voice-receive-mode: string@voice-receive-mode-completer
  --voice-url: string # The URL that we should call to answer a call to the phone number. The `voice_url` will not be called if a `voice_application_sid` or a `trunk_sid` is set. (format: uri)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2010-04-01/Accounts/{AccountSid}/IncomingPhoneNumbers/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: AccountSid, var: body_account_sid}, {name: AddressSid, var: address_sid}, {name: ApiVersion, var: api_version}, {name: BundleSid, var: bundle_sid}, {name: EmergencyAddressSid, var: emergency_address_sid}, {name: EmergencyStatus, var: emergency_status}, {name: FriendlyName, var: friendly_name}, {name: IdentitySid, var: identity_sid}, {name: SmsApplicationSid, var: sms_application_sid}, {name: SmsFallbackMethod, var: sms_fallback_method}, {name: SmsFallbackUrl, var: sms_fallback_url}, {name: SmsMethod, var: sms_method}, {name: SmsUrl, var: sms_url}, {name: StatusCallback, var: status_callback}, {name: StatusCallbackMethod, var: status_callback_method}, {name: TrunkSid, var: trunk_sid}, {name: VoiceApplicationSid, var: voice_application_sid}, {name: VoiceCallerIdLookup, var: voice_caller_id_lookup}, {name: VoiceFallbackMethod, var: voice_fallback_method}, {name: VoiceFallbackUrl, var: voice_fallback_url}, {name: VoiceMethod, var: voice_method}, {name: VoiceReceiveMode, var: voice_receive_mode}, {name: VoiceUrl, var: voice_url}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, sid: $sid, body_account_sid: $body_account_sid, address_sid: $address_sid, api_version: $api_version, bundle_sid: $bundle_sid, emergency_address_sid: $emergency_address_sid, emergency_status: $emergency_status, friendly_name: $friendly_name, identity_sid: $identity_sid, sms_application_sid: $sms_application_sid, sms_fallback_method: $sms_fallback_method, sms_fallback_url: $sms_fallback_url, sms_method: $sms_method, sms_url: $sms_url, status_callback: $status_callback, status_callback_method: $status_callback_method, trunk_sid: $trunk_sid, voice_application_sid: $voice_application_sid, voice_caller_id_lookup: $voice_caller_id_lookup, voice_fallback_method: $voice_fallback_method, voice_fallback_url: $voice_fallback_url, voice_method: $voice_method, voice_receive_mode: $voice_receive_mode, voice_url: $voice_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /2010-04-01/Accounts/{AccountSid}/Keys.json
#
# Returns: record<end: int, first_page_uri: string, keys: table<date_created: string, date_updated: string, friendly_name: string, sid: string>, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>
# operationId: ListKey
export def "list-key" [
  account_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/Keys.json"
    path_params: [{name: AccountSid, var: account_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /2010-04-01/Accounts/{AccountSid}/Keys.json
#
# Returns: record<date_created: string, date_updated: string, friendly_name: string, secret: string, sid: string>
# operationId: CreateNewKey
export def "create-new-key" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --friendly-name: string # A descriptive string that you create to describe the resource. It can be up to 64 characters long.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2010-04-01/Accounts/{AccountSid}/Keys.json"
    path_params: [{name: AccountSid, var: account_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: FriendlyName, var: friendly_name}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, friendly_name: $friendly_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /2010-04-01/Accounts/{AccountSid}/Keys/{Sid}.json
#
# operationId: DeleteKey
export def "delete-key" [
  account_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/Keys/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /2010-04-01/Accounts/{AccountSid}/Keys/{Sid}.json
#
# Returns: record<date_created: string, date_updated: string, friendly_name: string, sid: string>
# operationId: FetchKey
export def "fetch-key" [
  account_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/Keys/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /2010-04-01/Accounts/{AccountSid}/Keys/{Sid}.json
#
# Returns: record<date_created: string, date_updated: string, friendly_name: string, sid: string>
# operationId: UpdateKey
export def "update-key" [
  account_sid: string
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
  --friendly-name: string # A descriptive string that you create to describe the resource. It can be up to 64 characters long.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2010-04-01/Accounts/{AccountSid}/Keys/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: FriendlyName, var: friendly_name}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, sid: $sid, friendly_name: $friendly_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of messages belonging to the account used to make the request
#
# GET /2010-04-01/Accounts/{AccountSid}/Messages.json
# Returns: record<end: int, first_page_uri: string, messages: table<account_sid: string, api_version: string, body: string, date_created: string, date_sent: string, date_updated: string, direction: string, error_code: int, error_message: string, from: string, messaging_service_sid: string, num_media: string, num_segments: string, price: string, price_unit: string, sid: string, status: string, subresource_uris: record, to: string, uri: string>, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>
# operationId: ListMessage
export def "list-message" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --to: string # Read messages sent to only this phone number. (format: phone-number)
  --from: string # Read messages sent from only this phone number or alphanumeric sender ID. (format: phone-number)
  --date-sent: string # The date of the messages to show. Specify a date as `YYYY-MM-DD` in GMT to read only messages sent on this date. For example: `2009-07-06`. You can also specify an inequality, such as `DateSent<=YYYY-MM-DD`, to read messages sent on or before midnight on a date, and `DateSent>=YYYY-MM-DD` to read messages sent on or after midnight on a date. (format: date-time)
  --qp-date-sent: string # The date of the messages to show. Specify a date as `YYYY-MM-DD` in GMT to read only messages sent on this date. For example: `2009-07-06`. You can also specify an inequality, such as `DateSent<=YYYY-MM-DD`, to read messages sent on or before midnight on a date, and `DateSent>=YYYY-MM-DD` to read messages sent on or after midnight on a date. (format: date-time) (spec name: DateSent<)
  --qp-date-sent-2: string # The date of the messages to show. Specify a date as `YYYY-MM-DD` in GMT to read only messages sent on this date. For example: `2009-07-06`. You can also specify an inequality, such as `DateSent<=YYYY-MM-DD`, to read messages sent on or before midnight on a date, and `DateSent>=YYYY-MM-DD` to read messages sent on or after midnight on a date. (format: date-time) (spec name: DateSent>)
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2010-04-01/Accounts/{AccountSid}/Messages.json"
    path_params: [{name: AccountSid, var: account_sid}]
    query: [{name: To, var: to}, {name: From, var: from}, {name: DateSent, var: date_sent}, {name: "DateSent<", var: qp_date_sent}, {name: "DateSent>", var: qp_date_sent_2}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, to: $to, from: $from, date_sent: $date_sent, qp_date_sent: $qp_date_sent, qp_date_sent_2: $qp_date_sent_2, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send a message from the account used to make the request
#
# POST /2010-04-01/Accounts/{AccountSid}/Messages.json
# Returns: record<account_sid: string, api_version: string, body: string, date_created: string, date_sent: string, date_updated: string, direction: string, error_code: int, error_message: string, from: string, messaging_service_sid: string, num_media: string, num_segments: string, price: string, price_unit: string, sid: string, status: string, subresource_uris: record, to: string, uri: string>
# operationId: CreateMessage
export def "create-message" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address-retention: string@address-retention-completer
  --application-sid: string # The SID of the application that should receive message status. We POST a `message_sid` parameter and a `message_status` parameter with a value of `sent` or `failed` to the [application](https://www.twilio.com/docs/usage/api/applications)'s `message_status_callback`. If a `status_callback` parameter is also passed, it will be ignored and the application's `message_status_callback` parameter will be used.
  --attempt: int # Total number of attempts made ( including this ) to send out the message regardless of the provider used
  --body: string # The text of the message you want to send. Can be up to 1,600 characters in length.
  --content-retention: string@content-retention-completer
  --content-sid: string # The SID of the Content object returned at Content API content create time (https://www.twilio.com/docs/content-api/create-and-send-your-first-content-api-template#create-a-template). If this parameter is not specified, then the Content API will not be utilized.
  --content-variables: string # Key-value pairs of variable names to substitution values, used alongside a content_sid. If not specified, Content API will default to the default variables defined at create time.
  --force-delivery: oneof<nothing, bool> # Reserved
  --from: string # A Twilio phone number in [E.164](https://www.twilio.com/docs/glossary/what-e164) format, an [alphanumeric sender ID](https://www.twilio.com/docs/sms/send-messages#use-an-alphanumeric-sender-id), or a [Channel Endpoint address](https://www.twilio.com/docs/sms/channels#channel-addresses) that is enabled for the type of message you want to send. Phone numbers or [short codes](https://www.twilio.com/docs/sms/api/short-code) purchased from Twilio also work here. You cannot, for example, spoof messages from a private cell phone number. If you are using `messaging_service_sid`, this parameter must be empty. (format: phone-number)
  --max-price: float # The maximum total price in US dollars that you will pay for the message to be delivered. Can be a decimal value that has up to 4 decimal places. All messages are queued for delivery and the message cost is checked before the message is sent. If the cost exceeds `max_price`, the message will fail and a status of `Failed` is sent to the status callback. If `MaxPrice` is not set, the message cost is not checked.
  --media-url: list<string> # The URL of the media to send with the message. The media can be of type `gif`, `png`, and `jpeg` and will be formatted correctly on the recipient's device. The media size limit is 5MB for supported file types (JPEG, PNG, GIF) and 500KB for [other types](https://www.twilio.com/docs/sms/accepted-mime-types) of accepted media. To send more than one image in the message body, provide multiple `media_url` parameters in the POST request. You can include up to 10 `media_url` parameters per message. You can send images in an SMS message in only the US and Canada.
  --messaging-service-sid: string # The SID of the [Messaging Service](https://www.twilio.com/docs/sms/services#send-a-message-with-copilot) you want to associate with the Message. Set this parameter to use the [Messaging Service Settings and Copilot Features](https://www.twilio.com/console/sms/services) you have configured and leave the `from` parameter empty. When only this parameter is set, Twilio will use your enabled Copilot Features to select the `from` phone number for delivery.
  --persistent-action: list<string> # Rich actions for Channels Messages.
  --provide-feedback: oneof<nothing, bool> # Whether to confirm delivery of the message. Set this value to `true` if you are sending messages that have a trackable user action and you intend to confirm delivery of the message using the [Message Feedback API](https://www.twilio.com/docs/sms/api/message-feedback-resource). This parameter is `false` by default.
  --schedule-type: string@schedule-type-completer
  --send-as-mms: oneof<nothing, bool> # If set to True, Twilio will deliver the message as a single MMS message, regardless of the presence of media.
  --send-at: string # The time that Twilio will send the message. Must be in ISO 8601 format. (format: date-time)
  --shorten-urls: oneof<nothing, bool> # Determines the usage of Click Tracking. Setting it to `true` will instruct Twilio to replace all links in the Message with a shortened version based on the associated Domain Sid and track clicks on them. If this parameter is not set on an API call, we will use the value set on the Messaging Service. If this parameter is not set and the value is not configured on the Messaging Service used this will default to `false`.
  --smart-encoded: oneof<nothing, bool> # Whether to detect Unicode characters that have a similar GSM-7 character and replace them. Can be: `true` or `false`.
  --status-callback: string # The URL we should call using the `status_callback_method` to send status information to your application. If specified, we POST these message status changes to the URL: `queued`, `failed`, `sent`, `delivered`, or `undelivered`. Twilio will POST its [standard request parameters](https://www.twilio.com/docs/sms/twiml#request-parameters) as well as some additional parameters including `MessageSid`, `MessageStatus`, and `ErrorCode`. If you include this parameter with the `messaging_service_sid`, we use this URL instead of the Status Callback URL of the [Messaging Service](https://www.twilio.com/docs/sms/services/api). URLs must contain a valid hostname and underscores are not allowed. (format: uri)
  to: string # The destination phone number in [E.164](https://www.twilio.com/docs/glossary/what-e164) format for SMS/MMS or [Channel user address](https://www.twilio.com/docs/sms/channels#channel-addresses) for other 3rd-party channels. (format: phone-number)
  --validity-period: int # How long in seconds the message can remain in our outgoing message queue. After this period elapses, the message fails and we call your status callback. Can be between 1 and the default value of 14,400 seconds. After a message has been accepted by a carrier, however, we cannot guarantee that the message will not be queued after this period. We recommend that this value be at least 5 seconds.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2010-04-01/Accounts/{AccountSid}/Messages.json"
    path_params: [{name: AccountSid, var: account_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: AddressRetention, var: address_retention}, {name: ApplicationSid, var: application_sid}, {name: Attempt, var: attempt}, {name: Body, var: body}, {name: ContentRetention, var: content_retention}, {name: ContentSid, var: content_sid}, {name: ContentVariables, var: content_variables}, {name: ForceDelivery, var: force_delivery}, {name: From, var: from}, {name: MaxPrice, var: max_price}, {name: MediaUrl, var: media_url}, {name: MessagingServiceSid, var: messaging_service_sid}, {name: PersistentAction, var: persistent_action}, {name: ProvideFeedback, var: provide_feedback}, {name: ScheduleType, var: schedule_type}, {name: SendAsMms, var: send_as_mms}, {name: SendAt, var: send_at}, {name: ShortenUrls, var: shorten_urls}, {name: SmartEncoded, var: smart_encoded}, {name: StatusCallback, var: status_callback}, {name: To, var: to}, {name: ValidityPeriod, var: validity_period}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, address_retention: $address_retention, application_sid: $application_sid, attempt: $attempt, body: $body, content_retention: $content_retention, content_sid: $content_sid, content_variables: $content_variables, force_delivery: $force_delivery, from: $from, max_price: $max_price, media_url: $media_url, messaging_service_sid: $messaging_service_sid, persistent_action: $persistent_action, provide_feedback: $provide_feedback, schedule_type: $schedule_type, send_as_mms: $send_as_mms, send_at: $send_at, shorten_urls: $shorten_urls, smart_encoded: $smart_encoded, status_callback: $status_callback, to: $to, validity_period: $validity_period
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /2010-04-01/Accounts/{AccountSid}/Messages/{MessageSid}/Feedback.json
#
# Returns: record<account_sid: string, date_created: string, date_updated: string, message_sid: string, outcome: string, uri: string>
# operationId: CreateMessageFeedback
export def "create-message-feedback" [
  account_sid: string
  message_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --outcome: string@outcome-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2010-04-01/Accounts/{AccountSid}/Messages/{MessageSid}/Feedback.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: MessageSid, var: message_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Outcome, var: outcome}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, message_sid: $message_sid, outcome: $outcome
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of Media resources belonging to the account used to make the request
#
# GET /2010-04-01/Accounts/{AccountSid}/Messages/{MessageSid}/Media.json
# Returns: record<end: int, first_page_uri: string, media_list: table<account_sid: string, content_type: string, date_created: string, date_updated: string, parent_sid: string, sid: string, uri: string>, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>
# operationId: ListMedia
export def "list-media" [
  account_sid: string
  message_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-created: string # Only include media that was created on this date. Specify a date as `YYYY-MM-DD` in GMT, for example: `2009-07-06`, to read media that was created on this date. You can also specify an inequality, such as `StartTime<=YYYY-MM-DD`, to read media that was created on or before midnight of this date, and `StartTime>=YYYY-MM-DD` to read media that was created on or after midnight of this date. (format: date-time)
  --qp-date-created: string # Only include media that was created on this date. Specify a date as `YYYY-MM-DD` in GMT, for example: `2009-07-06`, to read media that was created on this date. You can also specify an inequality, such as `StartTime<=YYYY-MM-DD`, to read media that was created on or before midnight of this date, and `StartTime>=YYYY-MM-DD` to read media that was created on or after midnight of this date. (format: date-time) (spec name: DateCreated<)
  --qp-date-created-2: string # Only include media that was created on this date. Specify a date as `YYYY-MM-DD` in GMT, for example: `2009-07-06`, to read media that was created on this date. You can also specify an inequality, such as `StartTime<=YYYY-MM-DD`, to read media that was created on or before midnight of this date, and `StartTime>=YYYY-MM-DD` to read media that was created on or after midnight of this date. (format: date-time) (spec name: DateCreated>)
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2010-04-01/Accounts/{AccountSid}/Messages/{MessageSid}/Media.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: MessageSid, var: message_sid}]
    query: [{name: DateCreated, var: date_created}, {name: "DateCreated<", var: qp_date_created}, {name: "DateCreated>", var: qp_date_created_2}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, message_sid: $message_sid, date_created: $date_created, qp_date_created: $qp_date_created, qp_date_created_2: $qp_date_created_2, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete media from your account. Once delete, you will no longer be billed
#
# DELETE /2010-04-01/Accounts/{AccountSid}/Messages/{MessageSid}/Media/{Sid}.json
# operationId: DeleteMedia
export def "delete-media" [
  account_sid: string
  message_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/Messages/{MessageSid}/Media/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: MessageSid, var: message_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, message_sid: $message_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a single media instance belonging to the account used to make the request
#
# GET /2010-04-01/Accounts/{AccountSid}/Messages/{MessageSid}/Media/{Sid}.json
# Returns: record<account_sid: string, content_type: string, date_created: string, date_updated: string, parent_sid: string, sid: string, uri: string>
# operationId: FetchMedia
export def "fetch-media" [
  account_sid: string
  message_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/Messages/{MessageSid}/Media/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: MessageSid, var: message_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, message_sid: $message_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a message record from your account
#
# DELETE /2010-04-01/Accounts/{AccountSid}/Messages/{Sid}.json
# operationId: DeleteMessage
export def "delete-message" [
  account_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/Messages/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a message belonging to the account used to make the request
#
# GET /2010-04-01/Accounts/{AccountSid}/Messages/{Sid}.json
# Returns: record<account_sid: string, api_version: string, body: string, date_created: string, date_sent: string, date_updated: string, direction: string, error_code: int, error_message: string, from: string, messaging_service_sid: string, num_media: string, num_segments: string, price: string, price_unit: string, sid: string, status: string, subresource_uris: record, to: string, uri: string>
# operationId: FetchMessage
export def "fetch-message" [
  account_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/Messages/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# To redact a message-body from a post-flight message record, post to the message instance resource with an empty body
#
# POST /2010-04-01/Accounts/{AccountSid}/Messages/{Sid}.json
# Returns: record<account_sid: string, api_version: string, body: string, date_created: string, date_sent: string, date_updated: string, direction: string, error_code: int, error_message: string, from: string, messaging_service_sid: string, num_media: string, num_segments: string, price: string, price_unit: string, sid: string, status: string, subresource_uris: record, to: string, uri: string>
# operationId: UpdateMessage
export def "update-message" [
  account_sid: string
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
  --body: string # The text of the message you want to send. Can be up to 1,600 characters long.
  --status: string@status-completer-8
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2010-04-01/Accounts/{AccountSid}/Messages/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Body, var: body}, {name: Status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, sid: $sid, body: $body, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of notifications belonging to the account used to make the request
#
# GET /2010-04-01/Accounts/{AccountSid}/Notifications.json
# Returns: record<end: int, first_page_uri: string, next_page_uri: string, notifications: table<account_sid: string, api_version: string, call_sid: string, date_created: string, date_updated: string, error_code: string, log: string, message_date: string, message_text: string, more_info: string, request_method: string, request_url: string, sid: string, uri: string>, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>
# operationId: ListNotification
export def "list-notification" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --log: int # Only read notifications of the specified log level. Can be: `0` to read only ERROR notifications or `1` to read only WARNING notifications. By default, all notifications are read.
  --message-date: string # Only show notifications for the specified date, formatted as `YYYY-MM-DD`. You can also specify an inequality, such as `<=YYYY-MM-DD` for messages logged at or before midnight on a date, or `>=YYYY-MM-DD` for messages logged at or after midnight on a date. (format: date)
  --qp-message-date: string # Only show notifications for the specified date, formatted as `YYYY-MM-DD`. You can also specify an inequality, such as `<=YYYY-MM-DD` for messages logged at or before midnight on a date, or `>=YYYY-MM-DD` for messages logged at or after midnight on a date. (format: date) (spec name: MessageDate<)
  --qp-message-date-2: string # Only show notifications for the specified date, formatted as `YYYY-MM-DD`. You can also specify an inequality, such as `<=YYYY-MM-DD` for messages logged at or before midnight on a date, or `>=YYYY-MM-DD` for messages logged at or after midnight on a date. (format: date) (spec name: MessageDate>)
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2010-04-01/Accounts/{AccountSid}/Notifications.json"
    path_params: [{name: AccountSid, var: account_sid}]
    query: [{name: Log, var: log}, {name: MessageDate, var: message_date}, {name: "MessageDate<", var: qp_message_date}, {name: "MessageDate>", var: qp_message_date_2}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, log: $log, message_date: $message_date, qp_message_date: $qp_message_date, qp_message_date_2: $qp_message_date_2, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a notification belonging to the account used to make the request
#
# GET /2010-04-01/Accounts/{AccountSid}/Notifications/{Sid}.json
# Returns: record<account_sid: string, api_version: string, call_sid: string, date_created: string, date_updated: string, error_code: string, log: string, message_date: string, message_text: string, more_info: string, request_method: string, request_url: string, request_variables: string, response_body: string, response_headers: string, sid: string, uri: string>
# operationId: FetchNotification
export def "fetch-notification" [
  account_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/Notifications/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of outgoing-caller-ids belonging to the account used to make the request
#
# GET /2010-04-01/Accounts/{AccountSid}/OutgoingCallerIds.json
# Returns: record<end: int, first_page_uri: string, next_page_uri: string, outgoing_caller_ids: table<account_sid: string, date_created: string, date_updated: string, friendly_name: string, phone_number: string, sid: string, uri: string>, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>
# operationId: ListOutgoingCallerId
export def "list-outgoing-caller-id" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --phone-number: string # The phone number of the OutgoingCallerId resources to read. (format: phone-number)
  --friendly-name: string # The string that identifies the OutgoingCallerId resources to read.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2010-04-01/Accounts/{AccountSid}/OutgoingCallerIds.json"
    path_params: [{name: AccountSid, var: account_sid}]
    query: [{name: PhoneNumber, var: phone_number}, {name: FriendlyName, var: friendly_name}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, phone_number: $phone_number, friendly_name: $friendly_name, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /2010-04-01/Accounts/{AccountSid}/OutgoingCallerIds.json
#
# Returns: record<account_sid: string, call_sid: string, friendly_name: string, phone_number: string, validation_code: string>
# operationId: CreateValidationRequest
export def "create-validation-request" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --call-delay: int # The number of seconds to delay before initiating the verification call. Can be an integer between `0` and `60`, inclusive. The default is `0`.
  --extension: string # The digits to dial after connecting the verification call.
  --friendly-name: string # A descriptive string that you create to describe the new caller ID resource. It can be up to 64 characters long. The default value is a formatted version of the phone number.
  phone_number: string # The phone number to verify in [E.164](https://www.twilio.com/docs/glossary/what-e164) format, which consists of a + followed by the country code and subscriber number. (format: phone-number)
  --status-callback: string # The URL we should call using the `status_callback_method` to send status information about the verification process to your application. (format: uri)
  --status-callback-method: string@status-callback-method-completer # The HTTP method we should use to call `status_callback`. Can be: `GET` or `POST`, and the default is `POST`. (format: http-method)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2010-04-01/Accounts/{AccountSid}/OutgoingCallerIds.json"
    path_params: [{name: AccountSid, var: account_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: CallDelay, var: call_delay}, {name: Extension, var: extension}, {name: FriendlyName, var: friendly_name}, {name: PhoneNumber, var: phone_number}, {name: StatusCallback, var: status_callback}, {name: StatusCallbackMethod, var: status_callback_method}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, call_delay: $call_delay, extension: $extension, friendly_name: $friendly_name, phone_number: $phone_number, status_callback: $status_callback, status_callback_method: $status_callback_method
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete the caller-id specified from the account
#
# DELETE /2010-04-01/Accounts/{AccountSid}/OutgoingCallerIds/{Sid}.json
# operationId: DeleteOutgoingCallerId
export def "delete-outgoing-caller-id" [
  account_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/OutgoingCallerIds/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch an outgoing-caller-id belonging to the account used to make the request
#
# GET /2010-04-01/Accounts/{AccountSid}/OutgoingCallerIds/{Sid}.json
# Returns: record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, phone_number: string, sid: string, uri: string>
# operationId: FetchOutgoingCallerId
export def "fetch-outgoing-caller-id" [
  account_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/OutgoingCallerIds/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the caller-id
#
# POST /2010-04-01/Accounts/{AccountSid}/OutgoingCallerIds/{Sid}.json
# Returns: record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, phone_number: string, sid: string, uri: string>
# operationId: UpdateOutgoingCallerId
export def "update-outgoing-caller-id" [
  account_sid: string
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
  --friendly-name: string # A descriptive string that you create to describe the resource. It can be up to 64 characters long.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2010-04-01/Accounts/{AccountSid}/OutgoingCallerIds/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: FriendlyName, var: friendly_name}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, sid: $sid, friendly_name: $friendly_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of queues belonging to the account used to make the request
#
# GET /2010-04-01/Accounts/{AccountSid}/Queues.json
# Returns: record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, queues: table<account_sid: string, average_wait_time: int, current_size: int, date_created: string, date_updated: string, friendly_name: string, max_size: int, sid: string, uri: string>, start: int, uri: string>
# operationId: ListQueue
export def "list-queue" [
  account_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/Queues.json"
    path_params: [{name: AccountSid, var: account_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a queue
#
# POST /2010-04-01/Accounts/{AccountSid}/Queues.json
# Returns: record<account_sid: string, average_wait_time: int, current_size: int, date_created: string, date_updated: string, friendly_name: string, max_size: int, sid: string, uri: string>
# operationId: CreateQueue
export def "create-queue" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  friendly_name: string # A descriptive string that you created to describe this resource. It can be up to 64 characters long.
  --max-size: int # The maximum number of calls allowed to be in the queue. The default is 1000. The maximum is 5000.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2010-04-01/Accounts/{AccountSid}/Queues.json"
    path_params: [{name: AccountSid, var: account_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: FriendlyName, var: friendly_name}, {name: MaxSize, var: max_size}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, friendly_name: $friendly_name, max_size: $max_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve the members of the queue
#
# GET /2010-04-01/Accounts/{AccountSid}/Queues/{QueueSid}/Members.json
# Returns: record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, queue_members: table<call_sid: string, date_enqueued: string, position: int, queue_sid: string, uri: string, wait_time: int>, start: int, uri: string>
# operationId: ListMember
export def "list-member" [
  account_sid: string
  queue_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/Queues/{QueueSid}/Members.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: QueueSid, var: queue_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, queue_sid: $queue_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a specific member from the queue
#
# GET /2010-04-01/Accounts/{AccountSid}/Queues/{QueueSid}/Members/{CallSid}.json
# Returns: record<call_sid: string, date_enqueued: string, position: int, queue_sid: string, uri: string, wait_time: int>
# operationId: FetchMember
export def "fetch-member" [
  account_sid: string
  queue_sid: string
  call_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/Queues/{QueueSid}/Members/{CallSid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: QueueSid, var: queue_sid}, {name: CallSid, var: call_sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, queue_sid: $queue_sid, call_sid: $call_sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Dequeue a member from a queue and have the member's call begin executing the TwiML document at that URL
#
# POST /2010-04-01/Accounts/{AccountSid}/Queues/{QueueSid}/Members/{CallSid}.json
# Returns: record<call_sid: string, date_enqueued: string, position: int, queue_sid: string, uri: string, wait_time: int>
# operationId: UpdateMember
export def "update-member" [
  account_sid: string
  queue_sid: string
  call_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --method: string@method-completer # How to pass the update request data. Can be `GET` or `POST` and the default is `POST`. `POST` sends the data as encoded form data and `GET` sends the data as query parameters. (format: http-method)
  url: string # The absolute URL of the Queue resource. (format: uri)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2010-04-01/Accounts/{AccountSid}/Queues/{QueueSid}/Members/{CallSid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: QueueSid, var: queue_sid}, {name: CallSid, var: call_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Method, var: method}, {name: Url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, queue_sid: $queue_sid, call_sid: $call_sid, method: $method, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove an empty queue
#
# DELETE /2010-04-01/Accounts/{AccountSid}/Queues/{Sid}.json
# operationId: DeleteQueue
export def "delete-queue" [
  account_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/Queues/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch an instance of a queue identified by the QueueSid
#
# GET /2010-04-01/Accounts/{AccountSid}/Queues/{Sid}.json
# Returns: record<account_sid: string, average_wait_time: int, current_size: int, date_created: string, date_updated: string, friendly_name: string, max_size: int, sid: string, uri: string>
# operationId: FetchQueue
export def "fetch-queue" [
  account_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/Queues/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the queue with the new parameters
#
# POST /2010-04-01/Accounts/{AccountSid}/Queues/{Sid}.json
# Returns: record<account_sid: string, average_wait_time: int, current_size: int, date_created: string, date_updated: string, friendly_name: string, max_size: int, sid: string, uri: string>
# operationId: UpdateQueue
export def "update-queue" [
  account_sid: string
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
  --friendly-name: string # A descriptive string that you created to describe this resource. It can be up to 64 characters long.
  --max-size: int # The maximum number of calls allowed to be in the queue. The default is 1000. The maximum is 5000.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2010-04-01/Accounts/{AccountSid}/Queues/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: FriendlyName, var: friendly_name}, {name: MaxSize, var: max_size}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, sid: $sid, friendly_name: $friendly_name, max_size: $max_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of recordings belonging to the account used to make the request
#
# GET /2010-04-01/Accounts/{AccountSid}/Recordings.json
# Returns: record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, recordings: table<account_sid: string, api_version: string, call_sid: string, channels: int, conference_sid: string, date_created: string, date_updated: string, duration: string, encryption_details: any, error_code: int, media_url: string, price: string, price_unit: string, sid: string, source: string, start_time: string, status: string, subresource_uris: record, uri: string>, start: int, uri: string>
# operationId: ListRecording
export def "list-recording" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-created: string # Only include recordings that were created on this date. Specify a date as `YYYY-MM-DD` in GMT, for example: `2009-07-06`, to read recordings that were created on this date. You can also specify an inequality, such as `DateCreated<=YYYY-MM-DD`, to read recordings that were created on or before midnight of this date, and `DateCreated>=YYYY-MM-DD` to read recordings that were created on or after midnight of this date. (format: date-time)
  --qp-date-created: string # Only include recordings that were created on this date. Specify a date as `YYYY-MM-DD` in GMT, for example: `2009-07-06`, to read recordings that were created on this date. You can also specify an inequality, such as `DateCreated<=YYYY-MM-DD`, to read recordings that were created on or before midnight of this date, and `DateCreated>=YYYY-MM-DD` to read recordings that were created on or after midnight of this date. (format: date-time) (spec name: DateCreated<)
  --qp-date-created-2: string # Only include recordings that were created on this date. Specify a date as `YYYY-MM-DD` in GMT, for example: `2009-07-06`, to read recordings that were created on this date. You can also specify an inequality, such as `DateCreated<=YYYY-MM-DD`, to read recordings that were created on or before midnight of this date, and `DateCreated>=YYYY-MM-DD` to read recordings that were created on or after midnight of this date. (format: date-time) (spec name: DateCreated>)
  --call-sid: string # The [Call](https://www.twilio.com/docs/voice/api/call-resource) SID of the resources to read.
  --conference-sid: string # The Conference SID that identifies the conference associated with the recording to read.
  --include-soft-deleted: oneof<nothing, bool> # A boolean parameter indicating whether to retrieve soft deleted recordings or not. Recordings metadata are kept after deletion for a retention period of 40 days.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2010-04-01/Accounts/{AccountSid}/Recordings.json"
    path_params: [{name: AccountSid, var: account_sid}]
    query: [{name: DateCreated, var: date_created}, {name: "DateCreated<", var: qp_date_created}, {name: "DateCreated>", var: qp_date_created_2}, {name: CallSid, var: call_sid}, {name: ConferenceSid, var: conference_sid}, {name: IncludeSoftDeleted, var: include_soft_deleted}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, date_created: $date_created, qp_date_created: $qp_date_created, qp_date_created_2: $qp_date_created_2, call_sid: $call_sid, conference_sid: $conference_sid, include_soft_deleted: $include_soft_deleted, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /2010-04-01/Accounts/{AccountSid}/Recordings/{RecordingSid}/Transcriptions.json
#
# Returns: record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, transcriptions: table<account_sid: string, api_version: string, date_created: string, date_updated: string, duration: string, price: float, price_unit: string, recording_sid: string, sid: string, status: string, transcription_text: string, type: string, uri: string>, uri: string>
# operationId: ListRecordingTranscription
export def "list-recording-transcription" [
  account_sid: string
  recording_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/Recordings/{RecordingSid}/Transcriptions.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: RecordingSid, var: recording_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, recording_sid: $recording_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /2010-04-01/Accounts/{AccountSid}/Recordings/{RecordingSid}/Transcriptions/{Sid}.json
#
# operationId: DeleteRecordingTranscription
export def "delete-recording-transcription" [
  account_sid: string
  recording_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/Recordings/{RecordingSid}/Transcriptions/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: RecordingSid, var: recording_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, recording_sid: $recording_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /2010-04-01/Accounts/{AccountSid}/Recordings/{RecordingSid}/Transcriptions/{Sid}.json
#
# Returns: record<account_sid: string, api_version: string, date_created: string, date_updated: string, duration: string, price: float, price_unit: string, recording_sid: string, sid: string, status: string, transcription_text: string, type: string, uri: string>
# operationId: FetchRecordingTranscription
export def "fetch-recording-transcription" [
  account_sid: string
  recording_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/Recordings/{RecordingSid}/Transcriptions/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: RecordingSid, var: recording_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, recording_sid: $recording_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of results belonging to the recording
#
# GET /2010-04-01/Accounts/{AccountSid}/Recordings/{ReferenceSid}/AddOnResults.json
# Returns: record<add_on_results: table<account_sid: string, add_on_configuration_sid: string, add_on_sid: string, date_completed: string, date_created: string, date_updated: string, reference_sid: string, sid: string, status: string, subresource_uris: record>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>
# operationId: ListRecordingAddOnResult
export def "list-recording-add-on-result" [
  account_sid: string
  reference_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/Recordings/{ReferenceSid}/AddOnResults.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: ReferenceSid, var: reference_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, reference_sid: $reference_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of payloads belonging to the AddOnResult
#
# GET /2010-04-01/Accounts/{AccountSid}/Recordings/{ReferenceSid}/AddOnResults/{AddOnResultSid}/Payloads.json
# Returns: record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, payloads: table<account_sid: string, add_on_configuration_sid: string, add_on_result_sid: string, add_on_sid: string, content_type: string, date_created: string, date_updated: string, label: string, reference_sid: string, sid: string, subresource_uris: record>, previous_page_uri: string, start: int, uri: string>
# operationId: ListRecordingAddOnResultPayload
export def "list-recording-add-on-result-payload" [
  account_sid: string
  reference_sid: string
  add_on_result_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/Recordings/{ReferenceSid}/AddOnResults/{AddOnResultSid}/Payloads.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: ReferenceSid, var: reference_sid}, {name: AddOnResultSid, var: add_on_result_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, reference_sid: $reference_sid, add_on_result_sid: $add_on_result_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a payload from the result along with all associated Data
#
# DELETE /2010-04-01/Accounts/{AccountSid}/Recordings/{ReferenceSid}/AddOnResults/{AddOnResultSid}/Payloads/{Sid}.json
# operationId: DeleteRecordingAddOnResultPayload
export def "delete-recording-add-on-result-payload" [
  account_sid: string
  reference_sid: string
  add_on_result_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/Recordings/{ReferenceSid}/AddOnResults/{AddOnResultSid}/Payloads/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: ReferenceSid, var: reference_sid}, {name: AddOnResultSid, var: add_on_result_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, reference_sid: $reference_sid, add_on_result_sid: $add_on_result_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch an instance of a result payload
#
# GET /2010-04-01/Accounts/{AccountSid}/Recordings/{ReferenceSid}/AddOnResults/{AddOnResultSid}/Payloads/{Sid}.json
# Returns: record<account_sid: string, add_on_configuration_sid: string, add_on_result_sid: string, add_on_sid: string, content_type: string, date_created: string, date_updated: string, label: string, reference_sid: string, sid: string, subresource_uris: record>
# operationId: FetchRecordingAddOnResultPayload
export def "fetch-recording-add-on-result-payload" [
  account_sid: string
  reference_sid: string
  add_on_result_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/Recordings/{ReferenceSid}/AddOnResults/{AddOnResultSid}/Payloads/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: ReferenceSid, var: reference_sid}, {name: AddOnResultSid, var: add_on_result_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, reference_sid: $reference_sid, add_on_result_sid: $add_on_result_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a result and purge all associated Payloads
#
# DELETE /2010-04-01/Accounts/{AccountSid}/Recordings/{ReferenceSid}/AddOnResults/{Sid}.json
# operationId: DeleteRecordingAddOnResult
export def "delete-recording-add-on-result" [
  account_sid: string
  reference_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/Recordings/{ReferenceSid}/AddOnResults/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: ReferenceSid, var: reference_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, reference_sid: $reference_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch an instance of an AddOnResult
#
# GET /2010-04-01/Accounts/{AccountSid}/Recordings/{ReferenceSid}/AddOnResults/{Sid}.json
# Returns: record<account_sid: string, add_on_configuration_sid: string, add_on_sid: string, date_completed: string, date_created: string, date_updated: string, reference_sid: string, sid: string, status: string, subresource_uris: record>
# operationId: FetchRecordingAddOnResult
export def "fetch-recording-add-on-result" [
  account_sid: string
  reference_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/Recordings/{ReferenceSid}/AddOnResults/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: ReferenceSid, var: reference_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, reference_sid: $reference_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a recording from your account
#
# DELETE /2010-04-01/Accounts/{AccountSid}/Recordings/{Sid}.json
# operationId: DeleteRecording
export def "delete-recording" [
  account_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/Recordings/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch an instance of a recording
#
# GET /2010-04-01/Accounts/{AccountSid}/Recordings/{Sid}.json
# Returns: record<account_sid: string, api_version: string, call_sid: string, channels: int, conference_sid: string, date_created: string, date_updated: string, duration: string, encryption_details: any, error_code: int, media_url: string, price: string, price_unit: string, sid: string, source: string, start_time: string, status: string, subresource_uris: record, uri: string>
# operationId: FetchRecording
export def "fetch-recording" [
  account_sid: string
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
  --include-soft-deleted: oneof<nothing, bool> # A boolean parameter indicating whether to retrieve soft deleted recordings or not. Recordings metadata are kept after deletion for a retention period of 40 days.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2010-04-01/Accounts/{AccountSid}/Recordings/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: Sid, var: sid}]
    query: [{name: IncludeSoftDeleted, var: include_soft_deleted}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, sid: $sid, include_soft_deleted: $include_soft_deleted
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get All Credential Lists
#
# GET /2010-04-01/Accounts/{AccountSid}/SIP/CredentialLists.json
# Returns: record<credential_lists: table<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sid: string, subresource_uris: record, uri: string>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>
# operationId: ListSipCredentialList
export def "list-sip-credential-list" [
  account_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/SIP/CredentialLists.json"
    path_params: [{name: AccountSid, var: account_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a Credential List
#
# POST /2010-04-01/Accounts/{AccountSid}/SIP/CredentialLists.json
# Returns: record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sid: string, subresource_uris: record, uri: string>
# operationId: CreateSipCredentialList
export def "create-sip-credential-list" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  friendly_name: string # A human readable descriptive text that describes the CredentialList, up to 64 characters long.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2010-04-01/Accounts/{AccountSid}/SIP/CredentialLists.json"
    path_params: [{name: AccountSid, var: account_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: FriendlyName, var: friendly_name}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, friendly_name: $friendly_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of credentials.
#
# GET /2010-04-01/Accounts/{AccountSid}/SIP/CredentialLists/{CredentialListSid}/Credentials.json
# Returns: record<credentials: table<account_sid: string, credential_list_sid: string, date_created: string, date_updated: string, sid: string, uri: string, username: string>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>
# operationId: ListSipCredential
export def "list-sip-credential" [
  account_sid: string
  credential_list_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/SIP/CredentialLists/{CredentialListSid}/Credentials.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: CredentialListSid, var: credential_list_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, credential_list_sid: $credential_list_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new credential resource.
#
# POST /2010-04-01/Accounts/{AccountSid}/SIP/CredentialLists/{CredentialListSid}/Credentials.json
# Returns: record<account_sid: string, credential_list_sid: string, date_created: string, date_updated: string, sid: string, uri: string, username: string>
# operationId: CreateSipCredential
export def "create-sip-credential" [
  account_sid: string
  credential_list_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  password: string # The password that the username will use when authenticating SIP requests. The password must be a minimum of 12 characters, contain at least 1 digit, and have mixed case. (eg `IWasAtSignal2018`)
  username: string # The username that will be passed when authenticating SIP requests. The username should be sent in response to Twilio's challenge of the initial INVITE. It can be up to 32 characters long.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2010-04-01/Accounts/{AccountSid}/SIP/CredentialLists/{CredentialListSid}/Credentials.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: CredentialListSid, var: credential_list_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Password, var: password}, {name: Username, var: username}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, credential_list_sid: $credential_list_sid, password: $password, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a credential resource.
#
# DELETE /2010-04-01/Accounts/{AccountSid}/SIP/CredentialLists/{CredentialListSid}/Credentials/{Sid}.json
# operationId: DeleteSipCredential
export def "delete-sip-credential" [
  account_sid: string
  credential_list_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/SIP/CredentialLists/{CredentialListSid}/Credentials/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: CredentialListSid, var: credential_list_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, credential_list_sid: $credential_list_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a single credential.
#
# GET /2010-04-01/Accounts/{AccountSid}/SIP/CredentialLists/{CredentialListSid}/Credentials/{Sid}.json
# Returns: record<account_sid: string, credential_list_sid: string, date_created: string, date_updated: string, sid: string, uri: string, username: string>
# operationId: FetchSipCredential
export def "fetch-sip-credential" [
  account_sid: string
  credential_list_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/SIP/CredentialLists/{CredentialListSid}/Credentials/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: CredentialListSid, var: credential_list_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, credential_list_sid: $credential_list_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a credential resource.
#
# POST /2010-04-01/Accounts/{AccountSid}/SIP/CredentialLists/{CredentialListSid}/Credentials/{Sid}.json
# Returns: record<account_sid: string, credential_list_sid: string, date_created: string, date_updated: string, sid: string, uri: string, username: string>
# operationId: UpdateSipCredential
export def "update-sip-credential" [
  account_sid: string
  credential_list_sid: string
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
  --password: string # The password that the username will use when authenticating SIP requests. The password must be a minimum of 12 characters, contain at least 1 digit, and have mixed case. (eg `IWasAtSignal2018`)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2010-04-01/Accounts/{AccountSid}/SIP/CredentialLists/{CredentialListSid}/Credentials/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: CredentialListSid, var: credential_list_sid}, {name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Password, var: password}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, credential_list_sid: $credential_list_sid, sid: $sid, password: $password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a Credential List
#
# DELETE /2010-04-01/Accounts/{AccountSid}/SIP/CredentialLists/{Sid}.json
# operationId: DeleteSipCredentialList
export def "delete-sip-credential-list" [
  account_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/SIP/CredentialLists/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a Credential List
#
# GET /2010-04-01/Accounts/{AccountSid}/SIP/CredentialLists/{Sid}.json
# Returns: record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sid: string, subresource_uris: record, uri: string>
# operationId: FetchSipCredentialList
export def "fetch-sip-credential-list" [
  account_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/SIP/CredentialLists/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a Credential List
#
# POST /2010-04-01/Accounts/{AccountSid}/SIP/CredentialLists/{Sid}.json
# Returns: record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sid: string, subresource_uris: record, uri: string>
# operationId: UpdateSipCredentialList
export def "update-sip-credential-list" [
  account_sid: string
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
  friendly_name: string # A human readable descriptive text for a CredentialList, up to 64 characters long.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2010-04-01/Accounts/{AccountSid}/SIP/CredentialLists/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: FriendlyName, var: friendly_name}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, sid: $sid, friendly_name: $friendly_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of domains belonging to the account used to make the request
#
# GET /2010-04-01/Accounts/{AccountSid}/SIP/Domains.json
# Returns: record<domains: table<account_sid: string, api_version: string, auth_type: string, byoc_trunk_sid: string, date_created: string, date_updated: string, domain_name: string, emergency_caller_sid: string, emergency_calling_enabled: bool, friendly_name: string, secure: bool, sid: string, sip_registration: bool, subresource_uris: record, uri: string, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_status_callback_method: string, voice_status_callback_url: string, voice_url: string>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>
# operationId: ListSipDomain
export def "list-sip-domain" [
  account_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/SIP/Domains.json"
    path_params: [{name: AccountSid, var: account_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new Domain
#
# POST /2010-04-01/Accounts/{AccountSid}/SIP/Domains.json
# Returns: record<account_sid: string, api_version: string, auth_type: string, byoc_trunk_sid: string, date_created: string, date_updated: string, domain_name: string, emergency_caller_sid: string, emergency_calling_enabled: bool, friendly_name: string, secure: bool, sid: string, sip_registration: bool, subresource_uris: record, uri: string, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_status_callback_method: string, voice_status_callback_url: string, voice_url: string>
# operationId: CreateSipDomain
export def "create-sip-domain" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --byoc-trunk-sid: string # The SID of the BYOC Trunk(Bring Your Own Carrier) resource that the Sip Domain will be associated with.
  domain_name: string # The unique address you reserve on Twilio to which you route your SIP traffic. Domain names can contain letters, digits, and "-" and must end with `sip.twilio.com`.
  --emergency-caller-sid: string # Whether an emergency caller sid is configured for the domain. If present, this phone number will be used as the callback for the emergency call.
  --emergency-calling-enabled: oneof<nothing, bool> # Whether emergency calling is enabled for the domain. If enabled, allows emergency calls on the domain from phone numbers with validated addresses.
  --friendly-name: string # A descriptive string that you created to describe the resource. It can be up to 64 characters long.
  --secure: oneof<nothing, bool> # Whether secure SIP is enabled for the domain. If enabled, TLS will be enforced and SRTP will be negotiated on all incoming calls to this sip domain.
  --sip-registration: oneof<nothing, bool> # Whether to allow SIP Endpoints to register with the domain to receive calls. Can be `true` or `false`. `true` allows SIP Endpoints to register with the domain to receive calls, `false` does not.
  --voice-fallback-method: string@voice-fallback-method-completer # The HTTP method we should use to call `voice_fallback_url`. Can be: `GET` or `POST`. (format: http-method)
  --voice-fallback-url: string # The URL that we should call when an error occurs while retrieving or executing the TwiML from `voice_url`. (format: uri)
  --voice-method: string@voice-method-completer # The HTTP method we should use to call `voice_url`. Can be: `GET` or `POST`. (format: http-method)
  --voice-status-callback-method: string@voice-status-callback-method-completer # The HTTP method we should use to call `voice_status_callback_url`. Can be: `GET` or `POST`. (format: http-method)
  --voice-status-callback-url: string # The URL that we should call to pass status parameters (such as call ended) to your application. (format: uri)
  --voice-url: string # The URL we should when the domain receives a call. (format: uri)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2010-04-01/Accounts/{AccountSid}/SIP/Domains.json"
    path_params: [{name: AccountSid, var: account_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: ByocTrunkSid, var: byoc_trunk_sid}, {name: DomainName, var: domain_name}, {name: EmergencyCallerSid, var: emergency_caller_sid}, {name: EmergencyCallingEnabled, var: emergency_calling_enabled}, {name: FriendlyName, var: friendly_name}, {name: Secure, var: secure}, {name: SipRegistration, var: sip_registration}, {name: VoiceFallbackMethod, var: voice_fallback_method}, {name: VoiceFallbackUrl, var: voice_fallback_url}, {name: VoiceMethod, var: voice_method}, {name: VoiceStatusCallbackMethod, var: voice_status_callback_method}, {name: VoiceStatusCallbackUrl, var: voice_status_callback_url}, {name: VoiceUrl, var: voice_url}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, byoc_trunk_sid: $byoc_trunk_sid, domain_name: $domain_name, emergency_caller_sid: $emergency_caller_sid, emergency_calling_enabled: $emergency_calling_enabled, friendly_name: $friendly_name, secure: $secure, sip_registration: $sip_registration, voice_fallback_method: $voice_fallback_method, voice_fallback_url: $voice_fallback_url, voice_method: $voice_method, voice_status_callback_method: $voice_status_callback_method, voice_status_callback_url: $voice_status_callback_url, voice_url: $voice_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of credential list mappings belonging to the domain used in the request
#
# GET /2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/Auth/Calls/CredentialListMappings.json
# Returns: record<contents: table<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sid: string>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>
# operationId: ListSipAuthCallsCredentialListMapping
export def "list-sip-auth-calls-credential-list-mapping" [
  account_sid: string
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
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/Auth/Calls/CredentialListMappings.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: DomainSid, var: domain_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, domain_sid: $domain_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new credential list mapping resource
#
# POST /2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/Auth/Calls/CredentialListMappings.json
# Returns: record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sid: string>
# operationId: CreateSipAuthCallsCredentialListMapping
export def "create-sip-auth-calls-credential-list-mapping" [
  account_sid: string
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
  credential_list_sid: string # The SID of the CredentialList resource to map to the SIP domain.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/Auth/Calls/CredentialListMappings.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: DomainSid, var: domain_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: CredentialListSid, var: credential_list_sid}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, domain_sid: $domain_sid, credential_list_sid: $credential_list_sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a credential list mapping from the requested domain
#
# DELETE /2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/Auth/Calls/CredentialListMappings/{Sid}.json
# operationId: DeleteSipAuthCallsCredentialListMapping
export def "delete-sip-auth-calls-credential-list-mapping" [
  account_sid: string
  domain_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/Auth/Calls/CredentialListMappings/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: DomainSid, var: domain_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, domain_sid: $domain_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a specific instance of a credential list mapping
#
# GET /2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/Auth/Calls/CredentialListMappings/{Sid}.json
# Returns: record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sid: string>
# operationId: FetchSipAuthCallsCredentialListMapping
export def "fetch-sip-auth-calls-credential-list-mapping" [
  account_sid: string
  domain_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/Auth/Calls/CredentialListMappings/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: DomainSid, var: domain_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, domain_sid: $domain_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of IP Access Control List mappings belonging to the domain used in the request
#
# GET /2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/Auth/Calls/IpAccessControlListMappings.json
# Returns: record<contents: table<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sid: string>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>
# operationId: ListSipAuthCallsIpAccessControlListMapping
export def "list-sip-auth-calls-ip-access-control-list-mapping" [
  account_sid: string
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
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/Auth/Calls/IpAccessControlListMappings.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: DomainSid, var: domain_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, domain_sid: $domain_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new IP Access Control List mapping
#
# POST /2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/Auth/Calls/IpAccessControlListMappings.json
# Returns: record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sid: string>
# operationId: CreateSipAuthCallsIpAccessControlListMapping
export def "create-sip-auth-calls-ip-access-control-list-mapping" [
  account_sid: string
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
  ip_access_control_list_sid: string # The SID of the IpAccessControlList resource to map to the SIP domain.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/Auth/Calls/IpAccessControlListMappings.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: DomainSid, var: domain_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: IpAccessControlListSid, var: ip_access_control_list_sid}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, domain_sid: $domain_sid, ip_access_control_list_sid: $ip_access_control_list_sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an IP Access Control List mapping from the requested domain
#
# DELETE /2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/Auth/Calls/IpAccessControlListMappings/{Sid}.json
# operationId: DeleteSipAuthCallsIpAccessControlListMapping
export def "delete-sip-auth-calls-ip-access-control-list-mapping" [
  account_sid: string
  domain_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/Auth/Calls/IpAccessControlListMappings/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: DomainSid, var: domain_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, domain_sid: $domain_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a specific instance of an IP Access Control List mapping
#
# GET /2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/Auth/Calls/IpAccessControlListMappings/{Sid}.json
# Returns: record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sid: string>
# operationId: FetchSipAuthCallsIpAccessControlListMapping
export def "fetch-sip-auth-calls-ip-access-control-list-mapping" [
  account_sid: string
  domain_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/Auth/Calls/IpAccessControlListMappings/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: DomainSid, var: domain_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, domain_sid: $domain_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of credential list mappings belonging to the domain used in the request
#
# GET /2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/Auth/Registrations/CredentialListMappings.json
# Returns: record<contents: table<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sid: string>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>
# operationId: ListSipAuthRegistrationsCredentialListMapping
export def "list-sip-auth-registrations-credential-list-mapping" [
  account_sid: string
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
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/Auth/Registrations/CredentialListMappings.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: DomainSid, var: domain_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, domain_sid: $domain_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new credential list mapping resource
#
# POST /2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/Auth/Registrations/CredentialListMappings.json
# Returns: record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sid: string>
# operationId: CreateSipAuthRegistrationsCredentialListMapping
export def "create-sip-auth-registrations-credential-list-mapping" [
  account_sid: string
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
  credential_list_sid: string # The SID of the CredentialList resource to map to the SIP domain.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/Auth/Registrations/CredentialListMappings.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: DomainSid, var: domain_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: CredentialListSid, var: credential_list_sid}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, domain_sid: $domain_sid, credential_list_sid: $credential_list_sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a credential list mapping from the requested domain
#
# DELETE /2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/Auth/Registrations/CredentialListMappings/{Sid}.json
# operationId: DeleteSipAuthRegistrationsCredentialListMapping
export def "delete-sip-auth-registrations-credential-list-mapping" [
  account_sid: string
  domain_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/Auth/Registrations/CredentialListMappings/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: DomainSid, var: domain_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, domain_sid: $domain_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a specific instance of a credential list mapping
#
# GET /2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/Auth/Registrations/CredentialListMappings/{Sid}.json
# Returns: record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sid: string>
# operationId: FetchSipAuthRegistrationsCredentialListMapping
export def "fetch-sip-auth-registrations-credential-list-mapping" [
  account_sid: string
  domain_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/Auth/Registrations/CredentialListMappings/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: DomainSid, var: domain_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, domain_sid: $domain_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Read multiple CredentialListMapping resources from an account.
#
# GET /2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/CredentialListMappings.json
# Returns: record<credential_list_mappings: table<account_sid: string, date_created: string, date_updated: string, domain_sid: string, friendly_name: string, sid: string, uri: string>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>
# operationId: ListSipCredentialListMapping
export def "list-sip-credential-list-mapping" [
  account_sid: string
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
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/CredentialListMappings.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: DomainSid, var: domain_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, domain_sid: $domain_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a CredentialListMapping resource for an account.
#
# POST /2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/CredentialListMappings.json
# Returns: record<account_sid: string, date_created: string, date_updated: string, domain_sid: string, friendly_name: string, sid: string, uri: string>
# operationId: CreateSipCredentialListMapping
export def "create-sip-credential-list-mapping" [
  account_sid: string
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
  credential_list_sid: string # A 34 character string that uniquely identifies the CredentialList resource to map to the SIP domain.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/CredentialListMappings.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: DomainSid, var: domain_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: CredentialListSid, var: credential_list_sid}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, domain_sid: $domain_sid, credential_list_sid: $credential_list_sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a CredentialListMapping resource from an account.
#
# DELETE /2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/CredentialListMappings/{Sid}.json
# operationId: DeleteSipCredentialListMapping
export def "delete-sip-credential-list-mapping" [
  account_sid: string
  domain_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/CredentialListMappings/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: DomainSid, var: domain_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, domain_sid: $domain_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a single CredentialListMapping resource from an account.
#
# GET /2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/CredentialListMappings/{Sid}.json
# Returns: record<account_sid: string, date_created: string, date_updated: string, domain_sid: string, friendly_name: string, sid: string, uri: string>
# operationId: FetchSipCredentialListMapping
export def "fetch-sip-credential-list-mapping" [
  account_sid: string
  domain_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/CredentialListMappings/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: DomainSid, var: domain_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, domain_sid: $domain_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of IpAccessControlListMapping resources.
#
# GET /2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/IpAccessControlListMappings.json
# Returns: record<end: int, first_page_uri: string, ip_access_control_list_mappings: table<account_sid: string, date_created: string, date_updated: string, domain_sid: string, friendly_name: string, sid: string, uri: string>, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>
# operationId: ListSipIpAccessControlListMapping
export def "list-sip-ip-access-control-list-mapping" [
  account_sid: string
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
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/IpAccessControlListMappings.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: DomainSid, var: domain_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, domain_sid: $domain_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new IpAccessControlListMapping resource.
#
# POST /2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/IpAccessControlListMappings.json
# Returns: record<account_sid: string, date_created: string, date_updated: string, domain_sid: string, friendly_name: string, sid: string, uri: string>
# operationId: CreateSipIpAccessControlListMapping
export def "create-sip-ip-access-control-list-mapping" [
  account_sid: string
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
  ip_access_control_list_sid: string # The unique id of the IP access control list to map to the SIP domain.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/IpAccessControlListMappings.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: DomainSid, var: domain_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: IpAccessControlListSid, var: ip_access_control_list_sid}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, domain_sid: $domain_sid, ip_access_control_list_sid: $ip_access_control_list_sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an IpAccessControlListMapping resource.
#
# DELETE /2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/IpAccessControlListMappings/{Sid}.json
# operationId: DeleteSipIpAccessControlListMapping
export def "delete-sip-ip-access-control-list-mapping" [
  account_sid: string
  domain_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/IpAccessControlListMappings/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: DomainSid, var: domain_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, domain_sid: $domain_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch an IpAccessControlListMapping resource.
#
# GET /2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/IpAccessControlListMappings/{Sid}.json
# Returns: record<account_sid: string, date_created: string, date_updated: string, domain_sid: string, friendly_name: string, sid: string, uri: string>
# operationId: FetchSipIpAccessControlListMapping
export def "fetch-sip-ip-access-control-list-mapping" [
  account_sid: string
  domain_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/IpAccessControlListMappings/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: DomainSid, var: domain_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, domain_sid: $domain_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an instance of a Domain
#
# DELETE /2010-04-01/Accounts/{AccountSid}/SIP/Domains/{Sid}.json
# operationId: DeleteSipDomain
export def "delete-sip-domain" [
  account_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/SIP/Domains/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch an instance of a Domain
#
# GET /2010-04-01/Accounts/{AccountSid}/SIP/Domains/{Sid}.json
# Returns: record<account_sid: string, api_version: string, auth_type: string, byoc_trunk_sid: string, date_created: string, date_updated: string, domain_name: string, emergency_caller_sid: string, emergency_calling_enabled: bool, friendly_name: string, secure: bool, sid: string, sip_registration: bool, subresource_uris: record, uri: string, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_status_callback_method: string, voice_status_callback_url: string, voice_url: string>
# operationId: FetchSipDomain
export def "fetch-sip-domain" [
  account_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/SIP/Domains/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the attributes of a domain
#
# POST /2010-04-01/Accounts/{AccountSid}/SIP/Domains/{Sid}.json
# Returns: record<account_sid: string, api_version: string, auth_type: string, byoc_trunk_sid: string, date_created: string, date_updated: string, domain_name: string, emergency_caller_sid: string, emergency_calling_enabled: bool, friendly_name: string, secure: bool, sid: string, sip_registration: bool, subresource_uris: record, uri: string, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_status_callback_method: string, voice_status_callback_url: string, voice_url: string>
# operationId: UpdateSipDomain
export def "update-sip-domain" [
  account_sid: string
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
  --byoc-trunk-sid: string # The SID of the BYOC Trunk(Bring Your Own Carrier) resource that the Sip Domain will be associated with.
  --domain-name: string # The unique address you reserve on Twilio to which you route your SIP traffic. Domain names can contain letters, digits, and "-" and must end with `sip.twilio.com`.
  --emergency-caller-sid: string # Whether an emergency caller sid is configured for the domain. If present, this phone number will be used as the callback for the emergency call.
  --emergency-calling-enabled: oneof<nothing, bool> # Whether emergency calling is enabled for the domain. If enabled, allows emergency calls on the domain from phone numbers with validated addresses.
  --friendly-name: string # A descriptive string that you created to describe the resource. It can be up to 64 characters long.
  --secure: oneof<nothing, bool> # Whether secure SIP is enabled for the domain. If enabled, TLS will be enforced and SRTP will be negotiated on all incoming calls to this sip domain.
  --sip-registration: oneof<nothing, bool> # Whether to allow SIP Endpoints to register with the domain to receive calls. Can be `true` or `false`. `true` allows SIP Endpoints to register with the domain to receive calls, `false` does not.
  --voice-fallback-method: string@voice-fallback-method-completer # The HTTP method we should use to call `voice_fallback_url`. Can be: `GET` or `POST`. (format: http-method)
  --voice-fallback-url: string # The URL that we should call when an error occurs while retrieving or executing the TwiML requested by `voice_url`. (format: uri)
  --voice-method: string@voice-method-completer # The HTTP method we should use to call `voice_url` (format: http-method)
  --voice-status-callback-method: string@voice-status-callback-method-completer # The HTTP method we should use to call `voice_status_callback_url`. Can be: `GET` or `POST`. (format: http-method)
  --voice-status-callback-url: string # The URL that we should call to pass status parameters (such as call ended) to your application. (format: uri)
  --voice-url: string # The URL we should call when the domain receives a call. (format: uri)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2010-04-01/Accounts/{AccountSid}/SIP/Domains/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: ByocTrunkSid, var: byoc_trunk_sid}, {name: DomainName, var: domain_name}, {name: EmergencyCallerSid, var: emergency_caller_sid}, {name: EmergencyCallingEnabled, var: emergency_calling_enabled}, {name: FriendlyName, var: friendly_name}, {name: Secure, var: secure}, {name: SipRegistration, var: sip_registration}, {name: VoiceFallbackMethod, var: voice_fallback_method}, {name: VoiceFallbackUrl, var: voice_fallback_url}, {name: VoiceMethod, var: voice_method}, {name: VoiceStatusCallbackMethod, var: voice_status_callback_method}, {name: VoiceStatusCallbackUrl, var: voice_status_callback_url}, {name: VoiceUrl, var: voice_url}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, sid: $sid, byoc_trunk_sid: $byoc_trunk_sid, domain_name: $domain_name, emergency_caller_sid: $emergency_caller_sid, emergency_calling_enabled: $emergency_calling_enabled, friendly_name: $friendly_name, secure: $secure, sip_registration: $sip_registration, voice_fallback_method: $voice_fallback_method, voice_fallback_url: $voice_fallback_url, voice_method: $voice_method, voice_status_callback_method: $voice_status_callback_method, voice_status_callback_url: $voice_status_callback_url, voice_url: $voice_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of IpAccessControlLists that belong to the account used to make the request
#
# GET /2010-04-01/Accounts/{AccountSid}/SIP/IpAccessControlLists.json
# Returns: record<end: int, first_page_uri: string, ip_access_control_lists: table<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sid: string, subresource_uris: record, uri: string>, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>
# operationId: ListSipIpAccessControlList
export def "list-sip-ip-access-control-list" [
  account_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/SIP/IpAccessControlLists.json"
    path_params: [{name: AccountSid, var: account_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new IpAccessControlList resource
#
# POST /2010-04-01/Accounts/{AccountSid}/SIP/IpAccessControlLists.json
# Returns: record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sid: string, subresource_uris: record, uri: string>
# operationId: CreateSipIpAccessControlList
export def "create-sip-ip-access-control-list" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  friendly_name: string # A human readable descriptive text that describes the IpAccessControlList, up to 255 characters long.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2010-04-01/Accounts/{AccountSid}/SIP/IpAccessControlLists.json"
    path_params: [{name: AccountSid, var: account_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: FriendlyName, var: friendly_name}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, friendly_name: $friendly_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Read multiple IpAddress resources.
#
# GET /2010-04-01/Accounts/{AccountSid}/SIP/IpAccessControlLists/{IpAccessControlListSid}/IpAddresses.json
# Returns: record<end: int, first_page_uri: string, ip_addresses: table<account_sid: string, cidr_prefix_length: int, date_created: string, date_updated: string, friendly_name: string, ip_access_control_list_sid: string, ip_address: string, sid: string, uri: string>, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string>
# operationId: ListSipIpAddress
export def "list-sip-ip-address" [
  account_sid: string
  ip_access_control_list_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/SIP/IpAccessControlLists/{IpAccessControlListSid}/IpAddresses.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: IpAccessControlListSid, var: ip_access_control_list_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, ip_access_control_list_sid: $ip_access_control_list_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new IpAddress resource.
#
# POST /2010-04-01/Accounts/{AccountSid}/SIP/IpAccessControlLists/{IpAccessControlListSid}/IpAddresses.json
# Returns: record<account_sid: string, cidr_prefix_length: int, date_created: string, date_updated: string, friendly_name: string, ip_access_control_list_sid: string, ip_address: string, sid: string, uri: string>
# operationId: CreateSipIpAddress
export def "create-sip-ip-address" [
  account_sid: string
  ip_access_control_list_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cidr-prefix-length: int # An integer representing the length of the CIDR prefix to use with this IP address when accepting traffic. By default the entire IP address is used.
  friendly_name: string # A human readable descriptive text for this resource, up to 255 characters long.
  ip_address: string # An IP address in dotted decimal notation from which you want to accept traffic. Any SIP requests from this IP address will be allowed by Twilio. IPv4 only supported today.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2010-04-01/Accounts/{AccountSid}/SIP/IpAccessControlLists/{IpAccessControlListSid}/IpAddresses.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: IpAccessControlListSid, var: ip_access_control_list_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: CidrPrefixLength, var: cidr_prefix_length}, {name: FriendlyName, var: friendly_name}, {name: IpAddress, var: ip_address}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, ip_access_control_list_sid: $ip_access_control_list_sid, cidr_prefix_length: $cidr_prefix_length, friendly_name: $friendly_name, ip_address: $ip_address
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an IpAddress resource.
#
# DELETE /2010-04-01/Accounts/{AccountSid}/SIP/IpAccessControlLists/{IpAccessControlListSid}/IpAddresses/{Sid}.json
# operationId: DeleteSipIpAddress
export def "delete-sip-ip-address" [
  account_sid: string
  ip_access_control_list_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/SIP/IpAccessControlLists/{IpAccessControlListSid}/IpAddresses/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: IpAccessControlListSid, var: ip_access_control_list_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, ip_access_control_list_sid: $ip_access_control_list_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Read one IpAddress resource.
#
# GET /2010-04-01/Accounts/{AccountSid}/SIP/IpAccessControlLists/{IpAccessControlListSid}/IpAddresses/{Sid}.json
# Returns: record<account_sid: string, cidr_prefix_length: int, date_created: string, date_updated: string, friendly_name: string, ip_access_control_list_sid: string, ip_address: string, sid: string, uri: string>
# operationId: FetchSipIpAddress
export def "fetch-sip-ip-address" [
  account_sid: string
  ip_access_control_list_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/SIP/IpAccessControlLists/{IpAccessControlListSid}/IpAddresses/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: IpAccessControlListSid, var: ip_access_control_list_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, ip_access_control_list_sid: $ip_access_control_list_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an IpAddress resource.
#
# POST /2010-04-01/Accounts/{AccountSid}/SIP/IpAccessControlLists/{IpAccessControlListSid}/IpAddresses/{Sid}.json
# Returns: record<account_sid: string, cidr_prefix_length: int, date_created: string, date_updated: string, friendly_name: string, ip_access_control_list_sid: string, ip_address: string, sid: string, uri: string>
# operationId: UpdateSipIpAddress
export def "update-sip-ip-address" [
  account_sid: string
  ip_access_control_list_sid: string
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
  --cidr-prefix-length: int # An integer representing the length of the CIDR prefix to use with this IP address when accepting traffic. By default the entire IP address is used.
  --friendly-name: string # A human readable descriptive text for this resource, up to 255 characters long.
  --ip-address: string # An IP address in dotted decimal notation from which you want to accept traffic. Any SIP requests from this IP address will be allowed by Twilio. IPv4 only supported today.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2010-04-01/Accounts/{AccountSid}/SIP/IpAccessControlLists/{IpAccessControlListSid}/IpAddresses/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: IpAccessControlListSid, var: ip_access_control_list_sid}, {name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: CidrPrefixLength, var: cidr_prefix_length}, {name: FriendlyName, var: friendly_name}, {name: IpAddress, var: ip_address}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, ip_access_control_list_sid: $ip_access_control_list_sid, sid: $sid, cidr_prefix_length: $cidr_prefix_length, friendly_name: $friendly_name, ip_address: $ip_address
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an IpAccessControlList from the requested account
#
# DELETE /2010-04-01/Accounts/{AccountSid}/SIP/IpAccessControlLists/{Sid}.json
# operationId: DeleteSipIpAccessControlList
export def "delete-sip-ip-access-control-list" [
  account_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/SIP/IpAccessControlLists/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a specific instance of an IpAccessControlList
#
# GET /2010-04-01/Accounts/{AccountSid}/SIP/IpAccessControlLists/{Sid}.json
# Returns: record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sid: string, subresource_uris: record, uri: string>
# operationId: FetchSipIpAccessControlList
export def "fetch-sip-ip-access-control-list" [
  account_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/SIP/IpAccessControlLists/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Rename an IpAccessControlList
#
# POST /2010-04-01/Accounts/{AccountSid}/SIP/IpAccessControlLists/{Sid}.json
# Returns: record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sid: string, subresource_uris: record, uri: string>
# operationId: UpdateSipIpAccessControlList
export def "update-sip-ip-access-control-list" [
  account_sid: string
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
  friendly_name: string # A human readable descriptive text, up to 255 characters long.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2010-04-01/Accounts/{AccountSid}/SIP/IpAccessControlLists/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: FriendlyName, var: friendly_name}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, sid: $sid, friendly_name: $friendly_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of short-codes belonging to the account used to make the request
#
# GET /2010-04-01/Accounts/{AccountSid}/SMS/ShortCodes.json
# Returns: record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, short_codes: table<account_sid: string, api_version: string, date_created: string, date_updated: string, friendly_name: string, short_code: string, sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, uri: string>, start: int, uri: string>
# operationId: ListShortCode
export def "list-short-code" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --friendly-name: string # The string that identifies the ShortCode resources to read.
  --short-code: string # Only show the ShortCode resources that match this pattern. You can specify partial numbers and use '*' as a wildcard for any digit.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2010-04-01/Accounts/{AccountSid}/SMS/ShortCodes.json"
    path_params: [{name: AccountSid, var: account_sid}]
    query: [{name: FriendlyName, var: friendly_name}, {name: ShortCode, var: short_code}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, friendly_name: $friendly_name, short_code: $short_code, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch an instance of a short code
#
# GET /2010-04-01/Accounts/{AccountSid}/SMS/ShortCodes/{Sid}.json
# Returns: record<account_sid: string, api_version: string, date_created: string, date_updated: string, friendly_name: string, short_code: string, sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, uri: string>
# operationId: FetchShortCode
export def "fetch-short-code" [
  account_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/SMS/ShortCodes/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a short code with the following parameters
#
# POST /2010-04-01/Accounts/{AccountSid}/SMS/ShortCodes/{Sid}.json
# Returns: record<account_sid: string, api_version: string, date_created: string, date_updated: string, friendly_name: string, short_code: string, sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, uri: string>
# operationId: UpdateShortCode
export def "update-short-code" [
  account_sid: string
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
  --api-version: string # The API version to use to start a new TwiML session. Can be: `2010-04-01` or `2008-08-01`.
  --friendly-name: string # A descriptive string that you created to describe this resource. It can be up to 64 characters long. By default, the `FriendlyName` is the short code.
  --sms-fallback-method: string@sms-fallback-method-completer # The HTTP method that we should use to call the `sms_fallback_url`. Can be: `GET` or `POST`. (format: http-method)
  --sms-fallback-url: string # The URL that we should call if an error occurs while retrieving or executing the TwiML from `sms_url`. (format: uri)
  --sms-method: string@sms-method-completer # The HTTP method we should use when calling the `sms_url`. Can be: `GET` or `POST`. (format: http-method)
  --sms-url: string # The URL we should call when receiving an incoming SMS message to this short code. (format: uri)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2010-04-01/Accounts/{AccountSid}/SMS/ShortCodes/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: ApiVersion, var: api_version}, {name: FriendlyName, var: friendly_name}, {name: SmsFallbackMethod, var: sms_fallback_method}, {name: SmsFallbackUrl, var: sms_fallback_url}, {name: SmsMethod, var: sms_method}, {name: SmsUrl, var: sms_url}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, sid: $sid, api_version: $api_version, friendly_name: $friendly_name, sms_fallback_method: $sms_fallback_method, sms_fallback_url: $sms_fallback_url, sms_method: $sms_method, sms_url: $sms_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /2010-04-01/Accounts/{AccountSid}/SigningKeys.json
#
# Returns: record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, signing_keys: table<date_created: string, date_updated: string, friendly_name: string, sid: string>, start: int, uri: string>
# operationId: ListSigningKey
export def "list-signing-key" [
  account_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/SigningKeys.json"
    path_params: [{name: AccountSid, var: account_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new Signing Key for the account making the request.
#
# POST /2010-04-01/Accounts/{AccountSid}/SigningKeys.json
# Returns: record<date_created: string, date_updated: string, friendly_name: string, secret: string, sid: string>
# operationId: CreateNewSigningKey
export def "create-new-signing-key" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --friendly-name: string # A descriptive string that you create to describe the resource. It can be up to 64 characters long.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2010-04-01/Accounts/{AccountSid}/SigningKeys.json"
    path_params: [{name: AccountSid, var: account_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: FriendlyName, var: friendly_name}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, friendly_name: $friendly_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /2010-04-01/Accounts/{AccountSid}/SigningKeys/{Sid}.json
#
# operationId: DeleteSigningKey
export def "delete-signing-key" [
  account_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/SigningKeys/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /2010-04-01/Accounts/{AccountSid}/SigningKeys/{Sid}.json
#
# Returns: record<date_created: string, date_updated: string, friendly_name: string, sid: string>
# operationId: FetchSigningKey
export def "fetch-signing-key" [
  account_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/SigningKeys/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /2010-04-01/Accounts/{AccountSid}/SigningKeys/{Sid}.json
#
# Returns: record<date_created: string, date_updated: string, friendly_name: string, sid: string>
# operationId: UpdateSigningKey
export def "update-signing-key" [
  account_sid: string
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
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2010-04-01/Accounts/{AccountSid}/SigningKeys/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: FriendlyName, var: friendly_name}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, sid: $sid, friendly_name: $friendly_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new token for ICE servers
#
# POST /2010-04-01/Accounts/{AccountSid}/Tokens.json
# Returns: record<account_sid: string, date_created: string, date_updated: string, ice_servers: table<credential: string, url: string, urls: string, username: string>, password: string, ttl: string, username: string>
# operationId: CreateToken
export def "create-token" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ttl: int # The duration in seconds for which the generated credentials are valid. The default value is 86400 (24 hours).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2010-04-01/Accounts/{AccountSid}/Tokens.json"
    path_params: [{name: AccountSid, var: account_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Ttl, var: ttl}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, ttl: $ttl
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of transcriptions belonging to the account used to make the request
#
# GET /2010-04-01/Accounts/{AccountSid}/Transcriptions.json
# Returns: record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, transcriptions: table<account_sid: string, api_version: string, date_created: string, date_updated: string, duration: string, price: float, price_unit: string, recording_sid: string, sid: string, status: string, transcription_text: string, type: string, uri: string>, uri: string>
# operationId: ListTranscription
export def "list-transcription" [
  account_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/Transcriptions.json"
    path_params: [{name: AccountSid, var: account_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a transcription from the account used to make the request
#
# DELETE /2010-04-01/Accounts/{AccountSid}/Transcriptions/{Sid}.json
# operationId: DeleteTranscription
export def "delete-transcription" [
  account_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/Transcriptions/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch an instance of a Transcription
#
# GET /2010-04-01/Accounts/{AccountSid}/Transcriptions/{Sid}.json
# Returns: record<account_sid: string, api_version: string, date_created: string, date_updated: string, duration: string, price: float, price_unit: string, recording_sid: string, sid: string, status: string, transcription_text: string, type: string, uri: string>
# operationId: FetchTranscription
export def "fetch-transcription" [
  account_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/Transcriptions/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of usage-records belonging to the account used to make the request
#
# GET /2010-04-01/Accounts/{AccountSid}/Usage/Records.json
# Returns: record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, usage_records: table<account_sid: string, api_version: string, as_of: string, category: string, count: string, count_unit: string, description: string, end_date: string, price: float, price_unit: string, start_date: string, subresource_uris: record, uri: string, usage: string, usage_unit: string>>
# operationId: ListUsageRecord
export def "list-usage-record" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category: string@category-completer # The [usage category](https://www.twilio.com/docs/usage/api/usage-record#usage-categories) of the UsageRecord resources to read. Only UsageRecord resources in the specified category are retrieved.
  --start-date: string # Only include usage that has occurred on or after this date. Specify the date in GMT and format as `YYYY-MM-DD`. You can also specify offsets from the current date, such as: `-30days`, which will set the start date to be 30 days before the current date. (format: date)
  --end-date: string # Only include usage that occurred on or before this date. Specify the date in GMT and format as `YYYY-MM-DD`. You can also specify offsets from the current date, such as: `+30days`, which will set the end date to 30 days from the current date. (format: date)
  --include-subaccounts: oneof<nothing, bool> # Whether to include usage from the master account and all its subaccounts. Can be: `true` (the default) to include usage from the master account and all subaccounts or `false` to retrieve usage from only the specified account.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2010-04-01/Accounts/{AccountSid}/Usage/Records.json"
    path_params: [{name: AccountSid, var: account_sid}]
    query: [{name: Category, var: category}, {name: StartDate, var: start_date}, {name: EndDate, var: end_date}, {name: IncludeSubaccounts, var: include_subaccounts}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, category: $category, start_date: $start_date, end_date: $end_date, include_subaccounts: $include_subaccounts, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /2010-04-01/Accounts/{AccountSid}/Usage/Records/AllTime.json
#
# Returns: record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, usage_records: table<account_sid: string, api_version: string, as_of: string, category: string, count: string, count_unit: string, description: string, end_date: string, price: float, price_unit: string, start_date: string, subresource_uris: record, uri: string, usage: string, usage_unit: string>>
# operationId: ListUsageRecordAllTime
export def "list-usage-record-all-time" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category: string@category-completer # The [usage category](https://www.twilio.com/docs/usage/api/usage-record#usage-categories) of the UsageRecord resources to read. Only UsageRecord resources in the specified category are retrieved.
  --start-date: string # Only include usage that has occurred on or after this date. Specify the date in GMT and format as `YYYY-MM-DD`. You can also specify offsets from the current date, such as: `-30days`, which will set the start date to be 30 days before the current date. (format: date)
  --end-date: string # Only include usage that occurred on or before this date. Specify the date in GMT and format as `YYYY-MM-DD`. You can also specify offsets from the current date, such as: `+30days`, which will set the end date to 30 days from the current date. (format: date)
  --include-subaccounts: oneof<nothing, bool> # Whether to include usage from the master account and all its subaccounts. Can be: `true` (the default) to include usage from the master account and all subaccounts or `false` to retrieve usage from only the specified account.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2010-04-01/Accounts/{AccountSid}/Usage/Records/AllTime.json"
    path_params: [{name: AccountSid, var: account_sid}]
    query: [{name: Category, var: category}, {name: StartDate, var: start_date}, {name: EndDate, var: end_date}, {name: IncludeSubaccounts, var: include_subaccounts}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, category: $category, start_date: $start_date, end_date: $end_date, include_subaccounts: $include_subaccounts, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /2010-04-01/Accounts/{AccountSid}/Usage/Records/Daily.json
#
# Returns: record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, usage_records: table<account_sid: string, api_version: string, as_of: string, category: string, count: string, count_unit: string, description: string, end_date: string, price: float, price_unit: string, start_date: string, subresource_uris: record, uri: string, usage: string, usage_unit: string>>
# operationId: ListUsageRecordDaily
export def "list-usage-record-daily" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category: string@category-completer # The [usage category](https://www.twilio.com/docs/usage/api/usage-record#usage-categories) of the UsageRecord resources to read. Only UsageRecord resources in the specified category are retrieved.
  --start-date: string # Only include usage that has occurred on or after this date. Specify the date in GMT and format as `YYYY-MM-DD`. You can also specify offsets from the current date, such as: `-30days`, which will set the start date to be 30 days before the current date. (format: date)
  --end-date: string # Only include usage that occurred on or before this date. Specify the date in GMT and format as `YYYY-MM-DD`. You can also specify offsets from the current date, such as: `+30days`, which will set the end date to 30 days from the current date. (format: date)
  --include-subaccounts: oneof<nothing, bool> # Whether to include usage from the master account and all its subaccounts. Can be: `true` (the default) to include usage from the master account and all subaccounts or `false` to retrieve usage from only the specified account.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2010-04-01/Accounts/{AccountSid}/Usage/Records/Daily.json"
    path_params: [{name: AccountSid, var: account_sid}]
    query: [{name: Category, var: category}, {name: StartDate, var: start_date}, {name: EndDate, var: end_date}, {name: IncludeSubaccounts, var: include_subaccounts}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, category: $category, start_date: $start_date, end_date: $end_date, include_subaccounts: $include_subaccounts, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /2010-04-01/Accounts/{AccountSid}/Usage/Records/LastMonth.json
#
# Returns: record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, usage_records: table<account_sid: string, api_version: string, as_of: string, category: string, count: string, count_unit: string, description: string, end_date: string, price: float, price_unit: string, start_date: string, subresource_uris: record, uri: string, usage: string, usage_unit: string>>
# operationId: ListUsageRecordLastMonth
export def "list-usage-record-last-month" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category: string@category-completer # The [usage category](https://www.twilio.com/docs/usage/api/usage-record#usage-categories) of the UsageRecord resources to read. Only UsageRecord resources in the specified category are retrieved.
  --start-date: string # Only include usage that has occurred on or after this date. Specify the date in GMT and format as `YYYY-MM-DD`. You can also specify offsets from the current date, such as: `-30days`, which will set the start date to be 30 days before the current date. (format: date)
  --end-date: string # Only include usage that occurred on or before this date. Specify the date in GMT and format as `YYYY-MM-DD`. You can also specify offsets from the current date, such as: `+30days`, which will set the end date to 30 days from the current date. (format: date)
  --include-subaccounts: oneof<nothing, bool> # Whether to include usage from the master account and all its subaccounts. Can be: `true` (the default) to include usage from the master account and all subaccounts or `false` to retrieve usage from only the specified account.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2010-04-01/Accounts/{AccountSid}/Usage/Records/LastMonth.json"
    path_params: [{name: AccountSid, var: account_sid}]
    query: [{name: Category, var: category}, {name: StartDate, var: start_date}, {name: EndDate, var: end_date}, {name: IncludeSubaccounts, var: include_subaccounts}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, category: $category, start_date: $start_date, end_date: $end_date, include_subaccounts: $include_subaccounts, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /2010-04-01/Accounts/{AccountSid}/Usage/Records/Monthly.json
#
# Returns: record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, usage_records: table<account_sid: string, api_version: string, as_of: string, category: string, count: string, count_unit: string, description: string, end_date: string, price: float, price_unit: string, start_date: string, subresource_uris: record, uri: string, usage: string, usage_unit: string>>
# operationId: ListUsageRecordMonthly
export def "list-usage-record-monthly" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category: string@category-completer # The [usage category](https://www.twilio.com/docs/usage/api/usage-record#usage-categories) of the UsageRecord resources to read. Only UsageRecord resources in the specified category are retrieved.
  --start-date: string # Only include usage that has occurred on or after this date. Specify the date in GMT and format as `YYYY-MM-DD`. You can also specify offsets from the current date, such as: `-30days`, which will set the start date to be 30 days before the current date. (format: date)
  --end-date: string # Only include usage that occurred on or before this date. Specify the date in GMT and format as `YYYY-MM-DD`. You can also specify offsets from the current date, such as: `+30days`, which will set the end date to 30 days from the current date. (format: date)
  --include-subaccounts: oneof<nothing, bool> # Whether to include usage from the master account and all its subaccounts. Can be: `true` (the default) to include usage from the master account and all subaccounts or `false` to retrieve usage from only the specified account.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2010-04-01/Accounts/{AccountSid}/Usage/Records/Monthly.json"
    path_params: [{name: AccountSid, var: account_sid}]
    query: [{name: Category, var: category}, {name: StartDate, var: start_date}, {name: EndDate, var: end_date}, {name: IncludeSubaccounts, var: include_subaccounts}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, category: $category, start_date: $start_date, end_date: $end_date, include_subaccounts: $include_subaccounts, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /2010-04-01/Accounts/{AccountSid}/Usage/Records/ThisMonth.json
#
# Returns: record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, usage_records: table<account_sid: string, api_version: string, as_of: string, category: string, count: string, count_unit: string, description: string, end_date: string, price: float, price_unit: string, start_date: string, subresource_uris: record, uri: string, usage: string, usage_unit: string>>
# operationId: ListUsageRecordThisMonth
export def "list-usage-record-this-month" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category: string@category-completer # The [usage category](https://www.twilio.com/docs/usage/api/usage-record#usage-categories) of the UsageRecord resources to read. Only UsageRecord resources in the specified category are retrieved.
  --start-date: string # Only include usage that has occurred on or after this date. Specify the date in GMT and format as `YYYY-MM-DD`. You can also specify offsets from the current date, such as: `-30days`, which will set the start date to be 30 days before the current date. (format: date)
  --end-date: string # Only include usage that occurred on or before this date. Specify the date in GMT and format as `YYYY-MM-DD`. You can also specify offsets from the current date, such as: `+30days`, which will set the end date to 30 days from the current date. (format: date)
  --include-subaccounts: oneof<nothing, bool> # Whether to include usage from the master account and all its subaccounts. Can be: `true` (the default) to include usage from the master account and all subaccounts or `false` to retrieve usage from only the specified account.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2010-04-01/Accounts/{AccountSid}/Usage/Records/ThisMonth.json"
    path_params: [{name: AccountSid, var: account_sid}]
    query: [{name: Category, var: category}, {name: StartDate, var: start_date}, {name: EndDate, var: end_date}, {name: IncludeSubaccounts, var: include_subaccounts}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, category: $category, start_date: $start_date, end_date: $end_date, include_subaccounts: $include_subaccounts, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /2010-04-01/Accounts/{AccountSid}/Usage/Records/Today.json
#
# Returns: record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, usage_records: table<account_sid: string, api_version: string, as_of: string, category: string, count: string, count_unit: string, description: string, end_date: string, price: float, price_unit: string, start_date: string, subresource_uris: record, uri: string, usage: string, usage_unit: string>>
# operationId: ListUsageRecordToday
export def "list-usage-record-today" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category: string@category-completer # The [usage category](https://www.twilio.com/docs/usage/api/usage-record#usage-categories) of the UsageRecord resources to read. Only UsageRecord resources in the specified category are retrieved.
  --start-date: string # Only include usage that has occurred on or after this date. Specify the date in GMT and format as `YYYY-MM-DD`. You can also specify offsets from the current date, such as: `-30days`, which will set the start date to be 30 days before the current date. (format: date)
  --end-date: string # Only include usage that occurred on or before this date. Specify the date in GMT and format as `YYYY-MM-DD`. You can also specify offsets from the current date, such as: `+30days`, which will set the end date to 30 days from the current date. (format: date)
  --include-subaccounts: oneof<nothing, bool> # Whether to include usage from the master account and all its subaccounts. Can be: `true` (the default) to include usage from the master account and all subaccounts or `false` to retrieve usage from only the specified account.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2010-04-01/Accounts/{AccountSid}/Usage/Records/Today.json"
    path_params: [{name: AccountSid, var: account_sid}]
    query: [{name: Category, var: category}, {name: StartDate, var: start_date}, {name: EndDate, var: end_date}, {name: IncludeSubaccounts, var: include_subaccounts}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, category: $category, start_date: $start_date, end_date: $end_date, include_subaccounts: $include_subaccounts, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /2010-04-01/Accounts/{AccountSid}/Usage/Records/Yearly.json
#
# Returns: record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, usage_records: table<account_sid: string, api_version: string, as_of: string, category: string, count: string, count_unit: string, description: string, end_date: string, price: float, price_unit: string, start_date: string, subresource_uris: record, uri: string, usage: string, usage_unit: string>>
# operationId: ListUsageRecordYearly
export def "list-usage-record-yearly" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category: string@category-completer # The [usage category](https://www.twilio.com/docs/usage/api/usage-record#usage-categories) of the UsageRecord resources to read. Only UsageRecord resources in the specified category are retrieved.
  --start-date: string # Only include usage that has occurred on or after this date. Specify the date in GMT and format as `YYYY-MM-DD`. You can also specify offsets from the current date, such as: `-30days`, which will set the start date to be 30 days before the current date. (format: date)
  --end-date: string # Only include usage that occurred on or before this date. Specify the date in GMT and format as `YYYY-MM-DD`. You can also specify offsets from the current date, such as: `+30days`, which will set the end date to 30 days from the current date. (format: date)
  --include-subaccounts: oneof<nothing, bool> # Whether to include usage from the master account and all its subaccounts. Can be: `true` (the default) to include usage from the master account and all subaccounts or `false` to retrieve usage from only the specified account.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2010-04-01/Accounts/{AccountSid}/Usage/Records/Yearly.json"
    path_params: [{name: AccountSid, var: account_sid}]
    query: [{name: Category, var: category}, {name: StartDate, var: start_date}, {name: EndDate, var: end_date}, {name: IncludeSubaccounts, var: include_subaccounts}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, category: $category, start_date: $start_date, end_date: $end_date, include_subaccounts: $include_subaccounts, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /2010-04-01/Accounts/{AccountSid}/Usage/Records/Yesterday.json
#
# Returns: record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, usage_records: table<account_sid: string, api_version: string, as_of: string, category: string, count: string, count_unit: string, description: string, end_date: string, price: float, price_unit: string, start_date: string, subresource_uris: record, uri: string, usage: string, usage_unit: string>>
# operationId: ListUsageRecordYesterday
export def "list-usage-record-yesterday" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category: string@category-completer # The [usage category](https://www.twilio.com/docs/usage/api/usage-record#usage-categories) of the UsageRecord resources to read. Only UsageRecord resources in the specified category are retrieved.
  --start-date: string # Only include usage that has occurred on or after this date. Specify the date in GMT and format as `YYYY-MM-DD`. You can also specify offsets from the current date, such as: `-30days`, which will set the start date to be 30 days before the current date. (format: date)
  --end-date: string # Only include usage that occurred on or before this date. Specify the date in GMT and format as `YYYY-MM-DD`. You can also specify offsets from the current date, such as: `+30days`, which will set the end date to 30 days from the current date. (format: date)
  --include-subaccounts: oneof<nothing, bool> # Whether to include usage from the master account and all its subaccounts. Can be: `true` (the default) to include usage from the master account and all subaccounts or `false` to retrieve usage from only the specified account.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2010-04-01/Accounts/{AccountSid}/Usage/Records/Yesterday.json"
    path_params: [{name: AccountSid, var: account_sid}]
    query: [{name: Category, var: category}, {name: StartDate, var: start_date}, {name: EndDate, var: end_date}, {name: IncludeSubaccounts, var: include_subaccounts}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, category: $category, start_date: $start_date, end_date: $end_date, include_subaccounts: $include_subaccounts, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of usage-triggers belonging to the account used to make the request
#
# GET /2010-04-01/Accounts/{AccountSid}/Usage/Triggers.json
# Returns: record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, usage_triggers: table<account_sid: string, api_version: string, callback_method: string, callback_url: string, current_value: string, date_created: string, date_fired: string, date_updated: string, friendly_name: string, recurring: string, sid: string, trigger_by: string, trigger_value: string, uri: string, usage_category: string, usage_record_uri: string>>
# operationId: ListUsageTrigger
export def "list-usage-trigger" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --recurring: string@recurring-completer # The frequency of recurring UsageTriggers to read. Can be: `daily`, `monthly`, or `yearly` to read recurring UsageTriggers. An empty value or a value of `alltime` reads non-recurring UsageTriggers.
  --trigger-by: string@trigger-by-completer # The trigger field of the UsageTriggers to read. Can be: `count`, `usage`, or `price` as described in the [UsageRecords documentation](https://www.twilio.com/docs/usage/api/usage-record#usage-count-price).
  --usage-category: string@usage-category-completer # The usage category of the UsageTriggers to read. Must be a supported [usage categories](https://www.twilio.com/docs/usage/api/usage-record#usage-categories).
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2010-04-01/Accounts/{AccountSid}/Usage/Triggers.json"
    path_params: [{name: AccountSid, var: account_sid}]
    query: [{name: Recurring, var: recurring}, {name: TriggerBy, var: trigger_by}, {name: UsageCategory, var: usage_category}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, recurring: $recurring, trigger_by: $trigger_by, usage_category: $usage_category, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new UsageTrigger
#
# POST /2010-04-01/Accounts/{AccountSid}/Usage/Triggers.json
# Returns: record<account_sid: string, api_version: string, callback_method: string, callback_url: string, current_value: string, date_created: string, date_fired: string, date_updated: string, friendly_name: string, recurring: string, sid: string, trigger_by: string, trigger_value: string, uri: string, usage_category: string, usage_record_uri: string>
# operationId: CreateUsageTrigger
export def "create-usage-trigger" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --callback-method: string@callback-method-completer # The HTTP method we should use to call `callback_url`. Can be: `GET` or `POST` and the default is `POST`. (format: http-method)
  callback_url: string # The URL we should call using `callback_method` when the trigger fires. (format: uri)
  --friendly-name: string # A descriptive string that you create to describe the resource. It can be up to 64 characters long.
  --recurring: string@recurring-completer
  --trigger-by: string@trigger-by-completer
  trigger_value: string # The usage value at which the trigger should fire. For convenience, you can use an offset value such as `+30` to specify a trigger_value that is 30 units more than the current usage value. Be sure to urlencode a `+` as `%2B`.
  usage_category: string@usage-category-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2010-04-01/Accounts/{AccountSid}/Usage/Triggers.json"
    path_params: [{name: AccountSid, var: account_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: CallbackMethod, var: callback_method}, {name: CallbackUrl, var: callback_url}, {name: FriendlyName, var: friendly_name}, {name: Recurring, var: recurring}, {name: TriggerBy, var: trigger_by}, {name: TriggerValue, var: trigger_value}, {name: UsageCategory, var: usage_category}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, callback_method: $callback_method, callback_url: $callback_url, friendly_name: $friendly_name, recurring: $recurring, trigger_by: $trigger_by, trigger_value: $trigger_value, usage_category: $usage_category
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /2010-04-01/Accounts/{AccountSid}/Usage/Triggers/{Sid}.json
#
# operationId: DeleteUsageTrigger
export def "delete-usage-trigger" [
  account_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/Usage/Triggers/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch and instance of a usage-trigger
#
# GET /2010-04-01/Accounts/{AccountSid}/Usage/Triggers/{Sid}.json
# Returns: record<account_sid: string, api_version: string, callback_method: string, callback_url: string, current_value: string, date_created: string, date_fired: string, date_updated: string, friendly_name: string, recurring: string, sid: string, trigger_by: string, trigger_value: string, uri: string, usage_category: string, usage_record_uri: string>
# operationId: FetchUsageTrigger
export def "fetch-usage-trigger" [
  account_sid: string
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
    path: "/2010-04-01/Accounts/{AccountSid}/Usage/Triggers/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an instance of a usage trigger
#
# POST /2010-04-01/Accounts/{AccountSid}/Usage/Triggers/{Sid}.json
# Returns: record<account_sid: string, api_version: string, callback_method: string, callback_url: string, current_value: string, date_created: string, date_fired: string, date_updated: string, friendly_name: string, recurring: string, sid: string, trigger_by: string, trigger_value: string, uri: string, usage_category: string, usage_record_uri: string>
# operationId: UpdateUsageTrigger
export def "update-usage-trigger" [
  account_sid: string
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
  --callback-method: string@callback-method-completer # The HTTP method we should use to call `callback_url`. Can be: `GET` or `POST` and the default is `POST`. (format: http-method)
  --callback-url: string # The URL we should call using `callback_method` when the trigger fires. (format: uri)
  --friendly-name: string # A descriptive string that you create to describe the resource. It can be up to 64 characters long.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2010-04-01/Accounts/{AccountSid}/Usage/Triggers/{Sid}.json"
    path_params: [{name: AccountSid, var: account_sid}, {name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: CallbackMethod, var: callback_method}, {name: CallbackUrl, var: callback_url}, {name: FriendlyName, var: friendly_name}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    account_sid: $account_sid, sid: $sid, callback_method: $callback_method, callback_url: $callback_url, friendly_name: $friendly_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch the account specified by the provided Account Sid
#
# GET /2010-04-01/Accounts/{Sid}.json
# Returns: record<auth_token: string, date_created: string, date_updated: string, friendly_name: string, owner_account_sid: string, sid: string, status: string, subresource_uris: record, type: string, uri: string>
# operationId: FetchAccount
export def "fetch-account" [
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
    path: "/2010-04-01/Accounts/{Sid}.json"
    path_params: [{name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify the properties of a given Account
#
# POST /2010-04-01/Accounts/{Sid}.json
# Returns: record<auth_token: string, date_created: string, date_updated: string, friendly_name: string, owner_account_sid: string, sid: string, status: string, subresource_uris: record, type: string, uri: string>
# operationId: UpdateAccount
export def "update-account" [
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
  --friendly-name: string # Update the human-readable description of this Account
  --status: string@status-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2010-04-01/Accounts/{Sid}.json"
    path_params: [{name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: FriendlyName, var: friendly_name}, {name: Status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.twilio.com"
    auth: basic
  } {
    sid: $sid, friendly_name: $friendly_name, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
