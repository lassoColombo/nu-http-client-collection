# Auto-generated client for U.S. EPA Enforcement and Compliance History Online (ECHO) - Detailed Facility Report (DFR) v0.0.0
# Source: https://api.apis.guru/v2/specs/epa.gov/dfr/0.0.0/swagger.json
# Auth: --token flag or $env.U_S_EPA_ENFORCEMENT_AND_COMPLIANCE_HISTORY_ONLINE_ECHO_DETAILED_FACILITY_REPORT_DFR_TOKEN

const CLIENT = {
  base_url: "https://echodata.epa.gov/echo"
  token_env_var: "U_S_EPA_ENFORCEMENT_AND_COMPLIANCE_HISTORY_ONLINE_ECHO_DETAILED_FACILITY_REPORT_DFR_TOKEN"
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
def accept-completer [] { ["application/json" "application/xml"] }
def output-completer [] { ["JSON" "JSONP" "XML"] }
def p-missinglate-completer [] { ["LATE" "MISSING"] }
def p-qmtype-completer [] { ["MONTH" "QUARTER"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-dfr-rest-services-air-3-yr-download: "binary"
    post-dfr-rest-services-air-3-yr-download: "binary"
    get-dfr-rest-services-cwa-3-yr-effluent-download: "binary"
    post-dfr-rest-services-cwa-3-yr-effluent-download: "binary"
    get-dfr-rest-services-cwa-3-yr-sepscs-download: "binary"
    post-dfr-rest-services-cwa-3-yr-sepscs-download: "binary"
    get-dfr-rest-services-get-air-compliance: "record<Results: record<AirCompliance: record<Header: record, Sources: list>, Message: string>>"
    post-dfr-rest-services-get-air-compliance: "record<Results: record<AirCompliance: record<Header: record, Sources: list>, Message: string>>"
    get-dfr-rest-services-get-air-quality: "record<Results: record<AirQuality: record<CarbonMonoxide1971Area: string, Lead1978Area: string, Lead2008Area: string, NitrogenDioxide1971Area: string, Ozone8hr1997Area: string, Ozone8hr2008Area: string, Ozone8hr2015Area: string, ParticulateMatter1987Area: string, ParticulateMatter1997Area: string, ParticulateMatter2006Area: string, ParticulateMatter2012Area: string, SulfurDioxide1971Area: string, SulfurDioxide2010Area: string>, Message: string>>"
    post-dfr-rest-services-get-air-quality: "record<Results: record<AirQuality: record<CarbonMonoxide1971Area: string, Lead1978Area: string, Lead2008Area: string, NitrogenDioxide1971Area: string, Ozone8hr1997Area: string, Ozone8hr2008Area: string, Ozone8hr2015Area: string, ParticulateMatter1987Area: string, ParticulateMatter1997Area: string, ParticulateMatter2006Area: string, ParticulateMatter2012Area: string, SulfurDioxide1971Area: string, SulfurDioxide2010Area: string>, Message: string>>"
    get-dfr-rest-services-get-aws-docs: "record<Results: record<Message: string>>"
    post-dfr-rest-services-get-aws-docs: "record<Results: record<Message: string>>"
    get-dfr-rest-services-get-case-formal-actions: "record<Results: record<CaseFormalActions: record<Action: list, ProgramDates: list>, Message: string>>"
    post-dfr-rest-services-get-case-formal-actions: "record<Results: record<CaseFormalActions: record<Action: list, ProgramDates: list>, Message: string>>"
    get-dfr-rest-services-get-compliance-history: "record<Results: record<ComplianceHistory: record<Inspection: list, ProgramDates: list>, Message: string>>"
    post-dfr-rest-services-get-compliance-history: "record<Results: record<ComplianceHistory: record<Inspection: list, ProgramDates: list>, Message: string>>"
    get-dfr-rest-services-get-compliance-summary: "record<Results: record<ComplianceSummary: record<ProgramDates: list, Source: list>, Message: string>>"
    post-dfr-rest-services-get-compliance-summary: "record<Results: record<ComplianceSummary: record<ProgramDates: list, Source: list>, Message: string>>"
    get-dfr-rest-services-get-csv: "binary"
    post-dfr-rest-services-get-csv: "binary"
    get-dfr-rest-services-get-cwa-3yr-compliance: "record<Results: record<CWA3YrCompliance: record<Header: record, Sources: list>, Message: string>>"
    post-dfr-rest-services-get-cwa-3yr-compliance: "record<Results: record<CWA3YrCompliance: record<Header: record, Sources: list>, Message: string>>"
    get-dfr-rest-services-get-cwa-3yr-d80d90-counts: "record<Results: record<CWA3YrD80D90Counts: record<Header: record, Sources: list>, Message: string>>"
    post-dfr-rest-services-get-cwa-3yr-d80d90-counts: "record<Results: record<CWA3YrD80D90Counts: record<Header: record, Sources: list>, Message: string>>"
    get-dfr-rest-services-get-cwa-cs-compliance: "record<Results: record<CWACSCompliance: record<Header: record, Sources: list>, Message: string>>"
    post-dfr-rest-services-get-cwa-cs-compliance: "record<Results: record<CWACSCompliance: record<Header: record, Sources: list>, Message: string>>"
    get-dfr-rest-services-get-cwa-eff-alr: "record<Results: record<CWAEffluentALRExceedences: record<Header: record, Sources: list>, Message: string>>"
    post-dfr-rest-services-get-cwa-eff-alr: "record<Results: record<CWAEffluentALRExceedences: record<Header: record, Sources: list>, Message: string>>"
    get-dfr-rest-services-get-cwa-eff-alr-exp: "record<Results: record<CWAEffluentALRExceedencesEXP: record<Header: record, Sources: list>, Message: string>>"
    post-dfr-rest-services-get-cwa-eff-alr-exp: "record<Results: record<CWAEffluentALRExceedencesEXP: record<Header: record, Sources: list>, Message: string>>"
    get-dfr-rest-services-get-cwa-eff-compliance: "record<Results: record<CWAEffluentCompliance: record<Header: record, Sources: list>, Message: string>>"
    post-dfr-rest-services-get-cwa-eff-compliance: "record<Results: record<CWAEffluentCompliance: record<Header: record, Sources: list>, Message: string>>"
    get-dfr-rest-services-get-cwa-eff-compliance-exp: "record<Results: record<CWAEffluentComplianceEXP: record<Header: record, Sources: list>, Message: string>>"
    post-dfr-rest-services-get-cwa-eff-compliance-exp: "record<Results: record<CWAEffluentComplianceEXP: record<Header: record, Sources: list>, Message: string>>"
    get-dfr-rest-services-get-cwa-ps-compliance: "record<Results: record<CWAPSCompliance: record<Header: record, Sources: list>, Message: string>>"
    post-dfr-rest-services-get-cwa-ps-compliance: "record<Results: record<CWAPSCompliance: record<Header: record, Sources: list>, Message: string>>"
    get-dfr-rest-services-get-cwa-rnc-compliance: "record<Results: record<CWARNCCompliance: record<Header: record, Sources: list>, Message: string>>"
    post-dfr-rest-services-get-cwa-rnc-compliance: "record<Results: record<CWARNCCompliance: record<Header: record, Sources: list>, Message: string>>"
    get-dfr-rest-services-get-cwa-se-compliance: "record<Results: record<CWASECompliance: record<Header: record, Sources: list>, Message: string>>"
    post-dfr-rest-services-get-cwa-se-compliance: "record<Results: record<CWASECompliance: record<Header: record, Sources: list>, Message: string>>"
    get-dfr-rest-services-get-d80d90s-details: "record<Results: record<D80D90sDetails: record<Sources: list>, Message: string>>"
    post-dfr-rest-services-get-d80d90s-details: "record<Results: record<D80D90sDetails: record<Sources: list>, Message: string>>"
    get-dfr-rest-services-get-demographics-by-id: "record<Results: record<Demographics: record<Adults: string, AfricanAmerican: string, AmericanIndian: string, AsianPacificIslander: string, BSBA: string, CenterLatitude: string, CenterLongitude: string, Child: string, Grades9to12: string, HSDiploma: string, HispanicOrigin: string, Households: string, HouseholdsPublicAssistance: string, HousingUnits: string, Income15to25k: string, Income25to50k: string, Income50to75k: string, Income75kPlus: string, IncomeLess15k: string, LandArea: string, Less9thGrade: string, Minors: string, OtherMultiracial: string, PercentMinority: string, PersonsBelowPovertyLevel: string, PopulationDensity: string, Radius: string, Seniors: string, SomeCollege: string, TotalPersons: string, WaterArea: string, White: string>, Message: string>>"
    post-dfr-rest-services-get-demographics-by-id: "record<Results: record<Demographics: record<Adults: string, AfricanAmerican: string, AmericanIndian: string, AsianPacificIslander: string, BSBA: string, CenterLatitude: string, CenterLongitude: string, Child: string, Grades9to12: string, HSDiploma: string, HispanicOrigin: string, Households: string, HouseholdsPublicAssistance: string, HousingUnits: string, Income15to25k: string, Income25to50k: string, Income50to75k: string, Income75kPlus: string, IncomeLess15k: string, LandArea: string, Less9thGrade: string, Minors: string, OtherMultiracial: string, PercentMinority: string, PersonsBelowPovertyLevel: string, PopulationDensity: string, Radius: string, Seniors: string, SomeCollege: string, TotalPersons: string, WaterArea: string, White: string>, Message: string>>"
    get-dfr-rest-services-get-dfr: "record<Results: record<AirCompliance: record<Header: record, Sources: list>, AirQuality: record<CarbonMonoxide1971Area: string, Lead1978Area: string, Lead2008Area: string, NitrogenDioxide1971Area: string, Ozone8hr1997Area: string, Ozone8hr2008Area: string, Ozone8hr2015Area: string, ParticulateMatter1987Area: string, ParticulateMatter1997Area: string, ParticulateMatter2006Area: string, ParticulateMatter2012Area: string, SulfurDioxide1971Area: string, SulfurDioxide2010Area: string>, CAEDDocuments: list<record>, CWA3YrCompliance: record<Header: record, Sources: list>, CWA3YrD80D90Counts: record<Header: record, Sources: list>, CWACSCompliance: record<Header: record, Sources: list>, CWAEffluentALRExceedences: record<Header: record, Sources: list>, CWAEffluentALRExceedencesEXP: record<Header: record, Sources: list>, CWAEffluentCompliance: record<Header: record, Sources: list>, CWAEffluentComplianceEXP: record<Header: record, Sources: list>, CWAPSCompliance: record<Header: record, Sources: list>, CWARNCCompliance: record<Header: record, Sources: list>, CWASECompliance: record<Header: record, Sources: list>, CaseFormalActions: record<Action: list, ProgramDates: list>, ComplianceHistory: record<Inspection: list, ProgramDates: list>, ComplianceSummary: record<ProgramDates: list, Source: list>, Demographics: record<Adults: string, AfricanAmerican: string, AmericanIndian: string, AsianPacificIslander: string, BSBA: string, CenterLatitude: string, CenterLongitude: string, Child: string, Grades9to12: string, HSDiploma: string, HispanicOrigin: string, Households: string, HouseholdsPublicAssistance: string, HousingUnits: string, Income15to25k: string, Income25to50k: string, Income50to75k: string, Income75kPlus: string, IncomeLess15k: string, LandArea: string, Less9thGrade: string, Minors: string, OtherMultiracial: string, PercentMinority: string, PersonsBelowPovertyLevel: string, PopulationDensity: string, Radius: string, Seniors: string, SomeCollege: string, TotalPersons: string, WaterArea: string, White: string>, EJScreenIndexes: record<HazardWasteProximity: string, LeadPaintIndicator: string, NATACancerRisk: string, NATADieselPM: string, NATARespiratoryHI: string, Over80Count: string, Ozone: string, PM25: string, RMPProximity: string, RegistryID: string, SuperfundProximity: string, TrafficProximity: string, WaterDischargeProximity: string>, EnforcementComplianceSummaries: record<ProgramDates: list, Summaries: list>, FormalActions: record<Action: list, ProgramDates: list>, ICISFormalActions: record<Action: list, ProgramDates: list>, InspectionEnforcementSummary: record<ProgramDates: list, Source: list>, LeadAndCopperRule5Yr: record<CopperSamples: list, CuALE: string, CuALEUnits: string, CuALEValue: string, CuSampleDates: string, CuViol: string, LeadAndCopperViol: string, LeadCopperRuleHealthBasedViol: string, LeadSamples: list, PbALE: string, PbALEUnits: string, PbALEValue: string, PbSampleDates: string, PbViol: string, RuleCode350Viol: string, SourceID: string, iCU90: string, iPB90: string>, MapOutput: record<CenterLatitude: string, CenterLongitude: string, IconBaseURL: string, MapData: list, PopUpBaseURL: string>, Message: string, MultipleFRSFacilities: record<RegistryIDs: list>, NAICS: record<Sources: list>, Notices: record<Notice: list, ProgramDates: list>, Permits: list<record>, RCRACompliance: record<Mnth10End: string, Mnth10Start: string, Mnth11End: string, Mnth11Start: string, Mnth12End: string, Mnth12Start: string, Mnth13End: string, Mnth13Start: string, Mnth14End: string, Mnth14Start: string, Mnth15End: string, Mnth15Start: string, Mnth16End: string, Mnth16Start: string, Mnth17End: string, Mnth17Start: string, Mnth18End: string, Mnth18Start: string, Mnth19End: string, Mnth19Start: string, Mnth1End: string, Mnth1Start: string, Mnth20End: string, Mnth20Start: string, Mnth21End: string, Mnth21Start: string, Mnth22End: string, Mnth22Start: string, Mnth23End: string, Mnth23Start: string, Mnth24End: string, Mnth24Start: string, Mnth25End: string, Mnth25Start: string, Mnth26End: string, Mnth26Start: string, Mnth27End: string, Mnth27Start: string, Mnth28End: string, Mnth28Start: string, Mnth29End: string, Mnth29Start: string, Mnth2End: string, Mnth2Start: string, Mnth30End: string, Mnth30Start: string, Mnth31End: string, Mnth31Start: string, Mnth32End: string, Mnth32Start: string, Mnth33End: string, Mnth33Start: string, Mnth34End: string, Mnth34Start: string, Mnth35End: string, Mnth35Start: string, Mnth36End: string, Mnth36Start: string, Mnth3End: string, Mnth3Start: string, Mnth4End: string, Mnth4Start: string, Mnth5End: string, Mnth5Start: string, Mnth6End: string, Mnth6Start: string, Mnth7End: string, Mnth7Start: string, Mnth8End: string, Mnth8Start: string, Mnth9End: string, Mnth9Start: string, Qtr10End: string, Qtr10Start: string, Qtr11End: string, Qtr11Start: string, Qtr12End: string, Qtr12Start: string, Qtr1End: string, Qtr1Start: string, Qtr2End: string, Qtr2Start: string, Qtr3End: string, Qtr3Start: string, Qtr4End: string, Qtr4Start: string, Qtr5End: string, Qtr5Start: string, Qtr6End: string, Qtr6Start: string, Qtr7End: string, Qtr7Start: string, Qtr8End: string, Qtr8Start: string, Qtr9End: string, Qtr9Start: string, Sources: list>, Reports: record<HasPollRpt: string>, SDWISCompliance: record<Mnth10End: string, Mnth10Start: string, Mnth11End: string, Mnth11Start: string, Mnth12End: string, Mnth12Start: string, Mnth13End: string, Mnth13Start: string, Mnth14End: string, Mnth14Start: string, Mnth15End: string, Mnth15Start: string, Mnth16End: string, Mnth16Start: string, Mnth17End: string, Mnth17Start: string, Mnth18End: string, Mnth18Start: string, Mnth19End: string, Mnth19Start: string, Mnth1End: string, Mnth1Start: string, Mnth20End: string, Mnth20Start: string, Mnth21End: string, Mnth21Start: string, Mnth22End: string, Mnth22Start: string, Mnth23End: string, Mnth23Start: string, Mnth24End: string, Mnth24Start: string, Mnth25End: string, Mnth25Start: string, Mnth26End: string, Mnth26Start: string, Mnth27End: string, Mnth27Start: string, Mnth28End: string, Mnth28Start: string, Mnth29End: string, Mnth29Start: string, Mnth2End: string, Mnth2Start: string, Mnth30End: string, Mnth30Start: string, Mnth31End: string, Mnth31Start: string, Mnth32End: string, Mnth32Start: string, Mnth33End: string, Mnth33Start: string, Mnth34End: string, Mnth34Start: string, Mnth35End: string, Mnth35Start: string, Mnth36End: string, Mnth36Start: string, Mnth37End: string, Mnth37Start: string, Mnth38End: string, Mnth38Start: string, Mnth39End: string, Mnth39Start: string, Mnth3End: string, Mnth3Start: string, Mnth4End: string, Mnth4Start: string, Mnth5End: string, Mnth5Start: string, Mnth6End: string, Mnth6Start: string, Mnth7End: string, Mnth7Start: string, Mnth8End: string, Mnth8Start: string, Mnth9End: string, Mnth9Start: string, Qtr10End: string, Qtr10Start: string, Qtr11End: string, Qtr11Start: string, Qtr12End: string, Qtr12Start: string, Qtr13End: string, Qtr13Start: string, Qtr1End: string, Qtr1Start: string, Qtr2End: string, Qtr2Start: string, Qtr3End: string, Qtr3Start: string, Qtr4End: string, Qtr4Start: string, Qtr5End: string, Qtr5Start: string, Qtr6End: string, Qtr6Start: string, Qtr7End: string, Qtr7Start: string, Qtr8End: string, Qtr8Start: string, Qtr9End: string, Qtr9Start: string, Sources: list>, SIC: record<Sources: list>, SanitarySurveys: record<Sources: list>, SiteVisits: record<Sources: list>, SpatialMetadata: record<CalculatedAccuracy: string, CollectionMethod: string, CoordinateSourceSystem: string, CoordinateSourceSystemId: string, Latitude83: string, Longitude83: string, ReferencePoint: string, RegistryID: string>, SystemExtractDates: record<Dates: list>, TRIHistory: record<Sources: list>, TRIReleases: record<Chemicals: list, Header: list>, Tribes: list<record>, ViolationsEnforcementActions: record<Sources: list>, WaterQuality: record<Sources: list>, WaterQualityDetails: record<Sources: list>, WebFireDocuments: list<record>>>"
    post-dfr-rest-services-get-dfr: "record<Results: record<AirCompliance: record<Header: record, Sources: list>, AirQuality: record<CarbonMonoxide1971Area: string, Lead1978Area: string, Lead2008Area: string, NitrogenDioxide1971Area: string, Ozone8hr1997Area: string, Ozone8hr2008Area: string, Ozone8hr2015Area: string, ParticulateMatter1987Area: string, ParticulateMatter1997Area: string, ParticulateMatter2006Area: string, ParticulateMatter2012Area: string, SulfurDioxide1971Area: string, SulfurDioxide2010Area: string>, CAEDDocuments: list<record>, CWA3YrCompliance: record<Header: record, Sources: list>, CWA3YrD80D90Counts: record<Header: record, Sources: list>, CWACSCompliance: record<Header: record, Sources: list>, CWAEffluentALRExceedences: record<Header: record, Sources: list>, CWAEffluentALRExceedencesEXP: record<Header: record, Sources: list>, CWAEffluentCompliance: record<Header: record, Sources: list>, CWAEffluentComplianceEXP: record<Header: record, Sources: list>, CWAPSCompliance: record<Header: record, Sources: list>, CWARNCCompliance: record<Header: record, Sources: list>, CWASECompliance: record<Header: record, Sources: list>, CaseFormalActions: record<Action: list, ProgramDates: list>, ComplianceHistory: record<Inspection: list, ProgramDates: list>, ComplianceSummary: record<ProgramDates: list, Source: list>, Demographics: record<Adults: string, AfricanAmerican: string, AmericanIndian: string, AsianPacificIslander: string, BSBA: string, CenterLatitude: string, CenterLongitude: string, Child: string, Grades9to12: string, HSDiploma: string, HispanicOrigin: string, Households: string, HouseholdsPublicAssistance: string, HousingUnits: string, Income15to25k: string, Income25to50k: string, Income50to75k: string, Income75kPlus: string, IncomeLess15k: string, LandArea: string, Less9thGrade: string, Minors: string, OtherMultiracial: string, PercentMinority: string, PersonsBelowPovertyLevel: string, PopulationDensity: string, Radius: string, Seniors: string, SomeCollege: string, TotalPersons: string, WaterArea: string, White: string>, EJScreenIndexes: record<HazardWasteProximity: string, LeadPaintIndicator: string, NATACancerRisk: string, NATADieselPM: string, NATARespiratoryHI: string, Over80Count: string, Ozone: string, PM25: string, RMPProximity: string, RegistryID: string, SuperfundProximity: string, TrafficProximity: string, WaterDischargeProximity: string>, EnforcementComplianceSummaries: record<ProgramDates: list, Summaries: list>, FormalActions: record<Action: list, ProgramDates: list>, ICISFormalActions: record<Action: list, ProgramDates: list>, InspectionEnforcementSummary: record<ProgramDates: list, Source: list>, LeadAndCopperRule5Yr: record<CopperSamples: list, CuALE: string, CuALEUnits: string, CuALEValue: string, CuSampleDates: string, CuViol: string, LeadAndCopperViol: string, LeadCopperRuleHealthBasedViol: string, LeadSamples: list, PbALE: string, PbALEUnits: string, PbALEValue: string, PbSampleDates: string, PbViol: string, RuleCode350Viol: string, SourceID: string, iCU90: string, iPB90: string>, MapOutput: record<CenterLatitude: string, CenterLongitude: string, IconBaseURL: string, MapData: list, PopUpBaseURL: string>, Message: string, MultipleFRSFacilities: record<RegistryIDs: list>, NAICS: record<Sources: list>, Notices: record<Notice: list, ProgramDates: list>, Permits: list<record>, RCRACompliance: record<Mnth10End: string, Mnth10Start: string, Mnth11End: string, Mnth11Start: string, Mnth12End: string, Mnth12Start: string, Mnth13End: string, Mnth13Start: string, Mnth14End: string, Mnth14Start: string, Mnth15End: string, Mnth15Start: string, Mnth16End: string, Mnth16Start: string, Mnth17End: string, Mnth17Start: string, Mnth18End: string, Mnth18Start: string, Mnth19End: string, Mnth19Start: string, Mnth1End: string, Mnth1Start: string, Mnth20End: string, Mnth20Start: string, Mnth21End: string, Mnth21Start: string, Mnth22End: string, Mnth22Start: string, Mnth23End: string, Mnth23Start: string, Mnth24End: string, Mnth24Start: string, Mnth25End: string, Mnth25Start: string, Mnth26End: string, Mnth26Start: string, Mnth27End: string, Mnth27Start: string, Mnth28End: string, Mnth28Start: string, Mnth29End: string, Mnth29Start: string, Mnth2End: string, Mnth2Start: string, Mnth30End: string, Mnth30Start: string, Mnth31End: string, Mnth31Start: string, Mnth32End: string, Mnth32Start: string, Mnth33End: string, Mnth33Start: string, Mnth34End: string, Mnth34Start: string, Mnth35End: string, Mnth35Start: string, Mnth36End: string, Mnth36Start: string, Mnth3End: string, Mnth3Start: string, Mnth4End: string, Mnth4Start: string, Mnth5End: string, Mnth5Start: string, Mnth6End: string, Mnth6Start: string, Mnth7End: string, Mnth7Start: string, Mnth8End: string, Mnth8Start: string, Mnth9End: string, Mnth9Start: string, Qtr10End: string, Qtr10Start: string, Qtr11End: string, Qtr11Start: string, Qtr12End: string, Qtr12Start: string, Qtr1End: string, Qtr1Start: string, Qtr2End: string, Qtr2Start: string, Qtr3End: string, Qtr3Start: string, Qtr4End: string, Qtr4Start: string, Qtr5End: string, Qtr5Start: string, Qtr6End: string, Qtr6Start: string, Qtr7End: string, Qtr7Start: string, Qtr8End: string, Qtr8Start: string, Qtr9End: string, Qtr9Start: string, Sources: list>, Reports: record<HasPollRpt: string>, SDWISCompliance: record<Mnth10End: string, Mnth10Start: string, Mnth11End: string, Mnth11Start: string, Mnth12End: string, Mnth12Start: string, Mnth13End: string, Mnth13Start: string, Mnth14End: string, Mnth14Start: string, Mnth15End: string, Mnth15Start: string, Mnth16End: string, Mnth16Start: string, Mnth17End: string, Mnth17Start: string, Mnth18End: string, Mnth18Start: string, Mnth19End: string, Mnth19Start: string, Mnth1End: string, Mnth1Start: string, Mnth20End: string, Mnth20Start: string, Mnth21End: string, Mnth21Start: string, Mnth22End: string, Mnth22Start: string, Mnth23End: string, Mnth23Start: string, Mnth24End: string, Mnth24Start: string, Mnth25End: string, Mnth25Start: string, Mnth26End: string, Mnth26Start: string, Mnth27End: string, Mnth27Start: string, Mnth28End: string, Mnth28Start: string, Mnth29End: string, Mnth29Start: string, Mnth2End: string, Mnth2Start: string, Mnth30End: string, Mnth30Start: string, Mnth31End: string, Mnth31Start: string, Mnth32End: string, Mnth32Start: string, Mnth33End: string, Mnth33Start: string, Mnth34End: string, Mnth34Start: string, Mnth35End: string, Mnth35Start: string, Mnth36End: string, Mnth36Start: string, Mnth37End: string, Mnth37Start: string, Mnth38End: string, Mnth38Start: string, Mnth39End: string, Mnth39Start: string, Mnth3End: string, Mnth3Start: string, Mnth4End: string, Mnth4Start: string, Mnth5End: string, Mnth5Start: string, Mnth6End: string, Mnth6Start: string, Mnth7End: string, Mnth7Start: string, Mnth8End: string, Mnth8Start: string, Mnth9End: string, Mnth9Start: string, Qtr10End: string, Qtr10Start: string, Qtr11End: string, Qtr11Start: string, Qtr12End: string, Qtr12Start: string, Qtr13End: string, Qtr13Start: string, Qtr1End: string, Qtr1Start: string, Qtr2End: string, Qtr2Start: string, Qtr3End: string, Qtr3Start: string, Qtr4End: string, Qtr4Start: string, Qtr5End: string, Qtr5Start: string, Qtr6End: string, Qtr6Start: string, Qtr7End: string, Qtr7Start: string, Qtr8End: string, Qtr8Start: string, Qtr9End: string, Qtr9Start: string, Sources: list>, SIC: record<Sources: list>, SanitarySurveys: record<Sources: list>, SiteVisits: record<Sources: list>, SpatialMetadata: record<CalculatedAccuracy: string, CollectionMethod: string, CoordinateSourceSystem: string, CoordinateSourceSystemId: string, Latitude83: string, Longitude83: string, ReferencePoint: string, RegistryID: string>, SystemExtractDates: record<Dates: list>, TRIHistory: record<Sources: list>, TRIReleases: record<Chemicals: list, Header: list>, Tribes: list<record>, ViolationsEnforcementActions: record<Sources: list>, WaterQuality: record<Sources: list>, WaterQualityDetails: record<Sources: list>, WebFireDocuments: list<record>>>"
    get-dfr-rest-services-get-ejscreen-indexes: "record<Results: record<EJScreenIndexes: record<HazardWasteProximity: string, LeadPaintIndicator: string, NATACancerRisk: string, NATADieselPM: string, NATARespiratoryHI: string, Over80Count: string, Ozone: string, PM25: string, RMPProximity: string, RegistryID: string, SuperfundProximity: string, TrafficProximity: string, WaterDischargeProximity: string>, Message: string>>"
    post-dfr-rest-services-get-ejscreen-indexes: "record<Results: record<EJScreenIndexes: record<HazardWasteProximity: string, LeadPaintIndicator: string, NATACancerRisk: string, NATADieselPM: string, NATARespiratoryHI: string, Over80Count: string, Ozone: string, PM25: string, RMPProximity: string, RegistryID: string, SuperfundProximity: string, TrafficProximity: string, WaterDischargeProximity: string>, Message: string>>"
    get-dfr-rest-services-get-enforcement-summary: "record<Results: record<EnforcementComplianceSummaries: record<ProgramDates: list, Summaries: list>, Message: string>>"
    post-dfr-rest-services-get-enforcement-summary: "record<Results: record<EnforcementComplianceSummaries: record<ProgramDates: list, Summaries: list>, Message: string>>"
    get-dfr-rest-services-get-extract-dates: "record<Results: record<Message: string, SystemExtractDates: record<Dates: list>>>"
    post-dfr-rest-services-get-extract-dates: "record<Results: record<Message: string, SystemExtractDates: record<Dates: list>>>"
    get-dfr-rest-services-get-formal-actions: "record<Results: record<FormalActions: record<Action: list, ProgramDates: list>, Message: string>>"
    post-dfr-rest-services-get-formal-actions: "record<Results: record<FormalActions: record<Action: list, ProgramDates: list>, Message: string>>"
    get-dfr-rest-services-get-icis-formal-actions: "record<Results: record<ICISFormalActions: record<Action: list, ProgramDates: list>, Message: string>>"
    post-dfr-rest-services-get-icis-formal-actions: "record<Results: record<ICISFormalActions: record<Action: list, ProgramDates: list>, Message: string>>"
    get-dfr-rest-services-get-inspections: "record<Results: record<InspectionEnforcementSummary: record<ProgramDates: list, Source: list>, Message: string>>"
    post-dfr-rest-services-get-inspections: "record<Results: record<InspectionEnforcementSummary: record<ProgramDates: list, Source: list>, Message: string>>"
    get-dfr-rest-services-get-map: "record<Results: record<MapOutput: record<CenterLatitude: string, CenterLongitude: string, IconBaseURL: string, MapData: list, PopUpBaseURL: string>, Message: string>>"
    post-dfr-rest-services-get-map: "record<Results: record<MapOutput: record<CenterLatitude: string, CenterLongitude: string, IconBaseURL: string, MapData: list, PopUpBaseURL: string>, Message: string>>"
    get-dfr-rest-services-get-naics: "record<Results: record<Message: string, NAICS: record<Sources: list>>>"
    post-dfr-rest-services-get-naics: "record<Results: record<Message: string, NAICS: record<Sources: list>>>"
    get-dfr-rest-services-get-notices: "record<Results: record<Message: string, Notices: record<Notice: list, ProgramDates: list>>>"
    post-dfr-rest-services-get-notices: "record<Results: record<Message: string, Notices: record<Notice: list, ProgramDates: list>>>"
    get-dfr-rest-services-get-permits: "record<Results: record<Message: string, Permits: list<record>, Reports: record<HasPollRpt: string>>>"
    post-dfr-rest-services-get-permits: "record<Results: record<Message: string, Permits: list<record>, Reports: record<HasPollRpt: string>>>"
    get-dfr-rest-services-get-rcra-compliance: "record<Results: record<Message: string, RCRACompliance: record<Mnth10End: string, Mnth10Start: string, Mnth11End: string, Mnth11Start: string, Mnth12End: string, Mnth12Start: string, Mnth13End: string, Mnth13Start: string, Mnth14End: string, Mnth14Start: string, Mnth15End: string, Mnth15Start: string, Mnth16End: string, Mnth16Start: string, Mnth17End: string, Mnth17Start: string, Mnth18End: string, Mnth18Start: string, Mnth19End: string, Mnth19Start: string, Mnth1End: string, Mnth1Start: string, Mnth20End: string, Mnth20Start: string, Mnth21End: string, Mnth21Start: string, Mnth22End: string, Mnth22Start: string, Mnth23End: string, Mnth23Start: string, Mnth24End: string, Mnth24Start: string, Mnth25End: string, Mnth25Start: string, Mnth26End: string, Mnth26Start: string, Mnth27End: string, Mnth27Start: string, Mnth28End: string, Mnth28Start: string, Mnth29End: string, Mnth29Start: string, Mnth2End: string, Mnth2Start: string, Mnth30End: string, Mnth30Start: string, Mnth31End: string, Mnth31Start: string, Mnth32End: string, Mnth32Start: string, Mnth33End: string, Mnth33Start: string, Mnth34End: string, Mnth34Start: string, Mnth35End: string, Mnth35Start: string, Mnth36End: string, Mnth36Start: string, Mnth3End: string, Mnth3Start: string, Mnth4End: string, Mnth4Start: string, Mnth5End: string, Mnth5Start: string, Mnth6End: string, Mnth6Start: string, Mnth7End: string, Mnth7Start: string, Mnth8End: string, Mnth8Start: string, Mnth9End: string, Mnth9Start: string, Qtr10End: string, Qtr10Start: string, Qtr11End: string, Qtr11Start: string, Qtr12End: string, Qtr12Start: string, Qtr1End: string, Qtr1Start: string, Qtr2End: string, Qtr2Start: string, Qtr3End: string, Qtr3Start: string, Qtr4End: string, Qtr4Start: string, Qtr5End: string, Qtr5Start: string, Qtr6End: string, Qtr6Start: string, Qtr7End: string, Qtr7Start: string, Qtr8End: string, Qtr8Start: string, Qtr9End: string, Qtr9Start: string, Sources: list>>>"
    post-dfr-rest-services-get-rcra-compliance: "record<Results: record<Message: string, RCRACompliance: record<Mnth10End: string, Mnth10Start: string, Mnth11End: string, Mnth11Start: string, Mnth12End: string, Mnth12Start: string, Mnth13End: string, Mnth13Start: string, Mnth14End: string, Mnth14Start: string, Mnth15End: string, Mnth15Start: string, Mnth16End: string, Mnth16Start: string, Mnth17End: string, Mnth17Start: string, Mnth18End: string, Mnth18Start: string, Mnth19End: string, Mnth19Start: string, Mnth1End: string, Mnth1Start: string, Mnth20End: string, Mnth20Start: string, Mnth21End: string, Mnth21Start: string, Mnth22End: string, Mnth22Start: string, Mnth23End: string, Mnth23Start: string, Mnth24End: string, Mnth24Start: string, Mnth25End: string, Mnth25Start: string, Mnth26End: string, Mnth26Start: string, Mnth27End: string, Mnth27Start: string, Mnth28End: string, Mnth28Start: string, Mnth29End: string, Mnth29Start: string, Mnth2End: string, Mnth2Start: string, Mnth30End: string, Mnth30Start: string, Mnth31End: string, Mnth31Start: string, Mnth32End: string, Mnth32Start: string, Mnth33End: string, Mnth33Start: string, Mnth34End: string, Mnth34Start: string, Mnth35End: string, Mnth35Start: string, Mnth36End: string, Mnth36Start: string, Mnth3End: string, Mnth3Start: string, Mnth4End: string, Mnth4Start: string, Mnth5End: string, Mnth5Start: string, Mnth6End: string, Mnth6Start: string, Mnth7End: string, Mnth7Start: string, Mnth8End: string, Mnth8Start: string, Mnth9End: string, Mnth9Start: string, Qtr10End: string, Qtr10Start: string, Qtr11End: string, Qtr11Start: string, Qtr12End: string, Qtr12Start: string, Qtr1End: string, Qtr1Start: string, Qtr2End: string, Qtr2Start: string, Qtr3End: string, Qtr3Start: string, Qtr4End: string, Qtr4Start: string, Qtr5End: string, Qtr5Start: string, Qtr6End: string, Qtr6Start: string, Qtr7End: string, Qtr7Start: string, Qtr8End: string, Qtr8Start: string, Qtr9End: string, Qtr9Start: string, Sources: list>>>"
    get-dfr-rest-services-get-sdwa-lead-and-copper: "record<Results: record<LeadAndCopperRule5Yr: record<CopperSamples: list, CuALE: string, CuALEUnits: string, CuALEValue: string, CuSampleDates: string, CuViol: string, LeadAndCopperViol: string, LeadCopperRuleHealthBasedViol: string, LeadSamples: list, PbALE: string, PbALEUnits: string, PbALEValue: string, PbSampleDates: string, PbViol: string, RuleCode350Viol: string, SourceID: string, iCU90: string, iPB90: string>, Message: string>>"
    post-dfr-rest-services-get-sdwa-lead-and-copper: "record<Results: record<LeadAndCopperRule5Yr: record<CopperSamples: list, CuALE: string, CuALEUnits: string, CuALEValue: string, CuSampleDates: string, CuViol: string, LeadAndCopperViol: string, LeadCopperRuleHealthBasedViol: string, LeadSamples: list, PbALE: string, PbALEUnits: string, PbALEValue: string, PbSampleDates: string, PbViol: string, RuleCode350Viol: string, SourceID: string, iCU90: string, iPB90: string>, Message: string>>"
    get-dfr-rest-services-get-sdwa-sanitary-surveys: "record<Results: record<Message: string, SanitarySurveys: record<Sources: list>>>"
    post-dfr-rest-services-get-sdwa-sanitary-surveys: "record<Results: record<Message: string, SanitarySurveys: record<Sources: list>>>"
    get-dfr-rest-services-get-sdwa-site-visits: "record<Results: record<Message: string, SiteVisits: record<Sources: list>>>"
    post-dfr-rest-services-get-sdwa-site-visits: "record<Results: record<Message: string, SiteVisits: record<Sources: list>>>"
    get-dfr-rest-services-get-sdwa-violations: "record<Results: record<Message: string, ViolationsEnforcementActions: record<Sources: list>>>"
    post-dfr-rest-services-get-sdwa-violations: "record<Results: record<Message: string, ViolationsEnforcementActions: record<Sources: list>>>"
    get-dfr-rest-services-get-sdwis-compliance: "record<Results: record<Message: string, SDWISCompliance: record<Mnth10End: string, Mnth10Start: string, Mnth11End: string, Mnth11Start: string, Mnth12End: string, Mnth12Start: string, Mnth13End: string, Mnth13Start: string, Mnth14End: string, Mnth14Start: string, Mnth15End: string, Mnth15Start: string, Mnth16End: string, Mnth16Start: string, Mnth17End: string, Mnth17Start: string, Mnth18End: string, Mnth18Start: string, Mnth19End: string, Mnth19Start: string, Mnth1End: string, Mnth1Start: string, Mnth20End: string, Mnth20Start: string, Mnth21End: string, Mnth21Start: string, Mnth22End: string, Mnth22Start: string, Mnth23End: string, Mnth23Start: string, Mnth24End: string, Mnth24Start: string, Mnth25End: string, Mnth25Start: string, Mnth26End: string, Mnth26Start: string, Mnth27End: string, Mnth27Start: string, Mnth28End: string, Mnth28Start: string, Mnth29End: string, Mnth29Start: string, Mnth2End: string, Mnth2Start: string, Mnth30End: string, Mnth30Start: string, Mnth31End: string, Mnth31Start: string, Mnth32End: string, Mnth32Start: string, Mnth33End: string, Mnth33Start: string, Mnth34End: string, Mnth34Start: string, Mnth35End: string, Mnth35Start: string, Mnth36End: string, Mnth36Start: string, Mnth37End: string, Mnth37Start: string, Mnth38End: string, Mnth38Start: string, Mnth39End: string, Mnth39Start: string, Mnth3End: string, Mnth3Start: string, Mnth4End: string, Mnth4Start: string, Mnth5End: string, Mnth5Start: string, Mnth6End: string, Mnth6Start: string, Mnth7End: string, Mnth7Start: string, Mnth8End: string, Mnth8Start: string, Mnth9End: string, Mnth9Start: string, Qtr10End: string, Qtr10Start: string, Qtr11End: string, Qtr11Start: string, Qtr12End: string, Qtr12Start: string, Qtr13End: string, Qtr13Start: string, Qtr1End: string, Qtr1Start: string, Qtr2End: string, Qtr2Start: string, Qtr3End: string, Qtr3Start: string, Qtr4End: string, Qtr4Start: string, Qtr5End: string, Qtr5Start: string, Qtr6End: string, Qtr6Start: string, Qtr7End: string, Qtr7Start: string, Qtr8End: string, Qtr8Start: string, Qtr9End: string, Qtr9Start: string, Sources: list>>>"
    post-dfr-rest-services-get-sdwis-compliance: "record<Results: record<Message: string, SDWISCompliance: record<Mnth10End: string, Mnth10Start: string, Mnth11End: string, Mnth11Start: string, Mnth12End: string, Mnth12Start: string, Mnth13End: string, Mnth13Start: string, Mnth14End: string, Mnth14Start: string, Mnth15End: string, Mnth15Start: string, Mnth16End: string, Mnth16Start: string, Mnth17End: string, Mnth17Start: string, Mnth18End: string, Mnth18Start: string, Mnth19End: string, Mnth19Start: string, Mnth1End: string, Mnth1Start: string, Mnth20End: string, Mnth20Start: string, Mnth21End: string, Mnth21Start: string, Mnth22End: string, Mnth22Start: string, Mnth23End: string, Mnth23Start: string, Mnth24End: string, Mnth24Start: string, Mnth25End: string, Mnth25Start: string, Mnth26End: string, Mnth26Start: string, Mnth27End: string, Mnth27Start: string, Mnth28End: string, Mnth28Start: string, Mnth29End: string, Mnth29Start: string, Mnth2End: string, Mnth2Start: string, Mnth30End: string, Mnth30Start: string, Mnth31End: string, Mnth31Start: string, Mnth32End: string, Mnth32Start: string, Mnth33End: string, Mnth33Start: string, Mnth34End: string, Mnth34Start: string, Mnth35End: string, Mnth35Start: string, Mnth36End: string, Mnth36Start: string, Mnth37End: string, Mnth37Start: string, Mnth38End: string, Mnth38Start: string, Mnth39End: string, Mnth39Start: string, Mnth3End: string, Mnth3Start: string, Mnth4End: string, Mnth4Start: string, Mnth5End: string, Mnth5Start: string, Mnth6End: string, Mnth6Start: string, Mnth7End: string, Mnth7Start: string, Mnth8End: string, Mnth8Start: string, Mnth9End: string, Mnth9Start: string, Qtr10End: string, Qtr10Start: string, Qtr11End: string, Qtr11Start: string, Qtr12End: string, Qtr12Start: string, Qtr13End: string, Qtr13Start: string, Qtr1End: string, Qtr1Start: string, Qtr2End: string, Qtr2Start: string, Qtr3End: string, Qtr3Start: string, Qtr4End: string, Qtr4Start: string, Qtr5End: string, Qtr5Start: string, Qtr6End: string, Qtr6Start: string, Qtr7End: string, Qtr7Start: string, Qtr8End: string, Qtr8Start: string, Qtr9End: string, Qtr9Start: string, Sources: list>>>"
    get-dfr-rest-services-get-sic-codes: "record<Results: record<Message: string, SIC: record<Sources: list>>>"
    post-dfr-rest-services-get-sic-codes: "record<Results: record<Message: string, SIC: record<Sources: list>>>"
    get-dfr-rest-services-get-spatial-metadata: "record<Results: record<Message: string, SpatialMetadata: record<CalculatedAccuracy: string, CollectionMethod: string, CoordinateSourceSystem: string, CoordinateSourceSystemId: string, Latitude83: string, Longitude83: string, ReferencePoint: string, RegistryID: string>>>"
    post-dfr-rest-services-get-spatial-metadata: "record<Results: record<Message: string, SpatialMetadata: record<CalculatedAccuracy: string, CollectionMethod: string, CoordinateSourceSystem: string, CoordinateSourceSystemId: string, Latitude83: string, Longitude83: string, ReferencePoint: string, RegistryID: string>>>"
    get-dfr-rest-services-get-tri-history: "record<Results: record<Message: string, TRIHistory: record<Sources: list>>>"
    post-dfr-rest-services-get-tri-history: "record<Results: record<Message: string, TRIHistory: record<Sources: list>>>"
    get-dfr-rest-services-get-tri-releases: "record<Results: record<Message: string, TRIReleases: record<Chemicals: list, Header: list>>>"
    post-dfr-rest-services-get-tri-releases: "record<Results: record<Message: string, TRIReleases: record<Chemicals: list, Header: list>>>"
    get-dfr-rest-services-get-tribes: "record<Results: record<Message: string, Tribes: list<record>>>"
    post-dfr-rest-services-get-tribes: "record<Results: record<Message: string, Tribes: list<record>>>"
    get-dfr-rest-services-get-water-quality: "record<Results: record<Message: string, WaterQuality: record<Sources: list>>>"
    post-dfr-rest-services-get-water-quality: "record<Results: record<Message: string, WaterQuality: record<Sources: list>>>"
    get-dfr-rest-services-get-water-quality-details: "record<Results: record<Message: string, WaterQualityDetails: record<Sources: list>>>"
    post-dfr-rest-services-get-water-quality-details: "record<Results: record<Message: string, WaterQualityDetails: record<Sources: list>>>"
    get-dfr-rest-services-rcra-3-yr-download: "binary"
    post-dfr-rest-services-rcra-3-yr-download: "binary"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-dfr-rest-services-air-3-yr-download" "post-dfr-rest-services-air-3-yr-download" "get-dfr-rest-services-cwa-3-yr-effluent-download" "post-dfr-rest-services-cwa-3-yr-effluent-download" "get-dfr-rest-services-cwa-3-yr-sepscs-download" "post-dfr-rest-services-cwa-3-yr-sepscs-download" "get-dfr-rest-services-get-air-compliance" "post-dfr-rest-services-get-air-compliance" "get-dfr-rest-services-get-air-quality" "post-dfr-rest-services-get-air-quality" "get-dfr-rest-services-get-aws-docs" "post-dfr-rest-services-get-aws-docs" "get-dfr-rest-services-get-case-formal-actions" "post-dfr-rest-services-get-case-formal-actions" "get-dfr-rest-services-get-compliance-history" "post-dfr-rest-services-get-compliance-history" "get-dfr-rest-services-get-compliance-summary" "post-dfr-rest-services-get-compliance-summary" "get-dfr-rest-services-get-csv" "post-dfr-rest-services-get-csv" "get-dfr-rest-services-get-cwa-3yr-compliance" "post-dfr-rest-services-get-cwa-3yr-compliance" "get-dfr-rest-services-get-cwa-3yr-d80d90-counts" "post-dfr-rest-services-get-cwa-3yr-d80d90-counts" "get-dfr-rest-services-get-cwa-cs-compliance" "post-dfr-rest-services-get-cwa-cs-compliance" "get-dfr-rest-services-get-cwa-eff-alr" "post-dfr-rest-services-get-cwa-eff-alr" "get-dfr-rest-services-get-cwa-eff-alr-exp" "post-dfr-rest-services-get-cwa-eff-alr-exp" "get-dfr-rest-services-get-cwa-eff-compliance" "post-dfr-rest-services-get-cwa-eff-compliance" "get-dfr-rest-services-get-cwa-eff-compliance-exp" "post-dfr-rest-services-get-cwa-eff-compliance-exp" "get-dfr-rest-services-get-cwa-ps-compliance" "post-dfr-rest-services-get-cwa-ps-compliance" "get-dfr-rest-services-get-cwa-rnc-compliance" "post-dfr-rest-services-get-cwa-rnc-compliance" "get-dfr-rest-services-get-cwa-se-compliance" "post-dfr-rest-services-get-cwa-se-compliance" "get-dfr-rest-services-get-d80d90s-details" "post-dfr-rest-services-get-d80d90s-details" "get-dfr-rest-services-get-demographics-by-id" "post-dfr-rest-services-get-demographics-by-id" "get-dfr-rest-services-get-dfr" "post-dfr-rest-services-get-dfr" "get-dfr-rest-services-get-ejscreen-indexes" "post-dfr-rest-services-get-ejscreen-indexes" "get-dfr-rest-services-get-enforcement-summary" "post-dfr-rest-services-get-enforcement-summary" "get-dfr-rest-services-get-extract-dates" "post-dfr-rest-services-get-extract-dates" "get-dfr-rest-services-get-formal-actions" "post-dfr-rest-services-get-formal-actions" "get-dfr-rest-services-get-icis-formal-actions" "post-dfr-rest-services-get-icis-formal-actions" "get-dfr-rest-services-get-inspections" "post-dfr-rest-services-get-inspections" "get-dfr-rest-services-get-map" "post-dfr-rest-services-get-map" "get-dfr-rest-services-get-naics" "post-dfr-rest-services-get-naics" "get-dfr-rest-services-get-notices" "post-dfr-rest-services-get-notices" "get-dfr-rest-services-get-permits" "post-dfr-rest-services-get-permits" "get-dfr-rest-services-get-rcra-compliance" "post-dfr-rest-services-get-rcra-compliance" "get-dfr-rest-services-get-sdwa-lead-and-copper" "post-dfr-rest-services-get-sdwa-lead-and-copper" "get-dfr-rest-services-get-sdwa-sanitary-surveys" "post-dfr-rest-services-get-sdwa-sanitary-surveys" "get-dfr-rest-services-get-sdwa-site-visits" "post-dfr-rest-services-get-sdwa-site-visits" "get-dfr-rest-services-get-sdwa-violations" "post-dfr-rest-services-get-sdwa-violations" "get-dfr-rest-services-get-sdwis-compliance" "post-dfr-rest-services-get-sdwis-compliance" "get-dfr-rest-services-get-sic-codes" "post-dfr-rest-services-get-sic-codes" "get-dfr-rest-services-get-spatial-metadata" "post-dfr-rest-services-get-spatial-metadata" "get-dfr-rest-services-get-tri-history" "post-dfr-rest-services-get-tri-history" "get-dfr-rest-services-get-tri-releases" "post-dfr-rest-services-get-tri-releases" "get-dfr-rest-services-get-tribes" "post-dfr-rest-services-get-tribes" "get-dfr-rest-services-get-water-quality" "post-dfr-rest-services-get-water-quality" "get-dfr-rest-services-get-water-quality-details" "post-dfr-rest-services-get-water-quality-details" "get-dfr-rest-services-rcra-3-yr-download" "post-dfr-rest-services-rcra-3-yr-download" "commands"] | sort) } | get name | first)
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

# Downloads the complete Air Compliance History Section of the DFR
#
# GET /dfr_rest_services.air_3_yr_download
# Returns: binary
export def "get-dfr-rest-services-air-3-yr-download" [
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
    path: "/dfr_rest_services.air_3_yr_download"
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Downloads the complete Air Compliance History Section of the DFR
#
# POST /dfr_rest_services.air_3_yr_download
# Returns: binary
export def "post-dfr-rest-services-air-3-yr-download" [
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
    method: post
    path: "/dfr_rest_services.air_3_yr_download"
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Downloads NPDES Effluent Violation Information by month and quarter.
#
# GET /dfr_rest_services.cwa_3_yr_effluent_download
# Returns: binary
export def "get-dfr-rest-services-cwa-3-yr-effluent-download" [
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
    path: "/dfr_rest_services.cwa_3_yr_effluent_download"
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Downloads NPDES Effluent Violation Information by month and quarter.
#
# POST /dfr_rest_services.cwa_3_yr_effluent_download
# Returns: binary
export def "post-dfr-rest-services-cwa-3-yr-effluent-download" [
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
    method: post
    path: "/dfr_rest_services.cwa_3_yr_effluent_download"
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Downloads NPDES Compliance Schedule, Permit Schedule and Single Event Violation Information by month and quarter.
#
# GET /dfr_rest_services.cwa_3_yr_sepscs_download
# Returns: binary
export def "get-dfr-rest-services-cwa-3-yr-sepscs-download" [
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
    path: "/dfr_rest_services.cwa_3_yr_sepscs_download"
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Downloads NPDES Compliance Schedule, Permit Schedule and Single Event Violation Information by month and quarter.
#
# POST /dfr_rest_services.cwa_3_yr_sepscs_download
# Returns: binary
export def "post-dfr-rest-services-cwa-3-yr-sepscs-download" [
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
    method: post
    path: "/dfr_rest_services.cwa_3_yr_sepscs_download"
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Detailed Facility Report Air Compliance Report Service
#
# GET /dfr_rest_services.get_air_compliance
# Returns: record<Results: record<AirCompliance: record<Header: record, Sources: list>, Message: string>>
export def "get-dfr-rest-services-get-air-compliance" [
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
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID). (required)
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dfr_rest_services.get_air_compliance"
    query: [{name: output, var: output}, {name: p_id, var: p_id, required: true}, {name: callback, var: callback}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Detailed Facility Report Air Compliance Report Service
#
# POST /dfr_rest_services.get_air_compliance
# Returns: record<Results: record<AirCompliance: record<Header: record, Sources: list>, Message: string>>
export def "post-dfr-rest-services-get-air-compliance" [
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
  p_id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/dfr_rest_services.get_air_compliance"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: p_id, var: p_id}, {name: callback, var: callback}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Detailed Facility Report Air Quality Report Service
#
# GET /dfr_rest_services.get_air_quality
# Returns: record<Results: record<AirQuality: record<CarbonMonoxide1971Area: string, Lead1978Area: string, Lead2008Area: string, NitrogenDioxide1971Area: string, Ozone8hr1997Area: string, Ozone8hr2008Area: string, Ozone8hr2015Area: string, ParticulateMatter1987Area: string, ParticulateMatter1997Area: string, ParticulateMatter2006Area: string, ParticulateMatter2012Area: string, SulfurDioxide1971Area: string, SulfurDioxide2010Area: string>, Message: string>>
export def "get-dfr-rest-services-get-air-quality" [
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
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID). (required)
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dfr_rest_services.get_air_quality"
    query: [{name: output, var: output}, {name: p_id, var: p_id, required: true}, {name: callback, var: callback}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Detailed Facility Report Air Quality Report Service
#
# POST /dfr_rest_services.get_air_quality
# Returns: record<Results: record<AirQuality: record<CarbonMonoxide1971Area: string, Lead1978Area: string, Lead2008Area: string, NitrogenDioxide1971Area: string, Ozone8hr1997Area: string, Ozone8hr2008Area: string, Ozone8hr2015Area: string, ParticulateMatter1987Area: string, ParticulateMatter1997Area: string, ParticulateMatter2006Area: string, ParticulateMatter2012Area: string, SulfurDioxide1971Area: string, SulfurDioxide2010Area: string>, Message: string>>
export def "post-dfr-rest-services-get-air-quality" [
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
  p_id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/dfr_rest_services.get_air_quality"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: p_id, var: p_id}, {name: callback, var: callback}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Placeholder
#
# GET /dfr_rest_services.get_aws_docs
# Returns: record<Results: record<Message: string>>
export def "get-dfr-rest-services-get-aws-docs" [
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
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID). (required)
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dfr_rest_services.get_aws_docs"
    query: [{name: output, var: output}, {name: p_id, var: p_id, required: true}, {name: callback, var: callback}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Placeholder
#
# POST /dfr_rest_services.get_aws_docs
# Returns: record<Results: record<Message: string>>
export def "post-dfr-rest-services-get-aws-docs" [
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
  p_id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/dfr_rest_services.get_aws_docs"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: p_id, var: p_id}, {name: callback, var: callback}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Displays Cases related to the Facility
#
# GET /dfr_rest_services.get_case_formal_actions
# Returns: record<Results: record<CaseFormalActions: record<Action: list, ProgramDates: list>, Message: string>>
export def "get-dfr-rest-services-get-case-formal-actions" [
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
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID). (required)
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dfr_rest_services.get_case_formal_actions"
    query: [{name: output, var: output}, {name: p_id, var: p_id, required: true}, {name: callback, var: callback}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Displays Cases related to the Facility
#
# POST /dfr_rest_services.get_case_formal_actions
# Returns: record<Results: record<CaseFormalActions: record<Action: list, ProgramDates: list>, Message: string>>
export def "post-dfr-rest-services-get-case-formal-actions" [
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
  p_id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/dfr_rest_services.get_case_formal_actions"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: p_id, var: p_id}, {name: callback, var: callback}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Detailed Facility Report 5 Year Compliance Monitoring History Service
#
# GET /dfr_rest_services.get_compliance_history
# Returns: record<Results: record<ComplianceHistory: record<Inspection: list, ProgramDates: list>, Message: string>>
export def "get-dfr-rest-services-get-compliance-history" [
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
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID). (required)
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dfr_rest_services.get_compliance_history"
    query: [{name: output, var: output}, {name: p_id, var: p_id, required: true}, {name: callback, var: callback}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Detailed Facility Report 5 Year Compliance Monitoring History Service
#
# POST /dfr_rest_services.get_compliance_history
# Returns: record<Results: record<ComplianceHistory: record<Inspection: list, ProgramDates: list>, Message: string>>
export def "post-dfr-rest-services-get-compliance-history" [
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
  p_id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/dfr_rest_services.get_compliance_history"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: p_id, var: p_id}, {name: callback, var: callback}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Detailed Facility Report Compliance Summary Service
#
# GET /dfr_rest_services.get_compliance_summary
# Returns: record<Results: record<ComplianceSummary: record<ProgramDates: list, Source: list>, Message: string>>
export def "get-dfr-rest-services-get-compliance-summary" [
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
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID). (required)
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dfr_rest_services.get_compliance_summary"
    query: [{name: output, var: output}, {name: p_id, var: p_id, required: true}, {name: callback, var: callback}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Detailed Facility Report Compliance Summary Service
#
# POST /dfr_rest_services.get_compliance_summary
# Returns: record<Results: record<ComplianceSummary: record<ProgramDates: list, Source: list>, Message: string>>
export def "post-dfr-rest-services-get-compliance-summary" [
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
  p_id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/dfr_rest_services.get_compliance_summary"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: p_id, var: p_id}, {name: callback, var: callback}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Downloads a spectific section of the DFR in CSV Format
#
# GET /dfr_rest_services.get_csv
# Returns: binary
export def "get-dfr-rest-services-get-csv" [
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
    path: "/dfr_rest_services.get_csv"
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Downloads a spectific section of the DFR in CSV Format
#
# POST /dfr_rest_services.get_csv
# Returns: binary
export def "post-dfr-rest-services-get-csv" [
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
    method: post
    path: "/dfr_rest_services.get_csv"
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Detailed Facility Report 3 Year CWA Facility-Level Status Service
#
# GET /dfr_rest_services.get_cwa_3yr_compliance
# Returns: record<Results: record<CWA3YrCompliance: record<Header: record, Sources: list>, Message: string>>
export def "get-dfr-rest-services-get-cwa-3yr-compliance" [
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
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID). (required)
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dfr_rest_services.get_cwa_3yr_compliance"
    query: [{name: output, var: output}, {name: p_id, var: p_id, required: true}, {name: callback, var: callback}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Detailed Facility Report 3 Year CWA Facility-Level Status Service
#
# POST /dfr_rest_services.get_cwa_3yr_compliance
# Returns: record<Results: record<CWA3YrCompliance: record<Header: record, Sources: list>, Message: string>>
export def "post-dfr-rest-services-get-cwa-3yr-compliance" [
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
  p_id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/dfr_rest_services.get_cwa_3yr_compliance"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: p_id, var: p_id}, {name: callback, var: callback}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Displays monlthly and quarterly counts of D80 and D90 Effluent Non Reporting Violations Related to the Facility
#
# GET /dfr_rest_services.get_cwa_3yr_d80d90_counts
# Returns: record<Results: record<CWA3YrD80D90Counts: record<Header: record, Sources: list>, Message: string>>
export def "get-dfr-rest-services-get-cwa-3yr-d80d90-counts" [
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
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID). (required)
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dfr_rest_services.get_cwa_3yr_d80d90_counts"
    query: [{name: output, var: output}, {name: p_id, var: p_id, required: true}, {name: callback, var: callback}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Displays monlthly and quarterly counts of D80 and D90 Effluent Non Reporting Violations Related to the Facility
#
# POST /dfr_rest_services.get_cwa_3yr_d80d90_counts
# Returns: record<Results: record<CWA3YrD80D90Counts: record<Header: record, Sources: list>, Message: string>>
export def "post-dfr-rest-services-get-cwa-3yr-d80d90-counts" [
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
  p_id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/dfr_rest_services.get_cwa_3yr_d80d90_counts"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: p_id, var: p_id}, {name: callback, var: callback}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Detailed Facility Report CWA CSV Compliance Service
#
# GET /dfr_rest_services.get_cwa_cs_compliance
# Returns: record<Results: record<CWACSCompliance: record<Header: record, Sources: list>, Message: string>>
export def "get-dfr-rest-services-get-cwa-cs-compliance" [
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
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID). (required)
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dfr_rest_services.get_cwa_cs_compliance"
    query: [{name: output, var: output}, {name: p_id, var: p_id, required: true}, {name: callback, var: callback}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Detailed Facility Report CWA CSV Compliance Service
#
# POST /dfr_rest_services.get_cwa_cs_compliance
# Returns: record<Results: record<CWACSCompliance: record<Header: record, Sources: list>, Message: string>>
export def "post-dfr-rest-services-get-cwa-cs-compliance" [
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
  p_id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/dfr_rest_services.get_cwa_cs_compliance"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: p_id, var: p_id}, {name: callback, var: callback}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Detailed Facility Report CWA Effluent ALR Service
#
# GET /dfr_rest_services.get_cwa_eff_alr
# Returns: record<Results: record<CWAEffluentALRExceedences: record<Header: record, Sources: list>, Message: string>>
export def "get-dfr-rest-services-get-cwa-eff-alr" [
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
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID). (required)
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dfr_rest_services.get_cwa_eff_alr"
    query: [{name: output, var: output}, {name: p_id, var: p_id, required: true}, {name: callback, var: callback}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Detailed Facility Report CWA Effluent ALR Service
#
# POST /dfr_rest_services.get_cwa_eff_alr
# Returns: record<Results: record<CWAEffluentALRExceedences: record<Header: record, Sources: list>, Message: string>>
export def "post-dfr-rest-services-get-cwa-eff-alr" [
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
  p_id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/dfr_rest_services.get_cwa_eff_alr"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: p_id, var: p_id}, {name: callback, var: callback}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Placeholder
#
# GET /dfr_rest_services.get_cwa_eff_alr_exp
# Returns: record<Results: record<CWAEffluentALRExceedencesEXP: record<Header: record, Sources: list>, Message: string>>
export def "get-dfr-rest-services-get-cwa-eff-alr-exp" [
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
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID). (required)
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dfr_rest_services.get_cwa_eff_alr_exp"
    query: [{name: output, var: output}, {name: p_id, var: p_id, required: true}, {name: callback, var: callback}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Placeholder
#
# POST /dfr_rest_services.get_cwa_eff_alr_exp
# Returns: record<Results: record<CWAEffluentALRExceedencesEXP: record<Header: record, Sources: list>, Message: string>>
export def "post-dfr-rest-services-get-cwa-eff-alr-exp" [
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
  p_id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/dfr_rest_services.get_cwa_eff_alr_exp"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: p_id, var: p_id}, {name: callback, var: callback}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Detailed Facility Report CWA Effluent Compliance Service
#
# GET /dfr_rest_services.get_cwa_eff_compliance
# Returns: record<Results: record<CWAEffluentCompliance: record<Header: record, Sources: list>, Message: string>>
export def "get-dfr-rest-services-get-cwa-eff-compliance" [
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
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID). (required)
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dfr_rest_services.get_cwa_eff_compliance"
    query: [{name: output, var: output}, {name: p_id, var: p_id, required: true}, {name: callback, var: callback}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Detailed Facility Report CWA Effluent Compliance Service
#
# POST /dfr_rest_services.get_cwa_eff_compliance
# Returns: record<Results: record<CWAEffluentCompliance: record<Header: record, Sources: list>, Message: string>>
export def "post-dfr-rest-services-get-cwa-eff-compliance" [
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
  p_id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/dfr_rest_services.get_cwa_eff_compliance"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: p_id, var: p_id}, {name: callback, var: callback}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Placeholder
#
# GET /dfr_rest_services.get_cwa_eff_compliance_exp
# Returns: record<Results: record<CWAEffluentComplianceEXP: record<Header: record, Sources: list>, Message: string>>
export def "get-dfr-rest-services-get-cwa-eff-compliance-exp" [
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
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID). (required)
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dfr_rest_services.get_cwa_eff_compliance_exp"
    query: [{name: output, var: output}, {name: p_id, var: p_id, required: true}, {name: callback, var: callback}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Placeholder
#
# POST /dfr_rest_services.get_cwa_eff_compliance_exp
# Returns: record<Results: record<CWAEffluentComplianceEXP: record<Header: record, Sources: list>, Message: string>>
export def "post-dfr-rest-services-get-cwa-eff-compliance-exp" [
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
  p_id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/dfr_rest_services.get_cwa_eff_compliance_exp"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: p_id, var: p_id}, {name: callback, var: callback}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Detailed Facility Report CWA PSV Compliance Service
#
# GET /dfr_rest_services.get_cwa_ps_compliance
# Returns: record<Results: record<CWAPSCompliance: record<Header: record, Sources: list>, Message: string>>
export def "get-dfr-rest-services-get-cwa-ps-compliance" [
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
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID). (required)
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dfr_rest_services.get_cwa_ps_compliance"
    query: [{name: output, var: output}, {name: p_id, var: p_id, required: true}, {name: callback, var: callback}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Detailed Facility Report CWA PSV Compliance Service
#
# POST /dfr_rest_services.get_cwa_ps_compliance
# Returns: record<Results: record<CWAPSCompliance: record<Header: record, Sources: list>, Message: string>>
export def "post-dfr-rest-services-get-cwa-ps-compliance" [
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
  p_id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/dfr_rest_services.get_cwa_ps_compliance"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: p_id, var: p_id}, {name: callback, var: callback}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Detailed Facility Report CWA RNC Compliance Service
#
# GET /dfr_rest_services.get_cwa_rnc_compliance
# Returns: record<Results: record<CWARNCCompliance: record<Header: record, Sources: list>, Message: string>>
export def "get-dfr-rest-services-get-cwa-rnc-compliance" [
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
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID). (required)
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dfr_rest_services.get_cwa_rnc_compliance"
    query: [{name: output, var: output}, {name: p_id, var: p_id, required: true}, {name: callback, var: callback}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Detailed Facility Report CWA RNC Compliance Service
#
# POST /dfr_rest_services.get_cwa_rnc_compliance
# Returns: record<Results: record<CWARNCCompliance: record<Header: record, Sources: list>, Message: string>>
export def "post-dfr-rest-services-get-cwa-rnc-compliance" [
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
  p_id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/dfr_rest_services.get_cwa_rnc_compliance"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: p_id, var: p_id}, {name: callback, var: callback}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Detailed Facility Report CWA SEV Compliance Service
#
# GET /dfr_rest_services.get_cwa_se_compliance
# Returns: record<Results: record<CWASECompliance: record<Header: record, Sources: list>, Message: string>>
export def "get-dfr-rest-services-get-cwa-se-compliance" [
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
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID). (required)
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dfr_rest_services.get_cwa_se_compliance"
    query: [{name: output, var: output}, {name: p_id, var: p_id, required: true}, {name: callback, var: callback}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Detailed Facility Report CWA SEV Compliance Service
#
# POST /dfr_rest_services.get_cwa_se_compliance
# Returns: record<Results: record<CWASECompliance: record<Header: record, Sources: list>, Message: string>>
export def "post-dfr-rest-services-get-cwa-se-compliance" [
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
  p_id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/dfr_rest_services.get_cwa_se_compliance"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: p_id, var: p_id}, {name: callback, var: callback}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Display detailed D80/D90 information for the facility for a given quarter or month
#
# GET /dfr_rest_services.get_d80d90s_details
# Returns: record<Results: record<D80D90sDetails: record<Sources: list>, Message: string>>
export def "get-dfr-rest-services-get-d80d90s-details" [
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
  --p-npdes-id: string # The NPDES_ID for the NPDES Permit to download DMR D80 and D90 Non-Receipt violations.
  --p-missinglate: string@p-missinglate-completer # For the D80.D90 download, identifies whether or not MISSINGviolations are downloaded or LATE violations are downloaded. Valid values are: MiISSING and LATE.
  --p-qmtype: string@p-qmtype-completer # Identifies the time frame type, month or quarter, for the D80/D90 download.
  --p-qmvalue: string # A number between 1 and 39 that identifies the specific month or quarter for the D80/D90 violation download.
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dfr_rest_services.get_d80d90s_details"
    query: [{name: output, var: output}, {name: p_npdes_id, var: p_npdes_id}, {name: p_missinglate, var: p_missinglate}, {name: p_qmtype, var: p_qmtype}, {name: p_qmvalue, var: p_qmvalue}, {name: callback, var: callback}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_npdes_id: $p_npdes_id, p_missinglate: $p_missinglate, p_qmtype: $p_qmtype, p_qmvalue: $p_qmvalue, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Display detailed D80/D90 information for the facility for a given quarter or month
#
# POST /dfr_rest_services.get_d80d90s_details
# Returns: record<Results: record<D80D90sDetails: record<Sources: list>, Message: string>>
export def "post-dfr-rest-services-get-d80d90s-details" [
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
  --p-npdes-id: string # The NPDES_ID for the NPDES Permit to download DMR D80 and D90 Non-Receipt violations.
  --p-missinglate: string@p-missinglate-completer # For the D80.D90 download, identifies whether or not MISSINGviolations are downloaded or LATE violations are downloaded. Valid values are: MiISSING and LATE.
  --p-qmtype: string@p-qmtype-completer # Identifies the time frame type, month or quarter, for the D80/D90 download.
  --p-qmvalue: string # A number between 1 and 39 that identifies the specific month or quarter for the D80/D90 violation download.
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/dfr_rest_services.get_d80d90s_details"
    query: [{name: output, var: output}, {name: p_npdes_id, var: p_npdes_id}, {name: p_missinglate, var: p_missinglate}, {name: p_qmtype, var: p_qmtype}, {name: p_qmvalue, var: p_qmvalue}, {name: callback, var: callback}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_npdes_id: $p_npdes_id, p_missinglate: $p_missinglate, p_qmtype: $p_qmtype, p_qmvalue: $p_qmvalue, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Displays 2010 Census and ACS demographics by Facility ID
#
# GET /dfr_rest_services.get_demographics_by_id
# Returns: record<Results: record<Demographics: record<Adults: string, AfricanAmerican: string, AmericanIndian: string, AsianPacificIslander: string, BSBA: string, CenterLatitude: string, CenterLongitude: string, Child: string, Grades9to12: string, HSDiploma: string, HispanicOrigin: string, Households: string, HouseholdsPublicAssistance: string, HousingUnits: string, Income15to25k: string, Income25to50k: string, Income50to75k: string, Income75kPlus: string, IncomeLess15k: string, LandArea: string, Less9thGrade: string, Minors: string, OtherMultiracial: string, PercentMinority: string, PersonsBelowPovertyLevel: string, PopulationDensity: string, Radius: string, Seniors: string, SomeCollege: string, TotalPersons: string, WaterArea: string, White: string>, Message: string>>
export def "get-dfr-rest-services-get-demographics-by-id" [
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
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID). (required)
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dfr_rest_services.get_demographics_by_id"
    query: [{name: output, var: output}, {name: p_id, var: p_id, required: true}, {name: callback, var: callback}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Displays 2010 Census and ACS demographics by Facility ID
#
# POST /dfr_rest_services.get_demographics_by_id
# Returns: record<Results: record<Demographics: record<Adults: string, AfricanAmerican: string, AmericanIndian: string, AsianPacificIslander: string, BSBA: string, CenterLatitude: string, CenterLongitude: string, Child: string, Grades9to12: string, HSDiploma: string, HispanicOrigin: string, Households: string, HouseholdsPublicAssistance: string, HousingUnits: string, Income15to25k: string, Income25to50k: string, Income50to75k: string, Income75kPlus: string, IncomeLess15k: string, LandArea: string, Less9thGrade: string, Minors: string, OtherMultiracial: string, PercentMinority: string, PersonsBelowPovertyLevel: string, PopulationDensity: string, Radius: string, Seniors: string, SomeCollege: string, TotalPersons: string, WaterArea: string, White: string>, Message: string>>
export def "post-dfr-rest-services-get-demographics-by-id" [
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
  p_id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/dfr_rest_services.get_demographics_by_id"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: p_id, var: p_id}, {name: callback, var: callback}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Detailed Facility Report Service
#
# GET /dfr_rest_services.get_dfr
# Returns: record<Results: record<AirCompliance: record<Header: record, Sources: list>, AirQuality: record<CarbonMonoxide1971Area: string, Lead1978Area: string, Lead2008Area: string, NitrogenDioxide1971Area: string, Ozone8hr1997Area: string, Ozone8hr2008Area: string, Ozone8hr2015Area: string, ParticulateMatter1987Area: string, ParticulateMatter1997Area: string, ParticulateMatter2006Area: string, ParticulateMatter2012Area: string, SulfurDioxide1971Area: string, SulfurDioxide2010Area: string>, CAEDDocuments: list<record>, CWA3YrCompliance: record<Header: record, Sources: list>, CWA3YrD80D90Counts: record<Header: record, Sources: list>, CWACSCompliance: record<Header: record, Sources: list>, CWAEffluentALRExceedences: record<Header: record, Sources: list>, CWAEffluentALRExceedencesEXP: record<Header: record, Sources: list>, CWAEffluentCompliance: record<Header: record, Sources: list>, CWAEffluentComplianceEXP: record<Header: record, Sources: list>, CWAPSCompliance: record<Header: record, Sources: list>, CWARNCCompliance: record<Header: record, Sources: list>, CWASECompliance: record<Header: record, Sources: list>, CaseFormalActions: record<Action: list, ProgramDates: list>, ComplianceHistory: record<Inspection: list, ProgramDates: list>, ComplianceSummary: record<ProgramDates: list, Source: list>, Demographics: record<Adults: string, AfricanAmerican: string, AmericanIndian: string, AsianPacificIslander: string, BSBA: string, CenterLatitude: string, CenterLongitude: string, Child: string, Grades9to12: string, HSDiploma: string, HispanicOrigin: string, Households: string, HouseholdsPublicAssistance: string, HousingUnits: string, Income15to25k: string, Income25to50k: string, Income50to75k: string, Income75kPlus: string, IncomeLess15k: string, LandArea: string, Less9thGrade: string, Minors: string, OtherMultiracial: string, PercentMinority: string, PersonsBelowPovertyLevel: string, PopulationDensity: string, Radius: string, Seniors: string, SomeCollege: string, TotalPersons: string, WaterArea: string, White: string>, EJScreenIndexes: record<HazardWasteProximity: string, LeadPaintIndicator: string, NATACancerRisk: string, NATADieselPM: string, NATARespiratoryHI: string, Over80Count: string, Ozone: string, PM25: string, RMPProximity: string, RegistryID: string, SuperfundProximity: string, TrafficProximity: string, WaterDischargeProximity: string>, EnforcementComplianceSummaries: record<ProgramDates: list, Summaries: list>, FormalActions: record<Action: list, ProgramDates: list>, ICISFormalActions: record<Action: list, ProgramDates: list>, InspectionEnforcementSummary: record<ProgramDates: list, Source: list>, LeadAndCopperRule5Yr: record<CopperSamples: list, CuALE: string, CuALEUnits: string, CuALEValue: string, CuSampleDates: string, CuViol: string, LeadAndCopperViol: string, LeadCopperRuleHealthBasedViol: string, LeadSamples: list, PbALE: string, PbALEUnits: string, PbALEValue: string, PbSampleDates: string, PbViol: string, RuleCode350Viol: string, SourceID: string, iCU90: string, iPB90: string>, MapOutput: record<CenterLatitude: string, CenterLongitude: string, IconBaseURL: string, MapData: list, PopUpBaseURL: string>, Message: string, MultipleFRSFacilities: record<RegistryIDs: list>, NAICS: record<Sources: list>, Notices: record<Notice: list, ProgramDates: list>, Permits: list<record>, RCRACompliance: record<Mnth10End: string, Mnth10Start: string, Mnth11End: string, Mnth11Start: string, Mnth12End: string, Mnth12Start: string, Mnth13End: string, Mnth13Start: string, Mnth14End: string, Mnth14Start: string, Mnth15End: string, Mnth15Start: string, Mnth16End: string, Mnth16Start: string, Mnth17End: string, Mnth17Start: string, Mnth18End: string, Mnth18Start: string, Mnth19End: string, Mnth19Start: string, Mnth1End: string, Mnth1Start: string, Mnth20End: string, Mnth20Start: string, Mnth21End: string, Mnth21Start: string, Mnth22End: string, Mnth22Start: string, Mnth23End: string, Mnth23Start: string, Mnth24End: string, Mnth24Start: string, Mnth25End: string, Mnth25Start: string, Mnth26End: string, Mnth26Start: string, Mnth27End: string, Mnth27Start: string, Mnth28End: string, Mnth28Start: string, Mnth29End: string, Mnth29Start: string, Mnth2End: string, Mnth2Start: string, Mnth30End: string, Mnth30Start: string, Mnth31End: string, Mnth31Start: string, Mnth32End: string, Mnth32Start: string, Mnth33End: string, Mnth33Start: string, Mnth34End: string, Mnth34Start: string, Mnth35End: string, Mnth35Start: string, Mnth36End: string, Mnth36Start: string, Mnth3End: string, Mnth3Start: string, Mnth4End: string, Mnth4Start: string, Mnth5End: string, Mnth5Start: string, Mnth6End: string, Mnth6Start: string, Mnth7End: string, Mnth7Start: string, Mnth8End: string, Mnth8Start: string, Mnth9End: string, Mnth9Start: string, Qtr10End: string, Qtr10Start: string, Qtr11End: string, Qtr11Start: string, Qtr12End: string, Qtr12Start: string, Qtr1End: string, Qtr1Start: string, Qtr2End: string, Qtr2Start: string, Qtr3End: string, Qtr3Start: string, Qtr4End: string, Qtr4Start: string, Qtr5End: string, Qtr5Start: string, Qtr6End: string, Qtr6Start: string, Qtr7End: string, Qtr7Start: string, Qtr8End: string, Qtr8Start: string, Qtr9End: string, Qtr9Start: string, Sources: list>, Reports: record<HasPollRpt: string>, SDWISCompliance: record<Mnth10End: string, Mnth10Start: string, Mnth11End: string, Mnth11Start: string, Mnth12End: string, Mnth12Start: string, Mnth13End: string, Mnth13Start: string, Mnth14End: string, Mnth14Start: string, Mnth15End: string, Mnth15Start: string, Mnth16End: string, Mnth16Start: string, Mnth17End: string, Mnth17Start: string, Mnth18End: string, Mnth18Start: string, Mnth19End: string, Mnth19Start: string, Mnth1End: string, Mnth1Start: string, Mnth20End: string, Mnth20Start: string, Mnth21End: string, Mnth21Start: string, Mnth22End: string, Mnth22Start: string, Mnth23End: string, Mnth23Start: string, Mnth24End: string, Mnth24Start: string, Mnth25End: string, Mnth25Start: string, Mnth26End: string, Mnth26Start: string, Mnth27End: string, Mnth27Start: string, Mnth28End: string, Mnth28Start: string, Mnth29End: string, Mnth29Start: string, Mnth2End: string, Mnth2Start: string, Mnth30End: string, Mnth30Start: string, Mnth31End: string, Mnth31Start: string, Mnth32End: string, Mnth32Start: string, Mnth33End: string, Mnth33Start: string, Mnth34End: string, Mnth34Start: string, Mnth35End: string, Mnth35Start: string, Mnth36End: string, Mnth36Start: string, Mnth37End: string, Mnth37Start: string, Mnth38End: string, Mnth38Start: string, Mnth39End: string, Mnth39Start: string, Mnth3End: string, Mnth3Start: string, Mnth4End: string, Mnth4Start: string, Mnth5End: string, Mnth5Start: string, Mnth6End: string, Mnth6Start: string, Mnth7End: string, Mnth7Start: string, Mnth8End: string, Mnth8Start: string, Mnth9End: string, Mnth9Start: string, Qtr10End: string, Qtr10Start: string, Qtr11End: string, Qtr11Start: string, Qtr12End: string, Qtr12Start: string, Qtr13End: string, Qtr13Start: string, Qtr1End: string, Qtr1Start: string, Qtr2End: string, Qtr2Start: string, Qtr3End: string, Qtr3Start: string, Qtr4End: string, Qtr4Start: string, Qtr5End: string, Qtr5Start: string, Qtr6End: string, Qtr6Start: string, Qtr7End: string, Qtr7Start: string, Qtr8End: string, Qtr8Start: string, Qtr9End: string, Qtr9Start: string, Sources: list>, SIC: record<Sources: list>, SanitarySurveys: record<Sources: list>, SiteVisits: record<Sources: list>, SpatialMetadata: record<CalculatedAccuracy: string, CollectionMethod: string, CoordinateSourceSystem: string, CoordinateSourceSystemId: string, Latitude83: string, Longitude83: string, ReferencePoint: string, RegistryID: string>, SystemExtractDates: record<Dates: list>, TRIHistory: record<Sources: list>, TRIReleases: record<Chemicals: list, Header: list>, Tribes: list<record>, ViolationsEnforcementActions: record<Sources: list>, WaterQuality: record<Sources: list>, WaterQualityDetails: record<Sources: list>, WebFireDocuments: list<record>>>
export def "get-dfr-rest-services-get-dfr" [
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
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID). (required)
  --p-system: string # System Acronym Filter. Enter a single system acronym to filter results.
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dfr_rest_services.get_dfr"
    query: [{name: output, var: output}, {name: p_id, var: p_id, required: true}, {name: p_system, var: p_system}, {name: callback, var: callback}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, p_system: $p_system, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Detailed Facility Report Service
#
# POST /dfr_rest_services.get_dfr
# Returns: record<Results: record<AirCompliance: record<Header: record, Sources: list>, AirQuality: record<CarbonMonoxide1971Area: string, Lead1978Area: string, Lead2008Area: string, NitrogenDioxide1971Area: string, Ozone8hr1997Area: string, Ozone8hr2008Area: string, Ozone8hr2015Area: string, ParticulateMatter1987Area: string, ParticulateMatter1997Area: string, ParticulateMatter2006Area: string, ParticulateMatter2012Area: string, SulfurDioxide1971Area: string, SulfurDioxide2010Area: string>, CAEDDocuments: list<record>, CWA3YrCompliance: record<Header: record, Sources: list>, CWA3YrD80D90Counts: record<Header: record, Sources: list>, CWACSCompliance: record<Header: record, Sources: list>, CWAEffluentALRExceedences: record<Header: record, Sources: list>, CWAEffluentALRExceedencesEXP: record<Header: record, Sources: list>, CWAEffluentCompliance: record<Header: record, Sources: list>, CWAEffluentComplianceEXP: record<Header: record, Sources: list>, CWAPSCompliance: record<Header: record, Sources: list>, CWARNCCompliance: record<Header: record, Sources: list>, CWASECompliance: record<Header: record, Sources: list>, CaseFormalActions: record<Action: list, ProgramDates: list>, ComplianceHistory: record<Inspection: list, ProgramDates: list>, ComplianceSummary: record<ProgramDates: list, Source: list>, Demographics: record<Adults: string, AfricanAmerican: string, AmericanIndian: string, AsianPacificIslander: string, BSBA: string, CenterLatitude: string, CenterLongitude: string, Child: string, Grades9to12: string, HSDiploma: string, HispanicOrigin: string, Households: string, HouseholdsPublicAssistance: string, HousingUnits: string, Income15to25k: string, Income25to50k: string, Income50to75k: string, Income75kPlus: string, IncomeLess15k: string, LandArea: string, Less9thGrade: string, Minors: string, OtherMultiracial: string, PercentMinority: string, PersonsBelowPovertyLevel: string, PopulationDensity: string, Radius: string, Seniors: string, SomeCollege: string, TotalPersons: string, WaterArea: string, White: string>, EJScreenIndexes: record<HazardWasteProximity: string, LeadPaintIndicator: string, NATACancerRisk: string, NATADieselPM: string, NATARespiratoryHI: string, Over80Count: string, Ozone: string, PM25: string, RMPProximity: string, RegistryID: string, SuperfundProximity: string, TrafficProximity: string, WaterDischargeProximity: string>, EnforcementComplianceSummaries: record<ProgramDates: list, Summaries: list>, FormalActions: record<Action: list, ProgramDates: list>, ICISFormalActions: record<Action: list, ProgramDates: list>, InspectionEnforcementSummary: record<ProgramDates: list, Source: list>, LeadAndCopperRule5Yr: record<CopperSamples: list, CuALE: string, CuALEUnits: string, CuALEValue: string, CuSampleDates: string, CuViol: string, LeadAndCopperViol: string, LeadCopperRuleHealthBasedViol: string, LeadSamples: list, PbALE: string, PbALEUnits: string, PbALEValue: string, PbSampleDates: string, PbViol: string, RuleCode350Viol: string, SourceID: string, iCU90: string, iPB90: string>, MapOutput: record<CenterLatitude: string, CenterLongitude: string, IconBaseURL: string, MapData: list, PopUpBaseURL: string>, Message: string, MultipleFRSFacilities: record<RegistryIDs: list>, NAICS: record<Sources: list>, Notices: record<Notice: list, ProgramDates: list>, Permits: list<record>, RCRACompliance: record<Mnth10End: string, Mnth10Start: string, Mnth11End: string, Mnth11Start: string, Mnth12End: string, Mnth12Start: string, Mnth13End: string, Mnth13Start: string, Mnth14End: string, Mnth14Start: string, Mnth15End: string, Mnth15Start: string, Mnth16End: string, Mnth16Start: string, Mnth17End: string, Mnth17Start: string, Mnth18End: string, Mnth18Start: string, Mnth19End: string, Mnth19Start: string, Mnth1End: string, Mnth1Start: string, Mnth20End: string, Mnth20Start: string, Mnth21End: string, Mnth21Start: string, Mnth22End: string, Mnth22Start: string, Mnth23End: string, Mnth23Start: string, Mnth24End: string, Mnth24Start: string, Mnth25End: string, Mnth25Start: string, Mnth26End: string, Mnth26Start: string, Mnth27End: string, Mnth27Start: string, Mnth28End: string, Mnth28Start: string, Mnth29End: string, Mnth29Start: string, Mnth2End: string, Mnth2Start: string, Mnth30End: string, Mnth30Start: string, Mnth31End: string, Mnth31Start: string, Mnth32End: string, Mnth32Start: string, Mnth33End: string, Mnth33Start: string, Mnth34End: string, Mnth34Start: string, Mnth35End: string, Mnth35Start: string, Mnth36End: string, Mnth36Start: string, Mnth3End: string, Mnth3Start: string, Mnth4End: string, Mnth4Start: string, Mnth5End: string, Mnth5Start: string, Mnth6End: string, Mnth6Start: string, Mnth7End: string, Mnth7Start: string, Mnth8End: string, Mnth8Start: string, Mnth9End: string, Mnth9Start: string, Qtr10End: string, Qtr10Start: string, Qtr11End: string, Qtr11Start: string, Qtr12End: string, Qtr12Start: string, Qtr1End: string, Qtr1Start: string, Qtr2End: string, Qtr2Start: string, Qtr3End: string, Qtr3Start: string, Qtr4End: string, Qtr4Start: string, Qtr5End: string, Qtr5Start: string, Qtr6End: string, Qtr6Start: string, Qtr7End: string, Qtr7Start: string, Qtr8End: string, Qtr8Start: string, Qtr9End: string, Qtr9Start: string, Sources: list>, Reports: record<HasPollRpt: string>, SDWISCompliance: record<Mnth10End: string, Mnth10Start: string, Mnth11End: string, Mnth11Start: string, Mnth12End: string, Mnth12Start: string, Mnth13End: string, Mnth13Start: string, Mnth14End: string, Mnth14Start: string, Mnth15End: string, Mnth15Start: string, Mnth16End: string, Mnth16Start: string, Mnth17End: string, Mnth17Start: string, Mnth18End: string, Mnth18Start: string, Mnth19End: string, Mnth19Start: string, Mnth1End: string, Mnth1Start: string, Mnth20End: string, Mnth20Start: string, Mnth21End: string, Mnth21Start: string, Mnth22End: string, Mnth22Start: string, Mnth23End: string, Mnth23Start: string, Mnth24End: string, Mnth24Start: string, Mnth25End: string, Mnth25Start: string, Mnth26End: string, Mnth26Start: string, Mnth27End: string, Mnth27Start: string, Mnth28End: string, Mnth28Start: string, Mnth29End: string, Mnth29Start: string, Mnth2End: string, Mnth2Start: string, Mnth30End: string, Mnth30Start: string, Mnth31End: string, Mnth31Start: string, Mnth32End: string, Mnth32Start: string, Mnth33End: string, Mnth33Start: string, Mnth34End: string, Mnth34Start: string, Mnth35End: string, Mnth35Start: string, Mnth36End: string, Mnth36Start: string, Mnth37End: string, Mnth37Start: string, Mnth38End: string, Mnth38Start: string, Mnth39End: string, Mnth39Start: string, Mnth3End: string, Mnth3Start: string, Mnth4End: string, Mnth4Start: string, Mnth5End: string, Mnth5Start: string, Mnth6End: string, Mnth6Start: string, Mnth7End: string, Mnth7Start: string, Mnth8End: string, Mnth8Start: string, Mnth9End: string, Mnth9Start: string, Qtr10End: string, Qtr10Start: string, Qtr11End: string, Qtr11Start: string, Qtr12End: string, Qtr12Start: string, Qtr13End: string, Qtr13Start: string, Qtr1End: string, Qtr1Start: string, Qtr2End: string, Qtr2Start: string, Qtr3End: string, Qtr3Start: string, Qtr4End: string, Qtr4Start: string, Qtr5End: string, Qtr5Start: string, Qtr6End: string, Qtr6Start: string, Qtr7End: string, Qtr7Start: string, Qtr8End: string, Qtr8Start: string, Qtr9End: string, Qtr9Start: string, Sources: list>, SIC: record<Sources: list>, SanitarySurveys: record<Sources: list>, SiteVisits: record<Sources: list>, SpatialMetadata: record<CalculatedAccuracy: string, CollectionMethod: string, CoordinateSourceSystem: string, CoordinateSourceSystemId: string, Latitude83: string, Longitude83: string, ReferencePoint: string, RegistryID: string>, SystemExtractDates: record<Dates: list>, TRIHistory: record<Sources: list>, TRIReleases: record<Chemicals: list, Header: list>, Tribes: list<record>, ViolationsEnforcementActions: record<Sources: list>, WaterQuality: record<Sources: list>, WaterQualityDetails: record<Sources: list>, WebFireDocuments: list<record>>>
export def "post-dfr-rest-services-get-dfr" [
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
  p_id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --p-system: string # System Acronym Filter. Enter a single system acronym to filter results.
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/dfr_rest_services.get_dfr"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: p_id, var: p_id}, {name: p_system, var: p_system}, {name: callback, var: callback}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, p_system: $p_system, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Detailed Facility Report EJScreen Indexes Service
#
# GET /dfr_rest_services.get_ejscreen_indexes
# Returns: record<Results: record<EJScreenIndexes: record<HazardWasteProximity: string, LeadPaintIndicator: string, NATACancerRisk: string, NATADieselPM: string, NATARespiratoryHI: string, Over80Count: string, Ozone: string, PM25: string, RMPProximity: string, RegistryID: string, SuperfundProximity: string, TrafficProximity: string, WaterDischargeProximity: string>, Message: string>>
export def "get-dfr-rest-services-get-ejscreen-indexes" [
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
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID). (required)
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dfr_rest_services.get_ejscreen_indexes"
    query: [{name: output, var: output}, {name: p_id, var: p_id, required: true}, {name: callback, var: callback}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Detailed Facility Report EJScreen Indexes Service
#
# POST /dfr_rest_services.get_ejscreen_indexes
# Returns: record<Results: record<EJScreenIndexes: record<HazardWasteProximity: string, LeadPaintIndicator: string, NATACancerRisk: string, NATADieselPM: string, NATARespiratoryHI: string, Over80Count: string, Ozone: string, PM25: string, RMPProximity: string, RegistryID: string, SuperfundProximity: string, TrafficProximity: string, WaterDischargeProximity: string>, Message: string>>
export def "post-dfr-rest-services-get-ejscreen-indexes" [
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
  p_id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/dfr_rest_services.get_ejscreen_indexes"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: p_id, var: p_id}, {name: callback, var: callback}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Detailed Facility Report Enforcement Summary Service
#
# GET /dfr_rest_services.get_enforcement_summary
# Returns: record<Results: record<EnforcementComplianceSummaries: record<ProgramDates: list, Summaries: list>, Message: string>>
export def "get-dfr-rest-services-get-enforcement-summary" [
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
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID). (required)
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dfr_rest_services.get_enforcement_summary"
    query: [{name: output, var: output}, {name: p_id, var: p_id, required: true}, {name: callback, var: callback}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Detailed Facility Report Enforcement Summary Service
#
# POST /dfr_rest_services.get_enforcement_summary
# Returns: record<Results: record<EnforcementComplianceSummaries: record<ProgramDates: list, Summaries: list>, Message: string>>
export def "post-dfr-rest-services-get-enforcement-summary" [
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
  p_id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/dfr_rest_services.get_enforcement_summary"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: p_id, var: p_id}, {name: callback, var: callback}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Displays the dates that data was extracted from native EPA systems for the DFR.
#
# GET /dfr_rest_services.get_extract_dates
# Returns: record<Results: record<Message: string, SystemExtractDates: record<Dates: list>>>
export def "get-dfr-rest-services-get-extract-dates" [
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
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID). (required)
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dfr_rest_services.get_extract_dates"
    query: [{name: output, var: output}, {name: p_id, var: p_id, required: true}, {name: callback, var: callback}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Displays the dates that data was extracted from native EPA systems for the DFR.
#
# POST /dfr_rest_services.get_extract_dates
# Returns: record<Results: record<Message: string, SystemExtractDates: record<Dates: list>>>
export def "post-dfr-rest-services-get-extract-dates" [
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
  p_id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/dfr_rest_services.get_extract_dates"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: p_id, var: p_id}, {name: callback, var: callback}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Detailed Facility Report Formal Actions Service
#
# GET /dfr_rest_services.get_formal_actions
# Returns: record<Results: record<FormalActions: record<Action: list, ProgramDates: list>, Message: string>>
export def "get-dfr-rest-services-get-formal-actions" [
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
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID). (required)
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dfr_rest_services.get_formal_actions"
    query: [{name: output, var: output}, {name: p_id, var: p_id, required: true}, {name: callback, var: callback}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Detailed Facility Report Formal Actions Service
#
# POST /dfr_rest_services.get_formal_actions
# Returns: record<Results: record<FormalActions: record<Action: list, ProgramDates: list>, Message: string>>
export def "post-dfr-rest-services-get-formal-actions" [
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
  p_id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/dfr_rest_services.get_formal_actions"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: p_id, var: p_id}, {name: callback, var: callback}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Detailed Facility Report ICIS Formal Actions Service
#
# GET /dfr_rest_services.get_icis_formal_actions
# Returns: record<Results: record<ICISFormalActions: record<Action: list, ProgramDates: list>, Message: string>>
export def "get-dfr-rest-services-get-icis-formal-actions" [
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
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID). (required)
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dfr_rest_services.get_icis_formal_actions"
    query: [{name: output, var: output}, {name: p_id, var: p_id, required: true}, {name: callback, var: callback}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Detailed Facility Report ICIS Formal Actions Service
#
# POST /dfr_rest_services.get_icis_formal_actions
# Returns: record<Results: record<ICISFormalActions: record<Action: list, ProgramDates: list>, Message: string>>
export def "post-dfr-rest-services-get-icis-formal-actions" [
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
  p_id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/dfr_rest_services.get_icis_formal_actions"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: p_id, var: p_id}, {name: callback, var: callback}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Detailed Facility Report Inspections Summary Service
#
# GET /dfr_rest_services.get_inspections
# Returns: record<Results: record<InspectionEnforcementSummary: record<ProgramDates: list, Source: list>, Message: string>>
export def "get-dfr-rest-services-get-inspections" [
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
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID). (required)
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dfr_rest_services.get_inspections"
    query: [{name: output, var: output}, {name: p_id, var: p_id, required: true}, {name: callback, var: callback}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Detailed Facility Report Inspections Summary Service
#
# POST /dfr_rest_services.get_inspections
# Returns: record<Results: record<InspectionEnforcementSummary: record<ProgramDates: list, Source: list>, Message: string>>
export def "post-dfr-rest-services-get-inspections" [
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
  p_id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/dfr_rest_services.get_inspections"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: p_id, var: p_id}, {name: callback, var: callback}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Detailed Facility Report Map Service
#
# GET /dfr_rest_services.get_map
# Returns: record<Results: record<MapOutput: record<CenterLatitude: string, CenterLongitude: string, IconBaseURL: string, MapData: list, PopUpBaseURL: string>, Message: string>>
export def "get-dfr-rest-services-get-map" [
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
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID). (required)
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dfr_rest_services.get_map"
    query: [{name: output, var: output}, {name: p_id, var: p_id, required: true}, {name: callback, var: callback}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Detailed Facility Report Map Service
#
# POST /dfr_rest_services.get_map
# Returns: record<Results: record<MapOutput: record<CenterLatitude: string, CenterLongitude: string, IconBaseURL: string, MapData: list, PopUpBaseURL: string>, Message: string>>
export def "post-dfr-rest-services-get-map" [
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
  p_id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/dfr_rest_services.get_map"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: p_id, var: p_id}, {name: callback, var: callback}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Detailed Facility Report NAICS Code Service
#
# GET /dfr_rest_services.get_naics
# Returns: record<Results: record<Message: string, NAICS: record<Sources: list>>>
export def "get-dfr-rest-services-get-naics" [
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
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID). (required)
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dfr_rest_services.get_naics"
    query: [{name: output, var: output}, {name: p_id, var: p_id, required: true}, {name: callback, var: callback}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Detailed Facility Report NAICS Code Service
#
# POST /dfr_rest_services.get_naics
# Returns: record<Results: record<Message: string, NAICS: record<Sources: list>>>
export def "post-dfr-rest-services-get-naics" [
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
  p_id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/dfr_rest_services.get_naics"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: p_id, var: p_id}, {name: callback, var: callback}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Detailed Facility Report Notices Service
#
# GET /dfr_rest_services.get_notices
# Returns: record<Results: record<Message: string, Notices: record<Notice: list, ProgramDates: list>>>
export def "get-dfr-rest-services-get-notices" [
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
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID). (required)
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dfr_rest_services.get_notices"
    query: [{name: output, var: output}, {name: p_id, var: p_id, required: true}, {name: callback, var: callback}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Detailed Facility Report Notices Service
#
# POST /dfr_rest_services.get_notices
# Returns: record<Results: record<Message: string, Notices: record<Notice: list, ProgramDates: list>>>
export def "post-dfr-rest-services-get-notices" [
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
  p_id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/dfr_rest_services.get_notices"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: p_id, var: p_id}, {name: callback, var: callback}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Detailed Facility Report Permits Service
#
# GET /dfr_rest_services.get_permits
# Returns: record<Results: record<Message: string, Permits: list<record>, Reports: record<HasPollRpt: string>>>
export def "get-dfr-rest-services-get-permits" [
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
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID). (required)
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dfr_rest_services.get_permits"
    query: [{name: output, var: output}, {name: p_id, var: p_id, required: true}, {name: callback, var: callback}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Detailed Facility Report Permits Service
#
# POST /dfr_rest_services.get_permits
# Returns: record<Results: record<Message: string, Permits: list<record>, Reports: record<HasPollRpt: string>>>
export def "post-dfr-rest-services-get-permits" [
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
  p_id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/dfr_rest_services.get_permits"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: p_id, var: p_id}, {name: callback, var: callback}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Detailed Facility Report RCRA Compliance Service
#
# GET /dfr_rest_services.get_rcra_compliance
# Returns: record<Results: record<Message: string, RCRACompliance: record<Mnth10End: string, Mnth10Start: string, Mnth11End: string, Mnth11Start: string, Mnth12End: string, Mnth12Start: string, Mnth13End: string, Mnth13Start: string, Mnth14End: string, Mnth14Start: string, Mnth15End: string, Mnth15Start: string, Mnth16End: string, Mnth16Start: string, Mnth17End: string, Mnth17Start: string, Mnth18End: string, Mnth18Start: string, Mnth19End: string, Mnth19Start: string, Mnth1End: string, Mnth1Start: string, Mnth20End: string, Mnth20Start: string, Mnth21End: string, Mnth21Start: string, Mnth22End: string, Mnth22Start: string, Mnth23End: string, Mnth23Start: string, Mnth24End: string, Mnth24Start: string, Mnth25End: string, Mnth25Start: string, Mnth26End: string, Mnth26Start: string, Mnth27End: string, Mnth27Start: string, Mnth28End: string, Mnth28Start: string, Mnth29End: string, Mnth29Start: string, Mnth2End: string, Mnth2Start: string, Mnth30End: string, Mnth30Start: string, Mnth31End: string, Mnth31Start: string, Mnth32End: string, Mnth32Start: string, Mnth33End: string, Mnth33Start: string, Mnth34End: string, Mnth34Start: string, Mnth35End: string, Mnth35Start: string, Mnth36End: string, Mnth36Start: string, Mnth3End: string, Mnth3Start: string, Mnth4End: string, Mnth4Start: string, Mnth5End: string, Mnth5Start: string, Mnth6End: string, Mnth6Start: string, Mnth7End: string, Mnth7Start: string, Mnth8End: string, Mnth8Start: string, Mnth9End: string, Mnth9Start: string, Qtr10End: string, Qtr10Start: string, Qtr11End: string, Qtr11Start: string, Qtr12End: string, Qtr12Start: string, Qtr1End: string, Qtr1Start: string, Qtr2End: string, Qtr2Start: string, Qtr3End: string, Qtr3Start: string, Qtr4End: string, Qtr4Start: string, Qtr5End: string, Qtr5Start: string, Qtr6End: string, Qtr6Start: string, Qtr7End: string, Qtr7Start: string, Qtr8End: string, Qtr8Start: string, Qtr9End: string, Qtr9Start: string, Sources: list>>>
export def "get-dfr-rest-services-get-rcra-compliance" [
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
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID). (required)
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dfr_rest_services.get_rcra_compliance"
    query: [{name: output, var: output}, {name: p_id, var: p_id, required: true}, {name: callback, var: callback}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Detailed Facility Report RCRA Compliance Service
#
# POST /dfr_rest_services.get_rcra_compliance
# Returns: record<Results: record<Message: string, RCRACompliance: record<Mnth10End: string, Mnth10Start: string, Mnth11End: string, Mnth11Start: string, Mnth12End: string, Mnth12Start: string, Mnth13End: string, Mnth13Start: string, Mnth14End: string, Mnth14Start: string, Mnth15End: string, Mnth15Start: string, Mnth16End: string, Mnth16Start: string, Mnth17End: string, Mnth17Start: string, Mnth18End: string, Mnth18Start: string, Mnth19End: string, Mnth19Start: string, Mnth1End: string, Mnth1Start: string, Mnth20End: string, Mnth20Start: string, Mnth21End: string, Mnth21Start: string, Mnth22End: string, Mnth22Start: string, Mnth23End: string, Mnth23Start: string, Mnth24End: string, Mnth24Start: string, Mnth25End: string, Mnth25Start: string, Mnth26End: string, Mnth26Start: string, Mnth27End: string, Mnth27Start: string, Mnth28End: string, Mnth28Start: string, Mnth29End: string, Mnth29Start: string, Mnth2End: string, Mnth2Start: string, Mnth30End: string, Mnth30Start: string, Mnth31End: string, Mnth31Start: string, Mnth32End: string, Mnth32Start: string, Mnth33End: string, Mnth33Start: string, Mnth34End: string, Mnth34Start: string, Mnth35End: string, Mnth35Start: string, Mnth36End: string, Mnth36Start: string, Mnth3End: string, Mnth3Start: string, Mnth4End: string, Mnth4Start: string, Mnth5End: string, Mnth5Start: string, Mnth6End: string, Mnth6Start: string, Mnth7End: string, Mnth7Start: string, Mnth8End: string, Mnth8Start: string, Mnth9End: string, Mnth9Start: string, Qtr10End: string, Qtr10Start: string, Qtr11End: string, Qtr11Start: string, Qtr12End: string, Qtr12Start: string, Qtr1End: string, Qtr1Start: string, Qtr2End: string, Qtr2Start: string, Qtr3End: string, Qtr3Start: string, Qtr4End: string, Qtr4Start: string, Qtr5End: string, Qtr5Start: string, Qtr6End: string, Qtr6Start: string, Qtr7End: string, Qtr7Start: string, Qtr8End: string, Qtr8Start: string, Qtr9End: string, Qtr9Start: string, Sources: list>>>
export def "post-dfr-rest-services-get-rcra-compliance" [
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
  p_id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/dfr_rest_services.get_rcra_compliance"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: p_id, var: p_id}, {name: callback, var: callback}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Detailed Facility Report SDWA Lead and Copper Service
#
# GET /dfr_rest_services.get_sdwa_lead_and_copper
# Returns: record<Results: record<LeadAndCopperRule5Yr: record<CopperSamples: list, CuALE: string, CuALEUnits: string, CuALEValue: string, CuSampleDates: string, CuViol: string, LeadAndCopperViol: string, LeadCopperRuleHealthBasedViol: string, LeadSamples: list, PbALE: string, PbALEUnits: string, PbALEValue: string, PbSampleDates: string, PbViol: string, RuleCode350Viol: string, SourceID: string, iCU90: string, iPB90: string>, Message: string>>
export def "get-dfr-rest-services-get-sdwa-lead-and-copper" [
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
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID). (required)
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dfr_rest_services.get_sdwa_lead_and_copper"
    query: [{name: output, var: output}, {name: p_id, var: p_id, required: true}, {name: callback, var: callback}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Detailed Facility Report SDWA Lead and Copper Service
#
# POST /dfr_rest_services.get_sdwa_lead_and_copper
# Returns: record<Results: record<LeadAndCopperRule5Yr: record<CopperSamples: list, CuALE: string, CuALEUnits: string, CuALEValue: string, CuSampleDates: string, CuViol: string, LeadAndCopperViol: string, LeadCopperRuleHealthBasedViol: string, LeadSamples: list, PbALE: string, PbALEUnits: string, PbALEValue: string, PbSampleDates: string, PbViol: string, RuleCode350Viol: string, SourceID: string, iCU90: string, iPB90: string>, Message: string>>
export def "post-dfr-rest-services-get-sdwa-lead-and-copper" [
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
  p_id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/dfr_rest_services.get_sdwa_lead_and_copper"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: p_id, var: p_id}, {name: callback, var: callback}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Detailed Facility Report SDWA Sanitary Surveys Service
#
# GET /dfr_rest_services.get_sdwa_sanitary_surveys
# Returns: record<Results: record<Message: string, SanitarySurveys: record<Sources: list>>>
export def "get-dfr-rest-services-get-sdwa-sanitary-surveys" [
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
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID). (required)
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dfr_rest_services.get_sdwa_sanitary_surveys"
    query: [{name: output, var: output}, {name: p_id, var: p_id, required: true}, {name: callback, var: callback}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Detailed Facility Report SDWA Sanitary Surveys Service
#
# POST /dfr_rest_services.get_sdwa_sanitary_surveys
# Returns: record<Results: record<Message: string, SanitarySurveys: record<Sources: list>>>
export def "post-dfr-rest-services-get-sdwa-sanitary-surveys" [
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
  p_id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/dfr_rest_services.get_sdwa_sanitary_surveys"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: p_id, var: p_id}, {name: callback, var: callback}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Detailed Facility Report SDWA Sanitary Site Visits Service
#
# GET /dfr_rest_services.get_sdwa_site_visits
# Returns: record<Results: record<Message: string, SiteVisits: record<Sources: list>>>
export def "get-dfr-rest-services-get-sdwa-site-visits" [
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
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID). (required)
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dfr_rest_services.get_sdwa_site_visits"
    query: [{name: output, var: output}, {name: p_id, var: p_id, required: true}, {name: callback, var: callback}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Detailed Facility Report SDWA Sanitary Site Visits Service
#
# POST /dfr_rest_services.get_sdwa_site_visits
# Returns: record<Results: record<Message: string, SiteVisits: record<Sources: list>>>
export def "post-dfr-rest-services-get-sdwa-site-visits" [
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
  p_id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/dfr_rest_services.get_sdwa_site_visits"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: p_id, var: p_id}, {name: callback, var: callback}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Detailed Facility Report SDWA Violations Service
#
# GET /dfr_rest_services.get_sdwa_violations
# Returns: record<Results: record<Message: string, ViolationsEnforcementActions: record<Sources: list>>>
export def "get-dfr-rest-services-get-sdwa-violations" [
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
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID). (required)
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dfr_rest_services.get_sdwa_violations"
    query: [{name: output, var: output}, {name: p_id, var: p_id, required: true}, {name: callback, var: callback}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Detailed Facility Report SDWA Violations Service
#
# POST /dfr_rest_services.get_sdwa_violations
# Returns: record<Results: record<Message: string, ViolationsEnforcementActions: record<Sources: list>>>
export def "post-dfr-rest-services-get-sdwa-violations" [
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
  p_id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/dfr_rest_services.get_sdwa_violations"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: p_id, var: p_id}, {name: callback, var: callback}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Detailed Facility Report SDWIS Compliance Service
#
# GET /dfr_rest_services.get_sdwis_compliance
# Returns: record<Results: record<Message: string, SDWISCompliance: record<Mnth10End: string, Mnth10Start: string, Mnth11End: string, Mnth11Start: string, Mnth12End: string, Mnth12Start: string, Mnth13End: string, Mnth13Start: string, Mnth14End: string, Mnth14Start: string, Mnth15End: string, Mnth15Start: string, Mnth16End: string, Mnth16Start: string, Mnth17End: string, Mnth17Start: string, Mnth18End: string, Mnth18Start: string, Mnth19End: string, Mnth19Start: string, Mnth1End: string, Mnth1Start: string, Mnth20End: string, Mnth20Start: string, Mnth21End: string, Mnth21Start: string, Mnth22End: string, Mnth22Start: string, Mnth23End: string, Mnth23Start: string, Mnth24End: string, Mnth24Start: string, Mnth25End: string, Mnth25Start: string, Mnth26End: string, Mnth26Start: string, Mnth27End: string, Mnth27Start: string, Mnth28End: string, Mnth28Start: string, Mnth29End: string, Mnth29Start: string, Mnth2End: string, Mnth2Start: string, Mnth30End: string, Mnth30Start: string, Mnth31End: string, Mnth31Start: string, Mnth32End: string, Mnth32Start: string, Mnth33End: string, Mnth33Start: string, Mnth34End: string, Mnth34Start: string, Mnth35End: string, Mnth35Start: string, Mnth36End: string, Mnth36Start: string, Mnth37End: string, Mnth37Start: string, Mnth38End: string, Mnth38Start: string, Mnth39End: string, Mnth39Start: string, Mnth3End: string, Mnth3Start: string, Mnth4End: string, Mnth4Start: string, Mnth5End: string, Mnth5Start: string, Mnth6End: string, Mnth6Start: string, Mnth7End: string, Mnth7Start: string, Mnth8End: string, Mnth8Start: string, Mnth9End: string, Mnth9Start: string, Qtr10End: string, Qtr10Start: string, Qtr11End: string, Qtr11Start: string, Qtr12End: string, Qtr12Start: string, Qtr13End: string, Qtr13Start: string, Qtr1End: string, Qtr1Start: string, Qtr2End: string, Qtr2Start: string, Qtr3End: string, Qtr3Start: string, Qtr4End: string, Qtr4Start: string, Qtr5End: string, Qtr5Start: string, Qtr6End: string, Qtr6Start: string, Qtr7End: string, Qtr7Start: string, Qtr8End: string, Qtr8Start: string, Qtr9End: string, Qtr9Start: string, Sources: list>>>
export def "get-dfr-rest-services-get-sdwis-compliance" [
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
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID). (required)
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dfr_rest_services.get_sdwis_compliance"
    query: [{name: output, var: output}, {name: p_id, var: p_id, required: true}, {name: callback, var: callback}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Detailed Facility Report SDWIS Compliance Service
#
# POST /dfr_rest_services.get_sdwis_compliance
# Returns: record<Results: record<Message: string, SDWISCompliance: record<Mnth10End: string, Mnth10Start: string, Mnth11End: string, Mnth11Start: string, Mnth12End: string, Mnth12Start: string, Mnth13End: string, Mnth13Start: string, Mnth14End: string, Mnth14Start: string, Mnth15End: string, Mnth15Start: string, Mnth16End: string, Mnth16Start: string, Mnth17End: string, Mnth17Start: string, Mnth18End: string, Mnth18Start: string, Mnth19End: string, Mnth19Start: string, Mnth1End: string, Mnth1Start: string, Mnth20End: string, Mnth20Start: string, Mnth21End: string, Mnth21Start: string, Mnth22End: string, Mnth22Start: string, Mnth23End: string, Mnth23Start: string, Mnth24End: string, Mnth24Start: string, Mnth25End: string, Mnth25Start: string, Mnth26End: string, Mnth26Start: string, Mnth27End: string, Mnth27Start: string, Mnth28End: string, Mnth28Start: string, Mnth29End: string, Mnth29Start: string, Mnth2End: string, Mnth2Start: string, Mnth30End: string, Mnth30Start: string, Mnth31End: string, Mnth31Start: string, Mnth32End: string, Mnth32Start: string, Mnth33End: string, Mnth33Start: string, Mnth34End: string, Mnth34Start: string, Mnth35End: string, Mnth35Start: string, Mnth36End: string, Mnth36Start: string, Mnth37End: string, Mnth37Start: string, Mnth38End: string, Mnth38Start: string, Mnth39End: string, Mnth39Start: string, Mnth3End: string, Mnth3Start: string, Mnth4End: string, Mnth4Start: string, Mnth5End: string, Mnth5Start: string, Mnth6End: string, Mnth6Start: string, Mnth7End: string, Mnth7Start: string, Mnth8End: string, Mnth8Start: string, Mnth9End: string, Mnth9Start: string, Qtr10End: string, Qtr10Start: string, Qtr11End: string, Qtr11Start: string, Qtr12End: string, Qtr12Start: string, Qtr13End: string, Qtr13Start: string, Qtr1End: string, Qtr1Start: string, Qtr2End: string, Qtr2Start: string, Qtr3End: string, Qtr3Start: string, Qtr4End: string, Qtr4Start: string, Qtr5End: string, Qtr5Start: string, Qtr6End: string, Qtr6Start: string, Qtr7End: string, Qtr7Start: string, Qtr8End: string, Qtr8Start: string, Qtr9End: string, Qtr9Start: string, Sources: list>>>
export def "post-dfr-rest-services-get-sdwis-compliance" [
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
  p_id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/dfr_rest_services.get_sdwis_compliance"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: p_id, var: p_id}, {name: callback, var: callback}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Detailed Facility Report SIC Code Service
#
# GET /dfr_rest_services.get_sic_codes
# Returns: record<Results: record<Message: string, SIC: record<Sources: list>>>
export def "get-dfr-rest-services-get-sic-codes" [
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
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID). (required)
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dfr_rest_services.get_sic_codes"
    query: [{name: output, var: output}, {name: p_id, var: p_id, required: true}, {name: callback, var: callback}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Detailed Facility Report SIC Code Service
#
# POST /dfr_rest_services.get_sic_codes
# Returns: record<Results: record<Message: string, SIC: record<Sources: list>>>
export def "post-dfr-rest-services-get-sic-codes" [
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
  p_id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/dfr_rest_services.get_sic_codes"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: p_id, var: p_id}, {name: callback, var: callback}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Detailed Facility Report Spatial Metadata Service
#
# GET /dfr_rest_services.get_spatial_metadata
# Returns: record<Results: record<Message: string, SpatialMetadata: record<CalculatedAccuracy: string, CollectionMethod: string, CoordinateSourceSystem: string, CoordinateSourceSystemId: string, Latitude83: string, Longitude83: string, ReferencePoint: string, RegistryID: string>>>
export def "get-dfr-rest-services-get-spatial-metadata" [
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
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID). (required)
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dfr_rest_services.get_spatial_metadata"
    query: [{name: output, var: output}, {name: p_id, var: p_id, required: true}, {name: callback, var: callback}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Detailed Facility Report Spatial Metadata Service
#
# POST /dfr_rest_services.get_spatial_metadata
# Returns: record<Results: record<Message: string, SpatialMetadata: record<CalculatedAccuracy: string, CollectionMethod: string, CoordinateSourceSystem: string, CoordinateSourceSystemId: string, Latitude83: string, Longitude83: string, ReferencePoint: string, RegistryID: string>>>
export def "post-dfr-rest-services-get-spatial-metadata" [
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
  p_id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/dfr_rest_services.get_spatial_metadata"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: p_id, var: p_id}, {name: callback, var: callback}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Detailed Facility Report TRI History Service
#
# GET /dfr_rest_services.get_tri_history
# Returns: record<Results: record<Message: string, TRIHistory: record<Sources: list>>>
export def "get-dfr-rest-services-get-tri-history" [
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
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID). (required)
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dfr_rest_services.get_tri_history"
    query: [{name: output, var: output}, {name: p_id, var: p_id, required: true}, {name: callback, var: callback}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Detailed Facility Report TRI History Service
#
# POST /dfr_rest_services.get_tri_history
# Returns: record<Results: record<Message: string, TRIHistory: record<Sources: list>>>
export def "post-dfr-rest-services-get-tri-history" [
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
  p_id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/dfr_rest_services.get_tri_history"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: p_id, var: p_id}, {name: callback, var: callback}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Detailed Facility Report TRI Releases Service
#
# GET /dfr_rest_services.get_tri_releases
# Returns: record<Results: record<Message: string, TRIReleases: record<Chemicals: list, Header: list>>>
export def "get-dfr-rest-services-get-tri-releases" [
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
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID). (required)
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dfr_rest_services.get_tri_releases"
    query: [{name: output, var: output}, {name: p_id, var: p_id, required: true}, {name: callback, var: callback}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Detailed Facility Report TRI Releases Service
#
# POST /dfr_rest_services.get_tri_releases
# Returns: record<Results: record<Message: string, TRIReleases: record<Chemicals: list, Header: list>>>
export def "post-dfr-rest-services-get-tri-releases" [
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
  p_id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/dfr_rest_services.get_tri_releases"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: p_id, var: p_id}, {name: callback, var: callback}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Detailed Facility Report Tribes Service
#
# GET /dfr_rest_services.get_tribes
# Returns: record<Results: record<Message: string, Tribes: list<record>>>
export def "get-dfr-rest-services-get-tribes" [
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
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID). (required)
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dfr_rest_services.get_tribes"
    query: [{name: output, var: output}, {name: p_id, var: p_id, required: true}, {name: callback, var: callback}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Detailed Facility Report Tribes Service
#
# POST /dfr_rest_services.get_tribes
# Returns: record<Results: record<Message: string, Tribes: list<record>>>
export def "post-dfr-rest-services-get-tribes" [
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
  p_id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/dfr_rest_services.get_tribes"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: p_id, var: p_id}, {name: callback, var: callback}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Detailed Facility Report Water Quality Service
#
# GET /dfr_rest_services.get_water_quality
# Returns: record<Results: record<Message: string, WaterQuality: record<Sources: list>>>
export def "get-dfr-rest-services-get-water-quality" [
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
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID). (required)
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dfr_rest_services.get_water_quality"
    query: [{name: output, var: output}, {name: p_id, var: p_id, required: true}, {name: callback, var: callback}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Detailed Facility Report Water Quality Service
#
# POST /dfr_rest_services.get_water_quality
# Returns: record<Results: record<Message: string, WaterQuality: record<Sources: list>>>
export def "post-dfr-rest-services-get-water-quality" [
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
  p_id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/dfr_rest_services.get_water_quality"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: p_id, var: p_id}, {name: callback, var: callback}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Displays detailed Water Quality information from EPA's Office of Water Systems
#
# GET /dfr_rest_services.get_water_quality_details
# Returns: record<Results: record<Message: string, WaterQualityDetails: record<Sources: list>>>
export def "get-dfr-rest-services-get-water-quality-details" [
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
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID). (required)
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dfr_rest_services.get_water_quality_details"
    query: [{name: output, var: output}, {name: p_id, var: p_id, required: true}, {name: callback, var: callback}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Displays detailed Water Quality information from EPA's Office of Water Systems
#
# POST /dfr_rest_services.get_water_quality_details
# Returns: record<Results: record<Message: string, WaterQualityDetails: record<Sources: list>>>
export def "post-dfr-rest-services-get-water-quality-details" [
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
  p_id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/dfr_rest_services.get_water_quality_details"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: p_id, var: p_id}, {name: callback, var: callback}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_id: $p_id, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Downloads the complete RCRA Compliance History Section of the DFR
#
# GET /dfr_rest_services.rcra_3_yr_download
# Returns: binary
export def "get-dfr-rest-services-rcra-3-yr-download" [
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
    path: "/dfr_rest_services.rcra_3_yr_download"
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Downloads the complete RCRA Compliance History Section of the DFR
#
# POST /dfr_rest_services.rcra_3_yr_download
# Returns: binary
export def "post-dfr-rest-services-rcra-3-yr-download" [
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
    method: post
    path: "/dfr_rest_services.rcra_3_yr_download"
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}
