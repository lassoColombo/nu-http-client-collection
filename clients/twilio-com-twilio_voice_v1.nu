# Auto-generated client for Twilio - Voice v1.42.0
# Source: https://api.apis.guru/v2/specs/twilio.com/twilio_voice_v1/1.42.0/openapi.json
# Auth: --token flag or $env.TWILIO_VOICE_TOKEN

const CLIENT = {
  base_url: "https://voice.twilio.com"
  token_env_var: "TWILIO_VOICE_TOKEN"
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

def base-url-completer [] { ["https://voice.twilio.com"] }
def auth-scheme-completer [] { ["basic" "basic-credentials"] }

# Completers for enum parameters
def status-callback-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def voice-fallback-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def voice-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    list-byoc-trunk: "record<byoc_trunks: table<account_sid: string, cnam_lookup_enabled: bool, connection_policy_sid: string, date_created: string, date_updated: string, friendly_name: string, from_domain_sid: string, sid: string, status_callback_method: string, status_callback_url: string, url: string, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    create-byoc-trunk: "record<account_sid: string, cnam_lookup_enabled: bool, connection_policy_sid: string, date_created: string, date_updated: string, friendly_name: string, from_domain_sid: string, sid: string, status_callback_method: string, status_callback_url: string, url: string, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_url: string>"
    fetch-byoc-trunk: "record<account_sid: string, cnam_lookup_enabled: bool, connection_policy_sid: string, date_created: string, date_updated: string, friendly_name: string, from_domain_sid: string, sid: string, status_callback_method: string, status_callback_url: string, url: string, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_url: string>"
    update-byoc-trunk: "record<account_sid: string, cnam_lookup_enabled: bool, connection_policy_sid: string, date_created: string, date_updated: string, friendly_name: string, from_domain_sid: string, sid: string, status_callback_method: string, status_callback_url: string, url: string, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_url: string>"
    list-connection-policy: "record<connection_policies: table<account_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    create-connection-policy: "record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, url: string>"
    list-connection-policy-target: "record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, targets: table<account_sid: string, connection_policy_sid: string, date_created: string, date_updated: string, enabled: bool, friendly_name: string, priority: int, sid: string, target: string, url: string, weight: int>>"
    create-connection-policy-target: "record<account_sid: string, connection_policy_sid: string, date_created: string, date_updated: string, enabled: bool, friendly_name: string, priority: int, sid: string, target: string, url: string, weight: int>"
    fetch-connection-policy-target: "record<account_sid: string, connection_policy_sid: string, date_created: string, date_updated: string, enabled: bool, friendly_name: string, priority: int, sid: string, target: string, url: string, weight: int>"
    update-connection-policy-target: "record<account_sid: string, connection_policy_sid: string, date_created: string, date_updated: string, enabled: bool, friendly_name: string, priority: int, sid: string, target: string, url: string, weight: int>"
    fetch-connection-policy: "record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, url: string>"
    update-connection-policy: "record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, url: string>"
    create-dialing-permissions-country-bulk-update: "record<update_count: int, update_request: string>"
    list-dialing-permissions-country: "record<content: table<continent: string, country_codes: list, high_risk_special_numbers_enabled: bool, high_risk_tollfraud_numbers_enabled: bool, iso_code: string, links: record, low_risk_numbers_enabled: bool, name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    fetch-dialing-permissions-country: "record<continent: string, country_codes: list<string>, high_risk_special_numbers_enabled: bool, high_risk_tollfraud_numbers_enabled: bool, iso_code: string, links: record, low_risk_numbers_enabled: bool, name: string, url: string>"
    list-dialing-permissions-hrs-prefixes: "record<content: table<prefix: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    list-ip-record: "record<ip_records: table<account_sid: string, cidr_prefix_length: int, date_created: string, date_updated: string, friendly_name: string, ip_address: string, sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    create-ip-record: "record<account_sid: string, cidr_prefix_length: int, date_created: string, date_updated: string, friendly_name: string, ip_address: string, sid: string, url: string>"
    fetch-ip-record: "record<account_sid: string, cidr_prefix_length: int, date_created: string, date_updated: string, friendly_name: string, ip_address: string, sid: string, url: string>"
    update-ip-record: "record<account_sid: string, cidr_prefix_length: int, date_created: string, date_updated: string, friendly_name: string, ip_address: string, sid: string, url: string>"
    fetch-dialing-permissions-settings: "record<dialing_permissions_inheritance: bool, url: string>"
    update-dialing-permissions-settings: "record<dialing_permissions_inheritance: bool, url: string>"
    list-source-ip-mapping: "record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, source_ip_mappings: table<date_created: string, date_updated: string, ip_record_sid: string, sid: string, sip_domain_sid: string, url: string>>"
    create-source-ip-mapping: "record<date_created: string, date_updated: string, ip_record_sid: string, sid: string, sip_domain_sid: string, url: string>"
    fetch-source-ip-mapping: "record<date_created: string, date_updated: string, ip_record_sid: string, sid: string, sip_domain_sid: string, url: string>"
    update-source-ip-mapping: "record<date_created: string, date_updated: string, ip_record_sid: string, sid: string, sip_domain_sid: string, url: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["delete-archived-call" "list-byoc-trunk" "create-byoc-trunk" "delete-byoc-trunk" "fetch-byoc-trunk" "update-byoc-trunk" "list-connection-policy" "create-connection-policy" "list-connection-policy-target" "create-connection-policy-target" "delete-connection-policy-target" "fetch-connection-policy-target" "update-connection-policy-target" "delete-connection-policy" "fetch-connection-policy" "update-connection-policy" "create-dialing-permissions-country-bulk-update" "list-dialing-permissions-country" "fetch-dialing-permissions-country" "list-dialing-permissions-hrs-prefixes" "list-ip-record" "create-ip-record" "delete-ip-record" "fetch-ip-record" "update-ip-record" "fetch-dialing-permissions-settings" "update-dialing-permissions-settings" "list-source-ip-mapping" "create-source-ip-mapping" "delete-source-ip-mapping" "fetch-source-ip-mapping" "update-source-ip-mapping" "commands"] | sort) } | get name | first)
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

# Delete an archived call record from Bulk Export. Note: this does not also delete the record from the Voice API.
#
# DELETE /v1/Archives/{Date}/Calls/{Sid}
# operationId: DeleteArchivedCall
export def "delete-archived-call" [
  date: string
  sid: string
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
    path: "/v1/Archives/{Date}/Calls/{Sid}"
    path_params: [{name: Date, var: date}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://voice.twilio.com"
    auth: basic
  } {
    date: $date, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/ByocTrunks
#
# Returns: record<byoc_trunks: table<account_sid: string, cnam_lookup_enabled: bool, connection_policy_sid: string, date_created: string, date_updated: string, friendly_name: string, from_domain_sid: string, sid: string, status_callback_method: string, status_callback_url: string, url: string, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListByocTrunk
export def "list-byoc-trunk" [
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
    path: "/v1/ByocTrunks"
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://voice.twilio.com"
    auth: basic
  } {
    page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/ByocTrunks
#
# Returns: record<account_sid: string, cnam_lookup_enabled: bool, connection_policy_sid: string, date_created: string, date_updated: string, friendly_name: string, from_domain_sid: string, sid: string, status_callback_method: string, status_callback_url: string, url: string, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_url: string>
# operationId: CreateByocTrunk
export def "create-byoc-trunk" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cnam-lookup-enabled: oneof<nothing, bool> # Whether Caller ID Name (CNAM) lookup is enabled for the trunk. If enabled, all inbound calls to the BYOC Trunk from the United States and Canada automatically perform a CNAM Lookup and display Caller ID data on your phone. See [CNAM Lookups](https://www.twilio.com/docs/sip-trunking#CNAM) for more information.
  --connection-policy-sid: string # The SID of the Connection Policy that Twilio will use when routing traffic to your communications infrastructure.
  --friendly-name: string # A descriptive string that you create to describe the resource. It is not unique and can be up to 255 characters long.
  --from-domain-sid: string # The SID of the SIP Domain that should be used in the `From` header of originating calls sent to your SIP infrastructure. If your SIP infrastructure allows users to "call back" an incoming call, configure this with a [SIP Domain](https://www.twilio.com/docs/voice/api/sending-sip) to ensure proper routing. If not configured, the from domain will default to "sip.twilio.com".
  --status-callback-method: string@status-callback-method-completer # The HTTP method we should use to call `status_callback_url`. Can be: `GET` or `POST`. (format: http-method)
  --status-callback-url: string # The URL that we should call to pass status parameters (such as call ended) to your application. (format: uri)
  --voice-fallback-method: string@voice-fallback-method-completer # The HTTP method we should use to call `voice_fallback_url`. Can be: `GET` or `POST`. (format: http-method)
  --voice-fallback-url: string # The URL that we should call when an error occurs while retrieving or executing the TwiML from `voice_url`. (format: uri)
  --voice-method: string@voice-method-completer # The HTTP method we should use to call `voice_url`. Can be: `GET` or `POST`. (format: http-method)
  --voice-url: string # The URL we should call when the BYOC Trunk receives a call. (format: uri)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/ByocTrunks"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: CnamLookupEnabled, var: cnam_lookup_enabled}, {name: ConnectionPolicySid, var: connection_policy_sid}, {name: FriendlyName, var: friendly_name}, {name: FromDomainSid, var: from_domain_sid}, {name: StatusCallbackMethod, var: status_callback_method}, {name: StatusCallbackUrl, var: status_callback_url}, {name: VoiceFallbackMethod, var: voice_fallback_method}, {name: VoiceFallbackUrl, var: voice_fallback_url}, {name: VoiceMethod, var: voice_method}, {name: VoiceUrl, var: voice_url}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://voice.twilio.com"
    auth: basic
  } {
    cnam_lookup_enabled: $cnam_lookup_enabled, connection_policy_sid: $connection_policy_sid, friendly_name: $friendly_name, from_domain_sid: $from_domain_sid, status_callback_method: $status_callback_method, status_callback_url: $status_callback_url, voice_fallback_method: $voice_fallback_method, voice_fallback_url: $voice_fallback_url, voice_method: $voice_method, voice_url: $voice_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/ByocTrunks/{Sid}
#
# operationId: DeleteByocTrunk
export def "delete-byoc-trunk" [
  sid: string
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
    path: "/v1/ByocTrunks/{Sid}"
    path_params: [{name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://voice.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/ByocTrunks/{Sid}
#
# Returns: record<account_sid: string, cnam_lookup_enabled: bool, connection_policy_sid: string, date_created: string, date_updated: string, friendly_name: string, from_domain_sid: string, sid: string, status_callback_method: string, status_callback_url: string, url: string, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_url: string>
# operationId: FetchByocTrunk
export def "fetch-byoc-trunk" [
  sid: string
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
    path: "/v1/ByocTrunks/{Sid}"
    path_params: [{name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://voice.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/ByocTrunks/{Sid}
#
# Returns: record<account_sid: string, cnam_lookup_enabled: bool, connection_policy_sid: string, date_created: string, date_updated: string, friendly_name: string, from_domain_sid: string, sid: string, status_callback_method: string, status_callback_url: string, url: string, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_url: string>
# operationId: UpdateByocTrunk
export def "update-byoc-trunk" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cnam-lookup-enabled: oneof<nothing, bool> # Whether Caller ID Name (CNAM) lookup is enabled for the trunk. If enabled, all inbound calls to the BYOC Trunk from the United States and Canada automatically perform a CNAM Lookup and display Caller ID data on your phone. See [CNAM Lookups](https://www.twilio.com/docs/sip-trunking#CNAM) for more information.
  --connection-policy-sid: string # The SID of the Connection Policy that Twilio will use when routing traffic to your communications infrastructure.
  --friendly-name: string # A descriptive string that you create to describe the resource. It is not unique and can be up to 255 characters long.
  --from-domain-sid: string # The SID of the SIP Domain that should be used in the `From` header of originating calls sent to your SIP infrastructure. If your SIP infrastructure allows users to "call back" an incoming call, configure this with a [SIP Domain](https://www.twilio.com/docs/voice/api/sending-sip) to ensure proper routing. If not configured, the from domain will default to "sip.twilio.com".
  --status-callback-method: string@status-callback-method-completer # The HTTP method we should use to call `status_callback_url`. Can be: `GET` or `POST`. (format: http-method)
  --status-callback-url: string # The URL that we should call to pass status parameters (such as call ended) to your application. (format: uri)
  --voice-fallback-method: string@voice-fallback-method-completer # The HTTP method we should use to call `voice_fallback_url`. Can be: `GET` or `POST`. (format: http-method)
  --voice-fallback-url: string # The URL that we should call when an error occurs while retrieving or executing the TwiML requested by `voice_url`. (format: uri)
  --voice-method: string@voice-method-completer # The HTTP method we should use to call `voice_url` (format: http-method)
  --voice-url: string # The URL we should call when the BYOC Trunk receives a call. (format: uri)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/ByocTrunks/{Sid}"
    path_params: [{name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: CnamLookupEnabled, var: cnam_lookup_enabled}, {name: ConnectionPolicySid, var: connection_policy_sid}, {name: FriendlyName, var: friendly_name}, {name: FromDomainSid, var: from_domain_sid}, {name: StatusCallbackMethod, var: status_callback_method}, {name: StatusCallbackUrl, var: status_callback_url}, {name: VoiceFallbackMethod, var: voice_fallback_method}, {name: VoiceFallbackUrl, var: voice_fallback_url}, {name: VoiceMethod, var: voice_method}, {name: VoiceUrl, var: voice_url}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://voice.twilio.com"
    auth: basic
  } {
    sid: $sid, cnam_lookup_enabled: $cnam_lookup_enabled, connection_policy_sid: $connection_policy_sid, friendly_name: $friendly_name, from_domain_sid: $from_domain_sid, status_callback_method: $status_callback_method, status_callback_url: $status_callback_url, voice_fallback_method: $voice_fallback_method, voice_fallback_url: $voice_fallback_url, voice_method: $voice_method, voice_url: $voice_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/ConnectionPolicies
#
# Returns: record<connection_policies: table<account_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListConnectionPolicy
export def "list-connection-policy" [
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
    path: "/v1/ConnectionPolicies"
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://voice.twilio.com"
    auth: basic
  } {
    page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/ConnectionPolicies
#
# Returns: record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, url: string>
# operationId: CreateConnectionPolicy
export def "create-connection-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --friendly-name: string # A descriptive string that you create to describe the resource. It is not unique and can be up to 255 characters long.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/ConnectionPolicies"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: FriendlyName, var: friendly_name}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://voice.twilio.com"
    auth: basic
  } {
    friendly_name: $friendly_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/ConnectionPolicies/{ConnectionPolicySid}/Targets
#
# Returns: record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, targets: table<account_sid: string, connection_policy_sid: string, date_created: string, date_updated: string, enabled: bool, friendly_name: string, priority: int, sid: string, target: string, url: string, weight: int>>
# operationId: ListConnectionPolicyTarget
export def "list-connection-policy-target" [
  connection_policy_sid: string
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
    path: "/v1/ConnectionPolicies/{ConnectionPolicySid}/Targets"
    path_params: [{name: ConnectionPolicySid, var: connection_policy_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://voice.twilio.com"
    auth: basic
  } {
    connection_policy_sid: $connection_policy_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/ConnectionPolicies/{ConnectionPolicySid}/Targets
#
# Returns: record<account_sid: string, connection_policy_sid: string, date_created: string, date_updated: string, enabled: bool, friendly_name: string, priority: int, sid: string, target: string, url: string, weight: int>
# operationId: CreateConnectionPolicyTarget
export def "create-connection-policy-target" [
  connection_policy_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool> # Whether the Target is enabled. The default is `true`.
  --friendly-name: string # A descriptive string that you create to describe the resource. It is not unique and can be up to 255 characters long.
  --priority: int # The relative importance of the target. Can be an integer from 0 to 65535, inclusive, and the default is 10. The lowest number represents the most important target.
  target: string # The SIP address you want Twilio to route your calls to. This must be a `sip:` schema. `sips` is NOT supported. (format: uri)
  --weight: int # The value that determines the relative share of the load the Target should receive compared to other Targets with the same priority. Can be an integer from 1 to 65535, inclusive, and the default is 10. Targets with higher values receive more load than those with lower ones with the same priority.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/ConnectionPolicies/{ConnectionPolicySid}/Targets"
    path_params: [{name: ConnectionPolicySid, var: connection_policy_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Enabled, var: enabled}, {name: FriendlyName, var: friendly_name}, {name: Priority, var: priority}, {name: Target, var: target}, {name: Weight, var: weight}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://voice.twilio.com"
    auth: basic
  } {
    connection_policy_sid: $connection_policy_sid, enabled: $enabled, friendly_name: $friendly_name, priority: $priority, target: $target, weight: $weight
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/ConnectionPolicies/{ConnectionPolicySid}/Targets/{Sid}
#
# operationId: DeleteConnectionPolicyTarget
export def "delete-connection-policy-target" [
  connection_policy_sid: string
  sid: string
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
    path: "/v1/ConnectionPolicies/{ConnectionPolicySid}/Targets/{Sid}"
    path_params: [{name: ConnectionPolicySid, var: connection_policy_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://voice.twilio.com"
    auth: basic
  } {
    connection_policy_sid: $connection_policy_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/ConnectionPolicies/{ConnectionPolicySid}/Targets/{Sid}
#
# Returns: record<account_sid: string, connection_policy_sid: string, date_created: string, date_updated: string, enabled: bool, friendly_name: string, priority: int, sid: string, target: string, url: string, weight: int>
# operationId: FetchConnectionPolicyTarget
export def "fetch-connection-policy-target" [
  connection_policy_sid: string
  sid: string
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
    path: "/v1/ConnectionPolicies/{ConnectionPolicySid}/Targets/{Sid}"
    path_params: [{name: ConnectionPolicySid, var: connection_policy_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://voice.twilio.com"
    auth: basic
  } {
    connection_policy_sid: $connection_policy_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/ConnectionPolicies/{ConnectionPolicySid}/Targets/{Sid}
#
# Returns: record<account_sid: string, connection_policy_sid: string, date_created: string, date_updated: string, enabled: bool, friendly_name: string, priority: int, sid: string, target: string, url: string, weight: int>
# operationId: UpdateConnectionPolicyTarget
export def "update-connection-policy-target" [
  connection_policy_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool> # Whether the Target is enabled.
  --friendly-name: string # A descriptive string that you create to describe the resource. It is not unique and can be up to 255 characters long.
  --priority: int # The relative importance of the target. Can be an integer from 0 to 65535, inclusive. The lowest number represents the most important target.
  --target: string # The SIP address you want Twilio to route your calls to. This must be a `sip:` schema. `sips` is NOT supported. (format: uri)
  --weight: int # The value that determines the relative share of the load the Target should receive compared to other Targets with the same priority. Can be an integer from 1 to 65535, inclusive. Targets with higher values receive more load than those with lower ones with the same priority.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/ConnectionPolicies/{ConnectionPolicySid}/Targets/{Sid}"
    path_params: [{name: ConnectionPolicySid, var: connection_policy_sid}, {name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Enabled, var: enabled}, {name: FriendlyName, var: friendly_name}, {name: Priority, var: priority}, {name: Target, var: target}, {name: Weight, var: weight}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://voice.twilio.com"
    auth: basic
  } {
    connection_policy_sid: $connection_policy_sid, sid: $sid, enabled: $enabled, friendly_name: $friendly_name, priority: $priority, target: $target, weight: $weight
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/ConnectionPolicies/{Sid}
#
# operationId: DeleteConnectionPolicy
export def "delete-connection-policy" [
  sid: string
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
    path: "/v1/ConnectionPolicies/{Sid}"
    path_params: [{name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://voice.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/ConnectionPolicies/{Sid}
#
# Returns: record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, url: string>
# operationId: FetchConnectionPolicy
export def "fetch-connection-policy" [
  sid: string
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
    path: "/v1/ConnectionPolicies/{Sid}"
    path_params: [{name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://voice.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/ConnectionPolicies/{Sid}
#
# Returns: record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, url: string>
# operationId: UpdateConnectionPolicy
export def "update-connection-policy" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --friendly-name: string # A descriptive string that you create to describe the resource. It is not unique and can be up to 255 characters long.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/ConnectionPolicies/{Sid}"
    path_params: [{name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: FriendlyName, var: friendly_name}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://voice.twilio.com"
    auth: basic
  } {
    sid: $sid, friendly_name: $friendly_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a bulk update request to change voice dialing country permissions of one or more countries identified by the corresponding [ISO country code](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)
#
# POST /v1/DialingPermissions/BulkCountryUpdates
# Returns: record<update_count: int, update_request: string>
# operationId: CreateDialingPermissionsCountryBulkUpdate
export def "create-dialing-permissions-country-bulk-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  update_request: string # URL encoded JSON array of update objects. example : `[ { "iso_code": "GB", "low_risk_numbers_enabled": "true", "high_risk_special_numbers_enabled":"true", "high_risk_tollfraud_numbers_enabled": "false" } ]`
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/DialingPermissions/BulkCountryUpdates"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: UpdateRequest, var: update_request}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://voice.twilio.com"
    auth: basic
  } {
    update_request: $update_request
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all voice dialing country permissions for this account
#
# GET /v1/DialingPermissions/Countries
# Returns: record<content: table<continent: string, country_codes: list, high_risk_special_numbers_enabled: bool, high_risk_tollfraud_numbers_enabled: bool, iso_code: string, links: record, low_risk_numbers_enabled: bool, name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListDialingPermissionsCountry
export def "list-dialing-permissions-country" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --iso-code: string # Filter to retrieve the country permissions by specifying the [ISO country code](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2) (format: iso-country-code)
  --continent: string # Filter to retrieve the country permissions by specifying the continent
  --country-code: string # Filter the results by specified [country codes](https://www.itu.int/itudoc/itu-t/ob-lists/icc/e164_763.html)
  --low-risk-numbers-enabled: oneof<nothing, bool> # Filter to retrieve the country permissions with dialing to low-risk numbers enabled. Can be: `true` or `false`.
  --high-risk-special-numbers-enabled: oneof<nothing, bool> # Filter to retrieve the country permissions with dialing to high-risk special service numbers enabled. Can be: `true` or `false`
  --high-risk-tollfraud-numbers-enabled: oneof<nothing, bool> # Filter to retrieve the country permissions with dialing to high-risk [toll fraud](https://www.twilio.com/learn/voice-and-video/toll-fraud) numbers enabled. Can be: `true` or `false`.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/DialingPermissions/Countries"
    query: [{name: IsoCode, var: iso_code}, {name: Continent, var: continent}, {name: CountryCode, var: country_code}, {name: LowRiskNumbersEnabled, var: low_risk_numbers_enabled}, {name: HighRiskSpecialNumbersEnabled, var: high_risk_special_numbers_enabled}, {name: HighRiskTollfraudNumbersEnabled, var: high_risk_tollfraud_numbers_enabled}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://voice.twilio.com"
    auth: basic
  } {
    iso_code: $iso_code, continent: $continent, country_code: $country_code, low_risk_numbers_enabled: $low_risk_numbers_enabled, high_risk_special_numbers_enabled: $high_risk_special_numbers_enabled, high_risk_tollfraud_numbers_enabled: $high_risk_tollfraud_numbers_enabled, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve voice dialing country permissions identified by the given ISO country code
#
# GET /v1/DialingPermissions/Countries/{IsoCode}
# Returns: record<continent: string, country_codes: list<string>, high_risk_special_numbers_enabled: bool, high_risk_tollfraud_numbers_enabled: bool, iso_code: string, links: record, low_risk_numbers_enabled: bool, name: string, url: string>
# operationId: FetchDialingPermissionsCountry
export def "fetch-dialing-permissions-country" [
  iso_code: string
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
    path: "/v1/DialingPermissions/Countries/{IsoCode}"
    path_params: [{name: IsoCode, var: iso_code}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://voice.twilio.com"
    auth: basic
  } {
    iso_code: $iso_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch the high-risk special services prefixes from the country resource corresponding to the [ISO country code](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)
#
# GET /v1/DialingPermissions/Countries/{IsoCode}/HighRiskSpecialPrefixes
# Returns: record<content: table<prefix: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListDialingPermissionsHrsPrefixes
export def "list-dialing-permissions-hrs-prefixes" [
  iso_code: string
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
    path: "/v1/DialingPermissions/Countries/{IsoCode}/HighRiskSpecialPrefixes"
    path_params: [{name: IsoCode, var: iso_code}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://voice.twilio.com"
    auth: basic
  } {
    iso_code: $iso_code, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/IpRecords
#
# Returns: record<ip_records: table<account_sid: string, cidr_prefix_length: int, date_created: string, date_updated: string, friendly_name: string, ip_address: string, sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListIpRecord
export def "list-ip-record" [
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
    path: "/v1/IpRecords"
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://voice.twilio.com"
    auth: basic
  } {
    page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/IpRecords
#
# Returns: record<account_sid: string, cidr_prefix_length: int, date_created: string, date_updated: string, friendly_name: string, ip_address: string, sid: string, url: string>
# operationId: CreateIpRecord
export def "create-ip-record" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cidr-prefix-length: int # An integer representing the length of the [CIDR](https://tools.ietf.org/html/rfc4632) prefix to use with this IP address. By default the entire IP address is used, which for IPv4 is value 32.
  --friendly-name: string # A descriptive string that you create to describe the resource. It is not unique and can be up to 255 characters long.
  ip_address: string # An IP address in dotted decimal notation, IPv4 only.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/IpRecords"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: CidrPrefixLength, var: cidr_prefix_length}, {name: FriendlyName, var: friendly_name}, {name: IpAddress, var: ip_address}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://voice.twilio.com"
    auth: basic
  } {
    cidr_prefix_length: $cidr_prefix_length, friendly_name: $friendly_name, ip_address: $ip_address
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/IpRecords/{Sid}
#
# operationId: DeleteIpRecord
export def "delete-ip-record" [
  sid: string
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
    path: "/v1/IpRecords/{Sid}"
    path_params: [{name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://voice.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/IpRecords/{Sid}
#
# Returns: record<account_sid: string, cidr_prefix_length: int, date_created: string, date_updated: string, friendly_name: string, ip_address: string, sid: string, url: string>
# operationId: FetchIpRecord
export def "fetch-ip-record" [
  sid: string
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
    path: "/v1/IpRecords/{Sid}"
    path_params: [{name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://voice.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/IpRecords/{Sid}
#
# Returns: record<account_sid: string, cidr_prefix_length: int, date_created: string, date_updated: string, friendly_name: string, ip_address: string, sid: string, url: string>
# operationId: UpdateIpRecord
export def "update-ip-record" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --friendly-name: string # A descriptive string that you create to describe the resource. It is not unique and can be up to 255 characters long.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/IpRecords/{Sid}"
    path_params: [{name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: FriendlyName, var: friendly_name}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://voice.twilio.com"
    auth: basic
  } {
    sid: $sid, friendly_name: $friendly_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve voice dialing permissions inheritance for the sub-account
#
# GET /v1/Settings
# Returns: record<dialing_permissions_inheritance: bool, url: string>
# operationId: FetchDialingPermissionsSettings
export def "fetch-dialing-permissions-settings" [
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
    path: "/v1/Settings"
    accept: ["application/json"]
    ok: [200]
    base_url: "https://voice.twilio.com"
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update voice dialing permissions inheritance for the sub-account
#
# POST /v1/Settings
# Returns: record<dialing_permissions_inheritance: bool, url: string>
# operationId: UpdateDialingPermissionsSettings
export def "update-dialing-permissions-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --dialing-permissions-inheritance: oneof<nothing, bool> # `true` for the sub-account to inherit voice dialing permissions from the Master Project; otherwise `false`.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Settings"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: DialingPermissionsInheritance, var: dialing_permissions_inheritance}]}
    accept: ["application/json"]
    ok: [202]
    base_url: "https://voice.twilio.com"
    auth: basic
  } {
    dialing_permissions_inheritance: $dialing_permissions_inheritance
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/SourceIpMappings
#
# Returns: record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, source_ip_mappings: table<date_created: string, date_updated: string, ip_record_sid: string, sid: string, sip_domain_sid: string, url: string>>
# operationId: ListSourceIpMapping
export def "list-source-ip-mapping" [
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
    path: "/v1/SourceIpMappings"
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://voice.twilio.com"
    auth: basic
  } {
    page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/SourceIpMappings
#
# Returns: record<date_created: string, date_updated: string, ip_record_sid: string, sid: string, sip_domain_sid: string, url: string>
# operationId: CreateSourceIpMapping
export def "create-source-ip-mapping" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  ip_record_sid: string # The Twilio-provided string that uniquely identifies the IP Record resource to map from.
  sip_domain_sid: string # The SID of the SIP Domain that the IP Record should be mapped to.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/SourceIpMappings"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: IpRecordSid, var: ip_record_sid}, {name: SipDomainSid, var: sip_domain_sid}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://voice.twilio.com"
    auth: basic
  } {
    ip_record_sid: $ip_record_sid, sip_domain_sid: $sip_domain_sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/SourceIpMappings/{Sid}
#
# operationId: DeleteSourceIpMapping
export def "delete-source-ip-mapping" [
  sid: string
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
    path: "/v1/SourceIpMappings/{Sid}"
    path_params: [{name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://voice.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/SourceIpMappings/{Sid}
#
# Returns: record<date_created: string, date_updated: string, ip_record_sid: string, sid: string, sip_domain_sid: string, url: string>
# operationId: FetchSourceIpMapping
export def "fetch-source-ip-mapping" [
  sid: string
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
    path: "/v1/SourceIpMappings/{Sid}"
    path_params: [{name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://voice.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/SourceIpMappings/{Sid}
#
# Returns: record<date_created: string, date_updated: string, ip_record_sid: string, sid: string, sip_domain_sid: string, url: string>
# operationId: UpdateSourceIpMapping
export def "update-source-ip-mapping" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  sip_domain_sid: string # The SID of the SIP Domain that the IP Record should be mapped to.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/SourceIpMappings/{Sid}"
    path_params: [{name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: SipDomainSid, var: sip_domain_sid}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://voice.twilio.com"
    auth: basic
  } {
    sid: $sid, sip_domain_sid: $sip_domain_sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
