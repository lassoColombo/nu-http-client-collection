# Auto-generated client for Twilio - Supersim v1.42.0
# Source: https://api.apis.guru/v2/specs/twilio.com/twilio_supersim_v1/1.42.0/openapi.json
# Auth: --token flag or $env.TWILIO_SUPERSIM_TOKEN

const CLIENT = {
  base_url: "https://supersim.twilio.com"
  token_env_var: "TWILIO_SUPERSIM_TOKEN"
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

def base-url-completer [] { ["https://supersim.twilio.com"] }
def auth-scheme-completer [] { ["basic" "basic-credentials"] }

# Completers for enum parameters
def status-completer [] { ["available" "downloaded" "failed" "installed" "new" "reserving"] }
def callback-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def ip-commands-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def sms-commands-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def status-completer-1 [] { ["failed" "queued" "received" "sent"] }
def direction-completer [] { ["from_sim" "to_sim"] }
def payload-type-completer [] { ["binary" "text"] }
def status-completer-2 [] { ["failed" "in-progress" "scheduled" "successful"] }
def status-completer-3 [] { ["active" "inactive" "new" "ready" "scheduled"] }
def status-completer-4 [] { ["active" "inactive" "ready"] }
def status-completer-5 [] { ["delivered" "failed" "queued" "received" "sent"] }
def group-completer [] { ["fleet" "isoCountry" "network" "sim"] }
def granularity-completer [] { ["all" "day" "hour"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    list-esim-profile: "record<esim_profiles: table<account_sid: string, activation_code: string, date_created: string, date_updated: string, eid: string, error_code: string, error_message: string, iccid: string, matching_id: string, sid: string, sim_sid: string, smdp_plus_address: string, status: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    create-esim-profile: "record<account_sid: string, activation_code: string, date_created: string, date_updated: string, eid: string, error_code: string, error_message: string, iccid: string, matching_id: string, sid: string, sim_sid: string, smdp_plus_address: string, status: string, url: string>"
    fetch-esim-profile: "record<account_sid: string, activation_code: string, date_created: string, date_updated: string, eid: string, error_code: string, error_message: string, iccid: string, matching_id: string, sid: string, sim_sid: string, smdp_plus_address: string, status: string, url: string>"
    list-fleet: "record<fleets: table<account_sid: string, data_enabled: bool, data_limit: int, data_metering: string, date_created: string, date_updated: string, ip_commands_method: string, ip_commands_url: string, network_access_profile_sid: string, sid: string, sms_commands_enabled: bool, sms_commands_method: string, sms_commands_url: string, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    create-fleet: "record<account_sid: string, data_enabled: bool, data_limit: int, data_metering: string, date_created: string, date_updated: string, ip_commands_method: string, ip_commands_url: string, network_access_profile_sid: string, sid: string, sms_commands_enabled: bool, sms_commands_method: string, sms_commands_url: string, unique_name: string, url: string>"
    fetch-fleet: "record<account_sid: string, data_enabled: bool, data_limit: int, data_metering: string, date_created: string, date_updated: string, ip_commands_method: string, ip_commands_url: string, network_access_profile_sid: string, sid: string, sms_commands_enabled: bool, sms_commands_method: string, sms_commands_url: string, unique_name: string, url: string>"
    update-fleet: "record<account_sid: string, data_enabled: bool, data_limit: int, data_metering: string, date_created: string, date_updated: string, ip_commands_method: string, ip_commands_url: string, network_access_profile_sid: string, sid: string, sms_commands_enabled: bool, sms_commands_method: string, sms_commands_url: string, unique_name: string, url: string>"
    list-ip-command: "record<ip_commands: table<account_sid: string, date_created: string, date_updated: string, device_ip: string, device_port: int, direction: string, payload: string, payload_type: string, sid: string, sim_iccid: string, sim_sid: string, status: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    create-ip-command: "record<account_sid: string, date_created: string, date_updated: string, device_ip: string, device_port: int, direction: string, payload: string, payload_type: string, sid: string, sim_iccid: string, sim_sid: string, status: string, url: string>"
    fetch-ip-command: "record<account_sid: string, date_created: string, date_updated: string, device_ip: string, device_port: int, direction: string, payload: string, payload_type: string, sid: string, sim_iccid: string, sim_sid: string, status: string, url: string>"
    list-network-access-profile: "record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, network_access_profiles: table<account_sid: string, date_created: string, date_updated: string, links: record, sid: string, unique_name: string, url: string>>"
    create-network-access-profile: "record<account_sid: string, date_created: string, date_updated: string, links: record, sid: string, unique_name: string, url: string>"
    list-network-access-profile-network: "record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, networks: table<friendly_name: string, identifiers: list, iso_country: string, network_access_profile_sid: string, sid: string, url: string>>"
    create-network-access-profile-network: "record<friendly_name: string, identifiers: list<any>, iso_country: string, network_access_profile_sid: string, sid: string, url: string>"
    fetch-network-access-profile-network: "record<friendly_name: string, identifiers: list<any>, iso_country: string, network_access_profile_sid: string, sid: string, url: string>"
    fetch-network-access-profile: "record<account_sid: string, date_created: string, date_updated: string, links: record, sid: string, unique_name: string, url: string>"
    update-network-access-profile: "record<account_sid: string, date_created: string, date_updated: string, links: record, sid: string, unique_name: string, url: string>"
    list-network: "record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, networks: table<friendly_name: string, identifiers: list, iso_country: string, sid: string, url: string>>"
    fetch-network: "record<friendly_name: string, identifiers: list<any>, iso_country: string, sid: string, url: string>"
    list-settings-update: "record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, settings_updates: table<date_completed: string, date_created: string, date_updated: string, iccid: string, packages: list, sid: string, sim_sid: string, status: string>>"
    list-sim: "record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, sims: table<account_sid: string, date_created: string, date_updated: string, fleet_sid: string, iccid: string, links: record, sid: string, status: string, unique_name: string, url: string>>"
    create-sim: "record<account_sid: string, date_created: string, date_updated: string, fleet_sid: string, iccid: string, links: record, sid: string, status: string, unique_name: string, url: string>"
    fetch-sim: "record<account_sid: string, date_created: string, date_updated: string, fleet_sid: string, iccid: string, links: record, sid: string, status: string, unique_name: string, url: string>"
    update-sim: "record<account_sid: string, date_created: string, date_updated: string, fleet_sid: string, iccid: string, links: record, sid: string, status: string, unique_name: string, url: string>"
    list-billing-period: "record<billing_periods: table<account_sid: string, date_created: string, date_updated: string, end_time: string, period_type: string, sid: string, sim_sid: string, start_time: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    list-sim-ip-address: "record<ip_addresses: table<ip_address: string, ip_address_version: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>"
    list-sms-command: "record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, sms_commands: table<account_sid: string, date_created: string, date_updated: string, direction: string, payload: string, sid: string, sim_sid: string, status: string, url: string>>"
    create-sms-command: "record<account_sid: string, date_created: string, date_updated: string, direction: string, payload: string, sid: string, sim_sid: string, status: string, url: string>"
    fetch-sms-command: "record<account_sid: string, date_created: string, date_updated: string, direction: string, payload: string, sid: string, sim_sid: string, status: string, url: string>"
    list-usage-record: "record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, usage_records: table<account_sid: string, billed_unit: string, data_download: int, data_total: int, data_total_billed: float, data_upload: int, fleet_sid: string, iso_country: string, network_sid: string, period: any, sim_sid: string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["list-esim-profile" "create-esim-profile" "fetch-esim-profile" "list-fleet" "create-fleet" "fetch-fleet" "update-fleet" "list-ip-command" "create-ip-command" "fetch-ip-command" "list-network-access-profile" "create-network-access-profile" "list-network-access-profile-network" "create-network-access-profile-network" "delete-network-access-profile-network" "fetch-network-access-profile-network" "fetch-network-access-profile" "update-network-access-profile" "list-network" "fetch-network" "list-settings-update" "list-sim" "create-sim" "fetch-sim" "update-sim" "list-billing-period" "list-sim-ip-address" "list-sms-command" "create-sms-command" "fetch-sms-command" "list-usage-record" "commands"] | sort) } | get name | first)
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

# Retrieve a list of eSIM Profiles.
#
# GET /v1/ESimProfiles
# Returns: record<esim_profiles: table<account_sid: string, activation_code: string, date_created: string, date_updated: string, eid: string, error_code: string, error_message: string, iccid: string, matching_id: string, sid: string, sim_sid: string, smdp_plus_address: string, status: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListEsimProfile
export def "list-esim-profile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --eid: string # List the eSIM Profiles that have been associated with an EId.
  --sim-sid: string # Find the eSIM Profile resource related to a [Sim](https://www.twilio.com/docs/wireless/api/sim-resource) resource by providing the SIM SID. Will always return an array with either 1 or 0 records.
  --status: string@status-completer # List the eSIM Profiles that are in a given status.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/ESimProfiles"
    query: [{name: Eid, var: eid}, {name: SimSid, var: sim_sid}, {name: Status, var: status}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://supersim.twilio.com"
    auth: basic
  } {
    eid: $eid, sim_sid: $sim_sid, status: $status, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Order an eSIM Profile.
#
# POST /v1/ESimProfiles
# Returns: record<account_sid: string, activation_code: string, date_created: string, date_updated: string, eid: string, error_code: string, error_message: string, iccid: string, matching_id: string, sid: string, sim_sid: string, smdp_plus_address: string, status: string, url: string>
# operationId: CreateEsimProfile
export def "create-esim-profile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --callback-method: string@callback-method-completer # The HTTP method we should use to call `callback_url`. Can be: `GET` or `POST` and the default is POST. (format: http-method)
  --callback-url: string # The URL we should call using the `callback_method` when the status of the eSIM Profile changes. At this stage of the eSIM Profile pilot, the a request to the URL will only be called when the ESimProfile resource changes from `reserving` to `available`.
  --eid: string # Identifier of the eUICC that will claim the eSIM Profile.
  --generate-matching-id: oneof<nothing, bool> # When set to `true`, a value for `Eid` does not need to be provided. Instead, when the eSIM profile is reserved, a matching ID will be generated and returned via the `matching_id` property. This identifies the specific eSIM profile that can be used by any capable device to claim and download the profile.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/ESimProfiles"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: CallbackMethod, var: callback_method}, {name: CallbackUrl, var: callback_url}, {name: Eid, var: eid}, {name: GenerateMatchingId, var: generate_matching_id}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://supersim.twilio.com"
    auth: basic
  } {
    callback_method: $callback_method, callback_url: $callback_url, eid: $eid, generate_matching_id: $generate_matching_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch an eSIM Profile.
#
# GET /v1/ESimProfiles/{Sid}
# Returns: record<account_sid: string, activation_code: string, date_created: string, date_updated: string, eid: string, error_code: string, error_message: string, iccid: string, matching_id: string, sid: string, sim_sid: string, smdp_plus_address: string, status: string, url: string>
# operationId: FetchEsimProfile
export def "fetch-esim-profile" [
  sid: string
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
    path: "/v1/ESimProfiles/{Sid}"
    path_params: [{name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://supersim.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of Fleets from your account.
#
# GET /v1/Fleets
# Returns: record<fleets: table<account_sid: string, data_enabled: bool, data_limit: int, data_metering: string, date_created: string, date_updated: string, ip_commands_method: string, ip_commands_url: string, network_access_profile_sid: string, sid: string, sms_commands_enabled: bool, sms_commands_method: string, sms_commands_url: string, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListFleet
export def "list-fleet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --network-access-profile: string # The SID or unique name of the Network Access Profile that controls which cellular networks the Fleet's SIMs can connect to.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/Fleets"
    query: [{name: NetworkAccessProfile, var: network_access_profile}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://supersim.twilio.com"
    auth: basic
  } {
    network_access_profile: $network_access_profile, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a Fleet
#
# POST /v1/Fleets
# Returns: record<account_sid: string, data_enabled: bool, data_limit: int, data_metering: string, date_created: string, date_updated: string, ip_commands_method: string, ip_commands_url: string, network_access_profile_sid: string, sid: string, sms_commands_enabled: bool, sms_commands_method: string, sms_commands_url: string, unique_name: string, url: string>
# operationId: CreateFleet
export def "create-fleet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --data-enabled: oneof<nothing, bool> # Defines whether SIMs in the Fleet are capable of using 2G/3G/4G/LTE/CAT-M data connectivity. Defaults to `true`.
  --data-limit: int # The total data usage (download and upload combined) in Megabytes that each Super SIM assigned to the Fleet can consume during a billing period (normally one month). Value must be between 1MB (1) and 2TB (2,000,000). Defaults to 1GB (1,000).
  --ip-commands-method: string@ip-commands-method-completer # A string representing the HTTP method to use when making a request to `ip_commands_url`. Can be one of `POST` or `GET`. Defaults to `POST`. (format: http-method)
  --ip-commands-url: string # The URL that will receive a webhook when a Super SIM in the Fleet is used to send an IP Command from your device to a special IP address. Your server should respond with an HTTP status code in the 200 range; any response body will be ignored. (format: uri)
  network_access_profile: string # The SID or unique name of the Network Access Profile that will control which cellular networks the Fleet's SIMs can connect to.
  --sms-commands-enabled: oneof<nothing, bool> # Defines whether SIMs in the Fleet are capable of sending and receiving machine-to-machine SMS via Commands. Defaults to `true`.
  --sms-commands-method: string@sms-commands-method-completer # A string representing the HTTP method to use when making a request to `sms_commands_url`. Can be one of `POST` or `GET`. Defaults to `POST`. (format: http-method)
  --sms-commands-url: string # The URL that will receive a webhook when a Super SIM in the Fleet is used to send an SMS from your device to the SMS Commands number. Your server should respond with an HTTP status code in the 200 range; any response body will be ignored. (format: uri)
  --unique-name: string # An application-defined string that uniquely identifies the resource. It can be used in place of the resource's `sid` in the URL to address the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Fleets"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: DataEnabled, var: data_enabled}, {name: DataLimit, var: data_limit}, {name: IpCommandsMethod, var: ip_commands_method}, {name: IpCommandsUrl, var: ip_commands_url}, {name: NetworkAccessProfile, var: network_access_profile}, {name: SmsCommandsEnabled, var: sms_commands_enabled}, {name: SmsCommandsMethod, var: sms_commands_method}, {name: SmsCommandsUrl, var: sms_commands_url}, {name: UniqueName, var: unique_name}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://supersim.twilio.com"
    auth: basic
  } {
    data_enabled: $data_enabled, data_limit: $data_limit, ip_commands_method: $ip_commands_method, ip_commands_url: $ip_commands_url, network_access_profile: $network_access_profile, sms_commands_enabled: $sms_commands_enabled, sms_commands_method: $sms_commands_method, sms_commands_url: $sms_commands_url, unique_name: $unique_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a Fleet instance from your account.
#
# GET /v1/Fleets/{Sid}
# Returns: record<account_sid: string, data_enabled: bool, data_limit: int, data_metering: string, date_created: string, date_updated: string, ip_commands_method: string, ip_commands_url: string, network_access_profile_sid: string, sid: string, sms_commands_enabled: bool, sms_commands_method: string, sms_commands_url: string, unique_name: string, url: string>
# operationId: FetchFleet
export def "fetch-fleet" [
  sid: string
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
    path: "/v1/Fleets/{Sid}"
    path_params: [{name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://supersim.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the given properties of a Super SIM Fleet instance from your account.
#
# POST /v1/Fleets/{Sid}
# Returns: record<account_sid: string, data_enabled: bool, data_limit: int, data_metering: string, date_created: string, date_updated: string, ip_commands_method: string, ip_commands_url: string, network_access_profile_sid: string, sid: string, sms_commands_enabled: bool, sms_commands_method: string, sms_commands_url: string, unique_name: string, url: string>
# operationId: UpdateFleet
export def "update-fleet" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --data-limit: int # The total data usage (download and upload combined) in Megabytes that each Super SIM assigned to the Fleet can consume during a billing period (normally one month). Value must be between 1MB (1) and 2TB (2,000,000). Defaults to 1GB (1,000).
  --ip-commands-method: string@ip-commands-method-completer # A string representing the HTTP method to use when making a request to `ip_commands_url`. Can be one of `POST` or `GET`. Defaults to `POST`. (format: http-method)
  --ip-commands-url: string # The URL that will receive a webhook when a Super SIM in the Fleet is used to send an IP Command from your device to a special IP address. Your server should respond with an HTTP status code in the 200 range; any response body will be ignored. (format: uri)
  --network-access-profile: string # The SID or unique name of the Network Access Profile that will control which cellular networks the Fleet's SIMs can connect to.
  --sms-commands-method: string@sms-commands-method-completer # A string representing the HTTP method to use when making a request to `sms_commands_url`. Can be one of `POST` or `GET`. Defaults to `POST`. (format: http-method)
  --sms-commands-url: string # The URL that will receive a webhook when a Super SIM in the Fleet is used to send an SMS from your device to the SMS Commands number. Your server should respond with an HTTP status code in the 200 range; any response body will be ignored. (format: uri)
  --unique-name: string # An application-defined string that uniquely identifies the resource. It can be used in place of the resource's `sid` in the URL to address the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Fleets/{Sid}"
    path_params: [{name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: DataLimit, var: data_limit}, {name: IpCommandsMethod, var: ip_commands_method}, {name: IpCommandsUrl, var: ip_commands_url}, {name: NetworkAccessProfile, var: network_access_profile}, {name: SmsCommandsMethod, var: sms_commands_method}, {name: SmsCommandsUrl, var: sms_commands_url}, {name: UniqueName, var: unique_name}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://supersim.twilio.com"
    auth: basic
  } {
    sid: $sid, data_limit: $data_limit, ip_commands_method: $ip_commands_method, ip_commands_url: $ip_commands_url, network_access_profile: $network_access_profile, sms_commands_method: $sms_commands_method, sms_commands_url: $sms_commands_url, unique_name: $unique_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of IP Commands from your account.
#
# GET /v1/IpCommands
# Returns: record<ip_commands: table<account_sid: string, date_created: string, date_updated: string, device_ip: string, device_port: int, direction: string, payload: string, payload_type: string, sid: string, sim_iccid: string, sim_sid: string, status: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListIpCommand
export def "list-ip-command" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sim: string # The SID or unique name of the Sim resource that IP Command was sent to or from.
  --sim-iccid: string # The ICCID of the Sim resource that IP Command was sent to or from.
  --status: string@status-completer-1 # The status of the IP Command. Can be: `queued`, `sent`, `received` or `failed`. See the [IP Command Status Values](https://www.twilio.com/docs/wireless/api/ipcommand-resource#status-values) for a description of each.
  --direction: string@direction-completer # The direction of the IP Command. Can be `to_sim` or `from_sim`. The value of `to_sim` is synonymous with the term `mobile terminated`, and `from_sim` is synonymous with the term `mobile originated`.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/IpCommands"
    query: [{name: Sim, var: sim}, {name: SimIccid, var: sim_iccid}, {name: Status, var: status}, {name: Direction, var: direction}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://supersim.twilio.com"
    auth: basic
  } {
    sim: $sim, sim_iccid: $sim_iccid, status: $status, direction: $direction, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send an IP Command to a Super SIM.
#
# POST /v1/IpCommands
# Returns: record<account_sid: string, date_created: string, date_updated: string, device_ip: string, device_port: int, direction: string, payload: string, payload_type: string, sid: string, sim_iccid: string, sim_sid: string, status: string, url: string>
# operationId: CreateIpCommand
export def "create-ip-command" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --callback-method: string@callback-method-completer # The HTTP method we should use to call `callback_url`. Can be `GET` or `POST`, and the default is `POST`. (format: http-method)
  --callback-url: string # The URL we should call using the `callback_method` after we have sent the IP Command. (format: uri)
  device_port: int # The device port to which the IP Command will be sent.
  payload: string # The data that will be sent to the device. The payload cannot exceed 1300 bytes. If the PayloadType is set to text, the payload is encoded in UTF-8. If PayloadType is set to binary, the payload is encoded in Base64.
  --payload-type: string@payload-type-completer
  sim: string # The `sid` or `unique_name` of the [Super SIM](https://www.twilio.com/docs/iot/supersim/api/sim-resource) to send the IP Command to.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/IpCommands"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: CallbackMethod, var: callback_method}, {name: CallbackUrl, var: callback_url}, {name: DevicePort, var: device_port}, {name: Payload, var: payload}, {name: PayloadType, var: payload_type}, {name: Sim, var: sim}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://supersim.twilio.com"
    auth: basic
  } {
    callback_method: $callback_method, callback_url: $callback_url, device_port: $device_port, payload: $payload, payload_type: $payload_type, sim: $sim
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch IP Command instance from your account.
#
# GET /v1/IpCommands/{Sid}
# Returns: record<account_sid: string, date_created: string, date_updated: string, device_ip: string, device_port: int, direction: string, payload: string, payload_type: string, sid: string, sim_iccid: string, sim_sid: string, status: string, url: string>
# operationId: FetchIpCommand
export def "fetch-ip-command" [
  sid: string
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
    path: "/v1/IpCommands/{Sid}"
    path_params: [{name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://supersim.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of Network Access Profiles from your account.
#
# GET /v1/NetworkAccessProfiles
# Returns: record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, network_access_profiles: table<account_sid: string, date_created: string, date_updated: string, links: record, sid: string, unique_name: string, url: string>>
# operationId: ListNetworkAccessProfile
export def "list-network-access-profile" [
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
    path: "/v1/NetworkAccessProfiles"
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://supersim.twilio.com"
    auth: basic
  } {
    page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new Network Access Profile
#
# POST /v1/NetworkAccessProfiles
# Returns: record<account_sid: string, date_created: string, date_updated: string, links: record, sid: string, unique_name: string, url: string>
# operationId: CreateNetworkAccessProfile
export def "create-network-access-profile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --networks: list<string> # List of Network SIDs that this Network Access Profile will allow connections to.
  --unique-name: string # An application-defined string that uniquely identifies the resource. It can be used in place of the resource's `sid` in the URL to address the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/NetworkAccessProfiles"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Networks, var: networks}, {name: UniqueName, var: unique_name}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://supersim.twilio.com"
    auth: basic
  } {
    networks: $networks, unique_name: $unique_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of Network Access Profile resource's Network resource.
#
# GET /v1/NetworkAccessProfiles/{NetworkAccessProfileSid}/Networks
# Returns: record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, networks: table<friendly_name: string, identifiers: list, iso_country: string, network_access_profile_sid: string, sid: string, url: string>>
# operationId: ListNetworkAccessProfileNetwork
export def "list-network-access-profile-network" [
  network_access_profile_sid: string
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
    path: "/v1/NetworkAccessProfiles/{NetworkAccessProfileSid}/Networks"
    path_params: [{name: NetworkAccessProfileSid, var: network_access_profile_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://supersim.twilio.com"
    auth: basic
  } {
    network_access_profile_sid: $network_access_profile_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a Network resource to the Network Access Profile resource.
#
# POST /v1/NetworkAccessProfiles/{NetworkAccessProfileSid}/Networks
# Returns: record<friendly_name: string, identifiers: list<any>, iso_country: string, network_access_profile_sid: string, sid: string, url: string>
# operationId: CreateNetworkAccessProfileNetwork
export def "create-network-access-profile-network" [
  network_access_profile_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  network: string # The SID of the Network resource to be added to the Network Access Profile resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/NetworkAccessProfiles/{NetworkAccessProfileSid}/Networks"
    path_params: [{name: NetworkAccessProfileSid, var: network_access_profile_sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Network, var: network}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://supersim.twilio.com"
    auth: basic
  } {
    network_access_profile_sid: $network_access_profile_sid, network: $network
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a Network resource from the Network Access Profile resource's.
#
# DELETE /v1/NetworkAccessProfiles/{NetworkAccessProfileSid}/Networks/{Sid}
# operationId: DeleteNetworkAccessProfileNetwork
export def "delete-network-access-profile-network" [
  network_access_profile_sid: string
  sid: string
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
    path: "/v1/NetworkAccessProfiles/{NetworkAccessProfileSid}/Networks/{Sid}"
    path_params: [{name: NetworkAccessProfileSid, var: network_access_profile_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://supersim.twilio.com"
    auth: basic
  } {
    network_access_profile_sid: $network_access_profile_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a Network Access Profile resource's Network resource.
#
# GET /v1/NetworkAccessProfiles/{NetworkAccessProfileSid}/Networks/{Sid}
# Returns: record<friendly_name: string, identifiers: list<any>, iso_country: string, network_access_profile_sid: string, sid: string, url: string>
# operationId: FetchNetworkAccessProfileNetwork
export def "fetch-network-access-profile-network" [
  network_access_profile_sid: string
  sid: string
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
    path: "/v1/NetworkAccessProfiles/{NetworkAccessProfileSid}/Networks/{Sid}"
    path_params: [{name: NetworkAccessProfileSid, var: network_access_profile_sid}, {name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://supersim.twilio.com"
    auth: basic
  } {
    network_access_profile_sid: $network_access_profile_sid, sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a Network Access Profile instance from your account.
#
# GET /v1/NetworkAccessProfiles/{Sid}
# Returns: record<account_sid: string, date_created: string, date_updated: string, links: record, sid: string, unique_name: string, url: string>
# operationId: FetchNetworkAccessProfile
export def "fetch-network-access-profile" [
  sid: string
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
    path: "/v1/NetworkAccessProfiles/{Sid}"
    path_params: [{name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://supersim.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the given properties of a Network Access Profile in your account.
#
# POST /v1/NetworkAccessProfiles/{Sid}
# Returns: record<account_sid: string, date_created: string, date_updated: string, links: record, sid: string, unique_name: string, url: string>
# operationId: UpdateNetworkAccessProfile
export def "update-network-access-profile" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --unique-name: string # The new unique name of the Network Access Profile.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/NetworkAccessProfiles/{Sid}"
    path_params: [{name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: UniqueName, var: unique_name}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://supersim.twilio.com"
    auth: basic
  } {
    sid: $sid, unique_name: $unique_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of Network resources.
#
# GET /v1/Networks
# Returns: record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, networks: table<friendly_name: string, identifiers: list, iso_country: string, sid: string, url: string>>
# operationId: ListNetwork
export def "list-network" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --iso-country: string # The [ISO country code](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2) of the Network resources to read.
  --mcc: string # The 'mobile country code' of a country. Network resources with this `mcc` in their `identifiers` will be read.
  --mnc: string # The 'mobile network code' of a mobile operator network. Network resources with this `mnc` in their `identifiers` will be read.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/Networks"
    query: [{name: IsoCountry, var: iso_country}, {name: Mcc, var: mcc}, {name: Mnc, var: mnc}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://supersim.twilio.com"
    auth: basic
  } {
    iso_country: $iso_country, mcc: $mcc, mnc: $mnc, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a Network resource.
#
# GET /v1/Networks/{Sid}
# Returns: record<friendly_name: string, identifiers: list<any>, iso_country: string, sid: string, url: string>
# operationId: FetchNetwork
export def "fetch-network" [
  sid: string
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
    path: "/v1/Networks/{Sid}"
    path_params: [{name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://supersim.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of Settings Updates.
#
# GET /v1/SettingsUpdates
# Returns: record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, settings_updates: table<date_completed: string, date_created: string, date_updated: string, iccid: string, packages: list, sid: string, sim_sid: string, status: string>>
# operationId: ListSettingsUpdate
export def "list-settings-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sim: string # Filter the Settings Updates by a Super SIM's SID or UniqueName.
  --status: string@status-completer-2 # Filter the Settings Updates by status. Can be `scheduled`, `in-progress`, `successful`, or `failed`.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/SettingsUpdates"
    query: [{name: Sim, var: sim}, {name: Status, var: status}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://supersim.twilio.com"
    auth: basic
  } {
    sim: $sim, status: $status, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of Super SIMs from your account.
#
# GET /v1/Sims
# Returns: record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, sims: table<account_sid: string, date_created: string, date_updated: string, fleet_sid: string, iccid: string, links: record, sid: string, status: string, unique_name: string, url: string>>
# operationId: ListSim
export def "list-sim" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer-3 # The status of the Sim resources to read. Can be `new`, `ready`, `active`, `inactive`, or `scheduled`.
  --fleet: string # The SID or unique name of the Fleet to which a list of Sims are assigned.
  --iccid: string # The [ICCID](https://en.wikipedia.org/wiki/Subscriber_identity_module#ICCID) associated with a Super SIM to filter the list by. Passing this parameter will always return a list containing zero or one SIMs.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/Sims"
    query: [{name: Status, var: status}, {name: Fleet, var: fleet}, {name: Iccid, var: iccid}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://supersim.twilio.com"
    auth: basic
  } {
    status: $status, fleet: $fleet, iccid: $iccid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Register a Super SIM to your Account
#
# POST /v1/Sims
# Returns: record<account_sid: string, date_created: string, date_updated: string, fleet_sid: string, iccid: string, links: record, sid: string, status: string, unique_name: string, url: string>
# operationId: CreateSim
export def "create-sim" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  iccid: string # The [ICCID](https://en.wikipedia.org/wiki/Subscriber_identity_module#ICCID) of the Super SIM to be added to your Account.
  registration_code: string # The 10-digit code required to claim the Super SIM for your Account.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Sims"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Iccid, var: iccid}, {name: RegistrationCode, var: registration_code}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://supersim.twilio.com"
    auth: basic
  } {
    iccid: $iccid, registration_code: $registration_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a Super SIM instance from your account.
#
# GET /v1/Sims/{Sid}
# Returns: record<account_sid: string, date_created: string, date_updated: string, fleet_sid: string, iccid: string, links: record, sid: string, status: string, unique_name: string, url: string>
# operationId: FetchSim
export def "fetch-sim" [
  sid: string
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
    path: "/v1/Sims/{Sid}"
    path_params: [{name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://supersim.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the given properties of a Super SIM instance from your account.
#
# POST /v1/Sims/{Sid}
# Returns: record<account_sid: string, date_created: string, date_updated: string, fleet_sid: string, iccid: string, links: record, sid: string, status: string, unique_name: string, url: string>
# operationId: UpdateSim
export def "update-sim" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-sid: string # The SID of the Account to which the Sim resource should belong. The Account SID can only be that of the requesting Account or that of a Subaccount of the requesting Account. Only valid when the Sim resource's status is new.
  --callback-method: string@callback-method-completer # The HTTP method we should use to call `callback_url`. Can be: `GET` or `POST` and the default is POST. (format: http-method)
  --callback-url: string # The URL we should call using the `callback_method` after an asynchronous update has finished. (format: uri)
  --fleet: string # The SID or unique name of the Fleet to which the SIM resource should be assigned.
  --status: string@status-completer-4
  --unique-name: string # An application-defined string that uniquely identifies the resource. It can be used in place of the resource's `sid` in the URL to address the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/Sims/{Sid}"
    path_params: [{name: Sid, var: sid}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: AccountSid, var: account_sid}, {name: CallbackMethod, var: callback_method}, {name: CallbackUrl, var: callback_url}, {name: Fleet, var: fleet}, {name: Status, var: status}, {name: UniqueName, var: unique_name}]}
    accept: ["application/json"]
    ok: [200, 202]
    base_url: "https://supersim.twilio.com"
    auth: basic
  } {
    sid: $sid, account_sid: $account_sid, callback_method: $callback_method, callback_url: $callback_url, fleet: $fleet, status: $status, unique_name: $unique_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of Billing Periods for a Super SIM.
#
# GET /v1/Sims/{SimSid}/BillingPeriods
# Returns: record<billing_periods: table<account_sid: string, date_created: string, date_updated: string, end_time: string, period_type: string, sid: string, sim_sid: string, start_time: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListBillingPeriod
export def "list-billing-period" [
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
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/Sims/{SimSid}/BillingPeriods"
    path_params: [{name: SimSid, var: sim_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://supersim.twilio.com"
    auth: basic
  } {
    sim_sid: $sim_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of IP Addresses for the given Super SIM.
#
# GET /v1/Sims/{SimSid}/IpAddresses
# Returns: record<ip_addresses: table<ip_address: string, ip_address_version: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>>
# operationId: ListSimIpAddress
export def "list-sim-ip-address" [
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
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/Sims/{SimSid}/IpAddresses"
    path_params: [{name: SimSid, var: sim_sid}]
    query: [{name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://supersim.twilio.com"
    auth: basic
  } {
    sim_sid: $sim_sid, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of SMS Commands from your account.
#
# GET /v1/SmsCommands
# Returns: record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, sms_commands: table<account_sid: string, date_created: string, date_updated: string, direction: string, payload: string, sid: string, sim_sid: string, status: string, url: string>>
# operationId: ListSmsCommand
export def "list-sms-command" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sim: string # The SID or unique name of the Sim resource that SMS Command was sent to or from.
  --status: string@status-completer-5 # The status of the SMS Command. Can be: `queued`, `sent`, `delivered`, `received` or `failed`. See the [SMS Command Status Values](https://www.twilio.com/docs/iot/supersim/api/smscommand-resource#status-values) for a description of each.
  --direction: string@direction-completer # The direction of the SMS Command. Can be `to_sim` or `from_sim`. The value of `to_sim` is synonymous with the term `mobile terminated`, and `from_sim` is synonymous with the term `mobile originated`.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/SmsCommands"
    query: [{name: Sim, var: sim}, {name: Status, var: status}, {name: Direction, var: direction}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://supersim.twilio.com"
    auth: basic
  } {
    sim: $sim, status: $status, direction: $direction, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send SMS Command to a Sim.
#
# POST /v1/SmsCommands
# Returns: record<account_sid: string, date_created: string, date_updated: string, direction: string, payload: string, sid: string, sim_sid: string, status: string, url: string>
# operationId: CreateSmsCommand
export def "create-sms-command" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --callback-method: string@callback-method-completer # The HTTP method we should use to call `callback_url`. Can be: `GET` or `POST` and the default is POST. (format: http-method)
  --callback-url: string # The URL we should call using the `callback_method` after we have sent the command. (format: uri)
  payload: string # The message body of the SMS Command.
  sim: string # The `sid` or `unique_name` of the [SIM](https://www.twilio.com/docs/iot/supersim/api/sim-resource) to send the SMS Command to.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/SmsCommands"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: CallbackMethod, var: callback_method}, {name: CallbackUrl, var: callback_url}, {name: Payload, var: payload}, {name: Sim, var: sim}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://supersim.twilio.com"
    auth: basic
  } {
    callback_method: $callback_method, callback_url: $callback_url, payload: $payload, sim: $sim
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch SMS Command instance from your account.
#
# GET /v1/SmsCommands/{Sid}
# Returns: record<account_sid: string, date_created: string, date_updated: string, direction: string, payload: string, sid: string, sim_sid: string, status: string, url: string>
# operationId: FetchSmsCommand
export def "fetch-sms-command" [
  sid: string
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
    path: "/v1/SmsCommands/{Sid}"
    path_params: [{name: Sid, var: sid}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://supersim.twilio.com"
    auth: basic
  } {
    sid: $sid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List UsageRecords
#
# GET /v1/UsageRecords
# Returns: record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, usage_records: table<account_sid: string, billed_unit: string, data_download: int, data_total: int, data_total_billed: float, data_upload: int, fleet_sid: string, iso_country: string, network_sid: string, period: any, sim_sid: string>>
# operationId: ListUsageRecord
export def "list-usage-record" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sim: string # SID or unique name of a Sim resource. Only show UsageRecords representing usage incurred by this Super SIM.
  --fleet: string # SID or unique name of a Fleet resource. Only show UsageRecords representing usage for Super SIMs belonging to this Fleet resource at the time the usage occurred.
  --network: string # SID of a Network resource. Only show UsageRecords representing usage on this network.
  --iso-country: string # Alpha-2 ISO Country Code. Only show UsageRecords representing usage in this country. (format: iso-country-code)
  --group: string@group-completer # Dimension over which to aggregate usage records. Can be: `sim`, `fleet`, `network`, `isoCountry`. Default is to not aggregate across any of these dimensions, UsageRecords will be aggregated into the time buckets described by the `Granularity` parameter.
  --granularity: string@granularity-completer # Time-based grouping that UsageRecords should be aggregated by. Can be: `hour`, `day`, or `all`. Default is `all`. `all` returns one UsageRecord that describes the usage for the entire period.
  --start-time: string # Only include usage that occurred at or after this time, specified in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format. Default is one month before the `end_time`. (format: date-time)
  --end-time: string # Only include usage that occurred before this time (exclusive), specified in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format. Default is the current time. (format: date-time)
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/UsageRecords"
    query: [{name: Sim, var: sim}, {name: Fleet, var: fleet}, {name: Network, var: network}, {name: IsoCountry, var: iso_country}, {name: Group, var: group}, {name: Granularity, var: granularity}, {name: StartTime, var: start_time}, {name: EndTime, var: end_time}, {name: PageSize, var: page_size}, {name: Page, var: page}, {name: PageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://supersim.twilio.com"
    auth: basic
  } {
    sim: $sim, fleet: $fleet, network: $network, iso_country: $iso_country, group: $group, granularity: $granularity, start_time: $start_time, end_time: $end_time, page_size: $page_size, page: $page, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
