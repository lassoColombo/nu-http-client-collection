# Auto-generated client for Paylocity API v2
# Source: https://api.apis.guru/v2/specs/paylocity.com/2/openapi.json
# Auth: --token flag or $env.PAYLOCITY_API_TOKEN

const CLIENT = {
  base_url: "https://api.paylocity.com/api"
  token_env_var: "PAYLOCITY_API_TOKEN"
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

def base-url-completer [] { ["https://api.paylocity.com/api"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-all-company-codes-and-descriptions-by-resource: "table<code: string, description: string>"
    get-all-custom-fields-by-category: "table<category: string, defaultValue: string, isRequired: bool, label: string, type: string, values: list<record>>"
    add-employee: "record<employeeId: string>"
    get-all-employees: "table<employeeId: string, statusCode: string, statusTypeCode: string>"
    get-employee: "record<additionalDirectDeposit: table<accountNumber: string, accountType: string, amount: float, amountType: string, blockSpecial: bool, isSkipPreNote: bool, nameOnAccount: string, preNoteDate: string, routingNumber: string>, additionalRate: table<changeReason: string, costCenter1: string, costCenter2: string, costCenter3: string, effectiveDate: string, endCheckDate: string, job: string, rate: float, rateCode: string, rateNotes: string, ratePer: string, shift: string>, benefitSetup: record<benefitClass: string, benefitClassEffectiveDate: string, benefitSalary: float, benefitSalaryEffectiveDate: string, doNotApplyAdministrativePeriod: bool, isMeasureAcaEligibility: bool>, birthDate: string, coEmpCode: string, companyFEIN: string, companyName: string, currency: string, customBooleanFields: table<category: string, label: string, value: bool>, customDateFields: table<category: string, label: string, value: string>, customDropDownFields: table<category: string, label: string, value: string>, customNumberFields: table<category: string, label: string, value: float>, customTextFields: table<category: string, label: string, value: string>, departmentPosition: record<changeReason: string, clockBadgeNumber: string, costCenter1: string, costCenter2: string, costCenter3: string, effectiveDate: string, employeeType: string, equalEmploymentOpportunityClass: string, isMinimumWageExempt: bool, isOvertimeExempt: bool, isSupervisorReviewer: bool, isUnionDuesCollected: bool, isUnionInitiationCollected: bool, jobTitle: string, payGroup: string, positionCode: string, reviewerCompanyNumber: string, reviewerEmployeeId: string, shift: string, supervisorCompanyNumber: string, supervisorEmployeeId: string, tipped: string, unionAffiliationDate: string, unionCode: string, unionPosition: string, workersCompensation: string>, disabilityDescription: string, emergencyContacts: table<address1: string, address2: string, city: string, country: string, county: string, email: string, firstName: string, homePhone: string, lastName: string, mobilePhone: string, notes: string, pager: string, primaryPhone: string, priority: string, relationship: string, state: string, syncEmployeeInfo: bool, workExtension: string, workPhone: string, zip: string>, employeeId: string, ethnicity: string, federalTax: record<amount: float, deductionsAmount: float, dependentsAmount: float, exemptions: float, filingStatus: string, higherRate: bool, otherIncomeAmount: float, percentage: float, taxCalculationCode: string, w4FormYear: int>, firstName: string, gender: string, homeAddress: record<address1: string, address2: string, city: string, country: string, county: string, emailAddress: string, mobilePhone: string, phone: string, postalCode: string, state: string>, isHighlyCompensated: bool, isSmoker: bool, lastName: string, localTax: table<exemptions: float, exemptions2: float, filingStatus: string, residentPSD: string, taxCode: string, workPSD: string>, mainDirectDeposit: record<accountNumber: string, accountType: string, blockSpecial: bool, isSkipPreNote: bool, nameOnAccount: string, preNoteDate: string, routingNumber: string>, maritalStatus: string, middleName: string, nonPrimaryStateTax: record<amount: float, deductionsAmount: float, dependentsAmount: float, exemptions: float, exemptions2: float, filingStatus: string, higherRate: bool, otherIncomeAmount: float, percentage: float, reciprocityCode: string, specialCheckCalc: string, taxCalculationCode: string, taxCode: string, w4FormYear: int>, ownerPercent: float, preferredName: string, primaryPayRate: record<annualSalary: float, baseRate: float, beginCheckDate: string, changeReason: string, defaultHours: float, effectiveDate: string, isAutoPay: bool, payFrequency: string, payGrade: string, payRateNote: string, payType: string, ratePer: string, salary: float>, primaryStateTax: record<amount: float, deductionsAmount: float, dependentsAmount: float, exemptions: float, exemptions2: float, filingStatus: string, higherRate: bool, otherIncomeAmount: float, percentage: float, specialCheckCalc: string, taxCalculationCode: string, taxCode: string, w4FormYear: int>, priorLastName: string, salutation: string, ssn: string, status: record<adjustedSeniorityDate: string, changeReason: string, effectiveDate: string, employeeStatus: string, hireDate: string, isEligibleForRehire: bool, reHireDate: string, statusType: string, terminationDate: string>, suffix: string, taxSetup: record<fitwExemptNotes: string, fitwExemptReason: string, futaExemptNotes: string, futaExemptReason: string, isEmployee943: bool, isPension: bool, isStatutory: bool, medExemptNotes: string, medExemptReason: string, sitwExemptNotes: string, sitwExemptReason: string, ssExemptNotes: string, ssExemptReason: string, suiExemptNotes: string, suiExemptReason: string, suiState: string, taxDistributionCode1099R: string, taxForm: string>, veteranDescription: string, webTime: record<badgeNumber: string, chargeRate: float, isTimeLaborEnabled: bool>, workAddress: record<address1: string, address2: string, city: string, country: string, county: string, emailAddress: string, location: string, mailStop: string, mobilePhone: string, pager: string, phone: string, phoneExtension: string, postalCode: string, state: string>, workEligibility: record<alienOrAdmissionDocumentNumber: string, attestedDate: string, countryOfIssuance: string, foreignPassportNumber: string, i94AdmissionNumber: string, i9DateVerified: string, i9Notes: string, isI9Verified: bool, isSsnVerified: bool, ssnDateVerified: string, ssnNotes: string, visaType: string, workAuthorization: string, workUntil: string>>"
    get-all-direct-deposit: "table<additionalDirectDeposit: list<record>, mainDirectDeposit: record<accountNumber: string, accountType: string, blockSpecial: bool, isSkipPreNote: bool, nameOnAccount: string, preNoteDate: string, routingNumber: string>>"
    get-all-earnings: "table<agency: string, amount: float, annualMaximum: float, calculationCode: string, costCenter1: string, costCenter2: string, costCenter3: string, earningCode: string, effectiveDate: string, endDate: string, frequency: string, goal: float, hoursOrUnits: float, isSelfInsured: bool, jobCode: string, miscellaneousInfo: string, paidTowardsGoal: float, payPeriodMaximum: float, payPeriodMinimum: float, rate: float, rateCode: string, startDate: string>"
    get-earnings-by-earning-code: "table<agency: string, amount: float, annualMaximum: float, calculationCode: string, costCenter1: string, costCenter2: string, costCenter3: string, earningCode: string, effectiveDate: string, endDate: string, frequency: string, goal: float, hoursOrUnits: float, isSelfInsured: bool, jobCode: string, miscellaneousInfo: string, paidTowardsGoal: float, payPeriodMaximum: float, payPeriodMinimum: float, rate: float, rateCode: string, startDate: string>"
    get-earning-by-earning-code-and-start-date: "record<agency: string, amount: float, annualMaximum: float, calculationCode: string, costCenter1: string, costCenter2: string, costCenter3: string, earningCode: string, effectiveDate: string, endDate: string, frequency: string, goal: float, hoursOrUnits: float, isSelfInsured: bool, jobCode: string, miscellaneousInfo: string, paidTowardsGoal: float, payPeriodMaximum: float, payPeriodMinimum: float, rate: float, rateCode: string, startDate: string>"
    get-all-local-taxes: "table<exemptions: float, exemptions2: float, filingStatus: string, residentPSD: string, taxCode: string, workPSD: string>"
    get-local-tax-by-tax-code: "table<exemptions: float, exemptions2: float, filingStatus: string, residentPSD: string, taxCode: string, workPSD: string>"
    gets-employee-pay-statement-detail-data-based-on-the-specified-year: "table<amount: float, checkDate: string, det: string, detCode: string, detType: string, eligibleCompensation: float, hours: float, rate: float, transactionNumber: int, transactionType: string, year: int>"
    gets-employee-pay-statement-detail-data-based-on-the-specified-year-and-check-date: "table<amount: float, checkDate: string, det: string, detCode: string, detType: string, eligibleCompensation: float, hours: float, rate: float, transactionNumber: int, transactionType: string, year: int>"
    gets-employee-pay-statement-summary-data-based-on-the-specified-year: "table<autoPay: bool, beginDate: string, checkDate: string, checkNumber: int, directDepositAmount: float, endDate: string, grossPay: float, hours: float, netCheck: float, netPay: float, overtimeDollars: float, overtimeHours: float, process: int, regularDollars: float, regularHours: float, transactionNumber: int, voucherNumber: int, workersCompCode: string, year: int>"
    gets-employee-pay-statement-summary-data-based-on-the-specified-year-and-check-date: "table<autoPay: bool, beginDate: string, checkDate: string, checkNumber: int, directDepositAmount: float, endDate: string, grossPay: float, hours: float, netCheck: float, netPay: float, overtimeDollars: float, overtimeHours: float, process: int, regularDollars: float, regularHours: float, transactionNumber: int, voucherNumber: int, workersCompCode: string, year: int>"
    get-sensitive-data: "table<disability: record<disability: string, disabilityClassifications: list, hasDisability: string>, ethnicity: record<ethnicRacialIdentities: list, ethnicity: string>, gender: record<displayPronouns: bool, genderIdentityDescription: string, identifyAsLegalGender: string, legalGender: string, pronouns: string, sexualOrientation: string>, veteran: record<isVeteran: string, veteran: string>>"
    add-client-secret: "table<clientSecret: string, clientSecretExpirationDate: string>"
    add-new-employee-to-web-link: "table<trackingNumber: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-all-company-codes-and-descriptions-by-resource" "get-all-custom-fields-by-category" "add-employee" "get-all-employees" "get-employee" "update-employee" "add-or-update-additional-rates" "update-or-add-employee-benefit-setup" "get-all-direct-deposit" "get-all-earnings" "add-or-update-an-employee-earning" "get-earnings-by-earning-code" "delete-earning-by-earning-code-and-start-date" "get-earning-by-earning-code-and-start-date" "add-or-update-emergency-contacts" "get-all-local-taxes" "add-local-tax" "delete-local-tax-by-tax-code" "get-local-tax-by-tax-code" "add-or-update-non-primary-state-tax" "gets-employee-pay-statement-detail-data-based-on-the-specified-year" "gets-employee-pay-statement-detail-data-based-on-the-specified-year-and-check-date" "gets-employee-pay-statement-summary-data-based-on-the-specified-year" "gets-employee-pay-statement-summary-data-based-on-the-specified-year-and-check-date" "add-or-update-primary-state-tax" "get-sensitive-data" "add-or-update-sensitive-data" "get-company-specific-open-api-documentation" "add-client-secret" "add-new-employee-to-web-link" "commands"] | sort) } | get name | first)
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

# Get All Company Codes
#
# GET /v2/companies/{companyId}/codes/{codeResource}
# Returns: table<code: string, description: string>
# operationId: Get All Company Codes and Descriptions by Resource
export def "get-all-company-codes-and-descriptions-by-resource" [
  company_id: string
  code_resource: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v2/companies/{companyId}/codes/{codeResource}"
    path_params: [{name: companyId, var: company_id}, {name: codeResource, var: code_resource}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, code_resource: $code_resource
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get All Custom Fields
#
# GET /v2/companies/{companyId}/customfields/{category}
# Returns: table<category: string, defaultValue: string, isRequired: bool, label: string, type: string, values: list<record>>
# operationId: Get All Custom Fields by category
export def "get-all-custom-fields-by-category" [
  company_id: string
  category: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v2/companies/{companyId}/customfields/{category}"
    path_params: [{name: companyId, var: company_id}, {name: category, var: category}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, category: $category
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add new employee
#
# POST /v2/companies/{companyId}/employees
# Returns: record<employeeId: string>
# operationId: Add employee
export def "add-employee" [
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --additional-direct-deposit: list # Add up to 19 direct deposit accounts in addition to the main direct deposit account. IMPORTANT: A direct deposit update will remove ALL existing main and additional direct deposit information in WebPay and replace with information provided on the request. GET API will not return direct deposit data. — item shape: {accountNumber?: string, accountType?: string, amount?: float, amountType?: string, blockSpecial?: bool, isSkipPreNote?: bool, nameOnAccount?: string, preNoteDate?: string, routingNumber?: string}
  --additional-rate: list # Add Additional Rates. — item shape: {changeReason?: string, costCenter1?: string, costCenter2?: string, costCenter3?: string, effectiveDate?: string, endCheckDate?: string, job?: string, rate?: float, rateCode?: string, rateNotes?: string, ratePer?: string, shift?: string}
  --benefit-setup: record # Add or update setup values used for employee benefits integration, insurance plan settings, and ACA reporting. — shape: {benefitClass?: string, benefitClassEffectiveDate?: string, benefitSalary?: float, benefitSalaryEffectiveDate?: string, doNotApplyAdministrativePeriod?: bool, isMeasureAcaEligibility?: bool}
  --birth-date: string # Employee birthdate. Common formats include *MM-DD-CCYY*, *CCYY-MM-DD*. (nullable, format: paylocity-date)
  --co-emp-code: string # Unique idenifier for SSO.Max length: 20 (nullable)
  --company-fein: string # Company FEIN as defined in Web Pay, applicable with GET requests only. Max length: 20 (nullable)
  --company-name: string # Company name as defined in Web Pay, applicable with GET requests only. Max length: 50 (nullable)
  --currency: string # Employee is paid in this currency. Max length: 30 (nullable)
  --custom-boolean-fields: list # Up to 8 custom fields of boolean (checkbox) type value. — item shape: {category: "PayrollAndHR", label: string, value: bool}
  --custom-date-fields: list # Up to 8 custom fields of the date type value. — item shape: {category: "PayrollAndHR", label: string, value: string}
  --custom-drop-down-fields: list # Up to 8 custom fields of the dropdown type value. — item shape: {category: "PayrollAndHR", label: string, value: string}
  --custom-number-fields: list # Up to 8 custom fields of numeric type value. — item shape: {category: "PayrollAndHR", label: string, value: float}
  --custom-text-fields: list # Up to 8 custom fields of text type value. — item shape: {category: "PayrollAndHR", label: string, value: string}
  --department-position: record # Add or update home department cost center, position, supervisor, reviewer, employment type, EEO class, pay settings, and union information. — shape: {changeReason?: string, clockBadgeNumber?: string, costCenter1?: string, costCenter2?: string, costCenter3?: string, effectiveDate?: string, employeeType?: string, equalEmploymentOpportunityClass?: string, isMinimumWageExempt?: bool, isOvertimeExempt?: bool, isSupervisorReviewer?: bool, isUnionDuesCollected?: bool, isUnionInitiationCollected?: bool, jobTitle?: string, payGroup?: string, positionCode?: string, reviewerCompanyNumber?: string, reviewerEmployeeId?: string, shift?: string, ... (7 more fields)}
  --disability-description: string # Indicates if employee has disability status. (nullable)
  --emergency-contacts: list # Add or update Emergency Contacts. — item shape: {address1?: string, address2?: string, city?: string, country?: string, county?: string, email?: string, firstName: string, homePhone?: string, lastName: string, mobilePhone?: string, notes?: string, pager?: string, primaryPhone?: string, priority?: string, relationship?: string, state?: string, syncEmployeeInfo?: bool, workExtension?: string, workPhone?: string, zip?: string}
  --employee-id: string # Leave blank to have Web Pay automatically assign the next available employee ID.Max length: 9 (nullable)
  --ethnicity: string # Employee ethnicity. Max length: 10 (nullable)
  --federal-tax: record # Add or update federal tax amount type (taxCalculationCode), amount or percentage, filing status, and exemptions. — shape: {amount?: float, deductionsAmount?: float, dependentsAmount?: float, exemptions?: float, filingStatus?: string, higherRate?: bool, otherIncomeAmount?: float, percentage?: float, taxCalculationCode?: string, w4FormYear?: int}
  --first-name: string # Employee first name. Max length: 40 (nullable)
  --gender: string # Employee gender. Common values *M* (Male), *F* (Female). Max length: 1 (nullable)
  --home-address: record # Add or update employee's home address, personal phone numbers, and personal email. — shape: {address1?: string, address2?: string, city?: string, country?: string, county?: string, emailAddress?: string, mobilePhone?: string, phone?: string, postalCode?: string, state?: string}
  --is-highly-compensated: oneof<nothing, bool> # Indicates if employee meets the highly compensated employee criteria.
  --is-smoker: oneof<nothing, bool> # Indicates if employee is a smoker.
  --last-name: string # Employee last name. Max length: 40 (nullable)
  --local-tax: list # Add, update, or delete local tax code, filing status, and exemptions including PA-PSD taxes. — item shape: {exemptions?: float, exemptions2?: float, filingStatus?: string, residentPSD?: string, taxCode?: string, workPSD?: string}
  --main-direct-deposit: record # Add the main direct deposit account. After deposits are made to any additional direct deposit accounts, the remaining net check is deposited in the main direct deposit account. IMPORTANT: A direct deposit update will remove ALL existing main and additional direct deposit information in WebPay and replace with what is provided on the request. GET API will not return direct deposit data. — shape: {accountNumber?: string, accountType?: string, blockSpecial?: bool, isSkipPreNote?: bool, nameOnAccount?: string, preNoteDate?: string, routingNumber?: string}
  --marital-status: string # Employee marital status. Common values *D (Divorced), M (Married), S (Single), W (Widowed)*. Max length: 10 (nullable)
  --middle-name: string # Employee middle name. Max length: 20 (nullable)
  --non-primary-state-tax: record # Add or update non-primary state tax code, amount type (taxCalculationCode), amount or percentage, filing status, exemptions, supplemental check (specialCheckCalc), and reciprocity code information. — shape: {amount?: float, deductionsAmount?: float, dependentsAmount?: float, exemptions?: float, exemptions2?: float, filingStatus?: string, higherRate?: bool, otherIncomeAmount?: float, percentage?: float, reciprocityCode?: string, specialCheckCalc?: string, taxCalculationCode?: string, taxCode?: string, w4FormYear?: int}
  --owner-percent: float # Percentage of employee's ownership in the company, entered as a whole number. Decimal (12,2) (nullable)
  --preferred-name: string # Employee preferred display name. Max length: 20 (nullable)
  --primary-pay-rate: record # Add or update hourly or salary pay rate, effective date, and pay frequency. — shape: {annualSalary?: float, baseRate?: float, beginCheckDate?: string, changeReason?: string, defaultHours?: float, effectiveDate?: string, isAutoPay?: bool, payFrequency?: string, payGrade?: string, payRateNote?: string, payType?: string, ratePer?: string, salary?: float}
  --primary-state-tax: record # Add or update primary state tax code, amount type (taxCalculationCode), amount or percentage, filing status, exemptions, and supplemental check (specialCheckCalc) information. Only one primary state is allowed. Sending an updated primary state will replace the current primary state. — shape: {amount?: float, deductionsAmount?: float, dependentsAmount?: float, exemptions?: float, exemptions2?: float, filingStatus?: string, higherRate?: bool, otherIncomeAmount?: float, percentage?: float, specialCheckCalc?: string, taxCalculationCode?: string, taxCode?: string, w4FormYear?: int}
  --prior-last-name: string # Prior last name if applicable.Max length: 40 (nullable)
  --salutation: string # Employee preferred salutation. Max length: 10 (nullable)
  --ssn: string # Employee social security number. Leave it blank if valid social security number not available. Max length: 11 (nullable)
  --status: record # Add or update employee status, change reason, effective date, and adjusted seniority date. Note that companies that are still in Implementation cannot hire future employees. — shape: {adjustedSeniorityDate?: string, changeReason?: string, effectiveDate?: string, employeeStatus?: string, hireDate?: string, isEligibleForRehire?: bool, reHireDate?: string, statusType?: string, terminationDate?: string}
  --suffix: string # Employee name suffix. Common values are *Jr, Sr, II*.Max length: 30 (nullable)
  --tax-setup: record # Add tax form, 1099 exempt reasons and notes, and 943 agricultural employee information. Once the employee receives wages, this information cannot be updated. Add or update SUI tax state, retirement plan, and statutory information. — shape: {fitwExemptNotes?: string, fitwExemptReason?: string, futaExemptNotes?: string, futaExemptReason?: string, isEmployee943?: bool, isPension?: bool, isStatutory?: bool, medExemptNotes?: string, medExemptReason?: string, sitwExemptNotes?: string, sitwExemptReason?: string, ssExemptNotes?: string, ssExemptReason?: string, suiExemptNotes?: string, suiExemptReason?: string, suiState?: string, taxDistributionCode1099R?: string, taxForm?: string}
  --veteran-description: string # Indicates if employee is a veteran. (nullable)
  --web-time: record # Add or update Web Time badge number and charge rate and synchronize Web Pay and Web Time employee data. — shape: {badgeNumber?: string, chargeRate?: float, isTimeLaborEnabled?: bool}
  --work-address: record # Add or update employee's work address, phone numbers, and email. Work Location drop down field is not included. — shape: {address1?: string, address2?: string, city?: string, country?: string, county?: string, emailAddress?: string, location?: string, mailStop?: string, mobilePhone?: string, pager?: string, phone?: string, phoneExtension?: string, postalCode?: string, state?: string}
  --work-eligibility: record # Add or update I-9 work authorization information. — shape: {alienOrAdmissionDocumentNumber?: string, attestedDate?: string, countryOfIssuance?: string, foreignPassportNumber?: string, i94AdmissionNumber?: string, i9DateVerified?: string, i9Notes?: string, isI9Verified?: bool, isSsnVerified?: bool, ssnDateVerified?: string, ssnNotes?: string, visaType?: string, workAuthorization?: string, workUntil?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/companies/{companyId}/employees"
    path_params: [{name: companyId, var: company_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: additionalDirectDeposit, var: additional_direct_deposit}, {name: additionalRate, var: additional_rate}, {name: benefitSetup, var: benefit_setup}, {name: birthDate, var: birth_date}, {name: coEmpCode, var: co_emp_code}, {name: companyFEIN, var: company_fein}, {name: companyName, var: company_name}, {name: currency, var: currency}, {name: customBooleanFields, var: custom_boolean_fields}, {name: customDateFields, var: custom_date_fields}, {name: customDropDownFields, var: custom_drop_down_fields}, {name: customNumberFields, var: custom_number_fields}, {name: customTextFields, var: custom_text_fields}, {name: departmentPosition, var: department_position}, {name: disabilityDescription, var: disability_description}, {name: emergencyContacts, var: emergency_contacts}, {name: employeeId, var: employee_id}, {name: ethnicity, var: ethnicity}, {name: federalTax, var: federal_tax}, {name: firstName, var: first_name}, {name: gender, var: gender}, {name: homeAddress, var: home_address}, {name: isHighlyCompensated, var: is_highly_compensated}, {name: isSmoker, var: is_smoker}, {name: lastName, var: last_name}, {name: localTax, var: local_tax}, {name: mainDirectDeposit, var: main_direct_deposit}, {name: maritalStatus, var: marital_status}, {name: middleName, var: middle_name}, {name: nonPrimaryStateTax, var: non_primary_state_tax}, {name: ownerPercent, var: owner_percent}, {name: preferredName, var: preferred_name}, {name: primaryPayRate, var: primary_pay_rate}, {name: primaryStateTax, var: primary_state_tax}, {name: priorLastName, var: prior_last_name}, {name: salutation, var: salutation}, {name: ssn, var: ssn}, {name: status, var: status}, {name: suffix, var: suffix}, {name: taxSetup, var: tax_setup}, {name: veteranDescription, var: veteran_description}, {name: webTime, var: web_time}, {name: workAddress, var: work_address}, {name: workEligibility, var: work_eligibility}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    company_id: $company_id, additional_direct_deposit: $additional_direct_deposit, additional_rate: $additional_rate, benefit_setup: $benefit_setup, birth_date: $birth_date, co_emp_code: $co_emp_code, company_fein: $company_fein, company_name: $company_name, currency: $currency, custom_boolean_fields: $custom_boolean_fields, custom_date_fields: $custom_date_fields, custom_drop_down_fields: $custom_drop_down_fields, custom_number_fields: $custom_number_fields, custom_text_fields: $custom_text_fields, department_position: $department_position, disability_description: $disability_description, emergency_contacts: $emergency_contacts, employee_id: $employee_id, ethnicity: $ethnicity, federal_tax: $federal_tax, first_name: $first_name, gender: $gender, home_address: $home_address, is_highly_compensated: $is_highly_compensated, is_smoker: $is_smoker, last_name: $last_name, local_tax: $local_tax, main_direct_deposit: $main_direct_deposit, marital_status: $marital_status, middle_name: $middle_name, non_primary_state_tax: $non_primary_state_tax, owner_percent: $owner_percent, preferred_name: $preferred_name, primary_pay_rate: $primary_pay_rate, primary_state_tax: $primary_state_tax, prior_last_name: $prior_last_name, salutation: $salutation, ssn: $ssn, status: $status, suffix: $suffix, tax_setup: $tax_setup, veteran_description: $veteran_description, web_time: $web_time, work_address: $work_address, work_eligibility: $work_eligibility
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all employees
#
# GET /v2/companies/{companyId}/employees/
# Returns: table<employeeId: string, statusCode: string, statusTypeCode: string>
# operationId: Get all employees
export def "get-all-employees" [
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagesize: int # Number of records per page. Default value is 25.
  --pagenumber: int # Page number to retrieve; page numbers are 0-based (so to get the first page of results, pass pagenumber=0). Default value is 0.
  --includetotalcount: oneof<nothing, bool> # Whether to include the total record count in the header's X-Pcty-Total-Count property. Default value is true.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v2/companies/{companyId}/employees/"
    path_params: [{name: companyId, var: company_id}]
    query: [{name: pagesize, var: pagesize}, {name: pagenumber, var: pagenumber}, {name: includetotalcount, var: includetotalcount}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, pagesize: $pagesize, pagenumber: $pagenumber, includetotalcount: $includetotalcount
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get employee
#
# GET /v2/companies/{companyId}/employees/{employeeId}
# Returns: record<additionalDirectDeposit: table<accountNumber: string, accountType: string, amount: float, amountType: string, blockSpecial: bool, isSkipPreNote: bool, nameOnAccount: string, preNoteDate: string, routingNumber: string>, additionalRate: table<changeReason: string, costCenter1: string, costCenter2: string, costCenter3: string, effectiveDate: string, endCheckDate: string, job: string, rate: float, rateCode: string, rateNotes: string, ratePer: string, shift: string>, benefitSetup: record<benefitClass: string, benefitClassEffectiveDate: string, benefitSalary: float, benefitSalaryEffectiveDate: string, doNotApplyAdministrativePeriod: bool, isMeasureAcaEligibility: bool>, birthDate: string, coEmpCode: string, companyFEIN: string, companyName: string, currency: string, customBooleanFields: table<category: string, label: string, value: bool>, customDateFields: table<category: string, label: string, value: string>, customDropDownFields: table<category: string, label: string, value: string>, customNumberFields: table<category: string, label: string, value: float>, customTextFields: table<category: string, label: string, value: string>, departmentPosition: record<changeReason: string, clockBadgeNumber: string, costCenter1: string, costCenter2: string, costCenter3: string, effectiveDate: string, employeeType: string, equalEmploymentOpportunityClass: string, isMinimumWageExempt: bool, isOvertimeExempt: bool, isSupervisorReviewer: bool, isUnionDuesCollected: bool, isUnionInitiationCollected: bool, jobTitle: string, payGroup: string, positionCode: string, reviewerCompanyNumber: string, reviewerEmployeeId: string, shift: string, supervisorCompanyNumber: string, supervisorEmployeeId: string, tipped: string, unionAffiliationDate: string, unionCode: string, unionPosition: string, workersCompensation: string>, disabilityDescription: string, emergencyContacts: table<address1: string, address2: string, city: string, country: string, county: string, email: string, firstName: string, homePhone: string, lastName: string, mobilePhone: string, notes: string, pager: string, primaryPhone: string, priority: string, relationship: string, state: string, syncEmployeeInfo: bool, workExtension: string, workPhone: string, zip: string>, employeeId: string, ethnicity: string, federalTax: record<amount: float, deductionsAmount: float, dependentsAmount: float, exemptions: float, filingStatus: string, higherRate: bool, otherIncomeAmount: float, percentage: float, taxCalculationCode: string, w4FormYear: int>, firstName: string, gender: string, homeAddress: record<address1: string, address2: string, city: string, country: string, county: string, emailAddress: string, mobilePhone: string, phone: string, postalCode: string, state: string>, isHighlyCompensated: bool, isSmoker: bool, lastName: string, localTax: table<exemptions: float, exemptions2: float, filingStatus: string, residentPSD: string, taxCode: string, workPSD: string>, mainDirectDeposit: record<accountNumber: string, accountType: string, blockSpecial: bool, isSkipPreNote: bool, nameOnAccount: string, preNoteDate: string, routingNumber: string>, maritalStatus: string, middleName: string, nonPrimaryStateTax: record<amount: float, deductionsAmount: float, dependentsAmount: float, exemptions: float, exemptions2: float, filingStatus: string, higherRate: bool, otherIncomeAmount: float, percentage: float, reciprocityCode: string, specialCheckCalc: string, taxCalculationCode: string, taxCode: string, w4FormYear: int>, ownerPercent: float, preferredName: string, primaryPayRate: record<annualSalary: float, baseRate: float, beginCheckDate: string, changeReason: string, defaultHours: float, effectiveDate: string, isAutoPay: bool, payFrequency: string, payGrade: string, payRateNote: string, payType: string, ratePer: string, salary: float>, primaryStateTax: record<amount: float, deductionsAmount: float, dependentsAmount: float, exemptions: float, exemptions2: float, filingStatus: string, higherRate: bool, otherIncomeAmount: float, percentage: float, specialCheckCalc: string, taxCalculationCode: string, taxCode: string, w4FormYear: int>, priorLastName: string, salutation: string, ssn: string, status: record<adjustedSeniorityDate: string, changeReason: string, effectiveDate: string, employeeStatus: string, hireDate: string, isEligibleForRehire: bool, reHireDate: string, statusType: string, terminationDate: string>, suffix: string, taxSetup: record<fitwExemptNotes: string, fitwExemptReason: string, futaExemptNotes: string, futaExemptReason: string, isEmployee943: bool, isPension: bool, isStatutory: bool, medExemptNotes: string, medExemptReason: string, sitwExemptNotes: string, sitwExemptReason: string, ssExemptNotes: string, ssExemptReason: string, suiExemptNotes: string, suiExemptReason: string, suiState: string, taxDistributionCode1099R: string, taxForm: string>, veteranDescription: string, webTime: record<badgeNumber: string, chargeRate: float, isTimeLaborEnabled: bool>, workAddress: record<address1: string, address2: string, city: string, country: string, county: string, emailAddress: string, location: string, mailStop: string, mobilePhone: string, pager: string, phone: string, phoneExtension: string, postalCode: string, state: string>, workEligibility: record<alienOrAdmissionDocumentNumber: string, attestedDate: string, countryOfIssuance: string, foreignPassportNumber: string, i94AdmissionNumber: string, i9DateVerified: string, i9Notes: string, isI9Verified: bool, isSsnVerified: bool, ssnDateVerified: string, ssnNotes: string, visaType: string, workAuthorization: string, workUntil: string>>
# operationId: Get employee
export def "get-employee" [
  company_id: string
  employee_id: string
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
    path: "/v2/companies/{companyId}/employees/{employeeId}"
    path_params: [{name: companyId, var: company_id}, {name: employeeId, var: employee_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, employee_id: $employee_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update employee
#
# PATCH /v2/companies/{companyId}/employees/{employeeId}
# operationId: Update employee
export def "update-employee" [
  company_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --additional-direct-deposit: list # Add up to 19 direct deposit accounts in addition to the main direct deposit account. IMPORTANT: A direct deposit update will remove ALL existing main and additional direct deposit information in WebPay and replace with information provided on the request. GET API will not return direct deposit data. — item shape: {accountNumber?: string, accountType?: string, amount?: float, amountType?: string, blockSpecial?: bool, isSkipPreNote?: bool, nameOnAccount?: string, preNoteDate?: string, routingNumber?: string}
  --additional-rate: list # Add Additional Rates. — item shape: {changeReason?: string, costCenter1?: string, costCenter2?: string, costCenter3?: string, effectiveDate?: string, endCheckDate?: string, job?: string, rate?: float, rateCode?: string, rateNotes?: string, ratePer?: string, shift?: string}
  --benefit-setup: record # Add or update setup values used for employee benefits integration, insurance plan settings, and ACA reporting. — shape: {benefitClass?: string, benefitClassEffectiveDate?: string, benefitSalary?: float, benefitSalaryEffectiveDate?: string, doNotApplyAdministrativePeriod?: bool, isMeasureAcaEligibility?: bool}
  --birth-date: string # Employee birthdate. Common formats include *MM-DD-CCYY*, *CCYY-MM-DD*. (nullable, format: paylocity-date)
  --co-emp-code: string # Unique idenifier for SSO.Max length: 20 (nullable)
  --company-fein: string # Company FEIN as defined in Web Pay, applicable with GET requests only. Max length: 20 (nullable)
  --company-name: string # Company name as defined in Web Pay, applicable with GET requests only. Max length: 50 (nullable)
  --currency: string # Employee is paid in this currency. Max length: 30 (nullable)
  --custom-boolean-fields: list # Up to 8 custom fields of boolean (checkbox) type value. — item shape: {category: "PayrollAndHR", label: string, value: bool}
  --custom-date-fields: list # Up to 8 custom fields of the date type value. — item shape: {category: "PayrollAndHR", label: string, value: string}
  --custom-drop-down-fields: list # Up to 8 custom fields of the dropdown type value. — item shape: {category: "PayrollAndHR", label: string, value: string}
  --custom-number-fields: list # Up to 8 custom fields of numeric type value. — item shape: {category: "PayrollAndHR", label: string, value: float}
  --custom-text-fields: list # Up to 8 custom fields of text type value. — item shape: {category: "PayrollAndHR", label: string, value: string}
  --department-position: record # Add or update home department cost center, position, supervisor, reviewer, employment type, EEO class, pay settings, and union information. — shape: {changeReason?: string, clockBadgeNumber?: string, costCenter1?: string, costCenter2?: string, costCenter3?: string, effectiveDate?: string, employeeType?: string, equalEmploymentOpportunityClass?: string, isMinimumWageExempt?: bool, isOvertimeExempt?: bool, isSupervisorReviewer?: bool, isUnionDuesCollected?: bool, isUnionInitiationCollected?: bool, jobTitle?: string, payGroup?: string, positionCode?: string, reviewerCompanyNumber?: string, reviewerEmployeeId?: string, shift?: string, ... (7 more fields)}
  --disability-description: string # Indicates if employee has disability status. (nullable)
  --emergency-contacts: list # Add or update Emergency Contacts. — item shape: {address1?: string, address2?: string, city?: string, country?: string, county?: string, email?: string, firstName: string, homePhone?: string, lastName: string, mobilePhone?: string, notes?: string, pager?: string, primaryPhone?: string, priority?: string, relationship?: string, state?: string, syncEmployeeInfo?: bool, workExtension?: string, workPhone?: string, zip?: string}
  --body-employee-id: string # Leave blank to have Web Pay automatically assign the next available employee ID.Max length: 9 (nullable) (spec name: employeeId)
  --ethnicity: string # Employee ethnicity. Max length: 10 (nullable)
  --federal-tax: record # Add or update federal tax amount type (taxCalculationCode), amount or percentage, filing status, and exemptions. — shape: {amount?: float, deductionsAmount?: float, dependentsAmount?: float, exemptions?: float, filingStatus?: string, higherRate?: bool, otherIncomeAmount?: float, percentage?: float, taxCalculationCode?: string, w4FormYear?: int}
  --first-name: string # Employee first name. Max length: 40 (nullable)
  --gender: string # Employee gender. Common values *M* (Male), *F* (Female). Max length: 1 (nullable)
  --home-address: record # Add or update employee's home address, personal phone numbers, and personal email. — shape: {address1?: string, address2?: string, city?: string, country?: string, county?: string, emailAddress?: string, mobilePhone?: string, phone?: string, postalCode?: string, state?: string}
  --is-highly-compensated: oneof<nothing, bool> # Indicates if employee meets the highly compensated employee criteria.
  --is-smoker: oneof<nothing, bool> # Indicates if employee is a smoker.
  --last-name: string # Employee last name. Max length: 40 (nullable)
  --local-tax: list # Add, update, or delete local tax code, filing status, and exemptions including PA-PSD taxes. — item shape: {exemptions?: float, exemptions2?: float, filingStatus?: string, residentPSD?: string, taxCode?: string, workPSD?: string}
  --main-direct-deposit: record # Add the main direct deposit account. After deposits are made to any additional direct deposit accounts, the remaining net check is deposited in the main direct deposit account. IMPORTANT: A direct deposit update will remove ALL existing main and additional direct deposit information in WebPay and replace with what is provided on the request. GET API will not return direct deposit data. — shape: {accountNumber?: string, accountType?: string, blockSpecial?: bool, isSkipPreNote?: bool, nameOnAccount?: string, preNoteDate?: string, routingNumber?: string}
  --marital-status: string # Employee marital status. Common values *D (Divorced), M (Married), S (Single), W (Widowed)*. Max length: 10 (nullable)
  --middle-name: string # Employee middle name. Max length: 20 (nullable)
  --non-primary-state-tax: record # Add or update non-primary state tax code, amount type (taxCalculationCode), amount or percentage, filing status, exemptions, supplemental check (specialCheckCalc), and reciprocity code information. — shape: {amount?: float, deductionsAmount?: float, dependentsAmount?: float, exemptions?: float, exemptions2?: float, filingStatus?: string, higherRate?: bool, otherIncomeAmount?: float, percentage?: float, reciprocityCode?: string, specialCheckCalc?: string, taxCalculationCode?: string, taxCode?: string, w4FormYear?: int}
  --owner-percent: float # Percentage of employee's ownership in the company, entered as a whole number. Decimal (12,2) (nullable)
  --preferred-name: string # Employee preferred display name. Max length: 20 (nullable)
  --primary-pay-rate: record # Add or update hourly or salary pay rate, effective date, and pay frequency. — shape: {annualSalary?: float, baseRate?: float, beginCheckDate?: string, changeReason?: string, defaultHours?: float, effectiveDate?: string, isAutoPay?: bool, payFrequency?: string, payGrade?: string, payRateNote?: string, payType?: string, ratePer?: string, salary?: float}
  --primary-state-tax: record # Add or update primary state tax code, amount type (taxCalculationCode), amount or percentage, filing status, exemptions, and supplemental check (specialCheckCalc) information. Only one primary state is allowed. Sending an updated primary state will replace the current primary state. — shape: {amount?: float, deductionsAmount?: float, dependentsAmount?: float, exemptions?: float, exemptions2?: float, filingStatus?: string, higherRate?: bool, otherIncomeAmount?: float, percentage?: float, specialCheckCalc?: string, taxCalculationCode?: string, taxCode?: string, w4FormYear?: int}
  --prior-last-name: string # Prior last name if applicable.Max length: 40 (nullable)
  --salutation: string # Employee preferred salutation. Max length: 10 (nullable)
  --ssn: string # Employee social security number. Leave it blank if valid social security number not available. Max length: 11 (nullable)
  --status: record # Add or update employee status, change reason, effective date, and adjusted seniority date. Note that companies that are still in Implementation cannot hire future employees. — shape: {adjustedSeniorityDate?: string, changeReason?: string, effectiveDate?: string, employeeStatus?: string, hireDate?: string, isEligibleForRehire?: bool, reHireDate?: string, statusType?: string, terminationDate?: string}
  --suffix: string # Employee name suffix. Common values are *Jr, Sr, II*.Max length: 30 (nullable)
  --tax-setup: record # Add tax form, 1099 exempt reasons and notes, and 943 agricultural employee information. Once the employee receives wages, this information cannot be updated. Add or update SUI tax state, retirement plan, and statutory information. — shape: {fitwExemptNotes?: string, fitwExemptReason?: string, futaExemptNotes?: string, futaExemptReason?: string, isEmployee943?: bool, isPension?: bool, isStatutory?: bool, medExemptNotes?: string, medExemptReason?: string, sitwExemptNotes?: string, sitwExemptReason?: string, ssExemptNotes?: string, ssExemptReason?: string, suiExemptNotes?: string, suiExemptReason?: string, suiState?: string, taxDistributionCode1099R?: string, taxForm?: string}
  --veteran-description: string # Indicates if employee is a veteran. (nullable)
  --web-time: record # Add or update Web Time badge number and charge rate and synchronize Web Pay and Web Time employee data. — shape: {badgeNumber?: string, chargeRate?: float, isTimeLaborEnabled?: bool}
  --work-address: record # Add or update employee's work address, phone numbers, and email. Work Location drop down field is not included. — shape: {address1?: string, address2?: string, city?: string, country?: string, county?: string, emailAddress?: string, location?: string, mailStop?: string, mobilePhone?: string, pager?: string, phone?: string, phoneExtension?: string, postalCode?: string, state?: string}
  --work-eligibility: record # Add or update I-9 work authorization information. — shape: {alienOrAdmissionDocumentNumber?: string, attestedDate?: string, countryOfIssuance?: string, foreignPassportNumber?: string, i94AdmissionNumber?: string, i9DateVerified?: string, i9Notes?: string, isI9Verified?: bool, isSsnVerified?: bool, ssnDateVerified?: string, ssnNotes?: string, visaType?: string, workAuthorization?: string, workUntil?: string}
]: any -> any {
  $in | http-request {
    method: patch
    path: "/v2/companies/{companyId}/employees/{employeeId}"
    path_params: [{name: companyId, var: company_id}, {name: employeeId, var: employee_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: additionalDirectDeposit, var: additional_direct_deposit}, {name: additionalRate, var: additional_rate}, {name: benefitSetup, var: benefit_setup}, {name: birthDate, var: birth_date}, {name: coEmpCode, var: co_emp_code}, {name: companyFEIN, var: company_fein}, {name: companyName, var: company_name}, {name: currency, var: currency}, {name: customBooleanFields, var: custom_boolean_fields}, {name: customDateFields, var: custom_date_fields}, {name: customDropDownFields, var: custom_drop_down_fields}, {name: customNumberFields, var: custom_number_fields}, {name: customTextFields, var: custom_text_fields}, {name: departmentPosition, var: department_position}, {name: disabilityDescription, var: disability_description}, {name: emergencyContacts, var: emergency_contacts}, {name: employeeId, var: body_employee_id}, {name: ethnicity, var: ethnicity}, {name: federalTax, var: federal_tax}, {name: firstName, var: first_name}, {name: gender, var: gender}, {name: homeAddress, var: home_address}, {name: isHighlyCompensated, var: is_highly_compensated}, {name: isSmoker, var: is_smoker}, {name: lastName, var: last_name}, {name: localTax, var: local_tax}, {name: mainDirectDeposit, var: main_direct_deposit}, {name: maritalStatus, var: marital_status}, {name: middleName, var: middle_name}, {name: nonPrimaryStateTax, var: non_primary_state_tax}, {name: ownerPercent, var: owner_percent}, {name: preferredName, var: preferred_name}, {name: primaryPayRate, var: primary_pay_rate}, {name: primaryStateTax, var: primary_state_tax}, {name: priorLastName, var: prior_last_name}, {name: salutation, var: salutation}, {name: ssn, var: ssn}, {name: status, var: status}, {name: suffix, var: suffix}, {name: taxSetup, var: tax_setup}, {name: veteranDescription, var: veteran_description}, {name: webTime, var: web_time}, {name: workAddress, var: work_address}, {name: workEligibility, var: work_eligibility}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, employee_id: $employee_id, additional_direct_deposit: $additional_direct_deposit, additional_rate: $additional_rate, benefit_setup: $benefit_setup, birth_date: $birth_date, co_emp_code: $co_emp_code, company_fein: $company_fein, company_name: $company_name, currency: $currency, custom_boolean_fields: $custom_boolean_fields, custom_date_fields: $custom_date_fields, custom_drop_down_fields: $custom_drop_down_fields, custom_number_fields: $custom_number_fields, custom_text_fields: $custom_text_fields, department_position: $department_position, disability_description: $disability_description, emergency_contacts: $emergency_contacts, body_employee_id: $body_employee_id, ethnicity: $ethnicity, federal_tax: $federal_tax, first_name: $first_name, gender: $gender, home_address: $home_address, is_highly_compensated: $is_highly_compensated, is_smoker: $is_smoker, last_name: $last_name, local_tax: $local_tax, main_direct_deposit: $main_direct_deposit, marital_status: $marital_status, middle_name: $middle_name, non_primary_state_tax: $non_primary_state_tax, owner_percent: $owner_percent, preferred_name: $preferred_name, primary_pay_rate: $primary_pay_rate, primary_state_tax: $primary_state_tax, prior_last_name: $prior_last_name, salutation: $salutation, ssn: $ssn, status: $status, suffix: $suffix, tax_setup: $tax_setup, veteran_description: $veteran_description, web_time: $web_time, work_address: $work_address, work_eligibility: $work_eligibility
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add/update additional rates
#
# PUT /v2/companies/{companyId}/employees/{employeeId}/additionalRates
# operationId: Add or update additional rates
export def "add-or-update-additional-rates" [
  company_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --change-reason: string # Not required. If populated, must match one of the system coded values available in the Additional Rates Change Reason drop down. (nullable)
  --cost-center1: string # Not required. Valid values must match one of the system coded cost centers available in the Additional Rates Cost Center level 1 drop down. This cell must be in a text format. (nullable)
  --cost-center2: string # Not required. Valid values must match one of the system coded cost centers available in the Additional Rates Cost Center level 2 drop down. This cell must be in a text format. (nullable)
  --cost-center3: string # Not required. Valid values must match one of the system coded cost centers available in the Additional Rates Cost Center level 3 drop down. This cell must be in a text format. (nullable)
  --effective-date: string # Required. Common formats include *MM-DD-CCYY*, *CCYY-MM-DD*. (nullable, format: paylocity-date)
  --end-check-date: string # Not required. Must match one of the system coded check dates available in the Additional Rates End Check Date drop down. Common formats include *MM-DD-CCYY*, *CCYY-MM-DD*. (nullable, format: paylocity-date)
  --job: string # Not required. If populated, must match one of the system coded values available in the Additional Rates Job drop down. (nullable)
  --rate: float # Required. Enter dollar amount that corresponds to the Per selection. (nullable)
  --rate-code: string # Required. If populated, must match one of the system coded values available in the Additional Rates Rate Code drop down. (nullable)
  --rate-notes: string # Not required.Max length: 4000 (nullable)
  --rate-per: string # Required. Valid values are HOUR or WEEK. (nullable)
  --shift: string # Not required. If populated, must match one of the system coded values available in the Additional Rates Shift drop down. (nullable)
]: any -> any {
  $in | http-request {
    method: put
    path: "/v2/companies/{companyId}/employees/{employeeId}/additionalRates"
    path_params: [{name: companyId, var: company_id}, {name: employeeId, var: employee_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: changeReason, var: change_reason}, {name: costCenter1, var: cost_center1}, {name: costCenter2, var: cost_center2}, {name: costCenter3, var: cost_center3}, {name: effectiveDate, var: effective_date}, {name: endCheckDate, var: end_check_date}, {name: job, var: job}, {name: rate, var: rate}, {name: rateCode, var: rate_code}, {name: rateNotes, var: rate_notes}, {name: ratePer, var: rate_per}, {name: shift, var: shift}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, employee_id: $employee_id, change_reason: $change_reason, cost_center1: $cost_center1, cost_center2: $cost_center2, cost_center3: $cost_center3, effective_date: $effective_date, end_check_date: $end_check_date, job: $job, rate: $rate, rate_code: $rate_code, rate_notes: $rate_notes, rate_per: $rate_per, shift: $shift
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add/update employee's benefit setup
#
# PUT /v2/companies/{companyId}/employees/{employeeId}/benefitSetup
# operationId: Update or add employee benefit setup
export def "update-or-add-employee-benefit-setup" [
  company_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --benefit-class: string # Benefit Class code. Values are configured in Web Pay Company > Setup > Benefits > Classes.Max length: 30 (nullable)
  --benefit-class-effective-date: string # Date when Benefit Class takes effect. Common formats include *MM-DD-CCYY*, *CCYY-MM-DD*. (nullable, format: paylocity-date)
  --benefit-salary: float # Salary used to configure benefits.Decimal(12,2) (nullable)
  --benefit-salary-effective-date: string # Date when Benefit Salary takes effect. Common formats include *MM-DD-CCYY*, *CCYY-MM-DD*. (nullable, format: paylocity-date)
  --do-not-apply-administrative-period: oneof<nothing, bool> # Applicable only for HR Enhanced clients and Benefit Classes with ACA Employment Type of Full Time. (nullable)
  --is-measure-aca-eligibility: oneof<nothing, bool> # Only valid for HR Enhanced clients and Benefit Classes that are ACA Employment Type of Full Time. (nullable)
]: any -> any {
  $in | http-request {
    method: put
    path: "/v2/companies/{companyId}/employees/{employeeId}/benefitSetup"
    path_params: [{name: companyId, var: company_id}, {name: employeeId, var: employee_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: benefitClass, var: benefit_class}, {name: benefitClassEffectiveDate, var: benefit_class_effective_date}, {name: benefitSalary, var: benefit_salary}, {name: benefitSalaryEffectiveDate, var: benefit_salary_effective_date}, {name: doNotApplyAdministrativePeriod, var: do_not_apply_administrative_period}, {name: isMeasureAcaEligibility, var: is_measure_aca_eligibility}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, employee_id: $employee_id, benefit_class: $benefit_class, benefit_class_effective_date: $benefit_class_effective_date, benefit_salary: $benefit_salary, benefit_salary_effective_date: $benefit_salary_effective_date, do_not_apply_administrative_period: $do_not_apply_administrative_period, is_measure_aca_eligibility: $is_measure_aca_eligibility
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get All Direct Deposit
#
# GET /v2/companies/{companyId}/employees/{employeeId}/directDeposit
# Returns: table<additionalDirectDeposit: list<record>, mainDirectDeposit: record<accountNumber: string, accountType: string, blockSpecial: bool, isSkipPreNote: bool, nameOnAccount: string, preNoteDate: string, routingNumber: string>>
# operationId: Get All Direct Deposit
export def "get-all-direct-deposit" [
  company_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v2/companies/{companyId}/employees/{employeeId}/directDeposit"
    path_params: [{name: companyId, var: company_id}, {name: employeeId, var: employee_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, employee_id: $employee_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get All Earnings
#
# GET /v2/companies/{companyId}/employees/{employeeId}/earnings
# Returns: table<agency: string, amount: float, annualMaximum: float, calculationCode: string, costCenter1: string, costCenter2: string, costCenter3: string, earningCode: string, effectiveDate: string, endDate: string, frequency: string, goal: float, hoursOrUnits: float, isSelfInsured: bool, jobCode: string, miscellaneousInfo: string, paidTowardsGoal: float, payPeriodMaximum: float, payPeriodMinimum: float, rate: float, rateCode: string, startDate: string>
# operationId: Get All Earnings
export def "get-all-earnings" [
  company_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v2/companies/{companyId}/employees/{employeeId}/earnings"
    path_params: [{name: companyId, var: company_id}, {name: employeeId, var: employee_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, employee_id: $employee_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add/Update Earning
#
# PUT /v2/companies/{companyId}/employees/{employeeId}/earnings
# operationId: Add or update an employee earning
export def "add-or-update-an-employee-earning" [
  company_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --agency: string # Third-party agency associated with earning. Must match Company setup.Max length: 10 (nullable)
  --amount: float # Value that matches CalculationCode to add to gross wages. For percentage (%), enter whole number (10 = 10%). Decimal(12,2) (nullable)
  --annual-maximum: float # Year to Date dollar amount not to be exceeded for an earning in the calendar year. Used only with company driven maximums. Decimal(12,2) (nullable)
  --calculation-code: string # Defines how earnings are calculated. Common values are *% (percentage of gross), flat (flat dollar amount)*. Defaulted to the Company setup calcCode for earning. Max length: 20 (nullable)
  --cost-center1: string # Cost Center associated with earning. Must match Company setup. Max length: 10 (nullable)
  --cost-center2: string # Cost Center associated with earning. Must match Company setup. Max length: 10 (nullable)
  --cost-center3: string # Cost Center associated with earning. Must match Company setup. Max length: 10 (nullable)
  --earning-code: string # Earning code. Must match Company setup. Max length: 10 (nullable)
  --effective-date: string # Date earning is active. Defaulted to run date or check date based on Company setup. Common formats are MM-DD-CCYY, CCYY-MM-DD. (nullable, format: paylocity-date)
  --end-date: string # Stop date of an earning. Common formats are MM-DD-CCYY, CCYY-MM-DD. (nullable, format: paylocity-date)
  --frequency: string # Needed if earning is applied differently from the payroll frequency (one time earning for example). Max length: 5 (nullable)
  --goal: float # Dollar amount. The employee earning will stop when the goal amount is reached. Decimal(12,2) (nullable)
  --hours-or-units: float # The value is used in conjunction with the Rate field. When entering Group Term Life Insurance (GTL), it should contain the full amount of the group term life insurance policy. Decimal(12,2) (nullable)
  --is-self-insured: oneof<nothing, bool> # Used for ACA. If not entered, defaulted to Company earning setup. (nullable)
  --job-code: string # Job code associated with earnings. Must match Company setup. Max length: 20 (nullable)
  --miscellaneous-info: string # Information to print on the check stub if agency is set up for this earning. Max length: 50 (nullable)
  --paid-towards-goal: float # Amount already paid to employee toward goal. Decimal(12,2) (nullable)
  --pay-period-maximum: float # Maximum amount of the earning on a single paycheck. Decimal(12,2) (nullable)
  --pay-period-minimum: float # Minimum amount of the earning on a single paycheck. Decimal(12,2) (nullable)
  --rate: float # Rate is used in conjunction with the hoursOrUnits field. Decimal(12,2) (nullable)
  --rate-code: string # Rate Code applies to additional pay rates entered for an employee. Must match Company setup. Max length: 10 (nullable)
  --start-date: string # Start date of an earning based on payroll calendar. Common formats are MM-DD-CCYY, CCYY-MM-DD. (nullable, format: paylocity-date)
]: any -> any {
  $in | http-request {
    method: put
    path: "/v2/companies/{companyId}/employees/{employeeId}/earnings"
    path_params: [{name: companyId, var: company_id}, {name: employeeId, var: employee_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: agency, var: agency}, {name: amount, var: amount}, {name: annualMaximum, var: annual_maximum}, {name: calculationCode, var: calculation_code}, {name: costCenter1, var: cost_center1}, {name: costCenter2, var: cost_center2}, {name: costCenter3, var: cost_center3}, {name: earningCode, var: earning_code}, {name: effectiveDate, var: effective_date}, {name: endDate, var: end_date}, {name: frequency, var: frequency}, {name: goal, var: goal}, {name: hoursOrUnits, var: hours_or_units}, {name: isSelfInsured, var: is_self_insured}, {name: jobCode, var: job_code}, {name: miscellaneousInfo, var: miscellaneous_info}, {name: paidTowardsGoal, var: paid_towards_goal}, {name: payPeriodMaximum, var: pay_period_maximum}, {name: payPeriodMinimum, var: pay_period_minimum}, {name: rate, var: rate}, {name: rateCode, var: rate_code}, {name: startDate, var: start_date}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, employee_id: $employee_id, agency: $agency, amount: $amount, annual_maximum: $annual_maximum, calculation_code: $calculation_code, cost_center1: $cost_center1, cost_center2: $cost_center2, cost_center3: $cost_center3, earning_code: $earning_code, effective_date: $effective_date, end_date: $end_date, frequency: $frequency, goal: $goal, hours_or_units: $hours_or_units, is_self_insured: $is_self_insured, job_code: $job_code, miscellaneous_info: $miscellaneous_info, paid_towards_goal: $paid_towards_goal, pay_period_maximum: $pay_period_maximum, pay_period_minimum: $pay_period_minimum, rate: $rate, rate_code: $rate_code, start_date: $start_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Earnings by Earning Code
#
# GET /v2/companies/{companyId}/employees/{employeeId}/earnings/{earningCode}
# Returns: table<agency: string, amount: float, annualMaximum: float, calculationCode: string, costCenter1: string, costCenter2: string, costCenter3: string, earningCode: string, effectiveDate: string, endDate: string, frequency: string, goal: float, hoursOrUnits: float, isSelfInsured: bool, jobCode: string, miscellaneousInfo: string, paidTowardsGoal: float, payPeriodMaximum: float, payPeriodMinimum: float, rate: float, rateCode: string, startDate: string>
# operationId: Get Earnings by Earning Code
export def "get-earnings-by-earning-code" [
  company_id: string
  employee_id: string
  earning_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v2/companies/{companyId}/employees/{employeeId}/earnings/{earningCode}"
    path_params: [{name: companyId, var: company_id}, {name: employeeId, var: employee_id}, {name: earningCode, var: earning_code}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, employee_id: $employee_id, earning_code: $earning_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Earning by Earning Code and Start Date
#
# DELETE /v2/companies/{companyId}/employees/{employeeId}/earnings/{earningCode}/{startDate}
# operationId: Delete Earning by Earning Code and Start Date
export def "delete-earning-by-earning-code-and-start-date" [
  company_id: string
  employee_id: string
  earning_code: string
  start_date: string
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
    path: "/v2/companies/{companyId}/employees/{employeeId}/earnings/{earningCode}/{startDate}"
    path_params: [{name: companyId, var: company_id}, {name: employeeId, var: employee_id}, {name: earningCode, var: earning_code}, {name: startDate, var: start_date}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    company_id: $company_id, employee_id: $employee_id, earning_code: $earning_code, start_date: $start_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Earning by Earning Code and Start Date
#
# GET /v2/companies/{companyId}/employees/{employeeId}/earnings/{earningCode}/{startDate}
# Returns: record<agency: string, amount: float, annualMaximum: float, calculationCode: string, costCenter1: string, costCenter2: string, costCenter3: string, earningCode: string, effectiveDate: string, endDate: string, frequency: string, goal: float, hoursOrUnits: float, isSelfInsured: bool, jobCode: string, miscellaneousInfo: string, paidTowardsGoal: float, payPeriodMaximum: float, payPeriodMinimum: float, rate: float, rateCode: string, startDate: string>
# operationId: Get Earning by Earning Code and Start Date
export def "get-earning-by-earning-code-and-start-date" [
  company_id: string
  employee_id: string
  earning_code: string
  start_date: string
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
    path: "/v2/companies/{companyId}/employees/{employeeId}/earnings/{earningCode}/{startDate}"
    path_params: [{name: companyId, var: company_id}, {name: employeeId, var: employee_id}, {name: earningCode, var: earning_code}, {name: startDate, var: start_date}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, employee_id: $employee_id, earning_code: $earning_code, start_date: $start_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add/update emergency contacts
#
# PUT /v2/companies/{companyId}/employees/{employeeId}/emergencyContacts
# operationId: Add or update emergency contacts
export def "add-or-update-emergency-contacts" [
  company_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address1: string # 1st address line. (nullable)
  --address2: string # 2nd address line. (nullable)
  --city: string # City. (nullable)
  --country: string # County. (nullable)
  --county: string # Country. Must be a valid 3 character country code. Common values are *USA* (United States), *CAN* (Canada). (nullable)
  --email: string # Contact email. Must be valid email address format. (nullable)
  --first-name: string # Required. Contact first name. Max length: 40 (nullable)
  --home-phone: string # Contact Home Phone. Valid phone format *(###) #######* or *######-####* or *### ### ####* or *##########* or, if international, starts with *+#*, only spaces and digits allowed. (nullable)
  --last-name: string # Required. Contact last name. Max length: 40 (nullable)
  --mobile-phone: string # Contact Mobile Phone. Valid phone format *(###) #######* or *######-####* or *### ### ####* or *##########* or, if international, starts with *+#*, only spaces and digits allowed. (nullable)
  --notes: string # Notes. Max length: 1000 (nullable)
  --pager: string # Contact Pager. Valid phone format *(###) #######* or *######-####* or *### ### ####* or *##########* or, if international, starts with *+#*, only spaces and digits allowed. (nullable)
  --primary-phone: string # Required. Contact primary phone type. Must match Company setup. Valid values are H (Home), M (Mobile), P (Pager), W (Work) (nullable)
  --priority: string # Required. Contact priority. Valid values are *P* (Primary) or *S* (Secondary). (nullable)
  --relationship: string # Required. Contact relationship. Must match Company setup. Common values are Spouse, Mother, Father. (nullable)
  --state: string # State or Province. If U.S. address, must be valid 2 character state code. Common values are *IL* (Illinois), *CA* (California). (nullable)
  --sync-employee-info: oneof<nothing, bool> # Valid values are *true* or *false*.
  --work-extension: string # Work Extension. (nullable)
  --work-phone: string # Contact Work Phone. Valid phone format *(###) #######* or *######-####* or *### ### ####* or *##########* or, if international, starts with *+#*, only spaces and digits allowed. (nullable)
  --zip: string # Postal code. If U.S. address, must be a valid zip code. (nullable)
]: any -> any {
  $in | http-request {
    method: put
    path: "/v2/companies/{companyId}/employees/{employeeId}/emergencyContacts"
    path_params: [{name: companyId, var: company_id}, {name: employeeId, var: employee_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: address1, var: address1}, {name: address2, var: address2}, {name: city, var: city}, {name: country, var: country}, {name: county, var: county}, {name: email, var: email}, {name: firstName, var: first_name}, {name: homePhone, var: home_phone}, {name: lastName, var: last_name}, {name: mobilePhone, var: mobile_phone}, {name: notes, var: notes}, {name: pager, var: pager}, {name: primaryPhone, var: primary_phone}, {name: priority, var: priority}, {name: relationship, var: relationship}, {name: state, var: state}, {name: syncEmployeeInfo, var: sync_employee_info}, {name: workExtension, var: work_extension}, {name: workPhone, var: work_phone}, {name: zip, var: zip}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, employee_id: $employee_id, address1: $address1, address2: $address2, city: $city, country: $country, county: $county, email: $email, first_name: $first_name, home_phone: $home_phone, last_name: $last_name, mobile_phone: $mobile_phone, notes: $notes, pager: $pager, primary_phone: $primary_phone, priority: $priority, relationship: $relationship, state: $state, sync_employee_info: $sync_employee_info, work_extension: $work_extension, work_phone: $work_phone, zip: $zip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all local taxes
#
# GET /v2/companies/{companyId}/employees/{employeeId}/localTaxes
# Returns: table<exemptions: float, exemptions2: float, filingStatus: string, residentPSD: string, taxCode: string, workPSD: string>
# operationId: Get all local taxes
export def "get-all-local-taxes" [
  company_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v2/companies/{companyId}/employees/{employeeId}/localTaxes"
    path_params: [{name: companyId, var: company_id}, {name: employeeId, var: employee_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, employee_id: $employee_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add new local tax
#
# POST /v2/companies/{companyId}/employees/{employeeId}/localTaxes
# operationId: Add local tax
export def "add-local-tax" [
  company_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --exemptions: float # Local tax exemptions value.Decimal (12,2) (nullable)
  --exemptions2: float # Local tax exemptions 2 value.Decimal (12,2) (nullable)
  --filing-status: string # Employee local tax filing status. Must match specific local tax setup. Max length: 50 (nullable)
  --resident-psd: string # Resident PSD (political subdivision code) applicable in PA. Must match Company setup. Max length: 9 (nullable)
  --tax-code: string # Local tax code.Max length: 50 (nullable)
  --work-psd: string # Work location PSD. Must match Company setup. Max length: 9 (nullable)
]: any -> any {
  $in | http-request {
    method: post
    path: "/v2/companies/{companyId}/employees/{employeeId}/localTaxes"
    path_params: [{name: companyId, var: company_id}, {name: employeeId, var: employee_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: exemptions, var: exemptions}, {name: exemptions2, var: exemptions2}, {name: filingStatus, var: filing_status}, {name: residentPSD, var: resident_psd}, {name: taxCode, var: tax_code}, {name: workPSD, var: work_psd}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    company_id: $company_id, employee_id: $employee_id, exemptions: $exemptions, exemptions2: $exemptions2, filing_status: $filing_status, resident_psd: $resident_psd, tax_code: $tax_code, work_psd: $work_psd
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete local tax by tax code
#
# DELETE /v2/companies/{companyId}/employees/{employeeId}/localTaxes/{taxCode}
# operationId: Delete local tax by tax code
export def "delete-local-tax-by-tax-code" [
  company_id: string
  employee_id: string
  tax_code: string
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
    path: "/v2/companies/{companyId}/employees/{employeeId}/localTaxes/{taxCode}"
    path_params: [{name: companyId, var: company_id}, {name: employeeId, var: employee_id}, {name: taxCode, var: tax_code}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    company_id: $company_id, employee_id: $employee_id, tax_code: $tax_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get local taxes by tax code
#
# GET /v2/companies/{companyId}/employees/{employeeId}/localTaxes/{taxCode}
# Returns: table<exemptions: float, exemptions2: float, filingStatus: string, residentPSD: string, taxCode: string, workPSD: string>
# operationId: Get local tax by tax code
export def "get-local-tax-by-tax-code" [
  company_id: string
  employee_id: string
  tax_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v2/companies/{companyId}/employees/{employeeId}/localTaxes/{taxCode}"
    path_params: [{name: companyId, var: company_id}, {name: employeeId, var: employee_id}, {name: taxCode, var: tax_code}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, employee_id: $employee_id, tax_code: $tax_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add/update non-primary state tax
#
# PUT /v2/companies/{companyId}/employees/{employeeId}/nonprimaryStateTax
# operationId: Add or update non-primary state tax
export def "add-or-update-non-primary-state-tax" [
  company_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --amount: float # State tax code. Max length: 50 (nullable)
  --deductions-amount: float # Box 4(b) on form W4 (year 2020 or later): Deductions amount. Decimal (12,2)
  --dependents-amount: float # Box 3 on form W4 (year 2020 or later): Total dependents amount. Decimal (12,2)
  --exemptions: float # State tax exemptions value.Decimal (12,2) (nullable)
  --exemptions2: float # State tax exemptions 2 value.Decimal (12,2) (nullable)
  --filing-status: string # Employee state tax filing status. Common values are *S* (Single), *M* (Married).Max length: 50 (nullable)
  --higher-rate: oneof<nothing, bool> # Box 2(c) on form W4 (year 2020 or later): Multiple Jobs or Spouse Works. Boolean
  --other-income-amount: float # Box 4(a) on form W4 (year 2020 or later): Other income amount. Decimal (12,2)
  --percentage: float # State Tax percentage. Decimal (12,2) (nullable)
  --reciprocity-code: string # Non-primary state tax reciprocity code. Max length: 50 (nullable)
  --special-check-calc: string # Supplemental check calculation code. Common values are *Blocked* (Taxes blocked on Supplemental checks), *Supp* (Use supplemental Tax Rate-Code). Max length: 10 (nullable)
  --tax-calculation-code: string # Tax calculation code. Common values are *F* (Flat), *P* (Percentage), *FDFP* (Flat Dollar Amount plus Fixed Percentage). Max length: 10 (nullable)
  --tax-code: string # State tax code. Max length: 50 (nullable)
  --w4-form-year: int # The state W4 form year Integer
]: any -> any {
  $in | http-request {
    method: put
    path: "/v2/companies/{companyId}/employees/{employeeId}/nonprimaryStateTax"
    path_params: [{name: companyId, var: company_id}, {name: employeeId, var: employee_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: amount, var: amount}, {name: deductionsAmount, var: deductions_amount}, {name: dependentsAmount, var: dependents_amount}, {name: exemptions, var: exemptions}, {name: exemptions2, var: exemptions2}, {name: filingStatus, var: filing_status}, {name: higherRate, var: higher_rate}, {name: otherIncomeAmount, var: other_income_amount}, {name: percentage, var: percentage}, {name: reciprocityCode, var: reciprocity_code}, {name: specialCheckCalc, var: special_check_calc}, {name: taxCalculationCode, var: tax_calculation_code}, {name: taxCode, var: tax_code}, {name: w4FormYear, var: w4_form_year}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, employee_id: $employee_id, amount: $amount, deductions_amount: $deductions_amount, dependents_amount: $dependents_amount, exemptions: $exemptions, exemptions2: $exemptions2, filing_status: $filing_status, higher_rate: $higher_rate, other_income_amount: $other_income_amount, percentage: $percentage, reciprocity_code: $reciprocity_code, special_check_calc: $special_check_calc, tax_calculation_code: $tax_calculation_code, tax_code: $tax_code, w4_form_year: $w4_form_year
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get employee pay statement details data for the specified year.
#
# GET /v2/companies/{companyId}/employees/{employeeId}/paystatement/details/{year}
# Returns: table<amount: float, checkDate: string, det: string, detCode: string, detType: string, eligibleCompensation: float, hours: float, rate: float, transactionNumber: int, transactionType: string, year: int>
# operationId: Gets employee pay statement detail data based on the specified year
export def "gets-employee-pay-statement-detail-data-based-on-the-specified-year" [
  company_id: string
  employee_id: string
  year: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagesize: int # Number of records per page. Default value is 25.
  --pagenumber: int # Page number to retrieve; page numbers are 0-based (so to get the first page of results, pass pagenumber=0). Default value is 0.
  --includetotalcount: oneof<nothing, bool> # Whether to include the total record count in the header's X-Pcty-Total-Count property. Default value is true.
  --codegroup: string # Retrieve pay statement details related to specific deduction, earning or tax types. Common values include 401k, Memo, Reg, OT, Cash Tips, FED and SITW.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v2/companies/{companyId}/employees/{employeeId}/paystatement/details/{year}"
    path_params: [{name: companyId, var: company_id}, {name: employeeId, var: employee_id}, {name: year, var: year}]
    query: [{name: pagesize, var: pagesize}, {name: pagenumber, var: pagenumber}, {name: includetotalcount, var: includetotalcount}, {name: codegroup, var: codegroup}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, employee_id: $employee_id, year: $year, pagesize: $pagesize, pagenumber: $pagenumber, includetotalcount: $includetotalcount, codegroup: $codegroup
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get employee pay statement details data for the specified year and check date.
#
# GET /v2/companies/{companyId}/employees/{employeeId}/paystatement/details/{year}/{checkDate}
# Returns: table<amount: float, checkDate: string, det: string, detCode: string, detType: string, eligibleCompensation: float, hours: float, rate: float, transactionNumber: int, transactionType: string, year: int>
# operationId: Gets employee pay statement detail data based on the specified year and check date
export def "gets-employee-pay-statement-detail-data-based-on-the-specified-year-and-check-date" [
  company_id: string
  employee_id: string
  year: string
  check_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagesize: int # Number of records per page. Default value is 25.
  --pagenumber: int # Page number to retrieve; page numbers are 0-based (so to get the first page of results, pass pagenumber=0). Default value is 0.
  --includetotalcount: oneof<nothing, bool> # Whether to include the total record count in the header's X-Pcty-Total-Count property. Default value is true.
  --codegroup: string # Retrieve pay statement details related to specific deduction, earning or tax types. Common values include 401k, Memo, Reg, OT, Cash Tips, FED and SITW.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v2/companies/{companyId}/employees/{employeeId}/paystatement/details/{year}/{checkDate}"
    path_params: [{name: companyId, var: company_id}, {name: employeeId, var: employee_id}, {name: year, var: year}, {name: checkDate, var: check_date}]
    query: [{name: pagesize, var: pagesize}, {name: pagenumber, var: pagenumber}, {name: includetotalcount, var: includetotalcount}, {name: codegroup, var: codegroup}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, employee_id: $employee_id, year: $year, check_date: $check_date, pagesize: $pagesize, pagenumber: $pagenumber, includetotalcount: $includetotalcount, codegroup: $codegroup
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get employee pay statement summary data for the specified year.
#
# GET /v2/companies/{companyId}/employees/{employeeId}/paystatement/summary/{year}
# Returns: table<autoPay: bool, beginDate: string, checkDate: string, checkNumber: int, directDepositAmount: float, endDate: string, grossPay: float, hours: float, netCheck: float, netPay: float, overtimeDollars: float, overtimeHours: float, process: int, regularDollars: float, regularHours: float, transactionNumber: int, voucherNumber: int, workersCompCode: string, year: int>
# operationId: Gets employee pay statement summary data based on the specified year
export def "gets-employee-pay-statement-summary-data-based-on-the-specified-year" [
  company_id: string
  employee_id: string
  year: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagesize: int # Number of records per page. Default value is 25.
  --pagenumber: int # Page number to retrieve; page numbers are 0-based (so to get the first page of results, pass pagenumber=0). Default value is 0.
  --includetotalcount: oneof<nothing, bool> # Whether to include the total record count in the header's X-Pcty-Total-Count property. Default value is true.
  --codegroup: string # Retrieve pay statement details related to specific deduction, earning or tax types. Common values include 401k, Memo, Reg, OT, Cash Tips, FED and SITW.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v2/companies/{companyId}/employees/{employeeId}/paystatement/summary/{year}"
    path_params: [{name: companyId, var: company_id}, {name: employeeId, var: employee_id}, {name: year, var: year}]
    query: [{name: pagesize, var: pagesize}, {name: pagenumber, var: pagenumber}, {name: includetotalcount, var: includetotalcount}, {name: codegroup, var: codegroup}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, employee_id: $employee_id, year: $year, pagesize: $pagesize, pagenumber: $pagenumber, includetotalcount: $includetotalcount, codegroup: $codegroup
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get employee pay statement summary data for the specified year and check date.
#
# GET /v2/companies/{companyId}/employees/{employeeId}/paystatement/summary/{year}/{checkDate}
# Returns: table<autoPay: bool, beginDate: string, checkDate: string, checkNumber: int, directDepositAmount: float, endDate: string, grossPay: float, hours: float, netCheck: float, netPay: float, overtimeDollars: float, overtimeHours: float, process: int, regularDollars: float, regularHours: float, transactionNumber: int, voucherNumber: int, workersCompCode: string, year: int>
# operationId: Gets employee pay statement summary data based on the specified year and check date
export def "gets-employee-pay-statement-summary-data-based-on-the-specified-year-and-check-date" [
  company_id: string
  employee_id: string
  year: string
  check_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagesize: int # Number of records per page. Default value is 25.
  --pagenumber: int # Page number to retrieve; page numbers are 0-based (so to get the first page of results, pass pagenumber=0). Default value is 0.
  --includetotalcount: oneof<nothing, bool> # Whether to include the total record count in the header's X-Pcty-Total-Count property. Default value is true.
  --codegroup: string # Retrieve pay statement details related to specific deduction, earning or tax types. Common values include 401k, Memo, Reg, OT, Cash Tips, FED and SITW.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v2/companies/{companyId}/employees/{employeeId}/paystatement/summary/{year}/{checkDate}"
    path_params: [{name: companyId, var: company_id}, {name: employeeId, var: employee_id}, {name: year, var: year}, {name: checkDate, var: check_date}]
    query: [{name: pagesize, var: pagesize}, {name: pagenumber, var: pagenumber}, {name: includetotalcount, var: includetotalcount}, {name: codegroup, var: codegroup}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, employee_id: $employee_id, year: $year, check_date: $check_date, pagesize: $pagesize, pagenumber: $pagenumber, includetotalcount: $includetotalcount, codegroup: $codegroup
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add/update primary state tax
#
# PUT /v2/companies/{companyId}/employees/{employeeId}/primaryStateTax
# operationId: Add or update primary state tax
export def "add-or-update-primary-state-tax" [
  company_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --amount: float # State tax code. Max length: 50 (nullable)
  --deductions-amount: float # Box 4(b) on form W4 (year 2020 or later): Deductions amount. Decimal (12,2)
  --dependents-amount: float # Box 3 on form W4 (year 2020 or later): Total dependents amount. Decimal (12,2)
  --exemptions: float # State tax exemptions value.Decimal (12,2) (nullable)
  --exemptions2: float # State tax exemptions 2 value.Decimal (12,2) (nullable)
  --filing-status: string # Employee state tax filing status. Common values are *S* (Single), *M* (Married).Max length: 50 (nullable)
  --higher-rate: oneof<nothing, bool> # Box 2(c) on form W4 (year 2020 or later): Multiple Jobs or Spouse Works. Boolean
  --other-income-amount: float # Box 4(a) on form W4 (year 2020 or later): Other income amount. Decimal (12,2)
  --percentage: float # State Tax percentage. Decimal (12,2) (nullable)
  --special-check-calc: string # Supplemental check calculation code. Common values are *Blocked* (Taxes blocked on Supplemental checks), *Supp* (Use supplemental Tax Rate-Code). Max length: 10 (nullable)
  --tax-calculation-code: string # Tax calculation code. Common values are *F* (Flat), *P* (Percentage), *FDFP* (Flat Dollar Amount plus Fixed Percentage). Max length: 10 (nullable)
  --tax-code: string # State tax code. Max length: 50 (nullable)
  --w4-form-year: int # The state W4 form year Integer
]: any -> any {
  $in | http-request {
    method: put
    path: "/v2/companies/{companyId}/employees/{employeeId}/primaryStateTax"
    path_params: [{name: companyId, var: company_id}, {name: employeeId, var: employee_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: amount, var: amount}, {name: deductionsAmount, var: deductions_amount}, {name: dependentsAmount, var: dependents_amount}, {name: exemptions, var: exemptions}, {name: exemptions2, var: exemptions2}, {name: filingStatus, var: filing_status}, {name: higherRate, var: higher_rate}, {name: otherIncomeAmount, var: other_income_amount}, {name: percentage, var: percentage}, {name: specialCheckCalc, var: special_check_calc}, {name: taxCalculationCode, var: tax_calculation_code}, {name: taxCode, var: tax_code}, {name: w4FormYear, var: w4_form_year}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, employee_id: $employee_id, amount: $amount, deductions_amount: $deductions_amount, dependents_amount: $dependents_amount, exemptions: $exemptions, exemptions2: $exemptions2, filing_status: $filing_status, higher_rate: $higher_rate, other_income_amount: $other_income_amount, percentage: $percentage, special_check_calc: $special_check_calc, tax_calculation_code: $tax_calculation_code, tax_code: $tax_code, w4_form_year: $w4_form_year
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get sensitive data
#
# GET /v2/companies/{companyId}/employees/{employeeId}/sensitivedata
# Returns: table<disability: record<disability: string, disabilityClassifications: list, hasDisability: string>, ethnicity: record<ethnicRacialIdentities: list, ethnicity: string>, gender: record<displayPronouns: bool, genderIdentityDescription: string, identifyAsLegalGender: string, legalGender: string, pronouns: string, sexualOrientation: string>, veteran: record<isVeteran: string, veteran: string>>
# operationId: Get sensitive data
export def "get-sensitive-data" [
  company_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v2/companies/{companyId}/employees/{employeeId}/sensitivedata"
    path_params: [{name: companyId, var: company_id}, {name: employeeId, var: employee_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, employee_id: $employee_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add/update sensitive data
#
# PUT /v2/companies/{companyId}/employees/{employeeId}/sensitivedata
# operationId: Add or update Sensitive Data
export def "add-or-update-sensitive-data" [
  company_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --disability: record # Add or update disability data. — shape: {disability?: string, disabilityClassifications?: list, hasDisability?: string}
  --ethnicity: record # Add or update ethnicity data. — shape: {ethnicRacialIdentities?: list, ethnicity?: string}
  --gender: record # Add or update gender data. — shape: {displayPronouns?: bool, genderIdentityDescription?: string, identifyAsLegalGender?: string, legalGender?: string, pronouns?: string, sexualOrientation?: string}
  --veteran: record # Add or update veteran data. — shape: {isVeteran?: string, veteran?: string}
]: any -> any {
  $in | http-request {
    method: put
    path: "/v2/companies/{companyId}/employees/{employeeId}/sensitivedata"
    path_params: [{name: companyId, var: company_id}, {name: employeeId, var: employee_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: disability, var: disability}, {name: ethnicity, var: ethnicity}, {name: gender, var: gender}, {name: veteran, var: veteran}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, employee_id: $employee_id, disability: $disability, ethnicity: $ethnicity, gender: $gender, veteran: $veteran
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Company-Specific Open API Documentation
#
# GET /v2/companies/{companyId}/openapi
# operationId: Get company-specific Open API documentation
export def "get-company-specific-open-api-documentation" [
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Bearer + JWT (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/v2/companies/{companyId}/openapi"
    path_params: [{name: companyId, var: company_id}]
    header: [{name: Authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Obtain new client secret.
#
# POST /v2/credentials/secrets
# Returns: table<clientSecret: string, clientSecretExpirationDate: string>
# operationId: Add Client Secret
export def "add-client-secret" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  code: string # A value sent with the 'ACTION NEEDED: Web Link API Credentials Expiring Soon.' email notification.
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/credentials/secrets"
    body: {content_type: "application/json", kind: json, fields: [{name: code, var: code}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    code: $code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add new employee to Web Link
#
# POST /v2/weblinkstaging/companies/{companyId}/employees/newemployees
# Returns: table<trackingNumber: string>
# operationId: Add new employee to Web Link
export def "add-new-employee-to-web-link" [
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --additional-direct-deposit: list # Add up to 19 direct deposit accounts in addition to the main direct deposit account. IMPORTANT: A direct deposit update will remove ALL existing main and additional direct deposit information in WebPay and replace with information provided on the request. GET API will not return direct deposit data. — item shape: {accountNumber?: string, accountType?: string, amount?: float, amountType?: string, isSkipPreNote?: bool, preNoteDate?: string, routingNumber?: string}
  --benefit-setup: list # Add setup values used for employee benefits integration, insurance plan settings, and ACA reporting. — item shape: {benefitClass?: string, benefitClassEffectiveDate?: string, benefitSalary?: float, benefitSalaryEffectiveDate?: string, doNotApplyAdministrativePeriod?: bool, isMeasureAcaEligibility?: bool}
  --birth-date: string # Employee birthdate. Common formats include *MM-DD-CCYY*, *CCYY-MM-DD*. (nullable, format: paylocity-date)
  --custom-boolean-fields: list # Up to 8 custom fields of boolean (checkbox) type value. — item shape: {category: "PayrollAndHR", label: string, value: bool}
  --custom-date-fields: list # Up to 8 custom fields of the date type value. — item shape: {category: "PayrollAndHR", label: string, value: string}
  --custom-drop-down-fields: list # Up to 8 custom fields of the dropdown type value. — item shape: {category: "PayrollAndHR", label: string, value: string}
  --custom-number-fields: list # Up to 8 custom fields of numeric type value. — item shape: {category: "PayrollAndHR", label: string, value: float}
  --custom-text-fields: list # Up to 8 custom fields of text type value. — item shape: {category: "PayrollAndHR", label: string, value: string}
  --department-position: list # Add home department cost center, position, supervisor, reviewer, employment type, EEO class, pay settings, and union information. — item shape: {changeReason?: string, clockBadgeNumber?: string, costCenter1?: string, costCenter2?: string, costCenter3?: string, effectiveDate?: string, employeeType?: string, equalEmploymentOpportunityClass?: string, isMinimumWageExempt?: bool, isOvertimeExempt?: bool, isSupervisorReviewer?: bool, isUnionDuesCollected?: bool, isUnionInitiationCollected?: bool, jobTitle?: string, payGroup?: string, positionCode?: string, shift?: string, supervisorCompanyNumber?: string, supervisorEmployeeId?: string, ... (5 more fields)}
  --disability-description: string # Indicates if employee has disability status. (nullable)
  --employee-id: string # Leave blank to have Web Pay automatically assign the next available employee ID. Max length: 10 (nullable)
  --ethnicity: string # Employee ethnicity. Max length: 10 (nullable)
  --federal-tax: list # Add federal tax amount type (taxCalculationCode), amount or percentage, filing status, and exemptions. — item shape: {amount?: float, deductionsAmount?: float, dependentsAmount?: float, exemptions?: float, filingStatus?: string, higherRate?: bool, otherIncomeAmount?: float, percentage?: float, taxCalculationCode?: string, w4FormYear?: int}
  --first-name: string # Employee first name. Max length: 40 (nullable)
  --fitw-exempt-reason: string # Reason code for FITW exemption. Common values are *SE* (Statutory employee), *CR* (clergy/Religious). Max length: 30 (nullable)
  --futa-exempt-reason: string # Reason code for FUTA exemption. Common values are *501* (5019c)(3) Organization), *IC* (Independent Contractor). Max length: 30 (nullable)
  --gender: string # Employee gender. Common values *M* (Male), *F* (Female). Max length: 1 (nullable)
  --home-address: list # Add employee's home address, personal phone numbers, and personal email. — item shape: {address1?: string, address2?: string, city?: string, country?: string, county?: string, emailAddress?: string, mobilePhone?: string, phone?: string, postalCode?: string, state?: string}
  --is-employee943: oneof<nothing, bool> # Indicates if employee in agriculture or farming. (nullable)
  --is-smoker: oneof<nothing, bool> # Indicates if employee is a smoker. (nullable)
  --last-name: string # Employee last name. Max length: 40 (nullable)
  --local-tax: list # Add local tax code, filing status, and exemptions including PA-PSD taxes. — item shape: {exemptions?: float, exemptions2?: float, filingStatus?: string, residentPSD?: string, taxCode?: string, workPSD?: string}
  --main-direct-deposit: list # Add the main direct deposit account. After deposits are made to any additional direct deposit accounts, the remaining net check is deposited in the main direct deposit account. IMPORTANT: A direct deposit update will remove ALL existing main and additional direct deposit information in WebPay and replace with what is provided on the request. GET API will not return direct deposit data. — item shape: {accountNumber?: string, accountType?: string, isSkipPreNote?: bool, preNoteDate?: string, routingNumber?: string}
  --marital-status: string # Employee marital status. Common values *D (Divorced), M (Married), S (Single), W (Widowed)*. Max length: 10 (nullable)
  --med-exempt-reason: string # Reason code for Medicare exemption. Common values are *501* (5019c)(3) Organization), *IC* (Independent Contractor). Max length: 30 (nullable)
  --middle-name: string # Employee middle name. Max length: 20 (nullable)
  --non-primary-state-tax: list # Add non-primary state tax code, amount type (taxCalculationCode), amount or percentage, filing status, exemptions, supplemental check (specialCheckCalc), and reciprocity code information. — item shape: {amount?: float, deductionsAmount?: float, dependentsAmount?: float, exemptions?: float, exemptions2?: float, filingStatus?: string, higherRate?: bool, otherIncomeAmount?: float, percentage?: float, reciprocityCode?: string, specialCheckCalc?: string, taxCalculationCode?: string, taxCode?: string, w4FormYear?: int}
  --preferred-name: string # Employee preferred display name. Max length: 20 (nullable)
  --primary-pay-rate: list # Add hourly or salary pay rate, effective date, and pay frequency. — item shape: {baseRate?: float, changeReason?: string, defaultHours?: float, effectiveDate?: string, isAutoPay?: bool, payFrequency?: string, payGrade?: string, payType?: string, ratePer?: string, salary?: float}
  --primary-state-tax: list # Add primary state tax code, amount type (taxCalculationCode), amount or percentage, filing status, exemptions, and supplemental check (specialCheckCalc) information. Only one primary state is allowed. — item shape: {amount?: float, deductionsAmount?: float, dependentsAmount?: float, exemptions?: float, exemptions2?: float, filingStatus?: string, higherRate?: bool, otherIncomeAmount?: float, percentage?: float, specialCheckCalc?: string, taxCalculationCode?: string, taxCode?: string, w4FormYear?: int}
  --prior-last-name: string # Prior last name if applicable.Max length: 40 (nullable)
  --salutation: string # Employee preferred salutation. Max length: 10 (nullable)
  --sitw-exempt-reason: string # Reason code for SITW exemption. Common values are *SE* (Statutory employee), *CR* (clergy/Religious). Max length: 30 (nullable)
  --ss-exempt-reason: string # Reason code for Social Security exemption. Common values are *SE* (Statutory employee), *CR* (clergy/Religious). Max length: 30 (nullable)
  --ssn: string # Employee social security number. Leave it blank if valid social security number not available. Max length: 11 (nullable)
  --status: list # Add employee status, change reason, effective date, and adjusted seniority date. Note that companies that are still in Implementation cannot hire future employees. — item shape: {adjustedSeniorityDate?: string, changeReason?: string, effectiveDate?: string, employeeStatus?: string, hireDate?: string, isEligibleForRehire?: bool}
  --suffix: string # Employee name suffix. Common values are *Jr, Sr, II*.Max length: 30 (nullable)
  --sui-exempt-reason: string # Reason code for SUI exemption. Common values are *SE* (Statutory employee), *CR* (clergy/Religious). Max length: 30 (nullable)
  --sui-state: string # Employee SUI (State Unemployment Insurance) state. Max length: 2 (nullable)
  --tax-distribution-code1099-r: string # Employee 1099R distribution code. Common values are *7* (Normal Distribution), *F* (Charitable Gift Annuity). Max length: 1 (nullable)
  --tax-form: string # Employee tax form for reporting income. Valid values are *W2, 1099M, 1099R*. Default is W2. Max length: 15 (nullable)
  --veteran-description: string # Indicates if employee is a veteran. (nullable)
  --web-time: record # Add Web Time badge number and charge rate and synchronize Web Pay and Web Time employee data. — shape: {badgeNumber?: string, chargeRate?: float, isTimeLaborEnabled?: bool}
  --work-address: list # Add employee's work address, phone numbers, and email. Work Location drop down field is not included. — item shape: {address1?: string, address2?: string, city?: string, country?: string, county?: string, emailAddress?: string, mobilePhone?: string, pager?: string, phone?: string, phoneExtension?: string, postalCode?: string, state?: string}
  --work-eligibility: list # Add I-9 work authorization information. — item shape: {alienOrAdmissionDocumentNumber?: string, attestedDate?: string, countryOfIssuance?: string, foreignPassportNumber?: string, i94AdmissionNumber?: string, i9DateVerified?: string, i9Notes?: string, isI9Verified?: bool, isSsnVerified?: bool, ssnDateVerified?: string, ssnNotes?: string, visaType?: string, workAuthorization?: string, workUntil?: string}
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/weblinkstaging/companies/{companyId}/employees/newemployees"
    path_params: [{name: companyId, var: company_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: additionalDirectDeposit, var: additional_direct_deposit}, {name: benefitSetup, var: benefit_setup}, {name: birthDate, var: birth_date}, {name: customBooleanFields, var: custom_boolean_fields}, {name: customDateFields, var: custom_date_fields}, {name: customDropDownFields, var: custom_drop_down_fields}, {name: customNumberFields, var: custom_number_fields}, {name: customTextFields, var: custom_text_fields}, {name: departmentPosition, var: department_position}, {name: disabilityDescription, var: disability_description}, {name: employeeId, var: employee_id}, {name: ethnicity, var: ethnicity}, {name: federalTax, var: federal_tax}, {name: firstName, var: first_name}, {name: fitwExemptReason, var: fitw_exempt_reason}, {name: futaExemptReason, var: futa_exempt_reason}, {name: gender, var: gender}, {name: homeAddress, var: home_address}, {name: isEmployee943, var: is_employee943}, {name: isSmoker, var: is_smoker}, {name: lastName, var: last_name}, {name: localTax, var: local_tax}, {name: mainDirectDeposit, var: main_direct_deposit}, {name: maritalStatus, var: marital_status}, {name: medExemptReason, var: med_exempt_reason}, {name: middleName, var: middle_name}, {name: nonPrimaryStateTax, var: non_primary_state_tax}, {name: preferredName, var: preferred_name}, {name: primaryPayRate, var: primary_pay_rate}, {name: primaryStateTax, var: primary_state_tax}, {name: priorLastName, var: prior_last_name}, {name: salutation, var: salutation}, {name: sitwExemptReason, var: sitw_exempt_reason}, {name: ssExemptReason, var: ss_exempt_reason}, {name: ssn, var: ssn}, {name: status, var: status}, {name: suffix, var: suffix}, {name: suiExemptReason, var: sui_exempt_reason}, {name: suiState, var: sui_state}, {name: taxDistributionCode1099R, var: tax_distribution_code1099_r}, {name: taxForm, var: tax_form}, {name: veteranDescription, var: veteran_description}, {name: webTime, var: web_time}, {name: workAddress, var: work_address}, {name: workEligibility, var: work_eligibility}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    company_id: $company_id, additional_direct_deposit: $additional_direct_deposit, benefit_setup: $benefit_setup, birth_date: $birth_date, custom_boolean_fields: $custom_boolean_fields, custom_date_fields: $custom_date_fields, custom_drop_down_fields: $custom_drop_down_fields, custom_number_fields: $custom_number_fields, custom_text_fields: $custom_text_fields, department_position: $department_position, disability_description: $disability_description, employee_id: $employee_id, ethnicity: $ethnicity, federal_tax: $federal_tax, first_name: $first_name, fitw_exempt_reason: $fitw_exempt_reason, futa_exempt_reason: $futa_exempt_reason, gender: $gender, home_address: $home_address, is_employee943: $is_employee943, is_smoker: $is_smoker, last_name: $last_name, local_tax: $local_tax, main_direct_deposit: $main_direct_deposit, marital_status: $marital_status, med_exempt_reason: $med_exempt_reason, middle_name: $middle_name, non_primary_state_tax: $non_primary_state_tax, preferred_name: $preferred_name, primary_pay_rate: $primary_pay_rate, primary_state_tax: $primary_state_tax, prior_last_name: $prior_last_name, salutation: $salutation, sitw_exempt_reason: $sitw_exempt_reason, ss_exempt_reason: $ss_exempt_reason, ssn: $ssn, status: $status, suffix: $suffix, sui_exempt_reason: $sui_exempt_reason, sui_state: $sui_state, tax_distribution_code1099_r: $tax_distribution_code1099_r, tax_form: $tax_form, veteran_description: $veteran_description, web_time: $web_time, work_address: $work_address, work_eligibility: $work_eligibility
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
