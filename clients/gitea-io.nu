# Auto-generated client for Gitea API. v1.20.0+dev-93-g6886706f5
# Source: https://api.apis.guru/v2/specs/gitea.io/1.20.0+dev-93-g6886706f5/openapi.json
# Auth: --token flag or $env.GITEA_API_TOKEN

const CLIENT = {
  base_url: "https://api.apis.guru/api/v1"
  token_env_var: "GITEA_API_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: query-access_token, in: query, header_name: access_token, prefix: ""}
    {name: bearer, in: header, header_name: Authorization, prefix: Bearer}
    {name: basic, in: header, header_name: Authorization, prefix: Basic}
    {name: sudo, in: header, header_name: Sudo, prefix: ""}
    {name: query-sudo, in: query, header_name: sudo, prefix: ""}
    {name: x-gitea-otp, in: header, header_name: X-GITEA-OTP, prefix: ""}
    {name: query-token, in: query, header_name: token, prefix: ""}
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

def base-url-completer [] { ["https://api.apis.guru/api/v1"] }
def auth-scheme-completer [] { ["query-access_token" "bearer" "basic" "sudo" "query-sudo" "x-gitea-otp" "query-token" "basic-credentials"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "text/html"] }
def type-completer [] { ["dingtalk" "discord" "feishu" "gitea" "gogs" "msteams" "packagist" "slack" "telegram" "wechatwork"] }
def visibility-completer [] { ["limited" "private" "public"] }
def trust-model-completer [] { ["collaborator" "collaboratorcommitter" "committer" "default"] }
def permission-completer [] { ["admin" "read" "write"] }
def type-completer-1 [] { ["cargo" "chef" "composer" "conan" "conda" "container" "generic" "helm" "maven" "npm" "nuget" "pub" "pypi" "rubygems" "vagrant"] }
def service-completer [] { ["git" "gitea" "github" "gitlab"] }
def sort-completer [] { ["highestindex" "leastindex" "leastupdate" "oldest" "recentupdate"] }
def state-completer [] { ["error" "failure" "pending" "success" "warning"] }
def diff-type-completer [] { ["diff" "patch"] }
def state-completer-1 [] { ["all" "closed" "open"] }
def type-completer-2 [] { ["issues" "pulls"] }
def state-completer-2 [] { ["closed" "open"] }
def sort-completer-1 [] { ["leastcomment" "leastupdate" "mostcomment" "oldest" "priority" "recentupdate"] }
def whitespace-completer [] { ["ignore-all" "ignore-change" "ignore-eol" "show-all"] }
def do-completer [] { ["manually-merged" "merge" "rebase" "rebase-merge" "squash"] }
def style-completer [] { ["merge" "rebase"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    activitypub-person: "record<\"@context\": string>"
    admin-cron-list: "table<exec_times: int, name: string, next: string, prev: string, schedule: string>"
    admin-list-hooks: "table<active: bool, authorization_header: string, config: record, created_at: string, events: list<string>, id: int, type: string, updated_at: string>"
    admin-create-hook: "record<active: bool, authorization_header: string, config: record, created_at: string, events: list<string>, id: int, type: string, updated_at: string>"
    admin-get-hook: "record<active: bool, authorization_header: string, config: record, created_at: string, events: list<string>, id: int, type: string, updated_at: string>"
    admin-edit-hook: "record<active: bool, authorization_header: string, config: record, created_at: string, events: list<string>, id: int, type: string, updated_at: string>"
    admin-get-all-orgs: "table<avatar_url: string, description: string, full_name: string, id: int, location: string, name: string, repo_admin_change_team_access: bool, username: string, visibility: string, website: string>"
    admin-unadopted-list: "list<string>"
    admin-get-all-users: "table<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>"
    admin-create-user: "record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>"
    admin-edit-user: "record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>"
    admin-create-public-key: "record<created_at: string, fingerprint: string, id: int, key: string, key_type: string, read_only: bool, title: string, url: string, user: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>>"
    admin-create-org: "record<avatar_url: string, description: string, full_name: string, id: int, location: string, name: string, repo_admin_change_team_access: bool, username: string, visibility: string, website: string>"
    admin-create-repo: "record<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record<external_tracker_format: string, external_tracker_regexp_pattern: string, external_tracker_style: string, external_tracker_url: string>, external_wiki: record<external_wiki_url: string>, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record<allow_only_contributors_to_track_time: bool, enable_issue_dependencies: bool, enable_time_tracker: bool>, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, parent: any, permissions: record<admin: bool, pull: bool, push: bool>, private: bool, release_counter: int, repo_transfer: record<doer: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, recipient: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, teams: list<record>>, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>"
    render-markdown: "string"
    render-markdown-raw: "string"
    get-node-info: "record<metadata: record, openRegistrations: bool, protocols: list<string>, services: record<inbound: list<string>, outbound: list<string>>, software: record<homepage: string, name: string, repository: string, version: string>, usage: record<localComments: int, localPosts: int, users: record<activeHalfyear: int, activeMonth: int, total: int>>, version: string>"
    notify-get-list: "table<id: int, pinned: bool, repository: record<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record, external_wiki: record, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record, parent: any, permissions: record, private: bool, release_counter: int, repo_transfer: record, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>, subject: record<html_url: string, latest_comment_html_url: string, latest_comment_url: string, state: string, title: string, type: string, url: string>, unread: bool, updated_at: string, url: string>"
    notify-read-list: "table<id: int, pinned: bool, repository: record<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record, external_wiki: record, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record, parent: any, permissions: record, private: bool, release_counter: int, repo_transfer: record, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>, subject: record<html_url: string, latest_comment_html_url: string, latest_comment_url: string, state: string, title: string, type: string, url: string>, unread: bool, updated_at: string, url: string>"
    notify-new-available: "record<new: int>"
    notify-get-thread: "record<id: int, pinned: bool, repository: record<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record<external_tracker_format: string, external_tracker_regexp_pattern: string, external_tracker_style: string, external_tracker_url: string>, external_wiki: record<external_wiki_url: string>, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record<allow_only_contributors_to_track_time: bool, enable_issue_dependencies: bool, enable_time_tracker: bool>, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, parent: any, permissions: record<admin: bool, pull: bool, push: bool>, private: bool, release_counter: int, repo_transfer: record<doer: record, recipient: record, teams: list>, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>, subject: record<html_url: string, latest_comment_html_url: string, latest_comment_url: string, state: string, title: string, type: string, url: string>, unread: bool, updated_at: string, url: string>"
    notify-read-thread: "record<id: int, pinned: bool, repository: record<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record<external_tracker_format: string, external_tracker_regexp_pattern: string, external_tracker_style: string, external_tracker_url: string>, external_wiki: record<external_wiki_url: string>, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record<allow_only_contributors_to_track_time: bool, enable_issue_dependencies: bool, enable_time_tracker: bool>, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, parent: any, permissions: record<admin: bool, pull: bool, push: bool>, private: bool, release_counter: int, repo_transfer: record<doer: record, recipient: record, teams: list>, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>, subject: record<html_url: string, latest_comment_html_url: string, latest_comment_url: string, state: string, title: string, type: string, url: string>, unread: bool, updated_at: string, url: string>"
    create-org-repo-deprecated: "record<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record<external_tracker_format: string, external_tracker_regexp_pattern: string, external_tracker_style: string, external_tracker_url: string>, external_wiki: record<external_wiki_url: string>, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record<allow_only_contributors_to_track_time: bool, enable_issue_dependencies: bool, enable_time_tracker: bool>, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, parent: any, permissions: record<admin: bool, pull: bool, push: bool>, private: bool, release_counter: int, repo_transfer: record<doer: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, recipient: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, teams: list<record>>, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>"
    org-get-all: "table<avatar_url: string, description: string, full_name: string, id: int, location: string, name: string, repo_admin_change_team_access: bool, username: string, visibility: string, website: string>"
    org-create: "record<avatar_url: string, description: string, full_name: string, id: int, location: string, name: string, repo_admin_change_team_access: bool, username: string, visibility: string, website: string>"
    org-get: "record<avatar_url: string, description: string, full_name: string, id: int, location: string, name: string, repo_admin_change_team_access: bool, username: string, visibility: string, website: string>"
    org-edit: "record<avatar_url: string, description: string, full_name: string, id: int, location: string, name: string, repo_admin_change_team_access: bool, username: string, visibility: string, website: string>"
    org-list-hooks: "table<active: bool, authorization_header: string, config: record, created_at: string, events: list<string>, id: int, type: string, updated_at: string>"
    org-create-hook: "record<active: bool, authorization_header: string, config: record, created_at: string, events: list<string>, id: int, type: string, updated_at: string>"
    org-get-hook: "record<active: bool, authorization_header: string, config: record, created_at: string, events: list<string>, id: int, type: string, updated_at: string>"
    org-edit-hook: "record<active: bool, authorization_header: string, config: record, created_at: string, events: list<string>, id: int, type: string, updated_at: string>"
    org-list-labels: "table<color: string, description: string, exclusive: bool, id: int, name: string, url: string>"
    org-create-label: "record<color: string, description: string, exclusive: bool, id: int, name: string, url: string>"
    org-get-label: "record<color: string, description: string, exclusive: bool, id: int, name: string, url: string>"
    org-edit-label: "record<color: string, description: string, exclusive: bool, id: int, name: string, url: string>"
    org-list-members: "table<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>"
    org-list-public-members: "table<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>"
    org-list-repos: "table<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record<external_tracker_format: string, external_tracker_regexp_pattern: string, external_tracker_style: string, external_tracker_url: string>, external_wiki: record<external_wiki_url: string>, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record<allow_only_contributors_to_track_time: bool, enable_issue_dependencies: bool, enable_time_tracker: bool>, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, parent: any, permissions: record<admin: bool, pull: bool, push: bool>, private: bool, release_counter: int, repo_transfer: record<doer: record, recipient: record, teams: list>, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>"
    create-org-repo: "record<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record<external_tracker_format: string, external_tracker_regexp_pattern: string, external_tracker_style: string, external_tracker_url: string>, external_wiki: record<external_wiki_url: string>, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record<allow_only_contributors_to_track_time: bool, enable_issue_dependencies: bool, enable_time_tracker: bool>, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, parent: any, permissions: record<admin: bool, pull: bool, push: bool>, private: bool, release_counter: int, repo_transfer: record<doer: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, recipient: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, teams: list<record>>, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>"
    org-list-teams: "table<can_create_org_repo: bool, description: string, id: int, includes_all_repositories: bool, name: string, organization: record<avatar_url: string, description: string, full_name: string, id: int, location: string, name: string, repo_admin_change_team_access: bool, username: string, visibility: string, website: string>, permission: string, units: list<string>, units_map: record>"
    org-create-team: "record<can_create_org_repo: bool, description: string, id: int, includes_all_repositories: bool, name: string, organization: record<avatar_url: string, description: string, full_name: string, id: int, location: string, name: string, repo_admin_change_team_access: bool, username: string, visibility: string, website: string>, permission: string, units: list<string>, units_map: record>"
    team-search: "record<data: table<can_create_org_repo: bool, description: string, id: int, includes_all_repositories: bool, name: string, organization: record, permission: string, units: list, units_map: record>, ok: bool>"
    list-packages: "table<created_at: string, creator: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, id: int, name: string, owner: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, repository: record<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record, external_wiki: record, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record, parent: any, permissions: record, private: bool, release_counter: int, repo_transfer: record, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>, type: string, version: string>"
    get-package: "record<created_at: string, creator: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, id: int, name: string, owner: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, repository: record<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record<external_tracker_format: string, external_tracker_regexp_pattern: string, external_tracker_style: string, external_tracker_url: string>, external_wiki: record<external_wiki_url: string>, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record<allow_only_contributors_to_track_time: bool, enable_issue_dependencies: bool, enable_time_tracker: bool>, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, parent: any, permissions: record<admin: bool, pull: bool, push: bool>, private: bool, release_counter: int, repo_transfer: record<doer: record, recipient: record, teams: list>, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>, type: string, version: string>"
    list-package-files: "table<Size: int, id: int, md5: string, name: string, sha1: string, sha256: string, sha512: string>"
    issue-search-issues: "table<assets: list<record>, assignee: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, assignees: list<record>, body: string, closed_at: string, comments: int, created_at: string, due_date: string, html_url: string, id: int, is_locked: bool, labels: list<record>, milestone: record<closed_at: string, closed_issues: int, created_at: string, description: string, due_on: string, id: int, open_issues: int, state: string, title: string, updated_at: string>, number: int, original_author: string, original_author_id: int, pull_request: record<merged: bool, merged_at: string>, ref: string, repository: record<full_name: string, id: int, name: string, owner: string>, state: string, title: string, updated_at: string, url: string, user: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>>"
    repo-migrate: "record<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record<external_tracker_format: string, external_tracker_regexp_pattern: string, external_tracker_style: string, external_tracker_url: string>, external_wiki: record<external_wiki_url: string>, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record<allow_only_contributors_to_track_time: bool, enable_issue_dependencies: bool, enable_time_tracker: bool>, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, parent: any, permissions: record<admin: bool, pull: bool, push: bool>, private: bool, release_counter: int, repo_transfer: record<doer: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, recipient: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, teams: list<record>>, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>"
    repo-search: "record<data: table<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record, external_wiki: record, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record, parent: any, permissions: record, private: bool, release_counter: int, repo_transfer: record, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>, ok: bool>"
    repo-get: "record<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record<external_tracker_format: string, external_tracker_regexp_pattern: string, external_tracker_style: string, external_tracker_url: string>, external_wiki: record<external_wiki_url: string>, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record<allow_only_contributors_to_track_time: bool, enable_issue_dependencies: bool, enable_time_tracker: bool>, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, parent: any, permissions: record<admin: bool, pull: bool, push: bool>, private: bool, release_counter: int, repo_transfer: record<doer: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, recipient: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, teams: list<record>>, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>"
    repo-edit: "record<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record<external_tracker_format: string, external_tracker_regexp_pattern: string, external_tracker_style: string, external_tracker_url: string>, external_wiki: record<external_wiki_url: string>, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record<allow_only_contributors_to_track_time: bool, enable_issue_dependencies: bool, enable_time_tracker: bool>, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, parent: any, permissions: record<admin: bool, pull: bool, push: bool>, private: bool, release_counter: int, repo_transfer: record<doer: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, recipient: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, teams: list<record>>, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>"
    repo-get-assignees: "table<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>"
    repo-list-branch-protection: "table<approvals_whitelist_teams: list<string>, approvals_whitelist_username: list<string>, block_on_official_review_requests: bool, block_on_outdated_branch: bool, block_on_rejected_reviews: bool, branch_name: string, created_at: string, dismiss_stale_approvals: bool, enable_approvals_whitelist: bool, enable_merge_whitelist: bool, enable_push: bool, enable_push_whitelist: bool, enable_status_check: bool, merge_whitelist_teams: list<string>, merge_whitelist_usernames: list<string>, protected_file_patterns: string, push_whitelist_deploy_keys: bool, push_whitelist_teams: list<string>, push_whitelist_usernames: list<string>, require_signed_commits: bool, required_approvals: int, rule_name: string, status_check_contexts: list<string>, unprotected_file_patterns: string, updated_at: string>"
    repo-create-branch-protection: "record<approvals_whitelist_teams: list<string>, approvals_whitelist_username: list<string>, block_on_official_review_requests: bool, block_on_outdated_branch: bool, block_on_rejected_reviews: bool, branch_name: string, created_at: string, dismiss_stale_approvals: bool, enable_approvals_whitelist: bool, enable_merge_whitelist: bool, enable_push: bool, enable_push_whitelist: bool, enable_status_check: bool, merge_whitelist_teams: list<string>, merge_whitelist_usernames: list<string>, protected_file_patterns: string, push_whitelist_deploy_keys: bool, push_whitelist_teams: list<string>, push_whitelist_usernames: list<string>, require_signed_commits: bool, required_approvals: int, rule_name: string, status_check_contexts: list<string>, unprotected_file_patterns: string, updated_at: string>"
    repo-get-branch-protection: "record<approvals_whitelist_teams: list<string>, approvals_whitelist_username: list<string>, block_on_official_review_requests: bool, block_on_outdated_branch: bool, block_on_rejected_reviews: bool, branch_name: string, created_at: string, dismiss_stale_approvals: bool, enable_approvals_whitelist: bool, enable_merge_whitelist: bool, enable_push: bool, enable_push_whitelist: bool, enable_status_check: bool, merge_whitelist_teams: list<string>, merge_whitelist_usernames: list<string>, protected_file_patterns: string, push_whitelist_deploy_keys: bool, push_whitelist_teams: list<string>, push_whitelist_usernames: list<string>, require_signed_commits: bool, required_approvals: int, rule_name: string, status_check_contexts: list<string>, unprotected_file_patterns: string, updated_at: string>"
    repo-edit-branch-protection: "record<approvals_whitelist_teams: list<string>, approvals_whitelist_username: list<string>, block_on_official_review_requests: bool, block_on_outdated_branch: bool, block_on_rejected_reviews: bool, branch_name: string, created_at: string, dismiss_stale_approvals: bool, enable_approvals_whitelist: bool, enable_merge_whitelist: bool, enable_push: bool, enable_push_whitelist: bool, enable_status_check: bool, merge_whitelist_teams: list<string>, merge_whitelist_usernames: list<string>, protected_file_patterns: string, push_whitelist_deploy_keys: bool, push_whitelist_teams: list<string>, push_whitelist_usernames: list<string>, require_signed_commits: bool, required_approvals: int, rule_name: string, status_check_contexts: list<string>, unprotected_file_patterns: string, updated_at: string>"
    repo-list-branches: "table<commit: record<added: list, author: record, committer: record, id: string, message: string, modified: list, removed: list, timestamp: string, url: string, verification: record>, effective_branch_protection_name: string, enable_status_check: bool, name: string, protected: bool, required_approvals: int, status_check_contexts: list<string>, user_can_merge: bool, user_can_push: bool>"
    repo-create-branch: "record<commit: record<added: list<string>, author: record<email: string, name: string, username: string>, committer: record<email: string, name: string, username: string>, id: string, message: string, modified: list<string>, removed: list<string>, timestamp: string, url: string, verification: record<payload: string, reason: string, signature: string, signer: record, verified: bool>>, effective_branch_protection_name: string, enable_status_check: bool, name: string, protected: bool, required_approvals: int, status_check_contexts: list<string>, user_can_merge: bool, user_can_push: bool>"
    repo-get-branch: "record<commit: record<added: list<string>, author: record<email: string, name: string, username: string>, committer: record<email: string, name: string, username: string>, id: string, message: string, modified: list<string>, removed: list<string>, timestamp: string, url: string, verification: record<payload: string, reason: string, signature: string, signer: record, verified: bool>>, effective_branch_protection_name: string, enable_status_check: bool, name: string, protected: bool, required_approvals: int, status_check_contexts: list<string>, user_can_merge: bool, user_can_push: bool>"
    repo-list-collaborators: "table<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>"
    repo-get-repo-permissions: "record<permission: string, role_name: string, user: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>>"
    repo-get-all-commits: "table<author: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, commit: record<author: record, committer: record, message: string, tree: record, url: string, verification: record>, committer: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, created: string, files: list<record>, html_url: string, parents: list<record>, sha: string, stats: record<additions: int, deletions: int, total: int>, url: string>"
    repo-get-combined-status-by-ref: "record<commit_url: string, repository: record<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record<external_tracker_format: string, external_tracker_regexp_pattern: string, external_tracker_style: string, external_tracker_url: string>, external_wiki: record<external_wiki_url: string>, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record<allow_only_contributors_to_track_time: bool, enable_issue_dependencies: bool, enable_time_tracker: bool>, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, parent: any, permissions: record<admin: bool, pull: bool, push: bool>, private: bool, release_counter: int, repo_transfer: record<doer: record, recipient: record, teams: list>, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>, sha: string, state: string, statuses: table<context: string, created_at: string, creator: record, description: string, id: int, status: string, target_url: string, updated_at: string, url: string>, total_count: int, url: string>"
    repo-list-statuses-by-ref: "table<context: string, created_at: string, creator: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, description: string, id: int, status: string, target_url: string, updated_at: string, url: string>"
    repo-get-contents-list: "table<_links: record<git: string, html: string, self: string>, content: string, download_url: string, encoding: string, git_url: string, html_url: string, last_commit_sha: string, name: string, path: string, sha: string, size: int, submodule_git_url: string, target: string, type: string, url: string>"
    repo-delete-file: "record<commit: record<author: record<date: string, email: string, name: string>, committer: record<date: string, email: string, name: string>, created: string, html_url: string, message: string, parents: list<record>, sha: string, tree: record<created: string, sha: string, url: string>, url: string>, content: any, verification: record<payload: string, reason: string, signature: string, signer: record<email: string, name: string, username: string>, verified: bool>>"
    repo-get-contents: "record<_links: record<git: string, html: string, self: string>, content: string, download_url: string, encoding: string, git_url: string, html_url: string, last_commit_sha: string, name: string, path: string, sha: string, size: int, submodule_git_url: string, target: string, type: string, url: string>"
    repo-create-file: "record<commit: record<author: record<date: string, email: string, name: string>, committer: record<date: string, email: string, name: string>, created: string, html_url: string, message: string, parents: list<record>, sha: string, tree: record<created: string, sha: string, url: string>, url: string>, content: record<_links: record<git: string, html: string, self: string>, content: string, download_url: string, encoding: string, git_url: string, html_url: string, last_commit_sha: string, name: string, path: string, sha: string, size: int, submodule_git_url: string, target: string, type: string, url: string>, verification: record<payload: string, reason: string, signature: string, signer: record<email: string, name: string, username: string>, verified: bool>>"
    repo-update-file: "record<commit: record<author: record<date: string, email: string, name: string>, committer: record<date: string, email: string, name: string>, created: string, html_url: string, message: string, parents: list<record>, sha: string, tree: record<created: string, sha: string, url: string>, url: string>, content: record<_links: record<git: string, html: string, self: string>, content: string, download_url: string, encoding: string, git_url: string, html_url: string, last_commit_sha: string, name: string, path: string, sha: string, size: int, submodule_git_url: string, target: string, type: string, url: string>, verification: record<payload: string, reason: string, signature: string, signer: record<email: string, name: string, username: string>, verified: bool>>"
    repo-apply-diff-patch: "record<commit: record<author: record<date: string, email: string, name: string>, committer: record<date: string, email: string, name: string>, created: string, html_url: string, message: string, parents: list<record>, sha: string, tree: record<created: string, sha: string, url: string>, url: string>, content: record<_links: record<git: string, html: string, self: string>, content: string, download_url: string, encoding: string, git_url: string, html_url: string, last_commit_sha: string, name: string, path: string, sha: string, size: int, submodule_git_url: string, target: string, type: string, url: string>, verification: record<payload: string, reason: string, signature: string, signer: record<email: string, name: string, username: string>, verified: bool>>"
    list-forks: "table<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record<external_tracker_format: string, external_tracker_regexp_pattern: string, external_tracker_style: string, external_tracker_url: string>, external_wiki: record<external_wiki_url: string>, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record<allow_only_contributors_to_track_time: bool, enable_issue_dependencies: bool, enable_time_tracker: bool>, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, parent: any, permissions: record<admin: bool, pull: bool, push: bool>, private: bool, release_counter: int, repo_transfer: record<doer: record, recipient: record, teams: list>, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>"
    create-fork: "record<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record<external_tracker_format: string, external_tracker_regexp_pattern: string, external_tracker_style: string, external_tracker_url: string>, external_wiki: record<external_wiki_url: string>, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record<allow_only_contributors_to_track_time: bool, enable_issue_dependencies: bool, enable_time_tracker: bool>, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, parent: any, permissions: record<admin: bool, pull: bool, push: bool>, private: bool, release_counter: int, repo_transfer: record<doer: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, recipient: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, teams: list<record>>, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>"
    get-blob: "record<content: string, encoding: string, sha: string, size: int, url: string>"
    repo-get-single-commit: "record<author: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, commit: record<author: record<date: string, email: string, name: string>, committer: record<date: string, email: string, name: string>, message: string, tree: record<created: string, sha: string, url: string>, url: string, verification: record<payload: string, reason: string, signature: string, signer: record, verified: bool>>, committer: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, created: string, files: table<filename: string>, html_url: string, parents: table<created: string, sha: string, url: string>, sha: string, stats: record<additions: int, deletions: int, total: int>, url: string>"
    repo-download-commit-diff-or-patch: "string"
    repo-get-note: "record<commit: record<author: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, commit: record<author: record, committer: record, message: string, tree: record, url: string, verification: record>, committer: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, created: string, files: list<record>, html_url: string, parents: list<record>, sha: string, stats: record<additions: int, deletions: int, total: int>, url: string>, message: string>"
    repo-list-all-git-refs: "table<object: record<sha: string, type: string, url: string>, ref: string, url: string>"
    repo-list-git-refs: "table<object: record<sha: string, type: string, url: string>, ref: string, url: string>"
    get-annotated-tag: "record<message: string, object: record<sha: string, type: string, url: string>, sha: string, tag: string, tagger: record<date: string, email: string, name: string>, url: string, verification: record<payload: string, reason: string, signature: string, signer: record<email: string, name: string, username: string>, verified: bool>>"
    get-tree: "record<page: int, sha: string, total_count: int, tree: table<mode: string, path: string, sha: string, size: int, type: string, url: string>, truncated: bool, url: string>"
    repo-list-hooks: "table<active: bool, authorization_header: string, config: record, created_at: string, events: list<string>, id: int, type: string, updated_at: string>"
    repo-create-hook: "record<active: bool, authorization_header: string, config: record, created_at: string, events: list<string>, id: int, type: string, updated_at: string>"
    repo-list-git-hooks: "table<content: string, is_active: bool, name: string>"
    repo-get-git-hook: "record<content: string, is_active: bool, name: string>"
    repo-edit-git-hook: "record<content: string, is_active: bool, name: string>"
    repo-get-hook: "record<active: bool, authorization_header: string, config: record, created_at: string, events: list<string>, id: int, type: string, updated_at: string>"
    repo-edit-hook: "record<active: bool, authorization_header: string, config: record, created_at: string, events: list<string>, id: int, type: string, updated_at: string>"
    repo-get-issue-templates: "table<about: string, body: list<record>, content: string, file_name: string, labels: list<string>, name: string, ref: string, title: string>"
    issue-list-issues: "table<assets: list<record>, assignee: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, assignees: list<record>, body: string, closed_at: string, comments: int, created_at: string, due_date: string, html_url: string, id: int, is_locked: bool, labels: list<record>, milestone: record<closed_at: string, closed_issues: int, created_at: string, description: string, due_on: string, id: int, open_issues: int, state: string, title: string, updated_at: string>, number: int, original_author: string, original_author_id: int, pull_request: record<merged: bool, merged_at: string>, ref: string, repository: record<full_name: string, id: int, name: string, owner: string>, state: string, title: string, updated_at: string, url: string, user: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>>"
    issue-create-issue: "record<assets: table<browser_download_url: string, created_at: string, download_count: int, id: int, name: string, size: int, uuid: string>, assignee: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, assignees: table<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, body: string, closed_at: string, comments: int, created_at: string, due_date: string, html_url: string, id: int, is_locked: bool, labels: table<color: string, description: string, exclusive: bool, id: int, name: string, url: string>, milestone: record<closed_at: string, closed_issues: int, created_at: string, description: string, due_on: string, id: int, open_issues: int, state: string, title: string, updated_at: string>, number: int, original_author: string, original_author_id: int, pull_request: record<merged: bool, merged_at: string>, ref: string, repository: record<full_name: string, id: int, name: string, owner: string>, state: string, title: string, updated_at: string, url: string, user: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>>"
    issue-get-repo-comments: "table<assets: list<record>, body: string, created_at: string, html_url: string, id: int, issue_url: string, original_author: string, original_author_id: int, pull_request_url: string, updated_at: string, user: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>>"
    issue-get-comment: "record<assets: table<browser_download_url: string, created_at: string, download_count: int, id: int, name: string, size: int, uuid: string>, body: string, created_at: string, html_url: string, id: int, issue_url: string, original_author: string, original_author_id: int, pull_request_url: string, updated_at: string, user: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>>"
    issue-edit-comment: "record<assets: table<browser_download_url: string, created_at: string, download_count: int, id: int, name: string, size: int, uuid: string>, body: string, created_at: string, html_url: string, id: int, issue_url: string, original_author: string, original_author_id: int, pull_request_url: string, updated_at: string, user: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>>"
    issue-list-issue-comment-attachments: "table<browser_download_url: string, created_at: string, download_count: int, id: int, name: string, size: int, uuid: string>"
    issue-create-issue-comment-attachment: "record<browser_download_url: string, created_at: string, download_count: int, id: int, name: string, size: int, uuid: string>"
    issue-get-issue-comment-attachment: "record<browser_download_url: string, created_at: string, download_count: int, id: int, name: string, size: int, uuid: string>"
    issue-edit-issue-comment-attachment: "record<browser_download_url: string, created_at: string, download_count: int, id: int, name: string, size: int, uuid: string>"
    issue-get-comment-reactions: "table<content: string, created_at: string, user: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>>"
    issue-post-comment-reaction: "record<content: string, created_at: string, user: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>>"
    issue-get-issue: "record<assets: table<browser_download_url: string, created_at: string, download_count: int, id: int, name: string, size: int, uuid: string>, assignee: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, assignees: table<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, body: string, closed_at: string, comments: int, created_at: string, due_date: string, html_url: string, id: int, is_locked: bool, labels: table<color: string, description: string, exclusive: bool, id: int, name: string, url: string>, milestone: record<closed_at: string, closed_issues: int, created_at: string, description: string, due_on: string, id: int, open_issues: int, state: string, title: string, updated_at: string>, number: int, original_author: string, original_author_id: int, pull_request: record<merged: bool, merged_at: string>, ref: string, repository: record<full_name: string, id: int, name: string, owner: string>, state: string, title: string, updated_at: string, url: string, user: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>>"
    issue-edit-issue: "record<assets: table<browser_download_url: string, created_at: string, download_count: int, id: int, name: string, size: int, uuid: string>, assignee: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, assignees: table<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, body: string, closed_at: string, comments: int, created_at: string, due_date: string, html_url: string, id: int, is_locked: bool, labels: table<color: string, description: string, exclusive: bool, id: int, name: string, url: string>, milestone: record<closed_at: string, closed_issues: int, created_at: string, description: string, due_on: string, id: int, open_issues: int, state: string, title: string, updated_at: string>, number: int, original_author: string, original_author_id: int, pull_request: record<merged: bool, merged_at: string>, ref: string, repository: record<full_name: string, id: int, name: string, owner: string>, state: string, title: string, updated_at: string, url: string, user: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>>"
    issue-list-issue-attachments: "table<browser_download_url: string, created_at: string, download_count: int, id: int, name: string, size: int, uuid: string>"
    issue-create-issue-attachment: "record<browser_download_url: string, created_at: string, download_count: int, id: int, name: string, size: int, uuid: string>"
    issue-get-issue-attachment: "record<browser_download_url: string, created_at: string, download_count: int, id: int, name: string, size: int, uuid: string>"
    issue-edit-issue-attachment: "record<browser_download_url: string, created_at: string, download_count: int, id: int, name: string, size: int, uuid: string>"
    issue-get-comments: "table<assets: list<record>, body: string, created_at: string, html_url: string, id: int, issue_url: string, original_author: string, original_author_id: int, pull_request_url: string, updated_at: string, user: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>>"
    issue-create-comment: "record<assets: table<browser_download_url: string, created_at: string, download_count: int, id: int, name: string, size: int, uuid: string>, body: string, created_at: string, html_url: string, id: int, issue_url: string, original_author: string, original_author_id: int, pull_request_url: string, updated_at: string, user: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>>"
    issue-edit-comment-deprecated: "record<assets: table<browser_download_url: string, created_at: string, download_count: int, id: int, name: string, size: int, uuid: string>, body: string, created_at: string, html_url: string, id: int, issue_url: string, original_author: string, original_author_id: int, pull_request_url: string, updated_at: string, user: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>>"
    issue-edit-issue-deadline: "record<due_date: string>"
    issue-get-labels: "table<color: string, description: string, exclusive: bool, id: int, name: string, url: string>"
    issue-add-label: "table<color: string, description: string, exclusive: bool, id: int, name: string, url: string>"
    issue-replace-labels: "table<color: string, description: string, exclusive: bool, id: int, name: string, url: string>"
    issue-get-issue-reactions: "table<content: string, created_at: string, user: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>>"
    issue-post-issue-reaction: "record<content: string, created_at: string, user: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>>"
    issue-subscriptions: "table<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>"
    issue-check-subscription: "record<created_at: string, ignored: bool, reason: any, repository_url: string, subscribed: bool, url: string>"
    issue-get-comments-and-timeline: "table<assignee: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, assignee_team: record<can_create_org_repo: bool, description: string, id: int, includes_all_repositories: bool, name: string, organization: record, permission: string, units: list, units_map: record>, body: string, created_at: string, dependent_issue: record<assets: list, assignee: record, assignees: list, body: string, closed_at: string, comments: int, created_at: string, due_date: string, html_url: string, id: int, is_locked: bool, labels: list, milestone: record, number: int, original_author: string, original_author_id: int, pull_request: record, ref: string, repository: record, state: string, title: string, updated_at: string, url: string, user: record>, html_url: string, id: int, issue_url: string, label: record<color: string, description: string, exclusive: bool, id: int, name: string, url: string>, milestone: record<closed_at: string, closed_issues: int, created_at: string, description: string, due_on: string, id: int, open_issues: int, state: string, title: string, updated_at: string>, new_ref: string, new_title: string, old_milestone: record<closed_at: string, closed_issues: int, created_at: string, description: string, due_on: string, id: int, open_issues: int, state: string, title: string, updated_at: string>, old_project_id: int, old_ref: string, old_title: string, project_id: int, pull_request_url: string, ref_action: string, ref_comment: record<assets: list, body: string, created_at: string, html_url: string, id: int, issue_url: string, original_author: string, original_author_id: int, pull_request_url: string, updated_at: string, user: record>, ref_commit_sha: string, ref_issue: record<assets: list, assignee: record, assignees: list, body: string, closed_at: string, comments: int, created_at: string, due_date: string, html_url: string, id: int, is_locked: bool, labels: list, milestone: record, number: int, original_author: string, original_author_id: int, pull_request: record, ref: string, repository: record, state: string, title: string, updated_at: string, url: string, user: record>, removed_assignee: bool, resolve_doer: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, review_id: int, tracked_time: record<created: string, id: int, issue: record, issue_id: int, time: int, user_id: int, user_name: string>, type: string, updated_at: string, user: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>>"
    issue-tracked-times: "table<created: string, id: int, issue: record<assets: list, assignee: record, assignees: list, body: string, closed_at: string, comments: int, created_at: string, due_date: string, html_url: string, id: int, is_locked: bool, labels: list, milestone: record, number: int, original_author: string, original_author_id: int, pull_request: record, ref: string, repository: record, state: string, title: string, updated_at: string, url: string, user: record>, issue_id: int, time: int, user_id: int, user_name: string>"
    issue-add-time: "record<created: string, id: int, issue: record<assets: list<record>, assignee: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, assignees: list<record>, body: string, closed_at: string, comments: int, created_at: string, due_date: string, html_url: string, id: int, is_locked: bool, labels: list<record>, milestone: record<closed_at: string, closed_issues: int, created_at: string, description: string, due_on: string, id: int, open_issues: int, state: string, title: string, updated_at: string>, number: int, original_author: string, original_author_id: int, pull_request: record<merged: bool, merged_at: string>, ref: string, repository: record<full_name: string, id: int, name: string, owner: string>, state: string, title: string, updated_at: string, url: string, user: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>>, issue_id: int, time: int, user_id: int, user_name: string>"
    repo-list-keys: "table<created_at: string, fingerprint: string, id: int, key: string, key_id: int, read_only: bool, repository: record<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record, external_wiki: record, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record, parent: any, permissions: record, private: bool, release_counter: int, repo_transfer: record, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>, title: string, url: string>"
    repo-create-key: "record<created_at: string, fingerprint: string, id: int, key: string, key_id: int, read_only: bool, repository: record<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record<external_tracker_format: string, external_tracker_regexp_pattern: string, external_tracker_style: string, external_tracker_url: string>, external_wiki: record<external_wiki_url: string>, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record<allow_only_contributors_to_track_time: bool, enable_issue_dependencies: bool, enable_time_tracker: bool>, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, parent: any, permissions: record<admin: bool, pull: bool, push: bool>, private: bool, release_counter: int, repo_transfer: record<doer: record, recipient: record, teams: list>, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>, title: string, url: string>"
    repo-get-key: "record<created_at: string, fingerprint: string, id: int, key: string, key_id: int, read_only: bool, repository: record<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record<external_tracker_format: string, external_tracker_regexp_pattern: string, external_tracker_style: string, external_tracker_url: string>, external_wiki: record<external_wiki_url: string>, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record<allow_only_contributors_to_track_time: bool, enable_issue_dependencies: bool, enable_time_tracker: bool>, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, parent: any, permissions: record<admin: bool, pull: bool, push: bool>, private: bool, release_counter: int, repo_transfer: record<doer: record, recipient: record, teams: list>, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>, title: string, url: string>"
    issue-list-labels: "table<color: string, description: string, exclusive: bool, id: int, name: string, url: string>"
    issue-create-label: "record<color: string, description: string, exclusive: bool, id: int, name: string, url: string>"
    issue-get-label: "record<color: string, description: string, exclusive: bool, id: int, name: string, url: string>"
    issue-edit-label: "record<color: string, description: string, exclusive: bool, id: int, name: string, url: string>"
    repo-get-languages: "record"
    issue-get-milestones-list: "table<closed_at: string, closed_issues: int, created_at: string, description: string, due_on: string, id: int, open_issues: int, state: string, title: string, updated_at: string>"
    issue-create-milestone: "record<closed_at: string, closed_issues: int, created_at: string, description: string, due_on: string, id: int, open_issues: int, state: string, title: string, updated_at: string>"
    issue-get-milestone: "record<closed_at: string, closed_issues: int, created_at: string, description: string, due_on: string, id: int, open_issues: int, state: string, title: string, updated_at: string>"
    issue-edit-milestone: "record<closed_at: string, closed_issues: int, created_at: string, description: string, due_on: string, id: int, open_issues: int, state: string, title: string, updated_at: string>"
    notify-get-repo-list: "table<id: int, pinned: bool, repository: record<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record, external_wiki: record, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record, parent: any, permissions: record, private: bool, release_counter: int, repo_transfer: record, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>, subject: record<html_url: string, latest_comment_html_url: string, latest_comment_url: string, state: string, title: string, type: string, url: string>, unread: bool, updated_at: string, url: string>"
    notify-read-repo-list: "table<id: int, pinned: bool, repository: record<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record, external_wiki: record, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record, parent: any, permissions: record, private: bool, release_counter: int, repo_transfer: record, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>, subject: record<html_url: string, latest_comment_html_url: string, latest_comment_url: string, state: string, title: string, type: string, url: string>, unread: bool, updated_at: string, url: string>"
    repo-list-pull-requests: "table<allow_maintainer_edit: bool, assignee: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, assignees: list<record>, base: record<label: string, ref: string, repo: record, repo_id: int, sha: string>, body: string, closed_at: string, comments: int, created_at: string, diff_url: string, due_date: string, head: record<label: string, ref: string, repo: record, repo_id: int, sha: string>, html_url: string, id: int, is_locked: bool, labels: list<record>, merge_base: string, merge_commit_sha: string, mergeable: bool, merged: bool, merged_at: string, merged_by: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, milestone: record<closed_at: string, closed_issues: int, created_at: string, description: string, due_on: string, id: int, open_issues: int, state: string, title: string, updated_at: string>, number: int, patch_url: string, state: string, title: string, updated_at: string, url: string, user: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>>"
    repo-create-pull-request: "record<allow_maintainer_edit: bool, assignee: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, assignees: table<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, base: record<label: string, ref: string, repo: record<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record, external_wiki: record, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record, parent: any, permissions: record, private: bool, release_counter: int, repo_transfer: record, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>, repo_id: int, sha: string>, body: string, closed_at: string, comments: int, created_at: string, diff_url: string, due_date: string, head: record<label: string, ref: string, repo: record<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record, external_wiki: record, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record, parent: any, permissions: record, private: bool, release_counter: int, repo_transfer: record, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>, repo_id: int, sha: string>, html_url: string, id: int, is_locked: bool, labels: table<color: string, description: string, exclusive: bool, id: int, name: string, url: string>, merge_base: string, merge_commit_sha: string, mergeable: bool, merged: bool, merged_at: string, merged_by: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, milestone: record<closed_at: string, closed_issues: int, created_at: string, description: string, due_on: string, id: int, open_issues: int, state: string, title: string, updated_at: string>, number: int, patch_url: string, state: string, title: string, updated_at: string, url: string, user: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>>"
    repo-get-pull-request: "record<allow_maintainer_edit: bool, assignee: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, assignees: table<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, base: record<label: string, ref: string, repo: record<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record, external_wiki: record, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record, parent: any, permissions: record, private: bool, release_counter: int, repo_transfer: record, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>, repo_id: int, sha: string>, body: string, closed_at: string, comments: int, created_at: string, diff_url: string, due_date: string, head: record<label: string, ref: string, repo: record<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record, external_wiki: record, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record, parent: any, permissions: record, private: bool, release_counter: int, repo_transfer: record, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>, repo_id: int, sha: string>, html_url: string, id: int, is_locked: bool, labels: table<color: string, description: string, exclusive: bool, id: int, name: string, url: string>, merge_base: string, merge_commit_sha: string, mergeable: bool, merged: bool, merged_at: string, merged_by: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, milestone: record<closed_at: string, closed_issues: int, created_at: string, description: string, due_on: string, id: int, open_issues: int, state: string, title: string, updated_at: string>, number: int, patch_url: string, state: string, title: string, updated_at: string, url: string, user: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>>"
    repo-edit-pull-request: "record<allow_maintainer_edit: bool, assignee: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, assignees: table<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, base: record<label: string, ref: string, repo: record<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record, external_wiki: record, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record, parent: any, permissions: record, private: bool, release_counter: int, repo_transfer: record, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>, repo_id: int, sha: string>, body: string, closed_at: string, comments: int, created_at: string, diff_url: string, due_date: string, head: record<label: string, ref: string, repo: record<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record, external_wiki: record, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record, parent: any, permissions: record, private: bool, release_counter: int, repo_transfer: record, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>, repo_id: int, sha: string>, html_url: string, id: int, is_locked: bool, labels: table<color: string, description: string, exclusive: bool, id: int, name: string, url: string>, merge_base: string, merge_commit_sha: string, mergeable: bool, merged: bool, merged_at: string, merged_by: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, milestone: record<closed_at: string, closed_issues: int, created_at: string, description: string, due_on: string, id: int, open_issues: int, state: string, title: string, updated_at: string>, number: int, patch_url: string, state: string, title: string, updated_at: string, url: string, user: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>>"
    repo-download-pull-diff-or-patch: "string"
    repo-get-pull-request-commits: "table<author: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, commit: record<author: record, committer: record, message: string, tree: record, url: string, verification: record>, committer: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, created: string, files: list<record>, html_url: string, parents: list<record>, sha: string, stats: record<additions: int, deletions: int, total: int>, url: string>"
    repo-get-pull-request-files: "table<additions: int, changes: int, contents_url: string, deletions: int, filename: string, html_url: string, previous_filename: string, raw_url: string, status: string>"
    repo-create-pull-review-requests: "table<body: string, comments_count: int, commit_id: string, dismissed: bool, html_url: string, id: int, official: bool, pull_request_url: string, stale: bool, state: string, submitted_at: string, team: record<can_create_org_repo: bool, description: string, id: int, includes_all_repositories: bool, name: string, organization: record, permission: string, units: list, units_map: record>, updated_at: string, user: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>>"
    repo-list-pull-reviews: "table<body: string, comments_count: int, commit_id: string, dismissed: bool, html_url: string, id: int, official: bool, pull_request_url: string, stale: bool, state: string, submitted_at: string, team: record<can_create_org_repo: bool, description: string, id: int, includes_all_repositories: bool, name: string, organization: record, permission: string, units: list, units_map: record>, updated_at: string, user: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>>"
    repo-create-pull-review: "record<body: string, comments_count: int, commit_id: string, dismissed: bool, html_url: string, id: int, official: bool, pull_request_url: string, stale: bool, state: string, submitted_at: string, team: record<can_create_org_repo: bool, description: string, id: int, includes_all_repositories: bool, name: string, organization: record<avatar_url: string, description: string, full_name: string, id: int, location: string, name: string, repo_admin_change_team_access: bool, username: string, visibility: string, website: string>, permission: string, units: list<string>, units_map: record>, updated_at: string, user: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>>"
    repo-get-pull-review: "record<body: string, comments_count: int, commit_id: string, dismissed: bool, html_url: string, id: int, official: bool, pull_request_url: string, stale: bool, state: string, submitted_at: string, team: record<can_create_org_repo: bool, description: string, id: int, includes_all_repositories: bool, name: string, organization: record<avatar_url: string, description: string, full_name: string, id: int, location: string, name: string, repo_admin_change_team_access: bool, username: string, visibility: string, website: string>, permission: string, units: list<string>, units_map: record>, updated_at: string, user: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>>"
    repo-submit-pull-review: "record<body: string, comments_count: int, commit_id: string, dismissed: bool, html_url: string, id: int, official: bool, pull_request_url: string, stale: bool, state: string, submitted_at: string, team: record<can_create_org_repo: bool, description: string, id: int, includes_all_repositories: bool, name: string, organization: record<avatar_url: string, description: string, full_name: string, id: int, location: string, name: string, repo_admin_change_team_access: bool, username: string, visibility: string, website: string>, permission: string, units: list<string>, units_map: record>, updated_at: string, user: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>>"
    repo-get-pull-review-comments: "table<body: string, commit_id: string, created_at: string, diff_hunk: string, html_url: string, id: int, original_commit_id: string, original_position: int, path: string, position: int, pull_request_review_id: int, pull_request_url: string, resolver: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, updated_at: string, user: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>>"
    repo-dismiss-pull-review: "record<body: string, comments_count: int, commit_id: string, dismissed: bool, html_url: string, id: int, official: bool, pull_request_url: string, stale: bool, state: string, submitted_at: string, team: record<can_create_org_repo: bool, description: string, id: int, includes_all_repositories: bool, name: string, organization: record<avatar_url: string, description: string, full_name: string, id: int, location: string, name: string, repo_admin_change_team_access: bool, username: string, visibility: string, website: string>, permission: string, units: list<string>, units_map: record>, updated_at: string, user: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>>"
    repo-un-dismiss-pull-review: "record<body: string, comments_count: int, commit_id: string, dismissed: bool, html_url: string, id: int, official: bool, pull_request_url: string, stale: bool, state: string, submitted_at: string, team: record<can_create_org_repo: bool, description: string, id: int, includes_all_repositories: bool, name: string, organization: record<avatar_url: string, description: string, full_name: string, id: int, location: string, name: string, repo_admin_change_team_access: bool, username: string, visibility: string, website: string>, permission: string, units: list<string>, units_map: record>, updated_at: string, user: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>>"
    repo-list-push-mirrors: "table<created: string, interval: string, last_error: string, last_update: string, remote_address: string, remote_name: string, repo_name: string, sync_on_commit: bool>"
    repo-add-push-mirror: "record<created: string, interval: string, last_error: string, last_update: string, remote_address: string, remote_name: string, repo_name: string, sync_on_commit: bool>"
    repo-get-push-mirror-by-remote-name: "record<created: string, interval: string, last_error: string, last_update: string, remote_address: string, remote_name: string, repo_name: string, sync_on_commit: bool>"
    repo-list-releases: "table<assets: list<record>, author: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, body: string, created_at: string, draft: bool, html_url: string, id: int, name: string, prerelease: bool, published_at: string, tag_name: string, tarball_url: string, target_commitish: string, url: string, zipball_url: string>"
    repo-create-release: "record<assets: table<browser_download_url: string, created_at: string, download_count: int, id: int, name: string, size: int, uuid: string>, author: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, body: string, created_at: string, draft: bool, html_url: string, id: int, name: string, prerelease: bool, published_at: string, tag_name: string, tarball_url: string, target_commitish: string, url: string, zipball_url: string>"
    repo-get-latest-release: "record<assets: table<browser_download_url: string, created_at: string, download_count: int, id: int, name: string, size: int, uuid: string>, author: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, body: string, created_at: string, draft: bool, html_url: string, id: int, name: string, prerelease: bool, published_at: string, tag_name: string, tarball_url: string, target_commitish: string, url: string, zipball_url: string>"
    repo-get-release-by-tag: "record<assets: table<browser_download_url: string, created_at: string, download_count: int, id: int, name: string, size: int, uuid: string>, author: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, body: string, created_at: string, draft: bool, html_url: string, id: int, name: string, prerelease: bool, published_at: string, tag_name: string, tarball_url: string, target_commitish: string, url: string, zipball_url: string>"
    repo-get-release: "record<assets: table<browser_download_url: string, created_at: string, download_count: int, id: int, name: string, size: int, uuid: string>, author: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, body: string, created_at: string, draft: bool, html_url: string, id: int, name: string, prerelease: bool, published_at: string, tag_name: string, tarball_url: string, target_commitish: string, url: string, zipball_url: string>"
    repo-edit-release: "record<assets: table<browser_download_url: string, created_at: string, download_count: int, id: int, name: string, size: int, uuid: string>, author: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, body: string, created_at: string, draft: bool, html_url: string, id: int, name: string, prerelease: bool, published_at: string, tag_name: string, tarball_url: string, target_commitish: string, url: string, zipball_url: string>"
    repo-list-release-attachments: "table<browser_download_url: string, created_at: string, download_count: int, id: int, name: string, size: int, uuid: string>"
    repo-create-release-attachment: "record<browser_download_url: string, created_at: string, download_count: int, id: int, name: string, size: int, uuid: string>"
    repo-get-release-attachment: "record<browser_download_url: string, created_at: string, download_count: int, id: int, name: string, size: int, uuid: string>"
    repo-edit-release-attachment: "record<browser_download_url: string, created_at: string, download_count: int, id: int, name: string, size: int, uuid: string>"
    repo-get-reviewers: "table<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>"
    repo-signing-key: "string"
    repo-list-stargazers: "table<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>"
    repo-list-statuses: "table<context: string, created_at: string, creator: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, description: string, id: int, status: string, target_url: string, updated_at: string, url: string>"
    repo-create-status: "record<context: string, created_at: string, creator: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, description: string, id: int, status: string, target_url: string, updated_at: string, url: string>"
    repo-list-subscribers: "table<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>"
    user-current-check-subscription: "record<created_at: string, ignored: bool, reason: any, repository_url: string, subscribed: bool, url: string>"
    user-current-put-subscription: "record<created_at: string, ignored: bool, reason: any, repository_url: string, subscribed: bool, url: string>"
    repo-list-tags: "table<commit: record<created: string, sha: string, url: string>, id: string, message: string, name: string, tarball_url: string, zipball_url: string>"
    repo-create-tag: "record<commit: record<created: string, sha: string, url: string>, id: string, message: string, name: string, tarball_url: string, zipball_url: string>"
    repo-get-tag: "record<commit: record<created: string, sha: string, url: string>, id: string, message: string, name: string, tarball_url: string, zipball_url: string>"
    repo-list-teams: "table<can_create_org_repo: bool, description: string, id: int, includes_all_repositories: bool, name: string, organization: record<avatar_url: string, description: string, full_name: string, id: int, location: string, name: string, repo_admin_change_team_access: bool, username: string, visibility: string, website: string>, permission: string, units: list<string>, units_map: record>"
    repo-check-team: "record<can_create_org_repo: bool, description: string, id: int, includes_all_repositories: bool, name: string, organization: record<avatar_url: string, description: string, full_name: string, id: int, location: string, name: string, repo_admin_change_team_access: bool, username: string, visibility: string, website: string>, permission: string, units: list<string>, units_map: record>"
    repo-tracked-times: "table<created: string, id: int, issue: record<assets: list, assignee: record, assignees: list, body: string, closed_at: string, comments: int, created_at: string, due_date: string, html_url: string, id: int, is_locked: bool, labels: list, milestone: record, number: int, original_author: string, original_author_id: int, pull_request: record, ref: string, repository: record, state: string, title: string, updated_at: string, url: string, user: record>, issue_id: int, time: int, user_id: int, user_name: string>"
    user-tracked-times: "table<created: string, id: int, issue: record<assets: list, assignee: record, assignees: list, body: string, closed_at: string, comments: int, created_at: string, due_date: string, html_url: string, id: int, is_locked: bool, labels: list, milestone: record, number: int, original_author: string, original_author_id: int, pull_request: record, ref: string, repository: record, state: string, title: string, updated_at: string, url: string, user: record>, issue_id: int, time: int, user_id: int, user_name: string>"
    repo-list-topics: "record<topics: list<string>>"
    repo-transfer: "record<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record<external_tracker_format: string, external_tracker_regexp_pattern: string, external_tracker_style: string, external_tracker_url: string>, external_wiki: record<external_wiki_url: string>, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record<allow_only_contributors_to_track_time: bool, enable_issue_dependencies: bool, enable_time_tracker: bool>, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, parent: any, permissions: record<admin: bool, pull: bool, push: bool>, private: bool, release_counter: int, repo_transfer: record<doer: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, recipient: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, teams: list<record>>, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>"
    accept-repo-transfer: "record<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record<external_tracker_format: string, external_tracker_regexp_pattern: string, external_tracker_style: string, external_tracker_url: string>, external_wiki: record<external_wiki_url: string>, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record<allow_only_contributors_to_track_time: bool, enable_issue_dependencies: bool, enable_time_tracker: bool>, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, parent: any, permissions: record<admin: bool, pull: bool, push: bool>, private: bool, release_counter: int, repo_transfer: record<doer: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, recipient: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, teams: list<record>>, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>"
    reject-repo-transfer: "record<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record<external_tracker_format: string, external_tracker_regexp_pattern: string, external_tracker_style: string, external_tracker_url: string>, external_wiki: record<external_wiki_url: string>, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record<allow_only_contributors_to_track_time: bool, enable_issue_dependencies: bool, enable_time_tracker: bool>, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, parent: any, permissions: record<admin: bool, pull: bool, push: bool>, private: bool, release_counter: int, repo_transfer: record<doer: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, recipient: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, teams: list<record>>, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>"
    repo-create-wiki-page: "record<commit_count: int, content_base64: string, footer: string, html_url: string, last_commit: record<author: record<date: string, email: string, name: string>, commiter: record<date: string, email: string, name: string>, message: string, sha: string>, sidebar: string, sub_url: string, title: string>"
    repo-get-wiki-page: "record<commit_count: int, content_base64: string, footer: string, html_url: string, last_commit: record<author: record<date: string, email: string, name: string>, commiter: record<date: string, email: string, name: string>, message: string, sha: string>, sidebar: string, sub_url: string, title: string>"
    repo-edit-wiki-page: "record<commit_count: int, content_base64: string, footer: string, html_url: string, last_commit: record<author: record<date: string, email: string, name: string>, commiter: record<date: string, email: string, name: string>, message: string, sha: string>, sidebar: string, sub_url: string, title: string>"
    repo-get-wiki-pages: "table<html_url: string, last_commit: record<author: record, commiter: record, message: string, sha: string>, sub_url: string, title: string>"
    repo-get-wiki-page-revisions: "record<commits: table<author: record, commiter: record, message: string, sha: string>, count: int>"
    generate-repo: "record<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record<external_tracker_format: string, external_tracker_regexp_pattern: string, external_tracker_style: string, external_tracker_url: string>, external_wiki: record<external_wiki_url: string>, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record<allow_only_contributors_to_track_time: bool, enable_issue_dependencies: bool, enable_time_tracker: bool>, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, parent: any, permissions: record<admin: bool, pull: bool, push: bool>, private: bool, release_counter: int, repo_transfer: record<doer: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, recipient: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, teams: list<record>>, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>"
    repo-get-by-id: "record<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record<external_tracker_format: string, external_tracker_regexp_pattern: string, external_tracker_style: string, external_tracker_url: string>, external_wiki: record<external_wiki_url: string>, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record<allow_only_contributors_to_track_time: bool, enable_issue_dependencies: bool, enable_time_tracker: bool>, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, parent: any, permissions: record<admin: bool, pull: bool, push: bool>, private: bool, release_counter: int, repo_transfer: record<doer: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, recipient: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, teams: list<record>>, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>"
    get-general-api-settings: "record<default_git_trees_per_page: int, default_max_blob_size: int, default_paging_num: int, max_response_items: int>"
    get-general-attachment-settings: "record<allowed_types: string, enabled: bool, max_files: int, max_size: int>"
    get-general-repository-settings: "record<http_git_disabled: bool, lfs_disabled: bool, migrations_disabled: bool, mirrors_disabled: bool, stars_disabled: bool, time_tracking_disabled: bool>"
    get-general-ui-settings: "record<allowed_reactions: list<string>, custom_emojis: list<string>, default_theme: string>"
    get-signing-key: "string"
    org-get-team: "record<can_create_org_repo: bool, description: string, id: int, includes_all_repositories: bool, name: string, organization: record<avatar_url: string, description: string, full_name: string, id: int, location: string, name: string, repo_admin_change_team_access: bool, username: string, visibility: string, website: string>, permission: string, units: list<string>, units_map: record>"
    org-edit-team: "record<can_create_org_repo: bool, description: string, id: int, includes_all_repositories: bool, name: string, organization: record<avatar_url: string, description: string, full_name: string, id: int, location: string, name: string, repo_admin_change_team_access: bool, username: string, visibility: string, website: string>, permission: string, units: list<string>, units_map: record>"
    org-list-team-members: "table<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>"
    org-list-team-member: "record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>"
    org-list-team-repos: "table<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record<external_tracker_format: string, external_tracker_regexp_pattern: string, external_tracker_style: string, external_tracker_url: string>, external_wiki: record<external_wiki_url: string>, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record<allow_only_contributors_to_track_time: bool, enable_issue_dependencies: bool, enable_time_tracker: bool>, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, parent: any, permissions: record<admin: bool, pull: bool, push: bool>, private: bool, release_counter: int, repo_transfer: record<doer: record, recipient: record, teams: list>, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>"
    org-list-team-repo: "record<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record<external_tracker_format: string, external_tracker_regexp_pattern: string, external_tracker_style: string, external_tracker_url: string>, external_wiki: record<external_wiki_url: string>, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record<allow_only_contributors_to_track_time: bool, enable_issue_dependencies: bool, enable_time_tracker: bool>, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, parent: any, permissions: record<admin: bool, pull: bool, push: bool>, private: bool, release_counter: int, repo_transfer: record<doer: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, recipient: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, teams: list<record>>, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>"
    topic-search: "table<created: string, id: int, repo_count: int, topic_name: string, updated: string>"
    user-get-current: "record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>"
    user-get-oauth2-application: "table<client_id: string, client_secret: string, confidential_client: bool, created: string, id: int, name: string, redirect_uris: list<string>>"
    user-create-o-auth2-application: "record<client_id: string, client_secret: string, confidential_client: bool, created: string, id: int, name: string, redirect_uris: list<string>>"
    user-get-o-auth2-application: "record<client_id: string, client_secret: string, confidential_client: bool, created: string, id: int, name: string, redirect_uris: list<string>>"
    user-update-o-auth2-application: "record<client_id: string, client_secret: string, confidential_client: bool, created: string, id: int, name: string, redirect_uris: list<string>>"
    user-list-emails: "table<email: string, primary: bool, verified: bool>"
    user-add-email: "table<email: string, primary: bool, verified: bool>"
    user-current-list-followers: "table<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>"
    user-current-list-following: "table<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>"
    get-verification-token: "string"
    user-verify-gpg-key: "record<can_certify: bool, can_encrypt_comms: bool, can_encrypt_storage: bool, can_sign: bool, created_at: string, emails: table<email: string, verified: bool>, expires_at: string, id: int, key_id: string, primary_key_id: string, public_key: string, subkeys: list<any>, verified: bool>"
    user-current-list-gpg-keys: "table<can_certify: bool, can_encrypt_comms: bool, can_encrypt_storage: bool, can_sign: bool, created_at: string, emails: list<record>, expires_at: string, id: int, key_id: string, primary_key_id: string, public_key: string, subkeys: list<any>, verified: bool>"
    user-current-post-gpg-key: "record<can_certify: bool, can_encrypt_comms: bool, can_encrypt_storage: bool, can_sign: bool, created_at: string, emails: table<email: string, verified: bool>, expires_at: string, id: int, key_id: string, primary_key_id: string, public_key: string, subkeys: list<any>, verified: bool>"
    user-current-get-gpg-key: "record<can_certify: bool, can_encrypt_comms: bool, can_encrypt_storage: bool, can_sign: bool, created_at: string, emails: table<email: string, verified: bool>, expires_at: string, id: int, key_id: string, primary_key_id: string, public_key: string, subkeys: list<any>, verified: bool>"
    user-current-list-keys: "table<created_at: string, fingerprint: string, id: int, key: string, key_type: string, read_only: bool, title: string, url: string, user: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>>"
    user-current-post-key: "record<created_at: string, fingerprint: string, id: int, key: string, key_type: string, read_only: bool, title: string, url: string, user: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>>"
    user-current-get-key: "record<created_at: string, fingerprint: string, id: int, key: string, key_type: string, read_only: bool, title: string, url: string, user: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>>"
    org-list-current-user-orgs: "table<avatar_url: string, description: string, full_name: string, id: int, location: string, name: string, repo_admin_change_team_access: bool, username: string, visibility: string, website: string>"
    user-current-list-repos: "table<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record<external_tracker_format: string, external_tracker_regexp_pattern: string, external_tracker_style: string, external_tracker_url: string>, external_wiki: record<external_wiki_url: string>, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record<allow_only_contributors_to_track_time: bool, enable_issue_dependencies: bool, enable_time_tracker: bool>, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, parent: any, permissions: record<admin: bool, pull: bool, push: bool>, private: bool, release_counter: int, repo_transfer: record<doer: record, recipient: record, teams: list>, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>"
    create-current-user-repo: "record<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record<external_tracker_format: string, external_tracker_regexp_pattern: string, external_tracker_style: string, external_tracker_url: string>, external_wiki: record<external_wiki_url: string>, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record<allow_only_contributors_to_track_time: bool, enable_issue_dependencies: bool, enable_time_tracker: bool>, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, parent: any, permissions: record<admin: bool, pull: bool, push: bool>, private: bool, release_counter: int, repo_transfer: record<doer: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, recipient: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, teams: list<record>>, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>"
    get-user-settings: "table<description: string, diff_view_style: string, full_name: string, hide_activity: bool, hide_email: bool, language: string, location: string, theme: string, website: string>"
    update-user-settings: "table<description: string, diff_view_style: string, full_name: string, hide_activity: bool, hide_email: bool, language: string, location: string, theme: string, website: string>"
    user-current-list-starred: "table<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record<external_tracker_format: string, external_tracker_regexp_pattern: string, external_tracker_style: string, external_tracker_url: string>, external_wiki: record<external_wiki_url: string>, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record<allow_only_contributors_to_track_time: bool, enable_issue_dependencies: bool, enable_time_tracker: bool>, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, parent: any, permissions: record<admin: bool, pull: bool, push: bool>, private: bool, release_counter: int, repo_transfer: record<doer: record, recipient: record, teams: list>, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>"
    user-get-stop-watches: "table<created: string, duration: string, issue_index: int, issue_title: string, repo_name: string, repo_owner_name: string, seconds: int>"
    user-current-list-subscriptions: "table<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record<external_tracker_format: string, external_tracker_regexp_pattern: string, external_tracker_style: string, external_tracker_url: string>, external_wiki: record<external_wiki_url: string>, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record<allow_only_contributors_to_track_time: bool, enable_issue_dependencies: bool, enable_time_tracker: bool>, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, parent: any, permissions: record<admin: bool, pull: bool, push: bool>, private: bool, release_counter: int, repo_transfer: record<doer: record, recipient: record, teams: list>, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>"
    user-list-teams: "table<can_create_org_repo: bool, description: string, id: int, includes_all_repositories: bool, name: string, organization: record<avatar_url: string, description: string, full_name: string, id: int, location: string, name: string, repo_admin_change_team_access: bool, username: string, visibility: string, website: string>, permission: string, units: list<string>, units_map: record>"
    user-current-tracked-times: "table<created: string, id: int, issue: record<assets: list, assignee: record, assignees: list, body: string, closed_at: string, comments: int, created_at: string, due_date: string, html_url: string, id: int, is_locked: bool, labels: list, milestone: record, number: int, original_author: string, original_author_id: int, pull_request: record, ref: string, repository: record, state: string, title: string, updated_at: string, url: string, user: record>, issue_id: int, time: int, user_id: int, user_name: string>"
    user-search: "record<data: table<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, ok: bool>"
    user-get: "record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>"
    user-list-followers: "table<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>"
    user-list-following: "table<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>"
    user-list-gpg-keys: "table<can_certify: bool, can_encrypt_comms: bool, can_encrypt_storage: bool, can_sign: bool, created_at: string, emails: list<record>, expires_at: string, id: int, key_id: string, primary_key_id: string, public_key: string, subkeys: list<any>, verified: bool>"
    user-get-heatmap-data: "table<contributions: int, timestamp: int>"
    user-list-keys: "table<created_at: string, fingerprint: string, id: int, key: string, key_type: string, read_only: bool, title: string, url: string, user: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>>"
    org-list-user-orgs: "table<avatar_url: string, description: string, full_name: string, id: int, location: string, name: string, repo_admin_change_team_access: bool, username: string, visibility: string, website: string>"
    org-get-user-permissions: "record<can_create_repository: bool, can_read: bool, can_write: bool, is_admin: bool, is_owner: bool>"
    user-list-repos: "table<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record<external_tracker_format: string, external_tracker_regexp_pattern: string, external_tracker_style: string, external_tracker_url: string>, external_wiki: record<external_wiki_url: string>, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record<allow_only_contributors_to_track_time: bool, enable_issue_dependencies: bool, enable_time_tracker: bool>, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, parent: any, permissions: record<admin: bool, pull: bool, push: bool>, private: bool, release_counter: int, repo_transfer: record<doer: record, recipient: record, teams: list>, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>"
    user-list-starred: "table<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record<external_tracker_format: string, external_tracker_regexp_pattern: string, external_tracker_style: string, external_tracker_url: string>, external_wiki: record<external_wiki_url: string>, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record<allow_only_contributors_to_track_time: bool, enable_issue_dependencies: bool, enable_time_tracker: bool>, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, parent: any, permissions: record<admin: bool, pull: bool, push: bool>, private: bool, release_counter: int, repo_transfer: record<doer: record, recipient: record, teams: list>, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>"
    user-list-subscriptions: "table<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record<external_tracker_format: string, external_tracker_regexp_pattern: string, external_tracker_style: string, external_tracker_url: string>, external_wiki: record<external_wiki_url: string>, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record<allow_only_contributors_to_track_time: bool, enable_issue_dependencies: bool, enable_time_tracker: bool>, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, parent: any, permissions: record<admin: bool, pull: bool, push: bool>, private: bool, release_counter: int, repo_transfer: record<doer: record, recipient: record, teams: list>, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>"
    user-get-tokens: "table<id: int, name: string, scopes: list<string>, sha1: string, token_last_eight: string>"
    user-create-token: "record<id: int, name: string, scopes: list<string>, sha1: string, token_last_eight: string>"
    get-version: "record<version: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["activitypub-person" "activitypub-person-inbox" "admin-cron-list" "admin-cron-run" "admin-list-hooks" "admin-create-hook" "admin-get-hook" "admin-edit-hook" "admin-get-all-orgs" "admin-unadopted-list" "admin-delete-unadopted-repository" "admin-adopt-repository" "admin-get-all-users" "admin-create-user" "admin-delete-user" "admin-edit-user" "admin-create-public-key" "admin-delete-user-public-key" "admin-create-org" "admin-create-repo" "admin-delete-hook" "render-markdown" "render-markdown-raw" "get-node-info" "notify-get-list" "notify-read-list" "notify-new-available" "notify-get-thread" "notify-read-thread" "create-org-repo-deprecated" "org-get-all" "org-create" "org-delete" "org-get" "org-edit" "org-list-hooks" "org-create-hook" "org-delete-hook" "org-get-hook" "org-edit-hook" "org-list-labels" "org-create-label" "org-delete-label" "org-get-label" "org-edit-label" "org-list-members" "org-delete-member" "org-is-member" "org-list-public-members" "org-conceal-member" "org-is-public-member" "org-publicize-member" "org-list-repos" "create-org-repo" "org-list-teams" "org-create-team" "team-search" "list-packages" "delete-package" "get-package" "list-package-files" "issue-search-issues" "repo-migrate" "repo-search" "repo-delete" "repo-get" "repo-edit" "repo-get-archive" "repo-get-assignees" "repo-list-branch-protection" "repo-create-branch-protection" "repo-delete-branch-protection" "repo-get-branch-protection" "repo-edit-branch-protection" "repo-list-branches" "repo-create-branch" "repo-delete-branch" "repo-get-branch" "repo-list-collaborators" "repo-delete-collaborator" "repo-check-collaborator" "repo-add-collaborator" "repo-get-repo-permissions" "repo-get-all-commits" "repo-get-combined-status-by-ref" "repo-list-statuses-by-ref" "repo-get-contents-list" "repo-delete-file" "repo-get-contents" "repo-create-file" "repo-update-file" "repo-apply-diff-patch" "repo-get-editor-config" "list-forks" "create-fork" "get-blob" "repo-get-single-commit" "repo-download-commit-diff-or-patch" "repo-get-note" "repo-list-all-git-refs" "repo-list-git-refs" "get-annotated-tag" "get-tree" "repo-list-hooks" "repo-create-hook" "repo-list-git-hooks" "repo-delete-git-hook" "repo-get-git-hook" "repo-edit-git-hook" "repo-delete-hook" "repo-get-hook" "repo-edit-hook" "repo-test-hook" "repo-get-issue-templates" "issue-list-issues" "issue-create-issue" "issue-get-repo-comments" "issue-delete-comment" "issue-get-comment" "issue-edit-comment" "issue-list-issue-comment-attachments" "issue-create-issue-comment-attachment" "issue-delete-issue-comment-attachment" "issue-get-issue-comment-attachment" "issue-edit-issue-comment-attachment" "issue-delete-comment-reaction" "issue-get-comment-reactions" "issue-post-comment-reaction" "issue-delete" "issue-get-issue" "issue-edit-issue" "issue-list-issue-attachments" "issue-create-issue-attachment" "issue-delete-issue-attachment" "issue-get-issue-attachment" "issue-edit-issue-attachment" "issue-get-comments" "issue-create-comment" "issue-delete-comment-deprecated" "issue-edit-comment-deprecated" "issue-edit-issue-deadline" "issue-clear-labels" "issue-get-labels" "issue-add-label" "issue-replace-labels" "issue-remove-label" "issue-delete-issue-reaction" "issue-get-issue-reactions" "issue-post-issue-reaction" "issue-delete-stop-watch" "issue-start-stop-watch" "issue-stop-stop-watch" "issue-subscriptions" "issue-check-subscription" "issue-delete-subscription" "issue-add-subscription" "issue-get-comments-and-timeline" "issue-reset-time" "issue-tracked-times" "issue-add-time" "issue-delete-time" "repo-list-keys" "repo-create-key" "repo-delete-key" "repo-get-key" "issue-list-labels" "issue-create-label" "issue-delete-label" "issue-get-label" "issue-edit-label" "repo-get-languages" "repo-get-raw-file-or-lfs" "issue-get-milestones-list" "issue-create-milestone" "issue-delete-milestone" "issue-get-milestone" "issue-edit-milestone" "repo-mirror-sync" "notify-get-repo-list" "notify-read-repo-list" "repo-list-pull-requests" "repo-create-pull-request" "repo-get-pull-request" "repo-edit-pull-request" "repo-download-pull-diff-or-patch" "repo-get-pull-request-commits" "repo-get-pull-request-files" "repo-cancel-scheduled-auto-merge" "repo-pull-request-is-merged" "repo-merge-pull-request" "repo-delete-pull-review-requests" "repo-create-pull-review-requests" "repo-list-pull-reviews" "repo-create-pull-review" "repo-delete-pull-review" "repo-get-pull-review" "repo-submit-pull-review" "repo-get-pull-review-comments" "repo-dismiss-pull-review" "repo-un-dismiss-pull-review" "repo-update-pull-request" "repo-list-push-mirrors" "repo-add-push-mirror" "repo-push-mirror-sync" "repo-delete-push-mirror" "repo-get-push-mirror-by-remote-name" "repo-get-raw-file" "repo-list-releases" "repo-create-release" "repo-get-latest-release" "repo-delete-release-by-tag" "repo-get-release-by-tag" "repo-delete-release" "repo-get-release" "repo-edit-release" "repo-list-release-attachments" "repo-create-release-attachment" "repo-delete-release-attachment" "repo-get-release-attachment" "repo-edit-release-attachment" "repo-get-reviewers" "repo-signing-key" "repo-list-stargazers" "repo-list-statuses" "repo-create-status" "repo-list-subscribers" "user-current-delete-subscription" "user-current-check-subscription" "user-current-put-subscription" "repo-list-tags" "repo-create-tag" "repo-delete-tag" "repo-get-tag" "repo-list-teams" "repo-delete-team" "repo-check-team" "repo-add-team" "repo-tracked-times" "user-tracked-times" "repo-list-topics" "repo-update-topics" "repo-delete-topic" "repo-add-topic" "repo-transfer" "accept-repo-transfer" "reject-repo-transfer" "repo-create-wiki-page" "repo-delete-wiki-page" "repo-get-wiki-page" "repo-edit-wiki-page" "repo-get-wiki-pages" "repo-get-wiki-page-revisions" "generate-repo" "repo-get-by-id" "get-general-api-settings" "get-general-attachment-settings" "get-general-repository-settings" "get-general-ui-settings" "get-signing-key" "org-delete-team" "org-get-team" "org-edit-team" "org-list-team-members" "org-remove-team-member" "org-list-team-member" "org-add-team-member" "org-list-team-repos" "org-remove-team-repository" "org-list-team-repo" "org-add-team-repository" "topic-search" "user-get-current" "user-get-oauth2-application" "user-create-o-auth2-application" "user-delete-o-auth2-application" "user-get-o-auth2-application" "user-update-o-auth2-application" "user-delete-email" "user-list-emails" "user-add-email" "user-current-list-followers" "user-current-list-following" "user-current-delete-follow" "user-current-check-following" "user-current-put-follow" "get-verification-token" "user-verify-gpg-key" "user-current-list-gpg-keys" "user-current-post-gpg-key" "user-current-delete-gpg-key" "user-current-get-gpg-key" "user-current-list-keys" "user-current-post-key" "user-current-delete-key" "user-current-get-key" "org-list-current-user-orgs" "user-current-list-repos" "create-current-user-repo" "get-user-settings" "update-user-settings" "user-current-list-starred" "user-current-delete-star" "user-current-check-starring" "user-current-put-star" "user-get-stop-watches" "user-current-list-subscriptions" "user-list-teams" "user-current-tracked-times" "user-search" "user-get" "user-list-followers" "user-list-following" "user-check-following" "user-list-gpg-keys" "user-get-heatmap-data" "user-list-keys" "org-list-user-orgs" "org-get-user-permissions" "user-list-repos" "user-list-starred" "user-list-subscriptions" "user-get-tokens" "user-create-token" "user-delete-access-token" "get-version" "commands"] | sort) } | get name | first)
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

# Returns the Person actor for a user
#
# GET /activitypub/user/{username}
# Returns: record<"@context": string>
# operationId: activitypubPerson
export def "activitypub-person" [
  username: string
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
    path: "/activitypub/user/{username}"
    path_params: [{name: username, var: username}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Send to the inbox
#
# POST /activitypub/user/{username}/inbox
# operationId: activitypubPersonInbox
export def "activitypub-person-inbox" [
  username: string
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
    path: "/activitypub/user/{username}/inbox"
    path_params: [{name: username, var: username}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List cron tasks
#
# GET /admin/cron
# Returns: table<exec_times: int, name: string, next: string, prev: string, schedule: string>
# operationId: adminCronList
export def "admin-cron-list" [
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
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/admin/cron"
    query: [{name: page, var: page}, {name: limit, var: limit}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    page: $page, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Run cron task
#
# POST /admin/cron/{task}
# operationId: adminCronRun
export def "admin-cron-run" [
  task: string
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
    path: "/admin/cron/{task}"
    path_params: [{name: task, var: task}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    task: $task
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List system's webhooks
#
# GET /admin/hooks
# Returns: table<active: bool, authorization_header: string, config: record, created_at: string, events: list<string>, id: int, type: string, updated_at: string>
# operationId: adminListHooks
export def "admin-list-hooks" [
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
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/admin/hooks"
    query: [{name: page, var: page}, {name: limit, var: limit}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    page: $page, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a hook
#
# POST /admin/hooks
# Returns: record<active: bool, authorization_header: string, config: record, created_at: string, events: list<string>, id: int, type: string, updated_at: string>
# operationId: adminCreateHook
export def "admin-create-hook" [
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
  --active: oneof<nothing, bool> # default: false
  --authorization-header: string
  --branch-filter: string
  config: record # CreateHookOptionConfig has all config options in it required are "content_type" and "url" Required
  --events: list<string>
  type: string@type-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin/hooks"
    body: {content_type: "application/json", kind: json, fields: [{name: active, var: active}, {name: authorization_header, var: authorization_header}, {name: branch_filter, var: branch_filter}, {name: config, var: config}, {name: events, var: events}, {name: type, var: type}]}
    accept: ["application/json", "text/html"]
    ok: [201]
    auth: basic
  } {
    active: $active, authorization_header: $authorization_header, branch_filter: $branch_filter, config: $config, events: $events, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a hook
#
# GET /admin/hooks/{id}
# Returns: record<active: bool, authorization_header: string, config: record, created_at: string, events: list<string>, id: int, type: string, updated_at: string>
# operationId: adminGetHook
export def "admin-get-hook" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/admin/hooks/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a hook
#
# PATCH /admin/hooks/{id}
# Returns: record<active: bool, authorization_header: string, config: record, created_at: string, events: list<string>, id: int, type: string, updated_at: string>
# operationId: adminEditHook
export def "admin-edit-hook" [
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
  --accept: string@accept-completer # Response content type
  --active: oneof<nothing, bool>
  --authorization-header: string
  --branch-filter: string
  --config: record
  --events: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/admin/hooks/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: active, var: active}, {name: authorization_header, var: authorization_header}, {name: branch_filter, var: branch_filter}, {name: config, var: config}, {name: events, var: events}]}
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    id: $id, active: $active, authorization_header: $authorization_header, branch_filter: $branch_filter, config: $config, events: $events
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List all organizations
#
# GET /admin/orgs
# Returns: table<avatar_url: string, description: string, full_name: string, id: int, location: string, name: string, repo_admin_change_team_access: bool, username: string, visibility: string, website: string>
# operationId: adminGetAllOrgs
export def "admin-get-all-orgs" [
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
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/admin/orgs"
    query: [{name: page, var: page}, {name: limit, var: limit}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    page: $page, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List unadopted repositories
#
# GET /admin/unadopted
# Returns: list<string>
# operationId: adminUnadoptedList
export def "admin-unadopted-list" [
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
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
  --pattern: string # pattern of repositories to search for
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/admin/unadopted"
    query: [{name: page, var: page}, {name: limit, var: limit}, {name: pattern, var: pattern}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    page: $page, limit: $limit, pattern: $pattern
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete unadopted files
#
# DELETE /admin/unadopted/{owner}/{repo}
# operationId: adminDeleteUnadoptedRepository
export def "admin-delete-unadopted-repository" [
  owner: string
  repo: string
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
    path: "/admin/unadopted/{owner}/{repo}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    owner: $owner, repo: $repo
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adopt unadopted files as a repository
#
# POST /admin/unadopted/{owner}/{repo}
# operationId: adminAdoptRepository
export def "admin-adopt-repository" [
  owner: string
  repo: string
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
    path: "/admin/unadopted/{owner}/{repo}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    owner: $owner, repo: $repo
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all users
#
# GET /admin/users
# Returns: table<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>
# operationId: adminGetAllUsers
export def "admin-get-all-users" [
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
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/admin/users"
    query: [{name: page, var: page}, {name: limit, var: limit}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    page: $page, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a user
#
# POST /admin/users
# Returns: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>
# operationId: adminCreateUser
export def "admin-create-user" [
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
  --created-at: string # For explicitly setting the user creation timestamp. Useful when users are migrated from other systems. When omitted, the user's creation timestamp will be set to "now". (format: date-time)
  email: string # format: email
  --full-name: string
  --login-name: string
  --must-change-password: oneof<nothing, bool>
  password: string
  --restricted: oneof<nothing, bool>
  --send-notify: oneof<nothing, bool>
  --source-id: int # format: int64
  username: string
  --visibility: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin/users"
    body: {content_type: "application/json", kind: json, fields: [{name: created_at, var: created_at}, {name: email, var: email}, {name: full_name, var: full_name}, {name: login_name, var: login_name}, {name: must_change_password, var: must_change_password}, {name: password, var: password}, {name: restricted, var: restricted}, {name: send_notify, var: send_notify}, {name: source_id, var: source_id}, {name: username, var: username}, {name: visibility, var: visibility}]}
    accept: ["application/json", "text/html"]
    ok: [201]
    auth: basic
  } {
    created_at: $created_at, email: $email, full_name: $full_name, login_name: $login_name, must_change_password: $must_change_password, password: $password, restricted: $restricted, send_notify: $send_notify, source_id: $source_id, username: $username, visibility: $visibility
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a user
#
# DELETE /admin/users/{username}
# operationId: adminDeleteUser
export def "admin-delete-user" [
  username: string
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
    path: "/admin/users/{username}"
    path_params: [{name: username, var: username}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit an existing user
#
# PATCH /admin/users/{username}
# Returns: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>
# operationId: adminEditUser
export def "admin-edit-user" [
  username: string
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
  --active: oneof<nothing, bool>
  --admin: oneof<nothing, bool>
  --allow-create-organization: oneof<nothing, bool>
  --allow-git-hook: oneof<nothing, bool>
  --allow-import-local: oneof<nothing, bool>
  --description: string
  --email: string # format: email
  --full-name: string
  --location: string
  login_name: string
  --max-repo-creation: int # format: int64
  --must-change-password: oneof<nothing, bool>
  --password: string
  --prohibit-login: oneof<nothing, bool>
  --restricted: oneof<nothing, bool>
  source_id: int # format: int64
  --visibility: string
  --website: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/admin/users/{username}"
    path_params: [{name: username, var: username}]
    body: {content_type: "application/json", kind: json, fields: [{name: active, var: active}, {name: admin, var: admin}, {name: allow_create_organization, var: allow_create_organization}, {name: allow_git_hook, var: allow_git_hook}, {name: allow_import_local, var: allow_import_local}, {name: description, var: description}, {name: email, var: email}, {name: full_name, var: full_name}, {name: location, var: location}, {name: login_name, var: login_name}, {name: max_repo_creation, var: max_repo_creation}, {name: must_change_password, var: must_change_password}, {name: password, var: password}, {name: prohibit_login, var: prohibit_login}, {name: restricted, var: restricted}, {name: source_id, var: source_id}, {name: visibility, var: visibility}, {name: website, var: website}]}
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    username: $username, active: $active, admin: $admin, allow_create_organization: $allow_create_organization, allow_git_hook: $allow_git_hook, allow_import_local: $allow_import_local, description: $description, email: $email, full_name: $full_name, location: $location, login_name: $login_name, max_repo_creation: $max_repo_creation, must_change_password: $must_change_password, password: $password, prohibit_login: $prohibit_login, restricted: $restricted, source_id: $source_id, visibility: $visibility, website: $website
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add a public key on behalf of a user
#
# POST /admin/users/{username}/keys
# Returns: record<created_at: string, fingerprint: string, id: int, key: string, key_type: string, read_only: bool, title: string, url: string, user: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>>
# operationId: adminCreatePublicKey
export def "admin-create-public-key" [
  username: string
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
  key: string # An armored SSH key to add
  --read-only: oneof<nothing, bool> # Describe if the key has only read access or read/write
  title: string # Title of the key to add
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin/users/{username}/keys"
    path_params: [{name: username, var: username}]
    body: {content_type: "application/json", kind: json, fields: [{name: key, var: key}, {name: read_only, var: read_only}, {name: title, var: title}]}
    accept: ["application/json", "text/html"]
    ok: [201]
    auth: basic
  } {
    username: $username, key: $key, read_only: $read_only, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a user's public key
#
# DELETE /admin/users/{username}/keys/{id}
# operationId: adminDeleteUserPublicKey
export def "admin-delete-user-public-key" [
  username: string
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
    path: "/admin/users/{username}/keys/{id}"
    path_params: [{name: username, var: username}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    username: $username, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an organization
#
# POST /admin/users/{username}/orgs
# Returns: record<avatar_url: string, description: string, full_name: string, id: int, location: string, name: string, repo_admin_change_team_access: bool, username: string, visibility: string, website: string>
# operationId: adminCreateOrg
export def "admin-create-org" [
  username: string
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
  --description: string
  --full-name: string
  --location: string
  --repo-admin-change-team-access: oneof<nothing, bool>
  --body-username: string # (spec name: username)
  --visibility: string@visibility-completer # possible values are `public` (default), `limited` or `private`
  --website: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin/users/{username}/orgs"
    path_params: [{name: username, var: username}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: full_name, var: full_name}, {name: location, var: location}, {name: repo_admin_change_team_access, var: repo_admin_change_team_access}, {name: username, var: body_username, required: true}, {name: visibility, var: visibility}, {name: website, var: website}]}
    accept: ["application/json", "text/html"]
    ok: [201]
    auth: basic
  } {
    username: $username, description: $description, full_name: $full_name, location: $location, repo_admin_change_team_access: $repo_admin_change_team_access, body_username: $body_username, visibility: $visibility, website: $website
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a repository on behalf of a user
#
# POST /admin/users/{username}/repos
# Returns: record<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record<external_tracker_format: string, external_tracker_regexp_pattern: string, external_tracker_style: string, external_tracker_url: string>, external_wiki: record<external_wiki_url: string>, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record<allow_only_contributors_to_track_time: bool, enable_issue_dependencies: bool, enable_time_tracker: bool>, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, parent: any, permissions: record<admin: bool, pull: bool, push: bool>, private: bool, release_counter: int, repo_transfer: record<doer: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, recipient: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, teams: list<record>>, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>
# operationId: adminCreateRepo
export def "admin-create-repo" [
  username: string
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
  --auto-init: oneof<nothing, bool> # Whether the repository should be auto-initialized?
  --default-branch: string # DefaultBranch of the repository (used when initializes and in template)
  --description: string # Description of the repository to create
  --gitignores: string # Gitignores to use
  --issue-labels: string # Label-Set to use
  --license: string # License to use
  name: string # Name of the repository to create
  --private: oneof<nothing, bool> # Whether the repository is private
  --readme: string # Readme of the repository to create
  --template: oneof<nothing, bool> # Whether the repository is template
  --trust-model: string@trust-model-completer # TrustModel of the repository
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin/users/{username}/repos"
    path_params: [{name: username, var: username}]
    body: {content_type: "application/json", kind: json, fields: [{name: auto_init, var: auto_init}, {name: default_branch, var: default_branch}, {name: description, var: description}, {name: gitignores, var: gitignores}, {name: issue_labels, var: issue_labels}, {name: license, var: license}, {name: name, var: name}, {name: private, var: private}, {name: readme, var: readme}, {name: template, var: template}, {name: trust_model, var: trust_model}]}
    accept: ["application/json", "text/html"]
    ok: [201]
    auth: basic
  } {
    username: $username, auto_init: $auto_init, default_branch: $default_branch, description: $description, gitignores: $gitignores, issue_labels: $issue_labels, license: $license, name: $name, private: $private, readme: $readme, template: $template, trust_model: $trust_model
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a hook
#
# DELETE /amdin/hooks/{id}
# operationId: adminDeleteHook
export def "admin-delete-hook" [
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
    path: "/amdin/hooks/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Render a markdown document as HTML
#
# POST /markdown
# Returns: string
# operationId: renderMarkdown
export def "render-markdown" [
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
  --context: string # Context to render in: body
  --mode: string # Mode to render in: body
  --text: string # Text markdown to render in: body
  --wiki: oneof<nothing, bool> # Is it a wiki page ? in: body
]: any -> any {
  $in | http-request {
    method: post
    path: "/markdown"
    body: {content_type: "application/json", kind: json, fields: [{name: Context, var: context}, {name: Mode, var: mode}, {name: Text, var: text}, {name: Wiki, var: wiki}]}
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    context: $context, mode: $mode, text: $text, wiki: $wiki
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Render raw markdown as HTML
#
# POST /markdown/raw
# Returns: string
# operationId: renderMarkdownRaw
export def "render-markdown-raw" [
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
  --body: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/markdown/raw"
    body: {content_type: "text/plain", kind: opaque, accepts: scalar}
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns the nodeinfo of the Gitea application
#
# GET /nodeinfo
# Returns: record<metadata: record, openRegistrations: bool, protocols: list<string>, services: record<inbound: list<string>, outbound: list<string>>, software: record<homepage: string, name: string, repository: string, version: string>, usage: record<localComments: int, localPosts: int, users: record<activeHalfyear: int, activeMonth: int, total: int>>, version: string>
# operationId: getNodeInfo
export def "get-node-info" [
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
    path: "/nodeinfo"
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List users's notification threads
#
# GET /notifications
# Returns: table<id: int, pinned: bool, repository: record<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record, external_wiki: record, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record, parent: any, permissions: record, private: bool, release_counter: int, repo_transfer: record, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>, subject: record<html_url: string, latest_comment_html_url: string, latest_comment_url: string, state: string, title: string, type: string, url: string>, unread: bool, updated_at: string, url: string>
# operationId: notifyGetList
export def "notify-get-list" [
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
  --all: oneof<nothing, bool> # If true, show notifications marked as read. Default value is false
  --status-types: list<string> # Show notifications with the provided status types. Options are: unread, read and/or pinned. Defaults to unread & pinned.
  --subject-type: list<string> # filter notifications by subject type
  --since: string # Only show notifications updated after the given time. This is a timestamp in RFC 3339 format (format: date-time)
  --before: string # Only show notifications updated before the given time. This is a timestamp in RFC 3339 format (format: date-time)
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/notifications"
    query: [{name: all, var: all}, {name: status-types, var: status_types, style: multi}, {name: subject-type, var: subject_type, style: multi}, {name: since, var: since}, {name: before, var: before}, {name: page, var: page}, {name: limit, var: limit}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    all: $all, status_types: $status_types, subject_type: $subject_type, since: $since, before: $before, page: $page, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Mark notification threads as read, pinned or unread
#
# PUT /notifications
# Returns: table<id: int, pinned: bool, repository: record<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record, external_wiki: record, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record, parent: any, permissions: record, private: bool, release_counter: int, repo_transfer: record, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>, subject: record<html_url: string, latest_comment_html_url: string, latest_comment_url: string, state: string, title: string, type: string, url: string>, unread: bool, updated_at: string, url: string>
# operationId: notifyReadList
export def "notify-read-list" [
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
  --last-read-at: string # Describes the last point that notifications were checked. Anything updated since this time will not be updated. (format: date-time)
  --all: string # If true, mark all notifications on this repo. Default value is false
  --status-types: list<string> # Mark notifications with the provided status types. Options are: unread, read and/or pinned. Defaults to unread.
  --to-status: string # Status to mark notifications as, Defaults to read.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: put
    path: "/notifications"
    query: [{name: last_read_at, var: last_read_at}, {name: all, var: all}, {name: status-types, var: status_types, style: multi}, {name: to-status, var: to_status}]
    accept: ["application/json", "text/html"]
    ok: [205]
    auth: basic
  } {
    last_read_at: $last_read_at, all: $all, status_types: $status_types, to_status: $to_status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Check if unread notifications exist
#
# GET /notifications/new
# Returns: record<new: int>
# operationId: notifyNewAvailable
export def "notify-new-available" [
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
    path: "/notifications/new"
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get notification thread by ID
#
# GET /notifications/threads/{id}
# Returns: record<id: int, pinned: bool, repository: record<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record<external_tracker_format: string, external_tracker_regexp_pattern: string, external_tracker_style: string, external_tracker_url: string>, external_wiki: record<external_wiki_url: string>, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record<allow_only_contributors_to_track_time: bool, enable_issue_dependencies: bool, enable_time_tracker: bool>, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, parent: any, permissions: record<admin: bool, pull: bool, push: bool>, private: bool, release_counter: int, repo_transfer: record<doer: record, recipient: record, teams: list>, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>, subject: record<html_url: string, latest_comment_html_url: string, latest_comment_url: string, state: string, title: string, type: string, url: string>, unread: bool, updated_at: string, url: string>
# operationId: notifyGetThread
export def "notify-get-thread" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/notifications/threads/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Mark notification thread as read by ID
#
# PATCH /notifications/threads/{id}
# Returns: record<id: int, pinned: bool, repository: record<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record<external_tracker_format: string, external_tracker_regexp_pattern: string, external_tracker_style: string, external_tracker_url: string>, external_wiki: record<external_wiki_url: string>, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record<allow_only_contributors_to_track_time: bool, enable_issue_dependencies: bool, enable_time_tracker: bool>, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, parent: any, permissions: record<admin: bool, pull: bool, push: bool>, private: bool, release_counter: int, repo_transfer: record<doer: record, recipient: record, teams: list>, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>, subject: record<html_url: string, latest_comment_html_url: string, latest_comment_url: string, state: string, title: string, type: string, url: string>, unread: bool, updated_at: string, url: string>
# operationId: notifyReadThread
export def "notify-read-thread" [
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
  --accept: string@accept-completer # Response content type
  --to-status: string # Status to mark notifications as (default: read)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: patch
    path: "/notifications/threads/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: to-status, var: to_status}]
    accept: ["application/json", "text/html"]
    ok: [205]
    auth: basic
  } {
    id: $id, to_status: $to_status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a repository in an organization
#
# POST /org/{org}/repos
# DEPRECATED
# Returns: record<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record<external_tracker_format: string, external_tracker_regexp_pattern: string, external_tracker_style: string, external_tracker_url: string>, external_wiki: record<external_wiki_url: string>, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record<allow_only_contributors_to_track_time: bool, enable_issue_dependencies: bool, enable_time_tracker: bool>, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, parent: any, permissions: record<admin: bool, pull: bool, push: bool>, private: bool, release_counter: int, repo_transfer: record<doer: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, recipient: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, teams: list<record>>, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>
# operationId: createOrgRepoDeprecated
@deprecated
export def "create-org-repo-deprecated" [
  org: string
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
  --auto-init: oneof<nothing, bool> # Whether the repository should be auto-initialized?
  --default-branch: string # DefaultBranch of the repository (used when initializes and in template)
  --description: string # Description of the repository to create
  --gitignores: string # Gitignores to use
  --issue-labels: string # Label-Set to use
  --license: string # License to use
  name: string # Name of the repository to create
  --private: oneof<nothing, bool> # Whether the repository is private
  --readme: string # Readme of the repository to create
  --template: oneof<nothing, bool> # Whether the repository is template
  --trust-model: string@trust-model-completer # TrustModel of the repository
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/org/{org}/repos"
    path_params: [{name: org, var: org}]
    body: {content_type: "application/json", kind: json, fields: [{name: auto_init, var: auto_init}, {name: default_branch, var: default_branch}, {name: description, var: description}, {name: gitignores, var: gitignores}, {name: issue_labels, var: issue_labels}, {name: license, var: license}, {name: name, var: name}, {name: private, var: private}, {name: readme, var: readme}, {name: template, var: template}, {name: trust_model, var: trust_model}]}
    accept: ["application/json", "text/html"]
    ok: [201]
    auth: basic
  } {
    org: $org, auto_init: $auto_init, default_branch: $default_branch, description: $description, gitignores: $gitignores, issue_labels: $issue_labels, license: $license, name: $name, private: $private, readme: $readme, template: $template, trust_model: $trust_model
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get list of organizations
#
# GET /orgs
# Returns: table<avatar_url: string, description: string, full_name: string, id: int, location: string, name: string, repo_admin_change_team_access: bool, username: string, visibility: string, website: string>
# operationId: orgGetAll
export def "org-get-all" [
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
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/orgs"
    query: [{name: page, var: page}, {name: limit, var: limit}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    page: $page, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create an organization
#
# POST /orgs
# Returns: record<avatar_url: string, description: string, full_name: string, id: int, location: string, name: string, repo_admin_change_team_access: bool, username: string, visibility: string, website: string>
# operationId: orgCreate
export def "org-create" [
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
  --description: string
  --full-name: string
  --location: string
  --repo-admin-change-team-access: oneof<nothing, bool>
  username: string
  --visibility: string@visibility-completer # possible values are `public` (default), `limited` or `private`
  --website: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/orgs"
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: full_name, var: full_name}, {name: location, var: location}, {name: repo_admin_change_team_access, var: repo_admin_change_team_access}, {name: username, var: username}, {name: visibility, var: visibility}, {name: website, var: website}]}
    accept: ["application/json", "text/html"]
    ok: [201]
    auth: basic
  } {
    description: $description, full_name: $full_name, location: $location, repo_admin_change_team_access: $repo_admin_change_team_access, username: $username, visibility: $visibility, website: $website
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete an organization
#
# DELETE /orgs/{org}
# operationId: orgDelete
export def "org-delete" [
  org: string
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
    path: "/orgs/{org}"
    path_params: [{name: org, var: org}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    org: $org
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an organization
#
# GET /orgs/{org}
# Returns: record<avatar_url: string, description: string, full_name: string, id: int, location: string, name: string, repo_admin_change_team_access: bool, username: string, visibility: string, website: string>
# operationId: orgGet
export def "org-get" [
  org: string
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
    path: "/orgs/{org}"
    path_params: [{name: org, var: org}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    org: $org
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Edit an organization
#
# PATCH /orgs/{org}
# Returns: record<avatar_url: string, description: string, full_name: string, id: int, location: string, name: string, repo_admin_change_team_access: bool, username: string, visibility: string, website: string>
# operationId: orgEdit
export def "org-edit" [
  org: string
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
  --description: string
  --full-name: string
  --location: string
  --repo-admin-change-team-access: oneof<nothing, bool>
  --visibility: string@visibility-completer # possible values are `public`, `limited` or `private`
  --website: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/orgs/{org}"
    path_params: [{name: org, var: org}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: full_name, var: full_name}, {name: location, var: location}, {name: repo_admin_change_team_access, var: repo_admin_change_team_access}, {name: visibility, var: visibility}, {name: website, var: website}]}
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    org: $org, description: $description, full_name: $full_name, location: $location, repo_admin_change_team_access: $repo_admin_change_team_access, visibility: $visibility, website: $website
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List an organization's webhooks
#
# GET /orgs/{org}/hooks
# Returns: table<active: bool, authorization_header: string, config: record, created_at: string, events: list<string>, id: int, type: string, updated_at: string>
# operationId: orgListHooks
export def "org-list-hooks" [
  org: string
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
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/orgs/{org}/hooks"
    path_params: [{name: org, var: org}]
    query: [{name: page, var: page}, {name: limit, var: limit}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    org: $org, page: $page, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a hook
#
# POST /orgs/{org}/hooks
# Returns: record<active: bool, authorization_header: string, config: record, created_at: string, events: list<string>, id: int, type: string, updated_at: string>
# operationId: orgCreateHook
export def "org-create-hook" [
  org: string
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
  --active: oneof<nothing, bool> # default: false
  --authorization-header: string
  --branch-filter: string
  config: record # CreateHookOptionConfig has all config options in it required are "content_type" and "url" Required
  --events: list<string>
  type: string@type-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/orgs/{org}/hooks"
    path_params: [{name: org, var: org}]
    body: {content_type: "application/json", kind: json, fields: [{name: active, var: active}, {name: authorization_header, var: authorization_header}, {name: branch_filter, var: branch_filter}, {name: config, var: config}, {name: events, var: events}, {name: type, var: type}]}
    accept: ["application/json", "text/html"]
    ok: [201]
    auth: basic
  } {
    org: $org, active: $active, authorization_header: $authorization_header, branch_filter: $branch_filter, config: $config, events: $events, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a hook
#
# DELETE /orgs/{org}/hooks/{id}
# operationId: orgDeleteHook
export def "org-delete-hook" [
  org: string
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
    path: "/orgs/{org}/hooks/{id}"
    path_params: [{name: org, var: org}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    org: $org, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a hook
#
# GET /orgs/{org}/hooks/{id}
# Returns: record<active: bool, authorization_header: string, config: record, created_at: string, events: list<string>, id: int, type: string, updated_at: string>
# operationId: orgGetHook
export def "org-get-hook" [
  org: string
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/orgs/{org}/hooks/{id}"
    path_params: [{name: org, var: org}, {name: id, var: id}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    org: $org, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a hook
#
# PATCH /orgs/{org}/hooks/{id}
# Returns: record<active: bool, authorization_header: string, config: record, created_at: string, events: list<string>, id: int, type: string, updated_at: string>
# operationId: orgEditHook
export def "org-edit-hook" [
  org: string
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
  --accept: string@accept-completer # Response content type
  --active: oneof<nothing, bool>
  --authorization-header: string
  --branch-filter: string
  --config: record
  --events: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/orgs/{org}/hooks/{id}"
    path_params: [{name: org, var: org}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: active, var: active}, {name: authorization_header, var: authorization_header}, {name: branch_filter, var: branch_filter}, {name: config, var: config}, {name: events, var: events}]}
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    org: $org, id: $id, active: $active, authorization_header: $authorization_header, branch_filter: $branch_filter, config: $config, events: $events
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List an organization's labels
#
# GET /orgs/{org}/labels
# Returns: table<color: string, description: string, exclusive: bool, id: int, name: string, url: string>
# operationId: orgListLabels
export def "org-list-labels" [
  org: string
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
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/orgs/{org}/labels"
    path_params: [{name: org, var: org}]
    query: [{name: page, var: page}, {name: limit, var: limit}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    org: $org, page: $page, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a label for an organization
#
# POST /orgs/{org}/labels
# Returns: record<color: string, description: string, exclusive: bool, id: int, name: string, url: string>
# operationId: orgCreateLabel
export def "org-create-label" [
  org: string
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
  color: string # e.g. #00aabb
  --description: string
  --exclusive: oneof<nothing, bool> # e.g. false
  name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/orgs/{org}/labels"
    path_params: [{name: org, var: org}]
    body: {content_type: "application/json", kind: json, fields: [{name: color, var: color}, {name: description, var: description}, {name: exclusive, var: exclusive}, {name: name, var: name}]}
    accept: ["application/json", "text/html"]
    ok: [201]
    auth: basic
  } {
    org: $org, color: $color, description: $description, exclusive: $exclusive, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a label
#
# DELETE /orgs/{org}/labels/{id}
# operationId: orgDeleteLabel
export def "org-delete-label" [
  org: string
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
    path: "/orgs/{org}/labels/{id}"
    path_params: [{name: org, var: org}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    org: $org, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a single label
#
# GET /orgs/{org}/labels/{id}
# Returns: record<color: string, description: string, exclusive: bool, id: int, name: string, url: string>
# operationId: orgGetLabel
export def "org-get-label" [
  org: string
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/orgs/{org}/labels/{id}"
    path_params: [{name: org, var: org}, {name: id, var: id}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    org: $org, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a label
#
# PATCH /orgs/{org}/labels/{id}
# Returns: record<color: string, description: string, exclusive: bool, id: int, name: string, url: string>
# operationId: orgEditLabel
export def "org-edit-label" [
  org: string
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
  --accept: string@accept-completer # Response content type
  --color: string # e.g. #00aabb
  --description: string
  --exclusive: oneof<nothing, bool> # e.g. false
  --name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/orgs/{org}/labels/{id}"
    path_params: [{name: org, var: org}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: color, var: color}, {name: description, var: description}, {name: exclusive, var: exclusive}, {name: name, var: name}]}
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    org: $org, id: $id, color: $color, description: $description, exclusive: $exclusive, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List an organization's members
#
# GET /orgs/{org}/members
# Returns: table<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>
# operationId: orgListMembers
export def "org-list-members" [
  org: string
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
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/orgs/{org}/members"
    path_params: [{name: org, var: org}]
    query: [{name: page, var: page}, {name: limit, var: limit}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    org: $org, page: $page, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Remove a member from an organization
#
# DELETE /orgs/{org}/members/{username}
# operationId: orgDeleteMember
export def "org-delete-member" [
  org: string
  username: string
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
    path: "/orgs/{org}/members/{username}"
    path_params: [{name: org, var: org}, {name: username, var: username}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    org: $org, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check if a user is a member of an organization
#
# GET /orgs/{org}/members/{username}
# operationId: orgIsMember
export def "org-is-member" [
  org: string
  username: string
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
    path: "/orgs/{org}/members/{username}"
    path_params: [{name: org, var: org}, {name: username, var: username}]
    accept: ["application/json"]
    ok: [204, 303]
    auth: basic
  } {
    org: $org, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List an organization's public members
#
# GET /orgs/{org}/public_members
# Returns: table<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>
# operationId: orgListPublicMembers
export def "org-list-public-members" [
  org: string
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
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/orgs/{org}/public_members"
    path_params: [{name: org, var: org}]
    query: [{name: page, var: page}, {name: limit, var: limit}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    org: $org, page: $page, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Conceal a user's membership
#
# DELETE /orgs/{org}/public_members/{username}
# operationId: orgConcealMember
export def "org-conceal-member" [
  org: string
  username: string
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
    path: "/orgs/{org}/public_members/{username}"
    path_params: [{name: org, var: org}, {name: username, var: username}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    org: $org, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check if a user is a public member of an organization
#
# GET /orgs/{org}/public_members/{username}
# operationId: orgIsPublicMember
export def "org-is-public-member" [
  org: string
  username: string
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
    path: "/orgs/{org}/public_members/{username}"
    path_params: [{name: org, var: org}, {name: username, var: username}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    org: $org, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Publicize a user's membership
#
# PUT /orgs/{org}/public_members/{username}
# operationId: orgPublicizeMember
export def "org-publicize-member" [
  org: string
  username: string
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
    path: "/orgs/{org}/public_members/{username}"
    path_params: [{name: org, var: org}, {name: username, var: username}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    org: $org, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List an organization's repos
#
# GET /orgs/{org}/repos
# Returns: table<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record<external_tracker_format: string, external_tracker_regexp_pattern: string, external_tracker_style: string, external_tracker_url: string>, external_wiki: record<external_wiki_url: string>, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record<allow_only_contributors_to_track_time: bool, enable_issue_dependencies: bool, enable_time_tracker: bool>, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, parent: any, permissions: record<admin: bool, pull: bool, push: bool>, private: bool, release_counter: int, repo_transfer: record<doer: record, recipient: record, teams: list>, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>
# operationId: orgListRepos
export def "org-list-repos" [
  org: string
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
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/orgs/{org}/repos"
    path_params: [{name: org, var: org}]
    query: [{name: page, var: page}, {name: limit, var: limit}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    org: $org, page: $page, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a repository in an organization
#
# POST /orgs/{org}/repos
# Returns: record<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record<external_tracker_format: string, external_tracker_regexp_pattern: string, external_tracker_style: string, external_tracker_url: string>, external_wiki: record<external_wiki_url: string>, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record<allow_only_contributors_to_track_time: bool, enable_issue_dependencies: bool, enable_time_tracker: bool>, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, parent: any, permissions: record<admin: bool, pull: bool, push: bool>, private: bool, release_counter: int, repo_transfer: record<doer: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, recipient: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, teams: list<record>>, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>
# operationId: createOrgRepo
export def "create-org-repo" [
  org: string
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
  --auto-init: oneof<nothing, bool> # Whether the repository should be auto-initialized?
  --default-branch: string # DefaultBranch of the repository (used when initializes and in template)
  --description: string # Description of the repository to create
  --gitignores: string # Gitignores to use
  --issue-labels: string # Label-Set to use
  --license: string # License to use
  name: string # Name of the repository to create
  --private: oneof<nothing, bool> # Whether the repository is private
  --readme: string # Readme of the repository to create
  --template: oneof<nothing, bool> # Whether the repository is template
  --trust-model: string@trust-model-completer # TrustModel of the repository
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/orgs/{org}/repos"
    path_params: [{name: org, var: org}]
    body: {content_type: "application/json", kind: json, fields: [{name: auto_init, var: auto_init}, {name: default_branch, var: default_branch}, {name: description, var: description}, {name: gitignores, var: gitignores}, {name: issue_labels, var: issue_labels}, {name: license, var: license}, {name: name, var: name}, {name: private, var: private}, {name: readme, var: readme}, {name: template, var: template}, {name: trust_model, var: trust_model}]}
    accept: ["application/json", "text/html"]
    ok: [201]
    auth: basic
  } {
    org: $org, auto_init: $auto_init, default_branch: $default_branch, description: $description, gitignores: $gitignores, issue_labels: $issue_labels, license: $license, name: $name, private: $private, readme: $readme, template: $template, trust_model: $trust_model
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List an organization's teams
#
# GET /orgs/{org}/teams
# Returns: table<can_create_org_repo: bool, description: string, id: int, includes_all_repositories: bool, name: string, organization: record<avatar_url: string, description: string, full_name: string, id: int, location: string, name: string, repo_admin_change_team_access: bool, username: string, visibility: string, website: string>, permission: string, units: list<string>, units_map: record>
# operationId: orgListTeams
export def "org-list-teams" [
  org: string
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
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/orgs/{org}/teams"
    path_params: [{name: org, var: org}]
    query: [{name: page, var: page}, {name: limit, var: limit}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    org: $org, page: $page, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a team
#
# POST /orgs/{org}/teams
# Returns: record<can_create_org_repo: bool, description: string, id: int, includes_all_repositories: bool, name: string, organization: record<avatar_url: string, description: string, full_name: string, id: int, location: string, name: string, repo_admin_change_team_access: bool, username: string, visibility: string, website: string>, permission: string, units: list<string>, units_map: record>
# operationId: orgCreateTeam
export def "org-create-team" [
  org: string
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
  --can-create-org-repo: oneof<nothing, bool>
  --description: string
  --includes-all-repositories: oneof<nothing, bool>
  name: string
  --permission: string@permission-completer
  --units: list<string> # e.g. [repo.code, repo.issues, repo.ext_issues, repo.wiki, repo.pulls, repo.releases, repo.projects, repo.ext_wiki]
  --units-map: record # e.g. {repo.code: read, repo.ext_issues: none, repo.ext_wiki: none, repo.issues: write, repo.projects: none, repo.pulls: owner, repo.releases: none, repo.wiki: admin}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/orgs/{org}/teams"
    path_params: [{name: org, var: org}]
    body: {content_type: "application/json", kind: json, fields: [{name: can_create_org_repo, var: can_create_org_repo}, {name: description, var: description}, {name: includes_all_repositories, var: includes_all_repositories}, {name: name, var: name}, {name: permission, var: permission}, {name: units, var: units}, {name: units_map, var: units_map}]}
    accept: ["application/json", "text/html"]
    ok: [201]
    auth: basic
  } {
    org: $org, can_create_org_repo: $can_create_org_repo, description: $description, includes_all_repositories: $includes_all_repositories, name: $name, permission: $permission, units: $units, units_map: $units_map
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Search for teams within an organization
#
# GET /orgs/{org}/teams/search
# Returns: record<data: table<can_create_org_repo: bool, description: string, id: int, includes_all_repositories: bool, name: string, organization: record, permission: string, units: list, units_map: record>, ok: bool>
# operationId: teamSearch
export def "team-search" [
  org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # keywords to search
  --include-desc: oneof<nothing, bool> # include search within team description (defaults to true)
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/orgs/{org}/teams/search"
    path_params: [{name: org, var: org}]
    query: [{name: q, var: q}, {name: include_desc, var: include_desc}, {name: page, var: page}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    org: $org, q: $q, include_desc: $include_desc, page: $page, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all packages of an owner
#
# GET /packages/{owner}
# Returns: table<created_at: string, creator: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, id: int, name: string, owner: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, repository: record<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record, external_wiki: record, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record, parent: any, permissions: record, private: bool, release_counter: int, repo_transfer: record, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>, type: string, version: string>
# operationId: listPackages
export def "list-packages" [
  owner: string
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
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
  --type: string@type-completer-1 # package type filter
  --q: string # name filter
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/packages/{owner}"
    path_params: [{name: owner, var: owner}]
    query: [{name: page, var: page}, {name: limit, var: limit}, {name: type, var: type}, {name: q, var: q}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, page: $page, limit: $limit, type: $type, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a package
#
# DELETE /packages/{owner}/{type}/{name}/{version}
# operationId: deletePackage
export def "delete-package" [
  owner: string
  type: string
  name: string
  version: string
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
    path: "/packages/{owner}/{type}/{name}/{version}"
    path_params: [{name: owner, var: owner}, {name: type, var: type}, {name: name, var: name}, {name: version, var: version}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    owner: $owner, type: $type, name: $name, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a package
#
# GET /packages/{owner}/{type}/{name}/{version}
# Returns: record<created_at: string, creator: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, id: int, name: string, owner: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, repository: record<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record<external_tracker_format: string, external_tracker_regexp_pattern: string, external_tracker_style: string, external_tracker_url: string>, external_wiki: record<external_wiki_url: string>, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record<allow_only_contributors_to_track_time: bool, enable_issue_dependencies: bool, enable_time_tracker: bool>, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, parent: any, permissions: record<admin: bool, pull: bool, push: bool>, private: bool, release_counter: int, repo_transfer: record<doer: record, recipient: record, teams: list>, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>, type: string, version: string>
# operationId: getPackage
export def "get-package" [
  owner: string
  type: string
  name: string
  version: string
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
    path: "/packages/{owner}/{type}/{name}/{version}"
    path_params: [{name: owner, var: owner}, {name: type, var: type}, {name: name, var: name}, {name: version, var: version}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, type: $type, name: $name, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets all files of a package
#
# GET /packages/{owner}/{type}/{name}/{version}/files
# Returns: table<Size: int, id: int, md5: string, name: string, sha1: string, sha256: string, sha512: string>
# operationId: listPackageFiles
export def "list-package-files" [
  owner: string
  type: string
  name: string
  version: string
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
    path: "/packages/{owner}/{type}/{name}/{version}/files"
    path_params: [{name: owner, var: owner}, {name: type, var: type}, {name: name, var: name}, {name: version, var: version}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, type: $type, name: $name, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Search for issues across the repositories that the user has access to
#
# GET /repos/issues/search
# Returns: table<assets: list<record>, assignee: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, assignees: list<record>, body: string, closed_at: string, comments: int, created_at: string, due_date: string, html_url: string, id: int, is_locked: bool, labels: list<record>, milestone: record<closed_at: string, closed_issues: int, created_at: string, description: string, due_on: string, id: int, open_issues: int, state: string, title: string, updated_at: string>, number: int, original_author: string, original_author_id: int, pull_request: record<merged: bool, merged_at: string>, ref: string, repository: record<full_name: string, id: int, name: string, owner: string>, state: string, title: string, updated_at: string, url: string, user: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>>
# operationId: issueSearchIssues
export def "issue-search-issues" [
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
  --state: string # whether issue is open or closed
  --labels: string # comma separated list of labels. Fetch only issues that have any of this labels. Non existent labels are discarded
  --milestones: string # comma separated list of milestone names. Fetch only issues that have any of this milestones. Non existent are discarded
  --q: string # search string
  --priority-repo-id: int # repository to prioritize in the results (format: int64)
  --type: string # filter by type (issues / pulls) if set
  --since: string # Only show notifications updated after the given time. This is a timestamp in RFC 3339 format (format: date-time)
  --before: string # Only show notifications updated before the given time. This is a timestamp in RFC 3339 format (format: date-time)
  --assigned: oneof<nothing, bool> # filter (issues / pulls) assigned to you, default is false
  --created: oneof<nothing, bool> # filter (issues / pulls) created by you, default is false
  --mentioned: oneof<nothing, bool> # filter (issues / pulls) mentioning you, default is false
  --review-requested: oneof<nothing, bool> # filter pulls requesting your review, default is false
  --reviewed: oneof<nothing, bool> # filter pulls reviewed by you, default is false
  --owner: string # filter by owner
  --team: string # filter by team (requires organization owner parameter to be provided)
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/repos/issues/search"
    query: [{name: state, var: state}, {name: labels, var: labels}, {name: milestones, var: milestones}, {name: q, var: q}, {name: priority_repo_id, var: priority_repo_id}, {name: type, var: type}, {name: since, var: since}, {name: before, var: before}, {name: assigned, var: assigned}, {name: created, var: created}, {name: mentioned, var: mentioned}, {name: review_requested, var: review_requested}, {name: reviewed, var: reviewed}, {name: owner, var: owner}, {name: team, var: team}, {name: page, var: page}, {name: limit, var: limit}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    state: $state, labels: $labels, milestones: $milestones, q: $q, priority_repo_id: $priority_repo_id, type: $type, since: $since, before: $before, assigned: $assigned, created: $created, mentioned: $mentioned, review_requested: $review_requested, reviewed: $reviewed, owner: $owner, team: $team, page: $page, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Migrate a remote git repository
#
# POST /repos/migrate
# Returns: record<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record<external_tracker_format: string, external_tracker_regexp_pattern: string, external_tracker_style: string, external_tracker_url: string>, external_wiki: record<external_wiki_url: string>, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record<allow_only_contributors_to_track_time: bool, enable_issue_dependencies: bool, enable_time_tracker: bool>, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, parent: any, permissions: record<admin: bool, pull: bool, push: bool>, private: bool, release_counter: int, repo_transfer: record<doer: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, recipient: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, teams: list<record>>, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>
# operationId: repoMigrate
export def "repo-migrate" [
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
  --auth-password: string
  --auth-token: string
  --auth-username: string
  clone_addr: string
  --description: string
  --issues: oneof<nothing, bool>
  --labels: oneof<nothing, bool>
  --lfs: oneof<nothing, bool>
  --lfs-endpoint: string
  --milestones: oneof<nothing, bool>
  --mirror: oneof<nothing, bool>
  --mirror-interval: string
  --private: oneof<nothing, bool>
  --pull-requests: oneof<nothing, bool>
  --releases: oneof<nothing, bool>
  repo_name: string
  --repo-owner: string # Name of User or Organisation who will own Repo after migration
  --service: string@service-completer
  --uid: int # deprecated (only for backwards compatibility) (format: int64)
  --wiki: oneof<nothing, bool>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/repos/migrate"
    body: {content_type: "application/json", kind: json, fields: [{name: auth_password, var: auth_password}, {name: auth_token, var: auth_token}, {name: auth_username, var: auth_username}, {name: clone_addr, var: clone_addr}, {name: description, var: description}, {name: issues, var: issues}, {name: labels, var: labels}, {name: lfs, var: lfs}, {name: lfs_endpoint, var: lfs_endpoint}, {name: milestones, var: milestones}, {name: mirror, var: mirror}, {name: mirror_interval, var: mirror_interval}, {name: private, var: private}, {name: pull_requests, var: pull_requests}, {name: releases, var: releases}, {name: repo_name, var: repo_name}, {name: repo_owner, var: repo_owner}, {name: service, var: service}, {name: uid, var: uid}, {name: wiki, var: wiki}]}
    accept: ["application/json", "text/html"]
    ok: [201]
    auth: basic
  } {
    auth_password: $auth_password, auth_token: $auth_token, auth_username: $auth_username, clone_addr: $clone_addr, description: $description, issues: $issues, labels: $labels, lfs: $lfs, lfs_endpoint: $lfs_endpoint, milestones: $milestones, mirror: $mirror, mirror_interval: $mirror_interval, private: $private, pull_requests: $pull_requests, releases: $releases, repo_name: $repo_name, repo_owner: $repo_owner, service: $service, uid: $uid, wiki: $wiki
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Search for repositories
#
# GET /repos/search
# Returns: record<data: table<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record, external_wiki: record, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record, parent: any, permissions: record, private: bool, release_counter: int, repo_transfer: record, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>, ok: bool>
# operationId: repoSearch
export def "repo-search" [
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
  --q: string # keyword
  --topic: oneof<nothing, bool> # Limit search to repositories with keyword as topic
  --include-desc: oneof<nothing, bool> # include search of keyword within repository description
  --uid: int # search only for repos that the user with the given id owns or contributes to (format: int64)
  --priority-owner-id: int # repo owner to prioritize in the results (format: int64)
  --team-id: int # search only for repos that belong to the given team id (format: int64)
  --starred-by: int # search only for repos that the user with the given id has starred (format: int64)
  --private: oneof<nothing, bool> # include private repositories this user has access to (defaults to true)
  --is-private: oneof<nothing, bool> # show only pubic, private or all repositories (defaults to all)
  --template: oneof<nothing, bool> # include template repositories this user has access to (defaults to true)
  --archived: oneof<nothing, bool> # show only archived, non-archived or all repositories (defaults to all)
  --mode: string # type of repository to search for. Supported values are "fork", "source", "mirror" and "collaborative"
  --exclusive: oneof<nothing, bool> # if `uid` is given, search only for repos that the user owns
  --sort: string # sort repos by attribute. Supported values are "alpha", "created", "updated", "size", and "id". Default is "alpha"
  --order: string # sort order, either "asc" (ascending) or "desc" (descending). Default is "asc", ignored if "sort" is not specified.
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/repos/search"
    query: [{name: q, var: q}, {name: topic, var: topic}, {name: includeDesc, var: include_desc}, {name: uid, var: uid}, {name: priority_owner_id, var: priority_owner_id}, {name: team_id, var: team_id}, {name: starredBy, var: starred_by}, {name: private, var: private}, {name: is_private, var: is_private}, {name: template, var: template}, {name: archived, var: archived}, {name: mode, var: mode}, {name: exclusive, var: exclusive}, {name: sort, var: sort}, {name: order, var: order}, {name: page, var: page}, {name: limit, var: limit}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    q: $q, topic: $topic, include_desc: $include_desc, uid: $uid, priority_owner_id: $priority_owner_id, team_id: $team_id, starred_by: $starred_by, private: $private, is_private: $is_private, template: $template, archived: $archived, mode: $mode, exclusive: $exclusive, sort: $sort, order: $order, page: $page, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a repository
#
# DELETE /repos/{owner}/{repo}
# operationId: repoDelete
export def "repo-delete" [
  owner: string
  repo: string
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
    path: "/repos/{owner}/{repo}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    owner: $owner, repo: $repo
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a repository
#
# GET /repos/{owner}/{repo}
# Returns: record<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record<external_tracker_format: string, external_tracker_regexp_pattern: string, external_tracker_style: string, external_tracker_url: string>, external_wiki: record<external_wiki_url: string>, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record<allow_only_contributors_to_track_time: bool, enable_issue_dependencies: bool, enable_time_tracker: bool>, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, parent: any, permissions: record<admin: bool, pull: bool, push: bool>, private: bool, release_counter: int, repo_transfer: record<doer: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, recipient: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, teams: list<record>>, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>
# operationId: repoGet
export def "repo-get" [
  owner: string
  repo: string
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
    path: "/repos/{owner}/{repo}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Edit a repository's properties. Only fields that are set will be changed.
#
# PATCH /repos/{owner}/{repo}
# Returns: record<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record<external_tracker_format: string, external_tracker_regexp_pattern: string, external_tracker_style: string, external_tracker_url: string>, external_wiki: record<external_wiki_url: string>, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record<allow_only_contributors_to_track_time: bool, enable_issue_dependencies: bool, enable_time_tracker: bool>, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, parent: any, permissions: record<admin: bool, pull: bool, push: bool>, private: bool, release_counter: int, repo_transfer: record<doer: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, recipient: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, teams: list<record>>, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>
# operationId: repoEdit
export def "repo-edit" [
  owner: string
  repo: string
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
  --allow-manual-merge: oneof<nothing, bool> # either `true` to allow mark pr as merged manually, or `false` to prevent it.
  --allow-merge-commits: oneof<nothing, bool> # either `true` to allow merging pull requests with a merge commit, or `false` to prevent merging pull requests with merge commits.
  --allow-rebase: oneof<nothing, bool> # either `true` to allow rebase-merging pull requests, or `false` to prevent rebase-merging.
  --allow-rebase-explicit: oneof<nothing, bool> # either `true` to allow rebase with explicit merge commits (--no-ff), or `false` to prevent rebase with explicit merge commits.
  --allow-rebase-update: oneof<nothing, bool> # either `true` to allow updating pull request branch by rebase, or `false` to prevent it.
  --allow-squash-merge: oneof<nothing, bool> # either `true` to allow squash-merging pull requests, or `false` to prevent squash-merging.
  --archived: oneof<nothing, bool> # set to `true` to archive this repository.
  --autodetect-manual-merge: oneof<nothing, bool> # either `true` to enable AutodetectManualMerge, or `false` to prevent it. Note: In some special cases, misjudgments can occur.
  --default-allow-maintainer-edit: oneof<nothing, bool> # set to `true` to allow edits from maintainers by default
  --default-branch: string # sets the default branch for this repository.
  --default-delete-branch-after-merge: oneof<nothing, bool> # set to `true` to delete pr branch after merge by default
  --default-merge-style: string # set to a merge style to be used by this repository: "merge", "rebase", "rebase-merge", or "squash".
  --description: string # a short description of the repository.
  --enable-prune: oneof<nothing, bool> # enable prune - remove obsolete remote-tracking references
  --external-tracker: record # ExternalTracker represents settings for external tracker — shape: {external_tracker_format?: string, external_tracker_regexp_pattern?: string, external_tracker_style?: string, external_tracker_url?: string}
  --external-wiki: record # ExternalWiki represents setting for external wiki — shape: {external_wiki_url?: string}
  --has-issues: oneof<nothing, bool> # either `true` to enable issues for this repository or `false` to disable them.
  --has-projects: oneof<nothing, bool> # either `true` to enable project unit, or `false` to disable them.
  --has-pull-requests: oneof<nothing, bool> # either `true` to allow pull requests, or `false` to prevent pull request.
  --has-wiki: oneof<nothing, bool> # either `true` to enable the wiki for this repository or `false` to disable it.
  --ignore-whitespace-conflicts: oneof<nothing, bool> # either `true` to ignore whitespace for conflicts, or `false` to not ignore whitespace.
  --internal-tracker: record # InternalTracker represents settings for internal tracker — shape: {allow_only_contributors_to_track_time?: bool, enable_issue_dependencies?: bool, enable_time_tracker?: bool}
  --mirror-interval: string # set to a string like `8h30m0s` to set the mirror interval time
  --name: string # name of the repository
  --private: oneof<nothing, bool> # either `true` to make the repository private or `false` to make it public. Note: you will get a 422 error if the organization restricts changing repository visibility to organization owners and a non-owner tries to change the value of private.
  --template: oneof<nothing, bool> # either `true` to make this repository a template or `false` to make it a normal repository
  --website: string # a URL with more information about the repository.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/repos/{owner}/{repo}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}]
    body: {content_type: "application/json", kind: json, fields: [{name: allow_manual_merge, var: allow_manual_merge}, {name: allow_merge_commits, var: allow_merge_commits}, {name: allow_rebase, var: allow_rebase}, {name: allow_rebase_explicit, var: allow_rebase_explicit}, {name: allow_rebase_update, var: allow_rebase_update}, {name: allow_squash_merge, var: allow_squash_merge}, {name: archived, var: archived}, {name: autodetect_manual_merge, var: autodetect_manual_merge}, {name: default_allow_maintainer_edit, var: default_allow_maintainer_edit}, {name: default_branch, var: default_branch}, {name: default_delete_branch_after_merge, var: default_delete_branch_after_merge}, {name: default_merge_style, var: default_merge_style}, {name: description, var: description}, {name: enable_prune, var: enable_prune}, {name: external_tracker, var: external_tracker}, {name: external_wiki, var: external_wiki}, {name: has_issues, var: has_issues}, {name: has_projects, var: has_projects}, {name: has_pull_requests, var: has_pull_requests}, {name: has_wiki, var: has_wiki}, {name: ignore_whitespace_conflicts, var: ignore_whitespace_conflicts}, {name: internal_tracker, var: internal_tracker}, {name: mirror_interval, var: mirror_interval}, {name: name, var: name}, {name: private, var: private}, {name: template, var: template}, {name: website, var: website}]}
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, allow_manual_merge: $allow_manual_merge, allow_merge_commits: $allow_merge_commits, allow_rebase: $allow_rebase, allow_rebase_explicit: $allow_rebase_explicit, allow_rebase_update: $allow_rebase_update, allow_squash_merge: $allow_squash_merge, archived: $archived, autodetect_manual_merge: $autodetect_manual_merge, default_allow_maintainer_edit: $default_allow_maintainer_edit, default_branch: $default_branch, default_delete_branch_after_merge: $default_delete_branch_after_merge, default_merge_style: $default_merge_style, description: $description, enable_prune: $enable_prune, external_tracker: $external_tracker, external_wiki: $external_wiki, has_issues: $has_issues, has_projects: $has_projects, has_pull_requests: $has_pull_requests, has_wiki: $has_wiki, ignore_whitespace_conflicts: $ignore_whitespace_conflicts, internal_tracker: $internal_tracker, mirror_interval: $mirror_interval, name: $name, private: $private, template: $template, website: $website
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get an archive of a repository
#
# GET /repos/{owner}/{repo}/archive/{archive}
# operationId: repoGetArchive
export def "repo-get-archive" [
  owner: string
  repo: string
  archive: string
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
    path: "/repos/{owner}/{repo}/archive/{archive}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: archive, var: archive}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, archive: $archive
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return all users that have write access and can be assigned to issues
#
# GET /repos/{owner}/{repo}/assignees
# Returns: table<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>
# operationId: repoGetAssignees
export def "repo-get-assignees" [
  owner: string
  repo: string
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
    path: "/repos/{owner}/{repo}/assignees"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List branch protections for a repository
#
# GET /repos/{owner}/{repo}/branch_protections
# Returns: table<approvals_whitelist_teams: list<string>, approvals_whitelist_username: list<string>, block_on_official_review_requests: bool, block_on_outdated_branch: bool, block_on_rejected_reviews: bool, branch_name: string, created_at: string, dismiss_stale_approvals: bool, enable_approvals_whitelist: bool, enable_merge_whitelist: bool, enable_push: bool, enable_push_whitelist: bool, enable_status_check: bool, merge_whitelist_teams: list<string>, merge_whitelist_usernames: list<string>, protected_file_patterns: string, push_whitelist_deploy_keys: bool, push_whitelist_teams: list<string>, push_whitelist_usernames: list<string>, require_signed_commits: bool, required_approvals: int, rule_name: string, status_check_contexts: list<string>, unprotected_file_patterns: string, updated_at: string>
# operationId: repoListBranchProtection
export def "repo-list-branch-protection" [
  owner: string
  repo: string
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
    path: "/repos/{owner}/{repo}/branch_protections"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a branch protections for a repository
#
# POST /repos/{owner}/{repo}/branch_protections
# Returns: record<approvals_whitelist_teams: list<string>, approvals_whitelist_username: list<string>, block_on_official_review_requests: bool, block_on_outdated_branch: bool, block_on_rejected_reviews: bool, branch_name: string, created_at: string, dismiss_stale_approvals: bool, enable_approvals_whitelist: bool, enable_merge_whitelist: bool, enable_push: bool, enable_push_whitelist: bool, enable_status_check: bool, merge_whitelist_teams: list<string>, merge_whitelist_usernames: list<string>, protected_file_patterns: string, push_whitelist_deploy_keys: bool, push_whitelist_teams: list<string>, push_whitelist_usernames: list<string>, require_signed_commits: bool, required_approvals: int, rule_name: string, status_check_contexts: list<string>, unprotected_file_patterns: string, updated_at: string>
# operationId: repoCreateBranchProtection
export def "repo-create-branch-protection" [
  owner: string
  repo: string
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
  --approvals-whitelist-teams: list<string>
  --approvals-whitelist-username: list<string>
  --block-on-official-review-requests: oneof<nothing, bool>
  --block-on-outdated-branch: oneof<nothing, bool>
  --block-on-rejected-reviews: oneof<nothing, bool>
  --branch-name: string # Deprecated: true
  --dismiss-stale-approvals: oneof<nothing, bool>
  --enable-approvals-whitelist: oneof<nothing, bool>
  --enable-merge-whitelist: oneof<nothing, bool>
  --enable-push: oneof<nothing, bool>
  --enable-push-whitelist: oneof<nothing, bool>
  --enable-status-check: oneof<nothing, bool>
  --merge-whitelist-teams: list<string>
  --merge-whitelist-usernames: list<string>
  --protected-file-patterns: string
  --push-whitelist-deploy-keys: oneof<nothing, bool>
  --push-whitelist-teams: list<string>
  --push-whitelist-usernames: list<string>
  --require-signed-commits: oneof<nothing, bool>
  --required-approvals: int # format: int64
  --rule-name: string
  --status-check-contexts: list<string>
  --unprotected-file-patterns: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/repos/{owner}/{repo}/branch_protections"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}]
    body: {content_type: "application/json", kind: json, fields: [{name: approvals_whitelist_teams, var: approvals_whitelist_teams}, {name: approvals_whitelist_username, var: approvals_whitelist_username}, {name: block_on_official_review_requests, var: block_on_official_review_requests}, {name: block_on_outdated_branch, var: block_on_outdated_branch}, {name: block_on_rejected_reviews, var: block_on_rejected_reviews}, {name: branch_name, var: branch_name}, {name: dismiss_stale_approvals, var: dismiss_stale_approvals}, {name: enable_approvals_whitelist, var: enable_approvals_whitelist}, {name: enable_merge_whitelist, var: enable_merge_whitelist}, {name: enable_push, var: enable_push}, {name: enable_push_whitelist, var: enable_push_whitelist}, {name: enable_status_check, var: enable_status_check}, {name: merge_whitelist_teams, var: merge_whitelist_teams}, {name: merge_whitelist_usernames, var: merge_whitelist_usernames}, {name: protected_file_patterns, var: protected_file_patterns}, {name: push_whitelist_deploy_keys, var: push_whitelist_deploy_keys}, {name: push_whitelist_teams, var: push_whitelist_teams}, {name: push_whitelist_usernames, var: push_whitelist_usernames}, {name: require_signed_commits, var: require_signed_commits}, {name: required_approvals, var: required_approvals}, {name: rule_name, var: rule_name}, {name: status_check_contexts, var: status_check_contexts}, {name: unprotected_file_patterns, var: unprotected_file_patterns}]}
    accept: ["application/json", "text/html"]
    ok: [201]
    auth: basic
  } {
    owner: $owner, repo: $repo, approvals_whitelist_teams: $approvals_whitelist_teams, approvals_whitelist_username: $approvals_whitelist_username, block_on_official_review_requests: $block_on_official_review_requests, block_on_outdated_branch: $block_on_outdated_branch, block_on_rejected_reviews: $block_on_rejected_reviews, branch_name: $branch_name, dismiss_stale_approvals: $dismiss_stale_approvals, enable_approvals_whitelist: $enable_approvals_whitelist, enable_merge_whitelist: $enable_merge_whitelist, enable_push: $enable_push, enable_push_whitelist: $enable_push_whitelist, enable_status_check: $enable_status_check, merge_whitelist_teams: $merge_whitelist_teams, merge_whitelist_usernames: $merge_whitelist_usernames, protected_file_patterns: $protected_file_patterns, push_whitelist_deploy_keys: $push_whitelist_deploy_keys, push_whitelist_teams: $push_whitelist_teams, push_whitelist_usernames: $push_whitelist_usernames, require_signed_commits: $require_signed_commits, required_approvals: $required_approvals, rule_name: $rule_name, status_check_contexts: $status_check_contexts, unprotected_file_patterns: $unprotected_file_patterns
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a specific branch protection for the repository
#
# DELETE /repos/{owner}/{repo}/branch_protections/{name}
# operationId: repoDeleteBranchProtection
export def "repo-delete-branch-protection" [
  owner: string
  repo: string
  name: string
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
    path: "/repos/{owner}/{repo}/branch_protections/{name}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: name, var: name}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    owner: $owner, repo: $repo, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific branch protection for the repository
#
# GET /repos/{owner}/{repo}/branch_protections/{name}
# Returns: record<approvals_whitelist_teams: list<string>, approvals_whitelist_username: list<string>, block_on_official_review_requests: bool, block_on_outdated_branch: bool, block_on_rejected_reviews: bool, branch_name: string, created_at: string, dismiss_stale_approvals: bool, enable_approvals_whitelist: bool, enable_merge_whitelist: bool, enable_push: bool, enable_push_whitelist: bool, enable_status_check: bool, merge_whitelist_teams: list<string>, merge_whitelist_usernames: list<string>, protected_file_patterns: string, push_whitelist_deploy_keys: bool, push_whitelist_teams: list<string>, push_whitelist_usernames: list<string>, require_signed_commits: bool, required_approvals: int, rule_name: string, status_check_contexts: list<string>, unprotected_file_patterns: string, updated_at: string>
# operationId: repoGetBranchProtection
export def "repo-get-branch-protection" [
  owner: string
  repo: string
  name: string
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
    path: "/repos/{owner}/{repo}/branch_protections/{name}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: name, var: name}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Edit a branch protections for a repository. Only fields that are set will be changed
#
# PATCH /repos/{owner}/{repo}/branch_protections/{name}
# Returns: record<approvals_whitelist_teams: list<string>, approvals_whitelist_username: list<string>, block_on_official_review_requests: bool, block_on_outdated_branch: bool, block_on_rejected_reviews: bool, branch_name: string, created_at: string, dismiss_stale_approvals: bool, enable_approvals_whitelist: bool, enable_merge_whitelist: bool, enable_push: bool, enable_push_whitelist: bool, enable_status_check: bool, merge_whitelist_teams: list<string>, merge_whitelist_usernames: list<string>, protected_file_patterns: string, push_whitelist_deploy_keys: bool, push_whitelist_teams: list<string>, push_whitelist_usernames: list<string>, require_signed_commits: bool, required_approvals: int, rule_name: string, status_check_contexts: list<string>, unprotected_file_patterns: string, updated_at: string>
# operationId: repoEditBranchProtection
export def "repo-edit-branch-protection" [
  owner: string
  repo: string
  name: string
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
  --approvals-whitelist-teams: list<string>
  --approvals-whitelist-username: list<string>
  --block-on-official-review-requests: oneof<nothing, bool>
  --block-on-outdated-branch: oneof<nothing, bool>
  --block-on-rejected-reviews: oneof<nothing, bool>
  --dismiss-stale-approvals: oneof<nothing, bool>
  --enable-approvals-whitelist: oneof<nothing, bool>
  --enable-merge-whitelist: oneof<nothing, bool>
  --enable-push: oneof<nothing, bool>
  --enable-push-whitelist: oneof<nothing, bool>
  --enable-status-check: oneof<nothing, bool>
  --merge-whitelist-teams: list<string>
  --merge-whitelist-usernames: list<string>
  --protected-file-patterns: string
  --push-whitelist-deploy-keys: oneof<nothing, bool>
  --push-whitelist-teams: list<string>
  --push-whitelist-usernames: list<string>
  --require-signed-commits: oneof<nothing, bool>
  --required-approvals: int # format: int64
  --status-check-contexts: list<string>
  --unprotected-file-patterns: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/repos/{owner}/{repo}/branch_protections/{name}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: name, var: name}]
    body: {content_type: "application/json", kind: json, fields: [{name: approvals_whitelist_teams, var: approvals_whitelist_teams}, {name: approvals_whitelist_username, var: approvals_whitelist_username}, {name: block_on_official_review_requests, var: block_on_official_review_requests}, {name: block_on_outdated_branch, var: block_on_outdated_branch}, {name: block_on_rejected_reviews, var: block_on_rejected_reviews}, {name: dismiss_stale_approvals, var: dismiss_stale_approvals}, {name: enable_approvals_whitelist, var: enable_approvals_whitelist}, {name: enable_merge_whitelist, var: enable_merge_whitelist}, {name: enable_push, var: enable_push}, {name: enable_push_whitelist, var: enable_push_whitelist}, {name: enable_status_check, var: enable_status_check}, {name: merge_whitelist_teams, var: merge_whitelist_teams}, {name: merge_whitelist_usernames, var: merge_whitelist_usernames}, {name: protected_file_patterns, var: protected_file_patterns}, {name: push_whitelist_deploy_keys, var: push_whitelist_deploy_keys}, {name: push_whitelist_teams, var: push_whitelist_teams}, {name: push_whitelist_usernames, var: push_whitelist_usernames}, {name: require_signed_commits, var: require_signed_commits}, {name: required_approvals, var: required_approvals}, {name: status_check_contexts, var: status_check_contexts}, {name: unprotected_file_patterns, var: unprotected_file_patterns}]}
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, name: $name, approvals_whitelist_teams: $approvals_whitelist_teams, approvals_whitelist_username: $approvals_whitelist_username, block_on_official_review_requests: $block_on_official_review_requests, block_on_outdated_branch: $block_on_outdated_branch, block_on_rejected_reviews: $block_on_rejected_reviews, dismiss_stale_approvals: $dismiss_stale_approvals, enable_approvals_whitelist: $enable_approvals_whitelist, enable_merge_whitelist: $enable_merge_whitelist, enable_push: $enable_push, enable_push_whitelist: $enable_push_whitelist, enable_status_check: $enable_status_check, merge_whitelist_teams: $merge_whitelist_teams, merge_whitelist_usernames: $merge_whitelist_usernames, protected_file_patterns: $protected_file_patterns, push_whitelist_deploy_keys: $push_whitelist_deploy_keys, push_whitelist_teams: $push_whitelist_teams, push_whitelist_usernames: $push_whitelist_usernames, require_signed_commits: $require_signed_commits, required_approvals: $required_approvals, status_check_contexts: $status_check_contexts, unprotected_file_patterns: $unprotected_file_patterns
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List a repository's branches
#
# GET /repos/{owner}/{repo}/branches
# Returns: table<commit: record<added: list, author: record, committer: record, id: string, message: string, modified: list, removed: list, timestamp: string, url: string, verification: record>, effective_branch_protection_name: string, enable_status_check: bool, name: string, protected: bool, required_approvals: int, status_check_contexts: list<string>, user_can_merge: bool, user_can_push: bool>
# operationId: repoListBranches
export def "repo-list-branches" [
  owner: string
  repo: string
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
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/repos/{owner}/{repo}/branches"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}]
    query: [{name: page, var: page}, {name: limit, var: limit}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, page: $page, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a branch
#
# POST /repos/{owner}/{repo}/branches
# Returns: record<commit: record<added: list<string>, author: record<email: string, name: string, username: string>, committer: record<email: string, name: string, username: string>, id: string, message: string, modified: list<string>, removed: list<string>, timestamp: string, url: string, verification: record<payload: string, reason: string, signature: string, signer: record, verified: bool>>, effective_branch_protection_name: string, enable_status_check: bool, name: string, protected: bool, required_approvals: int, status_check_contexts: list<string>, user_can_merge: bool, user_can_push: bool>
# operationId: repoCreateBranch
export def "repo-create-branch" [
  owner: string
  repo: string
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
  new_branch_name: string # Name of the branch to create
  --old-branch-name: string # Name of the old branch to create from
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/repos/{owner}/{repo}/branches"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}]
    body: {content_type: "application/json", kind: json, fields: [{name: new_branch_name, var: new_branch_name}, {name: old_branch_name, var: old_branch_name}]}
    accept: ["application/json", "text/html"]
    ok: [201]
    auth: basic
  } {
    owner: $owner, repo: $repo, new_branch_name: $new_branch_name, old_branch_name: $old_branch_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a specific branch from a repository
#
# DELETE /repos/{owner}/{repo}/branches/{branch}
# operationId: repoDeleteBranch
export def "repo-delete-branch" [
  owner: string
  repo: string
  branch: string
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
    path: "/repos/{owner}/{repo}/branches/{branch}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: branch, var: branch}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    owner: $owner, repo: $repo, branch: $branch
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a specific branch from a repository, including its effective branch protection
#
# GET /repos/{owner}/{repo}/branches/{branch}
# Returns: record<commit: record<added: list<string>, author: record<email: string, name: string, username: string>, committer: record<email: string, name: string, username: string>, id: string, message: string, modified: list<string>, removed: list<string>, timestamp: string, url: string, verification: record<payload: string, reason: string, signature: string, signer: record, verified: bool>>, effective_branch_protection_name: string, enable_status_check: bool, name: string, protected: bool, required_approvals: int, status_check_contexts: list<string>, user_can_merge: bool, user_can_push: bool>
# operationId: repoGetBranch
export def "repo-get-branch" [
  owner: string
  repo: string
  branch: string
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
    path: "/repos/{owner}/{repo}/branches/{branch}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: branch, var: branch}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, branch: $branch
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List a repository's collaborators
#
# GET /repos/{owner}/{repo}/collaborators
# Returns: table<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>
# operationId: repoListCollaborators
export def "repo-list-collaborators" [
  owner: string
  repo: string
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
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/repos/{owner}/{repo}/collaborators"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}]
    query: [{name: page, var: page}, {name: limit, var: limit}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, page: $page, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a collaborator from a repository
#
# DELETE /repos/{owner}/{repo}/collaborators/{collaborator}
# operationId: repoDeleteCollaborator
export def "repo-delete-collaborator" [
  owner: string
  repo: string
  collaborator: string
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
    path: "/repos/{owner}/{repo}/collaborators/{collaborator}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: collaborator, var: collaborator}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    owner: $owner, repo: $repo, collaborator: $collaborator
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check if a user is a collaborator of a repository
#
# GET /repos/{owner}/{repo}/collaborators/{collaborator}
# operationId: repoCheckCollaborator
export def "repo-check-collaborator" [
  owner: string
  repo: string
  collaborator: string
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
    path: "/repos/{owner}/{repo}/collaborators/{collaborator}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: collaborator, var: collaborator}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    owner: $owner, repo: $repo, collaborator: $collaborator
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a collaborator to a repository
#
# PUT /repos/{owner}/{repo}/collaborators/{collaborator}
# operationId: repoAddCollaborator
export def "repo-add-collaborator" [
  owner: string
  repo: string
  collaborator: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --permission: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/repos/{owner}/{repo}/collaborators/{collaborator}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: collaborator, var: collaborator}]
    body: {content_type: "application/json", kind: json, fields: [{name: permission, var: permission}]}
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    owner: $owner, repo: $repo, collaborator: $collaborator, permission: $permission
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get repository permissions for a user
#
# GET /repos/{owner}/{repo}/collaborators/{collaborator}/permission
# Returns: record<permission: string, role_name: string, user: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>>
# operationId: repoGetRepoPermissions
export def "repo-get-repo-permissions" [
  owner: string
  repo: string
  collaborator: string
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
    path: "/repos/{owner}/{repo}/collaborators/{collaborator}/permission"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: collaborator, var: collaborator}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, collaborator: $collaborator
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a list of all commits from a repository
#
# GET /repos/{owner}/{repo}/commits
# Returns: table<author: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, commit: record<author: record, committer: record, message: string, tree: record, url: string, verification: record>, committer: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, created: string, files: list<record>, html_url: string, parents: list<record>, sha: string, stats: record<additions: int, deletions: int, total: int>, url: string>
# operationId: repoGetAllCommits
export def "repo-get-all-commits" [
  owner: string
  repo: string
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
  --sha: string # SHA or branch to start listing commits from (usually 'master')
  --path: string # filepath of a file/dir
  --stat: oneof<nothing, bool> # include diff stats for every commit (disable for speedup, default 'true')
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results (ignored if used with 'path')
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/repos/{owner}/{repo}/commits"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}]
    query: [{name: sha, var: sha}, {name: path, var: path}, {name: stat, var: stat}, {name: page, var: page}, {name: limit, var: limit}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, sha: $sha, path: $path, stat: $stat, page: $page, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a commit's combined status, by branch/tag/commit reference
#
# GET /repos/{owner}/{repo}/commits/{ref}/status
# Returns: record<commit_url: string, repository: record<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record<external_tracker_format: string, external_tracker_regexp_pattern: string, external_tracker_style: string, external_tracker_url: string>, external_wiki: record<external_wiki_url: string>, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record<allow_only_contributors_to_track_time: bool, enable_issue_dependencies: bool, enable_time_tracker: bool>, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, parent: any, permissions: record<admin: bool, pull: bool, push: bool>, private: bool, release_counter: int, repo_transfer: record<doer: record, recipient: record, teams: list>, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>, sha: string, state: string, statuses: table<context: string, created_at: string, creator: record, description: string, id: int, status: string, target_url: string, updated_at: string, url: string>, total_count: int, url: string>
# operationId: repoGetCombinedStatusByRef
export def "repo-get-combined-status-by-ref" [
  owner: string
  repo: string
  ref: string
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
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/repos/{owner}/{repo}/commits/{ref}/status"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: ref, var: ref}]
    query: [{name: page, var: page}, {name: limit, var: limit}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, ref: $ref, page: $page, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a commit's statuses, by branch/tag/commit reference
#
# GET /repos/{owner}/{repo}/commits/{ref}/statuses
# Returns: table<context: string, created_at: string, creator: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, description: string, id: int, status: string, target_url: string, updated_at: string, url: string>
# operationId: repoListStatusesByRef
export def "repo-list-statuses-by-ref" [
  owner: string
  repo: string
  ref: string
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
  --sort: string@sort-completer # type of sort
  --state: string@state-completer # type of state
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/repos/{owner}/{repo}/commits/{ref}/statuses"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: ref, var: ref}]
    query: [{name: sort, var: sort}, {name: state, var: state}, {name: page, var: page}, {name: limit, var: limit}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, ref: $ref, sort: $sort, state: $state, page: $page, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the metadata of all the entries of the root dir
#
# GET /repos/{owner}/{repo}/contents
# Returns: table<_links: record<git: string, html: string, self: string>, content: string, download_url: string, encoding: string, git_url: string, html_url: string, last_commit_sha: string, name: string, path: string, sha: string, size: int, submodule_git_url: string, target: string, type: string, url: string>
# operationId: repoGetContentsList
export def "repo-get-contents-list" [
  owner: string
  repo: string
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
  --ref: string # The name of the commit/branch/tag. Default the repository’s default branch (usually master)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/repos/{owner}/{repo}/contents"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}]
    query: [{name: ref, var: ref}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, ref: $ref
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a file in a repository
#
# DELETE /repos/{owner}/{repo}/contents/{filepath}
# Returns: record<commit: record<author: record<date: string, email: string, name: string>, committer: record<date: string, email: string, name: string>, created: string, html_url: string, message: string, parents: list<record>, sha: string, tree: record<created: string, sha: string, url: string>, url: string>, content: any, verification: record<payload: string, reason: string, signature: string, signer: record<email: string, name: string, username: string>, verified: bool>>
# operationId: repoDeleteFile
export def "repo-delete-file" [
  owner: string
  repo: string
  filepath: string
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
  --author: record # Identity for a person's identity like an author or committer — shape: {email?: string, name?: string}
  --branch: string # branch (optional) to base this file from. if not given, the default branch is used
  --committer: record # Identity for a person's identity like an author or committer — shape: {email?: string, name?: string}
  --dates: record # CommitDateOptions store dates for GIT_AUTHOR_DATE and GIT_COMMITTER_DATE — shape: {author?: string, committer?: string}
  --message: string # message (optional) for the commit of this file. if not supplied, a default message will be used
  --new-branch: string # new_branch (optional) will make a new branch from `branch` before creating the file
  sha: string # sha is the SHA for the file that already exists
  --signoff: oneof<nothing, bool> # Add a Signed-off-by trailer by the committer at the end of the commit log message.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: delete
    path: "/repos/{owner}/{repo}/contents/{filepath}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: filepath, var: filepath}]
    body: {content_type: "application/json", kind: json, fields: [{name: author, var: author}, {name: branch, var: branch}, {name: committer, var: committer}, {name: dates, var: dates}, {name: message, var: message}, {name: new_branch, var: new_branch}, {name: sha, var: sha}, {name: signoff, var: signoff}]}
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, filepath: $filepath, author: $author, branch: $branch, committer: $committer, dates: $dates, message: $message, new_branch: $new_branch, sha: $sha, signoff: $signoff
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the metadata and contents (if a file) of an entry in a repository, or a list of entries if a dir
#
# GET /repos/{owner}/{repo}/contents/{filepath}
# Returns: record<_links: record<git: string, html: string, self: string>, content: string, download_url: string, encoding: string, git_url: string, html_url: string, last_commit_sha: string, name: string, path: string, sha: string, size: int, submodule_git_url: string, target: string, type: string, url: string>
# operationId: repoGetContents
export def "repo-get-contents" [
  owner: string
  repo: string
  filepath: string
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
  --ref: string # The name of the commit/branch/tag. Default the repository’s default branch (usually master)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/repos/{owner}/{repo}/contents/{filepath}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: filepath, var: filepath}]
    query: [{name: ref, var: ref}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, filepath: $filepath, ref: $ref
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a file in a repository
#
# POST /repos/{owner}/{repo}/contents/{filepath}
# Returns: record<commit: record<author: record<date: string, email: string, name: string>, committer: record<date: string, email: string, name: string>, created: string, html_url: string, message: string, parents: list<record>, sha: string, tree: record<created: string, sha: string, url: string>, url: string>, content: record<_links: record<git: string, html: string, self: string>, content: string, download_url: string, encoding: string, git_url: string, html_url: string, last_commit_sha: string, name: string, path: string, sha: string, size: int, submodule_git_url: string, target: string, type: string, url: string>, verification: record<payload: string, reason: string, signature: string, signer: record<email: string, name: string, username: string>, verified: bool>>
# operationId: repoCreateFile
export def "repo-create-file" [
  owner: string
  repo: string
  filepath: string
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
  --author: record # Identity for a person's identity like an author or committer — shape: {email?: string, name?: string}
  --branch: string # branch (optional) to base this file from. if not given, the default branch is used
  --committer: record # Identity for a person's identity like an author or committer — shape: {email?: string, name?: string}
  content: string # content must be base64 encoded
  --dates: record # CommitDateOptions store dates for GIT_AUTHOR_DATE and GIT_COMMITTER_DATE — shape: {author?: string, committer?: string}
  --message: string # message (optional) for the commit of this file. if not supplied, a default message will be used
  --new-branch: string # new_branch (optional) will make a new branch from `branch` before creating the file
  --signoff: oneof<nothing, bool> # Add a Signed-off-by trailer by the committer at the end of the commit log message.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/repos/{owner}/{repo}/contents/{filepath}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: filepath, var: filepath}]
    body: {content_type: "application/json", kind: json, fields: [{name: author, var: author}, {name: branch, var: branch}, {name: committer, var: committer}, {name: content, var: content}, {name: dates, var: dates}, {name: message, var: message}, {name: new_branch, var: new_branch}, {name: signoff, var: signoff}]}
    accept: ["application/json", "text/html"]
    ok: [201]
    auth: basic
  } {
    owner: $owner, repo: $repo, filepath: $filepath, author: $author, branch: $branch, committer: $committer, content: $content, dates: $dates, message: $message, new_branch: $new_branch, signoff: $signoff
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a file in a repository
#
# PUT /repos/{owner}/{repo}/contents/{filepath}
# Returns: record<commit: record<author: record<date: string, email: string, name: string>, committer: record<date: string, email: string, name: string>, created: string, html_url: string, message: string, parents: list<record>, sha: string, tree: record<created: string, sha: string, url: string>, url: string>, content: record<_links: record<git: string, html: string, self: string>, content: string, download_url: string, encoding: string, git_url: string, html_url: string, last_commit_sha: string, name: string, path: string, sha: string, size: int, submodule_git_url: string, target: string, type: string, url: string>, verification: record<payload: string, reason: string, signature: string, signer: record<email: string, name: string, username: string>, verified: bool>>
# operationId: repoUpdateFile
export def "repo-update-file" [
  owner: string
  repo: string
  filepath: string
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
  --author: record # Identity for a person's identity like an author or committer — shape: {email?: string, name?: string}
  --branch: string # branch (optional) to base this file from. if not given, the default branch is used
  --committer: record # Identity for a person's identity like an author or committer — shape: {email?: string, name?: string}
  content: string # content must be base64 encoded
  --dates: record # CommitDateOptions store dates for GIT_AUTHOR_DATE and GIT_COMMITTER_DATE — shape: {author?: string, committer?: string}
  --from-path: string # from_path (optional) is the path of the original file which will be moved/renamed to the path in the URL
  --message: string # message (optional) for the commit of this file. if not supplied, a default message will be used
  --new-branch: string # new_branch (optional) will make a new branch from `branch` before creating the file
  sha: string # sha is the SHA for the file that already exists
  --signoff: oneof<nothing, bool> # Add a Signed-off-by trailer by the committer at the end of the commit log message.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/repos/{owner}/{repo}/contents/{filepath}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: filepath, var: filepath}]
    body: {content_type: "application/json", kind: json, fields: [{name: author, var: author}, {name: branch, var: branch}, {name: committer, var: committer}, {name: content, var: content}, {name: dates, var: dates}, {name: from_path, var: from_path}, {name: message, var: message}, {name: new_branch, var: new_branch}, {name: sha, var: sha}, {name: signoff, var: signoff}]}
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, filepath: $filepath, author: $author, branch: $branch, committer: $committer, content: $content, dates: $dates, from_path: $from_path, message: $message, new_branch: $new_branch, sha: $sha, signoff: $signoff
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Apply diff patch to repository
#
# POST /repos/{owner}/{repo}/diffpatch
# Returns: record<commit: record<author: record<date: string, email: string, name: string>, committer: record<date: string, email: string, name: string>, created: string, html_url: string, message: string, parents: list<record>, sha: string, tree: record<created: string, sha: string, url: string>, url: string>, content: record<_links: record<git: string, html: string, self: string>, content: string, download_url: string, encoding: string, git_url: string, html_url: string, last_commit_sha: string, name: string, path: string, sha: string, size: int, submodule_git_url: string, target: string, type: string, url: string>, verification: record<payload: string, reason: string, signature: string, signer: record<email: string, name: string, username: string>, verified: bool>>
# operationId: repoApplyDiffPatch
export def "repo-apply-diff-patch" [
  owner: string
  repo: string
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
  --author: record # Identity for a person's identity like an author or committer — shape: {email?: string, name?: string}
  --branch: string # branch (optional) to base this file from. if not given, the default branch is used
  --committer: record # Identity for a person's identity like an author or committer — shape: {email?: string, name?: string}
  content: string # content must be base64 encoded
  --dates: record # CommitDateOptions store dates for GIT_AUTHOR_DATE and GIT_COMMITTER_DATE — shape: {author?: string, committer?: string}
  --from-path: string # from_path (optional) is the path of the original file which will be moved/renamed to the path in the URL
  --message: string # message (optional) for the commit of this file. if not supplied, a default message will be used
  --new-branch: string # new_branch (optional) will make a new branch from `branch` before creating the file
  sha: string # sha is the SHA for the file that already exists
  --signoff: oneof<nothing, bool> # Add a Signed-off-by trailer by the committer at the end of the commit log message.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/repos/{owner}/{repo}/diffpatch"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}]
    body: {content_type: "application/json", kind: json, fields: [{name: author, var: author}, {name: branch, var: branch}, {name: committer, var: committer}, {name: content, var: content}, {name: dates, var: dates}, {name: from_path, var: from_path}, {name: message, var: message}, {name: new_branch, var: new_branch}, {name: sha, var: sha}, {name: signoff, var: signoff}]}
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, author: $author, branch: $branch, committer: $committer, content: $content, dates: $dates, from_path: $from_path, message: $message, new_branch: $new_branch, sha: $sha, signoff: $signoff
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get the EditorConfig definitions of a file in a repository
#
# GET /repos/{owner}/{repo}/editorconfig/{filepath}
# operationId: repoGetEditorConfig
export def "repo-get-editor-config" [
  owner: string
  repo: string
  filepath: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ref: string # The name of the commit/branch/tag. Default the repository’s default branch (usually master)
]: nothing -> any {
  http-request {
    method: get
    path: "/repos/{owner}/{repo}/editorconfig/{filepath}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: filepath, var: filepath}]
    query: [{name: ref, var: ref}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, filepath: $filepath, ref: $ref
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List a repository's forks
#
# GET /repos/{owner}/{repo}/forks
# Returns: table<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record<external_tracker_format: string, external_tracker_regexp_pattern: string, external_tracker_style: string, external_tracker_url: string>, external_wiki: record<external_wiki_url: string>, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record<allow_only_contributors_to_track_time: bool, enable_issue_dependencies: bool, enable_time_tracker: bool>, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, parent: any, permissions: record<admin: bool, pull: bool, push: bool>, private: bool, release_counter: int, repo_transfer: record<doer: record, recipient: record, teams: list>, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>
# operationId: listForks
export def "list-forks" [
  owner: string
  repo: string
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
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/repos/{owner}/{repo}/forks"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}]
    query: [{name: page, var: page}, {name: limit, var: limit}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, page: $page, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Fork a repository
#
# POST /repos/{owner}/{repo}/forks
# Returns: record<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record<external_tracker_format: string, external_tracker_regexp_pattern: string, external_tracker_style: string, external_tracker_url: string>, external_wiki: record<external_wiki_url: string>, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record<allow_only_contributors_to_track_time: bool, enable_issue_dependencies: bool, enable_time_tracker: bool>, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, parent: any, permissions: record<admin: bool, pull: bool, push: bool>, private: bool, release_counter: int, repo_transfer: record<doer: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, recipient: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, teams: list<record>>, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>
# operationId: createFork
export def "create-fork" [
  owner: string
  repo: string
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
  --name: string # name of the forked repository
  --organization: string # organization name, if forking into an organization
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/repos/{owner}/{repo}/forks"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: organization, var: organization}]}
    accept: ["application/json", "text/html"]
    ok: [202]
    auth: basic
  } {
    owner: $owner, repo: $repo, name: $name, organization: $organization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the blob of a repository.
#
# GET /repos/{owner}/{repo}/git/blobs/{sha}
# Returns: record<content: string, encoding: string, sha: string, size: int, url: string>
# operationId: GetBlob
export def "get-blob" [
  owner: string
  repo: string
  sha: string
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
    path: "/repos/{owner}/{repo}/git/blobs/{sha}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: sha, var: sha}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, sha: $sha
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a single commit from a repository
#
# GET /repos/{owner}/{repo}/git/commits/{sha}
# Returns: record<author: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, commit: record<author: record<date: string, email: string, name: string>, committer: record<date: string, email: string, name: string>, message: string, tree: record<created: string, sha: string, url: string>, url: string, verification: record<payload: string, reason: string, signature: string, signer: record, verified: bool>>, committer: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, created: string, files: table<filename: string>, html_url: string, parents: table<created: string, sha: string, url: string>, sha: string, stats: record<additions: int, deletions: int, total: int>, url: string>
# operationId: repoGetSingleCommit
export def "repo-get-single-commit" [
  owner: string
  repo: string
  sha: string
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
    path: "/repos/{owner}/{repo}/git/commits/{sha}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: sha, var: sha}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, sha: $sha
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a commit's diff or patch
#
# GET /repos/{owner}/{repo}/git/commits/{sha}.{diffType}
# Returns: string
# operationId: repoDownloadCommitDiffOrPatch
export def "repo-download-commit-diff-or-patch" [
  owner: string
  repo: string
  sha: string
  diff_type: string@diff-type-completer
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
    path: "/repos/{owner}/{repo}/git/commits/{sha}.{diffType}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: sha, var: sha}, {name: diffType, var: diff_type}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, sha: $sha, diff_type: $diff_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a note corresponding to a single commit from a repository
#
# GET /repos/{owner}/{repo}/git/notes/{sha}
# Returns: record<commit: record<author: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, commit: record<author: record, committer: record, message: string, tree: record, url: string, verification: record>, committer: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, created: string, files: list<record>, html_url: string, parents: list<record>, sha: string, stats: record<additions: int, deletions: int, total: int>, url: string>, message: string>
# operationId: repoGetNote
export def "repo-get-note" [
  owner: string
  repo: string
  sha: string
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
    path: "/repos/{owner}/{repo}/git/notes/{sha}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: sha, var: sha}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, sha: $sha
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get specified ref or filtered repository's refs
#
# GET /repos/{owner}/{repo}/git/refs
# Returns: table<object: record<sha: string, type: string, url: string>, ref: string, url: string>
# operationId: repoListAllGitRefs
export def "repo-list-all-git-refs" [
  owner: string
  repo: string
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
    path: "/repos/{owner}/{repo}/git/refs"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get specified ref or filtered repository's refs
#
# GET /repos/{owner}/{repo}/git/refs/{ref}
# Returns: table<object: record<sha: string, type: string, url: string>, ref: string, url: string>
# operationId: repoListGitRefs
export def "repo-list-git-refs" [
  owner: string
  repo: string
  ref: string
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
    path: "/repos/{owner}/{repo}/git/refs/{ref}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: ref, var: ref}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, ref: $ref
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the tag object of an annotated tag (not lightweight tags)
#
# GET /repos/{owner}/{repo}/git/tags/{sha}
# Returns: record<message: string, object: record<sha: string, type: string, url: string>, sha: string, tag: string, tagger: record<date: string, email: string, name: string>, url: string, verification: record<payload: string, reason: string, signature: string, signer: record<email: string, name: string, username: string>, verified: bool>>
# operationId: GetAnnotatedTag
export def "get-annotated-tag" [
  owner: string
  repo: string
  sha: string
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
    path: "/repos/{owner}/{repo}/git/tags/{sha}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: sha, var: sha}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, sha: $sha
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the tree of a repository.
#
# GET /repos/{owner}/{repo}/git/trees/{sha}
# Returns: record<page: int, sha: string, total_count: int, tree: table<mode: string, path: string, sha: string, size: int, type: string, url: string>, truncated: bool, url: string>
# operationId: GetTree
export def "get-tree" [
  owner: string
  repo: string
  sha: string
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
  --recursive: oneof<nothing, bool> # show all directories and files
  --page: int # page number; the 'truncated' field in the response will be true if there are still more items after this page, false if the last page
  --per-page: int # number of items per page
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/repos/{owner}/{repo}/git/trees/{sha}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: sha, var: sha}]
    query: [{name: recursive, var: recursive}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, sha: $sha, recursive: $recursive, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List the hooks in a repository
#
# GET /repos/{owner}/{repo}/hooks
# Returns: table<active: bool, authorization_header: string, config: record, created_at: string, events: list<string>, id: int, type: string, updated_at: string>
# operationId: repoListHooks
export def "repo-list-hooks" [
  owner: string
  repo: string
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
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/repos/{owner}/{repo}/hooks"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}]
    query: [{name: page, var: page}, {name: limit, var: limit}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, page: $page, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a hook
#
# POST /repos/{owner}/{repo}/hooks
# Returns: record<active: bool, authorization_header: string, config: record, created_at: string, events: list<string>, id: int, type: string, updated_at: string>
# operationId: repoCreateHook
export def "repo-create-hook" [
  owner: string
  repo: string
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
  --active: oneof<nothing, bool> # default: false
  --authorization-header: string
  --branch-filter: string
  config: record # CreateHookOptionConfig has all config options in it required are "content_type" and "url" Required
  --events: list<string>
  type: string@type-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/repos/{owner}/{repo}/hooks"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}]
    body: {content_type: "application/json", kind: json, fields: [{name: active, var: active}, {name: authorization_header, var: authorization_header}, {name: branch_filter, var: branch_filter}, {name: config, var: config}, {name: events, var: events}, {name: type, var: type}]}
    accept: ["application/json", "text/html"]
    ok: [201]
    auth: basic
  } {
    owner: $owner, repo: $repo, active: $active, authorization_header: $authorization_header, branch_filter: $branch_filter, config: $config, events: $events, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List the Git hooks in a repository
#
# GET /repos/{owner}/{repo}/hooks/git
# Returns: table<content: string, is_active: bool, name: string>
# operationId: repoListGitHooks
export def "repo-list-git-hooks" [
  owner: string
  repo: string
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
    path: "/repos/{owner}/{repo}/hooks/git"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a Git hook in a repository
#
# DELETE /repos/{owner}/{repo}/hooks/git/{id}
# operationId: repoDeleteGitHook
export def "repo-delete-git-hook" [
  owner: string
  repo: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/repos/{owner}/{repo}/hooks/git/{id}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    owner: $owner, repo: $repo, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a Git hook
#
# GET /repos/{owner}/{repo}/hooks/git/{id}
# Returns: record<content: string, is_active: bool, name: string>
# operationId: repoGetGitHook
export def "repo-get-git-hook" [
  owner: string
  repo: string
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/repos/{owner}/{repo}/hooks/git/{id}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: id, var: id}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Edit a Git hook in a repository
#
# PATCH /repos/{owner}/{repo}/hooks/git/{id}
# Returns: record<content: string, is_active: bool, name: string>
# operationId: repoEditGitHook
export def "repo-edit-git-hook" [
  owner: string
  repo: string
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
  --accept: string@accept-completer # Response content type
  --content: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/repos/{owner}/{repo}/hooks/git/{id}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: content, var: content}]}
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, id: $id, content: $content
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a hook in a repository
#
# DELETE /repos/{owner}/{repo}/hooks/{id}
# operationId: repoDeleteHook
export def "repo-delete-hook" [
  owner: string
  repo: string
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
    path: "/repos/{owner}/{repo}/hooks/{id}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    owner: $owner, repo: $repo, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a hook
#
# GET /repos/{owner}/{repo}/hooks/{id}
# Returns: record<active: bool, authorization_header: string, config: record, created_at: string, events: list<string>, id: int, type: string, updated_at: string>
# operationId: repoGetHook
export def "repo-get-hook" [
  owner: string
  repo: string
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/repos/{owner}/{repo}/hooks/{id}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: id, var: id}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Edit a hook in a repository
#
# PATCH /repos/{owner}/{repo}/hooks/{id}
# Returns: record<active: bool, authorization_header: string, config: record, created_at: string, events: list<string>, id: int, type: string, updated_at: string>
# operationId: repoEditHook
export def "repo-edit-hook" [
  owner: string
  repo: string
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
  --accept: string@accept-completer # Response content type
  --active: oneof<nothing, bool>
  --authorization-header: string
  --branch-filter: string
  --config: record
  --events: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/repos/{owner}/{repo}/hooks/{id}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: active, var: active}, {name: authorization_header, var: authorization_header}, {name: branch_filter, var: branch_filter}, {name: config, var: config}, {name: events, var: events}]}
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, id: $id, active: $active, authorization_header: $authorization_header, branch_filter: $branch_filter, config: $config, events: $events
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Test a push webhook
#
# POST /repos/{owner}/{repo}/hooks/{id}/tests
# operationId: repoTestHook
export def "repo-test-hook" [
  owner: string
  repo: string
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
  --ref: string # The name of the commit/branch/tag, indicates which commit will be loaded to the webhook payload.
]: nothing -> any {
  http-request {
    method: post
    path: "/repos/{owner}/{repo}/hooks/{id}/tests"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: id, var: id}]
    query: [{name: ref, var: ref}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    owner: $owner, repo: $repo, id: $id, ref: $ref
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get available issue templates for a repository
#
# GET /repos/{owner}/{repo}/issue_templates
# Returns: table<about: string, body: list<record>, content: string, file_name: string, labels: list<string>, name: string, ref: string, title: string>
# operationId: repoGetIssueTemplates
export def "repo-get-issue-templates" [
  owner: string
  repo: string
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
    path: "/repos/{owner}/{repo}/issue_templates"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List a repository's issues
#
# GET /repos/{owner}/{repo}/issues
# Returns: table<assets: list<record>, assignee: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, assignees: list<record>, body: string, closed_at: string, comments: int, created_at: string, due_date: string, html_url: string, id: int, is_locked: bool, labels: list<record>, milestone: record<closed_at: string, closed_issues: int, created_at: string, description: string, due_on: string, id: int, open_issues: int, state: string, title: string, updated_at: string>, number: int, original_author: string, original_author_id: int, pull_request: record<merged: bool, merged_at: string>, ref: string, repository: record<full_name: string, id: int, name: string, owner: string>, state: string, title: string, updated_at: string, url: string, user: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>>
# operationId: issueListIssues
export def "issue-list-issues" [
  owner: string
  repo: string
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
  --state: string@state-completer-1 # whether issue is open or closed
  --labels: string # comma separated list of labels. Fetch only issues that have any of this labels. Non existent labels are discarded
  --q: string # search string
  --type: string@type-completer-2 # filter by type (issues / pulls) if set
  --milestones: string # comma separated list of milestone names or ids. It uses names and fall back to ids. Fetch only issues that have any of this milestones. Non existent milestones are discarded
  --since: string # Only show items updated after the given time. This is a timestamp in RFC 3339 format (format: date-time)
  --before: string # Only show items updated before the given time. This is a timestamp in RFC 3339 format (format: date-time)
  --created-by: string # Only show items which were created by the the given user
  --assigned-by: string # Only show items for which the given user is assigned
  --mentioned-by: string # Only show items in which the given user was mentioned
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/repos/{owner}/{repo}/issues"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}]
    query: [{name: state, var: state}, {name: labels, var: labels}, {name: q, var: q}, {name: type, var: type}, {name: milestones, var: milestones}, {name: since, var: since}, {name: before, var: before}, {name: created_by, var: created_by}, {name: assigned_by, var: assigned_by}, {name: mentioned_by, var: mentioned_by}, {name: page, var: page}, {name: limit, var: limit}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, state: $state, labels: $labels, q: $q, type: $type, milestones: $milestones, since: $since, before: $before, created_by: $created_by, assigned_by: $assigned_by, mentioned_by: $mentioned_by, page: $page, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create an issue. If using deadline only the date will be taken into account, and time of day ignored.
#
# POST /repos/{owner}/{repo}/issues
# Returns: record<assets: table<browser_download_url: string, created_at: string, download_count: int, id: int, name: string, size: int, uuid: string>, assignee: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, assignees: table<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, body: string, closed_at: string, comments: int, created_at: string, due_date: string, html_url: string, id: int, is_locked: bool, labels: table<color: string, description: string, exclusive: bool, id: int, name: string, url: string>, milestone: record<closed_at: string, closed_issues: int, created_at: string, description: string, due_on: string, id: int, open_issues: int, state: string, title: string, updated_at: string>, number: int, original_author: string, original_author_id: int, pull_request: record<merged: bool, merged_at: string>, ref: string, repository: record<full_name: string, id: int, name: string, owner: string>, state: string, title: string, updated_at: string, url: string, user: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>>
# operationId: issueCreateIssue
export def "issue-create-issue" [
  owner: string
  repo: string
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
  --assignee: string # deprecated
  --assignees: list<string>
  --body: string
  --closed: oneof<nothing, bool>
  --due-date: string # format: date-time
  --labels: list<int> # list of label ids
  --milestone: int # milestone id (format: int64)
  --ref: string
  title: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/repos/{owner}/{repo}/issues"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}]
    body: {content_type: "application/json", kind: json, fields: [{name: assignee, var: assignee}, {name: assignees, var: assignees}, {name: body, var: body}, {name: closed, var: closed}, {name: due_date, var: due_date}, {name: labels, var: labels}, {name: milestone, var: milestone}, {name: ref, var: ref}, {name: title, var: title}]}
    accept: ["application/json", "text/html"]
    ok: [201]
    auth: basic
  } {
    owner: $owner, repo: $repo, assignee: $assignee, assignees: $assignees, body: $body, closed: $closed, due_date: $due_date, labels: $labels, milestone: $milestone, ref: $ref, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List all comments in a repository
#
# GET /repos/{owner}/{repo}/issues/comments
# Returns: table<assets: list<record>, body: string, created_at: string, html_url: string, id: int, issue_url: string, original_author: string, original_author_id: int, pull_request_url: string, updated_at: string, user: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>>
# operationId: issueGetRepoComments
export def "issue-get-repo-comments" [
  owner: string
  repo: string
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
  --since: string # if provided, only comments updated since the provided time are returned. (format: date-time)
  --before: string # if provided, only comments updated before the provided time are returned. (format: date-time)
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/repos/{owner}/{repo}/issues/comments"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}]
    query: [{name: since, var: since}, {name: before, var: before}, {name: page, var: page}, {name: limit, var: limit}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, since: $since, before: $before, page: $page, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a comment
#
# DELETE /repos/{owner}/{repo}/issues/comments/{id}
# operationId: issueDeleteComment
export def "issue-delete-comment" [
  owner: string
  repo: string
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
    path: "/repos/{owner}/{repo}/issues/comments/{id}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    owner: $owner, repo: $repo, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a comment
#
# GET /repos/{owner}/{repo}/issues/comments/{id}
# Returns: record<assets: table<browser_download_url: string, created_at: string, download_count: int, id: int, name: string, size: int, uuid: string>, body: string, created_at: string, html_url: string, id: int, issue_url: string, original_author: string, original_author_id: int, pull_request_url: string, updated_at: string, user: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>>
# operationId: issueGetComment
export def "issue-get-comment" [
  owner: string
  repo: string
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/repos/{owner}/{repo}/issues/comments/{id}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: id, var: id}]
    accept: ["application/json", "text/html"]
    ok: [200, 204]
    auth: basic
  } {
    owner: $owner, repo: $repo, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Edit a comment
#
# PATCH /repos/{owner}/{repo}/issues/comments/{id}
# Returns: record<assets: table<browser_download_url: string, created_at: string, download_count: int, id: int, name: string, size: int, uuid: string>, body: string, created_at: string, html_url: string, id: int, issue_url: string, original_author: string, original_author_id: int, pull_request_url: string, updated_at: string, user: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>>
# operationId: issueEditComment
export def "issue-edit-comment" [
  owner: string
  repo: string
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
  --accept: string@accept-completer # Response content type
  body: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/repos/{owner}/{repo}/issues/comments/{id}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: body, var: body}]}
    accept: ["application/json", "text/html"]
    ok: [200, 204]
    auth: basic
  } {
    owner: $owner, repo: $repo, id: $id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List comment's attachments
#
# GET /repos/{owner}/{repo}/issues/comments/{id}/assets
# Returns: table<browser_download_url: string, created_at: string, download_count: int, id: int, name: string, size: int, uuid: string>
# operationId: issueListIssueCommentAttachments
export def "issue-list-issue-comment-attachments" [
  owner: string
  repo: string
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/repos/{owner}/{repo}/issues/comments/{id}/assets"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: id, var: id}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a comment attachment
#
# POST /repos/{owner}/{repo}/issues/comments/{id}/assets
# Returns: record<browser_download_url: string, created_at: string, download_count: int, id: int, name: string, size: int, uuid: string>
# operationId: issueCreateIssueCommentAttachment
export def "issue-create-issue-comment-attachment" [
  owner: string
  repo: string
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
  --accept: string@accept-completer # Response content type
  --name: string # name of the attachment
  attachment: string # attachment to upload (format: binary)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/repos/{owner}/{repo}/issues/comments/{id}/assets"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: id, var: id}]
    query: [{name: name, var: name}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: attachment, var: attachment}], files: [attachment]}
    accept: ["application/json", "text/html"]
    ok: [201]
    auth: basic
  } {
    owner: $owner, repo: $repo, id: $id, name: $name, attachment: $attachment
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a comment attachment
#
# DELETE /repos/{owner}/{repo}/issues/comments/{id}/assets/{attachment_id}
# operationId: issueDeleteIssueCommentAttachment
export def "issue-delete-issue-comment-attachment" [
  owner: string
  repo: string
  id: int
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
    path: "/repos/{owner}/{repo}/issues/comments/{id}/assets/{attachment_id}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: id, var: id}, {name: attachment_id, var: attachment_id}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    owner: $owner, repo: $repo, id: $id, attachment_id: $attachment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a comment attachment
#
# GET /repos/{owner}/{repo}/issues/comments/{id}/assets/{attachment_id}
# Returns: record<browser_download_url: string, created_at: string, download_count: int, id: int, name: string, size: int, uuid: string>
# operationId: issueGetIssueCommentAttachment
export def "issue-get-issue-comment-attachment" [
  owner: string
  repo: string
  id: int
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/repos/{owner}/{repo}/issues/comments/{id}/assets/{attachment_id}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: id, var: id}, {name: attachment_id, var: attachment_id}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, id: $id, attachment_id: $attachment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Edit a comment attachment
#
# PATCH /repos/{owner}/{repo}/issues/comments/{id}/assets/{attachment_id}
# Returns: record<browser_download_url: string, created_at: string, download_count: int, id: int, name: string, size: int, uuid: string>
# operationId: issueEditIssueCommentAttachment
export def "issue-edit-issue-comment-attachment" [
  owner: string
  repo: string
  id: int
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
  --accept: string@accept-completer # Response content type
  --name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/repos/{owner}/{repo}/issues/comments/{id}/assets/{attachment_id}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: id, var: id}, {name: attachment_id, var: attachment_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json", "text/html"]
    ok: [201]
    auth: basic
  } {
    owner: $owner, repo: $repo, id: $id, attachment_id: $attachment_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Remove a reaction from a comment of an issue
#
# DELETE /repos/{owner}/{repo}/issues/comments/{id}/reactions
# operationId: issueDeleteCommentReaction
export def "issue-delete-comment-reaction" [
  owner: string
  repo: string
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
  --content: string
]: any -> any {
  $in | http-request {
    method: delete
    path: "/repos/{owner}/{repo}/issues/comments/{id}/reactions"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: content, var: content}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, id: $id, content: $content
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of reactions from a comment of an issue
#
# GET /repos/{owner}/{repo}/issues/comments/{id}/reactions
# Returns: table<content: string, created_at: string, user: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>>
# operationId: issueGetCommentReactions
export def "issue-get-comment-reactions" [
  owner: string
  repo: string
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/repos/{owner}/{repo}/issues/comments/{id}/reactions"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: id, var: id}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add a reaction to a comment of an issue
#
# POST /repos/{owner}/{repo}/issues/comments/{id}/reactions
# Returns: record<content: string, created_at: string, user: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>>
# operationId: issuePostCommentReaction
export def "issue-post-comment-reaction" [
  owner: string
  repo: string
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
  --accept: string@accept-completer # Response content type
  --content: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/repos/{owner}/{repo}/issues/comments/{id}/reactions"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: content, var: content}]}
    accept: ["application/json", "text/html"]
    ok: [200, 201]
    auth: basic
  } {
    owner: $owner, repo: $repo, id: $id, content: $content
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete an issue
#
# DELETE /repos/{owner}/{repo}/issues/{index}
# operationId: issueDelete
export def "issue-delete" [
  owner: string
  repo: string
  index: int
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
    path: "/repos/{owner}/{repo}/issues/{index}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: index, var: index}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    owner: $owner, repo: $repo, index: $index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an issue
#
# GET /repos/{owner}/{repo}/issues/{index}
# Returns: record<assets: table<browser_download_url: string, created_at: string, download_count: int, id: int, name: string, size: int, uuid: string>, assignee: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, assignees: table<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, body: string, closed_at: string, comments: int, created_at: string, due_date: string, html_url: string, id: int, is_locked: bool, labels: table<color: string, description: string, exclusive: bool, id: int, name: string, url: string>, milestone: record<closed_at: string, closed_issues: int, created_at: string, description: string, due_on: string, id: int, open_issues: int, state: string, title: string, updated_at: string>, number: int, original_author: string, original_author_id: int, pull_request: record<merged: bool, merged_at: string>, ref: string, repository: record<full_name: string, id: int, name: string, owner: string>, state: string, title: string, updated_at: string, url: string, user: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>>
# operationId: issueGetIssue
export def "issue-get-issue" [
  owner: string
  repo: string
  index: int
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
    path: "/repos/{owner}/{repo}/issues/{index}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: index, var: index}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, index: $index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Edit an issue. If using deadline only the date will be taken into account, and time of day ignored.
#
# PATCH /repos/{owner}/{repo}/issues/{index}
# Returns: record<assets: table<browser_download_url: string, created_at: string, download_count: int, id: int, name: string, size: int, uuid: string>, assignee: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, assignees: table<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, body: string, closed_at: string, comments: int, created_at: string, due_date: string, html_url: string, id: int, is_locked: bool, labels: table<color: string, description: string, exclusive: bool, id: int, name: string, url: string>, milestone: record<closed_at: string, closed_issues: int, created_at: string, description: string, due_on: string, id: int, open_issues: int, state: string, title: string, updated_at: string>, number: int, original_author: string, original_author_id: int, pull_request: record<merged: bool, merged_at: string>, ref: string, repository: record<full_name: string, id: int, name: string, owner: string>, state: string, title: string, updated_at: string, url: string, user: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>>
# operationId: issueEditIssue
export def "issue-edit-issue" [
  owner: string
  repo: string
  index: int
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
  --assignee: string # deprecated
  --assignees: list<string>
  --body: string
  --due-date: string # format: date-time
  --milestone: int # format: int64
  --ref: string
  --state: string
  --title: string
  --unset-due-date: oneof<nothing, bool>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/repos/{owner}/{repo}/issues/{index}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: index, var: index}]
    body: {content_type: "application/json", kind: json, fields: [{name: assignee, var: assignee}, {name: assignees, var: assignees}, {name: body, var: body}, {name: due_date, var: due_date}, {name: milestone, var: milestone}, {name: ref, var: ref}, {name: state, var: state}, {name: title, var: title}, {name: unset_due_date, var: unset_due_date}]}
    accept: ["application/json", "text/html"]
    ok: [201]
    auth: basic
  } {
    owner: $owner, repo: $repo, index: $index, assignee: $assignee, assignees: $assignees, body: $body, due_date: $due_date, milestone: $milestone, ref: $ref, state: $state, title: $title, unset_due_date: $unset_due_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List issue's attachments
#
# GET /repos/{owner}/{repo}/issues/{index}/assets
# Returns: table<browser_download_url: string, created_at: string, download_count: int, id: int, name: string, size: int, uuid: string>
# operationId: issueListIssueAttachments
export def "issue-list-issue-attachments" [
  owner: string
  repo: string
  index: int
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
    path: "/repos/{owner}/{repo}/issues/{index}/assets"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: index, var: index}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, index: $index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create an issue attachment
#
# POST /repos/{owner}/{repo}/issues/{index}/assets
# Returns: record<browser_download_url: string, created_at: string, download_count: int, id: int, name: string, size: int, uuid: string>
# operationId: issueCreateIssueAttachment
export def "issue-create-issue-attachment" [
  owner: string
  repo: string
  index: int
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
  --name: string # name of the attachment
  attachment: string # attachment to upload (format: binary)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/repos/{owner}/{repo}/issues/{index}/assets"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: index, var: index}]
    query: [{name: name, var: name}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: attachment, var: attachment}], files: [attachment]}
    accept: ["application/json", "text/html"]
    ok: [201]
    auth: basic
  } {
    owner: $owner, repo: $repo, index: $index, name: $name, attachment: $attachment
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete an issue attachment
#
# DELETE /repos/{owner}/{repo}/issues/{index}/assets/{attachment_id}
# operationId: issueDeleteIssueAttachment
export def "issue-delete-issue-attachment" [
  owner: string
  repo: string
  index: int
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
    path: "/repos/{owner}/{repo}/issues/{index}/assets/{attachment_id}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: index, var: index}, {name: attachment_id, var: attachment_id}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    owner: $owner, repo: $repo, index: $index, attachment_id: $attachment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an issue attachment
#
# GET /repos/{owner}/{repo}/issues/{index}/assets/{attachment_id}
# Returns: record<browser_download_url: string, created_at: string, download_count: int, id: int, name: string, size: int, uuid: string>
# operationId: issueGetIssueAttachment
export def "issue-get-issue-attachment" [
  owner: string
  repo: string
  index: int
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/repos/{owner}/{repo}/issues/{index}/assets/{attachment_id}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: index, var: index}, {name: attachment_id, var: attachment_id}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, index: $index, attachment_id: $attachment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Edit an issue attachment
#
# PATCH /repos/{owner}/{repo}/issues/{index}/assets/{attachment_id}
# Returns: record<browser_download_url: string, created_at: string, download_count: int, id: int, name: string, size: int, uuid: string>
# operationId: issueEditIssueAttachment
export def "issue-edit-issue-attachment" [
  owner: string
  repo: string
  index: int
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
  --accept: string@accept-completer # Response content type
  --name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/repos/{owner}/{repo}/issues/{index}/assets/{attachment_id}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: index, var: index}, {name: attachment_id, var: attachment_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json", "text/html"]
    ok: [201]
    auth: basic
  } {
    owner: $owner, repo: $repo, index: $index, attachment_id: $attachment_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List all comments on an issue
#
# GET /repos/{owner}/{repo}/issues/{index}/comments
# Returns: table<assets: list<record>, body: string, created_at: string, html_url: string, id: int, issue_url: string, original_author: string, original_author_id: int, pull_request_url: string, updated_at: string, user: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>>
# operationId: issueGetComments
export def "issue-get-comments" [
  owner: string
  repo: string
  index: int
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
  --since: string # if provided, only comments updated since the specified time are returned. (format: date-time)
  --before: string # if provided, only comments updated before the provided time are returned. (format: date-time)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/repos/{owner}/{repo}/issues/{index}/comments"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: index, var: index}]
    query: [{name: since, var: since}, {name: before, var: before}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, index: $index, since: $since, before: $before
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add a comment to an issue
#
# POST /repos/{owner}/{repo}/issues/{index}/comments
# Returns: record<assets: table<browser_download_url: string, created_at: string, download_count: int, id: int, name: string, size: int, uuid: string>, body: string, created_at: string, html_url: string, id: int, issue_url: string, original_author: string, original_author_id: int, pull_request_url: string, updated_at: string, user: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>>
# operationId: issueCreateComment
export def "issue-create-comment" [
  owner: string
  repo: string
  index: int
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
  body: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/repos/{owner}/{repo}/issues/{index}/comments"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: index, var: index}]
    body: {content_type: "application/json", kind: json, fields: [{name: body, var: body}]}
    accept: ["application/json", "text/html"]
    ok: [201]
    auth: basic
  } {
    owner: $owner, repo: $repo, index: $index, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a comment
#
# DELETE /repos/{owner}/{repo}/issues/{index}/comments/{id}
# DEPRECATED
# operationId: issueDeleteCommentDeprecated
@deprecated
export def "issue-delete-comment-deprecated" [
  owner: string
  repo: string
  index: int
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
    path: "/repos/{owner}/{repo}/issues/{index}/comments/{id}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: index, var: index}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    owner: $owner, repo: $repo, index: $index, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit a comment
#
# PATCH /repos/{owner}/{repo}/issues/{index}/comments/{id}
# DEPRECATED
# Returns: record<assets: table<browser_download_url: string, created_at: string, download_count: int, id: int, name: string, size: int, uuid: string>, body: string, created_at: string, html_url: string, id: int, issue_url: string, original_author: string, original_author_id: int, pull_request_url: string, updated_at: string, user: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>>
# operationId: issueEditCommentDeprecated
@deprecated
export def "issue-edit-comment-deprecated" [
  owner: string
  repo: string
  index: int
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
  --accept: string@accept-completer # Response content type
  body: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/repos/{owner}/{repo}/issues/{index}/comments/{id}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: index, var: index}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: body, var: body}]}
    accept: ["application/json", "text/html"]
    ok: [200, 204]
    auth: basic
  } {
    owner: $owner, repo: $repo, index: $index, id: $id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Set an issue deadline. If set to null, the deadline is deleted. If using deadline only the date will be taken into account, and time of day ignored.
#
# POST /repos/{owner}/{repo}/issues/{index}/deadline
# Returns: record<due_date: string>
# operationId: issueEditIssueDeadline
export def "issue-edit-issue-deadline" [
  owner: string
  repo: string
  index: int
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
  due_date: string # format: date-time
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/repos/{owner}/{repo}/issues/{index}/deadline"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: index, var: index}]
    body: {content_type: "application/json", kind: json, fields: [{name: due_date, var: due_date}]}
    accept: ["application/json", "text/html"]
    ok: [201]
    auth: basic
  } {
    owner: $owner, repo: $repo, index: $index, due_date: $due_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Remove all labels from an issue
#
# DELETE /repos/{owner}/{repo}/issues/{index}/labels
# operationId: issueClearLabels
export def "issue-clear-labels" [
  owner: string
  repo: string
  index: int
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
    path: "/repos/{owner}/{repo}/issues/{index}/labels"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: index, var: index}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    owner: $owner, repo: $repo, index: $index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an issue's labels
#
# GET /repos/{owner}/{repo}/issues/{index}/labels
# Returns: table<color: string, description: string, exclusive: bool, id: int, name: string, url: string>
# operationId: issueGetLabels
export def "issue-get-labels" [
  owner: string
  repo: string
  index: int
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
    path: "/repos/{owner}/{repo}/issues/{index}/labels"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: index, var: index}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, index: $index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add a label to an issue
#
# POST /repos/{owner}/{repo}/issues/{index}/labels
# Returns: table<color: string, description: string, exclusive: bool, id: int, name: string, url: string>
# operationId: issueAddLabel
export def "issue-add-label" [
  owner: string
  repo: string
  index: int
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
  --labels: list<int> # list of label IDs
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/repos/{owner}/{repo}/issues/{index}/labels"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: index, var: index}]
    body: {content_type: "application/json", kind: json, fields: [{name: labels, var: labels}]}
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, index: $index, labels: $labels
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Replace an issue's labels
#
# PUT /repos/{owner}/{repo}/issues/{index}/labels
# Returns: table<color: string, description: string, exclusive: bool, id: int, name: string, url: string>
# operationId: issueReplaceLabels
export def "issue-replace-labels" [
  owner: string
  repo: string
  index: int
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
  --labels: list<int> # list of label IDs
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: put
    path: "/repos/{owner}/{repo}/issues/{index}/labels"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: index, var: index}]
    body: {content_type: "application/json", kind: json, fields: [{name: labels, var: labels}]}
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, index: $index, labels: $labels
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Remove a label from an issue
#
# DELETE /repos/{owner}/{repo}/issues/{index}/labels/{id}
# operationId: issueRemoveLabel
export def "issue-remove-label" [
  owner: string
  repo: string
  index: int
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
    path: "/repos/{owner}/{repo}/issues/{index}/labels/{id}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: index, var: index}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    owner: $owner, repo: $repo, index: $index, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a reaction from an issue
#
# DELETE /repos/{owner}/{repo}/issues/{index}/reactions
# operationId: issueDeleteIssueReaction
export def "issue-delete-issue-reaction" [
  owner: string
  repo: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content: string
]: any -> any {
  $in | http-request {
    method: delete
    path: "/repos/{owner}/{repo}/issues/{index}/reactions"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: index, var: index}]
    body: {content_type: "application/json", kind: json, fields: [{name: content, var: content}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, index: $index, content: $content
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list reactions of an issue
#
# GET /repos/{owner}/{repo}/issues/{index}/reactions
# Returns: table<content: string, created_at: string, user: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>>
# operationId: issueGetIssueReactions
export def "issue-get-issue-reactions" [
  owner: string
  repo: string
  index: int
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
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/repos/{owner}/{repo}/issues/{index}/reactions"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: index, var: index}]
    query: [{name: page, var: page}, {name: limit, var: limit}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, index: $index, page: $page, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add a reaction to an issue
#
# POST /repos/{owner}/{repo}/issues/{index}/reactions
# Returns: record<content: string, created_at: string, user: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>>
# operationId: issuePostIssueReaction
export def "issue-post-issue-reaction" [
  owner: string
  repo: string
  index: int
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
  --content: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/repos/{owner}/{repo}/issues/{index}/reactions"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: index, var: index}]
    body: {content_type: "application/json", kind: json, fields: [{name: content, var: content}]}
    accept: ["application/json", "text/html"]
    ok: [200, 201]
    auth: basic
  } {
    owner: $owner, repo: $repo, index: $index, content: $content
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete an issue's existing stopwatch.
#
# DELETE /repos/{owner}/{repo}/issues/{index}/stopwatch/delete
# operationId: issueDeleteStopWatch
export def "issue-delete-stop-watch" [
  owner: string
  repo: string
  index: int
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
    path: "/repos/{owner}/{repo}/issues/{index}/stopwatch/delete"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: index, var: index}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    owner: $owner, repo: $repo, index: $index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Start stopwatch on an issue.
#
# POST /repos/{owner}/{repo}/issues/{index}/stopwatch/start
# operationId: issueStartStopWatch
export def "issue-start-stop-watch" [
  owner: string
  repo: string
  index: int
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
    path: "/repos/{owner}/{repo}/issues/{index}/stopwatch/start"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: index, var: index}]
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    owner: $owner, repo: $repo, index: $index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stop an issue's existing stopwatch.
#
# POST /repos/{owner}/{repo}/issues/{index}/stopwatch/stop
# operationId: issueStopStopWatch
export def "issue-stop-stop-watch" [
  owner: string
  repo: string
  index: int
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
    path: "/repos/{owner}/{repo}/issues/{index}/stopwatch/stop"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: index, var: index}]
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    owner: $owner, repo: $repo, index: $index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get users who subscribed on an issue.
#
# GET /repos/{owner}/{repo}/issues/{index}/subscriptions
# Returns: table<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>
# operationId: issueSubscriptions
export def "issue-subscriptions" [
  owner: string
  repo: string
  index: int
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
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/repos/{owner}/{repo}/issues/{index}/subscriptions"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: index, var: index}]
    query: [{name: page, var: page}, {name: limit, var: limit}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, index: $index, page: $page, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Check if user is subscribed to an issue
#
# GET /repos/{owner}/{repo}/issues/{index}/subscriptions/check
# Returns: record<created_at: string, ignored: bool, reason: any, repository_url: string, subscribed: bool, url: string>
# operationId: issueCheckSubscription
export def "issue-check-subscription" [
  owner: string
  repo: string
  index: int
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
    path: "/repos/{owner}/{repo}/issues/{index}/subscriptions/check"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: index, var: index}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, index: $index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Unsubscribe user from issue
#
# DELETE /repos/{owner}/{repo}/issues/{index}/subscriptions/{user}
# operationId: issueDeleteSubscription
export def "issue-delete-subscription" [
  owner: string
  repo: string
  index: int
  user: string
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
    path: "/repos/{owner}/{repo}/issues/{index}/subscriptions/{user}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: index, var: index}, {name: user, var: user}]
    accept: ["application/json"]
    ok: [200, 201, 304]
    auth: basic
  } {
    owner: $owner, repo: $repo, index: $index, user: $user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Subscribe user to issue
#
# PUT /repos/{owner}/{repo}/issues/{index}/subscriptions/{user}
# operationId: issueAddSubscription
export def "issue-add-subscription" [
  owner: string
  repo: string
  index: int
  user: string
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
    path: "/repos/{owner}/{repo}/issues/{index}/subscriptions/{user}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: index, var: index}, {name: user, var: user}]
    accept: ["application/json"]
    ok: [200, 201, 304]
    auth: basic
  } {
    owner: $owner, repo: $repo, index: $index, user: $user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all comments and events on an issue
#
# GET /repos/{owner}/{repo}/issues/{index}/timeline
# Returns: table<assignee: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, assignee_team: record<can_create_org_repo: bool, description: string, id: int, includes_all_repositories: bool, name: string, organization: record, permission: string, units: list, units_map: record>, body: string, created_at: string, dependent_issue: record<assets: list, assignee: record, assignees: list, body: string, closed_at: string, comments: int, created_at: string, due_date: string, html_url: string, id: int, is_locked: bool, labels: list, milestone: record, number: int, original_author: string, original_author_id: int, pull_request: record, ref: string, repository: record, state: string, title: string, updated_at: string, url: string, user: record>, html_url: string, id: int, issue_url: string, label: record<color: string, description: string, exclusive: bool, id: int, name: string, url: string>, milestone: record<closed_at: string, closed_issues: int, created_at: string, description: string, due_on: string, id: int, open_issues: int, state: string, title: string, updated_at: string>, new_ref: string, new_title: string, old_milestone: record<closed_at: string, closed_issues: int, created_at: string, description: string, due_on: string, id: int, open_issues: int, state: string, title: string, updated_at: string>, old_project_id: int, old_ref: string, old_title: string, project_id: int, pull_request_url: string, ref_action: string, ref_comment: record<assets: list, body: string, created_at: string, html_url: string, id: int, issue_url: string, original_author: string, original_author_id: int, pull_request_url: string, updated_at: string, user: record>, ref_commit_sha: string, ref_issue: record<assets: list, assignee: record, assignees: list, body: string, closed_at: string, comments: int, created_at: string, due_date: string, html_url: string, id: int, is_locked: bool, labels: list, milestone: record, number: int, original_author: string, original_author_id: int, pull_request: record, ref: string, repository: record, state: string, title: string, updated_at: string, url: string, user: record>, removed_assignee: bool, resolve_doer: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, review_id: int, tracked_time: record<created: string, id: int, issue: record, issue_id: int, time: int, user_id: int, user_name: string>, type: string, updated_at: string, user: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>>
# operationId: issueGetCommentsAndTimeline
export def "issue-get-comments-and-timeline" [
  owner: string
  repo: string
  index: int
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
  --since: string # if provided, only comments updated since the specified time are returned. (format: date-time)
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
  --before: string # if provided, only comments updated before the provided time are returned. (format: date-time)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/repos/{owner}/{repo}/issues/{index}/timeline"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: index, var: index}]
    query: [{name: since, var: since}, {name: page, var: page}, {name: limit, var: limit}, {name: before, var: before}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, index: $index, since: $since, page: $page, limit: $limit, before: $before
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Reset a tracked time of an issue
#
# DELETE /repos/{owner}/{repo}/issues/{index}/times
# operationId: issueResetTime
export def "issue-reset-time" [
  owner: string
  repo: string
  index: int
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
    path: "/repos/{owner}/{repo}/issues/{index}/times"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: index, var: index}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    owner: $owner, repo: $repo, index: $index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List an issue's tracked times
#
# GET /repos/{owner}/{repo}/issues/{index}/times
# Returns: table<created: string, id: int, issue: record<assets: list, assignee: record, assignees: list, body: string, closed_at: string, comments: int, created_at: string, due_date: string, html_url: string, id: int, is_locked: bool, labels: list, milestone: record, number: int, original_author: string, original_author_id: int, pull_request: record, ref: string, repository: record, state: string, title: string, updated_at: string, url: string, user: record>, issue_id: int, time: int, user_id: int, user_name: string>
# operationId: issueTrackedTimes
export def "issue-tracked-times" [
  owner: string
  repo: string
  index: int
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
  --user: string # optional filter by user (available for issue managers)
  --since: string # Only show times updated after the given time. This is a timestamp in RFC 3339 format (format: date-time)
  --before: string # Only show times updated before the given time. This is a timestamp in RFC 3339 format (format: date-time)
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/repos/{owner}/{repo}/issues/{index}/times"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: index, var: index}]
    query: [{name: user, var: user}, {name: since, var: since}, {name: before, var: before}, {name: page, var: page}, {name: limit, var: limit}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, index: $index, user: $user, since: $since, before: $before, page: $page, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add tracked time to a issue
#
# POST /repos/{owner}/{repo}/issues/{index}/times
# Returns: record<created: string, id: int, issue: record<assets: list<record>, assignee: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, assignees: list<record>, body: string, closed_at: string, comments: int, created_at: string, due_date: string, html_url: string, id: int, is_locked: bool, labels: list<record>, milestone: record<closed_at: string, closed_issues: int, created_at: string, description: string, due_on: string, id: int, open_issues: int, state: string, title: string, updated_at: string>, number: int, original_author: string, original_author_id: int, pull_request: record<merged: bool, merged_at: string>, ref: string, repository: record<full_name: string, id: int, name: string, owner: string>, state: string, title: string, updated_at: string, url: string, user: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>>, issue_id: int, time: int, user_id: int, user_name: string>
# operationId: issueAddTime
export def "issue-add-time" [
  owner: string
  repo: string
  index: int
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
  --created: string # format: date-time
  time: int # time in seconds (format: int64)
  --user-name: string # User who spent the time (optional)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/repos/{owner}/{repo}/issues/{index}/times"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: index, var: index}]
    body: {content_type: "application/json", kind: json, fields: [{name: created, var: created}, {name: time, var: time}, {name: user_name, var: user_name}]}
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, index: $index, created: $created, time: $time, user_name: $user_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete specific tracked time
#
# DELETE /repos/{owner}/{repo}/issues/{index}/times/{id}
# operationId: issueDeleteTime
export def "issue-delete-time" [
  owner: string
  repo: string
  index: int
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
    path: "/repos/{owner}/{repo}/issues/{index}/times/{id}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: index, var: index}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    owner: $owner, repo: $repo, index: $index, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List a repository's keys
#
# GET /repos/{owner}/{repo}/keys
# Returns: table<created_at: string, fingerprint: string, id: int, key: string, key_id: int, read_only: bool, repository: record<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record, external_wiki: record, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record, parent: any, permissions: record, private: bool, release_counter: int, repo_transfer: record, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>, title: string, url: string>
# operationId: repoListKeys
export def "repo-list-keys" [
  owner: string
  repo: string
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
  --key-id: int # the key_id to search for
  --fingerprint: string # fingerprint of the key
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/repos/{owner}/{repo}/keys"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}]
    query: [{name: key_id, var: key_id}, {name: fingerprint, var: fingerprint}, {name: page, var: page}, {name: limit, var: limit}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, key_id: $key_id, fingerprint: $fingerprint, page: $page, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add a key to a repository
#
# POST /repos/{owner}/{repo}/keys
# Returns: record<created_at: string, fingerprint: string, id: int, key: string, key_id: int, read_only: bool, repository: record<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record<external_tracker_format: string, external_tracker_regexp_pattern: string, external_tracker_style: string, external_tracker_url: string>, external_wiki: record<external_wiki_url: string>, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record<allow_only_contributors_to_track_time: bool, enable_issue_dependencies: bool, enable_time_tracker: bool>, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, parent: any, permissions: record<admin: bool, pull: bool, push: bool>, private: bool, release_counter: int, repo_transfer: record<doer: record, recipient: record, teams: list>, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>, title: string, url: string>
# operationId: repoCreateKey
export def "repo-create-key" [
  owner: string
  repo: string
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
  key: string # An armored SSH key to add
  --read-only: oneof<nothing, bool> # Describe if the key has only read access or read/write
  title: string # Title of the key to add
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/repos/{owner}/{repo}/keys"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}]
    body: {content_type: "application/json", kind: json, fields: [{name: key, var: key}, {name: read_only, var: read_only}, {name: title, var: title}]}
    accept: ["application/json", "text/html"]
    ok: [201]
    auth: basic
  } {
    owner: $owner, repo: $repo, key: $key, read_only: $read_only, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a key from a repository
#
# DELETE /repos/{owner}/{repo}/keys/{id}
# operationId: repoDeleteKey
export def "repo-delete-key" [
  owner: string
  repo: string
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
    path: "/repos/{owner}/{repo}/keys/{id}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    owner: $owner, repo: $repo, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a repository's key by id
#
# GET /repos/{owner}/{repo}/keys/{id}
# Returns: record<created_at: string, fingerprint: string, id: int, key: string, key_id: int, read_only: bool, repository: record<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record<external_tracker_format: string, external_tracker_regexp_pattern: string, external_tracker_style: string, external_tracker_url: string>, external_wiki: record<external_wiki_url: string>, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record<allow_only_contributors_to_track_time: bool, enable_issue_dependencies: bool, enable_time_tracker: bool>, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, parent: any, permissions: record<admin: bool, pull: bool, push: bool>, private: bool, release_counter: int, repo_transfer: record<doer: record, recipient: record, teams: list>, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>, title: string, url: string>
# operationId: repoGetKey
export def "repo-get-key" [
  owner: string
  repo: string
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/repos/{owner}/{repo}/keys/{id}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: id, var: id}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get all of a repository's labels
#
# GET /repos/{owner}/{repo}/labels
# Returns: table<color: string, description: string, exclusive: bool, id: int, name: string, url: string>
# operationId: issueListLabels
export def "issue-list-labels" [
  owner: string
  repo: string
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
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/repos/{owner}/{repo}/labels"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}]
    query: [{name: page, var: page}, {name: limit, var: limit}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, page: $page, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a label
#
# POST /repos/{owner}/{repo}/labels
# Returns: record<color: string, description: string, exclusive: bool, id: int, name: string, url: string>
# operationId: issueCreateLabel
export def "issue-create-label" [
  owner: string
  repo: string
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
  color: string # e.g. #00aabb
  --description: string
  --exclusive: oneof<nothing, bool> # e.g. false
  name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/repos/{owner}/{repo}/labels"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}]
    body: {content_type: "application/json", kind: json, fields: [{name: color, var: color}, {name: description, var: description}, {name: exclusive, var: exclusive}, {name: name, var: name}]}
    accept: ["application/json", "text/html"]
    ok: [201]
    auth: basic
  } {
    owner: $owner, repo: $repo, color: $color, description: $description, exclusive: $exclusive, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a label
#
# DELETE /repos/{owner}/{repo}/labels/{id}
# operationId: issueDeleteLabel
export def "issue-delete-label" [
  owner: string
  repo: string
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
    path: "/repos/{owner}/{repo}/labels/{id}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    owner: $owner, repo: $repo, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a single label
#
# GET /repos/{owner}/{repo}/labels/{id}
# Returns: record<color: string, description: string, exclusive: bool, id: int, name: string, url: string>
# operationId: issueGetLabel
export def "issue-get-label" [
  owner: string
  repo: string
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/repos/{owner}/{repo}/labels/{id}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: id, var: id}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a label
#
# PATCH /repos/{owner}/{repo}/labels/{id}
# Returns: record<color: string, description: string, exclusive: bool, id: int, name: string, url: string>
# operationId: issueEditLabel
export def "issue-edit-label" [
  owner: string
  repo: string
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
  --accept: string@accept-completer # Response content type
  --color: string # e.g. #00aabb
  --description: string
  --exclusive: oneof<nothing, bool> # e.g. false
  --name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/repos/{owner}/{repo}/labels/{id}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: color, var: color}, {name: description, var: description}, {name: exclusive, var: exclusive}, {name: name, var: name}]}
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, id: $id, color: $color, description: $description, exclusive: $exclusive, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get languages and number of bytes of code written
#
# GET /repos/{owner}/{repo}/languages
# Returns: record
# operationId: repoGetLanguages
export def "repo-get-languages" [
  owner: string
  repo: string
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
    path: "/repos/{owner}/{repo}/languages"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a file or it's LFS object from a repository
#
# GET /repos/{owner}/{repo}/media/{filepath}
# operationId: repoGetRawFileOrLFS
export def "repo-get-raw-file-or-lfs" [
  owner: string
  repo: string
  filepath: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ref: string # The name of the commit/branch/tag. Default the repository’s default branch (usually master)
]: nothing -> any {
  http-request {
    method: get
    path: "/repos/{owner}/{repo}/media/{filepath}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: filepath, var: filepath}]
    query: [{name: ref, var: ref}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, filepath: $filepath, ref: $ref
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all of a repository's opened milestones
#
# GET /repos/{owner}/{repo}/milestones
# Returns: table<closed_at: string, closed_issues: int, created_at: string, description: string, due_on: string, id: int, open_issues: int, state: string, title: string, updated_at: string>
# operationId: issueGetMilestonesList
export def "issue-get-milestones-list" [
  owner: string
  repo: string
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
  --state: string # Milestone state, Recognized values are open, closed and all. Defaults to "open"
  --name: string # filter by milestone name
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/repos/{owner}/{repo}/milestones"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}]
    query: [{name: state, var: state}, {name: name, var: name}, {name: page, var: page}, {name: limit, var: limit}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, state: $state, name: $name, page: $page, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a milestone
#
# POST /repos/{owner}/{repo}/milestones
# Returns: record<closed_at: string, closed_issues: int, created_at: string, description: string, due_on: string, id: int, open_issues: int, state: string, title: string, updated_at: string>
# operationId: issueCreateMilestone
export def "issue-create-milestone" [
  owner: string
  repo: string
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
  --description: string
  --due-on: string # format: date-time
  --state: string@state-completer-2
  --title: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/repos/{owner}/{repo}/milestones"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: due_on, var: due_on}, {name: state, var: state}, {name: title, var: title}]}
    accept: ["application/json", "text/html"]
    ok: [201]
    auth: basic
  } {
    owner: $owner, repo: $repo, description: $description, due_on: $due_on, state: $state, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a milestone
#
# DELETE /repos/{owner}/{repo}/milestones/{id}
# operationId: issueDeleteMilestone
export def "issue-delete-milestone" [
  owner: string
  repo: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/repos/{owner}/{repo}/milestones/{id}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    owner: $owner, repo: $repo, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a milestone
#
# GET /repos/{owner}/{repo}/milestones/{id}
# Returns: record<closed_at: string, closed_issues: int, created_at: string, description: string, due_on: string, id: int, open_issues: int, state: string, title: string, updated_at: string>
# operationId: issueGetMilestone
export def "issue-get-milestone" [
  owner: string
  repo: string
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/repos/{owner}/{repo}/milestones/{id}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: id, var: id}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a milestone
#
# PATCH /repos/{owner}/{repo}/milestones/{id}
# Returns: record<closed_at: string, closed_issues: int, created_at: string, description: string, due_on: string, id: int, open_issues: int, state: string, title: string, updated_at: string>
# operationId: issueEditMilestone
export def "issue-edit-milestone" [
  owner: string
  repo: string
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
  --accept: string@accept-completer # Response content type
  --description: string
  --due-on: string # format: date-time
  --state: string
  --title: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/repos/{owner}/{repo}/milestones/{id}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: due_on, var: due_on}, {name: state, var: state}, {name: title, var: title}]}
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, id: $id, description: $description, due_on: $due_on, state: $state, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Sync a mirrored repository
#
# POST /repos/{owner}/{repo}/mirror-sync
# operationId: repoMirrorSync
export def "repo-mirror-sync" [
  owner: string
  repo: string
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
    path: "/repos/{owner}/{repo}/mirror-sync"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List users's notification threads on a specific repo
#
# GET /repos/{owner}/{repo}/notifications
# Returns: table<id: int, pinned: bool, repository: record<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record, external_wiki: record, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record, parent: any, permissions: record, private: bool, release_counter: int, repo_transfer: record, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>, subject: record<html_url: string, latest_comment_html_url: string, latest_comment_url: string, state: string, title: string, type: string, url: string>, unread: bool, updated_at: string, url: string>
# operationId: notifyGetRepoList
export def "notify-get-repo-list" [
  owner: string
  repo: string
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
  --all: oneof<nothing, bool> # If true, show notifications marked as read. Default value is false
  --status-types: list<string> # Show notifications with the provided status types. Options are: unread, read and/or pinned. Defaults to unread & pinned
  --subject-type: list<string> # filter notifications by subject type
  --since: string # Only show notifications updated after the given time. This is a timestamp in RFC 3339 format (format: date-time)
  --before: string # Only show notifications updated before the given time. This is a timestamp in RFC 3339 format (format: date-time)
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/repos/{owner}/{repo}/notifications"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}]
    query: [{name: all, var: all}, {name: status-types, var: status_types, style: multi}, {name: subject-type, var: subject_type, style: multi}, {name: since, var: since}, {name: before, var: before}, {name: page, var: page}, {name: limit, var: limit}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, all: $all, status_types: $status_types, subject_type: $subject_type, since: $since, before: $before, page: $page, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Mark notification threads as read, pinned or unread on a specific repo
#
# PUT /repos/{owner}/{repo}/notifications
# Returns: table<id: int, pinned: bool, repository: record<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record, external_wiki: record, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record, parent: any, permissions: record, private: bool, release_counter: int, repo_transfer: record, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>, subject: record<html_url: string, latest_comment_html_url: string, latest_comment_url: string, state: string, title: string, type: string, url: string>, unread: bool, updated_at: string, url: string>
# operationId: notifyReadRepoList
export def "notify-read-repo-list" [
  owner: string
  repo: string
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
  --all: string # If true, mark all notifications on this repo. Default value is false
  --status-types: list<string> # Mark notifications with the provided status types. Options are: unread, read and/or pinned. Defaults to unread.
  --to-status: string # Status to mark notifications as. Defaults to read.
  --last-read-at: string # Describes the last point that notifications were checked. Anything updated since this time will not be updated. (format: date-time)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: put
    path: "/repos/{owner}/{repo}/notifications"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}]
    query: [{name: all, var: all}, {name: status-types, var: status_types, style: multi}, {name: to-status, var: to_status}, {name: last_read_at, var: last_read_at}]
    accept: ["application/json", "text/html"]
    ok: [205]
    auth: basic
  } {
    owner: $owner, repo: $repo, all: $all, status_types: $status_types, to_status: $to_status, last_read_at: $last_read_at
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List a repo's pull requests
#
# GET /repos/{owner}/{repo}/pulls
# Returns: table<allow_maintainer_edit: bool, assignee: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, assignees: list<record>, base: record<label: string, ref: string, repo: record, repo_id: int, sha: string>, body: string, closed_at: string, comments: int, created_at: string, diff_url: string, due_date: string, head: record<label: string, ref: string, repo: record, repo_id: int, sha: string>, html_url: string, id: int, is_locked: bool, labels: list<record>, merge_base: string, merge_commit_sha: string, mergeable: bool, merged: bool, merged_at: string, merged_by: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, milestone: record<closed_at: string, closed_issues: int, created_at: string, description: string, due_on: string, id: int, open_issues: int, state: string, title: string, updated_at: string>, number: int, patch_url: string, state: string, title: string, updated_at: string, url: string, user: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>>
# operationId: repoListPullRequests
export def "repo-list-pull-requests" [
  owner: string
  repo: string
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
  --state: string@state-completer-1 # State of pull request: open or closed (optional)
  --sort: string@sort-completer-1 # Type of sort
  --milestone: int # ID of the milestone (format: int64)
  --labels: list<int> # Label IDs
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/repos/{owner}/{repo}/pulls"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}]
    query: [{name: state, var: state}, {name: sort, var: sort}, {name: milestone, var: milestone}, {name: labels, var: labels, style: multi}, {name: page, var: page}, {name: limit, var: limit}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, state: $state, sort: $sort, milestone: $milestone, labels: $labels, page: $page, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a pull request
#
# POST /repos/{owner}/{repo}/pulls
# Returns: record<allow_maintainer_edit: bool, assignee: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, assignees: table<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, base: record<label: string, ref: string, repo: record<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record, external_wiki: record, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record, parent: any, permissions: record, private: bool, release_counter: int, repo_transfer: record, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>, repo_id: int, sha: string>, body: string, closed_at: string, comments: int, created_at: string, diff_url: string, due_date: string, head: record<label: string, ref: string, repo: record<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record, external_wiki: record, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record, parent: any, permissions: record, private: bool, release_counter: int, repo_transfer: record, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>, repo_id: int, sha: string>, html_url: string, id: int, is_locked: bool, labels: table<color: string, description: string, exclusive: bool, id: int, name: string, url: string>, merge_base: string, merge_commit_sha: string, mergeable: bool, merged: bool, merged_at: string, merged_by: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, milestone: record<closed_at: string, closed_issues: int, created_at: string, description: string, due_on: string, id: int, open_issues: int, state: string, title: string, updated_at: string>, number: int, patch_url: string, state: string, title: string, updated_at: string, url: string, user: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>>
# operationId: repoCreatePullRequest
export def "repo-create-pull-request" [
  owner: string
  repo: string
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
  --assignee: string
  --assignees: list<string>
  --base: string
  --body: string
  --due-date: string # format: date-time
  --head: string
  --labels: list<int>
  --milestone: int # format: int64
  --title: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/repos/{owner}/{repo}/pulls"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}]
    body: {content_type: "application/json", kind: json, fields: [{name: assignee, var: assignee}, {name: assignees, var: assignees}, {name: base, var: base}, {name: body, var: body}, {name: due_date, var: due_date}, {name: head, var: head}, {name: labels, var: labels}, {name: milestone, var: milestone}, {name: title, var: title}]}
    accept: ["application/json", "text/html"]
    ok: [201]
    auth: basic
  } {
    owner: $owner, repo: $repo, assignee: $assignee, assignees: $assignees, base: $base, body: $body, due_date: $due_date, head: $head, labels: $labels, milestone: $milestone, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a pull request
#
# GET /repos/{owner}/{repo}/pulls/{index}
# Returns: record<allow_maintainer_edit: bool, assignee: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, assignees: table<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, base: record<label: string, ref: string, repo: record<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record, external_wiki: record, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record, parent: any, permissions: record, private: bool, release_counter: int, repo_transfer: record, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>, repo_id: int, sha: string>, body: string, closed_at: string, comments: int, created_at: string, diff_url: string, due_date: string, head: record<label: string, ref: string, repo: record<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record, external_wiki: record, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record, parent: any, permissions: record, private: bool, release_counter: int, repo_transfer: record, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>, repo_id: int, sha: string>, html_url: string, id: int, is_locked: bool, labels: table<color: string, description: string, exclusive: bool, id: int, name: string, url: string>, merge_base: string, merge_commit_sha: string, mergeable: bool, merged: bool, merged_at: string, merged_by: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, milestone: record<closed_at: string, closed_issues: int, created_at: string, description: string, due_on: string, id: int, open_issues: int, state: string, title: string, updated_at: string>, number: int, patch_url: string, state: string, title: string, updated_at: string, url: string, user: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>>
# operationId: repoGetPullRequest
export def "repo-get-pull-request" [
  owner: string
  repo: string
  index: int
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
    path: "/repos/{owner}/{repo}/pulls/{index}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: index, var: index}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, index: $index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a pull request. If using deadline only the date will be taken into account, and time of day ignored.
#
# PATCH /repos/{owner}/{repo}/pulls/{index}
# Returns: record<allow_maintainer_edit: bool, assignee: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, assignees: table<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, base: record<label: string, ref: string, repo: record<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record, external_wiki: record, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record, parent: any, permissions: record, private: bool, release_counter: int, repo_transfer: record, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>, repo_id: int, sha: string>, body: string, closed_at: string, comments: int, created_at: string, diff_url: string, due_date: string, head: record<label: string, ref: string, repo: record<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record, external_wiki: record, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record, parent: any, permissions: record, private: bool, release_counter: int, repo_transfer: record, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>, repo_id: int, sha: string>, html_url: string, id: int, is_locked: bool, labels: table<color: string, description: string, exclusive: bool, id: int, name: string, url: string>, merge_base: string, merge_commit_sha: string, mergeable: bool, merged: bool, merged_at: string, merged_by: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, milestone: record<closed_at: string, closed_issues: int, created_at: string, description: string, due_on: string, id: int, open_issues: int, state: string, title: string, updated_at: string>, number: int, patch_url: string, state: string, title: string, updated_at: string, url: string, user: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>>
# operationId: repoEditPullRequest
export def "repo-edit-pull-request" [
  owner: string
  repo: string
  index: int
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
  --allow-maintainer-edit: oneof<nothing, bool>
  --assignee: string
  --assignees: list<string>
  --base: string
  --body: string
  --due-date: string # format: date-time
  --labels: list<int>
  --milestone: int # format: int64
  --state: string
  --title: string
  --unset-due-date: oneof<nothing, bool>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/repos/{owner}/{repo}/pulls/{index}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: index, var: index}]
    body: {content_type: "application/json", kind: json, fields: [{name: allow_maintainer_edit, var: allow_maintainer_edit}, {name: assignee, var: assignee}, {name: assignees, var: assignees}, {name: base, var: base}, {name: body, var: body}, {name: due_date, var: due_date}, {name: labels, var: labels}, {name: milestone, var: milestone}, {name: state, var: state}, {name: title, var: title}, {name: unset_due_date, var: unset_due_date}]}
    accept: ["application/json", "text/html"]
    ok: [201]
    auth: basic
  } {
    owner: $owner, repo: $repo, index: $index, allow_maintainer_edit: $allow_maintainer_edit, assignee: $assignee, assignees: $assignees, base: $base, body: $body, due_date: $due_date, labels: $labels, milestone: $milestone, state: $state, title: $title, unset_due_date: $unset_due_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a pull request diff or patch
#
# GET /repos/{owner}/{repo}/pulls/{index}.{diffType}
# Returns: string
# operationId: repoDownloadPullDiffOrPatch
export def "repo-download-pull-diff-or-patch" [
  owner: string
  repo: string
  index: int
  diff_type: string@diff-type-completer
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
  --binary: oneof<nothing, bool> # whether to include binary file changes. if true, the diff is applicable with `git apply`
]: nothing -> any {
  http-request {
    method: get
    path: "/repos/{owner}/{repo}/pulls/{index}.{diffType}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: index, var: index}, {name: diffType, var: diff_type}]
    query: [{name: binary, var: binary}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, index: $index, diff_type: $diff_type, binary: $binary
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get commits for a pull request
#
# GET /repos/{owner}/{repo}/pulls/{index}/commits
# Returns: table<author: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, commit: record<author: record, committer: record, message: string, tree: record, url: string, verification: record>, committer: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, created: string, files: list<record>, html_url: string, parents: list<record>, sha: string, stats: record<additions: int, deletions: int, total: int>, url: string>
# operationId: repoGetPullRequestCommits
export def "repo-get-pull-request-commits" [
  owner: string
  repo: string
  index: int
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
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/repos/{owner}/{repo}/pulls/{index}/commits"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: index, var: index}]
    query: [{name: page, var: page}, {name: limit, var: limit}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, index: $index, page: $page, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get changed files for a pull request
#
# GET /repos/{owner}/{repo}/pulls/{index}/files
# Returns: table<additions: int, changes: int, contents_url: string, deletions: int, filename: string, html_url: string, previous_filename: string, raw_url: string, status: string>
# operationId: repoGetPullRequestFiles
export def "repo-get-pull-request-files" [
  owner: string
  repo: string
  index: int
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
  --skip-to: string # skip to given file
  --whitespace: string@whitespace-completer # whitespace behavior
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/repos/{owner}/{repo}/pulls/{index}/files"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: index, var: index}]
    query: [{name: skip-to, var: skip_to}, {name: whitespace, var: whitespace}, {name: page, var: page}, {name: limit, var: limit}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, index: $index, skip_to: $skip_to, whitespace: $whitespace, page: $page, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Cancel the scheduled auto merge for the given pull request
#
# DELETE /repos/{owner}/{repo}/pulls/{index}/merge
# operationId: repoCancelScheduledAutoMerge
export def "repo-cancel-scheduled-auto-merge" [
  owner: string
  repo: string
  index: int
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
    path: "/repos/{owner}/{repo}/pulls/{index}/merge"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: index, var: index}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    owner: $owner, repo: $repo, index: $index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check if a pull request has been merged
#
# GET /repos/{owner}/{repo}/pulls/{index}/merge
# operationId: repoPullRequestIsMerged
export def "repo-pull-request-is-merged" [
  owner: string
  repo: string
  index: int
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
    path: "/repos/{owner}/{repo}/pulls/{index}/merge"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: index, var: index}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    owner: $owner, repo: $repo, index: $index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Merge a pull request
#
# POST /repos/{owner}/{repo}/pulls/{index}/merge
# operationId: repoMergePullRequest
export def "repo-merge-pull-request" [
  owner: string
  repo: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  do: string@do-completer
  --merge-commit-id: string
  --merge-message-field: string
  --merge-title-field: string
  --delete-branch-after-merge: oneof<nothing, bool>
  --force-merge: oneof<nothing, bool>
  --head-commit-id: string
  --merge-when-checks-succeed: oneof<nothing, bool>
]: any -> any {
  $in | http-request {
    method: post
    path: "/repos/{owner}/{repo}/pulls/{index}/merge"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: index, var: index}]
    body: {content_type: "application/json", kind: json, fields: [{name: Do, var: do}, {name: MergeCommitID, var: merge_commit_id}, {name: MergeMessageField, var: merge_message_field}, {name: MergeTitleField, var: merge_title_field}, {name: delete_branch_after_merge, var: delete_branch_after_merge}, {name: force_merge, var: force_merge}, {name: head_commit_id, var: head_commit_id}, {name: merge_when_checks_succeed, var: merge_when_checks_succeed}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, index: $index, do: $do, merge_commit_id: $merge_commit_id, merge_message_field: $merge_message_field, merge_title_field: $merge_title_field, delete_branch_after_merge: $delete_branch_after_merge, force_merge: $force_merge, head_commit_id: $head_commit_id, merge_when_checks_succeed: $merge_when_checks_succeed
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# cancel review requests for a pull request
#
# DELETE /repos/{owner}/{repo}/pulls/{index}/requested_reviewers
# operationId: repoDeletePullReviewRequests
export def "repo-delete-pull-review-requests" [
  owner: string
  repo: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --reviewers: list<string>
  --team-reviewers: list<string>
]: any -> any {
  $in | http-request {
    method: delete
    path: "/repos/{owner}/{repo}/pulls/{index}/requested_reviewers"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: index, var: index}]
    body: {content_type: "application/json", kind: json, fields: [{name: reviewers, var: reviewers}, {name: team_reviewers, var: team_reviewers}]}
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    owner: $owner, repo: $repo, index: $index, reviewers: $reviewers, team_reviewers: $team_reviewers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# create review requests for a pull request
#
# POST /repos/{owner}/{repo}/pulls/{index}/requested_reviewers
# Returns: table<body: string, comments_count: int, commit_id: string, dismissed: bool, html_url: string, id: int, official: bool, pull_request_url: string, stale: bool, state: string, submitted_at: string, team: record<can_create_org_repo: bool, description: string, id: int, includes_all_repositories: bool, name: string, organization: record, permission: string, units: list, units_map: record>, updated_at: string, user: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>>
# operationId: repoCreatePullReviewRequests
export def "repo-create-pull-review-requests" [
  owner: string
  repo: string
  index: int
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
  --reviewers: list<string>
  --team-reviewers: list<string>
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/repos/{owner}/{repo}/pulls/{index}/requested_reviewers"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: index, var: index}]
    body: {content_type: "application/json", kind: json, fields: [{name: reviewers, var: reviewers}, {name: team_reviewers, var: team_reviewers}]}
    accept: ["application/json", "text/html"]
    ok: [201]
    auth: basic
  } {
    owner: $owner, repo: $repo, index: $index, reviewers: $reviewers, team_reviewers: $team_reviewers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List all reviews for a pull request
#
# GET /repos/{owner}/{repo}/pulls/{index}/reviews
# Returns: table<body: string, comments_count: int, commit_id: string, dismissed: bool, html_url: string, id: int, official: bool, pull_request_url: string, stale: bool, state: string, submitted_at: string, team: record<can_create_org_repo: bool, description: string, id: int, includes_all_repositories: bool, name: string, organization: record, permission: string, units: list, units_map: record>, updated_at: string, user: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>>
# operationId: repoListPullReviews
export def "repo-list-pull-reviews" [
  owner: string
  repo: string
  index: int
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
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/repos/{owner}/{repo}/pulls/{index}/reviews"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: index, var: index}]
    query: [{name: page, var: page}, {name: limit, var: limit}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, index: $index, page: $page, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a review to an pull request
#
# POST /repos/{owner}/{repo}/pulls/{index}/reviews
# Returns: record<body: string, comments_count: int, commit_id: string, dismissed: bool, html_url: string, id: int, official: bool, pull_request_url: string, stale: bool, state: string, submitted_at: string, team: record<can_create_org_repo: bool, description: string, id: int, includes_all_repositories: bool, name: string, organization: record<avatar_url: string, description: string, full_name: string, id: int, location: string, name: string, repo_admin_change_team_access: bool, username: string, visibility: string, website: string>, permission: string, units: list<string>, units_map: record>, updated_at: string, user: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>>
# operationId: repoCreatePullReview
export def "repo-create-pull-review" [
  owner: string
  repo: string
  index: int
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
  --body: string
  --comments: list # item shape: {body?: string, new_position?: int, old_position?: int, path?: string}
  --commit-id: string
  --event: string # ReviewStateType review state type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/repos/{owner}/{repo}/pulls/{index}/reviews"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: index, var: index}]
    body: {content_type: "application/json", kind: json, fields: [{name: body, var: body}, {name: comments, var: comments}, {name: commit_id, var: commit_id}, {name: event, var: event}]}
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, index: $index, body: $body, comments: $comments, commit_id: $commit_id, event: $event
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a specific review from a pull request
#
# DELETE /repos/{owner}/{repo}/pulls/{index}/reviews/{id}
# operationId: repoDeletePullReview
export def "repo-delete-pull-review" [
  owner: string
  repo: string
  index: int
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
    path: "/repos/{owner}/{repo}/pulls/{index}/reviews/{id}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: index, var: index}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    owner: $owner, repo: $repo, index: $index, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific review for a pull request
#
# GET /repos/{owner}/{repo}/pulls/{index}/reviews/{id}
# Returns: record<body: string, comments_count: int, commit_id: string, dismissed: bool, html_url: string, id: int, official: bool, pull_request_url: string, stale: bool, state: string, submitted_at: string, team: record<can_create_org_repo: bool, description: string, id: int, includes_all_repositories: bool, name: string, organization: record<avatar_url: string, description: string, full_name: string, id: int, location: string, name: string, repo_admin_change_team_access: bool, username: string, visibility: string, website: string>, permission: string, units: list<string>, units_map: record>, updated_at: string, user: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>>
# operationId: repoGetPullReview
export def "repo-get-pull-review" [
  owner: string
  repo: string
  index: int
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/repos/{owner}/{repo}/pulls/{index}/reviews/{id}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: index, var: index}, {name: id, var: id}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, index: $index, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Submit a pending review to an pull request
#
# POST /repos/{owner}/{repo}/pulls/{index}/reviews/{id}
# Returns: record<body: string, comments_count: int, commit_id: string, dismissed: bool, html_url: string, id: int, official: bool, pull_request_url: string, stale: bool, state: string, submitted_at: string, team: record<can_create_org_repo: bool, description: string, id: int, includes_all_repositories: bool, name: string, organization: record<avatar_url: string, description: string, full_name: string, id: int, location: string, name: string, repo_admin_change_team_access: bool, username: string, visibility: string, website: string>, permission: string, units: list<string>, units_map: record>, updated_at: string, user: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>>
# operationId: repoSubmitPullReview
export def "repo-submit-pull-review" [
  owner: string
  repo: string
  index: int
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
  --accept: string@accept-completer # Response content type
  --body: string
  --event: string # ReviewStateType review state type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/repos/{owner}/{repo}/pulls/{index}/reviews/{id}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: index, var: index}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: body, var: body}, {name: event, var: event}]}
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, index: $index, id: $id, body: $body, event: $event
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a specific review for a pull request
#
# GET /repos/{owner}/{repo}/pulls/{index}/reviews/{id}/comments
# Returns: table<body: string, commit_id: string, created_at: string, diff_hunk: string, html_url: string, id: int, original_commit_id: string, original_position: int, path: string, position: int, pull_request_review_id: int, pull_request_url: string, resolver: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, updated_at: string, user: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>>
# operationId: repoGetPullReviewComments
export def "repo-get-pull-review-comments" [
  owner: string
  repo: string
  index: int
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/repos/{owner}/{repo}/pulls/{index}/reviews/{id}/comments"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: index, var: index}, {name: id, var: id}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, index: $index, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Dismiss a review for a pull request
#
# POST /repos/{owner}/{repo}/pulls/{index}/reviews/{id}/dismissals
# Returns: record<body: string, comments_count: int, commit_id: string, dismissed: bool, html_url: string, id: int, official: bool, pull_request_url: string, stale: bool, state: string, submitted_at: string, team: record<can_create_org_repo: bool, description: string, id: int, includes_all_repositories: bool, name: string, organization: record<avatar_url: string, description: string, full_name: string, id: int, location: string, name: string, repo_admin_change_team_access: bool, username: string, visibility: string, website: string>, permission: string, units: list<string>, units_map: record>, updated_at: string, user: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>>
# operationId: repoDismissPullReview
export def "repo-dismiss-pull-review" [
  owner: string
  repo: string
  index: int
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
  --accept: string@accept-completer # Response content type
  --message: string
  --priors: oneof<nothing, bool>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/repos/{owner}/{repo}/pulls/{index}/reviews/{id}/dismissals"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: index, var: index}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: message, var: message}, {name: priors, var: priors}]}
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, index: $index, id: $id, message: $message, priors: $priors
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Cancel to dismiss a review for a pull request
#
# POST /repos/{owner}/{repo}/pulls/{index}/reviews/{id}/undismissals
# Returns: record<body: string, comments_count: int, commit_id: string, dismissed: bool, html_url: string, id: int, official: bool, pull_request_url: string, stale: bool, state: string, submitted_at: string, team: record<can_create_org_repo: bool, description: string, id: int, includes_all_repositories: bool, name: string, organization: record<avatar_url: string, description: string, full_name: string, id: int, location: string, name: string, repo_admin_change_team_access: bool, username: string, visibility: string, website: string>, permission: string, units: list<string>, units_map: record>, updated_at: string, user: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>>
# operationId: repoUnDismissPullReview
export def "repo-un-dismiss-pull-review" [
  owner: string
  repo: string
  index: int
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/repos/{owner}/{repo}/pulls/{index}/reviews/{id}/undismissals"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: index, var: index}, {name: id, var: id}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, index: $index, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Merge PR's baseBranch into headBranch
#
# POST /repos/{owner}/{repo}/pulls/{index}/update
# operationId: repoUpdatePullRequest
export def "repo-update-pull-request" [
  owner: string
  repo: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --style: string@style-completer # how to update pull request
]: nothing -> any {
  http-request {
    method: post
    path: "/repos/{owner}/{repo}/pulls/{index}/update"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: index, var: index}]
    query: [{name: style, var: style}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, index: $index, style: $style
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all push mirrors of the repository
#
# GET /repos/{owner}/{repo}/push_mirrors
# Returns: table<created: string, interval: string, last_error: string, last_update: string, remote_address: string, remote_name: string, repo_name: string, sync_on_commit: bool>
# operationId: repoListPushMirrors
export def "repo-list-push-mirrors" [
  owner: string
  repo: string
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
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/repos/{owner}/{repo}/push_mirrors"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}]
    query: [{name: page, var: page}, {name: limit, var: limit}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, page: $page, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# add a push mirror to the repository
#
# POST /repos/{owner}/{repo}/push_mirrors
# Returns: record<created: string, interval: string, last_error: string, last_update: string, remote_address: string, remote_name: string, repo_name: string, sync_on_commit: bool>
# operationId: repoAddPushMirror
export def "repo-add-push-mirror" [
  owner: string
  repo: string
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
  --interval: string
  --remote-address: string
  --remote-password: string
  --remote-username: string
  --sync-on-commit: oneof<nothing, bool>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/repos/{owner}/{repo}/push_mirrors"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}]
    body: {content_type: "application/json", kind: json, fields: [{name: interval, var: interval}, {name: remote_address, var: remote_address}, {name: remote_password, var: remote_password}, {name: remote_username, var: remote_username}, {name: sync_on_commit, var: sync_on_commit}]}
    accept: ["application/json", "text/html"]
    ok: [201]
    auth: basic
  } {
    owner: $owner, repo: $repo, interval: $interval, remote_address: $remote_address, remote_password: $remote_password, remote_username: $remote_username, sync_on_commit: $sync_on_commit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Sync all push mirrored repository
#
# POST /repos/{owner}/{repo}/push_mirrors-sync
# operationId: repoPushMirrorSync
export def "repo-push-mirror-sync" [
  owner: string
  repo: string
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
    path: "/repos/{owner}/{repo}/push_mirrors-sync"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# deletes a push mirror from a repository by remoteName
#
# DELETE /repos/{owner}/{repo}/push_mirrors/{name}
# operationId: repoDeletePushMirror
export def "repo-delete-push-mirror" [
  owner: string
  repo: string
  name: string
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
    path: "/repos/{owner}/{repo}/push_mirrors/{name}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: name, var: name}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    owner: $owner, repo: $repo, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get push mirror of the repository by remoteName
#
# GET /repos/{owner}/{repo}/push_mirrors/{name}
# Returns: record<created: string, interval: string, last_error: string, last_update: string, remote_address: string, remote_name: string, repo_name: string, sync_on_commit: bool>
# operationId: repoGetPushMirrorByRemoteName
export def "repo-get-push-mirror-by-remote-name" [
  owner: string
  repo: string
  name: string
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
    path: "/repos/{owner}/{repo}/push_mirrors/{name}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: name, var: name}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a file from a repository
#
# GET /repos/{owner}/{repo}/raw/{filepath}
# operationId: repoGetRawFile
export def "repo-get-raw-file" [
  owner: string
  repo: string
  filepath: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ref: string # The name of the commit/branch/tag. Default the repository’s default branch (usually master)
]: nothing -> any {
  http-request {
    method: get
    path: "/repos/{owner}/{repo}/raw/{filepath}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: filepath, var: filepath}]
    query: [{name: ref, var: ref}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, filepath: $filepath, ref: $ref
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List a repo's releases
#
# GET /repos/{owner}/{repo}/releases
# Returns: table<assets: list<record>, author: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, body: string, created_at: string, draft: bool, html_url: string, id: int, name: string, prerelease: bool, published_at: string, tag_name: string, tarball_url: string, target_commitish: string, url: string, zipball_url: string>
# operationId: repoListReleases
export def "repo-list-releases" [
  owner: string
  repo: string
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
  --draft: oneof<nothing, bool> # filter (exclude / include) drafts, if you dont have repo write access none will show
  --pre-release: oneof<nothing, bool> # filter (exclude / include) pre-releases
  --per-page: int # page size of results, deprecated - use limit
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/repos/{owner}/{repo}/releases"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}]
    query: [{name: draft, var: draft}, {name: pre-release, var: pre_release}, {name: per_page, var: per_page}, {name: page, var: page}, {name: limit, var: limit}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, draft: $draft, pre_release: $pre_release, per_page: $per_page, page: $page, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a release
#
# POST /repos/{owner}/{repo}/releases
# Returns: record<assets: table<browser_download_url: string, created_at: string, download_count: int, id: int, name: string, size: int, uuid: string>, author: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, body: string, created_at: string, draft: bool, html_url: string, id: int, name: string, prerelease: bool, published_at: string, tag_name: string, tarball_url: string, target_commitish: string, url: string, zipball_url: string>
# operationId: repoCreateRelease
export def "repo-create-release" [
  owner: string
  repo: string
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
  --body: string
  --draft: oneof<nothing, bool>
  --name: string
  --prerelease: oneof<nothing, bool>
  tag_name: string
  --target-commitish: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/repos/{owner}/{repo}/releases"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}]
    body: {content_type: "application/json", kind: json, fields: [{name: body, var: body}, {name: draft, var: draft}, {name: name, var: name}, {name: prerelease, var: prerelease}, {name: tag_name, var: tag_name}, {name: target_commitish, var: target_commitish}]}
    accept: ["application/json", "text/html"]
    ok: [201]
    auth: basic
  } {
    owner: $owner, repo: $repo, body: $body, draft: $draft, name: $name, prerelease: $prerelease, tag_name: $tag_name, target_commitish: $target_commitish
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the most recent non-prerelease, non-draft release of a repository, sorted by created_at
#
# GET /repos/{owner}/{repo}/releases/latest
# Returns: record<assets: table<browser_download_url: string, created_at: string, download_count: int, id: int, name: string, size: int, uuid: string>, author: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, body: string, created_at: string, draft: bool, html_url: string, id: int, name: string, prerelease: bool, published_at: string, tag_name: string, tarball_url: string, target_commitish: string, url: string, zipball_url: string>
# operationId: repoGetLatestRelease
export def "repo-get-latest-release" [
  owner: string
  repo: string
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
    path: "/repos/{owner}/{repo}/releases/latest"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a release by tag name
#
# DELETE /repos/{owner}/{repo}/releases/tags/{tag}
# operationId: repoDeleteReleaseByTag
export def "repo-delete-release-by-tag" [
  owner: string
  repo: string
  tag: string
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
    path: "/repos/{owner}/{repo}/releases/tags/{tag}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: tag, var: tag}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    owner: $owner, repo: $repo, tag: $tag
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a release by tag name
#
# GET /repos/{owner}/{repo}/releases/tags/{tag}
# Returns: record<assets: table<browser_download_url: string, created_at: string, download_count: int, id: int, name: string, size: int, uuid: string>, author: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, body: string, created_at: string, draft: bool, html_url: string, id: int, name: string, prerelease: bool, published_at: string, tag_name: string, tarball_url: string, target_commitish: string, url: string, zipball_url: string>
# operationId: repoGetReleaseByTag
export def "repo-get-release-by-tag" [
  owner: string
  repo: string
  tag: string
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
    path: "/repos/{owner}/{repo}/releases/tags/{tag}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: tag, var: tag}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, tag: $tag
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a release
#
# DELETE /repos/{owner}/{repo}/releases/{id}
# operationId: repoDeleteRelease
export def "repo-delete-release" [
  owner: string
  repo: string
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
    path: "/repos/{owner}/{repo}/releases/{id}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    owner: $owner, repo: $repo, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a release
#
# GET /repos/{owner}/{repo}/releases/{id}
# Returns: record<assets: table<browser_download_url: string, created_at: string, download_count: int, id: int, name: string, size: int, uuid: string>, author: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, body: string, created_at: string, draft: bool, html_url: string, id: int, name: string, prerelease: bool, published_at: string, tag_name: string, tarball_url: string, target_commitish: string, url: string, zipball_url: string>
# operationId: repoGetRelease
export def "repo-get-release" [
  owner: string
  repo: string
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/repos/{owner}/{repo}/releases/{id}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: id, var: id}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a release
#
# PATCH /repos/{owner}/{repo}/releases/{id}
# Returns: record<assets: table<browser_download_url: string, created_at: string, download_count: int, id: int, name: string, size: int, uuid: string>, author: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, body: string, created_at: string, draft: bool, html_url: string, id: int, name: string, prerelease: bool, published_at: string, tag_name: string, tarball_url: string, target_commitish: string, url: string, zipball_url: string>
# operationId: repoEditRelease
export def "repo-edit-release" [
  owner: string
  repo: string
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
  --accept: string@accept-completer # Response content type
  --body: string
  --draft: oneof<nothing, bool>
  --name: string
  --prerelease: oneof<nothing, bool>
  --tag-name: string
  --target-commitish: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/repos/{owner}/{repo}/releases/{id}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: body, var: body}, {name: draft, var: draft}, {name: name, var: name}, {name: prerelease, var: prerelease}, {name: tag_name, var: tag_name}, {name: target_commitish, var: target_commitish}]}
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, id: $id, body: $body, draft: $draft, name: $name, prerelease: $prerelease, tag_name: $tag_name, target_commitish: $target_commitish
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List release's attachments
#
# GET /repos/{owner}/{repo}/releases/{id}/assets
# Returns: table<browser_download_url: string, created_at: string, download_count: int, id: int, name: string, size: int, uuid: string>
# operationId: repoListReleaseAttachments
export def "repo-list-release-attachments" [
  owner: string
  repo: string
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/repos/{owner}/{repo}/releases/{id}/assets"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: id, var: id}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a release attachment
#
# POST /repos/{owner}/{repo}/releases/{id}/assets
# Returns: record<browser_download_url: string, created_at: string, download_count: int, id: int, name: string, size: int, uuid: string>
# operationId: repoCreateReleaseAttachment
export def "repo-create-release-attachment" [
  owner: string
  repo: string
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
  --accept: string@accept-completer # Response content type
  --name: string # name of the attachment
  attachment: string # attachment to upload (format: binary)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/repos/{owner}/{repo}/releases/{id}/assets"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: id, var: id}]
    query: [{name: name, var: name}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: attachment, var: attachment}], files: [attachment]}
    accept: ["application/json", "text/html"]
    ok: [201]
    auth: basic
  } {
    owner: $owner, repo: $repo, id: $id, name: $name, attachment: $attachment
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a release attachment
#
# DELETE /repos/{owner}/{repo}/releases/{id}/assets/{attachment_id}
# operationId: repoDeleteReleaseAttachment
export def "repo-delete-release-attachment" [
  owner: string
  repo: string
  id: int
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
    path: "/repos/{owner}/{repo}/releases/{id}/assets/{attachment_id}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: id, var: id}, {name: attachment_id, var: attachment_id}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    owner: $owner, repo: $repo, id: $id, attachment_id: $attachment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a release attachment
#
# GET /repos/{owner}/{repo}/releases/{id}/assets/{attachment_id}
# Returns: record<browser_download_url: string, created_at: string, download_count: int, id: int, name: string, size: int, uuid: string>
# operationId: repoGetReleaseAttachment
export def "repo-get-release-attachment" [
  owner: string
  repo: string
  id: int
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/repos/{owner}/{repo}/releases/{id}/assets/{attachment_id}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: id, var: id}, {name: attachment_id, var: attachment_id}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, id: $id, attachment_id: $attachment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Edit a release attachment
#
# PATCH /repos/{owner}/{repo}/releases/{id}/assets/{attachment_id}
# Returns: record<browser_download_url: string, created_at: string, download_count: int, id: int, name: string, size: int, uuid: string>
# operationId: repoEditReleaseAttachment
export def "repo-edit-release-attachment" [
  owner: string
  repo: string
  id: int
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
  --accept: string@accept-completer # Response content type
  --name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/repos/{owner}/{repo}/releases/{id}/assets/{attachment_id}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: id, var: id}, {name: attachment_id, var: attachment_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json", "text/html"]
    ok: [201]
    auth: basic
  } {
    owner: $owner, repo: $repo, id: $id, attachment_id: $attachment_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Return all users that can be requested to review in this repo
#
# GET /repos/{owner}/{repo}/reviewers
# Returns: table<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>
# operationId: repoGetReviewers
export def "repo-get-reviewers" [
  owner: string
  repo: string
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
    path: "/repos/{owner}/{repo}/reviewers"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get signing-key.gpg for given repository
#
# GET /repos/{owner}/{repo}/signing-key.gpg
# Returns: string
# operationId: repoSigningKey
export def "repo-signing-key" [
  owner: string
  repo: string
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
    path: "/repos/{owner}/{repo}/signing-key.gpg"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}]
    accept: ["text/plain"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List a repo's stargazers
#
# GET /repos/{owner}/{repo}/stargazers
# Returns: table<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>
# operationId: repoListStargazers
export def "repo-list-stargazers" [
  owner: string
  repo: string
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
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/repos/{owner}/{repo}/stargazers"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}]
    query: [{name: page, var: page}, {name: limit, var: limit}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, page: $page, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a commit's statuses
#
# GET /repos/{owner}/{repo}/statuses/{sha}
# Returns: table<context: string, created_at: string, creator: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, description: string, id: int, status: string, target_url: string, updated_at: string, url: string>
# operationId: repoListStatuses
export def "repo-list-statuses" [
  owner: string
  repo: string
  sha: string
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
  --sort: string@sort-completer # type of sort
  --state: string@state-completer # type of state
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/repos/{owner}/{repo}/statuses/{sha}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: sha, var: sha}]
    query: [{name: sort, var: sort}, {name: state, var: state}, {name: page, var: page}, {name: limit, var: limit}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, sha: $sha, sort: $sort, state: $state, page: $page, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a commit status
#
# POST /repos/{owner}/{repo}/statuses/{sha}
# Returns: record<context: string, created_at: string, creator: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, description: string, id: int, status: string, target_url: string, updated_at: string, url: string>
# operationId: repoCreateStatus
export def "repo-create-status" [
  owner: string
  repo: string
  sha: string
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
  --context: string
  --description: string
  --state: string # CommitStatusState holds the state of a CommitStatus It can be "pending", "success", "error", "failure", and "warning"
  --target-url: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/repos/{owner}/{repo}/statuses/{sha}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: sha, var: sha}]
    body: {content_type: "application/json", kind: json, fields: [{name: context, var: context}, {name: description, var: description}, {name: state, var: state}, {name: target_url, var: target_url}]}
    accept: ["application/json", "text/html"]
    ok: [201]
    auth: basic
  } {
    owner: $owner, repo: $repo, sha: $sha, context: $context, description: $description, state: $state, target_url: $target_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List a repo's watchers
#
# GET /repos/{owner}/{repo}/subscribers
# Returns: table<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>
# operationId: repoListSubscribers
export def "repo-list-subscribers" [
  owner: string
  repo: string
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
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/repos/{owner}/{repo}/subscribers"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}]
    query: [{name: page, var: page}, {name: limit, var: limit}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, page: $page, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Unwatch a repo
#
# DELETE /repos/{owner}/{repo}/subscription
# operationId: userCurrentDeleteSubscription
export def "user-current-delete-subscription" [
  owner: string
  repo: string
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
    path: "/repos/{owner}/{repo}/subscription"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    owner: $owner, repo: $repo
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check if the current user is watching a repo
#
# GET /repos/{owner}/{repo}/subscription
# Returns: record<created_at: string, ignored: bool, reason: any, repository_url: string, subscribed: bool, url: string>
# operationId: userCurrentCheckSubscription
export def "user-current-check-subscription" [
  owner: string
  repo: string
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
    path: "/repos/{owner}/{repo}/subscription"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Watch a repo
#
# PUT /repos/{owner}/{repo}/subscription
# Returns: record<created_at: string, ignored: bool, reason: any, repository_url: string, subscribed: bool, url: string>
# operationId: userCurrentPutSubscription
export def "user-current-put-subscription" [
  owner: string
  repo: string
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
    path: "/repos/{owner}/{repo}/subscription"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List a repository's tags
#
# GET /repos/{owner}/{repo}/tags
# Returns: table<commit: record<created: string, sha: string, url: string>, id: string, message: string, name: string, tarball_url: string, zipball_url: string>
# operationId: repoListTags
export def "repo-list-tags" [
  owner: string
  repo: string
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
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results, default maximum page size is 50
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/repos/{owner}/{repo}/tags"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}]
    query: [{name: page, var: page}, {name: limit, var: limit}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, page: $page, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a new git tag in a repository
#
# POST /repos/{owner}/{repo}/tags
# Returns: record<commit: record<created: string, sha: string, url: string>, id: string, message: string, name: string, tarball_url: string, zipball_url: string>
# operationId: repoCreateTag
export def "repo-create-tag" [
  owner: string
  repo: string
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
  --message: string
  tag_name: string
  --target: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/repos/{owner}/{repo}/tags"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}]
    body: {content_type: "application/json", kind: json, fields: [{name: message, var: message}, {name: tag_name, var: tag_name}, {name: target, var: target}]}
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, message: $message, tag_name: $tag_name, target: $target
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a repository's tag by name
#
# DELETE /repos/{owner}/{repo}/tags/{tag}
# operationId: repoDeleteTag
export def "repo-delete-tag" [
  owner: string
  repo: string
  tag: string
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
    path: "/repos/{owner}/{repo}/tags/{tag}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: tag, var: tag}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    owner: $owner, repo: $repo, tag: $tag
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the tag of a repository by tag name
#
# GET /repos/{owner}/{repo}/tags/{tag}
# Returns: record<commit: record<created: string, sha: string, url: string>, id: string, message: string, name: string, tarball_url: string, zipball_url: string>
# operationId: repoGetTag
export def "repo-get-tag" [
  owner: string
  repo: string
  tag: string
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
    path: "/repos/{owner}/{repo}/tags/{tag}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: tag, var: tag}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, tag: $tag
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List a repository's teams
#
# GET /repos/{owner}/{repo}/teams
# Returns: table<can_create_org_repo: bool, description: string, id: int, includes_all_repositories: bool, name: string, organization: record<avatar_url: string, description: string, full_name: string, id: int, location: string, name: string, repo_admin_change_team_access: bool, username: string, visibility: string, website: string>, permission: string, units: list<string>, units_map: record>
# operationId: repoListTeams
export def "repo-list-teams" [
  owner: string
  repo: string
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
    path: "/repos/{owner}/{repo}/teams"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a team from a repository
#
# DELETE /repos/{owner}/{repo}/teams/{team}
# operationId: repoDeleteTeam
export def "repo-delete-team" [
  owner: string
  repo: string
  team: string
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
    path: "/repos/{owner}/{repo}/teams/{team}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: team, var: team}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    owner: $owner, repo: $repo, team: $team
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check if a team is assigned to a repository
#
# GET /repos/{owner}/{repo}/teams/{team}
# Returns: record<can_create_org_repo: bool, description: string, id: int, includes_all_repositories: bool, name: string, organization: record<avatar_url: string, description: string, full_name: string, id: int, location: string, name: string, repo_admin_change_team_access: bool, username: string, visibility: string, website: string>, permission: string, units: list<string>, units_map: record>
# operationId: repoCheckTeam
export def "repo-check-team" [
  owner: string
  repo: string
  team: string
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
    path: "/repos/{owner}/{repo}/teams/{team}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: team, var: team}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, team: $team
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add a team to a repository
#
# PUT /repos/{owner}/{repo}/teams/{team}
# operationId: repoAddTeam
export def "repo-add-team" [
  owner: string
  repo: string
  team: string
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
    path: "/repos/{owner}/{repo}/teams/{team}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: team, var: team}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    owner: $owner, repo: $repo, team: $team
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List a repo's tracked times
#
# GET /repos/{owner}/{repo}/times
# Returns: table<created: string, id: int, issue: record<assets: list, assignee: record, assignees: list, body: string, closed_at: string, comments: int, created_at: string, due_date: string, html_url: string, id: int, is_locked: bool, labels: list, milestone: record, number: int, original_author: string, original_author_id: int, pull_request: record, ref: string, repository: record, state: string, title: string, updated_at: string, url: string, user: record>, issue_id: int, time: int, user_id: int, user_name: string>
# operationId: repoTrackedTimes
export def "repo-tracked-times" [
  owner: string
  repo: string
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
  --user: string # optional filter by user (available for issue managers)
  --since: string # Only show times updated after the given time. This is a timestamp in RFC 3339 format (format: date-time)
  --before: string # Only show times updated before the given time. This is a timestamp in RFC 3339 format (format: date-time)
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/repos/{owner}/{repo}/times"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}]
    query: [{name: user, var: user}, {name: since, var: since}, {name: before, var: before}, {name: page, var: page}, {name: limit, var: limit}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, user: $user, since: $since, before: $before, page: $page, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List a user's tracked times in a repo
#
# GET /repos/{owner}/{repo}/times/{user}
# DEPRECATED
# Returns: table<created: string, id: int, issue: record<assets: list, assignee: record, assignees: list, body: string, closed_at: string, comments: int, created_at: string, due_date: string, html_url: string, id: int, is_locked: bool, labels: list, milestone: record, number: int, original_author: string, original_author_id: int, pull_request: record, ref: string, repository: record, state: string, title: string, updated_at: string, url: string, user: record>, issue_id: int, time: int, user_id: int, user_name: string>
# operationId: userTrackedTimes
@deprecated
export def "user-tracked-times" [
  owner: string
  repo: string
  user: string
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
    path: "/repos/{owner}/{repo}/times/{user}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: user, var: user}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, user: $user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get list of topics that a repository has
#
# GET /repos/{owner}/{repo}/topics
# Returns: record<topics: list<string>>
# operationId: repoListTopics
export def "repo-list-topics" [
  owner: string
  repo: string
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
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/repos/{owner}/{repo}/topics"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}]
    query: [{name: page, var: page}, {name: limit, var: limit}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, page: $page, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Replace list of topics for a repository
#
# PUT /repos/{owner}/{repo}/topics
# operationId: repoUpdateTopics
export def "repo-update-topics" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --topics: list<string> # list of topic names
]: any -> any {
  $in | http-request {
    method: put
    path: "/repos/{owner}/{repo}/topics"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}]
    body: {content_type: "application/json", kind: json, fields: [{name: topics, var: topics}]}
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    owner: $owner, repo: $repo, topics: $topics
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a topic from a repository
#
# DELETE /repos/{owner}/{repo}/topics/{topic}
# operationId: repoDeleteTopic
export def "repo-delete-topic" [
  owner: string
  repo: string
  topic: string
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
    path: "/repos/{owner}/{repo}/topics/{topic}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: topic, var: topic}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    owner: $owner, repo: $repo, topic: $topic
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a topic to a repository
#
# PUT /repos/{owner}/{repo}/topics/{topic}
# operationId: repoAddTopic
export def "repo-add-topic" [
  owner: string
  repo: string
  topic: string
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
    path: "/repos/{owner}/{repo}/topics/{topic}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: topic, var: topic}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    owner: $owner, repo: $repo, topic: $topic
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Transfer a repo ownership
#
# POST /repos/{owner}/{repo}/transfer
# Returns: record<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record<external_tracker_format: string, external_tracker_regexp_pattern: string, external_tracker_style: string, external_tracker_url: string>, external_wiki: record<external_wiki_url: string>, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record<allow_only_contributors_to_track_time: bool, enable_issue_dependencies: bool, enable_time_tracker: bool>, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, parent: any, permissions: record<admin: bool, pull: bool, push: bool>, private: bool, release_counter: int, repo_transfer: record<doer: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, recipient: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, teams: list<record>>, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>
# operationId: repoTransfer
export def "repo-transfer" [
  owner: string
  repo: string
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
  new_owner: string
  --team-ids: list<int> # ID of the team or teams to add to the repository. Teams can only be added to organization-owned repositories.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/repos/{owner}/{repo}/transfer"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}]
    body: {content_type: "application/json", kind: json, fields: [{name: new_owner, var: new_owner}, {name: team_ids, var: team_ids}]}
    accept: ["application/json", "text/html"]
    ok: [202]
    auth: basic
  } {
    owner: $owner, repo: $repo, new_owner: $new_owner, team_ids: $team_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Accept a repo transfer
#
# POST /repos/{owner}/{repo}/transfer/accept
# Returns: record<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record<external_tracker_format: string, external_tracker_regexp_pattern: string, external_tracker_style: string, external_tracker_url: string>, external_wiki: record<external_wiki_url: string>, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record<allow_only_contributors_to_track_time: bool, enable_issue_dependencies: bool, enable_time_tracker: bool>, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, parent: any, permissions: record<admin: bool, pull: bool, push: bool>, private: bool, release_counter: int, repo_transfer: record<doer: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, recipient: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, teams: list<record>>, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>
# operationId: acceptRepoTransfer
export def "accept-repo-transfer" [
  owner: string
  repo: string
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
    path: "/repos/{owner}/{repo}/transfer/accept"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}]
    accept: ["application/json", "text/html"]
    ok: [202]
    auth: basic
  } {
    owner: $owner, repo: $repo
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Reject a repo transfer
#
# POST /repos/{owner}/{repo}/transfer/reject
# Returns: record<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record<external_tracker_format: string, external_tracker_regexp_pattern: string, external_tracker_style: string, external_tracker_url: string>, external_wiki: record<external_wiki_url: string>, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record<allow_only_contributors_to_track_time: bool, enable_issue_dependencies: bool, enable_time_tracker: bool>, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, parent: any, permissions: record<admin: bool, pull: bool, push: bool>, private: bool, release_counter: int, repo_transfer: record<doer: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, recipient: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, teams: list<record>>, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>
# operationId: rejectRepoTransfer
export def "reject-repo-transfer" [
  owner: string
  repo: string
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
    path: "/repos/{owner}/{repo}/transfer/reject"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a wiki page
#
# POST /repos/{owner}/{repo}/wiki/new
# Returns: record<commit_count: int, content_base64: string, footer: string, html_url: string, last_commit: record<author: record<date: string, email: string, name: string>, commiter: record<date: string, email: string, name: string>, message: string, sha: string>, sidebar: string, sub_url: string, title: string>
# operationId: repoCreateWikiPage
export def "repo-create-wiki-page" [
  owner: string
  repo: string
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
  --content-base64: string # content must be base64 encoded
  --message: string # optional commit message summarizing the change
  --title: string # page title. leave empty to keep unchanged
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/repos/{owner}/{repo}/wiki/new"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}]
    body: {content_type: "application/json", kind: json, fields: [{name: content_base64, var: content_base64}, {name: message, var: message}, {name: title, var: title}]}
    accept: ["application/json", "text/html"]
    ok: [201]
    auth: basic
  } {
    owner: $owner, repo: $repo, content_base64: $content_base64, message: $message, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a wiki page
#
# DELETE /repos/{owner}/{repo}/wiki/page/{pageName}
# operationId: repoDeleteWikiPage
export def "repo-delete-wiki-page" [
  owner: string
  repo: string
  page_name: string
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
    path: "/repos/{owner}/{repo}/wiki/page/{pageName}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: pageName, var: page_name}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    owner: $owner, repo: $repo, page_name: $page_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a wiki page
#
# GET /repos/{owner}/{repo}/wiki/page/{pageName}
# Returns: record<commit_count: int, content_base64: string, footer: string, html_url: string, last_commit: record<author: record<date: string, email: string, name: string>, commiter: record<date: string, email: string, name: string>, message: string, sha: string>, sidebar: string, sub_url: string, title: string>
# operationId: repoGetWikiPage
export def "repo-get-wiki-page" [
  owner: string
  repo: string
  page_name: string
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
    path: "/repos/{owner}/{repo}/wiki/page/{pageName}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: pageName, var: page_name}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, page_name: $page_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Edit a wiki page
#
# PATCH /repos/{owner}/{repo}/wiki/page/{pageName}
# Returns: record<commit_count: int, content_base64: string, footer: string, html_url: string, last_commit: record<author: record<date: string, email: string, name: string>, commiter: record<date: string, email: string, name: string>, message: string, sha: string>, sidebar: string, sub_url: string, title: string>
# operationId: repoEditWikiPage
export def "repo-edit-wiki-page" [
  owner: string
  repo: string
  page_name: string
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
  --content-base64: string # content must be base64 encoded
  --message: string # optional commit message summarizing the change
  --title: string # page title. leave empty to keep unchanged
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/repos/{owner}/{repo}/wiki/page/{pageName}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: pageName, var: page_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: content_base64, var: content_base64}, {name: message, var: message}, {name: title, var: title}]}
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, page_name: $page_name, content_base64: $content_base64, message: $message, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get all wiki pages
#
# GET /repos/{owner}/{repo}/wiki/pages
# Returns: table<html_url: string, last_commit: record<author: record, commiter: record, message: string, sha: string>, sub_url: string, title: string>
# operationId: repoGetWikiPages
export def "repo-get-wiki-pages" [
  owner: string
  repo: string
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
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/repos/{owner}/{repo}/wiki/pages"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}]
    query: [{name: page, var: page}, {name: limit, var: limit}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, page: $page, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get revisions of a wiki page
#
# GET /repos/{owner}/{repo}/wiki/revisions/{pageName}
# Returns: record<commits: table<author: record, commiter: record, message: string, sha: string>, count: int>
# operationId: repoGetWikiPageRevisions
export def "repo-get-wiki-page-revisions" [
  owner: string
  repo: string
  page_name: string
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
  --page: int # page number of results to return (1-based)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/repos/{owner}/{repo}/wiki/revisions/{pageName}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}, {name: pageName, var: page_name}]
    query: [{name: page, var: page}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    owner: $owner, repo: $repo, page_name: $page_name, page: $page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a repository using a template
#
# POST /repos/{template_owner}/{template_repo}/generate
# Returns: record<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record<external_tracker_format: string, external_tracker_regexp_pattern: string, external_tracker_style: string, external_tracker_url: string>, external_wiki: record<external_wiki_url: string>, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record<allow_only_contributors_to_track_time: bool, enable_issue_dependencies: bool, enable_time_tracker: bool>, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, parent: any, permissions: record<admin: bool, pull: bool, push: bool>, private: bool, release_counter: int, repo_transfer: record<doer: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, recipient: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, teams: list<record>>, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>
# operationId: generateRepo
export def "generate-repo" [
  template_owner: string
  template_repo: string
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
  --avatar: oneof<nothing, bool> # include avatar of the template repo
  --default-branch: string # Default branch of the new repository
  --description: string # Description of the repository to create
  --git-content: oneof<nothing, bool> # include git content of default branch in template repo
  --git-hooks: oneof<nothing, bool> # include git hooks in template repo
  --labels: oneof<nothing, bool> # include labels in template repo
  name: string # Name of the repository to create
  owner: string # The organization or person who will own the new repository
  --private: oneof<nothing, bool> # Whether the repository is private
  --topics: oneof<nothing, bool> # include topics in template repo
  --webhooks: oneof<nothing, bool> # include webhooks in template repo
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/repos/{template_owner}/{template_repo}/generate"
    path_params: [{name: template_owner, var: template_owner}, {name: template_repo, var: template_repo}]
    body: {content_type: "application/json", kind: json, fields: [{name: avatar, var: avatar}, {name: default_branch, var: default_branch}, {name: description, var: description}, {name: git_content, var: git_content}, {name: git_hooks, var: git_hooks}, {name: labels, var: labels}, {name: name, var: name}, {name: owner, var: owner}, {name: private, var: private}, {name: topics, var: topics}, {name: webhooks, var: webhooks}]}
    accept: ["application/json", "text/html"]
    ok: [201]
    auth: basic
  } {
    template_owner: $template_owner, template_repo: $template_repo, avatar: $avatar, default_branch: $default_branch, description: $description, git_content: $git_content, git_hooks: $git_hooks, labels: $labels, name: $name, owner: $owner, private: $private, topics: $topics, webhooks: $webhooks
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a repository by id
#
# GET /repositories/{id}
# Returns: record<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record<external_tracker_format: string, external_tracker_regexp_pattern: string, external_tracker_style: string, external_tracker_url: string>, external_wiki: record<external_wiki_url: string>, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record<allow_only_contributors_to_track_time: bool, enable_issue_dependencies: bool, enable_time_tracker: bool>, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, parent: any, permissions: record<admin: bool, pull: bool, push: bool>, private: bool, release_counter: int, repo_transfer: record<doer: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, recipient: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, teams: list<record>>, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>
# operationId: repoGetByID
export def "repo-get-by-id" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/repositories/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get instance's global settings for api
#
# GET /settings/api
# Returns: record<default_git_trees_per_page: int, default_max_blob_size: int, default_paging_num: int, max_response_items: int>
# operationId: getGeneralAPISettings
export def "get-general-api-settings" [
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
    path: "/settings/api"
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get instance's global settings for Attachment
#
# GET /settings/attachment
# Returns: record<allowed_types: string, enabled: bool, max_files: int, max_size: int>
# operationId: getGeneralAttachmentSettings
export def "get-general-attachment-settings" [
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
    path: "/settings/attachment"
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get instance's global settings for repositories
#
# GET /settings/repository
# Returns: record<http_git_disabled: bool, lfs_disabled: bool, migrations_disabled: bool, mirrors_disabled: bool, stars_disabled: bool, time_tracking_disabled: bool>
# operationId: getGeneralRepositorySettings
export def "get-general-repository-settings" [
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
    path: "/settings/repository"
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get instance's global settings for ui
#
# GET /settings/ui
# Returns: record<allowed_reactions: list<string>, custom_emojis: list<string>, default_theme: string>
# operationId: getGeneralUISettings
export def "get-general-ui-settings" [
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
    path: "/settings/ui"
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get default signing-key.gpg
#
# GET /signing-key.gpg
# Returns: string
# operationId: getSigningKey
export def "get-signing-key" [
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
    path: "/signing-key.gpg"
    accept: ["text/plain"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a team
#
# DELETE /teams/{id}
# operationId: orgDeleteTeam
export def "org-delete-team" [
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
    path: "/teams/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a team
#
# GET /teams/{id}
# Returns: record<can_create_org_repo: bool, description: string, id: int, includes_all_repositories: bool, name: string, organization: record<avatar_url: string, description: string, full_name: string, id: int, location: string, name: string, repo_admin_change_team_access: bool, username: string, visibility: string, website: string>, permission: string, units: list<string>, units_map: record>
# operationId: orgGetTeam
export def "org-get-team" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/teams/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Edit a team
#
# PATCH /teams/{id}
# Returns: record<can_create_org_repo: bool, description: string, id: int, includes_all_repositories: bool, name: string, organization: record<avatar_url: string, description: string, full_name: string, id: int, location: string, name: string, repo_admin_change_team_access: bool, username: string, visibility: string, website: string>, permission: string, units: list<string>, units_map: record>
# operationId: orgEditTeam
export def "org-edit-team" [
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
  --accept: string@accept-completer # Response content type
  --can-create-org-repo: oneof<nothing, bool>
  --description: string
  --includes-all-repositories: oneof<nothing, bool>
  name: string
  --permission: string@permission-completer
  --units: list<string> # e.g. [repo.code, repo.issues, repo.ext_issues, repo.wiki, repo.pulls, repo.releases, repo.projects, repo.ext_wiki]
  --units-map: record # e.g. {repo.code: read, repo.ext_issues: none, repo.ext_wiki: none, repo.issues: write, repo.projects: none, repo.pulls: owner, repo.releases: none, repo.wiki: admin}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/teams/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: can_create_org_repo, var: can_create_org_repo}, {name: description, var: description}, {name: includes_all_repositories, var: includes_all_repositories}, {name: name, var: name}, {name: permission, var: permission}, {name: units, var: units}, {name: units_map, var: units_map}]}
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    id: $id, can_create_org_repo: $can_create_org_repo, description: $description, includes_all_repositories: $includes_all_repositories, name: $name, permission: $permission, units: $units, units_map: $units_map
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List a team's members
#
# GET /teams/{id}/members
# Returns: table<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>
# operationId: orgListTeamMembers
export def "org-list-team-members" [
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
  --accept: string@accept-completer # Response content type
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/teams/{id}/members"
    path_params: [{name: id, var: id}]
    query: [{name: page, var: page}, {name: limit, var: limit}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    id: $id, page: $page, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Remove a team member
#
# DELETE /teams/{id}/members/{username}
# operationId: orgRemoveTeamMember
export def "org-remove-team-member" [
  id: int
  username: string
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
    path: "/teams/{id}/members/{username}"
    path_params: [{name: id, var: id}, {name: username, var: username}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    id: $id, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List a particular member of team
#
# GET /teams/{id}/members/{username}
# Returns: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>
# operationId: orgListTeamMember
export def "org-list-team-member" [
  id: int
  username: string
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
    path: "/teams/{id}/members/{username}"
    path_params: [{name: id, var: id}, {name: username, var: username}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    id: $id, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add a team member
#
# PUT /teams/{id}/members/{username}
# operationId: orgAddTeamMember
export def "org-add-team-member" [
  id: int
  username: string
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
    path: "/teams/{id}/members/{username}"
    path_params: [{name: id, var: id}, {name: username, var: username}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    id: $id, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List a team's repos
#
# GET /teams/{id}/repos
# Returns: table<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record<external_tracker_format: string, external_tracker_regexp_pattern: string, external_tracker_style: string, external_tracker_url: string>, external_wiki: record<external_wiki_url: string>, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record<allow_only_contributors_to_track_time: bool, enable_issue_dependencies: bool, enable_time_tracker: bool>, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, parent: any, permissions: record<admin: bool, pull: bool, push: bool>, private: bool, release_counter: int, repo_transfer: record<doer: record, recipient: record, teams: list>, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>
# operationId: orgListTeamRepos
export def "org-list-team-repos" [
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
  --accept: string@accept-completer # Response content type
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/teams/{id}/repos"
    path_params: [{name: id, var: id}]
    query: [{name: page, var: page}, {name: limit, var: limit}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    id: $id, page: $page, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Remove a repository from a team
#
# DELETE /teams/{id}/repos/{org}/{repo}
# operationId: orgRemoveTeamRepository
export def "org-remove-team-repository" [
  id: int
  org: string
  repo: string
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
    path: "/teams/{id}/repos/{org}/{repo}"
    path_params: [{name: id, var: id}, {name: org, var: org}, {name: repo, var: repo}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    id: $id, org: $org, repo: $repo
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List a particular repo of team
#
# GET /teams/{id}/repos/{org}/{repo}
# Returns: record<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record<external_tracker_format: string, external_tracker_regexp_pattern: string, external_tracker_style: string, external_tracker_url: string>, external_wiki: record<external_wiki_url: string>, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record<allow_only_contributors_to_track_time: bool, enable_issue_dependencies: bool, enable_time_tracker: bool>, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, parent: any, permissions: record<admin: bool, pull: bool, push: bool>, private: bool, release_counter: int, repo_transfer: record<doer: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, recipient: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, teams: list<record>>, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>
# operationId: orgListTeamRepo
export def "org-list-team-repo" [
  id: int
  org: string
  repo: string
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
    path: "/teams/{id}/repos/{org}/{repo}"
    path_params: [{name: id, var: id}, {name: org, var: org}, {name: repo, var: repo}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    id: $id, org: $org, repo: $repo
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add a repository to a team
#
# PUT /teams/{id}/repos/{org}/{repo}
# operationId: orgAddTeamRepository
export def "org-add-team-repository" [
  id: int
  org: string
  repo: string
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
    path: "/teams/{id}/repos/{org}/{repo}"
    path_params: [{name: id, var: id}, {name: org, var: org}, {name: repo, var: repo}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    id: $id, org: $org, repo: $repo
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# search topics via keyword
#
# GET /topics/search
# Returns: table<created: string, id: int, repo_count: int, topic_name: string, updated: string>
# operationId: topicSearch
export def "topic-search" [
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
  --q: string # keywords to search (required)
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/topics/search"
    query: [{name: q, var: q, required: true}, {name: page, var: page}, {name: limit, var: limit}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    q: $q, page: $page, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get the authenticated user
#
# GET /user
# Returns: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>
# operationId: userGetCurrent
export def "user-get-current" [
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
    path: "/user"
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List the authenticated user's oauth2 applications
#
# GET /user/applications/oauth2
# Returns: table<client_id: string, client_secret: string, confidential_client: bool, created: string, id: int, name: string, redirect_uris: list<string>>
# operationId: userGetOauth2Application
export def "user-get-oauth2-application" [
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
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/user/applications/oauth2"
    query: [{name: page, var: page}, {name: limit, var: limit}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    page: $page, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# creates a new OAuth2 application
#
# POST /user/applications/oauth2
# Returns: record<client_id: string, client_secret: string, confidential_client: bool, created: string, id: int, name: string, redirect_uris: list<string>>
# operationId: userCreateOAuth2Application
export def "user-create-o-auth2-application" [
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
  --confidential-client: oneof<nothing, bool>
  --name: string
  --redirect-uris: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/user/applications/oauth2"
    body: {content_type: "application/json", kind: json, fields: [{name: confidential_client, var: confidential_client}, {name: name, var: name}, {name: redirect_uris, var: redirect_uris}]}
    accept: ["application/json", "text/html"]
    ok: [201]
    auth: basic
  } {
    confidential_client: $confidential_client, name: $name, redirect_uris: $redirect_uris
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# delete an OAuth2 Application
#
# DELETE /user/applications/oauth2/{id}
# operationId: userDeleteOAuth2Application
export def "user-delete-o-auth2-application" [
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
    path: "/user/applications/oauth2/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# get an OAuth2 Application
#
# GET /user/applications/oauth2/{id}
# Returns: record<client_id: string, client_secret: string, confidential_client: bool, created: string, id: int, name: string, redirect_uris: list<string>>
# operationId: userGetOAuth2Application
export def "user-get-o-auth2-application" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/user/applications/oauth2/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# update an OAuth2 Application, this includes regenerating the client secret
#
# PATCH /user/applications/oauth2/{id}
# Returns: record<client_id: string, client_secret: string, confidential_client: bool, created: string, id: int, name: string, redirect_uris: list<string>>
# operationId: userUpdateOAuth2Application
export def "user-update-o-auth2-application" [
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
  --accept: string@accept-completer # Response content type
  --confidential-client: oneof<nothing, bool>
  --name: string
  --redirect-uris: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/user/applications/oauth2/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: confidential_client, var: confidential_client}, {name: name, var: name}, {name: redirect_uris, var: redirect_uris}]}
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    id: $id, confidential_client: $confidential_client, name: $name, redirect_uris: $redirect_uris
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete email addresses
#
# DELETE /user/emails
# operationId: userDeleteEmail
export def "user-delete-email" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --emails: list<string> # email addresses to delete
]: any -> any {
  $in | http-request {
    method: delete
    path: "/user/emails"
    body: {content_type: "application/json", kind: json, fields: [{name: emails, var: emails}]}
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    emails: $emails
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the authenticated user's email addresses
#
# GET /user/emails
# Returns: table<email: string, primary: bool, verified: bool>
# operationId: userListEmails
export def "user-list-emails" [
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
    path: "/user/emails"
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add email addresses
#
# POST /user/emails
# Returns: table<email: string, primary: bool, verified: bool>
# operationId: userAddEmail
export def "user-add-email" [
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
  --emails: list<string> # email addresses to add
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/user/emails"
    body: {content_type: "application/json", kind: json, fields: [{name: emails, var: emails}]}
    accept: ["application/json", "text/html"]
    ok: [201]
    auth: basic
  } {
    emails: $emails
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List the authenticated user's followers
#
# GET /user/followers
# Returns: table<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>
# operationId: userCurrentListFollowers
export def "user-current-list-followers" [
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
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/user/followers"
    query: [{name: page, var: page}, {name: limit, var: limit}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    page: $page, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List the users that the authenticated user is following
#
# GET /user/following
# Returns: table<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>
# operationId: userCurrentListFollowing
export def "user-current-list-following" [
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
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/user/following"
    query: [{name: page, var: page}, {name: limit, var: limit}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    page: $page, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Unfollow a user
#
# DELETE /user/following/{username}
# operationId: userCurrentDeleteFollow
export def "user-current-delete-follow" [
  username: string
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
    path: "/user/following/{username}"
    path_params: [{name: username, var: username}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check whether a user is followed by the authenticated user
#
# GET /user/following/{username}
# operationId: userCurrentCheckFollowing
export def "user-current-check-following" [
  username: string
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
    path: "/user/following/{username}"
    path_params: [{name: username, var: username}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Follow a user
#
# PUT /user/following/{username}
# operationId: userCurrentPutFollow
export def "user-current-put-follow" [
  username: string
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
    path: "/user/following/{username}"
    path_params: [{name: username, var: username}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a Token to verify
#
# GET /user/gpg_key_token
# Returns: string
# operationId: getVerificationToken
export def "get-verification-token" [
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
    path: "/user/gpg_key_token"
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Verify a GPG key
#
# POST /user/gpg_key_verify
# Returns: record<can_certify: bool, can_encrypt_comms: bool, can_encrypt_storage: bool, can_sign: bool, created_at: string, emails: table<email: string, verified: bool>, expires_at: string, id: int, key_id: string, primary_key_id: string, public_key: string, subkeys: list<any>, verified: bool>
# operationId: userVerifyGPGKey
export def "user-verify-gpg-key" [
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
    path: "/user/gpg_key_verify"
    accept: ["application/json", "text/html"]
    ok: [201]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List the authenticated user's GPG keys
#
# GET /user/gpg_keys
# Returns: table<can_certify: bool, can_encrypt_comms: bool, can_encrypt_storage: bool, can_sign: bool, created_at: string, emails: list<record>, expires_at: string, id: int, key_id: string, primary_key_id: string, public_key: string, subkeys: list<any>, verified: bool>
# operationId: userCurrentListGPGKeys
export def "user-current-list-gpg-keys" [
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
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/user/gpg_keys"
    query: [{name: page, var: page}, {name: limit, var: limit}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    page: $page, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a GPG key
#
# POST /user/gpg_keys
# Returns: record<can_certify: bool, can_encrypt_comms: bool, can_encrypt_storage: bool, can_sign: bool, created_at: string, emails: table<email: string, verified: bool>, expires_at: string, id: int, key_id: string, primary_key_id: string, public_key: string, subkeys: list<any>, verified: bool>
# operationId: userCurrentPostGPGKey
export def "user-current-post-gpg-key" [
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
  armored_public_key: string # An armored GPG key to add
  --armored-signature: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/user/gpg_keys"
    body: {content_type: "application/json", kind: json, fields: [{name: armored_public_key, var: armored_public_key}, {name: armored_signature, var: armored_signature}]}
    accept: ["application/json", "text/html"]
    ok: [201]
    auth: basic
  } {
    armored_public_key: $armored_public_key, armored_signature: $armored_signature
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Remove a GPG key
#
# DELETE /user/gpg_keys/{id}
# operationId: userCurrentDeleteGPGKey
export def "user-current-delete-gpg-key" [
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
    path: "/user/gpg_keys/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a GPG key
#
# GET /user/gpg_keys/{id}
# Returns: record<can_certify: bool, can_encrypt_comms: bool, can_encrypt_storage: bool, can_sign: bool, created_at: string, emails: table<email: string, verified: bool>, expires_at: string, id: int, key_id: string, primary_key_id: string, public_key: string, subkeys: list<any>, verified: bool>
# operationId: userCurrentGetGPGKey
export def "user-current-get-gpg-key" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/user/gpg_keys/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List the authenticated user's public keys
#
# GET /user/keys
# Returns: table<created_at: string, fingerprint: string, id: int, key: string, key_type: string, read_only: bool, title: string, url: string, user: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>>
# operationId: userCurrentListKeys
export def "user-current-list-keys" [
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
  --fingerprint: string # fingerprint of the key
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/user/keys"
    query: [{name: fingerprint, var: fingerprint}, {name: page, var: page}, {name: limit, var: limit}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    fingerprint: $fingerprint, page: $page, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a public key
#
# POST /user/keys
# Returns: record<created_at: string, fingerprint: string, id: int, key: string, key_type: string, read_only: bool, title: string, url: string, user: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>>
# operationId: userCurrentPostKey
export def "user-current-post-key" [
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
  key: string # An armored SSH key to add
  --read-only: oneof<nothing, bool> # Describe if the key has only read access or read/write
  title: string # Title of the key to add
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/user/keys"
    body: {content_type: "application/json", kind: json, fields: [{name: key, var: key}, {name: read_only, var: read_only}, {name: title, var: title}]}
    accept: ["application/json", "text/html"]
    ok: [201]
    auth: basic
  } {
    key: $key, read_only: $read_only, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a public key
#
# DELETE /user/keys/{id}
# operationId: userCurrentDeleteKey
export def "user-current-delete-key" [
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
    path: "/user/keys/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a public key
#
# GET /user/keys/{id}
# Returns: record<created_at: string, fingerprint: string, id: int, key: string, key_type: string, read_only: bool, title: string, url: string, user: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>>
# operationId: userCurrentGetKey
export def "user-current-get-key" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/user/keys/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List the current user's organizations
#
# GET /user/orgs
# Returns: table<avatar_url: string, description: string, full_name: string, id: int, location: string, name: string, repo_admin_change_team_access: bool, username: string, visibility: string, website: string>
# operationId: orgListCurrentUserOrgs
export def "org-list-current-user-orgs" [
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
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/user/orgs"
    query: [{name: page, var: page}, {name: limit, var: limit}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    page: $page, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List the repos that the authenticated user owns
#
# GET /user/repos
# Returns: table<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record<external_tracker_format: string, external_tracker_regexp_pattern: string, external_tracker_style: string, external_tracker_url: string>, external_wiki: record<external_wiki_url: string>, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record<allow_only_contributors_to_track_time: bool, enable_issue_dependencies: bool, enable_time_tracker: bool>, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, parent: any, permissions: record<admin: bool, pull: bool, push: bool>, private: bool, release_counter: int, repo_transfer: record<doer: record, recipient: record, teams: list>, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>
# operationId: userCurrentListRepos
export def "user-current-list-repos" [
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
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/user/repos"
    query: [{name: page, var: page}, {name: limit, var: limit}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    page: $page, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a repository
#
# POST /user/repos
# Returns: record<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record<external_tracker_format: string, external_tracker_regexp_pattern: string, external_tracker_style: string, external_tracker_url: string>, external_wiki: record<external_wiki_url: string>, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record<allow_only_contributors_to_track_time: bool, enable_issue_dependencies: bool, enable_time_tracker: bool>, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, parent: any, permissions: record<admin: bool, pull: bool, push: bool>, private: bool, release_counter: int, repo_transfer: record<doer: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, recipient: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, teams: list<record>>, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>
# operationId: createCurrentUserRepo
export def "create-current-user-repo" [
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
  --auto-init: oneof<nothing, bool> # Whether the repository should be auto-initialized?
  --default-branch: string # DefaultBranch of the repository (used when initializes and in template)
  --description: string # Description of the repository to create
  --gitignores: string # Gitignores to use
  --issue-labels: string # Label-Set to use
  --license: string # License to use
  name: string # Name of the repository to create
  --private: oneof<nothing, bool> # Whether the repository is private
  --readme: string # Readme of the repository to create
  --template: oneof<nothing, bool> # Whether the repository is template
  --trust-model: string@trust-model-completer # TrustModel of the repository
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/user/repos"
    body: {content_type: "application/json", kind: json, fields: [{name: auto_init, var: auto_init}, {name: default_branch, var: default_branch}, {name: description, var: description}, {name: gitignores, var: gitignores}, {name: issue_labels, var: issue_labels}, {name: license, var: license}, {name: name, var: name}, {name: private, var: private}, {name: readme, var: readme}, {name: template, var: template}, {name: trust_model, var: trust_model}]}
    accept: ["application/json", "text/html"]
    ok: [201]
    auth: basic
  } {
    auto_init: $auto_init, default_branch: $default_branch, description: $description, gitignores: $gitignores, issue_labels: $issue_labels, license: $license, name: $name, private: $private, readme: $readme, template: $template, trust_model: $trust_model
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get user settings
#
# GET /user/settings
# Returns: table<description: string, diff_view_style: string, full_name: string, hide_activity: bool, hide_email: bool, language: string, location: string, theme: string, website: string>
# operationId: getUserSettings
export def "get-user-settings" [
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
    path: "/user/settings"
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update user settings
#
# PATCH /user/settings
# Returns: table<description: string, diff_view_style: string, full_name: string, hide_activity: bool, hide_email: bool, language: string, location: string, theme: string, website: string>
# operationId: updateUserSettings
export def "update-user-settings" [
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
  --description: string
  --diff-view-style: string
  --full-name: string
  --hide-activity: oneof<nothing, bool>
  --hide-email: oneof<nothing, bool> # Privacy
  --language: string
  --location: string
  --theme: string
  --website: string
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/user/settings"
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: diff_view_style, var: diff_view_style}, {name: full_name, var: full_name}, {name: hide_activity, var: hide_activity}, {name: hide_email, var: hide_email}, {name: language, var: language}, {name: location, var: location}, {name: theme, var: theme}, {name: website, var: website}]}
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    description: $description, diff_view_style: $diff_view_style, full_name: $full_name, hide_activity: $hide_activity, hide_email: $hide_email, language: $language, location: $location, theme: $theme, website: $website
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The repos that the authenticated user has starred
#
# GET /user/starred
# Returns: table<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record<external_tracker_format: string, external_tracker_regexp_pattern: string, external_tracker_style: string, external_tracker_url: string>, external_wiki: record<external_wiki_url: string>, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record<allow_only_contributors_to_track_time: bool, enable_issue_dependencies: bool, enable_time_tracker: bool>, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, parent: any, permissions: record<admin: bool, pull: bool, push: bool>, private: bool, release_counter: int, repo_transfer: record<doer: record, recipient: record, teams: list>, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>
# operationId: userCurrentListStarred
export def "user-current-list-starred" [
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
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/user/starred"
    query: [{name: page, var: page}, {name: limit, var: limit}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    page: $page, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Unstar the given repo
#
# DELETE /user/starred/{owner}/{repo}
# operationId: userCurrentDeleteStar
export def "user-current-delete-star" [
  owner: string
  repo: string
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
    path: "/user/starred/{owner}/{repo}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    owner: $owner, repo: $repo
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Whether the authenticated is starring the repo
#
# GET /user/starred/{owner}/{repo}
# operationId: userCurrentCheckStarring
export def "user-current-check-starring" [
  owner: string
  repo: string
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
    path: "/user/starred/{owner}/{repo}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    owner: $owner, repo: $repo
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Star the given repo
#
# PUT /user/starred/{owner}/{repo}
# operationId: userCurrentPutStar
export def "user-current-put-star" [
  owner: string
  repo: string
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
    path: "/user/starred/{owner}/{repo}"
    path_params: [{name: owner, var: owner}, {name: repo, var: repo}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    owner: $owner, repo: $repo
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of all existing stopwatches
#
# GET /user/stopwatches
# Returns: table<created: string, duration: string, issue_index: int, issue_title: string, repo_name: string, repo_owner_name: string, seconds: int>
# operationId: userGetStopWatches
export def "user-get-stop-watches" [
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
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/user/stopwatches"
    query: [{name: page, var: page}, {name: limit, var: limit}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    page: $page, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List repositories watched by the authenticated user
#
# GET /user/subscriptions
# Returns: table<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record<external_tracker_format: string, external_tracker_regexp_pattern: string, external_tracker_style: string, external_tracker_url: string>, external_wiki: record<external_wiki_url: string>, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record<allow_only_contributors_to_track_time: bool, enable_issue_dependencies: bool, enable_time_tracker: bool>, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, parent: any, permissions: record<admin: bool, pull: bool, push: bool>, private: bool, release_counter: int, repo_transfer: record<doer: record, recipient: record, teams: list>, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>
# operationId: userCurrentListSubscriptions
export def "user-current-list-subscriptions" [
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
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/user/subscriptions"
    query: [{name: page, var: page}, {name: limit, var: limit}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    page: $page, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List all the teams a user belongs to
#
# GET /user/teams
# Returns: table<can_create_org_repo: bool, description: string, id: int, includes_all_repositories: bool, name: string, organization: record<avatar_url: string, description: string, full_name: string, id: int, location: string, name: string, repo_admin_change_team_access: bool, username: string, visibility: string, website: string>, permission: string, units: list<string>, units_map: record>
# operationId: userListTeams
export def "user-list-teams" [
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
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/user/teams"
    query: [{name: page, var: page}, {name: limit, var: limit}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    page: $page, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List the current user's tracked times
#
# GET /user/times
# Returns: table<created: string, id: int, issue: record<assets: list, assignee: record, assignees: list, body: string, closed_at: string, comments: int, created_at: string, due_date: string, html_url: string, id: int, is_locked: bool, labels: list, milestone: record, number: int, original_author: string, original_author_id: int, pull_request: record, ref: string, repository: record, state: string, title: string, updated_at: string, url: string, user: record>, issue_id: int, time: int, user_id: int, user_name: string>
# operationId: userCurrentTrackedTimes
export def "user-current-tracked-times" [
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
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
  --since: string # Only show times updated after the given time. This is a timestamp in RFC 3339 format (format: date-time)
  --before: string # Only show times updated before the given time. This is a timestamp in RFC 3339 format (format: date-time)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/user/times"
    query: [{name: page, var: page}, {name: limit, var: limit}, {name: since, var: since}, {name: before, var: before}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    page: $page, limit: $limit, since: $since, before: $before
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Search for users
#
# GET /users/search
# Returns: record<data: table<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, ok: bool>
# operationId: userSearch
export def "user-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # keyword
  --uid: int # ID of the user to search for (format: int64)
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/search"
    query: [{name: q, var: q}, {name: uid, var: uid}, {name: page, var: page}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    q: $q, uid: $uid, page: $page, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a user
#
# GET /users/{username}
# Returns: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>
# operationId: userGet
export def "user-get" [
  username: string
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
    path: "/users/{username}"
    path_params: [{name: username, var: username}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List the given user's followers
#
# GET /users/{username}/followers
# Returns: table<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>
# operationId: userListFollowers
export def "user-list-followers" [
  username: string
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
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users/{username}/followers"
    path_params: [{name: username, var: username}]
    query: [{name: page, var: page}, {name: limit, var: limit}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    username: $username, page: $page, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List the users that the given user is following
#
# GET /users/{username}/following
# Returns: table<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>
# operationId: userListFollowing
export def "user-list-following" [
  username: string
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
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users/{username}/following"
    path_params: [{name: username, var: username}]
    query: [{name: page, var: page}, {name: limit, var: limit}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    username: $username, page: $page, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Check if one user is following another user
#
# GET /users/{username}/following/{target}
# operationId: userCheckFollowing
export def "user-check-following" [
  username: string
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
]: nothing -> any {
  http-request {
    method: get
    path: "/users/{username}/following/{target}"
    path_params: [{name: username, var: username}, {name: target, var: target}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    username: $username, target: $target
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the given user's GPG keys
#
# GET /users/{username}/gpg_keys
# Returns: table<can_certify: bool, can_encrypt_comms: bool, can_encrypt_storage: bool, can_sign: bool, created_at: string, emails: list<record>, expires_at: string, id: int, key_id: string, primary_key_id: string, public_key: string, subkeys: list<any>, verified: bool>
# operationId: userListGPGKeys
export def "user-list-gpg-keys" [
  username: string
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
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users/{username}/gpg_keys"
    path_params: [{name: username, var: username}]
    query: [{name: page, var: page}, {name: limit, var: limit}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    username: $username, page: $page, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a user's heatmap
#
# GET /users/{username}/heatmap
# Returns: table<contributions: int, timestamp: int>
# operationId: userGetHeatmapData
export def "user-get-heatmap-data" [
  username: string
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
    path: "/users/{username}/heatmap"
    path_params: [{name: username, var: username}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List the given user's public keys
#
# GET /users/{username}/keys
# Returns: table<created_at: string, fingerprint: string, id: int, key: string, key_type: string, read_only: bool, title: string, url: string, user: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>>
# operationId: userListKeys
export def "user-list-keys" [
  username: string
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
  --fingerprint: string # fingerprint of the key
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users/{username}/keys"
    path_params: [{name: username, var: username}]
    query: [{name: fingerprint, var: fingerprint}, {name: page, var: page}, {name: limit, var: limit}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    username: $username, fingerprint: $fingerprint, page: $page, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List a user's organizations
#
# GET /users/{username}/orgs
# Returns: table<avatar_url: string, description: string, full_name: string, id: int, location: string, name: string, repo_admin_change_team_access: bool, username: string, visibility: string, website: string>
# operationId: orgListUserOrgs
export def "org-list-user-orgs" [
  username: string
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
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users/{username}/orgs"
    path_params: [{name: username, var: username}]
    query: [{name: page, var: page}, {name: limit, var: limit}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    username: $username, page: $page, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get user permissions in organization
#
# GET /users/{username}/orgs/{org}/permissions
# Returns: record<can_create_repository: bool, can_read: bool, can_write: bool, is_admin: bool, is_owner: bool>
# operationId: orgGetUserPermissions
export def "org-get-user-permissions" [
  username: string
  org: string
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
    path: "/users/{username}/orgs/{org}/permissions"
    path_params: [{name: username, var: username}, {name: org, var: org}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    username: $username, org: $org
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List the repos owned by the given user
#
# GET /users/{username}/repos
# Returns: table<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record<external_tracker_format: string, external_tracker_regexp_pattern: string, external_tracker_style: string, external_tracker_url: string>, external_wiki: record<external_wiki_url: string>, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record<allow_only_contributors_to_track_time: bool, enable_issue_dependencies: bool, enable_time_tracker: bool>, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, parent: any, permissions: record<admin: bool, pull: bool, push: bool>, private: bool, release_counter: int, repo_transfer: record<doer: record, recipient: record, teams: list>, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>
# operationId: userListRepos
export def "user-list-repos" [
  username: string
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
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users/{username}/repos"
    path_params: [{name: username, var: username}]
    query: [{name: page, var: page}, {name: limit, var: limit}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    username: $username, page: $page, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The repos that the given user has starred
#
# GET /users/{username}/starred
# Returns: table<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record<external_tracker_format: string, external_tracker_regexp_pattern: string, external_tracker_style: string, external_tracker_url: string>, external_wiki: record<external_wiki_url: string>, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record<allow_only_contributors_to_track_time: bool, enable_issue_dependencies: bool, enable_time_tracker: bool>, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, parent: any, permissions: record<admin: bool, pull: bool, push: bool>, private: bool, release_counter: int, repo_transfer: record<doer: record, recipient: record, teams: list>, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>
# operationId: userListStarred
export def "user-list-starred" [
  username: string
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
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users/{username}/starred"
    path_params: [{name: username, var: username}]
    query: [{name: page, var: page}, {name: limit, var: limit}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    username: $username, page: $page, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List the repositories watched by a user
#
# GET /users/{username}/subscriptions
# Returns: table<allow_merge_commits: bool, allow_rebase: bool, allow_rebase_explicit: bool, allow_rebase_update: bool, allow_squash_merge: bool, archived: bool, avatar_url: string, clone_url: string, created_at: string, default_allow_maintainer_edit: bool, default_branch: string, default_delete_branch_after_merge: bool, default_merge_style: string, description: string, empty: bool, external_tracker: record<external_tracker_format: string, external_tracker_regexp_pattern: string, external_tracker_style: string, external_tracker_url: string>, external_wiki: record<external_wiki_url: string>, fork: bool, forks_count: int, full_name: string, has_issues: bool, has_projects: bool, has_pull_requests: bool, has_wiki: bool, html_url: string, id: int, ignore_whitespace_conflicts: bool, internal: bool, internal_tracker: record<allow_only_contributors_to_track_time: bool, enable_issue_dependencies: bool, enable_time_tracker: bool>, language: string, languages_url: string, link: string, mirror: bool, mirror_interval: string, mirror_updated: string, name: string, open_issues_count: int, open_pr_counter: int, original_url: string, owner: record<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, parent: any, permissions: record<admin: bool, pull: bool, push: bool>, private: bool, release_counter: int, repo_transfer: record<doer: record, recipient: record, teams: list>, size: int, ssh_url: string, stars_count: int, template: bool, updated_at: string, watchers_count: int, website: string>
# operationId: userListSubscriptions
export def "user-list-subscriptions" [
  username: string
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
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users/{username}/subscriptions"
    path_params: [{name: username, var: username}]
    query: [{name: page, var: page}, {name: limit, var: limit}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    username: $username, page: $page, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List the authenticated user's access tokens
#
# GET /users/{username}/tokens
# Returns: table<id: int, name: string, scopes: list<string>, sha1: string, token_last_eight: string>
# operationId: userGetTokens
export def "user-get-tokens" [
  username: string
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
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users/{username}/tokens"
    path_params: [{name: username, var: username}]
    query: [{name: page, var: page}, {name: limit, var: limit}]
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    username: $username, page: $page, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create an access token
#
# POST /users/{username}/tokens
# Returns: record<id: int, name: string, scopes: list<string>, sha1: string, token_last_eight: string>
# operationId: userCreateToken
export def "user-create-token" [
  username: string
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
  name: string
  --scopes: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users/{username}/tokens"
    path_params: [{name: username, var: username}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: scopes, var: scopes}]}
    accept: ["application/json", "text/html"]
    ok: [201]
    auth: basic
  } {
    username: $username, name: $name, scopes: $scopes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# delete an access token
#
# DELETE /users/{username}/tokens/{token}
# operationId: userDeleteAccessToken
export def "user-delete-access-token" [
  username: string
  token_arg: string
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
    path: "/users/{username}/tokens/{token}"
    path_params: [{name: username, var: username}, {name: token, var: token_arg}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    username: $username, token_arg: $token_arg
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the version of the Gitea application
#
# GET /version
# Returns: record<version: string>
# operationId: getVersion
export def "get-version" [
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
    path: "/version"
    accept: ["application/json", "text/html"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}
