# Auto-generated client for OnSched Setup API v1
# Source: https://api.apis.guru/v2/specs/onsched.com/setup/v1/openapi.json
# Auth: --token flag or $env.ONSCHED_SETUP_API_TOKEN

const CLIENT = {
  base_url: "https://sandbox-api.onsched.com"
  token_env_var: "ONSCHED_SETUP_API_TOKEN"
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

def base-url-completer [] { ["https://sandbox-api.onsched.com"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-setup-v1-appointments: "record<count: int, data: table<auditTrail: list, bookedBy: string, businessName: string, calendarId: string, confirmationNumber: string, confirmed: bool, createDate: string, customFields: record, customerId: string, customerMessage: string, customers: list, date: string, dateInternational: string, downloadIcsUrl: string, duration: int, email: string, emailConfirmationSent: string, emailReminderSent: string, endDateTime: string, firstname: string, groupSize: int, id: string, ipAddress: string, lastModifiedBy: string, lastModifiedOn: string, lastname: string, latitude: string, location: string, locationId: string, longitude: string, name: string, notes: string, object: string, onlineBooking: bool, paymentStatus: int, phone: string, phoneExt: string, phoneType: string, rescheduledId: string, resourceEmail: string, resourceGroupId: string, resourceGroupName: string, resourceId: string, resourceImageUrl: string, resourceName: string, resources: list, serviceAllocationId: string, serviceId: string, serviceImageUrl: string, serviceName: string, smsConfirmationSent: string, smsReminderSent: string, startDateTime: string, status: string, stripeChargeId: string, stripeRefundId: string, time: int, timezone: int, timezoneIana: string, timezoneId: string>, hasMore: bool, object: string, total: int, url: string>"
    get-setup-v1-appointments-id: "record<auditTrail: table<appointmentId: string, id: string, modificationType: string, modifiedBy: string, modifiedOn: string, notesAfter: string, notesBefore: string, statusAfter: string, statusBefore: string>, bookedBy: string, businessName: string, calendarId: string, confirmationNumber: string, confirmed: bool, createDate: string, customFields: record, customerId: string, customerMessage: string, customers: table<appointmentId: string, customerId: string>, date: string, dateInternational: string, downloadIcsUrl: string, duration: int, email: string, emailConfirmationSent: string, emailReminderSent: string, endDateTime: string, firstname: string, groupSize: int, id: string, ipAddress: string, lastModifiedBy: string, lastModifiedOn: string, lastname: string, latitude: string, location: string, locationId: string, longitude: string, name: string, notes: string, object: string, onlineBooking: bool, paymentStatus: int, phone: string, phoneExt: string, phoneType: string, rescheduledId: string, resourceEmail: string, resourceGroupId: string, resourceGroupName: string, resourceId: string, resourceImageUrl: string, resourceName: string, resources: table<appointmentId: string, resourceEmail: string, resourceGroupId: string, resourceId: string, resourceImageUrl: string, resourceName: string>, serviceAllocationId: string, serviceId: string, serviceImageUrl: string, serviceName: string, smsConfirmationSent: string, smsReminderSent: string, startDateTime: string, status: string, stripeChargeId: string, stripeRefundId: string, time: int, timezone: int, timezoneIana: string, timezoneId: string>"
    put-setup-v1-appointments-id-reassign-resource-resource-id: "record<auditTrail: table<appointmentId: string, id: string, modificationType: string, modifiedBy: string, modifiedOn: string, notesAfter: string, notesBefore: string, statusAfter: string, statusBefore: string>, bookedBy: string, businessName: string, calendarId: string, confirmationNumber: string, confirmed: bool, createDate: string, customFields: record, customerId: string, customerMessage: string, customers: table<appointmentId: string, customerId: string>, date: string, dateInternational: string, downloadIcsUrl: string, duration: int, email: string, emailConfirmationSent: string, emailReminderSent: string, endDateTime: string, firstname: string, groupSize: int, id: string, ipAddress: string, lastModifiedBy: string, lastModifiedOn: string, lastname: string, latitude: string, location: string, locationId: string, longitude: string, name: string, notes: string, object: string, onlineBooking: bool, paymentStatus: int, phone: string, phoneExt: string, phoneType: string, rescheduledId: string, resourceEmail: string, resourceGroupId: string, resourceGroupName: string, resourceId: string, resourceImageUrl: string, resourceName: string, resources: table<appointmentId: string, resourceEmail: string, resourceGroupId: string, resourceId: string, resourceImageUrl: string, resourceName: string>, serviceAllocationId: string, serviceId: string, serviceImageUrl: string, serviceName: string, smsConfirmationSent: string, smsReminderSent: string, startDateTime: string, status: string, stripeChargeId: string, stripeRefundId: string, time: int, timezone: int, timezoneIana: string, timezoneId: string>"
    get-setup-v1-businessusers: "record<count: int, data: table<accountId: string, businessName: string, email: string, id: string, identityAccount: bool, locationId: string, name: string, object: string, permissions: list, resourceId: string, resourceName: string, role: string>, hasMore: bool, object: string, total: int, url: string>"
    post-setup-v1-businessusers: "record<accountId: string, businessName: string, email: string, id: string, identityAccount: bool, locationId: string, name: string, object: string, permissions: table<access: string, function: string, object: string>, resourceId: string, resourceName: string, role: string>"
    get-setup-v1-businessusers-permissions: "record<count: int, data: table<access: string, function: string, object: string, role: string>, hasMore: bool, object: string, total: int, url: string>"
    get-setup-v1-businessusers-email-companies: "record<count: int, data: table<id: string, name: string, object: string>, email: string, hasMore: bool, object: string, total: int, url: string>"
    get-setup-v1-businessusers-id: "record<accountId: string, businessName: string, email: string, id: string, identityAccount: bool, locationId: string, name: string, object: string, permissions: table<access: string, function: string, object: string>, resourceId: string, resourceName: string, role: string>"
    put-setup-v1-businessusers-id: "record<accountId: string, businessName: string, email: string, id: string, identityAccount: bool, locationId: string, name: string, object: string, permissions: table<access: string, function: string, object: string>, resourceId: string, resourceName: string, role: string>"
    get-setup-v1-calendars: "record<count: int, data: table<availability: record, bookingsPerSlot: int, deletedStatus: bool, deletedTime: string, id: string, interval: int, locationId: string, name: string, object: string, primary: bool, resourceGroupId: string, type: string>, hasMore: bool, object: string, total: int, url: string>"
    post-setup-v1-calendars: "record<availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bookingsPerSlot: int, deletedStatus: bool, deletedTime: string, id: string, interval: int, locationId: string, name: string, object: string, primary: bool, resourceGroupId: string, type: string>"
    delete-setup-v1-calendars-block-id: "record<calendarId: string, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: string, locationId: string, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, startDate: string, startTime: int>"
    put-setup-v1-calendars-block-id: "record<calendarId: string, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: string, locationId: string, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, startDate: string, startTime: int>"
    get-setup-v1-calendars-blocks-id: "record<calendarId: string, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: string, locationId: string, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, startDate: string, startTime: int>"
    delete-setup-v1-calendars-id: "record<availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bookingsPerSlot: int, deletedStatus: bool, deletedTime: string, id: string, interval: int, locationId: string, name: string, object: string, primary: bool, resourceGroupId: string, type: string>"
    get-setup-v1-calendars-id: "record<availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bookingsPerSlot: int, deletedStatus: bool, deletedTime: string, id: string, interval: int, locationId: string, name: string, object: string, primary: bool, resourceGroupId: string, type: string>"
    put-setup-v1-calendars-id: "record<availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bookingsPerSlot: int, deletedStatus: bool, deletedTime: string, id: string, interval: int, locationId: string, name: string, object: string, primary: bool, resourceGroupId: string, type: string>"
    post-setup-v1-calendars-id-block: "record<businessId: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: int, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, resourceId: int, startDate: string, startTime: int>"
    get-setup-v1-calendars-id-blocks: "record<count: int, data: table<calendarId: string, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: string, locationId: string, object: string, reason: string, repeat: record, repeats: bool, startDate: string, startTime: int>, hasMore: bool, object: string, total: int, url: string>"
    put-setup-v1-calendars-id-recover: "record<availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bookingsPerSlot: int, deletedStatus: bool, deletedTime: string, id: string, interval: int, locationId: string, name: string, object: string, primary: bool, resourceGroupId: string, type: string>"
    get-setup-v1-calendars-id-services: "record<count: int, data: table<availability: record, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookingInterval: int, bookingLimit: int, calendarId: string, calendarResourceGroupId: string, cancellationFeeAmount: float, cancellationFeeTaxable: bool, companyId: string, consumerPadding: bool, customFields: record, dailyBookingLimitCount: int, dailyBookingLimitMinutes: int, defaultService: bool, description: string, duration: int, durationInterval: int, durationMax: int, durationMin: int, durationSelect: bool, feeAmount: float, feeTaxable: bool, id: string, imageUrl: string, locationId: string, maxBookingLimit: int, maxCapacity: int, maxGroupSize: int, maxResourceBookingLimit: int, mediaPageUrl: string, name: string, nonRefundable: bool, object: string, padding: int, roundRobin: int, serviceGroupId: int, serviceGroupName: string, showOnline: bool, type: string>, hasMore: bool, object: string, total: int, url: string>"
    get-setup-v1-companies: "record<addressLine1: string, addressLine2: string, bookingWebhookUrl: string, city: string, clientId: string, clientSecret: string, country: string, customerWebhookUrl: string, deletedStatus: bool, deletedTime: string, disableEmailAndSmsNotifications: bool, email: string, fax: string, id: string, name: string, notificationFromEmailAddress: string, notificationFromName: string, object: string, phone: string, postalCode: string, registrationDate: string, registrationEmail: string, reminderWebhookUrl: string, resourceWebhookUrl: string, state: string, timezoneId: string, timezoneName: string, webhookSignatureHash: string, website: string>"
    post-setup-v1-companies: "record<addressLine1: string, addressLine2: string, bookingWebhookUrl: string, city: string, clientId: string, clientSecret: string, country: string, customerWebhookUrl: string, deletedStatus: bool, deletedTime: string, disableEmailAndSmsNotifications: bool, email: string, fax: string, id: string, name: string, notificationFromEmailAddress: string, notificationFromName: string, object: string, phone: string, postalCode: string, registrationDate: string, registrationEmail: string, reminderWebhookUrl: string, resourceWebhookUrl: string, state: string, timezoneId: string, timezoneName: string, webhookSignatureHash: string, website: string>"
    put-setup-v1-companies: "record<addressLine1: string, addressLine2: string, bookingWebhookUrl: string, city: string, clientId: string, clientSecret: string, country: string, customerWebhookUrl: string, deletedStatus: bool, deletedTime: string, disableEmailAndSmsNotifications: bool, email: string, fax: string, id: string, name: string, notificationFromEmailAddress: string, notificationFromName: string, object: string, phone: string, postalCode: string, registrationDate: string, registrationEmail: string, reminderWebhookUrl: string, resourceWebhookUrl: string, state: string, timezoneId: string, timezoneName: string, webhookSignatureHash: string, website: string>"
    get-setup-v1-companies-domains: "record<data: table<domain: string, id: string, object: string>, object: string, url: string>"
    post-setup-v1-companies-domains: "record<domain: string, id: string, object: string>"
    delete-setup-v1-companies-domains-id: "record<domain: string, id: string, object: string>"
    get-setup-v1-companies-domains-id: "record<domain: string, id: string, object: string>"
    put-setup-v1-companies-domains-id: "record<domain: string, id: string, object: string>"
    get-setup-v1-companies-email-templates: "record<data: table<customized: bool, description: string, name: string, object: string, scope: string>, object: string, total: int, url: string>"
    delete-setup-v1-companies-email-templates-master: "record<centerEmailContent: bool, centerEmailContentPanel: bool, centerEmailFooter: bool, contentBackgroundColor: string, contentColor: string, contentLinkColor: string, emailBackgroundColor: string, emailColor: string, emailLinkColor: string, footerFontSize: string, footerLogoHeight: string, footerLogoPadding: string, footerPanelEmailContact: bool, footerPanelPhoneContact: bool, footerPanelWebsiteContact: bool, headerLogoHeight: string, headerLogoPadding: string, panelBackgroundColor: string, panelColor: string, panelLinkColor: string, privacyPolicyLink: string, showContentPanel: bool, showFooterLogo: bool, showFooterPanel: bool, showHeaderLogo: bool, showHeaderPanel: bool, version: string>"
    get-setup-v1-companies-email-templates-master: "record<centerEmailContent: bool, centerEmailContentPanel: bool, centerEmailFooter: bool, contentBackgroundColor: string, contentColor: string, contentLinkColor: string, emailBackgroundColor: string, emailColor: string, emailLinkColor: string, footerFontSize: string, footerLogoHeight: string, footerLogoPadding: string, footerPanelEmailContact: bool, footerPanelPhoneContact: bool, footerPanelWebsiteContact: bool, headerLogoHeight: string, headerLogoPadding: string, panelBackgroundColor: string, panelColor: string, panelLinkColor: string, privacyPolicyLink: string, showContentPanel: bool, showFooterLogo: bool, showFooterPanel: bool, showHeaderLogo: bool, showHeaderPanel: bool, version: string>"
    post-setup-v1-companies-email-templates-master: "record<centerEmailContent: bool, centerEmailContentPanel: bool, centerEmailFooter: bool, contentBackgroundColor: string, contentColor: string, contentLinkColor: string, emailBackgroundColor: string, emailColor: string, emailLinkColor: string, footerFontSize: string, footerLogoHeight: string, footerLogoPadding: string, footerPanelEmailContact: bool, footerPanelPhoneContact: bool, footerPanelWebsiteContact: bool, headerLogoHeight: string, headerLogoPadding: string, panelBackgroundColor: string, panelColor: string, panelLinkColor: string, privacyPolicyLink: string, showContentPanel: bool, showFooterLogo: bool, showFooterPanel: bool, showHeaderLogo: bool, showHeaderPanel: bool, version: string>"
    get-setup-v1-companies-email-templates-template-name: "record<content: string, contentType: string, statusCode: int>"
    get-setup-v1-companies-regions: "record<count: int, data: table<id: string, name: string, object: string>, hasMore: bool, object: string, total: int, url: string>"
    post-setup-v1-companies-regions: "record<id: string, name: string, object: string>"
    delete-setup-v1-companies-regions-id: "record<id: string, name: string, object: string>"
    get-setup-v1-companies-regions-id: "record<id: string, name: string, object: string>"
    put-setup-v1-companies-regions-id: "record<id: string, name: string, object: string>"
    get-setup-v1-companies-timezones-date: "record<object: string, regions: list<string>, timezones: table<name: string, region: string, timezoneIanna: string, tzOffset: int>>"
    get-setup-v1-customers: "record<count: int, data: table<address: record, birthdate: string, businessName: string, companyName: string, contact: record, createdBy: string, createdOn: string, customFields: record, deletedStatus: bool, deletedTime: string, disabled: bool, email: string, emailInfo: bool, emailPromotion: bool, firstname: string, gender: string, groupId: string, id: string, inviteEmailSent: string, lastVisitDate: string, lastname: string, latitude: string, locationId: string, longitude: string, modifiedBy: string, modifiedOn: string, name: string, notificationType: string, object: string, registeredBy: string, registrationDate: string, resourceId: string, stripeCustomerId: string, subscriptionId: string, verificationDate: string, verifiedBy: string, welcomeEmailSent: string>, hasMore: bool, object: string, total: int, url: string>"
    get-setup-v1-customers-id: "record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, birthdate: string, businessName: string, companyName: string, contact: record<businessPhone: string, businessPhoneExt: string, conferenceInfo: string, homePhone: string, mobilePhone: string, phoneType: string, skypeUsername: string>, createdBy: string, createdOn: string, customFields: record, deletedStatus: bool, deletedTime: string, disabled: bool, email: string, emailInfo: bool, emailPromotion: bool, firstname: string, gender: string, groupId: string, id: string, inviteEmailSent: string, lastVisitDate: string, lastname: string, latitude: string, locationId: string, longitude: string, modifiedBy: string, modifiedOn: string, name: string, notificationType: string, object: string, registeredBy: string, registrationDate: string, resourceId: string, stripeCustomerId: string, subscriptionId: string, verificationDate: string, verifiedBy: string, welcomeEmailSent: string>"
    get-setup-v1-customers-id-privacy: "record<appointments: table<auditTrail: list, bookedBy: string, businessName: string, calendarId: string, confirmationNumber: string, confirmed: bool, createDate: string, customFields: record, customerId: string, customerMessage: string, customers: list, date: string, dateInternational: string, downloadIcsUrl: string, duration: int, email: string, emailConfirmationSent: string, emailReminderSent: string, endDateTime: string, firstname: string, groupSize: int, id: string, ipAddress: string, lastModifiedBy: string, lastModifiedOn: string, lastname: string, latitude: string, location: string, locationId: string, longitude: string, name: string, notes: string, object: string, onlineBooking: bool, paymentStatus: int, phone: string, phoneExt: string, phoneType: string, rescheduledId: string, resourceEmail: string, resourceGroupId: string, resourceGroupName: string, resourceId: string, resourceImageUrl: string, resourceName: string, resources: list, serviceAllocationId: string, serviceId: string, serviceImageUrl: string, serviceName: string, smsConfirmationSent: string, smsReminderSent: string, startDateTime: string, status: string, stripeChargeId: string, stripeRefundId: string, time: int, timezone: int, timezoneIana: string, timezoneId: string>, customer: record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, birthdate: string, businessName: string, companyName: string, contact: record<businessPhone: string, businessPhoneExt: string, conferenceInfo: string, homePhone: string, mobilePhone: string, phoneType: string, skypeUsername: string>, createdBy: string, createdOn: string, customFields: record, deletedStatus: bool, deletedTime: string, disabled: bool, email: string, emailInfo: bool, emailPromotion: bool, firstname: string, gender: string, groupId: string, id: string, inviteEmailSent: string, lastVisitDate: string, lastname: string, latitude: string, locationId: string, longitude: string, modifiedBy: string, modifiedOn: string, name: string, notificationType: string, object: string, registeredBy: string, registrationDate: string, resourceId: string, stripeCustomerId: string, subscriptionId: string, verificationDate: string, verifiedBy: string, welcomeEmailSent: string>>"
    get-setup-v1-locations: "record<count: int, data: table<address: record, adminEmail: string, adminName: string, appointmentReminders: record, businessHolidays: list, businessHours: record, companyId: string, companyName: string, defaults: record, email: string, fax: string, friendlyId: string, id: string, imageUrl: string, latitude: float, logo: string, longitude: float, name: string, object: string, phone: string, primaryBusiness: bool, primaryCalendarId: string, regionId: string, services: list, settings: record, timezoneIana: string, timezoneId: string, timezoneOffset: int, travel: record, website: string>, hasMore: bool, object: string, total: int, url: string>"
    post-setup-v1-locations: "record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, adminEmail: string, adminName: string, appointmentReminders: record<emailFirstReminder: int, emailFirstReminderInterval: int, emailSecondReminder: int, emailSecondReminderInterval: int, smsFirstReminder: int, smsFirstReminderInterval: int, smsSecondReminder: int, smsSecondReminderInterval: int>, businessHolidays: table<businessClosed: bool, holidayName: string, id: string, publicHolidayId: int>, businessHours: record<fri: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, mon: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sat: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sun: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, thu: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, tue: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, wed: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>>, companyId: string, companyName: string, defaults: record<autoUpdateCustomer: bool, businessNotification: bool, customerCity: bool, customerState: bool, emailInfo: bool, enableUtcTimezone: bool, object: string>, email: string, fax: string, friendlyId: string, id: string, imageUrl: string, latitude: float, logo: string, longitude: float, name: string, object: string, phone: string, primaryBusiness: bool, primaryCalendarId: string, regionId: string, services: table<id: int, object: string, serviceId: int, serviceName: string>, settings: record<availabilityForm: int, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookWithAccount: bool, bookingConfirmationMessage: string, bookingMessage: string, bookingPolicy: string, bookingTimerMins: int, businessId: string, companyId: string, customerBookingsPerDay: int, customerVerification: bool, defaultService: bool, defaultToCustomerTimezone: bool, disableAuthorization: bool, enableWorldTimezones: bool, enabled: bool, familyMembersEnabled: bool, firstAvailable: bool, formFlow: int, hideBreadCrumbNav: bool, hideContinueBooking: bool, hideLocationNav: bool, hideNavBar: bool, hideServiceGroupsNav: bool, hideServicesNav: bool, id: int, lateCancelAction: int, lateCancelHours: int, lateRescheduleAction: int, lateRescheduleHours: int, liveMode: bool, locationId: string, object: string, resourceAnyLabel: string, resourceLabel: string, resourceSelection: bool, returnToAvailability: bool, returnToService: bool, serviceLabel: string, showBusinessLogo: bool, showOnSchedLogo: bool, showServiceGroups: bool>, timezoneIana: string, timezoneId: string, timezoneOffset: int, travel: record<distance: string, proximity: string, startAddress: string, startLat: string, startLon: string, units: string>, website: string>"
    post-setup-v1-locations-bulk: "table<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, adminEmail: string, adminName: string, appointmentReminders: record<emailFirstReminder: int, emailFirstReminderInterval: int, emailSecondReminder: int, emailSecondReminderInterval: int, smsFirstReminder: int, smsFirstReminderInterval: int, smsSecondReminder: int, smsSecondReminderInterval: int>, businessHolidays: list<record>, businessHours: record<fri: record, mon: record, sat: record, sun: record, thu: record, tue: record, wed: record>, companyId: string, companyName: string, defaults: record<autoUpdateCustomer: bool, businessNotification: bool, customerCity: bool, customerState: bool, emailInfo: bool, enableUtcTimezone: bool, object: string>, email: string, fax: string, friendlyId: string, id: string, imageUrl: string, latitude: float, logo: string, longitude: float, name: string, object: string, phone: string, primaryBusiness: bool, primaryCalendarId: string, regionId: string, services: list<record>, settings: record<availabilityForm: int, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookWithAccount: bool, bookingConfirmationMessage: string, bookingMessage: string, bookingPolicy: string, bookingTimerMins: int, businessId: string, companyId: string, customerBookingsPerDay: int, customerVerification: bool, defaultService: bool, defaultToCustomerTimezone: bool, disableAuthorization: bool, enableWorldTimezones: bool, enabled: bool, familyMembersEnabled: bool, firstAvailable: bool, formFlow: int, hideBreadCrumbNav: bool, hideContinueBooking: bool, hideLocationNav: bool, hideNavBar: bool, hideServiceGroupsNav: bool, hideServicesNav: bool, id: int, lateCancelAction: int, lateCancelHours: int, lateRescheduleAction: int, lateRescheduleHours: int, liveMode: bool, locationId: string, object: string, resourceAnyLabel: string, resourceLabel: string, resourceSelection: bool, returnToAvailability: bool, returnToService: bool, serviceLabel: string, showBusinessLogo: bool, showOnSchedLogo: bool, showServiceGroups: bool>, timezoneIana: string, timezoneId: string, timezoneOffset: int, travel: record<distance: string, proximity: string, startAddress: string, startLat: string, startLon: string, units: string>, website: string>"
    delete-setup-v1-locations-services-id: "record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, adminEmail: string, adminName: string, appointmentReminders: record<emailFirstReminder: int, emailFirstReminderInterval: int, emailSecondReminder: int, emailSecondReminderInterval: int, smsFirstReminder: int, smsFirstReminderInterval: int, smsSecondReminder: int, smsSecondReminderInterval: int>, businessHolidays: table<businessClosed: bool, holidayName: string, id: string, publicHolidayId: int>, businessHours: record<fri: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, mon: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sat: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sun: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, thu: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, tue: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, wed: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>>, companyId: string, companyName: string, defaults: record<autoUpdateCustomer: bool, businessNotification: bool, customerCity: bool, customerState: bool, emailInfo: bool, enableUtcTimezone: bool, object: string>, email: string, fax: string, friendlyId: string, id: string, imageUrl: string, latitude: float, logo: string, longitude: float, name: string, object: string, phone: string, primaryBusiness: bool, primaryCalendarId: string, regionId: string, services: table<id: int, object: string, serviceId: int, serviceName: string>, settings: record<availabilityForm: int, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookWithAccount: bool, bookingConfirmationMessage: string, bookingMessage: string, bookingPolicy: string, bookingTimerMins: int, businessId: string, companyId: string, customerBookingsPerDay: int, customerVerification: bool, defaultService: bool, defaultToCustomerTimezone: bool, disableAuthorization: bool, enableWorldTimezones: bool, enabled: bool, familyMembersEnabled: bool, firstAvailable: bool, formFlow: int, hideBreadCrumbNav: bool, hideContinueBooking: bool, hideLocationNav: bool, hideNavBar: bool, hideServiceGroupsNav: bool, hideServicesNav: bool, id: int, lateCancelAction: int, lateCancelHours: int, lateRescheduleAction: int, lateRescheduleHours: int, liveMode: bool, locationId: string, object: string, resourceAnyLabel: string, resourceLabel: string, resourceSelection: bool, returnToAvailability: bool, returnToService: bool, serviceLabel: string, showBusinessLogo: bool, showOnSchedLogo: bool, showServiceGroups: bool>, timezoneIana: string, timezoneId: string, timezoneOffset: int, travel: record<distance: string, proximity: string, startAddress: string, startLat: string, startLon: string, units: string>, website: string>"
    get-setup-v1-locations-services-id: "record<id: int, object: string, serviceId: int, serviceName: string>"
    delete-setup-v1-locations-id: "record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, adminEmail: string, adminName: string, appointmentReminders: record<emailFirstReminder: int, emailFirstReminderInterval: int, emailSecondReminder: int, emailSecondReminderInterval: int, smsFirstReminder: int, smsFirstReminderInterval: int, smsSecondReminder: int, smsSecondReminderInterval: int>, businessHolidays: table<businessClosed: bool, holidayName: string, id: string, publicHolidayId: int>, businessHours: record<fri: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, mon: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sat: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sun: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, thu: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, tue: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, wed: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>>, companyId: string, companyName: string, defaults: record<autoUpdateCustomer: bool, businessNotification: bool, customerCity: bool, customerState: bool, emailInfo: bool, enableUtcTimezone: bool, object: string>, email: string, fax: string, friendlyId: string, id: string, imageUrl: string, latitude: float, logo: string, longitude: float, name: string, object: string, phone: string, primaryBusiness: bool, primaryCalendarId: string, regionId: string, services: table<id: int, object: string, serviceId: int, serviceName: string>, settings: record<availabilityForm: int, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookWithAccount: bool, bookingConfirmationMessage: string, bookingMessage: string, bookingPolicy: string, bookingTimerMins: int, businessId: string, companyId: string, customerBookingsPerDay: int, customerVerification: bool, defaultService: bool, defaultToCustomerTimezone: bool, disableAuthorization: bool, enableWorldTimezones: bool, enabled: bool, familyMembersEnabled: bool, firstAvailable: bool, formFlow: int, hideBreadCrumbNav: bool, hideContinueBooking: bool, hideLocationNav: bool, hideNavBar: bool, hideServiceGroupsNav: bool, hideServicesNav: bool, id: int, lateCancelAction: int, lateCancelHours: int, lateRescheduleAction: int, lateRescheduleHours: int, liveMode: bool, locationId: string, object: string, resourceAnyLabel: string, resourceLabel: string, resourceSelection: bool, returnToAvailability: bool, returnToService: bool, serviceLabel: string, showBusinessLogo: bool, showOnSchedLogo: bool, showServiceGroups: bool>, timezoneIana: string, timezoneId: string, timezoneOffset: int, travel: record<distance: string, proximity: string, startAddress: string, startLat: string, startLon: string, units: string>, website: string>"
    get-setup-v1-locations-id: "record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, adminEmail: string, adminName: string, appointmentReminders: record<emailFirstReminder: int, emailFirstReminderInterval: int, emailSecondReminder: int, emailSecondReminderInterval: int, smsFirstReminder: int, smsFirstReminderInterval: int, smsSecondReminder: int, smsSecondReminderInterval: int>, businessHolidays: table<businessClosed: bool, holidayName: string, id: string, publicHolidayId: int>, businessHours: record<fri: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, mon: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sat: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sun: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, thu: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, tue: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, wed: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>>, companyId: string, companyName: string, defaults: record<autoUpdateCustomer: bool, businessNotification: bool, customerCity: bool, customerState: bool, emailInfo: bool, enableUtcTimezone: bool, object: string>, email: string, fax: string, friendlyId: string, id: string, imageUrl: string, latitude: float, logo: string, longitude: float, name: string, object: string, phone: string, primaryBusiness: bool, primaryCalendarId: string, regionId: string, services: table<id: int, object: string, serviceId: int, serviceName: string>, settings: record<availabilityForm: int, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookWithAccount: bool, bookingConfirmationMessage: string, bookingMessage: string, bookingPolicy: string, bookingTimerMins: int, businessId: string, companyId: string, customerBookingsPerDay: int, customerVerification: bool, defaultService: bool, defaultToCustomerTimezone: bool, disableAuthorization: bool, enableWorldTimezones: bool, enabled: bool, familyMembersEnabled: bool, firstAvailable: bool, formFlow: int, hideBreadCrumbNav: bool, hideContinueBooking: bool, hideLocationNav: bool, hideNavBar: bool, hideServiceGroupsNav: bool, hideServicesNav: bool, id: int, lateCancelAction: int, lateCancelHours: int, lateRescheduleAction: int, lateRescheduleHours: int, liveMode: bool, locationId: string, object: string, resourceAnyLabel: string, resourceLabel: string, resourceSelection: bool, returnToAvailability: bool, returnToService: bool, serviceLabel: string, showBusinessLogo: bool, showOnSchedLogo: bool, showServiceGroups: bool>, timezoneIana: string, timezoneId: string, timezoneOffset: int, travel: record<distance: string, proximity: string, startAddress: string, startLat: string, startLon: string, units: string>, website: string>"
    put-setup-v1-locations-id: "record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, adminEmail: string, adminName: string, appointmentReminders: record<emailFirstReminder: int, emailFirstReminderInterval: int, emailSecondReminder: int, emailSecondReminderInterval: int, smsFirstReminder: int, smsFirstReminderInterval: int, smsSecondReminder: int, smsSecondReminderInterval: int>, businessHolidays: table<businessClosed: bool, holidayName: string, id: string, publicHolidayId: int>, businessHours: record<fri: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, mon: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sat: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sun: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, thu: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, tue: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, wed: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>>, companyId: string, companyName: string, defaults: record<autoUpdateCustomer: bool, businessNotification: bool, customerCity: bool, customerState: bool, emailInfo: bool, enableUtcTimezone: bool, object: string>, email: string, fax: string, friendlyId: string, id: string, imageUrl: string, latitude: float, logo: string, longitude: float, name: string, object: string, phone: string, primaryBusiness: bool, primaryCalendarId: string, regionId: string, services: table<id: int, object: string, serviceId: int, serviceName: string>, settings: record<availabilityForm: int, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookWithAccount: bool, bookingConfirmationMessage: string, bookingMessage: string, bookingPolicy: string, bookingTimerMins: int, businessId: string, companyId: string, customerBookingsPerDay: int, customerVerification: bool, defaultService: bool, defaultToCustomerTimezone: bool, disableAuthorization: bool, enableWorldTimezones: bool, enabled: bool, familyMembersEnabled: bool, firstAvailable: bool, formFlow: int, hideBreadCrumbNav: bool, hideContinueBooking: bool, hideLocationNav: bool, hideNavBar: bool, hideServiceGroupsNav: bool, hideServicesNav: bool, id: int, lateCancelAction: int, lateCancelHours: int, lateRescheduleAction: int, lateRescheduleHours: int, liveMode: bool, locationId: string, object: string, resourceAnyLabel: string, resourceLabel: string, resourceSelection: bool, returnToAvailability: bool, returnToService: bool, serviceLabel: string, showBusinessLogo: bool, showOnSchedLogo: bool, showServiceGroups: bool>, timezoneIana: string, timezoneId: string, timezoneOffset: int, travel: record<distance: string, proximity: string, startAddress: string, startLat: string, startLon: string, units: string>, website: string>"
    get-setup-v1-locations-id-appointmentreminders: "record<emailFirstReminder: int, emailFirstReminderInterval: int, emailSecondReminder: int, emailSecondReminderInterval: int, smsFirstReminder: int, smsFirstReminderInterval: int, smsSecondReminder: int, smsSecondReminderInterval: int>"
    put-setup-v1-locations-id-appointmentreminders: "record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, adminEmail: string, adminName: string, appointmentReminders: record<emailFirstReminder: int, emailFirstReminderInterval: int, emailSecondReminder: int, emailSecondReminderInterval: int, smsFirstReminder: int, smsFirstReminderInterval: int, smsSecondReminder: int, smsSecondReminderInterval: int>, businessHolidays: table<businessClosed: bool, holidayName: string, id: string, publicHolidayId: int>, businessHours: record<fri: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, mon: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sat: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sun: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, thu: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, tue: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, wed: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>>, companyId: string, companyName: string, defaults: record<autoUpdateCustomer: bool, businessNotification: bool, customerCity: bool, customerState: bool, emailInfo: bool, enableUtcTimezone: bool, object: string>, email: string, fax: string, friendlyId: string, id: string, imageUrl: string, latitude: float, logo: string, longitude: float, name: string, object: string, phone: string, primaryBusiness: bool, primaryCalendarId: string, regionId: string, services: table<id: int, object: string, serviceId: int, serviceName: string>, settings: record<availabilityForm: int, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookWithAccount: bool, bookingConfirmationMessage: string, bookingMessage: string, bookingPolicy: string, bookingTimerMins: int, businessId: string, companyId: string, customerBookingsPerDay: int, customerVerification: bool, defaultService: bool, defaultToCustomerTimezone: bool, disableAuthorization: bool, enableWorldTimezones: bool, enabled: bool, familyMembersEnabled: bool, firstAvailable: bool, formFlow: int, hideBreadCrumbNav: bool, hideContinueBooking: bool, hideLocationNav: bool, hideNavBar: bool, hideServiceGroupsNav: bool, hideServicesNav: bool, id: int, lateCancelAction: int, lateCancelHours: int, lateRescheduleAction: int, lateRescheduleHours: int, liveMode: bool, locationId: string, object: string, resourceAnyLabel: string, resourceLabel: string, resourceSelection: bool, returnToAvailability: bool, returnToService: bool, serviceLabel: string, showBusinessLogo: bool, showOnSchedLogo: bool, showServiceGroups: bool>, timezoneIana: string, timezoneId: string, timezoneOffset: int, travel: record<distance: string, proximity: string, startAddress: string, startLat: string, startLon: string, units: string>, website: string>"
    delete-setup-v1-locations-id-deleteallimages: "bool"
    delete-setup-v1-locations-id-deleteimage: "record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, adminEmail: string, adminName: string, appointmentReminders: record<emailFirstReminder: int, emailFirstReminderInterval: int, emailSecondReminder: int, emailSecondReminderInterval: int, smsFirstReminder: int, smsFirstReminderInterval: int, smsSecondReminder: int, smsSecondReminderInterval: int>, businessHolidays: table<businessClosed: bool, holidayName: string, id: string, publicHolidayId: int>, businessHours: record<fri: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, mon: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sat: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sun: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, thu: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, tue: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, wed: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>>, companyId: string, companyName: string, defaults: record<autoUpdateCustomer: bool, businessNotification: bool, customerCity: bool, customerState: bool, emailInfo: bool, enableUtcTimezone: bool, object: string>, email: string, fax: string, friendlyId: string, id: string, imageUrl: string, latitude: float, logo: string, longitude: float, name: string, object: string, phone: string, primaryBusiness: bool, primaryCalendarId: string, regionId: string, services: table<id: int, object: string, serviceId: int, serviceName: string>, settings: record<availabilityForm: int, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookWithAccount: bool, bookingConfirmationMessage: string, bookingMessage: string, bookingPolicy: string, bookingTimerMins: int, businessId: string, companyId: string, customerBookingsPerDay: int, customerVerification: bool, defaultService: bool, defaultToCustomerTimezone: bool, disableAuthorization: bool, enableWorldTimezones: bool, enabled: bool, familyMembersEnabled: bool, firstAvailable: bool, formFlow: int, hideBreadCrumbNav: bool, hideContinueBooking: bool, hideLocationNav: bool, hideNavBar: bool, hideServiceGroupsNav: bool, hideServicesNav: bool, id: int, lateCancelAction: int, lateCancelHours: int, lateRescheduleAction: int, lateRescheduleHours: int, liveMode: bool, locationId: string, object: string, resourceAnyLabel: string, resourceLabel: string, resourceSelection: bool, returnToAvailability: bool, returnToService: bool, serviceLabel: string, showBusinessLogo: bool, showOnSchedLogo: bool, showServiceGroups: bool>, timezoneIana: string, timezoneId: string, timezoneOffset: int, travel: record<distance: string, proximity: string, startAddress: string, startLat: string, startLon: string, units: string>, website: string>"
    get-setup-v1-locations-id-email-templates: "record<data: table<customized: bool, description: string, name: string, object: string, scope: string>, object: string, total: int, url: string>"
    post-setup-v1-locations-id-email-templates: "record<content: string, contentType: string, statusCode: int>"
    delete-setup-v1-locations-id-email-templates-master: "record<centerEmailContent: bool, centerEmailContentPanel: bool, centerEmailFooter: bool, contentBackgroundColor: string, contentColor: string, contentLinkColor: string, emailBackgroundColor: string, emailColor: string, emailLinkColor: string, footerFontSize: string, footerLogoHeight: string, footerLogoPadding: string, footerPanelEmailContact: bool, footerPanelPhoneContact: bool, footerPanelWebsiteContact: bool, headerLogoHeight: string, headerLogoPadding: string, panelBackgroundColor: string, panelColor: string, panelLinkColor: string, privacyPolicyLink: string, showContentPanel: bool, showFooterLogo: bool, showFooterPanel: bool, showHeaderLogo: bool, showHeaderPanel: bool, version: string>"
    get-setup-v1-locations-id-email-templates-master: "record<centerEmailContent: bool, centerEmailContentPanel: bool, centerEmailFooter: bool, contentBackgroundColor: string, contentColor: string, contentLinkColor: string, emailBackgroundColor: string, emailColor: string, emailLinkColor: string, footerFontSize: string, footerLogoHeight: string, footerLogoPadding: string, footerPanelEmailContact: bool, footerPanelPhoneContact: bool, footerPanelWebsiteContact: bool, headerLogoHeight: string, headerLogoPadding: string, panelBackgroundColor: string, panelColor: string, panelLinkColor: string, privacyPolicyLink: string, showContentPanel: bool, showFooterLogo: bool, showFooterPanel: bool, showHeaderLogo: bool, showHeaderPanel: bool, version: string>"
    post-setup-v1-locations-id-email-templates-master: "record<centerEmailContent: bool, centerEmailContentPanel: bool, centerEmailFooter: bool, contentBackgroundColor: string, contentColor: string, contentLinkColor: string, emailBackgroundColor: string, emailColor: string, emailLinkColor: string, footerFontSize: string, footerLogoHeight: string, footerLogoPadding: string, footerPanelEmailContact: bool, footerPanelPhoneContact: bool, footerPanelWebsiteContact: bool, headerLogoHeight: string, headerLogoPadding: string, panelBackgroundColor: string, panelColor: string, panelLinkColor: string, privacyPolicyLink: string, showContentPanel: bool, showFooterLogo: bool, showFooterPanel: bool, showHeaderLogo: bool, showHeaderPanel: bool, version: string>"
    delete-setup-v1-locations-id-email-templates-template-name: "record<content: string, contentType: string, statusCode: int>"
    get-setup-v1-locations-id-email-templates-template-name: "record<content: string, contentType: string, statusCode: int>"
    post-setup-v1-locations-id-google-service-account: "record<auth_provider_x509_cert_url: string, auth_uri: string, client_email: string, client_id: string, client_x509_cert_url: string, private_key: string, private_key_id: string, project_id: string, token_uri: string, type: string>"
    put-setup-v1-locations-id-holidays-holiday-id-closed: "record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, adminEmail: string, adminName: string, appointmentReminders: record<emailFirstReminder: int, emailFirstReminderInterval: int, emailSecondReminder: int, emailSecondReminderInterval: int, smsFirstReminder: int, smsFirstReminderInterval: int, smsSecondReminder: int, smsSecondReminderInterval: int>, businessHolidays: table<businessClosed: bool, holidayName: string, id: string, publicHolidayId: int>, businessHours: record<fri: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, mon: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sat: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sun: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, thu: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, tue: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, wed: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>>, companyId: string, companyName: string, defaults: record<autoUpdateCustomer: bool, businessNotification: bool, customerCity: bool, customerState: bool, emailInfo: bool, enableUtcTimezone: bool, object: string>, email: string, fax: string, friendlyId: string, id: string, imageUrl: string, latitude: float, logo: string, longitude: float, name: string, object: string, phone: string, primaryBusiness: bool, primaryCalendarId: string, regionId: string, services: table<id: int, object: string, serviceId: int, serviceName: string>, settings: record<availabilityForm: int, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookWithAccount: bool, bookingConfirmationMessage: string, bookingMessage: string, bookingPolicy: string, bookingTimerMins: int, businessId: string, companyId: string, customerBookingsPerDay: int, customerVerification: bool, defaultService: bool, defaultToCustomerTimezone: bool, disableAuthorization: bool, enableWorldTimezones: bool, enabled: bool, familyMembersEnabled: bool, firstAvailable: bool, formFlow: int, hideBreadCrumbNav: bool, hideContinueBooking: bool, hideLocationNav: bool, hideNavBar: bool, hideServiceGroupsNav: bool, hideServicesNav: bool, id: int, lateCancelAction: int, lateCancelHours: int, lateRescheduleAction: int, lateRescheduleHours: int, liveMode: bool, locationId: string, object: string, resourceAnyLabel: string, resourceLabel: string, resourceSelection: bool, returnToAvailability: bool, returnToService: bool, serviceLabel: string, showBusinessLogo: bool, showOnSchedLogo: bool, showServiceGroups: bool>, timezoneIana: string, timezoneId: string, timezoneOffset: int, travel: record<distance: string, proximity: string, startAddress: string, startLat: string, startLon: string, units: string>, website: string>"
    put-setup-v1-locations-id-recover: "record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, adminEmail: string, adminName: string, appointmentReminders: record<emailFirstReminder: int, emailFirstReminderInterval: int, emailSecondReminder: int, emailSecondReminderInterval: int, smsFirstReminder: int, smsFirstReminderInterval: int, smsSecondReminder: int, smsSecondReminderInterval: int>, businessHolidays: table<businessClosed: bool, holidayName: string, id: string, publicHolidayId: int>, businessHours: record<fri: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, mon: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sat: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sun: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, thu: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, tue: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, wed: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>>, companyId: string, companyName: string, defaults: record<autoUpdateCustomer: bool, businessNotification: bool, customerCity: bool, customerState: bool, emailInfo: bool, enableUtcTimezone: bool, object: string>, email: string, fax: string, friendlyId: string, id: string, imageUrl: string, latitude: float, logo: string, longitude: float, name: string, object: string, phone: string, primaryBusiness: bool, primaryCalendarId: string, regionId: string, services: table<id: int, object: string, serviceId: int, serviceName: string>, settings: record<availabilityForm: int, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookWithAccount: bool, bookingConfirmationMessage: string, bookingMessage: string, bookingPolicy: string, bookingTimerMins: int, businessId: string, companyId: string, customerBookingsPerDay: int, customerVerification: bool, defaultService: bool, defaultToCustomerTimezone: bool, disableAuthorization: bool, enableWorldTimezones: bool, enabled: bool, familyMembersEnabled: bool, firstAvailable: bool, formFlow: int, hideBreadCrumbNav: bool, hideContinueBooking: bool, hideLocationNav: bool, hideNavBar: bool, hideServiceGroupsNav: bool, hideServicesNav: bool, id: int, lateCancelAction: int, lateCancelHours: int, lateRescheduleAction: int, lateRescheduleHours: int, liveMode: bool, locationId: string, object: string, resourceAnyLabel: string, resourceLabel: string, resourceSelection: bool, returnToAvailability: bool, returnToService: bool, serviceLabel: string, showBusinessLogo: bool, showOnSchedLogo: bool, showServiceGroups: bool>, timezoneIana: string, timezoneId: string, timezoneOffset: int, travel: record<distance: string, proximity: string, startAddress: string, startLat: string, startLon: string, units: string>, website: string>"
    delete-setup-v1-locations-id-services: "record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, adminEmail: string, adminName: string, appointmentReminders: record<emailFirstReminder: int, emailFirstReminderInterval: int, emailSecondReminder: int, emailSecondReminderInterval: int, smsFirstReminder: int, smsFirstReminderInterval: int, smsSecondReminder: int, smsSecondReminderInterval: int>, businessHolidays: table<businessClosed: bool, holidayName: string, id: string, publicHolidayId: int>, businessHours: record<fri: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, mon: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sat: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sun: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, thu: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, tue: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, wed: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>>, companyId: string, companyName: string, defaults: record<autoUpdateCustomer: bool, businessNotification: bool, customerCity: bool, customerState: bool, emailInfo: bool, enableUtcTimezone: bool, object: string>, email: string, fax: string, friendlyId: string, id: string, imageUrl: string, latitude: float, logo: string, longitude: float, name: string, object: string, phone: string, primaryBusiness: bool, primaryCalendarId: string, regionId: string, services: table<id: int, object: string, serviceId: int, serviceName: string>, settings: record<availabilityForm: int, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookWithAccount: bool, bookingConfirmationMessage: string, bookingMessage: string, bookingPolicy: string, bookingTimerMins: int, businessId: string, companyId: string, customerBookingsPerDay: int, customerVerification: bool, defaultService: bool, defaultToCustomerTimezone: bool, disableAuthorization: bool, enableWorldTimezones: bool, enabled: bool, familyMembersEnabled: bool, firstAvailable: bool, formFlow: int, hideBreadCrumbNav: bool, hideContinueBooking: bool, hideLocationNav: bool, hideNavBar: bool, hideServiceGroupsNav: bool, hideServicesNav: bool, id: int, lateCancelAction: int, lateCancelHours: int, lateRescheduleAction: int, lateRescheduleHours: int, liveMode: bool, locationId: string, object: string, resourceAnyLabel: string, resourceLabel: string, resourceSelection: bool, returnToAvailability: bool, returnToService: bool, serviceLabel: string, showBusinessLogo: bool, showOnSchedLogo: bool, showServiceGroups: bool>, timezoneIana: string, timezoneId: string, timezoneOffset: int, travel: record<distance: string, proximity: string, startAddress: string, startLat: string, startLon: string, units: string>, website: string>"
    get-setup-v1-locations-id-services: "record<count: int, data: table<id: int, object: string, serviceId: int, serviceName: string>, hasMore: bool, object: string, total: int, url: string>"
    post-setup-v1-locations-id-services: "record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, adminEmail: string, adminName: string, appointmentReminders: record<emailFirstReminder: int, emailFirstReminderInterval: int, emailSecondReminder: int, emailSecondReminderInterval: int, smsFirstReminder: int, smsFirstReminderInterval: int, smsSecondReminder: int, smsSecondReminderInterval: int>, businessHolidays: table<businessClosed: bool, holidayName: string, id: string, publicHolidayId: int>, businessHours: record<fri: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, mon: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sat: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sun: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, thu: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, tue: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, wed: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>>, companyId: string, companyName: string, defaults: record<autoUpdateCustomer: bool, businessNotification: bool, customerCity: bool, customerState: bool, emailInfo: bool, enableUtcTimezone: bool, object: string>, email: string, fax: string, friendlyId: string, id: string, imageUrl: string, latitude: float, logo: string, longitude: float, name: string, object: string, phone: string, primaryBusiness: bool, primaryCalendarId: string, regionId: string, services: table<id: int, object: string, serviceId: int, serviceName: string>, settings: record<availabilityForm: int, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookWithAccount: bool, bookingConfirmationMessage: string, bookingMessage: string, bookingPolicy: string, bookingTimerMins: int, businessId: string, companyId: string, customerBookingsPerDay: int, customerVerification: bool, defaultService: bool, defaultToCustomerTimezone: bool, disableAuthorization: bool, enableWorldTimezones: bool, enabled: bool, familyMembersEnabled: bool, firstAvailable: bool, formFlow: int, hideBreadCrumbNav: bool, hideContinueBooking: bool, hideLocationNav: bool, hideNavBar: bool, hideServiceGroupsNav: bool, hideServicesNav: bool, id: int, lateCancelAction: int, lateCancelHours: int, lateRescheduleAction: int, lateRescheduleHours: int, liveMode: bool, locationId: string, object: string, resourceAnyLabel: string, resourceLabel: string, resourceSelection: bool, returnToAvailability: bool, returnToService: bool, serviceLabel: string, showBusinessLogo: bool, showOnSchedLogo: bool, showServiceGroups: bool>, timezoneIana: string, timezoneId: string, timezoneOffset: int, travel: record<distance: string, proximity: string, startAddress: string, startLat: string, startLon: string, units: string>, website: string>"
    put-setup-v1-locations-id-settings-scope-settings-scope: "record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, adminEmail: string, adminName: string, appointmentReminders: record<emailFirstReminder: int, emailFirstReminderInterval: int, emailSecondReminder: int, emailSecondReminderInterval: int, smsFirstReminder: int, smsFirstReminderInterval: int, smsSecondReminder: int, smsSecondReminderInterval: int>, businessHolidays: table<businessClosed: bool, holidayName: string, id: string, publicHolidayId: int>, businessHours: record<fri: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, mon: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sat: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sun: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, thu: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, tue: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, wed: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>>, companyId: string, companyName: string, defaults: record<autoUpdateCustomer: bool, businessNotification: bool, customerCity: bool, customerState: bool, emailInfo: bool, enableUtcTimezone: bool, object: string>, email: string, fax: string, friendlyId: string, id: string, imageUrl: string, latitude: float, logo: string, longitude: float, name: string, object: string, phone: string, primaryBusiness: bool, primaryCalendarId: string, regionId: string, services: table<id: int, object: string, serviceId: int, serviceName: string>, settings: record<availabilityForm: int, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookWithAccount: bool, bookingConfirmationMessage: string, bookingMessage: string, bookingPolicy: string, bookingTimerMins: int, businessId: string, companyId: string, customerBookingsPerDay: int, customerVerification: bool, defaultService: bool, defaultToCustomerTimezone: bool, disableAuthorization: bool, enableWorldTimezones: bool, enabled: bool, familyMembersEnabled: bool, firstAvailable: bool, formFlow: int, hideBreadCrumbNav: bool, hideContinueBooking: bool, hideLocationNav: bool, hideNavBar: bool, hideServiceGroupsNav: bool, hideServicesNav: bool, id: int, lateCancelAction: int, lateCancelHours: int, lateRescheduleAction: int, lateRescheduleHours: int, liveMode: bool, locationId: string, object: string, resourceAnyLabel: string, resourceLabel: string, resourceSelection: bool, returnToAvailability: bool, returnToService: bool, serviceLabel: string, showBusinessLogo: bool, showOnSchedLogo: bool, showServiceGroups: bool>, timezoneIana: string, timezoneId: string, timezoneOffset: int, travel: record<distance: string, proximity: string, startAddress: string, startLat: string, startLon: string, units: string>, website: string>"
    post-setup-v1-locations-id-uploadimage: "record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, adminEmail: string, adminName: string, appointmentReminders: record<emailFirstReminder: int, emailFirstReminderInterval: int, emailSecondReminder: int, emailSecondReminderInterval: int, smsFirstReminder: int, smsFirstReminderInterval: int, smsSecondReminder: int, smsSecondReminderInterval: int>, businessHolidays: table<businessClosed: bool, holidayName: string, id: string, publicHolidayId: int>, businessHours: record<fri: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, mon: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sat: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sun: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, thu: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, tue: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, wed: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>>, companyId: string, companyName: string, defaults: record<autoUpdateCustomer: bool, businessNotification: bool, customerCity: bool, customerState: bool, emailInfo: bool, enableUtcTimezone: bool, object: string>, email: string, fax: string, friendlyId: string, id: string, imageUrl: string, latitude: float, logo: string, longitude: float, name: string, object: string, phone: string, primaryBusiness: bool, primaryCalendarId: string, regionId: string, services: table<id: int, object: string, serviceId: int, serviceName: string>, settings: record<availabilityForm: int, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookWithAccount: bool, bookingConfirmationMessage: string, bookingMessage: string, bookingPolicy: string, bookingTimerMins: int, businessId: string, companyId: string, customerBookingsPerDay: int, customerVerification: bool, defaultService: bool, defaultToCustomerTimezone: bool, disableAuthorization: bool, enableWorldTimezones: bool, enabled: bool, familyMembersEnabled: bool, firstAvailable: bool, formFlow: int, hideBreadCrumbNav: bool, hideContinueBooking: bool, hideLocationNav: bool, hideNavBar: bool, hideServiceGroupsNav: bool, hideServicesNav: bool, id: int, lateCancelAction: int, lateCancelHours: int, lateRescheduleAction: int, lateRescheduleHours: int, liveMode: bool, locationId: string, object: string, resourceAnyLabel: string, resourceLabel: string, resourceSelection: bool, returnToAvailability: bool, returnToService: bool, serviceLabel: string, showBusinessLogo: bool, showOnSchedLogo: bool, showServiceGroups: bool>, timezoneIana: string, timezoneId: string, timezoneOffset: int, travel: record<distance: string, proximity: string, startAddress: string, startLat: string, startLon: string, units: string>, website: string>"
    get-setup-v1-resourcegroups: "record<count: int, data: table<bookingNotification: int, deletedStatus: bool, deletedTime: string, description: string, email: string, id: string, locationId: string, name: string, object: string>, hasMore: bool, object: string, total: int, url: string>"
    post-setup-v1-resourcegroups: "record<bookingNotification: int, deletedStatus: bool, deletedTime: string, description: string, email: string, id: string, locationId: string, name: string, object: string>"
    delete-setup-v1-resourcegroups-id: "record<bookingNotification: int, deletedStatus: bool, deletedTime: string, description: string, email: string, id: string, locationId: string, name: string, object: string>"
    get-setup-v1-resourcegroups-id: "record<bookingNotification: int, deletedStatus: bool, deletedTime: string, description: string, email: string, id: string, locationId: string, name: string, object: string>"
    put-setup-v1-resourcegroups-id: "record<bookingNotification: int, deletedStatus: bool, deletedTime: string, description: string, email: string, id: string, locationId: string, name: string, object: string>"
    put-setup-v1-resourcegroups-id-recover: "record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bioLink: string, bookingNotification: int, calendarAvailability: int, contact: record<businessPhone: string, businessPhoneExt: string, conferenceInfo: string, homePhone: string, mobilePhone: string, phoneType: string, skypeUsername: string>, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, deletedStatus: bool, deletedTime: string, description: string, effectiveDate: string, email: string, gender: string, googleCalendarAuthUrl: string, googleCalendarAuthorized: bool, googleCalendarId: string, groupId: int, hourly: float, id: string, ignoreBusinessHours: bool, imageUrl: string, locationId: string, name: string, notificationType: int, object: string, options: record<bioLink: string, bookingNotification: int, calendarAvailability: int, displayColor: string, effectiveDate: string, gender: string, googleCalendarId: string, hourly: float, ignoreBusinessHours: bool, notificationType: int, outlookCalendarId: string, sortKey: int>, outlookCalendarAuthUrl: string, outlookCalendarAuthorized: bool, outlookCalendarId: string, phone: record<businessPhone: string, businessPhoneExt: string, homePhone: string, mobilePhone: string, phoneType: string>, recurringAvailability: bool, services: table<object: string, serviceId: int, serviceName: string>, skypeName: string, sortKey: int, timezoneIana: string, timezoneId: string, timezoneOffset: int>"
    get-setup-v1-resources: "record<count: int, data: table<address: record, availability: record, bioLink: string, bookingNotification: int, calendarAvailability: int, contact: record, customFields: record, deletedStatus: bool, deletedTime: string, description: string, effectiveDate: string, email: string, gender: string, googleCalendarAuthUrl: string, googleCalendarAuthorized: bool, googleCalendarId: string, groupId: int, hourly: float, id: string, ignoreBusinessHours: bool, imageUrl: string, locationId: string, name: string, notificationType: int, object: string, options: record, outlookCalendarAuthUrl: string, outlookCalendarAuthorized: bool, outlookCalendarId: string, phone: record, recurringAvailability: bool, services: list, skypeName: string, sortKey: int, timezoneIana: string, timezoneId: string, timezoneOffset: int>, hasMore: bool, object: string, total: int, url: string>"
    post-setup-v1-resources: "record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bioLink: string, bookingNotification: int, calendarAvailability: int, contact: record<businessPhone: string, businessPhoneExt: string, conferenceInfo: string, homePhone: string, mobilePhone: string, phoneType: string, skypeUsername: string>, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, deletedStatus: bool, deletedTime: string, description: string, effectiveDate: string, email: string, gender: string, googleCalendarAuthUrl: string, googleCalendarAuthorized: bool, googleCalendarId: string, groupId: int, hourly: float, id: string, ignoreBusinessHours: bool, imageUrl: string, locationId: string, name: string, notificationType: int, object: string, options: record<bioLink: string, bookingNotification: int, calendarAvailability: int, displayColor: string, effectiveDate: string, gender: string, googleCalendarId: string, hourly: float, ignoreBusinessHours: bool, notificationType: int, outlookCalendarId: string, sortKey: int>, outlookCalendarAuthUrl: string, outlookCalendarAuthorized: bool, outlookCalendarId: string, phone: record<businessPhone: string, businessPhoneExt: string, homePhone: string, mobilePhone: string, phoneType: string>, recurringAvailability: bool, services: table<object: string, serviceId: int, serviceName: string>, skypeName: string, sortKey: int, timezoneIana: string, timezoneId: string, timezoneOffset: int>"
    delete-setup-v1-resources-allocations-id: "record<businessId: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: int, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, resourceId: int, startDate: string, startTime: int>"
    get-setup-v1-resources-allocations-id: "record<businessId: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: int, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, resourceId: int, startDate: string, startTime: int>"
    put-setup-v1-resources-allocations-id: "record<businessId: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: int, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, resourceId: int, startDate: string, startTime: int>"
    delete-setup-v1-resources-block-id: "record<businessId: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: int, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, resourceId: int, startDate: string, startTime: int>"
    put-setup-v1-resources-block-id: "record<businessId: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: int, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, resourceId: int, startDate: string, startTime: int>"
    get-setup-v1-resources-blocks-id: "record<businessId: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: int, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, resourceId: int, startDate: string, startTime: int>"
    post-setup-v1-resources-bulk: "table<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, availability: record<fri: record, mon: record, sat: record, sun: record, thu: record, tue: record, wed: record>, bioLink: string, bookingNotification: int, calendarAvailability: int, contact: record<businessPhone: string, businessPhoneExt: string, conferenceInfo: string, homePhone: string, mobilePhone: string, phoneType: string, skypeUsername: string>, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, deletedStatus: bool, deletedTime: string, description: string, effectiveDate: string, email: string, gender: string, googleCalendarAuthUrl: string, googleCalendarAuthorized: bool, googleCalendarId: string, groupId: int, hourly: float, id: string, ignoreBusinessHours: bool, imageUrl: string, locationId: string, name: string, notificationType: int, object: string, options: record<bioLink: string, bookingNotification: int, calendarAvailability: int, displayColor: string, effectiveDate: string, gender: string, googleCalendarId: string, hourly: float, ignoreBusinessHours: bool, notificationType: int, outlookCalendarId: string, sortKey: int>, outlookCalendarAuthUrl: string, outlookCalendarAuthorized: bool, outlookCalendarId: string, phone: record<businessPhone: string, businessPhoneExt: string, homePhone: string, mobilePhone: string, phoneType: string>, recurringAvailability: bool, services: list<record>, skypeName: string, sortKey: int, timezoneIana: string, timezoneId: string, timezoneOffset: int>"
    put-setup-v1-resources-bulk: "table<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, availability: record<fri: record, mon: record, sat: record, sun: record, thu: record, tue: record, wed: record>, bioLink: string, bookingNotification: int, calendarAvailability: int, contact: record<businessPhone: string, businessPhoneExt: string, conferenceInfo: string, homePhone: string, mobilePhone: string, phoneType: string, skypeUsername: string>, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, deletedStatus: bool, deletedTime: string, description: string, effectiveDate: string, email: string, gender: string, googleCalendarAuthUrl: string, googleCalendarAuthorized: bool, googleCalendarId: string, groupId: int, hourly: float, id: string, ignoreBusinessHours: bool, imageUrl: string, locationId: string, name: string, notificationType: int, object: string, options: record<bioLink: string, bookingNotification: int, calendarAvailability: int, displayColor: string, effectiveDate: string, gender: string, googleCalendarId: string, hourly: float, ignoreBusinessHours: bool, notificationType: int, outlookCalendarId: string, sortKey: int>, outlookCalendarAuthUrl: string, outlookCalendarAuthorized: bool, outlookCalendarId: string, phone: record<businessPhone: string, businessPhoneExt: string, homePhone: string, mobilePhone: string, phoneType: string>, recurringAvailability: bool, services: list<record>, skypeName: string, sortKey: int, timezoneIana: string, timezoneId: string, timezoneOffset: int>"
    get-setup-v1-resources-timezones: "record<baseUtcOffset: int, daylightName: string, displayName: string, standardName: string, supportsDaylightSavingTime: bool, timezoneIana: string, timezoneId: string>"
    delete-setup-v1-resources-id: "record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bioLink: string, bookingNotification: int, calendarAvailability: int, contact: record<businessPhone: string, businessPhoneExt: string, conferenceInfo: string, homePhone: string, mobilePhone: string, phoneType: string, skypeUsername: string>, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, deletedStatus: bool, deletedTime: string, description: string, effectiveDate: string, email: string, gender: string, googleCalendarAuthUrl: string, googleCalendarAuthorized: bool, googleCalendarId: string, groupId: int, hourly: float, id: string, ignoreBusinessHours: bool, imageUrl: string, locationId: string, name: string, notificationType: int, object: string, options: record<bioLink: string, bookingNotification: int, calendarAvailability: int, displayColor: string, effectiveDate: string, gender: string, googleCalendarId: string, hourly: float, ignoreBusinessHours: bool, notificationType: int, outlookCalendarId: string, sortKey: int>, outlookCalendarAuthUrl: string, outlookCalendarAuthorized: bool, outlookCalendarId: string, phone: record<businessPhone: string, businessPhoneExt: string, homePhone: string, mobilePhone: string, phoneType: string>, recurringAvailability: bool, services: table<object: string, serviceId: int, serviceName: string>, skypeName: string, sortKey: int, timezoneIana: string, timezoneId: string, timezoneOffset: int>"
    get-setup-v1-resources-id: "record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bioLink: string, bookingNotification: int, calendarAvailability: int, contact: record<businessPhone: string, businessPhoneExt: string, conferenceInfo: string, homePhone: string, mobilePhone: string, phoneType: string, skypeUsername: string>, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, deletedStatus: bool, deletedTime: string, description: string, effectiveDate: string, email: string, gender: string, googleCalendarAuthUrl: string, googleCalendarAuthorized: bool, googleCalendarId: string, groupId: int, hourly: float, id: string, ignoreBusinessHours: bool, imageUrl: string, locationId: string, name: string, notificationType: int, object: string, options: record<bioLink: string, bookingNotification: int, calendarAvailability: int, displayColor: string, effectiveDate: string, gender: string, googleCalendarId: string, hourly: float, ignoreBusinessHours: bool, notificationType: int, outlookCalendarId: string, sortKey: int>, outlookCalendarAuthUrl: string, outlookCalendarAuthorized: bool, outlookCalendarId: string, phone: record<businessPhone: string, businessPhoneExt: string, homePhone: string, mobilePhone: string, phoneType: string>, recurringAvailability: bool, services: table<object: string, serviceId: int, serviceName: string>, skypeName: string, sortKey: int, timezoneIana: string, timezoneId: string, timezoneOffset: int>"
    put-setup-v1-resources-id: "record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bioLink: string, bookingNotification: int, calendarAvailability: int, contact: record<businessPhone: string, businessPhoneExt: string, conferenceInfo: string, homePhone: string, mobilePhone: string, phoneType: string, skypeUsername: string>, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, deletedStatus: bool, deletedTime: string, description: string, effectiveDate: string, email: string, gender: string, googleCalendarAuthUrl: string, googleCalendarAuthorized: bool, googleCalendarId: string, groupId: int, hourly: float, id: string, ignoreBusinessHours: bool, imageUrl: string, locationId: string, name: string, notificationType: int, object: string, options: record<bioLink: string, bookingNotification: int, calendarAvailability: int, displayColor: string, effectiveDate: string, gender: string, googleCalendarId: string, hourly: float, ignoreBusinessHours: bool, notificationType: int, outlookCalendarId: string, sortKey: int>, outlookCalendarAuthUrl: string, outlookCalendarAuthorized: bool, outlookCalendarId: string, phone: record<businessPhone: string, businessPhoneExt: string, homePhone: string, mobilePhone: string, phoneType: string>, recurringAvailability: bool, services: table<object: string, serviceId: int, serviceName: string>, skypeName: string, sortKey: int, timezoneIana: string, timezoneId: string, timezoneOffset: int>"
    get-setup-v1-resources-id-allocations: "record<count: int, data: table<businessId: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: int, object: string, reason: string, repeat: record, repeats: bool, resourceId: int, startDate: string, startTime: int>, hasMore: bool, object: string, total: int, url: string>"
    post-setup-v1-resources-id-allocations: "record<businessId: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: int, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, resourceId: int, startDate: string, startTime: int>"
    get-setup-v1-resources-id-availability: "record<businessId: int, ignoreBusinessHours: bool, resourceId: int, resourceName: string, resourceTzo: int, weekdays: record<fri: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, mon: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, sat: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, sun: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, thu: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, tue: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, wed: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>>>"
    put-setup-v1-resources-id-availability: "record<businessId: int, ignoreBusinessHours: bool, resourceId: int, resourceName: string, resourceTzo: int, weekdays: record<fri: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, mon: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, sat: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, sun: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, thu: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, tue: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, wed: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>>>"
    post-setup-v1-resources-id-block: "record<businessId: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: int, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, resourceId: int, startDate: string, startTime: int>"
    get-setup-v1-resources-id-blocks: "record<count: int, data: table<businessId: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: int, object: string, reason: string, repeat: record, repeats: bool, resourceId: int, startDate: string, startTime: int>, hasMore: bool, object: string, total: int, url: string>"
    get-setup-v1-resources-id-calendar-auth-google-google-email-address: "record<calendarAuthUrl: string, calendarId: string, object: string>"
    get-setup-v1-resources-id-calendar-auth-outlook-outlook-email-address: "record<calendarAuthUrl: string, calendarId: string, object: string>"
    delete-setup-v1-resources-id-deleteimage: "record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bioLink: string, bookingNotification: int, calendarAvailability: int, contact: record<businessPhone: string, businessPhoneExt: string, conferenceInfo: string, homePhone: string, mobilePhone: string, phoneType: string, skypeUsername: string>, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, deletedStatus: bool, deletedTime: string, description: string, effectiveDate: string, email: string, gender: string, googleCalendarAuthUrl: string, googleCalendarAuthorized: bool, googleCalendarId: string, groupId: int, hourly: float, id: string, ignoreBusinessHours: bool, imageUrl: string, locationId: string, name: string, notificationType: int, object: string, options: record<bioLink: string, bookingNotification: int, calendarAvailability: int, displayColor: string, effectiveDate: string, gender: string, googleCalendarId: string, hourly: float, ignoreBusinessHours: bool, notificationType: int, outlookCalendarId: string, sortKey: int>, outlookCalendarAuthUrl: string, outlookCalendarAuthorized: bool, outlookCalendarId: string, phone: record<businessPhone: string, businessPhoneExt: string, homePhone: string, mobilePhone: string, phoneType: string>, recurringAvailability: bool, services: table<object: string, serviceId: int, serviceName: string>, skypeName: string, sortKey: int, timezoneIana: string, timezoneId: string, timezoneOffset: int>"
    put-setup-v1-resources-id-reassign-appointments-resource-id: "table<auditTrail: list<record>, bookedBy: string, businessName: string, calendarId: string, confirmationNumber: string, confirmed: bool, createDate: string, customFields: record, customerId: string, customerMessage: string, customers: list<record>, date: string, dateInternational: string, downloadIcsUrl: string, duration: int, email: string, emailConfirmationSent: string, emailReminderSent: string, endDateTime: string, firstname: string, groupSize: int, id: string, ipAddress: string, lastModifiedBy: string, lastModifiedOn: string, lastname: string, latitude: string, location: string, locationId: string, longitude: string, name: string, notes: string, object: string, onlineBooking: bool, paymentStatus: int, phone: string, phoneExt: string, phoneType: string, rescheduledId: string, resourceEmail: string, resourceGroupId: string, resourceGroupName: string, resourceId: string, resourceImageUrl: string, resourceName: string, resources: list<record>, serviceAllocationId: string, serviceId: string, serviceImageUrl: string, serviceName: string, smsConfirmationSent: string, smsReminderSent: string, startDateTime: string, status: string, stripeChargeId: string, stripeRefundId: string, time: int, timezone: int, timezoneIana: string, timezoneId: string>"
    put-setup-v1-resources-id-recover: "record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bioLink: string, bookingNotification: int, calendarAvailability: int, contact: record<businessPhone: string, businessPhoneExt: string, conferenceInfo: string, homePhone: string, mobilePhone: string, phoneType: string, skypeUsername: string>, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, deletedStatus: bool, deletedTime: string, description: string, effectiveDate: string, email: string, gender: string, googleCalendarAuthUrl: string, googleCalendarAuthorized: bool, googleCalendarId: string, groupId: int, hourly: float, id: string, ignoreBusinessHours: bool, imageUrl: string, locationId: string, name: string, notificationType: int, object: string, options: record<bioLink: string, bookingNotification: int, calendarAvailability: int, displayColor: string, effectiveDate: string, gender: string, googleCalendarId: string, hourly: float, ignoreBusinessHours: bool, notificationType: int, outlookCalendarId: string, sortKey: int>, outlookCalendarAuthUrl: string, outlookCalendarAuthorized: bool, outlookCalendarId: string, phone: record<businessPhone: string, businessPhoneExt: string, homePhone: string, mobilePhone: string, phoneType: string>, recurringAvailability: bool, services: table<object: string, serviceId: int, serviceName: string>, skypeName: string, sortKey: int, timezoneIana: string, timezoneId: string, timezoneOffset: int>"
    delete-setup-v1-resources-id-services: "record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bioLink: string, bookingNotification: int, calendarAvailability: int, contact: record<businessPhone: string, businessPhoneExt: string, conferenceInfo: string, homePhone: string, mobilePhone: string, phoneType: string, skypeUsername: string>, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, deletedStatus: bool, deletedTime: string, description: string, effectiveDate: string, email: string, gender: string, googleCalendarAuthUrl: string, googleCalendarAuthorized: bool, googleCalendarId: string, groupId: int, hourly: float, id: string, ignoreBusinessHours: bool, imageUrl: string, locationId: string, name: string, notificationType: int, object: string, options: record<bioLink: string, bookingNotification: int, calendarAvailability: int, displayColor: string, effectiveDate: string, gender: string, googleCalendarId: string, hourly: float, ignoreBusinessHours: bool, notificationType: int, outlookCalendarId: string, sortKey: int>, outlookCalendarAuthUrl: string, outlookCalendarAuthorized: bool, outlookCalendarId: string, phone: record<businessPhone: string, businessPhoneExt: string, homePhone: string, mobilePhone: string, phoneType: string>, recurringAvailability: bool, services: table<object: string, serviceId: int, serviceName: string>, skypeName: string, sortKey: int, timezoneIana: string, timezoneId: string, timezoneOffset: int>"
    post-setup-v1-resources-id-services: "record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bioLink: string, bookingNotification: int, calendarAvailability: int, contact: record<businessPhone: string, businessPhoneExt: string, conferenceInfo: string, homePhone: string, mobilePhone: string, phoneType: string, skypeUsername: string>, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, deletedStatus: bool, deletedTime: string, description: string, effectiveDate: string, email: string, gender: string, googleCalendarAuthUrl: string, googleCalendarAuthorized: bool, googleCalendarId: string, groupId: int, hourly: float, id: string, ignoreBusinessHours: bool, imageUrl: string, locationId: string, name: string, notificationType: int, object: string, options: record<bioLink: string, bookingNotification: int, calendarAvailability: int, displayColor: string, effectiveDate: string, gender: string, googleCalendarId: string, hourly: float, ignoreBusinessHours: bool, notificationType: int, outlookCalendarId: string, sortKey: int>, outlookCalendarAuthUrl: string, outlookCalendarAuthorized: bool, outlookCalendarId: string, phone: record<businessPhone: string, businessPhoneExt: string, homePhone: string, mobilePhone: string, phoneType: string>, recurringAvailability: bool, services: table<object: string, serviceId: int, serviceName: string>, skypeName: string, sortKey: int, timezoneIana: string, timezoneId: string, timezoneOffset: int>"
    put-setup-v1-resources-id-services: "record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bioLink: string, bookingNotification: int, calendarAvailability: int, contact: record<businessPhone: string, businessPhoneExt: string, conferenceInfo: string, homePhone: string, mobilePhone: string, phoneType: string, skypeUsername: string>, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, deletedStatus: bool, deletedTime: string, description: string, effectiveDate: string, email: string, gender: string, googleCalendarAuthUrl: string, googleCalendarAuthorized: bool, googleCalendarId: string, groupId: int, hourly: float, id: string, ignoreBusinessHours: bool, imageUrl: string, locationId: string, name: string, notificationType: int, object: string, options: record<bioLink: string, bookingNotification: int, calendarAvailability: int, displayColor: string, effectiveDate: string, gender: string, googleCalendarId: string, hourly: float, ignoreBusinessHours: bool, notificationType: int, outlookCalendarId: string, sortKey: int>, outlookCalendarAuthUrl: string, outlookCalendarAuthorized: bool, outlookCalendarId: string, phone: record<businessPhone: string, businessPhoneExt: string, homePhone: string, mobilePhone: string, phoneType: string>, recurringAvailability: bool, services: table<object: string, serviceId: int, serviceName: string>, skypeName: string, sortKey: int, timezoneIana: string, timezoneId: string, timezoneOffset: int>"
    post-setup-v1-resources-id-uploadimage: "record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bioLink: string, bookingNotification: int, calendarAvailability: int, contact: record<businessPhone: string, businessPhoneExt: string, conferenceInfo: string, homePhone: string, mobilePhone: string, phoneType: string, skypeUsername: string>, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, deletedStatus: bool, deletedTime: string, description: string, effectiveDate: string, email: string, gender: string, googleCalendarAuthUrl: string, googleCalendarAuthorized: bool, googleCalendarId: string, groupId: int, hourly: float, id: string, ignoreBusinessHours: bool, imageUrl: string, locationId: string, name: string, notificationType: int, object: string, options: record<bioLink: string, bookingNotification: int, calendarAvailability: int, displayColor: string, effectiveDate: string, gender: string, googleCalendarId: string, hourly: float, ignoreBusinessHours: bool, notificationType: int, outlookCalendarId: string, sortKey: int>, outlookCalendarAuthUrl: string, outlookCalendarAuthorized: bool, outlookCalendarId: string, phone: record<businessPhone: string, businessPhoneExt: string, homePhone: string, mobilePhone: string, phoneType: string>, recurringAvailability: bool, services: table<object: string, serviceId: int, serviceName: string>, skypeName: string, sortKey: int, timezoneIana: string, timezoneId: string, timezoneOffset: int>"
    get-setup-v1-servicegroups: "record<count: int, data: table<companyId: string, description: string, id: string, imageUrl: string, isDeleted: bool, locationId: string, name: string, object: string, type: int>, hasMore: bool, object: string, total: int, url: string>"
    post-setup-v1-servicegroups: "record<companyId: string, description: string, id: string, imageUrl: string, isDeleted: bool, locationId: string, name: string, object: string, type: int>"
    delete-setup-v1-servicegroups-id: "record<companyId: string, description: string, id: string, imageUrl: string, isDeleted: bool, locationId: string, name: string, object: string, type: int>"
    get-setup-v1-servicegroups-id: "record<companyId: string, description: string, id: string, imageUrl: string, isDeleted: bool, locationId: string, name: string, object: string, type: int>"
    put-setup-v1-servicegroups-id: "record<companyId: string, description: string, id: string, imageUrl: string, isDeleted: bool, locationId: string, name: string, object: string, type: int>"
    put-setup-v1-servicegroups-id-recover: "record<companyId: string, description: string, id: string, imageUrl: string, isDeleted: bool, locationId: string, name: string, object: string, type: int>"
    get-setup-v1-services: "record<count: int, data: table<availability: record, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookingInterval: int, bookingLimit: int, calendarId: string, calendarResourceGroupId: string, cancellationFeeAmount: float, cancellationFeeTaxable: bool, companyId: string, consumerPadding: bool, customFields: record, dailyBookingLimitCount: int, dailyBookingLimitMinutes: int, defaultService: bool, description: string, duration: int, durationInterval: int, durationMax: int, durationMin: int, durationSelect: bool, feeAmount: float, feeTaxable: bool, id: string, imageUrl: string, locationId: string, maxBookingLimit: int, maxCapacity: int, maxGroupSize: int, maxResourceBookingLimit: int, mediaPageUrl: string, name: string, nonRefundable: bool, object: string, padding: int, roundRobin: int, serviceGroupId: int, serviceGroupName: string, showOnline: bool, type: string>, hasMore: bool, object: string, total: int, url: string>"
    post-setup-v1-services: "record<availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookingInterval: int, bookingLimit: int, calendarId: string, calendarResourceGroupId: string, cancellationFeeAmount: float, cancellationFeeTaxable: bool, companyId: string, consumerPadding: bool, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, dailyBookingLimitCount: int, dailyBookingLimitMinutes: int, defaultService: bool, description: string, duration: int, durationInterval: int, durationMax: int, durationMin: int, durationSelect: bool, feeAmount: float, feeTaxable: bool, id: string, imageUrl: string, locationId: string, maxBookingLimit: int, maxCapacity: int, maxGroupSize: int, maxResourceBookingLimit: int, mediaPageUrl: string, name: string, nonRefundable: bool, object: string, padding: int, roundRobin: int, serviceGroupId: int, serviceGroupName: string, showOnline: bool, type: string>"
    delete-setup-v1-services-allocations-id: "record<bookingCount: int, bookingLimit: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: string, locationId: string, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, resourceAddress: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, resourceDescription: string, resourceId: string, resourceImageUrl: string, resourceName: string, resourcePhone: record<businessPhone: string, businessPhoneExt: string, homePhone: string, mobilePhone: string, phoneType: string>, serviceDescription: string, serviceDuration: int, serviceId: string, serviceImageUrl: string, serviceName: string, startDate: string, startTime: int, timezoneName: string, timezoneOffset: int>"
    get-setup-v1-services-allocations-id: "record<bookingCount: int, bookingLimit: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: string, locationId: string, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, resourceAddress: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, resourceDescription: string, resourceId: string, resourceImageUrl: string, resourceName: string, resourcePhone: record<businessPhone: string, businessPhoneExt: string, homePhone: string, mobilePhone: string, phoneType: string>, serviceDescription: string, serviceDuration: int, serviceId: string, serviceImageUrl: string, serviceName: string, startDate: string, startTime: int, timezoneName: string, timezoneOffset: int>"
    put-setup-v1-services-allocations-id: "record<bookingCount: int, bookingLimit: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: string, locationId: string, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, resourceAddress: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, resourceDescription: string, resourceId: string, resourceImageUrl: string, resourceName: string, resourcePhone: record<businessPhone: string, businessPhoneExt: string, homePhone: string, mobilePhone: string, phoneType: string>, serviceDescription: string, serviceDuration: int, serviceId: string, serviceImageUrl: string, serviceName: string, startDate: string, startTime: int, timezoneName: string, timezoneOffset: int>"
    delete-setup-v1-services-block-id: "record<businessId: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: int, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, resourceId: int, startDate: string, startTime: int>"
    put-setup-v1-services-block-id: "record<deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: string, locationId: string, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, serviceId: string, startDate: string, startTime: int>"
    get-setup-v1-services-blocks-id: "record<businessId: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: int, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, resourceId: int, startDate: string, startTime: int>"
    post-setup-v1-services-calendar: "record<calendarId: string, calendarName: string, id: string, locationId: string, serviceId: string, serviceName: string>"
    delete-setup-v1-services-calendar-id: "record<calendarId: string, calendarName: string, id: string, locationId: string, serviceId: string, serviceName: string>"
    delete-setup-v1-services-id: "record<availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookingInterval: int, bookingLimit: int, calendarId: string, calendarResourceGroupId: string, cancellationFeeAmount: float, cancellationFeeTaxable: bool, companyId: string, consumerPadding: bool, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, dailyBookingLimitCount: int, dailyBookingLimitMinutes: int, defaultService: bool, description: string, duration: int, durationInterval: int, durationMax: int, durationMin: int, durationSelect: bool, feeAmount: float, feeTaxable: bool, id: string, imageUrl: string, locationId: string, maxBookingLimit: int, maxCapacity: int, maxGroupSize: int, maxResourceBookingLimit: int, mediaPageUrl: string, name: string, nonRefundable: bool, object: string, padding: int, roundRobin: int, serviceGroupId: int, serviceGroupName: string, showOnline: bool, type: string>"
    get-setup-v1-services-id: "record<availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookingInterval: int, bookingLimit: int, calendarId: string, calendarResourceGroupId: string, cancellationFeeAmount: float, cancellationFeeTaxable: bool, companyId: string, consumerPadding: bool, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, dailyBookingLimitCount: int, dailyBookingLimitMinutes: int, defaultService: bool, description: string, duration: int, durationInterval: int, durationMax: int, durationMin: int, durationSelect: bool, feeAmount: float, feeTaxable: bool, id: string, imageUrl: string, locationId: string, maxBookingLimit: int, maxCapacity: int, maxGroupSize: int, maxResourceBookingLimit: int, mediaPageUrl: string, name: string, nonRefundable: bool, object: string, padding: int, roundRobin: int, serviceGroupId: int, serviceGroupName: string, showOnline: bool, type: string>"
    put-setup-v1-services-id: "record<availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookingInterval: int, bookingLimit: int, calendarId: string, calendarResourceGroupId: string, cancellationFeeAmount: float, cancellationFeeTaxable: bool, companyId: string, consumerPadding: bool, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, dailyBookingLimitCount: int, dailyBookingLimitMinutes: int, defaultService: bool, description: string, duration: int, durationInterval: int, durationMax: int, durationMin: int, durationSelect: bool, feeAmount: float, feeTaxable: bool, id: string, imageUrl: string, locationId: string, maxBookingLimit: int, maxCapacity: int, maxGroupSize: int, maxResourceBookingLimit: int, mediaPageUrl: string, name: string, nonRefundable: bool, object: string, padding: int, roundRobin: int, serviceGroupId: int, serviceGroupName: string, showOnline: bool, type: string>"
    get-setup-v1-services-id-allocations: "record<count: int, data: table<bookingCount: int, bookingLimit: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: string, locationId: string, object: string, reason: string, repeat: record, repeats: bool, resourceAddress: record, resourceDescription: string, resourceId: string, resourceImageUrl: string, resourceName: string, resourcePhone: record, serviceDescription: string, serviceDuration: int, serviceId: string, serviceImageUrl: string, serviceName: string, startDate: string, startTime: int, timezoneName: string, timezoneOffset: int>, hasMore: bool, object: string, total: int, url: string>"
    post-setup-v1-services-id-allocations: "record<bookingCount: int, bookingLimit: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: string, locationId: string, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, resourceAddress: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, resourceDescription: string, resourceId: string, resourceImageUrl: string, resourceName: string, resourcePhone: record<businessPhone: string, businessPhoneExt: string, homePhone: string, mobilePhone: string, phoneType: string>, serviceDescription: string, serviceDuration: int, serviceId: string, serviceImageUrl: string, serviceName: string, startDate: string, startTime: int, timezoneName: string, timezoneOffset: int>"
    post-setup-v1-services-id-allocations-bulk: "table<bookingCount: int, bookingLimit: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: string, locationId: string, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, resourceAddress: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, resourceDescription: string, resourceId: string, resourceImageUrl: string, resourceName: string, resourcePhone: record<businessPhone: string, businessPhoneExt: string, homePhone: string, mobilePhone: string, phoneType: string>, serviceDescription: string, serviceDuration: int, serviceId: string, serviceImageUrl: string, serviceName: string, startDate: string, startTime: int, timezoneName: string, timezoneOffset: int>"
    get-setup-v1-services-id-availability: "record<ignoreBusinessHours: bool, serviceId: int, serviceName: string, weekdays: record<fri: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, mon: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, sat: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, sun: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, thu: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, tue: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, wed: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>>>"
    put-setup-v1-services-id-availability: "record<ignoreBusinessHours: bool, serviceId: int, serviceName: string, weekdays: record<fri: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, mon: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, sat: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, sun: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, thu: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, tue: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, wed: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>>>"
    post-setup-v1-services-id-block: "record<deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: string, locationId: string, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, serviceId: string, startDate: string, startTime: int>"
    get-setup-v1-services-id-blocks: "record<count: int, data: table<deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: string, locationId: string, object: string, reason: string, repeat: record, repeats: bool, serviceId: string, startDate: string, startTime: int>, hasMore: bool, object: string, total: int, url: string>"
    get-setup-v1-services-id-calendar: "record<calendarId: string, calendarName: string, id: string, locationId: string, serviceId: string, serviceName: string>"
    delete-setup-v1-services-id-deleteimage: "record<availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookingInterval: int, bookingLimit: int, calendarId: string, calendarResourceGroupId: string, cancellationFeeAmount: float, cancellationFeeTaxable: bool, companyId: string, consumerPadding: bool, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, dailyBookingLimitCount: int, dailyBookingLimitMinutes: int, defaultService: bool, description: string, duration: int, durationInterval: int, durationMax: int, durationMin: int, durationSelect: bool, feeAmount: float, feeTaxable: bool, id: string, imageUrl: string, locationId: string, maxBookingLimit: int, maxCapacity: int, maxGroupSize: int, maxResourceBookingLimit: int, mediaPageUrl: string, name: string, nonRefundable: bool, object: string, padding: int, roundRobin: int, serviceGroupId: int, serviceGroupName: string, showOnline: bool, type: string>"
    put-setup-v1-services-id-recover: "record<availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookingInterval: int, bookingLimit: int, calendarId: string, calendarResourceGroupId: string, cancellationFeeAmount: float, cancellationFeeTaxable: bool, companyId: string, consumerPadding: bool, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, dailyBookingLimitCount: int, dailyBookingLimitMinutes: int, defaultService: bool, description: string, duration: int, durationInterval: int, durationMax: int, durationMin: int, durationSelect: bool, feeAmount: float, feeTaxable: bool, id: string, imageUrl: string, locationId: string, maxBookingLimit: int, maxCapacity: int, maxGroupSize: int, maxResourceBookingLimit: int, mediaPageUrl: string, name: string, nonRefundable: bool, object: string, padding: int, roundRobin: int, serviceGroupId: int, serviceGroupName: string, showOnline: bool, type: string>"
    get-setup-v1-services-id-resources: "record<count: int, data: table<address: record, availability: record, bioLink: string, bookingNotification: int, calendarAvailability: int, contact: record, customFields: record, deletedStatus: bool, deletedTime: string, description: string, effectiveDate: string, email: string, gender: string, googleCalendarAuthUrl: string, googleCalendarAuthorized: bool, googleCalendarId: string, groupId: int, hourly: float, id: string, ignoreBusinessHours: bool, imageUrl: string, locationId: string, name: string, notificationType: int, object: string, options: record, outlookCalendarAuthUrl: string, outlookCalendarAuthorized: bool, outlookCalendarId: string, phone: record, recurringAvailability: bool, services: list, skypeName: string, sortKey: int, timezoneIana: string, timezoneId: string, timezoneOffset: int>, hasMore: bool, object: string, total: int, url: string>"
    post-setup-v1-services-id-uploadimage: "record<availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookingInterval: int, bookingLimit: int, calendarId: string, calendarResourceGroupId: string, cancellationFeeAmount: float, cancellationFeeTaxable: bool, companyId: string, consumerPadding: bool, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, dailyBookingLimitCount: int, dailyBookingLimitMinutes: int, defaultService: bool, description: string, duration: int, durationInterval: int, durationMax: int, durationMin: int, durationSelect: bool, feeAmount: float, feeTaxable: bool, id: string, imageUrl: string, locationId: string, maxBookingLimit: int, maxCapacity: int, maxGroupSize: int, maxResourceBookingLimit: int, mediaPageUrl: string, name: string, nonRefundable: bool, object: string, padding: int, roundRobin: int, serviceGroupId: int, serviceGroupName: string, showOnline: bool, type: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-setup-v1-appointments" "get-setup-v1-appointments-id" "put-setup-v1-appointments-id-reassign-resource-resource-id" "get-setup-v1-businessusers" "post-setup-v1-businessusers" "get-setup-v1-businessusers-permissions" "get-setup-v1-businessusers-email-companies" "delete-setup-v1-businessusers-id" "get-setup-v1-businessusers-id" "put-setup-v1-businessusers-id" "get-setup-v1-calendars" "post-setup-v1-calendars" "delete-setup-v1-calendars-block-id" "put-setup-v1-calendars-block-id" "get-setup-v1-calendars-blocks-id" "delete-setup-v1-calendars-id" "get-setup-v1-calendars-id" "put-setup-v1-calendars-id" "post-setup-v1-calendars-id-block" "get-setup-v1-calendars-id-blocks" "put-setup-v1-calendars-id-recover" "get-setup-v1-calendars-id-services" "get-setup-v1-companies" "post-setup-v1-companies" "put-setup-v1-companies" "get-setup-v1-companies-domains" "post-setup-v1-companies-domains" "delete-setup-v1-companies-domains-id" "get-setup-v1-companies-domains-id" "put-setup-v1-companies-domains-id" "get-setup-v1-companies-email-templates" "delete-setup-v1-companies-email-templates-master" "get-setup-v1-companies-email-templates-master" "post-setup-v1-companies-email-templates-master" "get-setup-v1-companies-email-templates-template-name" "get-setup-v1-companies-regions" "post-setup-v1-companies-regions" "delete-setup-v1-companies-regions-id" "get-setup-v1-companies-regions-id" "put-setup-v1-companies-regions-id" "get-setup-v1-companies-timezones-date" "get-setup-v1-customers" "get-setup-v1-customers-id" "get-setup-v1-customers-id-privacy" "get-setup-v1-locations" "post-setup-v1-locations" "post-setup-v1-locations-bulk" "delete-setup-v1-locations-services-id" "get-setup-v1-locations-services-id" "delete-setup-v1-locations-id" "get-setup-v1-locations-id" "put-setup-v1-locations-id" "get-setup-v1-locations-id-appointmentreminders" "put-setup-v1-locations-id-appointmentreminders" "delete-setup-v1-locations-id-deleteallimages" "delete-setup-v1-locations-id-deleteimage" "get-setup-v1-locations-id-email-templates" "post-setup-v1-locations-id-email-templates" "delete-setup-v1-locations-id-email-templates-master" "get-setup-v1-locations-id-email-templates-master" "post-setup-v1-locations-id-email-templates-master" "delete-setup-v1-locations-id-email-templates-template-name" "get-setup-v1-locations-id-email-templates-template-name" "delete-setup-v1-locations-id-google-service-account" "post-setup-v1-locations-id-google-service-account" "put-setup-v1-locations-id-holidays-holiday-id-closed" "put-setup-v1-locations-id-recover" "delete-setup-v1-locations-id-services" "get-setup-v1-locations-id-services" "post-setup-v1-locations-id-services" "put-setup-v1-locations-id-settings-scope-settings-scope" "post-setup-v1-locations-id-uploadimage" "get-setup-v1-resourcegroups" "post-setup-v1-resourcegroups" "delete-setup-v1-resourcegroups-id" "get-setup-v1-resourcegroups-id" "put-setup-v1-resourcegroups-id" "put-setup-v1-resourcegroups-id-recover" "get-setup-v1-resources" "post-setup-v1-resources" "delete-setup-v1-resources-allocations-id" "get-setup-v1-resources-allocations-id" "put-setup-v1-resources-allocations-id" "delete-setup-v1-resources-block-id" "put-setup-v1-resources-block-id" "get-setup-v1-resources-blocks-id" "post-setup-v1-resources-bulk" "put-setup-v1-resources-bulk" "get-setup-v1-resources-timezones" "delete-setup-v1-resources-id" "get-setup-v1-resources-id" "put-setup-v1-resources-id" "get-setup-v1-resources-id-allocations" "post-setup-v1-resources-id-allocations" "get-setup-v1-resources-id-availability" "put-setup-v1-resources-id-availability" "post-setup-v1-resources-id-block" "get-setup-v1-resources-id-blocks" "get-setup-v1-resources-id-calendar-auth-google-google-email-address" "get-setup-v1-resources-id-calendar-auth-outlook-outlook-email-address" "delete-setup-v1-resources-id-deleteimage" "put-setup-v1-resources-id-reassign-appointments-resource-id" "put-setup-v1-resources-id-recover" "delete-setup-v1-resources-id-services" "post-setup-v1-resources-id-services" "put-setup-v1-resources-id-services" "post-setup-v1-resources-id-uploadimage" "get-setup-v1-servicegroups" "post-setup-v1-servicegroups" "delete-setup-v1-servicegroups-id" "get-setup-v1-servicegroups-id" "put-setup-v1-servicegroups-id" "put-setup-v1-servicegroups-id-recover" "get-setup-v1-services" "post-setup-v1-services" "delete-setup-v1-services-allocations-id" "get-setup-v1-services-allocations-id" "put-setup-v1-services-allocations-id" "delete-setup-v1-services-block-id" "put-setup-v1-services-block-id" "get-setup-v1-services-blocks-id" "post-setup-v1-services-calendar" "delete-setup-v1-services-calendar-id" "delete-setup-v1-services-id" "get-setup-v1-services-id" "put-setup-v1-services-id" "get-setup-v1-services-id-allocations" "post-setup-v1-services-id-allocations" "post-setup-v1-services-id-allocations-bulk" "get-setup-v1-services-id-availability" "put-setup-v1-services-id-availability" "post-setup-v1-services-id-block" "get-setup-v1-services-id-blocks" "get-setup-v1-services-id-calendar" "delete-setup-v1-services-id-deleteimage" "put-setup-v1-services-id-recover" "get-setup-v1-services-id-resources" "post-setup-v1-services-id-uploadimage" "commands"] | sort) } | get name | first)
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

# List Appointments
#
# GET /setup/v1/appointments
# Returns: record<count: int, data: table<auditTrail: list, bookedBy: string, businessName: string, calendarId: string, confirmationNumber: string, confirmed: bool, createDate: string, customFields: record, customerId: string, customerMessage: string, customers: list, date: string, dateInternational: string, downloadIcsUrl: string, duration: int, email: string, emailConfirmationSent: string, emailReminderSent: string, endDateTime: string, firstname: string, groupSize: int, id: string, ipAddress: string, lastModifiedBy: string, lastModifiedOn: string, lastname: string, latitude: string, location: string, locationId: string, longitude: string, name: string, notes: string, object: string, onlineBooking: bool, paymentStatus: int, phone: string, phoneExt: string, phoneType: string, rescheduledId: string, resourceEmail: string, resourceGroupId: string, resourceGroupName: string, resourceId: string, resourceImageUrl: string, resourceName: string, resources: list, serviceAllocationId: string, serviceId: string, serviceImageUrl: string, serviceName: string, smsConfirmationSent: string, smsReminderSent: string, startDateTime: string, status: string, stripeChargeId: string, stripeRefundId: string, time: int, timezone: int, timezoneIana: string, timezoneId: string>, hasMore: bool, object: string, total: int, url: string>
export def "get-setup-v1-appointments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --location-id: string # id of business location, defaults to primary business location
  --email: string # Filter appointments by email address
  --lastname: string # Filter appointments by lastname or part of
  --service-id: string # Filter appointments by service
  --calendar-id: string # Filter appointments by calendar
  --resource-id: string # Filter appointments by resource
  --customer-id: string # Filter appointments by customer
  --service-allocation-id: string # Filter appointments by service allocation
  --start-date: string # Format YYYY-MM-DD: Filter appointments by on/after startDate (format: date-time)
  --end-date: string # Format YYYY-MM-DD: Filter appointments on/before endDate (format: date-time)
  --status: string # Filter appointments by status: IN, BK, CN, RE, RS
  --booked-by: string # Filter appointments by user email who booked
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit default 20, max 100 (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/setup/v1/appointments"
    query: [{name: locationId, var: location_id}, {name: email, var: email}, {name: lastname, var: lastname}, {name: serviceId, var: service_id}, {name: calendarId, var: calendar_id}, {name: resourceId, var: resource_id}, {name: customerId, var: customer_id}, {name: serviceAllocationId, var: service_allocation_id}, {name: startDate, var: start_date}, {name: endDate, var: end_date}, {name: status, var: status}, {name: bookedBy, var: booked_by}, {name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    location_id: $location_id, email: $email, lastname: $lastname, service_id: $service_id, calendar_id: $calendar_id, resource_id: $resource_id, customer_id: $customer_id, service_allocation_id: $service_allocation_id, start_date: $start_date, end_date: $end_date, status: $status, booked_by: $booked_by, offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Appointment
#
# GET /setup/v1/appointments/{id}
# Returns: record<auditTrail: table<appointmentId: string, id: string, modificationType: string, modifiedBy: string, modifiedOn: string, notesAfter: string, notesBefore: string, statusAfter: string, statusBefore: string>, bookedBy: string, businessName: string, calendarId: string, confirmationNumber: string, confirmed: bool, createDate: string, customFields: record, customerId: string, customerMessage: string, customers: table<appointmentId: string, customerId: string>, date: string, dateInternational: string, downloadIcsUrl: string, duration: int, email: string, emailConfirmationSent: string, emailReminderSent: string, endDateTime: string, firstname: string, groupSize: int, id: string, ipAddress: string, lastModifiedBy: string, lastModifiedOn: string, lastname: string, latitude: string, location: string, locationId: string, longitude: string, name: string, notes: string, object: string, onlineBooking: bool, paymentStatus: int, phone: string, phoneExt: string, phoneType: string, rescheduledId: string, resourceEmail: string, resourceGroupId: string, resourceGroupName: string, resourceId: string, resourceImageUrl: string, resourceName: string, resources: table<appointmentId: string, resourceEmail: string, resourceGroupId: string, resourceId: string, resourceImageUrl: string, resourceName: string>, serviceAllocationId: string, serviceId: string, serviceImageUrl: string, serviceName: string, smsConfirmationSent: string, smsReminderSent: string, startDateTime: string, status: string, stripeChargeId: string, stripeRefundId: string, time: int, timezone: int, timezoneIana: string, timezoneId: string>
export def "get-setup-v1-appointments-id" [
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
    path: "/setup/v1/appointments/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reassign Appointment
#
# PUT /setup/v1/appointments/{id}/reassign/resource/{resourceId}
# Returns: record<auditTrail: table<appointmentId: string, id: string, modificationType: string, modifiedBy: string, modifiedOn: string, notesAfter: string, notesBefore: string, statusAfter: string, statusBefore: string>, bookedBy: string, businessName: string, calendarId: string, confirmationNumber: string, confirmed: bool, createDate: string, customFields: record, customerId: string, customerMessage: string, customers: table<appointmentId: string, customerId: string>, date: string, dateInternational: string, downloadIcsUrl: string, duration: int, email: string, emailConfirmationSent: string, emailReminderSent: string, endDateTime: string, firstname: string, groupSize: int, id: string, ipAddress: string, lastModifiedBy: string, lastModifiedOn: string, lastname: string, latitude: string, location: string, locationId: string, longitude: string, name: string, notes: string, object: string, onlineBooking: bool, paymentStatus: int, phone: string, phoneExt: string, phoneType: string, rescheduledId: string, resourceEmail: string, resourceGroupId: string, resourceGroupName: string, resourceId: string, resourceImageUrl: string, resourceName: string, resources: table<appointmentId: string, resourceEmail: string, resourceGroupId: string, resourceId: string, resourceImageUrl: string, resourceName: string>, serviceAllocationId: string, serviceId: string, serviceImageUrl: string, serviceName: string, smsConfirmationSent: string, smsReminderSent: string, startDateTime: string, status: string, stripeChargeId: string, stripeRefundId: string, time: int, timezone: int, timezoneIana: string, timezoneId: string>
export def "put-setup-v1-appointments-id-reassign-resource-resource-id" [
  id: string
  resource_id: string
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
    method: put
    path: "/setup/v1/appointments/{id}/reassign/resource/{resourceId}"
    path_params: [{name: id, var: id}, {name: resourceId, var: resource_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, resource_id: $resource_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Users
#
# GET /setup/v1/businessusers
# Returns: record<count: int, data: table<accountId: string, businessName: string, email: string, id: string, identityAccount: bool, locationId: string, name: string, object: string, permissions: list, resourceId: string, resourceName: string, role: string>, hasMore: bool, object: string, total: int, url: string>
export def "get-setup-v1-businessusers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --location-id: string # id of business location, defaults to primary business location
  --email: string # Filter by email address
  --role: string # Filter user role
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit default 20, max 100 (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/setup/v1/businessusers"
    query: [{name: locationId, var: location_id}, {name: email, var: email}, {name: role, var: role}, {name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    location_id: $location_id, email: $email, role: $role, offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create User
#
# POST /setup/v1/businessusers
# Returns: record<accountId: string, businessName: string, email: string, id: string, identityAccount: bool, locationId: string, name: string, object: string, permissions: table<access: string, function: string, object: string>, resourceId: string, resourceName: string, role: string>
export def "post-setup-v1-businessusers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # nullable
  --location-id: string # nullable
  --name: string # nullable
  --resource-id: string # nullable
  --role: string # nullable
  --send-registration-invite: oneof<nothing, bool>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/setup/v1/businessusers"
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: locationId, var: location_id}, {name: name, var: name}, {name: resourceId, var: resource_id}, {name: role, var: role}, {name: sendRegistrationInvite, var: send_registration_invite}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    email: $email, location_id: $location_id, name: $name, resource_id: $resource_id, role: $role, send_registration_invite: $send_registration_invite
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List User Permissions
#
# GET /setup/v1/businessusers/permissions
# Returns: record<count: int, data: table<access: string, function: string, object: string, role: string>, hasMore: bool, object: string, total: int, url: string>
export def "get-setup-v1-businessusers-permissions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --role: string # Filter permissions by role
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit default 20, max 100 (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/setup/v1/businessusers/permissions"
    query: [{name: role, var: role}, {name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    role: $role, offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List User Companies
#
# GET /setup/v1/businessusers/{email}/companies
# Returns: record<count: int, data: table<id: string, name: string, object: string>, email: string, hasMore: bool, object: string, total: int, url: string>
export def "get-setup-v1-businessusers-email-companies" [
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search-text: string # All or partial company name
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit default 20, max 100 (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/setup/v1/businessusers/{email}/companies"
    path_params: [{name: email, var: email}]
    query: [{name: searchText, var: search_text}, {name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    email: $email, search_text: $search_text, offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete User
#
# DELETE /setup/v1/businessusers/{id}
export def "delete-setup-v1-businessusers-id" [
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
    path: "/setup/v1/businessusers/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get User
#
# GET /setup/v1/businessusers/{id}
# Returns: record<accountId: string, businessName: string, email: string, id: string, identityAccount: bool, locationId: string, name: string, object: string, permissions: table<access: string, function: string, object: string>, resourceId: string, resourceName: string, role: string>
export def "get-setup-v1-businessusers-id" [
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
    path: "/setup/v1/businessusers/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update User
#
# PUT /setup/v1/businessusers/{id}
# Returns: record<accountId: string, businessName: string, email: string, id: string, identityAccount: bool, locationId: string, name: string, object: string, permissions: table<access: string, function: string, object: string>, resourceId: string, resourceName: string, role: string>
export def "put-setup-v1-businessusers-id" [
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
  --email: string # nullable
  --name: string # nullable
  --resource-id: string # nullable
  --role: string # nullable
  --send-registration-invite: oneof<nothing, bool>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/setup/v1/businessusers/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: name, var: name}, {name: resourceId, var: resource_id}, {name: role, var: role}, {name: sendRegistrationInvite, var: send_registration_invite}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, email: $email, name: $name, resource_id: $resource_id, role: $role, send_registration_invite: $send_registration_invite
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Calendars
#
# GET /setup/v1/calendars
# Returns: record<count: int, data: table<availability: record, bookingsPerSlot: int, deletedStatus: bool, deletedTime: string, id: string, interval: int, locationId: string, name: string, object: string, primary: bool, resourceGroupId: string, type: string>, hasMore: bool, object: string, total: int, url: string>
export def "get-setup-v1-calendars" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --location-id: string # id of business location, defaults to primary business location
  --deleted: oneof<nothing, bool> # Filter by deleted status
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit default 20, max 100 (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/setup/v1/calendars"
    query: [{name: locationId, var: location_id}, {name: deleted, var: deleted}, {name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    location_id: $location_id, deleted: $deleted, offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEPRECATING: Create
#
# POST /setup/v1/calendars
# Returns: record<availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bookingsPerSlot: int, deletedStatus: bool, deletedTime: string, id: string, interval: int, locationId: string, name: string, object: string, primary: bool, resourceGroupId: string, type: string>
export def "post-setup-v1-calendars" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --availability: record # shape: {fri?: record, mon?: record, sat?: record, sun?: record, thu?: record, tue?: record, wed?: record}
  --bookings-per-slot: int # format: int32
  --interval: int # format: int32
  --location-id: string # nullable
  --name: string # nullable
  --resource-group-id: string # nullable
  --type: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/setup/v1/calendars"
    body: {content_type: "application/json", kind: json, fields: [{name: availability, var: availability}, {name: bookingsPerSlot, var: bookings_per_slot}, {name: interval, var: interval}, {name: locationId, var: location_id}, {name: name, var: name}, {name: resourceGroupId, var: resource_group_id}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    availability: $availability, bookings_per_slot: $bookings_per_slot, interval: $interval, location_id: $location_id, name: $name, resource_group_id: $resource_group_id, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Calendar Block
#
# DELETE /setup/v1/calendars/block/{id}
# Returns: record<calendarId: string, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: string, locationId: string, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, startDate: string, startTime: int>
export def "delete-setup-v1-calendars-block-id" [
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
    method: delete
    path: "/setup/v1/calendars/block/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Calendar Block
#
# PUT /setup/v1/calendars/block/{id}
# Returns: record<calendarId: string, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: string, locationId: string, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, startDate: string, startTime: int>
export def "put-setup-v1-calendars-block-id" [
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
  --end-date: string # nullable, format: date
  --end-time: int # nullable, format: int32
  --reason: string # nullable
  --repeat: record # shape: {frequency?: string, interval?: int, monthDay?: int, monthType?: string, weekdays?: string}
  --repeats: oneof<nothing, bool> # nullable
  --start-date: string # nullable, format: date
  --start-time: int # nullable, format: int32
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/setup/v1/calendars/block/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: endDate, var: end_date}, {name: endTime, var: end_time}, {name: reason, var: reason}, {name: repeat, var: repeat}, {name: repeats, var: repeats}, {name: startDate, var: start_date}, {name: startTime, var: start_time}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, end_date: $end_date, end_time: $end_time, reason: $reason, repeat: $repeat, repeats: $repeats, start_date: $start_date, start_time: $start_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Calendar Block
#
# GET /setup/v1/calendars/blocks/{id}
# Returns: record<calendarId: string, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: string, locationId: string, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, startDate: string, startTime: int>
export def "get-setup-v1-calendars-blocks-id" [
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
    path: "/setup/v1/calendars/blocks/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Calendar
#
# DELETE /setup/v1/calendars/{id}
# Returns: record<availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bookingsPerSlot: int, deletedStatus: bool, deletedTime: string, id: string, interval: int, locationId: string, name: string, object: string, primary: bool, resourceGroupId: string, type: string>
export def "delete-setup-v1-calendars-id" [
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
    method: delete
    path: "/setup/v1/calendars/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Calendar
#
# GET /setup/v1/calendars/{id}
# Returns: record<availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bookingsPerSlot: int, deletedStatus: bool, deletedTime: string, id: string, interval: int, locationId: string, name: string, object: string, primary: bool, resourceGroupId: string, type: string>
export def "get-setup-v1-calendars-id" [
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
    path: "/setup/v1/calendars/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Calendar
#
# PUT /setup/v1/calendars/{id}
# Returns: record<availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bookingsPerSlot: int, deletedStatus: bool, deletedTime: string, id: string, interval: int, locationId: string, name: string, object: string, primary: bool, resourceGroupId: string, type: string>
export def "put-setup-v1-calendars-id" [
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
  --availability: record # shape: {fri?: record, mon?: record, sat?: record, sun?: record, thu?: record, tue?: record, wed?: record}
  --bookings-per-slot: int # format: int32
  --interval: int # format: int32
  --location-id: string # nullable
  --name: string # nullable
  --resource-group-id: string # nullable
  --type: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/setup/v1/calendars/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: availability, var: availability}, {name: bookingsPerSlot, var: bookings_per_slot}, {name: interval, var: interval}, {name: locationId, var: location_id}, {name: name, var: name}, {name: resourceGroupId, var: resource_group_id}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, availability: $availability, bookings_per_slot: $bookings_per_slot, interval: $interval, location_id: $location_id, name: $name, resource_group_id: $resource_group_id, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Calendar Block
#
# POST /setup/v1/calendars/{id}/block
# Returns: record<businessId: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: int, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, resourceId: int, startDate: string, startTime: int>
export def "post-setup-v1-calendars-id-block" [
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
  --end-date: string # nullable, format: date
  --end-time: int # nullable, format: int32
  --reason: string # nullable
  --repeat: record # shape: {frequency?: string, interval?: int, monthDay?: int, monthType?: string, weekdays?: string}
  --repeats: oneof<nothing, bool> # nullable
  --start-date: string # nullable, format: date
  --start-time: int # nullable, format: int32
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/setup/v1/calendars/{id}/block"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: endDate, var: end_date}, {name: endTime, var: end_time}, {name: reason, var: reason}, {name: repeat, var: repeat}, {name: repeats, var: repeats}, {name: startDate, var: start_date}, {name: startTime, var: start_time}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, end_date: $end_date, end_time: $end_time, reason: $reason, repeat: $repeat, repeats: $repeats, start_date: $start_date, start_time: $start_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Calendar Blocks
#
# GET /setup/v1/calendars/{id}/blocks
# Returns: record<count: int, data: table<calendarId: string, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: string, locationId: string, object: string, reason: string, repeat: record, repeats: bool, startDate: string, startTime: int>, hasMore: bool, object: string, total: int, url: string>
export def "get-setup-v1-calendars-id-blocks" [
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
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit default 20, max 100 (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/setup/v1/calendars/{id}/blocks"
    path_params: [{name: id, var: id}]
    query: [{name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Recover Calendar
#
# PUT /setup/v1/calendars/{id}/recover
# Returns: record<availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bookingsPerSlot: int, deletedStatus: bool, deletedTime: string, id: string, interval: int, locationId: string, name: string, object: string, primary: bool, resourceGroupId: string, type: string>
export def "put-setup-v1-calendars-id-recover" [
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
    method: put
    path: "/setup/v1/calendars/{id}/recover"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Calendar Services
#
# GET /setup/v1/calendars/{id}/services
# Returns: record<count: int, data: table<availability: record, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookingInterval: int, bookingLimit: int, calendarId: string, calendarResourceGroupId: string, cancellationFeeAmount: float, cancellationFeeTaxable: bool, companyId: string, consumerPadding: bool, customFields: record, dailyBookingLimitCount: int, dailyBookingLimitMinutes: int, defaultService: bool, description: string, duration: int, durationInterval: int, durationMax: int, durationMin: int, durationSelect: bool, feeAmount: float, feeTaxable: bool, id: string, imageUrl: string, locationId: string, maxBookingLimit: int, maxCapacity: int, maxGroupSize: int, maxResourceBookingLimit: int, mediaPageUrl: string, name: string, nonRefundable: bool, object: string, padding: int, roundRobin: int, serviceGroupId: int, serviceGroupName: string, showOnline: bool, type: string>, hasMore: bool, object: string, total: int, url: string>
export def "get-setup-v1-calendars-id-services" [
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
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit default 20, max 100 (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/setup/v1/calendars/{id}/services"
    path_params: [{name: id, var: id}]
    query: [{name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Company
#
# GET /setup/v1/companies
# Returns: record<addressLine1: string, addressLine2: string, bookingWebhookUrl: string, city: string, clientId: string, clientSecret: string, country: string, customerWebhookUrl: string, deletedStatus: bool, deletedTime: string, disableEmailAndSmsNotifications: bool, email: string, fax: string, id: string, name: string, notificationFromEmailAddress: string, notificationFromName: string, object: string, phone: string, postalCode: string, registrationDate: string, registrationEmail: string, reminderWebhookUrl: string, resourceWebhookUrl: string, state: string, timezoneId: string, timezoneName: string, webhookSignatureHash: string, website: string>
export def "get-setup-v1-companies" [
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
    path: "/setup/v1/companies"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Company
#
# POST /setup/v1/companies
# Returns: record<addressLine1: string, addressLine2: string, bookingWebhookUrl: string, city: string, clientId: string, clientSecret: string, country: string, customerWebhookUrl: string, deletedStatus: bool, deletedTime: string, disableEmailAndSmsNotifications: bool, email: string, fax: string, id: string, name: string, notificationFromEmailAddress: string, notificationFromName: string, object: string, phone: string, postalCode: string, registrationDate: string, registrationEmail: string, reminderWebhookUrl: string, resourceWebhookUrl: string, state: string, timezoneId: string, timezoneName: string, webhookSignatureHash: string, website: string>
export def "post-setup-v1-companies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address-line1: string # nullable
  --address-line2: string # nullable
  --booking-webhook-url: string # nullable
  --city: string # nullable
  --country: string # nullable
  --customer-webhook-url: string # nullable
  --disable-email-and-sms-notifications: oneof<nothing, bool> # nullable
  --email: string # nullable
  --fax: string # nullable
  --name: string # nullable
  --notification-from-email-address: string # nullable
  --notification-from-name: string # nullable
  --phone: string # nullable
  --postal-code: string # nullable
  --registration-email: string # nullable
  --reminder-webhook-url: string # nullable
  --resource-webhook-url: string # nullable
  --state: string # nullable
  --timezone-name: string # nullable
  --webhook-signature-hash: string # nullable
  --website: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/setup/v1/companies"
    body: {content_type: "application/json", kind: json, fields: [{name: addressLine1, var: address_line1}, {name: addressLine2, var: address_line2}, {name: bookingWebhookUrl, var: booking_webhook_url}, {name: city, var: city}, {name: country, var: country}, {name: customerWebhookUrl, var: customer_webhook_url}, {name: disableEmailAndSmsNotifications, var: disable_email_and_sms_notifications}, {name: email, var: email}, {name: fax, var: fax}, {name: name, var: name}, {name: notificationFromEmailAddress, var: notification_from_email_address}, {name: notificationFromName, var: notification_from_name}, {name: phone, var: phone}, {name: postalCode, var: postal_code}, {name: registrationEmail, var: registration_email}, {name: reminderWebhookUrl, var: reminder_webhook_url}, {name: resourceWebhookUrl, var: resource_webhook_url}, {name: state, var: state}, {name: timezoneName, var: timezone_name}, {name: webhookSignatureHash, var: webhook_signature_hash}, {name: website, var: website}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    address_line1: $address_line1, address_line2: $address_line2, booking_webhook_url: $booking_webhook_url, city: $city, country: $country, customer_webhook_url: $customer_webhook_url, disable_email_and_sms_notifications: $disable_email_and_sms_notifications, email: $email, fax: $fax, name: $name, notification_from_email_address: $notification_from_email_address, notification_from_name: $notification_from_name, phone: $phone, postal_code: $postal_code, registration_email: $registration_email, reminder_webhook_url: $reminder_webhook_url, resource_webhook_url: $resource_webhook_url, state: $state, timezone_name: $timezone_name, webhook_signature_hash: $webhook_signature_hash, website: $website
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Company
#
# PUT /setup/v1/companies
# Returns: record<addressLine1: string, addressLine2: string, bookingWebhookUrl: string, city: string, clientId: string, clientSecret: string, country: string, customerWebhookUrl: string, deletedStatus: bool, deletedTime: string, disableEmailAndSmsNotifications: bool, email: string, fax: string, id: string, name: string, notificationFromEmailAddress: string, notificationFromName: string, object: string, phone: string, postalCode: string, registrationDate: string, registrationEmail: string, reminderWebhookUrl: string, resourceWebhookUrl: string, state: string, timezoneId: string, timezoneName: string, webhookSignatureHash: string, website: string>
export def "put-setup-v1-companies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address-line1: string # nullable
  --address-line2: string # nullable
  --booking-webhook-url: string # nullable
  --city: string # nullable
  --country: string # nullable
  --customer-webhook-url: string # nullable
  --disable-email-and-sms-notifications: oneof<nothing, bool> # nullable
  --email: string # nullable
  --fax: string # nullable
  --name: string # nullable
  --notification-from-email-address: string # nullable
  --notification-from-name: string # nullable
  --phone: string # nullable
  --postal-code: string # nullable
  --registration-email: string # nullable
  --reminder-webhook-url: string # nullable
  --resource-webhook-url: string # nullable
  --state: string # nullable
  --timezone-name: string # nullable
  --webhook-signature-hash: string # nullable
  --website: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/setup/v1/companies"
    body: {content_type: "application/json", kind: json, fields: [{name: addressLine1, var: address_line1}, {name: addressLine2, var: address_line2}, {name: bookingWebhookUrl, var: booking_webhook_url}, {name: city, var: city}, {name: country, var: country}, {name: customerWebhookUrl, var: customer_webhook_url}, {name: disableEmailAndSmsNotifications, var: disable_email_and_sms_notifications}, {name: email, var: email}, {name: fax, var: fax}, {name: name, var: name}, {name: notificationFromEmailAddress, var: notification_from_email_address}, {name: notificationFromName, var: notification_from_name}, {name: phone, var: phone}, {name: postalCode, var: postal_code}, {name: registrationEmail, var: registration_email}, {name: reminderWebhookUrl, var: reminder_webhook_url}, {name: resourceWebhookUrl, var: resource_webhook_url}, {name: state, var: state}, {name: timezoneName, var: timezone_name}, {name: webhookSignatureHash, var: webhook_signature_hash}, {name: website, var: website}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    address_line1: $address_line1, address_line2: $address_line2, booking_webhook_url: $booking_webhook_url, city: $city, country: $country, customer_webhook_url: $customer_webhook_url, disable_email_and_sms_notifications: $disable_email_and_sms_notifications, email: $email, fax: $fax, name: $name, notification_from_email_address: $notification_from_email_address, notification_from_name: $notification_from_name, phone: $phone, postal_code: $postal_code, registration_email: $registration_email, reminder_webhook_url: $reminder_webhook_url, resource_webhook_url: $resource_webhook_url, state: $state, timezone_name: $timezone_name, webhook_signature_hash: $webhook_signature_hash, website: $website
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Company Domains
#
# GET /setup/v1/companies/domains
# Returns: record<data: table<domain: string, id: string, object: string>, object: string, url: string>
export def "get-setup-v1-companies-domains" [
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
    path: "/setup/v1/companies/domains"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Company Domain
#
# POST /setup/v1/companies/domains
# Returns: record<domain: string, id: string, object: string>
export def "post-setup-v1-companies-domains" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/setup/v1/companies/domains"
    body: {content_type: "application/json", kind: json, fields: [{name: domain, var: domain}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain: $domain
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Company Domain
#
# DELETE /setup/v1/companies/domains/{id}
# Returns: record<domain: string, id: string, object: string>
export def "delete-setup-v1-companies-domains-id" [
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
    method: delete
    path: "/setup/v1/companies/domains/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Company Domain
#
# GET /setup/v1/companies/domains/{id}
# Returns: record<domain: string, id: string, object: string>
export def "get-setup-v1-companies-domains-id" [
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
    path: "/setup/v1/companies/domains/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Company Domain
#
# PUT /setup/v1/companies/domains/{id}
# Returns: record<domain: string, id: string, object: string>
export def "put-setup-v1-companies-domains-id" [
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
  --domain: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/setup/v1/companies/domains/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: domain, var: domain}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, domain: $domain
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Email Templates
#
# GET /setup/v1/companies/email/templates
# Returns: record<data: table<customized: bool, description: string, name: string, object: string, scope: string>, object: string, total: int, url: string>
export def "get-setup-v1-companies-email-templates" [
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
    path: "/setup/v1/companies/email/templates"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Master Template Settings
#
# DELETE /setup/v1/companies/email/templates/master
# Returns: record<centerEmailContent: bool, centerEmailContentPanel: bool, centerEmailFooter: bool, contentBackgroundColor: string, contentColor: string, contentLinkColor: string, emailBackgroundColor: string, emailColor: string, emailLinkColor: string, footerFontSize: string, footerLogoHeight: string, footerLogoPadding: string, footerPanelEmailContact: bool, footerPanelPhoneContact: bool, footerPanelWebsiteContact: bool, headerLogoHeight: string, headerLogoPadding: string, panelBackgroundColor: string, panelColor: string, panelLinkColor: string, privacyPolicyLink: string, showContentPanel: bool, showFooterLogo: bool, showFooterPanel: bool, showHeaderLogo: bool, showHeaderPanel: bool, version: string>
export def "delete-setup-v1-companies-email-templates-master" [
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
    method: delete
    path: "/setup/v1/companies/email/templates/master"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Master Template Settings
#
# GET /setup/v1/companies/email/templates/master
# Returns: record<centerEmailContent: bool, centerEmailContentPanel: bool, centerEmailFooter: bool, contentBackgroundColor: string, contentColor: string, contentLinkColor: string, emailBackgroundColor: string, emailColor: string, emailLinkColor: string, footerFontSize: string, footerLogoHeight: string, footerLogoPadding: string, footerPanelEmailContact: bool, footerPanelPhoneContact: bool, footerPanelWebsiteContact: bool, headerLogoHeight: string, headerLogoPadding: string, panelBackgroundColor: string, panelColor: string, panelLinkColor: string, privacyPolicyLink: string, showContentPanel: bool, showFooterLogo: bool, showFooterPanel: bool, showHeaderLogo: bool, showHeaderPanel: bool, version: string>
export def "get-setup-v1-companies-email-templates-master" [
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
    path: "/setup/v1/companies/email/templates/master"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Master Template Settings
#
# POST /setup/v1/companies/email/templates/master
# Returns: record<centerEmailContent: bool, centerEmailContentPanel: bool, centerEmailFooter: bool, contentBackgroundColor: string, contentColor: string, contentLinkColor: string, emailBackgroundColor: string, emailColor: string, emailLinkColor: string, footerFontSize: string, footerLogoHeight: string, footerLogoPadding: string, footerPanelEmailContact: bool, footerPanelPhoneContact: bool, footerPanelWebsiteContact: bool, headerLogoHeight: string, headerLogoPadding: string, panelBackgroundColor: string, panelColor: string, panelLinkColor: string, privacyPolicyLink: string, showContentPanel: bool, showFooterLogo: bool, showFooterPanel: bool, showHeaderLogo: bool, showHeaderPanel: bool, version: string>
export def "post-setup-v1-companies-email-templates-master" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --center-email-content: oneof<nothing, bool> # nullable
  --center-email-content-panel: oneof<nothing, bool> # nullable
  --center-email-footer: oneof<nothing, bool> # nullable
  --content-background-color: string # nullable
  --content-color: string # nullable
  --content-link-color: string # nullable
  --email-background-color: string # nullable
  --email-color: string # nullable
  --email-link-color: string # nullable
  --footer-font-size: string # nullable
  --footer-logo-height: string # nullable
  --footer-logo-padding: string # nullable
  --footer-panel-email-contact: oneof<nothing, bool> # nullable
  --footer-panel-phone-contact: oneof<nothing, bool> # nullable
  --footer-panel-website-contact: oneof<nothing, bool> # nullable
  --header-logo-height: string # nullable
  --header-logo-padding: string # nullable
  --panel-background-color: string # nullable
  --panel-color: string # nullable
  --panel-link-color: string # nullable
  --privacy-policy-link: string # nullable
  --show-content-panel: oneof<nothing, bool> # nullable
  --show-footer-logo: oneof<nothing, bool> # nullable
  --show-footer-panel: oneof<nothing, bool> # nullable
  --show-header-logo: oneof<nothing, bool> # nullable
  --show-header-panel: oneof<nothing, bool> # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/setup/v1/companies/email/templates/master"
    body: {content_type: "application/json", kind: json, fields: [{name: centerEmailContent, var: center_email_content}, {name: centerEmailContentPanel, var: center_email_content_panel}, {name: centerEmailFooter, var: center_email_footer}, {name: contentBackgroundColor, var: content_background_color}, {name: contentColor, var: content_color}, {name: contentLinkColor, var: content_link_color}, {name: emailBackgroundColor, var: email_background_color}, {name: emailColor, var: email_color}, {name: emailLinkColor, var: email_link_color}, {name: footerFontSize, var: footer_font_size}, {name: footerLogoHeight, var: footer_logo_height}, {name: footerLogoPadding, var: footer_logo_padding}, {name: footerPanelEmailContact, var: footer_panel_email_contact}, {name: footerPanelPhoneContact, var: footer_panel_phone_contact}, {name: footerPanelWebsiteContact, var: footer_panel_website_contact}, {name: headerLogoHeight, var: header_logo_height}, {name: headerLogoPadding, var: header_logo_padding}, {name: panelBackgroundColor, var: panel_background_color}, {name: panelColor, var: panel_color}, {name: panelLinkColor, var: panel_link_color}, {name: privacyPolicyLink, var: privacy_policy_link}, {name: showContentPanel, var: show_content_panel}, {name: showFooterLogo, var: show_footer_logo}, {name: showFooterPanel, var: show_footer_panel}, {name: showHeaderLogo, var: show_header_logo}, {name: showHeaderPanel, var: show_header_panel}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    center_email_content: $center_email_content, center_email_content_panel: $center_email_content_panel, center_email_footer: $center_email_footer, content_background_color: $content_background_color, content_color: $content_color, content_link_color: $content_link_color, email_background_color: $email_background_color, email_color: $email_color, email_link_color: $email_link_color, footer_font_size: $footer_font_size, footer_logo_height: $footer_logo_height, footer_logo_padding: $footer_logo_padding, footer_panel_email_contact: $footer_panel_email_contact, footer_panel_phone_contact: $footer_panel_phone_contact, footer_panel_website_contact: $footer_panel_website_contact, header_logo_height: $header_logo_height, header_logo_padding: $header_logo_padding, panel_background_color: $panel_background_color, panel_color: $panel_color, panel_link_color: $panel_link_color, privacy_policy_link: $privacy_policy_link, show_content_panel: $show_content_panel, show_footer_logo: $show_footer_logo, show_footer_panel: $show_footer_panel, show_header_logo: $show_header_logo, show_header_panel: $show_header_panel
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Email Template
#
# GET /setup/v1/companies/email/templates/{templateName}
# Returns: record<content: string, contentType: string, statusCode: int>
export def "get-setup-v1-companies-email-templates-template-name" [
  template_name: string
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
    path: "/setup/v1/companies/email/templates/{templateName}"
    path_params: [{name: templateName, var: template_name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    template_name: $template_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Regions
#
# GET /setup/v1/companies/regions
# Returns: record<count: int, data: table<id: string, name: string, object: string>, hasMore: bool, object: string, total: int, url: string>
export def "get-setup-v1-companies-regions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit default 20, max 100 (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/setup/v1/companies/regions"
    query: [{name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Region
#
# POST /setup/v1/companies/regions
# Returns: record<id: string, name: string, object: string>
export def "post-setup-v1-companies-regions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/setup/v1/companies/regions"
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Region
#
# DELETE /setup/v1/companies/regions/{id}
# Returns: record<id: string, name: string, object: string>
export def "delete-setup-v1-companies-regions-id" [
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
    method: delete
    path: "/setup/v1/companies/regions/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Region
#
# GET /setup/v1/companies/regions/{id}
# Returns: record<id: string, name: string, object: string>
export def "get-setup-v1-companies-regions-id" [
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
    path: "/setup/v1/companies/regions/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Region
#
# PUT /setup/v1/companies/regions/{id}
# Returns: record<id: string, name: string, object: string>
export def "put-setup-v1-companies-regions-id" [
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
  --name: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/setup/v1/companies/regions/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Time Zones
#
# GET /setup/v1/companies/timezones/{date}
# Returns: record<object: string, regions: list<string>, timezones: table<name: string, region: string, timezoneIanna: string, tzOffset: int>>
export def "get-setup-v1-companies-timezones-date" [
  date: string
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
    path: "/setup/v1/companies/timezones/{date}"
    path_params: [{name: date, var: date}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    date: $date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Customers
#
# GET /setup/v1/customers
# Returns: record<count: int, data: table<address: record, birthdate: string, businessName: string, companyName: string, contact: record, createdBy: string, createdOn: string, customFields: record, deletedStatus: bool, deletedTime: string, disabled: bool, email: string, emailInfo: bool, emailPromotion: bool, firstname: string, gender: string, groupId: string, id: string, inviteEmailSent: string, lastVisitDate: string, lastname: string, latitude: string, locationId: string, longitude: string, modifiedBy: string, modifiedOn: string, name: string, notificationType: string, object: string, registeredBy: string, registrationDate: string, resourceId: string, stripeCustomerId: string, subscriptionId: string, verificationDate: string, verifiedBy: string, welcomeEmailSent: string>, hasMore: bool, object: string, total: int, url: string>
export def "get-setup-v1-customers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --location-id: string # id of business location, defaults to primary business location
  --group-id: string # Filter by groupId
  --email: string # Filter by email address.
  --lastname: string # Search by lastname.
  --deleted: oneof<nothing, bool> # Filter by deleted status.
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit default 20, max 100 (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/setup/v1/customers"
    query: [{name: locationId, var: location_id}, {name: groupId, var: group_id}, {name: email, var: email}, {name: lastname, var: lastname}, {name: deleted, var: deleted}, {name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    location_id: $location_id, group_id: $group_id, email: $email, lastname: $lastname, deleted: $deleted, offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Customer
#
# GET /setup/v1/customers/{id}
# Returns: record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, birthdate: string, businessName: string, companyName: string, contact: record<businessPhone: string, businessPhoneExt: string, conferenceInfo: string, homePhone: string, mobilePhone: string, phoneType: string, skypeUsername: string>, createdBy: string, createdOn: string, customFields: record, deletedStatus: bool, deletedTime: string, disabled: bool, email: string, emailInfo: bool, emailPromotion: bool, firstname: string, gender: string, groupId: string, id: string, inviteEmailSent: string, lastVisitDate: string, lastname: string, latitude: string, locationId: string, longitude: string, modifiedBy: string, modifiedOn: string, name: string, notificationType: string, object: string, registeredBy: string, registrationDate: string, resourceId: string, stripeCustomerId: string, subscriptionId: string, verificationDate: string, verifiedBy: string, welcomeEmailSent: string>
export def "get-setup-v1-customers-id" [
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
    path: "/setup/v1/customers/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Customer Data
#
# GET /setup/v1/customers/{id}/privacy
# Returns: record<appointments: table<auditTrail: list, bookedBy: string, businessName: string, calendarId: string, confirmationNumber: string, confirmed: bool, createDate: string, customFields: record, customerId: string, customerMessage: string, customers: list, date: string, dateInternational: string, downloadIcsUrl: string, duration: int, email: string, emailConfirmationSent: string, emailReminderSent: string, endDateTime: string, firstname: string, groupSize: int, id: string, ipAddress: string, lastModifiedBy: string, lastModifiedOn: string, lastname: string, latitude: string, location: string, locationId: string, longitude: string, name: string, notes: string, object: string, onlineBooking: bool, paymentStatus: int, phone: string, phoneExt: string, phoneType: string, rescheduledId: string, resourceEmail: string, resourceGroupId: string, resourceGroupName: string, resourceId: string, resourceImageUrl: string, resourceName: string, resources: list, serviceAllocationId: string, serviceId: string, serviceImageUrl: string, serviceName: string, smsConfirmationSent: string, smsReminderSent: string, startDateTime: string, status: string, stripeChargeId: string, stripeRefundId: string, time: int, timezone: int, timezoneIana: string, timezoneId: string>, customer: record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, birthdate: string, businessName: string, companyName: string, contact: record<businessPhone: string, businessPhoneExt: string, conferenceInfo: string, homePhone: string, mobilePhone: string, phoneType: string, skypeUsername: string>, createdBy: string, createdOn: string, customFields: record, deletedStatus: bool, deletedTime: string, disabled: bool, email: string, emailInfo: bool, emailPromotion: bool, firstname: string, gender: string, groupId: string, id: string, inviteEmailSent: string, lastVisitDate: string, lastname: string, latitude: string, locationId: string, longitude: string, modifiedBy: string, modifiedOn: string, name: string, notificationType: string, object: string, registeredBy: string, registrationDate: string, resourceId: string, stripeCustomerId: string, subscriptionId: string, verificationDate: string, verifiedBy: string, welcomeEmailSent: string>>
export def "get-setup-v1-customers-id-privacy" [
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
    path: "/setup/v1/customers/{id}/privacy"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Locations
#
# GET /setup/v1/locations
# Returns: record<count: int, data: table<address: record, adminEmail: string, adminName: string, appointmentReminders: record, businessHolidays: list, businessHours: record, companyId: string, companyName: string, defaults: record, email: string, fax: string, friendlyId: string, id: string, imageUrl: string, latitude: float, logo: string, longitude: float, name: string, object: string, phone: string, primaryBusiness: bool, primaryCalendarId: string, regionId: string, services: list, settings: record, timezoneIana: string, timezoneId: string, timezoneOffset: int, travel: record, website: string>, hasMore: bool, object: string, total: int, url: string>
export def "get-setup-v1-locations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Location name(full or partial) to filter on
  --service-id: string # Find locations that offer this service
  --friendly-id: string # friendlyId of location
  --deleted: oneof<nothing, bool> # Filter locations on deleted status
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit default 20, max 100 (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/setup/v1/locations"
    query: [{name: name, var: name}, {name: serviceId, var: service_id}, {name: friendlyId, var: friendly_id}, {name: deleted, var: deleted}, {name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, service_id: $service_id, friendly_id: $friendly_id, deleted: $deleted, offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Location
#
# POST /setup/v1/locations
# Returns: record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, adminEmail: string, adminName: string, appointmentReminders: record<emailFirstReminder: int, emailFirstReminderInterval: int, emailSecondReminder: int, emailSecondReminderInterval: int, smsFirstReminder: int, smsFirstReminderInterval: int, smsSecondReminder: int, smsSecondReminderInterval: int>, businessHolidays: table<businessClosed: bool, holidayName: string, id: string, publicHolidayId: int>, businessHours: record<fri: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, mon: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sat: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sun: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, thu: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, tue: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, wed: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>>, companyId: string, companyName: string, defaults: record<autoUpdateCustomer: bool, businessNotification: bool, customerCity: bool, customerState: bool, emailInfo: bool, enableUtcTimezone: bool, object: string>, email: string, fax: string, friendlyId: string, id: string, imageUrl: string, latitude: float, logo: string, longitude: float, name: string, object: string, phone: string, primaryBusiness: bool, primaryCalendarId: string, regionId: string, services: table<id: int, object: string, serviceId: int, serviceName: string>, settings: record<availabilityForm: int, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookWithAccount: bool, bookingConfirmationMessage: string, bookingMessage: string, bookingPolicy: string, bookingTimerMins: int, businessId: string, companyId: string, customerBookingsPerDay: int, customerVerification: bool, defaultService: bool, defaultToCustomerTimezone: bool, disableAuthorization: bool, enableWorldTimezones: bool, enabled: bool, familyMembersEnabled: bool, firstAvailable: bool, formFlow: int, hideBreadCrumbNav: bool, hideContinueBooking: bool, hideLocationNav: bool, hideNavBar: bool, hideServiceGroupsNav: bool, hideServicesNav: bool, id: int, lateCancelAction: int, lateCancelHours: int, lateRescheduleAction: int, lateRescheduleHours: int, liveMode: bool, locationId: string, object: string, resourceAnyLabel: string, resourceLabel: string, resourceSelection: bool, returnToAvailability: bool, returnToService: bool, serviceLabel: string, showBusinessLogo: bool, showOnSchedLogo: bool, showServiceGroups: bool>, timezoneIana: string, timezoneId: string, timezoneOffset: int, travel: record<distance: string, proximity: string, startAddress: string, startLat: string, startLon: string, units: string>, website: string>
export def "post-setup-v1-locations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: record # shape: {addressLine1?: string, addressLine2?: string, city?: string, country?: string, postalCode?: string, state?: string}
  --admin-email: string # Field is required. (nullable)
  --admin-name: string # This field is no longer required and has been deprecated. (nullable)
  --appointment-reminders: record # shape: {emailFirstReminder?: int, emailFirstReminderInterval?: int, emailSecondReminder?: int, emailSecondReminderInterval?: int, smsFirstReminder?: int, smsFirstReminderInterval?: int, smsSecondReminder?: int, smsSecondReminderInterval?: int}
  --business-hours: record # shape: {fri?: record, mon?: record, sat?: record, sun?: record, thu?: record, tue?: record, wed?: record}
  --defaults: record # shape: {autoUpdateCustomer?: bool, businessNotification?: bool, customerCity?: bool, customerState?: bool, emailInfo?: bool, enableUtcTimezone?: bool}
  --email: string # nullable
  --fax: string # nullable
  --friendly-id: string # Use the friendlyId as an alternative to the assigned locationId Choose something easy and meaningful. Must be unique within your company. FriendlyId's are limited to maximum of 64 characters. (nullable)
  --name: string # nullable
  --phone: string # GroupSize Limits the number of people that can come along on a single appointment (nullable)
  --region-id: string # nullable
  --settings: record # shape: {bookAheadUnit?: int, bookAheadValue?: int, bookInAdvance?: int, bookingTimerMins?: int, customerBookingsPerDay?: int, enableWorldTimezones?: bool}
  --timezone-name: string # Field is required. It is in Iana format. e.g. America/New_York. Use moment.js in your client for ease of timezone detection and selection (nullable)
  --website: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/setup/v1/locations"
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: adminEmail, var: admin_email}, {name: adminName, var: admin_name}, {name: appointmentReminders, var: appointment_reminders}, {name: businessHours, var: business_hours}, {name: defaults, var: defaults}, {name: email, var: email}, {name: fax, var: fax}, {name: friendlyId, var: friendly_id}, {name: name, var: name}, {name: phone, var: phone}, {name: regionId, var: region_id}, {name: settings, var: settings}, {name: timezoneName, var: timezone_name}, {name: website, var: website}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    address: $address, admin_email: $admin_email, admin_name: $admin_name, appointment_reminders: $appointment_reminders, business_hours: $business_hours, defaults: $defaults, email: $email, fax: $fax, friendly_id: $friendly_id, name: $name, phone: $phone, region_id: $region_id, settings: $settings, timezone_name: $timezone_name, website: $website
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Locations Bulk
#
# POST /setup/v1/locations/bulk
# Returns: table<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, adminEmail: string, adminName: string, appointmentReminders: record<emailFirstReminder: int, emailFirstReminderInterval: int, emailSecondReminder: int, emailSecondReminderInterval: int, smsFirstReminder: int, smsFirstReminderInterval: int, smsSecondReminder: int, smsSecondReminderInterval: int>, businessHolidays: list<record>, businessHours: record<fri: record, mon: record, sat: record, sun: record, thu: record, tue: record, wed: record>, companyId: string, companyName: string, defaults: record<autoUpdateCustomer: bool, businessNotification: bool, customerCity: bool, customerState: bool, emailInfo: bool, enableUtcTimezone: bool, object: string>, email: string, fax: string, friendlyId: string, id: string, imageUrl: string, latitude: float, logo: string, longitude: float, name: string, object: string, phone: string, primaryBusiness: bool, primaryCalendarId: string, regionId: string, services: list<record>, settings: record<availabilityForm: int, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookWithAccount: bool, bookingConfirmationMessage: string, bookingMessage: string, bookingPolicy: string, bookingTimerMins: int, businessId: string, companyId: string, customerBookingsPerDay: int, customerVerification: bool, defaultService: bool, defaultToCustomerTimezone: bool, disableAuthorization: bool, enableWorldTimezones: bool, enabled: bool, familyMembersEnabled: bool, firstAvailable: bool, formFlow: int, hideBreadCrumbNav: bool, hideContinueBooking: bool, hideLocationNav: bool, hideNavBar: bool, hideServiceGroupsNav: bool, hideServicesNav: bool, id: int, lateCancelAction: int, lateCancelHours: int, lateRescheduleAction: int, lateRescheduleHours: int, liveMode: bool, locationId: string, object: string, resourceAnyLabel: string, resourceLabel: string, resourceSelection: bool, returnToAvailability: bool, returnToService: bool, serviceLabel: string, showBusinessLogo: bool, showOnSchedLogo: bool, showServiceGroups: bool>, timezoneIana: string, timezoneId: string, timezoneOffset: int, travel: record<distance: string, proximity: string, startAddress: string, startLat: string, startLon: string, units: string>, website: string>
export def "post-setup-v1-locations-bulk" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --locations: list # nullable — item shape: {address?: record, adminEmail?: string, adminName?: string, appointmentReminders?: record, businessHours?: record, defaults?: record, email?: string, fax?: string, friendlyId?: string, name?: string, phone?: string, regionId?: string, settings?: record, timezoneName?: string, website?: string}
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/setup/v1/locations/bulk"
    body: {content_type: "application/json", kind: json, fields: [{name: locations, var: locations}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    locations: $locations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unlink Service
#
# DELETE /setup/v1/locations/services/{id}
# Returns: record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, adminEmail: string, adminName: string, appointmentReminders: record<emailFirstReminder: int, emailFirstReminderInterval: int, emailSecondReminder: int, emailSecondReminderInterval: int, smsFirstReminder: int, smsFirstReminderInterval: int, smsSecondReminder: int, smsSecondReminderInterval: int>, businessHolidays: table<businessClosed: bool, holidayName: string, id: string, publicHolidayId: int>, businessHours: record<fri: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, mon: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sat: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sun: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, thu: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, tue: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, wed: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>>, companyId: string, companyName: string, defaults: record<autoUpdateCustomer: bool, businessNotification: bool, customerCity: bool, customerState: bool, emailInfo: bool, enableUtcTimezone: bool, object: string>, email: string, fax: string, friendlyId: string, id: string, imageUrl: string, latitude: float, logo: string, longitude: float, name: string, object: string, phone: string, primaryBusiness: bool, primaryCalendarId: string, regionId: string, services: table<id: int, object: string, serviceId: int, serviceName: string>, settings: record<availabilityForm: int, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookWithAccount: bool, bookingConfirmationMessage: string, bookingMessage: string, bookingPolicy: string, bookingTimerMins: int, businessId: string, companyId: string, customerBookingsPerDay: int, customerVerification: bool, defaultService: bool, defaultToCustomerTimezone: bool, disableAuthorization: bool, enableWorldTimezones: bool, enabled: bool, familyMembersEnabled: bool, firstAvailable: bool, formFlow: int, hideBreadCrumbNav: bool, hideContinueBooking: bool, hideLocationNav: bool, hideNavBar: bool, hideServiceGroupsNav: bool, hideServicesNav: bool, id: int, lateCancelAction: int, lateCancelHours: int, lateRescheduleAction: int, lateRescheduleHours: int, liveMode: bool, locationId: string, object: string, resourceAnyLabel: string, resourceLabel: string, resourceSelection: bool, returnToAvailability: bool, returnToService: bool, serviceLabel: string, showBusinessLogo: bool, showOnSchedLogo: bool, showServiceGroups: bool>, timezoneIana: string, timezoneId: string, timezoneOffset: int, travel: record<distance: string, proximity: string, startAddress: string, startLat: string, startLon: string, units: string>, website: string>
export def "delete-setup-v1-locations-services-id" [
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
    method: delete
    path: "/setup/v1/locations/services/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Linked Service
#
# GET /setup/v1/locations/services/{id}
# Returns: record<id: int, object: string, serviceId: int, serviceName: string>
export def "get-setup-v1-locations-services-id" [
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
    path: "/setup/v1/locations/services/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Location
#
# DELETE /setup/v1/locations/{id}
# Returns: record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, adminEmail: string, adminName: string, appointmentReminders: record<emailFirstReminder: int, emailFirstReminderInterval: int, emailSecondReminder: int, emailSecondReminderInterval: int, smsFirstReminder: int, smsFirstReminderInterval: int, smsSecondReminder: int, smsSecondReminderInterval: int>, businessHolidays: table<businessClosed: bool, holidayName: string, id: string, publicHolidayId: int>, businessHours: record<fri: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, mon: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sat: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sun: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, thu: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, tue: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, wed: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>>, companyId: string, companyName: string, defaults: record<autoUpdateCustomer: bool, businessNotification: bool, customerCity: bool, customerState: bool, emailInfo: bool, enableUtcTimezone: bool, object: string>, email: string, fax: string, friendlyId: string, id: string, imageUrl: string, latitude: float, logo: string, longitude: float, name: string, object: string, phone: string, primaryBusiness: bool, primaryCalendarId: string, regionId: string, services: table<id: int, object: string, serviceId: int, serviceName: string>, settings: record<availabilityForm: int, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookWithAccount: bool, bookingConfirmationMessage: string, bookingMessage: string, bookingPolicy: string, bookingTimerMins: int, businessId: string, companyId: string, customerBookingsPerDay: int, customerVerification: bool, defaultService: bool, defaultToCustomerTimezone: bool, disableAuthorization: bool, enableWorldTimezones: bool, enabled: bool, familyMembersEnabled: bool, firstAvailable: bool, formFlow: int, hideBreadCrumbNav: bool, hideContinueBooking: bool, hideLocationNav: bool, hideNavBar: bool, hideServiceGroupsNav: bool, hideServicesNav: bool, id: int, lateCancelAction: int, lateCancelHours: int, lateRescheduleAction: int, lateRescheduleHours: int, liveMode: bool, locationId: string, object: string, resourceAnyLabel: string, resourceLabel: string, resourceSelection: bool, returnToAvailability: bool, returnToService: bool, serviceLabel: string, showBusinessLogo: bool, showOnSchedLogo: bool, showServiceGroups: bool>, timezoneIana: string, timezoneId: string, timezoneOffset: int, travel: record<distance: string, proximity: string, startAddress: string, startLat: string, startLon: string, units: string>, website: string>
export def "delete-setup-v1-locations-id" [
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
    method: delete
    path: "/setup/v1/locations/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Location
#
# GET /setup/v1/locations/{id}
# Returns: record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, adminEmail: string, adminName: string, appointmentReminders: record<emailFirstReminder: int, emailFirstReminderInterval: int, emailSecondReminder: int, emailSecondReminderInterval: int, smsFirstReminder: int, smsFirstReminderInterval: int, smsSecondReminder: int, smsSecondReminderInterval: int>, businessHolidays: table<businessClosed: bool, holidayName: string, id: string, publicHolidayId: int>, businessHours: record<fri: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, mon: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sat: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sun: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, thu: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, tue: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, wed: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>>, companyId: string, companyName: string, defaults: record<autoUpdateCustomer: bool, businessNotification: bool, customerCity: bool, customerState: bool, emailInfo: bool, enableUtcTimezone: bool, object: string>, email: string, fax: string, friendlyId: string, id: string, imageUrl: string, latitude: float, logo: string, longitude: float, name: string, object: string, phone: string, primaryBusiness: bool, primaryCalendarId: string, regionId: string, services: table<id: int, object: string, serviceId: int, serviceName: string>, settings: record<availabilityForm: int, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookWithAccount: bool, bookingConfirmationMessage: string, bookingMessage: string, bookingPolicy: string, bookingTimerMins: int, businessId: string, companyId: string, customerBookingsPerDay: int, customerVerification: bool, defaultService: bool, defaultToCustomerTimezone: bool, disableAuthorization: bool, enableWorldTimezones: bool, enabled: bool, familyMembersEnabled: bool, firstAvailable: bool, formFlow: int, hideBreadCrumbNav: bool, hideContinueBooking: bool, hideLocationNav: bool, hideNavBar: bool, hideServiceGroupsNav: bool, hideServicesNav: bool, id: int, lateCancelAction: int, lateCancelHours: int, lateRescheduleAction: int, lateRescheduleHours: int, liveMode: bool, locationId: string, object: string, resourceAnyLabel: string, resourceLabel: string, resourceSelection: bool, returnToAvailability: bool, returnToService: bool, serviceLabel: string, showBusinessLogo: bool, showOnSchedLogo: bool, showServiceGroups: bool>, timezoneIana: string, timezoneId: string, timezoneOffset: int, travel: record<distance: string, proximity: string, startAddress: string, startLat: string, startLon: string, units: string>, website: string>
export def "get-setup-v1-locations-id" [
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
    path: "/setup/v1/locations/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Location
#
# PUT /setup/v1/locations/{id}
# Returns: record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, adminEmail: string, adminName: string, appointmentReminders: record<emailFirstReminder: int, emailFirstReminderInterval: int, emailSecondReminder: int, emailSecondReminderInterval: int, smsFirstReminder: int, smsFirstReminderInterval: int, smsSecondReminder: int, smsSecondReminderInterval: int>, businessHolidays: table<businessClosed: bool, holidayName: string, id: string, publicHolidayId: int>, businessHours: record<fri: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, mon: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sat: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sun: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, thu: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, tue: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, wed: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>>, companyId: string, companyName: string, defaults: record<autoUpdateCustomer: bool, businessNotification: bool, customerCity: bool, customerState: bool, emailInfo: bool, enableUtcTimezone: bool, object: string>, email: string, fax: string, friendlyId: string, id: string, imageUrl: string, latitude: float, logo: string, longitude: float, name: string, object: string, phone: string, primaryBusiness: bool, primaryCalendarId: string, regionId: string, services: table<id: int, object: string, serviceId: int, serviceName: string>, settings: record<availabilityForm: int, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookWithAccount: bool, bookingConfirmationMessage: string, bookingMessage: string, bookingPolicy: string, bookingTimerMins: int, businessId: string, companyId: string, customerBookingsPerDay: int, customerVerification: bool, defaultService: bool, defaultToCustomerTimezone: bool, disableAuthorization: bool, enableWorldTimezones: bool, enabled: bool, familyMembersEnabled: bool, firstAvailable: bool, formFlow: int, hideBreadCrumbNav: bool, hideContinueBooking: bool, hideLocationNav: bool, hideNavBar: bool, hideServiceGroupsNav: bool, hideServicesNav: bool, id: int, lateCancelAction: int, lateCancelHours: int, lateRescheduleAction: int, lateRescheduleHours: int, liveMode: bool, locationId: string, object: string, resourceAnyLabel: string, resourceLabel: string, resourceSelection: bool, returnToAvailability: bool, returnToService: bool, serviceLabel: string, showBusinessLogo: bool, showOnSchedLogo: bool, showServiceGroups: bool>, timezoneIana: string, timezoneId: string, timezoneOffset: int, travel: record<distance: string, proximity: string, startAddress: string, startLat: string, startLon: string, units: string>, website: string>
export def "put-setup-v1-locations-id" [
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
  --remove-region: oneof<nothing, bool>
  --address: record # shape: {addressLine1?: string, addressLine2?: string, city?: string, country?: string, postalCode?: string, state?: string}
  --admin-email: string # nullable
  --admin-name: string # nullable
  --appointment-reminders: record # shape: {emailFirstReminder?: int, emailFirstReminderInterval?: int, emailSecondReminder?: int, emailSecondReminderInterval?: int, smsFirstReminder?: int, smsFirstReminderInterval?: int, smsSecondReminder?: int, smsSecondReminderInterval?: int}
  --business-hours: record # shape: {fri?: record, mon?: record, sat?: record, sun?: record, thu?: record, tue?: record, wed?: record}
  --defaults: record # shape: {autoUpdateCustomer?: bool, businessNotification?: bool, customerCity?: bool, customerState?: bool, emailInfo?: bool, enableUtcTimezone?: bool}
  --email: string # nullable
  --fax: string # nullable
  --friendly-id: string # nullable
  --name: string # nullable
  --phone: string # nullable
  --region-id: string # nullable
  --settings: record # shape: {bookAheadUnit?: int, bookAheadValue?: int, bookInAdvance?: int, bookingTimerMins?: int, customerBookingsPerDay?: int, enableWorldTimezones?: bool}
  --timezone-name: string # nullable
  --website: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/setup/v1/locations/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: removeRegion, var: remove_region}]
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: adminEmail, var: admin_email}, {name: adminName, var: admin_name}, {name: appointmentReminders, var: appointment_reminders}, {name: businessHours, var: business_hours}, {name: defaults, var: defaults}, {name: email, var: email}, {name: fax, var: fax}, {name: friendlyId, var: friendly_id}, {name: name, var: name}, {name: phone, var: phone}, {name: regionId, var: region_id}, {name: settings, var: settings}, {name: timezoneName, var: timezone_name}, {name: website, var: website}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, remove_region: $remove_region, address: $address, admin_email: $admin_email, admin_name: $admin_name, appointment_reminders: $appointment_reminders, business_hours: $business_hours, defaults: $defaults, email: $email, fax: $fax, friendly_id: $friendly_id, name: $name, phone: $phone, region_id: $region_id, settings: $settings, timezone_name: $timezone_name, website: $website
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Reminders
#
# GET /setup/v1/locations/{id}/appointmentreminders
# Returns: record<emailFirstReminder: int, emailFirstReminderInterval: int, emailSecondReminder: int, emailSecondReminderInterval: int, smsFirstReminder: int, smsFirstReminderInterval: int, smsSecondReminder: int, smsSecondReminderInterval: int>
export def "get-setup-v1-locations-id-appointmentreminders" [
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
    path: "/setup/v1/locations/{id}/appointmentreminders"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Reminders
#
# PUT /setup/v1/locations/{id}/appointmentreminders
# Returns: record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, adminEmail: string, adminName: string, appointmentReminders: record<emailFirstReminder: int, emailFirstReminderInterval: int, emailSecondReminder: int, emailSecondReminderInterval: int, smsFirstReminder: int, smsFirstReminderInterval: int, smsSecondReminder: int, smsSecondReminderInterval: int>, businessHolidays: table<businessClosed: bool, holidayName: string, id: string, publicHolidayId: int>, businessHours: record<fri: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, mon: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sat: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sun: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, thu: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, tue: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, wed: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>>, companyId: string, companyName: string, defaults: record<autoUpdateCustomer: bool, businessNotification: bool, customerCity: bool, customerState: bool, emailInfo: bool, enableUtcTimezone: bool, object: string>, email: string, fax: string, friendlyId: string, id: string, imageUrl: string, latitude: float, logo: string, longitude: float, name: string, object: string, phone: string, primaryBusiness: bool, primaryCalendarId: string, regionId: string, services: table<id: int, object: string, serviceId: int, serviceName: string>, settings: record<availabilityForm: int, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookWithAccount: bool, bookingConfirmationMessage: string, bookingMessage: string, bookingPolicy: string, bookingTimerMins: int, businessId: string, companyId: string, customerBookingsPerDay: int, customerVerification: bool, defaultService: bool, defaultToCustomerTimezone: bool, disableAuthorization: bool, enableWorldTimezones: bool, enabled: bool, familyMembersEnabled: bool, firstAvailable: bool, formFlow: int, hideBreadCrumbNav: bool, hideContinueBooking: bool, hideLocationNav: bool, hideNavBar: bool, hideServiceGroupsNav: bool, hideServicesNav: bool, id: int, lateCancelAction: int, lateCancelHours: int, lateRescheduleAction: int, lateRescheduleHours: int, liveMode: bool, locationId: string, object: string, resourceAnyLabel: string, resourceLabel: string, resourceSelection: bool, returnToAvailability: bool, returnToService: bool, serviceLabel: string, showBusinessLogo: bool, showOnSchedLogo: bool, showServiceGroups: bool>, timezoneIana: string, timezoneId: string, timezoneOffset: int, travel: record<distance: string, proximity: string, startAddress: string, startLat: string, startLon: string, units: string>, website: string>
export def "put-setup-v1-locations-id-appointmentreminders" [
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
  --email-first-reminder: int # nullable, format: int32
  --email-first-reminder-interval: int # format: int32
  --email-second-reminder: int # nullable, format: int32
  --email-second-reminder-interval: int # format: int32
  --sms-first-reminder: int # nullable, format: int32
  --sms-first-reminder-interval: int # format: int32
  --sms-second-reminder: int # nullable, format: int32
  --sms-second-reminder-interval: int # format: int32
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/setup/v1/locations/{id}/appointmentreminders"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: emailFirstReminder, var: email_first_reminder}, {name: emailFirstReminderInterval, var: email_first_reminder_interval}, {name: emailSecondReminder, var: email_second_reminder}, {name: emailSecondReminderInterval, var: email_second_reminder_interval}, {name: smsFirstReminder, var: sms_first_reminder}, {name: smsFirstReminderInterval, var: sms_first_reminder_interval}, {name: smsSecondReminder, var: sms_second_reminder}, {name: smsSecondReminderInterval, var: sms_second_reminder_interval}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, email_first_reminder: $email_first_reminder, email_first_reminder_interval: $email_first_reminder_interval, email_second_reminder: $email_second_reminder, email_second_reminder_interval: $email_second_reminder_interval, sms_first_reminder: $sms_first_reminder, sms_first_reminder_interval: $sms_first_reminder_interval, sms_second_reminder: $sms_second_reminder, sms_second_reminder_interval: $sms_second_reminder_interval
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete All Location Images
#
# DELETE /setup/v1/locations/{id}/deleteallimages
# Returns: bool
export def "delete-setup-v1-locations-id-deleteallimages" [
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
  --uppercase: oneof<nothing, bool>
]: nothing -> any {
  http-request {
    method: delete
    path: "/setup/v1/locations/{id}/deleteallimages"
    path_params: [{name: id, var: id}]
    query: [{name: uppercase, var: uppercase}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, uppercase: $uppercase
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Location Image
#
# DELETE /setup/v1/locations/{id}/deleteimage
# Returns: record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, adminEmail: string, adminName: string, appointmentReminders: record<emailFirstReminder: int, emailFirstReminderInterval: int, emailSecondReminder: int, emailSecondReminderInterval: int, smsFirstReminder: int, smsFirstReminderInterval: int, smsSecondReminder: int, smsSecondReminderInterval: int>, businessHolidays: table<businessClosed: bool, holidayName: string, id: string, publicHolidayId: int>, businessHours: record<fri: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, mon: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sat: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sun: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, thu: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, tue: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, wed: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>>, companyId: string, companyName: string, defaults: record<autoUpdateCustomer: bool, businessNotification: bool, customerCity: bool, customerState: bool, emailInfo: bool, enableUtcTimezone: bool, object: string>, email: string, fax: string, friendlyId: string, id: string, imageUrl: string, latitude: float, logo: string, longitude: float, name: string, object: string, phone: string, primaryBusiness: bool, primaryCalendarId: string, regionId: string, services: table<id: int, object: string, serviceId: int, serviceName: string>, settings: record<availabilityForm: int, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookWithAccount: bool, bookingConfirmationMessage: string, bookingMessage: string, bookingPolicy: string, bookingTimerMins: int, businessId: string, companyId: string, customerBookingsPerDay: int, customerVerification: bool, defaultService: bool, defaultToCustomerTimezone: bool, disableAuthorization: bool, enableWorldTimezones: bool, enabled: bool, familyMembersEnabled: bool, firstAvailable: bool, formFlow: int, hideBreadCrumbNav: bool, hideContinueBooking: bool, hideLocationNav: bool, hideNavBar: bool, hideServiceGroupsNav: bool, hideServicesNav: bool, id: int, lateCancelAction: int, lateCancelHours: int, lateRescheduleAction: int, lateRescheduleHours: int, liveMode: bool, locationId: string, object: string, resourceAnyLabel: string, resourceLabel: string, resourceSelection: bool, returnToAvailability: bool, returnToService: bool, serviceLabel: string, showBusinessLogo: bool, showOnSchedLogo: bool, showServiceGroups: bool>, timezoneIana: string, timezoneId: string, timezoneOffset: int, travel: record<distance: string, proximity: string, startAddress: string, startLat: string, startLon: string, units: string>, website: string>
export def "delete-setup-v1-locations-id-deleteimage" [
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
    method: delete
    path: "/setup/v1/locations/{id}/deleteimage"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Email Templates
#
# GET /setup/v1/locations/{id}/email/templates
# Returns: record<data: table<customized: bool, description: string, name: string, object: string, scope: string>, object: string, total: int, url: string>
export def "get-setup-v1-locations-id-email-templates" [
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
    path: "/setup/v1/locations/{id}/email/templates"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Custom Template
#
# POST /setup/v1/locations/{id}/email/templates
# Returns: record<content: string, contentType: string, statusCode: int>
export def "post-setup-v1-locations-id-email-templates" [
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
  --template-content: string # nullable
  --template-name: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/setup/v1/locations/{id}/email/templates"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: templateContent, var: template_content}, {name: templateName, var: template_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, template_content: $template_content, template_name: $template_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Master Template Settings
#
# DELETE /setup/v1/locations/{id}/email/templates/master
# Returns: record<centerEmailContent: bool, centerEmailContentPanel: bool, centerEmailFooter: bool, contentBackgroundColor: string, contentColor: string, contentLinkColor: string, emailBackgroundColor: string, emailColor: string, emailLinkColor: string, footerFontSize: string, footerLogoHeight: string, footerLogoPadding: string, footerPanelEmailContact: bool, footerPanelPhoneContact: bool, footerPanelWebsiteContact: bool, headerLogoHeight: string, headerLogoPadding: string, panelBackgroundColor: string, panelColor: string, panelLinkColor: string, privacyPolicyLink: string, showContentPanel: bool, showFooterLogo: bool, showFooterPanel: bool, showHeaderLogo: bool, showHeaderPanel: bool, version: string>
export def "delete-setup-v1-locations-id-email-templates-master" [
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
    method: delete
    path: "/setup/v1/locations/{id}/email/templates/master"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Master Template Settings
#
# GET /setup/v1/locations/{id}/email/templates/master
# Returns: record<centerEmailContent: bool, centerEmailContentPanel: bool, centerEmailFooter: bool, contentBackgroundColor: string, contentColor: string, contentLinkColor: string, emailBackgroundColor: string, emailColor: string, emailLinkColor: string, footerFontSize: string, footerLogoHeight: string, footerLogoPadding: string, footerPanelEmailContact: bool, footerPanelPhoneContact: bool, footerPanelWebsiteContact: bool, headerLogoHeight: string, headerLogoPadding: string, panelBackgroundColor: string, panelColor: string, panelLinkColor: string, privacyPolicyLink: string, showContentPanel: bool, showFooterLogo: bool, showFooterPanel: bool, showHeaderLogo: bool, showHeaderPanel: bool, version: string>
export def "get-setup-v1-locations-id-email-templates-master" [
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
    path: "/setup/v1/locations/{id}/email/templates/master"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Master Template Settings
#
# POST /setup/v1/locations/{id}/email/templates/master
# Returns: record<centerEmailContent: bool, centerEmailContentPanel: bool, centerEmailFooter: bool, contentBackgroundColor: string, contentColor: string, contentLinkColor: string, emailBackgroundColor: string, emailColor: string, emailLinkColor: string, footerFontSize: string, footerLogoHeight: string, footerLogoPadding: string, footerPanelEmailContact: bool, footerPanelPhoneContact: bool, footerPanelWebsiteContact: bool, headerLogoHeight: string, headerLogoPadding: string, panelBackgroundColor: string, panelColor: string, panelLinkColor: string, privacyPolicyLink: string, showContentPanel: bool, showFooterLogo: bool, showFooterPanel: bool, showHeaderLogo: bool, showHeaderPanel: bool, version: string>
export def "post-setup-v1-locations-id-email-templates-master" [
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
  --center-email-content: oneof<nothing, bool> # nullable
  --center-email-content-panel: oneof<nothing, bool> # nullable
  --center-email-footer: oneof<nothing, bool> # nullable
  --content-background-color: string # nullable
  --content-color: string # nullable
  --content-link-color: string # nullable
  --email-background-color: string # nullable
  --email-color: string # nullable
  --email-link-color: string # nullable
  --footer-font-size: string # nullable
  --footer-logo-height: string # nullable
  --footer-logo-padding: string # nullable
  --footer-panel-email-contact: oneof<nothing, bool> # nullable
  --footer-panel-phone-contact: oneof<nothing, bool> # nullable
  --footer-panel-website-contact: oneof<nothing, bool> # nullable
  --header-logo-height: string # nullable
  --header-logo-padding: string # nullable
  --panel-background-color: string # nullable
  --panel-color: string # nullable
  --panel-link-color: string # nullable
  --privacy-policy-link: string # nullable
  --show-content-panel: oneof<nothing, bool> # nullable
  --show-footer-logo: oneof<nothing, bool> # nullable
  --show-footer-panel: oneof<nothing, bool> # nullable
  --show-header-logo: oneof<nothing, bool> # nullable
  --show-header-panel: oneof<nothing, bool> # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/setup/v1/locations/{id}/email/templates/master"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: centerEmailContent, var: center_email_content}, {name: centerEmailContentPanel, var: center_email_content_panel}, {name: centerEmailFooter, var: center_email_footer}, {name: contentBackgroundColor, var: content_background_color}, {name: contentColor, var: content_color}, {name: contentLinkColor, var: content_link_color}, {name: emailBackgroundColor, var: email_background_color}, {name: emailColor, var: email_color}, {name: emailLinkColor, var: email_link_color}, {name: footerFontSize, var: footer_font_size}, {name: footerLogoHeight, var: footer_logo_height}, {name: footerLogoPadding, var: footer_logo_padding}, {name: footerPanelEmailContact, var: footer_panel_email_contact}, {name: footerPanelPhoneContact, var: footer_panel_phone_contact}, {name: footerPanelWebsiteContact, var: footer_panel_website_contact}, {name: headerLogoHeight, var: header_logo_height}, {name: headerLogoPadding, var: header_logo_padding}, {name: panelBackgroundColor, var: panel_background_color}, {name: panelColor, var: panel_color}, {name: panelLinkColor, var: panel_link_color}, {name: privacyPolicyLink, var: privacy_policy_link}, {name: showContentPanel, var: show_content_panel}, {name: showFooterLogo, var: show_footer_logo}, {name: showFooterPanel, var: show_footer_panel}, {name: showHeaderLogo, var: show_header_logo}, {name: showHeaderPanel, var: show_header_panel}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, center_email_content: $center_email_content, center_email_content_panel: $center_email_content_panel, center_email_footer: $center_email_footer, content_background_color: $content_background_color, content_color: $content_color, content_link_color: $content_link_color, email_background_color: $email_background_color, email_color: $email_color, email_link_color: $email_link_color, footer_font_size: $footer_font_size, footer_logo_height: $footer_logo_height, footer_logo_padding: $footer_logo_padding, footer_panel_email_contact: $footer_panel_email_contact, footer_panel_phone_contact: $footer_panel_phone_contact, footer_panel_website_contact: $footer_panel_website_contact, header_logo_height: $header_logo_height, header_logo_padding: $header_logo_padding, panel_background_color: $panel_background_color, panel_color: $panel_color, panel_link_color: $panel_link_color, privacy_policy_link: $privacy_policy_link, show_content_panel: $show_content_panel, show_footer_logo: $show_footer_logo, show_footer_panel: $show_footer_panel, show_header_logo: $show_header_logo, show_header_panel: $show_header_panel
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Custom Template
#
# DELETE /setup/v1/locations/{id}/email/templates/{templateName}
# Returns: record<content: string, contentType: string, statusCode: int>
export def "delete-setup-v1-locations-id-email-templates-template-name" [
  id: string
  template_name: string
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
    method: delete
    path: "/setup/v1/locations/{id}/email/templates/{templateName}"
    path_params: [{name: id, var: id}, {name: templateName, var: template_name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, template_name: $template_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Email Template
#
# GET /setup/v1/locations/{id}/email/templates/{templateName}
# Returns: record<content: string, contentType: string, statusCode: int>
export def "get-setup-v1-locations-id-email-templates-template-name" [
  id: string
  template_name: string
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
    path: "/setup/v1/locations/{id}/email/templates/{templateName}"
    path_params: [{name: id, var: id}, {name: templateName, var: template_name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, template_name: $template_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Google Cal Access
#
# DELETE /setup/v1/locations/{id}/google/service/account
export def "delete-setup-v1-locations-id-google-service-account" [
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
    path: "/setup/v1/locations/{id}/google/service/account"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Google Cal Access
#
# POST /setup/v1/locations/{id}/google/service/account
# Returns: record<auth_provider_x509_cert_url: string, auth_uri: string, client_email: string, client_id: string, client_x509_cert_url: string, private_key: string, private_key_id: string, project_id: string, token_uri: string, type: string>
export def "post-setup-v1-locations-id-google-service-account" [
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
  --auth-provider-x509-cert-url: string # nullable
  --auth-uri: string # nullable
  --client-email: string # nullable
  --client-id: string # nullable
  --client-x509-cert-url: string # nullable
  --private-key: string # nullable
  --private-key-id: string # nullable
  --project-id: string # nullable
  --token-uri: string # nullable
  --type: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/setup/v1/locations/{id}/google/service/account"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: auth_provider_x509_cert_url, var: auth_provider_x509_cert_url}, {name: auth_uri, var: auth_uri}, {name: client_email, var: client_email}, {name: client_id, var: client_id}, {name: client_x509_cert_url, var: client_x509_cert_url}, {name: private_key, var: private_key}, {name: private_key_id, var: private_key_id}, {name: project_id, var: project_id}, {name: token_uri, var: token_uri}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, auth_provider_x509_cert_url: $auth_provider_x509_cert_url, auth_uri: $auth_uri, client_email: $client_email, client_id: $client_id, client_x509_cert_url: $client_x509_cert_url, private_key: $private_key, private_key_id: $private_key_id, project_id: $project_id, token_uri: $token_uri, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Location Holidays
#
# PUT /setup/v1/locations/{id}/holidays/{holidayId}/{closed}
# Returns: record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, adminEmail: string, adminName: string, appointmentReminders: record<emailFirstReminder: int, emailFirstReminderInterval: int, emailSecondReminder: int, emailSecondReminderInterval: int, smsFirstReminder: int, smsFirstReminderInterval: int, smsSecondReminder: int, smsSecondReminderInterval: int>, businessHolidays: table<businessClosed: bool, holidayName: string, id: string, publicHolidayId: int>, businessHours: record<fri: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, mon: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sat: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sun: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, thu: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, tue: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, wed: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>>, companyId: string, companyName: string, defaults: record<autoUpdateCustomer: bool, businessNotification: bool, customerCity: bool, customerState: bool, emailInfo: bool, enableUtcTimezone: bool, object: string>, email: string, fax: string, friendlyId: string, id: string, imageUrl: string, latitude: float, logo: string, longitude: float, name: string, object: string, phone: string, primaryBusiness: bool, primaryCalendarId: string, regionId: string, services: table<id: int, object: string, serviceId: int, serviceName: string>, settings: record<availabilityForm: int, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookWithAccount: bool, bookingConfirmationMessage: string, bookingMessage: string, bookingPolicy: string, bookingTimerMins: int, businessId: string, companyId: string, customerBookingsPerDay: int, customerVerification: bool, defaultService: bool, defaultToCustomerTimezone: bool, disableAuthorization: bool, enableWorldTimezones: bool, enabled: bool, familyMembersEnabled: bool, firstAvailable: bool, formFlow: int, hideBreadCrumbNav: bool, hideContinueBooking: bool, hideLocationNav: bool, hideNavBar: bool, hideServiceGroupsNav: bool, hideServicesNav: bool, id: int, lateCancelAction: int, lateCancelHours: int, lateRescheduleAction: int, lateRescheduleHours: int, liveMode: bool, locationId: string, object: string, resourceAnyLabel: string, resourceLabel: string, resourceSelection: bool, returnToAvailability: bool, returnToService: bool, serviceLabel: string, showBusinessLogo: bool, showOnSchedLogo: bool, showServiceGroups: bool>, timezoneIana: string, timezoneId: string, timezoneOffset: int, travel: record<distance: string, proximity: string, startAddress: string, startLat: string, startLon: string, units: string>, website: string>
export def "put-setup-v1-locations-id-holidays-holiday-id-closed" [
  id: string
  holiday_id: string
  closed: bool
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
    method: put
    path: "/setup/v1/locations/{id}/holidays/{holidayId}/{closed}"
    path_params: [{name: id, var: id}, {name: holidayId, var: holiday_id}, {name: closed, var: closed}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, holiday_id: $holiday_id, closed: $closed
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Recover Location
#
# PUT /setup/v1/locations/{id}/recover
# Returns: record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, adminEmail: string, adminName: string, appointmentReminders: record<emailFirstReminder: int, emailFirstReminderInterval: int, emailSecondReminder: int, emailSecondReminderInterval: int, smsFirstReminder: int, smsFirstReminderInterval: int, smsSecondReminder: int, smsSecondReminderInterval: int>, businessHolidays: table<businessClosed: bool, holidayName: string, id: string, publicHolidayId: int>, businessHours: record<fri: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, mon: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sat: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sun: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, thu: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, tue: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, wed: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>>, companyId: string, companyName: string, defaults: record<autoUpdateCustomer: bool, businessNotification: bool, customerCity: bool, customerState: bool, emailInfo: bool, enableUtcTimezone: bool, object: string>, email: string, fax: string, friendlyId: string, id: string, imageUrl: string, latitude: float, logo: string, longitude: float, name: string, object: string, phone: string, primaryBusiness: bool, primaryCalendarId: string, regionId: string, services: table<id: int, object: string, serviceId: int, serviceName: string>, settings: record<availabilityForm: int, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookWithAccount: bool, bookingConfirmationMessage: string, bookingMessage: string, bookingPolicy: string, bookingTimerMins: int, businessId: string, companyId: string, customerBookingsPerDay: int, customerVerification: bool, defaultService: bool, defaultToCustomerTimezone: bool, disableAuthorization: bool, enableWorldTimezones: bool, enabled: bool, familyMembersEnabled: bool, firstAvailable: bool, formFlow: int, hideBreadCrumbNav: bool, hideContinueBooking: bool, hideLocationNav: bool, hideNavBar: bool, hideServiceGroupsNav: bool, hideServicesNav: bool, id: int, lateCancelAction: int, lateCancelHours: int, lateRescheduleAction: int, lateRescheduleHours: int, liveMode: bool, locationId: string, object: string, resourceAnyLabel: string, resourceLabel: string, resourceSelection: bool, returnToAvailability: bool, returnToService: bool, serviceLabel: string, showBusinessLogo: bool, showOnSchedLogo: bool, showServiceGroups: bool>, timezoneIana: string, timezoneId: string, timezoneOffset: int, travel: record<distance: string, proximity: string, startAddress: string, startLat: string, startLon: string, units: string>, website: string>
export def "put-setup-v1-locations-id-recover" [
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
    method: put
    path: "/setup/v1/locations/{id}/recover"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Linked Services
#
# DELETE /setup/v1/locations/{id}/services
# Returns: record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, adminEmail: string, adminName: string, appointmentReminders: record<emailFirstReminder: int, emailFirstReminderInterval: int, emailSecondReminder: int, emailSecondReminderInterval: int, smsFirstReminder: int, smsFirstReminderInterval: int, smsSecondReminder: int, smsSecondReminderInterval: int>, businessHolidays: table<businessClosed: bool, holidayName: string, id: string, publicHolidayId: int>, businessHours: record<fri: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, mon: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sat: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sun: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, thu: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, tue: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, wed: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>>, companyId: string, companyName: string, defaults: record<autoUpdateCustomer: bool, businessNotification: bool, customerCity: bool, customerState: bool, emailInfo: bool, enableUtcTimezone: bool, object: string>, email: string, fax: string, friendlyId: string, id: string, imageUrl: string, latitude: float, logo: string, longitude: float, name: string, object: string, phone: string, primaryBusiness: bool, primaryCalendarId: string, regionId: string, services: table<id: int, object: string, serviceId: int, serviceName: string>, settings: record<availabilityForm: int, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookWithAccount: bool, bookingConfirmationMessage: string, bookingMessage: string, bookingPolicy: string, bookingTimerMins: int, businessId: string, companyId: string, customerBookingsPerDay: int, customerVerification: bool, defaultService: bool, defaultToCustomerTimezone: bool, disableAuthorization: bool, enableWorldTimezones: bool, enabled: bool, familyMembersEnabled: bool, firstAvailable: bool, formFlow: int, hideBreadCrumbNav: bool, hideContinueBooking: bool, hideLocationNav: bool, hideNavBar: bool, hideServiceGroupsNav: bool, hideServicesNav: bool, id: int, lateCancelAction: int, lateCancelHours: int, lateRescheduleAction: int, lateRescheduleHours: int, liveMode: bool, locationId: string, object: string, resourceAnyLabel: string, resourceLabel: string, resourceSelection: bool, returnToAvailability: bool, returnToService: bool, serviceLabel: string, showBusinessLogo: bool, showOnSchedLogo: bool, showServiceGroups: bool>, timezoneIana: string, timezoneId: string, timezoneOffset: int, travel: record<distance: string, proximity: string, startAddress: string, startLat: string, startLon: string, units: string>, website: string>
export def "delete-setup-v1-locations-id-services" [
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
    method: delete
    path: "/setup/v1/locations/{id}/services"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Location Linked Services
#
# GET /setup/v1/locations/{id}/services
# Returns: record<count: int, data: table<id: int, object: string, serviceId: int, serviceName: string>, hasMore: bool, object: string, total: int, url: string>
export def "get-setup-v1-locations-id-services" [
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
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit default 20, max 100 (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/setup/v1/locations/{id}/services"
    path_params: [{name: id, var: id}]
    query: [{name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Linked Service
#
# POST /setup/v1/locations/{id}/services
# Returns: record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, adminEmail: string, adminName: string, appointmentReminders: record<emailFirstReminder: int, emailFirstReminderInterval: int, emailSecondReminder: int, emailSecondReminderInterval: int, smsFirstReminder: int, smsFirstReminderInterval: int, smsSecondReminder: int, smsSecondReminderInterval: int>, businessHolidays: table<businessClosed: bool, holidayName: string, id: string, publicHolidayId: int>, businessHours: record<fri: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, mon: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sat: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sun: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, thu: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, tue: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, wed: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>>, companyId: string, companyName: string, defaults: record<autoUpdateCustomer: bool, businessNotification: bool, customerCity: bool, customerState: bool, emailInfo: bool, enableUtcTimezone: bool, object: string>, email: string, fax: string, friendlyId: string, id: string, imageUrl: string, latitude: float, logo: string, longitude: float, name: string, object: string, phone: string, primaryBusiness: bool, primaryCalendarId: string, regionId: string, services: table<id: int, object: string, serviceId: int, serviceName: string>, settings: record<availabilityForm: int, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookWithAccount: bool, bookingConfirmationMessage: string, bookingMessage: string, bookingPolicy: string, bookingTimerMins: int, businessId: string, companyId: string, customerBookingsPerDay: int, customerVerification: bool, defaultService: bool, defaultToCustomerTimezone: bool, disableAuthorization: bool, enableWorldTimezones: bool, enabled: bool, familyMembersEnabled: bool, firstAvailable: bool, formFlow: int, hideBreadCrumbNav: bool, hideContinueBooking: bool, hideLocationNav: bool, hideNavBar: bool, hideServiceGroupsNav: bool, hideServicesNav: bool, id: int, lateCancelAction: int, lateCancelHours: int, lateRescheduleAction: int, lateRescheduleHours: int, liveMode: bool, locationId: string, object: string, resourceAnyLabel: string, resourceLabel: string, resourceSelection: bool, returnToAvailability: bool, returnToService: bool, serviceLabel: string, showBusinessLogo: bool, showOnSchedLogo: bool, showServiceGroups: bool>, timezoneIana: string, timezoneId: string, timezoneOffset: int, travel: record<distance: string, proximity: string, startAddress: string, startLat: string, startLon: string, units: string>, website: string>
export def "post-setup-v1-locations-id-services" [
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
  --body: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/setup/v1/locations/{id}/services"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Location Scope
#
# PUT /setup/v1/locations/{id}/settings/scope/{settingsScope}
# Returns: record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, adminEmail: string, adminName: string, appointmentReminders: record<emailFirstReminder: int, emailFirstReminderInterval: int, emailSecondReminder: int, emailSecondReminderInterval: int, smsFirstReminder: int, smsFirstReminderInterval: int, smsSecondReminder: int, smsSecondReminderInterval: int>, businessHolidays: table<businessClosed: bool, holidayName: string, id: string, publicHolidayId: int>, businessHours: record<fri: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, mon: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sat: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sun: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, thu: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, tue: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, wed: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>>, companyId: string, companyName: string, defaults: record<autoUpdateCustomer: bool, businessNotification: bool, customerCity: bool, customerState: bool, emailInfo: bool, enableUtcTimezone: bool, object: string>, email: string, fax: string, friendlyId: string, id: string, imageUrl: string, latitude: float, logo: string, longitude: float, name: string, object: string, phone: string, primaryBusiness: bool, primaryCalendarId: string, regionId: string, services: table<id: int, object: string, serviceId: int, serviceName: string>, settings: record<availabilityForm: int, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookWithAccount: bool, bookingConfirmationMessage: string, bookingMessage: string, bookingPolicy: string, bookingTimerMins: int, businessId: string, companyId: string, customerBookingsPerDay: int, customerVerification: bool, defaultService: bool, defaultToCustomerTimezone: bool, disableAuthorization: bool, enableWorldTimezones: bool, enabled: bool, familyMembersEnabled: bool, firstAvailable: bool, formFlow: int, hideBreadCrumbNav: bool, hideContinueBooking: bool, hideLocationNav: bool, hideNavBar: bool, hideServiceGroupsNav: bool, hideServicesNav: bool, id: int, lateCancelAction: int, lateCancelHours: int, lateRescheduleAction: int, lateRescheduleHours: int, liveMode: bool, locationId: string, object: string, resourceAnyLabel: string, resourceLabel: string, resourceSelection: bool, returnToAvailability: bool, returnToService: bool, serviceLabel: string, showBusinessLogo: bool, showOnSchedLogo: bool, showServiceGroups: bool>, timezoneIana: string, timezoneId: string, timezoneOffset: int, travel: record<distance: string, proximity: string, startAddress: string, startLat: string, startLon: string, units: string>, website: string>
export def "put-setup-v1-locations-id-settings-scope-settings-scope" [
  id: string
  settings_scope: string
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
    method: put
    path: "/setup/v1/locations/{id}/settings/scope/{settingsScope}"
    path_params: [{name: id, var: id}, {name: settingsScope, var: settings_scope}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, settings_scope: $settings_scope
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload Location Image
#
# POST /setup/v1/locations/{id}/uploadimage
# Returns: record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, adminEmail: string, adminName: string, appointmentReminders: record<emailFirstReminder: int, emailFirstReminderInterval: int, emailSecondReminder: int, emailSecondReminderInterval: int, smsFirstReminder: int, smsFirstReminderInterval: int, smsSecondReminder: int, smsSecondReminderInterval: int>, businessHolidays: table<businessClosed: bool, holidayName: string, id: string, publicHolidayId: int>, businessHours: record<fri: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, mon: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sat: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sun: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, thu: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, tue: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, wed: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>>, companyId: string, companyName: string, defaults: record<autoUpdateCustomer: bool, businessNotification: bool, customerCity: bool, customerState: bool, emailInfo: bool, enableUtcTimezone: bool, object: string>, email: string, fax: string, friendlyId: string, id: string, imageUrl: string, latitude: float, logo: string, longitude: float, name: string, object: string, phone: string, primaryBusiness: bool, primaryCalendarId: string, regionId: string, services: table<id: int, object: string, serviceId: int, serviceName: string>, settings: record<availabilityForm: int, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookWithAccount: bool, bookingConfirmationMessage: string, bookingMessage: string, bookingPolicy: string, bookingTimerMins: int, businessId: string, companyId: string, customerBookingsPerDay: int, customerVerification: bool, defaultService: bool, defaultToCustomerTimezone: bool, disableAuthorization: bool, enableWorldTimezones: bool, enabled: bool, familyMembersEnabled: bool, firstAvailable: bool, formFlow: int, hideBreadCrumbNav: bool, hideContinueBooking: bool, hideLocationNav: bool, hideNavBar: bool, hideServiceGroupsNav: bool, hideServicesNav: bool, id: int, lateCancelAction: int, lateCancelHours: int, lateRescheduleAction: int, lateRescheduleHours: int, liveMode: bool, locationId: string, object: string, resourceAnyLabel: string, resourceLabel: string, resourceSelection: bool, returnToAvailability: bool, returnToService: bool, serviceLabel: string, showBusinessLogo: bool, showOnSchedLogo: bool, showServiceGroups: bool>, timezoneIana: string, timezoneId: string, timezoneOffset: int, travel: record<distance: string, proximity: string, startAddress: string, startLat: string, startLon: string, units: string>, website: string>
export def "post-setup-v1-locations-id-uploadimage" [
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
  --image-file-data: string # nullable
  --image-file-name: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/setup/v1/locations/{id}/uploadimage"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: imageFileData, var: image_file_data}, {name: imageFileName, var: image_file_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, image_file_data: $image_file_data, image_file_name: $image_file_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Resource Groups
#
# GET /setup/v1/resourcegroups
# Returns: record<count: int, data: table<bookingNotification: int, deletedStatus: bool, deletedTime: string, description: string, email: string, id: string, locationId: string, name: string, object: string>, hasMore: bool, object: string, total: int, url: string>
export def "get-setup-v1-resourcegroups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --location-id: string # id of business location, defaults to primary business location
  --deleted: oneof<nothing, bool> # Filter results by deleted status
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit default 20, max 100 (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/setup/v1/resourcegroups"
    query: [{name: locationId, var: location_id}, {name: deleted, var: deleted}, {name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    location_id: $location_id, deleted: $deleted, offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Resource Group
#
# POST /setup/v1/resourcegroups
# Returns: record<bookingNotification: int, deletedStatus: bool, deletedTime: string, description: string, email: string, id: string, locationId: string, name: string, object: string>
export def "post-setup-v1-resourcegroups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # nullable
  --email: string # nullable
  --location-id: string # nullable
  --name: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/setup/v1/resourcegroups"
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: email, var: email}, {name: locationId, var: location_id}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    description: $description, email: $email, location_id: $location_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Resource Group
#
# DELETE /setup/v1/resourcegroups/{id}
# Returns: record<bookingNotification: int, deletedStatus: bool, deletedTime: string, description: string, email: string, id: string, locationId: string, name: string, object: string>
export def "delete-setup-v1-resourcegroups-id" [
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
    method: delete
    path: "/setup/v1/resourcegroups/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Resource Group
#
# GET /setup/v1/resourcegroups/{id}
# Returns: record<bookingNotification: int, deletedStatus: bool, deletedTime: string, description: string, email: string, id: string, locationId: string, name: string, object: string>
export def "get-setup-v1-resourcegroups-id" [
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
    path: "/setup/v1/resourcegroups/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Resource Group
#
# PUT /setup/v1/resourcegroups/{id}
# Returns: record<bookingNotification: int, deletedStatus: bool, deletedTime: string, description: string, email: string, id: string, locationId: string, name: string, object: string>
export def "put-setup-v1-resourcegroups-id" [
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
  --description: string # nullable
  --email: string # nullable
  --name: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/setup/v1/resourcegroups/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: email, var: email}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, description: $description, email: $email, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Recover Resource Group
#
# PUT /setup/v1/resourcegroups/{id}/recover
# Returns: record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bioLink: string, bookingNotification: int, calendarAvailability: int, contact: record<businessPhone: string, businessPhoneExt: string, conferenceInfo: string, homePhone: string, mobilePhone: string, phoneType: string, skypeUsername: string>, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, deletedStatus: bool, deletedTime: string, description: string, effectiveDate: string, email: string, gender: string, googleCalendarAuthUrl: string, googleCalendarAuthorized: bool, googleCalendarId: string, groupId: int, hourly: float, id: string, ignoreBusinessHours: bool, imageUrl: string, locationId: string, name: string, notificationType: int, object: string, options: record<bioLink: string, bookingNotification: int, calendarAvailability: int, displayColor: string, effectiveDate: string, gender: string, googleCalendarId: string, hourly: float, ignoreBusinessHours: bool, notificationType: int, outlookCalendarId: string, sortKey: int>, outlookCalendarAuthUrl: string, outlookCalendarAuthorized: bool, outlookCalendarId: string, phone: record<businessPhone: string, businessPhoneExt: string, homePhone: string, mobilePhone: string, phoneType: string>, recurringAvailability: bool, services: table<object: string, serviceId: int, serviceName: string>, skypeName: string, sortKey: int, timezoneIana: string, timezoneId: string, timezoneOffset: int>
export def "put-setup-v1-resourcegroups-id-recover" [
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
    method: put
    path: "/setup/v1/resourcegroups/{id}/recover"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Resources
#
# GET /setup/v1/resources
# Returns: record<count: int, data: table<address: record, availability: record, bioLink: string, bookingNotification: int, calendarAvailability: int, contact: record, customFields: record, deletedStatus: bool, deletedTime: string, description: string, effectiveDate: string, email: string, gender: string, googleCalendarAuthUrl: string, googleCalendarAuthorized: bool, googleCalendarId: string, groupId: int, hourly: float, id: string, ignoreBusinessHours: bool, imageUrl: string, locationId: string, name: string, notificationType: int, object: string, options: record, outlookCalendarAuthUrl: string, outlookCalendarAuthorized: bool, outlookCalendarId: string, phone: record, recurringAvailability: bool, services: list, skypeName: string, sortKey: int, timezoneIana: string, timezoneId: string, timezoneOffset: int>, hasMore: bool, object: string, total: int, url: string>
export def "get-setup-v1-resources" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --location-id: string # id of business location, defaults to primary business location
  --resource-group-id: string # Filter by group Id
  --email: string # Filter by email address
  --name: string # Search by name
  --deleted: oneof<nothing, bool> # Show by deleted status, default is false
  --google-auth-return-url: string # Google calendar authorization return url
  --outlook-auth-return-url: string # Outlook calendar authorization return url
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit default 20, max is 100 (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/setup/v1/resources"
    query: [{name: locationId, var: location_id}, {name: resourceGroupId, var: resource_group_id}, {name: email, var: email}, {name: name, var: name}, {name: deleted, var: deleted}, {name: googleAuthReturnUrl, var: google_auth_return_url}, {name: outlookAuthReturnUrl, var: outlook_auth_return_url}, {name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    location_id: $location_id, resource_group_id: $resource_group_id, email: $email, name: $name, deleted: $deleted, google_auth_return_url: $google_auth_return_url, outlook_auth_return_url: $outlook_auth_return_url, offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Resource
#
# POST /setup/v1/resources
# Returns: record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bioLink: string, bookingNotification: int, calendarAvailability: int, contact: record<businessPhone: string, businessPhoneExt: string, conferenceInfo: string, homePhone: string, mobilePhone: string, phoneType: string, skypeUsername: string>, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, deletedStatus: bool, deletedTime: string, description: string, effectiveDate: string, email: string, gender: string, googleCalendarAuthUrl: string, googleCalendarAuthorized: bool, googleCalendarId: string, groupId: int, hourly: float, id: string, ignoreBusinessHours: bool, imageUrl: string, locationId: string, name: string, notificationType: int, object: string, options: record<bioLink: string, bookingNotification: int, calendarAvailability: int, displayColor: string, effectiveDate: string, gender: string, googleCalendarId: string, hourly: float, ignoreBusinessHours: bool, notificationType: int, outlookCalendarId: string, sortKey: int>, outlookCalendarAuthUrl: string, outlookCalendarAuthorized: bool, outlookCalendarId: string, phone: record<businessPhone: string, businessPhoneExt: string, homePhone: string, mobilePhone: string, phoneType: string>, recurringAvailability: bool, services: table<object: string, serviceId: int, serviceName: string>, skypeName: string, sortKey: int, timezoneIana: string, timezoneId: string, timezoneOffset: int>
export def "post-setup-v1-resources" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --google-auth-return-url: string # Google calendar authorization return url
  --outlook-auth-return-url: string # Outlook calendar authorization return url
  --address: record # shape: {addressLine1?: string, addressLine2?: string, city?: string, country?: string, postalCode?: string, state?: string}
  --availability: record # shape: {fri?: record, mon?: record, sat?: record, sun?: record, thu?: record, tue?: record, wed?: record}
  --contact: record # shape: {businessPhone?: string, businessPhoneExt?: string, conferenceInfo?: string, homePhone?: string, mobilePhone?: string, preferredPhoneType?: string, skypeUsername?: string}
  --custom-fields: record # shape: {field1?: string, field10?: string, field2?: string, field3?: string, field4?: string, field5?: string, field6?: string, field7?: string, field8?: string, field9?: string}
  --description: string # nullable
  --email: string # nullable
  --group-id: string # nullable
  --location-id: string # nullable
  --name: string # nullable
  --options: record # Options for the new resource — shape: {bioLink?: string, bookingNotification?: int, calendarAvailability?: int, displayColor?: string, effectiveDate?: string, gender?: string, googleCalendarId?: string, hourly?: float, ignoreBusinessHours?: bool, notificationType?: int, outlookCalendarId?: string, sortKey?: int}
  --recurring-availability: oneof<nothing, bool> # nullable
  --service-ids: list<string> # nullable
  --timezone-id: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/setup/v1/resources"
    query: [{name: googleAuthReturnUrl, var: google_auth_return_url}, {name: outlookAuthReturnUrl, var: outlook_auth_return_url}]
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: availability, var: availability}, {name: contact, var: contact}, {name: customFields, var: custom_fields}, {name: description, var: description}, {name: email, var: email}, {name: groupId, var: group_id}, {name: locationId, var: location_id}, {name: name, var: name}, {name: options, var: options}, {name: recurringAvailability, var: recurring_availability}, {name: serviceIds, var: service_ids}, {name: timezoneId, var: timezone_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    google_auth_return_url: $google_auth_return_url, outlook_auth_return_url: $outlook_auth_return_url, address: $address, availability: $availability, contact: $contact, custom_fields: $custom_fields, description: $description, email: $email, group_id: $group_id, location_id: $location_id, name: $name, options: $options, recurring_availability: $recurring_availability, service_ids: $service_ids, timezone_id: $timezone_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Allocation
#
# DELETE /setup/v1/resources/allocations/{id}
# Returns: record<businessId: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: int, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, resourceId: int, startDate: string, startTime: int>
export def "delete-setup-v1-resources-allocations-id" [
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
    method: delete
    path: "/setup/v1/resources/allocations/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Allocation
#
# GET /setup/v1/resources/allocations/{id}
# Returns: record<businessId: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: int, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, resourceId: int, startDate: string, startTime: int>
export def "get-setup-v1-resources-allocations-id" [
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
    path: "/setup/v1/resources/allocations/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Allocation
#
# PUT /setup/v1/resources/allocations/{id}
# Returns: record<businessId: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: int, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, resourceId: int, startDate: string, startTime: int>
export def "put-setup-v1-resources-allocations-id" [
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
  --end-date: string # nullable, format: date
  --end-time: int # nullable, format: int32
  --reason: string # nullable
  --repeat: record # shape: {frequency?: string, interval?: int, monthDay?: int, monthType?: string, weekdays?: string}
  --repeats: oneof<nothing, bool> # nullable
  --start-date: string # nullable, format: date
  --start-time: int # nullable, format: int32
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/setup/v1/resources/allocations/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: endDate, var: end_date}, {name: endTime, var: end_time}, {name: reason, var: reason}, {name: repeat, var: repeat}, {name: repeats, var: repeats}, {name: startDate, var: start_date}, {name: startTime, var: start_time}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, end_date: $end_date, end_time: $end_time, reason: $reason, repeat: $repeat, repeats: $repeats, start_date: $start_date, start_time: $start_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Block
#
# DELETE /setup/v1/resources/block/{id}
# Returns: record<businessId: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: int, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, resourceId: int, startDate: string, startTime: int>
export def "delete-setup-v1-resources-block-id" [
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
    method: delete
    path: "/setup/v1/resources/block/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Block
#
# PUT /setup/v1/resources/block/{id}
# Returns: record<businessId: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: int, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, resourceId: int, startDate: string, startTime: int>
export def "put-setup-v1-resources-block-id" [
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
  --all-day: oneof<nothing, bool> # nullable
  --end-date: string # nullable, format: date
  --end-time: int # nullable, format: int32
  --reason: string # nullable
  --repeat: record # shape: {frequency?: string, interval?: int, monthDay?: int, monthType?: string, weekdays?: string}
  --repeats: oneof<nothing, bool> # nullable
  --start-date: string # nullable, format: date
  --start-time: int # nullable, format: int32
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/setup/v1/resources/block/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: allDay, var: all_day}, {name: endDate, var: end_date}, {name: endTime, var: end_time}, {name: reason, var: reason}, {name: repeat, var: repeat}, {name: repeats, var: repeats}, {name: startDate, var: start_date}, {name: startTime, var: start_time}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, all_day: $all_day, end_date: $end_date, end_time: $end_time, reason: $reason, repeat: $repeat, repeats: $repeats, start_date: $start_date, start_time: $start_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Block
#
# GET /setup/v1/resources/blocks/{id}
# Returns: record<businessId: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: int, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, resourceId: int, startDate: string, startTime: int>
export def "get-setup-v1-resources-blocks-id" [
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
    path: "/setup/v1/resources/blocks/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Resources Bulk
#
# POST /setup/v1/resources/bulk
# Returns: table<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, availability: record<fri: record, mon: record, sat: record, sun: record, thu: record, tue: record, wed: record>, bioLink: string, bookingNotification: int, calendarAvailability: int, contact: record<businessPhone: string, businessPhoneExt: string, conferenceInfo: string, homePhone: string, mobilePhone: string, phoneType: string, skypeUsername: string>, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, deletedStatus: bool, deletedTime: string, description: string, effectiveDate: string, email: string, gender: string, googleCalendarAuthUrl: string, googleCalendarAuthorized: bool, googleCalendarId: string, groupId: int, hourly: float, id: string, ignoreBusinessHours: bool, imageUrl: string, locationId: string, name: string, notificationType: int, object: string, options: record<bioLink: string, bookingNotification: int, calendarAvailability: int, displayColor: string, effectiveDate: string, gender: string, googleCalendarId: string, hourly: float, ignoreBusinessHours: bool, notificationType: int, outlookCalendarId: string, sortKey: int>, outlookCalendarAuthUrl: string, outlookCalendarAuthorized: bool, outlookCalendarId: string, phone: record<businessPhone: string, businessPhoneExt: string, homePhone: string, mobilePhone: string, phoneType: string>, recurringAvailability: bool, services: list<record>, skypeName: string, sortKey: int, timezoneIana: string, timezoneId: string, timezoneOffset: int>
export def "post-setup-v1-resources-bulk" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --google-auth-return-url: string # Google calendar authorization return url
  --outlook-auth-return-url: string # Outlook calendar authorization return url
  --resources: list # nullable — item shape: {address?: record, availability?: record, contact?: record, customFields?: record, description?: string, email?: string, groupId?: string, locationId?: string, name?: string, options?: record, recurringAvailability?: bool, serviceIds?: list<string>, timezoneId?: string}
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/setup/v1/resources/bulk"
    query: [{name: googleAuthReturnUrl, var: google_auth_return_url}, {name: outlookAuthReturnUrl, var: outlook_auth_return_url}]
    body: {content_type: "application/json", kind: json, fields: [{name: resources, var: resources}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    google_auth_return_url: $google_auth_return_url, outlook_auth_return_url: $outlook_auth_return_url, resources: $resources
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Resources Bulk
#
# PUT /setup/v1/resources/bulk
# Returns: table<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, availability: record<fri: record, mon: record, sat: record, sun: record, thu: record, tue: record, wed: record>, bioLink: string, bookingNotification: int, calendarAvailability: int, contact: record<businessPhone: string, businessPhoneExt: string, conferenceInfo: string, homePhone: string, mobilePhone: string, phoneType: string, skypeUsername: string>, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, deletedStatus: bool, deletedTime: string, description: string, effectiveDate: string, email: string, gender: string, googleCalendarAuthUrl: string, googleCalendarAuthorized: bool, googleCalendarId: string, groupId: int, hourly: float, id: string, ignoreBusinessHours: bool, imageUrl: string, locationId: string, name: string, notificationType: int, object: string, options: record<bioLink: string, bookingNotification: int, calendarAvailability: int, displayColor: string, effectiveDate: string, gender: string, googleCalendarId: string, hourly: float, ignoreBusinessHours: bool, notificationType: int, outlookCalendarId: string, sortKey: int>, outlookCalendarAuthUrl: string, outlookCalendarAuthorized: bool, outlookCalendarId: string, phone: record<businessPhone: string, businessPhoneExt: string, homePhone: string, mobilePhone: string, phoneType: string>, recurringAvailability: bool, services: list<record>, skypeName: string, sortKey: int, timezoneIana: string, timezoneId: string, timezoneOffset: int>
export def "put-setup-v1-resources-bulk" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --google-auth-return-url: string # Google calendar authorization return url
  --outlook-auth-return-url: string # Outlook calendar authorization return url
  --resources: list # nullable — item shape: {address?: record, availability?: record, contact?: record, customFields?: record, description?: string, email?: string, groupId?: string, id?: string, name?: string, options?: record, recurringAvailability?: bool, serviceIds?: list<string>, timezoneId?: string}
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: put
    path: "/setup/v1/resources/bulk"
    query: [{name: googleAuthReturnUrl, var: google_auth_return_url}, {name: outlookAuthReturnUrl, var: outlook_auth_return_url}]
    body: {content_type: "application/json", kind: json, fields: [{name: resources, var: resources}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    google_auth_return_url: $google_auth_return_url, outlook_auth_return_url: $outlook_auth_return_url, resources: $resources
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Time Zones
#
# GET /setup/v1/resources/timezones
# Returns: record<baseUtcOffset: int, daylightName: string, displayName: string, standardName: string, supportsDaylightSavingTime: bool, timezoneIana: string, timezoneId: string>
export def "get-setup-v1-resources-timezones" [
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
    path: "/setup/v1/resources/timezones"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Resource
#
# DELETE /setup/v1/resources/{id}
# Returns: record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bioLink: string, bookingNotification: int, calendarAvailability: int, contact: record<businessPhone: string, businessPhoneExt: string, conferenceInfo: string, homePhone: string, mobilePhone: string, phoneType: string, skypeUsername: string>, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, deletedStatus: bool, deletedTime: string, description: string, effectiveDate: string, email: string, gender: string, googleCalendarAuthUrl: string, googleCalendarAuthorized: bool, googleCalendarId: string, groupId: int, hourly: float, id: string, ignoreBusinessHours: bool, imageUrl: string, locationId: string, name: string, notificationType: int, object: string, options: record<bioLink: string, bookingNotification: int, calendarAvailability: int, displayColor: string, effectiveDate: string, gender: string, googleCalendarId: string, hourly: float, ignoreBusinessHours: bool, notificationType: int, outlookCalendarId: string, sortKey: int>, outlookCalendarAuthUrl: string, outlookCalendarAuthorized: bool, outlookCalendarId: string, phone: record<businessPhone: string, businessPhoneExt: string, homePhone: string, mobilePhone: string, phoneType: string>, recurringAvailability: bool, services: table<object: string, serviceId: int, serviceName: string>, skypeName: string, sortKey: int, timezoneIana: string, timezoneId: string, timezoneOffset: int>
export def "delete-setup-v1-resources-id" [
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
    method: delete
    path: "/setup/v1/resources/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Resource
#
# GET /setup/v1/resources/{id}
# Returns: record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bioLink: string, bookingNotification: int, calendarAvailability: int, contact: record<businessPhone: string, businessPhoneExt: string, conferenceInfo: string, homePhone: string, mobilePhone: string, phoneType: string, skypeUsername: string>, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, deletedStatus: bool, deletedTime: string, description: string, effectiveDate: string, email: string, gender: string, googleCalendarAuthUrl: string, googleCalendarAuthorized: bool, googleCalendarId: string, groupId: int, hourly: float, id: string, ignoreBusinessHours: bool, imageUrl: string, locationId: string, name: string, notificationType: int, object: string, options: record<bioLink: string, bookingNotification: int, calendarAvailability: int, displayColor: string, effectiveDate: string, gender: string, googleCalendarId: string, hourly: float, ignoreBusinessHours: bool, notificationType: int, outlookCalendarId: string, sortKey: int>, outlookCalendarAuthUrl: string, outlookCalendarAuthorized: bool, outlookCalendarId: string, phone: record<businessPhone: string, businessPhoneExt: string, homePhone: string, mobilePhone: string, phoneType: string>, recurringAvailability: bool, services: table<object: string, serviceId: int, serviceName: string>, skypeName: string, sortKey: int, timezoneIana: string, timezoneId: string, timezoneOffset: int>
export def "get-setup-v1-resources-id" [
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
  --google-auth-return-url: string # Google calendar authorization return url
  --outlook-auth-return-url: string # Outlook calendar authorization return url
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/setup/v1/resources/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: googleAuthReturnUrl, var: google_auth_return_url}, {name: outlookAuthReturnUrl, var: outlook_auth_return_url}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, google_auth_return_url: $google_auth_return_url, outlook_auth_return_url: $outlook_auth_return_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Resource
#
# PUT /setup/v1/resources/{id}
# Returns: record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bioLink: string, bookingNotification: int, calendarAvailability: int, contact: record<businessPhone: string, businessPhoneExt: string, conferenceInfo: string, homePhone: string, mobilePhone: string, phoneType: string, skypeUsername: string>, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, deletedStatus: bool, deletedTime: string, description: string, effectiveDate: string, email: string, gender: string, googleCalendarAuthUrl: string, googleCalendarAuthorized: bool, googleCalendarId: string, groupId: int, hourly: float, id: string, ignoreBusinessHours: bool, imageUrl: string, locationId: string, name: string, notificationType: int, object: string, options: record<bioLink: string, bookingNotification: int, calendarAvailability: int, displayColor: string, effectiveDate: string, gender: string, googleCalendarId: string, hourly: float, ignoreBusinessHours: bool, notificationType: int, outlookCalendarId: string, sortKey: int>, outlookCalendarAuthUrl: string, outlookCalendarAuthorized: bool, outlookCalendarId: string, phone: record<businessPhone: string, businessPhoneExt: string, homePhone: string, mobilePhone: string, phoneType: string>, recurringAvailability: bool, services: table<object: string, serviceId: int, serviceName: string>, skypeName: string, sortKey: int, timezoneIana: string, timezoneId: string, timezoneOffset: int>
export def "put-setup-v1-resources-id" [
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
  --google-auth-return-url: string # Google calendar authorization return url
  --outlook-auth-return-url: string # Outlook calendar authorization return url
  --address: record # shape: {addressLine1?: string, addressLine2?: string, city?: string, country?: string, postalCode?: string, state?: string}
  --availability: record # shape: {fri?: record, mon?: record, sat?: record, sun?: record, thu?: record, tue?: record, wed?: record}
  --contact: record # shape: {businessPhone?: string, businessPhoneExt?: string, conferenceInfo?: string, homePhone?: string, mobilePhone?: string, preferredPhoneType?: string, skypeUsername?: string}
  --custom-fields: record # shape: {field1?: string, field10?: string, field2?: string, field3?: string, field4?: string, field5?: string, field6?: string, field7?: string, field8?: string, field9?: string}
  --description: string # nullable
  --email: string # nullable
  --group-id: string # nullable
  --location-id: string # nullable
  --name: string # nullable
  --options: record # shape: {bioLink?: string, bookingNotification?: int, calendarAvailability?: int, displayColor?: string, effectiveDate?: string, gender?: string, googleCalendarId?: string, hourly?: float, ignoreBusinessHours?: bool, notificationType?: int, outlookCalendarId?: string, sortKey?: int}
  --recurring-availability: oneof<nothing, bool> # nullable
  --service-ids: list<string> # nullable
  --timezone-id: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/setup/v1/resources/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: googleAuthReturnUrl, var: google_auth_return_url}, {name: outlookAuthReturnUrl, var: outlook_auth_return_url}]
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: availability, var: availability}, {name: contact, var: contact}, {name: customFields, var: custom_fields}, {name: description, var: description}, {name: email, var: email}, {name: groupId, var: group_id}, {name: locationId, var: location_id}, {name: name, var: name}, {name: options, var: options}, {name: recurringAvailability, var: recurring_availability}, {name: serviceIds, var: service_ids}, {name: timezoneId, var: timezone_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, google_auth_return_url: $google_auth_return_url, outlook_auth_return_url: $outlook_auth_return_url, address: $address, availability: $availability, contact: $contact, custom_fields: $custom_fields, description: $description, email: $email, group_id: $group_id, location_id: $location_id, name: $name, options: $options, recurring_availability: $recurring_availability, service_ids: $service_ids, timezone_id: $timezone_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Resource Allocations
#
# GET /setup/v1/resources/{id}/allocations
# Returns: record<count: int, data: table<businessId: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: int, object: string, reason: string, repeat: record, repeats: bool, resourceId: int, startDate: string, startTime: int>, hasMore: bool, object: string, total: int, url: string>
export def "get-setup-v1-resources-id-allocations" [
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
  --start-date: string # yyyy-mm-dd, filter allocations on/after startDate (format: date-time)
  --end-date: string # yyyy-mm-dd, filter on/before endDate (format: date-time)
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit default 20, max 100 (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/setup/v1/resources/{id}/allocations"
    path_params: [{name: id, var: id}]
    query: [{name: startDate, var: start_date}, {name: endDate, var: end_date}, {name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, start_date: $start_date, end_date: $end_date, offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Allocation
#
# POST /setup/v1/resources/{id}/allocations
# Returns: record<businessId: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: int, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, resourceId: int, startDate: string, startTime: int>
export def "post-setup-v1-resources-id-allocations" [
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
  --end-date: string # nullable, format: date
  --end-time: int # nullable, format: int32
  --reason: string # nullable
  --repeat: record # shape: {frequency?: string, interval?: int, monthDay?: int, monthType?: string, weekdays?: string}
  --repeats: oneof<nothing, bool> # nullable
  --start-date: string # nullable, format: date
  --start-time: int # nullable, format: int32
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/setup/v1/resources/{id}/allocations"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: endDate, var: end_date}, {name: endTime, var: end_time}, {name: reason, var: reason}, {name: repeat, var: repeat}, {name: repeats, var: repeats}, {name: startDate, var: start_date}, {name: startTime, var: start_time}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, end_date: $end_date, end_time: $end_time, reason: $reason, repeat: $repeat, repeats: $repeats, start_date: $start_date, start_time: $start_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Weekly Availability
#
# GET /setup/v1/resources/{id}/availability
# Returns: record<businessId: int, ignoreBusinessHours: bool, resourceId: int, resourceName: string, resourceTzo: int, weekdays: record<fri: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, mon: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, sat: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, sun: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, thu: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, tue: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, wed: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>>>
export def "get-setup-v1-resources-id-availability" [
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
    path: "/setup/v1/resources/{id}/availability"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Weekly Availability
#
# PUT /setup/v1/resources/{id}/availability
# Returns: record<businessId: int, ignoreBusinessHours: bool, resourceId: int, resourceName: string, resourceTzo: int, weekdays: record<fri: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, mon: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, sat: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, sun: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, thu: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, tue: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, wed: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>>>
export def "put-setup-v1-resources-id-availability" [
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
  --fri: record # shape: {endTime?: int, startTime?: int}
  --mon: record # shape: {endTime?: int, startTime?: int}
  --sat: record # shape: {endTime?: int, startTime?: int}
  --sun: record # shape: {endTime?: int, startTime?: int}
  --thu: record # shape: {endTime?: int, startTime?: int}
  --tue: record # shape: {endTime?: int, startTime?: int}
  --wed: record # shape: {endTime?: int, startTime?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/setup/v1/resources/{id}/availability"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: fri, var: fri}, {name: mon, var: mon}, {name: sat, var: sat}, {name: sun, var: sun}, {name: thu, var: thu}, {name: tue, var: tue}, {name: wed, var: wed}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fri: $fri, mon: $mon, sat: $sat, sun: $sun, thu: $thu, tue: $tue, wed: $wed
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Block
#
# POST /setup/v1/resources/{id}/block
# Returns: record<businessId: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: int, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, resourceId: int, startDate: string, startTime: int>
export def "post-setup-v1-resources-id-block" [
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
  --all-day: oneof<nothing, bool> # nullable
  --end-date: string # nullable, format: date
  --end-time: int # nullable, format: int32
  --reason: string # nullable
  --repeat: record # shape: {frequency?: string, interval?: int, monthDay?: int, monthType?: string, weekdays?: string}
  --repeats: oneof<nothing, bool> # nullable
  --start-date: string # nullable, format: date
  --start-time: int # nullable, format: int32
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/setup/v1/resources/{id}/block"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: allDay, var: all_day}, {name: endDate, var: end_date}, {name: endTime, var: end_time}, {name: reason, var: reason}, {name: repeat, var: repeat}, {name: repeats, var: repeats}, {name: startDate, var: start_date}, {name: startTime, var: start_time}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, all_day: $all_day, end_date: $end_date, end_time: $end_time, reason: $reason, repeat: $repeat, repeats: $repeats, start_date: $start_date, start_time: $start_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Resource Blocks
#
# GET /setup/v1/resources/{id}/blocks
# Returns: record<count: int, data: table<businessId: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: int, object: string, reason: string, repeat: record, repeats: bool, resourceId: int, startDate: string, startTime: int>, hasMore: bool, object: string, total: int, url: string>
export def "get-setup-v1-resources-id-blocks" [
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
  --start-date: string # YYYY-MM-DD, filter blocks on/after startDate (format: date-time)
  --end-date: string # YYYY-MM-DD, filter on/before endDate (format: date-time)
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit default 20, max 100 (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/setup/v1/resources/{id}/blocks"
    path_params: [{name: id, var: id}]
    query: [{name: startDate, var: start_date}, {name: endDate, var: end_date}, {name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, start_date: $start_date, end_date: $end_date, offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Resource Google URL
#
# GET /setup/v1/resources/{id}/calendar/auth/google/{googleEmailAddress}
# Returns: record<calendarAuthUrl: string, calendarId: string, object: string>
export def "get-setup-v1-resources-id-calendar-auth-google-google-email-address" [
  id: string
  google_email_address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --google-auth-return-url: string # Google calendar authorization return url
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/setup/v1/resources/{id}/calendar/auth/google/{googleEmailAddress}"
    path_params: [{name: id, var: id}, {name: googleEmailAddress, var: google_email_address}]
    query: [{name: googleAuthReturnUrl, var: google_auth_return_url}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, google_email_address: $google_email_address, google_auth_return_url: $google_auth_return_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Resource Outlook URL
#
# GET /setup/v1/resources/{id}/calendar/auth/outlook/{outlookEmailAddress}
# Returns: record<calendarAuthUrl: string, calendarId: string, object: string>
export def "get-setup-v1-resources-id-calendar-auth-outlook-outlook-email-address" [
  id: string
  outlook_email_address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --outlook-auth-return-url: string # Outlook calendar authorization return url
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/setup/v1/resources/{id}/calendar/auth/outlook/{outlookEmailAddress}"
    path_params: [{name: id, var: id}, {name: outlookEmailAddress, var: outlook_email_address}]
    query: [{name: outlookAuthReturnUrl, var: outlook_auth_return_url}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, outlook_email_address: $outlook_email_address, outlook_auth_return_url: $outlook_auth_return_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Resource Image
#
# DELETE /setup/v1/resources/{id}/deleteimage
# Returns: record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bioLink: string, bookingNotification: int, calendarAvailability: int, contact: record<businessPhone: string, businessPhoneExt: string, conferenceInfo: string, homePhone: string, mobilePhone: string, phoneType: string, skypeUsername: string>, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, deletedStatus: bool, deletedTime: string, description: string, effectiveDate: string, email: string, gender: string, googleCalendarAuthUrl: string, googleCalendarAuthorized: bool, googleCalendarId: string, groupId: int, hourly: float, id: string, ignoreBusinessHours: bool, imageUrl: string, locationId: string, name: string, notificationType: int, object: string, options: record<bioLink: string, bookingNotification: int, calendarAvailability: int, displayColor: string, effectiveDate: string, gender: string, googleCalendarId: string, hourly: float, ignoreBusinessHours: bool, notificationType: int, outlookCalendarId: string, sortKey: int>, outlookCalendarAuthUrl: string, outlookCalendarAuthorized: bool, outlookCalendarId: string, phone: record<businessPhone: string, businessPhoneExt: string, homePhone: string, mobilePhone: string, phoneType: string>, recurringAvailability: bool, services: table<object: string, serviceId: int, serviceName: string>, skypeName: string, sortKey: int, timezoneIana: string, timezoneId: string, timezoneOffset: int>
export def "delete-setup-v1-resources-id-deleteimage" [
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
    method: delete
    path: "/setup/v1/resources/{id}/deleteimage"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reassign Resource
#
# PUT /setup/v1/resources/{id}/reassign/appointments/{resourceId}
# Returns: table<auditTrail: list<record>, bookedBy: string, businessName: string, calendarId: string, confirmationNumber: string, confirmed: bool, createDate: string, customFields: record, customerId: string, customerMessage: string, customers: list<record>, date: string, dateInternational: string, downloadIcsUrl: string, duration: int, email: string, emailConfirmationSent: string, emailReminderSent: string, endDateTime: string, firstname: string, groupSize: int, id: string, ipAddress: string, lastModifiedBy: string, lastModifiedOn: string, lastname: string, latitude: string, location: string, locationId: string, longitude: string, name: string, notes: string, object: string, onlineBooking: bool, paymentStatus: int, phone: string, phoneExt: string, phoneType: string, rescheduledId: string, resourceEmail: string, resourceGroupId: string, resourceGroupName: string, resourceId: string, resourceImageUrl: string, resourceName: string, resources: list<record>, serviceAllocationId: string, serviceId: string, serviceImageUrl: string, serviceName: string, smsConfirmationSent: string, smsReminderSent: string, startDateTime: string, status: string, stripeChargeId: string, stripeRefundId: string, time: int, timezone: int, timezoneIana: string, timezoneId: string>
export def "put-setup-v1-resources-id-reassign-appointments-resource-id" [
  id: string
  resource_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # YYYY-MM-DD, Appt range start date (format: date-time)
  --end-date: string # YYYY-MM-DD, Appt range end date (format: date-time)
  --calendar-id: string # CalendarId of calendar containing appointments
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: put
    path: "/setup/v1/resources/{id}/reassign/appointments/{resourceId}"
    path_params: [{name: id, var: id}, {name: resourceId, var: resource_id}]
    query: [{name: startDate, var: start_date}, {name: endDate, var: end_date}, {name: calendarId, var: calendar_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, resource_id: $resource_id, start_date: $start_date, end_date: $end_date, calendar_id: $calendar_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Recover Resource
#
# PUT /setup/v1/resources/{id}/recover
# Returns: record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bioLink: string, bookingNotification: int, calendarAvailability: int, contact: record<businessPhone: string, businessPhoneExt: string, conferenceInfo: string, homePhone: string, mobilePhone: string, phoneType: string, skypeUsername: string>, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, deletedStatus: bool, deletedTime: string, description: string, effectiveDate: string, email: string, gender: string, googleCalendarAuthUrl: string, googleCalendarAuthorized: bool, googleCalendarId: string, groupId: int, hourly: float, id: string, ignoreBusinessHours: bool, imageUrl: string, locationId: string, name: string, notificationType: int, object: string, options: record<bioLink: string, bookingNotification: int, calendarAvailability: int, displayColor: string, effectiveDate: string, gender: string, googleCalendarId: string, hourly: float, ignoreBusinessHours: bool, notificationType: int, outlookCalendarId: string, sortKey: int>, outlookCalendarAuthUrl: string, outlookCalendarAuthorized: bool, outlookCalendarId: string, phone: record<businessPhone: string, businessPhoneExt: string, homePhone: string, mobilePhone: string, phoneType: string>, recurringAvailability: bool, services: table<object: string, serviceId: int, serviceName: string>, skypeName: string, sortKey: int, timezoneIana: string, timezoneId: string, timezoneOffset: int>
export def "put-setup-v1-resources-id-recover" [
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
  --google-auth-return-url: string # Google calendar authorization return url
  --outlook-auth-return-url: string # Outlook calendar authorization return url
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/setup/v1/resources/{id}/recover"
    path_params: [{name: id, var: id}]
    query: [{name: googleAuthReturnUrl, var: google_auth_return_url}, {name: outlookAuthReturnUrl, var: outlook_auth_return_url}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, google_auth_return_url: $google_auth_return_url, outlook_auth_return_url: $outlook_auth_return_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Linked Services
#
# DELETE /setup/v1/resources/{id}/services
# Returns: record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bioLink: string, bookingNotification: int, calendarAvailability: int, contact: record<businessPhone: string, businessPhoneExt: string, conferenceInfo: string, homePhone: string, mobilePhone: string, phoneType: string, skypeUsername: string>, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, deletedStatus: bool, deletedTime: string, description: string, effectiveDate: string, email: string, gender: string, googleCalendarAuthUrl: string, googleCalendarAuthorized: bool, googleCalendarId: string, groupId: int, hourly: float, id: string, ignoreBusinessHours: bool, imageUrl: string, locationId: string, name: string, notificationType: int, object: string, options: record<bioLink: string, bookingNotification: int, calendarAvailability: int, displayColor: string, effectiveDate: string, gender: string, googleCalendarId: string, hourly: float, ignoreBusinessHours: bool, notificationType: int, outlookCalendarId: string, sortKey: int>, outlookCalendarAuthUrl: string, outlookCalendarAuthorized: bool, outlookCalendarId: string, phone: record<businessPhone: string, businessPhoneExt: string, homePhone: string, mobilePhone: string, phoneType: string>, recurringAvailability: bool, services: table<object: string, serviceId: int, serviceName: string>, skypeName: string, sortKey: int, timezoneIana: string, timezoneId: string, timezoneOffset: int>
export def "delete-setup-v1-resources-id-services" [
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
    method: delete
    path: "/setup/v1/resources/{id}/services"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Linked Services
#
# POST /setup/v1/resources/{id}/services
# Returns: record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bioLink: string, bookingNotification: int, calendarAvailability: int, contact: record<businessPhone: string, businessPhoneExt: string, conferenceInfo: string, homePhone: string, mobilePhone: string, phoneType: string, skypeUsername: string>, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, deletedStatus: bool, deletedTime: string, description: string, effectiveDate: string, email: string, gender: string, googleCalendarAuthUrl: string, googleCalendarAuthorized: bool, googleCalendarId: string, groupId: int, hourly: float, id: string, ignoreBusinessHours: bool, imageUrl: string, locationId: string, name: string, notificationType: int, object: string, options: record<bioLink: string, bookingNotification: int, calendarAvailability: int, displayColor: string, effectiveDate: string, gender: string, googleCalendarId: string, hourly: float, ignoreBusinessHours: bool, notificationType: int, outlookCalendarId: string, sortKey: int>, outlookCalendarAuthUrl: string, outlookCalendarAuthorized: bool, outlookCalendarId: string, phone: record<businessPhone: string, businessPhoneExt: string, homePhone: string, mobilePhone: string, phoneType: string>, recurringAvailability: bool, services: table<object: string, serviceId: int, serviceName: string>, skypeName: string, sortKey: int, timezoneIana: string, timezoneId: string, timezoneOffset: int>
export def "post-setup-v1-resources-id-services" [
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
  --body: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/setup/v1/resources/{id}/services"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Linked Services
#
# PUT /setup/v1/resources/{id}/services
# Returns: record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bioLink: string, bookingNotification: int, calendarAvailability: int, contact: record<businessPhone: string, businessPhoneExt: string, conferenceInfo: string, homePhone: string, mobilePhone: string, phoneType: string, skypeUsername: string>, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, deletedStatus: bool, deletedTime: string, description: string, effectiveDate: string, email: string, gender: string, googleCalendarAuthUrl: string, googleCalendarAuthorized: bool, googleCalendarId: string, groupId: int, hourly: float, id: string, ignoreBusinessHours: bool, imageUrl: string, locationId: string, name: string, notificationType: int, object: string, options: record<bioLink: string, bookingNotification: int, calendarAvailability: int, displayColor: string, effectiveDate: string, gender: string, googleCalendarId: string, hourly: float, ignoreBusinessHours: bool, notificationType: int, outlookCalendarId: string, sortKey: int>, outlookCalendarAuthUrl: string, outlookCalendarAuthorized: bool, outlookCalendarId: string, phone: record<businessPhone: string, businessPhoneExt: string, homePhone: string, mobilePhone: string, phoneType: string>, recurringAvailability: bool, services: table<object: string, serviceId: int, serviceName: string>, skypeName: string, sortKey: int, timezoneIana: string, timezoneId: string, timezoneOffset: int>
export def "put-setup-v1-resources-id-services" [
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
  --body: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/setup/v1/resources/{id}/services"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload Resource Image
#
# POST /setup/v1/resources/{id}/uploadimage
# Returns: record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bioLink: string, bookingNotification: int, calendarAvailability: int, contact: record<businessPhone: string, businessPhoneExt: string, conferenceInfo: string, homePhone: string, mobilePhone: string, phoneType: string, skypeUsername: string>, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, deletedStatus: bool, deletedTime: string, description: string, effectiveDate: string, email: string, gender: string, googleCalendarAuthUrl: string, googleCalendarAuthorized: bool, googleCalendarId: string, groupId: int, hourly: float, id: string, ignoreBusinessHours: bool, imageUrl: string, locationId: string, name: string, notificationType: int, object: string, options: record<bioLink: string, bookingNotification: int, calendarAvailability: int, displayColor: string, effectiveDate: string, gender: string, googleCalendarId: string, hourly: float, ignoreBusinessHours: bool, notificationType: int, outlookCalendarId: string, sortKey: int>, outlookCalendarAuthUrl: string, outlookCalendarAuthorized: bool, outlookCalendarId: string, phone: record<businessPhone: string, businessPhoneExt: string, homePhone: string, mobilePhone: string, phoneType: string>, recurringAvailability: bool, services: table<object: string, serviceId: int, serviceName: string>, skypeName: string, sortKey: int, timezoneIana: string, timezoneId: string, timezoneOffset: int>
export def "post-setup-v1-resources-id-uploadimage" [
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
  --image-file-data: string # nullable
  --image-file-name: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/setup/v1/resources/{id}/uploadimage"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: imageFileData, var: image_file_data}, {name: imageFileName, var: image_file_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, image_file_data: $image_file_data, image_file_name: $image_file_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Service Groups
#
# GET /setup/v1/servicegroups
# Returns: record<count: int, data: table<companyId: string, description: string, id: string, imageUrl: string, isDeleted: bool, locationId: string, name: string, object: string, type: int>, hasMore: bool, object: string, total: int, url: string>
export def "get-setup-v1-servicegroups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --location-id: string # id of business location, defaults to primary business location
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit default 20, max 100 (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/setup/v1/servicegroups"
    query: [{name: locationId, var: location_id}, {name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    location_id: $location_id, offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Service Group
#
# POST /setup/v1/servicegroups
# Returns: record<companyId: string, description: string, id: string, imageUrl: string, isDeleted: bool, locationId: string, name: string, object: string, type: int>
export def "post-setup-v1-servicegroups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # nullable
  --location-id: string # nullable
  --name: string # nullable
  --type: int # nullable, format: int32
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/setup/v1/servicegroups"
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: locationId, var: location_id}, {name: name, var: name}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    description: $description, location_id: $location_id, name: $name, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Service Group
#
# DELETE /setup/v1/servicegroups/{id}
# Returns: record<companyId: string, description: string, id: string, imageUrl: string, isDeleted: bool, locationId: string, name: string, object: string, type: int>
export def "delete-setup-v1-servicegroups-id" [
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
    method: delete
    path: "/setup/v1/servicegroups/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Service Group
#
# GET /setup/v1/servicegroups/{id}
# Returns: record<companyId: string, description: string, id: string, imageUrl: string, isDeleted: bool, locationId: string, name: string, object: string, type: int>
export def "get-setup-v1-servicegroups-id" [
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
    path: "/setup/v1/servicegroups/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Service Group
#
# PUT /setup/v1/servicegroups/{id}
# Returns: record<companyId: string, description: string, id: string, imageUrl: string, isDeleted: bool, locationId: string, name: string, object: string, type: int>
export def "put-setup-v1-servicegroups-id" [
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
  --description: string # nullable
  --location-id: string # nullable
  --name: string # nullable
  --type: int # nullable, format: int32
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/setup/v1/servicegroups/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: locationId, var: location_id}, {name: name, var: name}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, description: $description, location_id: $location_id, name: $name, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Recover Service Group
#
# PUT /setup/v1/servicegroups/{id}/recover
# Returns: record<companyId: string, description: string, id: string, imageUrl: string, isDeleted: bool, locationId: string, name: string, object: string, type: int>
export def "put-setup-v1-servicegroups-id-recover" [
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
    method: put
    path: "/setup/v1/servicegroups/{id}/recover"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Services
#
# GET /setup/v1/services
# Returns: record<count: int, data: table<availability: record, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookingInterval: int, bookingLimit: int, calendarId: string, calendarResourceGroupId: string, cancellationFeeAmount: float, cancellationFeeTaxable: bool, companyId: string, consumerPadding: bool, customFields: record, dailyBookingLimitCount: int, dailyBookingLimitMinutes: int, defaultService: bool, description: string, duration: int, durationInterval: int, durationMax: int, durationMin: int, durationSelect: bool, feeAmount: float, feeTaxable: bool, id: string, imageUrl: string, locationId: string, maxBookingLimit: int, maxCapacity: int, maxGroupSize: int, maxResourceBookingLimit: int, mediaPageUrl: string, name: string, nonRefundable: bool, object: string, padding: int, roundRobin: int, serviceGroupId: int, serviceGroupName: string, showOnline: bool, type: string>, hasMore: bool, object: string, total: int, url: string>
export def "get-setup-v1-services" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --location-id: string # id of business location, defaults to primary business location
  --service-group-id: int # Filter services by groupId (format: int32)
  --deleted: oneof<nothing, bool> # Filter by deleted status
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit default 20, max 100 (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/setup/v1/services"
    query: [{name: locationId, var: location_id}, {name: serviceGroupId, var: service_group_id}, {name: deleted, var: deleted}, {name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    location_id: $location_id, service_group_id: $service_group_id, deleted: $deleted, offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Service
#
# POST /setup/v1/services
# Returns: record<availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookingInterval: int, bookingLimit: int, calendarId: string, calendarResourceGroupId: string, cancellationFeeAmount: float, cancellationFeeTaxable: bool, companyId: string, consumerPadding: bool, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, dailyBookingLimitCount: int, dailyBookingLimitMinutes: int, defaultService: bool, description: string, duration: int, durationInterval: int, durationMax: int, durationMin: int, durationSelect: bool, feeAmount: float, feeTaxable: bool, id: string, imageUrl: string, locationId: string, maxBookingLimit: int, maxCapacity: int, maxGroupSize: int, maxResourceBookingLimit: int, mediaPageUrl: string, name: string, nonRefundable: bool, object: string, padding: int, roundRobin: int, serviceGroupId: int, serviceGroupName: string, showOnline: bool, type: string>
export def "post-setup-v1-services" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --availability: record # shape: {fri?: record, mon?: record, sat?: record, sun?: record, thu?: record, tue?: record, wed?: record}
  --booking-interval: int # format: int32
  --booking-limit: int # format: int32
  --custom-fields: record # shape: {field1?: string, field10?: string, field2?: string, field3?: string, field4?: string, field5?: string, field6?: string, field7?: string, field8?: string, field9?: string}
  --description: string # nullable
  --duration: int # format: int32
  --fees: record # shape: {cancellationFeeAmount?: float, cancellationFeeTaxable?: bool, feeAmount?: float, feeTaxable?: bool, nonRefundable?: bool}
  --location-id: string # nullable
  --max-capacity: int # format: int32
  --max-group-size: int # format: int32
  --media-page-url: string # nullable
  --name: string # nullable
  --options: record # shape: {consumerPadding?: bool, defaultService?: bool, durationInterval?: int, durationMax?: int, durationMin?: int, durationSelect?: bool, padding?: int}
  --public: oneof<nothing, bool>
  --service-group-id: string # nullable
  --settings: record # shape: {bookAheadUnit?: int, bookAheadValue?: int, bookInAdvance?: int}
  --type: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/setup/v1/services"
    body: {content_type: "application/json", kind: json, fields: [{name: availability, var: availability}, {name: bookingInterval, var: booking_interval}, {name: bookingLimit, var: booking_limit}, {name: customFields, var: custom_fields}, {name: description, var: description}, {name: duration, var: duration}, {name: fees, var: fees}, {name: locationId, var: location_id}, {name: maxCapacity, var: max_capacity}, {name: maxGroupSize, var: max_group_size}, {name: mediaPageUrl, var: media_page_url}, {name: name, var: name}, {name: options, var: options}, {name: public, var: public}, {name: serviceGroupId, var: service_group_id}, {name: settings, var: settings}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    availability: $availability, booking_interval: $booking_interval, booking_limit: $booking_limit, custom_fields: $custom_fields, description: $description, duration: $duration, fees: $fees, location_id: $location_id, max_capacity: $max_capacity, max_group_size: $max_group_size, media_page_url: $media_page_url, name: $name, options: $options, public: $public, service_group_id: $service_group_id, settings: $settings, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Allocation
#
# DELETE /setup/v1/services/allocations/{id}
# Returns: record<bookingCount: int, bookingLimit: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: string, locationId: string, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, resourceAddress: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, resourceDescription: string, resourceId: string, resourceImageUrl: string, resourceName: string, resourcePhone: record<businessPhone: string, businessPhoneExt: string, homePhone: string, mobilePhone: string, phoneType: string>, serviceDescription: string, serviceDuration: int, serviceId: string, serviceImageUrl: string, serviceName: string, startDate: string, startTime: int, timezoneName: string, timezoneOffset: int>
export def "delete-setup-v1-services-allocations-id" [
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
    method: delete
    path: "/setup/v1/services/allocations/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Allocation
#
# GET /setup/v1/services/allocations/{id}
# Returns: record<bookingCount: int, bookingLimit: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: string, locationId: string, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, resourceAddress: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, resourceDescription: string, resourceId: string, resourceImageUrl: string, resourceName: string, resourcePhone: record<businessPhone: string, businessPhoneExt: string, homePhone: string, mobilePhone: string, phoneType: string>, serviceDescription: string, serviceDuration: int, serviceId: string, serviceImageUrl: string, serviceName: string, startDate: string, startTime: int, timezoneName: string, timezoneOffset: int>
export def "get-setup-v1-services-allocations-id" [
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
    path: "/setup/v1/services/allocations/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Allocation
#
# PUT /setup/v1/services/allocations/{id}
# Returns: record<bookingCount: int, bookingLimit: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: string, locationId: string, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, resourceAddress: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, resourceDescription: string, resourceId: string, resourceImageUrl: string, resourceName: string, resourcePhone: record<businessPhone: string, businessPhoneExt: string, homePhone: string, mobilePhone: string, phoneType: string>, serviceDescription: string, serviceDuration: int, serviceId: string, serviceImageUrl: string, serviceName: string, startDate: string, startTime: int, timezoneName: string, timezoneOffset: int>
export def "put-setup-v1-services-allocations-id" [
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
  --booking-limit: int # format: int32
  --end-date: string # nullable, format: date
  --end-time: int # nullable, format: int32
  --location-id: string # nullable
  --reason: string # nullable
  --repeat: record # shape: {frequency?: string, interval?: int, monthDay?: int, monthType?: string, weekdays?: string}
  --repeats: oneof<nothing, bool> # nullable
  --resource-id: string # nullable
  --start-date: string # nullable, format: date
  --start-time: int # nullable, format: int32
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/setup/v1/services/allocations/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: bookingLimit, var: booking_limit}, {name: endDate, var: end_date}, {name: endTime, var: end_time}, {name: locationId, var: location_id}, {name: reason, var: reason}, {name: repeat, var: repeat}, {name: repeats, var: repeats}, {name: resourceId, var: resource_id}, {name: startDate, var: start_date}, {name: startTime, var: start_time}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, booking_limit: $booking_limit, end_date: $end_date, end_time: $end_time, location_id: $location_id, reason: $reason, repeat: $repeat, repeats: $repeats, resource_id: $resource_id, start_date: $start_date, start_time: $start_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Block
#
# DELETE /setup/v1/services/block/{id}
# Returns: record<businessId: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: int, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, resourceId: int, startDate: string, startTime: int>
export def "delete-setup-v1-services-block-id" [
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
    method: delete
    path: "/setup/v1/services/block/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Block
#
# PUT /setup/v1/services/block/{id}
# Returns: record<deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: string, locationId: string, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, serviceId: string, startDate: string, startTime: int>
export def "put-setup-v1-services-block-id" [
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
  --end-date: string # nullable, format: date
  --end-time: int # nullable, format: int32
  --reason: string # nullable
  --repeat: record # shape: {frequency?: string, interval?: int, monthDay?: int, monthType?: string, weekdays?: string}
  --repeats: oneof<nothing, bool> # nullable
  --start-date: string # nullable, format: date
  --start-time: int # nullable, format: int32
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/setup/v1/services/block/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: endDate, var: end_date}, {name: endTime, var: end_time}, {name: reason, var: reason}, {name: repeat, var: repeat}, {name: repeats, var: repeats}, {name: startDate, var: start_date}, {name: startTime, var: start_time}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, end_date: $end_date, end_time: $end_time, reason: $reason, repeat: $repeat, repeats: $repeats, start_date: $start_date, start_time: $start_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Block
#
# GET /setup/v1/services/blocks/{id}
# Returns: record<businessId: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: int, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, resourceId: int, startDate: string, startTime: int>
export def "get-setup-v1-services-blocks-id" [
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
    path: "/setup/v1/services/blocks/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Link Service to Calendar
#
# POST /setup/v1/services/calendar
# Returns: record<calendarId: string, calendarName: string, id: string, locationId: string, serviceId: string, serviceName: string>
export def "post-setup-v1-services-calendar" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --calendar-id: string # nullable
  --location-id: string # nullable
  --service-id: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/setup/v1/services/calendar"
    body: {content_type: "application/json", kind: json, fields: [{name: calendarId, var: calendar_id}, {name: locationId, var: location_id}, {name: serviceId, var: service_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    calendar_id: $calendar_id, location_id: $location_id, service_id: $service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Service Links
#
# DELETE /setup/v1/services/calendar/{id}
# Returns: record<calendarId: string, calendarName: string, id: string, locationId: string, serviceId: string, serviceName: string>
export def "delete-setup-v1-services-calendar-id" [
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
    method: delete
    path: "/setup/v1/services/calendar/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Service
#
# DELETE /setup/v1/services/{id}
# Returns: record<availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookingInterval: int, bookingLimit: int, calendarId: string, calendarResourceGroupId: string, cancellationFeeAmount: float, cancellationFeeTaxable: bool, companyId: string, consumerPadding: bool, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, dailyBookingLimitCount: int, dailyBookingLimitMinutes: int, defaultService: bool, description: string, duration: int, durationInterval: int, durationMax: int, durationMin: int, durationSelect: bool, feeAmount: float, feeTaxable: bool, id: string, imageUrl: string, locationId: string, maxBookingLimit: int, maxCapacity: int, maxGroupSize: int, maxResourceBookingLimit: int, mediaPageUrl: string, name: string, nonRefundable: bool, object: string, padding: int, roundRobin: int, serviceGroupId: int, serviceGroupName: string, showOnline: bool, type: string>
export def "delete-setup-v1-services-id" [
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
    method: delete
    path: "/setup/v1/services/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Service
#
# GET /setup/v1/services/{id}
# Returns: record<availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookingInterval: int, bookingLimit: int, calendarId: string, calendarResourceGroupId: string, cancellationFeeAmount: float, cancellationFeeTaxable: bool, companyId: string, consumerPadding: bool, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, dailyBookingLimitCount: int, dailyBookingLimitMinutes: int, defaultService: bool, description: string, duration: int, durationInterval: int, durationMax: int, durationMin: int, durationSelect: bool, feeAmount: float, feeTaxable: bool, id: string, imageUrl: string, locationId: string, maxBookingLimit: int, maxCapacity: int, maxGroupSize: int, maxResourceBookingLimit: int, mediaPageUrl: string, name: string, nonRefundable: bool, object: string, padding: int, roundRobin: int, serviceGroupId: int, serviceGroupName: string, showOnline: bool, type: string>
export def "get-setup-v1-services-id" [
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
    path: "/setup/v1/services/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Service
#
# PUT /setup/v1/services/{id}
# Returns: record<availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookingInterval: int, bookingLimit: int, calendarId: string, calendarResourceGroupId: string, cancellationFeeAmount: float, cancellationFeeTaxable: bool, companyId: string, consumerPadding: bool, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, dailyBookingLimitCount: int, dailyBookingLimitMinutes: int, defaultService: bool, description: string, duration: int, durationInterval: int, durationMax: int, durationMin: int, durationSelect: bool, feeAmount: float, feeTaxable: bool, id: string, imageUrl: string, locationId: string, maxBookingLimit: int, maxCapacity: int, maxGroupSize: int, maxResourceBookingLimit: int, mediaPageUrl: string, name: string, nonRefundable: bool, object: string, padding: int, roundRobin: int, serviceGroupId: int, serviceGroupName: string, showOnline: bool, type: string>
export def "put-setup-v1-services-id" [
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
  --availability: record # shape: {fri?: record, mon?: record, sat?: record, sun?: record, thu?: record, tue?: record, wed?: record}
  --booking-interval: int # nullable, format: int32
  --booking-limit: int # nullable, format: int32
  --custom-fields: record # shape: {field1?: string, field10?: string, field2?: string, field3?: string, field4?: string, field5?: string, field6?: string, field7?: string, field8?: string, field9?: string}
  --description: string # nullable
  --duration: int # nullable, format: int32
  --fees: record # shape: {cancellationFeeAmount?: float, cancellationFeeTaxable?: bool, feeAmount?: float, feeTaxable?: bool, nonRefundable?: bool}
  --location-id: string # nullable
  --max-capacity: int # nullable, format: int32
  --max-group-size: int # nullable, format: int32
  --media-page-url: string # nullable
  --name: string # nullable
  --options: record # shape: {consumerPadding?: bool, defaultService?: bool, durationInterval?: int, durationMax?: int, durationMin?: int, durationSelect?: bool, padding?: int}
  --public: oneof<nothing, bool> # nullable
  --service-group-id: string # nullable
  --settings: record # shape: {bookAheadUnit?: int, bookAheadValue?: int, bookInAdvance?: int}
  --type: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/setup/v1/services/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: availability, var: availability}, {name: bookingInterval, var: booking_interval}, {name: bookingLimit, var: booking_limit}, {name: customFields, var: custom_fields}, {name: description, var: description}, {name: duration, var: duration}, {name: fees, var: fees}, {name: locationId, var: location_id}, {name: maxCapacity, var: max_capacity}, {name: maxGroupSize, var: max_group_size}, {name: mediaPageUrl, var: media_page_url}, {name: name, var: name}, {name: options, var: options}, {name: public, var: public}, {name: serviceGroupId, var: service_group_id}, {name: settings, var: settings}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, availability: $availability, booking_interval: $booking_interval, booking_limit: $booking_limit, custom_fields: $custom_fields, description: $description, duration: $duration, fees: $fees, location_id: $location_id, max_capacity: $max_capacity, max_group_size: $max_group_size, media_page_url: $media_page_url, name: $name, options: $options, public: $public, service_group_id: $service_group_id, settings: $settings, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Service Allocations
#
# GET /setup/v1/services/{id}/allocations
# Returns: record<count: int, data: table<bookingCount: int, bookingLimit: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: string, locationId: string, object: string, reason: string, repeat: record, repeats: bool, resourceAddress: record, resourceDescription: string, resourceId: string, resourceImageUrl: string, resourceName: string, resourcePhone: record, serviceDescription: string, serviceDuration: int, serviceId: string, serviceImageUrl: string, serviceName: string, startDate: string, startTime: int, timezoneName: string, timezoneOffset: int>, hasMore: bool, object: string, total: int, url: string>
export def "get-setup-v1-services-id-allocations" [
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
  --location-id: string # The id of the location. Defaults to the primary location
  --resource-id: string # The id of the resource to filter on
  --start-date: string # Format YYYY-MM-DD. Filter appointments by on/after startDate (format: date-time)
  --end-date: string # Format YYYY-MM-DD. Filter appointments on/before endDate (format: date-time)
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit default 20, max 100 (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/setup/v1/services/{id}/allocations"
    path_params: [{name: id, var: id}]
    query: [{name: locationId, var: location_id}, {name: resourceId, var: resource_id}, {name: startDate, var: start_date}, {name: endDate, var: end_date}, {name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, location_id: $location_id, resource_id: $resource_id, start_date: $start_date, end_date: $end_date, offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Allocation
#
# POST /setup/v1/services/{id}/allocations
# Returns: record<bookingCount: int, bookingLimit: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: string, locationId: string, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, resourceAddress: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, resourceDescription: string, resourceId: string, resourceImageUrl: string, resourceName: string, resourcePhone: record<businessPhone: string, businessPhoneExt: string, homePhone: string, mobilePhone: string, phoneType: string>, serviceDescription: string, serviceDuration: int, serviceId: string, serviceImageUrl: string, serviceName: string, startDate: string, startTime: int, timezoneName: string, timezoneOffset: int>
export def "post-setup-v1-services-id-allocations" [
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
  --booking-limit: int # format: int32
  --end-date: string # nullable, format: date
  --end-time: int # nullable, format: int32
  --location-id: string # nullable
  --reason: string # nullable
  --repeat: record # shape: {frequency?: string, interval?: int, monthDay?: int, monthType?: string, weekdays?: string}
  --repeats: oneof<nothing, bool> # nullable
  --resource-id: string # nullable
  --start-date: string # nullable, format: date
  --start-time: int # nullable, format: int32
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/setup/v1/services/{id}/allocations"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: bookingLimit, var: booking_limit}, {name: endDate, var: end_date}, {name: endTime, var: end_time}, {name: locationId, var: location_id}, {name: reason, var: reason}, {name: repeat, var: repeat}, {name: repeats, var: repeats}, {name: resourceId, var: resource_id}, {name: startDate, var: start_date}, {name: startTime, var: start_time}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, booking_limit: $booking_limit, end_date: $end_date, end_time: $end_time, location_id: $location_id, reason: $reason, repeat: $repeat, repeats: $repeats, resource_id: $resource_id, start_date: $start_date, start_time: $start_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Allocations Bulk
#
# POST /setup/v1/services/{id}/allocations/bulk
# Returns: table<bookingCount: int, bookingLimit: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: string, locationId: string, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, resourceAddress: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, resourceDescription: string, resourceId: string, resourceImageUrl: string, resourceName: string, resourcePhone: record<businessPhone: string, businessPhoneExt: string, homePhone: string, mobilePhone: string, phoneType: string>, serviceDescription: string, serviceDuration: int, serviceId: string, serviceImageUrl: string, serviceName: string, startDate: string, startTime: int, timezoneName: string, timezoneOffset: int>
export def "post-setup-v1-services-id-allocations-bulk" [
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
  --service-allocations: list # nullable — item shape: {bookingLimit?: int, endDate?: string, endTime?: int, locationId?: string, reason?: string, repeat?: record, repeats?: bool, resourceId?: string, startDate?: string, startTime?: int}
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/setup/v1/services/{id}/allocations/bulk"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: serviceAllocations, var: service_allocations}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, service_allocations: $service_allocations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Weekly Availability
#
# GET /setup/v1/services/{id}/availability
# Returns: record<ignoreBusinessHours: bool, serviceId: int, serviceName: string, weekdays: record<fri: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, mon: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, sat: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, sun: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, thu: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, tue: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, wed: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>>>
export def "get-setup-v1-services-id-availability" [
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
    path: "/setup/v1/services/{id}/availability"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Weekly Availability
#
# PUT /setup/v1/services/{id}/availability
# Returns: record<ignoreBusinessHours: bool, serviceId: int, serviceName: string, weekdays: record<fri: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, mon: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, sat: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, sun: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, thu: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, tue: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, wed: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>>>
export def "put-setup-v1-services-id-availability" [
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
  --fri: record # shape: {endTime?: int, startTime?: int}
  --mon: record # shape: {endTime?: int, startTime?: int}
  --sat: record # shape: {endTime?: int, startTime?: int}
  --sun: record # shape: {endTime?: int, startTime?: int}
  --thu: record # shape: {endTime?: int, startTime?: int}
  --tue: record # shape: {endTime?: int, startTime?: int}
  --wed: record # shape: {endTime?: int, startTime?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/setup/v1/services/{id}/availability"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: fri, var: fri}, {name: mon, var: mon}, {name: sat, var: sat}, {name: sun, var: sun}, {name: thu, var: thu}, {name: tue, var: tue}, {name: wed, var: wed}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fri: $fri, mon: $mon, sat: $sat, sun: $sun, thu: $thu, tue: $tue, wed: $wed
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Block
#
# POST /setup/v1/services/{id}/block
# Returns: record<deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: string, locationId: string, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, serviceId: string, startDate: string, startTime: int>
export def "post-setup-v1-services-id-block" [
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
  --end-date: string # nullable, format: date
  --end-time: int # nullable, format: int32
  --location-id: string # nullable
  --reason: string # nullable
  --repeat: record # shape: {frequency?: string, interval?: int, monthDay?: int, monthType?: string, weekdays?: string}
  --repeats: oneof<nothing, bool>
  --start-date: string # nullable, format: date
  --start-time: int # nullable, format: int32
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/setup/v1/services/{id}/block"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: endDate, var: end_date}, {name: endTime, var: end_time}, {name: locationId, var: location_id}, {name: reason, var: reason}, {name: repeat, var: repeat}, {name: repeats, var: repeats}, {name: startDate, var: start_date}, {name: startTime, var: start_time}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, end_date: $end_date, end_time: $end_time, location_id: $location_id, reason: $reason, repeat: $repeat, repeats: $repeats, start_date: $start_date, start_time: $start_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Service Blocks
#
# GET /setup/v1/services/{id}/blocks
# Returns: record<count: int, data: table<deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: string, locationId: string, object: string, reason: string, repeat: record, repeats: bool, serviceId: string, startDate: string, startTime: int>, hasMore: bool, object: string, total: int, url: string>
export def "get-setup-v1-services-id-blocks" [
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
  --start-date: string # Format YYYY-MM-DD. Filter blocks on/after startDate (format: date-time)
  --end-date: string # Format YYYY-MM-DD. Filter on/before endDate (format: date-time)
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit default 20, max 100 (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/setup/v1/services/{id}/blocks"
    path_params: [{name: id, var: id}]
    query: [{name: startDate, var: start_date}, {name: endDate, var: end_date}, {name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, start_date: $start_date, end_date: $end_date, offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Linked Calendar
#
# GET /setup/v1/services/{id}/calendar
# Returns: record<calendarId: string, calendarName: string, id: string, locationId: string, serviceId: string, serviceName: string>
export def "get-setup-v1-services-id-calendar" [
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
  --location-id: string # id of business location, defaults to primary business location
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/setup/v1/services/{id}/calendar"
    path_params: [{name: id, var: id}]
    query: [{name: locationId, var: location_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, location_id: $location_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Service Image
#
# DELETE /setup/v1/services/{id}/deleteimage
# Returns: record<availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookingInterval: int, bookingLimit: int, calendarId: string, calendarResourceGroupId: string, cancellationFeeAmount: float, cancellationFeeTaxable: bool, companyId: string, consumerPadding: bool, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, dailyBookingLimitCount: int, dailyBookingLimitMinutes: int, defaultService: bool, description: string, duration: int, durationInterval: int, durationMax: int, durationMin: int, durationSelect: bool, feeAmount: float, feeTaxable: bool, id: string, imageUrl: string, locationId: string, maxBookingLimit: int, maxCapacity: int, maxGroupSize: int, maxResourceBookingLimit: int, mediaPageUrl: string, name: string, nonRefundable: bool, object: string, padding: int, roundRobin: int, serviceGroupId: int, serviceGroupName: string, showOnline: bool, type: string>
export def "delete-setup-v1-services-id-deleteimage" [
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
    method: delete
    path: "/setup/v1/services/{id}/deleteimage"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Recover Service
#
# PUT /setup/v1/services/{id}/recover
# Returns: record<availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookingInterval: int, bookingLimit: int, calendarId: string, calendarResourceGroupId: string, cancellationFeeAmount: float, cancellationFeeTaxable: bool, companyId: string, consumerPadding: bool, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, dailyBookingLimitCount: int, dailyBookingLimitMinutes: int, defaultService: bool, description: string, duration: int, durationInterval: int, durationMax: int, durationMin: int, durationSelect: bool, feeAmount: float, feeTaxable: bool, id: string, imageUrl: string, locationId: string, maxBookingLimit: int, maxCapacity: int, maxGroupSize: int, maxResourceBookingLimit: int, mediaPageUrl: string, name: string, nonRefundable: bool, object: string, padding: int, roundRobin: int, serviceGroupId: int, serviceGroupName: string, showOnline: bool, type: string>
export def "put-setup-v1-services-id-recover" [
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
    method: put
    path: "/setup/v1/services/{id}/recover"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Resources for Service
#
# GET /setup/v1/services/{id}/resources
# Returns: record<count: int, data: table<address: record, availability: record, bioLink: string, bookingNotification: int, calendarAvailability: int, contact: record, customFields: record, deletedStatus: bool, deletedTime: string, description: string, effectiveDate: string, email: string, gender: string, googleCalendarAuthUrl: string, googleCalendarAuthorized: bool, googleCalendarId: string, groupId: int, hourly: float, id: string, ignoreBusinessHours: bool, imageUrl: string, locationId: string, name: string, notificationType: int, object: string, options: record, outlookCalendarAuthUrl: string, outlookCalendarAuthorized: bool, outlookCalendarId: string, phone: record, recurringAvailability: bool, services: list, skypeName: string, sortKey: int, timezoneIana: string, timezoneId: string, timezoneOffset: int>, hasMore: bool, object: string, total: int, url: string>
export def "get-setup-v1-services-id-resources" [
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
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit default 20, max 100 (format: int32)
  --google-auth-return-url: string # Google calendar authorization return url
  --outlook-auth-return-url: string # Outlook calendar authorization return url
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/setup/v1/services/{id}/resources"
    path_params: [{name: id, var: id}]
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: googleAuthReturnUrl, var: google_auth_return_url}, {name: outlookAuthReturnUrl, var: outlook_auth_return_url}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, offset: $offset, limit: $limit, google_auth_return_url: $google_auth_return_url, outlook_auth_return_url: $outlook_auth_return_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload Service Image
#
# POST /setup/v1/services/{id}/uploadimage
# Returns: record<availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookingInterval: int, bookingLimit: int, calendarId: string, calendarResourceGroupId: string, cancellationFeeAmount: float, cancellationFeeTaxable: bool, companyId: string, consumerPadding: bool, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, dailyBookingLimitCount: int, dailyBookingLimitMinutes: int, defaultService: bool, description: string, duration: int, durationInterval: int, durationMax: int, durationMin: int, durationSelect: bool, feeAmount: float, feeTaxable: bool, id: string, imageUrl: string, locationId: string, maxBookingLimit: int, maxCapacity: int, maxGroupSize: int, maxResourceBookingLimit: int, mediaPageUrl: string, name: string, nonRefundable: bool, object: string, padding: int, roundRobin: int, serviceGroupId: int, serviceGroupName: string, showOnline: bool, type: string>
export def "post-setup-v1-services-id-uploadimage" [
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
  --image-file-data: string # nullable
  --image-file-name: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/setup/v1/services/{id}/uploadimage"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: imageFileData, var: image_file_data}, {name: imageFileName, var: image_file_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, image_file_data: $image_file_data, image_file_name: $image_file_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
