# Auto-generated client for ClickMeter API v2
# Source: https://api.apis.guru/v2/specs/clickmeter.com/v2/openapi.json
# Auth: --token flag or $env.CLICKMETER_API_TOKEN

const CLIENT = {
  base_url: "http://apiv2.clickmeter.com:80"
  token_env_var: "CLICKMETER_API_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: x-clickmeter-authkey, in: header, header_name: X-Clickmeter-AuthKey, prefix: ""}
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

def base-url-completer [] { ["http://apiv2.clickmeter.com:80" "https://apiv2.clickmeter.com:80"] }
def auth-scheme-completer [] { ["x-clickmeter-authkey"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml" "text/json" "text/xml"] }
def accept-completer-1 [] { ["application/json" "text/json"] }
def sort-direction-completer [] { ["asc" "desc"] }
def time-format-completer [] { ["AmPm" "H24"] }
def entity-type-completer [] { ["datapoint" "group"] }
def type-completer [] { ["r" "w"] }
def type-completer-1 [] { ["datapoint" "group"] }
def time-frame-completer [] { ["beginning" "currentmonth" "currentyear" "custom" "last120" "last12months" "last180" "last30" "last7" "last90" "lastmonth" "lastyear" "previousmonth" "today" "yesterday"] }
def group-by-completer [] { ["month" "week"] }
def status-completer [] { ["active" "deleted"] }
def type-completer-2 [] { ["tl" "tp"] }
def status-completer-1 [] { ["active" "deleted" "paused" "spam"] }
def filter-completer [] { ["" "conversions" "nonuniques" "spiders" "uniques"] }
def protocol-completer [] { ["Http" "Https"] }
def timeframe-completer [] { ["currentmonth" "custom" "last120" "last180" "last30" "last7" "last90" "lastmonth" "previousmonth" "yesterday"] }
def filter-completer-1 [] { ["conversions" "nonuniques" "spiders" "uniques"] }
def status-completer-2 [] { ["Abuse" "Active" "Deleted" "Paused"] }
def type-completer-3 [] { ["TrackingLink" "TrackingPixel"] }
def type-completer-4 [] { ["dedicated" "go" "personal" "system"] }
def type-completer-5 [] { ["Dedicated" "Go" "Personal" "System"] }
def group-by-completer-1 [] { ["active" "deleted"] }
def type-completer-6 [] { ["dp" "gr" "tl" "tp"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    account-get: "record<boGoVal: string, bonusClicks: int, companyName: string, companyRole: string, email: string, firstName: string, lastName: string, phone: string, redirectOnly: bool, registrationDate: string, timeframeMinDate: string, timezone: int, timezonename: string>"
    account-post: "record<boGoVal: string, bonusClicks: int, companyName: string, companyRole: string, email: string, firstName: string, lastName: string, phone: string, redirectOnly: bool, registrationDate: string, timeframeMinDate: string, timezone: int, timezonename: string>"
    account-get-domain-whitelist: "record<entities: table<id: string, name: string>>"
    account-put-domain-whitelist: "record<id: string, name: string>"
    account-delete-domain-whitelist: "record<id: string, name: string>"
    account-get-guests: "record<entities: table<id: int, uri: string>>"
    account-put-guest: "record<apiKey: string, conversionOptions: record<hideComCost: bool, hideCost: bool, hideCount: bool, hideParams: bool, hideValue: bool, percentCommission: int, percentValue: int>, creationDate: string, currentGrant: record<DatapointType: string, Entity: record<id: int, uri: string>, EntityName: string, EntityType: string, Type: string>, dateFormat: string, decimalSeparator: string, email: string, extendedGrants: record<allowAllGrants: bool, allowGroupCreation: bool>, groupGrants: int, hitOptions: record<hideReferrer: bool>, id: int, key: string, language: string, loginCount: int, name: string, notes: string, numberGroupSeparator: string, password: string, timeFormat: string, timeZone: int, timeframeMinDate: string, timezonename: string, tlGrants: int, tpGrants: int, userName: string>"
    account-get-guests-count: "record<count: int>"
    account-delete-guest: "record<id: int, uri: string>"
    account-get-guest: "record<apiKey: string, conversionOptions: record<hideComCost: bool, hideCost: bool, hideCount: bool, hideParams: bool, hideValue: bool, percentCommission: int, percentValue: int>, creationDate: string, currentGrant: record<DatapointType: string, Entity: record<id: int, uri: string>, EntityName: string, EntityType: string, Type: string>, dateFormat: string, decimalSeparator: string, email: string, extendedGrants: record<allowAllGrants: bool, allowGroupCreation: bool>, groupGrants: int, hitOptions: record<hideReferrer: bool>, id: int, key: string, language: string, loginCount: int, name: string, notes: string, numberGroupSeparator: string, password: string, timeFormat: string, timeZone: int, timeframeMinDate: string, timezonename: string, tlGrants: int, tpGrants: int, userName: string>"
    account-post-guest: "record<apiKey: string, conversionOptions: record<hideComCost: bool, hideCost: bool, hideCount: bool, hideParams: bool, hideValue: bool, percentCommission: int, percentValue: int>, creationDate: string, currentGrant: record<DatapointType: string, Entity: record<id: int, uri: string>, EntityName: string, EntityType: string, Type: string>, dateFormat: string, decimalSeparator: string, email: string, extendedGrants: record<allowAllGrants: bool, allowGroupCreation: bool>, groupGrants: int, hitOptions: record<hideReferrer: bool>, id: int, key: string, language: string, loginCount: int, name: string, notes: string, numberGroupSeparator: string, password: string, timeFormat: string, timeZone: int, timeframeMinDate: string, timezonename: string, tlGrants: int, tpGrants: int, userName: string>"
    account-get-permissions: "record<entities: table<DatapointType: string, Entity: record, EntityName: string, EntityType: string, Type: string>>"
    account-get-permissions-count: "record<count: int>"
    post-account-guests-guest-id-type-permissions-patch: "record<id: int, uri: string>"
    account-patch-permissions: "record<id: int, uri: string>"
    account-get-ip-blacklist: "record<entities: table<id: string, ip: string>>"
    account-put-ip-blacklist: "record<id: string, ip: string>"
    account-delete-ip-blacklist: "record<id: string, ip: string>"
    account-get-plan: "record<allowedPersonalDomains: int, allowedPersonalUrls: int, billingPeriodEnd: string, billingPeriodStart: string, bonusMonthlyEvents: int, maximumDatapoints: int, maximumGuests: int, monthlyEvents: int, name: string, price: float, profileId: int, recurring: bool, recurringPeriod: int, usedDatapoints: int, usedMonthlyEvents: int>"
    aggregated-get-statistics-single: "record<activityDay: string, commissionsCost: float, conversionsCost: float, conversionsValue: float, convertedClicks: int, entityData: record, entityId: string, fromDay: string, hourlyBreakDown: record, lastHitDate: string, spiderHitsCount: int, toDay: string, totalClicks: int, totalViews: int, uniqueClicks: int, uniqueConversions: int, uniqueViews: int>"
    aggregated-get-statistics-list: "record<entities: table<activityDay: string, commissionsCost: float, conversionsCost: float, conversionsValue: float, convertedClicks: int, entityData: record, entityId: string, fromDay: string, hourlyBreakDown: record, lastHitDate: string, spiderHitsCount: int, toDay: string, totalClicks: int, totalViews: int, uniqueClicks: int, uniqueConversions: int, uniqueViews: int>>"
    aggregated-get-conversions-summary: "record<count: int, limit: int, offset: int, result: table<activityDay: string, commissionsCost: float, conversionsCost: float, conversionsValue: float, convertedClicks: int, entityData: record, entityId: string, fromDay: string, hourlyBreakDown: record, lastHitDate: string, spiderHitsCount: int, toDay: string, totalClicks: int, totalViews: int, uniqueClicks: int, uniqueConversions: int, uniqueViews: int>>"
    aggregated-get-datapoints-summary: "record<count: int, limit: int, offset: int, result: table<activityDay: string, commissionsCost: float, conversionsCost: float, conversionsValue: float, convertedClicks: int, entityData: record, entityId: string, fromDay: string, hourlyBreakDown: record, lastHitDate: string, spiderHitsCount: int, toDay: string, totalClicks: int, totalViews: int, uniqueClicks: int, uniqueConversions: int, uniqueViews: int>>"
    aggregated-get-groups-summary: "record<count: int, limit: int, offset: int, result: table<activityDay: string, commissionsCost: float, conversionsCost: float, conversionsValue: float, convertedClicks: int, entityData: record, entityId: string, fromDay: string, hourlyBreakDown: record, lastHitDate: string, spiderHitsCount: int, toDay: string, totalClicks: int, totalViews: int, uniqueClicks: int, uniqueConversions: int, uniqueViews: int>>"
    click-stream-get: "record<entities: table<accessTime: string, browser: record, clientLanguage: string, conversion1: record, conversion2: record, conversion3: record, conversion4: record, conversion5: record, conversions: list, entity: record, ip: string, isProxy: string, isSpider: string, isUnique: string, location: record, org: string, os: record, queryParams: string, realDestinationUrl: string, referer: string, source: record, type: string>>"
    conversions-get: "record<entities: table<id: int, uri: string>>"
    conversions-put: "record<id: int, uri: string>"
    conversions-get-statistics-all-list: "record<entities: table<activityDay: string, commissionsCost: float, conversionsCost: float, conversionsValue: float, convertedClicks: int, entityData: record, entityId: string, fromDay: string, hourlyBreakDown: record, lastHitDate: string, spiderHitsCount: int, toDay: string, totalClicks: int, totalViews: int, uniqueClicks: int, uniqueConversions: int, uniqueViews: int>>"
    conversions-count: "record<count: int>"
    conversions-delete: "record<id: int, uri: string>"
    get-conversions-conversion-id: "record<code: string, creationDate: string, deleted: bool, description: string, id: int, name: string, protocol: string, value: float>"
    conversions-post: "record<id: int, uri: string>"
    conversions-get-statistics-single: "record<activityDay: string, commissionsCost: float, conversionsCost: float, conversionsValue: float, convertedClicks: int, entityData: record, entityId: string, fromDay: string, hourlyBreakDown: record, lastHitDate: string, spiderHitsCount: int, toDay: string, totalClicks: int, totalViews: int, uniqueClicks: int, uniqueConversions: int, uniqueViews: int>"
    conversions-get-statistics-list: "record<entities: table<activityDay: string, commissionsCost: float, conversionsCost: float, conversionsValue: float, convertedClicks: int, entityData: record, entityId: string, fromDay: string, hourlyBreakDown: record, lastHitDate: string, spiderHitsCount: int, toDay: string, totalClicks: int, totalViews: int, uniqueClicks: int, uniqueConversions: int, uniqueViews: int>>"
    conversions-get-datapoints: "record<entities: table<id: int, uri: string>>"
    put-conversions-conversion-id-datapoints-batch-patch: "record<id: int, uri: string>"
    conversions-get-datapoints-count: "record<count: int>"
    conversions-patch: "record<id: int, uri: string>"
    conversions-get-hits: "record<hits: table<accessTime: string, browser: record, clientLanguage: string, conversion1: record, conversion2: record, conversion3: record, conversion4: record, conversion5: record, conversions: list, entity: record, ip: string, isProxy: string, isSpider: string, isUnique: string, location: record, org: string, os: record, queryParams: string, realDestinationUrl: string, referer: string, source: record, type: string>, lastKey: string>"
    conversions-patch-notes: "record<id: int, uri: string>"
    data-points-get: "record<entities: table<id: int, uri: string>>"
    data-points-put: "record<id: int, uri: string>"
    data-points-get-statistics-aggregated-single: "record<activityDay: string, commissionsCost: float, conversionsCost: float, conversionsValue: float, convertedClicks: int, entityData: record, entityId: string, fromDay: string, hourlyBreakDown: record, lastHitDate: string, spiderHitsCount: int, toDay: string, totalClicks: int, totalViews: int, uniqueClicks: int, uniqueConversions: int, uniqueViews: int>"
    data-points-get-statistics-all-list: "record<entities: table<activityDay: string, commissionsCost: float, conversionsCost: float, conversionsValue: float, convertedClicks: int, entityData: record, entityId: string, fromDay: string, hourlyBreakDown: record, lastHitDate: string, spiderHitsCount: int, toDay: string, totalClicks: int, totalViews: int, uniqueClicks: int, uniqueConversions: int, uniqueViews: int>>"
    data-points-batch-delete: "record<entityData: record<creationDate: string, encodeIp: bool, fifthConversionId: int, fifthConversionName: string, firstConversionId: int, firstConversionName: string, fourthConversionId: int, fourthConversionName: string, groupId: int, groupName: string, id: int, isPublic: bool, isSecured: bool, lightTracking: bool, name: string, notes: string, preferred: bool, redirectOnly: bool, secondConversionId: int, secondConversionName: string, status: string, tags: list<record>, thirdConversionId: int, thirdConversionName: string, title: string, trackingCode: string, type: string, typeTL: record<appendQuery: bool, browserDestinationItem: record, destinationMode: string, domainId: int, encodeUrl: bool, expirationClicks: int, expirationDate: string, firstUrl: string, goDomainId: int, hideUrl: bool, hideUrlTitle: string, isABTest: bool, password: string, pauseAfterClicksExpiration: bool, pauseAfterDateExpiration: bool, randomDestinationItems: list, redirectType: string, referrerClean: string, scripts: list, sequentialDestinationItems: list, spilloverDestinationItems: list, uniqueDestinationItem: record, url: string, urlAfterClicksExpiration: string, urlAfterDateExpiration: string, urlsByLanguage: list, urlsByNation: list, weightedDestinationItems: list>, typeTP: record<parameterNote: string>, writePermited: bool>, errors: table<code: record, errorMessage: string, errorValue: record, property: string>, result: record<id: int, uri: string>, status: string>"
    data-points-batch-post: "record<entityData: record<creationDate: string, encodeIp: bool, fifthConversionId: int, fifthConversionName: string, firstConversionId: int, firstConversionName: string, fourthConversionId: int, fourthConversionName: string, groupId: int, groupName: string, id: int, isPublic: bool, isSecured: bool, lightTracking: bool, name: string, notes: string, preferred: bool, redirectOnly: bool, secondConversionId: int, secondConversionName: string, status: string, tags: list<record>, thirdConversionId: int, thirdConversionName: string, title: string, trackingCode: string, type: string, typeTL: record<appendQuery: bool, browserDestinationItem: record, destinationMode: string, domainId: int, encodeUrl: bool, expirationClicks: int, expirationDate: string, firstUrl: string, goDomainId: int, hideUrl: bool, hideUrlTitle: string, isABTest: bool, password: string, pauseAfterClicksExpiration: bool, pauseAfterDateExpiration: bool, randomDestinationItems: list, redirectType: string, referrerClean: string, scripts: list, sequentialDestinationItems: list, spilloverDestinationItems: list, uniqueDestinationItem: record, url: string, urlAfterClicksExpiration: string, urlAfterDateExpiration: string, urlsByLanguage: list, urlsByNation: list, weightedDestinationItems: list>, typeTP: record<parameterNote: string>, writePermited: bool>, errors: table<code: record, errorMessage: string, errorValue: record, property: string>, result: record<id: int, uri: string>, status: string>"
    data-points-batch-put: "record<entityData: record<creationDate: string, encodeIp: bool, fifthConversionId: int, fifthConversionName: string, firstConversionId: int, firstConversionName: string, fourthConversionId: int, fourthConversionName: string, groupId: int, groupName: string, id: int, isPublic: bool, isSecured: bool, lightTracking: bool, name: string, notes: string, preferred: bool, redirectOnly: bool, secondConversionId: int, secondConversionName: string, status: string, tags: list<record>, thirdConversionId: int, thirdConversionName: string, title: string, trackingCode: string, type: string, typeTL: record<appendQuery: bool, browserDestinationItem: record, destinationMode: string, domainId: int, encodeUrl: bool, expirationClicks: int, expirationDate: string, firstUrl: string, goDomainId: int, hideUrl: bool, hideUrlTitle: string, isABTest: bool, password: string, pauseAfterClicksExpiration: bool, pauseAfterDateExpiration: bool, randomDestinationItems: list, redirectType: string, referrerClean: string, scripts: list, sequentialDestinationItems: list, spilloverDestinationItems: list, uniqueDestinationItem: record, url: string, urlAfterClicksExpiration: string, urlAfterDateExpiration: string, urlsByLanguage: list, urlsByNation: list, weightedDestinationItems: list>, typeTP: record<parameterNote: string>, writePermited: bool>, errors: table<code: record, errorMessage: string, errorValue: record, property: string>, result: record<id: int, uri: string>, status: string>"
    data-points-count: "record<count: int>"
    data-points-delete: "record<id: int, uri: string>"
    get-datapoints-id: "record<creationDate: string, encodeIp: bool, fifthConversionId: int, fifthConversionName: string, firstConversionId: int, firstConversionName: string, fourthConversionId: int, fourthConversionName: string, groupId: int, groupName: string, id: int, isPublic: bool, isSecured: bool, lightTracking: bool, name: string, notes: string, preferred: bool, redirectOnly: bool, secondConversionId: int, secondConversionName: string, status: string, tags: table<datapoints: list, groups: list, id: int, name: string>, thirdConversionId: int, thirdConversionName: string, title: string, trackingCode: string, type: string, typeTL: record<appendQuery: bool, browserDestinationItem: record<emailDestinationUrl: string, mobileDestinationUrl: string, spidersDestinationUrl: string>, destinationMode: string, domainId: int, encodeUrl: bool, expirationClicks: int, expirationDate: string, firstUrl: string, goDomainId: int, hideUrl: bool, hideUrlTitle: string, isABTest: bool, password: string, pauseAfterClicksExpiration: bool, pauseAfterDateExpiration: bool, randomDestinationItems: list<record>, redirectType: string, referrerClean: string, scripts: list<record>, sequentialDestinationItems: list<record>, spilloverDestinationItems: list<record>, uniqueDestinationItem: record<firstDestinationUrl: string>, url: string, urlAfterClicksExpiration: string, urlAfterDateExpiration: string, urlsByLanguage: list<record>, urlsByNation: list<record>, weightedDestinationItems: list<record>>, typeTP: record<parameterNote: string>, writePermited: bool>"
    data-points-post: "record<id: int, uri: string>"
    data-points-get-statistics-single: "record<activityDay: string, commissionsCost: float, conversionsCost: float, conversionsValue: float, convertedClicks: int, entityData: record, entityId: string, fromDay: string, hourlyBreakDown: record, lastHitDate: string, spiderHitsCount: int, toDay: string, totalClicks: int, totalViews: int, uniqueClicks: int, uniqueConversions: int, uniqueViews: int>"
    data-points-get-statistics-list: "record<entities: table<activityDay: string, commissionsCost: float, conversionsCost: float, conversionsValue: float, convertedClicks: int, entityData: record, entityId: string, fromDay: string, hourlyBreakDown: record, lastHitDate: string, spiderHitsCount: int, toDay: string, totalClicks: int, totalViews: int, uniqueClicks: int, uniqueConversions: int, uniqueViews: int>>"
    data-points-patch-favourite: "record<id: int, uri: string>"
    data-points-get-hits: "record<hits: table<accessTime: string, browser: record, clientLanguage: string, conversion1: record, conversion2: record, conversion3: record, conversion4: record, conversion5: record, conversions: list, entity: record, ip: string, isProxy: string, isSpider: string, isUnique: string, location: record, org: string, os: record, queryParams: string, realDestinationUrl: string, referer: string, source: record, type: string>, lastKey: string>"
    data-points-patch-notes: "record<id: int, uri: string>"
    domains-get: "record<entities: table<id: int, uri: string>>"
    domains-put: "record<id: int, uri: string>"
    domains-count: "record<count: int>"
    domains-delete: "record<id: int, uri: string>"
    get-domains-id: "record<custom404: string, customHomepage: string, id: int, name: string, type: string>"
    domains-update: "record<id: int, uri: string>"
    groups-get: "record<entities: table<id: int, uri: string>>"
    groups-put: "record<id: int, uri: string>"
    groups-get-statistics-aggregated-single: "record<activityDay: string, commissionsCost: float, conversionsCost: float, conversionsValue: float, convertedClicks: int, entityData: record, entityId: string, fromDay: string, hourlyBreakDown: record, lastHitDate: string, spiderHitsCount: int, toDay: string, totalClicks: int, totalViews: int, uniqueClicks: int, uniqueConversions: int, uniqueViews: int>"
    groups-get-statistics-all-list: "record<entities: table<activityDay: string, commissionsCost: float, conversionsCost: float, conversionsValue: float, convertedClicks: int, entityData: record, entityId: string, fromDay: string, hourlyBreakDown: record, lastHitDate: string, spiderHitsCount: int, toDay: string, totalClicks: int, totalViews: int, uniqueClicks: int, uniqueConversions: int, uniqueViews: int>>"
    groups-count: "record<count: int>"
    groups-delete: "record<id: int, uri: string>"
    get-groups-id: "record<creationDate: string, deleted: bool, id: int, isPublic: bool, name: string, notes: string, preferred: bool, redirectOnly: bool, tags: table<datapoints: list, groups: list, id: int, name: string>, writePermited: bool>"
    groups-post: "record<id: int, uri: string>"
    groups-get-statistics-single: "record<activityDay: string, commissionsCost: float, conversionsCost: float, conversionsValue: float, convertedClicks: int, entityData: record, entityId: string, fromDay: string, hourlyBreakDown: record, lastHitDate: string, spiderHitsCount: int, toDay: string, totalClicks: int, totalViews: int, uniqueClicks: int, uniqueConversions: int, uniqueViews: int>"
    groups-get-statistics-list: "record<entities: table<activityDay: string, commissionsCost: float, conversionsCost: float, conversionsValue: float, convertedClicks: int, entityData: record, entityId: string, fromDay: string, hourlyBreakDown: record, lastHitDate: string, spiderHitsCount: int, toDay: string, totalClicks: int, totalViews: int, uniqueClicks: int, uniqueConversions: int, uniqueViews: int>>"
    groups-get-datapoints-summary: "record<count: int, limit: int, offset: int, result: table<activityDay: string, commissionsCost: float, conversionsCost: float, conversionsValue: float, convertedClicks: int, entityData: record, entityId: string, fromDay: string, hourlyBreakDown: record, lastHitDate: string, spiderHitsCount: int, toDay: string, totalClicks: int, totalViews: int, uniqueClicks: int, uniqueConversions: int, uniqueViews: int>>"
    groups-get-datapoints: "record<entities: table<id: int, uri: string>>"
    groups-put-datapoint: "record<id: int, uri: string>"
    groups-get-datapoints-count: "record<count: int>"
    groups-patch-favourite: "record<id: int, uri: string>"
    groups-get-hits: "record<hits: table<accessTime: string, browser: record, clientLanguage: string, conversion1: record, conversion2: record, conversion3: record, conversion4: record, conversion5: record, conversions: list, entity: record, ip: string, isProxy: string, isSpider: string, isUnique: string, location: record, org: string, os: record, queryParams: string, realDestinationUrl: string, referer: string, source: record, type: string>, lastKey: string>"
    groups-patch-notes: "record<id: int, uri: string>"
    hits-get-hits: "record<hits: table<accessTime: string, browser: record, clientLanguage: string, conversion1: record, conversion2: record, conversion3: record, conversion4: record, conversion5: record, conversions: list, entity: record, ip: string, isProxy: string, isSpider: string, isUnique: string, location: record, org: string, os: record, queryParams: string, realDestinationUrl: string, referer: string, source: record, type: string>, lastKey: string>"
    me-get-me: "record<boGoVal: string, bonusClicks: int, companyName: string, companyRole: string, email: string, firstName: string, lastName: string, phone: string, redirectOnly: bool, registrationDate: string, timeframeMinDate: string, timezone: int, timezonename: string>"
    me-get-me-plan: "record<allowedPersonalDomains: int, allowedPersonalUrls: int, billingPeriodEnd: string, billingPeriodStart: string, bonusMonthlyEvents: int, maximumDatapoints: int, maximumGuests: int, monthlyEvents: int, name: string, price: float, profileId: int, recurring: bool, recurringPeriod: int, usedDatapoints: int, usedMonthlyEvents: int>"
    retargeting-get: "record<entities: table<id: int, uri: string>>"
    retargeting-put: "record<id: int, uri: string>"
    retargeting-count: "record<count: int>"
    retargeting-delete: "record<id: int, uri: string>"
    get-retargeting-id: "record<id: int, name: string, script: string>"
    retargeting-post: "record<id: int, uri: string>"
    retargeting-get-datapoints: "record<entities: table<id: int, uri: string>>"
    retargeting-get-datapoints-count: "record<count: int>"
    tags-get: "record<entities: table<id: int, uri: string>>"
    tags-put: "record<id: int, uri: string>"
    tags-count: "record"
    tags-delete: "record"
    get-tags-tag-id: "record<datapoints: list<int>, groups: list<int>, id: int, name: string>"
    tags-delete-related-datapoints: "record<id: int, uri: string>"
    tags-get-datapoints: "record<entities: table<id: int, uri: string>>"
    tags-get-datapoints-count: "record<count: int>"
    tags-patch-data-point: "record<id: int, uri: string>"
    tags-delete-related-groups: "record<id: int, uri: string>"
    tags-get-groups: "record<entities: table<id: int, uri: string>>"
    tags-get-groups-count: "record<count: int>"
    tags-patch-group: "record<id: int, uri: string>"
    tags-patch-tag-name: "record<id: int, uri: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["account-get" "account-post" "account-get-domain-whitelist" "account-put-domain-whitelist" "account-delete-domain-whitelist" "account-get-guests" "account-put-guest" "account-get-guests-count" "account-delete-guest" "account-get-guest" "account-post-guest" "account-get-permissions" "account-get-permissions-count" "post-account-guests-guest-id-type-permissions-patch" "account-patch-permissions" "account-get-ip-blacklist" "account-put-ip-blacklist" "account-delete-ip-blacklist" "account-get-plan" "aggregated-get-statistics-single" "aggregated-get-statistics-list" "aggregated-get-conversions-summary" "aggregated-get-datapoints-summary" "aggregated-get-groups-summary" "click-stream-get" "conversions-get" "conversions-put" "conversions-get-statistics-all-list" "conversions-count" "conversions-delete" "get-conversions-conversion-id" "conversions-post" "conversions-get-statistics-single" "conversions-get-statistics-list" "conversions-get-datapoints" "put-conversions-conversion-id-datapoints-batch-patch" "conversions-get-datapoints-count" "conversions-patch" "conversions-get-hits" "conversions-patch-notes" "data-points-get" "data-points-put" "data-points-get-statistics-aggregated-single" "data-points-get-statistics-all-list" "data-points-batch-delete" "data-points-batch-post" "data-points-batch-put" "data-points-count" "data-points-delete" "get-datapoints-id" "data-points-post" "data-points-get-statistics-single" "data-points-get-statistics-list" "data-points-patch-favourite" "data-points-get-hits" "data-points-patch-notes" "domains-get" "domains-put" "domains-count" "domains-delete" "get-domains-id" "domains-update" "groups-get" "groups-put" "groups-get-statistics-aggregated-single" "groups-get-statistics-all-list" "groups-count" "groups-delete" "get-groups-id" "groups-post" "groups-get-statistics-single" "groups-get-statistics-list" "groups-get-datapoints-summary" "groups-get-datapoints" "groups-put-datapoint" "groups-get-datapoints-count" "groups-patch-favourite" "groups-get-hits" "groups-patch-notes" "hits-get-hits" "me-get-me" "me-get-me-plan" "retargeting-get" "retargeting-put" "retargeting-count" "retargeting-delete" "get-retargeting-id" "retargeting-post" "retargeting-get-datapoints" "retargeting-get-datapoints-count" "tags-get" "tags-put" "tags-count" "tags-delete" "get-tags-tag-id" "tags-delete-related-datapoints" "tags-get-datapoints" "tags-get-datapoints-count" "tags-patch-data-point" "tags-delete-related-groups" "tags-get-groups" "tags-get-groups-count" "tags-patch-group" "tags-patch-tag-name" "commands"] | sort) } | get name | first)
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

# Retrieve current account data
#
# GET /account
# Returns: record<boGoVal: string, bonusClicks: int, companyName: string, companyRole: string, email: string, firstName: string, lastName: string, phone: string, redirectOnly: bool, registrationDate: string, timeframeMinDate: string, timezone: int, timezonename: string>
# operationId: Account_Get
export def "account-get" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/account"
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update current account data
#
# POST /account
# Returns: record<boGoVal: string, bonusClicks: int, companyName: string, companyRole: string, email: string, firstName: string, lastName: string, phone: string, redirectOnly: bool, registrationDate: string, timeframeMinDate: string, timezone: int, timezonename: string>
# operationId: Account_Post
export def "account-post" [
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
  --bo-go-val: string
  --bonus-clicks: int # format: int64
  --company-name: string
  --company-role: string
  --email: string
  --first-name: string
  --last-name: string
  --phone: string
  --redirect-only: oneof<nothing, bool>
  --registration-date: string # (A date in "YmdHis" format) (e.g. 20120203120530)
  --timeframe-min-date: string # (A date in "YmdHis" format) (e.g. 20120203120530)
  --timezone: int # format: int32
  --timezonename: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/account"
    body: {content_type: "application/json", kind: json, fields: [{name: boGoVal, var: bo_go_val}, {name: bonusClicks, var: bonus_clicks}, {name: companyName, var: company_name}, {name: companyRole, var: company_role}, {name: email, var: email}, {name: firstName, var: first_name}, {name: lastName, var: last_name}, {name: phone, var: phone}, {name: redirectOnly, var: redirect_only}, {name: registrationDate, var: registration_date}, {name: timeframeMinDate, var: timeframe_min_date}, {name: timezone, var: timezone}, {name: timezonename, var: timezonename}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    bo_go_val: $bo_go_val, bonus_clicks: $bonus_clicks, company_name: $company_name, company_role: $company_role, email: $email, first_name: $first_name, last_name: $last_name, phone: $phone, redirect_only: $redirect_only, registration_date: $registration_date, timeframe_min_date: $timeframe_min_date, timezone: $timezone, timezonename: $timezonename
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve list of a domains allowed to redirect in DDU mode
#
# GET /account/domainwhitelist
# Returns: record<entities: table<id: string, name: string>>
# operationId: Account_GetDomainWhitelist
export def "account-get-domain-whitelist" [
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
  --offset: int # Offset where to start from (format: int32)
  --limit: int # Limit results to this number (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/account/domainwhitelist"
    query: [{name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create an domain entry
#
# POST /account/domainwhitelist
# Returns: record<id: string, name: string>
# operationId: Account_PutDomainWhitelist
export def "account-put-domain-whitelist" [
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
  --id: string
  --name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/account/domainwhitelist"
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}, {name: name, var: name}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete an domain entry
#
# DELETE /account/domainwhitelist/{whitelistId}
# Returns: record<id: string, name: string>
# operationId: Account_DeleteDomainWhitelist
export def "account-delete-domain-whitelist" [
  whitelist_id: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/account/domainwhitelist/{whitelistId}"
    path_params: [{name: whitelistId, var: whitelist_id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    whitelist_id: $whitelist_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve list of a guest
#
# GET /account/guests
# Returns: record<entities: table<id: int, uri: string>>
# operationId: Account_GetGuests
export def "account-get-guests" [
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
  --offset: int # Offset where to start from (format: int32)
  --limit: int # Limit results to this number (format: int32)
  --sort-by: string # Field to sort by
  --sort-direction: string@sort-direction-completer # Direction of sort "asc" or "desc"
  --text-search: string # Filter fields by this pattern
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/account/guests"
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: sortBy, var: sort_by}, {name: sortDirection, var: sort_direction}, {name: textSearch, var: text_search}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    offset: $offset, limit: $limit, sort_by: $sort_by, sort_direction: $sort_direction, text_search: $text_search
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a guest
#
# POST /account/guests
# Returns: record<apiKey: string, conversionOptions: record<hideComCost: bool, hideCost: bool, hideCount: bool, hideParams: bool, hideValue: bool, percentCommission: int, percentValue: int>, creationDate: string, currentGrant: record<DatapointType: string, Entity: record<id: int, uri: string>, EntityName: string, EntityType: string, Type: string>, dateFormat: string, decimalSeparator: string, email: string, extendedGrants: record<allowAllGrants: bool, allowGroupCreation: bool>, groupGrants: int, hitOptions: record<hideReferrer: bool>, id: int, key: string, language: string, loginCount: int, name: string, notes: string, numberGroupSeparator: string, password: string, timeFormat: string, timeZone: int, timeframeMinDate: string, timezonename: string, tlGrants: int, tpGrants: int, userName: string>
# operationId: Account_PutGuest
export def "account-put-guest" [
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
  --api-key: string
  --conversion-options: record # shape: {hideComCost?: bool, hideCost?: bool, hideCount?: bool, hideParams?: bool, hideValue?: bool, percentCommission?: int, percentValue?: int}
  --creation-date: string # (A date in "YmdHis" format) (e.g. 20120203120530)
  --current-grant: record # shape: {DatapointType?: string, Entity?: record, EntityName?: string, EntityType?: string, Type?: string}
  --date-format: string
  --decimal-separator: string
  --email: string
  --extended-grants: record # shape: {allowAllGrants?: bool, allowGroupCreation?: bool}
  --group-grants: int # format: int64
  --hit-options: record # shape: {hideReferrer?: bool}
  --id: int # format: int64
  --key: string
  --language: string
  --login-count: int # format: int32
  --name: string
  --notes: string
  --number-group-separator: string
  --password: string
  --time-format: string@time-format-completer
  --time-zone: int # format: int32
  --timeframe-min-date: string # (A date in "YmdHis" format) (e.g. 20120203120530)
  --timezonename: string
  --tl-grants: int # format: int64
  --tp-grants: int # format: int64
  --user-name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/account/guests"
    body: {content_type: "application/json", kind: json, fields: [{name: apiKey, var: api_key}, {name: conversionOptions, var: conversion_options}, {name: creationDate, var: creation_date}, {name: currentGrant, var: current_grant}, {name: dateFormat, var: date_format}, {name: decimalSeparator, var: decimal_separator}, {name: email, var: email}, {name: extendedGrants, var: extended_grants}, {name: groupGrants, var: group_grants}, {name: hitOptions, var: hit_options}, {name: id, var: id}, {name: key, var: key}, {name: language, var: language}, {name: loginCount, var: login_count}, {name: name, var: name}, {name: notes, var: notes}, {name: numberGroupSeparator, var: number_group_separator}, {name: password, var: password}, {name: timeFormat, var: time_format}, {name: timeZone, var: time_zone}, {name: timeframeMinDate, var: timeframe_min_date}, {name: timezonename, var: timezonename}, {name: tlGrants, var: tl_grants}, {name: tpGrants, var: tp_grants}, {name: userName, var: user_name}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    api_key: $api_key, conversion_options: $conversion_options, creation_date: $creation_date, current_grant: $current_grant, date_format: $date_format, decimal_separator: $decimal_separator, email: $email, extended_grants: $extended_grants, group_grants: $group_grants, hit_options: $hit_options, id: $id, key: $key, language: $language, login_count: $login_count, name: $name, notes: $notes, number_group_separator: $number_group_separator, password: $password, time_format: $time_format, time_zone: $time_zone, timeframe_min_date: $timeframe_min_date, timezonename: $timezonename, tl_grants: $tl_grants, tp_grants: $tp_grants, user_name: $user_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve count of guests
#
# GET /account/guests/count
# Returns: record<count: int>
# operationId: Account_GetGuestsCount
export def "account-get-guests-count" [
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
  --text-search: string # Filter fields by this pattern
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/account/guests/count"
    query: [{name: textSearch, var: text_search}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    text_search: $text_search
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a guest
#
# DELETE /account/guests/{guestId}
# Returns: record<id: int, uri: string>
# operationId: Account_DeleteGuest
export def "account-delete-guest" [
  guest_id: int
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/account/guests/{guestId}"
    path_params: [{name: guestId, var: guest_id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    guest_id: $guest_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve a guest
#
# GET /account/guests/{guestId}
# Returns: record<apiKey: string, conversionOptions: record<hideComCost: bool, hideCost: bool, hideCount: bool, hideParams: bool, hideValue: bool, percentCommission: int, percentValue: int>, creationDate: string, currentGrant: record<DatapointType: string, Entity: record<id: int, uri: string>, EntityName: string, EntityType: string, Type: string>, dateFormat: string, decimalSeparator: string, email: string, extendedGrants: record<allowAllGrants: bool, allowGroupCreation: bool>, groupGrants: int, hitOptions: record<hideReferrer: bool>, id: int, key: string, language: string, loginCount: int, name: string, notes: string, numberGroupSeparator: string, password: string, timeFormat: string, timeZone: int, timeframeMinDate: string, timezonename: string, tlGrants: int, tpGrants: int, userName: string>
# operationId: Account_GetGuest
export def "account-get-guest" [
  guest_id: int
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/account/guests/{guestId}"
    path_params: [{name: guestId, var: guest_id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    guest_id: $guest_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a guest
#
# POST /account/guests/{guestId}
# Returns: record<apiKey: string, conversionOptions: record<hideComCost: bool, hideCost: bool, hideCount: bool, hideParams: bool, hideValue: bool, percentCommission: int, percentValue: int>, creationDate: string, currentGrant: record<DatapointType: string, Entity: record<id: int, uri: string>, EntityName: string, EntityType: string, Type: string>, dateFormat: string, decimalSeparator: string, email: string, extendedGrants: record<allowAllGrants: bool, allowGroupCreation: bool>, groupGrants: int, hitOptions: record<hideReferrer: bool>, id: int, key: string, language: string, loginCount: int, name: string, notes: string, numberGroupSeparator: string, password: string, timeFormat: string, timeZone: int, timeframeMinDate: string, timezonename: string, tlGrants: int, tpGrants: int, userName: string>
# operationId: Account_PostGuest
export def "account-post-guest" [
  guest_id: int
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
  --api-key: string
  --conversion-options: record # shape: {hideComCost?: bool, hideCost?: bool, hideCount?: bool, hideParams?: bool, hideValue?: bool, percentCommission?: int, percentValue?: int}
  --creation-date: string # (A date in "YmdHis" format) (e.g. 20120203120530)
  --current-grant: record # shape: {DatapointType?: string, Entity?: record, EntityName?: string, EntityType?: string, Type?: string}
  --date-format: string
  --decimal-separator: string
  --email: string
  --extended-grants: record # shape: {allowAllGrants?: bool, allowGroupCreation?: bool}
  --group-grants: int # format: int64
  --hit-options: record # shape: {hideReferrer?: bool}
  --id: int # format: int64
  --key: string
  --language: string
  --login-count: int # format: int32
  --name: string
  --notes: string
  --number-group-separator: string
  --password: string
  --time-format: string@time-format-completer
  --time-zone: int # format: int32
  --timeframe-min-date: string # (A date in "YmdHis" format) (e.g. 20120203120530)
  --timezonename: string
  --tl-grants: int # format: int64
  --tp-grants: int # format: int64
  --user-name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/account/guests/{guestId}"
    path_params: [{name: guestId, var: guest_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: apiKey, var: api_key}, {name: conversionOptions, var: conversion_options}, {name: creationDate, var: creation_date}, {name: currentGrant, var: current_grant}, {name: dateFormat, var: date_format}, {name: decimalSeparator, var: decimal_separator}, {name: email, var: email}, {name: extendedGrants, var: extended_grants}, {name: groupGrants, var: group_grants}, {name: hitOptions, var: hit_options}, {name: id, var: id}, {name: key, var: key}, {name: language, var: language}, {name: loginCount, var: login_count}, {name: name, var: name}, {name: notes, var: notes}, {name: numberGroupSeparator, var: number_group_separator}, {name: password, var: password}, {name: timeFormat, var: time_format}, {name: timeZone, var: time_zone}, {name: timeframeMinDate, var: timeframe_min_date}, {name: timezonename, var: timezonename}, {name: tlGrants, var: tl_grants}, {name: tpGrants, var: tp_grants}, {name: userName, var: user_name}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    guest_id: $guest_id, api_key: $api_key, conversion_options: $conversion_options, creation_date: $creation_date, current_grant: $current_grant, date_format: $date_format, decimal_separator: $decimal_separator, email: $email, extended_grants: $extended_grants, group_grants: $group_grants, hit_options: $hit_options, id: $id, key: $key, language: $language, login_count: $login_count, name: $name, notes: $notes, number_group_separator: $number_group_separator, password: $password, time_format: $time_format, time_zone: $time_zone, timeframe_min_date: $timeframe_min_date, timezonename: $timezonename, tl_grants: $tl_grants, tp_grants: $tp_grants, user_name: $user_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve permissions for a guest
#
# GET /account/guests/{guestId}/permissions
# Returns: record<entities: table<DatapointType: string, Entity: record, EntityName: string, EntityType: string, Type: string>>
# operationId: Account_GetPermissions
export def "account-get-permissions" [
  guest_id: int
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
  --entity-type: string@entity-type-completer # Can be "datapoint" or "group"
  --offset: int # Offset where to start from (format: int32)
  --limit: int # Limit results to this number (format: int32)
  --type: string@type-completer # Can be "w" or "r"
  --entity-id: int # Optional id of the datapoint/group entity to filter by (format: int64)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/account/guests/{guestId}/permissions"
    path_params: [{name: guestId, var: guest_id}]
    query: [{name: entityType, var: entity_type}, {name: offset, var: offset}, {name: limit, var: limit}, {name: type, var: type}, {name: entityId, var: entity_id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    guest_id: $guest_id, entity_type: $entity_type, offset: $offset, limit: $limit, type: $type, entity_id: $entity_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve count of the permissions for a guest
#
# GET /account/guests/{guestId}/permissions/count
# Returns: record<count: int>
# operationId: Account_GetPermissionsCount
export def "account-get-permissions-count" [
  guest_id: int
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
  --entity-type: string@entity-type-completer # Can be "datapoint" or "group"
  --type: string@type-completer # Can be "w" or "r"
  --entity-id: int # Optional id of the datapoint/group entity to filter by (format: int64)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/account/guests/{guestId}/permissions/count"
    path_params: [{name: guestId, var: guest_id}]
    query: [{name: entityType, var: entity_type}, {name: type, var: type}, {name: entityId, var: entity_id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    guest_id: $guest_id, entity_type: $entity_type, type: $type, entity_id: $entity_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Change the permission on a shared object
#
# POST /account/guests/{guestId}/{type}/permissions/patch
# Returns: record<id: int, uri: string>
export def "post-account-guests-guest-id-type-permissions-patch" [
  guest_id: int
  type: string@type-completer-1
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
  --action: string
  --id: int # format: int64
  --verb: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/account/guests/{guestId}/{type}/permissions/patch"
    path_params: [{name: guestId, var: guest_id}, {name: type, var: type}]
    body: {content_type: "application/json", kind: json, fields: [{name: Action, var: action}, {name: Id, var: id}, {name: Verb, var: verb}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    guest_id: $guest_id, type: $type, action: $action, id: $id, verb: $verb
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Change the permission on a shared object
#
# PUT /account/guests/{guestId}/{type}/permissions/patch
# Returns: record<id: int, uri: string>
# operationId: Account_PatchPermissions
export def "account-patch-permissions" [
  guest_id: int
  type: string@type-completer-1
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
  --action: string
  --id: int # format: int64
  --verb: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/account/guests/{guestId}/{type}/permissions/patch"
    path_params: [{name: guestId, var: guest_id}, {name: type, var: type}]
    body: {content_type: "application/json", kind: json, fields: [{name: Action, var: action}, {name: Id, var: id}, {name: Verb, var: verb}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    guest_id: $guest_id, type: $type, action: $action, id: $id, verb: $verb
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve list of a ip to exclude from event tracking
#
# GET /account/ipblacklist
# Returns: record<entities: table<id: string, ip: string>>
# operationId: Account_GetIpBlacklist
export def "account-get-ip-blacklist" [
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
  --offset: int # Offset where to start from (format: int32)
  --limit: int # Limit results to this number (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/account/ipblacklist"
    query: [{name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create an ip blacklist entry
#
# POST /account/ipblacklist
# Returns: record<id: string, ip: string>
# operationId: Account_PutIpBlacklist
export def "account-put-ip-blacklist" [
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
  --id: string
  --ip: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/account/ipblacklist"
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}, {name: ip, var: ip}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    id: $id, ip: $ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete an ip blacklist entry
#
# DELETE /account/ipblacklist/{blacklistId}
# Returns: record<id: string, ip: string>
# operationId: Account_DeleteIpBlacklist
export def "account-delete-ip-blacklist" [
  blacklist_id: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/account/ipblacklist/{blacklistId}"
    path_params: [{name: blacklistId, var: blacklist_id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    blacklist_id: $blacklist_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve current account plan
#
# GET /account/plan
# Returns: record<allowedPersonalDomains: int, allowedPersonalUrls: int, billingPeriodEnd: string, billingPeriodStart: string, bonusMonthlyEvents: int, maximumDatapoints: int, maximumGuests: int, monthlyEvents: int, name: string, price: float, profileId: int, recurring: bool, recurringPeriod: int, usedDatapoints: int, usedMonthlyEvents: int>
# operationId: Account_GetPlan
export def "account-get-plan" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/account/plan"
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve statistics about this customer for a timeframe
#
# GET /aggregated
# Returns: record<activityDay: string, commissionsCost: float, conversionsCost: float, conversionsValue: float, convertedClicks: int, entityData: record, entityId: string, fromDay: string, hourlyBreakDown: record, lastHitDate: string, spiderHitsCount: int, toDay: string, totalClicks: int, totalViews: int, uniqueClicks: int, uniqueConversions: int, uniqueViews: int>
# operationId: Aggregated_GetStatisticsSingle
export def "aggregated-get-statistics-single" [
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
  --time-frame: string@time-frame-completer # Timeframe of the request. See list at $timeframeList (required)
  --from-day: string # If using a "custom" timeFrame you can specify the starting day (YYYYMMDD)
  --to-day: string # If using a "custom" timeFrame you can specify the ending day (YYYYMMDD)
  --hourly: oneof<nothing, bool> # If using "yesterday" or "today" timeframe you can ask for the hourly detail
  --only-favorites: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/aggregated"
    query: [{name: timeFrame, var: time_frame, required: true}, {name: fromDay, var: from_day}, {name: toDay, var: to_day}, {name: hourly, var: hourly}, {name: onlyFavorites, var: only_favorites}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    time_frame: $time_frame, from_day: $from_day, to_day: $to_day, hourly: $hourly, only_favorites: $only_favorites
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve statistics about this customer for a timeframe grouped by some temporal entity (day/week/month)
#
# GET /aggregated/list
# Returns: record<entities: table<activityDay: string, commissionsCost: float, conversionsCost: float, conversionsValue: float, convertedClicks: int, entityData: record, entityId: string, fromDay: string, hourlyBreakDown: record, lastHitDate: string, spiderHitsCount: int, toDay: string, totalClicks: int, totalViews: int, uniqueClicks: int, uniqueConversions: int, uniqueViews: int>>
# operationId: Aggregated_GetStatisticsList
export def "aggregated-get-statistics-list" [
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
  --time-frame: string@time-frame-completer # Timeframe of the request. See list at $timeframeList (required)
  --from-day: string # If using a "custom" timeFrame you can specify the starting day (YYYYMMDD)
  --to-day: string # If using a "custom" timeFrame you can specify the ending day (YYYYMMDD)
  --group-by: string@group-by-completer # The temporal entity you want to group by ("week"/"month"). If unspecified is "day".
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/aggregated/list"
    query: [{name: timeFrame, var: time_frame, required: true}, {name: fromDay, var: from_day}, {name: toDay, var: to_day}, {name: groupBy, var: group_by}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    time_frame: $time_frame, from_day: $from_day, to_day: $to_day, group_by: $group_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve statistics about a subset of conversions for a timeframe with conversions data
#
# GET /aggregated/summary/conversions
# Returns: record<count: int, limit: int, offset: int, result: table<activityDay: string, commissionsCost: float, conversionsCost: float, conversionsValue: float, convertedClicks: int, entityData: record, entityId: string, fromDay: string, hourlyBreakDown: record, lastHitDate: string, spiderHitsCount: int, toDay: string, totalClicks: int, totalViews: int, uniqueClicks: int, uniqueConversions: int, uniqueViews: int>>
# operationId: Aggregated_GetConversionsSummary
export def "aggregated-get-conversions-summary" [
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
  --time-frame: string@time-frame-completer # Timeframe of the request. See list at $timeframeList (required)
  --from-day: string # If using a "custom" timeFrame you can specify the starting day (YYYYMMDD)
  --to-day: string # If using a "custom" timeFrame you can specify the ending day (YYYYMMDD)
  --status: string@status-completer # Status of conversion ("deleted"/"active")
  --sort-by: string # Field to sort by
  --sort-direction: string@sort-direction-completer # Direction of sort "asc" or "desc"
  --offset: int # Offset where to start from (format: int32)
  --limit: int # Limit results to this number (format: int32)
  --text-search: string # Filter fields by this pattern
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/aggregated/summary/conversions"
    query: [{name: timeFrame, var: time_frame, required: true}, {name: fromDay, var: from_day}, {name: toDay, var: to_day}, {name: status, var: status}, {name: sortBy, var: sort_by}, {name: sortDirection, var: sort_direction}, {name: offset, var: offset}, {name: limit, var: limit}, {name: textSearch, var: text_search}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    time_frame: $time_frame, from_day: $from_day, to_day: $to_day, status: $status, sort_by: $sort_by, sort_direction: $sort_direction, offset: $offset, limit: $limit, text_search: $text_search
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve statistics about a subset of datapoints for a timeframe with datapoints data
#
# GET /aggregated/summary/datapoints
# Returns: record<count: int, limit: int, offset: int, result: table<activityDay: string, commissionsCost: float, conversionsCost: float, conversionsValue: float, convertedClicks: int, entityData: record, entityId: string, fromDay: string, hourlyBreakDown: record, lastHitDate: string, spiderHitsCount: int, toDay: string, totalClicks: int, totalViews: int, uniqueClicks: int, uniqueConversions: int, uniqueViews: int>>
# operationId: Aggregated_GetDatapointsSummary
export def "aggregated-get-datapoints-summary" [
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
  --time-frame: string@time-frame-completer # Timeframe of the request. See list at $timeframeList (required)
  --type: string@type-completer-2 # Type of datapoint ("tl"/"tp") (required)
  --from-day: string # If using a "custom" timeFrame you can specify the starting day (YYYYMMDD)
  --to-day: string # If using a "custom" timeFrame you can specify the ending day (YYYYMMDD)
  --status: string@status-completer-1 # Status of datapoint ("deleted"/"active"/"paused"/"spam")
  --tag: string # A comma separated list of tags you want to filter with.
  --favourite: oneof<nothing, bool> # Is the datapoint marked as favourite
  --sort-by: string # Field to sort by
  --sort-direction: string@sort-direction-completer # Direction of sort "asc" or "desc"
  --offset: int # Offset where to start from (format: int32)
  --limit: int # Limit results to this number (format: int32)
  --group-id: int # Filter by this group id (format: int64)
  --text-search: string # Filter fields by this pattern
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/aggregated/summary/datapoints"
    query: [{name: timeFrame, var: time_frame, required: true}, {name: type, var: type, required: true}, {name: fromDay, var: from_day}, {name: toDay, var: to_day}, {name: status, var: status}, {name: tag, var: tag}, {name: favourite, var: favourite}, {name: sortBy, var: sort_by}, {name: sortDirection, var: sort_direction}, {name: offset, var: offset}, {name: limit, var: limit}, {name: groupId, var: group_id}, {name: textSearch, var: text_search}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    time_frame: $time_frame, type: $type, from_day: $from_day, to_day: $to_day, status: $status, tag: $tag, favourite: $favourite, sort_by: $sort_by, sort_direction: $sort_direction, offset: $offset, limit: $limit, group_id: $group_id, text_search: $text_search
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve statistics about a subset of groups for a timeframe with groups data
#
# GET /aggregated/summary/groups
# Returns: record<count: int, limit: int, offset: int, result: table<activityDay: string, commissionsCost: float, conversionsCost: float, conversionsValue: float, convertedClicks: int, entityData: record, entityId: string, fromDay: string, hourlyBreakDown: record, lastHitDate: string, spiderHitsCount: int, toDay: string, totalClicks: int, totalViews: int, uniqueClicks: int, uniqueConversions: int, uniqueViews: int>>
# operationId: Aggregated_GetGroupsSummary
export def "aggregated-get-groups-summary" [
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
  --time-frame: string@time-frame-completer # Timeframe of the request. See list at $timeframeList (required)
  --from-day: string # If using a "custom" timeFrame you can specify the starting day (YYYYMMDD)
  --to-day: string # If using a "custom" timeFrame you can specify the ending day (YYYYMMDD)
  --status: string@status-completer # Status of group ("deleted"/"active")
  --tag: string # A comma separated list of tags you want to filter with.
  --favourite: oneof<nothing, bool> # Is the group marked as favourite
  --sort-by: string # Field to sort by
  --sort-direction: string@sort-direction-completer # Direction of sort "asc" or "desc"
  --offset: int # Offset where to start from (format: int32)
  --limit: int # Limit results to this number (format: int32)
  --text-search: string # Filter fields by this pattern
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/aggregated/summary/groups"
    query: [{name: timeFrame, var: time_frame, required: true}, {name: fromDay, var: from_day}, {name: toDay, var: to_day}, {name: status, var: status}, {name: tag, var: tag}, {name: favourite, var: favourite}, {name: sortBy, var: sort_by}, {name: sortDirection, var: sort_direction}, {name: offset, var: offset}, {name: limit, var: limit}, {name: textSearch, var: text_search}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    time_frame: $time_frame, from_day: $from_day, to_day: $to_day, status: $status, tag: $tag, favourite: $favourite, sort_by: $sort_by, sort_direction: $sort_direction, offset: $offset, limit: $limit, text_search: $text_search
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve the latest list of events of this account. Limited to last 100.
#
# GET /clickstream
# Returns: record<entities: table<accessTime: string, browser: record, clientLanguage: string, conversion1: record, conversion2: record, conversion3: record, conversion4: record, conversion5: record, conversions: list, entity: record, ip: string, isProxy: string, isSpider: string, isUnique: string, location: record, org: string, os: record, queryParams: string, realDestinationUrl: string, referer: string, source: record, type: string>>
# operationId: ClickStream_Get
export def "click-stream-get" [
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
  --group: int # Filter by this group id (mutually exclusive with "datapoint" and "conversion") (format: int64)
  --datapoint: int # Filter by this datapoint id (mutually exclusive with "group" and "conversion") (format: int64)
  --conversion: int # Filter by this conversion id (mutually exclusive with "datapoint" and "group") (format: int64)
  --page-size: int # Limit results to this number (format: int32, default: 50)
  --filter: string@filter-completer # Filter event type ("spiders"/"uniques"/"nonuniques"/"conversions")
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/clickstream"
    query: [{name: group, var: group}, {name: datapoint, var: datapoint}, {name: conversion, var: conversion}, {name: pageSize, var: page_size}, {name: filter, var: filter}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    group: $group, datapoint: $datapoint, conversion: $conversion, page_size: $page_size, filter: $filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve a list of conversions
#
# GET /conversions
# Returns: record<entities: table<id: int, uri: string>>
# operationId: Conversions_Get
export def "conversions-get" [
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
  --offset: int # Offset where to start from (format: int32)
  --limit: int # Limit results to this number (format: int32)
  --status: string@status-completer # Status of conversion ("deleted"/"active")
  --text-search: string # Filter fields by this pattern
  --created-after: string # Exclude conversions created before this date (YYYYMMDD)
  --created-before: string # Exclude conversions created after this date (YYYYMMDD)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/conversions"
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: status, var: status}, {name: textSearch, var: text_search}, {name: createdAfter, var: created_after}, {name: createdBefore, var: created_before}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    offset: $offset, limit: $limit, status: $status, text_search: $text_search, created_after: $created_after, created_before: $created_before
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a conversion
#
# POST /conversions
# Returns: record<id: int, uri: string>
# operationId: Conversions_Put
export def "conversions-put" [
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
  --code: string
  --creation-date: string # (A date in "YmdHis" format) (e.g. 20120203120530)
  --deleted: oneof<nothing, bool>
  --description: string
  --id: int # format: int64
  --name: string
  --protocol: string@protocol-completer
  --value: float # format: double
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/conversions"
    body: {content_type: "application/json", kind: json, fields: [{name: code, var: code}, {name: creationDate, var: creation_date}, {name: deleted, var: deleted}, {name: description, var: description}, {name: id, var: id}, {name: name, var: name}, {name: protocol, var: protocol}, {name: value, var: value}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    code: $code, creation_date: $creation_date, deleted: $deleted, description: $description, id: $id, name: $name, protocol: $protocol, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve statistics about this customer for a timeframe related to a subset of conversions grouped by some temporal entity (day/week/month)
#
# GET /conversions/aggregated/list
# Returns: record<entities: table<activityDay: string, commissionsCost: float, conversionsCost: float, conversionsValue: float, convertedClicks: int, entityData: record, entityId: string, fromDay: string, hourlyBreakDown: record, lastHitDate: string, spiderHitsCount: int, toDay: string, totalClicks: int, totalViews: int, uniqueClicks: int, uniqueConversions: int, uniqueViews: int>>
# operationId: Conversions_GetStatisticsAllList
export def "conversions-get-statistics-all-list" [
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
  --time-frame: string@time-frame-completer # Timeframe of the request. See list at $timeframeList (required)
  --from-day: string # If using a "custom" timeFrame you can specify the starting day (YYYYMMDD)
  --to-day: string # If using a "custom" timeFrame you can specify the ending day (YYYYMMDD)
  --status: string@status-completer # Status of conversion ("deleted"/"active")
  --group-by: string@group-by-completer # The temporal entity you want to group by ("week"/"month"). If unspecified is "day".
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/conversions/aggregated/list"
    query: [{name: timeFrame, var: time_frame, required: true}, {name: fromDay, var: from_day}, {name: toDay, var: to_day}, {name: status, var: status}, {name: groupBy, var: group_by}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    time_frame: $time_frame, from_day: $from_day, to_day: $to_day, status: $status, group_by: $group_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve a count of conversions
#
# GET /conversions/count
# Returns: record<count: int>
# operationId: Conversions_Count
export def "conversions-count" [
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
  --status: string@status-completer # Status of conversion ("deleted"/"active")
  --text-search: string # Filter fields by this pattern
  --created-after: string # Exclude conversions created before this date (YYYYMMDD)
  --created-before: string # Exclude conversions created after this date (YYYYMMDD)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/conversions/count"
    query: [{name: status, var: status}, {name: textSearch, var: text_search}, {name: createdAfter, var: created_after}, {name: createdBefore, var: created_before}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    status: $status, text_search: $text_search, created_after: $created_after, created_before: $created_before
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete conversion specified by id
#
# DELETE /conversions/{conversionId}
# Returns: record<id: int, uri: string>
# operationId: Conversions_Delete
export def "conversions-delete" [
  conversion_id: int
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/conversions/{conversionId}"
    path_params: [{name: conversionId, var: conversion_id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    conversion_id: $conversion_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve conversion specified by id
#
# GET /conversions/{conversionId}
# Returns: record<code: string, creationDate: string, deleted: bool, description: string, id: int, name: string, protocol: string, value: float>
export def "get-conversions-conversion-id" [
  conversion_id: int
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/conversions/{conversionId}"
    path_params: [{name: conversionId, var: conversion_id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    conversion_id: $conversion_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update conversion specified by id
#
# POST /conversions/{conversionId}
# Returns: record<id: int, uri: string>
# operationId: Conversions_Post
export def "conversions-post" [
  conversion_id: int
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
  --code: string
  --creation-date: string # (A date in "YmdHis" format) (e.g. 20120203120530)
  --deleted: oneof<nothing, bool>
  --description: string
  --id: int # format: int64
  --name: string
  --protocol: string@protocol-completer
  --value: float # format: double
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/conversions/{conversionId}"
    path_params: [{name: conversionId, var: conversion_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: code, var: code}, {name: creationDate, var: creation_date}, {name: deleted, var: deleted}, {name: description, var: description}, {name: id, var: id}, {name: name, var: name}, {name: protocol, var: protocol}, {name: value, var: value}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    conversion_id: $conversion_id, code: $code, creation_date: $creation_date, deleted: $deleted, description: $description, id: $id, name: $name, protocol: $protocol, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve statistics about this conversion for a timeframe
#
# GET /conversions/{conversionId}/aggregated
# Returns: record<activityDay: string, commissionsCost: float, conversionsCost: float, conversionsValue: float, convertedClicks: int, entityData: record, entityId: string, fromDay: string, hourlyBreakDown: record, lastHitDate: string, spiderHitsCount: int, toDay: string, totalClicks: int, totalViews: int, uniqueClicks: int, uniqueConversions: int, uniqueViews: int>
# operationId: Conversions_GetStatisticsSingle
export def "conversions-get-statistics-single" [
  conversion_id: int
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
  --time-frame: string@time-frame-completer # Timeframe of the request. See list at $timeframeList (required)
  --from-day: string # If using a "custom" timeFrame you can specify the starting day (YYYYMMDD)
  --to-day: string # If using a "custom" timeFrame you can specify the ending day (YYYYMMDD)
  --tag: string # Filter by this tag name
  --favourite: oneof<nothing, bool> # Is the datapoint marked as favourite
  --hourly: oneof<nothing, bool> # If using "yesterday" or "today" timeframe you can ask for the hourly detail
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/conversions/{conversionId}/aggregated"
    path_params: [{name: conversionId, var: conversion_id}]
    query: [{name: timeFrame, var: time_frame, required: true}, {name: fromDay, var: from_day}, {name: toDay, var: to_day}, {name: tag, var: tag}, {name: favourite, var: favourite}, {name: hourly, var: hourly}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    conversion_id: $conversion_id, time_frame: $time_frame, from_day: $from_day, to_day: $to_day, tag: $tag, favourite: $favourite, hourly: $hourly
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve statistics about this conversion for a timeframe grouped by some temporal entity (day/week/month)
#
# GET /conversions/{conversionId}/aggregated/list
# Returns: record<entities: table<activityDay: string, commissionsCost: float, conversionsCost: float, conversionsValue: float, convertedClicks: int, entityData: record, entityId: string, fromDay: string, hourlyBreakDown: record, lastHitDate: string, spiderHitsCount: int, toDay: string, totalClicks: int, totalViews: int, uniqueClicks: int, uniqueConversions: int, uniqueViews: int>>
# operationId: Conversions_GetStatisticsList
export def "conversions-get-statistics-list" [
  conversion_id: int
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
  --time-frame: string@time-frame-completer # Timeframe of the request. See list at $timeframeList (required)
  --from-day: string # If using a "custom" timeFrame you can specify the starting day (YYYYMMDD)
  --to-day: string # If using a "custom" timeFrame you can specify the ending day (YYYYMMDD)
  --group-by: string@group-by-completer # The temporal entity you want to group by ("week"/"month"). If unspecified is "day".
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/conversions/{conversionId}/aggregated/list"
    path_params: [{name: conversionId, var: conversion_id}]
    query: [{name: timeFrame, var: time_frame, required: true}, {name: fromDay, var: from_day}, {name: toDay, var: to_day}, {name: groupBy, var: group_by}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    conversion_id: $conversion_id, time_frame: $time_frame, from_day: $from_day, to_day: $to_day, group_by: $group_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve a list of datapoints connected to this conversion
#
# GET /conversions/{conversionId}/datapoints
# Returns: record<entities: table<id: int, uri: string>>
# operationId: Conversions_GetDatapoints
export def "conversions-get-datapoints" [
  conversion_id: int
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
  --offset: int # Offset where to start from (format: int32)
  --limit: int # Limit results to this number (format: int32)
  --type: string@type-completer-2 # Type of datapoint ("tl"/"tp")
  --status: string@status-completer-1 # Status of datapoint ("deleted"/"active"/"paused"/"spam")
  --tags: string # Filter by this tag name
  --text-search: string # Filter fields by this pattern
  --created-after: string # Exclude datapoints created before this date (YYYYMMDD)
  --created-before: string # Exclude datapoints created after this date (YYYYMMDD)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/conversions/{conversionId}/datapoints"
    path_params: [{name: conversionId, var: conversion_id}]
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: type, var: type}, {name: status, var: status}, {name: tags, var: tags}, {name: textSearch, var: text_search}, {name: createdAfter, var: created_after}, {name: createdBefore, var: created_before}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    conversion_id: $conversion_id, offset: $offset, limit: $limit, type: $type, status: $status, tags: $tags, text_search: $text_search, created_after: $created_after, created_before: $created_before
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Modify the association between a conversion and multiple datapoints
#
# PUT /conversions/{conversionId}/datapoints/batch/patch
# Returns: record<id: int, uri: string>
export def "put-conversions-conversion-id-datapoints-batch-patch" [
  conversion_id: int
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
  --patch-requests: list # item shape: {Action?: string, Id?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/conversions/{conversionId}/datapoints/batch/patch"
    path_params: [{name: conversionId, var: conversion_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: PatchRequests, var: patch_requests}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    conversion_id: $conversion_id, patch_requests: $patch_requests
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve a count of datapoints connected to this conversion
#
# GET /conversions/{conversionId}/datapoints/count
# Returns: record<count: int>
# operationId: Conversions_GetDatapointsCount
export def "conversions-get-datapoints-count" [
  conversion_id: int
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
  --type: string # Type of datapoint ("tl"/"tp")
  --status: string # Status of datapoint ("deleted"/"active"/"paused"/"spam")
  --tags: string # Filter by this tag name
  --text-search: string # Filter fields by this pattern
  --created-after: string # Exclude datapoints created before this date (YYYYMMDD)
  --created-before: string # Exclude datapoints created after this date (YYYYMMDD)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/conversions/{conversionId}/datapoints/count"
    path_params: [{name: conversionId, var: conversion_id}]
    query: [{name: type, var: type}, {name: status, var: status}, {name: tags, var: tags}, {name: textSearch, var: text_search}, {name: createdAfter, var: created_after}, {name: createdBefore, var: created_before}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    conversion_id: $conversion_id, type: $type, status: $status, tags: $tags, text_search: $text_search, created_after: $created_after, created_before: $created_before
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Modify the association between a conversion and a datapoint
#
# PUT /conversions/{conversionId}/datapoints/patch
# Returns: record<id: int, uri: string>
# operationId: Conversions_Patch
export def "conversions-patch" [
  conversion_id: int
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
  --action: string
  --id: int # format: int64
  --replace-id: int # format: int64
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/conversions/{conversionId}/datapoints/patch"
    path_params: [{name: conversionId, var: conversion_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Action, var: action}, {name: Id, var: id}, {name: ReplaceId, var: replace_id}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    conversion_id: $conversion_id, action: $action, id: $id, replace_id: $replace_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve the list of events related to this conversion.
#
# GET /conversions/{conversionId}/hits
# Returns: record<hits: table<accessTime: string, browser: record, clientLanguage: string, conversion1: record, conversion2: record, conversion3: record, conversion4: record, conversion5: record, conversions: list, entity: record, ip: string, isProxy: string, isSpider: string, isUnique: string, location: record, org: string, os: record, queryParams: string, realDestinationUrl: string, referer: string, source: record, type: string>, lastKey: string>
# operationId: Conversions_GetHits
export def "conversions-get-hits" [
  conversion_id: int
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
  --timeframe: string@timeframe-completer # Timeframe of the request. See list at $timeframeList (required)
  --limit: int # Limit results to this number (format: int32)
  --offset: string # Offset where to start from (it's the lastKey field in the response object)
  --from-day: string # If using a "custom" timeFrame you can specify the starting day (YYYYMMDD)
  --to-day: string # If using a "custom" timeFrame you can specify the ending day (YYYYMMDD)
  --filter: string@filter-completer-1 # Filter event type ("spiders"/"uniques"/"nonuniques"/"conversions")
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/conversions/{conversionId}/hits"
    path_params: [{name: conversionId, var: conversion_id}]
    query: [{name: timeframe, var: timeframe, required: true}, {name: limit, var: limit}, {name: offset, var: offset}, {name: fromDay, var: from_day}, {name: toDay, var: to_day}, {name: filter, var: filter}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    conversion_id: $conversion_id, timeframe: $timeframe, limit: $limit, offset: $offset, from_day: $from_day, to_day: $to_day, filter: $filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Fast patch the "notes" field of a conversion
#
# PUT /conversions/{conversionId}/notes
# Returns: record<id: int, uri: string>
# operationId: Conversions_PatchNotes
export def "conversions-patch-notes" [
  conversion_id: int
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
  --text: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/conversions/{conversionId}/notes"
    path_params: [{name: conversionId, var: conversion_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Text, var: text}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    conversion_id: $conversion_id, text: $text
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List of all the datapoints associated to the user
#
# GET /datapoints
# Returns: record<entities: table<id: int, uri: string>>
# operationId: DataPoints_Get
export def "data-points-get" [
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
  --offset: int # Where to start when retrieving elements. Default is 0 if not specified. (format: int32, default: 0)
  --limit: int # Maximum elements to retrieve. Default to 20 if not specified. (format: int32, default: 20)
  --type: string@type-completer-2 # Type of the datapoint ("tp"/"tl")
  --status: string@status-completer-1 # Status of the datapoint
  --tags: string # A comma separated list of tags you want to filter with.
  --text-search: string # Filter fields by this pattern
  --only-favorites: oneof<nothing, bool> # Filter fields by favourite status
  --sort-by: string # Field to sort by
  --sort-direction: string@sort-direction-completer # Direction of sort "asc" or "desc"
  --created-after: string # Exclude datapoints created before this date (YYYYMMDD)
  --created-before: string # Exclude datapoints created after this date (YYYYMMDD)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/datapoints"
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: type, var: type}, {name: status, var: status}, {name: tags, var: tags}, {name: textSearch, var: text_search}, {name: onlyFavorites, var: only_favorites}, {name: sortBy, var: sort_by}, {name: sortDirection, var: sort_direction}, {name: createdAfter, var: created_after}, {name: createdBefore, var: created_before}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    offset: $offset, limit: $limit, type: $type, status: $status, tags: $tags, text_search: $text_search, only_favorites: $only_favorites, sort_by: $sort_by, sort_direction: $sort_direction, created_after: $created_after, created_before: $created_before
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a datapoint
#
# POST /datapoints
# Returns: record<id: int, uri: string>
# operationId: DataPoints_Put
export def "data-points-put" [
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
  --creation-date: string # (A date in "YmdHis" format) (e.g. 20120203120530)
  --encode-ip: oneof<nothing, bool>
  --fifth-conversion-id: int # format: int64
  --fifth-conversion-name: string
  --first-conversion-id: int # format: int64
  --first-conversion-name: string
  --fourth-conversion-id: int # format: int64
  --fourth-conversion-name: string
  --group-id: int # format: int64
  --group-name: string
  --id: int # format: int64
  --is-public: oneof<nothing, bool>
  --is-secured: oneof<nothing, bool>
  --light-tracking: oneof<nothing, bool>
  --name: string
  --notes: string
  --preferred: oneof<nothing, bool>
  --redirect-only: oneof<nothing, bool>
  --second-conversion-id: int # format: int64
  --second-conversion-name: string
  --status: string@status-completer-2
  --tags: list # item shape: {datapoints?: list<int>, groups?: list<int>, id?: int, name?: string}
  --third-conversion-id: int # format: int64
  --third-conversion-name: string
  --title: string
  --tracking-code: string
  --type: string@type-completer-3
  --type-tl: record # shape: {appendQuery?: bool, browserDestinationItem?: record, destinationMode?: "Simple"|"RandomDestination"|"DestinationByLanguage"|"SpilloverDestination"|"DynamicUrl"|"BrowserDestination"|"DestinationByNation"|"UniqueDestination"|"SequentialDestination"|"WeightedDestination", domainId?: int, encodeUrl?: bool, expirationClicks?: int, expirationDate?: string, firstUrl?: string, goDomainId?: int, hideUrl?: bool, hideUrlTitle?: string, isABTest?: bool, password?: string, pauseAfterClicksExpiration?: bool, ... (14 more fields)}
  --type-tp: record # shape: {parameterNote?: string}
  --write-permited: oneof<nothing, bool>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/datapoints"
    body: {content_type: "application/json", kind: json, fields: [{name: creationDate, var: creation_date}, {name: encodeIp, var: encode_ip}, {name: fifthConversionId, var: fifth_conversion_id}, {name: fifthConversionName, var: fifth_conversion_name}, {name: firstConversionId, var: first_conversion_id}, {name: firstConversionName, var: first_conversion_name}, {name: fourthConversionId, var: fourth_conversion_id}, {name: fourthConversionName, var: fourth_conversion_name}, {name: groupId, var: group_id}, {name: groupName, var: group_name}, {name: id, var: id}, {name: isPublic, var: is_public}, {name: isSecured, var: is_secured}, {name: lightTracking, var: light_tracking}, {name: name, var: name}, {name: notes, var: notes}, {name: preferred, var: preferred}, {name: redirectOnly, var: redirect_only}, {name: secondConversionId, var: second_conversion_id}, {name: secondConversionName, var: second_conversion_name}, {name: status, var: status}, {name: tags, var: tags}, {name: thirdConversionId, var: third_conversion_id}, {name: thirdConversionName, var: third_conversion_name}, {name: title, var: title}, {name: trackingCode, var: tracking_code}, {name: type, var: type}, {name: typeTL, var: type_tl}, {name: typeTP, var: type_tp}, {name: writePermited, var: write_permited}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    creation_date: $creation_date, encode_ip: $encode_ip, fifth_conversion_id: $fifth_conversion_id, fifth_conversion_name: $fifth_conversion_name, first_conversion_id: $first_conversion_id, first_conversion_name: $first_conversion_name, fourth_conversion_id: $fourth_conversion_id, fourth_conversion_name: $fourth_conversion_name, group_id: $group_id, group_name: $group_name, id: $id, is_public: $is_public, is_secured: $is_secured, light_tracking: $light_tracking, name: $name, notes: $notes, preferred: $preferred, redirect_only: $redirect_only, second_conversion_id: $second_conversion_id, second_conversion_name: $second_conversion_name, status: $status, tags: $tags, third_conversion_id: $third_conversion_id, third_conversion_name: $third_conversion_name, title: $title, tracking_code: $tracking_code, type: $type, type_tl: $type_tl, type_tp: $type_tp, write_permited: $write_permited
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve statistics about this customer for a timeframe by groups
#
# GET /datapoints/aggregated
# Returns: record<activityDay: string, commissionsCost: float, conversionsCost: float, conversionsValue: float, convertedClicks: int, entityData: record, entityId: string, fromDay: string, hourlyBreakDown: record, lastHitDate: string, spiderHitsCount: int, toDay: string, totalClicks: int, totalViews: int, uniqueClicks: int, uniqueConversions: int, uniqueViews: int>
# operationId: DataPoints_GetStatisticsAggregatedSingle
export def "data-points-get-statistics-aggregated-single" [
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
  --time-frame: string@time-frame-completer # Timeframe of the request. See list at $timeframeList (required)
  --type: string@type-completer-2 # Type of datapoint ("tl"/"tp")
  --from-day: string # If using a "custom" timeFrame you can specify the starting day (YYYYMMDD)
  --to-day: string # If using a "custom" timeFrame you can specify the ending day (YYYYMMDD)
  --hourly: oneof<nothing, bool> # If using "yesterday" or "today" timeframe you can ask for the hourly detail
  --status: string@status-completer-1 # Status of datapoint ("deleted"/"active"/"paused"/"spam")
  --tag: string # A comma separated list of tags you want to filter with.
  --favourite: oneof<nothing, bool> # Is the datapoint is marked as favourite
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/datapoints/aggregated"
    query: [{name: timeFrame, var: time_frame, required: true}, {name: type, var: type}, {name: fromDay, var: from_day}, {name: toDay, var: to_day}, {name: hourly, var: hourly}, {name: status, var: status}, {name: tag, var: tag}, {name: favourite, var: favourite}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    time_frame: $time_frame, type: $type, from_day: $from_day, to_day: $to_day, hourly: $hourly, status: $status, tag: $tag, favourite: $favourite
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve statistics about all datapoints of this customer for a timeframe grouped by some temporal entity (day/week/month)
#
# GET /datapoints/aggregated/list
# Returns: record<entities: table<activityDay: string, commissionsCost: float, conversionsCost: float, conversionsValue: float, convertedClicks: int, entityData: record, entityId: string, fromDay: string, hourlyBreakDown: record, lastHitDate: string, spiderHitsCount: int, toDay: string, totalClicks: int, totalViews: int, uniqueClicks: int, uniqueConversions: int, uniqueViews: int>>
# operationId: DataPoints_GetStatisticsAllList
export def "data-points-get-statistics-all-list" [
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
  --type: string@type-completer-2 # Type of datapoint ("tl"/"tp") (required)
  --time-frame: string@time-frame-completer # Timeframe of the request. See list at $timeframeList (required)
  --from-day: string # If using a "custom" timeFrame you can specify the starting day (YYYYMMDD)
  --to-day: string # If using a "custom" timeFrame you can specify the ending day (YYYYMMDD)
  --status: string@status-completer-1 # Status of datapoint ("deleted"/"active"/"paused"/"spam")
  --tag: string # A comma separated list of tags you want to filter with.
  --favourite: oneof<nothing, bool> # Is the datapoint is marked as favourite
  --group-by: string@group-by-completer # The temporal entity you want to group by ("week"/"month"). If unspecified is "day".
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/datapoints/aggregated/list"
    query: [{name: type, var: type, required: true}, {name: timeFrame, var: time_frame, required: true}, {name: fromDay, var: from_day}, {name: toDay, var: to_day}, {name: status, var: status}, {name: tag, var: tag}, {name: favourite, var: favourite}, {name: groupBy, var: group_by}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    type: $type, time_frame: $time_frame, from_day: $from_day, to_day: $to_day, status: $status, tag: $tag, favourite: $favourite, group_by: $group_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete multiple datapoints
#
# DELETE /datapoints/batch
# Returns: record<entityData: record<creationDate: string, encodeIp: bool, fifthConversionId: int, fifthConversionName: string, firstConversionId: int, firstConversionName: string, fourthConversionId: int, fourthConversionName: string, groupId: int, groupName: string, id: int, isPublic: bool, isSecured: bool, lightTracking: bool, name: string, notes: string, preferred: bool, redirectOnly: bool, secondConversionId: int, secondConversionName: string, status: string, tags: list<record>, thirdConversionId: int, thirdConversionName: string, title: string, trackingCode: string, type: string, typeTL: record<appendQuery: bool, browserDestinationItem: record, destinationMode: string, domainId: int, encodeUrl: bool, expirationClicks: int, expirationDate: string, firstUrl: string, goDomainId: int, hideUrl: bool, hideUrlTitle: string, isABTest: bool, password: string, pauseAfterClicksExpiration: bool, pauseAfterDateExpiration: bool, randomDestinationItems: list, redirectType: string, referrerClean: string, scripts: list, sequentialDestinationItems: list, spilloverDestinationItems: list, uniqueDestinationItem: record, url: string, urlAfterClicksExpiration: string, urlAfterDateExpiration: string, urlsByLanguage: list, urlsByNation: list, weightedDestinationItems: list>, typeTP: record<parameterNote: string>, writePermited: bool>, errors: table<code: record, errorMessage: string, errorValue: record, property: string>, result: record<id: int, uri: string>, status: string>
# operationId: DataPoints_BatchDelete
export def "data-points-batch-delete" [
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
  --entities: list # item shape: {id?: int, uri?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: delete
    path: "/datapoints/batch"
    body: {content_type: "application/json", kind: json, fields: [{name: Entities, var: entities}]}
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    entities: $entities
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update multiple datapoints
#
# POST /datapoints/batch
# Returns: record<entityData: record<creationDate: string, encodeIp: bool, fifthConversionId: int, fifthConversionName: string, firstConversionId: int, firstConversionName: string, fourthConversionId: int, fourthConversionName: string, groupId: int, groupName: string, id: int, isPublic: bool, isSecured: bool, lightTracking: bool, name: string, notes: string, preferred: bool, redirectOnly: bool, secondConversionId: int, secondConversionName: string, status: string, tags: list<record>, thirdConversionId: int, thirdConversionName: string, title: string, trackingCode: string, type: string, typeTL: record<appendQuery: bool, browserDestinationItem: record, destinationMode: string, domainId: int, encodeUrl: bool, expirationClicks: int, expirationDate: string, firstUrl: string, goDomainId: int, hideUrl: bool, hideUrlTitle: string, isABTest: bool, password: string, pauseAfterClicksExpiration: bool, pauseAfterDateExpiration: bool, randomDestinationItems: list, redirectType: string, referrerClean: string, scripts: list, sequentialDestinationItems: list, spilloverDestinationItems: list, uniqueDestinationItem: record, url: string, urlAfterClicksExpiration: string, urlAfterDateExpiration: string, urlsByLanguage: list, urlsByNation: list, weightedDestinationItems: list>, typeTP: record<parameterNote: string>, writePermited: bool>, errors: table<code: record, errorMessage: string, errorValue: record, property: string>, result: record<id: int, uri: string>, status: string>
# operationId: DataPoints_BatchPost
export def "data-points-batch-post" [
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
  --list: list # item shape: {creationDate?: string, encodeIp?: bool, fifthConversionId?: int, fifthConversionName?: string, firstConversionId?: int, firstConversionName?: string, fourthConversionId?: int, fourthConversionName?: string, groupId?: int, groupName?: string, id?: int, isPublic?: bool, isSecured?: bool, lightTracking?: bool, name?: string, notes?: string, preferred?: bool, redirectOnly?: bool, secondConversionId?: int, secondConversionName?: string, status?: "Active"|"Paused"|"Abuse"|"Deleted", tags?: list, ... (8 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/datapoints/batch"
    body: {content_type: "application/json", kind: json, fields: [{name: List, var: list}]}
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    list: $list
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create multiple datapoints
#
# PUT /datapoints/batch
# Returns: record<entityData: record<creationDate: string, encodeIp: bool, fifthConversionId: int, fifthConversionName: string, firstConversionId: int, firstConversionName: string, fourthConversionId: int, fourthConversionName: string, groupId: int, groupName: string, id: int, isPublic: bool, isSecured: bool, lightTracking: bool, name: string, notes: string, preferred: bool, redirectOnly: bool, secondConversionId: int, secondConversionName: string, status: string, tags: list<record>, thirdConversionId: int, thirdConversionName: string, title: string, trackingCode: string, type: string, typeTL: record<appendQuery: bool, browserDestinationItem: record, destinationMode: string, domainId: int, encodeUrl: bool, expirationClicks: int, expirationDate: string, firstUrl: string, goDomainId: int, hideUrl: bool, hideUrlTitle: string, isABTest: bool, password: string, pauseAfterClicksExpiration: bool, pauseAfterDateExpiration: bool, randomDestinationItems: list, redirectType: string, referrerClean: string, scripts: list, sequentialDestinationItems: list, spilloverDestinationItems: list, uniqueDestinationItem: record, url: string, urlAfterClicksExpiration: string, urlAfterDateExpiration: string, urlsByLanguage: list, urlsByNation: list, weightedDestinationItems: list>, typeTP: record<parameterNote: string>, writePermited: bool>, errors: table<code: record, errorMessage: string, errorValue: record, property: string>, result: record<id: int, uri: string>, status: string>
# operationId: DataPoints_BatchPut
export def "data-points-batch-put" [
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
  --list: list # item shape: {creationDate?: string, encodeIp?: bool, fifthConversionId?: int, fifthConversionName?: string, firstConversionId?: int, firstConversionName?: string, fourthConversionId?: int, fourthConversionName?: string, groupId?: int, groupName?: string, id?: int, isPublic?: bool, isSecured?: bool, lightTracking?: bool, name?: string, notes?: string, preferred?: bool, redirectOnly?: bool, secondConversionId?: int, secondConversionName?: string, status?: "Active"|"Paused"|"Abuse"|"Deleted", tags?: list, ... (8 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/datapoints/batch"
    body: {content_type: "application/json", kind: json, fields: [{name: List, var: list}]}
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    list: $list
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Count the datapoints associated to the user
#
# GET /datapoints/count
# Returns: record<count: int>
# operationId: DataPoints_Count
export def "data-points-count" [
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
  --type: string@type-completer-2 # Type of the datapoint ("tp"/"tl")
  --status: string@status-completer-1 # Status of the datapoint
  --tags: string # A comma separated list of tags you want to filter with.
  --text-search: string # Filter fields by this pattern
  --only-favorites: oneof<nothing, bool> # Filter fields by favourite status
  --created-after: string # Exclude datapoints created before this date (YYYYMMDD)
  --created-before: string # Exclude datapoints created after this date (YYYYMMDD)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/datapoints/count"
    query: [{name: type, var: type}, {name: status, var: status}, {name: tags, var: tags}, {name: textSearch, var: text_search}, {name: onlyFavorites, var: only_favorites}, {name: createdAfter, var: created_after}, {name: createdBefore, var: created_before}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    type: $type, status: $status, tags: $tags, text_search: $text_search, only_favorites: $only_favorites, created_after: $created_after, created_before: $created_before
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a datapoint
#
# DELETE /datapoints/{id}
# Returns: record<id: int, uri: string>
# operationId: DataPoints_Delete
export def "data-points-delete" [
  id: int
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/datapoints/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a datapoint
#
# GET /datapoints/{id}
# Returns: record<creationDate: string, encodeIp: bool, fifthConversionId: int, fifthConversionName: string, firstConversionId: int, firstConversionName: string, fourthConversionId: int, fourthConversionName: string, groupId: int, groupName: string, id: int, isPublic: bool, isSecured: bool, lightTracking: bool, name: string, notes: string, preferred: bool, redirectOnly: bool, secondConversionId: int, secondConversionName: string, status: string, tags: table<datapoints: list, groups: list, id: int, name: string>, thirdConversionId: int, thirdConversionName: string, title: string, trackingCode: string, type: string, typeTL: record<appendQuery: bool, browserDestinationItem: record<emailDestinationUrl: string, mobileDestinationUrl: string, spidersDestinationUrl: string>, destinationMode: string, domainId: int, encodeUrl: bool, expirationClicks: int, expirationDate: string, firstUrl: string, goDomainId: int, hideUrl: bool, hideUrlTitle: string, isABTest: bool, password: string, pauseAfterClicksExpiration: bool, pauseAfterDateExpiration: bool, randomDestinationItems: list<record>, redirectType: string, referrerClean: string, scripts: list<record>, sequentialDestinationItems: list<record>, spilloverDestinationItems: list<record>, uniqueDestinationItem: record<firstDestinationUrl: string>, url: string, urlAfterClicksExpiration: string, urlAfterDateExpiration: string, urlsByLanguage: list<record>, urlsByNation: list<record>, weightedDestinationItems: list<record>>, typeTP: record<parameterNote: string>, writePermited: bool>
export def "get-datapoints-id" [
  id: int
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/datapoints/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a datapoint
#
# POST /datapoints/{id}
# Returns: record<id: int, uri: string>
# operationId: DataPoints_Post
export def "data-points-post" [
  id: int
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
  --creation-date: string # (A date in "YmdHis" format) (e.g. 20120203120530)
  --encode-ip: oneof<nothing, bool>
  --fifth-conversion-id: int # format: int64
  --fifth-conversion-name: string
  --first-conversion-id: int # format: int64
  --first-conversion-name: string
  --fourth-conversion-id: int # format: int64
  --fourth-conversion-name: string
  --group-id: int # format: int64
  --group-name: string
  --body-id: int # format: int64 (spec name: id)
  --is-public: oneof<nothing, bool>
  --is-secured: oneof<nothing, bool>
  --light-tracking: oneof<nothing, bool>
  --name: string
  --notes: string
  --preferred: oneof<nothing, bool>
  --redirect-only: oneof<nothing, bool>
  --second-conversion-id: int # format: int64
  --second-conversion-name: string
  --status: string@status-completer-2
  --tags: list # item shape: {datapoints?: list<int>, groups?: list<int>, id?: int, name?: string}
  --third-conversion-id: int # format: int64
  --third-conversion-name: string
  --title: string
  --tracking-code: string
  --type: string@type-completer-3
  --type-tl: record # shape: {appendQuery?: bool, browserDestinationItem?: record, destinationMode?: "Simple"|"RandomDestination"|"DestinationByLanguage"|"SpilloverDestination"|"DynamicUrl"|"BrowserDestination"|"DestinationByNation"|"UniqueDestination"|"SequentialDestination"|"WeightedDestination", domainId?: int, encodeUrl?: bool, expirationClicks?: int, expirationDate?: string, firstUrl?: string, goDomainId?: int, hideUrl?: bool, hideUrlTitle?: string, isABTest?: bool, password?: string, pauseAfterClicksExpiration?: bool, ... (14 more fields)}
  --type-tp: record # shape: {parameterNote?: string}
  --write-permited: oneof<nothing, bool>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/datapoints/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: creationDate, var: creation_date}, {name: encodeIp, var: encode_ip}, {name: fifthConversionId, var: fifth_conversion_id}, {name: fifthConversionName, var: fifth_conversion_name}, {name: firstConversionId, var: first_conversion_id}, {name: firstConversionName, var: first_conversion_name}, {name: fourthConversionId, var: fourth_conversion_id}, {name: fourthConversionName, var: fourth_conversion_name}, {name: groupId, var: group_id}, {name: groupName, var: group_name}, {name: id, var: body_id}, {name: isPublic, var: is_public}, {name: isSecured, var: is_secured}, {name: lightTracking, var: light_tracking}, {name: name, var: name}, {name: notes, var: notes}, {name: preferred, var: preferred}, {name: redirectOnly, var: redirect_only}, {name: secondConversionId, var: second_conversion_id}, {name: secondConversionName, var: second_conversion_name}, {name: status, var: status}, {name: tags, var: tags}, {name: thirdConversionId, var: third_conversion_id}, {name: thirdConversionName, var: third_conversion_name}, {name: title, var: title}, {name: trackingCode, var: tracking_code}, {name: type, var: type}, {name: typeTL, var: type_tl}, {name: typeTP, var: type_tp}, {name: writePermited, var: write_permited}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    id: $id, creation_date: $creation_date, encode_ip: $encode_ip, fifth_conversion_id: $fifth_conversion_id, fifth_conversion_name: $fifth_conversion_name, first_conversion_id: $first_conversion_id, first_conversion_name: $first_conversion_name, fourth_conversion_id: $fourth_conversion_id, fourth_conversion_name: $fourth_conversion_name, group_id: $group_id, group_name: $group_name, body_id: $body_id, is_public: $is_public, is_secured: $is_secured, light_tracking: $light_tracking, name: $name, notes: $notes, preferred: $preferred, redirect_only: $redirect_only, second_conversion_id: $second_conversion_id, second_conversion_name: $second_conversion_name, status: $status, tags: $tags, third_conversion_id: $third_conversion_id, third_conversion_name: $third_conversion_name, title: $title, tracking_code: $tracking_code, type: $type, type_tl: $type_tl, type_tp: $type_tp, write_permited: $write_permited
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve statistics about this datapoint for a timeframe
#
# GET /datapoints/{id}/aggregated
# Returns: record<activityDay: string, commissionsCost: float, conversionsCost: float, conversionsValue: float, convertedClicks: int, entityData: record, entityId: string, fromDay: string, hourlyBreakDown: record, lastHitDate: string, spiderHitsCount: int, toDay: string, totalClicks: int, totalViews: int, uniqueClicks: int, uniqueConversions: int, uniqueViews: int>
# operationId: DataPoints_GetStatisticsSingle
export def "data-points-get-statistics-single" [
  id: int
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
  --time-frame: string@time-frame-completer # Timeframe of the request. See list at $timeframeList (required)
  --from-day: string # If using a "custom" timeFrame you can specify the starting day (YYYYMMDD)
  --to-day: string # If using a "custom" timeFrame you can specify the ending day (YYYYMMDD)
  --hourly: oneof<nothing, bool> # If using "yesterday" or "today" timeframe you can ask for the hourly detail
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/datapoints/{id}/aggregated"
    path_params: [{name: id, var: id}]
    query: [{name: timeFrame, var: time_frame, required: true}, {name: fromDay, var: from_day}, {name: toDay, var: to_day}, {name: hourly, var: hourly}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    id: $id, time_frame: $time_frame, from_day: $from_day, to_day: $to_day, hourly: $hourly
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve statistics about this datapoint for a timeframe grouped by some temporal entity (day/week/month)
#
# GET /datapoints/{id}/aggregated/list
# Returns: record<entities: table<activityDay: string, commissionsCost: float, conversionsCost: float, conversionsValue: float, convertedClicks: int, entityData: record, entityId: string, fromDay: string, hourlyBreakDown: record, lastHitDate: string, spiderHitsCount: int, toDay: string, totalClicks: int, totalViews: int, uniqueClicks: int, uniqueConversions: int, uniqueViews: int>>
# operationId: DataPoints_GetStatisticsList
export def "data-points-get-statistics-list" [
  id: int
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
  --time-frame: string@time-frame-completer # Timeframe of the request. See list at $timeframeList (required)
  --from-day: string # If using a "custom" timeFrame you can specify the starting day (YYYYMMDD)
  --to-day: string # If using a "custom" timeFrame you can specify the ending day (YYYYMMDD)
  --group-by: string@group-by-completer # The temporal entity you want to group by ("week"/"month"). If unspecified is "day".
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/datapoints/{id}/aggregated/list"
    path_params: [{name: id, var: id}]
    query: [{name: timeFrame, var: time_frame, required: true}, {name: fromDay, var: from_day}, {name: toDay, var: to_day}, {name: groupBy, var: group_by}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    id: $id, time_frame: $time_frame, from_day: $from_day, to_day: $to_day, group_by: $group_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Fast switch the "favourite" field of a datapoint
#
# PUT /datapoints/{id}/favourite
# Returns: record<id: int, uri: string>
# operationId: DataPoints_PatchFavourite
export def "data-points-patch-favourite" [
  id: int
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/datapoints/{id}/favourite"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve the list of events related to this datapoint.
#
# GET /datapoints/{id}/hits
# Returns: record<hits: table<accessTime: string, browser: record, clientLanguage: string, conversion1: record, conversion2: record, conversion3: record, conversion4: record, conversion5: record, conversions: list, entity: record, ip: string, isProxy: string, isSpider: string, isUnique: string, location: record, org: string, os: record, queryParams: string, realDestinationUrl: string, referer: string, source: record, type: string>, lastKey: string>
# operationId: DataPoints_GetHits
export def "data-points-get-hits" [
  id: int
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
  --timeframe: string@timeframe-completer # Timeframe of the request. See list at $timeframeList (required)
  --limit: int # Limit results to this number (format: int32)
  --offset: string # Offset where to start from (it's the lastKey field in the response object)
  --from-day: string # If using a "custom" timeFrame you can specify the starting day (YYYYMMDD)
  --to-day: string # If using a "custom" timeFrame you can specify the ending day (YYYYMMDD)
  --filter: string@filter-completer-1 # Filter event type ("spiders"/"uniques"/"nonuniques"/"conversions")
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/datapoints/{id}/hits"
    path_params: [{name: id, var: id}]
    query: [{name: timeframe, var: timeframe, required: true}, {name: limit, var: limit}, {name: offset, var: offset}, {name: fromDay, var: from_day}, {name: toDay, var: to_day}, {name: filter, var: filter}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    id: $id, timeframe: $timeframe, limit: $limit, offset: $offset, from_day: $from_day, to_day: $to_day, filter: $filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Fast patch the "notes" field of a datapoint
#
# PUT /datapoints/{id}/notes
# Returns: record<id: int, uri: string>
# operationId: DataPoints_PatchNotes
export def "data-points-patch-notes" [
  id: int
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
  --text: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/datapoints/{id}/notes"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Text, var: text}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    id: $id, text: $text
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve a list of domains
#
# GET /domains
# Returns: record<entities: table<id: int, uri: string>>
# operationId: Domains_Get
export def "domains-get" [
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
  --offset: int # Offset where to start from (format: int32)
  --limit: int # Limit results to this number (format: int32)
  --type: string@type-completer-4 # Type of domain ("system"/"go"/"personal"/"dedicated"). If not specified default is "system" (default: system)
  --name: string # Filter domains with this anmen
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/domains"
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: type, var: type}, {name: name, var: name}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    offset: $offset, limit: $limit, type: $type, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a domain
#
# POST /domains
# Returns: record<id: int, uri: string>
# operationId: Domains_Put
export def "domains-put" [
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
  --custom404: string
  --custom-homepage: string
  --id: int # format: int64
  --name: string
  --type: string@type-completer-5
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/domains"
    body: {content_type: "application/json", kind: json, fields: [{name: custom404, var: custom404}, {name: customHomepage, var: custom_homepage}, {name: id, var: id}, {name: name, var: name}, {name: type, var: type}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    custom404: $custom404, custom_homepage: $custom_homepage, id: $id, name: $name, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve count of domains
#
# GET /domains/count
# Returns: record<count: int>
# operationId: Domains_Count
export def "domains-count" [
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
  --type: string@type-completer-4 # Type of domain ("system"/"go"/"personal"/"dedicated"). If not specified default is "system" (default: system)
  --name: string # Filter domains with this anmen
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/domains/count"
    query: [{name: type, var: type}, {name: name, var: name}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    type: $type, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a domain
#
# DELETE /domains/{id}
# Returns: record<id: int, uri: string>
# operationId: Domains_Delete
export def "domains-delete" [
  id: int
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/domains/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a domain
#
# GET /domains/{id}
# Returns: record<custom404: string, customHomepage: string, id: int, name: string, type: string>
export def "get-domains-id" [
  id: int
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/domains/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a domain
#
# POST /domains/{id}
# Returns: record<id: int, uri: string>
# operationId: Domains_Update
export def "domains-update" [
  id: int
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
  --custom404: string
  --custom-homepage: string
  --body-id: int # format: int64 (spec name: id)
  --name: string
  --type: string@type-completer-5
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/domains/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: custom404, var: custom404}, {name: customHomepage, var: custom_homepage}, {name: id, var: body_id}, {name: name, var: name}, {name: type, var: type}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    id: $id, custom404: $custom404, custom_homepage: $custom_homepage, body_id: $body_id, name: $name, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List of all the groups associated to the user.
#
# GET /groups
# Returns: record<entities: table<id: int, uri: string>>
# operationId: Groups_Get
export def "groups-get" [
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
  --offset: int # Where to start when retrieving elements. Default is 0 if not specified. (format: int32, default: 0)
  --limit: int # Maximum elements to retrieve. Default to 20 if not specified. (format: int32, default: 20)
  --status: string@status-completer # Status of the group
  --tags: string # A comma separated list of tags you want to filter with.
  --text-search: string # Filter fields by this pattern
  --created-after: string # Exclude groups created before this date (YYYYMMDD)
  --created-before: string # Exclude groups created after this date (YYYYMMDD)
  --write: oneof<nothing, bool> # Write permission
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/groups"
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: status, var: status}, {name: tags, var: tags}, {name: textSearch, var: text_search}, {name: createdAfter, var: created_after}, {name: createdBefore, var: created_before}, {name: write, var: write}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    offset: $offset, limit: $limit, status: $status, tags: $tags, text_search: $text_search, created_after: $created_after, created_before: $created_before, write: $write
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a group
#
# POST /groups
# Returns: record<id: int, uri: string>
# operationId: Groups_Put
export def "groups-put" [
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
  --creation-date: string # (A date in "YmdHis" format) (e.g. 20120203120530)
  --deleted: oneof<nothing, bool>
  --id: int # format: int64
  --is-public: oneof<nothing, bool>
  --name: string
  --notes: string
  --preferred: oneof<nothing, bool>
  --redirect-only: oneof<nothing, bool>
  --tags: list # item shape: {datapoints?: list<int>, groups?: list<int>, id?: int, name?: string}
  --write-permited: oneof<nothing, bool>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/groups"
    body: {content_type: "application/json", kind: json, fields: [{name: creationDate, var: creation_date}, {name: deleted, var: deleted}, {name: id, var: id}, {name: isPublic, var: is_public}, {name: name, var: name}, {name: notes, var: notes}, {name: preferred, var: preferred}, {name: redirectOnly, var: redirect_only}, {name: tags, var: tags}, {name: writePermited, var: write_permited}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    creation_date: $creation_date, deleted: $deleted, id: $id, is_public: $is_public, name: $name, notes: $notes, preferred: $preferred, redirect_only: $redirect_only, tags: $tags, write_permited: $write_permited
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve statistics about this customer for a timeframe by groups
#
# GET /groups/aggregated
# Returns: record<activityDay: string, commissionsCost: float, conversionsCost: float, conversionsValue: float, convertedClicks: int, entityData: record, entityId: string, fromDay: string, hourlyBreakDown: record, lastHitDate: string, spiderHitsCount: int, toDay: string, totalClicks: int, totalViews: int, uniqueClicks: int, uniqueConversions: int, uniqueViews: int>
# operationId: Groups_GetStatisticsAggregatedSingle
export def "groups-get-statistics-aggregated-single" [
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
  --time-frame: string@time-frame-completer # Timeframe of the request. See list at $timeframeList (required)
  --from-day: string # If using a "custom" timeFrame you can specify the starting day (YYYYMMDD)
  --to-day: string # If using a "custom" timeFrame you can specify the ending day (YYYYMMDD)
  --hourly: oneof<nothing, bool> # If using "yesterday" or "today" timeframe you can ask for the hourly detail
  --status: string@status-completer # Status of group ("deleted"/"active")
  --tag: string # A comma separated list of tags you want to filter with.
  --favourite: oneof<nothing, bool> # Is the group is marked as favourite
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/groups/aggregated"
    query: [{name: timeFrame, var: time_frame, required: true}, {name: fromDay, var: from_day}, {name: toDay, var: to_day}, {name: hourly, var: hourly}, {name: status, var: status}, {name: tag, var: tag}, {name: favourite, var: favourite}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    time_frame: $time_frame, from_day: $from_day, to_day: $to_day, hourly: $hourly, status: $status, tag: $tag, favourite: $favourite
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve statistics about all groups of this customer for a timeframe grouped by some temporal entity (day/week/month)
#
# GET /groups/aggregated/list
# Returns: record<entities: table<activityDay: string, commissionsCost: float, conversionsCost: float, conversionsValue: float, convertedClicks: int, entityData: record, entityId: string, fromDay: string, hourlyBreakDown: record, lastHitDate: string, spiderHitsCount: int, toDay: string, totalClicks: int, totalViews: int, uniqueClicks: int, uniqueConversions: int, uniqueViews: int>>
# operationId: Groups_GetStatisticsAllList
export def "groups-get-statistics-all-list" [
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
  --time-frame: string@time-frame-completer # Timeframe of the request. See list at $timeframeList (required)
  --from-day: string # If using a "custom" timeFrame you can specify the starting day (YYYYMMDD)
  --to-day: string # If using a "custom" timeFrame you can specify the ending day (YYYYMMDD)
  --status: string # Status of group ("deleted"/"active")
  --tag: string # A comma separated list of tags you want to filter with.
  --favourite: oneof<nothing, bool> # Is the group is marked as favourite
  --group-by: string@group-by-completer-1 # The temporal entity you want to group by ("week"/"month"). If unspecified is "day".
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/groups/aggregated/list"
    query: [{name: timeFrame, var: time_frame, required: true}, {name: fromDay, var: from_day}, {name: toDay, var: to_day}, {name: status, var: status}, {name: tag, var: tag}, {name: favourite, var: favourite}, {name: groupBy, var: group_by}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    time_frame: $time_frame, from_day: $from_day, to_day: $to_day, status: $status, tag: $tag, favourite: $favourite, group_by: $group_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Count the groups associated to the user.
#
# GET /groups/count
# Returns: record<count: int>
# operationId: Groups_Count
export def "groups-count" [
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
  --status: string@status-completer # Status of the datapoint
  --tags: string # A comma separated list of tags you want to filter with.
  --text-search: string # Filter fields by this pattern
  --created-after: string # Exclude groups created before this date (YYYYMMDD)
  --created-before: string # Exclude groups created after this date (YYYYMMDD)
  --write: oneof<nothing, bool> # Write permission
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/groups/count"
    query: [{name: status, var: status}, {name: tags, var: tags}, {name: textSearch, var: text_search}, {name: createdAfter, var: created_after}, {name: createdBefore, var: created_before}, {name: write, var: write}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    status: $status, tags: $tags, text_search: $text_search, created_after: $created_after, created_before: $created_before, write: $write
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete group specified by id
#
# DELETE /groups/{id}
# Returns: record<id: int, uri: string>
# operationId: Groups_Delete
export def "groups-delete" [
  id: int
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/groups/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a group
#
# GET /groups/{id}
# Returns: record<creationDate: string, deleted: bool, id: int, isPublic: bool, name: string, notes: string, preferred: bool, redirectOnly: bool, tags: table<datapoints: list, groups: list, id: int, name: string>, writePermited: bool>
export def "get-groups-id" [
  id: int
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/groups/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a group
#
# POST /groups/{id}
# Returns: record<id: int, uri: string>
# operationId: Groups_Post
export def "groups-post" [
  id: int
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
  --creation-date: string # (A date in "YmdHis" format) (e.g. 20120203120530)
  --deleted: oneof<nothing, bool>
  --body-id: int # format: int64 (spec name: id)
  --is-public: oneof<nothing, bool>
  --name: string
  --notes: string
  --preferred: oneof<nothing, bool>
  --redirect-only: oneof<nothing, bool>
  --tags: list # item shape: {datapoints?: list<int>, groups?: list<int>, id?: int, name?: string}
  --write-permited: oneof<nothing, bool>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/groups/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: creationDate, var: creation_date}, {name: deleted, var: deleted}, {name: id, var: body_id}, {name: isPublic, var: is_public}, {name: name, var: name}, {name: notes, var: notes}, {name: preferred, var: preferred}, {name: redirectOnly, var: redirect_only}, {name: tags, var: tags}, {name: writePermited, var: write_permited}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    id: $id, creation_date: $creation_date, deleted: $deleted, body_id: $body_id, is_public: $is_public, name: $name, notes: $notes, preferred: $preferred, redirect_only: $redirect_only, tags: $tags, write_permited: $write_permited
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve statistics about this group for a timeframe
#
# GET /groups/{id}/aggregated
# Returns: record<activityDay: string, commissionsCost: float, conversionsCost: float, conversionsValue: float, convertedClicks: int, entityData: record, entityId: string, fromDay: string, hourlyBreakDown: record, lastHitDate: string, spiderHitsCount: int, toDay: string, totalClicks: int, totalViews: int, uniqueClicks: int, uniqueConversions: int, uniqueViews: int>
# operationId: Groups_GetStatisticsSingle
export def "groups-get-statistics-single" [
  id: int
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
  --time-frame: string@time-frame-completer # Timeframe of the request. See list at $timeframeList (required)
  --from-day: string # If using a "custom" timeFrame you can specify the starting day (YYYYMMDD)
  --to-day: string # If using a "custom" timeFrame you can specify the ending day (YYYYMMDD)
  --hourly: oneof<nothing, bool> # If using "yesterday" or "today" timeframe you can ask for the hourly detail
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/groups/{id}/aggregated"
    path_params: [{name: id, var: id}]
    query: [{name: timeFrame, var: time_frame, required: true}, {name: fromDay, var: from_day}, {name: toDay, var: to_day}, {name: hourly, var: hourly}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    id: $id, time_frame: $time_frame, from_day: $from_day, to_day: $to_day, hourly: $hourly
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve statistics about this group for a timeframe grouped by some temporal entity (day/week/month)
#
# GET /groups/{id}/aggregated/list
# Returns: record<entities: table<activityDay: string, commissionsCost: float, conversionsCost: float, conversionsValue: float, convertedClicks: int, entityData: record, entityId: string, fromDay: string, hourlyBreakDown: record, lastHitDate: string, spiderHitsCount: int, toDay: string, totalClicks: int, totalViews: int, uniqueClicks: int, uniqueConversions: int, uniqueViews: int>>
# operationId: Groups_GetStatisticsList
export def "groups-get-statistics-list" [
  id: int
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
  --time-frame: string@time-frame-completer # Timeframe of the request. See list at $timeframeList (required)
  --from-day: string # If using a "custom" timeFrame you can specify the starting day (YYYYMMDD)
  --to-day: string # If using a "custom" timeFrame you can specify the ending day (YYYYMMDD)
  --group-by: string@group-by-completer # The temporal entity you want to group by ("week"/"month"). If unspecified is "day".
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/groups/{id}/aggregated/list"
    path_params: [{name: id, var: id}]
    query: [{name: timeFrame, var: time_frame, required: true}, {name: fromDay, var: from_day}, {name: toDay, var: to_day}, {name: groupBy, var: group_by}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    id: $id, time_frame: $time_frame, from_day: $from_day, to_day: $to_day, group_by: $group_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve statistics about a subset of datapoints for a timeframe with datapoints data
#
# GET /groups/{id}/aggregated/summary
# Returns: record<count: int, limit: int, offset: int, result: table<activityDay: string, commissionsCost: float, conversionsCost: float, conversionsValue: float, convertedClicks: int, entityData: record, entityId: string, fromDay: string, hourlyBreakDown: record, lastHitDate: string, spiderHitsCount: int, toDay: string, totalClicks: int, totalViews: int, uniqueClicks: int, uniqueConversions: int, uniqueViews: int>>
# operationId: Groups_GetDatapointsSummary
export def "groups-get-datapoints-summary" [
  id: int
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
  --time-frame: string@time-frame-completer # Timeframe of the request. See list at $timeframeList (required)
  --type: string@type-completer-2 # Type of datapoint ("tl"/"tp")
  --from-day: string # If using a "custom" timeFrame you can specify the starting day (YYYYMMDD)
  --to-day: string # If using a "custom" timeFrame you can specify the ending day (YYYYMMDD)
  --status: string@status-completer # Status of datapoint ("deleted"/"active"/"paused"/"spam")
  --tag: string # A comma separated list of tags you want to filter with.
  --favourite: oneof<nothing, bool> # Is the datapoint marked as favourite
  --sort-by: string # Field to sort by
  --sort-direction: string@sort-direction-completer # Direction of sort "asc" or "desc"
  --offset: int # Offset where to start from (format: int32, default: 0)
  --limit: int # Limit results to this number (format: int32, default: 20)
  --text-search: string # Filter fields by this pattern
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/groups/{id}/aggregated/summary"
    path_params: [{name: id, var: id}]
    query: [{name: timeFrame, var: time_frame, required: true}, {name: type, var: type}, {name: fromDay, var: from_day}, {name: toDay, var: to_day}, {name: status, var: status}, {name: tag, var: tag}, {name: favourite, var: favourite}, {name: sortBy, var: sort_by}, {name: sortDirection, var: sort_direction}, {name: offset, var: offset}, {name: limit, var: limit}, {name: textSearch, var: text_search}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    id: $id, time_frame: $time_frame, type: $type, from_day: $from_day, to_day: $to_day, status: $status, tag: $tag, favourite: $favourite, sort_by: $sort_by, sort_direction: $sort_direction, offset: $offset, limit: $limit, text_search: $text_search
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List of all the datapoints associated to the user in this group.
#
# GET /groups/{id}/datapoints
# Returns: record<entities: table<id: int, uri: string>>
# operationId: Groups_GetDatapoints
export def "groups-get-datapoints" [
  id: int
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
  --offset: int # Where to start when retrieving elements. Default is 0 if not specified. (format: int32, default: 0)
  --limit: int # Maximum elements to retrieve. Default to 20 if not specified. (format: int32, default: 20)
  --type: string@type-completer-2 # Type of the datapoint ("tp"/"tl")
  --status: string@status-completer-1 # Status of the datapoint
  --tags: string # A comma separated list of tags you want to filter with.
  --text-search: string # Filter fields by this pattern
  --only-favorites: oneof<nothing, bool> # Filter fields by favourite status
  --sort-by: string # Field to sort by
  --sort-direction: string@sort-direction-completer # Direction of sort "asc" or "desc"
  --created-after: string # Exclude datapoints created before this date (YYYYMMDD)
  --created-before: string # Exclude datapoints created after this date (YYYYMMDD)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/groups/{id}/datapoints"
    path_params: [{name: id, var: id}]
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: type, var: type}, {name: status, var: status}, {name: tags, var: tags}, {name: textSearch, var: text_search}, {name: onlyFavorites, var: only_favorites}, {name: sortBy, var: sort_by}, {name: sortDirection, var: sort_direction}, {name: createdAfter, var: created_after}, {name: createdBefore, var: created_before}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    id: $id, offset: $offset, limit: $limit, type: $type, status: $status, tags: $tags, text_search: $text_search, only_favorites: $only_favorites, sort_by: $sort_by, sort_direction: $sort_direction, created_after: $created_after, created_before: $created_before
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a datapoint in this group
#
# POST /groups/{id}/datapoints
# Returns: record<id: int, uri: string>
# operationId: Groups_PutDatapoint
export def "groups-put-datapoint" [
  id: int
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
  --creation-date: string # (A date in "YmdHis" format) (e.g. 20120203120530)
  --encode-ip: oneof<nothing, bool>
  --fifth-conversion-id: int # format: int64
  --fifth-conversion-name: string
  --first-conversion-id: int # format: int64
  --first-conversion-name: string
  --fourth-conversion-id: int # format: int64
  --fourth-conversion-name: string
  --group-id: int # format: int64
  --group-name: string
  --body-id: int # format: int64 (spec name: id)
  --is-public: oneof<nothing, bool>
  --is-secured: oneof<nothing, bool>
  --light-tracking: oneof<nothing, bool>
  --name: string
  --notes: string
  --preferred: oneof<nothing, bool>
  --redirect-only: oneof<nothing, bool>
  --second-conversion-id: int # format: int64
  --second-conversion-name: string
  --status: string@status-completer-2
  --tags: list # item shape: {datapoints?: list<int>, groups?: list<int>, id?: int, name?: string}
  --third-conversion-id: int # format: int64
  --third-conversion-name: string
  --title: string
  --tracking-code: string
  --type: string@type-completer-3
  --type-tl: record # shape: {appendQuery?: bool, browserDestinationItem?: record, destinationMode?: "Simple"|"RandomDestination"|"DestinationByLanguage"|"SpilloverDestination"|"DynamicUrl"|"BrowserDestination"|"DestinationByNation"|"UniqueDestination"|"SequentialDestination"|"WeightedDestination", domainId?: int, encodeUrl?: bool, expirationClicks?: int, expirationDate?: string, firstUrl?: string, goDomainId?: int, hideUrl?: bool, hideUrlTitle?: string, isABTest?: bool, password?: string, pauseAfterClicksExpiration?: bool, ... (14 more fields)}
  --type-tp: record # shape: {parameterNote?: string}
  --write-permited: oneof<nothing, bool>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/groups/{id}/datapoints"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: creationDate, var: creation_date}, {name: encodeIp, var: encode_ip}, {name: fifthConversionId, var: fifth_conversion_id}, {name: fifthConversionName, var: fifth_conversion_name}, {name: firstConversionId, var: first_conversion_id}, {name: firstConversionName, var: first_conversion_name}, {name: fourthConversionId, var: fourth_conversion_id}, {name: fourthConversionName, var: fourth_conversion_name}, {name: groupId, var: group_id}, {name: groupName, var: group_name}, {name: id, var: body_id}, {name: isPublic, var: is_public}, {name: isSecured, var: is_secured}, {name: lightTracking, var: light_tracking}, {name: name, var: name}, {name: notes, var: notes}, {name: preferred, var: preferred}, {name: redirectOnly, var: redirect_only}, {name: secondConversionId, var: second_conversion_id}, {name: secondConversionName, var: second_conversion_name}, {name: status, var: status}, {name: tags, var: tags}, {name: thirdConversionId, var: third_conversion_id}, {name: thirdConversionName, var: third_conversion_name}, {name: title, var: title}, {name: trackingCode, var: tracking_code}, {name: type, var: type}, {name: typeTL, var: type_tl}, {name: typeTP, var: type_tp}, {name: writePermited, var: write_permited}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    id: $id, creation_date: $creation_date, encode_ip: $encode_ip, fifth_conversion_id: $fifth_conversion_id, fifth_conversion_name: $fifth_conversion_name, first_conversion_id: $first_conversion_id, first_conversion_name: $first_conversion_name, fourth_conversion_id: $fourth_conversion_id, fourth_conversion_name: $fourth_conversion_name, group_id: $group_id, group_name: $group_name, body_id: $body_id, is_public: $is_public, is_secured: $is_secured, light_tracking: $light_tracking, name: $name, notes: $notes, preferred: $preferred, redirect_only: $redirect_only, second_conversion_id: $second_conversion_id, second_conversion_name: $second_conversion_name, status: $status, tags: $tags, third_conversion_id: $third_conversion_id, third_conversion_name: $third_conversion_name, title: $title, tracking_code: $tracking_code, type: $type, type_tl: $type_tl, type_tp: $type_tp, write_permited: $write_permited
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Count the datapoints associated to the user in this group.
#
# GET /groups/{id}/datapoints/count
# Returns: record<count: int>
# operationId: Groups_GetDatapointsCount
export def "groups-get-datapoints-count" [
  id: int
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
  --type: string@type-completer-2 # Type of the datapoint ("tp"/"tl")
  --status: string@status-completer-1 # Status of the datapoint
  --tags: string # A comma separated list of tags you want to filter with.
  --text-search: string # Filter fields by this pattern
  --only-favorites: oneof<nothing, bool> # Filter fields by favourite status
  --created-after: string # Exclude datapoints created before this date (YYYYMMDD)
  --created-before: string # Exclude datapoints created after this date (YYYYMMDD)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/groups/{id}/datapoints/count"
    path_params: [{name: id, var: id}]
    query: [{name: type, var: type}, {name: status, var: status}, {name: tags, var: tags}, {name: textSearch, var: text_search}, {name: onlyFavorites, var: only_favorites}, {name: createdAfter, var: created_after}, {name: createdBefore, var: created_before}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    id: $id, type: $type, status: $status, tags: $tags, text_search: $text_search, only_favorites: $only_favorites, created_after: $created_after, created_before: $created_before
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Fast switch the "favourite" field of a group
#
# PUT /groups/{id}/favourite
# Returns: record<id: int, uri: string>
# operationId: Groups_PatchFavourite
export def "groups-patch-favourite" [
  id: int
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/groups/{id}/favourite"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve the list of events related to this group.
#
# GET /groups/{id}/hits
# Returns: record<hits: table<accessTime: string, browser: record, clientLanguage: string, conversion1: record, conversion2: record, conversion3: record, conversion4: record, conversion5: record, conversions: list, entity: record, ip: string, isProxy: string, isSpider: string, isUnique: string, location: record, org: string, os: record, queryParams: string, realDestinationUrl: string, referer: string, source: record, type: string>, lastKey: string>
# operationId: Groups_GetHits
export def "groups-get-hits" [
  id: int
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
  --timeframe: string@timeframe-completer # Timeframe of the request. See list at $timeframeList (required)
  --limit: int # Limit results to this number (format: int32)
  --offset: string # Offset where to start from (it's the lastKey field in the response object)
  --from-day: string # If using a "custom" timeFrame you can specify the starting day (YYYYMMDD)
  --to-day: string # If using a "custom" timeFrame you can specify the ending day (YYYYMMDD)
  --filter: string@filter-completer-1 # Filter event type ("spiders"/"uniques"/"nonuniques"/"conversions")
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/groups/{id}/hits"
    path_params: [{name: id, var: id}]
    query: [{name: timeframe, var: timeframe, required: true}, {name: limit, var: limit}, {name: offset, var: offset}, {name: fromDay, var: from_day}, {name: toDay, var: to_day}, {name: filter, var: filter}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    id: $id, timeframe: $timeframe, limit: $limit, offset: $offset, from_day: $from_day, to_day: $to_day, filter: $filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Fast patch the "notes" field of a group
#
# PUT /groups/{id}/notes
# Returns: record<id: int, uri: string>
# operationId: Groups_PatchNotes
export def "groups-patch-notes" [
  id: int
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
  --text: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/groups/{id}/notes"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Text, var: text}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    id: $id, text: $text
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve the list of events related to this account.
#
# GET /hits
# Returns: record<hits: table<accessTime: string, browser: record, clientLanguage: string, conversion1: record, conversion2: record, conversion3: record, conversion4: record, conversion5: record, conversions: list, entity: record, ip: string, isProxy: string, isSpider: string, isUnique: string, location: record, org: string, os: record, queryParams: string, realDestinationUrl: string, referer: string, source: record, type: string>, lastKey: string>
# operationId: Hits_GetHits
export def "hits-get-hits" [
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
  --timeframe: string@timeframe-completer # Timeframe of the request. See list at $timeframeList (required)
  --limit: int # Limit results to this number (format: int32)
  --offset: string # Offset where to start from (it's the lastKey field in the response object)
  --from-day: string # If using a "custom" timeFrame you can specify the starting day (YYYYMMDD)
  --to-day: string # If using a "custom" timeFrame you can specify the ending day (YYYYMMDD)
  --filter: string@filter-completer-1 # Filter event type ("spiders"/"uniques"/"nonuniques"/"conversions")
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/hits"
    query: [{name: timeframe, var: timeframe, required: true}, {name: limit, var: limit}, {name: offset, var: offset}, {name: fromDay, var: from_day}, {name: toDay, var: to_day}, {name: filter, var: filter}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    timeframe: $timeframe, limit: $limit, offset: $offset, from_day: $from_day, to_day: $to_day, filter: $filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve current account data
#
# GET /me
# Returns: record<boGoVal: string, bonusClicks: int, companyName: string, companyRole: string, email: string, firstName: string, lastName: string, phone: string, redirectOnly: bool, registrationDate: string, timeframeMinDate: string, timezone: int, timezonename: string>
# operationId: Me_GetMe
export def "me-get-me" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/me"
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve current account plan
#
# GET /me/plan
# Returns: record<allowedPersonalDomains: int, allowedPersonalUrls: int, billingPeriodEnd: string, billingPeriodStart: string, bonusMonthlyEvents: int, maximumDatapoints: int, maximumGuests: int, monthlyEvents: int, name: string, price: float, profileId: int, recurring: bool, recurringPeriod: int, usedDatapoints: int, usedMonthlyEvents: int>
# operationId: Me_GetMePlan
export def "me-get-me-plan" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/me/plan"
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List of all the retargeting scripts associated to the user
#
# GET /retargeting
# Returns: record<entities: table<id: int, uri: string>>
# operationId: Retargeting_Get
export def "retargeting-get" [
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
  --offset: int # Where to start when retrieving elements. Default is 0 if not specified. (format: int32, default: 0)
  --limit: int # Maximum elements to retrieve. Default to 20 if not specified. (format: int32, default: 20)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/retargeting"
    query: [{name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Creates a retargeting script
#
# POST /retargeting
# Returns: record<id: int, uri: string>
# operationId: Retargeting_Put
export def "retargeting-put" [
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
  --id: int # format: int64
  --name: string
  --script: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/retargeting"
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}, {name: name, var: name}, {name: script, var: script}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    id: $id, name: $name, script: $script
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve count of retargeting scripts
#
# GET /retargeting/count
# Returns: record<count: int>
# operationId: Retargeting_Count
export def "retargeting-count" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/retargeting/count"
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Deletes a retargeting script (and remove associations)
#
# DELETE /retargeting/{id}
# Returns: record<id: int, uri: string>
# operationId: Retargeting_Delete
export def "retargeting-delete" [
  id: int
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/retargeting/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a retargeting script object
#
# GET /retargeting/{id}
# Returns: record<id: int, name: string, script: string>
export def "get-retargeting-id" [
  id: int
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/retargeting/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Updates a retargeting script
#
# POST /retargeting/{id}
# Returns: record<id: int, uri: string>
# operationId: Retargeting_Post
export def "retargeting-post" [
  id: int
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
  --body-id: int # format: int64 (spec name: id)
  --name: string
  --script: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/retargeting/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: body_id}, {name: name, var: name}, {name: script, var: script}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    id: $id, body_id: $body_id, name: $name, script: $script
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List of all the datapoints associated to the retargeting script.
#
# GET /retargeting/{id}/datapoints
# Returns: record<entities: table<id: int, uri: string>>
# operationId: Retargeting_GetDatapoints
export def "retargeting-get-datapoints" [
  id: int
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
  --offset: int # Where to start when retrieving elements. Default is 0 if not specified. (format: int32, default: 0)
  --limit: int # Maximum elements to retrieve. Default to 20 if not specified. (format: int32, default: 20)
  --status: string@status-completer-1 # Status of the datapoint
  --tags: string # A comma separated list of tags you want to filter with.
  --text-search: string # Filter fields by this pattern
  --only-favorites: oneof<nothing, bool> # Filter fields by favourite status
  --sort-by: string # Field to sort by
  --sort-direction: string@sort-direction-completer # Direction of sort "asc" or "desc"
  --created-after: string # Exclude datapoints created before this date (YYYYMMDD)
  --created-before: string # Exclude datapoints created after this date (YYYYMMDD)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/retargeting/{id}/datapoints"
    path_params: [{name: id, var: id}]
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: status, var: status}, {name: tags, var: tags}, {name: textSearch, var: text_search}, {name: onlyFavorites, var: only_favorites}, {name: sortBy, var: sort_by}, {name: sortDirection, var: sort_direction}, {name: createdAfter, var: created_after}, {name: createdBefore, var: created_before}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    id: $id, offset: $offset, limit: $limit, status: $status, tags: $tags, text_search: $text_search, only_favorites: $only_favorites, sort_by: $sort_by, sort_direction: $sort_direction, created_after: $created_after, created_before: $created_before
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Count the datapoints associated to the retargeting script.
#
# GET /retargeting/{id}/datapoints/count
# Returns: record<count: int>
# operationId: Retargeting_GetDatapointsCount
export def "retargeting-get-datapoints-count" [
  id: int
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
  --status: string@status-completer-1 # Status of the datapoint
  --tags: string # A comma separated list of tags you want to filter with.
  --text-search: string # Filter fields by this pattern
  --only-favorites: oneof<nothing, bool> # Filter fields by favourite status
  --created-after: string # Exclude datapoints created before this date (YYYYMMDD)
  --created-before: string # Exclude datapoints created after this date (YYYYMMDD)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/retargeting/{id}/datapoints/count"
    path_params: [{name: id, var: id}]
    query: [{name: status, var: status}, {name: tags, var: tags}, {name: textSearch, var: text_search}, {name: onlyFavorites, var: only_favorites}, {name: createdAfter, var: created_after}, {name: createdBefore, var: created_before}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    id: $id, status: $status, tags: $tags, text_search: $text_search, only_favorites: $only_favorites, created_after: $created_after, created_before: $created_before
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List of all the groups associated to the user filtered by this tag.
#
# GET /tags
# Returns: record<entities: table<id: int, uri: string>>
# operationId: Tags_Get
export def "tags-get" [
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
  --offset: int # Where to start when retrieving elements. Default is 0 if not specified. (format: int32, default: 0)
  --limit: int # Maximum elements to retrieve. Default to 20 if not specified. (format: int32, default: 20)
  --name: string # Name of the tag
  --datapoints: string # Comma separated list of datapoints id to filter by
  --groups: string # Comma separated list of groups id to filter by
  --type: string@type-completer-6 # Type of entity related to the tag
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/tags"
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: name, var: name}, {name: datapoints, var: datapoints}, {name: groups, var: groups}, {name: type, var: type}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    offset: $offset, limit: $limit, name: $name, datapoints: $datapoints, groups: $groups, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a tag
#
# POST /tags
# Returns: record<id: int, uri: string>
# operationId: Tags_Put
export def "tags-put" [
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
  --datapoints: list<int>
  --groups: list<int>
  --id: int # format: int64
  --name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tags"
    body: {content_type: "application/json", kind: json, fields: [{name: datapoints, var: datapoints}, {name: groups, var: groups}, {name: id, var: id}, {name: name, var: name}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    datapoints: $datapoints, groups: $groups, id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List of all the groups associated to the user filtered by this tag.
#
# GET /tags/count
# Returns: record
# operationId: Tags_Count
export def "tags-count" [
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
  --name: string # Name of the tag
  --datapoints: string # Comma separated list of datapoints id to filter by
  --groups: string # Comma separated list of groups id to filter by
  --type: string@type-completer-6 # Type of entity related to the tag
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/tags/count"
    query: [{name: name, var: name}, {name: datapoints, var: datapoints}, {name: groups, var: groups}, {name: type, var: type}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    name: $name, datapoints: $datapoints, groups: $groups, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a tag
#
# DELETE /tags/{tagId}
# Returns: record
# operationId: Tags_Delete
export def "tags-delete" [
  tag_id: int
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/tags/{tagId}"
    path_params: [{name: tagId, var: tag_id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    tag_id: $tag_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve a tag
#
# GET /tags/{tagId}
# Returns: record<datapoints: list<int>, groups: list<int>, id: int, name: string>
export def "get-tags-tag-id" [
  tag_id: int
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/tags/{tagId}"
    path_params: [{name: tagId, var: tag_id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    tag_id: $tag_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete the association of this tag with all datapoints
#
# DELETE /tags/{tagId}/datapoints
# Returns: record<id: int, uri: string>
# operationId: Tags_DeleteRelatedDatapoints
export def "tags-delete-related-datapoints" [
  tag_id: int
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/tags/{tagId}/datapoints"
    path_params: [{name: tagId, var: tag_id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    tag_id: $tag_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List of all the datapoints associated to the user filtered by this tag
#
# GET /tags/{tagId}/datapoints
# Returns: record<entities: table<id: int, uri: string>>
# operationId: Tags_GetDatapoints
export def "tags-get-datapoints" [
  tag_id: int
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
  --offset: int # Where to start when retrieving elements. Default is 0 if not specified. (format: int32, default: 0)
  --limit: int # Maximum elements to retrieve. Default to 20 if not specified. (format: int32, default: 20)
  --type: string@type-completer-2 # Type of the datapoint ("tp"/"tl")
  --status: string@status-completer-1 # Status of the datapoint
  --text-search: string # Filter fields by this pattern
  --created-after: string # Exclude datapoints created before this date (YYYYMMDD)
  --created-before: string # Exclude datapoints created after this date (YYYYMMDD)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/tags/{tagId}/datapoints"
    path_params: [{name: tagId, var: tag_id}]
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: type, var: type}, {name: status, var: status}, {name: textSearch, var: text_search}, {name: createdAfter, var: created_after}, {name: createdBefore, var: created_before}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    tag_id: $tag_id, offset: $offset, limit: $limit, type: $type, status: $status, text_search: $text_search, created_after: $created_after, created_before: $created_before
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Count the datapoints associated to the user filtered by this tag
#
# GET /tags/{tagId}/datapoints/count
# Returns: record<count: int>
# operationId: Tags_GetDatapointsCount
export def "tags-get-datapoints-count" [
  tag_id: int
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
  --type: string@type-completer-2 # Type of the datapoint ("tp"/"tl")
  --status: string@status-completer-1 # Status of the datapoint
  --text-search: string # Filter fields by this pattern
  --created-after: string # Exclude datapoints created before this date (YYYYMMDD)
  --created-before: string # Exclude datapoints created after this date (YYYYMMDD)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/tags/{tagId}/datapoints/count"
    path_params: [{name: tagId, var: tag_id}]
    query: [{name: type, var: type}, {name: status, var: status}, {name: textSearch, var: text_search}, {name: createdAfter, var: created_after}, {name: createdBefore, var: created_before}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    tag_id: $tag_id, type: $type, status: $status, text_search: $text_search, created_after: $created_after, created_before: $created_before
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Associate/Deassociate a tag with a datapoint
#
# PUT /tags/{tagId}/datapoints/patch
# Returns: record<id: int, uri: string>
# operationId: Tags_PatchDataPoint
export def "tags-patch-data-point" [
  tag_id: int
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
  --action: string
  --id: int # format: int64
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/tags/{tagId}/datapoints/patch"
    path_params: [{name: tagId, var: tag_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Action, var: action}, {name: Id, var: id}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    tag_id: $tag_id, action: $action, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete the association of this tag with all groups
#
# DELETE /tags/{tagId}/groups
# Returns: record<id: int, uri: string>
# operationId: Tags_DeleteRelatedGroups
export def "tags-delete-related-groups" [
  tag_id: int
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/tags/{tagId}/groups"
    path_params: [{name: tagId, var: tag_id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    tag_id: $tag_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List of all the groups associated to the user filtered by this tag.
#
# GET /tags/{tagId}/groups
# Returns: record<entities: table<id: int, uri: string>>
# operationId: Tags_GetGroups
export def "tags-get-groups" [
  tag_id: int
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
  --offset: int # Where to start when retrieving elements. Default is 0 if not specified. (format: int32, default: 0)
  --limit: int # Maximum elements to retrieve. Default to 20 if not specified. (format: int32, default: 20)
  --status: string@status-completer # Status of the datapoint
  --text-search: string # Filter fields by this pattern
  --created-after: string # Exclude groups created before this date (YYYYMMDD)
  --created-before: string # Exclude groups created after this date (YYYYMMDD)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/tags/{tagId}/groups"
    path_params: [{name: tagId, var: tag_id}]
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: status, var: status}, {name: textSearch, var: text_search}, {name: createdAfter, var: created_after}, {name: createdBefore, var: created_before}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    tag_id: $tag_id, offset: $offset, limit: $limit, status: $status, text_search: $text_search, created_after: $created_after, created_before: $created_before
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Count the groups associated to the user filtered by this tag
#
# GET /tags/{tagId}/groups/count
# Returns: record<count: int>
# operationId: Tags_GetGroupsCount
export def "tags-get-groups-count" [
  tag_id: int
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
  --status: string@status-completer # Status of the datapoint
  --text-search: string # Filter fields by this pattern
  --created-after: string # Exclude groups created before this date (YYYYMMDD)
  --created-before: string # Exclude groups created after this date (YYYYMMDD)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/tags/{tagId}/groups/count"
    path_params: [{name: tagId, var: tag_id}]
    query: [{name: status, var: status}, {name: textSearch, var: text_search}, {name: createdAfter, var: created_after}, {name: createdBefore, var: created_before}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    tag_id: $tag_id, status: $status, text_search: $text_search, created_after: $created_after, created_before: $created_before
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Associate/Deassociate a tag with a group
#
# PUT /tags/{tagId}/groups/patch
# Returns: record<id: int, uri: string>
# operationId: Tags_PatchGroup
export def "tags-patch-group" [
  tag_id: int
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
  --action: string
  --id: int # format: int64
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/tags/{tagId}/groups/patch"
    path_params: [{name: tagId, var: tag_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Action, var: action}, {name: Id, var: id}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    tag_id: $tag_id, action: $action, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Fast patch a tag name
#
# PUT /tags/{tagId}/name
# Returns: record<id: int, uri: string>
# operationId: Tags_PatchTagName
export def "tags-patch-tag-name" [
  tag_id: int
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
  --text: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/tags/{tagId}/name"
    path_params: [{name: tagId, var: tag_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Text, var: text}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-clickmeter-authkey
  } {
    tag_id: $tag_id, text: $text
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}
