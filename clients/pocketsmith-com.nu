# Auto-generated client for PocketSmith v2.0
# Source: https://api.apis.guru/v2/specs/pocketsmith.com/2.0/openapi.json
# Auth: --token flag or $env.POCKETSMITH_TOKEN

const CLIENT = {
  base_url: "https://api.pocketsmith.com/v2"
  token_env_var: "POCKETSMITH_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: x-developer-key, in: header, header_name: X-Developer-Key, prefix: ""}
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

def base-url-completer [] { ["https://api.pocketsmith.com/v2"] }
def auth-scheme-completer [] { ["x-developer-key" "bearer"] }

# Completers for enum parameters
def type-completer [] { ["bank" "cash" "credits" "insurance" "loans" "mortgage" "other_asset" "other_liability" "property" "stocks" "vehicle"] }
def type-completer-1 [] { ["credit" "debit"] }
def refund-behaviour-completer [] { ["credits_are_refunds" "debits_are_deductions"] }
def behaviour-completer [] { ["all" "forward" "one"] }
def repeat-type-completer [] { ["daily" "each weekday" "fortnightly" "monthly" "once" "weekly" "yearly"] }
def period-completer [] { ["event" "months" "weeks" "years"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-accounts-id: "record<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, is_net_worth: bool, primary_scenario: record<achieve_date: string, closing_balance: float, closing_balance_date: string, created_at: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, description: string, id: int, interest_rate: float, interest_rate_repeat_id: int, maximum-value: float, minimum-value: float, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, title: string, type: string, updated_at: string>, primary_transaction_account: record<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, institution: record<created_at: string, currency_code: string, id: int, title: string, updated_at: string>, name: string, number: string, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, type: string, updated_at: string>, safe_balance: float, safe_balance_in_base_currency: float, scenarios: table<achieve_date: string, closing_balance: float, closing_balance_date: string, created_at: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, description: string, id: int, interest_rate: float, interest_rate_repeat_id: int, maximum-value: float, minimum-value: float, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, title: string, type: string, updated_at: string>, title: string, transaction_accounts: table<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, institution: record, name: string, number: string, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, type: string, updated_at: string>, type: string, updated_at: string>"
    put-accounts-id: "record<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, is_net_worth: bool, primary_scenario: record<achieve_date: string, closing_balance: float, closing_balance_date: string, created_at: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, description: string, id: int, interest_rate: float, interest_rate_repeat_id: int, maximum-value: float, minimum-value: float, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, title: string, type: string, updated_at: string>, primary_transaction_account: record<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, institution: record<created_at: string, currency_code: string, id: int, title: string, updated_at: string>, name: string, number: string, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, type: string, updated_at: string>, safe_balance: float, safe_balance_in_base_currency: float, scenarios: table<achieve_date: string, closing_balance: float, closing_balance_date: string, created_at: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, description: string, id: int, interest_rate: float, interest_rate_repeat_id: int, maximum-value: float, minimum-value: float, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, title: string, type: string, updated_at: string>, title: string, transaction_accounts: table<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, institution: record, name: string, number: string, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, type: string, updated_at: string>, type: string, updated_at: string>"
    get-accounts-id-transactions: "table<amount: float, amount_in_base_currency: float, category: record<children: list, colour: string, created_at: string, id: int, is_bill: bool, is_transfer: bool, parent_id: int, refund_behaviour: string, roll_up: bool, title: string, updated_at: string>, cheque_number: string, closing_balance: float, created_at: string, date: string, id: int, is_transfer: bool, labels: list<string>, memo: string, needs_review: bool, note: string, original_payee: string, payee: string, status: string, transaction_account: record<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, institution: record, name: string, number: string, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, type: string, updated_at: string>, type: string, updated_at: string, upload_source: string>"
    get-attachments-id: "record<content_type: string, content_type_meta: record<description: string, extension: string, title: string>, created_at: string, file_name: string, id: int, original_url: string, title: string, type: string, updated_at: string, variants: record<large_url: string, thumb_url: string>>"
    put-attachments-id: "record<content_type: string, content_type_meta: record<description: string, extension: string, title: string>, created_at: string, file_name: string, id: int, original_url: string, title: string, type: string, updated_at: string, variants: record<large_url: string, thumb_url: string>>"
    get-categories-id: "record<children: list<any>, colour: string, created_at: string, id: int, is_bill: bool, is_transfer: bool, parent_id: int, refund_behaviour: string, roll_up: bool, title: string, updated_at: string>"
    put-categories-id: "record<children: list<any>, colour: string, created_at: string, id: int, is_bill: bool, is_transfer: bool, parent_id: int, refund_behaviour: string, roll_up: bool, title: string, updated_at: string>"
    post-categories-id-category-rules: "record<category: record<children: list<any>, colour: string, created_at: string, id: int, is_bill: bool, is_transfer: bool, parent_id: int, refund_behaviour: string, roll_up: bool, title: string, updated_at: string>, created_at: string, id: int, payee_matches: string, updated_at: string>"
    get-categories-id-transactions: "table<amount: float, amount_in_base_currency: float, category: record<children: list, colour: string, created_at: string, id: int, is_bill: bool, is_transfer: bool, parent_id: int, refund_behaviour: string, roll_up: bool, title: string, updated_at: string>, cheque_number: string, closing_balance: float, created_at: string, date: string, id: int, is_transfer: bool, labels: list<string>, memo: string, needs_review: bool, note: string, original_payee: string, payee: string, status: string, transaction_account: record<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, institution: record, name: string, number: string, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, type: string, updated_at: string>, type: string, updated_at: string, upload_source: string>"
    get-currencies: "table<id: string, minor_unit: int, name: string, separators: record<major: string, minor: string>, symbol: string>"
    get-currencies-id: "record<id: string, minor_unit: int, name: string, separators: record<major: string, minor: string>, symbol: string>"
    get-events-id: "record<amount: float, amount_in_base_currency: float, category: record<children: list<any>, colour: string, created_at: string, id: int, is_bill: bool, is_transfer: bool, parent_id: int, refund_behaviour: string, roll_up: bool, title: string, updated_at: string>, colour: string, currency_code: string, date: string, id: string, infinite_series: bool, note: string, repeat_interval: int, repeat_type: string, scenario: record<achieve_date: string, closing_balance: float, closing_balance_date: string, created_at: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, description: string, id: int, interest_rate: float, interest_rate_repeat_id: int, maximum-value: float, minimum-value: float, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, title: string, type: string, updated_at: string>, series_id: int, series_start_id: string>"
    put-events-id: "record<amount: float, amount_in_base_currency: float, category: record<children: list<any>, colour: string, created_at: string, id: int, is_bill: bool, is_transfer: bool, parent_id: int, refund_behaviour: string, roll_up: bool, title: string, updated_at: string>, colour: string, currency_code: string, date: string, id: string, infinite_series: bool, note: string, repeat_interval: int, repeat_type: string, scenario: record<achieve_date: string, closing_balance: float, closing_balance_date: string, created_at: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, description: string, id: int, interest_rate: float, interest_rate_repeat_id: int, maximum-value: float, minimum-value: float, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, title: string, type: string, updated_at: string>, series_id: int, series_start_id: string>"
    get-institutions-id: "record<created_at: string, currency_code: string, id: int, title: string, updated_at: string>"
    put-institutions-id: "record<created_at: string, currency_code: string, id: int, title: string, updated_at: string>"
    get-institutions-id-accounts: "table<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, is_net_worth: bool, primary_scenario: record<achieve_date: string, closing_balance: float, closing_balance_date: string, created_at: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, description: string, id: int, interest_rate: float, interest_rate_repeat_id: int, maximum-value: float, minimum-value: float, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, title: string, type: string, updated_at: string>, primary_transaction_account: record<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, institution: record, name: string, number: string, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, type: string, updated_at: string>, safe_balance: float, safe_balance_in_base_currency: float, scenarios: list<record>, title: string, transaction_accounts: list<record>, type: string, updated_at: string>"
    get-me: "record<always_show_base_currency: bool, available_accounts: int, available_budgets: int, avatar_url: string, base_currency_code: string, beta_user: bool, created_at: string, email: string, forecast_defer_recalculate: bool, forecast_end_date: string, forecast_last_accessed_at: string, forecast_last_updated_at: string, forecast_needs_recalculate: bool, forecast_start_date: string, id: int, is_reviewing_transactions: bool, last_activity_at: string, last_logged_in_at: string, login: string, name: string, time_zone: string, updated_at: string, using_multiple_currencies: bool, week_start_day: int>"
    get-scenarios-id-events: "table<amount: float, amount_in_base_currency: float, category: record<children: list, colour: string, created_at: string, id: int, is_bill: bool, is_transfer: bool, parent_id: int, refund_behaviour: string, roll_up: bool, title: string, updated_at: string>, colour: string, currency_code: string, date: string, id: string, infinite_series: bool, note: string, repeat_interval: int, repeat_type: string, scenario: record<achieve_date: string, closing_balance: float, closing_balance_date: string, created_at: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, description: string, id: int, interest_rate: float, interest_rate_repeat_id: int, maximum-value: float, minimum-value: float, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, title: string, type: string, updated_at: string>, series_id: int, series_start_id: string>"
    post-scenarios-id-events: "record<amount: float, amount_in_base_currency: float, category: record<children: list<any>, colour: string, created_at: string, id: int, is_bill: bool, is_transfer: bool, parent_id: int, refund_behaviour: string, roll_up: bool, title: string, updated_at: string>, colour: string, currency_code: string, date: string, id: string, infinite_series: bool, note: string, repeat_interval: int, repeat_type: string, scenario: record<achieve_date: string, closing_balance: float, closing_balance_date: string, created_at: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, description: string, id: int, interest_rate: float, interest_rate_repeat_id: int, maximum-value: float, minimum-value: float, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, title: string, type: string, updated_at: string>, series_id: int, series_start_id: string>"
    get-time-zones: "table<abbreviation: string, formatted_name: string, formatted_offset: string, identifier: string, name: string, utc_offset: int>"
    get-transaction-accounts-id: "record<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, institution: record<created_at: string, currency_code: string, id: int, title: string, updated_at: string>, name: string, number: string, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, type: string, updated_at: string>"
    put-transaction-accounts-id: "record<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, institution: record<created_at: string, currency_code: string, id: int, title: string, updated_at: string>, name: string, number: string, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, type: string, updated_at: string>"
    get-transaction-accounts-id-transactions: "table<amount: float, amount_in_base_currency: float, category: record<children: list, colour: string, created_at: string, id: int, is_bill: bool, is_transfer: bool, parent_id: int, refund_behaviour: string, roll_up: bool, title: string, updated_at: string>, cheque_number: string, closing_balance: float, created_at: string, date: string, id: int, is_transfer: bool, labels: list<string>, memo: string, needs_review: bool, note: string, original_payee: string, payee: string, status: string, transaction_account: record<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, institution: record, name: string, number: string, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, type: string, updated_at: string>, type: string, updated_at: string, upload_source: string>"
    post-transaction-accounts-id-transactions: "record<amount: float, amount_in_base_currency: float, category: record<children: list<any>, colour: string, created_at: string, id: int, is_bill: bool, is_transfer: bool, parent_id: int, refund_behaviour: string, roll_up: bool, title: string, updated_at: string>, cheque_number: string, closing_balance: float, created_at: string, date: string, id: int, is_transfer: bool, labels: list<string>, memo: string, needs_review: bool, note: string, original_payee: string, payee: string, status: string, transaction_account: record<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, institution: record<created_at: string, currency_code: string, id: int, title: string, updated_at: string>, name: string, number: string, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, type: string, updated_at: string>, type: string, updated_at: string, upload_source: string>"
    get-transactions-id: "record<amount: float, amount_in_base_currency: float, category: record<children: list<any>, colour: string, created_at: string, id: int, is_bill: bool, is_transfer: bool, parent_id: int, refund_behaviour: string, roll_up: bool, title: string, updated_at: string>, cheque_number: string, closing_balance: float, created_at: string, date: string, id: int, is_transfer: bool, labels: list<string>, memo: string, needs_review: bool, note: string, original_payee: string, payee: string, status: string, transaction_account: record<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, institution: record<created_at: string, currency_code: string, id: int, title: string, updated_at: string>, name: string, number: string, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, type: string, updated_at: string>, type: string, updated_at: string, upload_source: string>"
    put-transactions-id: "record<amount: float, amount_in_base_currency: float, category: record<children: list<any>, colour: string, created_at: string, id: int, is_bill: bool, is_transfer: bool, parent_id: int, refund_behaviour: string, roll_up: bool, title: string, updated_at: string>, cheque_number: string, closing_balance: float, created_at: string, date: string, id: int, is_transfer: bool, labels: list<string>, memo: string, needs_review: bool, note: string, original_payee: string, payee: string, status: string, transaction_account: record<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, institution: record<created_at: string, currency_code: string, id: int, title: string, updated_at: string>, name: string, number: string, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, type: string, updated_at: string>, type: string, updated_at: string, upload_source: string>"
    get-transactions-id-attachments: "table<content_type: string, content_type_meta: record<description: string, extension: string, title: string>, created_at: string, file_name: string, id: int, original_url: string, title: string, type: string, updated_at: string, variants: record<large_url: string, thumb_url: string>>"
    post-transactions-id-attachments: "record<content_type: string, content_type_meta: record<description: string, extension: string, title: string>, created_at: string, file_name: string, id: int, original_url: string, title: string, type: string, updated_at: string, variants: record<large_url: string, thumb_url: string>>"
    get-users-id: "record<always_show_base_currency: bool, available_accounts: int, available_budgets: int, avatar_url: string, base_currency_code: string, beta_user: bool, created_at: string, email: string, forecast_defer_recalculate: bool, forecast_end_date: string, forecast_last_accessed_at: string, forecast_last_updated_at: string, forecast_needs_recalculate: bool, forecast_start_date: string, id: int, is_reviewing_transactions: bool, last_activity_at: string, last_logged_in_at: string, login: string, name: string, time_zone: string, updated_at: string, using_multiple_currencies: bool, week_start_day: int>"
    put-users-id: "record<always_show_base_currency: bool, available_accounts: int, available_budgets: int, avatar_url: string, base_currency_code: string, beta_user: bool, created_at: string, email: string, forecast_defer_recalculate: bool, forecast_end_date: string, forecast_last_accessed_at: string, forecast_last_updated_at: string, forecast_needs_recalculate: bool, forecast_start_date: string, id: int, is_reviewing_transactions: bool, last_activity_at: string, last_logged_in_at: string, login: string, name: string, time_zone: string, updated_at: string, using_multiple_currencies: bool, week_start_day: int>"
    get-users-id-accounts: "table<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, is_net_worth: bool, primary_scenario: record<achieve_date: string, closing_balance: float, closing_balance_date: string, created_at: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, description: string, id: int, interest_rate: float, interest_rate_repeat_id: int, maximum-value: float, minimum-value: float, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, title: string, type: string, updated_at: string>, primary_transaction_account: record<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, institution: record, name: string, number: string, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, type: string, updated_at: string>, safe_balance: float, safe_balance_in_base_currency: float, scenarios: list<record>, title: string, transaction_accounts: list<record>, type: string, updated_at: string>"
    post-users-id-accounts: "record<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, is_net_worth: bool, primary_scenario: record<achieve_date: string, closing_balance: float, closing_balance_date: string, created_at: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, description: string, id: int, interest_rate: float, interest_rate_repeat_id: int, maximum-value: float, minimum-value: float, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, title: string, type: string, updated_at: string>, primary_transaction_account: record<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, institution: record<created_at: string, currency_code: string, id: int, title: string, updated_at: string>, name: string, number: string, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, type: string, updated_at: string>, safe_balance: float, safe_balance_in_base_currency: float, scenarios: table<achieve_date: string, closing_balance: float, closing_balance_date: string, created_at: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, description: string, id: int, interest_rate: float, interest_rate_repeat_id: int, maximum-value: float, minimum-value: float, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, title: string, type: string, updated_at: string>, title: string, transaction_accounts: table<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, institution: record, name: string, number: string, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, type: string, updated_at: string>, type: string, updated_at: string>"
    put-users-id-accounts: "table<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, is_net_worth: bool, primary_scenario: record<achieve_date: string, closing_balance: float, closing_balance_date: string, created_at: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, description: string, id: int, interest_rate: float, interest_rate_repeat_id: int, maximum-value: float, minimum-value: float, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, title: string, type: string, updated_at: string>, primary_transaction_account: record<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, institution: record, name: string, number: string, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, type: string, updated_at: string>, safe_balance: float, safe_balance_in_base_currency: float, scenarios: list<record>, title: string, transaction_accounts: list<record>, type: string, updated_at: string>"
    get-users-id-attachments: "table<content_type: string, content_type_meta: record<description: string, extension: string, title: string>, created_at: string, file_name: string, id: int, original_url: string, title: string, type: string, updated_at: string, variants: record<large_url: string, thumb_url: string>>"
    post-users-id-attachments: "record<content_type: string, content_type_meta: record<description: string, extension: string, title: string>, created_at: string, file_name: string, id: int, original_url: string, title: string, type: string, updated_at: string, variants: record<large_url: string, thumb_url: string>>"
    get-users-id-budget: "table<category: record<children: list, colour: string, created_at: string, id: int, is_bill: bool, is_transfer: bool, parent_id: int, refund_behaviour: string, roll_up: bool, title: string, updated_at: string>, expense: record<average_actual_amount: float, average_forecast_amount: float, currency_code: string, end_date: string, periods: list, start_date: string, total_actual_amount: float, total_forecast_amount: float, total_over_by: float, total_under_by: float>, income: record<average_actual_amount: float, average_forecast_amount: float, currency_code: string, end_date: string, periods: list, start_date: string, total_actual_amount: float, total_forecast_amount: float, total_over_by: float, total_under_by: float>, is_transfer: bool>"
    get-users-id-budget-summary: "table<category: record<children: list, colour: string, created_at: string, id: int, is_bill: bool, is_transfer: bool, parent_id: int, refund_behaviour: string, roll_up: bool, title: string, updated_at: string>, expense: record<average_actual_amount: float, average_forecast_amount: float, currency_code: string, end_date: string, periods: list, start_date: string, total_actual_amount: float, total_forecast_amount: float, total_over_by: float, total_under_by: float>, income: record<average_actual_amount: float, average_forecast_amount: float, currency_code: string, end_date: string, periods: list, start_date: string, total_actual_amount: float, total_forecast_amount: float, total_over_by: float, total_under_by: float>, is_transfer: bool>"
    get-users-id-categories: "table<children: list<any>, colour: string, created_at: string, id: int, is_bill: bool, is_transfer: bool, parent_id: int, refund_behaviour: string, roll_up: bool, title: string, updated_at: string>"
    post-users-id-categories: "record<children: list<any>, colour: string, created_at: string, id: int, is_bill: bool, is_transfer: bool, parent_id: int, refund_behaviour: string, roll_up: bool, title: string, updated_at: string>"
    get-users-id-category-rules: "table<category: record<children: list, colour: string, created_at: string, id: int, is_bill: bool, is_transfer: bool, parent_id: int, refund_behaviour: string, roll_up: bool, title: string, updated_at: string>, created_at: string, id: int, payee_matches: string, updated_at: string>"
    get-users-id-events: "table<amount: float, amount_in_base_currency: float, category: record<children: list, colour: string, created_at: string, id: int, is_bill: bool, is_transfer: bool, parent_id: int, refund_behaviour: string, roll_up: bool, title: string, updated_at: string>, colour: string, currency_code: string, date: string, id: string, infinite_series: bool, note: string, repeat_interval: int, repeat_type: string, scenario: record<achieve_date: string, closing_balance: float, closing_balance_date: string, created_at: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, description: string, id: int, interest_rate: float, interest_rate_repeat_id: int, maximum-value: float, minimum-value: float, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, title: string, type: string, updated_at: string>, series_id: int, series_start_id: string>"
    get-users-id-institutions: "table<created_at: string, currency_code: string, id: int, title: string, updated_at: string>"
    post-users-id-institutions: "record<created_at: string, currency_code: string, id: int, title: string, updated_at: string>"
    get-users-id-labels: "list<string>"
    get-users-id-saved-searches: "table<created_at: string, id: int, title: string, updated_at: string>"
    get-users-id-transaction-accounts: "table<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, institution: record<created_at: string, currency_code: string, id: int, title: string, updated_at: string>, name: string, number: string, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, type: string, updated_at: string>"
    get-users-id-transactions: "table<amount: float, amount_in_base_currency: float, category: record<children: list, colour: string, created_at: string, id: int, is_bill: bool, is_transfer: bool, parent_id: int, refund_behaviour: string, roll_up: bool, title: string, updated_at: string>, cheque_number: string, closing_balance: float, created_at: string, date: string, id: int, is_transfer: bool, labels: list<string>, memo: string, needs_review: bool, note: string, original_payee: string, payee: string, status: string, transaction_account: record<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, institution: record, name: string, number: string, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, type: string, updated_at: string>, type: string, updated_at: string, upload_source: string>"
    get-users-id-trend-analysis: "table<category: record<children: list, colour: string, created_at: string, id: int, is_bill: bool, is_transfer: bool, parent_id: int, refund_behaviour: string, roll_up: bool, title: string, updated_at: string>, expense: record<average_actual_amount: float, average_forecast_amount: float, currency_code: string, end_date: string, periods: list, start_date: string, total_actual_amount: float, total_forecast_amount: float, total_over_by: float, total_under_by: float>, income: record<average_actual_amount: float, average_forecast_amount: float, currency_code: string, end_date: string, periods: list, start_date: string, total_actual_amount: float, total_forecast_amount: float, total_over_by: float, total_under_by: float>, is_transfer: bool>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["delete-accounts-id" "get-accounts-id" "put-accounts-id" "get-accounts-id-transactions" "delete-attachments-id" "get-attachments-id" "put-attachments-id" "delete-categories-id" "get-categories-id" "put-categories-id" "post-categories-id-category-rules" "get-categories-id-transactions" "get-currencies" "get-currencies-id" "delete-events-id" "get-events-id" "put-events-id" "delete-institutions-id" "get-institutions-id" "put-institutions-id" "get-institutions-id-accounts" "get-me" "get-scenarios-id-events" "post-scenarios-id-events" "get-time-zones" "get-transaction-accounts-id" "put-transaction-accounts-id" "get-transaction-accounts-id-transactions" "post-transaction-accounts-id-transactions" "delete-transactions-id" "get-transactions-id" "put-transactions-id" "get-transactions-id-attachments" "post-transactions-id-attachments" "delete-transactions-transaction-id-attachments-attachment-id" "get-users-id" "put-users-id" "get-users-id-accounts" "post-users-id-accounts" "put-users-id-accounts" "get-users-id-attachments" "post-users-id-attachments" "get-users-id-budget" "get-users-id-budget-summary" "get-users-id-categories" "post-users-id-categories" "get-users-id-category-rules" "get-users-id-events" "delete-users-id-forecast-cache" "get-users-id-institutions" "post-users-id-institutions" "get-users-id-labels" "get-users-id-saved-searches" "get-users-id-transaction-accounts" "get-users-id-transactions" "get-users-id-trend-analysis" "commands"] | sort) } | get name | first)
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

# Delete account
#
# DELETE /accounts/{id}
export def "delete-accounts-id" [
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
    path: "/accounts/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-developer-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get account
#
# GET /accounts/{id}
# Returns: record<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, is_net_worth: bool, primary_scenario: record<achieve_date: string, closing_balance: float, closing_balance_date: string, created_at: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, description: string, id: int, interest_rate: float, interest_rate_repeat_id: int, maximum-value: float, minimum-value: float, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, title: string, type: string, updated_at: string>, primary_transaction_account: record<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, institution: record<created_at: string, currency_code: string, id: int, title: string, updated_at: string>, name: string, number: string, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, type: string, updated_at: string>, safe_balance: float, safe_balance_in_base_currency: float, scenarios: table<achieve_date: string, closing_balance: float, closing_balance_date: string, created_at: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, description: string, id: int, interest_rate: float, interest_rate_repeat_id: int, maximum-value: float, minimum-value: float, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, title: string, type: string, updated_at: string>, title: string, transaction_accounts: table<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, institution: record, name: string, number: string, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, type: string, updated_at: string>, type: string, updated_at: string>
export def "get-accounts-id" [
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
    path: "/accounts/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-developer-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update account
#
# PUT /accounts/{id}
# Returns: record<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, is_net_worth: bool, primary_scenario: record<achieve_date: string, closing_balance: float, closing_balance_date: string, created_at: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, description: string, id: int, interest_rate: float, interest_rate_repeat_id: int, maximum-value: float, minimum-value: float, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, title: string, type: string, updated_at: string>, primary_transaction_account: record<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, institution: record<created_at: string, currency_code: string, id: int, title: string, updated_at: string>, name: string, number: string, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, type: string, updated_at: string>, safe_balance: float, safe_balance_in_base_currency: float, scenarios: table<achieve_date: string, closing_balance: float, closing_balance_date: string, created_at: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, description: string, id: int, interest_rate: float, interest_rate_repeat_id: int, maximum-value: float, minimum-value: float, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, title: string, type: string, updated_at: string>, title: string, transaction_accounts: table<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, institution: record, name: string, number: string, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, type: string, updated_at: string>, type: string, updated_at: string>
export def "put-accounts-id" [
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
  --currency-code: string # A new currency code for the account. (e.g. NZD)
  --is-net-worth: oneof<nothing, bool> # Whether the account is a net worth account. (e.g. false)
  --title: string # A new title for the account. (e.g. Savings)
  --type: string@type-completer # The type of the account. (e.g. bank)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/accounts/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: currency_code, var: currency_code}, {name: is_net_worth, var: is_net_worth}, {name: title, var: title}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-developer-key
  } {
    id: $id, currency_code: $currency_code, is_net_worth: $is_net_worth, title: $title, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List transactions in account
#
# GET /accounts/{id}/transactions
# Returns: table<amount: float, amount_in_base_currency: float, category: record<children: list, colour: string, created_at: string, id: int, is_bill: bool, is_transfer: bool, parent_id: int, refund_behaviour: string, roll_up: bool, title: string, updated_at: string>, cheque_number: string, closing_balance: float, created_at: string, date: string, id: int, is_transfer: bool, labels: list<string>, memo: string, needs_review: bool, note: string, original_payee: string, payee: string, status: string, transaction_account: record<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, institution: record, name: string, number: string, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, type: string, updated_at: string>, type: string, updated_at: string, upload_source: string>
export def "get-accounts-id-transactions" [
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
  --start-date: string # Limit to transactions on or after this date. Required if end_date is provided. If not provided, defaults to the furtherest date allowed by the user's subscription. (e.g. 2016-11-01)
  --end-date: string # Limit to transactions on or before this date. Required if start_date is provided. If not provided, defaults to today's date. (e.g. 2016-11-30)
  --updated-since: string # Limit to transactions updated since an ISO 8601 timestamp. (e.g. 2020-10-14T09:20:33+13:00)
  --uncategorised: int # Limit to uncategorised transactions. (e.g. 1)
  --type: string@type-completer-1 # Limit to transactions of this type. (e.g. debit)
  --needs-review: int # Limit to transactions that need to be reviewed. (e.g. 1)
  --search: string # Limit to transactions matching a keyword search string. The provided string is matched against the transaction amount, account name, payee, category title, note, labels, and the date in ISO 8601 format. (e.g. Paypal)
  --page: int # Choose a particular page of the results. (e.g. 3)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/accounts/{id}/transactions"
    path_params: [{name: id, var: id}]
    query: [{name: start_date, var: start_date}, {name: end_date, var: end_date}, {name: updated_since, var: updated_since}, {name: uncategorised, var: uncategorised}, {name: type, var: type}, {name: needs_review, var: needs_review}, {name: search, var: search}, {name: page, var: page}]
    accept: ["application/json"]
    ok: [200]
    auth: x-developer-key
  } {
    id: $id, start_date: $start_date, end_date: $end_date, updated_since: $updated_since, uncategorised: $uncategorised, type: $type, needs_review: $needs_review, search: $search, page: $page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete attachment
#
# DELETE /attachments/{id}
export def "delete-attachments-id" [
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
    path: "/attachments/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-developer-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get attachment
#
# GET /attachments/{id}
# Returns: record<content_type: string, content_type_meta: record<description: string, extension: string, title: string>, created_at: string, file_name: string, id: int, original_url: string, title: string, type: string, updated_at: string, variants: record<large_url: string, thumb_url: string>>
export def "get-attachments-id" [
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
    path: "/attachments/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-developer-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update attachment
#
# PUT /attachments/{id}
# Returns: record<content_type: string, content_type_meta: record<description: string, extension: string, title: string>, created_at: string, file_name: string, id: int, original_url: string, title: string, type: string, updated_at: string, variants: record<large_url: string, thumb_url: string>>
export def "put-attachments-id" [
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
  --title: string # The new title of the attachment. If the title is blank or not provided, the server will derive a title from the file name. (e.g. Invoice for taxi)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/attachments/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: title, var: title}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-developer-key
  } {
    id: $id, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete category
#
# DELETE /categories/{id}
export def "delete-categories-id" [
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
    path: "/categories/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-developer-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get category
#
# GET /categories/{id}
# Returns: record<children: list<any>, colour: string, created_at: string, id: int, is_bill: bool, is_transfer: bool, parent_id: int, refund_behaviour: string, roll_up: bool, title: string, updated_at: string>
export def "get-categories-id" [
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
    path: "/categories/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-developer-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update category
#
# PUT /categories/{id}
# Returns: record<children: list<any>, colour: string, created_at: string, id: int, is_bill: bool, is_transfer: bool, parent_id: int, refund_behaviour: string, roll_up: bool, title: string, updated_at: string>
export def "put-categories-id" [
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
  --colour: string # A new CSS-style hex colour for the category. (e.g. #e0e7ff)
  --is-bill: oneof<nothing, bool> # Set the category as a bill category. (e.g. true)
  --is-transfer: oneof<nothing, bool> # Set the category as a transfer category. (e.g. false)
  --parent-id: int # The unique identifier of a parent category for the category, making this category a child of that category. (e.g. 42)
  --refund-behaviour: string@refund-behaviour-completer # Set the refund behaviour of the category. (nullable, e.g. credits_are_refunds)
  --roll-up: oneof<nothing, bool> # Set the category to be rolled up into its parent category. (e.g. false)
  --title: string # A new title for the category. (e.g. Food)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/categories/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: colour, var: colour}, {name: is_bill, var: is_bill}, {name: is_transfer, var: is_transfer}, {name: parent_id, var: parent_id}, {name: refund_behaviour, var: refund_behaviour}, {name: roll_up, var: roll_up}, {name: title, var: title}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-developer-key
  } {
    id: $id, colour: $colour, is_bill: $is_bill, is_transfer: $is_transfer, parent_id: $parent_id, refund_behaviour: $refund_behaviour, roll_up: $roll_up, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create category rule in category
#
# POST /categories/{id}/category_rules
# Returns: record<category: record<children: list<any>, colour: string, created_at: string, id: int, is_bill: bool, is_transfer: bool, parent_id: int, refund_behaviour: string, roll_up: bool, title: string, updated_at: string>, created_at: string, id: int, payee_matches: string, updated_at: string>
export def "post-categories-id-category-rules" [
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
  --apply-to-all: oneof<nothing, bool> # Apply the created category rule to all transactions. (e.g. false)
  --apply-to-uncategorised: oneof<nothing, bool> # Apply the created category rule to all uncategorised transactions. (e.g. true)
  payee_matches: string # The keyword/s to match the transaction payees. (e.g. Countdown)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/categories/{id}/category_rules"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: apply_to_all, var: apply_to_all}, {name: apply_to_uncategorised, var: apply_to_uncategorised}, {name: payee_matches, var: payee_matches}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-developer-key
  } {
    id: $id, apply_to_all: $apply_to_all, apply_to_uncategorised: $apply_to_uncategorised, payee_matches: $payee_matches
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List transactions in categories
#
# GET /categories/{id}/transactions
# Returns: table<amount: float, amount_in_base_currency: float, category: record<children: list, colour: string, created_at: string, id: int, is_bill: bool, is_transfer: bool, parent_id: int, refund_behaviour: string, roll_up: bool, title: string, updated_at: string>, cheque_number: string, closing_balance: float, created_at: string, date: string, id: int, is_transfer: bool, labels: list<string>, memo: string, needs_review: bool, note: string, original_payee: string, payee: string, status: string, transaction_account: record<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, institution: record, name: string, number: string, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, type: string, updated_at: string>, type: string, updated_at: string, upload_source: string>
export def "get-categories-id-transactions" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # Limit to transactions on or after this date. Required if end_date is provided. If not provided, defaults to the furtherest date allowed by the user's subscription. (e.g. 2016-11-01)
  --end-date: string # Limit to transactions on or before this date. Required if start_date is provided. If not provided, defaults to today's date. (e.g. 2016-11-30)
  --updated-since: string # Limit to transactions updated since an ISO 8601 timestamp. (e.g. 2020-10-14T09:20:33+13:00)
  --uncategorised: int # Limit to uncategorised transactions. (e.g. 1)
  --type: string@type-completer-1 # Limit to transactions of this type. (e.g. debit)
  --needs-review: int # Limit to transactions that need to be reviewed. (e.g. 1)
  --search: string # Limit to transactions matching a keyword search string. The provided string is matched against the transaction amount, account name, payee, category title, note, labels, and the date in ISO 8601 format. (e.g. Paypal)
  --page: int # Choose a particular page of the results. (e.g. 3)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/categories/{id}/transactions"
    path_params: [{name: id, var: id}]
    query: [{name: start_date, var: start_date}, {name: end_date, var: end_date}, {name: updated_since, var: updated_since}, {name: uncategorised, var: uncategorised}, {name: type, var: type}, {name: needs_review, var: needs_review}, {name: search, var: search}, {name: page, var: page}]
    accept: ["application/json"]
    ok: [200]
    auth: x-developer-key
  } {
    id: $id, start_date: $start_date, end_date: $end_date, updated_since: $updated_since, uncategorised: $uncategorised, type: $type, needs_review: $needs_review, search: $search, page: $page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List currencies
#
# GET /currencies
# Returns: table<id: string, minor_unit: int, name: string, separators: record<major: string, minor: string>, symbol: string>
export def "get-currencies" [
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
    path: "/currencies"
    accept: ["application/json"]
    ok: [200]
    auth: x-developer-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get currency
#
# GET /currencies/{id}
# Returns: record<id: string, minor_unit: int, name: string, separators: record<major: string, minor: string>, symbol: string>
export def "get-currencies-id" [
  id: string
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
    path: "/currencies/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-developer-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete event
#
# DELETE /events/{id}
export def "delete-events-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --behaviour: string@behaviour-completer # Whether the delete applies only to this event, to all events within the series from this event or to all events within the series. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/events/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: behaviour, var: behaviour, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: x-developer-key
  } {
    id: $id, behaviour: $behaviour
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get event
#
# GET /events/{id}
# Returns: record<amount: float, amount_in_base_currency: float, category: record<children: list<any>, colour: string, created_at: string, id: int, is_bill: bool, is_transfer: bool, parent_id: int, refund_behaviour: string, roll_up: bool, title: string, updated_at: string>, colour: string, currency_code: string, date: string, id: string, infinite_series: bool, note: string, repeat_interval: int, repeat_type: string, scenario: record<achieve_date: string, closing_balance: float, closing_balance_date: string, created_at: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, description: string, id: int, interest_rate: float, interest_rate_repeat_id: int, maximum-value: float, minimum-value: float, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, title: string, type: string, updated_at: string>, series_id: int, series_start_id: string>
export def "get-events-id" [
  id: string
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
    auth: x-developer-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update event
#
# PUT /events/{id}
# Returns: record<amount: float, amount_in_base_currency: float, category: record<children: list<any>, colour: string, created_at: string, id: int, is_bill: bool, is_transfer: bool, parent_id: int, refund_behaviour: string, roll_up: bool, title: string, updated_at: string>, colour: string, currency_code: string, date: string, id: string, infinite_series: bool, note: string, repeat_interval: int, repeat_type: string, scenario: record<achieve_date: string, closing_balance: float, closing_balance_date: string, created_at: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, description: string, id: int, interest_rate: float, interest_rate_repeat_id: int, maximum-value: float, minimum-value: float, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, title: string, type: string, updated_at: string>, series_id: int, series_start_id: string>
export def "put-events-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --amount: float # The amount of the event. A positive amount is a credit, and a negative amount is a debit. (e.g. 11.5)
  behaviour: string@behaviour-completer # Whether the update applies only to this event, to all events within the series from this event or to all events within the series. (e.g. all)
  --note: string # A note for the event. (e.g. Need more beer.)
  --repeat-interval: int # The repeat interval of the event. (e.g. 1)
  --repeat-type: string@repeat-type-completer # The repeat type of the event. (e.g. weekly)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/events/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: amount, var: amount}, {name: behaviour, var: behaviour}, {name: note, var: note}, {name: repeat_interval, var: repeat_interval}, {name: repeat_type, var: repeat_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-developer-key
  } {
    id: $id, amount: $amount, behaviour: $behaviour, note: $note, repeat_interval: $repeat_interval, repeat_type: $repeat_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete institution
#
# DELETE /institutions/{id}
export def "delete-institutions-id" [
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
  --merge-into-institution-id: int # The unique identifier of the institution to merge into. (e.g. 44)
]: nothing -> any {
  http-request {
    method: delete
    path: "/institutions/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: merge_into_institution_id, var: merge_into_institution_id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-developer-key
  } {
    id: $id, merge_into_institution_id: $merge_into_institution_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get institution
#
# GET /institutions/{id}
# Returns: record<created_at: string, currency_code: string, id: int, title: string, updated_at: string>
export def "get-institutions-id" [
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
    path: "/institutions/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-developer-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update institution
#
# PUT /institutions/{id}
# Returns: record<created_at: string, currency_code: string, id: int, title: string, updated_at: string>
export def "put-institutions-id" [
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
  --currency-code: string # A new currency code for the institution. (e.g. NZD)
  --title: string # A new title for the institution. (e.g. Bank of Foo)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/institutions/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: currency_code, var: currency_code}, {name: title, var: title}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-developer-key
  } {
    id: $id, currency_code: $currency_code, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List accounts in institution
#
# GET /institutions/{id}/accounts
# Returns: table<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, is_net_worth: bool, primary_scenario: record<achieve_date: string, closing_balance: float, closing_balance_date: string, created_at: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, description: string, id: int, interest_rate: float, interest_rate_repeat_id: int, maximum-value: float, minimum-value: float, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, title: string, type: string, updated_at: string>, primary_transaction_account: record<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, institution: record, name: string, number: string, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, type: string, updated_at: string>, safe_balance: float, safe_balance_in_base_currency: float, scenarios: list<record>, title: string, transaction_accounts: list<record>, type: string, updated_at: string>
export def "get-institutions-id-accounts" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/institutions/{id}/accounts"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-developer-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the authorised user
#
# GET /me
# Returns: record<always_show_base_currency: bool, available_accounts: int, available_budgets: int, avatar_url: string, base_currency_code: string, beta_user: bool, created_at: string, email: string, forecast_defer_recalculate: bool, forecast_end_date: string, forecast_last_accessed_at: string, forecast_last_updated_at: string, forecast_needs_recalculate: bool, forecast_start_date: string, id: int, is_reviewing_transactions: bool, last_activity_at: string, last_logged_in_at: string, login: string, name: string, time_zone: string, updated_at: string, using_multiple_currencies: bool, week_start_day: int>
export def "get-me" [
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
    path: "/me"
    accept: ["application/json"]
    ok: [200]
    auth: x-developer-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List events in scenario.
#
# GET /scenarios/{id}/events
# Returns: table<amount: float, amount_in_base_currency: float, category: record<children: list, colour: string, created_at: string, id: int, is_bill: bool, is_transfer: bool, parent_id: int, refund_behaviour: string, roll_up: bool, title: string, updated_at: string>, colour: string, currency_code: string, date: string, id: string, infinite_series: bool, note: string, repeat_interval: int, repeat_type: string, scenario: record<achieve_date: string, closing_balance: float, closing_balance_date: string, created_at: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, description: string, id: int, interest_rate: float, interest_rate_repeat_id: int, maximum-value: float, minimum-value: float, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, title: string, type: string, updated_at: string>, series_id: int, series_start_id: string>
export def "get-scenarios-id-events" [
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
  --start-date: string # Return the events from and including this date. (required, e.g. 2020-10-01)
  --end-date: string # Return the events until and including this date. (required, e.g. 2020-10-30)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/scenarios/{id}/events"
    path_params: [{name: id, var: id}]
    query: [{name: start_date, var: start_date, required: true}, {name: end_date, var: end_date, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: x-developer-key
  } {
    id: $id, start_date: $start_date, end_date: $end_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create event in scenario
#
# POST /scenarios/{id}/events
# Returns: record<amount: float, amount_in_base_currency: float, category: record<children: list<any>, colour: string, created_at: string, id: int, is_bill: bool, is_transfer: bool, parent_id: int, refund_behaviour: string, roll_up: bool, title: string, updated_at: string>, colour: string, currency_code: string, date: string, id: string, infinite_series: bool, note: string, repeat_interval: int, repeat_type: string, scenario: record<achieve_date: string, closing_balance: float, closing_balance_date: string, created_at: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, description: string, id: int, interest_rate: float, interest_rate_repeat_id: int, maximum-value: float, minimum-value: float, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, title: string, type: string, updated_at: string>, series_id: int, series_start_id: string>
export def "post-scenarios-id-events" [
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
  amount: float # The amount of the event. A positive amount is a credit, and a negative amount is a debit. (e.g. 11.5)
  category_id: int # The unique identifier of the category for the event. (e.g. 42)
  date: string # The starting date of the event. (e.g. 2020-10-27)
  --note: string # A note for the event. (e.g. New beers for sampling over the weekends.)
  --repeat-interval: int # The repeat interval of the event. (default: 1, e.g. 1)
  repeat_type: string@repeat-type-completer # The repeat type of the event. (e.g. weekly)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/scenarios/{id}/events"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: amount, var: amount}, {name: category_id, var: category_id}, {name: date, var: date}, {name: note, var: note}, {name: repeat_interval, var: repeat_interval}, {name: repeat_type, var: repeat_type}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-developer-key
  } {
    id: $id, amount: $amount, category_id: $category_id, date: $date, note: $note, repeat_interval: $repeat_interval, repeat_type: $repeat_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List time zones
#
# GET /time_zones
# Returns: table<abbreviation: string, formatted_name: string, formatted_offset: string, identifier: string, name: string, utc_offset: int>
export def "get-time-zones" [
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
    path: "/time_zones"
    accept: ["application/json"]
    ok: [200]
    auth: x-developer-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get transaction account
#
# GET /transaction_accounts/{id}
# Returns: record<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, institution: record<created_at: string, currency_code: string, id: int, title: string, updated_at: string>, name: string, number: string, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, type: string, updated_at: string>
export def "get-transaction-accounts-id" [
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
    path: "/transaction_accounts/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-developer-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update transaction account
#
# PUT /transaction_accounts/{id}
# Returns: record<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, institution: record<created_at: string, currency_code: string, id: int, title: string, updated_at: string>, name: string, number: string, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, type: string, updated_at: string>
export def "put-transaction-accounts-id" [
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
  --institution-id: int # The unique identifier of a new institution for the transaction account. (e.g. 42)
  --starting-balance: float # The starting balance amount of the transaction account. (e.g. 3547.45)
  --starting-balance-date: string # The starting balance date of the transaction account. (e.g. 2015-03-15)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/transaction_accounts/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: institution_id, var: institution_id}, {name: starting_balance, var: starting_balance}, {name: starting_balance_date, var: starting_balance_date}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-developer-key
  } {
    id: $id, institution_id: $institution_id, starting_balance: $starting_balance, starting_balance_date: $starting_balance_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List transactions in transaction account
#
# GET /transaction_accounts/{id}/transactions
# Returns: table<amount: float, amount_in_base_currency: float, category: record<children: list, colour: string, created_at: string, id: int, is_bill: bool, is_transfer: bool, parent_id: int, refund_behaviour: string, roll_up: bool, title: string, updated_at: string>, cheque_number: string, closing_balance: float, created_at: string, date: string, id: int, is_transfer: bool, labels: list<string>, memo: string, needs_review: bool, note: string, original_payee: string, payee: string, status: string, transaction_account: record<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, institution: record, name: string, number: string, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, type: string, updated_at: string>, type: string, updated_at: string, upload_source: string>
export def "get-transaction-accounts-id-transactions" [
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
  --start-date: string # Limit to transactions on or after this date. Required if end_date is provided. If not provided, defaults to the furtherest date allowed by the user's subscription. (e.g. 2016-11-01)
  --end-date: string # Limit to transactions on or before this date. Required if start_date is provided. If not provided, defaults to today's date. (e.g. 2016-11-30)
  --updated-since: string # Limit to transactions updated since an ISO 8601 timestamp. (e.g. 2020-10-14T09:20:33+13:00)
  --uncategorised: int # Limit to uncategorised transactions. (e.g. 1)
  --type: string@type-completer-1 # Limit to transactions of this type. (e.g. debit)
  --needs-review: int # Limit to transactions that need to be reviewed. (e.g. 1)
  --search: string # Limit to transactions matching a keyword search string. The provided string is matched against the transaction amount, account name, payee, category title, note, labels, and the date in ISO 8601 format. (e.g. Paypal)
  --page: int # Choose a particular page of the results. (e.g. 3)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/transaction_accounts/{id}/transactions"
    path_params: [{name: id, var: id}]
    query: [{name: start_date, var: start_date}, {name: end_date, var: end_date}, {name: updated_since, var: updated_since}, {name: uncategorised, var: uncategorised}, {name: type, var: type}, {name: needs_review, var: needs_review}, {name: search, var: search}, {name: page, var: page}]
    accept: ["application/json"]
    ok: [200]
    auth: x-developer-key
  } {
    id: $id, start_date: $start_date, end_date: $end_date, updated_since: $updated_since, uncategorised: $uncategorised, type: $type, needs_review: $needs_review, search: $search, page: $page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a transaction in transaction account
#
# POST /transaction_accounts/{id}/transactions
# Returns: record<amount: float, amount_in_base_currency: float, category: record<children: list<any>, colour: string, created_at: string, id: int, is_bill: bool, is_transfer: bool, parent_id: int, refund_behaviour: string, roll_up: bool, title: string, updated_at: string>, cheque_number: string, closing_balance: float, created_at: string, date: string, id: int, is_transfer: bool, labels: list<string>, memo: string, needs_review: bool, note: string, original_payee: string, payee: string, status: string, transaction_account: record<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, institution: record<created_at: string, currency_code: string, id: int, title: string, updated_at: string>, name: string, number: string, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, type: string, updated_at: string>, type: string, updated_at: string, upload_source: string>
export def "post-transaction-accounts-id-transactions" [
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
  amount: float # The amount of the transaction. A positive amount is a credit, and a negative amount is a debit. (e.g. 11.5)
  --category-id: int # The unique identifier of a category for the transaction. (e.g. 42)
  --cheque-number: string # A cheque number for the transaction.
  date: string # The date when the transaction occurred. (e.g. 2018-02-27)
  --is-transfer: oneof<nothing, bool> # Whether the transaction should be indicated as a transfer. (e.g. false)
  --labels: string # A set of comma-separated labels for the transaction. (e.g. lunch,mexican)
  --memo: string # A memo for the transaction.
  --needs-review: oneof<nothing, bool> # Whether the transaction needs to be reviewed or not. (e.g. false)
  --note: string # A note for the transaction. (e.g. I really enjoyed the loaded corn chips)
  payee: string # The payee/merchant of the transaction. (e.g. Tex Otago)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/transaction_accounts/{id}/transactions"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: amount, var: amount}, {name: category_id, var: category_id}, {name: cheque_number, var: cheque_number}, {name: date, var: date}, {name: is_transfer, var: is_transfer}, {name: labels, var: labels}, {name: memo, var: memo}, {name: needs_review, var: needs_review}, {name: note, var: note}, {name: payee, var: payee}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-developer-key
  } {
    id: $id, amount: $amount, category_id: $category_id, cheque_number: $cheque_number, date: $date, is_transfer: $is_transfer, labels: $labels, memo: $memo, needs_review: $needs_review, note: $note, payee: $payee
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete transaction
#
# DELETE /transactions/{id}
export def "delete-transactions-id" [
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
    path: "/transactions/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-developer-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a transaction
#
# GET /transactions/{id}
# Returns: record<amount: float, amount_in_base_currency: float, category: record<children: list<any>, colour: string, created_at: string, id: int, is_bill: bool, is_transfer: bool, parent_id: int, refund_behaviour: string, roll_up: bool, title: string, updated_at: string>, cheque_number: string, closing_balance: float, created_at: string, date: string, id: int, is_transfer: bool, labels: list<string>, memo: string, needs_review: bool, note: string, original_payee: string, payee: string, status: string, transaction_account: record<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, institution: record<created_at: string, currency_code: string, id: int, title: string, updated_at: string>, name: string, number: string, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, type: string, updated_at: string>, type: string, updated_at: string, upload_source: string>
export def "get-transactions-id" [
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
    path: "/transactions/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-developer-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a transaction
#
# PUT /transactions/{id}
# Returns: record<amount: float, amount_in_base_currency: float, category: record<children: list<any>, colour: string, created_at: string, id: int, is_bill: bool, is_transfer: bool, parent_id: int, refund_behaviour: string, roll_up: bool, title: string, updated_at: string>, cheque_number: string, closing_balance: float, created_at: string, date: string, id: int, is_transfer: bool, labels: list<string>, memo: string, needs_review: bool, note: string, original_payee: string, payee: string, status: string, transaction_account: record<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, institution: record<created_at: string, currency_code: string, id: int, title: string, updated_at: string>, name: string, number: string, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, type: string, updated_at: string>, type: string, updated_at: string, upload_source: string>
export def "put-transactions-id" [
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
  --amount: float # A new amount for the transaction. (e.g. 225)
  --category-id: int # The unique identifier of a new category for the transaction. (e.g. 42)
  --cheque-number: string # A new cheque number for the transaction. (e.g. 503113643691)
  --date: string # A new date for the transaction. (e.g. 2018-02-27)
  --is-transfer: oneof<nothing, bool> # Whether the transaction is a transfer or not. (e.g. false)
  --labels: string # A new comma-separated set of labels for the transaction. (e.g. foo,bar,baz)
  --memo: string # A new memo for the transaction. (e.g. Rent)
  --needs-review: oneof<nothing, bool> # Whether the transaction needs to be reviewed or not. (e.g. false)
  --note: string # A new note for the transaction.
  --payee: string # A new payee for the transaction. (e.g. Bill)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/transactions/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: amount, var: amount}, {name: category_id, var: category_id}, {name: cheque_number, var: cheque_number}, {name: date, var: date}, {name: is_transfer, var: is_transfer}, {name: labels, var: labels}, {name: memo, var: memo}, {name: needs_review, var: needs_review}, {name: note, var: note}, {name: payee, var: payee}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-developer-key
  } {
    id: $id, amount: $amount, category_id: $category_id, cheque_number: $cheque_number, date: $date, is_transfer: $is_transfer, labels: $labels, memo: $memo, needs_review: $needs_review, note: $note, payee: $payee
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List attachments in transaction
#
# GET /transactions/{id}/attachments
# Returns: table<content_type: string, content_type_meta: record<description: string, extension: string, title: string>, created_at: string, file_name: string, id: int, original_url: string, title: string, type: string, updated_at: string, variants: record<large_url: string, thumb_url: string>>
export def "get-transactions-id-attachments" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/transactions/{id}/attachments"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-developer-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Assigns attachment to transaction
#
# POST /transactions/{id}/attachments
# Returns: record<content_type: string, content_type_meta: record<description: string, extension: string, title: string>, created_at: string, file_name: string, id: int, original_url: string, title: string, type: string, updated_at: string, variants: record<large_url: string, thumb_url: string>>
export def "post-transactions-id-attachments" [
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
  --attachment-id: int # The unique identifier of the attachment. (e.g. 1438154)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/transactions/{id}/attachments"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: attachment_id, var: attachment_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-developer-key
  } {
    id: $id, attachment_id: $attachment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unassigns attachment in transaction
#
# DELETE /transactions/{transaction_id}/attachments/{attachment_id}
export def "delete-transactions-transaction-id-attachments-attachment-id" [
  transaction_id: int
  attachment_id: int
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
    path: "/transactions/{transaction_id}/attachments/{attachment_id}"
    path_params: [{name: transaction_id, var: transaction_id}, {name: attachment_id, var: attachment_id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-developer-key
  } {
    transaction_id: $transaction_id, attachment_id: $attachment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get user
#
# GET /users/{id}
# Returns: record<always_show_base_currency: bool, available_accounts: int, available_budgets: int, avatar_url: string, base_currency_code: string, beta_user: bool, created_at: string, email: string, forecast_defer_recalculate: bool, forecast_end_date: string, forecast_last_accessed_at: string, forecast_last_updated_at: string, forecast_needs_recalculate: bool, forecast_start_date: string, id: int, is_reviewing_transactions: bool, last_activity_at: string, last_logged_in_at: string, login: string, name: string, time_zone: string, updated_at: string, using_multiple_currencies: bool, week_start_day: int>
export def "get-users-id" [
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
    path: "/users/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-developer-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update user
#
# PUT /users/{id}
# Returns: record<always_show_base_currency: bool, available_accounts: int, available_budgets: int, avatar_url: string, base_currency_code: string, beta_user: bool, created_at: string, email: string, forecast_defer_recalculate: bool, forecast_end_date: string, forecast_last_accessed_at: string, forecast_last_updated_at: string, forecast_needs_recalculate: bool, forecast_start_date: string, id: int, is_reviewing_transactions: bool, last_activity_at: string, last_logged_in_at: string, login: string, name: string, time_zone: string, updated_at: string, using_multiple_currencies: bool, week_start_day: int>
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
  --always-show-base-currency: oneof<nothing, bool> # Whether the user wishes to have all monetary values converted to their base currency. (e.g. true)
  --base-currency-code: string # A new base currency code for the user. (e.g. nzd)
  --beta-user: oneof<nothing, bool> # Whether the user is a beta user, and wishes to try out new features. (e.g. true)
  --email: string # A new email address for the user. (e.g. foo@bar.com)
  --name: string # A new name for the user. (e.g. John Appleseed)
  --time-zone: string # A new time zone for the user. (e.g. Auckland)
  --week-start-day: int # The day of the week the user wishes their calendars to start on. A number between 0 and 6, where 0 is Sunday and 6 is Saturday. (e.g. 1)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/users/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: always_show_base_currency, var: always_show_base_currency}, {name: base_currency_code, var: base_currency_code}, {name: beta_user, var: beta_user}, {name: email, var: email}, {name: name, var: name}, {name: time_zone, var: time_zone}, {name: week_start_day, var: week_start_day}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-developer-key
  } {
    id: $id, always_show_base_currency: $always_show_base_currency, base_currency_code: $base_currency_code, beta_user: $beta_user, email: $email, name: $name, time_zone: $time_zone, week_start_day: $week_start_day
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List accounts in user
#
# GET /users/{id}/accounts
# Returns: table<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, is_net_worth: bool, primary_scenario: record<achieve_date: string, closing_balance: float, closing_balance_date: string, created_at: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, description: string, id: int, interest_rate: float, interest_rate_repeat_id: int, maximum-value: float, minimum-value: float, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, title: string, type: string, updated_at: string>, primary_transaction_account: record<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, institution: record, name: string, number: string, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, type: string, updated_at: string>, safe_balance: float, safe_balance_in_base_currency: float, scenarios: list<record>, title: string, transaction_accounts: list<record>, type: string, updated_at: string>
export def "get-users-id-accounts" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users/{id}/accounts"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-developer-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an account in user
#
# POST /users/{id}/accounts
# Returns: record<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, is_net_worth: bool, primary_scenario: record<achieve_date: string, closing_balance: float, closing_balance_date: string, created_at: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, description: string, id: int, interest_rate: float, interest_rate_repeat_id: int, maximum-value: float, minimum-value: float, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, title: string, type: string, updated_at: string>, primary_transaction_account: record<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, institution: record<created_at: string, currency_code: string, id: int, title: string, updated_at: string>, name: string, number: string, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, type: string, updated_at: string>, safe_balance: float, safe_balance_in_base_currency: float, scenarios: table<achieve_date: string, closing_balance: float, closing_balance_date: string, created_at: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, description: string, id: int, interest_rate: float, interest_rate_repeat_id: int, maximum-value: float, minimum-value: float, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, title: string, type: string, updated_at: string>, title: string, transaction_accounts: table<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, institution: record, name: string, number: string, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, type: string, updated_at: string>, type: string, updated_at: string>
export def "post-users-id-accounts" [
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
  currency_code: string # A currency code for the account. (e.g. NZD)
  institution_id: int # The ID of the institution to create this account in. (e.g. 42)
  title: string # A title for the account. (e.g. Foo)
  type: string@type-completer # The type of the account. (e.g. bank)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users/{id}/accounts"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: currency_code, var: currency_code}, {name: institution_id, var: institution_id}, {name: title, var: title}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-developer-key
  } {
    id: $id, currency_code: $currency_code, institution_id: $institution_id, title: $title, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the display order of accounts in user
#
# PUT /users/{id}/accounts
# Returns: table<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, is_net_worth: bool, primary_scenario: record<achieve_date: string, closing_balance: float, closing_balance_date: string, created_at: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, description: string, id: int, interest_rate: float, interest_rate_repeat_id: int, maximum-value: float, minimum-value: float, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, title: string, type: string, updated_at: string>, primary_transaction_account: record<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, institution: record, name: string, number: string, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, type: string, updated_at: string>, safe_balance: float, safe_balance_in_base_currency: float, scenarios: list<record>, title: string, transaction_accounts: list<record>, type: string, updated_at: string>
export def "put-users-id-accounts" [
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
  accounts: list # List the account objects in their new display order. — item shape: {created_at?: string, currency_code?: string, current_balance?: float, current_balance_date?: string, current_balance_exchange_rate?: float, current_balance_in_base_currency?: float, id?: int, is_net_worth?: bool, primary_scenario?: record, primary_transaction_account?: record, safe_balance?: float, safe_balance_in_base_currency?: float, scenarios?: list, title?: string, transaction_accounts?: list, ... (2 more fields)}
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: put
    path: "/users/{id}/accounts"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: accounts, var: accounts}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-developer-key
  } {
    id: $id, accounts: $accounts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists attachments in user
#
# GET /users/{id}/attachments
# Returns: table<content_type: string, content_type_meta: record<description: string, extension: string, title: string>, created_at: string, file_name: string, id: int, original_url: string, title: string, type: string, updated_at: string, variants: record<large_url: string, thumb_url: string>>
export def "get-users-id-attachments" [
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
  --unassigned: int # If set, returns unassigned attachments, that are available for assigning to a transaction. (e.g. 1)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users/{id}/attachments"
    path_params: [{name: id, var: id}]
    query: [{name: unassigned, var: unassigned}]
    accept: ["application/json"]
    ok: [200]
    auth: x-developer-key
  } {
    id: $id, unassigned: $unassigned
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create attachment in user
#
# POST /users/{id}/attachments
# Returns: record<content_type: string, content_type_meta: record<description: string, extension: string, title: string>, created_at: string, file_name: string, id: int, original_url: string, title: string, type: string, updated_at: string, variants: record<large_url: string, thumb_url: string>>
export def "post-users-id-attachments" [
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
  --file-data: string # The base64-encoded contents of the source file. The supported file types are png, jpg, pdf, xls, xlsx, doc, docx. (format: base64)
  --file-name: string # The file name of the attachment. (e.g. taxi.png)
  --title: string # The title of the attachment. If the title is blank or not provided, the title will derived from the file name. (e.g. Invoice for taxi)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users/{id}/attachments"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: file_data, var: file_data}, {name: file_name, var: file_name}, {name: title, var: title}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-developer-key
  } {
    id: $id, file_data: $file_data, file_name: $file_name, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List budget for user
#
# GET /users/{id}/budget
# Returns: table<category: record<children: list, colour: string, created_at: string, id: int, is_bill: bool, is_transfer: bool, parent_id: int, refund_behaviour: string, roll_up: bool, title: string, updated_at: string>, expense: record<average_actual_amount: float, average_forecast_amount: float, currency_code: string, end_date: string, periods: list, start_date: string, total_actual_amount: float, total_forecast_amount: float, total_over_by: float, total_under_by: float>, income: record<average_actual_amount: float, average_forecast_amount: float, currency_code: string, end_date: string, periods: list, start_date: string, total_actual_amount: float, total_forecast_amount: float, total_over_by: float, total_under_by: float>, is_transfer: bool>
export def "get-users-id-budget" [
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
  --roll-up: oneof<nothing, bool> # Whether parent categories should have their children rolled up into them. When used, the children will still appear in the collection on their own, but their actual and forecast figures will be rolled up to the root parent. (e.g. true)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users/{id}/budget"
    path_params: [{name: id, var: id}]
    query: [{name: roll_up, var: roll_up}]
    accept: ["application/json"]
    ok: [200]
    auth: x-developer-key
  } {
    id: $id, roll_up: $roll_up
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get budget summary for user
#
# GET /users/{id}/budget_summary
# Returns: table<category: record<children: list, colour: string, created_at: string, id: int, is_bill: bool, is_transfer: bool, parent_id: int, refund_behaviour: string, roll_up: bool, title: string, updated_at: string>, expense: record<average_actual_amount: float, average_forecast_amount: float, currency_code: string, end_date: string, periods: list, start_date: string, total_actual_amount: float, total_forecast_amount: float, total_over_by: float, total_under_by: float>, income: record<average_actual_amount: float, average_forecast_amount: float, currency_code: string, end_date: string, periods: list, start_date: string, total_actual_amount: float, total_forecast_amount: float, total_over_by: float, total_under_by: float>, is_transfer: bool>
export def "get-users-id-budget-summary" [
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
  --period: string@period-completer # The period to analyse in, one of `weeks`, `months` or `years`. Also supported is `event`, although event period analysis is only possible when the budget events gathered align, so in this case where all categories are analysed together, it's highly unlikely that event period analysis will be possible. (required, e.g. weeks)
  --interval: int # The period interval, e.g. if the interval is 2 and the period is weeks, the budget will be analysed fortnightly. (required, e.g. 2)
  --start-date: string # The date to start analysing the budget from. This will be bumped out to make full periods as necessary. (required, e.g. 2016-11-01)
  --end-date: string # The date to stop analysing the budget from. This will be bumped out to make full periods as necessary. (required, e.g. 2016-11-30)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users/{id}/budget_summary"
    path_params: [{name: id, var: id}]
    query: [{name: period, var: period, required: true}, {name: interval, var: interval, required: true}, {name: start_date, var: start_date, required: true}, {name: end_date, var: end_date, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: x-developer-key
  } {
    id: $id, period: $period, interval: $interval, start_date: $start_date, end_date: $end_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List categories in user
#
# GET /users/{id}/categories
# Returns: table<children: list<any>, colour: string, created_at: string, id: int, is_bill: bool, is_transfer: bool, parent_id: int, refund_behaviour: string, roll_up: bool, title: string, updated_at: string>
export def "get-users-id-categories" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users/{id}/categories"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-developer-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create category in user
#
# POST /users/{id}/categories
# Returns: record<children: list<any>, colour: string, created_at: string, id: int, is_bill: bool, is_transfer: bool, parent_id: int, refund_behaviour: string, roll_up: bool, title: string, updated_at: string>
export def "post-users-id-categories" [
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
  --colour: string # A CSS-style hex colour for the category. (e.g. #e0e7ff)
  --is-bill: oneof<nothing, bool> # Set the category as a bill category. (e.g. true)
  --is-transfer: oneof<nothing, bool> # Set the category as a transfer category. (e.g. false)
  --parent-id: int # The unique identifier of a category to be the parent of this category. (e.g. 42)
  --refund-behaviour: string@refund-behaviour-completer # Set the refund behaviour of the category. (nullable, e.g. credits_are_refunds)
  --roll-up: oneof<nothing, bool> # Set the category to be rolled up into its parent category. (e.g. false)
  title: string # A title for the category. (e.g. Food)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users/{id}/categories"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: colour, var: colour}, {name: is_bill, var: is_bill}, {name: is_transfer, var: is_transfer}, {name: parent_id, var: parent_id}, {name: refund_behaviour, var: refund_behaviour}, {name: roll_up, var: roll_up}, {name: title, var: title}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-developer-key
  } {
    id: $id, colour: $colour, is_bill: $is_bill, is_transfer: $is_transfer, parent_id: $parent_id, refund_behaviour: $refund_behaviour, roll_up: $roll_up, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List category rules in user
#
# GET /users/{id}/category_rules
# Returns: table<category: record<children: list, colour: string, created_at: string, id: int, is_bill: bool, is_transfer: bool, parent_id: int, refund_behaviour: string, roll_up: bool, title: string, updated_at: string>, created_at: string, id: int, payee_matches: string, updated_at: string>
export def "get-users-id-category-rules" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users/{id}/category_rules"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-developer-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List events in user.
#
# GET /users/{id}/events
# Returns: table<amount: float, amount_in_base_currency: float, category: record<children: list, colour: string, created_at: string, id: int, is_bill: bool, is_transfer: bool, parent_id: int, refund_behaviour: string, roll_up: bool, title: string, updated_at: string>, colour: string, currency_code: string, date: string, id: string, infinite_series: bool, note: string, repeat_interval: int, repeat_type: string, scenario: record<achieve_date: string, closing_balance: float, closing_balance_date: string, created_at: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, description: string, id: int, interest_rate: float, interest_rate_repeat_id: int, maximum-value: float, minimum-value: float, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, title: string, type: string, updated_at: string>, series_id: int, series_start_id: string>
export def "get-users-id-events" [
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
  --start-date: string # Return the events from and including this date. (required, e.g. 2020-10-01)
  --end-date: string # Return the events until and including this date. (required, e.g. 2020-10-30)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users/{id}/events"
    path_params: [{name: id, var: id}]
    query: [{name: start_date, var: start_date, required: true}, {name: end_date, var: end_date, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: x-developer-key
  } {
    id: $id, start_date: $start_date, end_date: $end_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete forecast cache for user
#
# DELETE /users/{id}/forecast_cache
export def "delete-users-id-forecast-cache" [
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
    path: "/users/{id}/forecast_cache"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-developer-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List institutions in user
#
# GET /users/{id}/institutions
# Returns: table<created_at: string, currency_code: string, id: int, title: string, updated_at: string>
export def "get-users-id-institutions" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users/{id}/institutions"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-developer-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create institution in user
#
# POST /users/{id}/institutions
# Returns: record<created_at: string, currency_code: string, id: int, title: string, updated_at: string>
export def "post-users-id-institutions" [
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
  currency_code: string # A currency code for the institution. (e.g. NZD)
  title: string # A title for the institution. (e.g. Bank of Foo)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users/{id}/institutions"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: currency_code, var: currency_code}, {name: title, var: title}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-developer-key
  } {
    id: $id, currency_code: $currency_code, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List labels in user
#
# GET /users/{id}/labels
# Returns: list<string>
export def "get-users-id-labels" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users/{id}/labels"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-developer-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List saved searches in user
#
# GET /users/{id}/saved_searches
# Returns: table<created_at: string, id: int, title: string, updated_at: string>
export def "get-users-id-saved-searches" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users/{id}/saved_searches"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-developer-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List transaction accounts in user
#
# GET /users/{id}/transaction_accounts
# Returns: table<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, institution: record<created_at: string, currency_code: string, id: int, title: string, updated_at: string>, name: string, number: string, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, type: string, updated_at: string>
export def "get-users-id-transaction-accounts" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users/{id}/transaction_accounts"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-developer-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List transactions in user
#
# GET /users/{id}/transactions
# Returns: table<amount: float, amount_in_base_currency: float, category: record<children: list, colour: string, created_at: string, id: int, is_bill: bool, is_transfer: bool, parent_id: int, refund_behaviour: string, roll_up: bool, title: string, updated_at: string>, cheque_number: string, closing_balance: float, created_at: string, date: string, id: int, is_transfer: bool, labels: list<string>, memo: string, needs_review: bool, note: string, original_payee: string, payee: string, status: string, transaction_account: record<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, institution: record, name: string, number: string, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, type: string, updated_at: string>, type: string, updated_at: string, upload_source: string>
export def "get-users-id-transactions" [
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
  --start-date: string # Limit to transactions on or after this date. Required if end_date is provided. If not provided, defaults to the furtherest date allowed by the user's subscription. (e.g. 2016-11-01)
  --end-date: string # Limit to transactions on or before this date. Required if start_date is provided. If not provided, defaults to today's date. (e.g. 2016-11-30)
  --updated-since: string # Limit to transactions updated since an ISO 8601 timestamp. (e.g. 2020-10-14T09:20:33+13:00)
  --uncategorised: int # Limit to uncategorised transactions. (e.g. 1)
  --type: string@type-completer-1 # Limit to transactions of this type. (e.g. debit)
  --needs-review: int # Limit to transactions that need to be reviewed. (e.g. 1)
  --search: string # Limit to transactions matching a keyword search string. The provided string is matched against the transaction amount, account name, payee, category title, note, labels, and the date in ISO 8601 format. (e.g. Paypal)
  --page: int # Choose a particular page of the results. (e.g. 3)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users/{id}/transactions"
    path_params: [{name: id, var: id}]
    query: [{name: start_date, var: start_date}, {name: end_date, var: end_date}, {name: updated_since, var: updated_since}, {name: uncategorised, var: uncategorised}, {name: type, var: type}, {name: needs_review, var: needs_review}, {name: search, var: search}, {name: page, var: page}]
    accept: ["application/json"]
    ok: [200]
    auth: x-developer-key
  } {
    id: $id, start_date: $start_date, end_date: $end_date, updated_since: $updated_since, uncategorised: $uncategorised, type: $type, needs_review: $needs_review, search: $search, page: $page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get trend analysis for user
#
# GET /users/{id}/trend_analysis
# Returns: table<category: record<children: list, colour: string, created_at: string, id: int, is_bill: bool, is_transfer: bool, parent_id: int, refund_behaviour: string, roll_up: bool, title: string, updated_at: string>, expense: record<average_actual_amount: float, average_forecast_amount: float, currency_code: string, end_date: string, periods: list, start_date: string, total_actual_amount: float, total_forecast_amount: float, total_over_by: float, total_under_by: float>, income: record<average_actual_amount: float, average_forecast_amount: float, currency_code: string, end_date: string, periods: list, start_date: string, total_actual_amount: float, total_forecast_amount: float, total_over_by: float, total_under_by: float>, is_transfer: bool>
export def "get-users-id-trend-analysis" [
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
  --period: string@period-completer # The period to analyse in, one of `weeks`, `months` or `years`. Also supported is `event`, although event period analysis is only possible when the budget events gathered align, so in this case where all categories are analysed together, it's highly unlikely that event period analysis will be possible. (required, e.g. weeks)
  --interval: int # The period interval, e.g. if the interval is 2 and the period is weeks, the budget will be analysed fortnightly. (required, e.g. true)
  --start-date: string # The date to start analysing the budget from. This will be bumped out to make full periods as necessary. (required, e.g. 2016-11-01)
  --end-date: string # The date to stop analysing the budget from. This will be bumped out to make full periods as necessary. (required, e.g. 2016-11-30)
  --categories: string # A comma-separated list of category IDs to analyse. (required, e.g. 42,49)
  --scenarios: string # A comma-separated list of scenario IDs to analyse. You're likely going to want to include all a user's scenarios here, unless you have reason to only analyse for a subset of scenarios. Regardless of what scenarios are analysed, all actuals (transactions) across all accounts will be included. (required, e.g. 11,29)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users/{id}/trend_analysis"
    path_params: [{name: id, var: id}]
    query: [{name: period, var: period, required: true}, {name: interval, var: interval, required: true}, {name: start_date, var: start_date, required: true}, {name: end_date, var: end_date, required: true}, {name: categories, var: categories, required: true}, {name: scenarios, var: scenarios, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: x-developer-key
  } {
    id: $id, period: $period, interval: $interval, start_date: $start_date, end_date: $end_date, categories: $categories, scenarios: $scenarios
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
