# Auto-generated client for Issue Tracking API v9.3.0
# Source: https://api.apis.guru/v2/specs/apideck.com/issue-tracking/9.3.0/openapi.json
# Auth: --token flag or $env.ISSUE_TRACKING_API_TOKEN

const CLIENT = {
  base_url: "https://unify.apideck.com"
  token_env_var: "ISSUE_TRACKING_API_TOKEN"
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

def base-url-completer [] { ["https://unify.apideck.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def priority-completer [] { ["high" "low" "normal" "urgent"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    collections-all: "record<data: table<created_at: string, description: string, id: string, name: string, parent_id: string, type: string, updated_at: string>, links: record<current: string, next: string, previous: string>, meta: record<cursors: record<current: string, next: string, previous: string>, items_on_page: int>, operation: string, resource: string, service: string, status: string, status_code: int>"
    collections-one: "record<data: record<created_at: string, description: string, id: string, name: string, parent_id: string, type: string, updated_at: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    collection-tags-all: "record<data: table<id: string, name: string>, links: record<current: string, next: string, previous: string>, meta: record<cursors: record<current: string, next: string, previous: string>, items_on_page: int>, operation: string, resource: string, service: string, status: string, status_code: int>"
    collection-tickets-all: "record<data: table<assignees: list, collection_id: string, completed_at: string, created_at: string, created_by: string, description: string, due_date: string, id: string, parent_id: string, priority: string, status: string, subject: string, tags: list, type: string, updated_at: string>, links: record<current: string, next: string, previous: string>, meta: record<cursors: record<current: string, next: string, previous: string>, items_on_page: int>, operation: string, resource: string, service: string, status: string, status_code: int>"
    collection-tickets-add: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    collection-tickets-delete: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    collection-tickets-one: "record<data: record<assignees: list<record>, collection_id: string, completed_at: string, created_at: string, created_by: string, description: string, due_date: string, id: string, parent_id: string, priority: string, status: string, subject: string, tags: list<record>, type: string, updated_at: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    collection-tickets-update: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    collection-ticket-comments-all: "record<data: table<body: string, created_at: string, created_by: string, id: string, updated_at: string>, links: record<current: string, next: string, previous: string>, meta: record<cursors: record<current: string, next: string, previous: string>, items_on_page: int>, operation: string, resource: string, service: string, status: string, status_code: int>"
    collection-ticket-comments-add: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    collection-ticket-comments-delete: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    collection-ticket-comments-one: "record<data: record<body: string, created_at: string, created_by: string, id: string, updated_at: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    collection-ticket-comments-update: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    collection-users-all: "record<data: table<created_at: string, email: string, first_name: string, id: string, last_name: string, name: string, photo_url: string, updated_at: string>, links: record<current: string, next: string, previous: string>, meta: record<cursors: record<current: string, next: string, previous: string>, items_on_page: int>, operation: string, resource: string, service: string, status: string, status_code: int>"
    collection-users-one: "record<data: record<created_at: string, email: string, first_name: string, id: string, last_name: string, name: string, photo_url: string, updated_at: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["collections-all" "collections-one" "collection-tags-all" "collection-tickets-all" "collection-tickets-add" "collection-tickets-delete" "collection-tickets-one" "collection-tickets-update" "collection-ticket-comments-all" "collection-ticket-comments-add" "collection-ticket-comments-delete" "collection-ticket-comments-one" "collection-ticket-comments-update" "collection-users-all" "collection-users-one" "commands"] | sort) } | get name | first)
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

# List Collections
#
# GET /issue-tracking/collections
# Returns: record<data: table<created_at: string, description: string, id: string, name: string, parent_id: string, type: string, updated_at: string>, links: record<current: string, next: string, previous: string>, meta: record<cursors: record<current: string, next: string, previous: string>, items_on_page: int>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: collectionsAll
export def "collections-all" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --cursor: string # Cursor to start from. You can find cursors for next/previous pages in the meta.cursors property of the response. (nullable)
  --limit: int # Number of results to return. Minimum 1, Maximum 200, Default 20 (default: 20)
  --sort: record # Apply sorting (e.g. {by: name, direction: desc})
  --fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. Example: `fields=name,email,addresses.city`In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/issue-tracking/collections"
    query: [{name: raw, var: qp_raw}, {name: cursor, var: cursor}, {name: limit, var: limit}, {name: sort, var: sort, style: deepObject}, {name: fields, var: fields}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_raw: $qp_raw, cursor: $cursor, limit: $limit, sort: $sort, fields: $fields, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Collection
#
# GET /issue-tracking/collections/{collection_id}
# Returns: record<data: record<created_at: string, description: string, id: string, name: string, parent_id: string, type: string, updated_at: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: collectionsOne
export def "collections-one" [
  collection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. Example: `fields=name,email,addresses.city`In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/issue-tracking/collections/{collection_id}"
    path_params: [{name: collection_id, var: collection_id}]
    query: [{name: raw, var: qp_raw}, {name: fields, var: fields}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    collection_id: $collection_id, qp_raw: $qp_raw, fields: $fields, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Tags
#
# GET /issue-tracking/collections/{collection_id}/tags
# Returns: record<data: table<id: string, name: string>, links: record<current: string, next: string, previous: string>, meta: record<cursors: record<current: string, next: string, previous: string>, items_on_page: int>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: collectionTagsAll
export def "collection-tags-all" [
  collection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --cursor: string # Cursor to start from. You can find cursors for next/previous pages in the meta.cursors property of the response. (nullable)
  --limit: int # Number of results to return. Minimum 1, Maximum 200, Default 20 (default: 20)
  --fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. Example: `fields=name,email,addresses.city`In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/issue-tracking/collections/{collection_id}/tags"
    path_params: [{name: collection_id, var: collection_id}]
    query: [{name: raw, var: qp_raw}, {name: cursor, var: cursor}, {name: limit, var: limit}, {name: fields, var: fields}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    collection_id: $collection_id, qp_raw: $qp_raw, cursor: $cursor, limit: $limit, fields: $fields, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Tickets
#
# GET /issue-tracking/collections/{collection_id}/tickets
# Returns: record<data: table<assignees: list, collection_id: string, completed_at: string, created_at: string, created_by: string, description: string, due_date: string, id: string, parent_id: string, priority: string, status: string, subject: string, tags: list, type: string, updated_at: string>, links: record<current: string, next: string, previous: string>, meta: record<cursors: record<current: string, next: string, previous: string>, items_on_page: int>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: collectionTicketsAll
export def "collection-tickets-all" [
  collection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --cursor: string # Cursor to start from. You can find cursors for next/previous pages in the meta.cursors property of the response. (nullable)
  --limit: int # Number of results to return. Minimum 1, Maximum 200, Default 20 (default: 20)
  --sort: record # Apply sorting (e.g. {by: created_at, direction: desc})
  --filter: record # Apply filters (e.g. {status: [open]})
  --fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. Example: `fields=name,email,addresses.city`In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/issue-tracking/collections/{collection_id}/tickets"
    path_params: [{name: collection_id, var: collection_id}]
    query: [{name: raw, var: qp_raw}, {name: cursor, var: cursor}, {name: limit, var: limit}, {name: sort, var: sort, style: deepObject}, {name: filter, var: filter, style: deepObject}, {name: fields, var: fields}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    collection_id: $collection_id, qp_raw: $qp_raw, cursor: $cursor, limit: $limit, sort: $sort, filter: $filter, fields: $fields, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Ticket
#
# POST /issue-tracking/collections/{collection_id}/tickets
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: collectionTicketsAdd
export def "collection-tickets-add" [
  collection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
  --assignees: list # item shape: {id: string}
  --description: string # The ticket's description. HTML version of description is mapped if supported by the third-party platform (e.g. I am facing issues with my internet connection)
  --due-date: string # Due date of the ticket (nullable, format: date-time, e.g. 2020-09-30T07:43:32.000Z)
  --parent-id: string # The ticket's parent ID (e.g. 12345)
  --priority: string@priority-completer # Priority of the ticket (e.g. high)
  --status: string # The current status of the ticket. Possible values include: open, in_progress, closed, or - in cases where there is no clear mapping - the original value passed through. (nullable, e.g. open)
  --subject: string # Subject of the ticket (e.g. Technical Support Request)
  --tags: list # item shape: {id: string}
  --type: string # The ticket's type (e.g. Technical)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/issue-tracking/collections/{collection_id}/tickets"
    path_params: [{name: collection_id, var: collection_id}]
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: assignees, var: assignees}, {name: description, var: description}, {name: due_date, var: due_date}, {name: parent_id, var: parent_id}, {name: priority, var: priority}, {name: status, var: status}, {name: subject, var: subject}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    collection_id: $collection_id, qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id, assignees: $assignees, description: $description, due_date: $due_date, parent_id: $parent_id, priority: $priority, status: $status, subject: $subject, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Ticket
#
# DELETE /issue-tracking/collections/{collection_id}/tickets/{ticket_id}
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: collectionTicketsDelete
export def "collection-tickets-delete" [
  collection_id: string
  ticket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/issue-tracking/collections/{collection_id}/tickets/{ticket_id}"
    path_params: [{name: collection_id, var: collection_id}, {name: ticket_id, var: ticket_id}]
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    collection_id: $collection_id, ticket_id: $ticket_id, qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Ticket
#
# GET /issue-tracking/collections/{collection_id}/tickets/{ticket_id}
# Returns: record<data: record<assignees: list<record>, collection_id: string, completed_at: string, created_at: string, created_by: string, description: string, due_date: string, id: string, parent_id: string, priority: string, status: string, subject: string, tags: list<record>, type: string, updated_at: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: collectionTicketsOne
export def "collection-tickets-one" [
  collection_id: string
  ticket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. Example: `fields=name,email,addresses.city`In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/issue-tracking/collections/{collection_id}/tickets/{ticket_id}"
    path_params: [{name: collection_id, var: collection_id}, {name: ticket_id, var: ticket_id}]
    query: [{name: raw, var: qp_raw}, {name: fields, var: fields}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    collection_id: $collection_id, ticket_id: $ticket_id, qp_raw: $qp_raw, fields: $fields, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Ticket
#
# PATCH /issue-tracking/collections/{collection_id}/tickets/{ticket_id}
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: collectionTicketsUpdate
export def "collection-tickets-update" [
  collection_id: string
  ticket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
  --assignees: list # item shape: {id: string}
  --description: string # The ticket's description. HTML version of description is mapped if supported by the third-party platform (e.g. I am facing issues with my internet connection)
  --due-date: string # Due date of the ticket (nullable, format: date-time, e.g. 2020-09-30T07:43:32.000Z)
  --parent-id: string # The ticket's parent ID (e.g. 12345)
  --priority: string@priority-completer # Priority of the ticket (e.g. high)
  --status: string # The current status of the ticket. Possible values include: open, in_progress, closed, or - in cases where there is no clear mapping - the original value passed through. (nullable, e.g. open)
  --subject: string # Subject of the ticket (e.g. Technical Support Request)
  --tags: list # item shape: {id: string}
  --type: string # The ticket's type (e.g. Technical)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/issue-tracking/collections/{collection_id}/tickets/{ticket_id}"
    path_params: [{name: collection_id, var: collection_id}, {name: ticket_id, var: ticket_id}]
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: assignees, var: assignees}, {name: description, var: description}, {name: due_date, var: due_date}, {name: parent_id, var: parent_id}, {name: priority, var: priority}, {name: status, var: status}, {name: subject, var: subject}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    collection_id: $collection_id, ticket_id: $ticket_id, qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id, assignees: $assignees, description: $description, due_date: $due_date, parent_id: $parent_id, priority: $priority, status: $status, subject: $subject, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Comments
#
# GET /issue-tracking/collections/{collection_id}/tickets/{ticket_id}/comments
# Returns: record<data: table<body: string, created_at: string, created_by: string, id: string, updated_at: string>, links: record<current: string, next: string, previous: string>, meta: record<cursors: record<current: string, next: string, previous: string>, items_on_page: int>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: collectionTicketCommentsAll
export def "collection-ticket-comments-all" [
  collection_id: string
  ticket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --cursor: string # Cursor to start from. You can find cursors for next/previous pages in the meta.cursors property of the response. (nullable)
  --limit: int # Number of results to return. Minimum 1, Maximum 200, Default 20 (default: 20)
  --sort: record # Apply sorting (e.g. {by: created_at, direction: desc})
  --fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. Example: `fields=name,email,addresses.city`In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/issue-tracking/collections/{collection_id}/tickets/{ticket_id}/comments"
    path_params: [{name: collection_id, var: collection_id}, {name: ticket_id, var: ticket_id}]
    query: [{name: raw, var: qp_raw}, {name: cursor, var: cursor}, {name: limit, var: limit}, {name: sort, var: sort, style: deepObject}, {name: fields, var: fields}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    collection_id: $collection_id, ticket_id: $ticket_id, qp_raw: $qp_raw, cursor: $cursor, limit: $limit, sort: $sort, fields: $fields, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Comment
#
# POST /issue-tracking/collections/{collection_id}/tickets/{ticket_id}/comments
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: collectionTicketCommentsAdd
export def "collection-ticket-comments-add" [
  collection_id: string
  ticket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
  --body: string # Body of the comment (e.g. What internet provider do you use?)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/issue-tracking/collections/{collection_id}/tickets/{ticket_id}/comments"
    path_params: [{name: collection_id, var: collection_id}, {name: ticket_id, var: ticket_id}]
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: body, var: body}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    collection_id: $collection_id, ticket_id: $ticket_id, qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Comment
#
# DELETE /issue-tracking/collections/{collection_id}/tickets/{ticket_id}/comments/{id}
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: collectionTicketCommentsDelete
export def "collection-ticket-comments-delete" [
  collection_id: string
  ticket_id: string
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
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/issue-tracking/collections/{collection_id}/tickets/{ticket_id}/comments/{id}"
    path_params: [{name: collection_id, var: collection_id}, {name: ticket_id, var: ticket_id}, {name: id, var: id}]
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    collection_id: $collection_id, ticket_id: $ticket_id, id: $id, qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Comment
#
# GET /issue-tracking/collections/{collection_id}/tickets/{ticket_id}/comments/{id}
# Returns: record<data: record<body: string, created_at: string, created_by: string, id: string, updated_at: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: collectionTicketCommentsOne
export def "collection-ticket-comments-one" [
  collection_id: string
  ticket_id: string
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
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --cursor: string # Cursor to start from. You can find cursors for next/previous pages in the meta.cursors property of the response. (nullable)
  --limit: int # Number of results to return. Minimum 1, Maximum 200, Default 20 (default: 20)
  --fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. Example: `fields=name,email,addresses.city`In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/issue-tracking/collections/{collection_id}/tickets/{ticket_id}/comments/{id}"
    path_params: [{name: collection_id, var: collection_id}, {name: ticket_id, var: ticket_id}, {name: id, var: id}]
    query: [{name: raw, var: qp_raw}, {name: cursor, var: cursor}, {name: limit, var: limit}, {name: fields, var: fields}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    collection_id: $collection_id, ticket_id: $ticket_id, id: $id, qp_raw: $qp_raw, cursor: $cursor, limit: $limit, fields: $fields, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Comment
#
# PATCH /issue-tracking/collections/{collection_id}/tickets/{ticket_id}/comments/{id}
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: collectionTicketCommentsUpdate
export def "collection-ticket-comments-update" [
  collection_id: string
  ticket_id: string
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
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
  --body: string # Body of the comment (e.g. What internet provider do you use?)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/issue-tracking/collections/{collection_id}/tickets/{ticket_id}/comments/{id}"
    path_params: [{name: collection_id, var: collection_id}, {name: ticket_id, var: ticket_id}, {name: id, var: id}]
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: body, var: body}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    collection_id: $collection_id, ticket_id: $ticket_id, id: $id, qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Users
#
# GET /issue-tracking/collections/{collection_id}/users
# Returns: record<data: table<created_at: string, email: string, first_name: string, id: string, last_name: string, name: string, photo_url: string, updated_at: string>, links: record<current: string, next: string, previous: string>, meta: record<cursors: record<current: string, next: string, previous: string>, items_on_page: int>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: collectionUsersAll
export def "collection-users-all" [
  collection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --cursor: string # Cursor to start from. You can find cursors for next/previous pages in the meta.cursors property of the response. (nullable)
  --limit: int # Number of results to return. Minimum 1, Maximum 200, Default 20 (default: 20)
  --fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. Example: `fields=name,email,addresses.city`In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/issue-tracking/collections/{collection_id}/users"
    path_params: [{name: collection_id, var: collection_id}]
    query: [{name: raw, var: qp_raw}, {name: cursor, var: cursor}, {name: limit, var: limit}, {name: fields, var: fields}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    collection_id: $collection_id, qp_raw: $qp_raw, cursor: $cursor, limit: $limit, fields: $fields, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get user
#
# GET /issue-tracking/collections/{collection_id}/users/{id}
# Returns: record<data: record<created_at: string, email: string, first_name: string, id: string, last_name: string, name: string, photo_url: string, updated_at: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: collectionUsersOne
export def "collection-users-one" [
  collection_id: string
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
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. Example: `fields=name,email,addresses.city`In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/issue-tracking/collections/{collection_id}/users/{id}"
    path_params: [{name: collection_id, var: collection_id}, {name: id, var: id}]
    query: [{name: raw, var: qp_raw}, {name: fields, var: fields}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    collection_id: $collection_id, id: $id, qp_raw: $qp_raw, fields: $fields, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
