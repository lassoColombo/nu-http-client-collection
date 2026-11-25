# Auto-generated client for WhatsApp Business API v1.0
# Source: https://api.apis.guru/v2/specs/whatsapp.local/1.0/openapi.json
# Auth: --token flag or $env.WHATSAPP_BUSINESS_API_TOKEN

const CLIENT = {
  base_url: "http://whatsapp.local"
  token_env_var: "WHATSAPP_BUSINESS_API_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: bearer, in: header, header_name: Authorization, prefix: Bearer}
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

def base-url-completer [] { ["http://whatsapp.local" "http://example.com/v1"] }
def auth-scheme-completer [] { ["bearer" "basic" "basic-credentials"] }

# Completers for enum parameters
def method-completer [] { ["sms" "voice"] }
def shards-completer [] { ["1" "16" "2" "32" "4" "8"] }
def blocking-completer [] { ["no_wait" "wait"] }
def recipient-type-completer [] { ["group" "individual"] }
def type-completer [] { ["audio" "contacts" "document" "hsm" "image" "location" "text" "unknown" "video" "voice"] }
def accept-completer [] { ["application/json" "text/plain"] }
def accept-completer-1 [] { ["application/json" "image/jpeg"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    request-code: "record<account: table<vname: string>>"
    download-ca-certificate: "binary"
    download-webhook-ca-certificate: "binary"
    check-contact: "record<errors: table<code: int, details: string, href: string, title: string>, meta: record<api_status: string, version: string>, contacts: table<input: string, status: string, wa_id: string>>"
    get-all-groups: "record<errors: table<code: int, details: string, href: string, title: string>, meta: record<api_status: string, version: string>, groups: table<creation_time: int, id: string>>"
    create-group: "record<errors: table<code: int, details: string, href: string, title: string>, meta: record<api_status: string, version: string>, groups: table<creation_time: int, id: string>>"
    get-group-info: "record<errors: table<code: int, details: string, href: string, title: string>, meta: record<api_status: string, version: string>, groups: table<admins: list, creation_time: int, creator: string, participants: list, subject: string>>"
    get-group-invite: "record<errors: table<code: int, details: string, href: string, title: string>, meta: record<api_status: string, version: string>, groups: table<link: string>>"
    upload-media: "record<errors: table<code: int, details: string, href: string, title: string>, meta: record<api_status: string, version: string>, media: table<id: string>>"
    send-message: "record<errors: table<code: int, details: string, href: string, title: string>, meta: record<api_status: string, version: string>, messages: table<id: string>>"
    get-metrics: "record"
    get-application-settings: "record<callback_backoff_delay_ms: string, callback_persist: bool, heartbeat_interval: int, max_callback_backoff_delay_ms: string, media: record<auto_download: list<string>>, on_call_pager: string, pass_through: bool, sent_status: bool, unhealthy_interval: int, webhooks: record<max_concurrent_requests: int, url: string>>"
    update-application-settings: "record<errors: table<code: int, details: string, href: string, title: string>, meta: record<api_status: string, version: string>>"
    get-media-providers: "record<errors: table<code: int, details: string, href: string, title: string>, meta: record<api_status: string, version: string>, settings: record<application: record<media: record>>>"
    backup-settings: "record<settings: record<data: string>>"
    get-business-profile: "record<errors: table<code: int, details: string, href: string, title: string>, meta: record<api_status: string, version: string>, settings: record<business: record<profile: record>>>"
    get-profile-about: "record<settings: record<profile: record<about: record>>>"
    get-profile-photo: "record<settings: record<profile: record<photo: record>>>"
    get-app-stats: "record"
    get-db-stats: "record"
    get-support-info: "record"
    create-user: "record<errors: table<code: int, details: string, href: string, title: string>, meta: record<api_status: string, version: string>, users: table<username: string>>"
    login-user: "record<errors: table<code: int, details: string, href: string, title: string>, meta: record<api_status: string, version: string>, users: table<expires_after: string, token: string>>"
    delete-user: "record<errors: table<code: int, details: string, href: string, title: string>, meta: record<api_status: string, version: string>, users: table<username: string>>"
    get-user: "record<errors: table<code: int, details: string, href: string, title: string>, meta: record<api_status: string, version: string>, users: table<ROLES: string, username: string>>"
    update-user: "record<errors: table<code: int, details: string, href: string, title: string>, meta: record<api_status: string, version: string>, users: table<username: string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["request-code" "set-shards" "register-account" "upload-certificate" "download-ca-certificate" "delete-webhook-ca-certificate" "download-webhook-ca-certificate" "upload-webhook-ca-certificate" "check-contact" "get-all-groups" "create-group" "get-group-info" "update-group-info" "demote-group-admin" "promote-to-group-admin" "delete-group-icon" "get-group-icon-binary" "set-group-icon" "delete-group-invite" "get-group-invite" "leave-group" "remove-group-participant" "check-health" "upload-media" "delete-media" "download-media" "send-message" "mark-message-as-read" "get-metrics" "disable-two-step" "enable-two-step" "reset-application-settings" "get-application-settings" "update-application-settings" "get-media-providers" "update-media-providers" "delete-media-providers" "backup-settings" "get-business-profile" "update-business-profile" "get-profile-about" "update-profile-about" "delete-profile-photo" "get-profile-photo" "update-profile-photo" "restore-settings" "get-app-stats" "get-db-stats" "get-support-info" "create-user" "login-user" "logout-user" "delete-user" "get-user" "update-user" "commands"] | sort) } | get name | first)
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

# Request-Code
#
# POST /account
# Returns: record<account: table<vname: string>>
# operationId: RequestCode
export def "request-code" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  cc: string # Numerical country code for the phone number you are registering
  cert: string # Base64-encoded Verified Name certificate
  method: string@method-completer # Method of receiving your registration code
  phone_number: string # Phone number you are registering, without the country code or plus symbol (+)
  --pin: string # Existing 6-digit PIN — This is only required when two-factor verification is enabled on this account.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/account"
    body: {content_type: "application/json", kind: json, fields: [{name: cc, var: cc}, {name: cert, var: cert}, {name: method, var: method}, {name: phone_number, var: phone_number}, {name: pin, var: pin}]}
    accept: ["application/json"]
    ok: [201, 202]
    auth: bearer
  } {
    cc: $cc, cert: $cert, method: $method, phone_number: $phone_number, pin: $pin
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set-Shards
#
# POST /account/shards
# operationId: SetShards
export def "set-shards" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  cc: string
  phone_number: string
  pin: string
  shards: int@shards-completer # format: int32
]: any -> any {
  $in | http-request {
    method: post
    path: "/account/shards"
    body: {content_type: "application/json", kind: json, fields: [{name: cc, var: cc}, {name: phone_number, var: phone_number}, {name: pin, var: pin}, {name: shards, var: shards}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cc: $cc, phone_number: $phone_number, pin: $pin, shards: $shards
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Register-Account
#
# POST /account/verify
# operationId: RegisterAccount
export def "register-account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  code: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/account/verify"
    body: {content_type: "application/json", kind: json, fields: [{name: code, var: code}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    code: $code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload-Certificate
#
# POST /certificates/external
# operationId: UploadCertificate
export def "upload-certificate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/certificates/external"
    body: {content_type: "text/plain", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download-CA-Certificate
#
# GET /certificates/external/ca
# Returns: binary
# operationId: DownloadCaCertificate
export def "download-ca-certificate" [
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
    method: get
    path: "/certificates/external/ca"
    accept: ["text/plain"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Webhook CA Certificate
#
# DELETE /certificates/webhooks/ca
# operationId: DeleteWebhookCaCertificate
export def "delete-webhook-ca-certificate" [
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
    path: "/certificates/webhooks/ca"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download Webhook CA Certificate
#
# GET /certificates/webhooks/ca
# Returns: binary
# operationId: DownloadWebhookCaCertificate
export def "download-webhook-ca-certificate" [
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
    method: get
    path: "/certificates/webhooks/ca"
    accept: ["text/plain"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload Webhook CA Certificate
#
# POST /certificates/webhooks/ca
# operationId: UploadWebhookCaCertificate
export def "upload-webhook-ca-certificate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/certificates/webhooks/ca"
    body: {content_type: "text/plain", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check-Contact
#
# POST /contacts
# Returns: record<errors: table<code: int, details: string, href: string, title: string>, meta: record<api_status: string, version: string>, contacts: table<input: string, status: string, wa_id: string>>
# operationId: CheckContact
export def "check-contact" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --blocking: string@blocking-completer # Blocking determines whether the request should wait for the processing to complete (synchronous) or not (asynchronous). (default: no_wait)
  contacts: list<string> # Array of contact phone numbers. The numbers can be in any standard telephone number format.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/contacts"
    body: {content_type: "application/json", kind: json, fields: [{name: blocking, var: blocking}, {name: contacts, var: contacts}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    blocking: $blocking, contacts: $contacts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get-All-Groups
#
# GET /groups
# Returns: record<errors: table<code: int, details: string, href: string, title: string>, meta: record<api_status: string, version: string>, groups: table<creation_time: int, id: string>>
# operationId: GetAllGroups
export def "get-all-groups" [
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
    path: "/groups"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create-Group
#
# POST /groups
# Returns: record<errors: table<code: int, details: string, href: string, title: string>, meta: record<api_status: string, version: string>, groups: table<creation_time: int, id: string>>
# operationId: CreateGroup
export def "create-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  subject: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/groups"
    body: {content_type: "application/json", kind: json, fields: [{name: subject, var: subject}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subject: $subject
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get-Group-Info
#
# GET /groups/{GroupId}
# Returns: record<errors: table<code: int, details: string, href: string, title: string>, meta: record<api_status: string, version: string>, groups: table<admins: list, creation_time: int, creator: string, participants: list, subject: string>>
# operationId: GetGroupInfo
export def "get-group-info" [
  group_id: string
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
    path: "/groups/{GroupId}"
    path_params: [{name: GroupId, var: group_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update-Group-Info
#
# PUT /groups/{GroupId}
# operationId: UpdateGroupInfo
export def "update-group-info" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  subject: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/groups/{GroupId}"
    path_params: [{name: GroupId, var: group_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: subject, var: subject}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, subject: $subject
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Demote-Group-Admin
#
# DELETE /groups/{GroupId}/admins
# operationId: DemoteGroupAdmin
export def "demote-group-admin" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  wa_ids: list<string> # The WhatsApp IDs of the people to be added or removed as group admins
]: any -> any {
  $in | http-request {
    method: delete
    path: "/groups/{GroupId}/admins"
    path_params: [{name: GroupId, var: group_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: wa_ids, var: wa_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, wa_ids: $wa_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Promote-To-Group-Admin
#
# PATCH /groups/{GroupId}/admins
# operationId: PromoteToGroupAdmin
export def "promote-to-group-admin" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  wa_ids: list<string> # The WhatsApp IDs of the people to be added or removed as group admins
]: any -> any {
  $in | http-request {
    method: patch
    path: "/groups/{GroupId}/admins"
    path_params: [{name: GroupId, var: group_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: wa_ids, var: wa_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, wa_ids: $wa_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete-Group-Icon
#
# DELETE /groups/{GroupId}/icon
# operationId: DeleteGroupIcon
export def "delete-group-icon" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  file: string # format: binary
]: any -> any {
  $in | http-request {
    method: delete
    path: "/groups/{GroupId}/icon"
    path_params: [{name: GroupId, var: group_id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: File, var: file}], files: [File]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, file: $file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get-Group-Icon-Binary
#
# GET /groups/{GroupId}/icon
# operationId: GetGroupIconBinary
export def "get-group-icon-binary" [
  group_id: string
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
    method: get
    path: "/groups/{GroupId}/icon"
    path_params: [{name: GroupId, var: group_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set-Group-Icon
#
# POST /groups/{GroupId}/icon
# operationId: SetGroupIcon
export def "set-group-icon" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  file: string # format: binary
]: any -> any {
  $in | http-request {
    method: post
    path: "/groups/{GroupId}/icon"
    path_params: [{name: GroupId, var: group_id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: File, var: file}], files: [File]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, file: $file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete-Group-Invite
#
# DELETE /groups/{GroupId}/invite
# operationId: DeleteGroupInvite
export def "delete-group-invite" [
  group_id: string
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
    path: "/groups/{GroupId}/invite"
    path_params: [{name: GroupId, var: group_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get-Group-Invite
#
# GET /groups/{GroupId}/invite
# Returns: record<errors: table<code: int, details: string, href: string, title: string>, meta: record<api_status: string, version: string>, groups: table<link: string>>
# operationId: GetGroupInvite
export def "get-group-invite" [
  group_id: string
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
    path: "/groups/{GroupId}/invite"
    path_params: [{name: GroupId, var: group_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Leave-Group
#
# POST /groups/{GroupId}/leave
# operationId: LeaveGroup
export def "leave-group" [
  group_id: string
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
    method: post
    path: "/groups/{GroupId}/leave"
    path_params: [{name: GroupId, var: group_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove-Group-Participant
#
# DELETE /groups/{GroupId}/participants
# operationId: RemoveGroupParticipant
export def "remove-group-participant" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  wa_ids: list<string>
]: any -> any {
  $in | http-request {
    method: delete
    path: "/groups/{GroupId}/participants"
    path_params: [{name: GroupId, var: group_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: wa_ids, var: wa_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, wa_ids: $wa_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check-Health
#
# GET /health
# operationId: CheckHealth
export def "check-health" [
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
    method: get
    path: "/health"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload-Media
#
# POST /media
# Returns: record<errors: table<code: int, details: string, href: string, title: string>, meta: record<api_status: string, version: string>, media: table<id: string>>
# operationId: UploadMedia
export def "upload-media" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/media"
    body: {content_type: "application/msword", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete-Media
#
# DELETE /media/{MediaId}
# operationId: DeleteMedia
export def "delete-media" [
  media_id: string
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
    path: "/media/{MediaId}"
    path_params: [{name: MediaId, var: media_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    media_id: $media_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download-Media
#
# GET /media/{MediaId}
# operationId: DownloadMedia
export def "download-media" [
  media_id: string
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
    method: get
    path: "/media/{MediaId}"
    path_params: [{name: MediaId, var: media_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    media_id: $media_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send-Message
#
# POST /messages
# Returns: record<errors: table<code: int, details: string, href: string, title: string>, meta: record<api_status: string, version: string>, messages: table<id: string>>
# operationId: SendMessage
export def "send-message" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --audio: record # The media object containing audio — shape: {id?: string, link?: string, provider?: record}
  --contacts: list # item shape: {addresses?: list, birthday?: string, emails?: list, ims?: list<string>, name?: record, org?: record, phones?: list, urls?: list}
  --document: record # The media object containing a document — shape: {caption: string, filename: string, id?: string, link?: string, provider?: record}
  --hsm: record # The containing element for the message content — Indicates that the message is highly structured. Parameters contained within provide the structure. (e.g. {element_name: hello_world, language: {code: en, policy: deterministic}, localizable_params: [{default: 1234}], namespace: business_a_namespace}) — shape: {element_name: string, language: record, localizable_params: list, namespace: string}
  --image: record # The media object containing an image — shape: {caption: string, id?: string, link?: string, provider?: record}
  --location: record # e.g. {address: <Location's Address>, latitude: <Latitude>, longitude: <Longitude>, name: <Location Name>} — shape: {address: string, latitude: string, longitude: string, name: string}
  --preview-url: oneof<nothing, bool> # Specifying preview_url in the request is optional when not including a URL in your message. To include a URL preview, set preview_url to true in the message body and make sure the URL begins with http:// or https://. For more information, see the Sending URLs in Text Messages section.
  --recipient-type: string@recipient-type-completer # Determines whether the recipient is an individual or a group Specifying recipient_type in the request is optional when the value is individual. However, recipient_type is required when using group. If sending a text message to a group, see the Sending Group Messages documentation. (default: individual)
  --text: record # e.g. {body: <Message Text>} — shape: {body: string}
  to: string # When recipient_type is individual, this field is the WhatsApp ID (phone number) returned from contacts endpoint. When recipient_type is group, this field is the WhatsApp group ID.
  --ttl: record
  --type: string@type-completer # type of the message (default: text)
  --video: record # The media object containing a video — shape: {caption: string, id?: string, link?: string, provider?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/messages"
    body: {content_type: "application/json", kind: json, fields: [{name: audio, var: audio}, {name: contacts, var: contacts}, {name: document, var: document}, {name: hsm, var: hsm}, {name: image, var: image}, {name: location, var: location}, {name: preview_url, var: preview_url}, {name: recipient_type, var: recipient_type}, {name: text, var: text}, {name: to, var: to}, {name: ttl, var: ttl}, {name: type, var: type}, {name: video, var: video}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    audio: $audio, contacts: $contacts, document: $document, hsm: $hsm, image: $image, location: $location, preview_url: $preview_url, recipient_type: $recipient_type, text: $text, to: $to, ttl: $ttl, type: $type, video: $video
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Mark-Message-As-Read
#
# PUT /messages/{MessageID}
# operationId: MarkMessageAsRead
export def "mark-message-as-read" [
  message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  status: string # default: read
]: any -> any {
  $in | http-request {
    method: put
    path: "/messages/{MessageID}"
    path_params: [{name: MessageID, var: message_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    message_id: $message_id, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get-Metrics (since v2.21.3)
#
# GET /metrics
# Returns: record
# operationId: GetMetrics
export def "get-metrics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --format: string # e.g. prometheus
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/metrics"
    query: [{name: format, var: format}]
    accept: ["application/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    format: $format
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Disable-Two-Step
#
# DELETE /settings/account/two-step
# operationId: DisableTwoStep
export def "disable-two-step" [
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
    path: "/settings/account/two-step"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enable-Two-Step
#
# POST /settings/account/two-step
# operationId: EnableTwoStep
export def "enable-two-step" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  pin: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/settings/account/two-step"
    body: {content_type: "application/json", kind: json, fields: [{name: pin, var: pin}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pin: $pin
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reset-Application-Settings
#
# DELETE /settings/application
# operationId: ResetApplicationSettings
export def "reset-application-settings" [
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
    path: "/settings/application"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get-Application-Settings
#
# GET /settings/application
# Returns: record<callback_backoff_delay_ms: string, callback_persist: bool, heartbeat_interval: int, max_callback_backoff_delay_ms: string, media: record<auto_download: list<string>>, on_call_pager: string, pass_through: bool, sent_status: bool, unhealthy_interval: int, webhooks: record<max_concurrent_requests: int, url: string>>
# operationId: GetApplicationSettings
export def "get-application-settings" [
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
    path: "/settings/application"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update-Application-Settings
#
# PATCH /settings/application
# Returns: record<errors: table<code: int, details: string, href: string, title: string>, meta: record<api_status: string, version: string>>
# operationId: UpdateApplicationSettings
export def "update-application-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --callback-backoff-delay-ms: string # Backoff delay for a failed callback in milliseconds This setting is used to configure the amount of time the backoff delays before retrying a failed callback. The backoff delay increases linearly by this value each time a callback fails to get a HTTPS 200 OK response. The backoff delay is capped by the max_callback_backoff_delay_ms setting. (default: 3000)
  --callback-persist: oneof<nothing, bool> # Stores callbacks on disk until they are successfully acknowledged by the Webhook or not. Restart required. (default: true)
  --heartbeat-interval: int # Multiconnect: Interval of the Master node monitoring of Coreapp nodes in seconds (default: 5)
  --max-callback-backoff-delay-ms: string # Maximum delay for a failed callback in milliseconds (default: 900000)
  --media: record # e.g. {auto_download: [image, document, audio]} — shape: {auto_download: list<string>}
  --on-call-pager: string # Set to valid WhatsApp Group with users who wish to see alerts for critical errors and messages.
  --pass-through: oneof<nothing, bool> # When true, removes messages from the local database after they are delivered to or read by the recipient. When false, saves all messages on local storage until they are explicitly deleted. When messages are sent, they are stored in a local database. This database is used as the application's history. Since the business keeps its own history, you can specify whether you want message pass_through or not. Restart required. (default: true)
  --sent-status: oneof<nothing, bool> # Receive a notification that a message is sent to server. When true, you will receive a message indicating that a message has been sent. If false (default), you will not receive notification. (default: false)
  --unhealthy-interval: int # Multiconnect: Maximum amount of seconds a Master node waits for a Coreapp node to respond to a heartbeat before considering it unhealthy and starting the failover process. (default: 30)
  --webhooks: record # e.g. {max_concurrent_requests: 12, url: <Webhook URL, https>} — shape: {max_concurrent_requests?: "6"|"12"|"18"|"24", url?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/settings/application"
    body: {content_type: "application/json", kind: json, fields: [{name: callback_backoff_delay_ms, var: callback_backoff_delay_ms}, {name: callback_persist, var: callback_persist}, {name: heartbeat_interval, var: heartbeat_interval}, {name: max_callback_backoff_delay_ms, var: max_callback_backoff_delay_ms}, {name: media, var: media}, {name: on_call_pager, var: on_call_pager}, {name: pass_through, var: pass_through}, {name: sent_status, var: sent_status}, {name: unhealthy_interval, var: unhealthy_interval}, {name: webhooks, var: webhooks}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    callback_backoff_delay_ms: $callback_backoff_delay_ms, callback_persist: $callback_persist, heartbeat_interval: $heartbeat_interval, max_callback_backoff_delay_ms: $max_callback_backoff_delay_ms, media: $media, on_call_pager: $on_call_pager, pass_through: $pass_through, sent_status: $sent_status, unhealthy_interval: $unhealthy_interval, webhooks: $webhooks
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get-Media-Providers
#
# GET /settings/application/media/providers
# Returns: record<errors: table<code: int, details: string, href: string, title: string>, meta: record<api_status: string, version: string>, settings: record<application: record<media: record>>>
# operationId: GetMediaProviders
export def "get-media-providers" [
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
    path: "/settings/application/media/providers"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update-Media-Providers
#
# POST /settings/application/media/providers
# operationId: UpdateMediaProviders
export def "update-media-providers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> any {
  $in | http-request {
    method: post
    path: "/settings/application/media/providers"
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete-Media-Providers
#
# DELETE /settings/application/media/providers/{ProviderName}
# operationId: DeleteMediaProviders
export def "delete-media-providers" [
  provider_name: string
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
    path: "/settings/application/media/providers/{ProviderName}"
    path_params: [{name: ProviderName, var: provider_name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    provider_name: $provider_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Backup-Settings
#
# POST /settings/backup
# Returns: record<settings: record<data: string>>
# operationId: BackupSettings
export def "backup-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  password: string # Used to encrypt backup data for security
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/settings/backup"
    body: {content_type: "application/json", kind: json, fields: [{name: password, var: password}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    password: $password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get-Business-Profile
#
# GET /settings/business/profile
# Returns: record<errors: table<code: int, details: string, href: string, title: string>, meta: record<api_status: string, version: string>, settings: record<business: record<profile: record>>>
# operationId: GetBusinessProfile
export def "get-business-profile" [
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
    path: "/settings/business/profile"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update-Business-Profile
#
# POST /settings/business/profile
# operationId: updateBusinessProfile
export def "update-business-profile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  address: string # Address of the business Maximum of 256 characters
  description: string # Description of the business Maximum of 256 characters
  email: string # Email address to contact the business Maximum of 128 characters
  vertical: string # Industry of the business Maximum of 128 characters
  websites: list<string> # URLs associated with business (e.g., website, Facebook page, Instagram) Maximum of 2 websites with a maximum of 256 characters each
]: any -> any {
  $in | http-request {
    method: post
    path: "/settings/business/profile"
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: description, var: description}, {name: email, var: email}, {name: vertical, var: vertical}, {name: websites, var: websites}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    address: $address, description: $description, email: $email, vertical: $vertical, websites: $websites
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get-Profile-About
#
# GET /settings/profile/about
# Returns: record<settings: record<profile: record<about: record>>>
# operationId: GetProfileAbout
export def "get-profile-about" [
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
    path: "/settings/profile/about"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update-Profile-About
#
# PATCH /settings/profile/about
# operationId: UpdateProfileAbout
export def "update-profile-about" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  text: string # Text to display in your profile's About section The max length for the string is 139 characters.
]: any -> any {
  $in | http-request {
    method: patch
    path: "/settings/profile/about"
    body: {content_type: "application/json", kind: json, fields: [{name: text, var: text}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    text: $text
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete-Profile-Photo
#
# DELETE /settings/profile/photo
# operationId: DeleteProfilePhoto
export def "delete-profile-photo" [
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
    path: "/settings/profile/photo"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get-Profile-Photo
#
# GET /settings/profile/photo
# Returns: record<settings: record<profile: record<photo: record>>>
# operationId: GetProfilePhoto
export def "get-profile-photo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --format: string # e.g. link
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/settings/profile/photo"
    query: [{name: format, var: format}]
    accept: ["application/json", "image/jpeg"]
    ok: [200]
    auth: bearer
  } {
    format: $format
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update-Profile-Photo
#
# POST /settings/profile/photo
# operationId: UpdateProfilePhoto
export def "update-profile-photo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  file: string # format: binary
]: any -> any {
  $in | http-request {
    method: post
    path: "/settings/profile/photo"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: File, var: file}], files: [File]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    file: $file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Restore-Settings
#
# POST /settings/restore
# operationId: RestoreSettings
export def "restore-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  data: string # The data that was returned by the /v1/settings/backup API call
  password: string # The password you used in the /v1/settings/backup API call to encrypt the backup data
]: any -> any {
  $in | http-request {
    method: post
    path: "/settings/restore"
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}, {name: password, var: password}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    data: $data, password: $password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get-App-Stats
#
# GET /stats/app
# Returns: record
# operationId: GetAppStats
export def "get-app-stats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --format: string # e.g. prometheus
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/stats/app"
    query: [{name: format, var: format}]
    accept: ["application/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    format: $format
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get-DB-Stats
#
# GET /stats/db
# Returns: record
# operationId: GetDbStats
export def "get-db-stats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --format: string # e.g. prometheus
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/stats/db"
    query: [{name: format, var: format}]
    accept: ["application/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    format: $format
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get-Support-Info
#
# GET /support
# Returns: record
# operationId: GetSupportInfo
export def "get-support-info" [
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
    path: "/support"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create-User
#
# POST /users
# Returns: record<errors: table<code: int, details: string, href: string, title: string>, meta: record<api_status: string, version: string>, users: table<username: string>>
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
  password: string # username
  username: string # password
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users"
    body: {content_type: "application/json", kind: json, fields: [{name: password, var: password}, {name: username, var: username}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    password: $password, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Login-User
#
# POST /users/login
# Returns: record<errors: table<code: int, details: string, href: string, title: string>, meta: record<api_status: string, version: string>, users: table<expires_after: string, token: string>>
# operationId: LoginUser
export def "login-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  new_password: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users/login"
    body: {content_type: "application/json", kind: json, fields: [{name: new_password, var: new_password}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    new_password: $new_password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Logout-User
#
# POST /users/logout
# operationId: LogoutUser
export def "logout-user" [
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
    method: post
    path: "/users/logout"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete-User
#
# DELETE /users/{UserUsername}
# Returns: record<errors: table<code: int, details: string, href: string, title: string>, meta: record<api_status: string, version: string>, users: table<username: string>>
# operationId: DeleteUser
export def "delete-user" [
  user_username: string
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
    method: delete
    path: "/users/{UserUsername}"
    path_params: [{name: UserUsername, var: user_username}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_username: $user_username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get-User
#
# GET /users/{UserUsername}
# Returns: record<errors: table<code: int, details: string, href: string, title: string>, meta: record<api_status: string, version: string>, users: table<ROLES: string, username: string>>
# operationId: GetUser
export def "get-user" [
  user_username: string
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
    path: "/users/{UserUsername}"
    path_params: [{name: UserUsername, var: user_username}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_username: $user_username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update-User
#
# PUT /users/{UserUsername}
# Returns: record<errors: table<code: int, details: string, href: string, title: string>, meta: record<api_status: string, version: string>, users: table<username: string>>
# operationId: UpdateUser
export def "update-user" [
  user_username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  password: string # password
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/users/{UserUsername}"
    path_params: [{name: UserUsername, var: user_username}]
    body: {content_type: "application/json", kind: json, fields: [{name: password, var: password}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_username: $user_username, password: $password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
