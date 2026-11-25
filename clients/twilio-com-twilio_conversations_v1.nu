# Auto-generated client for Twilio - Conversations v1.42.0
# Source: https://api.apis.guru/v2/specs/twilio.com/twilio_conversations_v1/1.42.0/openapi.json
# Auth: --token flag or $env.TWILIO_CONVERSATIONS_TOKEN

const CLIENT = {
  base_url: "https://conversations.twilio.com"
  token_env_var: "TWILIO_CONVERSATIONS_TOKEN"
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

def base-url-completer [] { ["https://conversations.twilio.com"] }
def auth-scheme-completer [] { ["basic" "basic-credentials"] }

# Completers for enum parameters
def auto-creation-type-completer [] { ["default" "studio" "webhook"] }
def auto-creation-webhook-method-completer [] { ["GET" "POST"] }
def type-completer [] { ["gbm" "messenger" "sms" "whatsapp"] }
def target-completer [] { ["flex" "webhook"] }
def state-completer [] { ["active" "closed" "inactive"] }
def x-twilio-webhook-enabled-completer [] { ["false" "true"] }
def order-completer [] { ["asc" "desc"] }
def configuration-method-completer [] { ["GET" "POST"] }
def target-completer-1 [] { ["studio" "trigger" "webhook"] }
def type-completer-1 [] { ["apn" "fcm" "gcm"] }
def type-completer-2 [] { ["conversation" "service"] }
def notification-level-completer [] { ["default" "muted"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    fetch-configuration: "record<account_sid: string, default_chat_service_sid: string, default_closed_timer: string, default_inactive_timer: string, default_messaging_service_sid: string, links: record, url: string>"
    update-configuration: "record<account_sid: string, default_chat_service_sid: string, default_closed_timer: string, default_inactive_timer: string, default_messaging_service_sid: string, links: record, url: string>"
    list-configuration-address: "record<address_configurations: table<account_sid: string, address: string, auto_creation: any, date_created: string, date_updated: string, friendly_name: string, sid: string, type: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    create-configuration-address: "record<account_sid: string, address: string, auto_creation: any, date_created: string, date_updated: string, friendly_name: string, sid: string, type: string, url: string>"
    fetch-configuration-address: "record<account_sid: string, address: string, auto_creation: any, date_created: string, date_updated: string, friendly_name: string, sid: string, type: string, url: string>"
    update-configuration-address: "record<account_sid: string, address: string, auto_creation: any, date_created: string, date_updated: string, friendly_name: string, sid: string, type: string, url: string>"
    fetch-configuration-webhook: "record<account_sid: string, filters: list<string>, method: string, post_webhook_url: string, pre_webhook_url: string, target: string, url: string>"
    update-configuration-webhook: "record<account_sid: string, filters: list<string>, method: string, post_webhook_url: string, pre_webhook_url: string, target: string, url: string>"
    list-conversation: "record<conversations: table<account_sid: string, attributes: string, bindings: any, chat_service_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, messaging_service_sid: string, sid: string, state: string, timers: any, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    create-conversation: "record<account_sid: string, attributes: string, bindings: any, chat_service_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, messaging_service_sid: string, sid: string, state: string, timers: any, unique_name: string, url: string>"
    list-conversation-message: "record<messages: table<account_sid: string, attributes: string, author: string, body: string, content_sid: string, conversation_sid: string, date_created: string, date_updated: string, delivery: any, index: int, links: record, media: list, participant_sid: string, sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    create-conversation-message: "record<account_sid: string, attributes: string, author: string, body: string, content_sid: string, conversation_sid: string, date_created: string, date_updated: string, delivery: any, index: int, links: record, media: list<any>, participant_sid: string, sid: string, url: string>"
    list-conversation-message-receipt: "record<delivery_receipts: table<account_sid: string, channel_message_sid: string, conversation_sid: string, date_created: string, date_updated: string, error_code: int, message_sid: string, participant_sid: string, sid: string, status: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    fetch-conversation-message-receipt: "record<account_sid: string, channel_message_sid: string, conversation_sid: string, date_created: string, date_updated: string, error_code: int, message_sid: string, participant_sid: string, sid: string, status: string, url: string>"
    fetch-conversation-message: "record<account_sid: string, attributes: string, author: string, body: string, content_sid: string, conversation_sid: string, date_created: string, date_updated: string, delivery: any, index: int, links: record, media: list<any>, participant_sid: string, sid: string, url: string>"
    update-conversation-message: "record<account_sid: string, attributes: string, author: string, body: string, content_sid: string, conversation_sid: string, date_created: string, date_updated: string, delivery: any, index: int, links: record, media: list<any>, participant_sid: string, sid: string, url: string>"
    list-conversation-participant: "record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, participants: table<account_sid: string, attributes: string, conversation_sid: string, date_created: string, date_updated: string, identity: string, last_read_message_index: int, last_read_timestamp: string, messaging_binding: any, role_sid: string, sid: string, url: string>>"
    create-conversation-participant: "record<account_sid: string, attributes: string, conversation_sid: string, date_created: string, date_updated: string, identity: string, last_read_message_index: int, last_read_timestamp: string, messaging_binding: any, role_sid: string, sid: string, url: string>"
    fetch-conversation-participant: "record<account_sid: string, attributes: string, conversation_sid: string, date_created: string, date_updated: string, identity: string, last_read_message_index: int, last_read_timestamp: string, messaging_binding: any, role_sid: string, sid: string, url: string>"
    update-conversation-participant: "record<account_sid: string, attributes: string, conversation_sid: string, date_created: string, date_updated: string, identity: string, last_read_message_index: int, last_read_timestamp: string, messaging_binding: any, role_sid: string, sid: string, url: string>"
    list-conversation-scoped-webhook: "record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, webhooks: table<account_sid: string, configuration: any, conversation_sid: string, date_created: string, date_updated: string, sid: string, target: string, url: string>>"
    create-conversation-scoped-webhook: "record<account_sid: string, configuration: any, conversation_sid: string, date_created: string, date_updated: string, sid: string, target: string, url: string>"
    fetch-conversation-scoped-webhook: "record<account_sid: string, configuration: any, conversation_sid: string, date_created: string, date_updated: string, sid: string, target: string, url: string>"
    update-conversation-scoped-webhook: "record<account_sid: string, configuration: any, conversation_sid: string, date_created: string, date_updated: string, sid: string, target: string, url: string>"
    fetch-conversation: "record<account_sid: string, attributes: string, bindings: any, chat_service_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, messaging_service_sid: string, sid: string, state: string, timers: any, unique_name: string, url: string>"
    update-conversation: "record<account_sid: string, attributes: string, bindings: any, chat_service_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, messaging_service_sid: string, sid: string, state: string, timers: any, unique_name: string, url: string>"
    list-credential: "record<credentials: table<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sandbox: string, sid: string, type: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    create-credential: "record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sandbox: string, sid: string, type: string, url: string>"
    fetch-credential: "record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sandbox: string, sid: string, type: string, url: string>"
    update-credential: "record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sandbox: string, sid: string, type: string, url: string>"
    list-participant-conversation: "record<conversations: table<account_sid: string, chat_service_sid: string, conversation_attributes: string, conversation_created_by: string, conversation_date_created: string, conversation_date_updated: string, conversation_friendly_name: string, conversation_sid: string, conversation_state: string, conversation_timers: any, conversation_unique_name: string, links: record, participant_identity: string, participant_messaging_binding: any, participant_sid: string, participant_user_sid: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    list-role: "record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, roles: table<account_sid: string, chat_service_sid: string, date_created: string, date_updated: string, friendly_name: string, permissions: list, sid: string, type: string, url: string>>"
    create-role: "record<account_sid: string, chat_service_sid: string, date_created: string, date_updated: string, friendly_name: string, permissions: list<string>, sid: string, type: string, url: string>"
    fetch-role: "record<account_sid: string, chat_service_sid: string, date_created: string, date_updated: string, friendly_name: string, permissions: list<string>, sid: string, type: string, url: string>"
    update-role: "record<account_sid: string, chat_service_sid: string, date_created: string, date_updated: string, friendly_name: string, permissions: list<string>, sid: string, type: string, url: string>"
    list-service: "record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, services: table<account_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, url: string>>"
    create-service: "record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, url: string>"
    list-service-binding: "record<bindings: table<account_sid: string, binding_type: string, chat_service_sid: string, credential_sid: string, date_created: string, date_updated: string, endpoint: string, identity: string, message_types: list, sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    fetch-service-binding: "record<account_sid: string, binding_type: string, chat_service_sid: string, credential_sid: string, date_created: string, date_updated: string, endpoint: string, identity: string, message_types: list<string>, sid: string, url: string>"
    fetch-service-configuration: "record<chat_service_sid: string, default_chat_service_role_sid: string, default_conversation_creator_role_sid: string, default_conversation_role_sid: string, links: record, reachability_enabled: bool, url: string>"
    update-service-configuration: "record<chat_service_sid: string, default_chat_service_role_sid: string, default_conversation_creator_role_sid: string, default_conversation_role_sid: string, links: record, reachability_enabled: bool, url: string>"
    fetch-service-notification: "record<account_sid: string, added_to_conversation: any, chat_service_sid: string, log_enabled: bool, new_message: any, removed_from_conversation: any, url: string>"
    update-service-notification: "record<account_sid: string, added_to_conversation: any, chat_service_sid: string, log_enabled: bool, new_message: any, removed_from_conversation: any, url: string>"
    fetch-service-webhook-configuration: "record<account_sid: string, chat_service_sid: string, filters: list<string>, method: string, post_webhook_url: string, pre_webhook_url: string, url: string>"
    update-service-webhook-configuration: "record<account_sid: string, chat_service_sid: string, filters: list<string>, method: string, post_webhook_url: string, pre_webhook_url: string, url: string>"
    list-service-conversation: "record<conversations: table<account_sid: string, attributes: string, bindings: any, chat_service_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, messaging_service_sid: string, sid: string, state: string, timers: any, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    create-service-conversation: "record<account_sid: string, attributes: string, bindings: any, chat_service_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, messaging_service_sid: string, sid: string, state: string, timers: any, unique_name: string, url: string>"
    list-service-conversation-message: "record<messages: table<account_sid: string, attributes: string, author: string, body: string, chat_service_sid: string, content_sid: string, conversation_sid: string, date_created: string, date_updated: string, delivery: any, index: int, links: record, media: list, participant_sid: string, sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    create-service-conversation-message: "record<account_sid: string, attributes: string, author: string, body: string, chat_service_sid: string, content_sid: string, conversation_sid: string, date_created: string, date_updated: string, delivery: any, index: int, links: record, media: list<any>, participant_sid: string, sid: string, url: string>"
    list-service-conversation-message-receipt: "record<delivery_receipts: table<account_sid: string, channel_message_sid: string, chat_service_sid: string, conversation_sid: string, date_created: string, date_updated: string, error_code: int, message_sid: string, participant_sid: string, sid: string, status: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    fetch-service-conversation-message-receipt: "record<account_sid: string, channel_message_sid: string, chat_service_sid: string, conversation_sid: string, date_created: string, date_updated: string, error_code: int, message_sid: string, participant_sid: string, sid: string, status: string, url: string>"
    fetch-service-conversation-message: "record<account_sid: string, attributes: string, author: string, body: string, chat_service_sid: string, content_sid: string, conversation_sid: string, date_created: string, date_updated: string, delivery: any, index: int, links: record, media: list<any>, participant_sid: string, sid: string, url: string>"
    update-service-conversation-message: "record<account_sid: string, attributes: string, author: string, body: string, chat_service_sid: string, content_sid: string, conversation_sid: string, date_created: string, date_updated: string, delivery: any, index: int, links: record, media: list<any>, participant_sid: string, sid: string, url: string>"
    list-service-conversation-participant: "record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, participants: table<account_sid: string, attributes: string, chat_service_sid: string, conversation_sid: string, date_created: string, date_updated: string, identity: string, last_read_message_index: int, last_read_timestamp: string, messaging_binding: any, role_sid: string, sid: string, url: string>>"
    create-service-conversation-participant: "record<account_sid: string, attributes: string, chat_service_sid: string, conversation_sid: string, date_created: string, date_updated: string, identity: string, last_read_message_index: int, last_read_timestamp: string, messaging_binding: any, role_sid: string, sid: string, url: string>"
    fetch-service-conversation-participant: "record<account_sid: string, attributes: string, chat_service_sid: string, conversation_sid: string, date_created: string, date_updated: string, identity: string, last_read_message_index: int, last_read_timestamp: string, messaging_binding: any, role_sid: string, sid: string, url: string>"
    update-service-conversation-participant: "record<account_sid: string, attributes: string, chat_service_sid: string, conversation_sid: string, date_created: string, date_updated: string, identity: string, last_read_message_index: int, last_read_timestamp: string, messaging_binding: any, role_sid: string, sid: string, url: string>"
    list-service-conversation-scoped-webhook: "record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, webhooks: table<account_sid: string, chat_service_sid: string, configuration: any, conversation_sid: string, date_created: string, date_updated: string, sid: string, target: string, url: string>>"
    create-service-conversation-scoped-webhook: "record<account_sid: string, chat_service_sid: string, configuration: any, conversation_sid: string, date_created: string, date_updated: string, sid: string, target: string, url: string>"
    fetch-service-conversation-scoped-webhook: "record<account_sid: string, chat_service_sid: string, configuration: any, conversation_sid: string, date_created: string, date_updated: string, sid: string, target: string, url: string>"
    update-service-conversation-scoped-webhook: "record<account_sid: string, chat_service_sid: string, configuration: any, conversation_sid: string, date_created: string, date_updated: string, sid: string, target: string, url: string>"
    fetch-service-conversation: "record<account_sid: string, attributes: string, bindings: any, chat_service_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, messaging_service_sid: string, sid: string, state: string, timers: any, unique_name: string, url: string>"
    update-service-conversation: "record<account_sid: string, attributes: string, bindings: any, chat_service_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, messaging_service_sid: string, sid: string, state: string, timers: any, unique_name: string, url: string>"
    list-service-participant-conversation: "record<conversations: table<account_sid: string, chat_service_sid: string, conversation_attributes: string, conversation_created_by: string, conversation_date_created: string, conversation_date_updated: string, conversation_friendly_name: string, conversation_sid: string, conversation_state: string, conversation_timers: any, conversation_unique_name: string, links: record, participant_identity: string, participant_messaging_binding: any, participant_sid: string, participant_user_sid: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    list-service-role: "record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, roles: table<account_sid: string, chat_service_sid: string, date_created: string, date_updated: string, friendly_name: string, permissions: list, sid: string, type: string, url: string>>"
    create-service-role: "record<account_sid: string, chat_service_sid: string, date_created: string, date_updated: string, friendly_name: string, permissions: list<string>, sid: string, type: string, url: string>"
    fetch-service-role: "record<account_sid: string, chat_service_sid: string, date_created: string, date_updated: string, friendly_name: string, permissions: list<string>, sid: string, type: string, url: string>"
    update-service-role: "record<account_sid: string, chat_service_sid: string, date_created: string, date_updated: string, friendly_name: string, permissions: list<string>, sid: string, type: string, url: string>"
    list-service-user: "record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, users: table<account_sid: string, attributes: string, chat_service_sid: string, date_created: string, date_updated: string, friendly_name: string, identity: string, is_notifiable: bool, is_online: bool, links: record, role_sid: string, sid: string, url: string>>"
    create-service-user: "record<account_sid: string, attributes: string, chat_service_sid: string, date_created: string, date_updated: string, friendly_name: string, identity: string, is_notifiable: bool, is_online: bool, links: record, role_sid: string, sid: string, url: string>"
    fetch-service-user: "record<account_sid: string, attributes: string, chat_service_sid: string, date_created: string, date_updated: string, friendly_name: string, identity: string, is_notifiable: bool, is_online: bool, links: record, role_sid: string, sid: string, url: string>"
    update-service-user: "record<account_sid: string, attributes: string, chat_service_sid: string, date_created: string, date_updated: string, friendly_name: string, identity: string, is_notifiable: bool, is_online: bool, links: record, role_sid: string, sid: string, url: string>"
    list-service-user-conversation: "record<conversations: table<account_sid: string, attributes: string, chat_service_sid: string, conversation_sid: string, conversation_state: string, created_by: string, date_created: string, date_updated: string, friendly_name: string, last_read_message_index: int, links: record, notification_level: string, participant_sid: string, timers: any, unique_name: string, unread_messages_count: int, url: string, user_sid: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    fetch-service-user-conversation: "record<account_sid: string, attributes: string, chat_service_sid: string, conversation_sid: string, conversation_state: string, created_by: string, date_created: string, date_updated: string, friendly_name: string, last_read_message_index: int, links: record, notification_level: string, participant_sid: string, timers: any, unique_name: string, unread_messages_count: int, url: string, user_sid: string>"
    update-service-user-conversation: "record<account_sid: string, attributes: string, chat_service_sid: string, conversation_sid: string, conversation_state: string, created_by: string, date_created: string, date_updated: string, friendly_name: string, last_read_message_index: int, links: record, notification_level: string, participant_sid: string, timers: any, unique_name: string, unread_messages_count: int, url: string, user_sid: string>"
    fetch-service: "record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, url: string>"
    list-user: "record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, users: table<account_sid: string, attributes: string, chat_service_sid: string, date_created: string, date_updated: string, friendly_name: string, identity: string, is_notifiable: bool, is_online: bool, links: record, role_sid: string, sid: string, url: string>>"
    create-user: "record<account_sid: string, attributes: string, chat_service_sid: string, date_created: string, date_updated: string, friendly_name: string, identity: string, is_notifiable: bool, is_online: bool, links: record, role_sid: string, sid: string, url: string>"
    fetch-user: "record<account_sid: string, attributes: string, chat_service_sid: string, date_created: string, date_updated: string, friendly_name: string, identity: string, is_notifiable: bool, is_online: bool, links: record, role_sid: string, sid: string, url: string>"
    update-user: "record<account_sid: string, attributes: string, chat_service_sid: string, date_created: string, date_updated: string, friendly_name: string, identity: string, is_notifiable: bool, is_online: bool, links: record, role_sid: string, sid: string, url: string>"
    list-user-conversation: "record<conversations: table<account_sid: string, attributes: string, chat_service_sid: string, conversation_sid: string, conversation_state: string, created_by: string, date_created: string, date_updated: string, friendly_name: string, last_read_message_index: int, links: record, notification_level: string, participant_sid: string, timers: any, unique_name: string, unread_messages_count: int, url: string, user_sid: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    fetch-user-conversation: "record<account_sid: string, attributes: string, chat_service_sid: string, conversation_sid: string, conversation_state: string, created_by: string, date_created: string, date_updated: string, friendly_name: string, last_read_message_index: int, links: record, notification_level: string, participant_sid: string, timers: any, unique_name: string, unread_messages_count: int, url: string, user_sid: string>"
    update-user-conversation: "record<account_sid: string, attributes: string, chat_service_sid: string, conversation_sid: string, conversation_state: string, created_by: string, date_created: string, date_updated: string, friendly_name: string, last_read_message_index: int, links: record, notification_level: string, participant_sid: string, timers: any, unique_name: string, unread_messages_count: int, url: string, user_sid: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["fetch-configuration" "update-configuration" "list-configuration-address" "create-configuration-address" "delete-configuration-address" "fetch-configuration-address" "update-configuration-address" "fetch-configuration-webhook" "update-configuration-webhook" "list-conversation" "create-conversation" "list-conversation-message" "create-conversation-message" "list-conversation-message-receipt" "fetch-conversation-message-receipt" "delete-conversation-message" "fetch-conversation-message" "update-conversation-message" "list-conversation-participant" "create-conversation-participant" "delete-conversation-participant" "fetch-conversation-participant" "update-conversation-participant" "list-conversation-scoped-webhook" "create-conversation-scoped-webhook" "delete-conversation-scoped-webhook" "fetch-conversation-scoped-webhook" "update-conversation-scoped-webhook" "delete-conversation" "fetch-conversation" "update-conversation" "list-credential" "create-credential" "delete-credential" "fetch-credential" "update-credential" "list-participant-conversation" "list-role" "create-role" "delete-role" "fetch-role" "update-role" "list-service" "create-service" "list-service-binding" "delete-service-binding" "fetch-service-binding" "fetch-service-configuration" "update-service-configuration" "fetch-service-notification" "update-service-notification" "fetch-service-webhook-configuration" "update-service-webhook-configuration" "list-service-conversation" "create-service-conversation" "list-service-conversation-message" "create-service-conversation-message" "list-service-conversation-message-receipt" "fetch-service-conversation-message-receipt" "delete-service-conversation-message" "fetch-service-conversation-message" "update-service-conversation-message" "list-service-conversation-participant" "create-service-conversation-participant" "delete-service-conversation-participant" "fetch-service-conversation-participant" "update-service-conversation-participant" "list-service-conversation-scoped-webhook" "create-service-conversation-scoped-webhook" "delete-service-conversation-scoped-webhook" "fetch-service-conversation-scoped-webhook" "update-service-conversation-scoped-webhook" "delete-service-conversation" "fetch-service-conversation" "update-service-conversation" "list-service-participant-conversation" "list-service-role" "create-service-role" "delete-service-role" "fetch-service-role" "update-service-role" "list-service-user" "create-service-user" "delete-service-user" "fetch-service-user" "update-service-user" "list-service-user-conversation" "delete-service-user-conversation" "fetch-service-user-conversation" "update-service-user-conversation" "delete-service" "fetch-service" "list-user" "create-user" "delete-user" "fetch-user" "update-user" "list-user-conversation" "delete-user-conversation" "fetch-user-conversation" "update-user-conversation" "commands"] | sort) } | get name | first)
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

# Fetch the global configuration of conversations on your account
#
# GET /v1/Configuration
# Returns: record<account_sid: string, default_chat_service_sid: string, default_closed_timer: string, default_inactive_timer: string, default_messaging_service_sid: string, links: record, url: string>
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/Configuration"
    accept: ["application/json"]
    ok: [200]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the global configuration of conversations on your account
#
# POST /v1/Configuration
# Returns: record<account_sid: string, default_chat_service_sid: string, default_closed_timer: string, default_inactive_timer: string, default_messaging_service_sid: string, links: record, url: string>
# operationId: UpdateConfiguration
export def "update-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --default-chat-service-sid: string # The SID of the default [Conversation Service](https://www.twilio.com/docs/conversations/api/service-resource) to use when creating a conversation.
  --default-closed-timer: string # Default ISO8601 duration when conversation will be switched to `closed` state. Minimum value for this timer is 10 minutes.
  --default-inactive-timer: string # Default ISO8601 duration when conversation will be switched to `inactive` state. Minimum value for this timer is 1 minute.
  --default-messaging-service-sid: string # The SID of the default [Messaging Service](https://www.twilio.com/docs/sms/services/api) to use when creating a conversation.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Configuration"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: DefaultChatServiceSid, var: default_chat_service_sid}, {name: DefaultClosedTimer, var: default_closed_timer}, {name: DefaultInactiveTimer, var: default_inactive_timer}, {name: DefaultMessagingServiceSid, var: default_messaging_service_sid}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    default_chat_service_sid: $default_chat_service_sid, default_closed_timer: $default_closed_timer, default_inactive_timer: $default_inactive_timer, default_messaging_service_sid: $default_messaging_service_sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of address configurations for an account
#
# GET /v1/Configuration/Addresses
# Returns: record<address_configurations: table<account_sid: string, address: string, auto_creation: any, date_created: string, date_updated: string, friendly_name: string, sid: string, type: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListConfigurationAddress
export def "list-configuration-address" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string # Filter the address configurations by its type. This value can be one of: `whatsapp`, `sms`.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/Configuration/Addresses"
    query: [{name: Type, var: type}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    type: $type, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new address configuration
#
# POST /v1/Configuration/Addresses
# Returns: record<account_sid: string, address: string, auto_creation: any, date_created: string, date_updated: string, friendly_name: string, sid: string, type: string, url: string>
# operationId: CreateConfigurationAddress
export def "create-configuration-address" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  address: string # The unique address to be configured. The address can be a whatsapp address or phone number
  --auto-creation-conversation-service-sid: string # Conversation Service for the auto-created conversation. If not set, the conversation is created in the default service.
  --auto-creation-enabled: oneof<nothing, bool> # Enable/Disable auto-creating conversations for messages to this address
  --auto-creation-studio-flow-sid: string # For type `studio`, the studio flow SID where the webhook should be sent to.
  --auto-creation-studio-retry-count: int # For type `studio`, number of times to retry the webhook request
  --auto-creation-type: string@auto-creation-type-completer
  --auto-creation-webhook-filters: list<string> # The list of events, firing webhook event for this Conversation. Values can be any of the following: `onMessageAdded`, `onMessageUpdated`, `onMessageRemoved`, `onConversationUpdated`, `onConversationStateUpdated`, `onConversationRemoved`, `onParticipantAdded`, `onParticipantUpdated`, `onParticipantRemoved`, `onDeliveryUpdated`
  --auto-creation-webhook-method: string@auto-creation-webhook-method-completer
  --auto-creation-webhook-url: string # For type `webhook`, the url for the webhook request.
  --friendly-name: string # The human-readable name of this configuration, limited to 256 characters. Optional.
  type: string@type-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Configuration/Addresses"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Address, var: address}, {name: "AutoCreation.ConversationServiceSid", var: auto_creation_conversation_service_sid}, {name: "AutoCreation.Enabled", var: auto_creation_enabled}, {name: "AutoCreation.StudioFlowSid", var: auto_creation_studio_flow_sid}, {name: "AutoCreation.StudioRetryCount", var: auto_creation_studio_retry_count}, {name: "AutoCreation.Type", var: auto_creation_type}, {name: "AutoCreation.WebhookFilters", var: auto_creation_webhook_filters}, {name: "AutoCreation.WebhookMethod", var: auto_creation_webhook_method}, {name: "AutoCreation.WebhookUrl", var: auto_creation_webhook_url}, {name: FriendlyName, var: friendly_name}, {name: Type, var: type}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    address: $address, auto_creation_conversation_service_sid: $auto_creation_conversation_service_sid, auto_creation_enabled: $auto_creation_enabled, auto_creation_studio_flow_sid: $auto_creation_studio_flow_sid, auto_creation_studio_retry_count: $auto_creation_studio_retry_count, auto_creation_type: $auto_creation_type, auto_creation_webhook_filters: $auto_creation_webhook_filters, auto_creation_webhook_method: $auto_creation_webhook_method, auto_creation_webhook_url: $auto_creation_webhook_url, friendly_name: $friendly_name, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove an existing address configuration
#
# DELETE /v1/Configuration/Addresses/{Sid}
# operationId: DeleteConfigurationAddress
export def "delete-configuration-address" [
  sid: string
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
    path: "/v1/Configuration/Addresses/{Sid}"
    path_params: [{name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch an address configuration
#
# GET /v1/Configuration/Addresses/{Sid}
# Returns: record<account_sid: string, address: string, auto_creation: any, date_created: string, date_updated: string, friendly_name: string, sid: string, type: string, url: string>
# operationId: FetchConfigurationAddress
export def "fetch-configuration-address" [
  sid: string
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
    path: "/v1/Configuration/Addresses/{Sid}"
    path_params: [{name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing address configuration
#
# POST /v1/Configuration/Addresses/{Sid}
# Returns: record<account_sid: string, address: string, auto_creation: any, date_created: string, date_updated: string, friendly_name: string, sid: string, type: string, url: string>
# operationId: UpdateConfigurationAddress
export def "update-configuration-address" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-creation-conversation-service-sid: string # Conversation Service for the auto-created conversation. If not set, the conversation is created in the default service.
  --auto-creation-enabled: oneof<nothing, bool> # Enable/Disable auto-creating conversations for messages to this address
  --auto-creation-studio-flow-sid: string # For type `studio`, the studio flow SID where the webhook should be sent to.
  --auto-creation-studio-retry-count: int # For type `studio`, number of times to retry the webhook request
  --auto-creation-type: string@auto-creation-type-completer
  --auto-creation-webhook-filters: list<string> # The list of events, firing webhook event for this Conversation. Values can be any of the following: `onMessageAdded`, `onMessageUpdated`, `onMessageRemoved`, `onConversationUpdated`, `onConversationStateUpdated`, `onConversationRemoved`, `onParticipantAdded`, `onParticipantUpdated`, `onParticipantRemoved`, `onDeliveryUpdated`
  --auto-creation-webhook-method: string@auto-creation-webhook-method-completer
  --auto-creation-webhook-url: string # For type `webhook`, the url for the webhook request.
  --friendly-name: string # The human-readable name of this configuration, limited to 256 characters. Optional.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Configuration/Addresses/{Sid}"
    path_params: [{name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: "AutoCreation.ConversationServiceSid", var: auto_creation_conversation_service_sid}, {name: "AutoCreation.Enabled", var: auto_creation_enabled}, {name: "AutoCreation.StudioFlowSid", var: auto_creation_studio_flow_sid}, {name: "AutoCreation.StudioRetryCount", var: auto_creation_studio_retry_count}, {name: "AutoCreation.Type", var: auto_creation_type}, {name: "AutoCreation.WebhookFilters", var: auto_creation_webhook_filters}, {name: "AutoCreation.WebhookMethod", var: auto_creation_webhook_method}, {name: "AutoCreation.WebhookUrl", var: auto_creation_webhook_url}, {name: FriendlyName, var: friendly_name}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    sid: $sid, auto_creation_conversation_service_sid: $auto_creation_conversation_service_sid, auto_creation_enabled: $auto_creation_enabled, auto_creation_studio_flow_sid: $auto_creation_studio_flow_sid, auto_creation_studio_retry_count: $auto_creation_studio_retry_count, auto_creation_type: $auto_creation_type, auto_creation_webhook_filters: $auto_creation_webhook_filters, auto_creation_webhook_method: $auto_creation_webhook_method, auto_creation_webhook_url: $auto_creation_webhook_url, friendly_name: $friendly_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/Configuration/Webhooks
#
# Returns: record<account_sid: string, filters: list<string>, method: string, post_webhook_url: string, pre_webhook_url: string, target: string, url: string>
# operationId: FetchConfigurationWebhook
export def "fetch-configuration-webhook" [
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
    path: "/v1/Configuration/Webhooks"
    accept: ["application/json"]
    ok: [200]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/Configuration/Webhooks
#
# Returns: record<account_sid: string, filters: list<string>, method: string, post_webhook_url: string, pre_webhook_url: string, target: string, url: string>
# operationId: UpdateConfigurationWebhook
export def "update-configuration-webhook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: list<string> # The list of webhook event triggers that are enabled for this Service: `onMessageAdded`, `onMessageUpdated`, `onMessageRemoved`, `onConversationUpdated`, `onConversationRemoved`, `onParticipantAdded`, `onParticipantUpdated`, `onParticipantRemoved`
  --method: string # The HTTP method to be used when sending a webhook request.
  --post-webhook-url: string # The absolute url the post-event webhook request should be sent to.
  --pre-webhook-url: string # The absolute url the pre-event webhook request should be sent to.
  --target: string@target-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Configuration/Webhooks"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Filters, var: filters}, {name: Method, var: method}, {name: PostWebhookUrl, var: post_webhook_url}, {name: PreWebhookUrl, var: pre_webhook_url}, {name: Target, var: target}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    filters: $filters, method: $method, post_webhook_url: $post_webhook_url, pre_webhook_url: $pre_webhook_url, target: $target
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of conversations in your account's default service
#
# GET /v1/Conversations
# Returns: record<conversations: table<account_sid: string, attributes: string, bindings: any, chat_service_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, messaging_service_sid: string, sid: string, state: string, timers: any, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListConversation
export def "list-conversation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # Start date or time in ISO8601 format for filtering list of Conversations. If a date is provided, the start time of the date is used (YYYY-MM-DDT00:00:00Z). Can be combined with other filters.
  --end-date: string # End date or time in ISO8601 format for filtering list of Conversations. If a date is provided, the end time of the date is used (YYYY-MM-DDT23:59:59Z). Can be combined with other filters.
  --state: string@state-completer # State for sorting and filtering list of Conversations. Can be `active`, `inactive` or `closed`
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/Conversations"
    query: [{name: StartDate, var: start_date}, {name: EndDate, var: end_date}, {name: State, var: state}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    start_date: $start_date, end_date: $end_date, state: $state, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new conversation in your account's default service
#
# POST /v1/Conversations
# Returns: record<account_sid: string, attributes: string, bindings: any, chat_service_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, messaging_service_sid: string, sid: string, state: string, timers: any, unique_name: string, url: string>
# operationId: CreateConversation
export def "create-conversation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-twilio-webhook-enabled: string@x-twilio-webhook-enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
  --attributes: string # An optional string metadata field you can use to store any data you wish. The string value must contain structurally valid JSON if specified. **Note** that if the attributes are not set "{}" will be returned.
  --date-created: string # The date that this resource was created. (format: date-time)
  --date-updated: string # The date that this resource was last updated. (format: date-time)
  --friendly-name: string # The human-readable name of this conversation, limited to 256 characters. Optional.
  --messaging-service-sid: string # The unique ID of the [Messaging Service](https://www.twilio.com/docs/sms/services/api) this conversation belongs to.
  --state: string@state-completer
  --timers-closed: string # ISO8601 duration when conversation will be switched to `closed` state. Minimum value for this timer is 10 minutes.
  --timers-inactive: string # ISO8601 duration when conversation will be switched to `inactive` state. Minimum value for this timer is 1 minute.
  --unique-name: string # An application-defined string that uniquely identifies the resource. It can be used to address the resource in place of the resource's `sid` in the URL.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Conversations"
    header: [{name: X-Twilio-Webhook-Enabled, var: x_twilio_webhook_enabled}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Attributes, var: attributes}, {name: DateCreated, var: date_created}, {name: DateUpdated, var: date_updated}, {name: FriendlyName, var: friendly_name}, {name: MessagingServiceSid, var: messaging_service_sid}, {name: State, var: state}, {name: "Timers.Closed", var: timers_closed}, {name: "Timers.Inactive", var: timers_inactive}, {name: UniqueName, var: unique_name}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    x_twilio_webhook_enabled: $x_twilio_webhook_enabled, attributes: $attributes, date_created: $date_created, date_updated: $date_updated, friendly_name: $friendly_name, messaging_service_sid: $messaging_service_sid, state: $state, timers_closed: $timers_closed, timers_inactive: $timers_inactive, unique_name: $unique_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of all messages in the conversation
#
# GET /v1/Conversations/{ConversationSid}/Messages
# Returns: record<messages: table<account_sid: string, attributes: string, author: string, body: string, content_sid: string, conversation_sid: string, date_created: string, date_updated: string, delivery: any, index: int, links: record, media: list, participant_sid: string, sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListConversationMessage
export def "list-conversation-message" [
  conversation_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --order: string@order-completer # The sort order of the returned messages. Can be: `asc` (ascending) or `desc` (descending), with `asc` as the default.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/Conversations/{ConversationSid}/Messages"
    path_params: [{name: ConversationSid, var: conversation_sid}]
    query: [{name: Order, var: order}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    conversation_sid: $conversation_sid, order: $order, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a new message to the conversation
#
# POST /v1/Conversations/{ConversationSid}/Messages
# Returns: record<account_sid: string, attributes: string, author: string, body: string, content_sid: string, conversation_sid: string, date_created: string, date_updated: string, delivery: any, index: int, links: record, media: list<any>, participant_sid: string, sid: string, url: string>
# operationId: CreateConversationMessage
export def "create-conversation-message" [
  conversation_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-twilio-webhook-enabled: string@x-twilio-webhook-enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
  --attributes: string # A string metadata field you can use to store any data you wish. The string value must contain structurally valid JSON if specified. **Note** that if the attributes are not set "{}" will be returned.
  --author: string # The channel specific identifier of the message's author. Defaults to `system`.
  --body: string # The content of the message, can be up to 1,600 characters long.
  --content-sid: string # The unique ID of the multi-channel [Rich Content](https://www.twilio.com/docs/content-api) template, required for template-generated messages. **Note** that if this field is set, `Body` and `MediaSid` parameters are ignored.
  --content-variables: string # A structurally valid JSON string that contains values to resolve Rich Content template variables.
  --date-created: string # The date that this resource was created. (format: date-time)
  --date-updated: string # The date that this resource was last updated. `null` if the message has not been edited. (format: date-time)
  --media-sid: string # The Media SID to be attached to the new Message.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Conversations/{ConversationSid}/Messages"
    path_params: [{name: ConversationSid, var: conversation_sid}]
    header: [{name: X-Twilio-Webhook-Enabled, var: x_twilio_webhook_enabled}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Attributes, var: attributes}, {name: Author, var: author}, {name: Body, var: body}, {name: ContentSid, var: content_sid}, {name: ContentVariables, var: content_variables}, {name: DateCreated, var: date_created}, {name: DateUpdated, var: date_updated}, {name: MediaSid, var: media_sid}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    conversation_sid: $conversation_sid, x_twilio_webhook_enabled: $x_twilio_webhook_enabled, attributes: $attributes, author: $author, body: $body, content_sid: $content_sid, content_variables: $content_variables, date_created: $date_created, date_updated: $date_updated, media_sid: $media_sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of all delivery and read receipts of the conversation message
#
# GET /v1/Conversations/{ConversationSid}/Messages/{MessageSid}/Receipts
# Returns: record<delivery_receipts: table<account_sid: string, channel_message_sid: string, conversation_sid: string, date_created: string, date_updated: string, error_code: int, message_sid: string, participant_sid: string, sid: string, status: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListConversationMessageReceipt
export def "list-conversation-message-receipt" [
  conversation_sid: string
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
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/Conversations/{ConversationSid}/Messages/{MessageSid}/Receipts"
    path_params: [{name: ConversationSid, var: conversation_sid}, {name: MessageSid, var: message_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    conversation_sid: $conversation_sid, message_sid: $message_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch the delivery and read receipts of the conversation message
#
# GET /v1/Conversations/{ConversationSid}/Messages/{MessageSid}/Receipts/{Sid}
# Returns: record<account_sid: string, channel_message_sid: string, conversation_sid: string, date_created: string, date_updated: string, error_code: int, message_sid: string, participant_sid: string, sid: string, status: string, url: string>
# operationId: FetchConversationMessageReceipt
export def "fetch-conversation-message-receipt" [
  conversation_sid: string
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
    path: "/v1/Conversations/{ConversationSid}/Messages/{MessageSid}/Receipts/{Sid}"
    path_params: [{name: ConversationSid, var: conversation_sid}, {name: MessageSid, var: message_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    conversation_sid: $conversation_sid, message_sid: $message_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a message from the conversation
#
# DELETE /v1/Conversations/{ConversationSid}/Messages/{Sid}
# operationId: DeleteConversationMessage
export def "delete-conversation-message" [
  conversation_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-twilio-webhook-enabled: string@x-twilio-webhook-enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
]: nothing -> any {
  http-request {
    method: delete
    path: "/v1/Conversations/{ConversationSid}/Messages/{Sid}"
    path_params: [{name: ConversationSid, var: conversation_sid}, {name: Sid, var: sid}]
    header: [{name: X-Twilio-Webhook-Enabled, var: x_twilio_webhook_enabled}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    conversation_sid: $conversation_sid, sid: $sid, x_twilio_webhook_enabled: $x_twilio_webhook_enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a message from the conversation
#
# GET /v1/Conversations/{ConversationSid}/Messages/{Sid}
# Returns: record<account_sid: string, attributes: string, author: string, body: string, content_sid: string, conversation_sid: string, date_created: string, date_updated: string, delivery: any, index: int, links: record, media: list<any>, participant_sid: string, sid: string, url: string>
# operationId: FetchConversationMessage
export def "fetch-conversation-message" [
  conversation_sid: string
  sid: string
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
    path: "/v1/Conversations/{ConversationSid}/Messages/{Sid}"
    path_params: [{name: ConversationSid, var: conversation_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    conversation_sid: $conversation_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing message in the conversation
#
# POST /v1/Conversations/{ConversationSid}/Messages/{Sid}
# Returns: record<account_sid: string, attributes: string, author: string, body: string, content_sid: string, conversation_sid: string, date_created: string, date_updated: string, delivery: any, index: int, links: record, media: list<any>, participant_sid: string, sid: string, url: string>
# operationId: UpdateConversationMessage
export def "update-conversation-message" [
  conversation_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-twilio-webhook-enabled: string@x-twilio-webhook-enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
  --attributes: string # A string metadata field you can use to store any data you wish. The string value must contain structurally valid JSON if specified. **Note** that if the attributes are not set "{}" will be returned.
  --author: string # The channel specific identifier of the message's author. Defaults to `system`.
  --body: string # The content of the message, can be up to 1,600 characters long.
  --date-created: string # The date that this resource was created. (format: date-time)
  --date-updated: string # The date that this resource was last updated. `null` if the message has not been edited. (format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Conversations/{ConversationSid}/Messages/{Sid}"
    path_params: [{name: ConversationSid, var: conversation_sid}, {name: Sid, var: sid}]
    header: [{name: X-Twilio-Webhook-Enabled, var: x_twilio_webhook_enabled}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Attributes, var: attributes}, {name: Author, var: author}, {name: Body, var: body}, {name: DateCreated, var: date_created}, {name: DateUpdated, var: date_updated}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    conversation_sid: $conversation_sid, sid: $sid, x_twilio_webhook_enabled: $x_twilio_webhook_enabled, attributes: $attributes, author: $author, body: $body, date_created: $date_created, date_updated: $date_updated
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of all participants of the conversation
#
# GET /v1/Conversations/{ConversationSid}/Participants
# Returns: record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, participants: table<account_sid: string, attributes: string, conversation_sid: string, date_created: string, date_updated: string, identity: string, last_read_message_index: int, last_read_timestamp: string, messaging_binding: any, role_sid: string, sid: string, url: string>>
# operationId: ListConversationParticipant
export def "list-conversation-participant" [
  conversation_sid: string
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
    path: "/v1/Conversations/{ConversationSid}/Participants"
    path_params: [{name: ConversationSid, var: conversation_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    conversation_sid: $conversation_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a new participant to the conversation
#
# POST /v1/Conversations/{ConversationSid}/Participants
# Returns: record<account_sid: string, attributes: string, conversation_sid: string, date_created: string, date_updated: string, identity: string, last_read_message_index: int, last_read_timestamp: string, messaging_binding: any, role_sid: string, sid: string, url: string>
# operationId: CreateConversationParticipant
export def "create-conversation-participant" [
  conversation_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-twilio-webhook-enabled: string@x-twilio-webhook-enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
  --attributes: string # An optional string metadata field you can use to store any data you wish. The string value must contain structurally valid JSON if specified. **Note** that if the attributes are not set "{}" will be returned.
  --date-created: string # The date that this resource was created. (format: date-time)
  --date-updated: string # The date that this resource was last updated. (format: date-time)
  --identity: string # A unique string identifier for the conversation participant as [Conversation User](https://www.twilio.com/docs/conversations/api/user-resource). This parameter is non-null if (and only if) the participant is using the Conversations SDK to communicate. Limited to 256 characters.
  --messaging-binding-address: string # The address of the participant's device, e.g. a phone or WhatsApp number. Together with the Proxy address, this determines a participant uniquely. This field (with proxy_address) is only null when the participant is interacting from an SDK endpoint (see the 'identity' field).
  --messaging-binding-projected-address: string # The address of the Twilio phone number that is used in Group MMS. Communication mask for the Conversation participant with Identity.
  --messaging-binding-proxy-address: string # The address of the Twilio phone number (or WhatsApp number) that the participant is in contact with. This field, together with participant address, is only null when the participant is interacting from an SDK endpoint (see the 'identity' field).
  --role-sid: string # The SID of a conversation-level [Role](https://www.twilio.com/docs/conversations/api/role-resource) to assign to the participant.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Conversations/{ConversationSid}/Participants"
    path_params: [{name: ConversationSid, var: conversation_sid}]
    header: [{name: X-Twilio-Webhook-Enabled, var: x_twilio_webhook_enabled}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Attributes, var: attributes}, {name: DateCreated, var: date_created}, {name: DateUpdated, var: date_updated}, {name: Identity, var: identity}, {name: "MessagingBinding.Address", var: messaging_binding_address}, {name: "MessagingBinding.ProjectedAddress", var: messaging_binding_projected_address}, {name: "MessagingBinding.ProxyAddress", var: messaging_binding_proxy_address}, {name: RoleSid, var: role_sid}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    conversation_sid: $conversation_sid, x_twilio_webhook_enabled: $x_twilio_webhook_enabled, attributes: $attributes, date_created: $date_created, date_updated: $date_updated, identity: $identity, messaging_binding_address: $messaging_binding_address, messaging_binding_projected_address: $messaging_binding_projected_address, messaging_binding_proxy_address: $messaging_binding_proxy_address, role_sid: $role_sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a participant from the conversation
#
# DELETE /v1/Conversations/{ConversationSid}/Participants/{Sid}
# operationId: DeleteConversationParticipant
export def "delete-conversation-participant" [
  conversation_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-twilio-webhook-enabled: string@x-twilio-webhook-enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
]: nothing -> any {
  http-request {
    method: delete
    path: "/v1/Conversations/{ConversationSid}/Participants/{Sid}"
    path_params: [{name: ConversationSid, var: conversation_sid}, {name: Sid, var: sid}]
    header: [{name: X-Twilio-Webhook-Enabled, var: x_twilio_webhook_enabled}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    conversation_sid: $conversation_sid, sid: $sid, x_twilio_webhook_enabled: $x_twilio_webhook_enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a participant of the conversation
#
# GET /v1/Conversations/{ConversationSid}/Participants/{Sid}
# Returns: record<account_sid: string, attributes: string, conversation_sid: string, date_created: string, date_updated: string, identity: string, last_read_message_index: int, last_read_timestamp: string, messaging_binding: any, role_sid: string, sid: string, url: string>
# operationId: FetchConversationParticipant
export def "fetch-conversation-participant" [
  conversation_sid: string
  sid: string
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
    path: "/v1/Conversations/{ConversationSid}/Participants/{Sid}"
    path_params: [{name: ConversationSid, var: conversation_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    conversation_sid: $conversation_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing participant in the conversation
#
# POST /v1/Conversations/{ConversationSid}/Participants/{Sid}
# Returns: record<account_sid: string, attributes: string, conversation_sid: string, date_created: string, date_updated: string, identity: string, last_read_message_index: int, last_read_timestamp: string, messaging_binding: any, role_sid: string, sid: string, url: string>
# operationId: UpdateConversationParticipant
export def "update-conversation-participant" [
  conversation_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-twilio-webhook-enabled: string@x-twilio-webhook-enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
  --attributes: string # An optional string metadata field you can use to store any data you wish. The string value must contain structurally valid JSON if specified. **Note** that if the attributes are not set "{}" will be returned.
  --date-created: string # The date that this resource was created. (format: date-time)
  --date-updated: string # The date that this resource was last updated. (format: date-time)
  --identity: string # A unique string identifier for the conversation participant as [Conversation User](https://www.twilio.com/docs/conversations/api/user-resource). This parameter is non-null if (and only if) the participant is using the Conversations SDK to communicate. Limited to 256 characters.
  --last-read-message-index: int # Index of last “read” message in the [Conversation](https://www.twilio.com/docs/conversations/api/conversation-resource) for the Participant. (nullable)
  --last-read-timestamp: string # Timestamp of last “read” message in the [Conversation](https://www.twilio.com/docs/conversations/api/conversation-resource) for the Participant.
  --messaging-binding-projected-address: string # The address of the Twilio phone number that is used in Group MMS. 'null' value will remove it.
  --messaging-binding-proxy-address: string # The address of the Twilio phone number that the participant is in contact with. 'null' value will remove it.
  --role-sid: string # The SID of a conversation-level [Role](https://www.twilio.com/docs/conversations/api/role-resource) to assign to the participant.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Conversations/{ConversationSid}/Participants/{Sid}"
    path_params: [{name: ConversationSid, var: conversation_sid}, {name: Sid, var: sid}]
    header: [{name: X-Twilio-Webhook-Enabled, var: x_twilio_webhook_enabled}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Attributes, var: attributes}, {name: DateCreated, var: date_created}, {name: DateUpdated, var: date_updated}, {name: Identity, var: identity}, {name: LastReadMessageIndex, var: last_read_message_index}, {name: LastReadTimestamp, var: last_read_timestamp}, {name: "MessagingBinding.ProjectedAddress", var: messaging_binding_projected_address}, {name: "MessagingBinding.ProxyAddress", var: messaging_binding_proxy_address}, {name: RoleSid, var: role_sid}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    conversation_sid: $conversation_sid, sid: $sid, x_twilio_webhook_enabled: $x_twilio_webhook_enabled, attributes: $attributes, date_created: $date_created, date_updated: $date_updated, identity: $identity, last_read_message_index: $last_read_message_index, last_read_timestamp: $last_read_timestamp, messaging_binding_projected_address: $messaging_binding_projected_address, messaging_binding_proxy_address: $messaging_binding_proxy_address, role_sid: $role_sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of all webhooks scoped to the conversation
#
# GET /v1/Conversations/{ConversationSid}/Webhooks
# Returns: record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, webhooks: table<account_sid: string, configuration: any, conversation_sid: string, date_created: string, date_updated: string, sid: string, target: string, url: string>>
# operationId: ListConversationScopedWebhook
export def "list-conversation-scoped-webhook" [
  conversation_sid: string
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
    path: "/v1/Conversations/{ConversationSid}/Webhooks"
    path_params: [{name: ConversationSid, var: conversation_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    conversation_sid: $conversation_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new webhook scoped to the conversation
#
# POST /v1/Conversations/{ConversationSid}/Webhooks
# Returns: record<account_sid: string, configuration: any, conversation_sid: string, date_created: string, date_updated: string, sid: string, target: string, url: string>
# operationId: CreateConversationScopedWebhook
export def "create-conversation-scoped-webhook" [
  conversation_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --configuration-filters: list<string> # The list of events, firing webhook event for this Conversation.
  --configuration-flow-sid: string # The studio flow SID, where the webhook should be sent to.
  --configuration-method: string@configuration-method-completer
  --configuration-replay-after: int # The message index for which and it's successors the webhook will be replayed. Not set by default
  --configuration-triggers: list<string> # The list of keywords, firing webhook event for this Conversation.
  --configuration-url: string # The absolute url the webhook request should be sent to.
  target: string@target-completer-1
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Conversations/{ConversationSid}/Webhooks"
    path_params: [{name: ConversationSid, var: conversation_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: "Configuration.Filters", var: configuration_filters}, {name: "Configuration.FlowSid", var: configuration_flow_sid}, {name: "Configuration.Method", var: configuration_method}, {name: "Configuration.ReplayAfter", var: configuration_replay_after}, {name: "Configuration.Triggers", var: configuration_triggers}, {name: "Configuration.Url", var: configuration_url}, {name: Target, var: target}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    conversation_sid: $conversation_sid, configuration_filters: $configuration_filters, configuration_flow_sid: $configuration_flow_sid, configuration_method: $configuration_method, configuration_replay_after: $configuration_replay_after, configuration_triggers: $configuration_triggers, configuration_url: $configuration_url, target: $target
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove an existing webhook scoped to the conversation
#
# DELETE /v1/Conversations/{ConversationSid}/Webhooks/{Sid}
# operationId: DeleteConversationScopedWebhook
export def "delete-conversation-scoped-webhook" [
  conversation_sid: string
  sid: string
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
    path: "/v1/Conversations/{ConversationSid}/Webhooks/{Sid}"
    path_params: [{name: ConversationSid, var: conversation_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    conversation_sid: $conversation_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch the configuration of a conversation-scoped webhook
#
# GET /v1/Conversations/{ConversationSid}/Webhooks/{Sid}
# Returns: record<account_sid: string, configuration: any, conversation_sid: string, date_created: string, date_updated: string, sid: string, target: string, url: string>
# operationId: FetchConversationScopedWebhook
export def "fetch-conversation-scoped-webhook" [
  conversation_sid: string
  sid: string
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
    path: "/v1/Conversations/{ConversationSid}/Webhooks/{Sid}"
    path_params: [{name: ConversationSid, var: conversation_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    conversation_sid: $conversation_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing conversation-scoped webhook
#
# POST /v1/Conversations/{ConversationSid}/Webhooks/{Sid}
# Returns: record<account_sid: string, configuration: any, conversation_sid: string, date_created: string, date_updated: string, sid: string, target: string, url: string>
# operationId: UpdateConversationScopedWebhook
export def "update-conversation-scoped-webhook" [
  conversation_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --configuration-filters: list<string> # The list of events, firing webhook event for this Conversation.
  --configuration-flow-sid: string # The studio flow SID, where the webhook should be sent to.
  --configuration-method: string@configuration-method-completer
  --configuration-triggers: list<string> # The list of keywords, firing webhook event for this Conversation.
  --configuration-url: string # The absolute url the webhook request should be sent to.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Conversations/{ConversationSid}/Webhooks/{Sid}"
    path_params: [{name: ConversationSid, var: conversation_sid}, {name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: "Configuration.Filters", var: configuration_filters}, {name: "Configuration.FlowSid", var: configuration_flow_sid}, {name: "Configuration.Method", var: configuration_method}, {name: "Configuration.Triggers", var: configuration_triggers}, {name: "Configuration.Url", var: configuration_url}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    conversation_sid: $conversation_sid, sid: $sid, configuration_filters: $configuration_filters, configuration_flow_sid: $configuration_flow_sid, configuration_method: $configuration_method, configuration_triggers: $configuration_triggers, configuration_url: $configuration_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a conversation from your account's default service
#
# DELETE /v1/Conversations/{Sid}
# operationId: DeleteConversation
export def "delete-conversation" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-twilio-webhook-enabled: string@x-twilio-webhook-enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
]: nothing -> any {
  http-request {
    method: delete
    path: "/v1/Conversations/{Sid}"
    path_params: [{name: Sid, var: sid}]
    header: [{name: X-Twilio-Webhook-Enabled, var: x_twilio_webhook_enabled}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    sid: $sid, x_twilio_webhook_enabled: $x_twilio_webhook_enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a conversation from your account's default service
#
# GET /v1/Conversations/{Sid}
# Returns: record<account_sid: string, attributes: string, bindings: any, chat_service_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, messaging_service_sid: string, sid: string, state: string, timers: any, unique_name: string, url: string>
# operationId: FetchConversation
export def "fetch-conversation" [
  sid: string
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
    path: "/v1/Conversations/{Sid}"
    path_params: [{name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing conversation in your account's default service
#
# POST /v1/Conversations/{Sid}
# Returns: record<account_sid: string, attributes: string, bindings: any, chat_service_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, messaging_service_sid: string, sid: string, state: string, timers: any, unique_name: string, url: string>
# operationId: UpdateConversation
export def "update-conversation" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-twilio-webhook-enabled: string@x-twilio-webhook-enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
  --attributes: string # An optional string metadata field you can use to store any data you wish. The string value must contain structurally valid JSON if specified. **Note** that if the attributes are not set "{}" will be returned.
  --date-created: string # The date that this resource was created. (format: date-time)
  --date-updated: string # The date that this resource was last updated. (format: date-time)
  --friendly-name: string # The human-readable name of this conversation, limited to 256 characters. Optional.
  --messaging-service-sid: string # The unique ID of the [Messaging Service](https://www.twilio.com/docs/sms/services/api) this conversation belongs to.
  --state: string@state-completer
  --timers-closed: string # ISO8601 duration when conversation will be switched to `closed` state. Minimum value for this timer is 10 minutes.
  --timers-inactive: string # ISO8601 duration when conversation will be switched to `inactive` state. Minimum value for this timer is 1 minute.
  --unique-name: string # An application-defined string that uniquely identifies the resource. It can be used to address the resource in place of the resource's `sid` in the URL.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Conversations/{Sid}"
    path_params: [{name: Sid, var: sid}]
    header: [{name: X-Twilio-Webhook-Enabled, var: x_twilio_webhook_enabled}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Attributes, var: attributes}, {name: DateCreated, var: date_created}, {name: DateUpdated, var: date_updated}, {name: FriendlyName, var: friendly_name}, {name: MessagingServiceSid, var: messaging_service_sid}, {name: State, var: state}, {name: "Timers.Closed", var: timers_closed}, {name: "Timers.Inactive", var: timers_inactive}, {name: UniqueName, var: unique_name}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    sid: $sid, x_twilio_webhook_enabled: $x_twilio_webhook_enabled, attributes: $attributes, date_created: $date_created, date_updated: $date_updated, friendly_name: $friendly_name, messaging_service_sid: $messaging_service_sid, state: $state, timers_closed: $timers_closed, timers_inactive: $timers_inactive, unique_name: $unique_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of all push notification credentials on your account
#
# GET /v1/Credentials
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
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a new push notification credential to your account
#
# POST /v1/Credentials
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
  --certificate: string # [APN only] The URL encoded representation of the certificate. For example, `-----BEGIN CERTIFICATE----- MIIFnTCCBIWgAwIBAgIIAjy9H849+E8wDQYJKoZIhvcNAQEF.....A== -----END CERTIFICATE-----`.
  --friendly-name: string # A descriptive string that you create to describe the new resource. It can be up to 64 characters long.
  --private-key: string # [APN only] The URL encoded representation of the private key. For example, `-----BEGIN RSA PRIVATE KEY----- MIIEpQIBAAKCAQEAuyf/lNrH9ck8DmNyo3fG... -----END RSA PRIVATE KEY-----`.
  --sandbox: oneof<nothing, bool> # [APN only] Whether to send the credential to sandbox APNs. Can be `true` to send to sandbox APNs or `false` to send to production.
  --secret: string # [FCM only] The **Server key** of your project from the Firebase console, found under Settings / Cloud messaging.
  type: string@type-completer-1
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Credentials"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: ApiKey, var: api_key}, {name: Certificate, var: certificate}, {name: FriendlyName, var: friendly_name}, {name: PrivateKey, var: private_key}, {name: Sandbox, var: sandbox}, {name: Secret, var: secret}, {name: Type, var: type}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    api_key: $api_key, certificate: $certificate, friendly_name: $friendly_name, private_key: $private_key, sandbox: $sandbox, secret: $secret, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a push notification credential from your account
#
# DELETE /v1/Credentials/{Sid}
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
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a push notification credential from your account
#
# GET /v1/Credentials/{Sid}
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
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing push notification credential on your account
#
# POST /v1/Credentials/{Sid}
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
  --certificate: string # [APN only] The URL encoded representation of the certificate. For example, `-----BEGIN CERTIFICATE----- MIIFnTCCBIWgAwIBAgIIAjy9H849+E8wDQYJKoZIhvcNAQEF.....A== -----END CERTIFICATE-----`.
  --friendly-name: string # A descriptive string that you create to describe the new resource. It can be up to 64 characters long.
  --private-key: string # [APN only] The URL encoded representation of the private key. For example, `-----BEGIN RSA PRIVATE KEY----- MIIEpQIBAAKCAQEAuyf/lNrH9ck8DmNyo3fG... -----END RSA PRIVATE KEY-----`.
  --sandbox: oneof<nothing, bool> # [APN only] Whether to send the credential to sandbox APNs. Can be `true` to send to sandbox APNs or `false` to send to production.
  --secret: string # [FCM only] The **Server key** of your project from the Firebase console, found under Settings / Cloud messaging.
  --type: string@type-completer-1
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Credentials/{Sid}"
    path_params: [{name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: ApiKey, var: api_key}, {name: Certificate, var: certificate}, {name: FriendlyName, var: friendly_name}, {name: PrivateKey, var: private_key}, {name: Sandbox, var: sandbox}, {name: Secret, var: secret}, {name: Type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    sid: $sid, api_key: $api_key, certificate: $certificate, friendly_name: $friendly_name, private_key: $private_key, sandbox: $sandbox, secret: $secret, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of all Conversations that this Participant belongs to by identity or by address. Only one parameter should be specified.
#
# GET /v1/ParticipantConversations
# Returns: record<conversations: table<account_sid: string, chat_service_sid: string, conversation_attributes: string, conversation_created_by: string, conversation_date_created: string, conversation_date_updated: string, conversation_friendly_name: string, conversation_sid: string, conversation_state: string, conversation_timers: any, conversation_unique_name: string, links: record, participant_identity: string, participant_messaging_binding: any, participant_sid: string, participant_user_sid: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListParticipantConversation
export def "list-participant-conversation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --identity: string # A unique string identifier for the conversation participant as [Conversation User](https://www.twilio.com/docs/conversations/api/user-resource). This parameter is non-null if (and only if) the participant is using the Conversations SDK to communicate. Limited to 256 characters.
  --address: string # A unique string identifier for the conversation participant who's not a Conversation User. This parameter could be found in messaging_binding.address field of Participant resource. It should be url-encoded.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/ParticipantConversations"
    query: [{name: Identity, var: identity}, {name: Address, var: address}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    identity: $identity, address: $address, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of all user roles in your account's default service
#
# GET /v1/Roles
# Returns: record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, roles: table<account_sid: string, chat_service_sid: string, date_created: string, date_updated: string, friendly_name: string, permissions: list, sid: string, type: string, url: string>>
# operationId: ListRole
export def "list-role" [
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
    path: "/v1/Roles"
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new user role in your account's default service
#
# POST /v1/Roles
# Returns: record<account_sid: string, chat_service_sid: string, date_created: string, date_updated: string, friendly_name: string, permissions: list<string>, sid: string, type: string, url: string>
# operationId: CreateRole
export def "create-role" [
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
  permission: list<string> # A permission that you grant to the new role. Only one permission can be granted per parameter. To assign more than one permission, repeat this parameter for each permission value. The values for this parameter depend on the role's `type`.
  type: string@type-completer-2
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Roles"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: FriendlyName, var: friendly_name}, {name: Permission, var: permission}, {name: Type, var: type}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    friendly_name: $friendly_name, permission: $permission, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a user role from your account's default service
#
# DELETE /v1/Roles/{Sid}
# operationId: DeleteRole
export def "delete-role" [
  sid: string
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
    path: "/v1/Roles/{Sid}"
    path_params: [{name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a user role from your account's default service
#
# GET /v1/Roles/{Sid}
# Returns: record<account_sid: string, chat_service_sid: string, date_created: string, date_updated: string, friendly_name: string, permissions: list<string>, sid: string, type: string, url: string>
# operationId: FetchRole
export def "fetch-role" [
  sid: string
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
    path: "/v1/Roles/{Sid}"
    path_params: [{name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing user role in your account's default service
#
# POST /v1/Roles/{Sid}
# Returns: record<account_sid: string, chat_service_sid: string, date_created: string, date_updated: string, friendly_name: string, permissions: list<string>, sid: string, type: string, url: string>
# operationId: UpdateRole
export def "update-role" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  permission: list<string> # A permission that you grant to the role. Only one permission can be granted per parameter. To assign more than one permission, repeat this parameter for each permission value. Note that the update action replaces all previously assigned permissions with those defined in the update action. To remove a permission, do not include it in the subsequent update action. The values for this parameter depend on the role's `type`.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Roles/{Sid}"
    path_params: [{name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Permission, var: permission}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    sid: $sid, permission: $permission
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of all conversation services on your account
#
# GET /v1/Services
# Returns: record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, services: table<account_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, url: string>>
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
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new conversation service on your account
#
# POST /v1/Services
# Returns: record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, url: string>
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
  friendly_name: string # The human-readable name of this service, limited to 256 characters. Optional.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Services"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: FriendlyName, var: friendly_name}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    friendly_name: $friendly_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of all push notification bindings in the conversation service
#
# GET /v1/Services/{ChatServiceSid}/Bindings
# Returns: record<bindings: table<account_sid: string, binding_type: string, chat_service_sid: string, credential_sid: string, date_created: string, date_updated: string, endpoint: string, identity: string, message_types: list, sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListServiceBinding
export def "list-service-binding" [
  chat_service_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --binding-type: list<string> # The push technology used by the Binding resources to read. Can be: `apn`, `gcm`, or `fcm`. See [push notification configuration](https://www.twilio.com/docs/chat/push-notification-configuration) for more info.
  --identity: list<string> # The identity of a [Conversation User](https://www.twilio.com/docs/conversations/api/user-resource) this binding belongs to. See [access tokens](https://www.twilio.com/docs/conversations/create-tokens) for more details.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/Services/{ChatServiceSid}/Bindings"
    path_params: [{name: ChatServiceSid, var: chat_service_sid}]
    query: [{name: BindingType, var: binding_type, style: multi}, {name: Identity, var: identity, style: multi}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    chat_service_sid: $chat_service_sid, binding_type: $binding_type, identity: $identity, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a push notification binding from the conversation service
#
# DELETE /v1/Services/{ChatServiceSid}/Bindings/{Sid}
# operationId: DeleteServiceBinding
export def "delete-service-binding" [
  chat_service_sid: string
  sid: string
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
    path: "/v1/Services/{ChatServiceSid}/Bindings/{Sid}"
    path_params: [{name: ChatServiceSid, var: chat_service_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    chat_service_sid: $chat_service_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a push notification binding from the conversation service
#
# GET /v1/Services/{ChatServiceSid}/Bindings/{Sid}
# Returns: record<account_sid: string, binding_type: string, chat_service_sid: string, credential_sid: string, date_created: string, date_updated: string, endpoint: string, identity: string, message_types: list<string>, sid: string, url: string>
# operationId: FetchServiceBinding
export def "fetch-service-binding" [
  chat_service_sid: string
  sid: string
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
    path: "/v1/Services/{ChatServiceSid}/Bindings/{Sid}"
    path_params: [{name: ChatServiceSid, var: chat_service_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    chat_service_sid: $chat_service_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch the configuration of a conversation service
#
# GET /v1/Services/{ChatServiceSid}/Configuration
# Returns: record<chat_service_sid: string, default_chat_service_role_sid: string, default_conversation_creator_role_sid: string, default_conversation_role_sid: string, links: record, reachability_enabled: bool, url: string>
# operationId: FetchServiceConfiguration
export def "fetch-service-configuration" [
  chat_service_sid: string
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
    path: "/v1/Services/{ChatServiceSid}/Configuration"
    path_params: [{name: ChatServiceSid, var: chat_service_sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    chat_service_sid: $chat_service_sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update configuration settings of a conversation service
#
# POST /v1/Services/{ChatServiceSid}/Configuration
# Returns: record<chat_service_sid: string, default_chat_service_role_sid: string, default_conversation_creator_role_sid: string, default_conversation_role_sid: string, links: record, reachability_enabled: bool, url: string>
# operationId: UpdateServiceConfiguration
export def "update-service-configuration" [
  chat_service_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --default-chat-service-role-sid: string # The service-level role assigned to users when they are added to the service. See the [Conversation Role](https://www.twilio.com/docs/conversations/api/role-resource) for more info about roles.
  --default-conversation-creator-role-sid: string # The conversation-level role assigned to a conversation creator when they join a new conversation. See the [Conversation Role](https://www.twilio.com/docs/conversations/api/role-resource) for more info about roles.
  --default-conversation-role-sid: string # The conversation-level role assigned to users when they are added to a conversation. See the [Conversation Role](https://www.twilio.com/docs/conversations/api/role-resource) for more info about roles.
  --reachability-enabled: oneof<nothing, bool> # Whether the [Reachability Indicator](https://www.twilio.com/docs/chat/reachability-indicator) is enabled for this Conversations Service. The default is `false`.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Services/{ChatServiceSid}/Configuration"
    path_params: [{name: ChatServiceSid, var: chat_service_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: DefaultChatServiceRoleSid, var: default_chat_service_role_sid}, {name: DefaultConversationCreatorRoleSid, var: default_conversation_creator_role_sid}, {name: DefaultConversationRoleSid, var: default_conversation_role_sid}, {name: ReachabilityEnabled, var: reachability_enabled}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    chat_service_sid: $chat_service_sid, default_chat_service_role_sid: $default_chat_service_role_sid, default_conversation_creator_role_sid: $default_conversation_creator_role_sid, default_conversation_role_sid: $default_conversation_role_sid, reachability_enabled: $reachability_enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch push notification service settings
#
# GET /v1/Services/{ChatServiceSid}/Configuration/Notifications
# Returns: record<account_sid: string, added_to_conversation: any, chat_service_sid: string, log_enabled: bool, new_message: any, removed_from_conversation: any, url: string>
# operationId: FetchServiceNotification
export def "fetch-service-notification" [
  chat_service_sid: string
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
    path: "/v1/Services/{ChatServiceSid}/Configuration/Notifications"
    path_params: [{name: ChatServiceSid, var: chat_service_sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    chat_service_sid: $chat_service_sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update push notification service settings
#
# POST /v1/Services/{ChatServiceSid}/Configuration/Notifications
# Returns: record<account_sid: string, added_to_conversation: any, chat_service_sid: string, log_enabled: bool, new_message: any, removed_from_conversation: any, url: string>
# operationId: UpdateServiceNotification
export def "update-service-notification" [
  chat_service_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --added-to-conversation-enabled: oneof<nothing, bool> # Whether to send a notification when a participant is added to a conversation. The default is `false`.
  --added-to-conversation-sound: string # The name of the sound to play when a participant is added to a conversation and `added_to_conversation.enabled` is `true`.
  --added-to-conversation-template: string # The template to use to create the notification text displayed when a participant is added to a conversation and `added_to_conversation.enabled` is `true`.
  --log-enabled: oneof<nothing, bool> # Weather the notification logging is enabled.
  --new-message-badge-count-enabled: oneof<nothing, bool> # Whether the new message badge is enabled. The default is `false`.
  --new-message-enabled: oneof<nothing, bool> # Whether to send a notification when a new message is added to a conversation. The default is `false`.
  --new-message-sound: string # The name of the sound to play when a new message is added to a conversation and `new_message.enabled` is `true`.
  --new-message-template: string # The template to use to create the notification text displayed when a new message is added to a conversation and `new_message.enabled` is `true`.
  --new-message-with-media-enabled: oneof<nothing, bool> # Whether to send a notification when a new message with media/file attachments is added to a conversation. The default is `false`.
  --new-message-with-media-template: string # The template to use to create the notification text displayed when a new message with media/file attachments is added to a conversation and `new_message.attachments.enabled` is `true`.
  --removed-from-conversation-enabled: oneof<nothing, bool> # Whether to send a notification to a user when they are removed from a conversation. The default is `false`.
  --removed-from-conversation-sound: string # The name of the sound to play to a user when they are removed from a conversation and `removed_from_conversation.enabled` is `true`.
  --removed-from-conversation-template: string # The template to use to create the notification text displayed to a user when they are removed from a conversation and `removed_from_conversation.enabled` is `true`.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Services/{ChatServiceSid}/Configuration/Notifications"
    path_params: [{name: ChatServiceSid, var: chat_service_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: "AddedToConversation.Enabled", var: added_to_conversation_enabled}, {name: "AddedToConversation.Sound", var: added_to_conversation_sound}, {name: "AddedToConversation.Template", var: added_to_conversation_template}, {name: LogEnabled, var: log_enabled}, {name: "NewMessage.BadgeCountEnabled", var: new_message_badge_count_enabled}, {name: "NewMessage.Enabled", var: new_message_enabled}, {name: "NewMessage.Sound", var: new_message_sound}, {name: "NewMessage.Template", var: new_message_template}, {name: "NewMessage.WithMedia.Enabled", var: new_message_with_media_enabled}, {name: "NewMessage.WithMedia.Template", var: new_message_with_media_template}, {name: "RemovedFromConversation.Enabled", var: removed_from_conversation_enabled}, {name: "RemovedFromConversation.Sound", var: removed_from_conversation_sound}, {name: "RemovedFromConversation.Template", var: removed_from_conversation_template}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    chat_service_sid: $chat_service_sid, added_to_conversation_enabled: $added_to_conversation_enabled, added_to_conversation_sound: $added_to_conversation_sound, added_to_conversation_template: $added_to_conversation_template, log_enabled: $log_enabled, new_message_badge_count_enabled: $new_message_badge_count_enabled, new_message_enabled: $new_message_enabled, new_message_sound: $new_message_sound, new_message_template: $new_message_template, new_message_with_media_enabled: $new_message_with_media_enabled, new_message_with_media_template: $new_message_with_media_template, removed_from_conversation_enabled: $removed_from_conversation_enabled, removed_from_conversation_sound: $removed_from_conversation_sound, removed_from_conversation_template: $removed_from_conversation_template
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a specific service webhook configuration.
#
# GET /v1/Services/{ChatServiceSid}/Configuration/Webhooks
# Returns: record<account_sid: string, chat_service_sid: string, filters: list<string>, method: string, post_webhook_url: string, pre_webhook_url: string, url: string>
# operationId: FetchServiceWebhookConfiguration
export def "fetch-service-webhook-configuration" [
  chat_service_sid: string
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
    path: "/v1/Services/{ChatServiceSid}/Configuration/Webhooks"
    path_params: [{name: ChatServiceSid, var: chat_service_sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    chat_service_sid: $chat_service_sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a specific Webhook.
#
# POST /v1/Services/{ChatServiceSid}/Configuration/Webhooks
# Returns: record<account_sid: string, chat_service_sid: string, filters: list<string>, method: string, post_webhook_url: string, pre_webhook_url: string, url: string>
# operationId: UpdateServiceWebhookConfiguration
export def "update-service-webhook-configuration" [
  chat_service_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: list<string> # The list of events that your configured webhook targets will receive. Events not configured here will not fire. Possible values are `onParticipantAdd`, `onParticipantAdded`, `onDeliveryUpdated`, `onConversationUpdated`, `onConversationRemove`, `onParticipantRemove`, `onConversationUpdate`, `onMessageAdd`, `onMessageRemoved`, `onParticipantUpdated`, `onConversationAdded`, `onMessageAdded`, `onConversationAdd`, `onConversationRemoved`, `onParticipantUpdate`, `onMessageRemove`, `onMessageUpdated`, `onParticipantRemoved`, `onMessageUpdate` or `onConversationStateUpdated`.
  --method: string # The HTTP method to be used when sending a webhook request. One of `GET` or `POST`.
  --post-webhook-url: string # The absolute url the post-event webhook request should be sent to. (format: uri)
  --pre-webhook-url: string # The absolute url the pre-event webhook request should be sent to. (format: uri)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Services/{ChatServiceSid}/Configuration/Webhooks"
    path_params: [{name: ChatServiceSid, var: chat_service_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Filters, var: filters}, {name: Method, var: method}, {name: PostWebhookUrl, var: post_webhook_url}, {name: PreWebhookUrl, var: pre_webhook_url}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    chat_service_sid: $chat_service_sid, filters: $filters, method: $method, post_webhook_url: $post_webhook_url, pre_webhook_url: $pre_webhook_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of conversations in your service
#
# GET /v1/Services/{ChatServiceSid}/Conversations
# Returns: record<conversations: table<account_sid: string, attributes: string, bindings: any, chat_service_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, messaging_service_sid: string, sid: string, state: string, timers: any, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListServiceConversation
export def "list-service-conversation" [
  chat_service_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # Start date or time in ISO8601 format for filtering list of Conversations. If a date is provided, the start time of the date is used (YYYY-MM-DDT00:00:00Z). Can be combined with other filters.
  --end-date: string # End date or time in ISO8601 format for filtering list of Conversations. If a date is provided, the end time of the date is used (YYYY-MM-DDT23:59:59Z). Can be combined with other filters.
  --state: string@state-completer # State for sorting and filtering list of Conversations. Can be `active`, `inactive` or `closed`
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/Services/{ChatServiceSid}/Conversations"
    path_params: [{name: ChatServiceSid, var: chat_service_sid}]
    query: [{name: StartDate, var: start_date}, {name: EndDate, var: end_date}, {name: State, var: state}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    chat_service_sid: $chat_service_sid, start_date: $start_date, end_date: $end_date, state: $state, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new conversation in your service
#
# POST /v1/Services/{ChatServiceSid}/Conversations
# Returns: record<account_sid: string, attributes: string, bindings: any, chat_service_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, messaging_service_sid: string, sid: string, state: string, timers: any, unique_name: string, url: string>
# operationId: CreateServiceConversation
export def "create-service-conversation" [
  chat_service_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-twilio-webhook-enabled: string@x-twilio-webhook-enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
  --attributes: string # An optional string metadata field you can use to store any data you wish. The string value must contain structurally valid JSON if specified. **Note** that if the attributes are not set "{}" will be returned.
  --date-created: string # The date that this resource was created. (format: date-time)
  --date-updated: string # The date that this resource was last updated. (format: date-time)
  --friendly-name: string # The human-readable name of this conversation, limited to 256 characters. Optional.
  --messaging-service-sid: string # The unique ID of the [Messaging Service](https://www.twilio.com/docs/sms/services/api) this conversation belongs to.
  --state: string@state-completer
  --timers-closed: string # ISO8601 duration when conversation will be switched to `closed` state. Minimum value for this timer is 10 minutes.
  --timers-inactive: string # ISO8601 duration when conversation will be switched to `inactive` state. Minimum value for this timer is 1 minute.
  --unique-name: string # An application-defined string that uniquely identifies the resource. It can be used to address the resource in place of the resource's `sid` in the URL.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Services/{ChatServiceSid}/Conversations"
    path_params: [{name: ChatServiceSid, var: chat_service_sid}]
    header: [{name: X-Twilio-Webhook-Enabled, var: x_twilio_webhook_enabled}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Attributes, var: attributes}, {name: DateCreated, var: date_created}, {name: DateUpdated, var: date_updated}, {name: FriendlyName, var: friendly_name}, {name: MessagingServiceSid, var: messaging_service_sid}, {name: State, var: state}, {name: "Timers.Closed", var: timers_closed}, {name: "Timers.Inactive", var: timers_inactive}, {name: UniqueName, var: unique_name}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    chat_service_sid: $chat_service_sid, x_twilio_webhook_enabled: $x_twilio_webhook_enabled, attributes: $attributes, date_created: $date_created, date_updated: $date_updated, friendly_name: $friendly_name, messaging_service_sid: $messaging_service_sid, state: $state, timers_closed: $timers_closed, timers_inactive: $timers_inactive, unique_name: $unique_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of all messages in the conversation
#
# GET /v1/Services/{ChatServiceSid}/Conversations/{ConversationSid}/Messages
# Returns: record<messages: table<account_sid: string, attributes: string, author: string, body: string, chat_service_sid: string, content_sid: string, conversation_sid: string, date_created: string, date_updated: string, delivery: any, index: int, links: record, media: list, participant_sid: string, sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListServiceConversationMessage
export def "list-service-conversation-message" [
  chat_service_sid: string
  conversation_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --order: string@order-completer # The sort order of the returned messages. Can be: `asc` (ascending) or `desc` (descending), with `asc` as the default.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/Services/{ChatServiceSid}/Conversations/{ConversationSid}/Messages"
    path_params: [{name: ChatServiceSid, var: chat_service_sid}, {name: ConversationSid, var: conversation_sid}]
    query: [{name: Order, var: order}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    chat_service_sid: $chat_service_sid, conversation_sid: $conversation_sid, order: $order, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a new message to the conversation in a specific service
#
# POST /v1/Services/{ChatServiceSid}/Conversations/{ConversationSid}/Messages
# Returns: record<account_sid: string, attributes: string, author: string, body: string, chat_service_sid: string, content_sid: string, conversation_sid: string, date_created: string, date_updated: string, delivery: any, index: int, links: record, media: list<any>, participant_sid: string, sid: string, url: string>
# operationId: CreateServiceConversationMessage
export def "create-service-conversation-message" [
  chat_service_sid: string
  conversation_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-twilio-webhook-enabled: string@x-twilio-webhook-enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
  --attributes: string # A string metadata field you can use to store any data you wish. The string value must contain structurally valid JSON if specified. **Note** that if the attributes are not set "{}" will be returned.
  --author: string # The channel specific identifier of the message's author. Defaults to `system`.
  --body: string # The content of the message, can be up to 1,600 characters long.
  --content-sid: string # The unique ID of the multi-channel [Rich Content](https://www.twilio.com/docs/content-api) template, required for template-generated messages. **Note** that if this field is set, `Body` and `MediaSid` parameters are ignored.
  --content-variables: string # A structurally valid JSON string that contains values to resolve Rich Content template variables.
  --date-created: string # The date that this resource was created. (format: date-time)
  --date-updated: string # The date that this resource was last updated. `null` if the message has not been edited. (format: date-time)
  --media-sid: string # The Media SID to be attached to the new Message.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Services/{ChatServiceSid}/Conversations/{ConversationSid}/Messages"
    path_params: [{name: ChatServiceSid, var: chat_service_sid}, {name: ConversationSid, var: conversation_sid}]
    header: [{name: X-Twilio-Webhook-Enabled, var: x_twilio_webhook_enabled}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Attributes, var: attributes}, {name: Author, var: author}, {name: Body, var: body}, {name: ContentSid, var: content_sid}, {name: ContentVariables, var: content_variables}, {name: DateCreated, var: date_created}, {name: DateUpdated, var: date_updated}, {name: MediaSid, var: media_sid}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    chat_service_sid: $chat_service_sid, conversation_sid: $conversation_sid, x_twilio_webhook_enabled: $x_twilio_webhook_enabled, attributes: $attributes, author: $author, body: $body, content_sid: $content_sid, content_variables: $content_variables, date_created: $date_created, date_updated: $date_updated, media_sid: $media_sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of all delivery and read receipts of the conversation message
#
# GET /v1/Services/{ChatServiceSid}/Conversations/{ConversationSid}/Messages/{MessageSid}/Receipts
# Returns: record<delivery_receipts: table<account_sid: string, channel_message_sid: string, chat_service_sid: string, conversation_sid: string, date_created: string, date_updated: string, error_code: int, message_sid: string, participant_sid: string, sid: string, status: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListServiceConversationMessageReceipt
export def "list-service-conversation-message-receipt" [
  chat_service_sid: string
  conversation_sid: string
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
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/Services/{ChatServiceSid}/Conversations/{ConversationSid}/Messages/{MessageSid}/Receipts"
    path_params: [{name: ChatServiceSid, var: chat_service_sid}, {name: ConversationSid, var: conversation_sid}, {name: MessageSid, var: message_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    chat_service_sid: $chat_service_sid, conversation_sid: $conversation_sid, message_sid: $message_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch the delivery and read receipts of the conversation message
#
# GET /v1/Services/{ChatServiceSid}/Conversations/{ConversationSid}/Messages/{MessageSid}/Receipts/{Sid}
# Returns: record<account_sid: string, channel_message_sid: string, chat_service_sid: string, conversation_sid: string, date_created: string, date_updated: string, error_code: int, message_sid: string, participant_sid: string, sid: string, status: string, url: string>
# operationId: FetchServiceConversationMessageReceipt
export def "fetch-service-conversation-message-receipt" [
  chat_service_sid: string
  conversation_sid: string
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
    path: "/v1/Services/{ChatServiceSid}/Conversations/{ConversationSid}/Messages/{MessageSid}/Receipts/{Sid}"
    path_params: [{name: ChatServiceSid, var: chat_service_sid}, {name: ConversationSid, var: conversation_sid}, {name: MessageSid, var: message_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    chat_service_sid: $chat_service_sid, conversation_sid: $conversation_sid, message_sid: $message_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a message from the conversation
#
# DELETE /v1/Services/{ChatServiceSid}/Conversations/{ConversationSid}/Messages/{Sid}
# operationId: DeleteServiceConversationMessage
export def "delete-service-conversation-message" [
  chat_service_sid: string
  conversation_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-twilio-webhook-enabled: string@x-twilio-webhook-enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
]: nothing -> any {
  http-request {
    method: delete
    path: "/v1/Services/{ChatServiceSid}/Conversations/{ConversationSid}/Messages/{Sid}"
    path_params: [{name: ChatServiceSid, var: chat_service_sid}, {name: ConversationSid, var: conversation_sid}, {name: Sid, var: sid}]
    header: [{name: X-Twilio-Webhook-Enabled, var: x_twilio_webhook_enabled}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    chat_service_sid: $chat_service_sid, conversation_sid: $conversation_sid, sid: $sid, x_twilio_webhook_enabled: $x_twilio_webhook_enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a message from the conversation
#
# GET /v1/Services/{ChatServiceSid}/Conversations/{ConversationSid}/Messages/{Sid}
# Returns: record<account_sid: string, attributes: string, author: string, body: string, chat_service_sid: string, content_sid: string, conversation_sid: string, date_created: string, date_updated: string, delivery: any, index: int, links: record, media: list<any>, participant_sid: string, sid: string, url: string>
# operationId: FetchServiceConversationMessage
export def "fetch-service-conversation-message" [
  chat_service_sid: string
  conversation_sid: string
  sid: string
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
    path: "/v1/Services/{ChatServiceSid}/Conversations/{ConversationSid}/Messages/{Sid}"
    path_params: [{name: ChatServiceSid, var: chat_service_sid}, {name: ConversationSid, var: conversation_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    chat_service_sid: $chat_service_sid, conversation_sid: $conversation_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing message in the conversation
#
# POST /v1/Services/{ChatServiceSid}/Conversations/{ConversationSid}/Messages/{Sid}
# Returns: record<account_sid: string, attributes: string, author: string, body: string, chat_service_sid: string, content_sid: string, conversation_sid: string, date_created: string, date_updated: string, delivery: any, index: int, links: record, media: list<any>, participant_sid: string, sid: string, url: string>
# operationId: UpdateServiceConversationMessage
export def "update-service-conversation-message" [
  chat_service_sid: string
  conversation_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-twilio-webhook-enabled: string@x-twilio-webhook-enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
  --attributes: string # A string metadata field you can use to store any data you wish. The string value must contain structurally valid JSON if specified. **Note** that if the attributes are not set "{}" will be returned.
  --author: string # The channel specific identifier of the message's author. Defaults to `system`.
  --body: string # The content of the message, can be up to 1,600 characters long.
  --date-created: string # The date that this resource was created. (format: date-time)
  --date-updated: string # The date that this resource was last updated. `null` if the message has not been edited. (format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Services/{ChatServiceSid}/Conversations/{ConversationSid}/Messages/{Sid}"
    path_params: [{name: ChatServiceSid, var: chat_service_sid}, {name: ConversationSid, var: conversation_sid}, {name: Sid, var: sid}]
    header: [{name: X-Twilio-Webhook-Enabled, var: x_twilio_webhook_enabled}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Attributes, var: attributes}, {name: Author, var: author}, {name: Body, var: body}, {name: DateCreated, var: date_created}, {name: DateUpdated, var: date_updated}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    chat_service_sid: $chat_service_sid, conversation_sid: $conversation_sid, sid: $sid, x_twilio_webhook_enabled: $x_twilio_webhook_enabled, attributes: $attributes, author: $author, body: $body, date_created: $date_created, date_updated: $date_updated
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of all participants of the conversation
#
# GET /v1/Services/{ChatServiceSid}/Conversations/{ConversationSid}/Participants
# Returns: record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, participants: table<account_sid: string, attributes: string, chat_service_sid: string, conversation_sid: string, date_created: string, date_updated: string, identity: string, last_read_message_index: int, last_read_timestamp: string, messaging_binding: any, role_sid: string, sid: string, url: string>>
# operationId: ListServiceConversationParticipant
export def "list-service-conversation-participant" [
  chat_service_sid: string
  conversation_sid: string
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
    path: "/v1/Services/{ChatServiceSid}/Conversations/{ConversationSid}/Participants"
    path_params: [{name: ChatServiceSid, var: chat_service_sid}, {name: ConversationSid, var: conversation_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    chat_service_sid: $chat_service_sid, conversation_sid: $conversation_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a new participant to the conversation in a specific service
#
# POST /v1/Services/{ChatServiceSid}/Conversations/{ConversationSid}/Participants
# Returns: record<account_sid: string, attributes: string, chat_service_sid: string, conversation_sid: string, date_created: string, date_updated: string, identity: string, last_read_message_index: int, last_read_timestamp: string, messaging_binding: any, role_sid: string, sid: string, url: string>
# operationId: CreateServiceConversationParticipant
export def "create-service-conversation-participant" [
  chat_service_sid: string
  conversation_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-twilio-webhook-enabled: string@x-twilio-webhook-enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
  --attributes: string # An optional string metadata field you can use to store any data you wish. The string value must contain structurally valid JSON if specified. **Note** that if the attributes are not set "{}" will be returned.
  --date-created: string # The date that this resource was created. (format: date-time)
  --date-updated: string # The date that this resource was last updated. (format: date-time)
  --identity: string # A unique string identifier for the conversation participant as [Conversation User](https://www.twilio.com/docs/conversations/api/user-resource). This parameter is non-null if (and only if) the participant is using the Conversation SDK to communicate. Limited to 256 characters.
  --messaging-binding-address: string # The address of the participant's device, e.g. a phone or WhatsApp number. Together with the Proxy address, this determines a participant uniquely. This field (with proxy_address) is only null when the participant is interacting from an SDK endpoint (see the 'identity' field).
  --messaging-binding-projected-address: string # The address of the Twilio phone number that is used in Group MMS. Communication mask for the Conversation participant with Identity.
  --messaging-binding-proxy-address: string # The address of the Twilio phone number (or WhatsApp number) that the participant is in contact with. This field, together with participant address, is only null when the participant is interacting from an SDK endpoint (see the 'identity' field).
  --role-sid: string # The SID of a conversation-level [Role](https://www.twilio.com/docs/conversations/api/role-resource) to assign to the participant.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Services/{ChatServiceSid}/Conversations/{ConversationSid}/Participants"
    path_params: [{name: ChatServiceSid, var: chat_service_sid}, {name: ConversationSid, var: conversation_sid}]
    header: [{name: X-Twilio-Webhook-Enabled, var: x_twilio_webhook_enabled}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Attributes, var: attributes}, {name: DateCreated, var: date_created}, {name: DateUpdated, var: date_updated}, {name: Identity, var: identity}, {name: "MessagingBinding.Address", var: messaging_binding_address}, {name: "MessagingBinding.ProjectedAddress", var: messaging_binding_projected_address}, {name: "MessagingBinding.ProxyAddress", var: messaging_binding_proxy_address}, {name: RoleSid, var: role_sid}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    chat_service_sid: $chat_service_sid, conversation_sid: $conversation_sid, x_twilio_webhook_enabled: $x_twilio_webhook_enabled, attributes: $attributes, date_created: $date_created, date_updated: $date_updated, identity: $identity, messaging_binding_address: $messaging_binding_address, messaging_binding_projected_address: $messaging_binding_projected_address, messaging_binding_proxy_address: $messaging_binding_proxy_address, role_sid: $role_sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a participant from the conversation
#
# DELETE /v1/Services/{ChatServiceSid}/Conversations/{ConversationSid}/Participants/{Sid}
# operationId: DeleteServiceConversationParticipant
export def "delete-service-conversation-participant" [
  chat_service_sid: string
  conversation_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-twilio-webhook-enabled: string@x-twilio-webhook-enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
]: nothing -> any {
  http-request {
    method: delete
    path: "/v1/Services/{ChatServiceSid}/Conversations/{ConversationSid}/Participants/{Sid}"
    path_params: [{name: ChatServiceSid, var: chat_service_sid}, {name: ConversationSid, var: conversation_sid}, {name: Sid, var: sid}]
    header: [{name: X-Twilio-Webhook-Enabled, var: x_twilio_webhook_enabled}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    chat_service_sid: $chat_service_sid, conversation_sid: $conversation_sid, sid: $sid, x_twilio_webhook_enabled: $x_twilio_webhook_enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a participant of the conversation
#
# GET /v1/Services/{ChatServiceSid}/Conversations/{ConversationSid}/Participants/{Sid}
# Returns: record<account_sid: string, attributes: string, chat_service_sid: string, conversation_sid: string, date_created: string, date_updated: string, identity: string, last_read_message_index: int, last_read_timestamp: string, messaging_binding: any, role_sid: string, sid: string, url: string>
# operationId: FetchServiceConversationParticipant
export def "fetch-service-conversation-participant" [
  chat_service_sid: string
  conversation_sid: string
  sid: string
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
    path: "/v1/Services/{ChatServiceSid}/Conversations/{ConversationSid}/Participants/{Sid}"
    path_params: [{name: ChatServiceSid, var: chat_service_sid}, {name: ConversationSid, var: conversation_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    chat_service_sid: $chat_service_sid, conversation_sid: $conversation_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing participant in the conversation
#
# POST /v1/Services/{ChatServiceSid}/Conversations/{ConversationSid}/Participants/{Sid}
# Returns: record<account_sid: string, attributes: string, chat_service_sid: string, conversation_sid: string, date_created: string, date_updated: string, identity: string, last_read_message_index: int, last_read_timestamp: string, messaging_binding: any, role_sid: string, sid: string, url: string>
# operationId: UpdateServiceConversationParticipant
export def "update-service-conversation-participant" [
  chat_service_sid: string
  conversation_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-twilio-webhook-enabled: string@x-twilio-webhook-enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
  --attributes: string # An optional string metadata field you can use to store any data you wish. The string value must contain structurally valid JSON if specified. **Note** that if the attributes are not set "{}" will be returned.
  --date-created: string # The date that this resource was created. (format: date-time)
  --date-updated: string # The date that this resource was last updated. (format: date-time)
  --identity: string # A unique string identifier for the conversation participant as [Conversation User](https://www.twilio.com/docs/conversations/api/user-resource). This parameter is non-null if (and only if) the participant is using the Conversation SDK to communicate. Limited to 256 characters.
  --last-read-message-index: int # Index of last “read” message in the [Conversation](https://www.twilio.com/docs/conversations/api/conversation-resource) for the Participant. (nullable)
  --last-read-timestamp: string # Timestamp of last “read” message in the [Conversation](https://www.twilio.com/docs/conversations/api/conversation-resource) for the Participant.
  --messaging-binding-projected-address: string # The address of the Twilio phone number that is used in Group MMS. 'null' value will remove it.
  --messaging-binding-proxy-address: string # The address of the Twilio phone number that the participant is in contact with. 'null' value will remove it.
  --role-sid: string # The SID of a conversation-level [Role](https://www.twilio.com/docs/conversations/api/role-resource) to assign to the participant.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Services/{ChatServiceSid}/Conversations/{ConversationSid}/Participants/{Sid}"
    path_params: [{name: ChatServiceSid, var: chat_service_sid}, {name: ConversationSid, var: conversation_sid}, {name: Sid, var: sid}]
    header: [{name: X-Twilio-Webhook-Enabled, var: x_twilio_webhook_enabled}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Attributes, var: attributes}, {name: DateCreated, var: date_created}, {name: DateUpdated, var: date_updated}, {name: Identity, var: identity}, {name: LastReadMessageIndex, var: last_read_message_index}, {name: LastReadTimestamp, var: last_read_timestamp}, {name: "MessagingBinding.ProjectedAddress", var: messaging_binding_projected_address}, {name: "MessagingBinding.ProxyAddress", var: messaging_binding_proxy_address}, {name: RoleSid, var: role_sid}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    chat_service_sid: $chat_service_sid, conversation_sid: $conversation_sid, sid: $sid, x_twilio_webhook_enabled: $x_twilio_webhook_enabled, attributes: $attributes, date_created: $date_created, date_updated: $date_updated, identity: $identity, last_read_message_index: $last_read_message_index, last_read_timestamp: $last_read_timestamp, messaging_binding_projected_address: $messaging_binding_projected_address, messaging_binding_proxy_address: $messaging_binding_proxy_address, role_sid: $role_sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of all webhooks scoped to the conversation
#
# GET /v1/Services/{ChatServiceSid}/Conversations/{ConversationSid}/Webhooks
# Returns: record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, webhooks: table<account_sid: string, chat_service_sid: string, configuration: any, conversation_sid: string, date_created: string, date_updated: string, sid: string, target: string, url: string>>
# operationId: ListServiceConversationScopedWebhook
export def "list-service-conversation-scoped-webhook" [
  chat_service_sid: string
  conversation_sid: string
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
    path: "/v1/Services/{ChatServiceSid}/Conversations/{ConversationSid}/Webhooks"
    path_params: [{name: ChatServiceSid, var: chat_service_sid}, {name: ConversationSid, var: conversation_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    chat_service_sid: $chat_service_sid, conversation_sid: $conversation_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new webhook scoped to the conversation in a specific service
#
# POST /v1/Services/{ChatServiceSid}/Conversations/{ConversationSid}/Webhooks
# Returns: record<account_sid: string, chat_service_sid: string, configuration: any, conversation_sid: string, date_created: string, date_updated: string, sid: string, target: string, url: string>
# operationId: CreateServiceConversationScopedWebhook
export def "create-service-conversation-scoped-webhook" [
  chat_service_sid: string
  conversation_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --configuration-filters: list<string> # The list of events, firing webhook event for this Conversation.
  --configuration-flow-sid: string # The studio flow SID, where the webhook should be sent to.
  --configuration-method: string@configuration-method-completer
  --configuration-replay-after: int # The message index for which and it's successors the webhook will be replayed. Not set by default
  --configuration-triggers: list<string> # The list of keywords, firing webhook event for this Conversation.
  --configuration-url: string # The absolute url the webhook request should be sent to.
  target: string@target-completer-1
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Services/{ChatServiceSid}/Conversations/{ConversationSid}/Webhooks"
    path_params: [{name: ChatServiceSid, var: chat_service_sid}, {name: ConversationSid, var: conversation_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: "Configuration.Filters", var: configuration_filters}, {name: "Configuration.FlowSid", var: configuration_flow_sid}, {name: "Configuration.Method", var: configuration_method}, {name: "Configuration.ReplayAfter", var: configuration_replay_after}, {name: "Configuration.Triggers", var: configuration_triggers}, {name: "Configuration.Url", var: configuration_url}, {name: Target, var: target}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    chat_service_sid: $chat_service_sid, conversation_sid: $conversation_sid, configuration_filters: $configuration_filters, configuration_flow_sid: $configuration_flow_sid, configuration_method: $configuration_method, configuration_replay_after: $configuration_replay_after, configuration_triggers: $configuration_triggers, configuration_url: $configuration_url, target: $target
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove an existing webhook scoped to the conversation
#
# DELETE /v1/Services/{ChatServiceSid}/Conversations/{ConversationSid}/Webhooks/{Sid}
# operationId: DeleteServiceConversationScopedWebhook
export def "delete-service-conversation-scoped-webhook" [
  chat_service_sid: string
  conversation_sid: string
  sid: string
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
    path: "/v1/Services/{ChatServiceSid}/Conversations/{ConversationSid}/Webhooks/{Sid}"
    path_params: [{name: ChatServiceSid, var: chat_service_sid}, {name: ConversationSid, var: conversation_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    chat_service_sid: $chat_service_sid, conversation_sid: $conversation_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch the configuration of a conversation-scoped webhook
#
# GET /v1/Services/{ChatServiceSid}/Conversations/{ConversationSid}/Webhooks/{Sid}
# Returns: record<account_sid: string, chat_service_sid: string, configuration: any, conversation_sid: string, date_created: string, date_updated: string, sid: string, target: string, url: string>
# operationId: FetchServiceConversationScopedWebhook
export def "fetch-service-conversation-scoped-webhook" [
  chat_service_sid: string
  conversation_sid: string
  sid: string
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
    path: "/v1/Services/{ChatServiceSid}/Conversations/{ConversationSid}/Webhooks/{Sid}"
    path_params: [{name: ChatServiceSid, var: chat_service_sid}, {name: ConversationSid, var: conversation_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    chat_service_sid: $chat_service_sid, conversation_sid: $conversation_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing conversation-scoped webhook
#
# POST /v1/Services/{ChatServiceSid}/Conversations/{ConversationSid}/Webhooks/{Sid}
# Returns: record<account_sid: string, chat_service_sid: string, configuration: any, conversation_sid: string, date_created: string, date_updated: string, sid: string, target: string, url: string>
# operationId: UpdateServiceConversationScopedWebhook
export def "update-service-conversation-scoped-webhook" [
  chat_service_sid: string
  conversation_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --configuration-filters: list<string> # The list of events, firing webhook event for this Conversation.
  --configuration-flow-sid: string # The studio flow SID, where the webhook should be sent to.
  --configuration-method: string@configuration-method-completer
  --configuration-triggers: list<string> # The list of keywords, firing webhook event for this Conversation.
  --configuration-url: string # The absolute url the webhook request should be sent to.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Services/{ChatServiceSid}/Conversations/{ConversationSid}/Webhooks/{Sid}"
    path_params: [{name: ChatServiceSid, var: chat_service_sid}, {name: ConversationSid, var: conversation_sid}, {name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: "Configuration.Filters", var: configuration_filters}, {name: "Configuration.FlowSid", var: configuration_flow_sid}, {name: "Configuration.Method", var: configuration_method}, {name: "Configuration.Triggers", var: configuration_triggers}, {name: "Configuration.Url", var: configuration_url}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    chat_service_sid: $chat_service_sid, conversation_sid: $conversation_sid, sid: $sid, configuration_filters: $configuration_filters, configuration_flow_sid: $configuration_flow_sid, configuration_method: $configuration_method, configuration_triggers: $configuration_triggers, configuration_url: $configuration_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a conversation from your service
#
# DELETE /v1/Services/{ChatServiceSid}/Conversations/{Sid}
# operationId: DeleteServiceConversation
export def "delete-service-conversation" [
  chat_service_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-twilio-webhook-enabled: string@x-twilio-webhook-enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
]: nothing -> any {
  http-request {
    method: delete
    path: "/v1/Services/{ChatServiceSid}/Conversations/{Sid}"
    path_params: [{name: ChatServiceSid, var: chat_service_sid}, {name: Sid, var: sid}]
    header: [{name: X-Twilio-Webhook-Enabled, var: x_twilio_webhook_enabled}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    chat_service_sid: $chat_service_sid, sid: $sid, x_twilio_webhook_enabled: $x_twilio_webhook_enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a conversation from your service
#
# GET /v1/Services/{ChatServiceSid}/Conversations/{Sid}
# Returns: record<account_sid: string, attributes: string, bindings: any, chat_service_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, messaging_service_sid: string, sid: string, state: string, timers: any, unique_name: string, url: string>
# operationId: FetchServiceConversation
export def "fetch-service-conversation" [
  chat_service_sid: string
  sid: string
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
    path: "/v1/Services/{ChatServiceSid}/Conversations/{Sid}"
    path_params: [{name: ChatServiceSid, var: chat_service_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    chat_service_sid: $chat_service_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing conversation in your service
#
# POST /v1/Services/{ChatServiceSid}/Conversations/{Sid}
# Returns: record<account_sid: string, attributes: string, bindings: any, chat_service_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, messaging_service_sid: string, sid: string, state: string, timers: any, unique_name: string, url: string>
# operationId: UpdateServiceConversation
export def "update-service-conversation" [
  chat_service_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-twilio-webhook-enabled: string@x-twilio-webhook-enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
  --attributes: string # An optional string metadata field you can use to store any data you wish. The string value must contain structurally valid JSON if specified. **Note** that if the attributes are not set "{}" will be returned.
  --date-created: string # The date that this resource was created. (format: date-time)
  --date-updated: string # The date that this resource was last updated. (format: date-time)
  --friendly-name: string # The human-readable name of this conversation, limited to 256 characters. Optional.
  --messaging-service-sid: string # The unique ID of the [Messaging Service](https://www.twilio.com/docs/sms/services/api) this conversation belongs to.
  --state: string@state-completer
  --timers-closed: string # ISO8601 duration when conversation will be switched to `closed` state. Minimum value for this timer is 10 minutes.
  --timers-inactive: string # ISO8601 duration when conversation will be switched to `inactive` state. Minimum value for this timer is 1 minute.
  --unique-name: string # An application-defined string that uniquely identifies the resource. It can be used to address the resource in place of the resource's `sid` in the URL.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Services/{ChatServiceSid}/Conversations/{Sid}"
    path_params: [{name: ChatServiceSid, var: chat_service_sid}, {name: Sid, var: sid}]
    header: [{name: X-Twilio-Webhook-Enabled, var: x_twilio_webhook_enabled}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Attributes, var: attributes}, {name: DateCreated, var: date_created}, {name: DateUpdated, var: date_updated}, {name: FriendlyName, var: friendly_name}, {name: MessagingServiceSid, var: messaging_service_sid}, {name: State, var: state}, {name: "Timers.Closed", var: timers_closed}, {name: "Timers.Inactive", var: timers_inactive}, {name: UniqueName, var: unique_name}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    chat_service_sid: $chat_service_sid, sid: $sid, x_twilio_webhook_enabled: $x_twilio_webhook_enabled, attributes: $attributes, date_created: $date_created, date_updated: $date_updated, friendly_name: $friendly_name, messaging_service_sid: $messaging_service_sid, state: $state, timers_closed: $timers_closed, timers_inactive: $timers_inactive, unique_name: $unique_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of all Conversations that this Participant belongs to by identity or by address. Only one parameter should be specified.
#
# GET /v1/Services/{ChatServiceSid}/ParticipantConversations
# Returns: record<conversations: table<account_sid: string, chat_service_sid: string, conversation_attributes: string, conversation_created_by: string, conversation_date_created: string, conversation_date_updated: string, conversation_friendly_name: string, conversation_sid: string, conversation_state: string, conversation_timers: any, conversation_unique_name: string, links: record, participant_identity: string, participant_messaging_binding: any, participant_sid: string, participant_user_sid: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListServiceParticipantConversation
export def "list-service-participant-conversation" [
  chat_service_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --identity: string # A unique string identifier for the conversation participant as [Conversation User](https://www.twilio.com/docs/conversations/api/user-resource). This parameter is non-null if (and only if) the participant is using the Conversations SDK to communicate. Limited to 256 characters.
  --address: string # A unique string identifier for the conversation participant who's not a Conversation User. This parameter could be found in messaging_binding.address field of Participant resource. It should be url-encoded.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/Services/{ChatServiceSid}/ParticipantConversations"
    path_params: [{name: ChatServiceSid, var: chat_service_sid}]
    query: [{name: Identity, var: identity}, {name: Address, var: address}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    chat_service_sid: $chat_service_sid, identity: $identity, address: $address, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of all user roles in your service
#
# GET /v1/Services/{ChatServiceSid}/Roles
# Returns: record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, roles: table<account_sid: string, chat_service_sid: string, date_created: string, date_updated: string, friendly_name: string, permissions: list, sid: string, type: string, url: string>>
# operationId: ListServiceRole
export def "list-service-role" [
  chat_service_sid: string
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
    path: "/v1/Services/{ChatServiceSid}/Roles"
    path_params: [{name: ChatServiceSid, var: chat_service_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    chat_service_sid: $chat_service_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new user role in your service
#
# POST /v1/Services/{ChatServiceSid}/Roles
# Returns: record<account_sid: string, chat_service_sid: string, date_created: string, date_updated: string, friendly_name: string, permissions: list<string>, sid: string, type: string, url: string>
# operationId: CreateServiceRole
export def "create-service-role" [
  chat_service_sid: string
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
  permission: list<string> # A permission that you grant to the new role. Only one permission can be granted per parameter. To assign more than one permission, repeat this parameter for each permission value. The values for this parameter depend on the role's `type`.
  type: string@type-completer-2
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Services/{ChatServiceSid}/Roles"
    path_params: [{name: ChatServiceSid, var: chat_service_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: FriendlyName, var: friendly_name}, {name: Permission, var: permission}, {name: Type, var: type}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    chat_service_sid: $chat_service_sid, friendly_name: $friendly_name, permission: $permission, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a user role from your service
#
# DELETE /v1/Services/{ChatServiceSid}/Roles/{Sid}
# operationId: DeleteServiceRole
export def "delete-service-role" [
  chat_service_sid: string
  sid: string
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
    path: "/v1/Services/{ChatServiceSid}/Roles/{Sid}"
    path_params: [{name: ChatServiceSid, var: chat_service_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    chat_service_sid: $chat_service_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a user role from your service
#
# GET /v1/Services/{ChatServiceSid}/Roles/{Sid}
# Returns: record<account_sid: string, chat_service_sid: string, date_created: string, date_updated: string, friendly_name: string, permissions: list<string>, sid: string, type: string, url: string>
# operationId: FetchServiceRole
export def "fetch-service-role" [
  chat_service_sid: string
  sid: string
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
    path: "/v1/Services/{ChatServiceSid}/Roles/{Sid}"
    path_params: [{name: ChatServiceSid, var: chat_service_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    chat_service_sid: $chat_service_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing user role in your service
#
# POST /v1/Services/{ChatServiceSid}/Roles/{Sid}
# Returns: record<account_sid: string, chat_service_sid: string, date_created: string, date_updated: string, friendly_name: string, permissions: list<string>, sid: string, type: string, url: string>
# operationId: UpdateServiceRole
export def "update-service-role" [
  chat_service_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  permission: list<string> # A permission that you grant to the role. Only one permission can be granted per parameter. To assign more than one permission, repeat this parameter for each permission value. Note that the update action replaces all previously assigned permissions with those defined in the update action. To remove a permission, do not include it in the subsequent update action. The values for this parameter depend on the role's `type`.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Services/{ChatServiceSid}/Roles/{Sid}"
    path_params: [{name: ChatServiceSid, var: chat_service_sid}, {name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Permission, var: permission}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    chat_service_sid: $chat_service_sid, sid: $sid, permission: $permission
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of all conversation users in your service
#
# GET /v1/Services/{ChatServiceSid}/Users
# Returns: record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, users: table<account_sid: string, attributes: string, chat_service_sid: string, date_created: string, date_updated: string, friendly_name: string, identity: string, is_notifiable: bool, is_online: bool, links: record, role_sid: string, sid: string, url: string>>
# operationId: ListServiceUser
export def "list-service-user" [
  chat_service_sid: string
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
    path: "/v1/Services/{ChatServiceSid}/Users"
    path_params: [{name: ChatServiceSid, var: chat_service_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    chat_service_sid: $chat_service_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a new conversation user to your service
#
# POST /v1/Services/{ChatServiceSid}/Users
# Returns: record<account_sid: string, attributes: string, chat_service_sid: string, date_created: string, date_updated: string, friendly_name: string, identity: string, is_notifiable: bool, is_online: bool, links: record, role_sid: string, sid: string, url: string>
# operationId: CreateServiceUser
export def "create-service-user" [
  chat_service_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-twilio-webhook-enabled: string@x-twilio-webhook-enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
  --attributes: string # The JSON Object string that stores application-specific data. If attributes have not been set, `{}` is returned.
  --friendly-name: string # The string that you assigned to describe the resource.
  identity: string # The application-defined string that uniquely identifies the resource's User within the [Conversation Service](https://www.twilio.com/docs/conversations/api/service-resource). This value is often a username or an email address, and is case-sensitive.
  --role-sid: string # The SID of a service-level [Role](https://www.twilio.com/docs/conversations/api/role-resource) to assign to the user.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Services/{ChatServiceSid}/Users"
    path_params: [{name: ChatServiceSid, var: chat_service_sid}]
    header: [{name: X-Twilio-Webhook-Enabled, var: x_twilio_webhook_enabled}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Attributes, var: attributes}, {name: FriendlyName, var: friendly_name}, {name: Identity, var: identity}, {name: RoleSid, var: role_sid}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    chat_service_sid: $chat_service_sid, x_twilio_webhook_enabled: $x_twilio_webhook_enabled, attributes: $attributes, friendly_name: $friendly_name, identity: $identity, role_sid: $role_sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a conversation user from your service
#
# DELETE /v1/Services/{ChatServiceSid}/Users/{Sid}
# operationId: DeleteServiceUser
export def "delete-service-user" [
  chat_service_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-twilio-webhook-enabled: string@x-twilio-webhook-enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
]: nothing -> any {
  http-request {
    method: delete
    path: "/v1/Services/{ChatServiceSid}/Users/{Sid}"
    path_params: [{name: ChatServiceSid, var: chat_service_sid}, {name: Sid, var: sid}]
    header: [{name: X-Twilio-Webhook-Enabled, var: x_twilio_webhook_enabled}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    chat_service_sid: $chat_service_sid, sid: $sid, x_twilio_webhook_enabled: $x_twilio_webhook_enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a conversation user from your service
#
# GET /v1/Services/{ChatServiceSid}/Users/{Sid}
# Returns: record<account_sid: string, attributes: string, chat_service_sid: string, date_created: string, date_updated: string, friendly_name: string, identity: string, is_notifiable: bool, is_online: bool, links: record, role_sid: string, sid: string, url: string>
# operationId: FetchServiceUser
export def "fetch-service-user" [
  chat_service_sid: string
  sid: string
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
    path: "/v1/Services/{ChatServiceSid}/Users/{Sid}"
    path_params: [{name: ChatServiceSid, var: chat_service_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    chat_service_sid: $chat_service_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing conversation user in your service
#
# POST /v1/Services/{ChatServiceSid}/Users/{Sid}
# Returns: record<account_sid: string, attributes: string, chat_service_sid: string, date_created: string, date_updated: string, friendly_name: string, identity: string, is_notifiable: bool, is_online: bool, links: record, role_sid: string, sid: string, url: string>
# operationId: UpdateServiceUser
export def "update-service-user" [
  chat_service_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-twilio-webhook-enabled: string@x-twilio-webhook-enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
  --attributes: string # The JSON Object string that stores application-specific data. If attributes have not been set, `{}` is returned.
  --friendly-name: string # The string that you assigned to describe the resource.
  --role-sid: string # The SID of a service-level [Role](https://www.twilio.com/docs/conversations/api/role-resource) to assign to the user.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Services/{ChatServiceSid}/Users/{Sid}"
    path_params: [{name: ChatServiceSid, var: chat_service_sid}, {name: Sid, var: sid}]
    header: [{name: X-Twilio-Webhook-Enabled, var: x_twilio_webhook_enabled}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Attributes, var: attributes}, {name: FriendlyName, var: friendly_name}, {name: RoleSid, var: role_sid}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    chat_service_sid: $chat_service_sid, sid: $sid, x_twilio_webhook_enabled: $x_twilio_webhook_enabled, attributes: $attributes, friendly_name: $friendly_name, role_sid: $role_sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of all User Conversations for the User.
#
# GET /v1/Services/{ChatServiceSid}/Users/{UserSid}/Conversations
# Returns: record<conversations: table<account_sid: string, attributes: string, chat_service_sid: string, conversation_sid: string, conversation_state: string, created_by: string, date_created: string, date_updated: string, friendly_name: string, last_read_message_index: int, links: record, notification_level: string, participant_sid: string, timers: any, unique_name: string, unread_messages_count: int, url: string, user_sid: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListServiceUserConversation
export def "list-service-user-conversation" [
  chat_service_sid: string
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
    path: "/v1/Services/{ChatServiceSid}/Users/{UserSid}/Conversations"
    path_params: [{name: ChatServiceSid, var: chat_service_sid}, {name: UserSid, var: user_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    chat_service_sid: $chat_service_sid, user_sid: $user_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a specific User Conversation.
#
# DELETE /v1/Services/{ChatServiceSid}/Users/{UserSid}/Conversations/{ConversationSid}
# operationId: DeleteServiceUserConversation
export def "delete-service-user-conversation" [
  chat_service_sid: string
  user_sid: string
  conversation_sid: string
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
    path: "/v1/Services/{ChatServiceSid}/Users/{UserSid}/Conversations/{ConversationSid}"
    path_params: [{name: ChatServiceSid, var: chat_service_sid}, {name: UserSid, var: user_sid}, {name: ConversationSid, var: conversation_sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    chat_service_sid: $chat_service_sid, user_sid: $user_sid, conversation_sid: $conversation_sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a specific User Conversation.
#
# GET /v1/Services/{ChatServiceSid}/Users/{UserSid}/Conversations/{ConversationSid}
# Returns: record<account_sid: string, attributes: string, chat_service_sid: string, conversation_sid: string, conversation_state: string, created_by: string, date_created: string, date_updated: string, friendly_name: string, last_read_message_index: int, links: record, notification_level: string, participant_sid: string, timers: any, unique_name: string, unread_messages_count: int, url: string, user_sid: string>
# operationId: FetchServiceUserConversation
export def "fetch-service-user-conversation" [
  chat_service_sid: string
  user_sid: string
  conversation_sid: string
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
    path: "/v1/Services/{ChatServiceSid}/Users/{UserSid}/Conversations/{ConversationSid}"
    path_params: [{name: ChatServiceSid, var: chat_service_sid}, {name: UserSid, var: user_sid}, {name: ConversationSid, var: conversation_sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    chat_service_sid: $chat_service_sid, user_sid: $user_sid, conversation_sid: $conversation_sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a specific User Conversation.
#
# POST /v1/Services/{ChatServiceSid}/Users/{UserSid}/Conversations/{ConversationSid}
# Returns: record<account_sid: string, attributes: string, chat_service_sid: string, conversation_sid: string, conversation_state: string, created_by: string, date_created: string, date_updated: string, friendly_name: string, last_read_message_index: int, links: record, notification_level: string, participant_sid: string, timers: any, unique_name: string, unread_messages_count: int, url: string, user_sid: string>
# operationId: UpdateServiceUserConversation
export def "update-service-user-conversation" [
  chat_service_sid: string
  user_sid: string
  conversation_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --last-read-message-index: int # The index of the last Message in the Conversation that the Participant has read. (nullable)
  --last-read-timestamp: string # The date of the last message read in conversation by the user, given in ISO 8601 format. (format: date-time)
  --notification-level: string@notification-level-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Services/{ChatServiceSid}/Users/{UserSid}/Conversations/{ConversationSid}"
    path_params: [{name: ChatServiceSid, var: chat_service_sid}, {name: UserSid, var: user_sid}, {name: ConversationSid, var: conversation_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: LastReadMessageIndex, var: last_read_message_index}, {name: LastReadTimestamp, var: last_read_timestamp}, {name: NotificationLevel, var: notification_level}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    chat_service_sid: $chat_service_sid, user_sid: $user_sid, conversation_sid: $conversation_sid, last_read_message_index: $last_read_message_index, last_read_timestamp: $last_read_timestamp, notification_level: $notification_level
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a conversation service with all its nested resources from your account
#
# DELETE /v1/Services/{Sid}
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
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a conversation service from your account
#
# GET /v1/Services/{Sid}
# Returns: record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, url: string>
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
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of all conversation users in your account's default service
#
# GET /v1/Users
# Returns: record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, users: table<account_sid: string, attributes: string, chat_service_sid: string, date_created: string, date_updated: string, friendly_name: string, identity: string, is_notifiable: bool, is_online: bool, links: record, role_sid: string, sid: string, url: string>>
# operationId: ListUser
export def "list-user" [
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
    path: "/v1/Users"
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a new conversation user to your account's default service
#
# POST /v1/Users
# Returns: record<account_sid: string, attributes: string, chat_service_sid: string, date_created: string, date_updated: string, friendly_name: string, identity: string, is_notifiable: bool, is_online: bool, links: record, role_sid: string, sid: string, url: string>
# operationId: CreateUser
export def "create-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-twilio-webhook-enabled: string@x-twilio-webhook-enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
  --attributes: string # The JSON Object string that stores application-specific data. If attributes have not been set, `{}` is returned.
  --friendly-name: string # The string that you assigned to describe the resource.
  identity: string # The application-defined string that uniquely identifies the resource's User within the [Conversation Service](https://www.twilio.com/docs/conversations/api/service-resource). This value is often a username or an email address, and is case-sensitive.
  --role-sid: string # The SID of a service-level [Role](https://www.twilio.com/docs/conversations/api/role-resource) to assign to the user.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Users"
    header: [{name: X-Twilio-Webhook-Enabled, var: x_twilio_webhook_enabled}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Attributes, var: attributes}, {name: FriendlyName, var: friendly_name}, {name: Identity, var: identity}, {name: RoleSid, var: role_sid}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    x_twilio_webhook_enabled: $x_twilio_webhook_enabled, attributes: $attributes, friendly_name: $friendly_name, identity: $identity, role_sid: $role_sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a conversation user from your account's default service
#
# DELETE /v1/Users/{Sid}
# operationId: DeleteUser
export def "delete-user" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-twilio-webhook-enabled: string@x-twilio-webhook-enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
]: nothing -> any {
  http-request {
    method: delete
    path: "/v1/Users/{Sid}"
    path_params: [{name: Sid, var: sid}]
    header: [{name: X-Twilio-Webhook-Enabled, var: x_twilio_webhook_enabled}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    sid: $sid, x_twilio_webhook_enabled: $x_twilio_webhook_enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a conversation user from your account's default service
#
# GET /v1/Users/{Sid}
# Returns: record<account_sid: string, attributes: string, chat_service_sid: string, date_created: string, date_updated: string, friendly_name: string, identity: string, is_notifiable: bool, is_online: bool, links: record, role_sid: string, sid: string, url: string>
# operationId: FetchUser
export def "fetch-user" [
  sid: string
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
    path: "/v1/Users/{Sid}"
    path_params: [{name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing conversation user in your account's default service
#
# POST /v1/Users/{Sid}
# Returns: record<account_sid: string, attributes: string, chat_service_sid: string, date_created: string, date_updated: string, friendly_name: string, identity: string, is_notifiable: bool, is_online: bool, links: record, role_sid: string, sid: string, url: string>
# operationId: UpdateUser
export def "update-user" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-twilio-webhook-enabled: string@x-twilio-webhook-enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
  --attributes: string # The JSON Object string that stores application-specific data. If attributes have not been set, `{}` is returned.
  --friendly-name: string # The string that you assigned to describe the resource.
  --role-sid: string # The SID of a service-level [Role](https://www.twilio.com/docs/conversations/api/role-resource) to assign to the user.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Users/{Sid}"
    path_params: [{name: Sid, var: sid}]
    header: [{name: X-Twilio-Webhook-Enabled, var: x_twilio_webhook_enabled}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Attributes, var: attributes}, {name: FriendlyName, var: friendly_name}, {name: RoleSid, var: role_sid}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    sid: $sid, x_twilio_webhook_enabled: $x_twilio_webhook_enabled, attributes: $attributes, friendly_name: $friendly_name, role_sid: $role_sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of all User Conversations for the User.
#
# GET /v1/Users/{UserSid}/Conversations
# Returns: record<conversations: table<account_sid: string, attributes: string, chat_service_sid: string, conversation_sid: string, conversation_state: string, created_by: string, date_created: string, date_updated: string, friendly_name: string, last_read_message_index: int, links: record, notification_level: string, participant_sid: string, timers: any, unique_name: string, unread_messages_count: int, url: string, user_sid: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListUserConversation
export def "list-user-conversation" [
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
    path: "/v1/Users/{UserSid}/Conversations"
    path_params: [{name: UserSid, var: user_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    user_sid: $user_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a specific User Conversation.
#
# DELETE /v1/Users/{UserSid}/Conversations/{ConversationSid}
# operationId: DeleteUserConversation
export def "delete-user-conversation" [
  user_sid: string
  conversation_sid: string
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
    path: "/v1/Users/{UserSid}/Conversations/{ConversationSid}"
    path_params: [{name: UserSid, var: user_sid}, {name: ConversationSid, var: conversation_sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    user_sid: $user_sid, conversation_sid: $conversation_sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a specific User Conversation.
#
# GET /v1/Users/{UserSid}/Conversations/{ConversationSid}
# Returns: record<account_sid: string, attributes: string, chat_service_sid: string, conversation_sid: string, conversation_state: string, created_by: string, date_created: string, date_updated: string, friendly_name: string, last_read_message_index: int, links: record, notification_level: string, participant_sid: string, timers: any, unique_name: string, unread_messages_count: int, url: string, user_sid: string>
# operationId: FetchUserConversation
export def "fetch-user-conversation" [
  user_sid: string
  conversation_sid: string
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
    path: "/v1/Users/{UserSid}/Conversations/{ConversationSid}"
    path_params: [{name: UserSid, var: user_sid}, {name: ConversationSid, var: conversation_sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    user_sid: $user_sid, conversation_sid: $conversation_sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a specific User Conversation.
#
# POST /v1/Users/{UserSid}/Conversations/{ConversationSid}
# Returns: record<account_sid: string, attributes: string, chat_service_sid: string, conversation_sid: string, conversation_state: string, created_by: string, date_created: string, date_updated: string, friendly_name: string, last_read_message_index: int, links: record, notification_level: string, participant_sid: string, timers: any, unique_name: string, unread_messages_count: int, url: string, user_sid: string>
# operationId: UpdateUserConversation
export def "update-user-conversation" [
  user_sid: string
  conversation_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --last-read-message-index: int # The index of the last Message in the Conversation that the Participant has read. (nullable)
  --last-read-timestamp: string # The date of the last message read in conversation by the user, given in ISO 8601 format. (format: date-time)
  --notification-level: string@notification-level-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Users/{UserSid}/Conversations/{ConversationSid}"
    path_params: [{name: UserSid, var: user_sid}, {name: ConversationSid, var: conversation_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: LastReadMessageIndex, var: last_read_message_index}, {name: LastReadTimestamp, var: last_read_timestamp}, {name: NotificationLevel, var: notification_level}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://conversations.twilio.com"
    auth: basic
  } {
    user_sid: $user_sid, conversation_sid: $conversation_sid, last_read_message_index: $last_read_message_index, last_read_timestamp: $last_read_timestamp, notification_level: $notification_level
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
