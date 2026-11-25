# Auto-generated client for Traccar v5.6
# Source: https://api.apis.guru/v2/specs/traccar.org/5.6/openapi.json
# Auth: --token flag or $env.TRACCAR_TOKEN

const CLIENT = {
  base_url: "https://demo.traccar.org/api"
  token_env_var: "TRACCAR_TOKEN"
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

def base-url-completer [] { ["https://demo.traccar.org/api" "https://demo2.traccar.org/api" "https://demo3.traccar.org/api" "https://demo4.traccar.org/api" "https://server.traccar.org/api" "http://localhost:8082/api" "http://localhost:80/api"] }
def auth-scheme-completer [] { ["basic" "basic-credentials"] }

# Completers for enum parameters
def accept-completer [] { ["application/gpx+xml" "application/json" "text/csv"] }
def accept-completer-1 [] { ["application/json" "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-attributes-computed: "table<attribute: string, description: string, expression: string, id: int, type: string>"
    post-attributes-computed: "record<attribute: string, description: string, expression: string, id: int, type: string>"
    put-attributes-computed-id: "record<attribute: string, description: string, expression: string, id: int, type: string>"
    get-calendars: "table<attributes: record, data: string, id: int, name: string>"
    post-calendars: "record<attributes: record, data: string, id: int, name: string>"
    put-calendars-id: "record<attributes: record, data: string, id: int, name: string>"
    get-commands: "table<attributes: record, description: string, deviceId: int, id: int, type: string>"
    post-commands: "record<attributes: record, description: string, deviceId: int, id: int, type: string>"
    get-commands-send: "table<attributes: record, description: string, deviceId: int, id: int, type: string>"
    post-commands-send: "record<attributes: record, description: string, deviceId: int, id: int, type: string>"
    get-commands-types: "table<type: string>"
    put-commands-id: "record<attributes: record, description: string, deviceId: int, id: int, type: string>"
    get-devices: "table<attributes: record, category: string, contact: string, disabled: bool, geofenceIds: list<int>, groupId: int, id: int, lastUpdate: string, model: string, name: string, phone: string, positionId: int, status: string, uniqueId: string>"
    post-devices: "record<attributes: record, category: string, contact: string, disabled: bool, geofenceIds: list<int>, groupId: int, id: int, lastUpdate: string, model: string, name: string, phone: string, positionId: int, status: string, uniqueId: string>"
    put-devices-id: "record<attributes: record, category: string, contact: string, disabled: bool, geofenceIds: list<int>, groupId: int, id: int, lastUpdate: string, model: string, name: string, phone: string, positionId: int, status: string, uniqueId: string>"
    get-drivers: "table<attributes: record, id: int, name: string, uniqueId: string>"
    post-drivers: "record<attributes: record, id: int, name: string, uniqueId: string>"
    put-drivers-id: "record<attributes: record, id: int, name: string, uniqueId: string>"
    get-events-id: "record<attributes: record, deviceId: int, eventTime: string, geofenceId: int, id: int, maintenanceId: int, positionId: int, type: string>"
    get-geofences: "table<area: string, attributes: record, calendarId: int, description: string, id: int, name: string>"
    post-geofences: "record<area: string, attributes: record, calendarId: int, description: string, id: int, name: string>"
    put-geofences-id: "record<area: string, attributes: record, calendarId: int, description: string, id: int, name: string>"
    get-groups: "table<attributes: record, groupId: int, id: int, name: string>"
    post-groups: "record<attributes: record, groupId: int, id: int, name: string>"
    put-groups-id: "record<attributes: record, groupId: int, id: int, name: string>"
    get-maintenance: "table<attributes: record, id: int, name: string, period: float, start: float, type: string>"
    post-maintenance: "record<attributes: record, id: int, name: string, period: float, start: float, type: string>"
    put-maintenance-id: "record<attributes: record, id: int, name: string, period: float, start: float, type: string>"
    get-notifications: "table<always: bool, attributes: record, calendarId: int, id: int, mail: bool, sms: bool, type: string, web: bool>"
    post-notifications: "record<always: bool, attributes: record, calendarId: int, id: int, mail: bool, sms: bool, type: string, web: bool>"
    get-notifications-types: "table<type: string>"
    put-notifications-id: "record<always: bool, attributes: record, calendarId: int, id: int, mail: bool, sms: bool, type: string, web: bool>"
    post-permissions: "record<attributeId: int, calendarId: int, deviceId: int, driverId: int, geofenceId: int, groupId: int, managedUserId: int, notificationId: int, userId: int>"
    get-positions: "table<accuracy: float, address: string, altitude: float, attributes: record, course: float, deviceId: int, deviceTime: string, fixTime: string, id: int, latitude: float, longitude: float, network: record, outdated: bool, protocol: string, serverTime: string, speed: float, valid: bool>"
    get-reports-events: "table<attributes: record, deviceId: int, eventTime: string, geofenceId: int, id: int, maintenanceId: int, positionId: int, type: string>"
    get-reports-route: "table<accuracy: float, address: string, altitude: float, attributes: record, course: float, deviceId: int, deviceTime: string, fixTime: string, id: int, latitude: float, longitude: float, network: record, outdated: bool, protocol: string, serverTime: string, speed: float, valid: bool>"
    get-reports-stops: "table<address: string, deviceId: int, deviceName: string, duration: int, endTime: string, engineHours: int, lat: float, lon: float, spentFuel: float, startTime: string>"
    get-reports-summary: "table<averageSpeed: float, deviceId: int, deviceName: string, distance: float, engineHours: int, maxSpeed: float, spentFuel: float>"
    get-reports-trips: "table<averageSpeed: float, deviceId: int, deviceName: string, distance: float, driverName: string, driverUniqueId: int, duration: int, endAddress: string, endLat: float, endLon: float, endTime: string, maxSpeed: float, spentFuel: float, startAddress: string, startLat: float, startLon: float, startTime: string>"
    get-server: "record<attributes: record, bingKey: string, coordinateFormat: string, deviceReadonly: bool, forceSettings: bool, id: int, latitude: float, limitCommands: bool, longitude: float, map: string, mapUrl: string, poiLayer: string, readonly: bool, registration: bool, twelveHourFormat: bool, version: string, zoom: int>"
    put-server: "record<attributes: record, bingKey: string, coordinateFormat: string, deviceReadonly: bool, forceSettings: bool, id: int, latitude: float, limitCommands: bool, longitude: float, map: string, mapUrl: string, poiLayer: string, readonly: bool, registration: bool, twelveHourFormat: bool, version: string, zoom: int>"
    get-session: "record<administrator: bool, attributes: record, coordinateFormat: string, deviceLimit: int, deviceReadonly: bool, disabled: bool, email: string, expirationTime: string, id: int, latitude: float, limitCommands: bool, longitude: float, map: string, name: string, password: string, phone: string, poiLayer: string, readonly: bool, twelveHourFormat: bool, userLimit: int, zoom: int>"
    post-session: "record<administrator: bool, attributes: record, coordinateFormat: string, deviceLimit: int, deviceReadonly: bool, disabled: bool, email: string, expirationTime: string, id: int, latitude: float, limitCommands: bool, longitude: float, map: string, name: string, password: string, phone: string, poiLayer: string, readonly: bool, twelveHourFormat: bool, userLimit: int, zoom: int>"
    get-statistics: "table<activeDevices: int, activeUsers: int, captureTime: string, messagesReceived: int, messagesStored: int, requests: int>"
    get-users: "table<administrator: bool, attributes: record, coordinateFormat: string, deviceLimit: int, deviceReadonly: bool, disabled: bool, email: string, expirationTime: string, id: int, latitude: float, limitCommands: bool, longitude: float, map: string, name: string, password: string, phone: string, poiLayer: string, readonly: bool, twelveHourFormat: bool, userLimit: int, zoom: int>"
    post-users: "record<administrator: bool, attributes: record, coordinateFormat: string, deviceLimit: int, deviceReadonly: bool, disabled: bool, email: string, expirationTime: string, id: int, latitude: float, limitCommands: bool, longitude: float, map: string, name: string, password: string, phone: string, poiLayer: string, readonly: bool, twelveHourFormat: bool, userLimit: int, zoom: int>"
    put-users-id: "record<administrator: bool, attributes: record, coordinateFormat: string, deviceLimit: int, deviceReadonly: bool, disabled: bool, email: string, expirationTime: string, id: int, latitude: float, limitCommands: bool, longitude: float, map: string, name: string, password: string, phone: string, poiLayer: string, readonly: bool, twelveHourFormat: bool, userLimit: int, zoom: int>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-attributes-computed" "post-attributes-computed" "delete-attributes-computed-id" "put-attributes-computed-id" "get-calendars" "post-calendars" "delete-calendars-id" "put-calendars-id" "get-commands" "post-commands" "get-commands-send" "post-commands-send" "get-commands-types" "delete-commands-id" "put-commands-id" "get-devices" "post-devices" "delete-devices-id" "put-devices-id" "put-devices-id-accumulators" "get-drivers" "post-drivers" "delete-drivers-id" "put-drivers-id" "get-events-id" "get-geofences" "post-geofences" "delete-geofences-id" "put-geofences-id" "get-groups" "post-groups" "delete-groups-id" "put-groups-id" "get-maintenance" "post-maintenance" "delete-maintenance-id" "put-maintenance-id" "get-notifications" "post-notifications" "post-notifications-test" "get-notifications-types" "delete-notifications-id" "put-notifications-id" "delete-permissions" "post-permissions" "get-positions" "get-reports-events" "get-reports-route" "get-reports-stops" "get-reports-summary" "get-reports-trips" "get-server" "put-server" "delete-session" "get-session" "post-session" "get-statistics" "get-users" "post-users" "delete-users-id" "put-users-id" "commands"] | sort) } | get name | first)
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

# Fetch a list of Attributes
#
# GET /attributes/computed
# Returns: table<attribute: string, description: string, expression: string, id: int, type: string>
export def "get-attributes-computed" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --all: oneof<nothing, bool> # Can only be used by admins or managers to fetch all entities
  --user-id: int # Standard users can use this only with their own _userId_
  --device-id: int # Standard users can use this only with _deviceId_s, they have access to
  --group-id: int # Standard users can use this only with _groupId_s, they have access to
  --refresh: oneof<nothing, bool>
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/attributes/computed"
    query: [{name: all, var: all}, {name: userId, var: user_id}, {name: deviceId, var: device_id}, {name: groupId, var: group_id}, {name: refresh, var: refresh}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    all: $all, user_id: $user_id, device_id: $device_id, group_id: $group_id, refresh: $refresh
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an Attribute
#
# POST /attributes/computed
# Returns: record<attribute: string, description: string, expression: string, id: int, type: string>
export def "post-attributes-computed" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attribute: string
  --description: string
  --expression: string
  --id: int
  --type: string # String|Number|Boolean
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/attributes/computed"
    body: {content_type: "application/json", kind: json, fields: [{name: attribute, var: attribute}, {name: description, var: description}, {name: expression, var: expression}, {name: id, var: id}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    attribute: $attribute, description: $description, expression: $expression, id: $id, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an Attribute
#
# DELETE /attributes/computed/{id}
export def "delete-attributes-computed-id" [
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/attributes/computed/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an Attribute
#
# PUT /attributes/computed/{id}
# Returns: record<attribute: string, description: string, expression: string, id: int, type: string>
export def "put-attributes-computed-id" [
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
  --attribute: string
  --description: string
  --expression: string
  --body-id: int # (spec name: id)
  --type: string # String|Number|Boolean
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/attributes/computed/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: attribute, var: attribute}, {name: description, var: description}, {name: expression, var: expression}, {name: id, var: body_id}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, attribute: $attribute, description: $description, expression: $expression, body_id: $body_id, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a list of Calendars
#
# GET /calendars
# Returns: table<attributes: record, data: string, id: int, name: string>
export def "get-calendars" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --all: oneof<nothing, bool> # Can only be used by admins or managers to fetch all entities
  --user-id: int # Standard users can use this only with their own _userId_
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/calendars"
    query: [{name: all, var: all}, {name: userId, var: user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    all: $all, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a Calendar
#
# POST /calendars
# Returns: record<attributes: record, data: string, id: int, name: string>
export def "post-calendars" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: record
  --data: string # base64 encoded in iCalendar format
  --id: int
  --name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/calendars"
    body: {content_type: "application/json", kind: json, fields: [{name: attributes, var: attributes}, {name: data, var: data}, {name: id, var: id}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    attributes: $attributes, data: $data, id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a Calendar
#
# DELETE /calendars/{id}
export def "delete-calendars-id" [
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/calendars/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a Calendar
#
# PUT /calendars/{id}
# Returns: record<attributes: record, data: string, id: int, name: string>
export def "put-calendars-id" [
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
  --attributes: record
  --data: string # base64 encoded in iCalendar format
  --body-id: int # (spec name: id)
  --name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/calendars/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: attributes, var: attributes}, {name: data, var: data}, {name: id, var: body_id}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, attributes: $attributes, data: $data, body_id: $body_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a list of Saved Commands
#
# GET /commands
# Returns: table<attributes: record, description: string, deviceId: int, id: int, type: string>
export def "get-commands" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --all: oneof<nothing, bool> # Can only be used by admins or managers to fetch all entities
  --user-id: int # Standard users can use this only with their own _userId_
  --device-id: int # Standard users can use this only with _deviceId_s, they have access to
  --group-id: int # Standard users can use this only with _groupId_s, they have access to
  --refresh: oneof<nothing, bool>
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/commands"
    query: [{name: all, var: all}, {name: userId, var: user_id}, {name: deviceId, var: device_id}, {name: groupId, var: group_id}, {name: refresh, var: refresh}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    all: $all, user_id: $user_id, device_id: $device_id, group_id: $group_id, refresh: $refresh
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a Saved Command
#
# POST /commands
# Returns: record<attributes: record, description: string, deviceId: int, id: int, type: string>
export def "post-commands" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: record
  --description: string
  --device-id: int
  --id: int
  --type: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/commands"
    body: {content_type: "application/json", kind: json, fields: [{name: attributes, var: attributes}, {name: description, var: description}, {name: deviceId, var: device_id}, {name: id, var: id}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    attributes: $attributes, description: $description, device_id: $device_id, id: $id, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a list of Saved Commands supported by Device at the moment
#
# GET /commands/send
# Returns: table<attributes: record, description: string, deviceId: int, id: int, type: string>
export def "get-commands-send" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --device-id: int # Standard users can use this only with _deviceId_s, they have access to
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/commands/send"
    query: [{name: deviceId, var: device_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    device_id: $device_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Dispatch commands to device
#
# POST /commands/send
# Returns: record<attributes: record, description: string, deviceId: int, id: int, type: string>
export def "post-commands-send" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: record
  --description: string
  --device-id: int
  --id: int
  --type: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/commands/send"
    body: {content_type: "application/json", kind: json, fields: [{name: attributes, var: attributes}, {name: description, var: description}, {name: deviceId, var: device_id}, {name: id, var: id}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: basic
  } {
    attributes: $attributes, description: $description, device_id: $device_id, id: $id, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a list of available Commands for the Device or all possible Commands if Device ommited
#
# GET /commands/types
# Returns: table<type: string>
export def "get-commands-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --device-id: int # Internal device identifier. Only works if device has already reported some locations
  --protocol: string # Protocol name. Can be used instead of device id
  --text-channel: oneof<nothing, bool> # When `true` return SMS commands. If not specified or `false` return data commands
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/commands/types"
    query: [{name: deviceId, var: device_id}, {name: protocol, var: protocol}, {name: textChannel, var: text_channel}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    device_id: $device_id, protocol: $protocol, text_channel: $text_channel
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a Saved Command
#
# DELETE /commands/{id}
export def "delete-commands-id" [
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/commands/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a Saved Command
#
# PUT /commands/{id}
# Returns: record<attributes: record, description: string, deviceId: int, id: int, type: string>
export def "put-commands-id" [
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
  --attributes: record
  --description: string
  --device-id: int
  --body-id: int # (spec name: id)
  --type: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/commands/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: attributes, var: attributes}, {name: description, var: description}, {name: deviceId, var: device_id}, {name: id, var: body_id}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, attributes: $attributes, description: $description, device_id: $device_id, body_id: $body_id, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a list of Devices
#
# GET /devices
# Returns: table<attributes: record, category: string, contact: string, disabled: bool, geofenceIds: list<int>, groupId: int, id: int, lastUpdate: string, model: string, name: string, phone: string, positionId: int, status: string, uniqueId: string>
export def "get-devices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --all: oneof<nothing, bool> # Can only be used by admins or managers to fetch all entities
  --user-id: int # Standard users can use this only with their own _userId_
  --id: int # To fetch one or more devices. Multiple params can be passed like `id=31&id=42`
  --unique-id: string # To fetch one or more devices. Multiple params can be passed like `uniqueId=333331&uniqieId=44442`
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/devices"
    query: [{name: all, var: all}, {name: userId, var: user_id}, {name: id, var: id}, {name: uniqueId, var: unique_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    all: $all, user_id: $user_id, id: $id, unique_id: $unique_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a Device
#
# POST /devices
# Returns: record<attributes: record, category: string, contact: string, disabled: bool, geofenceIds: list<int>, groupId: int, id: int, lastUpdate: string, model: string, name: string, phone: string, positionId: int, status: string, uniqueId: string>
export def "post-devices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: record
  --category: string
  --contact: string
  --disabled: oneof<nothing, bool>
  --geofence-ids: list<int>
  --group-id: int
  --id: int
  --last-update: string # in IS0 8601 format. eg. `1963-11-22T18:30:00Z` (format: date-time)
  --model: string
  --name: string
  --phone: string
  --position-id: int
  --status: string
  --unique-id: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/devices"
    body: {content_type: "application/json", kind: json, fields: [{name: attributes, var: attributes}, {name: category, var: category}, {name: contact, var: contact}, {name: disabled, var: disabled}, {name: geofenceIds, var: geofence_ids}, {name: groupId, var: group_id}, {name: id, var: id}, {name: lastUpdate, var: last_update}, {name: model, var: model}, {name: name, var: name}, {name: phone, var: phone}, {name: positionId, var: position_id}, {name: status, var: status}, {name: uniqueId, var: unique_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    attributes: $attributes, category: $category, contact: $contact, disabled: $disabled, geofence_ids: $geofence_ids, group_id: $group_id, id: $id, last_update: $last_update, model: $model, name: $name, phone: $phone, position_id: $position_id, status: $status, unique_id: $unique_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a Device
#
# DELETE /devices/{id}
export def "delete-devices-id" [
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/devices/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a Device
#
# PUT /devices/{id}
# Returns: record<attributes: record, category: string, contact: string, disabled: bool, geofenceIds: list<int>, groupId: int, id: int, lastUpdate: string, model: string, name: string, phone: string, positionId: int, status: string, uniqueId: string>
export def "put-devices-id" [
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
  --attributes: record
  --category: string
  --contact: string
  --disabled: oneof<nothing, bool>
  --geofence-ids: list<int>
  --group-id: int
  --body-id: int # (spec name: id)
  --last-update: string # in IS0 8601 format. eg. `1963-11-22T18:30:00Z` (format: date-time)
  --model: string
  --name: string
  --phone: string
  --position-id: int
  --status: string
  --unique-id: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/devices/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: attributes, var: attributes}, {name: category, var: category}, {name: contact, var: contact}, {name: disabled, var: disabled}, {name: geofenceIds, var: geofence_ids}, {name: groupId, var: group_id}, {name: id, var: body_id}, {name: lastUpdate, var: last_update}, {name: model, var: model}, {name: name, var: name}, {name: phone, var: phone}, {name: positionId, var: position_id}, {name: status, var: status}, {name: uniqueId, var: unique_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, attributes: $attributes, category: $category, contact: $contact, disabled: $disabled, geofence_ids: $geofence_ids, group_id: $group_id, body_id: $body_id, last_update: $last_update, model: $model, name: $name, phone: $phone, position_id: $position_id, status: $status, unique_id: $unique_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update total distance and hours of the Device
#
# PUT /devices/{id}/accumulators
export def "put-devices-id-accumulators" [
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
  --device-id: int
  --hours: float
  --total-distance: float # in meters
]: any -> any {
  $in | http-request {
    method: put
    path: "/devices/{id}/accumulators"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: deviceId, var: device_id}, {name: hours, var: hours}, {name: totalDistance, var: total_distance}]}
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    id: $id, device_id: $device_id, hours: $hours, total_distance: $total_distance
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a list of Drivers
#
# GET /drivers
# Returns: table<attributes: record, id: int, name: string, uniqueId: string>
export def "get-drivers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --all: oneof<nothing, bool> # Can only be used by admins or managers to fetch all entities
  --user-id: int # Standard users can use this only with their own _userId_
  --device-id: int # Standard users can use this only with _deviceId_s, they have access to
  --group-id: int # Standard users can use this only with _groupId_s, they have access to
  --refresh: oneof<nothing, bool>
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/drivers"
    query: [{name: all, var: all}, {name: userId, var: user_id}, {name: deviceId, var: device_id}, {name: groupId, var: group_id}, {name: refresh, var: refresh}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    all: $all, user_id: $user_id, device_id: $device_id, group_id: $group_id, refresh: $refresh
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a Driver
#
# POST /drivers
# Returns: record<attributes: record, id: int, name: string, uniqueId: string>
export def "post-drivers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: record
  --id: int
  --name: string
  --unique-id: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/drivers"
    body: {content_type: "application/json", kind: json, fields: [{name: attributes, var: attributes}, {name: id, var: id}, {name: name, var: name}, {name: uniqueId, var: unique_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    attributes: $attributes, id: $id, name: $name, unique_id: $unique_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a Driver
#
# DELETE /drivers/{id}
export def "delete-drivers-id" [
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/drivers/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a Driver
#
# PUT /drivers/{id}
# Returns: record<attributes: record, id: int, name: string, uniqueId: string>
export def "put-drivers-id" [
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
  --attributes: record
  --body-id: int # (spec name: id)
  --name: string
  --unique-id: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/drivers/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: attributes, var: attributes}, {name: id, var: body_id}, {name: name, var: name}, {name: uniqueId, var: unique_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, attributes: $attributes, body_id: $body_id, name: $name, unique_id: $unique_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /events/{id}
#
# Returns: record<attributes: record, deviceId: int, eventTime: string, geofenceId: int, id: int, maintenanceId: int, positionId: int, type: string>
export def "get-events-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/events/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a list of Geofences
#
# GET /geofences
# Returns: table<area: string, attributes: record, calendarId: int, description: string, id: int, name: string>
export def "get-geofences" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --all: oneof<nothing, bool> # Can only be used by admins or managers to fetch all entities
  --user-id: int # Standard users can use this only with their own _userId_
  --device-id: int # Standard users can use this only with _deviceId_s, they have access to
  --group-id: int # Standard users can use this only with _groupId_s, they have access to
  --refresh: oneof<nothing, bool>
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/geofences"
    query: [{name: all, var: all}, {name: userId, var: user_id}, {name: deviceId, var: device_id}, {name: groupId, var: group_id}, {name: refresh, var: refresh}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    all: $all, user_id: $user_id, device_id: $device_id, group_id: $group_id, refresh: $refresh
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a Geofence
#
# POST /geofences
# Returns: record<area: string, attributes: record, calendarId: int, description: string, id: int, name: string>
export def "post-geofences" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --area: string
  --attributes: record
  --calendar-id: int
  --description: string
  --id: int
  --name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/geofences"
    body: {content_type: "application/json", kind: json, fields: [{name: area, var: area}, {name: attributes, var: attributes}, {name: calendarId, var: calendar_id}, {name: description, var: description}, {name: id, var: id}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    area: $area, attributes: $attributes, calendar_id: $calendar_id, description: $description, id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a Geofence
#
# DELETE /geofences/{id}
export def "delete-geofences-id" [
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/geofences/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a Geofence
#
# PUT /geofences/{id}
# Returns: record<area: string, attributes: record, calendarId: int, description: string, id: int, name: string>
export def "put-geofences-id" [
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
  --area: string
  --attributes: record
  --calendar-id: int
  --description: string
  --body-id: int # (spec name: id)
  --name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/geofences/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: area, var: area}, {name: attributes, var: attributes}, {name: calendarId, var: calendar_id}, {name: description, var: description}, {name: id, var: body_id}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, area: $area, attributes: $attributes, calendar_id: $calendar_id, description: $description, body_id: $body_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a list of Groups
#
# GET /groups
# Returns: table<attributes: record, groupId: int, id: int, name: string>
export def "get-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --all: oneof<nothing, bool> # Can only be used by admins or managers to fetch all entities
  --user-id: int # Standard users can use this only with their own _userId_
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/groups"
    query: [{name: all, var: all}, {name: userId, var: user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    all: $all, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a Group
#
# POST /groups
# Returns: record<attributes: record, groupId: int, id: int, name: string>
export def "post-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: record
  --group-id: int
  --id: int
  --name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/groups"
    body: {content_type: "application/json", kind: json, fields: [{name: attributes, var: attributes}, {name: groupId, var: group_id}, {name: id, var: id}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    attributes: $attributes, group_id: $group_id, id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a Group
#
# DELETE /groups/{id}
export def "delete-groups-id" [
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/groups/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a Group
#
# PUT /groups/{id}
# Returns: record<attributes: record, groupId: int, id: int, name: string>
export def "put-groups-id" [
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
  --attributes: record
  --group-id: int
  --body-id: int # (spec name: id)
  --name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/groups/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: attributes, var: attributes}, {name: groupId, var: group_id}, {name: id, var: body_id}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, attributes: $attributes, group_id: $group_id, body_id: $body_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a list of Maintenance
#
# GET /maintenance
# Returns: table<attributes: record, id: int, name: string, period: float, start: float, type: string>
export def "get-maintenance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --all: oneof<nothing, bool> # Can only be used by admins or managers to fetch all entities
  --user-id: int # Standard users can use this only with their own _userId_
  --device-id: int # Standard users can use this only with _deviceId_s, they have access to
  --group-id: int # Standard users can use this only with _groupId_s, they have access to
  --refresh: oneof<nothing, bool>
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/maintenance"
    query: [{name: all, var: all}, {name: userId, var: user_id}, {name: deviceId, var: device_id}, {name: groupId, var: group_id}, {name: refresh, var: refresh}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    all: $all, user_id: $user_id, device_id: $device_id, group_id: $group_id, refresh: $refresh
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a Maintenance
#
# POST /maintenance
# Returns: record<attributes: record, id: int, name: string, period: float, start: float, type: string>
export def "post-maintenance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: record
  --id: int
  --name: string
  --period: float
  --start: float
  --type: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/maintenance"
    body: {content_type: "application/json", kind: json, fields: [{name: attributes, var: attributes}, {name: id, var: id}, {name: name, var: name}, {name: period, var: period}, {name: start, var: start}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    attributes: $attributes, id: $id, name: $name, period: $period, start: $start, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a Maintenance
#
# DELETE /maintenance/{id}
export def "delete-maintenance-id" [
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/maintenance/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a Maintenance
#
# PUT /maintenance/{id}
# Returns: record<attributes: record, id: int, name: string, period: float, start: float, type: string>
export def "put-maintenance-id" [
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
  --attributes: record
  --body-id: int # (spec name: id)
  --name: string
  --period: float
  --start: float
  --type: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/maintenance/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: attributes, var: attributes}, {name: id, var: body_id}, {name: name, var: name}, {name: period, var: period}, {name: start, var: start}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, attributes: $attributes, body_id: $body_id, name: $name, period: $period, start: $start, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a list of Notifications
#
# GET /notifications
# Returns: table<always: bool, attributes: record, calendarId: int, id: int, mail: bool, sms: bool, type: string, web: bool>
export def "get-notifications" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --all: oneof<nothing, bool> # Can only be used by admins or managers to fetch all entities
  --user-id: int # Standard users can use this only with their own _userId_
  --device-id: int # Standard users can use this only with _deviceId_s, they have access to
  --group-id: int # Standard users can use this only with _groupId_s, they have access to
  --refresh: oneof<nothing, bool>
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/notifications"
    query: [{name: all, var: all}, {name: userId, var: user_id}, {name: deviceId, var: device_id}, {name: groupId, var: group_id}, {name: refresh, var: refresh}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    all: $all, user_id: $user_id, device_id: $device_id, group_id: $group_id, refresh: $refresh
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a Notification
#
# POST /notifications
# Returns: record<always: bool, attributes: record, calendarId: int, id: int, mail: bool, sms: bool, type: string, web: bool>
export def "post-notifications" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --always: oneof<nothing, bool>
  --attributes: record
  --calendar-id: int
  --id: int
  --mail: oneof<nothing, bool>
  --sms: oneof<nothing, bool>
  --type: string
  --web: oneof<nothing, bool>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/notifications"
    body: {content_type: "application/json", kind: json, fields: [{name: always, var: always}, {name: attributes, var: attributes}, {name: calendarId, var: calendar_id}, {name: id, var: id}, {name: mail, var: mail}, {name: sms, var: sms}, {name: type, var: type}, {name: web, var: web}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    always: $always, attributes: $attributes, calendar_id: $calendar_id, id: $id, mail: $mail, sms: $sms, type: $type, web: $web
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send test notification to current user via Email and SMS
#
# POST /notifications/test
export def "post-notifications-test" [
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
    path: "/notifications/test"
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a list of available Notification types
#
# GET /notifications/types
# Returns: table<type: string>
export def "get-notifications-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/notifications/types"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a Notification
#
# DELETE /notifications/{id}
export def "delete-notifications-id" [
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/notifications/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a Notification
#
# PUT /notifications/{id}
# Returns: record<always: bool, attributes: record, calendarId: int, id: int, mail: bool, sms: bool, type: string, web: bool>
export def "put-notifications-id" [
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
  --always: oneof<nothing, bool>
  --attributes: record
  --calendar-id: int
  --body-id: int # (spec name: id)
  --mail: oneof<nothing, bool>
  --sms: oneof<nothing, bool>
  --type: string
  --web: oneof<nothing, bool>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/notifications/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: always, var: always}, {name: attributes, var: attributes}, {name: calendarId, var: calendar_id}, {name: id, var: body_id}, {name: mail, var: mail}, {name: sms, var: sms}, {name: type, var: type}, {name: web, var: web}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, always: $always, attributes: $attributes, calendar_id: $calendar_id, body_id: $body_id, mail: $mail, sms: $sms, type: $type, web: $web
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unlink an Object from another Object
#
# DELETE /permissions
export def "delete-permissions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attribute-id: int # Computed Attribute Id, can be second parameter only
  --calendar-id: int # Calendar Id, can be second parameter only and only in combination with userId
  --device-id: int # Device Id, can be first parameter or second only in combination with userId
  --driver-id: int # Driver Id, can be second parameter only
  --geofence-id: int # Geofence Id, can be second parameter only
  --group-id: int # Group Id, can be first parameter or second only in combination with userId
  --managed-user-id: int # User Id, can be second parameter only and only in combination with userId
  --notification-id: int # Notification Id, can be second parameter only
  --user-id: int # User Id, can be only first parameter
]: any -> any {
  $in | http-request {
    method: delete
    path: "/permissions"
    body: {content_type: "application/json", kind: json, fields: [{name: attributeId, var: attribute_id}, {name: calendarId, var: calendar_id}, {name: deviceId, var: device_id}, {name: driverId, var: driver_id}, {name: geofenceId, var: geofence_id}, {name: groupId, var: group_id}, {name: managedUserId, var: managed_user_id}, {name: notificationId, var: notification_id}, {name: userId, var: user_id}]}
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    attribute_id: $attribute_id, calendar_id: $calendar_id, device_id: $device_id, driver_id: $driver_id, geofence_id: $geofence_id, group_id: $group_id, managed_user_id: $managed_user_id, notification_id: $notification_id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Link an Object to another Object
#
# POST /permissions
# Returns: record<attributeId: int, calendarId: int, deviceId: int, driverId: int, geofenceId: int, groupId: int, managedUserId: int, notificationId: int, userId: int>
export def "post-permissions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attribute-id: int # Computed Attribute Id, can be second parameter only
  --calendar-id: int # Calendar Id, can be second parameter only and only in combination with userId
  --device-id: int # Device Id, can be first parameter or second only in combination with userId
  --driver-id: int # Driver Id, can be second parameter only
  --geofence-id: int # Geofence Id, can be second parameter only
  --group-id: int # Group Id, can be first parameter or second only in combination with userId
  --managed-user-id: int # User Id, can be second parameter only and only in combination with userId
  --notification-id: int # Notification Id, can be second parameter only
  --user-id: int # User Id, can be only first parameter
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/permissions"
    body: {content_type: "application/json", kind: json, fields: [{name: attributeId, var: attribute_id}, {name: calendarId, var: calendar_id}, {name: deviceId, var: device_id}, {name: driverId, var: driver_id}, {name: geofenceId, var: geofence_id}, {name: groupId, var: group_id}, {name: managedUserId, var: managed_user_id}, {name: notificationId, var: notification_id}, {name: userId, var: user_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    attribute_id: $attribute_id, calendar_id: $calendar_id, device_id: $device_id, driver_id: $driver_id, geofence_id: $geofence_id, group_id: $group_id, managed_user_id: $managed_user_id, notification_id: $notification_id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetches a list of Positions
#
# GET /positions
# Returns: table<accuracy: float, address: string, altitude: float, attributes: record, course: float, deviceId: int, deviceTime: string, fixTime: string, id: int, latitude: float, longitude: float, network: record, outdated: bool, protocol: string, serverTime: string, speed: float, valid: bool>
export def "get-positions" [
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
  --device-id: int # _deviceId_ is optional, but requires the _from_ and _to_ parameters when used
  --from: string # in IS0 8601 format. eg. `1963-11-22T18:30:00Z` (format: date-time)
  --to: string # in IS0 8601 format. eg. `1963-11-22T18:30:00Z` (format: date-time)
  --id: int # To fetch one or more positions. Multiple params can be passed like `id=31&id=42`
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/positions"
    query: [{name: deviceId, var: device_id}, {name: from, var: from}, {name: to, var: to}, {name: id, var: id}]
    accept: ["application/gpx+xml", "application/json", "text/csv"]
    ok: [200]
    auth: basic
  } {
    device_id: $device_id, from: $from, to: $to, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Fetch a list of Events within the time period for the Devices or Groups
#
# GET /reports/events
# Returns: table<attributes: record, deviceId: int, eventTime: string, geofenceId: int, id: int, maintenanceId: int, positionId: int, type: string>
export def "get-reports-events" [
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
  --device-id: list<int>
  --group-id: list<int>
  --type: list<string> # % can be used to return events of all types
  --from: string # in IS0 8601 format. eg. `1963-11-22T18:30:00Z` (required, format: date-time)
  --to: string # in IS0 8601 format. eg. `1963-11-22T18:30:00Z` (required, format: date-time)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/reports/events"
    query: [{name: deviceId, var: device_id, style: multi}, {name: groupId, var: group_id, style: multi}, {name: type, var: type, style: csv}, {name: from, var: from, required: true}, {name: to, var: to, required: true}]
    accept: ["application/json", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"]
    ok: [200]
    auth: basic
  } {
    device_id: $device_id, group_id: $group_id, type: $type, from: $from, to: $to
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Fetch a list of Positions within the time period for the Devices or Groups
#
# GET /reports/route
# Returns: table<accuracy: float, address: string, altitude: float, attributes: record, course: float, deviceId: int, deviceTime: string, fixTime: string, id: int, latitude: float, longitude: float, network: record, outdated: bool, protocol: string, serverTime: string, speed: float, valid: bool>
export def "get-reports-route" [
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
  --device-id: list<int>
  --group-id: list<int>
  --from: string # in IS0 8601 format. eg. `1963-11-22T18:30:00Z` (required, format: date-time)
  --to: string # in IS0 8601 format. eg. `1963-11-22T18:30:00Z` (required, format: date-time)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/reports/route"
    query: [{name: deviceId, var: device_id, style: multi}, {name: groupId, var: group_id, style: multi}, {name: from, var: from, required: true}, {name: to, var: to, required: true}]
    accept: ["application/json", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"]
    ok: [200]
    auth: basic
  } {
    device_id: $device_id, group_id: $group_id, from: $from, to: $to
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Fetch a list of ReportStops within the time period for the Devices or Groups
#
# GET /reports/stops
# Returns: table<address: string, deviceId: int, deviceName: string, duration: int, endTime: string, engineHours: int, lat: float, lon: float, spentFuel: float, startTime: string>
export def "get-reports-stops" [
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
  --device-id: list<int>
  --group-id: list<int>
  --from: string # in IS0 8601 format. eg. `1963-11-22T18:30:00Z` (required, format: date-time)
  --to: string # in IS0 8601 format. eg. `1963-11-22T18:30:00Z` (required, format: date-time)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/reports/stops"
    query: [{name: deviceId, var: device_id, style: multi}, {name: groupId, var: group_id, style: multi}, {name: from, var: from, required: true}, {name: to, var: to, required: true}]
    accept: ["application/json", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"]
    ok: [200]
    auth: basic
  } {
    device_id: $device_id, group_id: $group_id, from: $from, to: $to
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Fetch a list of ReportSummary within the time period for the Devices or Groups
#
# GET /reports/summary
# Returns: table<averageSpeed: float, deviceId: int, deviceName: string, distance: float, engineHours: int, maxSpeed: float, spentFuel: float>
export def "get-reports-summary" [
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
  --device-id: list<int>
  --group-id: list<int>
  --from: string # in IS0 8601 format. eg. `1963-11-22T18:30:00Z` (required, format: date-time)
  --to: string # in IS0 8601 format. eg. `1963-11-22T18:30:00Z` (required, format: date-time)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/reports/summary"
    query: [{name: deviceId, var: device_id, style: multi}, {name: groupId, var: group_id, style: multi}, {name: from, var: from, required: true}, {name: to, var: to, required: true}]
    accept: ["application/json", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"]
    ok: [200]
    auth: basic
  } {
    device_id: $device_id, group_id: $group_id, from: $from, to: $to
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Fetch a list of ReportTrips within the time period for the Devices or Groups
#
# GET /reports/trips
# Returns: table<averageSpeed: float, deviceId: int, deviceName: string, distance: float, driverName: string, driverUniqueId: int, duration: int, endAddress: string, endLat: float, endLon: float, endTime: string, maxSpeed: float, spentFuel: float, startAddress: string, startLat: float, startLon: float, startTime: string>
export def "get-reports-trips" [
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
  --device-id: list<int>
  --group-id: list<int>
  --from: string # in IS0 8601 format. eg. `1963-11-22T18:30:00Z` (required, format: date-time)
  --to: string # in IS0 8601 format. eg. `1963-11-22T18:30:00Z` (required, format: date-time)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/reports/trips"
    query: [{name: deviceId, var: device_id, style: multi}, {name: groupId, var: group_id, style: multi}, {name: from, var: from, required: true}, {name: to, var: to, required: true}]
    accept: ["application/json", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"]
    ok: [200]
    auth: basic
  } {
    device_id: $device_id, group_id: $group_id, from: $from, to: $to
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Fetch Server information
#
# GET /server
# Returns: record<attributes: record, bingKey: string, coordinateFormat: string, deviceReadonly: bool, forceSettings: bool, id: int, latitude: float, limitCommands: bool, longitude: float, map: string, mapUrl: string, poiLayer: string, readonly: bool, registration: bool, twelveHourFormat: bool, version: string, zoom: int>
export def "get-server" [
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
    path: "/server"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Server information
#
# PUT /server
# Returns: record<attributes: record, bingKey: string, coordinateFormat: string, deviceReadonly: bool, forceSettings: bool, id: int, latitude: float, limitCommands: bool, longitude: float, map: string, mapUrl: string, poiLayer: string, readonly: bool, registration: bool, twelveHourFormat: bool, version: string, zoom: int>
export def "put-server" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: record
  --bing-key: string
  --coordinate-format: string
  --device-readonly: oneof<nothing, bool>
  --force-settings: oneof<nothing, bool>
  --id: int
  --latitude: float
  --limit-commands: oneof<nothing, bool>
  --longitude: float
  --map: string
  --map-url: string
  --poi-layer: string
  --readonly: oneof<nothing, bool>
  --registration: oneof<nothing, bool>
  --twelve-hour-format: oneof<nothing, bool>
  --version: string
  --zoom: int
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/server"
    body: {content_type: "application/json", kind: json, fields: [{name: attributes, var: attributes}, {name: bingKey, var: bing_key}, {name: coordinateFormat, var: coordinate_format}, {name: deviceReadonly, var: device_readonly}, {name: forceSettings, var: force_settings}, {name: id, var: id}, {name: latitude, var: latitude}, {name: limitCommands, var: limit_commands}, {name: longitude, var: longitude}, {name: map, var: map}, {name: mapUrl, var: map_url}, {name: poiLayer, var: poi_layer}, {name: readonly, var: readonly}, {name: registration, var: registration}, {name: twelveHourFormat, var: twelve_hour_format}, {name: version, var: version}, {name: zoom, var: zoom}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    attributes: $attributes, bing_key: $bing_key, coordinate_format: $coordinate_format, device_readonly: $device_readonly, force_settings: $force_settings, id: $id, latitude: $latitude, limit_commands: $limit_commands, longitude: $longitude, map: $map, map_url: $map_url, poi_layer: $poi_layer, readonly: $readonly, registration: $registration, twelve_hour_format: $twelve_hour_format, version: $version, zoom: $zoom
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Close the Session
#
# DELETE /session
export def "delete-session" [
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
    path: "/session"
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch Session information
#
# GET /session
# Returns: record<administrator: bool, attributes: record, coordinateFormat: string, deviceLimit: int, deviceReadonly: bool, disabled: bool, email: string, expirationTime: string, id: int, latitude: float, limitCommands: bool, longitude: float, map: string, name: string, password: string, phone: string, poiLayer: string, readonly: bool, twelveHourFormat: bool, userLimit: int, zoom: int>
export def "get-session" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # (spec name: token)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/session"
    query: [{name: token, var: qp_token}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new Session
#
# POST /session
# Returns: record<administrator: bool, attributes: record, coordinateFormat: string, deviceLimit: int, deviceReadonly: bool, disabled: bool, email: string, expirationTime: string, id: int, latitude: float, limitCommands: bool, longitude: float, map: string, name: string, password: string, phone: string, poiLayer: string, readonly: bool, twelveHourFormat: bool, userLimit: int, zoom: int>
export def "post-session" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string
  password: string # format: password
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/session"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: email, var: email}, {name: password, var: password}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    email: $email, password: $password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch server Statistics
#
# GET /statistics
# Returns: table<activeDevices: int, activeUsers: int, captureTime: string, messagesReceived: int, messagesStored: int, requests: int>
export def "get-statistics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --from: string # in IS0 8601 format. eg. `1963-11-22T18:30:00Z` (required, format: date-time)
  --to: string # in IS0 8601 format. eg. `1963-11-22T18:30:00Z` (required, format: date-time)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/statistics"
    query: [{name: from, var: from, required: true}, {name: to, var: to, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    from: $from, to: $to
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a list of Users
#
# GET /users
# Returns: table<administrator: bool, attributes: record, coordinateFormat: string, deviceLimit: int, deviceReadonly: bool, disabled: bool, email: string, expirationTime: string, id: int, latitude: float, limitCommands: bool, longitude: float, map: string, name: string, password: string, phone: string, poiLayer: string, readonly: bool, twelveHourFormat: bool, userLimit: int, zoom: int>
export def "get-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: string # Can only be used by admin or manager users
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users"
    query: [{name: userId, var: user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a User
#
# POST /users
# Returns: record<administrator: bool, attributes: record, coordinateFormat: string, deviceLimit: int, deviceReadonly: bool, disabled: bool, email: string, expirationTime: string, id: int, latitude: float, limitCommands: bool, longitude: float, map: string, name: string, password: string, phone: string, poiLayer: string, readonly: bool, twelveHourFormat: bool, userLimit: int, zoom: int>
export def "post-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --administrator: oneof<nothing, bool>
  --attributes: record
  --coordinate-format: string
  --device-limit: int
  --device-readonly: oneof<nothing, bool>
  --disabled: oneof<nothing, bool>
  --email: string
  --expiration-time: string # in IS0 8601 format. eg. `1963-11-22T18:30:00Z` (format: date-time)
  --id: int
  --latitude: float
  --limit-commands: oneof<nothing, bool>
  --longitude: float
  --map: string
  --name: string
  --password: string
  --phone: string
  --poi-layer: string
  --readonly: oneof<nothing, bool>
  --twelve-hour-format: oneof<nothing, bool>
  --user-limit: int
  --zoom: int
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users"
    body: {content_type: "application/json", kind: json, fields: [{name: administrator, var: administrator}, {name: attributes, var: attributes}, {name: coordinateFormat, var: coordinate_format}, {name: deviceLimit, var: device_limit}, {name: deviceReadonly, var: device_readonly}, {name: disabled, var: disabled}, {name: email, var: email}, {name: expirationTime, var: expiration_time}, {name: id, var: id}, {name: latitude, var: latitude}, {name: limitCommands, var: limit_commands}, {name: longitude, var: longitude}, {name: map, var: map}, {name: name, var: name}, {name: password, var: password}, {name: phone, var: phone}, {name: poiLayer, var: poi_layer}, {name: readonly, var: readonly}, {name: twelveHourFormat, var: twelve_hour_format}, {name: userLimit, var: user_limit}, {name: zoom, var: zoom}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    administrator: $administrator, attributes: $attributes, coordinate_format: $coordinate_format, device_limit: $device_limit, device_readonly: $device_readonly, disabled: $disabled, email: $email, expiration_time: $expiration_time, id: $id, latitude: $latitude, limit_commands: $limit_commands, longitude: $longitude, map: $map, name: $name, password: $password, phone: $phone, poi_layer: $poi_layer, readonly: $readonly, twelve_hour_format: $twelve_hour_format, user_limit: $user_limit, zoom: $zoom
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a User
#
# DELETE /users/{id}
export def "delete-users-id" [
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/users/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a User
#
# PUT /users/{id}
# Returns: record<administrator: bool, attributes: record, coordinateFormat: string, deviceLimit: int, deviceReadonly: bool, disabled: bool, email: string, expirationTime: string, id: int, latitude: float, limitCommands: bool, longitude: float, map: string, name: string, password: string, phone: string, poiLayer: string, readonly: bool, twelveHourFormat: bool, userLimit: int, zoom: int>
export def "put-users-id" [
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
  --administrator: oneof<nothing, bool>
  --attributes: record
  --coordinate-format: string
  --device-limit: int
  --device-readonly: oneof<nothing, bool>
  --disabled: oneof<nothing, bool>
  --email: string
  --expiration-time: string # in IS0 8601 format. eg. `1963-11-22T18:30:00Z` (format: date-time)
  --body-id: int # (spec name: id)
  --latitude: float
  --limit-commands: oneof<nothing, bool>
  --longitude: float
  --map: string
  --name: string
  --password: string
  --phone: string
  --poi-layer: string
  --readonly: oneof<nothing, bool>
  --twelve-hour-format: oneof<nothing, bool>
  --user-limit: int
  --zoom: int
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/users/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: administrator, var: administrator}, {name: attributes, var: attributes}, {name: coordinateFormat, var: coordinate_format}, {name: deviceLimit, var: device_limit}, {name: deviceReadonly, var: device_readonly}, {name: disabled, var: disabled}, {name: email, var: email}, {name: expirationTime, var: expiration_time}, {name: id, var: body_id}, {name: latitude, var: latitude}, {name: limitCommands, var: limit_commands}, {name: longitude, var: longitude}, {name: map, var: map}, {name: name, var: name}, {name: password, var: password}, {name: phone, var: phone}, {name: poiLayer, var: poi_layer}, {name: readonly, var: readonly}, {name: twelveHourFormat, var: twelve_hour_format}, {name: userLimit, var: user_limit}, {name: zoom, var: zoom}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, administrator: $administrator, attributes: $attributes, coordinate_format: $coordinate_format, device_limit: $device_limit, device_readonly: $device_readonly, disabled: $disabled, email: $email, expiration_time: $expiration_time, body_id: $body_id, latitude: $latitude, limit_commands: $limit_commands, longitude: $longitude, map: $map, name: $name, password: $password, phone: $phone, poi_layer: $poi_layer, readonly: $readonly, twelve_hour_format: $twelve_hour_format, user_limit: $user_limit, zoom: $zoom
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
