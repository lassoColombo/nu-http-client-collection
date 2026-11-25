# Auto-generated client for Google Workspace Reseller API v1
# Source: https://api.apis.guru/v2/specs/googleapis.com/reseller/v1/openapi.json
# Auth: --token flag or $env.GOOGLE_WORKSPACE_RESELLER_API_TOKEN

const CLIENT = {
  base_url: "https://reseller.googleapis.com"
  token_env_var: "GOOGLE_WORKSPACE_RESELLER_API_TOKEN"
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

def base-url-completer [] { ["https://reseller.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def customer-type-completer [] { ["customerTypeUnspecified" "domain" "team"] }
def deletion-type-completer [] { ["cancel" "deletion_type_undefined" "transfer_to_direct"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    reseller-customers-insert: "record<alternateEmail: string, customerDomain: string, customerDomainVerified: bool, customerId: string, customerType: string, kind: string, phoneNumber: string, postalAddress: record<addressLine1: string, addressLine2: string, addressLine3: string, contactName: string, countryCode: string, kind: string, locality: string, organizationName: string, postalCode: string, region: string>, primaryAdmin: record<primaryEmail: string>, resourceUiUrl: string>"
    reseller-customers-get: "record<alternateEmail: string, customerDomain: string, customerDomainVerified: bool, customerId: string, customerType: string, kind: string, phoneNumber: string, postalAddress: record<addressLine1: string, addressLine2: string, addressLine3: string, contactName: string, countryCode: string, kind: string, locality: string, organizationName: string, postalCode: string, region: string>, primaryAdmin: record<primaryEmail: string>, resourceUiUrl: string>"
    reseller-customers-patch: "record<alternateEmail: string, customerDomain: string, customerDomainVerified: bool, customerId: string, customerType: string, kind: string, phoneNumber: string, postalAddress: record<addressLine1: string, addressLine2: string, addressLine3: string, contactName: string, countryCode: string, kind: string, locality: string, organizationName: string, postalCode: string, region: string>, primaryAdmin: record<primaryEmail: string>, resourceUiUrl: string>"
    reseller-customers-update: "record<alternateEmail: string, customerDomain: string, customerDomainVerified: bool, customerId: string, customerType: string, kind: string, phoneNumber: string, postalAddress: record<addressLine1: string, addressLine2: string, addressLine3: string, contactName: string, countryCode: string, kind: string, locality: string, organizationName: string, postalCode: string, region: string>, primaryAdmin: record<primaryEmail: string>, resourceUiUrl: string>"
    reseller-subscriptions-insert: "record<billingMethod: string, creationTime: string, customerDomain: string, customerId: string, dealCode: string, kind: string, plan: record<commitmentInterval: record<endTime: string, startTime: string>, isCommitmentPlan: bool, planName: string>, purchaseOrderId: string, renewalSettings: record<kind: string, renewalType: string>, resourceUiUrl: string, seats: record<kind: string, licensedNumberOfSeats: int, maximumNumberOfSeats: int, numberOfSeats: int>, skuId: string, skuName: string, status: string, subscriptionId: string, suspensionReasons: list<string>, transferInfo: record<currentLegacySkuId: string, minimumTransferableSeats: int, transferabilityExpirationTime: string>, trialSettings: record<isInTrial: bool, trialEndTime: string>>"
    reseller-subscriptions-get: "record<billingMethod: string, creationTime: string, customerDomain: string, customerId: string, dealCode: string, kind: string, plan: record<commitmentInterval: record<endTime: string, startTime: string>, isCommitmentPlan: bool, planName: string>, purchaseOrderId: string, renewalSettings: record<kind: string, renewalType: string>, resourceUiUrl: string, seats: record<kind: string, licensedNumberOfSeats: int, maximumNumberOfSeats: int, numberOfSeats: int>, skuId: string, skuName: string, status: string, subscriptionId: string, suspensionReasons: list<string>, transferInfo: record<currentLegacySkuId: string, minimumTransferableSeats: int, transferabilityExpirationTime: string>, trialSettings: record<isInTrial: bool, trialEndTime: string>>"
    reseller-subscriptions-activate: "record<billingMethod: string, creationTime: string, customerDomain: string, customerId: string, dealCode: string, kind: string, plan: record<commitmentInterval: record<endTime: string, startTime: string>, isCommitmentPlan: bool, planName: string>, purchaseOrderId: string, renewalSettings: record<kind: string, renewalType: string>, resourceUiUrl: string, seats: record<kind: string, licensedNumberOfSeats: int, maximumNumberOfSeats: int, numberOfSeats: int>, skuId: string, skuName: string, status: string, subscriptionId: string, suspensionReasons: list<string>, transferInfo: record<currentLegacySkuId: string, minimumTransferableSeats: int, transferabilityExpirationTime: string>, trialSettings: record<isInTrial: bool, trialEndTime: string>>"
    reseller-subscriptions-change-plan: "record<billingMethod: string, creationTime: string, customerDomain: string, customerId: string, dealCode: string, kind: string, plan: record<commitmentInterval: record<endTime: string, startTime: string>, isCommitmentPlan: bool, planName: string>, purchaseOrderId: string, renewalSettings: record<kind: string, renewalType: string>, resourceUiUrl: string, seats: record<kind: string, licensedNumberOfSeats: int, maximumNumberOfSeats: int, numberOfSeats: int>, skuId: string, skuName: string, status: string, subscriptionId: string, suspensionReasons: list<string>, transferInfo: record<currentLegacySkuId: string, minimumTransferableSeats: int, transferabilityExpirationTime: string>, trialSettings: record<isInTrial: bool, trialEndTime: string>>"
    reseller-subscriptions-change-renewal-settings: "record<billingMethod: string, creationTime: string, customerDomain: string, customerId: string, dealCode: string, kind: string, plan: record<commitmentInterval: record<endTime: string, startTime: string>, isCommitmentPlan: bool, planName: string>, purchaseOrderId: string, renewalSettings: record<kind: string, renewalType: string>, resourceUiUrl: string, seats: record<kind: string, licensedNumberOfSeats: int, maximumNumberOfSeats: int, numberOfSeats: int>, skuId: string, skuName: string, status: string, subscriptionId: string, suspensionReasons: list<string>, transferInfo: record<currentLegacySkuId: string, minimumTransferableSeats: int, transferabilityExpirationTime: string>, trialSettings: record<isInTrial: bool, trialEndTime: string>>"
    reseller-subscriptions-change-seats: "record<billingMethod: string, creationTime: string, customerDomain: string, customerId: string, dealCode: string, kind: string, plan: record<commitmentInterval: record<endTime: string, startTime: string>, isCommitmentPlan: bool, planName: string>, purchaseOrderId: string, renewalSettings: record<kind: string, renewalType: string>, resourceUiUrl: string, seats: record<kind: string, licensedNumberOfSeats: int, maximumNumberOfSeats: int, numberOfSeats: int>, skuId: string, skuName: string, status: string, subscriptionId: string, suspensionReasons: list<string>, transferInfo: record<currentLegacySkuId: string, minimumTransferableSeats: int, transferabilityExpirationTime: string>, trialSettings: record<isInTrial: bool, trialEndTime: string>>"
    reseller-subscriptions-start-paid-service: "record<billingMethod: string, creationTime: string, customerDomain: string, customerId: string, dealCode: string, kind: string, plan: record<commitmentInterval: record<endTime: string, startTime: string>, isCommitmentPlan: bool, planName: string>, purchaseOrderId: string, renewalSettings: record<kind: string, renewalType: string>, resourceUiUrl: string, seats: record<kind: string, licensedNumberOfSeats: int, maximumNumberOfSeats: int, numberOfSeats: int>, skuId: string, skuName: string, status: string, subscriptionId: string, suspensionReasons: list<string>, transferInfo: record<currentLegacySkuId: string, minimumTransferableSeats: int, transferabilityExpirationTime: string>, trialSettings: record<isInTrial: bool, trialEndTime: string>>"
    reseller-subscriptions-suspend: "record<billingMethod: string, creationTime: string, customerDomain: string, customerId: string, dealCode: string, kind: string, plan: record<commitmentInterval: record<endTime: string, startTime: string>, isCommitmentPlan: bool, planName: string>, purchaseOrderId: string, renewalSettings: record<kind: string, renewalType: string>, resourceUiUrl: string, seats: record<kind: string, licensedNumberOfSeats: int, maximumNumberOfSeats: int, numberOfSeats: int>, skuId: string, skuName: string, status: string, subscriptionId: string, suspensionReasons: list<string>, transferInfo: record<currentLegacySkuId: string, minimumTransferableSeats: int, transferabilityExpirationTime: string>, trialSettings: record<isInTrial: bool, trialEndTime: string>>"
    reseller-resellernotify-getwatchdetails: "record<serviceAccountEmailAddresses: list<string>, topicName: string>"
    reseller-resellernotify-register: "record<topicName: string>"
    reseller-resellernotify-unregister: "record<topicName: string>"
    reseller-subscriptions-list: "record<kind: string, nextPageToken: string, subscriptions: table<billingMethod: string, creationTime: string, customerDomain: string, customerId: string, dealCode: string, kind: string, plan: record, purchaseOrderId: string, renewalSettings: record, resourceUiUrl: string, seats: record, skuId: string, skuName: string, status: string, subscriptionId: string, suspensionReasons: list, transferInfo: record, trialSettings: record>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["reseller-customers-insert" "reseller-customers-get" "reseller-customers-patch" "reseller-customers-update" "reseller-subscriptions-insert" "reseller-subscriptions-delete" "reseller-subscriptions-get" "reseller-subscriptions-activate" "reseller-subscriptions-change-plan" "reseller-subscriptions-change-renewal-settings" "reseller-subscriptions-change-seats" "reseller-subscriptions-start-paid-service" "reseller-subscriptions-suspend" "reseller-resellernotify-getwatchdetails" "reseller-resellernotify-register" "reseller-resellernotify-unregister" "reseller-subscriptions-list" "commands"] | sort) } | get name | first)
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

# Orders a new customer's account. Before ordering a new customer account, establish whether the customer account already exists using the [`customers.get`](/admin-sdk/reseller/v1/reference/customers/get) If the customer account exists as a direct Google account or as a resold customer account from another reseller, use the `customerAuthToken\` as described in [order a resold account for an existing customer](/admin-sdk/reseller/v1/how-tos/manage_customers#create_existing_customer). For more information about ordering a new customer account, see [order a new customer account](/admin-sdk/reseller/v1/how-tos/manage_customers#create_customer). After creating a new customer account, you must provision a user as an administrator. The customer's administrator is required to sign in to the Admin console and sign the G Suite via Reseller agreement to activate the account. Resellers are prohibited from signing the G Suite via Reseller agreement on the customer's behalf. For more information, see [order a new customer account](/admin-sdk/reseller/v1/how-tos/manage_customers#tos).
#
# POST /apps/reseller/v1/customers
# Returns: record<alternateEmail: string, customerDomain: string, customerDomainVerified: bool, customerId: string, customerType: string, kind: string, phoneNumber: string, postalAddress: record<addressLine1: string, addressLine2: string, addressLine3: string, contactName: string, countryCode: string, kind: string, locality: string, organizationName: string, postalCode: string, region: string>, primaryAdmin: record<primaryEmail: string>, resourceUiUrl: string>
# operationId: reseller.customers.insert
export def "reseller-customers-insert" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --customer-auth-token: string # The `customerAuthToken` query string is required when creating a resold account that transfers a direct customer's subscription or transfers another reseller customer's subscription to your reseller management. This is a hexadecimal authentication token needed to complete the subscription transfer. For more information, see the administrator help center.
  --alternate-email: string # Like the "Customer email" in the reseller tools, this email is the secondary contact used if something happens to the customer's service such as service outage or a security issue. This property is required when creating a new "domain" customer and should not use the same domain as `customerDomain`. The `alternateEmail` field is not necessary to create a "team" customer.
  --customer-domain: string # The customer's primary domain name string. `customerDomain` is required when creating a new customer. Do not include the `www` prefix in the domain when adding a customer.
  --customer-domain-verified: oneof<nothing, bool> # Whether the customer's primary domain has been verified.
  --customer-id: string # This property will always be returned in a response as the unique identifier generated by Google. In a request, this property can be either the primary domain or the unique identifier generated by Google.
  --customer-type: string@customer-type-completer # Identifies the type of the customer. Acceptable values include: * `domain`: Implies a domain-verified customer (default). * `team`: Implies an email-verified customer. For more information, see [managed teams](https://support.google.com/a/users/answer/9939479).
  --kind: string # Identifies the resource as a customer. Value: `reseller#customer` (default: reseller#customer)
  --phone-number: string # Customer contact phone number. Must start with "+" followed by the country code. The rest of the number can be contiguous numbers or respect the phone local format conventions, but it must be a real phone number and not, for example, "123". This field is silently ignored if invalid.
  --postal-address: record # JSON template for address of a customer. — shape: {addressLine1?: string, addressLine2?: string, addressLine3?: string, contactName?: string, countryCode?: string, kind?: string, locality?: string, organizationName?: string, postalCode?: string, region?: string}
  --primary-admin: record # JSON template for primary admin in case of TEAM customers — shape: {primaryEmail?: string}
  --resource-ui-url: string # URL to customer's Admin console dashboard. The read-only URL is generated by the API service. This is used if your client application requires the customer to complete a task in the Admin console.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/apps/reseller/v1/customers"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: customerAuthToken, var: customer_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: alternateEmail, var: alternate_email}, {name: customerDomain, var: customer_domain}, {name: customerDomainVerified, var: customer_domain_verified}, {name: customerId, var: customer_id}, {name: customerType, var: customer_type}, {name: kind, var: kind}, {name: phoneNumber, var: phone_number}, {name: postalAddress, var: postal_address}, {name: primaryAdmin, var: primary_admin}, {name: resourceUiUrl, var: resource_ui_url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, customer_auth_token: $customer_auth_token, alternate_email: $alternate_email, customer_domain: $customer_domain, customer_domain_verified: $customer_domain_verified, customer_id: $customer_id, customer_type: $customer_type, kind: $kind, phone_number: $phone_number, postal_address: $postal_address, primary_admin: $primary_admin, resource_ui_url: $resource_ui_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a customer account. Use this operation to see a customer account already in your reseller management, or to see the minimal account information for an existing customer that you do not manage. For more information about the API response for existing customers, see [retrieving a customer account](/admin-sdk/reseller/v1/how-tos/manage_customers#get_customer).
#
# GET /apps/reseller/v1/customers/{customerId}
# Returns: record<alternateEmail: string, customerDomain: string, customerDomainVerified: bool, customerId: string, customerType: string, kind: string, phoneNumber: string, postalAddress: record<addressLine1: string, addressLine2: string, addressLine3: string, contactName: string, countryCode: string, kind: string, locality: string, organizationName: string, postalCode: string, region: string>, primaryAdmin: record<primaryEmail: string>, resourceUiUrl: string>
# operationId: reseller.customers.get
export def "reseller-customers-get" [
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/apps/reseller/v1/customers/{customerId}"
    path_params: [{name: customerId, var: customer_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer_id: $customer_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a customer account's settings. This method supports patch semantics. You cannot update `customerType` via the Reseller API, but a `"team"` customer can verify their domain and become `customerType = "domain"`. For more information, see [Verify your domain to unlock Essentials features](https://support.google.com/a/answer/9122284).
#
# PATCH /apps/reseller/v1/customers/{customerId}
# Returns: record<alternateEmail: string, customerDomain: string, customerDomainVerified: bool, customerId: string, customerType: string, kind: string, phoneNumber: string, postalAddress: record<addressLine1: string, addressLine2: string, addressLine3: string, contactName: string, countryCode: string, kind: string, locality: string, organizationName: string, postalCode: string, region: string>, primaryAdmin: record<primaryEmail: string>, resourceUiUrl: string>
# operationId: reseller.customers.patch
export def "reseller-customers-patch" [
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --alternate-email: string # Like the "Customer email" in the reseller tools, this email is the secondary contact used if something happens to the customer's service such as service outage or a security issue. This property is required when creating a new "domain" customer and should not use the same domain as `customerDomain`. The `alternateEmail` field is not necessary to create a "team" customer.
  --customer-domain: string # The customer's primary domain name string. `customerDomain` is required when creating a new customer. Do not include the `www` prefix in the domain when adding a customer.
  --customer-domain-verified: oneof<nothing, bool> # Whether the customer's primary domain has been verified.
  --body-customer-id: string # This property will always be returned in a response as the unique identifier generated by Google. In a request, this property can be either the primary domain or the unique identifier generated by Google. (spec name: customerId)
  --customer-type: string@customer-type-completer # Identifies the type of the customer. Acceptable values include: * `domain`: Implies a domain-verified customer (default). * `team`: Implies an email-verified customer. For more information, see [managed teams](https://support.google.com/a/users/answer/9939479).
  --kind: string # Identifies the resource as a customer. Value: `reseller#customer` (default: reseller#customer)
  --phone-number: string # Customer contact phone number. Must start with "+" followed by the country code. The rest of the number can be contiguous numbers or respect the phone local format conventions, but it must be a real phone number and not, for example, "123". This field is silently ignored if invalid.
  --postal-address: record # JSON template for address of a customer. — shape: {addressLine1?: string, addressLine2?: string, addressLine3?: string, contactName?: string, countryCode?: string, kind?: string, locality?: string, organizationName?: string, postalCode?: string, region?: string}
  --primary-admin: record # JSON template for primary admin in case of TEAM customers — shape: {primaryEmail?: string}
  --resource-ui-url: string # URL to customer's Admin console dashboard. The read-only URL is generated by the API service. This is used if your client application requires the customer to complete a task in the Admin console.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/apps/reseller/v1/customers/{customerId}"
    path_params: [{name: customerId, var: customer_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: alternateEmail, var: alternate_email}, {name: customerDomain, var: customer_domain}, {name: customerDomainVerified, var: customer_domain_verified}, {name: customerId, var: body_customer_id}, {name: customerType, var: customer_type}, {name: kind, var: kind}, {name: phoneNumber, var: phone_number}, {name: postalAddress, var: postal_address}, {name: primaryAdmin, var: primary_admin}, {name: resourceUiUrl, var: resource_ui_url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer_id: $customer_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, alternate_email: $alternate_email, customer_domain: $customer_domain, customer_domain_verified: $customer_domain_verified, body_customer_id: $body_customer_id, customer_type: $customer_type, kind: $kind, phone_number: $phone_number, postal_address: $postal_address, primary_admin: $primary_admin, resource_ui_url: $resource_ui_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a customer account's settings. You cannot update `customerType` via the Reseller API, but a `"team"` customer can verify their domain and become `customerType = "domain"`. For more information, see [update a customer's settings](/admin-sdk/reseller/v1/how-tos/manage_customers#update_customer).
#
# PUT /apps/reseller/v1/customers/{customerId}
# Returns: record<alternateEmail: string, customerDomain: string, customerDomainVerified: bool, customerId: string, customerType: string, kind: string, phoneNumber: string, postalAddress: record<addressLine1: string, addressLine2: string, addressLine3: string, contactName: string, countryCode: string, kind: string, locality: string, organizationName: string, postalCode: string, region: string>, primaryAdmin: record<primaryEmail: string>, resourceUiUrl: string>
# operationId: reseller.customers.update
export def "reseller-customers-update" [
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --alternate-email: string # Like the "Customer email" in the reseller tools, this email is the secondary contact used if something happens to the customer's service such as service outage or a security issue. This property is required when creating a new "domain" customer and should not use the same domain as `customerDomain`. The `alternateEmail` field is not necessary to create a "team" customer.
  --customer-domain: string # The customer's primary domain name string. `customerDomain` is required when creating a new customer. Do not include the `www` prefix in the domain when adding a customer.
  --customer-domain-verified: oneof<nothing, bool> # Whether the customer's primary domain has been verified.
  --body-customer-id: string # This property will always be returned in a response as the unique identifier generated by Google. In a request, this property can be either the primary domain or the unique identifier generated by Google. (spec name: customerId)
  --customer-type: string@customer-type-completer # Identifies the type of the customer. Acceptable values include: * `domain`: Implies a domain-verified customer (default). * `team`: Implies an email-verified customer. For more information, see [managed teams](https://support.google.com/a/users/answer/9939479).
  --kind: string # Identifies the resource as a customer. Value: `reseller#customer` (default: reseller#customer)
  --phone-number: string # Customer contact phone number. Must start with "+" followed by the country code. The rest of the number can be contiguous numbers or respect the phone local format conventions, but it must be a real phone number and not, for example, "123". This field is silently ignored if invalid.
  --postal-address: record # JSON template for address of a customer. — shape: {addressLine1?: string, addressLine2?: string, addressLine3?: string, contactName?: string, countryCode?: string, kind?: string, locality?: string, organizationName?: string, postalCode?: string, region?: string}
  --primary-admin: record # JSON template for primary admin in case of TEAM customers — shape: {primaryEmail?: string}
  --resource-ui-url: string # URL to customer's Admin console dashboard. The read-only URL is generated by the API service. This is used if your client application requires the customer to complete a task in the Admin console.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/apps/reseller/v1/customers/{customerId}"
    path_params: [{name: customerId, var: customer_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: alternateEmail, var: alternate_email}, {name: customerDomain, var: customer_domain}, {name: customerDomainVerified, var: customer_domain_verified}, {name: customerId, var: body_customer_id}, {name: customerType, var: customer_type}, {name: kind, var: kind}, {name: phoneNumber, var: phone_number}, {name: postalAddress, var: postal_address}, {name: primaryAdmin, var: primary_admin}, {name: resourceUiUrl, var: resource_ui_url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer_id: $customer_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, alternate_email: $alternate_email, customer_domain: $customer_domain, customer_domain_verified: $customer_domain_verified, body_customer_id: $body_customer_id, customer_type: $customer_type, kind: $kind, phone_number: $phone_number, postal_address: $postal_address, primary_admin: $primary_admin, resource_ui_url: $resource_ui_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates or transfer a subscription. Create a subscription for a customer's account that you ordered using the [Order a new customer account](/admin-sdk/reseller/v1/reference/customers/insert.html) method. For more information about creating a subscription for different payment plans, see [manage subscriptions](/admin-sdk/reseller/v1/how-tos/manage_subscriptions#create_subscription).\ If you did not order the customer's account using the customer insert method, use the customer's `customerAuthToken` when creating a subscription for that customer. If transferring a G Suite subscription with an associated Google Drive or Google Vault subscription, use the [batch operation](/admin-sdk/reseller/v1/how-tos/batch.html) to transfer all of these subscriptions. For more information, see how to [transfer subscriptions](/admin-sdk/reseller/v1/how-tos/manage_subscriptions#transfer_a_subscription).
#
# POST /apps/reseller/v1/customers/{customerId}/subscriptions
# Returns: record<billingMethod: string, creationTime: string, customerDomain: string, customerId: string, dealCode: string, kind: string, plan: record<commitmentInterval: record<endTime: string, startTime: string>, isCommitmentPlan: bool, planName: string>, purchaseOrderId: string, renewalSettings: record<kind: string, renewalType: string>, resourceUiUrl: string, seats: record<kind: string, licensedNumberOfSeats: int, maximumNumberOfSeats: int, numberOfSeats: int>, skuId: string, skuName: string, status: string, subscriptionId: string, suspensionReasons: list<string>, transferInfo: record<currentLegacySkuId: string, minimumTransferableSeats: int, transferabilityExpirationTime: string>, trialSettings: record<isInTrial: bool, trialEndTime: string>>
# operationId: reseller.subscriptions.insert
export def "reseller-subscriptions-insert" [
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --customer-auth-token: string # The `customerAuthToken` query string is required when creating a resold account that transfers a direct customer's subscription or transfers another reseller customer's subscription to your reseller management. This is a hexadecimal authentication token needed to complete the subscription transfer. For more information, see the administrator help center.
  --billing-method: string # Read-only field that returns the current billing method for a subscription.
  --creation-time: string # The `creationTime` property is the date when subscription was created. It is in milliseconds using the Epoch format. See an example Epoch converter. (format: int64)
  --customer-domain: string # Primary domain name of the customer
  --body-customer-id: string # This property will always be returned in a response as the unique identifier generated by Google. In a request, this property can be either the primary domain or the unique identifier generated by Google. (spec name: customerId)
  --deal-code: string # Google-issued code (100 char max) for discounted pricing on subscription plans. Deal code must be included in `insert` requests in order to receive discounted rate. This property is optional, regular pricing applies if left empty.
  --kind: string # Identifies the resource as a Subscription. Value: `reseller#subscription` (default: reseller#subscription)
  --plan: record # The `plan` property is required. In this version of the API, the G Suite plans are the flexible plan, annual commitment plan, and the 30-day free trial plan. For more information about the API"s payment plans, see the API concepts. — shape: {commitmentInterval?: record, isCommitmentPlan?: bool, planName?: string}
  --purchase-order-id: string # This is an optional property. This purchase order (PO) information is for resellers to use for their company tracking usage. If a `purchaseOrderId` value is given it appears in the API responses and shows up in the invoice. The property accepts up to 80 plain text characters.
  --renewal-settings: record # JSON template for a subscription renewal settings. — shape: {kind?: string, renewalType?: string}
  --resource-ui-url: string # URL to customer's Subscriptions page in the Admin console. The read-only URL is generated by the API service. This is used if your client application requires the customer to complete a task using the Subscriptions page in the Admin console.
  --seats: record # JSON template for subscription seats. — shape: {kind?: string, licensedNumberOfSeats?: int, maximumNumberOfSeats?: int, numberOfSeats?: int}
  --sku-id: string # A required property. The `skuId` is a unique system identifier for a product's SKU assigned to a customer in the subscription. For products and SKUs available in this version of the API, see Product and SKU IDs.
  --sku-name: string # Read-only external display name for a product's SKU assigned to a customer in the subscription. SKU names are subject to change at Google's discretion. For products and SKUs available in this version of the API, see Product and SKU IDs.
  --status: string # This is an optional property.
  --subscription-id: string # The `subscriptionId` is the subscription identifier and is unique for each customer. This is a required property. Since a `subscriptionId` changes when a subscription is updated, we recommend not using this ID as a key for persistent data. Use the `subscriptionId` as described in retrieve all reseller subscriptions.
  --suspension-reasons: list<string> # Read-only field containing an enumerable of all the current suspension reasons for a subscription. It is possible for a subscription to have many concurrent, overlapping suspension reasons. A subscription's `STATUS` is `SUSPENDED` until all pending suspensions are removed. Possible options include: - `PENDING_TOS_ACCEPTANCE` - The customer has not logged in and accepted the G Suite Resold Terms of Services. - `RENEWAL_WITH_TYPE_CANCEL` - The customer's commitment ended and their service was cancelled at the end of their term. - `RESELLER_INITIATED` - A manual suspension invoked by a Reseller. - `TRIAL_ENDED` - The customer's trial expired without a plan selected. - `OTHER` - The customer is suspended for an internal Google reason (e.g. abuse or otherwise).
  --transfer-info: record # Read-only transfer related information for the subscription. For more information, see retrieve transferable subscriptions for a customer. — shape: {currentLegacySkuId?: string, minimumTransferableSeats?: int, transferabilityExpirationTime?: string}
  --trial-settings: record # The G Suite annual commitment and flexible payment plans can be in a 30-day free trial. For more information, see the API concepts. — shape: {isInTrial?: bool, trialEndTime?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/apps/reseller/v1/customers/{customerId}/subscriptions"
    path_params: [{name: customerId, var: customer_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: customerAuthToken, var: customer_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: billingMethod, var: billing_method}, {name: creationTime, var: creation_time}, {name: customerDomain, var: customer_domain}, {name: customerId, var: body_customer_id}, {name: dealCode, var: deal_code}, {name: kind, var: kind}, {name: plan, var: plan}, {name: purchaseOrderId, var: purchase_order_id}, {name: renewalSettings, var: renewal_settings}, {name: resourceUiUrl, var: resource_ui_url}, {name: seats, var: seats}, {name: skuId, var: sku_id}, {name: skuName, var: sku_name}, {name: status, var: status}, {name: subscriptionId, var: subscription_id}, {name: suspensionReasons, var: suspension_reasons}, {name: transferInfo, var: transfer_info}, {name: trialSettings, var: trial_settings}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer_id: $customer_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, customer_auth_token: $customer_auth_token, billing_method: $billing_method, creation_time: $creation_time, customer_domain: $customer_domain, body_customer_id: $body_customer_id, deal_code: $deal_code, kind: $kind, plan: $plan, purchase_order_id: $purchase_order_id, renewal_settings: $renewal_settings, resource_ui_url: $resource_ui_url, seats: $seats, sku_id: $sku_id, sku_name: $sku_name, status: $status, subscription_id: $subscription_id, suspension_reasons: $suspension_reasons, transfer_info: $transfer_info, trial_settings: $trial_settings
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancels, suspends, or transfers a subscription to direct.
#
# DELETE /apps/reseller/v1/customers/{customerId}/subscriptions/{subscriptionId}
# operationId: reseller.subscriptions.delete
export def "reseller-subscriptions-delete" [
  customer_id: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --deletion-type: string@deletion-type-completer # The `deletionType` query string enables the cancellation, downgrade, or suspension of a subscription. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/apps/reseller/v1/customers/{customerId}/subscriptions/{subscriptionId}"
    path_params: [{name: customerId, var: customer_id}, {name: subscriptionId, var: subscription_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: deletionType, var: deletion_type, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer_id: $customer_id, subscription_id: $subscription_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, deletion_type: $deletion_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a specific subscription. The `subscriptionId` can be found using the [Retrieve all reseller subscriptions](/admin-sdk/reseller/v1/how-tos/manage_subscriptions#get_all_subscriptions) method. For more information about retrieving a specific subscription, see the information descrived in [manage subscriptions](/admin-sdk/reseller/v1/how-tos/manage_subscriptions#get_subscription).
#
# GET /apps/reseller/v1/customers/{customerId}/subscriptions/{subscriptionId}
# Returns: record<billingMethod: string, creationTime: string, customerDomain: string, customerId: string, dealCode: string, kind: string, plan: record<commitmentInterval: record<endTime: string, startTime: string>, isCommitmentPlan: bool, planName: string>, purchaseOrderId: string, renewalSettings: record<kind: string, renewalType: string>, resourceUiUrl: string, seats: record<kind: string, licensedNumberOfSeats: int, maximumNumberOfSeats: int, numberOfSeats: int>, skuId: string, skuName: string, status: string, subscriptionId: string, suspensionReasons: list<string>, transferInfo: record<currentLegacySkuId: string, minimumTransferableSeats: int, transferabilityExpirationTime: string>, trialSettings: record<isInTrial: bool, trialEndTime: string>>
# operationId: reseller.subscriptions.get
export def "reseller-subscriptions-get" [
  customer_id: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/apps/reseller/v1/customers/{customerId}/subscriptions/{subscriptionId}"
    path_params: [{name: customerId, var: customer_id}, {name: subscriptionId, var: subscription_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer_id: $customer_id, subscription_id: $subscription_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Activates a subscription previously suspended by the reseller. If you did not suspend the customer subscription and it is suspended for any other reason, such as for abuse or a pending ToS acceptance, this call will not reactivate the customer subscription.
#
# POST /apps/reseller/v1/customers/{customerId}/subscriptions/{subscriptionId}/activate
# Returns: record<billingMethod: string, creationTime: string, customerDomain: string, customerId: string, dealCode: string, kind: string, plan: record<commitmentInterval: record<endTime: string, startTime: string>, isCommitmentPlan: bool, planName: string>, purchaseOrderId: string, renewalSettings: record<kind: string, renewalType: string>, resourceUiUrl: string, seats: record<kind: string, licensedNumberOfSeats: int, maximumNumberOfSeats: int, numberOfSeats: int>, skuId: string, skuName: string, status: string, subscriptionId: string, suspensionReasons: list<string>, transferInfo: record<currentLegacySkuId: string, minimumTransferableSeats: int, transferabilityExpirationTime: string>, trialSettings: record<isInTrial: bool, trialEndTime: string>>
# operationId: reseller.subscriptions.activate
export def "reseller-subscriptions-activate" [
  customer_id: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/reseller/v1/customers/{customerId}/subscriptions/{subscriptionId}/activate"
    path_params: [{name: customerId, var: customer_id}, {name: subscriptionId, var: subscription_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer_id: $customer_id, subscription_id: $subscription_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a subscription plan. Use this method to update a plan for a 30-day trial or a flexible plan subscription to an annual commitment plan with monthly or yearly payments. How a plan is updated differs depending on the plan and the products. For more information, see the description in [manage subscriptions](/admin-sdk/reseller/v1/how-tos/manage_subscriptions#update_subscription_plan).
#
# POST /apps/reseller/v1/customers/{customerId}/subscriptions/{subscriptionId}/changePlan
# Returns: record<billingMethod: string, creationTime: string, customerDomain: string, customerId: string, dealCode: string, kind: string, plan: record<commitmentInterval: record<endTime: string, startTime: string>, isCommitmentPlan: bool, planName: string>, purchaseOrderId: string, renewalSettings: record<kind: string, renewalType: string>, resourceUiUrl: string, seats: record<kind: string, licensedNumberOfSeats: int, maximumNumberOfSeats: int, numberOfSeats: int>, skuId: string, skuName: string, status: string, subscriptionId: string, suspensionReasons: list<string>, transferInfo: record<currentLegacySkuId: string, minimumTransferableSeats: int, transferabilityExpirationTime: string>, trialSettings: record<isInTrial: bool, trialEndTime: string>>
# operationId: reseller.subscriptions.changePlan
export def "reseller-subscriptions-change-plan" [
  customer_id: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --deal-code: string # Google-issued code (100 char max) for discounted pricing on subscription plans. Deal code must be included in `changePlan` request in order to receive discounted rate. This property is optional. If a deal code has already been added to a subscription, this property may be left empty and the existing discounted rate will still apply (if not empty, only provide the deal code that is already present on the subscription). If a deal code has never been added to a subscription and this property is left blank, regular pricing will apply.
  --kind: string # Identifies the resource as a subscription change plan request. Value: `subscriptions#changePlanRequest` (default: subscriptions#changePlanRequest)
  --plan-name: string # The `planName` property is required. This is the name of the subscription's payment plan. For more information about the Google payment plans, see API concepts. Possible values are: - `ANNUAL_MONTHLY_PAY` - The annual commitment plan with monthly payments *Caution: *`ANNUAL_MONTHLY_PAY` is returned as `ANNUAL` in all API responses. - `ANNUAL_YEARLY_PAY` - The annual commitment plan with yearly payments - `FLEXIBLE` - The flexible plan - `TRIAL` - The 30-day free trial plan
  --purchase-order-id: string # This is an optional property. This purchase order (PO) information is for resellers to use for their company tracking usage. If a `purchaseOrderId` value is given it appears in the API responses and shows up in the invoice. The property accepts up to 80 plain text characters.
  --seats: record # JSON template for subscription seats. — shape: {kind?: string, licensedNumberOfSeats?: int, maximumNumberOfSeats?: int, numberOfSeats?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/apps/reseller/v1/customers/{customerId}/subscriptions/{subscriptionId}/changePlan"
    path_params: [{name: customerId, var: customer_id}, {name: subscriptionId, var: subscription_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: dealCode, var: deal_code}, {name: kind, var: kind}, {name: planName, var: plan_name}, {name: purchaseOrderId, var: purchase_order_id}, {name: seats, var: seats}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer_id: $customer_id, subscription_id: $subscription_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, deal_code: $deal_code, kind: $kind, plan_name: $plan_name, purchase_order_id: $purchase_order_id, seats: $seats
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a user license's renewal settings. This is applicable for accounts with annual commitment plans only. For more information, see the description in [manage subscriptions](/admin-sdk/reseller/v1/how-tos/manage_subscriptions#update_renewal).
#
# POST /apps/reseller/v1/customers/{customerId}/subscriptions/{subscriptionId}/changeRenewalSettings
# Returns: record<billingMethod: string, creationTime: string, customerDomain: string, customerId: string, dealCode: string, kind: string, plan: record<commitmentInterval: record<endTime: string, startTime: string>, isCommitmentPlan: bool, planName: string>, purchaseOrderId: string, renewalSettings: record<kind: string, renewalType: string>, resourceUiUrl: string, seats: record<kind: string, licensedNumberOfSeats: int, maximumNumberOfSeats: int, numberOfSeats: int>, skuId: string, skuName: string, status: string, subscriptionId: string, suspensionReasons: list<string>, transferInfo: record<currentLegacySkuId: string, minimumTransferableSeats: int, transferabilityExpirationTime: string>, trialSettings: record<isInTrial: bool, trialEndTime: string>>
# operationId: reseller.subscriptions.changeRenewalSettings
export def "reseller-subscriptions-change-renewal-settings" [
  customer_id: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --kind: string # Identifies the resource as a subscription renewal setting. Value: `subscriptions#renewalSettings` (default: subscriptions#renewalSettings)
  --renewal-type: string # Renewal settings for the annual commitment plan. For more detailed information, see renewal options in the administrator help center. When renewing a subscription, the `renewalType` is a required property.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/apps/reseller/v1/customers/{customerId}/subscriptions/{subscriptionId}/changeRenewalSettings"
    path_params: [{name: customerId, var: customer_id}, {name: subscriptionId, var: subscription_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: kind, var: kind}, {name: renewalType, var: renewal_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer_id: $customer_id, subscription_id: $subscription_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, kind: $kind, renewal_type: $renewal_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a subscription's user license settings. For more information about updating an annual commitment plan or a flexible plan subscription’s licenses, see [Manage Subscriptions](/admin-sdk/reseller/v1/how-tos/manage_subscriptions#update_subscription_seat).
#
# POST /apps/reseller/v1/customers/{customerId}/subscriptions/{subscriptionId}/changeSeats
# Returns: record<billingMethod: string, creationTime: string, customerDomain: string, customerId: string, dealCode: string, kind: string, plan: record<commitmentInterval: record<endTime: string, startTime: string>, isCommitmentPlan: bool, planName: string>, purchaseOrderId: string, renewalSettings: record<kind: string, renewalType: string>, resourceUiUrl: string, seats: record<kind: string, licensedNumberOfSeats: int, maximumNumberOfSeats: int, numberOfSeats: int>, skuId: string, skuName: string, status: string, subscriptionId: string, suspensionReasons: list<string>, transferInfo: record<currentLegacySkuId: string, minimumTransferableSeats: int, transferabilityExpirationTime: string>, trialSettings: record<isInTrial: bool, trialEndTime: string>>
# operationId: reseller.subscriptions.changeSeats
export def "reseller-subscriptions-change-seats" [
  customer_id: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --kind: string # Identifies the resource as a subscription seat setting. Value: `subscriptions#seats` (default: subscriptions#seats)
  --licensed-number-of-seats: int # Read-only field containing the current number of users that are assigned a license for the product defined in `skuId`. This field's value is equivalent to the numerical count of users returned by the Enterprise License Manager API method: [`listForProductAndSku`](/admin-sdk/licensing/v1/reference/licenseAssignments/listForProductAndSku). (format: int32)
  --maximum-number-of-seats: int # This is a required property and is exclusive to subscriptions with `FLEXIBLE` or `TRIAL` plans. This property sets the maximum number of licensed users allowed on a subscription. This quantity can be increased up to the maximum limit defined in the reseller's contract. The minimum quantity is the current number of users in the customer account. *Note: *G Suite subscriptions automatically assign a license to every user. (format: int32)
  --number-of-seats: int # This is a required property and is exclusive to subscriptions with `ANNUAL_MONTHLY_PAY` and `ANNUAL_YEARLY_PAY` plans. This property sets the maximum number of licenses assignable to users on a subscription. The reseller can add more licenses, but once set, the `numberOfSeats` cannot be reduced until renewal. The reseller is invoiced based on the `numberOfSeats` value regardless of how many of these user licenses are assigned. *Note: *Google Workspace subscriptions automatically assign a license to every user. (format: int32)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/apps/reseller/v1/customers/{customerId}/subscriptions/{subscriptionId}/changeSeats"
    path_params: [{name: customerId, var: customer_id}, {name: subscriptionId, var: subscription_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: kind, var: kind}, {name: licensedNumberOfSeats, var: licensed_number_of_seats}, {name: maximumNumberOfSeats, var: maximum_number_of_seats}, {name: numberOfSeats, var: number_of_seats}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer_id: $customer_id, subscription_id: $subscription_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, kind: $kind, licensed_number_of_seats: $licensed_number_of_seats, maximum_number_of_seats: $maximum_number_of_seats, number_of_seats: $number_of_seats
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Immediately move a 30-day free trial subscription to a paid service subscription. This method is only applicable if a payment plan has already been set up for the 30-day trial subscription. For more information, see [manage subscriptions](/admin-sdk/reseller/v1/how-tos/manage_subscriptions#paid_service).
#
# POST /apps/reseller/v1/customers/{customerId}/subscriptions/{subscriptionId}/startPaidService
# Returns: record<billingMethod: string, creationTime: string, customerDomain: string, customerId: string, dealCode: string, kind: string, plan: record<commitmentInterval: record<endTime: string, startTime: string>, isCommitmentPlan: bool, planName: string>, purchaseOrderId: string, renewalSettings: record<kind: string, renewalType: string>, resourceUiUrl: string, seats: record<kind: string, licensedNumberOfSeats: int, maximumNumberOfSeats: int, numberOfSeats: int>, skuId: string, skuName: string, status: string, subscriptionId: string, suspensionReasons: list<string>, transferInfo: record<currentLegacySkuId: string, minimumTransferableSeats: int, transferabilityExpirationTime: string>, trialSettings: record<isInTrial: bool, trialEndTime: string>>
# operationId: reseller.subscriptions.startPaidService
export def "reseller-subscriptions-start-paid-service" [
  customer_id: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/reseller/v1/customers/{customerId}/subscriptions/{subscriptionId}/startPaidService"
    path_params: [{name: customerId, var: customer_id}, {name: subscriptionId, var: subscription_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer_id: $customer_id, subscription_id: $subscription_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Suspends an active subscription. You can use this method to suspend a paid subscription that is currently in the `ACTIVE` state. * For `FLEXIBLE` subscriptions, billing is paused. * For `ANNUAL_MONTHLY_PAY` or `ANNUAL_YEARLY_PAY` subscriptions: * Suspending the subscription does not change the renewal date that was originally committed to. * A suspended subscription does not renew. If you activate the subscription after the original renewal date, a new annual subscription will be created, starting on the day of activation. We strongly encourage you to suspend subscriptions only for short periods of time as suspensions over 60 days may result in the subscription being cancelled.
#
# POST /apps/reseller/v1/customers/{customerId}/subscriptions/{subscriptionId}/suspend
# Returns: record<billingMethod: string, creationTime: string, customerDomain: string, customerId: string, dealCode: string, kind: string, plan: record<commitmentInterval: record<endTime: string, startTime: string>, isCommitmentPlan: bool, planName: string>, purchaseOrderId: string, renewalSettings: record<kind: string, renewalType: string>, resourceUiUrl: string, seats: record<kind: string, licensedNumberOfSeats: int, maximumNumberOfSeats: int, numberOfSeats: int>, skuId: string, skuName: string, status: string, subscriptionId: string, suspensionReasons: list<string>, transferInfo: record<currentLegacySkuId: string, minimumTransferableSeats: int, transferabilityExpirationTime: string>, trialSettings: record<isInTrial: bool, trialEndTime: string>>
# operationId: reseller.subscriptions.suspend
export def "reseller-subscriptions-suspend" [
  customer_id: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/reseller/v1/customers/{customerId}/subscriptions/{subscriptionId}/suspend"
    path_params: [{name: customerId, var: customer_id}, {name: subscriptionId, var: subscription_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer_id: $customer_id, subscription_id: $subscription_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all the details of the watch corresponding to the reseller.
#
# GET /apps/reseller/v1/resellernotify/getwatchdetails
# Returns: record<serviceAccountEmailAddresses: list<string>, topicName: string>
# operationId: reseller.resellernotify.getwatchdetails
export def "reseller-resellernotify-getwatchdetails" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/apps/reseller/v1/resellernotify/getwatchdetails"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Registers a Reseller for receiving notifications.
#
# POST /apps/reseller/v1/resellernotify/register
# Returns: record<topicName: string>
# operationId: reseller.resellernotify.register
export def "reseller-resellernotify-register" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --service-account-email-address: string # The service account which will own the created Cloud-PubSub topic.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/reseller/v1/resellernotify/register"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: serviceAccountEmailAddress, var: service_account_email_address}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, service_account_email_address: $service_account_email_address
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unregisters a Reseller for receiving notifications.
#
# POST /apps/reseller/v1/resellernotify/unregister
# Returns: record<topicName: string>
# operationId: reseller.resellernotify.unregister
export def "reseller-resellernotify-unregister" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --service-account-email-address: string # The service account which owns the Cloud-PubSub topic.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/reseller/v1/resellernotify/unregister"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: serviceAccountEmailAddress, var: service_account_email_address}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, service_account_email_address: $service_account_email_address
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists of subscriptions managed by the reseller. The list can be all subscriptions, all of a customer's subscriptions, or all of a customer's transferable subscriptions. Optionally, this method can filter the response by a `customerNamePrefix`. For more information, see [manage subscriptions](/admin-sdk/reseller/v1/how-tos/manage_subscriptions).
#
# GET /apps/reseller/v1/subscriptions
# Returns: record<kind: string, nextPageToken: string, subscriptions: table<billingMethod: string, creationTime: string, customerDomain: string, customerId: string, dealCode: string, kind: string, plan: record, purchaseOrderId: string, renewalSettings: record, resourceUiUrl: string, seats: record, skuId: string, skuName: string, status: string, subscriptionId: string, suspensionReasons: list, transferInfo: record, trialSettings: record>>
# operationId: reseller.subscriptions.list
export def "reseller-subscriptions-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --customer-auth-token: string # The `customerAuthToken` query string is required when creating a resold account that transfers a direct customer's subscription or transfers another reseller customer's subscription to your reseller management. This is a hexadecimal authentication token needed to complete the subscription transfer. For more information, see the administrator help center.
  --customer-id: string # This can be either the customer's primary domain name or the customer's unique identifier. If the domain name for a customer changes, the old domain name cannot be used to access the customer, but the customer's unique identifier (as returned by the API) can always be used. We recommend storing the unique identifier in your systems where applicable.
  --customer-name-prefix: string # When retrieving all of your subscriptions and filtering for specific customers, you can enter a prefix for a customer name. Using an example customer group that includes `exam.com`, `example20.com` and `example.com`: - `exa` -- Returns all customer names that start with 'exa' which could include `exam.com`, `example20.com`, and `example.com`. A name prefix is similar to using a regular expression's asterisk, exa*. - `example` -- Returns `example20.com` and `example.com`.
  --max-results: int # When retrieving a large list, the `maxResults` is the maximum number of results per page. The `nextPageToken` value takes you to the next page. The default is 20.
  --page-token: string # Token to specify next page in the list
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/apps/reseller/v1/subscriptions"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: customerAuthToken, var: customer_auth_token}, {name: customerId, var: customer_id}, {name: customerNamePrefix, var: customer_name_prefix}, {name: maxResults, var: max_results}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, customer_auth_token: $customer_auth_token, customer_id: $customer_id, customer_name_prefix: $customer_name_prefix, max_results: $max_results, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
