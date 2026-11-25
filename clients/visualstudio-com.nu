# Auto-generated client for VSOnline v1
# Source: https://api.apis.guru/v2/specs/visualstudio.com/v1/openapi.json
# Auth: --token flag or $env.VSONLINE_TOKEN

const CLIENT = {
  base_url: "https://online.visualstudio.com"
  token_env_var: "VSONLINE_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: bearer, in: header, header_name: Authorization, prefix: Bearer}
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

def base-url-completer [] { ["https://online.visualstudio.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "text/json" "text/plain"] }
def privacy-completer [] { ["0 (Private)" "1 (Public)" "2 (Org)"] }
def tunnel-type-completer [] { ["0 (Basis)" "1 (Liveshare)"] }
def new-value-completer [] { ["0 (None)" "1 (Created)" "10 (Archived)" "11 (Starting)" "12 (ShuttingDown)" "13 (Failed)" "14 (Exporting)" "15 (Updating)" "16 (Rebuilding)" "2 (Queued)" "3 (Provisioning)" "4 (Available)" "5 (Awaiting)" "6 (Unavailable)" "7 (Deleted)" "8 (Moved)" "9 (Shutdown)"] }
def old-value-completer [] { ["0 (None)" "1 (Created)" "10 (Archived)" "11 (Starting)" "12 (ShuttingDown)" "13 (Failed)" "14 (Exporting)" "15 (Updating)" "16 (Rebuilding)" "2 (Queued)" "3 (Provisioning)" "4 (Available)" "5 (Awaiting)" "6 (Unavailable)" "7 (Deleted)" "8 (Moved)" "9 (Shutdown)"] }
def storage-type-completer [] { ["0 (V1)" "1 (V2)"] }
def location-completer [] { ["1001 (SouthAfricaNorth)" "1002 (SouthAfricaWest)" "101 (EastAsia)" "102 (SouthEastAsia)" "1201 (UaeCentral)" "1202 (UaeNorth)" "1401 (UkSouth)" "1402 (UkWest)" "1501 (CentralUs)" "1502 (EastUs)" "1503 (EastUs2)" "1504 (NorthCentralUs)" "1505 (SouthCentralUs)" "1506 (WestCentralUs)" "1507 (WestUs)" "1508 (WestUs2)" "1509 (WestUs3)" "1601 (CentralUsEuap)" "1602 (EastUs2Euap)" "1701 (SwitzerlandNorth)" "1702 (SwitzerlandWest)" "1801 (GermanyNorth)" "1802 (GermanyWestCentral)" "1901 (NorwayWest)" "1902 (NorwayEast)" "201 (AustraliaCentral)" "202 (AustraliaCentral2)" "203 (AustraliaEast)" "205 (AustraliaSouthEast)" "301 (BrazilSouth)" "401 (CanadaCentral)" "402 (CanadaEast)" "501 (NorthEurope)" "502 (WestEurope)" "601 (FranceCentral)" "602 (FranceSouth)" "701 (CentralIndia)" "702 (SouthIndia)" "703 (WestIndia)" "801 (JapanEast)" "802 (JapanWest)" "901 (KoreaCentral)" "902 (KoreaSouth)"] }
def subtype-completer [] { ["0 (Default)" "2 (ShrunkBlob)" "3 (FullBlob)" "4 (UserParametersBlob)" "5 (PrebuildHash)" "6 (VnetInjected)"] }
def type-completer [] { ["1 (ComputeVM)" "10 (VirtualNetwork)" "11 (NetworkSecurityGroup)" "12 (LiveShareWorkspace)" "13 (BasisTunnel)" "14 (StorageBlockBlob)" "15 (DataDisk)" "16 (PortForwardingWorkspace)" "2 (StorageFileShare)" "3 (StorageArchive)" "4 (KeyVault)" "5 (OSDisk)" "6 (NetworkInterface)" "7 (InputQueue)" "8 (Snapshot)" "9 (PoolQueue)"] }
def scope-completer [] { ["1 (Plan)" "2 (User)"] }
def type-completer-1 [] { ["1 (EnvironmentVariable)" "2 (ContainerRegistry)"] }
def region-completer [] { ["1001 (SouthAfricaNorth)" "1002 (SouthAfricaWest)" "101 (EastAsia)" "102 (SouthEastAsia)" "1201 (UaeCentral)" "1202 (UaeNorth)" "1401 (UkSouth)" "1402 (UkWest)" "1501 (CentralUs)" "1502 (EastUs)" "1503 (EastUs2)" "1504 (NorthCentralUs)" "1505 (SouthCentralUs)" "1506 (WestCentralUs)" "1507 (WestUs)" "1508 (WestUs2)" "1509 (WestUs3)" "1601 (CentralUsEuap)" "1602 (EastUs2Euap)" "1701 (SwitzerlandNorth)" "1702 (SwitzerlandWest)" "1801 (GermanyNorth)" "1802 (GermanyWestCentral)" "1901 (NorwayWest)" "1902 (NorwayEast)" "201 (AustraliaCentral)" "202 (AustraliaCentral2)" "203 (AustraliaEast)" "205 (AustraliaSouthEast)" "301 (BrazilSouth)" "401 (CanadaCentral)" "402 (CanadaEast)" "501 (NorthEurope)" "502 (WestEurope)" "601 (FranceCentral)" "602 (FranceSouth)" "701 (CentralIndia)" "702 (SouthIndia)" "703 (WestIndia)" "801 (JapanEast)" "802 (JapanWest)" "901 (KoreaCentral)" "902 (KoreaSouth)"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-api-v1-agents-family: "record<assetUri: string, family: string, name: string>"
    get-api-v1-environments: "table<accessToken: string, active: string, autoShutdownDelayMinutes: int, billableOwnerType: int, clientUsage: record<sessionId: string, usageData: record>, connection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record>, container: record<id: string, schemaVersion: string>, containerImage: string, createFromPrebuild: bool, created: string, displayStorageUtilizationInKb: bool, exportedBlobUrl: string, failoverDetails: record<failoverEnabled: bool, failoverRegion: int>, features: record, friendlyName: string, gitStatus: record<ahead: int, behind: int, branch: string, commit: string, hasUncommittedChanges: bool, hasUnpushedChanges: bool, noGitRepo: bool>, id: string, lastStateUpdateReason: string, lastUsed: string, location: string, organizationId: string, ownerId: string, planId: string, platform: string, portForwardingConnection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record>, prebuildType: string, recentFolders: list<string>, resourceTier: int, runtimeConstraints: record<allowedPortPrivacySettings: list, imageAllowList: list>, seed: record<cloneUrl: string, gitConfig: record, recurseClone: bool, repository: record, seedMoniker: string, seedType: string>, skuDisplayName: string, skuName: string, state: string, storageUtilizationInKb: int, subscriptionData: record<computeQuota: int, computeUsage: int, subscriptionId: string, subscriptionState: string>, templateStatus: string, type: string, updated: string>"
    post-api-v1-environments: "record<accessToken: string, active: string, autoShutdownDelayMinutes: int, billableOwnerType: int, clientUsage: record<sessionId: string, usageData: record>, connection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, container: record<id: string, schemaVersion: string>, containerImage: string, createFromPrebuild: bool, created: string, displayStorageUtilizationInKb: bool, exportedBlobUrl: string, failoverDetails: record<failoverEnabled: bool, failoverRegion: int>, features: record, friendlyName: string, gitStatus: record<ahead: int, behind: int, branch: string, commit: string, hasUncommittedChanges: bool, hasUnpushedChanges: bool, noGitRepo: bool>, id: string, lastStateUpdateReason: string, lastUsed: string, location: string, organizationId: string, ownerId: string, planId: string, platform: string, portForwardingConnection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, prebuildType: string, recentFolders: list<string>, resourceTier: int, runtimeConstraints: record<allowedPortPrivacySettings: list<int>, imageAllowList: list<string>>, seed: record<cloneUrl: string, gitConfig: record<userEmail: string, userName: string>, recurseClone: bool, repository: record<branchName: string, commitId: string, createType: string, diskUsage: string, name: string, owner: string, prebuildHash: string, repoId: int, url: string>, seedMoniker: string, seedType: string>, skuDisplayName: string, skuName: string, state: string, storageUtilizationInKb: int, subscriptionData: record<computeQuota: int, computeUsage: int, subscriptionId: string, subscriptionState: string>, templateStatus: string, type: string, updated: string>"
    get-environment-route: "record<accessToken: string, active: string, autoShutdownDelayMinutes: int, billableOwnerType: int, clientUsage: record<sessionId: string, usageData: record>, connection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, container: record<id: string, schemaVersion: string>, containerImage: string, createFromPrebuild: bool, created: string, displayStorageUtilizationInKb: bool, exportedBlobUrl: string, failoverDetails: record<failoverEnabled: bool, failoverRegion: int>, features: record, friendlyName: string, gitStatus: record<ahead: int, behind: int, branch: string, commit: string, hasUncommittedChanges: bool, hasUnpushedChanges: bool, noGitRepo: bool>, id: string, lastStateUpdateReason: string, lastUsed: string, location: string, organizationId: string, ownerId: string, planId: string, platform: string, portForwardingConnection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, prebuildType: string, recentFolders: list<string>, resourceTier: int, runtimeConstraints: record<allowedPortPrivacySettings: list<int>, imageAllowList: list<string>>, seed: record<cloneUrl: string, gitConfig: record<userEmail: string, userName: string>, recurseClone: bool, repository: record<branchName: string, commitId: string, createType: string, diskUsage: string, name: string, owner: string, prebuildHash: string, repoId: int, url: string>, seedMoniker: string, seedType: string>, skuDisplayName: string, skuName: string, state: string, storageUtilizationInKb: int, subscriptionData: record<computeQuota: int, computeUsage: int, subscriptionId: string, subscriptionState: string>, templateStatus: string, type: string, updated: string>"
    patch-api-v1-environments-environment-id: "record<accessToken: string, active: string, autoShutdownDelayMinutes: int, billableOwnerType: int, clientUsage: record<sessionId: string, usageData: record>, connection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, container: record<id: string, schemaVersion: string>, containerImage: string, createFromPrebuild: bool, created: string, displayStorageUtilizationInKb: bool, exportedBlobUrl: string, failoverDetails: record<failoverEnabled: bool, failoverRegion: int>, features: record, friendlyName: string, gitStatus: record<ahead: int, behind: int, branch: string, commit: string, hasUncommittedChanges: bool, hasUnpushedChanges: bool, noGitRepo: bool>, id: string, lastStateUpdateReason: string, lastUsed: string, location: string, organizationId: string, ownerId: string, planId: string, platform: string, portForwardingConnection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, prebuildType: string, recentFolders: list<string>, resourceTier: int, runtimeConstraints: record<allowedPortPrivacySettings: list<int>, imageAllowList: list<string>>, seed: record<cloneUrl: string, gitConfig: record<userEmail: string, userName: string>, recurseClone: bool, repository: record<branchName: string, commitId: string, createType: string, diskUsage: string, name: string, owner: string, prebuildHash: string, repoId: int, url: string>, seedMoniker: string, seedType: string>, skuDisplayName: string, skuName: string, state: string, storageUtilizationInKb: int, subscriptionData: record<computeQuota: int, computeUsage: int, subscriptionId: string, subscriptionState: string>, templateStatus: string, type: string, updated: string>"
    update-environment-route: "record<accessToken: string, active: string, autoShutdownDelayMinutes: int, billableOwnerType: int, clientUsage: record<sessionId: string, usageData: record>, connection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, container: record<id: string, schemaVersion: string>, containerImage: string, createFromPrebuild: bool, created: string, displayStorageUtilizationInKb: bool, exportedBlobUrl: string, failoverDetails: record<failoverEnabled: bool, failoverRegion: int>, features: record, friendlyName: string, gitStatus: record<ahead: int, behind: int, branch: string, commit: string, hasUncommittedChanges: bool, hasUnpushedChanges: bool, noGitRepo: bool>, id: string, lastStateUpdateReason: string, lastUsed: string, location: string, organizationId: string, ownerId: string, planId: string, platform: string, portForwardingConnection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, prebuildType: string, recentFolders: list<string>, resourceTier: int, runtimeConstraints: record<allowedPortPrivacySettings: list<int>, imageAllowList: list<string>>, seed: record<cloneUrl: string, gitConfig: record<userEmail: string, userName: string>, recurseClone: bool, repository: record<branchName: string, commitId: string, createType: string, diskUsage: string, name: string, owner: string, prebuildHash: string, repoId: int, url: string>, seedMoniker: string, seedType: string>, skuDisplayName: string, skuName: string, state: string, storageUtilizationInKb: int, subscriptionData: record<computeQuota: int, computeUsage: int, subscriptionId: string, subscriptionState: string>, templateStatus: string, type: string, updated: string>"
    get-api-v1-environments-environment-id-archive: "record<accessToken: string, active: string, autoShutdownDelayMinutes: int, billableOwnerType: int, clientUsage: record<sessionId: string, usageData: record>, connection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, container: record<id: string, schemaVersion: string>, containerImage: string, createFromPrebuild: bool, created: string, displayStorageUtilizationInKb: bool, exportedBlobUrl: string, failoverDetails: record<failoverEnabled: bool, failoverRegion: int>, features: record, friendlyName: string, gitStatus: record<ahead: int, behind: int, branch: string, commit: string, hasUncommittedChanges: bool, hasUnpushedChanges: bool, noGitRepo: bool>, id: string, lastStateUpdateReason: string, lastUsed: string, location: string, organizationId: string, ownerId: string, planId: string, platform: string, portForwardingConnection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, prebuildType: string, recentFolders: list<string>, resourceTier: int, runtimeConstraints: record<allowedPortPrivacySettings: list<int>, imageAllowList: list<string>>, seed: record<cloneUrl: string, gitConfig: record<userEmail: string, userName: string>, recurseClone: bool, repository: record<branchName: string, commitId: string, createType: string, diskUsage: string, name: string, owner: string, prebuildHash: string, repoId: int, url: string>, seedMoniker: string, seedType: string>, skuDisplayName: string, skuName: string, state: string, storageUtilizationInKb: int, subscriptionData: record<computeQuota: int, computeUsage: int, subscriptionId: string, subscriptionState: string>, templateStatus: string, type: string, updated: string>"
    post-api-v1-environments-environment-id-archive: "record<accessToken: string, active: string, autoShutdownDelayMinutes: int, billableOwnerType: int, clientUsage: record<sessionId: string, usageData: record>, connection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, container: record<id: string, schemaVersion: string>, containerImage: string, createFromPrebuild: bool, created: string, displayStorageUtilizationInKb: bool, exportedBlobUrl: string, failoverDetails: record<failoverEnabled: bool, failoverRegion: int>, features: record, friendlyName: string, gitStatus: record<ahead: int, behind: int, branch: string, commit: string, hasUncommittedChanges: bool, hasUnpushedChanges: bool, noGitRepo: bool>, id: string, lastStateUpdateReason: string, lastUsed: string, location: string, organizationId: string, ownerId: string, planId: string, platform: string, portForwardingConnection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, prebuildType: string, recentFolders: list<string>, resourceTier: int, runtimeConstraints: record<allowedPortPrivacySettings: list<int>, imageAllowList: list<string>>, seed: record<cloneUrl: string, gitConfig: record<userEmail: string, userName: string>, recurseClone: bool, repository: record<branchName: string, commitId: string, createType: string, diskUsage: string, name: string, owner: string, prebuildHash: string, repoId: int, url: string>, seedMoniker: string, seedType: string>, skuDisplayName: string, skuName: string, state: string, storageUtilizationInKb: int, subscriptionData: record<computeQuota: int, computeUsage: int, subscriptionId: string, subscriptionState: string>, templateStatus: string, type: string, updated: string>"
    post-api-v1-environments-environment-id-export: "record<accessToken: string, active: string, autoShutdownDelayMinutes: int, billableOwnerType: int, clientUsage: record<sessionId: string, usageData: record>, connection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, container: record<id: string, schemaVersion: string>, containerImage: string, createFromPrebuild: bool, created: string, displayStorageUtilizationInKb: bool, exportedBlobUrl: string, failoverDetails: record<failoverEnabled: bool, failoverRegion: int>, features: record, friendlyName: string, gitStatus: record<ahead: int, behind: int, branch: string, commit: string, hasUncommittedChanges: bool, hasUnpushedChanges: bool, noGitRepo: bool>, id: string, lastStateUpdateReason: string, lastUsed: string, location: string, organizationId: string, ownerId: string, planId: string, platform: string, portForwardingConnection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, prebuildType: string, recentFolders: list<string>, resourceTier: int, runtimeConstraints: record<allowedPortPrivacySettings: list<int>, imageAllowList: list<string>>, seed: record<cloneUrl: string, gitConfig: record<userEmail: string, userName: string>, recurseClone: bool, repository: record<branchName: string, commitId: string, createType: string, diskUsage: string, name: string, owner: string, prebuildHash: string, repoId: int, url: string>, seedMoniker: string, seedType: string>, skuDisplayName: string, skuName: string, state: string, storageUtilizationInKb: int, subscriptionData: record<computeQuota: int, computeUsage: int, subscriptionId: string, subscriptionState: string>, templateStatus: string, type: string, updated: string>"
    patch-api-v1-environments-environment-id-folder: "record<accessToken: string, active: string, autoShutdownDelayMinutes: int, billableOwnerType: int, clientUsage: record<sessionId: string, usageData: record>, connection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, container: record<id: string, schemaVersion: string>, containerImage: string, createFromPrebuild: bool, created: string, displayStorageUtilizationInKb: bool, exportedBlobUrl: string, failoverDetails: record<failoverEnabled: bool, failoverRegion: int>, features: record, friendlyName: string, gitStatus: record<ahead: int, behind: int, branch: string, commit: string, hasUncommittedChanges: bool, hasUnpushedChanges: bool, noGitRepo: bool>, id: string, lastStateUpdateReason: string, lastUsed: string, location: string, organizationId: string, ownerId: string, planId: string, platform: string, portForwardingConnection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, prebuildType: string, recentFolders: list<string>, resourceTier: int, runtimeConstraints: record<allowedPortPrivacySettings: list<int>, imageAllowList: list<string>>, seed: record<cloneUrl: string, gitConfig: record<userEmail: string, userName: string>, recurseClone: bool, repository: record<branchName: string, commitId: string, createType: string, diskUsage: string, name: string, owner: string, prebuildHash: string, repoId: int, url: string>, seedMoniker: string, seedType: string>, skuDisplayName: string, skuName: string, state: string, storageUtilizationInKb: int, subscriptionData: record<computeQuota: int, computeUsage: int, subscriptionId: string, subscriptionState: string>, templateStatus: string, type: string, updated: string>"
    get-api-v1-environments-environment-id-heartbeattoken: "record<accessToken: string, active: string, autoShutdownDelayMinutes: int, billableOwnerType: int, clientUsage: record<sessionId: string, usageData: record>, connection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, container: record<id: string, schemaVersion: string>, containerImage: string, createFromPrebuild: bool, created: string, displayStorageUtilizationInKb: bool, exportedBlobUrl: string, failoverDetails: record<failoverEnabled: bool, failoverRegion: int>, features: record, friendlyName: string, gitStatus: record<ahead: int, behind: int, branch: string, commit: string, hasUncommittedChanges: bool, hasUnpushedChanges: bool, noGitRepo: bool>, id: string, lastStateUpdateReason: string, lastUsed: string, location: string, organizationId: string, ownerId: string, planId: string, platform: string, portForwardingConnection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, prebuildType: string, recentFolders: list<string>, resourceTier: int, runtimeConstraints: record<allowedPortPrivacySettings: list<int>, imageAllowList: list<string>>, seed: record<cloneUrl: string, gitConfig: record<userEmail: string, userName: string>, recurseClone: bool, repository: record<branchName: string, commitId: string, createType: string, diskUsage: string, name: string, owner: string, prebuildHash: string, repoId: int, url: string>, seedMoniker: string, seedType: string>, skuDisplayName: string, skuName: string, state: string, storageUtilizationInKb: int, subscriptionData: record<computeQuota: int, computeUsage: int, subscriptionId: string, subscriptionState: string>, templateStatus: string, type: string, updated: string>"
    post-api-v1-environments-environment-id-notify: "string"
    put-api-v1-environments-environment-id-secrets: "record<accessToken: string, active: string, autoShutdownDelayMinutes: int, billableOwnerType: int, clientUsage: record<sessionId: string, usageData: record>, connection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, container: record<id: string, schemaVersion: string>, containerImage: string, createFromPrebuild: bool, created: string, displayStorageUtilizationInKb: bool, exportedBlobUrl: string, failoverDetails: record<failoverEnabled: bool, failoverRegion: int>, features: record, friendlyName: string, gitStatus: record<ahead: int, behind: int, branch: string, commit: string, hasUncommittedChanges: bool, hasUnpushedChanges: bool, noGitRepo: bool>, id: string, lastStateUpdateReason: string, lastUsed: string, location: string, organizationId: string, ownerId: string, planId: string, platform: string, portForwardingConnection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, prebuildType: string, recentFolders: list<string>, resourceTier: int, runtimeConstraints: record<allowedPortPrivacySettings: list<int>, imageAllowList: list<string>>, seed: record<cloneUrl: string, gitConfig: record<userEmail: string, userName: string>, recurseClone: bool, repository: record<branchName: string, commitId: string, createType: string, diskUsage: string, name: string, owner: string, prebuildHash: string, repoId: int, url: string>, seedMoniker: string, seedType: string>, skuDisplayName: string, skuName: string, state: string, storageUtilizationInKb: int, subscriptionData: record<computeQuota: int, computeUsage: int, subscriptionId: string, subscriptionState: string>, templateStatus: string, type: string, updated: string>"
    post-api-v1-environments-environment-id-shutdown: "record<accessToken: string, active: string, autoShutdownDelayMinutes: int, billableOwnerType: int, clientUsage: record<sessionId: string, usageData: record>, connection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, container: record<id: string, schemaVersion: string>, containerImage: string, createFromPrebuild: bool, created: string, displayStorageUtilizationInKb: bool, exportedBlobUrl: string, failoverDetails: record<failoverEnabled: bool, failoverRegion: int>, features: record, friendlyName: string, gitStatus: record<ahead: int, behind: int, branch: string, commit: string, hasUncommittedChanges: bool, hasUnpushedChanges: bool, noGitRepo: bool>, id: string, lastStateUpdateReason: string, lastUsed: string, location: string, organizationId: string, ownerId: string, planId: string, platform: string, portForwardingConnection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, prebuildType: string, recentFolders: list<string>, resourceTier: int, runtimeConstraints: record<allowedPortPrivacySettings: list<int>, imageAllowList: list<string>>, seed: record<cloneUrl: string, gitConfig: record<userEmail: string, userName: string>, recurseClone: bool, repository: record<branchName: string, commitId: string, createType: string, diskUsage: string, name: string, owner: string, prebuildHash: string, repoId: int, url: string>, seedMoniker: string, seedType: string>, skuDisplayName: string, skuName: string, state: string, storageUtilizationInKb: int, subscriptionData: record<computeQuota: int, computeUsage: int, subscriptionId: string, subscriptionState: string>, templateStatus: string, type: string, updated: string>"
    post-api-v1-environments-environment-id-start: "record<accessToken: string, active: string, autoShutdownDelayMinutes: int, billableOwnerType: int, clientUsage: record<sessionId: string, usageData: record>, connection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, container: record<id: string, schemaVersion: string>, containerImage: string, createFromPrebuild: bool, created: string, displayStorageUtilizationInKb: bool, exportedBlobUrl: string, failoverDetails: record<failoverEnabled: bool, failoverRegion: int>, features: record, friendlyName: string, gitStatus: record<ahead: int, behind: int, branch: string, commit: string, hasUncommittedChanges: bool, hasUnpushedChanges: bool, noGitRepo: bool>, id: string, lastStateUpdateReason: string, lastUsed: string, location: string, organizationId: string, ownerId: string, planId: string, platform: string, portForwardingConnection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, prebuildType: string, recentFolders: list<string>, resourceTier: int, runtimeConstraints: record<allowedPortPrivacySettings: list<int>, imageAllowList: list<string>>, seed: record<cloneUrl: string, gitConfig: record<userEmail: string, userName: string>, recurseClone: bool, repository: record<branchName: string, commitId: string, createType: string, diskUsage: string, name: string, owner: string, prebuildHash: string, repoId: int, url: string>, seedMoniker: string, seedType: string>, skuDisplayName: string, skuName: string, state: string, storageUtilizationInKb: int, subscriptionData: record<computeQuota: int, computeUsage: int, subscriptionId: string, subscriptionState: string>, templateStatus: string, type: string, updated: string>"
    get-api-v1-environments-environment-id-updates: "record<accessToken: string, active: string, autoShutdownDelayMinutes: int, billableOwnerType: int, clientUsage: record<sessionId: string, usageData: record>, connection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, container: record<id: string, schemaVersion: string>, containerImage: string, createFromPrebuild: bool, created: string, displayStorageUtilizationInKb: bool, exportedBlobUrl: string, failoverDetails: record<failoverEnabled: bool, failoverRegion: int>, features: record, friendlyName: string, gitStatus: record<ahead: int, behind: int, branch: string, commit: string, hasUncommittedChanges: bool, hasUnpushedChanges: bool, noGitRepo: bool>, id: string, lastStateUpdateReason: string, lastUsed: string, location: string, organizationId: string, ownerId: string, planId: string, platform: string, portForwardingConnection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, prebuildType: string, recentFolders: list<string>, resourceTier: int, runtimeConstraints: record<allowedPortPrivacySettings: list<int>, imageAllowList: list<string>>, seed: record<cloneUrl: string, gitConfig: record<userEmail: string, userName: string>, recurseClone: bool, repository: record<branchName: string, commitId: string, createType: string, diskUsage: string, name: string, owner: string, prebuildHash: string, repoId: int, url: string>, seedMoniker: string, seedType: string>, skuDisplayName: string, skuName: string, state: string, storageUtilizationInKb: int, subscriptionData: record<computeQuota: int, computeUsage: int, subscriptionId: string, subscriptionState: string>, templateStatus: string, type: string, updated: string>"
    post-api-v1-geneva-actions-billing-resend: "record<billGenerationTime: string, environmentId: string, id: string, location: int, partitionKey: string, periodEnd: string, periodStart: string, plan: record<location: int, name: string, providerNamespace: string, resourceGroup: string, resourceId: string, subscription: string>, usage: record, usageDetail: table<endState: int, id: string, resourceUsage: record, sku: record>>"
    get-api-v1-geneva-actions-billing-environment-id: "record<billGenerationTime: string, environmentId: string, id: string, location: int, partitionKey: string, periodEnd: string, periodStart: string, plan: record<location: int, name: string, providerNamespace: string, resourceGroup: string, resourceId: string, subscription: string>, usage: record, usageDetail: table<endState: int, id: string, resourceUsage: record, sku: record>>"
    get-api-v1-geneva-actions-billing-environment-id-state-changes: "record<environment: record<id: string, name: string, sku: record<name: string, tier: string>, userId: string>, id: string, newValue: int, oldValue: int, partitionKey: string, time: string>"
    post-api-v1-geneva-actions-billing-environment-id-state-changes: "record<environment: record<id: string, name: string, sku: record<name: string, tier: string>, userId: string>, id: string, newValue: int, oldValue: int, partitionKey: string, time: string>"
    post-api-v1-geneva-actions-configuration-target: "record<comment: string, key: string, value: string>"
    get-api-v1-geneva-actions-configuration-target-key: "record<comment: string, key: string, value: string>"
    get-api-v1-geneva-actions-environments-environment-id: "record<accessToken: string, active: string, autoShutdownDelayMinutes: int, billableOwnerType: int, clientUsage: record<sessionId: string, usageData: record>, connection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, container: record<id: string, schemaVersion: string>, containerImage: string, createFromPrebuild: bool, created: string, displayStorageUtilizationInKb: bool, exportedBlobUrl: string, failoverDetails: record<failoverEnabled: bool, failoverRegion: int>, features: record, friendlyName: string, gitStatus: record<ahead: int, behind: int, branch: string, commit: string, hasUncommittedChanges: bool, hasUnpushedChanges: bool, noGitRepo: bool>, id: string, lastStateUpdateReason: string, lastUsed: string, location: string, organizationId: string, ownerId: string, planId: string, platform: string, portForwardingConnection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, prebuildType: string, recentFolders: list<string>, resourceTier: int, runtimeConstraints: record<allowedPortPrivacySettings: list<int>, imageAllowList: list<string>>, seed: record<cloneUrl: string, gitConfig: record<userEmail: string, userName: string>, recurseClone: bool, repository: record<branchName: string, commitId: string, createType: string, diskUsage: string, name: string, owner: string, prebuildHash: string, repoId: int, url: string>, seedMoniker: string, seedType: string>, skuDisplayName: string, skuName: string, state: string, storageUtilizationInKb: int, subscriptionData: record<computeQuota: int, computeUsage: int, subscriptionId: string, subscriptionState: string>, templateStatus: string, type: string, updated: string>"
    put-api-v1-geneva-actions-environments-environment-id-archive: "record<accessToken: string, active: string, autoShutdownDelayMinutes: int, billableOwnerType: int, clientUsage: record<sessionId: string, usageData: record>, connection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, container: record<id: string, schemaVersion: string>, containerImage: string, createFromPrebuild: bool, created: string, displayStorageUtilizationInKb: bool, exportedBlobUrl: string, failoverDetails: record<failoverEnabled: bool, failoverRegion: int>, features: record, friendlyName: string, gitStatus: record<ahead: int, behind: int, branch: string, commit: string, hasUncommittedChanges: bool, hasUnpushedChanges: bool, noGitRepo: bool>, id: string, lastStateUpdateReason: string, lastUsed: string, location: string, organizationId: string, ownerId: string, planId: string, platform: string, portForwardingConnection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, prebuildType: string, recentFolders: list<string>, resourceTier: int, runtimeConstraints: record<allowedPortPrivacySettings: list<int>, imageAllowList: list<string>>, seed: record<cloneUrl: string, gitConfig: record<userEmail: string, userName: string>, recurseClone: bool, repository: record<branchName: string, commitId: string, createType: string, diskUsage: string, name: string, owner: string, prebuildHash: string, repoId: int, url: string>, seedMoniker: string, seedType: string>, skuDisplayName: string, skuName: string, state: string, storageUtilizationInKb: int, subscriptionData: record<computeQuota: int, computeUsage: int, subscriptionId: string, subscriptionState: string>, templateStatus: string, type: string, updated: string>"
    get-api-v1-geneva-actions-environments-environment-id-archived-storage-sas-target-blob: "string"
    put-api-v1-geneva-actions-environments-environment-id-shutdown: "record<accessToken: string, active: string, autoShutdownDelayMinutes: int, billableOwnerType: int, clientUsage: record<sessionId: string, usageData: record>, connection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, container: record<id: string, schemaVersion: string>, containerImage: string, createFromPrebuild: bool, created: string, displayStorageUtilizationInKb: bool, exportedBlobUrl: string, failoverDetails: record<failoverEnabled: bool, failoverRegion: int>, features: record, friendlyName: string, gitStatus: record<ahead: int, behind: int, branch: string, commit: string, hasUncommittedChanges: bool, hasUnpushedChanges: bool, noGitRepo: bool>, id: string, lastStateUpdateReason: string, lastUsed: string, location: string, organizationId: string, ownerId: string, planId: string, platform: string, portForwardingConnection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, prebuildType: string, recentFolders: list<string>, resourceTier: int, runtimeConstraints: record<allowedPortPrivacySettings: list<int>, imageAllowList: list<string>>, seed: record<cloneUrl: string, gitConfig: record<userEmail: string, userName: string>, recurseClone: bool, repository: record<branchName: string, commitId: string, createType: string, diskUsage: string, name: string, owner: string, prebuildHash: string, repoId: int, url: string>, seedMoniker: string, seedType: string>, skuDisplayName: string, skuName: string, state: string, storageUtilizationInKb: int, subscriptionData: record<computeQuota: int, computeUsage: int, subscriptionId: string, subscriptionState: string>, templateStatus: string, type: string, updated: string>"
    post-api-v1-geneva-actions-environments-environment-id-upload-running-vm-logs: "record<containerName: string, message: string, pathInContainer: string, storageUri: string, vmResourceId: string>"
    post-api-v1-geneva-actions-pools-change-resource-deletion-setting: "record<comment: string, key: string, value: string>"
    post-api-v1-geneva-actions-pools-target: "record<comment: string, key: string, value: string>"
    post-api-v1-geneva-actions-privacy-refresh-profile-telemetry-properties: "record<failed: table<oid: string, provider: string, tid: string>, succeeded: table<oid: string, provider: string, tid: string>>"
    post-api-v1-geneva-actions-resources-resource-id-under-investigation: "record<investigationStarted: string, resourceId: string, underInvestigation: bool, updated: bool>"
    get-api-v1-locations: "record<available: list<int>, current: int, hostnames: record>"
    get-api-v1-locations-location: "record<skus: table<availableSettings: record, displayName: string, name: string, os: string>>"
    get-template-info-route: "record<branchName: string, commitId: string, id: string, isPrebuild: bool, lastUsedTime: string, logicalSkus: list<string>, prebuildHash: string, repoId: int, templateStatus: string>"
    get-prebuild-readiness-route: "record<branchName: string, devContainerPath: string, location: int, poolSkus: list<string>, prebuildHash: string, repoId: string, supportedSkus: list<string>, templateSkus: list<string>>"
    get-api-v1-sas: "table<filters: list<record>, id: string, lastModified: string, notes: string, scope: int, secretName: string, type: int>"
    get-api-v1-secrets: "table<filters: list<record>, id: string, lastModified: string, notes: string, scope: int, secretName: string, type: int>"
    post-api-v1-secrets: "record<filters: table<type: int, value: string>, id: string, lastModified: string, notes: string, scope: int, secretName: string, type: int>"
    put-api-v1-secrets-secret-id: "record<filters: table<type: int, value: string>, id: string, lastModified: string, notes: string, scope: int, secretName: string, type: int>"
    get-api-v1-tenant-tenant-id: "record<id: string>"
    get-api-v1-tunnel-environment-id-port-info: "record<portVisibility: string, tunnelToken: string>"
    get-api-v1-pools-default: "table<allWithLatestVersion: bool, isEnvironmentPool: bool, location: string, poolCode: string, readyUnassignedCount: int, readyUnassignedLatestVersionCount: int, readyUnassignedNotLatestVersionAndIdleCount: int, readyUnassignedNotLatestVersionCount: int, resourceType: string, sku: string>"
    get-api-v1-tenant-tenant-id-pool-pool-name: "record<domainUserCredentials: record<domain: string, organizationalUnit: string, passwordSecretIdentifier: string, userName: string>, hotPoolSettings: record<size: int>, poolGroupName: string, provisioningStatus: record<completedSteps: int, currentStepDescription: string, isReady: bool, operationStartedTimeUtc: string, totalSteps: int>, tags: record, userGroupName: string, vmSpecs: record<diskType: int, imageResourceId: string, size: string, subnetResourceId: string>>"
    patch-api-v1-tenant-tenant-id-pool-pool-name: "record<domainUserCredentials: record<domain: string, organizationalUnit: string, passwordSecretIdentifier: string, userName: string>, hotPoolSettings: record<size: int>, poolGroupName: string, provisioningStatus: record<completedSteps: int, currentStepDescription: string, isReady: bool, operationStartedTimeUtc: string, totalSteps: int>, tags: record, userGroupName: string, vmSpecs: record<diskType: int, imageResourceId: string, size: string, subnetResourceId: string>>"
    put-api-v1-tenant-tenant-id-pool-pool-name: "record<domainUserCredentials: record<domain: string, organizationalUnit: string, passwordSecretIdentifier: string, userName: string>, hotPoolSettings: record<size: int>, poolGroupName: string, provisioningStatus: record<completedSteps: int, currentStepDescription: string, isReady: bool, operationStartedTimeUtc: string, totalSteps: int>, tags: record, userGroupName: string, vmSpecs: record<diskType: int, imageResourceId: string, size: string, subnetResourceId: string>>"
    get-api-v1-tenant-tenant-id-pool-group-pool-group-name: "record<displayName: string, region: int, tags: record>"
    get-api-v1-tenant-tenant-id-pool-pool-name-vm: "table<connection: record<connectionType: int, liveShareWorkspaceId: string>, provisioningStatus: record<completedSteps: int, currentStepDescription: string, isReady: bool, operationStartedTimeUtc: string, totalSteps: int>, status: int>"
    get-api-v1-tenant-tenant-id-pool-pool-name-vm-vm-name: "record<connection: record<connectionType: int, liveShareWorkspaceId: string>, provisioningStatus: record<completedSteps: int, currentStepDescription: string, isReady: bool, operationStartedTimeUtc: string, totalSteps: int>, status: int>"
    put-api-v1-tenant-tenant-id-pool-pool-name-vm-vm-name: "record<connection: record<connectionType: int, liveShareWorkspaceId: string>, provisioningStatus: record<completedSteps: int, currentStepDescription: string, isReady: bool, operationStartedTimeUtc: string, totalSteps: int>, status: int>"
    post-api-v2-prebuilds-templates: "record<properties: record, sasUrl: string, templateId: string>"
    get-prebuild-readiness-skus-route: "record<branchName: string, devContainerPath: string, location: int, poolSkus: list<string>, prebuildHash: string, repoId: string, supportedSkus: list<string>, templateSkus: list<string>>"
    get-internal-netmon-correlation: "string"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["post-api-v1-agent-telemetry" "post-api-v1-agent-telemetry-standalone" "get-api-v1-agents-family" "get-api-v1-environments" "post-api-v1-environments" "delete-api-v1-environments-environment-id" "get-environment-route" "patch-api-v1-environments-environment-id" "update-environment-route" "get-api-v1-environments-environment-id-archive" "post-api-v1-environments-environment-id-archive" "post-api-v1-environments-environment-id-export" "patch-api-v1-environments-environment-id-folder" "get-api-v1-environments-environment-id-heartbeattoken" "post-api-v1-environments-environment-id-notify" "delete-api-v1-environments-environment-id-ports-port" "put-api-v1-environments-environment-id-ports-port" "patch-api-v1-environments-environment-id-restore" "put-api-v1-environments-environment-id-secrets" "post-api-v1-environments-environment-id-shutdown" "post-api-v1-environments-environment-id-start" "get-api-v1-environments-environment-id-state" "get-api-v1-environments-environment-id-updates" "post-api-v1-geneva-actions-billing-resend" "get-api-v1-geneva-actions-billing-environment-id" "get-api-v1-geneva-actions-billing-environment-id-state-changes" "post-api-v1-geneva-actions-billing-environment-id-state-changes" "post-api-v1-geneva-actions-configuration-target" "delete-api-v1-geneva-actions-configuration-target-key" "get-api-v1-geneva-actions-configuration-target-key" "delete-api-v1-geneva-actions-environments-environment-id" "get-api-v1-geneva-actions-environments-environment-id" "put-api-v1-geneva-actions-environments-environment-id-archive" "get-api-v1-geneva-actions-environments-environment-id-archived-storage-sas-target-blob" "put-api-v1-geneva-actions-environments-environment-id-shutdown" "post-api-v1-geneva-actions-environments-environment-id-upload-running-vm-logs" "post-api-v1-geneva-actions-pools-change-resource-deletion-setting" "post-api-v1-geneva-actions-pools-pool-code-rotate-pool" "post-api-v1-geneva-actions-pools-target" "post-api-v1-geneva-actions-prebuilds-pools-createorupdatesettings" "post-api-v1-geneva-actions-prebuilds-pools-delete" "post-api-v1-geneva-actions-privacy-refresh-profile-telemetry-properties" "post-api-v1-geneva-actions-resources-resource-id-under-investigation" "delete-api-v1-geneva-actions-vnet-pool-definitions" "post-api-v1-geneva-actions-vnet-pool-definitions" "post-api-v1-heart-beat" "get-api-v1-locations" "get-api-v1-locations-location" "post-api-v1-prebuilds-pools-pool-id-instances" "put-api-v1-prebuilds-pools-pool-id-instances" "get-template-info-route" "get-prebuild-readiness-route" "get-api-v1-sas" "get-api-v1-secrets" "post-api-v1-secrets" "delete-api-v1-secrets-secret-id" "put-api-v1-secrets-secret-id" "delete-api-v1-tenant-tenant-id" "get-api-v1-tenant-tenant-id" "put-api-v1-tenant-tenant-id" "post-api-v1-tokens-plans-plan-name-delete-all-codespaces" "post-api-v1-tokens-plans-plan-name-read-all-codespaces" "post-api-v1-tokens-plans-plan-name-write-codespaces" "post-api-v1-tokens-plans-plan-name-write-delegates" "put-api-v1-tokens-subscriptions-subscription-id-resource-groups-resource-group-providers-provider-namespace-plans-resource-name" "post-api-v1-tokens-subscriptions-subscription-id-resource-groups-resource-group-providers-provider-namespace-plans-resource-name-delete-all-codespaces" "post-api-v1-tokens-subscriptions-subscription-id-resource-groups-resource-group-providers-provider-namespace-plans-resource-name-delete-all-environments" "post-api-v1-tokens-subscriptions-subscription-id-resource-groups-resource-group-providers-provider-namespace-plans-resource-name-read-all-codespaces" "post-api-v1-tokens-subscriptions-subscription-id-resource-groups-resource-group-providers-provider-namespace-plans-resource-name-read-all-environments" "post-api-v1-tokens-subscriptions-subscription-id-resource-groups-resource-group-providers-provider-namespace-plans-resource-name-write-codespaces" "post-api-v1-tokens-subscriptions-subscription-id-resource-groups-resource-group-providers-provider-namespace-plans-resource-name-write-delegates" "post-api-v1-tokens-subscriptions-subscription-id-resource-groups-resource-group-providers-provider-namespace-plans-resource-name-write-environments" "get-api-v1-tunnel-environment-id-port-info" "delete-api-v1-user-subscriptions" "post-api-v1-user-subscriptions" "get-api-v1-pools-default" "put-api-v1-subscriptions-subscription-id-providers-git-hub-network-resource-type-subscription-life-cycle-notification" "post-api-v1-subscriptions-subscription-id-providers-git-hub-network-resource-type-resource-read-begin" "put-api-v1-subscriptions-subscription-id-providers-microsoft-codespaces-plans-subscription-life-cycle-notification" "post-api-v1-subscriptions-subscription-id-providers-microsoft-codespaces-plans-resource-read-begin" "put-api-v1-subscriptions-subscription-id-providers-microsoft-vs-online-plans-subscription-life-cycle-notification" "post-api-v1-subscriptions-subscription-id-providers-microsoft-vs-online-plans-resource-read-begin" "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-git-hub-network-resource-type-resource-read-begin" "delete-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-git-hub-network-resource-type-resource-name" "patch-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-git-hub-network-resource-type-resource-name" "put-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-git-hub-network-resource-type-resource-name" "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-git-hub-network-resource-type-resource-name-resource-creation-completed" "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-git-hub-network-resource-type-resource-name-resource-creation-validate" "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-git-hub-network-resource-type-resource-name-resource-deletion-completed" "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-git-hub-network-resource-type-resource-name-resource-deletion-validate" "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-git-hub-network-resource-type-resource-name-resource-patch-completed" "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-git-hub-network-resource-type-resource-name-resource-patch-validate" "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-git-hub-network-resource-type-resource-name-resource-read-begin" "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-microsoft-codespaces-plans-resource-read-begin" "put-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-microsoft-codespaces-plans-resource-name" "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-microsoft-codespaces-plans-resource-name-delete-all-codespaces" "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-microsoft-codespaces-plans-resource-name-delete-all-environments" "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-microsoft-codespaces-plans-resource-name-read-all-codespaces" "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-microsoft-codespaces-plans-resource-name-read-all-environments" "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-microsoft-codespaces-plans-resource-name-read-delegates" "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-microsoft-codespaces-plans-resource-name-resource-creation-completed" "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-microsoft-codespaces-plans-resource-name-resource-creation-validate" "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-microsoft-codespaces-plans-resource-name-resource-deletion-validate" "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-microsoft-codespaces-plans-resource-name-resource-patch-completed" "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-microsoft-codespaces-plans-resource-name-resource-patch-validate" "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-microsoft-codespaces-plans-resource-name-resource-read-begin" "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-microsoft-codespaces-plans-resource-name-write-codespaces" "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-microsoft-codespaces-plans-resource-name-write-delegates" "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-microsoft-codespaces-plans-resource-name-write-environments" "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-microsoft-vs-online-plans-resource-read-begin" "put-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-microsoft-vs-online-plans-resource-name" "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-microsoft-vs-online-plans-resource-name-delete-all-codespaces" "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-microsoft-vs-online-plans-resource-name-delete-all-environments" "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-microsoft-vs-online-plans-resource-name-read-all-codespaces" "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-microsoft-vs-online-plans-resource-name-read-all-environments" "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-microsoft-vs-online-plans-resource-name-read-delegates" "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-microsoft-vs-online-plans-resource-name-resource-creation-completed" "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-microsoft-vs-online-plans-resource-name-resource-creation-validate" "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-microsoft-vs-online-plans-resource-name-resource-deletion-validate" "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-microsoft-vs-online-plans-resource-name-resource-patch-completed" "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-microsoft-vs-online-plans-resource-name-resource-patch-validate" "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-microsoft-vs-online-plans-resource-name-resource-read-begin" "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-microsoft-vs-online-plans-resource-name-write-codespaces" "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-microsoft-vs-online-plans-resource-name-write-delegates" "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-microsoft-vs-online-plans-resource-name-write-environments" "post-api-v1-subscriptions-subscription-id-resource-group-providers-microsoft-codespaces-plans-resource-name-delete-delegates" "post-api-v1-subscriptions-subscription-id-resource-group-providers-microsoft-vs-online-plans-resource-name-delete-delegates" "delete-api-v1-tenant-tenant-id-pool-pool-name" "get-api-v1-tenant-tenant-id-pool-pool-name" "patch-api-v1-tenant-tenant-id-pool-pool-name" "put-api-v1-tenant-tenant-id-pool-pool-name" "delete-api-v1-tenant-tenant-id-pool-group-pool-group-name" "get-api-v1-tenant-tenant-id-pool-group-pool-group-name" "patch-api-v1-tenant-tenant-id-pool-group-pool-group-name" "put-api-v1-tenant-tenant-id-pool-group-pool-group-name" "get-api-v1-tenant-tenant-id-pool-pool-name-vm" "delete-api-v1-tenant-tenant-id-pool-pool-name-vm-vm-name" "get-api-v1-tenant-tenant-id-pool-pool-name-vm-vm-name" "put-api-v1-tenant-tenant-id-pool-pool-name-vm-vm-name" "post-api-v1-tenant-tenant-id-pool-pool-name-vm-vm-name-start" "post-api-v1-tenant-tenant-id-pool-pool-name-vm-vm-name-stop" "post-api-v2-prebuilds-delete" "delete-api-v2-prebuilds-repository-repo-id-branch-branch-name" "post-api-v2-prebuilds-templates" "get-prebuild-readiness-skus-route" "post-api-v2-prebuilds-templates-updatemaxversions" "post-api-v2-prebuilds-templates-template-id-updatestatus" "get-health" "get-internal-netmon-correlation" "get-tunnelauth" "post-tunnelauth" "get-warmup" "commands"] | sort) } | get name | first)
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

# POST /api/v1/AgentTelemetry
export def "post-api-v1-agent-telemetry" [
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
    path: "/api/v1/AgentTelemetry"
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/v1/AgentTelemetry/standalone
export def "post-api-v1-agent-telemetry-standalone" [
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
    path: "/api/v1/AgentTelemetry/standalone"
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /api/v1/Agents/{family}
#
# Returns: record<assetUri: string, family: string, name: string>
export def "get-api-v1-agents-family" [
  family: string
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
    path: "/api/v1/Agents/{family}"
    path_params: [{name: family, var: family}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    family: $family
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /api/v1/Environments
#
# Returns: table<accessToken: string, active: string, autoShutdownDelayMinutes: int, billableOwnerType: int, clientUsage: record<sessionId: string, usageData: record>, connection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record>, container: record<id: string, schemaVersion: string>, containerImage: string, createFromPrebuild: bool, created: string, displayStorageUtilizationInKb: bool, exportedBlobUrl: string, failoverDetails: record<failoverEnabled: bool, failoverRegion: int>, features: record, friendlyName: string, gitStatus: record<ahead: int, behind: int, branch: string, commit: string, hasUncommittedChanges: bool, hasUnpushedChanges: bool, noGitRepo: bool>, id: string, lastStateUpdateReason: string, lastUsed: string, location: string, organizationId: string, ownerId: string, planId: string, platform: string, portForwardingConnection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record>, prebuildType: string, recentFolders: list<string>, resourceTier: int, runtimeConstraints: record<allowedPortPrivacySettings: list, imageAllowList: list>, seed: record<cloneUrl: string, gitConfig: record, recurseClone: bool, repository: record, seedMoniker: string, seedType: string>, skuDisplayName: string, skuName: string, state: string, storageUtilizationInKb: int, subscriptionData: record<computeQuota: int, computeUsage: int, subscriptionId: string, subscriptionState: string>, templateStatus: string, type: string, updated: string>
export def "get-api-v1-environments" [
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
  --name: string
  --plan-id: string
  --deleted: oneof<nothing, bool> # default: false
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/Environments"
    query: [{name: name, var: name}, {name: planId, var: plan_id}, {name: deleted, var: deleted}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    name: $name, plan_id: $plan_id, deleted: $deleted
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# POST /api/v1/Environments
#
# Returns: record<accessToken: string, active: string, autoShutdownDelayMinutes: int, billableOwnerType: int, clientUsage: record<sessionId: string, usageData: record>, connection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, container: record<id: string, schemaVersion: string>, containerImage: string, createFromPrebuild: bool, created: string, displayStorageUtilizationInKb: bool, exportedBlobUrl: string, failoverDetails: record<failoverEnabled: bool, failoverRegion: int>, features: record, friendlyName: string, gitStatus: record<ahead: int, behind: int, branch: string, commit: string, hasUncommittedChanges: bool, hasUnpushedChanges: bool, noGitRepo: bool>, id: string, lastStateUpdateReason: string, lastUsed: string, location: string, organizationId: string, ownerId: string, planId: string, platform: string, portForwardingConnection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, prebuildType: string, recentFolders: list<string>, resourceTier: int, runtimeConstraints: record<allowedPortPrivacySettings: list<int>, imageAllowList: list<string>>, seed: record<cloneUrl: string, gitConfig: record<userEmail: string, userName: string>, recurseClone: bool, repository: record<branchName: string, commitId: string, createType: string, diskUsage: string, name: string, owner: string, prebuildHash: string, repoId: int, url: string>, seedMoniker: string, seedType: string>, skuDisplayName: string, skuName: string, state: string, storageUtilizationInKb: int, subscriptionData: record<computeQuota: int, computeUsage: int, subscriptionId: string, subscriptionState: string>, templateStatus: string, type: string, updated: string>
@deprecated --flag location
@deprecated --flag platform
export def "post-api-v1-environments" [
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
  --access: oneof<nothing, bool>
  --analytics-tracking-id: string # nullable
  --auto-shutdown-delay-minutes: int # format: int32
  --billable-owner: record # shape: {id?: string, login?: string, type?: "0 (User)"|"1 (Organization)"}
  --connection: record # shape: {connectionServiceUri?: string, connectionSessionId?: string, connectionSessionPath?: string, hostPublicKeys?: list<string>, relayEndpoint?: string, relaySasToken?: string, sessionToken?: string, tunnelProperties?: record}
  --container-image: string # nullable
  --create-as-prebuild: oneof<nothing, bool>
  --dev-container-json: string # nullable
  --dev-container-path: string # nullable
  --experimental-features: record # shape: {enableDynamicHttpsDetection?: bool, queueResourceAllocation?: bool, usePrebuildFastPathIfAvailable?: bool, usePrebuiltImages?: bool, useStorageV2?: bool}
  --features: record # nullable
  friendly_name: string
  --git-hub-api-url: string # nullable
  --git-hub-app-url: string # nullable
  --git-hub-pfs-auth-endpoint: string # nullable
  --github-environment-endpoint: string # nullable
  --has-devcontainer-json: oneof<nothing, bool>
  --identity: record # shape: {displayName?: string, id?: string, userName?: string}
  --label: string # nullable
  --location: string # DEPRECATED, nullable
  --netmon-correlation-data: record # shape: {billableOwnerCreatedAt?: string, billableOwnerDatabaseId?: string, billableOwnerGlobalRelayId?: string, billableOwnerPlan?: string, ownerCreatedAt?: string, ownerDatabaseId?: string, ownerGlobalRelayId?: string, ownerPlan?: string, repositoryCreatedAt?: string, repositoryDatabaseId?: string, repositoryGlobalRelayId?: string, repositoryPrivate?: bool}
  --personalization: record # shape: {dotfilesInstallCommand?: string, dotfilesRepository?: string, dotfilesTargetPath?: string}
  --plan-id: string # nullable
  --platform: string # DEPRECATED, nullable
  --runtime-constraints: record # shape: {allowedPortPrivacySettings?: list<int>, imageAllowList?: list<string>}
  --secrets: list # nullable — item shape: {name?: string, type?: "1 (EnvironmentVariable)"|"2 (ContainerRegistry)", value?: string}
  --seed: record # shape: {cloneUrl?: string, gitConfig?: record, recurseClone?: bool, repository?: record, seedMoniker?: string, seedType?: string}
  --sku-name: string # nullable
  --test-account: oneof<nothing, bool>
  type: string
  --user-tier: string # nullable
  --working-directory: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/Environments"
    query: [{name: access, var: access}]
    body: {content_type: "application/json", kind: json, fields: [{name: analyticsTrackingId, var: analytics_tracking_id}, {name: autoShutdownDelayMinutes, var: auto_shutdown_delay_minutes}, {name: billableOwner, var: billable_owner}, {name: connection, var: connection}, {name: containerImage, var: container_image}, {name: createAsPrebuild, var: create_as_prebuild}, {name: devContainerJson, var: dev_container_json}, {name: devContainerPath, var: dev_container_path}, {name: experimentalFeatures, var: experimental_features}, {name: features, var: features}, {name: friendlyName, var: friendly_name}, {name: gitHubApiUrl, var: git_hub_api_url}, {name: gitHubAppUrl, var: git_hub_app_url}, {name: gitHubPfsAuthEndpoint, var: git_hub_pfs_auth_endpoint}, {name: githubEnvironmentEndpoint, var: github_environment_endpoint}, {name: hasDevcontainerJson, var: has_devcontainer_json}, {name: identity, var: identity}, {name: label, var: label}, {name: location, var: location}, {name: netmonCorrelationData, var: netmon_correlation_data}, {name: personalization, var: personalization}, {name: planId, var: plan_id}, {name: platform, var: platform}, {name: runtimeConstraints, var: runtime_constraints}, {name: secrets, var: secrets}, {name: seed, var: seed}, {name: skuName, var: sku_name}, {name: testAccount, var: test_account}, {name: type, var: type}, {name: userTier, var: user_tier}, {name: workingDirectory, var: working_directory}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [201, 307]
    auth: bearer
  } {
    access: $access, analytics_tracking_id: $analytics_tracking_id, auto_shutdown_delay_minutes: $auto_shutdown_delay_minutes, billable_owner: $billable_owner, connection: $connection, container_image: $container_image, create_as_prebuild: $create_as_prebuild, dev_container_json: $dev_container_json, dev_container_path: $dev_container_path, experimental_features: $experimental_features, features: $features, friendly_name: $friendly_name, git_hub_api_url: $git_hub_api_url, git_hub_app_url: $git_hub_app_url, git_hub_pfs_auth_endpoint: $git_hub_pfs_auth_endpoint, github_environment_endpoint: $github_environment_endpoint, has_devcontainer_json: $has_devcontainer_json, identity: $identity, label: $label, location: $location, netmon_correlation_data: $netmon_correlation_data, personalization: $personalization, plan_id: $plan_id, platform: $platform, runtime_constraints: $runtime_constraints, secrets: $secrets, seed: $seed, sku_name: $sku_name, test_account: $test_account, type: $type, user_tier: $user_tier, working_directory: $working_directory
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# DELETE /api/v1/Environments/{environmentId}
export def "delete-api-v1-environments-environment-id" [
  environment_id: string
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
    path: "/api/v1/Environments/{environmentId}"
    path_params: [{name: environmentId, var: environment_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    environment_id: $environment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /api/v1/Environments/{environmentId}
#
# Returns: record<accessToken: string, active: string, autoShutdownDelayMinutes: int, billableOwnerType: int, clientUsage: record<sessionId: string, usageData: record>, connection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, container: record<id: string, schemaVersion: string>, containerImage: string, createFromPrebuild: bool, created: string, displayStorageUtilizationInKb: bool, exportedBlobUrl: string, failoverDetails: record<failoverEnabled: bool, failoverRegion: int>, features: record, friendlyName: string, gitStatus: record<ahead: int, behind: int, branch: string, commit: string, hasUncommittedChanges: bool, hasUnpushedChanges: bool, noGitRepo: bool>, id: string, lastStateUpdateReason: string, lastUsed: string, location: string, organizationId: string, ownerId: string, planId: string, platform: string, portForwardingConnection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, prebuildType: string, recentFolders: list<string>, resourceTier: int, runtimeConstraints: record<allowedPortPrivacySettings: list<int>, imageAllowList: list<string>>, seed: record<cloneUrl: string, gitConfig: record<userEmail: string, userName: string>, recurseClone: bool, repository: record<branchName: string, commitId: string, createType: string, diskUsage: string, name: string, owner: string, prebuildHash: string, repoId: int, url: string>, seedMoniker: string, seedType: string>, skuDisplayName: string, skuName: string, state: string, storageUtilizationInKb: int, subscriptionData: record<computeQuota: int, computeUsage: int, subscriptionId: string, subscriptionState: string>, templateStatus: string, type: string, updated: string>
# operationId: GetEnvironmentRoute
export def "get-environment-route" [
  environment_id: string
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
  --connect: oneof<nothing, bool>
  --pf-connect: oneof<nothing, bool>
  --deleted: oneof<nothing, bool> # default: false
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/Environments/{environmentId}"
    path_params: [{name: environmentId, var: environment_id}]
    query: [{name: connect, var: connect}, {name: pfConnect, var: pf_connect}, {name: deleted, var: deleted}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    environment_id: $environment_id, connect: $connect, pf_connect: $pf_connect, deleted: $deleted
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# PATCH /api/v1/Environments/{environmentId}
#
# Returns: record<accessToken: string, active: string, autoShutdownDelayMinutes: int, billableOwnerType: int, clientUsage: record<sessionId: string, usageData: record>, connection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, container: record<id: string, schemaVersion: string>, containerImage: string, createFromPrebuild: bool, created: string, displayStorageUtilizationInKb: bool, exportedBlobUrl: string, failoverDetails: record<failoverEnabled: bool, failoverRegion: int>, features: record, friendlyName: string, gitStatus: record<ahead: int, behind: int, branch: string, commit: string, hasUncommittedChanges: bool, hasUnpushedChanges: bool, noGitRepo: bool>, id: string, lastStateUpdateReason: string, lastUsed: string, location: string, organizationId: string, ownerId: string, planId: string, platform: string, portForwardingConnection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, prebuildType: string, recentFolders: list<string>, resourceTier: int, runtimeConstraints: record<allowedPortPrivacySettings: list<int>, imageAllowList: list<string>>, seed: record<cloneUrl: string, gitConfig: record<userEmail: string, userName: string>, recurseClone: bool, repository: record<branchName: string, commitId: string, createType: string, diskUsage: string, name: string, owner: string, prebuildHash: string, repoId: int, url: string>, seedMoniker: string, seedType: string>, skuDisplayName: string, skuName: string, state: string, storageUtilizationInKb: int, subscriptionData: record<computeQuota: int, computeUsage: int, subscriptionId: string, subscriptionState: string>, templateStatus: string, type: string, updated: string>
export def "patch-api-v1-environments-environment-id" [
  environment_id: string
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
  --auto-shutdown-delay-minutes: int # nullable, format: int32
  --failover-details: record # shape: {failoverEnabled?: bool, ... (1 more fields)}
  --friendly-name: string # nullable
  --plan-access-token: string # nullable
  --plan-id: string # nullable
  --sku-name: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/api/v1/Environments/{environmentId}"
    path_params: [{name: environmentId, var: environment_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: autoShutdownDelayMinutes, var: auto_shutdown_delay_minutes}, {name: failoverDetails, var: failover_details}, {name: friendlyName, var: friendly_name}, {name: planAccessToken, var: plan_access_token}, {name: planId, var: plan_id}, {name: skuName, var: sku_name}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    environment_id: $environment_id, auto_shutdown_delay_minutes: $auto_shutdown_delay_minutes, failover_details: $failover_details, friendly_name: $friendly_name, plan_access_token: $plan_access_token, plan_id: $plan_id, sku_name: $sku_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# POST /api/v1/Environments/{environmentId}/_callback
#
# Returns: record<accessToken: string, active: string, autoShutdownDelayMinutes: int, billableOwnerType: int, clientUsage: record<sessionId: string, usageData: record>, connection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, container: record<id: string, schemaVersion: string>, containerImage: string, createFromPrebuild: bool, created: string, displayStorageUtilizationInKb: bool, exportedBlobUrl: string, failoverDetails: record<failoverEnabled: bool, failoverRegion: int>, features: record, friendlyName: string, gitStatus: record<ahead: int, behind: int, branch: string, commit: string, hasUncommittedChanges: bool, hasUnpushedChanges: bool, noGitRepo: bool>, id: string, lastStateUpdateReason: string, lastUsed: string, location: string, organizationId: string, ownerId: string, planId: string, platform: string, portForwardingConnection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, prebuildType: string, recentFolders: list<string>, resourceTier: int, runtimeConstraints: record<allowedPortPrivacySettings: list<int>, imageAllowList: list<string>>, seed: record<cloneUrl: string, gitConfig: record<userEmail: string, userName: string>, recurseClone: bool, repository: record<branchName: string, commitId: string, createType: string, diskUsage: string, name: string, owner: string, prebuildHash: string, repoId: int, url: string>, seedMoniker: string, seedType: string>, skuDisplayName: string, skuName: string, state: string, storageUtilizationInKb: int, subscriptionData: record<computeQuota: int, computeUsage: int, subscriptionId: string, subscriptionState: string>, templateStatus: string, type: string, updated: string>
# operationId: UpdateEnvironmentRoute
export def "update-environment-route" [
  environment_id: string
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
  --payload: record # shape: {sessionId?: string, sessionPath?: string}
  type: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/Environments/{environmentId}/_callback"
    path_params: [{name: environmentId, var: environment_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: payload, var: payload}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    environment_id: $environment_id, payload: $payload, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /api/v1/Environments/{environmentId}/archive
#
# Returns: record<accessToken: string, active: string, autoShutdownDelayMinutes: int, billableOwnerType: int, clientUsage: record<sessionId: string, usageData: record>, connection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, container: record<id: string, schemaVersion: string>, containerImage: string, createFromPrebuild: bool, created: string, displayStorageUtilizationInKb: bool, exportedBlobUrl: string, failoverDetails: record<failoverEnabled: bool, failoverRegion: int>, features: record, friendlyName: string, gitStatus: record<ahead: int, behind: int, branch: string, commit: string, hasUncommittedChanges: bool, hasUnpushedChanges: bool, noGitRepo: bool>, id: string, lastStateUpdateReason: string, lastUsed: string, location: string, organizationId: string, ownerId: string, planId: string, platform: string, portForwardingConnection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, prebuildType: string, recentFolders: list<string>, resourceTier: int, runtimeConstraints: record<allowedPortPrivacySettings: list<int>, imageAllowList: list<string>>, seed: record<cloneUrl: string, gitConfig: record<userEmail: string, userName: string>, recurseClone: bool, repository: record<branchName: string, commitId: string, createType: string, diskUsage: string, name: string, owner: string, prebuildHash: string, repoId: int, url: string>, seedMoniker: string, seedType: string>, skuDisplayName: string, skuName: string, state: string, storageUtilizationInKb: int, subscriptionData: record<computeQuota: int, computeUsage: int, subscriptionId: string, subscriptionState: string>, templateStatus: string, type: string, updated: string>
export def "get-api-v1-environments-environment-id-archive" [
  environment_id: string
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
    path: "/api/v1/Environments/{environmentId}/archive"
    path_params: [{name: environmentId, var: environment_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    environment_id: $environment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# POST /api/v1/Environments/{environmentId}/archive
#
# Returns: record<accessToken: string, active: string, autoShutdownDelayMinutes: int, billableOwnerType: int, clientUsage: record<sessionId: string, usageData: record>, connection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, container: record<id: string, schemaVersion: string>, containerImage: string, createFromPrebuild: bool, created: string, displayStorageUtilizationInKb: bool, exportedBlobUrl: string, failoverDetails: record<failoverEnabled: bool, failoverRegion: int>, features: record, friendlyName: string, gitStatus: record<ahead: int, behind: int, branch: string, commit: string, hasUncommittedChanges: bool, hasUnpushedChanges: bool, noGitRepo: bool>, id: string, lastStateUpdateReason: string, lastUsed: string, location: string, organizationId: string, ownerId: string, planId: string, platform: string, portForwardingConnection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, prebuildType: string, recentFolders: list<string>, resourceTier: int, runtimeConstraints: record<allowedPortPrivacySettings: list<int>, imageAllowList: list<string>>, seed: record<cloneUrl: string, gitConfig: record<userEmail: string, userName: string>, recurseClone: bool, repository: record<branchName: string, commitId: string, createType: string, diskUsage: string, name: string, owner: string, prebuildHash: string, repoId: int, url: string>, seedMoniker: string, seedType: string>, skuDisplayName: string, skuName: string, state: string, storageUtilizationInKb: int, subscriptionData: record<computeQuota: int, computeUsage: int, subscriptionId: string, subscriptionState: string>, templateStatus: string, type: string, updated: string>
export def "post-api-v1-environments-environment-id-archive" [
  environment_id: string
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
    method: post
    path: "/api/v1/Environments/{environmentId}/archive"
    path_params: [{name: environmentId, var: environment_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    environment_id: $environment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# POST /api/v1/Environments/{environmentId}/export
#
# Returns: record<accessToken: string, active: string, autoShutdownDelayMinutes: int, billableOwnerType: int, clientUsage: record<sessionId: string, usageData: record>, connection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, container: record<id: string, schemaVersion: string>, containerImage: string, createFromPrebuild: bool, created: string, displayStorageUtilizationInKb: bool, exportedBlobUrl: string, failoverDetails: record<failoverEnabled: bool, failoverRegion: int>, features: record, friendlyName: string, gitStatus: record<ahead: int, behind: int, branch: string, commit: string, hasUncommittedChanges: bool, hasUnpushedChanges: bool, noGitRepo: bool>, id: string, lastStateUpdateReason: string, lastUsed: string, location: string, organizationId: string, ownerId: string, planId: string, platform: string, portForwardingConnection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, prebuildType: string, recentFolders: list<string>, resourceTier: int, runtimeConstraints: record<allowedPortPrivacySettings: list<int>, imageAllowList: list<string>>, seed: record<cloneUrl: string, gitConfig: record<userEmail: string, userName: string>, recurseClone: bool, repository: record<branchName: string, commitId: string, createType: string, diskUsage: string, name: string, owner: string, prebuildHash: string, repoId: int, url: string>, seedMoniker: string, seedType: string>, skuDisplayName: string, skuName: string, state: string, storageUtilizationInKb: int, subscriptionData: record<computeQuota: int, computeUsage: int, subscriptionId: string, subscriptionState: string>, templateStatus: string, type: string, updated: string>
export def "post-api-v1-environments-environment-id-export" [
  environment_id: string
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
    method: post
    path: "/api/v1/Environments/{environmentId}/export"
    path_params: [{name: environmentId, var: environment_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    environment_id: $environment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# PATCH /api/v1/Environments/{environmentId}/folder
#
# Returns: record<accessToken: string, active: string, autoShutdownDelayMinutes: int, billableOwnerType: int, clientUsage: record<sessionId: string, usageData: record>, connection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, container: record<id: string, schemaVersion: string>, containerImage: string, createFromPrebuild: bool, created: string, displayStorageUtilizationInKb: bool, exportedBlobUrl: string, failoverDetails: record<failoverEnabled: bool, failoverRegion: int>, features: record, friendlyName: string, gitStatus: record<ahead: int, behind: int, branch: string, commit: string, hasUncommittedChanges: bool, hasUnpushedChanges: bool, noGitRepo: bool>, id: string, lastStateUpdateReason: string, lastUsed: string, location: string, organizationId: string, ownerId: string, planId: string, platform: string, portForwardingConnection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, prebuildType: string, recentFolders: list<string>, resourceTier: int, runtimeConstraints: record<allowedPortPrivacySettings: list<int>, imageAllowList: list<string>>, seed: record<cloneUrl: string, gitConfig: record<userEmail: string, userName: string>, recurseClone: bool, repository: record<branchName: string, commitId: string, createType: string, diskUsage: string, name: string, owner: string, prebuildHash: string, repoId: int, url: string>, seedMoniker: string, seedType: string>, skuDisplayName: string, skuName: string, state: string, storageUtilizationInKb: int, subscriptionData: record<computeQuota: int, computeUsage: int, subscriptionId: string, subscriptionState: string>, templateStatus: string, type: string, updated: string>
export def "patch-api-v1-environments-environment-id-folder" [
  environment_id: string
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
  --recent-folder-paths: list<string> # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/api/v1/Environments/{environmentId}/folder"
    path_params: [{name: environmentId, var: environment_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: recentFolderPaths, var: recent_folder_paths}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    environment_id: $environment_id, recent_folder_paths: $recent_folder_paths
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /api/v1/Environments/{environmentId}/heartbeattoken
#
# Returns: record<accessToken: string, active: string, autoShutdownDelayMinutes: int, billableOwnerType: int, clientUsage: record<sessionId: string, usageData: record>, connection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, container: record<id: string, schemaVersion: string>, containerImage: string, createFromPrebuild: bool, created: string, displayStorageUtilizationInKb: bool, exportedBlobUrl: string, failoverDetails: record<failoverEnabled: bool, failoverRegion: int>, features: record, friendlyName: string, gitStatus: record<ahead: int, behind: int, branch: string, commit: string, hasUncommittedChanges: bool, hasUnpushedChanges: bool, noGitRepo: bool>, id: string, lastStateUpdateReason: string, lastUsed: string, location: string, organizationId: string, ownerId: string, planId: string, platform: string, portForwardingConnection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, prebuildType: string, recentFolders: list<string>, resourceTier: int, runtimeConstraints: record<allowedPortPrivacySettings: list<int>, imageAllowList: list<string>>, seed: record<cloneUrl: string, gitConfig: record<userEmail: string, userName: string>, recurseClone: bool, repository: record<branchName: string, commitId: string, createType: string, diskUsage: string, name: string, owner: string, prebuildHash: string, repoId: int, url: string>, seedMoniker: string, seedType: string>, skuDisplayName: string, skuName: string, state: string, storageUtilizationInKb: int, subscriptionData: record<computeQuota: int, computeUsage: int, subscriptionId: string, subscriptionState: string>, templateStatus: string, type: string, updated: string>
export def "get-api-v1-environments-environment-id-heartbeattoken" [
  environment_id: string
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
    path: "/api/v1/Environments/{environmentId}/heartbeattoken"
    path_params: [{name: environmentId, var: environment_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    environment_id: $environment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# POST /api/v1/Environments/{environmentId}/notify
#
# Returns: string
export def "post-api-v1-environments-environment-id-notify" [
  environment_id: string
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
  --details: string # nullable
  --display-mode: string # nullable
  --message: string # nullable
  --modal: oneof<nothing, bool>
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/Environments/{environmentId}/notify"
    path_params: [{name: environmentId, var: environment_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: details, var: details}, {name: displayMode, var: display_mode}, {name: message, var: message}, {name: modal, var: modal}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    environment_id: $environment_id, details: $details, display_mode: $display_mode, message: $message, modal: $modal
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# DELETE /api/v1/Environments/{environmentId}/ports/{port}
export def "delete-api-v1-environments-environment-id-ports-port" [
  environment_id: string
  port: int
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
    path: "/api/v1/Environments/{environmentId}/ports/{port}"
    path_params: [{name: environmentId, var: environment_id}, {name: port, var: port}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    environment_id: $environment_id, port: $port
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /api/v1/Environments/{environmentId}/ports/{port}
export def "put-api-v1-environments-environment-id-ports-port" [
  environment_id: string
  port: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --privacy: int@privacy-completer # format: int32
  --tunnel-type: int@tunnel-type-completer # format: int32
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v1/Environments/{environmentId}/ports/{port}"
    path_params: [{name: environmentId, var: environment_id}, {name: port, var: port}]
    body: {content_type: "application/json", kind: json, fields: [{name: privacy, var: privacy}, {name: tunnelType, var: tunnel_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    environment_id: $environment_id, port: $port, privacy: $privacy, tunnel_type: $tunnel_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PATCH /api/v1/Environments/{environmentId}/restore
export def "patch-api-v1-environments-environment-id-restore" [
  environment_id: string
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
    method: patch
    path: "/api/v1/Environments/{environmentId}/restore"
    path_params: [{name: environmentId, var: environment_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    environment_id: $environment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /api/v1/Environments/{environmentId}/secrets
#
# Returns: record<accessToken: string, active: string, autoShutdownDelayMinutes: int, billableOwnerType: int, clientUsage: record<sessionId: string, usageData: record>, connection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, container: record<id: string, schemaVersion: string>, containerImage: string, createFromPrebuild: bool, created: string, displayStorageUtilizationInKb: bool, exportedBlobUrl: string, failoverDetails: record<failoverEnabled: bool, failoverRegion: int>, features: record, friendlyName: string, gitStatus: record<ahead: int, behind: int, branch: string, commit: string, hasUncommittedChanges: bool, hasUnpushedChanges: bool, noGitRepo: bool>, id: string, lastStateUpdateReason: string, lastUsed: string, location: string, organizationId: string, ownerId: string, planId: string, platform: string, portForwardingConnection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, prebuildType: string, recentFolders: list<string>, resourceTier: int, runtimeConstraints: record<allowedPortPrivacySettings: list<int>, imageAllowList: list<string>>, seed: record<cloneUrl: string, gitConfig: record<userEmail: string, userName: string>, recurseClone: bool, repository: record<branchName: string, commitId: string, createType: string, diskUsage: string, name: string, owner: string, prebuildHash: string, repoId: int, url: string>, seedMoniker: string, seedType: string>, skuDisplayName: string, skuName: string, state: string, storageUtilizationInKb: int, subscriptionData: record<computeQuota: int, computeUsage: int, subscriptionId: string, subscriptionState: string>, templateStatus: string, type: string, updated: string>
export def "put-api-v1-environments-environment-id-secrets" [
  environment_id: string
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
  --secrets: list # nullable — item shape: {name?: string, type?: "1 (EnvironmentVariable)"|"2 (ContainerRegistry)", value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/v1/Environments/{environmentId}/secrets"
    path_params: [{name: environmentId, var: environment_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: secrets, var: secrets}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [204, 307]
    auth: bearer
  } {
    environment_id: $environment_id, secrets: $secrets
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# POST /api/v1/Environments/{environmentId}/shutdown
#
# Returns: record<accessToken: string, active: string, autoShutdownDelayMinutes: int, billableOwnerType: int, clientUsage: record<sessionId: string, usageData: record>, connection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, container: record<id: string, schemaVersion: string>, containerImage: string, createFromPrebuild: bool, created: string, displayStorageUtilizationInKb: bool, exportedBlobUrl: string, failoverDetails: record<failoverEnabled: bool, failoverRegion: int>, features: record, friendlyName: string, gitStatus: record<ahead: int, behind: int, branch: string, commit: string, hasUncommittedChanges: bool, hasUnpushedChanges: bool, noGitRepo: bool>, id: string, lastStateUpdateReason: string, lastUsed: string, location: string, organizationId: string, ownerId: string, planId: string, platform: string, portForwardingConnection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, prebuildType: string, recentFolders: list<string>, resourceTier: int, runtimeConstraints: record<allowedPortPrivacySettings: list<int>, imageAllowList: list<string>>, seed: record<cloneUrl: string, gitConfig: record<userEmail: string, userName: string>, recurseClone: bool, repository: record<branchName: string, commitId: string, createType: string, diskUsage: string, name: string, owner: string, prebuildHash: string, repoId: int, url: string>, seedMoniker: string, seedType: string>, skuDisplayName: string, skuName: string, state: string, storageUtilizationInKb: int, subscriptionData: record<computeQuota: int, computeUsage: int, subscriptionId: string, subscriptionState: string>, templateStatus: string, type: string, updated: string>
export def "post-api-v1-environments-environment-id-shutdown" [
  environment_id: string
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
    method: post
    path: "/api/v1/Environments/{environmentId}/shutdown"
    path_params: [{name: environmentId, var: environment_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    environment_id: $environment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# POST /api/v1/Environments/{environmentId}/start
#
# Returns: record<accessToken: string, active: string, autoShutdownDelayMinutes: int, billableOwnerType: int, clientUsage: record<sessionId: string, usageData: record>, connection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, container: record<id: string, schemaVersion: string>, containerImage: string, createFromPrebuild: bool, created: string, displayStorageUtilizationInKb: bool, exportedBlobUrl: string, failoverDetails: record<failoverEnabled: bool, failoverRegion: int>, features: record, friendlyName: string, gitStatus: record<ahead: int, behind: int, branch: string, commit: string, hasUncommittedChanges: bool, hasUnpushedChanges: bool, noGitRepo: bool>, id: string, lastStateUpdateReason: string, lastUsed: string, location: string, organizationId: string, ownerId: string, planId: string, platform: string, portForwardingConnection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, prebuildType: string, recentFolders: list<string>, resourceTier: int, runtimeConstraints: record<allowedPortPrivacySettings: list<int>, imageAllowList: list<string>>, seed: record<cloneUrl: string, gitConfig: record<userEmail: string, userName: string>, recurseClone: bool, repository: record<branchName: string, commitId: string, createType: string, diskUsage: string, name: string, owner: string, prebuildHash: string, repoId: int, url: string>, seedMoniker: string, seedType: string>, skuDisplayName: string, skuName: string, state: string, storageUtilizationInKb: int, subscriptionData: record<computeQuota: int, computeUsage: int, subscriptionId: string, subscriptionState: string>, templateStatus: string, type: string, updated: string>
export def "post-api-v1-environments-environment-id-start" [
  environment_id: string
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
  --access: oneof<nothing, bool>
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/api/v1/Environments/{environmentId}/start"
    path_params: [{name: environmentId, var: environment_id}]
    query: [{name: access, var: access}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    environment_id: $environment_id, access: $access
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /api/v1/Environments/{environmentId}/state
export def "get-api-v1-environments-environment-id-state" [
  environment_id: string
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
    path: "/api/v1/Environments/{environmentId}/state"
    path_params: [{name: environmentId, var: environment_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    environment_id: $environment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /api/v1/Environments/{environmentId}/updates
#
# Returns: record<accessToken: string, active: string, autoShutdownDelayMinutes: int, billableOwnerType: int, clientUsage: record<sessionId: string, usageData: record>, connection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, container: record<id: string, schemaVersion: string>, containerImage: string, createFromPrebuild: bool, created: string, displayStorageUtilizationInKb: bool, exportedBlobUrl: string, failoverDetails: record<failoverEnabled: bool, failoverRegion: int>, features: record, friendlyName: string, gitStatus: record<ahead: int, behind: int, branch: string, commit: string, hasUncommittedChanges: bool, hasUnpushedChanges: bool, noGitRepo: bool>, id: string, lastStateUpdateReason: string, lastUsed: string, location: string, organizationId: string, ownerId: string, planId: string, platform: string, portForwardingConnection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, prebuildType: string, recentFolders: list<string>, resourceTier: int, runtimeConstraints: record<allowedPortPrivacySettings: list<int>, imageAllowList: list<string>>, seed: record<cloneUrl: string, gitConfig: record<userEmail: string, userName: string>, recurseClone: bool, repository: record<branchName: string, commitId: string, createType: string, diskUsage: string, name: string, owner: string, prebuildHash: string, repoId: int, url: string>, seedMoniker: string, seedType: string>, skuDisplayName: string, skuName: string, state: string, storageUtilizationInKb: int, subscriptionData: record<computeQuota: int, computeUsage: int, subscriptionId: string, subscriptionState: string>, templateStatus: string, type: string, updated: string>
export def "get-api-v1-environments-environment-id-updates" [
  environment_id: string
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
    path: "/api/v1/Environments/{environmentId}/updates"
    path_params: [{name: environmentId, var: environment_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    environment_id: $environment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# POST /api/v1/GenevaActions/Billing/resend
#
# Returns: record<billGenerationTime: string, environmentId: string, id: string, location: int, partitionKey: string, periodEnd: string, periodStart: string, plan: record<location: int, name: string, providerNamespace: string, resourceGroup: string, resourceId: string, subscription: string>, usage: record, usageDetail: table<endState: int, id: string, resourceUsage: record, sku: record>>
export def "post-api-v1-geneva-actions-billing-resend" [
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
  --end-time: string # format: date-time
  --start-time: string # format: date-time
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/GenevaActions/Billing/resend"
    body: {content_type: "application/json", kind: json, fields: [{name: endTime, var: end_time}, {name: startTime, var: start_time}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    end_time: $end_time, start_time: $start_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /api/v1/GenevaActions/Billing/{environmentId}
#
# Returns: record<billGenerationTime: string, environmentId: string, id: string, location: int, partitionKey: string, periodEnd: string, periodStart: string, plan: record<location: int, name: string, providerNamespace: string, resourceGroup: string, resourceId: string, subscription: string>, usage: record, usageDetail: table<endState: int, id: string, resourceUsage: record, sku: record>>
export def "get-api-v1-geneva-actions-billing-environment-id" [
  environment_id: string
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
  --start-time: string
  --end-time: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/GenevaActions/Billing/{environmentId}"
    path_params: [{name: environmentId, var: environment_id}]
    query: [{name: startTime, var: start_time}, {name: endTime, var: end_time}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    environment_id: $environment_id, start_time: $start_time, end_time: $end_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /api/v1/GenevaActions/Billing/{environmentId}/state-changes
#
# Returns: record<environment: record<id: string, name: string, sku: record<name: string, tier: string>, userId: string>, id: string, newValue: int, oldValue: int, partitionKey: string, time: string>
export def "get-api-v1-geneva-actions-billing-environment-id-state-changes" [
  environment_id: string
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
    path: "/api/v1/GenevaActions/Billing/{environmentId}/state-changes"
    path_params: [{name: environmentId, var: environment_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    environment_id: $environment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# POST /api/v1/GenevaActions/Billing/{environmentId}/state-changes
#
# Returns: record<environment: record<id: string, name: string, sku: record<name: string, tier: string>, userId: string>, id: string, newValue: int, oldValue: int, partitionKey: string, time: string>
export def "post-api-v1-geneva-actions-billing-environment-id-state-changes" [
  environment_id: string
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
  --new-value: int@new-value-completer # format: int32
  --old-value: int@old-value-completer # format: int32
  --time: string # nullable, format: date-time
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/GenevaActions/Billing/{environmentId}/state-changes"
    path_params: [{name: environmentId, var: environment_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: newValue, var: new_value}, {name: oldValue, var: old_value}, {name: time, var: time}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    environment_id: $environment_id, new_value: $new_value, old_value: $old_value, time: $time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# POST /api/v1/GenevaActions/Configuration/{target}
#
# Returns: record<comment: string, key: string, value: string>
export def "post-api-v1-geneva-actions-configuration-target" [
  target: string
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
  --comment: string # nullable
  --key: string # nullable
  --value: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/GenevaActions/Configuration/{target}"
    path_params: [{name: target, var: target}]
    body: {content_type: "application/json", kind: json, fields: [{name: comment, var: comment}, {name: key, var: key}, {name: value, var: value}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    target: $target, comment: $comment, key: $key, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# DELETE /api/v1/GenevaActions/Configuration/{target}/{key}
export def "delete-api-v1-geneva-actions-configuration-target-key" [
  target: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/v1/GenevaActions/Configuration/{target}/{key}"
    path_params: [{name: target, var: target}, {name: key, var: key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    target: $target, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /api/v1/GenevaActions/Configuration/{target}/{key}
#
# Returns: record<comment: string, key: string, value: string>
export def "get-api-v1-geneva-actions-configuration-target-key" [
  target: string
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/GenevaActions/Configuration/{target}/{key}"
    path_params: [{name: target, var: target}, {name: key, var: key}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    target: $target, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# DELETE /api/v1/GenevaActions/Environments/{environmentId}
export def "delete-api-v1-geneva-actions-environments-environment-id" [
  environment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --deletion-type: string
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/v1/GenevaActions/Environments/{environmentId}"
    path_params: [{name: environmentId, var: environment_id}]
    query: [{name: deletionType, var: deletion_type}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    environment_id: $environment_id, deletion_type: $deletion_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /api/v1/GenevaActions/Environments/{environmentId}
#
# Returns: record<accessToken: string, active: string, autoShutdownDelayMinutes: int, billableOwnerType: int, clientUsage: record<sessionId: string, usageData: record>, connection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, container: record<id: string, schemaVersion: string>, containerImage: string, createFromPrebuild: bool, created: string, displayStorageUtilizationInKb: bool, exportedBlobUrl: string, failoverDetails: record<failoverEnabled: bool, failoverRegion: int>, features: record, friendlyName: string, gitStatus: record<ahead: int, behind: int, branch: string, commit: string, hasUncommittedChanges: bool, hasUnpushedChanges: bool, noGitRepo: bool>, id: string, lastStateUpdateReason: string, lastUsed: string, location: string, organizationId: string, ownerId: string, planId: string, platform: string, portForwardingConnection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, prebuildType: string, recentFolders: list<string>, resourceTier: int, runtimeConstraints: record<allowedPortPrivacySettings: list<int>, imageAllowList: list<string>>, seed: record<cloneUrl: string, gitConfig: record<userEmail: string, userName: string>, recurseClone: bool, repository: record<branchName: string, commitId: string, createType: string, diskUsage: string, name: string, owner: string, prebuildHash: string, repoId: int, url: string>, seedMoniker: string, seedType: string>, skuDisplayName: string, skuName: string, state: string, storageUtilizationInKb: int, subscriptionData: record<computeQuota: int, computeUsage: int, subscriptionId: string, subscriptionState: string>, templateStatus: string, type: string, updated: string>
export def "get-api-v1-geneva-actions-environments-environment-id" [
  environment_id: string
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
    path: "/api/v1/GenevaActions/Environments/{environmentId}"
    path_params: [{name: environmentId, var: environment_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    environment_id: $environment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# PUT /api/v1/GenevaActions/Environments/{environmentId}/archive
#
# Returns: record<accessToken: string, active: string, autoShutdownDelayMinutes: int, billableOwnerType: int, clientUsage: record<sessionId: string, usageData: record>, connection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, container: record<id: string, schemaVersion: string>, containerImage: string, createFromPrebuild: bool, created: string, displayStorageUtilizationInKb: bool, exportedBlobUrl: string, failoverDetails: record<failoverEnabled: bool, failoverRegion: int>, features: record, friendlyName: string, gitStatus: record<ahead: int, behind: int, branch: string, commit: string, hasUncommittedChanges: bool, hasUnpushedChanges: bool, noGitRepo: bool>, id: string, lastStateUpdateReason: string, lastUsed: string, location: string, organizationId: string, ownerId: string, planId: string, platform: string, portForwardingConnection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, prebuildType: string, recentFolders: list<string>, resourceTier: int, runtimeConstraints: record<allowedPortPrivacySettings: list<int>, imageAllowList: list<string>>, seed: record<cloneUrl: string, gitConfig: record<userEmail: string, userName: string>, recurseClone: bool, repository: record<branchName: string, commitId: string, createType: string, diskUsage: string, name: string, owner: string, prebuildHash: string, repoId: int, url: string>, seedMoniker: string, seedType: string>, skuDisplayName: string, skuName: string, state: string, storageUtilizationInKb: int, subscriptionData: record<computeQuota: int, computeUsage: int, subscriptionId: string, subscriptionState: string>, templateStatus: string, type: string, updated: string>
export def "put-api-v1-geneva-actions-environments-environment-id-archive" [
  environment_id: string
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
    path: "/api/v1/GenevaActions/Environments/{environmentId}/archive"
    path_params: [{name: environmentId, var: environment_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    environment_id: $environment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /api/v1/GenevaActions/Environments/{environmentId}/archived_storage_sas/{targetBlob}
#
# Returns: string
export def "get-api-v1-geneva-actions-environments-environment-id-archived-storage-sas-target-blob" [
  environment_id: string
  target_blob: string
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
]: nothing -> any {
  http-request {
    method: get
    path: "/api/v1/GenevaActions/Environments/{environmentId}/archived_storage_sas/{targetBlob}"
    path_params: [{name: environmentId, var: environment_id}, {name: targetBlob, var: target_blob}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    environment_id: $environment_id, target_blob: $target_blob
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# PUT /api/v1/GenevaActions/Environments/{environmentId}/shutdown
#
# Returns: record<accessToken: string, active: string, autoShutdownDelayMinutes: int, billableOwnerType: int, clientUsage: record<sessionId: string, usageData: record>, connection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, container: record<id: string, schemaVersion: string>, containerImage: string, createFromPrebuild: bool, created: string, displayStorageUtilizationInKb: bool, exportedBlobUrl: string, failoverDetails: record<failoverEnabled: bool, failoverRegion: int>, features: record, friendlyName: string, gitStatus: record<ahead: int, behind: int, branch: string, commit: string, hasUncommittedChanges: bool, hasUnpushedChanges: bool, noGitRepo: bool>, id: string, lastStateUpdateReason: string, lastUsed: string, location: string, organizationId: string, ownerId: string, planId: string, platform: string, portForwardingConnection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, prebuildType: string, recentFolders: list<string>, resourceTier: int, runtimeConstraints: record<allowedPortPrivacySettings: list<int>, imageAllowList: list<string>>, seed: record<cloneUrl: string, gitConfig: record<userEmail: string, userName: string>, recurseClone: bool, repository: record<branchName: string, commitId: string, createType: string, diskUsage: string, name: string, owner: string, prebuildHash: string, repoId: int, url: string>, seedMoniker: string, seedType: string>, skuDisplayName: string, skuName: string, state: string, storageUtilizationInKb: int, subscriptionData: record<computeQuota: int, computeUsage: int, subscriptionId: string, subscriptionState: string>, templateStatus: string, type: string, updated: string>
export def "put-api-v1-geneva-actions-environments-environment-id-shutdown" [
  environment_id: string
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
    path: "/api/v1/GenevaActions/Environments/{environmentId}/shutdown"
    path_params: [{name: environmentId, var: environment_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    environment_id: $environment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# POST /api/v1/GenevaActions/Environments/{environmentId}/upload/running/vm/logs
#
# Returns: record<containerName: string, message: string, pathInContainer: string, storageUri: string, vmResourceId: string>
export def "post-api-v1-geneva-actions-environments-environment-id-upload-running-vm-logs" [
  environment_id: string
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
    method: post
    path: "/api/v1/GenevaActions/Environments/{environmentId}/upload/running/vm/logs"
    path_params: [{name: environmentId, var: environment_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    environment_id: $environment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# POST /api/v1/GenevaActions/Pools/change-resource-deletion-setting
#
# Returns: record<comment: string, key: string, value: string>
export def "post-api-v1-geneva-actions-pools-change-resource-deletion-setting" [
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
  --comment: string # nullable
  --enabled: oneof<nothing, bool>
  --pool-code: string # nullable
  --pool-type: string # nullable
  --region: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/GenevaActions/Pools/change-resource-deletion-setting"
    body: {content_type: "application/json", kind: json, fields: [{name: comment, var: comment}, {name: enabled, var: enabled}, {name: poolCode, var: pool_code}, {name: poolType, var: pool_type}, {name: region, var: region}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    comment: $comment, enabled: $enabled, pool_code: $pool_code, pool_type: $pool_type, region: $region
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# POST /api/v1/GenevaActions/Pools/{poolCode}/rotate-pool
export def "post-api-v1-geneva-actions-pools-pool-code-rotate-pool" [
  pool_code: string
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
    path: "/api/v1/GenevaActions/Pools/{poolCode}/rotate-pool"
    path_params: [{name: poolCode, var: pool_code}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pool_code: $pool_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/v1/GenevaActions/Pools/{target}
#
# Returns: record<comment: string, key: string, value: string>
export def "post-api-v1-geneva-actions-pools-target" [
  target: string
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
  --comment: string # nullable
  --max-target-count: string # nullable
  --min-target-count: string # nullable
  --pool-code: string # nullable
  --pool-type: string # nullable
  --region: string # nullable
  --target-count: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/GenevaActions/Pools/{target}"
    path_params: [{name: target, var: target}]
    body: {content_type: "application/json", kind: json, fields: [{name: comment, var: comment}, {name: maxTargetCount, var: max_target_count}, {name: minTargetCount, var: min_target_count}, {name: poolCode, var: pool_code}, {name: poolType, var: pool_type}, {name: region, var: region}, {name: targetCount, var: target_count}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    target: $target, comment: $comment, max_target_count: $max_target_count, min_target_count: $min_target_count, pool_code: $pool_code, pool_type: $pool_type, region: $region, target_count: $target_count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# POST /api/v1/GenevaActions/Prebuilds/pools/createorupdatesettings
export def "post-api-v1-geneva-actions-prebuilds-pools-createorupdatesettings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --branch-name: string # nullable
  --dev-container-path: string # nullable
  --pools: list # nullable — item shape: {poolType?: "0 (None)"|"1 (Blob)"|"2 (CodespacePool)"|"3 (StoragePool)"|"4 (CodespaceAndStoragePool)", skuName?: string, targetCount?: int}
  --repo-id: string # nullable
  --storage-type: int@storage-type-completer # format: int32
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/GenevaActions/Prebuilds/pools/createorupdatesettings"
    body: {content_type: "application/json", kind: json, fields: [{name: branchName, var: branch_name}, {name: devContainerPath, var: dev_container_path}, {name: pools, var: pools}, {name: repoId, var: repo_id}, {name: storageType, var: storage_type}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    branch_name: $branch_name, dev_container_path: $dev_container_path, pools: $pools, repo_id: $repo_id, storage_type: $storage_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/v1/GenevaActions/Prebuilds/pools/delete
export def "post-api-v1-geneva-actions-prebuilds-pools-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --branch-name: string # nullable
  --dev-container-path: string # nullable
  --pools: list # nullable — item shape: {poolType?: "0 (None)"|"1 (Blob)"|"2 (CodespacePool)"|"3 (StoragePool)"|"4 (CodespaceAndStoragePool)", skuName?: string, targetCount?: int}
  --repo-id: string # nullable
  --storage-type: int@storage-type-completer # format: int32
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/GenevaActions/Prebuilds/pools/delete"
    body: {content_type: "application/json", kind: json, fields: [{name: branchName, var: branch_name}, {name: devContainerPath, var: dev_container_path}, {name: pools, var: pools}, {name: repoId, var: repo_id}, {name: storageType, var: storage_type}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    branch_name: $branch_name, dev_container_path: $dev_container_path, pools: $pools, repo_id: $repo_id, storage_type: $storage_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/v1/GenevaActions/Privacy/refresh-profile-telemetry-properties
#
# Returns: record<failed: table<oid: string, provider: string, tid: string>, succeeded: table<oid: string, provider: string, tid: string>>
export def "post-api-v1-geneva-actions-privacy-refresh-profile-telemetry-properties" [
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
  --partner: string # nullable
  --tenant-id: string # nullable
  --user-ids: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/GenevaActions/Privacy/refresh-profile-telemetry-properties"
    body: {content_type: "application/json", kind: json, fields: [{name: partner, var: partner}, {name: tenantId, var: tenant_id}, {name: userIds, var: user_ids}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    partner: $partner, tenant_id: $tenant_id, user_ids: $user_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# POST /api/v1/GenevaActions/Resources/{resourceId}/under-investigation
#
# Returns: record<investigationStarted: string, resourceId: string, underInvestigation: bool, updated: bool>
export def "post-api-v1-geneva-actions-resources-resource-id-under-investigation" [
  resource_id: string
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
    method: post
    path: "/api/v1/GenevaActions/Resources/{resourceId}/under-investigation"
    path_params: [{name: resourceId, var: resource_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    resource_id: $resource_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# DELETE /api/v1/GenevaActions/VnetPoolDefinitions
export def "delete-api-v1-geneva-actions-vnet-pool-definitions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  dimensions: record
  --is-enabled: oneof<nothing, bool>
  location: int@location-completer # format: int32
  --logical-skus: list<string> # nullable
  subtype: int@subtype-completer # format: int32
  target_count: int # format: int32
  type: int@type-completer # format: int32
]: any -> any {
  $in | http-request {
    method: delete
    path: "/api/v1/GenevaActions/VnetPoolDefinitions"
    body: {content_type: "application/json", kind: json, fields: [{name: dimensions, var: dimensions}, {name: isEnabled, var: is_enabled, required: true}, {name: location, var: location}, {name: logicalSkus, var: logical_skus}, {name: subtype, var: subtype}, {name: targetCount, var: target_count}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    dimensions: $dimensions, is_enabled: $is_enabled, location: $location, logical_skus: $logical_skus, subtype: $subtype, target_count: $target_count, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/v1/GenevaActions/VnetPoolDefinitions
export def "post-api-v1-geneva-actions-vnet-pool-definitions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  dimensions: record
  --is-enabled: oneof<nothing, bool>
  location: int@location-completer # format: int32
  --logical-skus: list<string> # nullable
  subtype: int@subtype-completer # format: int32
  target_count: int # format: int32
  type: int@type-completer # format: int32
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/GenevaActions/VnetPoolDefinitions"
    body: {content_type: "application/json", kind: json, fields: [{name: dimensions, var: dimensions}, {name: isEnabled, var: is_enabled, required: true}, {name: location, var: location}, {name: logicalSkus, var: logical_skus}, {name: subtype, var: subtype}, {name: targetCount, var: target_count}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    dimensions: $dimensions, is_enabled: $is_enabled, location: $location, logical_skus: $logical_skus, subtype: $subtype, target_count: $target_count, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/v1/HeartBeat
export def "post-api-v1-heart-beat" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --agent-version: string # nullable
  --collected-data-list: list # nullable — item shape: {environmentId?: string, name?: string, parentActivityId?: string, timestamp?: string}
  --environment-id: string # nullable
  --resource-id: string # format: uuid
  --time-stamp: string # format: date-time
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/HeartBeat"
    body: {content_type: "application/json", kind: json, fields: [{name: agentVersion, var: agent_version}, {name: collectedDataList, var: collected_data_list}, {name: environmentId, var: environment_id}, {name: resourceId, var: resource_id}, {name: timeStamp, var: time_stamp}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    agent_version: $agent_version, collected_data_list: $collected_data_list, environment_id: $environment_id, resource_id: $resource_id, time_stamp: $time_stamp
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /api/v1/Locations
#
# Returns: record<available: list<int>, current: int, hostnames: record>
export def "get-api-v1-locations" [
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
    path: "/api/v1/Locations"
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /api/v1/Locations/{location}
#
# Returns: record<skus: table<availableSettings: record, displayName: string, name: string, os: string>>
export def "get-api-v1-locations-location" [
  location: string
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
  --plan-id: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/Locations/{location}"
    path_params: [{name: location, var: location}]
    query: [{name: planId, var: plan_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    location: $location, plan_id: $plan_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# POST /api/v1/Prebuilds/pools/{poolId}/instances
export def "post-api-v1-prebuilds-pools-pool-id-instances" [
  pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --environment-options: record # shape: {correlationId?: string}
  --secrets: list # nullable — item shape: {name?: string, type?: "1 (EnvironmentVariable)"|"2 (ContainerRegistry)", value?: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/Prebuilds/pools/{poolId}/instances"
    path_params: [{name: poolId, var: pool_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: environmentOptions, var: environment_options}, {name: secrets, var: secrets}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    pool_id: $pool_id, environment_options: $environment_options, secrets: $secrets
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /api/v1/Prebuilds/pools/{poolId}/instances
export def "put-api-v1-prebuilds-pools-pool-id-instances" [
  pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --environment-options: record # shape: {correlationId?: string}
  --secrets: list # nullable — item shape: {name?: string, type?: "1 (EnvironmentVariable)"|"2 (ContainerRegistry)", value?: string}
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v1/Prebuilds/pools/{poolId}/instances"
    path_params: [{name: poolId, var: pool_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: environmentOptions, var: environment_options}, {name: secrets, var: secrets}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    pool_id: $pool_id, environment_options: $environment_options, secrets: $secrets
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /api/v1/Prebuilds/template/{environmentId}
#
# Returns: record<branchName: string, commitId: string, id: string, isPrebuild: bool, lastUsedTime: string, logicalSkus: list<string>, prebuildHash: string, repoId: int, templateStatus: string>
# operationId: GetTemplateInfoRoute
export def "get-template-info-route" [
  environment_id: string
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
    path: "/api/v1/Prebuilds/template/{environmentId}"
    path_params: [{name: environmentId, var: environment_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    environment_id: $environment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /api/v1/Prebuilds/templates/repo/{repoId}/branch/{branchName}/hash/{prebuildHash}/location/{location}/skus
#
# Returns: record<branchName: string, devContainerPath: string, location: int, poolSkus: list<string>, prebuildHash: string, repoId: string, supportedSkus: list<string>, templateSkus: list<string>>
# operationId: GetPrebuildReadinessRoute
export def "get-prebuild-readiness-route" [
  repo_id: string
  branch_name: string
  prebuild_hash: string
  location: string
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
  --storage-type: int@storage-type-completer # format: int32
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/Prebuilds/templates/repo/{repoId}/branch/{branchName}/hash/{prebuildHash}/location/{location}/skus"
    path_params: [{name: repoId, var: repo_id}, {name: branchName, var: branch_name}, {name: prebuildHash, var: prebuild_hash}, {name: location, var: location}]
    query: [{name: storageType, var: storage_type}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    repo_id: $repo_id, branch_name: $branch_name, prebuild_hash: $prebuild_hash, location: $location, storage_type: $storage_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /api/v1/Sas
#
# Returns: table<filters: list<record>, id: string, lastModified: string, notes: string, scope: int, secretName: string, type: int>
export def "get-api-v1-sas" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/Sas"
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /api/v1/Secrets
#
# Returns: table<filters: list<record>, id: string, lastModified: string, notes: string, scope: int, secretName: string, type: int>
export def "get-api-v1-secrets" [
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
  --plan-id: string
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/Secrets"
    query: [{name: planId, var: plan_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    plan_id: $plan_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# POST /api/v1/Secrets
#
# Returns: record<filters: table<type: int, value: string>, id: string, lastModified: string, notes: string, scope: int, secretName: string, type: int>
export def "post-api-v1-secrets" [
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
  --plan-id: string
  --filters: list # nullable — item shape: {type?: "1 (GitRepo)"|"2 (CodespaceName)", value?: string}
  --notes: string # nullable
  --scope: int@scope-completer # format: int32
  --secret-name: string # nullable
  --type: int@type-completer-1 # format: int32
  --value: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/Secrets"
    query: [{name: planId, var: plan_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: filters, var: filters}, {name: notes, var: notes}, {name: scope, var: scope}, {name: secretName, var: secret_name}, {name: type, var: type}, {name: value, var: value}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    plan_id: $plan_id, filters: $filters, notes: $notes, scope: $scope, secret_name: $secret_name, type: $type, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# DELETE /api/v1/Secrets/{secretId}
export def "delete-api-v1-secrets-secret-id" [
  secret_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --plan-id: string
  --scope: int@scope-completer # format: int32
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/v1/Secrets/{secretId}"
    path_params: [{name: secretId, var: secret_id}]
    query: [{name: planId, var: plan_id}, {name: scope, var: scope}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    secret_id: $secret_id, plan_id: $plan_id, scope: $scope
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /api/v1/Secrets/{secretId}
#
# Returns: record<filters: table<type: int, value: string>, id: string, lastModified: string, notes: string, scope: int, secretName: string, type: int>
export def "put-api-v1-secrets-secret-id" [
  secret_id: string
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
  --plan-id: string
  --filters: list # nullable — item shape: {type?: "1 (GitRepo)"|"2 (CodespaceName)", value?: string}
  --notes: string # nullable
  --scope: int@scope-completer # format: int32
  --secret-name: string # nullable
  --value: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/v1/Secrets/{secretId}"
    path_params: [{name: secretId, var: secret_id}]
    query: [{name: planId, var: plan_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: filters, var: filters}, {name: notes, var: notes}, {name: scope, var: scope}, {name: secretName, var: secret_name}, {name: value, var: value}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    secret_id: $secret_id, plan_id: $plan_id, filters: $filters, notes: $notes, scope: $scope, secret_name: $secret_name, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# DELETE /api/v1/Tenant/{tenantId}
export def "delete-api-v1-tenant-tenant-id" [
  tenant_id: string
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
    path: "/api/v1/Tenant/{tenantId}"
    path_params: [{name: tenantId, var: tenant_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tenant_id: $tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /api/v1/Tenant/{tenantId}
#
# Returns: record<id: string>
export def "get-api-v1-tenant-tenant-id" [
  tenant_id: string
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
    path: "/api/v1/Tenant/{tenantId}"
    path_params: [{name: tenantId, var: tenant_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    tenant_id: $tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# PUT /api/v1/Tenant/{tenantId}
export def "put-api-v1-tenant-tenant-id" [
  tenant_id: string
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
    method: put
    path: "/api/v1/Tenant/{tenantId}"
    path_params: [{name: tenantId, var: tenant_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tenant_id: $tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/v1/Tokens/plans/{planName}/deleteAllCodespaces
export def "post-api-v1-tokens-plans-plan-name-delete-all-codespaces" [
  plan_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expiration: string # format: date-time
  --x-subscription-id: string
]: nothing -> any {
  http-request {
    method: post
    path: "/api/v1/Tokens/plans/{planName}/deleteAllCodespaces"
    path_params: [{name: planName, var: plan_name}]
    query: [{name: expiration, var: expiration}]
    header: [{name: x-subscription-id, var: x_subscription_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    plan_name: $plan_name, expiration: $expiration, x_subscription_id: $x_subscription_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/v1/Tokens/plans/{planName}/readAllCodespaces
export def "post-api-v1-tokens-plans-plan-name-read-all-codespaces" [
  plan_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expiration: string # format: date-time
  --x-subscription-id: string
]: nothing -> any {
  http-request {
    method: post
    path: "/api/v1/Tokens/plans/{planName}/readAllCodespaces"
    path_params: [{name: planName, var: plan_name}]
    query: [{name: expiration, var: expiration}]
    header: [{name: x-subscription-id, var: x_subscription_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    plan_name: $plan_name, expiration: $expiration, x_subscription_id: $x_subscription_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/v1/Tokens/plans/{planName}/writeCodespaces
export def "post-api-v1-tokens-plans-plan-name-write-codespaces" [
  plan_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expiration: string # format: date-time
  --x-subscription-id: string
]: nothing -> any {
  http-request {
    method: post
    path: "/api/v1/Tokens/plans/{planName}/writeCodespaces"
    path_params: [{name: planName, var: plan_name}]
    query: [{name: expiration, var: expiration}]
    header: [{name: x-subscription-id, var: x_subscription_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    plan_name: $plan_name, expiration: $expiration, x_subscription_id: $x_subscription_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/v1/Tokens/plans/{planName}/writeDelegates
export def "post-api-v1-tokens-plans-plan-name-write-delegates" [
  plan_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-subscription-id: string
  --environment-ids: list<string> # nullable
  --expiration: string # nullable, format: date-time
  --identity: record # shape: {displayName?: string, id?: string, username?: string}
  --port-numbers: list<int> # nullable
  --scope: string # nullable
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/Tokens/plans/{planName}/writeDelegates"
    path_params: [{name: planName, var: plan_name}]
    header: [{name: x-subscription-id, var: x_subscription_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: environmentIds, var: environment_ids}, {name: expiration, var: expiration}, {name: identity, var: identity}, {name: portNumbers, var: port_numbers}, {name: scope, var: scope}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    plan_name: $plan_name, x_subscription_id: $x_subscription_id, environment_ids: $environment_ids, expiration: $expiration, identity: $identity, port_numbers: $port_numbers, scope: $scope
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /api/v1/Tokens/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/{providerNamespace}/plans/{resourceName}
export def "put-api-v1-tokens-subscriptions-subscription-id-resource-groups-resource-group-providers-provider-namespace-plans-resource-name" [
  subscription_id: string
  resource_group: string
  provider_namespace: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --headers: record
  --id: string # nullable
  --identity: record # shape: {principalId?: string, tenantId?: string, type?: string}
  --location: string # nullable
  --name: string # nullable
  --properties: record # shape: {defaultCodespaceSku?: string, defaultEnvironmentSku?: string, encryption?: record, userId?: string, vnetProperties?: record}
  --provisioning-state: string # nullable
  --tags: record # nullable
  --type: string # nullable
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v1/Tokens/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/{providerNamespace}/plans/{resourceName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroup, var: resource_group}, {name: providerNamespace, var: provider_namespace}, {name: resourceName, var: resource_name}]
    header: [{name: headers, var: headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}, {name: identity, var: identity}, {name: location, var: location}, {name: name, var: name}, {name: properties, var: properties}, {name: provisioningState, var: provisioning_state}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group: $resource_group, provider_namespace: $provider_namespace, resource_name: $resource_name, headers: $headers, id: $id, identity: $identity, location: $location, name: $name, properties: $properties, provisioning_state: $provisioning_state, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/v1/Tokens/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/{providerNamespace}/plans/{resourceName}/deleteAllCodespaces
export def "post-api-v1-tokens-subscriptions-subscription-id-resource-groups-resource-group-providers-provider-namespace-plans-resource-name-delete-all-codespaces" [
  subscription_id: string
  resource_group: string
  provider_namespace: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expiration: string # format: date-time
]: nothing -> any {
  http-request {
    method: post
    path: "/api/v1/Tokens/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/{providerNamespace}/plans/{resourceName}/deleteAllCodespaces"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroup, var: resource_group}, {name: providerNamespace, var: provider_namespace}, {name: resourceName, var: resource_name}]
    query: [{name: expiration, var: expiration}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group: $resource_group, provider_namespace: $provider_namespace, resource_name: $resource_name, expiration: $expiration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/v1/Tokens/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/{providerNamespace}/plans/{resourceName}/deleteAllEnvironments
export def "post-api-v1-tokens-subscriptions-subscription-id-resource-groups-resource-group-providers-provider-namespace-plans-resource-name-delete-all-environments" [
  subscription_id: string
  resource_group: string
  provider_namespace: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expiration: string # format: date-time
]: nothing -> any {
  http-request {
    method: post
    path: "/api/v1/Tokens/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/{providerNamespace}/plans/{resourceName}/deleteAllEnvironments"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroup, var: resource_group}, {name: providerNamespace, var: provider_namespace}, {name: resourceName, var: resource_name}]
    query: [{name: expiration, var: expiration}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group: $resource_group, provider_namespace: $provider_namespace, resource_name: $resource_name, expiration: $expiration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/v1/Tokens/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/{providerNamespace}/plans/{resourceName}/readAllCodespaces
export def "post-api-v1-tokens-subscriptions-subscription-id-resource-groups-resource-group-providers-provider-namespace-plans-resource-name-read-all-codespaces" [
  subscription_id: string
  resource_group: string
  provider_namespace: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expiration: string # format: date-time
]: nothing -> any {
  http-request {
    method: post
    path: "/api/v1/Tokens/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/{providerNamespace}/plans/{resourceName}/readAllCodespaces"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroup, var: resource_group}, {name: providerNamespace, var: provider_namespace}, {name: resourceName, var: resource_name}]
    query: [{name: expiration, var: expiration}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group: $resource_group, provider_namespace: $provider_namespace, resource_name: $resource_name, expiration: $expiration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/v1/Tokens/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/{providerNamespace}/plans/{resourceName}/readAllEnvironments
export def "post-api-v1-tokens-subscriptions-subscription-id-resource-groups-resource-group-providers-provider-namespace-plans-resource-name-read-all-environments" [
  subscription_id: string
  resource_group: string
  provider_namespace: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expiration: string # format: date-time
]: nothing -> any {
  http-request {
    method: post
    path: "/api/v1/Tokens/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/{providerNamespace}/plans/{resourceName}/readAllEnvironments"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroup, var: resource_group}, {name: providerNamespace, var: provider_namespace}, {name: resourceName, var: resource_name}]
    query: [{name: expiration, var: expiration}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group: $resource_group, provider_namespace: $provider_namespace, resource_name: $resource_name, expiration: $expiration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/v1/Tokens/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/{providerNamespace}/plans/{resourceName}/writeCodespaces
export def "post-api-v1-tokens-subscriptions-subscription-id-resource-groups-resource-group-providers-provider-namespace-plans-resource-name-write-codespaces" [
  subscription_id: string
  resource_group: string
  provider_namespace: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expiration: string # format: date-time
]: nothing -> any {
  http-request {
    method: post
    path: "/api/v1/Tokens/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/{providerNamespace}/plans/{resourceName}/writeCodespaces"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroup, var: resource_group}, {name: providerNamespace, var: provider_namespace}, {name: resourceName, var: resource_name}]
    query: [{name: expiration, var: expiration}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group: $resource_group, provider_namespace: $provider_namespace, resource_name: $resource_name, expiration: $expiration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/v1/Tokens/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/{providerNamespace}/plans/{resourceName}/writeDelegates
export def "post-api-v1-tokens-subscriptions-subscription-id-resource-groups-resource-group-providers-provider-namespace-plans-resource-name-write-delegates" [
  subscription_id: string
  resource_group: string
  provider_namespace: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --environment-ids: list<string> # nullable
  --expiration: string # nullable, format: date-time
  --identity: record # shape: {displayName?: string, id?: string, username?: string}
  --port-numbers: list<int> # nullable
  --scope: string # nullable
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/Tokens/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/{providerNamespace}/plans/{resourceName}/writeDelegates"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroup, var: resource_group}, {name: providerNamespace, var: provider_namespace}, {name: resourceName, var: resource_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: environmentIds, var: environment_ids}, {name: expiration, var: expiration}, {name: identity, var: identity}, {name: portNumbers, var: port_numbers}, {name: scope, var: scope}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group: $resource_group, provider_namespace: $provider_namespace, resource_name: $resource_name, environment_ids: $environment_ids, expiration: $expiration, identity: $identity, port_numbers: $port_numbers, scope: $scope
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/v1/Tokens/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/{providerNamespace}/plans/{resourceName}/writeEnvironments
export def "post-api-v1-tokens-subscriptions-subscription-id-resource-groups-resource-group-providers-provider-namespace-plans-resource-name-write-environments" [
  subscription_id: string
  resource_group: string
  provider_namespace: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expiration: string # format: date-time
]: nothing -> any {
  http-request {
    method: post
    path: "/api/v1/Tokens/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/{providerNamespace}/plans/{resourceName}/writeEnvironments"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroup, var: resource_group}, {name: providerNamespace, var: provider_namespace}, {name: resourceName, var: resource_name}]
    query: [{name: expiration, var: expiration}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group: $resource_group, provider_namespace: $provider_namespace, resource_name: $resource_name, expiration: $expiration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /api/v1/Tunnel/{environmentId}/portInfo
#
# Returns: record<portVisibility: string, tunnelToken: string>
export def "get-api-v1-tunnel-environment-id-port-info" [
  environment_id: string
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
  --port-number: int # format: int32
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/Tunnel/{environmentId}/portInfo"
    path_params: [{name: environmentId, var: environment_id}]
    query: [{name: portNumber, var: port_number}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    environment_id: $environment_id, port_number: $port_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# DELETE /api/v1/UserSubscriptions
export def "delete-api-v1-user-subscriptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/v1/UserSubscriptions"
    query: [{name: email, var: email}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    email: $email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/v1/UserSubscriptions
export def "post-api-v1-user-subscriptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string
]: nothing -> any {
  http-request {
    method: post
    path: "/api/v1/UserSubscriptions"
    query: [{name: email, var: email}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    email: $email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /api/v1/pools/default
#
# Returns: table<allWithLatestVersion: bool, isEnvironmentPool: bool, location: string, poolCode: string, readyUnassignedCount: int, readyUnassignedLatestVersionCount: int, readyUnassignedNotLatestVersionAndIdleCount: int, readyUnassignedNotLatestVersionCount: int, resourceType: string, sku: string>
export def "get-api-v1-pools-default" [
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
  --sku-name: list<string>
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/pools/default"
    query: [{name: skuName, var: sku_name, style: multi}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    sku_name: $sku_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# PUT /api/v1/subscriptions/{subscriptionId}/providers/GitHub.Network/{resourceType}/SubscriptionLifeCycleNotification
export def "put-api-v1-subscriptions-subscription-id-providers-git-hub-network-resource-type-subscription-life-cycle-notification" [
  subscription_id: string
  resource_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --properties: record # shape: {accountOwner?: record, additionalProperties?: record, locationPlacementId?: string, managedByTenants?: list, quotaId?: string, registeredFeatures?: list, tenantId?: string}
  --registration-date: string # format: date-time
  --state: string # nullable
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v1/subscriptions/{subscriptionId}/providers/GitHub.Network/{resourceType}/SubscriptionLifeCycleNotification"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceType, var: resource_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: registrationDate, var: registration_date}, {name: state, var: state}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_type: $resource_type, properties: $properties, registration_date: $registration_date, state: $state
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/v1/subscriptions/{subscriptionId}/providers/GitHub.Network/{resourceType}/resourceReadBegin
export def "post-api-v1-subscriptions-subscription-id-providers-git-hub-network-resource-type-resource-read-begin" [
  subscription_id: string
  resource_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: list # nullable — item shape: {id?: string, location?: string, name?: string, properties?: record, provisioningState?: string, tags?: record, type?: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/subscriptions/{subscriptionId}/providers/GitHub.Network/{resourceType}/resourceReadBegin"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceType, var: resource_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_type: $resource_type, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /api/v1/subscriptions/{subscriptionId}/providers/Microsoft.Codespaces/plans/SubscriptionLifeCycleNotification
export def "put-api-v1-subscriptions-subscription-id-providers-microsoft-codespaces-plans-subscription-life-cycle-notification" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --properties: record # shape: {accountOwner?: record, additionalProperties?: record, locationPlacementId?: string, managedByTenants?: list, quotaId?: string, registeredFeatures?: list, tenantId?: string}
  --registration-date: string # format: date-time
  --state: string # nullable
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v1/subscriptions/{subscriptionId}/providers/Microsoft.Codespaces/plans/SubscriptionLifeCycleNotification"
    path_params: [{name: subscriptionId, var: subscription_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: registrationDate, var: registration_date}, {name: state, var: state}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, properties: $properties, registration_date: $registration_date, state: $state
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/v1/subscriptions/{subscriptionId}/providers/Microsoft.Codespaces/plans/resourceReadBegin
export def "post-api-v1-subscriptions-subscription-id-providers-microsoft-codespaces-plans-resource-read-begin" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: list # nullable — item shape: {id?: string, identity?: record, location?: string, name?: string, properties?: record, provisioningState?: string, tags?: record, type?: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/subscriptions/{subscriptionId}/providers/Microsoft.Codespaces/plans/resourceReadBegin"
    path_params: [{name: subscriptionId, var: subscription_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /api/v1/subscriptions/{subscriptionId}/providers/Microsoft.VSOnline/plans/SubscriptionLifeCycleNotification
export def "put-api-v1-subscriptions-subscription-id-providers-microsoft-vs-online-plans-subscription-life-cycle-notification" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --properties: record # shape: {accountOwner?: record, additionalProperties?: record, locationPlacementId?: string, managedByTenants?: list, quotaId?: string, registeredFeatures?: list, tenantId?: string}
  --registration-date: string # format: date-time
  --state: string # nullable
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v1/subscriptions/{subscriptionId}/providers/Microsoft.VSOnline/plans/SubscriptionLifeCycleNotification"
    path_params: [{name: subscriptionId, var: subscription_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: registrationDate, var: registration_date}, {name: state, var: state}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, properties: $properties, registration_date: $registration_date, state: $state
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/v1/subscriptions/{subscriptionId}/providers/Microsoft.VSOnline/plans/resourceReadBegin
export def "post-api-v1-subscriptions-subscription-id-providers-microsoft-vs-online-plans-resource-read-begin" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: list # nullable — item shape: {id?: string, identity?: record, location?: string, name?: string, properties?: record, provisioningState?: string, tags?: record, type?: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/subscriptions/{subscriptionId}/providers/Microsoft.VSOnline/plans/resourceReadBegin"
    path_params: [{name: subscriptionId, var: subscription_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/GitHub.Network/{resourceType}/resourceReadBegin
export def "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-git-hub-network-resource-type-resource-read-begin" [
  subscription_id: string
  resource_group: string
  resource_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: list # nullable — item shape: {id?: string, location?: string, name?: string, properties?: record, provisioningState?: string, tags?: record, type?: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/GitHub.Network/{resourceType}/resourceReadBegin"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroup, var: resource_group}, {name: resourceType, var: resource_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group: $resource_group, resource_type: $resource_type, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/GitHub.Network/{resourceType}/{resourceName}
export def "delete-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-git-hub-network-resource-type-resource-name" [
  subscription_id: string
  resource_group: string
  resource_type: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # nullable
  --location: string # nullable
  --name: string # nullable
  --properties: record # shape: {subnetId?: string}
  --provisioning-state: string # nullable
  --tags: record # nullable
  --type: string # nullable
]: any -> any {
  $in | http-request {
    method: delete
    path: "/api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/GitHub.Network/{resourceType}/{resourceName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroup, var: resource_group}, {name: resourceType, var: resource_type}, {name: resourceName, var: resource_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}, {name: location, var: location}, {name: name, var: name}, {name: properties, var: properties}, {name: provisioningState, var: provisioning_state}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group: $resource_group, resource_type: $resource_type, resource_name: $resource_name, id: $id, location: $location, name: $name, properties: $properties, provisioning_state: $provisioning_state, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PATCH /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/GitHub.Network/{resourceType}/{resourceName}
export def "patch-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-git-hub-network-resource-type-resource-name" [
  subscription_id: string
  resource_group: string
  resource_type: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # nullable
  --location: string # nullable
  --name: string # nullable
  --properties: record # shape: {subnetId?: string}
  --provisioning-state: string # nullable
  --tags: record # nullable
  --type: string # nullable
]: any -> any {
  $in | http-request {
    method: patch
    path: "/api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/GitHub.Network/{resourceType}/{resourceName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroup, var: resource_group}, {name: resourceType, var: resource_type}, {name: resourceName, var: resource_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}, {name: location, var: location}, {name: name, var: name}, {name: properties, var: properties}, {name: provisioningState, var: provisioning_state}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group: $resource_group, resource_type: $resource_type, resource_name: $resource_name, id: $id, location: $location, name: $name, properties: $properties, provisioning_state: $provisioning_state, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/GitHub.Network/{resourceType}/{resourceName}
export def "put-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-git-hub-network-resource-type-resource-name" [
  subscription_id: string
  resource_group: string
  resource_type: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # nullable
  --location: string # nullable
  --name: string # nullable
  --properties: record # shape: {subnetId?: string}
  --provisioning-state: string # nullable
  --tags: record # nullable
  --type: string # nullable
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/GitHub.Network/{resourceType}/{resourceName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroup, var: resource_group}, {name: resourceType, var: resource_type}, {name: resourceName, var: resource_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}, {name: location, var: location}, {name: name, var: name}, {name: properties, var: properties}, {name: provisioningState, var: provisioning_state}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group: $resource_group, resource_type: $resource_type, resource_name: $resource_name, id: $id, location: $location, name: $name, properties: $properties, provisioning_state: $provisioning_state, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/GitHub.Network/{resourceType}/{resourceName}/resourceCreationCompleted
export def "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-git-hub-network-resource-type-resource-name-resource-creation-completed" [
  subscription_id: string
  resource_group: string
  resource_type: string
  resource_name: string
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
    path: "/api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/GitHub.Network/{resourceType}/{resourceName}/resourceCreationCompleted"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroup, var: resource_group}, {name: resourceType, var: resource_type}, {name: resourceName, var: resource_name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group: $resource_group, resource_type: $resource_type, resource_name: $resource_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/GitHub.Network/{resourceType}/{resourceName}/resourceCreationValidate
export def "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-git-hub-network-resource-type-resource-name-resource-creation-validate" [
  subscription_id: string
  resource_group: string
  resource_type: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # nullable
  --location: string # nullable
  --name: string # nullable
  --properties: record # shape: {subnetId?: string}
  --provisioning-state: string # nullable
  --tags: record # nullable
  --type: string # nullable
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/GitHub.Network/{resourceType}/{resourceName}/resourceCreationValidate"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroup, var: resource_group}, {name: resourceType, var: resource_type}, {name: resourceName, var: resource_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}, {name: location, var: location}, {name: name, var: name}, {name: properties, var: properties}, {name: provisioningState, var: provisioning_state}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group: $resource_group, resource_type: $resource_type, resource_name: $resource_name, id: $id, location: $location, name: $name, properties: $properties, provisioning_state: $provisioning_state, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/GitHub.Network/{resourceType}/{resourceName}/resourceDeletionCompleted
export def "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-git-hub-network-resource-type-resource-name-resource-deletion-completed" [
  subscription_id: string
  resource_group: string
  resource_type: string
  resource_name: string
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
    path: "/api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/GitHub.Network/{resourceType}/{resourceName}/resourceDeletionCompleted"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroup, var: resource_group}, {name: resourceType, var: resource_type}, {name: resourceName, var: resource_name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group: $resource_group, resource_type: $resource_type, resource_name: $resource_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/GitHub.Network/{resourceType}/{resourceName}/resourceDeletionValidate
export def "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-git-hub-network-resource-type-resource-name-resource-deletion-validate" [
  subscription_id: string
  resource_group: string
  resource_type: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # nullable
  --location: string # nullable
  --name: string # nullable
  --properties: record # shape: {subnetId?: string}
  --provisioning-state: string # nullable
  --tags: record # nullable
  --type: string # nullable
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/GitHub.Network/{resourceType}/{resourceName}/resourceDeletionValidate"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroup, var: resource_group}, {name: resourceType, var: resource_type}, {name: resourceName, var: resource_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}, {name: location, var: location}, {name: name, var: name}, {name: properties, var: properties}, {name: provisioningState, var: provisioning_state}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group: $resource_group, resource_type: $resource_type, resource_name: $resource_name, id: $id, location: $location, name: $name, properties: $properties, provisioning_state: $provisioning_state, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/GitHub.Network/{resourceType}/{resourceName}/resourcePatchCompleted
export def "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-git-hub-network-resource-type-resource-name-resource-patch-completed" [
  subscription_id: string
  resource_group: string
  resource_type: string
  resource_name: string
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
    path: "/api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/GitHub.Network/{resourceType}/{resourceName}/resourcePatchCompleted"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroup, var: resource_group}, {name: resourceType, var: resource_type}, {name: resourceName, var: resource_name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group: $resource_group, resource_type: $resource_type, resource_name: $resource_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/GitHub.Network/{resourceType}/{resourceName}/resourcePatchValidate
export def "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-git-hub-network-resource-type-resource-name-resource-patch-validate" [
  subscription_id: string
  resource_group: string
  resource_type: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # nullable
  --location: string # nullable
  --name: string # nullable
  --properties: record # shape: {subnetId?: string}
  --provisioning-state: string # nullable
  --tags: record # nullable
  --type: string # nullable
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/GitHub.Network/{resourceType}/{resourceName}/resourcePatchValidate"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroup, var: resource_group}, {name: resourceType, var: resource_type}, {name: resourceName, var: resource_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}, {name: location, var: location}, {name: name, var: name}, {name: properties, var: properties}, {name: provisioningState, var: provisioning_state}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group: $resource_group, resource_type: $resource_type, resource_name: $resource_name, id: $id, location: $location, name: $name, properties: $properties, provisioning_state: $provisioning_state, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/GitHub.Network/{resourceType}/{resourceName}/resourceReadBegin
export def "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-git-hub-network-resource-type-resource-name-resource-read-begin" [
  subscription_id: string
  resource_group: string
  resource_type: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # nullable
  --location: string # nullable
  --name: string # nullable
  --properties: record # shape: {subnetId?: string}
  --provisioning-state: string # nullable
  --tags: record # nullable
  --type: string # nullable
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/GitHub.Network/{resourceType}/{resourceName}/resourceReadBegin"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroup, var: resource_group}, {name: resourceType, var: resource_type}, {name: resourceName, var: resource_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}, {name: location, var: location}, {name: name, var: name}, {name: properties, var: properties}, {name: provisioningState, var: provisioning_state}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group: $resource_group, resource_type: $resource_type, resource_name: $resource_name, id: $id, location: $location, name: $name, properties: $properties, provisioning_state: $provisioning_state, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Codespaces/plans/resourceReadBegin
export def "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-microsoft-codespaces-plans-resource-read-begin" [
  subscription_id: string
  resource_group: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: list # nullable — item shape: {id?: string, identity?: record, location?: string, name?: string, properties?: record, provisioningState?: string, tags?: record, type?: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Codespaces/plans/resourceReadBegin"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroup, var: resource_group}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group: $resource_group, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Codespaces/plans/{resourceName}
export def "put-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-microsoft-codespaces-plans-resource-name" [
  subscription_id: string
  resource_group: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --headers: record
  --id: string # nullable
  --identity: record # shape: {principalId?: string, tenantId?: string, type?: string}
  --location: string # nullable
  --name: string # nullable
  --properties: record # shape: {defaultCodespaceSku?: string, defaultEnvironmentSku?: string, encryption?: record, userId?: string, vnetProperties?: record}
  --provisioning-state: string # nullable
  --tags: record # nullable
  --type: string # nullable
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Codespaces/plans/{resourceName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroup, var: resource_group}, {name: resourceName, var: resource_name}]
    header: [{name: headers, var: headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}, {name: identity, var: identity}, {name: location, var: location}, {name: name, var: name}, {name: properties, var: properties}, {name: provisioningState, var: provisioning_state}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group: $resource_group, resource_name: $resource_name, headers: $headers, id: $id, identity: $identity, location: $location, name: $name, properties: $properties, provisioning_state: $provisioning_state, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Codespaces/plans/{resourceName}/deleteAllCodespaces
export def "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-microsoft-codespaces-plans-resource-name-delete-all-codespaces" [
  subscription_id: string
  resource_group: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expiration: string # format: date-time
]: nothing -> any {
  http-request {
    method: post
    path: "/api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Codespaces/plans/{resourceName}/deleteAllCodespaces"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroup, var: resource_group}, {name: resourceName, var: resource_name}]
    query: [{name: expiration, var: expiration}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group: $resource_group, resource_name: $resource_name, expiration: $expiration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Codespaces/plans/{resourceName}/deleteAllEnvironments
export def "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-microsoft-codespaces-plans-resource-name-delete-all-environments" [
  subscription_id: string
  resource_group: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expiration: string # format: date-time
]: nothing -> any {
  http-request {
    method: post
    path: "/api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Codespaces/plans/{resourceName}/deleteAllEnvironments"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroup, var: resource_group}, {name: resourceName, var: resource_name}]
    query: [{name: expiration, var: expiration}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group: $resource_group, resource_name: $resource_name, expiration: $expiration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Codespaces/plans/{resourceName}/readAllCodespaces
export def "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-microsoft-codespaces-plans-resource-name-read-all-codespaces" [
  subscription_id: string
  resource_group: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expiration: string # format: date-time
]: nothing -> any {
  http-request {
    method: post
    path: "/api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Codespaces/plans/{resourceName}/readAllCodespaces"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroup, var: resource_group}, {name: resourceName, var: resource_name}]
    query: [{name: expiration, var: expiration}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group: $resource_group, resource_name: $resource_name, expiration: $expiration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Codespaces/plans/{resourceName}/readAllEnvironments
export def "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-microsoft-codespaces-plans-resource-name-read-all-environments" [
  subscription_id: string
  resource_group: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expiration: string # format: date-time
]: nothing -> any {
  http-request {
    method: post
    path: "/api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Codespaces/plans/{resourceName}/readAllEnvironments"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroup, var: resource_group}, {name: resourceName, var: resource_name}]
    query: [{name: expiration, var: expiration}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group: $resource_group, resource_name: $resource_name, expiration: $expiration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Codespaces/plans/{resourceName}/readDelegates
export def "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-microsoft-codespaces-plans-resource-name-read-delegates" [
  subscription_id: string
  resource_group: string
  resource_name: string
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
    path: "/api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Codespaces/plans/{resourceName}/readDelegates"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroup, var: resource_group}, {name: resourceName, var: resource_name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group: $resource_group, resource_name: $resource_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Codespaces/plans/{resourceName}/resourceCreationCompleted
export def "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-microsoft-codespaces-plans-resource-name-resource-creation-completed" [
  subscription_id: string
  resource_group: string
  resource_name: string
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
    path: "/api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Codespaces/plans/{resourceName}/resourceCreationCompleted"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroup, var: resource_group}, {name: resourceName, var: resource_name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group: $resource_group, resource_name: $resource_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Codespaces/plans/{resourceName}/resourceCreationValidate
export def "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-microsoft-codespaces-plans-resource-name-resource-creation-validate" [
  subscription_id: string
  resource_group: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # nullable
  --identity: record # shape: {principalId?: string, tenantId?: string, type?: string}
  --location: string # nullable
  --name: string # nullable
  --properties: record # shape: {defaultCodespaceSku?: string, defaultEnvironmentSku?: string, encryption?: record, userId?: string, vnetProperties?: record}
  --provisioning-state: string # nullable
  --tags: record # nullable
  --type: string # nullable
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Codespaces/plans/{resourceName}/resourceCreationValidate"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroup, var: resource_group}, {name: resourceName, var: resource_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}, {name: identity, var: identity}, {name: location, var: location}, {name: name, var: name}, {name: properties, var: properties}, {name: provisioningState, var: provisioning_state}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group: $resource_group, resource_name: $resource_name, id: $id, identity: $identity, location: $location, name: $name, properties: $properties, provisioning_state: $provisioning_state, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Codespaces/plans/{resourceName}/resourceDeletionValidate
export def "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-microsoft-codespaces-plans-resource-name-resource-deletion-validate" [
  subscription_id: string
  resource_group: string
  resource_name: string
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
    path: "/api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Codespaces/plans/{resourceName}/resourceDeletionValidate"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroup, var: resource_group}, {name: resourceName, var: resource_name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group: $resource_group, resource_name: $resource_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Codespaces/plans/{resourceName}/resourcePatchCompleted
export def "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-microsoft-codespaces-plans-resource-name-resource-patch-completed" [
  subscription_id: string
  resource_group: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --headers: record
  --identity: record # shape: {principalId?: string, tenantId?: string, type?: string}
  --properties: record # shape: {defaultCodespaceSku?: string, defaultEnvironmentSku?: string, encryption?: record, userId?: string, vnetProperties?: record}
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Codespaces/plans/{resourceName}/resourcePatchCompleted"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroup, var: resource_group}, {name: resourceName, var: resource_name}]
    header: [{name: headers, var: headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: identity, var: identity}, {name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group: $resource_group, resource_name: $resource_name, headers: $headers, identity: $identity, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Codespaces/plans/{resourceName}/resourcePatchValidate
export def "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-microsoft-codespaces-plans-resource-name-resource-patch-validate" [
  subscription_id: string
  resource_group: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --identity: record # shape: {principalId?: string, tenantId?: string, type?: string}
  --properties: record # shape: {defaultCodespaceSku?: string, defaultEnvironmentSku?: string, encryption?: record, userId?: string, vnetProperties?: record}
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Codespaces/plans/{resourceName}/resourcePatchValidate"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroup, var: resource_group}, {name: resourceName, var: resource_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: identity, var: identity}, {name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group: $resource_group, resource_name: $resource_name, identity: $identity, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Codespaces/plans/{resourceName}/resourceReadBegin
export def "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-microsoft-codespaces-plans-resource-name-resource-read-begin" [
  subscription_id: string
  resource_group: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # nullable
  --identity: record # shape: {principalId?: string, tenantId?: string, type?: string}
  --location: string # nullable
  --name: string # nullable
  --properties: record # shape: {defaultCodespaceSku?: string, defaultEnvironmentSku?: string, encryption?: record, userId?: string, vnetProperties?: record}
  --provisioning-state: string # nullable
  --tags: record # nullable
  --type: string # nullable
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Codespaces/plans/{resourceName}/resourceReadBegin"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroup, var: resource_group}, {name: resourceName, var: resource_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}, {name: identity, var: identity}, {name: location, var: location}, {name: name, var: name}, {name: properties, var: properties}, {name: provisioningState, var: provisioning_state}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group: $resource_group, resource_name: $resource_name, id: $id, identity: $identity, location: $location, name: $name, properties: $properties, provisioning_state: $provisioning_state, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Codespaces/plans/{resourceName}/writeCodespaces
export def "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-microsoft-codespaces-plans-resource-name-write-codespaces" [
  subscription_id: string
  resource_group: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expiration: string # format: date-time
]: nothing -> any {
  http-request {
    method: post
    path: "/api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Codespaces/plans/{resourceName}/writeCodespaces"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroup, var: resource_group}, {name: resourceName, var: resource_name}]
    query: [{name: expiration, var: expiration}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group: $resource_group, resource_name: $resource_name, expiration: $expiration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Codespaces/plans/{resourceName}/writeDelegates
export def "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-microsoft-codespaces-plans-resource-name-write-delegates" [
  subscription_id: string
  resource_group: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --environment-ids: list<string> # nullable
  --expiration: string # nullable, format: date-time
  --identity: record # shape: {displayName?: string, id?: string, username?: string}
  --port-numbers: list<int> # nullable
  --scope: string # nullable
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Codespaces/plans/{resourceName}/writeDelegates"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroup, var: resource_group}, {name: resourceName, var: resource_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: environmentIds, var: environment_ids}, {name: expiration, var: expiration}, {name: identity, var: identity}, {name: portNumbers, var: port_numbers}, {name: scope, var: scope}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group: $resource_group, resource_name: $resource_name, environment_ids: $environment_ids, expiration: $expiration, identity: $identity, port_numbers: $port_numbers, scope: $scope
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Codespaces/plans/{resourceName}/writeEnvironments
export def "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-microsoft-codespaces-plans-resource-name-write-environments" [
  subscription_id: string
  resource_group: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expiration: string # format: date-time
]: nothing -> any {
  http-request {
    method: post
    path: "/api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Codespaces/plans/{resourceName}/writeEnvironments"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroup, var: resource_group}, {name: resourceName, var: resource_name}]
    query: [{name: expiration, var: expiration}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group: $resource_group, resource_name: $resource_name, expiration: $expiration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.VSOnline/plans/resourceReadBegin
export def "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-microsoft-vs-online-plans-resource-read-begin" [
  subscription_id: string
  resource_group: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: list # nullable — item shape: {id?: string, identity?: record, location?: string, name?: string, properties?: record, provisioningState?: string, tags?: record, type?: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.VSOnline/plans/resourceReadBegin"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroup, var: resource_group}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group: $resource_group, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.VSOnline/plans/{resourceName}
export def "put-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-microsoft-vs-online-plans-resource-name" [
  subscription_id: string
  resource_group: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --headers: record
  --id: string # nullable
  --identity: record # shape: {principalId?: string, tenantId?: string, type?: string}
  --location: string # nullable
  --name: string # nullable
  --properties: record # shape: {defaultCodespaceSku?: string, defaultEnvironmentSku?: string, encryption?: record, userId?: string, vnetProperties?: record}
  --provisioning-state: string # nullable
  --tags: record # nullable
  --type: string # nullable
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.VSOnline/plans/{resourceName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroup, var: resource_group}, {name: resourceName, var: resource_name}]
    header: [{name: headers, var: headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}, {name: identity, var: identity}, {name: location, var: location}, {name: name, var: name}, {name: properties, var: properties}, {name: provisioningState, var: provisioning_state}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group: $resource_group, resource_name: $resource_name, headers: $headers, id: $id, identity: $identity, location: $location, name: $name, properties: $properties, provisioning_state: $provisioning_state, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.VSOnline/plans/{resourceName}/deleteAllCodespaces
export def "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-microsoft-vs-online-plans-resource-name-delete-all-codespaces" [
  subscription_id: string
  resource_group: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expiration: string # format: date-time
]: nothing -> any {
  http-request {
    method: post
    path: "/api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.VSOnline/plans/{resourceName}/deleteAllCodespaces"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroup, var: resource_group}, {name: resourceName, var: resource_name}]
    query: [{name: expiration, var: expiration}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group: $resource_group, resource_name: $resource_name, expiration: $expiration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.VSOnline/plans/{resourceName}/deleteAllEnvironments
export def "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-microsoft-vs-online-plans-resource-name-delete-all-environments" [
  subscription_id: string
  resource_group: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expiration: string # format: date-time
]: nothing -> any {
  http-request {
    method: post
    path: "/api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.VSOnline/plans/{resourceName}/deleteAllEnvironments"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroup, var: resource_group}, {name: resourceName, var: resource_name}]
    query: [{name: expiration, var: expiration}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group: $resource_group, resource_name: $resource_name, expiration: $expiration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.VSOnline/plans/{resourceName}/readAllCodespaces
export def "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-microsoft-vs-online-plans-resource-name-read-all-codespaces" [
  subscription_id: string
  resource_group: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expiration: string # format: date-time
]: nothing -> any {
  http-request {
    method: post
    path: "/api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.VSOnline/plans/{resourceName}/readAllCodespaces"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroup, var: resource_group}, {name: resourceName, var: resource_name}]
    query: [{name: expiration, var: expiration}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group: $resource_group, resource_name: $resource_name, expiration: $expiration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.VSOnline/plans/{resourceName}/readAllEnvironments
export def "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-microsoft-vs-online-plans-resource-name-read-all-environments" [
  subscription_id: string
  resource_group: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expiration: string # format: date-time
]: nothing -> any {
  http-request {
    method: post
    path: "/api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.VSOnline/plans/{resourceName}/readAllEnvironments"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroup, var: resource_group}, {name: resourceName, var: resource_name}]
    query: [{name: expiration, var: expiration}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group: $resource_group, resource_name: $resource_name, expiration: $expiration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.VSOnline/plans/{resourceName}/readDelegates
export def "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-microsoft-vs-online-plans-resource-name-read-delegates" [
  subscription_id: string
  resource_group: string
  resource_name: string
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
    path: "/api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.VSOnline/plans/{resourceName}/readDelegates"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroup, var: resource_group}, {name: resourceName, var: resource_name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group: $resource_group, resource_name: $resource_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.VSOnline/plans/{resourceName}/resourceCreationCompleted
export def "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-microsoft-vs-online-plans-resource-name-resource-creation-completed" [
  subscription_id: string
  resource_group: string
  resource_name: string
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
    path: "/api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.VSOnline/plans/{resourceName}/resourceCreationCompleted"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroup, var: resource_group}, {name: resourceName, var: resource_name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group: $resource_group, resource_name: $resource_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.VSOnline/plans/{resourceName}/resourceCreationValidate
export def "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-microsoft-vs-online-plans-resource-name-resource-creation-validate" [
  subscription_id: string
  resource_group: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # nullable
  --identity: record # shape: {principalId?: string, tenantId?: string, type?: string}
  --location: string # nullable
  --name: string # nullable
  --properties: record # shape: {defaultCodespaceSku?: string, defaultEnvironmentSku?: string, encryption?: record, userId?: string, vnetProperties?: record}
  --provisioning-state: string # nullable
  --tags: record # nullable
  --type: string # nullable
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.VSOnline/plans/{resourceName}/resourceCreationValidate"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroup, var: resource_group}, {name: resourceName, var: resource_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}, {name: identity, var: identity}, {name: location, var: location}, {name: name, var: name}, {name: properties, var: properties}, {name: provisioningState, var: provisioning_state}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group: $resource_group, resource_name: $resource_name, id: $id, identity: $identity, location: $location, name: $name, properties: $properties, provisioning_state: $provisioning_state, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.VSOnline/plans/{resourceName}/resourceDeletionValidate
export def "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-microsoft-vs-online-plans-resource-name-resource-deletion-validate" [
  subscription_id: string
  resource_group: string
  resource_name: string
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
    path: "/api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.VSOnline/plans/{resourceName}/resourceDeletionValidate"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroup, var: resource_group}, {name: resourceName, var: resource_name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group: $resource_group, resource_name: $resource_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.VSOnline/plans/{resourceName}/resourcePatchCompleted
export def "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-microsoft-vs-online-plans-resource-name-resource-patch-completed" [
  subscription_id: string
  resource_group: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --headers: record
  --identity: record # shape: {principalId?: string, tenantId?: string, type?: string}
  --properties: record # shape: {defaultCodespaceSku?: string, defaultEnvironmentSku?: string, encryption?: record, userId?: string, vnetProperties?: record}
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.VSOnline/plans/{resourceName}/resourcePatchCompleted"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroup, var: resource_group}, {name: resourceName, var: resource_name}]
    header: [{name: headers, var: headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: identity, var: identity}, {name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group: $resource_group, resource_name: $resource_name, headers: $headers, identity: $identity, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.VSOnline/plans/{resourceName}/resourcePatchValidate
export def "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-microsoft-vs-online-plans-resource-name-resource-patch-validate" [
  subscription_id: string
  resource_group: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --identity: record # shape: {principalId?: string, tenantId?: string, type?: string}
  --properties: record # shape: {defaultCodespaceSku?: string, defaultEnvironmentSku?: string, encryption?: record, userId?: string, vnetProperties?: record}
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.VSOnline/plans/{resourceName}/resourcePatchValidate"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroup, var: resource_group}, {name: resourceName, var: resource_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: identity, var: identity}, {name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group: $resource_group, resource_name: $resource_name, identity: $identity, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.VSOnline/plans/{resourceName}/resourceReadBegin
export def "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-microsoft-vs-online-plans-resource-name-resource-read-begin" [
  subscription_id: string
  resource_group: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # nullable
  --identity: record # shape: {principalId?: string, tenantId?: string, type?: string}
  --location: string # nullable
  --name: string # nullable
  --properties: record # shape: {defaultCodespaceSku?: string, defaultEnvironmentSku?: string, encryption?: record, userId?: string, vnetProperties?: record}
  --provisioning-state: string # nullable
  --tags: record # nullable
  --type: string # nullable
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.VSOnline/plans/{resourceName}/resourceReadBegin"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroup, var: resource_group}, {name: resourceName, var: resource_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}, {name: identity, var: identity}, {name: location, var: location}, {name: name, var: name}, {name: properties, var: properties}, {name: provisioningState, var: provisioning_state}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group: $resource_group, resource_name: $resource_name, id: $id, identity: $identity, location: $location, name: $name, properties: $properties, provisioning_state: $provisioning_state, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.VSOnline/plans/{resourceName}/writeCodespaces
export def "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-microsoft-vs-online-plans-resource-name-write-codespaces" [
  subscription_id: string
  resource_group: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expiration: string # format: date-time
]: nothing -> any {
  http-request {
    method: post
    path: "/api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.VSOnline/plans/{resourceName}/writeCodespaces"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroup, var: resource_group}, {name: resourceName, var: resource_name}]
    query: [{name: expiration, var: expiration}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group: $resource_group, resource_name: $resource_name, expiration: $expiration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.VSOnline/plans/{resourceName}/writeDelegates
export def "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-microsoft-vs-online-plans-resource-name-write-delegates" [
  subscription_id: string
  resource_group: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --environment-ids: list<string> # nullable
  --expiration: string # nullable, format: date-time
  --identity: record # shape: {displayName?: string, id?: string, username?: string}
  --port-numbers: list<int> # nullable
  --scope: string # nullable
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.VSOnline/plans/{resourceName}/writeDelegates"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroup, var: resource_group}, {name: resourceName, var: resource_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: environmentIds, var: environment_ids}, {name: expiration, var: expiration}, {name: identity, var: identity}, {name: portNumbers, var: port_numbers}, {name: scope, var: scope}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group: $resource_group, resource_name: $resource_name, environment_ids: $environment_ids, expiration: $expiration, identity: $identity, port_numbers: $port_numbers, scope: $scope
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.VSOnline/plans/{resourceName}/writeEnvironments
export def "post-api-v1-subscriptions-subscription-id-resource-groups-resource-group-providers-microsoft-vs-online-plans-resource-name-write-environments" [
  subscription_id: string
  resource_group: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expiration: string # format: date-time
]: nothing -> any {
  http-request {
    method: post
    path: "/api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.VSOnline/plans/{resourceName}/writeEnvironments"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroup, var: resource_group}, {name: resourceName, var: resource_name}]
    query: [{name: expiration, var: expiration}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group: $resource_group, resource_name: $resource_name, expiration: $expiration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/v1/subscriptions/{subscriptionId}/{resourceGroup}/providers/Microsoft.Codespaces/plans/{resourceName}/deleteDelegates
export def "post-api-v1-subscriptions-subscription-id-resource-group-providers-microsoft-codespaces-plans-resource-name-delete-delegates" [
  subscription_id: string
  resource_group: string
  resource_name: string
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
    path: "/api/v1/subscriptions/{subscriptionId}/{resourceGroup}/providers/Microsoft.Codespaces/plans/{resourceName}/deleteDelegates"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroup, var: resource_group}, {name: resourceName, var: resource_name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group: $resource_group, resource_name: $resource_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/v1/subscriptions/{subscriptionId}/{resourceGroup}/providers/Microsoft.VSOnline/plans/{resourceName}/deleteDelegates
export def "post-api-v1-subscriptions-subscription-id-resource-group-providers-microsoft-vs-online-plans-resource-name-delete-delegates" [
  subscription_id: string
  resource_group: string
  resource_name: string
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
    path: "/api/v1/subscriptions/{subscriptionId}/{resourceGroup}/providers/Microsoft.VSOnline/plans/{resourceName}/deleteDelegates"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroup, var: resource_group}, {name: resourceName, var: resource_name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group: $resource_group, resource_name: $resource_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /api/v1/tenant/{tenantId}/Pool/{poolName}
export def "delete-api-v1-tenant-tenant-id-pool-pool-name" [
  tenant_id: string
  pool_name: string
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
    path: "/api/v1/tenant/{tenantId}/Pool/{poolName}"
    path_params: [{name: tenantId, var: tenant_id}, {name: poolName, var: pool_name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tenant_id: $tenant_id, pool_name: $pool_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /api/v1/tenant/{tenantId}/Pool/{poolName}
#
# Returns: record<domainUserCredentials: record<domain: string, organizationalUnit: string, passwordSecretIdentifier: string, userName: string>, hotPoolSettings: record<size: int>, poolGroupName: string, provisioningStatus: record<completedSteps: int, currentStepDescription: string, isReady: bool, operationStartedTimeUtc: string, totalSteps: int>, tags: record, userGroupName: string, vmSpecs: record<diskType: int, imageResourceId: string, size: string, subnetResourceId: string>>
export def "get-api-v1-tenant-tenant-id-pool-pool-name" [
  tenant_id: string
  pool_name: string
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
    path: "/api/v1/tenant/{tenantId}/Pool/{poolName}"
    path_params: [{name: tenantId, var: tenant_id}, {name: poolName, var: pool_name}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    tenant_id: $tenant_id, pool_name: $pool_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# PATCH /api/v1/tenant/{tenantId}/Pool/{poolName}
#
# Returns: record<domainUserCredentials: record<domain: string, organizationalUnit: string, passwordSecretIdentifier: string, userName: string>, hotPoolSettings: record<size: int>, poolGroupName: string, provisioningStatus: record<completedSteps: int, currentStepDescription: string, isReady: bool, operationStartedTimeUtc: string, totalSteps: int>, tags: record, userGroupName: string, vmSpecs: record<diskType: int, imageResourceId: string, size: string, subnetResourceId: string>>
export def "patch-api-v1-tenant-tenant-id-pool-pool-name" [
  tenant_id: string
  pool_name: string
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
  --domain-user-credentials: record # shape: {domain: string, organizationalUnit?: string, passwordSecretIdentifier: string, userName: string}
  --hot-pool-settings: record # shape: {size?: int}
  pool_group_name: string
  --tags: record # nullable
  --user-group-name: string # nullable
  vm_specs: record # shape: {diskType: "0 (StandardHDD)"|"1 (StandardSSD)"|"2 (PremiumSSD)", imageResourceId: string, size: string, subnetResourceId: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/api/v1/tenant/{tenantId}/Pool/{poolName}"
    path_params: [{name: tenantId, var: tenant_id}, {name: poolName, var: pool_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: domainUserCredentials, var: domain_user_credentials}, {name: hotPoolSettings, var: hot_pool_settings}, {name: poolGroupName, var: pool_group_name}, {name: tags, var: tags}, {name: userGroupName, var: user_group_name}, {name: vmSpecs, var: vm_specs}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    tenant_id: $tenant_id, pool_name: $pool_name, domain_user_credentials: $domain_user_credentials, hot_pool_settings: $hot_pool_settings, pool_group_name: $pool_group_name, tags: $tags, user_group_name: $user_group_name, vm_specs: $vm_specs
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# PUT /api/v1/tenant/{tenantId}/Pool/{poolName}
#
# Returns: record<domainUserCredentials: record<domain: string, organizationalUnit: string, passwordSecretIdentifier: string, userName: string>, hotPoolSettings: record<size: int>, poolGroupName: string, provisioningStatus: record<completedSteps: int, currentStepDescription: string, isReady: bool, operationStartedTimeUtc: string, totalSteps: int>, tags: record, userGroupName: string, vmSpecs: record<diskType: int, imageResourceId: string, size: string, subnetResourceId: string>>
export def "put-api-v1-tenant-tenant-id-pool-pool-name" [
  tenant_id: string
  pool_name: string
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
  --domain-user-credentials: record # shape: {domain: string, organizationalUnit?: string, passwordSecretIdentifier: string, userName: string}
  --hot-pool-settings: record # shape: {size?: int}
  pool_group_name: string
  --tags: record # nullable
  --user-group-name: string # nullable
  vm_specs: record # shape: {diskType: "0 (StandardHDD)"|"1 (StandardSSD)"|"2 (PremiumSSD)", imageResourceId: string, size: string, subnetResourceId: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/v1/tenant/{tenantId}/Pool/{poolName}"
    path_params: [{name: tenantId, var: tenant_id}, {name: poolName, var: pool_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: domainUserCredentials, var: domain_user_credentials}, {name: hotPoolSettings, var: hot_pool_settings}, {name: poolGroupName, var: pool_group_name}, {name: tags, var: tags}, {name: userGroupName, var: user_group_name}, {name: vmSpecs, var: vm_specs}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200, 202]
    auth: bearer
  } {
    tenant_id: $tenant_id, pool_name: $pool_name, domain_user_credentials: $domain_user_credentials, hot_pool_settings: $hot_pool_settings, pool_group_name: $pool_group_name, tags: $tags, user_group_name: $user_group_name, vm_specs: $vm_specs
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# DELETE /api/v1/tenant/{tenantId}/PoolGroup/{poolGroupName}
export def "delete-api-v1-tenant-tenant-id-pool-group-pool-group-name" [
  tenant_id: string
  pool_group_name: string
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
    path: "/api/v1/tenant/{tenantId}/PoolGroup/{poolGroupName}"
    path_params: [{name: tenantId, var: tenant_id}, {name: poolGroupName, var: pool_group_name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tenant_id: $tenant_id, pool_group_name: $pool_group_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /api/v1/tenant/{tenantId}/PoolGroup/{poolGroupName}
#
# Returns: record<displayName: string, region: int, tags: record>
export def "get-api-v1-tenant-tenant-id-pool-group-pool-group-name" [
  tenant_id: string
  pool_group_name: string
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
    path: "/api/v1/tenant/{tenantId}/PoolGroup/{poolGroupName}"
    path_params: [{name: tenantId, var: tenant_id}, {name: poolGroupName, var: pool_group_name}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    tenant_id: $tenant_id, pool_group_name: $pool_group_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# PATCH /api/v1/tenant/{tenantId}/PoolGroup/{poolGroupName}
export def "patch-api-v1-tenant-tenant-id-pool-group-pool-group-name" [
  tenant_id: string
  pool_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  display_name: string
  --tags: record # nullable
]: any -> any {
  $in | http-request {
    method: patch
    path: "/api/v1/tenant/{tenantId}/PoolGroup/{poolGroupName}"
    path_params: [{name: tenantId, var: tenant_id}, {name: poolGroupName, var: pool_group_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: displayName, var: display_name}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tenant_id: $tenant_id, pool_group_name: $pool_group_name, display_name: $display_name, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /api/v1/tenant/{tenantId}/PoolGroup/{poolGroupName}
export def "put-api-v1-tenant-tenant-id-pool-group-pool-group-name" [
  tenant_id: string
  pool_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  display_name: string
  region: int@region-completer # format: int32
  --tags: record # nullable
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v1/tenant/{tenantId}/PoolGroup/{poolGroupName}"
    path_params: [{name: tenantId, var: tenant_id}, {name: poolGroupName, var: pool_group_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: displayName, var: display_name}, {name: region, var: region}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tenant_id: $tenant_id, pool_group_name: $pool_group_name, display_name: $display_name, region: $region, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /api/v1/tenant/{tenantId}/pool/{poolName}/Vm
#
# Returns: table<connection: record<connectionType: int, liveShareWorkspaceId: string>, provisioningStatus: record<completedSteps: int, currentStepDescription: string, isReady: bool, operationStartedTimeUtc: string, totalSteps: int>, status: int>
export def "get-api-v1-tenant-tenant-id-pool-pool-name-vm" [
  tenant_id: string
  pool_name: string
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/tenant/{tenantId}/pool/{poolName}/Vm"
    path_params: [{name: tenantId, var: tenant_id}, {name: poolName, var: pool_name}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    tenant_id: $tenant_id, pool_name: $pool_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# DELETE /api/v1/tenant/{tenantId}/pool/{poolName}/Vm/{vmName}
export def "delete-api-v1-tenant-tenant-id-pool-pool-name-vm-vm-name" [
  tenant_id: string
  pool_name: string
  vm_name: string
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
    path: "/api/v1/tenant/{tenantId}/pool/{poolName}/Vm/{vmName}"
    path_params: [{name: tenantId, var: tenant_id}, {name: poolName, var: pool_name}, {name: vmName, var: vm_name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tenant_id: $tenant_id, pool_name: $pool_name, vm_name: $vm_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /api/v1/tenant/{tenantId}/pool/{poolName}/Vm/{vmName}
#
# Returns: record<connection: record<connectionType: int, liveShareWorkspaceId: string>, provisioningStatus: record<completedSteps: int, currentStepDescription: string, isReady: bool, operationStartedTimeUtc: string, totalSteps: int>, status: int>
export def "get-api-v1-tenant-tenant-id-pool-pool-name-vm-vm-name" [
  tenant_id: string
  pool_name: string
  vm_name: string
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
    path: "/api/v1/tenant/{tenantId}/pool/{poolName}/Vm/{vmName}"
    path_params: [{name: tenantId, var: tenant_id}, {name: poolName, var: pool_name}, {name: vmName, var: vm_name}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    tenant_id: $tenant_id, pool_name: $pool_name, vm_name: $vm_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# PUT /api/v1/tenant/{tenantId}/pool/{poolName}/Vm/{vmName}
#
# Returns: record<connection: record<connectionType: int, liveShareWorkspaceId: string>, provisioningStatus: record<completedSteps: int, currentStepDescription: string, isReady: bool, operationStartedTimeUtc: string, totalSteps: int>, status: int>
export def "put-api-v1-tenant-tenant-id-pool-pool-name-vm-vm-name" [
  tenant_id: string
  pool_name: string
  vm_name: string
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
  user: record # shape: {userPrincipalName: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/v1/tenant/{tenantId}/pool/{poolName}/Vm/{vmName}"
    path_params: [{name: tenantId, var: tenant_id}, {name: poolName, var: pool_name}, {name: vmName, var: vm_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: user, var: user}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200, 202]
    auth: bearer
  } {
    tenant_id: $tenant_id, pool_name: $pool_name, vm_name: $vm_name, user: $user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# POST /api/v1/tenant/{tenantId}/pool/{poolName}/Vm/{vmName}/start
export def "post-api-v1-tenant-tenant-id-pool-pool-name-vm-vm-name-start" [
  tenant_id: string
  pool_name: string
  vm_name: string
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
    path: "/api/v1/tenant/{tenantId}/pool/{poolName}/Vm/{vmName}/start"
    path_params: [{name: tenantId, var: tenant_id}, {name: poolName, var: pool_name}, {name: vmName, var: vm_name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tenant_id: $tenant_id, pool_name: $pool_name, vm_name: $vm_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/v1/tenant/{tenantId}/pool/{poolName}/Vm/{vmName}/stop
export def "post-api-v1-tenant-tenant-id-pool-pool-name-vm-vm-name-stop" [
  tenant_id: string
  pool_name: string
  vm_name: string
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
    path: "/api/v1/tenant/{tenantId}/pool/{poolName}/Vm/{vmName}/stop"
    path_params: [{name: tenantId, var: tenant_id}, {name: poolName, var: pool_name}, {name: vmName, var: vm_name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tenant_id: $tenant_id, pool_name: $pool_name, vm_name: $vm_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/v2/prebuilds/delete
export def "post-api-v2-prebuilds-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  branch_name: string
  --dev-container-path: string # nullable
  --prebuild-configuration-id: int # format: int64
  repo_id: int # format: int64
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v2/prebuilds/delete"
    body: {content_type: "application/json", kind: json, fields: [{name: branchName, var: branch_name}, {name: devContainerPath, var: dev_container_path}, {name: prebuildConfigurationId, var: prebuild_configuration_id}, {name: repoId, var: repo_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    branch_name: $branch_name, dev_container_path: $dev_container_path, prebuild_configuration_id: $prebuild_configuration_id, repo_id: $repo_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /api/v2/prebuilds/repository/{repoId}/branch/{branchName}
export def "delete-api-v2-prebuilds-repository-repo-id-branch-branch-name" [
  repo_id: int
  branch_name: string
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
    path: "/api/v2/prebuilds/repository/{repoId}/branch/{branchName}"
    path_params: [{name: repoId, var: repo_id}, {name: branchName, var: branch_name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    repo_id: $repo_id, branch_name: $branch_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/v2/prebuilds/templates
#
# Returns: record<properties: record, sasUrl: string, templateId: string>
export def "post-api-v2-prebuilds-templates" [
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
  --dev-container-path: string # nullable
  --experimental-features: record # shape: {enableDynamicHttpsDetection?: bool, queueResourceAllocation?: bool, usePrebuildFastPathIfAvailable?: bool, usePrebuiltImages?: bool, useStorageV2?: bool}
  --features: record # nullable
  friendly_name: string
  --plan-id: string # nullable
  --seed: record # shape: {cloneUrl?: string, gitConfig?: record, recurseClone?: bool, repository?: record, seedMoniker?: string, seedType?: string}
  --storage-type: int@storage-type-completer # format: int32
  --template-info: record # shape: {container?: record, prebuildConfigurationId?: string, templateSizeInGB?: float, totalTimeSavingsInSeconds?: string, workFlowRunId?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v2/prebuilds/templates"
    body: {content_type: "application/json", kind: json, fields: [{name: devContainerPath, var: dev_container_path}, {name: experimentalFeatures, var: experimental_features}, {name: features, var: features}, {name: friendlyName, var: friendly_name}, {name: planId, var: plan_id}, {name: seed, var: seed}, {name: storageType, var: storage_type}, {name: templateInfo, var: template_info}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [201]
    auth: bearer
  } {
    dev_container_path: $dev_container_path, experimental_features: $experimental_features, features: $features, friendly_name: $friendly_name, plan_id: $plan_id, seed: $seed, storage_type: $storage_type, template_info: $template_info
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /api/v2/prebuilds/templates/skus/repo/{repoId}/branch/{branchName}/hash/{prebuildHash}/location/{location}/devcontainerpath/{devContainerPath}
#
# Returns: record<branchName: string, devContainerPath: string, location: int, poolSkus: list<string>, prebuildHash: string, repoId: string, supportedSkus: list<string>, templateSkus: list<string>>
# operationId: GetPrebuildReadinessSkusRoute
export def "get-prebuild-readiness-skus-route" [
  repo_id: string
  branch_name: string
  prebuild_hash: string
  location: string
  dev_container_path: string
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
  --storage-type: int@storage-type-completer # format: int32
  --fast-path-enabled: oneof<nothing, bool>
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/prebuilds/templates/skus/repo/{repoId}/branch/{branchName}/hash/{prebuildHash}/location/{location}/devcontainerpath/{devContainerPath}"
    path_params: [{name: repoId, var: repo_id}, {name: branchName, var: branch_name}, {name: prebuildHash, var: prebuild_hash}, {name: location, var: location}, {name: devContainerPath, var: dev_container_path}]
    query: [{name: storageType, var: storage_type}, {name: fastPathEnabled, var: fast_path_enabled}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    repo_id: $repo_id, branch_name: $branch_name, prebuild_hash: $prebuild_hash, location: $location, dev_container_path: $dev_container_path, storage_type: $storage_type, fast_path_enabled: $fast_path_enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# POST /api/v2/prebuilds/templates/updatemaxversions
export def "post-api-v2-prebuilds-templates-updatemaxversions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  branch_name: string
  --dev-container-path: string # nullable
  max_prebuild_template_versions: int # format: int32
  repo_id: int # format: int64
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v2/prebuilds/templates/updatemaxversions"
    body: {content_type: "application/json", kind: json, fields: [{name: branchName, var: branch_name}, {name: devContainerPath, var: dev_container_path}, {name: maxPrebuildTemplateVersions, var: max_prebuild_template_versions}, {name: repoId, var: repo_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    branch_name: $branch_name, dev_container_path: $dev_container_path, max_prebuild_template_versions: $max_prebuild_template_versions, repo_id: $repo_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/v2/prebuilds/templates/{templateId}/updatestatus
export def "post-api-v2-prebuilds-templates-template-id-updatestatus" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-success: oneof<nothing, bool>
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v2/prebuilds/templates/{templateId}/updatestatus"
    path_params: [{name: templateId, var: template_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: isSuccess, var: is_success, required: true}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    template_id: $template_id, is_success: $is_success
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /health
export def "get-health" [
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

# GET /internal/Netmon/correlation
#
# Returns: string
export def "get-internal-netmon-correlation" [
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
  --mac-address: string
]: nothing -> any {
  http-request {
    method: get
    path: "/internal/Netmon/correlation"
    query: [{name: macAddress, var: mac_address}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    mac_address: $mac_address
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /tunnelauth
export def "get-tunnelauth" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --cluster: string
  --name: string
  --port: int # format: int32
  --pb: string
]: nothing -> any {
  http-request {
    method: get
    path: "/tunnelauth"
    query: [{name: id, var: id}, {name: cluster, var: cluster}, {name: name, var: name}, {name: port, var: port}, {name: pb, var: pb}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, cluster: $cluster, name: $name, port: $port, pb: $pb
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /tunnelauth
export def "post-tunnelauth" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --op: string
  --id: string
  --cluster: string
  --name: string
  --port: int # format: int32
]: nothing -> any {
  http-request {
    method: post
    path: "/tunnelauth"
    query: [{name: op, var: op}, {name: id, var: id}, {name: cluster, var: cluster}, {name: name, var: name}, {name: port, var: port}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    op: $op, id: $id, cluster: $cluster, name: $name, port: $port
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /warmup
export def "get-warmup" [
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
    path: "/warmup"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
