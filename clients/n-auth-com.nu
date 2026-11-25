# Auto-generated client for nextAuth API v2.2
# Source: https://api.apis.guru/v2/specs/n-auth.com/2.2/swagger.json
# Auth: --token flag or $env.NEXTAUTH_API_TOKEN

const CLIENT = {
  base_url: "https://api.nextauth.com"
  token_env_var: "NEXTAUTH_API_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: x-apikey, in: header, header_name: X-apikey, prefix: ""}
    {name: x-su, in: header, header_name: X-su, prefix: ""}
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

def base-url-completer [] { ["https://api.nextauth.com"] }
def auth-scheme-completer [] { ["x-apikey" "x-su"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-api-keys: "record<apikeys: table<apikey: string, description: string, role: string>>"
    create-api-key: "record<apikey: string, description: string, role: string>"
    get-global-attributes: "string"
    get-servers: "record<servers: table<accountCount: int, appandroid: string, appios: string, appname: string, appurl: string, lastLogin: int, logo: string, owner: int, pinTimeout: int, pinTransTimeout: int, pingTime: int, serverFlags: list, serverName: string, serverid: string, serverpk: string, siteurl: string, wsurl: string>, totalnumber: int>"
    create-server: "record<accountCount: int, appandroid: string, appios: string, appname: string, appurl: string, lastLogin: int, logo: string, owner: int, pinTimeout: int, pinTransTimeout: int, pingTime: int, serverFlags: list<string>, serverName: string, serverid: string, serverpk: string, siteurl: string, wsurl: string>"
    get-server: "record<accountCount: int, appandroid: string, appios: string, appname: string, appurl: string, lastLogin: int, logo: string, owner: int, pinTimeout: int, pinTransTimeout: int, pingTime: int, serverFlags: list<string>, serverName: string, serverid: string, serverpk: string, siteurl: string, wsurl: string>"
    update-server: "record<accountCount: int, appandroid: string, appios: string, appname: string, appurl: string, lastLogin: int, logo: string, owner: int, pinTimeout: int, pinTransTimeout: int, pingTime: int, serverFlags: list<string>, serverName: string, serverid: string, serverpk: string, siteurl: string, wsurl: string>"
    get-all-accounts: "record<accounts: table<blocked: bool, clientVersion: string, created: int, description: string, id: int, lastlogin: int, lastprovoke: int, userid: string>, totalnumber: int>"
    get-account: "record<blocked: bool, clientVersion: string, created: int, description: string, id: int, lastlogin: int, lastprovoke: int, userid: string>"
    update-account: "record<blocked: bool, clientVersion: string, created: int, description: string, id: int, lastlogin: int, lastprovoke: int, userid: string>"
    update-account-user: "record<blocked: bool, clientVersion: string, created: int, description: string, id: int, lastlogin: int, lastprovoke: int, userid: string>"
    get-server-attributes: "string"
    get-all-permissions: "record<permissions: table<acl: string, role: string, server: string>>"
    get-permissions: "record<permissions: table<acl: string, role: string, server: string>>"
    get-server-privileged-attributes: "string"
    get-session: "record<accountid: int, canprovoke: bool, hsid: string, loggedin: bool, loginqrdata: string, pk: string, userid: string>"
    get-html-enrol: "string"
    get-html-footer: "string"
    get-html-login: "string"
    get-qr-enrol: "binary"
    get-qr-login: "binary"
    create-transaction: "record<tid: string>"
    get-transaction-result: "record<tstatus: string>"
    get-users: "record<totalnumber: int, users: table<lastlogin: int, numberaccounts: int, userid: string>>"
    get-user: "record<accounts: table<blocked: bool, clientVersion: string, created: int, description: string, id: int, lastlogin: int, lastprovoke: int, userid: string>, totalnumber: int>"
    get-user-attributes: "string"
    get-user-role: "record<role: string>"
    get-or-create-user-role: "record<role: string>"
    get-server-vash: "binary"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-api-keys" "create-api-key" "delete-global-attributes" "get-global-attributes" "set-global-attributes" "update-global-attributes" "delete-global-attribute" "get-servers" "create-server" "get-server" "update-server" "get-all-accounts" "delete-account" "get-account" "update-account" "provoke-login-on-account" "update-account-user" "delete-server-attributes" "get-server-attributes" "set-server-attributes" "update-server-attributes" "delete-server-attribute" "get-all-permissions" "revoke-permissions" "get-permissions" "grant-permissions" "delete-server-privileged-attributes" "get-server-privileged-attributes" "set-server-privileged-attributes" "update-server-privileged-attributes" "delete-server-privileged-attribute" "get-session" "get-html-enrol" "get-html-footer" "get-html-login" "logout" "provoke-login" "get-qr-enrol" "get-qr-login" "register-user" "create-transaction" "get-transaction-result" "get-users" "delete-user" "delete-user-accounts" "get-user" "delete-user-attributes" "get-user-attributes" "set-user-attributes" "update-user-attributes" "delete-user-attribute" "provoke-login-on-user" "get-user-role" "get-or-create-user-role" "get-server-vash" "commands"] | sort) } | get name | first)
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

# Get all API keys.
#
# GET /apikeys/
# Returns: record<apikeys: table<apikey: string, description: string, role: string>>
# operationId: getApiKeys
export def "get-api-keys" [
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
    path: "/apikeys/"
    accept: ["application/json"]
    ok: [200]
    auth: x-apikey
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new API key.
#
# POST /apikeys/
# Returns: record<apikey: string, description: string, role: string>
# operationId: createApiKey
export def "create-api-key" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # Description for the new role (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apikeys/"
    query: [{name: description, var: description, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: x-apikey
  } {
    description: $description
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete all global attributes
#
# DELETE /attributes/
# operationId: deleteGlobalAttributes
export def "delete-global-attributes" [
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
    path: "/attributes/"
    accept: ["application/json"]
    ok: [200]
    auth: x-apikey
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all global attributes
#
# GET /attributes/
# Returns: string
# operationId: getGlobalAttributes
export def "get-global-attributes" [
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
    path: "/attributes/"
    accept: ["text/plain"]
    ok: [200]
    auth: x-apikey
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set all global attributes
#
# POST /attributes/
# operationId: setGlobalAttributes
export def "set-global-attributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  $in | http-request {
    method: post
    path: "/attributes/"
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: x-apikey
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update specified global attributes
#
# PUT /attributes/
# operationId: updateGlobalAttributes
export def "update-global-attributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  $in | http-request {
    method: put
    path: "/attributes/"
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: x-apikey
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete specific global attribute
#
# DELETE /attributes/{attributekey}
# operationId: deleteGlobalAttribute
export def "delete-global-attribute" [
  attributekey: string
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
    path: "/attributes/{attributekey}"
    path_params: [{name: attributekey, var: attributekey}]
    accept: ["application/json"]
    ok: [200]
    auth: x-apikey
  } {
    attributekey: $attributekey
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all your servers
#
# GET /servers/
# Returns: record<servers: table<accountCount: int, appandroid: string, appios: string, appname: string, appurl: string, lastLogin: int, logo: string, owner: int, pinTimeout: int, pinTransTimeout: int, pingTime: int, serverFlags: list, serverName: string, serverid: string, serverpk: string, siteurl: string, wsurl: string>, totalnumber: int>
# operationId: getServers
export def "get-servers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Limit the number of results
  --marker: int # Offset in the result list
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/servers/"
    query: [{name: limit, var: limit}, {name: marker, var: marker}]
    accept: ["application/json"]
    ok: [200]
    auth: x-apikey
  } {
    limit: $limit, marker: $marker
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new server
#
# POST /servers/
# Returns: record<accountCount: int, appandroid: string, appios: string, appname: string, appurl: string, lastLogin: int, logo: string, owner: int, pinTimeout: int, pinTransTimeout: int, pingTime: int, serverFlags: list<string>, serverName: string, serverid: string, serverpk: string, siteurl: string, wsurl: string>
# operationId: createServer
export def "create-server" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-count: int # Number of accounts registered with this server
  --appandroid: string # URL of the app in Google Play
  --appios: string # URL of the app in the App Store
  --appname: string # name of the app
  --appurl: string # URL (prefix) to launch the app
  --last-login: int # Last login on this server (format: int64)
  logo: string # Base 64 encoded logo
  --owner: int # Owner id
  pin_timeout: int # Time (minutes) since the last time the user entered his PIN, that the user is not requested a PIN at login. -1 means that the user is never asked for a PIN before logging in, 0 means that the user is asked every time he wants to login
  pin_trans_timeout: int # Time (minutes) since the last time the user entered his PIN, that the user is not requested a PIN at transaction approval. -1 means that the user is never asked for a PIN before approving a transaction, 0 means that the user is asked every time he wants to approve a transaction
  ping_time: int # Time (seconds) that the nextAuth app has before it needs to reply to a ping request from the nextAuth server (continuous authentication)
  server_flags: list<string> # Server flags
  server_name: string # Server name
  serverid: string # Base64 encoded id of the nextAuth server
  serverpk: string # Base64 encoded public key of the nextAuth server
  --siteurl: string # URL of the main website
  --wsurl: string # Websocket URL
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/servers/"
    body: {content_type: "application/json", kind: json, fields: [{name: accountCount, var: account_count}, {name: appandroid, var: appandroid}, {name: appios, var: appios}, {name: appname, var: appname}, {name: appurl, var: appurl}, {name: lastLogin, var: last_login}, {name: logo, var: logo}, {name: owner, var: owner}, {name: pinTimeout, var: pin_timeout}, {name: pinTransTimeout, var: pin_trans_timeout}, {name: pingTime, var: ping_time}, {name: serverFlags, var: server_flags}, {name: serverName, var: server_name}, {name: serverid, var: serverid}, {name: serverpk, var: serverpk}, {name: siteurl, var: siteurl}, {name: wsurl, var: wsurl}]}
    accept: ["application/octet-stream"]
    ok: [200]
    auth: x-apikey
  } {
    account_count: $account_count, appandroid: $appandroid, appios: $appios, appname: $appname, appurl: $appurl, last_login: $last_login, logo: $logo, owner: $owner, pin_timeout: $pin_timeout, pin_trans_timeout: $pin_trans_timeout, ping_time: $ping_time, server_flags: $server_flags, server_name: $server_name, serverid: $serverid, serverpk: $serverpk, siteurl: $siteurl, wsurl: $wsurl
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Configuration of a specific server
#
# GET /servers/{serverid}/
# Returns: record<accountCount: int, appandroid: string, appios: string, appname: string, appurl: string, lastLogin: int, logo: string, owner: int, pinTimeout: int, pinTransTimeout: int, pingTime: int, serverFlags: list<string>, serverName: string, serverid: string, serverpk: string, siteurl: string, wsurl: string>
# operationId: getServer
export def "get-server" [
  serverid: string
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
    path: "/servers/{serverid}/"
    path_params: [{name: serverid, var: serverid}]
    accept: ["application/json"]
    ok: [200]
    auth: x-apikey
  } {
    serverid: $serverid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update configuration of a specific server
#
# PUT /servers/{serverid}/
# Returns: record<accountCount: int, appandroid: string, appios: string, appname: string, appurl: string, lastLogin: int, logo: string, owner: int, pinTimeout: int, pinTransTimeout: int, pingTime: int, serverFlags: list<string>, serverName: string, serverid: string, serverpk: string, siteurl: string, wsurl: string>
# operationId: updateServer
export def "update-server" [
  serverid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-count: int # Number of accounts registered with this server
  --appandroid: string # URL of the app in Google Play
  --appios: string # URL of the app in the App Store
  --appname: string # name of the app
  --appurl: string # URL (prefix) to launch the app
  --last-login: int # Last login on this server (format: int64)
  logo: string # Base 64 encoded logo
  --owner: int # Owner id
  pin_timeout: int # Time (minutes) since the last time the user entered his PIN, that the user is not requested a PIN at login. -1 means that the user is never asked for a PIN before logging in, 0 means that the user is asked every time he wants to login
  pin_trans_timeout: int # Time (minutes) since the last time the user entered his PIN, that the user is not requested a PIN at transaction approval. -1 means that the user is never asked for a PIN before approving a transaction, 0 means that the user is asked every time he wants to approve a transaction
  ping_time: int # Time (seconds) that the nextAuth app has before it needs to reply to a ping request from the nextAuth server (continuous authentication)
  server_flags: list<string> # Server flags
  server_name: string # Server name
  --body-serverid: string # Base64 encoded id of the nextAuth server (spec name: serverid)
  serverpk: string # Base64 encoded public key of the nextAuth server
  --siteurl: string # URL of the main website
  --wsurl: string # Websocket URL
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/servers/{serverid}/"
    path_params: [{name: serverid, var: serverid}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountCount, var: account_count}, {name: appandroid, var: appandroid}, {name: appios, var: appios}, {name: appname, var: appname}, {name: appurl, var: appurl}, {name: lastLogin, var: last_login}, {name: logo, var: logo}, {name: owner, var: owner}, {name: pinTimeout, var: pin_timeout}, {name: pinTransTimeout, var: pin_trans_timeout}, {name: pingTime, var: ping_time}, {name: serverFlags, var: server_flags}, {name: serverName, var: server_name}, {name: serverid, var: body_serverid, required: true}, {name: serverpk, var: serverpk}, {name: siteurl, var: siteurl}, {name: wsurl, var: wsurl}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-apikey
  } {
    serverid: $serverid, account_count: $account_count, appandroid: $appandroid, appios: $appios, appname: $appname, appurl: $appurl, last_login: $last_login, logo: $logo, owner: $owner, pin_timeout: $pin_timeout, pin_trans_timeout: $pin_trans_timeout, ping_time: $ping_time, server_flags: $server_flags, server_name: $server_name, body_serverid: $body_serverid, serverpk: $serverpk, siteurl: $siteurl, wsurl: $wsurl
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all accounts
#
# GET /servers/{serverid}/accounts/
# Returns: record<accounts: table<blocked: bool, clientVersion: string, created: int, description: string, id: int, lastlogin: int, lastprovoke: int, userid: string>, totalnumber: int>
# operationId: getAllAccounts
export def "get-all-accounts" [
  serverid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter users based on an attribute. Takes the format *attributename=attributevalue*. You can filter for multiple values at once, e.g. *group=in:group1,group2*
  --limit: int # Limit the number of results
  --marker: int # Offset in the result list
  --sort: string # Sort the results by column. You can also specify ascending (default if not specified) or descending, e.g., *column:asc* . You can also sort by multiple columns, e.g., *column1:desc,column2:asc*
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/servers/{serverid}/accounts/"
    path_params: [{name: serverid, var: serverid}]
    query: [{name: filter, var: filter}, {name: limit, var: limit}, {name: marker, var: marker}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: x-apikey
  } {
    serverid: $serverid, filter: $filter, limit: $limit, marker: $marker, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete specific account
#
# DELETE /servers/{serverid}/accounts/{accountid}/
# operationId: deleteAccount
export def "delete-account" [
  serverid: string
  accountid: int
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
    path: "/servers/{serverid}/accounts/{accountid}/"
    path_params: [{name: serverid, var: serverid}, {name: accountid, var: accountid}]
    accept: ["application/json"]
    ok: [200]
    auth: x-apikey
  } {
    serverid: $serverid, accountid: $accountid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get specific account
#
# GET /servers/{serverid}/accounts/{accountid}/
# Returns: record<blocked: bool, clientVersion: string, created: int, description: string, id: int, lastlogin: int, lastprovoke: int, userid: string>
# operationId: getAccount
export def "get-account" [
  serverid: string
  accountid: int
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
    path: "/servers/{serverid}/accounts/{accountid}/"
    path_params: [{name: serverid, var: serverid}, {name: accountid, var: accountid}]
    accept: ["application/json"]
    ok: [200]
    auth: x-apikey
  } {
    serverid: $serverid, accountid: $accountid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update specific account
#
# PUT /servers/{serverid}/accounts/{accountid}/
# Returns: record<blocked: bool, clientVersion: string, created: int, description: string, id: int, lastlogin: int, lastprovoke: int, userid: string>
# operationId: updateAccount
export def "update-account" [
  serverid: string
  accountid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --blocked: oneof<nothing, bool> # True if the account is blocked (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/servers/{serverid}/accounts/{accountid}/"
    path_params: [{name: serverid, var: serverid}, {name: accountid, var: accountid}]
    query: [{name: blocked, var: blocked, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: x-apikey
  } {
    serverid: $serverid, accountid: $accountid, blocked: $blocked
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Push a login confirmation to the user's app
#
# POST /servers/{serverid}/accounts/{accountid}/provokelogin
# operationId: provokeLoginOnAccount
export def "provoke-login-on-account" [
  serverid: string
  accountid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-nonce: string # Base64 encoded nonce to identify the browser/webserver session (required)
  --announceinfo: any # shape: {info?: record, ip?: string, logo?: string, useragent?: string}
  --sessioninfo: any # shape: {info?: record, ip?: string, logo?: string, useragent?: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/servers/{serverid}/accounts/{accountid}/provokelogin"
    path_params: [{name: serverid, var: serverid}, {name: accountid, var: accountid}]
    header: [{name: X-nonce, var: x_nonce, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: announceinfo, var: announceinfo}, {name: sessioninfo, var: sessioninfo}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-apikey
  } {
    serverid: $serverid, accountid: $accountid, x_nonce: $x_nonce, announceinfo: $announceinfo, sessioninfo: $sessioninfo
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update user of the given account.
#
# PUT /servers/{serverid}/accounts/{accountid}/user
# Returns: record<blocked: bool, clientVersion: string, created: int, description: string, id: int, lastlogin: int, lastprovoke: int, userid: string>
# operationId: updateAccountUser
export def "update-account-user" [
  serverid: string
  accountid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --userid: string # User name (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/servers/{serverid}/accounts/{accountid}/user"
    path_params: [{name: serverid, var: serverid}, {name: accountid, var: accountid}]
    query: [{name: userid, var: userid, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: x-apikey
  } {
    serverid: $serverid, accountid: $accountid, userid: $userid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete all attributes of a specific server
#
# DELETE /servers/{serverid}/attributes/
# operationId: deleteServerAttributes
export def "delete-server-attributes" [
  serverid: string
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
    path: "/servers/{serverid}/attributes/"
    path_params: [{name: serverid, var: serverid}]
    accept: ["application/json"]
    ok: [200]
    auth: x-apikey
  } {
    serverid: $serverid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all attributes of a specific server
#
# GET /servers/{serverid}/attributes/
# Returns: string
# operationId: getServerAttributes
export def "get-server-attributes" [
  serverid: string
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
    path: "/servers/{serverid}/attributes/"
    path_params: [{name: serverid, var: serverid}]
    accept: ["text/plain"]
    ok: [200]
    auth: x-apikey
  } {
    serverid: $serverid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set all attributes of a specific server
#
# POST /servers/{serverid}/attributes/
# operationId: setServerAttributes
export def "set-server-attributes" [
  serverid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  $in | http-request {
    method: post
    path: "/servers/{serverid}/attributes/"
    path_params: [{name: serverid, var: serverid}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: x-apikey
  } {
    serverid: $serverid, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update specified attributes of a specific server
#
# PUT /servers/{serverid}/attributes/
# operationId: updateServerAttributes
export def "update-server-attributes" [
  serverid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  $in | http-request {
    method: put
    path: "/servers/{serverid}/attributes/"
    path_params: [{name: serverid, var: serverid}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: x-apikey
  } {
    serverid: $serverid, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete specific attribute of a specific server
#
# DELETE /servers/{serverid}/attributes/{attributekey}
# operationId: deleteServerAttribute
export def "delete-server-attribute" [
  serverid: string
  attributekey: string
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
    path: "/servers/{serverid}/attributes/{attributekey}"
    path_params: [{name: serverid, var: serverid}, {name: attributekey, var: attributekey}]
    accept: ["application/json"]
    ok: [200]
    auth: x-apikey
  } {
    serverid: $serverid, attributekey: $attributekey
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all permissions for the specified server.
#
# GET /servers/{serverid}/permissions/
# Returns: record<permissions: table<acl: string, role: string, server: string>>
# operationId: getAllPermissions
export def "get-all-permissions" [
  serverid: string
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
    path: "/servers/{serverid}/permissions/"
    path_params: [{name: serverid, var: serverid}]
    accept: ["application/json"]
    ok: [200]
    auth: x-apikey
  } {
    serverid: $serverid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Revoke all permissions for the specified server and role.
#
# DELETE /servers/{serverid}/permissions/{roleid}
# operationId: revokePermissions
export def "revoke-permissions" [
  serverid: string
  roleid: string
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
    path: "/servers/{serverid}/permissions/{roleid}"
    path_params: [{name: serverid, var: serverid}, {name: roleid, var: roleid}]
    accept: ["application/json"]
    ok: [200]
    auth: x-apikey
  } {
    serverid: $serverid, roleid: $roleid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all permissions for the specified server and role.
#
# GET /servers/{serverid}/permissions/{roleid}
# Returns: record<permissions: table<acl: string, role: string, server: string>>
# operationId: getPermissions
export def "get-permissions" [
  serverid: string
  roleid: string
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
    path: "/servers/{serverid}/permissions/{roleid}"
    path_params: [{name: serverid, var: serverid}, {name: roleid, var: roleid}]
    accept: ["application/json"]
    ok: [200]
    auth: x-apikey
  } {
    serverid: $serverid, roleid: $roleid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set new permissions for the specified role on a server
#
# POST /servers/{serverid}/permissions/{roleid}
# operationId: grantPermissions
export def "grant-permissions" [
  serverid: string
  roleid: string
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
    path: "/servers/{serverid}/permissions/{roleid}"
    path_params: [{name: serverid, var: serverid}, {name: roleid, var: roleid}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: x-apikey
  } {
    serverid: $serverid, roleid: $roleid, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete all privileged attributes of a specific server
#
# DELETE /servers/{serverid}/privilegedattributes/
# operationId: deleteServerPrivilegedAttributes
export def "delete-server-privileged-attributes" [
  serverid: string
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
    path: "/servers/{serverid}/privilegedattributes/"
    path_params: [{name: serverid, var: serverid}]
    accept: ["application/json"]
    ok: [200]
    auth: x-apikey
  } {
    serverid: $serverid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all privileged attributes of a specific server
#
# GET /servers/{serverid}/privilegedattributes/
# Returns: string
# operationId: getServerPrivilegedAttributes
export def "get-server-privileged-attributes" [
  serverid: string
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
    path: "/servers/{serverid}/privilegedattributes/"
    path_params: [{name: serverid, var: serverid}]
    accept: ["text/plain"]
    ok: [200]
    auth: x-apikey
  } {
    serverid: $serverid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set all privileged attributes of a specific server
#
# POST /servers/{serverid}/privilegedattributes/
# operationId: setServerPrivilegedAttributes
export def "set-server-privileged-attributes" [
  serverid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  $in | http-request {
    method: post
    path: "/servers/{serverid}/privilegedattributes/"
    path_params: [{name: serverid, var: serverid}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: x-apikey
  } {
    serverid: $serverid, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update privileged specified attributes of a specific server
#
# PUT /servers/{serverid}/privilegedattributes/
# operationId: updateServerPrivilegedAttributes
export def "update-server-privileged-attributes" [
  serverid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  $in | http-request {
    method: put
    path: "/servers/{serverid}/privilegedattributes/"
    path_params: [{name: serverid, var: serverid}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: x-apikey
  } {
    serverid: $serverid, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete specific privileged attribute of a specific server
#
# DELETE /servers/{serverid}/privilegedattributes/{attributekey}
# operationId: deleteServerPrivilegedAttribute
export def "delete-server-privileged-attribute" [
  serverid: string
  attributekey: string
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
    path: "/servers/{serverid}/privilegedattributes/{attributekey}"
    path_params: [{name: serverid, var: serverid}, {name: attributekey, var: attributekey}]
    accept: ["application/json"]
    ok: [200]
    auth: x-apikey
  } {
    serverid: $serverid, attributekey: $attributekey
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check if the user is logged in
#
# GET /servers/{serverid}/sessions/
# Returns: record<accountid: int, canprovoke: bool, hsid: string, loggedin: bool, loginqrdata: string, pk: string, userid: string>
# operationId: getSession
export def "get-session" [
  serverid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-nonce: string # Nonce to identify the browser/webserver session (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/servers/{serverid}/sessions/"
    path_params: [{name: serverid, var: serverid}]
    header: [{name: X-nonce, var: x_nonce, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: x-apikey
  } {
    serverid: $serverid, x_nonce: $x_nonce
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generate HTML to enrol a new user
#
# GET /servers/{serverid}/sessions/html/enrol
# Returns: string
# operationId: getHtmlEnrol
export def "get-html-enrol" [
  serverid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Name to forward to the nextAuth app for this account
  --userid: string # User name to register this user under
  --x-nonce: string # Nonce to identify the browser/webserver session (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/servers/{serverid}/sessions/html/enrol"
    path_params: [{name: serverid, var: serverid}]
    query: [{name: name, var: name}, {name: userid, var: userid}]
    header: [{name: X-nonce, var: x_nonce, required: true}]
    accept: ["text/html"]
    ok: [200]
    auth: x-apikey
  } {
    serverid: $serverid, name: $name, userid: $userid, x_nonce: $x_nonce
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generic HTML to add to footer. Required for login/logout/enrol functionality.
#
# GET /servers/{serverid}/sessions/html/footer
# Returns: string
# operationId: getHtmlFooter
export def "get-html-footer" [
  serverid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-nonce: string # Nonce to identify the browser/webserver session (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/servers/{serverid}/sessions/html/footer"
    path_params: [{name: serverid, var: serverid}]
    header: [{name: X-nonce, var: x_nonce, required: true}]
    accept: ["text/html"]
    ok: [200]
    auth: x-apikey
  } {
    serverid: $serverid, x_nonce: $x_nonce
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generate HTML for the login block
#
# GET /servers/{serverid}/sessions/html/login
# Returns: string
# operationId: getHtmlLogin
export def "get-html-login" [
  serverid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-nonce: string # Nonce to identify the browser/webserver session (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/servers/{serverid}/sessions/html/login"
    path_params: [{name: serverid, var: serverid}]
    header: [{name: X-nonce, var: x_nonce, required: true}]
    accept: ["text/html"]
    ok: [200]
    auth: x-apikey
  } {
    serverid: $serverid, x_nonce: $x_nonce
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Force a logout on the given session
#
# POST /servers/{serverid}/sessions/logout
# operationId: logout
export def "logout" [
  serverid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-nonce: string # Nonce to identify the browser/webserver session (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/servers/{serverid}/sessions/logout"
    path_params: [{name: serverid, var: serverid}]
    header: [{name: X-nonce, var: x_nonce, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: x-apikey
  } {
    serverid: $serverid, x_nonce: $x_nonce
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Push a login confirmation to the user's app
#
# POST /servers/{serverid}/sessions/provokelogin
# operationId: provokeLogin
export def "provoke-login" [
  serverid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-nonce: string # Nonce to identify the browser/webserver session (required)
  --announceinfo: any # shape: {info?: record, ip?: string, logo?: string, useragent?: string}
  --sessioninfo: any # shape: {info?: record, ip?: string, logo?: string, useragent?: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/servers/{serverid}/sessions/provokelogin"
    path_params: [{name: serverid, var: serverid}]
    header: [{name: X-nonce, var: x_nonce, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: announceinfo, var: announceinfo}, {name: sessioninfo, var: sessioninfo}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-apikey
  } {
    serverid: $serverid, x_nonce: $x_nonce, announceinfo: $announceinfo, sessioninfo: $sessioninfo
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generate data for an enrol qr code
#
# GET /servers/{serverid}/sessions/qr/enrol
# Returns: binary
# operationId: getQrEnrol
export def "get-qr-enrol" [
  serverid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Name to forward to the nextAuth app for this account (required)
  --userid: string # User name to register this user under
  --img: string # 'png' for a PNG image, not set for raw data in the qr code
  --s: int # size in pixels of the qr code, defaults to 500
  --x-nonce: string # Nonce to identify the browser/webserver session (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/servers/{serverid}/sessions/qr/enrol"
    path_params: [{name: serverid, var: serverid}]
    query: [{name: name, var: name, required: true}, {name: userid, var: userid}, {name: img, var: img}, {name: s, var: s}]
    header: [{name: X-nonce, var: x_nonce, required: true}]
    accept: ["application/octet-stream"]
    ok: [200]
    auth: x-apikey
  } {
    serverid: $serverid, name: $name, userid: $userid, img: $img, s: $s, x_nonce: $x_nonce
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generate data for a login qr code
#
# GET /servers/{serverid}/sessions/qr/login
# Returns: binary
# operationId: getQrLogin
export def "get-qr-login" [
  serverid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --img: string # "png" for a PNG image, not set for raw data in the qr code
  --s: int # size in pixels of the qr code, defaults to 500
  --x-nonce: string # Nonce to identify the browser/webserver session (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/servers/{serverid}/sessions/qr/login"
    path_params: [{name: serverid, var: serverid}]
    query: [{name: img, var: img}, {name: s, var: s}]
    header: [{name: X-nonce, var: x_nonce, required: true}]
    accept: ["application/octet-stream"]
    ok: [200]
    auth: x-apikey
  } {
    serverid: $serverid, img: $img, s: $s, x_nonce: $x_nonce
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Register a userid for the currently logged in account.
#
# POST /servers/{serverid}/sessions/registeruser
# operationId: registerUser
export def "register-user" [
  serverid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --userid: string # Username to register (required)
  --x-nonce: string # Nonce to identify the browser/webserver session (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/servers/{serverid}/sessions/registeruser"
    path_params: [{name: serverid, var: serverid}]
    query: [{name: userid, var: userid, required: true}]
    header: [{name: X-nonce, var: x_nonce, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: x-apikey
  } {
    serverid: $serverid, userid: $userid, x_nonce: $x_nonce
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a transaction to be approved within the current session.
#
# POST /servers/{serverid}/sessions/transactions
# Returns: record<tid: string>
# operationId: createTransaction
export def "create-transaction" [
  serverid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-nonce: string # Nonce to identify the browser/webserver session (required)
  --amount: string
  --benificiary: string
  --description: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/servers/{serverid}/sessions/transactions"
    path_params: [{name: serverid, var: serverid}]
    header: [{name: X-nonce, var: x_nonce, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: amount, var: amount}, {name: benificiary, var: benificiary}, {name: description, var: description}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-apikey
  } {
    serverid: $serverid, x_nonce: $x_nonce, amount: $amount, benificiary: $benificiary, description: $description
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get transaction result for a given transaction.
#
# GET /servers/{serverid}/transactions/{transactionid}
# Returns: record<tstatus: string>
# operationId: getTransactionResult
export def "get-transaction-result" [
  serverid: string
  transactionid: string
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
    path: "/servers/{serverid}/transactions/{transactionid}"
    path_params: [{name: serverid, var: serverid}, {name: transactionid, var: transactionid}]
    accept: ["application/json"]
    ok: [200]
    auth: x-apikey
  } {
    serverid: $serverid, transactionid: $transactionid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all users
#
# GET /servers/{serverid}/users/
# Returns: record<totalnumber: int, users: table<lastlogin: int, numberaccounts: int, userid: string>>
# operationId: getUsers
export def "get-users" [
  serverid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter users based on an attribute. Takes the format *attributename=attributevalue*. You can filter for multiple values at once, e.g. *group=in:group1,group2*
  --search: string # Search for a username LIKE %search%
  --limit: int # Limit the number of results
  --marker: int # Offset in the result list
  --sort: string # Sort the results by column. You can also specify ascending (default if not specified) or descending, e.g., *column:asc* . You can also sort by multiple columns, e.g., *column1:desc,column2:asc*
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/servers/{serverid}/users/"
    path_params: [{name: serverid, var: serverid}]
    query: [{name: filter, var: filter}, {name: search, var: search}, {name: limit, var: limit}, {name: marker, var: marker}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: x-apikey
  } {
    serverid: $serverid, filter: $filter, search: $search, limit: $limit, marker: $marker, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a specific user
#
# DELETE /servers/{serverid}/users/{userid}/
# operationId: deleteUser
export def "delete-user" [
  serverid: string
  userid: string
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
    path: "/servers/{serverid}/users/{userid}/"
    path_params: [{name: serverid, var: serverid}, {name: userid, var: userid}]
    accept: ["application/json"]
    ok: [200]
    auth: x-apikey
  } {
    serverid: $serverid, userid: $userid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete all accounts of a specific user
#
# DELETE /servers/{serverid}/users/{userid}/accounts
# operationId: deleteUserAccounts
export def "delete-user-accounts" [
  serverid: string
  userid: string
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
    path: "/servers/{serverid}/users/{userid}/accounts"
    path_params: [{name: serverid, var: serverid}, {name: userid, var: userid}]
    accept: ["application/json"]
    ok: [200]
    auth: x-apikey
  } {
    serverid: $serverid, userid: $userid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all accounts of a specific user
#
# GET /servers/{serverid}/users/{userid}/accounts
# Returns: record<accounts: table<blocked: bool, clientVersion: string, created: int, description: string, id: int, lastlogin: int, lastprovoke: int, userid: string>, totalnumber: int>
# operationId: getUser
export def "get-user" [
  serverid: string
  userid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Limit the number of results
  --marker: int # Offset in the result list
  --sort: string # Sort the results by column. You can also specify ascending (default if not specified) or descending, e.g., *column:asc* . You can also sort by multiple columns, e.g., *column1:desc,column2:asc*
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/servers/{serverid}/users/{userid}/accounts"
    path_params: [{name: serverid, var: serverid}, {name: userid, var: userid}]
    query: [{name: limit, var: limit}, {name: marker, var: marker}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: x-apikey
  } {
    serverid: $serverid, userid: $userid, limit: $limit, marker: $marker, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete all attributes of a specific user
#
# DELETE /servers/{serverid}/users/{userid}/attributes/
# operationId: deleteUserAttributes
export def "delete-user-attributes" [
  serverid: string
  userid: string
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
    path: "/servers/{serverid}/users/{userid}/attributes/"
    path_params: [{name: serverid, var: serverid}, {name: userid, var: userid}]
    accept: ["application/json"]
    ok: [200]
    auth: x-apikey
  } {
    serverid: $serverid, userid: $userid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all attributes of a specific user
#
# GET /servers/{serverid}/users/{userid}/attributes/
# Returns: string
# operationId: getUserAttributes
export def "get-user-attributes" [
  serverid: string
  userid: string
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
    path: "/servers/{serverid}/users/{userid}/attributes/"
    path_params: [{name: serverid, var: serverid}, {name: userid, var: userid}]
    accept: ["text/plain"]
    ok: [200]
    auth: x-apikey
  } {
    serverid: $serverid, userid: $userid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set all attributes of a specific user
#
# POST /servers/{serverid}/users/{userid}/attributes/
# operationId: setUserAttributes
export def "set-user-attributes" [
  serverid: string
  userid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  $in | http-request {
    method: post
    path: "/servers/{serverid}/users/{userid}/attributes/"
    path_params: [{name: serverid, var: serverid}, {name: userid, var: userid}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: x-apikey
  } {
    serverid: $serverid, userid: $userid, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update specified attributes of a specific user
#
# PUT /servers/{serverid}/users/{userid}/attributes/
# operationId: updateUserAttributes
export def "update-user-attributes" [
  serverid: string
  userid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  $in | http-request {
    method: put
    path: "/servers/{serverid}/users/{userid}/attributes/"
    path_params: [{name: serverid, var: serverid}, {name: userid, var: userid}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: x-apikey
  } {
    serverid: $serverid, userid: $userid, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete specific attribute of a specific user
#
# DELETE /servers/{serverid}/users/{userid}/attributes/{attributekey}
# operationId: deleteUserAttribute
export def "delete-user-attribute" [
  serverid: string
  userid: string
  attributekey: string
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
    path: "/servers/{serverid}/users/{userid}/attributes/{attributekey}"
    path_params: [{name: serverid, var: serverid}, {name: userid, var: userid}, {name: attributekey, var: attributekey}]
    accept: ["application/json"]
    ok: [200]
    auth: x-apikey
  } {
    serverid: $serverid, userid: $userid, attributekey: $attributekey
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Push a login confirmation to the user's app
#
# POST /servers/{serverid}/users/{userid}/provokelogin
# operationId: provokeLoginOnUser
export def "provoke-login-on-user" [
  serverid: string
  userid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-nonce: string # Nonce to identify the browser/webserver session (required)
  --announceinfo: any # shape: {info?: record, ip?: string, logo?: string, useragent?: string}
  --sessioninfo: any # shape: {info?: record, ip?: string, logo?: string, useragent?: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/servers/{serverid}/users/{userid}/provokelogin"
    path_params: [{name: serverid, var: serverid}, {name: userid, var: userid}]
    header: [{name: X-nonce, var: x_nonce, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: announceinfo, var: announceinfo}, {name: sessioninfo, var: sessioninfo}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-apikey
  } {
    serverid: $serverid, userid: $userid, x_nonce: $x_nonce, announceinfo: $announceinfo, sessioninfo: $sessioninfo
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get role for a specific user.
#
# GET /servers/{serverid}/users/{userid}/role/
# Returns: record<role: string>
# operationId: getUserRole
export def "get-user-role" [
  serverid: string
  userid: string
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
    path: "/servers/{serverid}/users/{userid}/role/"
    path_params: [{name: serverid, var: serverid}, {name: userid, var: userid}]
    accept: ["application/json"]
    ok: [200]
    auth: x-apikey
  } {
    serverid: $serverid, userid: $userid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get or create a role for a specific user.
#
# POST /servers/{serverid}/users/{userid}/role/
# Returns: record<role: string>
# operationId: getOrCreateUserRole
export def "get-or-create-user-role" [
  serverid: string
  userid: string
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
    method: post
    path: "/servers/{serverid}/users/{userid}/role/"
    path_params: [{name: serverid, var: serverid}, {name: userid, var: userid}]
    accept: ["application/json"]
    ok: [200]
    auth: x-apikey
  } {
    serverid: $serverid, userid: $userid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Visual hash of this server
#
# GET /servers/{serverid}/vash
# Returns: binary
# operationId: getServerVash
export def "get-server-vash" [
  serverid: string
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
    path: "/servers/{serverid}/vash"
    path_params: [{name: serverid, var: serverid}]
    accept: ["application/octet-stream"]
    ok: [200]
    auth: x-apikey
  } {
    serverid: $serverid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
