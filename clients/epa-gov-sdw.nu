# Auto-generated client for U.S. EPA Enforcement and Compliance History Online (ECHO) - Safe Drinking Water Act v2019.10.15
# Source: https://api.apis.guru/v2/specs/epa.gov/sdw/2019.10.15/swagger.json
# Auth: --token flag or $env.U_S_EPA_ENFORCEMENT_AND_COMPLIANCE_HISTORY_ONLINE_ECHO_SAFE_DRINKING_WATER_ACT_TOKEN

const CLIENT = {
  base_url: "https://echodata.epa.gov/echo"
  token_env_var: "U_S_EPA_ENFORCEMENT_AND_COMPLIANCE_HISTORY_ONLINE_ECHO_SAFE_DRINKING_WATER_ACT_TOKEN"
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
def descending-completer [] { ["N" "Y"] }
def p-reg-completer [] { ["01" "02" "03" "04" "05" "06" "07" "08" "09" "10"] }
def p-act-completer [] { ["A" "N" "Y"] }
def p-qiv-completer [] { ["0" "12" "GT1" "GT2" "GT4" "GT8"] }
def p-ico-completer [] { ["N" "Y"] }
def p-owop-completer [] { ["F" "L" "M" "N" "P" "S"] }
def p-systyp-completer [] { ["CWS" "NCWS" "NTCWS" "TNCWS"] }
def p-swtyp-completer [] { ["GU" "GUP" "GW" "GWP" "SW" "SWP"] }
def p-mr-completer [] { ["N" "Y"] }
def p-health-completer [] { ["N" "Y"] }
def p-other-completer [] { ["N" "Y"] }
def p-pn-completer [] { ["N" "Y"] }
def p-sv-completer [] { ["N" "Y"] }
def p-pswvio-completer [] { ["N" "Y"] }
def p-fea-completer [] { ["N" "W"] }
def p-feay-completer [] { ["1" "2" "3" "4" "5"] }
def p-feaa-completer [] { ["A" "E" "S"] }
def p-iea-completer [] { ["N" "W"] }
def p-ieay-completer [] { ["1" "2" "3" "4" "5"] }
def p-ieaa-completer [] { ["E" "S"] }
def p-qis-completer [] { ["12" "GE1" "GE12" "GE2" "GE4" "GE8" "GT1" "GT12" "GT2" "GT4" "GT8" "Z"] }
def p-ysl-completer [] { ["N" "NV" "W"] }
def p-ysly-completer [] { ["1" "2" "3" "4" "5"] }
def p-ysla-completer [] { ["A" "E" "S"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-sdw-rest-services-get-download: "binary"
    post-sdw-rest-services-get-download: "binary"
    get-sdw-rest-services-get-qid: "record<Results: record<Message: string, PageNo: string, QueryID: string, QueryRows: string, WaterSystems: list<record>>>"
    post-sdw-rest-services-get-qid: "record<Results: record<Message: string, PageNo: string, QueryID: string, QueryRows: string, WaterSystems: list<record>>>"
    get-sdw-rest-services-get-systems: "record<Results: record<BadSystemIDs: string, CVRows: string, FEARows: string, INSPRows: string, IndianCountryRows: string, InfFEARows: string, Message: string, PageNo: string, QueryID: string, QueryRows: string, SVRows: string, V3Rows: string, Version: string, WaterSystems: list<record>>>"
    post-sdw-rest-services-get-systems: "record<Results: record<BadSystemIDs: string, CVRows: string, FEARows: string, INSPRows: string, IndianCountryRows: string, InfFEARows: string, Message: string, PageNo: string, QueryID: string, QueryRows: string, SVRows: string, V3Rows: string, Version: string, WaterSystems: list<record>>>"
    get-sdw-rest-services-metadata: "record<Results: record<Message: string, ResultColumns: list<record>>>"
    post-sdw-rest-services-metadata: "record<Results: record<Message: string, ResultColumns: list<record>>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-sdw-rest-services-get-download" "post-sdw-rest-services-get-download" "get-sdw-rest-services-get-qid" "post-sdw-rest-services-get-qid" "get-sdw-rest-services-get-systems" "post-sdw-rest-services-get-systems" "get-sdw-rest-services-metadata" "post-sdw-rest-services-metadata" "commands"] | sort) } | get name | first)
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

# Safe Drinking Water Act (SDWA) Download Data Service
#
# GET /sdw_rest_services.get_download
# Returns: binary
export def "get-sdw-rest-services-get-download" [
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/sdw_rest_services.get_download"
    query: [{name: output, var: output}, {name: qid, var: qid, required: true}, {name: qcolumns, var: qcolumns}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, qid: $qid, qcolumns: $qcolumns
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Safe Drinking Water Act (SDWA) Download Data Service
#
# POST /sdw_rest_services.get_download
# Returns: binary
export def "post-sdw-rest-services-get-download" [
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/sdw_rest_services.get_download"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: qid, var: qid}, {name: qcolumns, var: qcolumns}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, qid: $qid, qcolumns: $qcolumns
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Safe Drinking Water Act (SDWA) Paginated Results Service
#
# GET /sdw_rest_services.get_qid
# Returns: record<Results: record<Message: string, PageNo: string, QueryID: string, QueryRows: string, WaterSystems: list<record>>>
export def "get-sdw-rest-services-get-qid" [
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/sdw_rest_services.get_qid"
    query: [{name: output, var: output}, {name: qid, var: qid, required: true}, {name: pageno, var: pageno}, {name: callback, var: callback}, {name: newsort, var: newsort}, {name: descending, var: descending}, {name: qcolumns, var: qcolumns}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, qid: $qid, pageno: $pageno, callback: $callback, newsort: $newsort, descending: $descending, qcolumns: $qcolumns
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Safe Drinking Water Act (SDWA) Paginated Results Service
#
# POST /sdw_rest_services.get_qid
# Returns: record<Results: record<Message: string, PageNo: string, QueryID: string, QueryRows: string, WaterSystems: list<record>>>
export def "post-sdw-rest-services-get-qid" [
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/sdw_rest_services.get_qid"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: qid, var: qid}, {name: pageno, var: pageno}, {name: callback, var: callback}, {name: newsort, var: newsort}, {name: descending, var: descending}, {name: qcolumns, var: qcolumns}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, qid: $qid, pageno: $pageno, callback: $callback, newsort: $newsort, descending: $descending, qcolumns: $qcolumns
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Safe Drinking Water Act (SDWA) Systems Search Service
#
# GET /sdw_rest_services.get_systems
# Returns: record<Results: record<BadSystemIDs: string, CVRows: string, FEARows: string, INSPRows: string, IndianCountryRows: string, InfFEARows: string, Message: string, PageNo: string, QueryID: string, QueryRows: string, SVRows: string, V3Rows: string, Version: string, WaterSystems: list<record>>>
export def "get-sdw-rest-services-get-systems" [
  --base-url(-b): string@base-url-completer # API base URL
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
  --p-ct: string # Facility City Filter. Enter a single case-insensitive city name to filter results.
  --p-co: string # Facility County Filter. Provide a single county name in combination with a state value provided via p_st.
  --p-fips: string # FIPS Code Filter. Enter a single 5-character Federal Information Processing Standards (FIPS) state + county value to restrict results. E.g. to limit results to Kenosha County, Wisconsin, use 55059.
  --p-st: string # Facility State and State-Equivalent Filter. Provide one or more USPS postal abbreviations for states and state-equivalents to filter results. Provide multiple values as a comma-delimited list.
  --p-zip: string # 5-Digit ZIP Code Filter. Provide one or more 5-digit postal zip codes to filter results. May contain multiple comma-separated values.
  --p-reg: string@p-reg-completer # EPA Region Filter. Provide a single value of 01 thru 10 to restrict results to a single EPA region.
  --p-trb: string # Tribe name
  --p-act: string@p-act-completer # Active Permits/Facilities Flag. Provide Y or N to filter results to facilities with active permits.
  --p-qiv: string@p-qiv-completer # Quarters in Noncompliance Limiter. Enter a coded value to limit results to facilities with given quarter of noncompliance. - Z = Zero quarters in noncompliance. - GEXX = Replacing XX with a numeric value, that number of quarterd or more in noncompliance. - GTXX = Replacing XX with a numeric value, more than that number of quarters in noncompliance.
  --p-ico: string@p-ico-completer # Indian Country Flag. Enter a "Y" or "N" to restrict searches to facilities inside or outside Indian Country.
  --p-pid: string # Nine-digit permit IDs. May contain up to 2000 comma-separated values.
  --p-owop: string@p-owop-completer # Owner/Operator code filter. Enter one of the following codes to filter results: - F = Federal Government - S = State Government - L = Local Government - M = Public/Private - N = Native American - P = Private
  --p-systyp: string@p-systyp-completer # Type of public water system: - CWS=Community water system - NCWS=Non-community water system - NTCWS=Non-transient non-community water system - TNCWS=Transient non-community water system
  --p-swtyp: string@p-swtyp-completer # Source Water Type: - SW = Surface water - GW= Ground water - GU = Ground water under direct influence of (UDI) surface water - SWP = Purchased Surface water - GWP = Purchased Ground water - GUP = Purchased Ground water UDI surface water
  --p-popsv: string # Estimated average daily population served by a system: - LE500 = 500 or less - IN501_3K = 501-3,300 - IN3K_10K = 3,301-10,000 - IN10K_100K = 10,001-100,000 - IN100K_1M = 100,001-1,000,000 - GT1M = More than 1,000,000 May contain multiple comma-separated values.
  --p-cntysv: string
  --p-cs: string # Current violations: - M = Monitoring and Reporting Violations - H = Health-based Violations - O = Other Violations - P = Public Notice Violations - S = Serious Violator - N = No Violations May contain multiple comma-separated values.
  --p-mr: string@p-mr-completer # Monitoring and Reporting Violations (failure to conduct regular monitoring of drinking water quality or submit monitoring results in a timely fashion).
  --p-health: string@p-health-completer # Violations of health-based drinking water standards (maximum contaminant levels, maximum residual disinfectant levels, or treatment technique rules).
  --p-other: string@p-other-completer # Other violations, such as failing to issue annual consumer confidence reports or maintain required records.
  --p-pn: string@p-pn-completer # Public Notice Violations (failure to immediately alert consumers of serious problem with drinking water).
  --p-sv: string@p-sv-completer # Serious Violator (unresolved serious, multiple, and/or continuing violations). A value of Y will return only SDWIS systems that are Serious Violators, while a value of N will only return SDWIS Systems that are not Serious Violators.
  --p-qs: string # Quick Search. Allows entry for city, state, and/or zip code.
  --p-sfs: string # Single Facility Search Filter. Provide a facility name or program system identifier to limit results. For the all data search, the FRS registry identifier is also searched.
  --p-pswpol: string # For CWA, pollutant names for surface water discharges. for Drinking Water, SDWIS Violation contaminant codes for unaddressed violations that have occurred in the last 3 years. May contain multiple comma-separated values.
  --p-pswvio: string@p-pswvio-completer # Used in conjuction with parameters p_pswpol and p_pswparam, indicates whether search should only include pollutants with violations.
  --p-pbale: string # Lead Action Level Exceedance. A "Y" value will select water systems with at least 1 Lead Action Level Exceedance.
  --p-cuale: string # Copper Action Level Exceedance. A "Y" value will select water systems with at least 1 Copper Action Level Exceedance.
  --p-rc350v: string # Rule code 350 violation. A "Y" value will select water systems with at least one rule code 350 violation.
  --p-pbv: string # Lead Violations. A "Y" value will select water systems with at least 1 Lead Violation.
  --p-cuv: string # Copper Violation. A "Y" value will select water systems with at least 1 Copper Violation.
  --p-lcrv: string # Lead or Copper rule violations. A "Y" value will select water systems with at least 1 Lead or Copper Rule Violation.
  --p-fea: string@p-fea-completer # Formal Enforcement Actions [within / not within] specified date range indicator. The date range is determined by parameters p_fead1 and p_fead2 or by parameter p_feay. - W = within date range - N = not within date range
  --p-feay: float@p-feay-completer # Years (1 to 5) Range. This value is used to create a date range for Formal Enforcement Actions (FEA). Used along with p_fea (which indicates whether to look within or outside of the date range) to find FEAs within (or not within) the number of years specified.
  --p-feaa: string@p-feaa-completer # Agency associated with Formal Enforcement Actions: - E = EPA - S = State - A = All
  --p-iea: string@p-iea-completer # Informal Enforcement Actions [within / not within] specified date range. The date range is determined by parameters p_iead1 and p_iead2 or by parameter p_ieay. - W = within date range - N = not within date range
  --p-ieay: float@p-ieay-completer # Years (1 to 5) Range. This value is used to create a date range for Informal Enforcement Actions (IEA). Used along with p_iea (which indicates whether to look within or outside of the date range) to find IEAs within (or not within) the number of years specified.
  --p-ieaa: string@p-ieaa-completer # Agency associated with Informal Enforcement Actions. If left blank, both agencies are included. - E = EPA - S = State
  --p-qis: string@p-qis-completer # Significant Quarters in Noncompliance Limiter. Enter one of the following codes to limit results to facilities having given quarters of noncompliance. - Z = Zero quarters in noncompliance. - GE1 = One or more quarters in noncompliance. - GT1 = More than one quarters in noncompliance. - GE2 = Two or more quarters in noncompliance. - GT2 = More than two quarters in noncompliance. - GE4 = Four or more quarters in noncompliance. - GT4 = More than four quarters in noncompliance. - GE8 = Eight or more quarters in noncompliance. - GT8 = More than eight quarters in noncompliance. - GE12 = Twelve or more quarters in noncompliance. - GT12 = Twelve or more quarters in noncompliance. - 12 = Exactly twelve quarters in noncompliance. Note the seemingly incongruous of GT12 is deliberate.
  --p-pfead1: string # Formal Enforcement Action Date Range Start. Enter a date in MM/DD/YYYY format to set the start of the range for filtering by recent Formal Enforcement Action (FEA) taken against the facility within the last five years.
  --p-pfead2: string # Formal Enforcement Action Date Range End. Enter a date in MM/DD/YYYY format to set the end of the date range for filtering by recent Formal Enforcement Action (FEA) taken against the facility within the last five years.
  --p-pfeat: string # Formal Enforcement Action (FEA) Code Filter. Enter one or more three-letter FEA codes to restrict results to facilities with these attributes. Use p_fead1 and p_fead2 parameters to further restrict this filter by entering a date range. Provide multiple codes as a comma-delimited list.
  --p-ss5yr: string # Sanitary Surveys (in past 5 years) flag. Values of visit_reason_code are either "SNSV" or "SNSP" in the past 5 years indicate a Sanitary Survey. Enter "Y" to select facilities with Sanitary Surveys within the past 5 years. Enter "N" to select facilities without Sanitary Surveys in the past 5 years. Enter a number to search for greater for facilities with a quantity than or equal to that value.
  --p-sdc: string # Significant Deficiency Count (in past 5 years) flag. Enter "Y" to select facilities with Sanitary Surveys within the past 5 years. Enter "N" to select facilities without Sanitary Surveys in the past 5 years. Enter a number to search for facilities with a quantity greater than or equal to that value.
  --p-sdc-ils: string
  --p-ysl: string@p-ysl-completer # Last Facility Inspection [within / not within] Specified Date Range Indicator. The date range is determined by parameters p_idt1 and p_idt2 or by parameter p_ysly. - W = within date range - N = not within date range
  --p-ysly: string@p-ysly-completer # Number of years (1 to 5) since last facility inspection. A value of 1 means that it has been inspected within the year.
  --p-ysla: string@p-ysla-completer # Facility Last Inspection Code Filter. If left blank, both agencies are included. Enter a value to limit results: - E = EPA - S = State
  --p-idt1: string # Beginning of date range of most recent facility inspection.
  --p-idt2: string # End of date range of most recent facility inspection.
  --p-cms-flag: string
  --queryset: float # Query Limiter. Enter a value to limit the number of records returned for each query. Value cannot exceed 70,000.
  --responseset: float # Response Set Limiter. Enter a value to limit the number of records per page. Value cannot exceed 1,000.
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
  --qcolumns: string # Used to customize service output. A list of comma-separated column IDs of output objects that will be returned in the service query object or download. Use the metadata service endpoint for a complete list of Ids and definitions.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/sdw_rest_services.get_systems"
    query: [{name: output, var: output}, {name: p_fn, var: p_fn}, {name: p_ct, var: p_ct}, {name: p_co, var: p_co}, {name: p_fips, var: p_fips}, {name: p_st, var: p_st}, {name: p_zip, var: p_zip}, {name: p_reg, var: p_reg}, {name: p_trb, var: p_trb}, {name: p_act, var: p_act}, {name: p_qiv, var: p_qiv}, {name: p_ico, var: p_ico}, {name: p_pid, var: p_pid}, {name: p_owop, var: p_owop}, {name: p_systyp, var: p_systyp}, {name: p_swtyp, var: p_swtyp}, {name: p_popsv, var: p_popsv}, {name: p_cntysv, var: p_cntysv}, {name: p_cs, var: p_cs}, {name: p_mr, var: p_mr}, {name: p_health, var: p_health}, {name: p_other, var: p_other}, {name: p_pn, var: p_pn}, {name: p_sv, var: p_sv}, {name: p_qs, var: p_qs}, {name: p_sfs, var: p_sfs}, {name: p_pswpol, var: p_pswpol}, {name: p_pswvio, var: p_pswvio}, {name: p_pbale, var: p_pbale}, {name: p_cuale, var: p_cuale}, {name: p_rc350v, var: p_rc350v}, {name: p_pbv, var: p_pbv}, {name: p_cuv, var: p_cuv}, {name: p_lcrv, var: p_lcrv}, {name: p_fea, var: p_fea}, {name: p_feay, var: p_feay}, {name: p_feaa, var: p_feaa}, {name: p_iea, var: p_iea}, {name: p_ieay, var: p_ieay}, {name: p_ieaa, var: p_ieaa}, {name: p_qis, var: p_qis}, {name: p_pfead1, var: p_pfead1}, {name: p_pfead2, var: p_pfead2}, {name: p_pfeat, var: p_pfeat}, {name: p_ss5yr, var: p_ss5yr}, {name: p_sdc, var: p_sdc}, {name: p_sdc_ils, var: p_sdc_ils}, {name: p_ysl, var: p_ysl}, {name: p_ysly, var: p_ysly}, {name: p_ysla, var: p_ysla}, {name: p_idt1, var: p_idt1}, {name: p_idt2, var: p_idt2}, {name: p_cms_flag, var: p_cms_flag}, {name: queryset, var: queryset}, {name: responseset, var: responseset}, {name: callback, var: callback}, {name: qcolumns, var: qcolumns}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_fn: $p_fn, p_ct: $p_ct, p_co: $p_co, p_fips: $p_fips, p_st: $p_st, p_zip: $p_zip, p_reg: $p_reg, p_trb: $p_trb, p_act: $p_act, p_qiv: $p_qiv, p_ico: $p_ico, p_pid: $p_pid, p_owop: $p_owop, p_systyp: $p_systyp, p_swtyp: $p_swtyp, p_popsv: $p_popsv, p_cntysv: $p_cntysv, p_cs: $p_cs, p_mr: $p_mr, p_health: $p_health, p_other: $p_other, p_pn: $p_pn, p_sv: $p_sv, p_qs: $p_qs, p_sfs: $p_sfs, p_pswpol: $p_pswpol, p_pswvio: $p_pswvio, p_pbale: $p_pbale, p_cuale: $p_cuale, p_rc350v: $p_rc350v, p_pbv: $p_pbv, p_cuv: $p_cuv, p_lcrv: $p_lcrv, p_fea: $p_fea, p_feay: $p_feay, p_feaa: $p_feaa, p_iea: $p_iea, p_ieay: $p_ieay, p_ieaa: $p_ieaa, p_qis: $p_qis, p_pfead1: $p_pfead1, p_pfead2: $p_pfead2, p_pfeat: $p_pfeat, p_ss5yr: $p_ss5yr, p_sdc: $p_sdc, p_sdc_ils: $p_sdc_ils, p_ysl: $p_ysl, p_ysly: $p_ysly, p_ysla: $p_ysla, p_idt1: $p_idt1, p_idt2: $p_idt2, p_cms_flag: $p_cms_flag, queryset: $queryset, responseset: $responseset, callback: $callback, qcolumns: $qcolumns
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Safe Drinking Water Act (SDWA) Systems Search Service
#
# POST /sdw_rest_services.get_systems
# Returns: record<Results: record<BadSystemIDs: string, CVRows: string, FEARows: string, INSPRows: string, IndianCountryRows: string, InfFEARows: string, Message: string, PageNo: string, QueryID: string, QueryRows: string, SVRows: string, V3Rows: string, Version: string, WaterSystems: list<record>>>
export def "post-sdw-rest-services-get-systems" [
  --base-url(-b): string@base-url-completer # API base URL
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
  --p-ct: string # Facility City Filter. Enter a single case-insensitive city name to filter results.
  --p-co: string # Facility County Filter. Provide a single county name in combination with a state value provided via p_st.
  --p-fips: string # FIPS Code Filter. Enter a single 5-character Federal Information Processing Standards (FIPS) state + county value to restrict results. E.g. to limit results to Kenosha County, Wisconsin, use 55059.
  --p-st: string # Facility State and State-Equivalent Filter. Provide one or more USPS postal abbreviations for states and state-equivalents to filter results. Provide multiple values as a comma-delimited list.
  --p-zip: string # 5-Digit ZIP Code Filter. Provide one or more 5-digit postal zip codes to filter results. May contain multiple comma-separated values.
  --p-reg: string@p-reg-completer # EPA Region Filter. Provide a single value of 01 thru 10 to restrict results to a single EPA region.
  --p-trb: string # Tribe name
  --p-act: string@p-act-completer # Active Permits/Facilities Flag. Provide Y or N to filter results to facilities with active permits.
  --p-qiv: string@p-qiv-completer # Quarters in Noncompliance Limiter. Enter a coded value to limit results to facilities with given quarter of noncompliance. - Z = Zero quarters in noncompliance. - GEXX = Replacing XX with a numeric value, that number of quarterd or more in noncompliance. - GTXX = Replacing XX with a numeric value, more than that number of quarters in noncompliance.
  --p-ico: string@p-ico-completer # Indian Country Flag. Enter a "Y" or "N" to restrict searches to facilities inside or outside Indian Country.
  --p-pid: string # Nine-digit permit IDs. May contain up to 2000 comma-separated values.
  --p-owop: string@p-owop-completer # Owner/Operator code filter. Enter one of the following codes to filter results: - F = Federal Government - S = State Government - L = Local Government - M = Public/Private - N = Native American - P = Private
  --p-systyp: string@p-systyp-completer # Type of public water system: - CWS=Community water system - NCWS=Non-community water system - NTCWS=Non-transient non-community water system - TNCWS=Transient non-community water system
  --p-swtyp: string@p-swtyp-completer # Source Water Type: - SW = Surface water - GW= Ground water - GU = Ground water under direct influence of (UDI) surface water - SWP = Purchased Surface water - GWP = Purchased Ground water - GUP = Purchased Ground water UDI surface water
  --p-popsv: string # Estimated average daily population served by a system: - LE500 = 500 or less - IN501_3K = 501-3,300 - IN3K_10K = 3,301-10,000 - IN10K_100K = 10,001-100,000 - IN100K_1M = 100,001-1,000,000 - GT1M = More than 1,000,000 May contain multiple comma-separated values.
  --p-cntysv: string
  --p-cs: string # Current violations: - M = Monitoring and Reporting Violations - H = Health-based Violations - O = Other Violations - P = Public Notice Violations - S = Serious Violator - N = No Violations May contain multiple comma-separated values.
  --p-mr: string@p-mr-completer # Monitoring and Reporting Violations (failure to conduct regular monitoring of drinking water quality or submit monitoring results in a timely fashion).
  --p-health: string@p-health-completer # Violations of health-based drinking water standards (maximum contaminant levels, maximum residual disinfectant levels, or treatment technique rules).
  --p-other: string@p-other-completer # Other violations, such as failing to issue annual consumer confidence reports or maintain required records.
  --p-pn: string@p-pn-completer # Public Notice Violations (failure to immediately alert consumers of serious problem with drinking water).
  --p-sv: string@p-sv-completer # Serious Violator (unresolved serious, multiple, and/or continuing violations). A value of Y will return only SDWIS systems that are Serious Violators, while a value of N will only return SDWIS Systems that are not Serious Violators.
  --p-qs: string # Quick Search. Allows entry for city, state, and/or zip code.
  --p-sfs: string # Single Facility Search Filter. Provide a facility name or program system identifier to limit results. For the all data search, the FRS registry identifier is also searched.
  --p-pswpol: string # For CWA, pollutant names for surface water discharges. for Drinking Water, SDWIS Violation contaminant codes for unaddressed violations that have occurred in the last 3 years. May contain multiple comma-separated values.
  --p-pswvio: string@p-pswvio-completer # Used in conjuction with parameters p_pswpol and p_pswparam, indicates whether search should only include pollutants with violations.
  --p-pbale: string # Lead Action Level Exceedance. A "Y" value will select water systems with at least 1 Lead Action Level Exceedance.
  --p-cuale: string # Copper Action Level Exceedance. A "Y" value will select water systems with at least 1 Copper Action Level Exceedance.
  --p-rc350v: string # Rule code 350 violation. A "Y" value will select water systems with at least one rule code 350 violation.
  --p-pbv: string # Lead Violations. A "Y" value will select water systems with at least 1 Lead Violation.
  --p-cuv: string # Copper Violation. A "Y" value will select water systems with at least 1 Copper Violation.
  --p-lcrv: string # Lead or Copper rule violations. A "Y" value will select water systems with at least 1 Lead or Copper Rule Violation.
  --p-fea: string@p-fea-completer # Formal Enforcement Actions [within / not within] specified date range indicator. The date range is determined by parameters p_fead1 and p_fead2 or by parameter p_feay. - W = within date range - N = not within date range
  --p-feay: float@p-feay-completer # Years (1 to 5) Range. This value is used to create a date range for Formal Enforcement Actions (FEA). Used along with p_fea (which indicates whether to look within or outside of the date range) to find FEAs within (or not within) the number of years specified.
  --p-feaa: string@p-feaa-completer # Agency associated with Formal Enforcement Actions: - E = EPA - S = State - A = All
  --p-iea: string@p-iea-completer # Informal Enforcement Actions [within / not within] specified date range. The date range is determined by parameters p_iead1 and p_iead2 or by parameter p_ieay. - W = within date range - N = not within date range
  --p-ieay: float@p-ieay-completer # Years (1 to 5) Range. This value is used to create a date range for Informal Enforcement Actions (IEA). Used along with p_iea (which indicates whether to look within or outside of the date range) to find IEAs within (or not within) the number of years specified.
  --p-ieaa: string@p-ieaa-completer # Agency associated with Informal Enforcement Actions. If left blank, both agencies are included. - E = EPA - S = State
  --p-qis: string@p-qis-completer # Significant Quarters in Noncompliance Limiter. Enter one of the following codes to limit results to facilities having given quarters of noncompliance. - Z = Zero quarters in noncompliance. - GE1 = One or more quarters in noncompliance. - GT1 = More than one quarters in noncompliance. - GE2 = Two or more quarters in noncompliance. - GT2 = More than two quarters in noncompliance. - GE4 = Four or more quarters in noncompliance. - GT4 = More than four quarters in noncompliance. - GE8 = Eight or more quarters in noncompliance. - GT8 = More than eight quarters in noncompliance. - GE12 = Twelve or more quarters in noncompliance. - GT12 = Twelve or more quarters in noncompliance. - 12 = Exactly twelve quarters in noncompliance. Note the seemingly incongruous of GT12 is deliberate.
  --p-pfead1: string # Formal Enforcement Action Date Range Start. Enter a date in MM/DD/YYYY format to set the start of the range for filtering by recent Formal Enforcement Action (FEA) taken against the facility within the last five years.
  --p-pfead2: string # Formal Enforcement Action Date Range End. Enter a date in MM/DD/YYYY format to set the end of the date range for filtering by recent Formal Enforcement Action (FEA) taken against the facility within the last five years.
  --p-pfeat: string # Formal Enforcement Action (FEA) Code Filter. Enter one or more three-letter FEA codes to restrict results to facilities with these attributes. Use p_fead1 and p_fead2 parameters to further restrict this filter by entering a date range. Provide multiple codes as a comma-delimited list.
  --p-ss5yr: string # Sanitary Surveys (in past 5 years) flag. Values of visit_reason_code are either "SNSV" or "SNSP" in the past 5 years indicate a Sanitary Survey. Enter "Y" to select facilities with Sanitary Surveys within the past 5 years. Enter "N" to select facilities without Sanitary Surveys in the past 5 years. Enter a number to search for greater for facilities with a quantity than or equal to that value.
  --p-sdc: string # Significant Deficiency Count (in past 5 years) flag. Enter "Y" to select facilities with Sanitary Surveys within the past 5 years. Enter "N" to select facilities without Sanitary Surveys in the past 5 years. Enter a number to search for facilities with a quantity greater than or equal to that value.
  --p-sdc-ils: string
  --p-ysl: string@p-ysl-completer # Last Facility Inspection [within / not within] Specified Date Range Indicator. The date range is determined by parameters p_idt1 and p_idt2 or by parameter p_ysly. - W = within date range - N = not within date range
  --p-ysly: string@p-ysly-completer # Number of years (1 to 5) since last facility inspection. A value of 1 means that it has been inspected within the year.
  --p-ysla: string@p-ysla-completer # Facility Last Inspection Code Filter. If left blank, both agencies are included. Enter a value to limit results: - E = EPA - S = State
  --p-idt1: string # Beginning of date range of most recent facility inspection.
  --p-idt2: string # End of date range of most recent facility inspection.
  --p-cms-flag: string
  --queryset: float # Query Limiter. Enter a value to limit the number of records returned for each query. Value cannot exceed 70,000.
  --responseset: float # Response Set Limiter. Enter a value to limit the number of records per page. Value cannot exceed 1,000.
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
  --qcolumns: string # Used to customize service output. A list of comma-separated column IDs of output objects that will be returned in the service query object or download. Use the metadata service endpoint for a complete list of Ids and definitions.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sdw_rest_services.get_systems"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: p_fn, var: p_fn}, {name: p_ct, var: p_ct}, {name: p_co, var: p_co}, {name: p_fips, var: p_fips}, {name: p_st, var: p_st}, {name: p_zip, var: p_zip}, {name: p_reg, var: p_reg}, {name: p_trb, var: p_trb}, {name: p_act, var: p_act}, {name: p_qiv, var: p_qiv}, {name: p_ico, var: p_ico}, {name: p_pid, var: p_pid}, {name: p_owop, var: p_owop}, {name: p_systyp, var: p_systyp}, {name: p_swtyp, var: p_swtyp}, {name: p_popsv, var: p_popsv}, {name: p_cntysv, var: p_cntysv}, {name: p_cs, var: p_cs}, {name: p_mr, var: p_mr}, {name: p_health, var: p_health}, {name: p_other, var: p_other}, {name: p_pn, var: p_pn}, {name: p_sv, var: p_sv}, {name: p_qs, var: p_qs}, {name: p_sfs, var: p_sfs}, {name: p_pswpol, var: p_pswpol}, {name: p_pswvio, var: p_pswvio}, {name: p_pbale, var: p_pbale}, {name: p_cuale, var: p_cuale}, {name: p_rc350v, var: p_rc350v}, {name: p_pbv, var: p_pbv}, {name: p_cuv, var: p_cuv}, {name: p_lcrv, var: p_lcrv}, {name: p_fea, var: p_fea}, {name: p_feay, var: p_feay}, {name: p_feaa, var: p_feaa}, {name: p_iea, var: p_iea}, {name: p_ieay, var: p_ieay}, {name: p_ieaa, var: p_ieaa}, {name: p_qis, var: p_qis}, {name: p_pfead1, var: p_pfead1}, {name: p_pfead2, var: p_pfead2}, {name: p_pfeat, var: p_pfeat}, {name: p_ss5yr, var: p_ss5yr}, {name: p_sdc, var: p_sdc}, {name: p_sdc_ils, var: p_sdc_ils}, {name: p_ysl, var: p_ysl}, {name: p_ysly, var: p_ysly}, {name: p_ysla, var: p_ysla}, {name: p_idt1, var: p_idt1}, {name: p_idt2, var: p_idt2}, {name: p_cms_flag, var: p_cms_flag}, {name: queryset, var: queryset}, {name: responseset, var: responseset}, {name: callback, var: callback}, {name: qcolumns, var: qcolumns}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_fn: $p_fn, p_ct: $p_ct, p_co: $p_co, p_fips: $p_fips, p_st: $p_st, p_zip: $p_zip, p_reg: $p_reg, p_trb: $p_trb, p_act: $p_act, p_qiv: $p_qiv, p_ico: $p_ico, p_pid: $p_pid, p_owop: $p_owop, p_systyp: $p_systyp, p_swtyp: $p_swtyp, p_popsv: $p_popsv, p_cntysv: $p_cntysv, p_cs: $p_cs, p_mr: $p_mr, p_health: $p_health, p_other: $p_other, p_pn: $p_pn, p_sv: $p_sv, p_qs: $p_qs, p_sfs: $p_sfs, p_pswpol: $p_pswpol, p_pswvio: $p_pswvio, p_pbale: $p_pbale, p_cuale: $p_cuale, p_rc350v: $p_rc350v, p_pbv: $p_pbv, p_cuv: $p_cuv, p_lcrv: $p_lcrv, p_fea: $p_fea, p_feay: $p_feay, p_feaa: $p_feaa, p_iea: $p_iea, p_ieay: $p_ieay, p_ieaa: $p_ieaa, p_qis: $p_qis, p_pfead1: $p_pfead1, p_pfead2: $p_pfead2, p_pfeat: $p_pfeat, p_ss5yr: $p_ss5yr, p_sdc: $p_sdc, p_sdc_ils: $p_sdc_ils, p_ysl: $p_ysl, p_ysly: $p_ysly, p_ysla: $p_ysla, p_idt1: $p_idt1, p_idt2: $p_idt2, p_cms_flag: $p_cms_flag, queryset: $queryset, responseset: $responseset, callback: $callback, qcolumns: $qcolumns
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Safe Drinking Water Act (SDWA) Metadata Service
#
# GET /sdw_rest_services.metadata
# Returns: record<Results: record<Message: string, ResultColumns: list<record>>>
export def "get-sdw-rest-services-metadata" [
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/sdw_rest_services.metadata"
    query: [{name: output, var: output}, {name: callback, var: callback}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Safe Drinking Water Act (SDWA) Metadata Service
#
# POST /sdw_rest_services.metadata
# Returns: record<Results: record<Message: string, ResultColumns: list<record>>>
export def "post-sdw-rest-services-metadata" [
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/sdw_rest_services.metadata"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: callback, var: callback}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}
