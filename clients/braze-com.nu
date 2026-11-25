# Auto-generated client for Braze Endpoints v1.0.0
# Source: https://api.apis.guru/v2/specs/braze.com/1.0.0/openapi.json
# Auth: --token flag or $env.BRAZE_ENDPOINTS_TOKEN

const CLIENT = {
  base_url: "https://rest.iad-01.braze.com"
  token_env_var: "BRAZE_ENDPOINTS_TOKEN"
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

def base-url-completer [] { ["https://rest.iad-01.braze.com"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {}
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["campaign-analytics" "campaign-details" "campaign-list" "canvas-data-series-analytics" "canvas-data-analytics-summary" "canvas-details" "canvas-list" "schedule-api-triggered-canvases" "see-content-block-information" "list-available-content-blocks" "query-hard-bounced-emails" "query-list-of-unsubscribed-email-addresses" "custom-events-analytics" "custom-events-list" "news-feed-card-analytics" "news-feed-cards-details" "news-feed-cards-list" "daily-active-users-by-date" "monthly-active-users-for-last30-days" "daily-new-users-by-date" "kp-is-for-daily-app-uninstalls-by-date" "get-upcoming-scheduled-campaigns-and-canvases" "segment-analytics" "segment-details" "segment-list" "send-analytics" "app-sessions-by-time" "list-users-subscription-group-status-sms" "list-users-subscription-group-sms" "see-email-template-information" "list-available-email-templates" "commands"] | sort) } | get name | first)
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

# Campaign Analytics
#
# GET /campaigns/data_series
# operationId: campaignAnalytics
export def "campaign-analytics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --campaign-id: string # (Required) String Campaign API identifier (e.g. {{campaign_identifier}})
  --length: string # (Required) Integer Max number of days before ending_at to include in the returned series - must be between 1 and 100 inclusive (e.g. 7)
  --ending-at: string # (Optional) DateTime (ISO 8601 string) Date on which the data series should end - defaults to time of the request (e.g. 2020-06-28T23:59:59-5:00)
]: nothing -> any {
  http-request {
    method: get
    path: "/campaigns/data_series"
    query: [{name: campaign_id, var: campaign_id}, {name: length, var: length}, {name: ending_at, var: ending_at}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    campaign_id: $campaign_id, length: $length, ending_at: $ending_at
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Campaign Details
#
# GET /campaigns/details
# operationId: campaignDetails
export def "campaign-details" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --campaign-id: string # (Required) String Campaign API identifier (e.g. {{campaign_identifier}})
]: nothing -> any {
  http-request {
    method: get
    path: "/campaigns/details"
    query: [{name: campaign_id, var: campaign_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    campaign_id: $campaign_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Campaign List
#
# GET /campaigns/list
# operationId: campaignList
export def "campaign-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: string # (Optional) Integer The page of campaigns to return, defaults to 0 (returns the first set of up to 100) (e.g. 0)
  --include-archived: string # (Optional) Boolean Whether or not to include archived campaigns, defaults to false (e.g. false)
  --sort-direction: string # (Optional) String Pass in the value `desc` to sort by creation time from newest to oldest. Pass in `asc` to sort from oldest to newest. If sort_direction is not included, the default order is oldest to newest. (e.g. desc)
  --last-edit-time-gt: string # (Optional) DateTime (ISO 8601 string) Filters the results and only returns campaigns that were edited greater than the time provided till now. (e.g. 2020-06-28T23:59:59-5:00)
]: nothing -> any {
  http-request {
    method: get
    path: "/campaigns/list"
    query: [{name: page, var: page}, {name: include_archived, var: include_archived}, {name: sort_direction, var: sort_direction}, {name: "last_edit.time[gt]", var: last_edit_time_gt}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, include_archived: $include_archived, sort_direction: $sort_direction, last_edit_time_gt: $last_edit_time_gt
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Canvas Data Series Analytics
#
# GET /canvas/data_series
# operationId: canvasDataSeriesAnalytics
export def "canvas-data-series-analytics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --canvas-id: string # (Required) String Canvas API Identifier (e.g. {{canvas_id}})
  --ending-at: string # (Required) DateTime (ISO 8601 string) Date on which the data export should end - defaults to time of the request (e.g. 2018-05-30T23:59:59-5:00)
  --starting-at: string # (Optional) DateTime (ISO 8601 string) Date on which the data export should begin (either length or starting_at are required) (e.g. 2018-05-28T23:59:59-5:00)
  --length: string # (Optional) DateTime (ISO 8601 string) Max number of days before ending_at to include in the returned series - must be between 1 and 14 inclusive (either length or starting_at required) (e.g. 10)
  --include-variant-breakdown: string # (Optional) Boolean Whether or not to include variant stats (defaults to false) (e.g. true)
  --include-step-breakdown: string # (Optional) Boolean Whether or not to include step stats (defaults to false) (e.g. true)
  --include-deleted-step-data: string # (Optional) Boolean Whether or not to include step stats for deleted steps (defaults to false) (e.g. true)
]: nothing -> any {
  http-request {
    method: get
    path: "/canvas/data_series"
    query: [{name: canvas_id, var: canvas_id}, {name: ending_at, var: ending_at}, {name: starting_at, var: starting_at}, {name: length, var: length}, {name: include_variant_breakdown, var: include_variant_breakdown}, {name: include_step_breakdown, var: include_step_breakdown}, {name: include_deleted_step_data, var: include_deleted_step_data}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    canvas_id: $canvas_id, ending_at: $ending_at, starting_at: $starting_at, length: $length, include_variant_breakdown: $include_variant_breakdown, include_step_breakdown: $include_step_breakdown, include_deleted_step_data: $include_deleted_step_data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Canvas Data Analytics Summary
#
# GET /canvas/data_summary
# operationId: canvasDataAnalyticsSummary
export def "canvas-data-analytics-summary" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --canvas-id: string # (Required) String Canvas API identifier (e.g. {{canvas_id}})
  --ending-at: string # (Required) DateTime (ISO 8601 string) Date on which the data export should end - defaults to time of the request (e.g. 2018-05-30T23:59:59-5:00)
  --starting-at: string # (Optional) DateTime (ISO 8601 string) Date on which the data export should begin (either length or starting_at required) (e.g. 2018-05-28T23:59:59-5:00)
  --length: string # (Optional) Integer Max number of days before ending_at to include in the returned series - must be between 1 and 14 inclusive (either length or starting_at required) (e.g. 5)
  --include-variant-breakdown: string # (Optional) Boolean Whether or not to include variant stats (defaults to false) (e.g. true)
  --include-step-breakdown: string # (Optional) Boolean Whether or not to include step stats (defaults to false) (e.g. true)
  --include-deleted-step-data: string # (Optional) Boolean Whether or not to include step stats for deleted steps (defaults to false) (e.g. true)
]: nothing -> any {
  http-request {
    method: get
    path: "/canvas/data_summary"
    query: [{name: canvas_id, var: canvas_id}, {name: ending_at, var: ending_at}, {name: starting_at, var: starting_at}, {name: length, var: length}, {name: include_variant_breakdown, var: include_variant_breakdown}, {name: include_step_breakdown, var: include_step_breakdown}, {name: include_deleted_step_data, var: include_deleted_step_data}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    canvas_id: $canvas_id, ending_at: $ending_at, starting_at: $starting_at, length: $length, include_variant_breakdown: $include_variant_breakdown, include_step_breakdown: $include_step_breakdown, include_deleted_step_data: $include_deleted_step_data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Canvas Details
#
# GET /canvas/details
# operationId: canvasDetails
export def "canvas-details" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --canvas-id: string # (Required) String Canvas API Identifier (e.g. {{canvas_identifier}})
]: nothing -> any {
  http-request {
    method: get
    path: "/canvas/details"
    query: [{name: canvas_id, var: canvas_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    canvas_id: $canvas_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Canvas List
#
# GET /canvas/list
# operationId: canvasList
export def "canvas-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: string # (Optional) Integer The page of Canvases to return, defaults to `0` (returns the first set of up to 100) (e.g. 1)
  --include-archived: string # (Optional) Boolean Whether or not to include archived Canvases, defaults to `false`. (e.g. false)
  --sort-direction: string # (Optional) String Pass in the value `desc` to sort by creation time from newest to oldest. Pass in `asc` to sort from oldest to newest. If sort_direction is not included, the default order is oldest to newest. (e.g. desc)
  --last-edit-time-gt: string # (Optional) DateTime (ISO 8601 string) Filters the results and only returns Canvases that were edited greater than the time provided till now. (e.g. 2020-06-28T23:59:59-5:00)
]: nothing -> any {
  http-request {
    method: get
    path: "/canvas/list"
    query: [{name: page, var: page}, {name: include_archived, var: include_archived}, {name: sort_direction, var: sort_direction}, {name: "last_edit.time[gt]", var: last_edit_time_gt}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, include_archived: $include_archived, sort_direction: $sort_direction, last_edit_time_gt: $last_edit_time_gt
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Schedule API Triggered Canvases
#
# POST /canvas/trigger/schedule/create
# operationId: scheduleApiTriggeredCanvases
export def "schedule-api-triggered-canvases" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --audience: record # shape: {AND?: list}
  --broadcast: oneof<nothing, bool> # e.g. false
  --canvas-entry-properties: record
  --canvas-id: string # e.g. canvas_identifier
  --recipients: list # item shape: {canvas_entry_properties?: record, external_user_id?: string, trigger_properties?: string, user_alias?: string}
  --schedule: record # shape: {at_optimal_time?: bool, in_local_time?: bool, time?: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/canvas/trigger/schedule/create"
    body: {content_type: "application/json", kind: json, fields: [{name: audience, var: audience}, {name: broadcast, var: broadcast}, {name: canvas_entry_properties, var: canvas_entry_properties}, {name: canvas_id, var: canvas_id}, {name: recipients, var: recipients}, {name: schedule, var: schedule}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    audience: $audience, broadcast: $broadcast, canvas_entry_properties: $canvas_entry_properties, canvas_id: $canvas_id, recipients: $recipients, schedule: $schedule
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# See Content Block Information
#
# GET /content_blocks/info
# operationId: seeContentBlockInformation
export def "see-content-block-information" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-block-id: string # (Required) String The Content Block ID. This can be found by either listing Content Block information or going to the Developer Console, then API Settings, then scrolling to the bottom and searching for your Content Block API Identifier. (e.g. {{content_block_id}})
  --include-inclusion-data: string # (Optional) Boolean When set to ‘true’, the API returns back the Message Variation API ID of Campaigns and Canvases where this content block is included, to be used in subsequent calls. The results exclude archived or deleted Campaigns or Canvases. (e.g. No)
]: nothing -> any {
  http-request {
    method: get
    path: "/content_blocks/info"
    query: [{name: content_block_id, var: content_block_id}, {name: include_inclusion_data, var: include_inclusion_data}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    content_block_id: $content_block_id, include_inclusion_data: $include_inclusion_data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Available Content Blocks
#
# GET /content_blocks/list
# operationId: listAvailableContentBlocks
export def "list-available-content-blocks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --modified-after: string # (Optional) String in ISO 8601 Retrieve only content blocks updated at or after the given time. (e.g. 2020-01-01T01:01:01.000000)
  --modified-before: string # (Optional) String in ISO 8601 Retrieve only content blocks updated at or before the given time. (e.g. 2020-02-01T01:01:01.000000)
  --limit: string # (Optional) Positive Number Maximum number of content blocks to retrieve, default to 100 if not provided, maximum acceptable value is 1000. (e.g. 100)
  --offset: string # (Optional) Positive Number Number of content blocks to skip before returning rest of the templates that fit the search criteria. (e.g. 1)
]: nothing -> any {
  http-request {
    method: get
    path: "/content_blocks/list"
    query: [{name: modified_after, var: modified_after}, {name: modified_before, var: modified_before}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    modified_after: $modified_after, modified_before: $modified_before, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Query Hard Bounced Emails
#
# GET /email/hard_bounces
# operationId: queryHardBouncedEmails
export def "query-hard-bounced-emails" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # (Optional*) String in YYYY-MM-DD format Start date of the range to retrieve hard bounces, must be earlier than `end_date`. This is treated as midnight in UTC time by the API. *You must provide either an `email` or a `start_date`, and an `end_date`. (e.g. 2019-01-01)
  --end-date: string # (Optional*) String in YYYY-MM-DD format String in YYYY-MM-DD format. End date of the range to retrieve hard bounces. This is treated as midnight in UTC time by the API. *You must provide either an `email` or a `start_date`, and an `end_date`. (e.g. 2019-02-01)
  --limit: string # (Optional) Integer Optional field to limit the number of results returned. Defaults to 100, maximum is 500. (e.g. 100)
  --offset: string # (Optional) Integer Optional beginning point in the list to retrieve from. (e.g. 1)
  --email: string # (Optional*) String If provided, we will return whether or not the user has hard bounced. *You must provide either an `email` or a `start_date`, and an `end_date`. (e.g. example@braze.com)
]: nothing -> any {
  http-request {
    method: get
    path: "/email/hard_bounces"
    query: [{name: start_date, var: start_date}, {name: end_date, var: end_date}, {name: limit, var: limit}, {name: offset, var: offset}, {name: email, var: email}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    start_date: $start_date, end_date: $end_date, limit: $limit, offset: $offset, email: $email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Query List of Unsubscribed Email Addresses
#
# GET /email/unsubscribes
# operationId: queryListOfUnsubscribedEmailAddresses
export def "query-list-of-unsubscribed-email-addresses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # (Optional*) String in YYYY-MM-DD format Start date of the range to retrieve unsubscribes, must be earlier than end_date. This is treated as midnight in UTC time by the API. (e.g. 2020-01-01)
  --end-date: string # (Optional*) String in YYYY-MM-DD format End date of the range to retrieve unsubscribes. This is treated as midnight in UTC time by the API. (e.g. 2020-02-01)
  --limit: string # (Optional) Integer Optional field to limit the number of results returned. Limit must be greater than 1. Defaults to 100, maximum is 500. (e.g. 1)
  --offset: string # (Optional) Integer Optional beginning point in the list to retrieve from (e.g. 1)
  --sort-direction: string # (Optional) String Pass in the value `asc` to sort unsubscribes from oldest to newest. Pass in `desc` to sort from newest to oldest. If sort_direction is not included, the default order is newest to oldest. (e.g. desc)
  --email: string # (Optional*) String If provided, we will return whether or not the user has unsubscribed (e.g. example@braze.com)
]: nothing -> any {
  http-request {
    method: get
    path: "/email/unsubscribes"
    query: [{name: start_date, var: start_date}, {name: end_date, var: end_date}, {name: limit, var: limit}, {name: offset, var: offset}, {name: sort_direction, var: sort_direction}, {name: email, var: email}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    start_date: $start_date, end_date: $end_date, limit: $limit, offset: $offset, sort_direction: $sort_direction, email: $email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Custom Events Analytics
#
# GET /events/data_series
# operationId: customEventsAnalytics
export def "custom-events-analytics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --event: string # (Required) String The name of the custom event for which to return analytics (e.g. event_name)
  --length: string # (Required) Integer Max number of units (days or hours) before ending_at to include in the returned series - must be between 1 and 100 inclusive (e.g. 24)
  --unit: string # (Optional) String Unit of time between data points - can be "day" or "hour" (defaults to "day") (e.g. hour)
  --ending-at: string # (Optional) DateTime (ISO 8601 string) Point in time when the data series should end - defaults to time of the request (e.g. 2014-12-10T23:59:59-05:00)
  --app-id: string # (Optional) String App API identifier retrieved from the Developer Console to limit analytics to a specific app (e.g. {{app_identifier}})
  --segment-id: string # (Optional) String Segment API identifier indicating the analytics enabled segment for which event analytics should be returned (e.g. {{segment_identifier}})
]: nothing -> any {
  http-request {
    method: get
    path: "/events/data_series"
    query: [{name: event, var: event}, {name: length, var: length}, {name: unit, var: unit}, {name: ending_at, var: ending_at}, {name: app_id, var: app_id}, {name: segment_id, var: segment_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    event: $event, length: $length, unit: $unit, ending_at: $ending_at, app_id: $app_id, segment_id: $segment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Custom Events List
#
# GET /events/list
# operationId: customEventsList
export def "custom-events-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: string # (Optional) Integer The page of event names to return, defaults to 0 (returns the first set of up to 250) (e.g. 3)
]: nothing -> any {
  http-request {
    method: get
    path: "/events/list"
    query: [{name: page, var: page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# News Feed Card Analytics
#
# GET /feed/data_series
# operationId: newsFeedCardAnalytics
export def "news-feed-card-analytics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --card-id: string # (Required) String Card API identifier (e.g. {{card_identifier}})
  --length: string # (Required) Integer Max number of units (days or hours) before ending_at to include in the returned series - must be between 1 and 100 inclusive (e.g. 14)
  --unit: string # (Optional) String Unit of time between data points - can be "day" or "hour" (defaults to "day") (e.g. day)
  --ending-at: string # (Optional) DateTime (ISO 8601 string) Date on which the data series should end - defaults to time of the request (e.g. 2018-06-28T23:59:59-5:00)
]: nothing -> any {
  http-request {
    method: get
    path: "/feed/data_series"
    query: [{name: card_id, var: card_id}, {name: length, var: length}, {name: unit, var: unit}, {name: ending_at, var: ending_at}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    card_id: $card_id, length: $length, unit: $unit, ending_at: $ending_at
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# News Feed Cards Details
#
# GET /feed/details
# operationId: newsFeedCardsDetails
export def "news-feed-cards-details" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --card-id: string # (Required) String Card API identifier (e.g. {{card_identifier}})
]: nothing -> any {
  http-request {
    method: get
    path: "/feed/details"
    query: [{name: card_id, var: card_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    card_id: $card_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# News Feed Cards List
#
# GET /feed/list
# operationId: newsFeedCardsList
export def "news-feed-cards-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: string # (Optional) Integer The page of cards to return, defaults to 0 (returns the first set of up to 100) (e.g. 1)
  --include-archived: string # (Optional) Boolean Whether or not to include archived cards, defaults to false (e.g. true)
  --sort-direction: string # (Optional) String Pass in the value `desc` to sort by creation time from newest to oldest. Pass in `asc` to sort from oldest to newest. If sort_direction is not included, the default order is oldest to newest. (e.g. desc)
]: nothing -> any {
  http-request {
    method: get
    path: "/feed/list"
    query: [{name: page, var: page}, {name: include_archived, var: include_archived}, {name: sort_direction, var: sort_direction}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, include_archived: $include_archived, sort_direction: $sort_direction
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Daily Active Users by Date
#
# GET /kpi/dau/data_series
# operationId: dailyActiveUsersByDate
export def "daily-active-users-by-date" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --length: string # (Required) Integer Max number of days before ending_at to include in the returned series - must be between 1 and 100 inclusive (e.g. 10)
  --ending-at: string # (Optional) DateTime (ISO 8601 string) Point in time when the data series should end - defaults to time of the request (e.g. 2018-06-28T23:59:59-5:00)
  --app-id: string # (Optional) String App API identifier; if excluded, results for all apps in app group will be returned (e.g. {{app_identifier}})
]: nothing -> any {
  http-request {
    method: get
    path: "/kpi/dau/data_series"
    query: [{name: length, var: length}, {name: ending_at, var: ending_at}, {name: app_id, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    length: $length, ending_at: $ending_at, app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Monthly Active Users for Last 30 Days
#
# GET /kpi/mau/data_series
# operationId: monthlyActiveUsersForLast30Days
export def "monthly-active-users-for-last30-days" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --length: string # (Required) Integer Max number of days before ending_at to include in the returned series - must be between 1 and 100 inclusive (e.g. 7)
  --ending-at: string # (Optional) DateTime (ISO 8601 string) Point in time when the data series should end - defaults to time of the request (e.g. 2018-06-28T23:59:59-05:00)
  --app-id: string # (Optional) String App API identifier; if excluded, results for all apps in app group will be returned (e.g. {{app_identifier}})
]: nothing -> any {
  http-request {
    method: get
    path: "/kpi/mau/data_series"
    query: [{name: length, var: length}, {name: ending_at, var: ending_at}, {name: app_id, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    length: $length, ending_at: $ending_at, app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Daily New Users by Date
#
# GET /kpi/new_users/data_series
# operationId: dailyNewUsersByDate
export def "daily-new-users-by-date" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --length: string # (Required) Integer Max number of days before ending_at to include in the returned series - must be between 1 and 100 inclusive (e.g. 14)
  --ending-at: string # (Optional) DateTime (ISO 8601 string) Point in time when the data series should end - defaults to time of the request (e.g. 2018-06-28T23:59:59-5:00)
  --app-id: string # (Optional) String App API identifier; if excluded, results for all apps in app group will be returned (e.g. {{app_identifier}})
]: nothing -> any {
  http-request {
    method: get
    path: "/kpi/new_users/data_series"
    query: [{name: length, var: length}, {name: ending_at, var: ending_at}, {name: app_id, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    length: $length, ending_at: $ending_at, app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# KPIs for Daily App Uninstalls by Date
#
# GET /kpi/uninstalls/data_series
# operationId: kpIsForDailyAppUninstallsByDate
export def "kp-is-for-daily-app-uninstalls-by-date" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --length: string # (Required) Integer Max number of days before ending_at to include in the returned series - must be between 1 and 100 inclusive (e.g. 14)
  --ending-at: string # (Optional) DateTime (ISO 8601 string) Point in time when the data series should end - defaults to time of the request (e.g. 2018-06-28T23:59:59-5:00)
  --app-id: string # (Optional) String App API identifier; if excluded, results for all apps in app group will be returned (e.g. {{app_identifier}})
]: nothing -> any {
  http-request {
    method: get
    path: "/kpi/uninstalls/data_series"
    query: [{name: length, var: length}, {name: ending_at, var: ending_at}, {name: app_id, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    length: $length, ending_at: $ending_at, app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Upcoming Scheduled Campaigns and Canvases
#
# GET /messages/scheduled_broadcasts
# operationId: getUpcomingScheduledCampaignsAndCanvases
export def "get-upcoming-scheduled-campaigns-and-canvases" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --end-time: string # (Required) String in ISO 8601 format End date of the range to retrieve upcoming scheduled Campaigns and Canvases. This is treated as midnight in UTC time by the API. (e.g. 2018-09-01T00:00:00-04:00)
]: nothing -> any {
  http-request {
    method: get
    path: "/messages/scheduled_broadcasts"
    query: [{name: end_time, var: end_time}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    end_time: $end_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Segment Analytics
#
# GET /segments/data_series
# operationId: segmentAnalytics
export def "segment-analytics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --segment-id: string # (Required) String Segment API identifier. (e.g. {{segment_identifier}})
  --length: string # (Required) Integer Max number of days before `ending_at` to include in the returned series - must be between 1 and 100 inclusive. (e.g. 14)
  --ending-at: string # (Optional) DateTime (ISO 8601 string) Point in time when the data series should end - defaults to time of the request. (e.g. 2018-06-27T23:59:59-5:00)
]: nothing -> any {
  http-request {
    method: get
    path: "/segments/data_series"
    query: [{name: segment_id, var: segment_id}, {name: length, var: length}, {name: ending_at, var: ending_at}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    segment_id: $segment_id, length: $length, ending_at: $ending_at
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Segment Details
#
# GET /segments/details
# operationId: segmentDetails
export def "segment-details" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --segment-id: string # (Required) String Segment API identifier (e.g. {{segment_identifier}})
]: nothing -> any {
  http-request {
    method: get
    path: "/segments/details"
    query: [{name: segment_id, var: segment_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    segment_id: $segment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Segment List
#
# GET /segments/list
# operationId: segmentList
export def "segment-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: string # (Optional) Integer The page of segments to return, defaults to 0 (returns the first set of up to 100) (e.g. 1)
  --sort-direction: string # (Optional) String Pass in the value `desc` to sort by creation time from newest to oldest. Pass in `asc` to sort from oldest to newest. If `sort_direction` is not included, the default order is oldest to newest. (e.g. desc)
]: nothing -> any {
  http-request {
    method: get
    path: "/segments/list"
    query: [{name: page, var: page}, {name: sort_direction, var: sort_direction}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, sort_direction: $sort_direction
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send Analytics
#
# GET /sends/data_series
# operationId: sendAnalytics
export def "send-analytics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --campaign-id: string # (Required) String Campaign API identifier. (e.g. {{campaign_identifier}})
  --send-id: string # (Required) String Send API identifier. (e.g. {{send_identifier}})
  --length: string # (Required) Integer Maximum number of days before `ending_at` to include in the returned series. Must be between 1 and 100 inclusive. (e.g. 30)
  --ending-at: string # (Optional) Datetime ISO 8601 string Date on which the data series should end. Defaults to time of the request. (e.g. 2014-12-10T23:59:59-05:00)
]: nothing -> any {
  http-request {
    method: get
    path: "/sends/data_series"
    query: [{name: campaign_id, var: campaign_id}, {name: send_id, var: send_id}, {name: length, var: length}, {name: ending_at, var: ending_at}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    campaign_id: $campaign_id, send_id: $send_id, length: $length, ending_at: $ending_at
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# App Sessions by Time
#
# GET /sessions/data_series
# operationId: appSessionsByTime
export def "app-sessions-by-time" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --length: string # (Required) Integer Max number of units (days or hours) before ending_at to include in the returned series - must be between 1 and 100 inclusive. (e.g. 14)
  --unit: string # (Optional) String Unit of time between data points - can be "day" or "hour" (defaults to "day"). (e.g. day)
  --ending-at: string # (Optional) DateTime (ISO 8601 string) Point in time when the data series should end - defaults to time of the request. (e.g. 2018-06-28T23:59:59-5:00)
  --app-id: string # (Optional) String App API identifier retrieved from the Developer Console to limit analytics to a specific app. (e.g. {{app_identifier}})
  --segment-id: string # (Optional) String Segment API identifier indicating the analytics enabled segment for which sessions should be returned. (e.g. {{segment_identifier}})
]: nothing -> any {
  http-request {
    method: get
    path: "/sessions/data_series"
    query: [{name: length, var: length}, {name: unit, var: unit}, {name: ending_at, var: ending_at}, {name: app_id, var: app_id}, {name: segment_id, var: segment_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    length: $length, unit: $unit, ending_at: $ending_at, app_id: $app_id, segment_id: $segment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List User's Subscription Group Status - SMS
#
# GET /subscription/status/get
# operationId: listUser'sSubscriptionGroupStatusSms
export def "list-users-subscription-group-status-sms" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --subscription-group-id: string # (Required) String The `id` of your subscription group. (e.g. {{subscription_group_id}})
  --external-id: string # (Required*) String The `external_id` of the user (must include at least one and at most 50 `external_ids`). Only external_id or phone is accepted for SMS subscription groups (e.g. {{external_identifier}})
  --phone: string # (Required*) String The phone number of the user (must include at least one phone number and at most 50 phone numbers). The recommendation is to provide this in the E.164 format. Only external_id or phone is accepted for SMS subscription groups (e.g. +11112223333)
]: nothing -> any {
  http-request {
    method: get
    path: "/subscription/status/get"
    query: [{name: subscription_group_id, var: subscription_group_id}, {name: external_id, var: external_id}, {name: phone, var: phone}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_group_id: $subscription_group_id, external_id: $external_id, phone: $phone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List User's Subscription Group - SMS
#
# GET /subscription/user/status
# operationId: listUser'sSubscriptionGroupSms
export def "list-users-subscription-group-sms" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --external-id: string # (Required*) String The external_id of the user. Must include at least one and at most 50 `external_ids`. (e.g. {{external_id}})
  --limit: string # (Optional) Integer The limit on the maximum number of results returned. Default (and max) limit is 100. (e.g. 100)
  --offset: string # (Optional) Integer Number of templates to skip before returning rest of the templates that fit the search criteria. (e.g. 1)
  --phone: string # (Required*) String The phone number of the user (must include at least one phone number and at most 50 phone numbers). The recommendation is to provide this in the E.164 format. (e.g. +11112223333)
]: nothing -> any {
  http-request {
    method: get
    path: "/subscription/user/status"
    query: [{name: external_id, var: external_id}, {name: limit, var: limit}, {name: offset, var: offset}, {name: phone, var: phone}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    external_id: $external_id, limit: $limit, offset: $offset, phone: $phone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# See Email Template Information
#
# GET /templates/email/info
# operationId: seeEmailTemplateInformation
export def "see-email-template-information" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email-template-id: string # (Required) String Your email template's API Identifier. (e.g. {{email_template_id}})
]: nothing -> any {
  http-request {
    method: get
    path: "/templates/email/info"
    query: [{name: email_template_id, var: email_template_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    email_template_id: $email_template_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Available Email Templates
#
# GET /templates/email/list
# operationId: listAvailableEmailTemplates
export def "list-available-email-templates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --modified-after: string # (Optional) String in ISO 8601 Retrieve only templates updated at or after the given time. (e.g. 2020-01-01T01:01:01.000000)
  --modified-before: string # (Optional) String in ISO 8601 Retrieve only templates updated at or before the given time (e.g. 2020-02-01T01:01:01.000000)
  --limit: string # (Optional) Positive Number Maximum number of templates to retrieve, default to 100 if not provided, maximum acceptable value is 1000. (e.g. 1)
  --offset: string # (Optional) Positive Number Number of templates to skip before returning rest of the templates that fit the search criteria. (e.g. 0)
]: nothing -> any {
  http-request {
    method: get
    path: "/templates/email/list"
    query: [{name: modified_after, var: modified_after}, {name: modified_before, var: modified_before}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    modified_after: $modified_after, modified_before: $modified_before, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
