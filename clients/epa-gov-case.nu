# Auto-generated client for U.S. EPA Enforcement and Compliance History Online (ECHO) - Enforcement Case Search v1.0.0
# Source: https://api.apis.guru/v2/specs/epa.gov/case/1.0.0/swagger.json
# Auth: --token flag or $env.U_S_EPA_ENFORCEMENT_AND_COMPLIANCE_HISTORY_ONLINE_ECHO_ENFORCEMENT_CASE_SEARCH_TOKEN

const CLIENT = {
  base_url: "https://echodata.epa.gov/echo"
  token_env_var: "U_S_EPA_ENFORCEMENT_AND_COMPLIANCE_HISTORY_ONLINE_ECHO_ENFORCEMENT_CASE_SEARCH_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: []
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

def base-url-completer [] { ["https://echodata.epa.gov/echo"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def output-completer [] { ["JSON" "JSONP" "XML"] }
def p-case-lead-completer [] { ["E" "S"] }
def p-region-completer [] { ["01" "02" "03" "04" "05" "06" "07" "08" "09" "10"] }
def p-sic-ao-naics-completer [] { ["AND" "OR"] }
def p-sic-primary-flg-completer [] { ["N" "Y"] }
def p-sic-frs-flg-completer [] { ["N" "Y"] }
def p-naics-primary-flg-completer [] { ["N" "Y"] }
def p-naics-frs-flg-completer [] { ["N" "Y"] }
def p-rank-order-completer [] { ["0" "1"] }
def p-tribal-completer [] { ["N" "Y"] }
def p-oeca-core-completer [] { ["N" "Y"] }
def p-multimedia-completer [] { ["N" "Y"] }
def p-fed-case-completer [] { ["N" "Y"] }
def p-fed-penalty-completer [] { ["ANY" "GT100000" "GT1000000" "GT2500000" "GT5000" "GT50000" "GT500000" "LE5000"] }
def p-comp-act-val-completer [] { ["ANY" "GT100000" "GT1000000" "GT5000" "GT50000000" "LE5000"] }
def p-sep-val-completer [] { ["ANY" "GT10000" "GT100000" "GT1000000" "GT50000" "GT500000" "LE10000"] }
def p-case-summary-type-completer [] { ["ALL" "CONTAINS" "WITHIN"] }
def p-usmex-completer [] { ["N" "Y"] }
def p-fntype-completer [] { ["ALL" "BEGINS" "CONTAINS" "EXACT"] }
def p-civil-criminal-indicator-completer [] { ["ALL" "CI" "CR"] }
def accept-completer [] { ["application/json" "application/xml"] }
def maplist-completer [] { ["N" "Y"] }
def tablelist-completer [] { ["N" "Y"] }
def descending-completer [] { ["N" "Y"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-case-rest-services-get-case-info: "record<Results: record<AFRRows: string, CERCLARows: string, CWARows: string, Cases: list<record>, ClusterOutput: record<ClusterData: list>, ClusterRecords: string, CriminalRows: string, EPCRARows: string, FIFRARows: string, FedPenRows: string, FederalRows: string, JDCRows: string, MapLocations: string, Message: string, QueryParameters: list<record>, QueryRows: string, RCRARows: string, SDWARows: string, SEPRows: string, TSCARows: string>>"
    post-case-rest-services-get-case-info: "record<Results: record<AFRRows: string, CERCLARows: string, CWARows: string, Cases: list<record>, ClusterOutput: record<ClusterData: list>, ClusterRecords: string, CriminalRows: string, EPCRARows: string, FIFRARows: string, FedPenRows: string, FederalRows: string, JDCRows: string, MapLocations: string, Message: string, QueryParameters: list<record>, QueryRows: string, RCRARows: string, SDWARows: string, SEPRows: string, TSCARows: string>>"
    get-case-rest-services-get-case-report: "record<Results: record<CAEDDocuments: list<record>, CaseInformation: record<Branch: string, CaseName: string, CaseNumber: string, CaseStatus: string, CaseStatusDate: string, CaseSummary: string, CaseType: string, DOJDocketNumber: string, EnforcementOutcome: string, EnforcementType: string, HeadquartersDivision: string, Lead: string, MultiMediaCase: string, RegionalDocketNumber: string, ReliefSought: string, ResultVolDisclosure: string, TotalComplianceActionCost: string, TotalCostRecovery: string, TotalFederalPenalty: string, TotalSEPCost: string, TotalStatePenalty: string, Violations: string>, CaseMilestones: list<record>, Citations: list<record>, Defendants: list<record>, EnforcementConclusions: list<record>, Facilities: list<record>, LawsAndSections: list<record>, Message: string, Pollutants: list<record>, ProgramLinks: list<record>, RelatedActivities: list<record>>>"
    post-case-rest-services-get-case-report: "record<Results: record<CAEDDocuments: list<record>, CaseInformation: record<Branch: string, CaseName: string, CaseNumber: string, CaseStatus: string, CaseStatusDate: string, CaseSummary: string, CaseType: string, DOJDocketNumber: string, EnforcementOutcome: string, EnforcementType: string, HeadquartersDivision: string, Lead: string, MultiMediaCase: string, RegionalDocketNumber: string, ReliefSought: string, ResultVolDisclosure: string, TotalComplianceActionCost: string, TotalCostRecovery: string, TotalFederalPenalty: string, TotalSEPCost: string, TotalStatePenalty: string, Violations: string>, CaseMilestones: list<record>, Citations: list<record>, Defendants: list<record>, EnforcementConclusions: list<record>, Facilities: list<record>, LawsAndSections: list<record>, Message: string, Pollutants: list<record>, ProgramLinks: list<record>, RelatedActivities: list<record>>>"
    get-case-rest-services-get-cases: "record<Results: record<AFRRows: string, CAARows: string, CERCLARows: string, CWARows: string, Cases: list<record>, CriminalRows: string, EPCRARows: string, FIFRARows: string, FedPenRows: string, FederalRows: string, JDCRows: string, MapOutput: record<IconBaseURL: string, MapData: list, PopUpBaseURL: string, QueryID: string>, Message: string, PageNo: string, QueryID: string, QueryRows: string, RCRARows: string, SDWARows: string, SEPRows: string, TSCARows: string>>"
    post-case-rest-services-get-cases: "record<Results: record<AFRRows: string, CAARows: string, CERCLARows: string, CWARows: string, Cases: list<record>, CriminalRows: string, EPCRARows: string, FIFRARows: string, FedPenRows: string, FederalRows: string, JDCRows: string, MapOutput: record<IconBaseURL: string, MapData: list, PopUpBaseURL: string, QueryID: string>, Message: string, PageNo: string, QueryID: string, QueryRows: string, RCRARows: string, SDWARows: string, SEPRows: string, TSCARows: string>>"
    get-case-rest-services-get-cases-from-facility: "record<Results: record<Results: record<CaseNumbers: list>>>"
    post-case-rest-services-get-cases-from-facility: "record<Results: record<Results: record<CaseNumbers: list>>>"
    get-case-rest-services-get-crcase-report: "record<Results: record<CRCaseInformation: record<CaseIdentifier: string, CaseSummary: string, Citations: string, FiscalYear: string, Statutes: string>, CRDefendants: list<record>, CRDetails: list<record>, Locations: list<record>, Message: string>>"
    post-case-rest-services-get-crcase-report: "record<Results: record<CRCaseInformation: record<CaseIdentifier: string, CaseSummary: string, Citations: string, FiscalYear: string, Statutes: string>, CRDefendants: list<record>, CRDetails: list<record>, Locations: list<record>, Message: string>>"
    get-case-rest-services-get-download: "binary"
    post-case-rest-services-get-download: "binary"
    get-case-rest-services-get-facilities-from-case: "record<Results: record<Results: record<RegistryIDs: list>>>"
    post-case-rest-services-get-facilities-from-case: "record<Results: record<Results: record<RegistryIDs: list>>>"
    get-case-rest-services-get-map: "record<MapOutput: record<IconBaseURL: string, MapData: list<record>, PopUpBaseURL: string, QueryID: string>>"
    post-case-rest-services-get-map: "record<MapOutput: record<IconBaseURL: string, MapData: list<record>, PopUpBaseURL: string, QueryID: string>>"
    get-case-rest-services-get-qid: "record<Results: record<Cases: list<record>, Message: string, PageNo: string, QueryID: string, QueryRows: string>>"
    post-case-rest-services-get-qid: "record<Results: record<Cases: list<record>, Message: string, PageNo: string, QueryID: string, QueryRows: string>>"
    get-case-rest-services-metadata: "record<Results: record<Message: string, ResultColumns: list<record>>>"
    post-case-rest-services-metadata: "record<Results: record<Message: string, ResultColumns: list<record>>>"
    get-rest-lookups-icis-law-sections: "record<Results: record<LuValues: list<record>, Message: string>>"
    post-rest-lookups-icis-law-sections: "record<Results: record<LuValues: list<record>, Message: string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-case-rest-services-get-case-info" "post-case-rest-services-get-case-info" "get-case-rest-services-get-case-report" "post-case-rest-services-get-case-report" "get-case-rest-services-get-cases" "post-case-rest-services-get-cases" "get-case-rest-services-get-cases-from-facility" "post-case-rest-services-get-cases-from-facility" "get-case-rest-services-get-crcase-report" "post-case-rest-services-get-crcase-report" "get-case-rest-services-get-download" "post-case-rest-services-get-download" "get-case-rest-services-get-facilities-from-case" "post-case-rest-services-get-facilities-from-case" "get-case-rest-services-get-map" "post-case-rest-services-get-map" "get-case-rest-services-get-qid" "post-case-rest-services-get-qid" "get-case-rest-services-metadata" "post-case-rest-services-metadata" "get-rest-lookups-icis-law-sections" "post-rest-lookups-icis-law-sections" "commands"] | sort) } | get name | first)
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

# Enforcement Case Search (new version)
#
# GET /case_rest_services.get_case_info
# Returns: record<Results: record<AFRRows: string, CERCLARows: string, CWARows: string, Cases: list<record>, ClusterOutput: record<ClusterData: list>, ClusterRecords: string, CriminalRows: string, EPCRARows: string, FIFRARows: string, FedPenRows: string, FederalRows: string, JDCRows: string, MapLocations: string, Message: string, QueryParameters: list<record>, QueryRows: string, RCRARows: string, SDWARows: string, SEPRows: string, TSCARows: string>>
export def "get-case-rest-services-get-case-info" [
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
  --output: string@output-completer # Output Format Flag. Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding. - XML = Data model formatted as Extensible Markup Language.
  --p-case-category: string # Case Category Filter. Enter one or more case category codes to filter results. Provide multiple values as a comma-delimited list. - AFR = Administrative - Formal - AIF = Administrative - Informal - JDC = Judicial
  --p-case-status: string # Case Status Code Filter. Enter one or more case status codes to limit results. Provide multiple values as a comma-delimited list.
  --p-milestone: string # Administrative or Judicial Milestone Filter. Enter one or milestone values to restrict results. Provide multiple values as a comma-delimited list.
  --p-from-date: string # Administrative or Judicial Milestone Date Range Start Limiter. Enter a date value in MM/DD/YYYY format to limit milestone results. Parameter p_to_date must also be populated when using this parameter option.
  --p-to-date: string # Administrative or Judicial Milestone Date Range End Limiter. Enter a date value in MM/DD/YYYY format to limit milestone results. Parameter p_from_date must also be populated when using this parameter option.
  --p-milestone-fy: string # Administrative or Judicial Milestone Fiscal Year Limiter. Enter a single fiscal year value to limit milestone searches to a given fiscal year.
  --p-name: string # Case Name Filter. Enter one or more case names to restrict results. Provide multiple values as a comma-delimited list. When using this parameter the p_name_type parameter is required.
  --p-name-type: string # Case Name Filter Modifier.
  --p-case-number: string # Case Number Filter. Enter one or more case numbers to restrict results. Provide multiple values as a comma-delimited list.
  --p-docket-number: string # DOJ Docket Number Filter. Enter a single docket number or partial docket number to restrict results. Use "%" as a wildcard for more complex filtering.
  --p-court-docket-number: string
  --p-activity-number: string # Case Activity Number Filter. Enter a single case activity number to filter results.
  --p-case-lead: string@p-case-lead-completer # Case Lead Limiter. Enter E or S to limit results. - E = EPA is the case lead. - S = The state is the case lead.
  --p-case-sens-flg: string # Case Sensitive Data Flag. Enter a Y or N to include or exclude cases with sensitive data.
  --p-region: string@p-region-completer # EPA Region Filter. Provide a single value of 01 thru 10 to restrict results to a single EPA region.
  --p-state: string # Case Location State Filter. Enter one or more state USPS postal codes to filter results. Provide multiple values as a comma-delimited list.
  --p-district: string # Case Location Court District Limiter. Enter a single state court district code to limit results.
  --p-sic: string # Standard Industrial Classification (SIC) Code Filter. Enter a single 4-digit SIC Code to filter results.
  --p-sic-ao-naics: string@p-sic-ao-naics-completer # Case Location SIC/NAICS And/Or Modifier. Enter either AND or OR to govern the search logic of SIC and NAICS codes. - AND = Search will return results having both the provided SIC code(s) and provided NAICS code(s). - OR = Search will return results having either the provided SIC code(s) or the provided NAICS code(s).
  --p-sic-primary-flg: string@p-sic-primary-flg-completer # Case Location Primary SIC Flag. Enter Y to limit SIC search results to primary SIC codes only.
  --p-sic-frs-flg: string@p-sic-frs-flg-completer # Case Location Extended FRS SIC Search Flag. Enter Y to expand SIC search to include Federal Registry Service datasets.
  --p-naics: string # North American Industry Classification System Filter. Enter two to six digits to filter results to facilities having matching NAICS codes. Digits less than six will match to all codes beginning with the provided values.
  --p-naics-primary-flg: string@p-naics-primary-flg-completer # Case Location Primary NAICS Flag. Enter Y to limit NAICS search results to primary NAICS codes only.
  --p-naics-frs-flg: string@p-naics-frs-flg-completer # Case Location Extended FRS NAICS Search Flag. Enter Y to expand NAICS search to include Federal Registry Service datasets.
  --p-enf-type: string # Case Enforcement Type Filter. Enter one or more case enforcement type codes to limit results. Provide multiple values as a comma-delimited list.
  --p-law: string # Law Statute Code Filter. Enter a single statute code to limit results.
  --p-section: string # Law Section Code Filter. Enter one or more law section codes to limit results. Provide multiple values as a comma-delimited list.
  --p-cp-citation: string # Law Section Code Filter Alternative. Enter a single law section code to limit results. This parameter accepts partial codes and allows for advanced search modifiers.
  --p-rank-order: string@p-rank-order-completer # Law Status Rank Order Limiter. Enter a single integer rank order to limit results.
  --p-enf-program: string # Enforcement Program Code Limiter. Enter one or more enforcement program codes to limit results. Provide multiple values as a comma-delimited list.
  --p-violation: string # Violation Type Code Filter. Enter one or more violation type codes to limit results. Provide multiple values as a comma-delimited list.
  --p-priority-area: string # Case Priority Area Filter. Enter one or more case priority areas to limit results. Provide multiple values as a comma-delimited list.
  --p-priority-area-desc: string # Case Priority Area Description Filter. Enter a single case priority area description or partial case priority area description to limit results. Use "%" as a wild-card match for more complex searches.
  --p-tribal: string@p-tribal-completer # Case Location Tribal Land Flag. Enter Y or N to include or disallow cases on tribal land.
  --p-oeca-core: string@p-oeca-core-completer # OECA Core Program Flag. Enter Y or N to include or exclude core program cases.
  --p-multimedia: string@p-multimedia-completer # Enforcement Multimedia Case Flag. Enter Y or N to include or exclude multimedia cases.
  --p-fed-case: string@p-fed-case-completer # Federal Facility Involvement Flag. Enter a Y or N to include or exclude cases involving federal facilities.
  --p-activity-contact: string # Activity Contact Last Name Filter. Enter a single last name or partial last name to filter results. Use "%" as a wild-card for advanced searching.
  --p-role: string # Activity Contact Role Code Filter. Enter a single role code to restrict results.
  --p-fed-penalty: string@p-fed-penalty-completer # Federal Penalty Assessed Amount Filter. Provide one of the following keywords to restrict results. - ANY = cases with any penalty amount. - LE5000 = cases with penalty amount less than or equal to $5,000. - GT5000 = cases with penalty amount more than $5,000. - GT50000 = cases with penalty amount more than $50,000. - GT100000 = cases with penalty amount more than $100,000. - GT500000 = cases with penalty amount more than $500,000. - GT1000000 = cases with penalty amount more than $1,000,000. - GT2500000 = cases with penalty amount more than $2,500,000.
  --p-total-fed-penalty: string # Total Federal Penalty Limiter. Enter a keyword value to limit results to cases with given total federal penalties. - ANY = Cases with any federal penalty greater than zero. - LEXX = Replacing XX with a dollar value, return cases with federal penalty less than or equal to the given amount. - GTXX = Replacing XX with a dollar value, return cases with federal penalty greater than the given amount.
  --p-cost-recovery: string # Cost Recovery Awarded Amount Limiter. Enter a keyword value to limit results to cases with given cost recovery amounts. - ANY = Cases with any cost recovery amount greater than zero. - LEXX = Replacing XX with a dollar value, return cases with cost recovery amount less than or equal to the given amount. - GTXX = Replacing XX with a dollar value, return cases with cost recovery amount greater than the given amount.
  --p-total-cost-recovery: string # Total Cost Recovery Amount Limiter. Enter a keyword value to limit results to cases with given cost recovery amounts. - ANY = Cases with any cost recovery amount greater than zero. - LEXX = Replacing XX with a dollar value, return cases with cost recovery amount less than or equal to the given amount. - GTXX = Replacing XX with a dollar value, return cases with cost recovery amount greater than the given amount.
  --p-complying-actions: string # Complying Actions Type Code Limiter. Enter one or more complying action codes to restrict results. Provide multiple values as a comma-delimited list.
  --p-comp-act-val: string@p-comp-act-val-completer # Compliance Action Cost Limiter. Enter a keyword value to limit results to cases with given compliance cost amounts. - ANY = Cases with any compliance cost amount greater than zero. - LEXX = Replacing XX with a dollar value, return cases with compliance cost amount less than or equal to the given amount. - GTXX = Replacing XX with a dollar value, return cases with compliance cost amount greater than the given amount.
  --p-total-comp-act-val: string # Total Compliance Action Amount Limiter. Enter a keyword value to limit results to cases with given total compliance action amounts. - ANY = Cases with any total compliance action amount greater than zero. - LEXX = Replacing XX with a dollar value, return cases with total compliance action amount less than or equal to the given amount. - GTXX = Replacing XX with a dollar value, return cases with total compliance action amount greater than the given amount.
  --p-sep-cats: string # Supplemental Environmental Projects Activity Category Code Limiter. Provide one or more SEP activity category codes to limit results. Provide multiple values as a comma-delimited list.
  --p-sep-val: string@p-sep-val-completer # Supplemental Environmental Projects Activity Value Limiter. Provide a keyword to limit results. - ANY = return cases with any SEP activity amount. - LE10000 = return cases with SEP activity amount less than or equal to $10,000. - GT10000 = return cases with SEP activity amount greater than $10,000. - GT50000 = return cases with SEP activity amount greater than $50,000. - GT100000 = return cases with SEP activity amount greater than $100,000. - GT500000 = return cases with SEP activity amount greater than $500,000. - GT1000000 = return cases with SEP activity amount greater than $1,000,000.
  --p-total-sep-val: string # Supplemental Environmental Projects Total Value Limiter. Provide a keyword to limit results. - ANY = return cases with any SEP total amount. - LE10000 = return cases with SEP total amount less than or equal to $10,000. - GT10000 = return cases with SEP total amount greater than $10,000. - GT50000 = return cases with SEP total amount greater than $50,000. - GT100000 = return cases with SEP total amount greater than $100,000. - GT500000 = return cases with SEP total amount greater than $500,000. - GT1000000 = return cases with SEP total amount greater than $1,000,000.
  --p-lodged-date: string # Settlement Lodged Date Limiter. Enter a single settlement lodged date in MM/DD/YYYY format to limit results.
  --p-entered-date: string # Settlement Entered Date Limiter. Enter a single settlement entered date in MM/DD/YYYY format to limit results.
  --p-facility-id: string # Case Facility Registration Identifier Limiter. Enter a single complete facility identifier to limit results.
  --p-fac-city: string # Case Facility City Limiter. Enter a single complete city name to filter cases by facility location city.
  --p-fac-zip: string # Case Facility ZIP Code Limiter. Enter a single 5-digit zip code to filter cases by facility location zip code.
  --p-fac-county: string # Case Facility County Limiter. Enter a single complete county name to filter cases by facility location county name.
  --p-case-summary: string # Case Summary Search Limiter. Enter a single case summary to limit results. This parameter accepts partial codes and allows for advanced search modifiers.
  --p-case-summary-type: string@p-case-summary-type-completer # Identifies how the the search terms enterened in p_case_summary are searched. Valid values are ALL (Default), WITHIN, and CONTAINS. Must be used with p_case_summary.
  --p-usmex: string@p-usmex-completer # US-Mexico Border Flag. Enter Y/N to restrict searches to facilities located within 100KM of the border.
  --p-c1lat: float # In decimal degrees. Latitude of 1st corner of box that bounds the resulting facilities. The latitude and longitude of both corners of the bounding box must be provided.
  --p-c1lon: float # In decimal degrees. Longitude of 1st corner of box that bounds the resulting facilities. The latitude and longitude of both corners of the bounding box must be provided.
  --p-c2lat: float # In decimal degrees. Latitude of 2nd corner of box that bounds the resulting facilities. The latitude and longitude of both corners of the bounding box must be provided.
  --p-c2lon: float # In decimal degrees. Longitude of 2nd corner of box that bounds the resulting facilities. The latitude and longitude of both corners of the bounding box must be provided.
  --p-voluntary: string # Voluntary Self Disclosure Flag. Enter Y or N to include or exclude cases results having voluntary disclosure.
  --p-fed-indicator: string # Federal Facility/Cross Media Flag. Enter Y or N to limit results to cases with federal facility cross media.
  --p-fntype: string@p-fntype-completer # Controls type of text search performed on facility name with parameter p_fn. - EXACT = Find facilities having the exact provided name(s). - BEGINS = Find facilities with names starting with the provided term(s). - ALL = Find facilities using Oracle text search terms. - CONTAINS =
  --p-civil-criminal-indicator: string@p-civil-criminal-indicator-completer # Civil/Criminal Case Limiter. Provide a keyword to limit results. - ANY = return both civil and criminal cases. - CI = return only civil cases. - CR = return only criminal cases.
  --queryset: float # Query Limiter. Enter a value to limit the number of records returned for each query. Value cannot exceed 70,000.
  --responseset: float # Response Set Limiter. Enter a value to limit the number of records per page. Value cannot exceed 1,000.
  --mapset: string # Identifies the maxium number of case facilities to return from the case_rest_services.get_case_info query. (default: 1400)
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
  --qcolumns: string # Used to customize service output. A list of comma-separated column IDs of output objects that will be returned in the service query object or download. Use the metadata service endpoint for a complete list of Ids and definitions.
  --p-pretty-print: float # Optional flag to request GeoJSON formatted results to be pretty printed. Only provide a numeric value when the output needs to be human readable as pretty printing has a performance cost.
  --p-ocmap-fy: string # Fiscal Year to select cases that are displayed in the Office of Complicance Fiscal Year Map Services
  --p-qs: string # Quick Search. Allows entry for city, state, and/or zip code.
  --p-has-map: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/case_rest_services.get_case_info"
    query: [{name: output, var: output}, {name: p_case_category, var: p_case_category}, {name: p_case_status, var: p_case_status}, {name: p_milestone, var: p_milestone}, {name: p_from_date, var: p_from_date}, {name: p_to_date, var: p_to_date}, {name: p_milestone_fy, var: p_milestone_fy}, {name: p_name, var: p_name}, {name: p_name_type, var: p_name_type}, {name: p_case_number, var: p_case_number}, {name: p_docket_number, var: p_docket_number}, {name: p_court_docket_number, var: p_court_docket_number}, {name: p_activity_number, var: p_activity_number}, {name: p_case_lead, var: p_case_lead}, {name: p_case_sens_flg, var: p_case_sens_flg}, {name: p_region, var: p_region}, {name: p_state, var: p_state}, {name: p_district, var: p_district}, {name: p_sic, var: p_sic}, {name: p_sic_ao_naics, var: p_sic_ao_naics}, {name: p_sic_primary_flg, var: p_sic_primary_flg}, {name: p_sic_frs_flg, var: p_sic_frs_flg}, {name: p_naics, var: p_naics}, {name: p_naics_primary_flg, var: p_naics_primary_flg}, {name: p_naics_frs_flg, var: p_naics_frs_flg}, {name: p_enf_type, var: p_enf_type}, {name: p_law, var: p_law}, {name: p_section, var: p_section}, {name: p_cp_citation, var: p_cp_citation}, {name: p_rank_order, var: p_rank_order}, {name: p_enf_program, var: p_enf_program}, {name: p_violation, var: p_violation}, {name: p_priority_area, var: p_priority_area}, {name: p_priority_area_desc, var: p_priority_area_desc}, {name: p_tribal, var: p_tribal}, {name: p_oeca_core, var: p_oeca_core}, {name: p_multimedia, var: p_multimedia}, {name: p_fed_case, var: p_fed_case}, {name: p_activity_contact, var: p_activity_contact}, {name: p_role, var: p_role}, {name: p_fed_penalty, var: p_fed_penalty}, {name: p_total_fed_penalty, var: p_total_fed_penalty}, {name: p_cost_recovery, var: p_cost_recovery}, {name: p_total_cost_recovery, var: p_total_cost_recovery}, {name: p_complying_actions, var: p_complying_actions}, {name: p_comp_act_val, var: p_comp_act_val}, {name: p_total_comp_act_val, var: p_total_comp_act_val}, {name: p_sep_cats, var: p_sep_cats}, {name: p_sep_val, var: p_sep_val}, {name: p_total_sep_val, var: p_total_sep_val}, {name: p_lodged_date, var: p_lodged_date}, {name: p_entered_date, var: p_entered_date}, {name: p_facility_id, var: p_facility_id}, {name: p_fac_city, var: p_fac_city}, {name: p_fac_zip, var: p_fac_zip}, {name: p_fac_county, var: p_fac_county}, {name: p_case_summary, var: p_case_summary}, {name: p_case_summary_type, var: p_case_summary_type}, {name: p_usmex, var: p_usmex}, {name: p_c1lat, var: p_c1lat}, {name: p_c1lon, var: p_c1lon}, {name: p_c2lat, var: p_c2lat}, {name: p_c2lon, var: p_c2lon}, {name: p_voluntary, var: p_voluntary}, {name: p_fed_indicator, var: p_fed_indicator}, {name: p_fntype, var: p_fntype}, {name: p_civil_criminal_indicator, var: p_civil_criminal_indicator}, {name: queryset, var: queryset}, {name: responseset, var: responseset}, {name: mapset, var: mapset}, {name: callback, var: callback}, {name: qcolumns, var: qcolumns}, {name: p_pretty_print, var: p_pretty_print}, {name: p_ocmap_fy, var: p_ocmap_fy}, {name: p_qs, var: p_qs}, {name: p_has_map, var: p_has_map}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_case_category: $p_case_category, p_case_status: $p_case_status, p_milestone: $p_milestone, p_from_date: $p_from_date, p_to_date: $p_to_date, p_milestone_fy: $p_milestone_fy, p_name: $p_name, p_name_type: $p_name_type, p_case_number: $p_case_number, p_docket_number: $p_docket_number, p_court_docket_number: $p_court_docket_number, p_activity_number: $p_activity_number, p_case_lead: $p_case_lead, p_case_sens_flg: $p_case_sens_flg, p_region: $p_region, p_state: $p_state, p_district: $p_district, p_sic: $p_sic, p_sic_ao_naics: $p_sic_ao_naics, p_sic_primary_flg: $p_sic_primary_flg, p_sic_frs_flg: $p_sic_frs_flg, p_naics: $p_naics, p_naics_primary_flg: $p_naics_primary_flg, p_naics_frs_flg: $p_naics_frs_flg, p_enf_type: $p_enf_type, p_law: $p_law, p_section: $p_section, p_cp_citation: $p_cp_citation, p_rank_order: $p_rank_order, p_enf_program: $p_enf_program, p_violation: $p_violation, p_priority_area: $p_priority_area, p_priority_area_desc: $p_priority_area_desc, p_tribal: $p_tribal, p_oeca_core: $p_oeca_core, p_multimedia: $p_multimedia, p_fed_case: $p_fed_case, p_activity_contact: $p_activity_contact, p_role: $p_role, p_fed_penalty: $p_fed_penalty, p_total_fed_penalty: $p_total_fed_penalty, p_cost_recovery: $p_cost_recovery, p_total_cost_recovery: $p_total_cost_recovery, p_complying_actions: $p_complying_actions, p_comp_act_val: $p_comp_act_val, p_total_comp_act_val: $p_total_comp_act_val, p_sep_cats: $p_sep_cats, p_sep_val: $p_sep_val, p_total_sep_val: $p_total_sep_val, p_lodged_date: $p_lodged_date, p_entered_date: $p_entered_date, p_facility_id: $p_facility_id, p_fac_city: $p_fac_city, p_fac_zip: $p_fac_zip, p_fac_county: $p_fac_county, p_case_summary: $p_case_summary, p_case_summary_type: $p_case_summary_type, p_usmex: $p_usmex, p_c1lat: $p_c1lat, p_c1lon: $p_c1lon, p_c2lat: $p_c2lat, p_c2lon: $p_c2lon, p_voluntary: $p_voluntary, p_fed_indicator: $p_fed_indicator, p_fntype: $p_fntype, p_civil_criminal_indicator: $p_civil_criminal_indicator, queryset: $queryset, responseset: $responseset, mapset: $mapset, callback: $callback, qcolumns: $qcolumns, p_pretty_print: $p_pretty_print, p_ocmap_fy: $p_ocmap_fy, p_qs: $p_qs, p_has_map: $p_has_map
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Enforcement Case Search (new version)
#
# POST /case_rest_services.get_case_info
# Returns: record<Results: record<AFRRows: string, CERCLARows: string, CWARows: string, Cases: list<record>, ClusterOutput: record<ClusterData: list>, ClusterRecords: string, CriminalRows: string, EPCRARows: string, FIFRARows: string, FedPenRows: string, FederalRows: string, JDCRows: string, MapLocations: string, Message: string, QueryParameters: list<record>, QueryRows: string, RCRARows: string, SDWARows: string, SEPRows: string, TSCARows: string>>
export def "post-case-rest-services-get-case-info" [
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
  --output: string@output-completer # Output Format Flag. Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding. - XML = Data model formatted as Extensible Markup Language.
  --p-case-category: string # Case Category Filter. Enter one or more case category codes to filter results. Provide multiple values as a comma-delimited list. - AFR = Administrative - Formal - AIF = Administrative - Informal - JDC = Judicial
  --p-case-status: string # Case Status Code Filter. Enter one or more case status codes to limit results. Provide multiple values as a comma-delimited list.
  --p-milestone: string # Administrative or Judicial Milestone Filter. Enter one or milestone values to restrict results. Provide multiple values as a comma-delimited list.
  --p-from-date: string # Administrative or Judicial Milestone Date Range Start Limiter. Enter a date value in MM/DD/YYYY format to limit milestone results. Parameter p_to_date must also be populated when using this parameter option.
  --p-to-date: string # Administrative or Judicial Milestone Date Range End Limiter. Enter a date value in MM/DD/YYYY format to limit milestone results. Parameter p_from_date must also be populated when using this parameter option.
  --p-milestone-fy: string # Administrative or Judicial Milestone Fiscal Year Limiter. Enter a single fiscal year value to limit milestone searches to a given fiscal year.
  --p-name: string # Case Name Filter. Enter one or more case names to restrict results. Provide multiple values as a comma-delimited list. When using this parameter the p_name_type parameter is required.
  --p-name-type: string # Case Name Filter Modifier.
  --p-case-number: string # Case Number Filter. Enter one or more case numbers to restrict results. Provide multiple values as a comma-delimited list.
  --p-docket-number: string # DOJ Docket Number Filter. Enter a single docket number or partial docket number to restrict results. Use "%" as a wildcard for more complex filtering.
  --p-court-docket-number: string
  --p-activity-number: string # Case Activity Number Filter. Enter a single case activity number to filter results.
  --p-case-lead: string@p-case-lead-completer # Case Lead Limiter. Enter E or S to limit results. - E = EPA is the case lead. - S = The state is the case lead.
  --p-case-sens-flg: string # Case Sensitive Data Flag. Enter a Y or N to include or exclude cases with sensitive data.
  --p-region: string@p-region-completer # EPA Region Filter. Provide a single value of 01 thru 10 to restrict results to a single EPA region.
  --p-state: string # Case Location State Filter. Enter one or more state USPS postal codes to filter results. Provide multiple values as a comma-delimited list.
  --p-district: string # Case Location Court District Limiter. Enter a single state court district code to limit results.
  --p-sic: string # Standard Industrial Classification (SIC) Code Filter. Enter a single 4-digit SIC Code to filter results.
  --p-sic-ao-naics: string@p-sic-ao-naics-completer # Case Location SIC/NAICS And/Or Modifier. Enter either AND or OR to govern the search logic of SIC and NAICS codes. - AND = Search will return results having both the provided SIC code(s) and provided NAICS code(s). - OR = Search will return results having either the provided SIC code(s) or the provided NAICS code(s).
  --p-sic-primary-flg: string@p-sic-primary-flg-completer # Case Location Primary SIC Flag. Enter Y to limit SIC search results to primary SIC codes only.
  --p-sic-frs-flg: string@p-sic-frs-flg-completer # Case Location Extended FRS SIC Search Flag. Enter Y to expand SIC search to include Federal Registry Service datasets.
  --p-naics: string # North American Industry Classification System Filter. Enter two to six digits to filter results to facilities having matching NAICS codes. Digits less than six will match to all codes beginning with the provided values.
  --p-naics-primary-flg: string@p-naics-primary-flg-completer # Case Location Primary NAICS Flag. Enter Y to limit NAICS search results to primary NAICS codes only.
  --p-naics-frs-flg: string@p-naics-frs-flg-completer # Case Location Extended FRS NAICS Search Flag. Enter Y to expand NAICS search to include Federal Registry Service datasets.
  --p-enf-type: string # Case Enforcement Type Filter. Enter one or more case enforcement type codes to limit results. Provide multiple values as a comma-delimited list.
  --p-law: string # Law Statute Code Filter. Enter a single statute code to limit results.
  --p-section: string # Law Section Code Filter. Enter one or more law section codes to limit results. Provide multiple values as a comma-delimited list.
  --p-cp-citation: string # Law Section Code Filter Alternative. Enter a single law section code to limit results. This parameter accepts partial codes and allows for advanced search modifiers.
  --p-rank-order: string@p-rank-order-completer # Law Status Rank Order Limiter. Enter a single integer rank order to limit results.
  --p-enf-program: string # Enforcement Program Code Limiter. Enter one or more enforcement program codes to limit results. Provide multiple values as a comma-delimited list.
  --p-violation: string # Violation Type Code Filter. Enter one or more violation type codes to limit results. Provide multiple values as a comma-delimited list.
  --p-priority-area: string # Case Priority Area Filter. Enter one or more case priority areas to limit results. Provide multiple values as a comma-delimited list.
  --p-priority-area-desc: string # Case Priority Area Description Filter. Enter a single case priority area description or partial case priority area description to limit results. Use "%" as a wild-card match for more complex searches.
  --p-tribal: string@p-tribal-completer # Case Location Tribal Land Flag. Enter Y or N to include or disallow cases on tribal land.
  --p-oeca-core: string@p-oeca-core-completer # OECA Core Program Flag. Enter Y or N to include or exclude core program cases.
  --p-multimedia: string@p-multimedia-completer # Enforcement Multimedia Case Flag. Enter Y or N to include or exclude multimedia cases.
  --p-fed-case: string@p-fed-case-completer # Federal Facility Involvement Flag. Enter a Y or N to include or exclude cases involving federal facilities.
  --p-activity-contact: string # Activity Contact Last Name Filter. Enter a single last name or partial last name to filter results. Use "%" as a wild-card for advanced searching.
  --p-role: string # Activity Contact Role Code Filter. Enter a single role code to restrict results.
  --p-fed-penalty: string@p-fed-penalty-completer # Federal Penalty Assessed Amount Filter. Provide one of the following keywords to restrict results. - ANY = cases with any penalty amount. - LE5000 = cases with penalty amount less than or equal to $5,000. - GT5000 = cases with penalty amount more than $5,000. - GT50000 = cases with penalty amount more than $50,000. - GT100000 = cases with penalty amount more than $100,000. - GT500000 = cases with penalty amount more than $500,000. - GT1000000 = cases with penalty amount more than $1,000,000. - GT2500000 = cases with penalty amount more than $2,500,000.
  --p-total-fed-penalty: string # Total Federal Penalty Limiter. Enter a keyword value to limit results to cases with given total federal penalties. - ANY = Cases with any federal penalty greater than zero. - LEXX = Replacing XX with a dollar value, return cases with federal penalty less than or equal to the given amount. - GTXX = Replacing XX with a dollar value, return cases with federal penalty greater than the given amount.
  --p-cost-recovery: string # Cost Recovery Awarded Amount Limiter. Enter a keyword value to limit results to cases with given cost recovery amounts. - ANY = Cases with any cost recovery amount greater than zero. - LEXX = Replacing XX with a dollar value, return cases with cost recovery amount less than or equal to the given amount. - GTXX = Replacing XX with a dollar value, return cases with cost recovery amount greater than the given amount.
  --p-total-cost-recovery: string # Total Cost Recovery Amount Limiter. Enter a keyword value to limit results to cases with given cost recovery amounts. - ANY = Cases with any cost recovery amount greater than zero. - LEXX = Replacing XX with a dollar value, return cases with cost recovery amount less than or equal to the given amount. - GTXX = Replacing XX with a dollar value, return cases with cost recovery amount greater than the given amount.
  --p-complying-actions: string # Complying Actions Type Code Limiter. Enter one or more complying action codes to restrict results. Provide multiple values as a comma-delimited list.
  --p-comp-act-val: string@p-comp-act-val-completer # Compliance Action Cost Limiter. Enter a keyword value to limit results to cases with given compliance cost amounts. - ANY = Cases with any compliance cost amount greater than zero. - LEXX = Replacing XX with a dollar value, return cases with compliance cost amount less than or equal to the given amount. - GTXX = Replacing XX with a dollar value, return cases with compliance cost amount greater than the given amount.
  --p-total-comp-act-val: string # Total Compliance Action Amount Limiter. Enter a keyword value to limit results to cases with given total compliance action amounts. - ANY = Cases with any total compliance action amount greater than zero. - LEXX = Replacing XX with a dollar value, return cases with total compliance action amount less than or equal to the given amount. - GTXX = Replacing XX with a dollar value, return cases with total compliance action amount greater than the given amount.
  --p-sep-cats: string # Supplemental Environmental Projects Activity Category Code Limiter. Provide one or more SEP activity category codes to limit results. Provide multiple values as a comma-delimited list.
  --p-sep-val: string@p-sep-val-completer # Supplemental Environmental Projects Activity Value Limiter. Provide a keyword to limit results. - ANY = return cases with any SEP activity amount. - LE10000 = return cases with SEP activity amount less than or equal to $10,000. - GT10000 = return cases with SEP activity amount greater than $10,000. - GT50000 = return cases with SEP activity amount greater than $50,000. - GT100000 = return cases with SEP activity amount greater than $100,000. - GT500000 = return cases with SEP activity amount greater than $500,000. - GT1000000 = return cases with SEP activity amount greater than $1,000,000.
  --p-total-sep-val: string # Supplemental Environmental Projects Total Value Limiter. Provide a keyword to limit results. - ANY = return cases with any SEP total amount. - LE10000 = return cases with SEP total amount less than or equal to $10,000. - GT10000 = return cases with SEP total amount greater than $10,000. - GT50000 = return cases with SEP total amount greater than $50,000. - GT100000 = return cases with SEP total amount greater than $100,000. - GT500000 = return cases with SEP total amount greater than $500,000. - GT1000000 = return cases with SEP total amount greater than $1,000,000.
  --p-lodged-date: string # Settlement Lodged Date Limiter. Enter a single settlement lodged date in MM/DD/YYYY format to limit results.
  --p-entered-date: string # Settlement Entered Date Limiter. Enter a single settlement entered date in MM/DD/YYYY format to limit results.
  --p-facility-id: string # Case Facility Registration Identifier Limiter. Enter a single complete facility identifier to limit results.
  --p-fac-city: string # Case Facility City Limiter. Enter a single complete city name to filter cases by facility location city.
  --p-fac-zip: string # Case Facility ZIP Code Limiter. Enter a single 5-digit zip code to filter cases by facility location zip code.
  --p-fac-county: string # Case Facility County Limiter. Enter a single complete county name to filter cases by facility location county name.
  --p-case-summary: string # Case Summary Search Limiter. Enter a single case summary to limit results. This parameter accepts partial codes and allows for advanced search modifiers.
  --p-case-summary-type: string@p-case-summary-type-completer # Identifies how the the search terms enterened in p_case_summary are searched. Valid values are ALL (Default), WITHIN, and CONTAINS. Must be used with p_case_summary.
  --p-usmex: string@p-usmex-completer # US-Mexico Border Flag. Enter Y/N to restrict searches to facilities located within 100KM of the border.
  --p-c1lat: float # In decimal degrees. Latitude of 1st corner of box that bounds the resulting facilities. The latitude and longitude of both corners of the bounding box must be provided.
  --p-c1lon: float # In decimal degrees. Longitude of 1st corner of box that bounds the resulting facilities. The latitude and longitude of both corners of the bounding box must be provided.
  --p-c2lat: float # In decimal degrees. Latitude of 2nd corner of box that bounds the resulting facilities. The latitude and longitude of both corners of the bounding box must be provided.
  --p-c2lon: float # In decimal degrees. Longitude of 2nd corner of box that bounds the resulting facilities. The latitude and longitude of both corners of the bounding box must be provided.
  --p-voluntary: string # Voluntary Self Disclosure Flag. Enter Y or N to include or exclude cases results having voluntary disclosure.
  --p-fed-indicator: string # Federal Facility/Cross Media Flag. Enter Y or N to limit results to cases with federal facility cross media.
  --p-fntype: string@p-fntype-completer # Controls type of text search performed on facility name with parameter p_fn. - EXACT = Find facilities having the exact provided name(s). - BEGINS = Find facilities with names starting with the provided term(s). - ALL = Find facilities using Oracle text search terms. - CONTAINS =
  --p-civil-criminal-indicator: string@p-civil-criminal-indicator-completer # Civil/Criminal Case Limiter. Provide a keyword to limit results. - ANY = return both civil and criminal cases. - CI = return only civil cases. - CR = return only criminal cases.
  --queryset: float # Query Limiter. Enter a value to limit the number of records returned for each query. Value cannot exceed 70,000.
  --responseset: float # Response Set Limiter. Enter a value to limit the number of records per page. Value cannot exceed 1,000.
  --mapset: string # Identifies the maxium number of case facilities to return from the case_rest_services.get_case_info query.
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
  --qcolumns: string # Used to customize service output. A list of comma-separated column IDs of output objects that will be returned in the service query object or download. Use the metadata service endpoint for a complete list of Ids and definitions.
  --p-pretty-print: float # Optional flag to request GeoJSON formatted results to be pretty printed. Only provide a numeric value when the output needs to be human readable as pretty printing has a performance cost.
  --p-ocmap-fy: string # Fiscal Year to select cases that are displayed in the Office of Complicance Fiscal Year Map Services
  --p-qs: string # Quick Search. Allows entry for city, state, and/or zip code.
  --p-has-map: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/case_rest_services.get_case_info"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: p_case_category, var: p_case_category}, {name: p_case_status, var: p_case_status}, {name: p_milestone, var: p_milestone}, {name: p_from_date, var: p_from_date}, {name: p_to_date, var: p_to_date}, {name: p_milestone_fy, var: p_milestone_fy}, {name: p_name, var: p_name}, {name: p_name_type, var: p_name_type}, {name: p_case_number, var: p_case_number}, {name: p_docket_number, var: p_docket_number}, {name: p_court_docket_number, var: p_court_docket_number}, {name: p_activity_number, var: p_activity_number}, {name: p_case_lead, var: p_case_lead}, {name: p_case_sens_flg, var: p_case_sens_flg}, {name: p_region, var: p_region}, {name: p_state, var: p_state}, {name: p_district, var: p_district}, {name: p_sic, var: p_sic}, {name: p_sic_ao_naics, var: p_sic_ao_naics}, {name: p_sic_primary_flg, var: p_sic_primary_flg}, {name: p_sic_frs_flg, var: p_sic_frs_flg}, {name: p_naics, var: p_naics}, {name: p_naics_primary_flg, var: p_naics_primary_flg}, {name: p_naics_frs_flg, var: p_naics_frs_flg}, {name: p_enf_type, var: p_enf_type}, {name: p_law, var: p_law}, {name: p_section, var: p_section}, {name: p_cp_citation, var: p_cp_citation}, {name: p_rank_order, var: p_rank_order}, {name: p_enf_program, var: p_enf_program}, {name: p_violation, var: p_violation}, {name: p_priority_area, var: p_priority_area}, {name: p_priority_area_desc, var: p_priority_area_desc}, {name: p_tribal, var: p_tribal}, {name: p_oeca_core, var: p_oeca_core}, {name: p_multimedia, var: p_multimedia}, {name: p_fed_case, var: p_fed_case}, {name: p_activity_contact, var: p_activity_contact}, {name: p_role, var: p_role}, {name: p_fed_penalty, var: p_fed_penalty}, {name: p_total_fed_penalty, var: p_total_fed_penalty}, {name: p_cost_recovery, var: p_cost_recovery}, {name: p_total_cost_recovery, var: p_total_cost_recovery}, {name: p_complying_actions, var: p_complying_actions}, {name: p_comp_act_val, var: p_comp_act_val}, {name: p_total_comp_act_val, var: p_total_comp_act_val}, {name: p_sep_cats, var: p_sep_cats}, {name: p_sep_val, var: p_sep_val}, {name: p_total_sep_val, var: p_total_sep_val}, {name: p_lodged_date, var: p_lodged_date}, {name: p_entered_date, var: p_entered_date}, {name: p_facility_id, var: p_facility_id}, {name: p_fac_city, var: p_fac_city}, {name: p_fac_zip, var: p_fac_zip}, {name: p_fac_county, var: p_fac_county}, {name: p_case_summary, var: p_case_summary}, {name: p_case_summary_type, var: p_case_summary_type}, {name: p_usmex, var: p_usmex}, {name: p_c1lat, var: p_c1lat}, {name: p_c1lon, var: p_c1lon}, {name: p_c2lat, var: p_c2lat}, {name: p_c2lon, var: p_c2lon}, {name: p_voluntary, var: p_voluntary}, {name: p_fed_indicator, var: p_fed_indicator}, {name: p_fntype, var: p_fntype}, {name: p_civil_criminal_indicator, var: p_civil_criminal_indicator}, {name: queryset, var: queryset}, {name: responseset, var: responseset}, {name: mapset, var: mapset}, {name: callback, var: callback}, {name: qcolumns, var: qcolumns}, {name: p_pretty_print, var: p_pretty_print}, {name: p_ocmap_fy, var: p_ocmap_fy}, {name: p_qs, var: p_qs}, {name: p_has_map, var: p_has_map}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_case_category: $p_case_category, p_case_status: $p_case_status, p_milestone: $p_milestone, p_from_date: $p_from_date, p_to_date: $p_to_date, p_milestone_fy: $p_milestone_fy, p_name: $p_name, p_name_type: $p_name_type, p_case_number: $p_case_number, p_docket_number: $p_docket_number, p_court_docket_number: $p_court_docket_number, p_activity_number: $p_activity_number, p_case_lead: $p_case_lead, p_case_sens_flg: $p_case_sens_flg, p_region: $p_region, p_state: $p_state, p_district: $p_district, p_sic: $p_sic, p_sic_ao_naics: $p_sic_ao_naics, p_sic_primary_flg: $p_sic_primary_flg, p_sic_frs_flg: $p_sic_frs_flg, p_naics: $p_naics, p_naics_primary_flg: $p_naics_primary_flg, p_naics_frs_flg: $p_naics_frs_flg, p_enf_type: $p_enf_type, p_law: $p_law, p_section: $p_section, p_cp_citation: $p_cp_citation, p_rank_order: $p_rank_order, p_enf_program: $p_enf_program, p_violation: $p_violation, p_priority_area: $p_priority_area, p_priority_area_desc: $p_priority_area_desc, p_tribal: $p_tribal, p_oeca_core: $p_oeca_core, p_multimedia: $p_multimedia, p_fed_case: $p_fed_case, p_activity_contact: $p_activity_contact, p_role: $p_role, p_fed_penalty: $p_fed_penalty, p_total_fed_penalty: $p_total_fed_penalty, p_cost_recovery: $p_cost_recovery, p_total_cost_recovery: $p_total_cost_recovery, p_complying_actions: $p_complying_actions, p_comp_act_val: $p_comp_act_val, p_total_comp_act_val: $p_total_comp_act_val, p_sep_cats: $p_sep_cats, p_sep_val: $p_sep_val, p_total_sep_val: $p_total_sep_val, p_lodged_date: $p_lodged_date, p_entered_date: $p_entered_date, p_facility_id: $p_facility_id, p_fac_city: $p_fac_city, p_fac_zip: $p_fac_zip, p_fac_county: $p_fac_county, p_case_summary: $p_case_summary, p_case_summary_type: $p_case_summary_type, p_usmex: $p_usmex, p_c1lat: $p_c1lat, p_c1lon: $p_c1lon, p_c2lat: $p_c2lat, p_c2lon: $p_c2lon, p_voluntary: $p_voluntary, p_fed_indicator: $p_fed_indicator, p_fntype: $p_fntype, p_civil_criminal_indicator: $p_civil_criminal_indicator, queryset: $queryset, responseset: $responseset, mapset: $mapset, callback: $callback, qcolumns: $qcolumns, p_pretty_print: $p_pretty_print, p_ocmap_fy: $p_ocmap_fy, p_qs: $p_qs, p_has_map: $p_has_map
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Enforcement Case Summary Report Search
#
# GET /case_rest_services.get_case_report
# Returns: record<Results: record<CAEDDocuments: list<record>, CaseInformation: record<Branch: string, CaseName: string, CaseNumber: string, CaseStatus: string, CaseStatusDate: string, CaseSummary: string, CaseType: string, DOJDocketNumber: string, EnforcementOutcome: string, EnforcementType: string, HeadquartersDivision: string, Lead: string, MultiMediaCase: string, RegionalDocketNumber: string, ReliefSought: string, ResultVolDisclosure: string, TotalComplianceActionCost: string, TotalCostRecovery: string, TotalFederalPenalty: string, TotalSEPCost: string, TotalStatePenalty: string, Violations: string>, CaseMilestones: list<record>, Citations: list<record>, Defendants: list<record>, EnforcementConclusions: list<record>, Facilities: list<record>, LawsAndSections: list<record>, Message: string, Pollutants: list<record>, ProgramLinks: list<record>, RelatedActivities: list<record>>>
export def "get-case-rest-services-get-case-report" [
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
  --p-id: string # Case Number. Enter the case number identifier to retrieve the case report.
  --output: string@output-completer # Output Format Flag. Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding. - XML = Data model formatted as Extensible Markup Language.
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/case_rest_services.get_case_report"
    query: [{name: p_id, var: p_id}, {name: output, var: output}, {name: callback, var: callback}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    p_id: $p_id, output: $output, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Enforcement Case Summary Report Search
#
# POST /case_rest_services.get_case_report
# Returns: record<Results: record<CAEDDocuments: list<record>, CaseInformation: record<Branch: string, CaseName: string, CaseNumber: string, CaseStatus: string, CaseStatusDate: string, CaseSummary: string, CaseType: string, DOJDocketNumber: string, EnforcementOutcome: string, EnforcementType: string, HeadquartersDivision: string, Lead: string, MultiMediaCase: string, RegionalDocketNumber: string, ReliefSought: string, ResultVolDisclosure: string, TotalComplianceActionCost: string, TotalCostRecovery: string, TotalFederalPenalty: string, TotalSEPCost: string, TotalStatePenalty: string, Violations: string>, CaseMilestones: list<record>, Citations: list<record>, Defendants: list<record>, EnforcementConclusions: list<record>, Facilities: list<record>, LawsAndSections: list<record>, Message: string, Pollutants: list<record>, ProgramLinks: list<record>, RelatedActivities: list<record>>>
export def "post-case-rest-services-get-case-report" [
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
  --p-id: string # Case Number. Enter the case number identifier to retrieve the case report.
  --output: string@output-completer # Output Format Flag. Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding. - XML = Data model formatted as Extensible Markup Language.
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/case_rest_services.get_case_report"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: p_id, var: p_id}, {name: output, var: output}, {name: callback, var: callback}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    p_id: $p_id, output: $output, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Enforcement Case Search
#
# GET /case_rest_services.get_cases
# Returns: record<Results: record<AFRRows: string, CAARows: string, CERCLARows: string, CWARows: string, Cases: list<record>, CriminalRows: string, EPCRARows: string, FIFRARows: string, FedPenRows: string, FederalRows: string, JDCRows: string, MapOutput: record<IconBaseURL: string, MapData: list, PopUpBaseURL: string, QueryID: string>, Message: string, PageNo: string, QueryID: string, QueryRows: string, RCRARows: string, SDWARows: string, SEPRows: string, TSCARows: string>>
export def "get-case-rest-services-get-cases" [
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
  --output: string@output-completer # Output Format Flag. Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding. - XML = Data model formatted as Extensible Markup Language.
  --p-case-category: string # Case Category Filter. Enter one or more case category codes to filter results. Provide multiple values as a comma-delimited list. - AFR = Administrative - Formal - AIF = Administrative - Informal - JDC = Judicial
  --p-case-status: string # Case Status Code Filter. Enter one or more case status codes to limit results. Provide multiple values as a comma-delimited list.
  --p-violation: string # Violation Type Code Filter. Enter one or more violation type codes to limit results. Provide multiple values as a comma-delimited list.
  --p-milestone: string # Administrative or Judicial Milestone Filter. Enter one or milestone values to restrict results. Provide multiple values as a comma-delimited list.
  --p-from-date: string # Administrative or Judicial Milestone Date Range Start Limiter. Enter a date value in MM/DD/YYYY format to limit milestone results. Parameter p_to_date must also be populated when using this parameter option.
  --p-to-date: string # Administrative or Judicial Milestone Date Range End Limiter. Enter a date value in MM/DD/YYYY format to limit milestone results. Parameter p_from_date must also be populated when using this parameter option.
  --p-milestone-fy: string # Administrative or Judicial Milestone Fiscal Year Limiter. Enter a single fiscal year value to limit milestone searches to a given fiscal year.
  --p-name: string # Case Name Filter. Enter one or more case names to restrict results. Provide multiple values as a comma-delimited list. When using this parameter the p_name_type parameter is required.
  --p-name-type: string # Case Name Filter Modifier.
  --p-case-number: string # Case Number Filter. Enter one or more case numbers to restrict results. Provide multiple values as a comma-delimited list.
  --p-docket-number: string # DOJ Docket Number Filter. Enter a single docket number or partial docket number to restrict results. Use "%" as a wildcard for more complex filtering.
  --p-court-docket-number: string
  --p-activity-number: string # Case Activity Number Filter. Enter a single case activity number to filter results.
  --p-case-lead: string@p-case-lead-completer # Case Lead Limiter. Enter E or S to limit results. - E = EPA is the case lead. - S = The state is the case lead.
  --p-case-sens-flg: string # Case Sensitive Data Flag. Enter a Y or N to include or exclude cases with sensitive data.
  --p-region: string@p-region-completer # EPA Region Filter. Provide a single value of 01 thru 10 to restrict results to a single EPA region.
  --p-state: string # Case Location State Filter. Enter one or more state USPS postal codes to filter results. Provide multiple values as a comma-delimited list.
  --p-district: string # Case Location Court District Limiter. Enter a single state court district code to limit results.
  --p-sic: string # Standard Industrial Classification (SIC) Code Filter. Enter a single 4-digit SIC Code to filter results.
  --p-sic-ao-naics: string@p-sic-ao-naics-completer # Case Location SIC/NAICS And/Or Modifier. Enter either AND or OR to govern the search logic of SIC and NAICS codes. - AND = Search will return results having both the provided SIC code(s) and provided NAICS code(s). - OR = Search will return results having either the provided SIC code(s) or the provided NAICS code(s).
  --p-sic-primary-flg: string@p-sic-primary-flg-completer # Case Location Primary SIC Flag. Enter Y to limit SIC search results to primary SIC codes only.
  --p-sic-frs-flg: string@p-sic-frs-flg-completer # Case Location Extended FRS SIC Search Flag. Enter Y to expand SIC search to include Federal Registry Service datasets.
  --p-naics: string # North American Industry Classification System Filter. Enter two to six digits to filter results to facilities having matching NAICS codes. Digits less than six will match to all codes beginning with the provided values.
  --p-naics-primary-flg: string@p-naics-primary-flg-completer # Case Location Primary NAICS Flag. Enter Y to limit NAICS search results to primary NAICS codes only.
  --p-naics-frs-flg: string@p-naics-frs-flg-completer # Case Location Extended FRS NAICS Search Flag. Enter Y to expand NAICS search to include Federal Registry Service datasets.
  --p-enf-type: string # Case Enforcement Type Filter. Enter one or more case enforcement type codes to limit results. Provide multiple values as a comma-delimited list.
  --p-law: string # Law Statute Code Filter. Enter a single statute code to limit results.
  --p-section: string # Law Section Code Filter. Enter one or more law section codes to limit results. Provide multiple values as a comma-delimited list.
  --p-cp-citation: string # Law Section Code Filter Alternative. Enter a single law section code to limit results. This parameter accepts partial codes and allows for advanced search modifiers.
  --p-rank-order: string@p-rank-order-completer # Law Status Rank Order Limiter. Enter a single integer rank order to limit results.
  --p-enf-program: string # Enforcement Program Code Limiter. Enter one or more enforcement program codes to limit results. Provide multiple values as a comma-delimited list.
  --p-priority-area: string # Case Priority Area Filter. Enter one or more case priority areas to limit results. Provide multiple values as a comma-delimited list.
  --p-priority-area-desc: string # Case Priority Area Description Filter. Enter a single case priority area description or partial case priority area description to limit results. Use "%" as a wild-card match for more complex searches.
  --p-tribal: string@p-tribal-completer # Case Location Tribal Land Flag. Enter Y or N to include or disallow cases on tribal land.
  --p-oeca-core: string@p-oeca-core-completer # OECA Core Program Flag. Enter Y or N to include or exclude core program cases.
  --p-multimedia: string@p-multimedia-completer # Enforcement Multimedia Case Flag. Enter Y or N to include or exclude multimedia cases.
  --p-fed-case: string@p-fed-case-completer # Federal Facility Involvement Flag. Enter a Y or N to include or exclude cases involving federal facilities.
  --p-activity-contact: string # Activity Contact Last Name Filter. Enter a single last name or partial last name to filter results. Use "%" as a wild-card for advanced searching.
  --p-role: string # Activity Contact Role Code Filter. Enter a single role code to restrict results.
  --p-fed-penalty: string@p-fed-penalty-completer # Federal Penalty Assessed Amount Filter. Provide one of the following keywords to restrict results. - ANY = cases with any penalty amount. - LE5000 = cases with penalty amount less than or equal to $5,000. - GT5000 = cases with penalty amount more than $5,000. - GT50000 = cases with penalty amount more than $50,000. - GT100000 = cases with penalty amount more than $100,000. - GT500000 = cases with penalty amount more than $500,000. - GT1000000 = cases with penalty amount more than $1,000,000. - GT2500000 = cases with penalty amount more than $2,500,000.
  --p-total-fed-penalty: string # Total Federal Penalty Limiter. Enter a keyword value to limit results to cases with given total federal penalties. - ANY = Cases with any federal penalty greater than zero. - LEXX = Replacing XX with a dollar value, return cases with federal penalty less than or equal to the given amount. - GTXX = Replacing XX with a dollar value, return cases with federal penalty greater than the given amount.
  --p-cost-recovery: string # Cost Recovery Awarded Amount Limiter. Enter a keyword value to limit results to cases with given cost recovery amounts. - ANY = Cases with any cost recovery amount greater than zero. - LEXX = Replacing XX with a dollar value, return cases with cost recovery amount less than or equal to the given amount. - GTXX = Replacing XX with a dollar value, return cases with cost recovery amount greater than the given amount.
  --p-total-cost-recovery: string # Total Cost Recovery Amount Limiter. Enter a keyword value to limit results to cases with given cost recovery amounts. - ANY = Cases with any cost recovery amount greater than zero. - LEXX = Replacing XX with a dollar value, return cases with cost recovery amount less than or equal to the given amount. - GTXX = Replacing XX with a dollar value, return cases with cost recovery amount greater than the given amount.
  --p-complying-actions: string # Complying Actions Type Code Limiter. Enter one or more complying action codes to restrict results. Provide multiple values as a comma-delimited list.
  --p-comp-act-val: string@p-comp-act-val-completer # Compliance Action Cost Limiter. Enter a keyword value to limit results to cases with given compliance cost amounts. - ANY = Cases with any compliance cost amount greater than zero. - LEXX = Replacing XX with a dollar value, return cases with compliance cost amount less than or equal to the given amount. - GTXX = Replacing XX with a dollar value, return cases with compliance cost amount greater than the given amount.
  --p-total-comp-act-val: string # Total Compliance Action Amount Limiter. Enter a keyword value to limit results to cases with given total compliance action amounts. - ANY = Cases with any total compliance action amount greater than zero. - LEXX = Replacing XX with a dollar value, return cases with total compliance action amount less than or equal to the given amount. - GTXX = Replacing XX with a dollar value, return cases with total compliance action amount greater than the given amount.
  --p-sep-cats: string # Supplemental Environmental Projects Activity Category Code Limiter. Provide one or more SEP activity category codes to limit results. Provide multiple values as a comma-delimited list.
  --p-sep-val: string@p-sep-val-completer # Supplemental Environmental Projects Activity Value Limiter. Provide a keyword to limit results. - ANY = return cases with any SEP activity amount. - LE10000 = return cases with SEP activity amount less than or equal to $10,000. - GT10000 = return cases with SEP activity amount greater than $10,000. - GT50000 = return cases with SEP activity amount greater than $50,000. - GT100000 = return cases with SEP activity amount greater than $100,000. - GT500000 = return cases with SEP activity amount greater than $500,000. - GT1000000 = return cases with SEP activity amount greater than $1,000,000.
  --p-total-sep-val: string # Supplemental Environmental Projects Total Value Limiter. Provide a keyword to limit results. - ANY = return cases with any SEP total amount. - LE10000 = return cases with SEP total amount less than or equal to $10,000. - GT10000 = return cases with SEP total amount greater than $10,000. - GT50000 = return cases with SEP total amount greater than $50,000. - GT100000 = return cases with SEP total amount greater than $100,000. - GT500000 = return cases with SEP total amount greater than $500,000. - GT1000000 = return cases with SEP total amount greater than $1,000,000.
  --p-lodged-date: string # Settlement Lodged Date Limiter. Enter a single settlement lodged date in MM/DD/YYYY format to limit results.
  --p-entered-date: string # Settlement Entered Date Limiter. Enter a single settlement entered date in MM/DD/YYYY format to limit results.
  --p-facility-id: string # Case Facility Registration Identifier Limiter. Enter a single complete facility identifier to limit results.
  --p-fac-city: string # Case Facility City Limiter. Enter a single complete city name to filter cases by facility location city.
  --p-fac-zip: string # Case Facility ZIP Code Limiter. Enter a single 5-digit zip code to filter cases by facility location zip code.
  --p-fac-county: string # Case Facility County Limiter. Enter a single complete county name to filter cases by facility location county name.
  --p-case-summary: string # Case Summary Search Limiter. Enter a single case summary to limit results. This parameter accepts partial codes and allows for advanced search modifiers.
  --p-case-summary-type: string@p-case-summary-type-completer # Identifies how the the search terms enterened in p_case_summary are searched. Valid values are ALL (Default), WITHIN, and CONTAINS. Must be used with p_case_summary.
  --p-usmex: string@p-usmex-completer # US-Mexico Border Flag. Enter Y/N to restrict searches to facilities located within 100KM of the border.
  --p-c1lat: float # In decimal degrees. Latitude of 1st corner of box that bounds the resulting facilities. The latitude and longitude of both corners of the bounding box must be provided.
  --p-c1lon: float # In decimal degrees. Longitude of 1st corner of box that bounds the resulting facilities. The latitude and longitude of both corners of the bounding box must be provided.
  --p-c2lat: float # In decimal degrees. Latitude of 2nd corner of box that bounds the resulting facilities. The latitude and longitude of both corners of the bounding box must be provided.
  --p-c2lon: float # In decimal degrees. Longitude of 2nd corner of box that bounds the resulting facilities. The latitude and longitude of both corners of the bounding box must be provided.
  --p-voluntary: string # Voluntary Self Disclosure Flag. Enter Y or N to include or exclude cases results having voluntary disclosure.
  --p-fed-indicator: string # Federal Facility/Cross Media Flag. Enter Y or N to limit results to cases with federal facility cross media.
  --p-fntype: string@p-fntype-completer # Controls type of text search performed on facility name with parameter p_fn. - EXACT = Find facilities having the exact provided name(s). - BEGINS = Find facilities with names starting with the provided term(s). - ALL = Find facilities using Oracle text search terms. - CONTAINS =
  --p-civil-criminal-indicator: string@p-civil-criminal-indicator-completer # Civil/Criminal Case Limiter. Provide a keyword to limit results. - ANY = return both civil and criminal cases. - CI = return only civil cases. - CR = return only criminal cases.
  --queryset: float # Query Limiter. Enter a value to limit the number of records returned for each query. Value cannot exceed 70,000.
  --responseset: float # Response Set Limiter. Enter a value to limit the number of records per page. Value cannot exceed 1,000.
  --maplist: string@maplist-completer # Map List Flag. Provide a Y to return mappable coordinates representing the full geographic extent of the queryset (all facilities that met the selection criteria).
  --tablelist: string@tablelist-completer # Table List Flag. Enter a Y to display the first page of facility results.
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
  --qcolumns: string # Used to customize service output. A list of comma-separated column IDs of output objects that will be returned in the service query object or download. Use the metadata service endpoint for a complete list of Ids and definitions.
  --p-ocmap-fy: string # Fiscal Year to select cases that are displayed in the Office of Complicance Fiscal Year Map Services
  --p-qs: string # Quick Search. Allows entry for city, state, and/or zip code.
  --p-has-map: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/case_rest_services.get_cases"
    query: [{name: output, var: output}, {name: p_case_category, var: p_case_category}, {name: p_case_status, var: p_case_status}, {name: p_violation, var: p_violation}, {name: p_milestone, var: p_milestone}, {name: p_from_date, var: p_from_date}, {name: p_to_date, var: p_to_date}, {name: p_milestone_fy, var: p_milestone_fy}, {name: p_name, var: p_name}, {name: p_name_type, var: p_name_type}, {name: p_case_number, var: p_case_number}, {name: p_docket_number, var: p_docket_number}, {name: p_court_docket_number, var: p_court_docket_number}, {name: p_activity_number, var: p_activity_number}, {name: p_case_lead, var: p_case_lead}, {name: p_case_sens_flg, var: p_case_sens_flg}, {name: p_region, var: p_region}, {name: p_state, var: p_state}, {name: p_district, var: p_district}, {name: p_sic, var: p_sic}, {name: p_sic_ao_naics, var: p_sic_ao_naics}, {name: p_sic_primary_flg, var: p_sic_primary_flg}, {name: p_sic_frs_flg, var: p_sic_frs_flg}, {name: p_naics, var: p_naics}, {name: p_naics_primary_flg, var: p_naics_primary_flg}, {name: p_naics_frs_flg, var: p_naics_frs_flg}, {name: p_enf_type, var: p_enf_type}, {name: p_law, var: p_law}, {name: p_section, var: p_section}, {name: p_cp_citation, var: p_cp_citation}, {name: p_rank_order, var: p_rank_order}, {name: p_enf_program, var: p_enf_program}, {name: p_priority_area, var: p_priority_area}, {name: p_priority_area_desc, var: p_priority_area_desc}, {name: p_tribal, var: p_tribal}, {name: p_oeca_core, var: p_oeca_core}, {name: p_multimedia, var: p_multimedia}, {name: p_fed_case, var: p_fed_case}, {name: p_activity_contact, var: p_activity_contact}, {name: p_role, var: p_role}, {name: p_fed_penalty, var: p_fed_penalty}, {name: p_total_fed_penalty, var: p_total_fed_penalty}, {name: p_cost_recovery, var: p_cost_recovery}, {name: p_total_cost_recovery, var: p_total_cost_recovery}, {name: p_complying_actions, var: p_complying_actions}, {name: p_comp_act_val, var: p_comp_act_val}, {name: p_total_comp_act_val, var: p_total_comp_act_val}, {name: p_sep_cats, var: p_sep_cats}, {name: p_sep_val, var: p_sep_val}, {name: p_total_sep_val, var: p_total_sep_val}, {name: p_lodged_date, var: p_lodged_date}, {name: p_entered_date, var: p_entered_date}, {name: p_facility_id, var: p_facility_id}, {name: p_fac_city, var: p_fac_city}, {name: p_fac_zip, var: p_fac_zip}, {name: p_fac_county, var: p_fac_county}, {name: p_case_summary, var: p_case_summary}, {name: p_case_summary_type, var: p_case_summary_type}, {name: p_usmex, var: p_usmex}, {name: p_c1lat, var: p_c1lat}, {name: p_c1lon, var: p_c1lon}, {name: p_c2lat, var: p_c2lat}, {name: p_c2lon, var: p_c2lon}, {name: p_voluntary, var: p_voluntary}, {name: p_fed_indicator, var: p_fed_indicator}, {name: p_fntype, var: p_fntype}, {name: p_civil_criminal_indicator, var: p_civil_criminal_indicator}, {name: queryset, var: queryset}, {name: responseset, var: responseset}, {name: maplist, var: maplist}, {name: tablelist, var: tablelist}, {name: callback, var: callback}, {name: qcolumns, var: qcolumns}, {name: p_ocmap_fy, var: p_ocmap_fy}, {name: p_qs, var: p_qs}, {name: p_has_map, var: p_has_map}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_case_category: $p_case_category, p_case_status: $p_case_status, p_violation: $p_violation, p_milestone: $p_milestone, p_from_date: $p_from_date, p_to_date: $p_to_date, p_milestone_fy: $p_milestone_fy, p_name: $p_name, p_name_type: $p_name_type, p_case_number: $p_case_number, p_docket_number: $p_docket_number, p_court_docket_number: $p_court_docket_number, p_activity_number: $p_activity_number, p_case_lead: $p_case_lead, p_case_sens_flg: $p_case_sens_flg, p_region: $p_region, p_state: $p_state, p_district: $p_district, p_sic: $p_sic, p_sic_ao_naics: $p_sic_ao_naics, p_sic_primary_flg: $p_sic_primary_flg, p_sic_frs_flg: $p_sic_frs_flg, p_naics: $p_naics, p_naics_primary_flg: $p_naics_primary_flg, p_naics_frs_flg: $p_naics_frs_flg, p_enf_type: $p_enf_type, p_law: $p_law, p_section: $p_section, p_cp_citation: $p_cp_citation, p_rank_order: $p_rank_order, p_enf_program: $p_enf_program, p_priority_area: $p_priority_area, p_priority_area_desc: $p_priority_area_desc, p_tribal: $p_tribal, p_oeca_core: $p_oeca_core, p_multimedia: $p_multimedia, p_fed_case: $p_fed_case, p_activity_contact: $p_activity_contact, p_role: $p_role, p_fed_penalty: $p_fed_penalty, p_total_fed_penalty: $p_total_fed_penalty, p_cost_recovery: $p_cost_recovery, p_total_cost_recovery: $p_total_cost_recovery, p_complying_actions: $p_complying_actions, p_comp_act_val: $p_comp_act_val, p_total_comp_act_val: $p_total_comp_act_val, p_sep_cats: $p_sep_cats, p_sep_val: $p_sep_val, p_total_sep_val: $p_total_sep_val, p_lodged_date: $p_lodged_date, p_entered_date: $p_entered_date, p_facility_id: $p_facility_id, p_fac_city: $p_fac_city, p_fac_zip: $p_fac_zip, p_fac_county: $p_fac_county, p_case_summary: $p_case_summary, p_case_summary_type: $p_case_summary_type, p_usmex: $p_usmex, p_c1lat: $p_c1lat, p_c1lon: $p_c1lon, p_c2lat: $p_c2lat, p_c2lon: $p_c2lon, p_voluntary: $p_voluntary, p_fed_indicator: $p_fed_indicator, p_fntype: $p_fntype, p_civil_criminal_indicator: $p_civil_criminal_indicator, queryset: $queryset, responseset: $responseset, maplist: $maplist, tablelist: $tablelist, callback: $callback, qcolumns: $qcolumns, p_ocmap_fy: $p_ocmap_fy, p_qs: $p_qs, p_has_map: $p_has_map
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Enforcement Case Search
#
# POST /case_rest_services.get_cases
# Returns: record<Results: record<AFRRows: string, CAARows: string, CERCLARows: string, CWARows: string, Cases: list<record>, CriminalRows: string, EPCRARows: string, FIFRARows: string, FedPenRows: string, FederalRows: string, JDCRows: string, MapOutput: record<IconBaseURL: string, MapData: list, PopUpBaseURL: string, QueryID: string>, Message: string, PageNo: string, QueryID: string, QueryRows: string, RCRARows: string, SDWARows: string, SEPRows: string, TSCARows: string>>
export def "post-case-rest-services-get-cases" [
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
  --output: string@output-completer # Output Format Flag. Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding. - XML = Data model formatted as Extensible Markup Language.
  --p-case-category: string # Case Category Filter. Enter one or more case category codes to filter results. Provide multiple values as a comma-delimited list. - AFR = Administrative - Formal - AIF = Administrative - Informal - JDC = Judicial
  --p-case-status: string # Case Status Code Filter. Enter one or more case status codes to limit results. Provide multiple values as a comma-delimited list.
  --p-milestone: string # Administrative or Judicial Milestone Filter. Enter one or milestone values to restrict results. Provide multiple values as a comma-delimited list.
  --p-from-date: string # Administrative or Judicial Milestone Date Range Start Limiter. Enter a date value in MM/DD/YYYY format to limit milestone results. Parameter p_to_date must also be populated when using this parameter option.
  --p-to-date: string # Administrative or Judicial Milestone Date Range End Limiter. Enter a date value in MM/DD/YYYY format to limit milestone results. Parameter p_from_date must also be populated when using this parameter option.
  --p-milestone-fy: string # Administrative or Judicial Milestone Fiscal Year Limiter. Enter a single fiscal year value to limit milestone searches to a given fiscal year.
  --p-name: string # Case Name Filter. Enter one or more case names to restrict results. Provide multiple values as a comma-delimited list. When using this parameter the p_name_type parameter is required.
  --p-name-type: string # Case Name Filter Modifier.
  --p-case-number: string # Case Number Filter. Enter one or more case numbers to restrict results. Provide multiple values as a comma-delimited list.
  --p-docket-number: string # DOJ Docket Number Filter. Enter a single docket number or partial docket number to restrict results. Use "%" as a wildcard for more complex filtering.
  --p-court-docket-number: string
  --p-activity-number: string # Case Activity Number Filter. Enter a single case activity number to filter results.
  --p-case-lead: string@p-case-lead-completer # Case Lead Limiter. Enter E or S to limit results. - E = EPA is the case lead. - S = The state is the case lead.
  --p-case-sens-flg: string # Case Sensitive Data Flag. Enter a Y or N to include or exclude cases with sensitive data.
  --p-region: string@p-region-completer # EPA Region Filter. Provide a single value of 01 thru 10 to restrict results to a single EPA region.
  --p-state: string # Case Location State Filter. Enter one or more state USPS postal codes to filter results. Provide multiple values as a comma-delimited list.
  --p-district: string # Case Location Court District Limiter. Enter a single state court district code to limit results.
  --p-sic: string # Standard Industrial Classification (SIC) Code Filter. Enter a single 4-digit SIC Code to filter results.
  --p-sic-ao-naics: string@p-sic-ao-naics-completer # Case Location SIC/NAICS And/Or Modifier. Enter either AND or OR to govern the search logic of SIC and NAICS codes. - AND = Search will return results having both the provided SIC code(s) and provided NAICS code(s). - OR = Search will return results having either the provided SIC code(s) or the provided NAICS code(s).
  --p-sic-primary-flg: string@p-sic-primary-flg-completer # Case Location Primary SIC Flag. Enter Y to limit SIC search results to primary SIC codes only.
  --p-sic-frs-flg: string@p-sic-frs-flg-completer # Case Location Extended FRS SIC Search Flag. Enter Y to expand SIC search to include Federal Registry Service datasets.
  --p-naics: string # North American Industry Classification System Filter. Enter two to six digits to filter results to facilities having matching NAICS codes. Digits less than six will match to all codes beginning with the provided values.
  --p-naics-primary-flg: string@p-naics-primary-flg-completer # Case Location Primary NAICS Flag. Enter Y to limit NAICS search results to primary NAICS codes only.
  --p-naics-frs-flg: string@p-naics-frs-flg-completer # Case Location Extended FRS NAICS Search Flag. Enter Y to expand NAICS search to include Federal Registry Service datasets.
  --p-enf-type: string # Case Enforcement Type Filter. Enter one or more case enforcement type codes to limit results. Provide multiple values as a comma-delimited list.
  --p-law: string # Law Statute Code Filter. Enter a single statute code to limit results.
  --p-section: string # Law Section Code Filter. Enter one or more law section codes to limit results. Provide multiple values as a comma-delimited list.
  --p-cp-citation: string # Law Section Code Filter Alternative. Enter a single law section code to limit results. This parameter accepts partial codes and allows for advanced search modifiers.
  --p-rank-order: string@p-rank-order-completer # Law Status Rank Order Limiter. Enter a single integer rank order to limit results.
  --p-enf-program: string # Enforcement Program Code Limiter. Enter one or more enforcement program codes to limit results. Provide multiple values as a comma-delimited list.
  --p-violation: string # Violation Type Code Filter. Enter one or more violation type codes to limit results. Provide multiple values as a comma-delimited list.
  --p-priority-area: string # Case Priority Area Filter. Enter one or more case priority areas to limit results. Provide multiple values as a comma-delimited list.
  --p-priority-area-desc: string # Case Priority Area Description Filter. Enter a single case priority area description or partial case priority area description to limit results. Use "%" as a wild-card match for more complex searches.
  --p-tribal: string@p-tribal-completer # Case Location Tribal Land Flag. Enter Y or N to include or disallow cases on tribal land.
  --p-oeca-core: string@p-oeca-core-completer # OECA Core Program Flag. Enter Y or N to include or exclude core program cases.
  --p-multimedia: string@p-multimedia-completer # Enforcement Multimedia Case Flag. Enter Y or N to include or exclude multimedia cases.
  --p-fed-case: string@p-fed-case-completer # Federal Facility Involvement Flag. Enter a Y or N to include or exclude cases involving federal facilities.
  --p-activity-contact: string # Activity Contact Last Name Filter. Enter a single last name or partial last name to filter results. Use "%" as a wild-card for advanced searching.
  --p-role: string # Activity Contact Role Code Filter. Enter a single role code to restrict results.
  --p-fed-penalty: string@p-fed-penalty-completer # Federal Penalty Assessed Amount Filter. Provide one of the following keywords to restrict results. - ANY = cases with any penalty amount. - LE5000 = cases with penalty amount less than or equal to $5,000. - GT5000 = cases with penalty amount more than $5,000. - GT50000 = cases with penalty amount more than $50,000. - GT100000 = cases with penalty amount more than $100,000. - GT500000 = cases with penalty amount more than $500,000. - GT1000000 = cases with penalty amount more than $1,000,000. - GT2500000 = cases with penalty amount more than $2,500,000.
  --p-total-fed-penalty: string # Total Federal Penalty Limiter. Enter a keyword value to limit results to cases with given total federal penalties. - ANY = Cases with any federal penalty greater than zero. - LEXX = Replacing XX with a dollar value, return cases with federal penalty less than or equal to the given amount. - GTXX = Replacing XX with a dollar value, return cases with federal penalty greater than the given amount.
  --p-cost-recovery: string # Cost Recovery Awarded Amount Limiter. Enter a keyword value to limit results to cases with given cost recovery amounts. - ANY = Cases with any cost recovery amount greater than zero. - LEXX = Replacing XX with a dollar value, return cases with cost recovery amount less than or equal to the given amount. - GTXX = Replacing XX with a dollar value, return cases with cost recovery amount greater than the given amount.
  --p-total-cost-recovery: string # Total Cost Recovery Amount Limiter. Enter a keyword value to limit results to cases with given cost recovery amounts. - ANY = Cases with any cost recovery amount greater than zero. - LEXX = Replacing XX with a dollar value, return cases with cost recovery amount less than or equal to the given amount. - GTXX = Replacing XX with a dollar value, return cases with cost recovery amount greater than the given amount.
  --p-complying-actions: string # Complying Actions Type Code Limiter. Enter one or more complying action codes to restrict results. Provide multiple values as a comma-delimited list.
  --p-comp-act-val: string@p-comp-act-val-completer # Compliance Action Cost Limiter. Enter a keyword value to limit results to cases with given compliance cost amounts. - ANY = Cases with any compliance cost amount greater than zero. - LEXX = Replacing XX with a dollar value, return cases with compliance cost amount less than or equal to the given amount. - GTXX = Replacing XX with a dollar value, return cases with compliance cost amount greater than the given amount.
  --p-total-comp-act-val: string # Total Compliance Action Amount Limiter. Enter a keyword value to limit results to cases with given total compliance action amounts. - ANY = Cases with any total compliance action amount greater than zero. - LEXX = Replacing XX with a dollar value, return cases with total compliance action amount less than or equal to the given amount. - GTXX = Replacing XX with a dollar value, return cases with total compliance action amount greater than the given amount.
  --p-sep-cats: string # Supplemental Environmental Projects Activity Category Code Limiter. Provide one or more SEP activity category codes to limit results. Provide multiple values as a comma-delimited list.
  --p-sep-val: string@p-sep-val-completer # Supplemental Environmental Projects Activity Value Limiter. Provide a keyword to limit results. - ANY = return cases with any SEP activity amount. - LE10000 = return cases with SEP activity amount less than or equal to $10,000. - GT10000 = return cases with SEP activity amount greater than $10,000. - GT50000 = return cases with SEP activity amount greater than $50,000. - GT100000 = return cases with SEP activity amount greater than $100,000. - GT500000 = return cases with SEP activity amount greater than $500,000. - GT1000000 = return cases with SEP activity amount greater than $1,000,000.
  --p-total-sep-val: string # Supplemental Environmental Projects Total Value Limiter. Provide a keyword to limit results. - ANY = return cases with any SEP total amount. - LE10000 = return cases with SEP total amount less than or equal to $10,000. - GT10000 = return cases with SEP total amount greater than $10,000. - GT50000 = return cases with SEP total amount greater than $50,000. - GT100000 = return cases with SEP total amount greater than $100,000. - GT500000 = return cases with SEP total amount greater than $500,000. - GT1000000 = return cases with SEP total amount greater than $1,000,000.
  --p-lodged-date: string # Settlement Lodged Date Limiter. Enter a single settlement lodged date in MM/DD/YYYY format to limit results.
  --p-entered-date: string # Settlement Entered Date Limiter. Enter a single settlement entered date in MM/DD/YYYY format to limit results.
  --p-facility-id: string # Case Facility Registration Identifier Limiter. Enter a single complete facility identifier to limit results.
  --p-fac-city: string # Case Facility City Limiter. Enter a single complete city name to filter cases by facility location city.
  --p-fac-zip: string # Case Facility ZIP Code Limiter. Enter a single 5-digit zip code to filter cases by facility location zip code.
  --p-fac-county: string # Case Facility County Limiter. Enter a single complete county name to filter cases by facility location county name.
  --p-case-summary: string # Case Summary Search Limiter. Enter a single case summary to limit results. This parameter accepts partial codes and allows for advanced search modifiers.
  --p-case-summary-type: string@p-case-summary-type-completer # Identifies how the the search terms enterened in p_case_summary are searched. Valid values are ALL (Default), WITHIN, and CONTAINS. Must be used with p_case_summary.
  --p-usmex: string@p-usmex-completer # US-Mexico Border Flag. Enter Y/N to restrict searches to facilities located within 100KM of the border.
  --p-c1lat: float # In decimal degrees. Latitude of 1st corner of box that bounds the resulting facilities. The latitude and longitude of both corners of the bounding box must be provided.
  --p-c1lon: float # In decimal degrees. Longitude of 1st corner of box that bounds the resulting facilities. The latitude and longitude of both corners of the bounding box must be provided.
  --p-c2lat: float # In decimal degrees. Latitude of 2nd corner of box that bounds the resulting facilities. The latitude and longitude of both corners of the bounding box must be provided.
  --p-c2lon: float # In decimal degrees. Longitude of 2nd corner of box that bounds the resulting facilities. The latitude and longitude of both corners of the bounding box must be provided.
  --p-voluntary: string # Voluntary Self Disclosure Flag. Enter Y or N to include or exclude cases results having voluntary disclosure.
  --p-fed-indicator: string # Federal Facility/Cross Media Flag. Enter Y or N to limit results to cases with federal facility cross media.
  --p-fntype: string@p-fntype-completer # Controls type of text search performed on facility name with parameter p_fn. - EXACT = Find facilities having the exact provided name(s). - BEGINS = Find facilities with names starting with the provided term(s). - ALL = Find facilities using Oracle text search terms. - CONTAINS =
  --p-civil-criminal-indicator: string@p-civil-criminal-indicator-completer # Civil/Criminal Case Limiter. Provide a keyword to limit results. - ANY = return both civil and criminal cases. - CI = return only civil cases. - CR = return only criminal cases.
  --queryset: float # Query Limiter. Enter a value to limit the number of records returned for each query. Value cannot exceed 70,000.
  --responseset: float # Response Set Limiter. Enter a value to limit the number of records per page. Value cannot exceed 1,000.
  --maplist: string@maplist-completer # Map List Flag. Provide a Y to return mappable coordinates representing the full geographic extent of the queryset (all facilities that met the selection criteria).
  --tablelist: string@tablelist-completer # Table List Flag. Enter a Y to display the first page of facility results.
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
  --qcolumns: string # Used to customize service output. A list of comma-separated column IDs of output objects that will be returned in the service query object or download. Use the metadata service endpoint for a complete list of Ids and definitions.
  --p-ocmap-fy: string # Fiscal Year to select cases that are displayed in the Office of Complicance Fiscal Year Map Services
  --p-qs: string # Quick Search. Allows entry for city, state, and/or zip code.
  --p-has-map: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/case_rest_services.get_cases"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: p_case_category, var: p_case_category}, {name: p_case_status, var: p_case_status}, {name: p_milestone, var: p_milestone}, {name: p_from_date, var: p_from_date}, {name: p_to_date, var: p_to_date}, {name: p_milestone_fy, var: p_milestone_fy}, {name: p_name, var: p_name}, {name: p_name_type, var: p_name_type}, {name: p_case_number, var: p_case_number}, {name: p_docket_number, var: p_docket_number}, {name: p_court_docket_number, var: p_court_docket_number}, {name: p_activity_number, var: p_activity_number}, {name: p_case_lead, var: p_case_lead}, {name: p_case_sens_flg, var: p_case_sens_flg}, {name: p_region, var: p_region}, {name: p_state, var: p_state}, {name: p_district, var: p_district}, {name: p_sic, var: p_sic}, {name: p_sic_ao_naics, var: p_sic_ao_naics}, {name: p_sic_primary_flg, var: p_sic_primary_flg}, {name: p_sic_frs_flg, var: p_sic_frs_flg}, {name: p_naics, var: p_naics}, {name: p_naics_primary_flg, var: p_naics_primary_flg}, {name: p_naics_frs_flg, var: p_naics_frs_flg}, {name: p_enf_type, var: p_enf_type}, {name: p_law, var: p_law}, {name: p_section, var: p_section}, {name: p_cp_citation, var: p_cp_citation}, {name: p_rank_order, var: p_rank_order}, {name: p_enf_program, var: p_enf_program}, {name: p_violation, var: p_violation}, {name: p_priority_area, var: p_priority_area}, {name: p_priority_area_desc, var: p_priority_area_desc}, {name: p_tribal, var: p_tribal}, {name: p_oeca_core, var: p_oeca_core}, {name: p_multimedia, var: p_multimedia}, {name: p_fed_case, var: p_fed_case}, {name: p_activity_contact, var: p_activity_contact}, {name: p_role, var: p_role}, {name: p_fed_penalty, var: p_fed_penalty}, {name: p_total_fed_penalty, var: p_total_fed_penalty}, {name: p_cost_recovery, var: p_cost_recovery}, {name: p_total_cost_recovery, var: p_total_cost_recovery}, {name: p_complying_actions, var: p_complying_actions}, {name: p_comp_act_val, var: p_comp_act_val}, {name: p_total_comp_act_val, var: p_total_comp_act_val}, {name: p_sep_cats, var: p_sep_cats}, {name: p_sep_val, var: p_sep_val}, {name: p_total_sep_val, var: p_total_sep_val}, {name: p_lodged_date, var: p_lodged_date}, {name: p_entered_date, var: p_entered_date}, {name: p_facility_id, var: p_facility_id}, {name: p_fac_city, var: p_fac_city}, {name: p_fac_zip, var: p_fac_zip}, {name: p_fac_county, var: p_fac_county}, {name: p_case_summary, var: p_case_summary}, {name: p_case_summary_type, var: p_case_summary_type}, {name: p_usmex, var: p_usmex}, {name: p_c1lat, var: p_c1lat}, {name: p_c1lon, var: p_c1lon}, {name: p_c2lat, var: p_c2lat}, {name: p_c2lon, var: p_c2lon}, {name: p_voluntary, var: p_voluntary}, {name: p_fed_indicator, var: p_fed_indicator}, {name: p_fntype, var: p_fntype}, {name: p_civil_criminal_indicator, var: p_civil_criminal_indicator}, {name: queryset, var: queryset}, {name: responseset, var: responseset}, {name: maplist, var: maplist}, {name: tablelist, var: tablelist}, {name: callback, var: callback}, {name: qcolumns, var: qcolumns}, {name: p_ocmap_fy, var: p_ocmap_fy}, {name: p_qs, var: p_qs}, {name: p_has_map, var: p_has_map}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_case_category: $p_case_category, p_case_status: $p_case_status, p_milestone: $p_milestone, p_from_date: $p_from_date, p_to_date: $p_to_date, p_milestone_fy: $p_milestone_fy, p_name: $p_name, p_name_type: $p_name_type, p_case_number: $p_case_number, p_docket_number: $p_docket_number, p_court_docket_number: $p_court_docket_number, p_activity_number: $p_activity_number, p_case_lead: $p_case_lead, p_case_sens_flg: $p_case_sens_flg, p_region: $p_region, p_state: $p_state, p_district: $p_district, p_sic: $p_sic, p_sic_ao_naics: $p_sic_ao_naics, p_sic_primary_flg: $p_sic_primary_flg, p_sic_frs_flg: $p_sic_frs_flg, p_naics: $p_naics, p_naics_primary_flg: $p_naics_primary_flg, p_naics_frs_flg: $p_naics_frs_flg, p_enf_type: $p_enf_type, p_law: $p_law, p_section: $p_section, p_cp_citation: $p_cp_citation, p_rank_order: $p_rank_order, p_enf_program: $p_enf_program, p_violation: $p_violation, p_priority_area: $p_priority_area, p_priority_area_desc: $p_priority_area_desc, p_tribal: $p_tribal, p_oeca_core: $p_oeca_core, p_multimedia: $p_multimedia, p_fed_case: $p_fed_case, p_activity_contact: $p_activity_contact, p_role: $p_role, p_fed_penalty: $p_fed_penalty, p_total_fed_penalty: $p_total_fed_penalty, p_cost_recovery: $p_cost_recovery, p_total_cost_recovery: $p_total_cost_recovery, p_complying_actions: $p_complying_actions, p_comp_act_val: $p_comp_act_val, p_total_comp_act_val: $p_total_comp_act_val, p_sep_cats: $p_sep_cats, p_sep_val: $p_sep_val, p_total_sep_val: $p_total_sep_val, p_lodged_date: $p_lodged_date, p_entered_date: $p_entered_date, p_facility_id: $p_facility_id, p_fac_city: $p_fac_city, p_fac_zip: $p_fac_zip, p_fac_county: $p_fac_county, p_case_summary: $p_case_summary, p_case_summary_type: $p_case_summary_type, p_usmex: $p_usmex, p_c1lat: $p_c1lat, p_c1lon: $p_c1lon, p_c2lat: $p_c2lat, p_c2lon: $p_c2lon, p_voluntary: $p_voluntary, p_fed_indicator: $p_fed_indicator, p_fntype: $p_fntype, p_civil_criminal_indicator: $p_civil_criminal_indicator, queryset: $queryset, responseset: $responseset, maplist: $maplist, tablelist: $tablelist, callback: $callback, qcolumns: $qcolumns, p_ocmap_fy: $p_ocmap_fy, p_qs: $p_qs, p_has_map: $p_has_map
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Placeholder
#
# GET /case_rest_services.get_cases_from_facility
# Returns: record<Results: record<Results: record<CaseNumbers: list>>>
export def "get-case-rest-services-get-cases-from-facility" [
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
  --p-id: string # Identifier for the service. (required)
  --output: string@output-completer # Output Format Flag. Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding. - XML = Data model formatted as Extensible Markup Language.
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/case_rest_services.get_cases_from_facility"
    query: [{name: p_id, var: p_id, required: true}, {name: output, var: output}, {name: callback, var: callback}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    p_id: $p_id, output: $output, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Placeholder
#
# POST /case_rest_services.get_cases_from_facility
# Returns: record<Results: record<Results: record<CaseNumbers: list>>>
export def "post-case-rest-services-get-cases-from-facility" [
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
  --p-id: string # Identifier for the service. (required)
  --output: string@output-completer # Output Format Flag. Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding. - XML = Data model formatted as Extensible Markup Language.
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/case_rest_services.get_cases_from_facility"
    query: [{name: p_id, var: p_id, required: true}, {name: output, var: output}, {name: callback, var: callback}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    p_id: $p_id, output: $output, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Enforcement Criminal Case Summary Report Search
#
# GET /case_rest_services.get_crcase_report
# Returns: record<Results: record<CRCaseInformation: record<CaseIdentifier: string, CaseSummary: string, Citations: string, FiscalYear: string, Statutes: string>, CRDefendants: list<record>, CRDetails: list<record>, Locations: list<record>, Message: string>>
export def "get-case-rest-services-get-crcase-report" [
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
  --p-id: string # Prosecution Summary Identifier. Enter the numeric prosecution summary identifier to retrieve the criminal case report.
  --output: string@output-completer # Output Format Flag. Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding. - XML = Data model formatted as Extensible Markup Language.
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
  --mapset: string # Identifies the maxium number of case facilities to return from the case_rest_services.get_case_info query. (default: 1400)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/case_rest_services.get_crcase_report"
    query: [{name: p_id, var: p_id}, {name: output, var: output}, {name: callback, var: callback}, {name: mapset, var: mapset}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    p_id: $p_id, output: $output, callback: $callback, mapset: $mapset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Enforcement Criminal Case Summary Report Search
#
# POST /case_rest_services.get_crcase_report
# Returns: record<Results: record<CRCaseInformation: record<CaseIdentifier: string, CaseSummary: string, Citations: string, FiscalYear: string, Statutes: string>, CRDefendants: list<record>, CRDetails: list<record>, Locations: list<record>, Message: string>>
export def "post-case-rest-services-get-crcase-report" [
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
  --p-id: string # Prosecution Summary Identifier. Enter the numeric prosecution summary identifier to retrieve the criminal case report.
  --output: string@output-completer # Output Format Flag. Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding. - XML = Data model formatted as Extensible Markup Language.
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/case_rest_services.get_crcase_report"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: p_id, var: p_id}, {name: output, var: output}, {name: callback, var: callback}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    p_id: $p_id, output: $output, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Enforcement Case Download Data Service
#
# GET /case_rest_services.get_download
# Returns: binary
export def "get-case-rest-services-get-download" [
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
  --output: string # Output Format Flag. Enter one of the following keywords: - CSV = Facility results formatted as comma delimited file download (default).
  --qid: string # Query ID Selector. Enter the QueryID number from a previously run query. (required)
  --qcolumns: string # Used to customize service output. A list of comma-separated column IDs of output objects that will be returned in the service query object or download. Use the metadata service endpoint for a complete list of Ids and definitions.
]: nothing -> any {
  http-request {
    method: get
    path: "/case_rest_services.get_download"
    query: [{name: output, var: output}, {name: qid, var: qid, required: true}, {name: qcolumns, var: qcolumns}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, qid: $qid, qcolumns: $qcolumns
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Enforcement Case Download Data Service
#
# POST /case_rest_services.get_download
# Returns: binary
export def "post-case-rest-services-get-download" [
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
  --output: string # Output Format Flag. Enter one of the following keywords: - CSV = Facility results formatted as comma delimited file download (default).
  qid: string # Query ID Selector. Enter the QueryID number from a previously run query.
  --qcolumns: string # Used to customize service output. A list of comma-separated column IDs of output objects that will be returned in the service query object or download. Use the metadata service endpoint for a complete list of Ids and definitions.
]: any -> any {
  $in | http-request {
    method: post
    path: "/case_rest_services.get_download"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: qid, var: qid}, {name: qcolumns, var: qcolumns}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, qid: $qid, qcolumns: $qcolumns
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Placeholder
#
# GET /case_rest_services.get_facilities_from_case
# Returns: record<Results: record<Results: record<RegistryIDs: list>>>
export def "get-case-rest-services-get-facilities-from-case" [
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
  --p-id: string # Identifier for the service. (required)
  --output: string@output-completer # Output Format Flag. Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding. - XML = Data model formatted as Extensible Markup Language.
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/case_rest_services.get_facilities_from_case"
    query: [{name: p_id, var: p_id, required: true}, {name: output, var: output}, {name: callback, var: callback}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    p_id: $p_id, output: $output, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Placeholder
#
# POST /case_rest_services.get_facilities_from_case
# Returns: record<Results: record<Results: record<RegistryIDs: list>>>
export def "post-case-rest-services-get-facilities-from-case" [
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
  --p-id: string # Identifier for the service. (required)
  --output: string@output-completer # Output Format Flag. Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding. - XML = Data model formatted as Extensible Markup Language.
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/case_rest_services.get_facilities_from_case"
    query: [{name: p_id, var: p_id, required: true}, {name: output, var: output}, {name: callback, var: callback}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    p_id: $p_id, output: $output, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Enforcement Case Map Service
#
# GET /case_rest_services.get_map
# Returns: record<MapOutput: record<IconBaseURL: string, MapData: list<record>, PopUpBaseURL: string, QueryID: string>>
export def "get-case-rest-services-get-map" [
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
  --output: string@output-completer # Output Format Flag. Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding. - XML = Data model formatted as Extensible Markup Language.
  --qid: string # Query ID Selector. Enter the QueryID number from a previously run query. (required)
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
  --tablelist: string@tablelist-completer # Table List Flag. Enter a Y to display the first page of facility results.
  --c1-lat: float # Latitude of 1st corner of box that bounds the resulting facilities. The latitude and longitude of both corners of the bounding box must be provided.
  --c1-long: float # Longitude of 1st corner of box that bounds the resulting facilities. The latitude and longitude of both corners of the bounding box must be provided.
  --c2-lat: float # Latitude of 2nd corner of box that bounds the resulting facilities. The latitude and longitude of both corners of the bounding box must be provided.
  --c2-long: float # Longitude of 2nd corner of box that bounds the resulting facilities. The latitude and longitude of both corners of the bounding box must be provided.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/case_rest_services.get_map"
    query: [{name: output, var: output}, {name: qid, var: qid, required: true}, {name: callback, var: callback}, {name: tablelist, var: tablelist}, {name: c1_lat, var: c1_lat}, {name: c1_long, var: c1_long}, {name: c2_lat, var: c2_lat}, {name: c2_long, var: c2_long}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, qid: $qid, callback: $callback, tablelist: $tablelist, c1_lat: $c1_lat, c1_long: $c1_long, c2_lat: $c2_lat, c2_long: $c2_long
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Enforcement Case Map Service
#
# POST /case_rest_services.get_map
# Returns: record<MapOutput: record<IconBaseURL: string, MapData: list<record>, PopUpBaseURL: string, QueryID: string>>
export def "post-case-rest-services-get-map" [
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
  --output: string@output-completer # Output Format Flag. Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding. - XML = Data model formatted as Extensible Markup Language.
  qid: string # Query ID Selector. Enter the QueryID number from a previously run query.
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
  --tablelist: string@tablelist-completer # Table List Flag. Enter a Y to display the first page of facility results.
  --c1-lat: float # Latitude of 1st corner of box that bounds the resulting facilities. The latitude and longitude of both corners of the bounding box must be provided.
  --c1-long: float # Longitude of 1st corner of box that bounds the resulting facilities. The latitude and longitude of both corners of the bounding box must be provided.
  --c2-lat: float # Latitude of 2nd corner of box that bounds the resulting facilities. The latitude and longitude of both corners of the bounding box must be provided.
  --c2-long: float # Longitude of 2nd corner of box that bounds the resulting facilities. The latitude and longitude of both corners of the bounding box must be provided.
  --mapset: string # Identifies the maxium number of case facilities to return from the case_rest_services.get_case_info query.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/case_rest_services.get_map"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: qid, var: qid}, {name: callback, var: callback}, {name: tablelist, var: tablelist}, {name: c1_lat, var: c1_lat}, {name: c1_long, var: c1_long}, {name: c2_lat, var: c2_lat}, {name: c2_long, var: c2_long}, {name: mapset, var: mapset}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, qid: $qid, callback: $callback, tablelist: $tablelist, c1_lat: $c1_lat, c1_long: $c1_long, c2_lat: $c2_lat, c2_long: $c2_long, mapset: $mapset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Enforcement Case Paginated Results Service
#
# GET /case_rest_services.get_qid
# Returns: record<Results: record<Cases: list<record>, Message: string, PageNo: string, QueryID: string, QueryRows: string>>
export def "get-case-rest-services-get-qid" [
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
  --output: string@output-completer # Output Format Flag. Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding. - XML = Data model formatted as Extensible Markup Language.
  --qid: string # Query ID Selector. Enter the QueryID number from a previously run query. (required)
  --pageno: float # Indicates the number of the page to display. It is used only when the results are paginated. (default: 1)
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
  --newsort: float # Output Sort Column. Enter the number of the column on which the data will be sorted. If unpopulated results will sort on the first column.
  --descending: string@descending-completer # Output Sort Column Descending Flag. Enter Y to column identified in the newsort parameter descending. Enter N to use ascending sort order. Used only when newsort parameter is populated.
  --qcolumns: string # Used to customize service output. A list of comma-separated column IDs of output objects that will be returned in the service query object or download. Use the metadata service endpoint for a complete list of Ids and definitions.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/case_rest_services.get_qid"
    query: [{name: output, var: output}, {name: qid, var: qid, required: true}, {name: pageno, var: pageno}, {name: callback, var: callback}, {name: newsort, var: newsort}, {name: descending, var: descending}, {name: qcolumns, var: qcolumns}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, qid: $qid, pageno: $pageno, callback: $callback, newsort: $newsort, descending: $descending, qcolumns: $qcolumns
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Enforcement Case Paginated Results Service
#
# POST /case_rest_services.get_qid
# Returns: record<Results: record<Cases: list<record>, Message: string, PageNo: string, QueryID: string, QueryRows: string>>
export def "post-case-rest-services-get-qid" [
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
  --output: string@output-completer # Output Format Flag. Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding. - XML = Data model formatted as Extensible Markup Language.
  qid: string # Query ID Selector. Enter the QueryID number from a previously run query.
  --pageno: float # Indicates the number of the page to display. It is used only when the results are paginated.
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
  --newsort: float # Output Sort Column. Enter the number of the column on which the data will be sorted. If unpopulated results will sort on the first column.
  --descending: string@descending-completer # Output Sort Column Descending Flag. Enter Y to column identified in the newsort parameter descending. Enter N to use ascending sort order. Used only when newsort parameter is populated.
  --qcolumns: string # Used to customize service output. A list of comma-separated column IDs of output objects that will be returned in the service query object or download. Use the metadata service endpoint for a complete list of Ids and definitions.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/case_rest_services.get_qid"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: qid, var: qid}, {name: pageno, var: pageno}, {name: callback, var: callback}, {name: newsort, var: newsort}, {name: descending, var: descending}, {name: qcolumns, var: qcolumns}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, qid: $qid, pageno: $pageno, callback: $callback, newsort: $newsort, descending: $descending, qcolumns: $qcolumns
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Enforcement Case Metadata Service
#
# GET /case_rest_services.metadata
# Returns: record<Results: record<Message: string, ResultColumns: list<record>>>
export def "get-case-rest-services-metadata" [
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
  --output: string@output-completer # Output Format Flag. Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding. - XML = Data model formatted as Extensible Markup Language.
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/case_rest_services.metadata"
    query: [{name: output, var: output}, {name: callback, var: callback}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Enforcement Case Metadata Service
#
# POST /case_rest_services.metadata
# Returns: record<Results: record<Message: string, ResultColumns: list<record>>>
export def "post-case-rest-services-metadata" [
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
  --output: string@output-completer # Output Format Flag. Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding. - XML = Data model formatted as Extensible Markup Language.
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/case_rest_services.metadata"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: callback, var: callback}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# ECHO ICIS Law Sections Lookup Service
#
# GET /rest_lookups.icis_law_sections
# Returns: record<Results: record<LuValues: list<record>, Message: string>>
export def "get-rest-lookups-icis-law-sections" [
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
  --output: string@output-completer # Output Format Flag. Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding. - XML = Data model formatted as Extensible Markup Language.
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
  --statute-code: string
  --status-flag: string
  --search-term: string # Enter a partial or complete search phrase or word.
  --search-code: string # Enter a partial or complete code value.
  --sort-order: float
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rest_lookups.icis_law_sections"
    query: [{name: output, var: output}, {name: callback, var: callback}, {name: statute_code, var: statute_code}, {name: status_flag, var: status_flag}, {name: search_term, var: search_term}, {name: search_code, var: search_code}, {name: sort_order, var: sort_order}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, callback: $callback, statute_code: $statute_code, status_flag: $status_flag, search_term: $search_term, search_code: $search_code, sort_order: $sort_order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# ECHO ICIS Law Sections Lookup Service
#
# POST /rest_lookups.icis_law_sections
# Returns: record<Results: record<LuValues: list<record>, Message: string>>
export def "post-rest-lookups-icis-law-sections" [
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
  --output: string@output-completer # Output Format Flag. Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding. - XML = Data model formatted as Extensible Markup Language.
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
  --statute-code: string
  --status-flag: string
  --search-term: string # Enter a partial or complete search phrase or word.
  --search-code: string # Enter a partial or complete code value.
  --sort-order: float
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/rest_lookups.icis_law_sections"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: callback, var: callback}, {name: statute_code, var: statute_code}, {name: status_flag, var: status_flag}, {name: search_term, var: search_term}, {name: search_code, var: search_code}, {name: sort_order, var: sort_order}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, callback: $callback, statute_code: $statute_code, status_flag: $status_flag, search_term: $search_term, search_code: $search_code, sort_order: $sort_order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}
