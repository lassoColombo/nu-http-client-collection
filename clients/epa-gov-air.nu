# Auto-generated client for U.S. EPA Enforcement and Compliance History Online (ECHO) - Clean Air Act v2019.10.15
# Source: https://api.apis.guru/v2/specs/epa.gov/air/2019.10.15/swagger.json
# Auth: --token flag or $env.U_S_EPA_ENFORCEMENT_AND_COMPLIANCE_HISTORY_ONLINE_ECHO_CLEAN_AIR_ACT_TOKEN

const CLIENT = {
  base_url: "https://echodata.epa.gov/echo"
  token_env_var: "U_S_EPA_ENFORCEMENT_AND_COMPLIANCE_HISTORY_ONLINE_ECHO_CLEAN_AIR_ACT_TOKEN"
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
def p-act-completer [] { ["A" "N" "Y"] }
def p-maj-completer [] { ["N" "Y"] }
def p-fea-completer [] { ["N" "W"] }
def p-feay-completer [] { ["1" "2" "3" "4" "5"] }
def p-feaa-completer [] { ["A" "E" "S"] }
def p-iea-completer [] { ["N" "W"] }
def p-ieay-completer [] { ["1" "2" "3" "4" "5"] }
def p-ieaa-completer [] { ["E" "S"] }
def p-qiv-completer [] { ["0" "12" "GT1" "GT2" "GT4" "GT8"] }
def p-impw-completer [] { ["N" "Y"] }
def p-trep-completer [] { ["CURR" "NOTCURR"] }
def p-tri-cat-completer [] { ["CARC" "HAP" "TOTAL"] }
def p-tri-amt-completer [] { ["0" "GT0" "GT1000" "GT10000" "GT5000" "GT50000"] }
def p-ghg-cat-completer [] { ["ALL" "BIOCO2" "CH4" "CO2" "HFC" "N2O" "NF3" "OTHER_L" "PFC" "SF6"] }
def p-ghg-amt-completer [] { ["0" "GT0" "GT10000" "GT1000000" "GT25000" "GT250000" "None"] }
def p-nei-amt-completer [] { ["0" "GT0" "GT10000" "GT1000000" "GT25000" "GT250000" "None"] }
def p-pm-completer [] { ["GT10" "GT25" "GT5" "GT50" "GT75" "NONE"] }
def p-pd-completer [] { ["GT100" "GT1000" "GT10000" "GT20000" "GT500" "GT5000" "NONE"] }
def p-ico-completer [] { ["N" "Y"] }
def p-med-completer [] { ["ALL" "M" "R" "S" "W"] }
def p-ysl-completer [] { ["N" "NV" "W"] }
def p-ysly-completer [] { ["1" "2" "3" "4" "5"] }
def p-ysla-completer [] { ["A" "E" "S"] }
def p-stsl-completer [] { ["N" "W"] }
def p-stsly-completer [] { ["1" "2" "3" "4" "5"] }
def p-stsla-completer [] { ["A" "E" "S"] }
def p-agoo-completer [] { ["AND" "OR"] }
def p-cifdi-completer [] { ["Any" "No" "Undetermined" "Yes"] }
def p-psncq-completer [] { ["GE1" "GE12" "GE2" "GE4" "GE8" "GT1" "GT12" "GT2" "GT4" "GT8"] }
def p-pctrack-completer [] { ["Off" "On" "Partial"] }
def p-swpa-completer [] { ["ground water" "source water" "surface water" "waiting for SSO"] }
def p-fntype-completer [] { ["ALL" "BEGINS" "CONTAINS" "EXACT"] }
def p-pidall-completer [] { ["N" "Y"] }
def p-fac-ico-completer [] { ["N" "Y"] }
def p-limit-addr-completer [] { ["N" "Y"] }
def p-decouple-completer [] { ["N" "Y"] }
def p-ejscreen-over80cnt-completer [] { ["1" "10" "11" "2" "3" "4" "5" "6" "7" "8" "9"] }
def tablelist-completer [] { ["N" "Y"] }
def maplist-completer [] { ["N" "Y"] }
def summarylist-completer [] { ["N" "Y"] }
def descending-completer [] { ["N" "Y"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-air-rest-services-get-download: "binary"
    post-air-rest-services-get-download: "binary"
    get-air-rest-services-get-facilities: "record<Results: record<BadSystemIDs: string, CVRows: string, FEARows: string, Facilities: list<record>, INSPRows: string, IndianCountryRows: string, InfFEARows: string, MapOutput: record<IconBaseURL: string, MapData: list, PopUpBaseURL: string, QueryID: string>, Message: string, PageNo: string, QueryID: string, QueryRows: string, SVRows: string, TotalPenalties: string, V3Rows: string>>"
    post-air-rest-services-get-facilities: "record<Results: record<BadSystemIDs: string, CVRows: string, FEARows: string, Facilities: list<record>, INSPRows: string, IndianCountryRows: string, InfFEARows: string, MapOutput: record<IconBaseURL: string, MapData: list, PopUpBaseURL: string, QueryID: string>, Message: string, PageNo: string, QueryID: string, QueryRows: string, SVRows: string, TotalPenalties: string, V3Rows: string>>"
    get-air-rest-services-get-facility-info: "record<Results: record<BadSystemIDs: string, CVRows: string, ClusterOutput: record<ClusterData: list>, ClusterRecords: string, FEARows: string, Facilities: list<record>, INSPRows: string, IconBaseURL: string, IndianCountryRows: string, InfFEARows: string, Message: string, PopUpBaseURL: string, QueryID: string, QueryParameters: list<record>, QueryRows: string, SVRows: string, ServiceBaseURL: string, TotalPenalties: string, V3Rows: string>>"
    post-air-rest-services-get-facility-info: "record<Results: record<BadSystemIDs: string, CVRows: string, ClusterOutput: record<ClusterData: list>, ClusterRecords: string, FEARows: string, Facilities: list<record>, INSPRows: string, IconBaseURL: string, IndianCountryRows: string, InfFEARows: string, Message: string, PopUpBaseURL: string, QueryID: string, QueryParameters: list<record>, QueryRows: string, SVRows: string, ServiceBaseURL: string, TotalPenalties: string, V3Rows: string>>"
    get-air-rest-services-get-geojson: "record<features: table<geometry: record, properties: record, type: string>, type: string>"
    post-air-rest-services-get-geojson: "record<features: table<geometry: record, properties: record, type: string>, type: string>"
    get-air-rest-services-get-info-clusters: "binary"
    post-air-rest-services-get-info-clusters: "binary"
    get-air-rest-services-get-map: "record<MapOutput: record<IconBaseURL: string, MapData: list<record>, PopUpBaseURL: string, QueryID: string>>"
    post-air-rest-services-get-map: "record<MapOutput: record<IconBaseURL: string, MapData: list<record>, PopUpBaseURL: string, QueryID: string>>"
    get-air-rest-services-get-qid: "record<Results: record<Facilities: list<record>, Message: string, PageNo: string, QueryID: string, QueryRows: string>>"
    post-air-rest-services-get-qid: "record<Results: record<Facilities: list<record>, Message: string, PageNo: string, QueryID: string, QueryRows: string>>"
    get-air-rest-services-metadata: "record<Results: record<Message: string, ResultColumns: list<record>>>"
    post-air-rest-services-metadata: "record<Results: record<Message: string, ResultColumns: list<record>>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-air-rest-services-get-download" "post-air-rest-services-get-download" "get-air-rest-services-get-facilities" "post-air-rest-services-get-facilities" "get-air-rest-services-get-facility-info" "post-air-rest-services-get-facility-info" "get-air-rest-services-get-geojson" "post-air-rest-services-get-geojson" "get-air-rest-services-get-info-clusters" "post-air-rest-services-get-info-clusters" "get-air-rest-services-get-map" "post-air-rest-services-get-map" "get-air-rest-services-get-qid" "post-air-rest-services-get-qid" "get-air-rest-services-metadata" "post-air-rest-services-metadata" "commands"] | sort) } | get name | first)
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

# Clean Air Act Download Data Service
#
# GET /air_rest_services.get_download
# Returns: binary
export def "get-air-rest-services-get-download" [
  --base-url(-b): string@base-url-completer # API base URL
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
  --qid: string # Query ID Selector. Enter the QueryID number from a previously run query. (required)
  --qcolumns: string # Used to customize service output. A list of comma-separated column IDs of output objects that will be returned in the service query object or download. Use the metadata service endpoint for a complete list of Ids and definitions.
  --p-pretty-print: float # Optional flag to request GeoJSON formatted results to be pretty printed. Only provide a numeric value when the output needs to be human readable as pretty printing has a performance cost.
]: nothing -> any {
  http-request {
    method: get
    path: "/air_rest_services.get_download"
    query: [{name: output, var: output}, {name: qid, var: qid, required: true}, {name: qcolumns, var: qcolumns}, {name: p_pretty_print, var: p_pretty_print}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, qid: $qid, qcolumns: $qcolumns, p_pretty_print: $p_pretty_print
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Clean Air Act Download Data Service
#
# POST /air_rest_services.get_download
# Returns: binary
export def "post-air-rest-services-get-download" [
  --base-url(-b): string@base-url-completer # API base URL
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
  qid: string # Query ID Selector. Enter the QueryID number from a previously run query.
  --qcolumns: string # Used to customize service output. A list of comma-separated column IDs of output objects that will be returned in the service query object or download. Use the metadata service endpoint for a complete list of Ids and definitions.
  --p-pretty-print: float # Optional flag to request GeoJSON formatted results to be pretty printed. Only provide a numeric value when the output needs to be human readable as pretty printing has a performance cost.
]: any -> any {
  $in | http-request {
    method: post
    path: "/air_rest_services.get_download"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: qid, var: qid}, {name: qcolumns, var: qcolumns}, {name: p_pretty_print, var: p_pretty_print}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, qid: $qid, qcolumns: $qcolumns, p_pretty_print: $p_pretty_print
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Clean Air Act Facility Search
#
# GET /air_rest_services.get_facilities
# Returns: record<Results: record<BadSystemIDs: string, CVRows: string, FEARows: string, Facilities: list<record>, INSPRows: string, IndianCountryRows: string, InfFEARows: string, MapOutput: record<IconBaseURL: string, MapData: list, PopUpBaseURL: string, QueryID: string>, Message: string, PageNo: string, QueryID: string, QueryRows: string, SVRows: string, TotalPenalties: string, V3Rows: string>>
export def "get-air-rest-services-get-facilities" [
  --base-url(-b): string@base-url-completer # API base URL
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
  --p-lcon: string # Air Program Local Control Region Code Filter. Enter one or more local control region codes to filter results. Provide multiple codes as a comma-delimited list. Codes where they exist are specific by state.
  --p-frs: string # Facility Registry Service ID Filter. Enter a single 12-digit FRS identifier to filter results.
  --p-reg: string@p-reg-completer # EPA Region Filter. Provide a single value of 01 thru 10 to restrict results to a single EPA region.
  --p-sic: string # Standard Industrial Classification (SIC) Code Filter. Enter a single 4-digit SIC Code to filter results. If more complex filtering is required, use p_sic2 and p_sic4.
  --p-ncs: string # North American Industry Classification System Filter. Enter two to six digits to filter results to facilities having matching NAICS codes. Digits less than six will match to all codes beginning with the provided values.
  --p-qnc: float # Number of quarters in non-compliance limiter. Enter an integer value between 1 and 4 to limit results.
  --p-pen: string # Last Penality Date Qualifier Filter. Enter one of the following: - NEVER = No Penalties - ANY = Any Penalty - LEXX = Less than or equal to XX months. Provide a number in place of XX, e.g. "LE5" for a facility with a penalty within previous 5 months. - GTXX = Greater than XX months. Provide a number in place of XX, eg. GT12, for a facility with the last penalty greater than 12 months ago.
  --p-opst: string # Operating status filter. Enter one or more operating status codes to limit results. Provide multiple codes as a comma-delimited list.
  --p-c1lat: float # In decimal degrees. Latitude of 1st corner of box that bounds the resulting facilities. The latitude and longitude of both corners of the bounding box must be provided.
  --p-c1lon: float # In decimal degrees. Longitude of 1st corner of box that bounds the resulting facilities. The latitude and longitude of both corners of the bounding box must be provided.
  --p-c2lat: float # In decimal degrees. Latitude of 2nd corner of box that bounds the resulting facilities. The latitude and longitude of both corners of the bounding box must be provided.
  --p-c2lon: float # In decimal degrees. Longitude of 2nd corner of box that bounds the resulting facilities. The latitude and longitude of both corners of the bounding box must be provided.
  --p-usmex: string@p-usmex-completer # US-Mexico Border Flag. Enter Y/N to restrict searches to facilities located within 100KM of the border.
  --p-sic2: string # Standard Industrial Classification (SIC) Code Filter Alternate 2. Enter a wild-card search against SIC codes. A final wild-card is always present allowing "22" to match all SIC codes beginning with 22. Use the "%" character within strings to match any SIC values with the pattern. For example, "2%21" matches 2021, 2121, 2221, etc.
  --p-sic4: string # Standard Industrial Classification (SIC) Code Filter Alternate 3. Enter the first 2, 3 or 4 SIC code digits to filter results to facilities having those code prefixes. As this alternative does not utilize an index, p_sic2 will generally be quicker.
  --p-fa: string # Federal Agency. 1 character or 5-character values; may contain multiple comma-separated values. ALL will retrieve all facilities where the federal agency code is not null. Use the Federal Agencies lookup service to obtain a list of values.
  --p-act: string@p-act-completer # Active Permits/Facilities Flag. Provide Y or N to filter results to facilities with active permits.
  --p-maj: string@p-maj-completer # Major Facility Flag. Enter Y to restrict results to Major facilities only.
  --p-mact: string # CAA Maximum Achievable Control Technology (MACT) Subpart codes (alpha ID between 1 and 7 characters) applicable to the facility.
  --p-nsps: string # Air Programl New Source Performance Standards (NSPS) Subpart Code Search. One or more valid Air Program NSPS Program codes cand be passed.
  --p-nspsm: string # Air Programl New Source Performance Standards Minors (NSPSM) Subpart Code Search. One or more valid Air Program NSPSM Subpart codes can be passed.
  --p-prog: string # Air Program Code Filter. Enter one or more Air program codes to filter results. Provide multiple values as a comma-delimited list.
  --p-fea: string@p-fea-completer # Formal Enforcement Actions [within / not within] specified date range indicator. The date range is determined by parameters p_fead1 and p_fead2 or by parameter p_feay. - W = within date range - N = not within date range
  --p-feay: float@p-feay-completer # Years (1 to 5) Range. This value is used to create a date range for Formal Enforcement Actions (FEA). Used along with p_fea (which indicates whether to look within or outside of the date range) to find FEAs within (or not within) the number of years specified.
  --p-feaa: string@p-feaa-completer # Agency associated with Formal Enforcement Actions: - E = EPA - S = State - A = All
  --p-iea: string@p-iea-completer # Informal Enforcement Actions [within / not within] specified date range. The date range is determined by parameters p_iead1 and p_iead2 or by parameter p_ieay. - W = within date range - N = not within date range
  --p-ieay: float@p-ieay-completer # Years (1 to 5) Range. This value is used to create a date range for Informal Enforcement Actions (IEA). Used along with p_iea (which indicates whether to look within or outside of the date range) to find IEAs within (or not within) the number of years specified.
  --p-ieaa: string@p-ieaa-completer # Agency associated with Informal Enforcement Actions. If left blank, both agencies are included. - E = EPA - S = State
  --p-qiv: string@p-qiv-completer # Quarters in Noncompliance Limiter. Enter a coded value to limit results to facilities with given quarter of noncompliance. - Z = Zero quarters in noncompliance. - GEXX = Replacing XX with a numeric value, that number of quarterd or more in noncompliance. - GTXX = Replacing XX with a numeric value, more than that number of quarters in noncompliance.
  --p-naa: string # Non-Attainment Area Flag. Enter a Y or N to filter for or against facilities flagged as non-attainment areas.
  --p-impw: string@p-impw-completer # Discharging into Impaired Waters Flag. Enter Y to limit results to facilities with discharge to waterbodies listed as impaired in the ATTAINS database.
  --p-trep: string@p-trep-completer # Current Toxics Release Inventory (TRI) Reporter Limiter. Enter one of the following codes to limit results. - CURR = Current TRI reporter. - NONCURR = Has reported to TRI in the past but not for the current reporting year.
  --p-tri-cat: string@p-tri-cat-completer # Toxic Release Inventory Released To Air Chemical Identifier Category Filter. Enter the chemical identifier category code to limit results. Note when filtering by TRI chemical identifier categories one may not also filter by specific chemical identifiers via p_tri_pol. You must also specify a release amount using p_tri_amt or p_tri_any_amt. - TOTAL = Total Released to Air - CARC = Total Carcinogens Released to Air - HAP = Total Hazardous Air Pollutants Released to Air
  --p-tri-amt: string@p-tri-amt-completer # Toxic Release Inventory Release Amount Filter. Enter a value in pounds to limit results to facilities releasing this amount or greateer of TRI releases. Valid values are 0, GT0, GT1000, GT5000, GT10000 and GT50000. Note when filtering by TRI release amounts one may only use either p_tri_amt or p_tri_any_amt.
  --p-tri-any-amt: float # Toxic Release Inventory Release Of Any Kind Above Value Filter. Enter a value to limit results to facilities releasing this amount or more of TRI releases. Note when filtering by TRI releases one may only use p_tri_any_amt or p_tri_amt and not both.
  --p-tri-pol: string # Toxic Release Inventory Chemical Identifier Filter. Enter one or more chemical identifier codes to limit results. Note when filtering by specific TRI chemical identifiers one may not also filter by chemical identifier categories via p_tri_cat.
  --p-ghg-cat: string@p-ghg-cat-completer # Green House Gas (GHG) Gas Code Category. Must be used with either a formatted (p_ghg_amt) or custom (p_ghg_any_amt) release amount.
  --p-ghg-amt: string@p-ghg-amt-completer # Green House Gas (GHG) CO2 Equivalent Formatted Release Amount. First 2 characters must contain GT (greater than) followed by a number.
  --p-ghg-any-amt: float # Green House Gas (GHG) C02 Equivalent Custom Amount. The C02E value reported for the provided category, will be greater or equal to the amount provided.
  --p-ghg-yr: string # Green House Gas (GHG) Reporting Year. (2010 through 2015)
  --p-nei-pol: string # National Emissions Inventory (NEI) Pollutant Identifier. When a pollutant identifer is entered a corresponding formatted amount or custom amount must be entered.
  --p-nei-amt: string@p-nei-amt-completer # National Emissions Inventory (NEI) Formatted Pollutant Amount. A formatted value where the 1st two characters must start with GT or LT followed by a number. Identifies facilities that have a NEI Pollutant Emission where the supplied value is > or < the pollutant emission amount.
  --p-nei-any-amt: float # National Emissions Inventory (NEI) Custom Pollutant Amount. Only a number can be entered. Identifies facilities with where the NEI Pollutant Emission Amount is greater than the number entered.
  --p-nei-yr: string # National Emissions Inventory (NEI) year: 2014 or 2011
  --p-nei-cat: string # National Emissions Inventory (NEI) Pollutant Category. When a pollutant category is entered, a corresponding formatted pollutant amount or custom amount must be entered.
  --p-pm: string@p-pm-completer # Percent Minority Population Limiter. Enter a value to restrict results to facilities with a given percentage of minority population within 3-mile radius. - NONE = 0% - GT5 = greater than 5% - GT10 = greater than 10% - GT25 = greater than 25% - GT50 = greater than 50% - GT75 = greater than 75%
  --p-pd: string@p-pd-completer # Population Density Limiter (per sq mile). Enter a value to limit results to facilities located in area of a given population density. - NONE = 0 population density per square mile - GT100 = More than 100 population density per square mile - GT500 = More than 500 population density per square mile - GT1000 = More than 1000 population density per square mile - GT5000 = More than 5000 population density per square mile - GT10000 = More than 10000 population density per square mile - GT20000 = More than 20000 population density per square mile
  --p-ico: string@p-ico-completer # Indian Country Flag. Enter a "Y" or "N" to restrict searches to facilities inside or outside Indian Country.
  --p-huc: string # 2-, 4-, 6-, or 8-character watershed code. May contain multiple comma-separated values.
  --p-wbd: string # 2-, 4-, 6-, 8-, 10-, or 12-character watershed (WBD from the USGS Watershed Boundary Dataset). May contain multiple comma-separated values. Uses the FRS Best Pick Coordinate to obtain the WBD12 Huc value.
  --p-pid: string # Nine-digit permit IDs. May contain up to 2000 comma-separated values.
  --p-med: string@p-med-completer # Filter Results by Media. - M = RMP (Risk Management Plan) - R = RCRA (Hazardous Waste) - S = SDWA (Public Drinking Water Systems) - W = Water - ALL = Water and RCRA and SDWA
  --p-ysl: string@p-ysl-completer # Last Facility Inspection [within / not within] Specified Date Range Indicator. The date range is determined by parameters p_idt1 and p_idt2 or by parameter p_ysly. - W = within date range - N = not within date range
  --p-ysly: float@p-ysly-completer # Number of years (1 to 5) since last facility inspection. A value of 1 means that it has been inspected within the year.
  --p-ysla: string@p-ysla-completer # Facility Last Inspection Code Filter. If left blank, both agencies are included. Enter a value to limit results: - E = EPA - S = State
  --p-stsl: string@p-stsl-completer # Last Stack Test [within / not within] Specified Date Range Indicator. - W = within date range - N = not within date range
  --p-stsly: float@p-stsly-completer # Number of years (1 to 5) since date of last stack test. A value of 1 means it has been inspected within the year.
  --p-stsla: string@p-stsla-completer # Stack Last Test Code Filter. Enter a value to limit results: - A = All - E = EPA - S = State
  --p-stres: string # Air Stack Test Status Description Filter. Enter one or more test status descriptions to filter results. Enter multiple values as a comma-delimited list.
  --p-sttyp: string # Air Conductor Type Code Filter. Enter one or more conductor type codes to filter results. Provide multiple values as a comma-delimited list.
  --p-qs: string # Quick Search. Allows entry for city, state, and/or zip code.
  --p-sfs: string # Single Facility Search Filter. Provide a facility name or program system identifier to limit results. For the all data search, the FRS registry identifier is also searched.
  --p-tribeid: float # Numeric code for tribe (or list of tribes).
  --p-tribename: string # Tribe Name Filter. Enter a single tribe name to filter results.
  --p-tribedist: float # Proximity to tribal land limiter. Enter an amount of mile between 0 and 25 to filter results. This parameter is only evaluated if p_tribeid is populated.
  --p-owop: string # Owner/Operator code filter. Enter one or more codes to limit results. - CNG - COR - CTG - DIS - FDF - MWD - MXO - NON - POF - SDT - STF - TRB
  --p-agoo: string@p-agoo-completer # Indicates whether to AND or OR the Owner/Operator parameter (p_owop) and the federal agency code (p_fa) parameters.
  --p-idt1: string # Beginning of date range of most recent facility inspection.
  --p-idt2: string # End of date range of most recent facility inspection.
  --p-stdt1: string # Beginning of date range of most recent stack test.
  --p-stdt2: string # End of date range of most recent stack test.
  --p-pityp: string # Inspection Type: - CAC = Corrective Action Inspection - CAV = Compliance Assistance Visit - CDI = Case Development Inspection - CEI = Inspection Inspection - CSE = Compliance Schedule Evaluation - FCI = Focused Compliance - FRR = Financial Record Review - FSD = Facility Self Disclosure - FUI = Follow-Up Inspection - GME = Groundwater Monitoring Evaluation - NRR = Non-Financial Record Review - OAM = Operation and Maintenance Inspection May contain multiple comma-separated values.
  --p-cifdi: string@p-cifdi-completer # Compliance issuess found during inspection.
  --p-pfead1: string # Formal Enforcement Action Date Range Start. Enter a date in MM/DD/YYYY format to set the start of the range for filtering by recent Formal Enforcement Action (FEA) taken against the facility within the last five years.
  --p-pfead2: string # Formal Enforcement Action Date Range End. Enter a date in MM/DD/YYYY format to set the end of the date range for filtering by recent Formal Enforcement Action (FEA) taken against the facility within the last five years.
  --p-pfeat: string # Formal Enforcement Action (FEA) Code Filter. Enter one or more three-letter FEA codes to restrict results to facilities with these attributes. Use p_fead1 and p_fead2 parameters to further restrict this filter by entering a date range. Provide multiple codes as a comma-delimited list.
  --p-psncq: string@p-psncq-completer # Quarters in Significant Noncompliance Limiter. Enter a coded value to limit results to facilities with given quarter of significant noncompliance. - Z = Zero quarters in significant noncompliance. - GEXX = Replacing XX with a numeric value, that number of quarterd or more in significant noncompliance. - GTXX = Replacing XX with a numeric value, more than that number of quarters in significant noncompliance.
  --p-pctrack: string@p-pctrack-completer # Compliance Tracking Limiter. Provide a keyword to indicate the extent to which data is being entered and effluent exceedances are being identified. - Off - Partial - On
  --p-swpa: string@p-swpa-completer # Source water protection area
  --p-des: string # Universe Designation Limiter. Enter one or more universe designation codes. Provide multiple values as a comma-delimited list. Use code "TSDF" to return the full enforcement TSDF universe and "Operating TSDF" to return the operating TSDF universe.
  --p-fntype: string@p-fntype-completer # Controls type of text search performed on facility name with parameter p_fn. - EXACT = Find facilities having the exact provided name(s). - BEGINS = Find facilities with names starting with the provided term(s). - ALL = Find facilities using Oracle text search terms. - CONTAINS =
  --p-hpvmth: string # Months in high priority violation status out of the previous three years limiter. Provide a number of months in the past three years. Results will limited to facilities in high priority violation status during that time.
  --p-recvio: string # Recent Violation Status Filter. Enter one or more recent violation codes to limit results. Provide multiple values as a comma-delimited list. - NO VIOL = Selects facilities with no recent violations. - ANY HPV = Selects facilities with either addressed or unaddressed high priority violations. - ADDRS-EPA - Select facilities with recent EPA addressed violations. - ADDRS-LOCAL - Select facilities with recent locally addressed violations. - ADDRS-STATE - Select facilities with recent state addressed violations. - UNADDR-EPA - Select facilities with recent EPA unaddressed violations. - UNADDR-LOCAL - Select facilities with recent locally unaddressed violations. - UNADDR-STATE - Select facilities with recent state unaddressed violations. - FRV VIOL = Selects facilities with a recent federally reportable violation without a high priority violation.
  --p-pollvio: string # Air Pollutant Code For A Recent Violation Filter. Provide one or more pollutant codes to select facilities with one or more of the entered pollutant codes for a recent air violation. Provide multiple values as a comma-delimited list.
  --p-ar: string # Associated EPA Air Reports Program Filter. Enter multiple values as a comma-delimited list. Valid values are: - TRI = Toxic Release Inventory. - GHG = Green House Gas Reporter. - EIS = Emission Inventory System. - CAMD = Clean Air Markets Program Reporter.
  --p-tri-yr: string # Toxic Release Inventory Reporting Year Filter. Enter one or more year values to filter results by the TRI reporting year. Provide multiple years as a comma-delimited list.
  --p-pidall: string@p-pidall-completer # Controls whether search is restricted to existing system. Y means the search will match the p_pid parameter against all associated permits (AIR, RCRA, SDWIS, etc).
  --p-fac-ico: string@p-fac-ico-completer # FRS tribal land code flag. Enter "Y" or "N" to include or exclude facilities based on FRS tribal land code.
  --p-icoo: string # Indian country search and/or flag. Enter "Y" to set indian country search conditions to return any results found using p_ico, p_fac_ico or p_fac_icoo. Otherwise only results matching all provided p_ico, p_fac_ico or p_fac_icoo conditions will be returned.
  --p-fac-icos: string # FRS tribal land spatial flag. Enter "Y" or "N" to include or exclude facilities based on FRS tribal land spatial flag.
  --p-ejscreen: string # Enter "Y" to limit facilities to Census block groups where one of more Environmental Justice indexes above 80th percentile.
  --p-limit-addr: string@p-limit-addr-completer # Limit Address Search Flag. Enter Y to restrict facility searches to native data source only.
  --p-lat: float # Latitude location in decimal degrees.
  --p-long: float # Longitude location in decimal degrees.
  --p-radius: float # Spatial Search Radius. Enter a radius up to 100 miles in which to spatially search for facilities.
  --p-decouple: string@p-decouple-completer # Decouple Inspection Code Search Flag. Enter "Y" to search for inspection code types with p_pityp without respect to the date range search provided with p_ysl* parameters.
  --p-ejscreen-over80cnt: string@p-ejscreen-over80cnt-completer # The number of Environmenmt Justice Indicators above the 80th percentile. Valid values are 1 through 11.
  --queryset: float # Query Limiter. Enter a value to limit the number of records returned for each query. Value cannot exceed 70,000.
  --responseset: float # Response Set Limiter. Enter a value to limit the number of records per page. Value cannot exceed 1,000.
  --tablelist: string@tablelist-completer # Table List Flag. Enter a Y to display the first page of facility results.
  --maplist: string@maplist-completer # Map List Flag. Provide a Y to return mappable coordinates representing the full geographic extent of the queryset (all facilities that met the selection criteria).
  --summarylist: string@summarylist-completer # Summary List Flag. Enter a Y to return a list of summary statistics based on the parameters submitted to the query service.
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
  --qcolumns: string # Used to customize service output. A list of comma-separated column IDs of output objects that will be returned in the service query object or download. Use the metadata service endpoint for a complete list of Ids and definitions.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/air_rest_services.get_facilities"
    query: [{name: output, var: output}, {name: p_fn, var: p_fn}, {name: p_sa, var: p_sa}, {name: p_sa1, var: p_sa1}, {name: p_ct, var: p_ct}, {name: p_co, var: p_co}, {name: p_fips, var: p_fips}, {name: p_st, var: p_st}, {name: p_zip, var: p_zip}, {name: p_lcon, var: p_lcon}, {name: p_frs, var: p_frs}, {name: p_reg, var: p_reg}, {name: p_sic, var: p_sic}, {name: p_ncs, var: p_ncs}, {name: p_qnc, var: p_qnc}, {name: p_pen, var: p_pen}, {name: p_opst, var: p_opst}, {name: p_c1lat, var: p_c1lat}, {name: p_c1lon, var: p_c1lon}, {name: p_c2lat, var: p_c2lat}, {name: p_c2lon, var: p_c2lon}, {name: p_usmex, var: p_usmex}, {name: p_sic2, var: p_sic2}, {name: p_sic4, var: p_sic4}, {name: p_fa, var: p_fa}, {name: p_act, var: p_act}, {name: p_maj, var: p_maj}, {name: p_mact, var: p_mact}, {name: p_nsps, var: p_nsps}, {name: p_nspsm, var: p_nspsm}, {name: p_prog, var: p_prog}, {name: p_fea, var: p_fea}, {name: p_feay, var: p_feay}, {name: p_feaa, var: p_feaa}, {name: p_iea, var: p_iea}, {name: p_ieay, var: p_ieay}, {name: p_ieaa, var: p_ieaa}, {name: p_qiv, var: p_qiv}, {name: p_naa, var: p_naa}, {name: p_impw, var: p_impw}, {name: p_trep, var: p_trep}, {name: p_tri_cat, var: p_tri_cat}, {name: p_tri_amt, var: p_tri_amt}, {name: p_tri_any_amt, var: p_tri_any_amt}, {name: p_tri_pol, var: p_tri_pol}, {name: p_ghg_cat, var: p_ghg_cat}, {name: p_ghg_amt, var: p_ghg_amt}, {name: p_ghg_any_amt, var: p_ghg_any_amt}, {name: p_ghg_yr, var: p_ghg_yr}, {name: p_nei_pol, var: p_nei_pol}, {name: p_nei_amt, var: p_nei_amt}, {name: p_nei_any_amt, var: p_nei_any_amt}, {name: p_nei_yr, var: p_nei_yr}, {name: p_nei_cat, var: p_nei_cat}, {name: p_pm, var: p_pm}, {name: p_pd, var: p_pd}, {name: p_ico, var: p_ico}, {name: p_huc, var: p_huc}, {name: p_wbd, var: p_wbd}, {name: p_pid, var: p_pid}, {name: p_med, var: p_med}, {name: p_ysl, var: p_ysl}, {name: p_ysly, var: p_ysly}, {name: p_ysla, var: p_ysla}, {name: p_stsl, var: p_stsl}, {name: p_stsly, var: p_stsly}, {name: p_stsla, var: p_stsla}, {name: p_stres, var: p_stres}, {name: p_sttyp, var: p_sttyp}, {name: p_qs, var: p_qs}, {name: p_sfs, var: p_sfs}, {name: p_tribeid, var: p_tribeid}, {name: p_tribename, var: p_tribename}, {name: p_tribedist, var: p_tribedist}, {name: p_owop, var: p_owop}, {name: p_agoo, var: p_agoo}, {name: p_idt1, var: p_idt1}, {name: p_idt2, var: p_idt2}, {name: p_stdt1, var: p_stdt1}, {name: p_stdt2, var: p_stdt2}, {name: p_pityp, var: p_pityp}, {name: p_cifdi, var: p_cifdi}, {name: p_pfead1, var: p_pfead1}, {name: p_pfead2, var: p_pfead2}, {name: p_pfeat, var: p_pfeat}, {name: p_psncq, var: p_psncq}, {name: p_pctrack, var: p_pctrack}, {name: p_swpa, var: p_swpa}, {name: p_des, var: p_des}, {name: p_fntype, var: p_fntype}, {name: p_hpvmth, var: p_hpvmth}, {name: p_recvio, var: p_recvio}, {name: p_pollvio, var: p_pollvio}, {name: p_ar, var: p_ar}, {name: p_tri_yr, var: p_tri_yr}, {name: p_pidall, var: p_pidall}, {name: p_fac_ico, var: p_fac_ico}, {name: p_icoo, var: p_icoo}, {name: p_fac_icos, var: p_fac_icos}, {name: p_ejscreen, var: p_ejscreen}, {name: p_limit_addr, var: p_limit_addr}, {name: p_lat, var: p_lat}, {name: p_long, var: p_long}, {name: p_radius, var: p_radius}, {name: p_decouple, var: p_decouple}, {name: p_ejscreen_over80cnt, var: p_ejscreen_over80cnt}, {name: queryset, var: queryset}, {name: responseset, var: responseset}, {name: tablelist, var: tablelist}, {name: maplist, var: maplist}, {name: summarylist, var: summarylist}, {name: callback, var: callback}, {name: qcolumns, var: qcolumns}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_fn: $p_fn, p_sa: $p_sa, p_sa1: $p_sa1, p_ct: $p_ct, p_co: $p_co, p_fips: $p_fips, p_st: $p_st, p_zip: $p_zip, p_lcon: $p_lcon, p_frs: $p_frs, p_reg: $p_reg, p_sic: $p_sic, p_ncs: $p_ncs, p_qnc: $p_qnc, p_pen: $p_pen, p_opst: $p_opst, p_c1lat: $p_c1lat, p_c1lon: $p_c1lon, p_c2lat: $p_c2lat, p_c2lon: $p_c2lon, p_usmex: $p_usmex, p_sic2: $p_sic2, p_sic4: $p_sic4, p_fa: $p_fa, p_act: $p_act, p_maj: $p_maj, p_mact: $p_mact, p_nsps: $p_nsps, p_nspsm: $p_nspsm, p_prog: $p_prog, p_fea: $p_fea, p_feay: $p_feay, p_feaa: $p_feaa, p_iea: $p_iea, p_ieay: $p_ieay, p_ieaa: $p_ieaa, p_qiv: $p_qiv, p_naa: $p_naa, p_impw: $p_impw, p_trep: $p_trep, p_tri_cat: $p_tri_cat, p_tri_amt: $p_tri_amt, p_tri_any_amt: $p_tri_any_amt, p_tri_pol: $p_tri_pol, p_ghg_cat: $p_ghg_cat, p_ghg_amt: $p_ghg_amt, p_ghg_any_amt: $p_ghg_any_amt, p_ghg_yr: $p_ghg_yr, p_nei_pol: $p_nei_pol, p_nei_amt: $p_nei_amt, p_nei_any_amt: $p_nei_any_amt, p_nei_yr: $p_nei_yr, p_nei_cat: $p_nei_cat, p_pm: $p_pm, p_pd: $p_pd, p_ico: $p_ico, p_huc: $p_huc, p_wbd: $p_wbd, p_pid: $p_pid, p_med: $p_med, p_ysl: $p_ysl, p_ysly: $p_ysly, p_ysla: $p_ysla, p_stsl: $p_stsl, p_stsly: $p_stsly, p_stsla: $p_stsla, p_stres: $p_stres, p_sttyp: $p_sttyp, p_qs: $p_qs, p_sfs: $p_sfs, p_tribeid: $p_tribeid, p_tribename: $p_tribename, p_tribedist: $p_tribedist, p_owop: $p_owop, p_agoo: $p_agoo, p_idt1: $p_idt1, p_idt2: $p_idt2, p_stdt1: $p_stdt1, p_stdt2: $p_stdt2, p_pityp: $p_pityp, p_cifdi: $p_cifdi, p_pfead1: $p_pfead1, p_pfead2: $p_pfead2, p_pfeat: $p_pfeat, p_psncq: $p_psncq, p_pctrack: $p_pctrack, p_swpa: $p_swpa, p_des: $p_des, p_fntype: $p_fntype, p_hpvmth: $p_hpvmth, p_recvio: $p_recvio, p_pollvio: $p_pollvio, p_ar: $p_ar, p_tri_yr: $p_tri_yr, p_pidall: $p_pidall, p_fac_ico: $p_fac_ico, p_icoo: $p_icoo, p_fac_icos: $p_fac_icos, p_ejscreen: $p_ejscreen, p_limit_addr: $p_limit_addr, p_lat: $p_lat, p_long: $p_long, p_radius: $p_radius, p_decouple: $p_decouple, p_ejscreen_over80cnt: $p_ejscreen_over80cnt, queryset: $queryset, responseset: $responseset, tablelist: $tablelist, maplist: $maplist, summarylist: $summarylist, callback: $callback, qcolumns: $qcolumns
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Clean Air Act Facility Search
#
# POST /air_rest_services.get_facilities
# Returns: record<Results: record<BadSystemIDs: string, CVRows: string, FEARows: string, Facilities: list<record>, INSPRows: string, IndianCountryRows: string, InfFEARows: string, MapOutput: record<IconBaseURL: string, MapData: list, PopUpBaseURL: string, QueryID: string>, Message: string, PageNo: string, QueryID: string, QueryRows: string, SVRows: string, TotalPenalties: string, V3Rows: string>>
export def "post-air-rest-services-get-facilities" [
  --base-url(-b): string@base-url-completer # API base URL
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
  --p-lcon: string # Air Program Local Control Region Code Filter. Enter one or more local control region codes to filter results. Provide multiple codes as a comma-delimited list. Codes where they exist are specific by state.
  --p-frs: string # Facility Registry Service ID Filter. Enter a single 12-digit FRS identifier to filter results.
  --p-reg: string@p-reg-completer # EPA Region Filter. Provide a single value of 01 thru 10 to restrict results to a single EPA region.
  --p-sic: string # Standard Industrial Classification (SIC) Code Filter. Enter a single 4-digit SIC Code to filter results. If more complex filtering is required, use p_sic2 and p_sic4.
  --p-ncs: string # North American Industry Classification System Filter. Enter two to six digits to filter results to facilities having matching NAICS codes. Digits less than six will match to all codes beginning with the provided values.
  --p-qnc: float # Number of quarters in non-compliance limiter. Enter an integer value between 1 and 4 to limit results.
  --p-pen: string # Last Penality Date Qualifier Filter. Enter one of the following: - NEVER = No Penalties - ANY = Any Penalty - LEXX = Less than or equal to XX months. Provide a number in place of XX, e.g. "LE5" for a facility with a penalty within previous 5 months. - GTXX = Greater than XX months. Provide a number in place of XX, eg. GT12, for a facility with the last penalty greater than 12 months ago.
  --p-opst: string # Operating status filter. Enter one or more operating status codes to limit results. Provide multiple codes as a comma-delimited list.
  --p-c1lat: float # In decimal degrees. Latitude of 1st corner of box that bounds the resulting facilities. The latitude and longitude of both corners of the bounding box must be provided.
  --p-c1lon: float # In decimal degrees. Longitude of 1st corner of box that bounds the resulting facilities. The latitude and longitude of both corners of the bounding box must be provided.
  --p-c2lat: float # In decimal degrees. Latitude of 2nd corner of box that bounds the resulting facilities. The latitude and longitude of both corners of the bounding box must be provided.
  --p-c2lon: float # In decimal degrees. Longitude of 2nd corner of box that bounds the resulting facilities. The latitude and longitude of both corners of the bounding box must be provided.
  --p-usmex: string@p-usmex-completer # US-Mexico Border Flag. Enter Y/N to restrict searches to facilities located within 100KM of the border.
  --p-sic2: string # Standard Industrial Classification (SIC) Code Filter Alternate 2. Enter a wild-card search against SIC codes. A final wild-card is always present allowing "22" to match all SIC codes beginning with 22. Use the "%" character within strings to match any SIC values with the pattern. For example, "2%21" matches 2021, 2121, 2221, etc.
  --p-sic4: string # Standard Industrial Classification (SIC) Code Filter Alternate 3. Enter the first 2, 3 or 4 SIC code digits to filter results to facilities having those code prefixes. As this alternative does not utilize an index, p_sic2 will generally be quicker.
  --p-fa: string # Federal Agency. 1 character or 5-character values; may contain multiple comma-separated values. ALL will retrieve all facilities where the federal agency code is not null. Use the Federal Agencies lookup service to obtain a list of values.
  --p-act: string@p-act-completer # Active Permits/Facilities Flag. Provide Y or N to filter results to facilities with active permits.
  --p-maj: string@p-maj-completer # Major Facility Flag. Enter Y to restrict results to Major facilities only.
  --p-mact: string # CAA Maximum Achievable Control Technology (MACT) Subpart codes (alpha ID between 1 and 7 characters) applicable to the facility.
  --p-nsps: string # Air Programl New Source Performance Standards (NSPS) Subpart Code Search. One or more valid Air Program NSPS Program codes cand be passed.
  --p-nspsm: string # Air Programl New Source Performance Standards Minors (NSPSM) Subpart Code Search. One or more valid Air Program NSPSM Subpart codes can be passed.
  --p-prog: string # Air Program Code Filter. Enter one or more Air program codes to filter results. Provide multiple values as a comma-delimited list.
  --p-fea: string@p-fea-completer # Formal Enforcement Actions [within / not within] specified date range indicator. The date range is determined by parameters p_fead1 and p_fead2 or by parameter p_feay. - W = within date range - N = not within date range
  --p-feay: float@p-feay-completer # Years (1 to 5) Range. This value is used to create a date range for Formal Enforcement Actions (FEA). Used along with p_fea (which indicates whether to look within or outside of the date range) to find FEAs within (or not within) the number of years specified.
  --p-feaa: string@p-feaa-completer # Agency associated with Formal Enforcement Actions: - E = EPA - S = State - A = All
  --p-iea: string@p-iea-completer # Informal Enforcement Actions [within / not within] specified date range. The date range is determined by parameters p_iead1 and p_iead2 or by parameter p_ieay. - W = within date range - N = not within date range
  --p-ieay: float@p-ieay-completer # Years (1 to 5) Range. This value is used to create a date range for Informal Enforcement Actions (IEA). Used along with p_iea (which indicates whether to look within or outside of the date range) to find IEAs within (or not within) the number of years specified.
  --p-ieaa: string@p-ieaa-completer # Agency associated with Informal Enforcement Actions. If left blank, both agencies are included. - E = EPA - S = State
  --p-qiv: string@p-qiv-completer # Quarters in Noncompliance Limiter. Enter a coded value to limit results to facilities with given quarter of noncompliance. - Z = Zero quarters in noncompliance. - GEXX = Replacing XX with a numeric value, that number of quarterd or more in noncompliance. - GTXX = Replacing XX with a numeric value, more than that number of quarters in noncompliance.
  --p-naa: string # Non-Attainment Area Flag. Enter a Y or N to filter for or against facilities flagged as non-attainment areas.
  --p-impw: string@p-impw-completer # Discharging into Impaired Waters Flag. Enter Y to limit results to facilities with discharge to waterbodies listed as impaired in the ATTAINS database.
  --p-trep: string@p-trep-completer # Current Toxics Release Inventory (TRI) Reporter Limiter. Enter one of the following codes to limit results. - CURR = Current TRI reporter. - NONCURR = Has reported to TRI in the past but not for the current reporting year.
  --p-tri-cat: string@p-tri-cat-completer # Toxic Release Inventory Released To Air Chemical Identifier Category Filter. Enter the chemical identifier category code to limit results. Note when filtering by TRI chemical identifier categories one may not also filter by specific chemical identifiers via p_tri_pol. You must also specify a release amount using p_tri_amt or p_tri_any_amt. - TOTAL = Total Released to Air - CARC = Total Carcinogens Released to Air - HAP = Total Hazardous Air Pollutants Released to Air
  --p-tri-amt: string@p-tri-amt-completer # Toxic Release Inventory Release Amount Filter. Enter a value in pounds to limit results to facilities releasing this amount or greateer of TRI releases. Valid values are 0, GT0, GT1000, GT5000, GT10000 and GT50000. Note when filtering by TRI release amounts one may only use either p_tri_amt or p_tri_any_amt.
  --p-tri-any-amt: float # Toxic Release Inventory Release Of Any Kind Above Value Filter. Enter a value to limit results to facilities releasing this amount or more of TRI releases. Note when filtering by TRI releases one may only use p_tri_any_amt or p_tri_amt and not both.
  --p-tri-pol: string # Toxic Release Inventory Chemical Identifier Filter. Enter one or more chemical identifier codes to limit results. Note when filtering by specific TRI chemical identifiers one may not also filter by chemical identifier categories via p_tri_cat.
  --p-ghg-cat: string@p-ghg-cat-completer # Green House Gas (GHG) Gas Code Category. Must be used with either a formatted (p_ghg_amt) or custom (p_ghg_any_amt) release amount.
  --p-ghg-amt: string@p-ghg-amt-completer # Green House Gas (GHG) CO2 Equivalent Formatted Release Amount. First 2 characters must contain GT (greater than) followed by a number.
  --p-ghg-any-amt: float # Green House Gas (GHG) C02 Equivalent Custom Amount. The C02E value reported for the provided category, will be greater or equal to the amount provided.
  --p-ghg-yr: string # Green House Gas (GHG) Reporting Year. (2010 through 2015)
  --p-nei-pol: string # National Emissions Inventory (NEI) Pollutant Identifier. When a pollutant identifer is entered a corresponding formatted amount or custom amount must be entered.
  --p-nei-amt: string@p-nei-amt-completer # National Emissions Inventory (NEI) Formatted Pollutant Amount. A formatted value where the 1st two characters must start with GT or LT followed by a number. Identifies facilities that have a NEI Pollutant Emission where the supplied value is > or < the pollutant emission amount.
  --p-nei-any-amt: float # National Emissions Inventory (NEI) Custom Pollutant Amount. Only a number can be entered. Identifies facilities with where the NEI Pollutant Emission Amount is greater than the number entered.
  --p-nei-yr: string # National Emissions Inventory (NEI) year: 2014 or 2011
  --p-nei-cat: string # National Emissions Inventory (NEI) Pollutant Category. When a pollutant category is entered, a corresponding formatted pollutant amount or custom amount must be entered.
  --p-pm: string@p-pm-completer # Percent Minority Population Limiter. Enter a value to restrict results to facilities with a given percentage of minority population within 3-mile radius. - NONE = 0% - GT5 = greater than 5% - GT10 = greater than 10% - GT25 = greater than 25% - GT50 = greater than 50% - GT75 = greater than 75%
  --p-pd: string@p-pd-completer # Population Density Limiter (per sq mile). Enter a value to limit results to facilities located in area of a given population density. - NONE = 0 population density per square mile - GT100 = More than 100 population density per square mile - GT500 = More than 500 population density per square mile - GT1000 = More than 1000 population density per square mile - GT5000 = More than 5000 population density per square mile - GT10000 = More than 10000 population density per square mile - GT20000 = More than 20000 population density per square mile
  --p-ico: string@p-ico-completer # Indian Country Flag. Enter a "Y" or "N" to restrict searches to facilities inside or outside Indian Country.
  --p-huc: string # 2-, 4-, 6-, or 8-character watershed code. May contain multiple comma-separated values.
  --p-wbd: string # 2-, 4-, 6-, 8-, 10-, or 12-character watershed (WBD from the USGS Watershed Boundary Dataset). May contain multiple comma-separated values. Uses the FRS Best Pick Coordinate to obtain the WBD12 Huc value.
  --p-pid: string # Nine-digit permit IDs. May contain up to 2000 comma-separated values.
  --p-med: string@p-med-completer # Filter Results by Media. - M = RMP (Risk Management Plan) - R = RCRA (Hazardous Waste) - S = SDWA (Public Drinking Water Systems) - W = Water - ALL = Water and RCRA and SDWA
  --p-ysl: string@p-ysl-completer # Last Facility Inspection [within / not within] Specified Date Range Indicator. The date range is determined by parameters p_idt1 and p_idt2 or by parameter p_ysly. - W = within date range - N = not within date range
  --p-ysly: float@p-ysly-completer # Number of years (1 to 5) since last facility inspection. A value of 1 means that it has been inspected within the year.
  --p-ysla: string@p-ysla-completer # Facility Last Inspection Code Filter. If left blank, both agencies are included. Enter a value to limit results: - E = EPA - S = State
  --p-stsl: string@p-stsl-completer # Last Stack Test [within / not within] Specified Date Range Indicator. - W = within date range - N = not within date range
  --p-stsly: float@p-stsly-completer # Number of years (1 to 5) since date of last stack test. A value of 1 means it has been inspected within the year.
  --p-stsla: string@p-stsla-completer # Stack Last Test Code Filter. Enter a value to limit results: - A = All - E = EPA - S = State
  --p-stres: string # Air Stack Test Status Description Filter. Enter one or more test status descriptions to filter results. Enter multiple values as a comma-delimited list.
  --p-sttyp: string # Air Conductor Type Code Filter. Enter one or more conductor type codes to filter results. Provide multiple values as a comma-delimited list.
  --p-qs: string # Quick Search. Allows entry for city, state, and/or zip code.
  --p-sfs: string # Single Facility Search Filter. Provide a facility name or program system identifier to limit results. For the all data search, the FRS registry identifier is also searched.
  --p-tribeid: float # Numeric code for tribe (or list of tribes).
  --p-tribename: string # Tribe Name Filter. Enter a single tribe name to filter results.
  --p-tribedist: float # Proximity to tribal land limiter. Enter an amount of mile between 0 and 25 to filter results. This parameter is only evaluated if p_tribeid is populated.
  --p-owop: string # Owner/Operator code filter. Enter one or more codes to limit results. - CNG - COR - CTG - DIS - FDF - MWD - MXO - NON - POF - SDT - STF - TRB
  --p-agoo: string@p-agoo-completer # Indicates whether to AND or OR the Owner/Operator parameter (p_owop) and the federal agency code (p_fa) parameters.
  --p-idt1: string # Beginning of date range of most recent facility inspection.
  --p-idt2: string # End of date range of most recent facility inspection.
  --p-stdt1: string # Beginning of date range of most recent stack test.
  --p-stdt2: string # End of date range of most recent stack test.
  --p-pityp: string # Inspection Type: - CAC = Corrective Action Inspection - CAV = Compliance Assistance Visit - CDI = Case Development Inspection - CEI = Inspection Inspection - CSE = Compliance Schedule Evaluation - FCI = Focused Compliance - FRR = Financial Record Review - FSD = Facility Self Disclosure - FUI = Follow-Up Inspection - GME = Groundwater Monitoring Evaluation - NRR = Non-Financial Record Review - OAM = Operation and Maintenance Inspection May contain multiple comma-separated values.
  --p-cifdi: string@p-cifdi-completer # Compliance issuess found during inspection.
  --p-pfead1: string # Formal Enforcement Action Date Range Start. Enter a date in MM/DD/YYYY format to set the start of the range for filtering by recent Formal Enforcement Action (FEA) taken against the facility within the last five years.
  --p-pfead2: string # Formal Enforcement Action Date Range End. Enter a date in MM/DD/YYYY format to set the end of the date range for filtering by recent Formal Enforcement Action (FEA) taken against the facility within the last five years.
  --p-pfeat: string # Formal Enforcement Action (FEA) Code Filter. Enter one or more three-letter FEA codes to restrict results to facilities with these attributes. Use p_fead1 and p_fead2 parameters to further restrict this filter by entering a date range. Provide multiple codes as a comma-delimited list.
  --p-psncq: string@p-psncq-completer # Quarters in Significant Noncompliance Limiter. Enter a coded value to limit results to facilities with given quarter of significant noncompliance. - Z = Zero quarters in significant noncompliance. - GEXX = Replacing XX with a numeric value, that number of quarterd or more in significant noncompliance. - GTXX = Replacing XX with a numeric value, more than that number of quarters in significant noncompliance.
  --p-pctrack: string@p-pctrack-completer # Compliance Tracking Limiter. Provide a keyword to indicate the extent to which data is being entered and effluent exceedances are being identified. - Off - Partial - On
  --p-swpa: string@p-swpa-completer # Source water protection area
  --p-des: string # Universe Designation Limiter. Enter one or more universe designation codes. Provide multiple values as a comma-delimited list. Use code "TSDF" to return the full enforcement TSDF universe and "Operating TSDF" to return the operating TSDF universe.
  --p-fntype: string@p-fntype-completer # Controls type of text search performed on facility name with parameter p_fn. - EXACT = Find facilities having the exact provided name(s). - BEGINS = Find facilities with names starting with the provided term(s). - ALL = Find facilities using Oracle text search terms. - CONTAINS =
  --p-hpvmth: string # Months in high priority violation status out of the previous three years limiter. Provide a number of months in the past three years. Results will limited to facilities in high priority violation status during that time.
  --p-recvio: string # Recent Violation Status Filter. Enter one or more recent violation codes to limit results. Provide multiple values as a comma-delimited list. - NO VIOL = Selects facilities with no recent violations. - ANY HPV = Selects facilities with either addressed or unaddressed high priority violations. - ADDRS-EPA - Select facilities with recent EPA addressed violations. - ADDRS-LOCAL - Select facilities with recent locally addressed violations. - ADDRS-STATE - Select facilities with recent state addressed violations. - UNADDR-EPA - Select facilities with recent EPA unaddressed violations. - UNADDR-LOCAL - Select facilities with recent locally unaddressed violations. - UNADDR-STATE - Select facilities with recent state unaddressed violations. - FRV VIOL = Selects facilities with a recent federally reportable violation without a high priority violation.
  --p-pollvio: string # Air Pollutant Code For A Recent Violation Filter. Provide one or more pollutant codes to select facilities with one or more of the entered pollutant codes for a recent air violation. Provide multiple values as a comma-delimited list.
  --p-ar: string # Associated EPA Air Reports Program Filter. Enter multiple values as a comma-delimited list. Valid values are: - TRI = Toxic Release Inventory. - GHG = Green House Gas Reporter. - EIS = Emission Inventory System. - CAMD = Clean Air Markets Program Reporter.
  --p-tri-yr: string # Toxic Release Inventory Reporting Year Filter. Enter one or more year values to filter results by the TRI reporting year. Provide multiple years as a comma-delimited list.
  --p-pidall: string@p-pidall-completer # Controls whether search is restricted to existing system. Y means the search will match the p_pid parameter against all associated permits (AIR, RCRA, SDWIS, etc).
  --p-fac-ico: string@p-fac-ico-completer # FRS tribal land code flag. Enter "Y" or "N" to include or exclude facilities based on FRS tribal land code.
  --p-icoo: string # Indian country search and/or flag. Enter "Y" to set indian country search conditions to return any results found using p_ico, p_fac_ico or p_fac_icoo. Otherwise only results matching all provided p_ico, p_fac_ico or p_fac_icoo conditions will be returned.
  --p-fac-icos: string # FRS tribal land spatial flag. Enter "Y" or "N" to include or exclude facilities based on FRS tribal land spatial flag.
  --p-ejscreen: string # Enter "Y" to limit facilities to Census block groups where one of more Environmental Justice indexes above 80th percentile.
  --p-limit-addr: string@p-limit-addr-completer # Limit Address Search Flag. Enter Y to restrict facility searches to native data source only.
  --p-lat: float # Latitude location in decimal degrees.
  --p-long: float # Longitude location in decimal degrees.
  --p-radius: float # Spatial Search Radius. Enter a radius up to 100 miles in which to spatially search for facilities.
  --p-decouple: string@p-decouple-completer # Decouple Inspection Code Search Flag. Enter "Y" to search for inspection code types with p_pityp without respect to the date range search provided with p_ysl* parameters.
  --p-ejscreen-over80cnt: string@p-ejscreen-over80cnt-completer # The number of Environmenmt Justice Indicators above the 80th percentile. Valid values are 1 through 11.
  --queryset: float # Query Limiter. Enter a value to limit the number of records returned for each query. Value cannot exceed 70,000.
  --responseset: float # Response Set Limiter. Enter a value to limit the number of records per page. Value cannot exceed 1,000.
  --tablelist: string@tablelist-completer # Table List Flag. Enter a Y to display the first page of facility results.
  --maplist: string@maplist-completer # Map List Flag. Provide a Y to return mappable coordinates representing the full geographic extent of the queryset (all facilities that met the selection criteria).
  --summarylist: string@summarylist-completer # Summary List Flag. Enter a Y to return a list of summary statistics based on the parameters submitted to the query service.
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
  --qcolumns: string # Used to customize service output. A list of comma-separated column IDs of output objects that will be returned in the service query object or download. Use the metadata service endpoint for a complete list of Ids and definitions.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/air_rest_services.get_facilities"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: p_fn, var: p_fn}, {name: p_sa, var: p_sa}, {name: p_sa1, var: p_sa1}, {name: p_ct, var: p_ct}, {name: p_co, var: p_co}, {name: p_fips, var: p_fips}, {name: p_st, var: p_st}, {name: p_zip, var: p_zip}, {name: p_lcon, var: p_lcon}, {name: p_frs, var: p_frs}, {name: p_reg, var: p_reg}, {name: p_sic, var: p_sic}, {name: p_ncs, var: p_ncs}, {name: p_qnc, var: p_qnc}, {name: p_pen, var: p_pen}, {name: p_opst, var: p_opst}, {name: p_c1lat, var: p_c1lat}, {name: p_c1lon, var: p_c1lon}, {name: p_c2lat, var: p_c2lat}, {name: p_c2lon, var: p_c2lon}, {name: p_usmex, var: p_usmex}, {name: p_sic2, var: p_sic2}, {name: p_sic4, var: p_sic4}, {name: p_fa, var: p_fa}, {name: p_act, var: p_act}, {name: p_maj, var: p_maj}, {name: p_mact, var: p_mact}, {name: p_nsps, var: p_nsps}, {name: p_nspsm, var: p_nspsm}, {name: p_prog, var: p_prog}, {name: p_fea, var: p_fea}, {name: p_feay, var: p_feay}, {name: p_feaa, var: p_feaa}, {name: p_iea, var: p_iea}, {name: p_ieay, var: p_ieay}, {name: p_ieaa, var: p_ieaa}, {name: p_qiv, var: p_qiv}, {name: p_naa, var: p_naa}, {name: p_impw, var: p_impw}, {name: p_trep, var: p_trep}, {name: p_tri_cat, var: p_tri_cat}, {name: p_tri_amt, var: p_tri_amt}, {name: p_tri_any_amt, var: p_tri_any_amt}, {name: p_tri_pol, var: p_tri_pol}, {name: p_ghg_cat, var: p_ghg_cat}, {name: p_ghg_amt, var: p_ghg_amt}, {name: p_ghg_any_amt, var: p_ghg_any_amt}, {name: p_ghg_yr, var: p_ghg_yr}, {name: p_nei_pol, var: p_nei_pol}, {name: p_nei_amt, var: p_nei_amt}, {name: p_nei_any_amt, var: p_nei_any_amt}, {name: p_nei_yr, var: p_nei_yr}, {name: p_nei_cat, var: p_nei_cat}, {name: p_pm, var: p_pm}, {name: p_pd, var: p_pd}, {name: p_ico, var: p_ico}, {name: p_huc, var: p_huc}, {name: p_wbd, var: p_wbd}, {name: p_pid, var: p_pid}, {name: p_med, var: p_med}, {name: p_ysl, var: p_ysl}, {name: p_ysly, var: p_ysly}, {name: p_ysla, var: p_ysla}, {name: p_stsl, var: p_stsl}, {name: p_stsly, var: p_stsly}, {name: p_stsla, var: p_stsla}, {name: p_stres, var: p_stres}, {name: p_sttyp, var: p_sttyp}, {name: p_qs, var: p_qs}, {name: p_sfs, var: p_sfs}, {name: p_tribeid, var: p_tribeid}, {name: p_tribename, var: p_tribename}, {name: p_tribedist, var: p_tribedist}, {name: p_owop, var: p_owop}, {name: p_agoo, var: p_agoo}, {name: p_idt1, var: p_idt1}, {name: p_idt2, var: p_idt2}, {name: p_stdt1, var: p_stdt1}, {name: p_stdt2, var: p_stdt2}, {name: p_pityp, var: p_pityp}, {name: p_cifdi, var: p_cifdi}, {name: p_pfead1, var: p_pfead1}, {name: p_pfead2, var: p_pfead2}, {name: p_pfeat, var: p_pfeat}, {name: p_psncq, var: p_psncq}, {name: p_pctrack, var: p_pctrack}, {name: p_swpa, var: p_swpa}, {name: p_des, var: p_des}, {name: p_fntype, var: p_fntype}, {name: p_hpvmth, var: p_hpvmth}, {name: p_recvio, var: p_recvio}, {name: p_pollvio, var: p_pollvio}, {name: p_ar, var: p_ar}, {name: p_tri_yr, var: p_tri_yr}, {name: p_pidall, var: p_pidall}, {name: p_fac_ico, var: p_fac_ico}, {name: p_icoo, var: p_icoo}, {name: p_fac_icos, var: p_fac_icos}, {name: p_ejscreen, var: p_ejscreen}, {name: p_limit_addr, var: p_limit_addr}, {name: p_lat, var: p_lat}, {name: p_long, var: p_long}, {name: p_radius, var: p_radius}, {name: p_decouple, var: p_decouple}, {name: p_ejscreen_over80cnt, var: p_ejscreen_over80cnt}, {name: queryset, var: queryset}, {name: responseset, var: responseset}, {name: tablelist, var: tablelist}, {name: maplist, var: maplist}, {name: summarylist, var: summarylist}, {name: callback, var: callback}, {name: qcolumns, var: qcolumns}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_fn: $p_fn, p_sa: $p_sa, p_sa1: $p_sa1, p_ct: $p_ct, p_co: $p_co, p_fips: $p_fips, p_st: $p_st, p_zip: $p_zip, p_lcon: $p_lcon, p_frs: $p_frs, p_reg: $p_reg, p_sic: $p_sic, p_ncs: $p_ncs, p_qnc: $p_qnc, p_pen: $p_pen, p_opst: $p_opst, p_c1lat: $p_c1lat, p_c1lon: $p_c1lon, p_c2lat: $p_c2lat, p_c2lon: $p_c2lon, p_usmex: $p_usmex, p_sic2: $p_sic2, p_sic4: $p_sic4, p_fa: $p_fa, p_act: $p_act, p_maj: $p_maj, p_mact: $p_mact, p_nsps: $p_nsps, p_nspsm: $p_nspsm, p_prog: $p_prog, p_fea: $p_fea, p_feay: $p_feay, p_feaa: $p_feaa, p_iea: $p_iea, p_ieay: $p_ieay, p_ieaa: $p_ieaa, p_qiv: $p_qiv, p_naa: $p_naa, p_impw: $p_impw, p_trep: $p_trep, p_tri_cat: $p_tri_cat, p_tri_amt: $p_tri_amt, p_tri_any_amt: $p_tri_any_amt, p_tri_pol: $p_tri_pol, p_ghg_cat: $p_ghg_cat, p_ghg_amt: $p_ghg_amt, p_ghg_any_amt: $p_ghg_any_amt, p_ghg_yr: $p_ghg_yr, p_nei_pol: $p_nei_pol, p_nei_amt: $p_nei_amt, p_nei_any_amt: $p_nei_any_amt, p_nei_yr: $p_nei_yr, p_nei_cat: $p_nei_cat, p_pm: $p_pm, p_pd: $p_pd, p_ico: $p_ico, p_huc: $p_huc, p_wbd: $p_wbd, p_pid: $p_pid, p_med: $p_med, p_ysl: $p_ysl, p_ysly: $p_ysly, p_ysla: $p_ysla, p_stsl: $p_stsl, p_stsly: $p_stsly, p_stsla: $p_stsla, p_stres: $p_stres, p_sttyp: $p_sttyp, p_qs: $p_qs, p_sfs: $p_sfs, p_tribeid: $p_tribeid, p_tribename: $p_tribename, p_tribedist: $p_tribedist, p_owop: $p_owop, p_agoo: $p_agoo, p_idt1: $p_idt1, p_idt2: $p_idt2, p_stdt1: $p_stdt1, p_stdt2: $p_stdt2, p_pityp: $p_pityp, p_cifdi: $p_cifdi, p_pfead1: $p_pfead1, p_pfead2: $p_pfead2, p_pfeat: $p_pfeat, p_psncq: $p_psncq, p_pctrack: $p_pctrack, p_swpa: $p_swpa, p_des: $p_des, p_fntype: $p_fntype, p_hpvmth: $p_hpvmth, p_recvio: $p_recvio, p_pollvio: $p_pollvio, p_ar: $p_ar, p_tri_yr: $p_tri_yr, p_pidall: $p_pidall, p_fac_ico: $p_fac_ico, p_icoo: $p_icoo, p_fac_icos: $p_fac_icos, p_ejscreen: $p_ejscreen, p_limit_addr: $p_limit_addr, p_lat: $p_lat, p_long: $p_long, p_radius: $p_radius, p_decouple: $p_decouple, p_ejscreen_over80cnt: $p_ejscreen_over80cnt, queryset: $queryset, responseset: $responseset, tablelist: $tablelist, maplist: $maplist, summarylist: $summarylist, callback: $callback, qcolumns: $qcolumns
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Clean Air Act Facility Enhanced Search
#
# GET /air_rest_services.get_facility_info
# Returns: record<Results: record<BadSystemIDs: string, CVRows: string, ClusterOutput: record<ClusterData: list>, ClusterRecords: string, FEARows: string, Facilities: list<record>, INSPRows: string, IconBaseURL: string, IndianCountryRows: string, InfFEARows: string, Message: string, PopUpBaseURL: string, QueryID: string, QueryParameters: list<record>, QueryRows: string, SVRows: string, ServiceBaseURL: string, TotalPenalties: string, V3Rows: string>>
export def "get-air-rest-services-get-facility-info" [
  --base-url(-b): string@base-url-completer # API base URL
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
  --p-lcon: string # Air Program Local Control Region Code Filter. Enter one or more local control region codes to filter results. Provide multiple codes as a comma-delimited list. Codes where they exist are specific by state.
  --p-frs: string # Facility Registry Service ID Filter. Enter a single 12-digit FRS identifier to filter results.
  --p-reg: string@p-reg-completer # EPA Region Filter. Provide a single value of 01 thru 10 to restrict results to a single EPA region.
  --p-sic: string # Standard Industrial Classification (SIC) Code Filter. Enter a single 4-digit SIC Code to filter results. If more complex filtering is required, use p_sic2 and p_sic4.
  --p-ncs: string # North American Industry Classification System Filter. Enter two to six digits to filter results to facilities having matching NAICS codes. Digits less than six will match to all codes beginning with the provided values.
  --p-qnc: float # Number of quarters in non-compliance limiter. Enter an integer value between 1 and 4 to limit results.
  --p-pen: string # Last Penality Date Qualifier Filter. Enter one of the following: - NEVER = No Penalties - ANY = Any Penalty - LEXX = Less than or equal to XX months. Provide a number in place of XX, e.g. "LE5" for a facility with a penalty within previous 5 months. - GTXX = Greater than XX months. Provide a number in place of XX, eg. GT12, for a facility with the last penalty greater than 12 months ago.
  --p-opst: string # Operating status filter. Enter one or more operating status codes to limit results. Provide multiple codes as a comma-delimited list.
  --xmin: float # Minimum longitude value in decimal degrees.
  --ymin: float # Minimum latitude value in decimal degrees.
  --xmax: float # Maximum longitude value in decimal degrees.
  --ymax: float # Maximum latitude value in decimal degrees.
  --p-usmex: string@p-usmex-completer # US-Mexico Border Flag. Enter Y/N to restrict searches to facilities located within 100KM of the border.
  --p-sic2: string # Standard Industrial Classification (SIC) Code Filter Alternate 2. Enter a wild-card search against SIC codes. A final wild-card is always present allowing "22" to match all SIC codes beginning with 22. Use the "%" character within strings to match any SIC values with the pattern. For example, "2%21" matches 2021, 2121, 2221, etc.
  --p-sic4: string # Standard Industrial Classification (SIC) Code Filter Alternate 3. Enter the first 2, 3 or 4 SIC code digits to filter results to facilities having those code prefixes. As this alternative does not utilize an index, p_sic2 will generally be quicker.
  --p-fa: string # Federal Agency. 1 character or 5-character values; may contain multiple comma-separated values. ALL will retrieve all facilities where the federal agency code is not null. Use the Federal Agencies lookup service to obtain a list of values.
  --p-act: string@p-act-completer # Active Permits/Facilities Flag. Provide Y or N to filter results to facilities with active permits.
  --p-maj: string@p-maj-completer # Major Facility Flag. Enter Y to restrict results to Major facilities only.
  --p-mact: string # CAA Maximum Achievable Control Technology (MACT) Subpart codes (alpha ID between 1 and 7 characters) applicable to the facility.
  --p-nsps: string # Air Programl New Source Performance Standards (NSPS) Subpart Code Search. One or more valid Air Program NSPS Program codes cand be passed.
  --p-nspsm: string # Air Programl New Source Performance Standards Minors (NSPSM) Subpart Code Search. One or more valid Air Program NSPSM Subpart codes can be passed.
  --p-prog: string # Air Program Code Filter. Enter one or more Air program codes to filter results. Provide multiple values as a comma-delimited list.
  --p-fea: string@p-fea-completer # Formal Enforcement Actions [within / not within] specified date range indicator. The date range is determined by parameters p_fead1 and p_fead2 or by parameter p_feay. - W = within date range - N = not within date range
  --p-feay: float@p-feay-completer # Years (1 to 5) Range. This value is used to create a date range for Formal Enforcement Actions (FEA). Used along with p_fea (which indicates whether to look within or outside of the date range) to find FEAs within (or not within) the number of years specified.
  --p-feaa: string@p-feaa-completer # Agency associated with Formal Enforcement Actions: - E = EPA - S = State - A = All
  --p-iea: string@p-iea-completer # Informal Enforcement Actions [within / not within] specified date range. The date range is determined by parameters p_iead1 and p_iead2 or by parameter p_ieay. - W = within date range - N = not within date range
  --p-ieay: float@p-ieay-completer # Years (1 to 5) Range. This value is used to create a date range for Informal Enforcement Actions (IEA). Used along with p_iea (which indicates whether to look within or outside of the date range) to find IEAs within (or not within) the number of years specified.
  --p-ieaa: string@p-ieaa-completer # Agency associated with Informal Enforcement Actions. If left blank, both agencies are included. - E = EPA - S = State
  --p-qiv: string@p-qiv-completer # Quarters in Noncompliance Limiter. Enter a coded value to limit results to facilities with given quarter of noncompliance. - Z = Zero quarters in noncompliance. - GEXX = Replacing XX with a numeric value, that number of quarterd or more in noncompliance. - GTXX = Replacing XX with a numeric value, more than that number of quarters in noncompliance.
  --p-naa: string # Non-Attainment Area Flag. Enter a Y or N to filter for or against facilities flagged as non-attainment areas.
  --p-impw: string@p-impw-completer # Discharging into Impaired Waters Flag. Enter Y to limit results to facilities with discharge to waterbodies listed as impaired in the ATTAINS database.
  --p-trep: string@p-trep-completer # Current Toxics Release Inventory (TRI) Reporter Limiter. Enter one of the following codes to limit results. - CURR = Current TRI reporter. - NONCURR = Has reported to TRI in the past but not for the current reporting year.
  --p-tri-cat: string@p-tri-cat-completer # Toxic Release Inventory Released To Air Chemical Identifier Category Filter. Enter the chemical identifier category code to limit results. Note when filtering by TRI chemical identifier categories one may not also filter by specific chemical identifiers via p_tri_pol. You must also specify a release amount using p_tri_amt or p_tri_any_amt. - TOTAL = Total Released to Air - CARC = Total Carcinogens Released to Air - HAP = Total Hazardous Air Pollutants Released to Air
  --p-tri-amt: string@p-tri-amt-completer # Toxic Release Inventory Release Amount Filter. Enter a value in pounds to limit results to facilities releasing this amount or greateer of TRI releases. Valid values are 0, GT0, GT1000, GT5000, GT10000 and GT50000. Note when filtering by TRI release amounts one may only use either p_tri_amt or p_tri_any_amt.
  --p-tri-any-amt: float # Toxic Release Inventory Release Of Any Kind Above Value Filter. Enter a value to limit results to facilities releasing this amount or more of TRI releases. Note when filtering by TRI releases one may only use p_tri_any_amt or p_tri_amt and not both.
  --p-tri-pol: string # Toxic Release Inventory Chemical Identifier Filter. Enter one or more chemical identifier codes to limit results. Note when filtering by specific TRI chemical identifiers one may not also filter by chemical identifier categories via p_tri_cat.
  --p-ghg-cat: string@p-ghg-cat-completer # Green House Gas (GHG) Gas Code Category. Must be used with either a formatted (p_ghg_amt) or custom (p_ghg_any_amt) release amount.
  --p-ghg-amt: string@p-ghg-amt-completer # Green House Gas (GHG) CO2 Equivalent Formatted Release Amount. First 2 characters must contain GT (greater than) followed by a number.
  --p-ghg-any-amt: float # Green House Gas (GHG) C02 Equivalent Custom Amount. The C02E value reported for the provided category, will be greater or equal to the amount provided.
  --p-ghg-yr: string # Green House Gas (GHG) Reporting Year. (2010 through 2015)
  --p-nei-pol: string # National Emissions Inventory (NEI) Pollutant Identifier. When a pollutant identifer is entered a corresponding formatted amount or custom amount must be entered.
  --p-nei-amt: string@p-nei-amt-completer # National Emissions Inventory (NEI) Formatted Pollutant Amount. A formatted value where the 1st two characters must start with GT or LT followed by a number. Identifies facilities that have a NEI Pollutant Emission where the supplied value is > or < the pollutant emission amount.
  --p-nei-any-amt: float # National Emissions Inventory (NEI) Custom Pollutant Amount. Only a number can be entered. Identifies facilities with where the NEI Pollutant Emission Amount is greater than the number entered.
  --p-nei-yr: string # National Emissions Inventory (NEI) year: 2014 or 2011
  --p-nei-cat: string # National Emissions Inventory (NEI) Pollutant Category. When a pollutant category is entered, a corresponding formatted pollutant amount or custom amount must be entered.
  --p-pm: string@p-pm-completer # Percent Minority Population Limiter. Enter a value to restrict results to facilities with a given percentage of minority population within 3-mile radius. - NONE = 0% - GT5 = greater than 5% - GT10 = greater than 10% - GT25 = greater than 25% - GT50 = greater than 50% - GT75 = greater than 75%
  --p-pd: string@p-pd-completer # Population Density Limiter (per sq mile). Enter a value to limit results to facilities located in area of a given population density. - NONE = 0 population density per square mile - GT100 = More than 100 population density per square mile - GT500 = More than 500 population density per square mile - GT1000 = More than 1000 population density per square mile - GT5000 = More than 5000 population density per square mile - GT10000 = More than 10000 population density per square mile - GT20000 = More than 20000 population density per square mile
  --p-ico: string@p-ico-completer # Indian Country Flag. Enter a "Y" or "N" to restrict searches to facilities inside or outside Indian Country.
  --p-huc: string # 2-, 4-, 6-, or 8-character watershed code. May contain multiple comma-separated values.
  --p-wbd: string # 2-, 4-, 6-, 8-, 10-, or 12-character watershed (WBD from the USGS Watershed Boundary Dataset). May contain multiple comma-separated values. Uses the FRS Best Pick Coordinate to obtain the WBD12 Huc value.
  --p-pid: string # Nine-digit permit IDs. May contain up to 2000 comma-separated values.
  --p-med: string@p-med-completer # Filter Results by Media. - M = RMP (Risk Management Plan) - R = RCRA (Hazardous Waste) - S = SDWA (Public Drinking Water Systems) - W = Water - ALL = Water and RCRA and SDWA
  --p-ysl: string@p-ysl-completer # Last Facility Inspection [within / not within] Specified Date Range Indicator. The date range is determined by parameters p_idt1 and p_idt2 or by parameter p_ysly. - W = within date range - N = not within date range
  --p-ysly: float@p-ysly-completer # Number of years (1 to 5) since last facility inspection. A value of 1 means that it has been inspected within the year.
  --p-ysla: string@p-ysla-completer # Facility Last Inspection Code Filter. If left blank, both agencies are included. Enter a value to limit results: - E = EPA - S = State
  --p-stsl: string@p-stsl-completer # Last Stack Test [within / not within] Specified Date Range Indicator. - W = within date range - N = not within date range
  --p-stsly: float@p-stsly-completer # Number of years (1 to 5) since date of last stack test. A value of 1 means it has been inspected within the year.
  --p-stsla: string@p-stsla-completer # Stack Last Test Code Filter. Enter a value to limit results: - A = All - E = EPA - S = State
  --p-stres: string # Air Stack Test Status Description Filter. Enter one or more test status descriptions to filter results. Enter multiple values as a comma-delimited list.
  --p-sttyp: string # Air Conductor Type Code Filter. Enter one or more conductor type codes to filter results. Provide multiple values as a comma-delimited list.
  --p-qs: string # Quick Search. Allows entry for city, state, and/or zip code.
  --p-sfs: string # Single Facility Search Filter. Provide a facility name or program system identifier to limit results. For the all data search, the FRS registry identifier is also searched.
  --p-tribeid: float # Numeric code for tribe (or list of tribes).
  --p-tribename: string # Tribe Name Filter. Enter a single tribe name to filter results.
  --p-tribedist: float # Proximity to tribal land limiter. Enter an amount of mile between 0 and 25 to filter results. This parameter is only evaluated if p_tribeid is populated.
  --p-owop: string # Owner/Operator code filter. Enter one or more codes to limit results. - CNG - COR - CTG - DIS - FDF - MWD - MXO - NON - POF - SDT - STF - TRB
  --p-agoo: string@p-agoo-completer # Indicates whether to AND or OR the Owner/Operator parameter (p_owop) and the federal agency code (p_fa) parameters.
  --p-idt1: string # Beginning of date range of most recent facility inspection.
  --p-idt2: string # End of date range of most recent facility inspection.
  --p-stdt1: string # Beginning of date range of most recent stack test.
  --p-stdt2: string # End of date range of most recent stack test.
  --p-pityp: string # Inspection Type: - CAC = Corrective Action Inspection - CAV = Compliance Assistance Visit - CDI = Case Development Inspection - CEI = Inspection Inspection - CSE = Compliance Schedule Evaluation - FCI = Focused Compliance - FRR = Financial Record Review - FSD = Facility Self Disclosure - FUI = Follow-Up Inspection - GME = Groundwater Monitoring Evaluation - NRR = Non-Financial Record Review - OAM = Operation and Maintenance Inspection May contain multiple comma-separated values.
  --p-cifdi: string@p-cifdi-completer # Compliance issuess found during inspection.
  --p-pfead1: string # Formal Enforcement Action Date Range Start. Enter a date in MM/DD/YYYY format to set the start of the range for filtering by recent Formal Enforcement Action (FEA) taken against the facility within the last five years.
  --p-pfead2: string # Formal Enforcement Action Date Range End. Enter a date in MM/DD/YYYY format to set the end of the date range for filtering by recent Formal Enforcement Action (FEA) taken against the facility within the last five years.
  --p-pfeat: string # Formal Enforcement Action (FEA) Code Filter. Enter one or more three-letter FEA codes to restrict results to facilities with these attributes. Use p_fead1 and p_fead2 parameters to further restrict this filter by entering a date range. Provide multiple codes as a comma-delimited list.
  --p-psncq: string@p-psncq-completer # Quarters in Significant Noncompliance Limiter. Enter a coded value to limit results to facilities with given quarter of significant noncompliance. - Z = Zero quarters in significant noncompliance. - GEXX = Replacing XX with a numeric value, that number of quarterd or more in significant noncompliance. - GTXX = Replacing XX with a numeric value, more than that number of quarters in significant noncompliance.
  --p-pctrack: string@p-pctrack-completer # Compliance Tracking Limiter. Provide a keyword to indicate the extent to which data is being entered and effluent exceedances are being identified. - Off - Partial - On
  --p-swpa: string@p-swpa-completer # Source water protection area
  --p-des: string # Universe Designation Limiter. Enter one or more universe designation codes. Provide multiple values as a comma-delimited list. Use code "TSDF" to return the full enforcement TSDF universe and "Operating TSDF" to return the operating TSDF universe.
  --p-fntype: string@p-fntype-completer # Controls type of text search performed on facility name with parameter p_fn. - EXACT = Find facilities having the exact provided name(s). - BEGINS = Find facilities with names starting with the provided term(s). - ALL = Find facilities using Oracle text search terms. - CONTAINS =
  --p-hpvmth: string # Months in high priority violation status out of the previous three years limiter. Provide a number of months in the past three years. Results will limited to facilities in high priority violation status during that time.
  --p-recvio: string # Recent Violation Status Filter. Enter one or more recent violation codes to limit results. Provide multiple values as a comma-delimited list. - NO VIOL = Selects facilities with no recent violations. - ANY HPV = Selects facilities with either addressed or unaddressed high priority violations. - ADDRS-EPA - Select facilities with recent EPA addressed violations. - ADDRS-LOCAL - Select facilities with recent locally addressed violations. - ADDRS-STATE - Select facilities with recent state addressed violations. - UNADDR-EPA - Select facilities with recent EPA unaddressed violations. - UNADDR-LOCAL - Select facilities with recent locally unaddressed violations. - UNADDR-STATE - Select facilities with recent state unaddressed violations. - FRV VIOL = Selects facilities with a recent federally reportable violation without a high priority violation.
  --p-pollvio: string # Air Pollutant Code For A Recent Violation Filter. Provide one or more pollutant codes to select facilities with one or more of the entered pollutant codes for a recent air violation. Provide multiple values as a comma-delimited list.
  --p-ar: string # Associated EPA Air Reports Program Filter. Enter multiple values as a comma-delimited list. Valid values are: - TRI = Toxic Release Inventory. - GHG = Green House Gas Reporter. - EIS = Emission Inventory System. - CAMD = Clean Air Markets Program Reporter.
  --p-tri-yr: string # Toxic Release Inventory Reporting Year Filter. Enter one or more year values to filter results by the TRI reporting year. Provide multiple years as a comma-delimited list.
  --p-pidall: string@p-pidall-completer # Controls whether search is restricted to existing system. Y means the search will match the p_pid parameter against all associated permits (AIR, RCRA, SDWIS, etc).
  --p-fac-ico: string@p-fac-ico-completer # FRS tribal land code flag. Enter "Y" or "N" to include or exclude facilities based on FRS tribal land code.
  --p-icoo: string # Indian country search and/or flag. Enter "Y" to set indian country search conditions to return any results found using p_ico, p_fac_ico or p_fac_icoo. Otherwise only results matching all provided p_ico, p_fac_ico or p_fac_icoo conditions will be returned.
  --p-fac-icos: string # FRS tribal land spatial flag. Enter "Y" or "N" to include or exclude facilities based on FRS tribal land spatial flag.
  --p-ejscreen: string # Enter "Y" to limit facilities to Census block groups where one of more Environmental Justice indexes above 80th percentile.
  --p-limit-addr: string@p-limit-addr-completer # Limit Address Search Flag. Enter Y to restrict facility searches to native data source only.
  --p-lat: float # Latitude location in decimal degrees.
  --p-long: float # Longitude location in decimal degrees.
  --p-radius: float # Spatial Search Radius. Enter a radius up to 100 miles in which to spatially search for facilities.
  --p-decouple: string@p-decouple-completer # Decouple Inspection Code Search Flag. Enter "Y" to search for inspection code types with p_pityp without respect to the date range search provided with p_ysl* parameters.
  --p-ejscreen-over80cnt: string@p-ejscreen-over80cnt-completer # The number of Environmenmt Justice Indicators above the 80th percentile. Valid values are 1 through 11.
  --queryset: float # Query Limiter. Enter a value to limit the number of records returned for each query. Value cannot exceed 70,000.
  --responseset: float # Response Set Limiter. Enter a value to limit the number of records per page. Value cannot exceed 1,000.
  --summarylist: string@summarylist-completer # Summary List Flag. Enter a Y to return a list of summary statistics based on the parameters submitted to the query service.
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
  --qcolumns: string # Used to customize service output. A list of comma-separated column IDs of output objects that will be returned in the service query object or download. Use the metadata service endpoint for a complete list of Ids and definitions.
  --p-pretty-print: float # Optional flag to request GeoJSON formatted results to be pretty printed. Only provide a numeric value when the output needs to be human readable as pretty printing has a performance cost.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/air_rest_services.get_facility_info"
    query: [{name: output, var: output}, {name: p_fn, var: p_fn}, {name: p_sa, var: p_sa}, {name: p_sa1, var: p_sa1}, {name: p_ct, var: p_ct}, {name: p_co, var: p_co}, {name: p_fips, var: p_fips}, {name: p_st, var: p_st}, {name: p_zip, var: p_zip}, {name: p_lcon, var: p_lcon}, {name: p_frs, var: p_frs}, {name: p_reg, var: p_reg}, {name: p_sic, var: p_sic}, {name: p_ncs, var: p_ncs}, {name: p_qnc, var: p_qnc}, {name: p_pen, var: p_pen}, {name: p_opst, var: p_opst}, {name: xmin, var: xmin}, {name: ymin, var: ymin}, {name: xmax, var: xmax}, {name: ymax, var: ymax}, {name: p_usmex, var: p_usmex}, {name: p_sic2, var: p_sic2}, {name: p_sic4, var: p_sic4}, {name: p_fa, var: p_fa}, {name: p_act, var: p_act}, {name: p_maj, var: p_maj}, {name: p_mact, var: p_mact}, {name: p_nsps, var: p_nsps}, {name: p_nspsm, var: p_nspsm}, {name: p_prog, var: p_prog}, {name: p_fea, var: p_fea}, {name: p_feay, var: p_feay}, {name: p_feaa, var: p_feaa}, {name: p_iea, var: p_iea}, {name: p_ieay, var: p_ieay}, {name: p_ieaa, var: p_ieaa}, {name: p_qiv, var: p_qiv}, {name: p_naa, var: p_naa}, {name: p_impw, var: p_impw}, {name: p_trep, var: p_trep}, {name: p_tri_cat, var: p_tri_cat}, {name: p_tri_amt, var: p_tri_amt}, {name: p_tri_any_amt, var: p_tri_any_amt}, {name: p_tri_pol, var: p_tri_pol}, {name: p_ghg_cat, var: p_ghg_cat}, {name: p_ghg_amt, var: p_ghg_amt}, {name: p_ghg_any_amt, var: p_ghg_any_amt}, {name: p_ghg_yr, var: p_ghg_yr}, {name: p_nei_pol, var: p_nei_pol}, {name: p_nei_amt, var: p_nei_amt}, {name: p_nei_any_amt, var: p_nei_any_amt}, {name: p_nei_yr, var: p_nei_yr}, {name: p_nei_cat, var: p_nei_cat}, {name: p_pm, var: p_pm}, {name: p_pd, var: p_pd}, {name: p_ico, var: p_ico}, {name: p_huc, var: p_huc}, {name: p_wbd, var: p_wbd}, {name: p_pid, var: p_pid}, {name: p_med, var: p_med}, {name: p_ysl, var: p_ysl}, {name: p_ysly, var: p_ysly}, {name: p_ysla, var: p_ysla}, {name: p_stsl, var: p_stsl}, {name: p_stsly, var: p_stsly}, {name: p_stsla, var: p_stsla}, {name: p_stres, var: p_stres}, {name: p_sttyp, var: p_sttyp}, {name: p_qs, var: p_qs}, {name: p_sfs, var: p_sfs}, {name: p_tribeid, var: p_tribeid}, {name: p_tribename, var: p_tribename}, {name: p_tribedist, var: p_tribedist}, {name: p_owop, var: p_owop}, {name: p_agoo, var: p_agoo}, {name: p_idt1, var: p_idt1}, {name: p_idt2, var: p_idt2}, {name: p_stdt1, var: p_stdt1}, {name: p_stdt2, var: p_stdt2}, {name: p_pityp, var: p_pityp}, {name: p_cifdi, var: p_cifdi}, {name: p_pfead1, var: p_pfead1}, {name: p_pfead2, var: p_pfead2}, {name: p_pfeat, var: p_pfeat}, {name: p_psncq, var: p_psncq}, {name: p_pctrack, var: p_pctrack}, {name: p_swpa, var: p_swpa}, {name: p_des, var: p_des}, {name: p_fntype, var: p_fntype}, {name: p_hpvmth, var: p_hpvmth}, {name: p_recvio, var: p_recvio}, {name: p_pollvio, var: p_pollvio}, {name: p_ar, var: p_ar}, {name: p_tri_yr, var: p_tri_yr}, {name: p_pidall, var: p_pidall}, {name: p_fac_ico, var: p_fac_ico}, {name: p_icoo, var: p_icoo}, {name: p_fac_icos, var: p_fac_icos}, {name: p_ejscreen, var: p_ejscreen}, {name: p_limit_addr, var: p_limit_addr}, {name: p_lat, var: p_lat}, {name: p_long, var: p_long}, {name: p_radius, var: p_radius}, {name: p_decouple, var: p_decouple}, {name: p_ejscreen_over80cnt, var: p_ejscreen_over80cnt}, {name: queryset, var: queryset}, {name: responseset, var: responseset}, {name: summarylist, var: summarylist}, {name: callback, var: callback}, {name: qcolumns, var: qcolumns}, {name: p_pretty_print, var: p_pretty_print}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_fn: $p_fn, p_sa: $p_sa, p_sa1: $p_sa1, p_ct: $p_ct, p_co: $p_co, p_fips: $p_fips, p_st: $p_st, p_zip: $p_zip, p_lcon: $p_lcon, p_frs: $p_frs, p_reg: $p_reg, p_sic: $p_sic, p_ncs: $p_ncs, p_qnc: $p_qnc, p_pen: $p_pen, p_opst: $p_opst, xmin: $xmin, ymin: $ymin, xmax: $xmax, ymax: $ymax, p_usmex: $p_usmex, p_sic2: $p_sic2, p_sic4: $p_sic4, p_fa: $p_fa, p_act: $p_act, p_maj: $p_maj, p_mact: $p_mact, p_nsps: $p_nsps, p_nspsm: $p_nspsm, p_prog: $p_prog, p_fea: $p_fea, p_feay: $p_feay, p_feaa: $p_feaa, p_iea: $p_iea, p_ieay: $p_ieay, p_ieaa: $p_ieaa, p_qiv: $p_qiv, p_naa: $p_naa, p_impw: $p_impw, p_trep: $p_trep, p_tri_cat: $p_tri_cat, p_tri_amt: $p_tri_amt, p_tri_any_amt: $p_tri_any_amt, p_tri_pol: $p_tri_pol, p_ghg_cat: $p_ghg_cat, p_ghg_amt: $p_ghg_amt, p_ghg_any_amt: $p_ghg_any_amt, p_ghg_yr: $p_ghg_yr, p_nei_pol: $p_nei_pol, p_nei_amt: $p_nei_amt, p_nei_any_amt: $p_nei_any_amt, p_nei_yr: $p_nei_yr, p_nei_cat: $p_nei_cat, p_pm: $p_pm, p_pd: $p_pd, p_ico: $p_ico, p_huc: $p_huc, p_wbd: $p_wbd, p_pid: $p_pid, p_med: $p_med, p_ysl: $p_ysl, p_ysly: $p_ysly, p_ysla: $p_ysla, p_stsl: $p_stsl, p_stsly: $p_stsly, p_stsla: $p_stsla, p_stres: $p_stres, p_sttyp: $p_sttyp, p_qs: $p_qs, p_sfs: $p_sfs, p_tribeid: $p_tribeid, p_tribename: $p_tribename, p_tribedist: $p_tribedist, p_owop: $p_owop, p_agoo: $p_agoo, p_idt1: $p_idt1, p_idt2: $p_idt2, p_stdt1: $p_stdt1, p_stdt2: $p_stdt2, p_pityp: $p_pityp, p_cifdi: $p_cifdi, p_pfead1: $p_pfead1, p_pfead2: $p_pfead2, p_pfeat: $p_pfeat, p_psncq: $p_psncq, p_pctrack: $p_pctrack, p_swpa: $p_swpa, p_des: $p_des, p_fntype: $p_fntype, p_hpvmth: $p_hpvmth, p_recvio: $p_recvio, p_pollvio: $p_pollvio, p_ar: $p_ar, p_tri_yr: $p_tri_yr, p_pidall: $p_pidall, p_fac_ico: $p_fac_ico, p_icoo: $p_icoo, p_fac_icos: $p_fac_icos, p_ejscreen: $p_ejscreen, p_limit_addr: $p_limit_addr, p_lat: $p_lat, p_long: $p_long, p_radius: $p_radius, p_decouple: $p_decouple, p_ejscreen_over80cnt: $p_ejscreen_over80cnt, queryset: $queryset, responseset: $responseset, summarylist: $summarylist, callback: $callback, qcolumns: $qcolumns, p_pretty_print: $p_pretty_print
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Clean Air Act Facility Enhanced Search
#
# POST /air_rest_services.get_facility_info
# Returns: record<Results: record<BadSystemIDs: string, CVRows: string, ClusterOutput: record<ClusterData: list>, ClusterRecords: string, FEARows: string, Facilities: list<record>, INSPRows: string, IconBaseURL: string, IndianCountryRows: string, InfFEARows: string, Message: string, PopUpBaseURL: string, QueryID: string, QueryParameters: list<record>, QueryRows: string, SVRows: string, ServiceBaseURL: string, TotalPenalties: string, V3Rows: string>>
export def "post-air-rest-services-get-facility-info" [
  --base-url(-b): string@base-url-completer # API base URL
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
  --p-lcon: string # Air Program Local Control Region Code Filter. Enter one or more local control region codes to filter results. Provide multiple codes as a comma-delimited list. Codes where they exist are specific by state.
  --p-frs: string # Facility Registry Service ID Filter. Enter a single 12-digit FRS identifier to filter results.
  --p-reg: string@p-reg-completer # EPA Region Filter. Provide a single value of 01 thru 10 to restrict results to a single EPA region.
  --p-sic: string # Standard Industrial Classification (SIC) Code Filter. Enter a single 4-digit SIC Code to filter results. If more complex filtering is required, use p_sic2 and p_sic4.
  --p-ncs: string # North American Industry Classification System Filter. Enter two to six digits to filter results to facilities having matching NAICS codes. Digits less than six will match to all codes beginning with the provided values.
  --p-qnc: float # Number of quarters in non-compliance limiter. Enter an integer value between 1 and 4 to limit results.
  --p-pen: string # Last Penality Date Qualifier Filter. Enter one of the following: - NEVER = No Penalties - ANY = Any Penalty - LEXX = Less than or equal to XX months. Provide a number in place of XX, e.g. "LE5" for a facility with a penalty within previous 5 months. - GTXX = Greater than XX months. Provide a number in place of XX, eg. GT12, for a facility with the last penalty greater than 12 months ago.
  --p-opst: string # Operating status filter. Enter one or more operating status codes to limit results. Provide multiple codes as a comma-delimited list.
  --xmin: float # Minimum longitude value in decimal degrees.
  --ymin: float # Minimum latitude value in decimal degrees.
  --xmax: float # Maximum longitude value in decimal degrees.
  --ymax: float # Maximum latitude value in decimal degrees.
  --p-usmex: string@p-usmex-completer # US-Mexico Border Flag. Enter Y/N to restrict searches to facilities located within 100KM of the border.
  --p-sic2: string # Standard Industrial Classification (SIC) Code Filter Alternate 2. Enter a wild-card search against SIC codes. A final wild-card is always present allowing "22" to match all SIC codes beginning with 22. Use the "%" character within strings to match any SIC values with the pattern. For example, "2%21" matches 2021, 2121, 2221, etc.
  --p-sic4: string # Standard Industrial Classification (SIC) Code Filter Alternate 3. Enter the first 2, 3 or 4 SIC code digits to filter results to facilities having those code prefixes. As this alternative does not utilize an index, p_sic2 will generally be quicker.
  --p-fa: string # Federal Agency. 1 character or 5-character values; may contain multiple comma-separated values. ALL will retrieve all facilities where the federal agency code is not null. Use the Federal Agencies lookup service to obtain a list of values.
  --p-act: string@p-act-completer # Active Permits/Facilities Flag. Provide Y or N to filter results to facilities with active permits.
  --p-maj: string@p-maj-completer # Major Facility Flag. Enter Y to restrict results to Major facilities only.
  --p-mact: string # CAA Maximum Achievable Control Technology (MACT) Subpart codes (alpha ID between 1 and 7 characters) applicable to the facility.
  --p-nsps: string # Air Programl New Source Performance Standards (NSPS) Subpart Code Search. One or more valid Air Program NSPS Program codes cand be passed.
  --p-nspsm: string # Air Programl New Source Performance Standards Minors (NSPSM) Subpart Code Search. One or more valid Air Program NSPSM Subpart codes can be passed.
  --p-prog: string # Air Program Code Filter. Enter one or more Air program codes to filter results. Provide multiple values as a comma-delimited list.
  --p-fea: string@p-fea-completer # Formal Enforcement Actions [within / not within] specified date range indicator. The date range is determined by parameters p_fead1 and p_fead2 or by parameter p_feay. - W = within date range - N = not within date range
  --p-feay: float@p-feay-completer # Years (1 to 5) Range. This value is used to create a date range for Formal Enforcement Actions (FEA). Used along with p_fea (which indicates whether to look within or outside of the date range) to find FEAs within (or not within) the number of years specified.
  --p-feaa: string@p-feaa-completer # Agency associated with Formal Enforcement Actions: - E = EPA - S = State - A = All
  --p-iea: string@p-iea-completer # Informal Enforcement Actions [within / not within] specified date range. The date range is determined by parameters p_iead1 and p_iead2 or by parameter p_ieay. - W = within date range - N = not within date range
  --p-ieay: float@p-ieay-completer # Years (1 to 5) Range. This value is used to create a date range for Informal Enforcement Actions (IEA). Used along with p_iea (which indicates whether to look within or outside of the date range) to find IEAs within (or not within) the number of years specified.
  --p-ieaa: string@p-ieaa-completer # Agency associated with Informal Enforcement Actions. If left blank, both agencies are included. - E = EPA - S = State
  --p-qiv: string@p-qiv-completer # Quarters in Noncompliance Limiter. Enter a coded value to limit results to facilities with given quarter of noncompliance. - Z = Zero quarters in noncompliance. - GEXX = Replacing XX with a numeric value, that number of quarterd or more in noncompliance. - GTXX = Replacing XX with a numeric value, more than that number of quarters in noncompliance.
  --p-naa: string # Non-Attainment Area Flag. Enter a Y or N to filter for or against facilities flagged as non-attainment areas.
  --p-impw: string@p-impw-completer # Discharging into Impaired Waters Flag. Enter Y to limit results to facilities with discharge to waterbodies listed as impaired in the ATTAINS database.
  --p-trep: string@p-trep-completer # Current Toxics Release Inventory (TRI) Reporter Limiter. Enter one of the following codes to limit results. - CURR = Current TRI reporter. - NONCURR = Has reported to TRI in the past but not for the current reporting year.
  --p-tri-cat: string@p-tri-cat-completer # Toxic Release Inventory Released To Air Chemical Identifier Category Filter. Enter the chemical identifier category code to limit results. Note when filtering by TRI chemical identifier categories one may not also filter by specific chemical identifiers via p_tri_pol. You must also specify a release amount using p_tri_amt or p_tri_any_amt. - TOTAL = Total Released to Air - CARC = Total Carcinogens Released to Air - HAP = Total Hazardous Air Pollutants Released to Air
  --p-tri-amt: string@p-tri-amt-completer # Toxic Release Inventory Release Amount Filter. Enter a value in pounds to limit results to facilities releasing this amount or greateer of TRI releases. Valid values are 0, GT0, GT1000, GT5000, GT10000 and GT50000. Note when filtering by TRI release amounts one may only use either p_tri_amt or p_tri_any_amt.
  --p-tri-any-amt: float # Toxic Release Inventory Release Of Any Kind Above Value Filter. Enter a value to limit results to facilities releasing this amount or more of TRI releases. Note when filtering by TRI releases one may only use p_tri_any_amt or p_tri_amt and not both.
  --p-tri-pol: string # Toxic Release Inventory Chemical Identifier Filter. Enter one or more chemical identifier codes to limit results. Note when filtering by specific TRI chemical identifiers one may not also filter by chemical identifier categories via p_tri_cat.
  --p-ghg-cat: string@p-ghg-cat-completer # Green House Gas (GHG) Gas Code Category. Must be used with either a formatted (p_ghg_amt) or custom (p_ghg_any_amt) release amount.
  --p-ghg-amt: string@p-ghg-amt-completer # Green House Gas (GHG) CO2 Equivalent Formatted Release Amount. First 2 characters must contain GT (greater than) followed by a number.
  --p-ghg-any-amt: float # Green House Gas (GHG) C02 Equivalent Custom Amount. The C02E value reported for the provided category, will be greater or equal to the amount provided.
  --p-ghg-yr: string # Green House Gas (GHG) Reporting Year. (2010 through 2015)
  --p-nei-pol: string # National Emissions Inventory (NEI) Pollutant Identifier. When a pollutant identifer is entered a corresponding formatted amount or custom amount must be entered.
  --p-nei-amt: string@p-nei-amt-completer # National Emissions Inventory (NEI) Formatted Pollutant Amount. A formatted value where the 1st two characters must start with GT or LT followed by a number. Identifies facilities that have a NEI Pollutant Emission where the supplied value is > or < the pollutant emission amount.
  --p-nei-any-amt: float # National Emissions Inventory (NEI) Custom Pollutant Amount. Only a number can be entered. Identifies facilities with where the NEI Pollutant Emission Amount is greater than the number entered.
  --p-nei-yr: string # National Emissions Inventory (NEI) year: 2014 or 2011
  --p-nei-cat: string # National Emissions Inventory (NEI) Pollutant Category. When a pollutant category is entered, a corresponding formatted pollutant amount or custom amount must be entered.
  --p-pm: string@p-pm-completer # Percent Minority Population Limiter. Enter a value to restrict results to facilities with a given percentage of minority population within 3-mile radius. - NONE = 0% - GT5 = greater than 5% - GT10 = greater than 10% - GT25 = greater than 25% - GT50 = greater than 50% - GT75 = greater than 75%
  --p-pd: string@p-pd-completer # Population Density Limiter (per sq mile). Enter a value to limit results to facilities located in area of a given population density. - NONE = 0 population density per square mile - GT100 = More than 100 population density per square mile - GT500 = More than 500 population density per square mile - GT1000 = More than 1000 population density per square mile - GT5000 = More than 5000 population density per square mile - GT10000 = More than 10000 population density per square mile - GT20000 = More than 20000 population density per square mile
  --p-ico: string@p-ico-completer # Indian Country Flag. Enter a "Y" or "N" to restrict searches to facilities inside or outside Indian Country.
  --p-huc: string # 2-, 4-, 6-, or 8-character watershed code. May contain multiple comma-separated values.
  --p-wbd: string # 2-, 4-, 6-, 8-, 10-, or 12-character watershed (WBD from the USGS Watershed Boundary Dataset). May contain multiple comma-separated values. Uses the FRS Best Pick Coordinate to obtain the WBD12 Huc value.
  --p-pid: string # Nine-digit permit IDs. May contain up to 2000 comma-separated values.
  --p-med: string@p-med-completer # Filter Results by Media. - M = RMP (Risk Management Plan) - R = RCRA (Hazardous Waste) - S = SDWA (Public Drinking Water Systems) - W = Water - ALL = Water and RCRA and SDWA
  --p-ysl: string@p-ysl-completer # Last Facility Inspection [within / not within] Specified Date Range Indicator. The date range is determined by parameters p_idt1 and p_idt2 or by parameter p_ysly. - W = within date range - N = not within date range
  --p-ysly: float@p-ysly-completer # Number of years (1 to 5) since last facility inspection. A value of 1 means that it has been inspected within the year.
  --p-ysla: string@p-ysla-completer # Facility Last Inspection Code Filter. If left blank, both agencies are included. Enter a value to limit results: - E = EPA - S = State
  --p-stsl: string@p-stsl-completer # Last Stack Test [within / not within] Specified Date Range Indicator. - W = within date range - N = not within date range
  --p-stsly: float@p-stsly-completer # Number of years (1 to 5) since date of last stack test. A value of 1 means it has been inspected within the year.
  --p-stsla: string@p-stsla-completer # Stack Last Test Code Filter. Enter a value to limit results: - A = All - E = EPA - S = State
  --p-stres: string # Air Stack Test Status Description Filter. Enter one or more test status descriptions to filter results. Enter multiple values as a comma-delimited list.
  --p-sttyp: string # Air Conductor Type Code Filter. Enter one or more conductor type codes to filter results. Provide multiple values as a comma-delimited list.
  --p-qs: string # Quick Search. Allows entry for city, state, and/or zip code.
  --p-sfs: string # Single Facility Search Filter. Provide a facility name or program system identifier to limit results. For the all data search, the FRS registry identifier is also searched.
  --p-tribeid: float # Numeric code for tribe (or list of tribes).
  --p-tribename: string # Tribe Name Filter. Enter a single tribe name to filter results.
  --p-tribedist: float # Proximity to tribal land limiter. Enter an amount of mile between 0 and 25 to filter results. This parameter is only evaluated if p_tribeid is populated.
  --p-owop: string # Owner/Operator code filter. Enter one or more codes to limit results. - CNG - COR - CTG - DIS - FDF - MWD - MXO - NON - POF - SDT - STF - TRB
  --p-agoo: string@p-agoo-completer # Indicates whether to AND or OR the Owner/Operator parameter (p_owop) and the federal agency code (p_fa) parameters.
  --p-idt1: string # Beginning of date range of most recent facility inspection.
  --p-idt2: string # End of date range of most recent facility inspection.
  --p-stdt1: string # Beginning of date range of most recent stack test.
  --p-stdt2: string # End of date range of most recent stack test.
  --p-pityp: string # Inspection Type: - CAC = Corrective Action Inspection - CAV = Compliance Assistance Visit - CDI = Case Development Inspection - CEI = Inspection Inspection - CSE = Compliance Schedule Evaluation - FCI = Focused Compliance - FRR = Financial Record Review - FSD = Facility Self Disclosure - FUI = Follow-Up Inspection - GME = Groundwater Monitoring Evaluation - NRR = Non-Financial Record Review - OAM = Operation and Maintenance Inspection May contain multiple comma-separated values.
  --p-cifdi: string@p-cifdi-completer # Compliance issuess found during inspection.
  --p-pfead1: string # Formal Enforcement Action Date Range Start. Enter a date in MM/DD/YYYY format to set the start of the range for filtering by recent Formal Enforcement Action (FEA) taken against the facility within the last five years.
  --p-pfead2: string # Formal Enforcement Action Date Range End. Enter a date in MM/DD/YYYY format to set the end of the date range for filtering by recent Formal Enforcement Action (FEA) taken against the facility within the last five years.
  --p-pfeat: string # Formal Enforcement Action (FEA) Code Filter. Enter one or more three-letter FEA codes to restrict results to facilities with these attributes. Use p_fead1 and p_fead2 parameters to further restrict this filter by entering a date range. Provide multiple codes as a comma-delimited list.
  --p-psncq: string@p-psncq-completer # Quarters in Significant Noncompliance Limiter. Enter a coded value to limit results to facilities with given quarter of significant noncompliance. - Z = Zero quarters in significant noncompliance. - GEXX = Replacing XX with a numeric value, that number of quarterd or more in significant noncompliance. - GTXX = Replacing XX with a numeric value, more than that number of quarters in significant noncompliance.
  --p-pctrack: string@p-pctrack-completer # Compliance Tracking Limiter. Provide a keyword to indicate the extent to which data is being entered and effluent exceedances are being identified. - Off - Partial - On
  --p-swpa: string@p-swpa-completer # Source water protection area
  --p-des: string # Universe Designation Limiter. Enter one or more universe designation codes. Provide multiple values as a comma-delimited list. Use code "TSDF" to return the full enforcement TSDF universe and "Operating TSDF" to return the operating TSDF universe.
  --p-fntype: string@p-fntype-completer # Controls type of text search performed on facility name with parameter p_fn. - EXACT = Find facilities having the exact provided name(s). - BEGINS = Find facilities with names starting with the provided term(s). - ALL = Find facilities using Oracle text search terms. - CONTAINS =
  --p-hpvmth: string # Months in high priority violation status out of the previous three years limiter. Provide a number of months in the past three years. Results will limited to facilities in high priority violation status during that time.
  --p-recvio: string # Recent Violation Status Filter. Enter one or more recent violation codes to limit results. Provide multiple values as a comma-delimited list. - NO VIOL = Selects facilities with no recent violations. - ANY HPV = Selects facilities with either addressed or unaddressed high priority violations. - ADDRS-EPA - Select facilities with recent EPA addressed violations. - ADDRS-LOCAL - Select facilities with recent locally addressed violations. - ADDRS-STATE - Select facilities with recent state addressed violations. - UNADDR-EPA - Select facilities with recent EPA unaddressed violations. - UNADDR-LOCAL - Select facilities with recent locally unaddressed violations. - UNADDR-STATE - Select facilities with recent state unaddressed violations. - FRV VIOL = Selects facilities with a recent federally reportable violation without a high priority violation.
  --p-pollvio: string # Air Pollutant Code For A Recent Violation Filter. Provide one or more pollutant codes to select facilities with one or more of the entered pollutant codes for a recent air violation. Provide multiple values as a comma-delimited list.
  --p-ar: string # Associated EPA Air Reports Program Filter. Enter multiple values as a comma-delimited list. Valid values are: - TRI = Toxic Release Inventory. - GHG = Green House Gas Reporter. - EIS = Emission Inventory System. - CAMD = Clean Air Markets Program Reporter.
  --p-tri-yr: string # Toxic Release Inventory Reporting Year Filter. Enter one or more year values to filter results by the TRI reporting year. Provide multiple years as a comma-delimited list.
  --p-pidall: string@p-pidall-completer # Controls whether search is restricted to existing system. Y means the search will match the p_pid parameter against all associated permits (AIR, RCRA, SDWIS, etc).
  --p-fac-ico: string@p-fac-ico-completer # FRS tribal land code flag. Enter "Y" or "N" to include or exclude facilities based on FRS tribal land code.
  --p-icoo: string # Indian country search and/or flag. Enter "Y" to set indian country search conditions to return any results found using p_ico, p_fac_ico or p_fac_icoo. Otherwise only results matching all provided p_ico, p_fac_ico or p_fac_icoo conditions will be returned.
  --p-fac-icos: string # FRS tribal land spatial flag. Enter "Y" or "N" to include or exclude facilities based on FRS tribal land spatial flag.
  --p-ejscreen: string # Enter "Y" to limit facilities to Census block groups where one of more Environmental Justice indexes above 80th percentile.
  --p-limit-addr: string@p-limit-addr-completer # Limit Address Search Flag. Enter Y to restrict facility searches to native data source only.
  --p-lat: float # Latitude location in decimal degrees.
  --p-long: float # Longitude location in decimal degrees.
  --p-radius: float # Spatial Search Radius. Enter a radius up to 100 miles in which to spatially search for facilities.
  --p-decouple: string@p-decouple-completer # Decouple Inspection Code Search Flag. Enter "Y" to search for inspection code types with p_pityp without respect to the date range search provided with p_ysl* parameters.
  --p-ejscreen-over80cnt: string@p-ejscreen-over80cnt-completer # The number of Environmenmt Justice Indicators above the 80th percentile. Valid values are 1 through 11.
  --queryset: float # Query Limiter. Enter a value to limit the number of records returned for each query. Value cannot exceed 70,000.
  --responseset: float # Response Set Limiter. Enter a value to limit the number of records per page. Value cannot exceed 1,000.
  --summarylist: string@summarylist-completer # Summary List Flag. Enter a Y to return a list of summary statistics based on the parameters submitted to the query service.
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
  --qcolumns: string # Used to customize service output. A list of comma-separated column IDs of output objects that will be returned in the service query object or download. Use the metadata service endpoint for a complete list of Ids and definitions.
  --p-pretty-print: float # Optional flag to request GeoJSON formatted results to be pretty printed. Only provide a numeric value when the output needs to be human readable as pretty printing has a performance cost.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/air_rest_services.get_facility_info"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: p_fn, var: p_fn}, {name: p_sa, var: p_sa}, {name: p_sa1, var: p_sa1}, {name: p_ct, var: p_ct}, {name: p_co, var: p_co}, {name: p_fips, var: p_fips}, {name: p_st, var: p_st}, {name: p_zip, var: p_zip}, {name: p_lcon, var: p_lcon}, {name: p_frs, var: p_frs}, {name: p_reg, var: p_reg}, {name: p_sic, var: p_sic}, {name: p_ncs, var: p_ncs}, {name: p_qnc, var: p_qnc}, {name: p_pen, var: p_pen}, {name: p_opst, var: p_opst}, {name: xmin, var: xmin}, {name: ymin, var: ymin}, {name: xmax, var: xmax}, {name: ymax, var: ymax}, {name: p_usmex, var: p_usmex}, {name: p_sic2, var: p_sic2}, {name: p_sic4, var: p_sic4}, {name: p_fa, var: p_fa}, {name: p_act, var: p_act}, {name: p_maj, var: p_maj}, {name: p_mact, var: p_mact}, {name: p_nsps, var: p_nsps}, {name: p_nspsm, var: p_nspsm}, {name: p_prog, var: p_prog}, {name: p_fea, var: p_fea}, {name: p_feay, var: p_feay}, {name: p_feaa, var: p_feaa}, {name: p_iea, var: p_iea}, {name: p_ieay, var: p_ieay}, {name: p_ieaa, var: p_ieaa}, {name: p_qiv, var: p_qiv}, {name: p_naa, var: p_naa}, {name: p_impw, var: p_impw}, {name: p_trep, var: p_trep}, {name: p_tri_cat, var: p_tri_cat}, {name: p_tri_amt, var: p_tri_amt}, {name: p_tri_any_amt, var: p_tri_any_amt}, {name: p_tri_pol, var: p_tri_pol}, {name: p_ghg_cat, var: p_ghg_cat}, {name: p_ghg_amt, var: p_ghg_amt}, {name: p_ghg_any_amt, var: p_ghg_any_amt}, {name: p_ghg_yr, var: p_ghg_yr}, {name: p_nei_pol, var: p_nei_pol}, {name: p_nei_amt, var: p_nei_amt}, {name: p_nei_any_amt, var: p_nei_any_amt}, {name: p_nei_yr, var: p_nei_yr}, {name: p_nei_cat, var: p_nei_cat}, {name: p_pm, var: p_pm}, {name: p_pd, var: p_pd}, {name: p_ico, var: p_ico}, {name: p_huc, var: p_huc}, {name: p_wbd, var: p_wbd}, {name: p_pid, var: p_pid}, {name: p_med, var: p_med}, {name: p_ysl, var: p_ysl}, {name: p_ysly, var: p_ysly}, {name: p_ysla, var: p_ysla}, {name: p_stsl, var: p_stsl}, {name: p_stsly, var: p_stsly}, {name: p_stsla, var: p_stsla}, {name: p_stres, var: p_stres}, {name: p_sttyp, var: p_sttyp}, {name: p_qs, var: p_qs}, {name: p_sfs, var: p_sfs}, {name: p_tribeid, var: p_tribeid}, {name: p_tribename, var: p_tribename}, {name: p_tribedist, var: p_tribedist}, {name: p_owop, var: p_owop}, {name: p_agoo, var: p_agoo}, {name: p_idt1, var: p_idt1}, {name: p_idt2, var: p_idt2}, {name: p_stdt1, var: p_stdt1}, {name: p_stdt2, var: p_stdt2}, {name: p_pityp, var: p_pityp}, {name: p_cifdi, var: p_cifdi}, {name: p_pfead1, var: p_pfead1}, {name: p_pfead2, var: p_pfead2}, {name: p_pfeat, var: p_pfeat}, {name: p_psncq, var: p_psncq}, {name: p_pctrack, var: p_pctrack}, {name: p_swpa, var: p_swpa}, {name: p_des, var: p_des}, {name: p_fntype, var: p_fntype}, {name: p_hpvmth, var: p_hpvmth}, {name: p_recvio, var: p_recvio}, {name: p_pollvio, var: p_pollvio}, {name: p_ar, var: p_ar}, {name: p_tri_yr, var: p_tri_yr}, {name: p_pidall, var: p_pidall}, {name: p_fac_ico, var: p_fac_ico}, {name: p_icoo, var: p_icoo}, {name: p_fac_icos, var: p_fac_icos}, {name: p_ejscreen, var: p_ejscreen}, {name: p_limit_addr, var: p_limit_addr}, {name: p_lat, var: p_lat}, {name: p_long, var: p_long}, {name: p_radius, var: p_radius}, {name: p_decouple, var: p_decouple}, {name: p_ejscreen_over80cnt, var: p_ejscreen_over80cnt}, {name: queryset, var: queryset}, {name: responseset, var: responseset}, {name: summarylist, var: summarylist}, {name: callback, var: callback}, {name: qcolumns, var: qcolumns}, {name: p_pretty_print, var: p_pretty_print}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_fn: $p_fn, p_sa: $p_sa, p_sa1: $p_sa1, p_ct: $p_ct, p_co: $p_co, p_fips: $p_fips, p_st: $p_st, p_zip: $p_zip, p_lcon: $p_lcon, p_frs: $p_frs, p_reg: $p_reg, p_sic: $p_sic, p_ncs: $p_ncs, p_qnc: $p_qnc, p_pen: $p_pen, p_opst: $p_opst, xmin: $xmin, ymin: $ymin, xmax: $xmax, ymax: $ymax, p_usmex: $p_usmex, p_sic2: $p_sic2, p_sic4: $p_sic4, p_fa: $p_fa, p_act: $p_act, p_maj: $p_maj, p_mact: $p_mact, p_nsps: $p_nsps, p_nspsm: $p_nspsm, p_prog: $p_prog, p_fea: $p_fea, p_feay: $p_feay, p_feaa: $p_feaa, p_iea: $p_iea, p_ieay: $p_ieay, p_ieaa: $p_ieaa, p_qiv: $p_qiv, p_naa: $p_naa, p_impw: $p_impw, p_trep: $p_trep, p_tri_cat: $p_tri_cat, p_tri_amt: $p_tri_amt, p_tri_any_amt: $p_tri_any_amt, p_tri_pol: $p_tri_pol, p_ghg_cat: $p_ghg_cat, p_ghg_amt: $p_ghg_amt, p_ghg_any_amt: $p_ghg_any_amt, p_ghg_yr: $p_ghg_yr, p_nei_pol: $p_nei_pol, p_nei_amt: $p_nei_amt, p_nei_any_amt: $p_nei_any_amt, p_nei_yr: $p_nei_yr, p_nei_cat: $p_nei_cat, p_pm: $p_pm, p_pd: $p_pd, p_ico: $p_ico, p_huc: $p_huc, p_wbd: $p_wbd, p_pid: $p_pid, p_med: $p_med, p_ysl: $p_ysl, p_ysly: $p_ysly, p_ysla: $p_ysla, p_stsl: $p_stsl, p_stsly: $p_stsly, p_stsla: $p_stsla, p_stres: $p_stres, p_sttyp: $p_sttyp, p_qs: $p_qs, p_sfs: $p_sfs, p_tribeid: $p_tribeid, p_tribename: $p_tribename, p_tribedist: $p_tribedist, p_owop: $p_owop, p_agoo: $p_agoo, p_idt1: $p_idt1, p_idt2: $p_idt2, p_stdt1: $p_stdt1, p_stdt2: $p_stdt2, p_pityp: $p_pityp, p_cifdi: $p_cifdi, p_pfead1: $p_pfead1, p_pfead2: $p_pfead2, p_pfeat: $p_pfeat, p_psncq: $p_psncq, p_pctrack: $p_pctrack, p_swpa: $p_swpa, p_des: $p_des, p_fntype: $p_fntype, p_hpvmth: $p_hpvmth, p_recvio: $p_recvio, p_pollvio: $p_pollvio, p_ar: $p_ar, p_tri_yr: $p_tri_yr, p_pidall: $p_pidall, p_fac_ico: $p_fac_ico, p_icoo: $p_icoo, p_fac_icos: $p_fac_icos, p_ejscreen: $p_ejscreen, p_limit_addr: $p_limit_addr, p_lat: $p_lat, p_long: $p_long, p_radius: $p_radius, p_decouple: $p_decouple, p_ejscreen_over80cnt: $p_ejscreen_over80cnt, queryset: $queryset, responseset: $responseset, summarylist: $summarylist, callback: $callback, qcolumns: $qcolumns, p_pretty_print: $p_pretty_print
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Clean Air Act GeoJSON Service
#
# GET /air_rest_services.get_geojson
# Returns: record<features: table<geometry: record, properties: record, type: string>, type: string>
export def "get-air-rest-services-get-geojson" [
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/air_rest_services.get_geojson"
    query: [{name: output, var: output}, {name: qid, var: qid, required: true}, {name: callback, var: callback}, {name: newsort, var: newsort}, {name: descending, var: descending}, {name: qcolumns, var: qcolumns}, {name: p_pretty_print, var: p_pretty_print}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, qid: $qid, callback: $callback, newsort: $newsort, descending: $descending, qcolumns: $qcolumns, p_pretty_print: $p_pretty_print
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Clean Air Act GeoJSON Service
#
# POST /air_rest_services.get_geojson
# Returns: record<features: table<geometry: record, properties: record, type: string>, type: string>
export def "post-air-rest-services-get-geojson" [
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/air_rest_services.get_geojson"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: qid, var: qid}, {name: callback, var: callback}, {name: newsort, var: newsort}, {name: descending, var: descending}, {name: qcolumns, var: qcolumns}, {name: p_pretty_print, var: p_pretty_print}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, qid: $qid, callback: $callback, newsort: $newsort, descending: $descending, qcolumns: $qcolumns, p_pretty_print: $p_pretty_print
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Clean Air Act Info Clusters Service
#
# GET /air_rest_services.get_info_clusters
# Returns: binary
export def "get-air-rest-services-get-info-clusters" [
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/air_rest_services.get_info_clusters"
    query: [{name: output, var: output}, {name: p_qid, var: p_qid, required: true}, {name: p_pretty_print, var: p_pretty_print}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_qid: $p_qid, p_pretty_print: $p_pretty_print
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Clean Air Act Info Clusters Service
#
# POST /air_rest_services.get_info_clusters
# Returns: binary
export def "post-air-rest-services-get-info-clusters" [
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/air_rest_services.get_info_clusters"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: p_qid, var: p_qid}, {name: p_pretty_print, var: p_pretty_print}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, p_qid: $p_qid, p_pretty_print: $p_pretty_print
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Clean Air Act Map Service
#
# GET /air_rest_services.get_map
# Returns: record<MapOutput: record<IconBaseURL: string, MapData: list<record>, PopUpBaseURL: string, QueryID: string>>
export def "get-air-rest-services-get-map" [
  --base-url(-b): string@base-url-completer # API base URL
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
  --p-id: string # Identifier for the service. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/air_rest_services.get_map"
    query: [{name: output, var: output}, {name: qid, var: qid, required: true}, {name: callback, var: callback}, {name: tablelist, var: tablelist}, {name: c1_lat, var: c1_lat}, {name: c1_long, var: c1_long}, {name: c2_lat, var: c2_lat}, {name: c2_long, var: c2_long}, {name: p_id, var: p_id, required: true}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, qid: $qid, callback: $callback, tablelist: $tablelist, c1_lat: $c1_lat, c1_long: $c1_long, c2_lat: $c2_lat, c2_long: $c2_long, p_id: $p_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Clean Air Act Map Service
#
# POST /air_rest_services.get_map
# Returns: record<MapOutput: record<IconBaseURL: string, MapData: list<record>, PopUpBaseURL: string, QueryID: string>>
export def "post-air-rest-services-get-map" [
  --base-url(-b): string@base-url-completer # API base URL
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
  p_id: string # Identifier for the service.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/air_rest_services.get_map"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: qid, var: qid}, {name: callback, var: callback}, {name: tablelist, var: tablelist}, {name: c1_lat, var: c1_lat}, {name: c1_long, var: c1_long}, {name: c2_lat, var: c2_lat}, {name: c2_long, var: c2_long}, {name: p_id, var: p_id}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, qid: $qid, callback: $callback, tablelist: $tablelist, c1_lat: $c1_lat, c1_long: $c1_long, c2_lat: $c2_lat, c2_long: $c2_long, p_id: $p_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Clean Air Act Search by Query ID
#
# GET /air_rest_services.get_qid
# Returns: record<Results: record<Facilities: list<record>, Message: string, PageNo: string, QueryID: string, QueryRows: string>>
export def "get-air-rest-services-get-qid" [
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/air_rest_services.get_qid"
    query: [{name: output, var: output}, {name: qid, var: qid, required: true}, {name: pageno, var: pageno}, {name: callback, var: callback}, {name: newsort, var: newsort}, {name: descending, var: descending}, {name: qcolumns, var: qcolumns}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, qid: $qid, pageno: $pageno, callback: $callback, newsort: $newsort, descending: $descending, qcolumns: $qcolumns
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Clean Air Act Search by Query ID
#
# POST /air_rest_services.get_qid
# Returns: record<Results: record<Facilities: list<record>, Message: string, PageNo: string, QueryID: string, QueryRows: string>>
export def "post-air-rest-services-get-qid" [
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/air_rest_services.get_qid"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: qid, var: qid}, {name: pageno, var: pageno}, {name: callback, var: callback}, {name: newsort, var: newsort}, {name: descending, var: descending}, {name: qcolumns, var: qcolumns}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, qid: $qid, pageno: $pageno, callback: $callback, newsort: $newsort, descending: $descending, qcolumns: $qcolumns
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Clean Air Act Metadata Service
#
# GET /air_rest_services.metadata
# Returns: record<Results: record<Message: string, ResultColumns: list<record>>>
export def "get-air-rest-services-metadata" [
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/air_rest_services.metadata"
    query: [{name: output, var: output}, {name: callback, var: callback}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Clean Air Act Metadata Service
#
# POST /air_rest_services.metadata
# Returns: record<Results: record<Message: string, ResultColumns: list<record>>>
export def "post-air-rest-services-metadata" [
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/air_rest_services.metadata"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: output, var: output}, {name: callback, var: callback}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    output: $output, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}
