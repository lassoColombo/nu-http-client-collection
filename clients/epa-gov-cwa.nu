# Auto-generated client for U.S. EPA Enforcement and Compliance History Online (ECHO) - Clean Water Act (CWA) Rest Services v2019.10.15
# Source: https://api.apis.guru/v2/specs/epa.gov/cwa/2019.10.15/swagger.json
# Auth: --token flag or $env.U_S_EPA_ENFORCEMENT_AND_COMPLIANCE_HISTORY_ONLINE_ECHO_CLEAN_WATER_ACT_CWA_REST_SERVICES_TOKEN

const CLIENT = {
  base_url: "https://echodata.epa.gov/echo"
  token_env_var: "U_S_EPA_ENFORCEMENT_AND_COMPLIANCE_HISTORY_ONLINE_ECHO_CLEAN_WATER_ACT_CWA_REST_SERVICES_TOKEN"
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
def p-reg-completer [] { ["01" "02" "03" "04" "05" "06" "07" "08" "09" "10"] }
def p-usmex-completer [] { ["N" "Y"] }
def p-ff-completer [] { ["Y"] }
def p-maj-completer [] { ["N" "Y"] }
def p-fea-completer [] { ["N" "W"] }
def p-feay-completer [] { ["1" "2" "3" "4" "5"] }
def p-feaa-completer [] { ["A" "E" "S"] }
def p-iea-completer [] { ["N" "W"] }
def p-ieay-completer [] { ["1" "2" "3" "4" "5"] }
def p-ieaa-completer [] { ["E" "S"] }
def p-qiv-completer [] { ["0" "12" "GT1" "GT2" "GT4" "GT8"] }
def p-impw-completer [] { ["N" "Y"] }
def p-imp-cau-grp-completer [] { ["ALGAL GROWTH" "AMMONIA" "BIOTOXINS" "CAUSE UNKNOWN" "CAUSE UNKNOWN - FISH KILLS" "CAUSE UNKNOWN - IMPAIRED BIOTA" "CHLORINE" "DIOXINS" "FISH CONSUMPTION ADVISORY" "FLOW ALTERATION(S)" "HABITAT ALTERATIONS" "MERCURY" "METALS (OTHER THAN MERCURY)" "NOXIOUS AQUATIC PLANTS" "NUISANCE EXOTIC SPECIES" "NUISANCE NATIVE SPECIES" "NUTRIENTS" "OIL AND GREASE" "ORGANIC ENRICHMENT/OXYGEN DEPLETION" "OTHER CAUSE" "PATHOGENS" "PESTICIDES" "PH/ACIDITY/CAUSTIC CONDITIONS" "POLYCHLORINATED BIPHENYLS (PCBS)" "RADIATION" "SALINITY/TOTAL DISSOLVED SOLIDS/CHLORIDES/SULFATES" "SEDIMENT" "TASTE, COLOR AND ODOR" "TEMPERATURE" "TOTAL TOXICS" "TOXIC INORGANICS" "TOXIC ORGANICS" "TRASH" "TURBIDITY"] }
def p-imp-pol-completer [] { ["N" "Y"] }
def p-trep-completer [] { ["CURR" "NOTCURR"] }
def p-pm-completer [] { ["GT10" "GT25" "GT5" "GT50" "GT75" "NONE"] }
def p-pd-completer [] { ["GT100" "GT1000" "GT10000" "GT20000" "GT500" "GT5000" "NONE"] }
def p-ico-completer [] { ["N" "Y"] }
def p-med-completer [] { ["A" "ALL" "M" "R" "S"] }
def p-ysl-completer [] { ["N" "NV" "W"] }
def p-ysly-completer [] { ["1" "2" "3" "4" "5"] }
def p-ysla-completer [] { ["A" "E" "S"] }
def p-plimits-completer [] { ["N" "Y"] }
def p-pcss-completer [] { ["ALL" "GE1" "GE10" "GE50"] }
def p-pexp-completer [] { ["EXP" "EXPGT1YR" "EXPLE1YR"] }
def p-owop-completer [] { ["FEDERAL" "NON-POTW" "POTW"] }
def p-agoo-completer [] { ["AND" "OR"] }
def p-pexcd-completer [] { ["0" "GE0" "GE10" "GE100" "GE50"] }
def p-psncq-completer [] { ["GE1" "GE12" "GE2" "GE4" "GE8" "GT1" "GT12" "GT2" "GT4" "GT8"] }
def p-pctrack-completer [] { ["Off" "On" "Partial"] }
def p-dwd-completer [] { ["0" "GT0" "GT1000" "GT10000" "GT20000" "GT5000" "GT50000"] }
def p-pt-completer [] { ["0" "GT0" "GT1000" "GT10000" "GT20000" "GT5000" "GT50000"] }
def p-pdwdist-completer [] { ["LT1" "LT10" "LT15" "LT2" "LT5" "N"] }
def p-pswdmp-completer [] { ["1" "2" "3" "4" "5"] }
def p-pswvio-completer [] { ["N" "Y"] }
def p-fntype-completer [] { ["ALL" "BEGINS" "CONTAINS" "EXACT"] }
def p-pidall-completer [] { ["N" "Y"] }
def p-last-dmr-within-completer [] { ["N" "W"] }
def p-indsw-completer [] { ["N" "Y"] }
def p-msgp-ptype-completer [] { ["NOE" "NOI"] }
def p-mon-type-completer [] { ["BENCH" "BENCHG2" "ELG"] }
def p-ms4-completer [] { ["N" "Y"] }
def p-oo-f-ntype-completer [] { ["ALL" "BEGINS" "CONTAINS" "EXACT"] }
def p-fac-ico-completer [] { ["N" "Y"] }
def p-limit-addr-completer [] { ["N" "Y"] }
def p-ejscreen-over80cnt-completer [] { ["1" "10" "11" "2" "3" "4" "5" "6" "7" "8" "9"] }
def p-bio-current-vio-completer [] { ["N" "Y"] }
def p-bio-vio-last-year-completer [] { ["N" "Y"] }
def p-vio-last-year-completer [] { ["N" "Y"] }
def tablelist-completer [] { ["N" "Y"] }
def maplist-completer [] { ["N" "Y"] }
def summarylist-completer [] { ["N" "Y"] }
def descending-completer [] { ["N" "Y"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-cwa-rest-services-get-download: "binary"
    post-cwa-rest-services-get-download: "binary"
    get-cwa-rest-services-get-facilities: "record<Results: record<BadSystemIDs: string, BioCVRows: string, BioV3Rows: string, CVRows: string, FEARows: string, Facilities: list<record>, INSPRows: string, IndianCountryRows: string, InfFEARows: string, MapOutput: record<IconBaseURL: string, MapData: list, PopUpBaseURL: string, QueryID: string>, Message: string, PageNo: string, QueryID: string, QueryRows: string, SVRows: string, TotalPenalties: string, V3Rows: string, Version: string, VioLast4QRows: string>>"
    post-cwa-rest-services-get-facilities: "record<Results: record<BadSystemIDs: string, BioCVRows: string, BioV3Rows: string, CVRows: string, FEARows: string, Facilities: list<record>, INSPRows: string, IndianCountryRows: string, InfFEARows: string, MapOutput: record<IconBaseURL: string, MapData: list, PopUpBaseURL: string, QueryID: string>, Message: string, PageNo: string, QueryID: string, QueryRows: string, SVRows: string, TotalPenalties: string, V3Rows: string, Version: string, VioLast4QRows: string>>"
    get-cwa-rest-services-get-facility-info: "record<Results: record<BadSystemIDs: string, BioCVRows: string, BioV3Rows: string, CVRows: string, ClusterOutput: record<ClusterData: list>, ClusterRecords: string, FEARows: string, Facilities: list<record>, INSPRows: string, IconBaseURL: string, IndianCountryRows: string, InfFEARows: string, Message: string, PopUpBaseURL: string, QueryID: string, QueryParameters: list<record>, QueryRows: string, SVRows: string, ServiceBaseURL: string, TotalPenalties: string, V3Rows: string, VioLast4QRows: string>>"
    post-cwa-rest-services-get-facility-info: "record<Results: record<BadSystemIDs: string, BioCVRows: string, BioV3Rows: string, CVRows: string, ClusterOutput: record<ClusterData: list>, ClusterRecords: string, FEARows: string, Facilities: list<record>, INSPRows: string, IconBaseURL: string, IndianCountryRows: string, InfFEARows: string, Message: string, PopUpBaseURL: string, QueryID: string, QueryParameters: list<record>, QueryRows: string, SVRows: string, ServiceBaseURL: string, TotalPenalties: string, V3Rows: string, VioLast4QRows: string>>"
    get-cwa-rest-services-get-geojson: "record<features: table<geometry: record, properties: record, type: string>, type: string>"
    post-cwa-rest-services-get-geojson: "record<features: table<geometry: record, properties: record, type: string>, type: string>"
    get-cwa-rest-services-get-info-clusters: "binary"
    post-cwa-rest-services-get-info-clusters: "binary"
    get-cwa-rest-services-get-map: "record<MapOutput: record<IconBaseURL: string, MapData: list<record>, PopUpBaseURL: string, QueryID: string>>"
    post-cwa-rest-services-get-map: "record<MapOutput: record<IconBaseURL: string, MapData: list<record>, PopUpBaseURL: string, QueryID: string>>"
    get-cwa-rest-services-get-qid: "record<Results: record<Facilities: list<record>, Message: string, PageNo: string, QueryID: string, QueryRows: string>>"
    post-cwa-rest-services-get-qid: "record<Results: record<Facilities: list<record>, Message: string, PageNo: string, QueryID: string, QueryRows: string>>"
    get-cwa-rest-services-metadata: "record<Results: record<Message: string, ResultColumns: list<record>>>"
    post-cwa-rest-services-metadata: "record<Results: record<Message: string, ResultColumns: list<record>>>"
    get-rest-lookups-bp-tribes: "record<Results: record<LuValues: list<record>, Message: string>>"
    post-rest-lookups-bp-tribes: "record<Results: record<LuValues: list<record>, Message: string>>"
    get-rest-lookups-cwa-parameters: "record<Results: record<LuValues: list<record>, Message: string>>"
    post-rest-lookups-cwa-parameters: "record<Results: record<LuValues: list<record>, Message: string>>"
    get-rest-lookups-cwa-pollutants: "record<Results: record<LuValues: list<record>, Message: string>>"
    post-rest-lookups-cwa-pollutants: "record<Results: record<LuValues: list<record>, Message: string>>"
    get-rest-lookups-federal-agencies: "record<Results: record<LuValues: list<record>, Message: string>>"
    post-rest-lookups-federal-agencies: "record<Results: record<LuValues: list<record>, Message: string>>"
    get-rest-lookups-icis-inspection-types: "record<Results: record<LuValues: list<record>, Message: string>>"
    post-rest-lookups-icis-inspection-types: "record<Results: record<LuValues: list<record>, Message: string>>"
    get-rest-lookups-icis-law-sections: "record<Results: record<LuValues: list<record>, Message: string>>"
    post-rest-lookups-icis-law-sections: "record<Results: record<LuValues: list<record>, Message: string>>"
    get-rest-lookups-naics-codes: "record<Results: record<LuValues: list<record>, Message: string>>"
    post-rest-lookups-naics-codes: "record<Results: record<LuValues: list<record>, Message: string>>"
    get-rest-lookups-npdes-parameters: "record<Results: record<LuValues: list<record>, Message: string>>"
    post-rest-lookups-npdes-parameters: "record<Results: record<LuValues: list<record>, Message: string>>"
    get-rest-lookups-wbd-code-lu: "record<Results: record<LuValues: list<record>, Message: string>>"
    post-rest-lookups-wbd-code-lu: "record<Results: record<LuValues: list<record>, Message: string>>"
    get-rest-lookups-wbd-name-lu: "record<Results: record<LuValues: list<record>, Message: string>>"
    post-rest-lookups-wbd-name-lu: "record<Results: record<LuValues: list<record>, Message: string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-cwa-rest-services-get-download" "post-cwa-rest-services-get-download" "get-cwa-rest-services-get-facilities" "post-cwa-rest-services-get-facilities" "get-cwa-rest-services-get-facility-info" "post-cwa-rest-services-get-facility-info" "get-cwa-rest-services-get-geojson" "post-cwa-rest-services-get-geojson" "get-cwa-rest-services-get-info-clusters" "post-cwa-rest-services-get-info-clusters" "get-cwa-rest-services-get-map" "post-cwa-rest-services-get-map" "get-cwa-rest-services-get-qid" "post-cwa-rest-services-get-qid" "get-cwa-rest-services-metadata" "post-cwa-rest-services-metadata" "get-rest-lookups-bp-tribes" "post-rest-lookups-bp-tribes" "get-rest-lookups-cwa-parameters" "post-rest-lookups-cwa-parameters" "get-rest-lookups-cwa-pollutants" "post-rest-lookups-cwa-pollutants" "get-rest-lookups-federal-agencies" "post-rest-lookups-federal-agencies" "get-rest-lookups-icis-inspection-types" "post-rest-lookups-icis-inspection-types" "get-rest-lookups-icis-law-sections" "post-rest-lookups-icis-law-sections" "get-rest-lookups-naics-codes" "post-rest-lookups-naics-codes" "get-rest-lookups-npdes-parameters" "post-rest-lookups-npdes-parameters" "get-rest-lookups-wbd-code-lu" "post-rest-lookups-wbd-code-lu" "get-rest-lookups-wbd-name-lu" "post-rest-lookups-wbd-name-lu" "commands"] | sort) } | get name | first)
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

# Clean Water Act (CWA) Download Data Service
#
# GET /cwa_rest_services.get_download
# Returns: binary
export def "get-cwa-rest-services-get-download" [
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
  --p-pretty-print: float # Optional flag to request GeoJSON formatted results to be pretty printed. Only provide a numeric value when the output needs to be human readable as pretty printing has a performance cost.
]: nothing -> any {
  http-request {
    method: get
    path: "/cwa_rest_services.get_download"
    query: [{name: output, var: output}, {name: qid, var: qid, required: true}, {name: qcolumns, var: qcolumns}, {name: p_pretty_print, var: p_pretty_print}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, qid: $qid, qcolumns: $qcolumns, p_pretty_print: $p_pretty_print
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Clean Water Act (CWA) Download Data Service
#
# POST /cwa_rest_services.get_download
# Returns: binary
export def "post-cwa-rest-services-get-download" [
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
  --p-pretty-print: float # Optional flag to request GeoJSON formatted results to be pretty printed. Only provide a numeric value when the output needs to be human readable as pretty printing has a performance cost.
]: any -> any {
  $in | http-request {
    method: post
    path: "/cwa_rest_services.get_download"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: qid, var: qid}, {name: qcolumns, var: qcolumns}, {name: p_pretty_print, var: p_pretty_print}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, qid: $qid, qcolumns: $qcolumns, p_pretty_print: $p_pretty_print
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Clean Water Act (CWA) Facility Search Service
#
# GET /cwa_rest_services.get_facilities
# Returns: record<Results: record<BadSystemIDs: string, BioCVRows: string, BioV3Rows: string, CVRows: string, FEARows: string, Facilities: list<record>, INSPRows: string, IndianCountryRows: string, InfFEARows: string, MapOutput: record<IconBaseURL: string, MapData: list, PopUpBaseURL: string, QueryID: string>, Message: string, PageNo: string, QueryID: string, QueryRows: string, SVRows: string, TotalPenalties: string, V3Rows: string, Version: string, VioLast4QRows: string>>
export def "get-cwa-rest-services-get-facilities" [
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
  --p-fn: string # Facility Name Filter. Enter one or more case-insensitive facility names to filter results. Provide multiple values as a comma-delimited list. See p_fntype for additional modifiers.
  --p-sa: string # Facility street address. Enter a complete or partial street address.
  --p-sa1: string # Facility street address. Enter a complete or partial street address. Note that p_sa1 is culmulative with p_sa.
  --p-ct: string # Facility City Filter. Enter a single case-insensitive city name to filter results.
  --p-co: string # Facility County Filter. Provide a single county name in combination with a state value provided via p_st.
  --p-fips: string # FIPS Code Filter. Enter a single 5-character Federal Information Processing Standards (FIPS) state + county value to restrict results. E.g. to limit results to Kenosha County, Wisconsin, use 55059.
  --p-st: string # Facility State and State-Equivalent Filter. Provide one or more USPS postal abbreviations for states and state-equivalents to filter results. Provide multiple values as a comma-delimited list.
  --p-zip: string # 5-Digit ZIP Code Filter. Provide one or more 5-digit postal zip codes to filter results. May contain multiple comma-separated values.
  --p-frs: string # Facility Registry Service ID Filter. Enter a single 12-digit FRS identifier to filter results.
  --p-reg: string@p-reg-completer # EPA Region Filter. Provide a single value of 01 thru 10 to restrict results to a single EPA region.
  --p-sic: string # Standard Industrial Classification (SIC) Code Filter. Enter a single 4-digit SIC Code to filter results. If more complex filtering is required, use p_sic2 and p_sic4.
  --p-ncs: string # North American Industry Classification System Filter. Enter two to six digits to filter results to facilities having matching NAICS codes. Digits less than six will match to all codes beginning with the provided values.
  --p-pen: string # Last Penality Date Qualifier Filter. Enter one of the following: - NEVER = No Penalties - ANY = Any Penalty - LEXX = Less than or equal to XX months. Provide a number in place of XX, e.g. "LE5" for a facility with a penalty within previous 5 months. - GTXX = Greater than XX months. Provide a number in place of XX, eg. GT12, for a facility with the last penalty greater than 12 months ago.
  --p-c1lat: float # In decimal degrees. Latitude of 1st corner of box that bounds the resulting facilities. The latitude and longitude of both corners of the bounding box must be provided.
  --p-c1lon: float # In decimal degrees. Longitude of 1st corner of box that bounds the resulting facilities. The latitude and longitude of both corners of the bounding box must be provided.
  --p-c2lat: float # In decimal degrees. Latitude of 2nd corner of box that bounds the resulting facilities. The latitude and longitude of both corners of the bounding box must be provided.
  --p-c2lon: float # In decimal degrees. Longitude of 2nd corner of box that bounds the resulting facilities. The latitude and longitude of both corners of the bounding box must be provided.
  --p-usmex: string@p-usmex-completer # US-Mexico Border Flag. Enter Y/N to restrict searches to facilities located within 100KM of the border.
  --p-sic2: string # Standard Industrial Classification (SIC) Code Filter Alternate 2. Enter a wild-card search against SIC codes. A final wild-card is always present allowing "22" to match all SIC codes beginning with 22. Use the "%" character within strings to match any SIC values with the pattern. For example, "2%21" matches 2021, 2121, 2221, etc.
  --p-sic4: string # Standard Industrial Classification (SIC) Code Filter Alternate 3. Enter the first 2, 3 or 4 SIC code digits to filter results to facilities having those code prefixes. As this alternative does not utilize an index, p_sic2 will generally be quicker.
  --p-fa: string # Federal Agency. 1 character or 5-character values; may contain multiple comma-separated values. ALL will retrieve all facilities where the federal agency code is not null. Use the Federal Agencies lookup service to obtain a list of values.
  --p-ff: string@p-ff-completer # Federal Facility Indicator Flag. Enter Y to restrict searches to federal facilities.
  --p-act: string # Active Permits/Facilities Flag. Provide Y or N to filter results to facilities with active permits. A Y will select ICIS NPDES permits with a status of effective, continued, or expired.
  --p-maj: string@p-maj-completer # Major Facility Flag. Enter Y to restrict results to Major facilities only.
  --p-mact: string # CAA Maximum Achievable Control Technology (MACT) Subpart codes (alpha ID between 1 and 7 characters) applicable to the facility.
  --p-fea: string@p-fea-completer # Formal Enforcement Actions [within / not within] specified date range indicator. The date range is determined by parameters p_fead1 and p_fead2 or by parameter p_feay. - W = within date range - N = not within date range
  --p-feay: float@p-feay-completer # Years (1 to 5) Range. This value is used to create a date range for Formal Enforcement Actions (FEA). Used along with p_fea (which indicates whether to look within or outside of the date range) to find FEAs within (or not within) the number of years specified.
  --p-feaa: string@p-feaa-completer # Agency associated with Formal Enforcement Actions: - E = EPA - S = State - A = All
  --p-iea: string@p-iea-completer # Informal Enforcement Actions [within / not within] specified date range. The date range is determined by parameters p_iead1 and p_iead2 or by parameter p_ieay. - W = within date range - N = not within date range
  --p-ieay: float@p-ieay-completer # Years (1 to 5) Range. This value is used to create a date range for Informal Enforcement Actions (IEA). Used along with p_iea (which indicates whether to look within or outside of the date range) to find IEAs within (or not within) the number of years specified.
  --p-ieaa: string@p-ieaa-completer # Agency associated with Informal Enforcement Actions. If left blank, both agencies are included. - E = EPA - S = State
  --p-qiv: string@p-qiv-completer # Quarters in Noncompliance Limiter. Enter a coded value to limit results to facilities with given quarter of noncompliance. - Z = Zero quarters in noncompliance. - GEXX = Replacing XX with a numeric value, that number of quarterd or more in noncompliance. - GTXX = Replacing XX with a numeric value, more than that number of quarters in noncompliance.
  --p-iv: string # Facility has a violation status of 'In Viol' during any of the selected quarters. Range: Fiscal Year 2020 Quarter 2 to Fiscal Year 2017 Quarter 2 Multiple values are comma delimited. |||||| Fiscal Years |||||| - FY2020 or FY20 or 2020 or 20 - FY2019 or FY19 or 2019 or 19 - FY2018 or FY18 or 2018 or 18 - FY2017 or FY17 or 2017 or 17 ||||| Fiscal Quarters ||||| - FY2020Q2 or FY20Q2 or 20202 or 202 or 13 - FY2020Q1 or FY20Q1 or 20201 or 201 or 12 - FY2019Q4 or FY19Q4 or 20194 or 194 or 11 - FY2019Q3 or FY19Q3 or 20193 or 193 or 10 - FY2019Q2 or FY19Q2 or 20192 or 192 or 9 - FY2019Q1 or FY19Q1 or 20191 or 191 or 8 - FY2018Q4 or FY18Q4 or 20184 or 184 or 7 - FY2018Q3 or FY18Q3 or 20183 or 183 or 6 - FY2018Q2 or FY18Q2 or 20182 or 182 or 5 - FY2018Q1 or FY18Q1 or 20181 or 181 or 4 - FY2017Q4 or FY17Q4 or 20174 or 174 or 3 - FY2017Q3 or FY17Q3 or 20173 or 173 or 2 - FY2017Q2 or FY17Q2 or 20172 or 172 or 1
  --p-impw: string@p-impw-completer # Discharging into Impaired Waters Flag. Enter Y to limit results to facilities with discharge to waterbodies listed as impaired in the ATTAINS database.
  --p-imp-cau-grp: string@p-imp-cau-grp-completer # Facility is discharging a pollutant group causing a waterbody to be impaired. Enter 1 through 34 (the internal number of the pollutant group); or enter a partial name such as Dioxin,Temp,tUrBidity.
  --p-imp-pol: string@p-imp-pol-completer # Facility is discharging pollutants that are potentially contributing to the impairment of local waterbodies according to the ATTAINS database.
  --p-trep: string@p-trep-completer # Current Toxics Release Inventory (TRI) Reporter Limiter. Enter one of the following codes to limit results. - CURR = Current TRI reporter. - NONCURR = Has reported to TRI in the past but not for the current reporting year.
  --p-pm: string@p-pm-completer # Percent Minority Population Limiter. Enter a value to restrict results to facilities with a given percentage of minority population within 3-mile radius. - NONE = 0% - GT5 = greater than 5% - GT10 = greater than 10% - GT25 = greater than 25% - GT50 = greater than 50% - GT75 = greater than 75%
  --p-pd: string@p-pd-completer # Population Density Limiter (per sq mile). Enter a value to limit results to facilities located in area of a given population density. - NONE = 0 population density per square mile - GT100 = More than 100 population density per square mile - GT500 = More than 500 population density per square mile - GT1000 = More than 1000 population density per square mile - GT5000 = More than 5000 population density per square mile - GT10000 = More than 10000 population density per square mile - GT20000 = More than 20000 population density per square mile
  --p-ico: string@p-ico-completer # Indian Country Flag. Enter a "Y" or "N" to restrict searches to facilities inside or outside Indian Country.
  --p-huc: string # 2-, 4-, 6-, or 8-character watershed code. May contain multiple comma-separated values.
  --p-pid: string # Nine-digit permit IDs. May contain up to 2000 comma-separated values.
  --p-med: string@p-med-completer # Filter Results by Media. - A = Air - M = RMP (Risk Management Plan) - R = RCRA (Hazardous Waste) - S = SDWA (Public Drinking Water Systems) - ALL = Air and RCRA and Water
  --p-ysl: string@p-ysl-completer # Last Facility Inspection [within / not within] Specified Date Range Indicator. The date range is determined by parameters p_idt1 and p_idt2 or by parameter p_ysly. - W = within date range - N = not within date range
  --p-ysly: float@p-ysly-completer # Number of years (1 to 5) since last facility inspection. A value of 1 means that it has been inspected within the year.
  --p-ysla: string@p-ysla-completer # Facility Last Inspection Code Filter. If left blank, both agencies are included. Enter a value to limit results: - E = EPA - S = State
  --p-qs: string # Quick Search. Allows entry for city, state, and/or zip code.
  --p-sfs: string # Single Facility Search Filter. Provide a facility name or program system identifier to limit results. For the all data search, the FRS registry identifier is also searched.
  --p-tribeid: float # Numeric code for tribe (or list of tribes).
  --p-tribename: string # Tribe Name Filter. Enter a single tribe name to filter results.
  --p-tribedist: float # Proximity to tribal land limiter. Enter an amount of mile between 0 and 25 to filter results. This parameter is only evaluated if p_tribeid is populated.
  --p-pstat: string # Permit Status Filter. Enter one or more of the following codes. Provide multiple values as a comma-delimited list. - EFF = Effective - EXP = Expired - PND = Pending - TRM = Terminated - RET = Retired - NON = Not Needed - ADC = Admin Continued
  --p-ptype: string # Permit Type Filter. Enter one or more code values to filter results. Provide multiple values as a comma-delimited list. - NPD = NPDES Individual Permit - NGP = NPDES Master General Permit - GPC = General Permit Covered Facility - SNN = State Issued Master General Permit (Non-NPDES) - IIU = Individual IU Permit (Non-NPDES) - SIN = Individual State Issued Permit (Non-NPDES) - APR = Associated Permit Record - UFT = Unpermitted Facility
  --p-pcomp: string # Permit Component Code Filter. Enter one or more codes to filter results. Provide multiple values as a comma-delimited list. - PRE = Pretreatment - CAF = CAFO - CSO = CSO - POT = POTW - BIO = Biosolids - SWS = Storm Water Small MS4s - SWM = Storm Water Medium/Large MS4s - SWI = Storm Water Industrial - SWC = Storm Water Construction
  --p-plimits: string@p-plimits-completer # Permit Limits Present Flag. Enter Y to limit results to facilities have present permit limits.
  --p-pcss: string@p-pcss-completer # Combined Sewer Systems Outflows Limiter. Enter one of the following to limit results to facilities having the given count of CSS outflows. - ALL = returns all facilities, regardless of the number of outflows. - GE1 = returns facilities with one or more outflows. - GE10 = returns facilities with ten or more outflows. - GE50 = returns facilities with fifty or more outflows.
  --p-pexp: string@p-pexp-completer # Permit Expired or Administratively Continued Limiter. Enter one of the following values to filter results. - EXP = limit results to facilities with permits expired or administratively continued. - EXPLE1YR = limit resuls to facilities with permits expired administratively continued within the past year. - EXPGT1YR = limit resuls to facilities with permits expired administratively continued more than a year ago.
  --p-owop: string@p-owop-completer # Owner/Operator code filter. Enter one of the following values to restrict results. - Federal = Federal facilities regulated under the NPDES program. - POTW = Publicly owned treatment works. Treatment works that are owned by a State, Tribe, or municipality. - Non-POTW = Non-publicly owned treatment works. Often referred to as "non-municipals" or "industrials".
  --p-ipfti: string
  --p-agoo: string@p-agoo-completer # Indicates whether to AND or OR the Owner/Operator parameter (p_owop) and the federal agency code (p_fa) parameters.
  --p-idt1: string # Beginning of date range of most recent facility inspection.
  --p-idt2: string # End of date range of most recent facility inspection.
  --p-pityp: string # Inspection Type Code. See ICIS Compliance Monitor Types lookup serivce for a list of available codes and descriptions.
  --p-pfead1: string # Formal Enforcement Action Date Range Start. Enter a date in MM/DD/YYYY format to set the start of the range for filtering by recent Formal Enforcement Action (FEA) taken against the facility within the last five years.
  --p-pfead2: string # Formal Enforcement Action Date Range End. Enter a date in MM/DD/YYYY format to set the end of the date range for filtering by recent Formal Enforcement Action (FEA) taken against the facility within the last five years.
  --p-pfeat: string # Formal Enforcement Action (FEA) Code Filter. Enter one or more three-letter FEA codes to restrict results to facilities with these attributes. Use p_fead1 and p_fead2 parameters to further restrict this filter by entering a date range. Provide multiple codes as a comma-delimited list.
  --p-pccs: string # Current Compliance Status: ||||||||||||||||||||||||||| Significant Noncompliance (SNC) ||||||||||||||||||||||||||| - SNC = E, S, X, T, D - E�= E(EffViol) - S�= S(CSchVio) - X = X(EffNMth) - T = T(CSchRpt) - D�= D(DMR NR) ||||||||||||||||||||||||||| Noncompliance (NC) ||||||||||||||||||||||||||| - NC = N, V - N�= N(RptViol) - V�= V(NonRNCV) ||||||||||||||||||||||||||| New Violations (PQV) ||||||||||||||||||||||||||| - PQV = New Violations (13th Quarter) ||||||||||||||||||||||||||| No Violations (NV) ||||||||||||||||||||||||||| - NV = R, P, M, U, W , Blank, and No New Violations (no PQV) - R�= R(Resolvd) - P�= P(ResPend) - M�= C(Manual) - U = U(N/A) - W = W(N/A) - Blank = (null) May contain multiple comma-separated values.
  --p-pexcd: string@p-pexcd-completer # 3-Year Effluent Exceedances Limiter. Enter a value to restrict results to facilities with the given amount of exceedances in the past 3 years. - 0 = facilities with no exceedances - GE0 = facilities with one or more exceedances - GE10 = facilities with ten or more exceedances - GE50 = facilities with fifty or more exceedances - GE100 = facilities with one hundred or more exceedances
  --p-psncq: string@p-psncq-completer # Quarters in Significant Noncompliance Limiter. Enter a coded value to limit results to facilities with given quarter of significant noncompliance. - Z = Zero quarters in significant noncompliance. - GEXX = Replacing XX with a numeric value, that number of quarterd or more in significant noncompliance. - GTXX = Replacing XX with a numeric value, more than that number of quarters in significant noncompliance.
  --p-pctrack: string@p-pctrack-completer # Compliance Tracking Limiter. Provide a keyword to indicate the extent to which data is being entered and effluent exceedances are being identified. - Off - Partial - On
  --p-dwd: string@p-dwd-completer # Direct Water Discharges. Pounds of toxic chemicals released directly to surface water as reported to the Toxics Release Inventory.
  --p-pt: string@p-pt-completer # POTW Transfers. Pounds of toxic chemicals transferred to a Publicly Operated Treatment Works (POTW) as reported to the Toxics Release Inventory.
  --p-pdwdist: string@p-pdwdist-completer # Distance (in miles) to downstream drinking water intake.
  --p-pswdpc: string # Pollutant Category Code: Values: WTR for Water, AIR for Air
  --p-pswdmp: string@p-pswdmp-completer # Used to determine limit begin and end dates for surface water discharges. Number represents years from current date.
  --p-pswpol: string # For CWA, pollutant names for surface water discharges. for Drinking Water, SDWIS Violation contaminant codes for unaddressed violations that have occurred in the last 3 years. May contain multiple comma-separated values.
  --p-pswcas: string # CAS numbers for surface water discharges. May contain multiple comma-separated values.
  --p-pswparam: string # Parameter codes for surface water discharges. May contain multiple comma-separated values.
  --p-pswvio: string@p-pswvio-completer # Used in conjuction with parameters p_pswpol and p_pswparam, indicates whether search should only include pollutants with violations.
  --p-wbd: string # 2-, 4-, 6-, 8-, 10-, or 12-character watershed (WBD from the USGS Watershed Boundary Dataset). May contain multiple comma-separated values. Uses the FRS Best Pick Coordinate to obtain the WBD12 Huc value.
  --p-radwbd: string # 2-, 4-, 6-, 8-, 10-, or 12 character watershed (WBD from the USGS Watershed Boundary Dataset). May contain multiple comma-separated values. Will search against WBD values otained by "reach indexing" NPDES permits against the medium resolution National Hydrography Dataset.
  --p-frswbd: string # Works exactly the same as the p_wbd parameter. 2-, 4-, 6-, 8-, 10-, or 12-character watershed (WBD from the USGS Watershed Boundary Dataset). May contain multiple comma-separated values. Uses the FRS Best Pick Coordinate to obtain the WBD12 Huc value.
  --p-fntype: string@p-fntype-completer # Controls type of text search performed on facility name with parameter p_fn. - EXACT = Find facilities having the exact provided name(s). - BEGINS = Find facilities with names starting with the provided term(s). - ALL = Find facilities using Oracle text search terms. - CONTAINS =
  --p-pidall: string@p-pidall-completer # Controls whether search is restricted to existing system. Y means the search will match the p_pid parameter against all associated permits (AIR, RCRA, SDWIS, etc).
  --p-months-last-dmr: float # The number of months since the last Discharge Monitoring Report has been submitted.
  --p-last-dmr-within: string@p-last-dmr-within-completer # W value returns facilities that have submitted DMRs within the number of months specified by p_months_last_dmr. An N value returns facilities that have not submitted a DMR within the specified number of months.
  --p-indsw: string@p-indsw-completer # Industrial Stormwater Permit Flag. Enter a Y or N to filter results by this type of permit.
  --p-msgp-ptype: string@p-msgp-ptype-completer # Multi-Sector General Purpose Permit Type. Enter a value to filter results by MSGP Permit Type. - NOI = Notice of Intent - NOE = No Exposure Certification
  --p-mon-type: string@p-mon-type-completer # For use with the Industrial Stormwater search only. Valid values are BENCHGS fro Benchmark (Alert Limit) G2 Ore, BENCH for Benchmark (Alert Limit), and ELG fro Effluent Limitation Guidelines(ELG)(Effluent Limit).
  --p-iagency: string # Issuing Agency Limiter. Enter a single value to filter results by the issuing agency, e.g. "State" or "EPA".
  --p-permitting-agency: string
  --p-isws: string # Multi-Sector General Purpose Permit Subsector Individual Identifier. Enter a value to filter results.
  --p-iswss: string # Multi-Sector General Purpose Permit Subsector Group Code. Enter a value to filter results.
  --p-iswss-id: string # Multi-Sector General Purpose Permit Sector Code. Enter a value to filter results.
  --p-ds1: string # Submitted Date Filter Start. To filter by the date of submission, enter a start date here and an end date in the p_ds2 parameter. Both dates are required for filtering.
  --p-ds2: string # Submitted Date Filter End. To filter by the date of submission, enter an end date here and a start date in the p_ds1 parameter. Both dates are required for filtering.
  --p-da1: string # Active Date Filter Start. To filter by the active date, enter a start date here and an end date in the p_da2 parameter. Both dates are required for filtering.
  --p-da2: string # Active Date Filter End. To filter by the active date, enter an end date here and a start date in the p_da1 parameter. Both dates are required for filtering.
  --p-ms4: string@p-ms4-completer # Municipal Separate Storm Water Sewer (MS4) Permit Flag. Enter a Y or N to filter results by this type of permit.
  --p-oo-fn: string # Owner/Operator Name. Enter the owner/operator name of the facility.
  --p-oo-f-ntype: string@p-oo-f-ntype-completer # Owner/Operator Name Multiple Selection Evaluator.
  --p-oo-sa: string # Owner/Operator Address. Enter the address of the owner/operator of the facility.
  --p-oo-sa1: string # Owner/Operator Address Line 2. Enter the line 2 address of the owner/operator of the facility.
  --p-oo-ct: string # Owner/Operator City. Enter the city where the owner/operator of the facility is located.
  --p-oo-st: string # Owner/Operator State. Enter the standardized postal state code where the owner/operator of the facility is located.
  --p-oo-zip: string # Owner/Operator Zip Code. Enter the postal zip code where the owner/operator of the facility is located.
  --p-fac-ico: string@p-fac-ico-completer # FRS tribal land code flag. Enter "Y" or "N" to include or exclude facilities based on FRS tribal land code.
  --p-icoo: string # Indian country search and/or flag. Enter "Y" to set indian country search conditions to return any results found using p_ico, p_fac_ico or p_fac_icoo. Otherwise only results matching all provided p_ico, p_fac_ico or p_fac_icoo conditions will be returned.
  --p-fac-icos: string # FRS tribal land spatial flag. Enter "Y" or "N" to include or exclude facilities based on FRS tribal land spatial flag.
  --p-ejscreen: string # Enter "Y" to limit facilities to Census block groups where one of more Environmental Justice indexes above 80th percentile.
  --p-alrexceed: float # Alert Limits Exceedences Limiter. Enter a numeric value to restrict results to facilities having the given amount or more of alert limits exceedances.
  --p-limit-addr: string@p-limit-addr-completer # Limit Address Search Flag. Enter Y to restrict facility searches to native data source only.
  --p-lat: float # Latitude location in decimal degrees.
  --p-long: float # Longitude location in decimal degrees.
  --p-radius: float # Spatial Search Radius. Enter a radius up to 100 miles in which to spatially search for facilities.
  --p-ejscreen-over80cnt: string@p-ejscreen-over80cnt-completer # The number of Environmenmt Justice Indicators above the 80th percentile. Valid values are 1 through 11.
  --p-bio-flag: string # A Y value will select all biosolid-related permits.
  --p-bio-fac-type: string # The code indicating the reporting obligation reason: - POT = A POTW with a design flow rate equal to or greater than one million gallons per day - CLI = A Class I Sludge Management Facility as defined in 40 CFR 503.9 - PPL = A POTW that serves 10,000 people or more - OTH = Otherwise required to report (e.g., permit condition, enforcement action) - NOA = None of the above
  --p-bio-trtmnt-procs: string # The biosolids or sewage sludge treatment process or processes at the facility: - AER = Aerobic Digestion - AIR = Air Drying (or Sludge Drying Beds) - ANA = Anaerobic Digestion - COD = Beta Ray Irradiation - COM = Lower Temperature Composting - DEW = Pasteurization - DIS = Gamma Ray Irradiation - HEA = Heat Drying (e.g., Flash Dryer, Spray Dryer, Rotary Dryer) - HET = Heat Treatment (Liquid Sewage Sludge Heated to 356 Deg. F/180 Deg. C or Higher for 30 min.) - HTC = Higher Temperature Composting - MET = Methane or Biogas Capture and Recovery - OTH = Other Treatment Process - PRE = Preliminary Operations (e.g., Sludge Grinding, Degritting, Blending) - SLU = Sludge Lagoon - STA = Lime Stabilization - THE = Temporary Sludge Storage (Sewage Sludge Stored on Land 2 Years or Less, Not in Sewage Sludge Unit) - THI = Thickening (Gravity and/or Flotation Thickening, Centrifugation, Belt Filter Press, Vacuum Filter) - THM = Thermophilic Aerobic Digestion - UND = Long-Term Sludge Storage (Sewage Sludge Stored on Land 2 Years or More, not in Sewage Sludge Unit)"
  --p-bio-analy-method-catgry: string # The unique code for the category of the analytic methods used by the facility to analyze regulated parameters (including enteric viruses, fecal coliforms, helminth ova, and Salmonella sp.) at the facility: - PAT = Pathogens - MET = Metals - NIT = Nitrogen Compounds - OTH = Other Analytes
  --p-bio-total-volume-amt: string # Total annual amount (in dry metric tons) of biosolids or sewage sludge generated at the facility. - EQ0 = 0 - IN0_1 = GT 0 but LT 1 - IN0_289 = GT 0 but LT 290 MT/year - IN290_1499 = GE 290 but LT 1500 MT/year - IN1500_14999 = GE 1500 but LT 15,000 - GE15000 = GE 15,000
  --p-bio-mgmt-prctce-type: string # The unique code that identifies the type of biosolids or sewage sludge management practice (e.g., land application, surface disposal, incineration) used by the facility. The facility will separately report the management practice for each biosolids or sewage sludge form and pathogen class. This data element will also identify the management practices used by surface disposal site owners/operators (see 40 CFR 503.24): - BIN = Incineration - BLN = Land Application - BOT = Other Management Practice - BSD = Surface Disposal
  --p-bio-mgmt-prctce-stype: string # This is the code indicating additional detail about the type of Management Practice used for a volume of Biosolids or Sewage Sludge: - ADV = Advanced Alkaline Stabilized Biosolids Distribution & Marketing - AGR = Agricultural Land Application - COM = Distribution and Marketing - Compost - DEE = Deep-well Injection Disposal - DIS = Disposal in a Municipal Landfill (under 40 CFR 258) - DMO = Distribution and Marketing - Other - HEA = Heat Dried Biosolids Distribution & Marketing - OTL = Other Land Application Management Practice Detail - OTO = Other Management Practice Detail - RSA = Reclamation Site Application - SEN = Sent to Cement Kiln for Use as Alternative Energy - STO = Storage - UIC = Use in Construction - UPS = Used in Production of Syngas - USE = Use as Daily Cover for Municipal Landfill (under 40 CFR 258)
  --p-bio-mgmt-prctce-handler: string # This is the code indicating the type of Biosolids or Sewage Sludge handlers/preparers. - OWN = Owner or Operator - OFF = Off-Site Third-Party Handler or Preparer
  --p-bio-mgmt-container: string # The code that identifies the nature of each biosolids and sewage sludge material generated by the facility in terms of whether the material is a biosolid or sewage sludge and whether the material is ultimately conveyed off-site in bulk or in bags. The facility separately reports the form for each biosolids or sewage sludge management practice or practices used by the facility and pathogen class: - BUL = Bulk - BAG = Bag or Container
  --p-bio-mgmt-pathogen: string # This code identifies the pathogen class [e.g., Class A, Class B, Not Applicable (Incineration)] for biosolids or sewage sludge generated by the facility. The facility will separately report the pathogen class for each biosolids or sewage sludge management practice used by the facility and by each biosolids or sewage sludge form. It also is used to filter applicable Pathogen Reduction and Vector Attraction Reduction Options as well as Land Application Management Practice Deficiencies. Only reqired for some of the mgmt. practice types: - AAA = Class A - AEQ = Class A EQ (sale/give away) - BBB = Class B - NAP = Not Applicable (Incineration)
  --p-bio-mgmt-pathred: string # This is the description of the option used by the facility to control pathogen for a Biosolids Management Practice: - A1 = Class A - Alternative 1: Time/Temperature - A2 = Class A - Alternative 2: pH/Temperature/Percent Solids - A3 = Class A - Alternative 3: Test Enteric Viruses and Helminth ova; Operating Parameters - A4 = Class A - Alternative 4: Test Enteric Viruses and Helminth ova; No New Solids - A51 = Class A - Alternative 5: PFRP 1: Composting - A52 = Class A - Alternative 5: PFRP 2: Heat Drying - A53 = Class A - Alternative 5: PFRP 3: Liquid heat treatment - A54 = Class A - Alternative 5: PFRP 4: Thermophilic Aerobic Digestion (ATAD) - A55 = Class A - Alternative 5 PFPR 5: Beta Ray Irradiation - A56 = Class A - Alternative 5 PFPR 6: Gamma Ray Irradiation - A57 = Class A - Alternative 5: PFRP 7: Pasteurization - A6 = Class A - Alternative 6: PFRP Equivalency - B1 = Class B - Alternative 1: Fecal Coliform Geometric Mean - B21 = Class B - Alternative 2 PSRP 1: Aerobic Digestion - B22 = Class B - Alternative 2 PSRP 2: Air Drying - B23 = Class B - Alternative 2 PSRP 3: Anaerobic Digestion - B24 = Class B - Alternative 2 PSRP 4: Composting - B25 = Class B - Alternative 2 PSRP 5: Lime Stabilization - B3 = Class B - Alternative 3: PSRP Equivalency - PH = pH Adjustment (Domestic Septage)
  --p-bio-mgmt-vector: string # The unique code that identifies the option used by the facility for vector attraction reduction. See a listing of these vector attraction reduction options at 40 CFR 503.33(b)(1) through (11). The facility will separately report the vector attraction reduction options for each biosolids or sewage sludge management practice used by the facility and by each biosolids or sewage sludge form as well as by each biosolids or sewage sludge pathogen class: - VR1 = Option 1 - Volatile Solids Reduction - VR2 = Option 2 - Bench-Scale Volatile Solids Reduction (Anaerobic Bench Test) - VR3 = Option 3 - Bench-Scale Volatile Solids Reduction (Aerobic Bench Test w/ Percent Solids - 2% or Less) - VR4 = Option 4 - Specific Oxygen Uptake Rate - VR5 = Option 5 - Aerobic Processing (Thermophilic Aerobic Digestion/Composting) - VR6 = Option 6 - Alkaline Treatment - VR7 = Option 7 - Drying (Equal to or Greater than 75 Percent) - VR8 = Option 8 - Drying (Equal to or Greater than 90 Percent) - VR9 = Option 9 - Sewage Sludge Injection - V10 = Option 10 - Sewage Sludge Timely Incorporation into Land - V11 = Option 11 - Sewage Sludge Covered at the End of Each Operating Day
  --p-bio-mgmt-def-category: string # This is the code indicating the type of NPDES special regulatory program deficiency: - INC = Biosolids Incineration - LNA = Biosolids Land Application - LNB = Biosolids Land Application - Pathogen Class B - OTB = Biosolids Other Management Practice - SFD = Biosolids Surface Disposal
  --p-bio-mgmt-deficiencies: float # The number of times noncompliance was reported by the facility in the last 3 years. The results returned will include facilities whose number of reported noncompliance events is greater than or equal to the number entered.
  --p-bio-vio-code: string # The Biosolids Single Event Violation Code. Enter one or mode codes.
  --p-bio-current-vio: string@p-bio-current-vio-completer # Indicator of whether the facility is currently in violation for biosolids under the Clean Water Act, in the 12th or 13th quarter: - Y = Yes - N = No
  --p-bio-qtrs-in-vio: float # The number of quarters, in the last three years, where the facility was in violation for a biosolids violation type. The results returned will include facilities whose number of quarters with violations is greater than or equal to the number entered.
  --p-bio-rpt-year: string # The last year that the permittee submitted an annual Biosolids report. Valid values are NONE and any year greater or equal to 2016.
  --p-bio-vio-last-year: string@p-bio-vio-last-year-completer # Identifies if a biosolids violation has occured in the last year. Valid values are Y and N.
  --p-msgp-rpt-year: string # The last year that a MSGP report was submitted for the permit. Valid values are "NONE" and any year Greater or Eqal to 2015.
  --p-vio-last-year: string@p-vio-last-year-completer # Identifies if a permit violation has occured in the last year. Valid values are Y and N.
  --queryset: float # Query Limiter. Enter a value to limit the number of records returned for each query. Value cannot exceed 70,000.
  --responseset: float # Response Set Limiter. Enter a value to limit the number of records per page. Value cannot exceed 1,000.
  --tablelist: string@tablelist-completer # Table List Flag. Enter a Y to display the first page of facility results.
  --maplist: string@maplist-completer # Map List Flag. Provide a Y to return mappable coordinates representing the full geographic extent of the queryset (all facilities that met the selection criteria).
  --summarylist: string@summarylist-completer # Summary List Flag. Enter a Y to return a list of summary statistics based on the parameters submitted to the query service.
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
  --qcolumns: string # Used to customize service output. A list of comma-separated column IDs of output objects that will be returned in the service query object or download. Use the metadata service endpoint for a complete list of Ids and definitions.
  --p-e90-count: float # Number of E90 Exceedances. Identifies water permits with a number of E90 (Effluient Exceedances) >= the value provided for the last number of years provided by the p_e90_years value.
  --p-e90-years: float # Number of years for the p_e90_count search. Identified the past number of years to be used for the p_e90_count search.
  --p-psc: string # Point Source Category.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/cwa_rest_services.get_facilities"
    query: [{name: output, var: output}, {name: p_fn, var: p_fn}, {name: p_sa, var: p_sa}, {name: p_sa1, var: p_sa1}, {name: p_ct, var: p_ct}, {name: p_co, var: p_co}, {name: p_fips, var: p_fips}, {name: p_st, var: p_st}, {name: p_zip, var: p_zip}, {name: p_frs, var: p_frs}, {name: p_reg, var: p_reg}, {name: p_sic, var: p_sic}, {name: p_ncs, var: p_ncs}, {name: p_pen, var: p_pen}, {name: p_c1lat, var: p_c1lat}, {name: p_c1lon, var: p_c1lon}, {name: p_c2lat, var: p_c2lat}, {name: p_c2lon, var: p_c2lon}, {name: p_usmex, var: p_usmex}, {name: p_sic2, var: p_sic2}, {name: p_sic4, var: p_sic4}, {name: p_fa, var: p_fa}, {name: p_ff, var: p_ff}, {name: p_act, var: p_act}, {name: p_maj, var: p_maj}, {name: p_mact, var: p_mact}, {name: p_fea, var: p_fea}, {name: p_feay, var: p_feay}, {name: p_feaa, var: p_feaa}, {name: p_iea, var: p_iea}, {name: p_ieay, var: p_ieay}, {name: p_ieaa, var: p_ieaa}, {name: p_qiv, var: p_qiv}, {name: p_iv, var: p_iv}, {name: p_impw, var: p_impw}, {name: p_imp_cau_grp, var: p_imp_cau_grp}, {name: p_imp_pol, var: p_imp_pol}, {name: p_trep, var: p_trep}, {name: p_pm, var: p_pm}, {name: p_pd, var: p_pd}, {name: p_ico, var: p_ico}, {name: p_huc, var: p_huc}, {name: p_pid, var: p_pid}, {name: p_med, var: p_med}, {name: p_ysl, var: p_ysl}, {name: p_ysly, var: p_ysly}, {name: p_ysla, var: p_ysla}, {name: p_qs, var: p_qs}, {name: p_sfs, var: p_sfs}, {name: p_tribeid, var: p_tribeid}, {name: p_tribename, var: p_tribename}, {name: p_tribedist, var: p_tribedist}, {name: p_pstat, var: p_pstat}, {name: p_ptype, var: p_ptype}, {name: p_pcomp, var: p_pcomp}, {name: p_plimits, var: p_plimits}, {name: p_pcss, var: p_pcss}, {name: p_pexp, var: p_pexp}, {name: p_owop, var: p_owop}, {name: p_ipfti, var: p_ipfti}, {name: p_agoo, var: p_agoo}, {name: p_idt1, var: p_idt1}, {name: p_idt2, var: p_idt2}, {name: p_pityp, var: p_pityp}, {name: p_pfead1, var: p_pfead1}, {name: p_pfead2, var: p_pfead2}, {name: p_pfeat, var: p_pfeat}, {name: p_pccs, var: p_pccs}, {name: p_pexcd, var: p_pexcd}, {name: p_psncq, var: p_psncq}, {name: p_pctrack, var: p_pctrack}, {name: p_dwd, var: p_dwd}, {name: p_pt, var: p_pt}, {name: p_pdwdist, var: p_pdwdist}, {name: p_pswdpc, var: p_pswdpc}, {name: p_pswdmp, var: p_pswdmp}, {name: p_pswpol, var: p_pswpol}, {name: p_pswcas, var: p_pswcas}, {name: p_pswparam, var: p_pswparam}, {name: p_pswvio, var: p_pswvio}, {name: p_wbd, var: p_wbd}, {name: p_radwbd, var: p_radwbd}, {name: p_frswbd, var: p_frswbd}, {name: p_fntype, var: p_fntype}, {name: p_pidall, var: p_pidall}, {name: p_months_last_dmr, var: p_months_last_dmr}, {name: p_last_dmr_within, var: p_last_dmr_within}, {name: p_indsw, var: p_indsw}, {name: p_msgp_ptype, var: p_msgp_ptype}, {name: p_mon_type, var: p_mon_type}, {name: p_iagency, var: p_iagency}, {name: p_permitting_agency, var: p_permitting_agency}, {name: p_isws, var: p_isws}, {name: p_iswss, var: p_iswss}, {name: p_iswssID, var: p_iswss_id}, {name: p_ds1, var: p_ds1}, {name: p_ds2, var: p_ds2}, {name: p_da1, var: p_da1}, {name: p_da2, var: p_da2}, {name: p_MS4, var: p_ms4}, {name: p_ooFN, var: p_oo_fn}, {name: p_ooFNtype, var: p_oo_f_ntype}, {name: p_ooSA, var: p_oo_sa}, {name: p_ooSA1, var: p_oo_sa1}, {name: p_ooCt, var: p_oo_ct}, {name: p_ooSt, var: p_oo_st}, {name: p_ooZip, var: p_oo_zip}, {name: p_fac_ico, var: p_fac_ico}, {name: p_icoo, var: p_icoo}, {name: p_fac_icos, var: p_fac_icos}, {name: p_ejscreen, var: p_ejscreen}, {name: p_alrexceed, var: p_alrexceed}, {name: p_limit_addr, var: p_limit_addr}, {name: p_lat, var: p_lat}, {name: p_long, var: p_long}, {name: p_radius, var: p_radius}, {name: p_ejscreen_over80cnt, var: p_ejscreen_over80cnt}, {name: p_bio_flag, var: p_bio_flag}, {name: p_bio_fac_type, var: p_bio_fac_type}, {name: p_bio_trtmnt_procs, var: p_bio_trtmnt_procs}, {name: p_bio_analy_method_catgry, var: p_bio_analy_method_catgry}, {name: p_bio_total_volume_amt, var: p_bio_total_volume_amt}, {name: p_bio_mgmt_prctce_type, var: p_bio_mgmt_prctce_type}, {name: p_bio_mgmt_prctce_stype, var: p_bio_mgmt_prctce_stype}, {name: p_bio_mgmt_prctce_handler, var: p_bio_mgmt_prctce_handler}, {name: p_bio_mgmt_container, var: p_bio_mgmt_container}, {name: p_bio_mgmt_pathogen, var: p_bio_mgmt_pathogen}, {name: p_bio_mgmt_pathred, var: p_bio_mgmt_pathred}, {name: p_bio_mgmt_vector, var: p_bio_mgmt_vector}, {name: p_bio_mgmt_def_category, var: p_bio_mgmt_def_category}, {name: p_bio_mgmt_deficiencies, var: p_bio_mgmt_deficiencies}, {name: p_bio_vio_code, var: p_bio_vio_code}, {name: p_bio_current_vio, var: p_bio_current_vio}, {name: p_bio_qtrs_in_vio, var: p_bio_qtrs_in_vio}, {name: p_bio_rpt_year, var: p_bio_rpt_year}, {name: p_bio_vio_last_year, var: p_bio_vio_last_year}, {name: p_msgp_rpt_year, var: p_msgp_rpt_year}, {name: p_vio_last_year, var: p_vio_last_year}, {name: queryset, var: queryset}, {name: responseset, var: responseset}, {name: tablelist, var: tablelist}, {name: maplist, var: maplist}, {name: summarylist, var: summarylist}, {name: callback, var: callback}, {name: qcolumns, var: qcolumns}, {name: p_e90_count, var: p_e90_count}, {name: p_e90_years, var: p_e90_years}, {name: p_psc, var: p_psc}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_fn: $p_fn, p_sa: $p_sa, p_sa1: $p_sa1, p_ct: $p_ct, p_co: $p_co, p_fips: $p_fips, p_st: $p_st, p_zip: $p_zip, p_frs: $p_frs, p_reg: $p_reg, p_sic: $p_sic, p_ncs: $p_ncs, p_pen: $p_pen, p_c1lat: $p_c1lat, p_c1lon: $p_c1lon, p_c2lat: $p_c2lat, p_c2lon: $p_c2lon, p_usmex: $p_usmex, p_sic2: $p_sic2, p_sic4: $p_sic4, p_fa: $p_fa, p_ff: $p_ff, p_act: $p_act, p_maj: $p_maj, p_mact: $p_mact, p_fea: $p_fea, p_feay: $p_feay, p_feaa: $p_feaa, p_iea: $p_iea, p_ieay: $p_ieay, p_ieaa: $p_ieaa, p_qiv: $p_qiv, p_iv: $p_iv, p_impw: $p_impw, p_imp_cau_grp: $p_imp_cau_grp, p_imp_pol: $p_imp_pol, p_trep: $p_trep, p_pm: $p_pm, p_pd: $p_pd, p_ico: $p_ico, p_huc: $p_huc, p_pid: $p_pid, p_med: $p_med, p_ysl: $p_ysl, p_ysly: $p_ysly, p_ysla: $p_ysla, p_qs: $p_qs, p_sfs: $p_sfs, p_tribeid: $p_tribeid, p_tribename: $p_tribename, p_tribedist: $p_tribedist, p_pstat: $p_pstat, p_ptype: $p_ptype, p_pcomp: $p_pcomp, p_plimits: $p_plimits, p_pcss: $p_pcss, p_pexp: $p_pexp, p_owop: $p_owop, p_ipfti: $p_ipfti, p_agoo: $p_agoo, p_idt1: $p_idt1, p_idt2: $p_idt2, p_pityp: $p_pityp, p_pfead1: $p_pfead1, p_pfead2: $p_pfead2, p_pfeat: $p_pfeat, p_pccs: $p_pccs, p_pexcd: $p_pexcd, p_psncq: $p_psncq, p_pctrack: $p_pctrack, p_dwd: $p_dwd, p_pt: $p_pt, p_pdwdist: $p_pdwdist, p_pswdpc: $p_pswdpc, p_pswdmp: $p_pswdmp, p_pswpol: $p_pswpol, p_pswcas: $p_pswcas, p_pswparam: $p_pswparam, p_pswvio: $p_pswvio, p_wbd: $p_wbd, p_radwbd: $p_radwbd, p_frswbd: $p_frswbd, p_fntype: $p_fntype, p_pidall: $p_pidall, p_months_last_dmr: $p_months_last_dmr, p_last_dmr_within: $p_last_dmr_within, p_indsw: $p_indsw, p_msgp_ptype: $p_msgp_ptype, p_mon_type: $p_mon_type, p_iagency: $p_iagency, p_permitting_agency: $p_permitting_agency, p_isws: $p_isws, p_iswss: $p_iswss, p_iswss_id: $p_iswss_id, p_ds1: $p_ds1, p_ds2: $p_ds2, p_da1: $p_da1, p_da2: $p_da2, p_ms4: $p_ms4, p_oo_fn: $p_oo_fn, p_oo_f_ntype: $p_oo_f_ntype, p_oo_sa: $p_oo_sa, p_oo_sa1: $p_oo_sa1, p_oo_ct: $p_oo_ct, p_oo_st: $p_oo_st, p_oo_zip: $p_oo_zip, p_fac_ico: $p_fac_ico, p_icoo: $p_icoo, p_fac_icos: $p_fac_icos, p_ejscreen: $p_ejscreen, p_alrexceed: $p_alrexceed, p_limit_addr: $p_limit_addr, p_lat: $p_lat, p_long: $p_long, p_radius: $p_radius, p_ejscreen_over80cnt: $p_ejscreen_over80cnt, p_bio_flag: $p_bio_flag, p_bio_fac_type: $p_bio_fac_type, p_bio_trtmnt_procs: $p_bio_trtmnt_procs, p_bio_analy_method_catgry: $p_bio_analy_method_catgry, p_bio_total_volume_amt: $p_bio_total_volume_amt, p_bio_mgmt_prctce_type: $p_bio_mgmt_prctce_type, p_bio_mgmt_prctce_stype: $p_bio_mgmt_prctce_stype, p_bio_mgmt_prctce_handler: $p_bio_mgmt_prctce_handler, p_bio_mgmt_container: $p_bio_mgmt_container, p_bio_mgmt_pathogen: $p_bio_mgmt_pathogen, p_bio_mgmt_pathred: $p_bio_mgmt_pathred, p_bio_mgmt_vector: $p_bio_mgmt_vector, p_bio_mgmt_def_category: $p_bio_mgmt_def_category, p_bio_mgmt_deficiencies: $p_bio_mgmt_deficiencies, p_bio_vio_code: $p_bio_vio_code, p_bio_current_vio: $p_bio_current_vio, p_bio_qtrs_in_vio: $p_bio_qtrs_in_vio, p_bio_rpt_year: $p_bio_rpt_year, p_bio_vio_last_year: $p_bio_vio_last_year, p_msgp_rpt_year: $p_msgp_rpt_year, p_vio_last_year: $p_vio_last_year, queryset: $queryset, responseset: $responseset, tablelist: $tablelist, maplist: $maplist, summarylist: $summarylist, callback: $callback, qcolumns: $qcolumns, p_e90_count: $p_e90_count, p_e90_years: $p_e90_years, p_psc: $p_psc
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Clean Water Act (CWA) Facility Search Service
#
# POST /cwa_rest_services.get_facilities
# Returns: record<Results: record<BadSystemIDs: string, BioCVRows: string, BioV3Rows: string, CVRows: string, FEARows: string, Facilities: list<record>, INSPRows: string, IndianCountryRows: string, InfFEARows: string, MapOutput: record<IconBaseURL: string, MapData: list, PopUpBaseURL: string, QueryID: string>, Message: string, PageNo: string, QueryID: string, QueryRows: string, SVRows: string, TotalPenalties: string, V3Rows: string, Version: string, VioLast4QRows: string>>
export def "post-cwa-rest-services-get-facilities" [
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
  --p-fn: string # Facility Name Filter. Enter one or more case-insensitive facility names to filter results. Provide multiple values as a comma-delimited list. See p_fntype for additional modifiers.
  --p-sa: string # Facility street address. Enter a complete or partial street address.
  --p-sa1: string # Facility street address. Enter a complete or partial street address. Note that p_sa1 is culmulative with p_sa.
  --p-ct: string # Facility City Filter. Enter a single case-insensitive city name to filter results.
  --p-co: string # Facility County Filter. Provide a single county name in combination with a state value provided via p_st.
  --p-fips: string # FIPS Code Filter. Enter a single 5-character Federal Information Processing Standards (FIPS) state + county value to restrict results. E.g. to limit results to Kenosha County, Wisconsin, use 55059.
  --p-st: string # Facility State and State-Equivalent Filter. Provide one or more USPS postal abbreviations for states and state-equivalents to filter results. Provide multiple values as a comma-delimited list.
  --p-zip: string # 5-Digit ZIP Code Filter. Provide one or more 5-digit postal zip codes to filter results. May contain multiple comma-separated values.
  --p-frs: string # Facility Registry Service ID Filter. Enter a single 12-digit FRS identifier to filter results.
  --p-reg: string@p-reg-completer # EPA Region Filter. Provide a single value of 01 thru 10 to restrict results to a single EPA region.
  --p-sic: string # Standard Industrial Classification (SIC) Code Filter. Enter a single 4-digit SIC Code to filter results. If more complex filtering is required, use p_sic2 and p_sic4.
  --p-ncs: string # North American Industry Classification System Filter. Enter two to six digits to filter results to facilities having matching NAICS codes. Digits less than six will match to all codes beginning with the provided values.
  --p-pen: string # Last Penality Date Qualifier Filter. Enter one of the following: - NEVER = No Penalties - ANY = Any Penalty - LEXX = Less than or equal to XX months. Provide a number in place of XX, e.g. "LE5" for a facility with a penalty within previous 5 months. - GTXX = Greater than XX months. Provide a number in place of XX, eg. GT12, for a facility with the last penalty greater than 12 months ago.
  --p-c1lat: float # In decimal degrees. Latitude of 1st corner of box that bounds the resulting facilities. The latitude and longitude of both corners of the bounding box must be provided.
  --p-c1lon: float # In decimal degrees. Longitude of 1st corner of box that bounds the resulting facilities. The latitude and longitude of both corners of the bounding box must be provided.
  --p-c2lat: float # In decimal degrees. Latitude of 2nd corner of box that bounds the resulting facilities. The latitude and longitude of both corners of the bounding box must be provided.
  --p-c2lon: float # In decimal degrees. Longitude of 2nd corner of box that bounds the resulting facilities. The latitude and longitude of both corners of the bounding box must be provided.
  --p-usmex: string@p-usmex-completer # US-Mexico Border Flag. Enter Y/N to restrict searches to facilities located within 100KM of the border.
  --p-sic2: string # Standard Industrial Classification (SIC) Code Filter Alternate 2. Enter a wild-card search against SIC codes. A final wild-card is always present allowing "22" to match all SIC codes beginning with 22. Use the "%" character within strings to match any SIC values with the pattern. For example, "2%21" matches 2021, 2121, 2221, etc.
  --p-sic4: string # Standard Industrial Classification (SIC) Code Filter Alternate 3. Enter the first 2, 3 or 4 SIC code digits to filter results to facilities having those code prefixes. As this alternative does not utilize an index, p_sic2 will generally be quicker.
  --p-fa: string # Federal Agency. 1 character or 5-character values; may contain multiple comma-separated values. ALL will retrieve all facilities where the federal agency code is not null. Use the Federal Agencies lookup service to obtain a list of values.
  --p-ff: string@p-ff-completer # Federal Facility Indicator Flag. Enter Y to restrict searches to federal facilities.
  --p-act: string # Active Permits/Facilities Flag. Provide Y or N to filter results to facilities with active permits. A Y will select ICIS NPDES permits with a status of effective, continued, or expired.
  --p-maj: string@p-maj-completer # Major Facility Flag. Enter Y to restrict results to Major facilities only.
  --p-mact: string # CAA Maximum Achievable Control Technology (MACT) Subpart codes (alpha ID between 1 and 7 characters) applicable to the facility.
  --p-fea: string@p-fea-completer # Formal Enforcement Actions [within / not within] specified date range indicator. The date range is determined by parameters p_fead1 and p_fead2 or by parameter p_feay. - W = within date range - N = not within date range
  --p-feay: float@p-feay-completer # Years (1 to 5) Range. This value is used to create a date range for Formal Enforcement Actions (FEA). Used along with p_fea (which indicates whether to look within or outside of the date range) to find FEAs within (or not within) the number of years specified.
  --p-feaa: string@p-feaa-completer # Agency associated with Formal Enforcement Actions: - E = EPA - S = State - A = All
  --p-iea: string@p-iea-completer # Informal Enforcement Actions [within / not within] specified date range. The date range is determined by parameters p_iead1 and p_iead2 or by parameter p_ieay. - W = within date range - N = not within date range
  --p-ieay: float@p-ieay-completer # Years (1 to 5) Range. This value is used to create a date range for Informal Enforcement Actions (IEA). Used along with p_iea (which indicates whether to look within or outside of the date range) to find IEAs within (or not within) the number of years specified.
  --p-ieaa: string@p-ieaa-completer # Agency associated with Informal Enforcement Actions. If left blank, both agencies are included. - E = EPA - S = State
  --p-qiv: string@p-qiv-completer # Quarters in Noncompliance Limiter. Enter a coded value to limit results to facilities with given quarter of noncompliance. - Z = Zero quarters in noncompliance. - GEXX = Replacing XX with a numeric value, that number of quarterd or more in noncompliance. - GTXX = Replacing XX with a numeric value, more than that number of quarters in noncompliance.
  --p-iv: string # Facility has a violation status of 'In Viol' during any of the selected quarters. Range: Fiscal Year 2020 Quarter 2 to Fiscal Year 2017 Quarter 2 Multiple values are comma delimited. |||||| Fiscal Years |||||| - FY2020 or FY20 or 2020 or 20 - FY2019 or FY19 or 2019 or 19 - FY2018 or FY18 or 2018 or 18 - FY2017 or FY17 or 2017 or 17 ||||| Fiscal Quarters ||||| - FY2020Q2 or FY20Q2 or 20202 or 202 or 13 - FY2020Q1 or FY20Q1 or 20201 or 201 or 12 - FY2019Q4 or FY19Q4 or 20194 or 194 or 11 - FY2019Q3 or FY19Q3 or 20193 or 193 or 10 - FY2019Q2 or FY19Q2 or 20192 or 192 or 9 - FY2019Q1 or FY19Q1 or 20191 or 191 or 8 - FY2018Q4 or FY18Q4 or 20184 or 184 or 7 - FY2018Q3 or FY18Q3 or 20183 or 183 or 6 - FY2018Q2 or FY18Q2 or 20182 or 182 or 5 - FY2018Q1 or FY18Q1 or 20181 or 181 or 4 - FY2017Q4 or FY17Q4 or 20174 or 174 or 3 - FY2017Q3 or FY17Q3 or 20173 or 173 or 2 - FY2017Q2 or FY17Q2 or 20172 or 172 or 1
  --p-impw: string@p-impw-completer # Discharging into Impaired Waters Flag. Enter Y to limit results to facilities with discharge to waterbodies listed as impaired in the ATTAINS database.
  --p-imp-cau-grp: string@p-imp-cau-grp-completer # Facility is discharging a pollutant group causing a waterbody to be impaired. Enter 1 through 34 (the internal number of the pollutant group); or enter a partial name such as Dioxin,Temp,tUrBidity.
  --p-imp-pol: string@p-imp-pol-completer # Facility is discharging pollutants that are potentially contributing to the impairment of local waterbodies according to the ATTAINS database.
  --p-trep: string@p-trep-completer # Current Toxics Release Inventory (TRI) Reporter Limiter. Enter one of the following codes to limit results. - CURR = Current TRI reporter. - NONCURR = Has reported to TRI in the past but not for the current reporting year.
  --p-pm: string@p-pm-completer # Percent Minority Population Limiter. Enter a value to restrict results to facilities with a given percentage of minority population within 3-mile radius. - NONE = 0% - GT5 = greater than 5% - GT10 = greater than 10% - GT25 = greater than 25% - GT50 = greater than 50% - GT75 = greater than 75%
  --p-pd: string@p-pd-completer # Population Density Limiter (per sq mile). Enter a value to limit results to facilities located in area of a given population density. - NONE = 0 population density per square mile - GT100 = More than 100 population density per square mile - GT500 = More than 500 population density per square mile - GT1000 = More than 1000 population density per square mile - GT5000 = More than 5000 population density per square mile - GT10000 = More than 10000 population density per square mile - GT20000 = More than 20000 population density per square mile
  --p-ico: string@p-ico-completer # Indian Country Flag. Enter a "Y" or "N" to restrict searches to facilities inside or outside Indian Country.
  --p-huc: string # 2-, 4-, 6-, or 8-character watershed code. May contain multiple comma-separated values.
  --p-pid: string # Nine-digit permit IDs. May contain up to 2000 comma-separated values.
  --p-med: string@p-med-completer # Filter Results by Media. - A = Air - M = RMP (Risk Management Plan) - R = RCRA (Hazardous Waste) - S = SDWA (Public Drinking Water Systems) - ALL = Air and RCRA and Water
  --p-ysl: string@p-ysl-completer # Last Facility Inspection [within / not within] Specified Date Range Indicator. The date range is determined by parameters p_idt1 and p_idt2 or by parameter p_ysly. - W = within date range - N = not within date range
  --p-ysly: float@p-ysly-completer # Number of years (1 to 5) since last facility inspection. A value of 1 means that it has been inspected within the year.
  --p-ysla: string@p-ysla-completer # Facility Last Inspection Code Filter. If left blank, both agencies are included. Enter a value to limit results: - E = EPA - S = State
  --p-qs: string # Quick Search. Allows entry for city, state, and/or zip code.
  --p-sfs: string # Single Facility Search Filter. Provide a facility name or program system identifier to limit results. For the all data search, the FRS registry identifier is also searched.
  --p-tribeid: float # Numeric code for tribe (or list of tribes).
  --p-tribename: string # Tribe Name Filter. Enter a single tribe name to filter results.
  --p-tribedist: float # Proximity to tribal land limiter. Enter an amount of mile between 0 and 25 to filter results. This parameter is only evaluated if p_tribeid is populated.
  --p-pstat: string # Permit Status Filter. Enter one or more of the following codes. Provide multiple values as a comma-delimited list. - EFF = Effective - EXP = Expired - PND = Pending - TRM = Terminated - RET = Retired - NON = Not Needed - ADC = Admin Continued
  --p-ptype: string # Permit Type Filter. Enter one or more code values to filter results. Provide multiple values as a comma-delimited list. - NPD = NPDES Individual Permit - NGP = NPDES Master General Permit - GPC = General Permit Covered Facility - SNN = State Issued Master General Permit (Non-NPDES) - IIU = Individual IU Permit (Non-NPDES) - SIN = Individual State Issued Permit (Non-NPDES) - APR = Associated Permit Record - UFT = Unpermitted Facility
  --p-pcomp: string # Permit Component Code Filter. Enter one or more codes to filter results. Provide multiple values as a comma-delimited list. - PRE = Pretreatment - CAF = CAFO - CSO = CSO - POT = POTW - BIO = Biosolids - SWS = Storm Water Small MS4s - SWM = Storm Water Medium/Large MS4s - SWI = Storm Water Industrial - SWC = Storm Water Construction
  --p-plimits: string@p-plimits-completer # Permit Limits Present Flag. Enter Y to limit results to facilities have present permit limits.
  --p-pcss: string@p-pcss-completer # Combined Sewer Systems Outflows Limiter. Enter one of the following to limit results to facilities having the given count of CSS outflows. - ALL = returns all facilities, regardless of the number of outflows. - GE1 = returns facilities with one or more outflows. - GE10 = returns facilities with ten or more outflows. - GE50 = returns facilities with fifty or more outflows.
  --p-pexp: string@p-pexp-completer # Permit Expired or Administratively Continued Limiter. Enter one of the following values to filter results. - EXP = limit results to facilities with permits expired or administratively continued. - EXPLE1YR = limit resuls to facilities with permits expired administratively continued within the past year. - EXPGT1YR = limit resuls to facilities with permits expired administratively continued more than a year ago.
  --p-owop: string@p-owop-completer # Owner/Operator code filter. Enter one of the following values to restrict results. - Federal = Federal facilities regulated under the NPDES program. - POTW = Publicly owned treatment works. Treatment works that are owned by a State, Tribe, or municipality. - Non-POTW = Non-publicly owned treatment works. Often referred to as "non-municipals" or "industrials".
  --p-ipfti: string
  --p-agoo: string@p-agoo-completer # Indicates whether to AND or OR the Owner/Operator parameter (p_owop) and the federal agency code (p_fa) parameters.
  --p-idt1: string # Beginning of date range of most recent facility inspection.
  --p-idt2: string # End of date range of most recent facility inspection.
  --p-pityp: string # Inspection Type Code. See ICIS Compliance Monitor Types lookup serivce for a list of available codes and descriptions.
  --p-pfead1: string # Formal Enforcement Action Date Range Start. Enter a date in MM/DD/YYYY format to set the start of the range for filtering by recent Formal Enforcement Action (FEA) taken against the facility within the last five years.
  --p-pfead2: string # Formal Enforcement Action Date Range End. Enter a date in MM/DD/YYYY format to set the end of the date range for filtering by recent Formal Enforcement Action (FEA) taken against the facility within the last five years.
  --p-pfeat: string # Formal Enforcement Action (FEA) Code Filter. Enter one or more three-letter FEA codes to restrict results to facilities with these attributes. Use p_fead1 and p_fead2 parameters to further restrict this filter by entering a date range. Provide multiple codes as a comma-delimited list.
  --p-pccs: string # Current Compliance Status: ||||||||||||||||||||||||||| Significant Noncompliance (SNC) ||||||||||||||||||||||||||| - SNC = E, S, X, T, D - E�= E(EffViol) - S�= S(CSchVio) - X = X(EffNMth) - T = T(CSchRpt) - D�= D(DMR NR) ||||||||||||||||||||||||||| Noncompliance (NC) ||||||||||||||||||||||||||| - NC = N, V - N�= N(RptViol) - V�= V(NonRNCV) ||||||||||||||||||||||||||| New Violations (PQV) ||||||||||||||||||||||||||| - PQV = New Violations (13th Quarter) ||||||||||||||||||||||||||| No Violations (NV) ||||||||||||||||||||||||||| - NV = R, P, M, U, W , Blank, and No New Violations (no PQV) - R�= R(Resolvd) - P�= P(ResPend) - M�= C(Manual) - U = U(N/A) - W = W(N/A) - Blank = (null) May contain multiple comma-separated values.
  --p-pexcd: string@p-pexcd-completer # 3-Year Effluent Exceedances Limiter. Enter a value to restrict results to facilities with the given amount of exceedances in the past 3 years. - 0 = facilities with no exceedances - GE0 = facilities with one or more exceedances - GE10 = facilities with ten or more exceedances - GE50 = facilities with fifty or more exceedances - GE100 = facilities with one hundred or more exceedances
  --p-psncq: string@p-psncq-completer # Quarters in Significant Noncompliance Limiter. Enter a coded value to limit results to facilities with given quarter of significant noncompliance. - Z = Zero quarters in significant noncompliance. - GEXX = Replacing XX with a numeric value, that number of quarterd or more in significant noncompliance. - GTXX = Replacing XX with a numeric value, more than that number of quarters in significant noncompliance.
  --p-pctrack: string@p-pctrack-completer # Compliance Tracking Limiter. Provide a keyword to indicate the extent to which data is being entered and effluent exceedances are being identified. - Off - Partial - On
  --p-dwd: string@p-dwd-completer # Direct Water Discharges. Pounds of toxic chemicals released directly to surface water as reported to the Toxics Release Inventory.
  --p-pt: string@p-pt-completer # POTW Transfers. Pounds of toxic chemicals transferred to a Publicly Operated Treatment Works (POTW) as reported to the Toxics Release Inventory.
  --p-pdwdist: string@p-pdwdist-completer # Distance (in miles) to downstream drinking water intake.
  --p-pswdpc: string # Pollutant Category Code: Values: WTR for Water, AIR for Air
  --p-pswdmp: string@p-pswdmp-completer # Used to determine limit begin and end dates for surface water discharges. Number represents years from current date.
  --p-pswpol: string # For CWA, pollutant names for surface water discharges. for Drinking Water, SDWIS Violation contaminant codes for unaddressed violations that have occurred in the last 3 years. May contain multiple comma-separated values.
  --p-pswcas: string # CAS numbers for surface water discharges. May contain multiple comma-separated values.
  --p-pswparam: string # Parameter codes for surface water discharges. May contain multiple comma-separated values.
  --p-pswvio: string@p-pswvio-completer # Used in conjuction with parameters p_pswpol and p_pswparam, indicates whether search should only include pollutants with violations.
  --p-wbd: string # 2-, 4-, 6-, 8-, 10-, or 12-character watershed (WBD from the USGS Watershed Boundary Dataset). May contain multiple comma-separated values. Uses the FRS Best Pick Coordinate to obtain the WBD12 Huc value.
  --p-radwbd: string # 2-, 4-, 6-, 8-, 10-, or 12 character watershed (WBD from the USGS Watershed Boundary Dataset). May contain multiple comma-separated values. Will search against WBD values otained by "reach indexing" NPDES permits against the medium resolution National Hydrography Dataset.
  --p-frswbd: string # Works exactly the same as the p_wbd parameter. 2-, 4-, 6-, 8-, 10-, or 12-character watershed (WBD from the USGS Watershed Boundary Dataset). May contain multiple comma-separated values. Uses the FRS Best Pick Coordinate to obtain the WBD12 Huc value.
  --p-fntype: string@p-fntype-completer # Controls type of text search performed on facility name with parameter p_fn. - EXACT = Find facilities having the exact provided name(s). - BEGINS = Find facilities with names starting with the provided term(s). - ALL = Find facilities using Oracle text search terms. - CONTAINS =
  --p-pidall: string@p-pidall-completer # Controls whether search is restricted to existing system. Y means the search will match the p_pid parameter against all associated permits (AIR, RCRA, SDWIS, etc).
  --p-months-last-dmr: float # The number of months since the last Discharge Monitoring Report has been submitted.
  --p-last-dmr-within: string@p-last-dmr-within-completer # W value returns facilities that have submitted DMRs within the number of months specified by p_months_last_dmr. An N value returns facilities that have not submitted a DMR within the specified number of months.
  --p-indsw: string@p-indsw-completer # Industrial Stormwater Permit Flag. Enter a Y or N to filter results by this type of permit.
  --p-msgp-ptype: string@p-msgp-ptype-completer # Multi-Sector General Purpose Permit Type. Enter a value to filter results by MSGP Permit Type. - NOI = Notice of Intent - NOE = No Exposure Certification
  --p-mon-type: string@p-mon-type-completer # For use with the Industrial Stormwater search only. Valid values are BENCHGS fro Benchmark (Alert Limit) G2 Ore, BENCH for Benchmark (Alert Limit), and ELG fro Effluent Limitation Guidelines(ELG)(Effluent Limit).
  --p-iagency: string # Issuing Agency Limiter. Enter a single value to filter results by the issuing agency, e.g. "State" or "EPA".
  --p-permitting-agency: string
  --p-isws: string # Multi-Sector General Purpose Permit Subsector Individual Identifier. Enter a value to filter results.
  --p-iswss: string # Multi-Sector General Purpose Permit Subsector Group Code. Enter a value to filter results.
  --p-iswss-id: string # Multi-Sector General Purpose Permit Sector Code. Enter a value to filter results.
  --p-ds1: string # Submitted Date Filter Start. To filter by the date of submission, enter a start date here and an end date in the p_ds2 parameter. Both dates are required for filtering.
  --p-ds2: string # Submitted Date Filter End. To filter by the date of submission, enter an end date here and a start date in the p_ds1 parameter. Both dates are required for filtering.
  --p-da1: string # Active Date Filter Start. To filter by the active date, enter a start date here and an end date in the p_da2 parameter. Both dates are required for filtering.
  --p-da2: string # Active Date Filter End. To filter by the active date, enter an end date here and a start date in the p_da1 parameter. Both dates are required for filtering.
  --p-ms4: string@p-ms4-completer # Municipal Separate Storm Water Sewer (MS4) Permit Flag. Enter a Y or N to filter results by this type of permit.
  --p-oo-fn: string # Owner/Operator Name. Enter the owner/operator name of the facility.
  --p-oo-f-ntype: string@p-oo-f-ntype-completer # Owner/Operator Name Multiple Selection Evaluator.
  --p-oo-sa: string # Owner/Operator Address. Enter the address of the owner/operator of the facility.
  --p-oo-sa1: string # Owner/Operator Address Line 2. Enter the line 2 address of the owner/operator of the facility.
  --p-oo-ct: string # Owner/Operator City. Enter the city where the owner/operator of the facility is located.
  --p-oo-st: string # Owner/Operator State. Enter the standardized postal state code where the owner/operator of the facility is located.
  --p-oo-zip: string # Owner/Operator Zip Code. Enter the postal zip code where the owner/operator of the facility is located.
  --p-fac-ico: string@p-fac-ico-completer # FRS tribal land code flag. Enter "Y" or "N" to include or exclude facilities based on FRS tribal land code.
  --p-icoo: string # Indian country search and/or flag. Enter "Y" to set indian country search conditions to return any results found using p_ico, p_fac_ico or p_fac_icoo. Otherwise only results matching all provided p_ico, p_fac_ico or p_fac_icoo conditions will be returned.
  --p-fac-icos: string # FRS tribal land spatial flag. Enter "Y" or "N" to include or exclude facilities based on FRS tribal land spatial flag.
  --p-ejscreen: string # Enter "Y" to limit facilities to Census block groups where one of more Environmental Justice indexes above 80th percentile.
  --p-alrexceed: float # Alert Limits Exceedences Limiter. Enter a numeric value to restrict results to facilities having the given amount or more of alert limits exceedances.
  --p-limit-addr: string@p-limit-addr-completer # Limit Address Search Flag. Enter Y to restrict facility searches to native data source only.
  --p-lat: float # Latitude location in decimal degrees.
  --p-long: float # Longitude location in decimal degrees.
  --p-radius: float # Spatial Search Radius. Enter a radius up to 100 miles in which to spatially search for facilities.
  --p-ejscreen-over80cnt: string@p-ejscreen-over80cnt-completer # The number of Environmenmt Justice Indicators above the 80th percentile. Valid values are 1 through 11.
  --p-bio-flag: string # A Y value will select all biosolid-related permits.
  --p-bio-fac-type: string # The code indicating the reporting obligation reason: - POT = A POTW with a design flow rate equal to or greater than one million gallons per day - CLI = A Class I Sludge Management Facility as defined in 40 CFR 503.9 - PPL = A POTW that serves 10,000 people or more - OTH = Otherwise required to report (e.g., permit condition, enforcement action) - NOA = None of the above
  --p-bio-trtmnt-procs: string # The biosolids or sewage sludge treatment process or processes at the facility: - AER = Aerobic Digestion - AIR = Air Drying (or Sludge Drying Beds) - ANA = Anaerobic Digestion - COD = Beta Ray Irradiation - COM = Lower Temperature Composting - DEW = Pasteurization - DIS = Gamma Ray Irradiation - HEA = Heat Drying (e.g., Flash Dryer, Spray Dryer, Rotary Dryer) - HET = Heat Treatment (Liquid Sewage Sludge Heated to 356 Deg. F/180 Deg. C or Higher for 30 min.) - HTC = Higher Temperature Composting - MET = Methane or Biogas Capture and Recovery - OTH = Other Treatment Process - PRE = Preliminary Operations (e.g., Sludge Grinding, Degritting, Blending) - SLU = Sludge Lagoon - STA = Lime Stabilization - THE = Temporary Sludge Storage (Sewage Sludge Stored on Land 2 Years or Less, Not in Sewage Sludge Unit) - THI = Thickening (Gravity and/or Flotation Thickening, Centrifugation, Belt Filter Press, Vacuum Filter) - THM = Thermophilic Aerobic Digestion - UND = Long-Term Sludge Storage (Sewage Sludge Stored on Land 2 Years or More, not in Sewage Sludge Unit)"
  --p-bio-analy-method-catgry: string # The unique code for the category of the analytic methods used by the facility to analyze regulated parameters (including enteric viruses, fecal coliforms, helminth ova, and Salmonella sp.) at the facility: - PAT = Pathogens - MET = Metals - NIT = Nitrogen Compounds - OTH = Other Analytes
  --p-bio-total-volume-amt: string # Total annual amount (in dry metric tons) of biosolids or sewage sludge generated at the facility. - EQ0 = 0 - IN0_1 = GT 0 but LT 1 - IN0_289 = GT 0 but LT 290 MT/year - IN290_1499 = GE 290 but LT 1500 MT/year - IN1500_14999 = GE 1500 but LT 15,000 - GE15000 = GE 15,000
  --p-bio-mgmt-prctce-type: string # The unique code that identifies the type of biosolids or sewage sludge management practice (e.g., land application, surface disposal, incineration) used by the facility. The facility will separately report the management practice for each biosolids or sewage sludge form and pathogen class. This data element will also identify the management practices used by surface disposal site owners/operators (see 40 CFR 503.24): - BIN = Incineration - BLN = Land Application - BOT = Other Management Practice - BSD = Surface Disposal
  --p-bio-mgmt-prctce-stype: string # This is the code indicating additional detail about the type of Management Practice used for a volume of Biosolids or Sewage Sludge: - ADV = Advanced Alkaline Stabilized Biosolids Distribution & Marketing - AGR = Agricultural Land Application - COM = Distribution and Marketing - Compost - DEE = Deep-well Injection Disposal - DIS = Disposal in a Municipal Landfill (under 40 CFR 258) - DMO = Distribution and Marketing - Other - HEA = Heat Dried Biosolids Distribution & Marketing - OTL = Other Land Application Management Practice Detail - OTO = Other Management Practice Detail - RSA = Reclamation Site Application - SEN = Sent to Cement Kiln for Use as Alternative Energy - STO = Storage - UIC = Use in Construction - UPS = Used in Production of Syngas - USE = Use as Daily Cover for Municipal Landfill (under 40 CFR 258)
  --p-bio-mgmt-prctce-handler: string # This is the code indicating the type of Biosolids or Sewage Sludge handlers/preparers. - OWN = Owner or Operator - OFF = Off-Site Third-Party Handler or Preparer
  --p-bio-mgmt-container: string # The code that identifies the nature of each biosolids and sewage sludge material generated by the facility in terms of whether the material is a biosolid or sewage sludge and whether the material is ultimately conveyed off-site in bulk or in bags. The facility separately reports the form for each biosolids or sewage sludge management practice or practices used by the facility and pathogen class: - BUL = Bulk - BAG = Bag or Container
  --p-bio-mgmt-pathogen: string # This code identifies the pathogen class [e.g., Class A, Class B, Not Applicable (Incineration)] for biosolids or sewage sludge generated by the facility. The facility will separately report the pathogen class for each biosolids or sewage sludge management practice used by the facility and by each biosolids or sewage sludge form. It also is used to filter applicable Pathogen Reduction and Vector Attraction Reduction Options as well as Land Application Management Practice Deficiencies. Only reqired for some of the mgmt. practice types: - AAA = Class A - AEQ = Class A EQ (sale/give away) - BBB = Class B - NAP = Not Applicable (Incineration)
  --p-bio-mgmt-pathred: string # This is the description of the option used by the facility to control pathogen for a Biosolids Management Practice: - A1 = Class A - Alternative 1: Time/Temperature - A2 = Class A - Alternative 2: pH/Temperature/Percent Solids - A3 = Class A - Alternative 3: Test Enteric Viruses and Helminth ova; Operating Parameters - A4 = Class A - Alternative 4: Test Enteric Viruses and Helminth ova; No New Solids - A51 = Class A - Alternative 5: PFRP 1: Composting - A52 = Class A - Alternative 5: PFRP 2: Heat Drying - A53 = Class A - Alternative 5: PFRP 3: Liquid heat treatment - A54 = Class A - Alternative 5: PFRP 4: Thermophilic Aerobic Digestion (ATAD) - A55 = Class A - Alternative 5 PFPR 5: Beta Ray Irradiation - A56 = Class A - Alternative 5 PFPR 6: Gamma Ray Irradiation - A57 = Class A - Alternative 5: PFRP 7: Pasteurization - A6 = Class A - Alternative 6: PFRP Equivalency - B1 = Class B - Alternative 1: Fecal Coliform Geometric Mean - B21 = Class B - Alternative 2 PSRP 1: Aerobic Digestion - B22 = Class B - Alternative 2 PSRP 2: Air Drying - B23 = Class B - Alternative 2 PSRP 3: Anaerobic Digestion - B24 = Class B - Alternative 2 PSRP 4: Composting - B25 = Class B - Alternative 2 PSRP 5: Lime Stabilization - B3 = Class B - Alternative 3: PSRP Equivalency - PH = pH Adjustment (Domestic Septage)
  --p-bio-mgmt-vector: string # The unique code that identifies the option used by the facility for vector attraction reduction. See a listing of these vector attraction reduction options at 40 CFR 503.33(b)(1) through (11). The facility will separately report the vector attraction reduction options for each biosolids or sewage sludge management practice used by the facility and by each biosolids or sewage sludge form as well as by each biosolids or sewage sludge pathogen class: - VR1 = Option 1 - Volatile Solids Reduction - VR2 = Option 2 - Bench-Scale Volatile Solids Reduction (Anaerobic Bench Test) - VR3 = Option 3 - Bench-Scale Volatile Solids Reduction (Aerobic Bench Test w/ Percent Solids - 2% or Less) - VR4 = Option 4 - Specific Oxygen Uptake Rate - VR5 = Option 5 - Aerobic Processing (Thermophilic Aerobic Digestion/Composting) - VR6 = Option 6 - Alkaline Treatment - VR7 = Option 7 - Drying (Equal to or Greater than 75 Percent) - VR8 = Option 8 - Drying (Equal to or Greater than 90 Percent) - VR9 = Option 9 - Sewage Sludge Injection - V10 = Option 10 - Sewage Sludge Timely Incorporation into Land - V11 = Option 11 - Sewage Sludge Covered at the End of Each Operating Day
  --p-bio-mgmt-def-category: string # This is the code indicating the type of NPDES special regulatory program deficiency: - INC = Biosolids Incineration - LNA = Biosolids Land Application - LNB = Biosolids Land Application - Pathogen Class B - OTB = Biosolids Other Management Practice - SFD = Biosolids Surface Disposal
  --p-bio-mgmt-deficiencies: float # The number of times noncompliance was reported by the facility in the last 3 years. The results returned will include facilities whose number of reported noncompliance events is greater than or equal to the number entered.
  --p-bio-vio-code: string # The Biosolids Single Event Violation Code. Enter one or mode codes.
  --p-bio-current-vio: string@p-bio-current-vio-completer # Indicator of whether the facility is currently in violation for biosolids under the Clean Water Act, in the 12th or 13th quarter: - Y = Yes - N = No
  --p-bio-qtrs-in-vio: float # The number of quarters, in the last three years, where the facility was in violation for a biosolids violation type. The results returned will include facilities whose number of quarters with violations is greater than or equal to the number entered.
  --p-bio-rpt-year: string # The last year that the permittee submitted an annual Biosolids report. Valid values are NONE and any year greater or equal to 2016.
  --p-bio-vio-last-year: string@p-bio-vio-last-year-completer # Identifies if a biosolids violation has occured in the last year. Valid values are Y and N.
  --p-msgp-rpt-year: string # The last year that a MSGP report was submitted for the permit. Valid values are "NONE" and any year Greater or Eqal to 2015.
  --p-vio-last-year: string@p-vio-last-year-completer # Identifies if a permit violation has occured in the last year. Valid values are Y and N.
  --queryset: float # Query Limiter. Enter a value to limit the number of records returned for each query. Value cannot exceed 70,000.
  --responseset: float # Response Set Limiter. Enter a value to limit the number of records per page. Value cannot exceed 1,000.
  --tablelist: string@tablelist-completer # Table List Flag. Enter a Y to display the first page of facility results.
  --maplist: string@maplist-completer # Map List Flag. Provide a Y to return mappable coordinates representing the full geographic extent of the queryset (all facilities that met the selection criteria).
  --summarylist: string@summarylist-completer # Summary List Flag. Enter a Y to return a list of summary statistics based on the parameters submitted to the query service.
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
  --qcolumns: string # Used to customize service output. A list of comma-separated column IDs of output objects that will be returned in the service query object or download. Use the metadata service endpoint for a complete list of Ids and definitions.
  --p-e90-count: float # Number of E90 Exceedances. Identifies water permits with a number of E90 (Effluient Exceedances) >= the value provided for the last number of years provided by the p_e90_years value.
  --p-e90-years: float # Number of years for the p_e90_count search. Identified the past number of years to be used for the p_e90_count search.
  --p-psc: string # Point Source Category.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/cwa_rest_services.get_facilities"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: p_fn, var: p_fn}, {name: p_sa, var: p_sa}, {name: p_sa1, var: p_sa1}, {name: p_ct, var: p_ct}, {name: p_co, var: p_co}, {name: p_fips, var: p_fips}, {name: p_st, var: p_st}, {name: p_zip, var: p_zip}, {name: p_frs, var: p_frs}, {name: p_reg, var: p_reg}, {name: p_sic, var: p_sic}, {name: p_ncs, var: p_ncs}, {name: p_pen, var: p_pen}, {name: p_c1lat, var: p_c1lat}, {name: p_c1lon, var: p_c1lon}, {name: p_c2lat, var: p_c2lat}, {name: p_c2lon, var: p_c2lon}, {name: p_usmex, var: p_usmex}, {name: p_sic2, var: p_sic2}, {name: p_sic4, var: p_sic4}, {name: p_fa, var: p_fa}, {name: p_ff, var: p_ff}, {name: p_act, var: p_act}, {name: p_maj, var: p_maj}, {name: p_mact, var: p_mact}, {name: p_fea, var: p_fea}, {name: p_feay, var: p_feay}, {name: p_feaa, var: p_feaa}, {name: p_iea, var: p_iea}, {name: p_ieay, var: p_ieay}, {name: p_ieaa, var: p_ieaa}, {name: p_qiv, var: p_qiv}, {name: p_iv, var: p_iv}, {name: p_impw, var: p_impw}, {name: p_imp_cau_grp, var: p_imp_cau_grp}, {name: p_imp_pol, var: p_imp_pol}, {name: p_trep, var: p_trep}, {name: p_pm, var: p_pm}, {name: p_pd, var: p_pd}, {name: p_ico, var: p_ico}, {name: p_huc, var: p_huc}, {name: p_pid, var: p_pid}, {name: p_med, var: p_med}, {name: p_ysl, var: p_ysl}, {name: p_ysly, var: p_ysly}, {name: p_ysla, var: p_ysla}, {name: p_qs, var: p_qs}, {name: p_sfs, var: p_sfs}, {name: p_tribeid, var: p_tribeid}, {name: p_tribename, var: p_tribename}, {name: p_tribedist, var: p_tribedist}, {name: p_pstat, var: p_pstat}, {name: p_ptype, var: p_ptype}, {name: p_pcomp, var: p_pcomp}, {name: p_plimits, var: p_plimits}, {name: p_pcss, var: p_pcss}, {name: p_pexp, var: p_pexp}, {name: p_owop, var: p_owop}, {name: p_ipfti, var: p_ipfti}, {name: p_agoo, var: p_agoo}, {name: p_idt1, var: p_idt1}, {name: p_idt2, var: p_idt2}, {name: p_pityp, var: p_pityp}, {name: p_pfead1, var: p_pfead1}, {name: p_pfead2, var: p_pfead2}, {name: p_pfeat, var: p_pfeat}, {name: p_pccs, var: p_pccs}, {name: p_pexcd, var: p_pexcd}, {name: p_psncq, var: p_psncq}, {name: p_pctrack, var: p_pctrack}, {name: p_dwd, var: p_dwd}, {name: p_pt, var: p_pt}, {name: p_pdwdist, var: p_pdwdist}, {name: p_pswdpc, var: p_pswdpc}, {name: p_pswdmp, var: p_pswdmp}, {name: p_pswpol, var: p_pswpol}, {name: p_pswcas, var: p_pswcas}, {name: p_pswparam, var: p_pswparam}, {name: p_pswvio, var: p_pswvio}, {name: p_wbd, var: p_wbd}, {name: p_radwbd, var: p_radwbd}, {name: p_frswbd, var: p_frswbd}, {name: p_fntype, var: p_fntype}, {name: p_pidall, var: p_pidall}, {name: p_months_last_dmr, var: p_months_last_dmr}, {name: p_last_dmr_within, var: p_last_dmr_within}, {name: p_indsw, var: p_indsw}, {name: p_msgp_ptype, var: p_msgp_ptype}, {name: p_mon_type, var: p_mon_type}, {name: p_iagency, var: p_iagency}, {name: p_permitting_agency, var: p_permitting_agency}, {name: p_isws, var: p_isws}, {name: p_iswss, var: p_iswss}, {name: p_iswssID, var: p_iswss_id}, {name: p_ds1, var: p_ds1}, {name: p_ds2, var: p_ds2}, {name: p_da1, var: p_da1}, {name: p_da2, var: p_da2}, {name: p_MS4, var: p_ms4}, {name: p_ooFN, var: p_oo_fn}, {name: p_ooFNtype, var: p_oo_f_ntype}, {name: p_ooSA, var: p_oo_sa}, {name: p_ooSA1, var: p_oo_sa1}, {name: p_ooCt, var: p_oo_ct}, {name: p_ooSt, var: p_oo_st}, {name: p_ooZip, var: p_oo_zip}, {name: p_fac_ico, var: p_fac_ico}, {name: p_icoo, var: p_icoo}, {name: p_fac_icos, var: p_fac_icos}, {name: p_ejscreen, var: p_ejscreen}, {name: p_alrexceed, var: p_alrexceed}, {name: p_limit_addr, var: p_limit_addr}, {name: p_lat, var: p_lat}, {name: p_long, var: p_long}, {name: p_radius, var: p_radius}, {name: p_ejscreen_over80cnt, var: p_ejscreen_over80cnt}, {name: p_bio_flag, var: p_bio_flag}, {name: p_bio_fac_type, var: p_bio_fac_type}, {name: p_bio_trtmnt_procs, var: p_bio_trtmnt_procs}, {name: p_bio_analy_method_catgry, var: p_bio_analy_method_catgry}, {name: p_bio_total_volume_amt, var: p_bio_total_volume_amt}, {name: p_bio_mgmt_prctce_type, var: p_bio_mgmt_prctce_type}, {name: p_bio_mgmt_prctce_stype, var: p_bio_mgmt_prctce_stype}, {name: p_bio_mgmt_prctce_handler, var: p_bio_mgmt_prctce_handler}, {name: p_bio_mgmt_container, var: p_bio_mgmt_container}, {name: p_bio_mgmt_pathogen, var: p_bio_mgmt_pathogen}, {name: p_bio_mgmt_pathred, var: p_bio_mgmt_pathred}, {name: p_bio_mgmt_vector, var: p_bio_mgmt_vector}, {name: p_bio_mgmt_def_category, var: p_bio_mgmt_def_category}, {name: p_bio_mgmt_deficiencies, var: p_bio_mgmt_deficiencies}, {name: p_bio_vio_code, var: p_bio_vio_code}, {name: p_bio_current_vio, var: p_bio_current_vio}, {name: p_bio_qtrs_in_vio, var: p_bio_qtrs_in_vio}, {name: p_bio_rpt_year, var: p_bio_rpt_year}, {name: p_bio_vio_last_year, var: p_bio_vio_last_year}, {name: p_msgp_rpt_year, var: p_msgp_rpt_year}, {name: p_vio_last_year, var: p_vio_last_year}, {name: queryset, var: queryset}, {name: responseset, var: responseset}, {name: tablelist, var: tablelist}, {name: maplist, var: maplist}, {name: summarylist, var: summarylist}, {name: callback, var: callback}, {name: qcolumns, var: qcolumns}, {name: p_e90_count, var: p_e90_count}, {name: p_e90_years, var: p_e90_years}, {name: p_psc, var: p_psc}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_fn: $p_fn, p_sa: $p_sa, p_sa1: $p_sa1, p_ct: $p_ct, p_co: $p_co, p_fips: $p_fips, p_st: $p_st, p_zip: $p_zip, p_frs: $p_frs, p_reg: $p_reg, p_sic: $p_sic, p_ncs: $p_ncs, p_pen: $p_pen, p_c1lat: $p_c1lat, p_c1lon: $p_c1lon, p_c2lat: $p_c2lat, p_c2lon: $p_c2lon, p_usmex: $p_usmex, p_sic2: $p_sic2, p_sic4: $p_sic4, p_fa: $p_fa, p_ff: $p_ff, p_act: $p_act, p_maj: $p_maj, p_mact: $p_mact, p_fea: $p_fea, p_feay: $p_feay, p_feaa: $p_feaa, p_iea: $p_iea, p_ieay: $p_ieay, p_ieaa: $p_ieaa, p_qiv: $p_qiv, p_iv: $p_iv, p_impw: $p_impw, p_imp_cau_grp: $p_imp_cau_grp, p_imp_pol: $p_imp_pol, p_trep: $p_trep, p_pm: $p_pm, p_pd: $p_pd, p_ico: $p_ico, p_huc: $p_huc, p_pid: $p_pid, p_med: $p_med, p_ysl: $p_ysl, p_ysly: $p_ysly, p_ysla: $p_ysla, p_qs: $p_qs, p_sfs: $p_sfs, p_tribeid: $p_tribeid, p_tribename: $p_tribename, p_tribedist: $p_tribedist, p_pstat: $p_pstat, p_ptype: $p_ptype, p_pcomp: $p_pcomp, p_plimits: $p_plimits, p_pcss: $p_pcss, p_pexp: $p_pexp, p_owop: $p_owop, p_ipfti: $p_ipfti, p_agoo: $p_agoo, p_idt1: $p_idt1, p_idt2: $p_idt2, p_pityp: $p_pityp, p_pfead1: $p_pfead1, p_pfead2: $p_pfead2, p_pfeat: $p_pfeat, p_pccs: $p_pccs, p_pexcd: $p_pexcd, p_psncq: $p_psncq, p_pctrack: $p_pctrack, p_dwd: $p_dwd, p_pt: $p_pt, p_pdwdist: $p_pdwdist, p_pswdpc: $p_pswdpc, p_pswdmp: $p_pswdmp, p_pswpol: $p_pswpol, p_pswcas: $p_pswcas, p_pswparam: $p_pswparam, p_pswvio: $p_pswvio, p_wbd: $p_wbd, p_radwbd: $p_radwbd, p_frswbd: $p_frswbd, p_fntype: $p_fntype, p_pidall: $p_pidall, p_months_last_dmr: $p_months_last_dmr, p_last_dmr_within: $p_last_dmr_within, p_indsw: $p_indsw, p_msgp_ptype: $p_msgp_ptype, p_mon_type: $p_mon_type, p_iagency: $p_iagency, p_permitting_agency: $p_permitting_agency, p_isws: $p_isws, p_iswss: $p_iswss, p_iswss_id: $p_iswss_id, p_ds1: $p_ds1, p_ds2: $p_ds2, p_da1: $p_da1, p_da2: $p_da2, p_ms4: $p_ms4, p_oo_fn: $p_oo_fn, p_oo_f_ntype: $p_oo_f_ntype, p_oo_sa: $p_oo_sa, p_oo_sa1: $p_oo_sa1, p_oo_ct: $p_oo_ct, p_oo_st: $p_oo_st, p_oo_zip: $p_oo_zip, p_fac_ico: $p_fac_ico, p_icoo: $p_icoo, p_fac_icos: $p_fac_icos, p_ejscreen: $p_ejscreen, p_alrexceed: $p_alrexceed, p_limit_addr: $p_limit_addr, p_lat: $p_lat, p_long: $p_long, p_radius: $p_radius, p_ejscreen_over80cnt: $p_ejscreen_over80cnt, p_bio_flag: $p_bio_flag, p_bio_fac_type: $p_bio_fac_type, p_bio_trtmnt_procs: $p_bio_trtmnt_procs, p_bio_analy_method_catgry: $p_bio_analy_method_catgry, p_bio_total_volume_amt: $p_bio_total_volume_amt, p_bio_mgmt_prctce_type: $p_bio_mgmt_prctce_type, p_bio_mgmt_prctce_stype: $p_bio_mgmt_prctce_stype, p_bio_mgmt_prctce_handler: $p_bio_mgmt_prctce_handler, p_bio_mgmt_container: $p_bio_mgmt_container, p_bio_mgmt_pathogen: $p_bio_mgmt_pathogen, p_bio_mgmt_pathred: $p_bio_mgmt_pathred, p_bio_mgmt_vector: $p_bio_mgmt_vector, p_bio_mgmt_def_category: $p_bio_mgmt_def_category, p_bio_mgmt_deficiencies: $p_bio_mgmt_deficiencies, p_bio_vio_code: $p_bio_vio_code, p_bio_current_vio: $p_bio_current_vio, p_bio_qtrs_in_vio: $p_bio_qtrs_in_vio, p_bio_rpt_year: $p_bio_rpt_year, p_bio_vio_last_year: $p_bio_vio_last_year, p_msgp_rpt_year: $p_msgp_rpt_year, p_vio_last_year: $p_vio_last_year, queryset: $queryset, responseset: $responseset, tablelist: $tablelist, maplist: $maplist, summarylist: $summarylist, callback: $callback, qcolumns: $qcolumns, p_e90_count: $p_e90_count, p_e90_years: $p_e90_years, p_psc: $p_psc
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Clean Water Act (CWA) Facility Enhanced Search Service
#
# GET /cwa_rest_services.get_facility_info
# Returns: record<Results: record<BadSystemIDs: string, BioCVRows: string, BioV3Rows: string, CVRows: string, ClusterOutput: record<ClusterData: list>, ClusterRecords: string, FEARows: string, Facilities: list<record>, INSPRows: string, IconBaseURL: string, IndianCountryRows: string, InfFEARows: string, Message: string, PopUpBaseURL: string, QueryID: string, QueryParameters: list<record>, QueryRows: string, SVRows: string, ServiceBaseURL: string, TotalPenalties: string, V3Rows: string, VioLast4QRows: string>>
export def "get-cwa-rest-services-get-facility-info" [
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
  --output: string # Output Format Flag. Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding. - XML = Data model formatted as Extensible Markup Language. - CSV = Facility results formatted as comma delimited file download. - GEOJSON = Facility results formatted as GeoJSON feature collection. - GEOJSONP = Facility results formatted as GeoJSON feature collection with Padding. - GEOJSOND = Facility results formatted as GeoJSON feature collection download.
  --p-fn: string # Facility Name Filter. Enter one or more case-insensitive facility names to filter results. Provide multiple values as a comma-delimited list. See p_fntype for additional modifiers.
  --p-sa: string # Facility street address. Enter a complete or partial street address.
  --p-sa1: string # Facility street address. Enter a complete or partial street address. Note that p_sa1 is culmulative with p_sa.
  --p-ct: string # Facility City Filter. Enter a single case-insensitive city name to filter results.
  --p-co: string # Facility County Filter. Provide a single county name in combination with a state value provided via p_st.
  --p-fips: string # FIPS Code Filter. Enter a single 5-character Federal Information Processing Standards (FIPS) state + county value to restrict results. E.g. to limit results to Kenosha County, Wisconsin, use 55059.
  --p-st: string # Facility State and State-Equivalent Filter. Provide one or more USPS postal abbreviations for states and state-equivalents to filter results. Provide multiple values as a comma-delimited list.
  --p-zip: string # 5-Digit ZIP Code Filter. Provide one or more 5-digit postal zip codes to filter results. May contain multiple comma-separated values.
  --p-frs: string # Facility Registry Service ID Filter. Enter a single 12-digit FRS identifier to filter results.
  --p-reg: string@p-reg-completer # EPA Region Filter. Provide a single value of 01 thru 10 to restrict results to a single EPA region.
  --p-sic: string # Standard Industrial Classification (SIC) Code Filter. Enter a single 4-digit SIC Code to filter results. If more complex filtering is required, use p_sic2 and p_sic4.
  --p-ncs: string # North American Industry Classification System Filter. Enter two to six digits to filter results to facilities having matching NAICS codes. Digits less than six will match to all codes beginning with the provided values.
  --p-pen: string # Last Penality Date Qualifier Filter. Enter one of the following: - NEVER = No Penalties - ANY = Any Penalty - LEXX = Less than or equal to XX months. Provide a number in place of XX, e.g. "LE5" for a facility with a penalty within previous 5 months. - GTXX = Greater than XX months. Provide a number in place of XX, eg. GT12, for a facility with the last penalty greater than 12 months ago.
  --xmin: float # Minimum longitude value in decimal degrees.
  --ymin: float # Minimum latitude value in decimal degrees.
  --xmax: float # Maximum longitude value in decimal degrees.
  --ymax: float # Maximum latitude value in decimal degrees.
  --p-usmex: string@p-usmex-completer # US-Mexico Border Flag. Enter Y/N to restrict searches to facilities located within 100KM of the border.
  --p-sic2: string # Standard Industrial Classification (SIC) Code Filter Alternate 2. Enter a wild-card search against SIC codes. A final wild-card is always present allowing "22" to match all SIC codes beginning with 22. Use the "%" character within strings to match any SIC values with the pattern. For example, "2%21" matches 2021, 2121, 2221, etc.
  --p-sic4: string # Standard Industrial Classification (SIC) Code Filter Alternate 3. Enter the first 2, 3 or 4 SIC code digits to filter results to facilities having those code prefixes. As this alternative does not utilize an index, p_sic2 will generally be quicker.
  --p-fa: string # Federal Agency. 1 character or 5-character values; may contain multiple comma-separated values. ALL will retrieve all facilities where the federal agency code is not null. Use the Federal Agencies lookup service to obtain a list of values.
  --p-ff: string@p-ff-completer # Federal Facility Indicator Flag. Enter Y to restrict searches to federal facilities.
  --p-act: string # Active Permits/Facilities Flag. Provide Y or N to filter results to facilities with active permits. A Y will select ICIS NPDES permits with a status of effective, continued, or expired.
  --p-maj: string@p-maj-completer # Major Facility Flag. Enter Y to restrict results to Major facilities only.
  --p-mact: string # CAA Maximum Achievable Control Technology (MACT) Subpart codes (alpha ID between 1 and 7 characters) applicable to the facility.
  --p-fea: string@p-fea-completer # Formal Enforcement Actions [within / not within] specified date range indicator. The date range is determined by parameters p_fead1 and p_fead2 or by parameter p_feay. - W = within date range - N = not within date range
  --p-feay: float@p-feay-completer # Years (1 to 5) Range. This value is used to create a date range for Formal Enforcement Actions (FEA). Used along with p_fea (which indicates whether to look within or outside of the date range) to find FEAs within (or not within) the number of years specified.
  --p-feaa: string@p-feaa-completer # Agency associated with Formal Enforcement Actions: - E = EPA - S = State - A = All
  --p-iea: string@p-iea-completer # Informal Enforcement Actions [within / not within] specified date range. The date range is determined by parameters p_iead1 and p_iead2 or by parameter p_ieay. - W = within date range - N = not within date range
  --p-ieay: float@p-ieay-completer # Years (1 to 5) Range. This value is used to create a date range for Informal Enforcement Actions (IEA). Used along with p_iea (which indicates whether to look within or outside of the date range) to find IEAs within (or not within) the number of years specified.
  --p-ieaa: string@p-ieaa-completer # Agency associated with Informal Enforcement Actions. If left blank, both agencies are included. - E = EPA - S = State
  --p-qiv: string@p-qiv-completer # Quarters in Noncompliance Limiter. Enter a coded value to limit results to facilities with given quarter of noncompliance. - Z = Zero quarters in noncompliance. - GEXX = Replacing XX with a numeric value, that number of quarterd or more in noncompliance. - GTXX = Replacing XX with a numeric value, more than that number of quarters in noncompliance.
  --p-iv: string # Facility has a violation status of 'In Viol' during any of the selected quarters. Range: Fiscal Year 2020 Quarter 2 to Fiscal Year 2017 Quarter 2 Multiple values are comma delimited. |||||| Fiscal Years |||||| - FY2020 or FY20 or 2020 or 20 - FY2019 or FY19 or 2019 or 19 - FY2018 or FY18 or 2018 or 18 - FY2017 or FY17 or 2017 or 17 ||||| Fiscal Quarters ||||| - FY2020Q2 or FY20Q2 or 20202 or 202 or 13 - FY2020Q1 or FY20Q1 or 20201 or 201 or 12 - FY2019Q4 or FY19Q4 or 20194 or 194 or 11 - FY2019Q3 or FY19Q3 or 20193 or 193 or 10 - FY2019Q2 or FY19Q2 or 20192 or 192 or 9 - FY2019Q1 or FY19Q1 or 20191 or 191 or 8 - FY2018Q4 or FY18Q4 or 20184 or 184 or 7 - FY2018Q3 or FY18Q3 or 20183 or 183 or 6 - FY2018Q2 or FY18Q2 or 20182 or 182 or 5 - FY2018Q1 or FY18Q1 or 20181 or 181 or 4 - FY2017Q4 or FY17Q4 or 20174 or 174 or 3 - FY2017Q3 or FY17Q3 or 20173 or 173 or 2 - FY2017Q2 or FY17Q2 or 20172 or 172 or 1
  --p-impw: string@p-impw-completer # Discharging into Impaired Waters Flag. Enter Y to limit results to facilities with discharge to waterbodies listed as impaired in the ATTAINS database.
  --p-imp-pol: string@p-imp-pol-completer # Facility is discharging pollutants that are potentially contributing to the impairment of local waterbodies according to the ATTAINS database.
  --p-imp-cau-grp: string@p-imp-cau-grp-completer # Facility is discharging a pollutant group causing a waterbody to be impaired. Enter 1 through 34 (the internal number of the pollutant group); or enter a partial name such as Dioxin,Temp,tUrBidity.
  --p-trep: string@p-trep-completer # Current Toxics Release Inventory (TRI) Reporter Limiter. Enter one of the following codes to limit results. - CURR = Current TRI reporter. - NONCURR = Has reported to TRI in the past but not for the current reporting year.
  --p-pm: string@p-pm-completer # Percent Minority Population Limiter. Enter a value to restrict results to facilities with a given percentage of minority population within 3-mile radius. - NONE = 0% - GT5 = greater than 5% - GT10 = greater than 10% - GT25 = greater than 25% - GT50 = greater than 50% - GT75 = greater than 75%
  --p-pd: string@p-pd-completer # Population Density Limiter (per sq mile). Enter a value to limit results to facilities located in area of a given population density. - NONE = 0 population density per square mile - GT100 = More than 100 population density per square mile - GT500 = More than 500 population density per square mile - GT1000 = More than 1000 population density per square mile - GT5000 = More than 5000 population density per square mile - GT10000 = More than 10000 population density per square mile - GT20000 = More than 20000 population density per square mile
  --p-ico: string@p-ico-completer # Indian Country Flag. Enter a "Y" or "N" to restrict searches to facilities inside or outside Indian Country.
  --p-huc: string # 2-, 4-, 6-, or 8-character watershed code. May contain multiple comma-separated values.
  --p-pid: string # Nine-digit permit IDs. May contain up to 2000 comma-separated values.
  --p-med: string@p-med-completer # Filter Results by Media. - A = Air - M = RMP (Risk Management Plan) - R = RCRA (Hazardous Waste) - S = SDWA (Public Drinking Water Systems) - ALL = Air and RCRA and Water
  --p-ysl: string@p-ysl-completer # Last Facility Inspection [within / not within] Specified Date Range Indicator. The date range is determined by parameters p_idt1 and p_idt2 or by parameter p_ysly. - W = within date range - N = not within date range
  --p-ysly: float@p-ysly-completer # Number of years (1 to 5) since last facility inspection. A value of 1 means that it has been inspected within the year.
  --p-ysla: string@p-ysla-completer # Facility Last Inspection Code Filter. If left blank, both agencies are included. Enter a value to limit results: - E = EPA - S = State
  --p-qs: string # Quick Search. Allows entry for city, state, and/or zip code.
  --p-sfs: string # Single Facility Search Filter. Provide a facility name or program system identifier to limit results. For the all data search, the FRS registry identifier is also searched.
  --p-tribeid: float # Numeric code for tribe (or list of tribes).
  --p-tribename: string # Tribe Name Filter. Enter a single tribe name to filter results.
  --p-tribedist: float # Proximity to tribal land limiter. Enter an amount of mile between 0 and 25 to filter results. This parameter is only evaluated if p_tribeid is populated.
  --p-pstat: string # Permit Status Filter. Enter one or more of the following codes. Provide multiple values as a comma-delimited list. - EFF = Effective - EXP = Expired - PND = Pending - TRM = Terminated - RET = Retired - NON = Not Needed - ADC = Admin Continued
  --p-ptype: string # Permit Type Filter. Enter one or more code values to filter results. Provide multiple values as a comma-delimited list. - NPD = NPDES Individual Permit - NGP = NPDES Master General Permit - GPC = General Permit Covered Facility - SNN = State Issued Master General Permit (Non-NPDES) - IIU = Individual IU Permit (Non-NPDES) - SIN = Individual State Issued Permit (Non-NPDES) - APR = Associated Permit Record - UFT = Unpermitted Facility
  --p-pcomp: string # Permit Component Code Filter. Enter one or more codes to filter results. Provide multiple values as a comma-delimited list. - PRE = Pretreatment - CAF = CAFO - CSO = CSO - POT = POTW - BIO = Biosolids - SWS = Storm Water Small MS4s - SWM = Storm Water Medium/Large MS4s - SWI = Storm Water Industrial - SWC = Storm Water Construction
  --p-plimits: string@p-plimits-completer # Permit Limits Present Flag. Enter Y to limit results to facilities have present permit limits.
  --p-pcss: string@p-pcss-completer # Combined Sewer Systems Outflows Limiter. Enter one of the following to limit results to facilities having the given count of CSS outflows. - ALL = returns all facilities, regardless of the number of outflows. - GE1 = returns facilities with one or more outflows. - GE10 = returns facilities with ten or more outflows. - GE50 = returns facilities with fifty or more outflows.
  --p-pexp: string@p-pexp-completer # Permit Expired or Administratively Continued Limiter. Enter one of the following values to filter results. - EXP = limit results to facilities with permits expired or administratively continued. - EXPLE1YR = limit resuls to facilities with permits expired administratively continued within the past year. - EXPGT1YR = limit resuls to facilities with permits expired administratively continued more than a year ago.
  --p-owop: string@p-owop-completer # Owner/Operator code filter. Enter one of the following values to restrict results. - Federal = Federal facilities regulated under the NPDES program. - POTW = Publicly owned treatment works. Treatment works that are owned by a State, Tribe, or municipality. - Non-POTW = Non-publicly owned treatment works. Often referred to as "non-municipals" or "industrials".
  --p-ipfti: string
  --p-agoo: string@p-agoo-completer # Indicates whether to AND or OR the Owner/Operator parameter (p_owop) and the federal agency code (p_fa) parameters.
  --p-idt1: string # Beginning of date range of most recent facility inspection.
  --p-idt2: string # End of date range of most recent facility inspection.
  --p-pityp: string # Inspection Type Code. See ICIS Compliance Monitor Types lookup serivce for a list of available codes and descriptions.
  --p-pfead1: string # Formal Enforcement Action Date Range Start. Enter a date in MM/DD/YYYY format to set the start of the range for filtering by recent Formal Enforcement Action (FEA) taken against the facility within the last five years.
  --p-pfead2: string # Formal Enforcement Action Date Range End. Enter a date in MM/DD/YYYY format to set the end of the date range for filtering by recent Formal Enforcement Action (FEA) taken against the facility within the last five years.
  --p-pfeat: string # Formal Enforcement Action (FEA) Code Filter. Enter one or more three-letter FEA codes to restrict results to facilities with these attributes. Use p_fead1 and p_fead2 parameters to further restrict this filter by entering a date range. Provide multiple codes as a comma-delimited list.
  --p-pccs: string # Current Compliance Status: ||||||||||||||||||||||||||| Significant Noncompliance (SNC) ||||||||||||||||||||||||||| - SNC = E, S, X, T, D - E�= E(EffViol) - S�= S(CSchVio) - X = X(EffNMth) - T = T(CSchRpt) - D�= D(DMR NR) ||||||||||||||||||||||||||| Noncompliance (NC) ||||||||||||||||||||||||||| - NC = N, V - N�= N(RptViol) - V�= V(NonRNCV) ||||||||||||||||||||||||||| New Violations (PQV) ||||||||||||||||||||||||||| - PQV = New Violations (13th Quarter) ||||||||||||||||||||||||||| No Violations (NV) ||||||||||||||||||||||||||| - NV = R, P, M, U, W , Blank, and No New Violations (no PQV) - R�= R(Resolvd) - P�= P(ResPend) - M�= C(Manual) - U = U(N/A) - W = W(N/A) - Blank = (null) May contain multiple comma-separated values.
  --p-pexcd: string@p-pexcd-completer # 3-Year Effluent Exceedances Limiter. Enter a value to restrict results to facilities with the given amount of exceedances in the past 3 years. - 0 = facilities with no exceedances - GE0 = facilities with one or more exceedances - GE10 = facilities with ten or more exceedances - GE50 = facilities with fifty or more exceedances - GE100 = facilities with one hundred or more exceedances
  --p-psncq: string@p-psncq-completer # Quarters in Significant Noncompliance Limiter. Enter a coded value to limit results to facilities with given quarter of significant noncompliance. - Z = Zero quarters in significant noncompliance. - GEXX = Replacing XX with a numeric value, that number of quarterd or more in significant noncompliance. - GTXX = Replacing XX with a numeric value, more than that number of quarters in significant noncompliance.
  --p-pctrack: string@p-pctrack-completer # Compliance Tracking Limiter. Provide a keyword to indicate the extent to which data is being entered and effluent exceedances are being identified. - Off - Partial - On
  --p-dwd: string@p-dwd-completer # Direct Water Discharges. Pounds of toxic chemicals released directly to surface water as reported to the Toxics Release Inventory.
  --p-pt: string@p-pt-completer # POTW Transfers. Pounds of toxic chemicals transferred to a Publicly Operated Treatment Works (POTW) as reported to the Toxics Release Inventory.
  --p-pdwdist: string@p-pdwdist-completer # Distance (in miles) to downstream drinking water intake.
  --p-pswdpc: string # Pollutant Category Code: Values: WTR for Water, AIR for Air
  --p-pswdmp: string@p-pswdmp-completer # Used to determine limit begin and end dates for surface water discharges. Number represents years from current date.
  --p-pswpol: string # For CWA, pollutant names for surface water discharges. for Drinking Water, SDWIS Violation contaminant codes for unaddressed violations that have occurred in the last 3 years. May contain multiple comma-separated values.
  --p-pswcas: string # CAS numbers for surface water discharges. May contain multiple comma-separated values.
  --p-pswparam: string # Parameter codes for surface water discharges. May contain multiple comma-separated values.
  --p-pswvio: string@p-pswvio-completer # Used in conjuction with parameters p_pswpol and p_pswparam, indicates whether search should only include pollutants with violations.
  --p-wbd: string # 2-, 4-, 6-, 8-, 10-, or 12-character watershed (WBD from the USGS Watershed Boundary Dataset). May contain multiple comma-separated values. Uses the FRS Best Pick Coordinate to obtain the WBD12 Huc value.
  --p-radwbd: string # 2-, 4-, 6-, 8-, 10-, or 12 character watershed (WBD from the USGS Watershed Boundary Dataset). May contain multiple comma-separated values. Will search against WBD values otained by "reach indexing" NPDES permits against the medium resolution National Hydrography Dataset.
  --p-frswbd: string # Works exactly the same as the p_wbd parameter. 2-, 4-, 6-, 8-, 10-, or 12-character watershed (WBD from the USGS Watershed Boundary Dataset). May contain multiple comma-separated values. Uses the FRS Best Pick Coordinate to obtain the WBD12 Huc value.
  --p-fntype: string@p-fntype-completer # Controls type of text search performed on facility name with parameter p_fn. - EXACT = Find facilities having the exact provided name(s). - BEGINS = Find facilities with names starting with the provided term(s). - ALL = Find facilities using Oracle text search terms. - CONTAINS =
  --p-pidall: string@p-pidall-completer # Controls whether search is restricted to existing system. Y means the search will match the p_pid parameter against all associated permits (AIR, RCRA, SDWIS, etc).
  --p-months-last-dmr: float # The number of months since the last Discharge Monitoring Report has been submitted.
  --p-last-dmr-within: string@p-last-dmr-within-completer # W value returns facilities that have submitted DMRs within the number of months specified by p_months_last_dmr. An N value returns facilities that have not submitted a DMR within the specified number of months.
  --p-indsw: string@p-indsw-completer # Industrial Stormwater Permit Flag. Enter a Y or N to filter results by this type of permit.
  --p-msgp-ptype: string@p-msgp-ptype-completer # Multi-Sector General Purpose Permit Type. Enter a value to filter results by MSGP Permit Type. - NOI = Notice of Intent - NOE = No Exposure Certification
  --p-mon-type: string@p-mon-type-completer # For use with the Industrial Stormwater search only. Valid values are BENCHGS fro Benchmark (Alert Limit) G2 Ore, BENCH for Benchmark (Alert Limit), and ELG fro Effluent Limitation Guidelines(ELG)(Effluent Limit).
  --p-iagency: string # Issuing Agency Limiter. Enter a single value to filter results by the issuing agency, e.g. "State" or "EPA".
  --p-permitting-agency: string
  --p-isws: string # Multi-Sector General Purpose Permit Subsector Individual Identifier. Enter a value to filter results.
  --p-iswss: string # Multi-Sector General Purpose Permit Subsector Group Code. Enter a value to filter results.
  --p-iswss-id: string # Multi-Sector General Purpose Permit Sector Code. Enter a value to filter results.
  --p-ds1: string # Submitted Date Filter Start. To filter by the date of submission, enter a start date here and an end date in the p_ds2 parameter. Both dates are required for filtering.
  --p-ds2: string # Submitted Date Filter End. To filter by the date of submission, enter an end date here and a start date in the p_ds1 parameter. Both dates are required for filtering.
  --p-da1: string # Active Date Filter Start. To filter by the active date, enter a start date here and an end date in the p_da2 parameter. Both dates are required for filtering.
  --p-da2: string # Active Date Filter End. To filter by the active date, enter an end date here and a start date in the p_da1 parameter. Both dates are required for filtering.
  --p-ms4: string@p-ms4-completer # Municipal Separate Storm Water Sewer (MS4) Permit Flag. Enter a Y or N to filter results by this type of permit.
  --p-oo-fn: string # Owner/Operator Name. Enter the owner/operator name of the facility.
  --p-oo-f-ntype: string@p-oo-f-ntype-completer # Owner/Operator Name Multiple Selection Evaluator.
  --p-oo-sa: string # Owner/Operator Address. Enter the address of the owner/operator of the facility.
  --p-oo-sa1: string # Owner/Operator Address Line 2. Enter the line 2 address of the owner/operator of the facility.
  --p-oo-ct: string # Owner/Operator City. Enter the city where the owner/operator of the facility is located.
  --p-oo-st: string # Owner/Operator State. Enter the standardized postal state code where the owner/operator of the facility is located.
  --p-oo-zip: string # Owner/Operator Zip Code. Enter the postal zip code where the owner/operator of the facility is located.
  --p-fac-ico: string@p-fac-ico-completer # FRS tribal land code flag. Enter "Y" or "N" to include or exclude facilities based on FRS tribal land code.
  --p-icoo: string # Indian country search and/or flag. Enter "Y" to set indian country search conditions to return any results found using p_ico, p_fac_ico or p_fac_icoo. Otherwise only results matching all provided p_ico, p_fac_ico or p_fac_icoo conditions will be returned.
  --p-fac-icos: string # FRS tribal land spatial flag. Enter "Y" or "N" to include or exclude facilities based on FRS tribal land spatial flag.
  --p-ejscreen: string # Enter "Y" to limit facilities to Census block groups where one of more Environmental Justice indexes above 80th percentile.
  --p-alrexceed: float # Alert Limits Exceedences Limiter. Enter a numeric value to restrict results to facilities having the given amount or more of alert limits exceedances.
  --p-limit-addr: string@p-limit-addr-completer # Limit Address Search Flag. Enter Y to restrict facility searches to native data source only.
  --p-lat: float # Latitude location in decimal degrees.
  --p-long: float # Longitude location in decimal degrees.
  --p-radius: float # Spatial Search Radius. Enter a radius up to 100 miles in which to spatially search for facilities.
  --p-ejscreen-over80cnt: string@p-ejscreen-over80cnt-completer # The number of Environmenmt Justice Indicators above the 80th percentile. Valid values are 1 through 11.
  --p-bio-flag: string # A Y value will select all biosolid-related permits.
  --p-bio-fac-type: string # The code indicating the reporting obligation reason: - POT = A POTW with a design flow rate equal to or greater than one million gallons per day - CLI = A Class I Sludge Management Facility as defined in 40 CFR 503.9 - PPL = A POTW that serves 10,000 people or more - OTH = Otherwise required to report (e.g., permit condition, enforcement action) - NOA = None of the above
  --p-bio-trtmnt-procs: string # The biosolids or sewage sludge treatment process or processes at the facility: - AER = Aerobic Digestion - AIR = Air Drying (or Sludge Drying Beds) - ANA = Anaerobic Digestion - COD = Beta Ray Irradiation - COM = Lower Temperature Composting - DEW = Pasteurization - DIS = Gamma Ray Irradiation - HEA = Heat Drying (e.g., Flash Dryer, Spray Dryer, Rotary Dryer) - HET = Heat Treatment (Liquid Sewage Sludge Heated to 356 Deg. F/180 Deg. C or Higher for 30 min.) - HTC = Higher Temperature Composting - MET = Methane or Biogas Capture and Recovery - OTH = Other Treatment Process - PRE = Preliminary Operations (e.g., Sludge Grinding, Degritting, Blending) - SLU = Sludge Lagoon - STA = Lime Stabilization - THE = Temporary Sludge Storage (Sewage Sludge Stored on Land 2 Years or Less, Not in Sewage Sludge Unit) - THI = Thickening (Gravity and/or Flotation Thickening, Centrifugation, Belt Filter Press, Vacuum Filter) - THM = Thermophilic Aerobic Digestion - UND = Long-Term Sludge Storage (Sewage Sludge Stored on Land 2 Years or More, not in Sewage Sludge Unit)"
  --p-bio-analy-method-catgry: string # The unique code for the category of the analytic methods used by the facility to analyze regulated parameters (including enteric viruses, fecal coliforms, helminth ova, and Salmonella sp.) at the facility: - PAT = Pathogens - MET = Metals - NIT = Nitrogen Compounds - OTH = Other Analytes
  --p-bio-total-volume-amt: string # Total annual amount (in dry metric tons) of biosolids or sewage sludge generated at the facility. - EQ0 = 0 - IN0_1 = GT 0 but LT 1 - IN0_289 = GT 0 but LT 290 MT/year - IN290_1499 = GE 290 but LT 1500 MT/year - IN1500_14999 = GE 1500 but LT 15,000 - GE15000 = GE 15,000
  --p-bio-mgmt-prctce-type: string # The unique code that identifies the type of biosolids or sewage sludge management practice (e.g., land application, surface disposal, incineration) used by the facility. The facility will separately report the management practice for each biosolids or sewage sludge form and pathogen class. This data element will also identify the management practices used by surface disposal site owners/operators (see 40 CFR 503.24): - BIN = Incineration - BLN = Land Application - BOT = Other Management Practice - BSD = Surface Disposal
  --p-bio-mgmt-prctce-stype: string # This is the code indicating additional detail about the type of Management Practice used for a volume of Biosolids or Sewage Sludge: - ADV = Advanced Alkaline Stabilized Biosolids Distribution & Marketing - AGR = Agricultural Land Application - COM = Distribution and Marketing - Compost - DEE = Deep-well Injection Disposal - DIS = Disposal in a Municipal Landfill (under 40 CFR 258) - DMO = Distribution and Marketing - Other - HEA = Heat Dried Biosolids Distribution & Marketing - OTL = Other Land Application Management Practice Detail - OTO = Other Management Practice Detail - RSA = Reclamation Site Application - SEN = Sent to Cement Kiln for Use as Alternative Energy - STO = Storage - UIC = Use in Construction - UPS = Used in Production of Syngas - USE = Use as Daily Cover for Municipal Landfill (under 40 CFR 258)
  --p-bio-mgmt-prctce-handler: string # This is the code indicating the type of Biosolids or Sewage Sludge handlers/preparers. - OWN = Owner or Operator - OFF = Off-Site Third-Party Handler or Preparer
  --p-bio-mgmt-container: string # The code that identifies the nature of each biosolids and sewage sludge material generated by the facility in terms of whether the material is a biosolid or sewage sludge and whether the material is ultimately conveyed off-site in bulk or in bags. The facility separately reports the form for each biosolids or sewage sludge management practice or practices used by the facility and pathogen class: - BUL = Bulk - BAG = Bag or Container
  --p-bio-mgmt-pathogen: string # This code identifies the pathogen class [e.g., Class A, Class B, Not Applicable (Incineration)] for biosolids or sewage sludge generated by the facility. The facility will separately report the pathogen class for each biosolids or sewage sludge management practice used by the facility and by each biosolids or sewage sludge form. It also is used to filter applicable Pathogen Reduction and Vector Attraction Reduction Options as well as Land Application Management Practice Deficiencies. Only reqired for some of the mgmt. practice types: - AAA = Class A - AEQ = Class A EQ (sale/give away) - BBB = Class B - NAP = Not Applicable (Incineration)
  --p-bio-mgmt-pathred: string # This is the description of the option used by the facility to control pathogen for a Biosolids Management Practice: - A1 = Class A - Alternative 1: Time/Temperature - A2 = Class A - Alternative 2: pH/Temperature/Percent Solids - A3 = Class A - Alternative 3: Test Enteric Viruses and Helminth ova; Operating Parameters - A4 = Class A - Alternative 4: Test Enteric Viruses and Helminth ova; No New Solids - A51 = Class A - Alternative 5: PFRP 1: Composting - A52 = Class A - Alternative 5: PFRP 2: Heat Drying - A53 = Class A - Alternative 5: PFRP 3: Liquid heat treatment - A54 = Class A - Alternative 5: PFRP 4: Thermophilic Aerobic Digestion (ATAD) - A55 = Class A - Alternative 5 PFPR 5: Beta Ray Irradiation - A56 = Class A - Alternative 5 PFPR 6: Gamma Ray Irradiation - A57 = Class A - Alternative 5: PFRP 7: Pasteurization - A6 = Class A - Alternative 6: PFRP Equivalency - B1 = Class B - Alternative 1: Fecal Coliform Geometric Mean - B21 = Class B - Alternative 2 PSRP 1: Aerobic Digestion - B22 = Class B - Alternative 2 PSRP 2: Air Drying - B23 = Class B - Alternative 2 PSRP 3: Anaerobic Digestion - B24 = Class B - Alternative 2 PSRP 4: Composting - B25 = Class B - Alternative 2 PSRP 5: Lime Stabilization - B3 = Class B - Alternative 3: PSRP Equivalency - PH = pH Adjustment (Domestic Septage)
  --p-bio-mgmt-vector: string # The unique code that identifies the option used by the facility for vector attraction reduction. See a listing of these vector attraction reduction options at 40 CFR 503.33(b)(1) through (11). The facility will separately report the vector attraction reduction options for each biosolids or sewage sludge management practice used by the facility and by each biosolids or sewage sludge form as well as by each biosolids or sewage sludge pathogen class: - VR1 = Option 1 - Volatile Solids Reduction - VR2 = Option 2 - Bench-Scale Volatile Solids Reduction (Anaerobic Bench Test) - VR3 = Option 3 - Bench-Scale Volatile Solids Reduction (Aerobic Bench Test w/ Percent Solids - 2% or Less) - VR4 = Option 4 - Specific Oxygen Uptake Rate - VR5 = Option 5 - Aerobic Processing (Thermophilic Aerobic Digestion/Composting) - VR6 = Option 6 - Alkaline Treatment - VR7 = Option 7 - Drying (Equal to or Greater than 75 Percent) - VR8 = Option 8 - Drying (Equal to or Greater than 90 Percent) - VR9 = Option 9 - Sewage Sludge Injection - V10 = Option 10 - Sewage Sludge Timely Incorporation into Land - V11 = Option 11 - Sewage Sludge Covered at the End of Each Operating Day
  --p-bio-mgmt-def-category: string # This is the code indicating the type of NPDES special regulatory program deficiency: - INC = Biosolids Incineration - LNA = Biosolids Land Application - LNB = Biosolids Land Application - Pathogen Class B - OTB = Biosolids Other Management Practice - SFD = Biosolids Surface Disposal
  --p-bio-mgmt-deficiencies: float # The number of times noncompliance was reported by the facility in the last 3 years. The results returned will include facilities whose number of reported noncompliance events is greater than or equal to the number entered.
  --p-bio-vio-code: string # The Biosolids Single Event Violation Code. Enter one or mode codes.
  --p-bio-current-vio: string@p-bio-current-vio-completer # Indicator of whether the facility is currently in violation for biosolids under the Clean Water Act, in the 12th or 13th quarter: - Y = Yes - N = No
  --p-bio-qtrs-in-vio: float # The number of quarters, in the last three years, where the facility was in violation for a biosolids violation type. The results returned will include facilities whose number of quarters with violations is greater than or equal to the number entered.
  --p-bio-rpt-year: string # The last year that the permittee submitted an annual Biosolids report. Valid values are NONE and any year greater or equal to 2016.
  --p-bio-vio-last-year: string@p-bio-vio-last-year-completer # Identifies if a biosolids violation has occured in the last year. Valid values are Y and N.
  --p-msgp-rpt-year: string # The last year that a MSGP report was submitted for the permit. Valid values are "NONE" and any year Greater or Eqal to 2015.
  --p-vio-last-year: string@p-vio-last-year-completer # Identifies if a permit violation has occured in the last year. Valid values are Y and N.
  --responseset: float # Response Set Limiter. Enter a value to limit the number of records per page. Value cannot exceed 1,000.
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
  --qcolumns: string # Used to customize service output. A list of comma-separated column IDs of output objects that will be returned in the service query object or download. Use the metadata service endpoint for a complete list of Ids and definitions.
  --p-pretty-print: float # Optional flag to request GeoJSON formatted results to be pretty printed. Only provide a numeric value when the output needs to be human readable as pretty printing has a performance cost.
  --p-e90-count: float # Number of E90 Exceedances. Identifies water permits with a number of E90 (Effluient Exceedances) >= the value provided for the last number of years provided by the p_e90_years value.
  --p-e90-years: float # Number of years for the p_e90_count search. Identified the past number of years to be used for the p_e90_count search.
  --p-psc: string # Point Source Category.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/cwa_rest_services.get_facility_info"
    query: [{name: output, var: output}, {name: p_fn, var: p_fn}, {name: p_sa, var: p_sa}, {name: p_sa1, var: p_sa1}, {name: p_ct, var: p_ct}, {name: p_co, var: p_co}, {name: p_fips, var: p_fips}, {name: p_st, var: p_st}, {name: p_zip, var: p_zip}, {name: p_frs, var: p_frs}, {name: p_reg, var: p_reg}, {name: p_sic, var: p_sic}, {name: p_ncs, var: p_ncs}, {name: p_pen, var: p_pen}, {name: xmin, var: xmin}, {name: ymin, var: ymin}, {name: xmax, var: xmax}, {name: ymax, var: ymax}, {name: p_usmex, var: p_usmex}, {name: p_sic2, var: p_sic2}, {name: p_sic4, var: p_sic4}, {name: p_fa, var: p_fa}, {name: p_ff, var: p_ff}, {name: p_act, var: p_act}, {name: p_maj, var: p_maj}, {name: p_mact, var: p_mact}, {name: p_fea, var: p_fea}, {name: p_feay, var: p_feay}, {name: p_feaa, var: p_feaa}, {name: p_iea, var: p_iea}, {name: p_ieay, var: p_ieay}, {name: p_ieaa, var: p_ieaa}, {name: p_qiv, var: p_qiv}, {name: p_iv, var: p_iv}, {name: p_impw, var: p_impw}, {name: p_imp_pol, var: p_imp_pol}, {name: p_imp_cau_grp, var: p_imp_cau_grp}, {name: p_trep, var: p_trep}, {name: p_pm, var: p_pm}, {name: p_pd, var: p_pd}, {name: p_ico, var: p_ico}, {name: p_huc, var: p_huc}, {name: p_pid, var: p_pid}, {name: p_med, var: p_med}, {name: p_ysl, var: p_ysl}, {name: p_ysly, var: p_ysly}, {name: p_ysla, var: p_ysla}, {name: p_qs, var: p_qs}, {name: p_sfs, var: p_sfs}, {name: p_tribeid, var: p_tribeid}, {name: p_tribename, var: p_tribename}, {name: p_tribedist, var: p_tribedist}, {name: p_pstat, var: p_pstat}, {name: p_ptype, var: p_ptype}, {name: p_pcomp, var: p_pcomp}, {name: p_plimits, var: p_plimits}, {name: p_pcss, var: p_pcss}, {name: p_pexp, var: p_pexp}, {name: p_owop, var: p_owop}, {name: p_ipfti, var: p_ipfti}, {name: p_agoo, var: p_agoo}, {name: p_idt1, var: p_idt1}, {name: p_idt2, var: p_idt2}, {name: p_pityp, var: p_pityp}, {name: p_pfead1, var: p_pfead1}, {name: p_pfead2, var: p_pfead2}, {name: p_pfeat, var: p_pfeat}, {name: p_pccs, var: p_pccs}, {name: p_pexcd, var: p_pexcd}, {name: p_psncq, var: p_psncq}, {name: p_pctrack, var: p_pctrack}, {name: p_dwd, var: p_dwd}, {name: p_pt, var: p_pt}, {name: p_pdwdist, var: p_pdwdist}, {name: p_pswdpc, var: p_pswdpc}, {name: p_pswdmp, var: p_pswdmp}, {name: p_pswpol, var: p_pswpol}, {name: p_pswcas, var: p_pswcas}, {name: p_pswparam, var: p_pswparam}, {name: p_pswvio, var: p_pswvio}, {name: p_wbd, var: p_wbd}, {name: p_radwbd, var: p_radwbd}, {name: p_frswbd, var: p_frswbd}, {name: p_fntype, var: p_fntype}, {name: p_pidall, var: p_pidall}, {name: p_months_last_dmr, var: p_months_last_dmr}, {name: p_last_dmr_within, var: p_last_dmr_within}, {name: p_indsw, var: p_indsw}, {name: p_msgp_ptype, var: p_msgp_ptype}, {name: p_mon_type, var: p_mon_type}, {name: p_iagency, var: p_iagency}, {name: p_permitting_agency, var: p_permitting_agency}, {name: p_isws, var: p_isws}, {name: p_iswss, var: p_iswss}, {name: p_iswssID, var: p_iswss_id}, {name: p_ds1, var: p_ds1}, {name: p_ds2, var: p_ds2}, {name: p_da1, var: p_da1}, {name: p_da2, var: p_da2}, {name: p_MS4, var: p_ms4}, {name: p_ooFN, var: p_oo_fn}, {name: p_ooFNtype, var: p_oo_f_ntype}, {name: p_ooSA, var: p_oo_sa}, {name: p_ooSA1, var: p_oo_sa1}, {name: p_ooCt, var: p_oo_ct}, {name: p_ooSt, var: p_oo_st}, {name: p_ooZip, var: p_oo_zip}, {name: p_fac_ico, var: p_fac_ico}, {name: p_icoo, var: p_icoo}, {name: p_fac_icos, var: p_fac_icos}, {name: p_ejscreen, var: p_ejscreen}, {name: p_alrexceed, var: p_alrexceed}, {name: p_limit_addr, var: p_limit_addr}, {name: p_lat, var: p_lat}, {name: p_long, var: p_long}, {name: p_radius, var: p_radius}, {name: p_ejscreen_over80cnt, var: p_ejscreen_over80cnt}, {name: p_bio_flag, var: p_bio_flag}, {name: p_bio_fac_type, var: p_bio_fac_type}, {name: p_bio_trtmnt_procs, var: p_bio_trtmnt_procs}, {name: p_bio_analy_method_catgry, var: p_bio_analy_method_catgry}, {name: p_bio_total_volume_amt, var: p_bio_total_volume_amt}, {name: p_bio_mgmt_prctce_type, var: p_bio_mgmt_prctce_type}, {name: p_bio_mgmt_prctce_stype, var: p_bio_mgmt_prctce_stype}, {name: p_bio_mgmt_prctce_handler, var: p_bio_mgmt_prctce_handler}, {name: p_bio_mgmt_container, var: p_bio_mgmt_container}, {name: p_bio_mgmt_pathogen, var: p_bio_mgmt_pathogen}, {name: p_bio_mgmt_pathred, var: p_bio_mgmt_pathred}, {name: p_bio_mgmt_vector, var: p_bio_mgmt_vector}, {name: p_bio_mgmt_def_category, var: p_bio_mgmt_def_category}, {name: p_bio_mgmt_deficiencies, var: p_bio_mgmt_deficiencies}, {name: p_bio_vio_code, var: p_bio_vio_code}, {name: p_bio_current_vio, var: p_bio_current_vio}, {name: p_bio_qtrs_in_vio, var: p_bio_qtrs_in_vio}, {name: p_bio_rpt_year, var: p_bio_rpt_year}, {name: p_bio_vio_last_year, var: p_bio_vio_last_year}, {name: p_msgp_rpt_year, var: p_msgp_rpt_year}, {name: p_vio_last_year, var: p_vio_last_year}, {name: responseset, var: responseset}, {name: callback, var: callback}, {name: qcolumns, var: qcolumns}, {name: p_pretty_print, var: p_pretty_print}, {name: p_e90_count, var: p_e90_count}, {name: p_e90_years, var: p_e90_years}, {name: p_psc, var: p_psc}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_fn: $p_fn, p_sa: $p_sa, p_sa1: $p_sa1, p_ct: $p_ct, p_co: $p_co, p_fips: $p_fips, p_st: $p_st, p_zip: $p_zip, p_frs: $p_frs, p_reg: $p_reg, p_sic: $p_sic, p_ncs: $p_ncs, p_pen: $p_pen, xmin: $xmin, ymin: $ymin, xmax: $xmax, ymax: $ymax, p_usmex: $p_usmex, p_sic2: $p_sic2, p_sic4: $p_sic4, p_fa: $p_fa, p_ff: $p_ff, p_act: $p_act, p_maj: $p_maj, p_mact: $p_mact, p_fea: $p_fea, p_feay: $p_feay, p_feaa: $p_feaa, p_iea: $p_iea, p_ieay: $p_ieay, p_ieaa: $p_ieaa, p_qiv: $p_qiv, p_iv: $p_iv, p_impw: $p_impw, p_imp_pol: $p_imp_pol, p_imp_cau_grp: $p_imp_cau_grp, p_trep: $p_trep, p_pm: $p_pm, p_pd: $p_pd, p_ico: $p_ico, p_huc: $p_huc, p_pid: $p_pid, p_med: $p_med, p_ysl: $p_ysl, p_ysly: $p_ysly, p_ysla: $p_ysla, p_qs: $p_qs, p_sfs: $p_sfs, p_tribeid: $p_tribeid, p_tribename: $p_tribename, p_tribedist: $p_tribedist, p_pstat: $p_pstat, p_ptype: $p_ptype, p_pcomp: $p_pcomp, p_plimits: $p_plimits, p_pcss: $p_pcss, p_pexp: $p_pexp, p_owop: $p_owop, p_ipfti: $p_ipfti, p_agoo: $p_agoo, p_idt1: $p_idt1, p_idt2: $p_idt2, p_pityp: $p_pityp, p_pfead1: $p_pfead1, p_pfead2: $p_pfead2, p_pfeat: $p_pfeat, p_pccs: $p_pccs, p_pexcd: $p_pexcd, p_psncq: $p_psncq, p_pctrack: $p_pctrack, p_dwd: $p_dwd, p_pt: $p_pt, p_pdwdist: $p_pdwdist, p_pswdpc: $p_pswdpc, p_pswdmp: $p_pswdmp, p_pswpol: $p_pswpol, p_pswcas: $p_pswcas, p_pswparam: $p_pswparam, p_pswvio: $p_pswvio, p_wbd: $p_wbd, p_radwbd: $p_radwbd, p_frswbd: $p_frswbd, p_fntype: $p_fntype, p_pidall: $p_pidall, p_months_last_dmr: $p_months_last_dmr, p_last_dmr_within: $p_last_dmr_within, p_indsw: $p_indsw, p_msgp_ptype: $p_msgp_ptype, p_mon_type: $p_mon_type, p_iagency: $p_iagency, p_permitting_agency: $p_permitting_agency, p_isws: $p_isws, p_iswss: $p_iswss, p_iswss_id: $p_iswss_id, p_ds1: $p_ds1, p_ds2: $p_ds2, p_da1: $p_da1, p_da2: $p_da2, p_ms4: $p_ms4, p_oo_fn: $p_oo_fn, p_oo_f_ntype: $p_oo_f_ntype, p_oo_sa: $p_oo_sa, p_oo_sa1: $p_oo_sa1, p_oo_ct: $p_oo_ct, p_oo_st: $p_oo_st, p_oo_zip: $p_oo_zip, p_fac_ico: $p_fac_ico, p_icoo: $p_icoo, p_fac_icos: $p_fac_icos, p_ejscreen: $p_ejscreen, p_alrexceed: $p_alrexceed, p_limit_addr: $p_limit_addr, p_lat: $p_lat, p_long: $p_long, p_radius: $p_radius, p_ejscreen_over80cnt: $p_ejscreen_over80cnt, p_bio_flag: $p_bio_flag, p_bio_fac_type: $p_bio_fac_type, p_bio_trtmnt_procs: $p_bio_trtmnt_procs, p_bio_analy_method_catgry: $p_bio_analy_method_catgry, p_bio_total_volume_amt: $p_bio_total_volume_amt, p_bio_mgmt_prctce_type: $p_bio_mgmt_prctce_type, p_bio_mgmt_prctce_stype: $p_bio_mgmt_prctce_stype, p_bio_mgmt_prctce_handler: $p_bio_mgmt_prctce_handler, p_bio_mgmt_container: $p_bio_mgmt_container, p_bio_mgmt_pathogen: $p_bio_mgmt_pathogen, p_bio_mgmt_pathred: $p_bio_mgmt_pathred, p_bio_mgmt_vector: $p_bio_mgmt_vector, p_bio_mgmt_def_category: $p_bio_mgmt_def_category, p_bio_mgmt_deficiencies: $p_bio_mgmt_deficiencies, p_bio_vio_code: $p_bio_vio_code, p_bio_current_vio: $p_bio_current_vio, p_bio_qtrs_in_vio: $p_bio_qtrs_in_vio, p_bio_rpt_year: $p_bio_rpt_year, p_bio_vio_last_year: $p_bio_vio_last_year, p_msgp_rpt_year: $p_msgp_rpt_year, p_vio_last_year: $p_vio_last_year, responseset: $responseset, callback: $callback, qcolumns: $qcolumns, p_pretty_print: $p_pretty_print, p_e90_count: $p_e90_count, p_e90_years: $p_e90_years, p_psc: $p_psc
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Clean Water Act (CWA) Facility Enhanced Search Service
#
# POST /cwa_rest_services.get_facility_info
# Returns: record<Results: record<BadSystemIDs: string, BioCVRows: string, BioV3Rows: string, CVRows: string, ClusterOutput: record<ClusterData: list>, ClusterRecords: string, FEARows: string, Facilities: list<record>, INSPRows: string, IconBaseURL: string, IndianCountryRows: string, InfFEARows: string, Message: string, PopUpBaseURL: string, QueryID: string, QueryParameters: list<record>, QueryRows: string, SVRows: string, ServiceBaseURL: string, TotalPenalties: string, V3Rows: string, VioLast4QRows: string>>
export def "post-cwa-rest-services-get-facility-info" [
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
  --output: string # Output Format Flag. Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding. - XML = Data model formatted as Extensible Markup Language. - CSV = Facility results formatted as comma delimited file download. - GEOJSON = Facility results formatted as GeoJSON feature collection. - GEOJSONP = Facility results formatted as GeoJSON feature collection with Padding. - GEOJSOND = Facility results formatted as GeoJSON feature collection download.
  --p-fn: string # Facility Name Filter. Enter one or more case-insensitive facility names to filter results. Provide multiple values as a comma-delimited list. See p_fntype for additional modifiers.
  --p-sa: string # Facility street address. Enter a complete or partial street address.
  --p-sa1: string # Facility street address. Enter a complete or partial street address. Note that p_sa1 is culmulative with p_sa.
  --p-ct: string # Facility City Filter. Enter a single case-insensitive city name to filter results.
  --p-co: string # Facility County Filter. Provide a single county name in combination with a state value provided via p_st.
  --p-fips: string # FIPS Code Filter. Enter a single 5-character Federal Information Processing Standards (FIPS) state + county value to restrict results. E.g. to limit results to Kenosha County, Wisconsin, use 55059.
  --p-st: string # Facility State and State-Equivalent Filter. Provide one or more USPS postal abbreviations for states and state-equivalents to filter results. Provide multiple values as a comma-delimited list.
  --p-zip: string # 5-Digit ZIP Code Filter. Provide one or more 5-digit postal zip codes to filter results. May contain multiple comma-separated values.
  --p-frs: string # Facility Registry Service ID Filter. Enter a single 12-digit FRS identifier to filter results.
  --p-reg: string@p-reg-completer # EPA Region Filter. Provide a single value of 01 thru 10 to restrict results to a single EPA region.
  --p-sic: string # Standard Industrial Classification (SIC) Code Filter. Enter a single 4-digit SIC Code to filter results. If more complex filtering is required, use p_sic2 and p_sic4.
  --p-ncs: string # North American Industry Classification System Filter. Enter two to six digits to filter results to facilities having matching NAICS codes. Digits less than six will match to all codes beginning with the provided values.
  --p-pen: string # Last Penality Date Qualifier Filter. Enter one of the following: - NEVER = No Penalties - ANY = Any Penalty - LEXX = Less than or equal to XX months. Provide a number in place of XX, e.g. "LE5" for a facility with a penalty within previous 5 months. - GTXX = Greater than XX months. Provide a number in place of XX, eg. GT12, for a facility with the last penalty greater than 12 months ago.
  --xmin: float # Minimum longitude value in decimal degrees.
  --ymin: float # Minimum latitude value in decimal degrees.
  --xmax: float # Maximum longitude value in decimal degrees.
  --ymax: float # Maximum latitude value in decimal degrees.
  --p-usmex: string@p-usmex-completer # US-Mexico Border Flag. Enter Y/N to restrict searches to facilities located within 100KM of the border.
  --p-sic2: string # Standard Industrial Classification (SIC) Code Filter Alternate 2. Enter a wild-card search against SIC codes. A final wild-card is always present allowing "22" to match all SIC codes beginning with 22. Use the "%" character within strings to match any SIC values with the pattern. For example, "2%21" matches 2021, 2121, 2221, etc.
  --p-sic4: string # Standard Industrial Classification (SIC) Code Filter Alternate 3. Enter the first 2, 3 or 4 SIC code digits to filter results to facilities having those code prefixes. As this alternative does not utilize an index, p_sic2 will generally be quicker.
  --p-fa: string # Federal Agency. 1 character or 5-character values; may contain multiple comma-separated values. ALL will retrieve all facilities where the federal agency code is not null. Use the Federal Agencies lookup service to obtain a list of values.
  --p-ff: string@p-ff-completer # Federal Facility Indicator Flag. Enter Y to restrict searches to federal facilities.
  --p-act: string # Active Permits/Facilities Flag. Provide Y or N to filter results to facilities with active permits. A Y will select ICIS NPDES permits with a status of effective, continued, or expired.
  --p-maj: string@p-maj-completer # Major Facility Flag. Enter Y to restrict results to Major facilities only.
  --p-mact: string # CAA Maximum Achievable Control Technology (MACT) Subpart codes (alpha ID between 1 and 7 characters) applicable to the facility.
  --p-fea: string@p-fea-completer # Formal Enforcement Actions [within / not within] specified date range indicator. The date range is determined by parameters p_fead1 and p_fead2 or by parameter p_feay. - W = within date range - N = not within date range
  --p-feay: float@p-feay-completer # Years (1 to 5) Range. This value is used to create a date range for Formal Enforcement Actions (FEA). Used along with p_fea (which indicates whether to look within or outside of the date range) to find FEAs within (or not within) the number of years specified.
  --p-feaa: string@p-feaa-completer # Agency associated with Formal Enforcement Actions: - E = EPA - S = State - A = All
  --p-iea: string@p-iea-completer # Informal Enforcement Actions [within / not within] specified date range. The date range is determined by parameters p_iead1 and p_iead2 or by parameter p_ieay. - W = within date range - N = not within date range
  --p-ieay: float@p-ieay-completer # Years (1 to 5) Range. This value is used to create a date range for Informal Enforcement Actions (IEA). Used along with p_iea (which indicates whether to look within or outside of the date range) to find IEAs within (or not within) the number of years specified.
  --p-ieaa: string@p-ieaa-completer # Agency associated with Informal Enforcement Actions. If left blank, both agencies are included. - E = EPA - S = State
  --p-qiv: string@p-qiv-completer # Quarters in Noncompliance Limiter. Enter a coded value to limit results to facilities with given quarter of noncompliance. - Z = Zero quarters in noncompliance. - GEXX = Replacing XX with a numeric value, that number of quarterd or more in noncompliance. - GTXX = Replacing XX with a numeric value, more than that number of quarters in noncompliance.
  --p-iv: string # Facility has a violation status of 'In Viol' during any of the selected quarters. Range: Fiscal Year 2020 Quarter 2 to Fiscal Year 2017 Quarter 2 Multiple values are comma delimited. |||||| Fiscal Years |||||| - FY2020 or FY20 or 2020 or 20 - FY2019 or FY19 or 2019 or 19 - FY2018 or FY18 or 2018 or 18 - FY2017 or FY17 or 2017 or 17 ||||| Fiscal Quarters ||||| - FY2020Q2 or FY20Q2 or 20202 or 202 or 13 - FY2020Q1 or FY20Q1 or 20201 or 201 or 12 - FY2019Q4 or FY19Q4 or 20194 or 194 or 11 - FY2019Q3 or FY19Q3 or 20193 or 193 or 10 - FY2019Q2 or FY19Q2 or 20192 or 192 or 9 - FY2019Q1 or FY19Q1 or 20191 or 191 or 8 - FY2018Q4 or FY18Q4 or 20184 or 184 or 7 - FY2018Q3 or FY18Q3 or 20183 or 183 or 6 - FY2018Q2 or FY18Q2 or 20182 or 182 or 5 - FY2018Q1 or FY18Q1 or 20181 or 181 or 4 - FY2017Q4 or FY17Q4 or 20174 or 174 or 3 - FY2017Q3 or FY17Q3 or 20173 or 173 or 2 - FY2017Q2 or FY17Q2 or 20172 or 172 or 1
  --p-impw: string@p-impw-completer # Discharging into Impaired Waters Flag. Enter Y to limit results to facilities with discharge to waterbodies listed as impaired in the ATTAINS database.
  --p-imp-pol: string@p-imp-pol-completer # Facility is discharging pollutants that are potentially contributing to the impairment of local waterbodies according to the ATTAINS database.
  --p-imp-cau-grp: string@p-imp-cau-grp-completer # Facility is discharging a pollutant group causing a waterbody to be impaired. Enter 1 through 34 (the internal number of the pollutant group); or enter a partial name such as Dioxin,Temp,tUrBidity.
  --p-trep: string@p-trep-completer # Current Toxics Release Inventory (TRI) Reporter Limiter. Enter one of the following codes to limit results. - CURR = Current TRI reporter. - NONCURR = Has reported to TRI in the past but not for the current reporting year.
  --p-pm: string@p-pm-completer # Percent Minority Population Limiter. Enter a value to restrict results to facilities with a given percentage of minority population within 3-mile radius. - NONE = 0% - GT5 = greater than 5% - GT10 = greater than 10% - GT25 = greater than 25% - GT50 = greater than 50% - GT75 = greater than 75%
  --p-pd: string@p-pd-completer # Population Density Limiter (per sq mile). Enter a value to limit results to facilities located in area of a given population density. - NONE = 0 population density per square mile - GT100 = More than 100 population density per square mile - GT500 = More than 500 population density per square mile - GT1000 = More than 1000 population density per square mile - GT5000 = More than 5000 population density per square mile - GT10000 = More than 10000 population density per square mile - GT20000 = More than 20000 population density per square mile
  --p-ico: string@p-ico-completer # Indian Country Flag. Enter a "Y" or "N" to restrict searches to facilities inside or outside Indian Country.
  --p-huc: string # 2-, 4-, 6-, or 8-character watershed code. May contain multiple comma-separated values.
  --p-pid: string # Nine-digit permit IDs. May contain up to 2000 comma-separated values.
  --p-med: string@p-med-completer # Filter Results by Media. - A = Air - M = RMP (Risk Management Plan) - R = RCRA (Hazardous Waste) - S = SDWA (Public Drinking Water Systems) - ALL = Air and RCRA and Water
  --p-ysl: string@p-ysl-completer # Last Facility Inspection [within / not within] Specified Date Range Indicator. The date range is determined by parameters p_idt1 and p_idt2 or by parameter p_ysly. - W = within date range - N = not within date range
  --p-ysly: float@p-ysly-completer # Number of years (1 to 5) since last facility inspection. A value of 1 means that it has been inspected within the year.
  --p-ysla: string@p-ysla-completer # Facility Last Inspection Code Filter. If left blank, both agencies are included. Enter a value to limit results: - E = EPA - S = State
  --p-qs: string # Quick Search. Allows entry for city, state, and/or zip code.
  --p-sfs: string # Single Facility Search Filter. Provide a facility name or program system identifier to limit results. For the all data search, the FRS registry identifier is also searched.
  --p-tribeid: float # Numeric code for tribe (or list of tribes).
  --p-tribename: string # Tribe Name Filter. Enter a single tribe name to filter results.
  --p-tribedist: float # Proximity to tribal land limiter. Enter an amount of mile between 0 and 25 to filter results. This parameter is only evaluated if p_tribeid is populated.
  --p-pstat: string # Permit Status Filter. Enter one or more of the following codes. Provide multiple values as a comma-delimited list. - EFF = Effective - EXP = Expired - PND = Pending - TRM = Terminated - RET = Retired - NON = Not Needed - ADC = Admin Continued
  --p-ptype: string # Permit Type Filter. Enter one or more code values to filter results. Provide multiple values as a comma-delimited list. - NPD = NPDES Individual Permit - NGP = NPDES Master General Permit - GPC = General Permit Covered Facility - SNN = State Issued Master General Permit (Non-NPDES) - IIU = Individual IU Permit (Non-NPDES) - SIN = Individual State Issued Permit (Non-NPDES) - APR = Associated Permit Record - UFT = Unpermitted Facility
  --p-pcomp: string # Permit Component Code Filter. Enter one or more codes to filter results. Provide multiple values as a comma-delimited list. - PRE = Pretreatment - CAF = CAFO - CSO = CSO - POT = POTW - BIO = Biosolids - SWS = Storm Water Small MS4s - SWM = Storm Water Medium/Large MS4s - SWI = Storm Water Industrial - SWC = Storm Water Construction
  --p-plimits: string@p-plimits-completer # Permit Limits Present Flag. Enter Y to limit results to facilities have present permit limits.
  --p-pcss: string@p-pcss-completer # Combined Sewer Systems Outflows Limiter. Enter one of the following to limit results to facilities having the given count of CSS outflows. - ALL = returns all facilities, regardless of the number of outflows. - GE1 = returns facilities with one or more outflows. - GE10 = returns facilities with ten or more outflows. - GE50 = returns facilities with fifty or more outflows.
  --p-pexp: string@p-pexp-completer # Permit Expired or Administratively Continued Limiter. Enter one of the following values to filter results. - EXP = limit results to facilities with permits expired or administratively continued. - EXPLE1YR = limit resuls to facilities with permits expired administratively continued within the past year. - EXPGT1YR = limit resuls to facilities with permits expired administratively continued more than a year ago.
  --p-owop: string@p-owop-completer # Owner/Operator code filter. Enter one of the following values to restrict results. - Federal = Federal facilities regulated under the NPDES program. - POTW = Publicly owned treatment works. Treatment works that are owned by a State, Tribe, or municipality. - Non-POTW = Non-publicly owned treatment works. Often referred to as "non-municipals" or "industrials".
  --p-ipfti: string
  --p-agoo: string@p-agoo-completer # Indicates whether to AND or OR the Owner/Operator parameter (p_owop) and the federal agency code (p_fa) parameters.
  --p-idt1: string # Beginning of date range of most recent facility inspection.
  --p-idt2: string # End of date range of most recent facility inspection.
  --p-pityp: string # Inspection Type Code. See ICIS Compliance Monitor Types lookup serivce for a list of available codes and descriptions.
  --p-pfead1: string # Formal Enforcement Action Date Range Start. Enter a date in MM/DD/YYYY format to set the start of the range for filtering by recent Formal Enforcement Action (FEA) taken against the facility within the last five years.
  --p-pfead2: string # Formal Enforcement Action Date Range End. Enter a date in MM/DD/YYYY format to set the end of the date range for filtering by recent Formal Enforcement Action (FEA) taken against the facility within the last five years.
  --p-pfeat: string # Formal Enforcement Action (FEA) Code Filter. Enter one or more three-letter FEA codes to restrict results to facilities with these attributes. Use p_fead1 and p_fead2 parameters to further restrict this filter by entering a date range. Provide multiple codes as a comma-delimited list.
  --p-pccs: string # Current Compliance Status: ||||||||||||||||||||||||||| Significant Noncompliance (SNC) ||||||||||||||||||||||||||| - SNC = E, S, X, T, D - E�= E(EffViol) - S�= S(CSchVio) - X = X(EffNMth) - T = T(CSchRpt) - D�= D(DMR NR) ||||||||||||||||||||||||||| Noncompliance (NC) ||||||||||||||||||||||||||| - NC = N, V - N�= N(RptViol) - V�= V(NonRNCV) ||||||||||||||||||||||||||| New Violations (PQV) ||||||||||||||||||||||||||| - PQV = New Violations (13th Quarter) ||||||||||||||||||||||||||| No Violations (NV) ||||||||||||||||||||||||||| - NV = R, P, M, U, W , Blank, and No New Violations (no PQV) - R�= R(Resolvd) - P�= P(ResPend) - M�= C(Manual) - U = U(N/A) - W = W(N/A) - Blank = (null) May contain multiple comma-separated values.
  --p-pexcd: string@p-pexcd-completer # 3-Year Effluent Exceedances Limiter. Enter a value to restrict results to facilities with the given amount of exceedances in the past 3 years. - 0 = facilities with no exceedances - GE0 = facilities with one or more exceedances - GE10 = facilities with ten or more exceedances - GE50 = facilities with fifty or more exceedances - GE100 = facilities with one hundred or more exceedances
  --p-psncq: string@p-psncq-completer # Quarters in Significant Noncompliance Limiter. Enter a coded value to limit results to facilities with given quarter of significant noncompliance. - Z = Zero quarters in significant noncompliance. - GEXX = Replacing XX with a numeric value, that number of quarterd or more in significant noncompliance. - GTXX = Replacing XX with a numeric value, more than that number of quarters in significant noncompliance.
  --p-pctrack: string@p-pctrack-completer # Compliance Tracking Limiter. Provide a keyword to indicate the extent to which data is being entered and effluent exceedances are being identified. - Off - Partial - On
  --p-dwd: string@p-dwd-completer # Direct Water Discharges. Pounds of toxic chemicals released directly to surface water as reported to the Toxics Release Inventory.
  --p-pt: string@p-pt-completer # POTW Transfers. Pounds of toxic chemicals transferred to a Publicly Operated Treatment Works (POTW) as reported to the Toxics Release Inventory.
  --p-pdwdist: string@p-pdwdist-completer # Distance (in miles) to downstream drinking water intake.
  --p-pswdpc: string # Pollutant Category Code: Values: WTR for Water, AIR for Air
  --p-pswdmp: string@p-pswdmp-completer # Used to determine limit begin and end dates for surface water discharges. Number represents years from current date.
  --p-pswpol: string # For CWA, pollutant names for surface water discharges. for Drinking Water, SDWIS Violation contaminant codes for unaddressed violations that have occurred in the last 3 years. May contain multiple comma-separated values.
  --p-pswcas: string # CAS numbers for surface water discharges. May contain multiple comma-separated values.
  --p-pswparam: string # Parameter codes for surface water discharges. May contain multiple comma-separated values.
  --p-pswvio: string@p-pswvio-completer # Used in conjuction with parameters p_pswpol and p_pswparam, indicates whether search should only include pollutants with violations.
  --p-wbd: string # 2-, 4-, 6-, 8-, 10-, or 12-character watershed (WBD from the USGS Watershed Boundary Dataset). May contain multiple comma-separated values. Uses the FRS Best Pick Coordinate to obtain the WBD12 Huc value.
  --p-radwbd: string # 2-, 4-, 6-, 8-, 10-, or 12 character watershed (WBD from the USGS Watershed Boundary Dataset). May contain multiple comma-separated values. Will search against WBD values otained by "reach indexing" NPDES permits against the medium resolution National Hydrography Dataset.
  --p-frswbd: string # Works exactly the same as the p_wbd parameter. 2-, 4-, 6-, 8-, 10-, or 12-character watershed (WBD from the USGS Watershed Boundary Dataset). May contain multiple comma-separated values. Uses the FRS Best Pick Coordinate to obtain the WBD12 Huc value.
  --p-fntype: string@p-fntype-completer # Controls type of text search performed on facility name with parameter p_fn. - EXACT = Find facilities having the exact provided name(s). - BEGINS = Find facilities with names starting with the provided term(s). - ALL = Find facilities using Oracle text search terms. - CONTAINS =
  --p-pidall: string@p-pidall-completer # Controls whether search is restricted to existing system. Y means the search will match the p_pid parameter against all associated permits (AIR, RCRA, SDWIS, etc).
  --p-months-last-dmr: float # The number of months since the last Discharge Monitoring Report has been submitted.
  --p-last-dmr-within: string@p-last-dmr-within-completer # W value returns facilities that have submitted DMRs within the number of months specified by p_months_last_dmr. An N value returns facilities that have not submitted a DMR within the specified number of months.
  --p-indsw: string@p-indsw-completer # Industrial Stormwater Permit Flag. Enter a Y or N to filter results by this type of permit.
  --p-msgp-ptype: string@p-msgp-ptype-completer # Multi-Sector General Purpose Permit Type. Enter a value to filter results by MSGP Permit Type. - NOI = Notice of Intent - NOE = No Exposure Certification
  --p-mon-type: string@p-mon-type-completer # For use with the Industrial Stormwater search only. Valid values are BENCHGS fro Benchmark (Alert Limit) G2 Ore, BENCH for Benchmark (Alert Limit), and ELG fro Effluent Limitation Guidelines(ELG)(Effluent Limit).
  --p-iagency: string # Issuing Agency Limiter. Enter a single value to filter results by the issuing agency, e.g. "State" or "EPA".
  --p-permitting-agency: string
  --p-isws: string # Multi-Sector General Purpose Permit Subsector Individual Identifier. Enter a value to filter results.
  --p-iswss: string # Multi-Sector General Purpose Permit Subsector Group Code. Enter a value to filter results.
  --p-iswss-id: string # Multi-Sector General Purpose Permit Sector Code. Enter a value to filter results.
  --p-ds1: string # Submitted Date Filter Start. To filter by the date of submission, enter a start date here and an end date in the p_ds2 parameter. Both dates are required for filtering.
  --p-ds2: string # Submitted Date Filter End. To filter by the date of submission, enter an end date here and a start date in the p_ds1 parameter. Both dates are required for filtering.
  --p-da1: string # Active Date Filter Start. To filter by the active date, enter a start date here and an end date in the p_da2 parameter. Both dates are required for filtering.
  --p-da2: string # Active Date Filter End. To filter by the active date, enter an end date here and a start date in the p_da1 parameter. Both dates are required for filtering.
  --p-ms4: string@p-ms4-completer # Municipal Separate Storm Water Sewer (MS4) Permit Flag. Enter a Y or N to filter results by this type of permit.
  --p-oo-fn: string # Owner/Operator Name. Enter the owner/operator name of the facility.
  --p-oo-f-ntype: string@p-oo-f-ntype-completer # Owner/Operator Name Multiple Selection Evaluator.
  --p-oo-sa: string # Owner/Operator Address. Enter the address of the owner/operator of the facility.
  --p-oo-sa1: string # Owner/Operator Address Line 2. Enter the line 2 address of the owner/operator of the facility.
  --p-oo-ct: string # Owner/Operator City. Enter the city where the owner/operator of the facility is located.
  --p-oo-st: string # Owner/Operator State. Enter the standardized postal state code where the owner/operator of the facility is located.
  --p-oo-zip: string # Owner/Operator Zip Code. Enter the postal zip code where the owner/operator of the facility is located.
  --p-fac-ico: string@p-fac-ico-completer # FRS tribal land code flag. Enter "Y" or "N" to include or exclude facilities based on FRS tribal land code.
  --p-icoo: string # Indian country search and/or flag. Enter "Y" to set indian country search conditions to return any results found using p_ico, p_fac_ico or p_fac_icoo. Otherwise only results matching all provided p_ico, p_fac_ico or p_fac_icoo conditions will be returned.
  --p-fac-icos: string # FRS tribal land spatial flag. Enter "Y" or "N" to include or exclude facilities based on FRS tribal land spatial flag.
  --p-ejscreen: string # Enter "Y" to limit facilities to Census block groups where one of more Environmental Justice indexes above 80th percentile.
  --p-alrexceed: float # Alert Limits Exceedences Limiter. Enter a numeric value to restrict results to facilities having the given amount or more of alert limits exceedances.
  --p-limit-addr: string@p-limit-addr-completer # Limit Address Search Flag. Enter Y to restrict facility searches to native data source only.
  --p-lat: float # Latitude location in decimal degrees.
  --p-long: float # Longitude location in decimal degrees.
  --p-radius: float # Spatial Search Radius. Enter a radius up to 100 miles in which to spatially search for facilities.
  --p-ejscreen-over80cnt: string@p-ejscreen-over80cnt-completer # The number of Environmenmt Justice Indicators above the 80th percentile. Valid values are 1 through 11.
  --p-bio-flag: string # A Y value will select all biosolid-related permits.
  --p-bio-fac-type: string # The code indicating the reporting obligation reason: - POT = A POTW with a design flow rate equal to or greater than one million gallons per day - CLI = A Class I Sludge Management Facility as defined in 40 CFR 503.9 - PPL = A POTW that serves 10,000 people or more - OTH = Otherwise required to report (e.g., permit condition, enforcement action) - NOA = None of the above
  --p-bio-trtmnt-procs: string # The biosolids or sewage sludge treatment process or processes at the facility: - AER = Aerobic Digestion - AIR = Air Drying (or Sludge Drying Beds) - ANA = Anaerobic Digestion - COD = Beta Ray Irradiation - COM = Lower Temperature Composting - DEW = Pasteurization - DIS = Gamma Ray Irradiation - HEA = Heat Drying (e.g., Flash Dryer, Spray Dryer, Rotary Dryer) - HET = Heat Treatment (Liquid Sewage Sludge Heated to 356 Deg. F/180 Deg. C or Higher for 30 min.) - HTC = Higher Temperature Composting - MET = Methane or Biogas Capture and Recovery - OTH = Other Treatment Process - PRE = Preliminary Operations (e.g., Sludge Grinding, Degritting, Blending) - SLU = Sludge Lagoon - STA = Lime Stabilization - THE = Temporary Sludge Storage (Sewage Sludge Stored on Land 2 Years or Less, Not in Sewage Sludge Unit) - THI = Thickening (Gravity and/or Flotation Thickening, Centrifugation, Belt Filter Press, Vacuum Filter) - THM = Thermophilic Aerobic Digestion - UND = Long-Term Sludge Storage (Sewage Sludge Stored on Land 2 Years or More, not in Sewage Sludge Unit)"
  --p-bio-analy-method-catgry: string # The unique code for the category of the analytic methods used by the facility to analyze regulated parameters (including enteric viruses, fecal coliforms, helminth ova, and Salmonella sp.) at the facility: - PAT = Pathogens - MET = Metals - NIT = Nitrogen Compounds - OTH = Other Analytes
  --p-bio-total-volume-amt: string # Total annual amount (in dry metric tons) of biosolids or sewage sludge generated at the facility. - EQ0 = 0 - IN0_1 = GT 0 but LT 1 - IN0_289 = GT 0 but LT 290 MT/year - IN290_1499 = GE 290 but LT 1500 MT/year - IN1500_14999 = GE 1500 but LT 15,000 - GE15000 = GE 15,000
  --p-bio-mgmt-prctce-type: string # The unique code that identifies the type of biosolids or sewage sludge management practice (e.g., land application, surface disposal, incineration) used by the facility. The facility will separately report the management practice for each biosolids or sewage sludge form and pathogen class. This data element will also identify the management practices used by surface disposal site owners/operators (see 40 CFR 503.24): - BIN = Incineration - BLN = Land Application - BOT = Other Management Practice - BSD = Surface Disposal
  --p-bio-mgmt-prctce-stype: string # This is the code indicating additional detail about the type of Management Practice used for a volume of Biosolids or Sewage Sludge: - ADV = Advanced Alkaline Stabilized Biosolids Distribution & Marketing - AGR = Agricultural Land Application - COM = Distribution and Marketing - Compost - DEE = Deep-well Injection Disposal - DIS = Disposal in a Municipal Landfill (under 40 CFR 258) - DMO = Distribution and Marketing - Other - HEA = Heat Dried Biosolids Distribution & Marketing - OTL = Other Land Application Management Practice Detail - OTO = Other Management Practice Detail - RSA = Reclamation Site Application - SEN = Sent to Cement Kiln for Use as Alternative Energy - STO = Storage - UIC = Use in Construction - UPS = Used in Production of Syngas - USE = Use as Daily Cover for Municipal Landfill (under 40 CFR 258)
  --p-bio-mgmt-prctce-handler: string # This is the code indicating the type of Biosolids or Sewage Sludge handlers/preparers. - OWN = Owner or Operator - OFF = Off-Site Third-Party Handler or Preparer
  --p-bio-mgmt-container: string # The code that identifies the nature of each biosolids and sewage sludge material generated by the facility in terms of whether the material is a biosolid or sewage sludge and whether the material is ultimately conveyed off-site in bulk or in bags. The facility separately reports the form for each biosolids or sewage sludge management practice or practices used by the facility and pathogen class: - BUL = Bulk - BAG = Bag or Container
  --p-bio-mgmt-pathogen: string # This code identifies the pathogen class [e.g., Class A, Class B, Not Applicable (Incineration)] for biosolids or sewage sludge generated by the facility. The facility will separately report the pathogen class for each biosolids or sewage sludge management practice used by the facility and by each biosolids or sewage sludge form. It also is used to filter applicable Pathogen Reduction and Vector Attraction Reduction Options as well as Land Application Management Practice Deficiencies. Only reqired for some of the mgmt. practice types: - AAA = Class A - AEQ = Class A EQ (sale/give away) - BBB = Class B - NAP = Not Applicable (Incineration)
  --p-bio-mgmt-pathred: string # This is the description of the option used by the facility to control pathogen for a Biosolids Management Practice: - A1 = Class A - Alternative 1: Time/Temperature - A2 = Class A - Alternative 2: pH/Temperature/Percent Solids - A3 = Class A - Alternative 3: Test Enteric Viruses and Helminth ova; Operating Parameters - A4 = Class A - Alternative 4: Test Enteric Viruses and Helminth ova; No New Solids - A51 = Class A - Alternative 5: PFRP 1: Composting - A52 = Class A - Alternative 5: PFRP 2: Heat Drying - A53 = Class A - Alternative 5: PFRP 3: Liquid heat treatment - A54 = Class A - Alternative 5: PFRP 4: Thermophilic Aerobic Digestion (ATAD) - A55 = Class A - Alternative 5 PFPR 5: Beta Ray Irradiation - A56 = Class A - Alternative 5 PFPR 6: Gamma Ray Irradiation - A57 = Class A - Alternative 5: PFRP 7: Pasteurization - A6 = Class A - Alternative 6: PFRP Equivalency - B1 = Class B - Alternative 1: Fecal Coliform Geometric Mean - B21 = Class B - Alternative 2 PSRP 1: Aerobic Digestion - B22 = Class B - Alternative 2 PSRP 2: Air Drying - B23 = Class B - Alternative 2 PSRP 3: Anaerobic Digestion - B24 = Class B - Alternative 2 PSRP 4: Composting - B25 = Class B - Alternative 2 PSRP 5: Lime Stabilization - B3 = Class B - Alternative 3: PSRP Equivalency - PH = pH Adjustment (Domestic Septage)
  --p-bio-mgmt-vector: string # The unique code that identifies the option used by the facility for vector attraction reduction. See a listing of these vector attraction reduction options at 40 CFR 503.33(b)(1) through (11). The facility will separately report the vector attraction reduction options for each biosolids or sewage sludge management practice used by the facility and by each biosolids or sewage sludge form as well as by each biosolids or sewage sludge pathogen class: - VR1 = Option 1 - Volatile Solids Reduction - VR2 = Option 2 - Bench-Scale Volatile Solids Reduction (Anaerobic Bench Test) - VR3 = Option 3 - Bench-Scale Volatile Solids Reduction (Aerobic Bench Test w/ Percent Solids - 2% or Less) - VR4 = Option 4 - Specific Oxygen Uptake Rate - VR5 = Option 5 - Aerobic Processing (Thermophilic Aerobic Digestion/Composting) - VR6 = Option 6 - Alkaline Treatment - VR7 = Option 7 - Drying (Equal to or Greater than 75 Percent) - VR8 = Option 8 - Drying (Equal to or Greater than 90 Percent) - VR9 = Option 9 - Sewage Sludge Injection - V10 = Option 10 - Sewage Sludge Timely Incorporation into Land - V11 = Option 11 - Sewage Sludge Covered at the End of Each Operating Day
  --p-bio-mgmt-def-category: string # This is the code indicating the type of NPDES special regulatory program deficiency: - INC = Biosolids Incineration - LNA = Biosolids Land Application - LNB = Biosolids Land Application - Pathogen Class B - OTB = Biosolids Other Management Practice - SFD = Biosolids Surface Disposal
  --p-bio-mgmt-deficiencies: float # The number of times noncompliance was reported by the facility in the last 3 years. The results returned will include facilities whose number of reported noncompliance events is greater than or equal to the number entered.
  --p-bio-vio-code: string # The Biosolids Single Event Violation Code. Enter one or mode codes.
  --p-bio-current-vio: string@p-bio-current-vio-completer # Indicator of whether the facility is currently in violation for biosolids under the Clean Water Act, in the 12th or 13th quarter: - Y = Yes - N = No
  --p-bio-qtrs-in-vio: float # The number of quarters, in the last three years, where the facility was in violation for a biosolids violation type. The results returned will include facilities whose number of quarters with violations is greater than or equal to the number entered.
  --p-bio-rpt-year: string # The last year that the permittee submitted an annual Biosolids report. Valid values are NONE and any year greater or equal to 2016.
  --p-bio-vio-last-year: string@p-bio-vio-last-year-completer # Identifies if a biosolids violation has occured in the last year. Valid values are Y and N.
  --p-msgp-rpt-year: string # The last year that a MSGP report was submitted for the permit. Valid values are "NONE" and any year Greater or Eqal to 2015.
  --p-vio-last-year: string@p-vio-last-year-completer # Identifies if a permit violation has occured in the last year. Valid values are Y and N.
  --responseset: float # Response Set Limiter. Enter a value to limit the number of records per page. Value cannot exceed 1,000.
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
  --qcolumns: string # Used to customize service output. A list of comma-separated column IDs of output objects that will be returned in the service query object or download. Use the metadata service endpoint for a complete list of Ids and definitions.
  --p-pretty-print: float # Optional flag to request GeoJSON formatted results to be pretty printed. Only provide a numeric value when the output needs to be human readable as pretty printing has a performance cost.
  --p-e90-count: float # Number of E90 Exceedances. Identifies water permits with a number of E90 (Effluient Exceedances) >= the value provided for the last number of years provided by the p_e90_years value.
  --p-e90-years: float # Number of years for the p_e90_count search. Identified the past number of years to be used for the p_e90_count search.
  --p-psc: string # Point Source Category.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/cwa_rest_services.get_facility_info"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: p_fn, var: p_fn}, {name: p_sa, var: p_sa}, {name: p_sa1, var: p_sa1}, {name: p_ct, var: p_ct}, {name: p_co, var: p_co}, {name: p_fips, var: p_fips}, {name: p_st, var: p_st}, {name: p_zip, var: p_zip}, {name: p_frs, var: p_frs}, {name: p_reg, var: p_reg}, {name: p_sic, var: p_sic}, {name: p_ncs, var: p_ncs}, {name: p_pen, var: p_pen}, {name: xmin, var: xmin}, {name: ymin, var: ymin}, {name: xmax, var: xmax}, {name: ymax, var: ymax}, {name: p_usmex, var: p_usmex}, {name: p_sic2, var: p_sic2}, {name: p_sic4, var: p_sic4}, {name: p_fa, var: p_fa}, {name: p_ff, var: p_ff}, {name: p_act, var: p_act}, {name: p_maj, var: p_maj}, {name: p_mact, var: p_mact}, {name: p_fea, var: p_fea}, {name: p_feay, var: p_feay}, {name: p_feaa, var: p_feaa}, {name: p_iea, var: p_iea}, {name: p_ieay, var: p_ieay}, {name: p_ieaa, var: p_ieaa}, {name: p_qiv, var: p_qiv}, {name: p_iv, var: p_iv}, {name: p_impw, var: p_impw}, {name: p_imp_pol, var: p_imp_pol}, {name: p_imp_cau_grp, var: p_imp_cau_grp}, {name: p_trep, var: p_trep}, {name: p_pm, var: p_pm}, {name: p_pd, var: p_pd}, {name: p_ico, var: p_ico}, {name: p_huc, var: p_huc}, {name: p_pid, var: p_pid}, {name: p_med, var: p_med}, {name: p_ysl, var: p_ysl}, {name: p_ysly, var: p_ysly}, {name: p_ysla, var: p_ysla}, {name: p_qs, var: p_qs}, {name: p_sfs, var: p_sfs}, {name: p_tribeid, var: p_tribeid}, {name: p_tribename, var: p_tribename}, {name: p_tribedist, var: p_tribedist}, {name: p_pstat, var: p_pstat}, {name: p_ptype, var: p_ptype}, {name: p_pcomp, var: p_pcomp}, {name: p_plimits, var: p_plimits}, {name: p_pcss, var: p_pcss}, {name: p_pexp, var: p_pexp}, {name: p_owop, var: p_owop}, {name: p_ipfti, var: p_ipfti}, {name: p_agoo, var: p_agoo}, {name: p_idt1, var: p_idt1}, {name: p_idt2, var: p_idt2}, {name: p_pityp, var: p_pityp}, {name: p_pfead1, var: p_pfead1}, {name: p_pfead2, var: p_pfead2}, {name: p_pfeat, var: p_pfeat}, {name: p_pccs, var: p_pccs}, {name: p_pexcd, var: p_pexcd}, {name: p_psncq, var: p_psncq}, {name: p_pctrack, var: p_pctrack}, {name: p_dwd, var: p_dwd}, {name: p_pt, var: p_pt}, {name: p_pdwdist, var: p_pdwdist}, {name: p_pswdpc, var: p_pswdpc}, {name: p_pswdmp, var: p_pswdmp}, {name: p_pswpol, var: p_pswpol}, {name: p_pswcas, var: p_pswcas}, {name: p_pswparam, var: p_pswparam}, {name: p_pswvio, var: p_pswvio}, {name: p_wbd, var: p_wbd}, {name: p_radwbd, var: p_radwbd}, {name: p_frswbd, var: p_frswbd}, {name: p_fntype, var: p_fntype}, {name: p_pidall, var: p_pidall}, {name: p_months_last_dmr, var: p_months_last_dmr}, {name: p_last_dmr_within, var: p_last_dmr_within}, {name: p_indsw, var: p_indsw}, {name: p_msgp_ptype, var: p_msgp_ptype}, {name: p_mon_type, var: p_mon_type}, {name: p_iagency, var: p_iagency}, {name: p_permitting_agency, var: p_permitting_agency}, {name: p_isws, var: p_isws}, {name: p_iswss, var: p_iswss}, {name: p_iswssID, var: p_iswss_id}, {name: p_ds1, var: p_ds1}, {name: p_ds2, var: p_ds2}, {name: p_da1, var: p_da1}, {name: p_da2, var: p_da2}, {name: p_MS4, var: p_ms4}, {name: p_ooFN, var: p_oo_fn}, {name: p_ooFNtype, var: p_oo_f_ntype}, {name: p_ooSA, var: p_oo_sa}, {name: p_ooSA1, var: p_oo_sa1}, {name: p_ooCt, var: p_oo_ct}, {name: p_ooSt, var: p_oo_st}, {name: p_ooZip, var: p_oo_zip}, {name: p_fac_ico, var: p_fac_ico}, {name: p_icoo, var: p_icoo}, {name: p_fac_icos, var: p_fac_icos}, {name: p_ejscreen, var: p_ejscreen}, {name: p_alrexceed, var: p_alrexceed}, {name: p_limit_addr, var: p_limit_addr}, {name: p_lat, var: p_lat}, {name: p_long, var: p_long}, {name: p_radius, var: p_radius}, {name: p_ejscreen_over80cnt, var: p_ejscreen_over80cnt}, {name: p_bio_flag, var: p_bio_flag}, {name: p_bio_fac_type, var: p_bio_fac_type}, {name: p_bio_trtmnt_procs, var: p_bio_trtmnt_procs}, {name: p_bio_analy_method_catgry, var: p_bio_analy_method_catgry}, {name: p_bio_total_volume_amt, var: p_bio_total_volume_amt}, {name: p_bio_mgmt_prctce_type, var: p_bio_mgmt_prctce_type}, {name: p_bio_mgmt_prctce_stype, var: p_bio_mgmt_prctce_stype}, {name: p_bio_mgmt_prctce_handler, var: p_bio_mgmt_prctce_handler}, {name: p_bio_mgmt_container, var: p_bio_mgmt_container}, {name: p_bio_mgmt_pathogen, var: p_bio_mgmt_pathogen}, {name: p_bio_mgmt_pathred, var: p_bio_mgmt_pathred}, {name: p_bio_mgmt_vector, var: p_bio_mgmt_vector}, {name: p_bio_mgmt_def_category, var: p_bio_mgmt_def_category}, {name: p_bio_mgmt_deficiencies, var: p_bio_mgmt_deficiencies}, {name: p_bio_vio_code, var: p_bio_vio_code}, {name: p_bio_current_vio, var: p_bio_current_vio}, {name: p_bio_qtrs_in_vio, var: p_bio_qtrs_in_vio}, {name: p_bio_rpt_year, var: p_bio_rpt_year}, {name: p_bio_vio_last_year, var: p_bio_vio_last_year}, {name: p_msgp_rpt_year, var: p_msgp_rpt_year}, {name: p_vio_last_year, var: p_vio_last_year}, {name: responseset, var: responseset}, {name: callback, var: callback}, {name: qcolumns, var: qcolumns}, {name: p_pretty_print, var: p_pretty_print}, {name: p_e90_count, var: p_e90_count}, {name: p_e90_years, var: p_e90_years}, {name: p_psc, var: p_psc}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_fn: $p_fn, p_sa: $p_sa, p_sa1: $p_sa1, p_ct: $p_ct, p_co: $p_co, p_fips: $p_fips, p_st: $p_st, p_zip: $p_zip, p_frs: $p_frs, p_reg: $p_reg, p_sic: $p_sic, p_ncs: $p_ncs, p_pen: $p_pen, xmin: $xmin, ymin: $ymin, xmax: $xmax, ymax: $ymax, p_usmex: $p_usmex, p_sic2: $p_sic2, p_sic4: $p_sic4, p_fa: $p_fa, p_ff: $p_ff, p_act: $p_act, p_maj: $p_maj, p_mact: $p_mact, p_fea: $p_fea, p_feay: $p_feay, p_feaa: $p_feaa, p_iea: $p_iea, p_ieay: $p_ieay, p_ieaa: $p_ieaa, p_qiv: $p_qiv, p_iv: $p_iv, p_impw: $p_impw, p_imp_pol: $p_imp_pol, p_imp_cau_grp: $p_imp_cau_grp, p_trep: $p_trep, p_pm: $p_pm, p_pd: $p_pd, p_ico: $p_ico, p_huc: $p_huc, p_pid: $p_pid, p_med: $p_med, p_ysl: $p_ysl, p_ysly: $p_ysly, p_ysla: $p_ysla, p_qs: $p_qs, p_sfs: $p_sfs, p_tribeid: $p_tribeid, p_tribename: $p_tribename, p_tribedist: $p_tribedist, p_pstat: $p_pstat, p_ptype: $p_ptype, p_pcomp: $p_pcomp, p_plimits: $p_plimits, p_pcss: $p_pcss, p_pexp: $p_pexp, p_owop: $p_owop, p_ipfti: $p_ipfti, p_agoo: $p_agoo, p_idt1: $p_idt1, p_idt2: $p_idt2, p_pityp: $p_pityp, p_pfead1: $p_pfead1, p_pfead2: $p_pfead2, p_pfeat: $p_pfeat, p_pccs: $p_pccs, p_pexcd: $p_pexcd, p_psncq: $p_psncq, p_pctrack: $p_pctrack, p_dwd: $p_dwd, p_pt: $p_pt, p_pdwdist: $p_pdwdist, p_pswdpc: $p_pswdpc, p_pswdmp: $p_pswdmp, p_pswpol: $p_pswpol, p_pswcas: $p_pswcas, p_pswparam: $p_pswparam, p_pswvio: $p_pswvio, p_wbd: $p_wbd, p_radwbd: $p_radwbd, p_frswbd: $p_frswbd, p_fntype: $p_fntype, p_pidall: $p_pidall, p_months_last_dmr: $p_months_last_dmr, p_last_dmr_within: $p_last_dmr_within, p_indsw: $p_indsw, p_msgp_ptype: $p_msgp_ptype, p_mon_type: $p_mon_type, p_iagency: $p_iagency, p_permitting_agency: $p_permitting_agency, p_isws: $p_isws, p_iswss: $p_iswss, p_iswss_id: $p_iswss_id, p_ds1: $p_ds1, p_ds2: $p_ds2, p_da1: $p_da1, p_da2: $p_da2, p_ms4: $p_ms4, p_oo_fn: $p_oo_fn, p_oo_f_ntype: $p_oo_f_ntype, p_oo_sa: $p_oo_sa, p_oo_sa1: $p_oo_sa1, p_oo_ct: $p_oo_ct, p_oo_st: $p_oo_st, p_oo_zip: $p_oo_zip, p_fac_ico: $p_fac_ico, p_icoo: $p_icoo, p_fac_icos: $p_fac_icos, p_ejscreen: $p_ejscreen, p_alrexceed: $p_alrexceed, p_limit_addr: $p_limit_addr, p_lat: $p_lat, p_long: $p_long, p_radius: $p_radius, p_ejscreen_over80cnt: $p_ejscreen_over80cnt, p_bio_flag: $p_bio_flag, p_bio_fac_type: $p_bio_fac_type, p_bio_trtmnt_procs: $p_bio_trtmnt_procs, p_bio_analy_method_catgry: $p_bio_analy_method_catgry, p_bio_total_volume_amt: $p_bio_total_volume_amt, p_bio_mgmt_prctce_type: $p_bio_mgmt_prctce_type, p_bio_mgmt_prctce_stype: $p_bio_mgmt_prctce_stype, p_bio_mgmt_prctce_handler: $p_bio_mgmt_prctce_handler, p_bio_mgmt_container: $p_bio_mgmt_container, p_bio_mgmt_pathogen: $p_bio_mgmt_pathogen, p_bio_mgmt_pathred: $p_bio_mgmt_pathred, p_bio_mgmt_vector: $p_bio_mgmt_vector, p_bio_mgmt_def_category: $p_bio_mgmt_def_category, p_bio_mgmt_deficiencies: $p_bio_mgmt_deficiencies, p_bio_vio_code: $p_bio_vio_code, p_bio_current_vio: $p_bio_current_vio, p_bio_qtrs_in_vio: $p_bio_qtrs_in_vio, p_bio_rpt_year: $p_bio_rpt_year, p_bio_vio_last_year: $p_bio_vio_last_year, p_msgp_rpt_year: $p_msgp_rpt_year, p_vio_last_year: $p_vio_last_year, responseset: $responseset, callback: $callback, qcolumns: $qcolumns, p_pretty_print: $p_pretty_print, p_e90_count: $p_e90_count, p_e90_years: $p_e90_years, p_psc: $p_psc
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Clean Water Act (CWA) GeoJSON Service
#
# GET /cwa_rest_services.get_geojson
# Returns: record<features: table<geometry: record, properties: record, type: string>, type: string>
export def "get-cwa-rest-services-get-geojson" [
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
  --output: string # Output Format Flag. Enter one of the following keywords: - GEOJSON = Facility results formatted as GeoJSON feature collection (default). - GEOJSONP = Facility results formatted as GeoJSON feature collection with Padding. - GEOJSOND = Facility results formatted as GeoJSON feature collection download.
  --qid: string # Query ID Selector. Enter the QueryID number from a previously run query. (required)
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
  --newsort: float # Output Sort Column. Enter the number of the column on which the data will be sorted. If unpopulated results will sort on the first column.
  --descending: string@descending-completer # Output Sort Column Descending Flag. Enter Y to column identified in the newsort parameter descending. Enter N to use ascending sort order. Used only when newsort parameter is populated.
  --qcolumns: string # Used to customize service output. A list of comma-separated column IDs of output objects that will be returned in the service query object or download. Use the metadata service endpoint for a complete list of Ids and definitions.
  --p-pretty-print: float # Optional flag to request GeoJSON formatted results to be pretty printed. Only provide a numeric value when the output needs to be human readable as pretty printing has a performance cost.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/cwa_rest_services.get_geojson"
    query: [{name: output, var: output}, {name: qid, var: qid, required: true}, {name: callback, var: callback}, {name: newsort, var: newsort}, {name: descending, var: descending}, {name: qcolumns, var: qcolumns}, {name: p_pretty_print, var: p_pretty_print}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, qid: $qid, callback: $callback, newsort: $newsort, descending: $descending, qcolumns: $qcolumns, p_pretty_print: $p_pretty_print
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Clean Water Act (CWA) GeoJSON Service
#
# POST /cwa_rest_services.get_geojson
# Returns: record<features: table<geometry: record, properties: record, type: string>, type: string>
export def "post-cwa-rest-services-get-geojson" [
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
  --output: string # Output Format Flag. Enter one of the following keywords: - GEOJSON = Facility results formatted as GeoJSON feature collection (default). - GEOJSONP = Facility results formatted as GeoJSON feature collection with Padding. - GEOJSOND = Facility results formatted as GeoJSON feature collection download.
  qid: string # Query ID Selector. Enter the QueryID number from a previously run query.
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
  --newsort: float # Output Sort Column. Enter the number of the column on which the data will be sorted. If unpopulated results will sort on the first column.
  --descending: string@descending-completer # Output Sort Column Descending Flag. Enter Y to column identified in the newsort parameter descending. Enter N to use ascending sort order. Used only when newsort parameter is populated.
  --qcolumns: string # Used to customize service output. A list of comma-separated column IDs of output objects that will be returned in the service query object or download. Use the metadata service endpoint for a complete list of Ids and definitions.
  --p-pretty-print: float # Optional flag to request GeoJSON formatted results to be pretty printed. Only provide a numeric value when the output needs to be human readable as pretty printing has a performance cost.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/cwa_rest_services.get_geojson"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: qid, var: qid}, {name: callback, var: callback}, {name: newsort, var: newsort}, {name: descending, var: descending}, {name: qcolumns, var: qcolumns}, {name: p_pretty_print, var: p_pretty_print}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, qid: $qid, callback: $callback, newsort: $newsort, descending: $descending, qcolumns: $qcolumns, p_pretty_print: $p_pretty_print
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Clean Water Act (CWA) Info Clusters Service
#
# GET /cwa_rest_services.get_info_clusters
# Returns: binary
export def "get-cwa-rest-services-get-info-clusters" [
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
  --output: string # Output Format Flag. Enter one of the following keywords: - CSV = Facility results formatted as comma delimited file download (default). - GEOJSOND = Facility results formatted as GeoJSON feature collection download.
  --p-qid: string # Query ID Selector. Enter the QueryID number from a previously run query. (required)
  --p-pretty-print: float # Optional flag to request GeoJSON formatted results to be pretty printed. Only provide a numeric value when the output needs to be human readable as pretty printing has a performance cost.
]: nothing -> any {
  http-request {
    method: get
    path: "/cwa_rest_services.get_info_clusters"
    query: [{name: output, var: output}, {name: p_qid, var: p_qid, required: true}, {name: p_pretty_print, var: p_pretty_print}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_qid: $p_qid, p_pretty_print: $p_pretty_print
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Clean Water Act (CWA) Info Clusters Service
#
# POST /cwa_rest_services.get_info_clusters
# Returns: binary
export def "post-cwa-rest-services-get-info-clusters" [
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
  --output: string # Output Format Flag. Enter one of the following keywords: - CSV = Facility results formatted as comma delimited file download (default). - GEOJSOND = Facility results formatted as GeoJSON feature collection download.
  p_qid: string # Query ID Selector. Enter the QueryID number from a previously run query.
  --p-pretty-print: float # Optional flag to request GeoJSON formatted results to be pretty printed. Only provide a numeric value when the output needs to be human readable as pretty printing has a performance cost.
]: any -> any {
  $in | http-request {
    method: post
    path: "/cwa_rest_services.get_info_clusters"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: p_qid, var: p_qid}, {name: p_pretty_print, var: p_pretty_print}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_qid: $p_qid, p_pretty_print: $p_pretty_print
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Clean Water Act (CWA) Map Service
#
# GET /cwa_rest_services.get_map
# Returns: record<MapOutput: record<IconBaseURL: string, MapData: list<record>, PopUpBaseURL: string, QueryID: string>>
export def "get-cwa-rest-services-get-map" [
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
  --p-id: string # Nine-character code used to uniquely identify a permitted NPDES facility. The NPDES permit program regulates the direct discharge of pollutants into US waters. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/cwa_rest_services.get_map"
    query: [{name: output, var: output}, {name: qid, var: qid, required: true}, {name: callback, var: callback}, {name: tablelist, var: tablelist}, {name: c1_lat, var: c1_lat}, {name: c1_long, var: c1_long}, {name: c2_lat, var: c2_lat}, {name: c2_long, var: c2_long}, {name: p_id, var: p_id, required: true}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, qid: $qid, callback: $callback, tablelist: $tablelist, c1_lat: $c1_lat, c1_long: $c1_long, c2_lat: $c2_lat, c2_long: $c2_long, p_id: $p_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Clean Water Act (CWA) Map Service
#
# POST /cwa_rest_services.get_map
# Returns: record<MapOutput: record<IconBaseURL: string, MapData: list<record>, PopUpBaseURL: string, QueryID: string>>
export def "post-cwa-rest-services-get-map" [
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
  p_id: string # Nine-character code used to uniquely identify a permitted NPDES facility. The NPDES permit program regulates the direct discharge of pollutants into US waters.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/cwa_rest_services.get_map"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: qid, var: qid}, {name: callback, var: callback}, {name: tablelist, var: tablelist}, {name: c1_lat, var: c1_lat}, {name: c1_long, var: c1_long}, {name: c2_lat, var: c2_lat}, {name: c2_long, var: c2_long}, {name: p_id, var: p_id}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, qid: $qid, callback: $callback, tablelist: $tablelist, c1_lat: $c1_lat, c1_long: $c1_long, c2_lat: $c2_lat, c2_long: $c2_long, p_id: $p_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Clean Water Act (CWA) Paginated Results Service
#
# GET /cwa_rest_services.get_qid
# Returns: record<Results: record<Facilities: list<record>, Message: string, PageNo: string, QueryID: string, QueryRows: string>>
export def "get-cwa-rest-services-get-qid" [
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
    path: "/cwa_rest_services.get_qid"
    query: [{name: output, var: output}, {name: qid, var: qid, required: true}, {name: pageno, var: pageno}, {name: callback, var: callback}, {name: newsort, var: newsort}, {name: descending, var: descending}, {name: qcolumns, var: qcolumns}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, qid: $qid, pageno: $pageno, callback: $callback, newsort: $newsort, descending: $descending, qcolumns: $qcolumns
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Clean Water Act (CWA) Paginated Results Service
#
# POST /cwa_rest_services.get_qid
# Returns: record<Results: record<Facilities: list<record>, Message: string, PageNo: string, QueryID: string, QueryRows: string>>
export def "post-cwa-rest-services-get-qid" [
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
    path: "/cwa_rest_services.get_qid"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: qid, var: qid}, {name: pageno, var: pageno}, {name: callback, var: callback}, {name: newsort, var: newsort}, {name: descending, var: descending}, {name: qcolumns, var: qcolumns}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, qid: $qid, pageno: $pageno, callback: $callback, newsort: $newsort, descending: $descending, qcolumns: $qcolumns
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Clean Water Act (CWA) Metadata Service
#
# GET /cwa_rest_services.metadata
# Returns: record<Results: record<Message: string, ResultColumns: list<record>>>
export def "get-cwa-rest-services-metadata" [
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
    path: "/cwa_rest_services.metadata"
    query: [{name: output, var: output}, {name: callback, var: callback}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Clean Water Act (CWA) Metadata Service
#
# POST /cwa_rest_services.metadata
# Returns: record<Results: record<Message: string, ResultColumns: list<record>>>
export def "post-cwa-rest-services-metadata" [
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
    path: "/cwa_rest_services.metadata"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: callback, var: callback}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# ECHO BP Tribes Lookup Service
#
# GET /rest_lookups.bp_tribes
# Returns: record<Results: record<LuValues: list<record>, Message: string>>
export def "get-rest-lookups-bp-tribes" [
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
  --search-term: string # Enter a partial or complete search phrase or word.
  --search-code: string # Enter a partial or complete code value.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rest_lookups.bp_tribes"
    query: [{name: output, var: output}, {name: callback, var: callback}, {name: search_term, var: search_term}, {name: search_code, var: search_code}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, callback: $callback, search_term: $search_term, search_code: $search_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# ECHO BP Tribes Lookup Service
#
# POST /rest_lookups.bp_tribes
# Returns: record<Results: record<LuValues: list<record>, Message: string>>
export def "post-rest-lookups-bp-tribes" [
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
  --search-term: string # Enter a partial or complete search phrase or word.
  --search-code: string # Enter a partial or complete code value.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/rest_lookups.bp_tribes"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: callback, var: callback}, {name: search_term, var: search_term}, {name: search_code, var: search_code}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, callback: $callback, search_term: $search_term, search_code: $search_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# ECHO CWA Parameter Lookup Service
#
# GET /rest_lookups.cwa_parameters
# Returns: record<Results: record<LuValues: list<record>, Message: string>>
export def "get-rest-lookups-cwa-parameters" [
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
  --search-term: string # Enter a partial or complete search phrase or word.
  --search-code: string # Enter a partial or complete code value.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rest_lookups.cwa_parameters"
    query: [{name: output, var: output}, {name: callback, var: callback}, {name: search_term, var: search_term}, {name: search_code, var: search_code}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, callback: $callback, search_term: $search_term, search_code: $search_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# ECHO CWA Parameter Lookup Service
#
# POST /rest_lookups.cwa_parameters
# Returns: record<Results: record<LuValues: list<record>, Message: string>>
export def "post-rest-lookups-cwa-parameters" [
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
  --search-term: string # Enter a partial or complete search phrase or word.
  --search-code: string # Enter a partial or complete code value.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/rest_lookups.cwa_parameters"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: callback, var: callback}, {name: search_term, var: search_term}, {name: search_code, var: search_code}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, callback: $callback, search_term: $search_term, search_code: $search_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# ECHO CWA Pollutants Lookup Service
#
# GET /rest_lookups.cwa_pollutants
# Returns: record<Results: record<LuValues: list<record>, Message: string>>
export def "get-rest-lookups-cwa-pollutants" [
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
  --search-term: string # Enter a partial or complete search phrase or word.
  --search-code: string # Enter a partial or complete code value.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rest_lookups.cwa_pollutants"
    query: [{name: output, var: output}, {name: callback, var: callback}, {name: search_term, var: search_term}, {name: search_code, var: search_code}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, callback: $callback, search_term: $search_term, search_code: $search_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# ECHO CWA Pollutants Lookup Service
#
# POST /rest_lookups.cwa_pollutants
# Returns: record<Results: record<LuValues: list<record>, Message: string>>
export def "post-rest-lookups-cwa-pollutants" [
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
  --search-term: string # Enter a partial or complete search phrase or word.
  --search-code: string # Enter a partial or complete code value.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/rest_lookups.cwa_pollutants"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: callback, var: callback}, {name: search_term, var: search_term}, {name: search_code, var: search_code}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, callback: $callback, search_term: $search_term, search_code: $search_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# ECHO Federal Agency Lookup Service
#
# GET /rest_lookups.federal_agencies
# Returns: record<Results: record<LuValues: list<record>, Message: string>>
export def "get-rest-lookups-federal-agencies" [
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
  --search-term: string # Enter a partial or complete search phrase or word.
  --search-code: string # Enter a partial or complete code value.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rest_lookups.federal_agencies"
    query: [{name: output, var: output}, {name: callback, var: callback}, {name: search_term, var: search_term}, {name: search_code, var: search_code}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, callback: $callback, search_term: $search_term, search_code: $search_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# ECHO Federal Agency Lookup Service
#
# POST /rest_lookups.federal_agencies
# Returns: record<Results: record<LuValues: list<record>, Message: string>>
export def "post-rest-lookups-federal-agencies" [
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
  --search-term: string # Enter a partial or complete search phrase or word.
  --search-code: string # Enter a partial or complete code value.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/rest_lookups.federal_agencies"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: callback, var: callback}, {name: search_term, var: search_term}, {name: search_code, var: search_code}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, callback: $callback, search_term: $search_term, search_code: $search_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# ECHO ICIS NPDES Inspection Types Lookup Service
#
# GET /rest_lookups.icis_inspection_types
# Returns: record<Results: record<LuValues: list<record>, Message: string>>
export def "get-rest-lookups-icis-inspection-types" [
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
  --search-term: string # Enter a partial or complete search phrase or word.
  --search-code: string # Enter a partial or complete code value.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rest_lookups.icis_inspection_types"
    query: [{name: output, var: output}, {name: callback, var: callback}, {name: search_term, var: search_term}, {name: search_code, var: search_code}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, callback: $callback, search_term: $search_term, search_code: $search_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# ECHO ICIS NPDES Inspection Types Lookup Service
#
# POST /rest_lookups.icis_inspection_types
# Returns: record<Results: record<LuValues: list<record>, Message: string>>
export def "post-rest-lookups-icis-inspection-types" [
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
  --search-term: string # Enter a partial or complete search phrase or word.
  --search-code: string # Enter a partial or complete code value.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/rest_lookups.icis_inspection_types"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: callback, var: callback}, {name: search_term, var: search_term}, {name: search_code, var: search_code}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, callback: $callback, search_term: $search_term, search_code: $search_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# ECHO ICIS NPDES Law Sections Lookup Service
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

# ECHO ICIS NPDES Law Sections Lookup Service
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

# ECHO NAICS Codes Lookup Service
#
# GET /rest_lookups.naics_codes
# Returns: record<Results: record<LuValues: list<record>, Message: string>>
export def "get-rest-lookups-naics-codes" [
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
  --search-term: string # Enter a partial or complete search phrase or word.
  --search-code: string # Enter a partial or complete code value.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rest_lookups.naics_codes"
    query: [{name: output, var: output}, {name: callback, var: callback}, {name: search_term, var: search_term}, {name: search_code, var: search_code}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, callback: $callback, search_term: $search_term, search_code: $search_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# ECHO NAICS Codes Lookup Service
#
# POST /rest_lookups.naics_codes
# Returns: record<Results: record<LuValues: list<record>, Message: string>>
export def "post-rest-lookups-naics-codes" [
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
  --search-term: string # Enter a partial or complete search phrase or word.
  --search-code: string # Enter a partial or complete code value.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/rest_lookups.naics_codes"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: callback, var: callback}, {name: search_term, var: search_term}, {name: search_code, var: search_code}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, callback: $callback, search_term: $search_term, search_code: $search_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# ECHO NPDES Parameters Lookup Service
#
# GET /rest_lookups.npdes_parameters
# Returns: record<Results: record<LuValues: list<record>, Message: string>>
export def "get-rest-lookups-npdes-parameters" [
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
  --search-term: string # Enter a partial or complete search phrase or word.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rest_lookups.npdes_parameters"
    query: [{name: output, var: output}, {name: callback, var: callback}, {name: search_term, var: search_term}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, callback: $callback, search_term: $search_term
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# ECHO NPDES Parameters Lookup Service
#
# POST /rest_lookups.npdes_parameters
# Returns: record<Results: record<LuValues: list<record>, Message: string>>
export def "post-rest-lookups-npdes-parameters" [
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
  --search-term: string # Enter a partial or complete search phrase or word.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/rest_lookups.npdes_parameters"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: callback, var: callback}, {name: search_term, var: search_term}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, callback: $callback, search_term: $search_term
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# ECHO WBD Code Lookup Service
#
# GET /rest_lookups.wbd_code_lu
# Returns: record<Results: record<LuValues: list<record>, Message: string>>
export def "get-rest-lookups-wbd-code-lu" [
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
  --wbd-code: string # Two-digit watershed code [Hydrologic Unit Code (HUC)].
  --wbd-level: string # The number of digits of the watershed code [Hydrologic Unit Code (HUC)] returned in the ValueCode. Must be an even number between 4 and 12.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rest_lookups.wbd_code_lu"
    query: [{name: output, var: output}, {name: callback, var: callback}, {name: wbd_code, var: wbd_code}, {name: wbd_level, var: wbd_level}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, callback: $callback, wbd_code: $wbd_code, wbd_level: $wbd_level
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# ECHO WBD Code Lookup Service
#
# POST /rest_lookups.wbd_code_lu
# Returns: record<Results: record<LuValues: list<record>, Message: string>>
export def "post-rest-lookups-wbd-code-lu" [
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
  --wbd-code: string # Two-digit watershed code [Hydrologic Unit Code (HUC)].
  --wbd-level: string # The number of digits of the watershed code [Hydrologic Unit Code (HUC)] returned in the ValueCode. Must be an even number between 4 and 12.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/rest_lookups.wbd_code_lu"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: callback, var: callback}, {name: wbd_code, var: wbd_code}, {name: wbd_level, var: wbd_level}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, callback: $callback, wbd_code: $wbd_code, wbd_level: $wbd_level
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# ECHO WBD Name Lookup Service
#
# GET /rest_lookups.wbd_name_lu
# Returns: record<Results: record<LuValues: list<record>, Message: string>>
export def "get-rest-lookups-wbd-name-lu" [
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
  --wbd-name: string # Watershed Name Filter. (required)
  --wbd-level: string # The number of digits of the watershed code [Hydrologic Unit Code (HUC)] returned in the ValueCode. Must be an even number between 4 and 12.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rest_lookups.wbd_name_lu"
    query: [{name: output, var: output}, {name: callback, var: callback}, {name: wbd_name, var: wbd_name, required: true}, {name: wbd_level, var: wbd_level}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, callback: $callback, wbd_name: $wbd_name, wbd_level: $wbd_level
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# ECHO WBD Name Lookup Service
#
# POST /rest_lookups.wbd_name_lu
# Returns: record<Results: record<LuValues: list<record>, Message: string>>
export def "post-rest-lookups-wbd-name-lu" [
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
  wbd_name: string # Watershed Name Filter.
  --wbd-level: string # The number of digits of the watershed code [Hydrologic Unit Code (HUC)] returned in the ValueCode. Must be an even number between 4 and 12.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/rest_lookups.wbd_name_lu"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: callback, var: callback}, {name: wbd_name, var: wbd_name}, {name: wbd_level, var: wbd_level}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, callback: $callback, wbd_name: $wbd_name, wbd_level: $wbd_level
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}
